-- D-pad/touch-button friendly RGB555 picker. No keyboard, clipboard, new
-- permissions, framebuffer reads or 32,768-row options schema are required.
local Picker = {}
function Picker.init(mod, config)
  local P, C = assert(config.hardware), assert(config.colours)
  local get, set = assert(config.getSetting), assert(config.setSetting)
  local Font = require("src.render.Font")
  local Screens = require("src.ui.Screens")
  local Runtime = require("src.mods.Runtime")
  local api = {}
  local keys={bike_colour=true,bike_stripes_colour=true,bike_centres_colour=true,
    bike_tyres_colour=true,bike_frame_colour=true,bike_handlebars_colour=true}
  local COLS,PER_PAGE=8,32
  local function ink() love.graphics.setColor(0,0,0,1) end
  local function white() love.graphics.setColor(1,1,1,1) end
  local function text(s,x,y) ink(); Font.draw(s,x,y); white() end
  local function border(x,y,w,h,selected)
    local G=love.graphics
    ink(); G.rectangle("line",x+0.5,y+0.5,w-1,h-1)
    if selected then
      white(); G.rectangle("line",x+1.5,y+1.5,w-3,h-3)
      ink(); G.rectangle("line",x+2.5,y+2.5,w-5,h-5)
    end
    white()
  end
  local function swatch(id,x,y,w,h)
    local G=love.graphics
    local c=P.rgb(id)
    if c then
      G.setColor(c[1]/255,c[2]/255,c[3]/255,1); G.rectangle("fill",x,y,w,h)
    else
      -- ORIGINAL is an action, not a colour duplicated in the catalogue.
      for i=0,3 do
        local shade=i/3
        G.setColor(shade,shade,shade,1)
        G.rectangle("fill",x+i*w/4,y,w/4,h)
      end
    end
    white()
  end
  local factory={new=function(game,opts)
    opts=opts or {}
    assert(keys[opts.key],"Unknown bicycle colour part")
    local saved=P.canonical(get(opts.key)) or "original"
    local rows,byId=P.presets(game,nil,saved)
    local sections={{label="ORIGINAL",original=true}}
    for _,group in ipairs(P.sections(rows))do sections[#sections+1]=group end
    sections[#sections+1]={label="ALL PRESETS",rows=rows}
    sections[#sections+1]={label="FULL GBC GRID",full=true}
    local self={game=game,key=opts.key,part=opts.label or "BICYCLE",rows=rows,
      sections=sections,sectionIndex=1,sectionFirst=1,sectionLabel="ALL PRESETS",saved=saved,
      index=1,draft=saved,mode="sections",focus="grid",timer=0,
      isOpaque=true,isModOptions=true,screenId="BicyclePlusPicker",
      repeatKey=nil,repeatClock=0,repeatNext=0.35}
    -- Only this opaque editor bypasses the game's retro display palette.
    -- Existing world/display settings are left entirely untouched.
    function self:sgbPalettes()
      return {{colors=false,x=0,y=0,w=160,h=144}}
    end
    function self:exit()
      if self.gridImage and self.gridImage.release then self.gridImage:release() end
      self.gridImage=nil
    end
    function self:openGrid()
      self.gridReturn=self.mode
      self.r,self.g,self.b=P.unpack(P.word(self.draft) or P.word(P.canonical("green")))
      self.draft=P.id(P.pack(self.r,self.g,self.b))
      self.mode,self.focus="rgb","grid"
      self.repeatKey=nil
    end
    local function direction(self,dt)
      local input=self.game.input
      local down
      for _,key in ipairs({"up","down","left","right"}) do
        if input:wasPressed(key) then
          self.repeatKey,self.repeatClock,self.repeatNext=key,0,0.35
          return key
        end
        if input.isDown and input:isDown(key) then down=down or key end
      end
      if not down then self.repeatKey=nil; return nil end
      if self.repeatKey~=down then
        self.repeatKey,self.repeatClock,self.repeatNext=down,0,0.35
        return nil
      end
      self.repeatClock=self.repeatClock+math.min(dt or 0,0.1)
      if self.repeatClock>=self.repeatNext then
        self.repeatNext=self.repeatClock+0.065
        return down
      end
    end
    function self:update(dt)
      self.timer=self.timer+(dt or 0)
      local input=self.game.input
      if input:wasPressed("start") then self.game.stack:pop();return end
      if input:wasPressed("b") then
        if self.mode=="rgb" then
          self.mode=self.gridReturn or "sections"
          self.draft=self.mode=="presets" and self.rows[self.index].id or self.saved
          self.repeatKey=nil
        elseif self.mode=="presets" then self.mode="sections";self.draft=self.saved;self.repeatKey=nil
        else self.game.stack:pop() end
        return
      end
      if input:wasPressed("select") then
        if self.mode~="rgb" then self:openGrid()
        else self.focus=self.focus=="grid" and "blue" or "grid" end
        return
      end
      if input:wasPressed("a") then
        if self.mode=="sections" then
          local section=self.sections[self.sectionIndex]
          if section.full then self:openGrid();return end
          if not section.original then
            if #section.rows==0 then self.notice="EMPTY SECTION";return end
            self.rows,self.sectionLabel=section.rows,section.label
            self.index=1
            for i,row in ipairs(self.rows)do if row.id==self.saved then self.index=i;break end end
            self.draft=self.rows[self.index].id;self.mode="presets";self.repeatKey=nil
            return
          end
          self.draft="original"
        end
        if not Runtime.safeMode and set(self.game,self.key,self.draft) then self.game.stack:pop()
        else self.notice="NOT SAVED" end
        return
      end
      local key=direction(self,dt)
      if not key then return end
      self.notice=nil
      if self.mode=="sections" then
        if key=="up" or key=="down" then
          self.sectionIndex=(self.sectionIndex-1+(key=="up" and -1 or 1))%#self.sections+1
        end
      elseif self.mode=="presets" then
        local delta=key=="left" and -1 or key=="right" and 1 or key=="up" and -COLS or COLS
        self.index=(self.index-1+delta)%#self.rows+1
        self.draft=self.rows[self.index].id
      else
        if self.focus=="blue" then
          self.b=(self.b+((key=="left" or key=="down") and -1 or 1))%32
        elseif key=="left" or key=="right" then
          self.r=(self.r+(key=="left" and -1 or 1))%32
        else self.g=(self.g+(key=="up" and -1 or 1))%32 end
        self.draft=P.id(P.pack(self.r,self.g,self.b))
      end
    end
    function self:drawGrid()
      local G=love.graphics
      -- Cache a 32x32 texture for the current blue slice. No shader tricks;
      -- every texel is one exact RGB555 colour, nearest-scaled three times.
      if not self.gridImage or self.gridBlue~=self.b then
        local data=love.image.newImageData(32,32)
        for g=0,31 do for r=0,31 do
          local c=P.rgb(P.id(P.pack(r,g,self.b)))
          data:setPixel(r,g,c[1]/255,c[2]/255,c[3]/255,1)
        end end
        local image=G.newImage(data);image:setFilter("nearest","nearest")
        if data.release then data:release() end
        if self.gridImage and self.gridImage.release then self.gridImage:release() end
        self.gridImage,self.gridBlue=image,self.b
      end
      white();G.draw(self.gridImage,8,24,0,3,3)
      -- A two-tone outline remains visible on both light and dark swatches.
      local x,y=8+self.r*3,24+self.g*3
      ink();G.rectangle("line",x-0.5,y-0.5,4,4)
      white();G.rectangle("line",x+0.5,y+0.5,2,2)
      text(("B:%02d"):format(self.b),112,24)
      if self.focus=="blue" then ink();G.rectangle("fill",112,34,32,1);white() end
      text(("R:%02d"):format(self.r),112,40)
      text(("G:%02d"):format(self.g),112,48)
      swatch(self.draft,112,60,32,12);border(112,60,32,12,false)
      C.drawSidePreview(self.game,112,80,2,self.timer,{[self.key]=self.draft})
      local hex=P.hex(self.draft):sub(2)
      text(hex..(" 555:%04X"):format(P.word(self.draft)),8,120)
      text(self.focus=="grid" and "SEL:BLUE LR/UD:RG" or "SEL:GRID LR/UD:B",8,128)
      text(self.notice or "A:SET B:BACK",8,136)
    end
    function self:draw()
      local G=love.graphics
      white();G.rectangle("fill",0,0,160,144)
      local title=self.part.." "..config.colourWord()
      text(title,math.floor((160-#title*8)/2),8)
      if self.mode=="rgb" then self:drawGrid();return end
      C.drawPreview(self.game,16,24,2,self.timer,{[self.key]=self.draft})
      if self.mode=="sections" then
        self.sectionFirst=math.max(1,math.min(self.sectionFirst,self.sectionIndex))
        if self.sectionIndex>self.sectionFirst+5 then self.sectionFirst=self.sectionIndex-5 end
        text("CHOOSE SECTION",16,56)
        for i=self.sectionFirst,math.min(self.sectionFirst+5,#self.sections)do
          local section=self.sections[i];local y=66+(i-self.sectionFirst)*10
          text(section.label,16,y)
          if i==self.sectionIndex then text(">",8,y) end
        end
        text(self.notice or "A:OPEN B:CANCEL",16,128)
        text("SEL:FULL GBC GRID",16,136)
        return
      end
      text(self.sectionLabel,8,56)
      local page=math.floor((self.index-1)/PER_PAGE)
      local first=page*PER_PAGE+1
      for i=0,PER_PAGE-1 do
        local row=self.rows[first+i]
        if row then
          local x,y=8+(i%COLS)*18,64+math.floor(i/COLS)*12
          swatch(row.id,x,y,16,10);border(x,y,16,10,first+i==self.index)
        end
      end
      local row=self.rows[self.index]
      local label=row.label:gsub("COLOUR",config.colourWord())
      if config.colourWord()=="COLOR" then label=label:gsub("GREY","GRAY") end
      text(label:sub(1,18),8,112)
      text(row.id=="original" and "UNCHANGED ART" or "HEX "..P.hex(row.id):sub(2),8,120)
      text(self.notice or "A:SET B:SECTIONS",8,128)
      text(("SEL:RGB  P%d/%d"):format(page+1,math.ceil(#self.rows/PER_PAGE)),8,136)
    end
    return self
  end}
  mod.content.screens:register("BicyclePlusPicker",factory)
  function api.open(game,key,label)
    if not game or not keys[key] or Runtime.safeMode then return false end
    return Screens.push(game,"BicyclePlusPicker",{key=key,label=label})
  end
  api.factory=factory -- deterministic menu tests, without replacing game input
  return api
end
return Picker
