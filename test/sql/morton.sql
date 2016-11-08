
select morton_pack(-13, 42) as code;

select morton_unpack(morton_pack(-13, 42)) as hex_qr;
