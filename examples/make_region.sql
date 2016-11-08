drop table if exists region;
create table region as
select ST_SetSRID(ST_GeomFromGeoJSON(
'{
    "type": "Polygon",
    "coordinates": [[
        [
            -73.99600982666016,
            40.70302525959208
        ],
        [
            -74.0203857421875,
            40.67829474034605
        ],
        [
            -74.00665283203124,
            40.664233301369194
        ],
        [
            -74.036865234375,
            40.6426145676101
        ],
        [
            -74.04304504394531,
            40.62515819144965
        ],
        [
            -74.03995513916016,
            40.613952441166596
        ],
        [
            -74.02931213378906,
            40.60326613801471
        ],
        [
            -74.0042495727539,
            40.596488572568774
        ],
        [
            -74.00081634521484,
            40.58527801407785
        ],
        [
            -74.01454925537108,
            40.578237865659524
        ],
        [
            -74.00527954101562,
            40.56858905146872
        ],
        [
            -73.87653350830078,
            40.58162765924269
        ],
        [
            -73.8827133178711,
            40.606654663050485
        ],
        [
            -73.89129638671875,
            40.61160681368841
        ],
        [
            -73.89026641845703,
            40.62489761395496
        ],
        [
            -73.87104034423828,
            40.637925243274374
        ],
        [
            -73.99600982666016,
            40.70302525959208
        ]
    ]]
}'), 4326) as geom;


delete from hexgrids where id = 1;
insert into hexgrids (id, params, tag)
    values (
        1,
        (
        hex_OrientationFlat(),
        3857,
        ST_SetSRID(ST_MakePoint(0, 0), 3857),
        ST_SetSRID(ST_MakePoint(500, 500), 3857))::hexgrid,
        'flat_grid_500x500'
    );

-- Make hexgrid polygons
\echo '=> hexgrid_region.geojson'
select
    ST_AsGeoJson(ST_Collect(ST_Transform(h::geometry, 4326)))
from
    ST_HexagonCoverage(ST_Transform(
        (select ST_Union(geom) from region), 3857), 1) as h;
