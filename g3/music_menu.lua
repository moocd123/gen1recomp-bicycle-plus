-- Song selection uses the same compact, controller/touch friendly UI as paint.
-- Browsing/preview never saves a song; USE SONG commits one selection.
local Menu = {}
function Menu.init(mod, config)
  local U,library,audio=config.ui,config.library,config.audio
  local get,set=config.getSetting,config.setSetting
  local Screens=require('src.ui.Screens')
  local Runtime=require('src.mods.Runtime')
  local api={}
  local function text(s,n)
    s=tostring(s or ''):upper():gsub('[^A-Z0-9 :/#%.%+%-]',' ')
    return #s>(n or 24) and s:sub(1,(n or 24)-2)..'..' or s
  end
  local function pop(game)config.menus.pop()end
  local message,openList,openDetail,openRoot,openRename,browseInbox,inboxHelp
  local menus=config.menus
  openList=function(game,opts)
    opts.music=true
    return menus.open(game,opts)
  end
  message=function(game,title,body)
    return openList(game,{title=title,subtitle=tostring(body or ''),rows={
      {label='BACK',action=function()pop(game)end}},footer='A:BACK'})
  end
  local function choose(game,id)
    if set(game,'bike_song',id)then audio.stopPreview();return true end
    return false
  end
  local function confirmDelete(game,row)
    openList(game,{title='REMOVE LOCAL SONG?',subtitle='ORIGINAL FILE IS SAFE',rows={
      {label='CANCEL',action=function()pop(game)end},
      {label='REMOVE COPY',action=function()
        audio.stopPreview();audio.stop()
        if get('bike_song')==row.id then choose(game,'original');audio.stop()end
        local ok,err=library.remove(row.id)
        pop(game);pop(game) -- confirmation and stale detail page
        if not ok then message(game,'REMOVE FAILED',err)end
      end},
    }})
  end
  openDetail=function(game,row)
    audio.stopPreview()
    local rows={
      {label=function()return audio.status().previewActive and 'STOP PREVIEW' or 'PREVIEW SONG'end,
        action=function()
          if audio.status().previewActive then audio.stopPreview()
          else local ok,err=audio.previewSong(row.id,game);if not ok then message(game,'PREVIEW FAILED',err)end end
        end},
      {label='USE FOR CYCLING',action=function()if choose(game,row.id)then pop(game)end end},
    }
    if row.id:sub(1,5)=='file:' then
      rows[#rows+1]={label='RENAME',action=function()audio.stopPreview();openRename(game,row)end}
      rows[#rows+1]={label='REMOVE LOCAL COPY',action=function()audio.stopPreview();confirmDelete(game,row)end}
    end
    rows[#rows+1]={label='BACK',action=function()pop(game)end}
    return openList(game,{title='SONG OPTIONS',subtitle=function()return row.name end,rows=rows,
      preview=true,exit=function()audio.stopPreview()end})
  end
  local function browseGame(game,edition)
    local songs,err=library.gameSongs(edition,game)
    if not songs then message(game,'SOUNDTRACK UNAVAILABLE',err);return end
    local rows={}
    for _,entry in ipairs(songs)do local row=entry
      rows[#rows+1]={label=function()return (get('bike_song')==row.id and 'ON 'or'')..row.name end,
        action=function()openDetail(game,row)end}
    end
    rows[#rows+1]={label='BACK',action=function()pop(game)end}
    return openList(game,{title=edition:upper()..' SOUNDTRACK',subtitle='A:SONG OPTIONS',rows=rows,pages=true})
  end
  local function browseFiles(game)
    local revision=-1
    local function refresh(s)
      if revision==library.revision then return end
      revision=library.revision;s.rows={}
      for _,entry in ipairs(library.files())do local row=entry
        s.rows[#s.rows+1]={label=function()return (row.missing and 'MISSING 'or'')..row.name end,
          action=function()openDetail(game,row)end}
      end
      if #s.rows==0 then s.rows[1]={label='NO IMPORTED AUDIO'}end
      s.rows[#s.rows+1]={label='BACK',action=function()pop(game)end}
      s.index=math.min(s.index,#s.rows)
    end
    local s=openList(game,{title='IMPORTED SONGS',subtitle='A:SONG OPTIONS',update=refresh,pages=true})
    refresh(s);return s
  end
  local function handleImported(game,row,err,page)
    if row and type(row)=='table' then
      if choose(game,row.id) then
        if page then page.notice='SELECTED: '..row.name;page.timer=0 end
        return true
      end
    elseif err~='IMPORT CANCELLED' then
      if page then page.notice=err or 'IMPORT FAILED';page.timer=0
      else message(game,'IMPORT FAILED',err or 'Cannot read this audio')end
    end
    return false
  end
  -- No tutorial or alternate-import entries. On a picker-less build this one
  -- Import action opens the engine's in-app file browser directly.
  browseInbox=function(game)
    local browser=library.picker.browser()
    if browser.active then message(game,'FILE BROWSER BUSY','Close the other file browser first');return end
    local ready,why=browser.open({title='Select audio',mode='all',initialPath='.'})
    if not ready then message(game,'FILE BROWSER',why);return end
    local last=''
    local function refresh(page)
      if last==browser.currentDir and page.ready then return end
      last=browser.currentDir;page.ready=true;page.rows={}
      page.rows[1]={label='.. PARENT FOLDER',action=function()
        local parent=browser.currentDir:gsub('/$',''):match('^(.*)/[^/]+$')
        local ok,err=browser.setDirectory(parent and parent~='' and parent or '/')
        if not ok then page.notice=err end;page.ready=false
      end}
      for _,entry in ipairs(browser.entries or {})do local item=entry
        local ext=item.name:lower():match('%.([^%.]+)$')
        if item.isDir or ({mp3=true,ogg=true,wav=true,flac=true})[ext]then
          page.rows[#page.rows+1]={label=(item.isDir and 'FOLDER: 'or'')..item.name,action=function()
            if item.isDir then local ok,err=browser.setDirectory(item.path);if not ok then page.notice=err end;page.ready=false
            else
              local row,err=library.picker.readSelected(item.path)
              if row then pop(game);handleImported(game,row,err,config.menus.top())
              else page.notice=err;page.timer=0 end
            end
          end}
        end
      end
    end
    local page=openList(game,{title='SELECT AUDIO FILE',subtitle=function()return browser.currentDir end,
      rows={},update=refresh,pages=true,exit=function()browser.close(nil)end})
    refresh(page);return page
  end
  local function chooseImport(game,page)
    audio.stopPreview()
    local row,err=library.chooseFile()
    if row=='pending' then page.notice='CHOOSING AUDIO FILE';page.timer=0
    elseif row=='browser' then browseInbox(game)
    else handleImported(game,row,err,page)end
  end
  openRoot=function(game)
    if Runtime.safeMode then return false end
    local rows={
      {label='ORIGINAL BICYCLE THEME',action=function(s)choose(game,'original');s.notice=nil end},
      {label='CURRENT GAME SONGS',action=function()browseGame(game,library.currentEdition())end},
      {label='OTHER IMPORTED GAMES',action=function()
        local other={}
        for _,entry in ipairs(library.editions(game))do local row=entry
          if row.available and row.id~=library.currentEdition() then
            other[#other+1]={label=row.label,
              action=function()browseGame(game,row.id)end}
          end
        end
        if #other==0 then other[1]={label='NO OTHER IMPORTED GAMES'}end
        openList(game,{title='OTHER IMPORTED GAMES',rows=other})
      end},
      {label='IMPORTED SONGS',action=function()browseFiles(game)end},
      {label='IMPORT SONG',action=function(s)chooseImport(game,s)end},
    }
    return openList(game,{title='BIKE SONG',tag='autobike.songs',rows=rows,
      subtitle=function()return library.describe(get('bike_song'))end,
      update=function(page)
        if library.lastImport then
          local event=library.lastImport;library.lastImport=nil
          handleImported(game,event.row,event.error,page)
        end
      end,
      exit=function()library.cancelPick();audio.stopPreview()end})
  end

  openRename=function(game,row)
    return config.textEntry.open(game,'SONG NAME',row.name,function(name)
      local ok,err=library.rename(row.id,name)
      if ok then row.name=name end
      return ok,err
    end)
  end
  function api.open(game)return openRoot(game)end
  function api.fileDropped(game,file)
    local top=game and config.menus.top()
    if Runtime.safeMode or not (top and top._bicycleMusic) or library.pending
        or not file or not file.getFilename then return false end
    local ok,name=pcall(file.getFilename,file)
    if not ok or not tostring(name):lower():match('%.(.*)$') then return false end
    local ext=tostring(name):lower():match('%.([^%.]+)$')
    if not ({mp3=true,ogg=true,wav=true,flac=true})[ext] then return false end
    audio.stopPreview()
    local call,row,err=pcall(library.importFile,file)
    handleImported(game,call and row or nil,call and err or 'Could not import the dropped file',top)
    return true
  end
  api.browseInbox=browseInbox
  api.chooseImport=chooseImport
  api.browseGame=browseGame;api.openDetail=openDetail;api.openRename=openRename
  return api
end
return Menu
