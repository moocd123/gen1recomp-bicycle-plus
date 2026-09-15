#!/usr/bin/env python3
"""Apply only the locally reviewed, hash-checked AUTOBIKE+ source edits."""
from pathlib import Path
import hashlib
import json

stage = Path(__file__).resolve().parent
root = stage.parents[2]
planned = []
seen = set()
for operation_file in sorted(stage.glob('ops*.json')):
    for entry in json.loads(operation_file.read_text(encoding='utf-8')):
        name = entry['path']
        path = Path(name)
        assert not path.is_absolute() and '..' not in path.parts and name not in seen, name
        seen.add(name)
        dest = root / path
        before = entry['before']
        if before is None:
            assert not dest.exists(), 'Refusing to overwrite new file: ' + name
            body = b''
        else:
            body = dest.read_bytes()
            assert hashlib.sha256(body).hexdigest() == before, 'Base mismatch: ' + name
        lines = body.decode('utf-8').splitlines(keepends=True)
        limit = len(lines)
        for start, end, replacement in reversed(entry['edits']):
            assert 0 <= start <= end <= limit, name
            lines[start:end] = replacement.splitlines(keepends=True)
            limit = start
        output = ''.join(lines).encode('utf-8')
        assert hashlib.sha256(output).hexdigest() == entry['after'], 'Target mismatch: ' + name
        planned.append((dest, output))
assert len(planned) == 14
# Validate the entire change set before writing any resulting source.
for dest, output in planned:
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_bytes(output)
print('PASS: all 14 base/target source hashes; only the reviewed edits were applied.')
