local engine=assert(arg[1]);package.path=engine..'/?.lua;'..package.path
local H=dofile('hardware_colours.lua');local P=dofile('colour_values.lua').extend(H)
local n=0;local function ck(v,m)assert(v,m);n=n+1 end
for word=0,32767 do
 local id=H.id(word);local old=H.rgb(id);local c=P.rgb(id)
 ck(c[1]==old[1]and c[2]==old[2]and c[3]==old[3],'legacy colour changed')
 local exact=P.exact(c[1],c[2],c[3]);ck(P.hex(exact)==H.hex(id),'RGB555 expansion')
 local h,s,v=P.toHSV(c[1],c[2],c[3]);local r,g,b=P.fromHSV(h,s,v)
 ck(r==c[1]and g==c[2]and b==c[3],'HSV round trip')
end
for _,c in ipairs({{139,0,186},{191,57,0},{88,184,248},{249,0,170},{58,44,19},{75,75,75},{1,2,3},{254,255,254},{0,0,0},{255,255,255}})do
 local id=P.exact(c[1],c[2],c[3]);local rgb=P.rgb(id)
 ck(rgb[1]==c[1]and rgb[2]==c[2]and rgb[3]==c[3],'exact RGB altered')
 ck(P.parseHex(P.hex(id))==id,'hex round trip')
end
for _,s in ipairs({'abc','1234567','GGHHII','rgb:123456','#FFFFFFx','1e999','FFFFFFFF','12 3456'})do ck(not P.parseHex(s),'invalid hex accepted')end
ck(P.parseHex(' #abcDEF ')=='rgb:ABCDEF','case/space normalization')
for _,v in ipairs({-1,256,1.5,math.huge,0/0,'7'})do ck(not P.exact(v,0,0),'invalid channel accepted')end
local refs=P.references({data={}})
for _,t in ipairs(H.trainer)do
 local d=P.describe(P.exact(t[2][1],t[2][2],t[2][3]),refs);ck(d[1].text:match('^TRAINER SKINS')~=nil,'trainer label missing')
end
ck(P.describe('rgb:008400',refs)[1].text=='TRAINER SKINS GREEN','008400 identity')
local boot=false;for _,row in ipairs(P.describe('rgb:FFFFCE',refs))do boot=boot or row.text=='GBC BOOT'end
ck(boot,'FFFFCE boot palette reference')
ck(P.describe('rgb:010203',refs)[1].text=='CUSTOM RGB','unknown RGB incorrectly named')
for _,rows in pairs(refs)do local seen={};for _,row in ipairs(rows)do ck(not seen[row.text],'duplicate reference');seen[row.text]=true end end
print(('PASS %d exact RGB/hex, HSV, RGB555 preservation and reference checks.'):format(n))
