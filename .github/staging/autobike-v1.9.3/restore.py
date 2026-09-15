#!/usr/bin/env python3
"""Restore only reviewed, hash-checked source. No game art/audio is transferred."""
from pathlib import Path
import base64
import gzip
import hashlib
import json

stage = Path(__file__).resolve().parent
root = stage.parents[2]
parts = sorted(stage.glob('source*.b64'))
assert len(parts) == 7, 'Missing source-transfer shard'
compressed = base64.b64decode(''.join(p.read_text(encoding='ascii') for p in parts), validate=True)
assert hashlib.sha256(compressed).hexdigest() == 'e50231cfd021ef054b2c5c4ff23e70a6d39e0528ff4c091da54582d1084ad96d', 'Transfer checksum mismatch'
entries = json.loads(gzip.decompress(compressed))
assert len(entries) == 19
planned = []
seen = set()
for entry in entries:
    name = entry['path']
    path = Path(name)
    assert not path.is_absolute() and '..' not in path.parts and name not in seen, name
    seen.add(name)
    dest = root / path
    if entry['before'] is None:
        assert not dest.exists(), 'Refusing to overwrite new file: ' + name
        body = b''
    else:
        body = dest.read_bytes()
        assert hashlib.sha256(body).hexdigest() == entry['before'], 'Base mismatch: ' + name
    lines = body.decode('utf-8').splitlines(keepends=True)
    limit = len(lines)
    for start, end, replacement in reversed(entry['edits']):
        assert 0 <= start <= end <= limit, name
        lines[start:end] = replacement.splitlines(keepends=True)
        limit = start
    output = ''.join(lines).encode('utf-8')
    assert hashlib.sha256(output).hexdigest() == entry['after'], 'Target mismatch: ' + name
    planned.append((dest, output))
# Verify the entire plan before writing any output file.
for dest, output in planned:
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(output)
(stage / 'target-files.json').write_text(json.dumps(sorted(seen)), encoding='utf-8')
print('PASS reviewed transfer checksum and all 19 source base/target hashes.')
