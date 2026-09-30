-- GBA-native counterpart of the existing Original/Custom colour editor.
-- All painting is preview-only until Apply. Fields have a controller keypad.
local M={}
function M.init(mod,U,H,S,paint)
 local api={}
 local G=love.graphics
 local plane={12,22,132,78};local light={153,22,9,78}
 local rects={r={174,46,54,16},g={174,65,54,16},b={174,84,54,16},hex={12,106,150,16},
  apply={12,142,58,16},cancel={174,142,54,16}}
 local order={'plane','light','r','g','b','hex','apply','cancel'}
 local function release(v)if v and v.release then v:release()end end
 local function clamp(v,lo,hi)return math.max(lo,math.min(hi,v))end
 local function focus(s,d)
  local pos=1;for i,v in ipairs(order)do if v==s.focus then pos=i;break end end
  s.focus=order[(pos-1+d)%#order+1];s._repeatKey=nil
 end
 local function padFor(field)
  if field=='hex'then return{'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F','DEL','CLR','OK','BACK'}end
  return{'7','8','9','DEL','4','5','6','CLR','1','2','3','OK','0','','','BACK'}
 end
 function api.open(game,key,label,initial)
  local id=H.canonical(initial)or H.canonical('green')
  if id=='original'then id=H.canonical('green')end
  local s={game=game,key=key,label=label,focus='plane',draft=id,timer=0,refs=H.references(game)}
  function s:setRGB(r,g,b)
   local value=H.exact(r,g,b);if not value then return false end
   self.draft=value;self.r,self.g,self.b=r,g,b
   local h,sat,v=H.toHSV(r,g,b)
   if sat>0 or self.h==nil then self.h=h end
   if v>0 or self.s==nil then self.s=sat end
   self.v=v;return true
  end
  local c=H.rgb(id);s:setRGB(c[1],c[2],c[3]);s.draft=id
  function s:fromHSV()
   local r,g,b=H.fromHSV(self.h,self.s,self.v)
   self.r,self.g,self.b=r,g,b;self.draft=H.exact(r,g,b)
  end
  function s:apply()
   if S.set(game,key,self.draft)then U.pop(self);return true end
   self.notice='NOT SAVED';return false
  end
  function s:editField(field)
   self.edit={field=field,buffer=field=='hex'and H.hex(self.draft):sub(2)or tostring(self[field]),replace=true,index=1}
   self.focus=field;self._repeatKey=nil;self.drag=nil
  end
  function s:typeText(str,paste)
   local ed=self.edit;if not ed then return false end
   str=tostring(str):upper();if paste then str=str:match('^%s*(.-)%s*$'):gsub('^#','')end
   local invalid=ed.field=='hex'and str:find('[^0-9A-F]')or ed.field~='hex'and str:find('[^0-9]')
   if invalid then ed.error='INVALID INPUT';return true end
   local value=(paste or ed.replace)and str or ed.buffer..str
   if #value<=(ed.field=='hex'and 6 or 3)then ed.buffer=value;ed.replace=false;ed.error=nil end
   return true
  end
  function s:erase()
   local ed=self.edit;ed.buffer=ed.replace and''or ed.buffer:sub(1,-2);ed.replace=false;ed.error=nil
  end
  function s:commitEdit()
   local ed=self.edit;if not ed then return false end
   if ed.field=='hex'then
    local v=H.parseHex(ed.buffer);if not v then ed.error='ENTER 6 HEX DIGITS';return false end
    local c=H.rgb(v);self:setRGB(c[1],c[2],c[3])
   else
    local n=ed.buffer:match('^%d%d?%d?$')and tonumber(ed.buffer)
    if not n or n>255 then ed.error='USE 0-255';return false end
    local r,g,b=self.r,self.g,self.b
    if ed.field=='r'then r=n elseif ed.field=='g'then g=n else b=n end
    self:setRGB(r,g,b)
   end
   self.edit=nil;self._repeatKey=nil;return true
  end
  function s:padAction(str)
   if str=='OK'then self:commitEdit()
   elseif str=='BACK'then self.edit=nil
   elseif str=='DEL'then self:erase()
   elseif str=='CLR'then self.edit.buffer='';self.edit.replace=false
   elseif str~=''then self:typeText(str)end
  end
  function s:movePad(k)
   local pad=padFor(self.edit.field);local d=k=='left'and-1 or k=='right'and 1 or k=='up'and-4 or 4
   local pos=self.edit.index
   for _=1,#pad do pos=(pos-1+d)%#pad+1;if pad[pos]~=''then break end end
   self.edit.index=pos
  end
  function s:rawKey(k)
   if self.edit then
    local ctrl=love.keyboard and love.keyboard.isDown and (love.keyboard.isDown('lctrl','rctrl','lgui','rgui'))
    if ctrl and k=='v'then
     if love.system and love.system.getClipboardText then local ok,v=pcall(love.system.getClipboardText);if ok then self:typeText(v,true)end end
    elseif ctrl and k=='a'then self.edit.replace=true
    elseif k=='return'or k=='kpenter'then self:commitEdit()
    elseif k=='escape'then self.edit=nil
    elseif k=='backspace'then self:erase()
    elseif k=='delete'then self.edit.buffer='';self.edit.replace=false
    elseif k=='tab'then if self:commitEdit()then focus(self,1)end
    elseif k=='up'or k=='down'or k=='left'or k=='right'then self:movePad(k)
    else local c=k:match('^kp(%d)$')or(#k==1 and k);if c then self:typeText(c)end end
    return true
   end
   if k=='tab'then focus(self,1);return true end
   if k=='escape'then U.pop(self);return true end
   if k=='return'or k=='kpenter'then self:activate();return true end
   return false
  end
  function s:activate()
   if self.focus=='cancel'then U.pop(self)
   elseif rects[self.focus]and self.focus~='apply'then self:editField(self.focus)
   else self:apply()end
  end
  function s:handleInput(input,dt)
   if self.edit then
    if input:wasPressed('b')then self.edit=nil;return end
    if input:wasPressed('start')then self:commitEdit();return end
    if input:wasPressed('select')then self:erase();return end
    if input:wasPressed('a')then self:padAction(padFor(self.edit.field)[self.edit.index]);return end
    local k=U.tap(self);if k then self:movePad(k)end;return
   end
   if input:wasPressed('b')or input:wasPressed('start')then U.pop(self);return end
   if input:wasPressed('select')then focus(self,1);return end
   if input:wasPressed('a')then self:activate();return end
   local k=U.direction(self,dt or 1/60);if not k then return end
   if self.focus=='plane'then
    if k=='left'or k=='right'then self.h=(self.h+(k=='left'and-1 or 1))%360
    else self.s=clamp(self.s+(k=='up'and 1 or-1)/255,0,1)end;self:fromHSV()
   elseif self.focus=='light'then self.v=clamp(self.v+((k=='up'or k=='right')and 1 or-1)/255,0,1);self:fromHSV()
   elseif self.focus=='r'or self.focus=='g'or self.focus=='b'then
    if k=='up'or k=='down'then focus(self,k=='up'and-1 or 1)
    else
     local r,g,b=self.r,self.g,self.b;local n=clamp(self[self.focus]+(k=='right'and 1 or-1),0,255)
     if self.focus=='r'then r=n elseif self.focus=='g'then g=n else b=n end
     self:setRGB(r,g,b)
    end
   else focus(self,(k=='left'or k=='up')and-1 or 1)end
  end
  function s:pick(target,x,y)
   self.focus=target
   if target=='plane'then self.h=clamp((x-plane[1])/(plane[3]-1),0,1)*359.999;self.s=1-clamp((y-plane[2])/(plane[4]-1),0,1)
   else self.v=1-clamp((y-light[2])/(light[4]-1),0,1)end
   self:fromHSV()
  end
  function s:pointer(e,x,y)
   if e.phase=='released'or e.phase=='cancelled'then if self.drag and self.drag.id==e.id then self.drag=nil end;return true end
   if e.phase=='moved'and self.drag and self.drag.id==e.id then self:pick(self.drag.target,x,y);return true end
   if e.phase~='pressed'and e.phase~='moved'then return false end
   if self.edit then
    for i,c in ipairs(padFor(self.edit.field))do
     if c~=''and U.hit(x,y,{24+(i-1)%4*49,49+math.floor((i-1)/4)*17,45,16})then
      self.edit.index=i;if e.phase=='pressed'then self:padAction(c)end;return true
     end
    end;return true
   end
   local target=U.hit(x,y,plane)and'plane'or U.hit(x,y,light)and'light'
   if target then self.focus=target;if e.phase=='pressed'then self.drag={target=target,id=e.id};self:pick(target,x,y)end;return true end
   for name,r in pairs(rects)do if U.hit(x,y,r)then self.focus=name;if e.phase=='pressed'then self:activate()end;return true end end
   return true
  end
  function s:images()
   if not self.chart or self.chartV~=self.v then
    local d=love.image.newImageData(plane[3],plane[4])
    for y=0,plane[4]-1 do for x=0,plane[3]-1 do
     local r,g,b=H.fromHSV(x/(plane[3]-1)*359.999,1-y/(plane[4]-1),self.v);d:setPixel(x,y,r/255,g/255,b/255,1)
    end end
    release(self.chart);self.chart=G.newImage(d);self.chart:setFilter('nearest','nearest');d:release();self.chartV=self.v
   end
   if not self.lightImage or self.lightH~=self.h or self.lightS~=self.s then
    local d=love.image.newImageData(1,light[4])
    for y=0,light[4]-1 do local r,g,b=H.fromHSV(self.h,self.s,1-y/(light[4]-1));d:setPixel(0,y,r/255,g/255,b/255,1)end
    release(self.lightImage);self.lightImage=G.newImage(d);self.lightImage:setFilter('nearest','nearest');d:release();self.lightH=self.h;self.lightS=self.s
   end
  end
  function s:exit()release(self.chart);release(self.lightImage);self.chart=nil;self.lightImage=nil;self.drag=nil end
  function s:draw()
   U.background(game)
   if self.edit then
    local ed=self.edit;U.centre(ed.field=='hex'and'HEX RRGGBB'or(ed.field:upper()..' VALUE 0-255'),10)
    if ed.replace then U.focus(45,28,150,15)end
    U.centre(ed.buffer==''and'-'or ed.buffer,28)
    for i,c in ipairs(padFor(ed.field))do if c~=''then U.button(c,{24+(i-1)%4*49,49+math.floor((i-1)/4)*17,45,16},self.edit.index==i)end end
    U.centre(ed.error or'A:KEY  B:CANCEL',142);return
   end
   U.text(label,12,4);U.text('LIGHT',133,4)
   self:images();G.setColor(1,1,1,1);G.draw(self.chart,plane[1],plane[2]);G.draw(self.lightImage,light[1],light[2],0,light[3],1)
   U.border(plane[1]-1,plane[2]-1,plane[3]+2,plane[4]+2);U.border(light[1]-1,light[2]-1,light[3]+2,light[4]+2)
   local x=plane[1]+math.floor(self.h/360*(plane[3]-1)+.5);local y=plane[2]+math.floor((1-self.s)*(plane[4]-1)+.5)
   U.clip(plane[1],plane[2],plane[3],plane[4],function()
    G.setColor(0,0,0,1);G.rectangle('fill',x-3,y-1,7,3);G.rectangle('fill',x-1,y-3,3,7)
    G.setColor(1,1,1,1);G.rectangle('fill',x-2,y,5,1);G.rectangle('fill',x,y-2,1,5)
   end)
   local ly=light[2]+math.floor((1-self.v)*(light[4]-1)+.5)
   G.setColor(0,0,0,1);G.rectangle('fill',light[1]-2,ly-1,light[3]+4,3)
   G.setColor(1,1,1,1);G.rectangle('fill',light[1]-1,ly,light[3]+2,1)
   if self.focus=='plane'then U.marker(4,25)elseif self.focus=='light'then U.marker(165,25)end
   paint.drawPreview(game,185,8,1,self.timer,{[key]=self.draft},key=='bike_handlebars_colour'and'down'or'left')
   for _,name in ipairs({'r','g','b','hex'})do
    local r=rects[name];if self.focus==name then U.focus(unpack(r))end;U.border(unpack(r))
    U.text(name=='hex'and('HEX '..H.hex(self.draft):sub(2))or(name:upper()..':'..('%03d'):format(self[name])),r[1]+3,r[2]+1)
   end
   G.setColor(self.r/255,self.g/255,self.b/255,1);G.rectangle('fill',174,106,54,16);U.border(174,106,54,16)
   local descriptions=H.describe(self.draft,self.refs);local which=math.floor(self.timer/3)%#descriptions+1
   U.marquee(self.notice or descriptions[which].text,12,126,216,self.timer)
   U.button('APPLY',rects.apply,self.focus=='apply');U.button('CANCEL',rects.cancel,self.focus=='cancel');U.text('SELECT:NEXT',82,144)
  end
  return U.push(s)
 end
 function api.appearance(game)
  local rows={{key='bike_colour',label='WHEEL'},{key='bike_stripes_colour',label='STRIPE'},
   {key='bike_centres_colour',label=S.centre(game)},{key='bike_tyres_colour',label='EDGE'},{key='bike_handlebars_colour',label='HANDLEBARS'},
   {reset=true,label='RESET '..S.word(game)..'S'}}
  local s={game=game,rows=rows,index=1,timer=0,tag='autobike.appearance'}
  function s:toggle(dir)
   local k=rows[self.index].key;if not k then return end
   if S.profiles then return S.profiles.step(game,k,dir or 1)end
   local old=S.get(k,game)
   S.set(game,k,old=='original'and S.remembered(game,k)or'original')
  end
  function s:activate()
   local row=rows[self.index]
   if row.reset then U.confirm(game,'RESET '..S.word(game)..'S?','OTHER SETTINGS UNCHANGED',function()return S.reset(game)end)
   elseif (S.profiles and S.profiles.selection(row.key,game)=='original')or(not S.profiles and S.get(row.key,game)=='original')then
    if S.profiles then S.profiles.select(game,row.key,'original')else S.set(game,row.key,'original')end
   else api.open(game,row.key,row.label,S.remembered(game,row.key))end
  end
  function s:handleInput(input)
   if input:wasPressed('b')or input:wasPressed('start')then U.pop(self);return end
   if input:wasPressed('a')then self:activate();return end
   local k=U.tap(self)
   if k=='up'then self.index=(self.index-2)%#rows+1
   elseif k=='down'then self.index=self.index%#rows+1
   elseif k=='left'or k=='right'then self:toggle(k=='left'and -1 or 1)end
  end
  function s:pointer(e,x,y)
   if e.phase~='pressed'and e.phase~='moved'then return true end
   for i,row in ipairs(rows)do if U.hit(x,y,{10,47+(i-1)*14,220,14})then
    self.index=i;if e.phase=='pressed'then if row.key and x>=151 then self:toggle()else self:activate()end end;return true
   end end
   if e.phase=='pressed'and U.hit(x,y,{184,145,48,15})then U.pop(self)end
   return true
  end
  function s:draw()
   U.background(game);paint.drawTriple(game,32,10,1,self.timer)
   for i,row in ipairs(rows)do
    local y=47+(i-1)*14;if i==self.index then U.focus(10,y,220,14);U.marker(13,y+4)end
    U.text(row.label,23,y)
    if row.key then local text=S.profiles and S.profiles.selection(row.key,game):upper()or(S.get(row.key,game)=='original'and'ORIGINAL'or'CUSTOM');U.text(text,225-U.width(text),y)end
   end
   U.centre(S.profiles and'LR:PROFILE'or('LR:'..S.word(game)..' TYPE'),131);U.text('A:PICK',12,145);U.text('B:BACK',190,145)
  end
  return U.push(s)
 end
 return api
end
return M
