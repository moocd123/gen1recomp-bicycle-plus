-- Software test boundaries, not GPU/device emulation.
local H={draws={},texts={},registered={}};local D={};D.__index=D
function D:getDimensions()return self.w,self.h end
function D:getPixel(x,y)
 assert(not self.released and x>=0 and y>=0 and x<self.w and y<self.h)
 return table.unpack(self.p[y*self.w+x+1]or{0,0,0,0})
end
function D:setPixel(x,y,...)assert(not self.released);self.p[y*self.w+x+1]={...}end
function D:mapPixel(fn)for y=0,self.h-1 do for x=0,self.w-1 do self:setPixel(x,y,fn(x,y,self:getPixel(x,y)))end end end
function D:release()self.released=true end
function H.data(w,h)return setmetatable({w=w,h=h,p={}},D)end
function H.copy(s)local w,h=s:getDimensions();local d=H.data(w,h);for y=0,h-1 do for x=0,w-1 do d:setPixel(x,y,s:getPixel(x,y))end end;return d end
function H.image(s)
 local o={data=H.copy(s)}
 function o:getDimensions()return self.data:getDimensions()end
 function o:setFilter(...)self.filter={...}end
 function o:release()self.released=true end
 return o
end
local function noop()end;H.noop=noop
H.G={setColor=noop,push=noop,pop=noop,setShader=noop,setBlendMode=noop,rectangle=noop,newImage=H.image,
 newQuad=function(x,y,w,h)return{x=x,y=y,w=w,h=h,getViewport=function()return x,y,w,h end}end,
 draw=function(...)H.draws[#H.draws+1]={...}end}
H.Font={drawBox=noop,drawCode=noop,draw=function(s,x,y)
 assert(not s:find('#',1,true),'native # is not a hex marker')
 assert(x>=0 and x+#s*8<=160 and y>=0 and y+8<=144,'text bounds: '..s)
 for _,v in ipairs(H.texts)do
  assert(not(x<v[2]+#v[1]*8 and x+#s*8>v[2] and y<v[3]+8 and y+8>v[3]),'text overlap: '..s..' / '..v[1])
 end
 H.texts[#H.texts+1]={s,x,y}
end}
local raw,images={},{}
H.Assets={register=function(v)H.registered[#H.registered+1]=v end,resolve=function(p)return p end,
 image=function(p)return assert(images[p],p)end,imageData=function(p)return H.copy(assert(raw[p],p))end}
function H.add(p,d)raw[p]=d;images[p]=H.image(d)end
function H.clear()H.draws={};H.texts={}end
function H.install()
 love={graphics=H.G,image={newImageData=H.data}}
 package.loaded['src.render.Assets']=H.Assets;package.loaded['src.render.Font']=H.Font
 package.loaded['src.ui.Theme']={cursor=0xED}
end
return H
