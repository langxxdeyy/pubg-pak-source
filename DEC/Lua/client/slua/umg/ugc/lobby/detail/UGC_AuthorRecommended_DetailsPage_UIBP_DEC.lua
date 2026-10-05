local UGC_AuthorRecommended_DetailsPage_UIBP = {}
local Config_UGC = require("client.slua.logic.ugc.config_ugc")
local config_ugc_hot_theme = require("client.slua.logic.ugc.hot_theme.config_ugc_hot_theme")
local _NewBatchPullStage = Config_UGC.BatchPullStage.none
local C_RowNum = 2
function UGC_AuthorRecommended_DetailsPage_UIBP:ctor(_, data)
  _NewBatchPullStage = Config_UGC.BatchPullStage.none
  self.data = data or {}
  self.FollowState = 0
  self.bTournament = false
  self.bAuthor = false
  self.bHotTheme = false
  self._NewLastScrollOffset = 0
  self.SendModTime = nil
  self.BeforeOffset = 0
end
function UGC_AuthorRecommended_DetailsPage_UIBP:OnInitialize()
  UGC_AuthorRecommended_DetailsPage_UIBP.__super.OnInitialize(self)
  self.LoopScrollBox_Mod = self:InitChildClassScrollBox(self.UIRoot.LoopScrollBox_Mod, "client.slua.umg.ugc.lobby.detail.UGC_AuthorRecommended_DetailsPage_Item_UIBP")
  if self.data and self.data.style == config_ugc_hot_theme.ItemDataType.ModList then
    self.UIRoot.WidgetSwitcher_Title:SetActiveWidgetIndex(1)
    self.UIRoot.WidgetSwitcher_Skip:SetActiveWidgetIndex(1)
    self.UIRoot.WidgetSwitcher_Skip:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
  elseif self.data and self.data.style == config_ugc_hot_theme.ItemDataType.AuthorList then
    self.UIRoot.WidgetSwitcher_Title:SetActiveWidgetIndex(0)
    self.UIRoot.WidgetSwitcher_Skip:SetActiveWidgetIndex(0)
    local logic_ugc_hot_page = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_ugc_hot_page)
    local Index = logic_ugc_hot_page:CheckAuthorThemeQuantity()
    if Index <= 3 then
      self.UIRoot.WidgetSwitcher_Skip:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
    else
      self.UIRoot.WidgetSwitcher_Skip:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
    end
  else
    self.UIRoot.WidgetSwitcher_Title:SetActiveWidgetIndex(0)
    self.UIRoot.WidgetSwitcher_Skip:SetActiveWidgetIndex(0)
    self.UIRoot.WidgetSwitcher_Skip:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
  end
  local Logic_UGC_TLog = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.Logic_UGC_TLog)
  Logic_UGC_TLog:StartRecordShowModDeduplication()
  local PublishRegionMacros = require("client.slua.config.ClientMacros.PublishRegionMacros")
  local publishRegion = Client.GetPublishRegion()
  if PublishRegionMacros.IsBlueholeFamily() then
    self:SetWidgetVisible(self.UIRoot.Button_SimultaneousMatching, false, false)
  end
  if self.data and self.data.base and self.data.base.desc then
    self:SetWidgetVisible(self.UIRoot.SizeBox_Info, true)
  else
    self:SetWidgetVisible(self.UIRoot.SizeBox_Info, false)
  end
  self.UIRoot.TextBlock_0:SetText(LocUtil.GetLocalizeResStr(81413))
  self:SetWidgetVisible(self.UIRoot.Button_0, false, true)
  if self.data and self.data.data_type and self.data.data_type == "SPEC_THEME" then
    self:SetWidgetVisible(self.UIRoot.Button_0, true, true)
  end
end
function UGC_AuthorRecommended_DetailsPage_UIBP:RegistEvents()
  UGC_AuthorRecommended_DetailsPage_UIBP.__super.RegistEvents(self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Close, self.OnClickClose, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Follow, self.OnClickButtonFollow, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_SimultaneousMatching, self.OnClickRandomPlay, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_MoreAuthorRecommended, self.OnClickMoreAuthors, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Info, self.OnClickButtonInfo, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_0, self.OnClickAlbumThemeUI, self)
  self:AddControlEventByControl(self.UIRoot.Common_Avatar_BP, "OnClickItemCallback", self.OnAuthorInfoClickCallback, self)
  self:AddControlEventByControl(self.UIRoot.LoopScrollBox_Mod, "OnUserScrolled", self._OnUserScrolled, self)
  self:AddControlEventByControl(self.UIRoot.LoopScrollBox_Mod, "OnEndScroll", self._OnEndScroll, self)
  self:AddCommonEvent(EVENTTYPE_UGC, EVENTID_UGC_SELECT_MOD, self.OnSelectModForMatch, self)
  self:AddCommonEvent(EVENTTYPE_UGC, EVENTID_UGC_UPDATE_AUTHOR, self.OnUpdateAuthor, self)
  self:AddCommonEvent(EVENTTYPE_UGC, EVENTID_UGC_UPDATE_AUTHOR_FOLLOW_STATUS, self.OnUpdateFollowStatus, self)
  self:AddCommonEvent(EVENTTYPE_UGC, EVENTID_UGC_DETAIL_MAIN_PANEL_CLOSE, self.OnCloseModDetailUI, self)
  self:AddCommonEvent(EVENTTYPE_UGC, EVENTID_UGC_AUTHOR_SUMMARY_RSP, self.AuthorTextRsp, self)
  self:AddCommonEvent(EVENTTYPE_UGC, EVENTID_UGC_EXCEED_FOLLOW_LIMIT, self.OnExceedFollowLimit, self)
  self:AddCommonEvent(EVENTTYPE_UGC, EVENTID_UGC_SHOW_GUEST, self.OnSelectModForMatch, self)
  self:AddCommonEvent(EVENTTYPE_UGC, EVENTID_UGC_ALBUM_THEME_TASK_REFRESH, self.OnRefreshAlbumThemeTaskUI, self)
end
function UGC_AuthorRecommended_DetailsPage_UIBP:OnPostInitialize()
  UGC_AuthorRecommended_DetailsPage_UIBP.__super.OnPostInitialize(self)
  self:UpdateUI()
  self:ReqModInfoBatch()
  self:CheckOpenWoWPass()
end
function UGC_AuthorRecommended_DetailsPage_UIBP:UpdateUI()
  if self.data and self.data.style == config_ugc_hot_theme.ItemDataType.ModList then
    if self.data.base.stage and self.data.base.stage ~= Config_UGC.TournamentStage.Publicity then
      self.UIRoot.TextBlock_Title:SetText(LocUtil.LocalizeResFormat(8800172, self.data.themeName))
      self.bTournament = true
    else
      self.UIRoot.TextBlock_Title:SetText(self.data.themeName)
      self.bHotTheme = true
    end
  elseif self.data and self.data.style == config_ugc_hot_theme.ItemDataType.AuthorList then
    self.bAuthor = true
    self:InitAuthor(self.data.author_uid)
    local LogicUGCAuthorGuest = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicUGCAuthorGuest)
    local summaryData = LogicUGCAuthorGuest:GetAuthorSummaryData(self.data.author_uid)
    if summaryData then
      self:RefreshAuthorText(summaryData)
    else
      local UGCAuthorHandler = require("client.network.Protocol.UGCAuthorHandler")
      UGCAuthorHandler.send_ugc_author_summary_req(self.data.author_uid)
      log(bWriteLog and "UGC_AuthorRecommended_DetailsPage_UIBP:OnPostInitialize  v.author_uid = " .. self.data.author_uid)
    end
  end
  if self.bAuthor then
    self.modid_list = self.data.mod_list
  else
    self.modid_list = self.data.dataList
  end
end
function UGC_AuthorRecommended_DetailsPage_UIBP:OnClose()
  if self.SendModTime then
    self:RemoveTimer(self.SendModTime)
    self.SendModTime = nil
  end
  UGC_AuthorRecommended_DetailsPage_UIBP.__super.OnClose(self)
end
function UGC_AuthorRecommended_DetailsPage_UIBP:OnSelectModForMatch()
  self:CloseSelf()
end
function UGC_AuthorRecommended_DetailsPage_UIBP:_OnUserScrolled(offset)
  if offset <= 0 then
    return
  end
  if self._NewLastScrollOffset == offset and (_NewBatchPullStage == Config_UGC.BatchPullStage.none or _NewBatchPullStage == Config_UGC.BatchPullStage.respondedWithData) then
    _NewBatchPullStage = Config_UGC.BatchPullStage.shouldRequest
  end
  self:ScrollShowMod(false, self.LoopScrollBox_Mod, offset)
  self._NewLastScrollOffset = offset
end
function UGC_AuthorRecommended_DetailsPage_UIBP:_OnEndScroll()
  if _NewBatchPullStage == Config_UGC.BatchPullStage.shouldRequest then
    _NewBatchPullStage = Config_UGC.BatchPullStage.requested
    self:ReqModInfoBatch()
  end
end
function UGC_AuthorRecommended_DetailsPage_UIBP:OnRefreshAlbumThemeTaskUI(_, _, task_data)
  log_tree("UGC_AuthorRecommended_DetailsPage_UIBP:OnRefreshAlbumThemeTaskUI", task_data)
  self:OnAlbumThemeTaskProgressUI(task_data)
end
function UGC_AuthorRecommended_DetailsPage_UIBP:OnClickClose()
  self:PlayAudio(sound_config.close)
  local Logic_UGC_TLog = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.Logic_UGC_TLog)
  Logic_UGC_TLog:EndRecordShowModDeduplication()
  self:CloseSelf()
end
function UGC_AuthorRecommended_DetailsPage_UIBP:OnClickRandomPlay()
  self:PlayAudio(sound_config.click_v1)
  local LogicUGCMulti = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicUGCMulti)
  local UGCTLogReport = ModuleManager.GetModule(ModuleManager.DataModuleConfig.UGCTLogReport)
  if self.bTournament then
    LogicUGCMulti:ReqSetUGCModBundle(Config_UGC.Enum_Bundle_Type.TourNament, self.data.themeId)
    UGCTLogReport:ReportDelay(TLogEventDefine.UGC_Tournament_ClickRandomPlay, tostring(self.data.themeId))
  else
    LogicUGCMulti:ReqSetUGCModBundle(Config_UGC.Enum_Bundle_Type.HotTheme, self.data.themeId)
    UGCTLogReport:ReportDelay(TLogEventDefine.UGC_HotTheme_ClickRandomPlay, tostring(self.data.themeId))
  end
end
function UGC_AuthorRecommended_DetailsPage_UIBP:OnClickMoreAuthors()
  self:PlayAudio(sound_config.click_v1)
  if self.data and self.data.style == config_ugc_hot_theme.ItemDataType.AuthorList then
    UIManager.ShowUI(UIManager.UI_Config.UGC_AllAuthorRecommended_DetailsPage_UIBP, false)
  else
    UIManager.ShowUI(UIManager.UI_Config.UGC_AllAuthorRecommended_DetailsPage_UIBP, true)
    local BasicDataTLogReport = ModuleManager.GetModule(ModuleManager.DataModuleConfig.BasicDataTLogReport)
    BasicDataTLogReport:ReportDelay(TLogEventDefine.UGC_HotTheme_ClickRandomPlay, tostring(self.data.themeId))
    self:CloseSelf()
  end
end
function UGC_AuthorRecommended_DetailsPage_UIBP:OnClickButtonFollow()
  self:PlayAudio(sound_config.click)
  log(bWriteLog and "UGC_NewMapMod_Author_Item_UIBP:OnClickFollow")
  local UIUtil = require("client.common.ui_util")
  if not UIUtil.CanClickNow(UIUtil.ClickFrequencyLimit.UGCAuthorFollow) then
    return
  end
  if self.FollowState == 0 then
    self.FollowState = 1
  elseif self.FollowState == 1 then
    self.FollowState = 0
  end
  self.UIRoot.Follow:SetActiveWidgetIndex(self.FollowState)
  local tlog_report_utils = require("client.slua.config.tlog.tlog_report_utils")
  local UGCAuthorHandler = require("client.network.Protocol.UGCAuthorHandler")
  if self.FollowState == 1 then
    UGCAuthorHandler.send_ugc_player_update_follow_list_req(1, self.UID)
  else
    UGCAuthorHandler.send_ugc_player_update_follow_list_req(0, self.UID)
  end
end
function UGC_AuthorRecommended_DetailsPage_UIBP:OnAuthorInfoClickCallback()
  self:PlayAudio(sound_config.click_v1)
  local bCanShowGuest = true
  if not self.UID or self.UID == tonumber(DataMgr.roleData.uid) then
    local LogicFitVersionDownload = require("client.slua.logic.download.fit.logic_fitVersion_download")
    if LogicFitVersionDownload.IfNotFitLobbyResDownloadedShowWindow() then
      return
    end
    if IsWoWEditor then
      UIManager.AndroidBackToLobby()
    else
      UIManager.ShowUI(UIManager.UI_Config.ugc_mine_main)
    end
  else
    local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
    bCanShowGuest = RoleInfoMainSystem.Show(RoleInfoMainSystem.WOW, RoleInfoMainSystem.RoleInfoOpenFromType.WoWItem, self.UID)
  end
  if bCanShowGuest == true then
    EventSystem:postEvent(EVENTTYPE_UGC, EVENTID_UGC_SHOW_GUEST)
  end
end
function UGC_AuthorRecommended_DetailsPage_UIBP:OnClickButtonInfo()
  self:PlayAudio(sound_config.click_v1)
  local tipsParam = {
    widget = self.UIRoot.Button_Info,
    content = self.data.base.desc,
    offsetX = -10,
    offsetY = 80
  }
  UIManager.ShowUI(UIManager.UI_Config.Common_Other_Tips_UIBP, tipsParam)
  local tlog_report_utils = require("client.slua.config.tlog.tlog_report_utils")
  tlog_report_utils.ReportTLogEvent(TLogEventDefine.UGC_Click_Hot_Theme_Question, self.data.themeId, "ThemeAll")
end
function UGC_AuthorRecommended_DetailsPage_UIBP:OnClickAlbumThemeUI()
  self:PlayAudio(sound_config.click_v1)
  log(bWriteLog and "UGC_AuthorRecommended_DetailsPage_UIBP:OnClickAlbumThemeUI")
  local LogicFitVersionDownload = require("client.slua.logic.download.fit.logic_fitVersion_download")
  if not LogicFitVersionDownload.IsFitLobbyResDownloaded() then
    LogicFitVersionDownload.ShowFullLobbyResDownloadPopup()
    return
  end
  local logic_ugc_album_theme = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_ugc_album_theme)
  logic_ugc_album_theme:SetAlbumThemeJustBrowseState(true)
  UIManager.ShowUI(UIManager.UI_Config.UGC_AlbumThemeSelect_Popup_UIBP, self.modInfo)
end
function UGC_AuthorRecommended_DetailsPage_UIBP:ReqModInfoBatch(ModInfoList)
  log(bWriteLog and "UGC_AuthorRecommended_DetailsPage_UIBP:ReqModInfoBatch")
  local LogicUGC = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicUGC)
  local ListType
  local _ReqModList = {}
  if self.bTournament then
    ListType = LogicUGC.C_ModListTypes.Match_tab
  elseif self.bAuthor or self.bHotTheme then
    ListType = LogicUGC.C_ModListTypes.HotTheme
  end
  local ConvertModList = {}
  if ModInfoList then
    ModInfoList = LogicUGC:BatchGetModInfo(self.modid_list, nil, nil, {bExportArray = true})
    for id, meta in ipairs(ModInfoList) do
      if self.bHotTheme or self.bAuthor then
        if meta and meta.pub_mod_meta and not meta.pub_mod_meta.perf_off_banner then
          table.insert(ConvertModList, {
            ModInfo = meta.pub_mod_meta,
            hotThemeDataType = self.data.data_type,
            hotThemeId = self.data.themeId
          })
        end
      else
        table.insert(ConvertModList, {
          ModInfo = meta.pub_mod_meta,
          hotThemeDataType = self.data.data_type,
          hotThemeId = self.data.themeId
        })
      end
    end
    ModInfoList = ConvertModList
    ConvertModList = nil
    local ShowModList = {}
    if self.data.video_url then
      table.insert(ModInfoList, 1, {
        video_url = self.data.video_url,
        video_cover_url = self.data.video_cover_url
      })
    end
    for i = 1, #ModInfoList, 2 do
      local TempModList = {}
      if ModInfoList[i].video_url then
        table.insert(TempModList, ModInfoList[i])
      else
        table.insert(TempModList, ModInfoList[i])
      end
      if ModInfoList[i + 1] then
        table.insert(TempModList, ModInfoList[i + 1])
      end
      table.insert(ShowModList, TempModList)
    end
    self:UpdateLoop(ShowModList)
    return
  end
  local ModInfoList = LogicUGC:BatchGetModInfo(self.modid_list, ListType, function(MetaList, ListType, Param, bUseCache, FilterOfflineModList)
    self:OnGetBatchModListRsp(MetaList, ListType, Param, bUseCache, FilterOfflineModList)
  end, {bSplit = true})
end
function UGC_AuthorRecommended_DetailsPage_UIBP:UpdateLoop(ShowModList)
  if self.LoopScrollBox_Mod:GetItemCount() > 0 then
    log(bWriteLog and "UGC_AuthorRecommended_DetailsPage_UIBP:UpdateLoop RefreshAllItems")
    self.LoopScrollBox_Mod:RefreshAllItems(ShowModList)
  else
    log(bWriteLog and "UGC_AuthorRecommended_DetailsPage_UIBP:UpdateLoop SetData")
    self.LoopScrollBox_Mod:SetData(ShowModList)
  end
  if self.SendModTime then
    self:RemoveTimer(self.SendModTime)
    self.SendModTime = nil
  end
  self.SendModTime = self:AddTimerOnce(0.5, function()
    self:ScrollShowMod(true, self.LoopScrollBox_Mod, 0)
  end)
end
function UGC_AuthorRecommended_DetailsPage_UIBP:OnGetBatchModListRsp(MetaList, ListType, Param, bUseCache, FilterOfflineModList)
  self:ReqModInfoBatch(MetaList)
end
function UGC_AuthorRecommended_DetailsPage_UIBP:InitAuthor(uid)
  self.UIRoot.TextBlock_50:SetText(LocUtil.GetLocalizeResStr(8800164) or "")
  local root = self.UIRoot
  self.UID = uid or 0
  if self.UID == tonumber(DataMgr.roleData.uid) then
    root.TextBlock_Name:SetText(DataMgr.roleData.nickName)
    local LogicUGCAuthor = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicUGCAuthor)
    local level = LogicUGCAuthor:GetMineAuthorLevel()
    local authorLevelConfig = Config_UGC.GetAuthorLevelConfigByID(level)
    root.Common_Avatar_BP:InitView(1, self.UID, DataMgr.roleData.headIconUrl, nil, DataMgr.roleData.cur_avatar_box_id, nil)
    self:SetWidgetVisible(self.UIRoot.Button_Follow, false, true)
  else
    local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
    local profile = logic_profile:GetLocalProfile(self.UID)
    if profile then
      root.TextBlock_Name:SetText(profile.nickName)
      root.Common_Avatar_BP:InitView(1, self.UID, profile.picUrl, nil, profile.cur_avatar_box_id, nil)
    else
      local logic_profile_get_wrap = require("client.slua.logic.user.profile.logic_profile_get_wrap")
      logic_profile_get_wrap.GetNormalProfiles({
        self.UID
      }, function(list)
        if list and next(list) and slua.isValid(self.UIRoot) then
          self.UIRoot.TextBlock_Name:SetText(list[1].nickName)
          if self.UIRoot.Common_Avatar_BP then
            self.UIRoot.Common_Avatar_BP:InitView(1, self.UID, list[1].picUrl, nil, list[1].cur_avatar_box_id, nil)
          end
        end
      end, Enum_PROFILE_REPORT_CFG.UGC)
    end
    local LogicUGCAuthor = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicUGCAuthor)
    local AuthorInfo = LogicUGCAuthor:GetAuthorInfo(self.UID)
    if AuthorInfo then
      local level = LogicUGCAuthor:GetAuthorLevel(self.UID)
      self:SetAuthorInfo(AuthorInfo, level)
    else
      local LogicUGCAuthor = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicUGCAuthor)
      LogicUGCAuthor:RequestAuthorInfo(self.UID, true)
    end
  end
end
function UGC_AuthorRecommended_DetailsPage_UIBP:OnUpdateAuthor(_, _, UID)
  log(bWriteLog and "UGC_AuthorRecommended_DetailsPage_UIBP:OnUpdateAuthor, UID = " .. tostring(UID))
  if UID ~= tonumber(self.UID) then
    log(bWriteLog and "UGC_AuthorRecommended_DetailsPage_UIBP:OnUpdateAuthor UID ~=  " .. tostring(UID))
    return
  end
  local LogicUGCAuthor = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicUGCAuthor)
  local AuthorInfo = LogicUGCAuthor:GetAuthorInfo(self.UID)
  local level = LogicUGCAuthor:GetAuthorLevel(self.UID)
  self:SetAuthorInfo(AuthorInfo, level)
end
function UGC_AuthorRecommended_DetailsPage_UIBP:SetAuthorInfo(AuthorInfo, level)
  log(bWriteLog and "UGC_AuthorRecommended_DetailsPage_UIBP:SetAuthorInfo")
  if not AuthorInfo then
    log(bWriteLog and "UGC_AuthorRecommended_DetailsPage_UIBP:SetAuthorInfo AuthorInfo is nil")
    return
  end
  local LogicUGCAuthor = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicUGCAuthor)
  local follow_status = LogicUGCAuthor:GetAuthorFollowStatus(self.UID)
  log(bWriteLog and "UGC_AuthorRecommended_DetailsPage_UIBP:SetAuthorInfo follow_status = " .. tostring(follow_status))
  if tonumber(self.UID) == tonumber(DataMgr.roleData.uid) then
    log(bWriteLog and "UGC_AuthorRecommended_DetailsPage_UIBP:SetAuthorInfo self.UID is self")
    self:SetWidgetVisible(self.UIRoot.Button_Follow, false, true)
  else
    self:SetWidgetVisible(self.UIRoot.Button_Follow, true, true)
    self.FollowState = follow_status
    self.UIRoot.TextBlock_Follow:SetText(LocUtil.GetLocalizeResStr(76424))
    self.UIRoot.TextBlock_HasFollowed:SetText(LocUtil.GetLocalizeResStr(49630))
    self.UIRoot.Follow:SetActiveWidgetIndex(follow_status)
  end
end
function UGC_AuthorRecommended_DetailsPage_UIBP:OnUpdateFollowStatus(_, _, author_uid)
  log(bWriteLog and "UGC_AuthorRecommended_DetailsPage_UIBP:OnUpdateFollowStatus author_uid = " .. tostring(author_uid))
  if author_uid ~= self.UID then
    log(bWriteLog and "UGC_AuthorRecommended_DetailsPage_UIBP:OnUpdateFollowStatus author_uid = " .. tostring(author_uid) .. ", self.UID = " .. tostring(self.UID))
    return
  end
  local LogicUGCAuthor = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicUGCAuthor)
  self.FollowState = LogicUGCAuthor:GetAuthorFollowStatus(self.UID) or 0
  self.UIRoot.Follow:SetActiveWidgetIndex(self.FollowState)
end
function UGC_AuthorRecommended_DetailsPage_UIBP:AuthorTextRsp(_, _, author_uid, result)
  if author_uid == self.data.author_uid then
    self:RefreshAuthorText(result)
  end
end
function UGC_AuthorRecommended_DetailsPage_UIBP:RefreshAuthorText(AuthorData)
  local StringUtil = require("common.string_util")
  local AuthorData = AuthorData
  if AuthorData and AuthorData.total_play_cnt then
    local value = StringUtil.FormatNum_KMB(AuthorData.total_play_cnt) or 0
    self.UIRoot.TextBlock_PlayNum:SetText(value)
    self.UIRoot.HorizontalBox_Play:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
  else
    self.UIRoot.HorizontalBox_Play:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  end
  if AuthorData and AuthorData.total_collect_cnt then
    local value = StringUtil.FormatNum_KMB(AuthorData.total_collect_cnt) or 0
    self.UIRoot.HorizontalBox_Score:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    self.UIRoot.TextBlock_Score:SetText(value)
  else
    self.UIRoot.HorizontalBox_Score:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  end
  if AuthorData and AuthorData.total_follower_cnt then
    local value = StringUtil.FormatNum_KMB(AuthorData.total_follower_cnt) or 0
    self.UIRoot.HorizontalBox_Collect:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    self.UIRoot.TextBlock_CollectNum:SetText(value)
  else
    self.UIRoot.HorizontalBox_Collect:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  end
end
function UGC_AuthorRecommended_DetailsPage_UIBP:OnCloseModDetailUI(_, _, bCloseByManual)
  if not bCloseByManual then
    self:CloseSelf()
  end
end
function UGC_AuthorRecommended_DetailsPage_UIBP:OnHotThemeUpdated(_, _, ListType, bIsDirty, MetaList, Param, FilterOfflineModList)
  self:UpdateUI()
end
function UGC_AuthorRecommended_DetailsPage_UIBP:OnExceedFollowLimit()
  ShowNotice(513003)
  self.FollowState = 0
  self.UIRoot.Follow:SetActiveWidgetIndex(self.FollowState)
end
function UGC_AuthorRecommended_DetailsPage_UIBP:ScrollShowMod(IsInit, widget, offset)
  if not widget and not widget.UIRoot then
    log(bWriteLog and "UGC_AuthorRecommended_DetailsPage_UIBP:ScrollShowMod widget and widget.root is nil")
    return
  end
  local LoopWide = math.floor(widget.UIRoot:GetViewSize().X)
  local PaddingX = math.floor(widget.UIRoot.Padding)
  local ItemWide = math.floor(widget.UIRoot.ItemSize) + PaddingX
  local Deviation = LoopWide % ItemWide
  local StartIndex = (LoopWide - Deviation) / ItemWide
  local modlist = widget:GetSetData()
  if IsInit then
    for i = 1, StartIndex do
      if modlist[i] then
        for Row, temp in ipairs(modlist[i]) do
          if temp and temp.ModInfo then
            self:SendModReachTLog(temp.ModInfo, Row, i, temp.hotThemeDataType, temp.hotThemeId)
          end
        end
      end
    end
    self.BeforeOffset = 0
  elseif ItemWide <= offset + Deviation - self.BeforeOffset then
    self.BeforeOffset = offset + Deviation
    local lineIndex = (self.BeforeOffset - self.BeforeOffset % ItemWide) / ItemWide
    if lineIndex and 1 <= lineIndex then
      local Num = math.floor(lineIndex + StartIndex)
      for Row, temp in ipairs(modlist[Num]) do
        if temp and temp.ModInfo then
          self:SendModReachTLog(temp.ModInfo, Row, Num, temp.hotThemeDataType, temp.hotThemeId)
        end
      end
    end
  end
end
function UGC_AuthorRecommended_DetailsPage_UIBP:SendModReachTLog(modInfo, Row, Index, data_type, hotThemeId)
  if not modInfo then
    log(bWriteLog and "UGC_AuthorRecommended_DetailsPage_UIBP:SendModReachTLog modInfo is nil")
    return
  end
  log(bWriteLog and "UGC_AuthorRecommended_DetailsPage_UIBP:SendModReachTLog modid = " .. modInfo.mod_id .. " Index = " .. Index)
  local logic_ugc_hot_page = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_ugc_hot_page)
  if data_type and (data_type == "TRAFFIC_POOL_GROWTH" or data_type == "SPEC_THEME") then
    logic_ugc_hot_page:AddReportExpose(modInfo.mod_id)
  end
  if hotThemeId == 209 and logic_ugc_hot_page.white_list and logic_ugc_hot_page.white_list[modInfo.mod_id] then
    logic_ugc_hot_page:AddReportExpose(modInfo.mod_id)
  end
  local params = {
    position = (Index - 1) * C_RowNum + Row,
    row = Row,
    col = Index,
    theme_id = self.data.themeId
  }
  local Logic_UGC_TLog = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.Logic_UGC_TLog)
  Logic_UGC_TLog:SendModTLog(modInfo.mod_id, TLogEventDefine.UGC_Mod_Exposure_Main, params)
end
function UGC_AuthorRecommended_DetailsPage_UIBP:OnAlbumThemeTaskProgressUI(task_progress_data)
  log(bWriteLog and "UGC_AuthorRecommended_DetailsPage_UIBP:AlbumThemeTaskUI")
  if not (self.data and self.data.data_type) or self.data.data_type ~= "SPEC_THEME" then
    self:SetWidgetVisible(self.UIRoot.CanvasPanel_Bottom, false)
    log(bWriteLog and "UGC_AuthorRecommended_DetailsPage_UIBP:AlbumThemeTaskUI data_type is nil or not SPEC_THEME")
    return
  end
  local data_config_marco = require("client.logic.data.data_config_marco")
  local BasicDataServerTable = ModuleManager.GetModule(ModuleManager.DataModuleConfig.BasicDataServerTable)
  local taskCfgs = BasicDataServerTable:GetCacheData(data_config_marco.wow_spec_theme_task_conf_table) or {}
  if not taskCfgs or not next(taskCfgs) then
    log(bWriteLog and "UGC_AuthorRecommended_DetailsPage_UIBP:AlbumThemeTaskUI taskCfgs is nil")
    return
  end
  local logic_ugc_album_theme = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_ugc_album_theme)
  task_progress_data = logic_ugc_album_theme.AlbumThemeTaskDataList
  self:SetWidgetVisible(self.UIRoot.CanvasPanel_Bottom, true)
  if not task_progress_data then
    self:SetWidgetVisible(self.UIRoot.CanvasPanel_Bottom, false)
    log(bWriteLog and "UGC_AuthorRecommended_DetailsPage_UIBP:AlbumThemeTaskUI task_progress_data is nil")
    return
  end
  local task_id
  for taskId, _ in pairs(task_progress_data) do
    task_id = taskId
    break
  end
  self.UIRoot.Lua_CommonItems:InitView(taskCfgs[task_id].resid_1, taskCfgs[task_id].count_1)
  if task_progress_data[task_id] then
    if task_progress_data[task_id].status == 0 then
      self.UIRoot.Lua_CommonItems:SetAwardState(0)
      self.UIRoot.Lua_CommonItems:EnableShowTips(true)
    elseif task_progress_data[task_id].status == 1 then
      self.UIRoot.Lua_CommonItems:SetAwardState(1)
      local fClickItemCallback = function()
        logic_ugc_album_theme:send_spec_theme_task_receive_reward_req(task_id)
      end
      self.UIRoot.Lua_CommonItems:SetClickItemCallback(fClickItemCallback)
    elseif task_progress_data[task_id].status == 2 then
      self.UIRoot.Lua_CommonItems:SetAwardState(2)
      self.UIRoot.Lua_CommonItems:EnableShowTips(true)
    end
  end
  self.UIRoot.UTRichTextBlock_Time:SetText(LocUtil.LocalizeResFormat(taskCfgs[task_id].task_description_id, task_progress_data[task_id].total_progress))
  self.UIRoot.UTRichTextBlock_Count:SetText(LocUtil.LocalizeResFormat(81399, task_progress_data[task_id].finish_count, taskCfgs[task_id].circle_count))
end
function UGC_AuthorRecommended_DetailsPage_UIBP:CheckOpenWoWPass()
  local logic_ugc_WOWPass = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_ugc_WOWPass)
  if logic_ugc_WOWPass:GetValidUGCPassInfo() then
    self:OnAlbumThemeTaskProgressUI()
  else
    log(bWriteLog and "UGC_AuthorRecommended_DetailsPage_UIBP:CheckOpenWoWPass is nil")
    self:SetWidgetVisible(self.UIRoot.CanvasPanel_Bottom, false)
  end
end
function UGC_AuthorRecommended_DetailsPage_UIBP:GetDataForJumpBack()
  return {
    ctorData = {
      [1] = self.data
    }
  }
end
local class = require("class")
local ui_base = require("client.slua_ui_framework.base")
local CUI_UGC_Detail_Info = class(ui_base, nil, UGC_AuthorRecommended_DetailsPage_UIBP)
return CUI_UGC_Detail_Info
