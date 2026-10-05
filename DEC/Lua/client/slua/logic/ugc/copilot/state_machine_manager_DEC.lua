local StateMachineManager = {Owner = nil}
local Config_UGC = require("client.slua.logic.ugc.config_ugc")
local Config_UGC_Copilot = require("client.slua.logic.ugc.copilot.config_ugc_copilot")
local STATE_TIMEOUTS = {
  [Config_UGC_Copilot.Enum_UGC_LLM_State.INITIALIZING] = 5,
  [Config_UGC_Copilot.Enum_UGC_LLM_State.COLLECTING_CONTEXT] = 20,
  [Config_UGC_Copilot.Enum_UGC_LLM_State.NEW_CHAT_PENDING] = 60,
  [Config_UGC_Copilot.Enum_UGC_LLM_State.HISTORY_LOADING] = 3,
  [Config_UGC_Copilot.Enum_UGC_LLM_State.STREAMING] = 45,
  [Config_UGC_Copilot.Enum_UGC_LLM_State.LONG_TASK_RUNNING] = 150
}
if IsEditor then
  STATE_TIMEOUTS[Config_UGC_Copilot.Enum_UGC_LLM_State.NEW_CHAT_PENDING] = 30
end
local ALLOWED_TRANSITIONS = {
  [Config_UGC_Copilot.Enum_UGC_LLM_State.INIT] = {
    [Config_UGC_Copilot.Enum_UGC_LLM_State.INITIALIZING] = true,
    [Config_UGC_Copilot.Enum_UGC_LLM_State.ERROR] = true
  },
  [Config_UGC_Copilot.Enum_UGC_LLM_State.INITIALIZING] = {
    [Config_UGC_Copilot.Enum_UGC_LLM_State.IDLE] = true,
    [Config_UGC_Copilot.Enum_UGC_LLM_State.INIT] = true,
    [Config_UGC_Copilot.Enum_UGC_LLM_State.ERROR] = true
  },
  [Config_UGC_Copilot.Enum_UGC_LLM_State.IDLE] = {
    [Config_UGC_Copilot.Enum_UGC_LLM_State.COLLECTING_CONTEXT] = true,
    [Config_UGC_Copilot.Enum_UGC_LLM_State.NEW_CHAT_PENDING] = true,
    [Config_UGC_Copilot.Enum_UGC_LLM_State.HISTORY_LOADING] = true,
    [Config_UGC_Copilot.Enum_UGC_LLM_State.IDLE] = true,
    [Config_UGC_Copilot.Enum_UGC_LLM_State.ERROR] = true,
    [Config_UGC_Copilot.Enum_UGC_LLM_State.LONG_TASK_RUNNING] = true
  },
  [Config_UGC_Copilot.Enum_UGC_LLM_State.COLLECTING_CONTEXT] = {
    [Config_UGC_Copilot.Enum_UGC_LLM_State.NEW_CHAT_PENDING] = true,
    [Config_UGC_Copilot.Enum_UGC_LLM_State.IDLE] = true,
    [Config_UGC_Copilot.Enum_UGC_LLM_State.ERROR] = true
  },
  [Config_UGC_Copilot.Enum_UGC_LLM_State.NEW_CHAT_PENDING] = {
    [Config_UGC_Copilot.Enum_UGC_LLM_State.STREAMING] = true,
    [Config_UGC_Copilot.Enum_UGC_LLM_State.ERROR] = true,
    [Config_UGC_Copilot.Enum_UGC_LLM_State.IDLE] = true
  },
  [Config_UGC_Copilot.Enum_UGC_LLM_State.STREAMING] = {
    [Config_UGC_Copilot.Enum_UGC_LLM_State.IDLE] = true,
    [Config_UGC_Copilot.Enum_UGC_LLM_State.ERROR] = true,
    [Config_UGC_Copilot.Enum_UGC_LLM_State.LONG_TASK_RUNNING] = true
  },
  [Config_UGC_Copilot.Enum_UGC_LLM_State.HISTORY_LOADING] = {
    [Config_UGC_Copilot.Enum_UGC_LLM_State.IDLE] = true,
    [Config_UGC_Copilot.Enum_UGC_LLM_State.ERROR] = true
  },
  [Config_UGC_Copilot.Enum_UGC_LLM_State.ERROR] = {
    [Config_UGC_Copilot.Enum_UGC_LLM_State.IDLE] = true
  },
  [Config_UGC_Copilot.Enum_UGC_LLM_State.LONG_TASK_RUNNING] = {
    [Config_UGC_Copilot.Enum_UGC_LLM_State.ERROR] = true,
    [Config_UGC_Copilot.Enum_UGC_LLM_State.IDLE] = true,
    [Config_UGC_Copilot.Enum_UGC_LLM_State.NEW_CHAT_PENDING] = true,
    [Config_UGC_Copilot.Enum_UGC_LLM_State.LONG_TASK_RUNNING] = true
  }
}
function StateMachineManager:ctor()
end
function StateMachineManager:OnInitialize()
  self:ResetData()
end
function StateMachineManager:ResetData()
  self.CurrentState = Config_UGC_Copilot.Enum_UGC_LLM_State.INIT
  self.LastErrorCode = nil
  self.ActiveTraceID = nil
  self.RequestStartTime = nil
  self.TimeoutTimers = {}
  self.stateTimeoutTimers = {}
  self.stoppedChats = {}
  self.stoppedTraceIDs = {}
  self._RevokedTraceIDs = {}
  self.initPendingRequests = {}
  self.initFailed = nil
  self.PendingInGenTraceID = nil
  self.PendingInGenData = nil
  self.CurrentLongTaskContext = nil
  self.LastActiveTraceID = nil
end
function StateMachineManager:GetCurrentState()
  return self.CurrentState
end
function StateMachineManager:UpdateState(newState, reason, overrideTimeout)
  reason = reason or "unspecified"
  local currentState = self.CurrentState
  print(bWriteLog and string.format("StateMachineManager:UpdateState Previous: %s, New: %s, Reason: %s", currentState, newState, reason))
  if not ALLOWED_TRANSITIONS[currentState] or not ALLOWED_TRANSITIONS[currentState][newState] then
    self:HandleError(Config_UGC_Copilot.Enum_UGC_LLM_ErrorCode.ERR_INVALID_TRANSITION, "invalid_transition")
    return false
  end
  if self.stateTimeoutTimers[currentState] then
    self.Owner:RemoveTimer(self.stateTimeoutTimers[currentState])
    self.stateTimeoutTimers[currentState] = nil
  end
  self.CurrentState = newState
  local timeout = overrideTimeout or STATE_TIMEOUTS[newState]
  if timeout then
    local timerID = self.Owner:AddTimerOnce(timeout, function()
      local CurrentState = self:GetCurrentState()
      if CurrentState then
        local StateConfig = Config_UGC_Copilot.CopilotStateConfig[CurrentState]
        if StateConfig and StateConfig.OnTimeOut then
          StateConfig.OnTimeOut()
        end
      end
      self:HandleError(Config_UGC_Copilot.Enum_UGC_LLM_ErrorCode.ERR_TIMEOUT, "state_timeout: " .. newState)
    end)
    self.stateTimeoutTimers[newState] = timerID
  end
  EventSystem:postEvent(EVENTTYPE_UGC_COPILOT, EVENTID_UGC_COPILOT_STATE_CHANGED, self.CurrentState)
  return true
end
function StateMachineManager:HandleError(errorCode, reason)
  reason = reason or "unspecified"
  print(bWriteLog and string.format("StateMachineManager:HandleError Code: %s, Reason: %s", errorCode, reason))
  self.LastErrorCode = errorCode
  if errorCode == Config_UGC_Copilot.Enum_UGC_LLM_ErrorCode.ERR_TIMEOUT and self.ActiveTraceID then
    local errorData = {
      trace_id = self.ActiveTraceID,
      error_source = "client",
      error_reason = reason,
      client_state = self.CurrentState,
      duration = self:GetExecutionDuration()
    }
    local UGCTLogReport = ModuleManager.GetModule(ModuleManager.DataModuleConfig.UGCTLogReport)
    if UGCTLogReport then
      UGCTLogReport:ReportDelay(TLogEventDefine.UGC_Copilot_Fail, errorCode, json.encode(errorData))
    end
  end
  if self.CurrentState == Config_UGC_Copilot.Enum_UGC_LLM_State.INITIALIZING then
    self:UpdateState(Config_UGC_Copilot.Enum_UGC_LLM_State.IDLE, "init_failed:" .. reason)
  elseif self.CurrentState == Config_UGC_Copilot.Enum_UGC_LLM_State.INIT then
  else
    self:UpdateState(Config_UGC_Copilot.Enum_UGC_LLM_State.ERROR, "error_occurred:" .. reason)
  end
  if errorCode == Config_UGC_Copilot.Enum_UGC_LLM_ErrorCode.ERR_TIMEOUT then
    ShowNotice(LocUtil.GetLocalizeResStr(17005210))
  end
  self:ClearAllTimeouts()
  self:SetActiveTraceID(nil)
  EventSystem:postEvent(EVENTTYPE_UGC_COPILOT, EVENTID_UGC_COPILOT_ERROR_OCCURRED, errorCode)
  if self.CurrentState == Config_UGC_Copilot.Enum_UGC_LLM_State.ERROR then
    self:ConfirmError()
  end
end
function StateMachineManager:ConfirmError()
  if self.CurrentState == Config_UGC_Copilot.Enum_UGC_LLM_State.ERROR then
    self:UpdateState(Config_UGC_Copilot.Enum_UGC_LLM_State.IDLE, "error_confirmed")
    print(bWriteLog and "StateMachineManager:ConfirmError: " .. tostring(self.LastErrorCode))
    if IsEditor then
      ShowNotice("##(Editor Only) Copilot Error: " .. tostring(self.LastErrorCode))
    end
    self.Owner:ClearCurrentChatContext(true)
    self.LastErrorCode = nil
  end
end
function StateMachineManager:ClearAllTimeouts()
  print(bWriteLog and "StateMachineManager:ClearAllTimeouts")
  for _, timerID in pairs(self.stateTimeoutTimers) do
    self.Owner:RemoveTimer(timerID)
  end
  self.stateTimeoutTimers = {}
  for _, timerID in pairs(self.TimeoutTimers) do
    self.Owner:RemoveTimer(timerID)
  end
  self.TimeoutTimers = {}
end
function StateMachineManager:IsInitializationComplete()
  return self.CurrentState ~= Config_UGC_Copilot.Enum_UGC_LLM_State.INITIALIZING and self.CurrentState ~= Config_UGC_Copilot.Enum_UGC_LLM_State.HISTORY_LOADING and self.CurrentState ~= Config_UGC_Copilot.Enum_UGC_LLM_State.INIT
end
function StateMachineManager:IsLoadingHistory()
  return self.CurrentState == Config_UGC_Copilot.Enum_UGC_LLM_State.HISTORY_LOADING
end
function StateMachineManager:IsStreamingChatStoppable()
  return self.CurrentState == Config_UGC_Copilot.Enum_UGC_LLM_State.STREAMING or self.CurrentState == Config_UGC_Copilot.Enum_UGC_LLM_State.NEW_CHAT_PENDING or self.CurrentState == Config_UGC_Copilot.Enum_UGC_LLM_State.LONG_TASK_RUNNING
end
function StateMachineManager:IsChatIdle()
  return self.CurrentState == Config_UGC_Copilot.Enum_UGC_LLM_State.IDLE
end
function StateMachineManager:IsCollectingContext()
  return self.CurrentState == Config_UGC_Copilot.Enum_UGC_LLM_State.COLLECTING_CONTEXT
end
function StateMachineManager:IsMessageStale(chat_id, trace_id)
  if chat_id and self.stoppedChats[chat_id] then
    return true
  end
  if trace_id and self.stoppedTraceIDs[trace_id] then
    return true
  end
  return false
end
function StateMachineManager:MarkMessageStale(chat_id, trace_id)
  print(bWriteLog and string.format("StateMachineManager:MarkMessageStale %s, %s", chat_id, trace_id))
  if chat_id then
    self.stoppedChats[chat_id] = true
  end
  if trace_id then
    self.stoppedTraceIDs[trace_id] = true
  end
end
function StateMachineManager:IsTraceIdRevoked(traceId)
  return self._RevokedTraceIDs and self._RevokedTraceIDs[traceId]
end
function StateMachineManager:SetInitRequestComplete(reqType)
  self.initPendingRequests[reqType] = true
  self:CheckInitializationComplete()
end
function StateMachineManager:CheckInitializationComplete()
  if self.CurrentState ~= Config_UGC_Copilot.Enum_UGC_LLM_State.INITIALIZING then
    return
  end
  if self.initPendingRequests.LLMQuotaRsp and self.initPendingRequests.History then
    EventSystem:postEvent(EVENTTYPE_UGC_COPILOT, EVENTID_UGC_COPILOT_INIT_FINISH, true)
    self:UpdateState(Config_UGC_Copilot.Enum_UGC_LLM_State.IDLE, "INITComplete_Success")
    if self.PendingInGenTraceID then
      self.PendingInGenTraceID = nil
      self.PendingInGenData = nil
      self.CurrentLongTaskContext = self.PendingInGenData
      self:SetActiveTraceID(self.PendingInGenTraceID)
      self:UpdateState(Config_UGC_Copilot.Enum_UGC_LLM_State.LONG_TASK_RUNNING, "Pending LongTask")
    end
  end
end
function StateMachineManager:CommitLongTaskFinish(TraceID, result_code, MsgType, LocResParam)
  print(bWriteLog and "StateMachineManager:CommitLongTaskFinish")
  local stateMachine = self.Owner.StateMachine
  local sessionManager = self.Owner.SessionManager
  local MsgConfig = Config_UGC_Copilot.GetCopilotMessageTypeConfig(MsgType)
  if result_code ~= nil and result_code ~= 0 and TraceID then
    Config_UGC_Copilot.OutputError(Config_UGC_Copilot.ErrorSource.SERVER_GEN, result_code, Config_UGC_Copilot.ErrorOutputType.CHAT, {
      traceId = TraceID,
      hideFeedback = false,
      hideMessageBG = false
    }, LocResParam)
  end
  if sessionManager.ActiveChat and sessionManager.ActiveChat.AIMessage then
    local aiMessage = sessionManager.ActiveChat.AIMessage
    if aiMessage.TraceID == TraceID then
      print(bWriteLog and string.format("CommitLongTaskFinish: AIMessage completed. TraceID: %s", tostring(TraceID)))
      sessionManager.ActiveChat.AIMessage = nil
      stateMachine:SetActiveTraceID(nil)
      EventSystem:postEvent(EVENTTYPE_UGC_COPILOT, EVENTID_UGC_COPILOT_MESSAGE_COMPLETE, sessionManager.ActiveChat)
      print(bWriteLog and "CommitLongTaskFinish: AIMessage reference cleared from ActiveChat")
    else
      print(bWriteLog and string.format("CommitLongTaskFinish: TraceID mismatch. AIMessage TraceID: %s, Expected: %s", tostring(aiMessage.TraceID), tostring(TraceID)))
    end
  else
    print(bWriteLog and "CommitLongTaskFinish: No AIMessage found in ActiveChat or ActiveChat is nil")
  end
  if MsgConfig and MsgConfig.bIsLongTask and result_code ~= 0 and MsgConfig.OnLongTaskFailed then
    MsgConfig.OnLongTaskFailed(nil, TraceID)
  end
  if not stateMachine:UpdateState(Config_UGC_Copilot.Enum_UGC_LLM_State.IDLE, "LongTaskFinished") then
    print(bWriteLog and "StateMachineManager:CommitLongTaskFinish status is not correct")
    return
  end
  if self.CurrentLongTaskContext == nil then
    print(bWriteLog and "StateMachineManager:CommitLongTaskFinish self.CurrentLongTaskContext is nil, warning")
    return
  end
  if self.CurrentLongTaskContext.trace_id ~= nil and self.CurrentLongTaskContext.trace_id ~= TraceID then
    print(bWriteLog and "StateMachineManager:CommitLongTaskFinish self.CurrentLongTaskContext is nil, trace id is not consistent CurrentLongTaskContext")
    return
  end
  self.Owner.StateMachine:ClearCurrentLongTaskContext()
  if MsgConfig and MsgConfig.bIsLongTask and result_code == 0 and MsgConfig.OnLongTaskFinished then
    MsgConfig.OnLongTaskFinished(TraceID)
  end
end
function StateMachineManager:GetLongTaskGenType()
  return self.CurrentLongTaskContext and self.CurrentLongTaskContext.precheck and self.CurrentLongTaskContext.precheck.gen_precheck and self.CurrentLongTaskContext.precheck.gen_precheck.gen_type
end
function StateMachineManager:SimulateInGenResponsePending(TraceID, InGenData)
  print(bWriteLog and "StateMachineManager:SimulateInGenResponsePending")
  self.PendingInGenTraceID = TraceID
  self.PendingInGenData = InGenData
end
function StateMachineManager:OnStop()
  if self.CurrentLongTaskContext then
    local LongTaskTypeConfig = Config_UGC_Copilot.GetCopilotMessageTypeConfig(self:GetLongTaskGenType())
    if LongTaskTypeConfig and LongTaskTypeConfig.bIsLongTask then
      local TraceID = ""
      if self.CurrentLongTaskContext and self.CurrentLongTaskContext.trace_id then
        TraceID = self.CurrentLongTaskContext.trace_id
      end
      LongTaskTypeConfig.OnLongTaskFinished(TraceID)
    end
  end
  local subsceneTaskFeature = self.Owner.SubsceneTaskFeature
  if subsceneTaskFeature then
    local TraceID = self.ActiveTraceID
    print(bWriteLog and string.format("StateMachineManager:OnStop - SubsceneTaskFeature:OnStop TraceID=%s subsceneID=%s", tostring(TraceID), tostring(subsceneTaskFeature:GetCurrentSubsceneID())))
    subsceneTaskFeature:OnStop(TraceID, "state_machine_stop")
  end
  self.CurrentLongTaskContext = nil
  self:ClearAllTimeouts()
end
function StateMachineManager:SetActiveTraceID(Value)
  print(bWriteLog and "StateMachineManager:SetActiveTraceID TraceID(before)= " .. tostring(self.ActiveTraceID) .. "")
  print(bWriteLog and "StateMachineManager:SetActiveTraceID TraceID = " .. tostring(Value))
  self.ActiveTraceID = Value
  if Value ~= nil then
    self.LastActiveTraceID = Value
  end
  EventSystem:postEvent(EVENTTYPE_UGC_COPILOT, EVENTID_UGC_COPILOT_ACTIVETRACEID_CHANGED)
end
function StateMachineManager:GetActiveTraceID()
  return self.ActiveTraceID
end
function StateMachineManager:GetLastActiveTraceID()
  return self.LastActiveTraceID
end
function StateMachineManager:MarkRequestStart()
  self.RequestStartTime = os.time()
end
function StateMachineManager:GetExecutionDuration()
  if self.RequestStartTime then
    return os.time() - self.RequestStartTime
  end
  return -1
end
function StateMachineManager:GetCurrentLongTaskContext()
  return self.CurrentLongTaskContext
end
function StateMachineManager:SetCurrentLongTaskContext(LongTaskContextValue)
  print(bWriteLog and "StateMachineManager:SetCurrentLongTaskContext")
  log_tree("StateMachineManager:SetCurrentLongTaskContext", LongTaskContextValue)
  self.CurrentLongTaskContext = LongTaskContextValue
end
function StateMachineManager:ClearCurrentLongTaskContext()
  print(bWriteLog and "StateMachineManager:ClearCurrentLongTaskContext")
  self.CurrentLongTaskContext = nil
end
function StateMachineManager:ClearActiveStates()
  print(bWriteLog and "StateMachineManager:ClearActiveStates")
  self:ClearCurrentLongTaskContext()
  self:SetActiveTraceID(nil)
end
function StateMachineManager:ResetCurrentStateTimeout()
  local currentState = self.CurrentState
  local timeout = STATE_TIMEOUTS[currentState]
  if not timeout then
    return
  end
  print(bWriteLog and string.format("StateMachineManager:ResetCurrentStateTimeout - Resetting timeout for state: %s", currentState))
  if self.stateTimeoutTimers[currentState] then
    self.Owner:RemoveTimer(self.stateTimeoutTimers[currentState])
    self.stateTimeoutTimers[currentState] = nil
  end
  local timerID = self.Owner:AddTimerOnce(timeout, function()
    local CurrentState = self:GetCurrentState()
    if CurrentState then
      local StateConfig = Config_UGC_Copilot.CopilotStateConfig[CurrentState]
      if StateConfig and StateConfig.OnTimeOut then
        StateConfig.OnTimeOut()
      end
    end
    self:HandleError(Config_UGC_Copilot.Enum_UGC_LLM_ErrorCode.ERR_TIMEOUT, "state_timeout: " .. currentState)
  end)
  self.stateTimeoutTimers[currentState] = timerID
end
local class = require("class")
local object = require("object")
return class(object, nil, StateMachineManager)
