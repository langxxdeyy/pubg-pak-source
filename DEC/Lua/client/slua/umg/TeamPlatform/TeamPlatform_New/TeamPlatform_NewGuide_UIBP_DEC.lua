local TeamPlatform_NewGuide_UIBP = {}
function TeamPlatform_NewGuide_UIBP:ctor(_, click_callback, AlignWidget)
  self.AlignWidget = AlignWidget
  self.click_callback = click_callback
end
function TeamPlatform_NewGuide_UIBP:OnInitialize()
end
function TeamPlatform_NewGuide_UIBP:RegistEvents()
  self:AddOnClickedEventByControl(self.UIRoot.Button_Guide1, self.OnClickButton_Guide1, self)
  self:AddCommonEvent(EVENTTYPE_SETTING, EVENTID_VIEWPORT_SIZE_CHANGED, self.OnScreenRatioChanged, self)
end
function TeamPlatform_NewGuide_UIBP:OnScreenRatioChanged()
  log(bWriteLog and "TeamPlatform_NewGuide_UIBP:OnScreenRatioChanged")
  self:AddTimerOnce(0.1, function()
    self:UpdatePosition(-25, 0)
  end)
end
function TeamPlatform_NewGuide_UIBP:UpdatePosition(offsetX, offsetY)
  log(bWriteLog and "TeamPlatform_NewGuide_UIBP:UpdatePosition")
  local logic_teammate_info = require("client.slua.umg.MainCity.Lobby_Friend.logic_teammate_info")
  logic_teammate_info.AdjustUIBySetAnchorAndPosition(self.AlignWidget, self.UIRoot.CanvasPanel_Guide2, offsetX, offsetY)
end
function TeamPlatform_NewGuide_UIBP:OnPostInitialize()
  log(bWriteLog and "TeamPlatform_NewGuide_UIBP:OnPostInitialize")
  local logic_newbie_team_recommend = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_newbie_team_recommend)
  logic_newbie_team_recommend:ClearTeamPlatformGuide()
  self:UpdateUI()
end
function TeamPlatform_NewGuide_UIBP:OnClose()
  log(bWriteLog and "TeamPlatform_NewGuide_UIBP:OnClose")
  self.AlignWidget = nil
end
function TeamPlatform_NewGuide_UIBP:OnClickButton_Guide1()
  log(bWriteLog and "TeamPlatform_NewGuide_UIBP:OnClickButton_Guide1")
  self:PlayAudio(sound_config.click_v1)
  if self.click_callback then
    self.click_callback()
  end
  self:CloseSelf()
end
function TeamPlatform_NewGuide_UIBP:UpdateUI()
  log(bWriteLog and "TeamPlatform_NewGuide_UIBP:UpdateUI")
  self:AddTimerOnce(0.1, function()
    self:UpdatePosition(-25, 0)
  end)
  self.UIRoot.TextBlock_Guide2:SetText(LocUtil.GetLocalizeResStr(75483))
end
local class = require("class")
local ui_base = require("client.slua_ui_framework.base")
return class(ui_base, nil, TeamPlatform_NewGuide_UIBP)
