#!/usr/bin/env python3
"""Build the reviewed Bicycle Plus v1.5.0 source; no engine or ROM assets."""
from pathlib import Path
from zipfile import ZipFile, ZipInfo, ZIP_DEFLATED
import hashlib
import json

ROOT = Path(__file__).resolve().parents[2]
DIST = ROOT / "dist"
LUA_HASHES = {
    "audio.lua": "7923276326260941c5af81cdbb704ed282fa99ca4156d63a18e369944835e880",
    "audio_menu.lua": "fbd12b1c7ba818ab140d25ce76f01f52847f92dc20505cd766e5fced53fe5d71",
    "automount.lua": "56cd15b7e830eb50551245978976b533114aebdc72218ded28c35f268d6d019c",
    "bike_parts.lua": "9f6f88975ed71bd5409800c78c91a975375790911f0f26af7b9c39023321fb87",
    "colour_picker.lua": "eeb8be973a5519e2e246c26e9cdf25183da7fd141c01dd058da2185068bbc746",
    "colours.lua": "7867a0bb0e5ba4b3db99c986a0e5a2b8887f2b34d6e78154dd66ece87f7fc8d5",
    "hardware_colours.lua": "54e5b47a2792130217089f5ab2a9f0d43a8e51aa05aea0e83489280f94c62b34",
    "main.lua": "b5a2016c6f2b18f0a4db93f683a06a976257fcfc638234b56714776818001f14"
}


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def main() -> None:
    m = json.loads((ROOT / "manifest.json").read_text(encoding="utf-8"))
    expected = ("bicycle_plus", "1.5.0", ">=0.2.59", 2, "main.lua",
                "moocd123/gen1recomp-bicycle-plus")
    actual = tuple(m.get(k) for k in ("id", "version", "game_version", "api", "entry", "github"))
    if actual != expected:
        raise SystemExit("Manifest does not match the reviewed v1.5.0 update.")
    if m.get("permissions") != ["engine_internals"] or m.get("optional_dependencies") != ["trainer_skins"]:
        raise SystemExit("Unexpected permissions or dependencies.")
    if m.get("name") != "Bicycle Plus" or m.get("affects_link") is not False:
        raise SystemExit("Unexpected identity or link behaviour.")
    if sorted(m.get("games", [])) != sorted(["red", "blue", "yellow", "gold", "silver", "crystal"]):
        raise SystemExit("Unexpected game targeting.")
    names = sorted([*LUA_HASHES, "manifest.json", "README.md", "LICENSE",
                    "CHANGELOG.md", "COMPATIBILITY.md", "VERIFICATION.md",
                    "RELEASE_NOTES_v1.5.0.md", "docs/HARDWARE_COLOURS.md"])
    files = {name: (ROOT / name).read_bytes() for name in names}
    for name, expected_hash in LUA_HASHES.items():
        if digest(files[name]) != expected_hash:
            raise SystemExit(f"Reviewed source hash mismatch: {name}")
    metadata = {
        "modkit": "1.0.0", "packed_at": "2026-09-14T00:00:00Z",
        "id": m["id"], "version": m["version"], "api": m["api"],
        "engine_range": m["game_version"],
        "files": [{"path": name, "bytes": len(data), "sha256": digest(data)}
                  for name, data in sorted(files.items())],
    }
    files[".modkit/pack.json"] = (json.dumps(metadata, indent=2) + "\n").encode("utf-8")
    DIST.mkdir(exist_ok=True)
    archive = DIST / "bicycle_plus-1.5.0.zip"
    with ZipFile(archive, "w") as z:
        for name, data in sorted(files.items()):
            info = ZipInfo(name, date_time=(2026, 9, 14, 0, 0, 0))
            info.compress_type = ZIP_DEFLATED
            info.create_system = 3
            info.external_attr = 0o100644 << 16
            z.writestr(info, data, compresslevel=9)
    with ZipFile(archive) as z:
        if z.testzip() is not None or set(z.namelist()) != set(files):
            raise SystemExit("ZIP verification failed.")
        for name, data in files.items():
            if z.read(name) != data:
                raise SystemExit(f"ZIP round-trip failed: {name}")
    checksum = f"{digest(archive.read_bytes())}  {archive.name}\n"
    (DIST / "SHA256SUMS.txt").write_text(checksum, encoding="ascii")
    print("PASS: manifest, eight reviewed Lua files, explicit allowlist and ZIP integrity.")
    print("Packaging checks are not physical-device gameplay tests.")
    print(checksum, end="")


if __name__ == "__main__":
    main()
