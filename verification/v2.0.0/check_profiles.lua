package.path=arg[1]..'/?.lua;'..package.path
local dir=arg[2]
local H=dofile(dir..'/colour_values.lua').extend(dofile(dir..'/hardware_colours.lua'))
local Profiles=dofile(dir..'/profiles.lua')
local Json=require('src.link.Json');local V=require('src.core.GameVersion')
local Runtime={safeMode=false};local files={};local fail=false;local damaged=false;local reads,writes=0,0
local cache={}
function cache:read(p)reads=reads+1;return files[p]end
function cache:delete(p)files[p]=nil;return true end
function cache:info(p)return files[p]and{type='file',size=#files[p]}end
function cache:write(p,b)writes=writes+1;if fail then files[p]='INCOMPLETE';return false,'DISK FULL'end;files[p]=damaged and b:sub(1,10)or b;return true end
local count=0
local function check(a,msg)assert(a,msg);count=count+1 end
local function eq(a,b,msg)check(a==b,(msg or'')..' got '..tostring(a)..' expected '..tostring(b))end
local raw={bike_colour='rgb:AABBCC',bike_stripes_colour='rgb:0055AA',bike_tyres_colour='original',
 bike_volume=4,riding_area_volume=2,riding_sfx_volume=5,bike_song='game:crystal:Music_Route29',riding_music='both',bike_filter=2,
 bike_song_resume=true,auto_mount=false,sfx_filter=3,spelling='us'}
local history={red={played=true},blue={played=true},crystal={played=true},firered={played=true,raw={bike_colour='rgb:112233',bike_volume=3,bike_song='game:firered:MUS_CYCLING',riding_music='bicycle'}}}
local function new(id)
 V.set(id)
 local o={musicVol=6,sfxVol=4,modOptions={autobike_plus_test=raw}}
 local g={options=o,save={options=o,player={name='SENTINEL'}},mods={modOptions={autobike_plus_test=raw},events={emit=function()end}},writes=0}
 function g:writeOptions()self.writes=self.writes+1 end
 local mod={id='autobike_plus_test',cache=cache,game=g}
 local p=Profiles.init(mod,H,{Runtime=Runtime,historical=function()return history end})
 return g,p
end
local g,p=new('red');check(p.ensure(g));eq(p.selection('audio'),'red');eq(p.get('bike_song'),'game:crystal:Music_Route29')
eq(p.selection('bike_colour'),'red');eq(p.get('bike_colour'),'rgb:AABBCC')
eq(p.get('bike_volume'),4)
local ss=p.snapshot();check(ss.profiles.blue.audio~=ss.profiles.red.audio);eq(ss.profiles.gold.audio,nil)
eq(ss.games.gold.parts.bike_colour,'original');eq(ss.profiles.firered.colours.bike_colour,'rgb:112233')
for _,id in ipairs(Profiles.ORDER)do
 local gg,pp=new(id);check(pp.ensure(gg))
 local order=pp.order();eq(order[1],'original');eq(order[2],id);eq(#order,9)
 local expected={'original',id};for _,x in ipairs(Profiles.ORDER)do if x~=id then expected[#expected+1]=x end end
 for i,x in ipairs(expected)do eq(order[i],x)end
 for _,key in ipairs(Profiles.COLOURS)do
  check(pp.select(gg,key,'original'));eq(pp.get(key),'original')
  for _,target in ipairs(Profiles.ORDER)do
   check(pp.select(gg,key,target));eq(pp.selection(key),target)
   local v=('rgb:%06X'):format(count*311%16777216);check(pp.set(gg,key,v));eq(pp.get(key),v)
   eq(pp.snapshot().profiles[target].colours[key],v)
  end
  local before=pp.snapshot().profiles.leafgreen.colours[key]
  check(pp.select(gg,key,'original'));eq(pp.get(key),'original');eq(pp.snapshot().profiles.leafgreen.colours[key],before)
 end
 for _,target in ipairs(Profiles.ORDER)do
  check(pp.select(gg,'audio',target));eq(pp.selection('audio'),target)
  for _,key in ipairs({'bike_volume','riding_area_volume','riding_sfx_volume'})do
   for value=0,7 do check(pp.set(gg,key,value));eq(pp.get(key),value);eq(pp.snapshot().volumes[key],value)end
  end
  for _,mode in ipairs({'area','bicycle','both'})do
   local bv=pp.get('bike_volume');check(pp.set(gg,'riding_music',mode));eq(pp.get('bike_volume'),bv)
  end
  check(pp.set(gg,'bike_song','game:leafgreen:MUS_CYCLING'));check(pp.set(gg,'bike_filter',3))
 end
 check(pp.select(gg,'audio','original'));eq(pp.get('bike_song'),'original');eq(pp.get('riding_music'),'bicycle');eq(pp.get('bike_filter'),0)
 eq(pp.get('bike_volume'),7);eq(pp.get('riding_sfx_volume'),7)
 check(pp.set(gg,'bike_volume',0));eq(pp.selection('audio'),id);eq(pp.get('bike_volume'),0)
 check(pp.select(gg,'audio','original'));eq(pp.get('bike_volume'),0)
 check(pp.resetColours(gg));for _,k in ipairs(Profiles.COLOURS)do eq(pp.get(k),'original')end
 eq(gg.writes,0,'profiles must not use progress/options writer')
end
-- Cross-game live references and per-game remembered selectors.
local r,pr=new('red');pr.ensure(r);pr.select(r,'bike_colour','red');pr.set(r,'bike_colour','rgb:FF0000');pr.select(r,'audio','red');pr.set(r,'bike_song','game:gold:Music_Bicycle')
local f,pf=new('firered');pf.ensure(f);pf.select(f,'bike_colour','red');eq(pf.get('bike_colour'),'rgb:FF0000');pf.set(f,'bike_colour','rgb:0011FF')
pf.select(f,'audio','red');pf.set(f,'bike_song','game:firered:MUS_PALLET')
local r2,pr2=new('red');pr2.ensure(r2);eq(pr2.selection('bike_colour'),'red');eq(pr2.get('bike_colour'),'rgb:0011FF');eq(pr2.get('bike_song'),'game:firered:MUS_PALLET')
-- A newly-played game stays Original and cannot be seeded by today's flat mirror.
files={};history={red={played=true}}
local a,pa=new('red');pa.ensure(a);pa.set(a,'bike_volume',2);pa.set(a,'bike_colour','rgb:FE0122')
local s,ps=new('silver');ps.ensure(s);eq(ps.selection('audio'),'original');eq(ps.selection('bike_colour'),'original');eq(ps.get('bike_volume'),2)
eq(ps.get('bike_song'),'original');eq(ps.snapshot().profiles.silver.audio,nil)
check(ps.select(s,'audio','red'));eq(ps.get('bike_volume'),2)
-- Failed writes are not committed in memory; previous journal remains readable.
local before=Json.encode(ps.snapshot());fail=true;check(not ps.set(s,'bike_volume',7));eq(Json.encode(ps.snapshot()),before);fail=false
local q,pq=new('silver');pq.ensure(q);eq(pq.get('bike_volume'),2)
Runtime.safeMode=true;local w=writes;check(not pq.set(q,'bike_volume',3));eq(writes,w);Runtime.safeMode=false
-- Malformed values, malformed profile names and path traversal cannot be saved.
for _,bad in ipairs({'../../red','RED','unknown','',123})do check(not pq.select(q,'audio',bad))end
for _,bad in ipairs({-1,8,0/0,math.huge,2.4,'x'})do check(not pq.set(q,'bike_volume',bad))end
check(not pq.set(q,'bike_colour','rgb:GG0000'))
-- Failed first writes and readback corruption must never expose unsaved values.
files={};fail=true;local ig,ip=new('red');check(not ip.ensure(ig));eq(ip.snapshot(),nil)
fail=false;check(ip.ensure(ig));check(ip.snapshot()~=nil)
local initialSeq=ip.snapshot().seq;damaged=true;check(not ip.set(ig,'bike_volume',6));eq(ip.snapshot().seq,initialSeq);damaged=false
local rg,rp=new('red');check(rp.ensure(rg));eq(rp.snapshot().seq,initialSeq)
print('PASS shared profiles unit/state matrix assertions='..count..' writes='..writes)
