local SetDisplay_Item_UIBP = {}
local logic_friendlist_custom_utils = require("client.slua.logic.friend.logic_friendlist_custom_utils")
function SetDisplay_Item_UIBP:ctor()
end
function SetDisplay_Item_UIBP:RegistEvents()
  if self.UIRoot.CheckBox_Set then
    self:AddOnCheckStateChangedEventByControl(self.UIRoot.CheckBox_Set, self.OnCheckBoxSetChanged, self)
  end
  if self.UIRoot.Button_Setting then
    self:AddOnClickedEventByControl(self.UIRoot.Button_Setting, self.OnClickButtonSetting, self)
  end
end
function SetDisplay_Item_UIBP:OnCheckBoxSetChanged(isChecked)
  if not self.data then
    return
  end
  self:PlayAudio(sound_config.toggle_v1)
  log(bWriteLog and string.format("SetDisplay_Item_UIBP:OnCheckBoxSetChanged itemName=%s, isChecked=%s, isDisabled=%s", self.data.itemName or "nil", tostring(isChecked), tostring(self.data.isDisabled)))
  if isChecked and self.data.isDisabled then
    log(bWriteLog and "SetDisplay_Item_UIBP:OnCheckBoxSetChanged limit reached, reverting checkbox")
    if self.UIRoot.CheckBox_Set then
      self.UIRoot.CheckBox_Set:SetCheckedState(UEnums.ECheckBoxState.Unchecked)
    end
    ShowNotice(87399)
    return
  end
  local parentUI = self:GetLoopScrollBoxParentUI()
  if not parentUI or not parentUI.currentSwitchValue then
    log(bWriteLog and "SetDisplay_Item_UIBP:OnCheckBoxSetChanged parentUI or currentSwitchValue is nil")
    return
  end
  local logic_friendlist_custom_utils = require("client.slua.logic.friend.logic_friendlist_custom_utils")
  local oldSwitch = parentUI.currentSwitchValue
  local newSwitch = logic_friendlist_custom_utils.SetSwitch(oldSwitch, self.data.bitMask, isChecked)
  parentUI.currentSwitchValue = newSwitch
  log(bWriteLog and string.format("SetDisplay_Item_UIBP:OnCheckBoxSetChanged oldSwitch=%d (0x%X), newSwitch=%d (0x%X)", oldSwitch, oldSwitch, newSwitch, newSwitch))
  self.data.IsOpen = isChecked and 1 or 0
  if not isChecked then
    if parentUI.RefreshDisplayItems then
      parentUI:RefreshDisplayItems()
      log(bWriteLog and "SetDisplay_Item_UIBP:OnCheckBoxSetChanged triggered RefreshDisplayItems (switch OFF)")
    end
  elseif parentUI.RefreshItemStates then
    parentUI:RefreshItemStates()
    log(bWriteLog and "SetDisplay_Item_UIBP:OnCheckBoxSetChanged triggered RefreshItemStates (switch ON)")
  end
  EventSystem:postEvent(EVENTTYPE_LOBBY, EVENT_FRIENDLIST_ITEM_CUMSTOM, self.data.bitMask)
end
function SetDisplay_Item_UIBP:OnClickButtonSetting()
  if not self.data then
    return
  end
  self:PlayAudio(sound_config.click_v1)
  log(bWriteLog and string.format("SetDisplay_Item_UIBP:OnClickButtonSetting itemName=%s", self.data.itemName or "nil"))
  if self.data.bitMask == logic_friendlist_custom_utils.SWITCH_MASK.Gender then
    local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
    local PersonalizationConst = require("client.slua.umg.roleInfoNew.PersonalizationConst")
    if RoleInfoMainSystem.Show(RoleInfoMainSystem.RoleInfoCard, RoleInfoMainSystem.RoleInfoOpenFromType.Null, DataMgr.roleData.uid) then
      local parent = self:GetLoopScrollBoxParentUI()
      if parent then
        parent:CloseSelf()
      end
    end
  elseif self.data.bitMask == logic_friendlist_custom_utils.SWITCH_MASK.NationFlag then
    local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
    local PersonalizationConst = require("client.slua.umg.roleInfoNew.PersonalizationConst")
    if RoleInfoMainSystem.Show(RoleInfoMainSystem.Personalize, RoleInfoMainSystem.RoleInfoOpenFromType.Null, DataMgr.roleData.uid, {
      personalInfo = {
        openTab = PersonalizationConst.ENUM_Type.CountryPage
      }
    }) then
      local parent = self:GetLoopScrollBoxParentUI()
      if parent then
        parent:CloseSelf()
      end
    end
  end
end
function SetDisplay_Item_UIBP:OnRefresh(data, selectIndex)
  if not data then
    return
  end
  self.data = data
  local isDisabled = data.isDisabled == true
  if data.itemName ~= 43275 then
    if self.UIRoot.Icon_Others and data.iconPath then
      self:SetTexture(self.UIRoot.Icon_Others, data.iconPath)
    end
  else
    local UIUtil = require("client.common.ui_util")
    UIUtil.UpdateNationImage(self.UIRoot.Icon_Others, data.iconPath)
  end
  if self.UIRoot.TextBlock_Content and data.itemName then
    self.UIRoot.TextBlock_Content:SetText(LocUtil.GetLocalizeResStr(data.itemName))
  end
  if self.UIRoot.CheckBox_Set then
    if isDisabled then
      self.UIRoot.CheckBox_Set:SetCheckedState(UEnums.ECheckBoxState.Unchecked)
      data.IsOpen = 0
    elseif data.IsOpen and data.IsOpen == 1 then
      self.UIRoot.CheckBox_Set:SetCheckedState(UEnums.ECheckBoxState.Checked)
    else
      self.UIRoot.CheckBox_Set:SetCheckedState(UEnums.ECheckBoxState.Unchecked)
    end
  end
  if self.UIRoot.Button_Setting then
    local shouldShow = data.hasSettingPage or false
    self:SetWidgetVisible(self.UIRoot.Button_Setting, shouldShow, shouldShow)
  end
  log(bWriteLog and string.format("SetDisplay_Item_UIBP:OnRefresh itemName=%s, IsOpen=%s, isDisabled=%s, hasSettingPage=%s", data.itemName or "nil", tostring(data.IsOpen), tostring(isDisabled), tostring(data.hasSettingPage)))
end
local class = require("class")
local scroll_box_child_base = require("client.slua_ui_framework.component.scroll_box_child_base")
return class(scroll_box_child_base, nil, SetDisplay_Item_UIBP)
