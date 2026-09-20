-- FireRed-style short text editor used by the isolated beta for local-song
-- names. Controller, keyboard, mouse and touch share the same 240x160 screen.
local Entry={}
function Entry.new(mod,services)
 local S=services or{}
 local Stack=S.Stack or require('src.ui.game3.stack')
 local Window=S.Window or require('src.ui.game3.window')
 local Chrome=S.Chrome or require('src.ui.game3.chrome')
 local Font=S.Font or require('src.ui.game3.frlg_font')
 local Options=S.Options or require('src.core.game3.options')
 local G=S.graphics or love.graphics
 local System=S.system or(love and love.system)
 local Keyboard=S.keyboard or(love and love.keyboard)
 local keys={}
 for c in('ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'):gmatch('.')do keys[#keys+1]=c end
 for _,v in ipairs({'SPACE','DEL','CLEAR','SAVE','BACK'})do keys[#keys+1]=v end
 local api={serial=0}
 local function rect(i)return{15+(i-1)%8*27,55+math.floor((i-1)/8)*15,25,13}end
 local function hit(x,y,r)return x>=r[1]and x<r[1]+r[3]and y>=r[2]and y<r[2]+r[4]end
 function api.open(game,title,initial,maximum,onSave)
  api.serial=api.serial+1;maximum=math.max(1,math.min(64,tonumber(maximum)or24))
  local id='autobike-gen3-text-'..api.serial
  local m={game=game,index=1,buffer=tostring(initial or''):upper():sub(1,maximum),replace=true,
   notice=nil,_autobikeGen3Pointer=true}
  local closed=false
  local function close()if closed then return end;closed=true;Stack.pop(id)end
  local function save()
   local name=m.buffer:gsub('%s+',' '):match('^%s*(.-)%s*$')
   if name==''then m.notice='ENTER A NAME';return false end
   local ok,err=onSave and onSave(name)or true
   if ok==false or ok==nil then m.notice=tostring(err or'NOT SAVED'):upper();return false end
   close();return true
  end
  local function action(k)
   if k=='BACK'then close()
   elseif k=='SAVE'then save()
   elseif k=='DEL'then m.buffer=m.replace and''or m.buffer:sub(1,-2);m.replace=false
   elseif k=='CLEAR'then m.buffer='';m.replace=false
   else
    local c=k=='SPACE'and' 'or k
    if m.replace then m.buffer='';m.replace=false end
    if#(m.buffer..c)<=maximum then m.buffer=m.buffer..c end
   end
  end
  local function move(d)
   local at=m.index
   for _=1,#keys do at=(at-1+d)%#keys+1;if keys[at]then break end end
   m.index=at
  end
  function m.handleInput(input)
   if input:wasPressed('b')then close();return true end
   if input:wasPressed('start')then save();return true end
   if input:wasPressed('select')then action('DEL');return true end
   if input:wasPressed('a')then action(keys[m.index]);return true end
   if input:wasPressed('left')then move(-1)elseif input:wasPressed('right')then move(1)
   elseif input:wasPressed('up')then move(-8)elseif input:wasPressed('down')then move(8)end
   return true
  end
  function m.rawKey(key)
   key=tostring(key or'')
   local ctrl=Keyboard and Keyboard.isDown and(Keyboard.isDown('lctrl')or Keyboard.isDown('rctrl')or Keyboard.isDown('lgui')or Keyboard.isDown('rgui'))
   if ctrl and key=='a'then m.replace=true;return true end
   if ctrl and key=='v'then
    if System and System.getClipboardText then
     local ok,text=pcall(System.getClipboardText);if ok then
      text=tostring(text or''):upper():gsub('[^A-Z0-9 _%.%+%-]',' '):gsub('%s+',' '):sub(1,maximum)
      m.buffer=text;m.replace=false;m.notice=nil
     else m.notice='PASTE UNAVAILABLE'end
    end
    return true
   end
   if key=='escape'then close()elseif key=='return'or key=='kpenter'then save()
   elseif key=='backspace'then action('DEL')elseif key=='delete'then action('CLEAR')
   elseif key=='space'then action('SPACE')
   else local c=key:match('^kp(%d)$')or(#key==1 and key:upper());if c and c:match('^[A-Z0-9]$')then action(c)end end
   return true
  end
  function m.pointer(phase,x,y)
   if phase~='pressed'and phase~='moved'then return true end
   for i,k in ipairs(keys)do local r=rect(i);if hit(x,y,r)then m.index=i;if phase=='pressed'then action(k)end;return true end end
   return false
  end
  function m.update()end
  function m.draw()
   G.push('all');G.setColor(0,0,0,1);G.rectangle('fill',0,0,240,160)
   G.setColor(0,123/255,197/255,1);G.rectangle('fill',0,0,240,16);G.setColor(1,1,1,1)
   Window.printPx('A: KEY  B: BACK  START: SAVE',8,1,{colors=Font.COLOR.NORMAL})
   Chrome.fixedStdFrame(2,3,26,2);Window.printPx(tostring(title or'SONG NAME'),24,25,{colors=Font.COLOR.NORMAL})
   local frame=tonumber(Options.block(game.options or{}).frameType)or0
   Window.userFrame(Window.template(2,7,26,3),frame)
   Window.printPx((m.replace and'> 'or'  ')..m.buffer,22,49,{colors=Font.COLOR.NORMAL})
   for i,k in ipairs(keys)do
    local r=rect(i);local label=({SPACE='SP',CLEAR='CLR',SAVE='OK',BACK='BACK'})[k]or k
    if i==m.index then G.setColor(0,123/255,197/255,0.35);G.rectangle('fill',r[1],r[2],r[3],r[4]);G.setColor(1,1,1,1)end
    Window.printPx(label,r[1]+2,r[2]+2,{colors=Font.COLOR.NORMAL})
   end
   if m.notice then Window.printPx(m.notice,16,148,{colors=Font.COLOR.NORMAL})end
   G.pop()
  end
  m.close=close;m.save=save;Stack.push(id,m,{hideBelow=true});return m
 end
 mod.exports.gen3TextEntry=api;return api
end
return Entry
