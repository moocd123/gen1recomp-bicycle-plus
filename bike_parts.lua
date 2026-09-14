-- Bicycle-only pixel metadata, in original 16x16 source-frame coordinates.
-- Coordinates describe visible regions, not official anatomical labels.
-- No sprite artwork is included. Directions are down/up/left, then their
-- moving frames; SpriteRenderer provides the matching right-facing mirror.
local Parts = {}

local RED = {
  {{7,11},{8,11},{7,12},{8,12},{7,13},{8,13},{7,14},{8,14}},
  {{7,13},{8,13},{7,14},{8,14}},
  {{3,11},{2,12},{2,13},{3,14},{4,14},{5,14},
   {11,11},{12,11},{13,11},{10,12},{10,13},{14,12},{14,13},
   {11,14},{12,14},{13,14}},
}
local GEN2 = {
  {{7,12},{8,12},{7,13},{8,13},{7,14},{8,14}},
  {{7,14},{8,14}},
  {{2,11},{1,12},{1,13},{5,13},{2,14},{3,14},{4,14},
   {11,11},{12,11},{13,11},{10,12},{14,12},{10,13},{14,13},
   {11,14},{12,14},{13,14}},
}
local function copy(points, dx)
  local result = {}
  for _, point in ipairs(points) do
    result[#result+1] = {point[1]+(dx or 0),point[2]}
  end
  return result
end
for frame=1,3 do
  RED[frame+3], GEN2[frame+3] = copy(RED[frame],-1), copy(GEN2[frame])
end
Parts.legacyMasks = {red=RED,gen2=GEN2}

-- Exposed wheel outlines. Deliberately omit the inward
-- edge next to the moving shoe and any black pixels in the rim mask: in
-- some poses those are the rider occluding the wheel, not tyre paint.
local leftTyre = {
  {1,11},{0,12},{0,13},{1,14},{2,15},{3,15},{4,15},{5,14},
}
local rightTyre = {
  {10,11},{14,11},{9,12},{15,12},{15,13},{10,14},{14,14},
  {11,15},{12,15},{13,15},
}
-- The side-view wheel centres are the original six dark pixels inside
-- each wheel. They belonged to TYRES before v1.4; splitting ownership
-- changes no geometry. Front/back views expose no separate centre block.
local leftCentre = {{2,12},{3,12},{4,12},{2,13},{3,13},{4,13}}
local rightCentre = {{11,12},{12,12},{13,12},{11,13},{12,13},{13,13}}
local lowerTyre = {{7,15},{8,15}}
-- The vertical borders of the narrow front/rear wheel are EDGE, not
-- handlebars. The small side stem remains an optional DETAILS accent.
local downEdge = {{6,12},{9,12},{6,13},{9,13},{6,14},{9,14}}
local upEdge = {{6,14},{9,14}}
local sideBars = {{2,10},{3,10}}
local sideDetail = {{3,11}}
local function frontBars(y)
  local points={}
  for row=y,y+1 do for x=4,11 do points[#points+1]={x,row} end end
  return points
end
local function append(a,b)
  for _,point in ipairs(b) do a[#a+1] = point end
  return a
end
local function index(points)
  local set = {}
  for _,point in ipairs(points) do set[point[2]*16+point[1]] = true end
  return set
end

Parts.masks = {red={},gen2={}}
for kind, highlights in pairs(Parts.legacyMasks) do
  for frame=1,6 do
    local direction = (frame-1)%3+1
    local movingShift = kind == "red" and frame>3 and -1 or 0
    local rims = highlights[frame]
    local tyres, centres, outline, handlebars, protected
    protected={}
    if direction == 3 then
      local leftShift = kind == "red" and 1 or 0
      tyres = append(copy(leftTyre,leftShift),copy(rightTyre))
      centres = append(copy(leftCentre,leftShift),copy(rightCentre))
      outline = copy(sideDetail,leftShift)
      handlebars = copy(sideBars,leftShift)
      -- Shared shoe/wheel boundaries stay in the original rider palette.
      protected={{9,12}}
      if frame==6 then protected[#protected+1]={10,14} end
    else
      tyres=append(copy(lowerTyre),copy(direction==1 and downEdge or upEdge))
      if kind=="red" then
        append(tyres,direction==1 and {{6,11},{9,11}} or {{6,13},{9,13}})
      end
      centres,outline={},{}
      -- The Gen 1 bar is a row higher and shifts left in its moving pose.
      -- No bar is exposed in the rear view: do not paint the rider's back.
      handlebars=direction==1 and frontBars(kind=="red" and 9 or 10) or {}
    end
    tyres,centres,outline=copy(tyres,movingShift),copy(centres,movingShift),copy(outline,movingShift)
    handlebars,protected=copy(handlebars,movingShift),copy(protected,movingShift)
    local mask={rims=rims,centres=centres,tyres=tyres,frame=outline,
      handlebars=handlebars,protected=protected}
    mask.lookup={rims=index(rims),centres=index(centres),tyres=index(tyres),
      frame=index(outline),handlebars=index(handlebars),protected=index(protected)}
    Parts.masks[kind][frame] = mask
  end
end

-- Native Red's rims have one source shade. An explicit stripe selection
-- decorates existing rim pixels and alternates the marks with native poses;
-- ORIGINAL does not add detail that was absent from the original artwork.
local redStripe = {
  {{7,12},{8,12}}, {{7,14},{8,14}}, {{2,12},{10,12}},
  {{6,14},{7,14}}, {{6,13},{7,13}}, {{4,14},{12,14}},
}
Parts.redStripeMasks = redStripe
local redStripeLookup = {}
for frame=1,6 do redStripeLookup[frame] = index(redStripe[frame]) end

-- Classify ORIGINAL SOURCE pixels, before trainer/display palette mapping.
-- r/g/b/a are normalised 0..1 ImageData values. Palette recolouring can make
-- a rim and a stripe identical on screen; it must not erase their identities.
function Parts.classify(kind,frame,x,y,r,g,b,a,explicitStripe)
  local family = Parts.masks[kind]
  if not family or type(frame) ~= "number" then return nil end
  frame = (frame-1)%6+1
  if x<0 or x>15 or y<0 or y>15 or a<=0.01 then return nil end
  local mask,key = family[frame].lookup,y*16+x
  local darkest = math.max(r,g,b)<=0.06
  local white = r>0.95 and g>0.95 and b>0.95
  if white then return nil end -- GB colour zero is opaque in imported PNGs.
  if mask.protected[key] then return nil end
  if mask.rims[key] then
    if darkest then return nil end -- Preserve rider occlusion/black detail.
    if kind == "red" then
      if explicitStripe and redStripeLookup[frame][key] then return "stripes" end
      return "rims"
    end
    local gray = math.abs(r-g)<0.025 and math.abs(g-b)<0.025
    if gray then return r>0.5 and "rims" or "stripes" end
    -- The supported Trainer Skins sheets use this peach wheel highlight;
    -- accents vary (red/green/blue/brown), so classify by highlight identity.
    local peach = r>0.85 and g>0.45 and g<0.7 and b>0.2 and b<0.45
    return peach and "rims" or "stripes"
  end
  if not darkest then return nil end -- Foreground hand/clothing colours are never outline paint.
  if mask.handlebars[key] then return "handlebars" end
  if mask.frame[key] then return "frame" end
  if mask.centres[key] then return "centres" end
  if mask.tyres[key] then return "tyres" end
  return nil
end

return Parts
