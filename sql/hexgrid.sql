
\echo use "create extension hexgrid" to load this file. \quit

-- types
drop type if exists hex_orientation cascade;
create type hex_orientation as (
    name        text,
    f           float[],
    b           float[],
    sinuses     float[],
    cosinuses   float[]
);

drop type if exists hexgrid cascade;
create type hexgrid as (
    orientation hex_orientation,
    srid        int,
    origin      geometry(point),
    size        geometry(point)
);

drop type if exists hexagon cascade;
create type hexagon as (
    code        int8,
    grid_id     int
);


-- tables

drop table if exists hexgrids;
create table hexgrids (
    id          serial primary key,
    params      hexgrid,
    tag         text
);


-- functions

create or replace function hex_Orientation(
    name        text,
    f           float[],
    b           float[],
    start_angle float
)
returns hex_orientation
language sql immutable strict parallel safe
as $function$
    select
    (
        name,
        f,
        b,
        (
            select array(
                select
                    sin(2.0 * pi() * (i + start_angle) / 6.0)
                from
                    generate_series(1, 6) as i)),
        (
            select array(
                select
                    cos(2.0 * pi() * i / 6.0)
                from
                    generate_series(1, 6) as i))
    ) :: hex_orientation
$function$;


create or replace function hex_OrientationPointy()
returns hex_orientation
language sql immutable strict parallel safe
as $function$
    select hex_Orientation(
        'pointy',
        array[sqrt(3.0), sqrt(3.0)/2.0, 0.0, 3.0/2.0],
        array[sqrt(3.0)/3.0, -1.0/3.0, 0.0, 2.0/3.0],
        0.0
    )
$function$;


create or replace function hex_OrientationFlat()
returns hex_orientation
language sql immutable strict parallel safe
as $function$
    select hex_Orientation(
        'flat',
        array[3.0/2.0, 0.0, sqrt(3.0)/2.0, sqrt(3.0)],
        array[2.0/3.0, 0.0, -1.0/3.0, sqrt(3.0)/3.0],
        0.0
    )
$function$;


create or replace function _get_hexgrid(
    grid_id int
)
returns hexgrid as $$
declare
    hexgrid    hexgrid;
begin
    hexgrid = (select params from hexgrids where id = grid_id);
    if hexgrid.srid is null
    then
        raise exception 'hexgrid % does not exist', grid_id;
    end if;
    return hexgrid;
end
$$ language 'plpgsql' immutable;


create or replace function _round_qr(
    q float,
    r float
)
returns int8[] as $$
declare
    s           float;
    round_q     float;
    round_r     float;
    round_s     float;
    dq          float;
    dr          float;
    ds          float;
begin
    s = -(q+r);

    round_q = round(q);
    round_r = round(r);
    round_s = round(s);

    dq = abs(round_q - q);
    dr = abs(round_r - r);
    ds = abs(round_s - s);

    if (dq > dr) and (dq > ds)
    then
        round_q = -(round_r + round_s);
    elseif dr > ds
    then
        round_r = -(round_q + round_s);
    end if;

    return array[trunc(round_q)::int8, trunc(round_r)::int8];
end
$$ language 'plpgsql' immutable;


create or replace function ST_Hexagon(
    point   geometry(point),
    grid_id int default 1
)
returns hexagon as $$
declare
    x       float default 0;
    y       float default 0;
    q       float;
    r       float;
    s       float;
    dq      float;
    dr      float;
    ds      float;
    round_qr    int8[];
    round_r    float;
    round_s    float;
    hexgrid    hexgrid;
begin
    hexgrid = _get_hexgrid(grid_id);
    point = ST_Transform(point, hexgrid.srid);

    x = (ST_X(point) - ST_X(hexgrid.origin)) / ST_X(hexgrid.size);
    y = (ST_Y(point) - ST_Y(hexgrid.origin)) / ST_Y(hexgrid.size);
    q = (hexgrid.orientation).b[1] * x + (hexgrid.orientation).b[2] * y;
    r = (hexgrid.orientation).b[3] * x + (hexgrid.orientation).b[4] * y;
    round_qr = _round_qr(q, r);
    return (
        morton_pack(
            round_qr[1],
            round_qr[2]
        ),
        grid_id
    )::hexagon;
end
$$ language 'plpgsql' immutable;

create or replace function _geometry_to_hex(
    point   geometry(point)
)
returns hexagon as $$
begin
    return ST_Hexagon(point, 1);
end
$$ language 'plpgsql' immutable;

drop cast if exists ( geometry as hexagon );
create cast ( geometry as hexagon )
with function _geometry_to_hex(geometry);


create or replace function ST_Centroid(
    hexagon     hexagon
)
returns geometry(point) as $$
declare
    x       float default 0;
    y       float default 0;
    f       float[];
    hexgrid    hexgrid;
    hex_qr  int8[];
begin
    hexgrid = _get_hexgrid(hexagon.grid_id);
    hex_qr = morton_unpack(hexagon.code);

    f = (hexgrid.orientation).f;
    x = (f[1] * hex_qr[1] + f[2] * hex_qr[2]) * ST_X(hexgrid.size) + ST_X(hexgrid.origin);
    y = (f[3] * hex_qr[1] + f[4] * hex_qr[2]) * ST_Y(hexgrid.size) + ST_Y(hexgrid.origin);
    return ST_SetSRID(ST_MakePoint(x, y), hexgrid.srid);
end
$$ language 'plpgsql' immutable;


create or replace function _hex_to_geometry(
    hexagon     hexagon
)
returns geometry(polygon) as $$
declare
    hexgrid        hexgrid;
    center      geometry;
    cosinuses   float[];
    sinuses     float[];
    multiline      geometry;
begin
    hexgrid = _get_hexgrid(hexagon.grid_id);

    center = ST_Centroid(hexagon);
    cosinuses = (hexgrid.orientation).cosinuses;
    sinuses = (hexgrid.orientation).sinuses;
    multiline = (
    select
        ST_SetSRID(
            ST_LineFromMultiPoint(
                ST_SnapToGrid(ST_Collect(geom), 0.000001)
            ),
            hexgrid.srid)
    from
        (select
            ST_MakePoint(
                ST_X(hexgrid.size) * cosinuses[i] + ST_X(center),
                ST_Y(hexgrid.size) * sinuses[i] + ST_Y(center)
            ) as geom
        from
            generate_series(1, 6) as i) as points
    );
    return ST_MakePolygon(
        ST_AddPoint(multiline, ST_StartPoint(multiline)));
end
$$ language 'plpgsql' immutable;

drop cast if exists ( hexagon as geometry );
create cast ( hexagon as geometry )
with function _hex_to_geometry(hexagon);

create or replace function _extent(
    region      geometry,
    grid_id     int
)
returns int8[] as $$
declare
    hexgrid        hexgrid;
begin
    hexgrid = _get_hexgrid(grid_id);
    region = ST_Transform(region, hexgrid.srid);

    return (select
        -- 3. select bounding hexes
        array[
            min(bbox.hex_qr[1]),
            max(bbox.hex_qr[1]),
            min(bbox.hex_qr[2]),
            max(bbox.hex_qr[2])
        ]
    from
        (
        select
            -- 2. calcaulate bounding hexes
            -- FIXME: double pack/unpack
            morton_unpack(
                (ST_Hexagon(ST_SetSRID((p.dp).geom, ST_SRID(region)), grid_id)).code
            ) as hex_qr
        from
            -- 1. get bounding box for geometry
            (select
                ST_DumpPoints(ST_Extent(region)) as dp
            )
            as p
        ) as bbox
    );
end
$$ language 'plpgsql' immutable strict parallel safe;



create or replace function ST_HexagonCoverage(
    region geometry,
    grid_id int default 1
)
returns setof hexagon as $$
declare
    qmin            int8;
    qmax            int8;
    rmin            int8;
    rmax            int8;
    bbox_hex_qrs    int8[];
    hexagon         hexagon;
    r               int8;
    q               int8;
begin
    if region is null or ST_IsEmpty(region)
    then
        raise exception 'empty region';
    end if;

    bbox_hex_qrs = _extent(region, grid_id);

    qmin = bbox_hex_qrs[1];
    qmax = bbox_hex_qrs[2];
    rmin = bbox_hex_qrs[3];
    rmax = bbox_hex_qrs[4];

    for q in (select generate_series(qmin, qmax))
    loop
        for r in (select generate_series(rmin, rmax))
        loop
            hexagon = (morton_pack(q, r), grid_id)::hexagon;
            if ST_Intersects(hexagon::geometry, region)
            then
                return next hexagon;
            end if;
        end loop;
    end loop;
    return;
end
$$ language 'plpgsql' immutable;
