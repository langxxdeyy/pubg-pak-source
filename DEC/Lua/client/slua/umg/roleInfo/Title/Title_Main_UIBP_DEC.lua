local Title_Main_UIBP = {}
function Title_Main_UIBP:ctor(_, uid)
  self.EnterUid = uid
  self.maxShowCount = 10
end
function Title_Main_UIBP:OnInitialize()
  Title_Main_UIBP.__super.OnInitialize(self)
  self.WearTitleButton = self.UIRoot.Button_0
  self.ShareButton = self.UIRoot.Button_1
  self.HaveAliasCount = self.UIRoot.TextBlock_0
  self.AliasCountText = self.UIRoot.TextBlock_1
  self.WearTitleText = self.UIRoot.TextBlock_2
  self.Adaptation = self.UIRoot.Spacer_1
end
function Title_Main_UIBP:RegistEvents()
  Title_Main_UIBP.__super.RegistEvents(self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_0, self.OnButton_SelectAlias, self)
  self:AddOnClickedEventByControl(self.UIRoot.Button_1, self.OnButton_Share, self)
  for i = 1, self.maxShowCount do
    local panel = self.UIRoot["Title_Main_Item_" .. i]
    if panel then
      self:AddControlEventByControl(panel.Button_0, "OnClicked", self.OnButton_ClearClick, self, i, panel)
      self:AddControlEventByControl(panel.Button_Add, "OnClicked", self.OnButton_AddClick, self, i, panel)
    end
  end
  self:AddCommonEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_LOBBY_SOCIAL_ALIAS_LIST, self.OnRefreshHaveAliasCount, self)
  self:AddCommonEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_HONOR_ALIAS_GET_SELECT_ALIAS_LIST, self.OnRefreshShowAliasData, self)
  self:AddCommonEvent(EVENTTYPE_LOBBY_SOCIAL, EVENTID_HONOR_ALIAS_CLICK_SHARE_ALIAS_LIST_UPDATE_BUTTON, self.UpdateButtonShow, self)
end
function Title_Main_UIBP:OnPostInitialize()
  Title_Main_UIBP.__super.OnPostInitialize(self)
  self:UpdateUI()
end
function Title_Main_UIBP:UpdateUI()
  self.HaveAliasCount:SetText(tostring(0))
  for i = 3, 6 do
    if self.UIRoot["TextBlock_Q" .. i] then
      self.UIRoot["TextBlock_Q" .. i]:SetText(tostring(0))
    end
  end
  for i = 1, self.maxShowCount do
    local panel = self.UIRoot["Title_Main_Item_" .. i]
    if panel then
      self:SetWidgetVisible(panel.Button_Add, true, true)
      panel.WidgetSwitcher_0:SetActiveWidgetIndex(1)
      self:SetWidgetVisible(panel.Button_0, false)
      self:SetWidgetVisible(panel.Title_Big_UIBP, false)
    end
  end
  local logic_roleInfo_honor_title_select = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_roleInfo_honor_title_select)
  logic_roleInfo_honor_title_select:get_show_alias_req()
  self:PlayUserWidgetAnimation(self.UIRoot.Animation_FadeIn, 0, 1, 0, 1)
  self:PlayUserWidgetAnimation(self.UIRoot.Animation_Loop, 0, 0, 0, 1)
  self:SetWidgetVisible(self.WearTitleButton, true, true)
  self:SetWidgetVisible(self.ShareButton, true, true)
  self.AliasCountText:SetText(LocUtil.GetLocalizeResStr(62342))
  self.WearTitleText:SetText(LocUtil.GetLocalizeResStr(62274))
end
function Title_Main_UIBP:OnClose()
  Title_Main_UIBP.__super.OnClose(self)
  log(bWriteLog and "Title_Main_UIBP:OnClose() and SaveShowAliasData")
  local logic_roleInfo_honor_title_select = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_roleInfo_honor_title_select)
  logic_roleInfo_honor_title_select:SaveShowAliasData()
end
function Title_Main_UIBP:OnRefreshHaveAliasCount()
  local logic_roleInfo_honor_title_select = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_roleInfo_honor_title_select)
  local havedAliasList = logic_roleInfo_honor_title_select:GetHavedAliasList()
  local count = #havedAliasList
  log(bWriteLog and "[wzp] Title_Main_UIBP:OnRefreshHaveAliasCount havedAliasList = " .. tostring(count))
  self.HaveAliasCount:SetText(tostring(count))
  local qualityCount = {}
  for k, v in ipairs(havedAliasList) do
    local quality = v.aliasQuality
    if qualityCount[quality] then
      qualityCount[quality] = qualityCount[quality] + 1
    else
      qualityCount[quality] = 1
    end
  end
  for i = 3, 6 do
    local textBlock = self.UIRoot["TextBlock_Q" .. i]
    if textBlock then
      self:SetWidgetVisible(textBlock, true, false)
      textBlock:SetText(tostring(qualityCount[i] or 0))
    end
  end
end
function Title_Main_UIBP:OnRefreshShowAliasData()
  local logic_roleInfo_honor_title_select = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_roleInfo_honor_title_select)
  local selectData = logic_roleInfo_honor_title_select:GetSaveSelectAliasList()
  self:RefreshShowTitleItemData(selectData)
  local logic_roleinfo_title = require("client.slua.logic.roleInfo.logic_roleinfo_title")
  logic_roleinfo_title.get_alias_list()
end
function Title_Main_UIBP:RefreshShowTitleItemData(SaveSelectAliasList)
  for i = 1, self.maxShowCount do
    local panel = self.UIRoot["Title_Main_Item_" .. i]
    if panel then
      self:SetWidgetVisible(panel.Button_Add, true, true)
      local alias_id
      for key, value in pairs(SaveSelectAliasList) do
        if value.order_id == i then
          alias_id = key
          break
        end
      end
      if alias_id then
        self:SetWidgetVisible(panel.Title_Big_UIBP, true)
        self:SetWidgetVisible(panel.Button_0, true, true)
        panel.WidgetSwitcher_0:SetActiveWidgetIndex(0)
        local cfg = CDataTable.GetTableData("AliasCfg", alias_id)
        if cfg ~= nil then
          local AliasData = {
            aliasId = alias_id,
            aliasIconUrl = cfg.AliasIconPath,
            aliasIconUrlBig = cfg.AliasIconPathBig,
            aliasTitle = FuncUtil.Gen_title(alias_id, SaveSelectAliasList[alias_id].rank, SaveSelectAliasList[alias_id].ext_info, SaveSelectAliasList[alias_id].rank_id),
            aliasQuality = cfg.AliasQuality,
            aliasDesc = cfg.AliasDesc,
            aliasNation = SaveSelectAliasList[alias_id].nation,
            aliasType = cfg.AliasType,
            aliasSmallIconUrl = cfg.AliasIconPathSmall,
            rank_id = SaveSelectAliasList[alias_id].rank_id
          }
          local UIUtil = require("client.common.ui_util")
          UIUtil.SetTitleItem(panel.Title_Big_UIBP, AliasData)
        end
      else
        panel.WidgetSwitcher_0:SetActiveWidgetIndex(1)
        self:SetWidgetVisible(panel.Button_0, false)
        self:SetWidgetVisible(panel.Title_Big_UIBP, false)
      end
    end
  end
end
function Title_Main_UIBP:OnButton_SelectAlias()
  self:PlayAudio(sound_config.click)
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  local PersonalizationConst = require("client.slua.umg.roleInfoNew.PersonalizationConst")
  if RoleInfoMainSystem.Show(RoleInfoMainSystem.Personalize, RoleInfoMainSystem.RoleInfoOpenFromType.Null, DataMgr.roleData.uid, {
    personalInfo = {
      openTab = PersonalizationConst.ENUM_Type.Alias
    },
    subTabID = nil
  }) then
    self:CloseSelf()
  end
end
function Title_Main_UIBP:OnButton_Share()
  self:PlayAudio(sound_config.click)
  local logic_roleInfo_honor_title_select = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_roleInfo_honor_title_select)
  logic_roleInfo_honor_title_select:ShareShowAliasList()
  local ShareMgr = require("client.logic.share.share_logic")
  ShareMgr.ShareBtnReq(1, ShareBtnTLogShareTypeDefine.PersonalHonorAlias, nil, nil)
end
function Title_Main_UIBP:OnButton_ClearClick(Index, Widget)
  self:PlayAudio(sound_config.click)
  local logic_roleInfo_honor_title_select = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_roleInfo_honor_title_select)
  if logic_roleInfo_honor_title_select:ClearSelectAliasDataByIndex(Index) then
    Widget.WidgetSwitcher_0:SetActiveWidgetIndex(1)
    self:SetWidgetVisible(Widget.Title_Big_UIBP, false)
    self:SetWidgetVisible(Widget.Button_0, false)
    self:SetWidgetVisible(Widget.Button_Add, true, true)
  end
end
function Title_Main_UIBP:OnButton_AddClick(Index, Widget)
  self:PlayAudio(sound_config.click)
  log(bWriteLog and "[wzp] Title_Main_UIBP:OnButton_AddClick index = " .. tostring(Index))
  UIManager.ShowUI(UIManager.UI_Config.Title_Select_Popup_UIBP, Index)
end
function Title_Main_UIBP:UpdateButtonShow(_, _, isShow)
  self:SetWidgetVisible(self.WearTitleButton, isShow, isShow)
  self:SetWidgetVisible(self.ShareButton, isShow, isShow)
  local logic_roleInfo_honor_title_select = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_roleInfo_honor_title_select)
  local selectData = logic_roleInfo_honor_title_select:GetSaveSelectAliasList()
  for i = 1, self.maxShowCount do
    local panel = self.UIRoot["Title_Main_Item_" .. i]
    if panel then
      if isShow then
        local alias_id
        for key, value in pairs(selectData) do
          if value.order_id == i then
            alias_id = key
            break
          end
        end
        if alias_id then
          self:SetWidgetVisible(panel.Button_0, true, true)
        else
          self:SetWidgetVisible(panel.Button_0, false)
        end
      else
        self:SetWidgetVisible(panel.Button_0, false)
      end
    end
  end
  self:SetWidgetVisible(self.Adaptation, isShow)
end
local class = require("class")
local ui_base = require("client.slua_ui_framework.base")
local CTitle_Main_UIBP = class(ui_base, nil, Title_Main_UIBP)
return CTitle_Main_UIBP
