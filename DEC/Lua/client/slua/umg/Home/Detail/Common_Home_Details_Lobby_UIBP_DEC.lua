local Common_Home_Details_Lobby_UIBP = {}
function Common_Home_Details_Lobby_UIBP:OnInitialize()
  Common_Home_Details_Lobby_UIBP.__super.OnInitialize(self)
  self.Common_Home_Party_Item_UIBP = nil
  if self.UIRoot.Common_UIPopupBG then
    self:SetWidgetVisible(self.UIRoot.Common_UIPopupBG, true)
  end
  if self.UIRoot.Home_Upgrade_Tips_UIBP then
    self:SetWidgetVisible(self.UIRoot.Home_Upgrade_Tips_UIBP, false)
  end
end
function Common_Home_Details_Lobby_UIBP:RegistEvents()
  Common_Home_Details_Lobby_UIBP.__super.RegistEvents(self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_HomeMall, self.OnClickButton_HomeMall, self)
  if self.UIRoot.Button_QR then
    self:AddOnClickedEventByControl(self.UIRoot.Button_QR, self.OnButton_ScanQRClick, self)
  end
end
function Common_Home_Details_Lobby_UIBP:OnClickButton_HomeMall()
  self:PlayAudio(sound_config.click_v1)
  local UIUtil = require("client.common.ui_util")
  if not UIUtil.CanClickNow(UIUtil.ClickFrequencyLimit.PlanPHLobbyClickStore) then
    return
  end
  local PHomeStoreProxy = require("client.slua.logic.homestore.PHomeStoreProxy")
  local PHomeStoreConst = require("client.slua.logic.homestore.PHomeStoreConst")
  PHomeStoreProxy:ShowPHomeMain(PHomeStoreConst.EOpenSceneFrom.Lobby, nil, nil, nil, nil, function()
    self:CloseSelf()
  end)
end
function Common_Home_Details_Lobby_UIBP:OnButton_ScanQRClick()
  self:PlayAudio(sound_config.click_v1)
  local UIUtil = require("client.common.ui_util")
  if not UIUtil.CanClickNow(UIUtil.ClickFrequencyLimit.HomeScanQRClick) then
    return
  end
  self:SetWidgetVisible(self.UIRoot.CanvasPanel_Guide, false)
  local PlayerPrefsSystem = require("client.logic.LogicPlayerPrefs.playerprefs")
  local saveData = {isNew = false}
  PlayerPrefsSystem.SaveTableToFile_N(saveData, PlayerPrefsSystem.ePlayerPrefsType.eHomeQrCodeGuideIsShow)
  local ScanQRCodeCallback = function(resultStr, from)
    if self and self.UIRoot then
      ShowNotice(45950)
      self:SendTLog(from)
      local StringUtil = require("common.string_util")
      local list = StringUtil.Split(resultStr, ",")
      log(bWriteLog and "Common_Home_Details_Lobby_UIBP:ScanQRCodeCallback: resultStr = " .. resultStr)
      if list[2] and list[2] == "home" then
        log(bWriteLog and "Common_Home_Details_Lobby_UIBP:ScanQRCodeCallback:" .. tostring(list[1]))
        local logic_home_download = require("client.slua.logic.home.Download.logic_home_download")
        logic_home_download.CheckHomeDownloadedDone(tonumber(list[1]), nil)
      else
        UIManager.ShowUI(UIManager.UI_Config.friend_new_search, resultStr)
      end
    end
  end
  local customFeatureCallback = function()
    local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
    if RoleInfoMainSystem.Show(RoleInfoMainSystem.RoleInfoCard, RoleInfoMainSystem.RoleInfoOpenFromType.QR_Code, DataMgr.roleData.uid) then
      self:CloseSelf()
    end
  end
  local customFeatureCallback2 = function()
    self:ShareMyHome()
  end
  local params = {
    photoSwitch = true,
    customFeatureSwitch = true,
    customFeatureCallback = customFeatureCallback,
    scanSuccessCallback = ScanQRCodeCallback,
    customFeatureSwitch2 = true,
    customFeatureCallback2 = customFeatureCallback2,
    bReceiveStr = true,
    describeID = 68186,
    customFeatureIcon = "/Game/UMG/Texture_200/Atlas/Common_New_Atlas/Frames/Common_Icon_NameCard_png.Common_Icon_NameCard_png"
  }
  local logic_qr_code = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_qr_code)
  logic_qr_code:ShowQRCodeUIWithPermission(params)
  self:ReportShareClickTlog()
end
function Common_Home_Details_Lobby_UIBP:ReportShareClickTlog()
  local tlog_report_utils = require("client.slua.config.tlog.tlog_report_utils")
  tlog_report_utils.ReportTLogEvent(TLogEventDefine.HomeButtonScanClick, 2)
end
function Common_Home_Details_Lobby_UIBP:RefreshUIStyle()
  Common_Home_Details_Lobby_UIBP.__super.RefreshUIStyle(self)
  self:SetWidgetVisible(self.UIRoot.Common_UIPopupBG, true, false)
  self:SetWidgetVisible(self.UIRoot.Button_LeftClose, false, true)
  self:SetWidgetVisible(self.UIRoot.CanvasPanel_Setting1, self.bSelf, false)
  self:SetWidgetVisible(self.UIRoot.CanvasPanel_Share1, self.bSelf, false)
  self:SetWidgetVisible(self.UIRoot.CanvasPanel_QR, true, false)
end
function Common_Home_Details_Lobby_UIBP:RefreshPlanPHInfo()
  Common_Home_Details_Lobby_UIBP.__super.RefreshPlanPHInfo(self)
  self.homeLevel = self.detail.grow_info and self.detail.grow_info.level
  self:RefreshPlanPHMessage()
end
function Common_Home_Details_Lobby_UIBP:RefreshEntryPanel()
  self:SetWidgetVisible(self.UIRoot.CanvasPanel_Entry, true, false)
  self.UIRoot.WidgetSwitcher_Entry:SetActiveWidgetIndex(0)
  if self.bSelf then
    self.UIRoot.TextBlock_Entry:SetText(LocUtil.GetLocalizeResStr(64742))
  else
    self.UIRoot.TextBlock_Entry:SetText(LocUtil.GetLocalizeResStr(64772))
  end
end
function Common_Home_Details_Lobby_UIBP:RefreshGiftBoxEntry()
  self:SetWidgetVisible(self.UIRoot.CanvasPanel_GiftBox, false)
end
function Common_Home_Details_Lobby_UIBP:UpdateDownloadInfo()
  local logic_home_profile = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_home_profile)
  if logic_home_profile:IsSelfNotCreatedHome(self.uid) then
    self.use_items_arr = {
      "map_planph_2"
    }
  end
  Common_Home_Details_Lobby_UIBP.__super.UpdateDownloadInfo(self)
end
local class = require("class")
local Common_Home_Details_UIBP = require("client.slua.umg.Home.Detail.Common_Home_Details_UIBP")
local CCommon_Home_Details_Lobby_UIBP = class(Common_Home_Details_UIBP, nil, Common_Home_Details_Lobby_UIBP)
return CCommon_Home_Details_Lobby_UIBP
