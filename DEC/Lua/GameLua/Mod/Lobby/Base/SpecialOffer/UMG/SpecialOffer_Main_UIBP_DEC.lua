local SpecialOffer_Main_UIBP = {}
local cfg = require("client.slua.logic.specialoffer.special_offer_cfg")
local id2ResId, uiCdg, id2Func, id2Coins, id2CheckShow, waitShow = cfg.id2ResId, cfg.uiCdg, cfg.id2Func, cfg.id2Coins, cfg.id2CheckShow, cfg.waitShow
local hideClickBolck = cfg.hideClickBolck
local id2ResIdByIn = cfg.id2ResIdByIn
local sDefaultSelectedTabBgPath = "/Game/UMG/Texture_200/Lobby_NoAtlas/Common/Tab/Vertical/LevelOne/Text/Common_Tab_Vertical_LevelOne_Text_Button.Common_Tab_Vertical_LevelOne_Text_Button"
local sSmallRPSelectedTabBgPath = "/Game/UMG/Texture_200/Lobby_NoAtlas/Common/Tab/Vertical/LevelOne/Text/Common_Tab_Vertical_LevelOne_Text_Button_02.Common_Tab_Vertical_LevelOne_Text_Button_02"
local sClosedIconPath = "/Game/UMG/Texture_200/Atlas/Common_New_Atlas/Frames/Common_Icon_Closed_png.Common_Icon_Closed_png"
local sDarkSkinClosedIconPath = "/Game/UMG/Texture_200/Atlas/Common_New_Atlas/Frames/Common_Icon_Closed_3_png.Common_Icon_Closed_3_png"
local nIndiaPreviewActivityId = 9460050
local Logic_SmallRPSpecialOfferAdapter = require("client.slua.logic.specialoffer.SmallRP.Logic_SmallRPSpecialOfferAdapter")
local IsSmallRPActivityId = function(nId)
  nId = tonumber(nId)
  if not nId then
    return false
  end
  if Logic_SmallRPSpecialOfferAdapter.IsActivityOpen(nId) then
    return true
  end
  return 100000 <= nId
end
local GetSmallRPActivityId = function(tUrlParam)
  if type(tUrlParam) ~= "table" then
    return
  end
  local nActivityId = tonumber(tUrlParam.activity_id)
  if nActivityId then
    return nActivityId
  end
  local nRoundId = tonumber(tUrlParam.round)
  if IsSmallRPActivityId(nRoundId) then
    return nRoundId
  end
end
local GetSmallRPLegacyRoundId = function(tUrlParam)
  if type(tUrlParam) ~= "table" then
    return
  end
  if tonumber(tUrlParam.activity_id) then
    return
  end
  local nRoundId = tonumber(tUrlParam.round)
  if nRoundId and not IsSmallRPActivityId(nRoundId) then
    return nRoundId
  end
end
local GetCurLegacySmallRPRoundId = function()
  local Logic_SmallRP = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.Logic_SmallRP)
  if not Logic_SmallRP or not Logic_SmallRP.GetActRoundId then
    return nil
  end
  local nLegacyRoundId = Logic_SmallRP:GetActRoundId()
  return tonumber(nLegacyRoundId)
end
local GetSmallRPDownloadContext = function(nId, nSmallRPActivityId)
  if nId ~= cfg.SmallRP or not nSmallRPActivityId then
    return
  end
  return {activity_id = nSmallRPActivityId}
end
local IsLegacySmallRPRound17 = function(nId, nSmallRPActivityId, nSmallRPLegacyRoundId)
  return nId == cfg.SmallRP and not nSmallRPActivityId and nSmallRPLegacyRoundId == 17
end
local IsSmallRPActivityDarkSkin = function(nId, nSmallRPActivityId)
  return nId == cfg.SmallRP and tonumber(nSmallRPActivityId) == nIndiaPreviewActivityId
end
function SpecialOffer_Main_UIBP:ctor(_, OrActId, urlParam)
  cfg.Init()
  self.urlParam = urlParam
  self._nSmallRPActivityId = tonumber(OrActId) == cfg.SmallRP and GetSmallRPActivityId(urlParam) or nil
  self._nSmallRPLegacyRoundId = tonumber(OrActId) == cfg.SmallRP and GetSmallRPLegacyRoundId(urlParam) or nil
  self._nPendingSmallRPActivityId = self._nSmallRPActivityId
  self._bPendingSmallRPDefault = tonumber(OrActId) == cfg.SmallRP and not self._nSmallRPActivityId and not self._nSmallRPLegacyRoundId
  self:SwitchId(OrActId)
  if self.nId == cfg.NewGroupBuy then
    if not self.urlParam then
      self.urlParam = {}
    end
    if not self.urlParam.source and tonumber(self.urlParam.internal) ~= 1 then
      self.urlParam.source = cfg.BargainEntrySource and cfg.BargainEntrySource.Tehui or 1
    end
  end
  local PublishRegionMacros = require("client.slua.config.ClientMacros.PublishRegionMacros")
  if PublishRegionMacros.IsJapanOrKorea() then
    local RechargePurchaseHandler = require("client.network.Protocol.RechargePurchaseHandler")
    RechargePurchaseHandler.send_get_limited_special_chest_req()
  end
  self.coinUIs = {}
  self.uiConfig = nil
  self.MarkTypes = {}
  self.bSkipAndroidBack = false
  self.TabCountDownTimerMap = {}
  self._tSmallRPActivityIdByIndex = {}
  self._tSmallRPActivityWidgetMap = {}
  self._cObj_downloadUI = nil
  self.whiteColor = FLinearColor(1, 1, 1, 0.7)
  self.whiteTextColor = FLinearColor(1, 1, 1, 1)
  self.halfWhiteColor = FLinearColor(1, 1, 1, 0.5)
  self.defaultIconTint = FLinearColor(0, 0, 0, 0.7)
  self.unSelectColor = FLinearColor(0, 0, 0, 1)
end
function SpecialOffer_Main_UIBP:OnInitialize()
  SpecialOffer_Main_UIBP.__super.OnInitialize(self)
  self.LoopScrollBox_Tab = self:InitScrollBox(self.UIRoot.LoopScrollBox_Tab)
  local special_offer_net_cfg = require("client.slua.logic.specialoffer.special_offer_net_cfg")
  special_offer_net_cfg.SendActNet()
end
function SpecialOffer_Main_UIBP:RegistEvents()
  SpecialOffer_Main_UIBP.__super.RegistEvents(self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Close, self.OnClickBtnClose, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Jump, self.OnClickBtnExchange, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_More, self.OnClickMore, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Help, self.OnClickBtnHelp, self)
  if self.UIRoot.Button_MoreDownload then
    self:AddOnClickedEventByControl(self.UIRoot.Button_MoreDownload, self.OnClickBtnMoreDownload, self)
  end
  self.LoopScrollBox_Tab:SetRefreshItemCallback(self.OnRefreshItem, self)
  self.LoopScrollBox_Tab:AddItemWidgetChildEvent("Button_Sel", "OnClicked", self.OnClickItem, self)
  self:AddCommonEvent(EVENTTYPE_SPECIAL_OFFER, EVENTID_SPECIAL_SKIP_ANDROIDBACK, self.CantAndroidBack, self)
  self:AddCommonEvent(EVENTTYPE_SPECIAL_OFFER, EVENTID_SPECIAL_RED_CHANGE, self.EventRefreshTab, self)
  self:AddCommonEvent(EVENTTYPE_DATA_MGR, EVNETID_DATAMGR_ACTIVITY_CHANGE, self.EventActivityChange, self)
  self:AddCommonEvent(EVENTTYPE_NEXTDAY, EVENTID_NEXTDAY_ZERO, self.OnNextDayUpdate, self)
  self:AddCommonEvent(EVENTTYPE_SPECIAL_OFFER, EVENTID_SPECIAL_OFFER_REFRESH_PAGE, self.UpdateUI, self)
  self:AddCommonEvent(EVENTTYPE_ACTIVITY, EVENTID_LUCKYBACK_DARW_TEN_ANIMATION, self.EventShowBorder, self)
  self:AddCommonEvent(EVENTTYPE_ACTIVITY, EVENTID_LUCKYBACK_DARW_ONE_ANIMATION, self.EventShowBorder, self)
  self:AddCommonEvent(EVENTTYPE_SPECIAL_OFFER, EVENTID_SPECIAL_OFFER_HIDE_TAB, self.EventHideTab, self)
  self:AddCommonEvent(EVENTTYPE_SPECIAL_OFFER, EVENTID_SPECIAL_OFFER_SHOW_TAB, self.EventShowTab, self)
  self:AddCommonEvent(EVENTTYPE_SPECIAL_OFFER, EVENTID_SPECIAL_OFFER_SET_MASK, self.SetMask, self)
  self:AddCommonEvent(EVENTTYPE_SPECIAL_OFFER, EVENTID_SPECIAL_OFFER_DOWNLOAD_COMPLETE, self.OnDownloadComplete, self)
  self:AddCommonEvent(EVENTTYPE_STORE_BTNEVENT, EVENTID_STORE_ONCLICK_PREVIEW, self.OnClickFullScreen, self)
  self:AddCommonEvent(EVENTID_UI, BP_ENUM_UI_SHOW, self.OnTabUIShow, self)
end
function SpecialOffer_Main_UIBP:OnPostInitialize()
  SpecialOffer_Main_UIBP.__super.OnPostInitialize(self)
  if Client.IsMatchVersion and Client.IsMatchVersion() then
    local title = LocUtil.GetLocalizeResStr(101001)
    local text = LocUtil.GetLocalizeResStr(120001)
    local CommonMsgBoxMgr = require("client.slua.logic.common.logic_common_msg_box")
    CommonMsgBoxMgr.Show(1, title, text)
    UIManager.CloseUI(UIManager.UI_Config.SpecialOffer_Main_UIBP)
    return
  end
  self:PlayUserWidgetAnimation(self.UIRoot.Fadein, 0, 1, 0, 1)
  self:SetMask(nil, nil, true)
  self:UpdateUI()
  self:IsHideSmallPayBtn()
  self:ReqGiftData()
  self:ReqDailyData()
  self:ReqDiscountDirectData()
  self:ReqSmallPaymentData()
  self:CreateSmallPaymentDownloadUI()
end
function SpecialOffer_Main_UIBP:OnClose()
  local RechargeSystem = require("client.logic.recharge.logic_recharge")
  RechargeSystem.UpdateChargeUIShowingState(false)
  self._tSmallRPActivityWidgetMap = {}
end
function SpecialOffer_Main_UIBP:OnAndroidBack()
  if not self.bSkipAndroidBack then
    self:CloseSelf()
  else
    log_warning(bWriteLog and "  : OnAndroidBack is in golden")
  end
end
function SpecialOffer_Main_UIBP:CantAndroidBack()
  self.bSkipAndroidBack = true
  self:AddTimer(5, function()
    self:CanAndroidBack()
  end)
end
function SpecialOffer_Main_UIBP:CanAndroidBack()
  self.bSkipAndroidBack = false
end
function SpecialOffer_Main_UIBP:SwitchId(OrActId)
  local lastId = self.nId
  self.nId = OrActId
  log(bWriteLog and "  :SwitchId self.nId: " .. tostring(self.nId))
  if self.nId then
    for i, act in pairs(cfg.id2ActId) do
      if tonumber(act) == self.nId then
        self.nId = i
        log(bWriteLog and "  : self.nId: " .. tostring(self.nId))
        break
      end
    end
  end
  if not self:CheckShowFunciton(self.nId) then
    if self.nId then
      log_warning("SpecialOfferId is error:" .. tostring(self.nId))
    end
    if self:CheckShowFunciton(cfg.NewGroupBuy) then
      self.nId = cfg.NewGroupBuy
    end
  end
  self:ChangeToSubscribe()
  if self.nId == lastId then
    return
  end
  return lastId
end
function SpecialOffer_Main_UIBP:CheckShowFunciton(id)
  if self:CheckIsFamilyBlock(id) then
    return false
  end
  local checkShowFunc = cfg.id2CheckShow[id]
  if id == cfg.SmallRP and self._nSmallRPActivityId and Logic_SmallRPSpecialOfferAdapter.IsActivityOpen(self._nSmallRPActivityId) then
    return cfg.uiCdg[id] ~= nil
  end
  return id and cfg.uiCdg[id] and (not checkShowFunc or checkShowFunc())
end
function SpecialOffer_Main_UIBP:ChangeToSubscribe()
  if self.nId == cfg.golden then
    local isShowGold = self:CheckShowFunciton(cfg.golden)
    if not isShowGold then
      ShowNotice(77066)
    end
    if not isShowGold then
      local AOSSHOPMacros = require("client.slua.config.ClientMacros.AOSSHOPMacros")
      local aosShop = Client.GetAOSSHOP()
      if aosShop == AOSSHOPMacros.Samsung or aosShop == AOSSHOPMacros.Amazon then
        self.nId = cfg.recharge
        return
      end
      self.nId = cfg.subscribe
    end
  end
end
function SpecialOffer_Main_UIBP:SwitchUI(idOrActId, urlParam)
  local nLastSmallRPActivityId = self._nSmallRPActivityId
  local nLastSmallRPLegacyRoundId = self._nSmallRPLegacyRoundId
  local nTargetSmallRPActivityId = tonumber(idOrActId) == cfg.SmallRP and GetSmallRPActivityId(urlParam) or nil
  local nTargetSmallRPLegacyRoundId = tonumber(idOrActId) == cfg.SmallRP and GetSmallRPLegacyRoundId(urlParam) or nil
  self._nSmallRPActivityId = nTargetSmallRPActivityId
  self._nSmallRPLegacyRoundId = nTargetSmallRPLegacyRoundId
  self._nPendingSmallRPActivityId = nTargetSmallRPActivityId
  self._bPendingSmallRPDefault = tonumber(idOrActId) == cfg.SmallRP and not nTargetSmallRPActivityId and not nTargetSmallRPLegacyRoundId
  local lastId = self:SwitchId(idOrActId)
  self.urlParam = urlParam or self.urlParam
  log(bWriteLog and "[SY]SpecialOffer_Main_UIBP:SwitchUI." .. tostring(lastId))
  if lastId or nLastSmallRPActivityId ~= self._nSmallRPActivityId or nLastSmallRPLegacyRoundId ~= self._nSmallRPLegacyRoundId then
    self:SelectTab()
    self.LoopScrollBox_Tab:RefreshAllItems()
    self:ShowSubUI(lastId)
  elseif self.nId == cfg.NewGroupBuy and tonumber(urlParam and urlParam.tabId) == 2 and self.subUI and self.subUI.JumpToBargainTab then
    self.subUI:JumpToBargainTab(urlParam)
    self.urlParam = nil
  end
end
function SpecialOffer_Main_UIBP:OnNextDayUpdate()
  self:NextDayReqActData()
end
function SpecialOffer_Main_UIBP:UpdateUI()
  self.allData = {}
  self._tSmallRPActivityIdByIndex = {}
  local AppendTab = function(nId, nActivityId)
    local nIndex = #self.allData + 1
    self.allData[nIndex] = nId
    self._tSmallRPActivityIdByIndex[nIndex] = nActivityId
  end
  if CGameState and slua.isValid(CGameState) and CGameState.IsCreativeMode and CGameState:IsCreativeMode() then
    local Len = #self.allData
    self.allData[Len + 1] = cfg.WOWCoinRecharge
  else
    for id, _ in pairs(uiCdg) do
      if not self:CheckIsFamilyBlock(id) then
        if id == cfg.SmallRP then
          local special_offer_net_cfg = require("client.slua.logic.specialoffer.special_offer_net_cfg")
          special_offer_net_cfg.SendActNetByType(cfg.SmallRP)
          if Logic_SmallRPSpecialOfferAdapter.IsLegacyOpen() then
            AppendTab(id)
          end
          for _, nActivityId in ipairs(Logic_SmallRPSpecialOfferAdapter.GetOpenActivityIdList()) do
            AppendTab(id, nActivityId)
          end
        elseif not id2CheckShow[id] or id2CheckShow[id]() then
          AppendTab(id)
        end
      end
    end
  end
  self:SortData()
  self:AddTimerOnce(0, function()
    self.LoopScrollBox_Tab:SetData(self.allData)
    local lastId = self.nId
    local nLastSmallRPActivityId = self._nSmallRPActivityId
    local nLegacySmallRPIndex, nFirstSmallRPActivityIndex
    for nIndex, nId in ipairs(self.allData) do
      if nId == cfg.SmallRP then
        if self._tSmallRPActivityIdByIndex[nIndex] then
          nFirstSmallRPActivityIndex = nFirstSmallRPActivityIndex or nIndex
        else
          nLegacySmallRPIndex = nIndex
        end
      end
    end
    if self._nPendingSmallRPActivityId then
      for _, nActivityId in pairs(self._tSmallRPActivityIdByIndex) do
        if nActivityId == self._nPendingSmallRPActivityId then
          self.nId = cfg.SmallRP
          self._nSmallRPActivityId = nActivityId
          self._nSmallRPLegacyRoundId = nil
          self._nPendingSmallRPActivityId = nil
          self._bPendingSmallRPDefault = false
          break
        end
      end
    elseif self._bPendingSmallRPDefault then
      if nLegacySmallRPIndex then
        self.nId = cfg.SmallRP
        self._nSmallRPActivityId = nil
        self._nSmallRPLegacyRoundId = GetCurLegacySmallRPRoundId()
        self._bPendingSmallRPDefault = false
      else
        local nMaxSortId = -1
        local nTargetIndex
        for nIndex, nId in ipairs(self.allData) do
          if nId == cfg.SmallRP then
            local nActivityId = self._tSmallRPActivityIdByIndex[nIndex]
            local nSortId = Logic_SmallRPSpecialOfferAdapter.GetSortId(nActivityId)
            if nSortId and nMaxSortId < nSortId then
              nMaxSortId = nSortId
              nTargetIndex = nIndex
            end
          end
        end
        if nTargetIndex then
          self.nId = cfg.SmallRP
          self._nSmallRPActivityId = self._tSmallRPActivityIdByIndex[nTargetIndex]
          self._nSmallRPLegacyRoundId = nil
          self._bPendingSmallRPDefault = false
        elseif nFirstSmallRPActivityIndex then
          self.nId = cfg.SmallRP
          self._nSmallRPActivityId = self._tSmallRPActivityIdByIndex[nFirstSmallRPActivityIndex]
          self._nSmallRPLegacyRoundId = nil
          self._bPendingSmallRPDefault = false
        end
      end
    end
    if self.nId == cfg.SmallRP and self._nSmallRPActivityId and not Logic_SmallRPSpecialOfferAdapter.IsActivityOpen(self._nSmallRPActivityId) then
      local nTargetIndex = nLegacySmallRPIndex or nFirstSmallRPActivityIndex
      if nTargetIndex then
        self.nId = cfg.SmallRP
        self._nSmallRPActivityId = self._tSmallRPActivityIdByIndex[nTargetIndex]
        if self._nSmallRPActivityId then
        end
        self._nSmallRPLegacyRoundId = GetCurLegacySmallRPRoundId()
      end
    end
    if not self.nId then
      self.nId = self.allData[1]
      self._nSmallRPActivityId = self._tSmallRPActivityIdByIndex[1]
      if self._nSmallRPActivityId then
      end
      self._nSmallRPLegacyRoundId = GetCurLegacySmallRPRoundId()
    end
    self:SelectTab()
    self.LoopScrollBox_Tab:RefreshAllItems()
    self:ChangeToSubscribe()
    if not self.subUI or lastId ~= self.nId or nLastSmallRPActivityId ~= self._nSmallRPActivityId then
      self:ShowSubUI(lastId)
    end
  end)
end
function SpecialOffer_Main_UIBP:CheckIsFamilyBlock(id)
  local logic_familycenter = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_familycenter)
  local familycenter_macro = require("client.slua.logic.familycenter.familycenter_macro")
  local cached = logic_familycenter:GetCachedResult(familycenter_macro.ENUM_SCENE.TREASURE_CHEST)
  local isHidePanel = not cached or not cached.pass
  return isHidePanel and id ~= cfg.recharge and id ~= cfg.WOWCoinRecharge and id ~= cfg.subscribe
end
function SpecialOffer_Main_UIBP:NextDayReqActData()
  local store_supply_manager = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.store_supply_manager)
  store_supply_manager:GetTabData(StoreConst.store_tab, 61)
end
function SpecialOffer_Main_UIBP:IsHideSmallPayBtn()
  self.UIRoot.WidgetSwitcher_0:SetActiveWidgetIndex(1)
  local show = true
  do
    local AOSSHOPMacros = require("client.slua.config.ClientMacros.AOSSHOPMacros")
    if Client.GetAOSSHOP() == AOSSHOPMacros.Samsung or Client.GetAOSSHOP() == AOSSHOPMacros.Amazon then
      show = false
    else
      local RechargeSystem = require("client.logic.recharge.logic_recharge")
      if RechargeSystem.EnterFrom == RechargeSystem.E_UcEntryType.FromHomeStoreUC then
        show = false
      else
      end
    end
  end
  if CGameState and slua.isValid(CGameState) and CGameState.IsCreativeMode and CGameState:IsCreativeMode() then
    show = false
  end
  if show then
    self:SetWidgetVisible(self.UIRoot.Button_Jump, true, true)
  else
    self:SetWidgetVisible(self.UIRoot.Button_Jump, false)
  end
end
function SpecialOffer_Main_UIBP:ReqGiftData()
  local logic_special_offer_material = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_special_offer_material)
  local logic_special_offer_condition = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_special_offer_condition)
  logic_special_offer_condition:ReqLoginDaysInfo()
  if not logic_special_offer_material:CheckGiftData() or not logic_special_offer_condition:CheckGiftData() then
    logic_special_offer_material:GetMaterialGiftsDataReq()
  end
end
function SpecialOffer_Main_UIBP:ReqDailyData()
  local EveryDayPackHandler = require("client.network.Protocol.EveryDayPackHandler")
  local EverydayV2PackHandler = require("client.network.Protocol.EverydayV2PackHandler")
  EveryDayPackHandler.send_daily_direct_buy_get_cfg()
  EverydayV2PackHandler.send_daily_direct_buy_v2_get_cfg_req()
end
function SpecialOffer_Main_UIBP:ReqDiscountDirectData()
  local PublishRegionMacros = require("client.slua.config.ClientMacros.PublishRegionMacros")
  if not PublishRegionMacros.IsBlueholeFamily() then
    return
  end
  local Discount_Direct_Logic = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.Discount_Direct_Logic)
  if not Discount_Direct_Logic:HaveGiftsData() then
    Discount_Direct_Logic:GetDiscountDirectDataReq()
  end
end
function SpecialOffer_Main_UIBP:ReqTemuCfg()
  local Logic_temu = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.Logic_temu)
  Logic_temu:TryGetCfg()
end
function SpecialOffer_Main_UIBP:ReqSmallPaymentData()
  local Logic_SmallPayment = require("client.slua.logic.SmallPayment.Logic_SmallPayment")
  Logic_SmallPayment.RequestActivityData()
end
function SpecialOffer_Main_UIBP:SortData()
  local special_offer_module = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.special_offer_module)
  local serverData = special_offer_module:GetAllData()
  if not serverData then
    return
  end
  local PublishRegionMacros = require("client.slua.config.ClientMacros.PublishRegionMacros")
  local IsIndia = PublishRegionMacros.IsBlueholeFamily()
  local IsConditionGiftAllDone = false
  if IsIndia then
    IsConditionGiftAllDone = self:IsConditionGiftAllDone()
  end
  local tSortData = {}
  local tSortNotDownload = {}
  local isFit = PublishRegionMacros.IsFITVersion()
  for nIndex, nId in ipairs(self.allData) do
    local needHideRed = isFit and not self:CheckIsDownload(nId, self._tSmallRPActivityIdByIndex[nIndex])
    local data = {
      id = nId,
      activity_id = self._tSmallRPActivityIdByIndex[nIndex],
      original_index = nIndex,
      needHideRed = needHideRed
    }
    if not needHideRed then
      table.insert(tSortData, data)
    else
      table.insert(tSortNotDownload, data)
    end
    if nId == cfg.SmallRP then
      data.small_rp_sort_id = Logic_SmallRPSpecialOfferAdapter.GetSortId(data.activity_id)
    end
  end
  local id2ActID = cfg.id2ActId
  local GetServerSortData = function(tTabData)
    if tTabData.id == cfg.SmallRP then
      local nAllWeight = Logic_SmallRPSpecialOfferAdapter.GetGroupAllWeight(serverData)
      return nAllWeight and {allWeight = nAllWeight} or nil
    end
    local tData = serverData[tTabData.id]
    if not tData then
      local nActId = id2ActID[tTabData.id]
      tData = nActId and serverData[nActId]
    end
    return tData
  end
  local SortFunc = function(a, b)
    local nIdA, nIdB = a.id, b.id
    if nIdA == cfg.NewGroupBuy and nIdB ~= cfg.NewGroupBuy then
      return true
    elseif nIdA ~= cfg.NewGroupBuy and nIdB == cfg.NewGroupBuy then
      return false
    end
    if IsConditionGiftAllDone then
      if nIdA == cfg.ConditionsGift and nIdB ~= cfg.ConditionsGift then
        return false
      elseif nIdA ~= cfg.ConditionsGift and nIdB == cfg.ConditionsGift then
        return true
      end
    end
    if nIdA == cfg.SmallRP and nIdB == cfg.SmallRP then
      if a.small_rp_sort_id ~= b.small_rp_sort_id then
        return a.small_rp_sort_id < b.small_rp_sort_id
      end
      return a.original_index < b.original_index
    end
    local varA, varB = GetServerSortData(a), GetServerSortData(b)
    if not varA or not varB then
      if varA and not varB then
        return true
      elseif not varA and varB then
        return false
      end
      local bSmallRPA, bSmallRPB = nIdA == cfg.SmallRP, nIdB == cfg.SmallRP
      if bSmallRPA ~= bSmallRPB then
        return not bSmallRPA
      end
      if nIdA ~= nIdB then
        return nIdA < nIdB
      end
      return a.original_index < b.original_index
    end
    if varA.allWeight == varB.allWeight then
      if nIdA == nIdB then
        return a.original_index < b.original_index
      end
      local nStableIdA, nStableIdB
      if PublishRegionMacros.IsBlueholeFamily() then
        nStableIdA, nStableIdB = id2ResIdByIn[nIdA], id2ResIdByIn[nIdB]
      else
        nStableIdA, nStableIdB = id2ResId[nIdA], id2ResId[nIdB]
      end
      nStableIdA, nStableIdB = nStableIdA or 0, nStableIdB or 0
      if nStableIdA ~= nStableIdB then
        return nStableIdA < nStableIdB
      end
      return nIdA < nIdB
    end
    return varA.allWeight > varB.allWeight
  end
  table.sort(tSortData, SortFunc)
  table.sort(tSortNotDownload, SortFunc)
  self.allData = {}
  self._isLightRedHide = {}
  self._tSmallRPActivityIdByIndex = {}
  if tSortNotDownload and next(tSortNotDownload) then
    for i, v in ipairs(tSortNotDownload) do
      table.insert(tSortData, v)
    end
  end
  for nIndex, tTabData in ipairs(tSortData) do
    self.allData[nIndex] = tTabData.id
    self._tSmallRPActivityIdByIndex[nIndex] = tTabData.activity_id
    self._isLightRedHide[nIndex] = tTabData.needHideRed
  end
end
function SpecialOffer_Main_UIBP:IsConditionGiftAllDone()
  local logic_special_offer_condition = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_special_offer_condition)
  if not logic_special_offer_condition:CheckGiftData() then
    return false
  end
  local tAllPackageData = logic_special_offer_condition:GetGiftsData()
  if not tAllPackageData or not next(tAllPackageData) then
    return false
  end
  for _, packageData in pairs(tAllPackageData) do
    for _, giftData in pairs(packageData) do
      if giftData.limitNum > 0 then
        return false
      end
    end
  end
  return true
end
function SpecialOffer_Main_UIBP:SelectTab()
  if not self.allData then
    log_error(bWriteLog and "SpecialOffer_Main_UIBP:SelectTab allData is nil  ")
    return
  end
  if self.nId == cfg.golden then
    local logic_familycenter = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_familycenter)
    if logic_familycenter then
      local familycenter_macro = require("client.slua.logic.familycenter.familycenter_macro")
      local cached = logic_familycenter:GetCachedResult(familycenter_macro.ENUM_SCENE.TREASURE_CHEST)
      if not cached or not cached.pass then
        for i, v in ipairs(self.allData) do
          if v ~= cfg.golden then
            self.nId = v
            break
          end
        end
      end
    end
  end
  local nSmallRPFallbackIndex
  for i, v in ipairs(self.allData) do
    local nActivityId = self._tSmallRPActivityIdByIndex[i]
    if v == self.nId and (v ~= cfg.SmallRP or nActivityId == self._nSmallRPActivityId) then
      self.LoopScrollBox_Tab:Select(i)
      self.LoopScrollBox_Tab:ScrollToCenter(i)
      return
    elseif v == cfg.SmallRP and self.nId == cfg.SmallRP and nActivityId and not nSmallRPFallbackIndex then
      nSmallRPFallbackIndex = i
    end
  end
  if nSmallRPFallbackIndex then
    self._nSmallRPActivityId = self._tSmallRPActivityIdByIndex[nSmallRPFallbackIndex]
    self.LoopScrollBox_Tab:Select(nSmallRPFallbackIndex)
    self.LoopScrollBox_Tab:ScrollToCenter(nSmallRPFallbackIndex)
  end
end
function SpecialOffer_Main_UIBP:OnRefreshItem(widget, index)
  local id = self.LoopScrollBox_Tab:GetItemData(index)
  local nSmallRPActivityId = id == cfg.SmallRP and self._tSmallRPActivityIdByIndex[index] or nil
  local resId = id2ResId[id]
  local bSelected = self.LoopScrollBox_Tab:GetSelectIndex() == index
  resId = nSmallRPActivityId and Logic_SmallRPSpecialOfferAdapter.GetTitle(nSmallRPActivityId) or resId
  if type(resId) == "number" then
    resId = LocUtil.GetLocalizeResStr(resId)
  end
  widget.TextBlock_Name:SetText(resId)
  widget.TextBlock_NameSel:SetText(resId)
  local bUseDarkTabBlock = self:IsUseDarkSkin()
  local unselectedTitleColor = bUseDarkTabBlock and self.whiteColor or self.unSelectColor
  local selectedTitleColor = bUseDarkTabBlock and self.unSelectColor or self.whiteColor
  widget.TextBlock_Name:SetColorAndOpacity(FSlateColor(unselectedTitleColor))
  widget.TextBlock_NameSel:SetColorAndOpacity(FSlateColor(selectedTitleColor))
  local special_offer_module = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.special_offer_module)
  local markType, time
  if self._isLightRedHide and self._isLightRedHide[index] then
  elseif nSmallRPActivityId then
    markType, time = Logic_SmallRPSpecialOfferAdapter.GetMark(nSmallRPActivityId)
  elseif id == cfg.SmallRP then
    markType, time = Logic_SmallRPSpecialOfferAdapter.GetLegacyMark()
  else
    markType, time = special_offer_module:Id2MarkType(id)
  end
  if nSmallRPActivityId or self._tSmallRPActivityWidgetMap[widget] then
    if self.TabCountDownTimerMap[widget] then
      self:RemoveTimer(self.TabCountDownTimerMap[widget])
      self.TabCountDownTimerMap[widget] = nil
    end
    self:SetWidgetVisible(widget.CanvasPanel_Day, false)
  end
  self._tSmallRPActivityWidgetMap[widget] = nSmallRPActivityId and true or nil
  self:SetWidgetVisible(widget.WidgetSwitcher_0, markType)
  if CGameState and slua.isValid(CGameState) and CGameState.IsCreativeMode and CGameState:IsCreativeMode() then
    self:SetWidgetVisible(widget.WidgetSwitcher_0, false)
  end
  if markType then
    log_warning(bWriteLog and "  :SpecialOffer_Main_UIBP markType: " .. tostring(markType))
    widget.WidgetSwitcher_0:SetActiveWidgetIndex(markType)
  end
  self.MarkTypes[index] = markType or -1
  if not markType and time then
    self:SetWidgetVisible(widget.CanvasPanel_Day, true)
    local TimeUtil = require("client.common.time_util")
    log(bWriteLog and "  :SpecialOffer_Main_UIBP real time: " .. tostring(time))
    local leftTime = time - TimeUtil.GetServerTimeInSec()
    local sTimeStr = TimeUtil.FormatCountDownTime_DH_or_HMS_or_MS(leftTime, true)
    widget.TextBlock_Day:SetText(sTimeStr)
    local timeColor = bSelected and selectedTitleColor or unselectedTitleColor
    widget.TextBlock_Day:SetColorAndOpacity(FSlateColor(timeColor))
    widget.Image_Day:SetColorAndOpacity(timeColor)
    if not self.TabCountDownTimerMap[widget] then
      do
        local timer = self:AddTimerLoop(0, function()
          leftTime = time - TimeUtil.GetServerTimeInSec()
          if leftTime <= 0 then
            self:SetWidgetVisible(widget.CanvasPanel_Day, false)
            if self.TabCountDownTimerMap[widget] then
              self:RemoveTimer(self.TabCountDownTimerMap[widget])
              self.TabCountDownTimerMap[widget] = nil
            end
            return
          end
          sTimeStr = TimeUtil.FormatCountDownTime_DH_or_HMS_or_MS(leftTime, true)
          widget.TextBlock_Day:SetText(sTimeStr)
        end, TIMER_INFINITE, 1)
        self.TabCountDownTimerMap[widget] = timer
      end
    end
  else
    self:SetWidgetVisible(widget.CanvasPanel_Day, false)
    if self.TabCountDownTimerMap[widget] then
      local timer = self.TabCountDownTimerMap[widget]
      self:RemoveTimer(timer)
      self.TabCountDownTimerMap[widget] = nil
    end
  end
  widget.tabLv1:SetActiveWidgetIndex(bSelected and 1 or 0)
  local sSelectedTabBgPath = id == cfg.SmallRP and sSmallRPSelectedTabBgPath or sDefaultSelectedTabBgPath
  self:SetTexture(widget.image_6, sSelectedTabBgPath, {sync = true, bMatchSize = false})
  self:SetWidgetVisible(widget.image_6, bSelected, false)
  local _ = bSelected and self:PlayWidgetAnimation(widget, widget.Anim_Select, 0, 1, 0, 1)
  self:RefreshLogoIcon(widget, id)
  if widget.CanvasPanel_Download then
    self:SetWidgetVisible(widget.CanvasPanel_Download, id == cfg.golden)
  end
end
function SpecialOffer_Main_UIBP:RefreshLogoIcon(node_tabItem, nSpecialOfferId)
  local Logic_SpecialOfferLogoCfg = require("client.slua.logic.specialoffer.Logic_SpecialOfferLogoCfg")
  local sLogoPath = Logic_SpecialOfferLogoCfg.GetLogoShowBySpecialOfferType(nSpecialOfferId)
  local bIsShow = false
  if sLogoPath and sLogoPath ~= "" then
    bIsShow = true
    local image_download_config = require("client.slua.logic.image_download.image_download_config")
    local tParams = {
      diskCacheType = image_download_config.EnumDiskCacheType.VersionUpdate
    }
    self:SetTexture(node_tabItem.Image_Logo, sLogoPath, tParams)
  end
  self:SetWidgetVisible(node_tabItem.CanvasPanel_Logo, bIsShow)
end
function SpecialOffer_Main_UIBP:OnClickItem(_, index)
  self:PlayAudio(sound_config.click_v1)
  local id = self.LoopScrollBox_Tab:GetItemData(index)
  if id == cfg.golden then
    local logic_familycenter = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_familycenter)
    if logic_familycenter then
      local familycenter_macro = require("client.slua.logic.familycenter.familycenter_macro")
      local handled = logic_familycenter:RunWithCompliance(familycenter_macro.ENUM_SCENE.TREASURE_CHEST, {
        onPass = function()
          self:_DoOnClickItem(index)
        end
      })
      if handled then
        return
      end
    end
  end
  self:_DoOnClickItem(index)
end
function SpecialOffer_Main_UIBP:_DoOnClickItem(index)
  local UIUtil = require("client.common.ui_util")
  if not UIUtil.CanClickNow(UIUtil.ClickFrequencyLimit.ActivityTab) then
    return
  end
  local select = self.LoopScrollBox_Tab:GetSelectIndex()
  if select == index then
    log(bWriteLog and "  : same index")
    return
  end
  local id = self.LoopScrollBox_Tab:GetItemData(index)
  local nSmallRPActivityId = id == cfg.SmallRP and self._tSmallRPActivityIdByIndex[index] or nil
  local lastId = self.nId
  self.nId = id
  self._nSmallRPActivityId = nSmallRPActivityId
  self._nSmallRPLegacyRoundId = not (id ~= cfg.SmallRP or nSmallRPActivityId) and GetCurLegacySmallRPRoundId() or nil
  self._bPendingSmallRPDefault = false
  log(bWriteLog and "  :OnClickItem index: " .. tostring(index))
  log(bWriteLog and "  :OnClickItem self.nId: " .. tostring(self.nId))
  if id == cfg.NewGroupBuy then
    if not self.urlParam then
      self.urlParam = {}
    end
    if not self.urlParam.source and tonumber(self.urlParam.internal) ~= 1 then
      self.urlParam.source = cfg.BargainEntrySource and cfg.BargainEntrySource.Tehui or 1
    end
  end
  self.LoopScrollBox_Tab:Select(index)
  self.LoopScrollBox_Tab:RefreshAllItems()
  self.LoopScrollBox_Tab:ScrollToCenter(index)
  if not self.nId then
    return
  end
  self:ShowSubUI(lastId)
  local tlog_report_utils = require("client.slua.config.tlog.tlog_report_utils")
  tlog_report_utils.ReportTLogEvent(TLogEventDefine.SpecialOfferItem, self.nId)
  local logic_return_tlog_report = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_return_tlog_report)
  logic_return_tlog_report:ReportReturnTLogEvent(TLogEventDefine.SpecialOfferItem, self.nId)
end
function SpecialOffer_Main_UIBP:ShowDownloadFullLobbyTip()
  local LogicFitVersionDownload = require("client.slua.logic.download.fit.logic_fitVersion_download")
  if not LogicFitVersionDownload.IsFitLobbyResDownloaded() then
    LogicFitVersionDownload.ShowFullLobbyResDownloadPopup()
    return
  end
end
function SpecialOffer_Main_UIBP:OnClickBtnMoreDownload()
  self:PlayAudio(sound_config.click_v1)
  self:ShowDownloadFullLobbyTip()
end
function SpecialOffer_Main_UIBP:GetDataForJumpBack()
  local tUrlParam
  if self.nId == cfg.SmallRP then
    if self._nSmallRPActivityId then
      tUrlParam = {
        activity_id = self._nSmallRPActivityId,
        round = self._nSmallRPActivityId
      }
    else
      local nLegacyRoundId = self._nSmallRPLegacyRoundId or GetCurLegacySmallRPRoundId()
      if nLegacyRoundId then
        tUrlParam = {round = nLegacyRoundId}
      end
    end
  end
  return {
    ctorData = {
      self.nId,
      tUrlParam
    }
  }
end
function SpecialOffer_Main_UIBP:OnClickBtnClose()
  self:PlayAudio(sound_config.close_v1)
  self:CloseSelf()
end
function SpecialOffer_Main_UIBP:CreateSmallPaymentDownloadUI()
  local PufferConst = require("client.slua.logic.download.puffer_const")
  local common_download_handler = require("client.slua.common.common_download_handler")
  common_download_handler.CreateDownloadUIReturnUIBase(PufferConst.ENUM_DownloadType.ODPAK, {
    UIManager.UI_Config.SmallPayment_Task_UIBP.path
  }, self, self.UIRoot.CanvasPanel_SmallPayDownload)
end
function SpecialOffer_Main_UIBP:OnClickBtnExchange()
  self:PlayAudio(sound_config.click)
  local Logic_SmallPayment = require("client.slua.logic.SmallPayment.Logic_SmallPayment")
  local exAtcId = Logic_SmallPayment.GetExchangeActId()
  if exAtcId == 0 then
    log_error("exchange activity id configuration error .")
    ShowNotice(4002)
    Logic_SmallPayment.RequestActivityData()
    return
  end
  local tlog_report_utils = require("client.slua.config.tlog.tlog_report_utils")
  tlog_report_utils.ReportTLogEvent(TLogEventDefine.SpecialOfferExchange, 0)
  local logic_return_tlog_report = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_return_tlog_report)
  logic_return_tlog_report:ReportReturnTLogEvent(TLogEventDefine.SpecialOfferExchange, 0)
  local LuckybackActivitySystem = require("client.slua.logic.lobby_activity.logic_luckyback_activity")
  LuckybackActivitySystem.OpenExchangeStoreExternal(true, exAtcId, nil, nil, 33)
  local tlog_commercial_player_behavior = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.tlog_commercial_player_behavior)
  local extra_data = {activity_id = exAtcId}
  tlog_commercial_player_behavior:ReportJumpToExchange(tlog_commercial_player_behavior.Enum_Scene.SpecialOffer, extra_data)
end
function SpecialOffer_Main_UIBP:OnClickMore()
  local LogicFitVersionDownload = require("client.slua.logic.download.fit.logic_fitVersion_download")
  self:PlayAudio(sound_config.click_v1)
  if not LogicFitVersionDownload.IsFitLobbyResDownloaded() then
    LogicFitVersionDownload.ShowFullLobbyResDownloadPopup()
  end
end
function SpecialOffer_Main_UIBP:OnClickBtnHelp()
  self:PlayAudio(sound_config.click_v1)
  local title = LocUtil.GetLocalizeResStr(62944)
  local content = LocUtil.GetLocalizeResStr(62945)
  UIManager.ShowUI(UIManager.UI_Config.HelpTip, 0, title, content)
end
function SpecialOffer_Main_UIBP:HideClickBlock()
  if self.UIRoot.ClickBlock then
    self:SetWidgetVisible(self.UIRoot.ClickBlock, not hideClickBolck[self.nId], true)
    log(bWriteLog and " hideClickBolck[self.nId]: " .. tostring(self.nId) .. ":" .. tostring(hideClickBolck[self.nId]))
  end
end
function SpecialOffer_Main_UIBP:ShowSubUI(lastId)
  log(bWriteLog and "  : SpecialOffer_Main_UIBP:ShowSubUI" .. tostring(lastId))
  if not self.UIRoot then
    return
  end
  if self.subUI then
    self.subUI:CloseSelf()
  end
  if cfg.MoreTab and self.nId == cfg.MoreTab then
    self:ShowTab(true)
    return
  end
  self:ShowTab(true)
  self:HideClickBlock()
  self:AddTimerOnce(0, function()
    self:UpdateCoins()
  end)
  local uiKey = uiCdg[tonumber(self.nId)]
  log(bWriteLog and "  : self.nActId: " .. tostring(self.nId))
  log(bWriteLog and "  : uiKey: " .. tostring(uiKey))
  self:ShowTabPanelUI()
end
function SpecialOffer_Main_UIBP:ShowDownloadUI(tDownloadCfg, nSmallRPActivityId)
  local cObj_downloadUI = self._cObj_downloadUI
  if not cObj_downloadUI then
    self._cObj_downloadUI = self:CreateChildWindow(self.UIRoot.CanvasPanel_DownloadUI, UIManager.UI_Config.SpecialOffer_DownloadTip_UIBP, tDownloadCfg, nSmallRPActivityId)
  else
    self._cObj_downloadUI:RefreshShow(tDownloadCfg, nSmallRPActivityId)
  end
end
function SpecialOffer_Main_UIBP:ShowTabPanelUI()
  if self:TryDownload(self.nId) then
    return
  end
  log(bWriteLog and "[SY]SpecialOffer_Main_UIBP:ShowTabPanelUI.")
  local nId = self.nId
  local nCurIndex = self.LoopScrollBox_Tab:GetSelectIndex()
  local markTp = self.MarkTypes[nCurIndex]
  if markTp and 0 < markTp then
    local special_offer_module = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.special_offer_module)
    if nId ~= cfg.SmallRP or not self._nSmallRPActivityId then
      special_offer_module:RemoveAllTypeRed(nId)
    end
    self.LoopScrollBox_Tab:RefreshItem(self.LoopScrollBox_Tab:GetSelectIndex())
  end
  local params
  if nId == cfg.SmallRP and self._nSmallRPActivityId then
    params = Logic_SmallRPSpecialOfferAdapter.CreateUIContext(self._nSmallRPActivityId)
  elseif nId ~= cfg.golden then
    params = nId
  end
  local uiKey = uiCdg[tonumber(nId)]
  self.uiConfig = UIManager.UI_Config[uiKey]
  if not self.uiConfig then
    log_error("SpecialOffer_Main_UIBP:ShowTabPanelUI uiConfig is nil uiKey:" .. tostring(uiKey))
    return
  end
  log(bWriteLog and "[SY]SpecialOffer_Main_UIBP:ShowTabPanelUI.uiKey: " .. tostring(uiKey) .. "")
  self.subUI = self:CreateChildWindow(self.UIRoot.CanvasPanel_Root, UIManager.UI_Config[uiKey], params, self.urlParam)
  self.urlParam = nil
  local func = id2Func[nId]
  if func then
    local actId = cfg.id2ActId[nId] or nId
    func(actId)
  end
  local bShow
  if uiKey == "ui_recharge" then
    bShow = true
  end
  local RechargeSystem = require("client.logic.recharge.logic_recharge")
  RechargeSystem.UpdateChargeUIShowingState(bShow)
  self.UIRoot.WidgetSwitcher_RootShow:SetActiveWidgetIndex(0)
  self:ShowCoin()
end
function SpecialOffer_Main_UIBP:OnTabUIShow(_, _, config)
  if self.uiConfig and config and self.uiConfig == config then
    self.uiConfig = nil
    if waitShow[self.nId] then
      return
    end
  end
end
function SpecialOffer_Main_UIBP:ShowCoin()
  self:SetWidgetVisible(self.UIRoot.WrapBox_Coin, true)
end
function SpecialOffer_Main_UIBP:HideCoin()
  self:SetWidgetVisible(self.UIRoot.WrapBox_Coin, false)
end
function SpecialOffer_Main_UIBP:OnTabFinished()
end
function SpecialOffer_Main_UIBP:UpdateCoins()
  if next(self.coinUIs) then
    for _, ui in pairs(self.coinUIs) do
      ui:Close()
    end
  end
  self.coinUIs = {}
  local Logic_SpecialCoinUtils = require("client.slua.logic.specialoffer.Logic_SpecialCoinUtils")
  local tCoinContext = self.nId == cfg.SmallRP and self._nSmallRPActivityId and {
    activity_id = self._nSmallRPActivityId
  } or nil
  local tCoinsData = Logic_SpecialCoinUtils.GetSpecialOfferCoinsData(self.nId, tCoinContext)
  for i, tCoinData in ipairs(tCoinsData) do
    local nItemId = tCoinData.nItemId
    local tExtraData = tCoinData.tExtraData
    if nItemId and 0 < nItemId then
      local cObj_ui = self:CreateChildWindow(self.UIRoot.WrapBox_Coin, UIManager.UI_Config.SpecialOffer_Coin_Item_UIBP, nItemId, tExtraData)
      self.coinUIs[i] = cObj_ui
    end
  end
  self:RefreshTopSkin()
end
function SpecialOffer_Main_UIBP:IsUseDarkSkin()
  return IsLegacySmallRPRound17(self.nId, self._nSmallRPActivityId, self._nSmallRPLegacyRoundId) or IsSmallRPActivityDarkSkin(self.nId, self._nSmallRPActivityId)
end
function SpecialOffer_Main_UIBP:RefreshTopSkin()
  local bUseDarkSkin = self:IsUseDarkSkin()
  local tTextColor = bUseDarkSkin and self.whiteTextColor or self.unSelectColor
  local questionTint = bUseDarkSkin and self.halfWhiteColor or self.defaultIconTint
  local root = self.UIRoot
  if slua.isValid(root.TextBlock_0) then
    root.TextBlock_0:SetColorAndOpacity(FSlateColor(tTextColor))
  end
  for _, cObj_coin in pairs(self.coinUIs) do
    if cObj_coin and cObj_coin.SetContentColor then
      cObj_coin:SetContentColor(tTextColor)
    end
  end
  self:SetImageBrushTint(root.Image_1, questionTint)
  if slua.isValid(root.Image_5) then
    self:SetTexture(root.Image_5, bUseDarkSkin and sDarkSkinClosedIconPath or sClosedIconPath, {sync = true, bMatchSize = false})
  end
  return bUseDarkSkin
end
function SpecialOffer_Main_UIBP:SetImageBrushTint(image, tint)
  if not slua.isValid(image) then
    return
  end
  local brush = slua.IndexReference(image, "Brush")
  if not brush then
    return
  end
  brush = brush:clone()
  brush.TintColor = FSlateColor(tint)
  image:SetBrush(brush)
end
function SpecialOffer_Main_UIBP:ShowTab(show, withAnim, speed)
  local root = self.UIRoot
  local bUseDarkTabBlock = self:RefreshTopSkin()
  self:SetWidgetVisible(root.Top, not show, true)
  self:SetWidgetVisible(root.Image_right, not show, true)
  self:SetWidgetVisible(root.Image_TabBlock, show and not bUseDarkTabBlock)
  self:SetWidgetVisible(root.Image_TabBlockDark, show and bUseDarkTabBlock)
  if withAnim and not show then
    self:AddTimerOnce(1, function()
      self:SetWidgetVisible(root.Image_right, true, true)
    end)
  end
  speed = speed or 1
  if withAnim then
    self:SetWidgetVisible(root.CanvasPanel_All, true)
    log_warning(bWriteLog and "  : withAnim")
    if show then
      self:PlayUserWidgetAnimation(self.UIRoot.Fadein, 0, 1, 0, speed)
    else
      self:PlayUserWidgetAnimation(self.UIRoot.Fadein, 0, 1, 1, speed)
    end
  else
    self:SetWidgetVisible(root.CanvasPanel_All, show)
  end
end
function SpecialOffer_Main_UIBP:OnClickFullScreen(_, _, isFullScreen, _)
  log_warning(bWriteLog and "  : isFullScreen: " .. tostring(isFullScreen))
  self:ShowTab(not isFullScreen)
end
function SpecialOffer_Main_UIBP:EventShowTab(_, _, ...)
  self:ShowTab(true, ...)
end
function SpecialOffer_Main_UIBP:EventHideTab(_, _, ...)
  self:ShowTab(false, ...)
end
function SpecialOffer_Main_UIBP:SetMask(_, _, isShow)
  self:SetWidgetVisible(self.UIRoot.ScaleBox_BG, isShow, false)
end
function SpecialOffer_Main_UIBP:EventShowBorder()
  local logic_scrapgold_draw = require("client.slua.logic.lobby_activity.logic_scrapgold_draw")
  if logic_scrapgold_draw.GetIsShowAnimation() == false and logic_scrapgold_draw.GetDrawAgain() then
    return
  end
  self:ShowTab(false, true)
end
function SpecialOffer_Main_UIBP:EventRefreshTab(_, _, id, nActivityId)
  log_warning(bWriteLog and "  :SpecialOffer_Main_UIBP:EventRefreshTab id: " .. tostring(id))
  local cfg_local = cfg
  if id == cfg_local.NewGroupBuy then
    self.nId = cfg_local.NewGroupBuy
    self:UpdateUI()
  else
    self:RefreshOneTab(id, nActivityId)
  end
end
function SpecialOffer_Main_UIBP:RefreshOneTab(id, nActivityId)
  nActivityId = tonumber(nActivityId)
  for i, oneId in ipairs(self.allData) do
    local nTabActivityId = self._tSmallRPActivityIdByIndex[i]
    local bIsTarget = oneId == id
    if id == cfg.SmallRP then
      bIsTarget = bIsTarget and nTabActivityId == nActivityId
    end
    if bIsTarget then
      self.LoopScrollBox_Tab:RefreshItem(i)
      break
    end
  end
end
function SpecialOffer_Main_UIBP:EventActivityChange()
  self:UpdateUI()
end
function SpecialOffer_Main_UIBP:IsUc()
  if self.nId == cfg.recharge then
    return true
  elseif cfg.recharge_purchase and cfg.recharge_purchase == self.nId then
    return true
  end
  return false
end
function SpecialOffer_Main_UIBP:GetCurrencyObjByItemId(nItemId)
  local nIndex
  local Logic_SpecialCoinUtils = require("client.slua.logic.specialoffer.Logic_SpecialCoinUtils")
  local tCoinContext = self.nId == cfg.SmallRP and self._nSmallRPActivityId and {
    activity_id = self._nSmallRPActivityId
  } or nil
  local tCoinsData = Logic_SpecialCoinUtils.GetSpecialOfferCoinsData(self.nId, tCoinContext)
  for i, aData in ipairs(tCoinsData) do
    local nCurrencyId = aData.nItemId
    if nCurrencyId == nItemId then
      nIndex = i
      break
    end
  end
  if not nIndex then
    return
  end
  return self.coinUIs[nIndex]
end
function SpecialOffer_Main_UIBP:CheckIsDownload(nId, nSmallRPActivityId)
  local special_offer_module = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.special_offer_module)
  return special_offer_module:CheckIsDownload(nId, nSmallRPActivityId)
end
function SpecialOffer_Main_UIBP:TryDownload(nId)
  local special_offer_download_cfg = require("client.slua.logic.specialoffer.special_offer_download_cfg")
  local tDownloadCfg = special_offer_download_cfg.GetDownloadCfgById(nId)
  if tDownloadCfg then
    local tDownloadContext = GetSmallRPDownloadContext(nId, self._nSmallRPActivityId)
    local tDownloadResList = tDownloadCfg.fGetDownloadResList(tDownloadContext) or {}
    local PufferManager = require("client.slua.logic.download.puffer.puffer_manager")
    local PufferConst = require("client.slua.logic.download.puffer_const")
    local nStatus = PufferManager.GetState(PufferConst.ENUM_DownloadType.ODPAK, tDownloadResList)
    if nStatus ~= PufferConst.ENUM_DownloadState.Done then
      self:ShowDownloadUI(tDownloadCfg, self._nSmallRPActivityId)
      self.UIRoot.WidgetSwitcher_RootShow:SetActiveWidgetIndex(1)
      local LogicFitVersionDownload = require("client.slua.logic.download.fit.logic_fitVersion_download")
      if LogicFitVersionDownload:CheckIsUseFitVersionDownloadRule() then
        self:HideCoin()
      end
      return true
    end
  end
  return false
end
function SpecialOffer_Main_UIBP:OnDownloadComplete()
  log(bWriteLog and "[SY]SpecialOffer_Main_UIBP:OnDownloadComplete.")
  self:UpdateUI()
  self:ShowTabPanelUI()
  self:UpdateCoins()
end
local class = require("class")
local ui_base = require("client.slua_ui_framework.base")
local CSpecialOffer_Main_UIBP = class(ui_base, nil, SpecialOffer_Main_UIBP)
return CSpecialOffer_Main_UIBP
