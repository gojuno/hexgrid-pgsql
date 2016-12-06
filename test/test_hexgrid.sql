
begin;
create extension hexgrid;

insert into
    hexgrids (id, params, tag)
    values
    (
        1,
        (
            hex_OrientationFlat(),
            3857,
            ST_SetSRID(ST_MakePoint(0, 0), 3857),
            ST_SetSRID(ST_MakePoint(500, 500), 3857)
        )::hexgrid,
        'flat_grid_500x500'
    ),
    (
        2,
        (
            hex_OrientationFlat(),
            3857,
            ST_SetSRID(ST_MakePoint(10, 20), 3857),
            ST_SetSRID(ST_MakePoint(20, 10), 3857)
        )::hexgrid,
        'flat_grid_20x10'
    );

select plan(7);

select is(
    ST_SetSRID(ST_MakePoint(10000, 10000), 3857)::hexagon,
    (115,1)::hexagon
);

select is(
    ST_Centroid((28, 1)::hexagon),
    ST_SetSRID(ST_MakePoint(4500, 4330.12701892219), 3857));


select is(
    ST_Transform(
        (ST_Hexagon(
            ST_SetSRID(ST_MakePoint(-73.0, 40.0), 4326), 1))::geometry,
        4326),
    GeomFromEWKT(
        'SRID=4326;POLYGON((
            -72.9970999875523 40.0017510726044,
            -73.0015915639729 40.0017510726044,
            -73.0038373521832 39.9987713095566,
            -73.0015915639729 39.9957914164756,
            -72.9970999875523 39.9957914164756,
            -72.994854199342 39.9987713095566,
            -72.9970999875523 40.0017510726044))'));

select is(
    morton_unpack((ST_Hexagon('SRID=3857;POINT(13 666)', 2)).code),
    array[0, 37]::int8[]
);

select is(
    morton_unpack((ST_Hexagon('SRID=3857;POINT(666 13)', 2)).code),
    array[22, -11]::int8[]
);

select is(
    morton_unpack((ST_Hexagon('SRID=3857;POINT(-13 -666)', 2)).code),
    array[-1, -39]::int8[]
);

select is(
    morton_unpack((ST_Hexagon('SRID=3857;POINT(-666 -13)', 2)).code),
    array[-22, 9]::int8[]
);

rollback;
