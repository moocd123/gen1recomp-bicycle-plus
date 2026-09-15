local engine=assert(arg[1]);package.path=engine..'/?.lua;'..package.path
local T=dofile('verification/v1.8.0/support.lua');local R=T.install()
local Sound={volume=7,playing={}}
function Sound.setVolumeLevel(n)Sound.volume=n end
function Sound.ducksMusic(_,name)return name=='fanfare'end
function Sound.isPlaying(name)return Sound.playing[name]end
local Chip={suspended=false};function Chip.isSuspended()return Chip.suspended end
function Chip.holdMusic()end;function Chip.stopMusic()end;function Chip.currentSource()end
local Synth={SAMPLE_RATE=44100,count=0}
function Synth.getStereo()return false end
function Synth.newEngine(data,def)
 Synth.count=Synth.count+1
 local obj={data=data,def=def,done=false,rendered=0};function obj:finished()return self.done end;return obj
end
function Synth.soundData(engine,n)engine.rendered=engine.rendered+n;return{release=T.noop}end
package.loaded['src.core.Sound']=Sound;package.loaded['src.core.ChipAudio']=Chip;package.loaded['src.core.ChipSynth']=Synth
package.loaded['src.core.Game']={}
local Music=require('src.core.Music')
local function latest(path)
 for i=#T.sources,1,-1 do local s=T.sources[i];if s.path==path and not s.released then return s end end
end
for _,edition in ipairs({'red','blue','yellow','gold','silver','crystal'})do
 local is2=edition=='gold'or edition=='silver'or edition=='crystal'
 local options={musicVol=7,sfxVol=6,musicFilter=0}
 local g={data={audio={songs={Music_PalletTown={file='area.ogg'},Music_BikeRiding={file='bike.ogg'},Battle={file='battle.ogg'}},mapSongs={A='Music_PalletTown'},special={bike='Music_BikeRiding'}}},save={options=options,onBike=true},stack={}}
 local top={};function g.stack:top()return top end
 local world={map={id='A'},player={}}
 if is2 then world.playerState='bike';g.world=world;g.options=options else g.overworld=world end
 local function ride(on)if is2 then world.playerState=on and'bike'or'walk'else g.save.onBike=on end end
 local set={bike_volume=7,bike_filter=0,sfx_filter=0,riding_music='bicycle',riding_area_volume=-1,riding_area_filter=-1,riding_sfx_volume=-1,riding_sfx_filter=-1,bike_song='custom',bike_song_restart='resume'}
 local L={revision=0,error=nil,resolve=function(_,id)
  if id=='missing'then return nil,'missing song'end
  local def=id=='chip'and{chip={}}or id=='intro'and{file='intro.ogg',loopFile='loop.ogg'}or{file=id=='bad'and'badfile.wav'or'custom.wav'}
  return{data={audio={songs={[id]=def}}},label=id,def=def}
 end,clear=function()end}
 local m=T.mod();m.game=g
 local A=dofile('audio.lua').init(m,set,L)
 A.update(g,0);Music.playMap(g.data,'A',true,false)
 A.update(g,.016)
 T.check(A.status().layerActive,'riding layer absent '..edition);T.eq(A.status().layerSong,'custom');T.check(A.status().areaSuppressed,'BICYCLE did not mute map')
 local playing=latest('custom.wav');T.check(playing and playing.playing,'custom music not playing')
 -- Independent native-scale gains: all 64 combinations, no saved setting mutation.
 for area=0,7 do for bike=0,7 do
  Music.setVolumeLevel(area);options.musicVol=area;set.bike_volume=bike;A.update(g,.02)
  if bike>0 then T.check(math.abs(latest('custom.wav').volume-.7*bike/7)<1e-12,'bike volume linked to area')end
  T.eq(options.musicVol,area,'save audio changed')
 end end
 set.bike_volume=7;Music.setVolumeLevel(7);set.riding_music='both';A.update(g,.02)
 T.check(not A.status().areaSuppressed,'BOTH suppressed area')
 set.bike_filter=2;set.riding_area_volume=2;set.riding_area_filter=1;set.riding_sfx_volume=3
 A.update(g,.02);T.eq(latest('custom.wav').filter.highgain,.16,'bike filter')
 T.eq(A.status().effectiveAreaVolume,2);T.eq(Sound.volume,3)
 local kept=latest('custom.wav');kept.pos=12;ride(false);Music.playMap(g.data,'A',false,false);A.update(g,.02)
 T.check(not kept.playing and not kept.released and A.status().parked,'RESUME not parked')
 T.check(not A.status().areaSuppressed,'off-bike area still suppressed');T.eq(Sound.volume,6)
 ride(true);Music.playMap(g.data,'A',true,false);A.update(g,.02)
 T.eq(latest('custom.wav'),kept,'resume recreated source');T.eq(kept.pos,12,'resume position reset');T.check(kept.playing,'resume not playing')
 -- Battles restore normal profile immediately; resume may keep paused custom source.
 Music.play(g.data,'Battle',true,{reason='battle'});A.update(g,.02)
 T.check(not kept.playing and not A.status().areaSuppressed,'bike bled into battle');T.eq(Sound.volume,6)
 Music.playMap(g.data,'A',true,false);A.update(g,.02);T.check(kept.playing,'map return failed')
 Sound.playing.fanfare=true;T.events:emit('sound.played',{kind='sfx',name='fanfare'});A.update(g,.02);T.check(not kept.playing,'fanfare did not pause')
 Sound.playing.fanfare=nil;A.update(g,.02);T.check(kept.playing,'fanfare resume failed')
 Chip.suspended=true;A.update(g,.02);T.check(not kept.playing,'audio suspension not respected');Chip.suspended=false;A.update(g,.02)
 -- Preview is temporary, uses bicycle volume/filter, and stops when screen ownership changes.
 local saved=set.bike_song;T.check(A.preview(g,'intro',top),'preview did not start');T.eq(set.bike_song,saved,'preview changed selected song');T.check(A.isPreviewing(),'preview absent')
 local intro=latest('intro.ogg');intro.playing=false;A.update(g,.02);T.check(latest('loop.ogg').playing,'intro-loop transition')
 top={};A.update(g,.02);T.check(not A.isPreviewing(),'preview leaked after screen change');T.check(kept.playing,'riding layer not restored after preview')
 -- Restart releases the custom source on dismount.
 set.bike_song_restart='restart';ride(false);Music.playMap(g.data,'A',false,false);A.update(g,.02);T.check(kept.released,'RESTART retained source')
 ride(true);Music.playMap(g.data,'A',true,false);A.update(g,.02);T.check(latest('custom.wav')~=kept,'restart reused source')
 set.bike_song='missing';A.refresh(g);A.update(g,.02);T.eq(A.status().layerSong,'Music_BikeRiding','missing custom must fall back to bicycle')
 set.bike_song='bad';A.refresh(g);A.update(g,.02);T.eq(A.status().layerSong,'Music_BikeRiding','bad decoder must fall back')
 set.bike_song='chip';A.refresh(g);A.update(g,.02);T.eq(A.status().layerSong,'chip');T.check(Synth.count>0,'chip engine not made')
 set.riding_music='area';A.update(g,.02);T.check(not A.status().layerActive,'AREA-only left bike active')
 A.dispose();Music.stop()
 for _,src in ipairs(T.sources)do if src.path=='custom.wav'or src.path=='chip'or src.path=='intro.ogg'or src.path=='loop.ogg'then T.check(not src.playing,'source leak on dispose')end end
 T.check(#R.errors==0,'runtime hook error hidden')
end
print(('PASS %d native Music/hooks lifecycle, audio-profile, gain, filter, preview and failure-fallback assertions across six contexts. Sources/decoders/synth are doubles.'):format(T.count))
