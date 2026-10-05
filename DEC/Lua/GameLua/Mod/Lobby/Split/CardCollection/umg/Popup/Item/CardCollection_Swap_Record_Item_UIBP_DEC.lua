local TimeUtil = require("client.common.time_util")
local CardCollection_Swap_Record_Item_UIBP = {}
local CardCollectionUtil = require("GameLua.Mod.Lobby.Base.CardCollection.logic.CardCollectionUtil")
local ButtonStyleConfig = require("client.slua.component.button.Common_Button_Style_Config")
local btnStatus = {
  [0] = 0,
  [1] = 1,
  [2] = 5,
  [3] = 2,
  [4] = 2
}
local swapSide = {Friend = 1, Outside = 2}
local outsideSwapIcon = 12220909
function CardCollection_Swap_Record_Item_UIBP:ctor()
end
function CardCollection_Swap_Record_Item_UIBP:OnInitialize()
  self.Widget_Name = self.UIRoot.Text_PlayerName
  self.Widget_Time = self.UIRoot.TextBlock_Time
  self.Widget_EndTime = self.UIRoot.TextBlock_LimitTime
  self.Common_Avatar = self.UIRoot.Common_Avatar_BP
  local lua = "GameLua.Mod.Lobby.Split.CardCollection.umg.Popup.Item.CardCollection_Card_Item_Swap_Record_UIBP"
  self.LoopScrollBox_Record = self:InitChildClassScrollBox(self.UIRoot.LoopScrollBox_0, lua)
  local UIComponentModule = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.UIComponentModule)
  self.CardItem = UIComponentModule:InitWithParentComponent(self, UIComponentModule.Config.CardCollection_Card_Item_Swap_Record, self.UIRoot.Collection_Card_Item_UIBP_1, self)
  self.UIRoot.WidgetSwitcher_0:SetActiveWidgetIndex(0)
end
function CardCollection_Swap_Record_Item_UIBP:RegistEvents()
  self:AddOnClickedEventByControl(self.UIRoot.Button_Share, self.OnClickButtonShare, self)
end
function CardCollection_Swap_Record_Item_UIBP:OnPostInitialize()
end
function CardCollection_Swap_Record_Item_UIBP:OnRefresh(data, index)
  self.data = data
  self:SetCardInfo()
  self:SetExtraInfo()
  self:SetUserInfo()
  self:SetSwapType()
  local btnStatusIndex = btnStatus[data.order_status or 3] or 2
  self.UIRoot.WidgetSwitcher_BtnStatus:SetActiveWidgetIndex(btnStatusIndex)
  if btnStatusIndex == btnStatus[0] then
    local CardCollectionSwapModule = ModuleManager.GetSplitModule(ModuleManager.LobbyModuleConfig.CardCollectionSwapModule)
    local _, validDay = CardCollectionSwapModule:GetSwapLimit()
    local expireTime = validDay * 86400
    if 0 >= data.create_time + expireTime - TimeUtil.GetServerTimeInSec() then
      self.UIRoot.WidgetSwitcher_BtnStatus:SetActiveWidgetIndex(btnStatus[5])
      return
    end
    self:SetButtonStatus()
    self:SetCountDown()
  end
end
function CardCollection_Swap_Record_Item_UIBP:OnShow()
end
function CardCollection_Swap_Record_Item_UIBP:OnHide()
end
function CardCollection_Swap_Record_Item_UIBP:OnClose()
end
function CardCollection_Swap_Record_Item_UIBP:OnClickButtonCancel()
  self:PlayAudio(sound_config.click_v1)
  local CommonMsgBoxMgr = require("client.slua.logic.common.logic_common_msg_box")
  local msg = LocUtil.GetLocalizeResStr(33020149)
  local btnOK = LocUtil.GetLocalizeResStr(6752)
  local btnCancel = LocUtil.GetLocalizeResStr(7510)
  local confirmCallback = function()
    local CardCollectionSeasonHandler = require("GameLua.Mod.Lobby.Split.CardCollection.ModCardCollectionSeasonHandler")
    CardCollectionSeasonHandler.send_card_collect_cancel_exchange_req(self.data.order_id)
  end
  CommonMsgBoxMgr.Show(CommonMsgBoxMgr.SHOW_TYPE_TWO, nil, msg, confirmCallback, nil, btnOK, btnCancel)
end
function CardCollection_Swap_Record_Item_UIBP:OnClickButtonSwapRsp()
  self:PlayAudio(sound_config.click_v1)
  local CardCollectionUIConfig = require("GameLua.Mod.Lobby.Base.CardCollection.logic.CardCollectionSeasonUIConfig")
  local popupType = CardCollectionUIConfig.ECardCollectionPopupType
  CardCollectionUtil.OpenPopup(popupType.SwapRsp, {
    orderId = self.data.order_id,
    orderInfo = self.data
  })
end
function CardCollection_Swap_Record_Item_UIBP:OnClickButtonShare()
  self:PlayAudio(sound_config.click_v1)
  CardCollectionUtil.OpenSwapShare(self.data.data.give_card_list, self.data.data.expect_res_id, self.data.order_id, self.data.create_time)
end
function CardCollection_Swap_Record_Item_UIBP:OnClickCard()
  local CardCollectionUIConfig = require("GameLua.Mod.Lobby.Base.CardCollection.logic.CardCollectionSeasonUIConfig")
  local popupType = CardCollectionUIConfig.ECardCollectionPopupType
  CardCollectionUtil.OpenPopup(popupType.SwapInfo, {
    orderInfo = self.data
  })
end
function CardCollection_Swap_Record_Item_UIBP:SetExtraInfo()
  self.Widget_Time:SetText(TimeUtil.FormatTime_YMDHM(self.data.create_time, true))
  local bIsOutsideShare = self.data.data.share_list and not not self.data.data.share_list[2]
  self:SetWidgetVisible(self.UIRoot.CanvasPanel_2, bIsOutsideShare)
  self:SetWidgetVisible(self.UIRoot.Button_Share, bIsOutsideShare, true)
end
function CardCollection_Swap_Record_Item_UIBP:SetSwapType()
  local shareList = self.data.data.share_list
  if not shareList then
    self:SetWidgetVisible(self.UIRoot.WidgetSwitcher_Type, false)
    return
  end
  if shareList[swapSide.Friend] then
    self:SetWidgetVisible(self.UIRoot.WidgetSwitcher_Type, true)
    self.UIRoot.WidgetSwitcher_Type:SetActiveWidgetIndex(1)
    return
  end
  if shareList[swapSide.Outside] then
    self:SetWidgetVisible(self.UIRoot.WidgetSwitcher_Type, true)
    self.UIRoot.WidgetSwitcher_Type:SetActiveWidgetIndex(0)
    return
  end
  self:SetWidgetVisible(self.UIRoot.WidgetSwitcher_Type, false)
end
function CardCollection_Swap_Record_Item_UIBP:SetCardInfo()
  self.CardItem:OnRefresh(self.data.show_data.expect_card)
  self.LoopScrollBox_Record:SetData(self.data.show_data.give_card_list)
  if #self.data.show_data.give_card_list == 1 then
    self:SetWidgetVisible(self.UIRoot.CanvasPanel_PickDesc, false)
    return
  end
  self:SetWidgetVisible(self.UIRoot.CanvasPanel_PickDesc, true)
  self.UIRoot.TextBlock_PickDesc:SetText(LocUtil.LocalizeResFormat(33020194, #self.data.show_data.give_card_list))
end
function CardCollection_Swap_Record_Item_UIBP:SetUserInfo()
  if self:SetCompleteAvatar() then
    return
  end
  if self:SetShareSwapAvatar() then
    return
  end
  self.Widget_Name:SetText(DataMgr.roleData.nickName)
  self.Common_Avatar:InitView(1, DataMgr.roleData.uid, DataMgr.roleData.headIconUrl, DataMgr.roleData.gender, DataMgr.roleData.cur_avatar_box_id, DataMgr.roleData.level, false, "")
end
function CardCollection_Swap_Record_Item_UIBP:SetCountDown()
  if self.Timer then
    return
  end
  local CardCollectionSwapModule = ModuleManager.GetSplitModule(ModuleManager.LobbyModuleConfig.CardCollectionSwapModule)
  local _, validDay = CardCollectionSwapModule:GetSwapLimit()
  local expireTime = validDay * 86400
  self.Timer = self:AddTimerLoop(0, function()
    if self.data.create_time + expireTime - TimeUtil.GetServerTimeInSec() <= 0 then
      self.UIRoot.WidgetSwitcher_BtnStatus:SetActiveWidgetIndex(btnStatus[5])
      self:RemoveTimer(self.Timer)
      self.Timer = nil
    end
    self.Widget_EndTime:SetText(TimeUtil.FormatCountDownTime_D_or_HMS(self.data.create_time + expireTime - TimeUtil.GetServerTimeInSec(), 1))
  end, 0, 1)
end
function CardCollection_Swap_Record_Item_UIBP:SetButtonStatus()
  if self:IsOrderSender() then
    self.UIRoot.Lua_Common_Button:SetBtnStyle(ButtonStyleConfig.ENUM_BTN_TYPE.Lv2Normal)
    self.UIRoot.Lua_Common_Button:SetBtnText(LocUtil.GetLocalizeResStr(7510))
    self.UIRoot.Lua_Common_Button:SetBtnClick(self.OnClickButtonCancel, self)
    return
  end
  self.UIRoot.Lua_Common_Button:SetBtnStyle(ButtonStyleConfig.ENUM_BTN_TYPE.Lv1Rec)
  self.UIRoot.Lua_Common_Button:SetBtnText(LocUtil.GetLocalizeResStr(33020170))
  self.UIRoot.Lua_Common_Button:SetBtnClick(self.OnClickButtonSwapRsp, self)
end
function CardCollection_Swap_Record_Item_UIBP:IsOrderSender()
  return tonumber(self.data.sender_id) == tonumber(DataMgr.roleData.uid)
end
function CardCollection_Swap_Record_Item_UIBP:SetShareSwapAvatar()
  local shareList = self.data.data.share_list
  if not shareList then
    return false
  end
  if type(shareList[swapSide.Friend]) == "number" then
    local logic_profile_get_wrap = require("client.slua.logic.user.profile.logic_profile_get_wrap")
    logic_profile_get_wrap.GetNormalProfiles({
      shareList[swapSide.Friend]
    }, function(list)
      if list and list[1] then
        local profile = list[1]
        self.Widget_Name:SetText(profile.nickName or "")
        self.Common_Avatar:InitView(1, profile.uid, profile.picUrl, nil, profile.cur_avatar_box_id, profile.level, false, "", true)
      end
    end, Enum_PROFILE_REPORT_CFG.CARD_COLLECTION)
    return true
  end
  if shareList[swapSide.Outside] then
    self.Widget_Name:SetText(LocUtil.GetLocalizeResStr(33020168))
    self.Common_Avatar:InitView(1, 0, outsideSwapIcon)
    return true
  end
  return false
end
function CardCollection_Swap_Record_Item_UIBP:SetCompleteAvatar()
  if self.data.order_status == 3 or self.data.order_status == 4 then
    local logic_profile_get_wrap = require("client.slua.logic.user.profile.logic_profile_get_wrap")
    logic_profile_get_wrap.GetNormalProfiles({
      self.data.data.dealer_id
    }, function(list)
      if list and list[1] then
        local profile = list[1]
        self.Widget_Name:SetText(profile.nickName or "")
        self.Common_Avatar:InitView(1, profile.uid, profile.picUrl, nil, profile.cur_avatar_box_id, profile.level, false, "", true)
      end
    end, Enum_PROFILE_REPORT_CFG.CARD_COLLECTION)
    return true
  end
  return false
end
local class = require("class")
local ui_base = require("client.slua_ui_framework.base")
local CCardCollection_Swap_Record_Item_UIBP = class(ui_base, nil, CardCollection_Swap_Record_Item_UIBP)
return CCardCollection_Swap_Record_Item_UIBP
