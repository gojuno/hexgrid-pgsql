--- Morton coding

create or replace function _morton_compact(
    value int8
)
returns int8 as $$
begin
    value = value & x'5555555555555555'::int8;
    value = (value | (value >> 1)) & x'3333333333333333'::int8;
    value = (value | (value >> 2)) & x'0f0f0f0f0f0f0f0f'::int8;
    value = (value | (value >> 4)) & x'00ff00ff00ff00ff'::int8;
    value = (value | (value >> 8)) & x'0000ffff0000ffff'::int8;
    value = (value | (value >> 16)) & x'00000000ffffffff'::int8;
    return value;
end
$$ language 'plpgsql' immutable strict parallel safe;


create or replace function _morton_split(
    value int8
)
returns int8 as $$
begin
    value = value & x'00000000ffffffff'::int8;
    value = (value | (value << 16)) & x'0000ffff0000ffff'::int8;
    value = (value | (value << 8)) & x'00ff00ff00ff00ff'::int8;
    value = (value | (value << 4)) & x'0f0f0f0f0f0f0f0f'::int8;
    value = (value | (value << 2)) & x'3333333333333333'::int8;
    value = (value | (value << 1)) & x'5555555555555555'::int8;
    return value;
end
$$ language 'plpgsql' immutable strict parallel safe;


create or replace function morton_pack(
    in_q int8, in_r int8
)
returns int8 as $$
declare
    q       int8;
    r       int8;
begin
    q = in_q;
    r = in_r;
    -- shift
    if q < 0
    then
        q = -q;
        q = q | (1::int8 << (32 - 1));
    end if;
    if r < 0
    then
        r = -r;
        r = r | (1::int8 << (32 - 1));
    end if;

    return _morton_split(q) | (_morton_split(r) << 1);
end
$$ language 'plpgsql' immutable strict parallel safe;


create or replace function morton_unpack(
    code int8
)
returns int8[] as $$
declare
    sign    int8;
    q       int8;
    r       int8;
begin
    q = _morton_compact(code);
    r = _morton_compact(code >> 1);

    -- unshift
    sign = q & (1::int8 << (32 - 1));
    q = q & ((1::int8 << (32 - 1)) - 1);
    if sign != 0
    then
        q = -q;
    end if;

    sign = r & (1::int8 << (32 - 1));
    r = r & ((1::int8 << (32 - 1)) - 1);
    if sign != 0
    then
        r = -r;
    end if;
    return array[q, r];
end
$$ language 'plpgsql' immutable strict parallel safe;
