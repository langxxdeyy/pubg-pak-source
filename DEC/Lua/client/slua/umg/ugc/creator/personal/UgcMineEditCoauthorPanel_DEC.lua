local UgcMineEditCoauthorPanel = {}
local Config_UGC = require("client.slua.logic.ugc.config_ugc")
local C_MAX_SELECT_NUM = 8
function UgcMineEditCoauthorPanel:ctor(_, coauthorList, selectedUids)
  self.coauthorList = coauthorList
  self.selectedUids = selectedUids
  if selectedUids then
    self.selectedUidSet = {}
    for _, uid in pairs(self.selectedUids) do
      self.selectedUidSet[uid] = true
    end
    self.selectedNum = #self.selectedUids
  end
  self.UID2Profiles = {}
end
function UgcMineEditCoauthorPanel:OnInitialize()
  UgcMineEditCoauthorPanel.__super.OnInitialize(self)
  if self:IsGuestMode() then
    self.UIRoot.CanvasPanel_ModifyShortcut:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  else
    self.UIRoot.CanvasPanel_ModifyShortcut:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
  end
  self.Common_Popup_Large_UIBP = self:InitCommonPopup(self.UIRoot.Common_Popup_Large_UIBP)
  if self:IsGuestMode() then
    self.Common_Popup_Large_UIBP:SetData(self, LocUtil.GetLocalizeResStr(66444))
    self.UIRoot.TextBlock_Tip:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  else
    self.Common_Popup_Large_UIBP:SetData(self, LocUtil.GetLocalizeResStr(66445), {
      helpInfo = {
        titleText = LocUtil.GetLocalizeResStr(4539),
        contentText = LocUtil.GetLocalizeStrConcatenation(66455)
      }
    })
    self.UIRoot.TextBlock_Tip:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    self.UIRoot.TextBlock_Tip:SetText(LocUtil.GetLocalizeResStr(66448))
  end
  self.coauthorPendingWidgetList = self:InitScrollBox(self.UIRoot.LoopScrollGrid_0)
  self.coauthorPendingWidgetList:SetRefreshItemCallback(self.OnRefreshAuthor, self)
  if not self:IsGuestMode() then
    self.coauthorPreviewWidgetList = self:InitScrollBox(self.UIRoot.LoopScrollGrid_1)
    self.coauthorPreviewWidgetList:SetRefreshItemCallback(self.OnPreviewRefreshAuthor, self)
  end
  local uids = {}
  if self:IsGuestMode() then
    uids = self.coauthorList
  else
    for _, uinfo in pairs(self.coauthorList) do
      table.insert(uids, uinfo[1])
    end
  end
  local logic_profile_get_wrap = require("client.slua.logic.user.profile.logic_profile_get_wrap")
  logic_profile_get_wrap.GetNormalProfiles(uids, function(profileList)
    for i, profile in pairs(profileList) do
      self.UID2Profiles[profile.uid] = profile
    end
    self.coauthorPendingWidgetList:SetData(self.coauthorList)
    if self.coauthorPreviewWidgetList then
      self.coauthorPreviewWidgetList:SetData(self.selectedUids)
    end
    self:RefreshUI()
  end, Enum_PROFILE_REPORT_CFG.UGC)
  self.UIRoot.TextBlock_2:SetText(LocUtil.GetLocalizeResStr(110036))
end
function UgcMineEditCoauthorPanel:RegistEvents()
  UgcMineEditCoauthorPanel.__super.RegistEvents(self)
  self.coauthorPendingWidgetList:AddItemWidgetChildEvent("CheckBox_Active", "OnCheckStateChanged", self.OnAuthorCheckboxChanged, self)
  self.coauthorPendingWidgetList:AddItemWidgetChildEvent("Common_Avatar_BP", "OnClickItemCallback", self.OnAuthorClick, self)
  if self.coauthorPreviewWidgetList then
    self.coauthorPreviewWidgetList:AddItemWidgetChildEvent("Button_Delete", "OnClicked", self.OnPreviewWidgetClick, self)
  end
  self:AddOnClickedEventByControl(self.UIRoot.Button_Submit, self.OnClickSubmit, self)
end
function UgcMineEditCoauthorPanel:OnPostInitialize()
  UgcMineEditCoauthorPanel.__super.OnPostInitialize(self)
end
function UgcMineEditCoauthorPanel:OnClose()
  EventSystem:postEvent(EVENTTYPE_UGC, EVENTID_UGC_OPEN_COAUTHOR_PANEL, false)
end
function UgcMineEditCoauthorPanel:OnAuthorCheckboxChanged(widget, index, check)
  print(bWriteLog and "UgcMineEditCoauthorPanel:OnAuthorCheckboxChange")
  local audio_util = require("client.common.audio_util")
  audio_util.PlayAudio(sound_config.click_v1)
  local itemData = self.coauthorPendingWidgetList:GetItemData(index)
  local Uid = itemData[1]
  if check then
    if self.selectedNum < C_MAX_SELECT_NUM then
      self:SelectAuthor(Uid)
    else
      widget.CheckBox_Active:SetCheckedState(0)
      ShowNotice(LocUtil.GetLocalizeResStr(48613))
    end
  else
    self:UnselectAuthor(Uid)
  end
  self.coauthorPreviewWidgetList:SetData(self.selectedUids)
  self:RefreshUI()
end
function UgcMineEditCoauthorPanel:OnAuthorClick(widget, index)
  local audio_util = require("client.common.audio_util")
  audio_util.PlayAudio(sound_config.click_v1)
  local itemData = self.coauthorPendingWidgetList:GetItemData(index)
  local Uid
  if self:IsGuestMode() then
    Uid = itemData
  else
    Uid = itemData[1]
  end
  local bCanShowGuest = true
  if Uid == tonumber(DataMgr.roleData.uid) then
    if IsWoWEditor then
      UIManager.AndroidBackToLobby()
    else
      UIManager.ShowUI(UIManager.UI_Config.ugc_mine_main)
    end
  else
    local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
    bCanShowGuest = RoleInfoMainSystem.Show(RoleInfoMainSystem.WOW, RoleInfoMainSystem.RoleInfoOpenFromType.WoWItem, Uid)
  end
  if bCanShowGuest == true then
    EventSystem:postEvent(EVENTTYPE_UGC, EVENTID_UGC_SHOW_GUEST)
    self:CloseSelf()
  end
  EventSystem:postEvent(EVENTTYPE_UGC, EVENTID_UGC_OPEN_COAUTHOR_PANEL, true)
end
function UgcMineEditCoauthorPanel:OnRefreshAuthor(widget, index)
  print(bWriteLog and "UgcMineEditCoauthorPanel:OnRefreshAuthor")
  local itemData = self.coauthorPendingWidgetList:GetItemData(index)
  local Uid, ModifyTime
  if self:IsGuestMode() then
    Uid = itemData
  else
    Uid = itemData[1]
    ModifyTime = itemData[2]
  end
  local Profile = self.UID2Profiles[Uid]
  if Profile then
    widget.TextBlock_PlayerName:SetText(Profile.nickName)
    widget.Common_Avatar_BP:InitView(1, Profile.uid, Profile.picUrl, Profile.sex, Profile.cur_avatar_box_id, Profile.level, false, "")
    widget.Common_Avatar_BP:SetButtonEnabled(true)
  else
    widget.TextBlock_PlayerName:SetText(tostring(Uid))
  end
  widget.Image_flag:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  widget.UnknowPass_ContinuousBuy_BP:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  if self:IsGuestMode() then
    widget.CheckBox_Active:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  else
    widget.CheckBox_Active:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
    if self:IsAuthorSelected(Uid) then
      widget.CheckBox_Active:SetCheckedState(1)
    else
      widget.CheckBox_Active:SetCheckedState(0)
    end
  end
  if self:IsGuestMode() then
    widget.TextBlock_ModifyDate:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  elseif ModifyTime ~= nil then
    widget.TextBlock_ModifyDate:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    local formattedDate = os.date("%Y-%m-%d", ModifyTime)
    local ModifyTimeText = LocUtil.LocalizeResFormat(66446, formattedDate)
    widget.TextBlock_ModifyDate:SetText(ModifyTimeText)
  end
end
function UgcMineEditCoauthorPanel:OnPreviewRefreshAuthor(widget, index)
  local itemData = self.coauthorPreviewWidgetList:GetItemData(index)
  local Uid
  Uid = itemData
  local Profile = self.UID2Profiles[Uid]
  if Profile then
    widget.Common_Avatar_BP:InitView(1, Profile.uid, Profile.picUrl, Profile.sex, Profile.cur_avatar_box_id, Profile.level, false, "")
    widget.Common_Avatar_BP:SetButtonEnabled(false)
  end
end
function UgcMineEditCoauthorPanel:OnPreviewWidgetClick(widget, index)
  local audio_util = require("client.common.audio_util")
  audio_util.PlayAudio(sound_config.click_v1)
  local itemData = self.coauthorPreviewWidgetList:GetItemData(index)
  local Uid = itemData
  self:UnselectAuthor(Uid)
  self.coauthorPendingWidgetList.UIRoot:RefreshAllItems()
  self.coauthorPreviewWidgetList:SetData(self.selectedUids)
  self:RefreshUI()
end
function UgcMineEditCoauthorPanel:IsGuestMode()
  return self.selectedUidSet == nil
end
function UgcMineEditCoauthorPanel:IsAuthorSelected(uid)
  return self.selectedUidSet[uid] == true
end
function UgcMineEditCoauthorPanel:SelectAuthor(uid)
  if self.selectedUidSet[uid] then
    return
  end
  self.selectedNum = self.selectedNum + 1
  table.insert(self.selectedUids, uid)
  self.selectedUidSet[uid] = true
end
function UgcMineEditCoauthorPanel:UnselectAuthor(uid)
  if not self.selectedUidSet[uid] then
    return
  end
  local indexToRemove
  for i, value in ipairs(self.selectedUids) do
    if value == uid then
      indexToRemove = i
      break
    end
  end
  if indexToRemove then
    table.remove(self.selectedUids, indexToRemove)
  end
  self.selectedNum = self.selectedNum - 1
  self.selectedUidSet[uid] = false
end
function UgcMineEditCoauthorPanel:OnClickSubmit()
  local audio_util = require("client.common.audio_util")
  audio_util.PlayAudio(sound_config.click_v1)
  EventSystem:postEvent(EVENTTYPE_UGC, EVENTID_UGC_COAUTHOR_SELECTED_UPDATE, self.selectedUids)
  self:CloseSelf()
end
function UgcMineEditCoauthorPanel:RefreshUI()
  if not self:IsGuestMode() then
    if self.selectedNum > 6 then
      self.UIRoot.TextBlock_Tip:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
    else
      self.UIRoot.TextBlock_Tip:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    end
  end
end
function UgcMineEditCoauthorPanel:GetDataForJumpBack()
  return {
    ctorData = {
      [1] = self.coauthorList,
      [2] = self.selectedUids
    }
  }
end
local class = require("class")
local ui_base = require("client.slua_ui_framework.base")
local CUgcMineEditCoauthorPanel = class(ui_base, nil, UgcMineEditCoauthorPanel)
return CUgcMineEditCoauthorPanel
