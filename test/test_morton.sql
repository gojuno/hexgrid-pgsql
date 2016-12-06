
begin;
create extension hexgrid;

select plan(2);

select is(morton_pack(-13, 42), 4611686018427390169);

select is(morton_unpack(morton_pack(-13, 42)), array[-13::int8,42::int8]);

rollback;
