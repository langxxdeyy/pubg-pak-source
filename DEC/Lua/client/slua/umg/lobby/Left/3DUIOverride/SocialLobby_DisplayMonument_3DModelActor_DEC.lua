local SocialLobby_DisplayMonument_3DModelActor = {}
local Util = require("client.slua_ui_framework.util")
local Logic_SocialLobbyConst = require("client.slua.logic.lobby.Left.SocialHallConst.Logic_SocialLobbyConst")
function SocialLobby_DisplayMonument_3DModelActor:ctor()
  self._nAsyncLoadTopMeshIndex = nil
  self._nAsyncLoadBottomMeshIndex = nil
  self._sLastTopMeshPath = nil
  self._sLastBottomMeshPath = nil
  self._nShowUId = nil
  self._bIsSelf = nil
  self:_InitPlayerInfo()
end
function SocialLobby_DisplayMonument_3DModelActor:_PostConstruct()
  SocialLobby_DisplayMonument_3DModelActor.__super._PostConstruct(self)
  self:_ResetInitShow()
end
function SocialLobby_DisplayMonument_3DModelActor:ReceiveBeginPlay()
  SocialLobby_DisplayMonument_3DModelActor.__super.ReceiveBeginPlay(self)
  self:AddCommonEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_SOCIAL_LOBBY_SWITCH_PLAYER, self.OnSwitchPlayerEvent, self)
  self:AddCommonEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_CHANGE_SOCIAL_CAMERA, self.OnChangeCameraEvent, self)
  self:AddCommonEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_LOBBY_COLLECT_HALL_LEVEL_CHANGE, self.OnMonumentChangeEvent, self)
end
function SocialLobby_DisplayMonument_3DModelActor:ReceiveEndPlay(EndReason, bClearTable)
  SocialLobby_DisplayMonument_3DModelActor.__super.ReceiveEndPlay(self, EndReason, bClearTable)
  self:_ClearAsyncLoadTopMeshIndex()
  self:_ClearAsyncLoadBottomMeshIndex()
end
function SocialLobby_DisplayMonument_3DModelActor:OnSwitchPlayerEvent(_, _)
  local Logic_SocialLobbyModule = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.Logic_SocialLobbyModule)
  if tostring(self._nShowUId) == tostring(Logic_SocialLobbyModule:GetCurUId()) then
    return
  end
  self:_InitPlayerInfo()
  self:_ResetInitShow()
end
function SocialLobby_DisplayMonument_3DModelActor:OnChangeCameraEvent(_, _, nCameraId)
  local bIsNormalCamera = nCameraId == Logic_SocialLobbyConst.SOCIAL_LOBBY_SHOW_CAMERA_ID
  local sTopMeshPath = self:_GetShowMeshPath(bIsNormalCamera)
  if self._sLastTopMeshPath == sTopMeshPath then
    return
  end
  self._BPVar_UObj_TopMesh:SetStaticMesh(nil)
  self:_AsyncLoadSetTopMeshShow(sTopMeshPath)
end
function SocialLobby_DisplayMonument_3DModelActor:OnMonumentChangeEvent()
  if not self._bIsSelf then
    return
  end
  local lobby_camera_manager_module = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.Lobby_camera_manager_module)
  local nCameraId = lobby_camera_manager_module:GetCurrentCameraID()
  local bIsNormalCamera = nCameraId == Logic_SocialLobbyConst.SOCIAL_LOBBY_SHOW_CAMERA_ID
  local sTopMeshPath, sBottomMeshPath = self:_GetShowMeshPath(bIsNormalCamera)
  if sTopMeshPath ~= self._sLastTopMeshPath then
    self:_AsyncLoadSetTopMeshShow(sTopMeshPath)
  end
  if sBottomMeshPath ~= self._sLastBottomMeshPath then
    self:_AsyncLoadSetBottomMeshShow(sBottomMeshPath)
  end
end
function SocialLobby_DisplayMonument_3DModelActor:_InitPlayerInfo()
  local Logic_SocialLobbyModule = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.Logic_SocialLobbyModule)
  self._nShowUId = tonumber(Logic_SocialLobbyModule:GetCurUId())
  self._bIsSelf = tostring(self._nShowUId) == tostring(DataMgr.roleData.uid)
end
function SocialLobby_DisplayMonument_3DModelActor:_ResetInitShow()
  local sTopMeshPath, sBottomMeshPath = self:_GetShowMeshPath(true)
  self:_AsyncLoadSetTopMeshShow(sTopMeshPath)
  self:_AsyncLoadSetBottomMeshShow(sBottomMeshPath)
end
function SocialLobby_DisplayMonument_3DModelActor:_GetShowMeshPath(bIsNormalCamera)
  local sTopMeshPath = "/Game/UMG/UI_BP/Lobby/SocialLobby/StaticMesh/DisplayMonumentMesh/SM_Lobby_Social_ShelfMesh_L_Display.SM_Lobby_Social_ShelfMesh_L_Display"
  local sBottomMeshPath = "/Game/UMG/UI_BP/Lobby/SocialLobby/StaticMesh/DisplayMonumentMesh/SM_Lobby_Social_ShelfMesh_L_Base.SM_Lobby_Social_ShelfMesh_L_Base"
  local Logic_SocialLobbyModule = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.Logic_SocialLobbyModule)
  local nMonumentItemId = Logic_SocialLobbyModule:GetMonumentShowItemId(self._nShowUId)
  local uMonumentCfg = CDataTable.GetTableDataByFilter("PlanCH_DisplayMonumentCfg", "ResId", nMonumentItemId)
  if not uMonumentCfg then
    return sTopMeshPath, sBottomMeshPath
  end
  if uMonumentCfg.BottomBooth ~= "" then
    sBottomMeshPath = uMonumentCfg.BottomBooth
  end
  if bIsNormalCamera then
    if uMonumentCfg.TopBoothNormal ~= "" then
      sTopMeshPath = uMonumentCfg.TopBoothNormal
    end
  elseif uMonumentCfg.TopBoothShort ~= "" then
    sTopMeshPath = uMonumentCfg.TopBoothShort
  end
  return sTopMeshPath, sBottomMeshPath
end
function SocialLobby_DisplayMonument_3DModelActor:_ClearAsyncLoadBottomMeshIndex()
  if self._nAsyncLoadBottomMeshIndex then
    Util.ClearAssetAsync(self._nAsyncLoadBottomMeshIndex)
    self._nAsyncLoadBottomMeshIndex = nil
  end
end
function SocialLobby_DisplayMonument_3DModelActor:_ClearAsyncLoadTopMeshIndex()
  if self._nAsyncLoadTopMeshIndex then
    Util.ClearAssetAsync(self._nAsyncLoadTopMeshIndex)
    self._nAsyncLoadTopMeshIndex = nil
  end
end
function SocialLobby_DisplayMonument_3DModelActor:_AsyncLoadSetBottomMeshShow(sMeshPath)
  self._sLastBottomMeshPath = sMeshPath
  self:_ClearAsyncLoadBottomMeshIndex()
  self._nAsyncLoadBottomMeshIndex = Util.GetAssetAsync(sMeshPath, function(uObj_loadObj)
    self._nAsyncLoadBottomMeshIndex = nil
    if not slua.isValid(self.Object) or not slua.isValid(uObj_loadObj) then
      return
    end
    self._sLastBottomMeshPath = sMeshPath
    self._BPVar_UObj_BottomMesh:SetStaticMesh(uObj_loadObj)
  end)
end
function SocialLobby_DisplayMonument_3DModelActor:_AsyncLoadSetTopMeshShow(sMeshPath)
  self._sLastTopMeshPath = sMeshPath
  self:_ClearAsyncLoadTopMeshIndex()
  self._nAsyncLoadTopMeshIndex = Util.GetAssetAsync(sMeshPath, function(uObj_loadObj)
    self._nAsyncLoadTopMeshIndex = nil
    if not slua.isValid(self.Object) or not slua.isValid(uObj_loadObj) then
      return
    end
    self._BPVar_UObj_TopMesh:SetStaticMesh(uObj_loadObj)
  end)
end
local class = require("class")
local ActorBase = require("GameLua.Mod.BaseMod.Common.Core.ActorBase")
return class(ActorBase, nil, SocialLobby_DisplayMonument_3DModelActor)
