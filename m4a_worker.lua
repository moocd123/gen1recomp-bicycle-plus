-- AUTOBIKE+ independent, data-only M4A synthesis worker.
-- The compute permission explicitly enables this private Lua state. This code
-- calls only the host's pure decoder/mixer, never Game3, a game save, the native
-- audio singleton, or a shared BGM channel. No user-supplied code is evaluated.
require('love.thread');require('love.sound');require('love.timer');require('love.filesystem')
local cmdName,outName,statusName=...
local cmd=love.thread.getChannel(cmdName)
local out=love.thread.getChannel(outName)
local status=love.thread.getChannel(statusName)
local function engine(name)
 local value=package.loaded[name]
 if value then return value end
 local chunk=assert(love.filesystem.load(name:gsub('%.','/')..'.lua'))
 value=chunk();package.loaded[name]=value;return value
end
local ok,err=xpcall(function()
 engine('src.core.game3.m4a_mix');engine('src.core.game3.m4a_sample');engine('src.core.game3.m4a_seq')
 local P=engine('src.core.game3.m4a_player')
 local root='data/generated/gba/audio'
 local pack,cache,slot,id,epoch
 local running=true;local playing=false;local looping=true;local mono=false
 local function reset()
  slot={voices={}}
  assert(P.start(pack,cache,slot,id,{forceSeq=true}),'Could not initialise GBA song')
 end
 while running do
  local m=cmd:pop()
  while m do
   if m.op=='quit'then running=false;break
   elseif m.op=='install'then
    assert(type(m.index)=='string'and #m.index<8388608,'Invalid music index')
    assert(type(m.samples)=='string'and #m.samples<67108864,'Invalid sample bank')
    assert(type(m.sequence)=='string'and #m.sequence<8388608,'Invalid sequence')
    id=assert(tonumber(m.id));epoch=m.epoch;looping=true;mono=m.mono==true
    local files={[root..'/index.lua']=m.index,[root..'/samples.bin']=m.samples,
      [root..'/songs/'..id..'.bin']=m.sequence}
    cache={read=function(_,path)return files[path]end}
    pack=assert(P.loadPack(cache,root));reset();status:push({ready=true,epoch=epoch,rate=P.SAMPLE_RATE})
   elseif m.op=='resume'then playing=true
   elseif m.op=='pause'then playing=false
   elseif m.op=='reset'then epoch=m.epoch;playing=false;out:clear();reset()
   elseif m.op=='loop'then looping=m.value~=false
   elseif m.op=='mix'then mono=m.mono==true
   end
   m=cmd:pop()
  end
  if not running then break end
  if playing and pack and out:getCount()<8 then
   if slot.done and #(slot.voices or{})==0 then
    if looping then reset()else playing=false;status:push({ended=true,epoch=epoch})end
   end
   if playing then
    local data=P.renderBuffered(slot,4096,{sampleRate=P.SAMPLE_RATE,master=1,mono=mono})
    assert(data,'GBA synthesis produced no PCM')
    out:push({data=data,epoch=epoch});data:release()
   end
  else love.timer.sleep(.002)end
 end
end,debug.traceback)
if not ok then status:push({error=tostring(err)})end
out:clear()
