local XSuit_Workshop_Glide_Component = {}
local StringUtil = require("common.string_util")
local XSuitHandler = require("client.network.Protocol.XSuitHandler")
function XSuit_Workshop_Glide_Component:InitGlideComponent()
  self:AddCommonEvent(EVENTTYPE_XSUIT, EVENTID_XSUIT_GLIDE_UNLOCK, self.RefreshGlideSource, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_DoubleRide, self.OnClickButton_DoubleRid, self)
  self.bCanDR = false
  self.bIsDR = false
  self.bShowDRGuid = nil
  self.DRlist = {}
  self.DRConfig = nil
end
function XSuit_Workshop_Glide_Component:RefreshGlideComponent()
  self:SetWidgetVisible(self.UIRoot.CanvasPanel_UnlockGlide, false)
  self:SetWidgetVisible(self.UIRoot.CanvasPanel_FeatureNotice, true)
  self:SetWidgetVisible(self.UIRoot.Button_DoubleRide, false, true)
  local bRiding, bGlide = self:IsSelectGlide()
  if bRiding or bGlide then
    self:RefreshGlideSource()
    self:RefreshButton_DoubleRide()
  end
end
function XSuit_Workshop_Glide_Component:RefreshGlideSource()
  log(bWriteLog and "xcc XSuit_Workshop_Glide_Component:RefreshGlideSource")
  local glideCfg = CDataTable.GetTableDataByFilter("XSuitGlideCfg", "XSuitID7", self.ItemResID)
  if nil == glideCfg then
    log(bWriteLog and "xcc XSuit_Workshop_Glide_Component:RefreshGlideSource glideCfg is nil self.ItemResID: " .. self.ItemResID .. " self.CurItemLevel: " .. self.CurItemLevel .. " self.selectFeatureIndex: " .. self.selectFeatureIndex)
    return
  end
  if self.CurItemLevel < self.selectLevel then
    log(bWriteLog and "xcc XSuit_Workshop_Glide_Component:RefreshGlideSource self.CurItemLevel < self.selectLevel")
    return
  end
  local bShowUnlockGlide = true
  if LobbySystem.CheckUrlCanJump("game://?module=1009500") then
    local xsuit_config_and_cache = require("client.slua.logic.XSuit.xsuit_config_and_cache")
    local curPoolConfig = xsuit_config_and_cache.GetNowPoolConfig()
    for _, v in ipairs(curPoolConfig) do
      local config = v.poolConfig
      if config.period == self.selectPeriod then
        bShowUnlockGlide = false
        log(bWriteLog and "xcc XSuit_Workshop_Glide_Component:RefreshGlideSource bShowUnlockGlide false")
      end
    end
  end
  local wardrobe_data = require("client.slua.logic.wardrobe.wardrobe_data")
  log(bWriteLog and "xcc XSuit_Workshop_Glide_Component:RefreshGlideSource self.selectFeatureIndex true")
  if wardrobe_data:HasItem(glideCfg.GlideID) then
    self.UIRoot.CanvasPanel_UnlockGlide:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  elseif bShowUnlockGlide then
    self.UIRoot.Lua_CommonItems:InitView(glideCfg.GlideID, 1)
    self.UIRoot.Lua_CommonItems:SetClickItemCallback(function()
      self:OnClickUnLockGlideSource()
    end)
    self.UIRoot.Lua_CommonItems:SetIsLock(true, true)
    self.UIRoot.Lua_CommonItems:EnableShowTips(false)
    self:SetWidgetVisible(self.UIRoot.CanvasPanel_FeatureNotice, false, false)
    self:SetWidgetVisible(self.UIRoot.CanvasPanel_UnlockGlide, true, false)
    self.UIRoot.TextBlock_Aircraft:SetText(LocUtil.GetLocalizeResStr(200000481))
  end
end
function XSuit_Workshop_Glide_Component:OnClickUnLockGlideSource()
  self:PlayAudio(sound_config.click_v1)
  local materialInfo = self:GetMaterialData(self.selectPeriod, self.selectBranchId, self.selectLevel, nil, nil, true)
  if not materialInfo or not next(materialInfo) then
    return
  end
  if self.limitMoneyList and materialInfo.bNeedMakeUp and materialInfo.bCanMakeUp then
    log(bWriteLog and "XSuit_Workshop_Glide_Component:OnClickUnLockGlideSource currency complete by xsuit draw activity")
    local logic_xsuit_activity = ModuleManager.GetModule(ModuleManager.JumpModuleConfig.logic_xsuit_activity)
    local costCurrency = CDataTable.GetTableData("Item", logic_xsuit_activity:GetDrawCurrencyID())
    local extraData = {}
    extraData.explain = {}
    extraData.explain.textId = 200000370
    extraData.explain.param1 = costCurrency.ItemName
    local msg = LocUtil.LocalizeResFormat(200000240, materialInfo.needCurrency)
    local clickOkCallback = function()
      XSuitHandler.send_do_onshot_exchange_by_activity_id_req(logic_xsuit_activity:GetExchangeActivityID(), materialInfo.exchangeList)
    end
    local CommonMsgBoxMgr = require("client.slua.logic.common.logic_common_msg_box")
    CommonMsgBoxMgr.Show(2, LocUtil.LocalizeResFormat(5077), msg, clickOkCallback, nil, nil, nil, extraData)
    return
  end
  local materialList = materialInfo.materialList
  local glideCfg = CDataTable.GetTableDataByFilter("XSuitGlideCfg", "XSuitID7", self.ItemResID)
  UIManager.ShowUI(UIManager.UI_Config.XSuit_Unlock_Glide_UIBP, materialList, function()
    self:ConfirmUnLockGlideSource(glideCfg.GlideID, materialList)
  end)
end
function XSuit_Workshop_Glide_Component:ConfirmUnLockGlideSource(GlideID, materialList)
  if self:CheckLockGlideSource(materialList) then
    XSuitHandler.send_unlock_xsuit_glide_req(GlideID, self.selectBranchId)
  else
    ShowNotice(100140014)
  end
end
function XSuit_Workshop_Glide_Component:CheckLockGlideSource(materialList)
  if not materialList then
    return false
  end
  for _, materia in ipairs(materialList) do
    if materia.count < materia.needCount then
      return false
    end
  end
  return true
end
function XSuit_Workshop_Glide_Component:RefreshButton_DoubleRide()
  self.bCanDR = false
  if self.ItemResID and self.DRlist[self.ItemResID] == nil then
    local featuresItem = CDataTable.GetTableData("FeaturesItems", self.ItemResID) or {}
    local features = StringUtil.Split(featuresItem.Features or "", ";") or {}
    self.DRlist[self.ItemResID] = false
    local DRFeature = 1832
    for _, v in ipairs(features) do
      if tonumber(v) == DRFeature then
        self.bCanDR = true
        self.DRlist[self.ItemResID] = true
        break
      end
    end
  else
    self.bCanDR = self.ItemResID and self.DRlist[self.ItemResID] or false
  end
  if self.bCanDR then
    self:SetWidgetVisible(self.UIRoot.Button_DoubleRide, true, true)
    if self.bShowDRGuid == nil then
      self:IsCanShowDRGuid()
    end
    if self.bShowDRGuid then
      self:SetWidgetVisible(self.UIRoot.Image_New, true, false)
    else
      self:SetWidgetVisible(self.UIRoot.Image_New, false, false)
    end
  end
  if not self.bIsDR then
    self.UIRoot.WidgetSwitcher_Aircraft:SetActiveWidgetIndex(1)
    self.bIsDR = true
  end
end
function XSuit_Workshop_Glide_Component:OnClickButton_DoubleRid()
  self:TryGetDRGlideId()
  if self.bCanDR then
    if self.bIsDR then
      self.bIsDR = false
      self:ShowDRGuid()
      self.UIRoot.WidgetSwitcher_Aircraft:SetActiveWidgetIndex(0)
      self:ShowAvatarDisplay(self.DRConfig and self.DRConfig.GlideID, {bWear = true})
    else
      self.bIsDR = true
      self.UIRoot.WidgetSwitcher_Aircraft:SetActiveWidgetIndex(1)
      self:ShowAvatarDisplay(self.DRConfig and self.DRConfig.DRGlideID, {bWear = true})
    end
  end
end
function XSuit_Workshop_Glide_Component:IsCanShowDRGuid()
  if self.bCanDR then
    local PlayerPrefsSystem = require("client.logic.LogicPlayerPrefs.playerprefs")
    local data = PlayerPrefsSystem.LoadFileToTable_N(PlayerPrefsSystem.ePlayerPrefsType.eXsuitGuide)
    if not (data and data.doubleRideGuide) or not data.doubleRideGuide[self.ItemResID] then
      self.bShowDRGuid = true
    else
      self.bShowDRGuid = false
    end
  end
end
function XSuit_Workshop_Glide_Component:ShowDRGuid()
  if self.bShowDRGuid then
    self.bShowDRGuid = false
    self:SetWidgetVisible(self.UIRoot.Image_New, false, false)
    local PlayerPrefsSystem = require("client.logic.LogicPlayerPrefs.playerprefs")
    local data = PlayerPrefsSystem.LoadFileToTable_N(PlayerPrefsSystem.ePlayerPrefsType.eXsuitGuide) or {}
    data.doubleRideGuide = data.doubleRideGuide or {}
    data.doubleRideGuide[self.ItemResID] = true
    PlayerPrefsSystem.SaveTableToFile_N(data, PlayerPrefsSystem.ePlayerPrefsType.eXsuitGuide)
    local id = tonumber(string.format("%d%d", self.ItemResID, self.selectFeatureIndex))
    UIManager.ShowUI(UIManager.UI_Config.ModeSelection_Guide_UIBP, id, 1, false, true)
  end
end
function XSuit_Workshop_Glide_Component:TryGetDRGlideId()
  local xsuit_config_and_cache = require("client.slua.logic.XSuit.xsuit_config_and_cache")
  self.DRConfig = xsuit_config_and_cache.GetDRGlideByXSuit7(self.ItemResID)
end
local Trait = require("common.trait")
local Cxsuit_unlock_glide = Trait(Trait.TraitPrototype, nil, XSuit_Workshop_Glide_Component)
return Cxsuit_unlock_glide
