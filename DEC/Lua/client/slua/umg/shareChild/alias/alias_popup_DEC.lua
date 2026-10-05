local SelfHitTestInvisible = UEnums.ESlateVisibility.SelfHitTestInvisible
local Collapsed = UEnums.ESlateVisibility.Collapsed
local RoleInfoAliasSystem = require("client.slua.logic.roleInfo.logic_roleinfo_title")
local PufferTlog = require("client.slua.logic.download.report.puffer_tlog")
local Alias_Popup_UI = {}
function Alias_Popup_UI:ctor(_, aliasData)
  local TableUtil = require("common.table_util")
  self.aliasData = TableUtil.CopyTable(aliasData)
end
function Alias_Popup_UI:OnConstruct()
  self:UpdateUI()
end
function Alias_Popup_UI:OnInitialize()
  Alias_Popup_UI.__super.OnInitialize(self)
  local UIUtil = require("client.common.ui_util")
  UIUtil.SetAdaptation(self.UIRoot.CanvasPanel_0)
end
function Alias_Popup_UI:RegistEvents()
  Alias_Popup_UI.__super.RegistEvents(self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_CloseUI, self.OnClickClose, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Share, self.OnClickShare, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Go, self.OnClickGo, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Moment, self.OnClickMoment, self)
end
function Alias_Popup_UI:OnPostInitialize()
  Alias_Popup_UI.__super.OnPostInitialize(self)
  self:UpdateUI()
end
function Alias_Popup_UI:OnClickGo()
  self:PlayAudio(sound_config.click_v1)
  if not self.aliasData then
    return
  end
  if UIManager.IsUIShow(UIManager.UI_Config.unknowpass_rank_first_week_awards) then
    UIManager.CloseUI(UIManager.UI_Config.unknowpass_rank_first_week_awards)
  end
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  local PersonalizationConst = require("client.slua.umg.roleInfoNew.PersonalizationConst")
  if RoleInfoMainSystem.Show(RoleInfoMainSystem.Personalize, RoleInfoMainSystem.RoleInfoOpenFromType.Null, DataMgr.roleData.uid, {
    personalInfo = {
      openTab = PersonalizationConst.ENUM_Type.Alias,
      itemID = self.aliasData.aliasId
    }
  }) then
    self:CloseSelf()
  end
end
function Alias_Popup_UI:OnClickShare()
  self:PlayAudio(sound_config.click_v1)
  if self.aliasData then
    RoleInfoAliasSystem.ShowShareAlias(self.aliasId, self.aliasData)
  else
    log(bWriteLog and "  : no AliasData")
  end
  local ShareMgr = require("client.logic.share.share_logic")
  ShareMgr.ShareBtnReq(1, ShareBtnTLogShareTypeDefine.ShareAfterWinningTheTitle, nil, nil)
end
function Alias_Popup_UI:OnClickClose()
  self:PlayAudio(sound_config.close_v1)
  self:CloseSelf()
end
function Alias_Popup_UI:UpdateUI()
  if not self.aliasData then
    return
  end
  self.UIRoot.Text_titleDesc:SetText(self.aliasData.aliasDesc or "")
  self:PlayUserWidgetAnimation(self.UIRoot.GetTitle, 0, 1, 0, 1)
  local sound = "/Game/WwiseEvent/UI_hall/Play_UI_Title_New.Play_UI_Title_New"
  self:PlayAudio(sound)
  local UIUtil = require("client.common.ui_util")
  UIUtil.SetTitleItem(self.UIRoot.TitleItem_Get_UIBP, self.aliasData)
  self:TryDownloadTitleIcon()
  local PublishRegionMacros = require("client.slua.config.ClientMacros.PublishRegionMacros")
  if PublishRegionMacros.IsBlueholeFamily() then
    self.UIRoot.TextBlock_Logo:SetText(LocUtil.GetLocalizeResStr(200021))
  end
  self:SetWidgetVisible(self.UIRoot.Moment_Panel, LobbySystem.CheckOpen(BP_ENUM_MOMENT_SWITCH))
end
function Alias_Popup_UI:TryDownloadTitleIcon()
  if not self.aliasData then
    return
  end
  local pak_util = require("client.common.pak_util")
  local iconPathList = {}
  local iconUrl = self.aliasData.aliasIconUrl
  local iconUrlBig = self.aliasData.aliasIconUrlBig
  if iconUrl and iconUrl ~= "" and not pak_util.IsPufferDownloaded(iconUrl) then
    table.insert(iconPathList, iconUrl)
  end
  if iconUrlBig and iconUrlBig ~= "" and not pak_util.IsPufferDownloaded(iconUrlBig) then
    table.insert(iconPathList, iconUrlBig)
  end
  if #iconPathList <= 0 then
    return
  end
  log(bWriteLog and "[Alias_Popup_UI:TryDownloadTitleIcon] download title icons, count = " .. tostring(#iconPathList))
  local PufferManager = require("client.slua.logic.download.puffer.puffer_manager")
  local PufferConst = require("client.slua.logic.download.puffer_const")
  local extraData = {bFirst = true, bAutoDownload = true}
  local weakSelf = self
  PufferManager.Download(PufferConst.ENUM_DownloadType.ODPAK, iconPathList, PufferTlog.Enum_TLog_From.Avatar, function()
    if not (weakSelf and weakSelf.UIRoot) or not slua.isValid(weakSelf.UIRoot.TitleItem_Get_UIBP) then
      return
    end
    if not weakSelf.aliasData then
      return
    end
    local UIUtil = require("client.common.ui_util")
    UIUtil.SetTitleItem(weakSelf.UIRoot.TitleItem_Get_UIBP, weakSelf.aliasData)
  end, extraData)
end
function Alias_Popup_UI:OnClose()
end
function Alias_Popup_UI:OnClickMoment()
  self:PlayAudio(sound_config.click_v1)
  local logic_moment_helper = require("client.slua.logic.moment.logic_moment_helper")
  if not logic_moment_helper.CanReleaseMoment() then
    return
  end
  local widget = self.UIRoot.Button_Panel
  widget:SetWidgetVisibility(Collapsed)
  if self.UIRoot then
    self.UIRoot.Button_CloseUI:SetWidgetVisibility(Collapsed)
    RoleInfoAliasSystem.ShowMomentShareAlias(function()
      widget:SetWidgetVisibility(SelfHitTestInvisible)
      if self.UIRoot then
        self.UIRoot.Button_CloseUI:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
      end
    end)
  end
end
local class = require("class")
local ui_base = require("client.slua_ui_framework.base")
local CAlias_Popup_UI = class(ui_base, nil, Alias_Popup_UI)
return CAlias_Popup_UI
