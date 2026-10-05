local UCG_WoWPass_PassportFile_UIBP = {}
function UCG_WoWPass_PassportFile_UIBP:ctor()
end
function UCG_WoWPass_PassportFile_UIBP:OnInitialize()
  self.LoopScrollGrid_0 = self:InitChildClassScrollBox(self.UIRoot.LoopScrollGrid_0, "client.slua.umg.ugc.WoWPass.Item.UGC_WoWPass_PassportFile_Item_UIBP")
end
function UCG_WoWPass_PassportFile_UIBP:RegistEvents()
  self:AddOnClickedEventByControl(self.UIRoot.Common_System_Close_UIBP_C_1.Button_Close, self.OnClickButton_Close, self)
  self:AddCommonEvent(EVENTTYPE_UGC, EVENTID_UGC_WOW_PASS_RECORD_RSP, self.OnPassRecordRsp, self)
  self:AddControlEventByControl(self.UIRoot.Common_Avatar_BP, "OnClickItemCallback", self.OnClickHeadCallback, self)
end
function UCG_WoWPass_PassportFile_UIBP:OnPostInitialize()
  self.UIRoot.Common_Empty_UIBP.TextBlock_Emtpy:SetText(LocUtil.GetLocalizeResStr(1050555))
  self:UpdatePlayerInfo()
  self:RequestRecordData()
end
function UCG_WoWPass_PassportFile_UIBP:OnClose()
end
function UCG_WoWPass_PassportFile_UIBP:OnClickButton_Close()
  self:PlayAudio(sound_config.close)
  self:CloseSelf()
end
function UCG_WoWPass_PassportFile_UIBP:OnClickHeadCallback()
  self:PlayAudio(sound_config.click_v1)
  local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
  if RoleInfoMainSystem.Show(RoleInfoMainSystem.Segment, RoleInfoMainSystem.RoleInfoOpenFromType.WOWPass, DataMgr.roleData.uid) then
    self:CloseSelf()
  end
end
function UCG_WoWPass_PassportFile_UIBP:OnPassRecordRsp(_, _, ErrorCode, RecordList)
  log(bWriteLog and "UCG_WoWPass_PassportFile_UIBP:OnPassRecordRsp ErrorCode=" .. tostring(ErrorCode))
  if ErrorCode ~= 0 then
    self:ShowEmptyState(true)
    return
  end
  self:UpdatePlayerInfo(RecordList)
  self:RefreshRecordList(RecordList)
end
function UCG_WoWPass_PassportFile_UIBP:UpdatePlayerInfo(RecordList)
  if not self.UIRoot then
    return
  end
  local NickName = DataMgr.roleData.nickName
  local HeadUrl = DataMgr.roleData.headIconUrl
  local HeadFrameId = DataMgr.roleData.cur_avatar_box_id
  self:SetWidgetVisible(self.UIRoot.Button_Help, false)
  self.UIRoot.Common_System_Close_UIBP_C_1.TextBlock_Title:SetText(LocUtil.GetLocalizeResStr(1050527))
  self.UIRoot.TextBlock_PlayName:SetText(NickName)
  self.UIRoot.Common_Avatar_BP:InitView(1, DataMgr.roleData.uid, HeadUrl, nil, HeadFrameId, nil)
end
function UCG_WoWPass_PassportFile_UIBP:RequestRecordData()
  local logic_ugc_WOWPass = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.logic_ugc_WOWPass)
  if not logic_ugc_WOWPass then
    self:ShowEmptyState(true)
    return
  end
  local CachedList = logic_ugc_WOWPass:GetPassRecordList()
  if CachedList then
    self:UpdatePlayerInfo(CachedList)
    self:RefreshRecordList(CachedList)
  else
    self:ShowEmptyState(false)
  end
  logic_ugc_WOWPass:ReqPassRecordInfo()
end
function UCG_WoWPass_PassportFile_UIBP:RefreshRecordList(RecordList)
  if not self.UIRoot or not self.LoopScrollGrid_0 then
    return
  end
  local DetailList = RecordList and RecordList.details
  local HasData = DetailList and next(DetailList) ~= nil
  self:ShowEmptyState(not HasData)
  if not HasData then
    self.LoopScrollGrid_0:SetData({})
    return
  end
  local SortedList = {}
  for SeasonId, Record in pairs(DetailList) do
    table.insert(SortedList, {
      season_id = tonumber(SeasonId) or 0,
      season_name = Record.season_name,
      season_level = Record.season_level,
      pass_type = Record.pass_type
    })
  end
  self.LoopScrollGrid_0:SetData(SortedList)
end
function UCG_WoWPass_PassportFile_UIBP:ShowEmptyState(bEmpty)
  if not self.UIRoot then
    return
  end
  self.UIRoot.WidgetSwitcher_0:SetActiveWidgetIndex(bEmpty and 1 or 0)
end
local class = require("class")
local ui_base = require("client.slua_ui_framework.base")
return class(ui_base, nil, UCG_WoWPass_PassportFile_UIBP)
