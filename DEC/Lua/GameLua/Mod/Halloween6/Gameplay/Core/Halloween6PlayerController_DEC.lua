local GameplayData = require("GameLua.GameCore.Data.GameplayData")
local USTExtraBlueprintFunctionLibrary = import("STExtraBlueprintFunctionLibrary")
local Halloween6PlayerController = {
  ServerRPC = {},
  ClientRPC = {},
  MulticastRPC = {}
}
function Halloween6PlayerController:ctor()
end
function Halloween6PlayerController:_PostConstruct()
  Halloween6PlayerController.__super._PostConstruct(self)
  if Client then
    self.bTrackingKillerEnabled = false
    print(bWriteLog and string.format("Halloween6PlayerController:_PostConstruct bTrackingKillerEnabled = %s", self.bTrackingKillerEnabled))
  end
end
function Halloween6PlayerController:ReceiveBeginPlay()
  Halloween6PlayerController.__super.ReceiveBeginPlay(self)
  local UKismetSystemLibrary = import("KismetSystemLibrary")
  if Client then
    UKismetSystemLibrary.ExecuteConsoleCommand(self.Object, "r.ForceLocalCharTickScreenSize 1")
    print(bWriteLog and "Halloween6PlayerController:ReceiveBeginPlay r.ForceLocalCharTickScreenSize 1")
  end
end
function Halloween6PlayerController:ReceiveEndPlay(EndPlayReason)
  self.PendingRestartConfirmActor = nil
  Halloween6PlayerController.__super.ReceiveEndPlay(self, EndPlayReason)
end
function Halloween6PlayerController:MarkRestartConfirmPending(StartActor)
  self.PendingRestartConfirmActor = StartActor
end
Halloween6PlayerController.ServerRPC.ServerRPC_RequestExitShootingRange = {
  Reliable = true,
  Params = {}
}
function Halloween6PlayerController:ServerRPC_RequestExitShootingRange()
  local PlayerKey = self.PlayerKey
  local ShootingRangeActor = CGameMode.ShootingRangeRegistry:GetActorByPlayerKey(PlayerKey)
  if not ShootingRangeActor then
    print(bWriteLog and string.format("Halloween6PlayerController:ServerRPC_RequestExitShootingRange - no active game for PlayerKey = %s", PlayerKey))
    return
  end
  print(bWriteLog and string.format("Halloween6PlayerController:ServerRPC_RequestExitShootingRange PlayerKey = %s", PlayerKey))
  ShootingRangeActor:RequestExitGame(PlayerKey)
end
Halloween6PlayerController.ServerRPC.ServerRPC_PauseShootingRange = {
  Reliable = true,
  Params = {}
}
function Halloween6PlayerController:ServerRPC_PauseShootingRange()
  local PlayerKey = self.PlayerKey
  local ShootingRangeActor = CGameMode.ShootingRangeRegistry:GetActorByPlayerKey(PlayerKey)
  if not ShootingRangeActor then
    print(bWriteLog and string.format("Halloween6PlayerController:ServerRPC_PauseShootingRange - no active game for PlayerKey = %s", PlayerKey))
    return
  end
  print(bWriteLog and string.format("Halloween6PlayerController:ServerRPC_PauseShootingRange PlayerKey = %s", PlayerKey))
  ShootingRangeActor:PauseForExit(PlayerKey)
end
Halloween6PlayerController.ServerRPC.ServerRPC_ResumeShootingRange = {
  Reliable = true,
  Params = {}
}
function Halloween6PlayerController:ServerRPC_ResumeShootingRange()
  local PlayerKey = self.PlayerKey
  local ShootingRangeActor = CGameMode.ShootingRangeRegistry:GetActorByPlayerKey(PlayerKey)
  if not ShootingRangeActor then
    print(bWriteLog and string.format("Halloween6PlayerController:ServerRPC_ResumeShootingRange - no active game for PlayerKey = %s", PlayerKey))
    return
  end
  print(bWriteLog and string.format("Halloween6PlayerController:ServerRPC_ResumeShootingRange PlayerKey = %s", PlayerKey))
  ShootingRangeActor:ResumeFromExit(PlayerKey)
end
Halloween6PlayerController.ClientRPC.ClientRPC_ShowQuestTips = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Int,
    {
      UEnums.EPropertyClass.Array,
      UEnums.EPropertyClass.Byte
    }
  }
}
function Halloween6PlayerController:ClientRPC_ShowQuestTips(TipsType, ParamsContent)
  if not Client then
    return
  end
  local Params = slua.LuaArchiverDecode(LuaStateWrapper, ParamsContent) or {}
  print(bWriteLog and string.format("Halloween6PlayerController:ClientRPC_ShowQuestTips TipsType = %s", TipsType))
  local PlayerCharacter = GameplayData.GetPlayerCharacter()
  if slua.isValid(PlayerCharacter) and PlayerCharacter.PlayerCharacterPOIGameplayFeature then
    PlayerCharacter.PlayerCharacterPOIGameplayFeature:ShowCommonPOIGameplayTipsUI(TipsType, Params)
  end
end
Halloween6PlayerController.ClientRPC.ClientRPC_ShowShootingRangeRestartConfirm = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Object
  }
}
function Halloween6PlayerController:ClientRPC_ShowShootingRangeRestartConfirm(StartActor)
  if not Client then
    return
  end
  if not slua.isValid(StartActor) then
    return
  end
  local ShootingRangeConfig = require("GameLua.Mod.Halloween6.Gameplay.Config.ShootingRangeConfig")
  local IngameTipsTools = require("GameLua.Mod.BaseMod.Common.UI.InGameTipsTools")
  local Title = ""
  local Content = ""
  local TitleId = ShootingRangeConfig.TextId.RestartConfirmTitle
  local ContentId = ShootingRangeConfig.TextId.RestartConfirmContent
  if TitleId and 0 < TitleId then
    Title = LocUtil.GetLocalizeResStr(TitleId)
  end
  if ContentId and 0 < ContentId then
    Content = LocUtil.GetLocalizeResStr(ContentId)
  end
  print(bWriteLog and "Halloween6PlayerController:ClientRPC_ShowShootingRangeRestartConfirm")
  IngameTipsTools.ShowMsgBox(IngameTipsTools.MSGBOX_SHOW_TYPE_TWO, Title, Content, function()
    if slua.isValid(StartActor) and self.ServerRPC_ConfirmStartShootingRange then
      self:ServerRPC_ConfirmStartShootingRange(StartActor)
    end
  end, nil)
end
Halloween6PlayerController.ServerRPC.ServerRPC_ConfirmStartShootingRange = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Object
  }
}
function Halloween6PlayerController:ServerRPC_ConfirmStartShootingRange(StartActor)
  if not slua.isValid(StartActor) then
    return
  end
  if not slua.isValid(self.PendingRestartConfirmActor) or self.PendingRestartConfirmActor ~= StartActor then
    print(bWriteLog and string.format("Halloween6PlayerController:ServerRPC_ConfirmStartShootingRange - no valid pending confirm, reject PlayerKey = %s", self.PlayerKey))
    self.PendingRestartConfirmActor = nil
    return
  end
  self.PendingRestartConfirmActor = nil
  local uCharacter = GameplayData.GetPlayerCharacter(self.PlayerKey)
  if not slua.isValid(uCharacter) then
    return
  end
  local ParentActor = StartActor:GetAttachParentActor()
  if not slua.isValid(ParentActor) then
    return
  end
  local Config = require("GameLua.Mod.Halloween6.Gameplay.Config.ShootingRangeConfig")
  local MaxDistance = Config.RestartConfirmMaxDistance or 500
  local CharLoc = uCharacter:K2_GetActorLocation()
  local ActorLoc = StartActor:K2_GetActorLocation()
  local Distance = FVector.Distance(CharLoc, ActorLoc)
  if MaxDistance < Distance then
    print(bWriteLog and string.format("Halloween6PlayerController:ServerRPC_ConfirmStartShootingRange - too far, distance = %s max = %s PlayerKey = %s", tostring(Distance), tostring(MaxDistance), self.PlayerKey))
    return
  end
  if StartActor.bIsCoolDown then
    local IngameTipsTools = require("GameLua.Mod.BaseMod.Common.UI.InGameTipsTools")
    local Remaining = 0
    if ParentActor.GetCooldownRemaining then
      Remaining = ParentActor:GetCooldownRemaining()
    end
    if Config.TextId.CoolDownTips and 0 < Config.TextId.CoolDownTips then
      IngameTipsTools.BattleNormalTipsByTextID(Config.TextId.CoolDownTips, tostring(Remaining), "", 3, self.PlayerKey, false)
    end
    print(bWriteLog and string.format("Halloween6PlayerController:ServerRPC_ConfirmStartShootingRange - cooldown remaining = %s PlayerKey = %s", tostring(Remaining), self.PlayerKey))
    return
  end
  if ParentActor.StartGame then
    ParentActor:StartGame(uCharacter)
  end
  print(bWriteLog and string.format("Halloween6PlayerController:ServerRPC_ConfirmStartShootingRange PlayerKey = %s", self.PlayerKey))
end
local RALLY_REQUEST_CD_TIME = 3
function Halloween6PlayerController:RequestRally()
  if not Client then
    return
  end
  local UGameplayStatics = import("GameplayStatics")
  local Now = UGameplayStatics.GetTimeSeconds(self)
  if self.LastClientRallyTime and Now - self.LastClientRallyTime < RALLY_REQUEST_CD_TIME then
    print(bWriteLog and string.format("Halloween6PlayerController:RequestRally - in CD, remain = %.2fs", RALLY_REQUEST_CD_TIME - (Now - self.LastClientRallyTime)))
    return
  end
  self.LastClientRallyTime = Now
  self:ServerRPC_RequestRally()
end
Halloween6PlayerController.ServerRPC.ServerRPC_RequestRally = {
  Reliable = true,
  Params = {}
}
function Halloween6PlayerController:ServerRPC_RequestRally()
  if Client then
    return
  end
  local PlayerKey = self.PlayerKey
  local UGameplayStatics = import("GameplayStatics")
  local Now = UGameplayStatics.GetTimeSeconds(self)
  if self.LastServerRallyTime and Now - self.LastServerRallyTime < RALLY_REQUEST_CD_TIME then
    print(bWriteLog and string.format("Halloween6PlayerController:ServerRPC_RequestRally - in CD, PlayerKey = %s", tostring(PlayerKey)))
    return
  end
  self.LastServerRallyTime = Now
  print(bWriteLog and string.format("Halloween6PlayerController:ServerRPC_RequestRally PlayerKey = %s", PlayerKey))
  if slua.isValid(CGameState) and CGameState.RequestRally then
    CGameState:RequestRally(PlayerKey)
  end
end
Halloween6PlayerController.ServerRPC.ServerRPC_JoinVampire = {
  Reliable = true,
  Params = {}
}
function Halloween6PlayerController:ServerRPC_JoinVampire()
  local PlayerKey = self.PlayerKey
  print(bWriteLog and string.format("Halloween6PlayerController:ServerRPC_JoinVampire PlayerKey = %s", PlayerKey))
  if CGameMode and CGameMode.ChooseTransformVampireFeature then
    CGameMode.ChooseTransformVampireFeature:OnPlayerChooseJoin(PlayerKey)
  end
end
Halloween6PlayerController.ServerRPC.ServerRPC_GiveUpVampire = {
  Reliable = true,
  Params = {}
}
function Halloween6PlayerController:ServerRPC_GiveUpVampire()
  local PlayerKey = self.PlayerKey
  print(bWriteLog and string.format("Halloween6PlayerController:ServerRPC_GiveUpVampire PlayerKey = %s", PlayerKey))
  if CGameMode and CGameMode.ChooseTransformVampireFeature then
    CGameMode.ChooseTransformVampireFeature:OnPlayerChooseGiveUp(PlayerKey, "PlayerGiveUp")
  end
end
function Halloween6PlayerController:ShouldShowVoiceVisualizationForSameTeam(OtherPlayerCharacter)
  if not slua.isValid(OtherPlayerCharacter) then
    return false
  end
  local LocalPlayerCharacter = GameplayData.GetLocalCharacter()
  if not slua.isValid(LocalPlayerCharacter) then
    return false
  end
  local bCanAttack = USTExtraBlueprintFunctionLibrary.CanAttack(OtherPlayerCharacter, LocalPlayerCharacter, false)
  return bCanAttack
end
local class = require("class")
local CPlayerController = require("GameLua.Mod.BRMod.Gameplay.Core.BRPlayerControllerBase")
local CHalloween6PlayerController = class(CPlayerController, nil, Halloween6PlayerController)
return require("combine_class").DeclareFeature(CHalloween6PlayerController, {
  {
    QTEChest = "GameLua.Mod.Library.GamePlay.Feature.QTEChestPlayerControllerFeature"
  }
}, "Halloween6PlayerController")
