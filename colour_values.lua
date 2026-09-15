-- Exact RGB editing layered over the original RGB555 catalogue.
-- Legacy IDs/aliases keep their old expansion; new rgb:RRGGBB IDs never round.
local Values={}
function Values.extend(H)
  local P=setmetatable({RGB_COUNT=16777216},{__index=H})
  local floor=math.floor
  local function byte(v)return type(v)=='number'and v==v and v>=0 and v<=255 and v==floor(v)end
  function P.exact(r,g,b)
    if not(byte(r)and byte(g)and byte(b))then return nil end
    return ('rgb:%02X%02X%02X'):format(r,g,b)
  end
  function P.canonical(v)
    if type(v)=='string'then local s=v:match('^rgb:(%x%x%x%x%x%x)$');if s then return 'rgb:'..s:upper()end end
    return H.canonical(v)
  end
  function P.parseHex(v)
    if type(v)~='string'then return nil end
    local s=v:match('^%s*#?(%x%x%x%x%x%x)%s*$')
    return s and('rgb:'..s:upper())or nil
  end
  function P.rgb(v)
    v=P.canonical(v)
    if v and v:sub(1,4)=='rgb:'then
      return {tonumber(v:sub(5,6),16),tonumber(v:sub(7,8),16),tonumber(v:sub(9,10),16)}
    end
    return H.rgb(v)
  end
  function P.word(v)
    v=P.canonical(v);if v and v:sub(1,4)=='rgb:'then return nil end
    return H.word(v)
  end
  function P.hex(v)
    local c=P.rgb(v);return c and('#%02X%02X%02X'):format(c[1],c[2],c[3])or'ORIGINAL'
  end
  function P.label(v)
    v=P.canonical(v);if v and v:sub(1,4)=='rgb:'then return v:sub(5)end
    return H.label(v)
  end
  function P.toHSV(r,g,b)
    r,g,b=r/255,g/255,b/255
    local hi,lo=math.max(r,g,b),math.min(r,g,b);local d=hi-lo;local h=0
    if d>0 then
      if hi==r then h=((g-b)/d)%6 elseif hi==g then h=(b-r)/d+2 else h=(r-g)/d+4 end
      h=h*60
    end
    return h,hi==0 and 0 or d/hi,hi
  end
  function P.fromHSV(h,s,v)
    h=(h or 0)%360;s=math.max(0,math.min(1,s or 0));v=math.max(0,math.min(1,v or 0))
    local c=v*s;local x=c*(1-math.abs((h/60)%2-1));local m=v-c;local r,g,b=0,0,0
    if h<60 then r,g=c,x elseif h<120 then r,g=x,c elseif h<180 then g,b=c,x
    elseif h<240 then g,b=x,c elseif h<300 then r,b=x,c else r,b=c,x end
    return floor((r+m)*255+0.5),floor((g+m)*255+0.5),floor((b+m)*255+0.5)
  end
  -- Build once per editor. Only approved palette tables are traversed, never
  -- arbitrary saved data. Exact matches may have multiple named sources.
  function P.references(game,resolve)
    resolve=resolve or require;local refs={}
    local function add(text,c,rank)
      if type(c)~='table'then return end
      local id=P.exact(c[1],c[2],c[3]);if not id then return end
      local key=id:sub(5);local rows=refs[key]
      if not rows then rows={};refs[key]=rows end
      for _,row in ipairs(rows)do if row.text==text then return end end
      rows[#rows+1]={text=text,rank=rank or 5}
    end
    for _,row in ipairs(H.trainer or {})do
      local label=row[1]:gsub('^TRAINER ','TRAINER SKINS ')
      add(label,row[2],1)
    end
    for _,group in ipairs(H.lcd or {})do
      if group[1]~='GREY'then
        for i,c in ipairs(group[2])do
          add(group[1]..' LCD LOOK '..i,c,2)
          local rounded=H.rgb(H.fromRGB(c[1],c[2],c[3]))
          add(group[1]..' LCD LOOK '..i,rounded,2)
        end
      end
    end
    local packsOK,packs=pcall(resolve,'data.gb_palettes')
    local permitted={['GB Color (Combo Palettes)']=true,['GB Color (Unique Palettes)']=true,['GB Color (Unused Palettes)']=true}
    if packsOK and type(packs)=='table'then
      for _,group in ipairs(packs)do if permitted[group.name]then
        for _,pal in ipairs(group.palettes or {})do for i=2,#pal do
          local s=pal[i]
          if type(s)=='string'and #s==24 and not s:find('[^%x]')then
            for at=1,24,6 do add('GBC BOOT',{tonumber(s:sub(at,at+1),16),tonumber(s:sub(at+2,at+3),16),tonumber(s:sub(at+4,at+5),16)},3)end
          end
        end end
      end end
    end
    local seen,remaining={},16000
    local function scan(t,depth)
      if type(t)~='table'or seen[t]or depth>10 or remaining<=0 then return end
      seen[t]=true;remaining=remaining-1
      if #t==3 and byte(t[1])and byte(t[2])and byte(t[3])then add('GBC GAME',t,4);return end
      for _,node in pairs(t)do scan(node,depth+1)end
    end
    for _,name in ipairs({'data.palettes_gbc','data.palettes_yellow','data.palettes_gbc_yellow'})do
      local ok,t=pcall(resolve,name);if ok then scan(t,0)end
    end
    scan(game and game.data and game.data.gen2Palettes,0)
    for _,row in ipairs(H.legacy or {})do add(row[2],row[3],5)end
    for _,rows in pairs(refs)do table.sort(rows,function(a,b)if a.rank~=b.rank then return a.rank<b.rank end;return a.text<b.text end)end
    return refs
  end
  function P.describe(id,refs)
    if id=='original'then return {{text='ORIGINAL ARTWORK'}}end
    local c=P.rgb(id);if not c then return {{text='INVALID COLOUR'}}end
    local key=('%02X%02X%02X'):format(c[1],c[2],c[3])
    if refs and refs[key]then return refs[key]end
    local quant=H.rgb(H.fromRGB(c[1],c[2],c[3]))
    local hardware=c[1]==quant[1]and c[2]==quant[2]and c[3]==quant[3]
    return {{text=hardware and'GBC RGB555 COLOUR'or'CUSTOM RGB'}}
  end
  return P
end
return Values
