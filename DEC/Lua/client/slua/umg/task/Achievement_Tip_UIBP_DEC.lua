local logic_achievement_float_tip = require("client.slua.logic.achievement.logic_achievement_float_tip")
local Achievement_Tip_UIBP = {}
function Achievement_Tip_UIBP:ctor(selfType, achieveIdList)
  self.achieveIDList = achieveIdList
  self.curShowID = 0
  self.IsNeedShowNext = false
  self.ppConfig = logic_achievement_float_tip.GetPlayerPrefabConfig()
end
function Achievement_Tip_UIBP:RegistEvents()
  Achievement_Tip_UIBP.__super.RegistEvents(self)
  self:AddCommonEvent(EVENTTYPE_TEAMUP, EVENTID_TEAMUP_ACCEPT_INVITE, self.OnTeamupAcceptInvite, self)
end
function Achievement_Tip_UIBP:OnShow()
  Achievement_Tip_UIBP.__super.OnShow(self)
  self:InitChildUI("Achievement_Tip_UIBP", true, false, true)
  if self.achieveIDList and next(self.achieveIDList) then
    self:ShowAchieveTip(self.achieveIDList)
  end
end
function Achievement_Tip_UIBP:ShowAchieveTip(ListID)
  if ListID and #ListID == 1 then
    self.curShowID = ListID[1]
  else
    self.curShowID = 0
  end
  self.ShowIdList = ListID
  self:RefreshInfo(self.ShowIdList)
  self:PlayUserWidgetAnimation(self.UIRoot.MoveIn, 0, 1, 0, 1)
end
function Achievement_Tip_UIBP:ShowNextTip()
  local t = logic_achievement_float_tip.AchievementIDList
  if 0 < #t then
    local ID = table.remove(t, 1)
    if ID and 0 < tonumber(ID) then
      self:ShowAchieveTip(ID)
    end
  else
    self:CloseSelf()
  end
end
function Achievement_Tip_UIBP:RefreshInfo(ShowList)
  local AchList = ShowList
  table.sort(AchList, function(a, b)
    local achievementA = CDataTable.GetTableData("AchievementCfg", a)
    local achievementB = CDataTable.GetTableData("AchievementCfg", b)
    if achievementA and achievementB and achievementA.ColorType ~= achievementB.ColorType then
      return achievementA.ColorType > achievementB.ColorType
    end
  end)
  local ItemList = {}
  if AchList and #AchList == 1 then
    local AchData = CDataTable.GetTableData("AchievementCfg", AchList[1])
    local Score = AchData.Score
    self.childUI.UIRoot.HorizontalBox_3:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    self.childUI.UIRoot.Image_2:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    self.childUI.UIRoot.LbScore:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    self.childUI.UIRoot.LbScore:SetText(Score)
  else
    self.childUI.UIRoot.HorizontalBox_3:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  end
  if AchList then
    local logic_achievement = require("client.slua.logic.achievement.logic_achievement")
    for i = 1, #AchList do
      local AchID = AchList[i]
      local PlayerPrefsSystem = require("client.logic.LogicPlayerPrefs.playerprefs")
      local saveData = PlayerPrefsSystem.LoadFileToTable_N(self.ppConfig) or {}
      table.insert(saveData, AchID)
      PlayerPrefsSystem.SaveTableToFile_N(saveData, self.ppConfig)
      logic_achievement_float_tip.InsertLocalRecord(AchID)
      local achievement = CDataTable.GetTableData("AchievementCfg", AchID)
      local IsMapping, AwardID, AwardNum, AwardID2, AwardNum2 = logic_achievement.GetAward(AchID)
      local list = {
        [1] = AwardID or achievement.AwardID,
        [2] = AwardNum or achievement.AwardNum
      }
      table.insert(ItemList, list)
      if AwardID2 and 0 < AwardID2 or achievement.AwardID2 and 0 < achievement.AwardID2 then
        local list2 = {
          [1] = AwardID2 or achievement.AwardID2,
          [2] = AwardNum2 or achievement.AwardNum2
        }
        table.insert(ItemList, list2)
      end
    end
  end
  table.sort(ItemList, function(a, b)
    local ItemA = CDataTable.GetTableData("Item", a[1])
    local ItemB = CDataTable.GetTableData("Item", b[1])
    if not ItemA or not ItemB then
      return false
    end
    if ItemA.ItemQuality ~= ItemB.ItemQuality then
      return ItemA.ItemQuality > ItemB.ItemQuality
    end
  end)
  for i = 1, 5 do
    if ItemList[i] then
      self.childUI.UIRoot["Activty_Tip_BP" .. i]:SetWidgetVisibility(UEnums.ESlateVisibility.HitTestInvisible)
      self.childUI.UIRoot["Activty_Tip_BP" .. i]:SetAwardItemNum(ItemList[i][2])
      self.childUI.UIRoot["Activty_Tip_BP" .. i]:SetIcon(ItemList[i][1])
    else
      self:SetWidgetVisible(self.childUI.UIRoot["Activty_Tip_BP" .. i], false)
    end
  end
  local achievement1 = CDataTable.GetTableData("AchievementCfg", AchList[1])
  if achievement1 then
    if AchList and #AchList == 1 then
      self.childUI.UIRoot.LbTitle:SetText(LocUtil.LocalizeResFormat(4773, achievement1.Name))
    else
      self.childUI.UIRoot.LbTitle:SetText(LocUtil.LocalizeResFormat(512035, achievement1.Name, AchList and #AchList or 0))
    end
    self.childUI.UIRoot.Icon:SetData(achievement1.GroupID, achievement1.MultiLvGroupNum, achievement1.BigImgUrl)
    self:SetWidgetVisible(self.childUI.UIRoot.WidgetSwitcher_1, achievement1.AchType == 1 or achievement1.AchType == 2)
    self.childUI.UIRoot.WidgetSwitcher_1:SetActiveWidgetIndex(0)
    if achievement1.AchType == 1 then
      self.childUI.UIRoot.TextBlock_15:SetText(LocUtil.LocalizeResFormat(18406))
    end
    if achievement1.AchType == 2 then
      self.childUI.UIRoot.WidgetSwitcher_1:SetActiveWidgetIndex(1)
      self.childUI.UIRoot.TextBlock_16:SetText(LocUtil.LocalizeResFormat(18405))
    end
  end
end
function Achievement_Tip_UIBP:RemoveCheckNextTimer()
  if self.CheckNextTimer then
    self:RemoveTimer(self.CheckNextTimer)
    self.CheckNextTimer = nil
  end
end
function Achievement_Tip_UIBP:OnClickClose()
  log(bWriteLog and "[chub]Achievement_Tip_UIBP:OnClickClose")
  Achievement_Tip_UIBP.__super.OnClickClose(self)
  logic_achievement_float_tip.HasClickedIngore = true
  logic_achievement_float_tip.ClearNewAchievementList()
end
function Achievement_Tip_UIBP:OnClickJump()
  self:PlayAudio(sound_config.click_v1)
  log(bWriteLog and "[v_wllwu] Achievement_Tip_UIBP:OnClickGo enter curShowID is " .. tostring(self.curShowID))
  if logic_achievement_float_tip.BlockingPopTip then
    log(bWriteLog and "[v_wllwu] Achievement_Tip_UIBP:OnClickGo has BlockingPopTip curShowID is " .. tostring(self.curShowID))
    return
  end
  local corp_welfare = require("client.slua.logic.corps.logic_corps_welfare")
  corp_welfare.ShowRedEnvelopUI()
  EventSystem:postEvent(EVENTTYPE_RANK, EVENTID_RANK_CLOSE)
  local uiTbl = {
    UIManager.UI_Config.ItemPreview_UIBP,
    UIManager.UI_Config.ui_chat_language_select,
    UIManager.UI_Config.ui_match_language_select,
    UIManager.UI_Config.Common_ItemGet_UIBP,
    UIManager.UI_Config.corps_recruit,
    UIManager.UI_Config.item_upgrade,
    UIManager.UI_Config.corps_welfare_redEnvelop,
    UIManager.UI_Config.pve_levelup_panel,
    UIManager.UI_Config.LuckyAirDrop_Main_UIBP,
    UIManager.UI_Config.mode_selection_main,
    UIManager.UI_Config.AchievementScoreAward_UIBP,
    UIManager.UI_Config.wardrobe,
    UIManager.UI_Config.fashion_bag_overview
  }
  for _, uiCfg in ipairs(uiTbl) do
    if UIManager.GetUI(uiCfg) then
      UIManager.CloseUI(uiCfg)
    end
  end
  local UnknowPassTunnelSystem = require("client.slua.logic.unknow_pass.NewRPPreview.logic_unknowpass_tunnel")
  UnknowPassTunnelSystem.CloseRP()
  UIManager.CloseUI(UIManager.UI_Config.Lobby_SeasonUI_Homepage_New01_Sidebar_UIBP)
  local pandoraSystem = require("client.slua.logic.Pandora.pandora_system")
  pandoraSystem.HideCurAct()
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  RoleInfoMainSystem.Close()
  EventSystem:postEvent(EVENTTYPE_WEAPON_DIY, EVENTID_WEAPON_DIY_JUMP_CLOSE)
  EventSystem:postEvent(EVENTTYPE_CHARACTER, EVENTID_CHARACTER_CLOSE_MAIN)
  local store_supply_manager = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.store_supply_manager)
  local frame = store_supply_manager:GetCurrentFrame()
  if frame ~= nil then
    frame:CloseSelf()
  end
  UIManager.AndroidBackToLobby()
  local index = RoleInfoMainSystem.Honor
  local openFrom = RoleInfoMainSystem.RoleInfoOpenFromType.Lobby
  local uid = DataMgr.roleData.uid
  local bShow = RoleInfoMainSystem.Show(index, openFrom, uid, {
    achieveInfo = {
      AchID = self.curShowID
    }
  })
  if bShow == true then
    ClientSendBAReport(TLogEventDefine.AchievementFloatTip, 0)
    logic_achievement_float_tip.ClearNewAchievementList()
    self:CloseSelf()
  end
end
function Achievement_Tip_UIBP:OnClose()
  Achievement_Tip_UIBP.__super.OnClose(self)
  logic_achievement_float_tip.RemoveFromQueue()
  if self.IsNeedShowNext then
    self.IsNeedShowNext = false
    local time_ticker = require("common.time_ticker")
    time_ticker.AddTimerOnce(0.3, function()
      logic_achievement_float_tip.ShowAchievementTip()
    end)
  end
end
function Achievement_Tip_UIBP:OnTeamupAcceptInvite()
  logic_achievement_float_tip.ClearNewAchievementList()
  self:CloseSelf()
end
local class = require("class")
local ui_base = require("client.slua.umg.common.Common_RightBottom_Tip_Base")
local CAchievement_Tip_UIBP = class(ui_base, nil, Achievement_Tip_UIBP)
return CAchievement_Tip_UIBP
