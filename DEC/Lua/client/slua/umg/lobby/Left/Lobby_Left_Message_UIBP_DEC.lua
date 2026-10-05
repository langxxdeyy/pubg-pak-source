local LobbySocialLeftMessage = {}
local LobbySocialSystem = require("client.slua.logic.lobby.Left.logic_lobby_social")
local gem_report_utils = require("client.logic.store.gem_report_utils")
local ModReddotSystem = require("GameLua.Mod.Library.Client.ModReddotSystem")
local PersonSpaceSystem = require("client.logic.personspace.logic_person_space")
function LobbySocialLeftMessage:ctor(_, sUId, isSocial, roleInfoOpenFromType)
  self.isSocial = isSocial
  self.currUID = sUId
  self.roleInfoOpenFromType = roleInfoOpenFromType
  self.bWOWOpen = false
  self.WOWLimitLevel = 0
  self.homePKTipsUI = nil
  self.playerDetail = nil
  self.bSelf = false
  self.bAnimEnd = false
  self._cObj_homeEntranceUIBP = nil
  self._cObj_partyEntranceUIBP = nil
  self._cObj_relationGuideTip = nil
  self._cObj_popularPKTop3 = nil
  self.foldStatus = true
end
function LobbySocialLeftMessage:OnInitialize()
  LobbySocialLeftMessage.__super.OnInitialize(self)
  self.util = require("client.slua_ui_framework.util")
  self.UIRoot.TextBlock_Relation:SetText(LocUtil.LocalizeResFormat(199604))
  self.UIRoot.TextBlock_Moment:SetText(LocUtil.LocalizeResFormat(18327))
  self.isCanCheckRecord = false
  self.curButtonActive = {
    0,
    0,
    0,
    0,
    0,
    0,
    0,
    0
  }
  self.bSelf = tonumber(self.currUID) == tonumber(DataMgr.roleData.uid)
end
function LobbySocialLeftMessage:RegistEvents()
  log(bWriteLog and "LobbySocialLeftMessage:RegistEvents")
  LobbySocialLeftMessage.__super.RegistEvents(self)
  local uNode_root = self.UIRoot
  self:AddOnClickedEventByControl(self.UIRoot.Button_Detail, self.OnButton_DetailClick, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_RP, self.OnButton_RPClick, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Achievement, self.OnButton_AchievementClick, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Upvote, self.OnButton_UpvoteClick, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Relation, self.OnButton_RelationClick, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Moment, self.OnButton_MomentClick, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Legion, self.OnButton_CorpsClick, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Club, self.OnButton_ClubClick, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_ScoreActive, self.Button_ScoreActive, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_ScoreNotActive, self.Button_ScoreNotActive, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Wow, self.OnButton_WowClick, self)
  self:AddOnClickedEventByControl(uNode_root.Button_CollectHallEntrance, self.OnButton_CollectHallClick, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Hide, self.OnButton_FoldClick, self, true)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Show, self.OnButton_FoldClick, self, false)
  if self.UIRoot.UnknowPass_ContinuousBuy_BP.SetClickItemCallback then
    self.UIRoot.UnknowPass_ContinuousBuy_BP:SetClickItemCallback(self.CheckRPRecord, self)
  end
  self:AddCommonEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_LOBBY_SOCIAL_PHOTO, self.OnSwitchPhotoMode, self)
  self:AddCommonEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_LOBBY_SOCIAL_EDIT_STATUS, self.UpdateEditingState, self)
  self:AddControlEventByControl(self.UIRoot.Common_Avatar_BP_2, "OnClickItemCallback", self.OnClickHeadCallback, self)
  self:AddCommonEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_LOBBY_SOCIAL_UPDATE_HEAD_ICON, self.UpdateHead, self)
  self:AddCommonEvent(EVENTTYPE_COLLECT, EVENTID_COLLECT_DATA_NOTIFY, self.UpdateHead, self)
  self:AddCommonEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_LOBBY_SOCIAL_PLAYER_PROFILE, self.OnUpdateSocialProfile, self)
  self:AddCommonEvent(EVENTTYPE_ACHIEVEMENT, EVENTID_ACHIEVEMENT_Summary, self.UpdateAchievement, self)
  self:AddCommonEvent(EVENTTYPE_UNKNOW_PASS, EVENTID_UNKNOW_PASS_INFO_UPDATE, self.OnUpdateUnknowPassInfo, self)
  self:AddCommonEvent(EVENTTYPE_LOBBY, EVENTID_UPDATE_LOBBY_AVATAR, self.OnUpdateLobbyAvatar, self)
  self:AddCommonEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_CARDINFO, self.OnUpdateCardInfo, self)
  self:AddCommonEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_LOBBY_SOCIAL_CORPS_SUMMARY, self.UpdateCorpsSummary, self)
  self:AddCommonEvent(EVENTTYPE_CORPS, EVENTID_CORPS_UPDATE_ICON, self.UpdateCorpsSummary, self)
  self:AddCommonEvent(EVENTTYPE_PERSON_SPACE, EVENTID_PERSONSPACE_SWITCH_UPDATE, self.UpdateRelationButton, self)
  self:AddCommonEvent(EVENTTYPE_PERSON_SPACE, EVENTID_PERSONSPACE_REDDOT_UPDATE, self.UpdateRelationReddot, self)
  self:AddCommonEvent(EVENTTYPE_PERSON_SPACE, EVENTID_PERSONSPACE_PARTNER_CHANGE, self.OnPersonSpacePartnerChange, self)
  self:AddCommonEvent(EVENTTYPE_ROLEINFO, EVENTID_TEAM_EVALUATION_INIT, self.UpdateEvaluationEntrance, self)
  self:AddCommonEvent(EVENTTYPE_MOMENT, EVENTID_MOMENT_BackGround_GetInfo, self.UpdateMomentReddot, self)
  self:AddCommonEvent(EVENTTYPE_MOMENT, EVENTID_MOMENT_BackGround_IsNew_Change, self.UpdateMomentReddot, self)
  self:AddCommonEvent(EVENTTYPE_MOMENT, EVENTID_MOMENT_BackGround_GETNEWBG, self.UpdateMomentReddot, self)
  self:AddCommonEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_LOBBY_COLLECT_HALL_LEVEL_CHANGE, self.OnCollectHallLevelChangeEvent, self)
  self:AddCommonEvent(EVENTTYPE_LOBBY, EVENTID_SWITCHTO_PAGE_START, self.OnSwitchToPageStart, self)
  self:AddCommonEvent(EVENTTYPE_LOBBY, EVENTID_SWITCHTO_PAGE_END, self.OnSwitchToPageEnd, self)
  self:AddCommonEvent(EVENTTYPE_LOBBY, EVENTID_ANIM_MID_TO_LEFT_END, self.OnAniMidToLeftEnd, self)
  self:AddCommonEvent(EVENTTYPE_UGC, EVENTID_UGC_UPDATE_AUTHOR, self.OnGetUGCAuthorData, self)
  self:AddCommonEvent(EVENTTYPE_UGC, EVENTID_UGC_GET_MINE_MODS, self.OnGetMyUGCData, self)
  self:AddCommonEvent(EVENTTYPE_POPULAR_HOMEPK, EVENTID_POPULAR_HOME_PK_CONFIG_UPDATE, self.OnHomePkCfgUpdate, self)
  self:AddCommonEvent(EVENTTYPE_POPULAR_HOMEPK, EVENTID_POPULAR_HOME_PK_DATA_UPDATE, self.OnPopularHomePKDataUpdate, self)
  self:RegistEvents_Popularity()
end
function LobbySocialLeftMessage:OnPostInitialize()
  LobbySocialLeftMessage.__super.OnPostInitialize(self)
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  local spData = RoleInfoMainSystem.GetSuperData()
  for key, _ in pairs(spData) do
    self:AddDataListener(spData, key, self.UpdateShowInfoReddot, self, key)
  end
  self:UpdateProfile()
  self:InitUI()
  if self.isSocial and self.bSelf then
    PersonSpaceSystem.get_intimacy_relation_req()
  end
end
function LobbySocialLeftMessage:OnShow()
  local uid = self.currUID
  if not LobbySocialSystem.IsSelf(uid) then
    self:ClearGuideTimer()
    self.guideTimer = self:AddTimer(0.1, function()
      local bSelf = LobbySocialSystem.IsSelf(self.currUID)
      if self:CanShowGuide(bSelf) then
        self:ShowCollectGuide(bSelf)
        self:ShowRelationGuide(bSelf)
      end
    end)
  end
  if LobbySocialSystem.IsSelf(uid) then
    self:UpdateNicknameFrame()
  end
end
function LobbySocialLeftMessage:InitUI()
  local uid = self.currUID
  self:UpdateShowInfoReddot()
  self:UpdateMomentReddot()
  self:UpdateRelationReddot()
  self:UpdateCorpsReddot(nil, nil, BP_ENUM_MODULE_CORPS)
  self:UpdateCorpsSummary()
  self:StartShowTips()
  self:UpdatePopularityButton()
  self:UpdateRelationButton()
  self:UpdateMomentButton()
  self:RefreshCollectHallEntranceButton()
  self:UpdateFoldButtons()
  self:UpdateEvaluationEntrance()
  local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
  self:SetWidgetVisible(self.UIRoot.CanvasPanel_Ban, logic_profile:IsPlayerBanned(uid))
  self:UpdatePHome()
  if not LobbySocialSystem.IsSelf(uid) then
    self:RequestHomeData()
    self:ReqAuthorInfo()
  end
end
function LobbySocialLeftMessage:OnSwitchToPageStart()
  log_warning(bWriteLog and "  LobbySocialLeftMessage:OnSwitchToPageStart.  self:RemoveTimer")
  self:ClearGuideTimer()
end
function LobbySocialLeftMessage:OnSwitchToPageEnd(_, _, fromPage, toPage)
  self:InitShowTipData()
  if self.guideTimer then
    log_warning(bWriteLog and "  LobbySocialLeftMessage:OnSwitchToPageEnd.  RemoveTimer")
    self:ClearGuideTimer()
  end
  if toPage == ENUM_LobbyPageType.Left then
    log(bWriteLog and "[v_wllwu] LobbySocialLeftMessage:OnSwitchToPageEnd")
    self:UpdateMomentBubbleTips(true)
    self:UpdateEvaluationEntrance()
    self:RequestHomeData()
    self:ReqAuthorInfo()
    self.isInSocialLobby = true
    self:StartShowTips()
    self.guideTimer = self:AddTimer(0.1, function()
      local isAndroidStackEmpty = UIManager.IsAndroidStackEmpty()
      if not isAndroidStackEmpty then
        log_warning(bWriteLog and "  LobbySocialLeftMessage:OnSwitchToPageEnd.  not isAndroidStackEmpty")
        return
      end
      if self:CanShowGuide(true) then
        self:ShowCollectGuide(true)
        self:ShowRelationGuide(true)
      end
    end)
  end
end
function LobbySocialLeftMessage:OnAniMidToLeftEnd()
  log(bWriteLog and "LobbySocialLeftMessage:OnAniMidToLeftEnd")
  self.bAnimEnd = true
end
function LobbySocialLeftMessage:OnSwitchPhotoMode(_, _, in_photo)
  log(bWriteLog and "LobbySocialLeftMessage:OnSwitchPhotoMode in_photo: " .. tostring(in_photo))
  if in_photo then
    self:SetWidgetVisible(self.UIRoot.CanvasPanel_IPX, false)
  else
    self:SetWidgetVisible(self.UIRoot.CanvasPanel_IPX, true)
  end
end
function LobbySocialLeftMessage:UpdateEditingState(_, _, IsEditing)
  self:SetWidgetVisibility(IsEditing and UEnums.ESlateVisibility.Collapsed or UEnums.ESlateVisibility.SelfHitTestInvisible)
end
function LobbySocialLeftMessage:ShowCollectGuide(bSelf)
  log(bWriteLog and "LobbySocialLeftMessage:ShowCollectGuide bSelf = " .. tostring(bSelf))
  local logic_player_return = require("client.slua.logic.player_return.logic_player_return")
  local isReturn = logic_player_return.isPlayerReturnOpenNew()
  if isReturn then
    local logic_backuser_tips_mutex = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_backuser_tips_mutex)
    local tip_id = logic_backuser_tips_mutex:GetTip()
    if tip_id ~= logic_backuser_tips_mutex.tips_id.CollectGuide then
      return
    end
  end
  local uid = self.currUID
  if not LobbySocialSystem.IsSelf(uid) then
    local collect_module = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.collect_module)
    local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
    local profile = logic_profile:GetLocalProfile(uid)
    local bShowCollect = collect_module:CanShowCollect(profile)
    log(bWriteLog and "LobbySocialLeftMessage:ShowCollectGuide bShowCollect = " .. tostring(bShowCollect))
    if not bShowCollect then
      return
    end
  end
  local level_unlock_util = require("client.logic.level_unlock.util.level_unlock_util")
  local bHaveLockedFeature = level_unlock_util:HaveLockedFeature()
  log(bWriteLog and "LobbySocialLeftMessage:ShowCollectGuide bHaveLockedFeature = " .. tostring(bHaveLockedFeature))
  if bHaveLockedFeature then
    return
  end
  local PlayerPrefsSystem = require("client.logic.LogicPlayerPrefs.playerprefs")
  local show = PlayerPrefsSystem.LoadFileToTable_N(PlayerPrefsSystem.ePlayerPrefsType.eCollectNew)
  log(bWriteLog and "LobbySocialLeftMessage:ShowCollectGuide show: " .. tostring(show))
  if not show or show == 0 then
    local maxWaitTime = 2
    local waitInterval = 0.05
    local elapsed = 0
    while not self.bAnimEnd and maxWaitTime > elapsed do
      coroutine.yield(waitInterval)
      elapsed = elapsed + waitInterval
    end
    if not self.bAnimEnd then
      log_warning(bWriteLog and "LobbySocialLeftMessage:ShowCollectGuide anim wait timeout, skip guide")
      return
    end
    local callBack = function()
      PlayerPrefsSystem.SaveTableToFile_N(1, PlayerPrefsSystem.ePlayerPrefsType.eCollectNew)
    end
    local word = LocUtil.GetLocalizeResStr(77549)
    local cObj_parent = self:GetParentUI()
    local location = cObj_parent:GetGuideCollectPos()
    if not location then
      log(bWriteLog and "LobbySocialLeftMessage:ShowCollectGuide >>> not found location")
      return
    end
    local cObj_parent_forFlag = self:GetParentUI()
    if cObj_parent_forFlag then
      cObj_parent_forFlag._bCollectGuideShowing = true
      local Logic_PlanCH_GuideManager = require("client.slua.logic.lobby.Left.SocialLobby.Logic_PlanCH_GuideManager")
      Logic_PlanCH_GuideManager:HideGuide("ClothSlotGuide")
      cObj_parent_forFlag:HideHighlightGuide()
    end
    local UIUtil = require("client.common.ui_util")
    local cObj_lobbyMainUI = UIManager.GetUI(UIManager.UI_Config.Lobby_Main_UIBP)
    local uLocalPos = UIUtil.WorldToUILocalPosition(location, cObj_lobbyMainUI.UIRoot)
    local uShowPos = UIUtil.ConvertLocalPositionBetweenWidgets(cObj_lobbyMainUI.UIRoot, uLocalPos, self.UIRoot.CanvasPanel_IPX)
    self.UIRoot.CanvasPanel_Collect.Slot:SetAlignment(FVector2D(0.5, 0.5))
    self.UIRoot.CanvasPanel_Collect.Slot:SetPosition(uShowPos)
    local origCallBack = callBack
    local selfRef = self
    function callBack()
      if origCallBack then
        origCallBack()
      end
      local cObj_parent_ref = selfRef:GetParentUI()
      if cObj_parent_ref and slua.isValid(cObj_parent_ref.UIRoot) then
        cObj_parent_ref._bCollectGuideShowing = false
        cObj_parent_ref:TryShowHighlightGuide()
      end
    end
    coroutine.yield(0.02)
    if self:CanShowGuide(bSelf) then
      UIManager.ShowUI(UIManager.UI_Config.NewbieGuide_UIBP, 3, word, self.UIRoot.CanvasPanel_Collect, callBack, true, 1, nil, nil, {X = 0.5, Y = 0.5})
    else
      do
        local cObj_parent_ref = selfRef:GetParentUI()
        if cObj_parent_ref and slua.isValid(cObj_parent_ref.UIRoot) then
          cObj_parent_ref._bCollectGuideShowing = false
          cObj_parent_ref:TryShowHighlightGuide()
        end
      end
    end
  end
end
function LobbySocialLeftMessage:ShowRelationGuide(bSelf)
  if not bSelf then
    self:ClearRelationGuideTip()
    return
  end
  local logic_player_return = require("client.slua.logic.player_return.logic_player_return")
  local isReturn = logic_player_return.isPlayerReturnOpenNew()
  if isReturn then
    local logic_backuser_tips_mutex = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_backuser_tips_mutex)
    local tip_id = logic_backuser_tips_mutex:GetTip()
    if tip_id ~= logic_backuser_tips_mutex.tips_id.RelationGuide then
      self:ClearRelationGuideTip()
      return
    end
  end
  local logic_person_space_relationship = require("client.logic.personspace.logic_person_space_relationship")
  if logic_person_space_relationship.NeedShowCohabitBubbleGuide() then
    self:ShowRelationGuideTip(0, LocUtil.GetLocalizeResStr(655878))
  elseif logic_person_space_relationship.NeedShowRelationGuide() then
    self:ShowRelationGuideTip(0, LocUtil.GetLocalizeResStr(73627))
  else
    local LogicFriend = require("client.slua.logic.friend.logic_new_friend")
    local dataList = LogicFriend.GetLimitedIntimacyCanBuildList(3)
    if #dataList <= 0 then
      self:ClearRelationGuideTip()
      return
    end
    self:ShowRelationGuideTip(1)
  end
end
function LobbySocialLeftMessage:ShowRelationGuideTip(nShowIndex, sShowTip)
  self:ClearRelationGuideTip()
  self._cObj_relationGuideTip = self:CreateChildWindow(self.UIRoot.CanvasPanel_RelationTips, UIManager.UI_Config.SocialLobby_LeftUI_RelationTip_UIBP, nShowIndex, sShowTip)
end
function LobbySocialLeftMessage:ClearRelationGuideTip()
  if not self._cObj_relationGuideTip then
    return
  end
  self._cObj_relationGuideTip:Close()
  self._cObj_relationGuideTip = nil
end
function LobbySocialLeftMessage:CanShowGuide(bSelf)
  log_warning(bWriteLog and "  LobbySocialLeftMessage:CanShowGuide. bSelf: " .. tostring(bSelf))
  if bSelf then
    local Lobby_Main_Control = require("client.slua.logic.lobby.Main.Lobby_Main_Control")
    local bIsSocialLeft = Lobby_Main_Control.curPage == ENUM_LobbyPageType.Left
    local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
    local bIsMainCityLeft = self.roleInfoOpenFromType == RoleInfoMainSystem.RoleInfoOpenFromType.MainCitySwitch
    return bIsSocialLeft or bIsMainCityLeft
  else
    return UIManager.IsUIShow(UIManager.UI_Config.Social_Person_Space_UIBP)
  end
end
function LobbySocialLeftMessage:ClearGuideTimer()
  if not self.guideTimer then
    return
  end
  self:RemoveTimer(self.guideTimer)
  self.guideTimer = nil
end
function LobbySocialLeftMessage:UpdateHead()
  local profile = LobbySocialSystem.GetProfileByUID(self.currUID)
  if not profile then
    return
  end
  local extraPara = {
    collectPara = {
      collectData = profile.collect_data,
      showCollectTips = false
    }
  }
  self.UIRoot.Common_Avatar_BP_2:InitView(1, profile.uid, profile.picUrl, profile.sex, profile.cur_avatar_box_id, profile.level, false, "", nil, extraPara)
end
function LobbySocialLeftMessage:UpdateNicknameFrame()
  log(bWriteLog and "LobbySocialLeftMessage:UpdateNicknameFrame")
  local profile = LobbySocialSystem.GetProfileByUID(self.currUID)
  if not profile then
    log(bWriteLog and "LobbySocialLeftMessage:UpdateNicknameFrame not profile")
    return
  end
  local nicknameFrameID = profile.friend_nickname_skin
  log(bWriteLog and "LobbySocialLeftMessage:UpdateNicknameFrame nicknameFrameID = " .. tostring(nicknameFrameID))
  local UIUtil = require("client.common.ui_util")
  UIUtil.UpdateNicknameFrame(self, nicknameFrameID, "SizeBox_NicknameFrame")
end
function LobbySocialLeftMessage:UpdateProfile()
  log(bWriteLog and "LobbySocialLeftMessage:UpdateProfile")
  local LogicUGC = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicUGC)
  self.bWOWOpen, self.WOWLimitLevel = LogicUGC:IsWOWOpen()
  local profile = LobbySocialSystem.GetProfileByUID(self.currUID)
  if not profile then
    log(bWriteLog and "LobbySocialLeftMessage:UpdateProfile not profile uid = " .. tostring(self.currUID))
    local MAX_PROFILE_RETRY = 3
    self._profileRequestCount = self._profileRequestCount or 0
    if not self._bRequestingProfile and MAX_PROFILE_RETRY > self._profileRequestCount then
      self._bRequestingProfile = true
      self._profileRequestCount = self._profileRequestCount + 1
      printf("LobbySocialLeftMessage:UpdateProfile request profile uid = %s, retry = %s", tostring(self.currUID), tostring(self._profileRequestCount))
      local logic_profile_get_wrap = require("client.slua.logic.user.profile.logic_profile_get_wrap")
      logic_profile_get_wrap.GetNormalProfiles({
        self.currUID
      }, function()
        if not self.UIRoot or not slua.isValid(self.UIRoot) then
          return
        end
        self._bRequestingProfile = false
        log(bWriteLog and "LobbySocialLeftMessage:UpdateProfile profile callback uid = " .. tostring(self.currUID))
        self:UpdateProfile()
      end, Enum_PROFILE_REPORT_CFG.ROLE_INFO)
    elseif MAX_PROFILE_RETRY <= self._profileRequestCount then
      log_warning(bWriteLog and "LobbySocialLeftMessage:UpdateProfile reached max retry uid = " .. tostring(self.currUID))
    end
    return
  end
  self._profileRequestCount = 0
  self._bRequestingProfile = false
  self.UIRoot.CanvasPanel_Profile:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
  local extraPara = {
    collectPara = {
      collectData = profile.collect_data,
      showCollectTips = false
    }
  }
  self.UIRoot.Common_Avatar_BP_2:InitView(1, profile.uid, profile.picUrl, profile.sex, profile.cur_avatar_box_id, profile.level, false, "", nil, extraPara)
  local UIUtil = require("client.common.ui_util")
  UIUtil.UpdateNationImage(self.UIRoot.Image_Flag, profile.nation)
  if profile.social_card and profile.social_card.new_sex and 0 < profile.social_card.new_sex then
    self.UIRoot.CanvasPanel_19:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    self.UIRoot.Common_Gender_UIBP:LoadIcon(profile.uid)
  else
    self.UIRoot.CanvasPanel_19:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  end
  self.UIRoot.Common_LightBoard_UIBP:ShowLightBoard(profile.uid, self.UIRoot.CanvasPanel_Family)
  local bShow = self.UIRoot.Common_Certification_UIBP:SetAuthInfo(profile.auth_type, profile.auth_end_time)
  self:SetWidgetVisible(self.UIRoot.SizeBox_Cert, bShow)
  self.UIRoot.Common_Certification_UIBP:SetTextFontSize(12)
  self.UIRoot.Common_Certification_UIBP:SetTextLight()
  self.UIRoot.Common_Certification_UIBP:SetImageSize(19, 19)
  self.UIRoot.TextBlock_Player2:SetText(profile.nickName or "")
  local NicknameColorManager = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.NicknameColorManager)
  local planID = NicknameColorManager:GetUserData(profile.uid)
  if planID == NicknameColorManager.DEFAULT_PLAN_ID then
    UIUtil.SetTextOutline(self.UIRoot.TextBlock_Player2, 0)
  else
    UIUtil.SetTextOutline(self.UIRoot.TextBlock_Player2, 1)
  end
  self.UIRoot.TextBlock_Player2:SetColorAndOpacity(NicknameColorManager:GetColorByUID(self.currUID))
  self.UIRoot.UnknowPass_ContinuousBuy_BP:SetTypeData(0, profile.upass_keep_buy, profile.upass_is_buy == 1, 1, profile.upass_cur_value or 0, profile.pass_type)
  self.UIRoot.CanvasPanel_RP:SetWidgetVisibility(UIUtil.BoolToVisible(profile.upass_is_show ~= 0))
  self.UIRoot.TextBlock_RP:SetText(LocUtil.LocalizeResFormat(43196, profile.upass.level or 1))
  self.UIRoot.TextBlock_Upvote:SetText(profile.upvote or 0)
  self.TextBlock_Relation = self.UIRoot.TextBlock_Relation
  self:UpdateUGCButton()
end
function LobbySocialLeftMessage:UpdateShowInfoReddot()
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  self.bIsTotalRed = false
  local spData = RoleInfoMainSystem.GetSuperData()
  local level_unlock_manager = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.level_unlock_manager)
  for key, bIsTabRed in pairs(spData) do
    if bIsTabRed then
      if tostring(key) == "achievementRed" then
        if level_unlock_manager:IsFeatureUnlocked(level_unlock_manager.featureDef.achievement) then
          self.bIsTotalRed = true
          break
        end
      else
        self.bIsTotalRed = true
        break
      end
    end
  end
  if self.UIRoot then
    local bCanShow = self.isSocial or self.roleInfoOpenFromType == RoleInfoMainSystem.RoleInfoOpenFromType.MainCitySwitch
    if bCanShow then
      self:SetWidgetVisible(self.UIRoot.showinfo_reddot, self.bIsTotalRed)
    else
      self:SetWidgetVisible(self.UIRoot.showinfo_reddot, false)
    end
  end
end
function LobbySocialLeftMessage:UpdateAchievement()
  local AchieveHandler = require("client.network.Protocol.AchieveHandler")
  local data = AchieveHandler.resSummaryTb[tonumber(self.currUID)]
  if data then
    self.UIRoot.TextBlock_Achievement:SetText(data.achieve_score)
  end
end
function LobbySocialLeftMessage:UpdateEvaluationEntrance()
  if LobbySocialSystem.IsSelf(self.currUID) and self.isSocial then
    local Lobby_Main_Control = require("client.slua.logic.lobby.Main.Lobby_Main_Control")
    if Lobby_Main_Control.curPage ~= ENUM_LobbyPageType.Left then
      return
    end
  end
  local logic_team_evaluation_view = require("client.slua.logic.team_evaluation.logic_team_evaluation_view")
  logic_team_evaluation_view.RefreshEvaluationEntrance(self.currUID, self.UIRoot)
  if tonumber(self.currUID) == tonumber(DataMgr.roleData.uid) then
    local settingType = logic_team_evaluation_view.GetEntranceSettingType()
    local data = logic_team_evaluation_view.GetEvaluationDataByUID(self.currUID)
    local shouldShowGuide = settingType == 2 and data.reason == 10 and not self.evaluationGuide
    shouldShowGuide = shouldShowGuide and not self.bHasShownEvluationGuide
    if shouldShowGuide then
      log(bWriteLog and "[DeanJYT] LobbySocialLeftMessage:UpdateEvaluationEntrance show guide")
      self.evaluationGuide = self:CreateChildWindow(self.UIRoot.CanvasPanel_Score, UIManager.UI_Config.Lobby_Left_EvaluationGuide_UIBP)
      self.evaluationGuide:SetTipsText()
    elseif self.evaluationGuide then
      self.evaluationGuide:Close()
      self.evaluationGuide = nil
    end
  elseif self.evaluationGuide then
    self.evaluationGuide:Close()
    self.evaluationGuide = nil
  end
end
function LobbySocialLeftMessage:OnUpdateSocialProfile(_, _, uid)
  log(bWriteLog and "LobbySocialLeftMessage:OnUpdateSocialProfile")
  self:UpdateProfile()
  self:UpdateNicknameFrame()
  self:OnUpdateProfilePopularity(uid)
end
function LobbySocialLeftMessage:OnUpdateUnknowPassInfo()
  log(bWriteLog and "LobbySocialLeftMessage:OnUpdateUnknowPassInfo")
  self:UpdateProfile()
end
function LobbySocialLeftMessage:OnUpdateLobbyAvatar()
  log(bWriteLog and "LobbySocialLeftMessage:OnUpdateLobbyAvatar")
  self:UpdateProfile()
end
function LobbySocialLeftMessage:OnUpdateCardInfo()
  log(bWriteLog and "LobbySocialLeftMessage:OnUpdateCardInfo")
  self:UpdateProfile()
end
function LobbySocialLeftMessage:OnClickHeadCallback()
  self:PlayAudio(sound_config.click_v1)
  local profile = LobbySocialSystem.GetProfileByUID(self.currUID)
  if not profile then
    return
  end
  local RoleInfoBigAvatarSystem = require("client.slua.logic.roleInfo.logic_roleInfo_BigAvatar")
  RoleInfoBigAvatarSystem.ShowUI(profile)
end
function LobbySocialLeftMessage:OnButton_DetailClick()
  self:PlayAudio(sound_config.click_v1)
  log(bWriteLog and "LobbySocialLeftMessage:OnButton_DetailClick")
  local profile = LobbySocialSystem.GetProfileByUID(self.currUID)
  local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
  if logic_profile:IsPlayerDelete(profile) then
    return
  end
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  RoleInfoMainSystem.Show(RoleInfoMainSystem.Segment, self.roleInfoOpenFromType or RoleInfoMainSystem.RoleInfoOpenFromType.Lobby, self.currUID)
  local tlog_report_utils = require("client.slua.config.tlog.tlog_report_utils")
  tlog_report_utils.ReportTLogEvent(TLogEventDefine.SocialLobbyHead)
end
function LobbySocialLeftMessage:OnButton_RPClick()
  self:PlayAudio(sound_config.click_v1)
  self:CheckRPRecord()
end
function LobbySocialLeftMessage:Button_ScoreActive()
  self:PlayAudio(sound_config.click_v1)
  local logic_team_evaluation_view = require("client.slua.logic.team_evaluation.logic_team_evaluation_view")
  logic_team_evaluation_view.ShowDetailedEvaluationView(self.currUID)
  if tonumber(self.currUID) == tonumber(DataMgr.roleData.uid) and self.evaluationGuide then
    log(bWriteLog and "[DeanJYT] LobbySocialLeftMessage:Button_ScoreActive close guide")
    logic_team_evaluation_view.send_finish_evaluation_guide_req()
    self.evaluationGuide:Close()
    self.evaluationGuide = nil
    self.bHasShownEvluationGuide = true
  end
end
function LobbySocialLeftMessage:Button_ScoreNotActive()
  self:PlayAudio(sound_config.click_v1)
  local logic_team_evaluation_view = require("client.slua.logic.team_evaluation.logic_team_evaluation_view")
  logic_team_evaluation_view.ShowNotEnoughEvaluationTips()
end
function LobbySocialLeftMessage:OnButton_AchievementClick()
  self:PlayAudio(sound_config.click_v1)
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  RoleInfoMainSystem.Show(RoleInfoMainSystem.Honor, RoleInfoMainSystem.RoleInfoOpenFromType.Lobby, self.currUID)
end
function LobbySocialLeftMessage:OnButton_UpvoteClick()
  self:PlayAudio(sound_config.click_v1)
  local tipsUI = UIManager.ShowUI(UIManager.UI_Config.common_float_tips)
  local TipsParam = {
    offsetX = 0,
    offsetY = 0,
    wrapWidthType = 1,
    anchors = {
      minX = 1,
      minY = 1,
      maxX = 1,
      maxY = 1
    }
  }
  tipsUI:SetTips(self.UIRoot.Button_Upvote, LocUtil.LocalizeResFormat(7230), TipsParam)
end
function LobbySocialLeftMessage:CheckRPRecord()
  self:PlayAudio(sound_config.click)
  local UnknowPassMacro = require("client.slua.logic.unknow_pass.unknowpass_macro")
  local UnknowPassUtil = require("client.slua.logic.unknow_pass.logic_unknowpass_util")
  UnknowPassUtil.GetUnknowPassNextSeason()
  local profile = LobbySocialSystem.GetProfileByUID(self.currUID)
  log_tree("LobbySocialLeftMessage:CheckRPRecord", profile)
  if not profile then
    return
  end
  if profile.upass and profile.upass.switch.record_privacy or self.currUID == DataMgr.roleData.uid then
    UIManager.ShowUI(UIManager.UI_Config.UnknowPass_RecordMain_UIBP, true, self.currUID)
    if self.currUID == DataMgr.roleData.uid then
      DataMgr.SetNewbieGuide(DataMgr.NEWBIE_GUIDE_MODULE_ID_PASS, UnknowPassMacro.ENUM_Pass_Main_Reddot.ENUM_Pass_NewRecordGuide)
    end
  else
    ShowNotice(18256)
  end
end
function LobbySocialLeftMessage:UpdateCorpsSummary()
  local uNode_root = self.UIRoot
  local tCorpSummary = LobbySocialSystem.GetCorpSummary(self.currUID)
  if not tCorpSummary or not next(tCorpSummary) then
    self:SetWidgetVisible(uNode_root.Button_Legion, false, true)
    return
  end
  local icon_path = "/Game/UMG/Texture/Atlas/Lobby/Frames/Lobby_Left_Corps_png.Lobby_Left_Corps_png"
  if tCorpSummary.icon ~= nil and tCorpSummary.icon > 0 then
    local corpIDConf = CDataTable.GetTableData("CorpsBadge", tonumber(tCorpSummary.icon))
    if corpIDConf ~= nil then
      icon_path = corpIDConf.IconPath
    end
  end
  self:SetWidgetVisible(uNode_root.Button_Legion, true, true)
  self:SetWidgetVisible(uNode_root.TextBlock_Legion, true)
  uNode_root.TextBlock_Legion:SetText(tCorpSummary.name)
  self:SetTexture(uNode_root.Icon_Legion, icon_path)
end
function LobbySocialLeftMessage:UpdateCorpsReddot(_, _, ModuleId)
  if BP_ENUM_MODULE_CORPS ~= ModuleId then
    return
  end
  log(bWriteLog and "UpdateCorpsReddot:" .. tostring(ModuleId))
  self:SetWidgetVisible(self.UIRoot.Reddot_Anchor, false)
  local CorpsRedPointData = require("client.slua.logic.corps.corps_reddot_data")
  local redPoint = CorpsRedPointData.GetRedDotSuperData()
  if redPoint and LobbySocialSystem.IsSelf(self.currUID) then
    self:SetWidgetVisible(self.UIRoot.Reddot_Anchor, true)
    self.UIRoot.Reddot_Anchor:UnBind()
    self.UIRoot.Reddot_Anchor:Bind(redPoint)
  else
    self:SetWidgetVisible(self.UIRoot.Reddot_Anchor, false)
  end
end
function LobbySocialLeftMessage:OnButton_CorpsClick()
  self:PlayAudio(sound_config.new_corpsBtn)
  log(bWriteLog and "LobbySocialLeftMessage:OnButton_CorpsClick")
  local growthprojectMgrB = require("client.slua.logic.growth_project.logic_growth_project_b")
  growthprojectMgrB.HideWeakGuide(5, 2)
  if not LobbySystem.CheckLobbyMenuOpen(BP_ENUM_LOBBY_MENU_CORPS) then
    return
  end
  if LobbySocialSystem.IsSelf(self.currUID) then
    local logic_corps_tab_mgr = require("client.slua.logic.corps.logic_corps_tab_mgr")
    logic_corps_tab_mgr.OpenCorpsUI()
    local tlog_report_utils = require("client.slua.config.tlog.tlog_report_utils")
    tlog_report_utils.ReportTLogEvent(TLogEventDefine.LobbyCorps)
  else
    local profile = LobbySocialSystem.GetProfileByUID(self.currUID)
    if profile then
      local RoleInfoCorpsSystem = require("client.slua.logic.roleInfo.logic_roleInfo_Corps")
      RoleInfoCorpsSystem.Open(profile.corps_id, self.currUID, profile.corp_alias_id)
    end
  end
end
function LobbySocialLeftMessage:UpdateRelationButton()
  local intimacy_visible_switchs_tool = require("client.slua.logic.friend.Intimacy.intimacy_visible_switchs_tool")
  if LobbySocialSystem.IsSelf(self.currUID) then
    self:SetWidgetVisible(self.UIRoot.Button_Relation, true, true)
  elseif intimacy_visible_switchs_tool.GetVisiblePlayer(self.currUID) then
    self:SetWidgetVisible(self.UIRoot.Button_Relation, true, true)
  else
    self:SetWidgetVisible(self.UIRoot.Button_Relation, false, true)
  end
end
function LobbySocialLeftMessage:OnPersonSpacePartnerChange()
  log(bWriteLog and "LobbySocialLeftMessage:OnPersonSpacePartnerChange")
  local bSelf = LobbySocialSystem.IsSelf(self.currUID)
  self:ShowRelationGuide(bSelf)
end
function LobbySocialLeftMessage:UpdateRelationReddot()
  local SocialReddotSystem = require("client.slua.logic.lobby.Left.logic_social_reddot")
  local IntimacyAwardSystem = require("client.slua.logic.person_space.logic_intimacy_award")
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  local bNeedRefresh = self.isSocial or self.roleInfoOpenFromType == RoleInfoMainSystem.RoleInfoOpenFromType.MainCitySwitch
  if PersonSpaceSystem.HasIntimacyCanGetRewardReddot() or IntimacyAwardSystem.HasIntimacyRewardReddot() then
    local reddotType = ModReddotSystem.ERedDotStyle.GIFT
    self.UIRoot.Reddot_Anchor_Intimacy:ShowRedPointByPath(reddotType)
    self:SetWidgetVisible(self.UIRoot.Reddot_Anchor_Intimacy, bNeedRefresh)
    self:SetWidgetVisible(self.UIRoot.Image_Relation_Reddot, false)
  else
    self:SetWidgetVisible(self.UIRoot.Image_Relation_Reddot, bNeedRefresh and SocialReddotSystem.HaveRelationReddot())
    self:SetWidgetVisible(self.UIRoot.Reddot_Anchor_Intimacy, false)
  end
end
function LobbySocialLeftMessage:OnButton_RelationClick()
  self:PlayAudio(sound_config.new_corpsBtn)
  local PersonSpaceRelationshipSystem = require("client.logic.personspace.logic_person_space_relationship")
  local LogicFriend = require("client.slua.logic.friend.logic_new_friend")
  local extraData = {viewIndex = 1}
  if LogicFriend.GetIntimacyList(false) == 0 then
    extraData = {
      intimacyInfo = {viewIndex = 2}
    }
  end
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  RoleInfoMainSystem.Show(RoleInfoMainSystem.IntimateRelationship, RoleInfoMainSystem.RoleInfoOpenFromType.Lobby, self.currUID, extraData)
  local roleInfoUI = UIManager.GetUI(UIManager.UI_Config.roleinfo_main)
  if roleInfoUI then
    roleInfoUI.TabID = RoleInfoMainSystem.IntimateRelationship
    roleInfoUI.SubTabID = RoleInfoMainSystem.IntimateRelationship_SubTab.Close
    roleInfoUI:UpdateUI()
  end
  log(bWriteLog and "[YY]open====????====" .. tostring(222222))
  LogicFriend.UpdateAvaliableIntimacyTb()
  PersonSpaceRelationshipSystem.SetHasShowRelationGuide()
  if PersonSpaceRelationshipSystem.NeedShowCohabitBubbleGuide() then
    log(bWriteLog and "[DeanJYT] LobbySocialLeftMessage:OnButton_RelationClick discard guide")
    PersonSpaceRelationshipSystem.SetHasShowCohabitBubbleGuide()
  end
  if LobbySocialSystem.IsSelf(self.currUID) then
    self:ShowRelationGuide()
  end
  gem_report_utils.ReportBtnClickEvent(gem_report_utils.SubEventName_PersonSpaceRelation)
  local tlog_report_utils = require("client.slua.config.tlog.tlog_report_utils")
  tlog_report_utils.ReportTLogEvent(TLogEventDefine.SocialLobbyIntime)
end
function LobbySocialLeftMessage:OnButton_FoldClick(bShowOrHide)
  self:PlayAudio(sound_config.click_v1)
  self.foldStatus = not bShowOrHide
  self:UpdateFoldButtons()
  EventSystem:postEvent(EVENTTYPE_UGC, EVENTID_UGC_GET_MINE_MODS)
end
function LobbySocialLeftMessage:UpdateFoldButtons()
  if not self.UIRoot then
    log(bWriteLog and "LobbySocialLeftMessage:UpdateFoldButtons self.UIRoot is nil")
    return
  end
  self:UpdateClubButton()
  self:UpdateUGCButton()
  self:UpdateFoldButton()
end
function LobbySocialLeftMessage:UpdateFoldButton()
  self.UIRoot.WidgetSwitcher_ShowState:SetActiveWidgetIndex(self.foldStatus and 0 or 1)
  if not self.isClubVisible and not self.isWowVisible then
    self:SetWidgetVisible(self.UIRoot.WidgetSwitcher_ShowState, false, true)
  else
    self:SetWidgetVisible(self.UIRoot.WidgetSwitcher_ShowState, true, true)
  end
end
function LobbySocialLeftMessage:SetWidgetFoldVisible(widget, bVisible, bButton)
  if not widget then
    log_warning(bWriteLog and "LobbySocialLeftMessage:SetWidgetFoldVisible widget is nil")
    return
  end
  self:SetWidgetVisible(widget, not self.foldStatus and bVisible, bButton)
end
function LobbySocialLeftMessage:UpdateMomentButton()
  self:SetWidgetVisible(self.UIRoot.Button_Moment, LobbySystem.CheckOpen(BP_ENUM_MOMENT_SWITCH), true)
end
function LobbySocialLeftMessage:UpdateMomentReddot()
  local logic_moment_background = require("client.slua.logic.moment.logic_moment_background")
  local localRedDotFileTb = logic_moment_background.GetLocalRedDotFileTb()
  self:SetWidgetVisible(self.UIRoot.Image_48, false)
  if logic_moment_background.HasNew() and localRedDotFileTb[1] == nil then
    self:SetWidgetVisible(self.UIRoot.Moment_Reddot, true)
  else
    self:SetWidgetVisible(self.UIRoot.Moment_Reddot, false)
    local moment_reddot_data = require("client.slua.logic.moment.moment_reddot_data")
    local momentRedPoint = moment_reddot_data.GetData()
    if momentRedPoint then
      self:AddDataListener(momentRedPoint, "has_new", function(oldValue, value)
        if not self.UIRoot then
          return
        end
        local logic_moment = require("client.slua.logic.moment.logic_moment")
        if logic_moment.IsCanOpenSelfMoment(false) and LobbySocialSystem.IsSelf(self.currUID) then
          self:SetWidgetVisible(self.UIRoot.Moment_Reddot, value)
        end
        self:UpdateMomentBubbleTips()
      end)
    end
  end
  self:UpdateMomentBubbleTips()
end
function LobbySocialLeftMessage:UpdateMomentBubbleTips(bResetLastShow)
  log(bWriteLog and "[v_wllwu] LobbySocialLeftMessage:UpdateMomentBubbleTips")
  local logic_moment = require("client.slua.logic.moment.logic_moment")
  if not logic_moment.IsCanOpenSelfMoment(false) or not LobbySocialSystem.IsSelf(self.currUID) then
    self:HideMomentBubbleTips()
    return
  end
  if bResetLastShow then
    self.lastShowBubbleTipID = nil
  else
    self.lastShowBubbleTipID = self.momentBubbleID
  end
  local logic_moment_bubble_tips = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_moment_bubble_tips)
  self.momentBubbleID = logic_moment_bubble_tips:GetBubbleTipsID()
  log(bWriteLog and "[v_wllwu] LobbySocialLeftMessage:UpdateMomentBubbleTips self.momentBubbleID = " .. tostring(self.momentBubbleID) .. " self.lastShowBubbleTipID = " .. tostring(self.lastShowBubbleTipID))
  if not self.momentBubbleID then
    self:HideMomentBubbleTips()
    return
  end
  if self.lastShowBubbleTipID and self.lastShowBubbleTipID == self.momentBubbleID then
    log(bWriteLog and "[v_wllwu] self.lastShowBubbleTipID error")
    return
  end
  local str = logic_moment_bubble_tips:GetBubbleTipsContent(self.momentBubbleID)
  if not str or str == "" then
    log(bWriteLog and "[v_wllwu] LobbySocialLeftMessage:UpdateMomentBubbleTips str is nil")
    self:HideMomentBubbleTips()
    return
  end
  self.UIRoot.TextBlock_MomentBubble:SetText(str)
  self:SetWidgetVisible(self.UIRoot.CanvasPanel_MomentBubble, true)
  logic_moment_bubble_tips:UpdateShowBubbleTipsID(self.momentBubbleID)
  self:RemoveMomentBubbleTimer()
  self.momentBubbleTipsTimer = self:AddTimerOnce(logic_moment_bubble_tips.autoHideBubbleTipsTime, function()
    self:SetWidgetVisible(self.UIRoot.CanvasPanel_MomentBubble, false)
  end)
end
function LobbySocialLeftMessage:HideMomentBubbleTips()
  self.momentBubbleID = nil
  self:RemoveMomentBubbleTimer()
  self:SetWidgetVisible(self.UIRoot.CanvasPanel_MomentBubble, false)
end
function LobbySocialLeftMessage:RemoveMomentBubbleTimer()
  if self.momentBubbleTipsTimer then
    self:RemoveTimer(self.momentBubbleTipsTimer)
    self.momentBubbleTipsTimer = nil
  end
end
function LobbySocialLeftMessage:OnButton_MomentClick()
  self:PlayAudio(sound_config.click_v1)
  log(bWriteLog and "LobbySocialLeftMessage:OnButton_MomentClick")
  local logic_moment_background = require("client.slua.logic.moment.logic_moment_background")
  local localRedDotFileTb = logic_moment_background.GetLocalRedDotFileTb()
  local logic_moment_bubble_tips = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_moment_bubble_tips)
  if localRedDotFileTb[1] == nil then
    localRedDotFileTb[1] = 1
    logic_moment_background.SaveLocalRedDotFileTb()
    logic_moment_bubble_tips:RemovePersonalBubble(logic_moment_bubble_tips.Enum_BubbleTipsID.BackGround)
    EventSystem:postEvent(EVENTTYPE_MOMENT, EVENTID_MOMENT_BackGround_GETNEWBG)
  end
  if self.momentBubbleID ~= nil then
    logic_moment_bubble_tips:SetRemoveTips(self.momentBubbleID)
  end
  local logic_moment = require("client.slua.logic.moment.logic_moment")
  if logic_moment.IsCanOpenSelfMoment(false) and LobbySocialSystem.IsSelf(self.currUID) then
    local moment_reddot_data = require("client.slua.logic.moment.moment_reddot_data")
    moment_reddot_data.TryClearNewGuide()
  end
  logic_moment.EnterMomentUI(self.currUID)
end
function LobbySocialLeftMessage:RefreshCollectHallEntranceButton()
  local Logic_SC_DownloadTools = require("client.slua.logic.lobby.Left.SocialLobby.Logic_SC_DownloadTools")
  local bIsShow = Logic_SC_DownloadTools.GetPlanCHIsOpen()
  local uNode_root = self.UIRoot
  self:SetWidgetVisible(uNode_root.CanvasPanel_CollectHallEntrance, bIsShow, false)
  if not bIsShow then
    return
  end
  local Logic_SocialLobbyModule = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.Logic_SocialLobbyModule)
  local nLevel = Logic_SocialLobbyModule:GetCollectHallLevel(self.currUID)
  uNode_root.TextBlock_CollectHall:SetText(LocUtil.GetLocalizeResStr(880060064))
end
function LobbySocialLeftMessage:OnCollectHallLevelChangeEvent()
  if not self.bSelf then
    return
  end
  self:RefreshCollectHallEntranceButton()
end
function LobbySocialLeftMessage:UpdateClubButton()
  log(bWriteLog and "LobbySocialLeftMessage:UpdateClubButton")
  self.isClubVisible = false
  self.UIRoot.TextBlock_6:SetText(LocUtil.LocalizeResFormat(23577))
  self:SetWidgetFoldVisible(self.UIRoot.Button_Club, false)
  if not LobbySocialSystem.IsSelf(self.currUID) then
    local logic_community = require("client.slua.logic.community.logic_community")
    if logic_community.GetShowEntry() then
      logic_community.IsUserClubMember(self.currUID, self.UIRoot, function(bIsMember)
        if bIsMember then
          if slua.isValid(self.UIRoot) then
            self:SetWidgetFoldVisible(self.UIRoot.Button_Club, true, true)
            self.isClubVisible = true
          end
        else
          log(bWriteLog and "LobbySocialLeftMessage:UpdateClubButton not member")
        end
      end)
    else
      log(bWriteLog and "LobbySocialLeftMessage:UpdateClubButton not show entry")
    end
  else
    log(bWriteLog and "LobbySocialLeftMessage:UpdateClubButton self")
  end
end
function LobbySocialLeftMessage:OnButton_ClubClick()
  log(bWriteLog and " LobbySocialLeftMessage:OnButton_ClubClick ")
  self:PlayAudio(sound_config.new_corpsBtn)
  if not self.isSocial then
    EventSystem:postEvent(EVENTTYPE_COMMUNITY, EVENTID_COMMUNITY_GOTO_CLUB_USERPROFILE, self.currUID)
  end
end
function LobbySocialLeftMessage:ReqAuthorInfo()
  if self.bWOWOpen then
    local LogicUGCAuthor = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicUGCAuthor)
    LogicUGCAuthor:RequestAuthorInfo(self.currUID)
  else
    log(bWriteLog and "[v_yibxu]  LobbySocialLeftMessage:ReqAuthorInfo self.bWOWOpen = " .. tostring(self.bWOWOpen))
  end
end
function LobbySocialLeftMessage:OnGetUGCAuthorData(_, _, uid)
  log(bWriteLog and "LobbySocialLeftMessage:OnGetUGCAuthorData uid = " .. tostring(uid))
  self:UpdateUGCButton(uid)
  self:UpdateFoldButton()
end
function LobbySocialLeftMessage:OnGetMyUGCData()
  log(bWriteLog and "LobbySocialLeftMessage:OnGetMyUGCData")
  self:UpdateUGCButton(tonumber(DataMgr.roleData.uid))
  self:UpdateFoldButton()
end
function LobbySocialLeftMessage:UpdateUGCButton(uid)
  log(bWriteLog and "LobbySocialLeftMessage:UpdateUGCButton uid = " .. tostring(uid))
  self.isWowVisible = false
  local curUid = tonumber(self.currUID)
  uid = uid or curUid
  if not curUid or curUid ~= tonumber(uid) then
    log(bWriteLog and "LobbySocialLeftMessage:UpdateUGCButton curUid = " .. tostring(curUid) .. " ~= uid = " .. tostring(uid))
    return
  end
  self:SetWidgetFoldVisible(self.UIRoot.Button_Wow, false, true)
  if not self.bWOWOpen then
    log(bWriteLog and "LobbySocialLeftMessage:UpdateUGCButton self.bWOWOpen = " .. tostring(self.bWOWOpen))
    return
  end
  local LogicUGCAuthor = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicUGCAuthor)
  if not LogicUGCAuthor:NewCheckPlayerIsAuthor(tonumber(self.currUID), true) then
    log(bWriteLog and "LobbySocialLeftMessage:UpdateUGCButton curUid = " .. tonumber(self.currUID) .. " is not author")
    return
  end
  if LogicUGCAuthor:CheckPlayerIsBanned(tonumber(self.currUID)) then
    log(bWriteLog and "LobbySocialLeftMessage:UpdateUGCButton curUid = " .. tonumber(self.currUID) .. "is ban")
    return
  end
  self.isWowVisible = true
  self:SetWidgetFoldVisible(self.UIRoot.Button_Wow, true, true)
  local AuthorInfo = LogicUGCAuthor:GetAuthorInfo(tonumber(self.currUID))
  if AuthorInfo then
    local level = AuthorInfo.new_level or AuthorInfo.level or 0
    self:UpdateAuthorInfo(level)
  else
    self:UpdateAuthorInfo(0)
  end
end
function LobbySocialLeftMessage:OnButton_WowClick()
  log(bWriteLog and " LobbySocialLeftMessage:OnButton_ClubClick ")
  self:PlayAudio(sound_config.click_v1)
  if self.bWOWOpen then
    local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
    RoleInfoMainSystem.Show(RoleInfoMainSystem.WOW, RoleInfoMainSystem.RoleInfoOpenFromType.WoWItem, self.currUID)
    local roleInfoUI = UIManager.GetUI(UIManager.UI_Config.roleinfo_main)
    if roleInfoUI then
      roleInfoUI.TabID = RoleInfoMainSystem.WOW
      roleInfoUI:UpdateUI()
    end
  else
    log(bWriteLog and "[v_yibxu] LobbySocialLeftMessage:OnButton_ClubClick bWOWOpen false")
  end
end
function LobbySocialLeftMessage:OnButton_CollectHallClick()
  self:PlayAudio(sound_config.click_v1)
  local LogicCollectionHallEntry = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicCollectionHallEntry)
  local Enum_EnterPlanCHSource = LogicCollectionHallEntry.Enum_EnterPlanCHSource
  LogicCollectionHallEntry:EntryVisitCollectionHall(self.currUID, Enum_EnterPlanCHSource.SocialLobby, true)
end
function LobbySocialLeftMessage:UpdateAuthorInfo(level)
  local Config_UGC = require("client.slua.logic.ugc.config_ugc")
  local authorLevelConfig = Config_UGC.GetAuthorLevelConfigByID(level)
  self.UIRoot.WidgetSwitcher_WOW:SetActiveWidgetIndex(1)
  local imagePath
  if authorLevelConfig then
    imagePath = authorLevelConfig.PageIcon
  else
    imagePath = "/Game/UMG/Texture_200/Lobby_NoAtlas/Ugc/CreatorLv/CreatorLv_Image_Lv_01.CreatorLv_Image_Lv_01"
  end
  self:SetTexture(self.UIRoot.Image_Lv, imagePath, {bMatchSize = true})
end
function LobbySocialLeftMessage:UpdatePHome()
  if not self._cObj_homeEntranceUIBP then
    self._cObj_homeEntranceUIBP = self:CreateChildWindow(self.UIRoot.CanvasPanel_Door, UIManager.UI_Config.Lobby_Home_Door_Entrance_UIBP, self.currUID)
  else
    self._cObj_homeEntranceUIBP:UpdateUI(self.currUID)
  end
end
function LobbySocialLeftMessage:RequestHomeData()
  local uid = tonumber(self.currUID)
  local logic_home_switch = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_home_switch)
  if not logic_home_switch:CheckHomeSwitchOpen() then
    log(bWriteLog and string.format("LobbySocialLeftMessage:RequestHomeData, not logic_home_switch:CheckHomeSwitchOpen()"))
    self:SetPlanPHPartyVisible(false)
    return
  end
  local logic_home_profile = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_home_profile)
  logic_home_profile:GetOrReqHomeProfile({uid}, function()
    local profile = logic_home_profile:GetHomeProfileByUid(uid)
    if not profile then
      log(bWriteLog and string.format("LobbySocialLeftMessage:RequestHomeData, logic_home_profile:GetOrReqHomeProfile, not profile. uid or self.currUID: %s", uid))
      return
    end
    if not profile.bUnLock then
      log(bWriteLog and string.format("LobbySocialLeftMessage:RequestHomeData, profile bUnLock is false"))
      self:SetPlanPHPartyVisible(false)
      return
    end
    local logic_home_detail = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_home_detail)
    logic_home_detail:GetOrReqHomeDetail(uid, function(uid, detail)
      log(bWriteLog and string.format("LobbySocialLeftMessage:RequestHomeData, logic_home_detail:GetOrReqHomeDetail, uid: %s", uid))
      log_tree(bWriteLog and "LobbySocialLeftMessage:RequestHomeData, logic_home_detail:GetOrReqHomeDetail, detail:", detail)
      self.playerDetail = detail
      self:RefreshPlanPHParty(uid, detail.party_show_info)
      local HomeWeddingUtil = require("client.slua.logic.homewedding.HomeWeddingUtil")
      local bIsBondingSystem = HomeWeddingUtil.IsShowWeddingEntry()
      if bIsBondingSystem and detail and next(detail) and detail.soulmate_ceremony then
        self:UpdateWeddingInfo(uid, detail.soulmate_ceremony)
      else
        log(bWriteLog and "LobbySocialLeftMessage:RequestHomeData - not detail.soulmate_ceremony")
      end
    end, true)
  end)
end
function LobbySocialLeftMessage:RequestHomePKInfo()
  log(bWriteLog and "LobbySocialLeftMessage:RequestHomePKInfo")
  local uid = tonumber(self.currUID)
  local logic_popular_home_pk = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_popular_home_pk)
  local PopularHomePKMacros = require("client.slua.logic.popular_home_pk.popular_home_pk_macros")
  local logic_popular_home_pk_util = require("client.slua.logic.popular_home_pk.logic_popular_home_pk_util")
  local actState = logic_popular_home_pk_util.GetActState()
  if actState ~= PopularHomePKMacros.ENUM_STATE.SIGN then
    log(bWriteLog and "LobbySocialLeftMessage:RequestHomePKInfo, act is not sign")
    return
  end
  if not logic_popular_home_pk:IsHomePkDataValid(tonumber(uid), 2) then
    logic_popular_home_pk:RequestGetHomePKData(tonumber(uid))
    log(bWriteLog and "LobbySocialLeftMessage:RequestHomePKInfo not valid pk data ")
    return
  end
  local detail = self.playerDetail
  if detail and detail.party_show_info then
    self:RefreshPlanPHPK(uid, detail.party_show_info)
  elseif self.playerDetail and self.playerDetail.soulmate_ceremony then
    self:RefreshPlanPHPK(uid, self.playerDetail.soulmate_ceremony)
  else
    self:RefreshPlanPHPK(uid, nil)
  end
end
function LobbySocialLeftMessage:RefreshPlanPHParty(uid, partyInfo)
  log(bWriteLog and string.format("LobbySocialLeftMessage:RefreshPlanPHParty"))
  if not slua.isValid(self.UIRoot) then
    log(bWriteLog and string.format("LobbySocialLeftMessage:RefreshPlanPHParty, not slua.isValid(self.UIRoot)"))
    return
  end
  log(bWriteLog and string.format("LobbySocialLeftMessage:RefreshPlanPHParty, uid: %s", uid))
  if partyInfo == nil then
    log(bWriteLog and string.format("LobbySocialLeftMessage:RefreshPlanPHParty, partyInfo == nil"))
    self:SetPlanPHPartyVisible(false)
    return
  end
  log_tree(bWriteLog and "LobbySocialLeftMessage:RefreshPlanPHParty, partyInfo:", partyInfo)
  local HomePartyUtil = require("client.slua.logic.homeparty.HomePartyUtil")
  local isShowParty = HomePartyUtil.IsShowParty(uid, partyInfo)
  self:SetPlanPHPartyVisible(isShowParty)
  log(bWriteLog and string.format("LobbySocialLeftMessage:RefreshPlanPHParty, isShowParty: %s", isShowParty))
  self:RefreshHomePartyEntranceUIBP(uid, partyInfo)
end
function LobbySocialLeftMessage:RefreshPlanPHPK(uid, partyInfo)
  log(bWriteLog and string.format("LobbySocialLeftMessage:RefreshPlanPHPK"))
  if not slua.isValid(self.UIRoot) then
    log(bWriteLog and string.format("LobbySocialLeftMessage:RefreshPlanPHPK, not slua.isValid(self.UIRoot)"))
    return
  end
  log(bWriteLog and string.format("LobbySocialLeftMessage:RefreshPlanPHPK, uid: %s", uid))
  local UIRoot = self.UIRoot
  if partyInfo ~= nil then
    log_tree(bWriteLog and "LobbySocialLeftMessage:RefreshPlanPHPK, partyInfo:", partyInfo)
    local HomePartyUtil = require("client.slua.logic.homeparty.HomePartyUtil")
    local isShowParty = HomePartyUtil.IsShowParty(uid, partyInfo)
    log(bWriteLog and string.format("LobbySocialLeftMessage:RefreshPlanPHPK, isShowParty: %s", isShowParty))
    if isShowParty then
      self:SetPlanPHPKVisible(false)
      return
    end
  end
  local PopularHomePKMacros = require("client.slua.logic.popular_home_pk.popular_home_pk_macros")
  local logic_popular_home_pk_util = require("client.slua.logic.popular_home_pk.logic_popular_home_pk_util")
  local actState = logic_popular_home_pk_util.GetActState()
  if actState ~= PopularHomePKMacros.ENUM_STATE.SIGN then
    log(bWriteLog and "LobbySocialLeftMessage:RefreshPlanPHPK, act is not sign")
    return
  end
  local logic_popular_home_pk = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_popular_home_pk)
  if not logic_popular_home_pk:CanShowTipsEntry(tonumber(uid)) then
    log(bWriteLog and "LobbySocialLeftMessage:RefreshPlanPHPK can not show tips")
    return
  end
  if self.homePKTipsUI == nil then
    self.homePKTipsUI = self:CreateChildWindow(UIRoot.CanvasPanel_PK, UIManager.UI_Config.HomePK_Condition_Tips_UIBP, uid)
  end
  self:SetPlanPHPKVisible(true)
end
function LobbySocialLeftMessage:SetPlanPHPartyVisible(isPartyVisible)
  log(bWriteLog and string.format("LobbySocialLeftMessage:SetPlanPHPartyVisible, isPartyVisible: %s", isPartyVisible))
  if not slua.isValid(self.UIRoot) then
    log(bWriteLog and string.format("LobbySocialLeftMessage:SetPlanPHPartyVisible, not slua.isValid(self.UIRoot)"))
    return
  end
  local UIRoot = self.UIRoot
  self:SetWidgetVisible(UIRoot.CanvasPanel_Party, isPartyVisible, false)
  EventSystem:postEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_LOBBY_SOCIAL_SET_UI_SHOW_PK_CANVAS, not isPartyVisible)
end
function LobbySocialLeftMessage:SetPlanPHPKVisible(isHomePKVisible)
  log(bWriteLog and string.format("LobbySocialLeftMessage:SetPlanPHPKVisible, isHomePKVisible: %s", isHomePKVisible))
  if not slua.isValid(self.UIRoot) then
    log(bWriteLog and string.format("LobbySocialLeftMessage:SetPlanPHPKVisible, not slua.isValid(self.UIRoot)"))
    return
  end
  local UIRoot = self.UIRoot
  self:SetWidgetVisible(UIRoot.CanvasPanel_PK, isHomePKVisible, false)
end
function LobbySocialLeftMessage:OnHomePkCfgUpdate()
  log(bWriteLog and "LobbySocialLeftMessage:OnHomePkCfgUpdate")
  local PopularHomePKMacros = require("client.slua.logic.popular_home_pk.popular_home_pk_macros")
  local logic_popular_home_pk_util = require("client.slua.logic.popular_home_pk.logic_popular_home_pk_util")
  local actState = logic_popular_home_pk_util.GetActState()
  if actState ~= PopularHomePKMacros.ENUM_STATE.SIGN then
    log(bWriteLog and "LobbySocialLeftMessage:OnHomePkCfgUpdate, act is not sign")
    return
  end
  self:RequestHomePKInfo()
end
function LobbySocialLeftMessage:OnPopularHomePKDataUpdate(_, _, target_uid)
  log(bWriteLog and "LobbySocialLeftMessage:OnPopularHomePKDataUpdate")
  local uid = tonumber(self.currUID)
  if self.playerDetail and self.playerDetail.party_show_info then
    local partyInfo = self.playerDetail.party_show_info
    self:RefreshPlanPHPK(uid, partyInfo)
  elseif self.playerDetail and self.playerDetail.soulmate_ceremony then
    self:RefreshPlanPHPK(uid, self.playerDetail.soulmate_ceremony)
  else
    self:RefreshPlanPHPK(uid, nil)
  end
end
function LobbySocialLeftMessage:UpdateWeddingInfo(uid, weddingInfo)
  log(bWriteLog and "LobbySocialLeftMessage:UpdateWeddingInfo")
  if not slua.isValid(self.UIRoot) then
    log(bWriteLog and string.format("LobbySocialLeftMessage:UpdateWeddingInfo, not slua.isValid(self.UIRoot)"))
    return
  end
  log(bWriteLog and string.format("LobbySocialLeftMessage:UpdateWeddingInfo, uid: %s", uid))
  if weddingInfo == nil then
    log(bWriteLog and string.format("LobbySocialLeftMessage:UpdateWeddingInfo, weddingInfo == nil"))
    self:SetPlanPHPartyVisible(false)
    return
  end
  log_tree(bWriteLog and "LobbySocialLeftMessage:UpdateWeddingInfo, weddingInfo:", weddingInfo)
  local HomeWeddingUtil = require("client.slua.logic.homewedding.HomeWeddingUtil")
  local isShowWedding = HomeWeddingUtil.IsShowWedding(uid, weddingInfo)
  self:SetPlanPHPartyVisible(isShowWedding)
  log(bWriteLog and string.format("LobbySocialLeftMessage:UpdateWeddingInfo, isShowWedding: %s", isShowWedding))
  self:RefreshHomePartyEntranceUIBP(uid, weddingInfo, true)
end
function LobbySocialLeftMessage:RefreshHomePartyEntranceUIBP(uid, partyInfo, bIsWedding)
  if not self._cObj_partyEntranceUIBP then
    self._cObj_partyEntranceUIBP = self:CreateChildWindow(self.UIRoot.CanvasPanel_Party, UIManager.UI_Config.Lobby_Home_Party_Entrance_UIBP, {
      uid = uid,
      partyInfo = partyInfo,
      bIsWedding = bIsWedding
    })
  else
    self._cObj_partyEntranceUIBP:UpdateUI(uid, partyInfo, true)
  end
end
function LobbySocialLeftMessage:RegistEvents_Popularity()
  self:AddOnClickedEventByControl(self.UIRoot.Button_Popularity, self.OnButton_PopularityClick, self)
  self:AddCommonEvent(EVENTTYPE_PERSON_SPACE, EVENTID_POPULARITY_GET_POPULARITY_RSP, self.OnGetPopularityRsp, self)
  self:AddCommonEvent(EVENTTYPE_PERSON_SPACE, EVENTID_POPULARITY_GET_POPULARITY_SIMPLE_RSP, self.UpdatePopularityButton, self)
  self:AddCommonEvent(EVENTTYPE_PERSON_SPACE, EVENTID_POPULARITY_REDDOT_CHANGE, self.UpdatePopularityReddot, self)
  self:AddCommonEvent(EVENTTYPE_PERSON_SPACE, EVENTID_POPULAR_GIFT_PK_STATUS, self.OnGetPopularPkStatus, self)
  self:AddCommonEvent(EVENTTYPE_PERSON_SPACE, EVENTID_POPULAR_GIFT_PK_LEVEL_REWARD_STATUS, self.OnGetPopularPkRewardStatus, self)
  self:AddCommonEvent(EVENTTYPE_PERSON_SPACE, EVENTID_PERSONSPACE_SHOW_NEXT_TIPS, self.OnShowNextTips, self)
  self:AddCommonEvent(EVENTTYPE_POPULAR_TEAMPK, EVENTID_POPULAR_TEAM_PK_CONFIG_UPDATE, self.OnGetPopularTeamPKConfig, self)
  self:AddCommonEvent(EVENTTYPE_POPULAR_TEAMPK, EVENTID_POPULAR_TEAM_PK_DATA_UPDATE, self.OnTeamPkDataUpdate, self)
end
function LobbySocialLeftMessage:UpdatePopularityButton(_, _, currUID)
  log(bWriteLog and "LobbySocialLeftMessage:UpdatePopularityButton")
  if not self.currUID then
    log(bWriteLog and "LobbySocialLeftMessage:UpdatePopularityButton currUID is nil")
    return
  end
  currUID = currUID or tonumber(self.currUID)
  if currUID and tonumber(currUID) ~= tonumber(self.currUID) then
    return
  end
  self:UpdatePopularityReddot()
  local bSelf = self.currUID and tonumber(self.currUID) == tonumber(DataMgr.roleData.uid)
  local RoleInfoPopularitySystem = require("client.slua.logic.person_space.logic_roleinfo_popularity")
  local SimpleInfo = RoleInfoPopularitySystem.PopularitySimpleCache[tostring(currUID)]
  if SimpleInfo then
    local popularityLevel = RoleInfoPopularitySystem.GetPopularityLevelByExp(SimpleInfo.total_devote)
    self.UIRoot.PopularityCount:SetText(LocUtil.LocalizeResFormat(6417, popularityLevel))
    local isShowDetailRaw = RoleInfoPopularitySystem.GetIsShowDetail(currUID)
    local IsShowDetail = isShowDetailRaw or bSelf
    if LobbySystem.CheckOpen(BP_ENUM_ONLY_FRIENFRIEND_PRIVACY) and not bSelf then
      if isShowDetailRaw == 0 then
        IsShowDetail = false
        self.UIRoot.PopularityCount:SetText(LocUtil.LocalizeResFormat(6417, 0))
      elseif isShowDetailRaw == 1 then
        IsShowDetail = true
      elseif isShowDetailRaw == 2 then
        local LogicFriend = require("client.slua.logic.friend.logic_new_friend")
        if not LogicFriend.IsMyFriend(currUID) then
          IsShowDetail = false
          self.UIRoot.PopularityCount:SetText(LocUtil.LocalizeResFormat(6417, 0))
        else
          IsShowDetail = true
        end
      end
    end
    local texture_path = RoleInfoPopularitySystem.GetPopularityTexture(SimpleInfo.total_devote, IsShowDetail)
    local UIUtil = require("client.common.ui_util")
    self.UIRoot.ScaleBox_Popularity:SetWidgetVisibility(UIUtil.BoolToVisible(IsShowDetail))
    if texture_path and texture_path ~= "" then
      self:SetTexture(self.UIRoot.Image_Popularity, texture_path)
    end
    local is_show_detail = bSelf or SimpleInfo.is_show_detail
    if not LobbySystem.CheckOpen(BP_ENUM_ONLY_FRIENFRIEND_PRIVACY) then
      self.UIRoot.ScaleBox_Popularity:SetWidgetVisibility(UIUtil.BoolToVisible(is_show_detail))
    end
  else
    local UIUtil = require("client.common.ui_util")
    self.UIRoot.ScaleBox_Popularity:SetWidgetVisibility(UIUtil.BoolToVisible(false))
  end
end
function LobbySocialLeftMessage:OnButton_PopularityClick()
  log(bWriteLog and "LobbySocialLeftMessage:OnButton_PopularityClick")
  self:PlayAudio(sound_config.click_v1)
  local bSelf = self.currUID and tonumber(self.currUID) == tonumber(DataMgr.roleData.uid)
  local RoleInfoPopularitySystem = require("client.slua.logic.person_space.logic_roleinfo_popularity")
  RoleInfoPopularitySystem.OpenPopularityUI(self.currUID)
  gem_report_utils.ReportBtnClickEvent(gem_report_utils.SubEventName_PersonSpacePopularity)
  local tlog_report_utils = require("client.slua.config.tlog.tlog_report_utils")
  if tonumber(self.currUID) == tonumber(DataMgr.roleData.uid) then
    tlog_report_utils.ReportTLogEvent(TLogEventDefine.PersonSpacePopularity)
  else
    tlog_report_utils.ReportTLogEvent(TLogEventDefine.PersonSpacePopularityGuest)
  end
  if not bSelf then
    log(bWriteLog and "LobbySocialLeftMessage:OnButton_PopularityClick is not self")
    return
  end
  if not RoleInfoPopularitySystem.CheckNeedGuidePopup() then
    log(bWriteLog and "LobbySocialLeftMessage:OnButton_PopularityClick CheckNeedGuidePopup false")
    return
  end
  local popupConfig = CDataTable.GetTable("GiftPopupConfig")
  local slapData = {
    title = LocUtil.GetLocalizeResStr(43293),
    descTitles = {},
    descriptions = {},
    showImagePaths = {}
  }
  for k, v in pairs(popupConfig) do
    table.insert(slapData.descTitles, v.Title)
    table.insert(slapData.descriptions, v.Desc)
    table.insert(slapData.showImagePaths, v.ImagePath)
  end
  UIManager.ShowUI(UIManager.UI_Config.Common_Announcement_UIBP, slapData)
  RoleInfoPopularitySystem.SaveGuidePopupData()
end
function LobbySocialLeftMessage:UpdatePopularityReddot()
  if not self.UIRoot.popularity_reddot then
    return
  end
  if not slua.isValid(self.UIRoot) then
    return
  end
  if not self.bSelf then
    return
  end
  local RoleInfoPopularitySystem = require("client.slua.logic.person_space.logic_roleinfo_popularity")
  if RoleInfoPopularitySystem.CheckNeedGuidePopup() then
    self:SetWidgetVisible(self.UIRoot.popularity_reddot, true)
    return
  end
  local logic_popular_pk_reddot = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_popular_pk_reddot)
  if logic_popular_pk_reddot:NeedShowReddot() then
    self:SetWidgetVisible(self.UIRoot.popularity_reddot, true)
    return
  end
  local logic_popular_team_pk = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_popular_team_pk)
  if logic_popular_team_pk:IsShowRedDot() then
    self:SetWidgetVisible(self.UIRoot.popularity_reddot, true)
    return
  end
  local SocialReddotSystem = require("client.slua.logic.lobby.Left.logic_social_reddot")
  self:SetWidgetVisible(self.UIRoot.popularity_reddot, SocialReddotSystem.HavePopularityReddot(self.currUID))
end
function LobbySocialLeftMessage:OnGetPopularPkRewardStatus()
  if not self.bSelf then
    return
  end
  log(bWriteLog and "LobbySocialLeftMessage:OnGetPopularPkRewardStatus")
  self:UpdatePopularityReddot()
end
local LobbySocialMacro = require("client.slua.logic.lobby.Left.lobby_social_macro")
local Enum_TipType = LobbySocialMacro.EnumPopularTipType
function LobbySocialLeftMessage:InitShowTipData()
  log(bWriteLog and "LobbySocialLeftMessage:InitShowTipData")
  self.waitShowTipType = Enum_TipType.none
  self.inShowingTipType = Enum_TipType.none
  self:SetWidgetVisible(self.UIRoot.CanvasPanel_Top3, false)
end
function LobbySocialLeftMessage:StartShowTips()
  log(bWriteLog and "LobbySocialLeftMessage:StartShowTips")
  if self.isSocial and not self.isInSocialLobby then
    log(bWriteLog and "[v_wllwu] LobbySocialLeftMessage:StartShowTips return when not in social lobby")
    return
  end
  self:InitShowTipData()
  local bIsGuest = not LobbySocialSystem.IsSelf(self.currUID)
  if bIsGuest then
    self:AddTimerOnce(1, function()
      log(bWriteLog and "LobbySocialLeftMessage:StartShowTips delay show tips")
      self:ShowNextTips()
    end)
  else
    self:ShowNextTips()
  end
end
function LobbySocialLeftMessage:OnUpdateProfilePopularity(uid)
  log(bWriteLog and "LobbySocialLeftMessage:OnUpdateProfilePopularity uid = " .. tostring(uid))
  if not uid or tonumber(uid) ~= tonumber(self.currUID) then
    log(bWriteLog and "[v_wllwu] LobbySocialLeftMessage:OnUpdateProfilePopularity return 1, uid is?" .. tostring(uid))
    return
  end
  if tonumber(self.currUID) == tonumber(DataMgr.roleData.uid) then
    log(bWriteLog and "[v_wllwu] LobbySocialLeftMessage:OnUpdateProfilePopularity return 2")
    return
  end
  if self.isGetOtherProfile then
    return
  end
  self.isGetOtherProfile = true
  log(bWriteLog and "[v_wllwu] LobbySocialLeftMessage:OnUpdateProfilePopularity enter")
  if self.waitShowTipType == Enum_TipType.popular_pk or self.waitShowTipType == Enum_TipType.team_pk then
    self:ShowNextTips(nil, self.waitShowTipType)
  end
end
function LobbySocialLeftMessage:OnShowNextTips(_, _, tipsType)
  log(bWriteLog and "[v_wllwu] LobbySocialLeftMessage:OnShowNextTips, tipsType is:" .. tostring(tipsType))
  if self.waitShowTipType ~= tipsType then
    return
  end
  log(bWriteLog and "[v_wllwu] LobbySocialLeftMessage:OnShowNextTips enter")
  self:ClearAutoHideTipTimer()
  self:CloseTips(self.waitShowTipType)
  self:ShowNextTips()
end
function LobbySocialLeftMessage:OnGetPopularityRsp(_, _, uid)
  log(bWriteLog and "[LobbySocialLeftMessage] OnGetPopularityRsp: " .. tostring(uid))
  self.sendTipsUid = uid
  self:ShowPopularityTop3()
end
function LobbySocialLeftMessage:OnGetPopularPkStatus(_, __, uid)
  if uid ~= tonumber(self.currUID) then
    return
  end
  log(bWriteLog and "[v_wllwu] LobbySocialLeftMessage:OnGetPopularPkStatus enter")
  self:UpdateSocialTips(Enum_TipType.popular_pk, true)
  self:UpdatePopularityReddot()
end
function LobbySocialLeftMessage:OnGetPopularTeamPKConfig()
  log(bWriteLog and "[v_wllwu] LobbySocialLeftMessage:OnGetPopularTeamPKConfig")
  self:UpdateSocialTips(Enum_TipType.team_pk)
end
function LobbySocialLeftMessage:OnTeamPkDataUpdate(_, __, uid)
  if uid ~= tonumber(self.currUID) then
    return
  end
  log(bWriteLog and "[v_wllwu] LobbySocialLeftMessage:OnTeamPkDataUpdate enter")
  self:UpdateSocialTips(Enum_TipType.team_pk, true)
  self:UpdatePopularityReddot()
end
function LobbySocialLeftMessage:ShowNextTips(banRequestData, tipType)
  log(bWriteLog and "[v_wllwu] LobbySocialLeftMessage:ShowNextTips banRequestData = " .. tostring(banRequestData) .. ", tipType = " .. tostring(tipType))
  local nextTipType = tipType or self.waitShowTipType + 1
  local tipList = self:GetTipList()
  if nextTipType > #tipList then
    self:OnTipsShowEndFunc()
    return
  end
  self.waitShowTipType = nextTipType
  if tonumber(self.currUID) ~= tonumber(DataMgr.roleData.uid) and not self.isGetOtherProfile then
    return
  end
  for i = nextTipType, #tipList do
    self.waitShowTipType = i
    if self:CheckCanShowOneTips(i, banRequestData and i == nextTipType) then
      return
    end
  end
  self:OnTipsShowEndFunc()
end
function LobbySocialLeftMessage:CheckCanShowOneTips(tipType, banRequestData)
  local tipList = self:GetTipList()
  local tipInfo = tipList[tipType]
  if not tipInfo then
    return false
  end
  local uid = tonumber(self.currUID)
  local logic_social_popularity_tips = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_social_popularity_tips)
  if not banRequestData and tipInfo.isNeedRequestDataFunc and logic_social_popularity_tips[tipInfo.isNeedRequestDataFunc](logic_social_popularity_tips, uid) then
    log(bWriteLog and "[v_wllwu] LobbySocialLeftMessage:CheckCanShowOneTips RequestData, showTipType is:" .. tostring(tipType))
    logic_social_popularity_tips[tipInfo.requestDataFunc](logic_social_popularity_tips, uid)
    return true
  end
  if logic_social_popularity_tips[tipInfo.checkShowFunc](logic_social_popularity_tips, uid) then
    if tipInfo.showFunc then
      self[tipInfo.showFunc](self)
    elseif tipInfo.uiName then
      self:CreateChildWindow(tipInfo.attachNodeName, UIManager.UI_Config[tipInfo.uiName], tipType, uid)
    end
    log(bWriteLog and "[v_wllwu] LobbySocialLeftMessage:CheckCanShowOneTips real show tips, tipType is:" .. tostring(tipType))
    self.inShowingTipType = tipType
    self:AddAutoHideTipTimer()
    return true
  end
  return false
end
function LobbySocialLeftMessage:AddAutoHideTipTimer()
  self:ClearAutoHideTipTimer()
  local tipList = self:GetTipList()
  local tipInfo = tipList[self.waitShowTipType]
  if not tipInfo then
    return
  end
  local time
  if tipInfo.getHideTimeFunc then
    local logic_social_popularity_tips = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_social_popularity_tips)
    time = logic_social_popularity_tips[tipInfo.getHideTimeFunc](logic_social_popularity_tips)
  end
  if not time or time <= 0 then
    return
  end
  self.autoHideTipsTimer = self:AddTimerOnce(time, function()
    self:CloseTips(self.waitShowTipType)
    self:ShowNextTips()
  end)
end
function LobbySocialLeftMessage:ClearAutoHideTipTimer()
  if self.autoHideTipsTimer then
    self:RemoveTimer(self.autoHideTipsTimer)
    self.autoHideTipsTimer = nil
  end
end
function LobbySocialLeftMessage:OnTipsShowEndFunc()
  log(bWriteLog and "[v_wllwu] LobbySocialLeftMessage:OnTipsShowEndFunc ")
  self.waitShowTipType = Enum_TipType.other
  self.inShowingTipType = Enum_TipType.none
  self:ShowPopularityTop3()
end
function LobbySocialLeftMessage:CloseTips(tipType)
  local tipList = self:GetTipList()
  local tipInfo = tipList[tipType]
  if not tipInfo then
    return
  end
  if tipInfo.hideFunc then
    self[tipInfo.hideFunc](self)
  elseif tipInfo.uiName then
    UIManager.CloseUI(UIManager.UI_Config[tipInfo.uiName])
  end
  self.inShowingTipType = Enum_TipType.none
end
function LobbySocialLeftMessage:GetTipList()
  local logic_social_popularity_tips = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_social_popularity_tips)
  return logic_social_popularity_tips.tipList
end
function LobbySocialLeftMessage:UpdateSocialTips(tipType, banRequestData)
  log(bWriteLog and "[v_wllwu] LobbySocialLeftMessage:UpdateSocialTips, self.waitShowTipType is: " .. tostring(tipType))
  if self.waitShowTipType ~= tipType or self.inShowingTipType == tipType then
    log(bWriteLog and "[v_wllwu] LobbySocialLeftMessage:UpdateSocialTips return, self.waitShowTipType is: " .. tostring(self.waitShowTipType))
    return
  end
  self:ShowNextTips(banRequestData, tipType)
end
function LobbySocialLeftMessage:ShowPopularityTop3()
  local uid = self.sendTipsUid
  if self.waitShowTipType ~= Enum_TipType.other then
    log(bWriteLog and "[v_wllwu] LobbyRightPopularityUI:ShowPopularityTop3 other tips is showing")
    return
  end
  if tonumber(uid) ~= tonumber(self.currUID) then
    log(bWriteLog and "LobbyRightPopularityUI:ShowPopularityTop3 uid not fetch")
    return
  end
  local RoleInfoPopularitySystem = require("client.slua.logic.person_space.logic_roleinfo_popularity")
  local PersonSpaceSystem = require("client.logic.personspace.logic_person_space")
  local devoteList = RoleInfoPopularitySystem.GetDevoteRank(uid) or {}
  local guardList = RoleInfoPopularitySystem.GetGuardRank(uid) or {}
  log(bWriteLog and "LobbyRightPopularityUI:ShowPopularityTop3 #devoteList = " .. tostring(#devoteList) .. ", #guardList = " .. tostring(#guardList))
  local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
  local ProfileInfo = logic_profile:GetLocalProfile(self.currUID)
  local psmatch_view_pk_switch
  if ProfileInfo then
    psmatch_view_pk_switch = ProfileInfo.psmatch_view_pk_switch
  end
  local bIsCanShow = true
  if LobbySystem.CheckOpen(BP_ENUM_ONLY_FRIENFRIEND_PRIVACY) then
    local LogicFriend = require("client.slua.logic.friend.logic_new_friend")
    if psmatch_view_pk_switch == 2 and not LogicFriend.IsMyFriend(uid) then
      bIsCanShow = false
    elseif psmatch_view_pk_switch == 1 then
      if #devoteList == 0 and #guardList == 0 then
        bIsCanShow = false
      end
    elseif psmatch_view_pk_switch == 0 then
      bIsCanShow = false
    end
  elseif #devoteList == 0 and #guardList == 0 then
    bIsCanShow = false
  end
  local PlayerPrefsSystem = require("client.logic.LogicPlayerPrefs.playerprefs")
  if not PlayerPrefsSystem.CheckAndSaveCurrentDate_N(PlayerPrefsSystem.ePlayerPrefsType.eLobbySocialPopularTop3Info, true, 1) then
    log(bWriteLog and "LobbyRightPopularityUI:ShowPopularityTop3 PlayerPrefsSystem.CheckAndSaveCurrentDate_N is false")
    bIsCanShow = false
  end
  if not bIsCanShow then
    self:SetWidgetVisible(self.UIRoot.CanvasPanel_Top3, false)
    return
  end
  local topUIDList = {}
  local popularityTopUIDInfo = {}
  local maxCandidateCount = 10
  local popularityTopLength = math.min(#devoteList, maxCandidateCount)
  for i = 1, popularityTopLength do
    table.insert(topUIDList, devoteList[i].uid)
    table.insert(popularityTopUIDInfo, {
      uid = devoteList[i].uid
    })
  end
  local guardTopUIDInfo = {}
  local guardTopLength = math.min(#guardList, maxCandidateCount)
  for i = 1, guardTopLength do
    table.insert(topUIDList, guardList[i].uid)
    table.insert(guardTopUIDInfo, {
      uid = guardList[i].uid
    })
  end
  local logic_profile_get_wrap = require("client.slua.logic.user.profile.logic_profile_get_wrap")
  logic_profile_get_wrap.GetNormalProfiles(topUIDList, function(list)
    if not self.UIRoot then
      log(bWriteLog and "LobbyRightPopularityUI:ShowPopularityTop3 not self.UIRoot")
      return
    end
    for j, currProfile in pairs(list) do
      for i, data in ipairs(popularityTopUIDInfo) do
        if tonumber(data.uid) == tonumber(currProfile.uid) then
          PersonSpaceSystem.AddProfileData(data, currProfile)
        end
      end
      for i, data in ipairs(guardTopUIDInfo) do
        if tonumber(data.uid) == tonumber(currProfile.uid) then
          PersonSpaceSystem.AddProfileData(data, currProfile)
        end
      end
    end
    local filteredPopularityList = {}
    for i, data in ipairs(popularityTopUIDInfo) do
      local bIsBanned = logic_profile:IsPlayerBanned(data.uid)
      if not bIsBanned then
        table.insert(filteredPopularityList, data)
        if 3 <= #filteredPopularityList then
          break
        end
      else
        log(bWriteLog and string.format("LobbyRightPopularityUI:ShowPopularityTop3 - Filtered banned player from popularity rank, uid=%s", tostring(data.uid)))
      end
    end
    popularityTopUIDInfo = filteredPopularityList
    local filteredGuardList = {}
    for i, data in ipairs(guardTopUIDInfo) do
      local bIsBanned = logic_profile:IsPlayerBanned(data.uid)
      if not bIsBanned then
        table.insert(filteredGuardList, data)
        if 3 <= #filteredGuardList then
          break
        end
      else
        log(bWriteLog and string.format("LobbyRightPopularityUI:ShowPopularityTop3 - Filtered banned player from guard rank, uid=%s", tostring(data.uid)))
      end
    end
    guardTopUIDInfo = filteredGuardList
    local bNeedPlayNext = false
    local cObj_popularPKTop3 = self:GetPopularPKTop3UI()
    if 0 < #popularityTopUIDInfo then
      bNeedPlayNext = 0 < #guardTopUIDInfo
      self.guardTopInfo = guardTopUIDInfo
      log(bWriteLog and "LobbyRightPopularityUI:ShowPopularityTop3 self.bNeedPlayNext = " .. tostring(self.bNeedPlayNext))
      log_tree("LobbyRightPopularityUI:OnGetPopularityRsp popularityTopUIDInfo", popularityTopUIDInfo)
      cObj_popularPKTop3:RefreshPopularityTopUIShow(popularityTopUIDInfo)
    elseif 0 < #guardTopUIDInfo then
      log(bWriteLog and "LobbyRightPopularityUI:ShowPopularityTop3 self.bNeedPlayNext = false")
      log_tree("LobbyRightPopularityUI:OnGetPopularityRsp guardTopUIDInfo", guardTopUIDInfo)
      cObj_popularPKTop3:RefreshPopularityTopUIShow(guardTopUIDInfo)
    end
    PlayerPrefsSystem.CheckAndSaveCurrentDate_N(PlayerPrefsSystem.ePlayerPrefsType.eLobbySocialPopularTop3Info, false, 1)
    self:SetWidgetVisible(self.UIRoot.CanvasPanel_Top3, true)
    self:PlayUserWidgetAnimation(self.UIRoot.Tips_Gift, 0, 1, 0, 1)
    if self.TipsTimer then
      self:RemoveTimer(self.TipsTimer)
    end
    self.TipsTimer = self:AddTimerOnce(4, function()
      if self.UIRoot then
        self:OnFinishedTipsGift(bNeedPlayNext)
      end
    end)
  end, Enum_PROFILE_REPORT_CFG.POP_DEVOTE)
end
function LobbySocialLeftMessage:OnFinishedTipsGift(bNeedPlayNext)
  if bNeedPlayNext then
    local guardTopUIDInfo = self.guardTopInfo
    local cObj_popularPKTop3 = self:GetPopularPKTop3UI()
    self:PlayUserWidgetAnimation(self.UIRoot.Refresh, 0, 1, 0, 1)
    cObj_popularPKTop3:PlayRefreshAnim()
    log_tree("LobbyRightPopularityUI:OnGetPopularityRsp guardTopUIDInfo", guardTopUIDInfo)
    cObj_popularPKTop3:RefreshGuardTopUIShow(guardTopUIDInfo)
  else
    self:SetWidgetVisible(self.UIRoot.CanvasPanel_Top3, false)
  end
end
function LobbySocialLeftMessage:GetPopularPKTop3UI()
  if not self._cObj_popularPKTop3 then
    self._cObj_popularPKTop3 = self:CreateChildWindow(self.UIRoot.Border_Top3, UIManager.UI_Config.SocialLobby_LeftUI_PopularPKTop3_UIBP)
  end
  return self._cObj_popularPKTop3
end
local class = require("class")
local ui_base = require("client.slua_ui_framework.base")
local CLobbySocialLeftMessage = class(ui_base, nil, LobbySocialLeftMessage)
return CLobbySocialLeftMessage
