local Logic_SmallRPConst = require("client.slua.logic.specialoffer.SmallRP.Logic_SmallRPConst")
local Logic_SmallRPUIContext = require("client.slua.logic.specialoffer.SmallRP.Logic_SmallRPUIContext")
local SmallRP_Task_UIBP = {}
local Enum_Task = Logic_SmallRPConst.Enum_Task
local _Enum_TaskType = {
  All = 1,
  Time = 2,
  Challenge = 3,
  WearingKilling = 4,
  TPlayGame = 5,
  Other = 6,
  Additional = 7,
  Linkage = 8
}
local _tTaskTypeTitle = {
  [_Enum_TaskType.All] = 4462,
  [_Enum_TaskType.Time] = 77875,
  [_Enum_TaskType.Challenge] = 18549,
  [_Enum_TaskType.WearingKilling] = 77876,
  [_Enum_TaskType.TPlayGame] = 66975,
  [_Enum_TaskType.Other] = 66976,
  [_Enum_TaskType.Additional] = 69476,
  [_Enum_TaskType.Linkage] = 79465
}
function SmallRP_Task_UIBP:ctor(_, tContext)
  self._nLastTabIndex = nil
  self._tAllTaskTabData = nil
  self._cObj_taskTabLoop = nil
  self._cObj_taskLoop = nil
  self._cObj_avatarDisplay = nil
  self._bIsCardUnlock = false
  self._nCurTaskProValue = 0
  self._cObj_smallRPModule, self._nActivityId, self._tSmallRPContext = Logic_SmallRPUIContext.Create(tContext)
end
function SmallRP_Task_UIBP:OnInitialize()
  SmallRP_Task_UIBP.__super.OnInitialize(self)
  local node_root = self.UIRoot
  self._cObj_taskTabLoop = self:InitChildClassScrollBox(node_root.LoopScrollBox_Tab, "client.slua.umg.SmallRP.SmallRP_Task_Tab_Item_UIBP")
  self._cObj_taskLoop = self:InitChildClassScrollBox(node_root.LoopScrollBox_Task, "client.slua.umg.SmallRP.SmallRP_Task_Item_UIBP", self._tSmallRPContext)
end
function SmallRP_Task_UIBP:RegistEvents()
  SmallRP_Task_UIBP.__super.RegistEvents(self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Close, self.OnCloseBtnClick, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Unlock, self.OnUnlockActBtnClick, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_GetAll, self.OnGetAllBtnClick, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_ToGo, self.OnGoToBtnClick, self)
  local node_root = self.UIRoot
  self:AddControlEventByControl(node_root.SmallRP_Task_Gift_Item_UIBP.Button_ProReward, "OnClicked", self.OnProRewardButtonClick, self)
  self:AddCommonEvent(EVENTTYPE_SMALL_RP, EVENTID_SMALL_RP_UNLOCK, self.OnUnlockEvent, self)
  self:AddCommonEvent(EVENTTYPE_SMALL_RP, EVENTID_SMALL_RP_TASK_UPDATE, self.OnTaskUpdateEvent, self)
  self:AddCommonEvent(EVENTTYPE_SMALL_RP, EVENTID_SMALL_RP_UPDATE_TASK_PRO_REWARD, self.OnTaskProRewardUpdateEvent, self)
  self:AddCommonEvent(EVENTTYPE_SMALL_RP, EVENTID_SMALL_RP_GOT_ACT_DATA, self.OnGotActDataEvent, self)
  self:AddCommonEvent(EVENTTYPE_SMALL_RP, EVENTID_SMALL_RP_ACTIVITY_REWARD_UPDATE, self.OnActivityRewardUpdateEvent, self)
  self:AddCommonEvent(EVENTTYPE_SMALL_RP, EVENTID_SMALL_RP_ACTIVITY_UNLOCK, self.OnActivityUnlockEvent, self)
  self:AddCommonEvent(EVENTTYPE_SMALL_RP, EVENTID_SMALL_RP_ACTIVITY_TASK_UPDATE, self.OnActivityTaskUpdateEvent, self)
  self:AddCommonEvent(EVENTTYPE_SMALL_RP, EVENTID_SMALL_RP_ACTIVITY_UPDATE_TASK_PRO_REWARD, self.OnActivityTaskProRewardUpdateEvent, self)
  self:AddCommonEvent(EVENTTYPE_SMALL_RP, EVENTID_SMALL_RP_ACTIVITY_GOT_ACT_DATA, self.OnActivityGotActDataEvent, self)
end
function SmallRP_Task_UIBP:OnPostInitialize()
  SmallRP_Task_UIBP.__super.OnPostInitialize(self)
  self:InitShow()
  local node_root = self.UIRoot
  node_root:PlayUserWidgetAnimation(node_root.Fadein, 0, 1, 0, 1)
end
function SmallRP_Task_UIBP:OnClose()
  SmallRP_Task_UIBP.__super.OnClose(self)
  if self._cObj_avatarDisplay then
    local ConstAvatarDisplay = require("client.slua.traits.DetailComponent.AvatarDisplay.ConstAvatarDislay")
    self._cObj_avatarDisplay:LoadLevelBySceneType(ConstAvatarDisplay.ESceneType.SmallRP300)
  end
end
function SmallRP_Task_UIBP:OnAndroidBack()
  local ui_jump_manager = require("client.common.uibase.ui_jump_manager")
  ui_jump_manager.CloseJumpModule(BP_ENUM_MODULE_SMALL_RP_TASK)
end
function SmallRP_Task_UIBP:JumpBack()
  self._cObj_avatarDisplay = self:CreateChildWindow(self.UIRoot.CanvasPanel_Details, UIManager.UI_Config.AvatarDisplayComponent)
end
function SmallRP_Task_UIBP:OnCloseBtnClick()
  self:PlayAudio(sound_config.click)
  self:OnAndroidBack()
end
function SmallRP_Task_UIBP:OnUnlockActBtnClick()
  self:PlayAudio(sound_config.click)
  local Enum_UnlockSourceType = Logic_SmallRPConst.Enum_UnlockSourceType
  self._cObj_smallRPModule:UnlockActBuy(Enum_UnlockSourceType.Task, self._bIsCardUnlock)
end
function SmallRP_Task_UIBP:OnGetAllBtnClick()
  self:PlayAudio(sound_config.click)
  if self._nActivityId then
    local SmallRPActivityHandler = require("client.network.Protocol.SmallRPActivityHandler")
    SmallRPActivityHandler.send_small_rp_activity_batch_get_task_award_req(self._nActivityId)
    return
  end
  local SmallRPHandler = require("client.network.Protocol.SmallRPHandler")
  SmallRPHandler.send_small_rp_batch_get_task_award_req()
end
function SmallRP_Task_UIBP:OnGoToBtnClick()
  self:PlayAudio(sound_config.click)
  local cObj_smallRPModule = self._cObj_smallRPModule
  cObj_smallRPModule:JumpToRelatedModule(1)
end
function SmallRP_Task_UIBP:OnProRewardButtonClick()
  self:PlayAudio(sound_config.click)
  local cObj_smallRPModule = self._cObj_smallRPModule
  local nCurTaskProValue = self._nCurTaskProValue
  local nCanReceiveCount = cObj_smallRPModule:GetCanReceiveTaskProRewardCount(nCurTaskProValue)
  local bIsUnlock = cObj_smallRPModule:GetIsUnlock()
  if nCanReceiveCount <= 0 then
    local nPackageItemId = cObj_smallRPModule:GetTaskProRewardAwardId()
    if not nPackageItemId then
      return
    end
    UIManager.ShowUI(UIManager.UI_Config.package_preview_panel, nPackageItemId)
  elseif not bIsUnlock and 0 < nCanReceiveCount then
    ShowNotice(76597)
  elseif bIsUnlock and 0 < nCanReceiveCount then
    if self._nActivityId then
      local SmallRPActivityHandler = require("client.network.Protocol.SmallRPActivityHandler")
      SmallRPActivityHandler.send_small_rp_activity_batch_get_stage_award_req(self._nActivityId)
      return
    end
    local SmallRPHandler = require("client.network.Protocol.SmallRPHandler")
    SmallRPHandler.send_small_rp_batch_get_stage_award_req()
  end
end
function SmallRP_Task_UIBP:OnUnlockEvent()
  self:RefreshUnlockShow()
end
function SmallRP_Task_UIBP:OnTaskUpdateEvent()
  self._cObj_taskTabLoop:RefreshAllItems()
  self:RefreshLevelShow()
  self:RefreshTaskList()
  self:RefreshGetAllBtnShow()
  self:RefreshTaskTotalProShow()
end
function SmallRP_Task_UIBP:OnTaskProRewardUpdateEvent()
  self:RefreshTaskProRewardShow(self._nCurTaskProValue)
end
function SmallRP_Task_UIBP:OnActivityRewardUpdateEvent(_, _, nActivityId, sRewardType)
  if not self._nActivityId or self._nActivityId ~= tonumber(nActivityId) then
    return
  end
  if sRewardType == "task" then
    self:OnTaskUpdateEvent()
  elseif sRewardType == "stage" then
    self:OnTaskProRewardUpdateEvent()
  end
end
function SmallRP_Task_UIBP:OnGotActDataEvent()
  self:RefreshUnlockShow()
  self:RefreshToGoButtonShow()
end
function SmallRP_Task_UIBP:OnActivityUnlockEvent(_, _, nActivityId)
  if not self._nActivityId or self._nActivityId ~= tonumber(nActivityId) then
    return
  end
  self:OnUnlockEvent()
end
function SmallRP_Task_UIBP:OnActivityTaskUpdateEvent(_, _, nActivityId)
  if not self._nActivityId or self._nActivityId ~= tonumber(nActivityId) then
    return
  end
  self:OnTaskUpdateEvent()
end
function SmallRP_Task_UIBP:OnActivityTaskProRewardUpdateEvent(_, _, nActivityId)
  if not self._nActivityId or self._nActivityId ~= tonumber(nActivityId) then
    return
  end
  self:OnTaskProRewardUpdateEvent()
end
function SmallRP_Task_UIBP:OnActivityGotActDataEvent(_, _, nActivityId)
  if not self._nActivityId or self._nActivityId ~= tonumber(nActivityId) then
    return
  end
  self:RefreshUnlockShow()
  self:RefreshToGoButtonShow()
end
local _GetTaskPriority = function(tTaskStatues)
  if not tTaskStatues then
    return 2
  end
  if tTaskStatues.status == Enum_Task.Completed then
    return 1
  elseif tTaskStatues.status == Enum_Task.Received then
    return 3
  else
    return 2
  end
end
function SmallRP_Task_UIBP:InitShow()
  local node_root = self.UIRoot
  local cObj_smallRPModule = self._cObj_smallRPModule
  self:InitTextureShow()
  node_root.Text_Title:SetText(LocUtil.LocalizeResFormat(66023))
  node_root.Text_UnlockActTip:SetText(LocUtil.LocalizeResFormat(66022))
  node_root.Text_Describe:SetText(LocUtil.GetLocalizeResStr(66301))
  node_root.Text_TaskProValueTip:SetText(LocUtil.GetLocalizeResStr(76585))
  local nMinProValue = cObj_smallRPModule:GetTaskProRewardMinProValue()
  local sShowStr = nMinProValue ~= 0 and LocUtil.LocalizeResFormat(76586, nMinProValue) or ""
  node_root.Text_TaskRewardTip:SetText(sShowStr)
  self:InitTaskTab()
  self:InitUnlockBtnShow()
  self:RefreshUnlockShow()
  self:RefreshToGoButtonShow()
  self:RefreshGetAllBtnShow()
  self:RefreshTaskTotalProShow()
  self:RefreshLevelShow()
  self:ShowLevelReward()
end
function SmallRP_Task_UIBP:InitTextureShow()
  local cObj_smallRPModule = self._cObj_smallRPModule
  local uObj_actCfg = cObj_smallRPModule:GetActShowCfg()
  if not uObj_actCfg then
    return
  end
  local sBasePath = uObj_actCfg.TemplateBasePath
  local node_root = self.UIRoot
  self:SetTexture(node_root.Image_TaskPanelBgL, sBasePath .. "NoAtlas/Image_BgL.Image_BgL")
  self:SetTexture(node_root.Image_TaskPanelBgR, sBasePath .. "NoAtlas/Image_BgR.Image_BgR")
  self:SetTexture(node_root.Image_People, sBasePath .. "NoAtlas/Image_People.Image_People")
  self:SetTexture(node_root.Image_LevelIcon, sBasePath .. "NoAtlas/Image_LevelIcon.Image_LevelIcon")
end
function SmallRP_Task_UIBP:InitTaskTab()
  local cObj_smallRPModule = self._cObj_smallRPModule
  local tAllTaskCfg = cObj_smallRPModule:GetCurRoundTaskCfg()
  local tAllTab = {
    {
      nTaskType = _Enum_TaskType.All,
      sTitle = LocUtil.GetLocalizeResStr(_tTaskTypeTitle[_Enum_TaskType.All]),
      tAllTask = {},
      fCheckRedFun = function()
        return self._cObj_smallRPModule:GetHasTaskCompletedStatus()
      end
    }
  }
  for _, v in pairs(tAllTaskCfg) do
    local nTaskType = v.TaskShowType
    if nTaskType and nTaskType ~= 0 then
      if not tAllTab[nTaskType] then
        tAllTab[nTaskType] = {
          nTaskType = nTaskType,
          sTitle = LocUtil.GetLocalizeResStr(_tTaskTypeTitle[nTaskType]),
          tAllTask = {}
        }
      end
      table.insert(tAllTab[nTaskType].tAllTask, v)
    end
    table.insert(tAllTab[_Enum_TaskType.All].tAllTask, v)
  end
  local tAllTabShow = {}
  for _, v in pairs(tAllTab) do
    table.insert(tAllTabShow, v)
  end
  table.sort(tAllTabShow, function(a, b)
    return a.nTaskType < b.nTaskType
  end)
  self._tAllTaskTabData = tAllTabShow
  self._cObj_taskTabLoop:SetData(tAllTabShow)
  local nShowIndex = 1
  self._cObj_taskTabLoop:Select(nShowIndex)
  self._nLastTabIndex = nShowIndex
  self:RefreshTaskList(nShowIndex)
end
function SmallRP_Task_UIBP:RefreshTaskList(nCurTabIndex)
  local tAllTaskTabData = self._tAllTaskTabData
  if not tAllTaskTabData then
    return
  end
  nCurTabIndex = nCurTabIndex or self._nLastTabIndex or 1
  local tCurTabData = tAllTaskTabData[nCurTabIndex] or {}
  local tAllShowTask = tCurTabData.tAllTask or {}
  if not next(tAllShowTask) then
    return
  end
  local cObj_smallRPModule = self._cObj_smallRPModule
  local tAllTaskData = cObj_smallRPModule:GetAllTaskData()
  if next(tAllTaskData) then
    table.sort(tAllShowTask, function(a, b)
      local tTaskA = tAllTaskData[a.TaskId]
      local tTaskB = tAllTaskData[b.TaskId]
      local nPriorityA = _GetTaskPriority(tTaskA)
      local nPriorityB = _GetTaskPriority(tTaskB)
      if nPriorityA ~= nPriorityB then
        return nPriorityA < nPriorityB
      end
      return a.Sort < b.Sort
    end)
  else
    table.sort(tAllShowTask, function(a, b)
      return a.Sort < b.Sort
    end)
  end
  self._cObj_taskLoop:SetData(tAllShowTask)
end
function SmallRP_Task_UIBP:InitUnlockBtnShow()
  local node_root = self.UIRoot
  local cObj_smallRPModule = self._cObj_smallRPModule
  local nCardItemId = cObj_smallRPModule:GetSmallRPCardId()
  local UIUtil = require("client.common.ui_util")
  local CoinMacro = require("client.slua.config.ClientMacros.CoinMacro")
  local wardrobeData = require("client.slua.logic.wardrobe.wardrobe_data")
  if nCardItemId and wardrobeData:GetHallDepotItemDataByResID(nCardItemId) then
    self._bIsCardUnlock = true
    node_root.Text_Price:SetText(1)
    self:SetTexture(node_root.Image_PriceIcon, UIUtil.GetItemSmallIcon(nCardItemId))
  else
    node_root.Text_Price:SetText(cObj_smallRPModule:GetUnlockNeedUC())
    self:SetTexture(node_root.Image_PriceIcon, UIUtil.GetItemSmallIcon(CoinMacro.Uc))
  end
end
function SmallRP_Task_UIBP:RefreshUnlockShow()
  local node_root = self.UIRoot
  local bIsUnlock = self._cObj_smallRPModule:GetIsUnlock()
  self:SetWidgetVisible(node_root.Text_Describe, not bIsUnlock)
  self:SetWidgetVisible(node_root.Button_Unlock, not bIsUnlock, true)
end
function SmallRP_Task_UIBP:RefreshToGoButtonShow()
  local cObj_smallRPModule = self._cObj_smallRPModule
  local nEntranceType = cObj_smallRPModule:GetConcernEntranceType(1)
  local nEntranceId = cObj_smallRPModule:GetConcernEntranceID(1)
  local bHasRelatedActivity = nEntranceType ~= Logic_SmallRPConst.Enum_EntranceType.Invalid and nEntranceId ~= nil and nEntranceId ~= 0
  self:SetWidgetVisible(self.UIRoot.Button_ToGo, bHasRelatedActivity, true)
end
function SmallRP_Task_UIBP:RefreshGetAllBtnShow()
  local node_root = self.UIRoot
  local bHasGet = self._cObj_smallRPModule:GetHasTaskCompletedStatus()
  node_root.WidgetSwitcher_GetAll:SetActiveWidgetIndex(bHasGet and 0 or 1)
end
function SmallRP_Task_UIBP:RefreshLevelShow()
  local cObj_smallRPModule = self._cObj_smallRPModule
  local nCurLevel = cObj_smallRPModule:GetCurLevel()
  local nMaxLevel = cObj_smallRPModule:GetMaxLevel()
  local node_root = self.UIRoot
  node_root.Text_Level:SetText(LocUtil.LocalizeResFormat(6417, nCurLevel))
  if nCurLevel >= nMaxLevel then
    node_root.Text_Score:SetText(LocUtil.GetLocalizeResStr(44960))
    node_root.Process_Score:SetPercent(1)
  else
    local nCurScore = cObj_smallRPModule:GetCurScore()
    local nNextLevelScore = cObj_smallRPModule:GetLevelScore(nCurLevel + 1)
    node_root.Text_Score:SetText(LocUtil.LocalizeResFormat(7255, nCurScore, nNextLevelScore))
    local nProValue = nCurScore / nNextLevelScore
    node_root.Process_Score:SetPercent(nProValue)
  end
end
function SmallRP_Task_UIBP:RefreshTaskTotalProShow()
  local node_root = self.UIRoot
  local nProValue = self._cObj_smallRPModule:GetFinishTaskPro()
  node_root.Text_TaskProValue:SetText(LocUtil.LocalizeResFormat(10283, nProValue))
  self._nCurTaskProValue = nProValue
  self:RefreshTaskProRewardShow(nProValue)
end
function SmallRP_Task_UIBP:ChangeTaskTab(nSelectIndex)
  if self._nLastTabIndex == nSelectIndex then
    return
  end
  self._cObj_taskTabLoop:Select(nSelectIndex)
  self._nLastTabIndex = nSelectIndex
  self:RefreshTaskList(nSelectIndex)
end
function SmallRP_Task_UIBP:RefreshTaskProRewardShow(nProValue)
  local node_root = self.UIRoot
  local node_proReward = node_root.SmallRP_Task_Gift_Item_UIBP
  local cObj_smallRPModule = self._cObj_smallRPModule
  local bIsReceivedAllProReward = cObj_smallRPModule:GetIsReceivedAllTaskProReward()
  self:SetWidgetVisible(node_root.CanvasPanel_TaskProReward, not bIsReceivedAllProReward)
  if bIsReceivedAllProReward then
    return
  end
  nProValue = nProValue or cObj_smallRPModule:GetFinishTaskPro()
  local nCanReceiveCount = cObj_smallRPModule:GetCanReceiveTaskProRewardCount(nProValue)
  local bIsUnlock = cObj_smallRPModule:GetIsUnlock()
  self:SetWidgetVisible(node_proReward.Image_Red, bIsUnlock and 0 < nCanReceiveCount)
  local nShowIndex = 1
  if 0 < nCanReceiveCount then
    nShowIndex = 0
  end
  node_proReward.WidgetSwitcher_Status:SetActiveWidgetIndex(nShowIndex)
  node_proReward.Text_RewardNum1:SetText(nCanReceiveCount)
  node_proReward.Text_RewardNum2:SetText(nCanReceiveCount)
end
function SmallRP_Task_UIBP:ShowLevelReward()
  local cObj_smallRPModule = self._cObj_smallRPModule
  local bIsUnlock = cObj_smallRPModule:GetIsUnlock()
  if bIsUnlock then
    return
  end
  local tAllShowLevel = cObj_smallRPModule:GetTipRewardLevelData()
  if not tAllShowLevel then
    return
  end
  local nShowMinLevel = tonumber(tAllShowLevel[1])
  local nCurLevel = cObj_smallRPModule:GetCurLevel()
  if nShowMinLevel > nCurLevel then
    return
  end
  local TimeUtil = require("client.common.time_util")
  local nCurTime = TimeUtil.GetServerTimeInSec()
  if self._nActivityId then
    local nLastTime = cObj_smallRPModule:GetShowUnlockRewardTime()
    if nLastTime and TimeUtil.IsSameDay(nLastTime, nCurTime) then
      return
    end
    cObj_smallRPModule:SetShowUnlockRewardTime(nCurTime)
    local tContext = {
      logic = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.Logic_SmallRPActivity),
      activity_id = self._nActivityId
    }
    UIManager.ShowUI(UIManager.UI_Config.SpecialOffer_SmallRP_Push_Popup_UIBP, tContext, true)
  else
    local PlayerPrefsSystem = require("client.logic.LogicPlayerPrefs.playerprefs")
    local tSmallRPLocalCache = PlayerPrefsSystem.LoadFileToTable_N(PlayerPrefsSystem.ePlayerPrefsType.eSmallRP) or {}
    local nLastTime = tSmallRPLocalCache.nShowUnlockRewardTime
    if nLastTime and TimeUtil.IsSameDay(nLastTime, nCurTime) then
      return
    end
    UIManager.ShowUI(UIManager.UI_Config.SpecialOffer_SmallRP_Push_Popup_UIBP, nil, true)
  end
end
local class = require("class")
local ui_base = require("client.slua_ui_framework.base")
local CSmallRP_Task_UIBP = class(ui_base, nil, SmallRP_Task_UIBP)
return CSmallRP_Task_UIBP
