local NosferatuFeature = {
  ServerRPC = {},
  ClientRPC = {},
  MulticastRPC = {}
}
local UTSkillEventType = import("UTSkillEventType")
local UGameplayStatics = import("GameplayStatics")
local ESTEPoseState = import("ESTEPoseState")
local EMovementMode = import("EMovementMode")
local EAttrModifyRefType = import("EAttrModifyRefType")
local EPawnState = import("EPawnState")
local EActorHiddenMask = import("EActorHiddenMask")
local EParachuteState = import("EParachuteState")
local ECameraDataType = import("ECameraDataType")
local GameplayData = require("GameLua.GameCore.Data.GameplayData")
local GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
local BloodMoveAudio1 = "/Game/Library/Res/Hero/Nosferatu/WwiseEvent/Halloween6_Zombie189_460/Play_Halloween6_Zombie189_Skill_BloodMove_Local.Play_Halloween6_Zombie189_Skill_BloodMove_Local"
local BloodMoveAudio2 = "/Game/Library/Res/Hero/Nosferatu/WwiseEvent/Halloween6_Zombie189_460/Play_Halloween6_Zombie189_Skill_BloodMove_Run_Remote.Play_Halloween6_Zombie189_Skill_BloodMove_Run_Remote"
local BloodMoveAudio3 = "/Game/Library/Res/Hero/Nosferatu/WwiseEvent/Halloween6_Zombie189_460/Stop_Halloween6_Zombie189_Skill_BloodMove_Local.Stop_Halloween6_Zombie189_Skill_BloodMove_Local"
local BloodMoveAudio4 = "/Game/Library/Res/Hero/Nosferatu/WwiseEvent/Halloween6_Zombie189_460/Stop_Halloween6_Zombie189_Skill_BloodMove_Run_Remote.Stop_Halloween6_Zombie189_Skill_BloodMove_Run_Remote"
local SPRINT_SPEED_RATE_ADD = 0.72
local RUN_SPEED_RATE_ADD = 0.46
local HIT_SLOW_BUFF_ID = 4605004
local NOSFERATU_CIRCLE_PAIN_RATE = 8
local DEFAULT_CIRCLE_PAIN_RATE = 1
local MeleeComboIDs = {4605003}
local TRANSFORM_SKILL_ID = 4605001
local NOSFERATU_SKILLS = {4605002, 4605006}
local SWIM_EXIT_UI_CHECK_DELAY = 0.3
local ATTACK_UI_CONFIG_NAMES = {
  "NosferatuAttackLeftUI",
  "NosferatuAttackRightUI"
}
local IsSwimming = function(uCharacter)
  if not slua.isValid(uCharacter) then
    return false
  end
  local uMoveComp = uCharacter.STCharacterMovement
  if not slua.isValid(uMoveComp) then
    uMoveComp = uCharacter.CharacterMovement
  end
  if not slua.isValid(uMoveComp) then
    return false
  end
  return uMoveComp.MovementMode == EMovementMode.MOVE_Swimming
end
local TAG_DISABLE_CHECK_FALLING_DISTANCE = "DisableCheckFallingDistance"
local RemoveActorTag = function(uCharacter, TagName)
  if not slua.isValid(uCharacter) or not uCharacter.Tags then
    return
  end
  for i = uCharacter.Tags:Num() - 1, 0, -1 do
    if uCharacter.Tags:Get(i) == TagName then
      uCharacter.Tags:Remove(i)
    end
  end
end
local TLOG_ID_NOSFERATU_TRANSFORM_DURATION = 2460
function NosferatuFeature:GetCharacter()
  if self and self.Owner then
    return self.Owner.Object
  end
  return nil
end
function NosferatuFeature.IsNosferatu(uCharacter)
  if not slua.isValid(uCharacter) then
    return false
  end
  local uHeroPropFeature = uCharacter.HeroPropFeature
  if not uHeroPropFeature then
    return false
  end
  return uHeroPropFeature:GetCurrentHeroID() == UEnums.HeroID.Nosferatu
end
function NosferatuFeature:_PostConstruct()
  NosferatuFeature.__super._PostConstruct(self)
  if self:HasAuthority() then
    self.bInvincible = false
  end
  self.bSwimSkillsDisabled = false
  self.SwimDisabledSkillSlots = nil
  self.bArrestSkillsDisabled = false
  self.ArrestStateTimer = nil
  self.bBloodPoolHidden = false
  self.bBloodPoolVisualApplied = false
end
function NosferatuFeature:ReceiveBeginPlay()
  NosferatuFeature.__super.ReceiveBeginPlay(self)
  print(bWriteLog and "NosferatuFeature:ReceiveBeginPlay")
  local uCharacter = self:GetCharacter()
  if not slua.isValid(uCharacter) then
    return
  end
  self:RefreshSpeedRateModifier()
  self:AddGameTimer(0, false, function()
    self:RefreshSpeedRateModifier()
  end)
  if uCharacter:HasAuthority() then
    self:AddControlEvent(uCharacter, "OnHandleSkillEndDelegate", self.OnHandleSkillEnd, self)
    self:AddControlEvent(uCharacter, "MovementModeChangedDelegate", self.HandleOnMovementModeChanged, self)
    self:AddControlEvent(uCharacter, "OnTakeDamageDynamicDelegate", self.HandleOnTakeDamage, self)
  end
  if NosferatuFeature.IsNosferatu(uCharacter) and uCharacter:IsLocallyControlled() then
    self:ProcessUI(true)
  end
  if Client then
    self:AddControlEvent(uCharacter, "OnParachuteStateChanged", self.HandleOnParachuteStateChanged, self)
    self:AddControlEvent(uCharacter, "MovementModeChangedDelegate", self.HandleClientMovementModeChanged, self)
  end
end
function NosferatuFeature:HandleAvatarAllMeshLoaded()
  if not Client then
    return
  end
  local uCharacter = self:GetCharacter()
  if not slua.isValid(uCharacter) or not slua.isValid(uCharacter.Mesh) then
    return
  end
  if not NosferatuFeature.IsNosferatu(uCharacter) then
    return
  end
  if uCharacter:IsLocallyControlled() then
    print(bWriteLog and "NosferatuFeature:HandleAvatarAllMeshLoaded AdjustSkinnedMinLODForPerformance 1 1 0")
    Game:AdjustSkinnedMinLODForPerformance(uCharacter.Mesh, 1, 1, 0)
  else
    print(bWriteLog and "NosferatuFeature:HandleAvatarAllMeshLoaded AdjustSkinnedMinLODForPerformance 2 1 0")
    Game:AdjustSkinnedMinLODForPerformance(uCharacter.Mesh, 2, 1, 0)
  end
end
function NosferatuFeature:HandleOnParachuteStateChanged(LastParachuteState, NewParachuteState)
  if NewParachuteState ~= EParachuteState.PS_None or LastParachuteState == EParachuteState.PS_None then
    return
  end
  local uCharacter = self:GetCharacter()
  if not slua.isValid(uCharacter) then
    return
  end
  if not NosferatuFeature.IsNosferatu(uCharacter) then
    return
  end
  print(bWriteLog and string.format("NosferatuFeature:HandleOnParachuteStateChanged parachute end (%s -> %s), reset transform camera", tostring(LastParachuteState), tostring(NewParachuteState)))
  self:ApplyTransformCameraData()
end
function NosferatuFeature:ApplyTransformCameraData()
  if not Client then
    return
  end
  local uCharacter = self:GetCharacter()
  if not slua.isValid(uCharacter) then
    return
  end
  local uLocalChar = GameplayData.GetPlayerCharacter()
  if not slua.isValid(uLocalChar) or uLocalChar ~= uCharacter then
    return
  end
  local uSpringArm = uCharacter.CustomSpringArm
  if not slua.isValid(uSpringArm) then
    print(bWriteLog and "NosferatuFeature:ApplyTransformCameraData CustomSpringArm invalid, skip")
    return
  end
  local Config = GamePlayTools.GetCurrentConfig("CommonFightTransformConfig")
  local ConfigData = Config and Config.CommonransformConfig and Config.CommonransformConfig[UEnums.HeroID.Nosferatu]
  if not ConfigData or not ConfigData.SpringArmLength then
    print(bWriteLog and "NosferatuFeature:ApplyTransformCameraData no SpringArmLength config, skip")
    return
  end
  local uCameraData = uSpringArm.PlayerTransformCameraData
  uCameraData.SpringArmLength = ConfigData.SpringArmLength
  uCameraData.SocketOffset = ConfigData.SocketOffset or FVector(0, 0, 0)
  uCameraData.TargetOffset = ConfigData.TargetOffset or FVector(0, 0, 0)
  uSpringArm.PlayerTransformCameraData = uCameraData
  uSpringArm:SetCameraDataEnable(ECameraDataType.ECameraDataType_Transform, false)
  uSpringArm:SetCameraDataEnable(ECameraDataType.ECameraDataType_Transform, true)
  print(bWriteLog and string.format("NosferatuFeature:ApplyTransformCameraData SpringArmLength=%s", tostring(ConfigData.SpringArmLength)))
end
function NosferatuFeature:OnHandleSkillEnd(uSkillCharacter, StopReason, SkillID)
  if SkillID ~= TRANSFORM_SKILL_ID then
    return
  end
  local uCharacter = self:GetCharacter()
  if not slua.isValid(uCharacter) then
    return
  end
  if uCharacter:HasAuthority() and not NosferatuFeature.IsNosferatu(uCharacter) then
    print(bWriteLog and string.format("NosferatuFeature:OnHandleSkillEnd transform skill %d ended but character is NOT Nosferatu, StopReason=%s, kill it", SkillID, tostring(StopReason)))
    local uNearDeathComp = uCharacter.NearDeatchComponent
    if slua.isValid(uNearDeathComp) then
      uNearDeathComp:TriggerGotoDieExplictly(uCharacter.Object)
    end
    local PlayerKey = uCharacter.PlayerKey
    if PlayerKey then
      Game:UIShowImageTips(PlayerKey, 46014014)
    end
  end
  self:SetBloodPoolHidden(false)
end
function NosferatuFeature:ReceiveEndPlay(EndPlayReason)
  print(bWriteLog and "NosferatuFeature:ReceiveEndPlay")
  self:RemoveSpeedRateModifier()
  if self.ArrestStateTimer then
    self:RemoveGameTimer(self.ArrestStateTimer)
    self.ArrestStateTimer = nil
  end
  NosferatuFeature.__super.ReceiveEndPlay(self, EndPlayReason)
end
function NosferatuFeature:OnPlayerPoseChange(LastPoseState, NewPoseState)
  if NewPoseState ~= ESTEPoseState.Sprint and LastPoseState ~= ESTEPoseState.Sprint then
    return
  end
  self:RefreshSpeedRateModifier()
end
function NosferatuFeature:HandleOnTakeDamage(FinalDamage, uDamageEvent, uVictim, uAttacker, uExtraDamageInfo)
  if not FinalDamage or FinalDamage <= 0 then
    return
  end
  local uCharacter = self:GetCharacter()
  if not slua.isValid(uCharacter) or not uCharacter:HasAuthority() then
    return
  end
  if not NosferatuFeature.IsNosferatu(uCharacter) then
    return
  end
  if not slua.isValid(uAttacker) or uAttacker == uCharacter.Object then
    return
  end
  uCharacter:AddBuffByID(HIT_SLOW_BUFF_ID, nil, 1, 0, 1)
  print(bWriteLog and string.format("NosferatuFeature:HandleOnTakeDamage add slow buff %d, Damage=%.2f, Attacker=%s", HIT_SLOW_BUFF_ID, FinalDamage, tostring(uAttacker)))
end
function NosferatuFeature:HandleOnMovementModeChanged(uCharacter, PrevMovementMode, PrevCustomMode)
  if not self.IsNosferatu(uCharacter) then
    return
  end
  local bWasSwimming = PrevMovementMode == EMovementMode.MOVE_Swimming
  local bIsSwimming = IsSwimming(self:GetCharacter())
  if bWasSwimming == bIsSwimming then
    return
  end
  self:SetSwimSkillsDisabled(bIsSwimming)
end
function NosferatuFeature:HandleClientMovementModeChanged(uCharacter, PrevMovementMode, PrevCustomMode)
  if not Client then
    return
  end
  if PrevMovementMode ~= EMovementMode.MOVE_Swimming then
    return
  end
  local uSelfCharacter = self:GetCharacter()
  if not slua.isValid(uSelfCharacter) or IsSwimming(uSelfCharacter) then
    return
  end
  if not uSelfCharacter:IsLocallyControlled() or not NosferatuFeature.IsNosferatu(uSelfCharacter) then
    return
  end
  self:CheckAttackUI()
  if self.SwimExitUICheckTimer then
    self:RemoveGameTimer(self.SwimExitUICheckTimer)
    self.SwimExitUICheckTimer = nil
  end
  self.SwimExitUICheckTimer = self:AddGameTimer(SWIM_EXIT_UI_CHECK_DELAY, false, function()
    self.SwimExitUICheckTimer = nil
    self:CheckAttackUI()
  end)
end
function NosferatuFeature:CheckAttackUI()
  if not Client then
    return
  end
  local uCharacter = self:GetCharacter()
  if not slua.isValid(uCharacter) then
    return
  end
  local uLocalChar = GameplayData.GetPlayerCharacter()
  if not slua.isValid(uLocalChar) or uCharacter ~= uLocalChar then
    return
  end
  if not NosferatuFeature.IsNosferatu(uCharacter) then
    return
  end
  local uMoveComp = uCharacter.STCharacterMovement
  if not slua.isValid(uMoveComp) then
    uMoveComp = uCharacter.CharacterMovement
  end
  if slua.isValid(uMoveComp) and uMoveComp.MovementMode == EMovementMode.MOVE_Swimming then
    print(bWriteLog and "NosferatuFeature:CheckAttackUI skip, swimming again")
    return
  end
  for _, sUIConfigName in ipairs(ATTACK_UI_CONFIG_NAMES) do
    local tConfig = UIManager.UI_Config_InGame[sUIConfigName]
    if tConfig then
      local uUI = UIManager.GetUI(tConfig)
      if not uUI or not uUI:IsShow() then
        print(bWriteLog and "NosferatuFeature:CheckAttackUI reshow " .. tostring(sUIConfigName))
        UIManager.ShowUI(tConfig)
      end
    end
  end
end
function NosferatuFeature:SetSwimSkillsDisabled(bDisabled)
  local uCharacter = self:GetCharacter()
  if not slua.isValid(uCharacter) or not uCharacter:HasAuthority() then
    return
  end
  if not self.IsNosferatu(uCharacter.Object) then
    return
  end
  self:DoSetSwimSkillsDisabled(bDisabled)
end
function NosferatuFeature:DoSetSwimSkillsDisabled(bDisabled)
  local uCharacter = self:GetCharacter()
  if not slua.isValid(uCharacter) or not uCharacter:HasAuthority() then
    return
  end
  local uSkillManager = uCharacter.SkillManager
  if not slua.isValid(uSkillManager) then
    print(bWriteLog and "NosferatuFeature:SetSwimSkillsDisabled SkillManager invalid, skip")
    return
  end
  if self.bSwimSkillsDisabled == bDisabled then
    return
  end
  self.bSwimSkillsDisabled = bDisabled
  if bDisabled then
    self.SwimDisabledSkillSlots = {}
    for _, nSkillID in ipairs(NOSFERATU_SKILLS) do
      local nSlot = 0
      if uSkillManager.GetSkillButtonSlot then
        nSlot = uSkillManager:GetSkillButtonSlot(nSkillID) or 0
      end
      self.SwimDisabledSkillSlots[nSkillID] = nSlot
      uSkillManager:TryDeleteOneSkill(nSkillID, true, false)
      print(bWriteLog and string.format("NosferatuFeature:SetSwimSkillsDisabled delete skill %d (slot=%s)", nSkillID, tostring(nSlot)))
    end
    return
  end
  local SavedSlots = self.SwimDisabledSkillSlots or {}
  for _, nSkillID in ipairs(NOSFERATU_SKILLS) do
    uSkillManager:TryAddOneSkill(nSkillID, true, 0)
    print(bWriteLog and string.format("NosferatuFeature:SetSwimSkillsDisabled restore skill %d (slot=%s)", nSkillID, tostring(SavedSlots[nSkillID] or 0)))
  end
  self.SwimDisabledSkillSlots = nil
end
function NosferatuFeature:EnterArrestState(nDuration)
  local uCharacter = self:GetCharacter()
  if not slua.isValid(uCharacter) or not uCharacter:HasAuthority() then
    return
  end
  if not self.IsNosferatu(uCharacter.Object) then
    return
  end
  if not self.bArrestSkillsDisabled then
    self.bArrestSkillsDisabled = true
    local uSkillManager = uCharacter.SkillManager
    if slua.isValid(uSkillManager) then
      uSkillManager:SetSkillIDsDisable(NOSFERATU_SKILLS, true, "NosferatuArrest")
    end
    print(bWriteLog and string.format("NosferatuFeature:EnterArrestState enter, duration=%.2f", nDuration))
  else
    print(bWriteLog and string.format("NosferatuFeature:EnterArrestState refresh, duration=%.2f", nDuration))
  end
  if self.ArrestStateTimer then
    self:RemoveGameTimer(self.ArrestStateTimer)
    self.ArrestStateTimer = nil
  end
  self.ArrestStateTimer = self:AddGameTimer(nDuration, false, function()
    self:ExitArrestState()
  end)
end
function NosferatuFeature:ExitArrestState()
  if self.ArrestStateTimer then
    self:RemoveGameTimer(self.ArrestStateTimer)
    self.ArrestStateTimer = nil
  end
  local uCharacter = self:GetCharacter()
  if not slua.isValid(uCharacter) or not uCharacter:HasAuthority() then
    return
  end
  if not self.bArrestSkillsDisabled then
    return
  end
  self.bArrestSkillsDisabled = false
  local uSkillManager = uCharacter.SkillManager
  if slua.isValid(uSkillManager) then
    uSkillManager:SetSkillIDsDisable(NOSFERATU_SKILLS, false, "NosferatuArrest")
  end
  print(bWriteLog and "NosferatuFeature:ExitArrestState exit")
end
function NosferatuFeature:RefreshSpeedRateModifier()
  local uCharacter = self:GetCharacter()
  if not slua.isValid(uCharacter) then
    return
  end
  if not NosferatuFeature.IsNosferatu(uCharacter) then
    self:RemoveSpeedRateModifier()
    return
  end
  if uCharacter.PoseState == ESTEPoseState.Sprint then
    self:SetSpeedRateModifier(SPRINT_SPEED_RATE_ADD)
  else
    self:SetSpeedRateModifier(RUN_SPEED_RATE_ADD)
  end
end
function NosferatuFeature:SetSpeedRateModifier(nSpeedRateAdd)
  if type(nSpeedRateAdd) ~= "number" then
    print(bWriteLog and string.format("NosferatuFeature:SetSpeedRateModifier bad arg %s, use RemoveSpeedRateModifier to clear", tostring(nSpeedRateAdd)))
    return
  end
  local uCharacter = self:GetCharacter()
  if not slua.isValid(uCharacter) then
    return
  end
  local uAttrModifyComp = uCharacter.AttrModifyComp
  if not slua.isValid(uAttrModifyComp) then
    return
  end
  self:RemoveSpeedRateModifier()
  self.SpeedRateModifyUID = uAttrModifyComp:AddModifyItemAndCache("SpeedRate", EAttrModifyRefType.Val, nSpeedRateAdd, true, uCharacter, false)
  self.SpeedRateModifyValue = nSpeedRateAdd
  print(bWriteLog and string.format("NosferatuFeature:SetSpeedRateModifier add SpeedRate +%.2f UID=%s", nSpeedRateAdd, tostring(self.SpeedRateModifyUID)))
end
function NosferatuFeature:RemoveSpeedRateModifier()
  if not self.SpeedRateModifyUID then
    self.SpeedRateModifyValue = nil
    return
  end
  local uCharacter = self:GetCharacter()
  if slua.isValid(uCharacter) then
    local uAttrModifyComp = uCharacter.AttrModifyComp
    if slua.isValid(uAttrModifyComp) then
      uAttrModifyComp:RemoveModifyItemFromCache(self.SpeedRateModifyUID)
      print(bWriteLog and string.format("NosferatuFeature:RemoveSpeedRateModifier remove SpeedRate modifier UID=%s", tostring(self.SpeedRateModifyUID)))
    end
  end
  self.SpeedRateModifyUID = nil
  self.SpeedRateModifyValue = nil
end
function NosferatuFeature:TryTransform()
  local uCharacter = self:GetCharacter()
  if not slua.isValid(uCharacter) then
    return
  end
  local UTSkillStopReason = import("UTSkillStopReason")
  uCharacter:StopAllSkills(UTSkillStopReason.SkillStopReason_Interrupted)
  uCharacter.Tags:Add(TAG_DISABLE_CHECK_FALLING_DISTANCE)
  uCharacter:AddBuffBySkill(600409, 1, nil, 1)
  uCharacter:AddSkillToken(4605001)
  uCharacter:TriggerEntrySkillWithID(TRANSFORM_SKILL_ID, true)
end
function NosferatuFeature:SetIgnoreMVPStatue(bIgnore)
  local uCharacter = self:GetCharacter()
  if not slua.isValid(uCharacter) then
    return
  end
  local uPlayerState = uCharacter.GetPlayerStateSafety and uCharacter:GetPlayerStateSafety() or uCharacter.PlayerState
  if not slua.isValid(uPlayerState) then
    return
  end
  uPlayerState.bIgnoreMVPStatue = bIgnore
  print(bWriteLog and string.format("NosferatuFeature:SetIgnoreMVPStatue %s", tostring(bIgnore)))
end
function NosferatuFeature:SetCirclePainRate(nRate)
  local uCharacter = self:GetCharacter()
  if not slua.isValid(uCharacter) then
    return
  end
  if not uCharacter:HasAuthority() then
    return
  end
  uCharacter.CirclePainRate = nRate
  print(bWriteLog and string.format("NosferatuFeature:SetCirclePainRate %s", tostring(nRate)))
end
function NosferatuFeature:BeforeEnterHero(HeroID, PlayerKey)
  print(bWriteLog and string.format("NosferatuFeature:BeforeEnterHero HeroID=%s PlayerKey=%s", tostring(HeroID), tostring(PlayerKey)))
  local uCharacter = self:GetCharacter()
  if slua.isValid(uCharacter) then
    uCharacter.bOpenPredictSwitchPose = false
  end
end
function NosferatuFeature:AfterEnterHero(HeroID, PlayerKey)
  print(bWriteLog and string.format("NosferatuFeature:AfterEnterHero HeroID=%s PlayerKey=%s", tostring(HeroID), tostring(PlayerKey)))
  local uCharacter = self:GetCharacter()
  if not slua.isValid(uCharacter) then
    return
  end
  print(bWriteLog and string.format("NosferatuFeature:AfterEnterHero uCharacter valid HeroID=%s PlayerKey=%s", tostring(HeroID), tostring(PlayerKey)))
  if Client then
    uCharacter:DelayHidden()
  end
  self:SetIgnoreMVPStatue(true)
  self:AddControlEvent(uCharacter, "OnPlayerPoseChange", self.OnPlayerPoseChange, self)
  self:RefreshSpeedRateModifier()
  self:AddGameTimer(0, false, function()
    self:RefreshSpeedRateModifier()
  end)
  self:SetPetHidden(true)
  if slua.isValid(uCharacter.PetComponent_BP) then
    self:AddControlEvent(uCharacter.PetComponent_BP, "OnRepPetPawnCalled", self.HandleRepPetPawn, self)
  end
  if slua.isValid(uCharacter.STCharacterMovement) then
    local EDynamicSimpleQueryConfigDisableMask = import("EDynamicSimpleQueryConfigDisableMask")
    uCharacter.STCharacterMovement:SetDynamicSimpleQueryConfigDisable(EDynamicSimpleQueryConfigDisableMask.Bit2, true)
    printf(bWriteLog and string.format("NosferatuFeature:AfterEnterHero, SetDynamicSimpleQueryConfigDisable Disable Simple Move, %s", uCharacter:GetPlayerNameSafety()))
  end
  if uCharacter:HasAuthority() then
    local UBoeingLibrary = import("/Script/ShadowTrackerExtra.BoeingLibrary")
    local ECharSkipState = import("/Script/ShadowTrackerExtra.ECharSkipState")
    UBoeingLibrary.MarkSkipState(uCharacter, ECharSkipState.CSS_CharMoveDist, true, "AfterEnterHero", false)
    if uCharacter.MarkEverVampire then
      uCharacter:MarkEverVampire()
    end
    for _, nID in ipairs(NOSFERATU_SKILLS) do
      uCharacter:AddSkillToken(nID)
    end
    for _, nID in ipairs(MeleeComboIDs) do
      uCharacter:AddSkillToken(nID)
    end
    uCharacter:AddBuffByID(4605002, nil, 1, 0, 1)
    Game:SetCampIDByController(uCharacter:GetPlayerControllerSafety(), 1)
    Game:AddHealth(uCharacter, uCharacter.HealthMax)
    self:SetCirclePainRate(NOSFERATU_CIRCLE_PAIN_RATE)
    if uCharacter.NearDeatchComponent then
      uCharacter.NearDeatchComponent:EnableDirectlyDie(true)
    end
    local uCharMoveComp = uCharacter.STCharacterMovement
    if slua.isValid(uCharMoveComp) then
      uCharMoveComp.bNotResetAccWhenForceUpdate = true
      uCharMoveComp.ExtraLocDiffScale = 1.5
    end
    if not uCharacter:ActorHasTag(TAG_DISABLE_CHECK_FALLING_DISTANCE) then
      uCharacter.Tags:Add(TAG_DISABLE_CHECK_FALLING_DISTANCE)
    end
    self.TransformStartTime = UGameplayStatics.GetTimeSeconds(uCharacter)
    if HeroID == UEnums.HeroID.Nosferatu and IsSwimming(uCharacter) then
      self:DoSetSwimSkillsDisabled(true)
    end
  end
  if Client then
    self:ProcessUI(true)
    local uAvatarComp = uCharacter.getAvatarComponent2 and uCharacter:getAvatarComponent2()
    if slua.isValid(uAvatarComp) then
      self:AddControlEvent(uAvatarComp, "OnAvatarAllMeshLoaded", self.HandleAvatarAllMeshLoaded, self)
    end
    self:HandleAvatarAllMeshLoaded()
    local uLocalChar = GameplayData.GetPlayerCharacter()
    if slua.isValid(uLocalChar) and uLocalChar == uCharacter then
      local NosferatuTransformTipPopup = require("GameLua.Mod.Halloween6.Client.UI.Popup.Halloween6NosferatuTransformTipPopup")
      NosferatuTransformTipPopup.TryShow()
    end
  end
end
function NosferatuFeature:BeforeExitHero(HeroID, PlayerKey)
  print(bWriteLog and string.format("NosferatuFeature:BeforeExitHero HeroID=%s PlayerKey=%s", tostring(HeroID), tostring(PlayerKey)))
  local uCharacter = self:GetCharacter()
  if not slua.isValid(uCharacter) then
    return
  end
  self:RemoveSpeedRateModifier()
  if uCharacter:HasAuthority() and self.TransformStartTime then
    local uPlayerState = uCharacter.GetPlayerStateSafety and uCharacter:GetPlayerStateSafety() or uCharacter.PlayerState
    if slua.isValid(uPlayerState) then
      local DuringTime = math.floor(UGameplayStatics.GetTimeSeconds(uCharacter) - self.TransformStartTime)
      if 0 < DuringTime then
        uPlayerState:AddGeneralCount(TLOG_ID_NOSFERATU_TRANSFORM_DURATION, DuringTime, false)
        print(bWriteLog and string.format("NosferatuFeature:BeforeExitHero AddGeneralCount %d, +%d", TLOG_ID_NOSFERATU_TRANSFORM_DURATION, DuringTime))
      end
    end
    self.TransformStartTime = nil
  end
end
function NosferatuFeature:AfterExitHero(HeroID, PlayerKey)
  print(bWriteLog and string.format("NosferatuFeature:AfterExitHero HeroID=%s PlayerKey=%s", tostring(HeroID), tostring(PlayerKey)))
  self.bSwimSkillsDisabled = false
  self.SwimDisabledSkillSlots = nil
  self:ExitArrestState()
  self:SetIgnoreMVPStatue(false)
  self:SetCirclePainRate(DEFAULT_CIRCLE_PAIN_RATE)
  local uCharacter = self:GetCharacter()
  if slua.isValid(uCharacter) then
    uCharacter.bOpenPredictSwitchPose = true
  end
  if slua.isValid(uCharacter) then
    uCharacter:SetActorHiddenInGame(true)
  end
  RemoveActorTag(uCharacter, TAG_DISABLE_CHECK_FALLING_DISTANCE)
  if slua.isValid(uCharacter) and slua.isValid(uCharacter.PetComponent_BP) then
    self:RemoveControlEvent(uCharacter.PetComponent_BP, "OnRepPetPawnCalled")
  end
  self:SetPetHidden(false)
  if Client then
    self:ProcessUI(false)
  end
end
function NosferatuFeature:SimulateEnterHero(HeroID, PlayerKey)
  print(bWriteLog and string.format("NosferatuFeature:SimulateEnterHero HeroID=%s PlayerKey=%s", tostring(HeroID), tostring(PlayerKey)))
  local uCharacter = self:GetCharacter()
  if not slua.isValid(uCharacter) then
    return
  end
  if slua.isValid(uCharacter) then
    uCharacter.bOpenPredictSwitchPose = false
  end
  self:AddControlEvent(uCharacter, "OnPlayerPoseChange", self.OnPlayerPoseChange, self)
  local uAvatarComp = uCharacter.getAvatarComponent2 and uCharacter:getAvatarComponent2()
  if slua.isValid(uAvatarComp) then
    self:AddControlEvent(uAvatarComp, "OnAvatarAllMeshLoaded", self.HandleAvatarAllMeshLoaded, self)
  end
  self:HandleAvatarAllMeshLoaded()
  self:SetIgnoreMVPStatue(true)
end
function NosferatuFeature:SimulateExitHero(HeroID, PlayerKey)
  print(bWriteLog and string.format("NosferatuFeature:SimulateExitHero HeroID=%s PlayerKey=%s", tostring(HeroID), tostring(PlayerKey)))
  self:SetIgnoreMVPStatue(false)
  local uCharacter = self:GetCharacter()
  if slua.isValid(uCharacter) then
    uCharacter.bOpenPredictSwitchPose = true
  end
end
function NosferatuFeature:GetLifetimeReplicatedProps()
  local ELifetimeCondition = import("ELifetimeCondition")
  return {
    {
      "bInvincible",
      ELifetimeCondition.COND_None,
      UEnums.EPropertyClass.Bool
    }
  }
end
function NosferatuFeature:SetInvincible(bEnable)
  if not self:HasAuthority() then
    print(bWriteLog and "NosferatuFeature:SetInvincible called on non-authority, ignored")
    return
  end
  bEnable = bEnable and true or false
  if self.bInvincible == bEnable then
    return
  end
  self.bInvincible = bEnable
  self:ForceNetUpdate()
  print(bWriteLog and string.format("NosferatuFeature:SetInvincible %s", tostring(bEnable)))
end
function NosferatuFeature:IsInvincible()
  return self.bInvincible == true
end
function NosferatuFeature:OnRep_bInvincible(OldValue)
  print(bWriteLog and string.format("NosferatuFeature:OnRep_bInvincible %s -> %s", tostring(OldValue), tostring(self.bInvincible)))
end
function NosferatuFeature:SetPetHidden(bHide)
  local uCharacter = self:GetCharacter()
  if not slua.isValid(uCharacter) or not slua.isValid(uCharacter.PetComponent_BP) then
    print(bWriteLog and "NosferatuFeature:SetPetHidden PetComponent_BP invalid")
    return
  end
  local EPetState = import("EPetState")
  if bHide then
    uCharacter.PetComponent_BP:PetEnterState(EPetState.PetDisappear)
  else
    uCharacter.PetComponent_BP:PetLeaveState(EPetState.PetDisappear)
  end
  print(bWriteLog and string.format("NosferatuFeature:SetPetHidden bHide=%s", tostring(bHide)))
end
function NosferatuFeature:HandleRepPetPawn()
  print(bWriteLog and "NosferatuFeature:HandleRepPetPawn re-apply pet hidden")
  self:SetPetHidden(true)
end
function NosferatuFeature:SetBloodPoolHidden(bHide)
  bHide = bHide and true or false
  if self.bBloodPoolHidden == bHide then
    return
  end
  self.bBloodPoolHidden = bHide
  print(bWriteLog and string.format("NosferatuFeature:SetBloodPoolHidden %s", tostring(bHide)))
  self:ApplyBloodPoolHiddenVisual(bHide)
end
function NosferatuFeature:IsBloodPoolHidden()
  return self.bBloodPoolHidden == true
end
function NosferatuFeature:ApplyBloodPoolHiddenVisual(bHide)
  if not Client then
    return
  end
  bHide = bHide and true or false
  if self.bBloodPoolVisualApplied == bHide then
    return
  end
  local uCharacter = self:GetCharacter()
  if not slua.isValid(uCharacter) then
    return
  end
  self.bBloodPoolVisualApplied = bHide
  if bHide then
    uCharacter:SetActorHiddenInGameMask(true, EActorHiddenMask.ActorHiddenMask7)
    self:AddControlEvent(uCharacter, "OnCharacterHiddenStateChange", self.HandleCharacterHiddenStateChange, self)
  else
    self:RemoveControlEvent(uCharacter, "OnCharacterHiddenStateChange")
    uCharacter:SetActorHiddenInGameMask(false, EActorHiddenMask.ActorHiddenMask7)
    if not uCharacter.bDead then
      if not uCharacter:GetActorEnableCollision() then
        uCharacter:SetActorEnableCollision(true)
      end
      if slua.isValid(uCharacter.STCharacterMovement) and not uCharacter.STCharacterMovement:IsActive() then
        uCharacter.STCharacterMovement:Activate(false)
      end
    end
  end
  local uOwnerMesh = uCharacter.Mesh
  if slua.isValid(uOwnerMesh) then
    uOwnerMesh:SetComponentTickEnabled(not bHide)
    uOwnerMesh.bNoSkeletonUpdate = bHide
  end
  print(bWriteLog and string.format("NosferatuFeature:ApplyBloodPoolHiddenVisual bHide=%s", tostring(bHide)))
end
function NosferatuFeature:HandleCharacterHiddenStateChange(bNewHidden)
  local uCharacter = self:GetCharacter()
  if not slua.isValid(uCharacter) then
    return
  end
  local bMaskHidden = uCharacter:IsMaskHidden(EActorHiddenMask.ActorHiddenMask7)
  if bNewHidden == bMaskHidden then
    return
  end
  print(bWriteLog and string.format("NosferatuFeature:HandleCharacterHiddenStateChange - correct hidden, bNewHidden=%s, bMaskHidden=%s", tostring(bNewHidden), tostring(bMaskHidden)))
  uCharacter:SetActorHiddenInGameMask(bMaskHidden, EActorHiddenMask.ActorHiddenMask7)
end
function NosferatuFeature:GetMeleeAttackID()
  local uCharacter = self:GetCharacter()
  if not slua.isValid(uCharacter) then
    return nil
  end
  for _, nID in ipairs(MeleeComboIDs) do
    if uCharacter:IsCastingSkillIDFix(nID) then
      return nID
    end
  end
  return nil
end
function NosferatuFeature:NosferatuMeleeAttack(bFire)
  local uCharacter = self:GetCharacter()
  if not slua.isValid(uCharacter) then
    return
  end
  if not slua.isValid(uCharacter.SkillManager) then
    return
  end
  local nAttackID = self:GetMeleeAttackID()
  if nAttackID then
    if bFire then
      print(bWriteLog and string.format("NosferatuFeature:NosferatuMeleeAttack SkillID:%d SET_KEY_DOWN", nAttackID))
      uCharacter.SkillManager:TriggerEvent(nAttackID, UTSkillEventType.SET_KEY_DOWN)
    else
      print(bWriteLog and string.format("NosferatuFeature:NosferatuMeleeAttack SkillID:%d SET_KEY_UP", nAttackID))
      uCharacter.SkillManager:TriggerEvent(nAttackID, UTSkillEventType.SET_KEY_UP)
    end
  elseif bFire then
    uCharacter:TriggerEntrySkillWithID(4605003, bFire)
  else
    uCharacter:TriggerEntrySkillWithID(4605003, bFire)
    uCharacter.SkillManager:TriggerEvent(4605003, UTSkillEventType.SET_KEY_UP)
  end
end
function NosferatuFeature:ProcessUI(bEnter)
  if not Client then
    return
  end
  local uCharacter = self:GetCharacter()
  if not slua.isValid(uCharacter) then
    print(bWriteLog and "NosferatuFeature:ProcessUI invalid character")
    return
  end
  local uLocalChar = GameplayData.GetPlayerCharacter()
  if not slua.isValid(uLocalChar) or uCharacter ~= uLocalChar then
    print(bWriteLog and "NosferatuFeature:ProcessUI invalid uLocalChar")
    return
  end
  if bEnter then
    UIManager.ShowUI(UIManager.UI_Config_InGame.NosferatuAttackLeftUI)
    UIManager.ShowUI(UIManager.UI_Config_InGame.NosferatuAttackRightUI)
  else
    UIManager.CloseUI(UIManager.UI_Config_InGame.NosferatuAttackLeftUI)
    UIManager.CloseUI(UIManager.UI_Config_InGame.NosferatuAttackRightUI)
  end
end
local class = require("class")
local CFeatureBase = require("GameLua.Mod.BaseMod.GamePlay.Feature.Common.FeatureBase")
local CNosferatuFeature = class(CFeatureBase, nil, NosferatuFeature)
return CNosferatuFeature
