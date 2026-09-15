-- Small controller/mouse/touch menus for the personal bicycle soundtrack.
local Menu={}
function Menu.init(mod,cfg)
  local U,L,A,I=cfg.ui,cfg.library,cfg.audio,cfg.importer
  local get,set=cfg.getSetting,cfg.setSetting
  local Screens=require('src.ui.Screens')
  local Runtime=require('src.mods.Runtime')
  local api={}
  local function text(s)return tostring(s or ''):upper():gsub('[^%w %-%./:]',' '):gsub('%s+',' ')end
  local function cut(s,n)return text(s):sub(1,n or 24)end
  local function shown(s,timer,width)
    s=text(s);width=width or 24
    if #s<=width then return s end
    local loop=s..'   ';local at=math.floor(math.max(0,timer-1)*3)%#loop+1
    return (loop..loop):sub(at,at+width-1)
  end
  local function message(game,title,body)
    return Screens.push(game,'BicyclePlusSongNotice',{title=title,body=body})
  end
  local function choose(game,id)
    A.stopPreview()
    if id~='original' then
      local ok,record,err=pcall(L.resolve,game,id)
      if not ok or not record then message(game,'SONG UNAVAILABLE',err or record);return false end
    end
    if set(game,'bike_song',id)then
      A.refresh(game);return true
    end
    return false
  end
  local function preview(state,id)
    if A.isPreviewing()then A.stopPreview();return end
    local ok,err=A.preview(state.game,id,state)
    if not ok then state.notice=err end
  end
  local function listFactory(game,opts)
    local s={game=game,isOpaque=true,isModOptions=true,_bicycleUI=U,sgbPalettes=U.zones,
      timer=0,index=1,scroll=0,title=opts.title,rows=opts.rows or {},subtitle=opts.subtitle,
      hint=opts.hint or 'A:CHOOSE SEL:PREVIEW',notice=opts.notice}
    function s:exit()A.stopPreview()end
    function s:clamp()
      if self.index<self.scroll+1 then self.scroll=self.index-1 end
      if self.index>self.scroll+6 then self.scroll=self.index-6 end
    end
    function s:activate()
      self.notice=nil;local row=self.rows[self.index]
      if row and row.action then row.action(self)end
    end
    function s:update(dt)
      self.timer=self.timer+(dt or 0);local input=game.input
      if input:wasPressed('b')or input:wasPressed('start')then game.stack:pop();return end
      if input:wasPressed('a')then self:activate();return end
      if input:wasPressed('select')then local row=self.rows[self.index];if row and row.song then preview(self,row.song)end;return end
      local k=U.direction(self,dt)
      if k=='up'or k=='down'then
        A.stopPreview();self.notice=nil;self.index=(self.index-1+(k=='up'and-1 or 1))%math.max(1,#self.rows)+1;self:clamp()
      elseif k=='left'or k=='right'then
        local row=self.rows[self.index]
        if row and row.step then row.step(k=='left'and -1 or 1)
        elseif #self.rows>6 then
          A.stopPreview();self.index=math.max(1,math.min(#self.rows,self.index+(k=='left'and -6 or 6)));self:clamp()
        end
      end
    end
    function s:pointer(e,x,y)
      if e.source=='mouse'and e.phase=='pressed'and e.button~=1 then return false end
      if e.phase=='pressed'or e.phase=='moved'then
        for j=1,6 do local index=self.scroll+j
          if self.rows[index]and U.hit(x,y,{4,42+(j-1)*13,152,13})then
            if self.index~=index then A.stopPreview()end
            self.index=index
            if e.phase=='pressed'then self:activate()end
            return true
          end
        end
        if e.phase=='pressed'then
          if U.hit(x,y,{4,124,45,19})then game.stack:pop()
          elseif U.hit(x,y,{112,124,44,19})then self.index=math.min(#self.rows,self.index+6);self:clamp()
          elseif U.hit(x,y,{59,124,42,19})then local r=self.rows[self.index];if r and r.song then preview(self,r.song)end end
        end
      end
      return true
    end
    function s:draw()
      U.background();U.centre(cut(self.title),5)
      local subtitle=type(self.subtitle)=='function'and self.subtitle()or self.subtitle or L.title(get('bike_song'))
      U.text(shown(subtitle,self.timer),8,18)
      U.text(cut(self.notice or (A.isPreviewing()and 'PREVIEW - BIKE VOLUME' or L.error or self.hint)),8,30)
      for j=1,6 do
        local row=self.rows[self.scroll+j];if row then
          local y=45+(j-1)*13
          if self.index==self.scroll+j then U.focus(4,y-2,152,12);U.marker(6,y)end
          local label=type(row.label)=='function'and row.label()or row.label
          U.text(self.index==self.scroll+j and shown(label,self.timer,23)or cut(label,23),16,y)
        end
      end
      U.text('B:BACK',5,129);U.text('SEL:PLAY',59,129);U.text('LR:PAGE',114,129)
      U.white()
    end
    return s
  end
  local function pushList(game,title,rows,subtitle)
    return Screens.push(game,'BicyclePlusSongList',{title=title,rows=rows,subtitle=subtitle})
  end
  mod.content.screens:register('BicyclePlusSongList',{new=listFactory})
  mod.content.screens:register('BicyclePlusSongNotice',{new=function(game,opts)
    local s={game=game,isOpaque=true,isModOptions=true,_bicycleUI=U,sgbPalettes=U.zones}
    function s:update()for _,k in ipairs({'a','b','start'})do if game.input:wasPressed(k)then game.stack:pop();return end end end
    function s:pointer(e)if e.phase=='pressed'then game.stack:pop()end;return true end
    function s:draw()
      U.background();U.centre(cut(opts.title),8)
      local value=text(opts.body);local y=30
      while #value>0 and y<120 do
        local line=value:sub(1,24);local stop=#value>24 and (line:match('^.*() ')or 24)or #value
        U.text(value:sub(1,stop),8,y);value=value:sub(stop+1);y=y+10
      end
      U.centre('A/B:BACK',130);U.white()
    end
    return s
  end})
  local detail
  local function gameSongs(game,version)
    local ok,tracks,err=pcall(L.gameList,game,version)
    if not ok or #tracks==0 then return message(game,'NO SONGS',err or tracks or 'No imported soundtrack available.')end
    local rows={}
    for _,track in ipairs(tracks)do
      local t=track;rows[#rows+1]={label=t.title,song=t.id,action=function()detail(game,t.id)end}
    end
    return pushList(game,version=='current'and 'THIS GAME' or version:upper()..' SONGS',rows,'A:OPTIONS - SELECT:PLAY')
  end
  local function mySongs(game)
    local tracks,err=L.myAudio();if #tracks==0 then return message(game,'MY AUDIO',err or 'No audio imported. Choose IMPORT AUDIO to add MP3, OGG or WAV.')end
    local rows={};for _,t in ipairs(tracks)do local id=t.id;rows[#rows+1]={label=t.title,song=id,action=function()detail(game,id)end}end
    return pushList(game,'MY AUDIO FILES',rows,'A:OPTIONS - SELECT:PLAY')
  end
  detail=function(game,id)
    local rows={
      {label='USE FOR CYCLING',action=function()if choose(game,id)then game.stack:pop()end end},
      {label=function()return A.isPreviewing()and 'STOP PREVIEW'or 'PLAY PREVIEW'end,song=id,action=function(s)preview(s,id)end},
    }
    if id:sub(1,5)=='file:'then
      rows[#rows+1]={label='RENAME',action=function()A.stopPreview();Screens.push(game,'BicyclePlusSongName',{id=id})end}
      rows[#rows+1]={label='REMOVE LIBRARY COPY',action=function()A.stopPreview();Screens.push(game,'BicyclePlusSongRemove',{id=id})end}
    end
    rows[#rows+1]={label='BACK',action=function()game.stack:pop()end}
    return pushList(game,'SONG OPTIONS',rows,function()return L.title(id)end)
  end
  mod.content.screens:register('BicyclePlusSongRemove',{new=function(game,opts)
    local s=listFactory(game,{title='REMOVE THIS AUDIO?',subtitle=L.title(opts.id),rows={}})
    s.rows={{label='CANCEL',action=function()game.stack:pop()end},
      {label='REMOVE COPY',action=function()
        A.stop();if get('bike_song')==opts.id then set(game,'bike_song','original')end
        local ok,err=L.remove(opts.id)
        if not ok then message(game,'NOT REMOVED',err);return end
        game.stack:pop();game.stack:pop();game.stack:pop();mySongs(game)
      end}}
    return s
  end})
  local nameKeys={};for c in ('ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'):gmatch('.')do nameKeys[#nameKeys+1]=c end
  for _,c in ipairs({'SP','DEL','OK','BACK','',''})do nameKeys[#nameKeys+1]=c end
  mod.content.screens:register('BicyclePlusSongName',{new=function(game,opts)
    local s={game=game,isOpaque=true,isModOptions=true,_bicycleUI=U,sgbPalettes=U.zones,
      value=L.title(opts.id):sub(1,24),replace=true,index=1}
    function s:insert(c)
      if self.replace then self.value='';self.replace=false end
      if #self.value<24 then self.value=self.value..c end
    end
    function s:accept()
      if self.value:match('%S')then local ok,err=L.rename(opts.id,self.value);if ok then game.stack:pop()else self.notice=err end end
    end
    function s:action(k)
      if k=='BACK'then game.stack:pop()
      elseif k=='OK'then self:accept()
      elseif k=='DEL'then self.value=self.replace and ''or self.value:sub(1,-2);self.replace=false
      elseif k=='SP'then self:insert(' ')
      elseif k~=''then self:insert(k)end
    end
    function s:update(dt)
      local input=game.input
      if input:wasPressed('b')then game.stack:pop();return end
      if input:wasPressed('start')then self:accept();return end
      if input:wasPressed('select')then self:action('DEL');return end
      if input:wasPressed('a')then self:action(nameKeys[self.index]);return end
      local k=U.direction(self,dt);if not k then return end
      local delta=k=='up'and-6 or k=='down'and 6 or k=='left'and-1 or 1
      for _=1,#nameKeys do self.index=(self.index-1+delta)%#nameKeys+1;if nameKeys[self.index]~=''then break end end
    end
    function s:rawKey(k)
      if k=='up'or k=='down'or k=='left'or k=='right'then
        local delta=k=='up'and -6 or k=='down'and 6 or k=='left'and -1 or 1
        for _=1,#nameKeys do self.index=(self.index-1+delta)%#nameKeys+1;if nameKeys[self.index]~=''then break end end
      elseif k=='escape'then game.stack:pop()
      elseif k=='return'or k=='kpenter'then self:accept()
      elseif k=='backspace'or k=='delete'then self:action('DEL')
      elseif k=='space'then self:insert(' ')
      elseif #k==1 and k:match('[%w%.%-]')then self:insert(k:upper())end
      return true
    end
    function s:pointer(e,x,y)
      if e.phase=='pressed'then for i,k in ipairs(nameKeys)do
        if k~=''and U.hit(x,y,{5+(i-1)%6*25,38+math.floor((i-1)/6)*12,24,11})then self.index=i;self:action(k);return true end
      end end
      return true
    end
    function s:draw()
      U.background();U.centre('AUDIO NAME',6)
      if self.replace then U.focus(7,18,146,12)end;U.text(self.value,8,20)
      for i,k in ipairs(nameKeys)do if k~=''then U.button(k,{5+(i-1)%6*25,38+math.floor((i-1)/6)*12,24,11},self.index==i)end end
      U.centre('A:KEY START:SAVE B:BACK',130);U.white()
    end
    return s
  end})
  mod.content.screens:register('BicyclePlusSongImport',{new=function(game)
    local s={game=game,isOpaque=true,isModOptions=true,_bicycleUI=U,sgbPalettes=U.zones,timer=0}
    function s:enter()
      A.stopPreview()
      local ok,result,err=pcall(I.start)
      if not ok then self.error=tostring(result)elseif not result then self.error=err end
    end
    function s:exit()if I.pending then I.cancel()end end
    function s:update(dt)
      self.timer=self.timer+(dt or 0)
      if game.input:wasPressed('b')or game.input:wasPressed('start')then game.stack:pop();return end
      if I.result then local id=I.result;I.result=nil;game.stack:pop();detail(game,id);return end
      if (self.error or not I.pending) and game.input:wasPressed('a')then game.stack:pop()end
    end
    function s:pointer(e,x,y)if e.phase=='pressed'and U.hit(x,y,{0,120,160,24})then game.stack:pop()end;return true end
    function s:draw()
      U.background();U.centre('IMPORT PERSONAL AUDIO',8)
      U.centre('MP3 / OGG VORBIS / WAV',27);U.centre('MAXIMUM 64 MIB PER FILE',40)
      local msg=text(self.error or I.message or 'PLEASE WAIT')
      U.text(shown(msg,self.timer),8,62)
      U.centre('FILES STAY ON YOUR DEVICE',86)
      U.centre('UPDATES KEEP YOUR LIBRARY',100)
      U.centre('B:BACK',130);U.white()
    end
    return s
  end})
  local function inbox(game)
    local rows={}
    for _,entry in ipairs(I.inbox())do
      local name=entry.name
      rows[#rows+1]={label=name,action=function()
        A.stopPreview()
        local ok,id,err=pcall(I.fromInbox,name)
        if not ok or not id then message(game,'IMPORT FAILED',err or id);return end
        detail(game,id)
      end}
    end
    if #rows==0 then return message(game,'AUDIO INBOX EMPTY',
      'Copy MP3 OGG or WAV files to '..I.inboxLabel..' in the app game-data folder. Then reopen this list.')end
    pushList(game,'AUDIO INBOX',rows,'A:IMPORT SELECTED FILE')
  end
  function api.open(game)
    if Runtime.safeMode then return false end
    local rows={
      {label='ORIGINAL BICYCLE',song='original',action=function(s)choose(game,'original');s.notice='Original bicycle selected.'end},
      {label='THIS GAME SOUNDTRACK',action=function()gameSongs(game,'current')end},
      {label='OTHER IMPORTED GAMES',action=function()
        local rows={};local ok,editions=pcall(L.editions,game)
        if not ok then return message(game,'UNAVAILABLE','The engine cannot open other imported games.')end
        for _,e in ipairs(editions)do local entry=e
          rows[#rows+1]={label=e.title..(e.available and ''or ' - NOT IMPORTED'),action=function()
            if entry.available then gameSongs(game,entry.version)else message(game,'IMPORT REQUIRED','Import '..entry.title..' through the launcher first.')end
          end}
        end
        pushList(game,'IMPORTED SOUNDTRACKS',rows,'ONLY YOUR IMPORTED ROMS')
      end},
      {label='MY AUDIO FILES',action=function()mySongs(game)end},
      {label='IMPORT AUDIO FILE',action=function()Screens.push(game,'BicyclePlusSongImport')end},
      {label='AUDIO INBOX',action=function()inbox(game)end},
      {label=function()return 'ON MOUNT: '..get('bike_song_restart'):upper()end,
        step=function()set(game,'bike_song_restart',get('bike_song_restart')=='resume'and'restart'or'resume')end,
        action=function()set(game,'bike_song_restart',get('bike_song_restart')=='resume'and'restart'or'resume')end},
      {label='BACK',action=function()game.stack:pop()end},
    }
    return pushList(game,'BICYCLE MUSIC',rows)
  end
  function api.update(dt)I.poll(dt)end
  api.detail=detail;api.gameSongs=gameSongs;api.mySongs=mySongs;api.inbox=inbox
  return api
end
return Menu
