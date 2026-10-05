local DetailBuy = {}
local Trait = require("common.trait")
local TDetailBuy = Trait(Trait.TraitPrototype, nil, DetailBuy)
function DetailBuy:BindDetailBuyEvent()
  self:AddCommonEvent(EVENTTYPE_STORE_BTNEVENT, EVENTID_THEMESHOP_ENTERFULLSCREEN, self.OnFullScreenPreview, self)
end
function DetailBuy:OnFullScreenPreview(_, _, bIsFullScreen)
  if bIsFullScreen then
    self:SetWidgetVisible(self.UIRoot.CanvasPanel_Store_Buy, false)
  else
    self:SetWidgetVisible(self.UIRoot.CanvasPanel_Store_Buy, true)
  end
end
function DetailBuy:UpdateBuyBtn(itemData, directPurchaseList, isGave, isShowCoupon, clickEvent, instance)
  self:_CallByPromise(function()
    if not self.storeButButton then
      self.storeButButton = self:CreateBuyBtn()
    end
    self.storeButButton:UpdateBuyBtn(itemData, directPurchaseList, isGave, isShowCoupon, clickEvent, instance)
  end)
end
function DetailBuy:UpdateExchangeBuyBtn(tItemData, fBuyCallback, cObj_mainPanel)
  self:_CallByPromise(function()
    if not self.storeButButton then
      self.storeButButton = self:CreateBuyBtn()
    end
    self.storeButButton:UpdateExchangeBuyBtn(tItemData, fBuyCallback, cObj_mainPanel)
  end)
end
function DetailBuy:UpdateCustomBuyBtn(tItemData, descId, fBuyCallback, cObj_mainPanel)
  self:_CallByPromise(function()
    if not self.storeButButton then
      self.storeButButton = self:CreateBuyBtn()
    end
    self.storeButButton:UpdateCustomBuyBtn(tItemData, descId, fBuyCallback, cObj_mainPanel)
  end)
end
function DetailBuy:UpdateCarExchangeBtn(tItemData, fBuyCallback, cObj_mainPanel)
  log(bWriteLog and "[SY]DetailBuy:UpdateCarExchangeBtn.")
  self:_CallByPromise(function()
    if not self.storeButButton then
      self.storeButButton = self:CreateBuyBtn()
    end
    self.storeButButton:UpdateCarExchangeBtn(tItemData, fBuyCallback, cObj_mainPanel)
  end)
end
function DetailBuy:UpdateItemData(itemData)
  self:_CallByPromise(function()
    if not self.storeButButton then
      self.storeButButton = self:CreateBuyBtn()
    end
    self.storeButButton:SetItemData(itemData)
  end)
end
function DetailBuy:UpdateCollectBtnById(itemId, bNegateCollected, sourceType)
  self:_CallByPromise(function()
    if not self.storeButButton then
      self.storeButButton = self:CreateBuyBtn()
    end
    local store_collect_data = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.store_collect_data)
    local bCollected = store_collect_data:IsCollectedByItemID(itemId)
    local collectItemData = {
      itemId = itemId,
      collected = bNegateCollected and not bCollected or bCollected
    }
    self:UpdateItemData(collectItemData)
    self.storeButButton:UpdateCollectBtn(collectItemData, nil, {sourceType = sourceType})
  end)
end
function DetailBuy:UpdateCollectBtn(itemData, isGive, extraData)
  self:_CallByPromise(function()
    if not self.storeButButton then
      self.storeButButton = self:CreateBuyBtn()
    end
    self.storeButButton:UpdateCollectBtn(itemData, isGive, extraData)
  end)
end
function DetailBuy:UpdateCollectBtnOnly(itemId, bNegateCollected, sourceType, bOnlyShowCollect)
  self:_CallByPromise(function()
    if not self.storeButButton and itemId then
      self.storeButButton = self:CreateBuyBtn()
    end
    if bOnlyShowCollect == nil then
      bOnlyShowCollect = true
    end
    if itemId then
      local store_collect_data = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.store_collect_data)
      local bCollected = store_collect_data:IsCollectedByItemID(itemId)
      local collectItemData = {
        itemId = itemId,
        collected = bNegateCollected and not bCollected or bCollected
      }
      self:UpdateItemData(collectItemData)
      self.storeButButton:UpdateCollectBtn(collectItemData, nil, {sourceType = sourceType, bOnlyShowCollect = bOnlyShowCollect})
    elseif self.storeButButton then
      self:UpdateItemData()
      self.storeButButton:HideCollectBtnOnly()
    end
  end)
end
function DetailBuy:SetCollectBtnPadding()
  if self.storeButButton then
    self.storeButButton:SetCollectBtnPadding()
  end
end
function DetailBuy:HideBuyBtnOnly()
  if self.storeButButton then
    self.storeButButton:HideBuyBtnOnly()
  end
end
function DetailBuy:UpdateLimitedSubscribeBtn(itemData, isGive)
  self:_CallByPromise(function()
    if not self.storeButButton then
      self.storeButButton = self:CreateBuyBtn()
    end
    self.storeButButton:UpdateLimitedSubscribeBtn(itemData, isGive)
  end)
end
function DetailBuy:SetBuyBtnByRecommend(sourceType, jumpEvent, instance)
  self:_CallByPromise(function()
    if not self.storeButButton then
      self.storeButButton = self:CreateBuyBtn()
    end
    self.storeButButton:UpdateBuyBtnByRecommend(sourceType, jumpEvent, instance)
  end)
end
function DetailBuy:UpdateBuyBtnByDirect(directData, buyEvent, instance)
  self:_CallByPromise(function()
    if not self.storeButButton then
      self.storeButButton = self:CreateBuyBtn()
    end
    self.storeButButton:UpdateBuyBtnByDirect(directData, buyEvent, instance)
  end)
end
function DetailBuy:UpdateGiftBtn(itemData, giveEvent, isGive)
  self:_CallByPromise(function()
    if not self.storeButButton then
      self.storeButButton = self:CreateBuyBtn()
    end
    self.storeButButton:UpdateGiftBtn(itemData, giveEvent, isGive)
  end)
end
function DetailBuy:SetInstallStyleButton(isInstall, event, instance)
  self:_CallByPromise(function()
    if not self.storeButButton then
      self.storeButButton = self:CreateBuyBtn()
    end
    self.storeButButton:UpdateInstallStyleButton(isInstall, event, instance)
  end)
end
function DetailBuy:CreateBuyBtn()
  local ui = self:CreateChildWindow("CanvasPanel_Store_Buy", UIManager.UI_Config.BuyButtonComponent)
  ui:SetAutoSize(true)
  return ui
end
function DetailBuy:HideAllBtnComponent()
  if not self.storeButButton then
    return
  end
  self.storeButButton:HideAllBtnComponent()
end
return TDetailBuy
