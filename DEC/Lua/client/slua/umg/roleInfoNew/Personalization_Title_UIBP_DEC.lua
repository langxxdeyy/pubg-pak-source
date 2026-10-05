local RoleInfoSystem = require("client.slua.logic.roleInfo.logic_roleinfo_title")
local Personalization_Title_UIBP = {
  NewbieGuideStep = 0,
  CONST = {
    JumpType = {
      default = 0,
      season = 1,
      achievement = 2,
      pay = 3,
      fightArea = 4,
      leagueGame = 5,
      rp_scription = 6,
      club_home_page = 7,
      club_metal_detail = 8,
      getWayPop = 9
    }
  }
}
local LvQualityNames = {
  "level0",
  "level1",
  "level2",
  "level3",
  "level4",
  "level5",
  "level6"
}
function Personalization_Title_UIBP:ctor(_, ScrollAliasId)
  self.ScrollAliasId = ScrollAliasId
  self.srcAliasReddotStatus = {}
  self.reddotChanged = false
  self.firstButton = 1
end
function Personalization_Title_UIBP:InitItemGrid()
  self.ItemGrid = self:InitScrollBox(self.UIRoot.Title_Grid)
end
function Personalization_Title_UIBP:RegistEvents()
  Personalization_Title_UIBP.__super.RegistEvents(self)
  self.ItemGrid:AddItemWidgetChildEvent("Button_0", "OnClicked", self.ButtonOnClickedItem, self)
  self:AddCommonEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_ALL_TITLE, self.UpdateCurrentAlias, self)
  self:AddCommonEvent(EVENTTYPE_ROLEINFO, EVENTID_ROLEINFO_UPDATE_IS_SHOW_ALIAS_ENTER_BROADCAST, self.UpdateIsShowAliasEnterBroadcast, self)
  self:AddOnCheckStateChangedEventByControl(self.UIRoot.CheckBox_Hide, self.OnClickCheckBoxHide, self)
end
function Personalization_Title_UIBP:OnPostInitialize()
  Personalization_Title_UIBP.__super.OnPostInitialize(self)
  self:InitUI()
  RoleInfoSystem.isFirstIn = true
end
function Personalization_Title_UIBP:OnClose()
  if self.reddotChanged then
    local changedTable = {}
    local changeNum = 0
    for k, v in pairs(RoleInfoSystem.arr_temp) do
      if self.srcAliasReddotStatus[v.id] ~= v.bReddot then
        changeNum = changeNum + 1
        changedTable[changeNum] = v.id
      end
    end
    if 0 < changeNum then
      RoleInfoSystem:click_alias_batch_report(changedTable)
    end
  end
  Personalization_Title_UIBP.__super.OnClose(self)
end
function Personalization_Title_UIBP:InitUI()
  RoleInfoSystem.initSortList()
  RoleInfoSystem.InitTypeList()
  RoleInfoSystem.Enter()
  RoleInfoSystem.isShow = true
end
function Personalization_Title_UIBP:UpdateCurrentAlias()
  if RoleInfoSystem.isFirstIn == true then
    RoleInfoSystem.isFirstIn = false
    for k, v in pairs(RoleInfoSystem.aliasList) do
      self.srcAliasReddotStatus[v.id] = v.bReddot or false
    end
    self.reddotChanged = false
  end
  RoleInfoSystem:UpdateReddot()
  self:RefreshItemGrid()
  self.ScrollAliasId = -1
end
function Personalization_Title_UIBP:OnRefreshGridItem(widget, index)
  local data = self.ItemGrid:GetItemData(index)
  self:RefreshTitleWidget(widget, data)
end
function Personalization_Title_UIBP:ButtonOnClickedItem(widget, index)
  local data = self.ItemGrid:GetItemData(index)
  local lastWidget = self.ItemGrid:GetIndexOfWidget(self.firstButton)
  self.firstButton = index
  self:PlayAudio(sound_config.click)
  log(bWriteLog and "[BaseItem:_OnClickedItem] index = " .. tostring(index) .. " preIndex = " .. self.baseItemSelectIndex)
  local itemData = self.ItemGrid:GetItemData(index)
  if itemData == nil then
    log(bWriteLog and "[BaseItem:_OnClickedItem] itemData = nil")
  end
  self.jumpSelectItemId = nil
  local needUpdate = itemData and self:UpdateItemReddot(itemData, index)
  if self.baseItemSelectIndex == index and needUpdate then
    self.ItemGrid:RefreshItem(index, itemData)
  end
  self.baseItemSelectIndex = index
  self:HandleClickedItem(widget, index)
  if data.bReddot then
    widget.New:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
  else
    widget.New:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  end
  self:SetWidgetVisible(widget.Image_Time, type(data.aliasExpireTime) ~= "number" or data.aliasExpireTime > 1)
  self:RefreshLittleTitle(widget, data)
  if RoleInfoSystem.selectAliasId == data.id then
    widget.checkImage:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
    if lastWidget and lastWidget ~= widget then
      lastWidget.checkImage:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
    end
  else
    widget.checkImage:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  end
  self:UpdateItemPreview(itemData)
end
function Personalization_Title_UIBP:RefreshTitleWidget(widget, data)
  self:ClearState(widget)
  if data.bReddot then
    widget.New:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
  else
    widget.New:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  end
  self:SetWidgetVisible(widget.Image_Time, type(data.aliasExpireTime) ~= "number" or data.aliasExpireTime > 1)
  widget.Title_UIBP:SetAliasInfo(data.id or 0, data.aliasTitle or "", data.aliasNation or "", 0, data.rank_id or 0)
  self:RefreshLittleTitle(widget, data)
  if RoleInfoSystem.selectAliasId == data.id then
    widget.checkImage:SetWidgetVisibility(UEnums.ESlateVisibility.SelfHitTestInvisible)
  else
    widget.checkImage:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  end
  if data.aliasState == RoleInfoSystem.enum_Alias_State_Type.notHave then
    local lockOpacity = FLinearColor(1, 1, 1, 0.7)
    widget.Image_Lock:SetColorAndOpacity(lockOpacity)
  elseif data.aliasState == RoleInfoSystem.enum_Alias_State_Type.use then
    widget.icon:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
  end
  local isHas = data.aliasState ~= RoleInfoSystem.enum_Alias_State_Type.notHave
  local borderOpacity = isHas and FLinearColor(1, 1, 1, 1) or FLinearColor(1, 1, 1, 0.4)
  widget.Title_UIBP:SetColorAndOpacity(borderOpacity)
  if data.aliasState == RoleInfoSystem.enum_Alias_State_Type.notHave then
    widget.CanvasPanel_Lock:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
  elseif data.aliasState == RoleInfoSystem.enum_Alias_State_Type.use then
    widget.icon:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
  end
end
function Personalization_Title_UIBP:IsLoadAvatarScene()
  return true
end
function Personalization_Title_UIBP:UpdateItemReddot(itemData, index)
  if itemData.bReddot then
    itemData.bReddot = false
    RoleInfoSystem:RemoveReddot(itemData.id)
    self.reddotChanged = true
    return true
  end
  return false
end
function Personalization_Title_UIBP:HandleClickedItem(widget, index)
  local data = self.ItemGrid:GetItemData(index)
  RoleInfoSystem.aliasInfo = RoleInfoSystem.aliasList[index]
  RoleInfoSystem.currentChangeState = 0
  if not data then
    log(bWriteLog and "Personalization_Title_UIBP:HandleClickedItem. data is nil")
    return
  end
  RoleInfoSystem.selectAliasId = data.id
end
function Personalization_Title_UIBP:ShowNewBieTips()
end
function Personalization_Title_UIBP:JumpToGet()
  self:PlayAudio(sound_config.click)
  local cfg = CDataTable.GetTableData("AliasCfg", RoleInfoSystem.selectAliasId)
  if cfg ~= nil then
    log(bWriteLog and "cfg.AliasJumpUrl:" .. tostring(cfg.AliasJumpUrl))
    local JumpUtils = require("client.logic.store.jump_utils")
    local JumpUrl = cfg.AliasJumpUrl
    if JumpUtils.IsGameJumpUrl(cfg.AliasJumpUrl) then
      GlobalData.JumpGameUrl(cfg.AliasJumpUrl)
    else
      JumpUrl = tonumber(cfg.AliasJumpUrl)
    end
    log(bWriteLog and "JumpUrl:" .. tostring(JumpUrl))
    if JumpUrl == nil then
      log(bWriteLog and "Personalization_Title_UIBP:JumpToGet. JumpUrl is nil")
      return
    end
    if JumpUrl == self.CONST.JumpType.season then
      local season_year_util = require("client.logic.season_year.util.season_year_util")
      local seasonYearOpen = season_year_util.CheckFunctionIsOpen()
      if not seasonYearOpen then
        UIManager.ShowUI(UIManager.UI_Config.ui_season_anim_mgr)
      else
        local SeasonSystem = require("client.logic.season.logic_season")
        SeasonSystem.ShowSeasonHomepage()
      end
    elseif JumpUrl == self.CONST.JumpType.achievement then
      local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
      local index = RoleInfoMainSystem.Honor
      local openFrom = RoleInfoMainSystem.RoleInfoOpenFromType.Lobby
      local uid = DataMgr.roleData.uid
      local bShow = RoleInfoMainSystem.Show(index, openFrom, uid)
      if bShow == true then
        return
      end
    elseif JumpUrl == self.CONST.JumpType.pay then
      local RechargeSystem = require("client.logic.recharge.logic_recharge")
      RechargeSystem.OpenRechargeUI()
    elseif JumpUrl == self.CONST.JumpType.fightArea then
    elseif JumpUrl == self.CONST.JumpType.leagueGame then
    elseif JumpUrl == self.CONST.JumpType.rp_scription then
      local UnknowPassPrimeSystem = require("client.slua.logic.unknow_pass.logic_unknowpass_subscription")
      UnknowPassPrimeSystem.ShowSubScriptionUI()
    elseif JumpUrl == self.CONST.JumpType.club_home_page then
      local logic_community = require("client.slua.logic.community.logic_community")
      local uid = DataMgr.roleData.uid
      logic_community.GotoClubUserProfile(uid, logic_community.GameScene.AliasJump)
    elseif JumpUrl == self.CONST.JumpType.club_metal_detail then
      local logic_community = require("client.slua.logic.community.logic_community")
      local jump_url = "/home_page?show_medal_detail=1"
      logic_community.DoJumpCommunityUrl(jump_url, logic_community.GameScene.AliasJump)
    end
  end
  UIManager.CloseUI(UIManager.UI_Config.roleinfo_main)
end
function Personalization_Title_UIBP:UpdateSelectedItemInfo(itemData)
  if not RoleInfoSystem.aliasInfo or not next(RoleInfoSystem.aliasInfo) then
    self.UIRoot.WidgetSwitcher_States:SetActiveWidgetIndex(0)
    return
  end
  local aliasInfo = RoleInfoSystem.aliasInfo
  local param = self:GenCommonItemParam()
  param.itemID = itemData.id
  param.name = aliasInfo.aliasTitle
  param.desc = aliasInfo.aliasDesc
  local enum_Alias_State_Type = RoleInfoSystem.enum_Alias_State_Type
  if aliasInfo.aliasState == enum_Alias_State_Type.notHave then
    param.extraInfo = aliasInfo.aliasGetDesc
  else
    param.extraInfo = aliasInfo.aliasReceiveTime
    param.expireTime = aliasInfo.aliasExpireTime
  end
  local UIUtil = require("client.common.ui_util")
  local DefaultIcon = UIUtil.GetDefaultIcon(itemData.id)
  self:SetTexture(self.UIRoot.current_iconBG, aliasInfo.aliasIconUrlBig, {sync = false, defaultIcon = DefaultIcon})
  local tItemData
  if RoleInfoSystem.alias_list_info and RoleInfoSystem.alias_list_info[RoleInfoSystem.selectAliasId] then
    tItemData = RoleInfoSystem.alias_list_info[RoleInfoSystem.selectAliasId]
  end
  if aliasInfo.aliasState == enum_Alias_State_Type.notHave then
    local cfg = CDataTable.GetTableData("AliasCfg", RoleInfoSystem.selectAliasId)
    log(bWriteLog and "[mxiliu]Role_Info_title:RefreshJumpButton:cfg.AliasJumpUrl:" .. tostring(cfg.AliasJumpUrl))
    local JumpUtils = require("client.logic.store.jump_utils")
    local JumpUrl = cfg.AliasJumpUrl
    if JumpUtils.IsGameJumpUrl(cfg.AliasJumpUrl) then
      param.buttonStyle = ENUM_Button_Style.Go
    else
      JumpUrl = tonumber(cfg.AliasJumpUrl)
      log(bWriteLog and "JumpUrl:" .. tostring(JumpUrl))
      if JumpUrl == self.CONST.JumpType.getWayPop then
        param.buttonStyle = ENUM_Button_Style.GetWay
      elseif JumpUrl ~= self.CONST.JumpType.default then
        param.buttonStyle = ENUM_Button_Style.Go
      else
        param.buttonStyle = ENUM_Button_Style.NoYet
      end
    end
  elseif aliasInfo.aliasState == enum_Alias_State_Type.have then
    param.buttonStyle = ENUM_Button_Style.Use
  else
    param.buttonStyle = ENUM_Button_Style.Unload
  end
  if RoleInfoSystem.IsHasFeature(aliasInfo.id, ENUM_FeatureType.EnterBroadcast) then
    self.UIRoot.TextBlock_Name:SetText(LocUtil.GetLocalizeResStr(77679))
    self.UIRoot.CheckBox_Hide:SetWidgetVisibility(UEnums.ESlateVisibility.Visible)
  else
    self.UIRoot.CheckBox_Hide:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  end
  self.UIRoot.Title_UIBP:SetAliasInfo(aliasInfo.id or 0, aliasInfo.aliasTitle or "", aliasInfo.aliasNation or "", 0, aliasInfo.rank_id or 0)
  return param
end
function Personalization_Title_UIBP:ClearState(widget)
  widget.New:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  widget.Icon:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  widget.checkImage:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
  widget.CanvasPanel_Lock:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
end
function Personalization_Title_UIBP:RefreshLittleTitle(widget, data)
  local Quality = data.aliasQuality
  if not Quality then
    log_error(bWriteLog and "Role_Info_title:RefreshLittleTitle, Quality(" .. tostring(Quality) .. ") is illegal ")
  else
    local titleUIbp = widget.Title_UIBP
    for k, v in ipairs(LvQualityNames) do
      if titleUIbp[v] ~= nil then
        titleUIbp[v]:SetWidgetVisibility(k == Quality and UEnums.ESlateVisibility.Visible or UEnums.ESlateVisibility.Collapsed)
      end
    end
  end
end
function Personalization_Title_UIBP:UseAlias()
  self:PlayAudio(sound_config.click)
  RoleInfoSystem.currentChangeState = 1
  RoleInfoSystem.change_alias_req(RoleInfoSystem.selectAliasId, RoleInfoSystem.currentChangeState)
end
function Personalization_Title_UIBP:UsingAlis()
  self:PlayAudio(sound_config.click)
  RoleInfoSystem.currentChangeState = 1
  RoleInfoSystem.change_alias_req(0, 0)
end
function Personalization_Title_UIBP:NewbieButtonClicked()
  if self.NewbieGuideStep == 0 then
    self.UIRoot.NewbieTips1:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
    self.UIRoot.NewbieTips2:SetWidgetVisibility(UEnums.ESlateVisibility.HitTestInvisible)
    self.NewbieGuideStep = 1
  elseif self.NewbieGuideStep == 1 then
    self.UIRoot.NewbieTips1:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
    self.UIRoot.NewbieTips2:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
    self.UIRoot.Button_Newbie:SetWidgetVisibility(UEnums.ESlateVisibility.Collapsed)
    DataMgr.SetNewbieGuide(DataMgr.NEWBIE_GUIDE_MODULE_ID_TITLE, 1)
    self:UseAlias()
    self.NewbieGuideStep = 0
  end
end
function Personalization_Title_UIBP:GetItemList()
  RoleInfoSystem.isCheck = self.isCheckOwned
  RoleInfoSystem.CheckBoxSelect(self.isCheckOwned)
  return RoleInfoSystem.aliasList
end
function Personalization_Title_UIBP:IsUsingItem(itemData)
  return itemData.id == self.ScrollAliasId
end
function Personalization_Title_UIBP:JumpAndSelectItem(index)
  Personalization_Title_UIBP.__super.JumpAndSelectItem(self, index)
  self.firstButton = index
  self.ItemGrid:RefreshAllItems()
end
function Personalization_Title_UIBP:HandleButtonGo()
  local cfg = CDataTable.GetTableData("AliasCfg", RoleInfoSystem.selectAliasId)
  if cfg ~= nil then
    log(bWriteLog and "cfg.AliasJumpUrl:" .. tostring(cfg.AliasJumpUrl))
    local JumpUtils = require("client.logic.store.jump_utils")
    local JumpUrl = cfg.AliasJumpUrl
    if JumpUtils.IsGameJumpUrl(cfg.AliasJumpUrl) then
      GlobalData.JumpGameUrl(cfg.AliasJumpUrl)
      return
    else
      JumpUrl = tonumber(cfg.AliasJumpUrl)
    end
    log(bWriteLog and "JumpUrl:" .. tostring(JumpUrl))
    if JumpUrl == nil then
      log(bWriteLog and "Personalization_Title_UIBP:HandleButtonGo not jump cfg")
      return
    end
    if JumpUrl == self.CONST.JumpType.season then
      local season_year_util = require("client.logic.season_year.util.season_year_util")
      local seasonYearOpen = season_year_util.CheckFunctionIsOpen()
      if not seasonYearOpen then
        UIManager.ShowUI(UIManager.UI_Config.ui_season_anim_mgr)
      else
        local SeasonSystem = require("client.logic.season.logic_season")
        SeasonSystem.ShowSeasonHomepage()
      end
    elseif JumpUrl == self.CONST.JumpType.achievement then
      local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
      local index = RoleInfoMainSystem.Honor
      local openFrom = RoleInfoMainSystem.RoleInfoOpenFromType.Lobby
      local uid = DataMgr.roleData.uid
      RoleInfoMainSystem.Show(index, openFrom, uid)
    elseif JumpUrl == self.CONST.JumpType.pay then
      local RechargeSystem = require("client.logic.recharge.logic_recharge")
      RechargeSystem.OpenRechargeUI()
    elseif JumpUrl == self.CONST.JumpType.fightArea then
    elseif JumpUrl == self.CONST.JumpType.leagueGame then
    elseif JumpUrl == self.CONST.JumpType.rp_scription then
      local UnknowPassPrimeSystem = require("client.slua.logic.unknow_pass.logic_unknowpass_subscription")
      UnknowPassPrimeSystem.ShowSubScriptionUI()
    elseif JumpUrl == self.CONST.JumpType.club_home_page then
      local uid = DataMgr.roleData.uid
      local logic_community = require("client.slua.logic.community.logic_community")
      logic_community.GotoClubUserProfile(uid, logic_community.GameScene.AliasJump)
    elseif JumpUrl == self.CONST.JumpType.club_metal_detail then
      local logic_community = require("client.slua.logic.community.logic_community")
      local jump_url = "/home_page?show_medal_detail=1"
      logic_community.DoJumpCommunityUrl(jump_url, logic_community.GameScene.AliasJump)
    elseif JumpUrl == self.CONST.JumpType.getWayPop then
      local getWayData = self:GetButtonGetWayData()
      if not getWayData then
        log_error(bWriteLog and "Personalization_Title_UIBP:HandleButtonGo not jump cfg data")
        return
      end
      local content = {}
      for i, v in pairs(getWayData.showImagePaths) do
        local temp = {
          description = getWayData.descriptions[i] or "",
          imagePath = v
        }
        table.insert(content, temp)
      end
      local params = {
        title = LocUtil.GetLocalizeResStr(67381),
        contentList = {}
      }
      table.insert(params.contentList, content)
      UIManager.ShowUI(UIManager.UI_Config.Common_Announcement_Medium_UIBP, params)
    elseif JumpUrl >= BP_ENUM_MODULE_LOBBY then
      local jump_url = "game://?module=" .. tostring(JumpUrl)
      GlobalData.JumpUrl(jump_url)
    end
  end
end
function Personalization_Title_UIBP:GetButtonGetWayData()
  local cfg = CDataTable.GetTableData("AliasGetWayConfig", RoleInfoSystem.selectAliasId)
  if not cfg then
    log(bWriteLog and "Personalization_Title_UIBP:HandleButtonGetWay not get way cfg")
    return nil
  end
  local StringUtil = require("common.string_util")
  local getWayImages = StringUtil.Split(cfg.GetWayImagePaths, ";")
  local getWayTexts = StringUtil.SplitToNum(cfg.GetWayTexts, ";")
  local t = {showImagePaths = getWayImages, descriptions = getWayTexts}
  log_tree(bWriteLog and "Personalization_Title_UIBP:HandleButtonGetWay", t)
  return t
end
function Personalization_Title_UIBP:HandleButtonUse()
  RoleInfoSystem.currentChangeState = 1
  self.firstButton = 1
  RoleInfoSystem.change_alias_req(RoleInfoSystem.selectAliasId, RoleInfoSystem.currentChangeState)
end
function Personalization_Title_UIBP:HandleButtonUnload()
  RoleInfoSystem.currentChangeState = 1
  RoleInfoSystem.change_alias_req(0, 0)
end
function Personalization_Title_UIBP:HandleButtonShare()
  if RoleInfoSystem.selectAliasId and RoleInfoSystem.aliasInfo then
    local time_util = require("client.common.time_util")
    local getTime = time_util.FormatTime_YMD(RoleInfoSystem.aliasInfo.aliasReceiveTimeCompare)
    AliasData = {
      aliasGetTime = getTime,
      aliasTitle = RoleInfoSystem.aliasInfo.aliasTitle,
      aliasId = RoleInfoSystem.aliasInfo.id,
      aliasType = RoleInfoSystem.aliasInfo.aliasType,
      aliasNation = RoleInfoSystem.aliasInfo.aliasNation,
      aliasQuality = RoleInfoSystem.aliasInfo.aliasQuality,
      aliasDesc = RoleInfoSystem.aliasInfo.aliasDesc,
      aliasIconUrl = RoleInfoSystem.aliasInfo.aliasIconUrl,
      aliasIconUrlBig = RoleInfoSystem.aliasInfo.aliasIconUrlBig
    }
    RoleInfoSystem.ShowShareAlias(RoleInfoSystem.selectAliasId, AliasData)
  else
    log(bWriteLog and "[v_zhaopwei]: no AliasData")
  end
  local ShareMgr = require("client.logic.share.share_logic")
  ShareMgr.ShareBtnReq(1, ShareBtnTLogShareTypeDefine.ShareAfterWinningTheTitle, nil, nil)
end
function Personalization_Title_UIBP:UpdateIsShowAliasEnterBroadcast(_, _, isShow)
  self.UIRoot.CheckBox_Hide:SetIsChecked(not isShow)
end
function Personalization_Title_UIBP:OnClickCheckBoxHide(isCheck)
  self:PlayAudio(sound_config.click)
  local CharacterHandler = require("client.network.Protocol.CharacterHandler")
  if isCheck then
    CharacterHandler.send_set_is_show_enter_broadcast_req(false)
  else
    CharacterHandler.send_set_is_show_enter_broadcast_req(true)
  end
end
local class = require("class")
local superCls = require("client.slua.umg.roleInfoNew.Personalization_BaseItem_UIBP")
local CUITemplate = class(superCls, nil, Personalization_Title_UIBP)
return CUITemplate
