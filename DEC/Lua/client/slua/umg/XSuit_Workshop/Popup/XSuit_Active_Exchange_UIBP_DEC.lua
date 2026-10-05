local XSuit_Active_Exchange_UIBP = {}
local XSuitHandler = require("client.network.Protocol.XSuitHandler")
function XSuit_Active_Exchange_UIBP:ctor(_, materList, itemID, callback)
  self.makeUpMaterialList = materList
  self.itemID = itemID
  self.callback = callback
end
function XSuit_Active_Exchange_UIBP:OnInitialize()
  self.Common_Popup_Medium_UIBP = self:InitCommonPopup(self.UIRoot.Common_Popup_Medium_UIBP)
end
function XSuit_Active_Exchange_UIBP:RegistEvents()
  self:AddOnClickedEventByControl(self.UIRoot.Button_Cancel, self.OnButtonClick_Cancel, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Confirm, self.OnButtonClick_Confirm, self)
end
function XSuit_Active_Exchange_UIBP:OnPostInitialize()
  self.Common_Popup_Medium_UIBP:SetData(self, LocUtil.GetLocalizeResStr(200000811))
  self.UIRoot.TextBlock_Confirm:SetText(LocUtil.GetLocalizeResStr(45133))
  self.UIRoot.TextBlock_Cancel:SetText(LocUtil.GetLocalizeResStr(45134))
  self.exchange_info = {}
  for _, v in pairs(self.makeUpMaterialList) do
    if not self.exchange_info[v.resID] then
      self.exchange_info[v.resID] = v.count
    else
      self.exchange_info[v.resID] = self.exchange_info[v.resID] + v.count
    end
  end
  self:SetWidgetVisible(self.UIRoot.HorizontalBox_Exchange1, false)
  self:SetWidgetVisible(self.UIRoot.HorizontalBox_Exchange2, false)
  local index = 1
  local LogicXSuit = require("client.slua.logic.XSuit.logic_xsuit")
  local mat1Count, mat2Count = 0, 0
  local moneys = LogicXSuit.GetConfig("XSuit_Material")
  for id, count in pairs(self.exchange_info) do
    self:SetWidgetVisible(self.UIRoot["HorizontalBox_Exchange" .. index], true)
    local itemId, exchangeData = LogicXSuit.MaterialActive2CommonNum(id)
    local itemL = self.UIRoot["Lua_CommonItems_L" .. index]
    itemL:InitView(exchangeData.exchange_resid, count // exchangeData.give_num)
    self.UIRoot["TextBlock_Ratio" .. index]:SetText(LocUtil.LocalizeResFormat(99010057, exchangeData.exchange_count, exchangeData.give_num))
    local itemR = self.UIRoot["Lua_CommonItems_R" .. index]
    itemR:InitView(itemId, count)
    index = index + 1
    mat1Count = moneys[1] == exchangeData.exchange_resid and count // exchangeData.give_num or mat1Count
    mat2Count = moneys[2] == exchangeData.exchange_resid and count // exchangeData.give_num or mat2Count
  end
  self.UIRoot.TextBlock_Ruler:SetText(LocUtil.LocalizeResFormat(200000709, mat1Count, mat2Count))
end
function XSuit_Active_Exchange_UIBP:OnButtonClick_Cancel()
  self:PlayAudio(sound_config.click_v1)
  self:CloseSelf()
end
function XSuit_Active_Exchange_UIBP:OnButtonClick_Confirm()
  self:PlayAudio(sound_config.click_v1)
  XSuitHandler.send_gold_dress_exchange_active_currency_req(self.exchange_info, self.itemID)
  if self.callback then
    self.callback()
  end
  self:CloseSelf()
end
local class = require("class")
local ui_base = require("client.slua_ui_framework.base")
local CXSuit_Active_Exchange_UIBP = class(ui_base, nil, XSuit_Active_Exchange_UIBP)
return CXSuit_Active_Exchange_UIBP
