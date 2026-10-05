local UGCCollectionListDetailsPanelUI = {}
local Util_UGC = require("client.slua.logic.ugc.util_ugc")
local UGCMacros = require("client.slua.logic.ugc.ugc_macros")
local C_ColNum = 5
function UGCCollectionListDetailsPanelUI:ctor(_, Collection, bAuthor, bHideGameButton)
  if not Collection then
    print(bWriteLog and "UGCCollectionListDetailsPanelUI. UGC-????-?/?? error! Collection is nil")
    return
  end
  self.CollectionData = Collection
  self.bAuthor = bAuthor == true
  self.CollectionList = nil
  self.bHideGameButton = bHideGameButton
  if IsWoWEditor then
    self.bHideGameButton = true
  end
  self.BeforeOffset = 0
  self.SendTime = 0
  self:InitCollistionModIDList()
  local LogicUGCCollectionList = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicUGCCollectionList)
  LogicUGCCollectionList:RequestCollectionList()
  LogicUGCCollectionList:RequestCollectionData(Collection.mod_collection_id)
  LogicUGCCollectionList:OpenDetails(Collection.mod_collection_id)
  self.Collection = LogicUGCCollectionList:GetCollectionInfo(Collection.mod_collection_id) or self.Collection
end
function UGCCollectionListDetailsPanelUI:OnInitialize()
  UGCCollectionListDetailsPanelUI.__super.OnInitialize(self)
  self.CollectionListLoop = self:InitChildClassScrollBox(self.UIRoot.LoopScrollGrid_Mod, "client.slua.umg.ugc.lobby.collection.UGCCollectionListDetailsItem")
  self.UIRoot.Common_Avatar_BP:SetWidgetVisibility(UEnums.ESlateVisibility.HitTestInvisible)
  self.UIRoot.WidgetSwitcher_OwnerState:SetActiveWidgetIndex(self.bAuthor and 0 or 1)
  self:SetWidgetVisible(self.UIRoot.HorizontalBox_View, false)
  if LobbySystem.CheckOpen(BP_ENUM_MULTI_UGC_SWITCH) then
    if self.bHideGameButton then
      self:SetWidgetVisible(self.UIRoot.Button_RandomPlay, false, true)
    else
      self:SetWidgetVisible(self.UIRoot.Button_RandomPlay, true, true)
    end
  else
    self:SetWidgetVisible(self.UIRoot.Button_RandomPlay, false, true)
  end
  local UIComponentModule = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.UIComponentModule)
  local PublishRegionMacros = require("client.slua.config.ClientMacros.PublishRegionMacros")
  if PublishRegionMacros.IsBlueholeFamily() then
    self.UIRoot.UGC_Trans_Item_UIBP:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  else
    self.transComp = UIComponentModule:InitWithParentComponent(self, UIComponentModule.Config.UGC_Trans_Item_UIBP, self.UIRoot.UGC_Trans_Item_UIBP)
  end
end
function UGCCollectionListDetailsPanelUI:RegistEvents()
  UGCCollectionListDetailsPanelUI.__super.RegistEvents(self)
  self:AddControlEventByControl(self.UIRoot.Button_DelCollection, "OnClicked", self._OnClickDelCollection, self)
  self:AddControlEventByControl(self.UIRoot.Button_Edit, "OnClicked", self._OnClickEditCollection, self)
  self:AddControlEventByControl(self.UIRoot.Button_Share, "OnClicked", self._OnClickShareCollection, self)
  self:AddControlEventByControl(self.UIRoot.Button_Report, "OnClicked", self._OnClickReport, self)
  self:AddControlEventByControl(self.UIRoot.Button_Like, "OnClicked", self._OnClickLike, self)
  self:AddControlEventByControl(self.UIRoot.Button_Share2, "OnClicked", self._OnClickShareCollection, self)
  self:AddControlEventByControl(self.UIRoot.LoopScrollGrid_Mod, "OnUserScrolled", self._OnUserScrolled, self)
  self:AddControlEventByControl(self.UIRoot.Button_Close, "OnClicked", self._OnClickClose, self)
  self:AddControlEventByControl(self.UIRoot.Button_Details, "OnClicked", self._OnClickNameDetails, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_RandomPlay, self._OnClickRandomPlay, self)
  self:AddCommonEvent(EVENTTYPE_UGC, EVENTID_UGC_ADD_FROM_COLLECTION, self._OnCollectionUpdateNoTLog, self)
  self:AddCommonEvent(EVENTTYPE_UGC, EVENTID_UGC_DEL_FROM_COLLECTION, self._OnCollectionUpdateNoTLog, self)
  self:AddCommonEvent(EVENTTYPE_UGC, EVENTID_UGC_UPDATE_COLLECTION, self._OnCollectionUpdateNoTLog, self)
  self:AddCommonEvent(EVENTTYPE_UGC, EVENTID_UGC_REQUESTCOLLECTIONLIST, self._RefreshBtn, self)
  self:AddCommonEvent(EVENTTYPE_UGC, EVENTID_UGC_SELECT_MOD, self.CloseSelf, self)
  self:AddCommonEvent(EVENTTYPE_UGC, EVENTID_UGC_BATCH_REQUESTCOLLECTION_META, self._RefreshCollection, self)
  self:AddCommonEvent(EVENTTYPE_UGC, EVENTID_UGC_CLICK_CREATE_ROOM, self.CloseSelf, self)
  self:AddCommonEvent(EVENTTYPE_UGC, EVENTID_UGC_DETAIL_MAIN_PANEL_CLOSE, self.OnCloseCollectionUI, self)
end
function UGCCollectionListDetailsPanelUI:OnPostInitialize()
  UGCCollectionListDetailsPanelUI.__super.OnPostInitialize(self)
  self:_RefreshCollection()
  self:_RefreshBtn()
  self:_UpdateMods()
  self:_CheckUrl()
end
function UGCCollectionListDetailsPanelUI:InitCollistionModIDList()
  if not self.CollectionData then
    return
  end
  local Mods = self.CollectionData.ModList
  self.CollectionModIDList = {}
  if Mods then
    for k, Mod in pairs(Mods) do
      local ModId = Mod.ModId
      table.insert(self.CollectionModIDList, ModId)
    end
  end
end
function UGCCollectionListDetailsPanelUI:OnClose()
  UGCCollectionListDetailsPanelUI.__super.OnClose(self)
  local TimeTicker = require("common.time_ticker")
  if self.SendTime then
    TimeTicker.RemoveTimer(self.SendTime)
    self.SendTime = nil
  end
  local LogicUGCCollectionList = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicUGCCollectionList)
  LogicUGCCollectionList:CloseDetails()
  local ui_jump_manager = require("client.common.uibase.ui_jump_manager")
  ui_jump_manager.CloseJumpModule(BP_ENUM_MODULE_UGC_COLLECTIONLIST_DETAILS)
end
function UGCCollectionListDetailsPanelUI:OnCloseCollectionUI(_, _, bCloseByManual)
  if not bCloseByManual then
    self:CloseSelf()
  end
end
function UGCCollectionListDetailsPanelUI:_RefreshCollection()
  local StringUtil = require("common.string_util")
  local LogicUGCCollectionList = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicUGCCollectionList)
  local CollectionData = LogicUGCCollectionList:GetCollectionInfo(self.CollectionData.mod_collection_id) or self.CollectionData
  if self.UIRoot.WidgetSwitcher_Mod then
    local onDownloadSuccess = function()
      self.UIRoot.WidgetSwitcher_Mod:SetActiveWidgetIndex(0)
    end
    self.UIRoot.WidgetSwitcher_Mod:SetActiveWidgetIndex(1)
    Util_UGC.SetUGCCollectionsImage(self, self.UIRoot.Image_Mod, CollectionData.pic_url, onDownloadSuccess, CollectionData.first_mod_template_id)
  else
    Util_UGC.SetUGCCollectionsImage(self, self.UIRoot.Image_Mod, CollectionData.pic_url, nil, CollectionData.first_mod_template_id)
  end
  local uid = CollectionData.uid
  if uid == tonumber(DataMgr.roleData.uid) then
    self.UIRoot.UTRichTextBlock_AuthorName:SetText(DataMgr.roleData.nickName)
    self.UIRoot.Common_Avatar_BP:InitView(1, DataMgr.roleData.uid, DataMgr.roleData.headIconUrl, DataMgr.roleData.gender, DataMgr.roleData.cur_avatar_box_id, DataMgr.roleData.level, false, "")
  else
    local logic_profile_get_wrap = require("client.slua.logic.user.profile.logic_profile_get_wrap")
    logic_profile_get_wrap.GetNormalProfiles({uid}, function(ProfileList)
      if not self.UIRoot then
        return
      end
      for _, Profile in pairs(ProfileList) do
        self.UIRoot.UTRichTextBlock_AuthorName:SetText(Profile.nickName)
        self.UIRoot.Common_Avatar_BP:InitView(1, Profile.uid, Profile.picUrl, Profile.sex, Profile.cur_avatar_box_id, 0, false, "")
      end
    end, Enum_PROFILE_REPORT_CFG.UGC)
  end
  local LogicUGCTrans = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicUGCTrans)
  local IsTransName = LogicUGCTrans:GetTransByStrWithState(tostring(CollectionData.name))
  local IsTransDesc = LogicUGCTrans:GetTransByStrWithState(tostring(CollectionData.desc))
  if not IsTransName then
    self.UIRoot.TextBlock_Name:SetText(tostring(CollectionData.name))
  else
    self.UIRoot.TextBlock_Name:SetText(tostring(IsTransName))
  end
  if not IsTransDesc then
    self.UIRoot.TextBlock_Desc:SetText(tostring(CollectionData.desc))
  else
    self.UIRoot.TextBlock_Desc:SetText(tostring(IsTransDesc))
  end
  self.UIRoot.TextBlock_ID:SetText(LocUtil.LocalizeResFormat(77904, CollectionData.mod_collection_id))
  self.UIRoot.TextBlock_Tag:SetText(LogicUGCCollectionList:GetTagName(CollectionData.tag))
  self.UIRoot.TextBlock_ModCtn:SetText(StringUtil.FormatNum_KMB(CollectionData.play_cnt))
  self.UIRoot.TextBlock_11:SetText(LocUtil.LocalizeResFormat(69278, CollectionData.pub_mod_list_count))
  self.UIRoot.TextBlock_PlayCtnTxt:SetText(StringUtil.FormatNum_KMB(CollectionData.like_cnt))
  self.UIRoot.TextBlock_CollectCtn:SetText(StringUtil.FormatNum_KMB(CollectionData.view_cnt))
  self.UIRoot.TextBlock_Share:SetText(StringUtil.FormatNum_KMB(CollectionData.share_cnt))
  self.UIRoot.TextBlock_Share2:SetText(StringUtil.FormatNum_KMB(CollectionData.share_cnt))
end
function UGCCollectionListDetailsPanelUI:_UpdateMods(ModInfoList)
  if not self.CollectionModIDList then
    return
  end
  local LogicUGC = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicUGC)
  if not ModInfoList then
    local TypeParam
    if self.bAuthor then
      TypeParam = {
        uid = self.CollectionData.uid,
        mod_collection_id = self.CollectionData.mod_collection_id
      }
    end
    if not next(self.CollectionModIDList) then
      local ModList = {}
      if self.bAuthor then
        table.insert(ModList, {
          bAdd = true,
          Collection = self.CollectionData
        })
      end
      self:_UpdateLoop(ModList)
    else
      local _, ReqList, NotReqList = LogicUGC:BatchGetModInfo(self.CollectionModIDList, LogicUGC.C_ModListTypes.Collections, function(MetaList, ListType, Param, bUseCache, FilterOfflineModList)
        if not self.UIRoot then
          return
        end
        self:OnGetBatchModListRsp(MetaList, ListType, Param, bUseCache, FilterOfflineModList)
      end, {
        bSplit = true,
        TypeParam = TypeParam,
        bSimple = true
      })
      self.bDelayFetch = NotReqList and 0 < #NotReqList
    end
    return
  end
  local ModList = {}
  self.CollectionList = {}
  if self.bAuthor then
    table.insert(ModList, {
      bAdd = true,
      Collection = self.CollectionData
    })
  end
  local ModInfoList = LogicUGC:BatchGetModInfo(self.CollectionModIDList, nil, nil, {bExportArray = true}) or {}
  for k, Mod in ipairs(ModInfoList) do
    table.insert(ModList, {
      Mod = Mod,
      Collection = self.CollectionData,
      bAuthor = self.bAuthor
    })
    table.insert(self.CollectionList, Mod.pub_mod_meta or Mod)
  end
  self:_UpdateLoop(ModList)
  self:InitTransState()
end
function UGCCollectionListDetailsPanelUI:_CheckUrl()
  if self.bAuthor and self.CollectionData and self.CollectionData.pub_mod_list_count > 0 then
    self:AddTimerOnce(1, function()
      if self.UIRoot then
        local CollectionUrl = self.CollectionData.pic_url
        local Mods = self.CollectionData.ModList
        if 0 < #Mods then
          local LogicUGC = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicUGC)
          local ModInfo = LogicUGC:GetModByAllCache(Mods[1].ModId)
          if ModInfo then
            local Url = Util_UGC.GetUGCThumbUrl(ModInfo.pub_mod_meta.setting, false)
            if Url ~= "" and Url and Url ~= CollectionUrl then
              print(bWriteLog and "UGCCollectionListDetailsPanelUI:_CheckUrl url not match, need to refresh.  url: " .. Url .. ", CollectionUrl: " .. CollectionUrl)
              local UGCModHandler = require("client.network.Protocol.UGCModHandler")
              UGCModHandler.send_ugc_refresh_mod_collection_picurl_req(self.CollectionData.mod_collection_id, Mods[1].ModId)
            end
          end
        end
      end
    end)
  end
end
function UGCCollectionListDetailsPanelUI:_UpdateLoop(ModList)
  if self.CollectionListLoop:GetItemCount() > 0 then
    self.CollectionListLoop:RefreshAllItems(ModList)
  else
    self.CollectionListLoop:SetData(ModList)
    local TimeTicker = require("common.time_ticker")
    if self.SendTime then
      TimeTicker.RemoveTimer(self.SendTime)
      self.SendTime = nil
    end
    self.SendTime = TimeTicker.AddTimerOnce(0.5, function()
      self:ScrollShowMod(true, self.CollectionListLoop, 0)
    end)
  end
end
function UGCCollectionListDetailsPanelUI:_RefreshBtn()
  if self.CollectionData then
    local LogicUGCCollectionList = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicUGCCollectionList)
    local bLike = LogicUGCCollectionList:IsLike(self.CollectionData.mod_collection_id)
    self.UIRoot.WidgetSwitcher_Favor:SetActiveWidgetIndex(bLike and 1 or 0)
  else
    self.UIRoot.WidgetSwitcher_Favor:SetActiveWidgetIndex(0)
  end
end
function UGCCollectionListDetailsPanelUI:_OnClickClose()
  self:PlayAudio(sound_config.click_v1)
  self:CloseSelf()
  EventSystem:postEvent(EVENTTYPE_UGC, EVENTID_UGC_ONCompilationsCelr_MOD)
end
function UGCCollectionListDetailsPanelUI:_OnClickDelCollection()
  self:PlayAudio(sound_config.click_v1)
  if self.CollectionData then
    local LogicUGCCollectionList = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicUGCCollectionList)
    local CollectionId = self.CollectionData.mod_collection_id
    local CommonMsgBoxMgr = require("client.slua.logic.common.logic_common_msg_box")
    local Title = LocUtil.GetLocalizeResStr(5077)
    local Desc = LocUtil.GetLocalizeResStr(69272)
    self.MsgBoxShowing = true
    CommonMsgBoxMgr.Show(CommonMsgBoxMgr.SHOW_TYPE_TWO, Title, Desc, function()
      local UGCModHandler = require("client.network.Protocol.UGCModHandler")
      UGCModHandler.send_ugc_delete_pub_mod_collection_req(CollectionId):Then(function(_, ModCollectionId)
        LogicUGCCollectionList:DelCollection(ModCollectionId)
        ShowNotice(69273)
        self:CloseSelf()
      end)
    end)
  end
end
function UGCCollectionListDetailsPanelUI:_OnClickLike()
  self:PlayAudio(sound_config.click_v1)
  if self.CollectionData then
    local LogicUGCCollectionList = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicUGCCollectionList)
    local CollectionId = self.CollectionData.mod_collection_id
    local bLike = LogicUGCCollectionList:IsLike(CollectionId)
    log(bWriteLog and "UGCCollectionListDetailsPanelUI:_OnClickLike current bLike = " .. tostring(bLike))
    local UGCModHandler = require("client.network.Protocol.UGCModHandler")
    if bLike then
      UGCModHandler.send_ugc_cancel_like_mod_collection_req(CollectionId):Then(function(_, ModCollectionId)
        LogicUGCCollectionList:CancelLikeCollection(ModCollectionId)
        self:_RefreshBtn()
        ShowNotice(6798)
      end)
    else
      if not LogicUGCCollectionList:CanLikeMoreCollection() then
        ShowNotice(69359)
        return
      end
      UGCModHandler.send_ugc_like_mod_collection_req(CollectionId):Then(function(_, ModCollectionId)
        LogicUGCCollectionList:LikeCollection(ModCollectionId)
        self:_RefreshBtn()
        ShowNotice(6797)
      end)
    end
  end
end
function UGCCollectionListDetailsPanelUI:_OnClickNameDetails()
  self:PlayAudio(sound_config.click)
  local uid = self.CollectionData.uid
  local config = UIManager.UI_Config.roleinfo_main
  if UIManager.IsUIShow(config) then
    UIManager.CloseUI(config)
  end
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  if RoleInfoMainSystem.Show(RoleInfoMainSystem.WOW, RoleInfoMainSystem.RoleInfoOpenFromType.WoWItem, uid) then
    EventSystem:postEvent(EVENTTYPE_UGC, EVENTID_UGC_SHOW_GUEST)
  end
end
function UGCCollectionListDetailsPanelUI:_OnClickRandomPlay()
  self:PlayAudio(sound_config.click)
  local Config_UGC = require("client.slua.logic.ugc.config_ugc")
  local LogicUGCMulti = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicUGCMulti)
  LogicUGCMulti:ReqSetUGCModBundle(Config_UGC.Enum_Bundle_Type.Bundle, self.CollectionData.mod_collection_id)
end
function UGCCollectionListDetailsPanelUI:_OnClickReport()
  self:PlayAudio(sound_config.click_v1)
  if self.CollectionData then
    local LogicComplaint = require("client.logic.battle.logic_complaint")
    LogicComplaint.ShowComplaint(LogicComplaint.EComplaintFrom.UGCCollections, self.CollectionData)
  end
end
function UGCCollectionListDetailsPanelUI:_OnClickShareCollection()
  self:PlayAudio(sound_config.click_v1)
  if self.CollectionData then
    if self.CollectionData.pub_mod_list_count == 0 then
      ShowNotice(69415)
      return
    end
    UIManager.ShowUI(UIManager.UI_Config.UGC_Share_CollectionList_Popup_UIBP, self.CollectionData)
    local LogicUGCCollectionList = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicUGCCollectionList)
    LogicUGCCollectionList:SetShareCollectionData(self.CollectionData)
  end
end
function UGCCollectionListDetailsPanelUI:_OnClickEditCollection()
  self:PlayAudio(sound_config.click_v1)
  if self.CollectionData and self.bAuthor and UIManager and UIManager.UI_Config.UGCCreateCollectionListPopup then
    UIManager.ShowUI(UIManager.UI_Config.UGCCreateCollectionListPopup, self.CollectionData)
  end
end
function UGCCollectionListDetailsPanelUI:_OnCollectionUpdate()
  if self.CollectionData then
    local LogicUGCCollectionList = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.LogicUGCCollectionList)
    self.CollectionData = LogicUGCCollectionList:GetCollectionInfo(self.CollectionData.mod_collection_id)
    self:InitCollistionModIDList()
    self:_RefreshCollection()
    self:_UpdateMods()
  end
end
function UGCCollectionListDetailsPanelUI:_OnCollectionUpdateNoTLog()
  local Logic_UGC_TLog = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.Logic_UGC_TLog)
  Logic_UGC_TLog:SetTLogSwitch(false)
  self:_OnCollectionUpdate()
  Logic_UGC_TLog:SetTLogSwitch(true)
end
local MaxScrollOffset = -1
function UGCCollectionListDetailsPanelUI:_OnUserScrolled(Offset)
  if Offset <= 0 then
    return
  end
  self:ScrollShowMod(false, self.CollectionListLoop, Offset)
  if Offset >= MaxScrollOffset then
    MaxScrollOffset = Offset
    if not self.bDelayFetch then
      return
    end
    if not self.UpdateTimer then
      self.UpdateTimer = self:AddTimerOnce(0, function()
        if self.UIRoot then
          self:_UpdateMods()
          self.UpdateTimer = nil
        end
      end)
    end
  end
end
function UGCCollectionListDetailsPanelUI:OnGetBatchModListRsp(MetaList, ListType, Param, bUseCache, FilterOfflineModList)
  self:_UpdateMods(MetaList)
end
function UGCCollectionListDetailsPanelUI:InitTransState()
  if not self.Collection or not next(self.Collection) then
    return
  end
  local TransMap = {}
  local TransSceneMap = {}
  if self.CollectionList and #self.CollectionList > 0 then
    for i, v in ipairs(self.CollectionList) do
      local ModName = v.setting and v.setting.name
      if ModName and ModName ~= "" then
        TransMap[ModName] = 1
        TransSceneMap[ModName] = UGCMacros.ENUM_TRANSLATE_SCENE.OUTGAME_OLD_LOBBY_MAP_TITLE
      end
    end
  end
  TransMap[self.CollectionData.name] = self.UIRoot.TextBlock_Name
  TransMap[self.CollectionData.desc] = self.UIRoot.TextBlock_Desc
  TransSceneMap[self.CollectionData.name] = UGCMacros.ENUM_TRANSLATE_SCENE.OUTGAME_MAP_COLLECTION_TITLE
  TransSceneMap[self.CollectionData.desc] = UGCMacros.ENUM_TRANSLATE_SCENE.OUTGAME_MAP_COLLECTION_DESC
  if self.transComp then
    self.transComp:SetStr2WidgetMap(TransMap, self.UIRoot, TransSceneMap)
    self.CollectionListLoop:RefreshAllItems()
    self.transComp:CheckAutoTranslate()
  end
end
function UGCCollectionListDetailsPanelUI:ScrollShowMod(IsInit, widget, offset)
  local LoopHeigth = widget.UIRoot:GetViewSize().Y
  local ItemHeigth = math.floor(widget.UIRoot.ItemSize.Y) + math.floor(widget.UIRoot.Padding.Y)
  local Deviation = LoopHeigth % ItemHeigth
  local StartIndex = (LoopHeigth - LoopHeigth % ItemHeigth) / ItemHeigth
  local modlist = widget:GetSetData()
  if IsInit then
    for i = 1, StartIndex * C_ColNum do
      if modlist[i] and modlist[i].Mod and modlist[i].Mod.pub_mod_meta then
        self:SendModReachTLog(modlist[i].Mod.pub_mod_meta, i)
      end
    end
    self.BeforeOffset = 0
  elseif ItemHeigth <= offset + Deviation - self.BeforeOffset then
    self.BeforeOffset = offset + Deviation
    local lineIndex = (self.BeforeOffset - self.BeforeOffset % ItemHeigth) / ItemHeigth
    if lineIndex and 1 <= lineIndex then
      local Num = math.floor((lineIndex + StartIndex - 1) * C_ColNum)
      for i = 1, C_ColNum do
        Num = Num + 1
        if modlist[Num] and modlist[Num].Mod and modlist[Num].Mod.pub_mod_meta then
          self:SendModReachTLog(modlist[Num].Mod.pub_mod_meta, Num)
        end
      end
    end
  end
end
function UGCCollectionListDetailsPanelUI:SendModReachTLog(modInfo, index)
  if not modInfo then
    log(bWriteLog and "UGCCollectionListDetailsPanelUI:SendModReachTLog modInfo is nil")
    return
  end
  local Logic_UGC_TLog = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.Logic_UGC_TLog)
  Logic_UGC_TLog:ReportModExposure(modInfo.mod_id, index, {
    colNum = C_ColNum,
    scene = TLogEventDefine.UGC_Mod_Exposure_Main
  })
end
function UGCCollectionListDetailsPanelUI:GetDataForJumpBack()
  return {
    ctorData = {
      [1] = self.CollectionData,
      [2] = self.bAuthor,
      [3] = self.bHideGameButton
    }
  }
end
local class = require("class")
local ui_base = require("client.slua_ui_framework.base")
return class(ui_base, nil, UGCCollectionListDetailsPanelUI)
