local CoupleAvatarConfig = require("client.slua.logic.lobby.Left.CoupleAvatarConfig")
local RoleInfoSegmentUI = {}
local EnumApplyType = {
  AddFriend = 1,
  Relation = 2,
  Partner = 3
}
local ModeType = {
  RANK = 0,
  MATCH = 1,
  PEAKGAME = 2,
  REFACTOR = 3
}
local ERankShowType = {Tpp = 1, Fpp = 2}
local ERankPlayersType = {
  Team = 1,
  Duo = 2,
  Solo = 3
}
local Month = 31
local Year = 365
local C_ModeMap = {
  [1] = {
    [1] = "squad",
    [2] = "duo",
    [3] = "solo"
  },
  [2] = {
    [1] = "fppsquad",
    [2] = "fppduo",
    [3] = "fppsolo"
  }
}
local LogicPeakGameUtil = require("client.logic.PeakGame.LogicPeakGameUtil")
local C_DefaultSegment = 101
function RoleInfoSegmentUI:ctor(_, extra)
  self.currMode = ModeType.REFACTOR
  self.rankShowType = ERankShowType.Tpp
  if extra then
    self.bInit = extra.bInit
  end
  self._tAvatarShowCfg = {
    UseCacheData = true,
    bCheckIsShow = true,
    bIsShowCar = true,
    bCustomerView = true,
    nSourceType = Enum_AvatarShowSource.RoleInfoSegmentUI
  }
  self._tCoupleUIShowCfg = {bIsCheckHideRoleTip = true, bIsShowDownloadUI = true}
  self._cObj_coupleAvatarUI = nil
  self.dontCollectAnim = false
  self.bUIShow = true
  self.bButtonClick = false
  self.bParentEnterAnimFinished = false
  self.isShowSkin = false
  self.isDefultNameColor = true
  self.FrameAnimPlayed = false
end
function RoleInfoSegmentUI:RegistEvents()
  RoleInfoSegmentUI.__super.RegistEvents(self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_ShowInformation, self.OnClickButtonShowInfo, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_14, self.OnButtonAceImprintClick, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_ArceText, self.OnButtonAceImprintClick, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_3, self.OnClickCorpsButton, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Join11, self.OnClickCorpsButton, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Apply11, self.OnClickApplyButton, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Invite11, self.OnClickInviteButton, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_corpsAlias, self.OnClickCorpsAliasButton, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_CopyPlayerID, self.OnClickCopyPlayerIDButton, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_0, self.OnClickRPButton, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Upvote_Tip, self.OnClickUpvoteButton, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_ScoreActive, self.OnClickScoreActiveButton, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_ScoreNotActive, self.OnClickScoreNotActiveButton, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_11, self.OnClickRankButton, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_16, self.OnClickRankButton, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_IntegralLevel, self.OnClickSmallIcon, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_switch, self.OnClickSwitchMode, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Tourist, self.OnButtonTourist, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_4, self.OnClickReportButton, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Jubao, self.OnClickJubaoButton, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Pinbi, self.OnClickPinbiButton, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_2, self.OnClickCopyNameButton, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_5, self.OnClickChangeProfileButton, self)
  self:AddControlEventByControl(self.UIRoot.Common_Avatar_BP, "OnClickItemCallback", self.OnClickHeadCallback, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_17, self.OnClickButtonSeasonRank, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_12, self.OnClickButtonHistoryMaxText, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_19, self.OnClickButtonAchieveText, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_InteractRecord, self.OnButton_InteractRecordClick, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_QRCode, self.OnClickShareButton, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Lock, self.OnClickLockButton, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Casual, self.OnClickCasualButton, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_10, self.OnClickPeakHistoryMaxButton, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_13, self.OnClickPeakRankButton, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_More, self.OnClicMoreButton, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_8, self.OnClicSaveButton, self)
  self:AddOnClickedEventByControl(self.UIRoot.Common_Collect_Level_HugeShow_UIBP.Button_TIPS, self.OnClickButton_TIPS, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Award, self.OnClickLevelAward, self)
  self:AddOnClickedEventByControl(self.UIRoot.Season_WeaponStrength_Title_UIBP.Button_WSDetail, self.OnClickWSDetail, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_WoWPass, self.OnClickWoWPass, self)
  self:AddCommonEvent(EVENTTYPE_DATA_MGR, EVNETID_DATAMGR_ROLE_CREDIT, self.OnRefreshCreditScore, self)
  self:AddCommonEvent(EVENTTYPE_ROLEINFO, EVENTID_TEAM_EVALUATION_INIT, self.OnRefreshEvaluationEntrance, self)
  self:AddCommonEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_ROLEINFO, self.OnRefreshRoleInfo, self)
  self:AddCommonEvent(EVENTTYPE_DATA_MGR, EVENTID_ACE_IMPRINT_UPDATE, self.OnRefreshAceImprint, self)
  self:AddCommonEvent(EVENTTYPE_SEGMENT_TITLE, EVENTID_SEGMENT_TITLE_SET_RSP, self.UpdateSegmentInfo, self)
  self:AddCommonEvent(EVENTTYPE_ACHIEVEMENT, EVENTID_ACHIEVEMENT_Summary, self.OnRefreshAchievement, self)
  self:AddCommonEvent(EVENTTYPE_LOBBY, EVENTID_UPDATE_LOBBY_AVATAR, self.OnRefreshProfile, self)
  self:AddCommonEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_NATIONAREA, self.OnRefreshProfile, self)
  self:AddCommonEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_LOBBY_SOCIAL_CARD_UPDATE, self.OnRefreshProfile, self)
  self:AddCommonEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_LOBBY_SOCIAL_UPDATE_HEAD_ICON, self.OnRefreshHead, self)
  self:AddCommonEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_LOBBY_SOCIAL_CORPS_ALIAS, self.OnRefreshCorpsSummary, self)
  self:AddCommonEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_LOBBY_SOCIAL_CORPS_SUMMARY, self.OnRefreshCorpsSummary, self)
  self:AddCommonEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_CARTE_FRAME_CHANGE, self.UpdateCarteFrame, self)
  self:AddCommonEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_PROFILE_FRAME_INFO, self.UpdateProfileFrame, self)
  self:AddCommonEvent(EVENTTYPE_PEAKGAME, EVENTID_PEAKGAME_RATING_NOTIFY, self.OnRefreshPeakGame, self)
  self:AddCommonEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_WEAPONSTRENGTH_ALIAS_GET_SELECT_ALIAS_LIST, self.UpdateWeaponStrengthAlis, self)
  self:AddCommonEvent(EVENTTYPE_SEASON_YEAR, EVENTID_SEASON_YEAR_BADGE_UPDATE, self.OnSeasonYearBadgeUpdate, self)
  self:AddCommonEvent(EVENTTYPE_SEASON_YEAR, EVENTID_OTHER_SEASON_YEAR_BADGE_UPDATE, self.OnSeasonYearBadgeUpdate, self)
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  local spData = RoleInfoMainSystem.GetSuperData()
  self:AddDataListener(spData, "settingRed", self.OnRefreshShowinfoReddot, self)
  self:AddDataListener(spData, "levelTaskRed", self.OnRefreshLevelAwardReddot, self)
  self:AddControlEventByControl(self.UIRoot.out, "OnAnimationFinished", self.OnAnimationFinished, self)
  self.PeakGame_RankIntegralLevel_Small_Switch_UIBP = LogicPeakGameUtil.InitSmallPeakRankIntegralSwitchWidget(self, self.UIRoot.PeakGame_RankIntegralLevel_Small_Switch_UIBP)
  local roleinfo_main = UIManager.GetUI(UIManager.UI_Config.roleinfo_main)
  if roleinfo_main then
    self:AddOnClickedEventByControl(roleinfo_main.UIRoot.Button_1, self.OnButtonHideClick, self)
    self:AddOnClickedEventByControl(roleinfo_main.UIRoot.Button_2, self.OnButtonReplayClick, self)
  end
  local ScreenInput = import("ScreenInput")
  local UIUtil = require("client.common.ui_util")
  local worldContextObject = UIUtil.GetGameInstance()
  self.screenInput = ScreenInput(worldContextObject)
  self.screenInput:Init()
  self:AddControlEventByControl(self.screenInput, "OnMouseButtonUp", self.OnMouseButtonUp, self)
end
function RoleInfoSegmentUI:OnAnimationFinished()
  self:AddTimerOnce(0, function()
    self:CloseSelf()
  end)
end
function RoleInfoSegmentUI:OnPostInitialize()
  RoleInfoSegmentUI.__super.OnPostInitialize(self)
  EventSystem:postEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_OPEN)
  self:RefreshSkin()
  self:InitNicknameOutline()
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  RoleInfoMainSystem.UpdateRoleinfoSeasonListID(1)
  local CardCollectionPlayerDisplayModule = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.CardCollectionPlayerDisplayModule)
  CardCollectionPlayerDisplayModule:GetCardScroreByUid(DataMgr.roleData.uid)
  self:UpdateUI()
  self:LoadAvatarScene()
  self:ShowPlayerAvatar()
  self:PlayUserWidgetAnimation(self.UIRoot.fadein, 0, 1, 0, 1)
  self.UIRoot.Common_UIPanelBG:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  self:SetWidgetVisible(self.UIRoot.CanvasPanel_Tab, false)
  self.UIRoot.WidgetSwitcher_Mid:SetActiveWidgetIndex(ModeType.REFACTOR)
  self.UIRoot.WidgetSwitcher_8:SetActiveWidgetIndex(1)
  self.UIRoot.TextBlock_21:SetText(LocUtil.GetLocalizeResStr(68405))
  self.UIRoot.TextBlock_29:SetText(LocUtil.GetLocalizeResStr(68417))
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local season_year_util = require("client.logic.season_year.util.season_year_util")
  if season_year_util.CheckFunctionIsOpen() then
    self.UIRoot.TextBlock_47:SetText(LocUtil.GetLocalizeResStr(85103))
    self:SetWidgetVisible(self.UIRoot.SizeBox_Badge_Root, true)
    self:SetWidgetVisible(self.UIRoot.PeakGame_RankIntegralLevel_Style_Large_UIBP_C_1, false)
    local season_year_badge_util = require("client.logic.season_year.util.season_year_badge_util")
    local badgeData
    if RoleInfoSystem.IsSelf() then
      print(bWriteLog and "RoleInfoSegmentUI:OnPostInitialize - Initializing self profile UI badgeData")
      badgeData = season_year_badge_util.GetCurSeasonYearBadgeInfo()
    else
      print(bWriteLog and "RoleInfoSegmentUI:OnPostInitialize - Initializing other player profile UI badgeData")
      badgeData = season_year_badge_util.GetSeasonYearBadge(RoleInfoSystem.CurShowPlayerInfoUid)
    end
    local season_year_util = require("client.logic.season_year.util.season_year_util")
    local season_year_id = season_year_util.GetSeasonYearId()
    if self.season_year_badge == nil then
      local season_year_util = require("client.logic.season_year.util.season_year_util")
      self.season_year_badge = season_year_util.CreateSeasonBadgeToWidget(self, self.UIRoot.SizeBox_Badge_Root, season_year_id, badgeData)
    end
  else
    self.UIRoot.TextBlock_47:SetText(LocUtil.GetLocalizeResStr(68412))
    self:SetWidgetVisible(self.UIRoot.SizeBox_Badge_Root, false)
    self:SetWidgetVisible(self.UIRoot.PeakGame_RankIntegralLevel_Style_Large_UIBP_C_1, true)
  end
  self.UIRoot.TextBlock_49:SetText(LocUtil.GetLocalizeResStr(68406))
  self:SetWidgetVisible(self.UIRoot.Button_ShowInformation, false)
  self:SetWidgetVisible(self.UIRoot.Button_6, false)
  self:SetWidgetVisible(self.UIRoot.Image_43, false)
  self:SetWidgetVisible(self.UIRoot.Button_More, true, true)
  local switch = LobbySystem.CheckOpen(BP_ENUM_SWITCH_ROLE_INFO_SHARE)
  if switch then
    self:TryShowFirstEnterGuide()
  end
  local season_year_util = require("client.logic.season_year.util.season_year_util")
  if RoleInfoSystem.IsSelf() then
    self.UIRoot.TextBlock_29:SetText(LocUtil.GetLocalizeResStr(605))
    self.UIRoot.TextBlock_42:SetText(LocUtil.GetLocalizeResStr(609))
    self.UIRoot.TextBlock_44:SetText(LocUtil.GetLocalizeResStr(607))
    self.UIRoot.TextBlock_26:SetText(LocUtil.GetLocalizeResStr(604))
    local cycleResStrID = 68425
    if season_year_util.CheckFunctionIsOpen() then
      cycleResStrID = 805862
    end
    self.UIRoot.TextBlock_25:SetText(LocUtil.GetLocalizeResStr(cycleResStrID))
    self.UIRoot.TextBlock_23:SetText(LocUtil.GetLocalizeResStr(68415))
    if RoleInfoMainSystem.GetSaveDataSwitch() and RoleInfoMainSystem.IsMe() then
      self:SetWidgetVisible(self.UIRoot.Button_8, true, true)
      self:SetWidgetVisible(self.UIRoot.Image_14, true)
    else
      self:SetWidgetVisible(self.UIRoot.Button_8, false)
      self:SetWidgetVisible(self.UIRoot.Image_61, false)
      self:SetWidgetVisible(self.UIRoot.Image_14, false)
    end
  else
    self.UIRoot.TextBlock_23:SetText(LocUtil.GetLocalizeResStr(68408))
    self.UIRoot.TextBlock_29:SetText(LocUtil.GetLocalizeResStr(42661))
    self.UIRoot.TextBlock_42:SetText(LocUtil.GetLocalizeResStr(42637))
    self.UIRoot.TextBlock_44:SetText(LocUtil.GetLocalizeResStr(607))
    self.UIRoot.TextBlock_26:SetText(LocUtil.GetLocalizeResStr(42635))
    local cycleResStrID = 42634
    if season_year_util.CheckFunctionIsOpen() then
      cycleResStrID = 805868
    end
    self.UIRoot.TextBlock_25:SetText(LocUtil.GetLocalizeResStr(cycleResStrID))
    self:SetWidgetVisible(self.UIRoot.Image_43, true)
    self:SetWidgetVisible(self.UIRoot.Image_61, false)
    self:SetWidgetVisible(self.UIRoot.Button_8, false)
    self:SetWidgetVisible(self.UIRoot.Image_14, true)
  end
end
function RoleInfoSegmentUI:OnShow()
  RoleInfoSegmentUI.__super.OnShow(self)
  local roleinfo_main = UIManager.GetUI(UIManager.UI_Config.roleinfo_main)
  if roleinfo_main then
    roleinfo_main:SetWidgetVisible(roleinfo_main.UIRoot.Button_1, true, true)
    local logic_roleInfo_background = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_roleInfo_background)
    if logic_roleInfo_background:HasHighLevelEffect() then
      roleinfo_main:SetWidgetVisible(roleinfo_main.UIRoot.Button_2, true, true)
    end
    if roleinfo_main.UIRoot.Anim_Select then
      roleinfo_main:PlayUserWidgetAnimation(roleinfo_main.UIRoot.Anim_Select, 0, 1, 0, 1)
    end
  end
  self:PlayEffect()
end
function RoleInfoSegmentUI:OnHide()
  RoleInfoSegmentUI.__super.OnHide(self)
  log(bWriteLog and "RoleInfoSegmentUI:OnHide")
  local roleinfo_main = UIManager.GetUI(UIManager.UI_Config.roleinfo_main)
  if roleinfo_main then
    roleinfo_main:SetWidgetVisible(roleinfo_main.UIRoot.Button_1, false)
    roleinfo_main:SetWidgetVisible(roleinfo_main.UIRoot.Button_2, false)
  end
  local logic_roleInfo_background = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_roleInfo_background)
  logic_roleInfo_background:ClearHighLevelEffect()
  self:ShowUIExceptHideAndReplay(true)
end
function RoleInfoSegmentUI:OnClose()
  if self.screenInput then
    self.screenInput:Shutdown()
    self.screenInput = nil
  end
  if self.profile_frame_bp then
    self.profile_frame_bp:CloseSelf()
    self.profile_frame_bp = nil
    self.FrameAnimPlayed = nil
  end
  self:UnloadAvatarScene()
  EventSystem:postEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_CLOSE)
end
function RoleInfoSegmentUI:UpdateUI()
  self:RequestData()
  self:InitWidgetState()
  self:InitTextUI()
  self:UpdateShowinfoReddot()
  self:UpdateLevelAwardReddot()
  self:UpdateRoleInfo()
  self:UpdateInteractRecordEntrance()
  self:UpdatePHomeDoorPlate()
  self:OnRefreshPeakGame()
  self:RefreshCasualSegment()
  self:UpdateWeaponStrengthAlis()
end
function RoleInfoSegmentUI:RequestData()
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  RoleInfoMainSystem.RequestBattleInfo()
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local logic_profile_get_wrap = require("client.slua.logic.user.profile.logic_profile_get_wrap")
  logic_profile_get_wrap.GetNormalProfiles({
    tonumber(RoleInfoSystem.CurShowPlayerInfoUid)
  }, function(list)
    self:OnGetSelfRoleInfoCallBack(list)
  end, Enum_PROFILE_REPORT_CFG.ROLE_INFO, 100, true)
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  if RoleInfoSystem.IsSelf() then
    local logic_roleInfo_weaponstrength_title_select = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_roleInfo_weaponstrength_title_select)
    logic_roleInfo_weaponstrength_title_select:send_get_show_weapon_alias_req()
    local logic_profileframe = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_roleInfo_profileframe)
    if not logic_profileframe.bDataReady then
      logic_profileframe:get_frame_list_req()
    end
  end
  local season_year_util = require("client.logic.season_year.util.season_year_util")
  if season_year_util.CheckFunctionIsOpen() then
    local logic_season_year_badge = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_season_year_badge)
    if RoleInfoSystem.IsSelf() then
      logic_season_year_badge:ReqSeasonYearBadgeInfo(false)
    else
      logic_season_year_badge:ReqOtherSeasonYearBadgeInfo(tonumber(RoleInfoSystem.CurShowPlayerInfoUid))
    end
  end
end
function RoleInfoSegmentUI:InitTextUI()
  self.UIRoot.SelectText:SetText(LocUtil.GetLocalizeResStr(602))
  self.UIRoot.TextBlock_8:SetText(LocUtil.GetLocalizeResStr(603))
  self.UIRoot.UnselectText:SetText(LocUtil.GetLocalizeResStr(602))
  self.UIRoot.TextBlock_19:SetText(LocUtil.GetLocalizeResStr(603))
  self.UIRoot.DayNumText:SetText(LocUtil.GetLocalizeResStr(607))
  self.UIRoot.GameNumText:SetText(LocUtil.GetLocalizeResStr(608))
  self.UIRoot.MatchNumText:SetText(LocUtil.GetLocalizeResStr(612))
  self.UIRoot.WinNumText:SetText(LocUtil.GetLocalizeResStr(613))
  self.UIRoot.TopTenText:SetText(LocUtil.GetLocalizeResStr(614))
  self.UIRoot.KDText:SetText(LocUtil.GetLocalizeResStr(615))
  self.UIRoot.ArceText:SetText(LocUtil.GetLocalizeResStr(611))
  if self:_IsRoleSelf() then
    self.UIRoot.HIstoryMaxText:SetText(LocUtil.GetLocalizeResStr(610))
    self.UIRoot.RankScoreText:SetText(LocUtil.GetLocalizeResStr(604))
    self.UIRoot.CreditText:SetText(LocUtil.GetLocalizeResStr(606))
    self.UIRoot.AchieveText:SetText(LocUtil.GetLocalizeResStr(609))
    self.UIRoot.RankNoText:SetText(LocUtil.GetLocalizeResStr(605))
  else
    self.UIRoot.HIstoryMaxText:SetText(LocUtil.GetLocalizeResStr(42633))
    self.UIRoot.RankScoreText:SetText(LocUtil.GetLocalizeResStr(42635))
    self.UIRoot.CreditText:SetText(LocUtil.GetLocalizeResStr(42636))
    self.UIRoot.AchieveText:SetText(LocUtil.GetLocalizeResStr(42637))
    self.UIRoot.RankNoText:SetText(LocUtil.GetLocalizeResStr(42661))
  end
end
function RoleInfoSegmentUI:InitWidgetState()
  self.PeakGame_RankIntegralLevel_Style_Large_UIBP_C_2 = LogicPeakGameUtil.InitLargePeakRankIntegralWidget(self, self.UIRoot.PeakGame_RankIntegralLevel_Style_Large_UIBP_C_2)
  self.PeakGame_RankIntegralLevel_Style_Large_UIBP_C_0 = LogicPeakGameUtil.InitLargePeakRankIntegralWidget(self, self.UIRoot.PeakGame_RankIntegralLevel_Style_Large_UIBP_C_0)
  self.PeakGame_RankIntegralLevel_Style_Small_UIBP_C_1 = LogicPeakGameUtil.InitSmallPeakRankIntegralWidget(self, self.UIRoot.PeakGame_RankIntegralLevel_Style_Small_UIBP_C_1)
  self.UIRoot.SelectSwitch:SetActiveWidgetIndex(ModeType.RANK)
  local PublishRegionMacros = require("client.slua.config.ClientMacros.PublishRegionMacros")
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  if Client.GetPublishRegion() == PublishRegionMacros.VNG and RoleInfoSystem.IsSelf() then
    self.UIRoot.CanvasPanel_24:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
  else
    self.UIRoot.CanvasPanel_24:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  end
  local season_year_util = require("client.logic.season_year.util.season_year_util")
  local seasonYearIsOpen = season_year_util.CheckFunctionIsOpen()
  if self:_IsRoleSelf() then
    self:SetWidgetVisible(self.UIRoot.Button_SeasonRank, true, true)
    self:SetWidgetVisible(self.UIRoot.Button_12, true, true)
    self:SetWidgetVisible(self.UIRoot.Button_AchieveText, true, true)
    self:SetWidgetVisible(self.UIRoot.Button_CreditText, true, true)
    self:SetWidgetVisible(self.UIRoot.Button_RankNoText, true, true)
    local strRegion = Client.GetPublishRegion()
    if PublishRegionMacros.IsBlueholeFamily() then
      self:SetWidgetVisible(self.UIRoot.CanvasPanel_QRCode, false, false)
    else
      self:SetWidgetVisible(self.UIRoot.CanvasPanel_QRCode, true, false)
    end
    self.UIRoot.Button_Casual:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
  else
    self:SetWidgetVisible(self.UIRoot.Button_SeasonRank, true, false)
    self:SetWidgetVisible(self.UIRoot.Button_12, true, false)
    self:SetWidgetVisible(self.UIRoot.Button_AchieveText, true, false)
    self:SetWidgetVisible(self.UIRoot.Button_CreditText, true, false)
    self:SetWidgetVisible(self.UIRoot.Button_RankNoText, true, false)
    self:SetWidgetVisible(self.UIRoot.CanvasPanel_QRCode, false, false)
    self.UIRoot.Button_Casual:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
  end
  self:SetWidgetVisible(self.UIRoot.CanvasPanel_Upvote_Tip, false, false)
  self:InitRestrictButton()
end
function RoleInfoSegmentUI:InitRestrictButton()
  local QRcodeRestrictManager = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.QRcodeRestrictManager)
  local isRestrict = QRcodeRestrictManager:IsRestrictSocial()
  self:SetWidgetVisible(self.UIRoot.Button_Lock, isRestrict, true)
end
function RoleInfoSegmentUI:UpdateShowinfoReddot()
  log(bWriteLog and "RoleInfoSegmentUI:UpdateShowinfoReddot")
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local bSelf = RoleInfoSystem.IsSelf()
  log(bWriteLog and "RoleInfoSegmentUI:UpdateShowinfoReddot bSelf = " .. tostring(bSelf))
  if not bSelf then
    self:SetWidgetVisible(self.UIRoot.Image_63, false, false)
    return
  end
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  local spData = RoleInfoMainSystem.GetSuperData()
  local settingRed = spData.settingRed
  log(bWriteLog and "RoleInfoSegmentUI:UpdateShowinfoReddot settingRed = " .. tostring(settingRed))
  local level_unlock_util = require("client.logic.level_unlock.util.level_unlock_util")
  local bHaveLockedFeature = level_unlock_util:HaveLockedFeature()
  log(bWriteLog and "RoleInfoSegmentUI:UpdateShowinfoReddot bHaveLockedFeature = " .. tostring(bHaveLockedFeature))
  if bHaveLockedFeature then
    self:SetWidgetVisible(self.UIRoot.Image_63, settingRed, false)
  else
    local levelTaskRed = spData.levelTaskRed
    log(bWriteLog and "RoleInfoSegmentUI:UpdateShowinfoReddot levelTaskRed = " .. tostring(levelTaskRed))
    self:SetWidgetVisible(self.UIRoot.Image_63, settingRed or levelTaskRed, false)
  end
end
function RoleInfoSegmentUI:UpdateLevelAwardReddot()
  log(bWriteLog and "RoleInfoSegmentUI:UpdateLevelAwardReddot")
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local bSelf = RoleInfoSystem.IsSelf()
  log(bWriteLog and "RoleInfoSegmentUI:UpdateLevelAwardReddot bSelf = " .. tostring(bSelf))
  if not bSelf then
    self:SetWidgetVisible(self.UIRoot.Image_63, false, false)
    self:SetWidgetVisible(self.UIRoot.Reddot_Anchor_Item_level, false, false)
    return
  end
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  local spData = RoleInfoMainSystem.GetSuperData()
  local levelTaskRed = spData.levelTaskRed
  log(bWriteLog and "RoleInfoSegmentUI:UpdateLevelAwardReddot levelTaskRed = " .. tostring(levelTaskRed))
  local level_unlock_util = require("client.logic.level_unlock.util.level_unlock_util")
  local bHaveLockedFeature = level_unlock_util:HaveLockedFeature()
  log(bWriteLog and "RoleInfoSegmentUI:UpdateLevelAwardReddot bHaveLockedFeature = " .. tostring(bHaveLockedFeature))
  if bHaveLockedFeature then
    self:SetWidgetVisible(self.UIRoot.Reddot_Anchor_Item_level, levelTaskRed, false)
  else
    self:SetWidgetVisible(self.UIRoot.Reddot_Anchor_Item_level, false, false)
    local settingRed = spData.settingRed
    log(bWriteLog and "RoleInfoSegmentUI:UpdateLevelAwardReddot settingRed = " .. tostring(settingRed))
    self:SetWidgetVisible(self.UIRoot.Image_63, settingRed or levelTaskRed)
  end
end
function RoleInfoSegmentUI:UpdateRoleInfo()
  self:UpdateProfile()
  self:UpdateCorpsSummary()
  self:RefreshAceImprintAndIntegral()
  self:RefreshMatchData()
  self:UpdatePlayerData()
  self:UpdateSegmentInfo()
end
function RoleInfoSegmentUI:UpdateInteractRecordEntrance()
  local LogicFriend = require("client.slua.logic.friend.logic_new_friend")
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local isFriend = LogicFriend.IsMyFriend(tonumber(RoleInfoSystem.CurShowPlayerInfoUid))
  local bVisible = isFriend and LobbySystem.CheckLobbyMenuOpen(BP_ENUM_MODULE_FRIEND_INTERACT_RECORD)
  self:SetWidgetVisible(self.UIRoot.Button_InteractRecord, bVisible, true)
  self:SetWidgetVisible(self.UIRoot.Image_InteractRecordLine, false, true)
end
function RoleInfoSegmentUI:UpdatePHomeDoorPlate()
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  if not self.Lobby_Home_Door_Entrance_UIBP then
    local componentClass = require("client.slua.umg.lobby.Left.Lobby_Home_Door_Entrance_UIBP")
    self.Lobby_Home_Door_Entrance_UIBP = componentClass(tonumber(RoleInfoSystem.CurShowPlayerInfoUid))
    self.Lobby_Home_Door_Entrance_UIBP:InitWithParentWidget(self, self.UIRoot.Lobby_Home_Door_Entrance_UIBP)
  else
    self.Lobby_Home_Door_Entrance_UIBP:UpdateUI(tonumber(RoleInfoSystem.CurShowPlayerInfoUid))
  end
end
function RoleInfoSegmentUI:UpdateCarteFrame()
  local LobbySocialSystem = require("client.slua.logic.lobby.Left.logic_lobby_social")
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local profile = LobbySocialSystem.GetProfileByUID(RoleInfoSystem.CurShowPlayerInfoUid)
  if not profile then
    return
  end
  local logic_social_card = require("client.slua.logic.lobby.Left.logic_social_card")
  local carte_frame_equip_id = logic_social_card.GetCarteFrameEquipIdByProfile(profile)
  self.isShowSkin = false
  log_format("RoleInfoSegmentUI:UpdateCardSkin. GetCarteFrameEquipIdByProfile=%s", carte_frame_equip_id)
  if carte_frame_equip_id then
    local logic_roleinfo_carte_frame = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_roleinfo_carte_frame)
    local _, _, roleinfo_bp_path, bLoopAnim = logic_roleinfo_carte_frame:GetSkinPath(carte_frame_equip_id, true)
    log_format("RoleInfoSegmentUI:UpdateCardSkin. UpdateCarteFrame=%s", roleinfo_bp_path)
    local downloadParentPanel = self.UIRoot.CanvasPanel_Download or self.UIRoot.BG_Effect
    self:LoadCarteBGEffect(roleinfo_bp_path, bLoopAnim, downloadParentPanel)
  else
    self.UIRoot.WidgetSwitcher_BG:SetActiveWidgetIndex(0)
  end
  self:ChangeTextColorBySkin()
end
function RoleInfoSegmentUI:LoadCarteBGEffect(roleinfo_bp_path, bLoopAnim, downloadParentPanel)
  if not roleinfo_bp_path or roleinfo_bp_path == "" then
    self:ClearCarteSkin()
    self.UIRoot.WidgetSwitcher_BG:SetActiveWidgetIndex(0)
    self.isShowSkin = false
    return
  end
  local PublishRegionMacros = require("client.slua.config.ClientMacros.PublishRegionMacros")
  local bIsFITVersion = PublishRegionMacros.IsFITVersion()
  local pak_util = require("client.common.pak_util")
  if not pak_util.IsFileExist(roleinfo_bp_path) then
    if bIsFITVersion then
      self:ClearCarteSkin()
      self.UIRoot.WidgetSwitcher_BG:SetActiveWidgetIndex(0)
      self.isShowSkin = false
      log_format("RoleInfoSegmentUI:UpdateCardSkin. downloadParentPanel=%s", roleinfo_bp_path)
      if not downloadParentPanel then
        return
      end
      log_format("RoleInfoSegmentUI:UpdateCardSkin. downloadParentPanel1=%s", roleinfo_bp_path)
      local PufferConst = require("client.slua.logic.download.puffer_const")
      local common_download_handler = require("client.slua.common.common_download_handler")
      common_download_handler.CreateDownloadUI(PufferConst.ENUM_DownloadType.ODPAK, {roleinfo_bp_path}, downloadParentPanel, {
        callback = function()
          if not slua.isValid(self.UIRoot) then
            return
          end
          self:UpdateCarteFrame()
        end,
        hideMask = true
      })
    else
      self:ClearCarteSkin()
      self.UIRoot.WidgetSwitcher_BG:SetActiveWidgetIndex(0)
      self.isShowSkin = false
      local PufferConst = require("client.slua.logic.download.puffer_const")
      local PufferManager = require("client.slua.logic.download.puffer.puffer_manager")
      local PufferTlog = require("client.slua.logic.download.report.puffer_tlog")
      PufferManager.Download(PufferConst.ENUM_DownloadType.ODPAK, {roleinfo_bp_path}, PufferTlog.Enum_TLog_From.Auto, function()
        if not slua.isValid(self.UIRoot) then
          return
        end
        self:UpdateCarteFrame()
      end, PufferManager.DefaultAutoDownloadParam)
    end
    return
  end
  self:ClearCarteSkin()
  self.UIRoot.WidgetSwitcher_BG:SetActiveWidgetIndex(1)
  local uiConfig = UIManager.UI_Config.Lobby_RoleInfo_EffectSkin_Item_UIBP
  local aniName
  if bLoopAnim then
    aniName = "Auto_Loop"
  end
  local logic_roleinfo_carte_frame = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_roleinfo_carte_frame)
  local extraData = {}
  local item_data = logic_roleinfo_carte_frame:GetCurrentCrateFrameBGCfg()
  if not item_data or item_data.Level == 1 then
  end
  if item_data and item_data.Level == 3 then
    extraData.bEnableGyroscope = true
  end
  self.card_skin_bp = self:CreateChildWindowWithBpPath("BG_Effect", uiConfig, roleinfo_bp_path, aniName, extraData)
  self.isShowSkin = true
end
function RoleInfoSegmentUI:UpdateProfileFrame()
  local logic_profileframe = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_roleInfo_profileframe)
  if not logic_profileframe:IsFeatureOpen() then
    self:SetWidgetVisible(self.UIRoot.FrameRoot, false)
    return
  end
  local LobbySocialSystem = require("client.slua.logic.lobby.Left.logic_lobby_social")
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local profile = LobbySocialSystem.GetProfileByUID(RoleInfoSystem.CurShowPlayerInfoUid)
  if not profile then
    return
  end
  local DefaultFrame = 62310001
  local frame_id = profile.profile_frame
  if RoleInfoSystem.IsSelf() and logic_profileframe.bDataReady then
    frame_id = logic_profileframe:GetCurrentEquipID()
  end
  if not frame_id or frame_id == DefaultFrame then
    self:SetWidgetVisible(self.UIRoot.FrameRoot, false)
    return
  end
  local _, personnalInfoFrameUMG, _, bLoopAnim = logic_profileframe:GetSkinPath(frame_id)
  if personnalInfoFrameUMG and personnalInfoFrameUMG ~= "" then
    local pak_util = require("client.common.pak_util")
    if pak_util.IsFileExist(personnalInfoFrameUMG) then
      local uiConfig = UIManager.UI_Config.Lobby_RoleInfo_EffectSkin_Item_UIBP
      local anim = bLoopAnim and "Auto_Loop"
      local extraData = {}
      if not self.profile_frame_bp then
        self.profile_frame_bp = self:CreateChildWindowWithBpPath("FrameRoot", uiConfig, personnalInfoFrameUMG, anim, extraData)
      end
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
function RoleInfoSegmentUI:UpdateNicknameFrame(nicknameFrameID)
  if self.bPlayNameAni then
    return
  end
  local clearFunc = function()
    if self.nicknameFrame then
      self.nicknameFrame:Close()
      self.nicknameFrame = nil
    end
  end
  clearFunc()
  local info = CDataTable.GetTableData("NicknameEffectCfg", nicknameFrameID)
  if not info then
    return
  end
  local nicknameFrameBPPath = info.BPPath
  if not nicknameFrameBPPath or nicknameFrameBPPath == "" then
    return
  end
  self.bPlayNameAni = true
  local uiConfig = UIManager.UI_Config.Lobby_RoleInfo_EffectSkin_Item_UIBP
  local extraData = {
    bPlayOnce = true,
    finishAniCallback = function()
      clearFunc()
    end
  }
  local doCreate = function()
    self.nicknameFrame = self:CreateChildWindowWithBpPath("SizeBox_NicknameFrame", uiConfig, nicknameFrameBPPath, "Anim_In", extraData)
  end
  local pak_util = require("client.common.pak_util")
  if pak_util.IsPufferDownloaded(nicknameFrameBPPath) then
    doCreate()
    return
  end
  log(bWriteLog and string.format("RoleInfoSegmentUI:UpdateNicknameFrame streaming download, id=%s, path=%s", tostring(nicknameFrameID), tostring(nicknameFrameBPPath)))
  pak_util.CheckAndDownloadWithCallback(nicknameFrameBPPath, function()
    if not pak_util.IsPufferDownloaded(nicknameFrameBPPath) then
      return
    end
    doCreate()
  end)
end
function RoleInfoSegmentUI:UpdateCollectTitle(profile, uid)
  local collect_module = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.collect_module)
  local collectTitle = self.UIRoot.Common_Collect_Level_HugeShow_UIBP
  if not profile.collect_data or not next(profile.collect_data) then
    log(bWriteLog and string.format("RoleInfoSegmentUI:UpdateProfile players are still in the old version. uid = %s", uid))
    collectTitle:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
    return
  end
  local privacy = profile.collect_data.privacy or {}
  local collect_privacy_module = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.collect_privacy_module)
  if not collect_privacy_module:CanShowCollectLevel(privacy) then
    log(bWriteLog and string.format("RoleInfoSegmentUI:UpdateProfile privacy switch is not turned on. uid = %s", uid))
    collectTitle:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
    return
  end
  local total_score, season_score = collect_module:GetCollectScoreByProfile(profile)
  local curLevel, desc, dan = collect_module:GetLevelDataByScore(total_score)
  local sLevel = collect_module:GetSeasonLevelByScore(season_score)
  local collect_badge_module = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.collect_badge_module)
  local light = collect_badge_module:CheckBadgeActivation(sLevel, uid)
  log(bWriteLog and string.format("RoleInfoSegmentUI:UpdateCollectTitle desc = %s", desc))
  collectTitle.WidgetSwitcher_0:SetActiveWidgetIndex(light and 0 or 1)
  collectTitle.TextBlock_ON:SetText(desc)
  collectTitle.TextBlock_OFF:SetText(desc)
  local collect_cfg = require("GameLua.Mod.Lobby.Base.Collect.logic.collect_cfg")
  local extendParam = {
    seasonLevel = sLevel,
    rank = dan,
    totalLevel = curLevel,
    halo = light
  }
  if self.dontCollectAnim then
    extendParam.animationType = collect_cfg.E_CollectBadge_AnimaType.None
  end
  collectTitle.Collect_Level_Item_UIBP:InitExquisiteCollectBadge(uid, extendParam)
  collectTitle:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
  if not self.dontCollectAnim then
    self.dontCollectAnim = true
  end
end
function RoleInfoSegmentUI:UpdateProfile()
  local LobbySocialSystem = require("client.slua.logic.lobby.Left.logic_lobby_social")
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local uid = RoleInfoSystem.CurShowPlayerInfoUid
  local profile = LobbySocialSystem.GetProfileByUID(uid)
  log_tree(bWriteLog and "RoleInfoSegmentUI:UpdateProfile : ", profile)
  if not profile then
    log(bWriteLog and "RoleInfoSegmentUI:UpdateProfile profile info is nil with uid " .. tostring(uid))
    return
  end
  self.UIRoot.Common_Avatar_BP:InitView(1, uid, profile.picUrl, profile.sex, profile.cur_avatar_box_id, profile.level, false, "")
  self.UIRoot.Common_Avatar_BP:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
  if not RoleInfoSystem.IsSelf() then
    self.UIRoot.Common_Avatar_BP:SetWidgetVisibility(UEnums.ESlateVisibility.HitTestInvisible)
  end
  self.PeakGame_RankIntegralLevel_Small_Switch_UIBP:SetSegmentBySegmentType(uid)
  local UIUtil = require("client.common.ui_util")
  UIUtil.UpdateNationImage(self.UIRoot.Image_Flag, profile.nation)
  self.UIRoot.TextBlock_PlayerName:SetText(profile.nickName or "")
  local NicknameColorManager = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.NicknameColorManager)
  self.UIRoot.TextBlock_PlayerName:SetColorAndOpacity(NicknameColorManager:GetColorByUID(profile.uid, ENUM_NAME_COLOR_UI_TYPE.RoleInfo))
  self:HaveNameColor(profile)
  self.UIRoot.TextBlock_PlayerID:SetText(RoleInfoSystem.CurShowPlayerInfoUid or "")
  if profile.social_card and self.UIRoot.Common_Gender_UIBP then
    self.UIRoot.Common_Gender_UIBP:LoadIcon(RoleInfoSystem.CurShowPlayerInfoUid)
  end
  self.UIRoot.Common_LightBoard_UIBP:ShowLightBoard(uid, self.UIRoot.CanvasPanel_Family)
  self.UIRoot.Common_Certification_UIBP:SetAuthInfo(profile.auth_type, profile.auth_end_time)
  self:UpdateCarteFrame()
  self:UpdateProfileFrame()
  if self.UIRoot.Pround_Level_Icon_UIBP then
    self.UIRoot.Pround_Level_Icon_UIBP:SetData(RoleInfoSystem.CurShowPlayerInfoUid)
  end
  local UnknowPassUtil = require("client.slua.logic.unknow_pass.logic_unknowpass_util")
  local upass_is_buy, upass_is_show, upass_keep_buy, upass_cur_value, pass_type = UnknowPassUtil.ParseUpassInfo(profile.upass)
  self.UIRoot.UnknowPass_ContinuousBuy_BP:SetTypeData(0, upass_keep_buy, upass_is_buy == 1, 1, upass_cur_value, pass_type or 0)
  self.UIRoot.PassBig:SetWidgetVisibility(UIUtil.BoolToVisible(upass_is_show ~= 0))
  self.UIRoot.TextBlock_upass_level:SetText(profile.upass.level or 1)
  self.UIRoot.Text_Upvote:SetText(profile.upvote or 0)
  self:UpdateEvaluationEntrance()
  self:SetWidgetVisible(self.UIRoot.CanvasPanel_82, not RoleInfoSystem.IsSelf(), true)
  self:SetWidgetVisible(self.UIRoot.Image_line1, false, false)
  local ZoneSystem = require("client.slua.logic.teamup.logic_zone")
  local zoneID = ZoneSystem.nChooseZoneID
  local bShow = RoleInfoSystem.IsSelf() and tonumber(zoneID) ~= 0
  local PublishRegionMacros = require("client.slua.config.ClientMacros.PublishRegionMacros")
  if PublishRegionMacros.IsBlueholeFamily() then
    self:SetWidgetVisible(self.UIRoot.Image_43, false)
  else
  end
  if bShow then
    local logic_multiple_area = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_multiple_area)
    self.UIRoot.TextBlock_Zone:SetText(logic_multiple_area:GetDisplayNameByZoneID(zoneID))
  end
  self:UpdateNicknameFrame(profile.friend_nickname_skin)
  self:UpdateCollectTitle(profile, uid)
  self:RefreshLevel(profile)
  self:RefreshUIByLevel(profile)
  self:SetWowPass(self.UIRoot, profile)
  self:ChangeTextColorBySkin()
end
function RoleInfoSegmentUI:ClearCarteSkin()
  if self.card_skin_bp then
    self.card_skin_bp:Close()
    self.card_skin_bp = nil
  end
end
function RoleInfoSegmentUI:UpdateEvaluationEntrance()
  self:SetWidgetVisible(self.UIRoot.CanvasPanel_Score, false, false)
end
function RoleInfoSegmentUI:UpdateCorpsSummary()
  local LobbySocialSystem = require("client.slua.logic.lobby.Left.logic_lobby_social")
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local profile = LobbySocialSystem.GetProfileByUID(RoleInfoSystem.CurShowPlayerInfoUid)
  if not profile then
    return
  end
  local corps_summary = LobbySocialSystem.CacheCorpsSummary[profile.corps_id] or {}
  if RoleInfoSystem.IsSelf() then
    self.UIRoot.Button_corpsAlias:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
  else
    self.UIRoot.Button_corpsAlias:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  end
  self.UIRoot.WidgetSwitcher_6:SetActiveWidgetIndex(0)
  self.UIRoot.WidgetSwitcher_5:SetActiveWidgetIndex(0)
  self.UIRoot.Button_3:SetIsEnabled(true)
  self.UIRoot.WidgetSwitcher_7:SetActiveWidgetIndex(0)
  self.UIRoot.Button_Invite11:SetIsEnabled(true)
  self.UIRoot.Button_Join11:SetIsEnabled(true)
  if profile.corps_id == 0 or profile.corps_id == nil then
    self.UIRoot.Image_CropsLogo:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
    self.UIRoot.WidgetSwitcher_4:SetActiveWidgetIndex(1)
    if RoleInfoSystem.IsSelf() then
      self.UIRoot.WidgetSwitcher_7:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
      self.UIRoot.WidgetSwitcher_7:SetActiveWidgetIndex(1)
    elseif DataMgr.corpsInfo.id ~= 0 then
      if LobbySocialSystem.HasInvited(RoleInfoSystem.CurShowPlayerInfoUid) then
        self.UIRoot.WidgetSwitcher_7:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
        self.UIRoot.WidgetSwitcher_7:SetActiveWidgetIndex(2)
      else
        self.UIRoot.WidgetSwitcher_7:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
        self.UIRoot.WidgetSwitcher_7:SetActiveWidgetIndex(0)
      end
    else
      self.UIRoot.WidgetSwitcher_7:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
    end
  else
    self.UIRoot.Image_CropsLogo:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    self.UIRoot.WidgetSwitcher_4:SetActiveWidgetIndex(0)
    self.UIRoot.TextBlock_CorpsName:SetText(corps_summary.name or "")
    local cfg = CDataTable.GetTableData("corps_alias_table", profile.corp_alias_id)
    if cfg and cfg.Default == 1 then
      self.UIRoot.WidgetSwitcher_5:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
      self.UIRoot.WidgetSwitcher_21:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
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
    else
      self.UIRoot.WidgetSwitcher_5:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
      self.UIRoot.WidgetSwitcher_21:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
      if cfg then
        self.UIRoot["aliasName" .. cfg.background]:SetText(cfg.CorpAliasName)
        self.UIRoot.WidgetSwitcher_21:SetActiveWidgetIndex(cfg.background - 1)
      end
    end
    local icon_path = "/Game/UMG/Texture/Atlas/LobbyPlayerInfoUI/Frames/Players_icon_xiangqing_png"
    if corps_summary.icon ~= nil and 0 < corps_summary.icon then
      local corpIDConf = CDataTable.GetTableData("CorpsBadge", tonumber(corps_summary.icon))
      if corpIDConf ~= nil then
        icon_path = corpIDConf.IconPath
      end
    end
    self:SetTexture(self.UIRoot.Image_CropsLogo, icon_path)
    if RoleInfoSystem.IsSelf() then
      self.UIRoot.WidgetSwitcher_6:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
    elseif DataMgr.corpsInfo.id ~= 0 then
      self.UIRoot.WidgetSwitcher_6:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
    else
      self.UIRoot.WidgetSwitcher_6:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
      if LobbySocialSystem.HasApplyed(profile.corps_id) then
        self.UIRoot.WidgetSwitcher_6:SetActiveWidgetIndex(1)
      else
        self.UIRoot.WidgetSwitcher_6:SetActiveWidgetIndex(0)
      end
    end
  end
  self:SetWidgetVisible(self.UIRoot.corpsAlias_redPoint, profile.corps_id ~= 0 and DataMgr.roleData.corps_alias_data.red_point ~= 0 and RoleInfoSystem.IsSelf())
end
function RoleInfoSegmentUI:RefreshAceImprintAndIntegral()
  local LobbySocialSystem = require("client.slua.logic.lobby.Left.logic_lobby_social")
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local profile = LobbySocialSystem.GetProfileByUID(RoleInfoSystem.CurShowPlayerInfoUid)
  if not profile then
    return
  end
  self:RefreshAceImprint()
end
function RoleInfoSegmentUI:RefreshAceImprint()
  log(bWriteLog and "RoleInfoSegmentUI:RefreshAceImprint")
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local bSelf = RoleInfoSystem.IsSelf()
  log(bWriteLog and "RoleInfoSegmentUI:RefreshAceImprint bSelf = " .. tostring(bSelf))
  local ace_config = require("client.slua.umg.ace_imprint.config.ace_config")
  self:SetCurShowAceBp(false)
  if bSelf then
    local ace_show_type = LobbySystem.roleData.ace_show_type
    log(bWriteLog and "RoleInfoSegmentUI:RefreshAceImprint ace_show_type = " .. tostring(ace_show_type))
    if ace_show_type and ace_show_type == ace_config.EAceShowType.PeakGame then
      self:RefreshPeakGameAce()
    elseif ace_show_type and ace_show_type == ace_config.EAceShowType.Honer then
      self:RefreshHonerGameAce()
    else
      self:SpecialImprintPorcess(ace_show_type)
    end
  else
    local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
    local profile = logic_profile:GetLocalProfile(RoleInfoSystem.CurShowPlayerInfoUid)
    if profile then
      local ace_show_type = profile.ace_show_type
      if ace_show_type and ace_show_type == ace_config.EAceShowType.PeakGame then
        self:RefreshPeakGameAce()
      elseif ace_show_type and ace_show_type == ace_config.EAceShowType.Honer then
        self:RefreshHonerGameAce()
      else
        self:SpecialImprintPorcess(ace_show_type)
      end
    end
  end
end
function RoleInfoSegmentUI:RefreshClassicAce()
  log(bWriteLog and "RoleInfoSegmentUI:RefreshClassicAce")
  local LobbySocialSystem = require("client.slua.logic.lobby.Left.logic_lobby_social")
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local ace_imprint_show_id, ace_imprint_base_id, ace_imprint_show_cnt = LobbySocialSystem.GetAceImprintShowId(RoleInfoSystem.CurShowPlayerInfoUid)
  log(bWriteLog and "UpdateAceImprintAndIntegral ace_imprint_show_id:" .. tostring(ace_imprint_show_id))
  if ace_imprint_show_id then
    self:SetWidgetVisible(self.UIRoot.Image_69, false, false)
    local AceImprintLogic = require("client.logic.season.AceImprintLogic")
    AceImprintLogic.SetAceImprintImage(self.UIRoot.Common_KingMark_UIBP_C_0, ace_imprint_show_id, ace_imprint_base_id, ace_imprint_show_cnt)
  else
    self:SetWidgetVisible(self.UIRoot.Common_KingMark_UIBP_C_0, false, false)
    self:SetTexture(self.UIRoot.Image_69, "/Game/Arts/UI/TableIcons/KingMark/iCON_KingMark_Not.iCON_KingMark_Not")
    self:SetWidgetVisible(self.UIRoot.Image_69, true, false)
  end
end
function RoleInfoSegmentUI:RefreshPeakGameAce()
  log(bWriteLog and "RoleInfoSegmentUI:RefreshPeakGameAce")
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local ace_util = require("client.logic.season.ace.ace_util")
  local peakgame_ace_id, peakgame_ace_count = ace_util.GetPeakGameAceData(RoleInfoSystem.CurShowPlayerInfoUid)
  if peakgame_ace_id and 0 < peakgame_ace_count then
    self:SetWidgetVisible(self.UIRoot.Image_69, false, false)
    ace_util.SetPeakGameAceImage(self.UIRoot.Common_KingMark_UIBP_C_0, peakgame_ace_id, peakgame_ace_count)
  else
    self:SetWidgetVisible(self.UIRoot.Common_KingMark_UIBP_C_0, false, false)
    self:SetTexture(self.UIRoot.Image_69, "/Game/Arts/UI/TableIcons/KingMark/iCON_KingMark_Not.iCON_KingMark_Not")
    self:SetWidgetVisible(self.UIRoot.Image_69, true, false)
  end
end
function RoleInfoSegmentUI:RefreshHonerGameAce()
  local season_year_util = require("client.logic.season_year.util.season_year_util")
  log(bWriteLog and "RoleInfoSegmentUI:RefreshHonerGameAce")
  local LobbySocialSystem = require("client.slua.logic.lobby.Left.logic_lobby_social")
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local ace_imprint_show_id, ace_imprint_base_id, ace_imprint_show_cnt = LobbySocialSystem.GetAceImprintShowId(RoleInfoSystem.CurShowPlayerInfoUid)
  log(bWriteLog and "RefreshHonerGameAce ace_imprint_show_id:" .. tostring(ace_imprint_show_id))
  if not season_year_util.CheckFunctionIsOpen() then
    self:SetWidgetVisible(self.UIRoot.Common_KingMark_UIBP_C_0, false, false)
    self:SetTexture(self.UIRoot.Image_69, "/Game/Arts/UI/TableIcons/KingMark/iCON_KingMark_Not.iCON_KingMark_Not")
    self:SetWidgetVisible(self.UIRoot.Image_69, true, false)
    return
  end
  if ace_imprint_show_id then
    if not self.Common_KingMark_UIBP_2 and self.UIRoot.CanvasPanel_ace then
      self.Common_KingMark_UIBP_2 = self:CreateChildWindow(self.UIRoot.CanvasPanel_ace, UIManager.UI_Config.Common_KingMark_UIBP_2)
    end
    if self.Common_KingMark_UIBP_2 then
      self:SetWidgetVisible(self.UIRoot.Image_69, false, false)
      local advance_num = 0
      local history_num = 0
      if ace_imprint_show_cnt and 0 < ace_imprint_show_cnt then
        advance_num = ace_imprint_show_id - ace_imprint_base_id
        history_num = ace_imprint_show_cnt - advance_num
      end
      self.Common_KingMark_UIBP_2:SetWidgetInfo(ace_imprint_base_id, {advance_num = advance_num, history_num = history_num})
    end
    self:SetWidgetVisible(self.UIRoot.Image_69, false, false)
    self:SetCurShowAceBp(season_year_util.CheckFunctionIsOpen())
  else
    self:SetWidgetVisible(self.UIRoot.Common_KingMark_UIBP_C_0, false, false)
    self:SetTexture(self.UIRoot.Image_69, "/Game/Arts/UI/TableIcons/KingMark/iCON_KingMark_Not.iCON_KingMark_Not")
    self:SetWidgetVisible(self.UIRoot.Image_69, true, false)
  end
end
function RoleInfoSegmentUI:SetCurShowAceBp(bIsNew)
  if self.Common_KingMark_UIBP_2 then
    if not bIsNew then
      self.Common_KingMark_UIBP_2:Hide()
    else
      self.Common_KingMark_UIBP_2:Show()
    end
  end
  self:SetWidgetVisible(self.UIRoot.Common_KingMark_UIBP_C_0, not bIsNew)
end
function RoleInfoSegmentUI:SpecialImprintPorcess(ace_show_type)
  if ace_show_type == nil then
    local LobbySocialSystem = require("client.slua.logic.lobby.Left.logic_lobby_social")
    local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
    local ace_imprint_show_id, ace_imprint_base_id, ace_imprint_show_cnt = LobbySocialSystem.GetAceImprintShowId(RoleInfoSystem.CurShowPlayerInfoUid)
    if ace_imprint_base_id then
      local ace_util = require("client.logic.season.ace.ace_util")
      if ace_util.IsHonerImprint(ace_imprint_base_id) then
        self:RefreshHonerGameAce()
      else
        self:RefreshClassicAce()
      end
    else
      self:RefreshClassicAce()
    end
  else
    self:RefreshClassicAce()
  end
end
function RoleInfoSegmentUI:RefreshMatchData()
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  if RoleInfoSystem.CareerCombatTotalInfoList[4] then
    self.UIRoot.MatchNum:SetText(RoleInfoSystem.CareerCombatTotalInfoList[4].role_allmatchnum or 0)
    self.UIRoot.WinNum:SetText(RoleInfoSystem.CareerCombatTotalInfoList[4].role_winnum or 0)
    self.UIRoot.Top10Num:SetText(RoleInfoSystem.CareerCombatTotalInfoList[4].role_toptennum or 0)
    self.UIRoot.Kd:SetText(RoleInfoSystem.CareerCombatTotalInfoList[4].role_kd_v2 or 0)
  end
end
function RoleInfoSegmentUI:OnGetSelfRoleInfoCallBack(list)
  log(bWriteLog and "RoleInfoSegmentUI.OnGetSelfRoleInfoCallBack")
  if not list or not list[1] then
    return
  end
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  if tonumber(RoleInfoSystem.CurShowPlayerInfoUid) ~= tonumber(list[1].uid) then
    return
  end
  local root = self.UIRoot
  if not root then
    return
  end
  local historyRanks = list[1].history_max_segment_level or {C_DefaultSegment}
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  local historyHigestRank, historySeasonId = RoleInfoMainSystem.GetHistotyMaxSegmentAndSeasonId(historyRanks, list[1].history_max_segment_season_id)
  root.Common_RankIntegralLevel_Style_Large_UIBP_C_2:SetRankInteralBySeason(historyHigestRank or C_DefaultSegment, nil, historySeasonId)
  self:UpdateSegmentInfo()
  self:SetWidgetVisible(root.Image_Tourist, RoleInfoSystem.IsSelf())
  self:SetWidgetVisible(root.Button_Tourist, RoleInfoSystem.IsSelf(), true)
  log(bWriteLog and "profile.account_type:" .. tostring(list[1].account_type))
  local account_type = list[1].account_type or 0
  self:SetWidgetVisible(root.CanvasPanel_Tourist, account_type == 5)
  local logic_roleInfo_background = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_roleInfo_background)
  logic_roleInfo_background:UpdatePlayerEquipBGLevel(RoleInfoSystem.CurShowPlayerInfoUid)
  if RoleInfoSystem.IsSelf() then
    log(bWriteLog and "RoleInfoSegmentUI:RefreshWeaponStrengthAlis isself")
    return
  end
  local info = list[1].show_weapon_alias_info
  self:UpdateWeaponStrengthAlis(list[1].show_weapon_alias_info)
end
function RoleInfoSegmentUI:UpdatePlayerData()
  local TimeUtil = require("client.common.time_util")
  local currTime = TimeUtil.GetServerTimeInSec()
  local LobbySocialSystem = require("client.slua.logic.lobby.Left.logic_lobby_social")
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local profile = LobbySocialSystem.GetProfileByUID(RoleInfoSystem.CurShowPlayerInfoUid)
  self:UpdateAchievement()
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  local basicInfoData = RoleInfoMainSystem.GetPersonInfo()
  local switch = RoleInfoSystem.bCanShowGameDay
  if RoleInfoSystem.IsSelf() or switch then
    if profile then
      if profile.registertime == nil or profile.registertime == 0 then
        self.UIRoot.TextBlock_45:SetText(LocUtil.GetLocalizeResStr(655))
      else
        local TimeUtil = require("client.common.time_util")
        local currTime = TimeUtil.GetServerTimeInSec()
        local time = profile.registertime
        log(bWriteLog and "UpdatePlayerData profile.registertime = " .. tostring(profile.registertime))
        log(bWriteLog and "UpdatePlayerData currTime = " .. tostring(currTime))
        local day = math.floor((currTime - time) / 86400 + 1)
        log(bWriteLog and "UpdatePlayerData day = " .. tostring(day))
        day = math.max(day, 1)
        local yearDay = self:DayToYear(day)
        log(bWriteLog and "UpdatePlayerData yearDay = " .. tostring(yearDay))
        self.UIRoot.TextBlock_45:SetText(yearDay)
      end
    else
      self.UIRoot.TextBlock_45:SetText(LocUtil.GetLocalizeResStr(655))
    end
  else
    self.UIRoot.TextBlock_45:SetText(LocUtil.GetLocalizeResStr(655))
  end
end
function RoleInfoSegmentUI:UpdateSegmentInfo()
  local ZoneSystem = require("client.slua.logic.teamup.logic_zone")
  local zoneId = ZoneSystem.nChooseZoneID
  if zoneId == 0 then
    zoneId = 1
  end
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local curTppScore = RoleInfoSystem.CurrSeasonTPPTotalScore[zoneId] or 0
  local curTppRank = RoleInfoSystem.CurrSeasonTPPTotalRank[zoneId] or LocUtil.GetLocalizeResStr(102127)
  local curFppScore = RoleInfoSystem.CurrSeasonFPPTotalScore[zoneId] or 0
  local curFppRank = RoleInfoSystem.CurrSeasonFPPTotalRank[zoneId] or LocUtil.GetLocalizeResStr(102127)
  local logic_leisure_season = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_leisure_season)
  if not logic_leisure_season:IsLeisureSeasonOpen() then
    self:SetWidgetVisible(self.UIRoot.HorizontalBox_Casual, false)
  else
    self:SetWidgetVisible(self.UIRoot.HorizontalBox_Casual, true)
    self:RefreshCasualSegment()
  end
  if curTppScore == 0 and curFppScore == 0 then
    printf("RoleInfoSegmentUI:UpdateSegmentInfo early return, curTppScore:%s, curTppRank:%s, curFppScore:%s, curFppRank:%s", tostring(curTppScore), tostring(curTppRank), tostring(curFppScore), tostring(curFppRank))
    return
  end
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  self.rankShowType = RoleInfoMainSystem.GetRankShowType()
  local playersType, segment = RoleInfoMainSystem.GetMaxSegmentInfo(self.rankShowType)
  self.UIRoot.Common_RankIntegralLevel_Style_Large_UIBP_C_1:SetRankInteral(segment or C_DefaultSegment, nil)
  local teamNum
  if playersType == ERankPlayersType.Team then
    teamNum = 4
    self:SetTexture(self.UIRoot.Image_5, "/Game/UMG/Texture/Atlas/Common_Atlas/Frames/common_icon_person_4_png.common_icon_person_4_png")
  elseif playersType == ERankPlayersType.Duo then
    teamNum = 2
    self:SetTexture(self.UIRoot.Image_5, "/Game/UMG/Texture/Atlas/Common_Atlas/Frames/common_icon_person_2_png.common_icon_person_2_png")
  elseif playersType == ERankPlayersType.Solo then
    teamNum = 1
    self:SetTexture(self.UIRoot.Image_5, "/Game/UMG/Texture/Atlas/Common_Atlas/Frames/common_icon_person_1_png.common_icon_person_1_png")
  end
  local perspective
  local playerType_TextID = self.rankShowType == ERankShowType.Tpp and 651 or 652
  if self.rankShowType == ERankShowType.Tpp then
    perspective = ENUM_PerspectiveType.TPP
    self.UIRoot.TextBlock_28:SetText(curTppScore or 0)
    self.UIRoot.TextBlock_32:SetText(curTppRank or "")
    printf("RoleInfoSegmentUI:UpdateSegmentInfo set TPP score:%s, rank:%s", tostring(curTppScore), tostring(curTppRank))
  else
    perspective = ENUM_PerspectiveType.FPP
    self.UIRoot.TextBlock_28:SetText(curFppScore or 0)
    self.UIRoot.TextBlock_32:SetText(curFppRank or "")
    printf("RoleInfoSegmentUI:UpdateSegmentInfo set FPP score:%s, rank:%s", tostring(curFppScore), tostring(curFppRank))
  end
  local LobbySocialSystem = require("client.slua.logic.lobby.Left.logic_lobby_social")
  local profile = LobbySocialSystem.GetProfileByUID(RoleInfoSystem.CurShowPlayerInfoUid)
  if profile then
    local logic_segment_title = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_segment_title)
    local roleInfoZoneID = RoleInfoMainSystem.GetShowRoleinfoOfZoneID()
    local segTitleId = logic_segment_title:GetProfileSegmentTitleIdByTeamNum(profile, roleInfoZoneID, teamNum, perspective)
    local modeName = C_ModeMap[self.rankShowType][playersType]
    if not profile.rankdata then
      log(bWriteLog and "RoleInfoSegmentUI:UpdateSegmentInfo not profile.rankdata")
      self.UIRoot.Common_RankIntegralLevel_Style_Small_UIBP_C_1:SetRankCustomColorWithSegmentTitle(segment or C_DefaultSegment, nil, self.textColor, nil, segTitleId)
      return
    else
      log(bWriteLog and "RoleInfoSegmentUI:UpdateSegmentInfo profile.rankdata is ready")
      if not profile.rankdata[roleInfoZoneID] or not profile.rankdata[roleInfoZoneID][modeName] then
        self.UIRoot.Common_RankIntegralLevel_Style_Small_UIBP_C_1:SetRankCustomColorWithSegmentTitle(segment or C_DefaultSegment, nil, self.textColor, nil, segTitleId)
      else
        local rating = profile.rankdata[roleInfoZoneID][modeName].rank_rating
        self.UIRoot.Common_RankIntegralLevel_Style_Small_UIBP_C_1:SetRankCustomColorWithSegmentTitle(segment or C_DefaultSegment, nil, self.textColor, nil, segTitleId, rating)
      end
    end
    local playersTypeStr = LocUtil.GetLocalizeResStr(100030)
    if playersType == ERankPlayersType.Solo then
      playersTypeStr = LocUtil.GetLocalizeResStr(100030)
    elseif playersType == ERankPlayersType.Duo then
      playersTypeStr = LocUtil.GetLocalizeResStr(100031)
    else
      playersTypeStr = LocUtil.GetLocalizeResStr(100032)
    end
    local rankShowTypeStr = LocUtil.GetLocalizeResStr(playerType_TextID)
    self.UIRoot.TextBlock_48:SetText(rankShowTypeStr .. "_" .. playersTypeStr)
  else
    self.UIRoot.Common_RankIntegralLevel_Style_Small_UIBP_C_1:SetRankInteral(segment or C_DefaultSegment, nil)
  end
end
function RoleInfoSegmentUI:DayToYear(day)
  if day < Year then
    if day > Month * 10 then
      return LocUtil.LocalizeResFormat(656, 11)
    else
      return LocUtil.LocalizeResFormat(656, math.ceil(day / Month))
    end
  else
    return LocUtil.LocalizeResFormat(654, math.floor(day / Year + 0.5))
  end
end
function RoleInfoSegmentUI:UpdateAchievement()
  local AchieveHandler = require("client.network.Protocol.AchieveHandler")
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local data = AchieveHandler.resSummaryTb[tonumber(RoleInfoSystem.CurShowPlayerInfoUid)]
  if data then
    self.UIRoot.TextBlock_43:SetText(data.achieve_score or 0)
  end
end
function RoleInfoSegmentUI:LoadAvatarScene()
  if self.UIRoot.Image_3 then
    self.UIRoot.Image_3:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  end
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local Lobby_camera_manager_module = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.Lobby_camera_manager_module)
  Lobby_camera_manager_module:SwitchCamera(40035)
  local logic_roleInfo_background = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_roleInfo_background)
  local callback = function()
    EventSystem:postEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_BACKGROUND_SCENE_LOADED)
  end
  logic_roleInfo_background:UpdatePlayerEquipBGLevel(RoleInfoSystem.CurShowPlayerInfoUid, callback)
end
function RoleInfoSegmentUI:ShowPlayerAvatar()
  if not self.bInit or self.bParentEnterAnimFinished then
    local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
    local nCurUId = RoleInfoSystem.CurShowPlayerInfoUid
    if self._cObj_coupleAvatarUI then
      self._cObj_coupleAvatarUI:RefreshShow(nCurUId)
    else
      self._cObj_coupleAvatarUI = self:CreateChildWindow(self.UIRoot.CanvasPanel_CoupleAvatar, UIManager.UI_Config.CoupleAvatar_UIBP, nCurUId, CoupleAvatarConfig.ESceneType.RoleInfo, self._tAvatarShowCfg, self._tCoupleUIShowCfg)
    end
  end
end
function RoleInfoSegmentUI:ShowAvatarAfterEnterAnim()
  log(bWriteLog and "RoleInfoSegmentUI:ShowAvatarAfterEnterAnim")
  self.bParentEnterAnimFinished = true
  if self:IsAsyncLoading() then
    return
  end
  self:ShowPlayerAvatar()
end
function RoleInfoSegmentUI:_IsRoleSelf()
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local curRoleId = RoleInfoSystem.CurShowPlayerInfoUid
  return curRoleId == DataMgr.roleData.uid
end
function RoleInfoSegmentUI:UnloadAvatarScene()
  local logic_roleInfo_background = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_roleInfo_background)
  logic_roleInfo_background:UnloadCurrentRoleInfoBGLevel(true)
end
function RoleInfoSegmentUI:RefreshUIByLevel(profile)
  log(bWriteLog and "RoleInfoSegmentUI:RefreshUIByLevel")
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local bSelf = RoleInfoSystem.IsSelf()
  log(bWriteLog and "RoleInfoSegmentUI:RefreshUIByLevel bSelf = " .. tostring(bSelf))
  if bSelf then
    local level_unlock_util = require("client.logic.level_unlock.util.level_unlock_util")
    local bHaveLockedFeature = level_unlock_util:HaveLockedFeature()
    log(bWriteLog and "RoleInfoSegmentUI:RefreshUIByLevel bHaveLockedFeature = " .. tostring(bHaveLockedFeature))
    if bHaveLockedFeature then
      self:SetWidgetVisible(self.UIRoot.SizeBox_Level, true, false)
      self:SetWidgetVisible(self.UIRoot.SizeBox_WeaponStrength, false, false)
      self:SetWidgetVisible(self.UIRoot.SizeBox_Collect, false, false)
    else
      self:SetWidgetVisible(self.UIRoot.SizeBox_Level, false, false)
      self:SetWidgetVisible(self.UIRoot.SizeBox_WeaponStrength, true, false)
      self:SetWidgetVisible(self.UIRoot.SizeBox_Collect, true, false)
    end
    return
  end
  local level = profile.level
  log(bWriteLog and "RoleInfoSegmentUI:RefreshUIByLevel level = " .. tostring(level))
  if level and 20 <= level then
    self:SetWidgetVisible(self.UIRoot.SizeBox_Level, false, false)
    self:SetWidgetVisible(self.UIRoot.SizeBox_Collect, true, false)
    self:SetWidgetVisible(self.UIRoot.SizeBox_WeaponStrength, true, false)
  else
    self:SetWidgetVisible(self.UIRoot.SizeBox_Level, true, false)
    self:SetWidgetVisible(self.UIRoot.SizeBox_Collect, false, false)
    self:SetWidgetVisible(self.UIRoot.SizeBox_WeaponStrength, false, false)
  end
end
function RoleInfoSegmentUI:RefreshLevel(profile)
  log(bWriteLog and "RoleInfoSegmentUI:RefreshLevel")
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  if RoleInfoSystem.IsSelf() then
    self:SetWidgetVisible(self.UIRoot.CanvasPanel_LevelAward, true, false)
  else
    self:SetWidgetVisible(self.UIRoot.CanvasPanel_LevelAward, false, false)
  end
  self.UIRoot.TextBlock_Title:SetText(LocUtil.GetLocalizeResStr(600))
  self.UIRoot.TextBlock_Award:SetText(LocUtil.GetLocalizeResStr(4328))
  local curlevel = tonumber(profile.level)
  self.UIRoot.TextBlock_Level:SetText(curlevel)
  local percent_exp = 1
  if 0 < curlevel and curlevel < 100 then
    local CorpsMgr = require("client.slua.logic.corps.corps_mgr")
    local exp = CorpsMgr.GetLevelExp(curlevel)
    percent_exp = profile.exp / exp
    local strLevel = profile.exp .. "/" .. exp
    self.UIRoot.TextBlock_Exp:SetText(strLevel)
  end
  self.UIRoot.ProgressBar_0:SetPercent(percent_exp)
  self:SetWidgetVisible(self.UIRoot.TextBlock_Exp, curlevel < 100)
end
function RoleInfoSegmentUI:OnButton_Achievement_TipClick()
  self:PlayAudio(sound_config.click)
end
function RoleInfoSegmentUI:OnClickRankButton()
  self:PlayAudio(sound_config.click)
  local tlog_report_utils = require("client.slua.config.tlog.tlog_report_utils")
  tlog_report_utils.ReportTLogEvent(TLogEventDefine.SegmentPop)
  UIManager.ShowUI(UIManager.UI_Config.RoleInfo_Rank_Popup_UIBP, self.rankShowType)
end
function RoleInfoSegmentUI:OnClickSmallIcon()
  self:PlayAudio(sound_config.click)
  local LobbySocialSystem = require("client.slua.logic.lobby.Left.logic_lobby_social")
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local profile = LobbySocialSystem.GetProfileByUID(RoleInfoSystem.CurShowPlayerInfoUid)
  if not profile then
    return
  end
  local tipsUI = UIManager.ShowUI(UIManager.UI_Config.integral_float_tips)
  tipsUI:SetTips(self.UIRoot.Button_IntegralLevel, profile.uid, 0, -10)
end
function RoleInfoSegmentUI:OnClickSwitchMode()
  self:PlayAudio(sound_config.click_v1)
  if self.currMode == ModeType.RANK then
    self.UIRoot.SelectSwitch:SetActiveWidgetIndex(ModeType.MATCH)
    self.currMode = ModeType.MATCH
  else
    self.UIRoot.SelectSwitch:SetActiveWidgetIndex(ModeType.RANK)
    self.currMode = ModeType.RANK
  end
end
function RoleInfoSegmentUI:OnButtonTourist()
  self:PlayAudio(sound_config.click_v1)
  UIManager.ShowUI(UIManager.UI_Config.AccessRestriction)
end
function RoleInfoSegmentUI:OnClickReportButton()
  self:PlayAudio(sound_config.click_v1)
  local LobbySocialSystem = require("client.slua.logic.lobby.Left.logic_lobby_social")
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local profile = LobbySocialSystem.GetProfileByUID(RoleInfoSystem.CurShowPlayerInfoUid)
  if RoleInfoSystem.CurShowPlayerInfoUid ~= tonumber(DataMgr.roleData.uid) then
    local LogicFriend = require("client.slua.logic.friend.logic_new_friend")
    if LogicFriend.IsMyFriend(RoleInfoSystem.CurShowPlayerInfoUid) then
      if profile and profile.nickName then
        self:OpenReportUI(profile)
      else
        log(bWriteLog and "RoleInfoSegmentUI:OnClickReportButton profile is invalid")
      end
    elseif self.UIRoot.GridPanel_More:GetVisibility() == UEnums.ESlateVisibility.SelfHitTestInvisible then
      self.UIRoot.GridPanel_More:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
    else
      self.UIRoot.GridPanel_More:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    end
  end
end
function RoleInfoSegmentUI:OnClickJubaoButton()
  self:PlayAudio(sound_config.click_v1)
  local LobbySocialSystem = require("client.slua.logic.lobby.Left.logic_lobby_social")
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local profile = LobbySocialSystem.GetProfileByUID(RoleInfoSystem.CurShowPlayerInfoUid)
  if profile and profile.nickName then
    self:OpenReportUI(profile)
  else
    log(bWriteLog and "RoleInfoSegmentUI:OnClickReportButton profile is invalid")
  end
  self.UIRoot.GridPanel_More:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
end
function RoleInfoSegmentUI:OpenReportUI(profile)
  local ChatMenuSystem = require("client.slua.logic.lobby_chat.logic_chat_menu")
  local chatMacro = require("client.slua.logic.lobby_chat.chat_macro")
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  local logic_chat_main = require("client.slua.logic.lobby_chat.logic_chat_main")
  local cacheReportData = logic_chat_main.GetReportCacheData()
  log(bWriteLog and string.format("RoleInfoSegmentUI:OpenReportUI, cacheReportData:%s", cacheReportData))
  if RoleInfoMainSystem.GetOpenForm() == RoleInfoMainSystem.RoleInfoOpenFromType.LobbyChat and cacheReportData and RoleInfoSystem.CurShowPlayerInfoUid == cacheReportData.Uid then
    ChatMenuSystem.on_report_req(RoleInfoSystem.CurShowPlayerInfoUid, profile.nickName, cacheReportData.ChatContent, cacheReportData.isVoice, cacheReportData.ChatType, chatMacro.CliSourceId.roleInfoSegment)
  else
    ChatMenuSystem.on_report_req(RoleInfoSystem.CurShowPlayerInfoUid, profile.nickName, " ", false, 0, chatMacro.CliSourceId.roleInfoSegment)
  end
end
function RoleInfoSegmentUI:OnClickPinbiButton()
  self:PlayAudio(sound_config.click_v1)
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  if "" == RoleInfoSystem.CurShowPlayerInfoUid then
    return
  end
  local PersonSpaceSystem = require("client.logic.personspace.logic_person_space")
  local LogicFriend = require("client.slua.logic.friend.logic_new_friend")
  local logic_friend_blacklist = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_friend_blacklist)
  if logic_friend_blacklist:IsBlacklist(RoleInfoSystem.CurShowPlayerInfoUid) then
    ShowNotice(106065)
  else
    local title = LocUtil.GetLocalizeResStr(34696)
    local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
    local data = logic_profile:GetLocalProfile(RoleInfoSystem.CurShowPlayerInfoUid)
    if data then
      do
        local msg = LocUtil.LocalizeResFormat(34697, data.nickName)
        local callback = function()
          local bSuccess = logic_friend_blacklist:proc_add_black_list_req(data.uid, logic_friend_blacklist.Enum_Add_Black_Scene.Lobby_RoleInfo_Segment)
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
        end
        local CommonMsgBoxMgr = require("client.slua.logic.common.logic_common_msg_box")
        CommonMsgBoxMgr.Show(2, title, msg, callback, nil)
      end
    end
  end
  self.UIRoot.GridPanel_More:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
end
function RoleInfoSegmentUI:OnClickCopyNameButton()
  self:PlayAudio(sound_config.click_v1)
  local LobbySocialSystem = require("client.slua.logic.lobby.Left.logic_lobby_social")
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local profile = LobbySocialSystem.GetProfileByUID(RoleInfoSystem.CurShowPlayerInfoUid)
  if profile then
    Client.ClipBoardCopy(profile.nickName)
    ShowNotice(105001)
  end
end
function RoleInfoSegmentUI:OnClickChangeProfileButton()
  self:PlayAudio(sound_config.click_v1)
  local logic_vng_personal_info = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_vng_personal_info)
  logic_vng_personal_info:OpenVNGPersonalInfoUrl(2)
end
function RoleInfoSegmentUI:OnClickHeadCallback()
  self:PlayAudio(sound_config.click_v1)
  local LobbySocialSystem = require("client.slua.logic.lobby.Left.logic_lobby_social")
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local profile = LobbySocialSystem.GetProfileByUID(RoleInfoSystem.CurShowPlayerInfoUid)
  if not profile then
    log(bWriteLog and "RoleInfoSegmentUI:OnClickHeadCallback profile is nil")
    return
  end
  local RoleInfoBigAvatarSystem = require("client.slua.logic.roleInfo.logic_roleInfo_BigAvatar")
  RoleInfoBigAvatarSystem.ShowUI(profile)
end
function RoleInfoSegmentUI:OnClickButtonShowInfo()
  self:PlayAudio(sound_config.click_v1)
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  RoleInfoMainSystem.Show(RoleInfoMainSystem.Personalize, RoleInfoMainSystem.RoleInfoOpenFromType.Lobby, RoleInfoSystem.CurShowPlayerInfoUid)
end
function RoleInfoSegmentUI:OnButtonAceImprintClick()
  self:PlayAudio(sound_config.click_v1)
  local tlog_report_utils = require("client.slua.config.tlog.tlog_report_utils")
  tlog_report_utils.ReportTLogEvent(TLogEventDefine.PersonSpaceSegmentCycleImprint)
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local AceImprintLogic = require("client.logic.season.AceImprintLogic")
  AceImprintLogic.ShowAceMarkUI(RoleInfoSystem.CurShowPlayerInfoUid)
end
function RoleInfoSegmentUI:OnClickCorpsButton()
  self:PlayAudio(sound_config.click_v1)
  local LogicFitVersionDownload = require("client.slua.logic.download.fit.logic_fitVersion_download")
  if LogicFitVersionDownload.IfNotFitLobbyResDownloadedShowWindow() then
    return
  end
  local growthprojectMgrB = require("client.slua.logic.growth_project.logic_growth_project_b")
  growthprojectMgrB.HideWeakGuide(5, 2)
  if not LobbySystem.CheckLobbyMenuOpen(BP_ENUM_LOBBY_MENU_CORPS) then
    return
  end
  local LobbySocialSystem = require("client.slua.logic.lobby.Left.logic_lobby_social")
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  if LobbySocialSystem.IsSelf(RoleInfoSystem.CurShowPlayerInfoUid) then
    local logic_corps_tab_mgr = require("client.slua.logic.corps.logic_corps_tab_mgr")
    logic_corps_tab_mgr.OpenCorpsUI()
    local tlog_report_utils = require("client.slua.config.tlog.tlog_report_utils")
    tlog_report_utils.ReportTLogEvent(TLogEventDefine.LobbyCorps)
  else
    local profile = LobbySocialSystem.GetProfileByUID(RoleInfoSystem.CurShowPlayerInfoUid)
    if profile then
      local RoleInfoCorpsSystem = require("client.slua.logic.roleInfo.logic_roleInfo_Corps")
      RoleInfoCorpsSystem.Open(profile.corps_id, self.currUID, profile.corp_alias_id)
    end
  end
end
function RoleInfoSegmentUI:OnClickApplyButton()
  self:PlayAudio(sound_config.click_v1)
  local LogicFitVersionDownload = require("client.slua.logic.download.fit.logic_fitVersion_download")
  if LogicFitVersionDownload.IfNotFitLobbyResDownloadedShowWindow() then
    return
  end
  local RoleInfoCorpsSystem = require("client.slua.logic.roleInfo.logic_roleInfo_Corps")
  RoleInfoCorpsSystem.SetCanJoin(true)
  local LobbySocialSystem = require("client.slua.logic.lobby.Left.logic_lobby_social")
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local profile = LobbySocialSystem.GetProfileByUID(RoleInfoSystem.CurShowPlayerInfoUid)
  if profile then
    RoleInfoCorpsSystem.Open(profile.corps_id, RoleInfoSystem.CurShowPlayerInfoUid, profile.corp_alias_id)
  end
end
function RoleInfoSegmentUI:OnClickInviteButton()
  self:PlayAudio(sound_config.click_v1)
  local LogicFitVersionDownload = require("client.slua.logic.download.fit.logic_fitVersion_download")
  if LogicFitVersionDownload.IfNotFitLobbyResDownloadedShowWindow() then
    return
  end
  local CorpsMemberSystem = require("client.slua.logic.corps.logic_corps_member")
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  CorpsMemberSystem.SendInviteReq(RoleInfoSystem.CurShowPlayerInfoUid, 0)
end
function RoleInfoSegmentUI:OnClickCorpsAliasButton()
  self:PlayAudio(sound_config.click_v1)
  local LogicFitVersionDownload = require("client.slua.logic.download.fit.logic_fitVersion_download")
  if LogicFitVersionDownload.IfNotFitLobbyResDownloadedShowWindow() then
    return
  end
  local RoleInfoCorpAliasSystem = require("client.slua.logic.roleInfo.logic_roleinfo_corpsalias")
  RoleInfoCorpAliasSystem.get_corps_alias_list_request()
end
function RoleInfoSegmentUI:OnClickCopyPlayerIDButton()
  self:PlayAudio(sound_config.click_v1)
  log(bWriteLog and "CopyPlayerID")
  local LobbySocialSystem = require("client.slua.logic.lobby.Left.logic_lobby_social")
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local profile = LobbySocialSystem.GetProfileByUID(RoleInfoSystem.CurShowPlayerInfoUid)
  if profile then
    Client.ClipBoardCopy(profile.uid)
    ShowNotice(105001)
  end
end
function RoleInfoSegmentUI:OnClickRPButton()
  self:PlayAudio(sound_config.click)
  local LobbySocialSystem = require("client.slua.logic.lobby.Left.logic_lobby_social")
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local profile = LobbySocialSystem.GetProfileByUID(RoleInfoSystem.CurShowPlayerInfoUid)
  if not profile then
    log(bWriteLog and "RoleInfoSegmentUI:OnClickRPButton profile is nil")
    return
  end
  if profile.upass and profile.upass.switch.record_privacy or RoleInfoSystem.IsSelf() then
    UIManager.ShowUI(UIManager.UI_Config.UnknowPass_RecordMain_UIBP, true, RoleInfoSystem.CurShowPlayerInfoUid)
    if RoleInfoSystem.IsSelf() then
      local UnknowPassMacro = require("client.slua.logic.unknow_pass.unknowpass_macro")
      DataMgr.SetNewbieGuide(DataMgr.NEWBIE_GUIDE_MODULE_ID_PASS, UnknowPassMacro.ENUM_Pass_Main_Reddot.ENUM_Pass_NewRecordGuide)
    end
  else
    ShowNotice(18256)
  end
end
function RoleInfoSegmentUI:OnClickUpvoteButton()
  self:PlayAudio(sound_config.click_v1)
  local tipsUI = UIManager.ShowUI(UIManager.UI_Config.common_float_tips)
  local TipsParam = {
    offsetX = 60,
    offsetY = 0,
    wrapWidthType = 1,
    anchors = {
      minX = 0.5,
      minY = 0,
      maxX = 0.5,
      maxY = 0
    }
  }
  tipsUI:SetTips(self.UIRoot.Button_Upvote_Tip, LocUtil.LocalizeResFormat(7230), TipsParam)
end
function RoleInfoSegmentUI:OnClickScoreActiveButton()
  self:PlayAudio(sound_config.click_v1)
  local logic_team_evaluation_view = require("client.slua.logic.team_evaluation.logic_team_evaluation_view")
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  logic_team_evaluation_view.ShowDetailedEvaluationView(RoleInfoSystem.CurShowPlayerInfoUid)
end
function RoleInfoSegmentUI:OnClickScoreNotActiveButton()
  self:PlayAudio(sound_config.click_v1)
  local logic_team_evaluation_view = require("client.slua.logic.team_evaluation.logic_team_evaluation_view")
  logic_team_evaluation_view.ShowNotEnoughEvaluationTips()
end
function RoleInfoSegmentUI:OnClickButtonSeasonRank()
  self:PlayAudio(sound_config.click)
  if not self:_IsRoleSelf() then
    return
  end
  local RankConfig = require("client.slua.logic.rank.rank_config")
  local RankSelectEnum = RankConfig.RankSelectEnum
  GlobalData.JumpUrl("game://?module=" .. BP_ENUM_MODULE_RANK .. "&to=" .. RankSelectEnum.sum)
end
function RoleInfoSegmentUI:OnClickButtonHistoryMaxText()
  if not self:_IsRoleSelf() then
    ShowNotice(42820)
    return
  end
  self:PlayAudio(sound_config.click)
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local logic_season_util = require("client.logic.season.logic_season_util")
  if logic_season_util.IsModReady() then
    UIManager.ShowUI(UIManager.UI_Config.Lobby_Season_Review_UIBP_S20, true, RoleInfoSystem.CurShowPlayerInfoUid)
  end
end
function RoleInfoSegmentUI:OnClickButtonAchieveText()
  if not self:_IsRoleSelf() then
    return
  end
  local LogicFitVersionDownload = require("client.slua.logic.download.fit.logic_fitVersion_download")
  if not LogicFitVersionDownload.IsFitLobbyResDownloaded() then
    LogicFitVersionDownload.ShowFullLobbyResDownloadPopup()
    return
  end
  self:PlayAudio(sound_config.click)
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  local roleinfo_main = UIManager.GetUI(UIManager.UI_Config.roleinfo_main)
  if roleinfo_main then
    local LobbySocialSystem = require("client.slua.logic.lobby.Left.logic_lobby_social")
    local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
    local profile = LobbySocialSystem.GetProfileByUID(RoleInfoSystem.CurShowPlayerInfoUid)
    if not profile then
      return
    end
    if profile.level >= 4 then
      RoleInfoMainSystem.ResetAchieveInfo()
      roleinfo_main:SwitchTab(RoleInfoMainSystem.Honor, 1)
      local ui = UIManager.GetUI(UIManager.UI_Config.Achievement_Task_UIBP)
      ui:OnClickTab(nil, 1)
    else
      local level_unlock_manager = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.level_unlock_manager)
      ShowNotice(level_unlock_manager:GetLockTip(level_unlock_manager.featureDef.achievement))
    end
  end
end
function RoleInfoSegmentUI:OnClickButtonCreditText()
  if not self:_IsRoleSelf() then
    return
  end
  self:PlayAudio(sound_config.click)
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  local roleinfo_main = UIManager.GetUI(UIManager.UI_Config.roleinfo_main)
  if roleinfo_main then
    log(bWriteLog and "RoleInfoSegmentUI:OnClickButtonCreditText" .. tostring(RoleInfoMainSystem.Credit))
    roleinfo_main:SwitchTab(RoleInfoMainSystem.Credit)
  end
end
function RoleInfoSegmentUI:OnButton_InteractRecordClick()
  self:PlayAudio(sound_config.click_v1)
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local logic_friend_interact_record = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_friend_interact_record)
  logic_friend_interact_record:ShowInteractRecordWithPlayer(tonumber(RoleInfoSystem.CurShowPlayerInfoUid), logic_friend_interact_record.openType.PersonSpace)
end
function RoleInfoSegmentUI:OnClickShareButton()
  log(bWriteLog and "RoleInfoSegmentUI:OnClickShareButton")
  self:PlayAudio(sound_config.click_v1)
  self:SetWidgetVisible(self.UIRoot.ShareRed, false)
  local Util = require("client.slua_ui_framework.util")
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  local tlog_report_utils = require("client.slua.config.tlog.tlog_report_utils")
  tlog_report_utils.ReportTLogEvent(TLogEventDefine.RoleInfoShare)
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local switch = LobbySystem.CheckOpen(BP_ENUM_SWITCH_ROLE_INFO_SHARE)
  if switch then
    local shareCfg = {
      sceneType = ShareSceneType.RoleInfoCard,
      campaign = "roleinfoCard",
      reasonStr = json.encode({
        uid = DataMgr.roleData.uid,
        buttonStr = "Button_QRCode"
      }),
      showFace = false,
      tabChildUiCfgs = {
        {
          text = LocUtil.GetLocalizeResStr(CDataTable.GetTableData("RoleInfoContentTable", 5).config),
          childUiCfg = UIManager.UI_Config.Lobby_RoleInfo_Card_Share_UIBP,
          childUiData = RoleInfoSystem.CurShowPlayerInfoUid,
          bottomCfg = {
            bShowSharePose = false,
            bShowPoseSelect = false,
            bShowSettingRankData = true,
            PrivacySettings = true
          }
        },
        {
          text = LocUtil.GetLocalizeResStr(CDataTable.GetTableData("RoleInfoContentTable", 6).config),
          childUiCfg = UIManager.UI_Config.ResultsRanking_Protect_Share_UIBP_2,
          childUiData = RoleInfoSystem.CurShowPlayerInfoUid,
          bottomCfg = {
            bShowSharePose = true,
            bShowPoseSelect = false,
            bShowSettingRankData = false,
            PrivacySettings = false
          }
        }
      }
    }
    Util.ShowShare(shareCfg)
  else
    local shareCfg = {
      sceneType = ShareSceneType.RoleInfoCard,
      campaign = "roleinfoCard",
      reasonStr = json.encode({
        uid = DataMgr.roleData.uid,
        buttonStr = "Button_QRCode"
      }),
      showFace = false,
      PrivacySettings = true,
      ShowSettingRankData = true
    }
    Util.ShowShare(shareCfg, UIManager.UI_Config.Lobby_RoleInfo_Card_Share_UIBP, RoleInfoSystem.CurShowPlayerInfoUid)
  end
end
function RoleInfoSegmentUI:OnClickButton_TIPS()
  self:PlayAudio(sound_config.click_v1)
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local LobbySocialSystem = require("client.slua.logic.lobby.Left.logic_lobby_social")
  local profile = LobbySocialSystem.GetProfileByUID(RoleInfoSystem.CurShowPlayerInfoUid)
  if not profile then
    log(bWriteLog and string.format("RoleInfoSegmentUI:OnClickButton_TIPS profile is nil uid = %s", RoleInfoSystem.CurShowPlayerInfoUid))
    return
  end
  local collect_module = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.collect_module)
  local collectScore, curSeasonScore = collect_module:GetCollectScoreByCollectData(profile.collect_data)
  UIManager.ShowUI(UIManager.UI_Config.Collect_Level_Medal_Tips_UIBP, self.UIRoot.Common_Collect_Level_HugeShow_UIBP.Button_TIPS, collectScore, curSeasonScore, RoleInfoSystem.CurShowPlayerInfoUid, {X = -280, Y = -50})
end
function RoleInfoSegmentUI:OnClickLockButton()
  self:PlayAudio(sound_config.click_v1)
  local QRcodeRestrictManager = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.QRcodeRestrictManager)
  QRcodeRestrictManager:ShowRestrictTips()
end
function RoleInfoSegmentUI:OnClickCasualButton()
  self:PlayAudio(sound_config.click_v1)
  log(bWriteLog and "RoleInfoSegmentUI:OnClickCasualButton")
  local season_year_util = require("client.logic.season_year.util.season_year_util")
  if season_year_util.CheckFunctionIsOpen() then
    local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
    local uid = DataMgr.roleData.uid
    if not RoleInfoSystem.IsSelf() then
      log(bWriteLog and "RoleInfoSegmentUI:OnClickCasualButton is not self")
      UIManager.ShowUI(UIManager.UI_Config.Lobby_Season_Other_Main_UIBP, RoleInfoSystem.CurShowPlayerInfoUid)
      return
    end
    local level_unlock_manager = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.level_unlock_manager)
    local unlockGuideConfigMap = level_unlock_manager:GetSystemList()
    local currentLevel = DataMgr.roleData.level
    local unlockGuideConfig = unlockGuideConfigMap[level_unlock_manager.featureDef.season]
    if unlockGuideConfig then
      local level_unlock_ui_util = require("client.logic.level_unlock.util.level_unlock_ui_util")
      local config = level_unlock_ui_util:GetGuideStepConfig(unlockGuideConfig, 1)
      local level_unlock_config = require("client.logic.level_unlock.config.level_unlock_config")
      local ELockType = level_unlock_config.ELockType
      if config and config.EntranceDisplayType == ELockType.hide then
        local requireLevel = unlockGuideConfig.unlockLevel
        if requireLevel and currentLevel < requireLevel then
          log(bWriteLog and "RoleInfoSegmentUI:OnClickCasualButton is not open")
          return
        end
      end
    end
    local logic_season_util = require("client.logic.season.logic_season_util")
    logic_season_util.CheckModWithFunc(function()
      local season_year_config = require("client.logic.season_year.config.season_year_config")
      local TabMenuIDs = season_year_config.ETabMenuIDs
      UIManager.ShowUI(UIManager.UI_Config.Lobby_Season_Main_UIBP, TabMenuIDs.Badge)
      local tlog_report_utils = require("client.slua.config.tlog.tlog_report_utils")
      local sTLogStr = "RoleInfo"
      tlog_report_utils.ReportTLogEvent(TLogEventDefine.SEASON_YEAR_SYSTEM_ENTRY_CLICK, 0, sTLogStr)
    end)
  else
    local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
    UIManager.ShowUI(UIManager.UI_Config.Lobby_RoleInfo_Leisure_Popup_UIBP, RoleInfoSystem.CurShowPlayerInfoUid)
  end
end
function RoleInfoSegmentUI:OnClickPeakHistoryMaxButton()
  self:PlayAudio(sound_config.click)
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local logic_season_util = require("client.logic.season.logic_season_util")
  if logic_season_util.IsModReady() then
    UIManager.ShowUI(UIManager.UI_Config.Lobby_Season_Review_UIBP_S20, true, RoleInfoSystem.CurShowPlayerInfoUid, 2)
  end
end
function RoleInfoSegmentUI:OnClickPeakRankButton()
  self:PlayAudio(sound_config.click)
  if not self.PeakGame then
    ShowNotice(68427)
    return
  end
  local tlog_report_utils = require("client.slua.config.tlog.tlog_report_utils")
  tlog_report_utils.ReportTLogEvent(TLogEventDefine.SegmentPop)
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local uid = DataMgr.roleData.uid
  if RoleInfoSystem.IsSelf() then
    uid = DataMgr.roleData.uid
  else
    uid = RoleInfoSystem.CurShowPlayerInfoUid
  end
  UIManager.ShowUI(UIManager.UI_Config.RoleInfo_PeakRank_Popup_UIBP, uid)
end
function RoleInfoSegmentUI:OnClicMoreButton()
  self:PlayAudio(sound_config.click_v1)
  UIManager.ShowUI(UIManager.UI_Config.Lobby_RoleInfo_PeakGame_Tips_UIBP)
end
function RoleInfoSegmentUI:OnClicSaveButton()
  self:PlayAudio(sound_config.click_v1)
  log(bWriteLog and "RoleInfoSegmentUI:OnClicSaveButton")
  self:UpdateSaveState()
end
function RoleInfoSegmentUI:UpdateSaveState()
  log(bWriteLog and "RoleInfoSegmentUI:UpdateSaveState")
  local logic_new_roleinfo = require("client.logic.roleinfo.logic_new_roleinfo")
  if not logic_new_roleinfo.GetSaveDataSwitch() then
    log(bWriteLog and "RoleInfoSegmentUI:UpdateSaveState 1")
    return
  end
  if not logic_new_roleinfo.IsMe() then
    log(bWriteLog and "RoleInfoSegmentUI:UpdateSaveState 2")
    return
  end
  logic_new_roleinfo.SaveData(self.TabID)
end
function RoleInfoSegmentUI:OnClickLevelAward()
  local LogicFitVersionDownload = require("client.slua.logic.download.fit.logic_fitVersion_download")
  if LogicFitVersionDownload.IfNotFitLobbyResDownloadedShowWindow() then
    return
  end
  local tlog_report_utils = require("client.slua.config.tlog.tlog_report_utils")
  tlog_report_utils.ReportTLogEvent(TLogEventDefine.GrowthTask)
  UIManager.ShowUI(UIManager.UI_Config.Task_LevelBP)
end
function RoleInfoSegmentUI:OnButtonHideClick()
  log(bWriteLog and "RoleInfoSegmentUI:OnButtonHideClick")
  self:PlayAudio(sound_config.click_v1)
  self.bUIShow = not self.bUIShow
  self:ShowUIExceptHideAndReplay(self.bUIShow)
  self.bButtonClick = true
end
function RoleInfoSegmentUI:OnButtonReplayClick()
  log(bWriteLog and "RoleInfoSegmentUI:OnButtonReplayClick")
  self:PlayAudio(sound_config.click_v1)
  self:PlayEffect()
  self.bButtonClick = true
end
function RoleInfoSegmentUI:OnClickWoWPass()
  self:PlayAudio(sound_config.click_v1)
  local LobbySocialSystem = require("client.slua.logic.lobby.Left.logic_lobby_social")
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local uid = RoleInfoSystem.CurShowPlayerInfoUid
  local profile = LobbySocialSystem.GetProfileByUID(uid)
  UIManager.ShowUI(UIManager.UI_Config.Lobby_RoleInfo_WoWPassPopup_UIBP, profile)
end
function RoleInfoSegmentUI:OnRefreshCreditScore(_, __, attriValue)
  if not self:_IsRoleSelf() then
    log(bWriteLog and "RoleInfoSegmentUI:OnRefreshCreditScore is not self with attriValue = " .. tostring(attriValue))
    return
  end
  log(bWriteLog and "RoleInfoSegmentUI:OnRefreshCreditScore attriValue = " .. tostring(attriValue))
  self.UIRoot.UTRichText_Credit:SetText(attriValue or 0)
end
function RoleInfoSegmentUI:OnRefreshEvaluationEntrance()
  self:UpdateEvaluationEntrance()
end
function RoleInfoSegmentUI:OnRefreshRoleInfo()
  self:UpdateRoleInfo()
end
function RoleInfoSegmentUI:OnRefreshAceImprint()
  self:RefreshAceImprint()
end
function RoleInfoSegmentUI:OnRefreshAchievement()
  self:UpdateAchievement()
end
function RoleInfoSegmentUI:OnRefreshProfile()
  self:UpdateProfile()
end
function RoleInfoSegmentUI:OnRefreshHead()
  local LobbySocialSystem = require("client.slua.logic.lobby.Left.logic_lobby_social")
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local profile = LobbySocialSystem.GetProfileByUID(RoleInfoSystem.CurShowPlayerInfoUid)
  if not profile then
    return
  end
  self.UIRoot.Common_Avatar_BP:InitView(1, profile.uid, profile.picUrl, profile.sex, profile.cur_avatar_box_id, profile.level, false, "")
end
function RoleInfoSegmentUI:OnRefreshCorpsSummary()
  self:UpdateCorpsSummary()
end
function RoleInfoSegmentUI:OnRefreshShowinfoReddot()
  log(bWriteLog and "RoleInfoSegmentUI:OnRefreshShowinfoReddot")
  self:UpdateShowinfoReddot()
end
function RoleInfoSegmentUI:OnRefreshLevelAwardReddot()
  log(bWriteLog and "RoleInfoSegmentUI:OnRefreshLevelAwardReddot")
  self:UpdateLevelAwardReddot()
end
function RoleInfoSegmentUI:OnRefreshPeakGame()
  local PeakGameConfig = require("client.logic.PeakGame.PeakGameConfig")
  if DataMgr.season_id >= PeakGameConfig.MinPeakGameSeasonId then
    self:SetWidgetVisible(self.UIRoot.Button_13, true, true)
    self:SetWidgetVisible(self.UIRoot.Button_10, true, true)
  else
    self:SetWidgetVisible(self.UIRoot.Button_10, false, false)
    self:SetWidgetVisible(self.UIRoot.Button_13, false, false)
    return
  end
  local bestSegment = 0
  local segment_id
  local PeakGameConfig = require("client.logic.PeakGame.PeakGameConfig")
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local LogicPeakGameSegmentUtil = require("client.logic.PeakGame.LogicPeakGameSegmentUtil")
  if RoleInfoSystem.IsSelf() then
    local LogicPeakGame = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicPeakGame)
    LogicPeakGame:ReqPeakGameRatingInfo()
    local LogicPeakGameSegmentUtil = require("client.logic.PeakGame.LogicPeakGameSegmentUtil")
    bestSegment = LogicPeakGameSegmentUtil.GetSelfHistoryMaxSegmentId()
    segment_id = LogicPeakGameSegmentUtil.GetSelfAllZoneCurSeasonMaxSegmentId()
  else
    local LobbySocialSystem = require("client.slua.logic.lobby.Left.logic_lobby_social")
    local uid = RoleInfoSystem.CurShowPlayerInfoUid
    local profile = LobbySocialSystem.GetProfileByUID(uid)
    segment_id = LogicPeakGameSegmentUtil.GetProfileCurMaxSegmentId(profile)
    bestSegment = LogicPeakGameSegmentUtil.GetProfileHistoryMaxSegmentId(profile)
  end
  self.UIRoot.WidgetSwitcher_9:SetActiveWidgetIndex(1)
  self.UIRoot.WidgetSwitcher_10:SetActiveWidgetIndex(1)
  if not segment_id or not LogicPeakGameUtil.IsPeakGameOpen() then
    self.UIRoot.TextBlock_50:SetText(LocUtil.GetLocalizeResStr(18774))
    self.PeakGame = false
  else
    self.PeakGame = true
    self.UIRoot.WidgetSwitcher_9:SetActiveWidgetIndex(0)
    self.PeakGame_RankIntegralLevel_Style_Large_UIBP_C_2:SetPeakRankIntegral(segment_id or PeakGameConfig.DefaultPeakGameSegment, false)
    self.PeakGame_RankIntegralLevel_Style_Small_UIBP_C_1:SetPeakRankCustomColor(segment_id or PeakGameConfig.DefaultPeakGameSegment, self.textColor)
  end
  if not bestSegment or not LogicPeakGameUtil.IsPeakGameOpen() then
    self:SetWidgetVisible(self.UIRoot.Button_10, true, false)
    self.UIRoot.TextBlock_46:SetText(LocUtil.GetLocalizeResStr(68411))
  else
    if not RoleInfoSystem.IsSelf() then
      self.UIRoot.TextBlock_46:SetText(LocUtil.GetLocalizeResStr(68411))
      self:SetWidgetVisible(self.UIRoot.Button_10, true, false)
    else
      self.UIRoot.TextBlock_46:SetText(LocUtil.GetLocalizeResStr(68418))
    end
    self.UIRoot.WidgetSwitcher_10:SetActiveWidgetIndex(0)
    self.PeakGame_RankIntegralLevel_Style_Large_UIBP_C_0:SetPeakRankIntegral(bestSegment, false)
  end
end
function RoleInfoSegmentUI:SetTextColor(color)
  local textNameList = {
    "TextBlock_5",
    "SelectText",
    "TextBlock_8",
    "TextBlock_35",
    "UnselectText",
    "TextBlock_19",
    "TextBlock_PeakGame",
    "TextBlock_37",
    "TextBlock_38",
    "TextBlock_33",
    "TextBlock_12",
    "TextBlock_Setting",
    "TextBlock_0",
    "HIstoryMaxText",
    "ArceText",
    "MatchNumText",
    "WinNumText",
    "TopTenText",
    "KDText",
    "TextBlock_27",
    "TextBlock_30",
    "TextBlock_48",
    "TextBlock_24",
    "TextBlock_50",
    "TextBlock_49",
    "TextBlock_23",
    "TextBlock_25",
    "TextBlock_46",
    "TextBlock_47",
    "RankScoreText",
    "TextBlock_TotalScore",
    "RankNoText",
    "TextBlock_TotalScoreRank",
    "CreditText",
    "UTRichText_Credit",
    "DayNumText",
    "GameNumText",
    "AchieveText",
    "TextBlock_AchievementScore",
    "TextBlock_1",
    "TextBlock_FppTotalScore",
    "TextBlock_FppTotalScoreRank",
    "TextBlock_26",
    "TextBlock_28",
    "TextBlock_29",
    "TextBlock_32",
    "TextBlock_34",
    "TextBlock_36",
    "TextBlock_39",
    "TextBlock_41",
    "TextBlock_42",
    "TextBlock_43",
    "TextBlock_44",
    "TextBlock_45",
    "TextBlock_22"
  }
  for _, textName in ipairs(textNameList) do
    self.UIRoot[textName]:SetColorAndOpacity(color)
  end
  self.textColor = color
end
function RoleInfoSegmentUI:RefreshSkin()
  local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local profile_info = logic_profile:GetLocalProfile(RoleInfoSystem.CurShowPlayerInfoUid)
  if not profile_info then
    return
  end
  self:SetTexture(self.UIRoot.Image_GB, "/Game/UMG/Texture_200/Atlas/Common_New_Atlas/Frames/Common_Image_WhiteBlock_png.Common_Image_WhiteBlock_png")
  local logic_social_card = require("client.slua.logic.lobby.Left.logic_social_card")
  local carte_frame_equip_id = 0
  if DataMgr.roleData and RoleInfoSystem.CurShowPlayerInfoUid and tonumber(RoleInfoSystem.CurShowPlayerInfoUid) == tonumber(DataMgr.roleData.uid) and logic_social_card.MySocialCard then
    carte_frame_equip_id = logic_social_card.MySocialCard.carte_frame_equip_id or logic_social_card.GetCarteFrameEquipIdByProfile(profile_info)
  else
    carte_frame_equip_id = logic_social_card.GetCarteFrameEquipIdByProfile(profile_info)
  end
  if carte_frame_equip_id then
    local SkinCfg = CDataTable.GetTableData("CarteFrameConfig", carte_frame_equip_id)
    if not SkinCfg then
      return
    end
    self:SetTextColor(FSlateColor(FLinearColor(0, 0, 0, 1)))
    if SkinCfg.DetailBottomEx and SkinCfg.DetailBottomEx ~= "" then
      do
        local pak_util = require("client.common.pak_util")
        pak_util.CheckAndDownloadWithCallback(SkinCfg.DetailBottomEx, function()
          self:SetTexture(self.UIRoot.Image_GB, SkinCfg.DetailBottomEx)
          if SkinCfg.DetailBottomColor and SkinCfg.DetailBottomColor == "1" then
            self:SetTextColor(FSlateColor(FLinearColor(1, 1, 1, 1)))
          end
        end)
      end
    end
  end
end
function RoleInfoSegmentUI:OnMouseButtonUp()
  log(bWriteLog and "RoleInfoSegmentUI:OnMouseButtonUp")
  self:AddTimerOnce(0, function()
    if self.bButtonClick == true then
      self.bButtonClick = false
      return
    end
    if self.bUIShow == false then
      self.bUIShow = true
      self:ShowUIExceptHideAndReplay(self.bUIShow)
    end
  end)
end
function RoleInfoSegmentUI:RefreshCasualSegment()
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local uid = RoleInfoSystem.CurShowPlayerInfoUid
  local leisure_season_util = require("client.slua.logic.leisure.leisure_season_util")
  local logic_leisure_season = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_leisure_season)
  local segmentID = logic_leisure_season:GetLeisureSegmentIDByUID(uid)
  if self.UIRoot.PeakGame_RankIntegralLevel_Style_Large_UIBP_C_1 then
    leisure_season_util.SetRankBigIcon(self.UIRoot.PeakGame_RankIntegralLevel_Style_Large_UIBP_C_1, segmentID)
  end
end
function RoleInfoSegmentUI:UpdateWeaponStrengthAlis(showAlisInfo)
  log(bWriteLog and "RoleInfoSegmentUI:UpdateWeaponStrengthAlis")
  log_tree("RoleInfoSegmentUI:UpdateWeaponStrengthAlis showAlisInfo", showAlisInfo)
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  if RoleInfoSystem.IsSelf() then
    log(bWriteLog and "RoleInfoSegmentUI:UpdateWeaponStrengthAlis is self")
    self:SetWidgetVisible(self.UIRoot.Season_WeaponStrength_Title_UIBP, true)
    self:SetWidgetVisible(self.UIRoot.Season_WeaponStrength_Title_UIBP.Image_SettingIcon, true)
    self:SetWidgetVisible(self.UIRoot.Season_WeaponStrength_Title_UIBP.Button_WSDetail, true, true)
    local logic_roleInfo_weaponstrength_title_select = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_roleInfo_weaponstrength_title_select)
    local selectData = logic_roleInfo_weaponstrength_title_select:GetSaveSelectAliasList_Weapon()
    self:HandleWeaponAliasDisplay(selectData)
  elseif showAlisInfo then
    self:SetWidgetVisible(self.UIRoot.Season_WeaponStrength_Title_UIBP, true)
    self:HandleWeaponAliasDisplay(showAlisInfo)
    self:SetWidgetVisible(self.UIRoot.Season_WeaponStrength_Title_UIBP.Image_SettingIcon, false)
  else
    log(bWriteLog and "RoleInfoSegmentUI:UpdateWeaponStrengthAlis is not self and not showAlisInfo")
    self:SetWidgetVisible(self.UIRoot.Season_WeaponStrength_Title_UIBP, false)
  end
end
function RoleInfoSegmentUI:HandleWeaponAliasDisplay(aliasInfo)
  log(bWriteLog and "RoleInfoSegmentUI:HandleWeaponAliasDisplay")
  log_tree("aliasInfo", aliasInfo)
  local weaponAlias, aliasText
  if aliasInfo and next(aliasInfo) then
    local key, value = next(aliasInfo)
    weaponAlias = value
    aliasText = FuncUtil.Gen_title(key, aliasInfo[key].rank, aliasInfo[key].ext_info, aliasInfo[key].rank_id)
    self:SetWidgetVisible(self.UIRoot.Season_WeaponStrength_Title_UIBP, true, true)
  else
    self:SetWidgetVisible(self.UIRoot.Season_WeaponStrength_Title_UIBP, false)
    log(bWriteLog and "RoleInfoSegmentUI:HandleWeaponAliasDisplay aliasInfo is nil")
  end
  if weaponAlias then
    log(bWriteLog and "RoleInfoSegmentUI:HandleWeaponAliasDisplay weaponAlias 1")
    self.UIRoot.Season_WeaponStrength_Title_UIBP.WidgetSwitcher_State:SetActiveWidgetIndex(1)
    local key, value = next(aliasInfo)
    self.UIRoot.Season_WeaponStrength_Title_UIBP.Title_UIBP:SetAliasInfo(key, aliasText, "", "", 0, 0)
  else
    log(bWriteLog and "RoleInfoSegmentUI:HandleWeaponAliasDisplay weaponAlias 2")
    self.UIRoot.Season_WeaponStrength_Title_UIBP.WidgetSwitcher_State:SetActiveWidgetIndex(0)
  end
end
function RoleInfoSegmentUI:OnSeasonYearBadgeUpdate()
  log(bWriteLog and "RoleInfoSegmentUI:OnSeasonYearBadgeUpdate")
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local season_year_badge_util = require("client.logic.season_year.util.season_year_badge_util")
  local badgeData
  if RoleInfoSystem.IsSelf() then
    badgeData = season_year_badge_util.GetCurSeasonYearBadgeInfo()
  else
    badgeData = season_year_badge_util.GetSeasonYearBadge(RoleInfoSystem.CurShowPlayerInfoUid)
  end
  if self.season_year_badge == nil then
    local season_year_util = require("client.logic.season_year.util.season_year_util")
    local season_year_id = season_year_util.GetSeasonYearId()
    self.season_year_badge = season_year_util.CreateSeasonBadgeToWidget(self, self.UIRoot.SizeBox_Badge_Root, season_year_id, badgeData)
  else
    self.season_year_badge:SetBadgeInfo(badgeData)
  end
end
function RoleInfoSegmentUI:ShowUIExceptHideAndReplay(bShow)
  if self.UIRoot.CanvasPanel_1 then
    self:SetWidgetVisible(self.UIRoot.CanvasPanel_1, bShow)
  end
  local Personalization_UIBP = UIManager.GetUI(UIManager.UI_Config.Personalization_UIBP)
  if Personalization_UIBP then
    Personalization_UIBP:SetWidgetVisible(Personalization_UIBP.UIRoot.Common_Tab_Vertical_LevelTwo_Icon_UIBP, bShow)
  end
  local Lobby_NewRoleInfo_Mgr_UIBP = UIManager.GetUI(UIManager.UI_Config.roleinfo_main)
  if Lobby_NewRoleInfo_Mgr_UIBP then
    Lobby_NewRoleInfo_Mgr_UIBP:SetWidgetVisible(Lobby_NewRoleInfo_Mgr_UIBP.UIRoot.CanvasPanel_11, bShow)
    Lobby_NewRoleInfo_Mgr_UIBP:SetWidgetVisible(Lobby_NewRoleInfo_Mgr_UIBP.UIRoot.Common_Tab_Vertical_LevelOne_Text_UIBP, bShow)
    Lobby_NewRoleInfo_Mgr_UIBP:SetWidgetVisible(Lobby_NewRoleInfo_Mgr_UIBP.UIRoot.Image_SideMask, bShow)
  end
end
function RoleInfoSegmentUI:PlayEffect(callback)
  log(bWriteLog and "RoleInfoSegmentUI:PlayEffect")
  local logic_roleInfo_background = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_roleInfo_background)
  logic_roleInfo_background:PlayHighLevelEffect(function()
    if callback then
      callback()
    end
  end)
end
function RoleInfoSegmentUI:SetWowPass(widget, profile)
  if widget.CanvasPanel_WoWPass and widget.Image_WowPass then
    local Util_UGC = require("client.slua.logic.ugc.util_ugc")
    if Util_UGC.WoWPassActive(profile) then
      self:SetWidgetVisible(widget.CanvasPanel_WoWPass, true, false)
      local IconPath = Util_UGC.GetWoWPassIconPath(profile)
      local params = {sync = false, bMatchSize = true}
      self:SetTexture(widget.Image_WoWPass, IconPath, params)
    else
      self:SetWidgetVisible(widget.CanvasPanel_WoWPass, false, false)
    end
  end
end
function RoleInfoSegmentUI:OnClickWSDetail()
  self:PlayAudio(sound_config.click_v1)
  if self:_IsRoleSelf() then
    UIManager.ShowUI(UIManager.UI_Config.WeaponStrength_Title_Select_Popup_UIBP)
  else
    local extraData
    local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
    RoleInfoMainSystem.Show(RoleInfoMainSystem.Honor, RoleInfoMainSystem.IntimateRelationship, self.currUID, extraData)
    local roleInfoUI = UIManager.GetUI(UIManager.UI_Config.roleinfo_main)
    if roleInfoUI then
      roleInfoUI.TabID = RoleInfoMainSystem.Honor
      roleInfoUI.SubTabID = RoleInfoMainSystem.Honor_SubTab.WeaponStrenthHonor
      roleInfoUI:UpdateUI()
    end
  end
end
function RoleInfoSegmentUI:HaveNameColor(profile)
  local NicknameColorManager = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.NicknameColorManager)
  local planID = NicknameColorManager:GetUserData(profile.uid)
  self.isDefultNameColor = planID == NicknameColorManager.DEFAULT_PLAN_ID
end
function RoleInfoSegmentUI:InitNicknameOutline()
  self:ApplyNicknameOutline(self.UIRoot.TextBlock_PlayerName, false)
end
function RoleInfoSegmentUI:ApplyNicknameOutline(textWidget, needOutline)
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
function RoleInfoSegmentUI:ApplyTextSkinStyle(textWidget, color)
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
function RoleInfoSegmentUI:ChangeTextColorBySkin()
  local color, imgColor
  if self.isShowSkin then
    color = FSlateColor(FLinearColor(1, 1, 1, 1))
    imgColor = FLinearColor(1, 1, 1, 1)
  else
    color = FSlateColor(FLinearColor(0, 0, 0, 1))
    imgColor = FLinearColor(0, 0, 0, 1)
  end
  local commonTexts = {
    self.UIRoot.TextBlock_CorpsName,
    self.UIRoot.Text_Commander,
    self.UIRoot.Text_DeputyCommander,
    self.UIRoot.Text_Elite,
    self.UIRoot.Text_Member,
    self.UIRoot.TextBlock_PlayerID,
    self.UIRoot.TextBlock_PlayerIDLabel,
    self.UIRoot.TextBlock_21,
    self.UIRoot.TextBlock_upass_level,
    self.UIRoot.TextBlock_10,
    self.UIRoot.ReportText,
    self.UIRoot.TextBlock_16,
    self.UIRoot.Text_NotJoin,
    self.UIRoot.TextBlock_Title,
    self.UIRoot.TextBlock_Level,
    self.UIRoot.TextBlock_Exp,
    self.UIRoot.TextBlock_Award
  }
  for _, w in ipairs(commonTexts) do
    self:ApplyTextSkinStyle(w, color)
  end
  if self.isDefultNameColor then
    self.UIRoot.TextBlock_PlayerName:SetColorAndOpacity(color)
  end
  self:ApplyNicknameOutline(self.UIRoot.TextBlock_PlayerName, not self.isDefultNameColor or self.isShowSkin)
  local imageList = {
    self.UIRoot.Image_62,
    self.UIRoot.Image_fuzhi,
    self.UIRoot.Image_9,
    self.UIRoot.Image_58,
    self.UIRoot.Image_6,
    self.UIRoot.Image_23
  }
  for _, img in ipairs(imageList) do
    img:SetColorAndOpacity(imgColor)
  end
end
local ROLEINFO_GUIDE_MODULE_ID = DataMgr.NEWBIE_GUIDE_MODULE_ID_ROLE_INFO
local ROLEINFO_FIRST_ENTER_GUIDE_KEY = 1
function RoleInfoSegmentUI:TryShowFirstEnterGuide()
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  if not RoleInfoMainSystem.IsMe() then
    return
  end
  if self._bFirstEnterGuideDone then
    return
  end
  self._bFirstEnterGuideDone = true
  if not DataMgr.HaveNewbieGuide(ROLEINFO_GUIDE_MODULE_ID, ROLEINFO_FIRST_ENTER_GUIDE_KEY) then
    return
  end
  if self.UIRoot.ShareRed then
    self:SetWidgetVisible(self.UIRoot.ShareRed, true)
  end
  local guideData = {
    hideBG = true,
    list = {
      [1] = {
        url = CDataTable.GetTableData("RoleInfoContentTable", 1).config,
        title = LocUtil.GetLocalizeResStr(CDataTable.GetTableData("RoleInfoContentTable", 2).config),
        desc = LocUtil.GetLocalizeResStr(CDataTable.GetTableData("RoleInfoContentTable", 3).config)
      }
    },
    closeFunc = function()
      self:OnFirstEnterGuideClose()
    end,
    closeFuncArgs = nil
  }
  if #guideData.list <= 0 then
    log(bWriteLog and "RoleInfoSegmentUI:TryShowFirstEnterGuide guide data list is empty, skip guide")
    return
  end
  log(bWriteLog and "RoleInfoSegmentUI:TryShowFirstEnterGuide showing first enter guide via ShowUI")
  UIManager.ShowUI(UIManager.UI_Config.Common_PageGuide_UIBP, guideData)
end
function RoleInfoSegmentUI:OnFirstEnterGuideClose()
  log(bWriteLog and "RoleInfoSegmentUI:OnFirstEnterGuideClose marking guide as completed")
  DataMgr.SetNewbieGuide(ROLEINFO_GUIDE_MODULE_ID, ROLEINFO_FIRST_ENTER_GUIDE_KEY)
end
local class = require("class")
local ui_base = require("client.slua_ui_framework.base")
local CRoleInfoSegmentUI = class(ui_base, nil, RoleInfoSegmentUI)
return CRoleInfoSegmentUI
