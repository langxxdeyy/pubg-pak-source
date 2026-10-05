local HomePK_Votes_Content_Popup_UIBP = {}
function HomePK_Votes_Content_Popup_UIBP:OnInitialize()
  self.Home_Popups_Large_UIBP = self:InitCommonPopup(self.UIRoot.Home_Popups_Large_UIBP)
  self.LoopScrollBox_Task = self:InitChildClassScrollBox(self.UIRoot.LoopScrollBox_Task, "GameLua.Mod.Lobby.Base.Home.PK.Item.HomePK_Votes_Content_Item_UIBP")
end
function HomePK_Votes_Content_Popup_UIBP:RegistEvents()
  self:AddCommonEvent(EVENTTYPE_POPULAR_HOMEPK, EVENTID_POPULAR_HOME_PK_GET_TASK_LIST, self.OnGetTaskList, self)
  self:AddCommonEvent(EVENTTYPE_POPULAR_HOMEPK, EVENTID_POPULAR_HOME_PK_TAKE_TASK_AWARD, self.OnTakeTaskAward, self)
end
function HomePK_Votes_Content_Popup_UIBP:OnPostInitialize()
  self.Home_Popups_Large_UIBP:SetData(self, LocUtil.GetLocalizeResStr(68018))
  local home_macros = require("client.slua.logic.home.home_macros")
  local PHomeTaskHandler = require("client.network.Protocol.PHomeTaskHandler")
  local logic_home_collection_task = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_home_collection_task)
  logic_home_collection_task:RequestManorTaskCfg(function()
    PHomeTaskHandler.send_get_manor_task_list_req(home_macros.ENUM_HOME_TASK_TYPE.HomePK)
  end)
  self:UpdateUI()
end
function HomePK_Votes_Content_Popup_UIBP:OnGetTaskList()
  log(bWriteLog and "HomePK_Votes_Content_Popup_UIBP:OnGetTaskList")
  self:UpdateUI()
end
function HomePK_Votes_Content_Popup_UIBP:OnTakeTaskAward()
  log(bWriteLog and "HomePK_Votes_Content_Popup_UIBP:OnTakeTaskAward")
  self:UpdateUI()
end
function HomePK_Votes_Content_Popup_UIBP:UpdateUI()
  local logic_popular_home_pk_task = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_popular_home_pk_task)
  local taskList = logic_popular_home_pk_task:GetTaskList()
  self.LoopScrollBox_Task:SetData(taskList)
  self.UIRoot.TextBlock_Desc:SetText(LocUtil.GetLocalizeResStr(66797))
  if self.countDownTimer then
    self:RemoveTimer(self.countDownTimer)
    self.countDownTimer = nil
  end
  self.weeklyTaskEndTime = logic_popular_home_pk_task:GetTaskEndTime()
  if self.weeklyTaskEndTime then
    self.countDownTimer = self:AddTimerLoop(0, function()
      self:RefreshCountDown()
    end, TIMER_INFINITE, 1)
  end
end
function HomePK_Votes_Content_Popup_UIBP:RefreshCountDown()
  local TimeUtil = require("client.common.time_util")
  local remainTime = self.weeklyTaskEndTime - TimeUtil.GetServerTimeInSec()
  local timeStr = TimeUtil.FormatCountDownTime_DH_or_HM(remainTime, true)
  self.UIRoot.TextBlock_Time:SetText(timeStr)
end
local class = require("class")
local ui_base = require("client.slua_ui_framework.base")
local CHomePK_Votes_Content_Popup_UIBP = class(ui_base, nil, HomePK_Votes_Content_Popup_UIBP)
return CHomePK_Votes_Content_Popup_UIBP
