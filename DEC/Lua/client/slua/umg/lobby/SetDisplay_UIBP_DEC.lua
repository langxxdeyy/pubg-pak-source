local SetDisplay_UIBP = {}
local logic_friendlist_custom_utils = require("client.slua.logic.friend.logic_friendlist_custom_utils")
local PublishRegionMacros = require("client.slua.config.ClientMacros.PublishRegionMacros")
local SWITCHS_LIMIT = 2
function SetDisplay_UIBP:ctor()
  self.currentSwitchValue = nil
  self.tipsUI = nil
end
function SetDisplay_UIBP:OnInitialize()
  self.LoopScrollGrid_Others = self:InitChildClassScrollBox(self.UIRoot.LoopScrollGrid_Others, "client.slua.umg.lobby.Item.SetDisplay_Item_UIBP")
  self.Common_Popup_Medium_UIBP = self:InitCommonPopup(self.UIRoot.Common_Popup_Medium_UIBP)
  local extra = {}
  self.Common_Popup_Medium_UIBP:SetData(self, LocUtil.GetLocalizeResStr(87388), extra)
  local extradata = {
    helpInfo = {
      showFunc = function()
        if self.tipsUI then
          if self.tipsUI:IsShow() then
            self:CloseTips()
          else
            self.tipsUI = self:CreateChildWindow(self.UIRoot.Common_Popup_Medium_UIBP.CanvasPanel_TipsOnRight, UIManager.UI_Config.Common_Tips_Right_UIBP, LocUtil.GetLocalizeResStr(87389))
          end
        else
          self.tipsUI = self:CreateChildWindow(self.UIRoot.Common_Popup_Medium_UIBP.CanvasPanel_TipsOnRight, UIManager.UI_Config.Common_Tips_Right_UIBP, LocUtil.GetLocalizeResStr(87389))
        end
        self:AddTimerOnce(3, function()
          self:CloseTips()
        end)
      end
    }
  }
  self.Common_Popup_Medium_UIBP:SetHelpInfo(extradata.helpInfo)
  if self.UIRoot.FriendsListItem_BP then
    self.FriendsListItem_BP = self.UIRoot.FriendsListItem_BP
  end
  local CollectHandler = require("client.network.Protocol.CollectHandler")
  CollectHandler.send_get_collect_sys_privacy_req()
  local LogicPeakGameUtil = require("client.logic.PeakGame.LogicPeakGameUtil")
  self.PeakGame_RankIntegralLevel_Style_Small_UIBP = LogicPeakGameUtil.InitSmallPeakRankIntegralWidget(self, self.FriendsListItem_BP.PeakGame_RankIntegralLevel_Style_Small_UIBP)
end
function SetDisplay_UIBP:RegistEvents()
  self:AddOnClickedEventByControl(self.UIRoot.Button_OK, self.OnClickButton_OK, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Cancel, self.OnClickButton_Cancel, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Close, self.OnClickButton_Close, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_ColLvSettingOn, self.OnClickJumpToSetting, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_ColLvSettingOff, self.OnClickJumpToSetting, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_AliasSetting, self.OnClickJumpToTitle, self)
  self:AddCommonEvent(EVENTTYPE_LOBBY, EVENT_FRIENDLIST_ITEM_CUMSTOM, self.OnChangeSetDisplay, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_CollectionLvOn, self.OnClickCollectLevelSwitch, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_CollectionLvOff, self.OnClickCollectLevelSwitch, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_AliasSettingOn, self.OnClickAliasSwitch, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_AliasSettingOff, self.OnClickAliasSwitch, self)
end
function SetDisplay_UIBP:OnPostInitialize()
  self:UpdateUI()
end
function SetDisplay_UIBP:OnClose()
  if self.CollectBadgeUI then
    self.CollectBadgeUI = nil
  end
  if self.LightBoardUI then
    self.LightBoardUI = nil
  end
  if self.ReturnPlayerUI then
    self.ReturnPlayerUI = nil
  end
  self:CloseTips()
  self.currentSwitchValue = nil
end
function SetDisplay_UIBP:CloseTips()
  log(bWriteLog and "SetDisplay_UIBP:CloseTips")
  if self.tipsUI then
    self.tipsUI:CloseSelf()
    self.tipsUI = nil
  end
end
function SetDisplay_UIBP:OnClickButton_Close()
  self:PlayAudio(sound_config.click_v1)
  self:CloseSelf()
end
function SetDisplay_UIBP:OnClickButton_Cancel()
  self:PlayAudio(sound_config.click_v1)
  self:CloseSelf()
end
function SetDisplay_UIBP:OnClickButton_OK()
  self:PlayAudio(sound_config.click_v1)
  if not self.currentSwitchValue then
    log(bWriteLog and "SetDisplay_UIBP:OnClickButton_OK currentSwitchValue is nil")
    return
  end
  local logic_friendlistitem_custom = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_friendlistitem_custom)
  log(bWriteLog and string.format("SetDisplay_UIBP:OnClickButton_OK sending switchValue=%d (0x%X) to server", self.currentSwitchValue, self.currentSwitchValue))
  logic_friendlistitem_custom:send_set_friend_list_show_switchs_req(self.currentSwitchValue)
  self:CloseSelf()
end
function SetDisplay_UIBP:OnClickJumpToSetting()
  self:PlayAudio(sound_config.click_v1)
  local setting_util = require("client.slua.logic.setting.setting_util")
  setting_util.Enter("PrivacyAndSocial", "Privacy", "DoubleShowCollectLevel")
  self:CloseSelf()
end
function SetDisplay_UIBP:OnClickJumpToTitle()
  self:PlayAudio(sound_config.click_v1)
  log(bWriteLog and "SetDisplay_UIBP:OnClickJumpToTitle")
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  local PersonalizationConst = require("client.slua.umg.roleInfoNew.PersonalizationConst")
  if RoleInfoMainSystem.Show(RoleInfoMainSystem.Personalize, RoleInfoMainSystem.RoleInfoOpenFromType.Null, DataMgr.roleData.uid, {
    personalInfo = {
      openTab = PersonalizationConst.ENUM_Type.Alias
    }
  }) then
    self:CloseSelf()
  end
end
function SetDisplay_UIBP:EnsureSwitchValueLoaded()
  if self.currentSwitchValue == nil then
    local myUid = DataMgr.roleData.uid
    local logic_friendlistitem_custom = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_friendlistitem_custom)
    self.currentSwitchValue = logic_friendlistitem_custom:GetFriendListShowSwitchs(myUid, true)
    log(bWriteLog and string.format("SetDisplay_UIBP:EnsureSwitchValueLoaded loaded=%d (0x%X)", self.currentSwitchValue, self.currentSwitchValue))
  end
end
function SetDisplay_UIBP:OnClickCollectLevelSwitch()
  log(bWriteLog and "SetDisplay_UIBP:OnClickCollectLevelSwitch")
  self:PlayAudio(sound_config.click_v1)
  local collect_privacy_module = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.collect_privacy_module)
  if not collect_privacy_module:CanShowMyCollectLevel() then
    log(bWriteLog and "SetDisplay_UIBP:OnClickCollectLevelSwitch privacy switch is OFF, showing toast")
    ShowNotice(87360)
    return
  end
  self:EnsureSwitchValueLoaded()
  local SWITCH_MASK = logic_friendlist_custom_utils.SWITCH_MASK
  local isCurrentOn = logic_friendlist_custom_utils.GetSwitch(self.currentSwitchValue, SWITCH_MASK.CollectLevel)
  log(bWriteLog and string.format("SetDisplay_UIBP:OnClickCollectLevelSwitch current state=%s", tostring(isCurrentOn)))
  local newIsOn = not isCurrentOn
  self.currentSwitchValue = logic_friendlist_custom_utils.SetSwitch(self.currentSwitchValue, SWITCH_MASK.CollectLevel, newIsOn)
  log(bWriteLog and string.format("SetDisplay_UIBP:OnClickCollectLevelSwitch new state=%s, newSwitchValue=%d (0x%X)", tostring(newIsOn), self.currentSwitchValue, self.currentSwitchValue))
  self.UIRoot.WidgetSwitcher_CollectionLv:SetActiveWidgetIndex(newIsOn and 0 or 1)
  self:OnChangeSetDisplay(_, _, SWITCH_MASK.CollectLevel)
end
function SetDisplay_UIBP:OnClickAliasSwitch()
  log(bWriteLog and "SetDisplay_UIBP:OnClickTitleSwitch")
  self:PlayAudio(sound_config.click_v1)
  self:EnsureSwitchValueLoaded()
  local SWITCH_MASK = logic_friendlist_custom_utils.SWITCH_MASK
  local isCurrentOn = logic_friendlist_custom_utils.GetSwitch(self.currentSwitchValue, SWITCH_MASK.Alias)
  log(bWriteLog and string.format("SetDisplay_UIBP:OnClickTitleSwitch current state=%s", tostring(isCurrentOn)))
  local newIsOn = not isCurrentOn
  self.currentSwitchValue = logic_friendlist_custom_utils.SetSwitch(self.currentSwitchValue, SWITCH_MASK.Alias, newIsOn)
  log(bWriteLog and string.format("SetDisplay_UIBP:OnClickTitleSwitch new state=%s, newSwitchValue=%d (0x%X)", tostring(newIsOn), self.currentSwitchValue, self.currentSwitchValue))
  self.UIRoot.WidgetSwitcher_AliasSetting:SetActiveWidgetIndex(newIsOn and 0 or 1)
  self:OnChangeSetDisplay(_, _, SWITCH_MASK.Alias)
end
function SetDisplay_UIBP:OnChangeSetDisplay(_, _, bitMask)
  log(bWriteLog and "SetDisplay_UIBP:OnLobbySetDisplay")
  local myUid = DataMgr.roleData.uid
  local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
  local profile = logic_profile:GetLocalProfile(tonumber(myUid))
  if not profile then
    log(bWriteLog and "SetDisplay_UIBP:RefreshDisplayItems profile is nil")
    return
  end
  local switchValue = self.currentSwitchValue
  local itemRoot = self.FriendsListItem_BP
  if bitMask == logic_friendlist_custom_utils.SWITCH_MASK.Alias then
    self:RefreshAlias(itemRoot, profile, switchValue)
  elseif bitMask == logic_friendlist_custom_utils.SWITCH_MASK.CollectLevel then
    self:RefreshCollectLevel(itemRoot, profile, switchValue)
  elseif bitMask == logic_friendlist_custom_utils.SWITCH_MASK.Gender then
    self:RefreshGenderOrPass(itemRoot, profile, switchValue)
  elseif bitMask == logic_friendlist_custom_utils.SWITCH_MASK.Pass then
    self:RefreshGenderOrPass(itemRoot, profile, switchValue)
  elseif bitMask == logic_friendlist_custom_utils.SWITCH_MASK.WowPass then
    self:RefreshWowPass(itemRoot, profile, switchValue)
  elseif bitMask == logic_friendlist_custom_utils.SWITCH_MASK.Certification then
    self:RefreshCertification(itemRoot, profile, switchValue)
  elseif bitMask == logic_friendlist_custom_utils.SWITCH_MASK.NationFlag then
    self:RefreshNationFlag(itemRoot, profile, switchValue)
  end
  self:RefreshItemStates()
end
function SetDisplay_UIBP:UpdateUI()
  log(bWriteLog and "SetDisplay_UIBP:UpdateUI")
  self.UIRoot.Text_Introduce:SetText(LocUtil.GetLocalizeResStr(87390))
  self.UIRoot.Text_CollectionLv:SetText(LocUtil.GetLocalizeResStr(87392))
  self.UIRoot.TextBlock_Alias:SetText(LocUtil.GetLocalizeResStr(87393))
  self:RefreshCollectLevelTextColor()
  self:RefreshSelfDisplay()
  if PublishRegionMacros.IsBlueholeFamily() then
    self:EnsureSwitchValueLoaded()
    local logic_friendlist_custom_utils = require("client.slua.logic.friend.logic_friendlist_custom_utils")
    local isNationFlagOn = logic_friendlist_custom_utils.GetSwitch(self.currentSwitchValue, logic_friendlist_custom_utils.SWITCH_MASK.NationFlag)
    if isNationFlagOn then
      self.currentSwitchValue = logic_friendlist_custom_utils.SetSwitch(self.currentSwitchValue, logic_friendlist_custom_utils.SWITCH_MASK.NationFlag, false)
      log(bWriteLog and "SetDisplay_UIBP:UpdateUI Bluehole version force off NationFlag switch")
    end
  end
  self:RefreshDisplayItems()
  self:RefreshItemCountText()
end
function SetDisplay_UIBP:RefreshCollectLevelTextColor()
  if not self.UIRoot.TextBlock_CollectOff then
    return
  end
  local collect_privacy_module = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.collect_privacy_module)
  local privacySwitch = collect_privacy_module:CanShowMyCollectLevel()
  if privacySwitch then
    self.UIRoot.TextBlock_CollectOff:SetColorAndOpacity(FSlateColor(FLinearColor(0, 0, 0, 0.698039)))
    log(bWriteLog and "SetDisplay_UIBP: CollectLevel text color - normal black (privacy ON)")
  else
    self.UIRoot.TextBlock_CollectOff:SetColorAndOpacity(FSlateColor(FLinearColor(0, 0, 0, 0.5)))
    log(bWriteLog and "SetDisplay_UIBP: CollectLevel text color - gray (privacy OFF)")
  end
end
function SetDisplay_UIBP:RefreshItemCountText()
  if not self.UIRoot.TextBlock_Others then
    return
  end
  local itemEnabledCount = 0
  if self.currentSwitchValue then
    itemEnabledCount = logic_friendlist_custom_utils.GetEnabledItemSwitchCount(self.currentSwitchValue)
  end
  local formattedText = LocUtil.LocalizeResFormat(87391, itemEnabledCount, SWITCHS_LIMIT)
  self.UIRoot.TextBlock_Others:SetText(formattedText)
  log(bWriteLog and string.format("SetDisplay_UIBP:RefreshItemCountText count=%d/%d", itemEnabledCount, SWITCHS_LIMIT))
end
function SetDisplay_UIBP:RefreshItemStates()
  log(bWriteLog and "SetDisplay_UIBP:RefreshItemStates")
  if not self.LoopScrollGrid_Others then
    log(bWriteLog and "SetDisplay_UIBP:RefreshItemStates LoopScrollGrid_Others is nil")
    return
  end
  local currentItems = self.LoopScrollGrid_Others:GetSetData()
  if not currentItems or #currentItems == 0 then
    log(bWriteLog and "SetDisplay_UIBP:RefreshItemStates no items to refresh")
    return
  end
  if not self.currentSwitchValue then
    log(bWriteLog and "SetDisplay_UIBP:RefreshItemStates currentSwitchValue is nil")
    return
  end
  local SWITCH_MASK = logic_friendlist_custom_utils.SWITCH_MASK
  local enabledCount = 0
  for i = 1, #currentItems do
    local item = currentItems[i]
    local isOn = logic_friendlist_custom_utils.GetSwitch(self.currentSwitchValue, item.bitMask)
    item.IsOpen = isOn and 1 or 0
    if isOn then
      enabledCount = enabledCount + 1
    end
  end
  log(bWriteLog and string.format("SetDisplay_UIBP:RefreshItemStates enabled count = %d / 2", enabledCount))
  for i = 1, #currentItems do
    local item = currentItems[i]
    if item.IsOpen == 1 then
      item.isDisabled = false
    else
      item.isDisabled = 2 <= enabledCount
    end
    log(bWriteLog and string.format("SetDisplay_UIBP:RefreshItemStates item=%s, IsOpen=%d, isDisabled=%s", tostring(item.itemName), item.IsOpen, tostring(item.isDisabled)))
  end
  self.LoopScrollGrid_Others:SetData(currentItems)
  self:RefreshItemCountText()
  log(bWriteLog and string.format("SetDisplay_UIBP:RefreshItemStates completed, total=%d, enabled=%d", #currentItems, enabledCount))
end
function SetDisplay_UIBP:RefreshDisplayItems()
  local myUid = DataMgr.roleData.uid
  local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
  local profile = logic_profile:GetLocalProfile(tonumber(myUid))
  if not profile then
    log(bWriteLog and "SetDisplay_UIBP:RefreshDisplayItems profile is nil")
    return
  end
  local displayItems = logic_friendlist_custom_utils.displayItems
  local SWITCH_MASK = logic_friendlist_custom_utils.SWITCH_MASK
  if not self.currentSwitchValue then
    local logic_friendlistitem_custom = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_friendlistitem_custom)
    self.currentSwitchValue = logic_friendlistitem_custom:GetFriendListShowSwitchs(myUid, true)
  end
  log(bWriteLog and string.format("SetDisplay_UIBP:RefreshDisplayItems switchValue=%d (0x%X)", self.currentSwitchValue, self.currentSwitchValue))
  local ownedItems = {}
  for i, item in ipairs(displayItems) do
    if item.bitMask == SWITCH_MASK.Pass then
      local LogicFriend = require("client.slua.logic.friend.logic_new_friend")
      local UPassIsBuy, UPassIsShow, UPassKeepBuy, UPassValue, pass_type = LogicFriend.ParsePassInfo(profile.upass)
      if UPassIsBuy and pass_type and 0 < pass_type then
        item.iconPath = "/Game/UMG/Texture/Lobby_NoAtlas/Common/UnknowPass/RPA_Record_Icon_LV_Better.RPA_Record_Icon_LV_Better"
        log(bWriteLog and string.format("SetDisplay_UIBP: Pass Elite icon, level=%d, type=%d", UPassValue or 0, pass_type))
      else
        item.iconPath = "/Game/UMG/Texture/Lobby_NoAtlas/Common/UnknowPass/RPA_Record_Icon_LV_None.RPA_Record_Icon_LV_None"
        log(bWriteLog and string.format("SetDisplay_UIBP: Pass basic icon, level=%d, type=%d, isBuy=%s", UPassValue or 0, pass_type or 0, tostring(UPassIsBuy)))
      end
      item.priority = 4
      table.insert(ownedItems, item)
    elseif item.bitMask == SWITCH_MASK.WowPass then
      local Util_UGC = require("client.slua.logic.ugc.util_ugc")
      local hasWowPass = Util_UGC.WoWPassActive(profile)
      local isWowPassOn = logic_friendlist_custom_utils.GetSwitch(self.currentSwitchValue, SWITCH_MASK.WowPass)
      if hasWowPass or isWowPassOn then
        if hasWowPass then
          local iconPath = Util_UGC.GetWoWPassIconPath(profile)
          if iconPath and iconPath ~= "" then
            item.iconPath = iconPath
          end
          log(bWriteLog and "SetDisplay_UIBP: WowPass owned")
        else
          log(bWriteLog and "SetDisplay_UIBP: WowPass expired but switch is ON")
        end
        item.priority = 5
        table.insert(ownedItems, item)
      else
        log(bWriteLog and "SetDisplay_UIBP: WowPass not owned and switch is OFF, hide")
      end
    elseif item.bitMask == SWITCH_MASK.Gender then
      local hasGender = profile.social_card and profile.social_card.new_sex and 0 < profile.social_card.new_sex
      local isGenderOn = logic_friendlist_custom_utils.GetSwitch(self.currentSwitchValue, SWITCH_MASK.Gender)
      if hasGender or isGenderOn then
        if hasGender then
          if profile.social_card.new_sex == 1 then
            item.iconPath = "/Game/UMG/Texture_200/Atlas/Common_New_Atlas/Frames/Common_Icon_Boy_png.Common_Icon_Boy_png"
          elseif profile.social_card.new_sex == 2 then
            item.iconPath = "/Game/UMG/Texture_200/Atlas/Common_New_Atlas/Frames/Common_Icon_Girl_png.Common_Icon_Girl_png"
          end
          log(bWriteLog and "SetDisplay_UIBP: Gender icon updated")
        else
          log(bWriteLog and "SetDisplay_UIBP: Gender not set but switch is ON")
        end
        item.priority = 1
        table.insert(ownedItems, item)
      else
        log(bWriteLog and "SetDisplay_UIBP: Gender not set and switch is OFF, hide")
      end
    elseif item.bitMask == SWITCH_MASK.NationFlag then
      local hasNation = profile.nation and profile.nation ~= ""
      local isNationFlagOn = logic_friendlist_custom_utils.GetSwitch(self.currentSwitchValue, SWITCH_MASK.NationFlag)
      if (hasNation or isNationFlagOn) and not PublishRegionMacros.IsBlueholeFamily() then
        if hasNation then
          item.iconPath = profile.nation
          log(bWriteLog and string.format("SetDisplay_UIBP: Nation icon updated, nation=%s", profile.nation))
        else
          log(bWriteLog and "SetDisplay_UIBP: Nation not set but switch is ON")
        end
        item.priority = 2
        table.insert(ownedItems, item)
      else
        log(bWriteLog and "SetDisplay_UIBP: Nation not set and switch is OFF, hide")
      end
    elseif item.bitMask == SWITCH_MASK.Certification then
      local logic_teammate_info = require("client.slua.umg.MainCity.Lobby_Friend.logic_teammate_info")
      local hasAuth = logic_teammate_info.CheckAuthInfoOpen(profile.auth_type, profile.auth_end_time)
      local isCertificationOn = logic_friendlist_custom_utils.GetSwitch(self.currentSwitchValue, SWITCH_MASK.Certification)
      if hasAuth or isCertificationOn then
        if hasAuth then
          log(bWriteLog and string.format("SetDisplay_UIBP: Certification active, auth_type=%s", tostring(profile.auth_type)))
        else
          log(bWriteLog and "SetDisplay_UIBP: Certification expired but switch is ON")
        end
        item.priority = 3
        table.insert(ownedItems, item)
      else
        log(bWriteLog and "SetDisplay_UIBP: Certification not owned and switch is OFF, hide")
      end
    end
  end
  table.sort(ownedItems, function(a, b)
    return a.priority < b.priority
  end)
  local enabledCount = 0
  for i = 1, #ownedItems do
    local item = ownedItems[i]
    local isOn = logic_friendlist_custom_utils.GetSwitch(self.currentSwitchValue, item.bitMask)
    item.IsOpen = isOn and 1 or 0
    if isOn then
      enabledCount = enabledCount + 1
    end
  end
  log(bWriteLog and string.format("SetDisplay_UIBP: Current enabled count = %d / 2", enabledCount))
  local finalDisplayItems = {}
  for i = 1, #ownedItems do
    local item = ownedItems[i]
    if item.IsOpen == 1 then
      item.isDisabled = false
      log(bWriteLog and string.format("SetDisplay_UIBP: Item %d enabled and toggleable, itemName=%s", i, item.itemName))
    elseif enabledCount < 2 then
      item.isDisabled = false
      log(bWriteLog and string.format("SetDisplay_UIBP: Item %d not enabled but can be toggled, itemName=%s", i, item.itemName))
    else
      item.isDisabled = true
      log(bWriteLog and string.format("SetDisplay_UIBP: Item %d disabled (limit reached), itemName=%s", i, item.itemName))
    end
    table.insert(finalDisplayItems, item)
  end
  if self.LoopScrollGrid_Others then
    self.LoopScrollGrid_Others:SetData(finalDisplayItems)
  end
  log(bWriteLog and string.format("SetDisplay_UIBP:RefreshDisplayItems totalConfig=%d, owned=%d, finalDisplay=%d, enabled=%d", #displayItems, #ownedItems, #finalDisplayItems, enabledCount))
end
function SetDisplay_UIBP:RefreshSelfDisplay()
  if not self.FriendsListItem_BP then
    log(bWriteLog and "SetDisplay_UIBP:RefreshSelfDisplay FriendsListItem_BP is nil")
    return
  end
  self:SetWidgetVisible(self.FriendsListItem_BP.CheckBox_Delete, false)
  self:SetWidgetVisible(self.FriendsListItem_BP.Image_Line, false)
  self:SetWidgetVisible(self.FriendsListItem_BP.CanvasPanel_Relationship, false)
  local myUid = DataMgr.roleData.uid
  if not myUid then
    return
  end
  local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
  local profile = logic_profile:GetLocalProfile(tonumber(myUid))
  if not profile then
    log(bWriteLog and "SetDisplay_UIBP:RefreshSelfDisplay profile is nil")
    return
  end
  local PlayerStatusMgr = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.PlayerStatusMgr)
  local status = PlayerStatusMgr:GetStatusData(myUid)
  local itemRoot = self.FriendsListItem_BP
  if itemRoot.Text_Name then
    self:SetWidgetVisible(itemRoot.Button_Birthday, true, false)
    itemRoot.Text_Name:SetText(profile.nickName or "")
    itemRoot.Text_Name:SetColorAndOpacity(FSlateColor(FLinearColor(0, 0, 0, 1)))
  end
  if itemRoot.Common_RankIntegralLevel_Style_Small_UIBP then
    self:SetWidgetVisible(itemRoot.Common_RankIntegralLevel_Style_Small_UIBP, true)
    local segment_show_type = profile.segment_show_type
    local PeakGameConfig = require("client.logic.PeakGame.PeakGameConfig")
    local rankBlackColor = FSlateColor(FLinearColor(0, 0, 0, 1))
    if segment_show_type == PeakGameConfig.EnumSegmentShowType.PeakGame then
      if itemRoot.WidgetSwitcher_Segment then
        itemRoot.WidgetSwitcher_Segment:SetActiveWidgetIndex(1)
      end
      if itemRoot.PeakGame_RankIntegralLevel_Style_Small_UIBP then
        local LogicPeakGameSegmentUtil = require("client.logic.PeakGame.LogicPeakGameSegmentUtil")
        local segment = LogicPeakGameSegmentUtil.GetSelfAllZoneCurSeasonMaxSegmentId()
        if self.PeakGame_RankIntegralLevel_Style_Small_UIBP then
          self.PeakGame_RankIntegralLevel_Style_Small_UIBP:SetPeakRankIntegral(segment or PeakGameConfig.DefaultPeakGameSegment)
          self.PeakGame_RankIntegralLevel_Style_Small_UIBP:ChangeRankInteralColor(rankBlackColor)
        end
      end
    else
      if itemRoot.WidgetSwitcher_Segment then
        itemRoot.WidgetSwitcher_Segment:SetActiveWidgetIndex(0)
      end
      local logic_segment_title = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_segment_title)
      local segment, zoneId, modeId = logic_segment_title:GetMaxSegementLevelWithZoneAndModeId(profile.segment_info)
      local segmentTitleId = logic_segment_title:GetSegmentTitleId(profile.hsegment_title_det, zoneId, modeId)
      if not zoneId or not modeId then
        itemRoot.Common_RankIntegralLevel_Style_Small_UIBP:SetRankInteral(segment or 101, nil)
      else
        itemRoot.Common_RankIntegralLevel_Style_Small_UIBP:SetRankInteralWithSegmentTitle(segment, nil, nil, segmentTitleId)
      end
      itemRoot.Common_RankIntegralLevel_Style_Small_UIBP:ChangeRankInteralColor(rankBlackColor)
    end
  end
  self:RefreshPlayerStatus(itemRoot, myUid, profile, status)
  local switchValue = self.currentSwitchValue
  if not switchValue then
    local logic_friendlistitem_custom = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_friendlistitem_custom)
    switchValue = logic_friendlistitem_custom:GetFriendListShowSwitchs(myUid, true)
  end
  log(bWriteLog and string.format("SetDisplay_UIBP:RefreshSelfDisplay switchValue=%s (0x%X)", tostring(switchValue), switchValue or 0))
  if itemRoot.Common_Avatar_BP then
    local isOnline = status and status.online == 1
    itemRoot.Common_Avatar_BP:InitView(1, myUid, profile.picUrl, 0, profile.cur_avatar_box_id, 0, false, "", isOnline)
    itemRoot.Common_Avatar_BP:SetButtonEnabled(false)
  end
  self:RefreshCollectLevel(itemRoot, profile, switchValue)
  self:RefreshAlias(itemRoot, profile, switchValue)
  self:RefreshNationFlag(itemRoot, profile, switchValue)
  self:RefreshGenderOrPass(itemRoot, profile, switchValue)
  self:RefreshCertification(itemRoot, profile, switchValue)
  self:RefreshWowPass(itemRoot, profile, switchValue)
  self:RefreshNicknameFrame(itemRoot, profile)
  self:RefreshReturnPlayer(itemRoot, profile)
  log(bWriteLog and "SetDisplay_UIBP:RefreshSelfDisplay finished")
end
function SetDisplay_UIBP:RefreshCollectLevel(itemRoot, profile, switchValue)
  local logic_friendlist_custom_utils = require("client.slua.logic.friend.logic_friendlist_custom_utils")
  local SWITCH_MASK = logic_friendlist_custom_utils.SWITCH_MASK
  local collect_privacy_module = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.collect_privacy_module)
  local privacySwitch = collect_privacy_module:CanShowMyCollectLevel()
  if privacySwitch then
    local isCollectLevelOn = logic_friendlist_custom_utils.GetSwitch(switchValue, SWITCH_MASK.CollectLevel)
    local hasCollectData = profile.collect_data and next(profile.collect_data)
    if hasCollectData then
      if itemRoot.SizeBox_CollectLevelItem then
        self:SetWidgetVisible(itemRoot.SizeBox_CollectLevelItem, isCollectLevelOn)
        if not self.CollectBadgeUI then
          local bpPath = "/Game/UMG/UI_Logic/Common/CommonItem/Common_Collect_Level_DynamicLoading_UIBP.Common_Collect_Level_DynamicLoading_UIBP"
          self.CollectBadgeUI = self:CreateChildWindowWithBpPath(itemRoot.SizeBox_CollectLevelItem, nil, bpPath)
          if self.CollectBadgeUI then
            self.CollectBadgeUI:SetAutoSize(true)
          end
        end
        if self.CollectBadgeUI and self.CollectBadgeUI.UIRoot and self.CollectBadgeUI.UIRoot.InitCollectBadge then
          self.CollectBadgeUI.UIRoot:InitCollectBadge(DataMgr.roleData.uid, profile.collect_data, false)
        end
      end
      if self.UIRoot.WidgetSwitcher_CollectionLv then
        self.UIRoot.WidgetSwitcher_CollectionLv:SetActiveWidgetIndex(isCollectLevelOn and 0 or 1)
        log(bWriteLog and string.format("SetDisplay_UIBP: CollectLevel switch %s", isCollectLevelOn and "ON" or "OFF"))
      end
    else
      if itemRoot.SizeBox_CollectLevelItem then
        self:SetWidgetVisible(itemRoot.SizeBox_CollectLevelItem, false)
      end
      if self.UIRoot.WidgetSwitcher_CollectionLv then
        self.UIRoot.WidgetSwitcher_CollectionLv:SetActiveWidgetIndex(1)
      end
      log(bWriteLog and "SetDisplay_UIBP: No collect data available")
    end
  else
    if self.UIRoot.WidgetSwitcher_CollectionLv then
      self.UIRoot.WidgetSwitcher_CollectionLv:SetActiveWidgetIndex(1)
      log(bWriteLog and "SetDisplay_UIBP: CollectLevel privacy OFF, force hide")
    end
    log(bWriteLog and "SetDisplay_UIBP: Privacy switch is OFF")
  end
end
function SetDisplay_UIBP:RefreshAlias(itemRoot, profile, switchValue)
  local logic_friendlist_custom_utils = require("client.slua.logic.friend.logic_friendlist_custom_utils")
  local SWITCH_MASK = logic_friendlist_custom_utils.SWITCH_MASK
  local isAliasOn = logic_friendlist_custom_utils.GetSwitch(switchValue, SWITCH_MASK.Alias)
  local hasAnyAlias = false
  local logic_roleinfo_title = require("client.slua.logic.roleInfo.logic_roleinfo_title")
  local aliasListData = logic_roleinfo_title.GetAliasListData()
  if aliasListData and next(aliasListData) then
    for aliasId, aliasData in pairs(aliasListData) do
      if aliasData.state and (aliasData.state == 1 or aliasData.state == 2) then
        hasAnyAlias = true
        break
      end
    end
  end
  if profile.alias and profile.alias.id and profile.alias.id > 0 then
    if itemRoot.Title_UIBP then
      itemRoot.Title_UIBP:SetAliasInfo(profile.alias.id, profile.alias.title or "", profile.alias.nation or "", 0, profile.alias.rank_id or 0)
    end
    if self.UIRoot.WidgetSwitcher_AliasSetting then
      self.UIRoot.WidgetSwitcher_AliasSetting:SetActiveWidgetIndex(isAliasOn and 0 or 1)
      log(bWriteLog and string.format("SetDisplay_UIBP: Alias switch %s (equipped branch)", isAliasOn and "ON" or "OFF"))
    end
    if itemRoot.title_box then
      if isAliasOn then
        itemRoot.title_box:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
      else
        itemRoot.title_box:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
      end
    end
    log(bWriteLog and string.format("SetDisplay_UIBP: Has alias and equipped, id=%s", profile.alias.id))
  elseif hasAnyAlias then
    if self.UIRoot.WidgetSwitcher_AliasSetting then
      self.UIRoot.WidgetSwitcher_AliasSetting:SetActiveWidgetIndex(isAliasOn and 0 or 1)
      log(bWriteLog and string.format("SetDisplay_UIBP: Alias switch %s (has but not equipped branch)", isAliasOn and "ON" or "OFF"))
    end
    if itemRoot.title_box then
      itemRoot.title_box:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
    end
    log(bWriteLog and "SetDisplay_UIBP: Has alias but not equipped")
  else
    if self.UIRoot.WidgetSwitcher_AliasSetting then
      self.UIRoot.WidgetSwitcher_AliasSetting:SetActiveWidgetIndex(2)
      log(bWriteLog and string.format("SetDisplay_UIBP: Alias switch %s (no alias branch)", isAliasOn and "ON" or "OFF"))
    end
    if itemRoot.title_box then
      itemRoot.title_box:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
    end
    log(bWriteLog and "SetDisplay_UIBP: No alias at all")
  end
end
function SetDisplay_UIBP:RefreshNationFlag(itemRoot, profile, switchValue)
  local logic_friendlist_custom_utils = require("client.slua.logic.friend.logic_friendlist_custom_utils")
  local SWITCH_MASK = logic_friendlist_custom_utils.SWITCH_MASK
  local isNationFlagOn = logic_friendlist_custom_utils.GetSwitch(switchValue, SWITCH_MASK.NationFlag)
  if itemRoot.Image_flag then
    if profile.nation and isNationFlagOn and not PublishRegionMacros.IsBlueholeFamily() then
      local UIUtil = require("client.common.ui_util")
      UIUtil.UpdateNationImage(itemRoot.Image_flag, profile.nation)
      self:SetWidgetVisible(itemRoot.Image_flag, true)
      log(bWriteLog and "SetDisplay_UIBP: NationFlag switch ON, showing flag")
    else
      self:SetWidgetVisible(itemRoot.Image_flag, false)
      log(bWriteLog and string.format("SetDisplay_UIBP: NationFlag switch OFF or no nation data, hiding flag (isOn=%s, hasNation=%s)", tostring(isNationFlagOn), tostring(profile.nation ~= nil)))
    end
  end
end
function SetDisplay_UIBP:RefreshGenderOrPass(itemRoot, profile, switchValue)
  local logic_friendlist_custom_utils = require("client.slua.logic.friend.logic_friendlist_custom_utils")
  local SWITCH_MASK = logic_friendlist_custom_utils.SWITCH_MASK
  local hasGender = profile.social_card and profile.social_card.new_sex and profile.social_card.new_sex > 0
  local isGenderOn = logic_friendlist_custom_utils.GetSwitch(switchValue, SWITCH_MASK.Gender)
  if itemRoot.SizeBox_Gender then
    if hasGender and isGenderOn then
      self:SetWidgetVisible(itemRoot.SizeBox_Gender, true)
      if itemRoot.Common_Gender_UIBP then
        itemRoot.Common_Gender_UIBP:LoadIcon(DataMgr.roleData.uid)
      end
      log(bWriteLog and "SetDisplay_UIBP: Gender switch ON, showing gender")
    else
      self:SetWidgetVisible(itemRoot.SizeBox_Gender, false)
      log(bWriteLog and string.format("SetDisplay_UIBP: Gender switch OFF or no data (isOn=%s, hasData=%s)", tostring(isGenderOn), tostring(hasGender)))
    end
  end
  local LogicFriend = require("client.slua.logic.friend.logic_new_friend")
  local UPassIsBuy, UPassIsShow, UPassKeepBuy, UPassValue, pass_type = LogicFriend.ParsePassInfo(profile.upass)
  local isPassOn = logic_friendlist_custom_utils.GetSwitch(switchValue, SWITCH_MASK.Pass)
  if itemRoot.SizeBox_BP then
    if isPassOn then
      self:SetWidgetVisible(itemRoot.SizeBox_BP, true)
      if itemRoot.UnknowPass_ContinuousBuy_BP and slua.isValid(itemRoot.UnknowPass_ContinuousBuy_BP) then
        itemRoot.UnknowPass_ContinuousBuy_BP:SetTypeData(0, UPassKeepBuy, UPassIsBuy, 1, UPassValue, pass_type or 0)
      end
      log(bWriteLog and "SetDisplay_UIBP: Pass switch ON, showing RP")
    else
      self:SetWidgetVisible(itemRoot.SizeBox_BP, false)
      log(bWriteLog and "SetDisplay_UIBP: Pass switch OFF, hiding RP")
    end
  end
end
function SetDisplay_UIBP:RefreshGender(itemRoot, profile, switchValue)
  local logic_friendlist_custom_utils = require("client.slua.logic.friend.logic_friendlist_custom_utils")
  local SWITCH_MASK = logic_friendlist_custom_utils.SWITCH_MASK
  local hasGender = profile.social_card and profile.social_card.new_sex and profile.social_card.new_sex > 0
  local isGenderOn = logic_friendlist_custom_utils.GetSwitch(switchValue, SWITCH_MASK.Gender)
  if itemRoot.Common_Gender_UIBP then
    if hasGender and isGenderOn then
      self:SetWidgetVisible(itemRoot.Common_Gender_UIBP, true)
      itemRoot.Common_Gender_UIBP:LoadIcon(DataMgr.roleData.uid)
      log(bWriteLog and "SetDisplay_UIBP: Gender switch ON (independent)")
    else
      self:SetWidgetVisible(itemRoot.Common_Gender_UIBP, false)
      log(bWriteLog and string.format("SetDisplay_UIBP: Gender switch OFF or no data (isOn=%s, hasData=%s)", tostring(isGenderOn), tostring(hasGender)))
    end
  end
end
function SetDisplay_UIBP:RefreshPass(itemRoot, profile, switchValue)
  local logic_friendlist_custom_utils = require("client.slua.logic.friend.logic_friendlist_custom_utils")
  local SWITCH_MASK = logic_friendlist_custom_utils.SWITCH_MASK
  local LogicFriend = require("client.slua.logic.friend.logic_new_friend")
  local UPassIsBuy, UPassIsShow, UPassKeepBuy, UPassValue, pass_type = LogicFriend.ParsePassInfo(profile.upass)
  local isPassOn = logic_friendlist_custom_utils.GetSwitch(switchValue, SWITCH_MASK.Pass)
  if itemRoot.UnknowPass_ContinuousBuy_BP then
    if UPassIsShow and isPassOn then
      self:SetWidgetVisible(itemRoot.UnknowPass_ContinuousBuy_BP, true)
      if slua.isValid(itemRoot.UnknowPass_ContinuousBuy_BP) then
        itemRoot.UnknowPass_ContinuousBuy_BP:SetTypeData(0, UPassKeepBuy, UPassIsBuy, 1, UPassValue, pass_type or 0)
      end
      log(bWriteLog and "SetDisplay_UIBP: Pass switch ON (independent)")
    else
      self:SetWidgetVisible(itemRoot.UnknowPass_ContinuousBuy_BP, false)
      log(bWriteLog and string.format("SetDisplay_UIBP: Pass switch OFF or no data (isOn=%s, hasPass=%s)", tostring(isPassOn), tostring(UPassIsShow)))
    end
  end
end
function SetDisplay_UIBP:RefreshCertification(itemRoot, profile, switchValue)
  log(bWriteLog and "SetDisplay_UIBP: RefreshCertification")
  local SWITCH_MASK = logic_friendlist_custom_utils.SWITCH_MASK
  local isCertificationOn = logic_friendlist_custom_utils.GetSwitch(switchValue, SWITCH_MASK.Certification)
  if itemRoot.CanvasPanel_Certification then
    local logic_teammate_info = require("client.slua.umg.MainCity.Lobby_Friend.logic_teammate_info")
    local hasAuth = logic_teammate_info.CheckAuthInfoOpen(profile.auth_type, profile.auth_end_time)
    if hasAuth and isCertificationOn then
      self:SetWidgetVisible(itemRoot.CanvasPanel_Certification, true)
      if not self.CertificationUI then
        local bpPath = "/Game/UMG/UI_BP/Common/Common_Certification_UIBP.Common_Certification_UIBP"
        self.CertificationUI = self:CreateChildWindowWithBpPath(itemRoot.CanvasPanel_Certification, nil, bpPath)
      end
      if self.CertificationUI and self.CertificationUI.UIRoot and self.CertificationUI.UIRoot.SetAuthInfo then
        self.CertificationUI.UIRoot:SetAuthInfo(profile.auth_type, profile.auth_end_time)
      end
      log(bWriteLog and "SetDisplay_UIBP: Certification switch ON, showing auth")
    else
      self:SetWidgetVisible(itemRoot.CanvasPanel_Certification, false)
      log(bWriteLog and string.format("SetDisplay_UIBP: Certification switch OFF or no auth data, hiding auth (isOn=%s, hasAuth=%s)", tostring(isCertificationOn), tostring(hasAuth)))
    end
  end
end
function SetDisplay_UIBP:RefreshWowPass(itemRoot, profile, switchValue)
  log(bWriteLog and "SetDisplay_UIBP: RefreshWowPass")
  local SWITCH_MASK = logic_friendlist_custom_utils.SWITCH_MASK
  local isWowPassOn = logic_friendlist_custom_utils.GetSwitch(switchValue, SWITCH_MASK.WowPass)
  if itemRoot.CanvasPanel_WowPass then
    local Util_UGC = require("client.slua.logic.ugc.util_ugc")
    local hasWowPass = Util_UGC.WoWPassActive(profile)
    if hasWowPass and isWowPassOn then
      self:SetWidgetVisible(itemRoot.CanvasPanel_WowPass, true)
      if not self.WowPassUI then
        self.WowPassUI = self:CreateChildWindow(itemRoot.CanvasPanel_WowPass, UIManager.UI_Config.FriendComp_WOWPass)
      end
      if self.WowPassUI and self.WowPassUI.SetData then
        self.WowPassUI:SetData(profile)
      end
      log(bWriteLog and "SetDisplay_UIBP: WowPass switch ON, showing WowPass")
    else
      self:SetWidgetVisible(itemRoot.CanvasPanel_WowPass, false)
      log(bWriteLog and string.format("SetDisplay_UIBP: WowPass switch OFF or no WowPass data, hiding WowPass (isOn=%s, hasWowPass=%s)", tostring(isWowPassOn), tostring(hasWowPass)))
    end
  end
end
function SetDisplay_UIBP:RefreshNicknameFrame(itemRoot, profile)
  log(bWriteLog and "SetDisplay_UIBP: RefreshNicknameFrame (LightBoard)")
  if not itemRoot or not itemRoot.ScaleBox_LightBoard then
    log(bWriteLog and "SetDisplay_UIBP: RefreshNicknameFrame ScaleBox_LightBoard not found")
    return
  end
  local hasLightBoard = profile and profile.light_board_info and next(profile.light_board_info)
  if hasLightBoard then
    self:SetWidgetVisible(itemRoot.ScaleBox_LightBoard, true)
    if not self.LightBoardUI then
      local bpPath = "/Game/UMG/UI_BP/Common/Common_LightBoard_UIBP.Common_LightBoard_UIBP"
      self.LightBoardUI = self:CreateChildWindowWithBpPath(itemRoot.ScaleBox_LightBoard, nil, bpPath)
    end
    if self.LightBoardUI and self.LightBoardUI.UIRoot and self.LightBoardUI.UIRoot.ShowLightBoard then
      self.LightBoardUI.UIRoot:ShowLightBoard(DataMgr.roleData.uid, itemRoot.CanvasPanel_Family)
      log(bWriteLog and "SetDisplay_UIBP: RefreshNicknameFrame light board shown")
    end
  else
    self:SetWidgetVisible(itemRoot.ScaleBox_LightBoard, false)
    log(bWriteLog and "SetDisplay_UIBP: RefreshNicknameFrame no light board data, hiding")
  end
end
function SetDisplay_UIBP:RefreshReturnPlayer(itemRoot, profile)
  log(bWriteLog and "SetDisplay_UIBP: RefreshReturnPlayer")
  if not itemRoot or not itemRoot.SizeBox_Return then
    log(bWriteLog and "SetDisplay_UIBP: RefreshReturnPlayer SizeBox_Return not found")
    return
  end
  local logic_oldfriend_care = require("client.slua.logic.oldfriend.logic_oldfriend_care")
  local bIsRejoin = logic_oldfriend_care.IsRejoinPlayer(profile)
  log(bWriteLog and string.format("SetDisplay_UIBP: RefreshReturnPlayer bIsRejoin=%s", tostring(bIsRejoin)))
  if bIsRejoin then
    self:SetWidgetVisible(itemRoot.SizeBox_Return, true)
    if not self.ReturnPlayerUI then
      self.ReturnPlayerUI = self:CreateChildWindow(itemRoot.SizeBox_Return, UIManager.UI_Config.ReturnActivity_Player_Tag_Item)
    end
    if self.ReturnPlayerUI and self.ReturnPlayerUI.SetData then
      local return_activity_macro = require("client.slua.logic.return_activity.return_activity_macro")
      local type = return_activity_macro.Enum_Tag_ShowType.Other
      self.ReturnPlayerUI:SetData({
        uid = DataMgr.roleData.uid,
        type = type,
        dir = 2
      })
    end
    log(bWriteLog and "SetDisplay_UIBP: RefreshReturnPlayer return player mark shown")
  else
    self:SetWidgetVisible(itemRoot.SizeBox_Return, false)
    log(bWriteLog and "SetDisplay_UIBP: RefreshReturnPlayer not a rejoin player, hiding mark")
  end
end
function SetDisplay_UIBP:RefreshPlayerStatus(itemRoot, uid, profile, status)
  log(bWriteLog and "SetDisplay_UIBP: RefreshPlayerStatus")
  if not (itemRoot and itemRoot.WidgetSwitcher_State) or not itemRoot.Text_GameState then
    log(bWriteLog and "SetDisplay_UIBP: RefreshPlayerStatus required widgets not found")
    return
  end
  local FLMacros = require("client.slua.logic.friend.refactor.friend_list_macros")
  itemRoot.Text_GameState:SetText(LocUtil.GetLocalizeResStr(4020))
  itemRoot.Text_GameState:SetColorAndOpacity(FLMacros.C_Colors.BLUE)
  itemRoot.WidgetSwitcher_State:SetActiveWidgetIndex(0)
  if itemRoot.Button_Go then
    self:SetWidgetVisible(itemRoot.Button_Go, true, false)
  end
  log(bWriteLog and "SetDisplay_UIBP: RefreshPlayerStatus set to idle")
end
local class = require("class")
local ui_base = require("client.slua_ui_framework.base")
return class(ui_base, nil, SetDisplay_UIBP)
