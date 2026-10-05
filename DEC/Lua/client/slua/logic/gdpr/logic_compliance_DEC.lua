local logic_compliance = {
  bInit = false,
  sdkInstance = nil,
  flowEndCallback = nil,
  flowEndForbiddenCallback = nil,
  sdkErrorCallback = nil,
  luaSdkCallBackDel = {},
  sCountry = nil,
  nYear = nil,
  nMonth = nil,
  certState = nil,
  bForceCert = true,
  bQueryUserStatus = false,
  lastSendEmailUrl = nil,
  lastSendParentName = nil,
  bReverifyCleared = false,
  bPendingBrazilMinorCheck = false,
  bBrazilMinorCheckDone = false,
  bLoginToLobby = false,
  bRegionReady = false
}
logic_compliance.Enum_Minor_Cert_Status = {
  Init = 0,
  Process = 1,
  Finish = 2
}
local INTLMethodID = {
  INTL_COMPLIANCE_SET_USER_PROFILE = 901,
  INTL_COMPLIANCE_QUERY_USER_STATUS = 902,
  INTL_COMPLIANCE_SET_ADULTHOOD = 903,
  INTL_COMPLIANCE_SET_EU_AGREE_STATUS = 904,
  INTL_COMPLIANCE_SEND_EMAIL = 905,
  INTL_COMPLIANCE_COMMIT_BIRTHDAY = 906,
  INTL_COMPLIANCE_SET_PARENT_CERTIFICATE_STATUS = 907,
  INTL_COMPLIANCE_QUERY_IS_EEA = 908,
  INTL_COMPLIANCE_OPEN_AGE_GATE = 909,
  INTL_COMPLIANCE_CLEAR_USER_STATUS = 911,
  INTL_COMPLIANCE_CHANGE_REGION = 917
}
logic_compliance.EndFlowState = {ForbiddenEnterGame = -1, NextStep = 1}
local EndFlowState = logic_compliance.EndFlowState
local SEND_EMAIL_SCENE = {
  Default = 0,
  BrazilAdultVerification = 11,
  BrazilParentVerification = 12
}
local BRAZIL_COMPLIANCE_EVENT_STAGE = {
  ShowAgeCollectPopup = 1,
  CertSuccessEnterGame = 2,
  MinorBlockPopup = 3
}
local BRAZIL_COMPLIANCE_USER_TYPE = {NewUser = 1, ExistingUser = 2}
local BRAZIL_COMPLIANCE_STATUS = {Adult = 0, Minor = 1}
local AUTH_FLOW_EVENT_STEP = {
  COUNTRY_PAGE_SHOW = 1,
  COUNTRY_SUBMITTED = 2,
  AGE_SUBMITTED = 3,
  BRANCH_DECIDED = 4,
  CPF_EMAIL_SENT = 5,
  PARENT_EMAIL_SENT = 6,
  PARENT_CONSENT_SUBMITTED = 7,
  THIRD_PARTY_AUTH_START = 8,
  AUTH_SKIPPED = 9,
  PARENT_UNAUTHORIZED = 10,
  REGISTER_COMPLIANCE_COMPLETE = 11
}
local AUTH_FLOW_AGE_CONFIRM_METHOD = {
  AGE_SLIDER = 1,
  BIRTH_YEAR = 2,
  SELF_CONFIRM = 3
}
local AUTH_FLOW_AGE_GROUP_RESULT = {ADULT = 1, MINOR = 2}
local AUTH_FLOW_AUTH_BRANCH = {
  NORMAL_ADULT = 1,
  ADULT_CPF = 2,
  MINOR_CPF = 3,
  CREDIT_CARD = 4,
  PARENT_EMAIL = 5,
  SELF_AUTH = 6
}
local AUTH_FLOW_REGISTER_COMPLIANCE_TYPE = {
  SDK_SUCCESS_CALLBACK = 1,
  AUTH_SKIPPED = 2,
  NO_NEED_COMPLY = 3
}
logic_compliance.AUTH_FLOW_EVENT_STEP = AUTH_FLOW_EVENT_STEP
logic_compliance.AUTH_FLOW_AGE_CONFIRM_METHOD = AUTH_FLOW_AGE_CONFIRM_METHOD
logic_compliance.AUTH_FLOW_AGE_GROUP_RESULT = AUTH_FLOW_AGE_GROUP_RESULT
logic_compliance.AUTH_FLOW_AUTH_BRANCH = AUTH_FLOW_AUTH_BRANCH
logic_compliance.AUTH_FLOW_REGISTER_COMPLIANCE_TYPE = AUTH_FLOW_REGISTER_COMPLIANCE_TYPE
function logic_compliance.CheckBrazilMinorBlock()
  if not logic_compliance.IsIpRegionBrazil() then
    log(bWriteLog and "logic_compliance.CheckBrazilMinorBlock not brazil ip")
    return
  end
  local logic_familycenter = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_familycenter)
  if logic_familycenter:IsInGrayScale() then
    printf("logic_compliance.CheckBrazilMinorBlock skip, familycenter gray scale active")
    return
  end
  if logic_compliance.bBrazilMinorCheckDone then
    log(bWriteLog and "logic_compliance.CheckBrazilMinorBlock already done, skip")
    return
  end
  if logic_compliance.flowEndCallback then
    log(bWriteLog and "logic_compliance.CheckBrazilMinorBlock BeginFlow is running, skip to avoid callback conflict")
    return
  end
  if not logic_compliance.IsEntryOpen() then
    log(bWriteLog and "logic_compliance.CheckBrazilMinorBlock entry closed")
    return
  end
  if not logic_compliance.bInit then
    if not logic_compliance.bPendingBrazilMinorCheck then
      logic_compliance.bPendingBrazilMinorCheck = true
      log(bWriteLog and "logic_compliance.CheckBrazilMinorBlock SDK not initialized, pending")
    end
    return
  end
  logic_compliance.bPendingBrazilMinorCheck = false
  logic_compliance.bBrazilMinorCheckDone = true
  log(bWriteLog and "logic_compliance.CheckBrazilMinorBlock SDKQueryUserStatus")
  logic_compliance.SDKQueryUserStatus(function(jsonData)
    log_tree(bWriteLog and "logic_compliance.CheckBrazilMinorBlock jsonData = ", jsonData)
    if not logic_compliance.IsBrazilRegion(jsonData.region) then
      return
    end
    if jsonData.adultStatus == 1 then
      return
    end
    if jsonData.parentAdultVerificationStatus ~= 1 then
      log(bWriteLog and "logic_compliance.CheckBrazilMinorBlock minor not certified, start certification flow")
      logic_compliance.BrazilFlowNotStartCertificate(jsonData)
    elseif not logic_compliance.IsBrazilMinorGameplayAllowed(jsonData.adultStatus) then
      logic_compliance.ShowBrazilMinorBlockPopup(jsonData.region)
    end
  end)
end
function logic_compliance.OnModePostSwitch(_, _, gamestatus)
  log(bWriteLog and "logic_compliance OnModePostSwitch")
  if gamestatus.pre ~= GameStatus.Login or gamestatus.current ~= GameStatus.Lobby then
    log(bWriteLog and "logic_compliance OnModePostSwitch not Login->Lobby, skip")
    return
  end
  logic_compliance.bLoginToLobby = true
  if logic_compliance.bRegionReady then
    logic_compliance.CheckBrazilMinorBlock()
  end
end
function logic_compliance.OnSetRegionOK()
  log(bWriteLog and "logic_compliance OnSetRegionOK")
  logic_compliance.bRegionReady = true
  if logic_compliance.bLoginToLobby then
    logic_compliance.CheckBrazilMinorBlock()
  end
end
function logic_compliance.ShowBrazilMinorBlockPopup(sdkRegion)
  log(bWriteLog and "logic_compliance ShowBrazilMinorBlockPopup")
  logic_compliance.ReportBrazilCompliance(BRAZIL_COMPLIANCE_EVENT_STAGE.MinorBlockPopup, logic_compliance.GetBrazilReportUserType(), BRAZIL_COMPLIANCE_STATUS.Minor, DataMgr.RegionData.region, tostring(sdkRegion or ""))
  local logic_common_msg_box = require("client.slua.logic.common.logic_common_msg_box")
  local callback = function()
    local login_module = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.login_module)
    login_module:sendLogout()
    logic_connection_waiting:Hide(1)
    login_module:backLogin()
  end
  logic_common_msg_box.Show(logic_common_msg_box.SHOW_TYPE_ONE, LocUtil.GetLocalizeResStr(101001), LocUtil.GetLocalizeResStr(87843), callback, nil, nil, nil, {androidCallback = callback})
end
function logic_compliance.OnLogout()
  log(bWriteLog and "logic_compliance onLogout")
  logic_compliance.bInit = false
  logic_compliance.sCountry = nil
  logic_compliance.nYear = nil
  logic_compliance.nMonth = nil
  logic_compliance.certState = nil
  logic_compliance.bForceCert = true
  logic_compliance.bQueryUserStatus = false
  logic_compliance.lastSendEmailUrl = nil
  logic_compliance.lastSendParentName = nil
  logic_compliance.bReverifyCleared = false
  logic_compliance.bPendingBrazilMinorCheck = false
  logic_compliance.bBrazilMinorCheckDone = false
  logic_compliance.bLoginToLobby = false
  logic_compliance.bRegionReady = false
  DataMgr.minor_cert_status = nil
end
function logic_compliance.SetLuaSdkCallBackDel(methodId, callback)
  log(bWriteLog and " logic_compliance.SetLuaSdkCallBackDel methodId = " .. tostring(methodId) .. " callback = " .. tostring(callback))
  if not callback then
    return
  end
  if not logic_compliance.luaSdkCallBackDel[methodId] then
    logic_compliance.luaSdkCallBackDel[methodId] = {}
  end
  table.insert(logic_compliance.luaSdkCallBackDel[methodId], callback)
end
function logic_compliance.LazyInitSdk()
  log(bWriteLog and "logic_compliance.LazyInitSdk logic_compliance.bInit = " .. tostring(logic_compliance.bInit))
  if logic_compliance.bInit == false then
    local SDKCallbackHelper = import("SDKCallbackHelper")
    local callbackInstance = SDKCallbackHelper.GetInstance()
    callbackInstance.SDKCallbackDelegate:Add(function(methodid, ret, extra)
      log(bWriteLog and "logic_compliance.LazyInitSdk methodid = " .. tostring(methodid))
      if methodid ~= 3000 then
        return
      end
      logic_compliance.OnCppSDKCallback(ret)
    end)
    local ComplianceHelper = import("IntlSDKComplianceHelper")
    local ComplianceHelperInstance = ComplianceHelper.GetInstance()
    logic_compliance.sdkInstance = ComplianceHelperInstance
    logic_compliance.bInit = true
    log(bWriteLog and "logic_compliance.LazyInitSdk")
    if logic_compliance.bPendingBrazilMinorCheck then
      log(bWriteLog and "logic_compliance.LazyInitSdk trigger pending CheckBrazilMinorBlock")
      logic_compliance.CheckBrazilMinorBlock()
    end
  end
end
function logic_compliance.OnCppSDKCallback(strResult)
  printf("logic_compliance.OnCppSDKCallback strResult:%s, ", strResult)
  local complianceRet = json.decode(strResult)
  local methodId = complianceRet.methodId
  local callbackList = logic_compliance.luaSdkCallBackDel[methodId]
  printf("logic_compliance.OnCppSDKCallback methodId:%s, callbackCount:%s", methodId, callbackList and #callbackList or 0)
  if callbackList and 0 < #callbackList then
    local callback = table.remove(callbackList, 1)
    if #callbackList == 0 then
      logic_compliance.luaSdkCallBackDel[methodId] = nil
    end
    if callback then
      callback(complianceRet)
    end
  end
end
function logic_compliance.SDKSetUserProfile(sRegion)
  log(bWriteLog and string.format(" logic_compliance.SDKSetUserProfile sRegion:%s", sRegion))
  if sRegion ~= nil and logic_compliance.IsEntryOpen() then
    logic_compliance.sdkInstance:SetUserProfile(sRegion)
  end
end
function logic_compliance.SDKQueryUserStatus(callback)
  log(bWriteLog and "logic_compliance.SDKQueryUserStatus")
  logic_compliance.bQueryUserStatus = true
  local wrappedCallback = callback
  if callback then
    function wrappedCallback(jsonData)
      if jsonData and type(jsonData.region) == "string" and jsonData.region ~= "" and (not logic_compliance.sCountry or logic_compliance.sCountry == "") then
        logic_compliance.sCountry = jsonData.region
        printf("logic_compliance.SDKQueryUserStatus fallback sCountry from SDK region=%s", jsonData.region)
      end
      callback(jsonData)
    end
  end
  logic_compliance.SetLuaSdkCallBackDel(INTLMethodID.INTL_COMPLIANCE_QUERY_USER_STATUS, wrappedCallback)
  if not logic_compliance.sdkInstance then
    return
  end
  logic_compliance.sdkInstance:QueryUserStatus()
end
function logic_compliance.SDKCommitBirthday(sBirthday, callback)
  log(bWriteLog and "logic_compliance.SDKCommitBirthday sBirthday = " .. tostring(sBirthday))
  logic_compliance.SetLuaSdkCallBackDel(INTLMethodID.INTL_COMPLIANCE_COMMIT_BIRTHDAY, callback)
  logic_compliance.sdkInstance:CommitBirthday(sBirthday)
end
function logic_compliance.SDKSendEmail(emailUrl, userName, Scene, callback)
  log(bWriteLog and string.format("logic_compliance.SDKSendEmail emailUrl: %s, userName: %s, Scene: %s", emailUrl, userName, Scene))
  logic_compliance.SetLuaSdkCallBackDel(INTLMethodID.INTL_COMPLIANCE_SEND_EMAIL, callback)
  logic_compliance.sdkInstance:SendEmail(emailUrl, userName, Scene)
end
function logic_compliance.SDKSetParentStatus(nStatus, callback)
  log(bWriteLog and "logic_compliance.SDKSetParentStatus nStatus = " .. tostring(nStatus))
  if not logic_compliance.bQueryUserStatus then
    local utility = require("common.utility")
    logic_compliance.SDKQueryUserStatus()
  end
  logic_compliance.SetLuaSdkCallBackDel(INTLMethodID.INTL_COMPLIANCE_SET_PARENT_CERTIFICATE_STATUS, callback)
  logic_compliance.sdkInstance:SetParentStatus(nStatus)
end
function logic_compliance.SDKChangeRegion(sRegion, callback)
  log(bWriteLog and "logic_compliance.SDKChangeRegion sRegion = " .. tostring(sRegion))
  if not logic_compliance.IsEntryOpen() then
    log(bWriteLog and "logic_compliance.SDKChangeRegion sdkInstance is nil")
    return
  end
  logic_compliance.SetLuaSdkCallBackDel(INTLMethodID.INTL_COMPLIANCE_CHANGE_REGION, callback)
  logic_compliance.sdkInstance:ChangeRegion(sRegion)
end
local SDK_LANG_TYPE_MAP = {
  ar = "ar",
  de = "de",
  en = "en",
  es = "es",
  fr = "fr",
  hi = "hi",
  id = "id",
  ja = "ja",
  ko = "ko",
  ms = "ms",
  nl = "nl",
  pt = "pt",
  ru = "ru",
  th = "th",
  tr = "tr",
  vi = "vi",
  zh = "zh-Hans",
  TW = "zh-TW",
  HK = "zh-Hant"
}
local GetSDKAgeGateLangType = function()
  local webModule = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.webModule)
  local language = webModule:GetCurrentLanguage()
  return SDK_LANG_TYPE_MAP[language] or language
end
function logic_compliance.SDKOpenAgeGate(sBaseUrl, sParamJson, sExtraJson, callback)
  local langType = GetSDKAgeGateLangType()
  if sParamJson == nil or sParamJson == "" then
    sParamJson = json.encode({lang_type = langType})
  else
    local paramTable = json.decode(sParamJson)
    if type(paramTable) == "table" then
      paramTable.lang_type = langType
      sParamJson = json.encode(paramTable)
    else
      sParamJson = json.encode({lang_type = langType})
    end
  end
  log(bWriteLog and string.format("logic_compliance.SDKOpenAgeGate sBaseUrl:%s, sParamJson:%s, sExtraJson:%s", tostring(sBaseUrl), tostring(sParamJson), tostring(sExtraJson)))
  if not logic_compliance.IsEntryOpen() then
    log(bWriteLog and "logic_compliance.SDKOpenAgeGate entry closed")
    return
  end
  if not logic_compliance.sdkInstance then
    return
  end
  logic_compliance.SDKClearUserStatus(function(clearResult)
    log(bWriteLog and "logic_compliance.SDKOpenAgeGate clear user status callback retCode=" .. tostring(clearResult and clearResult.retCode))
    if not logic_compliance.sdkInstance then
      log(bWriteLog and "logic_compliance.SDKOpenAgeGate sdkInstance destroyed after clear user status")
      return
    end
    logic_compliance.SetLuaSdkCallBackDel(INTLMethodID.INTL_COMPLIANCE_OPEN_AGE_GATE, callback)
    logic_compliance.sdkInstance:OpenAgeGate(sBaseUrl or "", sParamJson or "", sExtraJson or "")
  end)
end
function logic_compliance.SDKClearUserStatus(callback)
  log(bWriteLog and "logic_compliance.SDKClearUserStatus")
  if not logic_compliance.IsEntryOpen() then
    log(bWriteLog and "logic_compliance.SDKClearUserStatus entry closed")
    return
  end
  logic_compliance.SetLuaSdkCallBackDel(INTLMethodID.INTL_COMPLIANCE_CLEAR_USER_STATUS, callback)
  if not logic_compliance.sdkInstance then
    return
  end
  logic_compliance.sdkInstance:ClearUserStatus()
end
local _IsEntryOpen = function()
  local PublishRegionMacros = require("client.slua.config.ClientMacros.PublishRegionMacros")
  local strRegion = Client.GetPublishRegion()
  if strRegion ~= PublishRegionMacros.GLOBAL and strRegion ~= PublishRegionMacros.FIT then
    return false
  end
  if not logic_compliance.IsSwitchOpen() then
    log(bWriteLog and "logic_compliance switch not open")
    return false
  end
  local login_module = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.login_module)
  if not login_module.commonSwitch then
    log(bWriteLog and "logic_compliance common switch is nil")
    return false
  end
  local isOpen = login_module.commonSwitch.MinorCertSwitchNewUser
  log(bWriteLog and string.format("logic_compliance.IsEntryOpen: %s", tostring(isOpen)))
  return isOpen
end
function logic_compliance.IsSwitchOpen()
  return LobbySystem.CheckOpen(20217)
end
function logic_compliance.IsEntryOpen()
  local open = _IsEntryOpen()
  log(bWriteLog and string.format(" logic_compliance.IsEntryOpen open:%s", open))
  if open then
    logic_compliance.LazyInitSdk()
  end
  return open
end
function logic_compliance.CanUseAgeGate()
  log(bWriteLog and "logic_compliance.CanUseAgeGate")
  local GdprSystem = require("client.slua.logic.gdpr.logic_gdpr")
  local entryOpen = logic_compliance.IsEntryOpen()
  log(bWriteLog and "logic_compliance.CanUseAgeGate entryOpen = " .. tostring(entryOpen))
  if not entryOpen then
    return false
  end
  local verified = DataMgr.minor_cert_status == logic_compliance.Enum_Minor_Cert_Status.Finish
  log(bWriteLog and "logic_compliance.CanUseAgeGate verified = " .. tostring(verified))
  if verified then
    return false
  end
  if DataMgr.roleData.eugdpr and DataMgr.roleData.eugdpr.user_type ~= 0 then
    log(bWriteLog and "logic_compliance.CanUseAgeGate DataMgr.roleData.eugdpr.user_type = " .. tostring(DataMgr.roleData.eugdpr.user_type))
    if GdprSystem.IsEUGDPRUser(DataMgr.roleData.eugdpr.user_type) then
      local compliance_util = require("client.slua.logic.gdpr.compliance_util")
      local useAgeGate = compliance_util.CheckDGPRAgegateVersionMatch()
      local useAgeGateSwitch = LobbySystem.CheckOpen(80043)
      log(bWriteLog and "logic_compliance.CanUseAgeGate useAgeGate = " .. tostring(useAgeGate) .. " useAgeGateSwitch = " .. tostring(useAgeGateSwitch))
      if useAgeGateSwitch and useAgeGate then
        return true
      end
      return false
    end
  end
  return true
end
function logic_compliance.BeginFlow(flowEndCallback, flowEndForbiddenCallback)
  log(bWriteLog and " logic_compliance.BeginFlow, status: " .. tostring(DataMgr.minor_cert_status))
  logic_compliance.flowEndCallback = flowEndCallback
  logic_compliance.flowEndForbiddenCallback = flowEndForbiddenCallback
  local roleData = LobbySystem and LobbySystem.roleData
  local NewbieRoleState = LobbySystem and LobbySystem.NewbieRoleState
  local firstLoginState = roleData and roleData.is_first_login
  logic_compliance.bInRegistrationFlow = NewbieRoleState ~= nil and (firstLoginState == NewbieRoleState.Init or firstLoginState == NewbieRoleState.UpdateRole)
  printf("logic_compliance.BeginFlow bInRegistrationFlow=%s, is_first_login=%s", logic_compliance.bInRegistrationFlow, tostring(firstLoginState))
  local logic_familycenter = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_familycenter)
  if logic_familycenter:IsInGrayScale() then
    log(bWriteLog and "logic_compliance.BeginFlow ? familycenter BeginNewFlow (gray scale)")
    logic_familycenter:BeginNewFlow(flowEndCallback, flowEndForbiddenCallback)
    return
  end
  if not DataMgr.minor_cert_status or DataMgr.minor_cert_status == logic_compliance.Enum_Minor_Cert_Status.Init then
    log(bWriteLog and "logic_compliance status Init")
    logic_compliance.SDKQueryUserStatus(function(jsonData)
      log(bWriteLog and " logic_compliance query user status finished")
      log_tree(bWriteLog and "logic_compliance.BeginFlow jsonData = ", jsonData)
      if logic_compliance.IsBrazilRegion(jsonData.region) then
        logic_compliance.FlowBrazil(jsonData)
        return
      end
      if jsonData.adultStatus == 1 then
        logic_compliance.ReportAuthFlowEvent({
          EventStep = AUTH_FLOW_EVENT_STEP.BRANCH_DECIDED,
          AuthBranch = AUTH_FLOW_AUTH_BRANCH.NORMAL_ADULT
        })
        logic_compliance.EndFlow(EndFlowState.NextStep, AUTH_FLOW_REGISTER_COMPLIANCE_TYPE.NO_NEED_COMPLY)
      else
        local compliance_util = require("client.slua.logic.gdpr.compliance_util")
        local regionCode = compliance_util.GetRegionCodeByRegion(jsonData.region)
        log(bWriteLog and "logic_compliance.BeginFlow regionCode = " .. tostring(regionCode))
        local isEEA = compliance_util.CheckIsEEA(regionCode)
        log(bWriteLog and "logic_compliance.BeginFlow isEEA = " .. tostring(isEEA))
        log_tree(bWriteLog and "logic_compliance.BeginFlow DataMgr.roleData.eugdpr = ", DataMgr.roleData.eugdpr)
        if isEEA and DataMgr.roleData.eugdpr and not DataMgr.roleData.eugdpr.is_agegate then
          log(bWriteLog and "logic_compliance.BeginFlow send_eugdpr_update_agegate_req true")
          local EUGDPRHandler = require("client.network.Protocol.EUGDPRHandler")
          EUGDPRHandler.send_eugdpr_update_agegate_req(true)
        end
        if jsonData.parentCertificateStatus == 1 then
          logic_compliance.FlowHasCertificate(jsonData)
        elseif jsonData.certificateType == -1 then
          logic_compliance.FlowSelectArea(jsonData)
        elseif jsonData.certificateType == 0 then
          logic_compliance.FlowNoCertificationRequired(jsonData)
        else
          logic_compliance.FlowNeedCertificate(jsonData)
        end
      end
    end)
  elseif DataMgr.minor_cert_status == logic_compliance.Enum_Minor_Cert_Status.Process then
    log(bWriteLog and "logic_compliance status process")
    logic_compliance.SDKQueryUserStatus(function(jsonData)
      if logic_compliance.IsBrazilRegion(jsonData.region) then
        logic_compliance.FlowBrazil(jsonData)
        return
      end
      if jsonData.certificateType == -1 then
        logic_compliance.FlowSelectArea(jsonData)
      elseif jsonData.certificateType == 0 then
        logic_compliance.FlowNoCertificationRequired(jsonData)
      else
        logic_compliance.FlowNeedCertificate(jsonData)
      end
    end)
  elseif DataMgr.minor_cert_status == logic_compliance.Enum_Minor_Cert_Status.Finish then
    log(bWriteLog and "logic_compliance status finish")
    if logic_compliance.IsIpRegionBrazil() then
      logic_compliance.SDKQueryUserStatus(function(jsonData)
        if logic_compliance.IsBrazilRegion(jsonData.region) then
          logic_compliance.FlowBrazil(jsonData)
          return
        end
        if flowEndCallback then
          flowEndCallback()
        end
      end)
      return
    end
    if flowEndCallback then
      flowEndCallback()
    end
  end
end
function logic_compliance.FlowSelectArea(jsonData)
  log(bWriteLog and "logic_compliance FlowSelectArea eu_gdpr_jpage")
  UIManager.ShowUI(UIManager.UI_Config.eu_gdpr_jpage, 0, nil, nil, jsonData)
end
function logic_compliance.FlowNoCertificationRequired(jsonData)
  log(bWriteLog and "logic_compliance FlowNoCertificationRequired")
  logic_compliance.SDKSetParentStatus(1, function(_)
    logic_compliance.FlowHasCertificate(jsonData, AUTH_FLOW_REGISTER_COMPLIANCE_TYPE.NO_NEED_COMPLY)
  end)
end
function logic_compliance.FlowNeedCertificate(jsonData)
  log(bWriteLog and "logic_compliance FlowNeedCertificate")
  if jsonData.parentCertificateStatus == -1 then
    logic_compliance.FlowParentDenyVerify(jsonData)
  elseif jsonData.parentCertificateStatus == 10 then
    local adultExpiration = tonumber(jsonData.adultStatusExpiration)
    local sdkNow = logic_compliance.GetComplianceNowInSec(jsonData)
    local bExpired = not logic_compliance.bReverifyCleared and adultExpiration ~= nil and 0 < adultExpiration and adultExpiration < sdkNow
    printf("logic_compliance.FlowNeedCertificate verifyInProgressCheck, parentCertStatus:%s, adultExpiration:%s, sdkNow:%s, tS:%s, expired:%s, reverifyCleared:%s", tostring(jsonData.parentCertificateStatus), tostring(adultExpiration), tostring(sdkNow), tostring(jsonData.tS), tostring(bExpired), tostring(logic_compliance.bReverifyCleared))
    if bExpired then
      logic_compliance.FlowParentOutOfDate(jsonData)
    else
      logic_compliance.FlowWaitEmail(jsonData)
    end
  elseif jsonData.parentCertificateStatus == 0 then
    logic_compliance.FlowNotStartCertificate(jsonData)
  elseif jsonData.parentCertificateStatus == 1 then
    logic_compliance.FlowHasCertificate(jsonData)
  elseif jsonData.certificateType == 3 then
    logic_compliance.FlowMailVerify(jsonData)
  end
end
function logic_compliance.GetComplianceNowInSec(jsonData)
  local sdkNow = jsonData and tonumber(jsonData.tS)
  if sdkNow and 0 < sdkNow then
    return sdkNow
  end
  local TimeUtil = require("client.common.time_util")
  return TimeUtil.GetServerTimeInSec()
end
function logic_compliance.FlowParentDenyVerify(jsonData)
  log(bWriteLog and "logic_compliance FlowParentDenyVerify")
  local nextTimestamp = tonumber(jsonData.parentCertificateStatusExpiration)
  local now = logic_compliance.GetComplianceNowInSec(jsonData)
  local bExpired = nextTimestamp == nil or nextTimestamp <= 0 or nextTimestamp < now
  printf("logic_compliance.FlowParentDenyVerify rejectCooldownCheck, parentCertStatus:%s, expiration:%s, sdkNow:%s, expired:%s", tostring(jsonData.parentCertificateStatus), tostring(nextTimestamp), tostring(now), tostring(bExpired))
  if bExpired then
    logic_compliance.FlowParentOutOfDate(jsonData)
  else
    logic_compliance.FlowParentReject(nextTimestamp - now)
  end
end
function logic_compliance.FlowParentOutOfDate(jsonData)
  log(bWriteLog and "logic_compliance FlowParentOutOfDate")
  UIManager.ShowUI(UIManager.UI_Config.gdpr_verify_result, 2, nil, jsonData)
end
function logic_compliance.FlowParentReject(delta)
  log(bWriteLog and "logic_compliance FlowParentReject delta = " .. tostring(delta))
  UIManager.ShowUI(UIManager.UI_Config.gdpr_verify_result, 1, delta)
end
function logic_compliance.FlowRestartCertificate()
  log(bWriteLog and "logic_compliance FlowRestartCertificate")
  logic_compliance.bReverifyCleared = true
  logic_compliance.SDKClearUserStatus(function(clearResult)
    printf("logic_compliance.FlowRestartCertificate clearUserStatus, retCode:%s", tostring(clearResult and clearResult.retCode))
    logic_compliance.SDKQueryUserStatus(function(jsonData)
      printf("logic_compliance.FlowRestartCertificate refreshed, parentCertStatus:%s, certificateType:%s, adultExpiration:%s", tostring(jsonData and jsonData.parentCertificateStatus), tostring(jsonData and jsonData.certificateType), tostring(jsonData and jsonData.adultStatusExpiration))
      if not jsonData then
        return
      end
      if logic_compliance.IsBrazilRegion(jsonData.region) then
        logic_compliance.FlowBrazil(jsonData)
      elseif jsonData.certificateType == -1 then
        logic_compliance.FlowSelectArea(jsonData)
      elseif jsonData.certificateType == 0 then
        logic_compliance.FlowNoCertificationRequired(jsonData)
      else
        logic_compliance.FlowNeedCertificate(jsonData)
      end
    end)
  end)
end
function logic_compliance.FlowWaitEmail(jsonData)
  log(bWriteLog and "logic_compliance FlowWaitEmail")
  local complianceData
  if jsonData and logic_compliance.IsBrazilRegion(jsonData.region) then
    complianceData = {
      region = jsonData.region,
      adultStatus = jsonData.adultStatus,
      emailUrl = logic_compliance.lastSendEmailUrl,
      parentName = logic_compliance.lastSendParentName
    }
  end
  UIManager.ShowUI(UIManager.UI_Config.gdpr_wait_email_verify, complianceData)
end
function logic_compliance.FlowNotStartCertificate(jsonData)
  log(bWriteLog and "logic_compliance FlowNotStartCertificate")
  logic_compliance.sCountry = tostring(jsonData.region)
  UIManager.ShowUI(UIManager.UI_Config.agegate_select_age, jsonData.adultAge, function()
    local nYear = logic_compliance.nYear
    local nMonth = logic_compliance.nMonth
    if nYear and nMonth then
      local str = string.format("%s-%02d", nYear, nMonth)
      log(bWriteLog and "[boteliu] set birthday: " .. str)
      logic_compliance.SDKCommitBirthday(str, function(result)
        log(bWriteLog and "[boteliu] after get birthday result")
        log_tree(bWriteLog and "logic_compliance.FlowNotStartCertificate result = ", result)
        if result.adultStatus == 1 then
          local compliance_util = require("client.slua.logic.gdpr.compliance_util")
          compliance_util.GDPRAgegateAdult(result.region)
          logic_compliance.EndFlow(EndFlowState.NextStep)
        elseif result.parentCertificateStatus == 11 then
          UIManager.ShowUI(UIManager.UI_Config.gdpr_wait_creditcard_verify, 1)
        elseif result.parentCertificateStatus == 1 then
          logic_compliance.EndFlow(EndFlowState.NextStep)
        elseif result.parentCertificateStatus == -1 then
          logic_compliance.FlowParentDenyVerify(result)
        else
          logic_compliance.FlowSelectCertificateOptions(result)
        end
      end)
    else
      log(bWriteLog and "[boteliu] set birthday invalid, year: " .. tostring(nYear) .. " month: " .. tostring(nMonth))
    end
  end)
end
function logic_compliance.FlowHasCertificate(jsonData, registerComplianceType)
  log(bWriteLog and " logic_compliance FlowHasCertificate")
  if jsonData and logic_compliance.IsBrazilRegion(jsonData.region) and not logic_compliance.IsBrazilMinorGameplayAllowed(jsonData.adultStatus) then
    log(bWriteLog and "logic_compliance FlowHasCertificate Brazil minor gameplay not allowed, show block popup")
    logic_compliance.ShowBrazilMinorBlockPopup(jsonData.region)
    return
  end
  logic_compliance.EndFlow(EndFlowState.NextStep, registerComplianceType)
end
function logic_compliance.FlowMailVerify(jsonData)
  log(bWriteLog and "logic_compliance FlowMailVerify")
  local scene = SEND_EMAIL_SCENE.Default
  local bIsBrazilRegion = logic_compliance.IsBrazilRegion(jsonData.region)
  if jsonData and bIsBrazilRegion then
    if jsonData.adultStatus == 1 then
      scene = SEND_EMAIL_SCENE.BrazilAdultVerification
    else
      scene = SEND_EMAIL_SCENE.BrazilParentVerification
    end
    log(bWriteLog and "logic_compliance FlowMailVerify scene = " .. tostring(scene) .. ", adultStatus = " .. tostring(jsonData.adultStatus))
  end
  local complianceData = {
    region = jsonData.region,
    adultStatus = jsonData.adultStatus
  }
  if bIsBrazilRegion then
    complianceData.titleTextID = 87832
    complianceData.descTextID = 87833
    complianceData.mailTextID = 87834
  end
  if bIsBrazilRegion then
    logic_compliance.ReportAuthFlowEvent({
      EventStep = AUTH_FLOW_EVENT_STEP.BRANCH_DECIDED,
      AuthBranch = jsonData.adultStatus == 1 and AUTH_FLOW_AUTH_BRANCH.ADULT_CPF or AUTH_FLOW_AUTH_BRANCH.MINOR_CPF
    })
  else
    logic_compliance.ReportAuthFlowEvent({
      EventStep = AUTH_FLOW_EVENT_STEP.BRANCH_DECIDED,
      AuthBranch = AUTH_FLOW_AUTH_BRANCH.PARENT_EMAIL
    })
  end
  UIManager.ShowUI(UIManager.UI_Config.gdpr_email_verify, function(emailUrl, parentName)
    if bIsBrazilRegion then
      logic_compliance.lastSendEmailUrl = emailUrl
      logic_compliance.lastSendParentName = parentName
    end
    log_tree(bWriteLog and "logic_compliance.FlowMailVerify complianceData", complianceData)
    logic_compliance.SDKSendEmail(emailUrl, parentName or "", scene, function(sendResult)
      if sendResult and sendResult.retCode == 5 and sendResult.thirdCode == 30025 then
        log(bWriteLog and "logic_compliance FlowMailVerify SDKSendEmail rate limited")
        local msgContent = LocUtil.GetLocalizeResStr(87845)
        local CommonMsgBoxMgr = require("client.slua.logic.common.logic_common_msg_box")
        CommonMsgBoxMgr.Show(1, nil, msgContent, function()
          local login_module = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.login_module)
          login_module:sendLogout()
        end, nil, nil, nil, {
          androidCallback = function()
            return true
          end
        })
        return
      end
      if bIsBrazilRegion then
        local isAdult = jsonData.adultStatus == 1
        local payload = {
          EventStep = AUTH_FLOW_EVENT_STEP.CPF_EMAIL_SENT,
          AuthBranch = isAdult and AUTH_FLOW_AUTH_BRANCH.ADULT_CPF or AUTH_FLOW_AUTH_BRANCH.MINOR_CPF
        }
        if isAdult then
          payload.SelfEmail = emailUrl or ""
        else
          payload.ParentEmail = emailUrl or ""
        end
        logic_compliance.ReportAuthFlowEvent(payload)
      else
        logic_compliance.ReportAuthFlowEvent({
          EventStep = AUTH_FLOW_EVENT_STEP.PARENT_EMAIL_SENT,
          AuthBranch = AUTH_FLOW_AUTH_BRANCH.PARENT_EMAIL,
          ParentEmail = emailUrl or ""
        })
      end
      logic_compliance.ReportToSvrReq(1)
      logic_compliance.SDKQueryUserStatus(function(result)
        if bIsBrazilRegion then
          logic_compliance.FlowBrazil(result)
        else
          logic_compliance.FlowNeedCertificate(result)
        end
      end)
    end)
  end, complianceData)
end
function logic_compliance.FlowSelectCertificateOptions(jsonData)
  log(bWriteLog and "logic_compliance FlowSelectCertificateOptions")
  local logic_familycenter_fit = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_familycenter_fit)
  if logic_familycenter_fit:NeedForceSelfAuth(jsonData) then
    log(bWriteLog and "logic_compliance.FlowSelectCertificateOptions force self auth by logic_familycenter_fit")
    logic_compliance.FlowSelfCertification(jsonData)
    return
  end
  if jsonData.certificateType == -1 then
    logic_compliance.FlowSelectCertificateUI(jsonData)
  elseif jsonData.certificateType == 1 then
    logic_compliance.FlowSelfCertification(jsonData)
  elseif jsonData.certificateType == 2 then
    logic_compliance.FlowCardVerify()
  elseif jsonData.certificateType == 3 then
    logic_compliance.FlowMailVerify(jsonData)
  end
end
function logic_compliance.FlowSelectCertificateUI(jsonData)
  log(bWriteLog and "[boteliu] unknown certificate type")
  logic_compliance.FlowMailVerify(jsonData)
end
function logic_compliance.FlowSelfCertification(jsonData)
  log(bWriteLog and "logic_compliance FlowSelfCertification")
  logic_compliance.ReportAuthFlowEvent({
    EventStep = AUTH_FLOW_EVENT_STEP.BRANCH_DECIDED,
    AuthBranch = AUTH_FLOW_AUTH_BRANCH.SELF_AUTH
  })
  local compliance_util = require("client.slua.logic.gdpr.compliance_util")
  compliance_util.GDPRAgegateParentWaiting(jsonData.region)
  UIManager.ShowUI(UIManager.UI_Config.gdpr_self_verify, function()
    log(bWriteLog and "[boteliu] logic_compliance FlowSelfCertification self certification finished")
    local compliance_util = require("client.slua.logic.gdpr.compliance_util")
    compliance_util.GDPRAgegateYoungWithParentAgree(jsonData.region)
    if jsonData and jsonData.certificateType == 1 then
      logic_compliance.SDKSetParentStatus(1)
    end
    local logic_familycenter_fit = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.logic_familycenter_fit)
    logic_familycenter_fit:ReportFitVersionComplianceDone(jsonData)
    logic_compliance.EndFlow(EndFlowState.NextStep)
  end, function()
    log(bWriteLog and "logic_compliance FlowSelfCertification clickCancelCallback")
    local compliance_util = require("client.slua.logic.gdpr.compliance_util")
    compliance_util.GDPRAgegateYoungWithParentNotAgree(jsonData.region)
  end)
end
function logic_compliance.FlowCardVerify()
  log(bWriteLog and "[boteliu] start card verify")
  logic_compliance.ReportAuthFlowEvent({
    EventStep = AUTH_FLOW_EVENT_STEP.BRANCH_DECIDED,
    AuthBranch = AUTH_FLOW_AUTH_BRANCH.CREDIT_CARD
  })
  logic_compliance.ReportAuthFlowEvent({
    EventStep = AUTH_FLOW_EVENT_STEP.THIRD_PARTY_AUTH_START,
    AuthBranch = AUTH_FLOW_AUTH_BRANCH.CREDIT_CARD
  })
end
function logic_compliance.EndFlow(state, registerComplianceType)
  log(bWriteLog and "logic_compliance.EndFlow state = " .. tostring(state))
  if state == EndFlowState.ForbiddenEnterGame then
    log(bWriteLog and "logic_compliance.EndFlow logic_compliance.flowEndForbiddenCallback = " .. tostring(logic_compliance.flowEndForbiddenCallback))
    if logic_compliance.flowEndForbiddenCallback then
      logic_compliance.flowEndForbiddenCallback()
    end
  elseif state == EndFlowState.NextStep then
    logic_compliance.ReportToSvrReq(2)
    local complianceType = type(registerComplianceType) == "number" and registerComplianceType or AUTH_FLOW_REGISTER_COMPLIANCE_TYPE.SDK_SUCCESS_CALLBACK
    logic_compliance.ReportAuthFlowEvent({
      EventStep = AUTH_FLOW_EVENT_STEP.REGISTER_COMPLIANCE_COMPLETE,
      RegisterComplianceType = complianceType
    })
    log(bWriteLog and "logic_compliance.EndFlow logic_compliance.flowEndCallback = " .. tostring(logic_compliance.flowEndCallback))
    if logic_compliance.flowEndCallback then
      logic_compliance.flowEndCallback()
    end
  end
end
function logic_compliance.ReportToSvrReq(state)
  log(bWriteLog and "logic_compliance.ReportToSvrReq state = " .. tostring(state))
  local EUGDPRHandler = require("client.network.Protocol.EUGDPRHandler")
  EUGDPRHandler.send_minor_cert_report_req(state)
  logic_compliance.certState = state
end
function logic_compliance.GetBrazilSwitchConfig()
  local PublishRegionMacros = require("client.slua.config.ClientMacros.PublishRegionMacros")
  if not PublishRegionMacros.IsGlobalVersion() then
    return false, false, false
  end
  local nSwitchOpen = HDmpveRemote.HDmpveRemoteConfigGetInt("BrazilMinorCertification", 122)
  local BrazilMinorCertificationFlowSwitch = math.floor(nSwitchOpen / 100) == 2
  local BrazilMinorCertifiedGameplaySwitch = math.floor(nSwitchOpen / 10) % 10 == 2
  local BrazilMinorSkipCertificationSwitch = nSwitchOpen % 10 == 2
  log(bWriteLog and string.format("logic_compliance.GetBrazilSwitchConfig nSwitchOpen=%s, CertFlowSwitch=%s, CertifiedGameplaySwitch=%s, SkipCertSwitch=%s", tostring(nSwitchOpen), tostring(BrazilMinorCertificationFlowSwitch), tostring(BrazilMinorCertifiedGameplaySwitch), tostring(BrazilMinorSkipCertificationSwitch)))
  return BrazilMinorCertificationFlowSwitch, BrazilMinorCertifiedGameplaySwitch, BrazilMinorSkipCertificationSwitch
end
function logic_compliance.IsComplianceRegionBrazil(region)
  log(bWriteLog and string.format("logic_compliance.IsComplianceRegionBrazil region:%s", tostring(region)))
  if region and region ~= "" then
    local numRegion = tonumber(region)
    if not numRegion then
      log(bWriteLog and string.format("logic_compliance.IsComplianceRegionBrazil region:%s tonumber failed", tostring(region)))
      return false
    end
    local regionConfig = CDataTable.GetTableDataByFilter("RegionConfig", "Region", numRegion)
    if regionConfig and regionConfig.RegionCode == "BR" then
      log(bWriteLog and string.format("logic_compliance.IsComplianceRegionBrazil region:%s is BR, return true", tostring(region)))
      return true
    else
      log(bWriteLog and string.format("logic_compliance.IsComplianceRegionBrazil region:%s is not BR, regionConfig:%s", tostring(region), tostring(regionConfig and regionConfig.RegionCode)))
    end
  else
    log(bWriteLog and "logic_compliance.IsComplianceRegionBrazil region is nil or empty")
  end
  log(bWriteLog and "logic_compliance.IsComplianceRegionBrazil return false")
  return false
end
function logic_compliance.IsIpRegionBrazil()
  local login_module = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.login_module)
  local ipRegion = login_module.sIpRegion
  local result = ipRegion == "BR"
  log(bWriteLog and string.format("logic_compliance.IsIpRegionBrazil sIpRegion:%s, result:%s", tostring(ipRegion), tostring(result)))
  return result
end
function logic_compliance.IsGameRegionBrazil()
  log(bWriteLog and string.format("logic_compliance.IsGameRegionBrazil DataMgr.RegionData.region:%s", tostring(DataMgr.RegionData.region)))
  if DataMgr.RegionData.region == "BR" then
    local regionConfig = CDataTable.GetTableDataByFilter("RegionConfig", "RegionCode", "BR")
    if regionConfig then
      log(bWriteLog and "logic_compliance.IsGameRegionBrazil RegionData.region is BR, regionConfig found, return true")
      return true
    else
      log(bWriteLog and "logic_compliance.IsGameRegionBrazil RegionData.region is BR, but regionConfig not found")
    end
  end
  log(bWriteLog and "logic_compliance.IsGameRegionBrazil return false")
  return false
end
function logic_compliance.IsBrazilRegion(region)
  log(bWriteLog and string.format("logic_compliance.IsBrazilRegion region:%s", tostring(region)))
  if not logic_compliance.IsIpRegionBrazil() then
    log(bWriteLog and "logic_compliance.IsBrazilRegion IP not in Brazil, skip")
    return false
  end
  local BrazilMinorCertificationFlowSwitch, BrazilMinorCertifiedGameplaySwitch = logic_compliance.GetBrazilSwitchConfig()
  if not BrazilMinorCertificationFlowSwitch then
    log(bWriteLog and "logic_compliance.IsBrazilRegion BrazilMinorCertificationFlowSwitch is off, use non-Brazil flow")
    return false
  end
  if logic_compliance.IsComplianceRegionBrazil(region) then
    return true
  end
  if region and region ~= "" then
    log(bWriteLog and "logic_compliance.IsBrazilRegion compliance region is not Brazil, return false")
    return false
  end
  if logic_compliance.IsGameRegionBrazil() then
    local regionConfig = CDataTable.GetTableDataByFilter("RegionConfig", "RegionCode", "BR")
    if regionConfig then
      log(bWriteLog and "logic_compliance.IsBrazilRegion compliance region is empty, game region is BR, set region to BR")
      logic_compliance.SDKSetUserProfile(string.format("%03s", tostring(regionConfig.Region)))
    end
    return true
  end
  log(bWriteLog and "logic_compliance.IsBrazilRegion return false")
  return false
end
function logic_compliance.IsBrazilMinorGameplayAllowed(adultStatus)
  if adultStatus == 1 then
    log(bWriteLog and "logic_compliance.IsBrazilMinorGameplayAllowed adultStatus=1, adult user, allow")
    return true
  end
  local BrazilMinorCertificationFlowSwitch, BrazilMinorCertifiedGameplaySwitch = logic_compliance.GetBrazilSwitchConfig()
  if not BrazilMinorCertificationFlowSwitch then
    log(bWriteLog and "logic_compliance.IsBrazilMinorGameplayAllowed CertFlowSwitch is off, using non-Brazil flow")
    return true
  end
  if BrazilMinorCertifiedGameplaySwitch then
    log(bWriteLog and "logic_compliance.IsBrazilMinorGameplayAllowed minor can play after certification")
    return true
  else
    log(bWriteLog and "logic_compliance.IsBrazilMinorGameplayAllowed minor certified but gameplay not allowed")
    return false
  end
end
function logic_compliance.IsBrazilSkipCertificationAllowed(region)
  local BrazilMinorCertificationFlowSwitch, _, BrazilMinorSkipCertificationSwitch = logic_compliance.GetBrazilSwitchConfig()
  if not BrazilMinorCertificationFlowSwitch then
    log(bWriteLog and "logic_compliance.IsBrazilSkipCertificationAllowed CertFlowSwitch is off")
    return false
  end
  if not logic_compliance.IsBrazilRegion(region) then
    log(bWriteLog and "logic_compliance.IsBrazilSkipCertificationAllowed not Brazil region")
    return false
  end
  log(bWriteLog and string.format("logic_compliance.IsBrazilSkipCertificationAllowed SkipCertSwitch=%s", tostring(BrazilMinorSkipCertificationSwitch)))
  return BrazilMinorSkipCertificationSwitch
end
function logic_compliance.FlowBrazil(jsonData)
  log(bWriteLog and "logic_compliance FlowBrazil adultStatus = " .. tostring(jsonData.adultStatus) .. ", needAdultVerification = " .. tostring(jsonData.needAdultVerification) .. ", adultVerificationStatus = " .. tostring(jsonData.adultVerificationStatus))
  log(bWriteLog and "logic_compliance FlowBrazil parentAdultVerificationStatus = " .. tostring(jsonData.parentAdultVerificationStatus) .. ", needParentAdultVerification = " .. tostring(jsonData.needParentAdultVerification) .. ", parentCertificateStatus = " .. tostring(jsonData.parentCertificateStatus))
  if jsonData.retCode == 5 and jsonData.thirdCode == 30025 then
    local msgContent = LocUtil.GetLocalizeResStr(87845)
    local CommonMsgBoxMgr = require("client.slua.logic.common.logic_common_msg_box")
    CommonMsgBoxMgr.Show(1, nil, msgContent, function()
      local login_module = ModuleManager.GetModule(ModuleManager.LobbyModuleConfig.login_module)
      login_module:sendLogout()
    end)
    return
  elseif jsonData.retCode ~= 0 then
    ShowNotice(87846)
    return
  end
  if jsonData.adultStatus == 1 then
    if jsonData.needAdultVerification == 0 then
      log(bWriteLog and "logic_compliance FlowBrazil [Adult] needAdultVerification=0, no verification required")
      logic_compliance.FlowHasCertificate(jsonData, AUTH_FLOW_REGISTER_COMPLIANCE_TYPE.NO_NEED_COMPLY)
    elseif jsonData.adultVerificationStatus == 1 then
      log(bWriteLog and "logic_compliance FlowBrazil [Adult] adultVerificationStatus=1, already verified")
      logic_compliance.FlowHasCertificate(jsonData)
    elseif jsonData.adultVerificationStatus == 10 then
      logic_compliance.FlowWaitEmail(jsonData)
    else
      log(bWriteLog and "logic_compliance FlowBrazil [Adult] adultVerificationStatus != 1, need verification")
      logic_compliance.BrazilFlowNotStartCertificate(jsonData)
    end
  elseif jsonData.needParentAdultVerification == 1 then
    if jsonData.parentAdultVerificationStatus == 0 then
      log(bWriteLog and "logic_compliance FlowBrazil [Minor] parentAdultVerificationStatus=0, parent not started")
      logic_compliance.BrazilFlowNotStartCertificate(jsonData)
    elseif jsonData.parentAdultVerificationStatus == 1 then
      log(bWriteLog and "logic_compliance FlowBrazil [Minor] parentAdultVerificationStatus=1, parent already verified")
      logic_compliance.FlowHasCertificate(jsonData)
    elseif jsonData.parentAdultVerificationStatus == 10 then
      log(bWriteLog and "logic_compliance FlowBrazil [Minor] parentAdultVerificationStatus=10, waiting email verification")
      logic_compliance.FlowWaitEmail(jsonData)
    end
  elseif jsonData.parentCertificateStatus == 1 then
    logic_compliance.FlowHasCertificate(jsonData)
  elseif jsonData.certificateType == -1 then
    logic_compliance.FlowSelectArea()
  elseif jsonData.certificateType == 0 then
    logic_compliance.FlowNoCertificationRequired(jsonData)
  else
    logic_compliance.FlowNeedCertificate(jsonData)
  end
end
function logic_compliance.BrazilFlowNotStartCertificate(jsonData)
  log(bWriteLog and "logic_compliance BrazilFlowNotStartCertificate")
  logic_compliance.sCountry = tostring(jsonData.region)
  local complianceData = {
    region = jsonData.region,
    adultStatus = jsonData.adultStatus
  }
  logic_compliance.ReportBrazilCompliance(BRAZIL_COMPLIANCE_EVENT_STAGE.ShowAgeCollectPopup, logic_compliance.GetBrazilReportUserType(), nil, DataMgr.RegionData.region, tostring(jsonData.region))
  UIManager.ShowUI(UIManager.UI_Config.agegate_select_age, jsonData.adultAge, function()
    local nYear = logic_compliance.nYear
    local nMonth = logic_compliance.nMonth
    if nYear and nMonth then
      local str = string.format("%s-%02d", nYear, nMonth)
      log(bWriteLog and "logic_compliance BrazilFlowNotStartCertificate set birthday: " .. str)
      logic_compliance.SDKCommitBirthday(str, function(result)
        log(bWriteLog and "logic_compliance BrazilFlowNotStartCertificate after get birthday result")
        log_tree(bWriteLog and "logic_compliance BrazilFlowNotStartCertificate result = ", result)
        logic_compliance.SDKQueryUserStatus(function(newjsonData)
          log_tree(bWriteLog and "logic_compliance BrazilFlowNotStartCertificate after get birthday req compliance result = ", newjsonData)
          logic_compliance.FlowMailVerify(newjsonData)
        end)
      end)
    else
      log(bWriteLog and "logic_compliance BrazilFlowNotStartCertificate set birthday invalid, year: " .. tostring(nYear) .. " month: " .. tostring(nMonth))
    end
  end, complianceData)
end
function logic_compliance.ReportBrazilCompliance(eventStage, userType, complianceStatus, region, regionCompliance)
  log(bWriteLog and string.format("logic_compliance.ReportBrazilCompliance eventStage=%s, userType=%s, complianceStatus=%s, region=%s, regionCompliance=%s", tostring(eventStage), tostring(userType), tostring(complianceStatus), tostring(region), tostring(regionCompliance)))
  local clientConfig = HDmpveRemote.HDmpveRemoteConfigGetInt("BrazilMinorCertification", 12)
  local appVersion = Client.GetAppVersion() or ""
  local reportData = {
    app_version = appVersion,
    event_stage = eventStage,
    user_type = userType,
    region = region or DataMgr.RegionData.region or "",
    region_compliance = regionCompliance or "",
    client_config_snapshot = clientConfig
  }
  if eventStage == BRAZIL_COMPLIANCE_EVENT_STAGE.CertSuccessEnterGame or eventStage == BRAZIL_COMPLIANCE_EVENT_STAGE.MinorBlockPopup then
    reportData.compliance_status = complianceStatus
  end
  local tlog_report_utils = require("client.slua.config.tlog.tlog_report_utils")
  local reportStr = json.encode(reportData)
  tlog_report_utils.ReportTLogEvent(TLogEventDefine.Brazil_Compliance_Report, 0, reportStr)
  log(bWriteLog and string.format("logic_compliance.ReportBrazilCompliance reportStr=%s", tostring(reportStr)))
end
function logic_compliance.GetBrazilReportUserType()
  local logic_gdpr = require("client.slua.logic.gdpr.logic_gdpr")
  if logic_gdpr.GetIsNewUser() then
    return BRAZIL_COMPLIANCE_USER_TYPE.NewUser
  else
    return BRAZIL_COMPLIANCE_USER_TYPE.ExistingUser
  end
end
logic_compliance.BRAZIL_COMPLIANCE_EVENT_STAGE = BRAZIL_COMPLIANCE_EVENT_STAGE
logic_compliance.BRAZIL_COMPLIANCE_USER_TYPE = BRAZIL_COMPLIANCE_USER_TYPE
logic_compliance.BRAZIL_COMPLIANCE_STATUS = BRAZIL_COMPLIANCE_STATUS
function logic_compliance.ReportAuthFlowEvent(params)
  params = params or {}
  if type(params.EventStep) ~= "number" then
    printf("[WARN] logic_compliance.ReportAuthFlowEvent invalid EventStep=%s, skip", params.EventStep)
    return
  end
  if not logic_compliance.bInRegistrationFlow then
    printf("logic_compliance.ReportAuthFlowEvent skip: not in registration flow, EventStep=%s", params.EventStep)
    return
  end
  if params.EventStep == AUTH_FLOW_EVENT_STEP.REGISTER_COMPLIANCE_COMPLETE and type(params.RegisterComplianceType) ~= "number" then
    printf("[WARN] logic_compliance.ReportAuthFlowEvent REGISTER_COMPLIANCE_COMPLETE missing RegisterComplianceType=%s, skip", params.RegisterComplianceType)
    return
  end
  local msg = {
    region_compliance = type(logic_compliance.sCountry) == "string" and logic_compliance.sCountry or "",
    EventStep = params.EventStep,
    AgeConfirmMethod = type(params.AgeConfirmMethod) == "number" and params.AgeConfirmMethod or 0,
    AgeGroupResult = type(params.AgeGroupResult) == "number" and params.AgeGroupResult or 0,
    AuthBranch = type(params.AuthBranch) == "number" and params.AuthBranch or 0,
    SelfEmail = type(params.SelfEmail) == "string" and params.SelfEmail or "",
    ParentEmail = type(params.ParentEmail) == "string" and params.ParentEmail or "",
    RegisterComplianceType = type(params.RegisterComplianceType) == "number" and params.RegisterComplianceType or 0
  }
  printf("logic_compliance.ReportAuthFlowEvent region_compliance=%s, EventStep=%s, AgeConfirmMethod=%s, AgeGroupResult=%s, AuthBranch=%s, SelfEmail=%s, ParentEmail=%s, RegisterComplianceType=%s", msg.region_compliance, msg.EventStep, msg.AgeConfirmMethod, msg.AgeGroupResult, msg.AuthBranch, msg.SelfEmail, msg.ParentEmail, msg.RegisterComplianceType)
  logic_compliance:ReportMinorComplianceAuthFlowReq(msg)
end
function logic_compliance:ReportMinorComplianceAuthFlowReq(msg)
  local Handler = require("client.network.Protocol.EUGDPRHandler")
  Handler.send_report_minor_compliance_auth_flow_req(msg)
end
return logic_compliance
