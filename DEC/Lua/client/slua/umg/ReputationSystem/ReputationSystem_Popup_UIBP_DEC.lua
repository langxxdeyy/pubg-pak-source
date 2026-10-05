local ReputationSystem_Popup_UIBP = {}
function ReputationSystem_Popup_UIBP:ctor()
end
function ReputationSystem_Popup_UIBP:OnInitialize()
  ReputationSystem_Popup_UIBP.__super.OnInitialize(self)
  self.Common_Popup_Large_UIBP = self:InitCommonPopup(self.UIRoot.Common_Popup_Large_UIBP)
end
function ReputationSystem_Popup_UIBP:RegistEvents()
  ReputationSystem_Popup_UIBP.__super.RegistEvents(self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_OK, self.OnButton_OKClick, self)
  self:AddControlEventByControl(self.UIRoot.CustomScrollBox_0, "OnUserScrolled", self.OnUserScrolled, self)
  self:AddCommonEvent(EVENTTYPE_REPUTATION, EVENTID_REPUTATION_GET_PARAM_TAB, self.ShowDescTable, self)
end
function ReputationSystem_Popup_UIBP:OnPostInitialize()
  ReputationSystem_Popup_UIBP.__super.OnPostInitialize(self)
  self:InitUI()
  local logic_reputation_system = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_reputation_system)
  logic_reputation_system:RequestParamTab()
end
function ReputationSystem_Popup_UIBP:InitUI()
  self.Common_Popup_Large_UIBP:SetData(self, LocUtil.GetLocalizeResStr(29651), {showCloseBtn = false})
  self.UIRoot.UTRichText_Content:SetText(LocUtil.GetLocalizeResStr(29654))
  self.UIRoot.Text_OK:SetText(LocUtil.GetLocalizeResStr(29653))
  self.UIRoot.TextBlock_Note:SetText(LocUtil.GetLocalizeResStr(29667))
  self.UIRoot.ReputationSystem_Popup_Item_3:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  self.UIRoot.TextBlock_ActionTitle:SetText(LocUtil.GetLocalizeResStr(29645))
  self.UIRoot.ReputationSystem_Popup_Item.TextBlock_TitleDesc:SetText(LocUtil.GetLocalizeResStr(29647))
  self.UIRoot.ReputationSystem_Popup_Item.TextBlock_Action:SetText(LocUtil.GetLocalizeResStr(29648))
  self.UIRoot.ReputationSystem_Popup_Item.TextBlock_Desc:SetText(LocUtil.GetLocalizeResStr(29649))
  self.UIRoot.ReputationSystem_Popup_Item.TextBlock_Rules:SetText(LocUtil.GetLocalizeResStr(29650))
  self.UIRoot.TextBlock_CreditTitle:SetText(LocUtil.GetLocalizeResStr(29631))
  self.UIRoot.ReputationSystem_Popup_Item_3.TextBlock_Score:SetText(LocUtil.GetLocalizeResStr(29646))
  self.UIRoot.ReputationSystem_Popup_Item_3.TextBlock_Desc:SetText(LocUtil.GetLocalizeResStr(29631))
  self:ShowRulesTable()
end
function ReputationSystem_Popup_UIBP:ShowRulesTable()
  local CreditRulesTable = CDataTable.GetTable("CreditRulesTable") or {}
  local lastLine
  for k, v in pairs(CreditRulesTable) do
    self.UIRoot.ReputationSystem_Popup_Item["ReputationSystem_Popup_Item_" .. k].TextBlock_Action:SetText(v.Action)
    self.UIRoot.ReputationSystem_Popup_Item["ReputationSystem_Popup_Item_" .. k].TextBlock_Desc:SetText(v.ActionDesc)
    self.UIRoot.ReputationSystem_Popup_Item["ReputationSystem_Popup_Item_" .. k].TextBlock_Rules:SetText(v.Rules)
    lastLine = k
  end
  if lastLine then
    self.UIRoot.ReputationSystem_Popup_Item["ReputationSystem_Popup_Item_" .. lastLine].Image_Line:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  end
end
function ReputationSystem_Popup_UIBP:OnUserScrolled(currentOffset)
  local endOffset = self.UIRoot.CustomScrollBox_0:GetMaxScrollOffset()
  local bShowArrow = currentOffset <= endOffset - 2
  self:SetWidgetVisible(self.UIRoot.Image_Arrow, bShowArrow, false)
end
function ReputationSystem_Popup_UIBP:ShowDescTable()
  local logic_reputation_system = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_reputation_system)
  local descData = logic_reputation_system:GetDescTable()
  local descDatalength = #descData
  self.UIRoot.ReputationSystem_Popup_Item_3:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
  for k, v in pairs(descData) do
    local minScore = v.FloorScore
    local maxScore = v.CeilingScore
    local showDesc = LocUtil.LocalizeResFormatByStr(v.PopupScoreDesc, 100 - v.ExpRate)
    local showScore
    if minScore == maxScore then
      showScore = tostring(minScore)
    else
      showScore = LocUtil.LocalizeResFormat(29655, minScore, maxScore)
    end
    local widget = self.UIRoot.ReputationSystem_Popup_Item_3["ReputationSystem_Popup_Item_" .. k]
    if 100 <= minScore then
      local addScore = CDataTable.GetTableData("ParamTable", "credit_score_add")
      showDesc = LocUtil.LocalizeResFormatByStr(v.PopupScoreDesc, v.AddCoins, addScore.ParamValue)
      widget.TextBlock_Score:SetColorAndOpacity(FSlateColor(FLinearColor(0.012983, 0.013702, 0.473532, 1)))
    elseif 60 <= minScore then
      widget.TextBlock_Score:SetColorAndOpacity(FSlateColor(FLinearColor(0.693872, 0.14996, 0, 1)))
    else
      widget.TextBlock_Score:SetColorAndOpacity(FSlateColor(FLinearColor(0.584079, 0.003347, 0.027321, 1)))
    end
    widget.TextBlock_Score:SetText(showScore)
    widget.TextBlock_Desc:SetText(showDesc)
    self:SetWidgetVisible(widget.CanvasPanel_Current, false)
  end
  if 0 < descDatalength then
    self.UIRoot.ReputationSystem_Popup_Item_3["ReputationSystem_Popup_Item_" .. tostring(descDatalength)].Image_Line:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  end
end
function ReputationSystem_Popup_UIBP:OnButton_OKClick()
  self:PlayAudio(sound_config.click)
  local logic_reputation_system = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_reputation_system)
  logic_reputation_system:ReportAcceptCreditPack()
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  if RoleInfoMainSystem.Show(RoleInfoMainSystem.Credit, RoleInfoMainSystem.RoleInfoOpenFromType.Null, DataMgr.roleData.uid) then
    self:CloseSelf()
  end
end
local class = require("class")
local ui_base = require("client.slua_ui_framework.base")
local CReputationSystem_Popup_UIBP = class(ui_base, nil, ReputationSystem_Popup_UIBP)
return CReputationSystem_Popup_UIBP
