local UGCFriendUpdatesItem = {}
local TimeUtil = require("client.common.time_util")
local Config_UGC = require("client.slua.logic.ugc.config_ugc")
function UGCFriendUpdatesItem:OnInitialize()
  UGCFriendUpdatesItem.__super.OnInitialize(self)
  self.modWidgetList = self:InitChildClassScrollBox(self.UIRoot.LoopScrollBox_ModList, "client.slua.umg.ugc.lobby.friend.UGCFriendModItem")
end
function UGCFriendUpdatesItem:RegistEvents()
  self:AddControlEventByControl(self.UIRoot.Common_Avatar_BP, "OnClickItemCallback", self.OnAvatarClick, self)
  self:AddCommonEvent(EVENTTYPE_CHAT, EVENTID_UGC_TRANSLATE_CALLBACK, self.OnTransRsp, self)
  self:AddCommonEvent(EVENTTYPE_CHAT, EVENTID_UGC_TRANSLATE_STATE_CHANGE, self.OnTransStateChange, self)
end
function UGCFriendUpdatesItem:OnPostInitialize()
  UGCFriendUpdatesItem.__super.OnPostInitialize(self)
  local UIComponentModule = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.UIComponentModule)
  self.New_UGC_Common_Mod_Item_UIBP = UIComponentModule:InitWithParentComponent(self, UIComponentModule.Config.UGC_FriendUpdates_Item_UIBP, self.UIRoot.New_UGC_Common_Mod_Item_UIBP)
  self.UIRoot.Image_TagBG:SetWidgetVisibility(UEnums.GSlateVisibility.Collapsed)
  self.UIRoot.TextBlock_0:SetWidgetVisibility(UEnums.GSlateVisibility.Collapsed)
end
function UGCFriendUpdatesItem:OnRefresh(data)
  self.data = data
  self.modInfo = data and data.modInfo or {}
  self:_UpdateAuthor()
  self:FriendLabel()
  self:_UpdateTypeTag()
  local badgeSceneType
  if data and data.NoticeTime ~= nil then
    local Config_Badge = require("client.slua.logic.ugc.config_ugc_badge")
    badgeSceneType = Config_Badge.SceneType.UpdateNotice
  end
  self.New_UGC_Common_Mod_Item_UIBP:SetBadgeSceneType(badgeSceneType)
  self.New_UGC_Common_Mod_Item_UIBP:OnRefresh(self.modInfo)
  self:AuthorUpdates()
end
function UGCFriendUpdatesItem:OnClickAuthorCommunity()
  if not self.data then
    return
  end
  local authorUid = self.data.authorUid
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  if RoleInfoMainSystem.Show(RoleInfoMainSystem.WOW, RoleInfoMainSystem.RoleInfoOpenFromType.WoWItem, authorUid) then
    EventSystem:postEvent(EVENTTYPE_UGC, EVENTID_UGC_SHOW_GUEST)
  end
end
function UGCFriendUpdatesItem:OnAvatarClick()
  self:PlayAudio(sound_config.click_v1)
  if self:CheckInGame() then
    return
  end
  local bCanShowGuest = true
  if not self.data.author_uid or self.data.author_uid == tonumber(DataMgr.roleData.uid) then
    if IsWoWEditor then
      UIManager.AndroidBackToLobby()
    else
      UIManager.ShowUI(UIManager.UI_Config.ugc_mine_main)
    end
  else
    local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
    bCanShowGuest = RoleInfoMainSystem.Show(RoleInfoMainSystem.WOW, RoleInfoMainSystem.RoleInfoOpenFromType.WoWItem, self.data.author_uid, {
      mod_id = self.modInfo.mod_id
    })
  end
  if bCanShowGuest == true then
    EventSystem:postEvent(EVENTTYPE_UGC, EVENTID_UGC_SHOW_GUEST)
  end
end
function UGCFriendUpdatesItem:OnTransRsp(_, _, chatMsg)
  if not self.modInfo then
    return
  end
  if not (chatMsg and chatMsg.msg) or chatMsg.msg ~= self.modInfo.setting.name then
    return
  end
  self:InitName()
end
function UGCFriendUpdatesItem:OnTransStateChange(_, _, str)
  if not self.modInfo then
    return
  end
  if not str or str ~= self.modInfo.setting.name then
    return
  end
  self:InitName()
end
function UGCFriendUpdatesItem:_UpdateAuthor()
  local authorUid = self.data.author_uid
  local logic_profile = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_profile)
  local profile = logic_profile:GetLocalProfile(authorUid)
  if profile then
    self.UIRoot.TextBlock_Name:SetText(profile.nickName)
    self.UIRoot.Common_Avatar_BP:InitView(1, authorUid, profile.picUrl, nil, profile.cur_avatar_box_id, nil)
    self.UIRoot.Common_Avatar_BP:SetButtonEnabled(true)
  else
    EventSystem:postEvent(EVENTTYPE_UGC, EVENTID_UGC_FOLLOW_AUTHOR_NO_PROFILE, authorUid)
  end
end
function UGCFriendUpdatesItem:FriendLabel()
  local AuthorUID = self.data.author_uid
  self.UIRoot.CanvasPanel_Sub_Tag:SetWidgetVisibility(UEnums.GSlateVisibility.Collapsed)
  local LogicUGCAuthor = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicUGCAuthor)
  local followList = LogicUGCAuthor:GetSortedFollowList()
  for _, follow_author in ipairs(followList) do
    if AuthorUID == follow_author.uid then
      self.UIRoot.CanvasPanel_Sub_Tag:SetWidgetVisibility(UEnums.GSlateVisibility.SelfHitTestInvisible)
      break
    end
  end
end
function UGCFriendUpdatesItem:_UpdateTypeTag()
  if self.data and self.data.UpdateType then
    local LogicUGCAuthorNotice = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_ugc_author_notice)
    local typeText = LogicUGCAuthorNotice and LogicUGCAuthorNotice:GetUpdateTypeName(self.data.UpdateType) or ""
    self.UIRoot.TextBlock_0:SetText(typeText)
    self.UIRoot.Image_TagBG:SetWidgetVisibility(UEnums.GSlateVisibility.SelfHitTestInvisible)
    self.UIRoot.TextBlock_0:SetWidgetVisibility(UEnums.GSlateVisibility.SelfHitTestInvisible)
  else
    self.UIRoot.Image_TagBG:SetWidgetVisibility(UEnums.GSlateVisibility.Collapsed)
    self.UIRoot.TextBlock_0:SetWidgetVisibility(UEnums.GSlateVisibility.Collapsed)
  end
end
function UGCFriendUpdatesItem:InitName()
  if not self.modInfo or not self.modInfo.setting then
    if self.UIRoot and slua.isValid(self.UIRoot) then
      self.UIRoot.TextBlock_Message:SetText(LocUtil.GetLocalizeResStr(24838))
    end
    return
  end
  if not slua.isValid(self.UIRoot) then
    return
  end
  if not slua.isValid(self.UIRoot.TextBlock_Message) then
    return
  end
  local LogicUGCTrans = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicUGCTrans)
  local translatedStr = LogicUGCTrans:GetTransByStrWithState(self.modInfo.setting.name)
  local name = translatedStr or self.modInfo.setting.name
  local newTime
  local TimeStr, GameStateStr = ""
  if not self.data.IsPlaying then
    TimeStr = TimeUtil.GetTimeAgoStr(self.data.verify_time)
    if self.data.outcome == Config_UGC.Enum_OutcomeType.Win then
      GameStateStr = LocUtil.LocalizeResFormat(81570, TimeStr, name)
    else
      GameStateStr = LocUtil.LocalizeResFormat(81573, TimeStr, name)
    end
  end
  if self.data.IsRecommend then
    TimeStr = TimeUtil.GetTimeAgoStr(self.data.verify_time)
    GameStateStr = LocUtil.LocalizeResFormat(81571, TimeStr, name)
  end
  if self.data.IsCollect then
    TimeStr = TimeUtil.GetTimeAgoStr(self.data.verify_time)
    GameStateStr = LocUtil.LocalizeResFormat(81572, TimeStr, name)
  end
  if self.data.bFollow or self.data.bFriend then
    if self.data.NoticeTime ~= nil then
      newTime = self.data.NoticeTime
    else
      newTime = math.max(self.modInfo.publish_date or 0, self.modInfo.update_date or 0)
    end
    TimeStr = TimeUtil.GetTimeAgoStr(newTime)
    if self.isUpdate then
      GameStateStr = LocUtil.LocalizeResFormat(81569, TimeStr, name)
    else
      GameStateStr = LocUtil.LocalizeResFormat(81574, TimeStr, name)
    end
    if self.data.Version and self.data.Version ~= "" then
      GameStateStr = GameStateStr .. "  " .. tostring(self.data.Version)
    end
  end
  log(bWriteLog and "UGCFriendUpdatesItem:InitName name =" .. tostring(name) .. "  TimeStr =" .. tostring(TimeStr))
  if slua.isValid(self.UIRoot.TextBlock_Message) then
    self.UIRoot.TextBlock_Message:SetText(GameStateStr)
  end
  self.UIRoot.TextBlock_Tag:SetText(LocUtil.GetLocalizeResStr(81323))
end
function UGCFriendUpdatesItem:AuthorUpdates()
  if not self.data then
    return
  end
  if self.data.IsPlaying == nil then
    self.isUpdate = self:GetUpdateInfoState(self.data.modInfo)
  end
  self:InitName()
end
function UGCFriendUpdatesItem:GetUpdateInfoState(modInfo)
  if not modInfo then
    return
  end
  local publish_date = modInfo.publish_date or 0
  local update_date = modInfo.update_date or 0
  local newTime = math.max(publish_date, update_date)
  local isUpdate = newTime ~= publish_date
  return isUpdate, newTime
end
function UGCFriendUpdatesItem:_UpdateModScrollBox()
  self.modWidgetList:SetData(self.data.modInfoList)
  self.modWidgetList:RefreshAllItems()
end
function UGCFriendUpdatesItem:UpdateAuthorLevel()
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
function UGCFriendUpdatesItem:OnClickAuthorSpace()
  local authorUid = self.data.authorUid
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  RoleInfoMainSystem.Show(RoleInfoMainSystem.WOW, RoleInfoMainSystem.RoleInfoOpenFromType.RegionStrongerRank, tostring(authorUid))
end
function UGCFriendUpdatesItem:CheckInGame()
  return not GameStatus.IsInLobbyOrMainCity()
end
local class = require("class")
local ui_base = require("client.slua_ui_framework.component.scroll_box_child_base")
local CUGCFriendUpdatesItem = class(ui_base, nil, UGCFriendUpdatesItem)
return CUGCFriendUpdatesItem
