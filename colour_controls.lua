-- Original/Custom rows and a confirmed colour-only reset.
local Controls={}
function Controls.init(mod,config)
  local Hardware,colours,picker,UI=config.hardware,config.colours,config.picker,config.ui
  local getSetting,setSetting=config.getSetting,config.setSetting
  local migrateSettings,defineOptions=config.migrate,config.refreshOptions
  local colourWord,centreWord=config.colourWord,config.centreWord
  local Runtime=require("src.mods.Runtime");local Screens=require("src.ui.Screens")
  local colourKeys={bike_colour=true,bike_stripes_colour=true,bike_centres_colour=true,
    bike_tyres_colour=true,bike_frame_colour=true,bike_handlebars_colour=true}
  local function lastCustom(game,key)
    local current=getSetting(key)
    if current~="original" then return current end
    local options=game.save and game.save.options or {}
    local saved=options.modOptions and options.modOptions[mod.id] or {}
    local live=game.mods and game.mods.modOptions and game.mods.modOptions[mod.id] or {}
    local value=Hardware.canonical(live[key.."_custom"] or saved[key.."_custom"])
    return value and value~="original" and value or Hardware.canonical("green")
  end
  -- Reset paint only in one write; remembered custom colours remain available.
  local function resetColours(game)
    if Runtime.safeMode or not(game and game.mods and game.save and game.save.options)then return false end
    if migrateSettings then migrateSettings(game)end
    local o=game.save.options;o.modOptions=o.modOptions or {};game.mods.modOptions=game.mods.modOptions or {}
    local saved=o.modOptions[mod.id]or{};local live=game.mods.modOptions[mod.id]or{}
    for key in pairs(colourKeys)do
      local old=Hardware.canonical(live[key]or saved[key])
      if old and old~="original"then saved[key.."_custom"]=old;live[key.."_custom"]=old end
      saved[key]="original";live[key]="original"
    end
    o.modOptions[mod.id],game.mods.modOptions[mod.id]=saved,live
    if game.writeOptions then game:writeOptions()end
    if game.mods.events then game.mods.events:emit("mod.options_changed",{mod=mod.id,reset="colours"})end
    defineOptions();return true
  end

  mod.content.screens:register("BicyclePlusResetColours", {new=function(game)
    local self={game=game,isOpaque=true,isModOptions=true,index=1,
      sgbPalettes=UI.zones,_bicycleUI=UI}
    local buttons={{16,86,56,18},{88,86,56,18}}
    function self:choose()
      if self.index==1 or resetColours(self.game)then self.game.stack:pop()end
    end
    function self:update(dt)
      local input=self.game.input
      if input:wasPressed("b")or input:wasPressed("start")then self.game.stack:pop();return end
      if input:wasPressed("a")then self:choose();return end
      if UI.direction(self,dt)then self.index=3-self.index end
    end
    function self:pointer(e,x,y)
      if e.phase=="pressed"or e.phase=="moved"then
        for i,r in ipairs(buttons)do if UI.hit(x,y,r)then
          self.index=i;if e.phase=="pressed"and(e.source~="mouse"or e.button==1)then self:choose()end
          return true
        end end
      end
      return true
    end
    function self:draw()
      UI.background();UI.centre("RESET "..colourWord().."S?",18)
      UI.centre("ALL SIX BIKE PARTS",40);UI.centre("RETURN TO ORIGINAL",51)
      UI.centre("OTHER SETTINGS UNCHANGED",66)
      UI.button("CANCEL",buttons[1],self.index==1);UI.button("RESET",buttons[2],self.index==2)
      UI.centre("A:CONFIRM  B:BACK",114);UI.white()
    end
    return self
  end})

  mod.content.screens:register("BicyclePlusColours", {new=function(game)
    migrateSettings(game)
    local self={game=game,isOpaque=true,isModOptions=true,timer=0,index=1,
      sgbPalettes=UI.zones,_bicycleUI=UI,bicyclePlusPreviewRect={x=16,y=4,scale=2},
      rows={
        {key="bike_colour",label=function()return "WHEEL"end},
        {key="bike_stripes_colour",label=function()return "STRIPE"end},
        {key="bike_centres_colour",label=centreWord},
        {key="bike_tyres_colour",label=function()return "EDGE"end},
        {key="bike_frame_colour",label=function()return "DETAILS"end},
        {key="bike_handlebars_colour",label=function()return "HANDLEBARS"end},
        {reset=true,label=function()return "RESET "..colourWord().."S"end},
      }}
    function self:toggle()
      local key=self.rows[self.index].key
      if key then
        local current=getSetting(key)
        if current~="original"then
          local saved=self.game.save.options.modOptions[mod.id]
          local live=self.game.mods.modOptions[mod.id]
          saved[key.."_custom"],live[key.."_custom"]=current,current
        end
        setSetting(self.game,key,current=="original"and lastCustom(self.game,key)or"original")
      end
    end
    function self:activate()
      local row=self.rows[self.index]
      if row.reset then Screens.push(self.game,"BicyclePlusResetColours")
      elseif getSetting(row.key)=="original"then setSetting(self.game,row.key,"original")
      else picker.open(self.game,row.key,row.label(),lastCustom(self.game,row.key))end
    end
    function self:update(dt)
      self.timer=self.timer+(dt or 0);local input=self.game.input
      if input:wasPressed("b")or input:wasPressed("start")then self.game.stack:pop();return end
      if input:wasPressed("a")then self:activate();return end
      if input:wasPressed("select")and colours.needsColourMode(self.game)then colours.enableColourMode(self.game);return end
      local key=UI.direction(self,dt)
      if key=="up"then self.index=(self.index-2)%#self.rows+1
      elseif key=="down"then self.index=self.index%#self.rows+1
      elseif key=="left"or key=="right"then self:toggle()end
    end
    function self:pointer(e,x,y)
      if e.phase~="pressed"and e.phase~="moved"then return true end
      if e.source=="mouse"and e.phase=="pressed"and e.button~=1 then return false end
      for i,row in ipairs(self.rows)do
        if UI.hit(x,y,{4,40+(i-1)*10,152,10})then
          self.index=i
          if e.phase=="pressed"then if row.key and x>=100 then self:toggle()else self:activate()end end
          return true
        end
      end
      if e.phase=="pressed"and UI.hit(x,y,{114,125,42,14})then self.game.stack:pop()end
      return true
    end
    function self:draw()
      UI.background();UI.white();colours.drawPreview(self.game,16,4,2,self.timer)
      for i,row in ipairs(self.rows)do
        local y=42+(i-1)*10
        if self.index==i then UI.focus(4,y-2,152,10);UI.marker(6,y)end
        UI.text(row.label(),16,y)
        if row.key then UI.text(getSetting(row.key)=="original"and"ORIGINAL"or"CUSTOM",104,y)end
      end
      UI.centre(colours.needsColourMode(self.game)and"SEL:FULL COLOUR"or("LR:"..colourWord().." TYPE"),114)
      UI.text("A:PICK",8,129);UI.text("B:BACK",116,129)
      UI.white()
    end
    return self
  end})

  return {reset=resetColours}
end
return Controls
