delete from hexgrids where id = 2;
insert into 
    hexgrids (id, params, tag)
    values(
        2,
        (
            hex_OrientationFlat(),
            3857,
            ST_SetSRID(ST_MakePoint(0, 0), 3857),
            ST_SetSRID(ST_MakePoint(5, 5), 3857)
        )::hexgrid,
        'flat_grid_5x5'
    );

drop table if exists basic_geom;
create table basic_geom(
    g       int,
    geom    geometry
);

insert into basic_geom (g, geom)
    values
    (1, 'SRID=3857;POINT(0 0)'),
    (1, 'SRID=3857;POINT(10 10)'),
    (1, 'SRID=3857;POINT(20 20)'),
    (1, 'SRID=3857;POINT(30 30)'),
    (1, 'SRID=3857;POINT(40 40)'),
    (1, 'SRID=3857;POINT(50 50)'),
    (1, 'SRID=3857;POINT(60 60)'),
    (1, 'SRID=3857;POINT(70 70)'),
    (1, 'SRID=3857;POINT(80 80)'),
    (1, 'SRID=3857;POINT(90 90)'),
    (1, 'SRID=3857;POINT(100 100)'),
    (1, 'SRID=3857;POINT(0 70)'),
    (1, 'SRID=3857;POINT(10 70)'),
    (1, 'SRID=3857;POINT(20 70)'),
    (1, 'SRID=3857;POINT(30 70)'),
    (1, 'SRID=3857;POINT(40 70)'),
    (1, 'SRID=3857;POINT(40 80)'),
    (1, 'SRID=3857;POINT(40 90)'),
    (1, 'SRID=3857;POINT(40 100)');


\echo '=> basic_geom.geojson'

select
    st_asgeojson(st_collect(geom)) as geom
from 
    basic_geom;


\echo '=> basic_hexat.geojson'
select
    st_asgeojson(st_collect(ST_Hexagon(geom, 2)::geometry)) as geom
from basic_geom;

\echo '=> basic_region.geojson'

select ST_AsGeoJson('SRID=3857;POLYGON((0 0, 100 0, 100 100, 0 100, 0 0))');

\echo '=> basic_hexgrid_region.geojson'

select
    st_asgeojson(st_collect(h::geometry)) as geom
from
    ST_HexagonCoverage('SRID=3857;POLYGON((0 0, 100 0, 100 100, 0 100, 0 0))', 2) as h;
