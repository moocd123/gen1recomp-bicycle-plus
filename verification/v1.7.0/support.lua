-- Software doubles: these do not test a GPU, audio device, OS or touch driver.
local H={draws={},texts={},rects={},registered={}}
local D={};D.__index=D
function D:getDimensions()return self.w,self.h end
function D:getPixel(x,y)
 assert(not self.released and x>=0 and y>=0 and x<self.w and y<self.h,'invalid source pixel')
 local p=self.p[y*self.w+x+1]or{0,0,0,0};return p[1],p[2],p[3],p[4]
end
function D:setPixel(x,y,r,g,b,a)
 assert(not self.released and x>=0 and y>=0 and x<self.w and y<self.h,'invalid output pixel')
 self.p[y*self.w+x+1]={r,g,b,a}
end
function D:mapPixel(fn)for y=0,self.h-1 do for x=0,self.w-1 do self:setPixel(x,y,fn(x,y,self:getPixel(x,y)))end end end
function D:release()self.released=true end
function H.data(w,h)return setmetatable({w=w,h=h,p={}},D)end
function H.copy(src)
 local w,h=src:getDimensions();local d=H.data(w,h)
 for y=0,h-1 do for x=0,w-1 do d:setPixel(x,y,src:getPixel(x,y))end end
 return d
end
function H.image(src)
 local im={data=H.copy(src)}
 function im:getDimensions()return self.data:getDimensions()end
 function im:setFilter(a,b)self.filter={a,b}end
 function im:release()self.released=true end
 return im
end
local function noop()end
H.noop=noop
H.G={transformPoint=function(x,y)return x,y end,intersectScissor=function(...)H.scissor={...}end,getDimensions=function()return 160,144 end,setColor=noop,push=noop,pop=noop,setShader=noop,setBlendMode=noop,newImage=H.image,
 newQuad=function(x,y,w,h)return{x=x,y=y,w=w,h=h,getViewport=function()return x,y,w,h end}end,
 rectangle=function(...)H.rects[#H.rects+1]={...}end,
 draw=function(...)H.draws[#H.draws+1]={...}end}
H.Font={draw=function(s,x,y)
 assert(not s:find('#',1,true),'native # glyph is not a hex prefix')
 assert(x>=0 and x+#s*8<=160 and y>=0 and y+8<=144,'text outside native screen: '..s)
 H.texts[#H.texts+1]={s,x,y}
end,drawBox=noop,drawCode=noop}
local raw,images={},{}
H.Assets={register=function(x)H.registered[#H.registered+1]=x end,resolve=function(p)return p end,
 image=function(p)return assert(images[p],'missing image '..p)end,
 imageData=function(p)return H.copy(assert(raw[p],'missing raw '..p))end}
function H.add(p,d)raw[p]=d;images[p]=H.image(d)end
function H.install()
 love={graphics=H.G,image={newImageData=H.data}}
 package.loaded['src.render.Assets']=H.Assets;package.loaded['src.render.Font']=H.Font
 package.loaded['src.ui.Theme']={cursor=0xED}
end
function H.reset()H.draws={};H.texts={};H.rects={}end
function H.layout()
 for i,a in ipairs(H.texts)do for j=1,i-1 do local b=H.texts[j]
  assert(not(a[2]<b[2]+#b[1]*8 and b[2]<a[2]+#a[1]*8 and a[3]<b[3]+8 and b[3]<a[3]+8),
   'text overlap: '..a[1]..' / '..b[1])
 end end
end
return H
