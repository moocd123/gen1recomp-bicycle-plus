local M={}
function M.init(U)
 local api={}
 local keys={};for c in('ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'):gmatch('.')do keys[#keys+1]=c end
 for _,c in ipairs({'SPACE','DEL','CLEAR','SAVE','BACK'})do keys[#keys+1]=c end
 local function rect(i)return{12+(i-1)%6*36,43+math.floor((i-1)/6)*14,34,14}end
 function api.open(game,title,initial,save)
  local s={game=game,buffer=tostring(initial or''):upper():sub(1,64),index=1,replace=true,timer=0,_bicycleMusic=true}
  function s:key(c)
   if c=='BACK'then U.pop(self)
   elseif c=='SAVE'then
    local text=self.buffer:gsub('%s+',' '):match('^%s*(.-)%s*$')
    if text==''then self.notice='ENTER A NAME';return end
    local ok,err=save(text);if ok then U.pop(self)else self.notice=err or'NOT SAVED'end
   elseif c=='DEL'then self.buffer=self.replace and''or self.buffer:sub(1,-2);self.replace=false
   elseif c=='CLEAR'then self.buffer='';self.replace=false
   else if self.replace then self.buffer='';self.replace=false end
    c=c=='SPACE'and' 'or c;if #self.buffer+#c<=64 then self.buffer=self.buffer..c end
   end
  end
  function s:rawKey(k)
   local ctrl=love.keyboard and love.keyboard.isDown('lctrl','rctrl','lgui','rgui')
   if ctrl and k=='a'then self.replace=true
   elseif ctrl and k=='v'then
    if love.system.getClipboardText then local ok,t=pcall(love.system.getClipboardText);if ok then self.buffer=t:upper():gsub('[^A-Z0-9 _%.%+%-]',' '):sub(1,64);self.replace=false end end
   elseif k=='escape'then self:key('BACK')
   elseif k=='return'or k=='kpenter'then self:key('SAVE')
   elseif k=='backspace'then self:key('DEL')
   elseif k=='delete'then self:key('CLEAR')
   elseif k=='space'then self:key('SPACE')
   elseif #k==1 and k:match('[%w]')then self:key(k:upper())end
   return true
  end
  function s:handleInput(input)
   if input:wasPressed('b')then U.pop(self);return end
   if input:wasPressed('start')then self:key('SAVE');return end
   if input:wasPressed('select')then self:key('DEL');return end
   if input:wasPressed('a')then self:key(keys[self.index]);return end
   local k=U.tap(self);if k then local d=k=='up'and -6 or k=='down'and 6 or k=='left'and -1 or 1;self.index=(self.index-1+d)%#keys+1 end
  end
  function s:pointer(e,x,y)
   if e.phase=='pressed'or e.phase=='moved'then
    for i,k in ipairs(keys)do if U.hit(x,y,rect(i))then self.index=i;if e.phase=='pressed'then self:key(k)end;return true end end
   end
   return true
  end
  function s:draw()
   U.background(game);U.centre(title,4)
   if self.replace then U.focus(12,22,216,16)end;U.marquee(self.buffer,15,23,209,self.timer)
   for i,k in ipairs(keys)do U.button(({SPACE='SP',CLEAR='CLR',SAVE='OK'})[k]or k,rect(i),self.index==i)end
   U.marquee(self.notice or'A:KEY  B:BACK  START:OK',12,145,216,self.timer)
  end
  return U.push(s)
 end
 return api
end
return M
