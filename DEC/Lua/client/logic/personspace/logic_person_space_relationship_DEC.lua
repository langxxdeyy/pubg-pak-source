local PersonSpaceRelationshipSystem = {
  InitmacyFriendList = {},
  RelationShip_SwitchSetting = {},
  RelationShip_SwitchStatus = {},
  RelationShip_Status = {}
}
local E_ItemStatus = {Has = 0, Empty = 1}
PersonSpaceRelationshipSystem.OpenBlackLevelData = {
  [1] = {
    localize = 47553,
    iconPath = "/Game/UMG/Texture_200/Atlas/Common_New_Atlas/Frames/Common_Icon_Openblack_Friends_png.Common_Icon_Openblack_Friends_png"
  },
  [2] = {
    localize = 47554,
    iconPath = "/Game/UMG/Texture_200/Atlas/Common_New_Atlas/Frames/Common_Icon_Openblack_Partner_png.Common_Icon_Openblack_Partner_png"
  },
  [3] = {
    localize = 47555,
    iconPath = "/Game/UMG/Texture_200/Atlas/Common_New_Atlas/Frames/Common_Icon_Openblack_Friend_png.Common_Icon_Openblack_Friend_png"
  }
}
PersonSpaceRelationshipSystem.E_ItemStatus = E_ItemStatus
local table_pool = require("common.table_pool")
local tablePool = table_pool.Create()
function PersonSpaceRelationshipSystem.ShowUI(uid)
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  RoleInfoMainSystem.Show(RoleInfoMainSystem.IntimateRelationship, RoleInfoMainSystem.RoleInfoOpenFromType.Lobby, uid)
end
function PersonSpaceRelationshipSystem.InitStatusData()
  local switchData = {
    IsAllSwitch_Closed = true,
    IsAllChildSwitch_Closed = true,
    HasChildSwitch_Closed = false
  }
  PersonSpaceRelationshipSystem.RelationShip_SwitchStatus = switchData
  local LogicFriend = require("client.slua.logic.friend.logic_new_friend")
  PersonSpaceRelationshipSystem.RelationShip_Status = {}
  local IntimacyConst = require("client.slua.logic.friend.Intimacy.IntimacyConst")
  local IntimacyUtils = require("client.slua.logic.friend.Intimacy.IntimacyUtils")
  local maxIndex = IntimacyConst.EIntimacyType.Max
  for relationType = 1, maxIndex do
    local data = {
      relation = relationType,
      curCount = 0,
      maxCount = IntimacyUtils.GetRelationMaxCnt(relationType),
      HasLocked = true,
      InitmacyFriendList = {}
    }
    table.insert(PersonSpaceRelationshipSystem.RelationShip_Status, data)
  end
end
function PersonSpaceRelationshipSystem.UpdataRelationStatusData()
  for _, v in pairs(PersonSpaceRelationshipSystem.RelationShip_Status) do
    if v then
      v.curCount = 0
      v.InitmacyFriendList = {}
    end
  end
  local PersonSpaceSystem = require("client.logic.personspace.logic_person_space")
  for _, v in pairs(PersonSpaceSystem.FriendIntimacyDatas) do
    if v and v.relation then
      local relationStatus = PersonSpaceRelationshipSystem.RelationShip_Status[v.relation]
      if relationStatus then
        relationStatus.curCount = relationStatus.curCount + 1
        table.insert(relationStatus.InitmacyFriendList, v)
      end
    end
  end
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  PersonSpaceRelationshipSystem.UpdateSecrecySetting(RoleInfoSystem.CurShowPlayerInfoUid)
end
function PersonSpaceRelationshipSystem.UpdateSecrecySetting(uid)
  local switchData = PersonSpaceRelationshipSystem.RelationShip_SwitchStatus
  switchData.IsAllChildSwitch_Closed = true
  switchData.IsAllSwitch_Closed = true
  switchData.HasChildSwitch_Closed = false
  tablePool:RecycleAll(PersonSpaceRelationshipSystem.RelationShip_SwitchSetting)
  PersonSpaceRelationshipSystem.RelationShip_SwitchSetting = {}
  local PersonSpaceSystem = require("client.logic.personspace.logic_person_space")
  local isAllVisible = PersonSpaceSystem.GetSwitchVisible(uid, 0)
  local IntimacyConst = require("client.slua.logic.friend.Intimacy.IntimacyConst")
  local maxIndex = IntimacyConst.EIntimacyType.Max
  for _relation = 0, maxIndex do
    local _isVisible = PersonSpaceSystem.GetSwitchVisible(uid, _relation)
    if _relation ~= 0 then
      switchData.IsAllChildSwitch_Closed = switchData.IsAllChildSwitch_Closed and not _isVisible
      switchData.HasChildSwitch_Closed = switchData.HasChildSwitch_Closed or not _isVisible
      local RelationStatus = PersonSpaceRelationshipSystem.RelationShip_Status[_relation]
      if RelationStatus then
        RelationStatus.HasLocked = not isAllVisible or not _isVisible
      end
    end
    local temp = tablePool:Get()
    temp.relation = _relation
    temp.isVisible = _isVisible
    table.insert(PersonSpaceRelationshipSystem.RelationShip_SwitchSetting, temp)
  end
  switchData.IsAllSwitch_Closed = switchData.IsAllChildSwitch_Closed or not isAllVisible
  PersonSpaceRelationshipSystem.RelationShip_SwitchStatus = switchData
end
function PersonSpaceRelationshipSystem.IsMySelf(uid)
  return tonumber(uid) == tonumber(DataMgr.roleData.uid)
end
function PersonSpaceRelationshipSystem.CanShowRelationSystemGuide()
  return DataMgr.roleData.level >= 10
end
function PersonSpaceRelationshipSystem.NeedShowRelationGuide()
  if not PersonSpaceRelationshipSystem.CanShowRelationSystemGuide() then
    return false
  end
  local PlayerPrefsSystem = require("client.logic.LogicPlayerPrefs.playerprefs")
  local cfg = PlayerPrefsSystem.LoadFileToTable_N(PlayerPrefsSystem.ePlayerPrefsType.IntemateRelationSystemGuide) or {}
  if cfg and cfg[DataMgr.roleData.uid] then
    log(bWriteLog and "PersonSpaceRelationshipSystem.NeedShowRelationGuide finish guide")
    return false
  end
  log(bWriteLog and "PersonSpaceRelationshipSystem.NeedShowRelationGuide show guide")
  return true
end
function PersonSpaceRelationshipSystem.NeedShowCohabitRelationGuide()
  if not PersonSpaceRelationshipSystem.CanShowRelationSystemGuide() then
    return false
  end
  if not LobbySystem.CheckOpen(BP_ENUM_MODULE_PLANPH_HOME_COHABIT) then
    log(bWriteLog and "PersonSpaceRelationshipSystem.NeedShowCohabitRelationGuide switch false")
    return false
  end
  local PlayerPrefsSystem = require("client.logic.LogicPlayerPrefs.playerprefs")
  local cfg = PlayerPrefsSystem.LoadFileToTable_N(PlayerPrefsSystem.ePlayerPrefsType.IntemateRelationCohabitGuide) or {}
  if cfg and cfg[DataMgr.roleData.uid] then
    log(bWriteLog and "PersonSpaceRelationshipSystem.NeedShowCohabitRelationGuide finish guide")
    return false
  end
  log(bWriteLog and "PersonSpaceRelationshipSystem.NeedShowCohabitRelationGuide show guide")
  return true
end
function PersonSpaceRelationshipSystem.NeedShowCohabitBubbleGuide()
  if not PersonSpaceRelationshipSystem.CanShowRelationSystemGuide() then
    return false
  end
  if not LobbySystem.CheckOpen(BP_ENUM_MODULE_PLANPH_HOME_COHABIT) then
    return false
  end
  local PlayerPrefsSystem = require("client.logic.LogicPlayerPrefs.playerprefs")
  local savedData = PlayerPrefsSystem.LoadFileToTable_N(PlayerPrefsSystem.ePlayerPrefsType.eHomeJointEntryUsed) or {}
  if savedData.bHasShownCohabitBubble then
    log(bWriteLog and "PersonSpaceRelationshipSystem.NeedShowCohabitBubbleGuide finish guide")
    return false
  end
  log(bWriteLog and "PersonSpaceRelationshipSystem.NeedShowCohabitBubbleGuide show guide")
  return true
end
function PersonSpaceRelationshipSystem.SetHasShowCohabitBubbleGuide()
  local PlayerPrefsSystem = require("client.logic.LogicPlayerPrefs.playerprefs")
  local savedData = PlayerPrefsSystem.LoadFileToTable_N(PlayerPrefsSystem.ePlayerPrefsType.eHomeJointEntryUsed) or {}
  savedData.bHasShownCohabitBubble = true
  PlayerPrefsSystem.SaveTableToFile_N(savedData, PlayerPrefsSystem.ePlayerPrefsType.eHomeJointEntryUsed)
end
function PersonSpaceRelationshipSystem.SetHasShowRelationGuide()
  local PlayerPrefsSystem = require("client.logic.LogicPlayerPrefs.playerprefs")
  local cfg = PlayerPrefsSystem.LoadFileToTable_N(PlayerPrefsSystem.ePlayerPrefsType.IntemateRelationSystemGuide) or {}
  cfg[DataMgr.roleData.uid] = true
  PlayerPrefsSystem.SaveTableToFile_N(cfg, PlayerPrefsSystem.ePlayerPrefsType.IntemateRelationSystemGuide)
  if LobbySystem.CheckOpen(BP_ENUM_MODULE_PLANPH_HOME_COHABIT) then
    local cohabitCfg = PlayerPrefsSystem.LoadFileToTable_N(PlayerPrefsSystem.ePlayerPrefsType.IntemateRelationCohabitGuide) or {}
    cohabitCfg[DataMgr.roleData.uid] = true
    PlayerPrefsSystem.SaveTableToFile_N(cohabitCfg, PlayerPrefsSystem.ePlayerPrefsType.IntemateRelationCohabitGuide)
  end
end
function PersonSpaceRelationshipSystem.GetRelationSystemGuideData()
  log(bWriteLog and "[dongkaizha] PersonSpaceRelationshipSystem.GetRelationSystemGuideData: intimacy system guide")
  local bCohabitOpen = LobbySystem.CheckOpen(BP_ENUM_MODULE_PLANPH_HOME_COHABIT)
  local bShouldShowCohabitGuide = PersonSpaceRelationshipSystem.NeedShowCohabitRelationGuide() and bCohabitOpen
  local bShouldShowRelationGuide = PersonSpaceRelationshipSystem.NeedShowRelationGuide()
  local data = {
    title = LocUtil.GetLocalizeResStr(73241),
    notes = {}
  }
  local guideConfig = CDataTable.GetTable("IntimacySystemGuideCfg")
  if guideConfig then
    for _, config in pairs(guideConfig) do
      if (config.ID == 1 or config.ID == 2) and not bShouldShowCohabitGuide then
        log(bWriteLog and "PersonSpaceRelationshipSystem.GetRelationSystemGuideData: cohabit not open, skip config.ID = " .. tostring(config.ID))
      elseif bShouldShowCohabitGuide and not bShouldShowRelationGuide and config.ID > 2 then
        log(bWriteLog and "PersonSpaceRelationshipSystem.GetRelationSystemGuideData: only show cohabit guide, skip config.ID = " .. tostring(config.ID))
      else
        log(bWriteLog and "PersonSpaceRelationshipSystem.GetRelationSystemGuideData: add config.ID = " .. tostring(config.ID))
        local tmpText = config.GuideText
        if tonumber(tmpText) then
          tmpText = LocUtil.GetLocalizeResStr(tonumber(tmpText))
        end
        table.insert(data.notes, {
          ImagePath = config.ImagePath,
          Text = tmpText
        })
      end
    end
  end
  return data
end
function PersonSpaceRelationshipSystem.HasChangeNameReddot(uid)
  local C_UnlockCustomIntimacy = tonumber(DataMgr.GetSystemConfig("CustomNameUnlockIntimacy"))
  local C_UnlockCustomInteract = tonumber(DataMgr.GetSystemConfig("CustomNameUnlockInteract"))
  local logic_interaction = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_interaction)
  local LogicFriend = require("client.slua.logic.friend.logic_new_friend")
  local friendData = LogicFriend.GetFriendData(uid)
  if not friendData then
    printf("PersonSpaceRelationshipSystem.HasChangeNameReddot: friendData is nil, uid:%s", uid)
    return false
  end
  local intimacy = LogicFriend.GetFriendData(uid).intimacy or 0
  local interactInfo = logic_interaction:GetInteractInfo(uid)
  local historyScore = interactInfo and interactInfo.max_history_score or 0
  if C_UnlockCustomIntimacy > intimacy or C_UnlockCustomInteract > historyScore then
    return false
  end
  local PlayerPrefsSystem = require("client.logic.LogicPlayerPrefs.playerprefs")
  local cfg = PlayerPrefsSystem.LoadFileToTable_N(PlayerPrefsSystem.ePlayerPrefsType.IntimateRelationChangeNameReddot) or {}
  if cfg and cfg[DataMgr.roleData.uid] then
    log(bWriteLog and "PersonSpaceRelationshipSystem.HasChangeNameReddot false")
    return false
  end
  log(bWriteLog and "PersonSpaceRelationshipSystem.HasChangeNameReddot true")
  return true
end
function PersonSpaceRelationshipSystem.SetChangeNameReddot()
  local PlayerPrefsSystem = require("client.logic.LogicPlayerPrefs.playerprefs")
  local cfg = PlayerPrefsSystem.LoadFileToTable_N(PlayerPrefsSystem.ePlayerPrefsType.IntimateRelationChangeNameReddot) or {}
  cfg[DataMgr.roleData.uid] = true
  PlayerPrefsSystem.SaveTableToFile_N(cfg, PlayerPrefsSystem.ePlayerPrefsType.IntimateRelationChangeNameReddot)
  return true
end
function PersonSpaceRelationshipSystem.GetChangingRelation(uid)
  local LogicFriend = require("client.slua.logic.friend.logic_new_friend")
  local friendData = LogicFriend.GetFriendData(uid)
  local TableUtil = require("common.table_util")
  local changeRelation = 0
  local changeRelationData = TableUtil.GetTableValue(friendData, "change_data", LogicFriend.RelationChangeType.RelationType)
  if changeRelationData and (changeRelationData.state == 1 or changeRelationData.state == 2) then
    changeRelation = changeRelationData.param
  end
  log(bWriteLog and "PersonSpaceRelationshipSystem.GetChangingRelation = " .. tostring(changeRelation))
  return changeRelation
end
function PersonSpaceRelationshipSystem.GetChangingRelationAsApplier(uid)
  local LogicFriend = require("client.slua.logic.friend.logic_new_friend")
  local friendData = LogicFriend.GetFriendData(uid)
  local TableUtil = require("common.table_util")
  local changeRelation = 0
  local changeRelationData = TableUtil.GetTableValue(friendData, "change_data", LogicFriend.RelationChangeType.RelationType)
  if changeRelationData and changeRelationData.state == 1 then
    changeRelation = changeRelationData.param
  end
  log(bWriteLog and "PersonSpaceRelationshipSystem.GetChangingRelation = " .. tostring(changeRelation))
  return changeRelation
end
function PersonSpaceRelationshipSystem.GetChangingRelationAsApplied(uid)
  local LogicFriend = require("client.slua.logic.friend.logic_new_friend")
  local friendData = LogicFriend.GetFriendData(uid)
  local TableUtil = require("common.table_util")
  local changeRelation = 0
  local changeRelationData = TableUtil.GetTableValue(friendData, "change_data", LogicFriend.RelationChangeType.RelationType)
  if changeRelationData and changeRelationData.state == 2 then
    changeRelation = changeRelationData.param
  end
  log(bWriteLog and "PersonSpaceRelationshipSystem.GetChangingRelation = " .. tostring(changeRelation))
  return changeRelation
end
function PersonSpaceRelationshipSystem.GetFriendCustomRelationName(uid)
  local LogicFriend = require("client.slua.logic.friend.logic_new_friend")
  local PersonSpaceSystem = require("client.logic.personspace.logic_person_space")
  local friendData = LogicFriend.GetFriendData(uid)
  local IntimacyData = PersonSpaceSystem.GetFriendIntimacyDataByUID(uid)
  local TableUtil = require("common.table_util")
  local customName = ""
  local changeNameData = TableUtil.GetTableValue(friendData, "change_data", LogicFriend.RelationChangeType.CustomName)
  if IntimacyData and IntimacyData.custom_name then
    customName = IntimacyData.custom_name
  elseif friendData and friendData.custom_name then
    customName = friendData.custom_name
  elseif changeNameData and changeNameData.state == 4 then
    customName = changeNameData.param
  end
  log(bWriteLog and "PersonSpaceRelationshipSystem.GetFriendCustomRelationName = " .. tostring(customName))
  return customName
end
function PersonSpaceRelationshipSystem.GetFriendChangingRelationName(uid)
  local LogicFriend = require("client.slua.logic.friend.logic_new_friend")
  local friendData = LogicFriend.GetFriendData(uid)
  local TableUtil = require("common.table_util")
  local relationName = ""
  local changeNameData = TableUtil.GetTableValue(friendData, "change_data", LogicFriend.RelationChangeType.RelationType)
  if changeNameData and (changeNameData.state == 1 or changeNameData.state == 2) then
    local ui_util = require("client.common.ui_util")
    relationName = ui_util.GetIntimacyRelationName(changeNameData.param)
  end
  log(bWriteLog and "PersonSpaceRelationshipSystem.GetFriendCustomRelationName = " .. tostring(relationName))
  return relationName
end
function PersonSpaceRelationshipSystem.GetIntimacyNameByRelation(relation)
  local configs = CDataTable.GetTableByFilter("IntimacyNameConfig", "IntimacyID", relation)
  local list = {}
  if configs then
    for _, v in pairs(configs) do
      table.insert(list, v)
    end
  end
  return list
end
function PersonSpaceRelationshipSystem.GetOtherFriendRelationName(uid)
  local name = ""
  local PersonSpaceSystem = require("client.logic.personspace.logic_person_space")
  local data = PersonSpaceSystem.GetFriendIntimacyDataByUID(uid)
  if data and data.custom_name then
    name = data.custom_name
  end
  log(bWriteLog and "PersonSpaceRelationshipSystem.GetOtherFriendRelationName uid = " .. tostring(uid) .. " name = " .. name)
  return name
end
function PersonSpaceRelationshipSystem.IsRelationChanging(uid)
  local LogicFriend = require("client.slua.logic.friend.logic_new_friend")
  local friendData = LogicFriend.GetFriendData(uid)
  local TableUtil = require("common.table_util")
  local changing = false
  local changeRelationData = TableUtil.GetTableValue(friendData, "change_data", LogicFriend.RelationChangeType.RelationType)
  if changeRelationData and (changeRelationData.state == 1 or changeRelationData.state == 2) then
    changing = true
  end
  log(bWriteLog and "PersonSpaceRelationshipSystem.IsRelationChanging = " .. tostring(changing))
  return changing
end
function PersonSpaceRelationshipSystem.GetFriendChatBgList(uid)
  local list = {}
  local LogicFriend = require("client.slua.logic.friend.logic_new_friend")
  local PublishRegionMacros = require("client.slua.config.ClientMacros.PublishRegionMacros")
  local isFitVersion = PublishRegionMacros.IsFITVersion()
  local bgConfig = CDataTable.GetTable("FriendChatRoomBgConfig")
  if bgConfig then
    for _, v in pairs(bgConfig) do
      if isFitVersion and (v.ItemID == 62110101 or v.ItemID == 62110103 or v.ItemID == 62110104) then
      else
        table.insert(list, v)
      end
    end
  end
  log_tree(bWriteLog and "PersonSpaceRelationshipSystem.GetFriendChatBgList", list)
  return list
end
return PersonSpaceRelationshipSystem
