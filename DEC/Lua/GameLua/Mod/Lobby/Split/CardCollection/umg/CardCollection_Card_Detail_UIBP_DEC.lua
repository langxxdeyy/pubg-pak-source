local CardCollectionUIConfig = require("GameLua.Mod.Lobby.Base.CardCollection.logic.CardCollectionSeasonUIConfig")
local CardCollectionUtil = require("GameLua.Mod.Lobby.Base.CardCollection.logic.CardCollectionUtil")
local PopupType = CardCollectionUIConfig.ECardCollectionPopupType
local CardCollection_Card_Detail_UIBP = {}
function CardCollection_Card_Detail_UIBP:ctor(_, extraData)
  extraData = extraData or {}
  self.data = extraData.data
  self.setUI = extraData.setUI
  self.curOwned = nil
  self.subPanelCache = {}
  self.isHistory = extraData.isHistory
  self.index = extraData.index
end
function CardCollection_Card_Detail_UIBP:OnInitialize()
end
function CardCollection_Card_Detail_UIBP:RegistEvents()
  self:AddOnClickedEventByControl(self.UIRoot.Button_Close, self.OnClickButtonClose, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Left, self.OnClickButtonLeft, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Right, self.OnClickButtonRight, self)
  self:AddCommonEvent(EVENTTYPE_CARD_COLLECTION, EVENTID_CARDCOLLECTION_SEND_BOTTLE_RESULT, self.OnSingleCardChange, self)
  self:AddCommonEvent(EVENTTYPE_CARD_COLLECTION, EVENTID_CARDCOLLECTION_GEN_EXCHANGE_RESULT, self.OnSingleCardChange, self)
  self:AddCommonEvent(EVENTTYPE_CARD_COLLECTION, EVENTID_CARDCOLLECTION_GIFT_CARD_RESULT, self.OnSingleCardChange, self)
  self:AddCommonEvent(EVENTTYPE_CARD_COLLECTION, EVENTID_CARDCOLLECTION_SET_DATA_UPDATE, self.OnMultiCardChange, self)
end
function CardCollection_Card_Detail_UIBP:OnPostInitialize()
  self:UpdateUI()
  local CardCollectionSwapModule = ModuleManager.GetSplitModule(ModuleManager.LobbyModuleConfig.CardCollectionSwapModule)
  CardCollectionSwapModule:QuerySwapHistory()
end
function CardCollection_Card_Detail_UIBP:OnShow()
end
function CardCollection_Card_Detail_UIBP:OnHide()
end
function CardCollection_Card_Detail_UIBP:OnClose()
end
function CardCollection_Card_Detail_UIBP:OnClickButtonClose()
  self:PlayAudio(sound_config.close_v1)
  self:CloseSelf()
end
function CardCollection_Card_Detail_UIBP:OnClickButtonLeft()
  self:PlayAudio(sound_config.click_v1)
  log(bWriteLog and "[CardCollection] CardDetail:OnClickButtonLeft")
  self:_SwitchCard(-1)
end
function CardCollection_Card_Detail_UIBP:OnClickButtonRight()
  self:PlayAudio(sound_config.click_v1)
  log(bWriteLog and "[CardCollection] CardDetail:OnClickButtonRight")
  self:_SwitchCard(1)
end
function CardCollection_Card_Detail_UIBP:_SwitchCard(direction)
  if not self.setUI or not slua.isValid(self.setUI.UIRoot) then
    self:_RefetchSetUI()
  end
  if not self.setUI or not slua.isValid(self.setUI.UIRoot) then
    return
  end
  local newCardData
  newCardData, self.index = self.setUI:SwitchDetailCard(direction)
  if newCardData then
    self.data = newCardData
    self:UpdateUI()
  end
end
function CardCollection_Card_Detail_UIBP:_RefetchSetUI()
  local parentUIConfig = self.isHistory and UIManager.UI_Config.CardCollection_History_UIBP or UIManager.UI_Config.CardCollection_Set_UIBP
  self.setUI = UIManager.GetUI(parentUIConfig)
  log(bWriteLog and "[CardCollection] CardDetail:_RefetchSetUI")
end
function CardCollection_Card_Detail_UIBP:OnSingleCardChange()
  if not (self.data and self.data.count) or self.data.count <= 0 then
    return
  end
  self.data.count = self.data.count - 1
  self:UpdateUI()
end
function CardCollection_Card_Detail_UIBP:OnMultiCardChange()
  if self.setUI and self.setUI.data then
    self.data = self.setUI.data.CardData[self.index]
    self:UpdateUI()
  end
end
function CardCollection_Card_Detail_UIBP:UpdateUI()
  if not self.data then
    return
  end
  local bOwned = self.data.count and self.data.count > 0
  self._signAutoPlay = bOwned
  self._signPlayedMap = {}
  self:_ShowDetailPanel(bOwned)
end
function CardCollection_Card_Detail_UIBP:_ShowDetailPanel(bOwned)
  if self.curOwned == bOwned and self.subPanelCache[bOwned] then
    self.subPanelCache[bOwned]:OnRefresh(self.data)
    return
  end
  self.curOwned = bOwned
  local uiConfig = bOwned and UIManager.UI_Config.CardCollection_Card_Detail_Owned_UIBP or UIManager.UI_Config.CardCollection_Card_Detail_Unowned_UIBP
  local attachPanel = self.UIRoot.CanvasPanel_Mount
  if not self.subPanelCache[bOwned] and attachPanel then
    self.subPanelCache[bOwned] = self:CreateChildWindow(attachPanel, uiConfig)
  end
  for owned, handle in pairs(self.subPanelCache) do
    if owned == bOwned then
      handle:SelfHitTestInvisible()
    else
      handle:Hide()
    end
  end
  local targetHandle = self.subPanelCache[bOwned]
  if targetHandle then
    targetHandle:OnRefresh(self.data)
  end
  if self.isHistory and targetHandle and targetHandle.HideNode then
    targetHandle:HideNode(self.isHistory)
  end
end
function CardCollection_Card_Detail_UIBP:GetDataForJumpBack()
  log(bWriteLog and string.format("CardCollection_Card_Detail_UIBP:GetDataForJumpBack index=%s, isHistory=%s", tostring(self.index), tostring(self.isHistory)))
  return {
    ctorData = {
      {
        data = self.data,
        isHistory = self.isHistory,
        index = self.index
      }
    }
  }
end
function CardCollection_Card_Detail_UIBP:JumpBack(uiData)
  log_tree(bWriteLog and "CardCollection_Card_Detail_UIBP:JumpBack uiData", uiData)
  self:_RefetchSetUI()
  self:UpdateUI()
end
local class = require("class")
local ui_base = require("client.slua_ui_framework.base")
local CCardCollection_Card_Detail_UIBP = class(ui_base, nil, CardCollection_Card_Detail_UIBP)
return CCardCollection_Card_Detail_UIBP
