local NewStoreSystem = {}
local Trait = require("common.trait")
local NewStoreAsyncBase = require("client.slua.umg.NewStoreV280.Main.NewStoreAsyncBase")
local Traits = {
  require("client.slua.umg.NewStoreV280.Traits.Common.TStoreReporterUtil"),
  require("client.slua.umg.NewStoreV280.Traits.Common.TStoreJumpUtil"),
  require("client.slua.umg.NewStoreV280.Traits.Common.TStoreShowHideUtil"),
  require("client.slua.umg.NewStoreV280.Traits.Store.TStoreStateData"),
  require("client.slua.umg.NewStoreV280.Traits.Store.TStoreTabConfig")
}
local CNewStoreSystem = Trait.TraitClass(NewStoreAsyncBase, nil, NewStoreSystem, Traits)
function NewStoreSystem:ctor(selfType, _, jumpInfo)
  local store_jump_manager = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.store_jump_manager)
  store_jump_manager:SetJumpInfo(jumpInfo)
  store_jump_manager:SetBuySource(jumpInfo and jumpInfo.buySource)
end
function NewStoreSystem:OnInitialize()
  NewStoreSystem.__super.OnInitialize(self)
  local store_collect_data = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.store_collect_data)
  store_collect_data:GetSelfCollectData()
  local LuckAirDropHandler = require("client.network.Protocol.LuckAirDropHandler")
  LuckAirDropHandler.send_target_airdrop_trigger_req(1)
end
function NewStoreSystem:RegistEvents()
  NewStoreSystem.__super.RegistEvents(self)
  self:AddCommonEvent(EVENTTYPE_STORE_DATA, EVENTID_STORE_PAGETAB_CLICK, self.OnPageTabClicked, self)
  self:AddCommonEvent(EVENTTYPE_STORE_DATA, EVENTID_STORE_SUBPAGETAB_CLICK, self.OnSubPageTabClicked, self)
  self:AddCommonEvent(EVENTTYPE_STORE_BTNEVENT, EVENTID_STORE_FULLSCREEN_PREVIEW_QUIT, self.QuitFullScreenPreview, self)
  self:AddCommonEvent(EVENTTYPE_KEY_DESIGN_POINT, EVENTID_KEY_DESIGN_POINT_CLOSE, self.OnKDPUIClose, self)
  self:AddCommonEvent(EVENTTYPE_STORE_BTNEVENT, EVENTID_STORE_FULL_AVATAR_PREVIEW, self.FullAvatarPreview, self)
  self:AddControlEventByControl(self.UIRoot.btn_goback, "OnClicked", self.OnClickBack, self)
  self:AddCommonEvent(EVENTTYPE_LUCKAIR_TARGET, EVENTID_LUCKY_AIRDROP_TARGET_SHOW, self.ShowAirDropIcon, self)
  self:AddCommonEvent(EVENTTYPE_LUCKAIR_TARGET, EVENTID_LUCKY_AIRDROP_TARGET_HIDE, self.HideAirDropIcon, self)
  self:AddControlEventByControl(self.UIRoot.Common_SmallKT_Entrance_Item_UIBP.Button_0, "OnClicked", self.OnClickAirDropIcon, self)
end
function NewStoreSystem:OnConstruct(_, jumpInfo)
  local store_jump_manager = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.store_jump_manager)
  store_jump_manager:SetJumpInfo(jumpInfo)
end
function NewStoreSystem:OnPostInitialize()
  log(bWriteLog and "[ui_open] NewStoreSystem:OnPostInitialize")
  NewStoreSystem.__super.OnPostInitialize(self)
  self:InitStoreJumpUtil()
  self:InitShowHideUtil()
end
function NewStoreSystem:OnShow()
  NewStoreSystem.__super.OnShow(self)
  self:UpdateUI()
end
function NewStoreSystem:OnClose()
  log(bWriteLog and "[ui_close] NewStoreSystem:OnClose")
  self:QuitFullScreenPreview()
  self:ClosePageListPanel()
  self:CloseComponents()
  self:FinalShowHideUtil()
  EventSystem:postEvent(EVENTTYPE_STORE, EVENTID_STORE_ON_CLOSE)
  local store_supply_switcher = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.store_supply_switcher)
  store_supply_switcher:HideStore()
  local store_jump_manager = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.store_jump_manager)
  store_jump_manager:ClearBuySource()
  NewStoreSystem.__super.OnClose(self)
end
function NewStoreSystem:OnPageTabClicked(_, __, tabIndex, tabData)
  log(bWriteLog and string.format("NewStoreSystem:OnPageTabClicked index: %d", tabIndex))
  self.tabId = tabData.tabId
  self.currentTabIndex = tabIndex
  self.currentTabData = tabData
  self.currentSubTabIndex = 0
  self:ShowAirDropIcon()
end
function NewStoreSystem:OnSubPageTabClicked(_, __, subTabIndex, subTabData)
  log(bWriteLog and string.format("NewStoreSystem:OnSubPageTabClicked subTabIndex: %d", subTabIndex))
  if self.currentSubTabIndex == subTabIndex then
    return
  end
  self.currentSubTabIndex = subTabIndex
  self.subTabId = subTabData.subTabId
  self:UpdatePageList()
  self:ShowAirDropIcon()
  self:SetCurGroupForStore(self.tabId, self.subTabId)
  if self.subTabId ~= StoreConst.subtype_new_recommend_rec then
    local guideCfg = require("client.slua.umg.XSuit_Workshop.Config.XSuit_Guide_Config")
    guideCfg.ShowMaterialGuide("Wardrobe")
  end
end
function NewStoreSystem:GetTabType()
  return StoreConst.store_tab
end
function NewStoreSystem:IsStoreSystem()
  log(bWriteLog and "NewStoreSystem:IsStoreSystem")
  return true
end
function NewStoreSystem:ClearProductItemData()
end
function NewStoreSystem:UpdateUI()
  self:UpdateStoreTitle()
  self:ShowAirDropIcon()
end
function NewStoreSystem:UpdateStoreTitle()
  self.UIRoot.CanvasPanel_3:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
  if self:GetTabType() == StoreConst.store_tab then
    self.UIRoot.TextBlock_2:SetText(LocUtil.GetLocalizeResStr(10074))
    self.UIRoot.WidgetSwitcher_0:SetActiveWidgetIndex(0)
  else
    self.UIRoot.TextBlock_2:SetText(LocUtil.GetLocalizeResStr(501065))
    self.UIRoot.WidgetSwitcher_0:SetActiveWidgetIndex(1)
  end
end
function NewStoreSystem:IsShowCustomPanel()
  return false
end
function NewStoreSystem:OnClickBack()
  self:OnClickClose()
end
function NewStoreSystem:GetDataForJumpBack()
  local jumpInfo = {Tab1 = 0, Tab2 = 0}
  local tabData = self:GetTabPanelCurrentTabData()
  local subTabData = self:GetTabPanelCurrentSubTabData()
  if tabData then
    jumpInfo.Tab1 = tabData.tabId
  end
  if subTabData then
    jumpInfo.Tab2 = subTabData.subTabId
  end
  if self.PageListPanel then
    local currentItem = self.PageListPanel:GetCurrentItemInfo()
    if currentItem then
      jumpInfo.itemId = currentItem.itemId
      jumpInfo.shopId = currentItem.shopId
    end
    local curBannerInfo = self.PageListPanel:GetCurrentBannerInfo()
    if curBannerInfo then
      jumpInfo.bannerID = curBannerInfo.id
    end
  end
  return {
    ctorData = {
      [1] = self:GetTabType(),
      [2] = jumpInfo
    }
  }
end
function NewStoreSystem:EnterFullScreen(isFullScreen, itemid, viewId, onlyShowKDP)
  EventSystem:postEvent(EVENTTYPE_STORE_BTNEVENT, EVENTID_THEMESHOP_ENTERFULLSCREEN, isFullScreen)
  local KeyDesignPointSystem = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.KeyDesignPointSystem)
  local NeedShowKDP = KeyDesignPointSystem:NeedShowKeyDesign(viewId, true)
  local ModelDisplayTypeHelper = require("client.logic.avatar.ModelDisplayTypeHelper")
  local bIsWeapon = ModelDisplayTypeHelper.IsWeaponById(viewId)
  if bIsWeapon and onlyShowKDP and not NeedShowKDP then
    ShowNotice(511044)
    return
  end
  if NeedShowKDP then
    log(bWriteLog and "NewStoreSystem:EnterFullScreen Show KDP")
    if isFullScreen then
      KeyDesignPointSystem:ShowWeaponKDPUIAsChild(self, "CanvasPanel_0", viewId)
      self.UIRoot.CanvasPanel_Detail:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
    else
      KeyDesignPointSystem:CloseWeaponKDPUI()
      self.UIRoot.CanvasPanel_Detail:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    end
  else
    self:FullScreenPreviewWeapon(isFullScreen, itemid)
  end
  self.IsFullScreen = isFullScreen
  if isFullScreen then
    self:PlayUserWidgetAnimation(self.UIRoot.out, 0, 1, 0, 1)
    self.UIRoot.AdapationPanel:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
    self:SetWidgetVisible(self.UIRoot.CanvasPanel_Money, false)
    self:SetWidgetVisible(self.UIRoot.Image_WhiteBg, false)
  else
    self:PlayUserWidgetAnimation(self.UIRoot.open, 0, 1, 0, 1)
    self.UIRoot.AdapationPanel:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    self:SetWidgetVisible(self.UIRoot.CanvasPanel_Money, true)
    self:SetWidgetVisible(self.UIRoot.Image_WhiteBg, true)
  end
end
function NewStoreSystem:FullScreenPreviewWeapon(isFullScreen, itemId)
  log_warning(bWriteLog and "  NewStoreSystem:FullScreenPreviewWeapon. isFullScreen: " .. tostring(isFullScreen))
  if not itemId or itemId <= 0 then
    return
  end
  local HallThemeFeture = CDataTable.GetTableData("HallThemeFeture", itemId)
  if HallThemeFeture then
    return
  end
  local Lobby_camera_manager_module = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.Lobby_camera_manager_module)
  local store_item_upgrade_system = require("client.logic.store.store_item_upgrade")
  if isFullScreen then
    if store_item_upgrade_system.GetCurrentModele() == store_item_upgrade_system.module.weapon then
      store_item_upgrade_system.SetSavedLastModelItemID(store_item_upgrade_system.GetCurrentItemID())
    else
      store_item_upgrade_system.SetSavedLastModelItemID(itemId)
    end
    store_item_upgrade_system.SetCurrentModele(store_item_upgrade_system.module.weapon_preview)
    local store_camera_manager = require("client.slua.logic.store.store_camera_manager")
    store_camera_manager.ShowMallFullScreen(itemId, Lobby_camera_manager_module.Enum_CameraID.store_preview)
  else
    Lobby_camera_manager_module:SwitchCamera(Lobby_camera_manager_module.Enum_CameraID.store_weapon)
    local ModelDisplayer = require("client.logic.avatar.ModelDisplayer")
    ModelDisplayer.Show()
  end
end
function NewStoreSystem:QuitFullScreenPreview()
  if self.IsFullScreen then
    self.IsFullScreen = false
    local itemId = self.subPage and self.subPage.currentItem and self.subPage.currentItem.itemId
    self:EnterFullScreen(false, itemId)
  end
end
function NewStoreSystem:FullAvatarPreview(_, _, isOpen)
  if isOpen then
    self:Collapsed()
  else
    self:SelfHitTestInvisible()
  end
end
function NewStoreSystem:OnKDPUIClose(_, _)
  EventSystem:postEvent(EVENTTYPE_STORE_BTNEVENT, EVENTID_STORE_ONCLOSE_PREVITE)
  EventSystem:postEvent(EVENTTYPE_THEME_SYSTEM, EVENTID_THEMESHOP_PREVIEW, true)
  self.IsFullScreen = false
end
function NewStoreSystem:GotoSpecifiedTabAndItem(tabId, subTabId, itemId)
  self:GetTabPanel():GotoSpecifiedTabAndItem(tabId, subTabId, itemId)
  self:UpdateUI()
end
function NewStoreSystem:OnAndroidBack()
  if self.IsFullScreen then
    self:QuitFullScreenPreview()
    EventSystem:postEvent(EVENTTYPE_STORE_BTNEVENT, EVENTID_STORE_ONCLOSE_PREVITE)
    self:OnClickSkipMotion()
    return
  end
  self:CloseSelf()
end
return CNewStoreSystem
