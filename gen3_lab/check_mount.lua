local root=arg[1]or'gen3_lab';local Model=dofile(root..'/mount.lua');local n=0
local function ck(v,m)assert(v,m);n=n+1 end
local function fresh()return{session={},map='FR_ROUTE_1',field=true,enabled=true,hasBike=true,riding=false}end
for _,flag in ipairs({'safeMode','busy','moving','surfing','jumping','hidden','manualInput'})do
 local m=Model.new();local s=fresh();s[flag]=true;local calls=0
 local function use()calls=calls+1;s.riding=true;return true end
 for i=1,20 do ck(not m:step(s,use),'mounted during '..flag)end
 ck(calls==0,'native action called during '..flag);s[flag]=false
 ck(m:step(s,use)and calls==1,'did not retry when '..flag..' cleared')
 ck(not m:step(s,use)and calls==1,'already-mounted player toggled off')
end
for _,allowed in ipairs({true,false})do
 local m=Model.new();local s=fresh();local calls=0
 local function use()calls=calls+1;s.riding=allowed;return allowed end
 m:step(s,use);for i=1,100 do m:step(s,use)end
 ck(calls==1,'repeated toggle/rejection this visit')
 s.riding=false;s.map='FR_ROUTE_2';m:step(s,use);ck(calls==2,'new map did not reset decision')
 m:manual(true,false);s.riding=false
 for i=1,100 do m:step(s,use)end
 ck(calls==2,'manual dismount not retained')
 s.map='FR_ROUTE_1';m:step(s,use);ck(calls==3,'re-entering earlier area did not rearm')
end
local m=Model.new();local s=fresh();local calls=0
local function use()calls=calls+1;s.riding=true;return true end
s.hasBike=false;ck(not m:step(s,use)and calls==0,'granted missing bike')
s.hasBike=true;s.enabled=false;ck(not m:step(s,use)and calls==0,'ignored disabled')
s.enabled=true;ck(m:step(s,use),'explicit re-enable not usable')
s.riding=false;m:step(s,use);ck(calls==1,'unclassified dismount immediately remounted')
s.session={};ck(m:step(s,use)and calls==2,'new session stuck with old suppression')
m:reset();s=fresh();ck(not m:step(s,function()error('native test error')end),'native error was accepted')
ck(not m:step(s,use)and calls==2,'error retried every frame')
print('PASS '..n..' pure auto-mount state and native-action deferral assertions.')
