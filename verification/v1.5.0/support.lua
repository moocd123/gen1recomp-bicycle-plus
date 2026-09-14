-- Software ImageData/graphics test doubles. These are NOT GPU/device tests.
local H={draws={},texts={},rects={},registered={}}
local Data={};Data.__index=Data
function Data:getDimensions()return self.w,self.h end
function Data:getPixel(x,y)
  assert(not self.released,"read after ImageData release")
  assert(x>=0 and y>=0 and x<self.w and y<self.h,"pixel out of bounds")
  local p=self.p[y*self.w+x+1] or {0,0,0,0};return p[1],p[2],p[3],p[4]
end
function Data:setPixel(x,y,r,g,b,a)
  assert(not self.released,"write after ImageData release")
  assert(x>=0 and y>=0 and x<self.w and y<self.h,"pixel out of bounds")
  self.p[y*self.w+x+1]={r,g,b,a}
end
function Data:mapPixel(fn)
  for y=0,self.h-1 do for x=0,self.w-1 do
    self:setPixel(x,y,fn(x,y,self:getPixel(x,y)))
  end end
end
function Data:release()self.released=true end
function H.data(w,h)return setmetatable({w=w,h=h,p={}},Data)end
function H.copy(source)
  local w,h=source:getDimensions();local d=H.data(w,h)
  for y=0,h-1 do for x=0,w-1 do d:setPixel(x,y,source:getPixel(x,y))end end
  return d
end
function H.image(source)
  local image={data=H.copy(source),filter={"nearest","nearest"}}
  function image:getDimensions()return self.data:getDimensions()end
  function image:setFilter(a,b)self.filter={a,b}end
  function image:release()self.released=true end
  return image
end
local function noop()end
H.G={setColor=noop,push=noop,pop=noop,setShader=noop,setBlendMode=noop,
  newImage=H.image,
  newQuad=function(x,y,w,h)
    return {x=x,y=y,w=w,h=h,getViewport=function()return x,y,w,h end}
  end,
  rectangle=function(mode,x,y,w,h)H.rects[#H.rects+1]={mode,x,y,w,h}end,
  draw=function(...)H.draws[#H.draws+1]={...}end}
H.Font={draw=function(s,x,y)
  assert(not s:find("#",1,true),"Native # expands to POKe; do not use it as a hex prefix")
  assert(x>=0 and x+#s*8<=160 and y>=0 and y+8<=144,"menu text outside 160x144: "..s)
  H.texts[#H.texts+1]={s,x,y}
end,drawBox=noop,drawCode=noop}
local raw,images={},{}
H.Assets={register=function(fn)H.registered[#H.registered+1]=fn end,
  resolve=function(path)return path end,
  image=function(path)assert(images[path],"test image missing: "..path);return images[path]end,
  imageData=function(path)return H.copy(assert(raw[path],"raw fixture missing: "..path))end}
function H.add(path,data)raw[path]=data;images[path]=H.image(data)end
function H.resetDraws()H.draws={};H.texts={};H.rects={}end
function H.install()
  love={graphics=H.G,image={newImageData=H.data}}
  package.loaded["src.render.Assets"]=H.Assets
  package.loaded["src.render.Font"]=H.Font
  package.loaded["src.ui.Theme"]={cursor=0xED}
end
H.noop=noop
return H
