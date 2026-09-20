-- Gen 3-native FireRed song browser. Current FireRed songs, already-imported
-- Gen 1/2 soundtracks and this beta's isolated local files share one selector.
local SongMenu={}
function SongMenu.new(mod,settings,menu,Catalog,services)
 local S=services or{}
 local Audio=S.Audio or require('src.core.game3.audio')
 local Legacy=S.Legacy
 local Local=S.Local
 local Importer=S.Importer
 local Preview=S.Preview
 local TextEntry=S.TextEntry
 local api={}
 local status=nil
 local function selected(game)return settings.get('bike_song',game)or'original'end
 local function choose(game,key)return settings.set(game,'bike_song',key)end
 local function setStatus(v)status=v and tostring(v):upper()or nil;return status end
 local function stopPreview()if Preview and Preview.stopPreview then Preview.stopPreview()end end
 local function isPreviewing(key)
  if not(Preview and Preview.status)then return false end
  local s=Preview.status();return s and s.preview==true and s.previewKey==key
 end
 local function handleImported(game,row,err)
  if type(row)=='table'and row.id then
   if choose(game,row.id)then setStatus('SELECTED: '..tostring(row.name or'IMPORTED SONG'));return row end
   return nil,setStatus('COULD NOT SAVE SONG')
  end
  if err and err~='IMPORT CANCELLED'then return nil,setStatus(err)end
  return nil
 end
 function api.describe(game)
  local key=selected(game)
  if key=='original'or key:match('^firered:%d+$')or key:match('^fr:%d+$')then return Catalog.describe(key)end
  if Legacy and Legacy.describe then local v=Legacy.describe(key);if v then return v end end
  if Local and Local.describe then local v=Local.describe(key);if v then return v end end
  return'MISSING SONG'
 end
 function api.importStatus()return status end
 function api.poll(game,dt)
  if not(Importer and Importer.hasWork and Importer.hasWork())then return end
  local row,err=Importer.poll(dt);if row or err then return handleImported(game,row,err)end
 end
 function api.openDetail(game,row,isLocal)
  local key=row.key or row.id
  local rows={}
  if Preview and Preview.previewSong then
   rows[#rows+1]={label=function()return isPreviewing(key)and'STOP PREVIEW'or'PREVIEW SONG'end,activate=function()
    if isPreviewing(key)then stopPreview();return end
    stopPreview();local ok,err=Preview.previewSong(key,game);if not ok then setStatus(err or'PREVIEW FAILED')end
   end}
  end
  rows[#rows+1]={label='USE FOR CYCLING',value=function()return selected(game)==key and'ON'or nil end,
   activate=function()stopPreview();return choose(game,key)end}
  if isLocal and Local and TextEntry then
   rows[#rows+1]={label='RENAME',activate=function()
    stopPreview();return TextEntry.open(game,'SONG NAME',row.name,24,function(name)
     local ok,err=Local.rename(row.id,name)
     if ok then row.name=name;setStatus('RENAMED: '..name);return true end
     return nil,err or'RENAME FAILED'
    end)
   end}
  end
  if isLocal and Local and Local.remove then
   rows[#rows+1]={label='REMOVE LOCAL COPY',activate=function()
    stopPreview()
    return menu.open(game,'REMOVE LOCAL SONG?',{
     {label='CANCEL'},
     {label='REMOVE COPY',activate=function()
      if selected(game)==row.id then choose(game,'original')end
      local ok,err=Local.remove(row.id)
      if ok then setStatus('REMOVED: '..row.name)else setStatus(err or'REMOVE FAILED')end
     end},
    })
   end}
  end
  return menu.open(game,'SONG OPTIONS',rows,{exit=stopPreview})
 end
 function api.openCurrent(game)
  local rows={}
  for _,song in ipairs(Catalog.available(Audio))do local row=song
   rows[#rows+1]={label=row.name,value=function()return selected(game)==row.key and'ON'or nil end,
    activate=function()return api.openDetail(game,row,false)end}
  end
  if#rows==0 then rows[1]={label='FIRERED SOUNDTRACK UNAVAILABLE'}end
  return menu.open(game,'FIRERED SOUNDTRACK',rows)
 end
 function api.openLegacyEdition(game,edition,label)
  local rows,err;if Legacy and Legacy.gameSongs then rows,err=Legacy.gameSongs(edition,game)end
  if type(rows)~='table'then rows={{label=tostring(err or'SOUNDTRACK UNAVAILABLE')}}
  else
   local out={}
   for _,song in ipairs(rows)do local row=song
    out[#out+1]={label=row.name,value=function()return selected(game)==row.id and'ON'or nil end,
     activate=function()return api.openDetail(game,row,false)end}
   end
   rows=#out>0 and out or{{label='NO PLAYABLE SONGS FOUND'}}
  end
  return menu.open(game,(label or edition):upper()..' SOUNDTRACK',rows)
 end
 function api.openLegacy(game)
  local rows={};local editions={};if Legacy and Legacy.editions then editions=Legacy.editions(game)or{}end
  for _,edition in ipairs(editions)do local row=edition
   rows[#rows+1]={label=row.label,value=function()return row.available and nil or'NOT IMPORTED'end,
    activate=row.available and function()return api.openLegacyEdition(game,row.id,row.label)end or nil}
  end
  if#rows==0 then rows[1]={label='NO GEN 1 OR 2 IMPORTS FOUND'}end
  return menu.open(game,'OTHER GAME SONGS',rows)
 end
 function api.openLocal(game)
  local rows={}
  if Local and Local.files then
   for _,entry in ipairs(Local.files())do local row=entry
    rows[#rows+1]={label=(row.missing and'MISSING: 'or'')..row.name,
     value=function()return selected(game)==row.id and'ON'or nil end,
     activate=not row.missing and function()return api.openDetail(game,row,true)end or nil}
   end
  end
  if#rows==0 then rows[1]={label='NO IMPORTED AUDIO'}end
  return menu.open(game,'IMPORTED SONGS',rows)
 end
 function api.openBrowser(game,path)
  if not(Importer and Importer.browser)then return nil,setStatus('FILE BROWSER UNAVAILABLE')end
  local browser=Importer.browser();local ok,why=browser.open({title='Select audio',mode='all',initialPath=path or'.'})
  if not ok then return nil,setStatus(why or'FILE BROWSER FAILED')end
  local page;local rows={}
  rows[#rows+1]={label='.. PARENT FOLDER',activate=function()
   local parent=browser.currentDir:gsub('/$',''):match('^(.*)/[^/]+$');local target=parent and parent~=''and parent or'/'
   if page and page.close then page.close()else browser.close()end;return api.openBrowser(game,target)
  end}
  for _,entry in ipairs(browser.entries or{})do local item=entry;local ext=tostring(item.name or''):lower():match('%.([^%.]+)$')
   if item.isDir or({mp3=true,ogg=true,wav=true,flac=true})[ext]then
    rows[#rows+1]={label=(item.isDir and'FOLDER: 'or'')..tostring(item.name or item.path),activate=function()
     if item.isDir then if page and page.close then page.close()else browser.close()end;return api.openBrowser(game,item.path)end
     local row,err=Importer.readSelected(item.path)
     if row then if page and page.close then page.close()else browser.close()end;return handleImported(game,row,err)end
     return setStatus(err or'IMPORT FAILED')
    end}
   end
  end
  page=menu.open(game,'SELECT AUDIO FILE',rows,{exit=function()browser.close()end});return page
 end
 function api.chooseImport(game)
  if not Importer then return nil,setStatus('IMPORT UNAVAILABLE')end
  stopPreview();local row,err=Importer.choose()
  if row=='pending'then setStatus('CHOOSING AUDIO FILE');return row
  elseif row=='browser'then setStatus(nil);return api.openBrowser(game,'.')
  elseif type(row)=='table'then return handleImported(game,row,err)end
  return handleImported(game,nil,err or'IMPORT FAILED')
 end
 function api.open(game)
  local rows={
   {label='ORIGINAL BICYCLE THEME',value=function()return selected(game)=='original'and'ON'or nil end,
    activate=function()stopPreview();return choose(game,'original')end},
   {label='CURRENT GAME SONGS',activate=function()return api.openCurrent(game)end},
  }
  if Legacy then rows[#rows+1]={label='OTHER IMPORTED GAMES',activate=function()return api.openLegacy(game)end}end
  if Local then rows[#rows+1]={label='IMPORTED SONGS',activate=function()return api.openLocal(game)end}end
  if Importer then rows[#rows+1]={label='IMPORT SONG',value=function()return status end,activate=function()return api.chooseImport(game)end}end
  return menu.open(game,'BIKE SONG',rows,{exit=function()stopPreview();if Importer and Importer.cancel then Importer.cancel()end end})
 end
 mod.exports.gen3SongMenu=api;return api
end
return SongMenu
