-- Optional local-only integration: user-supplied ROMs, native extractor/synth.
-- Nothing from the imported data or generated PCM is saved or packaged.
local engine=assert(arg[1]);local roms=assert(arg[2],'ROM directory required')
local T=dofile('verification/v1.8.0/test_support.lua').init(engine)
local Json=require('src.link.Json');local V=require('src.core.GameVersion')
local cache=require('src.import.CacheFs');local prefix=''
function cache.write(path,bytes)T.files[prefix..path]=bytes;return true end
local plainRead=love.filesystem.read
love.filesystem.read=function(p)
 local bytes=T.files[p]
 if not bytes then bytes=T.files[V.cachePrefix()..p]end
 if bytes then return bytes,#bytes end
 return nil,'missing test file '..p
end
local names={red='Pokémon - Red Version.gb',blue='Pokémon - Blue Version.gb',yellow='Pokémon - Yellow Version - Special Pikachu Edition.gb',
 gold='Pokémon - Gold Version.gbc',silver='Pokémon - Silver Version.gbc',crystal='Pokémon - Crystal Version.gbc'}
local data={};local total=0
for _,edition in ipairs(V.ORDER)do
 local info=V.info(edition);local metadata=assert(Json.decode(T.readDisk(engine..'/'..info.manifest)))
 local bytes=T.readDisk(roms..'/'..names[edition]);prefix=info.cachePrefix
 local Extractor=require(info.generation==2 and'src.import.RomExtractorGen2'or'src.import.RomExtractor')
 local ex=Extractor.new(bytes,metadata)
 data[edition]={audio=ex:extractAudio()}
 print('EXTRACTED SOUNDTRACK '..edition)
end
local S=require('src.core.ChipSynth')
love.sound={newSoundData=function(count,rate,bits,channels)
 local d={values={},count=count,channels=channels}
 function d:setSample(index,channel,value)
  assert(type(value)=='number'and value==value and math.abs(value)<=1.001,'invalid PCM')
  self.values[index*self.channels+channel]=value
 end
 function d:release()end
 return d
end}
local Library=dofile('song_library.lua');local library=Library.init({})
local function render(d,def,count)
 local synth=S.newEngine(d,def,{allowLoops=true})
 return S.soundData(synth,count,2).values
end
local expected={}
for _,ed in ipairs(V.ORDER)do
 V.set(ed);S.invalidateBanks()
 local game={data=data[ed]}
 local tracks=assert(library.gameSongs(ed,game))
 local sounding=0
 for _,track in ipairs(tracks)do
  local values=render(data[ed],data[ed].audio.songs[track.label],512)
  for _,v in ipairs(values)do if v~=0 then sounding=sounding+1;break end end
  total=total+1
 end
 local label=ed=='red'or ed=='blue'or ed=='yellow';label=label and 'Music_BikeRiding'or'Music_Bicycle'
 expected[ed]=render(data[ed],data[ed].audio.songs[label],2048)
 print(('PASS %s: %d tracks instantiated and first 512 stereo frames rendered (%d audible starts).'):format(ed,#tracks,sounding))
end
local pairs=0
for _,current in ipairs(V.ORDER)do
 V.set(current);S.invalidateBanks();local game={data=data[current]};library.refresh()
 for _,target in ipairs(V.ORDER)do
  local label=target=='red'or target=='blue'or target=='yellow';label=label and'Music_BikeRiding'or'Music_Bicycle'
  local selected=assert(library.resolve('game:'..target..':'..label,game))
  local rendered=render(selected.data,selected.def,2048)
  assert(V.get()==current,'library changed active game')
  for i,value in ipairs(rendered)do assert(value==expected[target][i],'cross-game PCM or cached banks mismatch '..current..' -> '..target)end
  -- The current game's source remains correct immediately after the foreign one.
  local localLabel=current=='red'or current=='blue'or current=='yellow';localLabel=localLabel and'Music_BikeRiding'or'Music_Bicycle'
  local area=render(data[current],data[current].audio.songs[localLabel],2048)
  for i,value in ipairs(area)do assert(value==expected[current][i],'native bank cache contaminated')end
  pairs=pairs+1
 end
end
print(('PASS %d real imported track starts; %d current/selected edition pairings with 2048-frame exact PCM comparisons and active-bank rechecks. No hardware audio device used.'):format(total,pairs))
