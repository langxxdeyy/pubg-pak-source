local logic_activity_introduce_guide = require("client.slua.logic.activity.logic_activity_introduce_guide")
local Logic_SmallRPUIContext = require("client.slua.logic.specialoffer.SmallRP.Logic_SmallRPUIContext")
local Promise = require("common.promise")
local Trait = require("common.trait")
local Traits = {
  require("client.slua.traits.Localization.TKoreaRevealItemTips")
}
local SmallRP_Award_UIBP = {}
local _AvatarSceneCfg = {bWear = true, bIsValidItemJump = true}
local _tShowWidth = {
  76,
  162,
  248,
  196
}
local _tMultiChooseOneShowWidth = {
  200,
  196,
  263,
  196
}
local _nBigMultiChooseShowWidth = 161
local _intervalDis = 80
local _nMakeLevelCount = 3
local _ImageColor_Grey = FLinearColor(1, 1, 1, 0.4)
local _ImageColor_White = FLinearColor(1, 1, 1, 1)
local _TextColor_Red = FSlateColor(FLinearColor(0.760525, 0.008023, 0.043735, 1))
local _TextColor_White = FSlateColor(FLinearColor(1, 1, 1, 0.7))
local _sLatestSmallRPPreviewSceneName, _cObjLatestSmallRPPreviewOwner
local _nIndiaPreviewActivityId = 9460050
local _sIndiaPreviewSceneName = "Lobby_MP_460_India"
local _sIndiaPreviewScenePath = "/Game/MultiRegion/Content/IN/Arts_Scenes/Lobby/Lobby_Split/Lobby_MP_460_India/Lobby_MP_460_India"
local _sIndiaPreviewPakLookupPath = "/Game/Arts_Scenes/Lobby/Lobby_Split/Lobby_MP_460_India/Lobby_MP_460_India"
local UnloadSmallRPPreviewScene = function(sSceneName)
  if not (LobbySceneManager and sSceneName) or sSceneName == "" then
    return
  end
  if LobbySceneManager.IsStreamLevelLoaded(sSceneName) then
    LobbySceneManager.LoadStreamLevel(false, sSceneName, nil, nil, {bForceUnload = true})
  end
end
local PrepareSmallRPPreviewScene = function(self, sSceneName)
  if not sSceneName or sSceneName == "" then
    return
  end
  if _sLatestSmallRPPreviewSceneName and _sLatestSmallRPPreviewSceneName ~= sSceneName then
    UnloadSmallRPPreviewScene(_sLatestSmallRPPreviewSceneName)
  end
  _sLatestSmallRPPreviewSceneName = sSceneName
  _cObjLatestSmallRPPreviewOwner = self
end
function SmallRP_Award_UIBP:ctor(_, tContext)
  self._cObj_avatarDetails = nil
  self._cObj_smallRPModule, self._nActivityId, self._tSmallRPContext = Logic_SmallRPUIContext.Create(tContext)
  self._nLastAvatarShowLevel = nil
  self._nLastItemId = nil
  self._nLastSelectLevel = nil
  self._nCurBannerShowLevel = nil
  self._nCurBannerShowRoundId = nil
  self._nCurBannerShowItemId = nil
  self._sTitleImagePath = nil
  self._bIsShowAvatar = false
  self._bIsCardUnlock = false
  self._tAllRewardNode = {}
  self._tLevelRewardPos = {}
  self._nScrollWidth = 0
  self._bIsInit = false
  self._bIsDragShow = false
  self._nDragCheckTime = 0
  self._guidePromise = nil
  self._fnPreviewSceneNameGetter = nil
end
function SmallRP_Award_UIBP:RegistEvents()
  SmallRP_Award_UIBP.__super.RegistEvents(self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Help, self.OnHelpBtnClick, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Video, self.OnVideoBtnClick, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_BuyScore, self.OnBuyScoreBtnClick, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Task, self.OnTaskBtnClick, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_UnLock, self.OnUnlockBtnClick, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_GetAll, self.OnGetAllBtnClick, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Preview, self.OnPreviewButtonClick, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Gift, self.OnGiftBtnClick, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_LuckTip, self.OnLuckTipBtnClick, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Go1Button, self.OnGo1BtnClick, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Go2Button, self.OnGo2BtnClick, self)
  self:AddControlEventByControl(self.UIRoot.ScrollBox_LevelReward, "OnBeginScroll", self.OnBeginScroll, self)
  self:AddControlEventByControl(self.UIRoot.ScrollBox_LevelReward, "OnUserScrolled", self.OnScrollingEvent, self)
  self:AddControlEventByControl(self.UIRoot.ScrollBox_LevelReward, "OnEndScroll", self.OnDragLoopEnd, self)
  self:AddControlEventByControl(self.UIRoot.Fadein, "OnAnimationFinished", self.OnFadeInAnimFinished, self)
  self:AddControlEventByControl(self.UIRoot.Tips_Fadein, "OnAnimationFinished", self.OnTipsFadeInAnimFinished, self)
  self:AddCommonEvent(EVENTTYPE_SMALL_RP, EVENTID_SMALL_RP_INIT_REWARD_LIST, self.OnGotLevelRewardCfgRefresh, self)
  self:AddCommonEvent(EVENTTYPE_SMALL_RP, EVENTID_SMALL_RP_REFRESH_REWARD_LIST, self.OnRefreshRewardListEvent, self)
  self:AddCommonEvent(EVENTTYPE_SMALL_RP, EVENTID_SMALL_RP_UNLOCK, self.OnUnlockEvent, self)
  self:AddCommonEvent(EVENTTYPE_SMALL_RP, EVENTID_SMALL_RP_LEVEL_CHANGE, self.OnLevelChangeEvent, self)
  self:AddCommonEvent(EVENTTYPE_SMALL_RP, EVENTID_SMALL_RP_RED_DOT_REFRESH, self.OnRedDotRefreshEvent, self)
  self:AddCommonEvent(EVENTTYPE_LOBBY_SCENE, EVENTID_SCENE_LOADED, self.OnSceneLoaded, self)
  self:AddCommonEvent(EVENTTYPE_SMALL_RP, EVENTID_SMALL_RP_GOT_ACT_DATA, self.OnGotActDataEvent, self)
  self:AddCommonEvent(EVENTTYPE_SMALL_RP, EVENTID_SMALL_RP_ACTIVITY_REWARD_UPDATE, self.OnActivityRewardUpdateEvent, self)
  self:AddCommonEvent(EVENTTYPE_SMALL_RP, EVENTID_SMALL_RP_ACTIVITY_GOT_ACT_DATA, self.OnActivityGotActDataEvent, self)
  self:AddCommonEvent(EVENTTYPE_SMALL_RP, EVENTID_SMALL_RP_ACTIVITY_INIT_REWARD_LIST, self.OnActivityInitRewardListEvent, self)
  self:AddCommonEvent(EVENTTYPE_SMALL_RP, EVENTID_SMALL_RP_ACTIVITY_UNLOCK, self.OnActivityUnlockEvent, self)
  self:AddCommonEvent(EVENTTYPE_SMALL_RP, EVENTID_SMALL_RP_ACTIVITY_SCORE_CHANGE, self.OnActivityScoreChangeEvent, self)
  self:AddCommonEvent(EVENTTYPE_SMALL_RP, EVENTID_SMALL_RP_ACTIVITY_LEVEL_CHANGE, self.OnActivityLevelChangeEvent, self)
  self:AddCommonEvent(EVENTTYPE_SMALL_RP, EVENTID_SMALL_RP_ACTIVITY_RED_DOT_REFRESH, self.OnActivityRedDotRefreshEvent, self)
end
function SmallRP_Award_UIBP:OnPostInitialize()
  SmallRP_Award_UIBP.__super.OnPostInitialize(self)
  self:ApplyPreviewSceneNameGetter()
  self._cObj_smallRPModule:RequestTaskData()
  if tonumber(self._nActivityId) == _nIndiaPreviewActivityId and not IsEditor then
    local PufferManager = require("client.slua.logic.download.puffer.puffer_manager")
    local PufferConst = require("client.slua.logic.download.puffer_const")
    local PufferTlog = require("client.slua.logic.download.report.puffer_tlog")
    local sSceneDownloadPath = _sIndiaPreviewScenePath
    local sPakName = PufferManager.GetPakName(sSceneDownloadPath)
    if not sPakName or sPakName == "" then
      sSceneDownloadPath = _sIndiaPreviewPakLookupPath
    end
    PufferManager.Download(PufferConst.ENUM_DownloadType.ODPAK, {sSceneDownloadPath}, PufferTlog.Enum_TLog_From.Scene, nil, {bAutoDownload = false, bFirst = true})
  end
  self:InitShow()
  local node_root = self.UIRoot
  node_root:PlayUserWidgetAnimation(node_root.Fadein, 0, 1, 0, 1)
  self:CheckIsPlayVideo()
  self:AddTimerOnce(0, function()
    local slateBlueprintLibrary = import("SlateBlueprintLibrary")
    local Geometry = node_root.ScrollBox_LevelReward:GetCachedGeometry()
    local tDesiredSize = slateBlueprintLibrary.GetLocalSize(Geometry)
    self._nScrollWidth = tDesiredSize.X
    self:RefreshBannerShow()
  end)
  node_root.Reddot_Anchor:ShowRedPointByPath("/Game/UMG/UI_Logic/Reddot/Reddot_Anchor_Item03.Reddot_Anchor_Item03", 2)
end
function SmallRP_Award_UIBP:OnShow()
  SmallRP_Award_UIBP.__super.OnShow(self)
  self:ShowKoreaRevealItemTips()
end
function SmallRP_Award_UIBP:OnClose()
  if _cObjLatestSmallRPPreviewOwner == self then
    UnloadSmallRPPreviewScene(_sLatestSmallRPPreviewSceneName)
    _sLatestSmallRPPreviewSceneName = nil
    _cObjLatestSmallRPPreviewOwner = nil
  end
  self:RestorePreviewSceneNameGetter()
  if self._guidePromise then
    self._guidePromise:Reject()
    self._guidePromise = nil
  end
  EventSystem:postEvent(EVENTTYPE_SPECIAL_OFFER, EVENTID_SPECIAL_OFFER_SET_MASK, true)
  if UIManager.IsUIShow(UIManager.UI_Config.NewbieGuide_UIBP) then
    UIManager.CloseUI(UIManager.UI_Config.NewbieGuide_UIBP)
  end
  SmallRP_Award_UIBP.__super.OnClose(self)
end
function SmallRP_Award_UIBP:OnHelpBtnClick()
  self:PlayAudio(sound_config.click)
  local sContentKey = 66013
  local uObj_actCfg = self._cObj_smallRPModule:GetActShowCfg() or {}
  if uObj_actCfg.RuleTextKey and uObj_actCfg.RuleTextKey ~= 0 then
    sContentKey = uObj_actCfg.RuleTextKey
  end
  local sTitle = LocUtil.GetLocalizeResStr(4726)
  local sContent = LocUtil.GetLocalizeStrConcatenation(sContentKey)
  UIManager.ShowUI(UIManager.UI_Config.HelpTip, 0, sTitle, sContent)
end
function SmallRP_Award_UIBP:OnVideoBtnClick()
  self:PlayAudio(sound_config.click)
  self:CheckIsPlayVideo(true)
end
function SmallRP_Award_UIBP:OnBuyScoreBtnClick()
  if not self._cObj_smallRPModule:GetIsUnlock() then
    return
  end
  self:PlayAudio(sound_config.click)
  local ui_jump_manager = require("client.common.uibase.ui_jump_manager")
  ui_jump_manager.OpenJumpModule(BP_ENUM_MODULE_SMALL_RP_BUY_SCORE, self._tSmallRPContext)
end
function SmallRP_Award_UIBP:OnTaskBtnClick()
  self:PlayAudio(sound_config.click)
  local ui_jump_manager = require("client.common.uibase.ui_jump_manager")
  ui_jump_manager.OpenJumpModule(BP_ENUM_MODULE_SMALL_RP_TASK, self._tSmallRPContext)
end
function SmallRP_Award_UIBP:OnLuckTipBtnClick()
  self:PlayAudio(sound_config.click)
  local node_root = self.UIRoot
  node_root:StopAnimation(node_root.Tips_Fadein)
  node_root:PlayUserWidgetAnimation(node_root.Tips_Fadeout, 0, 1, 0, 1)
  self:SetWidgetVisible(node_root.Button_LuckTip, false, true)
end
function SmallRP_Award_UIBP:IsEntranceConnectedRPScore(num)
  local cObj_smallRPModule = self._cObj_smallRPModule
  return cObj_smallRPModule:IsEntranceConnectedRPScore(num)
end
function SmallRP_Award_UIBP:OnGo1BtnClick()
  self:PlayAudio(sound_config.click)
  local cObj_smallRPModule = self._cObj_smallRPModule
  cObj_smallRPModule:JumpToRelatedModule(1)
end
function SmallRP_Award_UIBP:OnGo2BtnClick()
  self:PlayAudio(sound_config.click)
  local cObj_smallRPModule = self._cObj_smallRPModule
  cObj_smallRPModule:JumpToRelatedModule(2)
end
function SmallRP_Award_UIBP:OnGiftBtnClick()
  self:PlayAudio(sound_config.click)
  local cObj_smallRPModule = self._cObj_smallRPModule
  local bIsUnlock = cObj_smallRPModule:GetIsUnlock()
  local Logic_ItemGiveAndAskConst = require("client.slua.logic.ItemGiveAndAsk.Logic_ItemGiveAndAskConst")
  local Enum_TabType = Logic_ItemGiveAndAskConst.Enum_TabType
  local nShowTabType = Enum_TabType.Give
  if not bIsUnlock then
    nShowTabType = Enum_TabType.Ask
  end
  local nItemId = cObj_smallRPModule:GetSmallRPCardId()
  if not nItemId or nItemId == 0 then
    log(bWriteLog and " SmallRP_Award_UIBP:OnGiftBtnClick not nItemId = " .. tostring(nItemId))
    return
  end
  local Enum_GiveGiftType = Logic_ItemGiveAndAskConst.Enum_GiveGiftType
  local nActivityId = tonumber(self._nActivityId)
  local nGiveType = nActivityId and 0 < nActivityId and Enum_GiveGiftType.SmallRPActivityCard or Enum_GiveGiftType.SmallRPCard
  local Logic_FriendGiftPopupShow = require("client.slua.logic.ItemGiveAndAsk.Logic_FriendGiftPopupShow")
  Logic_FriendGiftPopupShow.ShowGiveAndRequestFriendGift(nShowTabType, nGiveType, nItemId)
end
function SmallRP_Award_UIBP:OnUnlockBtnClick()
  self:PlayAudio(sound_config.click)
  local Logic_SmallRPConst = require("client.slua.logic.specialoffer.SmallRP.Logic_SmallRPConst")
  local Enum_UnlockSourceType = Logic_SmallRPConst.Enum_UnlockSourceType
  self._cObj_smallRPModule:UnlockActBuy(Enum_UnlockSourceType.MainUI, self._bIsCardUnlock)
end
function SmallRP_Award_UIBP:OnGetAllBtnClick()
  self:PlayAudio(sound_config.click)
  local tChooseData = self._cObj_smallRPModule:GetAllRewardMultiChooseOne()
  if not self._nActivityId then
    return
  end
  self:ShowActivityMultiChooseOne(tChooseData, 1)
end
function SmallRP_Award_UIBP:OnPreviewButtonClick()
  self:PlayAudio(sound_config.click)
  local nShowLevel = self._nCurBannerShowLevel
  if not self._bIsInit or not nShowLevel then
    return
  end
  self._bIsDragShow = false
  local cObj_smallRPModule = self._cObj_smallRPModule
  local nScrollToIndex = nShowLevel - 2
  nScrollToIndex = math.max(1, nScrollToIndex)
  nScrollToIndex = math.min(nScrollToIndex, cObj_smallRPModule:GetMaxLevel())
  self:ScrollToIndex(nScrollToIndex)
  local nLastSelectLevel = self._nLastSelectLevel
  if nShowLevel == nLastSelectLevel then
    return
  end
  if not self._tAllRewardNode[nShowLevel] then
    self:AddLevelRewardNodeByShowLevel(false, nShowLevel)
  end
  self:RefreshSelectLevel(true, nShowLevel)
  local tItemData = cObj_smallRPModule:GetShowItemDataByLevel(nShowLevel)
  self:SetRewardDisplay(tItemData, nShowLevel)
end
function SmallRP_Award_UIBP:OnBeginScroll()
  self._bIsDragShow = true
end
function SmallRP_Award_UIBP:OnScrollingEvent()
  local TimeUtil = require("client.common.time_util")
  local nCurTime = TimeUtil.GetMiliseconds()
  if nCurTime - self._nDragCheckTime > 0.5 then
    local node_root = self.UIRoot
    local nPosX = node_root.ScrollBox_LevelReward:GetScrollOffset()
    local nCurLevel
    for k, v in ipairs(self._tLevelRewardPos) do
      if v > nPosX then
        nCurLevel = k
        break
      end
    end
    if nCurLevel then
      self:AddLevelRewardNodeByShowLevel(false, nCurLevel + _nMakeLevelCount)
    end
  end
  self._nDragCheckTime = nCurTime
end
function SmallRP_Award_UIBP:OnDragLoopEnd()
  self:RefreshBannerShow()
end
function SmallRP_Award_UIBP:OnTipsFadeInAnimFinished()
  local node_root = self.UIRoot
  node_root.Text_MultiTip:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
end
function SmallRP_Award_UIBP:OnFadeInAnimFinished()
  local node_root = self.UIRoot
  local cObj_smallRPModule = self._cObj_smallRPModule
  local Logic_SmallRPConst = require("client.slua.logic.specialoffer.SmallRP.Logic_SmallRPConst")
  if cObj_smallRPModule:IsEntranceConnectedRPScore(1) then
    node_root:PlayUserWidgetAnimation(node_root.Tips_Fadein, 0, 1, 0, 1)
    self:SetWidgetVisible(node_root.Button_LuckTip, true, true)
  else
    self:SetWidgetVisible(node_root.Button_LuckTip, false, true)
  end
  self:AddTimerOnce(0, function()
    local nActRoundId = cObj_smallRPModule:GetActRoundId()
    self._guidePromise = self._guidePromise or Promise.Helper.LobbyAwait(0.1, function()
      log(bWriteLog and "[v_hfflaing] SmallRP_Award_UIBP:WaitForNewbieGuide")
      return not UIManager.GetUI(UIManager.UI_Config.NewbieGuide_UIBP)
    end)
    self._guidePromise:Then(function()
      log(bWriteLog and "[v_hfflaing] SmallRP_Award_UIBP:TryShowIntroduceGuide")
      return logic_activity_introduce_guide:TryShowIntroduceGuide(logic_activity_introduce_guide.ENUM_ACTIVITYTYPE.ENUM_ACTIVITY_RP, nActRoundId)
    end):Catch(function()
      log(bWriteLog and "[v_hfflaing] SmallRP_Award_UIBP:CloseIntroduceGuide")
      logic_activity_introduce_guide:CloseIntroduceGuide()
    end)
    local bIsUnlock = cObj_smallRPModule:GetIsUnlock()
    if not nActRoundId or bIsUnlock then
      return
    end
    if self._nActivityId then
      if cObj_smallRPModule:IsGuideCheck() then
        return
      end
    else
      local PlayerPrefsSystem = require("client.logic.LogicPlayerPrefs.playerprefs")
      local tSmallRPLocalCache = PlayerPrefsSystem.LoadFileToTable_N(PlayerPrefsSystem.ePlayerPrefsType.eSmallRP) or {}
      if tSmallRPLocalCache.IsGuideCheck then
        return
      end
    end
    local tAllGuide = {
      {
        node_widget = node_root.Button_UnLock,
        sGuideText = LocUtil.GetLocalizeResStr(66543)
      },
      {
        node_widget = node_root.Button_Task,
        sGuideText = LocUtil.GetLocalizeResStr(66544)
      }
    }
    local bIsEntranceConnectedRPScore1 = cObj_smallRPModule:IsEntranceConnectedRPScore(1)
    local bIsEntranceConnectedRPScore2 = cObj_smallRPModule:IsEntranceConnectedRPScore(2)
    if bIsEntranceConnectedRPScore1 and bIsEntranceConnectedRPScore2 then
      table.insert(tAllGuide, {
        node_widget = node_root.Button_Go1Button,
        sGuideText = LocUtil.GetLocalizeResStr(76599)
      })
    elseif bIsEntranceConnectedRPScore1 then
      table.insert(tAllGuide, {
        node_widget = node_root.Button_Go1Button,
        sGuideText = LocUtil.GetLocalizeResStr(76599)
      })
    elseif bIsEntranceConnectedRPScore2 then
      table.insert(tAllGuide, {
        node_widget = node_root.Button_Go2Button,
        sGuideText = LocUtil.GetLocalizeResStr(76599)
      })
    end
    local nIPScoreId = cObj_smallRPModule:GetIPScoreId()
    if nIPScoreId and 0 < nIPScoreId then
      local cObj_parent = self:GetParentUI()
      local cObj_ipScore = cObj_parent:GetCurrencyObjByItemId(nIPScoreId)
      if cObj_ipScore and slua.isValid(cObj_ipScore.UIRoot) then
        table.insert(tAllGuide, {
          nDir = 3,
          node_widget = cObj_ipScore.UIRoot,
          sGuideText = LocUtil.GetLocalizeResStr(76584)
        })
      end
    end
    self:TriggerGuide(tAllGuide)
  end)
end
function SmallRP_Award_UIBP:TriggerGuide(tAllGuideData)
  if #tAllGuideData <= 0 then
    return
  end
  local function fContinueGuide()
    if #tAllGuideData <= 0 then
      local cObj_smallRPModule = self._cObj_smallRPModule
      local nActRoundId = cObj_smallRPModule:GetActRoundId()
      if self._nActivityId then
        cObj_smallRPModule:SaveGuideCheck()
      else
        local PlayerPrefsSystem = require("client.logic.LogicPlayerPrefs.playerprefs")
        local tSmallRPLocalCache = PlayerPrefsSystem.LoadFileToTable_N(PlayerPrefsSystem.ePlayerPrefsType.eSmallRP) or {}
        tSmallRPLocalCache.IsGuideCheck = true
        PlayerPrefsSystem.SaveTableToFile_N(tSmallRPLocalCache, PlayerPrefsSystem.ePlayerPrefsType.eSmallRP)
      end
      return false
    end
    self:AddTimerOnce(0, function()
      if tAllGuideData and 0 < #tAllGuideData then
        local tCurTempGuide = table.remove(tAllGuideData, 1)
        local nDir = tCurTempGuide.nDir or 1
        local uiInfo = UIManager.GetUI(UIManager.UI_Config.NewbieGuide_UIBP)
        if uiInfo then
          uiInfo:RefreshUI(nDir, tCurTempGuide.sGuideText, tCurTempGuide.node_widget, fContinueGuide, false, 1)
        end
      end
    end)
    return true
  end
  local tCurGuide = table.remove(tAllGuideData, 1)
  UIManager.ShowUI(UIManager.UI_Config.NewbieGuide_UIBP, 1, tCurGuide.sGuideText, tCurGuide.node_widget, fContinueGuide, false, 1)
end
function SmallRP_Award_UIBP:OnRefreshRewardListEvent(_, _, tAllLevel)
  local nLastSelectLevel = self._nLastSelectLevel
  local tAllRewardNode = self._tAllRewardNode
  if tAllLevel then
    for _, v in ipairs(tAllLevel) do
      local cObj_levelReward = tAllRewardNode[v]
      if cObj_levelReward then
        cObj_levelReward:RefreshShow(false, nLastSelectLevel)
      end
    end
  else
    for _, v in pairs(tAllRewardNode) do
      local cObj_levelReward = v
      cObj_levelReward:RefreshShow(false, nLastSelectLevel)
    end
  end
  self:RefreshGetAllBtnShow()
end
function SmallRP_Award_UIBP:OnActivityRewardUpdateEvent(_, _, nActivityId, sRewardType, nSourceId)
  if not self._nActivityId or self._nActivityId ~= tonumber(nActivityId) or sRewardType ~= "level" then
    return
  end
  local tAllLevel = nSourceId and self._cObj_smallRPModule:GetRelatedRewardLevel(nSourceId) or nil
  self:OnRefreshRewardListEvent(nil, nil, tAllLevel)
end
function SmallRP_Award_UIBP:OnGotLevelRewardCfgRefresh()
  self:InitLevelRewardLoop()
  self:RefreshGetAllBtnShow()
  self:RefreshBannerShow()
end
function SmallRP_Award_UIBP:OnUnlockEvent()
  self:RefreshActUnlock()
  self:RefreshUnlockLevelRewardTip()
  if not self._bIsShowAvatar then
    self:InitAvatarDisplay()
    self:OnScrollingEvent()
  end
  self:RefreshLevelChange()
  self:RefreshGiftBtnShow()
end
function SmallRP_Award_UIBP:OnLevelChangeEvent()
  self:RefreshLevelChange()
end
function SmallRP_Award_UIBP:OnRedDotRefreshEvent(_, _, nActivityId)
  nActivityId = tonumber(nActivityId)
  if self._nActivityId then
    if nActivityId and self._nActivityId ~= nActivityId then
      return
    end
  elseif nActivityId then
    return
  end
  self:RefreshRedDot()
end
function SmallRP_Award_UIBP:OnActivityGotActDataEvent(_, _, nActivityId)
  if not self._nActivityId or self._nActivityId ~= tonumber(nActivityId) then
    return
  end
  self:RefreshUnlockCostShow()
  self:RefreshActUnlock()
  self:RefreshLevelChange()
  self:RefreshGiftBtnShow()
end
function SmallRP_Award_UIBP:OnActivityInitRewardListEvent(_, _, nActivityId)
  if not self._nActivityId or self._nActivityId ~= tonumber(nActivityId) then
    return
  end
  self:OnGotLevelRewardCfgRefresh()
end
function SmallRP_Award_UIBP:OnActivityUnlockEvent(_, _, nActivityId)
  if not self._nActivityId or self._nActivityId ~= tonumber(nActivityId) then
    return
  end
  self:OnUnlockEvent()
end
function SmallRP_Award_UIBP:OnActivityScoreChangeEvent(_, _, nActivityId)
  if not self._nActivityId or self._nActivityId ~= tonumber(nActivityId) then
    return
  end
  self:RefreshLevelChange()
  self:RefreshGiftBtnShow()
end
function SmallRP_Award_UIBP:OnActivityLevelChangeEvent(_, _, nActivityId)
  if not self._nActivityId or self._nActivityId ~= tonumber(nActivityId) then
    return
  end
  self:RefreshLevelChange()
end
function SmallRP_Award_UIBP:OnActivityRedDotRefreshEvent(_, _, nActivityId)
  if not self._nActivityId or self._nActivityId ~= tonumber(nActivityId) then
    return
  end
  self:RefreshRedDot()
end
function SmallRP_Award_UIBP:GetPreviewSceneName()
  if tonumber(self._nActivityId) == _nIndiaPreviewActivityId then
    return _sIndiaPreviewSceneName
  end
  if self._nActivityId then
    local uObj_actCfg = self._cObj_smallRPModule:GetActShowCfg() or {}
    printf("SmallRP_Award_UIBP:GetPreviewSceneName source=activity, activityId=%s, sceneName=%s", self._nActivityId, uObj_actCfg.SceneName)
    return uObj_actCfg.SceneName
  end
  local Logic_SmallRPUtils = require("client.slua.logic.specialoffer.SmallRP.Logic_SmallRPUtils")
  local sSceneName = Logic_SmallRPUtils.GetSceneName()
  printf("SmallRP_Award_UIBP:GetPreviewSceneName source=legacy, sceneName=%s", sSceneName)
  return sSceneName
end
function SmallRP_Award_UIBP:ApplyPreviewSceneNameGetter()
  if not self._nActivityId or self._fnPreviewSceneNameGetter then
    return
  end
  function self._fnPreviewSceneNameGetter()
    return self:GetPreviewSceneName()
  end
  local Logic_SmallRPUtils = require("client.slua.logic.specialoffer.SmallRP.Logic_SmallRPUtils")
  Logic_SmallRPUtils.SetSceneNameGetter(self._fnPreviewSceneNameGetter)
  printf("SmallRP_Award_UIBP:ApplyPreviewSceneNameGetter activityId=%s", self._nActivityId)
end
function SmallRP_Award_UIBP:RestorePreviewSceneNameGetter()
  if not self._fnPreviewSceneNameGetter then
    return
  end
  local Logic_SmallRPUtils = require("client.slua.logic.specialoffer.SmallRP.Logic_SmallRPUtils")
  Logic_SmallRPUtils.ClearSceneNameGetter(self._fnPreviewSceneNameGetter)
  printf("SmallRP_Award_UIBP:RestorePreviewSceneNameGetter activityId=%s", self._nActivityId)
  self._fnPreviewSceneNameGetter = nil
end
function SmallRP_Award_UIBP:OnSceneLoaded(_, _, LevelName)
  local sSceneName = self:GetPreviewSceneName()
  printf("SmallRP_Award_UIBP:OnSceneLoaded loadedLevel=%s, previewSceneName=%s", LevelName, sSceneName)
  if LevelName == sSceneName then
    if tonumber(self._nActivityId) == _nIndiaPreviewActivityId then
      if not LobbySceneManager or not LobbySceneManager.IsStreamLevelLoaded(sSceneName) then
        printf("SmallRP_Award_UIBP:OnSceneLoaded skip fallback scene event, sceneName=%s", sSceneName)
        return
      end
      if self._bIsShowAvatar then
        self:SetWidgetVisible(self.UIRoot.CanvasPanel_BG, false)
      end
    end
    EventSystem:postEvent(EVENTTYPE_SPECIAL_OFFER, EVENTID_SPECIAL_OFFER_SET_MASK, false)
  end
end
function SmallRP_Award_UIBP:OnGotActDataEvent(_, _)
  self:RefreshUnlockCostShow()
  self:RefreshActUnlock()
  self:RefreshLevelChange()
  self:RefreshGiftBtnShow()
end
function SmallRP_Award_UIBP:RefreshTitleTextureByReward(nLevel, nItemId)
  local uObj_actCfg = self._cObj_smallRPModule:GetActShowCfg()
  if not uObj_actCfg then
    return
  end
  local sTitleImageName = "Image_Title"
  if nLevel == 14 and nItemId == 1967005 then
    sTitleImageName = "Image_Title_White"
  end
  local sTitleImagePath = string.format("%sNoAtlas/%s.%s", uObj_actCfg.TemplateBasePath, sTitleImageName, sTitleImageName)
  if self._sTitleImagePath == sTitleImagePath then
    return
  end
  self._sTitleImagePath = sTitleImagePath
  self:SetTexture(self.UIRoot.Image_Title, sTitleImagePath)
end
function SmallRP_Award_UIBP:InitShow()
  local node_root = self.UIRoot
  local cObj_smallRPModule = self._cObj_smallRPModule
  self:InitTextureShow()
  self:InitRelatedModuleShow()
  local nCardItemId = cObj_smallRPModule:GetSmallRPCardId()
  local bIsShowGiftBtn = nCardItemId and nCardItemId ~= 0
  self:SetWidgetVisible(node_root.Button_Gift, bIsShowGiftBtn, true)
  if self._nActivityId then
    local Logic_SmallRPActivityRedMgr = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.Logic_SmallRPActivityRedMgr)
    Logic_SmallRPActivityRedMgr:SaveFirstOpen(self._nActivityId)
  else
    local Logic_SmallRPRedMgr = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.Logic_SmallRPRedMgr)
    Logic_SmallRPRedMgr:SaveFirstOpen()
  end
  self:RefreshRedDot()
  local TimeUtil = require("client.common.time_util")
  local nBeginTime, nEndTime = cObj_smallRPModule:GetActTime()
  if nBeginTime and nEndTime then
    node_root.Text_ActTime:SetText(TimeUtil.FormatTime_timeFrame(nBeginTime, nEndTime))
  else
    node_root.Text_ActTime:SetText("")
  end
  local UIUtil = require("client.common.ui_util")
  if nEndTime and UIUtil.IsCountDown(nEndTime, 3) then
    self:AddTimerLoop(0, function()
      local timeStr = UIUtil.GetCountDownStr(nEndTime)
      self.UIRoot.Text_Time:SetText(timeStr)
    end, TIMER_INFINITE, 1)
    self:SetWidgetVisible(self.UIRoot.CanvasPanel_Countdown, true)
  else
    self:SetWidgetVisible(self.UIRoot.CanvasPanel_Countdown, false)
  end
  self:RefreshUnlockCostShow()
  node_root.Text_UnlockActTip:SetText(LocUtil.LocalizeResFormat(66022))
  self:SetTexture(node_root.Image_ScoreIcon, cObj_smallRPModule:GetCostIcon(cObj_smallRPModule:GetScoreShowItemId()))
  local sMultiTipStr = cObj_smallRPModule:ReplaceTextScoreIcon(LocUtil.LocalizeResFormat(79476, LocUtil.LocalizeResFormat(cObj_smallRPModule:GetEntranceTittleID(1))))
  node_root.Text_MultiTip:SetText(sMultiTipStr)
  node_root.Text_MultiTip:SetWidgetVisibility(UEnums.ESlateVisibility.Hidden)
  local nOneLevelGetIPScore = cObj_smallRPModule:GetLevelExtraGetIPScoreNum()
  local nRoundId = cObj_smallRPModule:GetActRoundId()
  if nRoundId then
    local imageRichTextContent = LocUtil.LocalizeResFormat(77043, nOneLevelGetIPScore)
    node_root.RichText_UnLockTip:SetText(string.format(imageRichTextContent, nRoundId))
  else
    node_root.RichText_UnLockTip:SetText("")
  end
  self:RefreshUnlockLevelRewardTip()
  self:RefreshVideoBtnShow()
  self:RefreshActUnlock()
  self:RefreshLevelChange()
  self:InitAvatarDetails()
  self:InitLevelRewardLoop()
  self:RefreshGiftBtnShow()
  self._bIsInit = true
end
function SmallRP_Award_UIBP:RefreshUnlockCostShow()
  local node_root = self.UIRoot
  local cObj_smallRPModule = self._cObj_smallRPModule
  local nCardItemId = cObj_smallRPModule:GetSmallRPCardId()
  local UIUtil = require("client.common.ui_util")
  local CoinMacro = require("client.slua.config.ClientMacros.CoinMacro")
  local wardrobeData = require("client.slua.logic.wardrobe.wardrobe_data")
  if nCardItemId and wardrobeData:GetHallDepotItemDataByResID(nCardItemId) then
    self._bIsCardUnlock = true
    node_root.Text_Cost:SetText(1)
    self:SetTexture(node_root.Image_CostIcon, UIUtil.GetItemSmallIcon(nCardItemId))
  else
    node_root.Text_Cost:SetText(cObj_smallRPModule:GetUnlockNeedUC())
    self:SetTexture(node_root.Image_CostIcon, UIUtil.GetItemSmallIcon(CoinMacro.Uc))
  end
end
function SmallRP_Award_UIBP:InitTextureShow()
  local cObj_smallRPModule = self._cObj_smallRPModule
  local uObj_actCfg = cObj_smallRPModule:GetActShowCfg()
  if not uObj_actCfg then
    return
  end
  local sBasePath = uObj_actCfg.TemplateBasePath
  local node_root = self.UIRoot
  local UIUtil = require("client.common.ui_util")
  local sPromoImagePath = sBasePath .. "NoAtlas/Image_Promo.Image_Promo"
  local sLeftBgImagePath = sBasePath .. "NoAtlas/Image_Poster_BgL.Image_Poster_BgL"
  local sRightBgImagePath = sBasePath .. "NoAtlas/Image_Poster_BgR.Image_Poster_BgR"
  if UIUtil.IsExistBlueprintPath(sPromoImagePath) then
    self:SetTexture(node_root.Image_Promo, sPromoImagePath)
    node_root.WidgetSwitcher_Publicize:SetActiveWidgetIndex(0)
    self:SetWidgetVisible(node_root.WidgetSwitcher_Publicize, true)
  else
    if not UIUtil.IsExistBlueprintPath(sLeftBgImagePath) or not UIUtil.IsExistBlueprintPath(sRightBgImagePath) then
      sLeftBgImagePath = sBasePath .. "NoAtlas/Image_BgL.Image_BgL"
      sRightBgImagePath = sBasePath .. "NoAtlas/Image_BgR.Image_BgR"
    end
    if UIUtil.IsExistBlueprintPath(sLeftBgImagePath) and UIUtil.IsExistBlueprintPath(sRightBgImagePath) then
      self:SetTexture(node_root.Image_LeftBg, sLeftBgImagePath)
      self:SetTexture(node_root.Image_RightBg, sRightBgImagePath)
      node_root.WidgetSwitcher_Publicize:SetActiveWidgetIndex(1)
      self:SetWidgetVisible(node_root.WidgetSwitcher_Publicize, true)
    else
      self:SetWidgetVisible(node_root.WidgetSwitcher_Publicize, false)
    end
  end
  local sCoreRewardTipUIBPPath = sBasePath .. "SmallRP_Core_Reward_UIBP.SmallRP_Core_Reward_UIBP"
  if UIUtil.IsExistBlueprintPath(sCoreRewardTipUIBPPath) then
    self:CreateChildWindowWithBpPath("CanvasPanel_Core_Reward", UIManager.UI_Config.ChildUIWithoutBpPath, sCoreRewardTipUIBPPath)
  end
  self:RefreshTitleTextureByReward()
  self:SetTexture(node_root.Image_LevelIcon, sBasePath .. "NoAtlas/Image_LevelIcon.Image_LevelIcon")
  local sLuckTipBg = sBasePath .. "NoAtlas/SmallRP_LuckySpin_Tips.SmallRP_LuckySpin_Tips"
  if UIUtil.IsExistBlueprintPath(sLuckTipBg) then
    self:SetTexture(node_root.Image_ExShopDialogBg, sLuckTipBg)
  end
  local sActTimeColor = uObj_actCfg.ActTimeTextColor
  if sActTimeColor == "" then
    sActTimeColor = "FFFFFFFF"
  end
  local sIconColor = uObj_actCfg.ActIconColor
  if sIconColor == "" then
    sIconColor = "FFFFFFFF"
  end
  local uObj_iconColor = FLinearColor.FromSRGBColor(FColor.FromHex(sIconColor))
  node_root.Image_Help:SetColorAndOpacity(uObj_iconColor)
  node_root.Text_ActTime:SetColorAndOpacity(FSlateColor(FLinearColor.FromSRGBColor(FColor.FromHex(sActTimeColor))))
  local sRightMaskColor = uObj_actCfg.RightMaskColor
  self:InitMaskImageShow(node_root.Image_RightMask, sRightMaskColor)
  local sBottomMaskColor = uObj_actCfg.BottomMaskColor
  self:InitMaskImageShow(node_root.Image_BottomMask, sBottomMaskColor)
end
function SmallRP_Award_UIBP:InitRelatedModuleShow(image, color)
  local cObj_smallRPModule = self._cObj_smallRPModule
  local uObj_actCfg = cObj_smallRPModule:GetActShowCfg()
  if not uObj_actCfg then
    return
  end
  local node_root = self.UIRoot
  local Logic_SmallRPConst = require("client.slua.logic.specialoffer.SmallRP.Logic_SmallRPConst")
  if cObj_smallRPModule:GetConcernEntranceType(1) == Logic_SmallRPConst.Enum_EntranceType.Invalid then
    self:SetWidgetVisible(node_root.Button_Go1Button, false)
  else
    self:SetWidgetVisible(node_root.Button_Go1Button, true, true)
    node_root.Text_Go1:SetText(LocUtil.GetLocalizeResStr(cObj_smallRPModule:GetEntranceTittleID(1)))
    self:SetTexture(node_root.Image_Go1, cObj_smallRPModule:GetEntranceImagePath(1))
  end
  if cObj_smallRPModule:GetConcernEntranceType(2) == Logic_SmallRPConst.Enum_EntranceType.Invalid then
    self:SetWidgetVisible(node_root.Button_Go2Button, false)
  else
    self:SetWidgetVisible(node_root.Button_Go2Button, true, true)
    node_root.Text_Go2:SetText(LocUtil.GetLocalizeResStr(cObj_smallRPModule:GetEntranceTittleID(2)))
    self:SetTexture(node_root.Image_Go2, cObj_smallRPModule:GetEntranceImagePath(2))
  end
end
function SmallRP_Award_UIBP:InitMaskImageShow(node_maskImage, sColorCfg)
  if sColorCfg and sColorCfg ~= "" then
    local uObj_color = FLinearColor.FromSRGBColor(FColor.FromHex(sColorCfg))
    node_maskImage:SetColorAndOpacity(uObj_color)
    self:SetWidgetVisible(node_maskImage, true)
    return
  end
  self:SetWidgetVisible(node_maskImage, false)
end
function SmallRP_Award_UIBP:InitAvatarDetails()
  if self._cObj_avatarDetails then
    return
  end
  local ConstDetail = require("client.slua.traits.DetailComponent.ConstDetail")
  local ConstAvatarDislay = require("client.slua.traits.DetailComponent.AvatarDisplay.ConstAvatarDislay")
  local DetailConfig = ConstDetail.GetDefaultConfig()
  DetailConfig.videoBtn = false
  DetailConfig.enlarge = true
  DetailConfig.boxDropList = true
  DetailConfig.car = true
  DetailConfig.goResearch = true
  DetailConfig.inventory = true
  DetailConfig.characterTrans = false
  function DetailConfig.fTransPreview(nItemId)
    local cObj_smallRPModule = self._cObj_smallRPModule
    local nRoundId = cObj_smallRPModule:GetActRoundId()
    if not nRoundId then
      return
    end
    local sJumpCfgTable = self._nActivityId and "SmallRPActivitySpecialItemJumpCfg" or "SpecialItemJumpCfg"
    local uObj_jumpCfg = CDataTable.GetTableDataByFilter(sJumpCfgTable, "ItemId", nItemId, "ActRound", nRoundId)
    if not uObj_jumpCfg then
      return
    end
    GlobalData.JumpUrl(uObj_jumpCfg.JumpUrl)
  end
  local tShowCfg = {
    switches = DetailConfig,
    curScene = ConstAvatarDislay.ESceneType.SmallRP300,
    namePadding = FMargin(0, 0, 0, 195),
    topPadding = FMargin(0, 110, 0, 0),
    offsetInfo = {
      kill = FVector2D(350, 0)
    }
  }
  local sPreviewSceneName = self:GetPreviewSceneName()
  PrepareSmallRPPreviewScene(self, sPreviewSceneName)
  local cObj_avatarDetails = self:CreateChildWindow(self.UIRoot.CanvasPanel_Details, UIManager.UI_Config.DetailComponentMain, tShowCfg)
  cObj_avatarDetails:SetPadding(-10, 0, 0, 0)
  self._cObj_avatarDetails = cObj_avatarDetails
end
function SmallRP_Award_UIBP:RefreshRedDot()
  local node_root = self.UIRoot
  local isShowRed
  if self._nActivityId then
    local Logic_SmallRPActivityRedMgr = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.Logic_SmallRPActivityRedMgr)
    isShowRed = Logic_SmallRPActivityRedMgr:GetTaskIsRed(self._nActivityId)
  else
    local Logic_SmallRPRedMgr = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.Logic_SmallRPRedMgr)
    isShowRed = Logic_SmallRPRedMgr:GetTaskIsRed()
  end
  self:SetWidgetVisible(node_root.Reddot_Anchor, isShowRed)
end
function SmallRP_Award_UIBP:RefreshGiftBtnShow()
  local cObj_smallRPModule = self._cObj_smallRPModule
  local nShowIndex = cObj_smallRPModule:GetIsUnlock() and 0 or 1
  local node_root = self.UIRoot
  node_root.WidgetSwitcher_GiftShow:SetActiveWidgetIndex(nShowIndex)
end
function SmallRP_Award_UIBP:AddLevelRewardNodeByShowLevel(bIsForce, nCurShowLevel, tAllRewardData)
  if not bIsForce and not self._bIsInit then
    return
  end
  local cObj_smallRPModule = self._cObj_smallRPModule
  tAllRewardData = tAllRewardData or cObj_smallRPModule:GetCurRoundLevelRewardCfg()
  if not tAllRewardData then
    return
  end
  local tLevelRewardPos = self._tLevelRewardPos
  local nLevelMax = #tAllRewardData
  local nShowMinLevel = math.max(1, nCurShowLevel - _nMakeLevelCount)
  local nShowMaxLevel = math.min(nLevelMax, nCurShowLevel + _nMakeLevelCount)
  for k = nShowMinLevel, nShowMaxLevel do
    self:AddLevelRewardNode(k, tAllRewardData, tLevelRewardPos[k])
  end
  return nShowMinLevel, nShowMaxLevel
end
function SmallRP_Award_UIBP:InitLevelRewardLoop()
  local cObj_smallRPModule = self._cObj_smallRPModule
  local tAllRewardData = cObj_smallRPModule:GetCurRoundLevelRewardCfg()
  local node_root = self.UIRoot
  if tAllRewardData then
    local tAllRewardNode = self._tAllRewardNode
    if next(tAllRewardNode) then
      return
    end
    local tLevelRewardPos = self._tLevelRewardPos
    tLevelRewardPos[1] = 0
    for k, v in ipairs(tAllRewardData) do
      tLevelRewardPos[k + 1] = (tLevelRewardPos[k] or 0) + self:GetCurSizeX(v) + _intervalDis
    end
    local nMaxWidth = tLevelRewardPos[#tLevelRewardPos] - _intervalDis + 10
    local nHeight = node_root.Canvas_LevelReward.Slot:GetSize().Y
    node_root.Canvas_LevelReward.Slot:SetSize(FVector2D(nMaxWidth, nHeight))
    local nScrollToLevel = self:GetCurScrollToLevel()
    local nShowMinLevel, nShowMaxLevel = self:AddLevelRewardNodeByShowLevel(true, nScrollToLevel, tAllRewardData)
    self:InitAvatarDisplay()
    if not nShowMinLevel or not nShowMaxLevel then
      return
    end
    self:DelayAddRewardLevelNode(tAllRewardData, tLevelRewardPos, nShowMinLevel, nShowMaxLevel)
  else
    if not self._cObj_avatarDetails then
      self:InitAvatarDetails()
    end
    local ConstAvatarDisplay = require("client.slua.traits.DetailComponent.AvatarDisplay.ConstAvatarDislay")
    self._cObj_avatarDetails:SetDefaultSceneByType(ConstAvatarDisplay.ESceneType.SmallRP300)
  end
end
function SmallRP_Award_UIBP:DelayAddRewardLevelNode(tAllRewardData, tLevelRewardPos, nShowMinLevel, nShowMaxLevel)
  local nLevelMax = #tAllRewardData
  self:AddTimer(0.1, function()
    local bIsAdd = true
    while bIsAdd do
      bIsAdd = false
      if 1 < nShowMinLevel then
        nShowMinLevel = nShowMinLevel - 1
        self:AddLevelRewardNode(nShowMinLevel, tAllRewardData, tLevelRewardPos[nShowMinLevel])
        bIsAdd = true
      end
      if nShowMaxLevel < nLevelMax then
        nShowMaxLevel = nShowMaxLevel + 1
        self:AddLevelRewardNode(nShowMaxLevel, tAllRewardData, tLevelRewardPos[nShowMaxLevel])
        bIsAdd = true
      end
      coroutine.yield(0.1)
    end
  end)
end
function SmallRP_Award_UIBP:GetCurScrollToLevel()
  local cObj_smallRPModule = self._cObj_smallRPModule
  if not cObj_smallRPModule:GetIsUnlock() then
    return 1
  end
  local nCurLevel = cObj_smallRPModule:GetCurLevel()
  local nScrollToIndex = math.max(1, nCurLevel - 2)
  return nScrollToIndex
end
function SmallRP_Award_UIBP:InitAvatarDisplay()
  local node_root = self.UIRoot
  local cObj_smallRPModule = self._cObj_smallRPModule
  if cObj_smallRPModule:GetIsUnlock() then
    local nCurLevel = cObj_smallRPModule:GetCurLevel()
    local nScrollToIndex = self:GetCurScrollToLevel()
    self:ScrollToIndex(nScrollToIndex)
    self:RefreshSelectLevel(true, nCurLevel)
    local tItemData = cObj_smallRPModule:GetShowItemDataByLevel(nCurLevel)
    self:SetRewardDisplay(tItemData, nCurLevel)
  else
    self:ScrollToIndex(1)
    self:SetWidgetVisible(node_root.CanvasPanel_BG, true)
  end
end
function SmallRP_Award_UIBP:RefreshVideoBtnShow()
  local node_root = self.UIRoot
  local VideoLibrary = require("client.slua.logic.video.lobby_video_function_library")
  if not VideoLibrary.IsCanPlayVideo() then
    self:SetWidgetVisible(node_root.Button_Video, false)
    return
  end
  local cObj_smallRPModule = self._cObj_smallRPModule
  local uObj_actCfg = cObj_smallRPModule:GetActShowCfg() or {}
  if not uObj_actCfg.VideoPath or uObj_actCfg.VideoPath == "" then
    self:SetWidgetVisible(node_root.Button_Video, false)
    return
  end
  local videoDownloadPath = DataMgr.GetVideoDownloadPath(uObj_actCfg.VideoPath)
  if videoDownloadPath ~= "" then
    local PufferConst = require("client.slua.logic.download.puffer_const")
    local common_download_handler = require("client.slua.common.common_download_handler")
    local params = {hideMask = true}
    common_download_handler.CreateDownloadUIReturnUIBase(PufferConst.ENUM_DownloadType.ODPAK, {videoDownloadPath}, self, node_root.Panel_Download, params)
  end
  self:SetWidgetVisible(node_root.Button_Video, true, true)
end
function SmallRP_Award_UIBP:RefreshActUnlock()
  local cObj_smallRPModule = self._cObj_smallRPModule
  local bIsUnlock = cObj_smallRPModule:GetIsUnlock()
  local uObj_ShowColor = bIsUnlock and _ImageColor_White or _ImageColor_Grey
  local node_root = self.UIRoot
  node_root.Image_AddScore:SetColorAndOpacity(uObj_ShowColor)
end
function SmallRP_Award_UIBP:RefreshLevelChange()
  self:RefreshLevelShow()
  self:RefreshGetAllBtnShow()
  for _, v in pairs(self._tAllRewardNode) do
    local cObj_levelReward = v
    cObj_levelReward:RefreshShow(false, self._nLastSelectLevel)
  end
  self:RefreshBannerShow()
end
function SmallRP_Award_UIBP:RefreshLevelShow()
  local node_root = self.UIRoot
  local cObj_smallRPModule = self._cObj_smallRPModule
  local nCurLevel = cObj_smallRPModule:GetCurLevel()
  local nCurScore = cObj_smallRPModule:GetCurScore()
  local bIsMaxLevel = nCurLevel == cObj_smallRPModule:GetMaxLevel()
  local nLevelShow = 0
  if bIsMaxLevel then
    nLevelShow = 1
    node_root.Text_LevelMax:SetText(LocUtil.LocalizeResFormat(6417, nCurLevel))
    self:SetWidgetVisible(node_root.Button_BuyScore, false)
  else
    local nNextLevelScore = cObj_smallRPModule:GetLevelScore(nCurLevel + 1)
    node_root.Text_Level:SetText(LocUtil.LocalizeResFormat(6417, nCurLevel))
    node_root.Text_Score:SetText(LocUtil.LocalizeResFormat(6830, nCurScore, nNextLevelScore))
    node_root.Process_Score:SetPercent(nCurScore / nNextLevelScore)
    self:SetWidgetVisible(node_root.Button_BuyScore, true, true)
  end
  node_root.WidgetSwitcher_Level:SetActiveWidgetIndex(nLevelShow)
end
function SmallRP_Award_UIBP:RefreshGetAllBtnShow()
  local cObj_smallRPModule = self._cObj_smallRPModule
  local node_root = self.UIRoot
  local bIsUnlock = cObj_smallRPModule:GetIsUnlock()
  if bIsUnlock then
    local bIsReceive = cObj_smallRPModule:GetHaveRewardCanReceive()
    local nShowIndex = bIsReceive and 1 or 2
    node_root.WidgetSwitcher_GetAll:SetActiveWidgetIndex(nShowIndex)
  else
    node_root.WidgetSwitcher_GetAll:SetActiveWidgetIndex(0)
  end
end
function SmallRP_Award_UIBP:RefreshUnlockLevelRewardTip()
  local node_root = self.UIRoot
  local cObj_smallRPModule = self._cObj_smallRPModule
  local bIsUnlock = cObj_smallRPModule:GetIsUnlock()
  local nIPLineActId = cObj_smallRPModule:GetIPLineActId()
  local nLevelGetScore = cObj_smallRPModule:GetLevelExtraGetIPScoreNum()
  local bIsShow = bIsUnlock and nIPLineActId and 0 < nIPLineActId and 0 < nLevelGetScore
  self:SetWidgetVisible(node_root.HorizontalBox_UnLockTip, bIsShow)
end
function SmallRP_Award_UIBP:RefreshBannerShow()
  local tLevelRewardPos = self._tLevelRewardPos
  if not next(tLevelRewardPos) then
    return
  end
  local node_root = self.UIRoot
  local cObj_smallRPModule = self._cObj_smallRPModule
  local nCurPos = node_root.ScrollBox_LevelReward:GetScrollOffset()
  local nMaxPos = nCurPos + self._nScrollWidth
  local nCurLevel = 1
  for i = 2, #tLevelRewardPos do
    if nMaxPos >= tLevelRewardPos[i] then
      nCurLevel = i
    else
      break
    end
  end
  local nShowLevel = cObj_smallRPModule:GetCurShowBannerLevel(nCurLevel, self._bIsInit)
  if not nShowLevel then
    self:SetWidgetVisible(node_root.Panel_Preview, false)
    self._nCurBannerShowLevel = nil
    self._nCurBannerShowRoundId = nil
    self._nCurBannerShowItemId = nil
    return
  end
  local nRoundId = cObj_smallRPModule:GetActRoundId()
  local nShowItemId = cObj_smallRPModule:GetShowItemIdByLevel(nShowLevel)
  if not nRoundId or not nShowItemId then
    self:SetWidgetVisible(node_root.Panel_Preview, false)
    self._nCurBannerShowLevel = nil
    self._nCurBannerShowRoundId = nil
    self._nCurBannerShowItemId = nil
    return
  end
  if not self._bIsShowAvatar then
    self:RefreshTitleTextureByReward(nShowLevel, nShowItemId)
  end
  if self._nCurBannerShowLevel == nShowLevel and self._nCurBannerShowRoundId == nRoundId and self._nCurBannerShowItemId == nShowItemId then
    return
  end
  local sBannerCfgTable = self._nActivityId and "SmallRPActivityBanner" or "AssembleActBanner"
  local tBannerShowCfg = CDataTable.GetTableDataByFilter(sBannerCfgTable, "ItemId", nShowItemId, "ActRound", nRoundId)
  if not tBannerShowCfg then
    self:SetWidgetVisible(node_root.Panel_Preview, false)
    self._nCurBannerShowLevel = nil
    self._nCurBannerShowRoundId = nil
    self._nCurBannerShowItemId = nil
    return
  end
  self._nCurBannerShowLevel = nShowLevel
  self._nCurBannerShowRoundId = nRoundId
  self._nCurBannerShowItemId = nShowItemId
  self:SetTexture(node_root.Image_Preview_Banner, tBannerShowCfg.PicPath)
  self:SetWidgetVisible(node_root.Panel_Preview, true)
  if self._bIsInit and self._bIsDragShow then
    self._bIsDragShow = false
    self:RefreshSelectLevel(true, nShowLevel)
    self:SetRewardDisplay(cObj_smallRPModule:GetShowItemDataByLevel(nShowLevel), nShowLevel)
  end
end
function SmallRP_Award_UIBP:RefreshSelectLevel(bResetCurItemIndex, nSelectLevel)
  local nLastSelectLevel = self._nLastSelectLevel
  if nLastSelectLevel and nLastSelectLevel ~= nSelectLevel then
    local cObj_lastLevelReward = self:GetRewardLevelNode(nLastSelectLevel)
    if cObj_lastLevelReward then
      cObj_lastLevelReward:RefreshShow(true, nSelectLevel)
    end
  end
  local cObj_levelReward = self:GetRewardLevelNode(nSelectLevel)
  if cObj_levelReward then
    cObj_levelReward:RefreshShow(bResetCurItemIndex, nSelectLevel)
  end
  self._nLastSelectLevel = nSelectLevel
end
function SmallRP_Award_UIBP:ScrollToIndex(nScrollToLevel)
  local node_root = self.UIRoot
  local nPosX = self._tLevelRewardPos[nScrollToLevel] or 0
  node_root.ScrollBox_LevelReward:SetScrollOffset(nPosX)
  self:RefreshBannerShow()
end
function SmallRP_Award_UIBP:SetRewardDisplay(tItemData, nLevel)
  if not tItemData then
    return
  end
  local nItemId = tItemData.resid
  self:RefreshTitleTextureByReward(nLevel, nItemId)
  if self._nLastAvatarShowLevel == nLevel and self._nLastItemId == nItemId then
    return
  end
  self._nLastItemId = nItemId
  self:SetAvatarShow(nItemId, tItemData.valid_hours)
  self._nLastAvatarShowLevel = nLevel
  self._bIsShowAvatar = true
end
function SmallRP_Award_UIBP:SetAvatarShow(nItemId, nValidHours)
  if not self._cObj_avatarDetails then
    self:InitAvatarDetails()
  end
  _AvatarSceneCfg.itemValidTime = nValidHours
  self._cObj_avatarDetails:SetData(nItemId, _AvatarSceneCfg)
  if tonumber(self._nActivityId) == _nIndiaPreviewActivityId then
    local bLevelLoaded = LobbySceneManager and LobbySceneManager.IsStreamLevelLoaded(_sIndiaPreviewSceneName)
    self:SetWidgetVisible(self.UIRoot.CanvasPanel_BG, not bLevelLoaded)
    EventSystem:postEvent(EVENTTYPE_SPECIAL_OFFER, EVENTID_SPECIAL_OFFER_SET_MASK, not bLevelLoaded)
    return
  end
  self:SetWidgetVisible(self.UIRoot.CanvasPanel_BG, false)
  EventSystem:postEvent(EVENTTYPE_SPECIAL_OFFER, EVENTID_SPECIAL_OFFER_SET_MASK, false)
end
function SmallRP_Award_UIBP:GetRewardLevelNode(nLevel)
  local tAllRewardNode = self._tAllRewardNode
  if not tAllRewardNode[nLevel] then
    local cObj_smallRPModule = self._cObj_smallRPModule
    local tAllRewardData = cObj_smallRPModule:GetCurRoundLevelRewardCfg()
    local nShowPosX = self._tLevelRewardPos[nLevel]
    self:AddLevelRewardNode(nLevel, tAllRewardData, nShowPosX)
  end
  return tAllRewardNode[nLevel]
end
function SmallRP_Award_UIBP:AddLevelRewardNode(nLevel, tAllRewardData, nShowPosX)
  local tAllRewardNode = self._tAllRewardNode
  if not tAllRewardData or tAllRewardNode[nLevel] then
    return
  end
  local tCurLevelReward = tAllRewardData[nLevel]
  local tNextLevelReward = tAllRewardData[nLevel + 1]
  local cObj_levelReward = self:CreateChildWindow(self.UIRoot.Canvas_LevelReward, UIManager.UI_Config.SmallRP_Award_Item_UIBP, nLevel, tCurLevelReward, self:GetCurSizeX(tCurLevelReward), self._tSmallRPContext)
  cObj_levelReward:ResetProBarWidth(tNextLevelReward, _tShowWidth, _intervalDis, _tMultiChooseOneShowWidth, _nBigMultiChooseShowWidth)
  cObj_levelReward:SetAutoSize(true)
  cObj_levelReward:SetAnchors(0, 0, 0, 0)
  cObj_levelReward:SetPosition(nShowPosX or 0, 0)
  tAllRewardNode[nLevel] = cObj_levelReward
  return cObj_levelReward
end
function SmallRP_Award_UIBP:ShowActivityMultiChooseOne(tChooseData, nManualIndex)
  if type(tChooseData) ~= "table" or tChooseData.activity_id ~= self._nActivityId then
    return
  end
  local tManualLevels = tChooseData.manual_levels or {}
  local nLevel = tManualLevels[nManualIndex]
  if not nLevel then
    local SmallRPActivityHandler = require("client.network.Protocol.SmallRPActivityHandler")
    SmallRPActivityHandler.send_small_rp_activity_batch_get_level_award_req(self._nActivityId, tChooseData.selects or {})
    return
  end
  local tLevelChooseData
  for _, tLevelData in ipairs(tChooseData.levels or {}) do
    if tLevelData.level == nLevel then
      tLevelChooseData = tLevelData
      break
    end
  end
  if not tLevelChooseData then
    return
  end
  local tShowData = {
    tAllItemId = tLevelChooseData.all_item_ids,
    nShowGroupId = tLevelChooseData.group_id,
    tValidItem = tLevelChooseData.valid_items,
    tSelectedItem = tChooseData.selected_items,
    fSelectedCallback = function(nSelectIndex, nSelectItemId)
      tChooseData.selects[nLevel] = nSelectIndex
      if nSelectItemId then
        tChooseData.selected_items[nSelectItemId] = true
      end
      self:AddTimerOnce(0, function()
        self:ShowActivityMultiChooseOne(tChooseData, nManualIndex + 1)
      end)
    end
  }
  local Logic_MultiChooseOne = require("client.slua.logic.common.Logic_MultiChooseOne")
  Logic_MultiChooseOne.ShowUI(#tLevelChooseData.all_item_ids, tShowData)
end
function SmallRP_Award_UIBP:CheckIsPlayVideo(bIsForce)
  local VideoLibrary = require("client.slua.logic.video.lobby_video_function_library")
  if not VideoLibrary.IsCanPlayVideo() then
    return
  end
  local cObj_smallRPModule = self._cObj_smallRPModule
  local uObj_actCfg = cObj_smallRPModule:GetActShowCfg() or {}
  if uObj_actCfg.VideoPath and uObj_actCfg.VideoPath ~= "" then
    local bIsPlay = true
    local TimeUtil = require("client.common.time_util")
    local nCurTime = TimeUtil.GetServerTimeInSec()
    local PlayerPrefsSystem = require("client.logic.LogicPlayerPrefs.playerprefs")
    local tSmallRPLocalCache = PlayerPrefsSystem.LoadFileToTable_N(PlayerPrefsSystem.ePlayerPrefsType.eSmallRP) or {}
    if tSmallRPLocalCache.nVideoTime then
      bIsPlay = not TimeUtil.IsSameDay(nCurTime, tSmallRPLocalCache.nVideoTime)
    end
    if bIsForce or bIsPlay then
      tSmallRPLocalCache.nVideoTime = nCurTime
      PlayerPrefsSystem.SaveTableToFile_N(tSmallRPLocalCache, PlayerPrefsSystem.ePlayerPrefsType.eSmallRP)
      VideoLibrary.PlayVideo(uObj_actCfg.VideoPath, {bDoNotChangeCameraSetting = true}, true)
    end
  end
end
function SmallRP_Award_UIBP:GetCurSizeX(tLevelReward)
  if not tLevelReward then
    return 0
  end
  local nItemCount = #tLevelReward
  local bIsMultiChooseOne = tLevelReward[1] and tLevelReward[1].select_one
  if bIsMultiChooseOne then
    return _tMultiChooseOneShowWidth[nItemCount] or _nBigMultiChooseShowWidth
  end
  return _tShowWidth[nItemCount] or 0
end
local class = require("class")
local ui_base = require("client.slua_ui_framework.base")
local CSmallRP_Award_UIBP = Trait.TraitClass(ui_base, nil, SmallRP_Award_UIBP, Traits)
return CSmallRP_Award_UIBP
