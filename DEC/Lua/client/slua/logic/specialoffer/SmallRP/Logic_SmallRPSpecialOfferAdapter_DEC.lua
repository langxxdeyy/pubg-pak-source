local Logic_SmallRPSpecialOfferAdapter = {}
local GetActivityLogic = function()
  return ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.Logic_SmallRPActivity)
end
local GetActivityRedMgr = function()
  return ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.Logic_SmallRPActivityRedMgr)
end
local GetLegacyLogic = function()
  return ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.Logic_SmallRP)
end
function Logic_SmallRPSpecialOfferAdapter.GetOpenActivityIdList()
  local tActivityIdList = {}
  local Logic_SmallRPActivity = GetActivityLogic()
  if not Logic_SmallRPActivity then
    return tActivityIdList
  end
  for _, tActivityData in ipairs(Logic_SmallRPActivity:GetOpenActivityList()) do
    local nActivityId = tonumber(tActivityData.activity_id)
    if nActivityId and Logic_SmallRPActivity:GetIsOpen(nActivityId) then
      tActivityIdList[#tActivityIdList + 1] = nActivityId
    end
  end
  return tActivityIdList
end
function Logic_SmallRPSpecialOfferAdapter.IsLegacyOpen()
  local Logic_SmallRP = GetLegacyLogic()
  if not Logic_SmallRP or not Logic_SmallRP.GetIsOpen then
    return false
  end
  return Logic_SmallRP:GetIsOpen() == true
end
function Logic_SmallRPSpecialOfferAdapter.IsActivityOpen(nActivityId)
  nActivityId = tonumber(nActivityId)
  if not nActivityId then
    return false
  end
  local Logic_SmallRPActivity = GetActivityLogic()
  if not Logic_SmallRPActivity then
    return false
  end
  return Logic_SmallRPActivity:GetActivityData(nActivityId) ~= nil and Logic_SmallRPActivity:GetIsOpen(nActivityId)
end
function Logic_SmallRPSpecialOfferAdapter.GetGroupAllWeight(tServerData)
  if type(tServerData) ~= "table" then
    return
  end
  local cfg = require("client.slua.logic.specialoffer.special_offer_cfg")
  local tGroupData = tServerData[cfg.SmallRP] or tServerData[tostring(cfg.SmallRP)]
  if type(tGroupData) ~= "table" then
    return
  end
  local nBaseWeight = (tonumber(tGroupData.weight) or 0) + (tonumber(tGroupData.pay_weight) or 0)
  return tonumber(tGroupData.allWeight) or nBaseWeight
end
function Logic_SmallRPSpecialOfferAdapter.GetSortId(nActivityId)
  nActivityId = tonumber(nActivityId)
  if nActivityId then
    return nActivityId
  end
  local Logic_SmallRP = GetLegacyLogic()
  local nLegacyRoundId
  if Logic_SmallRP and Logic_SmallRP.GetActRoundId then
    local nRawLegacyRoundId = Logic_SmallRP:GetActRoundId()
    nLegacyRoundId = tonumber(nRawLegacyRoundId)
  end
  return nLegacyRoundId or math.huge
end
function Logic_SmallRPSpecialOfferAdapter.GetTitle(nActivityId)
  local Logic_SmallRPActivity = GetActivityLogic()
  if Logic_SmallRPActivity then
    local tControlCfg = Logic_SmallRPActivity:GetControlCfg(nActivityId)
    if tControlCfg and tControlCfg.act_name then
      return tControlCfg.act_name
    end
  end
  local ActivityNewSystem = require("client.slua.logic.activity.logic_activity_mgr")
  local tActivityData = ActivityNewSystem.GetActivityByID and ActivityNewSystem.GetActivityByID(tonumber(nActivityId)) or nil
  return tActivityData and (tActivityData.Name or tActivityData.ActivityName or tActivityData.Title) or nil
end
function Logic_SmallRPSpecialOfferAdapter.GetMark(nActivityId)
  local special_offer_mark = require("client.slua.logic.specialoffer.special_offer_mark")
  local markType = special_offer_mark.markType
  local UIUtil = require("client.common.ui_util")
  local nEndTime
  local Logic_SmallRPActivity = GetActivityLogic()
  if Logic_SmallRPActivity then
    local _, nActEndTime = Logic_SmallRPActivity:GetActTime(nActivityId)
    nEndTime = nActEndTime
  end
  if not nEndTime or not UIUtil.IsCountDown(nEndTime, 3) then
    nEndTime = nil
  end
  local Logic_SmallRPActivityRedMgr = GetActivityRedMgr()
  if not Logic_SmallRPActivityRedMgr then
    return nil, nEndTime
  end
  if not Logic_SmallRPActivityRedMgr:GetIsOpenedAct(nActivityId) then
    return markType.New, nil
  end
  if Logic_SmallRPActivityRedMgr:GetIsShowRedDot(nActivityId) then
    return markType.Got, nil
  end
  return nil, nEndTime
end
function Logic_SmallRPSpecialOfferAdapter.GetLegacyMark()
  local special_offer_mark = require("client.slua.logic.specialoffer.special_offer_mark")
  local markType = special_offer_mark.markType
  local UIUtil = require("client.common.ui_util")
  local Logic_SmallRP = GetLegacyLogic()
  if not Logic_SmallRP then
    return
  end
  local _, nActEndTime = Logic_SmallRP:GetActTime()
  local nEndTime = nActEndTime and UIUtil.IsCountDown(nActEndTime, 3) and nActEndTime or nil
  local Logic_SmallRPRedMgr = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.Logic_SmallRPRedMgr)
  if not Logic_SmallRPRedMgr then
    return nil, nEndTime
  end
  if Logic_SmallRPRedMgr:GetTaskIsRed() or Logic_SmallRPRedMgr:GetLevelRewardIsRed() then
    return markType.Got, nil
  end
  if not Logic_SmallRPRedMgr:GetIsOpenedAct() then
    return markType.New, nil
  end
  return nil, nEndTime
end
function Logic_SmallRPSpecialOfferAdapter.CreateUIContext(nActivityId)
  return {
    logic = GetActivityLogic(),
    activity_id = tonumber(nActivityId)
  }
end
return Logic_SmallRPSpecialOfferAdapter
