-- Native FireRed colour editor for the isolated AUTOBIKE+ beta.
-- Uses the ROM-derived Gen3 font/window chrome. Controller/menu movement is
-- edge-triggered, while colour adjustment may repeat while a direction is held.
local Picker={}

local PART_KEYS={
 bike_frame_colour=true,bike_tyres_colour=true,bike_rims_colour=true,
 bike_spokes_colour=true,bike_handlebars_colour=true,
}
local FOCUS={'plane','light','r','g','b','hex','original','apply','cancel'}
local RECTS={
 plane={18,48,96,56},light={122,48,10,56},
 r={150,48,72,14},g={150,64,72,14},b={150,80,72,14},hex={150,96,72,14},
 original={18,120,62,18},apply={88,120,62,18},cancel={158,120,64,18},
}

local function clamp(v,a,b)return math.max(a,math.min(b,v))end
local function hexByte(n)return('%02X'):format(clamp(math.floor(tonumber(n)or 0),0,255))end
local function rgbHex(r,g,b)return'#'..hexByte(r)..hexByte(g)..hexByte(b)end
local function parseHex(v)
 v=tostring(v or''):gsub('^#','')
 if not v:match('^%x%x%x%x%x%x$')then return nil end
 return tonumber(v:sub(1,2),16),tonumber(v:sub(3,4),16),tonumber(v:sub(5,6),16)
end
local function rgbToHsv(r,g,b)
 r,g,b=r/255,g/255,b/255
 local mx=math.max(r,g,b);local mn=math.min(r,g,b);local d=mx-mn
 local h=0
 if d~=0 then
  if mx==r then h=60*(((g-b)/d)%6)
  elseif mx==g then h=60*((b-r)/d+2)
  else h=60*((r-g)/d+4)end
 end
 return h,mx==0 and 0 or d/mx,mx
end
local function hsvToRgb(h,s,v)
 h=(tonumber(h)or 0)%360;s=clamp(tonumber(s)or 0,0,1);v=clamp(tonumber(v)or 0,0,1)
 local c=v*s;local x=c*(1-math.abs((h/60)%2-1));local m=v-c
 local r,g,b
 if h<60 then r,g,b=c,x,0 elseif h<120 then r,g,b=x,c,0 elseif h<180 then r,g,b=0,c,x
 elseif h<240 then r,g,b=0,x,c elseif h<300 then r,g,b=x,0,c else r,g,b=c,0,x end
 return math.floor((r+m)*255+0.5),math.floor((g+m)*255+0.5),math.floor((b+m)*255+0.5)
end
local function hit(x,y,r)return x>=r[1]and x<r[1]+r[3]and y>=r[2]and y<r[2]+r[4]end

function Picker.new(mod,settings,services)
 local S=services or{}
 local Stack=S.Stack or require('src.ui.game3.stack')
 local Window=S.Window or require('src.ui.game3.window')
 local Chrome=S.Chrome or require('src.ui.game3.chrome')
 local Font=S.Font or require('src.ui.game3.frlg_font')
 local Options=S.Options or require('src.core.game3.options')
 local G=S.graphics or love.graphics
 local System=S.system or(love and love.system)
 local Keyboard=S.keyboard or(love and love.keyboard)
 local api={serial=0}
 local current

 local function topPicker()
  local top=Stack.top();local m=top and top.mod
  return m and m._autobikeGen3Picker and m or nil
 end
 local function measure(s)return Font.measure(tostring(s or''))end
 local function printText(s,x,y)Window.printPx(tostring(s or''),x,y,{colors=Font.COLOR.NORMAL})end
 local function nextFocus(m,d)
  local at=1;for i,v in ipairs(FOCUS)do if v==m.focus then at=i;break end end
  m.focus=FOCUS[(at-1+d)%#FOCUS+1];m.repeatKey=nil
 end
 local function remembered(game,key)
  if settings.getRememberedColour then return settings.getRememberedColour(key,game)end
  local cur=settings.get(key,game)
  if type(cur)=='string'and cur~='original'and parseHex(cur)then return cur end
  return'#C53A3A'
 end
 local function pad(edit)
  if edit.field=='hex'then return{'0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F','DEL','CLR','OK','BACK'}end
  return{'7','8','9','DEL','4','5','6','CLR','1','2','3','OK','0','','','BACK'}
 end
 local function padRect(i)return{34+(i-1)%4*44,48+math.floor((i-1)/4)*20,38,16}end

 function api.open(game,key,label)
  assert(game and PART_KEYS[key],'FireRed bicycle colour key required')
  api.serial=api.serial+1
  local id='autobike-gen3-colour-'..api.serial
  local seed=settings.get(key,game);local original=seed=='original'
  if original then seed=remembered(game,key)end
  local r,g,b=parseHex(seed);if not r then r,g,b=197,58,58 end
  local h,s,v=rgbToHsv(r,g,b)
  local m={_autobikeGen3Picker=true,game=game,key=key,label=label or'BICYCLE',focus='plane',
   r=r,g=g,b=b,h=h,s=s,v=v,originalDraft=original,edit=nil,timer=0,repeatKey=nil,lastInput=nil}
  current=m
  local function close()if current==m then current=nil end;Stack.pop(id)end
  local function setRGB(rr,gg,bb)
   m.r,m.g,m.b=clamp(math.floor(rr+0.5),0,255),clamp(math.floor(gg+0.5),0,255),clamp(math.floor(bb+0.5),0,255)
   local nh,ns,nv=rgbToHsv(m.r,m.g,m.b);if ns>0 then m.h=nh end;m.s=ns;m.v=nv;m.originalDraft=false
  end
  local function fromHSV()
   local rr,gg,bb=hsvToRgb(m.h,m.s,m.v);m.r,m.g,m.b=rr,gg,bb;m.originalDraft=false
  end
  local function apply()
   local value=m.originalDraft and'original'or rgbHex(m.r,m.g,m.b):lower()
   if value~='original'and settings.rememberColour then settings.rememberColour(game,key,value)end
   if settings.set(game,key,value)then close();return true end
   m.notice='NOT SAVED';return false
  end
  local function beginEdit(field)
   local text=field=='hex'and rgbHex(m.r,m.g,m.b):sub(2)or tostring(m[field])
   m.edit={field=field,buffer=text,replace=true,index=1};m.focus=field;m.repeatKey=nil
  end
  local function typeText(text,paste)
   local ed=m.edit;if not ed then return false end
   text=tostring(text or''):upper()
   if paste then text=text:match('^%s*(.-)%s*$'):gsub('^#','')end
   local valid=ed.field=='hex'and not text:find('[^0-9A-F]')or ed.field~='hex'and not text:find('[^0-9]')
   if not valid then ed.error='INVALID INPUT';return true end
   local max=ed.field=='hex'and 6 or 3
   local nv=(ed.replace or paste)and text or ed.buffer..text
   if #nv<=max then ed.buffer=nv;ed.replace=false;ed.error=nil end
   return true
  end
  local function erase()
   if not m.edit then return end
   m.edit.buffer=m.edit.replace and''or m.edit.buffer:sub(1,-2);m.edit.replace=false;m.edit.error=nil
  end
  local function commitEdit()
   local ed=m.edit;if not ed then return false end
   if ed.field=='hex'then
    local rr,gg,bb=parseHex(ed.buffer)
    if not rr then ed.error='ENTER 6 HEX DIGITS';return false end
    setRGB(rr,gg,bb)
   else
    local n=ed.buffer:match('^%d%d?%d?$')and tonumber(ed.buffer)
    if not n or n>255 then ed.error='USE 0-255';return false end
    local rr,gg,bb=m.r,m.g,m.b;if ed.field=='r'then rr=n elseif ed.field=='g'then gg=n else bb=n end
    setRGB(rr,gg,bb)
   end
   m.edit=nil;return true
  end
  local function padMove(dir)
   local p=pad(m.edit);local delta=dir=='left'and-1 or dir=='right'and 1 or dir=='up'and-4 or 4
   local at=m.edit.index
   for _=1,#p do at=(at-1+delta)%#p+1;if p[at]~=''then break end end
   m.edit.index=at
  end
  local function padAction(labelText)
   if labelText=='DEL'then erase()elseif labelText=='CLR'then m.edit.buffer='';m.edit.replace=false;m.edit.error=nil
   elseif labelText=='OK'then commitEdit()elseif labelText=='BACK'then m.edit=nil
   elseif labelText and labelText~=''then typeText(labelText,false)end
  end
  local function activate()
   if m.focus=='r'or m.focus=='g'or m.focus=='b'or m.focus=='hex'then beginEdit(m.focus)
   elseif m.focus=='original'then m.originalDraft=true
   elseif m.focus=='apply'then apply()elseif m.focus=='cancel'then close()end
  end
  local function adjust(dir)
   if m.edit then padMove(dir);return end
   if m.focus=='plane'then
    if dir=='left'or dir=='right'then m.h=(m.h+(dir=='left'and-2 or 2))%360
    else m.s=clamp(m.s+(dir=='up'and 1 or-1)/64,0,1)end;fromHSV()
   elseif m.focus=='light'then
    m.v=clamp(m.v+((dir=='up'or dir=='right')and 1 or-1)/64,0,1);fromHSV()
   elseif m.focus=='r'or m.focus=='g'or m.focus=='b'then
    if dir=='left'or dir=='right'then
     local delta=dir=='left'and-1 or 1;local rr,gg,bb=m.r,m.g,m.b
     if m.focus=='r'then rr=clamp(rr+delta,0,255)elseif m.focus=='g'then gg=clamp(gg+delta,0,255)else bb=clamp(bb+delta,0,255)end
     setRGB(rr,gg,bb)
    else nextFocus(m,dir=='up'and-1 or 1)end
   else nextFocus(m,(dir=='left'or dir=='up')and-1 or 1)end
  end
  function m.rawKey(keyName)
   keyName=tostring(keyName or'')
   if not m.edit then
    if keyName=='tab'then nextFocus(m,1);return true end
    if keyName=='escape'then close();return true end
    if keyName=='return'or keyName=='kpenter'then activate();return true end
    return false
   end
   local ctrl=Keyboard and Keyboard.isDown and(Keyboard.isDown('lctrl')or Keyboard.isDown('rctrl')or Keyboard.isDown('lgui')or Keyboard.isDown('rgui'))
   if ctrl and keyName=='a'then m.edit.replace=true;return true end
   if ctrl and keyName=='v'then
    if System and System.getClipboardText then local ok,text=pcall(System.getClipboardText);if ok then typeText(text,true)else m.edit.error='PASTE UNAVAILABLE'end end
    return true
   end
   if keyName=='escape'then m.edit=nil;return true end
   if keyName=='return'or keyName=='kpenter'then commitEdit();return true end
   if keyName=='tab'then if commitEdit()then nextFocus(m,1)end;return true end
   if keyName=='backspace'then erase();return true end
   if keyName=='delete'then m.edit.buffer='';m.edit.replace=false;return true end
   if keyName=='left'or keyName=='right'or keyName=='up'or keyName=='down'then padMove(keyName);return true end
   local ch=keyName:match('^kp(%d)$')or(#keyName==1 and keyName:upper())
   if ch and ch:match('^[0-9A-F]$')then typeText(ch,false);return true end
   return true
  end
  function m.handleInput(input)
   m.lastInput=input
   if m.edit then
    if input:wasPressed('b')then m.edit=nil;return true end
    if input:wasPressed('start')then commitEdit();return true end
    if input:wasPressed('select')then erase();return true end
    if input:wasPressed('a')then padAction(pad(m.edit)[m.edit.index]);return true end
    for _,d in ipairs({'up','down','left','right'})do if input:wasPressed(d)then padMove(d);return true end end
    return true
   end
   if input:wasPressed('b')then close();return true end
   if input:wasPressed('start')then apply();return true end
   if input:wasPressed('select')then nextFocus(m,1);return true end
   if input:wasPressed('a')then activate();return true end
   for _,d in ipairs({'up','down','left','right'})do
    if input:wasPressed(d)then adjust(d);m.repeatKey=d;m.repeatClock=.25;return true end
   end
   return true
  end
  function m.update(dt)
   m.timer=m.timer+math.min(.2,math.max(0,dt or 0))
   if m.edit or not m.repeatKey or not(m.lastInput and m.lastInput.isDown)then return end
   if not m.lastInput:isDown(m.repeatKey)then m.repeatKey=nil;return end
   m.repeatClock=(m.repeatClock or.25)-(dt or 0)
   if m.repeatClock<=0 then adjust(m.repeatKey);m.repeatClock=.04 end
  end
  function m.pointer(phase,x,y,idp)
   -- Coordinates are native 240x160. v0.2.66 Game3 does not yet expose the
   -- input.pointer hook, so the integration bridge can call this when one is
   -- available without changing picker geometry/state code.
   if phase~='pressed'and phase~='moved'then return true end
   if m.edit then
    if phase=='pressed'then for i,labelText in ipairs(pad(m.edit))do local rr=padRect(i);if labelText~=''and hit(x,y,rr)then m.edit.index=i;padAction(labelText);return true end end end
    return true
   end
   if hit(x,y,RECTS.plane)then
    m.h=clamp((x-RECTS.plane[1])/(RECTS.plane[3]-1),0,1)*359.999
    m.s=1-clamp((y-RECTS.plane[2])/(RECTS.plane[4]-1),0,1);m.focus='plane';fromHSV();return true
   end
   if hit(x,y,RECTS.light)then m.v=1-clamp((y-RECTS.light[2])/(RECTS.light[4]-1),0,1);m.focus='light';fromHSV();return true end
   for name,rr in pairs(RECTS)do if name~='plane'and name~='light'and hit(x,y,rr)then m.focus=name;if phase=='pressed'then activate()end;return true end end
   return true
  end
  local function focusMark(name,x,y)
   if m.focus==name then printText('>',x,y)end
  end
  function m.draw()
   G.push('all');G.setColor(0,0,0,1);G.rectangle('fill',0,0,240,160)
   G.setColor(0,123/255,197/255,1);G.rectangle('fill',0,0,240,16);G.setColor(1,1,1,1)
   printText(m.edit and'A: KEY   B: BACK'or'A: PICK  SELECT: NEXT  START: APPLY',8,1)
   Chrome.fixedStdFrame(2,3,26,2);printText((m.label or'BICYCLE')..' COLOUR',24,25)
   local frame=tonumber(Options.block(game.options or{}).frameType)or 0;Window.userFrame(Window.template(1,6,28,12),frame)
   if m.edit then
    local ed=m.edit;printText(ed.field=='hex'and'HEX RRGGBB'or(ed.field:upper()..' VALUE 0-255'),28,44)
    printText(ed.buffer~=''and ed.buffer or'-',150,44)
    local p=pad(ed);for i,t in ipairs(p)do if t~=''then local rr=padRect(i);if i==ed.index then printText('>',rr[1]-10,rr[2]+3)end;printText(t,rr[1]+6,rr[2]+3)end end
    if ed.error then printText(ed.error,28,142)end
    G.pop();return
   end
   -- Coarse HSV plane and value bar. The actual saved value remains exact RGB.
   for yy=0,7 do for xx=0,11 do local rr,gg,bb=hsvToRgb(xx/11*359.999,1-yy/7,m.v);G.setColor(rr/255,gg/255,bb/255,1);G.rectangle('fill',18+xx*8,48+yy*7,8,7)end end
   for yy=0,13 do local rr,gg,bb=hsvToRgb(m.h,m.s,1-yy/13);G.setColor(rr/255,gg/255,bb/255,1);G.rectangle('fill',122,48+yy*4,10,4)end
   G.setColor(1,1,1,1);focusMark('plane',8,68);focusMark('light',112,68)
   local vals={{'R',m.r,48,'r'},{'G',m.g,64,'g'},{'B',m.b,80,'b'},{'HEX',rgbHex(m.r,m.g,m.b),96,'hex'}}
   for _,row in ipairs(vals)do focusMark(row[4],140,row[3]+2);printText(row[1],150,row[3]+2);local txt=tostring(row[2]);printText(txt,220-measure(txt),row[3]+2)end
   G.setColor(m.r/255,m.g/255,m.b/255,1);G.rectangle('fill',138,111,84,7);G.setColor(1,1,1,1)
   local actions={{'ORIGINAL','original',18},{'APPLY','apply',88},{'CANCEL','cancel',158}}
   for _,a in ipairs(actions)do focusMark(a[2],a[3]-10,126);printText(a[1],a[3]+4,126)end
   if m.originalDraft then printText('ORIGINAL SELECTED',18,143)elseif m.notice then printText(m.notice,18,143)end
   G.pop()
  end
  Stack.push(id,m,{hideBelow=true});m.close=close;m.apply=apply;m.beginEdit=beginEdit;m.commitEdit=commitEdit;m.setRGB=setRGB
  return m
 end

 if mod.hooks and mod.hooks.wrap then
  mod.hooks:wrap('input.key',function(next,game,ev)
   local m=topPicker()
   if m and ev and ev.phase=='pressed'and m.rawKey and m.rawKey(ev.key)then return true end
   return next(game,ev)
  end,120)
 end
 api.active=function()return topPicker()end
 return api
end
return Picker
