-- FireRed current-game song catalogue for the isolated AUTOBIKE+ beta.
-- Names mirror pret/pokefirered's public song constants; availability is
-- still decided from the user's extracted FireRed audio pack at runtime.
local Catalog={}
local NAMES={
 [264]='Evolution',[265]='RS Gym Leader Battle',[266]='RS Trainer Battle',
 [267]='School',[268]='Slots Jackpot',[269]='Slots Win',[270]='Move Deleted',
 [271]='Too Bad',[272]='Follow Me',[273]='Game Corner',[274]='Rocket Hideout',
 [275]='Pokemon Gym',[276]='Jigglypuff Song',[277]='Intro Fight',[278]='Title Screen',
 [279]='Cinnabar Island',[280]='Lavender Town',[281]='Healing Theme',
 [282]='Bicycle',[283]='Team Rocket Encounter',[284]='Girl Encounter',
 [285]='Boy Encounter',[286]='Hall of Fame',[287]='Viridian Forest',
 [288]='Mt. Moon',[289]='Pokemon Mansion',[290]='Credits',[291]='Route 1',
 [292]='Route 24',[293]='Route 3',[294]='Route 11',[295]='Victory Road',
 [296]='Gym Leader Battle',[297]='Trainer Battle',[298]='Wild Pokemon Battle',
 [299]='Champion Battle',[300]='Pallet Town',[301]='Professor Oak Lab',
 [302]='Professor Oak',[303]='Pokemon Center',[304]='S.S. Anne',[305]='Surfing',
 [306]='Pokemon Tower',[307]='Silph Co.',[308]='Fuchsia City',[309]='Celadon City',
 [310]='Trainer Victory',[311]='Wild Pokemon Victory',[312]='Gym Leader Victory',
 [313]='Vermilion City',[314]='Pewter City',[315]='Rival Encounter',
 [316]='Rival Exit',[317]='Pokedex Rating',[318]='Obtain Key Item',
 [319]='Caught Pokemon Intro',[320]='Photo',[321]='Game Freak',[322]='Caught Pokemon',
 [323]='New Game Instructions',[324]='New Game Intro',[325]='New Game Exit',
 [326]='Pokemon Jump',[327]='Union Room',[328]='Network Center',[329]='Mystery Gift',
 [330]='Berry Pick',[331]='Sevii Cave',[332]='Teachy TV Show',[333]='Sevii Route',
 [334]='Sevii Dungeon',[335]='Sevii Islands 1-3',[336]='Sevii Islands 4-5',
 [337]='Sevii Islands 6-7',[338]='Poke Flute',[339]='Deoxys Battle',
 [340]='Mewtwo Battle',[341]='Legendary Battle',[342]='Gym Leader Encounter',
 [343]='Deoxys Encounter',[344]='Trainer Tower',[345]='Pallet Town (Slow)',
 [346]='Teachy TV Menu',
}
Catalog.NAMES=NAMES

function Catalog.key(id)
 id=tonumber(id)
 if not id or id~=math.floor(id) or not NAMES[id] then return nil end
 return 'firered:'..id
end

function Catalog.id(key)
 if type(key)=='number' then return NAMES[key] and key or nil end
 if type(key)~='string' then return nil end
 local id=tonumber(key:match('^firered:(%d+)$') or key:match('^fr:(%d+)$'))
 return id and NAMES[id] and id or nil
end

function Catalog.name(id)
 id=tonumber(id);return id and NAMES[id] or nil
end

function Catalog.describe(key)
 if key==nil or key=='original' then return 'ORIGINAL BICYCLE' end
 local id=Catalog.id(key)
 return id and (NAMES[id] or ('FIRERED SONG '..id)) or 'MISSING SONG'
end

function Catalog.available(Audio)
 local rows={}
 if type(Audio)~='table' or type(Audio.songInfo)~='function' then return rows end
 for id=264,346 do
  if NAMES[id] then
   local ok,info=pcall(Audio.songInfo,id)
   if ok and type(info)=='table' and info.kind=='bgm' and info.missing~=true then
    rows[#rows+1]={id=id,key='firered:'..id,name=NAMES[id],kind='firered'}
   end
  end
 end
 return rows
end
return Catalog
