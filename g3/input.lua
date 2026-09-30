-- Instance-scoped GBA pointer/text adapter. Native virtual buttons get first
-- refusal; other screens and releases retain the engine's original handlers.
local M={}
function M.attach(mod,U)
 local game=assert(mod.game)
 local Display=require('src.core.game3.display')
 local Bus=require('src.mods.Runtime')
 local hooks,events=Bus.hooks,Bus.events
 local prior,wrapped,held={}, {}, {}
 local disposed=false
 local function active()return not disposed and hooks==Bus.hooks and events==Bus.events and not Bus.safeMode end
 local function point(x,y)
  local w,h=love.graphics.getDimensions();local sx,ox,oy,_,_,sy=Display.fit(w,h);sy=sy or sx
  if not sx or sx<=0 or not sy or sy<=0 then return end
  local gx,gy=(x-ox)/sx,(y-oy)/sy
  return gx,gy,gx>=0 and gx<240 and gy>=0 and gy<160
 end
 local function dispatch(phase,id,x,y,source,button)
  if not active()then return false end
  local page=phase=='pressed'and U.top()or held[id]or U.top()
  if not page or not page.pointer then return false end
  if held[id] and U.top()~=held[id]then held[id]=nil;return false end
  local gx,gy,inside=point(x,y);if not gx then return false end
  if not inside and not held[id]then return false end
  local handled=page:pointer({phase=phase,id=id,source=source,button=button},gx,gy)
  if phase=='pressed'and handled then held[id]=page end
  if phase=='released'or phase=='cancelled'then held[id]=nil end
  return handled==true
 end
 local function install(name,f)
  prior[name]=game[name]
  wrapped[name]=f(prior[name]or function()end);game[name]=wrapped[name]
 end
 install('touchpressed',function(old)return function(self,id,x,y,...)
  if active()and U.top()then
   if self.touchControls and self.touchControls:touchpressed(id,x,y)then return end
   if dispatch('pressed',id,x,y,'touch',1)then return end
   return -- the normal Game3 handler only forwards to the same touch controls
  end
  return old(self,id,x,y,...)
 end end)
 for _,pair in ipairs({{'touchmoved','moved'},{'touchreleased','released'}})do
  local name,phase=pair[1],pair[2]
  install(name,function(old)return function(self,id,x,y,...)
   if held[id]and dispatch(phase,id,x,y,'touch',1)then return end
   return old(self,id,x,y,...)
  end end)
 end
 install('mousepressed',function(old)return function(self,x,y,button,istouch,...)
  if not istouch and button==1 and active()and U.top()then
   if love.system.getOS()~='Android' and os.getenv and os.getenv('POKEPORT_TOUCH')=='1' and self.touchControls
    and self.touchControls:touchpressed('mouse',x,y)then return end
   if dispatch('pressed','mouse',x,y,'mouse',button)then return end
  end
  return old(self,x,y,button,istouch,...)
 end end)
 install('mousemoved',function(old)return function(self,x,y,dx,dy,istouch,...)
  if not istouch and dispatch('moved','mouse',x,y,'mouse',1)then return end
  return old(self,x,y,dx,dy,istouch,...)
 end end)
 install('mousereleased',function(old)return function(self,x,y,button,istouch,...)
  if not istouch and button==1 and held.mouse and dispatch('released','mouse',x,y,'mouse',button)then return end
  return old(self,x,y,button,istouch,...)
 end end)
 mod.hooks:wrap('input.key',function(next,g,e)
  local p=active()and U.top()
  if p and p.rawKey and e and e.phase=='pressed'and p:rawKey(e.key)then return true end
  return next(g,e)
 end,-90)
 local api={coordinates=point,dispatch=dispatch}
 function api.dispose()
  if disposed then return end;disposed=true
  for id,p in pairs(held)do if p.pointer then pcall(p.pointer,p,{phase='cancelled',id=id},0,0)end end
  held={}
  for k,old in pairs(prior)do if game[k]==wrapped[k]then game[k]=old end end
 end
 require('src.render.Assets').register({release=api.dispose})
 return api
end
return M
