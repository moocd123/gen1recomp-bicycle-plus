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
  local function pop(game)game.stack:pop()end
  local message,openList,openDetail,openRoot,openRename,browseInbox,inboxHelp
  local function generic(game,opts)
    local s={game=game,isOpaque=true,isModOptions=true,_bicycleUI=U,index=1,scroll=0,timer=0,
      title=opts.title,rows=opts.rows or {},subtitle=opts.subtitle,onUpdate=opts.update,
      bicycleMusicPreview=opts.preview==true,_bicycleMusic=true}
    function s:sgbPalettes()return U.zones()end
    function s:exit()if opts.exit then opts.exit()end end
    function s:activate()
      local row=self.rows[self.index]
      if row and row.action then row.action(self)end
    end
    function s:update(dt)
      self.timer=self.timer+(dt or 0)
      if self.onUpdate then self.onUpdate(self)end
      local input=self.game.input
      if input:wasPressed('b')or input:wasPressed('start')then pop(self.game);return end
      if input:wasPressed('a')then self:activate();return end
      local key=U.direction(self,dt)
      if #self.rows>0 then
        if key=='up'then self.index=(self.index-2)%#self.rows+1
        elseif key=='down'then self.index=self.index%#self.rows+1
        elseif key=='left'then self.index=math.max(1,self.index-8)
        elseif key=='right'then self.index=math.min(#self.rows,self.index+8)end
      end
    end
    function s:visible()
      if self.index<=self.scroll then self.scroll=self.index-1 end
      if self.index>self.scroll+8 then self.scroll=self.index-8 end
      self.scroll=math.max(0,self.scroll)
    end
    function s:pointer(e,x,y)
      if e.phase~='pressed' and e.phase~='moved'then return true end
      if e.source=='mouse' and e.phase=='pressed' and e.button~=1 then return false end
      self:visible()
      for i=1,8 do
        local index=self.scroll+i
        if self.rows[index] and U.hit(x,y,{4,37+(i-1)*10,152,10})then
          self.index=index;if e.phase=='pressed'then self:activate()end;return true
        end
      end
      if e.phase=='pressed'then
        if U.hit(x,y,{112,127,46,17})then pop(self.game)
        elseif U.hit(x,y,{4,127,38,17})then self.index=math.max(1,self.index-8)
        elseif U.hit(x,y,{44,127,38,17})then self.index=math.min(#self.rows,self.index+8)end
      end
      return true
    end
    function s:draw()
      U.background();U.centre(text(self.title,25),4)
      local sub=type(self.subtitle)=='function'and self.subtitle()or self.subtitle
      sub=tostring(sub or ''):upper():gsub('[^A-Z0-9 :/#%.%+%-]',' ')
      if #sub>25 then
        local span=#sub-25;local step=math.floor(math.max(0,self.timer-1.5)*4)%(span+14)
        local at=math.min(span,step)
        sub=sub:sub(at+1,at+25)
      end
      U.text(text(sub,25),5,17)
      U.text(('%d/%d'):format(self.index,#self.rows),5,27)
      self:visible()
      for i=1,8 do
        local row=self.rows[self.scroll+i]
        if row then
          local y=39+(i-1)*10
          if self.index==self.scroll+i then U.focus(4,y-2,152,10);U.marker(6,y)end
          local name=type(row.label)=='function'and row.label()or row.label
          U.text(text(name,23),16,y)
        end
      end
      U.text('PREV',5,130);U.text('NEXT',45,130);U.text('B:BACK',116,130);U.white()
    end
    return s
  end
  mod.content.screens:register('BicyclePlusSongList',{new=generic})
  openList=function(game,opts)return Screens.push(game,'BicyclePlusSongList',opts)end
  message=function(game,title,body)
    local rows={};body=tostring(body or '')
    while #body>0 do
      local at=body:sub(1,23):match('^.*() ')or math.min(23,#body)
      if #body<=23 then at=#body end
      rows[#rows+1]={label=body:sub(1,at)};body=body:sub(at+1)
    end
    rows[#rows+1]={label='BACK',action=function()pop(game)end}
    openList(game,{title=title,rows=rows,subtitle='A:BACK / B:BACK'})
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
    return openList(game,{title=edition:upper()..' SOUNDTRACK',subtitle='A:SONG OPTIONS',rows=rows})
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
    local s=openList(game,{title='MY AUDIO FILES',subtitle='A:SONG OPTIONS',update=refresh})
    refresh(s);return s
  end
  local function handleImported(game,row,err)
    if row and type(row)=='table'then openDetail(game,row)
    else message(game,'AUDIO IMPORT',err or 'No file selected')end
  end
  local function chooseImport(game)
    local row,err=library.chooseFile()
    if row=='pending'then
      local s
      s=openList(game,{title='IMPORT AUDIO',subtitle='RETURN AFTER CHOOSING',rows={
        {label='CANCEL WAIT',action=function()library.cancelPick();pop(game)end},
      },update=function(page)
        if library.pending then return end
        pop(game)
        local outcome=library.lastImport
        library.lastImport=nil
        handleImported(game,outcome and outcome.row, outcome and outcome.error or library.notice)
      end,exit=function()library.cancelPick()end})
    elseif row=='browser' then browseInbox(game,'',err)
    else handleImported(game,row,err)end
  end
  browseInbox=function(game,relative,notice)
    relative=relative or ''
    local rows={}
    for _,entry in ipairs(library.inbox(relative))do local row=entry
      rows[#rows+1]={label=(row.directory and 'FOLDER: ' or '')..row.name,action=function()
        if row.directory then browseInbox(game,row.relative)
        else local imported,err=library.importInbox(row.relative);handleImported(game,imported,err)end
      end}
    end
    if #rows==0 then rows={{label='NO AUDIO FILES HERE'}} end
    rows[#rows+1]={label='REFRESH FOLDER',action=function()pop(game);browseInbox(game,relative)end}
    rows[#rows+1]={label='INBOX LOCATION / HELP',action=function()inboxHelp(game)end}
    rows[#rows+1]={label='BACK',action=function()pop(game)end}
    openList(game,{title='AUDIO FILE BROWSER',subtitle=notice or (relative~='' and relative or 'INBOX: MP3 OGG WAV FLAC'),rows=rows})
  end
  inboxHelp=function(game)
    local rows={
      {label='OPEN INBOX FOLDER',action=function()
        local ok,err=library.openInboxFolder();if not ok then message(game,'INBOX LOCATION',library.inboxPath()..' '..tostring(err))end
      end},
      {label='COPY FOLDER PATH',action=function()
        local ok,err=library.copyInboxPath();message(game,ok and 'PATH COPIED' or 'COPY UNAVAILABLE',err)
      end},
      {label='SHOW FOLDER PATH',action=function()message(game,'INBOX PATH',library.inboxPath())end},
      {label='HOW TO IMPORT',action=function()
        message(game,'PORTABLE IMPORT','Copy MP3 OGG WAV or FLAC files into the music inbox using your platform file manager. Then choose BROWSE MUSIC INBOX. Subfolders are supported. Desktop builds can also drag an audio file onto this music menu. System picker availability depends on your build.')
      end},
      {label='BACK',action=function()pop(game)end},
    }
    return openList(game,{title='AUDIO IMPORT HELP',subtitle='LOCAL FILES - NO UPLOAD',rows=rows})
  end
  openRoot=function(game)
    if Runtime.safeMode then return false end
    local rows={
      {label='ORIGINAL BICYCLE THEME',action=function()choose(game,'original')end},
      {label='CURRENT GAME SONGS',action=function()browseGame(game,library.currentEdition())end},
      {label='OTHER IMPORTED GAMES',action=function()
        local other={}
        for _,entry in ipairs(library.editions(game))do local row=entry
          if row.id~=library.currentEdition() then
            other[#other+1]={label=row.label..(row.available and''or' - NOT IMPORTED'),
              action=function()browseGame(game,row.id)end}
          end
        end
        openList(game,{title='IMPORTED SOUNDTRACKS',subtitle='USES LOCAL ROM IMPORTS',rows=other})
      end},
      {label='MY AUDIO FILES',action=function()browseFiles(game)end},
      {label='IMPORT AUDIO FILE',action=function()chooseImport(game)end},
      {label='BROWSE MUSIC INBOX',action=function()browseInbox(game)end},
      {label=function()return 'ON MOUNT: '..(get('bike_song_resume')and'RESUME'or'RESTART')end,
        action=function()set(game,'bike_song_resume',not get('bike_song_resume'))end},
      {label='FILE IMPORT HELP',action=function()inboxHelp(game)end},
      {label='BACK',action=function()pop(game)end},
    }
    return openList(game,{title='BICYCLE SONG',subtitle=function()return library.describe(get('bike_song'))end,rows=rows})
  end

  mod.content.screens:register('BicyclePlusSongName',{new=function(game,opts)
    local row=opts.row;local chars={}
    for c in ('ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'):gmatch('.')do chars[#chars+1]=c end
    for _,c in ipairs({'SPACE','DEL','CLEAR','SAVE','BACK'})do chars[#chars+1]=c end
    local s={game=game,isOpaque=true,isModOptions=true,_bicycleUI=U,_bicycleMusic=true,buffer=row.name:upper():sub(1,24),replace=true,index=1}
    function s:sgbPalettes()return U.zones()end
    function s:key(c)
      if c=='BACK'then pop(game)
      elseif c=='SAVE'then
        if self.buffer:match('%S')then local ok,err=library.rename(row.id,self.buffer)
          if ok then row.name=self.buffer;pop(game)else self.error=err end
        else self.error='ENTER A NAME'end
      elseif c=='DEL'then self.buffer=self.replace and''or self.buffer:sub(1,-2);self.replace=false
      elseif c=='CLEAR'then self.buffer='';self.replace=false
      else c=c=='SPACE'and' 'or c
        if self.replace then self.buffer='';self.replace=false end
        if #self.buffer<24 then self.buffer=self.buffer..c end
      end
    end
    function s:rawKey(key)
      if key=='escape'then self:key('BACK')
      elseif key=='return'or key=='kpenter'then self:key('SAVE')
      elseif key=='backspace'then self:key('DEL')
      elseif key=='delete'then self:key('CLEAR')
      elseif key=='space'then self:key('SPACE')
      elseif #key==1 and key:match('[%w]')then self:key(key:upper())end
      return true
    end
    function s:update(dt)
      local input=game.input
      if input:wasPressed('b')then pop(game);return end
      if input:wasPressed('start')then self:key('SAVE');return end
      if input:wasPressed('select')then self:key('DEL');return end
      if input:wasPressed('a')then self:key(chars[self.index]);return end
      local key=U.direction(self,dt)
      if key then local d=key=='up'and -6 or key=='down'and 6 or key=='left'and -1 or 1;self.index=(self.index-1+d)%#chars+1 end
    end
    function s:pointer(e,x,y)
      if e.phase~='pressed'and e.phase~='moved'then return true end
      for i,c in ipairs(chars)do local r={5+(i-1)%6*25,37+math.floor((i-1)/6)*12,24,11}
        if U.hit(x,y,r)then self.index=i;if e.phase=='pressed'and(e.source~='mouse'or e.button==1)then self:key(c)end;return true end
      end
      return true
    end
    function s:draw()
      U.background();U.centre('SONG NAME',4)
      if self.replace then U.focus(5,16,150,14)end
      U.text(text(self.buffer,24),8,20)
      for i,c in ipairs(chars)do
        local label=({SPACE='SP',CLEAR='CLR',SAVE='OK',BACK='BACK'})[c]or c
        U.button(label,{5+(i-1)%6*25,37+math.floor((i-1)/6)*12,24,11},self.index==i)
      end
      U.text(text(self.error or 'A:KEY  B:BACK  START:OK',25),5,129);U.white()
    end
    return s
  end})
  openRename=function(game,row)return Screens.push(game,'BicyclePlusSongName',{row=row})end
  function api.open(game)return openRoot(game)end
  function api.fileDropped(game,file)
    local top=game and game.stack and game.stack:top()
    if Runtime.safeMode or not (top and top._bicycleMusic) or library.pending
        or not file or not file.getFilename then return false end
    local ok,name=pcall(file.getFilename,file)
    if not ok or not tostring(name):lower():match('%.(.*)$') then return false end
    local ext=tostring(name):lower():match('%.([^%.]+)$')
    if not ({mp3=true,ogg=true,wav=true,flac=true})[ext] then return false end
    audio.stopPreview()
    local call,row,err=pcall(library.importFile,file)
    handleImported(game,call and row or nil,call and err or 'Could not import the dropped file')
    return true
  end
  api.browseInbox=browseInbox
  api.chooseImport=chooseImport
  api.inboxHelp=inboxHelp
  api.browseGame=browseGame;api.openDetail=openDetail;api.openRename=openRename
  return api
end
return Menu
