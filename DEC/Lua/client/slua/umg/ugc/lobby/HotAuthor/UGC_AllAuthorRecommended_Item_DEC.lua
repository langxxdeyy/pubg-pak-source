local UGC_AllAuthorRecommended_Item = {}
function UGC_AllAuthorRecommended_Item:ctor()
  self.AuthorData = {}
  self.FollowState = 0
end
function UGC_AllAuthorRecommended_Item:RegistEvents()
  self:AddControlEventByControl(self.UIRoot.Button_Follow, "OnClicked", self.OnClickButtonFollow, self)
  self:AddControlEventByControl(self.UIRoot.Common_Avatar_BP, "OnClickItemCallback", self.OnAuthorInfoClickCallback, self)
  self:AddCommonEvent(EVENTTYPE_UGC, EVENTID_UGC_GET_FOLLOW_AUTHOR_LIST, self.OnUpdateFollowStatus, self)
  self:AddCommonEvent(EVENTTYPE_UGC, EVENTID_UGC_HOT_AUTHOR_MODRSP, self.RefreshModItem, self)
  self:AddCommonEvent(EVENTTYPE_UGC, EVENTID_UGC_EXCEED_FOLLOW_LIMIT, self.OnExceedFollowLimit, self)
end
function UGC_AllAuthorRecommended_Item:OnPostInitialize()
end
function UGC_AllAuthorRecommended_Item:OnInitialize()
  self.LoopScrollGrid_Author = self:InitChildClassScrollBox(self.UIRoot.LoopScrollGrid_Author, "client.slua.umg.ugc.lobby.HotAuthor.UGC_AuthorRecomended_ModItem")
end
function UGC_AllAuthorRecommended_Item:InitFollow()
  local LogicUGCAuthor = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicUGCAuthor)
  local follow_status = LogicUGCAuthor:GetAuthorFollowStatus(self.AuthorData.uid) or 0
  log(bWriteLog and "UGC_AllAuthorRecommended_Item:Init follow_status = " .. tostring(follow_status))
  if tonumber(self.AuthorData.uid) == tonumber(DataMgr.roleData.uid) then
    log(bWriteLog and "UGCDetailInfoSubPanel:InitCovers is self")
    self:SetWidgetVisible(self.UIRoot.Button_Follow, false, true)
  else
    self:SetWidgetVisible(self.UIRoot.Button_Follow, true, true)
    self.FollowState = follow_status
    self.UIRoot.Follow:SetActiveWidgetIndex(follow_status)
  end
end
function UGC_AllAuthorRecommended_Item:OnClickButtonFollow()
  self:PlayAudio(sound_config.click_v1)
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
    UGCAuthorHandler.send_ugc_player_update_follow_list_req(1, self.AuthorData.uid)
    tlog_report_utils.ReportTLogEvent(TLogEventDefine.UGC_Main_Hot_Author_Follow, 1, tostring(self.AuthorData.uid))
  else
    UGCAuthorHandler.send_ugc_player_update_follow_list_req(0, self.AuthorData.uid)
    tlog_report_utils.ReportTLogEvent(TLogEventDefine.UGC_Main_Hot_Author_Follow, 0, tostring(self.AuthorData.uid))
  end
end
function UGC_AllAuthorRecommended_Item:OnAuthorInfoClickCallback()
  self:PlayAudio(sound_config.click_v1)
  local bCanShowGuest = true
  if not self.AuthorData.uid or self.AuthorData.uid == tonumber(DataMgr.roleData.uid) then
    if IsWoWEditor then
      UIManager.AndroidBackToLobby()
    else
      UIManager.ShowUI(UIManager.UI_Config.ugc_mine_main)
    end
  else
    local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
    bCanShowGuest = RoleInfoMainSystem.Show(RoleInfoMainSystem.WOW, RoleInfoMainSystem.RoleInfoOpenFromType.WoWItem, self.AuthorData.uid)
  end
  if bCanShowGuest == true then
    EventSystem:postEvent(EVENTTYPE_UGC, EVENTID_UGC_SHOW_GUEST)
  end
end
function UGC_AllAuthorRecommended_Item:OnRefresh(data)
  self.AuthorData = data
  self:InitFollow()
  self:RefreshAuthorText()
  self:RefreshModItem()
end
function UGC_AllAuthorRecommended_Item:RefreshAuthorText()
  local StringUtil = require("common.string_util")
  if self.AuthorData and self.AuthorData.total_play_cnt then
    self.UIRoot.TextBlock_PlayNum:SetText(StringUtil.FormatNum_KMB(self.AuthorData.total_play_cnt))
    self.UIRoot.HorizontalBox_Play:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
  else
    self.UIRoot.HorizontalBox_Play:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  end
  if self.AuthorData and self.AuthorData.total_collect_cnt then
    self.UIRoot.HorizontalBox_Collect:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
    self.UIRoot.TextBlock_CollectNum:SetText(StringUtil.FormatNum_KMB(self.AuthorData.total_collect_cnt))
  else
    self.UIRoot.HorizontalBox_Collect:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  end
  if self.AuthorData and self.AuthorData.total_follower_cnt then
    self.UIRoot.HorizontalBox_Follower:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
    self.UIRoot.TextBlock_FollowerNum:SetText(StringUtil.FormatNum_KMB(self.AuthorData.total_follower_cnt))
  else
    self.UIRoot.HorizontalBox_Follower:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  end
  local logic_profile_get_wrap = require("client.slua.logic.user.profile.logic_profile_get_wrap")
  logic_profile_get_wrap.GetNormalProfiles({
    self.AuthorData.uid
  }, function(profileList)
    if slua.isValid(self.UIRoot) then
      self:UpdataProfile(profileList)
    end
  end, Enum_PROFILE_REPORT_CFG.UGC)
end
function UGC_AllAuthorRecommended_Item:RefreshModItem()
  local LogicUGC = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicUGC)
  local MetaList = {}
  for k, modid in pairs(self.AuthorData.top_play_mod) do
    table.insert(MetaList, LogicUGC:GetModByAllCache(modid))
  end
  self.LoopScrollGrid_Author:SetData(MetaList)
end
function UGC_AllAuthorRecommended_Item:UpdataProfile(profileList)
  for i, profile in pairs(profileList) do
    self.UIRoot.TextBlock_AuthorName:SetText(profile.nickName)
    self.UIRoot.Common_Avatar_BP:InitView(1, profile.uid, profile.picUrl, nil, profile.cur_avatar_box_id, nil)
    self:SetWOWpassImage(profile)
  end
end
function UGC_AllAuthorRecommended_Item:OnUpdateFollowStatus()
  log(bWriteLog and "UGC_AllAuthorRecommended_Item:OnUpdateFollowStatus")
  local LogicUGCAuthor = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicUGCAuthor)
  self.FollowState = LogicUGCAuthor:GetAuthorFollowStatus(self.AuthorData.uid) or 0
  self.UIRoot.Follow:SetActiveWidgetIndex(self.FollowState)
end
function UGC_AllAuthorRecommended_Item:OnExceedFollowLimit(_, _, uid)
  if self.AuthorData.uid == uid then
    ShowNotice(513003)
    self.FollowState = 0
    self.UIRoot.Follow:SetActiveWidgetIndex(self.FollowState)
  end
end
function UGC_AllAuthorRecommended_Item:SetWOWpassImage(profile)
  if not self.UIRoot.SizeBox_WoWPass and not self.UIRoot.Image_WoWPass then
    return
  end
  local IconPath
  if profile.uid == tonumber(DataMgr.roleData.uid) then
    local logic_ugc_WOWPass = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_ugc_WOWPass)
    IconPath = logic_ugc_WOWPass:GetWOWpassIcon()
  else
    local Util_UGC = require("client.slua.logic.ugc.util_ugc")
    if Util_UGC.WoWPassActive(profile) then
      IconPath = Util_UGC.GetWoWPassIconPath(profile)
    end
  end
  local bShowWoWPass = IconPath ~= nil
  self:SetWidgetVisible(self.UIRoot.SizeBox_WoWPass, bShowWoWPass, false)
  if bShowWoWPass then
    local params = {sync = false, bMatchSize = true}
    local CommonUIUtil = require("client.common.ui_util")
    self:SetTexture(self.UIRoot.Image_WoWPass, IconPath, params)
  end
end
local class = require("class")
local ui_base = require("client.slua_ui_framework.component.scroll_box_child_base")
local CUGC_AllAuthorRecommended_Item = class(ui_base, nil, UGC_AllAuthorRecommended_Item)
return CUGC_AllAuthorRecommended_Item
