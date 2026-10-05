local CreativeModeCharacterAnimationConfig = require("GameLua.Mod.CreativeBase.Gameplay.Animation.CreativeModeCharacterAnimationConfig")
local AnimationUtility = require("GameLua.Mod.CreativeBase.Gameplay.Animation.CreativeModeCharacterAnimationUtility")
local CreativeSkeletalModelPresetConfig = require("GameLua.Mod.CreativeBase.Gameplay.Animation.CreativeSkeletalModelPresetConfig")
local CustomAssetSkeletalMeshDefine = require("common.CustomAsset.CustomSkeletalMesh.CustomAssetSkeletalMeshDefine")
local EPresetKind = CreativeSkeletalModelPresetConfig.EPresetKind
local EOfficialSkeletonPreset = CustomAssetSkeletalMeshDefine.EOfficialSkeletonPreset
local CreativeUserSkeletalMeshComponentImplFunc = function(RootBaseClass)
  local CreativeUserSkeletalMeshComponent = {
    MulticastRPC = {}
  }
  local SECTION_KEY = "SkeletalMeshComponent"
  local CreativeUserMeshComponentImplFunc = require("GameLua.Mod.CreativeBase.Gameplay.Component.CreativeComponent.CreativeUserMeshComponentImpl")
  local CMeshComponent = CreativeUserMeshComponentImplFunc(RootBaseClass)
  local EAnimationMode = CreativeModeCharacterAnimationConfig.EAnimationMode
  local EAnimInstancePreset = CreativeModeCharacterAnimationConfig.EAnimInstancePreset
  local EAnimInstanceSource = CreativeModeCharacterAnimationConfig.EAnimInstanceSource
  local AnimInstancePresetRegistry = CreativeModeCharacterAnimationConfig.AnimInstancePresetRegistry
  local EAnimSlotKey = CreativeModeCharacterAnimationConfig.EAnimSlotKey
  local PresetToKeyName = {}
  for KeyName, PresetValue in pairs(EAnimInstancePreset) do
    PresetToKeyName[PresetValue] = KeyName
  end
  local NormalizePresetID = function(PresetRef)
    if PresetRef == nil or PresetRef == "" or PresetRef == 0 or PresetRef == "0" then
      return 0
    end
    if type(PresetRef) == "number" then
      return PresetRef
    end
    if type(PresetRef) == "string" then
      local AsNum = tonumber(PresetRef)
      if AsNum ~= nil and tostring(AsNum) == PresetRef then
        return AsNum
      end
      return PresetRef
    end
    return 0
  end
  local ToPresetStr = function(PresetRef)
    if PresetRef == nil or PresetRef == "" or PresetRef == 0 or PresetRef == "0" then
      return ""
    end
    if type(PresetRef) == "number" then
      return tostring(PresetRef)
    end
    if type(PresetRef) == "string" then
      return PresetRef
    end
    return tostring(PresetRef)
  end
  function CreativeUserSkeletalMeshComponent:ctor()
    self.nPlayRate = 1
    self.nMeshPresetID = ""
    self.nSkeletonType = 0
    self.nAnimationMode = 0
    self.nAnimInstanceSource = 0
    self.nInstancePreset = 0
    self.nCustomAnimBPID = ""
    self.nSingleAnimPresetID = ""
    self.nIdleAnimPresetID = ""
    self.nWalkAnimPresetID = ""
    self.nRunAnimPresetID = ""
    self.nLandAnimPresetID = ""
    self.nBirthAnimPresetID = ""
    self.nLoopAnimPresetID = ""
  end
  local SlotKeyToSelfKey = {
    [EAnimSlotKey.Idle] = "nIdleAnimPresetID",
    [EAnimSlotKey.Walk] = "nWalkAnimPresetID",
    [EAnimSlotKey.Run] = "nRunAnimPresetID",
    [EAnimSlotKey.Land] = "nLandAnimPresetID",
    [EAnimSlotKey.Birth] = "nBirthAnimPresetID",
    [EAnimSlotKey.Loop] = "nLoopAnimPresetID"
  }
  local PENDING_WARN_DELAY = 8
  local PENDING_RETRY_DELAY = 10
  local ApplySkeletalMesh = function(Object, PresetID, IsCurrent, Component)
    PresetID = NormalizePresetID(PresetID)
    if PresetID == 0 then
      if slua.isValid(Object) and Object.SetSkeletalMesh then
        Object:SetSkeletalMesh(nil, true)
      end
      return
    end
    local bLoadSettled = false
    local bRetried = false
    local ApplyMesh = function(MeshAsset)
      bLoadSettled = true
      if (IsCurrent == nil or IsCurrent()) and slua.isValid(Object) and slua.isValid(MeshAsset) then
        Object:SetSkeletalMesh(MeshAsset, true)
        if Component then
          Component:_TryApplyAnimationFromSnapshot()
        end
      end
    end
    local DoLoad = function()
      CreativeSkeletalModelPresetConfig.AsyncLoadByPresetID(EPresetKind.Mesh, PresetID, "SkeletalMesh", ApplyMesh)
    end
    DoLoad()
    if Component ~= nil and Component.AddGameTimer ~= nil then
      Component:AddGameTimer(PENDING_WARN_DELAY, false, function()
        if not (not bLoadSettled and slua.isValid(Object)) or bRetried then
          return
        end
        bRetried = true
        DoLoad()
        Component:AddGameTimer(PENDING_RETRY_DELAY, false, function()
          if bLoadSettled or not slua.isValid(Object) then
            return
          end
          local AssetPath = CreativeSkeletalModelPresetConfig.ResolveAssetPath(EPresetKind.Mesh, PresetID)
          if type(AssetPath) ~= "string" or AssetPath == "" then
            return
          end
          ApplyMesh(slua.loadObject(AssetPath))
        end)
      end)
    end
  end
  local PlayAnimSequenceAsMontage = function(Object, AnimationAsset)
    local AnimInstance = Object.GetAnimInstance ~= nil and Object:GetAnimInstance() or nil
    if slua.isValid(AnimInstance) and AnimInstance.PlayCreativeDynamicMontage then
      AnimInstance:PlayCreativeDynamicMontage(AnimationAsset, 0.25, 0.25, 1, 1, false, 0, "None")
      return
    end
  end
  local ApplySingleAnimation = function(Component, PresetID)
    PresetID = NormalizePresetID(PresetID)
    if PresetID == 0 then
      return
    end
    local Object = Component and Component.Object
    if not slua.isValid(Object) then
      return
    end
    CreativeSkeletalModelPresetConfig.AsyncLoadByPresetID(EPresetKind.Anim, PresetID, "SingleAnimation", function(AnimationAsset)
      if not slua.isValid(Object) or not slua.isValid(AnimationAsset) then
        return
      end
      if Component.nAnimationMode == EAnimationMode.SingleAnimation then
        if Object.PlayAnimation ~= nil then
          Object:PlayAnimation(AnimationAsset, true)
        elseif Object.SetAnimation ~= nil then
          Object:SetAnimation(AnimationAsset)
          if Object.Play ~= nil then
            Object:Play(true)
          end
        end
        if Object.SetPlayRate ~= nil then
          Object:SetPlayRate(Component.nPlayRate or 1)
        end
      else
        PlayAnimSequenceAsMontage(Object, AnimationAsset)
      end
    end)
  end
  local ApplyCustomAnimBP = function(Object, CustomAnimBPID)
    CustomAnimBPID = NormalizePresetID(CustomAnimBPID)
    if CustomAnimBPID == 0 then
      return
    end
    local TemplateClassPath = CreativeModeCharacterAnimationConfig.CustomAnimBPInstanceTemplateClassPath
    if TemplateClassPath == nil or TemplateClassPath == "" then
      print("CreativeUserSkeletalMeshComponent.ApplyCustomAnimBP - CustomAnimBP template class path not configured")
      return
    end
    local TemplateClass
    if slua.loadClass ~= nil then
      TemplateClass = slua.loadClass(TemplateClassPath)
    else
      TemplateClass = slua.loadObject(TemplateClassPath)
    end
    if TemplateClass == nil then
      print("CreativeUserSkeletalMeshComponent.ApplyCustomAnimBP - load template class failed, path=" .. tostring(TemplateClassPath))
      return
    end
    if Object.SetAnimationMode ~= nil then
      Object:SetAnimationMode(2)
    end
    if Object.SetAnimInstanceClass ~= nil then
      Object:SetAnimInstanceClass(TemplateClass)
    end
    if slua.isValid(CustomAssetMgr) and CustomAssetMgr.AsyncLoadCustomAsset ~= nil then
      CustomAssetMgr:AsyncLoadCustomAsset(CustomAnimBPID, function(MetaObject)
        if not slua.isValid(Object) or not slua.isValid(MetaObject) then
          return
        end
        local AnimInstance = Object.GetAnimInstance ~= nil and Object:GetAnimInstance() or nil
        if not slua.isValid(AnimInstance) then
          print("CreativeUserSkeletalMeshComponent.ApplyCustomAnimBP - AnimInstance invalid after SetAnimInstanceClass")
          return
        end
        if AnimInstance.InitFromCustomMeta ~= nil then
          AnimInstance:InitFromCustomMeta(MetaObject)
        else
          print("CreativeUserSkeletalMeshComponent.ApplyCustomAnimBP - AnimInstance.InitFromCustomMeta not implemented yet, meta ignored")
        end
      end)
    else
      print("CreativeUserSkeletalMeshComponent.ApplyCustomAnimBP - CustomAssetMgr unavailable")
    end
  end
  local ApplyAnimationInstance = function(Object, SkeletonType, InstancePreset, SlotSnapshot)
    local PresetCfg = AnimInstancePresetRegistry[InstancePreset]
    if PresetCfg == nil then
      print("CreativeUserSkeletalMeshComponent.ApplyAnimationInstance - unknown InstancePreset=" .. tostring(InstancePreset) .. ", skip")
      return
    end
    local OfficialSkeletonPreset = SkeletonType
    if OfficialSkeletonPreset == nil then
      print("CreativeUserSkeletalMeshComponent.ApplyAnimationInstance - unsupported SkeletonType=" .. tostring(SkeletonType) .. ", skip")
      return
    end
    local AnimBPClassPath = PresetCfg.AnimBPClassPathByPreset and PresetCfg.AnimBPClassPathByPreset[OfficialSkeletonPreset]
    if AnimBPClassPath == nil or AnimBPClassPath == "" then
      print("CreativeUserSkeletalMeshComponent.ApplyAnimationInstance - AnimBP path missing for preset=" .. tostring(InstancePreset) .. " skeleton=" .. tostring(OfficialSkeletonPreset))
      return
    end
    local AnimBPClass
    if slua.loadClass ~= nil then
      AnimBPClass = slua.loadClass(AnimBPClassPath)
    else
      AnimBPClass = slua.loadObject(AnimBPClassPath)
    end
    if AnimBPClass == nil then
      print("CreativeUserSkeletalMeshComponent.ApplyAnimationInstance - load AnimBP class failed, path=" .. tostring(AnimBPClassPath))
      return
    end
    if Object.SetAnimationMode ~= nil then
      Object:SetAnimationMode(2)
    end
    if Object.SetAnimInstanceClass ~= nil then
      Object:SetAnimInstanceClass(AnimBPClass)
    end
    local SlotKeyToPreset
    for _, Slot in ipairs(PresetCfg.Slots or {}) do
      local PresetID = SlotSnapshot and SlotSnapshot[Slot.Key] or nil
      local PresetRef = NormalizePresetID(PresetID)
      if PresetRef ~= 0 then
        SlotKeyToPreset = SlotKeyToPreset or {}
        SlotKeyToPreset[Slot.Key] = PresetRef
      end
    end
    if SlotKeyToPreset == nil then
      return
    end
    local AnimInstance = Object.GetAnimInstance ~= nil and Object:GetAnimInstance() or nil
    if not slua.isValid(AnimInstance) then
      print("CreativeUserSkeletalMeshComponent.ApplyAnimationInstance - AnimInstance invalid, skip override")
      return
    end
    AnimationUtility.ApplyStateAnimSequenceOverride(AnimInstance, SlotKeyToPreset)
  end
  function CreativeUserSkeletalMeshComponent.ComponentConstruction(Object, ComponentConfig, Options)
    if ComponentConfig == nil then
      return
    end
    if not slua.isValid(Object) then
      print("CreativeUserSkeletalMeshComponent.ComponentConstruction - Object is invalid, skip")
      return
    end
    CMeshComponent.ComponentConstruction(Object, ComponentConfig, Options)
    local SectionConfig = ComponentConfig[SECTION_KEY]
    if SectionConfig == nil then
      return
    end
    local SkeletalMeshData = SectionConfig.SkeletalMesh
    if SkeletalMeshData ~= nil then
      ApplySkeletalMesh(Object, SkeletalMeshData.MeshPresetID)
    end
  end
  function CreativeUserSkeletalMeshComponent:PostComponentConstruction(ComponentConfig, Options)
    CreativeUserSkeletalMeshComponent.__super.PostComponentConstruction(self, ComponentConfig, Options)
    local SectionConfig = ComponentConfig and ComponentConfig[SECTION_KEY]
    if SectionConfig == nil then
      return
    end
    local SkeletalMeshData = SectionConfig.SkeletalMesh
    self.nMeshPresetID = SkeletalMeshData and ToPresetStr(SkeletalMeshData.MeshPresetID) or ""
    self.nSkeletonType = tonumber(SectionConfig.SkeletonType) or 0
    self.nDriverMode = tonumber(SectionConfig.DriverMode) or 0
    self.nAnimationMode = tonumber(SectionConfig.AnimationMode) or 0
    local SingleAnim = SectionConfig.SingleAnimation
    self.nSingleAnimPresetID = SingleAnim and ToPresetStr(SingleAnim.AnimationPresetID) or ""
    self.nAnimInstanceSource = tonumber(SectionConfig.AnimInstanceSource) or 0
    self.nInstancePreset = tonumber(SectionConfig.AnimInstancePreset) or 0
    self.nCustomAnimBPID = ToPresetStr(SectionConfig.CustomAnimBPID)
    for PresetValue, PresetCfg in pairs(AnimInstancePresetRegistry) do
      local KeyName = PresetToKeyName[PresetValue]
      local SlotsStruct = KeyName and SectionConfig["Slots_" .. KeyName]
      if SlotsStruct ~= nil then
        for _, Slot in ipairs(PresetCfg.Slots or {}) do
          local SelfKey = SlotKeyToSelfKey[Slot.Key]
          if SelfKey ~= nil then
            self[SelfKey] = ToPresetStr(SlotsStruct[Slot.Key])
          end
        end
      end
    end
  end
  function CreativeUserSkeletalMeshComponent:GetLifetimeReplicatedProps()
    local ELifetimeCondition = import("ELifetimeCondition")
    local RepTable = {
      {
        "nPlayRate",
        ELifetimeCondition.COND_None,
        UEnums.EPropertyClass.Float
      },
      {
        "nMeshPresetID",
        ELifetimeCondition.COND_None,
        UEnums.EPropertyClass.Str
      },
      {
        "nSkeletonType",
        ELifetimeCondition.COND_None,
        UEnums.EPropertyClass.UInt32
      },
      {
        "nAnimationMode",
        ELifetimeCondition.COND_None,
        UEnums.EPropertyClass.UInt32
      },
      {
        "nAnimInstanceSource",
        ELifetimeCondition.COND_None,
        UEnums.EPropertyClass.UInt32
      },
      {
        "nInstancePreset",
        ELifetimeCondition.COND_None,
        UEnums.EPropertyClass.UInt32
      },
      {
        "nCustomAnimBPID",
        ELifetimeCondition.COND_None,
        UEnums.EPropertyClass.Str
      },
      {
        "nSingleAnimPresetID",
        ELifetimeCondition.COND_None,
        UEnums.EPropertyClass.Str
      },
      {
        "nIdleAnimPresetID",
        ELifetimeCondition.COND_None,
        UEnums.EPropertyClass.Str
      },
      {
        "nWalkAnimPresetID",
        ELifetimeCondition.COND_None,
        UEnums.EPropertyClass.Str
      },
      {
        "nRunAnimPresetID",
        ELifetimeCondition.COND_None,
        UEnums.EPropertyClass.Str
      },
      {
        "nLandAnimPresetID",
        ELifetimeCondition.COND_None,
        UEnums.EPropertyClass.Str
      },
      {
        "nBirthAnimPresetID",
        ELifetimeCondition.COND_None,
        UEnums.EPropertyClass.Str
      },
      {
        "nLoopAnimPresetID",
        ELifetimeCondition.COND_None,
        UEnums.EPropertyClass.Str
      }
    }
    if CreativeUserSkeletalMeshComponent.__super.GetLifetimeReplicatedProps then
      local BaseRepTable = CreativeUserSkeletalMeshComponent.__super.GetLifetimeReplicatedProps(self)
      table.move(BaseRepTable, 1, #BaseRepTable, #RepTable + 1, RepTable)
    end
    return RepTable
  end
  function CreativeUserSkeletalMeshComponent:_TryApplyMeshFromSnapshot()
    if not slua.isValid(self.Object) then
      return
    end
    local PresetStr = self.nMeshPresetID
    ApplySkeletalMesh(self.Object, PresetStr, function()
      return self.nMeshPresetID == PresetStr
    end, self)
  end
  function CreativeUserSkeletalMeshComponent:OnRep_nMeshPresetID(OldValue)
    self:_TryApplyMeshFromSnapshot()
  end
  function CreativeUserSkeletalMeshComponent:_TryApplyAnimationFromSnapshot()
    if not slua.isValid(self.Object) then
      return
    end
    if self.nAnimationMode == EAnimationMode.SingleAnimation then
      if self.Object.SetAnimationMode ~= nil then
        self.Object:SetAnimationMode(1)
      end
      ApplySingleAnimation(self, self.nSingleAnimPresetID)
    elseif self.nAnimationMode == EAnimationMode.AnimationInstance then
      if self.nAnimInstanceSource == EAnimInstanceSource.CustomABP then
        ApplyCustomAnimBP(self.Object, self.nCustomAnimBPID)
      else
        local SlotSnapshot = {}
        for SlotKey, SelfKey in pairs(SlotKeyToSelfKey) do
          SlotSnapshot[SlotKey] = self[SelfKey]
        end
        ApplyAnimationInstance(self.Object, self.nSkeletonType, self.nInstancePreset, SlotSnapshot)
      end
    end
  end
  function CreativeUserSkeletalMeshComponent:OnRep_nSkeletonType(OldValue)
    self:_TryApplyAnimationFromSnapshot()
  end
  function CreativeUserSkeletalMeshComponent:OnRep_nAnimationMode(OldValue)
    self:_TryApplyAnimationFromSnapshot()
  end
  function CreativeUserSkeletalMeshComponent:OnRep_nAnimInstanceSource(OldValue)
    self:_TryApplyAnimationFromSnapshot()
  end
  function CreativeUserSkeletalMeshComponent:OnRep_nInstancePreset(OldValue)
    self:_TryApplyAnimationFromSnapshot()
  end
  function CreativeUserSkeletalMeshComponent:OnRep_nCustomAnimBPID(OldValue)
    self:_TryApplyAnimationFromSnapshot()
  end
  function CreativeUserSkeletalMeshComponent:OnRep_nSingleAnimPresetID(OldValue)
    self:_TryApplyAnimationFromSnapshot()
  end
  function CreativeUserSkeletalMeshComponent:OnRep_nIdleAnimPresetID(OldValue)
    self:_TryApplyAnimationFromSnapshot()
  end
  function CreativeUserSkeletalMeshComponent:OnRep_nWalkAnimPresetID(OldValue)
    self:_TryApplyAnimationFromSnapshot()
  end
  function CreativeUserSkeletalMeshComponent:OnRep_nRunAnimPresetID(OldValue)
    self:_TryApplyAnimationFromSnapshot()
  end
  function CreativeUserSkeletalMeshComponent:OnRep_nLandAnimPresetID(OldValue)
    self:_TryApplyAnimationFromSnapshot()
  end
  function CreativeUserSkeletalMeshComponent:OnRep_nBirthAnimPresetID(OldValue)
    self:_TryApplyAnimationFromSnapshot()
  end
  function CreativeUserSkeletalMeshComponent:OnRep_nLoopAnimPresetID(OldValue)
    self:_TryApplyAnimationFromSnapshot()
  end
  function CreativeUserSkeletalMeshComponent:SetPlayRateLocal(Rate)
    if not slua.isValid(self.Object) then
      return
    end
    if self.Object.GlobalAnimRateScale ~= nil then
      self.Object.GlobalAnimRateScale = Rate
    end
    if self.Object.SetPlayRate ~= nil then
      self.Object:SetPlayRate(Rate)
    end
  end
  function CreativeUserSkeletalMeshComponent:OnRep_nPlayRate(OldValue)
    self:SetPlayRateLocal(self.nPlayRate)
  end
  function CreativeUserSkeletalMeshComponent:SetBasicLoopAnim(Anim)
    local PresetStr = ToPresetStr(Anim)
    if self.nAnimationMode == EAnimationMode.SingleAnimation then
      self.nSingleAnimPresetID = PresetStr
    elseif self.nAnimationMode == EAnimationMode.AnimationInstance then
      self.nInstancePreset = EAnimInstancePreset.BasicLoop
      self.nLoopAnimPresetID = PresetStr
    end
    self:_TryApplyAnimationFromSnapshot()
  end
  function CreativeUserSkeletalMeshComponent:CreativeSetSkeletalMesh(MeshAsset)
    if self:IsDedicatedServer() then
      self.nMeshPresetID = ToPresetStr(MeshAsset)
      self:_TryApplyMeshFromSnapshot()
    else
      ApplySkeletalMesh(self.Object, MeshAsset, nil, self)
    end
  end
  function CreativeUserSkeletalMeshComponent:CreativePlayAnimation(Anim)
    if self:IsDedicatedServer() then
      self:MulticastRPC_PlayAnimationByPresetID(ToPresetStr(Anim))
    else
      ApplySingleAnimation(self, Anim)
    end
  end
  CreativeUserSkeletalMeshComponent.MulticastRPC.MulticastRPC_PlayAnimationByPresetID = {
    Reliable = true,
    Params = {
      UEnums.EPropertyClass.Str
    }
  }
  function CreativeUserSkeletalMeshComponent:MulticastRPC_PlayAnimationByPresetID(PresetIDStr)
    ApplySingleAnimation(self, PresetIDStr)
  end
  function CreativeUserSkeletalMeshComponent:CreativeSetPlayRate(Rate)
    self.nPlayRate = Rate
    self:SetPlayRateLocal(Rate)
  end
  function CreativeUserSkeletalMeshComponent:OnReceiveBeginPlay()
    CreativeUserSkeletalMeshComponent.__super.OnReceiveBeginPlay(self)
    print(bWriteLog and "CreativeUserSkeletalMeshComponent:OnReceiveBeginPlay")
    self:_TryApplyMeshFromSnapshot()
    self:SetPlayRateLocal(self.nPlayRate)
  end
  function CreativeUserSkeletalMeshComponent:OnReceiveEndPlay()
    print(bWriteLog and "CreativeUserSkeletalMeshComponent:OnReceiveEndPlay")
    CreativeUserSkeletalMeshComponent.__super.OnReceiveEndPlay(self)
  end
  local class = require("class")
  local CCreativeUserSkeletalMeshComponent = class(CMeshComponent, nil, CreativeUserSkeletalMeshComponent)
  return CCreativeUserSkeletalMeshComponent
end
return CreativeUserSkeletalMeshComponentImplFunc
