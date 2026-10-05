local GameplayData = require("GameLua.GameCore.Data.GameplayData")
local GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
local GameComponentData = require("GameLua.GameCore.Data.GameComponentData")
local InGameUITools = require("GameLua.Mod.BaseMod.Common.UI.InGameUITools")
local ShootingUIPanelUISubSystem = {}
local WeaponChangeType = {
  WeaponChange = 0,
  ScoopeChange = 1,
  AttachItemChange = 2
}
function ShootingUIPanelUISubSystem:ctor()
  self.bHasRegistEvents = false
  self.ShouldHideShootingUINode = {
    "SwitchThrowPan",
    "AimFirePanel",
    "Shoot_RedSight"
  }
  self.SpecialUIList = {}
end
function ShootingUIPanelUISubSystem:OnInit()
  print(bWriteLog and "ShootingUIPanelUISubSystem:OnInit")
  self.bBuffListUseTwoBox = false
  self:RegistEvents()
end
function ShootingUIPanelUISubSystem:OnRelease()
  print(bWriteLog and "ShootingUIPanelUISubSystem:OnRelease")
  ShootingUIPanelUISubSystem.__super.OnRelease(self)
end
function ShootingUIPanelUISubSystem:RegistEvents()
  if self.bHasRegistEvents then
    self:RemoveCommonEvent(EVENTTYPE_INGAME, EVENTID_ENTER_HOT_AIR_BALLOON)
    self:RemoveCommonEvent(EVENTTYPE_INGAME_SHOOTINGUI_PANEL, EVENTID_SHOOTINGUI_ADD_CUSTOM_WEAPONUI)
    self:RemoveCommonEvent(EVENTTYPE_PLAYEREVENT_WEAPON, EVENTID_PLAYEREVENT_WEAPON_DURABILITY_CHANAGED)
  end
  self.bHasRegistEvents = true
  self:AddCommonEvent(EVENTTYPE_INGAME, EVENTID_ENTER_HOT_AIR_BALLOON, self.HandEnterHotAirBallon, self)
  self:AddCommonEvent(EVENTTYPE_PLAYEREVENT_CHARACTER, EVENTID_PLAYEREVENT_SCOPECHANGE, self.OnScopingChange, self)
  self:AddCommonEvent(EVENTTYPE_INGAME_SHOOTINGUI_PANEL, EVENTID_SHOOTINGUI_ADD_CUSTOM_WEAPONUI, self.OnAddCustomWeaponUIWrapper, self)
  self:AddCommonEvent(EVENTTYPE_PLAYEREVENT_WEAPON, EVENTID_PLAYEREVENT_WEAPON_DURABILITY_CHANAGED, self.OnWeaponDurabilityChangedWrapper, self)
  self:AddCommonEvent(EVENTTYPE_PLAYEREVENT_WEAPON, EVENTID_PLAYEREVENT_WEAPON_CHANGE_WEAPONATTACHMENT, self.HandleChangeWeaponAttachment, self)
  GameplayData.AddSelfPlayerControllerEvent(self, "OnOBPlayerWeaponChangedDelegate", self.OnOBPlayerWeaponChanged, self)
  self:AddUIMessageEvent("UIMsg_SetLaunchShootingPanel", self.UIMsg_SetLaunchShootingPanel, self)
  self:AddUIMessageEvent("UIMsg_StopFire", self.UIMsg_StopFire, self)
  self:AddUIMessageEvent("UIMsg_PlayBulletEffect", self.UIMsg_PlayBulletEffect, self)
  self:AddUIMessageEvent("UIMsg_AdaptFBTipsWithIPX", self.UIMsg_AdaptFBTipsWithIPX, self)
  self:AddUIMessageEvent("UIMsg_HideSideSight", self.UIMsg_HideSideSight, self)
  self:AddUIMessageEvent("UIMsg_ShowDeathMatchUI", self.UIMsg_ShowDeathMatchUI, self)
  self:AddCommonEvent(EVENTTYPE_INGAME_CREATIVE_MODE, EVENTID_UPDATE_BUFFLIST_MODE, self.OnUpdateBuffListMode, self)
  self:AddDataListener(GameplayData.GetSuperData(), "PlayerCharacter", self.OnPlayerCharacterChanged, self)
  self:AddCommonEvent(EVENTTYPE_INGAME, EVENTID_INGAME_CUSTOMVIRTUALITEM_WEAPON_SPAWN, self.OnNewCustomVirtualItemSpawn, self)
end
function ShootingUIPanelUISubSystem:OnPlayerCharacterChanged(_, PlayerCharacter)
  if not slua.isValid(PlayerCharacter) then
    return
  end
  self:WeaponChange()
  GameComponentData.AddSelfWeaponManagerComponentEvent(self, "ChangeCurrentUsingWeaponDelegate", self.WeaponChange, self)
  self:AddControlEvent(PlayerCharacter, "OnDeathDelegate", self.WeaponChange, self)
  self:AddControlEvent(PlayerCharacter, "OnEndPlay", self.WeaponChange, self)
end
function ShootingUIPanelUISubSystem:HandleChangeWeaponAttachment(_, __, PlayerKey, TargetWeaponSlot, AttachmentID, bEquip)
  local PlayerCharacter = GameplayData.GetPlayerCharacter()
  if not slua.isValid(PlayerCharacter) then
    return
  end
  local CurWeapon = PlayerCharacter:GetCurrentShootWeapon()
  if not slua.isValid(CurWeapon) or not CurWeapon.GetWeaponSlot then
    return
  end
  local CurWeaponSlot = CurWeapon:GetWeaponSlot()
  if CurWeaponSlot ~= TargetWeaponSlot then
    return
  end
  local ModWeaponConfig = GamePlayTools.GetCurrentConfig("ModWeaponConfig")
  if ModWeaponConfig and ModWeaponConfig[AttachmentID] and next(ModWeaponConfig[AttachmentID]) then
    self:CloseWeaponSpecialUI()
    if not bEquip then
      print(bWriteLog and "ShootingUIPanelUISubSystem:HandleChangeWeaponAttachment - UnEquip AttachItemID")
      return
    end
    local Config = ModWeaponConfig[AttachmentID]
    if Config.NeedScope then
      local OwnerPawn = CurWeapon:GetOwnerPawn()
      if slua.isValid(OwnerPawn) and not OwnerPawn.bIsGunADS then
        print(bWriteLog and "ShootingUIPanelUISubSystem:HandleChangeWeaponAttachment - NeedScope but bIsGunADS is false")
        return false
      end
    end
    if Config.WeaponSpecialUI and next(Config.WeaponSpecialUI) then
      self.SpecialUIList = Config.WeaponSpecialUI
    end
  end
  self:ShowWeaponSpecialUI(CurWeapon)
end
function ShootingUIPanelUISubSystem:OnScopingChange(_, __, PlayerKey, bIsGunADS)
  print(bWriteLog and "ShootingUIPanelUISubSystem:OnScopingChange -", tostring(PlayerKey), tostring(bIsGunADS))
  local PlayerCharacter = GameplayData.GetPlayerCharacter()
  if not slua.isValid(PlayerCharacter) or PlayerCharacter.PlayerKey ~= PlayerKey then
    print(bWriteLog and "ShootingUIPanelUISubSystem:OnScopingChange - Wrong PlayerCharacter")
    return
  end
  self:HandleWeaponSpecialUI(WeaponChangeType.ScoopeChange)
end
function ShootingUIPanelUISubSystem:WeaponChange(TargetChangeSlot)
  self:HandleWeaponSpecialUI(WeaponChangeType.WeaponChange)
end
function ShootingUIPanelUISubSystem:OnOBPlayerWeaponChanged()
  self:HandleWeaponSpecialUI(WeaponChangeType.WeaponChange)
end
function ShootingUIPanelUISubSystem:HandleWeaponSpecialUI(WeaponChangeEvent)
  local PlayerController = GameplayData.GetPlayerController()
  if not slua.isValid(PlayerController) then
    return
  end
  local bIsOB = PlayerController:IsInSpectating()
  print(bWriteLog and "ShootingUIPanelUISubSystem:HandleWeaponSpecialUI - bIsOB is " .. tostring(bIsOB))
  if WeaponChangeEvent == WeaponChangeType.WeaponChange then
    self:CloseWeaponSpecialUI()
  end
  local PlayerCharacter = PlayerController:GetCurPlayerCharacter()
  if not slua.isValid(PlayerCharacter) then
    return
  end
  local WeaponManager = PlayerCharacter:GetWeaponManager()
  if not slua.isValid(WeaponManager) then
    return
  end
  local CurrentUsingWeapon = WeaponManager:GetCurrentUsingWeapon()
  if slua.isValid(CurrentUsingWeapon) then
    local WeaponID = CurrentUsingWeapon:GetWeaponID()
    local ModWeaponConfig = GamePlayTools.GetCurrentConfig("ModWeaponConfig")
    if ModWeaponConfig and ModWeaponConfig[WeaponID] and next(ModWeaponConfig[WeaponID]) then
      local Config = ModWeaponConfig[WeaponID]
      local WeaponSpecialUI = self:FiltrateOBSpecialUI(Config.WeaponSpecialUI, bIsOB)
      if Config.bNeedScope then
        if WeaponChangeEvent == WeaponChangeType.ScoopeChange then
          self:CloseWeaponSpecialUI()
        end
        local OwnerPawn = CurrentUsingWeapon:GetOwnerPawn()
        local bIsGunADS = slua.isValid(OwnerPawn) and OwnerPawn.bIsGunADS
        if not bIsGunADS then
          print(bWriteLog and string.format("ShootingUIPanelUISubSystem:WeaponChange - WeaponID %s NeedScope but bIsGunADS is false", tostring(WeaponID)))
        elseif WeaponSpecialUI and next(WeaponSpecialUI) then
          self.SpecialUIList = WeaponSpecialUI
        end
      elseif WeaponSpecialUI and next(WeaponSpecialUI) then
        self.SpecialUIList = WeaponSpecialUI
      end
    elseif CurrentUsingWeapon.WeaponSpecialUIList and next(CurrentUsingWeapon.WeaponSpecialUIList) then
      log_warning("The SpecialUIList Config in Weapon will be Deprecated in the Future")
      self.SpecialUIList = CurrentUsingWeapon.WeaponSpecialUIList
    end
    local AttachmentID = CurrentUsingWeapon.AttachedAttachmentID
    if ModWeaponConfig and AttachmentID then
      for _, ID in pairs(AttachmentID) do
        local Config = ModWeaponConfig[ID]
        if Config and Config.WeaponSpecialUI and next(Config.WeaponSpecialUI) then
          local WeaponSpecialUIList
          if not bIsOB then
            WeaponSpecialUIList = Config.WeaponSpecialUI
          else
            WeaponSpecialUIList = self:FiltrateOBSpecialUI(Config.WeaponSpecialUI, bIsOB)
          end
          for _, WeaponSpecialUI in ipairs(WeaponSpecialUIList) do
            table.insert(self.SpecialUIList, WeaponSpecialUI)
          end
        end
      end
    end
    self:ShowWeaponSpecialUI(CurrentUsingWeapon)
  end
end
function ShootingUIPanelUISubSystem:ShowWeaponSpecialUI(CurrentUsingWeapon)
  for _, UIName in pairs(self.SpecialUIList) do
    local Config = UIManager.UI_Config_InGame[UIName]
    if Config then
      local WeaponUI = UIManager.ShowUI(Config)
      if WeaponUI and WeaponUI.UpdateCurrentWeapon then
        WeaponUI:UpdateCurrentWeapon(CurrentUsingWeapon)
      end
    end
  end
end
function ShootingUIPanelUISubSystem:CloseWeaponSpecialUI()
  for _, UIName in pairs(self.SpecialUIList) do
    local Config = UIManager.UI_Config_InGame[UIName]
    if Config then
      UIManager.CloseUI(Config)
    end
  end
  self.SpecialUIList = {}
end
function ShootingUIPanelUISubSystem:FiltrateOBSpecialUI(WeaponSpecialUIConfig, bIsOB)
  local WeaponSpecialUI = {}
  if not WeaponSpecialUIConfig or not next(WeaponSpecialUIConfig) then
    print(bWriteLog and "ShootingUIPanelUISubSystem:FiltrateOBSpecialUI - WeaponSpecialUIConfig is nil")
    return WeaponSpecialUI
  end
  for Index, Value in pairs(WeaponSpecialUIConfig) do
    if bIsOB and type(Index) == "string" and type(Value) == "table" and Value.bOBShow == true then
      table.insert(WeaponSpecialUI, Index)
    elseif not bIsOB then
      if type(Index) == "string" then
        table.insert(WeaponSpecialUI, Index)
      elseif type(Value) == "string" then
        table.insert(WeaponSpecialUI, Value)
      end
    end
  end
  return WeaponSpecialUI
end
function ShootingUIPanelUISubSystem:HandEnterHotAirBallon(_, _, bIsEnter)
  local ShowHideUIFlag = require("GameLua.Mod.BaseMod.Client.Config.ShowHideUIFlag")
  if bIsEnter then
    local ShootingUIPanelLuaClass = InGameUITools.GetShootingUIPanelLuaClass()
    if ShootingUIPanelLuaClass and ShootingUIPanelLuaClass.UIRoot then
      local UIRoot = ShootingUIPanelLuaClass.UIRoot
      for _, WidgetName in pairs(self.ShouldHideShootingUINode) do
        local Widget = UIRoot[WidgetName]
        if Widget then
          Widget:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
        end
      end
    end
    EventSystem:postEvent(EVENTTYPE_INGAME, EVENTID_SHOW_HIDE_UI_WITH_FLAG, ShowHideUIFlag.bEnterHalloWeen2Drive, true)
  else
    local PlayerController = GameplayData.GetPlayerController()
    if slua.isValid(PlayerController) then
      PlayerController:CastUIMsg("SwitchOperationUI", "ingame")
    end
    EventSystem:postEvent(EVENTTYPE_INGAME, EVENTID_SHOW_HIDE_UI_WITH_FLAG, ShowHideUIFlag.bEnterHalloWeen2Drive, false)
  end
end
function ShootingUIPanelUISubSystem:UIMsg_ShowDeathMatchUI()
  local ShootingUIPanelLuaClass = InGameUITools.GetShootingUIPanelLuaClass()
  if not ShootingUIPanelLuaClass then
    return
  end
  ShootingUIPanelLuaClass.UIRoot.ConsumeListPanel:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  local ShowHideUIFlag = require("GameLua.Mod.BaseMod.Client.Config.ShowHideUIFlag")
  EventSystem:postEvent(EVENTTYPE_INGAME, EVENTID_SHOW_HIDE_UI_WITH_FLAG, ShowHideUIFlag.bShowDeathMatchUI, true)
end
function ShootingUIPanelUISubSystem:UIMsg_HideSideSight()
  local ShootingUIPanelLuaClass = InGameUITools.GetShootingUIPanelLuaClass()
  if not (ShootingUIPanelLuaClass and ShootingUIPanelLuaClass.UIRoot) or not ShootingUIPanelLuaClass.UIRoot.RedSight_UIBP then
    return
  end
  ShootingUIPanelLuaClass.UIRoot.RedSight_UIBP:UIMsg_HideSideSight()
end
function ShootingUIPanelUISubSystem:UIMsg_AdaptFBTipsWithIPX()
  local ShootingUIPanelLuaClass = InGameUITools.GetShootingUIPanelLuaClass()
  if not ShootingUIPanelLuaClass then
    return
  end
  ShootingUIPanelLuaClass:AdaptFBTipsWithIPX()
end
function ShootingUIPanelUISubSystem:UIMsg_PlayBulletEffect()
  local PlayerController = GameplayData.GetPlayerController()
  if not slua.isValid(PlayerController) then
    return
  end
  local PlayerCharacter = PlayerController.STExtraBaseCharacter
  if not slua.isValid(PlayerCharacter) then
    return
  end
  local WeaponManager = PlayerCharacter:GetWeaponManager()
  if not slua.isValid(WeaponManager) then
    return
  end
  local CurrentShootWeapon = PlayerCharacter:GetCurrentShootWeapon()
  if not slua.isValid(CurrentShootWeapon) then
    return
  end
  local ShootingUIPanelLuaClass = InGameUITools.GetShootingUIPanelLuaClass()
  if not ShootingUIPanelLuaClass then
    return
  end
  local ESurviveWeaponPropSlot = import("ESurviveWeaponPropSlot")
  local CurrentAnimation
  if WeaponManager:GetInventoryWeaponByPropSlot(ESurviveWeaponPropSlot.SWPS_MainShootWeapon1) == CurrentShootWeapon then
    CurrentAnimation = ShootingUIPanelLuaClass.FirWeaponSlot.UIRoot.BulletFull
  elseif WeaponManager:GetInventoryWeaponByPropSlot(ESurviveWeaponPropSlot.SWPS_MainShootWeapon2) == CurrentShootWeapon then
    CurrentAnimation = ShootingUIPanelLuaClass.SecWeaponSlot.UIRoot.BulletFull
  elseif WeaponManager:GetInventoryWeaponByPropSlot(ESurviveWeaponPropSlot.SWPS_SubShootWeapon) == CurrentShootWeapon then
    CurrentAnimation = ShootingUIPanelLuaClass.PistolModeUI.UIRoot.BulletFull
  end
  if CurrentAnimation then
    ShootingUIPanelLuaClass:PlayUserWidgetAnimation(CurrentAnimation, 0, 1, 0, 1)
  end
end
function ShootingUIPanelUISubSystem:UIMsg_StopFire()
  local PlayerController = GameplayData.GetPlayerController()
  if not slua.isValid(PlayerController) then
    return
  end
  local PlayerCharacter = PlayerController:GetPlayerCharacterSafety()
  if not slua.isValid(PlayerCharacter) then
    return
  end
  PlayerCharacter:StopFire()
  PlayerCharacter:MeleeReleased()
  local ShootingUIPanelLuaClass = InGameUITools.GetShootingUIPanelLuaClass()
  if not ShootingUIPanelLuaClass then
    return
  end
  ShootingUIPanelLuaClass:OnReleaseFireBtn()
end
function ShootingUIPanelUISubSystem:UIMsg_SetLaunchShootingPanel()
  local ShootingUIPanelLuaClass = InGameUITools.GetShootingUIPanelLuaClass()
  if not ShootingUIPanelLuaClass then
    return
  end
  ShootingUIPanelLuaClass:ShowUIByOperation(UEnums.UIOperation.Parachute)
end
function ShootingUIPanelUISubSystem:OnAddCustomWeaponUIWrapper(_, _, CustomUI)
  local ShootingUIPanelLuaClass = InGameUITools.GetShootingUIPanelLuaClass()
  if not ShootingUIPanelLuaClass then
    return
  end
  ShootingUIPanelLuaClass:OnAddCustomWeaponUIWrapper(_, _, CustomUI)
end
function ShootingUIPanelUISubSystem:OnWeaponDurabilityChangedWrapper(_, _, WeaponSlot)
  local ShootingUIPanelLuaClass = InGameUITools.GetShootingUIPanelLuaClass()
  if not ShootingUIPanelLuaClass then
    return
  end
  ShootingUIPanelLuaClass:OnWeaponDurabilityChangedWrapper(_, _, WeaponSlot)
end
function ShootingUIPanelUISubSystem:OnUpdateBuffListMode(_, _, bBuffListUseTwoBox)
  print(bWriteLog and "ShootingUIPanelUISubSystem:OnUpdateBuffListMode bBuffListUseTwoBox", bBuffListUseTwoBox)
  self.bBuffListUseTwoBox = bBuffListUseTwoBox
  local SuperData = self:GetSuperData()
  if SuperData then
    SuperData.bBuffListUseTwoBox = bBuffListUseTwoBox
  end
end
function ShootingUIPanelUISubSystem:OnNewCustomVirtualItemSpawn(_, _, ItemID)
  local PlayerCharacter = GameplayData.GetPlayerCharacter()
  if not slua.isValid(PlayerCharacter) then
    return
  end
  local WeaponManager = PlayerCharacter:GetWeaponManager()
  if not slua.isValid(WeaponManager) then
    return
  end
  local CurrentUsingWeapon = WeaponManager:GetCurrentUsingWeapon()
  if not slua.isValid(CurrentUsingWeapon) then
    return
  end
  local WeaponID = CurrentUsingWeapon:GetItemDefineID().TypeSpecificID
  if WeaponID and WeaponID == ItemID then
    local CustomVirtualItemSubsystem = SubsystemMgr:Get("CustomVirtualItemSubsystem")
    if CustomVirtualItemSubsystem then
      local BluePrintInfo = CustomVirtualItemSubsystem:GetBluePrintInfo(ItemID)
      if BluePrintInfo.WeaponSpecialUIList and next(BluePrintInfo.WeaponSpecialUIList) then
        print(bWriteLog and "ShootingUIPanelUISubSystem:OnNewCustomVirtualItemSpawn ItemID", ItemID)
        self:CloseWeaponSpecialUI()
        self.SpecialUIList = BluePrintInfo.WeaponSpecialUIList
        self:ShowWeaponSpecialUI(CurrentUsingWeapon)
      end
    end
  end
end
local class = require("class")
local CSubsystemBase = require("GameLua.GameCore.Module.Subsystem.SubsystemBase")
return class(CSubsystemBase, nil, ShootingUIPanelUISubSystem)
