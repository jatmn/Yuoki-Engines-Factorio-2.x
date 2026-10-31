--[[Yuoki intermediates script
Copyright joshrick (Codec) © August 2020
adds Yuoki intermediate products to the vanilla intermediates list--]]
local productivity_item_list = {
  "y-iron-case",
  "y-quantrinum-charge",
  "ye_center",
  "ye_sealing",
  "y-winding",
  "yie_pureiron",
  "yie_hard_metals",
  "ye_buechsenblech",
}

for _, name in ipairs(productivity_item_list) do
  data.raw.recipe[name].allow_productivity = true
end
