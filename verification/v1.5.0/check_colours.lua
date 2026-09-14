-- Run from repo root: texlua verification/v1.5.0/check_colours.lua ENGINE_DIR
-- Exhaustive colour math and native-palette input checks; no graphics/device test.
local engine=assert(arg[1],"Pass the directory containing the engine src/")
package.path=engine.."/?.lua;"..engine.."/?/init.lua;"..package.path
local P=assert(loadfile("hardware_colours.lua"))()
local n=0
local function check(v,s) assert(v,s);n=n+1 end
local seen={}
for word=0,32767 do
  local r,g,b=P.unpack(word)
  check(P.pack(r,g,b)==word,"RGB555 packing round-trip")
  local id=P.id(word);check(P.word(id)==word,"stored ID round-trip")
  local c=P.rgb(id);local h=P.hex(id)
  check(not seen[h],"duplicate rendered RGB colour");seen[h]=true
  check(P.fromRGB(c[1],c[2],c[3])==id,"display RGB round-trip")
  check(P.canonical(id:lower())==id,"case-normalised hexadecimal word")
end
check(P.COUNT==32768,"exact catalogue size")
for _,v in ipairs({"gbc:8000","gbc:FFFF","gbc:-001","gbc:00000","gbc:1",
  "gbc:GGGG","#FF0000","rgb:123456","red ","","original ",true,12,0/0}) do
  check(P.canonical(v)==nil,"reject invalid colour value")
end
check(P.canonical(nil)==nil,"nil validation")
check(P.canonical("original")=="original","Original always retained")
check(P.rgb("original")==nil,"Original is not an RGB swatch")
check(P.pack(-1,0,0)==nil and P.pack(32,0,0)==nil and P.pack(0,0.1,0)==nil,"strict five-bit inputs")
for _,row in ipairs(P.legacy) do
  local c=P.rgb(row[1]);local old=row[3]
  check(c[1]==old[1] and c[2]==old[2] and c[3]==old[3],"old selected appearance stays exact: "..row[1])
end
local rows,byId=P.presets({data={gen2Palettes={demo={{255,0,0},{0,255,0},{0,0,255}}}}})
local unique={}
for _,row in ipairs(rows) do
  check(not unique[row.id],"no duplicate preset ID");unique[row.id]=true
  check(P.canonical(row.id)==row.id,"canonical preset identity")
  check(byId[row.id]==row,"lookup points to the unique swatch")
end
for _,group in ipairs(P.lcd) do for _,c in ipairs(group[2]) do
  check(byId[P.fromRGB(c[1],c[2],c[3])],"LCD preset included")
end end
for _,row in ipairs(P.trainer) do
  local c=row[2];check(byId[P.fromRGB(c[1],c[2],c[3])],"trainer shade included")
end
local packs=require("data.gb_palettes")
local bootColours={}
for _,group in ipairs(packs) do
  if group.name:match("^GB Color %(") then
    for _,pal in ipairs(group.palettes) do for i=2,#pal do
      local t=pal[i]
      for at=1,#t,6 do
        local id=P.fromRGB(tonumber(t:sub(at,at+1),16),tonumber(t:sub(at+2,at+3),16),tonumber(t:sub(at+4,at+5),16))
        check(byId[id],"every built-in GBC boot-palette swatch included")
        bootColours[id]=true
      end
    end end
  end
end
local missing=P.presets(nil,function()error("optional colour pack absent")end)
check(#missing>=13,"missing optional palette packs degrade safely")
local cycle={};cycle.self=cycle
check(#P.presets({data={gen2Palettes=cycle}},function()error("absent")end)>=13,"cyclic mod palette data is bounded")
local counts=0;for _ in pairs(bootColours) do counts=counts+1 end
print(("PASS: %d colour checks; 32768 unique RGB555 values; %d unique preset swatches (%d GBC boot colours); Original retained.")
  :format(n,#rows-1,counts))
print("LCD/trainer swatches are projected to RGB555; this is not a physical LCD colour calibration.")
