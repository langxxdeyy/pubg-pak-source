local tostring = tostring
local logic_theme_system = {}
local C_CurChestID = 15110001
function logic_theme_system:DefineAndResetData()
  self.ExchangeItemList = {}
  self.ExchangeNewTypeItemList = {}
  self.OfflineChestInfo = nil
  self.OfflineChestV2Info = nil
  self.lastSelectTab = nil
  self.exchangeNewType = 0
  self.ActivityExchangeID = 0
  self.bHasReqExchange = false
end
function logic_theme_system:OnPostSwitchGameStatus(preState, nextState)
  if nextState == GameStatus.Lobby then
    log(bWriteLog and "logic_theme_system:OnPostSwitchGameStatus")
    self:QueryOfflineChestV2Info()
    self:ReqExchangeActivity()
  end
end
function logic_theme_system:OnLogOut()
  self.bHasReqExchange = false
end
function logic_theme_system:SetLastSelectTab(tab)
  self.lastSelectTab = tab
  log(bWriteLog and "logic_theme_system:SetSelectTab " .. tab)
end
function logic_theme_system:GetLastSelectTab()
  log(bWriteLog and "logic_theme_system:GetSelectTab " .. tostring(self.lastSelectTab))
  return self.lastSelectTab
end
function logic_theme_system:SetOverviewPage(page)
  log(bWriteLog and "logic_theme_system:SetOverviewPage " .. tostring(page))
  self.lastOverviewPage = page
end
function logic_theme_system:GetOverviewPage()
  log(bWriteLog and "logic_theme_system:GetOverviewPage " .. tostring(self.lastOverviewPage))
  return self.lastOverviewPage
end
function logic_theme_system:CheckThemeSystemNew()
  local PlayerPrefsSystem = require("client.logic.LogicPlayerPrefs.playerprefs")
  local data = PlayerPrefsSystem.LoadFileToTable_N(PlayerPrefsSystem.ePlayerPrefsType.eThemeSystemNewMark)
  local ThemeConfig = require("client.slua.logic.theme_system.theme_config")
  local items = ThemeConfig.GetThemeSystemIntroduction()
  if not next(items) then
    log(bWriteLog and "logic_theme_system:CheckThemeSystemNew current theme is nil")
    return false
  end
  if not data or not next(data) then
    log(bWriteLog and string.format("logic_theme_system:CheckThemeSystemNew data is nil"))
    return true
  end
  for i, v in ipairs(items) do
    if not data[v.themeId] then
      return true
    end
  end
  log(bWriteLog and string.format("logic_theme_system:CheckThemeSystemNew show new red dot"))
  return false
end
function logic_theme_system:MarkNewForThemeSystem()
  local ThemeConfig = require("client.slua.logic.theme_system.theme_config")
  local items = ThemeConfig.GetThemeSystemIntroduction()
  local data = {}
  for i, v in ipairs(items) do
    data[v.themeId] = true
  end
  local PlayerPrefsSystem = require("client.logic.LogicPlayerPrefs.playerprefs")
  PlayerPrefsSystem.SaveTableToFile_N(data, PlayerPrefsSystem.ePlayerPrefsType.eThemeSystemNewMark)
end
function logic_theme_system:SetExchangeID(id)
  self.ActivityExchangeID = id
end
function logic_theme_system:GetExchangeID()
  return self.ActivityExchangeID
end
local formatItem = function(itemId, count, validTime)
  return string.format("%s_%s_%s", itemId, count, validTime)
end
function logic_theme_system:OnRespExchangeInfo(rs, exchange_table, mydata, activity_id)
  if rs ~= 0 then
    ShowNotice(rs)
    return
  end
  local ItemList = {}
  local NewList = {}
  local hasExchanges = mydata and mydata.new_limit_exchange_info or {}
  local redPointDeleteFlag = mydata and mydata.red_point_del_flag or {}
  local TimeUtil = require("client.common.time_util")
  local curTime = TimeUtil.GetServerTimeInSec()
  local MaxTaskCount = 9999999999
  for i, v in pairs(exchange_table) do
    local preTime = v.listing_time
    local endTime = v.delisting_time
    local sExchangeDataKey = formatItem(v.award_item_id, v.award_item_num, v.award_item_valid_time)
    local exchangeItem = {
      itemId = v.award_item_id,
      itemNum = v.award_item_num,
      needItemId = v.need_item_id,
      needItemNum = v.need_item_num,
      timeLimits = v.exchange_times_limit,
      iconCDNPath = v.award_picture_cdn,
      pos = v.pos_id,
      discount = v.discount,
      validTime = v.award_item_valid_time or 0,
      startTime = v.start_time or 0,
      hasExchangeCount = hasExchanges[sExchangeDataKey] or 0,
      exchange_sheet_id = v.exchange_sheet_id or 1001,
      original_price = v.original_price,
      isNew = v.is_new or false,
      newType = v.new_type or 0,
      listing_time = v.listing_time or 0,
      delisting_time = v.delisting_time or 0,
      bIsNoExchangeLimit = MaxTaskCount <= v.exchange_times_limit
    }
    if v.new_type and 0 < v.new_type and (not redPointDeleteFlag or not redPointDeleteFlag[sExchangeDataKey]) then
      if preTime then
        if curTime < endTime and curTime >= preTime then
          NewList[sExchangeDataKey] = v.new_type
        end
      else
        NewList[sExchangeDataKey] = v.new_type
      end
    end
    if preTime ~= nil and endTime ~= nil then
      if curTime < endTime and curTime >= preTime then
        table.insert(ItemList, exchangeItem)
      end
    else
      table.insert(ItemList, exchangeItem)
    end
  end
  local theme_system_reddot = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.theme_system_reddot)
  table.sort(ItemList, function(a, b)
    return a.pos < b.pos
  end)
  self.ExchangeItemList[activity_id] = ItemList
  self.ExchangeNewTypeItemList[activity_id] = NewList
  local num = 0
  for k, v in pairs(NewList) do
    num = num + 1
  end
  log(bWriteLog and "[zzw]logic_theme_system:ExchangeNewTypeItemList NewList num = " .. num)
  if next(self.ExchangeNewTypeItemList[activity_id]) then
    theme_system_reddot:SetExchangeNewReddot()
  else
    theme_system_reddot:CloseExchangeNewReddot()
  end
  EventSystem:postEvent(EVENTTYPE_THEME_SYSTEM, EVENTID_THEME_SYSTEM_EXCHANGE_REFRESH)
end
function logic_theme_system:UpdateExchangeInfo(rs, mydata, award_info, activity_id)
  if rs ~= 0 then
    ShowNotice(rs)
    return
  end
  if not self.ExchangeItemList then
    return
  end
  if not self.ExchangeItemList[activity_id] then
    return
  end
  local ItemList = self.ExchangeItemList[activity_id]
  local hasExchanges = mydata and mydata.new_limit_exchange_info or {}
  for i, v in pairs(ItemList) do
    v.hasExchangeCount = hasExchanges[formatItem(v.itemId, v.itemNum, v.validTime)] or 0
  end
  local arrayItemList = {}
  for i, v in pairs(award_info) do
    local arrayItem = {
      res_id = v.resid,
      expire_ts = v.expire_ts or 0,
      valid_hours = v.valid_hours or 0,
      count = v.count
    }
    table.insert(arrayItemList, arrayItem)
  end
  local Logic_CommonItemGet = require("client.slua.logic.common.CommonItemGet.Logic_CommonItemGet")
  Logic_CommonItemGet.ShowPanel_DefaultStyle(arrayItemList)
  local itemId = award_info and award_info[1] and award_info[1].resid
  EventSystem:postEvent(EVENTTYPE_THEME_SYSTEM, EVENTID_THEME_SYSTEM_EXCHANGE_REFRESH_LIMIT, itemId)
end
function logic_theme_system:GetExchangeItemList(tabType)
  local ThemeConfig = require("client.slua.logic.theme_system.theme_config")
  local filteredList = {}
  for k, v in ipairs(self.ExchangeItemList[self.ActivityExchangeID] or {}) do
    local itemData = CDataTable.GetTableData("Item", v.itemId)
    if itemData then
      if tabType == ThemeConfig.ExchangeTabType.Souvenir then
        if itemData.ItemType == ENUM_ITEM_TYPE.Consumables and itemData.ItemSubType == ENUM_ITEM_SUBTYPE.RightReleaseCollection then
          table.insert(filteredList, v)
        end
      elseif itemData.ItemType ~= ENUM_ITEM_TYPE.Consumables or itemData.ItemSubType ~= ENUM_ITEM_SUBTYPE.RightReleaseCollection then
        table.insert(filteredList, v)
      end
    end
  end
  return filteredList
end
function logic_theme_system:GetExchangeInfoList(tabType)
  local dataList = {}
  local exchangeList = self:GetExchangeItemList(tabType)
  for i, v in ipairs(exchangeList) do
    local tabId = v.exchange_sheet_id - 1000
    if not dataList[tabId] then
      dataList[tabId] = {}
    end
    table.insert(dataList[tabId], v)
  end
  for i, v in pairs(dataList) do
    table.sort(v, function(a, b)
      return a.pos < b.pos
    end)
  end
  log_tree(bWriteLog and "logic_theme_system:GetExchangeInfoList dataList", dataList)
  return dataList
end
function logic_theme_system:CheckThemeExchange(id)
  return id ~= nil and id == self.ActivityExchangeID
end
function logic_theme_system:ClearRedPointDataByFormatItemKey(formatItemKey)
  if not (self.ExchangeNewTypeItemList and self.ExchangeNewTypeItemList[self.ActivityExchangeID]) or not next(self.ExchangeNewTypeItemList[self.ActivityExchangeID]) then
    return
  end
  local currentList = self.ExchangeNewTypeItemList[self.ActivityExchangeID]
  if currentList[formatItemKey] then
    currentList[formatItemKey] = nil
  end
  if not next(currentList) then
    local theme_system_reddot = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.theme_system_reddot)
    theme_system_reddot:CloseExchangeNewReddot()
  end
end
function logic_theme_system:GetExchangeNewType()
  if not (self.ExchangeNewTypeItemList and self.ExchangeNewTypeItemList[self.ActivityExchangeID]) or not next(self.ExchangeNewTypeItemList[self.ActivityExchangeID]) then
    return 0
  end
  local currentList = self.ExchangeNewTypeItemList[self.ActivityExchangeID]
  local type1, type2, type3 = 0, 0, 0
  for formatItemKey, newType in pairs(currentList) do
    if newType == 1 then
      type1 = type1 + 1
    elseif newType == 2 then
      type2 = type2 + 1
    elseif newType == 3 then
      type3 = type3 + 1
    end
  end
  if 0 < type1 then
    return 1
  elseif 0 < type2 then
    return 2
  elseif 0 < type3 then
    return 3
  end
  return 0
end
function logic_theme_system:GetHasExchangeNew(formatKey)
  if not self.ExchangeNewTypeItemList or not next(self.ExchangeNewTypeItemList[self.ActivityExchangeID]) then
    return false
  end
  local currentList = self.ExchangeNewTypeItemList[self.ActivityExchangeID]
  if currentList[formatKey] then
    log(bWriteLog and "logic_theme_system:GetHasExchangeNew true")
    return true
  end
  log(bWriteLog and "logic_theme_system:GetHasExchangeNew false")
  return false
end
function logic_theme_system:ReqExchangeActivity()
  log(bWriteLog and "logic_theme_system:ReqExchangeActivity")
  if self.bHasReqExchange then
    log(bWriteLog and "logic_theme_system:ReqExchangeActivity has req")
    return
  end
  if not self.ActivityExchangeID or self.ActivityExchangeID == 0 then
    local ThemeConfig = require("client.slua.logic.theme_system.theme_config")
    self.ActivityExchangeID = ThemeConfig.GetThemeExchangeActivityID()
  end
  if self.ActivityExchangeID ~= 0 then
    self.bHasReqExchange = true
    local LuckybackHandler = require("client.network.Protocol.LuckybackHandler")
    LuckybackHandler.send_get_exchange_activity_info_req(self.ActivityExchangeID)
  else
    log(bWriteLog and "logic_theme_system:ReqExchangeActivity not exchangeID")
  end
end
function logic_theme_system:RefreshExchangeEffect()
  local theme_system_reddot = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.theme_system_reddot)
  if theme_system_reddot:HasNewRedDot() then
    return
  end
  local type = self:GetExchangeNewType()
  if not self.exchangeNewType or self.exchangeNewType ~= type then
    self.exchangeNewType = type
    self:AddTimerOnce(0, function()
      EventSystem:postEvent(EVENTTYPE_THEME_SYSTEM, EVENTID_THEME_SYSTEM_REFRESH_NEW_MARK)
    end)
  end
end
function logic_theme_system:CheckThemeExchangeStoreJump()
  local ui = UIManager.GetUI(UIManager.UI_Config.Theme_MainTab_UIBP)
  if ui and ui.subSystemHandle and ui.subSystemHandle.curSelectExchangeIndex and ui.subSystemHandle:IsGamePlayTab(ui.subSystemHandle.curSelectExchangeIndex) then
    return true
  end
end
function logic_theme_system:JumpModeDetails()
  if not self.ActivityExchangeID or self.ActivityExchangeID == 0 then
    local ThemeConfig = require("client.slua.logic.theme_system.theme_config")
    self.ActivityExchangeID = ThemeConfig.GetThemeExchangeActivityID()
  end
  if self.ActivityExchangeID ~= 0 then
    local config = CDataTable.GetTableData("ThemeExchangeConfig", self.ActivityExchangeID)
    if config then
      local themeViewId = config.ThemeViewID
      local logic_mode_selection = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_mode_selection)
      logic_mode_selection:OpenModeSelectionDetails(themeViewId)
    end
  end
end
function logic_theme_system:GetExchangeTabInfo()
  self.exchangeTabInfo = self.exchangeTabInfo or {
    [1] = {
      tabId = 1,
      tabName = LocUtil.GetLocalizeResStr(390138),
      helpTips = LocUtil.GetLocalizeResStr(390140)
    },
    [2] = {
      tabId = 2,
      tabName = LocUtil.GetLocalizeResStr(390139)
    }
  }
  return self.exchangeTabInfo
end
function logic_theme_system:CheckThemeOfflineChest(itemList)
  if itemList and #itemList == 1 then
    return itemList[1].res_id == C_CurChestID
  end
  return false
end
function logic_theme_system:GetOfflineChestInsID()
  local wardrobe_data = require("client.slua.logic.wardrobe.wardrobe_data")
  local tBagItemData = wardrobe_data:GetHallDepotItemDataByResIDAndTimeliness(C_CurChestID)
  if tBagItemData then
    return tBagItemData.insID
  end
  return ""
end
function logic_theme_system:GetOfflineChestCount()
  local wardrobe_data = require("client.slua.logic.wardrobe.wardrobe_data")
  local chestCount = wardrobe_data:GetHallDepotItemCountByResID(C_CurChestID)
  return chestCount
end
function logic_theme_system:UnpackOfflineChest()
  local insID = self:GetOfflineChestInsID()
  if insID ~= "" then
    local ThemeSystemHandler = require("client.network.Protocol.ThemeSystemHandler")
    ThemeSystemHandler.send_unpack_offline_chest_req(tonumber(insID))
  else
    log(bWriteLog and string.format("logic_theme_system:UnpackOfflineChest insID is nil"))
  end
end
function logic_theme_system:ReceiveUnpackOfflineChest(offline_chest_desc)
  log_tree(bWriteLog and "ReceiveUnpackOfflineChest", offline_chest_desc)
  self.OfflineChestInfo = offline_chest_desc
  EventSystem:postEvent(EVENTTYPE_THEME_SYSTEM, EVENTID_THEME_SYSTEM_RECEIVE_UNPACK_CHEST)
end
function logic_theme_system:QueryOfflineChestInfo()
  log(bWriteLog and "logic_theme_system:QueryOfflineChestInfo")
  local ThemeSystemHandler = require("client.network.Protocol.ThemeSystemHandler")
  ThemeSystemHandler.send_query_offline_chest_req()
end
function logic_theme_system:ReceiveOfflineChestInfo(offline_chest)
  log_tree(bWriteLog and "ReceiveOfflineChestInfo", offline_chest)
  local theme_system_reddot = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.theme_system_reddot)
  self.OfflineChestInfo = nil
  if offline_chest and offline_chest.slot then
    self.OfflineChestInfo = offline_chest.slot
    local TimeUtil = require("client.common.time_util")
    local curTime = TimeUtil.GetServerTimeInSec()
    local timeLeft = self.OfflineChestInfo.end_time - curTime
    if timeLeft <= 0 then
      theme_system_reddot:SetAwardRedDot()
      return
    end
  end
  theme_system_reddot:CloseAwardRedDot()
end
function logic_theme_system:GetOfflineChestInfo()
  return self.OfflineChestInfo
end
function logic_theme_system:CheckChestDisassemblyCompleted()
  if self.OfflineChestInfo then
    local TimeUtil = require("client.common.time_util")
    local curTime = TimeUtil.GetServerTimeInSec()
    local timeLeft = self.OfflineChestInfo.end_time - curTime
    return timeLeft <= 0
  end
  return false
end
function logic_theme_system:OpenChest()
  if self.OfflineChestInfo and self.OfflineChestInfo.inst_id then
    local ThemeSystemHandler = require("client.network.Protocol.ThemeSystemHandler")
    ThemeSystemHandler.send_open_offline_chest_req(tonumber(self.OfflineChestInfo.inst_id))
  end
end
function logic_theme_system:ReceiveAward(award_list)
  log_tree(bWriteLog and "logic_theme_system:ReceiveAward", award_list)
  EventSystem:postEvent(EVENTTYPE_THEME_SYSTEM, EVENTID_THEME_SYSTEM_RECEIVE_AWARD, award_list)
  EventSystem:postEvent(EVENTTYPE_CARD_COLLECTION, EVENTID_CARDCOLLECTION_FRAGMENT_UPDATE)
  self.OfflineChestInfo = nil
  local theme_system_reddot = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.theme_system_reddot)
  theme_system_reddot:CloseAwardRedDot()
end
function logic_theme_system:SetReddotAwardCountDown(time)
  if self.boxTimer then
    self:RemoveTimer(self.boxTimer)
    self.boxTimer = nil
  end
  self.boxTimer = self:AddTimerOnce(time, function()
    local theme_system_reddot = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.theme_system_reddot)
    theme_system_reddot:SetAwardRedDot()
  end)
end
function logic_theme_system:QueryOfflineChestV2Info()
  log(bWriteLog and "logic_theme_system:QueryOfflineChestV2Info")
  local ThemeSystemHandler = require("client.network.Protocol.ThemeSystemHandler")
  ThemeSystemHandler.send_get_offline_chest_v2_req()
end
function logic_theme_system:ReceiveOfflineChestV2Info(offline_chest_v2)
  log_tree(bWriteLog and "logic_theme_system:ReceiveOfflineChestV2Info", offline_chest_v2)
  self.OfflineChestV2Info = offline_chest_v2
end
function logic_theme_system:GetOfflineChestV2Info()
  return self.OfflineChestV2Info
end
function logic_theme_system:CheckOfflineChestV2CanOpen()
  local state = 0
  if self.OfflineChestV2Info then
    local consecutive_login_days = self.OfflineChestV2Info.consecutive_login_days or 0
    local open_times = self.OfflineChestV2Info.open_times or 0
    if 1 < consecutive_login_days then
      if 0 < open_times then
        state = 2
      elseif open_times == 0 then
        state = 1
      end
    end
    log(bWriteLog and string.format("logic_theme_system:CheckOfflineChestV2CanOpen consecutive_login_days = %d, open_times = %d, state = %d", consecutive_login_days, open_times, state))
    return state
  end
  log(bWriteLog and "logic_theme_system:CheckOfflineChestV2CanOpen OfflineChestV2Info is nil")
  return state
end
function logic_theme_system:OpenChestV2()
  log(bWriteLog and "logic_theme_system:OpenChestV2")
  if self:CheckOfflineChestV2CanOpen() == 1 then
    local ThemeSystemHandler = require("client.network.Protocol.ThemeSystemHandler")
    ThemeSystemHandler.send_open_offline_chest_v2_req()
  else
    log(bWriteLog and "logic_theme_system:OpenChestV2 cannot open, check condition failed")
  end
end
function logic_theme_system:ReceiveOfflineChestV2Award(award_list, offline_chest_v2)
  log_tree(bWriteLog and "logic_theme_system:ReceiveOfflineChestV2Award award_list", award_list)
  log_tree(bWriteLog and "logic_theme_system:ReceiveOfflineChestV2Award offline_chest_v2", offline_chest_v2)
  EventSystem:postEvent(EVENTTYPE_THEME_SYSTEM, EVENTID_THEME_SYSTEM_RECEIVE_AWARD, award_list)
  EventSystem:postEvent(EVENTTYPE_CARD_COLLECTION, EVENTID_CARDCOLLECTION_FRAGMENT_UPDATE)
  self.OfflineChestV2Info = offline_chest_v2
  log(bWriteLog and "logic_theme_system:ReceiveOfflineChestV2Award award received, red dot closed")
end
function logic_theme_system:GetExchangeStoreTabList()
  local ThemeConfig = require("client.slua.logic.theme_system.theme_config")
  local tabList = {
    {
      panelType = ThemeConfig.ExchangeTabType.Other,
      activePath = "/Game/UMG/Texture_200/Atlas/Theme/Frames/Theme_Tab_Like_Select_png.Theme_Tab_Like_Select_png",
      inactivePath = "/Game/UMG/Texture_200/Atlas/Theme/Frames/Theme_Tab_Like_png.Theme_Tab_Like_png"
    }
  }
  local PublishRegionMacros = require("client.slua.config.ClientMacros.PublishRegionMacros")
  if not PublishRegionMacros.IsBlueholeFamily() then
    local souvenirTabInfo = {
      panelType = ThemeConfig.ExchangeTabType.Souvenir,
      activePath = "/Game/UMG/Texture_200/Atlas/Theme/Frames/Theme_Tab_Collection_Select_png.Theme_Tab_Collection_Select_png",
      inactivePath = "/Game/UMG/Texture_200/Atlas/Theme/Frames/Theme_Tab_Collection_png.Theme_Tab_Collection_png"
    }
    table.insert(tabList, souvenirTabInfo)
  end
  return tabList
end
function logic_theme_system:CheckNextVersionPreheatRedDot()
  log(bWriteLog and "logic_theme_system:CheckNextVersionPreheatRedDot")
  local ThemeConfig = require("client.slua.logic.theme_system.theme_config")
  local config = ThemeConfig.GetThemeSystemConfig()
  if not config then
    log(bWriteLog and "logic_theme_system:CheckNextVersionPreheatRedDot theme config is nil")
    return false
  end
  local PlayerPrefsSystem = require("client.logic.LogicPlayerPrefs.playerprefs")
  local data = PlayerPrefsSystem.LoadFileToTable_N(PlayerPrefsSystem.ePlayerPrefsType.eThemeSystemSubRedDot)
  local version_util = require("client.common.version_util")
  local curVersion = version_util.GetCurVersionNumber()
  if data and data[curVersion] then
    local themePrefs = data[curVersion]
    local ThemeConfig = require("client.slua.logic.theme_system.theme_config")
    if themePrefs[ThemeConfig.ThemeRedDotType.NextVersionPreheat] then
      log(bWriteLog and "logic_theme_system:CheckNextVersionPreheatRedDot next version preheat red dot is triggered")
      return false
    end
  end
  if ThemeConfig.GetThemeActivityState() == ThemeConfig.ThemeActivityState.Preheat then
    log(bWriteLog and "logic_theme_system:CheckNextVersionPreheatRedDot in time!")
    return true
  end
  return false
end
function logic_theme_system:ClearNextVersionPreheatRedDot()
  log(bWriteLog and "logic_theme_system:ClearNextVersionPreheatRedDot")
  local ThemeConfig = require("client.slua.logic.theme_system.theme_config")
  local config = ThemeConfig.GetThemeSystemConfig()
  if not config then
    log(bWriteLog and "logic_theme_system:ClearNextVersionPreheatRedDot theme config is nil")
    return
  end
  local version_util = require("client.common.version_util")
  local curVersion = version_util.GetCurVersionNumber()
  local PlayerPrefsSystem = require("client.logic.LogicPlayerPrefs.playerprefs")
  local data = PlayerPrefsSystem.LoadFileToTable_N(PlayerPrefsSystem.ePlayerPrefsType.eThemeSystemSubRedDot) or {}
  if not data[curVersion] then
    data[curVersion] = {}
  end
  data[curVersion][ThemeConfig.ThemeRedDotType.NextVersionPreheat] = 1
  PlayerPrefsSystem.SaveTableToFile_N(data, PlayerPrefsSystem.ePlayerPrefsType.eThemeSystemSubRedDot)
end
function logic_theme_system:CheckMidTermActivityPreheatRedDot()
  log(bWriteLog and "logic_theme_system:CheckMidTermActivityPreheatRedDot")
  local ThemeConfig = require("client.slua.logic.theme_system.theme_config")
  local config = ThemeConfig.GetThemeSystemConfig()
  if not config then
    log(bWriteLog and "logic_theme_system:CheckMidTermActivityPreheatRedDot theme config is nil")
    return false
  end
  local themeID = config.ThemeId
  if not themeID or themeID == 0 then
    log(bWriteLog and "logic_theme_system:CheckMidTermActivityPreheatRedDot themeID is invalid")
    return false
  end
  local PlayerPrefsSystem = require("client.logic.LogicPlayerPrefs.playerprefs")
  local recordData = PlayerPrefsSystem.LoadFileToTable_N(PlayerPrefsSystem.ePlayerPrefsType.eThemeMapIconAnimRecord) or {}
  local version_util = require("client.common.version_util")
  local curVersion = version_util.GetCurVersionNumber()
  local midTermActivityConfig = ThemeConfig.GetOperationActivityConfig()
  if not midTermActivityConfig then
    log(bWriteLog and "logic_theme_system:CheckMidTermActivityPreheatRedDot midTermActivityConfig is nil")
    return false
  end
  if recordData[curVersion] and recordData[curVersion][midTermActivityConfig.ID] then
    log(bWriteLog and "logic_theme_system:CheckMidTermActivityPreheatRedDot midTermActivityConfig red dot is triggered")
    return false
  end
  log(bWriteLog and "logic_theme_system:CheckMidTermActivityPreheatRedDot has midTermActivityConfig red dot")
  return true
end
function logic_theme_system:CheckTaskFinishedRedDot()
  log(bWriteLog and "logic_theme_system:CheckTaskFinishedRedDot")
  local logic_theme_task = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_theme_task)
  return logic_theme_task:NeedShowTaskReddot()
end
function logic_theme_system:CheckCurThemeActOpenRedDot()
  log(bWriteLog and "logic_theme_system:CheckCurThemeActOpenRedDot")
  local ThemeConfig = require("client.slua.logic.theme_system.theme_config")
  local IsOpen = ThemeConfig.GetThemeActivityState() == ThemeConfig.ThemeActivityState.Online
  if not IsOpen then
    log(bWriteLog and "logic_theme_system:CheckCurThemeActOpenRedDot theme activity is not online")
    return false
  end
  local jumpUrl = self:GetCurThemeActURL()
  if jumpUrl == "" then
    log(bWriteLog and "logic_theme_system:CheckCurThemeActOpenRedDot jumpUrl is empty")
    return false
  end
  local PlayerPrefsSystem = require("client.logic.LogicPlayerPrefs.playerprefs")
  local data = PlayerPrefsSystem.LoadFileToTable_N(PlayerPrefsSystem.ePlayerPrefsType.eThemeSystemActNewMark) or {}
  if data[jumpUrl] then
    log(bWriteLog and "logic_theme_system:CheckCurThemeActOpenRedDot red dot already shown for url: " .. jumpUrl)
    return false
  end
  log(bWriteLog and "logic_theme_system:CheckCurThemeActOpenRedDot should show red dot for url: " .. jumpUrl)
  return true
end
function logic_theme_system:ClearCurThemeActOpenRedDot()
  log(bWriteLog and "logic_theme_system:ClearCurThemeActOpenRedDot")
  local ThemeConfig = require("client.slua.logic.theme_system.theme_config")
  local IsOpen = ThemeConfig.GetThemeActivityState() == ThemeConfig.ThemeActivityState.Online
  if not IsOpen then
    log(bWriteLog and "logic_theme_system:ClearCurThemeActOpenRedDot theme activity is not online")
    return
  end
  local jumpUrl = self:GetCurThemeActURL()
  if jumpUrl == "" then
    log(bWriteLog and "logic_theme_system:ClearCurThemeActOpenRedDot jumpUrl is empty")
    return
  end
  local data = {}
  data[jumpUrl] = true
  local PlayerPrefsSystem = require("client.logic.LogicPlayerPrefs.playerprefs")
  PlayerPrefsSystem.SaveTableToFile_N(data, PlayerPrefsSystem.ePlayerPrefsType.eThemeSystemActNewMark)
  log(bWriteLog and "logic_theme_system:ClearCurThemeActOpenRedDot red dot cleared for url: " .. jumpUrl)
end
function logic_theme_system:CheckCurThemeActRewardRedDot()
  log(bWriteLog and "logic_theme_system:CheckCurThemeActRewardRedDot")
  local jumpUrl = self:GetCurThemeActURL()
  if jumpUrl == "" then
    log(bWriteLog and "logic_theme_system:CheckCurThemeActRewardRedDot jumpUrl is empty")
    return false
  end
  local JumpUtils = require("client.logic.store.jump_utils")
  local actID = self:GetThemeActIdByUrl(jumpUrl)
  if JumpUtils.IsPanDoraJumpUrl(jumpUrl) then
    log(bWriteLog and "logic_theme_system:CheckCurThemeActRewardRedDot processing pandora jump url")
    local pandoraLogic = require("client.slua.logic.Pandora.pandora_logic")
    if pandoraLogic.ActHasRedPoint(actID) then
      log(bWriteLog and "logic_theme_system:CheckCurThemeActRewardRedDot pandora activity has red point")
      return true
    end
  elseif JumpUtils.IsGameJumpUrl(jumpUrl) then
    log(bWriteLog and "logic_theme_system:CheckCurThemeActRewardRedDot processing game jump url")
    local ActivityNewSystem = require("client.slua.logic.activity.logic_activity_mgr")
    local activityData = ActivityNewSystem.GetActivityByID(actID)
    if activityData and activityData.status == 1 then
      log(bWriteLog and "logic_theme_system:CheckCurThemeActRewardRedDot game activity has rewards")
      return true
    end
  end
  log(bWriteLog and "logic_theme_system:CheckCurThemeActRewardRedDot no reward red dot found")
  return false
end
function logic_theme_system:GetThemeActIdByUrl(jumpUrl)
  local actID = 0
  local JumpUtils = require("client.logic.store.jump_utils")
  if JumpUtils.IsPanDoraJumpUrl(jumpUrl) then
    log(bWriteLog and "logic_theme_system:CheckCurThemeActRewardRedDot processing pandora jump url")
    local pandoraUtils = require("client.slua.logic.Pandora.pandora_utils")
    actID = pandoraUtils.GetActIdByUrl(jumpUrl)
    log_format("logic_theme_system:CheckCurThemeActRewardRedDot pandora actID: %d", actID)
  elseif JumpUtils.IsGameJumpUrl(jumpUrl) then
    log(bWriteLog and "logic_theme_system:CheckCurThemeActRewardRedDot processing game jump url")
    local webModule = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.webModule)
    jumpUrl = string.lower(jumpUrl)
    jumpUrl = webModule:URLDecode(jumpUrl)
    jumpUrl = GlobalData.PreprocessUrl(jumpUrl)
    local StringUtil = require("common.string_util")
    local params = StringUtil.ParseURLParams(jumpUrl)
    actID = tonumber(params.id)
    log_format("logic_theme_system:CheckCurThemeActRewardRedDot game actID: %d", actID)
  end
  return actID
end
function logic_theme_system:GetCurThemeActURL()
  log(bWriteLog and "logic_theme_system:GetCurThemeActURL")
  local theme_config = require("client.slua.logic.theme_system.theme_config")
  local config = theme_config.GetThemeSystemConfig()
  if not config then
    log(bWriteLog and "logic_theme_system:GetCurThemeActURL config is nil")
    return ""
  end
  self.curActivityURL = ""
  local themeID = config.themeId
  self.curActivityURL = theme_config.GetCurrentThemeActivityJump(themeID) or ""
  log_format("logic_theme_system:GetCurThemeActURL themeID: %d, url: %s", themeID, self.curActivityURL)
  return self.curActivityURL
end
function logic_theme_system:on_get_global_magic_tree_percent_rsp(err_code, ret_tbl)
  if err_code == 0 then
    self.magicTreeInfo = ret_tbl
    EventSystem:postEvent(EVENTTYPE_THEME_SYSTEM, EVENTID_THEME_SYSTEM_MAGIC_TREE_INFO_RSP)
  else
    ShowNotice(err_code)
  end
end
function logic_theme_system:GetMagicTreeInfo()
  return self.magicTreeInfo
end
function logic_theme_system:on_get_magic_tree_stat_rsp(plant_info, watering_info)
  for _, v in pairs(plant_info) do
    if v.location and next(v.location) and not v.progress then
      v.progress = 0
    end
  end
  log_tree(bWriteLog and "logic_theme_system.on_get_magic_tree_stat_rsp plant_info = ", plant_info)
  self.plant_info = plant_info
end
function logic_theme_system:send_get_magic_tree_stat_req()
  local ThemeSystemHandler = require("client.network.Protocol.ThemeSystemHandler")
  ThemeSystemHandler.send_get_magic_tree_stat_req()
end
function logic_theme_system:GetAllPlantInfo()
  return self.plant_info or {}
end
function logic_theme_system:GetSinglePlantInfo(plant_key)
  return self.plant_info and self.plant_info[plant_key] or {}
end
local class = require("class")
local CModuleBase = require("client.module_framework.ModuleBase")
local CModuleTemplate = class(CModuleBase, nil, logic_theme_system)
return CModuleTemplate
