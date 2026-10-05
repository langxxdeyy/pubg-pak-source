local ChatMenuSystem = require("client.slua.logic.lobby_chat.logic_chat_menu")
local PufferTlog = require("client.slua.logic.download.report.puffer_tlog")
local PlayerStatusUtil = require("client.slua.logic.player_status.PlayerStatusUtil")
local FLMacros = require("client.slua.logic.friend.refactor.friend_list_macros")
local LogicChatApplyMsg = require("client.slua.logic.lobby_chat.logic_chat_apply_msg")
local Personal_Info_UIBP = {}
local EnumApplyType = {
  AddFriend = 1,
  Relation = 2,
  Partner = 3
}
function Personal_Info_UIBP:ctor(_, uid, params, eShowLocationType, bShowGift, bShowPinbi)
  if not uid or type(uid) == "table" then
    return
  end
  self.uid = tonumber(uid)
  self.params = params
  self.isSelf = tonumber(self.uid) == tonumber(DataMgr.roleData.uid)
  log(bWriteLog and "Personal_Info_UIBP:ctor uid = " .. tostring(uid) .. " self.isSelf = " .. tostring(self.isSelf))
  self.bNeedRefreshNormalInfoNum = 0
  self.openSubWidget = nil
  self.isShowMood = false
  self.isShowSkin = false
  self.isDefultNameColor = true
  self.eShowLocationType = eShowLocationType
  self.needDownloadPakNames = {}
  self.bShowGift = bShowGift
  self:PreloadPersonalInfo()
  self.IsPlanBTParam = params.IsPlanBTParam or false
  self.FrameAnimPlayed = false
end
function Personal_Info_UIBP:OnInitialize()
  local custom_presentation_util = require("client.slua.logic.person_space.custom_presentation_util")
  self:SetWidgetVisible(self.UIRoot.Lobby_RoleInfo_CustomPresentation_Item_UIBP, false, false)
  self:SetWidgetVisible(self.UIRoot.LobbyChat_InformationCustomDetail_UIBP, true, false)
  local UIComponentModule = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.UIComponentModule)
  self.LobbyChat_InformationCustomDetail_UIBP = UIComponentModule:InitWithParentComponent(self, UIComponentModule.Config.LobbyChat_InformationCustomDetail_UIBP, self.UIRoot.LobbyChat_InformationCustomDetail_UIBP)
  self.UIRoot.Image_Platform:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  self:SetWidgetVisible(self.UIRoot.CanvasPanel_48, false, false)
  self:SetWidgetVisible(self.UIRoot.Button_FriendsGoTo, true, true)
  self:InitNicknameOutline()
end
function Personal_Info_UIBP:InitNicknameOutline()
  self:ApplyNicknameOutline(self.UIRoot.TextBlock_Name, false)
end
function Personal_Info_UIBP:ApplyNicknameOutline(textWidget, needOutline)
  if not textWidget or not textWidget.Font then
    return
  end
  local font = textWidget.Font
  if needOutline then
    font.OutlineSettings.OutlineSize = 1
    font.OutlineSettings.OutlineColor = FLinearColor(0, 0, 0, 1)
  else
    font.OutlineSettings.OutlineSize = 0
    font.OutlineSettings.OutlineColor = FLinearColor(0, 0, 0, 1)
  end
  textWidget:setFont(font)
end
function Personal_Info_UIBP:RegistEvents()
  self:AddOnClickedEventByControl(self.UIRoot.Button_Close, self.OnClickButton_Close, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_More, self.OnClickButton_More, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Report, self.OnClickButton_Report, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Poke, self.OnClickButton_Poke, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_SendGift, self.OnClickButton_SendGift, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Invite, self.OnClickButton_Invite, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Apply, self.OnClickButton_Apply, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_AddFriened, self.OnClickButton_AddFriened, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Chat, self.OnClickButton_Chat, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Play1, self.OnClickButton_Play1, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Play2, self.OnClickButton_Play2, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_mood, self.OnClickButton_mood, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_good, self.OnClickButton_good, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_SocialHall, self.OnClickButton_SocialHall, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Home, self.OnClickButton_Home, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_CardCollect, self.OnClickButton_CardCollect, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_BP, self.OnClickButton_GiveBP, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Club, self.on_hover_club_profile_click, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Moment, self.on_hover_moment_click, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Remark, self.OnClickRemark, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_InteractRecord, self.OnButton_InteractRecordClick, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Souvenirs, self.OnButton_SouvenirsClick, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Pinbi, self.OnClickedPinbi, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Fire, self.OnClickButtonFire, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_FriendsGoTo, self.OnClickButton_FriendsGoTo, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Home22, self.OnClickGoHome, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Home_Download, self.OnClickHome_Download, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Lock01, self.OnClickHomeLock, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_CollectHall_Go, self.OnClickButton_CollectHall_Go, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Collect_DownLoad, self.OnClickButton_Collect_DownLoad, self)
  self:AddControlEventByControl(self.UIRoot.Common_Avatar_BP, "OnClickItemCallback", self.OnClickHeadCallback, self)
  self:AddCommonEvent(EVENTTYPE_CORPS, EVENTID_CORPS_GET_SUMMARY, self.GetCorpsSummaryRsp, self)
  self:AddCommonEvent(EVENTTYPE_CHAT, EVENTID_CHAT_INTERACT_RSP, self.OnInteract, self)
  self:AddCommonEvent(EVENTTYPE_FRIEND, EVENTID_BATCH_GET_PLAYERSTATUS, self.OnFriendStatusChange, self)
  self:AddCommonEvent(EVENTTYPE_FRIEND, EVENTID_FRIEND_UPDATE_REMARK, self.OnFriendStatusChange, self)
  self:AddCommonEvent(EVENTTYPE_FRIEND, EVENTID_FRIEND_GROUP_ONLINE_CHANGE, self.OnFriendStatusChange, self)
  self:AddCommonEvent(EVENTTYPE_FRIEND, EVENTID_FRIEND_INTIMACY_UPDATE, self.OnFriendStatusChange, self)
  self:AddCommonEvent(EVENTTYPE_FRIEND, EVENTID_FRIEND_STATUS_CHANGE, self.OnFriendStatusChange, self)
  self:AddCommonEvent(EVENTTYPE_FRIEND, EVENTID_FRIEND_TOP_STATUS_CHANGE, self.OnFriendStatusChange, self)
end
function Personal_Info_UIBP:OnPostInitialize()
  local logic_interaction = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_interaction)
  logic_interaction:send_get_interact_info_req(self.uid)
  self:SetWidgetVisible(self.UIRoot.CanvasPanel_mood, false, false)
  self:UpdateUI()
  self:UpdateCardSkin()
  self:UpdateProfileFrame()
  self:UpdataRelationship()
  self.isShowGood = false
  self:RefreshExtendButton()
  self.UIRoot.TextBlock_Return_Tips:SetText(LocUtil.GetLocalizeResStr(86256))
end
function Personal_Info_UIBP:OnClose()
  self:StopSkinDownloadPollTimer()
  local logic_teamquick_join = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_teamquick_join)
  logic_teamquick_join:SetAvatarTeamID(nil)
  if self.profile_frame_bp then
    self.profile_frame_bp:CloseSelf()
    self.profile_frame_bp = nil
    self.FrameAnimPlayed = nil
  end
end
function Personal_Info_UIBP:PreloadPersonalInfo()
  local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
  local profile = logic_profile:GetLocalProfile(self.uid)
  if not profile or not profile.rankdata then
    local logic_profile_get_wrap = require("client.slua.logic.user.profile.logic_profile_get_wrap")
    logic_profile_get_wrap.GetRankProfiles(Enum_PROFILE_REPORT_CFG.MAINCITY_INFOCARD, {
      self.uid
    }, function(listInfo)
    end)
  end
  if profile then
    local corpsID = profile.corps_id or 0
    if 0 < corpsID then
      ChatMenuSystem.get_corps_summary_req(corpsID, tonumber(self.uid))
    end
  end
  local logic_interaction = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_interaction)
  logic_interaction:send_get_interact_info_req(self.uid)
  local custom_presentation_util = require("client.slua.logic.person_space.custom_presentation_util")
  self._cpData = custom_presentation_util.GetDataByUID(self.uid)
  local custom_presentation_config = require("client.slua.logic.person_space.custom_presentation_config")
  for index, cpData in ipairs(self._cpData) do
    if cpData and 0 < cpData.mId then
      if cpData.mId == custom_presentation_config.NewModuleID.Common_RankIntegralLevelMax then
        local logic_profile_get_wrap = require("client.slua.logic.user.profile.logic_profile_get_wrap")
        logic_profile_get_wrap.GetNormalProfiles({
          tonumber(self.uid)
        }, nil, Enum_PROFILE_REPORT_CFG.ROLE_INFO, 100, true)
      elseif cpData.mId == custom_presentation_config.NewModuleID.SeasonYear then
        local logic_season_year_badge = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_season_year_badge)
        if tonumber(self.uid) ~= tonumber(DataMgr.roleData.uid) then
          local badgeData = logic_season_year_badge:CheckOtherSeasonYearBadge(self.uid)
          if badgeData == nil then
            logic_season_year_badge:ReqOtherSeasonYearBadgeInfo(tonumber(self.uid))
          end
        end
      elseif cpData.mId == custom_presentation_config.NewModuleID.Relation then
        local relation_uid = cpData.relation_uid or cpData.mData.uid
        local relation_profile = logic_profile:GetLocalProfile(relation_uid)
        if not relation_profile then
          custom_presentation_util.GetRelationFriendData(relation_uid)
        end
      end
    end
  end
  local PersonSpaceHandler = require("client.network.Protocol.PersonSpaceHandler")
  PersonSpaceHandler.send_get_other_intimacy_relation_req(self.uid)
end
function Personal_Info_UIBP:OnClickButton_Close()
  self:PlayAudio(sound_config.click_v1)
  if self.openSubWidget then
    self:SetWidgetVisible(self.openSubWidget, false, false)
    self.openSubWidget = nil
    return
  end
  self:CloseSelf()
end
function Personal_Info_UIBP:OnClickButton_More()
  log(bWriteLog and "Personal_Info_UIBP:OnClickButton_More")
  self:PlayAudio(sound_config.click_v1)
  self.isShowExtend = not self.isShowExtend
  self:SetWidgetVisible(self.UIRoot.CanvasPanel_More, self.isShowExtend, false)
  self.openSubWidget = self.UIRoot.CanvasPanel_More
end
function Personal_Info_UIBP:OnClickButton_Report()
  log(bWriteLog and "Personal_Info_UIBP:OnClickButton_Report")
  self:PlayAudio(sound_config.click_v1)
  self:SetWidgetVisible(self.UIRoot.CanvasPanel_More, false, false)
  self.openSubWidget = nil
  local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
  local profile = logic_profile:GetLocalProfile(self.uid)
  if not profile then
    return
  end
  local ChatMenuSystem = require("client.slua.logic.lobby_chat.logic_chat_menu")
  ChatMenuSystem.on_report_req(self.uid, profile.nickName, "", false, 0, self.params.CliSourceId)
end
function Personal_Info_UIBP:OnClickButton_BlackList()
  log(bWriteLog and "Personal_Info_UIBP:OnClickButton_BlackList")
  self:PlayAudio(sound_config.click_v1)
  self:SetWidgetVisible(self.UIRoot.CanvasPanel_More, false, false)
  self.openSubWidget = nil
  local PersonSpaceSystem = require("client.logic.personspace.logic_person_space")
  local LogicFriend = require("client.slua.logic.friend.logic_new_friend")
  local logic_friend_blacklist = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_friend_blacklist)
  if logic_friend_blacklist:IsBlacklist(self.uid) then
    ShowNotice(106065)
  else
    local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
    local data = logic_profile:GetLocalProfile(self.uid)
    if data then
      do
        local callback = function(isCheck, isDifferentTeams)
          logic_friend_blacklist:proc_add_black_list_req(data.uid, logic_friend_blacklist.Enum_Add_Black_Scene.MainCity_Info_Card)
          if data.type == EnumApplyType.Partner then
            PersonSpaceSystem.refuse_make_intimacy_partner_req(data.uid)
          elseif data.type == EnumApplyType.Relation then
            LogicFriend.reply_intimacy_relation_req(data.uid, data.param, 0)
          else
            local isFriend = LogicFriend.IsMyFriend(self.uid)
            if not isFriend then
              local logic_friend_apply = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_friend_apply)
              logic_friend_apply:add_inner_friend_op_req(data.uid, 0)
            end
          end
          self:CloseSelf()
        end
        local extraData = {
          isDifferentTeams = true,
          showUIKey = "Com_Match_Black_UIBP"
        }
        local CommonMsgBoxMgr = require("client.slua.logic.common.logic_common_msg_box")
        local title = LocUtil.GetLocalizeResStr(34696)
        local msg = LocUtil.LocalizeResFormat(34697, data.nickName)
        CommonMsgBoxMgr.Show(2, title, msg, callback, nil, nil, nil, extraData)
      end
    end
  end
end
function Personal_Info_UIBP:OnClickButton_Poke()
  log(bWriteLog and "Personal_Info_UIBP:OnClickButton_Poke")
  self:PlayAudio(sound_config.click_v1)
  local logic_poke = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_poke)
  logic_poke:send_poke_friend_req(self.uid)
  self:ReportTLog(self.uid, "Poke")
end
function Personal_Info_UIBP:OnClickButton_SendGift()
  log(bWriteLog and "Personal_Info_UIBP:OnClickButton_SendGift")
  self:PlayAudio(sound_config.click_v1)
  local RoleInfoPopularitySystem = require("client.slua.logic.person_space.logic_roleinfo_popularity")
  local giftSourceType = RoleInfoPopularitySystem.GiftSourceType.MainCityInfoCard
  self:ReportTLog(self.uid, "SendGift")
  UIManager.ShowUI(UIManager.UI_Config.roleinfo_send_gift, giftSourceType, nil, nil, self.uid)
end
function Personal_Info_UIBP:OnClickButton_Invite()
  log(bWriteLog and "Personal_Info_UIBP:OnClickButton_Invite")
  self:PlayAudio(sound_config.click_v1)
  self:ShowWaitingUI()
  self:InviteRequest()
  local StatManager = import("StatManager")
  StatManager.GetInstance():ReportEventWithNoParam(33, true)
  self:ReportTLog(self.uid, "Invite")
end
function Personal_Info_UIBP:OnClickButton_Apply()
  log(bWriteLog and "Personal_Info_UIBP:OnClickButton_Apply")
  self:PlayAudio(sound_config.click_v1)
  local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
  local profile = logic_profile:GetLocalProfile(self.uid)
  local player = profile
  local LobbySystem = require("client.logic.login.logic_lobby")
  local isInMatching = LobbySystem.isInMatch
  if not player or type(player) ~= "table" or not next(player) then
    return
  end
  local PlayerStatusMgr = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.PlayerStatusMgr)
  local status = PlayerStatusMgr:GetStatusData(player.uid)
  if not status then
    return
  end
  self:ShowWaitingUI()
  local TeamUpNewSystem = require("client.slua.logic.teamup.logic_team_up")
  if PlayerStatusUtil.InHall(status) and status.mod_id then
    local UGCPlayHallRoom = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.UGCPlayHallRoom)
    UGCPlayHallRoom:ReplyUGCPlayRoomInvitation(status.mod_id, status.hall_id, status.ph_room_svr_id, {src_def = "friend"}, true)
  elseif PlayerStatusUtil.IsRoom(status) and status.mod_id then
    local StatusHandler = require("client.network.Protocol.StatusHandler")
    PlayerStatusMgr:QueryFriendRoom(player.uid, function(roomId)
      local LogicUGCRoom = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicUGCRoom)
      LogicUGCRoom:ReqQueryRoom(tonumber(roomId))
    end)
  elseif isInMatching then
    ShowNotice(110122)
    return
  elseif TeamUpNewSystem.CanInviteFriend() then
    if status.tplan_type and status.tplan_type ~= 0 then
      local LogicTxMissionDownload = require("client.slua.logic.TxMission.logic_xmission_download")
      if not LogicTxMissionDownload.CheckResHasDownloaded() then
        ShowNotice(45677)
        return
      end
    end
    local logic_friend_list_ui = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_friend_list_ui)
    local from = logic_friend_list_ui:GetFrom()
    if from == FLMacros.ENUM_OPEN_FROM.TPLAN then
      if not status.tplan_type or status.tplan_type == 0 then
        local title = LocUtil.GetLocalizeResStr(101001)
        local content = LocUtil.GetLocalizeResStr(35198)
        local CommonMsgBoxMgr = require("client.slua.logic.common.logic_common_msg_box")
        CommonMsgBoxMgr.ShowTPlan(2, title, content, function()
          local LogicTxMissionMain = require("client.slua.logic.TxMission.logic_xmission_main")
          LogicTxMissionMain.QuitXMissionByJoinTeam(player.uid)
        end)
        return
      end
      TeamUpNewSystem.team_apply_request(player.uid, TeamUpNewSystem.E_InviteFromType.TPlan)
    elseif from == FLMacros.ENUM_OPEN_FROM.ISLAND then
      if status.tplan_type and status.tplan_type == 1 then
        ShowNotice(11893)
        return
      else
        TeamUpNewSystem.team_apply_request(player.uid, TeamUpNewSystem.E_InviteFromType.FriendBar)
      end
    elseif from == FLMacros.ENUM_OPEN_FROM.CREATIVEWOW then
      TeamUpNewSystem.team_apply_request(player.uid, TeamUpNewSystem.E_InviteFromType.CreativeWoW)
    else
      TeamUpNewSystem.team_apply_request(player.uid, TeamUpNewSystem.E_InviteFromType.FriendBar)
    end
  end
end
function Personal_Info_UIBP:ShowWaitingUI()
  log(bWriteLog and "Personal_Info_UIBP:ShowWaitingUI")
  self:SetWidgetVisible(self.UIRoot.WidgetSwitcher_Team, true, false)
  self:SetWidgetVisible(self.UIRoot.SizeBox_10, true, false)
  self.UIRoot.WidgetSwitcher_Team:SetActiveWidgetIndex(2)
  self:AddTimerOnce(5.5, function()
    self:RefreshInteractButton()
  end)
end
function Personal_Info_UIBP:InviteRequest()
  log(bWriteLog and "Personal_Info_UIBP:InviteRequest")
  local isInRoomWaiting = RoomSystem.IsShowWaiting()
  local isInMatching = LobbySystem.isInMatch
  log(bWriteLog and "Personal_Info_UIBP:InviteRequest isInRoomWaiting = " .. tostring(isInRoomWaiting) .. " isInMatching = " .. tostring(isInMatching))
  local TeamUpNewSystem = require("client.slua.logic.teamup.logic_team_up")
  local bTriggerAction = false
  if isInRoomWaiting then
    RoomSystem.room_invite_request(self.uid)
    bTriggerAction = true
  elseif isInMatching then
    ShowNotice(110122)
  elseif TeamUpNewSystem.CanInviteFriend(self.uid) then
    TeamUpNewSystem.team_invite_request(self.uid, TeamUpNewSystem.E_InviteFromType.MainCityInfoCard)
    bTriggerAction = true
  end
  if bTriggerAction then
    local MCActionConfig = require("GameLua.Mod.MainCity.Gameplay.Config.MCActionConfig")
    EventSystem:postEvent(EVENTTYPE_MAINCITY, EVENTID_MAINCITY_PLAYER_INFO_CARD_TRIG_ACTION, MCActionConfig.TriggerActionEmoteId.InviteTeam)
    EventSystem:postEvent(EVENTTYPE_ACTIVITY, EVENTID_BARGAIN_PLAYER_INFO_CARD_TRIG_ACTION)
  end
  EventSystem:postEvent(EVENTTYPE_LOBBY, EVENT_ONE_TEAM_INVITE_SENT, self.uid)
end
function Personal_Info_UIBP:ApplyRequest()
  log(bWriteLog and "Personal_Info_UIBP:ApplyRequest")
  local isInMatching = LobbySystem.isInMatch
  log(bWriteLog and "Personal_Info_UIBP:ApplyRequest isInMatching = " .. tostring(isInMatching))
  local TeamUpNewSystem = require("client.slua.logic.teamup.logic_team_up")
  if isInMatching then
    ShowNotice(110122)
  elseif TeamUpNewSystem.CanInviteFriend() then
    TeamUpNewSystem.team_apply_request(self.uid, TeamUpNewSystem.E_InviteFromType.MainCityInfoCard)
  end
end
function Personal_Info_UIBP:OnClickButton_AddFriened()
  log(bWriteLog and "Personal_Info_UIBP:OnClickButton_AddFriened")
  self:PlayAudio(sound_config.click_v1)
  local LogicFriend = require("client.slua.logic.friend.logic_new_friend")
  local msgId = LogicChatApplyMsg.GetApplyMsgId(self.IsPlanBTParam and ChatMenuSystem.EShowLocationType.PlanBT or self.eShowLocationType, nil, self.params and self.params.CliSourceId, self.uid)
  log(bWriteLog and "Personal_Info_UIBP:OnClickedAddButton msgId = " .. tostring(msgId))
  self:ReportTLog(self.uid, "AddFriend")
  local logic_teamquick_join = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_teamquick_join)
  local sId = logic_teamquick_join:GetAvatarTeamID()
  local tabType = sId and LogicFriend.TabType.FlashTeamMemberCard or LogicFriend.TabType.MainCityInfoCard
  if self.IsPlanBTParam then
    tabType = LogicFriend.TabType.PlanBT
  end
  UIManager.ShowUI(UIManager.UI_Config.friend_verify, {
    self.uid
  }, tabType, msgId)
  if not sId then
    return
  end
  if UIManager.GetUI(UIManager.UI_Config.Lobby_InviteFriend_BP) then
    local logic_friend_list_ui = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_friend_list_ui)
    local tabID = logic_friend_list_ui:GetTabID()
    if tabID == 6 then
      local tlog_report_utils = require("client.slua.config.tlog.tlog_report_utils")
      tlog_report_utils.ReportTLogEvent(TLogEventDefine.QuickTeamAddFriend, 0, tostring(sId) .. "_" .. tostring(self.uid))
    end
  elseif UIManager.GetUI(UIManager.UI_Config.ui_chat_main) then
    local uichat = UIManager.GetUI(UIManager.UI_Config.ui_chat_main)
    if uichat and uichat.LoopScrollBox_ChannelTabs and uichat.LoopScrollBox_ChannelTabs.GetSelectIndex and uichat.LoopScrollBox_ChannelTabs:GetSelectIndex() == 4 then
      local tlog_report_utils = require("client.slua.config.tlog.tlog_report_utils")
      tlog_report_utils.ReportTLogEvent(TLogEventDefine.QuickTeamAddFriend, 2, tostring(sId) .. "_" .. tostring(self.uid))
    end
  end
end
function Personal_Info_UIBP:OnClickButton_Chat()
  log(bWriteLog and "Personal_Info_UIBP:OnClickButton_Chat")
  self:PlayAudio(sound_config.click_v1)
  local LogicFriend = require("client.slua.logic.friend.logic_new_friend")
  local isFriend = LogicFriend.IsMyFriend(self.uid)
  log(bWriteLog and "Personal_Info_UIBP:OnClickButton_Chat isFriend = " .. tostring(isFriend))
  if isFriend then
    local logic_chat_main = require("client.slua.logic.lobby_chat.logic_chat_main")
    logic_chat_main.OpenChatMainByFriendId(self.uid)
    self:ReportTLog(self.uid, "Chat")
    self:CloseSelf()
  end
end
function Personal_Info_UIBP:OnClickButton_Play1()
  log(bWriteLog and "Personal_Info_UIBP:OnClickButton_Play1")
  self:PlayAudio(sound_config.click_v1)
end
function Personal_Info_UIBP:OnClickButton_Play2()
  log(bWriteLog and "Personal_Info_UIBP:OnClickButton_Play2")
  self:PlayAudio(sound_config.click_v1)
end
function Personal_Info_UIBP:OnClickHeadCallback()
  log(bWriteLog and "Personal_Info_UIBP:OnClickHeadCallback")
  self:PlayAudio(sound_config.click_v1)
  local LogicFitVersionDownload = require("client.slua.logic.download.fit.logic_fitVersion_download")
  if not LogicFitVersionDownload.IsFitLobbyResDownloaded() then
    LogicFitVersionDownload.ShowFullLobbyResDownloadPopup()
    return
  end
  local Lobby_Main_City = require("client.slua.logic.lobby.MainCity.Lobby_Main_City")
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  Lobby_Main_City.EnterRoleSpace(self.uid, RoleInfoMainSystem.RoleInfoOpenFromType.MainCityInfoCard)
  local MCActionConfig = require("GameLua.Mod.MainCity.Gameplay.Config.MCActionConfig")
  EventSystem:postEvent(EVENTTYPE_MAINCITY, EVENTID_MAINCITY_PLAYER_INFO_CARD_TRIG_ACTION, MCActionConfig.TriggerActionEmoteId.CheckProfile)
  EventSystem:postEvent(EVENTTYPE_ACTIVITY, EVENTID_BARGAIN_PLAYER_INFO_CARD_TRIG_ACTION)
  local str = "from:ButtonHead;uid:" .. tostring(self.uid)
  local logic_return_tlog_report = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_return_tlog_report)
  logic_return_tlog_report:ReportReturnTLogEvent(TLogEventDefine.Click_Friend_To_SocialSpeace, 0, str)
  self:CloseSelf()
end
function Personal_Info_UIBP:OnCharmLevelChanged(_, _, nPlayerUID, nCharmLevel, bShowCharm)
  printf("Personal_Info_UIBP:OnCharmLevelChanged nPlayerUID = %s, nCharmLevel = %s, bShowCharm = %s", nPlayerUID, nCharmLevel, bShowCharm)
  if nPlayerUID == tonumber(self.uid) then
    self:RefreshCharmLevel(nCharmLevel, bShowCharm)
  end
end
function Personal_Info_UIBP:UpdateUI()
  log(bWriteLog and "Personal_Info_UIBP:UpdateUI")
  self:SetContent()
  self:RefreshInfo()
  self:RefreshCharmLevel()
  self:UpdateCustomPresentation()
  self:ShowReturnFlag()
  self:ShowRPFlag()
end
function Personal_Info_UIBP:RefreshExtendButton()
  local logic_friend_gift = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_friend_gift)
  local isCanSendCoin = logic_friend_gift:CanSendCoin(self.uid)
  self:SetWidgetVisible(self.UIRoot.SizeBox_BP, isCanSendCoin, true)
  self:SetWidgetVisible(self.UIRoot.Button_Club, false, true)
  self:SetWidgetVisible(self.UIRoot.Image_68, false, false)
  local logic_home_entry = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_home_entry)
  local isPlanPHMode = logic_home_entry:IsPlanPHMode()
  local logic_community = require("client.slua.logic.community.logic_community")
  if self.eShowLocationType ~= ChatMenuSystem.EShowLocationType.PlanZMember and logic_community.GetShowEntry() and UIManager.IsUIShow(UIManager.UI_Config.ui_room_waiting) == false and not isPlanPHMode then
    logic_community.IsUserClubMember(self.uid, self.UIRoot, function(bIsMember)
      if bIsMember and slua.isValid(self.UIRoot) then
        self:SetWidgetVisible(self.UIRoot.Button_Club, true, true)
        self:SetWidgetVisible(self.UIRoot.Image_68, true, false)
      end
    end)
  end
  local showMoment = true
  local MatchModeMgrSystem = require("client.slua.logic.match.logic_mode_mgr")
  local myselfOnIsland = MatchModeMgrSystem.IsSocialIslandMode()
  local SingleTrainTool = require("GameLua.Mod.SingleTraining.GamePlay.Data.SingleTrainTool")
  local isInSingleTraining = SingleTrainTool.IsSelfInTraining()
  if not LobbySystem.CheckOpen(BP_ENUM_MOMENT_SWITCH) or myselfOnIsland or isPlanPHMode or self.eShowLocationType == ChatMenuSystem.EShowLocationType.TPlanTeamPlatform or self.eShowLocationType == ChatMenuSystem.EShowLocationType.PlanZMember or self.eShowLocationType == ChatMenuSystem.EShowLocationType.PlanPHPlayerList or isInSingleTraining then
    showMoment = false
  end
  self:SetWidgetVisible(self.UIRoot.Button_Moment, showMoment, true)
  self:SetWidgetVisible(self.UIRoot.Image_Line, showMoment, true)
  local LogicFriend = require("client.slua.logic.friend.logic_new_friend")
  local isFriend = LogicFriend.IsMyFriend(self.uid)
  if isFriend then
    self.UIRoot.Button_Remark:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
    self.UIRoot.Image_66:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
  else
    self.UIRoot.Button_Remark:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
    self.UIRoot.Image_66:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  end
  local bShouldShowInteractRecord = isFriend and LobbySystem.CheckLobbyMenuOpen(BP_ENUM_MODULE_FRIEND_INTERACT_RECORD) and not myselfOnIsland
  self:SetWidgetVisible(self.UIRoot.Button_InteractRecord, bShouldShowInteractRecord, true)
  self:SetWidgetVisible(self.UIRoot.Image_64, bShouldShowInteractRecord, true)
  local UIUtil = require("client.common.ui_util")
  if not (self.eShowLocationType ~= ChatMenuSystem.EShowLocationType.Chat and self.eShowLocationType ~= ChatMenuSystem.EShowLocationType.PlanZMember and (self.eShowLocationType ~= ChatMenuSystem.EShowLocationType.Teammate or isFriend)) or self.eShowLocationType == ChatMenuSystem.EShowLocationType.Assembly or self.eShowLocationType == ChatMenuSystem.EShowLocationType.MainCity then
    self.UIRoot.Button_Pinbi:SetWidgetVisibility(UIUtil.BoolToVisible(true, true, true))
    self.UIRoot.Image_42:SetWidgetVisibility(UIUtil.BoolToVisible(true, true, true))
  else
    self.UIRoot.Button_Pinbi:SetWidgetVisibility(UIUtil.BoolToVisible(self.bShowPinbi, true, true))
    self.UIRoot.Image_42:SetWidgetVisibility(UIUtil.BoolToVisible(self.bShowPinbi, true, true))
  end
  self.UIRoot.Button_AddFriened:SetWidgetVisibility(UIUtil.BoolToVisible(not isFriend, true, true))
  self:ApplyPlanBTHideWidgets()
end
function Personal_Info_UIBP:SetContent()
  log(bWriteLog and "Personal_Info_UIBP:SetContent")
  self.UIRoot.TextBlock_Report:SetText(LocUtil.GetLocalizeResStr(638))
  self.UIRoot.TextBlock_Collect:SetText(LocUtil.GetLocalizeResStr(73314))
  self.UIRoot.TextBlock_Prosperity:SetText(LocUtil.GetLocalizeResStr(64754))
  self.UIRoot.TextBlock_Popularity:SetText(LocUtil.GetLocalizeResStr(64756))
  self.UIRoot.TextBlock_Interact:SetText(LocUtil.GetLocalizeResStr(73315))
  self.UIRoot.TextBlock_Play:SetText(LocUtil.GetLocalizeResStr(73316))
  self.UIRoot.TextBlock_Play1:SetText(LocUtil.GetLocalizeResStr(73317))
  self.UIRoot.TextBlock_Play2:SetText(LocUtil.GetLocalizeResStr(73318))
end
function Personal_Info_UIBP:RefreshInfo()
  log(bWriteLog and "Personal_Info_UIBP:RefreshInfo")
  local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
  local profile = logic_profile:GetLocalProfile(self.uid)
  if not profile or not profile.rankdata then
    local logic_profile_get_wrap = require("client.slua.logic.user.profile.logic_profile_get_wrap")
    logic_profile_get_wrap.GetRankProfiles(Enum_PROFILE_REPORT_CFG.MAINCITY_INFOCARD, {
      self.uid
    }, function(listInfo)
      log(bWriteLog and "Personal_Info_UIBP:RefreshInfo get rank profile")
      if listInfo and listInfo[1] and tonumber(listInfo[1].uid) == tonumber(self.uid) and self.UIRoot then
        self:SetWidgetVisible(self.UIRoot.CanvasPanel_48, true, false)
        self:RefreshBasicInfo(listInfo[1])
        self:RefreshInteractButton()
        self:RefreshPlayerData(listInfo[1])
        self:ChangeTextColorBySkin()
      end
    end)
    return
  else
    self:SetWidgetVisible(self.UIRoot.CanvasPanel_48, true, false)
  end
  log_tree(bWriteLog and "Personal_Info_UIBP:RefreshInfo profile = ", profile)
  self:RefreshBasicInfo(profile)
  self:RefreshInteractButton()
  self:RefreshPlayerData(profile)
  self:ChangeTextColorBySkin()
end
function Personal_Info_UIBP:RefreshBasicInfo(profile)
  log(bWriteLog and "Personal_Info_UIBP:RefreshBasicInfo")
  self:SetWidgetVisible(self.UIRoot.CanvasPanel_More, false, false)
  self:_RefreshAlisaInfo(profile)
  self.UIRoot.Common_Avatar_BP:InitView(1, self.uid, profile.picUrl, profile.sex, profile.cur_avatar_box_id, profile.level, false, "")
  self.UIRoot.Common_Gender_UIBP:LoadIcon(self.uid)
  self.UIRoot.TextBlock_Name:SetText(profile.nickName or "")
  local LogicFriend = require("client.slua.logic.friend.logic_new_friend")
  local name = LogicFriend.GetRemark(self.uid)
  if name then
    self.UIRoot.TextBlock_Name:SetText(name)
  end
  local NicknameColorManager = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.NicknameColorManager)
  self.UIRoot.TextBlock_Name:SetColorAndOpacity(NicknameColorManager:GetColorByUID(profile.uid))
  self:HaveNameColor(profile)
  self:_RefreshTeamState()
  self:RefreshSocialCardLabelInfo(profile)
  self:SetFriendState(profile)
  local UIUtil = require("client.common.ui_util")
  local platformIcon = UIUtil.GetPlatformlIcon(self.uid)
  if platformIcon then
    self:SetTexture(self.UIRoot.Image_Platform, platformIcon)
    self.UIRoot.Image_Platform:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    local PublishRegionMacros = require("client.slua.config.ClientMacros.PublishRegionMacros")
    if PublishRegionMacros.IsBlueholeFamily() and (BP_Platform == BP_ENUM_PLAYFORM_WX or BP_Platform == BP_ENUM_PLAYFORM_BGBGByiTOP) then
      self.UIRoot.Image_Platform:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
    end
  else
    self.UIRoot.Image_Platform:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  end
  if self.UIRoot.Common_LightBoard_UIBP then
    self.UIRoot.Common_LightBoard_UIBP:ShowLightBoard(self.uid)
    self.UIRoot.CanvasPanel_Family:SetWidgetVisibility(self.UIRoot.Common_LightBoard_UIBP:GetVisibility())
  end
  UIUtil.UpdateNationImage(self.UIRoot.Image_Flag, profile.nation)
  self:SetPeakGameRank(profile)
  self.corp_alias_id = profile.corp_alias_id or 0
  local corpsID = profile.corps_id or 0
  self.UIRoot.UTRichTextBlock_0:SetText(LocUtil.GetLocalizeResStr(5085))
  if 0 < corpsID then
    ChatMenuSystem.get_corps_summary_req(corpsID, tonumber(self.uid))
  else
    self.UIRoot.WidgetSwitcher_Juntuan:setActiveWidgetIndex(1)
  end
  local logic_friend_list = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_friend_list)
  local intimacy = logic_friend_list:GetIntimacy(self.uid) or 0
  self.UIRoot.Text_Intimacy:SetText(tostring(intimacy))
  if 0 < intimacy then
    self.UIRoot.HorizontalBox_20:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
  else
    self.UIRoot.HorizontalBox_20:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  end
  local isMainCity = self.eShowLocationType and self.eShowLocationType == ChatMenuSystem.EShowLocationType.MainCity or false
  if not isMainCity then
    local isFriend = LogicFriend.IsMyFriend(self.uid)
    if isFriend then
      local logic_friend_interact_record = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_friend_interact_record)
      local interactData = logic_friend_interact_record:GetCumulativeInteractRecordDataHighFrequency(self.uid)
      local dayFriendDays = 0
      if interactData and interactData.add_friend_days then
        dayFriendDays = interactData.add_friend_days
      end
      local bValidDays = logic_friend_interact_record.IsAddFriendDaysValid(dayFriendDays)
      self.UIRoot.Button_FriendsGoTo:SetWidgetVisibility(bValidDays and UEnums.ESlateVisibility.Visible or UEnums.ESlateVisibility.Collapsed)
      self.UIRoot.Text_FriendsGoTo:SetText(LocUtil.LocalizeResFormat(45024))
      self.UIRoot.TextBlock_Number:SetText(dayFriendDays)
      self.UIRoot.TextBlock_Day:SetText(LocUtil.LocalizeResFormat(44861))
      if 0 < intimacy or 0 < dayFriendDays then
        self.UIRoot.CanvasPanel_32:SetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
      else
        self.UIRoot.CanvasPanel_32:SetVisibility(UEnums.ESlateVisibility.Collapsed)
      end
    else
      self.UIRoot.Button_FriendsGoTo:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
      self.UIRoot.CanvasPanel_32:SetVisibility(UEnums.ESlateVisibility.Collapsed)
    end
  end
end
function Personal_Info_UIBP:_RefreshAlisaInfo(profile)
  log(bWriteLog and "Personal_Info_UIBP:_RefreshAlisaInfo")
  if profile.alias and profile.alias.id and profile.alias.id > 0 then
    self.UIRoot.Title_UIBP:SetAliasInfo(profile.alias.id or 0, profile.alias.title or "", profile.alias.nation or "", 0, profile.alias.rank_id or 0)
    self:SetWidgetVisible(self.UIRoot.Title_UIBP, true, false)
  else
    self:SetWidgetVisible(self.UIRoot.Title_UIBP, false, false)
  end
end
function Personal_Info_UIBP:_RefreshTeamState()
  log(bWriteLog and "Personal_Info_UIBP:_RefreshTeamState")
  self:SetWidgetVisible(self.UIRoot.TextBlock_State, false, false)
  local bHasRefresh = false
  local logic_team_up = require("client.slua.logic.teamup.logic_team_up")
  for uid, v in pairs(logic_team_up.teamInfo.members or {}) do
    if tonumber(self.uid) == tonumber(uid) and tonumber(uid) ~= DataMgr.roleData.uid then
      self.UIRoot.TextBlock_State:SetText(LocUtil.LocalizeResFormat(65074, LocUtil.GetLocalizeResStr(73319)))
      self:SetWidgetVisible(self.UIRoot.TextBlock_State, true, false)
      bHasRefresh = true
      break
    end
  end
  if not bHasRefresh then
    local LogicFriend = require("client.slua.logic.friend.logic_new_friend")
    local isFriend = LogicFriend.IsMyFriend(self.uid)
    if isFriend then
      self.UIRoot.TextBlock_State:SetText(LocUtil.LocalizeResFormat(65074, LocUtil.GetLocalizeResStr(64748)))
      self:SetWidgetVisible(self.UIRoot.TextBlock_State, true, false)
    end
  end
  if self.eShowLocationType ~= ChatMenuSystem.EShowLocationType.MainCity then
    self:SetWidgetVisible(self.UIRoot.TextBlock_State, false, false)
  end
end
function Personal_Info_UIBP:_RefreshBirthdayInfo(profile)
  log(bWriteLog and "Personal_Info_UIBP:_RefreshBirthdayInfo")
  local socialCard
  if self.isSelf then
    local SocialCardSystem = require("client.slua.logic.lobby.Left.logic_social_card")
    if SocialCardSystem and SocialCardSystem.MySocialCard then
      socialCard = SocialCardSystem.MySocialCard or {}
    end
  else
    socialCard = profile.social_card or {}
  end
  log_tree(bWriteLog and "Personal_Info_UIBP:_RefreshBirthdayInfo socialCard = ", socialCard)
  local GetBirthdayInfo = function()
    local birthYMD
    if socialCard.birthday and socialCard.birthday ~= "" then
      local TimeUtil = require("client.common.time_util")
      local StringUtil = require("common.string_util")
      local ymd = StringUtil.Split(socialCard.birthday, "-")
      local strRegion = Client.GetPublishRegion()
      local PublishRegionMacros = require("client.slua.config.ClientMacros.PublishRegionMacros")
      if self.isSelf and (PublishRegionMacros.IsJapanOrKorea() or PublishRegionMacros.IsBlueholeFamily()) then
        birthYMD = TimeUtil.GetBirthdayTimeFormat(tostring(ymd[1]), tonumber(ymd[2]), tonumber(ymd[3]))
      else
        birthYMD = TimeUtil.GetBirthdayTimeFormat_MD(tonumber(ymd[2]), tonumber(ymd[3]))
      end
    end
    log(bWriteLog and "Personal_Info_UIBP:_RefreshBirthdayInfo GetBirthdayInfo birthYMD = " .. tostring(birthYMD))
    return birthYMD
  end
  local resultBirthYMD = ""
  local SettingUtil = require("client.slua.logic.setting.setting_util")
  if LobbySystem.CheckOpen(BP_ENUM_ONLY_FRIENFRIEND_PRIVACY) then
    if SettingUtil.OnlyFriend(self.uid, profile.birthday_privacy_value, 1) or profile.birthday_privacy_value == 1 then
      resultBirthYMD = GetBirthdayInfo()
    end
  else
    resultBirthYMD = GetBirthdayInfo()
  end
  local AnalyzeInteractiveState = function(State)
    if State == 0 then
      return LocUtil.GetLocalizeResStr(73336)
    end
    local firstState
    local MainCityCoreConst = require("GameLua.Mod.MainCity.Gameplay.Core.MainCityCoreConst")
    for k, v in pairs(MainCityCoreConst.EMainCityInteractiveStateTypeFlag) do
      if State & v ~= 0 then
        firstState = v
        break
      end
    end
    if firstState then
      local stateTextID = MainCityCoreConst.StateTextID[firstState]
      if stateTextID then
        return LocUtil.GetLocalizeResStr(stateTextID)
      end
    end
    return LocUtil.GetLocalizeResStr(73336)
  end
  self:SetWidgetVisible(self.UIRoot.TextBlock_Birthday, false, false)
  local MainCity_PlayerCharacter_Manager = require("GameLua.Mod.MainCity.Gameplay.Core.MainCity_PlayerCharacter_Manager")
  local playerCharacter = MainCity_PlayerCharacter_Manager.GetCharacter(tonumber(self.uid))
  if Game:IsValid(playerCharacter) then
    local playerState = playerCharacter:GetPlayerStateSafety()
    if Game:IsValid(playerState) then
      local State = playerState.InteractivePlayerStateFeature.InteractiveState
      local StateText = AnalyzeInteractiveState(State)
      self.UIRoot.TextBlock_Birthday:SetText(StateText)
      self:SetWidgetVisible(self.UIRoot.TextBlock_Birthday, true, false)
    end
  end
  self:_RefreshSocialCardLabelInfo(socialCard)
end
function Personal_Info_UIBP:RefreshSocialCardLabelInfo(profile)
  local socialCard
  if self.isSelf then
    local SocialCardSystem = require("client.slua.logic.lobby.Left.logic_social_card")
    if SocialCardSystem and SocialCardSystem.MySocialCard then
      socialCard = SocialCardSystem.MySocialCard or {}
    end
  else
    socialCard = profile.social_card or {}
  end
  self:_RefreshSocialCardLabelInfo(socialCard)
end
function Personal_Info_UIBP:_RefreshSocialCardLabelInfo(socialCard)
  log(bWriteLog and "Personal_Info_UIBP:_RefreshSocialCardLabelInfo")
  self:SetWidgetVisible(self.UIRoot.HorizontalBox_Label, false, false)
  if socialCard == nil or not next(socialCard) then
    return
  end
  local labelResult = {}
  local SocialCardSystem = require("client.slua.logic.lobby.Left.logic_social_card")
  if socialCard.tendency and type(socialCard.tendency) == "number" then
    local tendency = SocialCardSystem.GetTendencyList()
    local partner = tendency[socialCard.tendency]
    if partner then
      local content = LocUtil.LocalizeResFormat(656086, partner)
      table.insert(labelResult, content)
    end
  end
  local date = ""
  local time = ""
  if socialCard.play_date and type(socialCard.play_date) == "number" then
    local listDate = SocialCardSystem.GetDataList()
    date = listDate[socialCard.play_date] or ""
  end
  if socialCard.play_time and type(socialCard.play_time) == "number" then
    local timeList = SocialCardSystem.GetTimeList()
    time = timeList[socialCard.play_time] or ""
  end
  local timeValue = ""
  if date ~= "" and time ~= "" then
    timeValue = LocUtil.LocalizeResFormat(45903, tostring(date), tostring(time))
  elseif date == "" and time == "" then
  else
    timeValue = tostring(date) .. tostring(time)
  end
  if timeValue and timeValue ~= "" then
    table.insert(labelResult, timeValue)
  end
  local CardTagList = SocialCardSystem.UnifyCardData(socialCard)
  for _, value in pairs(CardTagList) do
    table.insert(labelResult, value)
  end
  log_tree(bWriteLog and "Personal_Info_UIBP:_RefreshSocialCardLabelInfo labelResult = ", labelResult)
  self:SetWidgetVisible(self.UIRoot.HorizontalBox_Label, true, false)
  for i = 1, 2 do
    if labelResult[i] then
      self.UIRoot["TextBlock_Label" .. tostring(i)]:SetText(labelResult[i])
      self:SetWidgetVisible(self.UIRoot["Button_Label" .. tostring(i)], true, false)
    else
      self:SetWidgetVisible(self.UIRoot["Button_Label" .. tostring(i)], false, false)
    end
  end
end
function Personal_Info_UIBP:_RefreshFriendState(profile)
  log(bWriteLog and "Personal_Info_UIBP:_RefreshBirthdayInfo")
  local stateVisible = false
  local stateWidgets = {
    self.UIRoot.Image_State,
    self.UIRoot.TextBlock_0,
    self.UIRoot.SizeBox_Desc,
    self.UIRoot.Image_DescLine01
  }
  self:SetWidgetVisible(self.UIRoot.TextBlock_0, false, false)
  local TimeUtil = require("client.common.time_util")
  local frd_status_id = profile.frd_status_id
  local logic_main_city_status = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_main_city_status)
  local now_time = TimeUtil.GetServerTimeInSec()
  local frd_status_end_time = profile.frd_status_end_time
  if frd_status_end_time and now_time > frd_status_end_time then
    frd_status_id = 0
  end
  local status = logic_main_city_status:GetMCPlayerStatus(self.uid)
  if status ~= 0 then
    frd_status_id = status
  end
  log(bWriteLog and "Personal_Info_UIBP:_RefreshBirthdayInfo frd_status_id = " .. tostring(frd_status_id) .. " now_time = " .. tostring(now_time) .. " frd_status_end_time = " .. tostring(frd_status_end_time))
  self.UIRoot.Image_State:SetRenderScale(FVector2D(1, 1))
  if frd_status_id and 0 < frd_status_id and frd_status_id ~= 13 then
    local cfg = CDataTable.GetTableData("FriendStatusCfg", frd_status_id)
    local PlayerStatusEnum = require("client.slua.logic.player_status.PlayerStatusEnum")
    if cfg and cfg.type ~= PlayerStatusEnum.Enum_TeamState.Stealth then
      stateVisible = true
      self:SetTexture(self.UIRoot.Image_State, cfg.icon_url)
      self.UIRoot.TextBlock_0:SetText(cfg.name)
    end
  elseif frd_status_id and frd_status_id == 13 and profile.frd_custom_txt and profile.frd_custom_txt ~= "" and profile.frd_icon_idx and profile.frd_icon_idx ~= 0 then
    local path = "/Game/UMG/Texture/Atlas/ChatEmojiUI/Frames/emoji_1_50_" .. tostring(profile.frd_icon_idx) .. "_png.emoji_1_50_" .. tostring(profile.frd_icon_idx) .. "_png"
    self.UIRoot.Image_State:SetRenderScale(FVector2D(0.8, 0.8))
    stateVisible = true
    self:SetTexture(self.UIRoot.Image_State, path)
    self.UIRoot.TextBlock_0:SetText(profile.frd_custom_txt)
  end
  for _, widget in pairs(stateWidgets) do
    if widget then
      self:SetWidgetVisible(widget, stateVisible, false)
    end
  end
end
function Personal_Info_UIBP:RefreshInteractButton()
  log(bWriteLog and "Personal_Info_UIBP:RefreshInteractButton")
  if not self.UIRoot then
    return
  end
  if self.isSelf then
    self:SetWidgetVisible(self.UIRoot.VerticalBox_Interact, false, false)
    self:SetWidgetVisible(self.UIRoot.VerticalBox_Play, false, false)
    return
  end
  self:SetWidgetVisible(self.UIRoot.VerticalBox_Interact, true, false)
  self:SetWidgetVisible(self.UIRoot.VerticalBox_Play, false, false)
  local LogicFriend = require("client.slua.logic.friend.logic_new_friend")
  local isFriend = LogicFriend.IsMyFriend(self.uid)
  log(bWriteLog and "Personal_Info_UIBP:RefreshInteractButton isFriend = " .. tostring(isFriend))
  if isFriend then
    self:SetWidgetVisible(self.UIRoot.SizeBox_12, false, false)
  else
    self:SetWidgetVisible(self.UIRoot.SizeBox_12, true, false)
  end
  if isFriend and not GameStatus.IsCollectionHallMode() then
    self:SetWidgetVisible(self.UIRoot.Button_Chat, true, true)
    self:SetWidgetVisible(self.UIRoot.SizeBox_13, true, false)
  else
    self:SetWidgetVisible(self.UIRoot.Button_Chat, false, true)
    self:SetWidgetVisible(self.UIRoot.SizeBox_13, false, false)
  end
  self:TryRefreshButtonState()
  local isMainCity = self.eShowLocationType and self.eShowLocationType == ChatMenuSystem.EShowLocationType.MainCity or false
  self:SetWidgetVisible(self.UIRoot.Button_SocialHall, not isMainCity, true)
  self:SetWidgetVisible(self.UIRoot.SizeBox_30, not isMainCity, false)
  self:SetWidgetVisible(self.UIRoot.Button_Home, not isMainCity, true)
  self:SetWidgetVisible(self.UIRoot.Button_CardCollect, false, true)
  self:SetWidgetVisible(self.UIRoot.SizeBox_33, false, false)
  self:SetWidgetVisible(self.UIRoot.VerticalBox_Interact, isMainCity)
  self:SetHomeEntry()
  self:SetCollectHallEntry()
  self.UIRoot.WidgetSwitcher_MainCity:SetActiveWidgetIndex(isMainCity and 0 or 1)
  local MatchModeMgrSystem = require("client.slua.logic.match.logic_mode_mgr")
  local myselfOnIsland = MatchModeMgrSystem.IsSocialIslandMode()
  local LogicTxMissionMain = require("client.slua.logic.TxMission.logic_xmission_main")
  local bShouldShowSouvenir = LogicTxMissionMain.IsInXMission() and not myselfOnIsland and LobbySystem.CheckLobbyMenuOpen(BP_ENUM_SWITCH_SOUVENIRS, false)
  self:SetWidgetVisible(self.UIRoot.Button_Souvenirs, bShouldShowSouvenir, true)
  self:SetWidgetVisible(self.UIRoot.SizeBox_31, bShouldShowSouvenir, false)
  local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
  local profile = logic_profile:GetLocalProfile(self.uid)
  local customSwitches = self:GetPlayerCustomSwitches(profile)
  if customSwitches and customSwitches.collectLevel then
    self:SetWidgetVisible(self.UIRoot.Common_Collect_Level_DynamicLoading_UIBP, true, false)
    self.UIRoot.Common_Collect_Level_DynamicLoading_UIBP:InitCollectBadge(self.uid, profile.collect_data, true)
  else
    self:SetWidgetVisible(self.UIRoot.Common_Collect_Level_DynamicLoading_UIBP, false, false)
  end
  self:ApplyPlanBTHideWidgets()
end
function Personal_Info_UIBP:TryRefreshButtonState()
  log(bWriteLog and "Personal_Info_UIBP:TryRefreshButtonState")
  local PlayerStatusMgr = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.PlayerStatusMgr)
  PlayerStatusMgr:GetOrReqStatusData(ENUM_BATCH_GET_GROUP_AND_ONLINE.MainCityInfoCard, {
    tonumber(self.uid)
  }, function(infos)
    if infos == nil or not next(infos) then
      return
    end
    local newStatus = infos[tonumber(self.uid)]
    if not newStatus then
      return
    end
    if not slua.isValid(self.UIRoot) then
      return
    end
    self:_RefreshTeamButtonState(newStatus)
  end)
end
function Personal_Info_UIBP:ShouldShowTeamButton(status)
  if GameStatus.IsInFightingPHomeMode() then
    log(bWriteLog and "Personal_Info_UIBP:ShouldShowTeamButton me in home")
    return false
  end
  local home_macros = require("client.slua.logic.home.home_macros")
  if status and status.game_sub_mode and status.game_sub_mode == home_macros.Home_SubMode.Visit then
    log(bWriteLog and "Personal_Info_UIBP:ShouldShowTeamButton target in home")
    return false
  end
  if GameStatus.IsCollectionHallMode() then
    log(bWriteLog and "Personal_Info_UIBP:ShouldShowTeamButton me in  hall")
    return false
  end
  local PlayerStatusUtil = require("client.slua.logic.player_status.PlayerStatusUtil")
  if PlayerStatusUtil.IsInCollectionHall(status) then
    log(bWriteLog and "Personal_Info_UIBP:ShouldShowTeamButton target in collection hall")
    return false
  end
  return true
end
function Personal_Info_UIBP:_RefreshTeamButtonState(status)
  log_tree(bWriteLog and "Personal_Info_UIBP:_RefreshTeamButtonState status = ", status)
  self:SetWidgetVisible(self.UIRoot.WidgetSwitcher_Team, false, false)
  self:SetWidgetVisible(self.UIRoot.SizeBox_10, false, false)
  if not self:ShouldShowTeamButton(status) then
    return
  end
  local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
  local profile = logic_profile:GetLocalProfile(self.uid)
  if not profile then
    log(bWriteLog and "Personal_Info_UIBP:_RefreshTeamButtonState no profile")
    return
  end
  local PlayerStatusEnum = require("client.slua.logic.player_status.PlayerStatusEnum")
  local isBusy = false
  if profile.frd_status_id and profile.frd_status_id > 0 then
    local cfg = CDataTable.GetTableData("FriendStatusCfg", profile.frd_status_id)
    if cfg and cfg.type == PlayerStatusEnum.Enum_TeamState.Busy then
      isBusy = true
    end
  end
  log(bWriteLog and string.format("Personal_Info_UIBP:RefreshTeamAction, profile.frd_status_id: %s, isBusy: %s", profile.frd_status_id or -1, isBusy))
  if status.online == 0 then
    return
  end
  local isDoNotBother = PlayerStatusUtil.IsDoNotBother(status)
  local LogicFriend = require("client.slua.logic.friend.logic_new_friend")
  local bFriend = LogicFriend.IsMyFriend(self.uid)
  log(bWriteLog and "Personal_Info_UIBP:_RefreshTeamButtonState isDoNotBother = " .. tostring(isDoNotBother) .. " bFriend = " .. tostring(bFriend))
  local TeamUpNewSystem = require("client.slua.logic.teamup.logic_team_up")
  if (PlayerStatusUtil.IsIdleOrFree(status) or PlayerStatusUtil.ISLANDIdle(status) or PlayerStatusUtil.IsInHomeIdle(status) or PlayerStatusUtil.WoWIdle(status) or PlayerStatusUtil.IsMainCityIdle(status)) and TeamUpNewSystem.CanInvite() and not isBusy then
    log(bWriteLog and "Personal_Info_UIBP:_RefreshTeamButtonState 1")
    local PlayerStatusMgr = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.PlayerStatusMgr)
    local is_video_inspect = status and status.is_video_inspect or PlayerStatusMgr:GetIsVideoInspect(self.uid)
    log(bWriteLog and "Personal_Info_UIBP:_RefreshTeamButtonState is_video_inspect = " .. tostring(is_video_inspect))
    if is_video_inspect then
      self:SetWidgetVisible(self.UIRoot.WidgetSwitcher_Team, true, false)
      self:SetWidgetVisible(self.UIRoot.SizeBox_10, true, false)
      self.UIRoot.WidgetSwitcher_Team:SetActiveWidgetIndex(1)
    else
      self:SetWidgetVisible(self.UIRoot.WidgetSwitcher_Team, true, false)
      self:SetWidgetVisible(self.UIRoot.SizeBox_10, true, false)
      self.UIRoot.WidgetSwitcher_Team:SetActiveWidgetIndex(0)
    end
  elseif (PlayerStatusUtil.IsTeam(status) or PlayerStatusUtil.ISLANDInTeam(status) or PlayerStatusUtil.IsInHomeTeam(status) or PlayerStatusUtil.WoWInTeam(status) or PlayerStatusUtil.IsMainCityTeam(status)) and not TeamUpNewSystem.IsInTeam() and status.currentTeamAmount < status.maxTeamAmount and not isBusy then
    log(bWriteLog and "Personal_Info_UIBP:_RefreshTeamButtonState 2")
    self:SetWidgetVisible(self.UIRoot.WidgetSwitcher_Team, true, false)
    self.UIRoot.WidgetSwitcher_Team:SetActiveWidgetIndex(1)
    self:SetWidgetVisible(self.UIRoot.SizeBox_10, true, false)
  elseif bFriend and isDoNotBother then
    log(bWriteLog and "Personal_Info_UIBP:_RefreshTeamButtonState 3")
    self:SetWidgetVisible(self.UIRoot.WidgetSwitcher_Team, true, false)
    self.UIRoot.WidgetSwitcher_Team:SetActiveWidgetIndex(0)
    self:SetWidgetVisible(self.UIRoot.SizeBox_10, true, false)
  else
    log(bWriteLog and "Personal_Info_UIBP:_RefreshTeamButtonState 4")
  end
end
function Personal_Info_UIBP:_RefreshGameplayButtonState(status)
  log_tree(bWriteLog and "Personal_Info_UIBP:_RefreshGameplayButtonState status = ", status)
  self:SetWidgetVisible(self.UIRoot.VerticalBox_Play, false, false)
  local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
  local profile = logic_profile:GetLocalProfile(self.uid)
  if not profile then
    log(bWriteLog and "Personal_Info_UIBP:_RefreshGameplayButtonState no profile")
    return
  end
  local PlayerStatusEnum = require("client.slua.logic.player_status.PlayerStatusEnum")
  local isBusy = false
  if profile.frd_status_id and profile.frd_status_id > 0 then
    local cfg = CDataTable.GetTableData("FriendStatusCfg", profile.frd_status_id)
    if cfg and cfg.type == PlayerStatusEnum.Enum_TeamState.Busy then
      isBusy = true
    end
  end
  log(bWriteLog and string.format("Personal_Info_UIBP:_RefreshGameplayButtonState, profile.frd_status_id: %s, isBusy: %s", profile.frd_status_id or -1, isBusy))
  if isBusy then
    return
  end
  local isDoNotBother = PlayerStatusUtil.IsDoNotBother(status)
  local LogicFriend = require("client.slua.logic.friend.logic_new_friend")
  local bFriend = LogicFriend.IsMyFriend(self.uid)
  log(bWriteLog and "Personal_Info_UIBP:_RefreshGameplayButtonState isDoNotBother = " .. tostring(isDoNotBother) .. " bFriend = " .. tostring(bFriend))
  if isDoNotBother then
    if bFriend then
      self:SetWidgetVisible(self.UIRoot.VerticalBox_Play, true, false)
    end
  else
    self:SetWidgetVisible(self.UIRoot.VerticalBox_Play, true, false)
  end
end
function Personal_Info_UIBP:RefreshPlayerData(profile)
  log(bWriteLog and "Personal_Info_UIBP:RefreshPlayerData")
  self:_RefreshRankData(profile)
end
function Personal_Info_UIBP:_RefreshRankData(profile)
  log(bWriteLog and "Personal_Info_UIBP:_RefreshRankData")
  local logic_season_util = require("client.logic.season.logic_season_util")
  local maxSegment, maxZoneId, maxModeId = logic_season_util:GetCurrAllZoneMaxSegment(profile.segment_info)
  local logic_segment_title = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_segment_title)
  local segmentTitleId = logic_segment_title:GetSegmentTitleId(profile.hsegment_title_det, maxZoneId, maxModeId)
  if not profile.rankdata then
    self.UIRoot.Common_RankIntegralLevel_Style_Small_UIBP:SetRankInteralWithSegmentTitle(maxSegment, nil, nil, segmentTitleId)
    self.UIRoot.TextBlock_TotalScore:SetText("")
  else
    local rating = logic_segment_title:GetProfileRankdataMaxRating(profile.rankdata)
    self.UIRoot.Common_RankIntegralLevel_Style_Small_UIBP:SetRankInteralWithSegmentTitle(maxSegment, nil, nil, segmentTitleId, rating)
    if rating and 0 < rating then
      self.UIRoot.TextBlock_TotalScore:SetText(math.floor(rating + 0.5 + FLOAT_NUMBER_TRAIL))
    else
      self.UIRoot.TextBlock_TotalScore:SetText("")
    end
  end
end
function Personal_Info_UIBP:_RefreshHomeData()
  log(bWriteLog and "Personal_Info_UIBP:_RefreshHomeData")
  local logic_home_profile = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_home_profile)
  local homeProfile = logic_home_profile:GetHomeProfileByUid(self.uid, false)
  if homeProfile and homeProfile.grow_info and homeProfile.grow_info.level then
    self:SetWidgetVisible(self.UIRoot.TextBlock_Level, true, false)
    self.UIRoot.TextBlock_Level:SetText(LocUtil.LocalizeResFormat(6417, homeProfile.grow_info.level))
  else
    self:SetWidgetVisible(self.UIRoot.TextBlock_Level, false, false)
  end
  local logic_new_friend = require("client.slua.logic.friend.logic_new_friend")
  local isFriend = logic_new_friend.IsMyFriend(self.uid) or self.isSelf
  local bShow = false
  if isFriend then
    local logic_lobby_home_entry_item_tree_item = require("client.slua.logic.home.Lobby.logic_lobby_home_entry_item_tree_item")
    local info = logic_lobby_home_entry_item_tree_item.GetShowInfo(self.uid)
    log_tree(bWriteLog and "Personal_Info_UIBP:_RefreshHomeData info = ", info)
    bShow = info.bShow
  end
  if bShow then
    self:SetWidgetVisible(self.UIRoot.CanvasPanel_Info1, true, false)
  else
    self.bNeedRefreshNormalInfoNum = self.bNeedRefreshNormalInfoNum + 1
    self:SetWidgetVisible(self.UIRoot.CanvasPanel_Info1, false, false)
  end
end
function Personal_Info_UIBP:_RefreshHomeGameplayData(detail)
  log(bWriteLog and "Personal_Info_UIBP:_RefreshHomeGameplayData")
  log_tree(bWriteLog and "Personal_Info_UIBP:_RefreshHomeGameplayData detail = ", detail)
  local HomePartyUtil = require("client.slua.logic.homeparty.HomePartyUtil")
  local party_show_info = detail.party_show_info
  local isShowParty = HomePartyUtil.IsShowParty(self.uid, party_show_info)
  if isShowParty then
    if not self.Common_Home_Party_Item_UIBP then
      local componentClass = require(UIManager.UI_Config.Common_Home_Party_Item_UIBP.moduleName)
      self.Common_Home_Party_Item_UIBP = componentClass({
        uid = self.uid,
        partyInfo = detail.party_show_info
      })
      self.Common_Home_Party_Item_UIBP:InitWithParentWidget(self, self.UIRoot.Common_Home_Party_Item_UIBP)
    else
      self.Common_Home_Party_Item_UIBP:UpdateUI(self.uid, detail.party_show_info)
    end
    self:SetWidgetVisible(self.UIRoot.CanvasPanel_Info4, true, false)
  else
    self.bNeedRefreshNormalInfoNum = self.bNeedRefreshNormalInfoNum + 1
    self:SetWidgetVisible(self.UIRoot.CanvasPanel_Info4, false, false)
  end
  self:SetWidgetVisible(self.UIRoot.CanvasPanel_Info2, false, false)
  self:SetWidgetVisible(self.UIRoot.CanvasPanel_Info3, false, false)
  if self.bNeedRefreshNormalInfoNum > 0 then
    local totalStructureProsperity = detail.grow_info.prosperity_detail[1] or 0
    local totalDecorateProsperity = detail.grow_info.prosperity_detail[2] or 0
    local totalOthersProsperity = detail.grow_info.prosperity_detail[3] or 0
    local totalProsperity = totalStructureProsperity + totalDecorateProsperity + totalOthersProsperity
    self.UIRoot.TextBlock_ProsperityValue:SetText(totalProsperity)
    self:SetWidgetVisible(self.UIRoot.CanvasPanel_Info2, true, false)
    self.bNeedRefreshNormalInfoNum = self.bNeedRefreshNormalInfoNum - 1
  end
  if self.bNeedRefreshNormalInfoNum > 0 then
    local StringUtil = require("common.string_util")
    local popularity = StringUtil.FormatNum_KMB(detail.grow_info.total_heat)
    self.UIRoot.TextBlock_PopularityValue:SetText(popularity)
    self:SetWidgetVisible(self.UIRoot.CanvasPanel_Info3, true, false)
    self.bNeedRefreshNormalInfoNum = self.bNeedRefreshNormalInfoNum - 1
  end
end
function Personal_Info_UIBP:_RefreshDefaultHomeInfo()
  log(bWriteLog and "Personal_Info_UIBP:_RefreshDefaultHomeInfo")
  self:SetWidgetVisible(self.UIRoot.CanvasPanel_Info1, false, false)
  self:SetWidgetVisible(self.UIRoot.CanvasPanel_Info2, true, false)
  self:SetWidgetVisible(self.UIRoot.CanvasPanel_Info3, true, false)
  self:SetWidgetVisible(self.UIRoot.CanvasPanel_Info4, false, false)
  self.bNeedRefreshNormalInfoNum = 0
  self.UIRoot.TextBlock_ProsperityValue:SetText("0")
  self.UIRoot.TextBlock_PopularityValue:SetText("0")
end
function Personal_Info_UIBP:RefreshCharmLevel(nCharmLevel, bShowCharm)
  printf("Personal_Info_UIBP:RefreshCharmLevel nCharmLevel = %s, bShowCharm = %s", nCharmLevel, bShowCharm)
  if false == bShowCharm then
    printf(bWriteLog and "Personal_Info_UIBP:RefreshCharmLevel bShowCharm = false")
    self:SetWidgetVisible(self.UIRoot.Image_137, false)
    return
  end
  local CharmUtils = require("GameLua.Mod.MainCity.Client.logic.Charm.CharmUtils")
  if nil == bShowCharm then
    bShowCharm = CharmUtils.IsPlayerShownCharmDisplay(tonumber(self.uid))
    if false == bShowCharm then
      printf(bWriteLog and "Personal_Info_UIBP:RefreshCharmLevel bShowCharm = false")
      self:SetWidgetVisible(self.UIRoot.Image_137, false)
      return
    end
  end
  if nCharmLevel == nil then
    local charmValue = CharmUtils.GetCharmValueByUid(tonumber(self.uid))
    nCharmLevel = CharmUtils.CalculateCharmLevel(charmValue)
    printf("Personal_Info_UIBP:RefreshCharmLevel after nCharmLevel = %s", nCharmLevel)
  end
  local cfg = CDataTable.GetTableData("MainCityCharmLevelCfg", nCharmLevel)
  local bShow = false
  if cfg then
    local NameCardParam = cfg.NameCardParam
    if NameCardParam and NameCardParam ~= "" then
      bShow = true
    end
  end
  self:SetWidgetVisible(self.UIRoot.Image_137, bShow, false)
end
function Personal_Info_UIBP:UpdateCustomPresentation()
  log(bWriteLog and "Personal_Info_UIBP:UpdateCustomPresentation")
  if self.LobbyChat_InformationCustomDetail_UIBP then
    self.LobbyChat_InformationCustomDetail_UIBP:SetDataByUid(self.uid)
    self.LobbyChat_InformationCustomDetail_UIBP:HideBg()
  end
end
function Personal_Info_UIBP:ShowReturnFlag()
  local logic_oldfriend_care = require("client.slua.logic.oldfriend.logic_oldfriend_care")
  local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
  local profile = logic_profile:GetLocalProfile(self.uid)
  if logic_oldfriend_care.IsRejoinPlayer(profile) then
    self.UIRoot.Image_74:SetColorAndOpacity(FLinearColor(0.879623, 0.672443, 0.304987, 1))
    self.UIRoot.Image_13:SetColorAndOpacity(FLinearColor(0.879623, 0.672443, 0.304987, 1))
    self:SetWidgetVisible(self.UIRoot.Image_Bubble_Invite, true)
    self:SetWidgetVisible(self.UIRoot.Image_Bubble_Apply, true)
    self:SetWidgetVisible(self.UIRoot.Image_57, true)
  else
    self:SetWidgetVisible(self.UIRoot.Image_Bubble_Invite, false)
    self:SetWidgetVisible(self.UIRoot.Image_Bubble_Apply, false)
    self.UIRoot.Image_13:SetColorAndOpacity(FLinearColor(1, 1, 1, 1))
    self.UIRoot.Image_74:SetColorAndOpacity(FLinearColor(1, 1, 1, 1))
    self:SetWidgetVisible(self.UIRoot.Image_57, false)
  end
end
function Personal_Info_UIBP:ShowRPFlag()
  local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
  local profile = logic_profile:GetLocalProfile(self.uid)
  if not profile then
    return
  end
  local UnknowPassUtil = require("client.slua.logic.unknow_pass.logic_unknowpass_util")
  local UPassIsBuy, UPassIsShow, UPassKeepBuy, UpassValue, pass_type = UnknowPassUtil.ParseUpassInfo(profile.upass)
  self.UIRoot.UnknowPass_ContinuousBuy_BP:SetTypeData(0, UPassKeepBuy, UPassIsBuy == 1, 1, UpassValue, pass_type or 0)
  self:SetWidgetVisible(self.UIRoot.UnknowPass_ContinuousBuy_BP, UPassIsShow ~= 0)
end
function Personal_Info_UIBP:SetPeakGameRank(profile)
  log(bWriteLog and "ChatMenu_BP:SetClassicRank")
  local segment
  local LogicPeakGameSegmentUtil = require("client.logic.PeakGame.LogicPeakGameSegmentUtil")
  if tonumber(profile.uid) == tonumber(DataMgr.roleData.uid) then
    segment = LogicPeakGameSegmentUtil.GetSelfAllZoneCurSeasonMaxSegmentId()
  else
    segment = LogicPeakGameSegmentUtil.GetProfileCurMaxSegmentId(profile)
  end
end
function Personal_Info_UIBP:ReportTLog(targetUid, interact)
  local tlog_report_utils = require("client.slua.config.tlog.tlog_report_utils")
  local isTeammate = false
  local isFriend = false
  targetUid = tonumber(targetUid)
  if targetUid and 0 < targetUid then
    local LogicFriend = require("client.slua.logic.friend.logic_new_friend")
    isFriend = LogicFriend.IsInnerFriend(targetUid)
    local TeamUpNewSystem = require("client.slua.logic.teamup.logic_team_up")
    if TeamUpNewSystem.GetMemberInfo(targetUid) then
      isTeammate = true
    else
      isTeammate = false
    end
  else
    log(bWriteLog and "Personal_Info_UIBP:ReportTLog error targetUid = " .. tostring(targetUid))
  end
  local str = string.format("MainCityInfoCardAction|{ targetUid = [%s], interact = [%s], isFriend = [%s], isTeammate = [%s] }", targetUid, interact, tostring(isFriend), tostring(isTeammate))
  tlog_report_utils.ReportTLogEvent(TLogEventDefine.MainCity_SocialCard_Interact, 0, str)
end
function Personal_Info_UIBP:GetCorpsSummaryRsp(eventType, eventID, corps_summary)
  local Icon = ChatMenuSystem.GetCorpsSummaryIcon(corps_summary)
  if Icon ~= "" then
    self:SetTexture(self.UIRoot.Image_icon_juntuan, Icon)
  end
  local UIUtil = require("client.common.ui_util")
  self.UIRoot.SizeBox_18:SetWidgetVisibility(UIUtil.BoolToVisible(Icon ~= ""))
  self.UIRoot.txt_juntuan:SetText(corps_summary.name)
  self.UIRoot.WidgetSwitcher_Juntuan:SetActiveWidgetIndex(0)
  local cfg = CDataTable.GetTableData("corps_alias_table", self.corp_alias_id or 0)
  self.UIRoot.WidgetSwitcher_5:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
  local pos = corps_summary.position or 0
  if pos == 0 then
    self.UIRoot.WidgetSwitcher_5:SetActiveWidgetIndex(3)
  elseif pos == 1 then
    self.UIRoot.WidgetSwitcher_5:SetActiveWidgetIndex(0)
  elseif pos == 2 then
    self.UIRoot.WidgetSwitcher_5:SetActiveWidgetIndex(1)
  elseif pos == 3 then
    self.UIRoot.WidgetSwitcher_5:SetActiveWidgetIndex(2)
  else
    self.UIRoot.WidgetSwitcher_5:SetActiveWidgetIndex(3)
  end
  if cfg and cfg.Default == 1 then
    self.UIRoot.WidgetSwitcher_21:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  else
    self.UIRoot.WidgetSwitcher_21:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
    if cfg then
      self.UIRoot["aliasName" .. cfg.background]:SetText(cfg.CorpAliasName)
      self.UIRoot.WidgetSwitcher_21:SetActiveWidgetIndex(cfg.background - 1)
    end
  end
  self:ChangeTextColorBySkin()
end
function Personal_Info_UIBP:OnInteract(eventType, eventID, uid)
  log(bWriteLog and "ChatMenu_BP:OnInteract")
  local logic_interaction = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_interaction)
  local interactInfo = logic_interaction:GetInteractInfo(uid)
  if not next(interactInfo) then
    return
  end
  self:SetWidgetVisible(self.UIRoot.HorizontalBox_29, false, false)
  self:SetWidgetVisible(self.UIRoot.Button_Fire, false, false)
  local isShowScintilla = false
  if interactInfo.status and interactInfo.status ~= logic_interaction.FireType.initial then
    local texturePath = logic_interaction:GetIconInfoByID(uid)
    if texturePath ~= nil and interactInfo.score and interactInfo.score > 0 then
      self:SetWidgetVisible(self.UIRoot.HorizontalBox_29, true, true)
      self:SetWidgetVisible(self.UIRoot.Button_Fire, true, true)
      self:SetTexture(self.UIRoot.Image_Scintilla, texturePath)
      self.UIRoot.TextBlock_4:SetText(interactInfo.score)
      isShowScintilla = true
    end
  end
  local logic_friend_interact_record = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_friend_interact_record)
  local interactData = logic_friend_interact_record:GetCumulativeInteractRecordDataHighFrequency(self.uid)
  local dayFriendDays = 0
  if interactData and interactData.add_friend_days then
    dayFriendDays = interactData.add_friend_days
  end
  local isShowDay = 0 < dayFriendDays
  local logic_friend_list = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_friend_list)
  local intimacy = logic_friend_list:GetIntimacy(self.uid) or 0
  local isShowIntimacy = 0 < intimacy
  if isShowScintilla or isShowIntimacy or isShowDay then
    self:SetWidgetVisible(self.UIRoot.HorizontalBox_Left, true, true)
    self:SetWidgetVisible(self.UIRoot.Spacer_Out, true, true)
    self.UIRoot.CanvasPanel_32:SetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    if not isShowScintilla and not isShowIntimacy then
      self:SetWidgetVisible(self.UIRoot.HorizontalBox_Left, false, false)
      self:SetWidgetVisible(self.UIRoot.Spacer_Out, false, false)
    end
  else
    self:SetWidgetVisible(self.UIRoot.HorizontalBox_Left, false, false)
    self:SetWidgetVisible(self.UIRoot.Spacer_Out, false, false)
    self.UIRoot.CanvasPanel_32:SetVisibility(UEnums.ESlateVisibility.Collapsed)
  end
  self:ChangeTextColorBySkin()
end
function Personal_Info_UIBP:SetFriendState(profile)
  self:SetWidgetVisible(self.UIRoot.Image_BG1, false, false)
  self:SetWidgetVisible(self.UIRoot.Image_LeftBG, false, false)
  self:SetWidgetVisible(self.UIRoot.Image_LeftBG, false, false)
  local TimeUtil = require("client.common.time_util")
  local frd_status_id = profile.frd_status_id
  local now_time = TimeUtil.GetServerTimeInSec()
  local frd_status_end_time = profile.frd_status_end_time
  if frd_status_end_time and now_time > frd_status_end_time then
    frd_status_id = 0
  end
  self.isCanShowMood = false
  self.UIRoot.Image_ScoreLevel:SetRenderScale(FVector2D(1, 1))
  if frd_status_id and 0 < frd_status_id and frd_status_id ~= 13 then
    local cfg = CDataTable.GetTableData("FriendStatusCfg", frd_status_id)
    local PlayerStatusEnum = require("client.slua.logic.player_status.PlayerStatusEnum")
    if cfg and cfg.type ~= PlayerStatusEnum.Enum_TeamState.Stealth then
      self:SetTexture(self.UIRoot.Image_ScoreLevel, cfg.icon_url)
      self.UIRoot.TextBlock_3:SetText(cfg.name)
      self.isCanShowMood = true
    end
  elseif frd_status_id and frd_status_id == 13 and profile.frd_custom_txt and profile.frd_custom_txt ~= "" and profile.frd_icon_idx and profile.frd_icon_idx ~= 0 then
    local path = "/Game/UMG/Texture/Atlas/ChatEmojiUI/Frames/emoji_1_50_" .. tostring(profile.frd_icon_idx) .. "_png.emoji_1_50_" .. tostring(profile.frd_icon_idx) .. "_png"
    self.UIRoot.Image_ScoreLevel:SetRenderScale(FVector2D(0.8, 0.8))
    self:SetTexture(self.UIRoot.Image_ScoreLevel, path)
    self.UIRoot.TextBlock_3:SetText(profile.frd_custom_txt)
    self.isCanShowMood = true
  end
  if self.isCanShowMood then
    self:SetWidgetVisible(self.UIRoot.CanvasPanel_34, true, false)
    self:SetWidgetVisible(self.UIRoot.Button_good, true, true)
  else
    self:SetWidgetVisible(self.UIRoot.CanvasPanel_34, false, false)
    self:SetWidgetVisible(self.UIRoot.Button_good, false, true)
  end
  if self.UIRoot.WidgetSwitcher_mood then
    self.UIRoot.WidgetSwitcher_mood:SetActiveWidgetIndex(self:CheckCanCare() and 0 or 1)
  end
  local isShowReturnTag = false
  local logic_oldfriend_care = require("client.slua.logic.oldfriend.logic_oldfriend_care")
  if logic_oldfriend_care.IsRejoinPlayer(profile) then
    local return_activity_macro = require("client.slua.logic.return_activity.return_activity_macro")
    local type = return_activity_macro.Enum_Tag_ShowType.Other
    if self.uid == tonumber(DataMgr.roleData.uid) then
      type = return_activity_macro.Enum_Tag_ShowType.Me
    end
    local params = {
      uid = self.uid,
      type = type,
      dir = 1,
      bOnDarkBg = true
    }
    if not self.returnTagItem then
      self.returnTagItem = self:CreateChildWindow(self.UIRoot.SizeBox_Return, UIManager.UI_Config.ReturnActivity_Player_Tag_Item, params)
      self:SetWidgetVisible(self.returnTagItem.UIRoot.Image_Mask, false)
    end
    isShowReturnTag = true
    self:SetWidgetVisible(self.UIRoot.SizeBox_Return, true, false)
    self:SetWidgetVisible(self.UIRoot.TextBlock_Return_Tips, true, false)
  else
    isShowReturnTag = false
    self:SetWidgetVisible(self.UIRoot.SizeBox_Return, false, false)
    self:SetWidgetVisible(self.UIRoot.TextBlock_Return_Tips, false, false)
  end
  self:SetWidgetVisible(self.UIRoot.CanvasPanel_Return_Tips, isShowReturnTag, false)
  self:SetWidgetVisible(self.UIRoot.Image_BG1, false, false)
  self:SetWidgetVisible(self.UIRoot.Image_LeftBG, isShowReturnTag, false)
  self:SetWidgetVisible(self.UIRoot.Image_RightBG, false, false)
end
function Personal_Info_UIBP:OnClickButton_mood()
  self:PlayAudio(sound_config.click_v1)
  if not self.isCanShowMood then
    return
  end
  self.isShowMood = not self.isShowMood
  if self.isShowMood then
    self:SetWidgetVisible(self.UIRoot.CanvasPanel_mood, true, false)
  else
    self:SetWidgetVisible(self.UIRoot.CanvasPanel_mood, false, false)
  end
end
function Personal_Info_UIBP:OnClickButton_good()
  self:PlayAudio(sound_config.click_v1)
  if self:CheckCanCare() then
    local FriendHandler = require("client.network.Protocol.FriendHandler")
    FriendHandler.send_do_friend_status_like_req(self.uid)
    if self.UIRoot.WidgetSwitcher_mood then
      self.UIRoot.WidgetSwitcher_mood:SetActiveWidgetIndex(1)
    end
  end
end
function Personal_Info_UIBP:OnClickButton_SocialHall()
  self:PlayAudio(sound_config.click_v1)
  local LogicFitVersionDownload = require("client.slua.logic.download.fit.logic_fitVersion_download")
  if not LogicFitVersionDownload.IsFitLobbyResDownloaded() then
    LogicFitVersionDownload.ShowFullLobbyResDownloadPopup()
    return
  end
  local SocialPersonSpaceSystem = require("client.slua.logic.lobby.Left.logic_social_person_space")
  SocialPersonSpaceSystem.EnterPersonSpace(self.uid)
  local str = "from:ButtonSocialHall;uid:" .. tostring(self.uid)
  local logic_return_tlog_report = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_return_tlog_report)
  logic_return_tlog_report:ReportReturnTLogEvent(TLogEventDefine.Click_Friend_To_SocialSpeace, 0, str)
  self:CloseSelf()
end
function Personal_Info_UIBP:EnterHome()
  local logic_home_entry = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_home_entry)
  logic_home_entry:EntryVisitHome(self.uid)
  local home_macros = require("client.slua.logic.home.home_macros")
  local BasicDataTLogReport = ModuleManager.GetModule(ModuleManager.DataModuleConfig.BasicDataTLogReport)
  BasicDataTLogReport:ReportImmediate(TLogEventDefine.Home_Enter_Other_Click_Entry, home_macros.ENUM_VISIT_SCENE_TYPE.RoleInfoCard)
end
function Personal_Info_UIBP:OnClickButton_Home()
  self:PlayAudio(sound_config.click_v1)
  local LogicFitVersionDownload = require("client.slua.logic.download.fit.logic_fitVersion_download")
  if not LogicFitVersionDownload.IsFitLobbyResDownloaded() then
    LogicFitVersionDownload.ShowFullLobbyResDownloadPopup()
    return
  end
  local logic_home_switch = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_home_switch)
  if logic_home_switch:CheckHomeLimit(true) then
    return
  end
  local SingleTrainTool = require("GameLua.Mod.SingleTraining.GamePlay.Data.SingleTrainTool")
  if SingleTrainTool.IsSelfInTraining() then
    ShowNotice(43911)
    return
  end
  local gotoFuc = function()
    if self and slua.isValid(self.UIRoot) then
      log(bWriteLog and "Personal_Info_UIBP:OnButton_HomeClick gotoFuc")
      self:EnterHome()
    else
      log(bWriteLog and "Personal_Info_UIBP:OnButton_HomeClick gotoFuc failed due to nil UIRoot")
    end
  end
  local logic_home_download = require("client.slua.logic.home.Download.logic_home_download")
  logic_home_download.CheckHomeDownloadedDone(self.uid, gotoFuc)
end
function Personal_Info_UIBP:OnClickButton_CardCollect()
  self:PlayAudio(sound_config.click_v1)
  local LogicCollectionHallEntry = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicCollectionHallEntry)
  local Enum_EnterPlanCHSource = LogicCollectionHallEntry.Enum_EnterPlanCHSource
  LogicCollectionHallEntry:EntryVisitCollectionHall(self.uid, Enum_EnterPlanCHSource.Lobby_FriendDetail, true)
end
function Personal_Info_UIBP:OnClickButtonFire()
  self:PlayAudio(sound_config.click_v1)
  local GameplayData = require("GameLua.GameCore.Data.GameplayData")
  local PlayerController = GameplayData.GetPlayerController()
  if slua.isValid(PlayerController) and PlayerController.bPlanBT then
    ShowNotice(4607717)
    return
  end
  UIManager.ShowUI(UIManager.UI_Config.Lobby_RoleInfo_IntimateRelationship_RecordMain_UIBP, self.uid, 2)
  self:CloseSelf()
end
function Personal_Info_UIBP:OnClickButton_FriendsGoTo()
  self:PlayAudio(sound_config.click_v1)
  local GameplayData = require("GameLua.GameCore.Data.GameplayData")
  local PlayerController = GameplayData.GetPlayerController()
  if slua.isValid(PlayerController) and PlayerController.bPlanBT then
    ShowNotice(4607717)
    return
  end
  UIManager.ShowUI(UIManager.UI_Config.Lobby_RoleInfo_IntimateRelationship_RecordMain_UIBP, self.uid, 1)
  self:CloseSelf()
end
function Personal_Info_UIBP:OnClickGoHome()
  self:PlayAudio(sound_config.click_v1)
  self:OnClickButton_Home()
end
function Personal_Info_UIBP:OnClickHomeLock()
  self:PlayAudio(sound_config.click_v1)
  ShowNotice(19810167)
end
function Personal_Info_UIBP:OnClickHome_Download()
  self:PlayAudio(sound_config.click_v1)
  local logic_home_download = require("client.slua.logic.home.Download.logic_home_download")
  logic_home_download.GetHomeMapPakSize(tonumber(DataMgr.roleData.uid), function(leftSize, downloadTypeInfo, use_items_arr)
    local DownloadData = {
      downloadSize = leftSize,
      use_items = use_items_arr,
      downloadHomeTypeInfo = downloadTypeInfo,
      GotoFunc = function()
        self:OnClickButton_Home()
      end
    }
    if GameStatus and GameStatus.IsInFightingNotMainCity() then
      log(bWriteLog and "logic_home_download._DoCheckHomeDownloadedDone in fighting(not main city), use bDownloadAllMode")
      DownloadData.bDownloadAllMode = true
      function DownloadData.GotoFunc()
        logic_home_download.StartDownloadAllHomeRes(DataMgr.roleData.uid)
      end
    end
    if 0 < leftSize then
      UIManager.ShowUI(UIManager.UI_Config.Home_Download_Entrance_Popup_UIBP, tonumber(DataMgr.roleData.uid), DownloadData)
    end
    self:SetHomeEntry()
  end)
end
function Personal_Info_UIBP:OnClickButton_CollectHall_Go()
  self:PlayAudio(sound_config.click_v1)
  self:OnClickButton_CardCollect()
end
function Personal_Info_UIBP:OnClickButton_Collect_DownLoad()
  self:PlayAudio(sound_config.click_v1)
  local LogicFitVersionDownload = require("client.slua.logic.download.fit.logic_fitVersion_download")
  if not LogicFitVersionDownload.IsFitLobbyResDownloaded() then
    LogicFitVersionDownload.ShowFullLobbyResDownloadPopup()
    return
  end
  local logic_mode_mgr = require("client.slua.logic.match.logic_mode_mgr")
  if logic_mode_mgr.IsSocialIslandMode() then
    ShowNotice(792512)
    return
  end
  local Logic_SC_DownloadTools = require("client.slua.logic.lobby.Left.SocialLobby.Logic_SC_DownloadTools")
  Logic_SC_DownloadTools.ShowPlanCHDownloadPopup(tonumber(DataMgr.roleData.uid), function()
    self:OnClickButton_CardCollect()
  end)
end
function Personal_Info_UIBP:OnClickButton_GiveBP()
  self:PlayAudio(sound_config.click_v1)
  local MailMacro = require("client.slua.logic.mail.mail_macro")
  local msg = {
    op = MailMacro.Enum_FriendPresentFromType.ChatMenu
  }
  local FriendGiftHandler = require("client.network.Protocol.FriendGiftHandler")
  FriendGiftHandler.send_present_friend_gold_req(tonumber(self.uid), msg)
  self:CloseSelf()
end
function Personal_Info_UIBP:on_hover_club_profile_click()
  log(bWriteLog and " ChatMenu_BP:on_hover_club_profile_click ")
  self:PlayAudio(sound_config.click_v1)
  local logic_friend_blacklist = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_friend_blacklist)
  if logic_friend_blacklist:IsBlacklist(self.uid) then
    ShowNotice(700012)
    return
  end
  if logic_friend_blacklist:IsByBlacklist(self.uid) then
    ShowNotice(77902)
    return
  end
  local MatchModeMgrSystem = require("client.slua.logic.match.logic_mode_mgr")
  if MatchModeMgrSystem.IsSocialIslandMode() then
    ShowNotice(27607)
    return
  end
  if UIManager.IsUIShow(UIManager.UI_Config.ui_chat_main) then
    UIManager.CloseUI(UIManager.UI_Config.ui_chat_main)
  end
  self:CloseSelf()
  if UIManager.IsUIShow(UIManager.UI_Config.Lobby_Lucky_Teammate_UIBP) then
    UIManager.CloseUI(UIManager.UI_Config.Lobby_Lucky_Teammate_UIBP)
  end
  local logic_community = require("client.slua.logic.community.logic_community")
  logic_community.GotoClubUserProfile(self.uid, logic_community.GameScene.FromPersonalPopup)
end
function Personal_Info_UIBP:IsPlayerInvisible()
  local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
  local profile = logic_profile:GetLocalProfile(self.uid)
  if not (profile and profile.frd_status_id) or profile.frd_status_id <= 0 then
    log(bWriteLog and "Personal_Info_UIBP:IsPlayerInVisible profile or status empty")
  else
    local cfg = CDataTable.GetTableData("FriendStatusCfg", profile.frd_status_id)
    if cfg and cfg.type == 7 then
      log(bWriteLog and "Personal_Info_UIBP:IsPlayerInVisible friend is hiding")
      return true
    end
  end
  return false
end
function Personal_Info_UIBP:on_hover_moment_click()
  self:PlayAudio(sound_config.click)
  local LogicFitVersionDownload = require("client.slua.logic.download.fit.logic_fitVersion_download")
  if not LogicFitVersionDownload.IsFitLobbyResDownloaded() then
    LogicFitVersionDownload.ShowFullLobbyResDownloadPopup()
    return
  end
  local MatchModeMgrSystem = require("client.slua.logic.match.logic_mode_mgr")
  local myselfOnIsland = MatchModeMgrSystem.IsSocialIslandMode()
  if myselfOnIsland then
    return
  end
  if UIManager.IsUIShow(UIManager.UI_Config.Lobby_Lucky_Teammate_UIBP) then
    UIManager.CloseUI(UIManager.UI_Config.Lobby_Lucky_Teammate_UIBP)
  end
  if UIManager.IsUIShow(UIManager.UI_Config.friend_applylist) then
    UIManager.CloseUI(UIManager.UI_Config.friend_applylist)
  end
  local logic_moment = require("client.slua.logic.moment.logic_moment")
  logic_moment.EnterMomentUI(self.uid)
  if UIManager.IsUIShow(UIManager.UI_Config.UGCDetailMainPanel) then
    UIManager.CloseUI(UIManager.UI_Config.UGCDetailMainPanel)
  end
  if UIManager.IsUIShow(UIManager.UI_Config.Home_MsgBoard_Visitor_GuestBook_UIBP) then
    UIManager.CloseUI(UIManager.UI_Config.Home_MsgBoard_Visitor_GuestBook_UIBP)
  end
  if UIManager.IsUIShow(UIManager.UI_Config.ChatRoom_Audience_UIBP) then
    UIManager.CloseUI(UIManager.UI_Config.ChatRoom_Audience_UIBP)
  end
  self:CloseSelf()
end
function Personal_Info_UIBP:OnClickRemark()
  self:PlayAudio(sound_config.click_v1)
  UIManager.ShowUI(UIManager.UI_Config.friend_remark, self.uid)
end
function Personal_Info_UIBP:OnButton_SouvenirsClick()
  self:PlayAudio(sound_config.click_v1)
  local souvenirs_util = require("client.slua.logic.TxMission.souvenirs.souvenirs_util")
  souvenirs_util.ShowOtherSouvenirs(self.uid)
end
function Personal_Info_UIBP:OnClickedPinbi()
  self:PlayAudio(sound_config.click_v1)
  if not self.uid then
    return
  end
  local logic_home_entry = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_home_entry)
  if logic_home_entry:IsPlanPHMode() then
    self:ShowHomeBlackListPop()
  else
    self:ShowCommonBlackListPop()
  end
end
function Personal_Info_UIBP:ShowHomeBlackListPop()
  local PersonSpaceSystem = require("client.logic.personspace.logic_person_space")
  local LogicFriend = require("client.slua.logic.friend.logic_new_friend")
  local logic_friend_blacklist = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_friend_blacklist)
  if logic_friend_blacklist:IsBlacklist(self.uid) then
    ShowNotice(106065)
  else
    local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
    local data = logic_profile:GetLocalProfile(self.uid)
    if data then
      do
        local config = {
          title = LocUtil.GetLocalizeResStr(34696),
          clickOkCallback = function()
            local bSuccess = logic_friend_blacklist:proc_add_black_list_req(data.uid, logic_friend_blacklist.Enum_Add_Black_Scene.Chat_Menu_BP)
            if bSuccess then
              if data.type == EnumApplyType.Partner then
                PersonSpaceSystem.refuse_make_intimacy_partner_req(data.uid)
              elseif data.type == EnumApplyType.Relation then
                LogicFriend.reply_intimacy_relation_req(data.uid, data.param, 0)
              else
                local logic_friend_apply = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_friend_apply)
                logic_friend_apply:add_inner_friend_op_req(data.uid, 0)
              end
            end
            self:CloseSelf()
          end,
          notice = LocUtil.LocalizeResFormat(34697, data.nickName),
          type = 4
        }
        UIManager.ShowUI(UIManager.UI_Config_InGame.PlanPH_Common_Popups_MediumSmall_UIBP, config)
      end
    end
  end
end
function Personal_Info_UIBP:ShowCommonBlackListPop()
  local PersonSpaceSystem = require("client.logic.personspace.logic_person_space")
  local LogicFriend = require("client.slua.logic.friend.logic_new_friend")
  local logic_friend_blacklist = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_friend_blacklist)
  if logic_friend_blacklist:IsBlacklist(self.uid) then
    ShowNotice(106065)
  else
    local title = LocUtil.GetLocalizeResStr(34696)
    local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
    local data = logic_profile:GetLocalProfile(self.uid)
    if data then
      do
        local msg = LocUtil.LocalizeResFormat(34697, data.nickName)
        local logic_match_blacklist = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_match_blacklist)
        logic_match_blacklist:send_get_match_black_list_req()
        local callback = function(isCheck, isDifferentTeams)
          log(bWriteLog and "[v_yunjxing] ChatMenu_BP:ShowCommonBlackListPop " .. tostring(isDifferentTeams))
          local bSuccess = logic_friend_blacklist:proc_add_black_list_req(data.uid, logic_friend_blacklist.Enum_Add_Black_Scene.Chat_Menu_BP)
          if bSuccess then
            if data.type == EnumApplyType.Partner then
              PersonSpaceSystem.refuse_make_intimacy_partner_req(data.uid)
            elseif data.type == EnumApplyType.Relation then
              LogicFriend.reply_intimacy_relation_req(data.uid, data.param, 0)
            else
              local logic_friend_apply = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_friend_apply)
              if logic_friend_apply:GetApplyData(data.uid) then
                logic_friend_apply:add_inner_friend_op_req(data.uid, 0)
              else
                log(bWriteLog and "ChatMenu_BP:ShowCommonBlackListPop logic_friend_apply:GetApplyData(data.uid) is nil")
              end
            end
          end
          local logic_friend_blacklist = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_friend_blacklist)
          local nowMatchBlackCount = logic_match_blacklist:GetMatchBlackMapSize()
          if isCheck and not logic_friend_blacklist:IsLimit() and nowMatchBlackCount < logic_match_blacklist.toplimit then
            logic_match_blacklist:send_add_match_black_list_req(self.uid)
          else
            log(bWriteLog and "[v_yunjxing] ChatMenu_BP:ShowCommonBlackListPop isCheck false or nowMatchBlackCount =" .. tostring(nowMatchBlackCount))
          end
          self:CloseSelf()
        end
        local extraData = {
          isDifferentTeams = true,
          showUIKey = "Com_Match_Black_UIBP"
        }
        local CommonMsgBoxMgr = require("client.slua.logic.common.logic_common_msg_box")
        CommonMsgBoxMgr.Show(2, title, msg, callback, nil, nil, nil, extraData)
      end
    end
  end
end
function Personal_Info_UIBP:OnButton_InteractRecordClick()
  self:PlayAudio(sound_config.click_v1)
  UIManager.ShowUI(UIManager.UI_Config.Lobby_RoleInfo_IntimateRelationship_RecordMain_UIBP, tonumber(self.uid), 1)
  self:CloseSelf()
end
function Personal_Info_UIBP:SetHomeEntry()
  local QRcodeRestrictManager = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.QRcodeRestrictManager)
  local bShowHomePanel = not QRcodeRestrictManager:IsRestirctManor() and self.eShowLocationType ~= ChatMenuSystem.EShowLocationType.UGCPlayHallRoom
  self:SetWidgetVisible(self.UIRoot.Button_Home, false, true)
  self:SetWidgetVisible(self.UIRoot.SizeBox_32, false, false)
  local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
  local name = logic_profile:GetLocalProfile(self.uid).nickName
  name = LocUtil.LocalizeResFormat(64759, name)
  self.UIRoot.TextBlock_HoneName:SetText(name)
  self.UIRoot.TextBlock_HoneName_Down:SetText(name)
  local logic_home_switch = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_home_switch)
  if not logic_home_switch:CheckHomeSwitchOpen(false) then
    return
  end
  local logic_home_profile = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_home_profile)
  local uid = tonumber(self.uid)
  logic_home_profile:GetOrReqHomeProfile({uid}, function()
    if not self.UIRoot then
      return
    end
    local profile = logic_home_profile:GetHomeProfileByUid(uid)
    log(bWriteLog and "logic_home_profile:GetHomeProfileByUid(uid):%s", profile)
    if profile then
      if not profile.bUnLock then
        self.UIRoot.WidgetSwitcher_Home:SetActiveWidgetIndex(2)
      else
        local logic_home_download = require("client.slua.logic.home.Download.logic_home_download")
        logic_home_download.GetHomeMapPakSize(tonumber(DataMgr.roleData.uid), function(leftSize, downloadTypeInfo, use_items_arr)
          log(bWriteLog and "logic_home_download.CheckHomeDownloadedDone, leftSize:%s", leftSize)
          if 0 < leftSize then
            self.UIRoot.WidgetSwitcher_Home:SetActiveWidgetIndex(1)
            self.UIRoot.ProgressBar_Home:SetPercent(0)
          else
            self.UIRoot.WidgetSwitcher_Home:SetActiveWidgetIndex(0)
          end
        end)
      end
      if profile.grow_info and profile.grow_info.level then
        local level = profile.grow_info.level
        self:SetWidgetVisible(self.UIRoot.TextBlock_HomeLv, true, false)
        self.UIRoot.TextBlock_HomeLv:SetText(level)
      else
        self:SetWidgetVisible(self.UIRoot.TextBlock_HomeLv, false, false)
      end
      if profile.name and profile.name ~= "" then
        self.UIRoot.TextBlock_HoneName_Down:SetText(profile.name)
        self.UIRoot.TextBlock_HoneName:SetText(profile.name)
      else
        name = LocUtil.LocalizeResFormat(64759, name)
        self.UIRoot.TextBlock_HoneName:SetText(name)
        self.UIRoot.TextBlock_HoneName_Down:SetText(name)
      end
      local home_item_utils = require("client.slua.logic.home.home_item_utils")
      home_item_utils.SetHomeHouseIcon(self.UIRoot.Image_HomeIcon, uid)
      local logic_home_entry = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_home_entry)
      local manorID = logic_home_entry:GetManorOwnerId()
      if manorID and manorID == uid and not GameStatus.IsInLobbyOrMainCity() then
        self:SetWidgetVisible(self.UIRoot.Button_Home, false, false)
        self:SetWidgetVisible(self.UIRoot.SizeBox_32, false, false)
        return
      end
    end
    if slua.isValid(self.UIRoot) then
      self:ApplyPlanBTHideWidgets()
    end
  end, true)
  self:ApplyPlanBTHideWidgets()
end
function Personal_Info_UIBP:SetCollectHallEntry()
  local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
  local profile = logic_profile:GetLocalProfile(self.uid)
  local collect_data = profile.collect_data
  if collect_data then
    local Logic_SC_DownloadTools = require("client.slua.logic.lobby.Left.SocialLobby.Logic_SC_DownloadTools")
    if not Logic_SC_DownloadTools.CheckPlanCHIsDownloaded(tonumber(DataMgr.roleData.uid)) then
      self.UIRoot.WidgetSwitcher_CollectionHall:SetActiveWidgetIndex(1)
      self.UIRoot.ProgressBar_CollectionHall:SetPercent(0)
    else
      self.UIRoot.WidgetSwitcher_CollectionHall:SetActiveWidgetIndex(0)
    end
    local Logic_SocialLobbyModule = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.Logic_SocialLobbyModule)
    local nLevel = Logic_SocialLobbyModule:_GetCollectHallLevelByUId(self.uid)
    self.UIRoot.TextBlock_CollectionHall_Lv:SetText("LV." .. nLevel)
    self.UIRoot.TextBlock_CollectionHall_Name:SetText(LocUtil.LocalizeResFormat(880060018, profile.nickName or ""))
    self.UIRoot.TextBlock_CollectionHall_Name_Down:SetText(LocUtil.LocalizeResFormat(880060018, profile.nickName or ""))
  else
    self.UIRoot.WidgetSwitcher_CollectionHall:SetActiveWidgetIndex(2)
  end
  self:ApplyPlanBTHideWidgets()
end
function Personal_Info_UIBP:ApplyPlanBTHideWidgets()
  if not self.IsPlanBTParam then
    return
  end
  if not self.UIRoot or not slua.isValid(self.UIRoot) then
    return
  end
  local Collapsed = UEnums.ESlateVisibility.Collapsed
  local popupWidgets = {
    "Button_InteractRecord",
    "Image_64",
    "Button_Remark",
    "Image_66",
    "Button_Club",
    "Image_68",
    "Button_Moment",
    "Image_Line"
  }
  for _, name in ipairs(popupWidgets) do
    local w = self.UIRoot[name]
    if w then
      w:SetWidgetVisibility(Collapsed)
    end
  end
  if self.UIRoot.Button_Poke then
    self.UIRoot.Button_Poke:SetWidgetVisibility(Collapsed)
  end
  if self.UIRoot.SizeBox_9 then
    self.UIRoot.SizeBox_9:SetWidgetVisibility(Collapsed)
  end
  local bottomEntryWidgets = {
    "Button_Home22",
    "WidgetSwitcher_Home",
    "Button_CollectHall_Go",
    "WidgetSwitcher_CollectionHall"
  }
  for _, name in ipairs(bottomEntryWidgets) do
    local w = self.UIRoot[name]
    if w then
      w:SetWidgetVisibility(Collapsed)
    end
  end
end
function Personal_Info_UIBP:OnClickButton_TV()
  self:PlayAudio(sound_config.click_v1)
end
function Personal_Info_UIBP:UpdateCardSkin()
  self.UIRoot.WidgetSwitcher_Effect:SetActiveWidgetIndex(0)
  local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
  local profile_info = logic_profile:GetLocalProfile(self.uid)
  if not profile_info then
    return
  end
  local logic_social_card = require("client.slua.logic.lobby.Left.logic_social_card")
  local PufferManager = require("client.slua.logic.download.puffer.puffer_manager")
  local carte_frame_equip_id = logic_social_card.GetCarteFrameEquipIdByProfile(profile_info)
  if carte_frame_equip_id then
    local logic_roleinfo_carte_frame = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_roleinfo_carte_frame)
    local effect_bp_path, skin_path, _, bLoopAnim = logic_roleinfo_carte_frame:GetSkinPath(carte_frame_equip_id, true)
    local pak_util = require("client.common.pak_util")
    log_format(bWriteLog and "Personal_Info_UIBP:UpdateCardSkin effect_bp_path=%s", effect_bp_path)
    local downloadArr = {}
    self.needDownloadPakNames = {}
    local PublishRegionMacros = require("client.slua.config.ClientMacros.PublishRegionMacros")
    local isFitVersion = PublishRegionMacros.IsFITVersion()
    if isFitVersion then
      local downloadParentPanel = self.UIRoot.CanvasPanel_Download or self.UIRoot.CanvasPanel_Effect_002
      self:LoadCarteBGEffect(effect_bp_path, bLoopAnim, carte_frame_equip_id, downloadParentPanel, downloadArr)
    else
      local itemDisplayFallbackLogic = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.item_display_fallback_logic)
      if itemDisplayFallbackLogic:IsSmallPackageResourceMissing(carte_frame_equip_id) then
        local relatedPaks = PufferManager.GetPakNamesByItemID(carte_frame_equip_id) or {}
        for pakName, _ in pairs(relatedPaks) do
          if pakName and pakName ~= "" and not self.needDownloadPakNames[pakName] then
            self.needDownloadPakNames[pakName] = true
            table.insert(downloadArr, pakName)
          end
        end
        log_format(bWriteLog and "Personal_Info_UIBP:UpdateCardSkin small package missing, frame_id=%s pakCount=%s", tostring(carte_frame_equip_id), tostring(#downloadArr))
      end
      if effect_bp_path and effect_bp_path ~= "" and pak_util.IsFileExist(effect_bp_path) then
        self.isShowSkin = true
        self:ChangeTextColorBySkin()
        self:ClearCarteSkin()
        self.UIRoot.WidgetSwitcher_Effect:SetActiveWidgetIndex(1)
        local uiConfig = UIManager.UI_Config.Lobby_RoleInfo_EffectSkin_Item_UIBP
        local aniName
        if bLoopAnim then
          aniName = "Auto_Loop"
        end
        local extraData = {}
        local item_data = logic_roleinfo_carte_frame:GetCrateFrameBGCfg(carte_frame_equip_id)
        if item_data and item_data.Level == 3 then
          extraData.bEnableGyroscope = true
        end
        self.card_skin_bp = self:CreateChildWindowWithBpPath("CanvasPanel_Effect_002", uiConfig, effect_bp_path, aniName, extraData)
      else
        self.isShowSkin = false
        local bpPakName = PufferManager.GetPakName(effect_bp_path)
        log_format("Personal_Info_UIBP:UpdateCardSkin. bpPakName=%s", bpPakName)
        if bpPakName ~= "" then
          self.needDownloadPakNames[bpPakName] = true
          table.insert(downloadArr, bpPakName)
        end
        log_format(bWriteLog and "Personal_Info_UIBP:UpdateCardSkin effect_bp_path file not exist", effect_bp_path)
        self.UIRoot.WidgetSwitcher_Effect:SetActiveWidgetIndex(0)
      end
    end
    log_format(bWriteLog and "Personal_Info_UIBP:UpdateCardSkin skin_path=%s", skin_path)
    if skin_path and skin_path ~= "" then
      local ret = self:SetTexture(self.UIRoot.Image_21, skin_path)
      local SetTextureConst = require("client.slua.logic.image_download.SetTextureConst")
      log_format(bWriteLog and "Personal_Info_UIBP:UpdateCardSkin SetTexture ret=%s", tostring(ret))
      if ret ~= SetTextureConst.Done then
        self.UIRoot.WidgetSwitcher_1:SetActiveWidgetIndex(0)
        local pakName = PufferManager.GetPakName(skin_path)
        log_format("Personal_Info_UIBP:UpdateCardSkin. pakName=%s", pakName)
        self.needDownloadPakNames[pakName] = true
        table.insert(downloadArr, pakName)
      else
        self.UIRoot.WidgetSwitcher_1:SetActiveWidgetIndex(1)
      end
    else
      self.UIRoot.WidgetSwitcher_1:SetActiveWidgetIndex(0)
    end
    if next(downloadArr) then
      local PufferConst = require("client.slua.logic.download.puffer_const")
      PufferManager.Download(PufferConst.ENUM_DownloadType.ODPAK, downloadArr, PufferTlog.Enum_TLog_From.Social, nil, PufferManager.DefaultForceDownloadParam)
    end
    self:UpdateSkinDownloadPollTimer()
  end
end
function Personal_Info_UIBP:UpdateProfileFrame()
  local logic_profileframe = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_roleInfo_profileframe)
  if not logic_profileframe:IsFeatureOpen() then
    self:SetWidgetVisible(self.UIRoot.FrameRoot, false)
    return
  end
  local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
  local profile_info = logic_profile:GetLocalProfile(self.uid)
  if not profile_info then
    return
  end
  local DefaultFrame = 62310001
  local frame_id = profile_info.profile_frame
  if not frame_id or frame_id == DefaultFrame then
    self:SetWidgetVisible(self.UIRoot.FrameRoot, false)
    return
  end
  local _, _, infoCardFrameUMG, bLoopAnim = logic_profileframe:GetSkinPath(frame_id)
  if infoCardFrameUMG and infoCardFrameUMG ~= "" then
    local pak_util = require("client.common.pak_util")
    if pak_util.IsFileExist(infoCardFrameUMG) then
      local uiConfig = UIManager.UI_Config.Lobby_RoleInfo_EffectSkin_Item_UIBP
      local anim = bLoopAnim and "Auto_Loop"
      local extraData = {}
      self.profile_frame_bp = self:CreateChildWindowWithBpPath("FrameRoot", uiConfig, infoCardFrameUMG, anim, extraData)
      self:SetWidgetVisible(self.UIRoot.FrameRoot, self.profile_frame_bp ~= nil)
    else
      self:SetWidgetVisible(self.UIRoot.FrameRoot, false)
    end
  else
    self:SetWidgetVisible(self.UIRoot.FrameRoot, false)
  end
  if self.profile_frame_bp and self.profile_frame_bp.UIRoot.Anim_In then
    if self.FrameAnimPlayed then
      return
    end
    self.FrameAnimPlayed = true
    self:PlayWidgetAnimation(self.profile_frame_bp.UIRoot, self.profile_frame_bp.UIRoot.Anim_In, 0, 1, 0, 1)
  end
end
function Personal_Info_UIBP:UpdataRelationship()
  local LogicFriend = require("client.slua.logic.friend.logic_new_friend")
  local relation = LogicFriend.GetRelation(self.uid)
  if relation ~= 0 then
    local IntimacyAwardSystem = require("client.slua.logic.person_space.logic_intimacy_award")
    self:SetTexture(self.UIRoot.Image_Love, IntimacyAwardSystem.GetInitimacyIcon_other(relation))
  else
    self:SetTexture(self.UIRoot.Image_Love, "/Game/UMG/Texture_200/Atlas/Common_New_Atlas/Frames/Common_Icon_Relationship_png.Common_Icon_Relationship_png")
  end
end
function Personal_Info_UIBP:ClearCarteSkin()
  if self.card_skin_bp then
    self.card_skin_bp:Close()
    self.card_skin_bp = nil
  end
end
function Personal_Info_UIBP:UpdateSkinDownloadPollTimer()
  if self.needDownloadPakNames and next(self.needDownloadPakNames) then
    if not self._skinDownloadPollTimer then
      log(bWriteLog and "Personal_Info_UIBP:UpdateSkinDownloadPollTimer start")
      self._skinDownloadPollTimer = self:AddTimerLoop(1, function()
        if not slua.isValid(self.UIRoot) then
          self:StopSkinDownloadPollTimer()
          return
        end
        self:UpdateCardSkin()
      end, TIMER_INFINITE, 1)
    end
  else
    self:StopSkinDownloadPollTimer()
  end
end
function Personal_Info_UIBP:StopSkinDownloadPollTimer()
  if self._skinDownloadPollTimer then
    log(bWriteLog and "Personal_Info_UIBP:StopSkinDownloadPollTimer stop")
    self:RemoveTimer(self._skinDownloadPollTimer)
    self._skinDownloadPollTimer = nil
  end
end
function Personal_Info_UIBP:HaveNameColor(profile)
  local NicknameColorManager = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.NicknameColorManager)
  local planID = NicknameColorManager:GetUserData(profile.uid)
  self.isDefultNameColor = planID == NicknameColorManager.DEFAULT_PLAN_ID
end
function Personal_Info_UIBP:ApplyTextSkinStyle(textWidget, color)
  if not textWidget then
    return
  end
  if textWidget.SetColorAndOpacity then
    textWidget:SetColorAndOpacity(color)
  end
  if textWidget.Font then
    local font = textWidget.Font
    if self.isShowSkin then
      font.OutlineSettings.OutlineSize = 1
      font.OutlineSettings.OutlineColor = FLinearColor(0, 0, 0, 1)
    else
      font.OutlineSettings.OutlineSize = 0
      font.OutlineSettings.OutlineColor = FLinearColor(0, 0, 0, 1)
    end
    textWidget:setFont(font)
  end
end
function Personal_Info_UIBP:ChangeTextColorBySkin()
  local color, remarkStyle
  if self.isShowSkin then
    color = FSlateColor(FLinearColor(1, 1, 1, 1))
    remarkStyle = "<Back_Award_Description>(%s)</>"
  else
    color = FSlateColor(FLinearColor(0, 0, 0, 1))
    remarkStyle = "<NoteNameForInfo>(%s)</>"
  end
  local commonTexts = {
    self.UIRoot.TextBlock_4,
    self.UIRoot.Text_Intimacy,
    self.UIRoot.UTRichTextBlock_0,
    self.UIRoot.txt_juntuan,
    self.UIRoot.Text_Commander,
    self.UIRoot.Text_DeputyCommander,
    self.UIRoot.Text_Elite,
    self.UIRoot.Text_Member,
    self.UIRoot.TextBlock_Label1,
    self.UIRoot.TextBlock_Label2
  }
  for _, w in ipairs(commonTexts) do
    self:ApplyTextSkinStyle(w, color)
  end
  local goToColor, numberColor, dayColor
  if self.isShowSkin then
    goToColor = FSlateColor(FLinearColor(1, 1, 1, 0.8))
    numberColor = FSlateColor(FLinearColor(1, 1, 1, 1))
    dayColor = FSlateColor(FLinearColor(1, 1, 1, 0.8))
  else
    goToColor = FSlateColor(FLinearColor(0, 0, 0, 0.4))
    numberColor = FSlateColor(FLinearColor(0, 0, 0, 0.7))
    dayColor = FSlateColor(FLinearColor(0, 0, 0, 0.4))
  end
  self:ApplyTextSkinStyle(self.UIRoot.Text_FriendsGoTo, goToColor)
  self:ApplyTextSkinStyle(self.UIRoot.TextBlock_Number, numberColor)
  self:ApplyTextSkinStyle(self.UIRoot.TextBlock_Day, dayColor)
  if self.isDefultNameColor then
    self.UIRoot.TextBlock_Name:SetColorAndOpacity(color)
  end
  self:ApplyNicknameOutline(self.UIRoot.TextBlock_Name, not self.isDefultNameColor or self.isShowSkin)
  local imageList = {"Calendar", "Image_290"}
  for _, widgetName in ipairs(imageList) do
    self.UIRoot[widgetName]:SetColorAndOpacity(self.isShowSkin and FLinearColor(1, 1, 1, 0.7) or FLinearColor(0, 0, 0, 0.7))
  end
  self.UIRoot.Common_RankIntegralLevel_Style_Small_UIBP:ChangeRankInteralColor(color)
  local LogicFriend = require("client.slua.logic.friend.logic_new_friend")
  local name = LogicFriend.GetNamePure(self.uid)
  local remark = LogicFriend.GetRemarkNamePure(self.uid)
  if remark ~= "" then
    local nameText = name .. string.format(remarkStyle, remark)
    self.UIRoot.TextBlock_Name:SetText(nameText)
  end
  self:SetWidgetVisible(self.UIRoot.Image_BGMask, self.isShowSkin, false)
end
function Personal_Info_UIBP.ClipString(str)
  if not str then
    return ""
  end
  local StringUtil = require("common.string_util")
  local maxLength = 14
  local len = StringUtil.GetCharactersLength(str, 2)
  if maxLength < len then
    return LocUtil.LocalizeResFormat(8600314, StringUtil.ClipString(str, maxLength, 2))
  else
    return str
  end
end
function Personal_Info_UIBP:CloseChatMain()
  if UIManager.IsUIShow(UIManager.UI_Config.ui_chat_main) then
    UIManager.CloseUI(UIManager.UI_Config.ui_chat_main)
  end
end
function Personal_Info_UIBP:GetPlayerCustomSwitches(profile)
  local logic_friendlist_custom_utils = require("client.slua.logic.friend.logic_friendlist_custom_utils")
  if not profile then
    return {
      collectLevel = true,
      alias = true,
      pass = true,
      wowPass = true,
      gender = true,
      nationFlag = true,
      certification = true
    }
  end
  local switchValue = profile.friend_list_bits_switch
  if switchValue == nil then
    switchValue = logic_friendlist_custom_utils.CalculateDefaultSwitch(profile)
  end
  local SWITCH_MASK = logic_friendlist_custom_utils.SWITCH_MASK
  local switches = {
    collectLevel = logic_friendlist_custom_utils.GetSwitch(switchValue, SWITCH_MASK.CollectLevel),
    alias = logic_friendlist_custom_utils.GetSwitch(switchValue, SWITCH_MASK.Alias),
    pass = logic_friendlist_custom_utils.GetSwitch(switchValue, SWITCH_MASK.Pass),
    wowPass = logic_friendlist_custom_utils.GetSwitch(switchValue, SWITCH_MASK.WowPass),
    gender = logic_friendlist_custom_utils.GetSwitch(switchValue, SWITCH_MASK.Gender),
    nationFlag = logic_friendlist_custom_utils.GetSwitch(switchValue, SWITCH_MASK.NationFlag),
    certification = logic_friendlist_custom_utils.GetSwitch(switchValue, SWITCH_MASK.Certification)
  }
  return switches
end
function Personal_Info_UIBP:OnClickButton_Island()
  if not self._isLandState then
    return
  end
  local QRcodeRestrictManager = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.QRcodeRestrictManager)
  if QRcodeRestrictManager:IsRestrictBatlleAll() then
    QRcodeRestrictManager:ShowRestrictTips()
    return
  end
  if self._isLandState == 1 then
    local logic_chat_channel_social_island_chat = require("client.slua.logic.lobby_chat.logic_chat_channel_social_island_chat")
    local num = #logic_chat_channel_social_island_chat.islandMember
    local SocialIslandHandler = require("client.network.Protocol.SocialIslandHandler")
    local max = SocialIslandHandler.GetMaxPlayer()
    if num >= max then
      local clickOkCallback = function()
        SocialIslandHandler.ReqEnterSystemIsland()
      end
      local title = LocUtil.GetLocalizeResStr(5077)
      local content = LocUtil.GetLocalizeResStr(9864)
      local CommonMsgBoxMgr = require("client.slua.logic.common.logic_common_msg_box")
      CommonMsgBoxMgr.Show(2, title, content, clickOkCallback)
    else
      SocialIslandHandler.send_socialland_invite_req(self.uid)
    end
  elseif self._isLandState == 2 then
    local LogicUGCMatch = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicUGCMatch)
    if LogicUGCMatch:HasUGCMatchInfo() then
      printf("FriendsListItem_BP:OnClickButton_Island return, LogicUGCMatch:HasUGCMatchInfo()")
      ShowNotice(48409)
      return
    end
    local SocialIslandHandler = require("client.network.Protocol.SocialIslandHandler")
    SocialIslandHandler.send_socialland_apply_req(self.uid, 1)
  elseif self._isLandState == 3 then
    local PlayerStatusMgr = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.PlayerStatusMgr)
    local status = PlayerStatusMgr:GetStatusData(self.uid)
    if not status then
      printf("FriendsListItem_BP:OnClickButton_Island return, status is nil")
      return
    end
    local islandStr = LocUtil.GetLocalizeResStr(9558)
    if status.socialland_type == 2 then
      islandStr = LocUtil.GetLocalizeResStr(9559)
    end
    local CommonMsgBoxMgr = require("client.slua.logic.common.logic_common_msg_box")
    local SocialIslandHandler = require("client.network.Protocol.SocialIslandHandler")
    CommonMsgBoxMgr.Show(4, "", LocUtil.LocalizeResFormat(9552, islandStr, islandStr), function()
      SocialIslandHandler.send_socialland_invite_req(self.uid)
    end, function(_)
      SocialIslandHandler.send_socialland_apply_req(self.uid, 1)
    end, LocUtil.GetLocalizeResStr(9566), LocUtil.GetLocalizeResStr(9565))
  elseif self._isLandState == 4 then
    local SocialIslandTools = require("GameLua.Mod.SocialIsland.GamePlay.SocialIslandTools")
    if not SocialIslandTools.IsPlayerIdleClient() then
      ShowNotice(34298)
      return
    end
    local IslandMacro = require("GameLua.Mod.SocialIsland.Client.IslandMacro")
    NetUtil.MoveFollowTarget(IslandMacro.ENUM_FollowType.FollowPlayer, tonumber(self.uid))
  end
end
function Personal_Info_UIBP:GetIslandActionData(status)
  local logic_friend_list_ui = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_friend_list_ui)
  local from = logic_friend_list_ui:GetFrom()
  local data = {bIsShow = false}
  if from == FLMacros.ENUM_OPEN_FROM.TPLAN or status.tplan_type == 1 then
    return data
  end
  local ShootingTrainTool = require("GameLua.Mod.SingleTraining.GamePlay.Data.SingleTrainTool")
  if ShootingTrainTool.IsSelfInTraining() or ShootingTrainTool.IsOtherInTraining(status) then
    return data
  end
  local LogicIslandStatus = require("GameLua.Mod.SocialIsland.Client.IslandStatusLogic")
  local socialIslandStatus = LogicIslandStatus:CheckIslandStatus(status.socialland_type, status.game_id, status.land_id)
  local home_macros = require("client.slua.logic.home.home_macros")
  self._isLandState = 1
  if not (not PlayerStatusUtil.IsBattle(status) or status.socialland_type ~= 0 or status.game_sub_mode == home_macros.Home_SubMode.Visit or PlayerStatusUtil.IsMainCity(status)) or (status.teamState or 0) > 2 then
    data.bIsShow = false
  elseif socialIslandStatus == LogicIslandStatus.ENUM_ISLAND_STATUS.ME_ON_ISLAND then
    data.bIsShow = true
    self._isLandState = 1
  elseif socialIslandStatus == LogicIslandStatus.ENUM_ISLAND_STATUS.TARGET_ON_ISLAND then
    data.bIsShow = true
    self._isLandState = 2
  elseif socialIslandStatus == LogicIslandStatus.ENUM_ISLAND_STATUS.ON_DIFFERENT_ISLAND then
    data.bIsShow = true
    self._isLandState = 3
  elseif socialIslandStatus == LogicIslandStatus.ENUM_ISLAND_STATUS.ON_SAME_ISLAND then
    data.bIsShow = true
    self._isLandState = 4
  else
    data.bIsShow = false
  end
  return data
end
function Personal_Info_UIBP:SetTipsBySetAnchors(maxX, maxY)
  if not self.UIRoot then
    return
  end
  local menuWidget = self.UIRoot.menu
  menuWidget.Slot:SetPosition(FVector2D(0, 0))
  local util = require("client.slua_ui_framework.util")
  util.SetAnchors(menuWidget, maxX, maxY, maxX, maxY)
  util.SetAlignment(menuWidget, 0, 0)
end
function Personal_Info_UIBP:CheckCanCare()
  local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
  local profile = logic_profile:GetLocalProfile(self.uid)
  if not profile then
    return false
  end
  local latestStatusStamp = profile.frd_status_end_time or 0
  local FriendHandler = require("client.network.Protocol.FriendHandler")
  if FriendHandler.friend_status_data and FriendHandler.friend_status_data.self_like_list then
    for _, timestamp in pairs(FriendHandler.friend_status_data.self_like_list) do
      if timestamp == latestStatusStamp then
        return false
      end
    end
  end
  return true
end
function Personal_Info_UIBP:OnClickButton_Reservation()
  self:PlayAudio(sound_config.click_v1)
  local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
  local player = logic_profile:GetLocalProfile(self.uid)
  if not player or type(player) ~= "table" or not next(player) then
    return
  end
  local LogicFriend = require("client.slua.logic.friend.logic_new_friend")
  local state = LogicFriend.GetReserveState(self.uid)
  if state ~= 1 then
    return
  end
  if player.game_sub_mode == 26001 then
    ShowNotice(39036)
    return
  end
  local SingleTrainTool = require("GameLua.Mod.SingleTraining.GamePlay.Data.SingleTrainTool")
  if SingleTrainTool.IsSelfInTraining() then
    ShowNotice(43911)
    return
  else
    log(bWriteLog and "Personal_Info_UIBP:OnClickButton_Reservation not in single train")
  end
  if not self.UIRoot then
    print(bWriteLog and "Personal_Info_UIBP:OnClickButton_Reservation UIRoot is nil")
    return
  end
  local TeamUpNewSystem = require("client.slua.logic.teamup.logic_team_up")
  local logic_friend_list_ui = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_friend_list_ui)
  local from = logic_friend_list_ui:GetFrom()
  if from == FLMacros.ENUM_OPEN_FROM.ISMOREPLAYERNUM then
    LogicFriend.ReserveFriend(player.uid, TeamUpNewSystem.E_InviteFromType.SwtichModeAppointment)
  else
    LogicFriend.ReserveFriend(player.uid, TeamUpNewSystem.E_InviteFromType.Appointment)
  end
  local jumpBackData = {
    configName = "Lobby_InviteFriend_BP",
    ctorData = {
      [1] = from,
      [2] = logic_friend_list_ui:GetTabID(),
      [3] = player.uid
    }
  }
  local logic_chat_main = require("client.slua.logic.lobby_chat.logic_chat_main")
  logic_chat_main.RecordJumpBackData(jumpBackData)
  logic_chat_main.OpenChatMainByFriendId(player.uid)
  UIManager.CloseUI(UIManager.UI_Config.Lobby_InviteFriend_BP)
  local tlog_report_utils = require("client.slua.config.tlog.tlog_report_utils")
  tlog_report_utils.ReportTLogEvent(TLogEventDefine.FriendSideBarReserveClick)
end
function Personal_Info_UIBP:OnFriendStatusChange()
  self:UpdateUI()
end
function Personal_Info_UIBP:SetTips(widget, offsetX, offsetY)
end
function Personal_Info_UIBP:SetTipsPosition(offsetX, offsetY)
  if not self.UIRoot then
    return
  end
  local WidgetLayoutLibrary = import("WidgetLayoutLibrary")
  local slot = WidgetLayoutLibrary.SlotAsCanvasSlot(self.UIRoot.SizeBox_Root)
  local x = -350 + offsetX
  local y = offsetY
  slot:SetPosition(FVector2D(x, y))
end
function Personal_Info_UIBP:LoadCarteBGEffect(effect_bp_path, bLoopAnim, carte_frame_equip_id, downloadParentPanel, downloadArr)
  local logic_roleinfo_carte_frame = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_roleinfo_carte_frame)
  local pak_util = require("client.common.pak_util")
  local PufferManager = require("client.slua.logic.download.puffer.puffer_manager")
  if not effect_bp_path or effect_bp_path == "" then
    self:ClearCarteSkin()
    self.UIRoot.WidgetSwitcher_Effect:SetActiveWidgetIndex(0)
    self.isShowSkin = false
    return
  end
  if pak_util.IsFileExist(effect_bp_path) then
    self.isShowSkin = true
    self:ChangeTextColorBySkin()
    self:ClearCarteSkin()
    self.UIRoot.WidgetSwitcher_Effect:SetActiveWidgetIndex(1)
    local uiConfig = UIManager.UI_Config.Lobby_RoleInfo_EffectSkin_Item_UIBP
    local aniName
    if bLoopAnim then
      aniName = "Auto_Loop"
    end
    local extraData = {}
    local item_data = logic_roleinfo_carte_frame:GetCrateFrameBGCfg(carte_frame_equip_id)
    if item_data and item_data.Level == 3 then
      extraData.bEnableGyroscope = true
    end
    self.card_skin_bp = self:CreateChildWindowWithBpPath("CanvasPanel_Effect_002", uiConfig, effect_bp_path, aniName, extraData)
    return
  end
  self.isShowSkin = false
  self:ClearCarteSkin()
  self.UIRoot.WidgetSwitcher_Effect:SetActiveWidgetIndex(0)
  log_format(bWriteLog and "Personal_Info_UIBP:LoadCarteBGEffect effect_bp_path not exist=%s", tostring(effect_bp_path))
  if downloadParentPanel then
    local PufferConst = require("client.slua.logic.download.puffer_const")
    local common_download_handler = require("client.slua.common.common_download_handler")
    common_download_handler.CreateDownloadUI(PufferConst.ENUM_DownloadType.ODPAK, {effect_bp_path}, downloadParentPanel, {
      callback = function()
        if not slua.isValid(self.UIRoot) then
          return
        end
        self:UpdateCardSkin()
      end,
      hideMask = true
    })
  else
    log_format(bWriteLog and "Personal_Info_UIBP:LoadCarteBGEffect downloadParentPanel not exist=%s", tostring(effect_bp_path))
  end
end
local class = require("class")
local ui_base = require("client.slua_ui_framework.base")
local CPersonal_Info_UIBP = class(ui_base, nil, Personal_Info_UIBP)
return CPersonal_Info_UIBP
