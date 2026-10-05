local UI_UGC_Mine_Photo_Album_Details_Select = {}
function UI_UGC_Mine_Photo_Album_Details_Select:ctor(_, slot, setting)
  self.slot = slot or nil
  self.setting = setting or {}
  self.bIsInGame = false
end
function UI_UGC_Mine_Photo_Album_Details_Select:OnInitialize()
  UI_UGC_Mine_Photo_Album_Details_Select.__super.OnInitialize(self)
  self.LoopScrollGrid_Photo = self:InitChildClassScrollBox(self.UIRoot.LoopScrollGrid_Photo, "client.slua.umg.ugc.creator.personal.UgcMinePhotoPictureItemNew")
  if not slua.isValid(CGameState) or IsWoWEditor or not CGameState:IsCreativeMode() then
    self:SetWidgetVisible(self.UIRoot.Button_0, false)
  end
end
function UI_UGC_Mine_Photo_Album_Details_Select:RegistEvents()
  UI_UGC_Mine_Photo_Album_Details_Select.__super.RegistEvents(self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Close, self.OnButtonCloseClicked, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_0, self.OnClickGotoPhoto, self)
  self:AddCommonEvent(EVENTTYPE_UGC, EVENTID_UGC_ADDCOVER, self.OnSelectPhoto, self)
  self:AddCommonEvent(EVENTTYPE_UGC, EVENTID_UGC_SELECTPHOTO, self.OnSelectPhoto, self)
end
function UI_UGC_Mine_Photo_Album_Details_Select:OnPostInitialize()
  UI_UGC_Mine_Photo_Album_Details_Select.__super.OnPostInitialize(self)
  EventSystem:postEvent(EVENTTYPE_NEWBIE_GUIDE, EVENTID_NEWBIE_UI_OPEN, "UI_UGC_Mine_Photo_Album_Details_Select")
end
function UI_UGC_Mine_Photo_Album_Details_Select:OnShow()
  self:InitPanel()
  self.LoopScrollGrid_Photo:ScrollToItem(1)
end
function UI_UGC_Mine_Photo_Album_Details_Select:InitPanel()
  self:SetWidgetVisible(self.UIRoot.SizeBox_1, false)
  self:SetWidgetVisible(self.UIRoot.HorizontalBox_Bottom, false)
  self:SetWidgetVisible(self.UIRoot.AutoScrollBox_5, false)
  self.UIRoot.TextBlock_Time:SetText("")
  self.UIRoot.UTRichTextBlock_Num:SetText("")
  self.UIRoot.TextBlock_Title:SetText(self.setting and self.setting.name or "")
  self.UIRoot.TextBlock_Page_Title:SetText(LocUtil.GetLocalizeResStr(4303051))
  self.UIRoot.TextBlock_0:SetText(LocUtil.GetLocalizeResStr(89944))
  self:SetWidgetVisible(self.UIRoot.TextBlock_Limt, false)
  self:SetWidgetVisible(self.UIRoot.CanvasPanel_Tips, false)
  local pictureInfo = {}
  local album = self.setting.album or {}
  for i = 1, #album do
    local isViewPicture = false
    local pics = self.setting.view_pic_list or {}
    for _, picIndex in ipairs(pics) do
      if i == picIndex then
        isViewPicture = true
      end
    end
    pictureInfo[i] = {
      slot = self.slot,
      index = i,
      isViewPicture = isViewPicture,
      isThumb = self.setting.thumb_index == i,
      urlInfo = album[i],
      isSelectMode = true,
      isInGame = self.bIsInGame
    }
  end
  table.sort(pictureInfo, function(a, b)
    local nWeight_A = a.isThumb and 3 or a.isViewPicture and 2 or 1
    local nWeight_B = b.isThumb and 3 or b.isViewPicture and 2 or 1
    if nWeight_A ~= nWeight_B then
      return nWeight_A > nWeight_B
    end
  end)
  if pictureInfo and #pictureInfo ~= 0 then
    self.LoopScrollGrid_Photo:SetData(pictureInfo)
    self.UIRoot.WidgetSwitcher_State:SetActiveWidgetIndex(0)
  else
    self.UIRoot.TextBlock_None:SetText(LocUtil.GetLocalizeResStr(4600267))
    self.UIRoot.WidgetSwitcher_State:SetActiveWidgetIndex(1)
  end
end
function UI_UGC_Mine_Photo_Album_Details_Select:ForceShowEmpty()
  self.UIRoot.TextBlock_None:SetText(LocUtil.GetLocalizeResStr(4600267))
  self.UIRoot.WidgetSwitcher_State:SetActiveWidgetIndex(1)
end
function UI_UGC_Mine_Photo_Album_Details_Select:OnButtonCloseClicked()
  self:PlayAudio(sound_config.close_v1)
  self:CloseSelf()
end
function UI_UGC_Mine_Photo_Album_Details_Select:OnClickGotoPhoto()
  self:PlayAudio(sound_config.close_v1)
  self:CloseSelf()
  local SettingUI = UIManager.GetUI(UIManager.UI_Config_InGame.CreativeModeSettingMainUI)
  if SettingUI then
    SettingUI:Hide()
  end
  local CreativeModeEditBuildSubSystem = SubsystemMgr:Get("CreativeModeEditBuildSubSystem")
  local bIsFreeViewMode = CreativeModeEditBuildSubSystem and CreativeModeEditBuildSubSystem:IsFreeViewMode()
  local IngameSelfieSubsystem = SubsystemMgr:Get("CreativeModeIngameSelfieSubsystem")
  if IngameSelfieSubsystem then
    if not bIsFreeViewMode then
      IngameSelfieSubsystem:EnterSelfie()
    else
      IngameSelfieSubsystem:StartCameraScreenShot()
    end
  end
end
function UI_UGC_Mine_Photo_Album_Details_Select:OnSelectPhoto(_, _, slot, index)
  self:CloseSelf()
end
function UI_UGC_Mine_Photo_Album_Details_Select:GetDataForJumpBack()
  return {
    ctorData = {
      [1] = self.slot
    }
  }
end
local class = require("class")
local ui_base = require("client.slua_ui_framework.base")
return class(ui_base, nil, UI_UGC_Mine_Photo_Album_Details_Select)
