local XSuit_Workshop_Upgrade_Component = {}
local xsuit_config_and_cache = require("client.slua.logic.XSuit.xsuit_config_and_cache")
local LogicXSuit = require("client.slua.logic.XSuit.logic_xsuit")
local XSuitHandler = require("client.network.Protocol.XSuitHandler")
local defaultState = 2
function XSuit_Workshop_Upgrade_Component:InitUpgradeComponent()
  self.MaterialComp = nil
  self.MaterialComp_UnlockFeature = nil
  self.UnlockType = nil
  self.UIRoot.TextBlock_Unlock:SetText(LocUtil.LocalizeResFormat(44666))
  self:AddOnClickedEventByControl(self.UIRoot.Button_Upgrade, self.OnClickUpgrade, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_NoUpgrade, self.OnClickNoUpgrade, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Get, self.OnClickGo, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Unlock, self.OnClickUnlockState, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_UnlockFeature, self.OnClickSubUnlock, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_6, self.OnClickSubUnlockGray, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_FreeUpgrade, self.OnButtonClick_FreeUpgrade, self)
  self:AddCommonEvent(EVENTTYPE_XSUIT, EVENTID_XSUIT_UNLOCK_FEATURE, self.OnUnlockFeature, self)
  self:AddCommonEvent(EVENTTYPE_XSUIT, EVENTID_XSUIT_ACTIVE_BRANCH_UPDATE, self.RefreshByActiveBranch, self)
  self:AddCommonEvent(EVENTTYPE_GOLDEN_SUIT, EVENTID_GOLDEN_SUIT_UPDATE_DRESS_STATE, self.OnStateUpdate, self)
  self:AddCommonEvent(EVENTTYPE_GOLDEN_SUIT, EVENTID_GOLDEN_SUIT_UNLOCK_STATE_SUCCESS, self.OnStateUnlock, self)
  self:AddCommonEvent(EVENTTYPE_GOLDEN_SUIT, EVENTID_GOLDEN_SUIT_EXCHANGED, self.OnExchanged, self)
  self.upgradeMaterialInfo = {}
end
function XSuit_Workshop_Upgrade_Component:UpdateButtonGroup()
  log(bWriteLog and "xcc XSuit_Workshop_Upgrade_Component:UpdateButtonGroup")
  self.UnlockType = nil
  if self.selectLevel <= self.CurItemLevel then
    local multiCfg = xsuit_config_and_cache.GetMultiTypeUnlockConfigByPeriod(self.selectPeriod)
    if multiCfg and self.CurItemLevel > 0 and self.CurItemLevel >= multiCfg.unlock_level and not LogicXSuit.CheckUnlockState(self.selectPeriod, self.CurState) and self.selectLevel >= multiCfg.unlock_level then
      self.UnlockType = 2
    end
  elseif self.selectLevel > self.CurItemLevel + 1 then
    self.UnlockType = 3
  elseif self.CurItemLevel > 0 and self.selectLevel == self.CurItemLevel + 1 then
    self.UnlockType = 1
  else
    self.UnlockType = 0
  end
  if self.UnlockType then
    self:SetWidgetVisible(self.UIRoot.Switch_Button, true)
    self.UIRoot.Switch_Button:SetActiveWidgetIndex(self.UnlockType)
    self:UpdateFreezeShow()
  else
    self:SetWidgetVisible(self.UIRoot.Switch_Button, false)
  end
  self:RefreshFreeUpgradeInfo()
end
function XSuit_Workshop_Upgrade_Component:UpdateFreezeShow()
  local nSuitLevel = self.CurItemLevel
  if 0 < nSuitLevel then
    local tUpdateInfo = self.CurUpgradeInfo
    local nSuitId = tUpdateInfo[nSuitLevel].item_id
    local wardrobe_data = require("client.slua.logic.wardrobe.wardrobe_data")
    local tItemData = wardrobe_data:GetHallDepotItemDataByResID(nSuitId)
    if tItemData and tItemData.lock_cnt and 0 < tItemData.lock_cnt then
      self:SetWidgetVisible(self.UIRoot.Switch_Button, false)
      log(bWriteLog and "XSuit_Workshop_Upgrade_Component:UpdateFreezeShow true nSuitLevel = " .. tostring(nSuitLevel) .. " nSuitId = " .. tostring(nSuitId) .. " tItemData.lock_cnt = " .. tostring(tItemData.lock_cnt) .. "")
    end
  end
end
function XSuit_Workshop_Upgrade_Component:UpdateMaterial()
  if self.selectLevel > self.CurItemLevel or self.UnlockType ~= 0 then
    local info = self:SetMaterialList() or {}
    if next(info) then
      self:RefershMaterial(info)
      return
    end
  end
  self:HideMaterialWidget()
end
function XSuit_Workshop_Upgrade_Component:HideMaterialWidget()
  if self.MaterialComp then
    self.MaterialComp:SetWidgetVisibility(false)
  end
end
function XSuit_Workshop_Upgrade_Component:RefershMaterial(info)
  local extra = {
    bShowFragmentTip = info.bNeedMakeUp and info.bCanMakeUp,
    bActive = info.bActive,
    makeUpList = info.makeUpList
  }
  if not self.MaterialComp then
    self.MaterialComp = self:CreateChildWindow(self.UIRoot.Material_Panel, UIManager.UI_Config.XSuit_Material_UIBP, 3, info.materialList, extra)
  else
    self.MaterialComp:SetMaterialData(info.materialList, extra)
  end
  self.MaterialComp:SetWidgetVisibility(true)
end
function XSuit_Workshop_Upgrade_Component:OnClickUpgrade()
  self:PlayAudio(sound_config.click_v1)
  local UIUtil = require("client.common.ui_util")
  if not UIUtil.CanClickNow(UIUtil.ClickFrequencyLimit.XSuit_Workshop_Upgrade_Component) then
    return
  end
  if self.bBranch then
    local branchId = LogicXSuit.GetActiveBranchIdByPeriod(self.selectPeriod)
    if not branchId then
      if self:ForceSelectBranch() then
        return
      end
      local PlayerPrefsSystem = require("client.logic.LogicPlayerPrefs.playerprefs")
      local cache = PlayerPrefsSystem.LoadFileToTable_N(PlayerPrefsSystem.ePlayerPrefsType.eXSuitActiveBranch)
      if not cache or not cache[self.selectPeriod] then
        PlayerPrefsSystem.SaveTableToFile_N({
          [self.selectPeriod] = true
        }, PlayerPrefsSystem.ePlayerPrefsType.eXSuitActiveBranch)
        UIManager.ShowUI(UIManager.UI_Config.XSuit_Select_Branch_UIBP, self.selectPeriod, function()
          self:UpgradeByCommonMaterial()
        end)
        return
      end
    elseif branchId and branchId == self.selectBranchId then
      self:FreeUpgradeByActiveBranch()
      return
    end
  end
  self:UpgradeByCommonMaterial()
end
function XSuit_Workshop_Upgrade_Component:UpgradeByCommonMaterial()
  local materialInfo = self:GetMaterialData(self.selectPeriod, self.selectBranchId, self.selectLevel)
  if not materialInfo or not materialInfo.bUpgrade then
    ShowNotice(9986)
    return
  end
  local styleType, title, msg, clickOkCallback, extraData = 2, LocUtil.LocalizeResFormat(5077), nil, nil, {}
  if materialInfo.bNeedMakeUp and materialInfo.bCanMakeUp then
    log(bWriteLog and "XSuit_Workshop_Upgrade_Component:UpgradeByCommonMaterial quickExchangeMaterial")
    local logic_xsuit_activity = ModuleManager.GetModule(ModuleManager.JumpModuleConfig.logic_xsuit_activity)
    local costCurrency = CDataTable.GetTableData("Item", logic_xsuit_activity:GetDrawCurrencyID() or 1703269)
    extraData.explain = LocUtil.LocalizeResFormat(200000370, costCurrency.ItemName)
    msg = LocUtil.LocalizeResFormat(200000240, materialInfo.needCurrency)
    function clickOkCallback()
      XSuitHandler.send_do_onshot_exchange_by_activity_id_req(logic_xsuit_activity:GetExchangeActivityID(), materialInfo.exchangeList)
    end
  else
    msg = LocUtil.LocalizeResFormat(200000371, materialInfo.materialList[1].needCount, materialInfo.materialList[2].needCount)
    function clickOkCallback()
      local needUpgradeID = LogicXSuit.GetItemIDByPeriodSelf(self.selectPeriod, self.selectBranchId)
      XSuitHandler.send_rise_star_req(self.selectPeriod, needUpgradeID, self.selectBranchId)
    end
  end
  local CommonMsgBoxMgr = require("client.slua.logic.common.logic_common_msg_box")
  CommonMsgBoxMgr.Show(styleType, title, msg, clickOkCallback, nil, nil, nil, extraData)
end
function XSuit_Workshop_Upgrade_Component:OnClickNoUpgrade()
  self:PlayAudio(sound_config.click_v1)
  ShowNotice(10646)
end
function XSuit_Workshop_Upgrade_Component:OnClickGo()
  self:PlayAudio(sound_config.click_v1)
  local jumpList = LogicXSuit.GetJumpInfoByItemID(self.ItemResID)
  for index, jumpType in pairs(jumpList or {}) do
    local cfg = CDataTable.GetTableData("JumpConfig", jumpType)
    GlobalData.JumpUrl(cfg.JumpUrl)
    return
  end
  ShowNotice(6430)
end
function XSuit_Workshop_Upgrade_Component:OnClickUnlockState()
  self:PlayAudio(sound_config.click_v1)
  local UIUtil = require("client.common.ui_util")
  if not UIUtil.CanClickNow(UIUtil.ClickFrequencyLimit.XSuit_Workshop_Upgrade_Component) then
    return
  end
  local materialInfo = self:GetMaterialData(self.selectPeriod, self.selectBranchId, nil, nil, 1)
  if not materialInfo or not next(materialInfo) then
    log(bWriteLog and "XSuit_Workshop_Upgrade_Component:OnClickUnlockState materialInfo is nil")
    return
  end
  local styleType, title, msg, clickOkCallback, extraData = 2, LocUtil.LocalizeResFormat(5077), nil, nil, {}
  local CommonMsgBoxMgr = require("client.slua.logic.common.logic_common_msg_box")
  if materialInfo.bNeedMakeUp and materialInfo.bCanMakeUp then
    log(bWriteLog and "XSuit_Workshop_Upgrade_Component:OnClickUnlockState quickExchangeMaterial")
    msg = LocUtil.LocalizeResFormat(200000240, materialInfo.needCurrency)
    function clickOkCallback()
      if slua.isValid(self.UIRoot) then
        local logic_xsuit_activity = ModuleManager.GetModule(ModuleManager.JumpModuleConfig.logic_xsuit_activity)
        XSuitHandler.send_do_onshot_exchange_by_activity_id_req(logic_xsuit_activity:GetExchangeActivityID(), materialInfo.exchangeList)
      end
    end
    CommonMsgBoxMgr.Show(styleType, title, msg, clickOkCallback)
  else
    msg = ""
    if materialInfo.materialList[1] and materialInfo.materialList[2] then
      msg = LocUtil.LocalizeResFormat(18140176, materialInfo.materialList[1].needCount, materialInfo.materialList[2].needCount)
    elseif materialInfo.materialList[1] then
      msg = LocUtil.LocalizeResFormat(18140179, materialInfo.materialList[1].needCount)
    end
    function clickOkCallback()
      LogicXSuit.SendUnlockGoldDressStateReq(self.selectPeriod, self.CurState, self.selectBranchId)
    end
    CommonMsgBoxMgr.Show(styleType, title, msg, clickOkCallback, nil, nil, nil, extraData)
  end
end
function XSuit_Workshop_Upgrade_Component:OnStateUpdate()
  self.CurState = self.CurState or defaultState
  self:UpdateCurXSuitInfo()
  self:UpdateButtonGroup()
  self:UpdateMaterial()
  self:UpdateChangeStateButton()
  self:TryShowEffect()
end
function XSuit_Workshop_Upgrade_Component:OnStateUnlock()
  self.upgradeMaterialInfo = {}
  self:OnStateUpdate()
end
function XSuit_Workshop_Upgrade_Component:UpdateUnlockFeatureButton(show, period, branchId, level, index)
  if not show then
    self.UIRoot.CanvasPanel_UnlockFeature:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  else
    self.UIRoot.TextBlock_12:SetText(LocUtil.LocalizeResFormat(44666))
    self.UIRoot.TextBlock_13:SetText(LocUtil.LocalizeResFormat(44666))
    self.UIRoot.CanvasPanel_UnlockFeature:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
    local materInfo = self:GetMaterialData(period, branchId, level, index)
    if not materInfo or not next(materInfo) then
      log(bWriteLog and "XSuit_Workshop_Upgrade_Component:UpdateUnlockFeatureButton error")
      return
    end
    if not self.MaterialComp_UnlockFeature then
      self.MaterialComp_UnlockFeature = self:CreateChildWindow(self.UIRoot.Material_Panel02, UIManager.UI_Config.XSuit_Material_UIBP, 3, materInfo.materialList, {
        bShowFragmentTip = materInfo.bNeedMakeUp and materInfo.bCanMakeUp
      })
    else
      self.MaterialComp_UnlockFeature:SetMaterialData(materInfo.materialList, {
        bShowFragmentTip = materInfo.bNeedMakeUp and materInfo.bCanMakeUp
      })
    end
    self.MaterialComp_UnlockFeature:SetWidgetVisibility(true)
    if self.CurItemLevel < self.selectLevel or not materInfo.bUpgrade then
      self.UIRoot.WidgetSwitcher_3:SetActiveWidgetIndex(1)
    else
      self.UIRoot.WidgetSwitcher_3:SetActiveWidgetIndex(0)
    end
  end
end
function XSuit_Workshop_Upgrade_Component:OnClickSubUnlock()
  self:PlayAudio(sound_config.click_v1)
  local effectIdArray = self.CurUpgradeInfo[self.selectLevel].effect_id_array
  if effectIdArray[self.selectFeatureIndex] and effectIdArray[self.selectFeatureIndex] ~= 0 then
    local effectInfo = CDataTable.GetTableData("GoldenSuitEffectCfg", effectIdArray[self.selectFeatureIndex])
    if effectInfo and effectInfo.UnlockType and effectInfo.UnlockType ~= 0 then
      local UnLockFeatureCfg = CDataTable.GetTableDataByFilter("UnLockFeatureCfg", "EffectType", effectInfo.UnlockType, "Period", self.selectPeriod, "BranchId", self.selectBranchId)
      if not UnLockFeatureCfg then
        log(bWriteLog and "XSuit_Workshop_Upgrade_Component:OnClickSubUnlock not UnLockFeatureCfg")
        return
      end
      local CommonMsgBoxMgr = require("client.slua.logic.common.logic_common_msg_box")
      local styleType, title, msg, clickOkCallback, extraData = 2, LocUtil.LocalizeResFormat(5077), nil, nil, {}
      local logic_xsuit_activity = ModuleManager.GetModule(ModuleManager.JumpModuleConfig.logic_xsuit_activity)
      local materInfo = self:GetMaterialData(self.selectPeriod, self.selectBranchId, self.selectLevel, UnLockFeatureCfg.UnlockIndex)
      if not materInfo or not next(materInfo) then
        log(bWriteLog and "XSuit_Workshop_Upgrade_Component:OnClickSubUnlock not materInfo")
        return
      end
      if materInfo.bNeedMakeUp and materInfo.bCanMakeUp then
        log(bWriteLog and "XSuit_Workshop_Upgrade_Component:OnClickSubUnlock quickExchangeMaterial")
        msg = LocUtil.LocalizeResFormat(200000240, materInfo.needCurrency)
        function clickOkCallback()
          XSuitHandler.send_do_onshot_exchange_by_activity_id_req(logic_xsuit_activity:GetExchangeActivityID(), materInfo.exchangeList)
        end
        CommonMsgBoxMgr.Show(styleType, title, msg, clickOkCallback)
        return
      end
      local material = materInfo.materialList
      msg = LocUtil.LocalizeResFormat(18140176, material[1].needCount, material[2].needCount)
      function clickOkCallback()
        XSuitHandler.send_unlock_gold_dress_level_feature_req(self.selectPeriod, self.selectLevel, UnLockFeatureCfg.UnlockIndex, self.selectBranchId)
      end
      CommonMsgBoxMgr.Show(styleType, title, msg, clickOkCallback)
      return
    end
  end
  log(bWriteLog and "XSuit_Workshop_Upgrade_Component:OnClickSubUnlock not lock feature " .. tostring(self.selectPeriod) .. tostring(self.selectLevel) .. tostring(self.selectFeatureIndex))
end
function XSuit_Workshop_Upgrade_Component:OnClickSubUnlockGray()
  self:PlayAudio(sound_config.click_v1)
  if self.CurItemLevel < self.selectLevel then
    ShowNotice(LocUtil.LocalizeResFormat(200000048, self.selectLevel))
  else
    ShowNotice(48655)
  end
end
function XSuit_Workshop_Upgrade_Component:OnUnlockFeature()
  ShowNotice(200000028)
  self.upgradeMaterialInfo = {}
  self:RefreshOneLevelTab(self.selectLevel)
end
function XSuit_Workshop_Upgrade_Component:RefreshFreeUpgradeInfo()
  self:SetWidgetVisible(self.UIRoot.Button_FreeUpgrade, false)
  if self.bBranch then
    local branchId = LogicXSuit.GetActiveBranchIdByPeriod(self.selectPeriod)
    if branchId == nil then
      self.UIRoot.TextBlock_FreeUpgrade:SetText(LocUtil.GetLocalizeResStr(200000698))
      self:SetWidgetVisible(self.UIRoot.Button_FreeUpgrade, true, true)
    elseif branchId == self.selectBranchId then
      self.UIRoot.TextBlock_FreeUpgrade:SetText(LocUtil.GetLocalizeResStr(200000689))
      self:SetWidgetVisible(self.UIRoot.Button_FreeUpgrade, true, true)
      self:GetMaterialData(self.selectPeriod, self.selectBranchId, self.selectLevel)
    else
      self:SetWidgetVisible(self.UIRoot.Button_FreeUpgrade, false)
    end
  end
end
function XSuit_Workshop_Upgrade_Component:OnButtonClick_FreeUpgrade()
  self:PlayAudio(sound_config.click_v1)
  local branchId = LogicXSuit.GetActiveBranchIdByPeriod(self.selectPeriod)
  if branchId and branchId == self.selectBranchId then
    local TimeUtil = require("client.common.time_util")
    local weekStartTime = LogicXSuit.GetTaskStartTime(true)
    local weekEndTime = LogicXSuit.GetTaskEndTime(true)
    if weekStartTime == 0 or weekEndTime == 0 or TimeUtil.UnixTimeBetween(weekStartTime, weekEndTime) ~= 0 then
      ShowNotice(100330012)
      return
    end
    local seasonStartTime = LogicXSuit.GetTaskStartTime(false)
    local seasonStartEndTime = LogicXSuit.GetTaskEndTime(false)
    if seasonStartTime == 0 or seasonStartEndTime == 0 or TimeUtil.UnixTimeBetween(seasonStartTime, seasonStartEndTime) ~= 0 then
      ShowNotice(100330012)
      return
    end
    UIManager.ShowUI(UIManager.UI_Config.XSuit_Active_Mission_UIBP, self.selectPeriod, self.selectBranchId)
  elseif not branchId then
    UIManager.ShowUI(UIManager.UI_Config.XSuit_Select_Branch_UIBP, self.selectPeriod)
  end
end
function XSuit_Workshop_Upgrade_Component:RefreshByActiveBranch(_, _)
  self.upgradeMaterialInfo = {}
  self:CacheCurXSuitInfo()
  self:SetPeriodTabData()
end
function XSuit_Workshop_Upgrade_Component:ForceSelectBranch()
  local unlockBranchLits = LogicXSuit.GetUnlockedBranchIdListByPeriod(self.selectPeriod)
  if unlockBranchLits and 1 < #unlockBranchLits then
    local styleType, title, msg = 1, LocUtil.LocalizeResFormat(200000695), LocUtil.GetLocalizeResStr(200000770)
    local CommonMsgBoxMgr = require("client.slua.logic.common.logic_common_msg_box")
    CommonMsgBoxMgr.Show(styleType, title, msg, function()
      UIManager.ShowUI(UIManager.UI_Config.XSuit_Select_Branch_UIBP, self.selectPeriod)
    end, nil, LocUtil.GetLocalizeResStr(200000772), nil, {
      urlTips = LocUtil.GetLocalizeResStr(200000771)
    })
    return true
  end
  return false
end
function XSuit_Workshop_Upgrade_Component:FreeUpgradeByActiveBranch()
  local info = self:GetMaterialData(self.selectPeriod, self.selectBranchId, self.selectLevel)
  if not (info and next(info)) or not info.bUpgrade then
    log(bWriteLog and "XSuit_Workshop_Upgrade_Component:OnButtonClick_FreeUpgrade error")
    ShowNotice(9009)
    return
  end
  local CommonMsgBoxMgr = require("client.slua.logic.common.logic_common_msg_box")
  local styleType, title, msg, clickOkCallback, extraData = 2, LocUtil.LocalizeResFormat(5077), nil, nil, {}
  local logic_xsuit_activity = ModuleManager.GetModule(ModuleManager.JumpModuleConfig.logic_xsuit_activity)
  if info.bNeedMakeUp then
    if info.bCanMakeUp then
      if info.needCurrency > 0 then
        local costCurrency = CDataTable.GetTableData("Item", logic_xsuit_activity:GetDrawCurrencyID() or 1703269)
        extraData.explain = LocUtil.LocalizeResFormat(200000370, costCurrency.ItemName)
        msg = LocUtil.LocalizeResFormat(200000240, info.needCurrency)
        function clickOkCallback()
          XSuitHandler.send_do_onshot_exchange_by_activity_id_req(logic_xsuit_activity:GetExchangeActivityID(), info.exchangeList)
        end
        CommonMsgBoxMgr.Show(styleType, title, msg, clickOkCallback)
      else
        local itemID = LogicXSuit.GetItemIDByLevel(self.selectPeriod, self.selectLevel, self.selectBranchId)
        if not itemID then
          log(bWriteLog and "XSuit_Workshop_Upgrade_Component:FreeUpgradeByActiveBranch itemID error")
          return
        end
        UIManager.ShowUI(UIManager.UI_Config.XSuit_Active_Exchange_UIBP, info.makeUpList, itemID, function()
          if info.needCurrency <= 0 then
            return
          end
          local costCurrency = CDataTable.GetTableData("Item", logic_xsuit_activity:GetDrawCurrencyID() or 1703269)
          extraData.explain = LocUtil.LocalizeResFormat(200000370, costCurrency.ItemName)
          msg = LocUtil.LocalizeResFormat(200000240, info.needCurrency)
          function clickOkCallback()
            XSuitHandler.send_do_onshot_exchange_by_activity_id_req(logic_xsuit_activity:GetExchangeActivityID(), info.exchangeList)
          end
          CommonMsgBoxMgr.Show(styleType, title, msg, clickOkCallback)
        end)
      end
    else
      ShowNotice(9009)
    end
  else
    msg = LocUtil.LocalizeResFormat(200000810, info.materialList[1].needCount, info.materialList[2].needCount)
    function clickOkCallback()
      XSuitHandler.send_rise_star_req(self.selectPeriod, LogicXSuit.GetItemIDByPeriodSelf(self.selectPeriod, self.selectBranchId), self.selectBranchId)
    end
    CommonMsgBoxMgr.Show(styleType, title, msg, clickOkCallback)
  end
end
function XSuit_Workshop_Upgrade_Component:OnExchanged(_, _)
  self.upgradeMaterialInfo = {}
  self:UpdateMaterial()
end
function XSuit_Workshop_Upgrade_Component:SetMaterialList()
  if not self.CurUpgradeInfo then
    return
  end
  if self.UnlockType == 2 then
    local list = {}
    local multiCfg = xsuit_config_and_cache.GetMultiTypeUnlockConfigByPeriod(self.selectPeriod)
    local unlockLevel = multiCfg and multiCfg.unlock_level
    if not unlockLevel or unlockLevel > self.selectLevel then
      return list
    end
    return self:GetMaterialData(self.selectPeriod, self.selectBranchId, nil, nil, 1)
  elseif self.CurItemLevel > 0 and self.CurItemLevel < self.selectLevel then
    return self:GetMaterialData(self.selectPeriod, self.selectBranchId, self.selectLevel)
  end
end
function XSuit_Workshop_Upgrade_Component:SetMaterialData(period, branchId, level, featureIndex, state, materialInfo, bGlide)
  if period and branchId and level and featureIndex then
    self.upgradeMaterialInfo[period][branchId][level][featureIndex] = materialInfo
  elseif period and branchId and state then
    self.upgradeMaterialInfo[period][branchId].stateMaterialInfo = materialInfo
  elseif period and branchId and level and bGlide then
    self.upgradeMaterialInfo[period][branchId][level].glideMaterialInfo = materialInfo
  elseif period and branchId and level then
    self.upgradeMaterialInfo[period][branchId][level].levelMaterialInfo = materialInfo
  end
end
function XSuit_Workshop_Upgrade_Component:GetMaterialData(period, branchId, level, featureIndex, state, bGlide)
  self.upgradeMaterialInfo[period] = self.upgradeMaterialInfo[period] or {}
  self.upgradeMaterialInfo[period][branchId] = self.upgradeMaterialInfo[period][branchId] or {}
  if period and branchId and level and featureIndex then
    self.upgradeMaterialInfo[period][branchId][level] = self.upgradeMaterialInfo[period][branchId][level] or {}
    if self.upgradeMaterialInfo[period][branchId][level][featureIndex] then
      return self.upgradeMaterialInfo[period][branchId][level][featureIndex]
    else
      local info = LogicXSuit.BuildMaterialInfo(period, branchId, level, featureIndex)
      self:SetMaterialData(period, branchId, level, featureIndex, nil, info)
      return info
    end
  elseif period and branchId and state then
    if self.upgradeMaterialInfo[period][branchId].stateMaterialInfo then
      return self.upgradeMaterialInfo[period][branchId].stateMaterialInfo
    else
      local info = LogicXSuit.BuildMaterialInfo(period, branchId, nil, nil, state)
      self:SetMaterialData(period, branchId, nil, nil, state, info)
      return info
    end
  elseif period and branchId and level and bGlide then
    self.upgradeMaterialInfo[period][branchId][level] = self.upgradeMaterialInfo[period][branchId][level] or {}
    if self.upgradeMaterialInfo[period][branchId][level].glideMaterialInfo then
      return self.upgradeMaterialInfo[period][branchId][level].glideMaterialInfo
    else
      local info = LogicXSuit.BuildMaterialInfo(period, branchId, level, nil, nil, bGlide)
      self:SetMaterialData(period, branchId, level, nil, nil, info, bGlide)
      return info
    end
  elseif period and branchId and level then
    self.upgradeMaterialInfo[period][branchId][level] = self.upgradeMaterialInfo[period][branchId][level] or {}
    if self.upgradeMaterialInfo[period][branchId][level].levelMaterialInfo then
      return self.upgradeMaterialInfo[period][branchId][level].levelMaterialInfo
    else
      local info = LogicXSuit.BuildMaterialInfo(period, branchId, level)
      self:SetMaterialData(period, branchId, level, nil, nil, info)
      return info
    end
  end
end
local Trait = require("common.trait")
local TXSuit_Workshop_Upgrade_Component = Trait(Trait.TraitPrototype, nil, XSuit_Workshop_Upgrade_Component)
return TXSuit_Workshop_Upgrade_Component
