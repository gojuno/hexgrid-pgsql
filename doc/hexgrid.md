# Types

## hex_orientation

    create type hex_orientation as (
        name        text,
        f           float[],
        b           float[],
        sinuses     float[],
        cosinuses   float[]
    );

## hexgrid

    create type hexgrid as (
        orientation hex_orientation,
        srid        int,
        origin      geometry(point),
        size        geometry(point)
    );

where

* orientation - orientation of hexgrid
* srid - SRID on a geometry
* origin - center of hexgrid
* size - size of hexagon in grid


# Predefined orientations

## hex_OrientationPointy

Pointy topped orientation

## hex_OrientationFlat

Flat topped orientation

# Helpers functions

## morton_pack

    function morton_pack(
        q int8,
        r int8
    ) returns int8

Example:

    =# select morton_pack(10,20) as code;
     code
    ------
      612
    (1 row)

## morton_unpack

    function morton_unpack(
        code int8
    ) returns int8[]

Example:

    =# select morton_unpack(612) as qr;
       qr
    ---------
     {10,20}
    (1 row)

# Main functions

## ST_Hexagon

Get hexagon for given point

    function ST_Hexagon(
        point   geometry(point),
        grid_id int default 1
    ) returns hexagon

Example:

    =# select ST_Hexagon('SRID=3857;POINT(1000 1000)') as hex;
      hex
    -------
     (3,1)
    (1 row)

## ST_Centroid

Get center point of hexagon

    function ST_Centroid(
        hexagon     hexagon
    ) returns geometry(point)

## ST_HexagonCoverage

Make hexagons for given region 

    ST_HexagonCoverage(
        region geometry,
        grid_id int default 1
    ) returns setof hexagon 

