local root=arg[1]or'gen3_lab';local Shade=dofile(root..'/shading.lua');local Parts=dofile(root..'/parts.lua')
local n=0;local function ck(v,m)assert(v,m);n=n+1 end
local probes={{0,0,0},{255,255,255},{0,255,0},{255,0,0},{0,0,255},{128,128,128},{21,192,173}}
for _,c in ipairs(probes)do
 local previous=-1
 for s=0,255 do local v=Shade.tint({s,s,s},c,0,1);local l=Shade.luma(v[1],v[2],v[3]);ck(l>=previous,'shade order reversed');previous=l end
 local a=Shade.tint({0,0,0},c,0,1);local b=Shade.tint({255,255,255},c,0,1)
 ck(Shade.luma(b[1],b[2],b[3])-Shade.luma(a[1],a[2],a[3])>0.1,'black/white shading collapsed')
end
ck(not Shade.valid({-1,0,0})and not Shade.valid({256,0,0})and not Shade.valid({1.5,0,0}),'invalid paint accepted')
for f=0,8 do for y=0,31 do for x=0,31 do
 ck(Parts.classify(f,x,y,0,0,0,0)==nil,'transparent paint')
 ck(y>=22 or not Parts.classify(f,x,y,0,0,0,255),'upper rider outline selected')
end end end
-- The optional local fixtures are extracted privately from user-supplied ROMs.
-- They are not in the repository or CI. Never upload their bytes as test output.
if arg[2]then for _,who in ipairs({'red','leaf'})do
 local file=assert(io.open(arg[2]..'/firered_'..who..'.rgba','rb'));local bytes=file:read('*a');file:close()
 ck(Shade.paint(bytes,32,288,Parts.sheet,{})==bytes,'Original bytes changed')
 for _,part in ipairs({'frame','tyres','rims','spokes','handlebars'})do for _,c in ipairs(probes)do
  local out,count=Shade.paint(bytes,32,288,Parts.sheet,{[part]=c});ck(count>0,'empty material')
  for p=0,32*288-1 do local at=p*4+1;local r,g,b,a=bytes:byte(at,at+3)
   ck(out:byte(at+3)==a,'alpha changed')
   if Parts.sheet(p%32,math.floor(p/32),r,g,b,a)~=part then ck(out:sub(at,at+3)==bytes:sub(at,at+3),'non-target changed')end
  end
 end end
end end
print('PASS '..n..' shade/region assertions. Pixel anatomy still needs human review.')
