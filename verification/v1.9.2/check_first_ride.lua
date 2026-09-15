-- Production main/audio/library, native Loader/Runtime/Music. Mocked Sources,
-- sprites and player movement. Tests settings and routing, not sound quality.
local T=dofile('verification/v1.9.0/support.lua').init(assert(arg[1]))
local noop=function()end
love.graphics={setColor=noop,rectangle=noop,push=noop,pop=noop,transformPoint=function(x,y)return x,y end,intersectScissor=noop,getDimensions=function()return 160,144 end}
love.keyboard={isDown=function()return false end}
package.loaded['src.render.Assets']={register=noop}
package.loaded['src.render.Font']={draw=noop,drawBox=noop,drawCode=noop}
package.loaded['src.ui.Theme']={cursor=1}
package.loaded['src.render.PaletteFX']={wholeNamed=function()return{}end,mode='redpp',setMode=noop}
package.loaded['src.render.GbcPalette']={mode='gbc',setMode=noop}
package.loaded['src.core.ChipAudio']={isSuspended=function()return false end,stopMusic=noop,holdMusic=noop,currentSource=function()end}
package.loaded['src.core.ChipSynth']={SAMPLE_RATE=44100,getStereo=function()return false end}
local Loader=require('src.mods.Loader');local Manifest=require('src.mods.Manifest')
local n=0;local function ck(v,m)assert(v,m);n=n+1 end
local service=[[return{init=function()return{update=function()end,status=function()return{}end,
 previewZones=function()return{}end,needsColourMode=function()return false end,drawPreview=function()return true end}end}]]
for _,edition in ipairs({'red','blue','yellow','gold','silver','crystal'})do
 require('src.core.GameVersion').set(edition)
 for volume=0,7 do
  package.loaded['src.core.Music']=nil
  local Sound={setVolumeLevel=noop,isPlaying=function()return false end,ducksMusic=function()return true end}
  for _,name in ipairs({'play','playStereo','playMove','playCry','playPikaCry','startLoop'})do Sound[name]=noop end
  package.loaded['src.core.Sound']=Sound
  local Music=require('src.core.Music');local baseline=Music.play
  local gen2=edition=='gold'or edition=='silver'or edition=='crystal'
  local suffix=edition..volume
  local map,bike='test-map-'..suffix..'.wav','test-bike-'..suffix..'.wav'
  T.files[map]='RIFF0000WAVE'..string.rep('map',100);T.files[bike]='RIFF0000WAVE'..string.rep('bike',100)
  local data={audio={songs={Music_PalletTown={file=map},Music_BikeRiding={file=bike}},mapSongs={PALLET='Music_PalletTown'}},screens={}}
  if gen2 then data.audio.generation=2;data.audio.songs.Music_Bicycle={file=bike}end
  local g={data=data,input={},stack={top=function()return{}end},overworld={map={id='PALLET'},player={}},writes=0}
  if gen2 then g.world={map={id='PALLET'},playerState='walk',player={}}end
  function g:writeOptions()self.writes=self.writes+1 end
  local l=Loader.new({fs=T.fs,game=g,generation=gen2 and 2 or 1});l.game=g;g.mods=l
  T.Runtime.install(l.events,l.hooks)
  local record={path='mods/bicycle_plus',manifest=Manifest.validate({id='bicycle_plus',name='AUTOBIKE+',version='1.9.2',api=2,entry='main.lua',games={edition},permissions={'engine_internals','filesystem'}},'bicycle_plus')}
  local mod=l:_api(record);mod.env=l:_modEnv(record)
  function mod:read(p)if p=='automount.lua'or p=='colours.lua'then return service end;return T.readDisk(p)end
  function mod.content.screens:register(k,v)g.data.screens[k]=v end
  T.load(mod,'main')(mod)
  -- Gen 1 loads entry chunks before the save/options are attached.
  ck(g.writes==0,'entry stored a premature bike volume')
  g.save={onBike=false,options={musicVol=volume,musicFilter=0,sfxVol=5,modOptions={}}};g.options=g.save.options
  Music.setVolumeLevel(volume);Music.setFilterLevel(0);Sound.setVolumeLevel(5)
  l.events:emit('game.ready',{game=g})
  local settings=l.modOptions.bicycle_plus;local audio=mod.exports.audio
  ck(settings.riding_music=='bicycle'and settings.bike_volume==volume and settings.auto_mount==true,'first-ride defaults incorrect')
  local function source(path,playing)
   for i=#T.audio.sources,1,-1 do local s=T.audio.sources[i];if s.path==path and not s.released and (not playing or s.playing)then return s end end
  end
  local function mount(on)
   g.save.onBike=on;if gen2 then g.world.playerState=on and'bike'or'walk'end
   Music.playMap(data,'PALLET',on,false);mod.exports.update(g,.016)
  end
  mount(true)
  ck(source(map).volume==0,'area audible with fresh bicycle-only default')
  local bs=source(bike,true)
  ck((bs~=nil)==(volume>0),'OFF was ignored or the bike was missing')
  if bs then ck(math.abs(bs.volume-.7*volume/7)<1e-10,'bike did not inherit Music gain')end
  mount(false)
  ck(not source(bike,true)and math.abs(source(map).volume-.7*volume/7)<1e-10,'off-bike music failed to restore')
  g.save.options.musicVol=6;Music.setVolumeLevel(6)
  mount(true)
  ck(settings.bike_volume==volume,'normal music edit changed stored bike gain')
  mod.exports.setSetting(g,'riding_music','both')
  audio.update(g,.016)
  ck(math.abs(source(map).volume-.6)<1e-10,'BOTH did not follow normal area via SAME')
  bs=source(bike,true);if bs then ck(math.abs(bs.volume-.7*volume/7)<1e-10,'BOTH changed bike gain')end
  mod.exports.setSetting(g,'riding_music','area');audio.update(g,.016)
  ck(not source(bike,true)and math.abs(source(map).volume-.6)<1e-10,'AREA selection wrong')
  ck(settings.bike_volume==volume and g.save.options.musicVol==6,'selector edited stored gains')
  audio.dispose();ck(Music.play==baseline,'audio cleanup failed')
 end
end
print(('PASS %d first-ride and off-bike gain/routing assertions in 48 volume/edition cases. Playback devices and movement are simulated.'):format(n))
