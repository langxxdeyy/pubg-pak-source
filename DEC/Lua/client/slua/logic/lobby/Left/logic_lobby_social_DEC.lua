local LobbySocialSystem = {
  CurrSocicalUID = 0,
  self_combat_data = nil,
  combat_datas = {},
  career_datas = {},
  peak_datas = {},
  SOCIAL_GUIDE_MAIN = 1,
  SOCIAL_PHOTO_TIPS = 2,
  SOCIAL_SOUVENIRS_TIPS = 3,
  EnterSocialTime = 0,
  CacheCorpsSummary = {},
  OwnHasApply = {},
  InvitedOthers = {},
  IsDisplay3D = true,
  self_achievement_summary = nil,
  AutoAniTime = 4,
  DelayTime_Low = 0.6,
  DelayTime_High = 0.3
}
function LobbySocialSystem.GetDelayTime()
  local UIUtil = require("client.common.ui_util")
  local GameInstance = UIUtil.GetGameInstance()
  local nDeviceLevel = GameInstance:GetDeviceLevel()
  if 0 < nDeviceLevel then
    return LobbySocialSystem.DelayTime_High
  end
  return LobbySocialSystem.DelayTime_Low
end
function LobbySocialSystem.RegisterEvents()
  LobbySocialSystem.CurrSocicalUID = tonumber(DataMgr.roleData.uid)
  EventSystem:registEvent(EVENTTYPE_LOBBY, EVENTID_SWITCHTO_PAGE_END, LobbySocialSystem.OnSwitchToPageEnd)
end
function LobbySocialSystem.UnRegisterEvents()
  EventSystem:unregistEvent(EVENTTYPE_LOBBY, EVENTID_SWITCHTO_PAGE_END, LobbySocialSystem.OnSwitchToPageEnd)
end
function LobbySocialSystem.OnSwitchToPageEnd(_, _, fromPage, toPage)
  if toPage == ENUM_LobbyPageType.Left then
    local TimeUtil = require("client.common.time_util")
    LobbySocialSystem.EnterSocialTime = TimeUtil.GetServerTimeInSec()
    local tlog_report_utils = require("client.slua.config.tlog.tlog_report_utils")
    tlog_report_utils.ReportTLogEvent(TLogEventDefine.EnterSelfSocialLobby)
  end
  if fromPage == ENUM_LobbyPageType.Left then
    local TimeUtil = require("client.common.time_util")
    local period = TimeUtil.GetServerTimeInSec() - LobbySocialSystem.EnterSocialTime
    local tlog_report_utils = require("client.slua.config.tlog.tlog_report_utils")
    tlog_report_utils.ReportTLogEvent(TLogEventDefine.SocialLobbyStay, 0, tostring(period))
  end
end
function LobbySocialSystem.EnterSocial()
  local logic_achievement = require("client.slua.logic.achievement.logic_achievement")
  logic_achievement.ReqData()
  LobbySocialSystem.CheckNewBieGuide()
  local LogicChatRoomBG = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicChatRoomBG)
  LogicChatRoomBG:send_get_chat_background_req()
end
function LobbySocialSystem.CheckNewBieGuide()
  local bNewbie = DataMgr.HaveNewbieGuide(DataMgr.NEWBIE_GUIDE_MODULE_ID_SOCIAL_LOBBY, LobbySocialSystem.SOCIAL_GUIDE_MAIN)
  local isAndroidEmpty = UIManager.IsAndroidStackEmpty()
  log(bWriteLog and "LobbySocialSystem.CheckNewBieGuide isAndroidEmpty : " .. tostring(isAndroidEmpty))
  if bNewbie and isAndroidEmpty then
    UIManager.ShowUI(UIManager.UI_Config.Lobby_Left_Record_Newbie_UIBP)
    DataMgr.SetNewbieGuide(DataMgr.NEWBIE_GUIDE_MODULE_ID_SOCIAL_LOBBY, LobbySocialSystem.SOCIAL_GUIDE_MAIN)
  end
end
function LobbySocialSystem.GetCorpSummary(uid)
  if not uid then
    return
  end
  local profile = LobbySocialSystem.GetProfileByUID(uid)
  if not profile or profile.corps_id == 0 then
    return
  end
  local tCorpSummary = LobbySocialSystem.CacheCorpsSummary[profile.corps_id]
  if not tCorpSummary then
    LobbySocialSystem.get_corps_summary_req(uid)
    return
  end
  return tCorpSummary
end
function LobbySocialSystem.get_corps_summary_req(uid, forceUpdate)
  local CorpsMgr = require("client.slua.logic.corps.corps_mgr")
  local profile = LobbySocialSystem.GetProfileByUID(uid)
  if not profile then
    return
  end
  if profile.corps_id ~= nil and tonumber(profile.corps_id) > 0 then
    local Summary = LobbySocialSystem.CacheCorpsSummary[profile.corps_id]
    if Summary and not forceUpdate then
      LobbySocialSystem.RefreshCorpsSummary(profile.corps_id, Summary)
    else
      CorpsMgr.get_corps_summary_req(profile.corps_id, tonumber(uid))
    end
  else
    LobbySocialSystem.RefreshCorpsSummary(0, {})
  end
end
function LobbySocialSystem.GetPlayerCarTeamInfo(uid)
  log(bWriteLog and "LobbySocialSystem.GetPlayerCarTeamInfo:", tostring(uid))
  local profile = LobbySocialSystem.GetProfileByUID(uid)
  if not profile then
    return
  end
  log(bWriteLog and "carteamID .." .. tostring(profile.carteam_id))
  local LogicEsportSquadOther = require("client.slua.logic.esport.logic_esport_squad_other")
  LogicEsportSquadOther.QueryOthersCarteamReq(tonumber(uid), tonumber(profile.carteam_id))
end
function LobbySocialSystem.RefreshCarTeamUI(team_id)
  EventSystem:postEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_LOBBY_SOCIAL_CARTEAM, team_id)
end
function LobbySocialSystem.GetCarTeamInfo(team_id)
  local LogicEsportSquadOther = require("client.slua.logic.esport.logic_esport_squad_other")
  local carteam = LogicEsportSquadOther.GetTeamData(team_id)
  local AllianceInfo = {
    RankIndex = 0,
    Alliance_Icon = "/Game/UMG/Texture/Atlas/Lobby/Frames/Lobby_Left_Alliance_png.Lobby_Left_Alliance_png",
    Alliance_TeamName = LocUtil.GetLocalizeResStr(6514)
  }
  if not carteam then
    return AllianceInfo
  end
  if carteam and carteam.name then
    AllianceInfo.Alliance_TeamName = carteam.name
  end
  if carteam and carteam.leader then
    if not carteam.team_flag then
      carteam.team_flag = 1
    else
      carteam.team_flag = tonumber(carteam.team_flag)
    end
    local Guidon = CDataTable.GetTableData("GuidonConfig", carteam.team_flag)
    AllianceInfo.Alliance_Icon = Guidon.res_path
  end
  return AllianceInfo
end
function LobbySocialSystem.RefreshCorpsSummary(corps_id, corps_summary)
  LobbySocialSystem.CacheCorpsSummary[corps_id] = corps_summary
  EventSystem:postEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_LOBBY_SOCIAL_CORPS_SUMMARY)
end
function LobbySocialSystem.ResetCorpApplyAndInviteInfo()
  LobbySocialSystem.OwnHasApply = {}
  LobbySocialSystem.InvitedOthers = {}
end
function LobbySocialSystem.CacheOwnHasApply(corps_id)
  if not LobbySocialSystem.IsSelf(corps_id) then
    LobbySocialSystem.OwnHasApply[tonumber(corps_id)] = true
    log(bWriteLog and "LobbySocialSystem.CacheOwnHasApply id:" .. tostring(corps_id))
  end
end
function LobbySocialSystem.CacheInviteOther(uid)
  if not LobbySocialSystem.IsSelf(uid) then
    LobbySocialSystem.InvitedOthers[tonumber(uid)] = true
  end
end
function LobbySocialSystem.HasInvited(uid)
  return LobbySocialSystem.InvitedOthers[tonumber(uid)]
end
function LobbySocialSystem.HasApplyed(corps_id)
  return LobbySocialSystem.OwnHasApply[tonumber(corps_id)]
end
function LobbySocialSystem.GetAceImprintShowId(uid)
  if LobbySocialSystem.IsSelf(uid) then
    return DataMgr.ace_imprint_show_id, DataMgr.ace_imprint_base_id, DataMgr.ace_imprint_show_cnt
  else
    local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
    local profile = logic_profile:GetLocalProfile(uid)
    if profile then
      return profile.ace_imprint_show_id, profile.ace_imprint_base_id, profile.ace_imprint_show_cnt
    end
    return 0
  end
end
function LobbySocialSystem.get_achievement_summary_req(uid)
  local AchieveHandler = require("client.network.Protocol.AchieveHandler")
  if LobbySocialSystem.IsSelf(uid) then
    if LobbySocialSystem.self_achievement_summary then
      EventSystem:postEvent(EVENTTYPE_ACHIEVEMENT, EVENTID_ACHIEVEMENT_Summary)
    else
      AchieveHandler.send_get_achievement_summary_req(uid)
    end
  else
    AchieveHandler.send_get_achievement_summary_req(uid)
  end
end
function LobbySocialSystem.GetProfileByUID(uid)
  if tonumber(uid) == tonumber(DataMgr.roleData.uid) then
    return LobbySocialSystem.GetSelfProfile()
  else
    local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
    return logic_profile:GetLocalProfile(uid)
  end
end
function LobbySocialSystem.GetSelfProfile()
  local upass = {
    is_buy = UnknowPassSystem.IsBuyElite and 1 or 0,
    keep_buy = UnknowPassSystem.GetKeeyBuy(),
    switch = {
      ui = true,
      record_privacy = next(UnknowPassSystem.Data) and UnknowPassSystem.Data.base and UnknowPassSystem.Data.base.switch.record_privacy or false
    },
    level = UnknowPassSystem.Level,
    cur_value = UnknowPassSystem.GetCurValue(),
    pass_type = UnknowPassSystem.PassType
  }
  local Switch = UnknowPassSystem.switch
  local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
  local profileData = logic_profile:GetLocalProfile(DataMgr.roleData.uid) or {}
  local historyMaxSegments = profileData.history_max_segment_level or {101}
  local historyMaxSegmentsSeasonId = profileData.history_max_segment_season_id
  local PublishRegionMacros = require("client.slua.config.ClientMacros.PublishRegionMacros")
  local curAllZoneSegment = DataMgr.roleData.allzoneSegment
  if PublishRegionMacros.IsBlueholeFamily() then
    curAllZoneSegment = {
      [3] = curAllZoneSegment[3]
    }
  else
    local logic_multiple_area = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_multiple_area)
    if logic_multiple_area:IsConnectToRussiaArea() then
      curAllZoneSegment = {
        [2] = curAllZoneSegment[2]
      }
    end
  end
  local SocialCardSystem = require("client.slua.logic.lobby.Left.logic_social_card")
  local LanguageMacros = require("client.slua.config.ClientMacros.LanguageMacros")
  local TimeUtil = require("client.common.time_util")
  local data = {
    alias = DataMgr.roleData.alias,
    uid = DataMgr.roleData.uid,
    nation = DataMgr.roleData.nation,
    level = DataMgr.roleData.level,
    lastLoginTime = 0,
    segment_info = DataMgr.roleData.allzoneSegment,
    hsegment_title_det = DataMgr.roleData.allzoneSegmentTitle,
    arena_rating_and_segment = {},
    nickName = DataMgr.roleData.nickName,
    platName = "",
    sex = DataMgr.roleData.gender,
    signature = DataMgr.roleData.signature,
    lastOnlineTime = 0,
    vipLevel = 0,
    picUrl = DataMgr.roleData.headIconUrl,
    exp = DataMgr.roleData.roleExp,
    upvote = DataMgr.roleData.upvote or 0,
    recent_upvote = 0,
    charisma = DataMgr.roleData.charisma or 0,
    startup_type = 0,
    cur_avatar_box_id = DataMgr.roleData.cur_avatar_box_id,
    social_card = SocialCardSystem.MySocialCard,
    corps_id = DataMgr.corpsInfo.id,
    history_max_segment_level = historyMaxSegments,
    history_max_segment_season_id = historyMaxSegmentsSeasonId,
    cur_max_segment_level = FuncUtil.GetCurMaxSegementLevel(curAllZoneSegment),
    credit = DataMgr.roleData.credit,
    avatar_show = nil,
    upass = upass,
    language = LanguageMacros.EN,
    warZoneID = 0,
    auth_type = DataMgr.roleData.auth_type,
    auth_end_time = DataMgr.roleData.auth_end_time,
    pround_info = DataMgr.roleData.pround_info or {},
    total_devote = DataMgr.roleData.total_devote or 0,
    psmatch_info = DataMgr.roleData.psmatch_info or {},
    friend_nickname_skin = DataMgr.roleData.friend_nickname_skin,
    chat_bubble = DataMgr.roleData.chat_bubble,
    remarks_name = "",
    intimacy = 0,
    online = 0,
    teamState = 0,
    currentTeamAmount = 0,
    maxTeamAmount = 0,
    timeSinceGameBegin = 0,
    timeSinceGameBeginStr = "",
    gameMode = 0,
    gameSubMode = 0,
    watchUid = 0,
    enableWatch = 0,
    corp_alias_id = DataMgr.roleData.corps_alias_data.cur_corps_alias_id,
    carteam_id = DataMgr.roleData.carteamId or 0,
    timestamp = TimeUtil.GetServerTimeInSec(),
    pve_level = DataMgr.roleData.pve_level,
    pve_exp = DataMgr.roleData.pve_exp,
    character_ids = {},
    ip_region = "",
    is_del = false,
    active_period_idxs = {},
    segment_info_solo = 101,
    segment_info_duo = 101,
    segment_info_squad = 101,
    upass_is_buy = upass.is_buy,
    upass_is_show = Switch and Switch.ui and 1 or 0,
    upass_keep_buy = upass.keep_buy,
    upass_cur_value = upass.cur_value,
    pass_type = upass.pass_type or 0,
    account_type = profileData.account_type,
    registertime = DataMgr.registertime,
    battleinfo_show_options = DataMgr.roleData.battleinfo_show_options,
    rankdata = DataMgr.roleData.rankdata,
    collect_data = DataMgr.roleData.brief_collect_data or {},
    wow_pass = profileData.wow_pass,
    profile_frame = DataMgr.roleData.profile_frame,
    social_card_frame = DataMgr.roleData.social_card_frame
  }
  return data
end
function LobbySocialSystem.IsSelf(uid)
  return tonumber(uid) == tonumber(DataMgr.roleData.uid)
end
function LobbySocialSystem.OnUpdateSeason()
  log(bWriteLog and "LobbySocialSystem.OnUpdateSeason")
  LobbySocialSystem.self_combat_data = nil
end
function LobbySocialSystem.get_role_combat_info_req(uid)
  local profile = LobbySocialSystem.GetProfileByUID(uid)
  if not profile then
    log_error("get_role_combat_info_req no profile")
    return
  end
  local cur_zone_id = 1
  local client_data = {
    uid = tonumber(uid)
  }
  if not profile.battleinfo_show_options or not next(profile.battleinfo_show_options) then
    log(bWriteLog and "[LobbySocialSystem] nil battleinfo_show_options, use default info")
    local maxSegment = DataMgr.GetMaxSegmentInfo(profile.segment_info)
    cur_zone_id = maxSegment.zoneid
    client_data.segmentType = maxSegment.segmentType
  elseif LobbySocialSystem.IsSelf(uid) then
    local ZoneSystem = require("client.slua.logic.teamup.logic_zone")
    cur_zone_id = ZoneSystem.nChooseZoneID
    if cur_zone_id == 0 then
      cur_zone_id = 1
    end
  else
    cur_zone_id = profile.zone_id or 1
  end
  log(bWriteLog and "LobbySocialSystem get_role_combat_info_req, zoneId = " .. cur_zone_id)
  local SocialLobbyHandler = require("client.network.Protocol.SocialLobbyHandler")
  if LobbySocialSystem.IsSelf(uid) then
    if LobbySocialSystem.self_combat_data then
      EventSystem:postEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_LOBBY_SOCIAL_COMBAT_INFO)
    else
      SocialLobbyHandler.send_get_role_battle_info(tonumber(uid), client_data, BP_COMBAT_MSG_TYPE_SOCIAL, cur_zone_id)
    end
  else
    SocialLobbyHandler.send_get_role_battle_info(tonumber(uid), client_data, BP_COMBAT_MSG_TYPE_SOCIAL, cur_zone_id)
  end
end
function LobbySocialSystem.get_role_combat_info_rsp(res, client_data, optype, role_combat_info, zoneid, curseasonid, allseasonlist, battle_info_career, peakgame_info)
  log(bWriteLog and "LobbySocialSystem get_role_combat_info_rsp curseasonid:" .. tostring(curseasonid) .. ",res:" .. tostring(res) .. ",optype:" .. tostring(optype))
  if optype ~= BP_COMBAT_MSG_TYPE_SOCIAL then
    return
  end
  if res ~= 0 then
    log_error("Error: " .. res)
    return
  end
  local role_combat_infos = {
    [enum_SegmentType.solo] = role_combat_info.warsolo,
    [enum_SegmentType.double] = role_combat_info.warduo,
    [enum_SegmentType.team] = role_combat_info.warsquad,
    [enum_SegmentType.fpp_solo] = role_combat_info.fppsolo,
    [enum_SegmentType.fpp_double] = role_combat_info.fppduo,
    [enum_SegmentType.fpp_team] = role_combat_info.fppsquad
  }
  local role_career_infos = {
    [enum_SegmentType.solo] = battle_info_career.warsolo,
    [enum_SegmentType.double] = battle_info_career.warduo,
    [enum_SegmentType.team] = battle_info_career.warsquad,
    [enum_SegmentType.fpp_solo] = battle_info_career.fppsolo,
    [enum_SegmentType.fpp_double] = battle_info_career.fppduo,
    [enum_SegmentType.fpp_team] = battle_info_career.fppsquad
  }
  local peakGame_infos = {
    [enum_SegmentType.team] = LobbySocialSystem.FillDefaultValue(peakgame_info)
  }
  for _, combat_info in pairs(role_combat_infos) do
    if not combat_info.game_num or combat_info.game_num == 0 then
      combat_info.win_rate = 0
      combat_info.top10_rate = 0
    else
      combat_info.win_rate = combat_info.win_num / combat_info.game_num * 100
      combat_info.top10_rate = combat_info.top10_count / combat_info.game_num * 100
    end
  end
  for _, combat_info in pairs(role_career_infos) do
    if not combat_info.game_num or combat_info.game_num == 0 then
      combat_info.win_rate = 0
      combat_info.top10_rate = 0
    else
      combat_info.win_rate = combat_info.win_num / combat_info.game_num * 100
      combat_info.top10_rate = combat_info.top10_count / combat_info.game_num * 100
    end
  end
  if tonumber(client_data.uid) == tonumber(DataMgr.roleData.uid) then
    LobbySocialSystem.self_combat_data = role_combat_infos
  end
  LobbySocialSystem.combat_datas[tonumber(client_data.uid)] = role_combat_infos
  LobbySocialSystem.career_datas[tonumber(client_data.uid)] = role_career_infos
  LobbySocialSystem.peak_datas[tonumber(client_data.uid)] = peakGame_infos
  EventSystem:postEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_LOBBY_SOCIAL_COMBAT_INFO, client_data.uid)
end
function LobbySocialSystem.FillDefaultValue(peakgame_info)
  log(bWriteLog and "logic_peakgame_combat:FillDefaultValue")
  log_tree("logic_peakgame_combat:FillDefaultValue peakgame_info = ", peakgame_info)
  local new_peakgame_info = {}
  local default_peakgame_combat = require("client.logic.combat.default_peakgame_combat")
  if not (peakgame_info and next(peakgame_info)) or not peakgame_info.squad then
    return
  end
  local battle_info = peakgame_info.squad
  local battle_info_format = default_peakgame_combat.battle_info_format
  for key, value in pairs(battle_info) do
    if peakgame_info[key] then
      new_peakgame_info[key] = peakgame_info[key]
    else
      new_peakgame_info[key] = value
    end
    if battle_info_format[key] then
      new_peakgame_info[key] = battle_info_format[key](new_peakgame_info[key])
    end
  end
  if new_peakgame_info.game_num and new_peakgame_info.game_num == 0 then
    new_peakgame_info.win_rate = 0
    new_peakgame_info.top10_rate = 0
    new_peakgame_info.avg_assist = 0
  else
    new_peakgame_info.win_rate = tostring((new_peakgame_info.win_num or 0) / new_peakgame_info.game_num * 100)
    new_peakgame_info.top10_rate = tostring((new_peakgame_info.top10_count or 0) / new_peakgame_info.game_num * 100)
    new_peakgame_info.avg_assist = tostring((new_peakgame_info.total_assist or 0) / new_peakgame_info.game_num)
  end
  local StringUtil = require("common.string_util")
  local avg_shot_hit_ratio = StringUtil.StrReplace(new_peakgame_info.avg_shot_hit_ratio or "0", "%", "")
  new_peakgame_info.avg_shot_hit_ratio = tostring(tonumber(avg_shot_hit_ratio) / 100)
  local head_shot_ratio = StringUtil.StrReplace(new_peakgame_info.head_shot_ratio or "0", "%", "")
  new_peakgame_info.head_shot_ratio = tostring(tonumber(head_shot_ratio) / 100)
  log_tree("LobbySocialSystem:FillDefaultValue new_peakgame_info = ", new_peakgame_info)
  return new_peakgame_info
end
function LobbySocialSystem.GetCombatInfo(uid)
  return LobbySocialSystem.combat_datas[tonumber(uid)]
end
function LobbySocialSystem.GetCareerCombatInfo(uid)
  return LobbySocialSystem.career_datas[tonumber(uid)]
end
function LobbySocialSystem.GetPeakCombatInfo(uid)
  return LobbySocialSystem.peak_datas[tonumber(uid)]
end
function LobbySocialSystem.OnGameStateChange(eventType, eventID, vars)
  log(bWriteLog and "LobbySocialSystem.OnGameStateChange  " .. tostring(vars.current) .. "  " .. tostring(vars.pre))
  LobbySocialSystem.self_combat_data = nil
  LobbySocialSystem.combat_datas = {}
  LobbySocialSystem.career_datas = {}
  LobbySocialSystem.self_achievement_summary = nil
  LobbySocialSystem.CacheCorpsSummary = {}
end
function LobbySocialSystem.Recover()
  local Lobby_Main_Control = require("client.slua.logic.lobby.Main.Lobby_Main_Control")
  Lobby_Main_Control.ChangeToLeftCamera()
end
function LobbySocialSystem.IsSocialOrPersonSpaceShow()
  local Lobby_Main_Control = require("client.slua.logic.lobby.Main.Lobby_Main_Control")
  local Lobby_Main_UIBP = UIManager.GetUI(UIManager.UI_Config.Lobby_Main_UIBP)
  if Lobby_Main_Control.curPage == ENUM_LobbyPageType.Left and Lobby_Main_UIBP and Lobby_Main_UIBP:IsShow() or UIManager.IsUIShow(UIManager.UI_Config.Social_Person_Space_UIBP) then
    return true
  end
  return false
end
return LobbySocialSystem
