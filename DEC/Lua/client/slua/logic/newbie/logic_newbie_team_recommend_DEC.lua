local logic_newbie_team_recommend = {}
function logic_newbie_team_recommend:ctor()
end
function logic_newbie_team_recommend:DefineAndResetData()
  self.bInit = false
  self.mentor_list = nil
  self.newbie_list = nil
  self.uid_2_last_invite_time = {}
end
function logic_newbie_team_recommend:RegistEvents()
  self:AddCommonEvent(EVENTTYPE_MENTOR, EVENTID_MENTOR_RECOMMEND, self.OnMentorRecommend, self)
end
function logic_newbie_team_recommend:NeedMentor2NewbieChannelTip()
  local PlayerPrefsSystem = require("client.logic.LogicPlayerPrefs.playerprefs")
  local data = PlayerPrefsSystem.LoadFileToTable_N(PlayerPrefsSystem.ePlayerPrefsType.eMentorToNewbieChannelTip) or {}
  if not data or not next(data) then
    return true
  end
  local TimeUtil = require("client.common.time_util")
  local last_time = data.last_time or 0
  local svr_time = TimeUtil.GetServerTimeInSec()
  if TimeUtil.IsSameDay(svr_time, last_time) then
    return false
  end
  return true
end
function logic_newbie_team_recommend:RecordMentor2NewbieChannelLastTipTime()
  local PlayerPrefsSystem = require("client.logic.LogicPlayerPrefs.playerprefs")
  local data = PlayerPrefsSystem.LoadFileToTable_N(PlayerPrefsSystem.ePlayerPrefsType.eMentorToNewbieChannelTip) or {}
  local TimeUtil = require("client.common.time_util")
  data.last_time = TimeUtil.GetServerTimeInSec()
  PlayerPrefsSystem.SaveTableToFile_N(data, PlayerPrefsSystem.ePlayerPrefsType.eMentorToNewbieChannelTip)
end
function logic_newbie_team_recommend:NeedTeamPlatformGuide()
  log(bWriteLog and "logic_newbie_team_recommend:NeedTeamPlatformGuide")
  local PlayerPrefsSystem = require("client.logic.LogicPlayerPrefs.playerprefs")
  local data = PlayerPrefsSystem.LoadFileToTable_N(PlayerPrefsSystem.ePlayerPrefsType.eNewbieTeamPlatformGuide) or {}
  if data.hasGuide then
    return false
  end
  return true
end
function logic_newbie_team_recommend:ClearTeamPlatformGuide()
  log(bWriteLog and "logic_newbie_team_recommend:ClearTeamPlatformGuide")
  local PlayerPrefsSystem = require("client.logic.LogicPlayerPrefs.playerprefs")
  local data = PlayerPrefsSystem.LoadFileToTable_N(PlayerPrefsSystem.ePlayerPrefsType.eNewbieTeamPlatformGuide) or {}
  data.hasGuide = true
  PlayerPrefsSystem.SaveTableToFile_N(data, PlayerPrefsSystem.ePlayerPrefsType.eNewbieTeamPlatformGuide)
end
function logic_newbie_team_recommend:CanTeamInvite(uid)
  local TimeUtil = require("client.common.time_util")
  local last_invite_time = self.uid_2_last_invite_time[uid] or 0
  local svr_time = TimeUtil.GetServerTimeInSec()
  if svr_time - last_invite_time < 60 then
    log(bWriteLog and "logic_newbie_team_recommend:CanTeamInvite false")
    return false
  end
  log(bWriteLog and "logic_newbie_team_recommend:CanTeamInvite true")
  return true
end
function logic_newbie_team_recommend:OnMentorRecommend(event_type, event_id, data)
  self:proc_get_mentor_rsp(data)
end
function logic_newbie_team_recommend:send_get_mentor_req(count)
  local MentorSystem = require("client.slua.logic.mentor.logic_mentor")
  local replace_uid_list = {}
  if self.mentor_list then
    for _, v in ipairs(self.mentor_list) do
      table.insert(replace_uid_list, v.uid)
    end
  end
  if self.bInit then
    log_format(bWriteLog and "logic_newbie_team_recommend:send_get_mentor_req count: %s", count)
    MentorSystem.mentor_recommend_req(count, MentorSystem.recommend_req_from.FromMentorChatChannel, replace_uid_list, true)
  else
    local callback = function()
      self.bInit = true
      MentorSystem.mentor_recommend_req(count, MentorSystem.recommend_req_from.FromMentorChatChannel, replace_uid_list, true)
    end
    log(bWriteLog and "logic_newbie_team_recommend:send_get_mentor_req init count: %s", count)
    MentorSystem.set_mentor_identity_req(1, callback)
  end
end
function logic_newbie_team_recommend:proc_get_mentor_rsp(mentor_list)
  log_tree(bWriteLog and "logic_newbie_team_recommend:proc_get_mentor_rsp ", mentor_list)
  if mentor_list == nil then
    return
  end
  self.mentor_list = mentor_list
  local callback = function(profiles)
    EventSystem:postEvent(EVENTTYPE_NEWBIE_TEAM_RECOMMEND, EVENTID_NEWBIE_TEAM_RECOMMEND_GET_MENTOR_RSP)
  end
  local uid_list = {}
  for _, v in ipairs(mentor_list) do
    table.insert(uid_list, v.uid)
  end
  local logic_profile_get_wrap = require("client.slua.logic.user.profile.logic_profile_get_wrap")
  logic_profile_get_wrap.GetNormalProfiles(uid_list, callback, Enum_PROFILE_REPORT_CFG.NEWBIE_CHAT_CHANNEL, 0, true)
end
function logic_newbie_team_recommend:send_mentor_recommend_mentee_req(count)
  log_format(bWriteLog and "logic_newbie_team_recommend:send_mentor_recommend_mentee_req, count: %s", count)
  local MentorHandler = require("client.network.Protocol.MentorHandler")
  MentorHandler.send_mentor_recommend_mentee_req(count)
end
function logic_newbie_team_recommend:proc_mentor_recommend_mentee_rsp(err_code, search_res)
  log_tree(bWriteLog and "logic_newbie_team_recommend:proc_mentor_recommend_mentee_rsp ", {err_code, search_res})
  if err_code ~= 0 then
    return
  end
  self.newbie_list = search_res or {}
  local callback = function(profiles)
    EventSystem:postEvent(EVENTTYPE_NEWBIE_TEAM_RECOMMEND, EVENTID_NEWBIE_TEAM_RECOMMEND_GET_NEWBIE_RSP)
  end
  local uid_list = {}
  for _, v in ipairs(search_res) do
    table.insert(uid_list, v.uid)
  end
  local logic_profile_get_wrap = require("client.slua.logic.user.profile.logic_profile_get_wrap")
  logic_profile_get_wrap.GetNormalProfiles(uid_list, callback, Enum_PROFILE_REPORT_CFG.NEWBIE_CHAT_CHANNEL, 0, true)
end
function logic_newbie_team_recommend:team_invite_request(uid, from)
  log_format(bWriteLog and "logic_newbie_team_recommend:team_invite_request, uid: %s, from: %s", uid, from)
  if not self:CanTeamInvite(uid) then
    return
  end
  local TeamUpNewSystem = require("client.slua.logic.teamup.logic_team_up")
  TeamUpNewSystem.team_invite_request(uid, from)
  local TimeUtil = require("client.common.time_util")
  self.uid_2_last_invite_time[uid] = TimeUtil.GetServerTimeInSec()
end
local class = require("class")
local CModuleBase = require("client.module_framework.ModuleBase")
local Clogic_newbie_team_recommend = class(CModuleBase, nil, logic_newbie_team_recommend)
return Clogic_newbie_team_recommend
