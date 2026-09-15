#!/usr/bin/env python3
"""Apply reviewed UTF-8 source deltas, validating base and final file hashes."""
from pathlib import Path
import hashlib
import json
import re

STAGE = Path(__file__).resolve().parent
ROOT = STAGE.parents[2]
sha = lambda data: hashlib.sha256(data).hexdigest()
expected = json.loads((STAGE / 'target-sha256.json').read_text())
assert len(expected) == 33
for name, digest in expected.items():
    path = Path(name)
    assert not path.is_absolute() and '..' not in path.parts
    assert re.fullmatch(r'[a-f0-9]{64}', digest)
    assert (ROOT / path).resolve().is_relative_to(ROOT.resolve())

for number in range(1, 7):
    operations = json.loads((STAGE / f'ops{number}.json').read_text())
    for name, entry in operations.items():
        assert name in expected, f'Path not allowlisted: {name}'
        path = ROOT / name
        if entry['old'] is None:
            assert not path.exists(), f'Unexpected existing file: {name}'
            before = b''
        else:
            before = path.read_bytes()
            assert sha(before) == entry['old'], f'Base mismatch: {name}'
        lines = before.decode('utf-8').splitlines(keepends=True)
        limit = len(lines)
        for start, end, replacement in reversed(entry['edits']):
            assert isinstance(start, int) and isinstance(end, int)
            assert 0 <= start <= end <= limit
            limit = start
            lines[start:end] = [replacement]
        output = ''.join(lines).encode('utf-8')
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(output)

# This one final allowlist is authoritative, including sequential corrections.
for name, digest in expected.items():
    assert sha((ROOT / name).read_bytes()) == digest, f'Final source mismatch: {name}'
print('PASS: reviewed base hashes and all 33 final source hashes.')
