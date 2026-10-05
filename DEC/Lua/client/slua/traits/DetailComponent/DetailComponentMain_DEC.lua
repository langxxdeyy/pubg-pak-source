local DetailComponentMain = {}
local Trait = require("common.trait")
local DetailComponentBase = require("client.slua.traits.DetailComponent.Base.DetailComponentBase")
local ModelDisplayTypeHelper = require("client.logic.avatar.ModelDisplayTypeHelper")
local Traits = {
  require("client.slua.traits.DetailComponent.DetailTraits.DetailInitWidget"),
  require("client.slua.traits.DetailComponent.DetailTraits.DetailBuy"),
  require("client.slua.traits.DetailComponent.DetailTraits.DetailUse"),
  require("client.slua.traits.DetailComponent.DetailTraits.DetailCharacterVoice"),
  require("client.slua.traits.DetailComponent.DetailTraits.DetailDesc"),
  require("client.slua.traits.DetailComponent.DetailTraits.DetailFeatures"),
  require("client.slua.traits.DetailComponent.DetailTraits.DetailItemList"),
  require("client.slua.traits.DetailComponent.DetailTraits.DetailPerSpaceSwitch"),
  require("client.slua.traits.DetailComponent.DetailTraits.DetailJump"),
  require("client.slua.traits.DetailComponent.DetailTraits.DetailLevel"),
  require("client.slua.traits.DetailComponent.DetailTraits.DetailLimit"),
  require("client.slua.traits.DetailComponent.DetailTraits.DetailRelic"),
  require("client.slua.traits.DetailComponent.DetailTraits.DetailState"),
  require("client.slua.traits.DetailComponent.DetailTraits.DetailBranch"),
  require("client.slua.traits.DetailComponent.DetailTraits.DetailTransform"),
  require("client.slua.traits.DetailComponent.DetailTraits.DetailView"),
  require("client.slua.traits.DetailComponent.DetailTraits.DetailVoices"),
  require("client.slua.traits.DetailComponent.DetailTraits.DetailSuitTips"),
  require("client.slua.traits.DetailComponent.DetailTraits.DetailKillBroadcast"),
  require("client.slua.traits.DetailComponent.DetailTraits.DetailRaceCar"),
  require("client.slua.traits.DetailComponent.DetailTraits.DetailPlaneNotice"),
  require("client.slua.traits.DetailComponent.DetailTraits.DetailCommonBtn"),
  require("client.slua.traits.DetailComponent.DetailTraits.DetailSpecialFeature"),
  require("client.slua.traits.DetailComponent.DetailTraits.DetailBlack5Jump"),
  require("client.slua.traits.DetailComponent.AvatarDisplay.TWeaponAutoRotate"),
  require("client.slua.traits.DetailComponent.DetailTraits.DetailRpComponent"),
  require("client.slua.traits.DetailComponent.AvatarDisplay.StreamLevelManager"),
  require("client.slua.traits.DetailComponent.DetailTraits.DetailWingman"),
  require("client.slua.traits.DetailComponent.DetailTraits.DetailVehicleStartUpEffect"),
  require("client.slua.traits.DetailComponent.DetailTraits.DetailDownload"),
  require("client.slua.traits.DetailComponent.DetailTraits.DetailVehicleSwift"),
  require("client.slua.traits.DetailComponent.DetailTraits.DetailCarCompose"),
  require("client.slua.traits.DetailComponent.DetailTraits.DetailColorChangeWeapon"),
  require("client.slua.traits.DetailComponent.DetailTraits.DetailCharacter"),
  require("client.slua.traits.DetailComponent.DetailTraits.DetailMatchCarType")
}
local CDetailComponentMain = Trait.TraitClass(DetailComponentBase, nil, DetailComponentMain, Traits)
function DetailComponentMain:ctor(selfType, initData)
  self.initData = initData or {}
  self.rawSwitches = initData.switches or {}
  self.showOffsetInfo = {
    kill = nil,
    feature = nil,
    sportsCarEnter = nil
  }
  self.curItemID = 0
  self.extraData = nil
  self.curTabID = nil
  self.curSubTabID = nil
  self.jkJumpItem = nil
  self.widgetAvatarDisplay = nil
  self.curScene = self.initData.curScene
  self.cacheBeforeItemID = nil
  self._tShowCurChestData = nil
  self.showOrHide = self.initData.canShowOrHide or false
  self:InitComponentSwitch()
  self.ClickDownLoadItem = {}
  self.AsyncShowAvatarDisplay = {}
  self:DetailStateCtorInit()
  self.Common_FullScreenView_UIBP = nil
  if self.curScene and 0 < self.curScene then
    self:LoadLevelBySceneType(self.curScene)
  end
end
function DetailComponentMain:OnInitialize()
  DetailComponentMain.__super.OnInitialize(self)
  self:InitDetailNamePadding()
  self:InitOffsetInfo()
end
function DetailComponentMain:RegistEvents()
  DetailComponentMain.__super.RegistEvents(self)
  self:BindJumpBtnEvent()
  self:BindUpLevelEvent()
  self:BindStateChangeEvent()
  self:InitBranchComponent()
  self:BindTransformEvent()
  self:BindVoicesEvent()
  self:BindSuitTips()
  self:BindFeatureEvent()
  self:BindDetailKillBroadcastEvent()
  self:BindViewEvent()
  self:BindRaceCarEvent()
  self:BindDetailPlaneNoticeEvent()
  self:BindLimitBtnEvent()
  self:BindBlack5Event()
  self:BindCommonBtnEvent()
  self:BindRpClickEvent()
  self:BindPerSpaceSwitchEvent()
  self:BindWingmanEvent()
  self:InitItemListDetailPadding()
  self:BindVehicleStartUpEvent()
  self:BindVehicleSwiftEvent()
  self:InitViewDetailPadding()
  self:BindMatchCarTypeEvent()
  self:BindDetailBuyEvent()
  self:AddCommonEvent(EVENTTYPE_STORE_DATA, EVENTID_STORE_SHOW_MAIN_UI_ANIMATION, self.ShowSelfUIAnimation, self)
  self:AddCommonEvent(EVENTTYPE_DETAIL_COMPONENT, EVENTID_DETAIL_HIDE_ALL_COMPONENT, self.OnHideAllDetailComponent, self)
  self:AddCommonEvent(EVENTTYPE_DETAIL_COMPONENT, EVENTID_DETAIL_CLICK_RECOVER, self.DetailClickRecover, self)
  self:AddCommonEvent(EVENTTYPE_CHANGE_HEAD, EVENTID_UPDATE_CHANGE_HEAD_PREVIEW, self.OnUpdateChangeHeadPreview, self)
  self:AddCommonEvent(EVENTTYPE_DETAIL_COMPONENT, EVENTID_DETAIL_DISPLAY, self.OnDetailDisplay, self)
  self:AddCommonEvent(EVENTTYPE_PUFFER, EVENTID_CLICK_DOWNLOAD, self.OnAvatarClickDownload, self)
  self:AddCommonEvent(EVENTTYPE_PUFFER, EVENTID_PUFFER_DOWNLOADFINISH, self.OnAvatarDownloadFinished, self)
  self:AddCommonEvent(EVENTTYPE_PUFFER, EVENTID_REMOVE_CLICK_DOWNLOAD, self.OnRemoveAvatarClickDownload, self)
  self:AddCommonEvent(EVENTTYPE_COLOR_SHAPE, EVENTID_USE_UNLOCK_ITEM_UNLOCK_COLOR_SHAPE, self.OnUseUnlockItemUnlockColorShapeEvent, self)
  self:AddCommonEvent(EVENTTYPE_DETAIL_COMPONENT, EVENTID_DETAIL_SPECIAL_FEATURE, self.InitSpecialFeatureCmpWithEvent, self)
  self:AddCommonEvent(EVENTTYPE_PUFFER, EVENTID_PUFFER_PETDOWNLOADED, self.OnPetLoadedSetPosFail, self)
  self:AddCommonEvent(EVENTTYPE_DETAIL_COMPONENT, EVENTID_DETAIL_COMMON_PREVIEW, self.OpenCommonFullScreen, self)
  self:AddCommonEvent(EVENTTYPE_DETAIL_COMPONENT, EVENTID_RECOVER_SPECIAL_ITEM_LEVEL, self.OnRecoverSpecialItemLevel, self)
  self:AddCommonEvent(EVENTTYPE_MOTION, EVENTID_MOTION_UPGRADE, self.OnMotionUpgradeEvent, self)
end
function DetailComponentMain:OnPostInitialize()
  DetailComponentMain.__super.OnPostInitialize(self)
  self:InitializeWidget()
  local f_Padding = FMargin(0, 0, 0, 0)
  if self.initData.topPadding then
    f_Padding = self.initData.topPadding
  end
  self:SetDetailTopPadding(f_Padding)
  self:_OnAsyncLoadingCompleted()
end
function DetailComponentMain:OnAllLoadCompleted()
  self:InitAvatarDisplay()
  self:_ExecuteAsyncProcessPromise()
  self:ResolveAvatarDisplay()
  local fASyncLoadedCallback = self.initData.fASyncLoadedCallback
  if fASyncLoadedCallback and type(fASyncLoadedCallback) == "function" then
    fASyncLoadedCallback()
  end
  EventSystem:postEvent(EVENTTYPE_DETAIL_COMPONENT, EVENTID_DETAIL_LOAD_COMPLETED)
end
function DetailComponentMain:OnShow()
  self:PlayUserWidgetAnimation(self.UIRoot.open, 0, 1, 0, 1)
  DetailComponentMain.__super.OnShow(self)
end
function DetailComponentMain:OnHide()
  self:StopVoice()
  DetailComponentMain.__super.OnHide(self)
end
function DetailComponentMain:OnClose()
  self:_ClearAsyncProcessPromise()
  self:CloseViewComponent()
  self:CloseItemListComp()
  self:CloseOpenCommonFullScreen()
  local logic_store_enter_feature = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_store_enter_feature)
  logic_store_enter_feature:ClearPreItemType()
  logic_store_enter_feature:RestoreAsyncLoadingTimeLimit()
  self:StopAllFeature(true, false, true)
  self.initData = nil
  self.cacheBeforeItemID = nil
  DetailComponentMain.__super.OnClose(self)
end
function DetailComponentMain:OnPetLoadedSetPosFail()
  log(bWriteLog and "  DetailComponentMain:OnPetLoadedSetPosFail.  " .. tostring(self.curItemID))
  local curItemID = self.curItemID
  local itemCfg = CDataTable.GetTableData("Item", curItemID)
  if not itemCfg then
    return
  end
  if not ModelDisplayTypeHelper.IsPet(itemCfg.ItemType) and not ModelDisplayTypeHelper.IsPetSkin(itemCfg.ItemType) then
    return
  end
  log(bWriteLog and "  DetailComponentMain:OnPetLoadedSetPosFail. self.curItemID: " .. tostring(self.curItemID))
  self:ShowAvatarDisplay(curItemID)
  self:SetViewComponentData(curItemID)
end
function DetailComponentMain:ShowSelfUIAnimation()
  self:PlayUserWidgetAnimation(self.UIRoot.open, 0, 1, 0, 1)
end
function DetailComponentMain:OnHideAllDetailComponent()
  self:StopAllFeature(false, false, true, true)
  self:HideAllBtnComponent()
  self:HideUseBtn()
  self:HideCharacterComp()
  self:HideAllVideo()
  self:Collapsed()
  self:SetWidgetVisible(self.UIRoot.CP_Detail, false)
  log(bWriteLog and "DetailComponentMain:OnHideAllDetailComponent")
end
function DetailComponentMain:DetailClickRecover()
  self:HideTransform()
end
function DetailComponentMain:OnUpdateChangeHeadPreview(_, __, bInChangeHeadPreview)
  self:UpdateViewByChangeHeadState(bInChangeHeadPreview)
  self:UpdateItemListByChangeHeadState(bInChangeHeadPreview)
end
function DetailComponentMain:OnDetailDisplay(_, __, itemID)
  self:ShowAvatarDisplay(itemID, {bIgnoreFeature = true})
end
function DetailComponentMain:OnRecoverSpecialItemLevel(_, __, itemID)
  if self.widgetAvatarDisplay then
    local itemCfg = CDataTable.GetTableData("Item", itemID)
    if not itemCfg then
      return
    end
    self.widgetAvatarDisplay:RecoverSpecialItemLevel(itemCfg, self.curScene, false, true, {bIgnoreFeature = false})
  end
end
function DetailComponentMain:OnMotionUpgradeEvent(_, __, itemID)
  self:UpdateEmoteUnlockState(itemID)
  self:OnMotionUpgradeRefresh(itemID)
end
function DetailComponentMain:OnUseUnlockItemUnlockColorShapeEvent(_, _)
  local tShowSwitchCfg = self.initData.switches
  local bIsShow = tShowSwitchCfg.boxDropList
  if not bIsShow then
    return
  end
  local nCurDetailItemID = self.curItemID
  local uObj_itemCfg = CDataTable.GetTableData("Item", nCurDetailItemID)
  if not uObj_itemCfg then
    return
  end
  local tExtraData = self.extraData or {}
  self:RefreshDetailComp(nCurDetailItemID, tExtraData)
end
function DetailComponentMain:OpenCommonFullScreen()
  if not (self:GetParentUI():IsShow() and self.curItemID) or self.curItemID <= 0 then
    log(bWriteLog and string.format("DetailComponentMain:OpenCommonFullScreen ignore inactive instance. self=%s IsShow=%s curItemID=%s", tostring(self), tostring(self:IsShow()), tostring(self.curItemID)))
    return
  end
  local curShowItem = self.realShowItem or self.curItemID
  local specialFeatures, normalFeatures, allShowFeatureList = self:GetShowFeatures()
  local cfg = CDataTable.GetTableData("Item", curShowItem)
  local ModelDisplayer = require("client.logic.avatar.ModelDisplayer")
  local bWeapon, bPet
  if ModelDisplayTypeHelper.IsWeapon(cfg.ItemType) then
    bWeapon = ModelDisplayer.GetShowingStatus() == ModelDisplayer.Enum_Status.Model
  elseif ModelDisplayTypeHelper.IsPetType(cfg.ItemType) then
    bPet = self:CheckIsShowPet()
  end
  local bCheckEquip = true
  if bPet == nil then
    local StoreUtils = require("client.slua.logic.store.utils.store_utils")
    if not StoreUtils.IsEquippedByItemId(curShowItem) then
      bCheckEquip = false
    end
  end
  local full_preview_module = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.full_preview_module)
  if not full_preview_module:ToFullScreenCamera({
    bWeapon = bWeapon,
    bPet = bPet,
    bCheckEquip = bCheckEquip,
    nSceneType = self.curScene
  }) then
    log(bWriteLog and "ViewWeaponPreview:OnClickPreviewFull.  error " .. tostring(curShowItem) .. " itemType: " .. tostring(cfg.ItemType))
    return
  end
  if not bCheckEquip then
    ShowNotice(7000041)
    return
  end
  EventSystem:postEvent(EVENTTYPE_PUFFER, EVENTID_REMOVE_CLICK_DOWNLOAD)
  self:StopAllFeature()
  local extraData = {
    specialFeatures = specialFeatures,
    normalFeatures = normalFeatures,
    allShowFeatureList = allShowFeatureList,
    bWeapon = bWeapon,
    bPet = bPet,
    showItemList = self.showItemList,
    switchConfig = self.switchConfig,
    baseItemId = self.curItemID
  }
  if bWeapon ~= nil then
    self.Common_FullScreenView_UIBP = UIManager.ShowUI(UIManager.UI_Config.Common_FullScreenView_Weapon_UIBP, curShowItem, extraData)
  else
    self.Common_FullScreenView_UIBP = UIManager.ShowUI(UIManager.UI_Config.Common_FullScreenView_UIBP, curShowItem, extraData)
  end
end
function DetailComponentMain:CloseOpenCommonFullScreen()
  if self.Common_FullScreenView_UIBP then
    self.Common_FullScreenView_UIBP:CloseSelf()
  end
  self.Common_FullScreenView_UIBP = nil
end
function DetailComponentMain:SetCustomSwitchConfig(switches, SceneType)
  self:SetNewSwitch(switches, SceneType)
end
function DetailComponentMain:SetData(itemID, extraData)
  log(bWriteLog and "[SY]DetailComponentMain:SetData." .. tostring(itemID))
  self:_CallByPromise(function()
    self:RefreshDetailComp(itemID, extraData)
  end)
end
function DetailComponentMain:HomeAssetSetData(itemID, extraData)
  log(bWriteLog and "DetailComponentMain:HomeAssetSetData." .. tostring(itemID))
  self:_CallByPromise(function()
    self:HomeAssetRefreshDetailComp(itemID, extraData)
  end)
end
function DetailComponentMain:SetProductListData(dataList, clickEvent, defSelectIdx, tExtraData)
  self:_CallByPromise(function()
    self:ItemListComponentSetData(dataList, clickEvent, defSelectIdx, tExtraData)
  end)
end
function DetailComponentMain:SetLimitBuyText(limitBuyInfo)
  self:_CallByPromise(function()
    self:InitLimitBuy(limitBuyInfo)
  end)
end
function DetailComponentMain:SetDescText(descText)
  self:_CallByPromise(function()
    self:InitDesc(descText)
  end)
end
function DetailComponentMain:SetDirectPurchaseItemData(itemID, extraData, tabId)
  extraData = extraData or {}
  self.curItemID = itemID or 0
  local itemCfg = CDataTable.GetTableData("Item", self.curItemID)
  if self.curItemID == 0 or not itemCfg then
    return
  end
  self.curTabID = tabId
  self.extraData = extraData
  local ConstAvatarDislay = require("client.slua.traits.DetailComponent.AvatarDisplay.ConstAvatarDislay")
  if not ConstAvatarDislay.IsStoreCrate(self.curScene) then
    self:ShowAvatarDisplay(itemID, extraData)
  end
  self:InitLevelUp(itemCfg.ItemType)
  self:InitStateChange(itemCfg.ItemType)
  self:RefreshBranch()
  self:InitJump(itemCfg, nil, true)
  self:SetViewComponentData(self.curItemID)
  self:InitSpecialFeatureComponent()
  self:InitFeatures(self.curItemID, itemCfg.ItemType, itemCfg.ItemSubType)
  self:InitVoiceFeature(self.curItemID, itemCfg.ItemType, itemCfg.ItemSubType)
  self:InitSuitTips(self.curItemID, itemCfg.ItemType, itemCfg.ItemSubType)
  self:InitFireworkTips(self.curItemID)
end
function DetailComponentMain:InitAvatarDisplay()
  if not self.curScene or self.curScene <= 0 then
    return
  end
  if not self.widgetAvatarDisplay then
    self.widgetAvatarDisplay = self:CreateChildWindow("CP_AvatarDisplay", UIManager.UI_Config.AvatarDisplayComponent)
  end
  self.widgetAvatarDisplay:InitAvatarDisplay(self.initData.initEquipList, self.curScene, self.initData)
end
function DetailComponentMain:ResolveAvatarDisplay()
  if self.AsyncShowAvatarDisplay and next(self.AsyncShowAvatarDisplay) then
    for i, v in pairs(self.AsyncShowAvatarDisplay) do
      self:ShowAvatarDisplay(v.itemID, v.extraData)
    end
  end
  self.AsyncShowAvatarDisplay = {}
end
function DetailComponentMain:ShowAvatarDisplay(itemID, extraData)
  local itemCfg = CDataTable.GetTableData("Item", itemID)
  if not itemCfg then
    log(bWriteLog and string.format("[DetailComponentMain:ShowAvatarDisplay] itemID:%s, return itemCfg is nil curScene:%s, ", tostring(itemID), tostring(self.curScene)))
    return
  end
  if not self.curScene or self.curScene <= 0 then
    log(bWriteLog and string.format("[DetailComponentMain:ShowAvatarDisplay] itemID:%s, return curScene:%s, ", tostring(itemID), tostring(self.curScene)))
    return
  end
  if not self.widgetAvatarDisplay then
    table.insert(self.AsyncShowAvatarDisplay, {itemID = itemID, extraData = extraData})
    log(bWriteLog and string.format("[DetailComponentMain:ShowAvatarDisplay] itemID:%s, curScene:%s, return widgetAvatarDisplay is nil", tostring(itemID), tostring(self.curScene)))
    return
  end
  if not self:IsShow() then
    self:ShowAvatarDisplayComponent()
  end
  extraData = extraData or {}
  if self.IsIgnoreContinuous and extraData.bIgnoreFeature == nil then
    extraData.bIgnoreFeature = self:IsIgnoreContinuous(itemID, itemCfg.ItemType)
  end
  if ModelDisplayTypeHelper.IsVoiceBag(itemCfg.ItemType, itemCfg.ItemSubType) then
    self:InitVoiceFeature(itemID, itemCfg.ItemType, itemCfg.ItemSubType)
  end
  self.initData.switches = self.switchConfig
  self.widgetAvatarDisplay:ShowAvatarDisplay(itemID, self.curScene, extraData, self.initData)
  if extraData.bIgnoreFeature ~= true then
    self:UpdateRealShowItem(itemID)
  end
end
function DetailComponentMain:ClearAvatarDisplay(bNotDefaultEquip, bResetDefaultEquip)
  if not self.curScene or self.curScene <= 0 or not self.widgetAvatarDisplay then
    return
  end
  self.widgetAvatarDisplay:ClearAvatarDisplay(bNotDefaultEquip)
  if bResetDefaultEquip then
    self.ClickDownLoadItem = {}
  end
end
function DetailComponentMain:CheckIfContainGoldenClothes(dataList)
  if dataList == nil or next(dataList) == nil then
    return false
  end
  if dataList and next(dataList) then
    for k, v in pairs(dataList) do
      local itemID
      if type(v) == "table" then
        itemID = v.DropItemID or v.itemId
      elseif type(v) == "number" then
        itemID = v
      end
      local ItemConfig = CDataTable.GetTableData("Item", itemID)
      if ItemConfig and ModelDisplayTypeHelper.IsGoldenSuitByQuality(ItemConfig.ItemType, ItemConfig.ItemQuality) then
        return true
      end
    end
  end
  return false
end
function DetailComponentMain:SetDefaultSceneByType(SceneType)
  if not self.curScene or not self.widgetAvatarDisplay then
    return
  end
  self.widgetAvatarDisplay:LoadLevelBySceneType(SceneType)
end
function DetailComponentMain:RefreshRpDetail(itemInfo)
  self:RefreshDetailComponent(itemInfo)
end
function DetailComponentMain:HideAvatarDownloadUI()
  if not self.curScene or not self.widgetAvatarDisplay then
    return
  end
  self.widgetAvatarDisplay:HideDownloadPanel()
end
function DetailComponentMain:InitOffsetInfo()
  if not self.initData.offsetInfo then
    return
  end
  for k, v in pairs(self.initData.offsetInfo) do
    self.showOffsetInfo[k] = v
  end
end
function DetailComponentMain:CheckItemIDSame(itemID, tabId, subTabId)
  log(bWriteLog and string.format("StoreDetail:CheckItemIDSame self.curTabID = %s, tabId = %s, subTabId = %s, self.cacheBeforeItemID = %s? itemID = %s", self.curTabID, tabId, subTabId, self.cacheBeforeItemID, itemID))
  if not itemID or self.cacheBeforeItemID ~= itemID then
    self.cacheBeforeItemID = itemID
    return false
  end
  if self.curTabID ~= tabId then
    self.cacheBeforeItemID = itemID
    return false
  end
  if self.curSubTabID ~= subTabId then
    self.cacheBeforeItemID = itemID
    return false
  end
  return true
end
function DetailComponentMain:ShowAvatarDisplayComponent()
  if not self.UIRoot then
    return
  end
  self:SelfHitTestInvisible()
  self:SetWidgetVisible(self.UIRoot.CP_AvatarDisplay, true)
end
function DetailComponentMain:HomeAssetRefreshDetailComp(itemID, extraData)
  log(bWriteLog and string.format("DetailComponentMain:SetData itemID = %s", itemID))
  extraData = extraData or {}
  local itemCfg = CDataTable.GetTableData("Item", itemID)
  if itemID == 0 or itemCfg == nil then
    self:Collapsed()
    self:SetWidgetVisible(self.UIRoot.CP_Detail, false)
    log(bWriteLog and "DetailComponentMain:RefreshDetailComp itemID = 0 or itemCfg == nil")
    return
  else
    self:SetWidgetVisible(self.UIRoot.CP_Detail, true)
    log(bWriteLog and "DetailComponentMain:RefreshDetailComp ShowDetailComp")
  end
  self.curItemID = itemID or 0
  self:UpdateRealShowItem(itemID)
  self.showItemList = nil
  self.curTabID = extraData.currentTabID
  self.curSubTabID = extraData.currentSubTabId
  self.ClickDownLoadItem = {}
  self.extraData = extraData or {}
  self.instId = extraData.inst_id or 0
  self:InitName(self:GetItemName(self.curItemID), extraData.itemValidTime or 0)
  self:InitDesc(self:GetItemDesc(self.curItemID))
  self:InitItemQuality(itemCfg.ItemQuality)
  if extraData.itemEndTime then
    self:InitLimitTime(extraData.itemEndTime or 0)
  else
    self:InitLimitTime(extraData.delistingTime or 0)
  end
  if extraData.wowpassLimitTime then
    self:RefreshWowPassExpireTime(extraData.wowpassLimitTime)
  end
  self:SetViewComponentData(self.curItemID)
end
function DetailComponentMain:RefreshDetailComp(itemID, extraData)
  log(bWriteLog and string.format("DetailComponentMain:SetData itemID = %s", itemID))
  extraData = extraData or {}
  local isSame = self:CheckItemIDSame(itemID, extraData.currentTabID, extraData.currentSubTabId)
  local itemCfg = CDataTable.GetTableData("Item", itemID)
  if itemID == 0 or itemCfg == nil then
    self:Collapsed()
    self:SetWidgetVisible(self.UIRoot.CP_Detail, false)
    log(bWriteLog and "DetailComponentMain:RefreshDetailComp itemID = 0 or itemCfg == nil")
    return
  else
    self:ShowAvatarDisplayComponent()
    self:SetWidgetVisible(self.UIRoot.CP_Detail, true)
    log(bWriteLog and "DetailComponentMain:RefreshDetailComp ShowDetailComp")
  end
  local logic_store_enter_feature = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_store_enter_feature)
  logic_store_enter_feature:SetCurEnterExpressionID(nil)
  self.curItemID = itemID or 0
  self:UpdateRealShowItem(itemID)
  self.showItemList = nil
  self.curTabID = extraData.currentTabID
  self.curSubTabID = extraData.currentSubTabId
  self.ClickDownLoadItem = {}
  self.extraData = extraData or {}
  self.instId = extraData.inst_id or 0
  if self.extraData and self.extraData.bSelectChest then
    self:ClearAvatarDisplay()
  end
  if self:IsCharacterBoxVoice(self.curItemID, extraData.currentSupplyItemID or 0, itemCfg) then
    self:ClearAvatarDisplay()
    self:InitName("")
    self:InitDesc("")
    self:InitItemQuality()
  else
    local VideoLibrary = require("client.slua.logic.video.lobby_video_function_library")
    VideoLibrary.StopCardVoice()
    self:RemoveSingleFeatureData(ENUM_FeatureType.ShowAircraft)
    local ConstAvatarDislay = require("client.slua.traits.DetailComponent.AvatarDisplay.ConstAvatarDislay")
    if not ConstAvatarDislay.IsStoreCrate(self.curScene) and not self.extraData.WeaponChangeColorData then
      self:ShowAvatarDisplay(itemID, extraData)
    elseif self.extraData.WeaponChangeColorData then
      extraData.bIsClearWearingEquip = true
      self:ShowAvatarDisplay(itemID, extraData)
      self:ClearAvatarDisplay()
    end
    self:InitName(self:GetItemName(self.curItemID), extraData.itemValidTime or 0)
    self:InitDesc(self:GetItemDesc(self.curItemID))
    self:InitItemQuality(itemCfg.ItemQuality)
    self:InitWoWPassAuthorTag(extraData.WoWPassTag)
  end
  if extraData.itemEndTime then
    self:InitLimitTime(extraData.itemEndTime or 0)
  else
    self:InitLimitTime(extraData.delistingTime or 0)
  end
  if extraData.wowpassLimitTime then
    self:RefreshWowPassExpireTime(extraData.wowpassLimitTime)
  end
  self:CloseOpenCommonFullScreen()
  self:InitLimitBuy(extraData.limitBuyInfo, extraData.shopId, itemID, extraData)
  self:InitDiscountDesc(extraData.showDiscountDesc)
  self:InitStateChange(itemCfg.ItemType, extraData.bWear)
  self:RefreshBranch(extraData.bWear)
  self:InitJump(itemCfg, extraData.JKExchangeID, nil, extraData and extraData.tJumpTipsInfo)
  self:InitFireworkTips(self.curItemID)
  self:InitEmote(self.curItemID)
  self:InitRaceCar(self.curItemID)
  self:UpdateCharacterComp(extraData.characterId)
  self:UpdateMatchCarTypeBtn(extraData.bShowMatchCarTypeBtn, itemCfg.ItemType)
  self:HideCommonBtn()
  self:InitTransform(self.curItemID, self.curTabID, self.curSubTabID)
  self:SetTransform(false)
  local StoreUtils = require("client.slua.logic.store.utils.store_utils")
  local isSelectChest = StoreUtils.IsSelectChestBox(itemCfg.ItemType, itemCfg.ItemSubType)
  local isChest = StoreUtils.IsTreasuresAndSpecialChests(itemCfg.ItemType, itemCfg.ItemSubType) or isSelectChest
  log(bWriteLog and string.format("StoreDetail:SetData isSame = %s", isSame))
  if not isSame and not isChest and extraData.bRefreshItemList ~= false then
    self:SetSelectNameItemList("")
    self:SetProductListData({})
  end
  self:InitSpecialFeatureComponent()
  if not isChest or not isSame then
    self:SetViewComponentData(self.curItemID)
    self:InitFeatures(self.curItemID, itemCfg.ItemType, itemCfg.ItemSubType, {
      bGetFeatureOne = self.extraData.bGetFeatureOne or false,
      bIsShowAskTips = self.extraData.bIsShowAskTips,
      sAskTips = self.extraData.sAskTips
    })
    self:InitSuitTips(self.curItemID, itemCfg.ItemType, itemCfg.ItemSubType)
  end
  if not isSame and not isChest then
    self:InitVoiceFeature(self.curItemID, itemCfg.ItemType, itemCfg.ItemSubType)
  end
  self:InitDetailColorChangeWeapon(self.extraData.WeaponChangeColorData)
  self:InitCarCompose(self.extraData.lowCarList)
  self:InitLevelUp(itemCfg.ItemType)
  self:UpdateExtraExchange()
  self:InitBlack5Jump()
  self:InitPersonalSpaceSwitch(itemCfg.ItemType, itemCfg.ItemSubType)
  self:InitDailyDiscountBuy(extraData)
  self:InitBoxDetailsShow(self.curItemID, itemCfg, extraData)
end
function DetailComponentMain:InitComponentSwitch()
  self.switchConfig = {}
  local ConstDetail = require("client.slua.traits.DetailComponent.ConstDetail")
  for i, v in pairs(ConstDetail.DetailCompDefaultConfig) do
    if type(v) == "boolean" then
      self.switchConfig[i] = v
    end
  end
  local customizeSwitch = self.rawSwitches or {}
  for i, v in pairs(customizeSwitch) do
    self.switchConfig[i] = v
  end
end
function DetailComponentMain:SetNewSwitch(switches, SceneType)
  self.switchConfig = {}
  local ConstDetail = require("client.slua.traits.DetailComponent.ConstDetail")
  for i, v in pairs(ConstDetail.DetailCompDefaultConfig) do
    if type(v) == "boolean" then
      self.switchConfig[i] = v
    end
  end
  if switches then
    for i, v in pairs(switches) do
      self.switchConfig[i] = v
    end
  end
  local customizeSwitch = self.rawSwitches
  for i, v in pairs(customizeSwitch) do
    self.switchConfig[i] = v
  end
  self.curScene = SceneType
  self:CustomizedViewSwitches(self.switchConfig, self.curScene)
  self:CustomizedItemListSwitches(self.switchConfig)
  self:CustomizedFeatureCompSwitches(self.switchConfig, self.curScene)
end
function DetailComponentMain:InitBoxDetailsShow(nItemId, uObj_ItemCfg, tExtraData)
  local tShowSwitchCfg = self.initData.switches
  local bIsShow = tShowSwitchCfg.boxDropList
  if not bIsShow then
    return
  end
  local tShowListData = tExtraData.tShowBoxListData
  local fClickListItemEvent = tExtraData.fClickListItemEvent
  if tShowListData then
    self._tShowCurChestData = tShowListData
    self:SetProductListData(tShowListData, fClickListItemEvent, 1)
    self:SetBoxDropListRateData(nItemId, tExtraData)
    return
  end
  if uObj_ItemCfg.ItemType == ENUM_ITEM_TYPE.Starter_Pack then
    local Logic_DetailUtils = require("client.slua.logic.common.Logic_DetailUtils")
    local BasicDataChestTable = ModuleManager.GetModule(ModuleManager.DataModuleConfig.BasicDataChestTable)
    local fCacheChestData = function(nChestId, tAllItem)
      if not self.UIRoot or self.curItemID ~= nChestId then
        return
      end
      if not tAllItem or not next(tAllItem) then
        return
      end
      local tAllDropItem = Logic_DetailUtils.OrganizeBoxDropData(tAllItem, nChestId)
      self._tShowCurChestData = tAllDropItem
      self:SetProductListData(tAllDropItem, fClickListItemEvent, 1)
      self:SetBoxDropListRateData(nChestId, tExtraData, tAllDropItem)
    end
    BasicDataChestTable:GetOrReqData(nItemId, fCacheChestData)
  else
    self:InitSpecialItemShowList(nItemId)
  end
end
function DetailComponentMain:InitSpecialItemShowList(nItemId)
  local Logic_ColorShapeUtils = require("client.slua.logic.wardrobe.Logic_ColorShapeUtils")
  if nItemId == Logic_ColorShapeUtils.GetColorShapeUnlockItemId() then
    local LogicMultiItemModule = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicMultiItemModule)
    local tAllShowItem = LogicMultiItemModule:GetAllUnlockableData()
    local tShowData = {}
    for _, v in ipairs(tAllShowItem) do
      table.insert(tShowData, {DropItemID = v})
    end
    self._tShowCurChestData = tShowData
    local Logic_DetailUtils = require("client.slua.logic.common.Logic_DetailUtils")
    local Enum_DetailListMoreType = Logic_DetailUtils.Enum_DetailListMoreType
    local tProductExtraData = {
      sTitle = LocUtil.GetLocalizeResStr(18130062),
      nMoreShowType = Enum_DetailListMoreType.ColorShapeUnlockPopup,
      bMaskFirstSelect = true,
      nShowMoreBtnByNeedItemCount = 3
    }
    self:SetProductListData(tShowData, function()
      UIManager.ShowUI(UIManager.UI_Config.UnknowPass_BP_DoubleColorSuit_Popup_UIBP)
      return true
    end, nil, tProductExtraData)
  end
end
function DetailComponentMain:SetBoxDropListRateData(nItemId, tExtraData)
  local tShowSwitchCfg = self.initData.switches
  local bIsShow = tShowSwitchCfg.boxDropRate
  if not bIsShow then
    return
  end
  local Logic_DetailUtils = require("client.slua.logic.common.Logic_DetailUtils")
  local nRateShowType = tExtraData.nRateShowType
  local tRateShowData = tExtraData.tRateShowData
  if not nRateShowType then
    local Enum_RateType = Logic_DetailUtils.Rate_Type
    local bIsSelectChest = Logic_DetailUtils.CheckIfCustomSelectChest(nItemId)
    nRateShowType = bIsSelectChest and Enum_RateType.none or Enum_RateType.one
  end
  self:UpdateRateInfo(nRateShowType, tRateShowData)
end
function DetailComponentMain:UpdateRealShowItem(ItemId, showItemList)
  self.realShowItem = ItemId
  self.showItemList = showItemList or self.showItemList or {ItemId}
end
return CDetailComponentMain
