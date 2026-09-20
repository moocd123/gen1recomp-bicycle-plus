"""Read-only feasibility audit of pinned engine source; never handles ROMs."""
from pathlib import Path
import re, subprocess, sys
engine, mod = map(Path, sys.argv[1:3])
# The experiment has no runtime edits and cannot overwrite production releases.
changed = subprocess.check_output(['git','-C',str(mod),'diff','--name-only','9233e841e16bae164e3163840aa0c876d6c1537b','HEAD'],text=True).splitlines()
assert all(p.startswith('gen3_lab/') or p=='.github/workflows/gen3-lab.yml' for p in changed), changed
print('PASS: production runtime, manifest and publishing workflows are unchanged.')
files = ['src/core/Game3.lua','src/core/game3/player.lua','src/core/game3/item_use.lua',
 'src/core/game3/field_view.lua','src/core/game3/map.lua','src/core/game3/runtime.lua',
 'src/core/game3/audio.lua','src/core/game3/m4a_player.lua','src/ui/game3/option_rows.lua',
 'src/ui/game3/stack.lua','src/ui/game3/window.lua','src/ui/game3/frlg_font.lua',
 'src/mods/Gen3Compat.lua']
for name in files:
    p=engine/name
    if not p.is_file(): print('MISSING',name);continue
    print('\n###',name)
    for num,line in enumerate(p.read_text().splitlines(),1):
        if re.match(r'^function ',line) or 'COVERAGE[' in line or re.search(r'ModRuntime\.(call|emit|wants)|Runtime\.(call|emit)',line):
            print(f'{num}: {line}')
    if name.endswith(('field_view.lua','option_rows.lua','map.lua')):
        lines=p.read_text().splitlines()
        for i,line in enumerate(lines):
            if any(s in line for s in ['playerGraphicsId','OwSprites.draw','biking','ui.options','player.before_draw']):
                print('CONTEXT',i+1,'\n'+'\n'.join(lines[max(0,i-4):i+8]))
print('\n### Native Gen 3 test files')
for p in sorted((engine/'tests').rglob('*')):
    if p.is_file() and re.search(r'gen3|game3|firered',str(p)) and re.search(r'mod|bike|option|audio|sprite',p.name):
        print(p.relative_to(engine))
