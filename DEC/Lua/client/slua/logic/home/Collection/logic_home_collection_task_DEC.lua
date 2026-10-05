local logic_home_collection_task = {}
function logic_home_collection_task:DefineAndResetData()
  self.task_list = nil
  self.begin_time = 0
  self.end_time = 0
  self.haveReportButlerInteract = false
end
function logic_home_collection_task:RegistEvents()
  logic_home_collection_task.__super.RegistEvents(self)
  self:AddCommonEvent(EVENTTYPE_NEXTDAY, EVENTID_NEXTDAY_ZERO, self.OnNextDayHandler, self)
end
function logic_home_collection_task:GetTaskTypeList()
  if not self.task_list then
    log(bWriteLog and "logic_home_collection_task:GetTaskTypeList no task_list")
    return {}
  end
  local taskTypeList = {}
  for taskType, _ in pairs(self.task_list) do
    table.insert(taskTypeList, taskType)
  end
  return taskTypeList
end
function logic_home_collection_task:GetTaskList(taskType)
  log(bWriteLog and "logic_home_collection_task:GetTaskList taskType:" .. tostring(taskType))
  if not self.task_list or not self.task_list[taskType] then
    log(bWriteLog and "logic_home_collection_task:GetTaskList no task_list")
    return {}
  end
  local task_list = self.task_list[taskType]
  local home_collection_macro = require("client.slua.logic.home.Collection.home_collection_macro")
  table.sort(task_list, function(a, b)
    if a.status ~= b.status then
      return a.status < b.status
    elseif a.status == home_collection_macro.Enum_TaskStatus.NotFinish and b.status == home_collection_macro.Enum_TaskStatus.NotFinish then
      local aSelfFinished = a.cur_value >= a.need_value
      local bSelfFinished = b.cur_value >= b.need_value
      if aSelfFinished ~= bSelfFinished then
        return bSelfFinished
      end
    end
    local taskCfgA = self:GetManorTaskCfg(a.task_id)
    local taskCfgB = self:GetManorTaskCfg(b.task_id)
    if not taskCfgA or not taskCfgB then
      return false
    end
    return taskCfgA.order_prior > taskCfgB.order_prior
  end)
  return task_list
end
function logic_home_collection_task:GetFinishTaskList()
  if not self.task_list then
    log(bWriteLog and "logic_home_collection_task:GetFinishTaskList no task_list")
    return {}
  end
  local home_collection_macro = require("client.slua.logic.home.Collection.home_collection_macro")
  local finishList = {}
  for _, task_array in pairs(self.task_list) do
    for _, task in pairs(task_array) do
      if task.status == home_collection_macro.Enum_TaskStatus.Finish then
        table.insert(finishList, task.task_id)
      end
    end
  end
  log_tree(bWriteLog and "logic_home_collection_task:GetFinishTaskList finishList:", finishList)
  return finishList
end
function logic_home_collection_task:FillFinishTaskRewardList(rewardDic, appendFunc, promise)
  local inner = function()
    local home_collection_macro = require("client.slua.logic.home.Collection.home_collection_macro")
    local finishStatus = home_collection_macro.Enum_TaskStatus.Finish
    for _, task_array in pairs(self.task_list) do
      for _, task in pairs(task_array) do
        if task.status == finishStatus then
          for i, v in pairs(task.award_item_list) do
            appendFunc(rewardDic, v.res_id, v.count)
          end
        end
      end
    end
    promise:Resolve()
  end
  if not self.task_list then
    self:send_get_manor_task_list_req():Then(inner)
    self:AddTimerOnce(3, function()
      promise:Resolve()
    end)
  else
    inner()
  end
end
function logic_home_collection_task:GetTask(taskID)
  if not self.task_list then
    log(bWriteLog and "logic_home_collection_task:GetTask no task_list")
    return nil
  end
  for _, taskList in pairs(self.task_list) do
    for _, task in ipairs(taskList) do
      if task.task_id == taskID then
        return task
      end
    end
  end
  log(bWriteLog and "logic_home_collection_task:GetTask no task")
  return nil
end
function logic_home_collection_task:GetTaskEndTime(taskType)
  local taskList = self:GetTaskList(taskType)
  local maxEndTime = 0
  for _, task in ipairs(taskList) do
    if maxEndTime < task.end_time then
      maxEndTime = task.end_time
    end
  end
  return maxEndTime
end
function logic_home_collection_task:SetTaskStartEndTime(begin_time, end_time)
  log(bWriteLog and "logic_home_collection_task:SetTaskStartEndTime begin_time:" .. tostring(begin_time))
  log(bWriteLog and "logic_home_collection_task:SetTaskStartEndTime end_time:" .. tostring(end_time))
  self.begin_time = begin_time or 0
  self.end_time = end_time or 0
end
function logic_home_collection_task:GetTaskStartEndTime()
  return self.begin_time, self.end_time
end
function logic_home_collection_task:GetTaskProgress(taskType)
  local taskList = self:GetTaskList(taskType)
  local totalCount = #taskList
  local finishCount = 0
  local home_collection_macro = require("client.slua.logic.home.Collection.home_collection_macro")
  for _, task in ipairs(taskList) do
    if task.status == home_collection_macro.Enum_TaskStatus.Finish or task.status == home_collection_macro.Enum_TaskStatus.Award then
      finishCount = finishCount + 1
    end
  end
  return finishCount, totalCount
end
function logic_home_collection_task:SetAwardFlag(award_flag)
  log(bWriteLog and "logic_home_collection_task:SetAwardFlag award_flag:" .. tostring(award_flag))
  local home_collection_task_redpoint = require("client.slua.logic.home.Collection.home_collection_task_redpoint")
  if award_flag and award_flag == 1 then
    home_collection_task_redpoint.UpdateRedpointCount(1)
  else
    home_collection_task_redpoint.UpdateRedpointCount(0)
  end
end
function logic_home_collection_task:send_get_manor_task_list_req()
  local home_macros = require("client.slua.logic.home.home_macros")
  local PHomeTaskHandler = require("client.network.Protocol.PHomeTaskHandler")
  return PHomeTaskHandler.send_get_manor_task_list_req(home_macros.ENUM_HOME_TASK_TYPE.HomeCollection)
end
function logic_home_collection_task:on_get_manor_task_list_rsp(task_map, award_flag, task_begin_time, task_end_time)
  if not task_map or not next(task_map) then
    log(bWriteLog and "logic_home_collection_task:on_get_manor_task_list_rsp invalid task_map")
    return
  end
  self.task_list = {}
  local home_collection_macro = require("client.slua.logic.home.Collection.home_collection_macro")
  for taskId, task in pairs(task_map) do
    local taskCfg = self:GetManorTaskCfg(taskId)
    if taskCfg then
      task.task_id = taskId
      if taskCfg.day_refresh == 1 then
        self:AddTaskData(home_collection_macro.Enum_TaskType.Daily, task)
      else
        self:AddTaskData(home_collection_macro.Enum_TaskType.Weekly, task)
      end
    else
      log(bWriteLog and "logic_home_collection_task:on_get_manor_task_list_rsp no taskCfg:" .. tostring(taskId))
    end
  end
  log_tree(bWriteLog and "logic_home_collection_task:on_get_manor_task_list_rsp task_list:", self.task_list)
  self:SetAwardFlag(award_flag)
  self:SetTaskStartEndTime(task_begin_time, task_end_time)
  EventSystem:postEvent(EVENTTYPE_PLANPH_LOBBY, EVENTID_PLANPH_GET_TASK_LIST)
end
function logic_home_collection_task:on_manor_task_update_notify(update_task_info, award_flag)
  if not update_task_info or not next(update_task_info) then
    log(bWriteLog and "logic_home_collection_task:on_manor_task_update_notify invalid update_task_info")
    return
  end
  for taskId, taskInfo in pairs(update_task_info) do
    local task = self:GetTask(taskId)
    if task then
      task.status = taskInfo.status
      task.cur_value = taskInfo.cur_value
      task.mate_cur_value = taskInfo.mate_cur_value
    end
  end
  self:SetAwardFlag(award_flag)
  EventSystem:postEvent(EVENTTYPE_PLANPH_LOBBY, EVENTID_HOME_TASK_UPDATE_NOTIFY)
end
function logic_home_collection_task:send_take_manor_task_award_req(task_id)
  local home_macros = require("client.slua.logic.home.home_macros")
  local PHomeTaskHandler = require("client.network.Protocol.PHomeTaskHandler")
  PHomeTaskHandler.send_take_manor_task_award_req(task_id, home_macros.ENUM_HOME_TASK_TYPE.HomeCollection)
end
function logic_home_collection_task:on_take_manor_task_award_rsp(task_id, award_flag)
  local task = self:GetTask(task_id)
  if task then
    if task.award_item_list and next(task.award_item_list) then
      local Logic_CommonItemGet = require("client.slua.logic.common.CommonItemGet.Logic_CommonItemGet")
      Logic_CommonItemGet.ShowPanel_DefaultStyle(task.award_item_list)
    end
    local home_collection_macro = require("client.slua.logic.home.Collection.home_collection_macro")
    task.status = home_collection_macro.Enum_TaskStatus.Award
  end
  self:SetAwardFlag(award_flag)
  EventSystem:postEvent(EVENTTYPE_PLANPH_LOBBY, EVENTID_PLANPH_TAKE_TASK_AWARD, task_id)
end
function logic_home_collection_task:send_batch_take_manor_task_award_req(task_id_list)
  if not task_id_list or not next(task_id_list) then
    log(bWriteLog and "logic_home_collection_task:send_batch_take_manor_task_award_req invalid task_id_list")
    return
  end
  local home_macros = require("client.slua.logic.home.home_macros")
  local PHomeTaskHandler = require("client.network.Protocol.PHomeTaskHandler")
  PHomeTaskHandler.send_batch_take_manor_task_award_req(task_id_list, home_macros.ENUM_HOME_TASK_TYPE.HomeCollection)
end
function logic_home_collection_task:batch_take_manor_task_award_rsp(task_id_list, award_flag, invoke_type)
  local award_item_list = {}
  local MergeAward = function(source_award_item_list)
    if not source_award_item_list or not next(source_award_item_list) then
      log(bWriteLog and "logic_home_collection_task:batch_take_manor_task_award_rsp MergeAward invalid param")
      return
    end
    for _, award_item in ipairs(source_award_item_list) do
      local merged = false
      for _, award in ipairs(award_item_list) do
        if award.res_id == award_item.res_id and award.valid_hours == award_item.valid_hours then
          log(bWriteLog and "logic_home_collection_task:batch_take_manor_task_award_rsp MergeAward, merge:" .. tostring(award_item.res_id))
          award.count = award.count + award_item.count
          merged = true
          break
        end
      end
      if not merged then
        log(bWriteLog and "logic_home_collection_task:batch_take_manor_task_award_rsp MergeAward, insert:" .. tostring(award_item.res_id))
        table.insert(award_item_list, award_item)
      end
    end
  end
  local home_collection_macro = require("client.slua.logic.home.Collection.home_collection_macro")
  for _, task_id in ipairs(task_id_list) do
    local task = self:GetTask(task_id)
    if task then
      MergeAward(task.award_item_list)
      task.status = home_collection_macro.Enum_TaskStatus.Award
    end
  end
  if next(award_item_list) then
    if invoke_type == 1 then
      local logic_oneclick_reward = require("client.slua.logic.mini_tv.logic_oneclick_reward")
      local OneClickMacro = require("client.slua.logic.mini_tv.logic_oneclick_macro")
      logic_oneclick_reward.AddListToAllRewardData(award_item_list, OneClickMacro.MapNumToSystem.MODE_AWARD_TYPE_MANOR_TASK)
    else
      local Logic_CommonItemGet = require("client.slua.logic.common.CommonItemGet.Logic_CommonItemGet")
      Logic_CommonItemGet.ShowPanel_DefaultStyle(award_item_list)
    end
  end
  self:SetAwardFlag(award_flag)
  EventSystem:postEvent(EVENTTYPE_PLANPH_LOBBY, EVENTID_PLANPH_BATCH_TAKE_TASK_AWARD)
end
function logic_home_collection_task:OnNextDayHandler()
  self.haveReportButlerInteract = false
end
function logic_home_collection_task:send_report_manor_butler_interaction()
  log(bWriteLog and "logic_home_collection_task:send_report_manor_butler_interaction")
  if self.haveReportButlerInteract then
    log(bWriteLog and "logic_home_collection_task:send_report_manor_butler_interaction haveReport")
    return
  end
  local PHomeTaskHandler = require("client.network.Protocol.PHomeTaskHandler")
  PHomeTaskHandler.send_report_manor_butler_interaction()
  self.haveReportButlerInteract = true
end
function logic_home_collection_task:AddTaskData(taskType, task)
  if self.task_list[taskType] == nil then
    self.task_list[taskType] = {}
  end
  table.insert(self.task_list[taskType], task)
end
function logic_home_collection_task:GetIsRun()
  local logic_home_switch = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_home_switch)
  if logic_home_switch:CheckHomeLimit(false) then
    log(bWriteLog and "logic_home_collection_task:GetIsRun HomeLimit")
    return false
  end
  local BasicDataServerTable = ModuleManager.GetModule(ModuleManager.DataModuleConfig.BasicDataServerTable)
  local data_config_marco = require("client.logic.data.data_config_marco")
  if not BasicDataServerTable:GetCacheData(data_config_marco.manor_task_cfg) then
    log(bWriteLog and "logic_home_collection_task:GetIsRun no task cfg")
    return false
  end
  log(bWriteLog and "logic_home_collection_task:GetIsRun true")
  return true
end
function logic_home_collection_task:RequestManorTaskCfg(onComplete)
  log(bWriteLog and "logic_home_collection_task:RequestManorTaskCfg")
  local BasicDataServerTable = ModuleManager.GetModule(ModuleManager.DataModuleConfig.BasicDataServerTable)
  local data_config_marco = require("client.logic.data.data_config_marco")
  BasicDataServerTable:GetOrReqData(data_config_marco.manor_task_cfg, function(table_name, table_data)
    log(bWriteLog and "logic_home_collection_task:RequestManorTaskCfg table_name:" .. table_name)
    EventSystem:postEvent(EVENTTYPE_PLANPH_LOBBY, EVENTID_PLANPH_HOME_TASK_CONFIG_UPDATE)
    if onComplete then
      onComplete(table_data)
    end
  end)
end
function logic_home_collection_task:GetManorTaskCfg(task_id)
  local BasicDataServerTable = ModuleManager.GetModule(ModuleManager.DataModuleConfig.BasicDataServerTable)
  local data_config_marco = require("client.logic.data.data_config_marco")
  local manor_task_cfg = BasicDataServerTable:GetCacheData(data_config_marco.manor_task_cfg)
  if not manor_task_cfg then
    log(bWriteLog and "logic_home_collection_task:GetManorTaskCfg no manor_task_cfg")
    return nil
  end
  return manor_task_cfg[task_id]
end
local class = require("class")
local CModuleBase = require("client.module_framework.ModuleBase")
local Clogic_home_collection_task = class(CModuleBase, nil, logic_home_collection_task)
return Clogic_home_collection_task
