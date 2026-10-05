local UGCFollowAuthorItem = {}
local Config_UGC = require("client.slua.logic.ugc.config_ugc")
function UGCFollowAuthorItem:ctor()
  self.BeforeOffset = 0
end
function UGCFollowAuthorItem:OnInitialize()
  UGCFollowAuthorItem.__super.OnInitialize(self)
  self.modWidgetList = self:InitChildClassScrollBox(self.UIRoot.LoopScrollBox_ModList, "client.slua.umg.ugc.lobby.follow.UGCFollowModItem")
end
function UGCFollowAuthorItem:RegistEvents()
  self:AddControlEventByControl(self.UIRoot.Button_AuthorCommunity, "OnClicked", self.OnClickAuthorCommunity, self)
  self:AddControlEventByControl(self.UIRoot.Common_Avatar_BP, "OnClickItemCallback", self.OnAvatarClick, self)
  self:AddControlEventByControl(self.UIRoot.Button_ShowAll, "OnClicked", self.OnClickAuthorSpace, self)
  self:AddControlEventByControl(self.UIRoot.LoopScrollBox_ModList, "OnUserScrolled", self.OnUserScrolled, self)
end
function UGCFollowAuthorItem:OnPostInitialize()
  self.modWidgetList:SetMaxInertiaSpeed(Config_UGC.AUTHOR_INERTIA_SCROLL)
  UGCFollowAuthorItem.__super.OnPostInitialize(self)
end
function UGCFollowAuthorItem:OnRefresh(data)
  UGCFollowAuthorItem.__super.OnRefresh(self, data)
  self.data = data
  self:_UpdateAuthor()
  self:_UpdateModScrollBox()
end
function UGCFollowAuthorItem:OnClickAuthorCommunity()
  self:PlayAudio(sound_config.click_v1)
  if not self.data then
    return
  end
  local authorUid = self.data.authorUid
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  if RoleInfoMainSystem.Show(RoleInfoMainSystem.WOW, RoleInfoMainSystem.RoleInfoOpenFromType.WoWItem, authorUid) then
    EventSystem:postEvent(EVENTTYPE_UGC, EVENTID_UGC_SHOW_GUEST)
  end
end
function UGCFollowAuthorItem:OnAvatarClick()
  self:PlayAudio(sound_config.click_v1)
  local SocialPersonSpaceSystem = require("client.slua.logic.lobby.Left.logic_social_person_space")
  if not self.data then
    return
  end
  local authorUid = self.data.authorUid
  SocialPersonSpaceSystem.EnterPersonSpace(authorUid)
end
function UGCFollowAuthorItem:OnUserScrolled(offset)
  if offset <= 0 then
    return
  end
  self:ScrollShowMod(false, self.modWidgetList, offset)
end
function UGCFollowAuthorItem:_UpdateAuthor()
  local authorUid = self.data.authorUid
  local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
  local profile = logic_profile:GetLocalProfile(authorUid)
  if profile then
    self:SetWidgetVisible(self.UIRoot.Title_UIBP, true)
    self.UIRoot.TextBlock_AuthorName:SetText(profile.nickName)
    self.UIRoot.Common_Avatar_BP:InitView(1, authorUid, profile.picUrl, nil, profile.cur_avatar_box_id, nil)
    self.UIRoot.Title_UIBP:SetAliasInfo(profile.alias.id or 0, profile.alias.title or "", profile.alias.nation or "", 0, profile.alias.rank_id or 0)
  else
    self:SetWidgetVisible(self.UIRoot.Title_UIBP, false)
    EventSystem:postEvent(EVENTTYPE_UGC, EVENTID_UGC_FOLLOW_AUTHOR_NO_PROFILE, authorUid)
  end
end
function UGCFollowAuthorItem:_UpdateModScrollBox()
  self.modWidgetList:SetData(self.data.modInfoList)
  self.modWidgetList:RefreshAllItems()
end
function UGCFollowAuthorItem:UpdateAuthorLevel()
  local LogicUGCAuthor = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicUGCAuthor)
  local authorUid = self.data.authorUid
  local level = LogicUGCAuthor:GetAuthorLevel(authorUid)
  local authorLevelConfig = Config_UGC.GetAuthorLevelConfigByID(level)
  if authorLevelConfig then
    self.UIRoot.TextBlock_AuthorLevel:SetText(authorLevelConfig.Name)
    if authorLevelConfig.BgImage and authorLevelConfig.BgImage ~= "" then
      self:SetTexture(self.UIRoot.Image_AuthorLevelBg, authorLevelConfig.BgImage)
      self:SetWidgetVisible(self.UIRoot.Image_AuthorLevelBg, true)
    else
      self:SetWidgetVisible(self.UIRoot.Image_AuthorLevelBg, false)
    end
    if authorLevelConfig.Icon and authorLevelConfig.Icon ~= "" then
      self:SetTexture(self.UIRoot.Image_AuthorLevel, authorLevelConfig.Icon)
      self:SetWidgetVisible(self.UIRoot.Image_AuthorLevel, true)
      self:SetWidgetVisible(self.UIRoot.CanvasPanel_LevelIcon, false)
    else
      self:SetWidgetVisible(self.UIRoot.Image_AuthorLevel, false)
      self:SetWidgetVisible(self.UIRoot.CanvasPanel_LevelIcon, false)
    end
  end
end
function UGCFollowAuthorItem:SendModReachTLog(modInfo, Index)
  if not modInfo then
    log(bWriteLog and "UGCFollowAuthorItem:SendModReachTLog modInfo is nil")
    return
  end
  log(bWriteLog and "UGCFollowAuthorItem:SendModReachTLog mod_id = " .. modInfo.mod_id .. " Index = " .. Index)
  local params = {position = Index}
  local Logic_UGC_TLog = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.Logic_UGC_TLog)
  Logic_UGC_TLog:SendModTLog(modInfo.mod_id, TLogEventDefine.UGC_Mod_Exposure_Main, params)
end
function UGCFollowAuthorItem:OnClickAuthorSpace()
  self:PlayAudio(sound_config.click_v1)
  local authorUid = self.data.authorUid
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  RoleInfoMainSystem.Show(RoleInfoMainSystem.WOW, RoleInfoMainSystem.RoleInfoOpenFromType.RegionStrongerRank, tostring(authorUid))
end
function UGCFollowAuthorItem:ScrollShowMod(IsInit, widget, offset)
  local LoopWide = widget.UIRoot:GetViewSize().X - 3
  local ItemWide = math.floor(widget.UIRoot.ItemSize)
  local Deviation = LoopWide % ItemWide
  local StartIndex = (LoopWide - LoopWide % ItemWide) / ItemWide
  local modlist = widget:GetSetData()
  if IsInit then
    for i = 1, StartIndex do
      if modlist[i] and modlist[i].pub_mod_meta then
        self:SendModReachTLog(modlist[i].pub_mod_meta, i)
      end
    end
    self.BeforeOffset = 0
  elseif ItemWide <= offset + Deviation - self.BeforeOffset then
    self.BeforeOffset = offset + Deviation
    local lineIndex = (self.BeforeOffset - self.BeforeOffset % ItemWide) / ItemWide
    if lineIndex and 1 <= lineIndex then
      local Num = math.floor(lineIndex + StartIndex)
      if modlist[Num] and modlist[Num].pub_mod_meta then
        self:SendModReachTLog(modlist[Num].pub_mod_meta, Num)
      end
    end
  end
end
local class = require("class")
local ui_base = require("client.slua_ui_framework.component.scroll_box_child_base")
local CUGCFollowAuthorItem = class(ui_base, nil, UGCFollowAuthorItem)
return CUGCFollowAuthorItem
