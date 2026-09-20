local root=arg[1]or'gen3_lab'
local Layer=assert(loadfile(root..'/audio_layer.lua'))()
local function check(v,msg)if not v then error(msg or'check failed',2)end end
local function near(a,b,msg)check(math.abs((a or 0)-(b or 0))<1e-8,msg or(tostring(a)..' ~= '..tostring(b)))end

local values={
 riding_music='bicycle',bike_volume=7,bike_filter=0,riding_area_volume=-1,riding_area_filter=-1,
 riding_sfx_volume=-1,riding_sfx_filter=-1,sfx_filter=0,bike_song='original',bike_song_resume=false,
}
local settings={get=function(key)return values[key]end}
local Runtime={safeMode=false,hooks={},events={}}
local Version={get=function()return'firered'end,generation=function()return 3 end}
local PlayerState={biking=true}
local registered={}
local Assets={register=function(v)registered[#registered+1]=v end}

local function soundSource()
 local s={playing=false,paused=false,queues=0,volume=1,filter=nil,released=false}
 function s:getFreeBufferCount()return 1 end
 function s:queue(_)self.queues=self.queues+1;return true end
 function s:play()self.playing=true;self.paused=false end
 function s:pause()self.playing=false;self.paused=true end
 function s:stop()self.playing=false;self.paused=false end
 function s:isPlaying()return self.playing end
 function s:setVolume(v)self.volume=v end
 function s:setFilter(v)self.filter=v end
 function s:getFilter()return self.filter end
 function s:release()self.released=true end
 return s
end
local se=soundSource();local cry=soundSource()
local nativeUpdates,restores,gains,bgmFilters=0,0,0,0
local Audio={_pack={},_cache={},_bgmVolume=5/7,_sfxVolume=4/7,_filterLevel=1,
 _seSources={se},_crySource=cry,_fanfareActive=false}
local originalUpdate=function()nativeUpdates=nativeUpdates+1 end
Audio.update=originalUpdate
function Audio.role(name)return name=='cycling'and 282 or nil end
function Audio.songInfo(id)
 if id==282 or id==300 then return{id=id,kind='bgm',loop=true}end
 return nil
end
function Audio.applyEngineOptions(o)
 restores=restores+1;Audio._bgmVolume=(o.musicVol or 7)/7;Audio._sfxVolume=(o.sfxVol or 7)/7
 Audio._filterLevel=(o.musicFilter or 0)>0 and o.musicFilter or nil
end
function Audio.applyGain()gains=gains+1 end
function Audio.applyBgmFilter()bgmFilters=bgmFilters+1 end

local starts,renders=0,0
local Player={SAMPLE_RATE=44100,BUFFER_SAMPLES=8192}
function Player.start(_,_,slot,id)
 starts=starts+1;slot.songId=id;slot.voices={};return id==282 or id==300
end
function Player.renderBuffered(slot,n,opts)
 renders=renders+1;return{slot=slot,n=n,rate=opts.sampleRate}
end
local made={}
local function newQueueableSource()
 local s=soundSource();made[#made+1]=s;return s
end
local game={phase='field',options={musicVol=5,sfxVol=4,musicFilter=1}}
local mod={id='autobike_plus_firered_beta',game=game,exports={},events={on=function()end},hooks={wrap=function()end}}
local api=Layer.attach(mod,settings,{Version=Version,Audio=Audio,Player=Player,PlayerState=PlayerState,
 Runtime=Runtime,Assets=Assets,newQueueableSource=newQueueableSource,bufferSamples=128,maxFill=1})
check(Audio.update~=originalUpdate,'layer wraps native Audio.update')

-- BICYCLE: independent song starts while native area bus is suppressed.
Audio.update(1/60)
check(nativeUpdates==1,'native Audio.update still runs')
check(starts==1 and renders==1,'independent M4A slot starts and renders')
check(api.status().songId==282 and api.status().ready,'original resolves to FireRed cycling role')
near(Audio._bgmVolume,0,'bicycle-only suppresses area only after overlay is ready')
near(Audio._sfxVolume,4/7,'inherited riding SFX volume uses native option')
near(made[1].volume,1,'bike volume 7 is full overlay gain')
check(made[1].playing,'overlay source plays')

-- BOTH keeps the independent overlay while applying the riding-area profile.
values.riding_music='both';values.riding_area_volume=3;values.bike_volume=2;values.bike_filter=2
Audio.update(1/60)
near(Audio._bgmVolume,3/7,'both preserves riding area volume')
near(made[1].volume,2/7,'bike volume is independent')
check(made[1].filter and made[1].filter.highgain==0.16,'bike filter applies only to overlay')

-- Invalid selection fails safe: never mute the real area song.
values.riding_music='bicycle';values.bike_song='missing'
Audio.update(1/60)
check(not api.status().ready and api.status().error,'invalid song reports unavailable overlay')
near(Audio._bgmVolume,3/7,'invalid bicycle song fails open to area music')

-- Resume retains the private sequencer/source across a dismount.
values.bike_song='original';values.bike_song_resume=true;PlayerState.biking=true
Audio.update(1/60);local resumeStarts=starts;local resumeSource=made[#made]
PlayerState.biking=false;Audio.update(1/60)
check(resumeSource.paused,'resume mode pauses on dismount')
near(Audio._bgmVolume,5/7,'dismount restores native music option')
PlayerState.biking=true;Audio.update(1/60)
check(starts==resumeStarts,'resume mode does not restart M4A sequencer')
check(resumeSource.playing,'paused overlay resumes')

-- Restart discards the slot and starts it again after remounting.
values.bike_song_resume=false;PlayerState.biking=false;Audio.update(1/60)
local beforeRestart=starts
PlayerState.biking=true;Audio.update(1/60)
check(starts==beforeRestart+1,'restart mode creates a new M4A slot')

-- Native fanfares temporarily own audio; bicycle-only must not mute them.
values.bike_song_resume=true;Audio._fanfareActive=true
local fanfareSource=made[#made];Audio.update(1/60)
check(fanfareSource.paused,'fanfare suspends overlay')
near(Audio._bgmVolume,5/7,'fanfare restores native music gain')
Audio._fanfareActive=false;local beforeFanfareResume=starts;Audio.update(1/60)
check(starts==beforeFanfareResume and fanfareSource.playing,'overlay resumes after fanfare')

-- Global SFX filter works off-bike and does not overwrite a newer external filter.
PlayerState.biking=false;values.sfx_filter=2;Audio.update(1/60)
check(se.filter and se.filter.highgain==0.16,'off-bike SFX filter applies')
se.filter={type='lowpass',volume=1,highgain=0.9};values.sfx_filter=0;Audio.update(1/60)
check(se.filter and se.filter.highgain==0.9,'newer external SFX filter wins during restore')

-- Disposal releases only the private source and restores the native update entry.
api.dispose()
check(Audio.update==originalUpdate,'dispose restores native Audio.update')
check(not api.status().overlay,'dispose removes private cycling source')
check(#registered>=1,'asset lifecycle owns disposal')
check(gains>0 and bgmFilters>0 and restores>0,'native runtime profiles were actively managed')
print('PASS independent FireRed cycling audio routing, fanfare safety, resume/restart and SFX filter ownership')
