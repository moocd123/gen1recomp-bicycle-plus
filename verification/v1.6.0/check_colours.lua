local engine=assert(arg[1]);package.path=engine..'/?.lua;'..engine..'/?/init.lua;'..package.path
local P=dofile('hardware_colours.lua');local n=0
local function check(v,s)assert(v,s);n=n+1 end
local seen={}
for w=0,32767 do
 local r,g,b=P.unpack(w);check(P.pack(r,g,b)==w,'RGB555 round trip')
 local id=P.id(w);local c=P.rgb(id);local hex=P.hex(id)
 check(not seen[hex],'unique RGB');seen[hex]=true
 check(P.fromRGB(table.unpack(c))==id,'lossless code expansion')
end
local rows,byId=P.presets({data={}});check(rows[1].id=='original','Original first')
local last=-2;seen={}
for _,r in ipairs(rows)do
 check(P.codeKey(r.id)>last,'RRGGBB code order');last=P.codeKey(r.id)
 check(not seen[r.id],'global deduplication');seen[r.id]=true
 check(not r.label:find('SKIN',1,true) and #r.label<=18,'full unambiguous names fit')
end
local groupIds={'dmg','pocket','light','gbc','trainer'};seen={};local total=0
for i,group in ipairs(P.sections(rows))do
 check(group.id==groupIds[i],'chronological system sections plus Trainer')
 last=-2
 for _,r in ipairs(group.rows)do
  check(not seen[r.id],'no duplicates across sections');seen[r.id]=true;total=total+1
  check(P.codeKey(r.id)>last,'hex order inside section');last=P.codeKey(r.id)
  if group.id=='trainer' then check(r.label:match('^TRAINER '),'full TRAINER label')end
 end
end
check(total==#rows-1,'every non-Original preset has exactly one section')
for _,ref in ipairs(P.trainer)do
 local id=P.fromRGB(table.unpack(ref[2]));check(byId[id]~=nil,'every trainer reference included')
 check(byId[id].section=='trainer' and byId[id].label:match('^TRAINER '),'trainer ownership beats GBC duplicate')
end
last=-2
for _,r in ipairs(P.quickChoices)do check(P.codeKey(r[2])>last,'quick colours sorted');last=P.codeKey(r[2])end
for _,r in ipairs(P.legacy)do check(P.canonical(r[1])==P.fromRGB(table.unpack(r[3])),'saved aliases retained')end
local saved
for w=0,32767 do if not byId[P.id(w)]then saved=P.id(w);break end end
local custom=P.presets({data={}},nil,saved);last=-2
for _,r in ipairs(custom)do check(P.codeKey(r.id)>last,'saved custom swatch also sorted');last=P.codeKey(r.id)end
print(('PASS: %d colour/catalogue checks; 32768 unique RGB555 colours; %d unique presets partitioned into five sections.'):format(n,#rows-1))
