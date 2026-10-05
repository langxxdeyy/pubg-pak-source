local Lobby_RoleInfo_InteractRecord_UIBP = {}
function Lobby_RoleInfo_InteractRecord_UIBP:ctor(_, uid)
  log(bWriteLog and "[DeanJYT] Lobby_RoleInfo_InteractRecord_UIBP:ctor uid = " .. tostring(uid))
  self.showingUid = uid
  self.curSelectedSeasonID = 0
  self.bComboBoxInited = false
end
local C_Showing_Slot_Index_Start = 3
local C_Showing_Slot_Index_End = 22
local C_Slot_Info_Name_Prefix = "UTRichTextBlock_InteractRecord_Name_Slot_"
local C_Slot_Info_Value_Prefix = "UTRichTextBlock_InteractRecord_Value_Slot_"
local C_Slot_Prefix = "Slot_"
local C_Info_Name_Desc_Button = "Button_Slot_"
local C_DefaultSegment = 101
local C_IntimacyRelationships = {
  200030,
  200031,
  200032,
  200033,
  73243,
  8075861
}
local C_EmptyDataPlaceHolder = "-"
function Lobby_RoleInfo_InteractRecord_UIBP:OnInitialize()
  Lobby_RoleInfo_InteractRecord_UIBP.__super.OnInitialize(self)
  self.Common_Popup_Large_UIBP = self:InitCommonPopup(self.UIRoot.Common_Popup_Large_UIBP)
  self.ComboBox_Season = self:InitCommonComboBoxNew(self.UIRoot.Common_ComboBox_UIBP)
end
function Lobby_RoleInfo_InteractRecord_UIBP:RegistEvents()
  Lobby_RoleInfo_InteractRecord_UIBP.__super.RegistEvents(self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Share, self.OnButton_ShareClick, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Intimacy, self.OnButton_IntimacyClick, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Title, self.OnButton_TitleClick, self)
  self:AddControlEventByControl(self.UIRoot.Common_Popup_Large_UIBP.Button_Help, "OnClicked", self.OnButton_HelpClick, self)
  self.ComboBox_Season:SetRefreshOptionCallback(self.OnRefresSeasonItem, self)
  self.ComboBox_Season:SetSelectOptionCallback(self.OnSelectSeasonItem, self)
  for i = C_Showing_Slot_Index_Start, C_Showing_Slot_Index_End do
    local widget_button = self.UIRoot[C_Info_Name_Desc_Button .. tostring(i)]
    if widget_button then
      self:AddOnClickedEventByControl(widget_button, self.OnButton_SlotDescClick, self, i)
    end
  end
  self:AddCommonEvent(EVENTTYPE_ROLEINFO, EVENTID_CUMULATIVE_ROLEINFO_INTERACT_RECORD, self.OnCumulativeDataUpdated, self)
  self:AddCommonEvent(EVENTTYPE_ROLEINFO, EVENTID_SEASON_ROLEINFO_INTERACT_RECORD, self.OnSeasonDataUpdated, self)
end
function Lobby_RoleInfo_InteractRecord_UIBP:OnShow()
  Lobby_RoleInfo_InteractRecord_UIBP.__super.OnShow(self)
  self:RefreshPopup()
  self:RefreshPlayerView()
  self:RefreshFriendInteractTitle()
  local seasonOptionData = {
    {
      seasonID = 0,
      seasonName = LocUtil.GetLocalizeResStr(4462)
    }
  }
  self.ComboBox_Season:SetData(seasonOptionData)
  self:SelectSeasonItem(self.curSelectedSeasonID)
  self.bComboBoxInited = true
  local logic_friend_interact_record = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_friend_interact_record)
  logic_friend_interact_record:RequestCumulativeInteractDataForPlayer(self.showingUid)
  logic_friend_interact_record:RequestSeasonInteractDataForPlayer(self.showingUid)
end
function Lobby_RoleInfo_InteractRecord_UIBP:RefreshPopup()
  local title = LocUtil.GetLocalizeStrConcatenation(77951)
  local extraData = {
    helpInfo = {
      titleText = title,
      contentText = LocUtil.GetLocalizeStrConcatenation(320028)
    }
  }
  self.Common_Popup_Large_UIBP:SetData(self, title, extraData)
end
function Lobby_RoleInfo_InteractRecord_UIBP:RefreshPlayerView()
  local LobbySocialSystem = require("client.slua.logic.lobby.Left.logic_lobby_social")
  local UIUtil = require("client.common.ui_util")
  local myProfile = LobbySocialSystem.GetProfileByUID(DataMgr.roleData.uid)
  if myProfile then
    self.UIRoot.SizeBox_Gender_Me:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    self.UIRoot.Common_Gender_Me:LoadIcon(myProfile.uid)
    self.UIRoot.Common_Avatar_BP_Me:InitView(1, DataMgr.roleData.uid, myProfile.picUrl, tonumber(myProfile.sex) + 1, myProfile.cur_avatar_box_id, myProfile.level, false, "")
    self.UIRoot.Common_RankIntegralLevel_Style_Small_UIBP_Me:SetRankInteral(myProfile.cur_max_segment_level or C_DefaultSegment, nil)
    self.UIRoot.TextBlock_MyName:SetText(myProfile.nickName)
    UIUtil.UpdateNationImage(self.UIRoot.Image_Flag_Me, myProfile.nation)
  else
    self.UIRoot.SizeBox_Gender_Me:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  end
  local profile = LobbySocialSystem.GetProfileByUID(self.showingUid)
  if profile then
    self.UIRoot.SizeBox_Gender_Other:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    self.UIRoot.Common_Gender_Other:LoadIcon(profile.uid)
    self.UIRoot.Common_Avatar_BP_Other:InitView(1, self.showingUid, profile.picUrl, tonumber(profile.sex) + 1, profile.cur_avatar_box_id, profile.level, false, "")
    self.UIRoot.Common_RankIntegralLevel_Style_Small_UIBP_Other:SetRankInteral(profile.cur_max_segment_level or C_DefaultSegment, nil)
    self.UIRoot.TextBlock_OtherName:SetText(profile.nickName)
    UIUtil.UpdateNationImage(self.UIRoot.Image_Flag_Other, profile.nation)
  else
    self.UIRoot.SizeBox_Gender_Other:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  end
  local LogicFriend = require("client.slua.logic.friend.logic_new_friend")
  local relation = LogicFriend.GetRelation(self.showingUid)
  if 0 < relation then
    self.UIRoot.WidgetSwitcher_RelationIcon:SetActiveWidgetIndex(relation - 1)
    self.UIRoot.TextBlock_RelationShip:SetText(LocUtil.GetLocalizeResStr(C_IntimacyRelationships[relation]))
    local IntimacyUtils = require("client.slua.logic.friend.Intimacy.IntimacyUtils")
    local bIsBondingSystem = IntimacyUtils.IsBondingSystemOpen()
    if not bIsBondingSystem and relation == 6 then
      self.UIRoot.WidgetSwitcher_RelationIcon:SetActiveWidgetIndex(1)
      self.UIRoot.TextBlock_RelationShip:SetText(LocUtil.GetLocalizeResStr(C_IntimacyRelationships[2]))
    end
    local intimacy = LogicFriend.GetInnerFriendIntimacy(self.showingUid)
    local IntimacyAwardSystem = require("client.slua.logic.person_space.logic_intimacy_award")
    local intimacyLvCfg = IntimacyAwardSystem.GetInitimacyLvCfg(intimacy)
    self.UIRoot.TextBlock_Intimate:SetText(intimacy)
    if intimacyLvCfg then
      self.UIRoot.TextBlock_IntimacyLevel:SetText(intimacyLvCfg.Level)
    end
    self:SetWidgetVisible(self.UIRoot.CanvasPanel_IntimacyLevel, true)
  else
    local intimacy = LogicFriend.GetInnerFriendIntimacy(self.showingUid)
    self.UIRoot.TextBlock_Intimate:SetText(intimacy)
    self.UIRoot.WidgetSwitcher_RelationIcon:SetActiveWidgetIndex(6)
    self.UIRoot.TextBlock_RelationShip:SetText(LocUtil.LocalizeResFormat(7255, intimacy, 100))
    self:SetWidgetVisible(self.UIRoot.CanvasPanel_IntimacyLevel, false)
  end
  local logic_interaction = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_interaction)
  local score = logic_interaction:GetInteractionScore(self.showingUid)
  self.UIRoot.TextBlock_Interact:SetText(score or 0)
  local iconpath = logic_interaction:GetIconInfoByID(self.showingUid) or "/Game/UMG/Texture_200/Atlas/LobbyChatUI/Frames/Scintilla_Handshake_png.Scintilla_Handshake_png"
  self:SetTexture(self.UIRoot.Image_Interact, iconpath)
end
function Lobby_RoleInfo_InteractRecord_UIBP:SetWidgetVisibleWithCheck(widget, visible, isButton)
  if not slua.isValid(widget) then
    return
  end
  self:SetWidgetVisible(self, widget, visible, isButton)
end
function Lobby_RoleInfo_InteractRecord_UIBP:SetTextWithCheck(widget, text)
  if not slua.isValid(widget) then
    return
  end
  widget:SetText(text)
end
function Lobby_RoleInfo_InteractRecord_UIBP:RefreshSingleSlotView(slotID)
  local logic_friend_interact_record = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_friend_interact_record)
  local data = logic_friend_interact_record:GetSingleShowInfoBySlot(self.showingUid, C_Slot_Prefix .. slotID, self.curSelectedSeasonID)
  if not data then
    self:SetTextWithCheck(self.UIRoot[C_Slot_Info_Name_Prefix .. slotID], C_EmptyDataPlaceHolder)
    self:SetTextWithCheck(self.UIRoot[C_Slot_Info_Value_Prefix .. slotID], C_EmptyDataPlaceHolder)
    return
  end
  log_tree("[DeanJYT] Lobby_RoleInfo_InteractRecord_UIBP:RefreshSingleSlotView slotID = " .. tostring(slotID), data)
  self:SetTextWithCheck(self.UIRoot[C_Slot_Info_Name_Prefix .. slotID], data.desc)
  self:SetTextWithCheck(self.UIRoot[C_Slot_Info_Value_Prefix .. slotID], data.value)
end
function Lobby_RoleInfo_InteractRecord_UIBP:RefreshAllSlotView()
  for i = C_Showing_Slot_Index_Start, C_Showing_Slot_Index_End do
    self:RefreshSingleSlotView(i)
  end
end
function Lobby_RoleInfo_InteractRecord_UIBP:RefreshFriendInteractTitle()
  local logic_friend_interact_record = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_friend_interact_record)
  local titleCfg = logic_friend_interact_record:GetInteractTitle(self.showingUid)
  if titleCfg and titleCfg.title ~= "" then
    self:SetWidgetVisible(self.UIRoot.CanvasPanel_Title, true)
    self.UIRoot.UTRichTextBlock_FriendTitle:SetText(titleCfg.title)
  else
    self:SetWidgetVisible(self.UIRoot.CanvasPanel_Title, false)
  end
end
function Lobby_RoleInfo_InteractRecord_UIBP:SelectSeasonItem(seasonID)
  local totalOptionCount = self.ComboBox_Season:GetOptionCount()
  for i = 1, totalOptionCount do
    local data = self.ComboBox_Season:GetOptionData(i)
    if data.seasonID == seasonID then
      self.ComboBox_Season:SelectIndex(i)
      return
    end
  end
end
function Lobby_RoleInfo_InteractRecord_UIBP:OnButton_ShareClick()
  self:PlayAudio(sound_config.click)
  self.ComboBox_Season:CloseComboBox()
  local util = require("client.slua_ui_framework.util")
  local shareCfg = {
    campaign = "interact_record",
    share_type = ShareBtnTLogShareTypeDefine.FriendInteraction
  }
  util.ShowShare(shareCfg, UIManager.UI_Config.Lobby_RoleInfo_InteractRecord_Share_UIBP, self.showingUid, self.curSelectedSeasonID)
  local ShareMgr = require("client.logic.share.share_logic")
  ShareMgr.ShareBtnReq(1, ShareBtnTLogShareTypeDefine.FriendInteraction, nil, nil)
end
function Lobby_RoleInfo_InteractRecord_UIBP:OnButton_IntimacyClick()
  self:PlayAudio(sound_config.click)
  self.ComboBox_Season:CloseComboBox()
  local isLobbyOrMainCity = GameStatus.IsInLobbyOrMainCity()
  local isHomeMode = GameStatus.IsPHomeMode()
  log(bWriteLog and "Lobby_IntimateRelationship_Chat_UIBP.OnClickAvatarCallback isLobbyOrMainCity = " .. tostring(isLobbyOrMainCity))
  if not isLobbyOrMainCity then
    if CGameState and CGameState.bSocialIslandGameMode then
      ShowNotice(34159)
    elseif CGameState and CGameState.bIsCreativeWoW then
      ShowNotice(8700883)
    elseif isHomeMode then
      ShowNotice(655365)
    else
      ShowNotice(43911)
    end
    return
  end
  local LogicFriend = require("client.slua.logic.friend.logic_new_friend")
  local relation = LogicFriend.GetRelation(self.showingUid)
  local extraData = {
    viewIndex = 1,
    friendUid = self.showingUid,
    subTabID = 25
  }
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  if relation <= 0 then
    extraData = {
      subTabID = 25,
      intimacyInfo = {
        viewIndex = 2,
        friendUid = self.showingUid
      }
    }
  end
  local bShow = RoleInfoMainSystem.Show(RoleInfoMainSystem.IntimateRelationship, RoleInfoMainSystem.RoleInfoOpenFromType.Null, DataMgr.roleData.uid, extraData)
  if bShow == true then
    local roleInfoUI = UIManager.GetUI(UIManager.UI_Config.roleinfo_main)
    if roleInfoUI then
      local PublishRegionMacros = require("client.slua.config.ClientMacros.PublishRegionMacros")
      local isFitVersion = PublishRegionMacros.IsFITVersion()
      local LogicFitVersionDownload = require("client.slua.logic.download.fit.logic_fitVersion_download")
      if LogicFitVersionDownload.IsFitLobbyResDownloaded() then
        roleInfoUI.TabID = RoleInfoMainSystem.IntimateRelationship
        roleInfoUI.SubTabID = RoleInfoMainSystem.IntimateRelationship_SubTab.Close
        roleInfoUI:UpdateUI()
      end
    end
    local tlog_report_utils = require("client.slua.config.tlog.tlog_report_utils")
    tlog_report_utils.ReportTLogEvent(TLogEventDefine.InteractRecord_Intimacy)
    local friend_applylist = UIManager.GetUI(UIManager.UI_Config.friend_applylist)
    if friend_applylist then
      UIManager.CloseUI(UIManager.UI_Config.friend_applylist)
    end
    self:CloseSelf()
  end
end
function Lobby_RoleInfo_InteractRecord_UIBP:OnButton_TitleClick()
  self:PlayAudio(sound_config.click)
  self.ComboBox_Season:CloseComboBox()
  local logic_friend_interact_record = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_friend_interact_record)
  local titleCfg = logic_friend_interact_record:GetInteractTitle(self.showingUid)
  if titleCfg and titleCfg.desc ~= "" then
    local tipsParams = {
      widget = self.UIRoot.Button_Title,
      content = titleCfg.desc
    }
    UIManager.ShowUI(UIManager.UI_Config.Common_Other_Tips_UIBP, tipsParams)
  end
end
function Lobby_RoleInfo_InteractRecord_UIBP:OnButton_HelpClick()
  log(bWriteLog and "[DeanJYT] Lobby_RoleInfo_InteractRecord_UIBP:OnButton_HelpClick")
  self.ComboBox_Season:CloseComboBox()
end
function Lobby_RoleInfo_InteractRecord_UIBP:OnButton_SlotDescClick(slotID)
  self:PlayAudio(sound_config.click)
  self.ComboBox_Season:CloseComboBox()
  local logic_friend_interact_record = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_friend_interact_record)
  local data = logic_friend_interact_record:GetSingleShowInfoBySlot(self.showingUid, C_Slot_Prefix .. slotID, self.curSelectedSeasonID)
  if not data then
    return
  end
  local TimeUtil = require("client.common.time_util")
  local content = LocUtil.LocalizeFormatConcatenation(data.detailedDescID, "<Yellow>" .. TimeUtil.FormatTime_YMD(data.recordStartTime) .. "</>")
  local tipsParams = {
    widget = self.UIRoot[C_Info_Name_Desc_Button .. tostring(slotID)],
    content = content
  }
  UIManager.ShowUI(UIManager.UI_Config.Common_Other_Tips_UIBP, tipsParams)
end
function Lobby_RoleInfo_InteractRecord_UIBP:OnRefresSeasonItem(widget, data, index, selectIndex)
  widget.TextBlock_ItemName:SetText(data.seasonName)
end
function Lobby_RoleInfo_InteractRecord_UIBP:OnSelectSeasonItem(widget, data)
  log(bWriteLog and "[DeanJYT] Lobby_RoleInfo_InteractRecord_UIBP:OnSelectSeasonItem")
  if self.bComboBoxInited then
    self:PlayAudio(sound_config.click_v1)
  end
  widget.TextBlock_ItemName:SetText(data.seasonName)
  local lastSelectID = self.curSelectedSeasonID
  self.curSelectedSeasonID = data.seasonID
  self:RefreshAllSlotView()
  if self.bComboBoxInited and lastSelectID ~= self.curSelectedSeasonID then
    log(bWriteLog and "[DeanJYT] Lobby_RoleInfo_InteractRecord_UIBP:OnSelectSeasonItem report TLog")
    local tlog_report_utils = require("client.slua.config.tlog.tlog_report_utils")
    tlog_report_utils.ReportTLogEvent(TLogEventDefine.InteractRecord_Season)
  end
end
function Lobby_RoleInfo_InteractRecord_UIBP:OnCumulativeDataUpdated(_, _, uid)
  if uid ~= self.showingUid then
    return
  end
  if self.curSelectedSeasonID == 0 then
    self.bComboBoxInited = false
    self:SelectSeasonItem(self.curSelectedSeasonID)
    self.bComboBoxInited = true
  end
  self:RefreshFriendInteractTitle()
end
local SeasonOptionSortFunc = function(a, b)
  local aID = a and a.seasonID or -1
  local bID = b and b.seasonID or -1
  return aID < bID
end
function Lobby_RoleInfo_InteractRecord_UIBP:OnSeasonDataUpdated(_, _, uid)
  if uid ~= self.showingUid then
    return
  end
  local logic_friend_interact_record = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_friend_interact_record)
  local allSeasonData = logic_friend_interact_record:GetAllSeasonInteractRecordData(self.showingUid)
  if not allSeasonData then
    log(bWriteLog and "[DeanJYT] Lobby_RoleInfo_InteractRecord_UIBP:OnSeasonDataUpdated allSeasonData is nil")
    return
  end
  local seasonOptionData = {
    {
      seasonID = 0,
      seasonName = LocUtil.GetLocalizeResStr(4462)
    }
  }
  for k, v in pairs(allSeasonData) do
    seasonOptionData[#seasonOptionData + 1] = {
      seasonID = k,
      seasonName = CDataTable.GetTableData("SeasonInfo", k).SeasonName
    }
  end
  self.bComboBoxInited = false
  table.sort(seasonOptionData, SeasonOptionSortFunc)
  self.ComboBox_Season:SetData(seasonOptionData)
  self:SelectSeasonItem(self.curSelectedSeasonID)
  self.bComboBoxInited = true
end
local class = require("class")
local ui_base = require("client.slua_ui_framework.base")
local CLobby_RoleInfo_InteractRecord_UIBP = class(ui_base, nil, Lobby_RoleInfo_InteractRecord_UIBP)
return CLobby_RoleInfo_InteractRecord_UIBP
