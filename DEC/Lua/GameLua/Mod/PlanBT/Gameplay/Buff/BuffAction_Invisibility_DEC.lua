local GameplayData = require("GameLua.GameCore.Data.GameplayData")
local EPawnState = import("EPawnState")
local BuffAction_Invisibility = {
  sObjectName = "BuffAction_Invisibility"
}
function BuffAction_Invisibility:ctor(selfType)
  self.bAvatarReloadHookBound = false
  self.CachedInkMaterial = nil
end
function BuffAction_Invisibility:LuaOnInitialize()
  print(bWriteLog and string.format("%s:LuaOnInitialize", self.sObjectName))
end
function BuffAction_Invisibility:LuaOnExecute()
  print(bWriteLog and "BuffAction_Invisibility:LuaOnExecute")
  local OwnerPawn = self:GetOwner()
  if not slua.isValid(OwnerPawn) then
    return
  end
  OwnerPawn.HasInvisibilityBuff = true
  if Client then
    self.CachedFootstepSound = OwnerPawn.FootstepSound
    OwnerPawn.FootstepSound = nil
    self:ManageHeart(false)
  end
  OwnerPawn.voiceCheckEnable = false
  self:SetPetEnable(OwnerPawn, false)
  OwnerPawn.bEnableFootprint = false
  self:StopMutexBuffs()
  self:ApplyInvisibilityMaterial(OwnerPawn)
  if OwnerPawn:HasAuthority() then
    self:AddControlEvent(OwnerPawn, "OnTakeDamageDynamicDelegate", self.HandleOnTakeDamage, self)
    self:AddControlEvent(OwnerPawn, "StateEnterHandler", self.HandleOnEnterState, self)
    self:AddControlEvent(OwnerPawn, "OnHandleSkillStartDelegate", self.OnSkillStarted, self)
  end
  if Client then
    self:BindAvatarReloadHook(OwnerPawn)
    GameplayData.AddSelfPlayerControllerEvent(self, "OnSpectatorChange", self.OnSpectatorChange, self)
  elseif OwnerPawn.SetInInvisibilityBuff then
    OwnerPawn:SetInInvisibilityBuff(true)
  end
end
function BuffAction_Invisibility:ManageHeart(bForceUnhide)
end
local SAME_TEAM_MATERIAL_PATH = "/Game/Arts/Common/MasterMaterials/Character_Buff/MI_Buff_Hide.MI_Buff_Hide"
local ENEMY_MATERIAL_PATH = "/Game/Mod/PlanBT/Arts_Effect/Mat/M_TF_AirDistortion.M_TF_AirDistortion"
function BuffAction_Invisibility:ApplyInvisibilityMaterial(OwnerPawn, bUnhideMask)
  print(bWriteLog and string.format("BuffAction_Invisibility:ApplyInvisibilityMaterial - bUnhideMask=%s", tostring(bUnhideMask)))
  if not slua.isValid(OwnerPawn) then
    print(bWriteLog and "BuffAction_Invisibility:ApplyInvisibilityMaterial - invalid OwnerPawn, skip")
    return
  end
  local PC = GameplayData.GetPlayerController()
  local bPetSpectator = slua.isValid(PC) and PC:IsInPetSpectator()
  local LocalChar = GameplayData.GetLocalCharacter()
  if not slua.isValid(LocalChar) and not bPetSpectator then
    print(bWriteLog and "BuffAction_Invisibility:ApplyInvisibilityMaterial - no valid LocalChar and not PetSpectator, skip")
    return
  end
  if self.AsyncLoadID then
    self:CancelAsyncLoad(self.AsyncLoadID)
    self.AsyncLoadID = nil
  end
  local bSameTeam = OwnerPawn:IsSameTeam(LocalChar) or bPetSpectator
  local MaterialPath = bSameTeam and SAME_TEAM_MATERIAL_PATH or ENEMY_MATERIAL_PATH
  self.AsyncLoadID = self:AsyncLoadAsset(MaterialPath, function(Material)
    if slua.isValid(Material) and slua.isValid(OwnerPawn) then
      OwnerPawn:ChangeAllAvatarMaterialToFeatureMaterial(Material)
      self.CachedInkMaterial = Material
    end
    self.AsyncLoadID = nil
  end)
  if bSameTeam and bUnhideMask then
    OwnerPawn:SetActorHiddenInGameMask(false, 2)
  end
end
function BuffAction_Invisibility:OnSpectatorChange()
  local OwnerPawn = self:GetOwner()
  if not slua.isValid(OwnerPawn) then
    return
  end
  self:ApplyInvisibilityMaterial(OwnerPawn, true)
  if Client then
    self:ManageHeart(false)
  elseif OwnerPawn.SetInInvisibilityBuff then
    OwnerPawn:SetInInvisibilityBuff(true)
  end
end
function BuffAction_Invisibility:LuaOnEnd()
  print(bWriteLog and "BuffAction_Invisibility:LuaOnEnd")
  local OwnerPawn = self:GetOwner()
  if not slua.isValid(OwnerPawn) then
    return
  end
  OwnerPawn.HasInvisibilityBuff = false
  if Client then
    OwnerPawn.FootstepSound = self.CachedFootstepSound
    self.CachedFootstepSound = nil
    self:ManageHeart(true)
  elseif OwnerPawn.SetInInvisibilityBuff then
    OwnerPawn:SetInInvisibilityBuff(false)
  end
  OwnerPawn.voiceCheckEnable = true
  self:SetPetEnable(OwnerPawn, true)
  OwnerPawn.bEnableFootprint = true
  if self.AsyncLoadID then
    self:CancelAsyncLoad(self.AsyncLoadID)
    self.AsyncLoadID = nil
  end
  OwnerPawn:ClearAllAvatarFeatureMaterial()
  if OwnerPawn:HasAuthority() then
    self:RemoveControlEvent(OwnerPawn, "OnTakeDamageDynamicDelegate")
    self:RemoveControlEvent(OwnerPawn, "StateEnterHandler")
    self:RemoveControlEvent(OwnerPawn, "OnHandleSkillStartDelegate")
  end
  self.bAvatarReloadHookBound = false
  self.CachedInkMaterial = nil
end
function BuffAction_Invisibility:BindAvatarReloadHook(uOwnerPawn)
  if self.bAvatarReloadHookBound then
    print(bWriteLog and "BuffAction_Invisibility:BindAvatarReloadHook - already bound, skip")
    return
  end
  if not slua.isValid(uOwnerPawn) then
    print(bWriteLog and "BuffAction_Invisibility:BindAvatarReloadHook - invalid OwnerPawn, skip")
    return
  end
  if not self.AddControlEvent then
    print(bWriteLog and "BuffAction_Invisibility:BindAvatarReloadHook - AddControlEvent unavailable, skip")
    return
  end
  if uOwnerPawn.getAvatarComponent2 then
    local uAvatarComp = uOwnerPawn:getAvatarComponent2()
    if slua.isValid(uAvatarComp) then
      self:AddControlEvent(uAvatarComp, "OnAvatarAllMeshLoaded", self.OnCharacterMeshLoaded, self)
      print(bWriteLog and "BuffAction_Invisibility:BindAvatarReloadHook - hook bound")
    end
  end
  if uOwnerPawn.GetWeaponManager then
    local uWeaponManager = uOwnerPawn:GetWeaponManager()
    if slua.isValid(uWeaponManager) and uWeaponManager.GetAllInventoryWeaponList then
      local tAllWeapons = uWeaponManager:GetAllInventoryWeaponList(false)
      if tAllWeapons then
        for i = 0, tAllWeapons:Num() - 1 do
          local uWeapon = tAllWeapons:Get(i)
          if slua.isValid(uWeapon) then
            if slua.isValid(uWeapon.WeaponAvatarComponent) and slua.isValid(uWeapon.WeaponAvatarComponent.OnAvatarAllMeshLoaded) then
              self:AddControlEvent(uWeapon.WeaponAvatarComponent, "OnAvatarAllMeshLoaded", self.OnWeaponMeshLoaded, self)
            end
            if slua.isValid(uWeapon.GrenadeAvatarComponent) and slua.isValid(uWeapon.GrenadeAvatarComponent.OnAvatarAllMeshLoaded) then
              self:AddControlEvent(uWeapon.GrenadeAvatarComponent, "OnAvatarAllMeshLoaded", self.OnWeaponMeshLoaded, self)
            end
            if slua.isValid(uWeapon.SlaveWeapon) and slua.isValid(uWeapon.SlaveWeapon.WeaponAvatarComponent) and slua.isValid(uWeapon.SlaveWeapon.WeaponAvatarComponent.OnAvatarAllMeshLoaded) then
              self:AddControlEvent(uWeapon.SlaveWeapon.WeaponAvatarComponent, "OnAvatarAllMeshLoaded", self.OnWeaponMeshLoaded, self)
            end
          end
        end
      end
    end
  end
  self.bAvatarReloadHookBound = true
end
function BuffAction_Invisibility:OnCharacterMeshLoaded()
  local uOwnerPawn = self:GetOwner()
  if not slua.isValid(uOwnerPawn) then
    print(bWriteLog and "BuffAction_Invisibility:OnCharacterMeshLoaded - invalid OwnerPawn, skip")
    return
  end
  if not uOwnerPawn.HasInvisibilityBuff then
    print(bWriteLog and "BuffAction_Invisibility:OnCharacterMeshLoaded - HasInvisibilityBuff is false, skip")
    return
  end
  print(bWriteLog and "BuffAction_Invisibility:OnCharacterMeshLoaded")
  if slua.isValid(self.CachedInkMaterial) and uOwnerPawn.getAvatarComponent2 then
    local uAvatarComp = uOwnerPawn:getAvatarComponent2()
    if slua.isValid(uAvatarComp) and uAvatarComp.ChangeAllMeshToFeatureMaterial then
      print(bWriteLog and "BuffAction_Invisibility:OnCharacterMeshLoaded - apply material")
      uAvatarComp:ChangeAllMeshToFeatureMaterial(self.CachedInkMaterial)
    end
  end
end
function BuffAction_Invisibility:OnWeaponMeshLoaded()
  local uOwnerPawn = self:GetOwner()
  if not slua.isValid(uOwnerPawn) then
    print(bWriteLog and "BuffAction_Invisibility:OnWeaponMeshLoaded - invalid OwnerPawn, skip")
    return
  end
  if not uOwnerPawn.HasInvisibilityBuff then
    print(bWriteLog and "BuffAction_Invisibility:OnWeaponMeshLoaded - HasInvisibilityBuff is false, skip")
    return
  end
  print(bWriteLog and "BuffAction_Invisibility:OnWeaponMeshLoaded")
  if slua.isValid(self.CachedInkMaterial) and uOwnerPawn.GetWeaponManager then
    local uWeaponManager = uOwnerPawn:GetWeaponManager()
    if slua.isValid(uWeaponManager) and uWeaponManager.GetAllInventoryWeaponList then
      local tAllWeapons = uWeaponManager:GetAllInventoryWeaponList(false)
      if tAllWeapons then
        for i = 0, tAllWeapons:Num() - 1 do
          local uWeapon = tAllWeapons:Get(i)
          if slua.isValid(uWeapon) then
            if slua.isValid(uWeapon.WeaponAvatarComponent) then
              uWeapon.WeaponAvatarComponent:ChangeAllMeshToFeatureMaterial(self.CachedInkMaterial)
            end
            if slua.isValid(uWeapon.GrenadeAvatarComponent) then
              uWeapon.GrenadeAvatarComponent:ChangeAllMeshToFeatureMaterial(self.CachedInkMaterial)
            end
            if slua.isValid(uWeapon.SlaveWeapon) and slua.isValid(uWeapon.SlaveWeapon.WeaponAvatarComponent) then
              uWeapon.SlaveWeapon.WeaponAvatarComponent:ChangeAllMeshToFeatureMaterial(self.CachedInkMaterial)
            end
          end
        end
      end
      print(bWriteLog and "BuffAction_Invisibility:OnWeaponMeshLoaded - apply material")
    end
  end
end
function BuffAction_Invisibility:SetPetEnable(uPlayer, bEnable)
  if slua.isValid(uPlayer) then
    print(bWriteLog and "BuffAction_Invisibility:SetPetEnable bEnable:", bEnable, " uPlayer:", uPlayer)
    if uPlayer.PetComponent_BP then
      if bEnable then
        uPlayer.PetComponent_BP:SetPetActorHiddenInGameMask(false, 3)
      else
        uPlayer.PetComponent_BP:SetPetActorHiddenInGameMask(true, 3)
      end
    end
  end
end
local IllegalStates = {
  EPawnState.InParachute,
  EPawnState.Dying,
  EPawnState.Dead,
  EPawnState.Swim,
  EPawnState.DriveVehicle,
  EPawnState.InVehicle,
  EPawnState.BeCarriedBack,
  EPawnState.InZipline,
  EPawnState.Diving,
  EPawnState.CarryBack,
  EPawnState.GunFire,
  EPawnState.MeleeAttack,
  EPawnState.HoldGrenade,
  EPawnState.UseConsumables,
  EPawnState.Save
}
function BuffAction_Invisibility:HandleOnEnterState(State)
  print(bWriteLog and string.format("BuffAction_Invisibility:HandleOnEnterState %s", tostring(State)))
  local OwnerPawn = self:GetOwner()
  if not slua.isValid(OwnerPawn) then
    return
  end
  for _, S in ipairs(IllegalStates) do
    if S == State then
      print(bWriteLog and string.format("BuffAction_Invisibility:HandleOnEnterState illegal state, remove buff"))
      self:StopBuff()
      return
    end
  end
end
function BuffAction_Invisibility:HandleOnTakeDamage(FinalDamage, uDamageEvent, uHitCharacter, uAttackCharacter, uExtraInfo)
  if uExtraInfo.DamageTypeId == 13 and not uExtraInfo.DamageToDying and not uExtraInfo.DamageToDead then
    return
  end
  if slua.isValid(uHitCharacter) then
    print(bWriteLog and "BuffAction_Invisibility:HandleOnTakeDamage")
    self:StopBuff()
  end
end
function BuffAction_Invisibility:OnSkillStarted(Character, SkillId)
  print(bWriteLog and string.format("BuffAction_Invisibility:OnSkillStarted illegal SkillId %d, remove buff", SkillId))
  self:StopBuff()
end
function BuffAction_Invisibility:StopBuff()
  print(bWriteLog and "BuffAction_Invisibility:StopBuff")
  local OwnerPawn = self:GetOwner()
  if not slua.isValid(OwnerPawn) then
    return
  end
  OwnerPawn:RemoveBuffByID(450901, nil, -1, 0)
end
local MutexBuffIDs = {450911}
function BuffAction_Invisibility:StopMutexBuffs()
  print(bWriteLog and "BuffAction_Invisibility:StopMutexBuffs")
  local OwnerPawn = self:GetOwner()
  if not slua.isValid(OwnerPawn) then
    return
  end
  if not OwnerPawn.RemoveBuffByID then
    return
  end
  for _, BuffID in ipairs(MutexBuffIDs) do
    OwnerPawn:RemoveBuffByID(BuffID, nil, -1, 0)
  end
end
local class = require("GameLua.GameCore.Module.Skill.SkillLua.noctor_class")
local CBuffNodeBase = require("GameLua.GameCore.Module.Skill.SkillLua.BuffActionBase")
local CBuffAction_Invisibility = class(CBuffNodeBase, nil, BuffAction_Invisibility)
return CBuffAction_Invisibility
