local ui_chat_share_achievement_show = {}
function ui_chat_share_achievement_show:ctor(selfType, posX, achievement)
  local UIUtil = require("client.common.ui_util")
  local Margin = UIUtil.GetScreenPadding()
  local left = Margin.Left
  self.posX = posX + left
  self.achievement = achievement
end
function ui_chat_share_achievement_show:OnInitialize()
  ui_chat_share_achievement_show.__super.OnInitialize(self)
  local UIUtil = require("client.common.ui_util")
  UIUtil.SetAdaptation(self.UIRoot.CanvasPanel_2)
  self:InitUI()
end
function ui_chat_share_achievement_show:RegistEvents()
  ui_chat_share_achievement_show.__super.RegistEvents(self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Share, self.OnClickDetail, self)
  self:AddOnClickedEventByControl(self.UIRoot.MaskButton, self.OnClickClose, self)
end
function ui_chat_share_achievement_show:OnPostInitialize()
  ui_chat_share_achievement_show.__super.OnPostInitialize(self)
end
function ui_chat_share_achievement_show:InitUI()
  self.UIRoot.CanvasPanel_0.Slot:SetPosition(FVector2D(self.posX, 0))
  self.UIRoot.TextBlock_Title:SetText(self.achievement.title)
  local achievement_cfg_tool = require("client.slua.logic.achievement.achievement_cfg_tool")
  local info = achievement_cfg_tool.GetAchiveInfo(self.achievement.id)
  local des = info.des
  local StringUtil = require("common.string_util")
  local len = 0
  des, len = StringUtil.cut_utf8_blen(des, 67)
  if 67 < len then
    des = des .. "..."
  end
  self.UIRoot.TextBlock_Des:SetText(des)
  self.UIRoot.TextBlock_Score:SetText(self.achievement.score)
  self.UIRoot.UTRichTextBlock_0:SetText(LocUtil.LocalizeResFormat(5054, self.achievement.owner_player_name, self.achievement.finish_time, "AA"))
  self.UIRoot.TextBlock_CurProcess:SetText("")
  self.UIRoot.AchievementItem256_UIBP:SetData(self.achievement.group_id, self.achievement.group_num, self.achievement.big_img_url)
  local cfg = CDataTable.GetTableData("AchievementCfg", self.achievement.id)
  local AchType = cfg.AchType
  if AchType == 1 then
    self.UIRoot.WidgetSwitcher_1:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    self.UIRoot.WidgetSwitcher_1:SetActiveWidgetIndex(0)
  elseif AchType == 2 then
    self.UIRoot.WidgetSwitcher_1:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    self.UIRoot.WidgetSwitcher_1:SetActiveWidgetIndex(1)
  else
    self.UIRoot.WidgetSwitcher_1:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  end
end
function ui_chat_share_achievement_show:OnClickDetail()
  self:PlayAudio(sound_config.click)
  local id = self.achievement.id
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  local index = RoleInfoMainSystem.Honor
  local openFrom = RoleInfoMainSystem.RoleInfoOpenFromType.Lobby
  local uid = DataMgr.roleData.uid
  if RoleInfoMainSystem.Show(index, openFrom, uid, {
    achieveInfo = {AchID = id}
  }) then
    local logic_chat_main = require("client.slua.logic.lobby_chat.logic_chat_main")
    logic_chat_main.CloseChatWin()
    logic_chat_main.beCloseFromOther = false
    self:CloseSelf()
  end
end
function ui_chat_share_achievement_show:OnClickClose()
  self:PlayAudio(sound_config.click)
  self:CloseSelf()
end
function ui_chat_share_achievement_show:GetDesc(desc)
  local res = ""
  local delTable = {}
  local indexi = 0
  local indexj = 0
  for i = 1, #desc do
    local ch = string.sub(desc, i, i)
    if ch == "<" then
      indexi = i
    elseif ch == ">" and indexi ~= 0 then
      indexj = i
      table.insert(delTable, indexi)
      table.insert(delTable, indexj)
      indexi = 0
      indexj = 0
    end
  end
  local j = 0
  for i, v in pairs(delTable) do
    if i % 2 == 1 then
      res = res .. string.sub(desc, j, v - 1)
    else
      j = v + 1
    end
  end
  res = res .. string.sub(desc, j, #desc)
  return res
end
local class = require("class")
local ui_base = require("client.slua_ui_framework.base")
local CUIChatShareAchievement = class(ui_base, nil, ui_chat_share_achievement_show)
return CUIChatShareAchievement
