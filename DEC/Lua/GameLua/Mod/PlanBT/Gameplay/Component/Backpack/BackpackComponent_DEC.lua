local BackpackComponent = {}
local ItemConfig = require("GameLua.Mod.PlanBT.Gameplay.Config.ItemConfig")
local BROOM_ITEM_ID = 604154
local BROOM_SKILL_ID = 4900011
local BROOM_SKILL_SLOT = 3
local PLANBT_BROOM_VEHICLE_CLASS = "/Game/Mod/PlanBT/BluePrints/Actor/Vehicle/VH_Broom_PlanBT.VH_Broom_PlanBT"
function BackpackComponent:ctor(selfType)
end
function BackpackComponent:ReceiveBeginPlay()
  BackpackComponent.__super.ReceiveBeginPlay(self)
  if not Client then
    self:AddControlEvent(self.Object, "ItemOperationDelegate", self.OnItemOperationDelegate, self)
    self:ServerSetDropMeelWeapon(true)
  end
end
function BackpackComponent:NewItemHandle(DefineID)
  local uItemHandle = BackpackComponent.__super.NewItemHandle(self, DefineID)
  if DefineID.TypeSpecificID == BROOM_ITEM_ID and slua.isValid(uItemHandle) then
    uItemHandle.VehicleClass = PLANBT_BROOM_VEHICLE_CLASS
    print(bWriteLog and string.format("[PlanBT] BackpackComponent:NewItemHandle - Override broom VehicleClass[%s]", PLANBT_BROOM_VEHICLE_CLASS))
  end
  return uItemHandle
end
function BackpackComponent:PickUpItem_Default(DefineID, PickupInfo, Reason)
  local uBroomSkillManager
  if DefineID.TypeSpecificID == BROOM_ITEM_ID then
    local uPlayerController = self:GetOwner()
    local uPlayerCharacter = slua.isValid(uPlayerController) and uPlayerController:GetPlayerCharacterSafety()
    uBroomSkillManager = slua.isValid(uPlayerCharacter) and uPlayerCharacter.SkillManager
    if not slua.isValid(uBroomSkillManager) then
      return false
    end
    local nSlotSkillID = uBroomSkillManager:GetButtonSlotSkillID(BROOM_SKILL_SLOT)
    if 0 < nSlotSkillID and nSlotSkillID ~= BROOM_SKILL_ID then
      print(bWriteLog and string.format("[PlanBT] BackpackComponent:PickUpItem_Default - Broom slot occupied PlayerKey[%s] SkillID[%d]", tostring(uPlayerCharacter.PlayerKey), nSlotSkillID))
      self:BroadcastItemOperationFailedDelegate(DefineID, UEnums.EBattleItemOperationType.Pickup, UEnums.EBattleItemOperationFailedReason.PickupFailed_Default)
      return false
    end
  end
  if DefineID.Type == 1 or DefineID.Type == 30 then
    local Config = ItemConfig[DefineID.TypeSpecificID]
    self:AddSkillInfo(Config)
  end
  local bResult = self.Super:PickUpItem_Default(DefineID, PickupInfo, Reason)
  if bResult and uBroomSkillManager and uBroomSkillManager:GetSkillButtonSlot(BROOM_SKILL_ID) ~= BROOM_SKILL_SLOT then
    uBroomSkillManager:TryAddOneSkill(BROOM_SKILL_ID, true, BROOM_SKILL_SLOT)
    uBroomSkillManager:SetSkillActive(BROOM_SKILL_ID, true, true, BROOM_SKILL_SLOT)
  end
  return bResult
end
function BackpackComponent:DropItem(DefineID, Count, Reason)
  if DefineID.Type == 1 then
    local Config = ItemConfig[DefineID.TypeSpecificID]
    self:RemoveSkillInfo(Config)
  end
  return self.Super:DropItem(DefineID, Count, Reason)
end
function BackpackComponent:OnItemOperationDelegate(DefineID, OperationType, Reason)
end
function BackpackComponent:AddSkillInfo(Config)
  if not Config then
    return
  end
  if not Config.bAddSkillInfo then
    return
  end
  local uPlayerController = self:GetOwner()
  if not slua.isValid(uPlayerController) then
    return
  end
  local uPlayerCharacter = uPlayerController:GetPlayerCharacterSafety()
  if not slua.isValid(uPlayerCharacter) then
    return
  end
  local uSkillManager = uPlayerCharacter.SkillManager
  if not slua.isValid(uSkillManager) then
    return
  end
  if Config.Level and Config.SkillID then
    uSkillManager:SetSkillLevel(Config.SkillID, Config.Level)
    print(bWriteLog and string.format("BackpackComponent:AddSkillInfo SetSkillLevel SkillID[%d] Level[%d]", Config.SkillID, Config.Level))
  elseif Config.SkillBuffID then
  elseif Config.SkillID then
    uSkillManager:TryAddOneSkill(Config.SkillID, true, 0)
    print(bWriteLog and string.format("BackpackComponent:AddSkillInfo TryAddOneSkill SkillID[%d]", Config.SkillID))
  end
end
function BackpackComponent:RemoveSkillInfo(Config)
  if not Config then
    return
  end
  if not Config.bRemoveSkillInfo then
    return
  end
end
function BackpackComponent:ServerSetDropMeelWeapon(bDrop)
  if bDrop then
    print(bWriteLog and "BackpackComponent:ServerSetDropMeelWeapon call super")
    self.Super:ServerSetDropMeelWeapon(bDrop)
  else
    print(bWriteLog and "BackpackComponent:ServerSetDropMeelWeapon do nothing")
  end
end
local class = require("class")
local CBackpackComponentBase = require("GameLua.Mod.CreativeBase.GamePlay.Component.CreativeModeBackPackComponent")
return class(CBackpackComponentBase, nil, BackpackComponent)
