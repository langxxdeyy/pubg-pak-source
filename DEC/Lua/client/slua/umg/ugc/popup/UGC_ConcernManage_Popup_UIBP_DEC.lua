local UGC_ConcernManage_Popup_UIBP = {}
function UGC_ConcernManage_Popup_UIBP:ctor()
  self.profileReqList = {}
end
function UGC_ConcernManage_Popup_UIBP:OnInitialize()
  UGC_ConcernManage_Popup_UIBP.__super.OnInitialize(self)
  self.Common_Popup_Large_UIBP = self:InitCommonPopup(self.UIRoot.Common_Popup_Large_UIBP)
  self.LoopScrollGrid_Follow = self:InitScrollBox(self.UIRoot.LoopScrollGrid_Follow)
end
function UGC_ConcernManage_Popup_UIBP:RegistEvents()
  UGC_ConcernManage_Popup_UIBP.__super.RegistEvents(self)
  self.LoopScrollGrid_Follow:SetRefreshItemCallback(self.OnRefreshFollowItem, self)
  self.LoopScrollGrid_Follow:AddItemWidgetChildEvent("Button_Follow", "OnClicked", self.OnClickFollowItem, self)
  self.LoopScrollGrid_Follow:AddItemWidgetChildEvent("Common_Avatar_BP", "OnClickItemCallback", self.OnClickItemHead, self)
  self:AddCommonEvent(EVENTTYPE_UGC, EVENTID_UGC_GET_FOLLOW_AUTHOR_LIST, self.OnFollowListRsp, self)
  self:AddCommonEvent(EVENTTYPE_PROFILE, EVENTID_PROFILE_LIST_UPDATE, self.OnProfileListRsp, self)
  self:AddCommonEvent(EVENTTYPE_UGC, EVENTID_UGC_UPDATE_AUTHOR_FOLLOW_STATUS, self.OnUpdateFollowStatus, self)
end
function UGC_ConcernManage_Popup_UIBP:OnPostInitialize()
  UGC_ConcernManage_Popup_UIBP.__super.OnPostInitialize(self)
  self.Common_Popup_Large_UIBP:SetData(self, LocUtil.GetLocalizeResStr(49631))
  self:UpdateUI()
  local UGCAuthorHandler = require("client.network.Protocol.UGCAuthorHandler")
  UGCAuthorHandler.send_ugc_get_player_follow_author_list_req()
  self:AddTimerLoop(0, function()
    if #self.profileReqList > 0 then
      local logic_profile_get_wrap = require("client.slua.logic.user.profile.logic_profile_get_wrap")
      logic_profile_get_wrap.GetNormalProfiles(self.profileReqList, nil, Enum_PROFILE_REPORT_CFG.UGC)
      self.profileReqList = {}
    end
  end, TIMER_INFINITE, 0.2)
end
function UGC_ConcernManage_Popup_UIBP:UpdateUI()
  local LogicUGCAuthor = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicUGCAuthor)
  local followList = LogicUGCAuthor:GetSortedFollowList()
  local followNum = #followList
  if 0 < followNum then
    self.UIRoot.WidgetSwitcher_0:SetActiveWidgetIndex(0)
    for key, value in pairs(followList) do
      value.FollowState = LogicUGCAuthor:GetAuthorFollowStatus(value.uid) or 1
    end
    self.LoopScrollGrid_Follow:SetData(followList)
  else
    self.UIRoot.WidgetSwitcher_0:SetActiveWidgetIndex(1)
    self.UIRoot.TextBlock_Empty:SetText(LocUtil.GetLocalizeResStr(49634))
  end
  for k, v in ipairs(followList) do
    local follow_status = LogicUGCAuthor:GetAuthorFollowStatus(v.uid)
    if follow_status == 0 then
      followNum = followNum - 1
    end
  end
  local max_follow_num = LogicUGCAuthor:GetMaxFollowNum()
  self.UIRoot.TextBlock_FollowNum:SetText(LocUtil.LocalizeResFormat(49632, followNum, max_follow_num))
end
function UGC_ConcernManage_Popup_UIBP:OnRefreshFollowItem(widget, index)
  local info = self.LoopScrollGrid_Follow:GetItemData(index)
  local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
  local profile = logic_profile:GetLocalProfile(info.uid)
  if not profile then
    log(bWriteLog and "UGC_Rank_UIBP:OnRefreshRankItem insert req uid = " .. tostring(info.uid))
    local TableUtil = require("common.table_util")
    if TableUtil.IsInTable(self.profileReqList, info.uid) == false then
      table.insert(self.profileReqList, info.uid)
    end
    return
  end
  widget.Common_Avatar_BP:InitView(1, info.uid, profile.picUrl, 0, profile.cur_avatar_box_id, profile.level, false, "")
  widget.TextBlock_AuthorName:SetText(profile.nickName)
  local StringUtil = require("common.string_util")
  local formatNum = StringUtil.FormatNum_KMB(info.total_follower_cnt or 0)
  widget.TextBlock_FollowNum:SetText(LocUtil.LocalizeResFormat(49633, formatNum))
  widget.TextBlock_Follow:SetText(LocUtil.GetLocalizeResStr(76424))
  widget.TextBlock_HasFollowed:SetText(LocUtil.GetLocalizeResStr(49630))
  widget.WidgetSwitcher_1:SetActiveWidgetIndex(info.FollowState)
end
function UGC_ConcernManage_Popup_UIBP:OnClickFollowItem(widget, index)
  self:PlayAudio(sound_config.click)
  local UIUtil = require("client.common.ui_util")
  if not UIUtil.CanClickNow(UIUtil.ClickFrequencyLimit.UGCAuthorFollow) then
    return
  end
  local tlog_report_utils = require("client.slua.config.tlog.tlog_report_utils")
  local info = self.LoopScrollGrid_Follow:GetItemData(index)
  if info.FollowState == 1 then
    info.FollowState = 0
  elseif info.FollowState == 0 then
    info.FollowState = 1
  end
  local UGCAuthorHandler = require("client.network.Protocol.UGCAuthorHandler")
  if info.FollowState == 1 then
    UGCAuthorHandler.send_ugc_player_update_follow_list_req(1, info.uid)
    tlog_report_utils.ReportTLogEvent(TLogEventDefine.UGC_Follow_Manage_Follow_Click, 1, tostring(info.uid))
  else
    UGCAuthorHandler.send_ugc_player_update_follow_list_req(0, info.uid)
    tlog_report_utils.ReportTLogEvent(TLogEventDefine.UGC_Follow_Manage_Follow_Click, 0, tostring(info.uid))
  end
end
function UGC_ConcernManage_Popup_UIBP:OnClickItemHead(widget, index, uid)
  self:PlayAudio(sound_config.click_v1)
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  if RoleInfoMainSystem.Show(RoleInfoMainSystem.WOW, RoleInfoMainSystem.RoleInfoOpenFromType.WoWItem, tonumber(uid)) then
    EventSystem:postEvent(EVENTTYPE_UGC, EVENTID_UGC_SHOW_GUEST)
    self:CloseSelf()
  end
end
function UGC_ConcernManage_Popup_UIBP:OnFollowListRsp()
  self:UpdateUI()
end
function UGC_ConcernManage_Popup_UIBP:OnProfileListRsp()
  self.LoopScrollGrid_Follow:RefreshAllItems()
end
function UGC_ConcernManage_Popup_UIBP:OnUpdateFollowStatus()
  self:UpdateUI()
end
local class = require("class")
local ui_base = require("client.slua_ui_framework.base")
local CUGC_ConcernManage_Popup_UIBP = class(ui_base, nil, UGC_ConcernManage_Popup_UIBP)
return CUGC_ConcernManage_Popup_UIBP
