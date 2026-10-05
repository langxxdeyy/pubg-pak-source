local PersonalBasicInfo = {
  role_name = "",
  role_id = "",
  role_sex = "",
  role_nation = "",
  role_image = "",
  role_curlevel = "",
  role_nextlevel = "",
  role_curexpnum = "",
  role_needexpnum = "",
  role_sign = "",
  role_upvote = 0,
  role_charisma = 0,
  role_curlevelnum = 0,
  role_nextlevelnum = 0,
  role_segment_solo = 0,
  role_segment_double = 0,
  role_segment_team = 0,
  role_segment_max = 0,
  role_all_zone_segment_max = 0,
  role_startup_type = 0,
  role_avatar_frame = 0,
  role_credit = 0,
  role_corpsid = 0,
  role_segmentFPP_solo = 0,
  role_segmentFPP_double = 0,
  role_segmentFPP_team = 0,
  role_segmentFPP_max = 0,
  role_upassIsBuy = 0,
  role_upassKeepBuy = 0,
  role_upassUiShow = 0,
  role_upassLevel = 0,
  role_aliasId = 0,
  role_aliasTitle = "",
  role_aliasReceiveTime = 0,
  role_aliasExpireTime = 0,
  role_aliasNation = "",
  role_corpAliasId = 0,
  role_carteamId = 0
}
local CorpsSummary = {
  str_corps_id = "",
  str_city = "",
  n_activeness = 0,
  n_level = 0,
  n_leader = 0,
  n_icon = 0,
  str_icon_path = "",
  n_join_level = 0,
  str_announcement = "",
  n_member_num = 0,
  n_member_max = 0,
  n_join_segment = 0,
  str_name = "",
  n_position = 0,
  b_IsOwnApply = false,
  b_IsInvited = false,
  str_icon_text = "",
  n_icon_text_colour = 0,
  corpsAliasName = ""
}
local RoleInfoOpenFromType = {
  ReOpen = -2,
  Null = -1,
  Lobby = 1,
  LobbyChat = 2,
  TeamUPFriend = 4,
  AllianceRecruitApply = 12,
  AllianceRoleInfo = 13,
  ChatRoom = 14,
  LobbyFriend = 15,
  LobbyFriendToCard = 16,
  shop_gift_msgcenter = 19,
  TeamUp = 20,
  CorpsApplyList = 21,
  CorpsRankAward = 23,
  CorpsSuggestion = 24,
  WarZoneRank = 30,
  RegionStrongerRank = 31,
  CountryStrongerRank = 32,
  Upass = 37,
  CorpsInvitation = 38,
  QuickTeamUp = 39,
  Friend_Apply = 43,
  AllStar = 45,
  RPGroup = 46,
  Moment = 47,
  AllStar_Rank = 48,
  CommunityH5 = 49,
  Sink = 51,
  AllStar_Team = 55,
  Mail = 56,
  Lobby_RoleInfo_Intimacy_List_UIBP = 57,
  Lobby_Recruit_Card_Edit_UIBP = 58,
  Chat_Social_Card = 59,
  QR_Code = 60,
  UseItem = 61,
  LightBoard_Gift_UIBP = 62,
  Popular_TeamPK_Rank = 63,
  Popular_TeamPK_Record = 64,
  PHome_Detail = 65,
  WOW = 66,
  HomePK = 67,
  WoWItem = 68,
  MainCityInfoCard = 69,
  Commercialization = 70,
  MainCitySwitch = 71,
  WeaponStrength_Classic = 72,
  WeaponStrength_Peak = 73,
  HunterVsHunted_Pop = 74,
  BlackFridayRPGroup = 75,
  MemoryRecord = 76,
  WeddingProcessIntroduction = 77,
  WeddingActivitySquare = 78,
  MainCityWeddingEntryArea = 79,
  UGCTemplateUI = 80,
  SocialLobbyCollectMileage = 81,
  WOWPass = 82
}
local WearResType = {
  head = 1,
  face = 2,
  clothes = 3,
  pants = 4,
  shoes = 5,
  glasses = 6,
  gloves = 8,
  headid = 9,
  hairid = 10,
  weapon_type = 13,
  weapon_skin = 14,
  background = 101,
  vst_type = 102,
  vst_skin = 103,
  diy_info = 120,
  extra_weapon_res = 121,
  extra_weapon_skin = 122,
  extra_weapon_diy_info = 123
}
local NFrom
local SSelfID = DataMgr.roleData.uid
local BP_CombatUrl = FuncUtil.GetDomainByID(3366036) .. "/act/a201811s3summary/index.html"
local CombatUrl = FuncUtil.GetDomainByID(3366036) .. "/act/a201811s3summary/index.html"
local CreditUrl = FuncUtil.GetDomainByID(3366057) .. FuncUtil.GetDomainByID(3366178)
local NCombatModelType = 1
local NRoleID, NOpenFromType, TOpenFromStatus, AchieveInfo, IntimacyInfo
local NShootTypeID = 1
local NCombatShootTypeID = 1
local OwnHasApply = {}
local InvitedOthers = {}
local SCorpsHistoryUrl
local RoleInfoMatchSeasonNameList = {}
local NShowRoleInfoOfZoneId = 0
local NRoleInfoSeason_ListID = 1
local ZoneNameList, RoleInfoShootTypeNameList
local NModeID = 1
local BHasSetMaxCombatShootTypeID = false
local NLastShowIndex
local roleinfo_red_data = require("client.logic.roleinfo.roleinfo_red_data")
local RoleInfoMainSystem = {
  Null = 0,
  Base = 1,
  Segment = 3,
  Combat = 4,
  HistoryCombat = 5,
  IntimateRelationship = 6,
  IntimateRelationship_SubTab = {
    Close = 25,
    Partner = 26,
    Exhibit = 27
  },
  Credit = 7,
  RoleInfoCard = 8,
  Career = 10,
  Personalize = 11,
  Honor = 12,
  Honor_SubTab = {
    Achievement = 13,
    Alias = 14,
    WeaponStrenthHonor = 28,
    HonourCertificate = 29
  },
  Collect = 15,
  CollectMain = 16,
  CollectRoom = 17,
  CollectLib = 18,
  Milestone = 23,
  CollectRank = 24,
  WOW = 19,
  WOW_SubTab = {
    WorkData = 20,
    PlayData = 21,
    AuthorHome = 22
  }
}
local collectTabMark = {
  [RoleInfoMainSystem.Collect] = 1,
  [RoleInfoMainSystem.CollectMain] = 1,
  [RoleInfoMainSystem.CollectRoom] = 1,
  [RoleInfoMainSystem.CollectLib] = 1,
  [RoleInfoMainSystem.Milestone] = 1,
  [RoleInfoMainSystem.CollectRank] = 1
}
local jumpTabMark = {
  [RoleInfoMainSystem.Honor] = 1
}
local C_Check_Asset_Path = "/Game/Mod/Lobby/Split/Collect/Collect_Guide_UIBP.Collect_Guide_UIBP"
RoleInfoMainSystem.C_Check_Asset_Path = C_Check_Asset_Path
function RoleInfoMainSystem.InitOnlyOne()
  EventSystem:registEvent(EVENTTYPE_URL, BP_ENUM_MODULE_ROLEINFO, RoleInfoMainSystem.OnJumpUrl)
  EventSystem:registEvent(EVENTTYPE_LOGIN, EVENTID_BACKLOGIN, RoleInfoMainSystem.BackLoginEventHandler)
  EventSystem:registEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_ROLEINFO, RoleInfoMainSystem.UpdateRoleInfo)
  EventSystem:registEvent(EVENTTYPE_TEAMUP, EVENTID_TEAMUP_CHANGE_EQUIPMENT, RoleInfoMainSystem.TeamEquipmentChange)
end
function RoleInfoMainSystem.Show(index, openFrom, uid, extraData)
  log(bWriteLog and string.format("RoleInfoMainSystem.Show, uid:%s", uid))
  log(bWriteLog and string.format("RoleInfoMainSystem.Show, index:%s", index))
  log(bWriteLog and string.format("RoleInfoMainSystem.Show, openFrom:%s", openFrom))
  if not RoleInfoMainSystem.CanShowUI(index, openFrom, uid, extraData) then
    return false
  end
  if not (uid and tonumber(uid)) or tonumber(uid) <= 0 then
    log_error(bWriteLog and "RoleInfoMainSystem.Show, wrong uid")
    return
  end
  local config = UIManager.UI_Config.roleinfo_main
  local ui = UIManager.GetUI(config)
  local sJumpSelfUrl
  if ui and ui:IsShow() and extraData and extraData.bIsRecodeBackToUId then
    sJumpSelfUrl = string.format("game://?module=1002300&UID=%s&index=%s&subTabID=%s", ui:GetCurUIShowData())
  end
  local logic_friend_blacklist = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_friend_blacklist)
  if logic_friend_blacklist:IsBlacklist(uid) then
    ShowNotice(700012)
    return
  end
  if logic_friend_blacklist:IsByBlacklist(uid) then
    ShowNotice(77902)
    return
  end
  if not LobbySystem.CheckOpen(BP_ENUM_NEW_PROFILE) then
    return
  end
  log(bWriteLog and "  : RoleInfoMainSystem.Show" .. string.format("%s%s%s", index, openFrom, uid))
  if index == RoleInfoMainSystem.Honor then
    local level_unlock_manager = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.level_unlock_manager)
    if not level_unlock_manager:IsFeatureUnlocked(level_unlock_manager.featureDef.achievement) then
      ShowNotice(level_unlock_manager:GetLockTip(level_unlock_manager.featureDef.achievement))
      return
    end
  end
  local inputAchieveInfo, inputIntimacyInfo, personalInfo, openFromStatus, subTabID, mod_id, openSource
  if extraData then
    inputAchieveInfo = extraData.achieveInfo
    inputIntimacyInfo = extraData.intimacyInfo
    personalInfo = extraData.personalInfo
    openFromStatus = extraData.openFromStatus
    subTabID = tonumber(extraData.subTabID)
    mod_id = extraData.mod_id
    if not extraData.openSource then
      extraData.openSource = openFrom
    end
  else
    extraData = {}
    extraData.openSource = openFrom
  end
  openSource = extraData.openSource
  if ui and ui:IsShow() and ui.uid == uid then
  else
    RoleInfoMainSystem.BeforeShowUI(index, openFrom, uid, openFromStatus, inputAchieveInfo, inputIntimacyInfo)
  end
  if ui and ui:IsShow() then
    ui.personalizeExtraData = personalInfo
    ui.inputIntimacyInfo = inputIntimacyInfo
    ui.TabID = index
    ui.SubTabID = subTabID
    ui.mod_id = mod_id
    ui.openSource = openSource
    ui:UpdateUI()
    ui:SetRecordJumpToSelf(sJumpSelfUrl)
    return true
  end
  UIManager.ShowUI(config, index, nil, uid, nil, personalInfo, subTabID, extraData)
  return true
end
function RoleInfoMainSystem.CanShowUI(index, openFrom, uid, extraData)
  if index == RoleInfoMainSystem.WOW or index == RoleInfoMainSystem.IntimateRelationship then
    local LogicFitVersionDownload = require("client.slua.logic.download.fit.logic_fitVersion_download")
    if LogicFitVersionDownload.IfNotFitLobbyResDownloadedShowWindow() then
      log(bWriteLog and "RoleInfoMainSystem.CanShowUI WOW FitLobbyRes not downloaded, show fit popup")
      return false
    end
  end
  if extraData and extraData.jumpCanShowUI then
    return true
  end
  local PufferSwitch = require("client.slua.logic.download.puffer_switch")
  if index == RoleInfoMainSystem.Personalize and not PufferSwitch.CanAutoDownload() then
    local openTab = extraData and extraData.personalInfo and tonumber(extraData.personalInfo.openTab) or 0
    local logic_personalization_download = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_personalization_download)
    local result = logic_personalization_download:GetCheckFuncItemList(openTab)
    if result == false then
      logic_personalization_download:SetCallBackParams(openTab, index, openFrom, uid, extraData)
      return false
    else
      local isPopup = logic_personalization_download:ShowDownLoadPopup(openTab, index, openFrom, uid, extraData)
      if isPopup then
        return false
      end
    end
  end
  return true
end
function RoleInfoMainSystem.BeforeShowUI(index, openFrom, uid, openFromStatus, inputAchieveInfo, inputIntimacyInfo)
  log(bWriteLog and "  : openFrom" .. tostring(openFrom))
  NLastShowIndex = index
  if uid then
    local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
    RoleInfoSystem.Enter(uid)
  else
    local _RoleInfoSystem = require("client.slua.logic.roleInfo.logic_roleinfo_title")
    _RoleInfoSystem.Enter()
  end
  if openFrom == RoleInfoOpenFromType.AllianceRoleInfo then
    local ESportSquadSystem = require("client.slua.logic.esport.logic_esport_squad")
    ESportSquadSystem.CloseTeamMainPanel()
  end
  RoleInfoMainSystem.GetRoleInfoUIOpenFromType(openFrom)
  if UIManager.IsUIShow(UIManager.UI_Config.room_list) then
    openFrom = 0
  end
  if UIManager.IsUIShow(UIManager.UI_Config.LuckyAirDrop_FaceSlap_UIBP) then
    local LuckAirDropSystem = require("client.slua.logic.luck_airdrop.logic_luck_air_drop")
    local TickLeftTime = LuckAirDropSystem.GetLeftTime()
    if 0 < TickLeftTime then
      local AirDropMesh = require("client.slua.umg.LuckyAirDrop.ui_airdrop_mesh")
      AirDropMesh.Create()
    end
    UIManager.CloseUI(UIManager.UI_Config.LuckyAirDrop_FaceSlap_UIBP)
  end
  local __RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  if 0 < DataMgr.Last_CombatModelType and SSelfID == __RoleInfoSystem.CurShowPlayerInfoUid then
    NCombatModelType = DataMgr.Last_CombatModelType
  end
  NCombatModelType = 1
  NModeID = 1
  BHasSetMaxCombatShootTypeID = false
  NOpenFromType = openFrom or RoleInfoOpenFromType.Null
  TOpenFromStatus = openFromStatus or {}
  RoleInfoMainSystem.SetAchieveInfo(inputAchieveInfo or nil)
  IntimacyInfo = inputIntimacyInfo or nil
  if __RoleInfoSystem.PersonalBasicInfo.role_id then
    NRoleID = __RoleInfoSystem.PersonalBasicInfo.role_id
  end
  RoleInfoMainSystem.UnifyAllData()
  RoleInfoMainSystem.InitRoleInfoShootTypeNameList()
  local logic_achievement = require("client.slua.logic.achievement.logic_achievement")
  logic_achievement.ReqData()
  local logic_roleInfo_honor_title_select = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_roleInfo_honor_title_select)
  logic_roleInfo_honor_title_select:get_show_alias_req()
  local SettingHandler = require("client.network.Protocol.SettingHandler")
  SettingHandler.send_get_birthday_privacy_req()
  SettingHandler.send_get_lbs_privacy_req()
  if index == RoleInfoMainSystem.WOW then
    local LogicUGCAuthor = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicUGCAuthor)
    LogicUGCAuthor:RequestAuthorInfo(uid)
  end
end
function RoleInfoMainSystem.IsShow()
  return UIManager.IsUIShow(UIManager.UI_Config.roleinfo_main)
end
function RoleInfoMainSystem.Close(releaseAvatar, sJumpUrl)
  RoleInfoMainSystem.CloseExceptMainUI(releaseAvatar)
  UIManager.CloseUI(UIManager.UI_Config.roleinfo_main)
  if sJumpUrl then
    GlobalData.JumpUrl(sJumpUrl)
  end
end
function RoleInfoMainSystem.CloseExceptMainUI(releaseAvatar)
  local RoleInfoPopularitySystem = require("client.slua.logic.person_space.logic_roleinfo_popularity")
  RoleInfoPopularitySystem.leave()
  UIManager.CloseUI(UIManager.UI_Config.Achievement_Task_UIBP)
  UIManager.CloseUI(UIManager.UI_Config.Achievement_Space_UIBP)
  UIManager.CloseUI(UIManager.UI_Config.friend_inner_list)
  UIManager.CloseUI(UIManager.UI_Config.Team_Evaluation_UIBP)
  UIManager.CloseUI(UIManager.UI_Config.role_info_big_avatar)
  UIManager.CloseUI(UIManager.UI_Config.Achievement_Detail_1_UIBP)
  UIManager.CloseUI(UIManager.UI_Config.AchievementScoreAward_UIBP)
  UIManager.CloseUI(UIManager.UI_Config.Lobby_RoleInfo_IntimateRelationship_Popup_Large_UIBP)
  UIManager.CloseUI(UIManager.UI_Config.Personalization_UIBP)
  UIManager.CloseUI(UIManager.UI_Config.Lobby_RoleInfo_IntimateRelationship_Popup_UIBP)
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local logic_xmission_history_record = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_xmission_history_record)
  logic_xmission_history_record:ClearDetailRecordData(RoleInfoSystem.CurShowPlayerInfoUid)
  RoleInfoSystem.Release()
  SSelfID = ""
  BP_CombatUrl = CombatUrl
  NRoleID = ""
  NCombatModelType = 1
  NShowRoleInfoOfZoneId = 0
  BHasSetMaxCombatShootTypeID = false
  EventSystem:postEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_CLOSE_PANEL)
  local HallThemeUtils = require("client.logic.lobby.hall_theme_utils")
  HallThemeUtils.ProcLeaveRoleSpace()
  local froms = {
    RoleInfoOpenFromType.LobbyChat,
    RoleInfoOpenFromType.TeamUPFriend,
    RoleInfoOpenFromType.LobbyFriend,
    RoleInfoOpenFromType.AllianceRoleInfo,
    RoleInfoOpenFromType.TeamUp,
    RoleInfoOpenFromType.WarZoneRank,
    RoleInfoOpenFromType.RegionStrongerRank,
    RoleInfoOpenFromType.CountryStrongerRank
  }
  for _, form in pairs(froms) do
    if form == NOpenFromType then
      RoleInfoMainSystem.RoleInfoRecoverMenu()
      break
    end
  end
  if not releaseAvatar then
    local TeamAvatarManager = require("client.logic.avatar.logic_team_avatar_manager")
    TeamAvatarManager.ShowAllAvatar()
  end
  local SocialCardSystem = require("client.slua.logic.lobby.Left.logic_social_card")
  if next(SocialCardSystem.MySocialCard) then
    SocialCardSystem.SocialCard = SocialCardSystem.MySocialCard
  end
  log_tree(bWriteLog and "SocialCardSystem.SocialCard", SocialCardSystem.SocialCard)
end
function RoleInfoMainSystem.RoleInfoRecoverMenu()
  if NOpenFromType == 30 then
  elseif NOpenFromType == 31 then
  elseif NOpenFromType == 32 then
  else
    EventSystem:postEvent(EVENTTYPE_WARDROBE, EVENTID_WARDROBE_AVATAR_RESET_CLOSE)
  end
end
function RoleInfoMainSystem.IsCollectTabbByIndex(index)
  return collectTabMark[index] == 1
end
function RoleInfoMainSystem.CanJumpWithSubTab(index)
  return jumpTabMark[index] == 1
end
function RoleInfoMainSystem.OnModePostSwitch(preState, nextState)
  log(bWriteLog and "  :RoleInfoMainSystem.OnModePostSwitch " .. tostring(nextState))
  if GameStatus.IsInLobbyOrMainCity() then
  else
    local RoleInfoHistorySystem = require("client.logic.roleinfo.logic_roleinfo_history")
    RoleInfoHistorySystem.cachedUid = ""
    RoleInfoMainSystem.Close(true)
  end
end
function RoleInfoMainSystem.GetRoleInfoUIOpenFromType(openFrom)
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  if openFrom ~= nil and tonumber(DataMgr.roleData.uid) ~= tonumber(RoleInfoSystem.CurShowPlayerInfoUid) and not RoomSystem.IsShowWaiting() then
    NFrom = openFrom
  else
    NFrom = 0
    log(bWriteLog and "  : NFrom == 0" .. tostring(NFrom))
  end
end
function RoleInfoMainSystem.OnJumpUrl(eventType, eventID, vars)
  if vars then
    log(bWriteLog and "[chub]RoleInfoMainSystem.Show")
    local index = tonumber(vars.index or RoleInfoMainSystem.Segment)
    local openFrom = tonumber(vars.openFrom or RoleInfoOpenFromType.Lobby)
    if vars.AchID then
      index = RoleInfoMainSystem.Honor_SubTab.Achievement
    end
    local expUID = DataMgr.roleData.uid
    local jumpCollect = RoleInfoMainSystem.IsCollectTabbByIndex(index)
    if jumpCollect then
      local PufferManager = require("client.slua.logic.download.puffer.puffer_manager")
      if not PufferManager.CheckDownloadOnJump(C_Check_Asset_Path, true) then
        log(bWriteLog and string.format("RoleInfoMainSystem.OnJumpUrl collect_asset not ready"))
        return
      end
      if vars.rewardIndex then
        vars.extraTab = vars.extraTab or {}
        vars.extraTab.rewardIndex = vars.rewardIndex
        vars.extraTab.rewardSubIndex = vars.rewardSubIndex or 1
        vars.extraTab.jumpSubTabID = tonumber(vars.jumpSubTabID)
      end
      if vars.toIndex then
        vars.extraTab = vars.extraTab or {}
        vars.extraTab.toIndex = vars.toIndex
      end
    end
    if vars.UID then
      if jumpCollect then
        local collect_module = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.collect_module)
        local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
        local profile = logic_profile:GetLocalProfile(vars.UID)
        if not collect_module:CanShowCollect(profile) then
          log(bWriteLog and string.format("RoleInfoMainSystem.OnJumpUrl collect_module:CanShowCollect(%s) == false", vars.UID))
          ShowNotice(77641)
          return
        end
      end
      log(bWriteLog and string.format("RoleInfoMainSystem.OnJumpUrl vars.UID = %s", vars.UID))
      expUID = vars.UID
    end
    RoleInfoMainSystem.Show(index, openFrom, expUID, {
      subTabID = vars.subTabID,
      bIsRecodeBackToUId = vars.isRecodeBackToUId,
      achieveInfo = {
        AchID = vars.AchID
      },
      personalInfo = {
        openTab = vars.openTab,
        itemID = vars.itemID,
        subTab = vars.subTab,
        extraTab = vars.extraTab
      }
    })
  else
    log(bWriteLog and "[chub]SocialPersonSpaceSystem.EnterPersonSpace")
    local SocialPersonSpaceSystem = require("client.slua.logic.lobby.Left.logic_social_person_space")
    SocialPersonSpaceSystem.EnterPersonSpace(DataMgr.roleData.uid, true, RoleInfoOpenFromType.Lobby)
  end
end
function RoleInfoMainSystem.BackLoginEventHandler()
  DataMgr.Last_Combat_ShootType = 0
end
function RoleInfoMainSystem.UpdateRoleInfo()
  RoleInfoMainSystem.UnifyAllData()
end
function RoleInfoMainSystem.TeamEquipmentChange()
  if RoleInfoMainSystem.GetIsRestoreMenu() then
    local TeamAvatarManager = require("client.logic.avatar.logic_team_avatar_manager")
    TeamAvatarManager.HideAllAvatar()
  end
end
function RoleInfoMainSystem.SetHistoryRed(flag)
  log(bWriteLog and "  : flag" .. tostring(flag))
  roleinfo_red_data.SetHistoryRed(flag)
end
function RoleInfoMainSystem.GetSuperData()
  return roleinfo_red_data.GetSuperData()
end
function RoleInfoMainSystem.GetSaveDataSwitch()
  local cfg = CDataTable.GetTableData("RegionConfig", FuncUtil.GetAccountRegionForBP())
  log(bWriteLog and "  : FuncUtil.GetAccountRegionForBP()" .. tostring(FuncUtil.GetAccountRegionForBP()))
  if cfg then
    log(bWriteLog and "  : cfg.saveDataSwitch" .. tostring(cfg.saveDataSwitch))
    return cfg.saveDataSwitch
  end
  return false
end
function RoleInfoMainSystem.IsMe()
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  return RoleInfoSystem.PersonalBasicInfo.role_id == tostring(DataMgr.roleData.uid)
end
function RoleInfoMainSystem.IsShowSelf()
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  return SSelfID == RoleInfoSystem.CurShowPlayerInfoUid
end
function RoleInfoMainSystem.GetShareData()
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local CombatInfo = {}
  if NCombatShootTypeID == ShootType.TPPType then
    local TableUtil = require("common.table_util")
    CombatInfo = TableUtil.CopyTable(RoleInfoSystem.CombatTotalInfoList[NCombatModelType])
  elseif NCombatShootTypeID == ShootType.FPPType then
    local TableUtil = require("common.table_util")
    CombatInfo = TableUtil.CopyTable(RoleInfoSystem.FPPCombatTotalInfoList[NCombatModelType])
  end
  return CombatInfo
end
function RoleInfoMainSystem.GetShareSegmentScore()
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local ScoreInfo
  if NCombatShootTypeID == ShootType.TPPType then
    ScoreInfo = RoleInfoSystem.CombatTotalInfoList[NCombatModelType]
  elseif NCombatShootTypeID == ShootType.FPPType then
    ScoreInfo = RoleInfoSystem.FPPCombatTotalInfoList[NCombatModelType]
  end
  return ScoreInfo and ScoreInfo.role_score or 0
end
function RoleInfoMainSystem.GetShareSegmentLevel()
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local Level = 0
  if NCombatShootTypeID == ShootType.TPPType then
    if NCombatModelType == 1 then
      Level = RoleInfoSystem.PersonalBasicInfo.role_segment_solo
    elseif NCombatModelType == 2 then
      Level = RoleInfoSystem.PersonalBasicInfo.role_segment_double
    elseif NCombatModelType == 3 then
      Level = RoleInfoSystem.PersonalBasicInfo.role_segment_team
    end
  elseif NCombatShootTypeID == ShootType.FPPType then
    if NCombatModelType == 1 then
      Level = RoleInfoSystem.PersonalBasicInfo.role_segmentFPP_solo
    elseif NCombatModelType == 2 then
      Level = RoleInfoSystem.PersonalBasicInfo.role_segmentFPP_double
    elseif NCombatModelType == 3 then
      Level = RoleInfoSystem.PersonalBasicInfo.role_segmentFPP_team
    end
  end
  return Level or 0
end
function RoleInfoMainSystem.GetShareSegmentTitleId()
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local seasonIdForSegment = RoleInfoSystem.AllSeasonIDList[RoleInfoMainSystem.GetRoleinfoSeasonListID()]
  if seasonIdForSegment and seasonIdForSegment ~= 0 and seasonIdForSegment ~= DataMgr.season_id then
    return nil
  end
  local zoneid = RoleInfoMainSystem.GetShowRoleinfoOfZoneID()
  local allZoneSegmentTitle = PersonalBasicInfo.hsegment_title_det
  if not (type(allZoneSegmentTitle) == "table" and zoneid) or type(allZoneSegmentTitle[zoneid]) ~= "table" then
    return nil
  end
  local segTitleInfo
  if NCombatShootTypeID == ShootType.TPPType then
    if NCombatModelType == 1 then
      segTitleInfo = allZoneSegmentTitle[zoneid][1]
    elseif NCombatModelType == 2 then
      segTitleInfo = allZoneSegmentTitle[zoneid][2]
    elseif NCombatModelType == 3 then
      segTitleInfo = allZoneSegmentTitle[zoneid][3]
    end
  elseif NCombatShootTypeID == ShootType.FPPType then
    if NCombatModelType == 1 then
      segTitleInfo = allZoneSegmentTitle[zoneid][4]
    elseif NCombatModelType == 2 then
      segTitleInfo = allZoneSegmentTitle[zoneid][5]
    elseif NCombatModelType == 3 then
      segTitleInfo = allZoneSegmentTitle[zoneid][6]
    end
  end
  if segTitleInfo and segTitleInfo.id then
    return segTitleInfo.id
  end
  return nil
end
function RoleInfoMainSystem.ShareCombat()
  local pReasonStr, pCombatInfo, pCombatScoreInfo, pCombatSurviveInfo, pCombatGradeInfo
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  if NCombatShootTypeID == ShootType.TPPType then
    pCombatInfo = RoleInfoSystem.CombatTotalInfoList[NCombatModelType]
    pCombatScoreInfo = RoleInfoSystem.CombatTotalInfoList[NCombatModelType]
    pCombatSurviveInfo = RoleInfoSystem.CombatTotalInfoList[NCombatModelType]
    pCombatGradeInfo = RoleInfoSystem.CombatGradeInfoList[NCombatModelType]
  elseif NCombatShootTypeID == ShootType.FPPType then
    pCombatInfo = RoleInfoSystem.FPPCombatTotalInfoList[NCombatModelType]
    pCombatScoreInfo = RoleInfoSystem.FPPCombatTotalInfoList[NCombatModelType]
    pCombatSurviveInfo = RoleInfoSystem.FPPCombatTotalInfoList[NCombatModelType]
    pCombatGradeInfo = RoleInfoSystem.CombatGradeInfoList[NCombatModelType]
  end
  if pCombatInfo and pCombatScoreInfo and pCombatSurviveInfo and pCombatGradeInfo then
    pReasonStr = json.encode({
      uid = DataMgr.roleData.uid,
      totalRound = pCombatInfo.role_allmatchnum,
      totalKill = pCombatInfo.role_killnum,
      totalWin = pCombatInfo.role_winnum,
      top10Times = pCombatInfo.role_toptennum,
      newSegmentLevel = RoleInfoMainSystem.GetShareSegmentLevel(),
      sumScoreimes = pCombatScoreInfo.role_score,
      totalHeadShotRate = pCombatInfo.role_critrate,
      modeSumScore = pCombatGradeInfo.sum_score,
      modeRatingLevel = pCombatGradeInfo.rating_score,
      kdValue = pCombatInfo.role_kd_v2,
      aveSurviveTime = pCombatSurviveInfo.role_avesurvivetime,
      buttonStr = "roleInfo"
    })
  end
  local Util = require("client.slua_ui_framework.util")
  local seasonIdForSegment = RoleInfoSystem.AllSeasonIDList[RoleInfoMainSystem.GetRoleinfoSeasonListID()]
  local segmentLevel, segmentTitleId
  local logic_combat = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_combat)
  local EnumModType = logic_combat:GetEnumModeType()
  if RoleInfoMainSystem.GetCombatMode() == EnumModType.Rank then
    segmentLevel = RoleInfoMainSystem.GetShareSegmentLevel()
    segmentTitleId = RoleInfoMainSystem.GetShareSegmentTitleId()
  end
  local shareCfg = {
    sceneType = 3,
    isOld = true,
    campaign = "roleinfo",
    reasonStr = pReasonStr,
    bShowPoseSelect = true,
    segmentLevel = segmentLevel,
    seasonIdForSegment = seasonIdForSegment,
    share_type = ShareBtnTLogShareTypeDefine.IndividualAchievements,
    segmentTitleId = segmentTitleId
  }
  log_tree("[v_ywuyuan] RoleInfoMainSystem.ShareCombat shareCfg = ", shareCfg)
  local ShareMgr = require("client.logic.share.share_logic")
  if ShareMgr.Check180ShareOpen() then
    local modeList = logic_combat:GetModeListCfg()
    local modeName = modeList[RoleInfoMainSystem.GetCombatMode()].text
    local seasonName
    local seasonListID = RoleInfoMainSystem.GetRoleinfoSeasonListID()
    if seasonListID == 1 then
      local seasonData = CDataTable.GetTableData("SeasonInfo", RoleInfoSystem.curseasonid)
      seasonName = seasonData and seasonData.SeasonName or ""
    else
      local logic_rank_combat = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_rank_combat)
      local seasonNameList = logic_rank_combat:GetRankBattleSeasonList()
      seasonName = seasonNameList and seasonNameList[seasonListID].text or ""
    end
    local sModeSeasonTitle = LocUtil.LocalizeResFormat(7545, modeName, seasonName)
    log(bWriteLog and "[chub]Sharerecord_SingleBureau_UIBP_New, sModeSeasonTitle = " .. tostring(sModeSeasonTitle))
    Util.ShowShare(shareCfg, UIManager.UI_Config.Sharerecord_SingleBureau_UIBP_New, NCombatModelType, NCombatShootTypeID, sModeSeasonTitle)
    ShareMgr.ReportClickShare("roleInfo")
  else
    Util.ShowShare(shareCfg, UIManager.UI_Config.Person_Share, NCombatModelType, NCombatShootTypeID)
  end
end
function RoleInfoMainSystem.GetShareGradeData()
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local CombatGradeInfo
  if NCombatShootTypeID == ShootType.TPPType then
    CombatGradeInfo = RoleInfoSystem.CombatGradeInfoList[NCombatModelType]
  elseif NCombatShootTypeID == ShootType.FPPType then
    CombatGradeInfo = RoleInfoSystem.FPPCombatGradeInfoList[NCombatModelType]
  end
  return CombatGradeInfo or {}
end
local _tostring = tostring
local GetNewData = function()
  local BusinessHelper = import("BusinessHelper")
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local seasonId = RoleInfoSystem.AllSeasonIDList[NRoleInfoSeason_ListID]
  log(bWriteLog and "RoleInfoSystem GetNewData -- seasonid:" .. _tostring(seasonId))
  local sep = " "
  local data = ""
  local maxStrLen = 100000
  if maxStrLen < string.len(DataMgr.roleData.nickName) then
    log(bWriteLog and "local function GetNewData err 1")
    return data
  end
  data = data .. "Nickname " .. DataMgr.roleData.nickName .. sep
  log(bWriteLog and "local function GetNewData 1")
  if DataMgr.roleData.gender == 1 then
    data = data .. "Gender " .. LocUtil.GetLocalizeResStr(200042) .. sep
  else
    data = data .. "Gender " .. LocUtil.GetLocalizeResStr(200043) .. sep
  end
  log(bWriteLog and "local function GetNewData 2")
  local accountRegion = FuncUtil.GetAccountRegionForBP()
  if maxStrLen < string.len(accountRegion) then
    log(bWriteLog and "local function GetNewData err 3")
    return data
  end
  data = data .. "Region " .. accountRegion .. sep
  log(bWriteLog and "local function GetNewData 3")
  local ipAddr = Client.GetIpAddr()
  if maxStrLen < string.len(ipAddr) then
    log(bWriteLog and "local function GetNewData err 4")
    return data
  end
  data = data .. "IP " .. ipAddr .. sep
  log(bWriteLog and "local function GetNewData 4")
  data = data .. "OpenID " .. _tostring(BusinessHelper.GetOpenId()) .. sep
  local ZoneSystem = require("client.slua.logic.teamup.logic_zone")
  local zoneId = ZoneSystem.nChooseZoneID or 1
  local role_totalscore = ""
  if RoleInfoSystem.PersonalTotalScoreInfo[zoneId] and RoleInfoSystem.PersonalTotalScoreInfo[zoneId].role_totalscore then
    role_totalscore = _tostring(RoleInfoSystem.PersonalTotalScoreInfo[zoneId].role_totalscore)
  end
  data = data .. "TPP TotoalScore " .. role_totalscore .. sep
  if maxStrLen < string.len(data) then
    log(bWriteLog and "local function GetNewData err 5")
    return data
  end
  log(bWriteLog and "local function GetNewData 5")
  local role_totalrank = 0
  if RoleInfoSystem.PersonalTotalRankInfo[zoneId] and RoleInfoSystem.PersonalTotalRankInfo[zoneId].role_totalrank then
    role_totalrank = _tostring(RoleInfoSystem.PersonalTotalRankInfo[zoneId].role_totalrank)
  end
  data = data .. "TPP TotalRank " .. role_totalrank .. sep
  local segCfg = FuncUtil.GetRankTableData(PersonalBasicInfo.role_segment_solo, seasonId)
  local segmentName = segCfg and segCfg.Name or ""
  data = data .. "TPP SoloRank " .. segmentName .. sep
  data = data .. "TPP SoloScore " .. RoleInfoSystem.CombatTotalInfoList[1].role_score .. sep
  if maxStrLen < string.len(data) then
    log(bWriteLog and "local function GetNewData err 6")
    return data
  end
  log(bWriteLog and "local function GetNewData 6")
  segCfg = FuncUtil.GetRankTableData(PersonalBasicInfo.role_segment_double, seasonId)
  segmentName = segCfg and segCfg.Name or ""
  data = data .. "TPP DuoRank " .. segmentName .. sep
  data = data .. "TPP DuoScore " .. RoleInfoSystem.CombatTotalInfoList[2].role_score .. sep
  segCfg = FuncUtil.GetRankTableData(PersonalBasicInfo.role_segment_team, seasonId)
  segmentName = segCfg and segCfg.Name or ""
  data = data .. "TPP SquadRank " .. segmentName .. sep
  data = data .. "TPP SquadScore " .. _tostring(RoleInfoSystem.CombatTotalInfoList[3].role_score) .. sep
  role_totalscore = ""
  if RoleInfoSystem.FPPPersonalTotalScoreInfo[zoneId] and RoleInfoSystem.FPPPersonalTotalScoreInfo[zoneId].role_totalscore then
    role_totalscore = _tostring(RoleInfoSystem.FPPPersonalTotalScoreInfo[zoneId].role_totalscore)
  end
  data = data .. "FPP TotoalScore " .. role_totalscore .. sep
  if maxStrLen < string.len(data) then
    log(bWriteLog and "local function GetNewData err 7")
    return data
  end
  log(bWriteLog and "local function GetNewData 7")
  role_totalrank = 0
  if RoleInfoSystem.FPPPersonalTotalRankInfo[zoneId] and RoleInfoSystem.FPPPersonalTotalRankInfo[zoneId].role_totalrank then
    role_totalrank = _tostring(RoleInfoSystem.FPPPersonalTotalRankInfo[zoneId].role_totalrank)
  end
  data = data .. "FPP TotalRank " .. role_totalrank .. sep
  segCfg = FuncUtil.GetRankTableData(PersonalBasicInfo.role_segmentFPP_solo, seasonId)
  segmentName = segCfg and segCfg.Name or ""
  data = data .. "FPP SoloRank " .. segmentName .. sep
  data = data .. "FPP SoloScore " .. RoleInfoSystem.FPPCombatTotalInfoList[1].role_score .. sep
  if maxStrLen < string.len(data) then
    log(bWriteLog and "local function GetNewData err 8")
    return data
  end
  log(bWriteLog and "local function GetNewData 8")
  segCfg = FuncUtil.GetRankTableData(PersonalBasicInfo.role_segmentFPP_double, seasonId)
  segmentName = segCfg and segCfg.Name or ""
  data = data .. "FPP DuoRank " .. segmentName .. sep
  data = data .. "FPP DuoScore " .. RoleInfoSystem.FPPCombatTotalInfoList[2].role_score .. sep
  segCfg = FuncUtil.GetRankTableData(PersonalBasicInfo.role_segmentFPP_team, seasonId)
  segmentName = segCfg and segCfg.Name or ""
  data = data .. "FPP Squad ank " .. segmentName .. sep
  data = data .. "FPP Squad core " .. RoleInfoSystem.FPPCombatTotalInfoList[3].role_score .. sep
  if maxStrLen < string.len(data) then
    log(bWriteLog and "local function GetNewData err 9")
    return data
  end
  log(bWriteLog and "local function GetNewData 9")
  local friendStr = ""
  local LogicFriend = require("client.slua.logic.friend.logic_new_friend")
  for _, friUid in pairs(LogicFriend.GetAllFriendList()) do
    local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
    local profile = logic_profile:GetLocalProfile(friUid)
    if profile then
      friendStr = friendStr .. profile.nickName .. "_" .. _tostring(friUid) .. " "
      if maxStrLen < string.len(friendStr) then
        log(bWriteLog and "local function GetNewData err 10")
        return data
      end
    end
  end
  log(bWriteLog and "local function GetNewData 10")
  if friendStr ~= "" then
    data = data .. "Friends " .. friendStr .. sep
  end
  if maxStrLen < string.len(data) then
    log(bWriteLog and "local function GetNewData err 20")
    return data
  end
  log(bWriteLog and "local function GetNewData 20")
  local wardrobe_data = require("client.slua.logic.wardrobe.wardrobe_data")
  for _, v in pairs(wardrobe_data.GetArrayHallDepotItemInfo()) do
    local itemCfg = CDataTable.GetTableData("Item", v.resID)
    if itemCfg and itemCfg.itemName then
      data = data .. itemCfg.itemName .. sep
      if maxStrLen < string.len(data) then
        log(bWriteLog and "local function GetNewData err 30")
        return data
      end
    end
  end
  log(bWriteLog and "local function GetNewData 30")
  return data
end
local WritePage2DataString = function(index)
  log(bWriteLog and "local function WritePage2DataStrin index = " .. tostring(index))
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local str = "Solo: "
  if index == 2 then
    str = "Duo: "
  elseif index == 3 then
    str = "Squad: "
  end
  local sep = " "
  local basic = RoleInfoSystem.CombatTotalInfoList[index]
  str = str .. "Rounds " .. basic.role_allmatchnum .. sep
  str = str .. "Wins " .. basic.role_winnum .. sep
  str = str .. "Top 10 " .. basic.role_toptennum .. sep
  str = str .. "Kills " .. basic.role_killnum .. sep
  str = str .. "K/O Ratio " .. basic.role_kd .. sep
  str = str .. "Crit Rate " .. basic.role_critrate .. sep
  log(bWriteLog and "local function WritePage2DataStrin 1 " .. string.len(str))
  local radar = RoleInfoSystem.CombatGradeInfoList[index]
  str = str .. "Grade " .. radar.grade .. sep
  str = str .. "Total Rating " .. radar.sum_score .. sep
  str = str .. "Survives " .. radar.survive_score .. "%" .. sep
  str = str .. "Total Rating " .. radar.rating_score .. "%" .. sep
  str = str .. "Fight " .. radar.fight_score .. "%" .. sep
  str = str .. "Support " .. radar.assist_score .. "%" .. sep
  str = str .. "Win Ratio " .. radar.top1_score .. "%" .. sep
  log(bWriteLog and "local function WritePage2DataStrin 2 " .. string.len(str))
  local combat = RoleInfoSystem.CombatTotalInfoList[index]
  str = str .. "Longest Survival " .. combat.role_maxsurvivetime .. "min" .. sep
  str = str .. "AVG Survival " .. combat.role_avesurvivetime .. "min" .. sep
  str = str .. "Longest Traveled " .. combat.role_maxdistance .. "km" .. sep
  str = str .. "AVG Traveled " .. combat.role_avedistance .. "km" .. sep
  str = str .. "AVG Heals " .. combat.role_aveheal .. sep
  str = str .. "Win Ratio " .. combat.role_winrate .. "%" .. sep
  str = str .. "Top Ten " .. combat.role_toptenrate .. "%" .. sep
  if index ~= 1 then
    str = str .. "Revives " .. combat.role_aidcount .. sep
  end
  log(bWriteLog and "local function WritePage2DataStrin 3 " .. string.len(str))
  local battle = RoleInfoSystem.CombatTotalInfoList[index]
  str = str .. "Crit Hits " .. battle.role_critcount .. sep
  str = str .. "Crit Rate " .. battle.role_hitrate .. "%" .. sep
  str = str .. "Most Kill " .. battle.role_maxkill .. sep
  str = str .. "Highest Damage " .. battle.role_maxdamage .. sep
  str = str .. "AVG Damage " .. battle.role_avedamage .. sep
  log(bWriteLog and "local function WritePage2DataStrin 4 " .. string.len(str))
  return str
end
function RoleInfoMainSystem.SaveData(index)
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  if index == 1 then
    local regionConfig = FuncUtil.GetRegionConfigTable()
    local nation = PersonalBasicInfo.role_nation
    for _, v in pairs(regionConfig) do
      if v.RegionCode == nation then
        nation = v.RegionName
        break
      end
    end
    if nation == "" then
      nation = "unknown"
    end
    local sep = " "
    local data = GetNewData()
    data = "Name " .. PersonalBasicInfo.role_name .. sep
    data = data .. "Country " .. nation .. sep
    data = data .. "ID " .. PersonalBasicInfo.role_id .. sep
    data = data .. "Lv." .. PersonalBasicInfo.role_curlevelnum .. sep
    data = data .. "Signature " .. RoleInfoSystem.PersonalBasicInfo.role_sign .. sep
    Client.ClipBoardCopy(data)
    ShowNotice(105001)
  else
    local data = GetNewData()
    data = data .. WritePage2DataString(1)
    data = data .. WritePage2DataString(2)
    data = data .. WritePage2DataString(3)
    Client.ClipBoardCopy(data)
    ShowNotice(105001)
  end
end
function RoleInfoMainSystem.GetUrl()
  return BP_CombatUrl or ""
end
function RoleInfoMainSystem.GetCorpsHistoryUrl()
  return SCorpsHistoryUrl or ""
end
function RoleInfoMainSystem.UnifyAllData()
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  for k, v in pairs(RoleInfoSystem.PersonalBasicInfo) do
    PersonalBasicInfo[k] = v
    if k == "role_id" then
      NRoleID = v
    end
  end
  SSelfID = DataMgr.roleData.uid or "0"
  Client.EncryptUID(NRoleID, "6bdZX[5]s&3LadBV")
  local zoneid = 1
  local areaid = 1
  local platid = 1
  local myLanguage = Client.GetCurrentLanguage()
  local PublishRegionMacros = require("client.slua.config.ClientMacros.PublishRegionMacros")
  if PublishRegionMacros.IsBlueholeFamily() then
    CreditUrl = FuncUtil.GetDomainByID(3366058) .. FuncUtil.GetDomainByID(3366178)
  end
  SCorpsHistoryUrl = CreditUrl .. "?area_id=" .. areaid .. "&platid=" .. platid .. "&zoneid=" .. zoneid .. "&language=" .. myLanguage
  log(bWriteLog and "  : BP_CorpsHistoryUrl" .. _tostring(SCorpsHistoryUrl))
  RoleInfoMainSystem.SetSeasonCombatURL()
end
function RoleInfoMainSystem.ResetCorpApplyAndInviteInfo()
  OwnHasApply = {}
  InvitedOthers = {}
end
function RoleInfoMainSystem.ResetIntimacyInfo()
  IntimacyInfo = nil
end
function RoleInfoMainSystem.SetSeasonCombatURL()
  local SeasonPrivateKey = "XEPPTNsQV5BAkGDA"
  local openid = _tostring(DataMgr.roleData.openID)
  local language = Client.GetCurrentLanguage()
  local StringUtil = require("common.string_util")
  local pic = StringUtil.EncodeURI(_tostring(DataMgr.roleData.headIconUrl))
  local sign = ""
  local paramList = {
    {key = "openid", val = openid},
    {key = "language", val = language}
  }
  table.sort(paramList, function(a, b)
    return a.key < b.key
  end)
  local signUrl = ""
  for _, v in ipairs(paramList) do
    signUrl = signUrl .. "&" .. v.key .. "=" .. v.val
  end
  signUrl = string.gsub(signUrl, "&", "", 1)
  local encryptionStr = SeasonPrivateKey .. signUrl .. SeasonPrivateKey
  sign = Client.MD5HashAnsiString(encryptionStr)
  local strRegion = Client.GetPublishRegion()
  local PublishRegionMacros = require("client.slua.config.ClientMacros.PublishRegionMacros")
  if strRegion == PublishRegionMacros.KOREA then
    CombatUrl = FuncUtil.GetDomainByID(3366036) .. "/act/a201811rhs3summary/index.html"
  elseif strRegion == PublishRegionMacros.JAPAN then
    CombatUrl = FuncUtil.GetDomainByID(3366036) .. "/act/a201811rhs3summary/index.html"
  else
    CombatUrl = FuncUtil.GetDomainByID(3366036) .. "/act/a201811s3summary/index.html"
  end
  BP_CombatUrl = CombatUrl .. "?openid=" .. openid .. "&language=" .. language .. "&pic=" .. pic .. "&sign=" .. sign
end
function RoleInfoMainSystem.RefreshCorpsSummary(corps_summary)
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local corps_id = "0"
  if corps_summary.corps_id ~= nil then
    corps_id = _tostring(corps_summary.corps_id)
  end
  PersonalBasicInfo.role_id = RoleInfoSystem.PersonalBasicInfo.role_id
  CorpsSummary.b_IsOwnApply = false
  if RoleInfoSystem.PersonalBasicInfo.role_id ~= nil and OwnHasApply[tonumber(RoleInfoSystem.PersonalBasicInfo.role_id)] then
    CorpsSummary.b_IsOwnApply = true
  end
  CorpsSummary.b_IsInvited = false
  local InviteID = RoleInfoSystem.PersonalBasicInfo.role_id
  if InviteID ~= nil and InvitedOthers[tonumber(InviteID)] then
    CorpsSummary.b_IsInvited = true
  end
  if corps_id == "0" then
    CorpsSummary.str_corps_id = "0"
    local RoleInfoCorpsSystem = require("client.slua.logic.roleInfo.logic_roleInfo_Corps")
    RoleInfoCorpsSystem.SetCorpsInfo(CorpsSummary, corps_summary)
    return
  end
  CorpsSummary.str_corps_id = _tostring(corps_summary.corps_id)
  CorpsSummary.str_city = corps_summary.city
  CorpsSummary.n_activeness = corps_summary.activeness
  CorpsSummary.n_level = corps_summary.level
  CorpsSummary.n_leader = corps_summary.leader
  CorpsSummary.n_icon = corps_summary.icon
  CorpsSummary.str_icon_path = ""
  if corps_summary.icon ~= nil and corps_summary.icon > 0 then
    local corpIDConf = CDataTable.GetTableData("CorpsBadge", tonumber(corps_summary.icon))
    if corpIDConf ~= nil then
      CorpsSummary.str_icon_path = corpIDConf.IconPath
    end
  end
  CorpsSummary.str_icon_text = corps_summary.icon_text or ""
  CorpsSummary.n_icon_text_colour = corps_summary.icon_text_colour or 0
  CorpsSummary.n_join_level = corps_summary.join_level
  CorpsSummary.str_announcement = corps_summary.announcement
  CorpsSummary.n_member_num = corps_summary.member_num
  local levelCfg = CDataTable.GetTableData("CorpsLevel", corps_summary.level)
  if levelCfg ~= nil then
    CorpsSummary.n_member_max = levelCfg.MemberLimit
  else
    CorpsSummary.n_member_max = 0
  end
  CorpsSummary.n_join_segment = corps_summary.join_segment
  CorpsSummary.str_name = corps_summary.name
  local corpsAliasCfg = CDataTable.GetTableData("corps_alias_table", RoleInfoSystem.PersonalBasicInfo.role_corpAliasId)
  if corpsAliasCfg then
    CorpsSummary.corpsAliasName = string.format(corpsAliasCfg.CorpsAliasNameSmall, CorpsSummary.str_name)
  end
  if corps_summary.position == nil then
    CorpsSummary.n_position = 0
  else
    CorpsSummary.n_position = corps_summary.position
  end
  local _RoleInfoCorpsSystem = require("client.slua.logic.roleInfo.logic_roleInfo_Corps")
  _RoleInfoCorpsSystem.SetCorpsInfo(CorpsSummary, corps_summary)
end
function RoleInfoMainSystem.RequestBattleInfo(zoneId)
  log(bWriteLog and "  : BP_Back_ShowRoleInfoOfZoneId" .. _tostring(NShowRoleInfoOfZoneId))
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local season_id = RoleInfoSystem.AllSeasonIDList[NRoleInfoSeason_ListID]
  if season_id == nil or season_id == RoleInfoSystem.curseasonid then
    RoleInfoSystem.RequestCurrSeasonBattleInfo(zoneId)
  else
    RoleInfoSystem.RequestHistorySeasonBattleInfo(zoneId)
  end
end
function RoleInfoMainSystem.InitZoneData()
  ZoneNameList = {}
  local ZoneSystem = require("client.slua.logic.teamup.logic_zone")
  local table = table
  for _, v in ipairs(ZoneSystem.chooseZoneList) do
    local logic_multiple_area = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_multiple_area)
    table.insert(ZoneNameList, logic_multiple_area:GetDisplayNameByZoneID(v.zone_id))
  end
end
function RoleInfoMainSystem.InitRoleInfoShootTypeNameList()
  RoleInfoShootTypeNameList = {
    LocUtil.GetLocalizeResStr(100040),
    LocUtil.GetLocalizeResStr(100050)
  }
end
function RoleInfoMainSystem.GetRoleInfoShootTypeNameList()
  return RoleInfoShootTypeNameList
end
function RoleInfoMainSystem.GetZoneNameList()
  return ZoneNameList or {}
end
function RoleInfoMainSystem.RoleInfoToHistoryDetail()
  local role_info = {
    role_name = PersonalBasicInfo.role_name,
    role_id = PersonalBasicInfo.role_id,
    role_sex = (tonumber(PersonalBasicInfo.role_sex) or 0) + 1,
    role_image = PersonalBasicInfo.role_image,
    role_avatar_frame = PersonalBasicInfo.role_avatar_frame
  }
  return role_info
end
function RoleInfoMainSystem.ChacheOwnHasApplyInfo(roleID, hasApply)
  if roleID == nil or roleID == "0" then
    return
  end
  if roleID ~= SSelfID then
    OwnHasApply[tonumber(roleID)] = hasApply
  end
end
function RoleInfoMainSystem.ChacheInviteOther()
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  if RoleInfoSystem.PersonalBasicInfo.role_id == nil or RoleInfoSystem.PersonalBasicInfo.role_id == "0" then
    return
  end
  if RoleInfoSystem.PersonalBasicInfo.role_id ~= SSelfID then
    InvitedOthers[tonumber(RoleInfoSystem.PersonalBasicInfo.role_id)] = true
  end
end
function RoleInfoMainSystem.SetInviteCorpsResult()
  RoleInfoMainSystem.ChacheInviteOther()
  CorpsSummary.b_IsInvited = true
end
function RoleInfoMainSystem.SetBaseShootTypeID(id)
  NShootTypeID = id
  log(bWriteLog and "   BP_RoleInfo_BaseShootTypeID = " .. NShootTypeID)
end
function RoleInfoMainSystem.GetRoleInfoBaseShootTypeID()
  return NShootTypeID
end
function RoleInfoMainSystem.SetCombatShootTypeID(id)
  NCombatShootTypeID = id
  log(bWriteLog and "   BP_RoleInfo_CombatShootTypeID = " .. NCombatShootTypeID)
end
function RoleInfoMainSystem.GetCombatShootTypeID()
  return NCombatShootTypeID
end
function RoleInfoMainSystem.SetCombatMode(id)
  NModeID = id
  log(bWriteLog and "   BP_RoleInfo_CombatShootTypeID = " .. NCombatShootTypeID)
end
function RoleInfoMainSystem.GetCombatMode()
  return NModeID
end
function RoleInfoMainSystem.SetEmptyData()
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  for k, v in pairs(RoleInfoSystem.PersonalBasicInfo) do
    PersonalBasicInfo[k] = v
  end
end
function RoleInfoMainSystem.UpdateRoleinfoSeasonListID(list_id)
  NRoleInfoSeason_ListID = list_id
end
function RoleInfoMainSystem.GetRoleinfoSeasonListID()
  return NRoleInfoSeason_ListID
end
function RoleInfoMainSystem.GetMatchSeasonNameList()
  return RoleInfoMatchSeasonNameList
end
function RoleInfoMainSystem.SetCombatShootType(type)
  NCombatShootTypeID = type
end
function RoleInfoMainSystem.GetCombatShootType()
  return NCombatShootTypeID
end
function RoleInfoMainSystem.UpdateCombatModelType(type)
  NCombatModelType = type
end
function RoleInfoMainSystem.GetCombatModelType()
  return NCombatModelType
end
function RoleInfoMainSystem.UpdateRoleInfoNation(roleNation)
  PersonalBasicInfo.role_nation = roleNation
end
function RoleInfoMainSystem.GetCurShowUId()
  return PersonalBasicInfo.role_id
end
function RoleInfoMainSystem.IsPlayerSelf()
  return SSelfID == PersonalBasicInfo.role_id
end
function RoleInfoMainSystem.UpdateShowRoleinfoOfZoneID(zone_id)
  NShowRoleInfoOfZoneId = zone_id
end
function RoleInfoMainSystem.GetShowRoleinfoOfZoneID()
  return NShowRoleInfoOfZoneId
end
function RoleInfoMainSystem.SetShootTypeMax(max)
  NCombatShootTypeID = max
  NShootTypeID = max
  log(bWriteLog and "  : max" .. _tostring(max))
end
function RoleInfoMainSystem.SetCombatModelTypeMax(max)
  NCombatModelType = max
  log(bWriteLog and "  : max" .. _tostring(max))
end
function RoleInfoMainSystem.GetIsRestoreMenu()
  return RoleInfoMainSystem.IsShow()
end
function RoleInfoMainSystem.GetOpenForm()
  return NOpenFromType
end
function RoleInfoMainSystem.GetOpenStatus()
  return TOpenFromStatus
end
function RoleInfoMainSystem.GetAchieveInfo()
  return AchieveInfo
end
function RoleInfoMainSystem.SetAchieveInfo(info)
  AchieveInfo = info
end
function RoleInfoMainSystem.GetIntimacyInfo()
  return IntimacyInfo
end
function RoleInfoMainSystem.GetRoleId()
  return NRoleID
end
function RoleInfoMainSystem.GetPersonInfo()
  return PersonalBasicInfo
end
function RoleInfoMainSystem.GetCorpsSummary()
  return CorpsSummary
end
function RoleInfoMainSystem.GetWearResType()
  return WearResType
end
function RoleInfoMainSystem.ResetAchieveInfo()
  AchieveInfo = nil
end
function RoleInfoMainSystem.GetHistotyMaxSegmentAndSeasonId(historyMaxSegmentLevels, maxSegmentSeasonTable)
  if not historyMaxSegmentLevels or not next(historyMaxSegmentLevels) then
    log(bWriteLog and "RoleInfoMainSystem.GetHistotyMaxSegmentAndSeasonId historyMaxSegmentLevels is invalid")
    return 101, 0
  end
  if not maxSegmentSeasonTable or not next(maxSegmentSeasonTable) then
    log(bWriteLog and "RoleInfoMainSystem.GetHistotyMaxSegmentAndSeasonId maxSegmentSeasonTable is invalid")
    return math.max(table.unpack(historyMaxSegmentLevels)) or 101, 23
  end
  local historySeasonId = 23
  local historyMaxSegment = 0
  for zoneId, segId in pairs(historyMaxSegmentLevels) do
    local seasonId = maxSegmentSeasonTable[zoneId] or 23
    if segId > historyMaxSegment or segId == historyMaxSegment and historySeasonId < seasonId then
      historyMaxSegment = segId
      historySeasonId = seasonId
    end
  end
  log(bWriteLog and "RoleInfoMainSystem.GetHistotyMaxSegmentAndSeasonId historyMaxSegment is " .. _tostring(historyMaxSegment) .. " historyMaxSegment is " .. _tostring(historySeasonId))
  return historyMaxSegment, historySeasonId
end
RoleInfoMainSystem.RoleInfoOpenFromType = RoleInfoOpenFromType
local ERankShowType = {Tpp = 1, Fpp = 2}
local ERankPlayersType = {
  Team = 1,
  Duo = 2,
  Solo = 3
}
local ERankType = {InRank = 1, OutRankWithoutScore = 2}
local C_DefaultSegment = 101
local C_DefaultRankShowType = ERankShowType.Tpp
local C_DefaultRankPlayersType = ERankPlayersType.Team
function RoleInfoMainSystem.GetRankType(rank)
  if math.type(tonumber(rank)) == "integer" then
    return ERankType.InRank
  end
  if rank:find("%%") or rank == tostring(LocUtil.GetLocalizeResStr(102127)) then
    return ERankType.OutRankWithoutScore
  end
  log(bWriteLog and "[RoleInfoMainSystem] A non-existent ranking type :" .. tostring(rank))
  return nil
end
function RoleInfoMainSystem.GetRankPercentDigit(rank)
  for w in rank:gmatch("%d+%.%d+") do
    return tonumber(w)
  end
end
function RoleInfoMainSystem.GetMaxSegmentInfo(rankShowType)
  if rankShowType == nil then
    return
  end
  local data = RoleInfoMainSystem.GetPersonInfo()
  if not data or not next(data) then
    return C_DefaultRankPlayersType, C_DefaultSegment
  end
  local segmentTab = {
    C_DefaultSegment,
    C_DefaultSegment,
    C_DefaultSegment
  }
  if rankShowType == ERankShowType.Tpp then
    segmentTab = {
      [1] = data.curr_role_segment_team or C_DefaultSegment,
      [2] = data.curr_role_segment_double or C_DefaultSegment,
      [3] = data.curr_role_segment_solo or C_DefaultSegment
    }
  elseif rankShowType == ERankShowType.Fpp then
    segmentTab = {
      [1] = data.curr_role_segmentFPP_team or C_DefaultSegment,
      [2] = data.curr_role_segmentFPP_double or C_DefaultSegment,
      [3] = data.curr_role_segmentFPP_solo or C_DefaultSegment
    }
  end
  local segment = math.max(segmentTab[1], segmentTab[2], segmentTab[3])
  local playersType = C_DefaultRankPlayersType
  for k, v in ipairs(segmentTab) do
    if segment == v then
      playersType = k
      break
    end
  end
  segment = segment == 0 and C_DefaultSegment or segment
  return playersType, segment
end
function RoleInfoMainSystem.GetMaxSegmentScore()
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local combatData = RoleInfoSystem.CombatTotalInfoList or {
    0,
    0,
    0
  }
  local maxTppSegmentScore = math.max(combatData[1].role_score, combatData[2].role_score, combatData[3].role_score)
  if maxTppSegmentScore == "" then
    maxTppSegmentScore = 0
  end
  combatData = RoleInfoSystem.FPPCombatTotalInfoList or {
    0,
    0,
    0
  }
  local maxFppSegmentScore = math.max(combatData[1].role_score, combatData[2].role_score, combatData[3].role_score)
  if maxFppSegmentScore == "" then
    maxFppSegmentScore = 0
  end
  return tonumber(maxTppSegmentScore or 0), tonumber(maxFppSegmentScore or 0)
end
function RoleInfoMainSystem.GetRankShowType()
  local maxTppSegmentScore, maxFppSegmentScore = RoleInfoMainSystem.GetMaxSegmentScore()
  return maxFppSegmentScore <= maxTppSegmentScore and ERankShowType.Tpp or ERankShowType.Fpp
end
return RoleInfoMainSystem
