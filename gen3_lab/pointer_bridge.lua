-- FireRed v0.2.66 does not expose the Gen1/2 input.pointer hook. Bridge native
-- mouse/touch presses into the isolated picker without modifying Game3 or the
-- shared touch controls. Only an active AUTOBIKE+ picker inside the 240x160
-- game viewport is intercepted; every other event retains the original path.
local Bridge={}
function Bridge.attach(mod,picker,services)
 local S=services or{}
 local game=assert(S.game or mod.game,'Game3 instance required')
 local Display=S.Display or require('src.core.game3.display')
 local G=S.graphics or(love and love.graphics)
 local Assets=S.Assets or require('src.render.Assets')
 local disposed=false
 local prior,wrappers={},{}
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
 local function dispatch(phase,id,x,y)
  if disposed or not(picker and picker.active)then return false end
  local page=picker.active();if not(page and page.pointer)then return false end
  local gx,gy,inside=localPoint(x,y);if not gx or not inside then return false end
  local ok,used=pcall(page.pointer,page,phase,gx,gy,id)
  return ok and used==true
 end
 local function install(name,phase,idAt,xAt,yAt,touchGuard)
  local old=game[name];if type(old)~='function'then return end
  prior[name]=old
  local wrapper
  wrapper=function(self,...)
   local a={...}
   if not(touchGuard and a[touchGuard]==true) then
    local id=idAt and a[idAt]or'mouse';local x=a[xAt];local y=a[yAt]
    -- Presses are sufficient for all picker fields/buttons and discrete HSV
    -- selection. Native move/release remain chained until drag capture is added.
    if dispatch(phase,id,x,y)then return true end
   end
   return old(self,...)
  end
  wrappers[name]=wrapper;game[name]=wrapper
 end
 install('mousepressed','pressed',nil,1,2,4)
 install('touchpressed','pressed',1,2,3,nil)
 local api={}
 function api.coordinates(x,y)return localPoint(x,y)end
 function api.dispose()
  if disposed then return end;disposed=true
  for name,old in pairs(prior)do if game[name]==wrappers[name]then game[name]=old end end
 end
 if Assets and Assets.register then Assets.register({release=api.dispose})end
 return api
end
return Bridge
