-- File-safety regression: software filesystem, not a power-loss/device test.
local T=dofile('verification/v1.8.0/test_support.lua').init(assert(arg[1]))
local L=dofile('song_library.lua')
local Json=require('src.link.Json')
local protected={
 ['save.lua']='PLAYER PROGRESS', ['saves/red/slot1.lua']='PARTY INVENTORY BADGES',
 ['options.lua']='GLOBAL SETTINGS', ['picked_rom.gb']='PENDING ROM',
 ['picked_save.sav']='PENDING SAVE', ['picked_mod.zip']='PENDING MOD',
 ['mods/another_mod/main.lua']='UNRELATED MOD', ['original-song.wav']='ORIGINAL FILE',
}
for path,data in pairs(protected)do T.files[path]=data end
local allowed={['pick_complete.flag']=true,['pick_error.flag']=true,
 [L.PENDING]=true,[L.PENDING..'.part']=true}
local n=0
local function ck(v,m)assert(v,m);n=n+1 end
local baseWrite,baseRemove,baseDir=T.fs.write,T.fs.remove,T.fs.createDirectory
local function within(path)
 return type(path)=='string'and not path:find('..',1,true)and
 (path==L.ROOT or path:sub(1,#L.ROOT+1)==L.ROOT..'/' or allowed[path])
end
T.fs.write=function(p,b)ck(within(p),'write outside owned storage: '..tostring(p));return baseWrite(p,b)end
T.fs.remove=function(p)ck(within(p),'delete outside owned storage: '..tostring(p));return baseRemove(p)end
T.fs.createDirectory=function(p)ck(within(p),'mkdir outside owned storage');return baseDir(p)end
local lib=L.init({})
local bytes='RIFF1234WAVE'..string.rep('safe-test',100)
local row=assert(lib.importBytes(bytes,'original-song.wav'))
ck(lib.rename(row.id,'new name'),'rename')
ck(lib.remove(row.id),'remove')
for _,bad in ipairs({'../save.lua','/save.lua','folder/../../options.lua','folder\\..\\save.lua','C:/save.lua'})do
 ck(not lib.importInbox(bad),'path traversal accepted')
end
-- A corrupt index must not supply an arbitrary deletion path.
T.files[L.ROOT..'/index-a.json']=Json.encode({format=1,seq=10,tracks={{id='file:../../save.lua',ext='wav',name='bad'}}})
T.files[L.ROOT..'/index-b.json']='malformed'
local clean=L.init({});ck(#clean.files()==0,'unsafe index accepted')
ck(not clean.remove('file:../../save.lua'),'unsafe deletion accepted')
-- Failed next-index write leaves the previous valid catalogue recoverable.
local first=assert(clean.importBytes(bytes,'first.wav'))
local previousWrite=T.fs.write
T.fs.write=function(p,b)
 if p==L.ROOT..'/index-b.json'then baseWrite(p,'{incomplete');return nil,'simulated disk failure'end
 return previousWrite(p,b)
end
ck(not clean.rename(first.id,'not committed'),'failed write succeeded')
ck(L.init({}).describe(first.id)=='first','previous index was not recovered')
T.fs.write=previousWrite
-- Native completion only consumes this mod's temporary destination/marker.
love.system.pickFileKinds=function()return'rom,mod,sav,required_import'end
love.system.pickFile=function(kind,path)ck(kind=='required_import'and path==L.PENDING,'shared game staging used');return true end
ck(clean.chooseFile()=='pending','native pick')
T.files[L.PENDING]='ID3'..string.rep('native',100)
T.files['pick_complete.flag']='v1\n'..L.PENDING..'\n'..string.rep('a',32)..'\n603\n'
ck(clean.poll(),'native complete')
for path,data in pairs(protected)do ck(T.files[path]==data,'protected file changed: '..path)end
ck(not L.valid('game:red:../../save.lua'),'invalid song ID')
print(('PASS %d storage-safety assertions: protected saves/options/ROMs/source files unchanged; bounded owned writes, traversal rejection and interrupted-index recovery. Simulated filesystem only.'):format(n))
