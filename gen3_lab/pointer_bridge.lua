-- FireRed v0.2.66 does not expose the Gen1/2 input.pointer hook. Bridge native
-- mouse/touch input into the isolated picker without modifying Game3 or the
-- shared touch controls. A press inside the 240x160 game viewport captures
-- that pointer until release, so HSV/value drags keep working across the
-- window edge; every uncaptured event retains the original native path.
local Bridge={}
function Bridge.attach(mod,picker,services)
 local S=services or{}
 local game=assert(S.game or mod.game,'Game3 instance required')
 local Display=S.Display or require('src.core.game3.display')
 local G=S.graphics or(love and love.graphics)
 local Assets=S.Assets or require('src.render.Assets')
 local disposed=false
 local prior,wrappers={},{}
 local captured={}
 local function localPoint(x,y)
  if type(x)~='number'or type(y)~='number'then return nil end
  local w,h=Display.W or 240,Display.H or 160
  local winW,winH=w,h
  if G and G.getDimensions then local ok,a,b=pcall(G.getDimensions);if ok and a and b then winW,winH=a,b end end
  local sx,ox,oy,pw,ph,sy=Display.fit(winW,winH)
  sx=tonumber(sx)or 1;sy=tonumber(sy)or sx;ox=tonumber(ox)or 0;oy=tonumber(oy)or 0
  if sx<=0 or sy<=0 then return nil end
  local gx,gy=(x-ox)/sx,(y-oy)/sy
  return gx,gy,gx>=0 and gy>=0 and gx<w and gy<h
 end
 local function currentPage()
  if disposed or not(picker and picker.active)then return nil end
  local page=picker.active()
  return page and page.pointer and page or nil
 end
 local function dispatch(phase,id,x,y,needsCapture)
  id=id or'mouse'
  local page
  if needsCapture then
   page=captured[id]
   if not page or currentPage()~=page then captured[id]=nil;return false end
  else
   page=currentPage();if not page then return false end
  end
  local gx,gy,inside=localPoint(x,y)
  if not gx then
   if phase=='released'or phase=='cancelled'then captured[id]=nil end
   return false
  end
  if phase=='pressed'and not inside then return false end
  local ok,used=pcall(page.pointer,page,phase,gx,gy,id)
  used=ok and used==true
  if phase=='pressed'and used then
   captured[id]=page
  elseif phase=='released'or phase=='cancelled'then
   captured[id]=nil
  end
  return used
 end
 local function install(name,phase,idAt,xAt,yAt,touchGuard,needsCapture)
  local old=game[name];if type(old)~='function'then return end
  prior[name]=old
  local wrapper
  wrapper=function(self,...)
   local a={...}
   if not(touchGuard and a[touchGuard]==true)then
    local id=idAt and a[idAt]or'mouse'
    if dispatch(phase,id,a[xAt],a[yAt],needsCapture)then return true end
   end
   return old(self,...)
  end
  wrappers[name]=wrapper;game[name]=wrapper
 end
 install('mousepressed','pressed',nil,1,2,4,false)
 install('mousemoved','moved',nil,1,2,5,true)
 install('mousereleased','released',nil,1,2,4,true)
 install('touchpressed','pressed',1,2,3,nil,false)
 install('touchmoved','moved',1,2,3,nil,true)
 install('touchreleased','released',1,2,3,nil,true)
 local api={}
 function api.coordinates(x,y)return localPoint(x,y)end
 function api.dispose()
  if disposed then return end;disposed=true;captured={}
  for name,old in pairs(prior)do if game[name]==wrappers[name]then game[name]=old end end
 end
 if Assets and Assets.register then Assets.register({release=api.dispose})end
 return api
end
return Bridge
