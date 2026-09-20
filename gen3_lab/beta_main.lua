-- Entry used only by the staged FireRed test package. The stable main.lua is
-- intentionally not generation-dispatched until this beta is proven.
return function(mod)
 local function module(name)
  return assert(load(assert(mod:read(name..'.lua')),'@autobike_plus_firered_beta/'..name..'.lua'))()
 end
 local settings=module('settings').init(mod)
 local menu=module('native_menu').new()
 local integration=module('integration').attach(mod,{
  settings=settings,menu=menu,Machine=module('mount'),NativeMount=module('native_mount'),
 })
 mod.exports.beta=integration
end
