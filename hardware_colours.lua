-- Hardware-limited colour catalogue. A colour is one RGB555 word (0..32767).
-- Display expansion matches the engine: round(component * 255 / 31).
-- Presets are references into this one catalogue, never additional colours.
local P = {COUNT=32768}
local floor = math.floor
local function integer(v, lo, hi)
  return type(v)=="number" and v==v and v>=lo and v<=hi and v==floor(v)
end
function P.pack(r,g,b)
  if not (integer(r,0,31) and integer(g,0,31) and integer(b,0,31)) then return nil end
  return r+32*g+1024*b
end
function P.unpack(word)
  if not integer(word,0,32767) then return nil end
  return word%32, floor(word/32)%32, floor(word/1024)
end
function P.id(word)
  if not integer(word,0,32767) then return nil end
  return ("gbc:%04X"):format(word)
end
function P.fromRGB(r,g,b)
  if not (integer(r,0,255) and integer(g,0,255) and integer(b,0,255)) then return nil end
  return P.id(P.pack(floor(r*31/255+0.5),floor(g*31/255+0.5),floor(b*31/255+0.5)))
end
-- Keep these aliases readable forever: existing saves need no destructive migration.
P.legacy = {
  {"red","RED",{255,58,8}}, {"orange","ORANGE",{255,132,8}},
  {"yellow","YELLOW",{255,222,41}}, {"green","GREEN",{58,189,25}},
  {"cyan","CYAN",{49,189,222}}, {"blue","BLUE",{82,74,255}},
  {"purple","PURPLE",{156,74,222}}, {"pink","PINK",{247,82,173}},
  {"brown","BROWN",{123,82,25}}, {"silver","SILVER",{165,173,181}},
  {"black","CHARCOAL",{49,49,58}}, {"white","OFFWHITE",{239,239,247}},
}
local aliases, names = {}, {}
P.quickChoices = {{"ORIGINAL","original"}}
P.legacyOptions = {{id="original",label="Original"}}
for _,row in ipairs(P.legacy) do
  local c=row[3]
  local id=P.fromRGB(c[1],c[2],c[3])
  aliases[row[1]]=id; names[id]=row[2]
  P.quickChoices[#P.quickChoices+1]={row[2],id}
  P.legacyOptions[#P.legacyOptions+1]={id=id,label=row[2],rgb=c}
end
function P.canonical(value)
  if value=="original" then return value end
  if type(value)~="string" then return nil end
  if aliases[value] then return aliases[value] end
  local s=value:match("^gbc:(%x%x%x%x)$")
  return s and P.id(tonumber(s,16)) or nil
end
function P.word(value)
  value=P.canonical(value)
  return value and value~="original" and tonumber(value:sub(5),16) or nil
end
function P.rgb(value)
  local word=P.word(value)
  if word==nil then return nil end
  local r,g,b=P.unpack(word)
  return {floor(r*255/31+0.5),floor(g*255/31+0.5),floor(b*255/31+0.5)}
end
function P.hex(value)
  local c=P.rgb(value)
  return c and ("#%02X%02X%02X"):format(c[1],c[2],c[3]) or "ORIGINAL"
end
function P.label(value)
  value=P.canonical(value)
  return names[value] or (value and value~="original" and P.hex(value):sub(2) or "ORIGINAL")
end
-- SameBoy Core/display.c: four LCD shades only, not the fifth LCD-off entry.
-- These are screen-look approximations, not programmable DMG colour registers.
-- Snap them to the same RGB555 catalogue instead of adding 24-bit exceptions.
P.lcd = {
  {"DMG",{{0x08,0x18,0x10},{0x39,0x61,0x39},{0x84,0xA5,0x63},{0xC6,0xDE,0x8C}}},
  {"POCKET",{{0x07,0x10,0x0E},{0x3A,0x4C,0x3A},{0x81,0x8D,0x66},{0xC2,0xCE,0x93}}},
  {"LIGHT",{{0x0A,0x1C,0x15},{0x35,0x78,0x62},{0x56,0xB4,0x95},{0x7F,0xE2,0xC3}}},
  {"GREY",{{0,0,0},{85,85,85},{170,170,170},{255,255,255}}},
}
P.trainer = {
  {"SKIN 010 RED",{248,56,8}}, {"SKIN 010 GREEN",{0,132,0}},
  {"SKIN 010 BLUE",{0,0,255}}, {"SKIN 020 RED",{255,0,0}},
  {"SKIN 020 GREEN",{58,189,25}}, {"SKIN 020 BLUE",{82,74,255}},
  {"SKIN 020 YELLOW",{173,90,0}}, {"SKIN 020 PURPLE",{139,0,186}},
  {"SKIN 020 ORANGE",{191,57,0}}, {"SKIN 020 CYAN",{88,184,248}},
  {"SKIN 020 PINK",{249,0,170}}, {"SKIN 020 BROWN",{58,44,19}},
  {"SKIN 020 GREY",{75,75,75}}, {"SKIN HIGHLIGHT",{239,156,107}},
}
local hardwarePacks = {
  ["GB Color (Combo Palettes)"]=true,
  ["GB Color (Unique Palettes)"]=true,
  ["GB Color (Unused Palettes)"]=true,
}
local function sortedKeys(t)
  local out={}
  for k in pairs(t) do
    if type(k)=="string" or type(k)=="number" then out[#out+1]=k end
  end
  table.sort(out,function(a,b)
    if type(a)==type(b) then return a<b end
    return type(a)<type(b)
  end)
  return out
end
-- Returns unique swatches plus source aliases. Existing skin colours may match
-- ORIGINAL at runtime: ORIGINAL is deliberately retained as a semantic option.
function P.presets(game, resolve)
  resolve=resolve or require
  local out={{id="original",label="ORIGINAL",sources={"UNMODIFIED ART"}}}
  local byId={original=out[1]}
  local function addRGB(label,c)
    if type(c)~="table" then return end
    local id=P.fromRGB(c[1],c[2],c[3])
    if not id then return end
    local row=byId[id]
    if not row then
      row={id=id,label=label,rgb=P.rgb(id),sources={},sourceSet={}}
      byId[id]=row; out[#out+1]=row
    end
    if not row.sourceSet[label] then
      row.sources[#row.sources+1]=label; row.sourceSet[label]=true
    end
  end
  for _,row in ipairs(P.legacy) do addRGB(row[2],row[3]) end
  for _,group in ipairs(P.lcd) do
    for i,c in ipairs(group[2]) do addRGB(group[1].." SHADE "..i,c) end
  end
  for _,row in ipairs(P.trainer) do addRGB(row[1],row[2]) end
  local ok,packs=pcall(resolve,"data.gb_palettes")
  if ok and type(packs)=="table" then
    for _,group in ipairs(packs) do
      if hardwarePacks[group.name] then
        for _,pal in ipairs(group.palettes or {}) do
          for i=2,#pal do
            local text=pal[i]
            if type(text)=="string" and #text==24 and not text:find("[^%x]") then
              for at=1,24,6 do
                addRGB("GBC BOOT",{tonumber(text:sub(at,at+1),16),
                  tonumber(text:sub(at+2,at+3),16),tonumber(text:sub(at+4,at+5),16)})
              end
            end
          end
        end
      end
    end
  end
  -- Restrict traversal to palette registries, never the world or save tree.
  -- Limits and cycle checks also bound malformed/replacement mod data.
  local visited,remaining={},16000
  local function scan(node,label,depth)
    if type(node)~="table" or visited[node] or depth>10 or remaining<=0 then return end
    visited[node]=true; remaining=remaining-1
    if #node==3 and integer(node[1],0,255) and integer(node[2],0,255)
        and integer(node[3],0,255) then addRGB(label,node); return end
    for _,key in ipairs(sortedKeys(node)) do scan(node[key],label,depth+1) end
  end
  -- These built-in colour packs are GBC-formatted, including Yellow CGB mode.
  for _,name in ipairs({"data.palettes_gbc","data.palettes_yellow","data.palettes_gbc_yellow"}) do
    local found,pack=pcall(resolve,name)
    if found then scan(pack,"GAME GBC",0) end
  end
  local data=game and game.data or {}
  scan(data.gen2Palettes,"GAME GBC",0)
  -- Keep the selected custom colour discoverable without duplicating a preset.
  return out,byId
end
return P
