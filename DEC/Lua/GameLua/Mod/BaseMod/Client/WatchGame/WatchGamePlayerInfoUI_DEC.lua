local EPawnState = import("EPawnState")
local ESTEPoseState = import("ESTEPoseState")
local EBulletClipType = import("EBulletClipType")
local ESurviveWeaponPropSlot = import("ESurviveWeaponPropSlot")
local ECharacterPoseType = import("ECharacterPoseType")
local USTExtraUIUtils = import("STExtraUIUtils")
local UAESkillManagerUtils = import("UAESkillManagerUtils")
local UIDataProcessingFunctionLibrary = import("UIDataProcessingFunctionLibrary")
local GameplayData = require("GameLua.GameCore.Data.GameplayData")
local GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
local WatchGamePlayerInfoUI = {}
function WatchGamePlayerInfoUI:ctor()
  self.bDriveVehicle = false
  self.TimerHandleForceUpdateHP = nil
  self.ModWeaponUI = {}
  self.TimerHandlePredictStayOver = nil
  self.TimerHandleTickCheck = nil
  self.CurHealth = 0
  self.CurEnergy = 0
  self.FixWeaponIcon = false
  self.RecoverStartHealth = 0
  self.RecoverCount = 0
  self.PredictStepValue = 0
  self.PrePredictValue = 0
  self.TotalAddToHealth = 0
  self.WaitAddPredictTime = 0
  self.NeedPredictWaitForHide = false
  self.IsMultAddHealth = false
  self.PredictHideBaseHealth = 0
  self.CurPredictHealth = 0
end
function WatchGamePlayerInfoUI:OnInitialize()
  WatchGamePlayerInfoUI.__super.OnInitialize(self)
  self:SetAnchors(0, 0, 1, 1)
  self:SetAlignment(0.5, 1)
  self:SetOffsets(0, 0, 0, 0)
  self:Localization()
  self:SetInfoWeapon()
  self:SetInfoArmor()
  self:OnPoseChanged(ESTEPoseState.Stand, true)
  local PC = GameplayData.GetPlayerController()
  if slua.isValid(PC) and PC.GetCurPawn then
    local CurPawn = PC:GetCurPawn()
    print(bWriteLog and string.format("WatchGamePlayerInfoUI:OnInitialize CurPawn[%s]", tostring(CurPawn)))
    if slua.isValid(CurPawn) and CurPawn.Health and CurPawn.HealthMax and 0 < CurPawn.HealthMax then
      self:OnUpdateHP(CurPawn.Health, CurPawn.Health / CurPawn.HealthMax)
    end
  end
  self.FixWeaponIcon = true
end
function WatchGamePlayerInfoUI:RegistEvents()
  WatchGamePlayerInfoUI.__super.RegistEvents(self)
  print(bWriteLog and "WatchGamePlayerInfoUI:RegistEvents ")
  self:AddUIMessageEvent("PlayerInfo_UpdatePredictHealth", self.OnPlayerInfo_UpdatePredictHealth, self)
  self:AddUIMessageEvent("PlayerInfo_UpdateEnergy", self.OnPlayerInfo_UpdateEnergy, self)
  GameplayData.AddSelfPlayerControllerEvent(self, "OnViewTargetChange", self.OnViewTargetChange, self)
  GameplayData.AddSelfPlayerControllerEvent(self, "OnReconnectResetUIByPlayerControllerStateDelegate", self.OnReconnectResetUIByPlayerControllerStateDelegate, self)
  GameplayData.AddSelfPlayerControllerEvent(self, "OnSpectatorChange", self.OnSpectatorChange, self)
  GameplayData.AddSelfPlayerControllerEvent(self, "OnOBPlayerItemChangedDelegate", self.OnOBPlayerBulletChanged, self)
  GameplayData.AddSelfPlayerControllerEvent(self, "OnOBPlayerBulletChangedDelegate", self.OnOBPlayerBulletChanged, self)
  GameplayData.AddSelfPlayerControllerEvent(self, "OnOBPlayerWeaponChangedDelegate", self.OnOBPlayerWeaponChanged, self)
  GameplayData.AddSelfPlayerControllerEventWithCondition(self, "OnCharacterStatesChangeWithFilterState", {
    State = {
      EPawnState.DriveVehicle
    }
  }, self.OnCharacterStatesChange, self)
  self:AddCommonEvent(EVENTTYPE_INGAME_REPLAY, EVENTID_REFRESH_WEAPONUI, self.UISettingWeapon, self)
  self:AddUIMessageEvent("UISetting_Weapon", self.UISettingWeapon, self)
  self:AddCommonEvent(EVENTTYPE_INGAME_REPLAY, EVENTID_REFRESH_BULLETUI, self.UISettingBullet, self)
  self:AddUIMessageEvent("UISetting_Bullet", self.UISettingBullet, self)
  self:AddCommonEvent(EVENTTYPE_INGAME_REPLAY, EVENTID_AFTER_SET_VIEWTARGET, self.UpdatePlayerInfo, self)
  self:AddCommonEvent(EVENTTYPE_INGAME_REPLAY, EVENTID_BEGIN_DEATH_CAMERA, self.OnReplayUIInit, self)
  self:InitUI()
  self.TimerHandleForceUpdateHP = self:AddGameTimer(3, true, function()
    print(bWriteLog and "WatchGamePlayerInfoUI:TimerHandleForceUpdateHP")
    self:ForceUpdateHP()
  end)
  self.TimerHandleTickCheck = self:AddGameTimer(0.2, true, function()
    self:OnTickCheck(0.2)
  end)
end
function WatchGamePlayerInfoUI:OnReconnectResetUIByPlayerControllerStateDelegate()
  print(bWriteLog and "WatchGamePlayerInfoUI:OnReconnectResetUIByPlayerControllerStateDelegate")
  self:UIMsg_ForceUpdate_Health()
end
function WatchGamePlayerInfoUI:OnViewTargetChange()
  print(bWriteLog and "WatchGamePlayerInfoUI:OnViewTargetChange")
  self:TryUpdateCurPawnHP()
  self:PlayerInfo_UpdateEnergy()
end
function WatchGamePlayerInfoUI:OnPlayerInfo_UpdatePredictHealth()
  print(bWriteLog and "WatchGamePlayerInfoUI:OnPlayerInfo_UpdatePredictHealth")
  self:TryUpdateCurPawnHP()
  self:PlayerInfo_UpdatePredictHealth()
end
function WatchGamePlayerInfoUI:OnPlayerInfo_UpdateEnergy()
  print(bWriteLog and "WatchGamePlayerInfoUI:OnPlayerInfo_UpdateEnergy")
  self:PlayerInfo_UpdateEnergy()
end
function WatchGamePlayerInfoUI:InitUI()
  local PC = GameplayData.GetPlayerController()
  if not slua.isValid(PC) then
    return
  end
  GameplayData.AddSelfPlayerControllerEvent(self, "OnCharacterBreathChange", self.OnUpdateBreath, self)
  GameplayData.AddSelfPlayerControllerEvent(self, "OnCharacterRecoveryHealth", self.OnRecoveryStart, self)
  GameplayData.AddSelfPlayerControllerEvent(self, "OnLocalCharacterHPChangeDel", self.OnUpdateHP, self)
  GameplayData.AddSelfPlayerControllerEvent(self, "PlayerControllerRespawnedDelegate", self.Event_OnPlayerControllerRespawned, self)
  GameplayData.AddSelfPlayerControllerEvent(self, "OnCharacterNearDeathOrRescueingOtherNotifyDelegate", self.Event_OnNearDeathOrRescuing, self)
  GameplayData.AddSelfPlayerControllerEvent(self, "OnViewTargetPoseChangedDelegate", self.OnViewTargetPoseChanged, self)
end
function WatchGamePlayerInfoUI:TryUpdateCurPawnHP()
  local PC = GameplayData.GetPlayerController()
  if slua.isValid(PC) and PC.GetCurPawn then
    local CurPawn = PC:GetCurPawn()
    print(bWriteLog and string.format("WatchGamePlayerInfoUI:TryUpdateCurPawnHP - CurPawn %s", tostring(CurPawn)))
    if slua.isValid(CurPawn) and CurPawn.Health and CurPawn.HealthMax and CurPawn.HealthMax > 0 then
      self:OnUpdateHP(CurPawn.Health, CurPawn.Health / CurPawn.HealthMax)
    end
  end
end
function WatchGamePlayerInfoUI:OnUpdateHP(CurrentHP, RatioHP)
  local nRatio = math.max(0, math.min(1, RatioHP))
  self.CurHealth = CurrentHP
  if 0.9999 <= nRatio then
    self.UIRoot.WidgetSwitcher_Self_HPStatus:SetActiveWidgetIndex(0)
  elseif 0.7499 <= nRatio then
    self.UIRoot.WidgetSwitcher_Self_HPStatus:SetActiveWidgetIndex(1)
    self.UIRoot.Self_BeingHitBar:SetPercent(nRatio)
  elseif 0.2499 <= nRatio then
    self.UIRoot.WidgetSwitcher_Self_HPStatus:SetActiveWidgetIndex(2)
    self.UIRoot.Self_LowHPWaringBar:SetPercent(nRatio)
  elseif 0 <= nRatio then
    self.UIRoot.WidgetSwitcher_Self_HPStatus:SetActiveWidgetIndex(3)
    local nLowRatio = math.max(0.005, math.min(0.2499, nRatio))
    self.UIRoot.Self_DeadBar:SetPercent(nLowRatio)
  end
  local uPawn = USTExtraUIUtils.GetOwningPlayerPawnOrVehicleDriver(self.UIRoot)
  local PlayerState = slua.isValid(uPawn) and uPawn.GetPlayerStateSafety and uPawn:GetPlayerStateSafety()
  if slua.isValid(PlayerState) and PlayerState.GetPlayerHealth and PlayerState.GetPlayerMaxHealth then
    local nHealth = PlayerState:GetPlayerHealth()
    local nMaxHealth = PlayerState:GetPlayerMaxHealth()
    local sHPText = string.format("%s/%s", tostring(nHealth), tostring(nMaxHealth))
    self.UIRoot.TextBlock_HP:SetText(sHPText)
  end
end
function WatchGamePlayerInfoUI:OnUpdateBreath(Breath, Ratio, Who, HealthStatus)
  local bShouldUpdate = false
  local PlayerCharacter = slua.isValid(Who) and Who or nil
  if slua.isValid(PlayerCharacter) and PlayerCharacter.ShouldUpdateHPOnUI then
    bShouldUpdate = PlayerCharacter:ShouldUpdateHPOnUI()
  end
  if not bShouldUpdate then
    local uWidget = self.UIRoot
    local OwningPlayer = slua.isValid(uWidget) and uWidget:GetOwningPlayer() or nil
    if slua.isValid(PlayerCharacter) and PlayerCharacter.GetController then
      local Controller = PlayerCharacter:GetController()
      if slua.isValid(Controller) and slua.isValid(OwningPlayer) and Controller == OwningPlayer then
        bShouldUpdate = true
      end
    end
  end
  if not bShouldUpdate then
    return
  end
  print(bWriteLog and string.format("WatchGamePlayerInfoUI:OnUpdateBreath - breath is %s health state is %s", tostring(Breath), tostring(HealthStatus)))
  if 2 <= HealthStatus then
    self.UIRoot.Self_DeadBar:SetPercent(0)
    self.UIRoot.WidgetSwitcher_Self_HPStatus:SetActiveWidgetIndex(3)
  elseif HealthStatus ~= 0 then
    local nRatio = math.max(0, math.min(1, Ratio))
    self.UIRoot.Self_DeadBar:SetPercent(nRatio)
    self.UIRoot.WidgetSwitcher_Self_HPStatus:SetActiveWidgetIndex(3)
  end
end
function WatchGamePlayerInfoUI:UIMsg_ForceUpdate_Health()
  local uPawn = GameplayData.GetPlayerCharacter()
  if not slua.isValid(uPawn) then
    return
  end
  local nHealth = uPawn.Health or 0
  local nHealthMax = uPawn.HealthMax or 1
  if nHealthMax <= 0 then
    return
  end
  local nRatio = math.max(0, math.min(1, nHealth / nHealthMax))
  self.CurHealth = nRatio
  if 0.9999 <= nRatio then
    self.UIRoot.WidgetSwitcher_Self_HPStatus:SetActiveWidgetIndex(0)
    return
  end
  if 0.7499 <= nRatio then
    self.UIRoot.WidgetSwitcher_Self_HPStatus:SetActiveWidgetIndex(1)
    self.UIRoot.Self_BeingHitBar:SetPercent(nRatio)
    return
  end
  if 0.2499 <= nRatio then
    self.UIRoot.WidgetSwitcher_Self_HPStatus:SetActiveWidgetIndex(2)
    self.UIRoot.Self_LowHPWaringBar:SetPercent(nRatio)
    return
  end
  self.UIRoot.WidgetSwitcher_Self_HPStatus:SetActiveWidgetIndex(3)
  self.UIRoot.Self_DeadBar:SetPercent(nRatio)
end
function WatchGamePlayerInfoUI:UpdateHP()
  local uPC = GameplayData.GetPlayerController()
  if not slua.isValid(uPC) then
    return
  end
  if not uPC.GetCurPawn then
    return
  end
  local uPawn = uPC:GetCurPawn()
  print("WatchGamePlayerInfoUI:UpdateHP", uPawn)
  if not slua.isValid(uPawn) then
    return
  end
  local nHealth = uPawn.Health or 0
  local nHealthMax = uPawn.HealthMax or 0
  if nHealthMax <= 0 then
    return
  end
  local nRatio = nHealth / nHealthMax
  if 0 < nRatio then
    self:OnUpdateHP(0, nRatio)
  end
end
function WatchGamePlayerInfoUI:UpdatePlayerBuff(Energy)
  local nEnergy = Energy or 0
  if 0 < nEnergy and nEnergy <= 100 then
    self.UIRoot.GridPanel_Help:SetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
  else
    self.UIRoot.GridPanel_Help:SetVisibility(UEnums.ESlateVisibility.Collapsed)
  end
  if 60 <= nEnergy and nEnergy <= 100 then
    self.UIRoot.GridPanel_Power:SetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
  else
    self.UIRoot.GridPanel_Power:SetVisibility(UEnums.ESlateVisibility.Collapsed)
  end
end
function WatchGamePlayerInfoUI:PlayerInfo_UpdateEnergy()
  local uWidget = self.UIRoot
  if not slua.isValid(uWidget) then
    return
  end
  local uPawn = USTExtraUIUtils.GetOwningPlayerPawnOrVehicleDriver(uWidget)
  if slua.isValid(uPawn) and uPawn.bEnableSinkEnergy then
    return
  end
  local nLatestEnergy = UIDataProcessingFunctionLibrary.GetCharacterEnergyValue(uPawn) or 0
  local nOldEnergy = self.CurEnergy
  if nLatestEnergy > nOldEnergy then
    uWidget.HorizontalBox_NormalEnergy:SetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    if slua.isValid(uWidget.EnergyChangeAnim) then
      local nStartTime = nOldEnergy / 100
      local nEndTime = nLatestEnergy / 100
      uWidget:PlayAnimationTo(uWidget.EnergyChangeAnim, nStartTime, nEndTime, 1, 0, 1)
    end
    self.CurEnergy = nLatestEnergy
    self:UpdatePlayerBuff(self.CurEnergy)
  else
    self.CurEnergy = nLatestEnergy
    uWidget.ProgressBar_Power4:SetPercent(math.max(0, math.min(1, (self.CurEnergy - 90) / 10)))
    uWidget.ProgressBar_Power3:SetPercent(math.max(0, math.min(1, (self.CurEnergy - 60) / 30)))
    uWidget.ProgressBar_Power2:SetPercent(math.max(0, math.min(1, (self.CurEnergy - 20) / 40)))
    uWidget.ProgressBar_Power1:SetPercent(math.max(0, math.min(1, self.CurEnergy / 20)))
    if 0 >= self.CurEnergy then
      uWidget.HorizontalBox_NormalEnergy:SetVisibility(UEnums.ESlateVisibility.Hidden)
    end
    self:UpdatePlayerBuff(self.CurEnergy)
  end
end
function WatchGamePlayerInfoUI:PlayerInfo_UpdatePredictHealth()
  local uWidget = self.UIRoot
  if not slua.isValid(uWidget) then
    return
  end
  local uPawn = USTExtraUIUtils.GetOwningPlayerPawnOrVehicleDriver(uWidget)
  if not slua.isValid(uPawn) then
    return
  end
  local nHealthPredict = uPawn.HealthPredict or 0
  self.CurPredictHealth = nHealthPredict
  self:SetPreditTimerFunc(nHealthPredict)
  local nPlayerHealth = 0
  if self.GetPlayerHealth then
    nPlayerHealth = self:GetPlayerHealth() or 0
  end
  local nValueLimit = 0
  if uPawn.GetValueLimitForHealthPredict then
    nValueLimit = uPawn:GetValueLimitForHealthPredict() or 0
  end
  local nTotalAddToHealth = math.min(nHealthPredict + nPlayerHealth, nValueLimit)
  self.TotalAddToHealth = nTotalAddToHealth
  self.PrePredictValue = nHealthPredict
  uWidget.ProgressBar_Addition:SetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
  local nHealthMax = uPawn.HealthMax or 1
  if 0 < nHealthMax then
    local nPercent = math.max(0, math.min(1, nTotalAddToHealth / nHealthMax))
    uWidget.ProgressBar_Addition:SetPercent(nPercent)
  end
  if 0 >= self.CurPredictHealth then
    self.RecoverStartHealth = 0
    self.RecoverCount = 0
    if self.IsMultAddHealth then
      self.NeedPredictWaitForHide = true
      self.WaitAddPredictTime = 6.9
      self.IsMultAddHealth = false
    else
      local uPC = GameplayData.GetPlayerController()
      if slua.isValid(uPC) and uPC.RunOnNextFrameEvent then
        GameplayData.AddSelfPlayerControllerEvent(self, "RunOnNextFrameDelegate", self.HidePredictNextFrame, self)
        uPC:RunOnNextFrameEvent()
      end
    end
  end
end
function WatchGamePlayerInfoUI:SetPreditTimerFunc(PredictValue)
  if self.TimerHandlePredictStayOver then
    self:RemoveGameTimer(self.TimerHandlePredictStayOver)
    self.TimerHandlePredictStayOver = nil
  end
  if PredictValue <= 0 then
    self:PredictStayOverLogic()
  else
    self.TimerHandlePredictStayOver = self:AddGameTimer(7.9, false, function()
      self:PredictStayOverLogic()
    end)
  end
end
function WatchGamePlayerInfoUI:PredictStayOverLogic()
  if self.TimerHandlePredictStayOver then
    self:RemoveGameTimer(self.TimerHandlePredictStayOver)
    self.TimerHandlePredictStayOver = nil
  end
  local uWidget = self.UIRoot
  if uWidget.ProgressBar_Addition:IsVisible() then
    uWidget.ProgressBar_Addition:SetPercent(0)
    uWidget.ProgressBar_Addition:SetVisibility(UEnums.ESlateVisibility.Collapsed)
  end
end
function WatchGamePlayerInfoUI:HidePredictNextFrame()
  self.UIRoot.ProgressBar_Addition:SetVisibility(UEnums.ESlateVisibility.Hidden)
  local uWidget = self.UIRoot
  local uPawn = USTExtraUIUtils.GetOwningPlayerPawnOrVehicleDriver(uWidget)
  if not slua.isValid(uPawn) then
    return
  end
  local uPC
  if uPawn.GetPlayerControllerSafety then
    uPC = uPawn:GetPlayerControllerSafety()
  end
  if slua.isValid(uPC) then
    self:RemoveControlEventByControl(uPC, "RunOnNextFrameDelegate")
  end
  if uPawn.ResetValueLimitForHealthPredict then
    uPawn:ResetValueLimitForHealthPredict()
  end
end
function WatchGamePlayerInfoUI:GetPlayerHealth()
  local uWidget = self.UIRoot
  if not slua.isValid(uWidget) then
    return 0
  end
  local uPawn = USTExtraUIUtils.GetOwningPlayerPawnOrVehicleDriver(uWidget)
  local nHealth = 0
  if slua.isValid(uPawn) then
    nHealth = uPawn.Health or 0
  end
  self.PredictHideBaseHealth = nHealth
  if self.RecoverStartHealth <= 1e-05 then
    return nHealth
  end
  if nHealth < self.RecoverStartHealth then
    self.RecoverStartHealth = nHealth
    self.RecoverCount = 0
    return nHealth
  end
  local nHealthPredict = 0
  if slua.isValid(uPawn) then
    nHealthPredict = uPawn.HealthPredict or 0
  end
  if nHealthPredict > self.PrePredictValue then
    self.RecoverStartHealth = nHealth
    self.RecoverCount = 0
    return nHealth
  end
  self.PredictStepValue = self.PrePredictValue - nHealthPredict
  self.RecoverCount = self.RecoverCount + 1
  local nSimulated = self.RecoverCount * self.PredictStepValue + self.RecoverStartHealth
  if nHealth > nSimulated then
    self.RecoverStartHealth = nHealth
    self.RecoverCount = 0
    return nHealth
  end
  return nSimulated
end
function WatchGamePlayerInfoUI:SetInfoWeapon()
  for InstID, ModWeapon in pairs(self.ModWeaponUI) do
    local WeaponUI = self.ModWeaponUI[InstID]
    if WeaponUI then
      if self:HasWeapon(InstID) then
        if WeaponUI.ModWeaponIcon then
          WeaponUI.ModWeaponIcon:Collapsed()
        end
        if WeaponUI.ModWeaponLabel then
          WeaponUI.ModWeaponLabel:Collapsed()
        end
      else
        if WeaponUI.ModWeaponIcon then
          WeaponUI.ModWeaponIcon:Close()
          WeaponUI.ModWeaponIcon = nil
        end
        if WeaponUI.ModWeaponLabel then
          WeaponUI.ModWeaponLabel:Close()
          WeaponUI.ModWeaponLabel = nil
        end
      end
    end
  end
  if self:IsModWeaponUI() then
    print(bWriteLog and "WatchGamePlayerInfoUI:IsModWeaponUI true")
    return
  elseif self:IsMEnsureWeapon() then
    print(bWriteLog and "WatchGamePlayerInfoUI:IsMEnsureWeapon true")
    return
  else
    print(bWriteLog and "WatchGamePlayerInfoUI:IsModWeaponUI false")
  end
  self.UIRoot.Image_WeaponIcon:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
  local uWidget = self.UIRoot
  local uPawn = USTExtraUIUtils.GetOwningPlayerPawnOrVehicleDriver(uWidget)
  if not slua.isValid(uPawn) then
    return
  end
  if uPawn:HasState(EPawnState.ControlUnmannedVehicle) then
    uWidget.Image_WeaponIcon:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
    uWidget.Image_ThrowIcon:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
    return
  end
  local WeaponManager = uPawn:GetWeaponManager()
  if not slua.isValid(WeaponManager) then
    return
  end
  local CurPropSlot = WeaponManager:GetCurrentUsingPropSlot()
  if CurPropSlot == ESurviveWeaponPropSlot.SWPS_None then
    local bDriveVehicle = uPawn:HasState(EPawnState.DriveVehicle)
    if bDriveVehicle then
      local Socket = WeaponManager.LastUseNoneGrenadeLogicSlot
      local Slot = WeaponManager:GetPropSlotByLogicSocket(Socket)
      local LastWeapon = WeaponManager:GetInventoryWeaponByPropSlot(Slot)
      self:ShowImageIcon(uWidget.Image_WeaponIcon)
      if slua.isValid(LastWeapon) then
        local WeaponDefineID = LastWeapon:GetItemDefineID()
        local nTypeID = WeaponDefineID.TypeSpecificID
        local sIconPath = self:GetItemIconPath(nTypeID)
        self:SetImgByIcon(uWidget.Image_WeaponIcon, sIconPath)
      else
        self:SetImgByIcon(uWidget.Image_WeaponIcon, "/Game/Arts/UI/TableIcons/WeaponIcons/Icon256x128_W/Icon_WEP_Fist_W.Icon_WEP_Fist_W")
      end
    else
      self:ShowImageIcon(uWidget.Image_WeaponIcon)
      self:SetImgByIcon(uWidget.Image_WeaponIcon, "/Game/Arts/UI/TableIcons/WeaponIcons/Icon256x128_W/Icon_WEP_Fist_W.Icon_WEP_Fist_W")
    end
  elseif CurPropSlot == ESurviveWeaponPropSlot.SWPS_HandProp then
    local Grenade = WeaponManager:GetInventoryWeaponByPropSlot(ESurviveWeaponPropSlot.SWPS_HandProp)
    self:ShowImageIcon(uWidget.Image_ThrowIcon)
    if slua.isValid(Grenade) and Grenade.GetItemDefineID then
      local nGrenadeTypeID = Grenade:GetItemDefineID().TypeSpecificID
      if nGrenadeTypeID ~= 0 then
        local SkillIconConfig = UAESkillManagerUtils.GetGrenadeSkillIconConfig(nGrenadeTypeID)
        self:SetImgByIcon(uWidget.Image_ThrowIcon, SkillIconConfig.IconPath)
      end
    end
  elseif CurPropSlot == ESurviveWeaponPropSlot.SWPS_VehicleWeapon then
    local VehicleWeapon = WeaponManager:GetCurrentUsingWeapon()
    if slua.isValid(VehicleWeapon) then
      local WeaponDefineID = VehicleWeapon:GetItemDefineID()
      local nWeaponTypeID = WeaponDefineID.TypeSpecificID
      local sWeaponIconPath = self:GetItemIconPath(nWeaponTypeID)
      if sWeaponIconPath and sWeaponIconPath ~= "" then
        self:SetImgByIcon(uWidget.Image_WeaponIcon, sWeaponIconPath)
      end
    end
  elseif CurPropSlot == ESurviveWeaponPropSlot.SWPS_MainShootWeapon1 or CurPropSlot == ESurviveWeaponPropSlot.SWPS_MainShootWeapon2 or CurPropSlot == ESurviveWeaponPropSlot.SWPS_SubShootWeapon or CurPropSlot == ESurviveWeaponPropSlot.SWPS_MeleeWeapon then
    self:ShowImageIcon(uWidget.Image_WeaponIcon)
    local Weapon = WeaponManager:GetInventoryWeaponByPropSlot(CurPropSlot)
    if slua.isValid(Weapon) then
      local WeaponDefineID = Weapon:GetItemDefineID()
      local nWeaponTypeID = WeaponDefineID.TypeSpecificID
      local sWeaponIconPath = self:GetItemIconPath(nWeaponTypeID)
      if sWeaponIconPath and sWeaponIconPath ~= "" then
        self:SetImgByIcon(uWidget.Image_WeaponIcon, sWeaponIconPath)
      end
    end
  end
  local bDriveVehicle2 = uPawn:HasState(EPawnState.DriveVehicle)
  if bDriveVehicle2 and self.FixWeaponIcon then
    local Socket2 = WeaponManager.LastUseNoneGrenadeLogicSlot
    local Slot2 = WeaponManager:GetPropSlotByLogicSocket(Socket2)
    local LastWeapon2 = WeaponManager:GetInventoryWeaponByPropSlot(Slot2)
    if slua.isValid(LastWeapon2) then
      local WeaponDefineID2 = LastWeapon2:GetItemDefineID()
      local nTypeID2 = WeaponDefineID2.TypeSpecificID
      local sIconPath2 = self:GetItemIconPath(nTypeID2)
      if sIconPath2 and sIconPath2 ~= "" then
        self:SetImgByIcon(uWidget.Image_WeaponIcon, sIconPath2)
      end
    end
  end
end
function WatchGamePlayerInfoUI:GetItemIconPath(TypeSpecificID)
  if not TypeSpecificID or TypeSpecificID <= 0 then
    return nil
  end
  local ItemData = CDataTable.GetTableData("Item", tostring(TypeSpecificID))
  if ItemData and ItemData.ItemWhiteIcon and ItemData.ItemWhiteIcon ~= "" then
    return tostring(ItemData.ItemWhiteIcon)
  end
  return nil
end
function WatchGamePlayerInfoUI:SetImgByIcon(TargetImage, IconPath)
  if slua.isValid(TargetImage) and IconPath and IconPath ~= "" then
    TargetImage:SetBrushFromPathAsync(IconPath, false)
  end
end
function WatchGamePlayerInfoUI:SetInfoArmor()
  local uWidget = self.UIRoot
  local uPawn = USTExtraUIUtils.GetOwningPlayerPawnOrVehicleDriver(uWidget)
  if not slua.isValid(uPawn) then
    return
  end
  local WeaponManager = uPawn:GetWeaponManager()
  if not slua.isValid(WeaponManager) then
    return
  end
  local CurPropSlot = WeaponManager:GetCurrentUsingPropSlot()
  local ArmorNum = -1
  local ArmorNumText = ""
  if CurPropSlot == ESurviveWeaponPropSlot.SWPS_MainShootWeapon1 or CurPropSlot == ESurviveWeaponPropSlot.SWPS_MainShootWeapon2 or CurPropSlot == ESurviveWeaponPropSlot.SWPS_SubShootWeapon then
    local Weapon = WeaponManager:GetInventoryWeaponByPropSlot(CurPropSlot)
    if slua.isValid(Weapon) and Weapon.GetCurrentBulletNumInClip then
      local nArmorNum = Weapon:GetCurrentBulletNumInClip(EBulletClipType.BCT_BASE)
      ArmorNum = nArmorNum
      local bInfinite = false
      if Weapon.GetClipHasInfiniteBulletsFromEntity then
        bInfinite = Weapon:GetClipHasInfiniteBulletsFromEntity()
      end
      if bInfinite then
        ArmorNumText = "?"
      else
        ArmorNumText = tostring(nArmorNum)
      end
    end
  elseif CurPropSlot == ESurviveWeaponPropSlot.SWPS_HandProp then
    local Weapon = WeaponManager:GetInventoryWeaponByPropSlot(CurPropSlot)
    if slua.isValid(Weapon) and Weapon.GetItemDefineID then
      local ItemDefineID = Weapon:GetItemDefineID()
      if ItemDefineID and ItemDefineID.TypeSpecificID and ItemDefineID.TypeSpecificID > 0 then
        local nTypeSpecificID = ItemDefineID.TypeSpecificID
        local uPC = GameplayData.GetPlayerController()
        if slua.isValid(uPC) and uPC.GetMultiItemFromItemList then
          local nTypeSpecificIDArray = slua.Array(UEnums.EPropertyClass.Int)
          nTypeSpecificIDArray:Add(nTypeSpecificID)
          local tBattleItemArray = uPC:GetMultiItemFromItemList(nTypeSpecificIDArray)
          if tBattleItemArray and tBattleItemArray.Num then
            do
              local ok, nNum = pcall(function()
                return tBattleItemArray:Num()
              end)
              if ok and nNum and 0 < nNum then
                local okGet, tBattleItem = pcall(function()
                  return tBattleItemArray:Get(0)
                end)
                if okGet and tBattleItem and tBattleItem.AdditionalData then
                  local nAdditionalData = tBattleItem.AdditionalData
                  ArmorNum = nAdditionalData
                  ArmorNumText = tostring(nAdditionalData)
                end
              end
            end
          end
        end
      end
    end
  end
  if 0 <= ArmorNum then
    uWidget.TextBlock_BulletNum:SetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    uWidget.TextBlock_BulletNum:SetText(ArmorNumText or "")
  else
    uWidget.TextBlock_BulletNum:SetVisibility(UEnums.ESlateVisibility.Collapsed)
  end
  local uPlayerController = GameplayData.GetPlayerController()
  local uPlayerCharacter = slua.isValid(uPlayerController) and uPlayerController:GetCurPlayerCharacter()
  local uWeapon = slua.isValid(uPlayerCharacter) and uPlayerCharacter:GetCurrentShootWeapon()
  if slua.isValid(uWeapon) and uWeapon:IsShowBulletRemainPercentForUI() then
    uWidget.WidgetSwitcher_0:SetActiveWidgetIndex(1)
    uWidget.ProgressBar_0:SetPercent(uWeapon:GetCurBulletRemainPercent())
  else
    uWidget.WidgetSwitcher_0:SetActiveWidgetIndex(0)
  end
end
function WatchGamePlayerInfoUI:OnPoseChanged(PoseState, bUpdateToCurrentState)
  print(bWriteLog and string.format("WatchGamePlayerInfoUI:OnPoseChanged - PoseState %s bUpdateToCurrentState %s", tostring(PoseState), tostring(bUpdateToCurrentState)))
  local uWidget = self.UIRoot
  local nRawPoseState = PoseState
  local uPC = GameplayData.GetPlayerController()
  if not slua.isValid(uPC) or not uPC.GetCurPawn then
    return
  end
  local uPawn = uPC:GetCurPawn()
  if not slua.isValid(uPawn) then
    return
  end
  if bUpdateToCurrentState and uPawn.PoseState then
    nRawPoseState = uPawn.PoseState
  end
  local nPoseType
  if uPawn.ConvertCharacterPoseStateToPoseType then
    nPoseType = uPawn:ConvertCharacterPoseStateToPoseType(nRawPoseState)
  end
  if nPoseType == nil then
    return
  end
  if nPoseType == ECharacterPoseType.ECharPose_Stand then
    uWidget.WidgetSwitcher_State:SetActiveWidgetIndex(1)
  elseif nPoseType == ECharacterPoseType.ECharPose_Crouch then
    uWidget.WidgetSwitcher_State:SetActiveWidgetIndex(0)
  elseif nPoseType == ECharacterPoseType.ECharPose_Prone then
    uWidget.WidgetSwitcher_State:SetActiveWidgetIndex(2)
  end
end
function WatchGamePlayerInfoUI:HideWeaponIcon()
  self.UIRoot.Image_ThrowIcon:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  self.UIRoot.Image_WeaponIcon:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
end
function WatchGamePlayerInfoUI:ShowImageIcon(uWidget)
  print(bWriteLog and "WatchGamePlayerInfoUI:ShowImageIcon", uWidget)
  if self.UIRoot.Image_ThrowIcon == uWidget then
    self.UIRoot.Image_ThrowIcon:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    self.UIRoot.Image_WeaponIcon:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  elseif self.UIRoot.Image_WeaponIcon == uWidget then
    self.UIRoot.Image_WeaponIcon:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    self.UIRoot.Image_ThrowIcon:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  end
end
function WatchGamePlayerInfoUI:Localization()
  local sText = LocUtil.GetLocalizeResStr(25259)
  self.UIRoot.TextBlock_VideoInspection:SetText(sText)
end
function WatchGamePlayerInfoUI:Event_OnPlayerControllerRespawned()
  print(bWriteLog and "WatchGamePlayerInfoUI:Event_OnPlayerControllerRespawned")
  self:UpdateHP()
end
function WatchGamePlayerInfoUI:Event_OnNearDeathOrRescuing(bIsNearDeath, bIsRescuingOther)
  print(bWriteLog and string.format("WatchGamePlayerInfoUI:Event_OnNearDeathOrRescuing - bIsNearDeath %s bIsRescuingOther %s", tostring(bIsNearDeath), tostring(bIsRescuingOther)))
  self:UpdateHP()
end
function WatchGamePlayerInfoUI:OnViewTargetPoseChanged(LastPose, NewPose)
  print(bWriteLog and string.format("WatchGamePlayerInfoUI:OnViewTargetPoseChanged - LastPose %s NewPose %s", tostring(LastPose), tostring(NewPose)))
  self:OnPoseChanged(NewPose, false)
end
function WatchGamePlayerInfoUI:UISettingWeapon()
  print(bWriteLog and "WatchGamePlayerInfoUI:UISettingWeapon - refresh weapon icon + ammo/armor info")
  self:SetInfoWeapon()
  self:SetInfoArmor()
end
function WatchGamePlayerInfoUI:UISettingBullet()
  print(bWriteLog and "WatchGamePlayerInfoUI:UISettingBullet")
  self:SetInfoArmor()
end
function WatchGamePlayerInfoUI:UpdatePlayerInfo()
  print(bWriteLog and "WatchGamePlayerInfoUI:UpdatePlayerInfo - reset weapon/ammo/HP/pose after ViewTarget change")
  self:SetInfoWeapon()
  self:SetInfoArmor()
  self:UpdateHP()
  self:OnPoseChanged(ESTEPoseState.Stand, true)
end
function WatchGamePlayerInfoUI:OnReplayUIInit(_, _, GameReplayType)
  local EGameReplayType = import("EGameReplayType")
  print(bWriteLog and "WatchGamePlayerInfoUI:OnReplayUIInit - GameReplayType", GameReplayType)
  if EGameReplayType.EGameReplayType_DeathPlayback == GameReplayType then
    self:TryUpdateCurPawnHP()
  end
end
function WatchGamePlayerInfoUI:OnRecoveryStart()
  print(bWriteLog and "WatchGamePlayerInfoUI:OnRecoveryStart")
  local PC = GameplayData.GetPlayerController()
  if not slua.isValid(PC) or not PC.GetCurPawn then
    return
  end
  local PlayerCharacter = PC:GetCurPawn()
  if not slua.isValid(PlayerCharacter) then
    return
  end
  self.IsMultAddHealth = self.RecoverCount == 0
  self.RecoverStartHealth = PlayerCharacter.Health or 0
  self.RecoverCount = 0
end
function WatchGamePlayerInfoUI:IsCustomUIDataValid()
  return false
end
function WatchGamePlayerInfoUI:OnTickCheck(DeltaTime)
  if not self.NeedPredictWaitForHide then
    return
  end
  self.WaitAddPredictTime = (self.WaitAddPredictTime or 0) - DeltaTime
  local uPC = GameplayData.GetPlayerController()
  if not slua.isValid(uPC) or not uPC.GetCurPawn then
    return
  end
  local PlayerCharacter = uPC:GetCurPawn()
  if not slua.isValid(PlayerCharacter) then
    return
  end
  local Health = PlayerCharacter.Health or 0
  if Health >= (self.TotalAddToHealth or 0) - 1e-05 or self.WaitAddPredictTime <= 0 or Health < (self.PredictHideBaseHealth or 0) then
    self.NeedPredictWaitForHide = false
    if PlayerCharacter.ResetValueLimitForHealthPredict then
      PlayerCharacter:ResetValueLimitForHealthPredict()
    end
    self.UIRoot.ProgressBar_Addition:SetVisibility(UEnums.ESlateVisibility.Hidden)
  end
end
function WatchGamePlayerInfoUI:IsMEnsureWeapon()
  local PlayerController = GameplayData.GetPlayerController()
  local PlayerCharacter = slua.isValid(PlayerController) and PlayerController:GetCurPlayerCharacter()
  if not slua.isValid(PlayerCharacter) then
    return false
  end
  if PlayerCharacter:GetMEnsure() and PlayerCharacter.GetMEnsureWeaponIconPath then
    local IconPath = PlayerCharacter:GetMEnsureWeaponIconPath()
    self.UIRoot.Image_WeaponIcon:SetBrushFromSoftObjectPathAsync(IconPath, false)
    self.UIRoot.Image_WeaponIcon:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    return true
  end
  return false
end
function WatchGamePlayerInfoUI:IsModWeaponUI()
  local PlayerController = GameplayData.GetPlayerController()
  local PlayerCharacter = slua.isValid(PlayerController) and PlayerController:GetCurPlayerCharacter()
  if not slua.isValid(PlayerCharacter) then
    return false
  end
  if PlayerCharacter:HasState(EPawnState.ControlUnmannedVehicle) then
    return false
  end
  local Weapon = PlayerCharacter:GetCurrentWeapon()
  if not slua.isValid(Weapon) and PlayerCharacter:HasState(EPawnState.DriveVehicle) then
    local WeaponManager = PlayerCharacter:GetWeaponManager()
    local Socket = WeaponManager.LastUseNoneGrenadeLogicSlot
    local Slot = WeaponManager:GetPropSlotByLogicSocket(Socket)
    Weapon = WeaponManager:GetInventoryWeaponByPropSlot(Slot)
  end
  if not slua.isValid(Weapon) then
    return false
  end
  local WeaponDefineID = Weapon:GetItemDefineID()
  local ItemID = WeaponDefineID.TypeSpecificID
  local ModWeaponConfig = GamePlayTools.GetCurrentConfig("ModWeaponConfig")
  if ModWeaponConfig and ModWeaponConfig[ItemID] and (ModWeaponConfig[ItemID].LabelUIConfig or ModWeaponConfig[ItemID].WeaponSlotUI) then
    print(bWriteLog and string.format("WatchGamePlayerInfoUI:IsModWeaponUI - ItemID %s is Mod Weapon", tostring(ItemID)))
    self:UpdateModWeaponUI(ModWeaponConfig[ItemID], WeaponDefineID.InstanceID, Weapon)
    return true
  end
  return false
end
function WatchGamePlayerInfoUI:HasWeapon(InstID)
  local PlayerController = GameplayData.GetPlayerController()
  local PlayerCharacter = slua.isValid(PlayerController) and PlayerController:GetCurPlayerCharacter()
  if not slua.isValid(PlayerCharacter) then
    return false
  end
  local WeaponManager = PlayerCharacter:GetWeaponManager()
  if not slua.isValid(WeaponManager) then
    return false
  end
  local WeaponList = WeaponManager:GetAllInventoryWeaponList(false)
  if not WeaponList or WeaponList:Num() <= 0 then
    return false
  end
  for _, ItemData in pairs(WeaponList) do
    if slua.isValid(ItemData) then
      local DefineID = ItemData:GetItemDefineID()
      if DefineID.InstanceID == InstID then
        return true
      end
    end
  end
  return false
end
function WatchGamePlayerInfoUI:UpdateModWeaponUI(WeaponConfig, InstID, Weapon)
  print(bWriteLog and "WatchGamePlayerInfoUI:UpdateModWeaponUI")
  if not self.ModWeaponUI[InstID] then
    self.ModWeaponUI[InstID] = {ModWeaponIcon = nil, ModWeaponLabel = nil}
  end
  local ModWeapon = self.ModWeaponUI[InstID]
  local ModWeaponUI = ModWeapon.ModWeaponIcon
  local ModWeaponLabel = ModWeapon.ModWeaponLabel
  if ModWeaponUI then
    print(bWriteLog and "WatchGamePlayerInfoUI:UpdateModWeaponUI - WeaponConfig.WeaponSlotUI")
    ModWeaponUI:SelfHitTestInvisible()
    if not WeaponConfig.bShowWeaponSlotProfileImg then
      self:HideWeaponIcon()
    end
  else
    local WeaponIconConfig = WeaponConfig.WeaponSlotUI
    local WeaponSlotCanvas = self.UIRoot.CanvasPanel_WeaponSlot
    if WeaponIconConfig and WeaponSlotCanvas then
      local IconConfig = UIManager.UI_Config_InGame[WeaponIconConfig]
      if IconConfig then
        print(bWriteLog and "WatchGamePlayerInfoUI:UpdateModWeaponUI - WeaponConfig.WeaponSlotUI")
        ModWeaponUI = self:CreateChildWindow(WeaponSlotCanvas, IconConfig)
        if not ModWeaponUI then
          return
        end
        if not WeaponConfig.bShowWeaponSlotProfileImg then
          self:HideWeaponIcon()
        end
        self.ModWeaponUI[InstID].ModWeaponIcon = ModWeaponUI
        if ModWeaponUI.UpdateCurrentWeapon then
          ModWeaponUI:UpdateCurrentWeapon(Weapon)
        end
      end
    else
      print(bWriteLog and "WatchGamePlayerInfoUI:UpdateModWeaponUI - no WeaponConfig.WeaponSlotUI")
      self.UIRoot.Image_WeaponIcon:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
      self:SetInfoWeapon()
    end
  end
  if ModWeaponLabel then
    print(bWriteLog and "WatchGamePlayerInfoUI:UpdateModWeaponUI - WeaponConfig.ModWeaponLabel")
    ModWeaponLabel:SelfHitTestInvisible()
  else
    local LabelUIConfig = WeaponConfig.LabelUIConfig
    local ModLabelCanvas = self.UIRoot.CanvasPanel_WeaponSlot
    if LabelUIConfig and ModLabelCanvas then
      local LabelConfig = UIManager.UI_Config_InGame[LabelUIConfig]
      if LabelConfig then
        print(bWriteLog and "WatchGamePlayerInfoUI:UpdateModWeaponUI - WeaponConfig.ModWeaponLabel")
        ModWeaponLabel = self:CreateChildWindow(ModLabelCanvas, LabelConfig, 1)
        self.ModWeaponUI[InstID].ModWeaponLabel = ModWeaponLabel
      end
    end
  end
end
function WatchGamePlayerInfoUI:ForceUpdateHP()
  local RatioHP = 1
  local PC = GameplayData.GetPlayerController()
  if slua.isValid(PC) then
    local PlayerCharacter = PC:GetCurPawn()
    print(bWriteLog and "WatchGamePlayerInfoUI:ForceUpdateHP - PlayerCharacter", PlayerCharacter)
    if slua.isValid(PlayerCharacter) and PlayerCharacter.Health and PlayerCharacter.HealthMax then
      local Health = PlayerCharacter.Health
      local HealthMax = PlayerCharacter.HealthMax
      RatioHP = Health / (HealthMax + 0.0001)
      print(bWriteLog and "WatchGamePlayerInfoUI:ForceUpdateHP - Health, HealthMax, RatioHP", Health, HealthMax, RatioHP)
      if 0.1 < RatioHP then
        self:OnUpdateHP(0, RatioHP)
      end
    end
  end
end
function WatchGamePlayerInfoUI:OnOBPlayerBulletChanged()
  self:SetInfoArmor()
end
function WatchGamePlayerInfoUI:OnOBPlayerWeaponChanged()
  print(bWriteLog and "WatchGamePlayerInfoUI:OnOBPlayerWeaponChanged")
  self:SetInfoWeapon()
  self:SetInfoArmor()
end
function WatchGamePlayerInfoUI:OnCharacterStatesChange()
  local PlayerController = GameplayData.GetPlayerController()
  if not slua.isValid(PlayerController) then
    return
  end
  local PlayerCharacter = PlayerController:GetCurPlayerCharacter()
  if not slua.isValid(PlayerCharacter) or PlayerCharacter.HasState == nil then
    return
  end
  local bCurrentbDriveVehicle = PlayerCharacter:HasState(EPawnState.DriveVehicle)
  if self.bDriveVehicle ~= bCurrentbDriveVehicle then
    self.bDriveVehicle = bCurrentbDriveVehicle
    if self.bDriveVehicle then
      self:SetInfoWeapon()
    end
  end
end
function WatchGamePlayerInfoUI:OnSpectatorChange()
  print(bWriteLog and "WatchGamePlayerInfoUI:OnSpectatorChange")
  self:TryUpdateCurPawnHP()
  self:OnOBPlayerPoseChanged()
end
function WatchGamePlayerInfoUI:OnOBPlayerPoseChanged()
  print(bWriteLog and "WatchGamePlayerInfoUI:OnOBPlayerPoseChanged")
  self:OnPoseChanged(ESTEPoseState.Stand, false)
end
function WatchGamePlayerInfoUI:Close_WeaponSlot()
  for WeaponID, ModWeapon in pairs(self.ModWeaponUI) do
    local WeaponUI = self.ModWeaponUI[WeaponID]
    if WeaponUI then
      if WeaponUI.ModWeaponIcon then
        WeaponUI.ModWeaponIcon:Close()
        WeaponUI.ModWeaponIcon = nil
      end
      if WeaponUI.ModWeaponLabel then
        WeaponUI.ModWeaponLabel:Close()
        WeaponUI.ModWeaponLabel = nil
      end
    end
  end
  self.ModWeaponUI = nil
end
function WatchGamePlayerInfoUI:OnClose()
  print(bWriteLog and "WatchGamePlayerInfoUI:OnClose")
  if self.TimerHandleForceUpdateHP then
    self:RemoveGameTimer(self.TimerHandleForceUpdateHP)
    self.TimerHandleForceUpdateHP = nil
  end
  self:Close_WeaponSlot()
  if self.TimerHandlePredictStayOver then
    self:RemoveGameTimer(self.TimerHandlePredictStayOver)
    self.TimerHandlePredictStayOver = nil
  end
  if self.TimerHandleTickCheck then
    self:RemoveGameTimer(self.TimerHandleTickCheck)
    self.TimerHandleTickCheck = nil
  end
  WatchGamePlayerInfoUI.__super.OnClose(self)
end
local class = require("class")
local UIBase = require("client.slua_ui_framework.base")
return class(UIBase, nil, WatchGamePlayerInfoUI)
