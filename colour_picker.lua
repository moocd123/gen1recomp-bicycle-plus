-- One HSV chart, exact RGB/hex fields, and a controller/touch numeric keypad.
-- No palette pages. Drafts affect only the preview until APPLY/A confirms.
local Picker={}
function Picker.init(mod,config)
  local P,C,U=assert(config.hardware),assert(config.colours),assert(config.ui)
  local get,set=assert(config.getSetting),assert(config.setSetting)
  local Screens=require('src.ui.Screens');local Runtime=require('src.mods.Runtime')
  local api={};local keys={bike_colour=true,bike_stripes_colour=true,bike_centres_colour=true,
    bike_tyres_colour=true,bike_frame_colour=true,bike_handlebars_colour=true}
  local plane={8,18,88,72};local light={101,18,7,72}
  local rects={r={114,49,38,11},g={114,63,38,11},b={114,77,38,11},hex={8,94,100,11},
    apply={8,128,46,13},cancel={106,128,46,13}}
  local focusOrder={'plane','light','r','g','b','hex','apply','cancel'}
  local function release(o)if o and o.release then o:release()end end
  local function nextFocus(self,delta)
    local at=1;for i,name in ipairs(focusOrder)do if name==self.focus then at=i;break end end
    self.focus=focusOrder[(at-1+delta)%#focusOrder+1]
  end
  local factory={new=function(game,opts)
    opts=opts or {};assert(keys[opts.key],'Unknown bicycle part')
    local id=P.canonical(get(opts.key));if not id or id=='original' then id=P.canonical(opts.initial)or P.canonical('green')end
    if id=='original' then id=P.canonical('green')end
    local self={game=game,key=opts.key,part=opts.label or 'BICYCLE',saved=id,draft=id,
      timer=0,focus='plane',isOpaque=true,isModOptions=true,screenId='BicyclePlusPicker',_bicycleUI=U,
      refs=P.references(game),edit=nil}
    function self:sgbPalettes()return{{colors=false,x=0,y=0,w=160,h=144}}end
    function self:exit()release(self.planeImage);release(self.lightImage);self.planeImage=nil;self.lightImage=nil;self.edit=nil end
    function self:setRGB(r,g,b)
      local value=P.exact(r,g,b);if not value then return false end
      self.r,self.g,self.b=r,g,b;self.draft=value
      local h,s,v=P.toHSV(r,g,b)
      if s>0 then self.h=h end
      self.h=self.h or 0
      -- Keep hue/saturation when value reaches zero so lightening black
      -- restores the chosen hue rather than unexpectedly turning it grey.
      if v>0 or self.s==nil then self.s=s end
      self.v=v;self.notice=nil;return true
    end
    function self:fromHSV()
      local r,g,b=P.fromHSV(self.h,self.s,self.v)
      self.r,self.g,self.b=r,g,b;self.draft=P.exact(r,g,b);self.notice=nil
    end
    local initial=P.rgb(id);self:setRGB(initial[1],initial[2],initial[3]);self.draft=id
    function self:apply()
      if not Runtime.safeMode and set(self.game,self.key,self.draft) then self.game.stack:pop();return true end
      self.notice='NOT SAVED';return false
    end
    function self:beginEdit(field)
      local s=field=='hex' and P.hex(self.draft):sub(2) or tostring(self[field])
      self.edit={field=field,buffer=s,replace=true,index=1}
      self.focus=field;self.repeatKey=nil;self.drag=nil
    end
    function self:commitEdit()
      local ed=self.edit;if not ed then return false end
      if ed.field=='hex' then
        local id=P.parseHex(ed.buffer)
        if not id then ed.error='ENTER 6 HEX DIGITS';return false end
        local c=P.rgb(id);self:setRGB(c[1],c[2],c[3])
      else
        local n=ed.buffer:match('^%d%d?%d?$') and tonumber(ed.buffer)
        if not n or n>255 then ed.error='USE 0-255';return false end
        local r,g,b=self.r,self.g,self.b
        if ed.field=='r'then r=n elseif ed.field=='g'then g=n else b=n end
        self:setRGB(r,g,b)
      end
      self.edit=nil;self.repeatKey=nil;return true
    end
    function self:typeText(text,paste)
      local ed=self.edit;if not ed then return false end
      text=tostring(text):upper()
      if paste then text=text:match('^%s*(.-)%s*$'):gsub('^#','')end
      local valid=ed.field=='hex' and not text:find('[^0-9A-F]') or ed.field~='hex' and not text:find('[^0-9]')
      local max=ed.field=='hex' and 6 or 3
      if not valid then ed.error='INVALID INPUT';return true end
      local value=(ed.replace or paste) and text or ed.buffer..text
      if #value<=max then ed.buffer=value;ed.replace=false;ed.error=nil end
      return true
    end
    function self:erase()
      if self.edit then
        self.edit.buffer=self.edit.replace and '' or self.edit.buffer:sub(1,-2)
        self.edit.replace=false;self.edit.error=nil
      end
    end
    function self:rawKey(key)
      if not self.edit then
        if key=='tab'then nextFocus(self,1);return true end
        if key=='escape'then self.game.stack:pop();return true end
        if key=='return'or key=='kpenter'then
          if self.focus=='cancel'then self.game.stack:pop()
          elseif rects[self.focus]and self.focus~='apply'then self:beginEdit(self.focus)
          else self:apply()end
          return true
        end
        return false
      end
      local ctrl=love.keyboard and love.keyboard.isDown and
        (love.keyboard.isDown('lctrl')or love.keyboard.isDown('rctrl')or love.keyboard.isDown('lgui')or love.keyboard.isDown('rgui'))
      if ctrl and key=='a'then self.edit.replace=true;return true end
      if ctrl and key=='v'then
        if love.system and love.system.getClipboardText then
          local ok,text=pcall(love.system.getClipboardText)
          if ok then self:typeText(text,true)else self.edit.error='PASTE UNAVAILABLE'end
        end
        return true
      end
      if key=='left'or key=='right'or key=='up'or key=='down'then
        self:movePad(key);return true
      end
      if key=='space'then self:padAction(self:pad()[self.edit.index]);return true end
      if key=='escape'then self.edit=nil;return true end
      if key=='return'or key=='kpenter'then self:commitEdit();return true end
      if key=='tab'then if self:commitEdit()then nextFocus(self,1)end;return true end
      if key=='backspace'then self:erase();return true end
      if key=='delete'then self.edit.buffer='';self.edit.replace=false;return true end
      local char=key:match('^kp(%d)$')or (#key==1 and key)
      if char then self:typeText(char)end
      -- Raw field typing must not trigger game hotkeys or mapped A/B buttons.
      return true
    end
    function self:pad()
      if self.edit.field=='hex' then return {'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F','DEL','CLR','OK','BACK'}end
      return {'7','8','9','DEL','4','5','6','CLR','1','2','3','OK','0','','','BACK'}
    end
    function self:movePad(key)
      local pad=self:pad();local delta=key=='left'and -1 or key=='right'and 1 or key=='up'and -4 or 4
      local at=self.edit.index
      for _=1,#pad do at=(at-1+delta)%#pad+1;if pad[at]~=''then break end end
      self.edit.index=at
    end
    function self:padAction(label)
      if label=='DEL'then self:erase()
      elseif label=='CLR'then self.edit.buffer='';self.edit.replace=false;self.edit.error=nil
      elseif label=='OK'then self:commitEdit()
      elseif label=='BACK'then self.edit=nil
      elseif label~=''then self:typeText(label)end
    end
    function self:update(dt)
      self.timer=self.timer+(dt or 0);local input=self.game.input
      if self.edit then
        if input:wasPressed('b')then self.edit=nil;return end
        if input:wasPressed('start')then self:commitEdit();return end
        if input:wasPressed('select')then self:erase();return end
        if input:wasPressed('a')then self:padAction(self:pad()[self.edit.index]);return end
        local key=U.tapDirection(self)
        if key then self:movePad(key)end
        return
      end
      if input:wasPressed('b')or input:wasPressed('start')then self.game.stack:pop();return end
      if input:wasPressed('select')then nextFocus(self,1);return end
      if input:wasPressed('a')then
        if self.focus=='cancel'then self.game.stack:pop()
        elseif rects[self.focus]and self.focus~='apply'then self:beginEdit(self.focus)
        else self:apply()end
        return
      end
      local key=U.direction(self,dt);if not key then return end
      if self.focus=='plane'then
        if key=='left'or key=='right'then self.h=(self.h+(key=='left'and -1 or 1))%360
        else self.s=math.max(0,math.min(1,self.s+(key=='up'and 1 or -1)/255))end
        self:fromHSV()
      elseif self.focus=='light'then
        self.v=math.max(0,math.min(1,self.v+((key=='up'or key=='right')and 1 or -1)/255));self:fromHSV()
      elseif self.focus=='r'or self.focus=='g'or self.focus=='b'then
        if key=='up'or key=='down'then nextFocus(self,key=='up'and -1 or 1)
        else local r,g,b=self.r,self.g,self.b;local n=math.max(0,math.min(255,self[self.focus]+(key=='right'and 1 or -1)))
          if self.focus=='r'then r=n elseif self.focus=='g'then g=n else b=n end;self:setRGB(r,g,b)
        end
      else nextFocus(self,(key=='left'or key=='up')and -1 or 1)end
    end
    function self:pickXY(target,x,y)
      if target=='plane'then
        self.h=math.max(0,math.min(1,(x-plane[1])/(plane[3]-1)))*359.999
        self.s=1-math.max(0,math.min(1,(y-plane[2])/(plane[4]-1)))
      else self.v=1-math.max(0,math.min(1,(y-light[2])/(light[4]-1)))end
      self.focus=target;self:fromHSV()
    end
    function self:pointer(e,x,y)
      if e.phase=='cancelled'or e.phase=='released'then
        if self.drag and self.drag.id==e.id then self.drag=nil end;return true
      end
      if e.phase=='moved' and self.drag and self.drag.id==e.id then self:pickXY(self.drag.target,x,y);return true end
      if e.phase~='pressed' and e.phase~='moved'then return false end
      if e.source=='mouse'and e.phase=='pressed'and e.button~=1 then return false end
      if self.edit then
        local pad=self:pad()
        for i,label in ipairs(pad)do
          local r={12+(i-1)%4*35,50+math.floor((i-1)/4)*15,31,13}
          if label~=''and U.hit(x,y,r)then self.edit.index=i;if e.phase=='pressed'then self:padAction(label)end;return true end
        end
        return x>=0 and x<160 and y>=0 and y<144
      end
      local target=U.hit(x,y,plane)and'plane'or U.hit(x,y,light)and'light'
      if target then
        self.focus=target
        if e.phase=='pressed'then self.drag={id=e.id,target=target};self:pickXY(target,x,y)end
        return true
      end
      for name,r in pairs(rects)do if U.hit(x,y,r)then
        self.focus=name
        if e.phase=='pressed'then
          if name=='apply'then self:apply()elseif name=='cancel'then self.game.stack:pop()else self:beginEdit(name)end
        end
        return true
      end end
      return x>=0 and x<160 and y>=0 and y<144
    end
    function self:images()
      local G=love.graphics
      if not self.planeImage or self.planeValue~=self.v then
        local d=love.image.newImageData(plane[3],plane[4])
        for y=0,plane[4]-1 do for x=0,plane[3]-1 do
          local r,g,b=P.fromHSV(x/(plane[3]-1)*359.999,1-y/(plane[4]-1),self.v)
          d:setPixel(x,y,r/255,g/255,b/255,1)
        end end
        release(self.planeImage);self.planeImage=G.newImage(d);self.planeImage:setFilter('nearest','nearest');release(d);self.planeValue=self.v
      end
      if not self.lightImage or self.lightHue~=self.h or self.lightSat~=self.s then
        local d=love.image.newImageData(1,light[4])
        for y=0,light[4]-1 do local r,g,b=P.fromHSV(self.h,self.s,1-y/(light[4]-1));d:setPixel(0,y,r/255,g/255,b/255,1)end
        release(self.lightImage);self.lightImage=G.newImage(d);self.lightImage:setFilter('nearest','nearest');release(d);self.lightHue,self.lightSat=self.h,self.s
      end
    end
    function self:drawEdit()
      local ed=self.edit;U.background()
      local label=ed.field=='hex'and'HEX RRGGBB'or (ed.field:upper()..' VALUE 0-255')
      U.centre(label,8)
      local buffer=ed.buffer~=''and ed.buffer or '-';local x=math.floor((160-U.width(buffer,2))/2)
      if ed.replace then U.focus(x-2,22,U.width(buffer,2)+4,18)end
      U.text(buffer,x,24,2)
      local pad=self:pad()
      for i,s in ipairs(pad)do if s~=''then U.button(s,{12+(i-1)%4*35,50+math.floor((i-1)/4)*15,31,13},ed.index==i)end end
      U.centre(ed.error or 'A:KEY  B:CANCEL',130)
    end
    function self:draw()
      if self.edit then self:drawEdit();return end
      U.background();U.text(self.part,8,5);U.text('LIGHT',88,5)
      self:images();U.white();local G=love.graphics
      G.draw(self.planeImage,plane[1],plane[2]);G.draw(self.lightImage,light[1],light[2],0,light[3],1)
      U.border(plane[1]-1,plane[2]-1,plane[3]+2,plane[4]+2);U.border(light[1]-1,light[2]-1,light[3]+2,light[4]+2)
      local x=plane[1]+math.floor(self.h/360*(plane[3]-1)+0.5)
      local y=plane[2]+math.floor((1-self.s)*(plane[4]-1)+0.5)
      U.ink();G.rectangle('fill',x-3,y-1,7,3);G.rectangle('fill',x-1,y-3,3,7)
      U.white();G.rectangle('fill',x-2,y,5,1);G.rectangle('fill',x,y-2,1,5)
      local ly=light[2]+math.floor((1-self.v)*(light[4]-1)+0.5)
      U.ink();G.rectangle('fill',light[1]-2,ly-1,light[3]+4,3);U.white();G.rectangle('fill',light[1]-1,ly,light[3]+2,1)
      if self.focus=='plane'then U.marker(0,20)elseif self.focus=='light'then U.marker(110,20)end
      U.white();U.preview(C,self.game,118,13,2,self.timer,{[self.key]=self.draft},self.key=='bike_handlebars_colour'and'down'or'left')
      for _,name in ipairs({'r','g','b','hex'})do
        local r=rects[name];if self.focus==name then U.focus(r[1],r[2],r[3],r[4])end;U.border(r[1],r[2],r[3],r[4])
        U.text(name=='hex'and('HEX '..P.hex(self.draft):sub(2))or(name:upper()..':'..('%03d'):format(self[name])),r[1]+3,r[2]+2)
      end
      local c=P.rgb(self.draft);G.setColor(c[1]/255,c[2]/255,c[3]/255,1);G.rectangle('fill',114,94,38,11);U.border(114,94,38,11)
      local descriptions=P.describe(self.draft,self.refs);local at=math.floor(self.timer/3)%#descriptions+1
      local label=self.notice or descriptions[at].text
      local max=24;local l1,l2=label,''
      if #label>max then local split=label:sub(1,max):match('^.*() ')or max;l1=label:sub(1,split);l2=label:sub(split+1)end
      U.text(l1,8,109);if l2~=''then U.text(l2:sub(1,24),8,118)elseif #descriptions>1 then U.text(('MATCH %d/%d'):format(at,#descriptions),8,118)end
      U.button('APPLY',rects.apply,self.focus=='apply');U.button('CANCEL',rects.cancel,self.focus=='cancel')
      U.text('SELECT',58,126);U.text('NEXT',64,136);U.white()
    end
    return self
  end}
  mod.content.screens:register('BicyclePlusPicker',factory)
  function api.open(game,key,label,initial)
    if not game or not keys[key]or Runtime.safeMode then return false end
    return Screens.push(game,'BicyclePlusPicker',{key=key,label=label,initial=initial})
  end
  api.factory=factory
  return api
end
return Picker
