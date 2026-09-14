-- Six bicycle parts and a colour-only reset. Native font/input/screens.
local Controls={}
function Controls.init(mod,c)
  local Font=require('src.render.Font')
  local Theme=require('src.ui.Theme')
  local Screens=require('src.ui.Screens')
  local Runtime=require('src.mods.Runtime')
  local P,C=c.hardware,c.colours
  local keys={'bike_colour','bike_stripes_colour','bike_centres_colour',
    'bike_tyres_colour','bike_frame_colour','bike_handlebars_colour'}
  local api={}
  function api.reset(game)
    if Runtime.safeMode or not(game and game.save and game.save.options and game.mods)then return false end
    local options,loader=game.save.options,game.mods
    options.modOptions=options.modOptions or {};loader.modOptions=loader.modOptions or {}
    local saved=options.modOptions[mod.id] or {};local live=loader.modOptions[mod.id] or {}
    local beforeSaved,beforeLive={},{}
    for _,key in ipairs(keys)do
      beforeSaved[key],beforeLive[key]=saved[key],live[key]
      saved[key],live[key]='original','original'
    end
    options.modOptions[mod.id],loader.modOptions[mod.id]=saved,live
    -- One write for the complete reset, not six intermediate states.
    local ok,result=true,nil
    if game.writeOptions then ok,result=pcall(game.writeOptions,game)end
    if not ok or result==false then
      for _,key in ipairs(keys)do saved[key],live[key]=beforeSaved[key],beforeLive[key]end
      return false
    end
    c.refreshOptions()
    if loader.events then
      for _,key in ipairs(keys)do
        loader.events:emit('mod.options_changed',{mod=mod.id,key=key,value='original'})
      end
    end
    return true
  end
  mod.content.screens:register('BicyclePlusResetColours',{new=function(game)
    local self={game=game,isOpaque=true,isModOptions=true,index=1,sgbPalettes=c.palette}
    function self:update()
      local input=self.game.input
      if input:wasPressed('b') or input:wasPressed('start')then self.game.stack:pop();return end
      if input:wasPressed('up') or input:wasPressed('down')then self.index=3-self.index
      elseif input:wasPressed('a')then
        if self.index==1 then self.game.stack:pop()
        elseif api.reset(self.game)then self.game.stack:pop()
        else self.notice='NOT RESET'end
      end
    end
    function self:draw()
      local G=love.graphics
      G.setColor(1,1,1,1);G.rectangle('fill',0,0,160,144);Font.drawBox(0,0,20,18)
      G.setColor(0,0,0,1)
      local title='RESET '..c.colourWord()..'S?'
      Font.draw(title,math.floor((160-#title*8)/2),16)
      Font.draw('ALL SIX PARTS',28,40);Font.draw('TO ORIGINAL?',32,56)
      Font.draw('NO',40,80);Font.draw('YES',40,96)
      Font.drawCode(Theme.cursor,24,self.index==1 and 80 or 96)
      Font.draw(self.notice or 'BIKE ONLY',40,116);Font.draw('A:OK B:CANCEL',24,128)
      G.setColor(1,1,1,1)
    end
    return self
  end})
  mod.content.screens:register('BicyclePlusColours',{new=function(game)
    c.migrate(game)
    local self={game=game,isOpaque=true,isModOptions=true,timer=0,index=1,first=1,
      sgbPalettes=c.previewPalette,bicyclePlusPreviewRect={x=16,y=24,scale=2},rows={
        {key=keys[1],label=function()return 'WHEEL'end},
        {key=keys[2],label=function()return 'STRIPE'end},
        {key=keys[3],label=c.centreWord},
        {key=keys[4],label=function()return 'EDGE'end},
        {key=keys[5],label=function()return 'DETAILS'end},
        {key=keys[6],label=function()return 'HANDLEBARS'end},
        {reset=true,label=function()return 'RESET '..c.colourWord()..'S'end},
      }}
    function self:update(dt)
      self.timer=self.timer+(dt or 0)
      local input=self.game.input
      if input:wasPressed('b') or input:wasPressed('start')then self.game.stack:pop();return end
      local row=self.rows[self.index]
      if input:wasPressed('a')then
        if row.reset then Screens.push(self.game,'BicyclePlusResetColours')
        else c.picker.open(self.game,row.key,row.label())end
        return
      end
      if input:wasPressed('select') and C.needsColourMode(self.game)then C.enableColourMode(self.game);return end
      if input:wasPressed('up')then self.index=(self.index-2)%#self.rows+1
      elseif input:wasPressed('down')then self.index=self.index%#self.rows+1
      elseif row.key and (input:wasPressed('left') or input:wasPressed('right'))then
        local at=1;local selected=c.getSetting(row.key)
        for i,choice in ipairs(P.quickChoices)do if choice[2]==selected then at=i;break end end
        local delta=input:wasPressed('left') and -1 or 1
        c.setSetting(self.game,row.key,P.quickChoices[(at-1+delta)%#P.quickChoices+1][2])
      end
    end
    function self:draw()
      local G=love.graphics
      G.setColor(1,1,1,1);G.rectangle('fill',0,0,160,144);Font.drawBox(0,0,20,18)
      G.setColor(0,0,0,1)
      local title='BICYCLE '..c.colourWord()
      Font.draw(title,math.floor((160-#title*8)/2),8)
      G.setColor(1,1,1,1)
      local ok,status=C.drawPreview(self.game,16,24,2,self.timer)
      G.setColor(0,0,0,1)
      self.first=math.max(1,math.min(self.first,self.index))
      if self.index>self.first+4 then self.first=self.index-4 end
      if ok==false then Font.draw('ENTER GAME FIRST',16,56)
      elseif status=='Custom bike art kept original'then Font.draw('ART KEPT ORIGINAL',12,56)
      elseif status=='Colour readback unavailable'then Font.draw(c.colourWord()..' NOT READY',16,56)
      else
        Font.draw('ART:'..C.artStyle(self.game),16,56)
        Font.draw(('%d-%d'):format(self.first,math.min(self.first+4,#self.rows)),112,56)
      end
      for i=self.first,math.min(self.first+4,#self.rows)do
        local row=self.rows[i];local y=64+(i-self.first)*11
        Font.draw(row.label(),16,y)
        if row.key then
          local selected=c.getSetting(row.key);local value=P.label(selected);local edge=144
          if row.key==keys[6]then
            edge=152
            value=selected=='original' and 'ORIG.' or (#value>6 and P.hex(selected):sub(2) or value)
          end
          Font.draw(value,edge-#value*8,y)
        end
        if i==self.index then Font.drawCode(Theme.cursor,8,y)end
      end
      Font.draw(self.rows[self.index].reset and 'A:RESET '..c.colourWord()..'S' or 'A:PICK LR:QUICK',16,120)
      if C.needsColourMode(self.game)then Font.draw('SEL:'..C.colourModeName(self.game)..' B:BACK',4,128)
      else Font.draw('B:BACK  SAVED',24,128)end
      G.setColor(1,1,1,1)
    end
    return self
  end})
  return api
end
return Controls
