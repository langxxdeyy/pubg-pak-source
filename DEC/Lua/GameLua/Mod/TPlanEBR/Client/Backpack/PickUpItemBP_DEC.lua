local PickUpItem_BP = {}
local GameplayData = require("GameLua.GameCore.Data.GameplayData")
local BackpackTPlanLibrary = require("GameLua.Mod.TPlan.Client.Backpack.BackpackTPlanLibrary")
function PickUpItem_BP:CheckQuality()
  local ItemData = self:GetItemTableData(self.TypeSpecificID)
  if not ItemData then
    return false
  end
  local ItemType = ItemData.ItemType
  local ItemSubType = ItemData.ItemSubType
  if ItemType == 1 then
    local WeaponQuality = self:GetCurWeaponQuality(ItemSubType)
    if WeaponQuality > self.Quality then
      return true
    elseif self:CheckValuableWeapon() then
      return true
    end
    return false
  elseif ItemSubType == 501 then
    local uCharacter = GameplayData.GetPlayerCharacter()
    if not slua.isValid(uCharacter) then
      return false
    end
    local USTExtraBlueprintFunctionLibrary = import("STExtraBlueprintFunctionLibrary")
    local BackPackComp = USTExtraBlueprintFunctionLibrary.GetBackpackComponentFromCharacter(uCharacter)
    if not slua.isValid(BackPackComp) then
      return false
    end
    local ItemQuality = self:GetEquipedArmorQuality(false, ItemSubType, BackPackComp)
    return ItemQuality > self.Quality
  elseif ItemSubType == 502 or ItemSubType == 503 then
    local uCharacter = GameplayData.GetPlayerCharacter()
    if not slua.isValid(uCharacter) then
      return false
    end
    local USTExtraBlueprintFunctionLibrary = import("STExtraBlueprintFunctionLibrary")
    local BackPackComp = USTExtraBlueprintFunctionLibrary.GetBackpackComponentFromCharacter(uCharacter)
    if not slua.isValid(BackPackComp) then
      return false
    end
    local ItemQuality = self:GetEquipedArmorQuality(true, ItemSubType, BackPackComp)
    return ItemQuality > self.Quality
  end
  return false
end
function PickUpItem_BP:CheckValuableWeapon()
  local BackpackTPlanLibrary = require("GameLua.Mod.TPlan.Client.Backpack.BackpackTPlanLibrary")
  if BackpackTPlanLibrary and BackpackTPlanLibrary.IsValuableWeapon(self.TypeSpecificID) and BackpackTPlanLibrary.IsMeleeWeaponValuable() then
    return true
  end
  return false
end
local class = require("class")
local CDelegateContainer = require("GameLua.Mod.BaseMod.Client.Backpack.PickUpItemBP")
return class(CDelegateContainer, nil, PickUpItem_BP)
