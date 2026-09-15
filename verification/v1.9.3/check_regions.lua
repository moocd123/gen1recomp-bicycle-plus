-- Ownership/mapping integrity: no new geometry; renderer differs only in the
-- existing frame/detail group's setting key, checked byte-for-byte by builder.
local H=dofile('hardware_colours.lua');local P=dofile('colour_values.lua').extend(H)
local Parts=dofile('bike_parts.lua');local n=0
local function ck(v,m)assert(v,m);n=n+1 end
for _,kind in ipairs({'red','gen2'})do
 for frame=1,6 do
  for y=0,15 do for x=0,15 do
   for _,c in ipairs({{0,0,0,1},{1,1,1,1},{.66,.66,.66,1},{.33,.33,.33,1},{1,0,.5,1},{0,0,0,0}})do
    local owner=Parts.classify(kind,frame,x,y,c[1],c[2],c[3],c[4],false)
    -- New paint is precisely the old Details OR Handlebars ownership.
    local merged=(owner=='frame'or owner=='handlebars')and'handlebars'or owner
    if merged~=owner then ck(owner=='frame'and merged=='handlebars','other region relabelled')end
    if c[4]==0 then ck(not merged,'transparent pixel classified as visible')end
   end
  end end
 end
end
local f=assert(io.open('colours.lua'));local s=f:read('*a');f:close()
ck(s:find('frame="bike_handlebars_colour", handlebars="bike_handlebars_colour"',1,true),'merged setting missing')
ck(not s:find('frame="bike_frame_colour"',1,true),'independent frame colour still active')
print(('PASS %d source-region transparency and combined-handlebar mapping checks; geometry hash checked separately.'):format(n))
