# Sanitized EDID fixtures

These hexadecimal fixtures retain the capability/timing structure of the ASUS
PG27UCWM and Apple Studio Display XDR. They are test inputs only and must never
be installed as display overrides.

Every fixture uses these synthetic identity fields:

- Base EDID serial: `123456` (bytes 12–15, little endian).
- Manufacture date: week 1, 2020 (bytes 16–17).
- ASUS serial descriptor: `TEST-000001`, newline, space (bytes 113–125).
- XDR ContainerID: `00112233-4455-4677-8899-aabbccddeeff` (bytes 264–279).
- XDR tiled-display serial: `123456` (bytes 334–337, little endian).

The ContainerID and tiled serial offsets follow the `0x29` and `0x12`
DisplayID blocks, respectively. The model identifiers, tile geometry, small
vendor capability blocks, colorimetry, HDR, audio and timing data remain intact.
EDID outer checksums and the XDR identity block's internal DisplayID checksum
were recalculated after replacing the identifiers.

The capped fixtures were independently constructed during hardware investigation,
then sanitized identically to the original fixtures. Tests compare the engine's
result against these fixed expected bytes; they do not generate the expected
result using the implementation under test.

`../decode-fixtures.py` checks every synthetic identity field and checksum before
writing temporary binary inputs. The Objective-C tests validate caps,
preservation, idempotence and rejection of malformed or foreign EDIDs. They link
only the pure EDID modules and Foundation, and never call the display daemon or
modify the connected monitors.
