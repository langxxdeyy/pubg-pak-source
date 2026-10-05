local CreativeModeParticleGeneratorGameObject = {}
local Utility = require("GameLua.Mod.CreativeBase.Gameplay.Meta.CreativeModeUtility")
local UGameplayStatics = import("GameplayStatics")
local ParticleGeneratorActorClass = "/Game/Library/CreativeDL/IG2900/Arts_PlayerBluePrints/Logic/ParticleGenerator/Runtime/BP_ParticleGeneratorActor.BP_ParticleGeneratorActor"
local ECreativeModePlayState = import("ECreativeModePlayState")
function CreativeModeParticleGeneratorGameObject:ReceiveBeginPlay()
  CreativeModeParticleGeneratorGameObject.__super.ReceiveBeginPlay(self)
  self.bWaitToMove = false
  self.bIsStart = false
  self.bEnableObby = true
  self:OfflineSpawnEditorObjectInPlace()
end
function CreativeModeParticleGeneratorGameObject:_Active(Msg)
  log(bWriteLog and "CreativeModeParticleGeneratorGameObject:_Active " .. self:GetInstanceId())
  if self:HasAuthority() then
    self:CreateParticleGeneratorActor()
    self.bWaitToMove = false
    if slua.isValid(self.ParticleGeneratorActor) then
      local bStartMoveOnActive = self:GetValue("ObbyParam.StartMoveOnActive")
      if bStartMoveOnActive then
        local ActiveChoose = self:_GetActiveChoose()
        if ActiveChoose == 1 then
          self.bWaitToMove = true
        else
          self:StartMove()
        end
      end
      local IsStartOnActive = self:GetValue("ParticleGenerator.IsStartOnActive")
      if IsStartOnActive then
        local PlayState = CGameState:GetPlayState()
        log(bWriteLog and "CreativeModeParticleGeneratorGameObject:_Active 1== " .. tostring(PlayState))
        if PlayState == ECreativeModePlayState.CreativeModePlayState_None then
          self:AddGameTimer(1, false, function()
            local InPlayState = CGameState:GetPlayState()
            log(bWriteLog and "CreativeModeParticleGeneratorGameObject:_Active 2== " .. tostring(PlayState))
            if InPlayState == ECreativeModePlayState.CreativeModePlayState_None then
              self:AddGameTimer(2, false, function()
                self:StartPlayParticle(Msg)
              end)
            else
              self:StartPlayParticle(Msg)
            end
          end)
        else
          self:StartPlayParticle(Msg)
        end
      end
    end
  end
end
function CreativeModeParticleGeneratorGameObject:_Inactive(Msg)
  if self:HasAuthority() then
    log(bWriteLog and "CreativeModeParticleGeneratorGameObject:_Inactive " .. self:GetInstanceId())
    if slua.isValid(self.ParticleGeneratorActor) and self.ParticleGeneratorActor.SimpleMoveFeature then
      self.ParticleGeneratorActor.SimpleMoveFeature:StopMove()
    end
    self:DestroyParticleGeneratorActor()
    self.bIsStart = false
    self.bWaitToMove = false
    self:RemoveLoopTimer()
    self.bIsParticlePlaying = false
  end
end
function CreativeModeParticleGeneratorGameObject:OnCreativeModePlayStateChange(PlayState)
  log(bWriteLog and "CreativeModeParticleGeneratorGameObject:OnCreativeModePlayStateChange " .. tostring(PlayState))
  if PlayState == ECreativeModePlayState.CreativeModePlayState_Fighting and self.bWaitToMove then
    self:StartMove()
  end
end
function CreativeModeParticleGeneratorGameObject:StartMoveOnActive(bStartMoveOnActive)
  if bStartMoveOnActive then
    local ActiveChoose = self:_GetActiveChoose()
    if ActiveChoose == 0 then
      self.bWaitToMove = true
    elseif slua.isValid(self.ParticleGeneratorActor) then
      self:StartMove()
    end
  end
end
function CreativeModeParticleGeneratorGameObject:CreateParticleGeneratorActor()
  log(bWriteLog and "CreativeModeParticleGeneratorGameObject:CreateParticleGeneratorActor")
  if self.ParticleGeneratorActor == nil then
    local StaticObject_Class = slua.loadClass(ParticleGeneratorActorClass)
    local LuaTransform = self:GetValue("Transform")
    local InstanceTransform = Utility:MakeUnrealTransform(LuaTransform)
    self.ParticleGeneratorActor = UGameplayStatics.BeginDeferredActorSpawnFromClass(self, StaticObject_Class, InstanceTransform, UEnums.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
    UGameplayStatics.FinishSpawningActor(self.ParticleGeneratorActor, InstanceTransform)
    local ObbyParamBase = self:GetValue("ObbyParam.Base")
    local AssetConfig = self:GetAssetInfo()
    local ConfigObbyParamBase = AssetConfig and AssetConfig.ObbyParam and AssetConfig.ObbyParam.Base and AssetConfig.ObbyParam.Base.LocationOffset
    self.ParticleGeneratorActor.SimpleMoveFeature:InitLocationOffset(ObbyParamBase, ConfigObbyParamBase)
    self.ParticleGeneratorActor.SimpleMoveFeature:OnSpawnActorFinish(ObbyParamBase)
    local MoveMode = self:GetValue("ObbyParam.MoveMode")
    self.ParticleGeneratorActor.SimpleMoveFeature:SetObbyActorMoveMode(MoveMode)
    self:AddControlEvent(self.ParticleGeneratorActor.ObbyActorMove, "OnMoveSingleTimeFinished", self._OnMoveSingleTimeFinished, self)
    GetCreativePerfManager():RecordActor(self.ParticleGeneratorActor, self:GetAssetId())
  else
    log(bWriteLog and "CreativeModeParticleGeneratorGameObject:CreateParticleGeneratorActor ParticleGeneratorActor==nil", true)
  end
end
function CreativeModeParticleGeneratorGameObject:DestroyParticleGeneratorActor()
  log(bWriteLog and "CreativeModeParticleGeneratorGameObject:DestroyParticleGeneratorActor")
  if slua.isValid(self.ParticleGeneratorActor) then
    self:RemoveControlEvent(self.ParticleGeneratorActor.ObbyActorMove, "OnMoveSingleTimeFinished")
    self.ParticleGeneratorActor:K2_DestroyActor()
    self.ParticleGeneratorActor = nil
  end
end
function CreativeModeParticleGeneratorGameObject:StartPlayParticle(Msg)
  log(bWriteLog and "CreativeModeParticleGeneratorGameObject:StartPlayParticle")
  local ParticleID = self:GetValue("ParticleGenerator.ParticleID")
  local bPlayAtTriggerPos = self:GetValue("ParticleGenerator.PlayAtTriggerPos")
  if bPlayAtTriggerPos and Msg then
    local triggerActor = Game:GetCharacterByUID(tonumber(Msg.TriggerPlayerUID))
    if slua.isValid(triggerActor) then
      local playPosition = triggerActor:K2_GetActorLocation()
      local playPosOffset = self:GetValue("ParticleGenerator.PlayPosOffset")
      playPosition.X = playPosition.X + playPosOffset.X
      playPosition.Y = playPosition.Y + playPosOffset.Y
      playPosition.Z = playPosition.Z + playPosOffset.Z
      if CGameState and CGameState.GameStatePlayEffectFeature then
        CGameState.GameStatePlayEffectFeature:PlayEffect(self:GetInstanceId(), ParticleID, playPosition)
      end
      return
    end
  end
  if slua.isValid(self.ParticleGeneratorActor) then
    local ParticleSubsys = SubsystemMgr:Get("CreativeModeParticleSystemSubSystem")
    local ParticleConfig = ParticleSubsys and ParticleSubsys:GetParticleConfigByID(ParticleID)
    local IsLoopEffect = true
    if ParticleConfig and ParticleConfig.IsLoopEffect ~= nil then
      IsLoopEffect = ParticleConfig.IsLoopEffect
    end
    if IsLoopEffect then
      local OnceDuration = self:GetValue("ParticleGenerator.OnceDuration")
      if OnceDuration < 0.1 then
        if ParticleConfig then
          OnceDuration = ParticleConfig.Duration
        else
          OnceDuration = 600
        end
      end
      self.ParticleGeneratorActor:PlayOnceParticle(self:GetInstanceId(), ParticleID or 0, OnceDuration)
      self:RemoveLoopTimer()
      if not self.LoopTimerId then
        self.LoopTimerId = self:AddGameTimer(OnceDuration, false, function()
          if self:HasAuthority() then
            self:BroadcastObjectEvent("ParticlePlayed")
            self:RemoveLoopTimer()
          end
        end)
      end
      return
    end
    local Duration = math.max(0.1, ParticleConfig.Duration or 0.1)
    local IsLoop = self:GetValue("ParticleGenerator.IsLoop")
    if IsLoop then
      local LoopInterval = self:GetValue("ParticleGenerator.LoopInterval")
      Duration = math.max(Duration, LoopInterval)
    end
    local ActiveAgainAction = self:GetValue("ParticleGenerator.ActiveAgainAction")
    local bResetTimer = false
    if self.bIsParticlePlaying then
      if ActiveAgainAction == 1 then
        bResetTimer = true
        self.ParticleGeneratorActor:PlayParticle(self:GetInstanceId(), ParticleID or 0, IsLoop, Duration)
      end
    else
      self.bIsParticlePlaying = true
      bResetTimer = true
      self.ParticleGeneratorActor:PlayParticle(self:GetInstanceId(), ParticleID or 0, IsLoop, Duration)
    end
    if bResetTimer then
      self:RemoveLoopTimer()
    end
    if not self.LoopTimerId then
      self.LoopTimerId = self:AddGameTimer(Duration, IsLoop, function()
        if self:HasAuthority() then
          self:BroadcastObjectEvent("ParticlePlayed")
          if not IsLoop then
            self.bIsParticlePlaying = false
            self:RemoveLoopTimer()
          end
        end
      end)
    end
  end
end
function CreativeModeParticleGeneratorGameObject:RemoveLoopTimer()
  if self.LoopTimerId then
    self:RemoveGameTimer(self.LoopTimerId)
    self.LoopTimerId = nil
  end
end
function CreativeModeParticleGeneratorGameObject:StartMove()
  if not self.bIsStart and slua.isValid(self.ParticleGeneratorActor) then
    self.ParticleGeneratorActor.SimpleMoveFeature:StartMove()
    self.bIsStart = true
  end
end
function CreativeModeParticleGeneratorGameObject:StopMove()
  if not self.bIsStart then
    return
  end
  if slua.isValid(self.ParticleGeneratorActor) then
    self.ParticleGeneratorActor.SimpleMoveFeature:StopMove()
    self.bIsStart = false
  end
end
function CreativeModeParticleGeneratorGameObject:PauseMove()
  if not self.bIsStart then
    return
  end
  if slua.isValid(self.ParticleGeneratorActor) then
    self.ParticleGeneratorActor.SimpleMoveFeature:PauseMove()
  end
end
function CreativeModeParticleGeneratorGameObject:ContinueMove()
  if not self.bIsStart then
    return
  end
  if slua.isValid(self.ParticleGeneratorActor) then
    self.ParticleGeneratorActor.SimpleMoveFeature:ContinueMove()
  end
end
function CreativeModeParticleGeneratorGameObject:_OnMoveSingleTimeFinished()
  print(bWriteLog and "CreativeModeParticleGeneratorGameObject:_OnMoveSingleTimeFinished")
  if self:HasAuthority() then
    self:BroadcastObjectEvent("RoundEnd")
  end
end
function CreativeModeParticleGeneratorGameObject:OnStartMove(functionIndex, Msg)
  log(bWriteLog and "CreativeModeParticleGeneratorGameObject:OnStartMove")
  self:StartMove()
end
function CreativeModeParticleGeneratorGameObject:OnStopMove(functionIndex, Msg)
  log(bWriteLog and "CreativeModeParticleGeneratorGameObject:OnStopMove")
  self:StopMove()
end
function CreativeModeParticleGeneratorGameObject:OnPauseMove(functionIndex, Msg)
  log(bWriteLog and "CreativeModeParticleGeneratorGameObject:OnPauseMove")
  self:PauseMove()
end
function CreativeModeParticleGeneratorGameObject:OnContinueMove(functionIndex, Msg)
  log(bWriteLog and "CreativeModeParticleGeneratorGameObject:OnContinueMove")
  self:ContinueMove()
end
function CreativeModeParticleGeneratorGameObject:PlayParticle(functionIndex, Msg)
  if self:HasAuthority() and self:GetIsActive() then
    self:StartPlayParticle(Msg)
  end
end
local class = require("class")
local CBaseObject = require("GameLua.Mod.CreativeBase.Gameplay.Object.GameObject.CreativeModeGameObjectBase")
return class(CBaseObject, nil, CreativeModeParticleGeneratorGameObject)
