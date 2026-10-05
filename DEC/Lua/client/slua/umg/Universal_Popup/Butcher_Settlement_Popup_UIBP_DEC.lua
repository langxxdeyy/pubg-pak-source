local Butcher_Settlement_Popup_UIBP = {}
local history_combat_cfg = require("client.logic.combat.history.history_combat_cfg")
function Butcher_Settlement_Popup_UIBP:ctor(_, history_record)
  log_tree("Butcher_Settlement_Popup_UIBP:ctor, history_record = ", history_record)
  self.data = history_record
end
function Butcher_Settlement_Popup_UIBP:OnInitialize()
  Butcher_Settlement_Popup_UIBP.__super.OnInitialize(self)
end
function Butcher_Settlement_Popup_UIBP:RegistEvents()
  self:AddOnClickedEventByControl(self.UIRoot.Button_Jump, self.OnClickButton_Jump, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Close, self.OnClickButton_Close, self)
  self:AddControlEventByControl(self.UIRoot.MoveOut, "OnAnimationFinished", self.OnAnimationEnd, self)
end
function Butcher_Settlement_Popup_UIBP:OnPostInitialize()
  self:InitData()
  self:UpdateUI()
end
function Butcher_Settlement_Popup_UIBP:InitData()
  self:PlayUserWidgetAnimation(self.UIRoot.MoveIn, 0, 1, 0, 1)
  local RemainTime = 0
  local nSecond = 10
  self:AddTimer(0, function()
    while RemainTime < nSecond do
      self.UIRoot.ProgressBar_Time:SetPercent(RemainTime / nSecond)
      RemainTime = RemainTime + 0.033
      coroutine.yield(0.033)
    end
    self:ClosePop()
  end)
  local data = self:GetRecordData()
  if not data then
    return
  end
  local scoreKey = 40002020
  local hunterIcon = 40002021
  local huntedIcon = 40002022
  local changeKey = 40002023
  local index = data.score_data[history_combat_cfg.EHvHCampType.Hunter] ~= nil and 1 or 0
  if data.count == 1 then
    local history_combat_util = require("client.logic.combat.history.history_combat_util")
    local state_str = history_combat_util.GetHvHSettlementStr(data.person_state)
    self.UIRoot.TextBlock_Title:SetText(LocUtil.LocalizeResFormat(4002088, state_str))
    local get_score = data.score_data[data.camp_type]
    local ratingStr = 0 <= get_score.change_rating and tostring("+" .. get_score.change_rating) or tostring(get_score.change_rating)
    local scoreStr = LocUtil.LocalizeResFormat(changeKey, get_score.rating, ratingStr)
    if data.camp_type == history_combat_cfg.EHvHCampType.Hunter then
      local iconScoreStr = LocUtil.LocalizeResFormat(hunterIcon, scoreStr)
      self.UIRoot.TextBlock_ScoreText:SetText(LocUtil.LocalizeResFormat(scoreKey, iconScoreStr))
    else
      local iconScoreStr = LocUtil.LocalizeResFormat(huntedIcon, scoreStr)
      self.UIRoot.TextBlock_ScoreText:SetText(LocUtil.LocalizeResFormat(scoreKey, iconScoreStr))
    end
  elseif data.type_count == 1 then
    self.UIRoot.TextBlock_Title:SetText(LocUtil.LocalizeResFormat(4002090, data.count))
    local get_score = data.score_data[data.camp_type]
    local ratingStr = 0 <= get_score.change_rating and tostring("+" .. get_score.change_rating) or tostring(get_score.change_rating)
    local scoreStr = LocUtil.LocalizeResFormat(changeKey, get_score.rating, ratingStr)
    if data.camp_type == history_combat_cfg.EHvHCampType.Hunter then
      local iconScoreStr = LocUtil.LocalizeResFormat(hunterIcon, scoreStr)
      self.UIRoot.TextBlock_ScoreText:SetText(LocUtil.LocalizeResFormat(scoreKey, iconScoreStr))
    else
      local iconScoreStr = LocUtil.LocalizeResFormat(huntedIcon, scoreStr)
      self.UIRoot.TextBlock_ScoreText:SetText(LocUtil.LocalizeResFormat(scoreKey, iconScoreStr))
    end
  else
    index = 2
    self.UIRoot.TextBlock_Title:SetText(LocUtil.LocalizeResFormat(4002090, data.count))
    local iconScoreStr = ""
    for key, get_score in pairs(data.score_data) do
      local ratingStr = get_score.change_rating and (0 <= get_score.change_rating and tostring("+" .. get_score.change_rating) or tostring(get_score.change_rating)) or "+0"
      local scoreStr = LocUtil.LocalizeResFormat(changeKey, get_score.rating, ratingStr)
      if key == history_combat_cfg.EHvHCampType.Hunter then
        iconScoreStr = iconScoreStr .. LocUtil.LocalizeResFormat(hunterIcon, scoreStr)
      else
        iconScoreStr = iconScoreStr .. LocUtil.LocalizeResFormat(huntedIcon, scoreStr)
      end
    end
    self.UIRoot.TextBlock_ScoreText:SetText(LocUtil.LocalizeResFormat(scoreKey, iconScoreStr))
  end
  self.UIRoot.WidgetSwitcher_0:SetActiveWidgetIndex(index)
  local logic_history_combat = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_history_combat)
  logic_history_combat:ClearHunterVsHuntedRecord()
end
function Butcher_Settlement_Popup_UIBP:GetRecordData()
  local camp_data = {
    count = #self.data,
    type_count = nil,
    camp_type = nil,
    rank = nil,
    person_state = self.data[1].person_state or 0,
    score_data = {}
  }
  if #self.data == 0 then
    return nil
  elseif #self.data == 1 then
    local value = self.data[1]
    local getValue = self:GetOneData(value)
    camp_data.score_data[getValue.camp_type] = {
      change_rating = getValue.change_rating,
      rating = getValue.current_rating
    }
    camp_data.type_count = 1
    camp_data.camp_type = getValue.camp_type
    camp_data.rank = getValue.rank
    return camp_data
  else
    for key, value in pairs(self.data) do
      local getValue = self:GetOneData(value)
      local index = getValue.camp_type
      if not camp_data.score_data[index] then
        camp_data.score_data[index] = {
          change_rating = getValue.change_rating,
          rating = getValue.current_rating,
          lastTime = getValue.lastTime
        }
      else
        camp_data.score_data[index].change_rating = camp_data.score_data[index].change_rating + getValue.change_rating
        if camp_data.score_data[index].lastTime < getValue.lastTime then
          camp_data.score_data[index].rating = getValue.current_rating
          camp_data.score_data[index].lastTime = getValue.lastTime
        end
      end
    end
  end
  camp_data.type_count = 0
  for key, value in pairs(camp_data.score_data) do
    camp_data.type_count = camp_data.type_count + 1
  end
  if camp_data.type_count == 1 then
    camp_data.camp_type = next(camp_data.score_data)
  else
    camp_data.camp_type = nil
  end
  return camp_data
end
function Butcher_Settlement_Popup_UIBP:OnClickButton_Close()
  self:PlayAudio(sound_config.click_v1)
  self:ClosePop()
end
function Butcher_Settlement_Popup_UIBP:OnClickButton_Jump()
  self:PlayAudio(sound_config.click)
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  local extraData = {}
  if RoleInfoMainSystem.Show(RoleInfoMainSystem.HistoryCombat, RoleInfoMainSystem.RoleInfoOpenFromType.HunterVsHunted_Pop, DataMgr.roleData.uid, extraData) then
    self:ClosePop()
  end
end
function Butcher_Settlement_Popup_UIBP:OnAnimationEnd()
  log(bWriteLog and "Butcher_Settlement_Popup_UIBP:OnAnimationEnd")
  self:AddTimerOnce(0, function()
    self:CloseSelf()
  end)
end
function Butcher_Settlement_Popup_UIBP:ClosePop()
  self:PlayUserWidgetAnimation(self.UIRoot.MoveOut, 0, 1, 0, 1)
end
function Butcher_Settlement_Popup_UIBP:UpdateUI()
  log(bWriteLog and "Butcher_Settlement_Popup_UIBP:UpdateUI")
  self:SetTexture(self.UIRoot.Image_Go, "/Game/UMG/Texture_200/Atlas/Common_New_Atlas/Frames/Common_Btn_Huangse_png.Common_Btn_Huangse_png")
  self.UIRoot.TextBlock_Desc:SetText(LocUtil.LocalizeResFormat(4002092))
end
function Butcher_Settlement_Popup_UIBP:GetOneData(data)
  local result = {
    camp_type = data.camp_type or history_combat_cfg.EHvHCampType.Hunter,
    change_rating = data.change_rating_num or 0,
    current_rating = data.rating,
    lastTime = data.timestamp,
    rank = data.person_rank
  }
  return result
end
function Butcher_Settlement_Popup_UIBP:GetSwitchPosWidget()
  return self.UIRoot.Border_Side
end
local class = require("class")
local ui_base = require("client.slua_ui_framework.base")
return class(ui_base, nil, Butcher_Settlement_Popup_UIBP)
