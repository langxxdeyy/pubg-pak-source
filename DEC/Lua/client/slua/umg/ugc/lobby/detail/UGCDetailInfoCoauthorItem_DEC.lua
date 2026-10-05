local UGCDetailInfoCoauthorItem = {}
function UGCDetailInfoCoauthorItem:ctor()
end
function UGCDetailInfoCoauthorItem:OnInitialize()
end
function UGCDetailInfoCoauthorItem:RegistEvents()
  self:AddControlEventByControl(self.UIRoot.Common_Avatar_BP, "OnClickItemCallback", self.OnAuthorClick, self)
end
function UGCDetailInfoCoauthorItem:OnPostInitialize()
  UGCDetailInfoCoauthorItem.__super.OnPostInitialize(self)
end
function UGCDetailInfoCoauthorItem:OnClose()
end
function UGCDetailInfoCoauthorItem:InitAvatarView(authorInfo)
  self.authorInfo = authorInfo
  self.UIRoot.TextBlock_AuthorName:SetText(self.authorInfo.nickName)
  self.UIRoot.Common_Avatar_BP:InitView(1, self.authorInfo.uid, self.authorInfo.picUrl, nil, self.authorInfo.cur_avatar_box_id, nil)
  self.UIRoot.Common_Avatar_BP:SetButtonEnabled(true)
end
function UGCDetailInfoCoauthorItem:OnAuthorClick(widget, index)
  local audio_util = require("client.common.audio_util")
  audio_util.PlayAudio(sound_config.click_v1)
  local Uid = self.authorInfo.uid
  local bCanShowGuest = true
  if Uid == tonumber(DataMgr.roleData.uid) then
    local LogicFitVersionDownload = require("client.slua.logic.download.fit.logic_fitVersion_download")
    if LogicFitVersionDownload.IfNotFitLobbyResDownloadedShowWindow() then
      return
    end
    if IsWoWEditor then
      UIManager.AndroidBackToLobby()
    else
      UIManager.ShowUI(UIManager.UI_Config.ugc_mine_main)
    end
  else
    local RoleInfoMainSystem = require("client.logic.roleinfo.logic_new_roleinfo")
    bCanShowGuest = RoleInfoMainSystem.Show(RoleInfoMainSystem.WOW, RoleInfoMainSystem.RoleInfoOpenFromType.WoWItem, Uid)
  end
  if bCanShowGuest == true then
    EventSystem:postEvent(EVENTTYPE_UGC, EVENTID_UGC_SHOW_GUEST)
  end
end
local class = require("class")
local ui_base = require("client.slua_ui_framework.base")
local CUI_UGC_Detail_Info = class(ui_base, nil, UGCDetailInfoCoauthorItem)
return CUI_UGC_Detail_Info
