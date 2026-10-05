local CreativeModeParticleGeneratorActor = {
  ServerRPC = {},
  ClientRPC = {},
  MulticastRPC = {}
}
local UKismetSystemLibrary = import("KismetSystemLibrary")
function CreativeModeParticleGeneratorActor:ctor()
end
function CreativeModeParticleGeneratorActor:GetLifetimeReplicatedProps()
  local ELifetimeCondition = import("ELifetimeCondition")
  local RepTable = {
    {
      "InstanceId",
      ELifetimeCondition.COND_None,
      UEnums.EPropertyClass.Str
    },
    {
      "bPlaying",
      ELifetimeCondition.COND_None,
      UEnums.EPropertyClass.Bool
    }
  }
  return RepTable
end
function CreativeModeParticleGeneratorActor:_PostConstruct()
  CreativeModeParticleGeneratorActor.__super._PostConstruct(self)
  if Client then
    local ActorTick = self.PrimaryActorTick
    ActorTick.bCanEverTick = true
    self.PrimaryActorTick = ActorTick
  end
end
function CreativeModeParticleGeneratorActor:ReceiveBeginPlay()
  CreativeModeParticleGeneratorActor.__super.ReceiveBeginPlay(self)
end
function CreativeModeParticleGeneratorActor:ReceiveEndPlay(EndPlayReason)
  if self._CreateParticleHandle then
    local ParticleSubsys = SubsystemMgr:Get("CreativeModeParticleSystemSubSystem")
    if ParticleSubsys then
      ParticleSubsys:CancelCreateParticle(self._CreateParticleHandle)
    end
    self._CreateParticleHandle = nil
  end
  CreativeModeParticleGeneratorActor.__super.ReceiveEndPlay(self, EndPlayReason)
end
function CreativeModeParticleGeneratorActor:ReceiveTick(DeltaTime)
end
CreativeModeParticleGeneratorActor.MulticastRPC.RPC_PlayParticle = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Str,
    UEnums.EPropertyClass.UInt64,
    UEnums.EPropertyClass.Bool,
    UEnums.EPropertyClass.Int
  }
}
CreativeModeParticleGeneratorActor.MulticastRPC.RPC_PlayOnceParticle = {
  Reliable = true,
  Params = {
    UEnums.EPropertyClass.Str,
    UEnums.EPropertyClass.UInt64,
    UEnums.EPropertyClass.Float
  }
}
function CreativeModeParticleGeneratorActor:OnRep_InstanceId()
  printf("CreativeModeParticleGeneratorActor:OnRep_InstanceId %s bParticleIsPlaying %s", self.InstanceId, tostring(self.bParticleIsPlaying))
  self:ActivePlayParticle()
end
function CreativeModeParticleGeneratorActor:OnRep_bPlaying()
  printf("CreativeModeParticleGeneratorActor:OnRep_bPlaying %s bParticleIsPlaying %s", self.bPlaying, self.InstanceId, tostring(self.bParticleIsPlaying))
  self:ActivePlayParticle()
end
function CreativeModeParticleGeneratorActor:RPC_PlayParticle(InstanceId, ParticleID, IsLoop, LoopInterval)
  printf(bWriteLog and "CreativeModeParticleGeneratorActor:RPC_PlayParticle %s %s %s", ParticleID, IsLoop, LoopInterval)
  self.InstanceId = InstanceId
  self.ParticleID = ParticleID
  self.bIsLoop = IsLoop
  self.LoopInterval = LoopInterval
  self:StartPlayParticle()
end
function CreativeModeParticleGeneratorActor:RPC_PlayOnceParticle(InstanceId, ParticleID, Duration)
  printf(bWriteLog and "CreativeModeParticleGeneratorActor:RPC_PlayOnceParticle %s %s", ParticleID, Duration)
  self.InstanceId = InstanceId
  self.ParticleID = ParticleID
  self.bIsLoop = false
  self.LoopInterval = Duration
  if 0 < Duration then
    self:StartPlayParticle()
  end
end
function CreativeModeParticleGeneratorActor:StartPlayParticle()
  printf(bWriteLog and "CreativeModeParticleGeneratorActor:StartPlayParticle")
  if UKismetSystemLibrary.IsDedicatedServer(CGameWorld) then
    return
  end
  if slua.isValid(self.ParticleSystem) then
    self.bParticleIsPlaying = true
    self.ParticleSystem:SetVisibility(true, false)
    local ParticleSubsys = SubsystemMgr:Get("CreativeModeParticleSystemSubSystem")
    if not ParticleSubsys then
      return
    end
    if self._CreateParticleHandle then
      ParticleSubsys:CancelCreateParticle(self._CreateParticleHandle)
      self._CreateParticleHandle = nil
    end
    self._CreateParticleHandle = ParticleSubsys:CreateParticleWithComponent(self.ParticleSystem, self.ParticleID, nil, nil, nil, function(ParticleComp)
      self._CreateParticleHandle = nil
      if not slua.isValid(ParticleComp) then
        return
      end
      local ParticleConfig = ParticleSubsys:GetParticleConfigByID(self.ParticleID)
      if ParticleConfig then
        local CreativeModeBlueprintLibrary = import("CreativeModeBlueprintLibrary")
        if ParticleConfig.CullDistance then
          CreativeModeBlueprintLibrary.SetParticleCullingDistance(ParticleComp, ParticleConfig.CullDistance or 500)
        end
        if ParticleConfig.CanChangeColor then
          local InstanceManager = GetInstanceManager()
          local instanceData = InstanceManager and InstanceManager:GetInstance(self.InstanceId)
          if instanceData and instanceData.ParticleGenerator then
            local deviceData = instanceData.ParticleGenerator
            local ColorPreset = deviceData.ColorPreset
            local CustomColor = deviceData.CustomColor and deviceData.CustomColor.overrides or {
              R = 0,
              G = 0,
              B = 0
            }
            local CreativeModeLightDeviceConfig = require("GameLua.Mod.CreativeBase.Gameplay.Config.CreativeModeLightDeviceConfig")
            local LightColor = CreativeModeLightDeviceConfig.GetColor(ColorPreset, CustomColor.R, CustomColor.G, CustomColor.B)
            ParticleComp:SetColorParameter("CrossColor", LightColor)
          end
        end
      end
    end)
    if self.LoopTimerId then
      self:RemoveGameTimer(self.LoopTimerId)
      self.LoopTimerId = nil
    end
    if self.LoopInterval > 0 then
      self.LoopTimerId = self:AddGameTimer(self.LoopInterval, self.bIsLoop, function()
        if slua.isValid(self.ParticleSystem) then
          self.ParticleSystem:Deactivate()
          if self.bIsLoop then
            self.ParticleSystem:Activate(true)
          end
        end
      end)
    end
  end
end
function CreativeModeParticleGeneratorActor:StopPlayParticle()
  if slua.isValid(self.ParticleSystem) then
    self.ParticleSystem:Deactivate()
    self.ParticleSystem:SetVisible(false, false)
  end
  if self._CreateParticleHandle then
    local ParticleSubsys = SubsystemMgr:Get("CreativeModeParticleSystemSubSystem")
    if ParticleSubsys then
      ParticleSubsys:CancelCreateParticle(self._CreateParticleHandle)
    end
    self._CreateParticleHandle = nil
  end
  self:RemoveAllGameTimer()
  self.bParticleIsPlaying = false
end
function CreativeModeParticleGeneratorActor:ActivePlayParticle()
  printf(bWriteLog and "CreativeModeParticleGeneratorActor:ActivePlayParticle")
  if UKismetSystemLibrary.IsDedicatedServer(CGameWorld) then
    return
  end
  if self.InstanceId and self.InstanceId ~= "" and self.bPlaying then
    local InstanceManager = GetInstanceManager()
    if not InstanceManager then
      printf(bWriteLog and "CreativeModeParticleGeneratorActor:ActivePlayParticle InstanceManager is nil")
      return
    end
    local instanceData = InstanceManager:GetInstance(self.InstanceId)
    if instanceData and instanceData.ParticleGenerator then
      local deviceData = instanceData.ParticleGenerator
      self.ParticleID = deviceData.ParticleID
    end
    self:AddGameTimer(3, false, function()
      if not self.bParticleIsPlaying then
        printf(bWriteLog and "CreativeModeParticleGeneratorActor:ActivePlayParticle DoPlay")
        local InstanceManager = GetInstanceManager()
        local instanceData = InstanceManager and InstanceManager:GetInstance(self.InstanceId)
        if instanceData and instanceData.ParticleGenerator then
          local deviceData = instanceData.ParticleGenerator
          self.ParticleID = deviceData.ParticleID
          local ParticleSubsys = SubsystemMgr:Get("CreativeModeParticleSystemSubSystem")
          local ParticleConfig = ParticleSubsys and ParticleSubsys:GetParticleConfigByID(deviceData.ParticleID)
          if not ParticleConfig then
            return
          end
          local IsLoopEffect = true
          if ParticleConfig.IsLoopEffect ~= nil then
            IsLoopEffect = ParticleConfig.IsLoopEffect
          end
          if IsLoopEffect then
            local OnceDuration = deviceData.OnceDuration
            if OnceDuration < 0.1 then
              if ParticleConfig.Duration then
                OnceDuration = ParticleConfig.Duration
              else
                OnceDuration = 600
              end
            end
            self.bIsLoop = false
            self.LoopInterval = OnceDuration
          else
            local Duration = math.max(0.1, ParticleConfig.Duration or 0.1)
            local IsLoop = deviceData.IsLoop
            if IsLoop then
              local LoopInterval = deviceData.LoopInterval
              Duration = math.max(Duration, LoopInterval)
            end
            self.bIsLoop = IsLoop
            self.LoopInterval = Duration
          end
          self:StartPlayParticle()
        end
      end
    end)
  end
end
function CreativeModeParticleGeneratorActor:PlayParticle(InstanceId, ParticleID, IsLoop, LoopInterval)
  printf(bWriteLog and "CreativeModeParticleGeneratorActor:PlayParticle")
  self.InstanceId = InstanceId
  self.bPlaying = true
  self:RPC_PlayParticle(InstanceId, ParticleID, IsLoop, LoopInterval)
end
function CreativeModeParticleGeneratorActor:PlayOnceParticle(InstanceId, ParticleID, Duration)
  printf(bWriteLog and "CreativeModeParticleGeneratorActor:PlayOnceParticle")
  self.InstanceId = InstanceId
  self.bPlaying = true
  self:RPC_PlayOnceParticle(InstanceId, ParticleID, Duration)
end
local class = require("class")
local CActorBase = require("GameLua.Mod.BaseMod.Common.Core.ActorBase")
local CCreativeModeParticleGeneratorActor = class(CActorBase, nil, CreativeModeParticleGeneratorActor)
return require("combine_class").DeclareFeature(CCreativeModeParticleGeneratorActor, {
  {
    SimpleMoveFeature = "GameLua.Mod.CreativeBase.Gameplay.Object.GameObject.LightDevice.CreativeModeSimpleMoveFeature"
  }
}, "CreativeModeParticleGeneratorActor")
