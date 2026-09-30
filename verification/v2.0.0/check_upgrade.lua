package.path=arg[1]..'/?.lua;'..package.path
local dir=arg[2];local Json=require('src.link.Json');local V=require('src.core.GameVersion')
local H=dofile(dir..'/colour_values.lua').extend(dofile(dir..'/hardware_colours.lua'))
local Profiles=dofile(dir..'/profiles.lua');local Upgrade=dofile(dir..'/public_upgrade.lua')
local n=0;local function ck(v,m)assert(v,m);n=n+1 end
local function cp(t)local r={};for k,v in pairs(t)do r[k]=v end;return r end
local function equal(a,b)for k,v in pairs(a)do ck(b[k]==v,'Protected source changed: '..k)end;for k in pairs(b)do ck(a[k]~=nil,'Unexpected source write: '..k)end end
local function fixture()
 local ownFiles,testFiles={},{};local blocked;local RT={safeMode=false};local writes=0
 local function cache(files)
  return{read=function(_,p)return files[p]end,info=function(_,p)return files[p]and{type='file',size=#files[p]}end,
   write=function(_,p,b)if p==blocked then return false,'SIMULATED FULL DISK'end;files[p]=b;writes=writes+1;return true end,
   delete=function(_,p)files[p]=nil;return true end}
 end
 local tc,pc=cache(testFiles),cache(ownFiles)
 V.set('red')
 local o={musicVol=3,modOptions={autobike_plus_test={auto_mount=false,spelling='us',sfx_filter=2},bicycle_plus={auto_mount=true,spelling='uk',sfx_filter=0}}}
 local g={options=o,save={options=o,player={name='PROTECTED'}},mods={modOptions={autobike_plus_test=o.modOptions.autobike_plus_test,bicycle_plus=o.modOptions.bicycle_plus}}}
 function g:writeOptions()self.optionWrites=(self.optionWrites or 0)+1;return true end
 local pp=Profiles.init({id='autobike_plus_test',cache=tc},H,{Runtime=RT,historical=function()return{}end})
 ck(pp.ensure(g));ck(pp.select(g,'bike_colour','red'));ck(pp.set(g,'bike_colour','rgb:2244FF'))
 ck(pp.set(g,'bike_volume',0));ck(pp.set(g,'bike_song','game:leafgreen:MUS_CYCLING'))
 local dig=string.rep('a',64);local bytes='VALID GENERATED MOCK AUDIO';testFiles['music/index-a.json']=Json.encode({format=1,seq=1,tracks={{id='file:'..dig,ext='wav',name='My Test Song'}}})
 testFiles['music/tracks/'..dig..'.wav']=bytes
 local imports=0
 _G.__releaseLibrary={hash=function(b)return b==bytes and dig or string.rep('b',64)end,init=function()
  return{importBytes=function(b,name)
   imports=imports+1;local ok,e=pc:write('music/tracks/'..dig..'.wav',b);if not ok then return nil,e end
   return{id='file:'..dig}
  end,rename=function(id,name)return pc:write('mock-renamed-song',name)end,shutdown=function()end}
 end}
 local mod={id='bicycle_plus',cache=pc,game=g,read=function(_,p)
  if p=='song_library.lua'then return'return _G.__releaseLibrary' end
  local f=assert(io.open(dir..'/'..p));local b=f:read('*a');f:close();return b
 end}
 local services={Runtime=RT,Cache={readAt=function(path)
  local prefix='mod_cache/autobike_plus_test/';ck(path:sub(1,#prefix)==prefix,'Unsafe source path');return testFiles[path:sub(#prefix+1)]
 end},Save={persistenceFs=function()return nil end}}
 return{own=ownFiles,old=testFiles,mod=mod,g=g,p=pp,RT=RT,
  new=function()return Upgrade.init(mod,H,services)end,
  block=function(p)blocked=p end,writes=function()return writes end,imports=function()return imports end,dig=dig}
end
-- Adopt shared settings/media once, retain source, preserve explicit OFF and
-- defer flat native options until the actual game/loader objects exist.
for _,id in ipairs(Profiles.ORDER)do
 local f=fixture();V.set(id);local before=cp(f.old)
 local u=f.new();ck(u.prepare(),u.error)
 ck(f.own['music/tracks/'..f.dig..'.wav']==f.old['music/tracks/'..f.dig..'.wav'],'Music copy missing')
 local copied=Json.decode(f.own['profiles/v1-a.json']);ck(copied.profiles.red.colours.bike_colour=='rgb:2244FF');ck(copied.profiles.red.audio.bike_volume==0)
 local mods=f.g.mods;f.g.mods=nil;ck(not u.options(f.g));f.g.mods=mods
 ck(u.options(f.g));ck(f.g.options.modOptions.bicycle_plus.auto_mount==false);ck(f.g.options.modOptions.bicycle_plus.spelling=='us')
 ck(f.g.options.modOptions.bicycle_plus.sfx_filter==2);ck(f.g.save.player.name=='PROTECTED')
 equal(before,f.old)
 local count=f.writes();f.g.options.modOptions.bicycle_plus.auto_mount=true
 local again=f.new();ck(again.prepare());ck(not again.options(f.g));ck(f.writes()==count,'Repeated upgrade writes');ck(f.g.options.modOptions.bicycle_plus.auto_mount==true,'Public edit reset')
end
-- New public-only installs keep legacy preferences; no test-related reset.
do local f=fixture();for p in pairs(f.old)do f.old[p]=nil end;local u=f.new();ck(u.prepare());ck(not u.options(f.g));ck(f.g.options.modOptions.bicycle_plus.auto_mount==true);ck(not f.own['profiles/v1-a.json'])end
-- Existing public journals win, even when old local-test data is still present.
do local f=fixture();f.own['profiles/v1-a.json']=f.old['profiles/v1-a.json'];local before=cp(f.own);local u=f.new();ck(u.prepare());ck(not u.options(f.g));ck(f.own['profiles/v1-a.json']==before['profiles/v1-a.json']);ck(f.imports()==0)end
-- Failed/partial adoption is retryable, with old test data intact. Only profile
-- and mod-cache writes occur; no native progress-save operation is used.
for _,blocked in ipairs({'release/v2-adoption.json','music/tracks/'..string.rep('a',64)..'.wav','profiles/v1-a.json','profiles/v1-b.json'})do
 local f=fixture();local source=cp(f.old);f.block(blocked);local u=f.new();ck(not u.prepare(),'Failure was ignored: '..blocked);equal(source,f.old)
 f.block(nil);u=f.new();ck(u.prepare(),u.error);ck(u.options(f.g));ck(f.g.options.modOptions.bicycle_plus.auto_mount==false);equal(source,f.old)
end
do local f=fixture();f.RT.safeMode=true;local count=f.writes();ck(f.new().prepare());ck(f.writes()==count)end
do local f=fixture();f.old['profiles/v1-a.json']='broken';f.old['profiles/v1-b.json']='broken';local count=f.writes();ck(not f.new().prepare());ck(f.writes()==count)end
do local f=fixture();f.own['release/v2-adoption.json']='broken';ck(not f.new().prepare());ck(f.own['release/v2-adoption.json']=='broken')end
do local f=fixture();f.old['music/tracks/'..f.dig..'.wav']='CORRUPTED';ck(not f.new().prepare());ck(not f.own['profiles/v1-a.json'])end
print('PASS public-upgrade storage, one-time adoption, false/zero, retry and source-isolation checks: '..n)
