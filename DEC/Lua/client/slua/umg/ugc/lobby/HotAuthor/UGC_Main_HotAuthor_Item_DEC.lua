local UGC_Main_HotAuthor_Item = {}
local Config_UGC = require("client.slua.logic.ugc.config_ugc")
function UGC_Main_HotAuthor_Item:ctor()
  self._LastScrollOffset = -1
  self.openSourceType = nil
  self.data = nil
  self.IsOpen = false
end
function UGC_Main_HotAuthor_Item:OnInitialize()
  UGC_Main_HotAuthor_Item.__super.OnInitialize(self)
  self.ModWidgetList = self:InitChildClassScrollBox(self.UIRoot.LoopScrollBox_ModList, "client.slua.umg.ugc.lobby.HotAuthor.UGC_HotAuthor_Mod_Item")
end
function UGC_Main_HotAuthor_Item:RegistEvents()
  self:AddControlEventByControl(self.UIRoot.Common_Avatar_BP, "OnClickItemCallback", self.OnAvatarClick, self)
  self:AddControlEventByControl(self.UIRoot.Button_ShowAll, "OnClicked", self.OnClickButtonShowAll, self)
end
function UGC_Main_HotAuthor_Item:OnRefresh(data)
  self.data = data
  self:UpdateAuthor()
  self:UpdateModScrollBox()
  if self.data and self.data.Open and not self.IsOpen then
    self.IsOpen = true
    self:OnClickButtonShowAll()
    EventSystem:postEvent(EVENTTYPE_UGC, EVENTID_UGC_HOTAUTHOR_DETIAL_JUMP)
  end
end
function UGC_Main_HotAuthor_Item:OnClickButtonShowAll()
  self:PlayAudio(sound_config.click_v1)
  local Logic_UGC_TLog = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.Logic_UGC_TLog)
  Logic_UGC_TLog:SetSelectedThemeId(self.data.themeId)
  UIManager.ShowUI(UIManager.UI_Config.UGC_AuthorRecommended_DetailsPage_UIBP, self.data)
end
function UGC_Main_HotAuthor_Item:UpdateAuthor()
  if self.data.author_uid then
    local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
    local author = logic_profile:GetLocalProfile(self.data.author_uid)
    if not author then
      local logic_profile_get_wrap = require("client.slua.logic.user.profile.logic_profile_get_wrap")
      logic_profile_get_wrap.GetNormalProfiles({
        self.data.author_uid
      }, function(profileList)
        if not self.UIRoot then
          return
        end
        self:UpdataProfile(profileList)
      end, Enum_PROFILE_REPORT_CFG.UGC)
    else
      self:UpdataProfile({author})
    end
  end
end
function UGC_Main_HotAuthor_Item:UpdataProfile(profileList)
  for i, profile in pairs(profileList) do
    self.UIRoot.TextBlock_AuthorName:SetText(profile.nickName)
    self.UIRoot.Common_Avatar_BP:InitView(1, profile.uid, profile.picUrl, nil, profile.cur_avatar_box_id, nil)
    self:SetWOWpassImage(profile)
    local authorLevelConfig
    if profile.ugc_author_info then
      authorLevelConfig = Config_UGC.GetAuthorLevelConfigByID(profile.ugc_author_info.new_level or profile.ugc_author_info.level)
    end
    if authorLevelConfig then
      log(bWriteLog and "UGC_NewMapMod_Author_Item_UIBP:SetAuthorInfo authorLevelConfig.Name = " .. tostring(authorLevelConfig.Name))
      self.UIRoot.CanvasPanel_19:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
      do
        local text = authorLevelConfig.Name
        self.UIRoot.TextBlock_Description:SetText(text)
        self:SetTexture(self.UIRoot.Image_Lv, authorLevelConfig.PageIcon)
      end
      break
    end
    self.UIRoot.CanvasPanel_19:SetWidgetVisibility(UEnums.ESlateVisibility.Hidden)
    break
  end
end
function UGC_Main_HotAuthor_Item:SetWOWpassImage(profile)
  if not self.UIRoot.SizeBox_WoWPass and not self.UIRoot.Image_WoWPass then
    return
  end
  local IconPath
  if profile.uid == tonumber(DataMgr.roleData.uid) then
    local logic_ugc_WOWPass = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_ugc_WOWPass)
    IconPath = logic_ugc_WOWPass:GetWOWpassIcon()
  else
    local Util_UGC = require("client.slua.logic.ugc.util_ugc")
    if Util_UGC.WoWPassActive(profile) then
      IconPath = Util_UGC.GetWoWPassIconPath(profile)
    end
  end
  local bShowWoWPass = IconPath ~= nil
  self:SetWidgetVisible(self.UIRoot.SizeBox_WoWPass, bShowWoWPass, false)
  if bShowWoWPass then
    local params = {sync = false, bMatchSize = true}
    local CommonUIUtil = require("client.common.ui_util")
    self:SetTexture(self.UIRoot.Image_WoWPass, IconPath, params)
  end
end
function UGC_Main_HotAuthor_Item:UpdateModScrollBox()
  local modinfo = self.data.mod_list or {}
  local LogicUGC = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicUGC)
  local ModList = {}
  if self.data and self.data.video_url then
    table.insert(ModList, {
      video_url = self.data.video_url,
      video_cover_url = self.data.video_cover_url
    })
  end
  for k, modid in pairs(modinfo) do
    local modInfo = LogicUGC:GetModByAllCache(tonumber(modid))
    if modInfo and #ModList < 2 then
      modInfo.themeId = self.data.themeId
      table.insert(ModList, modInfo)
    end
  end
  self.ModWidgetList:SetData(ModList)
  self.ModWidgetList:RefreshAllItems()
end
function UGC_Main_HotAuthor_Item:OnAvatarClick()
  self:PlayAudio(sound_config.click_v1)
  local bCanShowGuest = true
  if not self.data.author_uid or self.data.author_uid == tonumber(DataMgr.roleData.uid) then
    if IsWoWEditor then
      UIManager.AndroidBackToLobby()
    else
      UIManager.ShowUI(UIManager.UI_Config.ugc_mine_main)
    end
  else
    local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
    bCanShowGuest = RoleInfoMainSystem.Show(RoleInfoMainSystem.WOW, RoleInfoMainSystem.RoleInfoOpenFromType.WoWItem, self.data.author_uid)
  end
  if bCanShowGuest == true then
    EventSystem:postEvent(EVENTTYPE_UGC, EVENTID_UGC_SHOW_GUEST)
  end
end
local class = require("class")
local ui_base = require("client.slua_ui_framework.component.scroll_box_child_base")
local CUGC_Main_HotAuthor_Item = class(ui_base, nil, UGC_Main_HotAuthor_Item)
return CUGC_Main_HotAuthor_Item
