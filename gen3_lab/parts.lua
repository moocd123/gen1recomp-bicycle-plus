-- Conservative FireRed player-bike mask research, 32x32, nine standard frames.
-- No sprite images, ROM data or fonts embedded. Unknown palettes left alone.
local Parts={}
Parts.SOURCE_HASHES={
 [1]='28b0f9ea36211bd0abcbd5117b22db79f0d635510374b654db3e28073a1b7301',
 [8]='a323563f87b33502d7215f051184a2eaf4eb75400fb687c215c7155caf1a1d92',
}
function Parts.verify(bytes,gid,sha256)
 return type(bytes)=='string'and #bytes==36864 and Parts.SOURCE_HASHES[gid]~=nil
   and sha256(bytes)==Parts.SOURCE_HASHES[gid]
end
local known={}
for k,c in pairs({dark={58,58,123},outline={0,0,0},rim={181,181,214},
 spoke={239,239,255},frame={197,58,58},frameShadow={123,66,66}})do
 known[c[1]..','..c[2]..','..c[3]]=k
end
local function inrange(x,a,b)return x>=a and x<=b end
local edge={
 [25]={{7,8},{21,22}},[26]={{6,10},{18,23}},[27]={{5,6},{23,24}},
 [28]={{5,5},{13,13},{24,24}},[29]={{5,5},{13,13},{24,24}},
 [30]={{6,6},{12,12},{17,17},{23,23}},[31]={{7,11},{18,22}},
}
function Parts.classify(frame,x,y,r,g,b,a)
 if a==0 or frame<0 or frame>8 or x<0 or x>31 or y<0 or y>31 then return nil end
 local c=known[r..','..g..','..b];if not c then return nil end
 local facing=(frame==2 or frame==7 or frame==8)and'side'
   or(frame==0 or frame==3 or frame==4)and'front'or'back'
 if facing=='side'then
  if ((x==11 and y==22)or(x==10 and(y==23 or y==24)))and c=='rim'then return'handlebars'end
  if c=='frame'and((x==11 and(y==25 or y==26))or(x==10 and y==27)or(x==9 and y==28)
     or(x==18 and y==27)or((x==19 or x==20)and y==28))then return'frame'end
  if c=='frameShadow'and y==27 and inrange(x,19,21)then return'frame'end
  if c=='rim'and((inrange(y,28,29)and(x==6 or x==12 or x==23))
     or(y==29 and x==17)or(y==30 and(inrange(x,7,11)or inrange(x,18,22))))then return'rims'end
  if c=='spoke'and y>=27 and y<=29 and(inrange(x,7,11)or inrange(x,18,22))then return'spokes'end
  if c=='dark'and y==29 and(x==7 or x==11 or x==18 or x==22)then return'spokes'end
  if(c=='outline'or c=='dark')and edge[y]then
   for _,span in ipairs(edge[y])do if inrange(x,span[1],span[2])then return'tyres'end end
  end
 else
  if facing=='front'and y==24 and inrange(x,14,17)and c=='rim'then return'handlebars'end
  if c=='frame'and((inrange(y,27,28)and(x==14 or x==17))
     or(facing=='front'and y==25 and(x==15 or x==16)))then return'frame'end
  if inrange(y,27,31)and(x==15 or x==16)then
   if c=='rim'then return'rims'end
   if c=='outline'or c=='dark'then return'tyres'end
  end
 end
 return nil
end
function Parts.sheet(x,y,r,g,b,a)return Parts.classify(math.floor(y/32),x,y%32,r,g,b,a)end
return Parts
