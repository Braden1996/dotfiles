#!/usr/bin/env python3
"""Verify sanitized EDID fixtures and decode them into a disposable directory."""

from pathlib import Path
import sys


def main():
    if len(sys.argv) != 2:
        raise SystemExit("usage: decode-fixtures.py OUTPUT_DIRECTORY")
    destination = Path(sys.argv[1])
    destination.mkdir(parents=True, exist_ok=True)
    fixture_dir = Path(__file__).parent / "fixtures"
    serial = (123456).to_bytes(4, "little")
    sizes = {
        "asus-original": 384,
        "asus-cap144": 384,
        "xdr-original": 768,
        "xdr-cap60": 640,
    }
    for name, size in sizes.items():
        data = bytes.fromhex((fixture_dir / f"{name}.hex").read_text())
        assert len(data) == size, f"{name}: unexpected fixture length"
        assert data[12:16] == serial, f"{name}: base serial must be synthetic"
        assert data[16:18] == bytes([1, 30]), f"{name}: date must be synthetic"
        for pos in range(54, 126, 18):
            if data[pos:pos + 5] == b"\x00\x00\x00\xff\x00":
                assert data[pos + 5:pos + 18] == b"TEST-000001\n ", (
                    f"{name}: serial descriptor must be synthetic"
                )
        if name.startswith("xdr"):
            assert data[261] == 0x29 and data[263] == 16
            assert data[264:280] == bytes.fromhex(
                "00112233445546778899aabbccddeeff"
            ), f"{name}: ContainerID must be synthetic"
            assert data[313] == 0x12 and data[315] == 22
            assert data[334:338] == serial, f"{name}: tiled serial must be synthetic"
        for base in range(0, len(data), 128):
            block = data[base:base + 128]
            assert sum(block) % 256 == 0, f"{name}: invalid EDID checksum"
            if block[0] == 0x70:
                end = 5 + block[2]
                assert sum(block[1:end + 1]) % 256 == 0, (
                    f"{name}: invalid internal DisplayID checksum"
                )
        (destination / f"{name}.bin").write_bytes(data)
    print("validated synthetic monitor identities and fixture checksums")


if __name__ == "__main__":
    main()
