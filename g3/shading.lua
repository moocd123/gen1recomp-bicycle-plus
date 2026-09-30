-- Shade-preserving paint research. Pure byte operations; no global palette edits.
-- Selected RGB is a paint reference. Near-black/white reserve tonal headroom.
local Shade={}
local function byte(v)return type(v)=='number'and v>=0 and v<=255 and v==math.floor(v)end
function Shade.valid(c)return type(c)=='table'and byte(c[1])and byte(c[2])and byte(c[3])end
function Shade.luma(r,g,b)return (0.2126*r+0.7152*g+0.0722*b)/255 end
function Shade.tint(source,base,lo,hi)
  assert(Shade.valid(source)and Shade.valid(base),'Invalid RGB')
  local t=hi>lo and math.max(0,math.min(1,(Shade.luma(source[1],source[2],source[3])-lo)/(hi-lo)))or 0.5
  local d=(t-0.5)*0.7
  local out={}
  for i=1,3 do
    local v=math.max(0.04,math.min(0.94,base[i]/255))
    v=d<0 and v*(1+d) or v+(1-v)*d
    out[i]=math.floor(v*255+0.5)
  end
  return out
end
function Shade.paint(bytes,w,h,classify,paints)
  assert(type(bytes)=='string'and #bytes==w*h*4,'Invalid RGBA dimensions')
  local bands={};local names={};local count=0
  for p=0,w*h-1 do
    local at=p*4+1;local r,g,b,a=bytes:byte(at,at+3)
    local part=a>0 and classify(p%w,math.floor(p/w),r,g,b,a)or nil
    if part then
      local lum=Shade.luma(r,g,b);names[p]=part
      local v=bands[part]or{lo=lum,hi=lum};v.lo=math.min(v.lo,lum);v.hi=math.max(v.hi,lum);bands[part]=v
    end
  end
  local out={}
  for p=0,w*h-1 do
    local at=p*4+1;local part=names[p];local c=part and paints[part]
    if c and c~='original' then
      assert(Shade.valid(c),'Invalid paint')
      local r,g,b,a=bytes:byte(at,at+3);local v=bands[part]
      local rgb=Shade.tint({r,g,b},c,v.lo,v.hi)
      out[p+1]=string.char(rgb[1],rgb[2],rgb[3],a);count=count+1
    else out[p+1]=bytes:sub(at,at+3)end
  end
  return table.concat(out),count
end
return Shade
