#!/usr/bin/env python3
"""Restore only the approved, hash-checked public-release source files."""
from pathlib import Path
import hashlib
import json
import lzma
import subprocess

XZ_SHA = '1aad4b4d6b27303c332617933da6139485ee039857525675e7a0efc6405e04a5'
JSON_SHA = 'aae0e228331b37b384763d10cebf63bdfe373e07c364d3bb39bf23499b552ebb'
BASES = {'9233e841e16bae164e3163840aa0c876d6c1537b',
         '79f920167249fe9bc082ef495446ce35b3eaac51'}
NOTES_BLOB = 'dd122e3d6bfeaab37751698dcd7948406cd87c46'

def sha(data):
    return hashlib.sha256(data).hexdigest()

def safe(name):
    path = Path(name)
    if not isinstance(name, str) or path.is_absolute() or '..' in path.parts or '\\' in name:
        raise ValueError('Unsafe source path')
    if name != path.as_posix() or name.startswith('.git/') or path.suffix not in ('.lua', '.py', '.md', '.json') and name != 'LICENSE':
        raise ValueError('Unexpected source path: ' + name)
    return path

def plan(root, stage, read_git=None):
    packed = b''.join((stage / ('payload-%d.part' % i)).read_bytes() for i in range(1, 6))
    assert sha(packed) == XZ_SHA, 'Compressed payload hash mismatch'
    raw = lzma.decompress(packed)
    assert sha(raw) == JSON_SHA, 'Operation payload hash mismatch'
    operations = json.loads(raw)
    assert len(operations) == 49
    if read_git is None:
        def read_git(ref, path=None):
            cmd = ['git', 'show', ref + ':' + path] if path else ['git', 'cat-file', 'blob', ref]
            return subprocess.check_output(cmd, cwd=root)
    outputs = []
    seen = set()
    for op in operations:
        name = op['path']; dest = root / safe(name)
        assert name not in seen, 'Duplicate source file: ' + name
        seen.add(name)
        assert sum(key in op for key in ('body', 'base', 'blob')) == 1
        if 'body' in op:
            data = op['body'].encode('utf-8')
        elif 'blob' in op:
            assert name == 'RELEASE_NOTES_v2.0.0.md' and op['blob'] == NOTES_BLOB
            data = read_git(NOTES_BLOB)
        else:
            ref, source, digest = op['base']
            assert ref in BASES
            safe(source)
            data = read_git(ref, source)
            assert sha(data) == digest, 'Pinned source mismatch: ' + name
            lines = data.decode('utf-8').splitlines(keepends=True)
            limit = len(lines)
            for start, end, replacement in reversed(op.get('edits', [])):
                assert 0 <= start <= end <= limit, 'Overlapping source edit: ' + name
                lines[start:end] = replacement.splitlines(keepends=True)
                limit = start
            data = ''.join(lines).encode('utf-8')
        assert sha(data) == op['sha256'], 'Final source mismatch: ' + name
        outputs.append((dest, data))
    return outputs

if __name__ == '__main__':
    stage = Path(__file__).resolve().parent
    root = stage.parents[2]
    outputs = plan(root, stage)
    # Validate the complete result before replacing any runtime file.
    for dest, data in outputs:
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(data)
    (stage / 'source-paths.json').write_text(json.dumps([str(p.relative_to(root)) for p, _ in outputs]))
    print('PASS: 49 approved source files; all pinned inputs and output hashes verified.')
