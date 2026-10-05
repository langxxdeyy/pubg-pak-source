local Lobby_RoleInfo_PeakGame_Tips_UIBP = {}
function Lobby_RoleInfo_PeakGame_Tips_UIBP:ctor()
end
function Lobby_RoleInfo_PeakGame_Tips_UIBP:OnInitialize()
end
function Lobby_RoleInfo_PeakGame_Tips_UIBP:RegistEvents()
  self:AddOnClickedEventByControl(self.UIRoot.Button_Close, self.OnClickButton_Close, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_6, self.OnClickButtonShowInfo, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_Award, self.OnClickPlayerLevel, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_0, self.OnClickButtonCreditText, self)
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  local spData = RoleInfoMainSystem.GetSuperData()
  self:AddDataListener(spData, "levelTaskRed", self.OnRefreshLevelAwardReddot, self)
end
function Lobby_RoleInfo_PeakGame_Tips_UIBP:OnPostInitialize()
  self:UpdateUI()
end
function Lobby_RoleInfo_PeakGame_Tips_UIBP:UpdateShowinfoReddot()
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  local spData = RoleInfoMainSystem.GetSuperData()
  self:SetWidgetVisible(self.UIRoot.Image_41, spData.settingRed)
end
function Lobby_RoleInfo_PeakGame_Tips_UIBP:OnClose()
end
function Lobby_RoleInfo_PeakGame_Tips_UIBP:OnClickButtonCreditText()
  if not self:_IsRoleSelf() then
    return
  end
  self:PlayAudio(sound_config.click)
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  local roleinfo_main = UIManager.GetUI(UIManager.UI_Config.roleinfo_main)
  if roleinfo_main then
    log(bWriteLog and "Lobby_RoleInfo_PeakGame_Tips_UIBP:OnClickButtonCreditText" .. tostring(RoleInfoMainSystem.Credit))
    roleinfo_main:SwitchTab(RoleInfoMainSystem.Credit)
  end
  self:CloseSelf()
end
function Lobby_RoleInfo_PeakGame_Tips_UIBP:OnClickButtonShowInfo()
  self:PlayAudio(sound_config.click_v1)
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  if RoleInfoMainSystem.Show(RoleInfoMainSystem.Personalize, RoleInfoMainSystem.RoleInfoOpenFromType.Lobby, RoleInfoSystem.CurShowPlayerInfoUid) then
    self:CloseSelf()
  end
end
function Lobby_RoleInfo_PeakGame_Tips_UIBP:OnClickPlayerLevel()
  local LogicFitVersionDownload = require("client.slua.logic.download.fit.logic_fitVersion_download")
  if LogicFitVersionDownload.IfNotFitLobbyResDownloadedShowWindow() then
    log(bWriteLog and "Lobby_RoleInfo_PeakGame_Tips_UIBP:OnClickPlayerLevel - FitLobbyRes not downloaded, show fit popup")
    return
  end
  local tlog_report_utils = require("client.slua.config.tlog.tlog_report_utils")
  tlog_report_utils.ReportTLogEvent(TLogEventDefine.GrowthTask)
  UIManager.ShowUI(UIManager.UI_Config.Task_LevelBP)
  self:CloseSelf()
end
function Lobby_RoleInfo_PeakGame_Tips_UIBP:OnClickButton_Close()
  self:PlayAudio(sound_config.click_v1)
  self:CloseSelf()
end
function Lobby_RoleInfo_PeakGame_Tips_UIBP:OnRefreshLevelAwardReddot()
  log(bWriteLog and "Lobby_RoleInfo_PeakGame_Tips_UIBP:OnRefreshLevelAwardReddot")
  self:UpdateLevelAwardReddot()
end
function Lobby_RoleInfo_PeakGame_Tips_UIBP:UpdateUI()
  log(bWriteLog and "Lobby_RoleInfo_PeakGame_Tips_UIBP:UpdateUI")
  self:InitUI()
  self:UpdateLevelAwardReddot()
end
function Lobby_RoleInfo_PeakGame_Tips_UIBP:InitUI()
  self.UIRoot.TextBlock_0:SetText(LocUtil.GetLocalizeResStr(68419))
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  local basicInfoData = RoleInfoMainSystem.GetPersonInfo()
  self:SetWidgetVisible(self.UIRoot.CanvasPanel_3, RoleInfoSystem.IsSelf())
  local ZoneSystem = require("client.slua.logic.teamup.logic_zone")
  local zoneID = ZoneSystem.nChooseZoneID
  local bShow = RoleInfoSystem.IsSelf() and tonumber(zoneID) ~= 0
  local logic_multiple_area = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_multiple_area)
  self.UIRoot.TextBlock_Zone:SetText(logic_multiple_area:GetDisplayNameByZoneID(zoneID))
  local LobbySocialSystem = require("client.slua.logic.lobby.Left.logic_lobby_social")
  local uid = RoleInfoSystem.CurShowPlayerInfoUid
  local profile = LobbySocialSystem.GetProfileByUID(uid)
  if profile then
    log(bWriteLog and "Lobby_RoleInfo_PeakGame_Tips_UIBP:InitUI profile 1")
    self:RefreshLevel(profile)
    self:RefreshPVELevel(profile)
  else
    log(bWriteLog and "Lobby_RoleInfo_PeakGame_Tips_UIBP:InitUI profile 2")
    local logic_profile_get_wrap = require("client.slua.logic.user.profile.logic_profile_get_wrap")
    logic_profile_get_wrap.GetNormalProfiles({
      tonumber(uid)
    }, function(list)
      if list and next(list) then
        local profile = list[1]
        self:RefreshLevel(profile)
        self:RefreshPVELevel(profile)
      end
    end, Enum_PROFILE_REPORT_CFG.ROLE_INFO)
  end
  self:SetWidgetVisible(self.UIRoot.TextBlock_6, true)
  self.UIRoot.TextBlock_6:SetText(LocUtil.LocalizeResFormat(68414))
  self:SetWidgetVisible(self.UIRoot.TextBlock_7, true)
  self.UIRoot.TextBlock_7:SetText(LocUtil.GetLocalizeResStr(612))
  self:SetWidgetVisible(self.UIRoot.TextBlock_9, true)
  local gameNum = 0
  if RoleInfoSystem.CareerCombatTotalInfoList[4] and RoleInfoSystem.CareerCombatTotalInfoList[4].role_allmatchnum then
    gameNum = RoleInfoSystem.CareerCombatTotalInfoList[4].role_allmatchnum
  end
  self.UIRoot.TextBlock_9:SetText(gameNum)
  self:SetWidgetVisible(self.UIRoot.TextBlock_10, true)
  self:SetWidgetVisible(self.UIRoot.TextBlock_12, true)
  self:SetWidgetVisible(self.UIRoot.TextBlock_14, true)
  self:SetWidgetVisible(self.UIRoot.TextBlock_16, true)
  self:SetWidgetVisible(self.UIRoot.TextBlock_18, true)
  self.UIRoot.TextBlock_10:SetText(LocUtil.GetLocalizeResStr(613))
  self.UIRoot.TextBlock_12:SetText(LocUtil.GetLocalizeResStr(614))
  self.UIRoot.TextBlock_14:SetText(LocUtil.GetLocalizeResStr(615))
  self.UIRoot.TextBlock_16:SetText(LocUtil.GetLocalizeResStr(29642))
  self.UIRoot.TextBlock_18:SetText(LocUtil.GetLocalizeResStr(608))
  if RoleInfoSystem.CareerCombatTotalInfoList[4] then
    self:SetWidgetVisible(self.UIRoot.TextBlock_11, true)
    self:SetWidgetVisible(self.UIRoot.TextBlock_13, true)
    self:SetWidgetVisible(self.UIRoot.TextBlock_15, true)
    self:SetWidgetVisible(self.UIRoot.TextBlock_19, true)
    self.UIRoot.TextBlock_11:SetText(RoleInfoSystem.CareerCombatTotalInfoList[4].role_winnum or 0)
    self.UIRoot.TextBlock_13:SetText(RoleInfoSystem.CareerCombatTotalInfoList[4].role_toptennum or 0)
    self.UIRoot.TextBlock_15:SetText(RoleInfoSystem.CareerCombatTotalInfoList[4].role_kd_v2 or 0)
    self.UIRoot.TextBlock_19:SetText(RoleInfoSystem.CareerCombatTotalInfoList[4].role_allgamenum or 0)
  end
  self:SetWidgetVisible(self.UIRoot.TextBlock_17, true)
  local roleCredit = basicInfoData.role_credit
  self.UIRoot.TextBlock_17:SetText(tostring(roleCredit) or 0)
  if not RoleInfoSystem.IsSelf() then
    self:SetWidgetVisible(self.UIRoot.Button_6, true, false)
    self:SetWidgetVisible(self.UIRoot.Image_41, false)
  else
    self:UpdateShowinfoReddot()
    self:SetWidgetVisible(self.UIRoot.Button_6, true, true)
  end
end
function Lobby_RoleInfo_PeakGame_Tips_UIBP:DayToYear(day)
  local Month = 31
  local Year = 365
  if day < Year then
    if day > Month * 10 then
      return LocUtil.LocalizeResFormat(656, 11)
    else
      return LocUtil.LocalizeResFormat(656, math.ceil(day / Month))
    end
  else
    return LocUtil.LocalizeResFormat(654, math.floor(day / Year + 0.5))
  end
end
function Lobby_RoleInfo_PeakGame_Tips_UIBP:RefreshPVELevel(profile)
  log(bWriteLog and "Lobby_RoleInfo_PeakGame_Tips_UIBP:RefreshPVELevel")
  self:SetWidgetVisible(self.UIRoot.TextBlock_1, true)
  self:SetWidgetVisible(self.UIRoot.TextBlock_3, true)
  self.UIRoot.TextBlock_1:SetText(LocUtil.LocalizeResFormat(653))
  self.UIRoot.TextBlock_3:SetText(LocUtil.LocalizeResFormat(680, profile.pve_level or 1))
  local PVE_XP = profile.pve_exp or 0
  local percent_pve_exp = 1
  local curPveLevel = tonumber(profile.pve_level) or 1
  local MaxXP = 0
  if 0 < curPveLevel and curPveLevel < 100 then
    local curPveLevelItem = CDataTable.GetTableData("PveLevel", curPveLevel)
    MaxXP = curPveLevelItem.Exp or 0
    percent_pve_exp = (profile.pve_exp or 0) / (curPveLevelItem.Exp or 1)
  end
  local strPveLevel = PVE_XP .. "/" .. MaxXP
  self.UIRoot.TextBlock_4:SetText(strPveLevel)
  self.UIRoot.ProgressBar_1:SetPercent(percent_pve_exp)
  self:SetWidgetVisible(self.UIRoot.TextBlock_4, curPveLevel < 100)
end
function Lobby_RoleInfo_PeakGame_Tips_UIBP:RefreshLevel(profile)
  log(bWriteLog and "Lobby_RoleInfo_PeakGame_Tips_UIBP:RefreshLevel")
  self:SetWidgetVisible(self.UIRoot.CanvasPanel_Title, true, false)
  if self._IsRoleSelf() then
    self:SetWidgetVisible(self.UIRoot.Button_Award, true, true)
  else
    self:SetWidgetVisible(self.UIRoot.Button_Award, false, true)
  end
  self:SetWidgetVisible(self.UIRoot.TextBlock_Title, true)
  self:SetWidgetVisible(self.UIRoot.TextBlock_Level, true)
  self:SetWidgetVisible(self.UIRoot.TextBlock_2, true)
  self.UIRoot.TextBlock_Title:SetText(LocUtil.GetLocalizeResStr(600))
  self.UIRoot.TextBlock_Award:SetText(LocUtil.GetLocalizeResStr(4328))
  local curlevel = tonumber(profile.level)
  self.UIRoot.TextBlock_Level:SetText(curlevel)
  local percent_exp = 1
  if 0 < curlevel and curlevel < 100 then
    local CorpsMgr = require("client.slua.logic.corps.corps_mgr")
    local Exp = CorpsMgr.GetLevelExp(curlevel)
    percent_exp = profile.exp / Exp
    local strLevel = profile.exp .. "/" .. Exp
    self.UIRoot.TextBlock_2:SetText(strLevel)
  end
  self.UIRoot.ProgressBar_0:SetPercent(percent_exp)
  self:SetWidgetVisible(self.UIRoot.TextBlock_2, curlevel < 100)
end
function Lobby_RoleInfo_PeakGame_Tips_UIBP:UpdateLevelAwardReddot()
  log(bWriteLog and "Lobby_RoleInfo_PeakGame_Tips_UIBP:UpdateLevelAwardReddot")
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  local spData = RoleInfoMainSystem.GetSuperData()
  local levelTaskRed = spData.levelTaskRed
  log(bWriteLog and "Lobby_RoleInfo_PeakGame_Tips_UIBP:UpdateLevelAwardReddot levelTaskRed = " .. tostring(levelTaskRed))
  local level_unlock_util = require("client.logic.level_unlock.util.level_unlock_util")
  local bHaveLockedFeature = level_unlock_util:HaveLockedFeature()
  log(bWriteLog and "Lobby_RoleInfo_PeakGame_Tips_UIBP:UpdateLevelAwardReddot bHaveLockedFeature = " .. tostring(bHaveLockedFeature))
  if bHaveLockedFeature then
    self:SetWidgetVisible(self.UIRoot.Reddot_Anchor_Item_level, false, false)
  else
    self:SetWidgetVisible(self.UIRoot.Reddot_Anchor_Item_level, levelTaskRed, false)
  end
end
function Lobby_RoleInfo_PeakGame_Tips_UIBP:_IsRoleSelf()
  local RoleInfoSystem = require("client.logic.roleinfo.logic_roleinfo")
  local curRoleId = RoleInfoSystem.CurShowPlayerInfoUid
  return curRoleId == DataMgr.roleData.uid
end
local class = require("class")
local ui_base = require("client.slua_ui_framework.base")
local CLobby_RoleInfo_PeakGame_Tips_UIBP = class(ui_base, nil, Lobby_RoleInfo_PeakGame_Tips_UIBP)
return CLobby_RoleInfo_PeakGame_Tips_UIBP
