local LogicXSuit = {
  baseInfo = {},
  upgradeInfo = {},
  workshopTabData = nil,
  unlockFeatureInfo = nil,
  switchLevel = nil,
  stateInfo = nil,
  levelAction = nil,
  FeatureSwitch = {},
  EliminationKingClothOverrideEnabled = nil,
  _FetchingEliminationKingOverride = false,
  _PendingElimOverrideRecheckOnLevel6 = false,
  condtion = {},
  gridExchangeData = {},
  itemInfoList = {},
  needShowRelicID = 0,
  needShowRelicUid = 0,
  relicInfoList = {},
  inviteActionMap = nil,
  actionPeriodMap = {},
  lastSendInviteTime = 0,
  openUpgrade = false,
  playerEquipItemID = 0,
  shareTimeList = {},
  currencyIconPath = nil,
  materialItemIDMap = {},
  unlockStateMatMap = {},
  needPlayActionMember = {},
  playedActionUidMap = {},
  bVersionInit = false,
  equip_data = {},
  activeBranchInfo = {},
  reddotData = {},
  MaterialCommon2Active = nil,
  XSuitWardrobeBranchData = {},
  UpgradeDiscount = {},
  collectInfo = {},
  task_conf_info = {},
  task_status_info = {},
  task_info = {
    week_id = 1,
    season_id = 1,
    week_info = {
      [1] = {start_time = 0, end_time = 0}
    },
    season_info = {
      [1] = {start_time = 0, end_time = 0}
    }
  }
}
local PufferConst = require("client.slua.logic.download.puffer_const")
local PufferManager = require("client.slua.logic.download.puffer.puffer_manager")
local LogicXSuitConfig = require("client.slua.logic.XSuit.logic_xsuit_config")
local xsuit_config_and_cache = require("client.slua.logic.XSuit.xsuit_config_and_cache")
local XSuitHandler = require("client.network.Protocol.XSuitHandler")
local ui_show_queue_config = require("client.common.uibase.ui_show_queue_config")
local maxFeatureCount = 5
local GiftTipSortWeightOffset = {Tarot = -0.2, SmallRP = -0.1}
function LogicXSuit.GetConfig(key)
  if key then
    return LogicXSuitConfig[key]
  end
end
function LogicXSuit.OnLogin(bReLogin)
  if not bReLogin or LogicXSuit.openUpgrade == false then
    LogicXSuit.openUpgrade = LobbySystem.CheckLobbyMenuOpen(BP_ENUM_LOBBY_MENU_XSUIT_WORK_SHOP, false)
    log(bWriteLog and "LogicXSuit.openUpgrade = " .. tostring(LogicXSuit.openUpgrade))
    XSuitHandler.send_get_rise_star_info_req()
    XSuitHandler.send_get_gold_dress_new_level_req()
    LogicXSuit.stateInfo = nil
    LogicXSuit.SendGetGoldDressStateReq()
    XSuitHandler.send_gold_dress_get_branch_switch_info_req()
    XSuitHandler.send_gold_dress_branch_personal_info_req()
    LogicXSuit.InitRedotData()
  end
end
function LogicXSuit.OnModePreSwitch(_, currentStatus)
  if not GameStatus.IsInLobbyOrMainCity() then
    LogicXSuit.needPlayActionMember = {}
  end
end
function LogicXSuit.InitWorkshopTabData()
  LogicXSuit.workshopTabData = {}
  local config = xsuit_config_and_cache.GetVersionArgConfig()
  local version = config.MAX_PERIOD or 1
  for i = 1, version do
    local info, bBranch, BranchId = LogicXSuit.GetBaseInfo(i)
    if not info then
      break
    end
    local uiCfg = LogicXSuit.GetUpgradeUIInfo(i)
    local scrollInfo = {
      period = i,
      imagePath = uiCfg and uiCfg.ItemImagePath
    }
    if bBranch and not BranchId then
      scrollInfo.branchList = {}
      for index = 0, #info do
        uiCfg = LogicXSuit.GetBranchUIInfo(i, index)
        local commonCfg = LogicXSuit.GetUpgradeUIInfoByBranchId(i, index)
        local _ = uiCfg and commonCfg and table.insert(scrollInfo.branchList, {
          period = i,
          imagePath = uiCfg.ItemImagePath,
          Branch = uiCfg.BranchId,
          BranchName = commonCfg.BranchName
        })
      end
    end
    table.insert(LogicXSuit.workshopTabData, scrollInfo)
  end
  table.sort(LogicXSuit.workshopTabData, function(a, b)
    return a.period > b.period
  end)
end
function LogicXSuit.InitXSuitBaseInfo(period)
  if LogicXSuit.baseInfo[period] then
    return
  end
  local cfg = CDataTable.GetTableByFilter("GoldenSuitUpgradeCfg", "Period", period)
  for _, j in pairs(cfg) do
    LogicXSuit._InitOneBaseInfo(j)
    LogicXSuit._InitOneUpgradeInfo(j)
  end
end
function LogicXSuit._InitOneUpgradeInfo(data)
  if LogicXSuit.upgradeInfo[data.Period] == nil then
    LogicXSuit.upgradeInfo[data.Period] = {}
  end
  if LogicXSuit.upgradeInfo[data.Period][data.BranchId] == nil then
    LogicXSuit.upgradeInfo[data.Period][data.BranchId] = {}
  end
  LogicXSuit.materialItemIDMap[data.MatID1] = true
  LogicXSuit.materialItemIDMap[data.MatID2] = true
  if data.SecondMatID > 0 and not LogicXSuit.unlockStateMatMap[data.SecondMatID] then
    LogicXSuit.unlockStateMatMap[data.SecondMatID] = data.Period
  end
  if 0 < data.ActiveID2 and not LogicXSuit.unlockStateMatMap[data.ActiveID2] then
    LogicXSuit.unlockStateMatMap[data.ActiveID2] = data.Period
  end
  if 0 < data.ActiveID1 and not LogicXSuit.unlockStateMatMap[data.ActiveID1] then
    LogicXSuit.unlockStateMatMap[data.ActiveID1] = data.Period
  end
  if 0 < data.BackID2 and not LogicXSuit.unlockStateMatMap[data.BackID2] then
    LogicXSuit.unlockStateMatMap[data.BackID2] = data.Period
  end
  if 0 < data.BackID1 and not LogicXSuit.unlockStateMatMap[data.BackID1] then
    LogicXSuit.unlockStateMatMap[data.BackID1] = data.Period
  end
  local info = {
    cfg = data,
    item_id = data.ItemID,
    tab_name_array = {
      data.SubTabID1,
      data.SubTabID2,
      data.SubTabID3,
      data.SubTabID4,
      data.SubTabID5
    },
    tab_desc_array = {
      data.TabDesc1,
      data.TabDesc2,
      data.TabDesc3,
      data.TabDesc4,
      data.TabDesc5
    },
    effect_id_array = {
      data.Effect1,
      data.Effect2,
      data.Effect3,
      data.Effect4,
      data.Effect5
    }
  }
  info.featureList = {}
  for i = 1, 5 do
    local featureId = data["SubTabID" .. i]
    if featureId and 0 < featureId then
      table.insert(info.featureList, {
        tabId = data["SubTabID" .. i],
        desc = data["TabDesc" .. i],
        effectId = data["Effect" .. i]
      })
    end
  end
  LogicXSuit.upgradeInfo[data.Period][data.BranchId][data.Star] = info
end
function LogicXSuit._InitOneBaseInfo(data)
  if LogicXSuit.baseInfo[data.Period] == nil then
    LogicXSuit.baseInfo[data.Period] = {}
  end
  if LogicXSuit.baseInfo[data.Period][data.BranchId] == nil then
    LogicXSuit.baseInfo[data.Period][data.BranchId] = {}
  end
  local info = LogicXSuit.baseInfo[data.Period][data.BranchId]
  if data.RelicID ~= 0 and data.RelicID ~= "" then
    info.relic_id = data.RelicID
  end
  if data.Star == 1 then
    info.item_id = data.ItemID
  end
  if info.max_level == nil or data.Star > info.max_level then
    info.max_level = data.Star
    info.max_item_id = data.ItemID
  end
  if data.ActID ~= 0 then
    info.act_id = data.ActID
  end
end
function LogicXSuit.InitXSuitItemList(itemId)
  if not next(LogicXSuit.itemInfoList) then
    local GoldenSuitUpgradeCfg = CDataTable.GetTable("GoldenSuitUpgradeCfg")
    for _, data in pairs(GoldenSuitUpgradeCfg) do
      LogicXSuit.itemInfoList[data.ItemID] = {
        period = data.Period,
        level = data.Star,
        BranchId = data.BranchId
      }
    end
  end
end
function LogicXSuit.InitRedotData()
  local PlayerPrefsSystem = require("client.logic.LogicPlayerPrefs.playerprefs")
  local redPointData = PlayerPrefsSystem.LoadFileToTable_N(PlayerPrefsSystem.ePlayerPrefsType.eGoldenSuitLotteryRedPoint)
  log_tree(bWriteLog and "LogicXSuit.InitRedotData redPointData = ", redPointData)
  local config = xsuit_config_and_cache.GetVersionArgConfig()
  local maxPeriod = config.MAX_PERIOD or 16
  LogicXSuit.reddotData = {version = maxPeriod}
  if redPointData then
    if not redPointData.version or 16 > redPointData.version then
      redPointData.version = nil
      local branchId = 0
      for period, reddot in pairs(redPointData) do
        LogicXSuit.reddotData[period] = {
          [branchId] = {
            version = reddot.version
          },
          version = reddot.version
        }
        reddot.version = nil
        for key, value in pairs(reddot) do
          LogicXSuit.reddotData[period][branchId][key] = value
        end
      end
      LogicXSuit.SetReddotCache()
    else
      LogicXSuit.reddotData = redPointData
    end
  end
  log_tree(bWriteLog and "LogicXSuit.InitRedotData LogicXSuit.reddotData = ", LogicXSuit.reddotData)
end
function LogicXSuit.InitInviteAction()
  LogicXSuit.inviteActionMap = {}
  local cfg = CDataTable.GetTable("GoldenSuitMapCfg")
  local StringUtil = require("common.string_util")
  for _, j in pairs(cfg) do
    local inviteeActionIDStrList = StringUtil.Split(j.InviteeActionID, "|")
    local inviteeActionIDList = {}
    for _, v in pairs(inviteeActionIDStrList) do
      local inviteeActionID = tonumber(v)
      if inviteeActionID then
        table.insert(inviteeActionIDList, inviteeActionID)
        LogicXSuit.actionPeriodMap[inviteeActionID] = {
          Period = j.Period,
          BranchId = j.BranchId
        }
      end
    end
    LogicXSuit.inviteActionMap[j.InviterActionID] = inviteeActionIDList
    LogicXSuit.actionPeriodMap[j.InviterActionID] = {
      Period = j.Period,
      BranchId = j.BranchId
    }
  end
end
function LogicXSuit.GetWorkshopTabData()
  if not LogicXSuit.workshopTabData then
    LogicXSuit.InitWorkshopTabData()
  end
  local TableUtil = require("common.table_util")
  local newInfo = TableUtil.FastCopyTable(LogicXSuit.workshopTabData)
  local maxPeriod = LogicXSuit.GetMaxPeriod()
  for i = #newInfo, 1, -1 do
    local info = newInfo[i]
    if maxPeriod < info.period then
      table.remove(newInfo, i)
    elseif info.branchList then
      for j = #info.branchList, 1, -1 do
        local branchInfo = info.branchList[j]
        if not LogicXSuit.IsBranchOpen(info.period, branchInfo.Branch) then
          table.remove(info.branchList, j)
        end
      end
    end
  end
  return newInfo
end
function LogicXSuit.GetMaxPeriod()
  for i = #LogicXSuit.shareTimeList, 1, -1 do
    if LogicXSuit.IsBranchOpen(i, 0) then
      return i
    end
  end
  return 0
end
function LogicXSuit.GetReddotCacheByPeriod(period)
  return LogicXSuit.reddotData[period] and LogicXSuit.reddotData[period].version
end
function LogicXSuit.GetReddotCacheByBranchId(period, branchId)
  return LogicXSuit.reddotData[period] and LogicXSuit.reddotData[period][branchId] and LogicXSuit.reddotData[period][branchId].version
end
function LogicXSuit.GetReddotCacheByLevel(period, branchId, level)
  return LogicXSuit.reddotData[period] and LogicXSuit.reddotData[period][branchId] and LogicXSuit.reddotData[period][branchId][level] and LogicXSuit.reddotData[period][branchId][level].version
end
function LogicXSuit.GetReddotCacheByFeature(period, branchId, level, index)
  return LogicXSuit.reddotData[period] and LogicXSuit.reddotData[period][branchId] and LogicXSuit.reddotData[period][branchId][level] and LogicXSuit.reddotData[period][branchId][level][index] and LogicXSuit.reddotData[period][branchId][level][index].version
end
function LogicXSuit.GetActiveBranchIdByPeriod(period)
  return LogicXSuit.activeBranchInfo[period] and LogicXSuit.activeBranchInfo[period].branch_id or nil
end
function LogicXSuit.GetUnlockedBranchIdListByPeriod(period)
  local periodInfo = LogicXSuit.shareTimeList[period]
  if periodInfo then
    local branchIdList = {}
    for i = 0, #periodInfo do
      local branchInfo = periodInfo[i]
      if branchInfo and branchInfo.unlock_flag then
        table.insert(branchIdList, i)
      end
    end
    return branchIdList
  end
end
function LogicXSuit.GetUpgradeBranchIdAndLevelByPeriod(period)
  local branchIdList = LogicXSuit.GetUnlockedBranchIdListByPeriod(period)
  for _, id in ipairs(branchIdList or {}) do
    local level = LogicXSuit.GetLevelByPeriodSelf(period, id)
    local upgradeInfo = LogicXSuit.GetUpgradeInfo(period, true, id)
    if 0 < level and level < #upgradeInfo then
      return id, level
    end
  end
end
function LogicXSuit.GetSuitItemIDByPeriod(period, branchId)
  if period then
    local info = LogicXSuit.GetBaseInfo(period, true, branchId)
    if info then
      return info.item_id, info.max_item_id
    end
  end
end
function LogicXSuit.GetPeriodByItemId(itemID)
  LogicXSuit.InitXSuitItemList(itemID)
  if LogicXSuit.itemInfoList[itemID] then
    return LogicXSuit.itemInfoList[itemID].period
  end
  return nil
end
function LogicXSuit.GetBranchByItemId(itemID)
  LogicXSuit.InitXSuitItemList(itemID)
  if LogicXSuit.itemInfoList[itemID] then
    return LogicXSuit.itemInfoList[itemID].BranchId
  end
  return nil
end
function LogicXSuit.GetLevelByItemId(itemID)
  LogicXSuit.InitXSuitItemList(itemID)
  if LogicXSuit.itemInfoList[itemID] then
    return LogicXSuit.itemInfoList[itemID].level
  end
  return nil
end
function LogicXSuit.GetItemIDByLevel(period, level, branchId)
  local cfgList = LogicXSuit.GetUpgradeInfo(tonumber(period), true, branchId)
  if cfgList and cfgList[level] then
    return cfgList[level].item_id
  end
end
function LogicXSuit.GetLevelByPeriod(period, source, branch_id)
  branch_id = branch_id or 0
  local info = LogicXSuit.GetUpgradeInfo(period, true, branch_id)
  if info then
    local level = 0
    for i, data in pairs(info) do
      local wardrobe_data = require("client.slua.logic.wardrobe.wardrobe_data")
      if wardrobe_data:GetHallDepotItemDataByResIDAndSource(data.item_id, source) ~= nil then
        level = i
      end
    end
    return level
  else
    return 0
  end
end
function LogicXSuit.GetLevelByPeriodSelf(period, branch_id)
  branch_id = branch_id or 0
  local periodInfo = LogicXSuit.shareTimeList and LogicXSuit.shareTimeList[period]
  local branchInfo = periodInfo and periodInfo[branch_id]
  return branchInfo and branchInfo.unlock_flag and branchInfo.current or 0
end
function LogicXSuit.GetItemIDByPeriod(period, source, branch_id)
  branch_id = branch_id or 0
  if not source then
    return LogicXSuit.GetItemIDByPeriodSelf(period, branch_id)
  end
  local level = LogicXSuit.GetLevelByPeriod(period, source, branch_id)
  if level then
    local upgradeInfo = LogicXSuit.GetUpgradeInfo(period, true, branch_id)
    return upgradeInfo[level].item_id
  end
  return nil
end
function LogicXSuit.GetItemIDByPeriodSelf(period, branch_id)
  branch_id = branch_id or 0
  local periodInfo = LogicXSuit.shareTimeList and LogicXSuit.shareTimeList[period]
  local branchInfo = periodInfo and periodInfo[branch_id]
  if branchInfo and branchInfo.unlock_flag and branchInfo.current then
    return LogicXSuit.GetItemIDByLevel(period, branchInfo.current, branch_id)
  end
end
function LogicXSuit.GetShareTime(itemId)
  local period = LogicXSuit.GetPeriodByItemId(itemId)
  if not period then
    return nil
  end
  local branchId = LogicXSuit.GetBranchByItemId(itemId)
  local level = LogicXSuit.GetLevelByItemId(itemId)
  local data = LogicXSuit.shareTimeList[period] and LogicXSuit.shareTimeList[period][branchId]
  if data.unlock_flag and data.level_time and data.level_time[level] then
    return data.level_time[level]
  end
end
function LogicXSuit.GetBaseInfo(period_id, bBranch, _BranchId)
  if not period_id then
    return nil
  end
  LogicXSuit.InitXSuitBaseInfo(period_id)
  if LogicXSuit.baseInfo then
    local info = LogicXSuit.baseInfo[period_id]
    if not info then
      return nil
    end
    local TableUtil = require("common.table_util")
    local newInfo = TableUtil.FastCopyTable(info)
    if #newInfo == 0 then
      bBranch = true
      _BranchId = 0
    end
    local maxPeriod = LogicXSuit.GetMaxPeriod()
    if maxPeriod == #LogicXSuit.shareTimeList then
      return bBranch and info[_BranchId] or info, 0 < #info, _BranchId
    end
    for BranchId, realInfo in pairs(newInfo) do
      for i = realInfo.max_level, 1, -1 do
        if LogicXSuit.CheckShowByLevel(period_id, i, BranchId) then
          realInfo.max_level = i
          realInfo.max_item_id = LogicXSuit.upgradeInfo[period_id][BranchId][i].item_id
          break
        end
      end
    end
    return bBranch and newInfo[_BranchId] or newInfo, 0 < #newInfo, _BranchId
  else
    return nil
  end
end
function LogicXSuit.GetUpgradeInfo(period_id, bBranch, _BranchId)
  LogicXSuit.InitXSuitBaseInfo(period_id)
  local info = LogicXSuit.upgradeInfo[period_id]
  local TableUtil = require("common.table_util")
  local newInfo = TableUtil.FastCopyTable(info)
  if #newInfo == 0 then
    bBranch = true
    _BranchId = 0
  end
  local maxPeriod = LogicXSuit.GetMaxPeriod()
  if maxPeriod == #LogicXSuit.shareTimeList then
    return bBranch and _BranchId and info[_BranchId] or info, 0 < #info, _BranchId
  end
  for BranchId, realInfo in pairs(newInfo) do
    for index = #realInfo, 1, -1 do
      if not LogicXSuit.CheckShowByLevel(period_id, index, BranchId) then
        table.remove(realInfo, index)
      else
        for featureIndex = maxFeatureCount, 1 do
          if info["SubTabID" .. featureIndex] and not LogicXSuit.CheckShowByLevelAndFeature(period_id, index, featureIndex, BranchId) then
            table.remove(realInfo[index], featureIndex)
          end
        end
      end
    end
  end
  return bBranch and newInfo[_BranchId] or newInfo, 0 < #newInfo, _BranchId
end
function LogicXSuit.GetUpgradeUIInfo(period_id)
  local cfg = CDataTable.GetTableDataByFilter("GoldenSuitUpgradeUICfg", "Period", period_id, "IsBranch", 0)
  return cfg
end
function LogicXSuit.GetBranchUIInfo(period, branch)
  return CDataTable.GetTableDataByFilter("GoldenSuitUpgradeUICfg", "Period", period, "IsBranch", 1, "BranchId", branch)
end
function LogicXSuit.GetUpgradeUIInfoByBranchId(period_id, BranchId)
  local cfg = CDataTable.GetTableDataByFilter("XSuitCommonBranch", "Period", period_id, "IsBranch", 1, "BranchId", BranchId)
  return cfg
end
function LogicXSuit.GetShowRelicID(itemID)
  local level = LogicXSuit.GetLevelByItemId(itemID)
  if not level or level < 2 then
    return nil
  end
  local period = LogicXSuit.GetPeriodByItemId(itemID)
  if period then
    local branchId = LogicXSuit.GetBranchByItemId(itemID)
    local baseInfo = LogicXSuit.GetBaseInfo(period, true, branchId)
    if baseInfo then
      return baseInfo.relic_id
    end
  end
  return nil
end
function LogicXSuit.GetEnterActionByPeriod(period, state, branchId)
  branchId = branchId or 0
  local config = LogicXSuit.GetBranchMapData(period, branchId)
  if not config then
    return nil
  end
  local enterActionID
  if config.EnterActionID and config.EnterActionID ~= 0 then
    enterActionID = config.EnterActionID
  end
  local multi_state_manager = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.multi_state_manager)
  enterActionID = multi_state_manager:ChangeEmoteByState(enterActionID, state)
  return enterActionID
end
function LogicXSuit.IsBattleEmotion(action_id)
  log(bWriteLog and "LogicXSuit.IsBattleEmotion " .. tostring(action_id))
  local config = CDataTable.GetTableDataByFilter("GoldenSuitMapCfg", "BattleActionID", action_id)
  return config and true or false, config and config.Period
end
function LogicXSuit.GetItemIDListByPeriod(period, branchId)
  branchId = branchId or 0
  local itemList = {}
  local multi_state_manager = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.multi_state_manager)
  local datas = LogicXSuit.GetUpgradeInfo(period, true, branchId)
  for level, itemData in pairs(datas) do
    if type(itemData) == "table" and itemData.item_id then
      table.insert(itemList, itemData.item_id)
      local changeStateAction = multi_state_manager:GetStateChangeAction(itemData.item_id)
      if changeStateAction then
        for beforeCloth, action in pairs(changeStateAction) do
          table.insert(itemList, beforeCloth)
          table.insert(itemList, action)
        end
      end
    end
  end
  local config = LogicXSuit.GetBranchMapData(period, branchId)
  if config and config.BattleActionID and config.BattleActionID ~= 0 then
    table.insert(itemList, config.BattleActionID)
  end
  for _, itemData in pairs(datas) do
    if type(itemData) == "table" and itemData.item_id then
      local emoteConfig = CDataTable.GetTableDataByFilter("BornIslandShowEmoteCfg", "ItemID", itemData.item_id)
      if emoteConfig then
        if emoteConfig.EmotionID and emoteConfig.EmotionID ~= 0 then
          table.insert(itemList, emoteConfig.EmotionID)
        end
        if emoteConfig.PrepareEmotionID and emoteConfig.PrepareEmotionID ~= 0 then
          table.insert(itemList, emoteConfig.PrepareEmotionID)
        end
        break
      end
    end
  end
  return itemList
end
function LogicXSuit.GetActSuitMaxLevelByPeriod(period, branch_id)
  if not period then
    return nil
  end
  local info = LogicXSuit.GetUpgradeInfo(period, true, branch_id)
  return info and #info or 0
end
function LogicXSuit.BuildMaterialInfo(period, branchId, nextLevel, featureIndex, state, bGlide)
  LogicXSuit.InitXSuitBaseInfo(period)
  local materialList, makeUpList, exchangeList = {}, {}, {}
  local bUpgrade, bNeedMakeUp, bCanMakeUp, needCurrency, bActive = true, false, true, 0, false
  if period and branchId and nextLevel and featureIndex then
    local list = LogicXSuit.GetUnlockFeatureMaterial(period, branchId, nextLevel, featureIndex)
    for index, material in pairs(list) do
      local _bUpgrade, _bNeedMakeUp, _bCanMakeUp, _needCurrency = LogicXSuit.AddMaterial(materialList, makeUpList, exchangeList, material.resid, material.count, material.timing_resid, nil, nil, nil, period, branchId)
      bUpgrade = _bUpgrade and bUpgrade
      bNeedMakeUp = _bNeedMakeUp or bNeedMakeUp
      bCanMakeUp = _bCanMakeUp and bCanMakeUp
      needCurrency = _needCurrency + needCurrency
    end
  elseif period and branchId and state then
    local multiCfg = xsuit_config_and_cache.GetMultiTypeUnlockConfigByPeriod(period)
    if not multiCfg then
      return {}
    end
    local unlockLevel = multiCfg.unlock_level
    local info = LogicXSuit.upgradeInfo[period][branchId][unlockLevel].cfg
    for i = 1, 2 do
      local comMatId = info["SecondMatID" .. i] or info.SecondMatID
      local needNum = info["SecondMatCount" .. i] or info.SecondMatCount
      local limitMatId = info["LimitMatID" .. i]
      if comMatId ~= info["MatID" .. i] then
        limitMatId = 0
      end
      if comMatId <= 0 then
        break
      end
      local _bUpgrade, _bNeedMakeUp, _bCanMakeUp, _needCurrency = LogicXSuit.AddMaterial(materialList, makeUpList, exchangeList, comMatId, needNum, limitMatId, nil, nil, nil, period, branchId)
      bUpgrade = _bUpgrade and bUpgrade
      bNeedMakeUp = _bNeedMakeUp or bNeedMakeUp
      bCanMakeUp = (_bUpgrade or _bCanMakeUp) and bCanMakeUp
      needCurrency = _needCurrency + needCurrency
    end
  elseif period and branchId and nextLevel and bGlide then
    local itemId = LogicXSuit.GetItemIDByLevel(period, nextLevel, branchId)
    local glideCfg = CDataTable.GetTableDataByFilter("XSuitGlideCfg", "XSuitID7", itemId)
    local upgradeInfo = LogicXSuit.upgradeInfo[period][branchId][2].cfg
    local wardrobe_data = require("client.slua.logic.wardrobe.wardrobe_data")
    local backResNumList = {}
    for i = 1, 4 do
      local _idx = i <= 2 and i or i - 2
      local comMatId = i <= 2 and upgradeInfo["BackID" .. _idx] or upgradeInfo["MatID" .. _idx]
      local needNum = glideCfg["MatNum" .. _idx]
      local limitMatId = upgradeInfo["LimitMatID" .. _idx]
      local wardrobeCount = wardrobe_data:GetHallDepotItemCountByResID(comMatId) or 0
      if i <= 2 and wardrobeCount <= 0 then
        needNum = 0
      elseif i <= 2 and 0 < wardrobeCount then
        backResNumList[_idx] = {}
        backResNumList[_idx].num = wardrobeCount
        if wardrobeCount >= needNum then
          backResNumList[_idx].enough = true
        else
          needNum = wardrobeCount
        end
      end
      if 2 < i and backResNumList[_idx] and backResNumList[_idx].enough then
        needNum = 0
      elseif 2 < i and backResNumList[_idx] and not backResNumList[_idx].enough then
        needNum = needNum - backResNumList[_idx].num
      end
      if 0 < needNum then
        local _bUpgrade, _bNeedMakeUp, _bCanMakeUp, _needCurrency = LogicXSuit.AddMaterial(materialList, makeUpList, exchangeList, comMatId, needNum, limitMatId, nil, nil, nil, period, branchId)
        bUpgrade = _bUpgrade and bUpgrade
        bNeedMakeUp = _bNeedMakeUp or bNeedMakeUp
        bCanMakeUp = (_bUpgrade or _bCanMakeUp) and bCanMakeUp
        needCurrency = _needCurrency + needCurrency
      end
    end
  elseif period and branchId and nextLevel then
    local info = LogicXSuit.upgradeInfo[period][branchId][nextLevel].cfg
    local activeBranch = LogicXSuit.GetActiveBranchIdByPeriod(period)
    local discountData, bOpenActive = LogicXSuit.GetDiscountBranchAndDiscount(period)
    for i = 1, 2 do
      local comMatId = info["MatID" .. i]
      local needNum = info["MatNum" .. i]
      local limitMatId = info["LimitMatID" .. i]
      local activeId = activeBranch == branchId and info["ActiveID" .. i] or 0
      local activeNum = activeBranch == branchId and info["ActiveNum" .. i] or 0
      local backId = info["BackID" .. i]
      local discountNum = 0
      if bOpenActive then
        for index, data in pairs(discountData) do
          if data.branchId == branchId and data.level == nextLevel - 1 then
            discountNum = i == 1 and data.main_discount or data.assistant_discount
            break
          end
        end
      end
      local _bUpgrade, _bNeedMakeUp, _bCanMakeUp, _needCurrency = LogicXSuit.AddMaterial(materialList, makeUpList, exchangeList, comMatId, needNum, limitMatId, activeId, activeNum, backId, period, branchId, discountNum)
      bUpgrade = _bUpgrade and bUpgrade
      bNeedMakeUp = _bNeedMakeUp or bNeedMakeUp
      bCanMakeUp = (_bUpgrade or _bCanMakeUp) and bCanMakeUp
      needCurrency = _needCurrency + needCurrency
      bActive = 0 < activeId
    end
  else
    return {}
  end
  if 0 < needCurrency then
    local logic_xsuit_activity = ModuleManager.GetModule(ModuleManager.JumpModuleConfig.logic_xsuit_activity)
    local currencyCount = logic_xsuit_activity:GetDrawCurrencyCount()
    if currencyCount and needCurrency > currencyCount then
      bCanMakeUp = false
      bUpgrade = false
    end
  end
  return {
    bUpgrade = bUpgrade,
    bNeedMakeUp = bNeedMakeUp,
    bCanMakeUp = bCanMakeUp,
    materialList = materialList,
    makeUpList = makeUpList,
    exchangeList = exchangeList,
    needCurrency = needCurrency,
    bActive = bActive
  }
end
function LogicXSuit.AddMaterial(materialList, makeUpList, exchangeList, comMatId, needNum, limitMatId, activeId, activeNum, backId, period, branchId, discountNum)
  local resId, needCount = activeId and 0 < activeId and activeId or comMatId, activeId and 0 < activeId and activeNum or needNum
  local haveCount = 0
  local wardrobe_data = require("client.slua.logic.wardrobe.wardrobe_data")
  local wardrobeCount = wardrobe_data:GetHallDepotItemCountByResID(resId) or 0
  local originalNeedCount
  if discountNum and 0 < discountNum then
    originalNeedCount = needCount
    needCount = math.ceil(needCount * (100 - discountNum) / 100)
  end
  local bUpgrade, bNeedMakeUp, bCanMakeUp = false, false, false
  haveCount = haveCount + wardrobeCount
  local materialInfo = {
    resID = resId,
    count = wardrobeCount,
    needCount = needCount,
    SourceJumpList = LogicXSuit.GetJumpInfoByItemID(resId),
    discount = originalNeedCount and discountNum
  }
  table.insert(materialList, materialInfo)
  if needCount <= haveCount then
    bUpgrade, bNeedMakeUp, bCanMakeUp = true, false, false
  end
  local common2ActiveNum = 1
  if activeId and 0 < activeId then
    common2ActiveNum = LogicXSuit.MaterialCommon2ActiveNum(comMatId)
  end
  local transformCount = 0
  local realExchangeCount = 0
  if activeId and 0 < activeId and resId ~= comMatId then
    wardrobeCount = wardrobe_data:GetHallDepotItemCountByResID(comMatId) or 0
    transformCount = wardrobeCount * common2ActiveNum
    realExchangeCount = math.ceil(needCount / common2ActiveNum) * common2ActiveNum
    if not bUpgrade and (not bNeedMakeUp or not bCanMakeUp) and needCount <= haveCount + transformCount and realExchangeCount <= haveCount + transformCount then
      table.insert(makeUpList, {
        resID = activeId,
        count = math.ceil((needCount - haveCount) / common2ActiveNum) * common2ActiveNum
      })
      bUpgrade, bNeedMakeUp, bCanMakeUp = true, true, true
    elseif not bUpgrade and (not bNeedMakeUp or not bCanMakeUp) then
      table.insert(makeUpList, {resID = activeId, count = transformCount})
    end
    haveCount = haveCount + transformCount
  end
  wardrobeCount = wardrobe_data:GetHallDepotItemCountByResID(limitMatId, true) or 0
  transformCount = wardrobeCount * common2ActiveNum
  if activeId and 0 < activeId then
    realExchangeCount = math.ceil(needCount / common2ActiveNum) * common2ActiveNum
    if not bUpgrade and (not bNeedMakeUp or not bCanMakeUp) and needCount <= haveCount + transformCount and realExchangeCount <= haveCount + transformCount then
      table.insert(makeUpList, {
        resID = activeId,
        count = math.ceil((needCount - haveCount) / common2ActiveNum) * common2ActiveNum
      })
      bUpgrade, bNeedMakeUp, bCanMakeUp = true, true, true
    elseif not bUpgrade and (not bNeedMakeUp or not bCanMakeUp) then
      table.insert(makeUpList, {resID = activeId, count = transformCount})
    end
    haveCount = haveCount + transformCount
  else
    materialInfo.count = materialInfo.count + wardrobeCount
    haveCount = haveCount + transformCount
    if needCount <= haveCount then
      bUpgrade, bNeedMakeUp, bCanMakeUp = true, false, false
    end
  end
  local upgradeInfo = LogicXSuit.upgradeInfo[period][branchId][2]
  if activeId and activeId <= 0 and upgradeInfo and upgradeInfo.cfg and upgradeInfo.cfg.BackID1 and 0 < upgradeInfo.cfg.BackID1 then
    wardrobeCount = wardrobe_data:GetHallDepotItemCountByResID(backId) or 0
    transformCount = wardrobeCount * common2ActiveNum
    materialInfo.count = materialInfo.count + transformCount
    haveCount = haveCount + transformCount
    if needCount <= haveCount then
      bUpgrade, bNeedMakeUp, bCanMakeUp = true, false, false
    end
  end
  if bUpgrade or bNeedMakeUp and bCanMakeUp then
    return bUpgrade, bNeedMakeUp, bCanMakeUp, 0
  end
  local logic_xsuit_activity = ModuleManager.GetModule(ModuleManager.JumpModuleConfig.logic_xsuit_activity)
  local limitExchangeInfo = logic_xsuit_activity:GetExchangeDataByItemID(limitMatId)
  if not limitExchangeInfo then
    return false, true, false, 0
  end
  local currencyId = logic_xsuit_activity:GetDrawCurrencyID()
  local currencyCount = wardrobe_data:GetHallDepotItemCountByResID(currencyId, true) or 0
  needCount = needCount - haveCount
  local needCurrency = 0
  local discount = limitExchangeInfo.hasDiscount and limitExchangeInfo.drawDiscount
  if discount then
    local canExchangeCount = limitExchangeInfo.timeLimits - (limitExchangeInfo.hasExchangeCount or 0)
    transformCount = canExchangeCount * common2ActiveNum
    realExchangeCount = math.ceil(needCount / common2ActiveNum)
    if needCount <= transformCount then
      needCurrency = needCurrency + math.ceil(realExchangeCount * limitExchangeInfo.needItemNum * discount / 100)
      local _ = 0 < realExchangeCount and table.insert(exchangeList, {
        pos_id = limitExchangeInfo.pos,
        exchange_num = realExchangeCount
      })
      if currencyCount >= math.ceil(realExchangeCount * limitExchangeInfo.needItemNum * discount / 100) then
        return true, true, true, needCurrency
      else
        return false, true, false, needCurrency
      end
    else
      local _ = 0 < canExchangeCount and table.insert(exchangeList, {
        pos_id = limitExchangeInfo.pos,
        exchange_num = canExchangeCount
      })
      local price = math.ceil(canExchangeCount * limitExchangeInfo.needItemNum * discount / 100)
      currencyCount = currencyCount - price
      needCurrency = needCurrency + price
      needCount = needCount - transformCount
    end
  end
  local exchangeInfo = logic_xsuit_activity:GetExchangeDataByItemID(comMatId)
  if not exchangeInfo then
    return false, true, false, needCurrency
  end
  local canExchangeCount = exchangeInfo.timeLimits - (exchangeInfo.hasExchangeCount or 0)
  transformCount = canExchangeCount * common2ActiveNum
  realExchangeCount = math.ceil(needCount / common2ActiveNum)
  if transformCount then
    needCurrency = needCurrency + realExchangeCount * exchangeInfo.needItemNum
    local _ = 0 < realExchangeCount and table.insert(exchangeList, {
      pos_id = exchangeInfo.pos,
      exchange_num = realExchangeCount
    })
    if currencyCount >= realExchangeCount * exchangeInfo.needItemNum then
      return true, true, true, needCurrency
    else
      return false, true, false, needCurrency
    end
  else
    local _ = 0 < canExchangeCount and table.insert(exchangeList, {
      pos_id = limitExchangeInfo.pos,
      exchange_num = canExchangeCount
    })
    local price = canExchangeCount * limitExchangeInfo.needItemNum
    currencyCount = currencyCount - price
    needCurrency = needCurrency + price
    needCount = needCount - transformCount
  end
  return false, true, false, needCurrency
end
function LogicXSuit.GetJumpInfoByItemID(itemID)
  if not LogicXSuit.jumpList then
    LogicXSuit.jumpList = {}
  end
  if LogicXSuit.jumpList[itemID] then
    return LogicXSuit.jumpList[itemID]
  end
  local list = {}
  local ItemUpgradeMgr = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.ItemUpgradeModule)
  local itemJumpCfg = ItemUpgradeMgr:GetItemSourceJumpConfig(itemID)
  local jumpStr = itemJumpCfg and itemJumpCfg.JumpType or ""
  if jumpStr ~= "" then
    local JumpUtils = require("client.logic.store.jump_utils")
    local StringUtil = require("common.string_util")
    local jumpTypeList = StringUtil.Split(jumpStr, "|")
    for i, jType in ipairs(jumpTypeList) do
      local nJumpID = tonumber(jType)
      if nJumpID == JumpUtils.ENUM_JUMP_TYPE.Store and JumpUtils.FindJumpInfoAllByToModelId(itemID, JumpUtils.MODEL_ID_STORE) then
        table.insert(list, nJumpID)
      elseif nJumpID == JumpUtils.ENUM_JUMP_TYPE.Supply and JumpUtils.FindJumpInfoAllByToModelId(itemID, JumpUtils.MODEL_ID_SUPPLY) then
        table.insert(list, nJumpID)
      elseif nJumpID == JumpUtils.ENUM_JUMP_TYPE.JKStore and JumpUtils.FindJumpInfoAll(itemID) then
        table.insert(list, nJumpID)
      else
        local jumpCfg = CDataTable.GetTableData("JumpConfig", nJumpID)
        if jumpCfg and string.len(jumpCfg.JumpUrl) > 0 and LobbySystem.CheckUrlCanJump(jumpCfg.JumpUrl) then
          table.insert(list, nJumpID)
        end
      end
    end
  end
  LogicXSuit.jumpList[itemID] = list
  return list
end
function LogicXSuit.IsUnlockStateMaterial(itemID)
  if not itemID then
    return nil
  end
  if not LogicXSuit.unlockStateMatMap then
    return nil
  end
  return LogicXSuit.unlockStateMatMap[itemID]
end
function LogicXSuit.GetXSuitLocalizeResStr(id)
  local str = LocUtil.GetLocalizeResStr(id)
  if str then
    str = string.gsub(str, "%$%$", "\"")
  else
    str = ""
  end
  return str
end
function LogicXSuit.GetSwitchItemIDByItemID(itemID)
  local period = LogicXSuit.GetPeriodByItemId(itemID)
  local branchId = LogicXSuit.GetBranchByItemId(itemID)
  local switchLevel = LogicXSuit.GetSwitchLevelByPeriod(period, branchId)
  return LogicXSuit.GetSwitchItemByItemAndSwitchLevel(itemID, switchLevel)
end
function LogicXSuit.GetSwitchItemByItemAndSwitchLevel(itemID, switchLevel)
  log(bWriteLog and "LogicXSuit.GetSwitchItemByItemAndSwitchLevel, itemID = " .. tostring(itemID) .. "; switchLevel = " .. tostring(switchLevel))
  if LogicXSuit.IsXSuit(itemID) then
    local originalLevel = LogicXSuit.GetLevelByItemId(itemID)
    local period = LogicXSuit.GetPeriodByItemId(itemID)
    if switchLevel > originalLevel then
      log(bWriteLog and "LogicXSuit.GetSwitchItemByItemAndSwitchLevel: switchLevel > originalLevel")
      return itemID
    else
      local putOnLevel = originalLevel
      if switchLevel == 1 then
        if originalLevel == 1 then
          putOnLevel = 1
        else
          putOnLevel = 2
        end
      elseif switchLevel == 3 then
        if 5 <= originalLevel then
          putOnLevel = 5
        else
          putOnLevel = originalLevel
        end
      elseif switchLevel == 6 then
        putOnLevel = 6
      elseif switchLevel == 7 then
        putOnLevel = 7
      end
      log(bWriteLog and "LogicXSuit.GetSwitchItemByItemAndSwitchLevel: period = " .. tostring(period) .. "; putOnLevel = " .. tostring(putOnLevel))
      local branchId = LogicXSuit.GetBranchByItemId(itemID)
      return LogicXSuit.GetItemIDByLevel(period, putOnLevel, branchId)
    end
  else
    log(bWriteLog and "LogicXSuit.GetSwitchItemByItemAndSwitchLevel: not GoldenSuit")
    return itemID
  end
end
function LogicXSuit.GetItemShowID(InsID)
  local WardrobeData = require("client.slua.logic.wardrobe.wardrobe_data")
  local ShowItemID = WardrobeData:GetItemIDByInsID(InsID)
  local Source = WardrobeData:GetItemSource(InsID)
  if Source == EWardrobeDataSource.InheritWardrobe then
    ShowItemID = LogicXSuit.ChangeItemIDByMyselfState(ShowItemID, Source)
  else
    ShowItemID = LogicXSuit.GetSwitchItemIDByItemID(ShowItemID)
    ShowItemID = LogicXSuit.ChangeItemIDByMyselfState(ShowItemID, Source)
  end
  return ShowItemID
end
function LogicXSuit._GetSwitchLevelByItemID(itemID)
  local period = LogicXSuit.GetPeriodByItemId(itemID)
  if period then
    local branchId = LogicXSuit.GetBranchByItemId(itemID)
    return LogicXSuit.GetSwitchLevelByPeriod(period, branchId)
  end
  return nil
end
function LogicXSuit.GetSwitchLevelByInsID(InsID)
  local WardrobeData = require("client.slua.logic.wardrobe.wardrobe_data")
  local Source = WardrobeData:GetItemSource(InsID)
  local ItemID = WardrobeData:GetItemIDByInsID(InsID)
  if Source == EWardrobeDataSource.InheritWardrobe then
    return LogicXSuit.GetDefaultSwitchLevelByItemID(ItemID)
  else
    return LogicXSuit._GetSwitchLevelByItemID(ItemID)
  end
end
function LogicXSuit.GetDefaultSwitchLevelByItemID(itemID)
  local level = LogicXSuit.GetLevelByItemId(itemID)
  if level then
    local switchLevelList = LogicXSuit.GetConfig("switchLevelList")
    return switchLevelList[level]
  else
    return 0
  end
end
function LogicXSuit.GetSwitchLevelByPeriod(period, branch_id)
  local switchLevelList = LogicXSuit.GetConfig("switchLevelList")
  if not LogicXSuit.switchLevel then
    XSuitHandler.send_get_gold_dress_new_level_req()
    return switchLevelList[LogicXSuit.GetLevelByPeriodSelf(period, branch_id)]
  end
  local level = LogicXSuit.switchLevel[period] and LogicXSuit.switchLevel[period][branch_id]
  if level and 0 < level then
    return level
  else
    return switchLevelList[LogicXSuit.GetLevelByPeriodSelf(period, branch_id)]
  end
end
function LogicXSuit.GetPeriodOfCurrentlyWearing()
  local wardrobe_data = require("client.slua.logic.wardrobe.wardrobe_data")
  local period, branchId
  local tRoleData = AvatarData.GetRoleWear()
  for _, v in pairs(tRoleData) do
    local itemInfo = wardrobe_data:GetHallDepotItemDataByInsID(v)
    if itemInfo and itemInfo.resID then
      period = LogicXSuit.GetPeriodByItemId(itemInfo.resID)
      branchId = LogicXSuit.GetBranchByItemId(itemInfo.resID)
      if period ~= nil then
        return period, itemInfo.resID, v, branchId
      end
    end
  end
  return nil, nil
end
function LogicXSuit.MaterialCommon2ActiveNum(itemId)
  if not LogicXSuit.MaterialCommon2Active then
    return 1
  end
  for _, v in pairs(LogicXSuit.MaterialCommon2Active) do
    if v.exchange_resid == itemId then
      return v.give_num
    end
  end
  return 1
end
function LogicXSuit.MaterialActive2CommonNum(itemId)
  if not LogicXSuit.MaterialCommon2Active then
    return itemId
  end
  return itemId, LogicXSuit.MaterialCommon2Active[itemId]
end
function LogicXSuit.GetNextBranchIdAndItemId(itemID)
  local period = LogicXSuit.GetPeriodByItemId(itemID)
  if not period then
    return
  end
  if not LogicXSuit.IsBranch(period) then
    return
  end
  local branchIdList = LogicXSuit.GetUnlockedBranchIdListByPeriod(period)
  if not branchIdList or #branchIdList <= 1 then
    return
  end
  local branchId = LogicXSuit.GetBranchByItemId(itemID)
  local nextBranchId
  for k, v in ipairs(branchIdList) do
    if v == branchId then
      local index = k + 1
      if index > #branchIdList then
        index = 1
      end
      nextBranchId = branchIdList[index]
      break
    end
  end
  return nextBranchId, LogicXSuit.GetItemIDByLevel(period, 1, nextBranchId), period, branchId
end
function LogicXSuit.GetWardrobeBranchByPeriod(period)
  return LogicXSuit.XSuitWardrobeBranchData[period] and LogicXSuit.XSuitWardrobeBranchData[period].branch_id
end
function LogicXSuit.GetSchemeIdByFeature(period, branchId, feature)
  return LogicXSuit.equip_data[period] and LogicXSuit.equip_data[period][branchId] and LogicXSuit.equip_data[period][branchId][feature]
end
function LogicXSuit.GetSchemeIdByBranch(period, branchId)
  return LogicXSuit.equip_data[period] and LogicXSuit.equip_data[period][branchId]
end
function LogicXSuit.GetDiscountBranchAndDiscount(period)
  local branchList = LogicXSuit.shareTimeList[period]
  if not (branchList and LogicXSuit.UpgradeDiscount) or not LogicXSuit.UpgradeDiscount[period] then
    return
  end
  local discountData = {}
  for branchId, v in pairs(branchList) do
    table.insert(discountData, {
      period = period,
      branchId = branchId,
      level = v.current or 0
    })
  end
  table.sort(discountData, function(a, b)
    if a.level == b.level then
      return a.branchId < b.branchId
    end
    return a.level > b.level
  end)
  for index, data in pairs(discountData) do
    local discount = LogicXSuit.UpgradeDiscount[period] and LogicXSuit.UpgradeDiscount[period][data.level]
    if discount then
      if index == 1 then
        data.main_discount = 0
        data.assistant_discount = 0
      elseif index == #discountData then
        if data.level == discountData[1].level then
          data.main_discount = 0
          data.assistant_discount = 0
        elseif data.level == discountData[2].level then
          data.main_discount = 100 - discount[1].main_discount
          data.assistant_discount = 100 - discount[1].assistant_discount
        else
          data.main_discount = 100 - discount[2].main_discount
          data.assistant_discount = 100 - discount[2].assistant_discount
        end
      elseif data.level == discountData[1].level then
        data.main_discount = 0
        data.assistant_discount = 0
      else
        data.main_discount = 100 - discount[1].main_discount
        data.assistant_discount = 100 - discount[1].assistant_discount
      end
    else
      data.main_discount = 0
      data.assistant_discount = 0
    end
  end
  local activeBranchId = LogicXSuit.GetActiveBranchIdByPeriod(period)
  return discountData, activeBranchId ~= nil
end
function LogicXSuit.GetUpgradeDiscountInfo(period)
  return LogicXSuit.UpgradeDiscount and LogicXSuit.UpgradeDiscount[period]
end
function LogicXSuit.GetBranchMapData(period, branchId)
  branchId = branchId or 0
  return CDataTable.GetTableDataByFilter("GoldenSuitMapCfg", "Period", period, "BranchId", branchId)
end
function LogicXSuit.GetTaskState(taskId, bWeek)
  if bWeek then
    local weekId = LogicXSuit.task_info.week_id
    local info = LogicXSuit.task_status_info and LogicXSuit.task_status_info.week_task
    return info and info[weekId] and info[weekId][taskId] or {}
  else
    return LogicXSuit.task_status_info and LogicXSuit.task_status_info.season_task and LogicXSuit.task_status_info.season_task[taskId] or {}
  end
end
function LogicXSuit.GetTaskConfig()
  local CommonItem_Const = require("client.slua.component.item.ItemUtils.CommonItem_Const")
  local weekId = LogicXSuit.task_info.week_id
  local weekTaskStatus = LogicXSuit.task_status_info and LogicXSuit.task_status_info.week_task and LogicXSuit.task_status_info.week_task[weekId] or {}
  local weekConfigs, realWeekConfigs = {}, {}
  local minTaskList = {}
  for taskId, stateData in pairs(weekTaskStatus) do
    local config = LogicXSuit.task_conf_info.week_task[taskId]
    if config then
      table.insert(realWeekConfigs, config)
      if not minTaskList[config.sys_category] then
        minTaskList[config.sys_category] = {}
      end
      if not minTaskList[config.sys_category][config.task_type] then
        minTaskList[config.sys_category][config.task_type] = config
      else
        local cacheCfg = minTaskList[config.sys_category][config.task_type]
        if cacheCfg.finish_value < config.finish_value then
          local state = LogicXSuit.GetTaskState(cacheCfg.task_id, true)
          if state.status == CommonItem_Const.Enum_ItemStatus.Got then
            minTaskList[config.sys_category][config.task_type] = config
          end
        else
          local state = LogicXSuit.GetTaskState(config.task_id, true)
          if state.status ~= CommonItem_Const.Enum_ItemStatus.Got then
            minTaskList[config.sys_category][config.task_type] = config
          end
        end
      end
    end
  end
  for sysId, taskTypeList in pairs(minTaskList) do
    for taskType, config in pairs(taskTypeList) do
      table.insert(weekConfigs, config)
    end
  end
  local sortFunc = function(list, bWeek)
    table.sort(list, function(a, b)
      local stateA = LogicXSuit.GetTaskState(a.task_id, bWeek)
      local stateB = LogicXSuit.GetTaskState(b.task_id, bWeek)
      if stateA.status == stateB.status then
        return a.task_id < b.task_id
      else
        local bMaxA = stateA.finish_count and a.max_finish_count <= stateA.finish_count
        local bMaxB = stateB.finish_count and b.max_finish_count <= stateB.finish_count
        if bMaxA == bMaxB then
          if stateA.status == CommonItem_Const.Enum_ItemStatus.Done or stateB.status == CommonItem_Const.Enum_ItemStatus.Got then
            return true
          elseif stateB.status == CommonItem_Const.Enum_ItemStatus.Done or stateA.status == CommonItem_Const.Enum_ItemStatus.Got then
            return false
          else
            return a.task_id < b.task_id
          end
        else
          return bMaxB
        end
      end
    end)
  end
  local seasonConfigs, realSeasonConfigs = {}, {}
  minTaskList = {}
  for taskId, config in pairs(LogicXSuit.task_conf_info.season_task or {}) do
    table.insert(realSeasonConfigs, config)
    if not minTaskList[config.sys_category] then
      minTaskList[config.sys_category] = {}
    end
    if not minTaskList[config.sys_category][config.task_type] then
      minTaskList[config.sys_category][config.task_type] = config
    else
      local cacheCfg = minTaskList[config.sys_category][config.task_type]
      if cacheCfg.finish_value < config.finish_value then
        local state = LogicXSuit.GetTaskState(cacheCfg.task_id, false)
        if state.status == CommonItem_Const.Enum_ItemStatus.Got then
          minTaskList[config.sys_category][config.task_type] = config
        end
      else
        local state = LogicXSuit.GetTaskState(config.task_id, false)
        if state.status ~= CommonItem_Const.Enum_ItemStatus.Got then
          minTaskList[config.sys_category][config.task_type] = config
        end
      end
    end
  end
  for sysId, taskTypeList in pairs(minTaskList) do
    for taskType, config in pairs(taskTypeList) do
      table.insert(seasonConfigs, config)
    end
  end
  sortFunc(weekConfigs, true)
  sortFunc(seasonConfigs, false)
  return weekConfigs, seasonConfigs, realWeekConfigs, realSeasonConfigs
end
function LogicXSuit.GetTaskStartTime(bWeek)
  if bWeek then
    return LogicXSuit.task_info.week_info and LogicXSuit.task_info.week_info[LogicXSuit.task_info.week_id] and LogicXSuit.task_info.week_info[LogicXSuit.task_info.week_id].start_time or 0
  else
    return LogicXSuit.task_info.season_info and LogicXSuit.task_info.season_info[LogicXSuit.task_info.season_id] and LogicXSuit.task_info.season_info[LogicXSuit.task_info.season_id].start_time or 0
  end
end
function LogicXSuit.GetTaskEndTime(bWeek)
  if bWeek then
    return LogicXSuit.task_info.week_info and LogicXSuit.task_info.week_info[LogicXSuit.task_info.week_id] and LogicXSuit.task_info.week_info[LogicXSuit.task_info.week_id].end_time or 0
  else
    return LogicXSuit.task_info.season_info and LogicXSuit.task_info.season_info[LogicXSuit.task_info.season_id] and LogicXSuit.task_info.season_info[LogicXSuit.task_info.season_id].end_time or 0
  end
end
function LogicXSuit.GetTaskMaxFinishValue(bWeek)
  if bWeek then
    return LogicXSuit.task_info.week_info and LogicXSuit.task_info.week_info[LogicXSuit.task_info.week_id] and LogicXSuit.task_info.week_info[LogicXSuit.task_info.week_id].total_task or 0
  else
    return LogicXSuit.task_info.season_info and LogicXSuit.task_info.season_info[LogicXSuit.task_info.season_id] and LogicXSuit.task_info.season_info[LogicXSuit.task_info.season_id].total_task or 0
  end
end
function LogicXSuit.GetBackMaterialList(period, branchId, level)
  local upgradeList = LogicXSuit.upgradeInfo[period][branchId]
  local materialLIst = {}
  for lv, datas in pairs(upgradeList) do
    if 1 < lv and lv <= level then
      local config = datas.cfg
      if not materialLIst[config.MatID1] then
        materialLIst[config.MatID1] = config.MatNum1
      else
        materialLIst[config.MatID1] = materialLIst[config.MatID1] + config.MatNum1
      end
      if not materialLIst[config.MatID2] then
        materialLIst[config.MatID2] = config.MatNum2
      else
        materialLIst[config.MatID2] = materialLIst[config.MatID2] + config.MatNum2
      end
    end
  end
  local backList = {}
  for id, num in pairs(materialLIst) do
    table.insert(backList, num)
  end
  return backList
end
function LogicXSuit.SetXSuitCommonInfo(open, info, unlock_info, active_branch_info, Common2ActiveMaterial, UpgradeDiscount)
  log(bWriteLog and "LogicXSuit.SetXSuitCommonInfo open = " .. tostring(open) .. " || is : " .. tostring(open == 1))
  if info then
    LogicXSuit.shareTimeList = info
  else
    log(bWriteLog and "LogicXSuit.SetXSuitCommonInfo not info")
  end
  if unlock_info then
    LogicXSuit.unlockFeatureInfo = unlock_info
  else
    log(bWriteLog and "LogicXSuit.SetXSuitCommonInfo not unlock_info")
  end
  if active_branch_info then
    LogicXSuit.activeBranchInfo = active_branch_info
  else
    log(bWriteLog and "LogicXSuit.SetXSuitCommonInfo not active_branch_info")
  end
  if Common2ActiveMaterial then
    LogicXSuit.MaterialCommon2Active = Common2ActiveMaterial
  else
    log(bWriteLog and "LogicXSuit.SetXSuitCommonInfo not Common2ActiveMaterial")
  end
  if UpgradeDiscount then
    LogicXSuit.UpgradeDiscount = {}
    for period, datas in pairs(UpgradeDiscount) do
      LogicXSuit.UpgradeDiscount[period] = {}
      for discountLevel, discounts in pairs(datas) do
        for index, discount in pairs(discounts) do
          local levelInfo = discount.upgrade_list
          local realLevel = next(levelInfo)
          LogicXSuit.UpgradeDiscount[period][realLevel] = LogicXSuit.UpgradeDiscount[period][realLevel] or {}
          LogicXSuit.UpgradeDiscount[period][realLevel][discountLevel] = discount
          LogicXSuit.UpgradeDiscount[period][realLevel][discountLevel].level = realLevel
        end
      end
    end
  else
    log(bWriteLog and "LogicXSuit.SetXSuitCommonInfo not UpgradeDiscount")
  end
end
function LogicXSuit.SetXSuitLevel(cur_level, period, branch_id)
  if not (cur_level and period) or not branch_id then
    return
  end
  local branchInfo = LogicXSuit.shareTimeList[period] and LogicXSuit.shareTimeList[period][branch_id] or {}
  branchInfo.current = cur_level
  branchInfo.unlock_flag = true
  LogicXSuit.shareTimeList[period] = LogicXSuit.shareTimeList[period] or {}
  LogicXSuit.shareTimeList[period][branch_id] = branchInfo
end
function LogicXSuit.SetReddotCacheByPeriod(period, newVersion)
  LogicXSuit.reddotData[period] = LogicXSuit.reddotData[period] or {}
  LogicXSuit.reddotData[period].version = newVersion
  LogicXSuit.SetReddotCache()
end
function LogicXSuit.SetReddotCacheByBranchId(period, branchId, newVersion)
  LogicXSuit.reddotData[period] = LogicXSuit.reddotData[period] or {}
  LogicXSuit.reddotData[period][branchId] = LogicXSuit.reddotData[period][branchId] or {}
  LogicXSuit.reddotData[period][branchId].version = newVersion
  LogicXSuit.SetReddotCache()
end
function LogicXSuit.SetReddotCacheByLevel(period, branchId, level, newVersion)
  LogicXSuit.reddotData[period] = LogicXSuit.reddotData[period] or {}
  LogicXSuit.reddotData[period][branchId] = LogicXSuit.reddotData[period][branchId] or {}
  LogicXSuit.reddotData[period][branchId][level] = LogicXSuit.reddotData[period][branchId][level] or {}
  LogicXSuit.reddotData[period][branchId][level].version = newVersion
  LogicXSuit.SetReddotCache()
end
function LogicXSuit.SetReddotCacheByFeature(period, branchId, level, index, newVersion)
  LogicXSuit.reddotData[period] = LogicXSuit.reddotData[period] or {}
  LogicXSuit.reddotData[period][branchId] = LogicXSuit.reddotData[period][branchId] or {}
  LogicXSuit.reddotData[period][branchId][level] = LogicXSuit.reddotData[period][branchId][level] or {}
  LogicXSuit.reddotData[period][branchId][level][index] = LogicXSuit.reddotData[period][branchId][level][index] or {}
  LogicXSuit.reddotData[period][branchId][level][index].version = newVersion
  LogicXSuit.SetReddotCache()
end
function LogicXSuit.SetReddotCache()
  local PlayerPrefsSystem = require("client.logic.LogicPlayerPrefs.playerprefs")
  PlayerPrefsSystem.SaveTableToFile_N(LogicXSuit.reddotData, PlayerPrefsSystem.ePlayerPrefsType.eGoldenSuitLotteryRedPoint)
end
function LogicXSuit.SetActiveBranchInfo(period, itemId, branchId)
  LogicXSuit.activeBranchInfo[period] = {resid = itemId, branch_id = branchId}
end
function LogicXSuit.OnGetGoldDressNewLevelRsp(set_info)
  if set_info then
    LogicXSuit.switchLevel = set_info
  else
    local switchLevel = {}
    local config = xsuit_config_and_cache.GetVersionArgConfig()
    local maxPeriod = config.MAX_PERIOD or 1
    for i = 1, maxPeriod do
      switchLevel[i] = {}
      local allConfig, bBranch = LogicXSuit.GetBaseInfo(i)
      if bBranch then
        for BranchId, _ in pairs(allConfig) do
          switchLevel[i][BranchId] = LogicXSuit.GetLevelByPeriodSelf(i, BranchId)
        end
      else
        switchLevel[i][0] = LogicXSuit.GetLevelByPeriodSelf(i, 0)
      end
    end
    LogicXSuit.switchLevel = switchLevel
  end
  LogicXSuit.UpdateLobbyAvatar()
end
function LogicXSuit.SetSwitchLevelByPeriod(period, switchLevel, branch_id)
  branch_id = branch_id or 0
  local level = LogicXSuit.GetLevelByPeriodSelf(period, branch_id)
  if switchLevel > level or switchLevel <= 0 then
    return
  end
  local maxLevel = LogicXSuit.GetActSuitMaxLevelByPeriod(period, branch_id)
  if not maxLevel or switchLevel > maxLevel then
    return
  end
  if switchLevel ~= 1 and switchLevel ~= 3 and switchLevel ~= 6 and switchLevel ~= 7 then
    return
  end
  XSuitHandler.send_set_gold_dress_new_level_req(period, switchLevel, branch_id)
end
function LogicXSuit.OnSetGoldDressNewLevelRsp(period, switchLevel, branch_id)
  LogicXSuit.switchLevel[period] = LogicXSuit.switchLevel[period] or {}
  LogicXSuit.switchLevel[period][branch_id] = switchLevel
  local tlog_report_utils = require("client.slua.config.tlog.tlog_report_utils")
  local originalLevel = LogicXSuit.GetLevelByPeriodSelf(period, branch_id)
  if originalLevel == 7 and switchLevel < 7 then
    tlog_report_utils.ReportTLogEvent(TLogEventDefine.GoldenSuit_SwitchLevel_From_Seven)
  end
  if originalLevel == 6 and switchLevel < 6 then
    tlog_report_utils.ReportTLogEvent(TLogEventDefine.GoldenSuit_SwitchLevel_From_Six)
  end
  if 3 <= originalLevel and originalLevel < 6 and switchLevel == 1 then
    tlog_report_utils.ReportTLogEvent(TLogEventDefine.GoldenSuit_SwitchLevel_From_Three)
  end
  EventSystem:postEvent(EVENTTYPE_GOLDEN_SUIT, EVENTID_GOLDEN_SUIT_UPDATE_DRESS_LEVEL, branch_id)
  LogicXSuit.UpdateLobbyAvatar()
  local BasicDataAvatarWearInfo = ModuleManager.GetModule(ModuleManager.DataModuleConfig.BasicDataAvatarWearInfo)
  BasicDataAvatarWearInfo:GetOrReqData(DataMgr.roleData.uid, function(callUid, callInfo)
    EventSystem:postEvent(EVENTTYPE_RANK, EVENTID_WARZONE_UPDATE_AVATAR, callUid)
  end, {bForceReq = true}, Enum_AvatarShowSource.WardrobeLogic)
end
function LogicXSuit.SetWardrobeBranchByPeriod(period, data)
  LogicXSuit.XSuitWardrobeBranchData[period] = data
end
function LogicXSuit.SetWardrobeBranch(data)
  LogicXSuit.XSuitWardrobeBranchData = data
end
function LogicXSuit.SetSchemeIdCache(data)
  LogicXSuit.equip_data = data or {}
  LogicXSuit._SyncSelfXSuitSchemeToLobbyPawn()
end
function LogicXSuit.SetSchemeIdCacheByFeature(period, branchId, featureId, schemeId)
  LogicXSuit.equip_data[period] = LogicXSuit.equip_data[period] or {}
  LogicXSuit.equip_data[period][branchId] = LogicXSuit.equip_data[period][branchId] or {}
  LogicXSuit.equip_data[period][branchId][featureId] = schemeId
  LogicXSuit._SyncSelfXSuitSchemeToLobbyPawn()
end
function LogicXSuit.SetCollectInfo(info)
  LogicXSuit.collectInfo = info or {}
end
function LogicXSuit.SetCollectInfoByFeature(period, featureId)
  LogicXSuit.collectInfo[period] = LogicXSuit.collectInfo[period] or {}
  LogicXSuit.collectInfo[period][featureId] = 0
end
function LogicXSuit.SetTaskConfig(data)
  LogicXSuit.task_conf_info = data or {}
end
function LogicXSuit.SetTaskStatus(data)
  LogicXSuit.task_status_info = data or {}
end
function LogicXSuit.SetTaskWeekId(weekId, seasonId, bChangeOnline)
  if bChangeOnline and (weekId ~= LogicXSuit.task_info.week_id or seasonId ~= LogicXSuit.task_info.season_id) then
    EventSystem:postEvent(EVENTTYPE_XSUIT, EVENTID_XSUIT_MISSION_CONFIG_UPDATE)
  end
  LogicXSuit.task_info.week_id = weekId
  LogicXSuit.task_info.season_id = seasonId
end
function LogicXSuit.SetTaskTime(week_info, season_info)
  LogicXSuit.task_info.week_info = week_info
  LogicXSuit.task_info.season_info = season_info
end
function LogicXSuit.IsBranchOpen(period, branchId)
  local init_show_time = LogicXSuit.shareTimeList[period] and LogicXSuit.shareTimeList[period][branchId] and LogicXSuit.shareTimeList[period][branchId].init_show_time
  local TimeUtil = require("client.common.time_util")
  if init_show_time <= TimeUtil.GetServerTimeInSec() then
    return true
  end
  return false
end
function LogicXSuit.IsBranchUnlocked(period, branchId)
  return LogicXSuit.shareTimeList[period] and LogicXSuit.shareTimeList[period][branchId] and LogicXSuit.shareTimeList[period][branchId].unlock_flag
end
function LogicXSuit.IsBranch(period)
  local _, bBranch = LogicXSuit.GetBaseInfo(period)
  return bBranch
end
function LogicXSuit.CanShowUpgradeBtn(itemID)
  local level = LogicXSuit.GetLevelByItemId(itemID)
  local period = LogicXSuit.GetPeriodByItemId(itemID)
  local branchId = LogicXSuit.GetBranchByItemId(itemID)
  local info = LogicXSuit.GetBaseInfo(period, true, branchId)
  if level ~= nil and info ~= nil and level ~= info.max_level then
    return true
  else
    return false
  end
end
function LogicXSuit.SuitNeedUpgrading(period, branchId)
  local level = LogicXSuit.GetLevelByPeriodSelf(period, branchId)
  local maxLevel = LogicXSuit.GetActSuitMaxLevelByPeriod(period, branchId)
  return 0 < level and level < maxLevel
end
function LogicXSuit.CheckShowByLevel(period, level, BranchId)
  local maxPeriod = LogicXSuit.GetMaxPeriod()
  if not period or period > maxPeriod then
    return false
  end
  local redCfg = xsuit_config_and_cache.GetReddotWithWorkShopByPeriod(period, BranchId, level)
  local version = redCfg and redCfg.version or maxPeriod
  return maxPeriod >= version
end
function LogicXSuit.CheckShowByLevelAndFeature(period, level, feature, branchId)
  local maxPeriod = LogicXSuit.GetMaxPeriod()
  if not period or period > maxPeriod then
    return false
  end
  local redCfg = xsuit_config_and_cache.GetReddotWithWorkShopByPeriod(period, branchId, level, feature)
  local version = redCfg and redCfg.version or maxPeriod
  return maxPeriod >= version
end
function LogicXSuit.IsXSuit(itemID)
  LogicXSuit.InitXSuitItemList(itemID)
  return LogicXSuit.itemInfoList[itemID] ~= nil
end
function LogicXSuit.IsXSuitEmotion(itemID)
  local cfg = CDataTable.GetTableDataByFilter("GoldenSuitMapCfg", "BattleActionID", itemID)
  if cfg then
    return true
  end
  cfg = CDataTable.GetTableDataByFilter("GoldenSuitMapCfg", "InviterActionID", itemID)
  if cfg then
    return true
  end
  return false
end
function LogicXSuit.IsMuNaiYiBlockItem(itemID)
  if not itemID then
    return false
  end
  local config = CDataTable.GetTableData("MuNaiYiBlockCfg", itemID)
  return config ~= nil
end
function LogicXSuit.CheckHasSameGroupItem(resID)
  local period = LogicXSuit.GetPeriodByItemId(resID)
  if not period then
    return false
  end
  local branchId = LogicXSuit.GetBranchByItemId(resID)
  local branchInfo = LogicXSuit.shareTimeList[period] and LogicXSuit.shareTimeList[period][branchId]
  if branchInfo and branchInfo.unlock_flag and branchInfo.level_time and branchInfo.level_time[1] then
    return true, LogicXSuit.GetItemIDByLevel(period, 1, branchId)
  end
  return false
end
function LogicXSuit.CheckDownloadStatus(resID)
  log(bWriteLog and "LogicXSuit.CheckDownloadStatus resID: " .. tostring(resID) .. " " .. type(resID))
  if not _G.IsEditor and not PufferDownloader.PufferJsonDownloadReturn then
    return false
  end
  local period = LogicXSuit.GetPeriodByItemId(resID)
  if not period then
    return false
  end
  local branchId = LogicXSuit.GetBranchByItemId(resID)
  local downloadList = LogicXSuit.GetItemIDListByPeriod(period, branchId)
  local state = PufferManager.GetState(PufferConst.ENUM_DownloadType.ODPAK, downloadList)
  return state == PufferConst.ENUM_DownloadState.Done
end
function LogicXSuit.CheckSingleItemDownloadStatus(resID)
  local state = PufferManager.GetState(PufferConst.ENUM_DownloadType.ODPAK, {resID})
  if state ~= PufferConst.ENUM_DownloadState.Done then
    return false
  else
    return true
  end
end
function LogicXSuit.IsSpecialBranchBox(itemId)
  local boxCfg = CDataTable.GetTableData("XSuitBranchChest", itemId)
  return boxCfg
end
function LogicXSuit.CheckSpecialBranchBoxDownload(itemId)
  local boxCfg = CDataTable.GetTableData("XSuitBranchChest", itemId)
  if boxCfg then
    local list = {}
    table.insert(list, itemId)
    local StringUtil = require("common.string_util")
    local splitRet = StringUtil.Split(boxCfg.DependRes, "|")
    for _, v in pairs(splitRet) do
      if tonumber(v) then
        table.insert(list, tonumber(v))
      elseif StringUtil.Ends(tostring(v), ".mp4") then
        table.insert(list, DataMgr.GetVideoDownloadPath(v))
      else
        table.insert(list, v)
      end
    end
    local state = PufferManager.GetState(PufferConst.ENUM_DownloadType.ODPAK, list)
    if state ~= PufferConst.ENUM_DownloadState.Done then
      local PufferTlog = require("client.slua.logic.download.report.puffer_tlog")
      PufferManager.Download(PufferConst.ENUM_DownloadType.ODPAK, list, PufferTlog.Enum_TLog_From.Avatar, nil, {bFirst = true, bAutoDownload = false})
      return false
    else
      return true
    end
  end
  return false
end
function LogicXSuit.IsItemCollected(period, itemId)
  return LogicXSuit.collectInfo and LogicXSuit.collectInfo[period] and LogicXSuit.collectInfo[period][itemId]
end
function LogicXSuit.IsGetAllXSuitByPeriod(period)
  if LogicXSuit.IsBranch(period) then
    local periodInfo = LogicXSuit.shareTimeList and LogicXSuit.shareTimeList[period]
    for branchId, branchInfo in pairs(periodInfo) do
      if not branchInfo.unlock_flag then
        return true, false
      end
    end
    return true, true
  else
    return false, LogicXSuit.IsBranchUnlocked(period, 0)
  end
end
function LogicXSuit.ShowSendGiftUI(itemId, isFromExchange)
  local Logic_FriendGiftPopupShow = require("client.slua.logic.ItemGiveAndAsk.Logic_FriendGiftPopupShow")
  local Logic_ItemGiveAndAskConst = require("client.slua.logic.ItemGiveAndAsk.Logic_ItemGiveAndAskConst")
  local nGiveType = Logic_ItemGiveAndAskConst.Enum_GiveGiftType.XSuit
  Logic_FriendGiftPopupShow.ShowOnlyGiveFriendGift(nGiveType, itemId, nil, {bGiveXSuitFormExchange = isFromExchange})
end
function LogicXSuit.ShowGiftPacketUI(giftInfo, mailInfo)
  local logic_xsuit_activity = ModuleManager.GetModule(ModuleManager.JumpModuleConfig.logic_xsuit_activity)
  if not LogicXSuit.CheckSpinDownloadState() then
    if not mailInfo then
      return
    end
    if logic_xsuit_activity:IsDrawActivityInfoNotFound() then
      if mailInfo.isFetched == false then
        local ShopGiftPacketLogic = require("client.logic.shop.logic_shop_gift_packet")
        ShopGiftPacketLogic.SendMarketGiftTakeReq(mailInfo.index)
      else
        ShowNotice(102036)
      end
    end
    return
  end
  local Config = require("client.slua.umg.lobby_activity.xsuit_spin.Config.XSuitSpinConfig")
  local GiftPacketCfg = Config.GiftPacket
  if not mailInfo then
    UIManager.ShowUIWithLuaAndBpPath(UIManager.UI_Config.MainUIWithoutLuaAndBpPathAsy, GiftPacketCfg.BaseLua, GiftPacketCfg.BPPath, giftInfo, mailInfo)
  else
    UIManager.ShowUI(UIManager.UI_Config.Xsuit_Gift_Confirm_UIBP, nil, function()
      UIManager.ShowUIWithLuaAndBpPath(UIManager.UI_Config.MainUIWithoutLuaAndBpPathAsy, GiftPacketCfg.BaseLua, GiftPacketCfg.BPPath, giftInfo, mailInfo)
    end)
  end
end
function LogicXSuit.CheckSpinDownloadState()
  local logic_xsuit_activity = ModuleManager.GetModule(ModuleManager.JumpModuleConfig.logic_xsuit_activity)
  local actId = logic_xsuit_activity:GetDrawActivityID()
  if not actId then
    if not logic_xsuit_activity:IsDrawActivityInfoNotFound() then
      XSuitHandler.send_get_gold_dress_activity_req()
      ShowNotice(120164)
    end
    log(bWriteLog and "LogicXSuit.CheckSpinDownloadState false, not actId")
    return false
  end
  local state = PufferManager.GetStateByModuleIDActivityID(BP_ENUM_MODULE_XSUIT_SPIN)
  if state ~= PufferConst.ENUM_DownloadState.Done then
    log(bWriteLog and "LogicXSuit.CheckSpinDownloadState false, state = " .. tostring(state))
    return false
  end
  return true
end
function LogicXSuit.PopCommonTip(msglist)
  if not msglist or not next(msglist) then
    return
  end
  if IsWoWEditor then
    return
  end
  local uidlist = {}
  for i, v in ipairs(msglist) do
    table.insert(uidlist, v.uid)
  end
  local cb = function()
    local logic_achievement_float_tip = require("client.slua.logic.achievement.logic_achievement_float_tip")
    if logic_achievement_float_tip.IslenthZeroNewAchievementList() then
      local logic_tarotcard_exchange_sendgift = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_tarotcard_exchange_sendgift)
      local GetGiftTipPriority = function(msgInfo)
        if LogicXSuit.GetPeriodByItemId(msgInfo.item) or CDataTable.GetTableData("XSuitBranchChest", msgInfo.item) then
          return 1
        elseif logic_tarotcard_exchange_sendgift:CanPop(msgInfo.item) then
          return 2
        elseif msgInfo.bSmallRPCardGift then
          return 3
        end
        return 4
      end
      table.sort(msglist, function(a, b)
        return GetGiftTipPriority(a) < GetGiftTipPriority(b)
      end)
      for i, v in ipairs(msglist) do
        if LogicXSuit.GetPeriodByItemId(v.item) or CDataTable.GetTableData("XSuitBranchChest", v.item) then
          LogicXSuit.CheckXsuitAssert({
            PufferConst.EODPackID.XSuit
          }, function()
            UIManager.ShowUI(UIManager.UI_Config.XSuit_Mail_Gift_UIBP, v)
          end, nil, {bFirst = true, bAutoDownload = false})
        elseif logic_tarotcard_exchange_sendgift:CanPop(v.item) then
          local queueParam = ui_show_queue_config.GetParamTable(nil, nil, nil, GiftTipSortWeightOffset.Tarot)
          UIManager.ShowUI(UIManager.UI_Config.TarotCardGiftReceiveTips, v, queueParam)
        elseif v.bSmallRPCardGift then
          local queueParam = ui_show_queue_config.GetParamTable(nil, nil, nil, GiftTipSortWeightOffset.SmallRP)
          UIManager.ShowUI(UIManager.UI_Config.Common_Receive_UIBP, v, queueParam)
        else
          UIManager.ShowUI(UIManager.UI_Config.Common_Receive_UIBP, v)
        end
      end
    end
  end
  local logic_profile_get_wrap = require("client.slua.logic.user.profile.logic_profile_get_wrap")
  logic_profile_get_wrap.GetFriendProfiles(0, uidlist, cb)
end
function LogicXSuit.ClosePopTip()
  local ui = UIManager.GetUI(UIManager.UI_Config.Common_Receive_UIBP)
  if ui then
    UIManager.CloseUI(UIManager.UI_Config.Common_Receive_UIBP)
  end
end
function LogicXSuit.CreateXsuitShareConfig(period, branchId)
  local shareCfg = xsuit_config_and_cache.GetShareWithWorkshopByPeriod(period or 0, branchId)
  local config = {
    moduleName = "client.slua.umg.XSuit_Workshop.Page.XSuit_Share_Base_UIBP",
    path = shareCfg and shareCfg.path,
    isSingleton = false,
    asy = true,
    uiStat = {name = "??-????"},
    AndroidBackType = 2,
    keyName = string.format("golden_suit_share_base_%d", period or 0)
  }
  return config
end
function LogicXSuit.ShowGoldSuitShareUI(itemId, bReleaseMoment, closeFunc)
  local period = LogicXSuit.GetPeriodByItemId(itemId)
  local branchId = LogicXSuit.GetBranchByItemId(itemId)
  local baseCfg = LogicXSuit.CreateXsuitShareConfig(period, branchId)
  if bReleaseMoment then
    local logic_moment = require("client.slua.logic.moment.logic_moment")
    logic_moment.ShowMomentShare()
  else
    local Util = require("client.slua_ui_framework.util")
    local cfg = {
      campaign = "golden_suit",
      isOld = true,
      nItemId = itemId,
      share_type = ShareBtnTLogShareTypeDefine.HolyCostume,
      reasonStr = json.encode({
        uid = DataMgr.roleData.uid,
        itemId = itemId
      }),
      closeFunc = closeFunc
    }
    local ShareMgr = require("client.logic.share.share_logic")
    ShareMgr.ShareBtnReq(1, ShareBtnTLogShareTypeDefine.HolyCostume, nil, nil)
    Util.ShowShare(cfg, baseCfg, itemId)
  end
end
function LogicXSuit.CheckShareReady(itemId)
  local period = LogicXSuit.GetPeriodByItemId(itemId)
  if period then
    local branchId = LogicXSuit.GetBranchByItemId(itemId)
    local baseCfg = LogicXSuit.CreateXsuitShareConfig(period, branchId)
    local pak_util = require("client.common.pak_util")
    local isDownloaded = pak_util.IsPufferDownloaded(baseCfg.path)
    return isDownloaded, baseCfg.path
  end
  return true
end
function LogicXSuit.ShowUpgradeUI(period, branchId, itemId, state, featureIndex)
  local LogicFitVersionDownload = require("client.slua.logic.download.fit.logic_fitVersion_download")
  if LogicFitVersionDownload.IfNotFitLobbyResDownloadedShowWindow() then
    return
  end
  if not GlobalData.ActResourceDownloaded({
    PufferConst.EODPackID.XSuit
  }, nil, nil, PufferConst.ENUM_DownloadType.ODPACK) then
    return false
  end
  if LogicXSuit.openUpgrade then
    UIManager.ShowUI(UIManager.UI_Config.XSuit_Workshop_Main_UIBP, period, branchId, itemId, state, featureIndex)
    return true
  else
    ShowNotice(120001)
    return false
  end
end
function LogicXSuit.ShowUpgradeUIFromURL()
  local isOpen = LogicXSuit.openUpgrade
  if not isOpen then
    ShowNotice(120001)
    return
  end
  local level_unlock_manager = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.level_unlock_manager)
  if not level_unlock_manager:IsFeatureUnlocked(level_unlock_manager.featureDef.workshop) then
    ShowNotice(level_unlock_manager:GetLockTip(level_unlock_manager.featureDef.workshop))
    return
  end
  LogicXSuit.ShowUpgradeUI()
end
function LogicXSuit.ShowUpgradeSuccessUI(curLevel, period, branch_id)
  local upgradeInfo = LogicXSuit.GetUpgradeInfo(period, true, branch_id)
  if not upgradeInfo or not upgradeInfo[curLevel] then
    return
  end
  local config = CDataTable.GetTableDataByFilter("XSuitCommonBranch", "Period", period, "IsBranch", 0)
  local uiConfig = {
    keyName = "XSuit_Workshop_Upgrade_Success_UIBP",
    moduleName = "client.slua.umg.XSuit_Workshop.Popup.XSuit_Workshop_Upgrade_Success_UIBP",
    path = config and config.UpgradeSpecialShow ~= "" and config.UpgradeSpecialShow or "/Game/Arts_UI/FromUMG/XSuit/XsuitWorkShop/XSuit_Common_AscendStar_UIBP.XSuit_Common_AscendStar_UIBP",
    containerName = UIContainers.Top,
    zOrder = EFixedZOrder.CommonPopup,
    asy = true,
    uiStat = {name = "??-??????"}
  }
  local info = {
    item_id = upgradeInfo[curLevel].item_id,
    level = curLevel,
    max_level = LogicXSuit.GetActSuitMaxLevelByPeriod(period, branch_id),
    need_jump = upgradeInfo[curLevel].cfg.NeedJump,
    branch_id = branch_id,
    period = period,
    bSpecialShow = config and config.UpgradeSpecialShow ~= ""
  }
  UIManager.ShowUI(uiConfig, info)
end
function LogicXSuit.ShowUnlockStateSuccessUI(oldInfo, info)
  for period, data in pairs(info) do
    local oldData = oldInfo[period]
    for branchId, branchData in pairs(data) do
      local oldBranchData = oldData[branchId]
      for state, v in pairs(branchData.unlock_state) do
        local oldV = oldBranchData.unlock_state[state]
        if not oldV or v ~= oldV then
          local ItemGetModule = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.rare_item_get_module)
          ItemGetModule:ShowOneXSuit(period, state)
          return
        end
      end
    end
  end
end
function LogicXSuit.JumpToVideo(id)
  LogicXSuit.ShowUpgradeUI()
end
function LogicXSuit.CheckHasEquipXSuitByAction(action_id)
  local TeamAvatarManager = require("client.logic.avatar.logic_team_avatar_manager")
  local data = LogicXSuit.actionPeriodMap[action_id]
  local info = LogicXSuit.GetUpgradeInfo(data.Period, true, data.BranchId or 0)
  if not info then
    return false, false
  end
  local avatar = TeamAvatarManager.GetMainAvatar()
  local multi_state_manager = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.multi_state_manager)
  for i, info in pairs(info) do
    if avatar:HasEquiped(info.item_id) then
      return true, 1 < i
    end
    local allDisplayID = multi_state_manager:GetAllDisplayClothIDByOriginID(info.item_id)
    if allDisplayID then
      for _, disPlayID in pairs(allDisplayID) do
        if avatar:HasEquiped(disPlayID) then
          return true, 1 < i
        end
      end
    end
  end
  return false, false
end
function LogicXSuit.RefreshAllTeammateRelic()
  for uid, data in pairs(LogicXSuit.relicInfoList) do
    if data and data.status and data.wearID ~= 0 then
      local TeamAvatarManager = require("client.logic.avatar.logic_team_avatar_manager")
      TeamAvatarManager.PutonEquipment(uid, data.wearID)
    end
  end
end
function LogicXSuit.OnRelicStatusChange(uid, itemid, status)
  local TeamAvatarManager = require("client.logic.avatar.logic_team_avatar_manager")
  uid = tostring(uid)
  if not LogicXSuit.relicInfoList[uid] then
    LogicXSuit.relicInfoList[uid] = {status = false, wearID = 0}
  end
  local relicInfo = LogicXSuit.relicInfoList[uid]
  local oldStatus = relicInfo.status or false
  local afterStatus = status == 2 and itemid ~= 0
  if itemid == 0 then
    afterStatus = false
  end
  log(bWriteLog and "[Debug][Suit][Team] GetPlayerRelicStatus change uid = " .. tostring(uid) .. "|| oldStatus = " .. tostring(oldStatus) .. " || afterStatus = " .. tostring(afterStatus))
  local oldWearID = relicInfo.wearID
  relicInfo.status = afterStatus
  relicInfo.wearID = afterStatus and itemid or 0
  if oldStatus and not afterStatus then
    if itemid ~= 0 then
      TeamAvatarManager.PutoffEquipment(uid, itemid)
    end
    if oldWearID ~= 0 and oldWearID ~= itemid then
      TeamAvatarManager.PutoffEquipment(uid, oldWearID)
    end
    local logic_share_bag_team_util = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_share_bag_team_util)
    local selectSharedItems = logic_share_bag_team_util:GetLastSelectSharedItemsByUID(uid)
    logic_share_bag_team_util:UpdateTeamAvatar(uid, selectSharedItems, true)
    EventSystem:postEvent(EVENTTYPE_GOLDEN_SUIT, EVENTID_GOLDEN_SUIT_REFRESH_RELIC_STATUS)
    if uid == tostring(DataMgr.roleData.uid) then
      EventSystem:postEvent(EVENTTYPE_GOLDEN_SUIT, EVENTID_GOLDEN_SUIT_UPDATE_RELIC_STATUS, oldWearID, false)
    end
  elseif not oldStatus and afterStatus then
    TeamAvatarManager.PutonEquipment(uid, itemid)
    EventSystem:postEvent(EVENTTYPE_GOLDEN_SUIT, EVENTID_GOLDEN_SUIT_REFRESH_RELIC_STATUS)
    if uid == tostring(DataMgr.roleData.uid) then
      EventSystem:postEvent(EVENTTYPE_GOLDEN_SUIT, EVENTID_GOLDEN_SUIT_UPDATE_RELIC_STATUS, itemid, true)
    end
  elseif oldStatus and afterStatus then
    TeamAvatarManager.PutoffEquipment(uid, oldWearID)
    TeamAvatarManager.PutonEquipment(uid, itemid)
    EventSystem:postEvent(EVENTTYPE_GOLDEN_SUIT, EVENTID_GOLDEN_SUIT_REFRESH_RELIC_STATUS)
    if uid == tostring(DataMgr.roleData.uid) then
      EventSystem:postEvent(EVENTTYPE_GOLDEN_SUIT, EVENTID_GOLDEN_SUIT_UPDATE_RELIC_STATUS, itemid, true)
    end
  end
end
function LogicXSuit.CheckAndPlayEnterAction(AvatarUID)
  local actionID = LogicXSuit.GetNeedPlayActionID(AvatarUID)
  if actionID == nil then
    return false
  end
  log(bWriteLog and "LogicXSuit.CheckAndPlayEnterAction" .. actionID)
  LogicXSuit.SetPlayedActionUid(AvatarUID)
  local TeamAvatarManager = require("client.logic.avatar.logic_team_avatar_manager")
  TeamAvatarManager.StopAction(AvatarUID)
  local time_ticker = require("common.time_ticker")
  time_ticker.AddTimerOnce(0.01, function()
    log(bWriteLog and "CheckAndPlayEnterAction GoldenSuit actionID:" .. tostring(actionID))
    TeamAvatarManager.PlayAction(AvatarUID, actionID)
  end)
  return true
end
function LogicXSuit.GetNeedPlayActionID(uid)
  local numberUid = tonumber(uid)
  if numberUid and LogicXSuit.playedActionUidMap[numberUid] then
    return nil
  end
  local info = LogicXSuit.needPlayActionMember[tostring(uid)]
  if info and info.itemID and LogicXSuit.CheckSingleItemDownloadStatus(info.itemID) then
    return info.actionID
  end
  return nil
end
function LogicXSuit.RefreshPlayActionUidList(info)
  if not info or not info.members then
    return
  end
  for k, v in pairs(LogicXSuit.playedActionUidMap) do
    if not info.members[k] then
      LogicXSuit.playedActionUidMap[k] = false
    end
  end
end
function LogicXSuit.RefreshSharedRelicInfo(info)
  log(bWriteLog and "LogicXSuit.RefreshSharedRelicInfo")
  if not GameStatus.IsInLobbyOrMainCity() then
    return
  end
  local TeamUpNewSystem = require("client.slua.logic.teamup.logic_team_up")
  local team_info = info or TeamUpNewSystem.teamInfo
  if not team_info or not team_info.members then
    return
  end
  LogicXSuit.needShowRelicID = 0
  LogicXSuit.needShowRelicUid = 0
  LogicXSuit.playerEquipItemID = 0
  local needShowRating = 0
  local wardrobe_data = require("client.slua.logic.wardrobe.wardrobe_data")
  for _, v in pairs(team_info.members) do
    local golden_suit_id = 0
    if v.uid == tonumber(DataMgr.roleData.uid) then
      local tRoleWear = AvatarData.GetRoleWear()
      for _, instId in ipairs(tRoleWear) do
        local data = wardrobe_data:GetHallDepotItemDataByInsID(instId)
        if data and data.resID and LogicXSuit.IsXSuit(data.resID) and wardrobe_data:GetItemSource(instId) ~= EWardrobeDataSource.InheritWardrobe and LogicXSuit.CheckHasEquipXSuit() then
          golden_suit_id = data.resID
          LogicXSuit.playerEquipItemID = golden_suit_id
          break
        end
      end
    elseif v.wear_ext and v.wear_ext[3] and v.wear_ext[3][1] and v.wear_ext[3][ENUM_AVATAR_DATA_TYPE.Source] ~= EWardrobeDataSource.InheritWardrobe then
      local multi_state_manager = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.multi_state_manager)
      local OriginItemID = multi_state_manager:GetOriginClothIDAndState(v.wear_ext[3][1]) or v.wear_ext[3][1]
      if LogicXSuit.IsXSuit(OriginItemID) then
        golden_suit_id = OriginItemID
      end
    end
    local relicID = LogicXSuit.GetShowRelicID(golden_suit_id)
    if relicID and needShowRating < v.max_segment_rating then
      LogicXSuit.needShowRelicID = relicID
      LogicXSuit.needShowRelicUid = tostring(v.uid)
      needShowRating = v.max_segment_rating
    end
  end
  log(bWriteLog and string.format("[Debug][Suit][Team] LogicXSuit.RefreshSharedRelicInfo needShowRelicId: %d, needShowRelicUid: %d", LogicXSuit.needShowRelicID or 0, LogicXSuit.needShowRelicUid or 0))
  EventSystem:postEvent(EVENTTYPE_GOLDEN_SUIT, EVENTID_GOLDEN_SUIT_REFRESH_RELIC_STATUS)
end
function LogicXSuit.GetXSuitTeamupAction(member_info)
  if not member_info then
    return
  end
  local action_info = LogicXSuit.needPlayActionMember[tostring(member_info.uid)]
  if not action_info then
    return
  end
  return action_info.actionID
end
function LogicXSuit.SyncXSuitScheme(teamInfo, gold_dress_set_info_all)
  if teamInfo.members == nil then
    return false
  end
  for _, v in pairs(teamInfo.members) do
    local isOtherPlayer = tostring(v.uid) ~= DataMgr.roleData.uid
    if isOtherPlayer then
      gold_dress_set_info_all = gold_dress_set_info_all or v.gold_dress_set_info_all
      LogicXSuit._SyncTeammateXSuitSchemeToLobbyPawn(v, gold_dress_set_info_all)
    end
  end
end
function LogicXSuit._SyncTeammateXSuitSchemeToLobbyPawn(v, gold_dress_set_info_all)
  if not v or not v.uid then
    return
  end
  local TeamAvatarManager = require("client.logic.avatar.logic_team_avatar_manager")
  local Avatar = TeamAvatarManager.GetAvatarByUid(tostring(v.uid))
  if not Avatar then
    return
  end
  local LobbyPawn = Avatar:GetModel()
  if not slua.isValid(LobbyPawn) or not LobbyPawn.SetClothSchemeIDList then
    return
  end
  local schemeIDList = {}
  local setInfo = gold_dress_set_info_all and gold_dress_set_info_all.set_info
  if setInfo then
    for _, periodData in pairs(setInfo) do
      if periodData then
        for _, branchData in pairs(periodData) do
          if branchData and branchData.personal_equip_info then
            for _, schemeID in pairs(branchData.personal_equip_info) do
              if schemeID and 0 < schemeID then
                table.insert(schemeIDList, schemeID)
              end
            end
          end
        end
      end
    end
  end
  LobbyPawn:SetClothSchemeIDList(schemeIDList)
end
function LogicXSuit.GetSelfSchemeIDList()
  local schemeIDList = {}
  local equip_data = LogicXSuit.equip_data
  if equip_data then
    for _, periodData in pairs(equip_data) do
      if periodData then
        for _, branchData in pairs(periodData) do
          if branchData then
            for _, schemeID in pairs(branchData) do
              if schemeID and 0 < schemeID then
                table.insert(schemeIDList, schemeID)
              end
            end
          end
        end
      end
    end
  end
  return schemeIDList
end
function LogicXSuit._SyncSelfXSuitSchemeToLobbyPawn()
  log(bWriteLog and "LogicXSuit._SyncSelfXSuitSchemeToLobbyPawn")
  if not (DataMgr and DataMgr.roleData) or not DataMgr.roleData.uid then
    return
  end
  local TeamAvatarManager = require("client.logic.avatar.logic_team_avatar_manager")
  local Avatar = TeamAvatarManager.GetAvatarByUid(tostring(DataMgr.roleData.uid))
  if not Avatar then
    return
  end
  local LobbyPawn = Avatar:GetModel()
  if not slua.isValid(LobbyPawn) or not LobbyPawn.SetClothSchemeIDList then
    return
  end
  LobbyPawn:SetClothSchemeIDList(LogicXSuit.GetSelfSchemeIDList())
end
function LogicXSuit.RefreshTeamInfo(info)
  if not GameStatus.IsInLobbyOrMainCity() then
    return
  end
  local team_info = info
  if team_info == nil then
    local TeamUpNewSystem = require("client.slua.logic.teamup.logic_team_up")
    team_info = TeamUpNewSystem.teamInfo
  end
  if not (team_info.members ~= nil and team_info.player_count) or team_info.player_count <= 1 then
    LogicXSuit.ClearPlayedActionUid()
  end
  if team_info.members == nil then
    return false
  end
  LogicXSuit.RefreshPlayActionUidList(info)
  LogicXSuit.needPlayActionMember = {}
  local team_member = 0
  local wardrobe_data = require("client.slua.logic.wardrobe.wardrobe_data")
  for _, v in pairs(team_info.members) do
    local golden_suit_id = 0
    local golden_suit_source = EWardrobeDataSource.Wardrobe
    local unlockLevel
    local state = 0
    LogicXSuit.playerEquipItemID = 0
    if v.uid == tonumber(DataMgr.roleData.uid) then
      local tRoleWear = AvatarData.GetRoleWear()
      for _, instId in pairs(tRoleWear) do
        local data = wardrobe_data:GetHallDepotItemDataByInsID(instId)
        if data and data.resID and LogicXSuit.IsXSuit(data.resID) and LogicXSuit.CheckHasEquipXSuit() then
          golden_suit_source = wardrobe_data:GetItemSource(instId)
          local period = LogicXSuit.GetPeriodByItemId(data.resID)
          if period then
            golden_suit_id = data.resID
            local branch = LogicXSuit.GetBranchByItemId(data.resID) or 0
            if v.gold_dress_set_info and v.gold_dress_set_info.set_info and v.gold_dress_set_info.set_info[period] and v.gold_dress_set_info.set_info[period][branch] and golden_suit_source ~= EWardrobeDataSource.InheritWardrobe then
              golden_suit_id = LogicXSuit.GetSwitchItemByItemAndSwitchLevel(data.resID, v.gold_dress_set_info.set_info[period][branch])
            end
          end
          LogicXSuit.playerEquipItemID = golden_suit_id
          if period then
            unlockLevel = LogicXSuit.GetLevelByItemId(data.resID)
            state = LogicXSuit.GetCurStateByInsID(instId)
          end
          break
        end
      end
    elseif v.wear_ext and v.wear_ext[3] and v.wear_ext[3][1] then
      local period = LogicXSuit.GetPeriodByItemId(v.wear_ext[3][1])
      if period then
        local branch = LogicXSuit.GetBranchByItemId(v.wear_ext[3][1]) or 0
        unlockLevel = LogicXSuit.GetLevelByItemId(v.wear_ext[3][1])
        golden_suit_source = v.wear_ext[3][ENUM_AVATAR_DATA_TYPE.Source] or golden_suit_source
        golden_suit_id = v.wear_ext[3][ENUM_AVATAR_DATA_TYPE.ItemID]
        if golden_suit_source ~= EWardrobeDataSource.InheritWardrobe and v.gold_dress_set_info and v.gold_dress_set_info.set_info and v.gold_dress_set_info.set_info[period] and v.gold_dress_set_info.set_info[period][branch] then
          golden_suit_id = LogicXSuit.GetSwitchItemByItemAndSwitchLevel(v.wear_ext[3][1], v.gold_dress_set_info.set_info[period][branch])
        end
        if v.gold_dress_set_info_all and v.gold_dress_set_info_all.set_info and v.gold_dress_set_info_all.set_info[period] and v.gold_dress_set_info_all.set_info[period][branch] then
          state = v.gold_dress_set_info_all.set_info[period][branch].bicolor_state
        end
      end
    end
    local isOtherPlayer = tostring(v.uid) ~= DataMgr.roleData.uid
    local actionID = LogicXSuit.GetActionByItemId(golden_suit_id, isOtherPlayer, state, unlockLevel, v) or 0
    log(bWriteLog and "v.uid  = " .. tostring(v.uid) .. " || actionID = " .. tostring(actionID))
    if actionID and actionID ~= 0 then
      LogicXSuit.needPlayActionMember[tostring(v.uid)] = {actionID = actionID, itemID = golden_suit_id}
    end
    team_member = team_member + 1
  end
  LogicXSuit.RefreshSharedRelicInfo(info)
end
function LogicXSuit.CheckHasEquipXSuit(uid, tarAvatar, period)
  local TeamAvatarManager = require("client.logic.avatar.logic_team_avatar_manager")
  local avatar
  if tarAvatar then
    avatar = tarAvatar
  elseif uid ~= nil then
    avatar = TeamAvatarManager.GetAvatarByUid(uid)
  else
    avatar = TeamAvatarManager.GetMainAvatar()
  end
  if not avatar then
    return false
  end
  local multi_state_manager = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.multi_state_manager)
  local equipmentsInfoList = avatar:GetEquipments()
  for k, v in pairs(equipmentsInfoList) do
    if v.itemID then
      if LogicXSuit.IsXSuit(v.itemID) then
        return true
      end
      local originCloth = multi_state_manager:GetOriginClothIDAndState(v.itemID)
      if originCloth and LogicXSuit.IsXSuit(originCloth) then
        return true
      end
    end
  end
  return false
end
function LogicXSuit.SetPlayedActionUid(uid)
  local numberUid = tonumber(uid)
  if numberUid then
    LogicXSuit.playedActionUidMap[numberUid] = true
  end
end
function LogicXSuit.ClearPlayedActionUid()
  LogicXSuit.playedActionUidMap = {}
end
function LogicXSuit.CheckNeedPutOnRelic(uid)
  log(bWriteLog and "[jonahwei][Suit][Team] CheckNeedPutOnRelic uid = " .. tostring(uid))
  local relicInfo = LogicXSuit.relicInfoList[uid]
  if relicInfo and relicInfo.status == true and relicInfo.wearID ~= 0 then
    return true, relicInfo.wearID
  end
  return false
end
function LogicXSuit.GetPlayerRelicStatus(uid)
  uid = tostring(uid)
  log(bWriteLog and "[Debug][Suit][Team] GetPlayerRelicStatus uid = " .. tostring(uid) .. "|| LogicXSuit.needShowUid = " .. tostring(LogicXSuit.needShowRelicUid) .. "|| relicInfoList[uid].status = " .. tostring(LogicXSuit.relicInfoList[uid] and LogicXSuit.relicInfoList[uid].status) .. " CheckHasEquipXSuit(): " .. tostring(LogicXSuit.CheckHasEquipXSuit()) .. " LogicXSuit.playerEquipItemID: " .. tostring(LogicXSuit.playerEquipItemID))
  if LogicXSuit.needShowRelicUid == tonumber(DataMgr.roleData.uid) or LogicXSuit.needShowRelicUid == 0 or LogicXSuit.CheckHasEquipXSuit() then
    return nil
  end
  if LogicXSuit.playerEquipItemID ~= 0 then
    return nil
  end
  local relicInfo = LogicXSuit.relicInfoList[uid]
  return relicInfo and relicInfo.status or false
end
function LogicXSuit.GetRelateItemBySchemeID(schemeID)
  if not schemeID or schemeID <= 0 then
    return nil
  end
  local row = CDataTable.GetTableDataByFilter("XSuitCustomScheme", "SchemeID", schemeID)
  if row and row.RelateItem and 0 < row.RelateItem then
    return row.RelateItem
  end
  return nil
end
function LogicXSuit.GetActionByItemId(itemID, isOtherPlayer, state, unlockLevel, v)
  local gold_dress_set_info_all = v.gold_dress_set_info_all
  local action_type_set_info = v.action_type_set_info
  local period = LogicXSuit.GetPeriodByItemId(itemID)
  if period ~= nil then
    local level = LogicXSuit.GetLevelByItemId(itemID)
    if level < 2 then
      return 0
    end
    local branchId = LogicXSuit.GetBranchByItemId(itemID)
    local cfg = LogicXSuit.GetBranchMapData(period, branchId)
    if not cfg then
      return 0
    end
    local low_action_id = cfg.LowTeamupActionID
    local XSuitSchemeFeatureType = require("GameLua.Activity.Commercialize.GamePlay.XSuit.XSuitSchemeFeatureType")
    local equipInfo = gold_dress_set_info_all and gold_dress_set_info_all.set_info and gold_dress_set_info_all.set_info[period] and gold_dress_set_info_all.set_info[period][branchId] and gold_dress_set_info_all.set_info[period][branchId].personal_equip_info
    local schemeID = equipInfo and equipInfo[XSuitSchemeFeatureType.TeamEnter2]
    if schemeID and 0 < schemeID then
      local schemeEmoteID = LogicXSuit.GetRelateItemBySchemeID(schemeID)
      if schemeEmoteID and 0 < schemeEmoteID then
        low_action_id = schemeEmoteID
      end
    end
    local UnLockFeatureType = require("GameLua.Activity.Commercialize.GamePlay.XSuit.UnLockFeatureType")
    local XSuitUtil = require("GameLua.Activity.Commercialize.GamePlay.XSuit.XSuitUtil")
    local isUnLockFeature, FeatureLevel, FeatureIndex = XSuitUtil:IsUnlockedFeature(period, branchId, UnLockFeatureType.TeamEnterAction2)
    if not isUnLockFeature or gold_dress_set_info_all and gold_dress_set_info_all.set_info and gold_dress_set_info_all.set_info[period] and gold_dress_set_info_all.set_info[period][branchId] and gold_dress_set_info_all.set_info[period][branchId].unlock_info and gold_dress_set_info_all.set_info[period][branchId].unlock_info[FeatureLevel] and gold_dress_set_info_all.set_info[period][branchId].unlock_info[FeatureLevel][FeatureIndex] and gold_dress_set_info_all.set_info[period][branchId].unlock_info[FeatureLevel][FeatureIndex].state == 1 then
    else
      low_action_id = 0
    end
    if level == 2 and 0 < low_action_id then
      return low_action_id
    end
    if level < 5 then
      local LowLevelEffect = require("GameLua.Activity.Commercialize.GamePlay.XSuit.LowLevelEffect")
      if not XSuitUtil:IsValidXSuitEffect(itemID, LowLevelEffect.TeamEnterAction5, unlockLevel) then
        return low_action_id
      end
    end
    if isOtherPlayer then
      if action_type_set_info and action_type_set_info.set_info and action_type_set_info.set_info[period] and action_type_set_info.set_info[period][branchId] and action_type_set_info.set_info[period][branchId] == 2 then
        return low_action_id
      end
      local otherActionId = cfg.OtherTeamupActionID
      if otherActionId and otherActionId ~= 0 then
        return otherActionId
      end
    else
      local levelAction = LogicXSuit.GetLevelAction(period, branchId)
      if levelAction == 2 then
        return low_action_id
      end
    end
    local action = cfg.TeamupActionID
    local multi_state_manager = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.multi_state_manager)
    action = multi_state_manager:ChangeEmoteByState(action, state)
    return action
  end
  return nil
end
function LogicXSuit.IsNeedStopActionWhenPutOn(actionID)
  if not LogicXSuit.inviteActionMap then
    LogicXSuit.InitInviteAction()
  end
  for i, j in pairs(LogicXSuit.inviteActionMap) do
    if i == actionID then
      return true
    end
    for _, jj in pairs(j) do
      if jj == actionID then
        return true
      end
    end
  end
  return false
end
function LogicXSuit.IsInviteAction(action_id)
  if not action_id or action_id == 0 then
    return false
  end
  if not LogicXSuit.inviteActionMap then
    LogicXSuit.InitInviteAction()
  end
  return LogicXSuit.inviteActionMap[action_id] ~= nil
end
function LogicXSuit.GetInviteeActionList(action_id)
  if not LogicXSuit.inviteActionMap then
    LogicXSuit.InitInviteAction()
  end
  return LogicXSuit.inviteActionMap[action_id]
end
function LogicXSuit.CheckNeedSendInvite(inviter_action_id)
  log(bWriteLog and "CheckNeedSendInvite inviter_action_id = " .. tostring(inviter_action_id) .. " || value  = " .. tostring(LogicXSuit.inviteActionMap[inviter_action_id]))
  LogicXSuit.GetBaseInfo(1, true, 0)
  local TimeUtil = require("client.common.time_util")
  local time = TimeUtil.GetServerTimeInSec()
  if time - LogicXSuit.lastSendInviteTime <= 5 then
    log(bWriteLog and "CheckNeedSendInvite inviter_action_id is in CD ,cd = " .. tostring(time - LogicXSuit.lastSendInviteTime))
    return
  end
  LogicXSuit.lastSendInviteTime = time
  local inviteeActionIDs = LogicXSuit.inviteActionMap[inviter_action_id]
  if inviteeActionIDs ~= nil then
    XSuitHandler.send_change_emtion_action_req(inviter_action_id)
  end
end
function LogicXSuit.IsMatchAction(uid, actionID, suitID)
  if not (uid and actionID) or not suitID then
    return false
  end
  local actionInfo = LogicXSuit.needPlayActionMember[uid]
  if not actionInfo then
    return false
  end
  if actionInfo.itemID ~= suitID then
    return false
  end
  if actionInfo.actionID == actionID then
    return true
  end
  if actionInfo.actionID == 12219234 and actionID == 12219233 or actionInfo.actionID == 12219260 and actionID == 12219259 then
    return true
  end
  return false
end
function LogicXSuit.HasEliminationKingOverrideAvailable(ItemResID, CurItemLevel)
  if not (ItemResID and CurItemLevel) or CurItemLevel <= 0 then
    return false
  end
  local XSuitUtil = require("GameLua.Activity.Commercialize.GamePlay.XSuit.XSuitUtil")
  local Period = XSuitUtil:GetPeriodByItemId(ItemResID)
  if not Period or Period <= 0 then
    return false
  end
  local StateCfg = CDataTable.GetTableData("ClothingStateConfig", ItemResID)
  local SelfOriginClothID = StateCfg and StateCfg.OriginClothID or ItemResID
  local SelfState = StateCfg and StateCfg.State or 0
  local BattleEffectTable = CDataTable.GetTable("GoldClothBattleEffect")
  if not BattleEffectTable then
    return false
  end
  for CandidateID, CandidateCfg in pairs(BattleEffectTable) do
    if CandidateCfg.KingEliminationOverrideID and 0 < CandidateCfg.KingEliminationOverrideID then
      local CPeriod = XSuitUtil:GetPeriodByItemId(CandidateID)
      local CLevel = XSuitUtil:GetLevelByItemId(CandidateID) or 0
      if CPeriod == Period and CurItemLevel >= CLevel then
        local CCfg = CDataTable.GetTableData("ClothingStateConfig", CandidateID)
        local CandOrigin = CCfg and CCfg.OriginClothID or CandidateID
        local CandState = CCfg and CCfg.State or 0
        if CandOrigin == SelfOriginClothID and CandState == SelfState then
          return true
        end
      end
    end
  end
  return false
end
function LogicXSuit.GetEliminationKingClothOverrideEnabled()
  if LogicXSuit.EliminationKingClothOverrideEnabled == nil and not LogicXSuit._FetchingEliminationKingOverride then
    LogicXSuit._FetchingEliminationKingOverride = true
    XSuitHandler.send_gold_dress_get_eliminate_req()
  end
  return LogicXSuit.EliminationKingClothOverrideEnabled
end
function LogicXSuit.SetEliminationKingClothOverrideEnabled(flag)
  LogicXSuit.EliminationKingClothOverrideEnabled = flag == true and true or false
  LogicXSuit._FetchingEliminationKingOverride = false
  EventSystem:postEvent(EVENTTYPE_XSUIT, EVENTID_XSUIT_ELIMINATION_KING_OVERRIDE_UPDATE)
end
function LogicXSuit.ComputeEliminationKingOverrideDefault()
  local LogicEliminationKingEffect = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicEliminationKingEffect)
  local EquipedEffectId = LogicEliminationKingEffect and LogicEliminationKingEffect:GetCurEquipedEffectId() or nil
  return EquipedEffectId == nil or EquipedEffectId == 0
end
function LogicXSuit.IsEliminationKingOverrideFirstFetch()
  local PlayerPrefsSystem = require("client.logic.LogicPlayerPrefs.playerprefs")
  local data = PlayerPrefsSystem.LoadFileToTable_N(PlayerPrefsSystem.ePlayerPrefsType.eXsuitEliminationKingOverrideInited)
  return data == nil or data.inited ~= true
end
function LogicXSuit.MarkEliminationKingOverrideInited()
  local PlayerPrefsSystem = require("client.logic.LogicPlayerPrefs.playerprefs")
  PlayerPrefsSystem.SaveTableToFile_N({inited = true}, PlayerPrefsSystem.ePlayerPrefsType.eXsuitEliminationKingOverrideInited)
end
function LogicXSuit.HasAnyXSuitAtElimOverrideTier()
  if not LogicXSuit.shareTimeList then
    return false
  end
  for period, periodInfo in pairs(LogicXSuit.shareTimeList) do
    if type(periodInfo) == "table" then
      for branchId, branchInfo in pairs(periodInfo) do
        if type(branchInfo) == "table" and branchInfo.unlock_flag and (branchInfo.current or 0) >= 6 then
          local ItemResID = LogicXSuit.GetItemIDByLevel(period, 6, branchId)
          if ItemResID and LogicXSuit.HasEliminationKingOverrideAvailable(ItemResID, 6) then
            return true
          end
        end
      end
    end
  end
  return false
end
function LogicXSuit.SendGetGoldDressStateReq()
  log(bWriteLog and "LogicXSuit.SendGetGoldDressStateReq")
  XSuitHandler.send_get_gold_dress_state_req()
end
function LogicXSuit.OnGetGoldDressStateRsp(info, inherit_all_state_info)
  local LogicInheritWardrobe = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.LogicInheritWardrobe)
  LogicInheritWardrobe:CacheXSuitStateInfo(inherit_all_state_info or {})
  if info or inherit_all_state_info then
    if LogicXSuit.stateInfo and info then
      LogicXSuit.ShowUnlockStateSuccessUI(LogicXSuit.stateInfo, info)
    end
    LogicXSuit.stateInfo = info or {}
    LogicXSuit.UpdateLobbyAvatar(true)
    EventSystem:postEvent(EVENTTYPE_GOLDEN_SUIT, EVENTID_GOLDEN_SUIT_UPDATE_DRESS_STATE)
    EventSystem:postEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_AVATAR_DATA_CHANGE)
  else
    log(bWriteLog and "LogicXSuit.OnGetGoldDressStateRsp miss info")
    LogicXSuit.stateInfo = {}
  end
end
function LogicXSuit.SendUnlockGoldDressStateReq(period, state, branchId)
  branchId = branchId or 0
  log(bWriteLog and "LogicXSuit.SendUnlockGoldDressStateReq")
  local itemID = LogicXSuit.GetItemIDByPeriodSelf(period, branchId)
  XSuitHandler.send_unlock_gold_dress_state_req(period, itemID, state, branchId)
end
function LogicXSuit.OnUnlockGoldDressStateRsp(info)
  if info then
    if LogicXSuit.stateInfo and info then
      LogicXSuit.ShowUnlockStateSuccessUI(LogicXSuit.stateInfo, info)
    end
    LogicXSuit.stateInfo = info
    LogicXSuit.UpdateLobbyAvatar()
    EventSystem:postEvent(EVENTTYPE_GOLDEN_SUIT, EVENTID_GOLDEN_SUIT_UNLOCK_STATE_SUCCESS)
  else
    log(bWriteLog and "LogicXSuit.OnUnlockGoldDressStateRsp miss info")
    LogicXSuit.stateInfo = {}
  end
end
function LogicXSuit.onRefreshGoldDressStateRsp(info)
  log_tree("LogicXSuit.onRefreshGoldDressStateRsp", info)
  if not LogicXSuit.stateInfo then
    LogicXSuit.stateInfo = {}
  end
  for k, v in pairs(info) do
    for branchId, data in pairs(v) do
      LogicXSuit.stateInfo[k] = LogicXSuit.stateInfo[k] or {}
      LogicXSuit.stateInfo[k][branchId] = data
      local ItemGetModule = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.rare_item_get_module)
      ItemGetModule:ShowOneXSuit(k, v.cur_state)
      EventSystem:postEvent(EVENTTYPE_GOLDEN_SUIT, EVENTID_GOLDEN_SUIT_UPDATE_DRESS_STATE, k)
    end
  end
end
function LogicXSuit.SendSetGoldDressStateReq(period, state, source, branch_id)
  branch_id = branch_id or 0
  log(bWriteLog and "LogicXSuit.SendSetGoldDressStateReq")
  XSuitHandler.send_set_gold_dress_state_req(period, state, source, branch_id)
end
function LogicXSuit.OnSetGoldDressStateRsp(info, source)
  if info then
    if source == EWardrobeDataSource.InheritWardrobe then
      local LogicInheritWardrobe = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.LogicInheritWardrobe)
      for period, v in pairs(info) do
        for branchId, data in pairs(v) do
          LogicInheritWardrobe:ChangeXSuitStateInfo(period, branchId, data)
          EventSystem:postEvent(EVENTTYPE_GOLDEN_SUIT, EVENTID_GOLDEN_SUIT_UPDATE_DRESS_STATE, period)
        end
      end
    else
      for period, v in pairs(info) do
        for branchId, data in pairs(v) do
          LogicXSuit.stateInfo[period] = LogicXSuit.stateInfo[period] or {}
          LogicXSuit.stateInfo[period][branchId] = LogicXSuit.stateInfo[period][branchId] or {}
          LogicXSuit.stateInfo[period][branchId].cur_state = data.cur_state
          EventSystem:postEvent(EVENTTYPE_GOLDEN_SUIT, EVENTID_GOLDEN_SUIT_UPDATE_DRESS_STATE, period)
        end
      end
    end
    LogicXSuit.UpdateLobbyAvatar()
    local BasicDataAvatarWearInfo = ModuleManager.GetModule(ModuleManager.DataModuleConfig.BasicDataAvatarWearInfo)
    BasicDataAvatarWearInfo:GetOrReqData(DataMgr.roleData.uid, function(callUid, callInfo)
      EventSystem:postEvent(EVENTTYPE_RANK, EVENTID_WARZONE_UPDATE_AVATAR, callUid)
    end, {bForceReq = true}, Enum_AvatarShowSource.LogicXSuit)
  else
    log(bWriteLog and "LogicXSuit.OnSetGoldDressStateRsp miss info")
    LogicXSuit.stateInfo = {}
  end
end
function LogicXSuit.GetStateInfo(source)
  local stateInfo
  if source == EWardrobeDataSource.InheritWardrobe then
    local LogicInheritWardrobe = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.LogicInheritWardrobe)
    stateInfo = LogicInheritWardrobe:GetXSuitStateInfo()
  else
    stateInfo = LogicXSuit.stateInfo
  end
  return stateInfo
end
function LogicXSuit.GetCurStateByPeriod(period, source)
  local stateInfo = LogicXSuit.GetStateInfo(source)
  if stateInfo and stateInfo[period] then
    return stateInfo[period][0].cur_state
  end
  return nil
end
function LogicXSuit.GetCurStateByItemID(itemID, source)
  LogicXSuit.InitXSuitItemList(itemID)
  if LogicXSuit.itemInfoList[itemID] then
    local period = LogicXSuit.itemInfoList[itemID].period
    return LogicXSuit.GetCurStateByPeriod(period, source)
  end
  return nil
end
function LogicXSuit.GetCurStateByInsID(InsID)
  local WardrobeData = require("client.slua.logic.wardrobe.wardrobe_data")
  local ItemData = WardrobeData:GetHallDepotItemDataByInsID(InsID)
  if not ItemData then
    log(bWriteLog and "LogicXSuit.GetCurStateByInsID not ItemData InsID:" .. tostring(InsID))
    return
  end
  local Source = WardrobeData:GetItemSource(InsID)
  return LogicXSuit.GetCurStateByItemID(ItemData.resID, Source)
end
function LogicXSuit.IsMultiStateCloth(itemID)
  log_warning(bWriteLog and "  LogicXSuit.IsMultiStateCloth. itemID: " .. tostring(itemID))
  local multi_state_manager = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.multi_state_manager)
  return multi_state_manager:IsMultiStateCloth(itemID)
end
function LogicXSuit.ChangeItemIDByState(itemID, state)
  local multi_state_manager = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.multi_state_manager)
  return multi_state_manager:ChangeClothByState(itemID, state)
end
function LogicXSuit.ChangeItemIDByMyselfState(itemID, source)
  LogicXSuit.InitXSuitItemList(itemID)
  if itemID and LogicXSuit.itemInfoList[itemID] then
    local period = LogicXSuit.itemInfoList[itemID].period
    local state = LogicXSuit.GetCurStateByPeriod(period, source)
    return LogicXSuit.ChangeItemIDByState(itemID, state)
  end
  return itemID
end
function LogicXSuit.GetXSuitItemIDByLevelAndState(itemID, level, state)
  if not itemID or not LogicXSuit.IsXSuit(itemID) then
    return itemID
  end
  LogicXSuit.InitXSuitItemList(itemID)
  local period = LogicXSuit.GetPeriodByItemId(itemID)
  if not period then
    return itemID
  end
  local targetLevelItemID = itemID
  if level and 0 < level then
    local branchId = LogicXSuit.GetBranchByItemId(itemID)
    targetLevelItemID = LogicXSuit.GetItemIDByLevel(period, level, branchId)
    if not targetLevelItemID then
      return itemID
    end
  end
  return LogicXSuit.ChangeItemIDByState(targetLevelItemID, state)
end
function LogicXSuit.ChangeItemIDByInsID(InsID)
  local WardrobeData = require("client.slua.logic.wardrobe.wardrobe_data")
  local Source = WardrobeData:GetItemSource(InsID)
  local itemID = WardrobeData:GetItemIDByInsID(InsID)
  return LogicXSuit.ChangeItemIDByMyselfState(itemID, Source)
end
function LogicXSuit.GetMyselfState(itemID)
  log(bWriteLog and "LogicXSuit.GetMyselfState itemID = " .. tostring(itemID))
  local state
  LogicXSuit.InitXSuitItemList(itemID)
  if itemID and LogicXSuit.itemInfoList[itemID] then
    local period = LogicXSuit.itemInfoList[itemID].period
    state = LogicXSuit.GetCurStateByPeriod(period, EWardrobeDataSource.Wardrobe)
    log(bWriteLog and "LogicXSuit.GetMyselfState state = " .. tostring(state))
  end
  return state
end
function LogicXSuit.CheckUnlockState(period, state, source)
  local stateInfo = LogicXSuit.GetStateInfo(source)
  if stateInfo and stateInfo[period] then
    return stateInfo[period][0].unlock_state[state] == 1
  end
  return false
end
function LogicXSuit.IsXSuitGlide(itemID)
  local NormalGlideID = LogicXSuit.GetNormalGlideID(itemID)
  local cfg = CDataTable.GetTableDataByFilter("XSuitGlideCfg", "GlideID", NormalGlideID)
  if not cfg then
    return false
  end
  return true
end
function LogicXSuit.GetLevel1XSuitID(NormalGlideID)
  local cfg = CDataTable.GetTableByFilter("XSuitGlideCfg", "GlideID", NormalGlideID)
  local res = {}
  for k, v in pairs(cfg or {}) do
    table.insert(res, v.XSuitID1)
  end
  return res
end
function LogicXSuit.GetLevel7XSuitID(NormalGlideID)
  local cfg = CDataTable.GetTableByFilter("XSuitGlideCfg", "GlideID", NormalGlideID)
  local res = {}
  for k, v in pairs(cfg or {}) do
    table.insert(res, v.XSuitID7)
  end
  return res
end
function LogicXSuit.GetAllSpecialGlideIDs(NormalGlideID)
  local cfgList = CDataTable.GetTableByFilter("XSuitGlideCfg", "GlideID", NormalGlideID)
  local result = {}
  for _, cfg in pairs(cfgList or {}) do
    if cfg.SpecialGlideID and cfg.SpecialGlideID > 0 then
      table.insert(result, cfg.SpecialGlideID)
    end
  end
  return result
end
function LogicXSuit.GetNormalGlideID(ItemID)
  local normalCfg = CDataTable.GetTableDataByFilter("XSuitGlideCfg", "GlideID", ItemID)
  if normalCfg then
    return normalCfg.GlideID
  end
  local specialCfg = CDataTable.GetTableDataByFilter("XSuitGlideCfg", "SpecialGlideID", ItemID)
  if specialCfg then
    return specialCfg.GlideID
  end
  return ItemID
end
function LogicXSuit.IsNormalGlideID(ItemID)
  local NormalGlideID = LogicXSuit.GetNormalGlideID(ItemID)
  if ItemID == NormalGlideID then
    return true
  end
  return false
end
function LogicXSuit.GetLevelAction(period, branchId)
  local default = 5
  if not LogicXSuit.levelAction then
    log(bWriteLog and "LogicXSuit.GetLevelAction not levelAction")
    XSuitHandler.send_gold_dress_get_level_action_req()
    return 5
  end
  return LogicXSuit.levelAction[period] and LogicXSuit.levelAction[period][branchId] or default
end
function LogicXSuit.GetFeatureSwitch(period, level, index, branchId)
  local info = LogicXSuit.FeatureSwitch
  if not (info and info[period] and info[period][branchId] and info[period][branchId][level]) or not info[period][branchId][level][index] then
    log(bWriteLog and "LogicXSuit.GetFeatureSwitch not FeatureSwitch")
    XSuitHandler.send_gold_dress_flag_operation_req(period, level, index, 2, nil, branchId)
    return 1
  end
  return info[period][branchId][level][index] or 1
end
function LogicXSuit.SetFeatureSwitch(info)
  LogicXSuit.FeatureSwitch = LogicXSuit.FeatureSwitch or {}
  LogicXSuit.FeatureSwitch[info.period_id] = LogicXSuit.FeatureSwitch[info.period_id] or {}
  LogicXSuit.FeatureSwitch[info.period_id][info.branch_id] = LogicXSuit.FeatureSwitch[info.period_id][info.branch_id] or {}
  LogicXSuit.FeatureSwitch[info.period_id][info.branch_id][info.level_id] = LogicXSuit.FeatureSwitch[info.period_id][info.branch_id][info.level_id] or {}
  LogicXSuit.FeatureSwitch[info.period_id][info.branch_id][info.level_id][info.index] = info.flag_value or 1
  local XSuitFeatureSwitchType = require("GameLua.Activity.Commercialize.GamePlay.XSuit.XSuitFeatureSwitchType")
  if info.index == XSuitFeatureSwitchType.RunAction then
    EventSystem:postEvent(EVENTTYPE_XSUIT, EVENTID_XSUIT_RUN_ACTION_UPDATE)
  elseif info.index == XSuitFeatureSwitchType.Orbiter then
    EventSystem:postEvent(EVENTTYPE_XSUIT, EVENTID_XSUIT_ORBITER_UPDATE)
  elseif info.index == XSuitFeatureSwitchType.Execute then
    EventSystem:postEvent(EVENTTYPE_XSUIT, EVENTID_XSUIT_EXECUTE_UPDATE)
  end
end
function LogicXSuit.HasUnlockFeature(period, branchId, level, index)
  if LogicXSuit.unlockFeatureInfo and LogicXSuit.unlockFeatureInfo[period] and LogicXSuit.unlockFeatureInfo[period][branchId] and LogicXSuit.unlockFeatureInfo[period][branchId][level] and LogicXSuit.unlockFeatureInfo[period][branchId][level][index] and LogicXSuit.unlockFeatureInfo[period][branchId][level][index] and LogicXSuit.unlockFeatureInfo[period][branchId][level][index].unlock_info_state.state == 1 then
    return true
  else
    return false
  end
end
function LogicXSuit.GetUnlockFeatureMaterial(period, branchId, level, index)
  if LogicXSuit.unlockFeatureInfo and LogicXSuit.unlockFeatureInfo[period] and LogicXSuit.unlockFeatureInfo[period][branchId] and LogicXSuit.unlockFeatureInfo[period][branchId][level] and LogicXSuit.unlockFeatureInfo[period][branchId][level][index] and LogicXSuit.unlockFeatureInfo[period][branchId][level][index] and LogicXSuit.unlockFeatureInfo[period][branchId][level][index].need_list then
    return LogicXSuit.unlockFeatureInfo[period][branchId][level][index].need_list
  else
    return {}
  end
end
function LogicXSuit.on_unlock_gold_dress_level_feature_rsp(period, branchId, level, index, gold_dress_set_info_all)
  log_tree("LogicXSuit.on_unlock_gold_dress_level_feature_rsp gold_dress_set_info_all", gold_dress_set_info_all)
  LogicXSuit.unlockFeatureInfo[period][branchId][level][index].unlock_info_state.state = gold_dress_set_info_all[period][branchId].unlock_info[level][index].state
  EventSystem:postEvent(EVENTTYPE_XSUIT, EVENTID_XSUIT_UNLOCK_FEATURE)
end
function LogicXSuit.draw_gold_dress_req(cost_times, currency_id, coupon_id, pool_id)
  XSuitHandler.send_draw_gold_dress_req(cost_times, currency_id, coupon_id and coupon_id ~= 0 and coupon_id or nil, pool_id)
  EventSystem:postEvent(EVENTTYPE_XSUIT, EVENTID_XSUIT_SPIN_SHOWORHIDE_MASK, true)
end
function LogicXSuit.UpdateLobbyAvatar(NeedPutOff)
  log(bWriteLog and "LogicXSuit.UpdateLobbyAvatar")
  local TeamAvatarManager = require("client.logic.avatar.logic_team_avatar_manager")
  local avatar = TeamAvatarManager.GetModel(DataMgr.roleData.uid)
  if avatar then
    local item, itemInsID
    local wardrobe_data = require("client.slua.logic.wardrobe.wardrobe_data")
    local tRoleWear = AvatarData.GetRoleWear()
    for _, v in pairs(tRoleWear) do
      local itemInfo = wardrobe_data:GetHallDepotItemDataByInsID(v)
      if itemInfo and LogicXSuit.IsXSuit(itemInfo.resID) then
        item = itemInfo.resID
        itemInsID = itemInfo.insID
        break
      end
    end
    if item then
      local switchItem = LogicXSuit.GetItemShowID(itemInsID)
      if NeedPutOff then
        TeamAvatarManager.ChangeAvatarEquipment(DataMgr.roleData.uid, AvatarData.CreateAvatarCustom(item))
      end
      TeamAvatarManager.ChangeAvatarEquipment(DataMgr.roleData.uid, AvatarData.CreateAvatarCustom(switchItem), true)
    end
    LogicXSuit._SyncSelfXSuitSchemeToLobbyPawn()
  end
end
function LogicXSuit.ShowErrCode(err_code)
  if err_code == 100170001 then
    ShowNotice(10295)
  elseif err_code == 100170002 then
    ShowNotice(10296)
  elseif err_code == 100170003 then
    ShowNotice(10297)
  elseif err_code == 100170004 then
    ShowNotice(8262)
  elseif err_code == 100170005 then
    ShowNotice(9963)
  elseif err_code == 100170006 then
  elseif err_code == 100170007 then
    ShowNotice(10298)
  elseif err_code == 100170008 then
    ShowNotice(10299)
  elseif err_code == 100170126 then
    ShowNotice(995002)
  elseif err_code == 100170009 then
  elseif err_code == 100170010 then
  elseif err_code == 100170011 then
    local param0 = CDataTable.GetTableData("Item", 1521841).ItemName
    local str = LocUtil.LocalizeResFormat(10334, param0)
    ShowNotice(str)
  elseif err_code == 100170012 then
    ShowNotice(10299)
  elseif err_code == 100170013 then
    ShowNotice(10335)
  elseif err_code == 100170014 then
  elseif err_code == 100170015 then
    ShowNotice(9986)
  end
end
function LogicXSuit.CheckXsuitAssert(keyList, callback, from, extraData)
  log_tree("xcc LogicXSuit:CheckXsuitAssert keyList:", keyList)
  if not PufferManager.CheckAndDownload(PufferConst.ENUM_DownloadType.ODPACK, keyList, callback, from, extraData) and callback and type(callback) == "function" then
    callback()
  end
end
local CUSTOM_SCHEME_ICON_FIELDS = {
  "ItemSmallIcon",
  "ItemSmallIcon2",
  "ItemBigIcon",
  "ItemBigIcon2"
}
function LogicXSuit.GetCustomSchemeIconPathList()
  if LogicXSuit.customSchemeIconPathList then
    return LogicXSuit.customSchemeIconPathList
  end
  local iconPathList = {}
  local addedSet = {}
  local schemeTable = CDataTable.GetTable("XSuitCustomScheme")
  for _, schemeCfg in pairs(schemeTable or {}) do
    local itemID = schemeCfg.ItemID
    local itemCfg = itemID and 0 < itemID and CDataTable.GetTableData("Item", itemID)
    if itemCfg then
      for _, fieldName in ipairs(CUSTOM_SCHEME_ICON_FIELDS) do
        local iconPath = itemCfg[fieldName]
        if iconPath and iconPath ~= "" and not addedSet[iconPath] then
          addedSet[iconPath] = true
          table.insert(iconPathList, iconPath)
        end
      end
    end
  end
  LogicXSuit.customSchemeIconPathList = iconPathList
  log(bWriteLog and "LogicXSuit.GetCustomSchemeIconPathList iconCount = " .. tostring(#iconPathList))
  return iconPathList
end
function LogicXSuit.PreDownloadCustomSchemeIcon(extraData)
  local iconPathList = LogicXSuit.GetCustomSchemeIconPathList()
  if not next(iconPathList) then
    return
  end
  local downloadType = PufferConst.ENUM_DownloadType.ODPAK
  if PufferManager.GetState(downloadType, iconPathList) == PufferConst.ENUM_DownloadState.Done then
    log(bWriteLog and "LogicXSuit.PreDownloadCustomSchemeIcon already done")
    return
  end
  log(bWriteLog and "LogicXSuit.PreDownloadCustomSchemeIcon iconCount = " .. tostring(#iconPathList))
  local PufferTlog = require("client.slua.logic.download.report.puffer_tlog")
  PufferManager.Download(downloadType, iconPathList, PufferTlog.Enum_TLog_From.LobbyEntrance, nil, extraData or {bAutoDownload = true, bFirst = true})
end
function LogicXSuit.GetXSuitBranchChangeAction(period, fromBranch, toBranch)
  if not (period and fromBranch and toBranch) or fromBranch == toBranch then
    return nil, nil
  end
  local row = CDataTable.GetTableDataByFilter("XSuitBranchChangeActionConfig", "Period", period, "BeforeBranch", fromBranch, "AfterBranch", toBranch)
  if not row then
    return nil, nil
  end
  return row.ActionID, row.IsPlayAnimAfterTransform
end
function LogicXSuit.GetCurrentEquippedXSuitPeriodAndBranch(avatarLogic)
  if not avatarLogic then
    return nil, nil
  end
  local equipments = avatarLogic:GetEquipments()
  if not equipments then
    return nil, nil
  end
  local multi_state_manager = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.multi_state_manager)
  for _, info in ipairs(equipments) do
    local displayID = info.itemID
    local originID = multi_state_manager:GetOriginClothIDAndState(displayID) or displayID
    if LogicXSuit.IsXSuit(originID) then
      return LogicXSuit.GetPeriodByItemId(originID), LogicXSuit.GetBranchByItemId(originID)
    end
  end
  return nil, nil
end
return LogicXSuit
