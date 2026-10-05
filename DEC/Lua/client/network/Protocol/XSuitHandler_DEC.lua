local NetManager = require("client.network.comm.NetManager")
local XSuitHandler = {}
function XSuitHandler.send_get_gold_dress_activity_req()
  NetManager.SendPkg(746699151)
end
function XSuitHandler.on_get_gold_dress_activity_rsp(err_code, draw_info)
  local logic_xsuit_activity = ModuleManager.GetModule(ModuleManager.JumpModuleConfig.logic_xsuit_activity)
  logic_xsuit_activity:OnGetDrawActivityInfo(err_code, draw_info)
end
function XSuitHandler.send_draw_gold_dress_req(cost_times, currency_id, voucher_id, pool_id)
  local QRcodeRestrictManager = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.QRcodeRestrictManager)
  if QRcodeRestrictManager:CheckUCRestrict() then
    return
  end
  EventSystem:postEvent(EVENTTYPE_ACTIVITY, EVENTID_SPIN_STOP_COIN_UPDATE)
  NetManager.SendPkg(1099270815, cost_times, currency_id, voucher_id, pool_id)
end
function XSuitHandler.on_draw_gold_dress_rsp(err_code, item_list, decompose_list, pool_accumulate_info, pool_draw_times, is_can_first, accumulate_coin_count)
  log(bWriteLog and "XSuitHandler.on_draw_gold_dress_rsp err_code = " .. tostring(err_code))
  local LogicXSuit = require("client.slua.logic.XSuit.logic_xsuit")
  if err_code ~= 0 then
    ShowNotice(err_code)
    LogicXSuit.ShowErrCode(err_code)
    return
  end
  if err_code == 0 then
    log_tree("XSuitHandler.on_draw_gold_dress_rsp = ", item_list)
    local logic_xsuit_activity = ModuleManager.GetModule(ModuleManager.JumpModuleConfig.logic_xsuit_activity)
    logic_xsuit_activity:SetAccumulateStateInfo(pool_accumulate_info)
    logic_xsuit_activity:SetAccumulateDrawTime(pool_draw_times)
    logic_xsuit_activity:SetAccumulateCoinCount(accumulate_coin_count)
    log(bWriteLog and "xcc XSuitHandler.on_draw_gold_dress_rsp is_can_first" .. tostring(is_can_first))
    logic_xsuit_activity:SetIsFirstDiscount(is_can_first)
    XSuitHandler.send_get_gold_dress_activity_req()
    EventSystem:postEvent(EVENTTYPE_ACTIVITY, EVENTID_SPIN_STOP_COIN_UPDATE_TIMER)
    EventSystem:postEvent(EVENTTYPE_XSUIT, EVENTID_XSUIT_SPIN_DRAW_RSP, item_list, decompose_list)
  end
end
function XSuitHandler.send_get_rise_star_info_req(id)
  NetManager.SendPkg(936041735, id)
end
function XSuitHandler.on_get_rise_star_info_rsp(err_code, open, rise_star_info, unlock_info, rise_star_info_new, unlock_info_new, Common2ActiveMaterial, UpgradeDiscount)
  if err_code ~= 0 then
    log(bWriteLog and "XSuitHandler.on_get_rise_star_info_rsp error code = " .. tostring(err_code))
    return
  end
  local LogicXSuit = require("client.slua.logic.XSuit.logic_xsuit")
  LogicXSuit.SetXSuitCommonInfo(open, rise_star_info_new.star_info, unlock_info_new.unlock_info, rise_star_info_new.active_branch_info, Common2ActiveMaterial, UpgradeDiscount)
  if LogicXSuit._PendingElimOverrideRecheckOnLevel6 then
    LogicXSuit._PendingElimOverrideRecheckOnLevel6 = false
    LogicXSuit.EliminationKingClothOverrideEnabled = nil
    LogicXSuit._FetchingEliminationKingOverride = true
    XSuitHandler.send_gold_dress_get_eliminate_req()
  end
end
function XSuitHandler.send_rise_star_req(id, item_id, branch_id)
  NetManager.SendPkg(1249575219, id, item_id, branch_id)
end
function XSuitHandler.on_rise_star_rsp(err_code, cur_level, period, branch_id)
  log(bWriteLog and "on_rise_star_rsp err_code = " .. tostring(err_code) .. " || cur_level = " .. tostring(cur_level))
  local LogicXSuit = require("client.slua.logic.XSuit.logic_xsuit")
  if err_code ~= 0 then
    LogicXSuit.ShowErrCode(err_code)
    return
  end
  XSuitHandler.send_get_rise_star_info_req()
  if cur_level == 6 then
    local ItemResID = LogicXSuit.GetItemIDByLevel(period, 6, branch_id)
    if ItemResID and LogicXSuit.HasEliminationKingOverrideAvailable(ItemResID, 6) then
      LogicXSuit._PendingElimOverrideRecheckOnLevel6 = true
    end
  end
  LogicXSuit.ShowUpgradeSuccessUI(cur_level, period, branch_id)
  LogicXSuit.SetXSuitLevel(cur_level, period, branch_id)
  EventSystem:postEvent(EVENTTYPE_GOLDEN_SUIT, EVENTID_GOLDEN_SUIT_UPGRADE_SUCCESS, cur_level, period, branch_id)
end
function XSuitHandler.send_change_emtion_action_req(action_id)
  log(bWriteLog and "XSuitHandler.send_change_emtion_action_req id = " .. tostring(action_id))
  NetManager.SendPkg(980620199, action_id)
end
function XSuitHandler.on_change_emtion_action_rsp(err_code)
end
function XSuitHandler.on_notify_change_emtion_action(inviter_id, action_id)
  log(bWriteLog and "XSuitHandler.on_notify_change_emtion_action inviter_id = " .. tostring(inviter_id) .. " || action_id = " .. tostring(action_id))
  if IsWoWEditor then
    return
  end
  local LogicXSuit = require("client.slua.logic.XSuit.logic_xsuit")
  if action_id == 12215504 then
    local wardrobe_data = require("client.slua.logic.wardrobe.wardrobe_data")
    local tRoleWear = AvatarData.GetRoleWear()
    for _, v in pairs(tRoleWear) do
      local itemInfo = wardrobe_data:GetHallDepotItemDataByInsID(v)
      if itemInfo then
        local id = itemInfo.resID
        if id and LogicXSuit.IsMuNaiYiBlockItem(id) then
          log(bWriteLog and "XSuitHandler.on_notify_change_emtion_action IsMuNaiYiBlockItem!  " .. tostring(id))
          return
        end
      end
    end
  end
  if GameStatus.IsInFightingNotSocialNotMainCityNotHome() then
    log(bWriteLog and "XSuitHandler.on_notify_change_emtion_action  not lobby")
    return
  end
  UIManager.ShowUI(UIManager.UI_Config.XSuit_Invite_UIBP, action_id, inviter_id)
end
function XSuitHandler.send_emtion_action_reply_req(is_play, action_id, random_sound_id, inviter_id)
  log(bWriteLog and "XSuitHandler.send_emtion_action_reply_req " .. tostring(is_play) .. " || action_id = " .. tostring(action_id))
  NetManager.SendPkg(880490923, is_play, action_id, random_sound_id, inviter_id)
end
function XSuitHandler.on_emtion_action_reply_rsp(err_code)
end
function XSuitHandler.send_wear_gold_dress_req(status, itemid)
  NetManager.SendPkg(2093412579, status, itemid)
end
function XSuitHandler.on_wear_gold_dress_rsp(err_code)
  if err_code ~= 0 then
    log(bWriteLog and "XSuitHandler.on_wear_gold_dress_rsp error code = " .. tostring(err_code))
  end
end
function XSuitHandler.on_team_update_gold_dress(uid, itemid, status)
  log(bWriteLog and "on_team_update_gold_dress uid = " .. tostring(uid) .. " || itemid = " .. tostring(itemid) .. " || status = " .. tostring(status))
  local LogicXSuit = require("client.slua.logic.XSuit.logic_xsuit")
  LogicXSuit.OnRelicStatusChange(tostring(uid), itemid, status)
  EventSystem:postEvent(EVENTTYPE_GOLDEN_SUIT, EVENTID_GOLDEN_SUIT_REFRESH_RELIC_STATUS)
end
function XSuitHandler.send_set_wish_pool_id_req(pool_id)
  NetManager.SendPkg(1261786215, pool_id)
end
function XSuitHandler.on_set_wish_pool_id_rsp(err_code, pool_id)
  log(bWriteLog and "XSuitHandler.on_set_wish_pool_id_rsp err_code = " .. tostring(err_code))
  if err_code ~= 0 then
    return
  end
  local logic_xsuit_activity = ModuleManager.GetModule(ModuleManager.JumpModuleConfig.logic_xsuit_activity)
  logic_xsuit_activity:SetWishPoolID(pool_id)
  EventSystem:postEvent(EVENTTYPE_GOLDEN_SUIT, EVENTID_GOLDEN_SUIT_LOTTERY_UPDATE_WISHPOOL)
end
function XSuitHandler.send_get_wish_pool_req()
  log(bWriteLog and "XSuitHandler.send_get_wish_pool_req")
  NetManager.SendPkg(248126303)
end
function XSuitHandler.on_get_wish_pool_rsp(res, wish_pool)
  log(bWriteLog and "XSuitHandler.on_get_wish_pool_rsp res = " .. res)
  if res ~= 0 then
    return
  end
  local logic_xsuit_activity = ModuleManager.GetModule(ModuleManager.JumpModuleConfig.logic_xsuit_activity)
  logic_xsuit_activity:SetWishPoolID(wish_pool == 0 and 1001 or wish_pool)
  EventSystem:postEvent(EVENTTYPE_GOLDEN_SUIT, EVENTID_GOLDEN_SUIT_LOTTERY_UPDATE_WISHPOOL)
end
function XSuitHandler.send_do_onshot_exchange_by_activity_id_req(activity_id, award_item_list)
  NetManager.SendPkg(2120963335, activity_id, award_item_list)
end
function XSuitHandler.on_do_onshot_exchange_by_activity_id_rsp(err_code, my_activity_data, award_list, activity_id)
  if err_code == 0 then
    local LuckybackActivitySystem = require("client.slua.logic.lobby_activity.logic_luckyback_activity")
    LuckybackActivitySystem.do_exchange_by_activity_id_rsp(err_code, my_activity_data, award_list, activity_id)
  else
    log_error("XSuitHandler.on_do_onshot_exchange_by_activity_id_rsp err_code: " .. tostring(err_code))
  end
end
function XSuitHandler.send_set_gold_dress_new_level_req(periodic_id, level_id, branch_id)
  NetManager.SendPkg(1293078951, periodic_id, level_id, branch_id)
end
function XSuitHandler.on_set_gold_dress_new_level_rsp(err_code, periodic_id, level_id, branch_id)
  if err_code == 0 then
    local LogicXSuit = require("client.slua.logic.XSuit.logic_xsuit")
    LogicXSuit.OnSetGoldDressNewLevelRsp(periodic_id, level_id, branch_id)
  else
    log_error("XSuitHandler.on_set_gold_dress_new_level_rsp err_code: " .. tostring(err_code))
  end
end
function XSuitHandler.send_get_gold_dress_new_level_req()
  NetManager.SendPkg(1624245415)
end
function XSuitHandler.on_get_gold_dress_new_level_rsp(err_code, set_info, gold_dress_set_info_new)
  if err_code == 0 then
    local LogicXSuit = require("client.slua.logic.XSuit.logic_xsuit")
    LogicXSuit.OnGetGoldDressNewLevelRsp(gold_dress_set_info_new.set_info)
  else
    log_error("XSuitHandler.on_get_gold_dress_new_level_rsp err_code: " .. tostring(err_code))
  end
end
function XSuitHandler.send_unlock_gold_dress_state_req(period, itemid, state, branchId)
  NetManager.SendPkg(2016980015, period, itemid, state, branchId or 0)
end
function XSuitHandler.on_unlock_gold_dress_state_rsp(err_code, all_state_info, all_state_info_new, branchId)
  if err_code == 0 then
    local LogicXSuit = require("client.slua.logic.XSuit.logic_xsuit")
    LogicXSuit.OnUnlockGoldDressStateRsp(all_state_info_new.state_info)
  else
    if err_code == 100170122 then
      ShowNotice(40036)
    end
    log_error("XSuitHandler.on_unlock_gold_dress_state_rsp err_code: " .. tostring(err_code))
  end
end
function XSuitHandler.send_set_gold_dress_state_req(period, state, source, branch_id)
  NetManager.SendPkg(1938023015, period, state, source, branch_id)
end
function XSuitHandler.on_set_gold_dress_state_rsp(err_code, ret_tbl, source, ret_tbl_new, branch_id)
  if err_code == 0 then
    local LogicXSuit = require("client.slua.logic.XSuit.logic_xsuit")
    LogicXSuit.OnSetGoldDressStateRsp(ret_tbl_new.set_info, source, branch_id)
  else
    log_error("XSuitHandler.on_set_gold_dress_state_rsp err_code: " .. tostring(err_code))
  end
end
function XSuitHandler.send_get_gold_dress_state_req()
  NetManager.SendPkg(139747687)
end
function XSuitHandler.on_get_gold_dress_state_rsp(err_code, info, inherit_all_state_info, all_state_info_new, inherit_info_new)
  if err_code == 0 then
    local LogicXSuit = require("client.slua.logic.XSuit.logic_xsuit")
    LogicXSuit.OnGetGoldDressStateRsp(all_state_info_new.state_info, inherit_info_new.state_info)
  else
    log_error("XSuitHandler.on_get_gold_dress_state_rsp err_code: " .. tostring(err_code))
  end
end
function XSuitHandler.on_refresh_gold_dress_state_rsp(err_code, info, info_new)
  if err_code == 0 then
    local LogicXSuit = require("client.slua.logic.XSuit.logic_xsuit")
    LogicXSuit.onRefreshGoldDressStateRsp(info_new.state_info)
  else
    log_error("XSuitHandler.on_get_gold_dress_state_rsp err_code: " .. tostring(err_code))
    ShowNotice(err_code)
  end
end
function XSuitHandler.send_unlock_gold_dress_level_feature_req(period, level, index, branch_id)
  NetManager.SendPkg(1297130967, period, level, index, branch_id)
end
function XSuitHandler.on_unlock_gold_dress_level_feature_rsp(err_code, period, level, index, gold_dress_set_info_all, gold_dress_set_info_all_new, branch_id)
  if err_code == 0 then
    local LogicXSuit = require("client.slua.logic.XSuit.logic_xsuit")
    LogicXSuit.on_unlock_gold_dress_level_feature_rsp(period, branch_id, level, index, gold_dress_set_info_all_new.set_info)
  else
    log_error("XSuitHandler.on_unlock_gold_dress_level_feature_rsp err_code: " .. tostring(err_code))
    if err_code == 100170124 then
      ShowNotice(40036)
    end
  end
end
function XSuitHandler.send_get_accumulate_pool_reward_req(pool_id, times, opt_flag, is_take_all)
  NetManager.SendPkg(1910843783, pool_id, times, opt_flag, is_take_all)
end
function XSuitHandler.on_get_accumulate_pool_reward_rsp(err_code, times_info_conf, pool_accumulate_info, decompose_list)
  log(bWriteLog and "XSuitHandler.on_get_accumulate_pool_reward_rsp  " .. tostring(err_code))
  local logic_xsuit_activity = ModuleManager.GetModule(ModuleManager.JumpModuleConfig.logic_xsuit_activity)
  if err_code == 0 then
    logic_xsuit_activity:on_get_accumulate_pool_reward_rsp(times_info_conf, pool_accumulate_info, decompose_list)
  end
end
function XSuitHandler.send_unlock_xsuit_glide_req(resid, branch_id)
  NetManager.SendPkg(169817159, resid, branch_id)
end
function XSuitHandler.on_unlock_xsuit_glide_rsp(err_code, resid)
  if err_code == 0 then
    local Logic_CommonItemGet = require("client.slua.logic.common.CommonItemGet.Logic_CommonItemGet")
    local allData = {
      [1] = {
        res_id = resid,
        count = 1,
        valid_hours = 0,
        expire_time = 0
      }
    }
    Logic_CommonItemGet.ShowPanel_FullCustom(allData, {})
    EventSystem:postEvent(EVENTTYPE_XSUIT, EVENTID_XSUIT_GLIDE_UNLOCK)
  else
    ShowNotice(err_code)
  end
end
function XSuitHandler.send_gold_dress_get_level_action_req()
  NetManager.SendPkg(1151944727)
end
function XSuitHandler.on_gold_dress_get_level_action_rsp(err_code, info, gold_dress_level_action_info_new)
  if err_code == 0 then
    log_tree("XSuitHandler.on_gold_dress_get_level_action_rsp ", info)
    local LogicXSuit = require("client.slua.logic.XSuit.logic_xsuit")
    LogicXSuit.levelAction = gold_dress_level_action_info_new.set_info or {}
    EventSystem:postEvent(EVENTTYPE_XSUIT, EVENTID_XSUIT_LEVEL_ACTION_UPDATE)
  else
    ShowNotice(err_code)
  end
end
function XSuitHandler.send_gold_dress_set_level_action_req(period_id, action_type, branch_id)
  NetManager.SendPkg(1441847655, period_id, action_type, branch_id)
end
function XSuitHandler.on_gold_dress_set_level_action_rsp(err_code, period_id, action_type, branch_id)
  if err_code == 0 then
    log(bWriteLog and "XSuitHandler.on_gold_dress_set_level_action_rsp " .. tostring(period_id) .. "  " .. tostring(action_type))
    local LogicXSuit = require("client.slua.logic.XSuit.logic_xsuit")
    LogicXSuit.levelAction = LogicXSuit.levelAction or {}
    LogicXSuit.levelAction[period_id] = LogicXSuit.levelAction[period_id] or {}
    LogicXSuit.levelAction[period_id][branch_id] = action_type
    EventSystem:postEvent(EVENTTYPE_XSUIT, EVENTID_XSUIT_LEVEL_ACTION_UPDATE)
  else
    ShowNotice(err_code)
  end
end
function XSuitHandler.send_gold_dress_flag_operation_req(period_id, level_id, index, operation_type, flag_value, branch_id)
  log(bWriteLog and "XSuitHandler.send_gold_dress_flag_operation_req period_id:" .. tostring(period_id) .. "  level_id:" .. tostring(level_id) .. "  index:" .. tostring(index) .. "  operation_type:" .. tostring(operation_type) .. "  flag_value:" .. tostring(flag_value))
  NetManager.SendPkg(1126377351, period_id, level_id, index, operation_type, flag_value, branch_id)
end
function XSuitHandler.on_gold_dress_flag_operation_rsp(err_code, info)
  log_tree(bWriteLog and "XSuitHandler.on_gold_dress_flag_operation_rsp ", info)
  if err_code == 0 then
    local LogicXSuit = require("client.slua.logic.XSuit.logic_xsuit")
    LogicXSuit.SetFeatureSwitch(info)
  else
    log(bWriteLog and "XSuitHandler.on_gold_dress_flag_operation_rsp " .. tostring(err_code))
  end
end
function XSuitHandler.send_open_gold_dress_branch_box_req(instid, target_item_id, source)
  NetManager.SendPkg(216680647, instid, target_item_id, source)
end
function XSuitHandler.on_open_gold_dress_branch_box_rsp(err_code, result_info)
  if err_code ~= 0 then
    ShowNotice(err_code)
    return
  end
  EventSystem:postEvent(EVENTTYPE_XSUIT, EVENTID_XSUIT_BRANCH_BOX_OPEN, result_info)
  XSuitHandler.send_get_rise_star_info_req()
  XSuitHandler.send_gold_dress_get_branch_switch_info_req()
end
function XSuitHandler.send_gold_dress_choose_active_branch_req(periodic_id, resid)
  NetManager.SendPkg(45866323, periodic_id, resid)
end
function XSuitHandler.on_gold_dress_choose_active_branch_rsp(err_code, periodic_id, resid, branch_id)
  if err_code ~= 0 then
    ShowNotice(err_code)
    return
  end
  local LogicXSuit = require("client.slua.logic.XSuit.logic_xsuit")
  LogicXSuit.SetActiveBranchInfo(periodic_id, resid, branch_id)
  local config = LogicXSuit.GetUpgradeUIInfoByBranchId(periodic_id, branch_id)
  if config then
    ShowNotice(LocUtil.LocalizeResFormat(200000754, LocUtil.GetLocalizeResStr(config.BranchName)))
    EventSystem:postEvent(EVENTTYPE_XSUIT, EVENTID_XSUIT_ACTIVE_BRANCH_UPDATE)
  end
end
function XSuitHandler.send_gold_dress_set_eliminate_req(flag)
  local NewValue = flag and true or false
  log(bWriteLog and "XSuitHandler.send_gold_dress_set_eliminate_req enabled:" .. tostring(NewValue))
  NetManager.SendPkg(561742375, NewValue)
end
function XSuitHandler.on_gold_dress_set_eliminate_rsp(err, flag)
  log(bWriteLog and "XSuitHandler.on_gold_dress_set_eliminate_rsp err:" .. tostring(err) .. " flag:" .. tostring(flag))
  local LogicXSuit = require("client.slua.logic.XSuit.logic_xsuit")
  if err == 0 then
    LogicXSuit.SetEliminationKingClothOverrideEnabled(flag)
  else
    LogicXSuit.ShowErrCode(err)
  end
end
function XSuitHandler.send_gold_dress_get_eliminate_req()
  log(bWriteLog and "XSuitHandler.send_gold_dress_get_eliminate_req")
  NetManager.SendPkg(786285095)
end
function XSuitHandler.on_gold_dress_get_eliminate_rsp(err, rspData)
  log(bWriteLog and "XSuitHandler.on_gold_dress_get_eliminate_rsp err:" .. tostring(err) .. " rspData:" .. tostring(rspData))
  local LogicXSuit = require("client.slua.logic.XSuit.logic_xsuit")
  if err ~= 0 then
    LogicXSuit._FetchingEliminationKingOverride = false
    LogicXSuit.ShowErrCode(err)
    return
  end
  local bPreference = type(rspData) == "table" and rspData.flag == true
  if not LogicXSuit.HasAnyXSuitAtElimOverrideTier() then
    LogicXSuit.SetEliminationKingClothOverrideEnabled(false)
    return
  end
  if LogicXSuit.IsEliminationKingOverrideFirstFetch() then
    bPreference = LogicXSuit.ComputeEliminationKingOverrideDefault()
    XSuitHandler.send_gold_dress_set_eliminate_req(bPreference)
    LogicXSuit.MarkEliminationKingOverrideInited()
  end
  LogicXSuit.SetEliminationKingClothOverrideEnabled(bPreference)
end
function XSuitHandler.send_gold_dress_exchange_active_currency_req(exchange_info, target_item_id)
  NetManager.SendPkg(1501410591, exchange_info, target_item_id)
end
function XSuitHandler.on_gold_dress_exchange_active_currency_rsp(err_code)
  if err_code ~= 0 then
    ShowNotice(err_code)
    return
  end
  EventSystem:postEvent(EVENTTYPE_GOLDEN_SUIT, EVENTID_GOLDEN_SUIT_EXCHANGED)
end
function XSuitHandler.send_gold_dress_branch_switch_req(resid)
  NetManager.SendPkg(226868839, resid)
end
function XSuitHandler.on_gold_dress_branch_switch_rsp(err_code, resid, ext_info)
  if err_code == 0 then
    local LogicXSuit = require("client.slua.logic.XSuit.logic_xsuit")
    local period = LogicXSuit.GetPeriodByItemId(resid)
    local info = ext_info.current_branch_info
    local branchId = info.branch_id or LogicXSuit.GetBranchByItemId(resid)
    LogicXSuit.SetWardrobeBranchByPeriod(period, ext_info.current_branch_info)
    EventSystem:postEvent(EVENTTYPE_GOLDEN_SUIT, EVENTID_GOLDEN_SUIT_UPDATE_DRESS_BRANCH, period, branchId, resid)
  else
    ShowNotice(err_code)
  end
end
function XSuitHandler.send_gold_dress_get_branch_switch_info_req()
  NetManager.SendPkg(296182371)
end
function XSuitHandler.on_gold_dress_get_branch_switch_info_rsp(err_code, ext_info)
  if err_code ~= 0 then
    ShowNotice(err_code)
    return
  end
  local LogicXSuit = require("client.slua.logic.XSuit.logic_xsuit")
  LogicXSuit.SetWardrobeBranch(ext_info.current_branch_info)
end
function XSuitHandler.send_gold_dress_branch_personal_info_req()
  NetManager.SendPkg(34884599)
end
function XSuitHandler.on_gold_dress_branch_personal_info_rsp(err_code, equip_data)
  if err_code ~= 0 then
    ShowNotice(err_code)
    return
  end
  local LogicXSuit = require("client.slua.logic.XSuit.logic_xsuit")
  LogicXSuit.SetSchemeIdCache(equip_data)
end
function XSuitHandler.send_gold_dress_set_branch_personal_req(period, branch, feature_id, scheme_id)
  NetManager.SendPkg(1484273255, period, branch, feature_id, scheme_id)
end
function XSuitHandler.on_gold_dress_set_branch_personal_rsp(err_code, period, branch, feature_id, scheme_id)
  if err_code ~= 0 then
    ShowNotice(err_code)
    return
  end
  local LogicXSuit = require("client.slua.logic.XSuit.logic_xsuit")
  LogicXSuit.SetSchemeIdCacheByFeature(period, branch, feature_id, scheme_id)
  EventSystem:postEvent(EVENTTYPE_XSUIT, EVENTID_XSUIT_CUSTOM_SET, period, branch, feature_id, scheme_id)
end
function XSuitHandler.send_gold_dress_get_collect_reward_req(periodic_id, resid)
  NetManager.SendPkg(1065785883, periodic_id, resid)
end
function XSuitHandler.on_gold_dress_get_collect_reward_rsp(err_code, periodic_id, resid)
  if err_code ~= 0 then
    log("on_gold_dress_get_collect_reward_rsp err_code = " .. tostring(err_code))
    return
  end
  local LogicXSuit = require("client.slua.logic.XSuit.logic_xsuit")
  LogicXSuit.SetCollectInfoByFeature(periodic_id, resid)
  EventSystem:postEvent(EVENTTYPE_XSUIT, EVENTID_XSUIT_FEATURE_GET, resid)
end
function XSuitHandler.send_gold_dress_get_collect_info_req()
  NetManager.SendPkg(1473522791)
end
function XSuitHandler.on_gold_dress_get_collect_info_rsp(err_code, info)
  if err_code ~= 0 then
    ShowNotice(err_code)
    return
  end
  local LogicXSuit = require("client.slua.logic.XSuit.logic_xsuit")
  LogicXSuit.SetCollectInfo(info.collect_info)
end
function XSuitHandler.send_gold_dress_reset_cost_branch_req(resid)
  NetManager.SendPkg(2005567079, resid)
end
function XSuitHandler.on_gold_dress_reset_cost_branch_rsp(err_code, resid, info)
  if err_code ~= 0 then
    ShowNotice(err_code)
    return
  end
  local LogicXSuit = require("client.slua.logic.XSuit.logic_xsuit")
  local period = LogicXSuit.GetPeriodByItemId(resid)
  local branchId = info.gold_dress_active_branch_info.branch_id
  local level = LogicXSuit.GetLevelByPeriodSelf(period, branchId)
  local backList = LogicXSuit.GetBackMaterialList(period, branchId, level)
  ShowNotice(LocUtil.LocalizeResFormat(200000764, backList[1] or 0, backList[2] or 0))
  LogicXSuit.SetActiveBranchInfo(period, resid, branchId)
  LogicXSuit.SetXSuitLevel(1, period, branchId)
  EventSystem:postEvent(EVENTTYPE_XSUIT, EVENTID_XSUIT_ACTIVE_BRANCH_UPDATE)
end
function XSuitHandler.send_gold_dress_task_info_req()
  NetManager.SendPkg(2048080871)
end
function XSuitHandler.on_gold_dress_task_info_rsp(err_code, info)
  if err_code ~= 0 then
    log(bWriteLog and "on_gold_dress_task_info_rsp err_code: " .. err_code)
    return
  end
  local LogicXSuit = require("client.slua.logic.XSuit.logic_xsuit")
  LogicXSuit.SetTaskConfig(info.task_conf_info)
  LogicXSuit.SetTaskStatus(info.task_status_info)
  LogicXSuit.SetTaskWeekId(info.current_week_id, info.current_season_id)
  LogicXSuit.SetTaskTime(info.week_conf, info.season_conf)
  EventSystem:postEvent(EVENTTYPE_XSUIT, EVENTID_XSUIT_MISSION_CONFIG_UPDATE)
end
function XSuitHandler.on_gold_dress_task_notify(task_status_info)
  local LogicXSuit = require("client.slua.logic.XSuit.logic_xsuit")
  LogicXSuit.SetTaskStatus(task_status_info.task_status_info)
  LogicXSuit.SetTaskWeekId(task_status_info.current_week_id, task_status_info.current_season_id, true)
  EventSystem:postEvent(EVENTTYPE_XSUIT, EVENTID_XSUIT_MISSION_CONFIG_UPDATE)
end
function XSuitHandler.send_gold_dress_task_reward_req(task_id)
  NetManager.SendPkg(1835389447, task_id)
end
function XSuitHandler.on_gold_dress_task_reward_rsp(err_code, task_id, reward_list)
  if err_code ~= 0 then
    ShowNotice(err_code)
    return
  end
  local Logic_CommonItemGet = require("client.slua.logic.common.CommonItemGet.Logic_CommonItemGet")
  Logic_CommonItemGet.ShowPanel_DecomposeStyle(reward_list)
  EventSystem:postEvent(EVENTTYPE_XSUIT, EVENTID_XSUIT_MISSION_CONFIG_UPDATE)
end
return XSuitHandler
