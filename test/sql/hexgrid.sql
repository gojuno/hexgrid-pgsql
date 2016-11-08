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

select ST_SetSRID(ST_MakePoint(10000, 10000), 3857)::hexagon as hexagon;

select ST_AsText(ST_Centroid((28, 1)::hexagon)) as center;

select ST_AsText(ST_Transform(
    (ST_Hexagon(ST_SetSRID(ST_MakePoint(-73.0, 40.0), 4326), 1))::geometry, 4326
)) as geom;


select
    morton_unpack((ST_Hexagon('SRID=3857;POINT(13 666)', 2)).code) as p1,
    morton_unpack((ST_Hexagon('SRID=3857;POINT(666 13)', 2)).code) as p2,
    morton_unpack((ST_Hexagon('SRID=3857;POINT(-13 -666)', 2)).code) as p3,
    morton_unpack((ST_Hexagon('SRID=3857;POINT(-666 -13)', 2)).code) as p4;
