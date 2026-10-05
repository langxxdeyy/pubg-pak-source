local UGCFriendUpdatesSmallItem = {}
local TimeUtil = require("client.common.time_util")
function UGCFriendUpdatesSmallItem:OnInitialize()
  UGCFriendUpdatesSmallItem.__super.OnInitialize(self)
end
function UGCFriendUpdatesSmallItem:RegistEvents()
  self:AddControlEventByControl(self.UIRoot.Common_Avatar_BP, "OnClickItemCallback", self.OnAvatarClick, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_WorkTitle, self.OnClickWorkTitle, self)
  self:AddCommonEvent(EVENTTYPE_CHAT, EVENTID_UGC_TRANSLATE_CALLBACK, self.OnTransRsp, self)
  self:AddCommonEvent(EVENTTYPE_CHAT, EVENTID_UGC_TRANSLATE_STATE_CHANGE, self.OnTransStateChange, self)
end
function UGCFriendUpdatesSmallItem:OnPostInitialize()
  UGCFriendUpdatesSmallItem.__super.OnPostInitialize(self)
end
function UGCFriendUpdatesSmallItem:OnRefresh(data)
  UGCFriendUpdatesSmallItem.__super.OnRefresh(self, data)
  self.data = data
  self.modInfo = data and data.modInfo or {}
  self:_UpdateAuthor()
  self:FriendLabel()
  self:AuthorUpdates()
end
function UGCFriendUpdatesSmallItem:OnAvatarClick()
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
function UGCFriendUpdatesSmallItem:OnTransRsp(_, _, chatMsg)
  if not self.modInfo then
    return
  end
  if not (chatMsg and chatMsg.msg) or chatMsg.msg ~= self.modInfo.setting.name then
    return
  end
  self:InitName()
end
function UGCFriendUpdatesSmallItem:OnTransStateChange(_, _, str)
  if not self.modInfo then
    return
  end
  if not str or str ~= self.modInfo.setting.name then
    return
  end
  self:InitName()
end
function UGCFriendUpdatesSmallItem:OnClickWorkTitle()
  self:PlayAudio(sound_config.subTab_v1)
  local Config_UGC = require("client.slua.logic.ugc.config_ugc")
  local openSourceModule = Config_UGC.Source_Open_Detail.UGCMain
  local extendedParams = {}
  if self.openSourceType then
    log(bWriteLog and " NewUGCCommonModItem:OnClickMod() self.openSourceType:" .. tostring(self.openSourceType))
    openSourceModule = self.openSourceType
  end
  extendedParams.sourceModule = openSourceModule
  UIManager.ShowUI(UIManager.UI_Config.UGCDetailMainPanel, Config_UGC.Config_UGC_DetailTabs, self.modInfo, extendedParams)
  if self.modInfo then
    local UGCMacros = require("client.slua.logic.ugc.ugc_macros")
    self:SendModReachTLog(self.modInfo, UGCMacros.ENU_UGC_TLOG_REACH_TYPE.CLICK)
  end
end
function UGCFriendUpdatesSmallItem:_UpdateAuthor()
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
function UGCFriendUpdatesSmallItem:FriendLabel()
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
function UGCFriendUpdatesSmallItem:InitName()
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
  local Config_UGC = require("client.slua.logic.ugc.config_ugc")
  if not self.data.IsPlaying then
    TimeStr = TimeUtil.GetTimeAgoStr(self.data.verify_time)
    if self.data.outcome == Config_UGC.Enum_OutcomeType.Win then
      GameStateStr = LocUtil.LocalizeResFormat(81381, name)
    else
      GameStateStr = LocUtil.LocalizeResFormat(81384, name)
    end
  end
  if self.data.IsRecommend then
    TimeStr = TimeUtil.GetTimeAgoStr(self.data.verify_time)
    GameStateStr = LocUtil.LocalizeResFormat(81382, name)
  end
  if self.data.IsCollect then
    TimeStr = TimeUtil.GetTimeAgoStr(self.data.verify_time)
    GameStateStr = LocUtil.LocalizeResFormat(81383, name)
  end
  if self.data.bFollow or self.data.bFriend then
    if self.data.NoticeTime ~= nil then
      newTime = self.data.NoticeTime
    else
      newTime = math.max(self.modInfo.publish_date or 0, self.modInfo.update_date or 0)
    end
    TimeStr = TimeUtil.GetTimeAgoStr(newTime)
    if self.isUpdate then
      GameStateStr = LocUtil.LocalizeResFormat(81380, name)
    else
      GameStateStr = LocUtil.LocalizeResFormat(81568, name)
    end
  end
  log(bWriteLog and "UGCFriendUpdatesSmallItem:InitName name =" .. tostring(name) .. "  TimeStr =" .. tostring(TimeStr))
  if slua.isValid(self.UIRoot.TextBlock_Message) then
    self.UIRoot.TextBlock_Message:SetText(GameStateStr)
  end
  if slua.isValid(self.UIRoot.TextBlock_Time) then
    self.UIRoot.TextBlock_Time:SetText(TimeStr)
  end
  self.UIRoot.TextBlock_Tag:SetText(LocUtil.GetLocalizeResStr(81323))
end
function UGCFriendUpdatesSmallItem:AuthorUpdates()
  if not self.data then
    return
  end
  if self.data.IsPlaying == nil then
    self.isUpdate = self:GetUpdateInfoState(self.data.modInfo)
  end
  self:InitName()
end
function UGCFriendUpdatesSmallItem:GetUpdateInfoState(modInfo)
  if not modInfo then
    return
  end
  local publish_date = modInfo.publish_date or 0
  local update_date = modInfo.update_date or 0
  local newTime = math.max(publish_date, update_date)
  local isUpdate = newTime ~= publish_date
  return isUpdate, newTime
end
function UGCFriendUpdatesSmallItem:CheckInGame()
  return not GameStatus.IsInLobbyOrMainCity()
end
local class = require("class")
local ui_base = require("client.slua.umg.ugc.lobby.UGCModItemBase")
local CUGCFriendUpdatesSmallItem = class(ui_base, nil, UGCFriendUpdatesSmallItem)
return CUGCFriendUpdatesSmallItem
