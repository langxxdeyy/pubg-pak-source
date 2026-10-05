local collect_clothe_module = {}
local ActivityProgressStatus = ActivityProgressStatus
function collect_clothe_module:DefineAndResetData()
  self.clotheSeriesData = nil
  self.clotheSeriesMap = nil
end
function collect_clothe_module:GetListOfAvailableRewards()
  local result, seriesID = {}
  local list = self:GetAllClotheSeriesData()
  local checkAward = function(awardData, seriesScore, seriesId)
    if awardData.MinScore == 0 or seriesScore < awardData.MinScore then
      return
    end
    for i = 1, 2 do
      if self:CheckAwardAvailable(i, awardData, seriesId) then
        if not seriesID then
          seriesID = seriesId
        end
        table.insert(result, {
          itemId = awardData["Drop" .. i],
          num = awardData["Num" .. i],
          time = awardData["Time" .. i],
          idx = awardData.Level,
          subIdx = i
        })
      end
    end
  end
  for i, v in ipairs(list) do
    local seriesId = v.SeriesID
    local seriesScore = self:GetClotheSeriesScore(seriesId)
    local awardList = v.AwardList
    if awardList and next(awardList) and 0 < seriesScore then
      for _, awardData in pairs(awardList) do
        checkAward(awardData, seriesScore, seriesId)
      end
    end
  end
  return result, seriesID
end
function collect_clothe_module:HasRed()
  local bRedDot = false
  local front = 1
  local clotheData = self:GetAllClotheSeriesData()
  local back = #clotheData
  while front <= back do
    local frontSeriesData = clotheData[front]
    local backSeriesData = clotheData[back]
    if self:IsRedOneClothe(frontSeriesData) or self:IsRedOneClothe(backSeriesData) then
      bRedDot = true
      break
    end
    if front == back or front == back - 1 then
      break
    end
    front = front + 1
    back = back - 1
  end
  return bRedDot
end
function collect_clothe_module:IsRedOneClothe(seriesData)
  if not seriesData or not next(seriesData) then
    return false
  end
  local CanGet = self:ClotheSeriesHasCanGetAwardStatus(seriesData.SeriesID)
  if CanGet then
    return true
  end
  return false
end
function collect_clothe_module:ClotheSeriesHasCanGetAwardStatus(seriesId)
  if not seriesId then
    return false
  end
  local seriesData = self:GetClotheSeriesData(seriesId)
  local awardList = seriesData.AwardList
  if not awardList or not next(awardList) then
    return false
  end
  local seriesScore = self:GetClotheSeriesScore(seriesId)
  if seriesScore == 0 then
    return false
  end
  for _, awardData in pairs(awardList) do
    if self:CheckAwardAvailableForCurrentLevel(awardData, seriesScore, seriesId) then
      return true
    end
  end
  return false
end
function collect_clothe_module:GetClotheSeriesData(seriesId)
  if not seriesId then
    return nil
  end
  if not self.clotheSeriesMap then
    self:GetAllClotheSeriesData()
  end
  return self.clotheSeriesMap[seriesId]
end
function collect_clothe_module:CheckAwardAvailableForCurrentLevel(awardData, seriesScore, seriesId)
  if awardData.MinScore == 0 or seriesScore < awardData.MinScore then
    return false
  end
  for i = 1, 2 do
    if self:CheckAwardAvailable(i, awardData, seriesId) then
      return true
    end
  end
  return false
end
function collect_clothe_module:CheckAwardAvailable(i, awardData, seriesId)
  local Num = string.format("Num%s", i)
  local Drop = string.format("Drop%s", i)
  local Cost = string.format("Cost%s", i)
  if awardData[Drop] ~= 0 and awardData[Num] ~= 0 and awardData[Cost] == 0 then
    local itemID = awardData[Drop]
    local collect_encryption_module = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.collect_encryption_module)
    if collect_encryption_module:IsEncryption(itemID) then
      return false
    end
    local status = self:GetClotheSeriesAwardStatus(seriesId, awardData.Level, i)
    local Version = string.format("Version%s", i)
    local ShowTime = string.format("ShowTime%s", i)
    local collect_encryption_module = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.collect_encryption_module)
    if status == ActivityProgressStatus.Done and not collect_encryption_module:IsEncryptionSeries(awardData[Version], awardData[ShowTime]) then
      return true
    end
  end
  return false
end
function collect_clothe_module:GetClotheSeriesAwardStatus(seriesId, level, subIndex)
  local collect_module = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.collect_module)
  local collect_data = collect_module:GetCollectData()
  if not seriesId or not collect_data then
    return ActivityProgressStatus.Not
  end
  seriesId = tonumber(seriesId)
  local clotheSeriesAwardData = collect_data.cloth_award_status
  if not (clotheSeriesAwardData and clotheSeriesAwardData[seriesId] and clotheSeriesAwardData[seriesId][level]) or not clotheSeriesAwardData[seriesId][level][subIndex] then
    local seriesAwardData = self:GetClotheSeriesAwardData(seriesId, level)
    local score = self:GetClotheSeriesScore(seriesId)
    if score >= seriesAwardData.MinScore then
      return ActivityProgressStatus.Done
    end
  else
    if not level or not subIndex then
      return ActivityProgressStatus.Not
    end
    local awardStatusList = clotheSeriesAwardData[tonumber(seriesId)]
    local status = awardStatusList[level][subIndex]
    if status then
      return ActivityProgressStatus.Get
    end
  end
  return ActivityProgressStatus.Not
end
function collect_clothe_module:GetClotheSeriesAwardData(seriesId, index)
  if not index or index == 0 then
    index = 1
  end
  local seriesData = self:GetClotheSeriesData(seriesId)
  if not seriesData then
    return nil
  end
  local awardList = seriesData.AwardList
  if not awardList then
    return nil
  end
  return awardList[index]
end
function collect_clothe_module:GetClotheSeriesScoreNextDiff(seriesId)
  if not seriesId then
    return 0
  end
  local seriesData = self:GetClotheSeriesData(seriesId)
  if not seriesData then
    return 0
  end
  local awardList = seriesData.AwardList
  if not awardList then
    return 0
  end
  local seriesScore = self:GetClotheSeriesScore(seriesId)
  for _, awardData in pairs(awardList) do
    if awardData.MinScore and seriesScore < awardData.MinScore then
      return awardData.MinScore - seriesScore
    end
  end
  return 0
end
function collect_clothe_module:GetClotheSeriesProgress(seriesId, level)
  if not seriesId then
    return 0
  end
  local maxAwardLevel = self:GetClotheSeriesMaxAwardLevel(seriesId)
  if level == maxAwardLevel then
    return 0
  end
  local score = self:GetClotheSeriesScore(seriesId)
  local prevAwardData = self:GetClotheSeriesAwardData(seriesId, level)
  if level == 0 then
    return score / prevAwardData.MinScore
  else
    local preScore = prevAwardData.MinScore
    local nextScore = prevAwardData.Score
    return (score - preScore) / (nextScore - preScore)
  end
end
function collect_clothe_module:GetClotheSeriesMaxAwardLevel(seriesId)
  if not seriesId then
    return 0
  end
  local seriesData = self:GetClotheSeriesData(seriesId)
  if not seriesData then
    return 0
  end
  local awardList = seriesData.AwardList
  if not awardList then
    return 0
  end
  return #awardList
end
function collect_clothe_module:GetClotheSeriesScore(seriesId)
  local collect_module = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.collect_module)
  local collect_data = collect_module:GetCollectData()
  if not seriesId or not collect_data then
    return 0
  end
  local seriesScoreData = collect_data.cloth_sys_score
  if not seriesScoreData then
    return 0
  end
  if seriesScoreData[tonumber(seriesId)] then
    return seriesScoreData[tonumber(seriesId)]
  end
  return 0
end
function collect_clothe_module:GetClotheSeriesMaxTakeAwardLevel(seriesId)
  if not seriesId then
    return 0
  end
  local seriesData = self:GetClotheSeriesData(seriesId)
  if not seriesData then
    return 0
  end
  local awardList = seriesData.AwardList
  if not awardList then
    return 0
  end
  local seriesScore = self:GetClotheSeriesScore(seriesId)
  for Level, awardData in pairs(awardList) do
    if awardData.MinScore and seriesScore < awardData.MinScore then
      return Level - 1
    end
  end
  return #awardList
end
function collect_clothe_module:GetAllClotheSeriesData()
  if self.clotheSeriesData then
    return self.clotheSeriesData
  end
  self.clotheSeriesMap = {}
  self.clotheSeriesData = {}
  local collect_module = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.collect_module)
  local SeriesAwardList = collect_module:GetSplitTable("CollectClotheSeriesAward", collect_module.E_ColCfgMode.JK) or {}
  for _, v in pairs(SeriesAwardList) do
    if v.SeriesID and v.Level then
      if not self.clotheSeriesMap[v.SeriesID] then
        self.clotheSeriesMap[v.SeriesID] = {
          AwardList = {},
          ItemList = {}
        }
      end
      self.clotheSeriesMap[v.SeriesID].AwardList[v.Level] = v
    end
  end
  local SeriesList = collect_module:GetSplitTable("CollectClotheSeries", collect_module.E_ColCfgMode.JK) or {}
  for k, v in pairs(SeriesList) do
    local clothData = self.clotheSeriesMap[k]
    if clothData then
      clothData.SeriesID = v.SeriesID
      clothData.SeriesName = v.SeriesName
      clothData.Weight = v.Weight
      clothData.ItemList = {}
    end
  end
  local insertSubThemeItem = function(subThemeInfoMap, v)
    local itemData = {
      SeriesID = v.SeriesID,
      ItemID = v.ItemID,
      SubThemeID = v.SubThemeID
    }
    if not subThemeInfoMap[v.SubThemeID] then
      local info = collect_module:GetSplitTableData("CollectClotheSubTheme", collect_module.E_ColCfgMode.DifJK, v.SubThemeID)
      if info then
        subThemeInfoMap[v.SubThemeID] = info
      end
    end
    local info = subThemeInfoMap[v.SubThemeID]
    if info then
      itemData.Version = info.Version
      itemData.Time = info.Time
    end
    if self.clotheSeriesMap[v.SeriesID] and self.clotheSeriesMap[v.SeriesID].ItemList then
      table.insert(self.clotheSeriesMap[v.SeriesID].ItemList, itemData)
    end
  end
  local subThemeInfoMap = {}
  local SeriesItemList = collect_module:GetSplitTableByFilter("CollectClotheItem", collect_module.E_ColCfgMode.DifJK, "IsNeedShow", 1) or {}
  for _, v in pairs(SeriesItemList) do
    if v.SeriesID and self.clotheSeriesMap[v.SeriesID] then
      insertSubThemeItem(subThemeInfoMap, v)
    end
  end
  for _, v in pairs(self.clotheSeriesMap) do
    table.sort(v.AwardList, function(a, b)
      if a.Level and b.Level then
        return a.Level < b.Level
      end
      return false
    end)
    table.insert(self.clotheSeriesData, v)
  end
  table.sort(self.clotheSeriesData, function(a, b)
    if a.Weight and b.Weight then
      return a.Weight > b.Weight
    end
    return false
  end)
  return self.clotheSeriesData
end
function collect_clothe_module:GetClotheSeriesTotalScore()
  local collect_module = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.collect_module)
  local collect_data = collect_module:GetCollectData()
  if not collect_data or not collect_data.cloth_score then
    return 0
  end
  return collect_data.cloth_score
end
local class = require("class")
local CModuleBase = require("client.module_framework.ModuleBase")
local CModuleTemplate = class(CModuleBase, nil, collect_clothe_module)
return CModuleTemplate
