local ChatComponent = {
  LuaEventContainer = {
    "OnSendMessage"
  }
}
local PublishRegionMacros = require("client.slua.config.ClientMacros.PublishRegionMacros")
local UGameplayStatics = import("GameplayStatics")
local GamePlayTools = require("GameLua.Mod.BaseMod.Common.GamePlayTools")
local GameplayData = require("GameLua.GameCore.Data.GameplayData")
local ChatFlagType = import("/Script/ShadowTrackerExtra.ChatFlagType")
local QuickChatFlag = import("/Script/ShadowTrackerExtra.QuickChatFlag")
function ChatComponent:ctor()
  self.ChatSettingConfig = {
    [1] = {
      Key = "OpenSilentChat",
      Type = "Bool"
    },
    [2] = {
      FuncName = "CheckGlobalChat"
    },
    [3] = {
      FuncName = "CheckCampCaht"
    }
  }
  self.SpecialChatMap = {}
  self.SpecialChatCD = {}
  self.LastSendSpecialChatTime = {}
  self.TransFormIDs = {}
  self.ChatBlacklist = {}
  self.FilterInfoTable = {}
  self._ColonChar = LocUtil.GetLocalizeResStr(4164)
  self.EndCharContent = "</>"
  self._STTS_Queue = {}
  self._IgnoreSplitActorNameID = {
    [225] = true,
    [9000] = true
  }
  self._PersonalizedActorID = {
    [9000] = true
  }
end
function ChatComponent:ReceiveBeginPlay()
  self.Super:ReceiveBeginPlay()
  self:RegistEvents()
  if not Client then
    EventSystem:postEvent(EVENTTYPE_INGAME, EVENTID_CHECK_CAN_CUSTOM_CHAT)
  end
  local uSTExtraBlueprintFunctionLibrary = import("STExtraBlueprintFunctionLibrary")
  self.bIsPreChatDetection = uSTExtraBlueprintFunctionLibrary.GetConsoleVariableIntValue("s.PreChatDetection")
end
function ChatComponent:ReceiveEndPlay(EndPlayReason)
  ChatComponent.__super.ReceiveEndPlay(self, EndPlayReason)
end
function ChatComponent:GetIsForbidCustomChat()
  local uPlayerController = self:GetOwner()
  if not slua.isValid(uPlayerController) then
    return false
  end
  return uPlayerController.bForbidCustomChat ~= false
end
function ChatComponent:RegistEvents()
  if Client and self:IsRealController() then
    print(bWriteLog and "ChatComponent:RegistEvents")
    self:AddCommonEvent(EVENTTYPE_INGAME, EVENTID_INGAME_RECEIVE_TRANSLATE_MSG, self.OnReceiveTranslateMsg, self)
    self:AddCommonEvent(EVENTTYPE_INGAME, EVENTID_INGAME_REPORT_RESULT_MAIL, self.OnReportResultMail, self)
  end
  local uPlayerController = self:GetOwner()
  if slua.isValid(uPlayerController) then
    self:AddControlEvent(uPlayerController, "OnPlayerEnterFighting", self.HandlePlayerEnterFighting, self)
  end
end
function ChatComponent:OnUnRegistEvents()
  if Client and self:IsRealController() then
    print(bWriteLog and "ChatComponent:UnRegistEvents")
    self:RemoveCommonEvent(EVENTTYPE_INGAME, EVENTID_INGAME_RECEIVE_TRANSLATE_MSG)
    self:RemoveCommonEvent(EVENTTYPE_INGAME, EVENTID_INGAME_REPORT_RESULT_MAIL)
  end
  local uPlayerController = self:GetOwner()
  if slua.isValid(uPlayerController) then
    self:RemoveControlEvent(uPlayerController, "OnPlayerEnterFighting")
  end
end
function ChatComponent:IsRealController()
  local uPlayerController = self:GetOwner()
  if not slua.isValid(uPlayerController) then
    return false
  end
  if uPlayerController.bIsForReplay or uPlayerController:ActorHasTag("DemoRecSpectator") then
    return false
  end
  return true
end
function ChatComponent:IsActorInGlobal(ActorID)
  local bIsTableContains = false
  if not self.TableActorID then
    self.TableActorID = {}
  end
  if self.TableActorID[ActorID] ~= nil then
    bIsTableContains = self.TableActorID[ActorID]
  else
    local actorTableData = CDataTable.GetTableData("VoiceActorCfg", ActorID)
    bIsTableContains = actorTableData and actorTableData.IsPlayInGlobal
    self.TableActorID[ActorID] = bIsTableContains
  end
  return bIsTableContains
end
function ChatComponent:CheckIsNeedShow(checkSetting)
  if not self.ChatSettingConfig[checkSetting] then
    return 0
  end
  local SettingModule = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.SettingModule)
  local SettingText = self.ChatSettingConfig[checkSetting]
  if SettingText then
    if SettingText.Key then
      if SettingText.Type == "Int" then
        local SettingValue = SettingModule:GetOptionValue(SettingText.Key)
        local TableUtil = require("common.table_util")
        if 0 < TableUtil.Find(SettingText.Value, SettingValue) then
          return 0
        else
          return 1
        end
      elseif SettingText.Type == "Bool" then
        local SettingValue = SettingModule:GetOptionValue(SettingText.Key)
        if SettingValue then
          return 0
        else
          return 1
        end
      end
    elseif SettingText.FuncName and SettingText.FuncName then
      return self[SettingText.FuncName](self)
    end
  else
    return 0
  end
end
function ChatComponent:CheckCDMsgs(MsgID)
  local uPlayerController = self:GetOwner()
  if slua.isValid(uPlayerController) and uPlayerController.CheckAutoLanguageCD then
    return uPlayerController:CheckAutoLanguageCD(MsgID)
  end
  for key, value in pairs(self.CDMsgIDs) do
    if value == MsgID then
      if self.bIsCDMsgInDuration == true then
        return false
      else
        self.bIsCDMsgInDuration = true
        self:AddGameTimer(self.CDMsgDuration, false, function()
          self.bIsCDMsgInDuration = false
        end)
        return true
      end
    end
  end
  return true
end
function ChatComponent:SendSTTMsg(Message, MsgExtraParam, STTClipFileID, bAll, bSameCamp)
  print(bWriteLog and "ChatComponent:SendSTTMsg - bAll=" .. tostring(bAll) .. " bSameCamp=" .. tostring(bSameCamp) .. " bIsPreChatDetection=" .. tostring(self.bIsPreChatDetection))
  local PlayerController = self:GetOwner()
  if slua.isValid(PlayerController) then
    local FInGameChatMsg = import("InGameChatMsg")
    local MsgItem = FInGameChatMsg()
    MsgItem.msgContent = Message
    MsgItem.STTClipFileID = STTClipFileID
    MsgItem.playerName = PlayerController.PlayerName
    MsgItem.playerIdentifier = PlayerController.PlayerKey
    if bAll then
      self:ServerSendMsgToAll(MsgItem, 2, true)
    elseif bSameCamp then
      self:ServerSendMsgToSameCamp(MsgItem, 3, true)
    else
      self:ServerSendMsg(MsgItem, 0, true, false, false)
    end
    self:LuaBroadcast("OnSendMessage", Message)
    self:ReportBattleChat(0, Message, MsgExtraParam)
  end
end
function ChatComponent:BeginFilter(text, extra_info, delegate)
  print(bWriteLog and "ChatComponent:BeginFilter - " .. text)
  if not text or #text == 0 then
    return
  end
  self.FilterInfoTable[text] = {extra_info = extra_info, delegate = delegate}
  local logicMain = require("client.slua.logic.lobby_chat.logic_chat_main")
  logicMain.filter_text_req(text, text)
end
function ChatComponent:OnFilterFinishRsp(filter_text, passthrough)
  print(bWriteLog and "ChatComponent:OnFilterFinishRsp - filter_text=" .. tostring(filter_text) .. " passthrough=" .. tostring(passthrough))
  local info = self.FilterInfoTable[passthrough]
  if info then
    if info.delegate then
      info.delegate(self, filter_text, passthrough, info.extra_info)
    end
    self.FilterInfoTable[passthrough] = nil
  else
    print(bWriteLog and "ChatComponent:OnFilterFinishRsp - AddPlayerMessage directly")
    self:AddPlayerMessage(passthrough .. filter_text)
  end
end
function ChatComponent:AddMarkAndPlaySound(Name, Content, MsgID, ItemCount, ItemID, PlayerKeyString, bIsMe, PlaySound, ShowChat, Distance)
  local uPlayerController = self:GetOwner()
  if not slua.isValid(uPlayerController) then
    return
  end
  local region = Client.GetPublishRegion()
  local bIsBanID = false
  if PublishRegionMacros.IsBlueholeFamily() then
    for index, value in ipairs(self.MuteMsgOnBluehole) do
      if value == MsgID then
        bIsBanID = true
        break
      end
    end
  end
  if not bIsBanID and PlaySound and Distance <= self.MaxShowVoiceDistance then
    local soundMsgID = math.floor(MsgID % 100000)
    local soundActorID = math.floor(MsgID / 100000)
    self:PlaySound(soundMsgID, soundActorID)
  end
  local MyName = LocUtil.GetLocalizeResStr(101717)
  if Game:IsRunningForAnticheat() then
    if bIsMe then
      MyName = "Reported Player"
    elseif not string.match(Name, "Teammate %d") then
      Name = "***"
    end
  end
  self.currContentMsg = Content
  if MsgID ~= 0 then
    self.currContentMsg = self:GetLocalText(MsgID, ItemID, PlayerKeyString, Distance, Name, ItemCount)
  end
  if bIsMe then
    self.MarkText = self.MyColor .. MyName .. LocUtil.GetLocalizeResStr(4164) .. self.EndChar .. self.currContentMsg
  else
    self.MarkText = self.TeammateColor .. Name .. LocUtil.GetLocalizeResStr(4164) .. self.EndChar .. self.currContentMsg
  end
  if not ShowChat then
    return
  end
  self:AddOneMarkToUIInner(bIsMe, self.MarkText)
end
function ChatComponent:LocalOnPreFilterFinish(sContent)
  self.currContentMsg = "<ChatReportMail>" .. sContent .. "</>"
  print(bWriteLog and "ChatComponent:LocalOnPreFilterFinish " .. self.currContentMsg)
  self.addToUIText = self.currContentMsg
  self:AddOneMsgToUIInner(true)
end
function ChatComponent:AddPlayerMessage(sFilterText)
  local VoiceReportSubsystem = SubsystemMgr:Get("VoiceReportSubsystem")
  if VoiceReportSubsystem and VoiceReportSubsystem.AddTextToCache then
    VoiceReportSubsystem:AddTextToCache(sFilterText)
  end
  self:AddMsgInClient(sFilterText)
end
function ChatComponent:AddMsgInClient(sFilterText)
  print(bWriteLog and "ChatComponent:AddMsgInClient " .. tostring(sFilterText))
  self.addToUIText = tostring(sFilterText)
  self:AddOneMsgToUIInner(false)
end
function ChatComponent:_GetPrefix(Name, IsMe)
  if IsMe then
    return self.MyColor .. LocUtil.GetLocalizeResStr(101717) .. self._ColonChar .. self.EndCharContent
  elseif Name and Name ~= "" then
    return self.TeammateColor .. Name .. self._ColonChar .. self.EndCharContent
  else
    return ""
  end
end
function ChatComponent:ShowQuickMsg_Lua(MsgItem, IsMe, playSound, ShowChat, bIsSignMark, Distance)
  if #MsgItem.ExtendParams > 0 then
    self:OnReceiveMsg(MsgItem.ExtendParams, MsgItem.msgID, IsMe)
  end
  if self.ChatBlacklist[MsgItem.playerName] then
    return
  end
  local bSkipVoiceBubble = false
  if not IsMe and self:IsPersonalizedVoice(MsgItem.msgID) then
    local SettingModule = ModuleManager.GetModule(ModuleManager.CommonModuleConfig.SettingModule)
    local bEnemyVoiceOn = true
    if SettingModule then
      local ReceiverSetting = SettingModule:GetOptionValue("ReceiverSetting")
      local bPlayEnemyPersonalizedVoice = SettingModule:GetOptionValue("PlayEnemyPersonalizedVoice")
      if Client and Client.IsDevelopment() then
        log(bWriteLog and "ChatComponent:ShowQuickMsg_Lua for personalize voice, ReceiverSetting:" .. tostring(ReceiverSetting) .. " bPlayEnemyPersonalizedVoice:" .. tostring(bPlayEnemyPersonalizedVoice))
      end
      if ReceiverSetting and ReceiverSetting ~= 0 or bPlayEnemyPersonalizedVoice == false then
        bEnemyVoiceOn = false
      end
    end
    local uOwnerPC = self:GetOwner()
    local uSelfPS = slua.isValid(uOwnerPC) and uOwnerPC.PlayerState or nil
    local SenderKey = MsgItem.playerIdentifier
    local bDefinitelyTeammate = false
    if slua.isValid(uSelfPS) and uSelfPS.IsTeammate and SenderKey and 0 < SenderKey then
      bDefinitelyTeammate = uSelfPS:IsTeammate(SenderKey)
    end
    if not bDefinitelyTeammate then
      local uSenderPS = Game and Game:GetPlayerStateByPlayerKey(SenderKey) or nil
      if not slua.isValid(uSenderPS) then
        local uGameState = GameplayData and GameplayData.GetGameState and GameplayData.GetGameState()
        if slua.isValid(uGameState) and uGameState.FindCharacterByPlayerKey and SenderKey then
          local uSenderChar = uGameState:FindCharacterByPlayerKey(SenderKey)
          if slua.isValid(uSenderChar) and slua.isValid(uSenderChar.PlayerState) then
            uSenderPS = uSenderChar.PlayerState
          end
        end
      end
      local bIsEnemy = false
      if slua.isValid(uSelfPS) and slua.isValid(uSenderPS) then
        local SelfTeam, SenderTeam = uSelfPS.TeamID, uSenderPS.TeamID
        if SelfTeam and SenderTeam and (SelfTeam < 0 or SenderTeam < 0 or SelfTeam ~= SenderTeam) then
          bIsEnemy = true
        end
      elseif slua.isValid(uSelfPS) and SenderKey and 0 < SenderKey and uSelfPS.PlayerKey and uSelfPS.PlayerKey ~= SenderKey then
        bIsEnemy = true
      end
      if bIsEnemy then
        if not bEnemyVoiceOn then
          self.CurrMsg.msgID = 0
          return
        else
          ShowChat = false
          bSkipVoiceBubble = true
        end
      end
    end
  end
  if bIsSignMark then
    self:AddOneMarkToUI(MsgItem.playerName, MsgItem.msgContent, MsgItem.msgID, MsgItem.itemCount, MsgItem.itemID, MsgItem.PlayerKeyString, IsMe, playSound, ShowChat, Distance)
  else
    if Game:IsRunningForAnticheat() then
      return
    end
    self:AddOneMsgToUI1(MsgItem.playerName, MsgItem.msgContent, MsgItem.msgID, MsgItem.audioID, MsgItem.itemID, MsgItem.PlayerKeyString, IsMe, playSound, ShowChat, Distance)
    if not bSkipVoiceBubble then
      EventSystem:postEvent(EVENTTYPE_INGAME, EVENTID_INGAME_QUICK_VOICE_BUBBLE, MsgItem, IsMe)
    end
  end
  self.CurrMsg.msgID = 0
end
function ChatComponent:ShowTeamMsg_Lua(MsgItem, IsMe)
  if self.ChatBlacklist[MsgItem.playerName] then
    return
  end
  if IsMe then
    local PrefixStr = self:_GetPrefix(MsgItem.playerName, IsMe)
    self.currContentMsg = PrefixStr .. MsgItem.msgContent
    self:AddPlayerMessage(self.currContentMsg)
    return
  end
  self:BeginFilter(MsgItem.msgContent, MsgItem, self.ShowTeamMsg_Filter)
end
function ChatComponent:ShowTeamMsg_Filter(filter_text, original, MsgItem)
  MsgItem.msgContent = filter_text
  local bHasBeenCensored = string.find(filter_text, "*")
  if MsgItem.STTClipFileID == "_" or bHasBeenCensored then
    self:SendFilterWithTranslation(MsgItem)
  elseif #MsgItem.STTClipFileID > 1 then
    self:EnqueueSTTSMessage(MsgItem)
  else
    local PrefixStr = self:_GetPrefix(MsgItem.playerName, false)
    self.currContentMsg = PrefixStr .. MsgItem.msgContent
    self:AddPlayerMessage(self.currContentMsg)
  end
end
function ChatComponent:EnqueueSTTSMessage(MsgItem)
  print(bWriteLog and string.format("ChatComponent:EnqueueSTTSMessage - STTClipFileID:%s, QueueSize:%d", tostring(MsgItem.STTClipFileID), #self._STTS_Queue))
  table.insert(self._STTS_Queue, MsgItem)
  if #self._STTS_Queue == 1 then
    self:SubmitSTTSTranslation(MsgItem)
  end
end
function ChatComponent:DequeueSTTSMessage(Translated)
  print(bWriteLog and string.format("ChatComponent:DequeueSTTSMessage - Translated:%s, QueueSize:%d", tostring(Translated), #self._STTS_Queue))
  local MsgItem = table.remove(self._STTS_Queue, 1)
  if MsgItem then
    if Translated then
      print(bWriteLog and "ChatComponent:DequeueSTTSMessage - AddPlayerMessage with translated text")
      self:AddPlayerMessage(self:_GetPrefix(MsgItem.playerName, false) .. Translated)
    else
      print(bWriteLog and "ChatComponent:DequeueSTTSMessage - Translated is false, fallback to SendFilterWithTranslation")
      self:SendFilterWithTranslation(MsgItem)
    end
  end
  local NextMsgItem = self._STTS_Queue[1]
  if NextMsgItem then
    print(bWriteLog and "ChatComponent:DequeueSTTSMessage - Processing next item in queue")
    self:SubmitSTTSTranslation(NextMsgItem)
  end
end
function ChatComponent:SubmitSTTSTranslation(MsgItem)
  print(bWriteLog and string.format("ChatComponent:SubmitSTTSTranslation - STTClipFileID:%s", tostring(MsgItem.STTClipFileID)))
  local VoiceChatSubsystem = SubsystemMgr:Get("VoiceChatSubsystem")
  assert(VoiceChatSubsystem)
  if not VoiceChatSubsystem:SubmitSTTSTranslation(MsgItem.STTClipFileID) then
    print(bWriteLog and "ChatComponent:SubmitSTTSTranslation - SubmitSTTSTranslation failed, dequeue with false")
    self:DequeueSTTSMessage(false)
  end
end
function ChatComponent:SendFilterWithTranslation(MsgItem)
  local Prefix = self:_GetPrefix(MsgItem.playerName, false)
  local FirstLang = self:GetFirstLanguage().name
  print(bWriteLog and "ChatComponent:SendFilterWithTranslation", MsgItem.msgContent, Prefix)
  if nil == MsgItem.msgContent or "" == MsgItem.msgContent then
    return
  end
  if nil == Prefix or "" == Prefix then
    return
  end
  local ChatHandler = require("client.network.Protocol.ChatHandler")
  ChatHandler.send_chat_translate_with_filter_req(FirstLang, MsgItem.msgContent, 0, Prefix)
end
function ChatComponent:GetFirstLanguage()
  local FirstLanguage = {}
  FirstLanguage.id = 0
  FirstLanguage.name = ""
  local logic_chat_channel_world = require("client.slua.logic.lobby_chat.logic_chat_channel_world")
  for i, v in ipairs(logic_chat_channel_world.language_data_list) do
    if v.id == DataMgr.FirstSecondLanguage[1] then
      FirstLanguage = v
      if FirstLanguage.id == 103 then
        FirstLanguage.name = "zh-TW"
        break
      end
      if FirstLanguage.id == 113 then
        FirstLanguage.name = "ms"
      end
      break
    end
  end
  print(bWriteLog and "[SpeechToText] ChatComponent:GetFirstLanguage ", #logic_chat_channel_world.language_data_list, FirstLanguage.id, FirstLanguage.name, FirstLanguage.lang_name)
  return FirstLanguage
end
function ChatComponent:OnReceiveTranslateMsg(_, _, Ret, MsgID, From, To, TransKey, TransValue, Prefix)
  if not slua.isValid(self.Object) then
    return
  end
  print(bWriteLog and "ChatComponent:OnReceiveTranslateMsg", Ret, MsgID, From, To, TransKey, TransValue, Prefix)
  if Ret == 0 and TransValue and TransValue ~= "" then
    self:AddPlayerMessage(Prefix .. TransValue)
  else
    local logicMain = require("client.slua.logic.lobby_chat.logic_chat_main")
    logicMain.filter_text_req(TransKey, Prefix)
  end
end
function ChatComponent:ClientReceiveGift_Lua(MsgItem)
  if MsgItem.msgID == 0 then
    self:AddMsgInClient(MsgItem.msgContent)
  else
    self.addToUIMsgID = MsgItem.msgID
    self:AddMsgInClient(self:_GetPrefix(MsgItem.playerName, false) .. MsgItem.msgContent)
  end
end
function ChatComponent:OnReportResultMail(_, __, report_info)
  print(bWriteLog and "ChatComponent:OnReportResultMail")
  if not slua.isValid(self.Object) then
    print(bWriteLog and "ChatComponent:OnReportResultMail Object invalid")
    return
  end
  if GameStatus.IsInLobbyOrMainCity() then
    print(bWriteLog and "ChatComponent:OnReportResultMail IsInLobbyOrMainCity")
    return
  end
  if not report_info.id or not report_info.params then
    print(bWriteLog and "ChatComponent:OnReportResultMail id or params nil")
    return
  end
  print(bWriteLog and string.format("ChatComponent:OnReportResultMail id[%s] params[%s]", tostring(report_info.id), tostring(report_info.params)))
  local FeedBackData = CDataTable.GetTableData("ReportMailFeedback", report_info.id)
  if not FeedBackData then
    print(bWriteLog and "ChatComponent:OnReportResultMail FeedBackData nil")
    return
  end
  local StringUtil = require("common.string_util")
  local tParamTable = StringUtil.Split(report_info.params, ",")
  local Length = #tParamTable
  print(bWriteLog and string.format("ChatComponent:OnReportResultMail Length[%s]", tostring(Length)))
  local sContent
  if Length == 2 then
    sContent = LocUtil.LocalizeResFormat(FeedBackData.LocalizeID, tParamTable[1], tParamTable[2])
  elseif Length == 3 then
    sContent = LocUtil.LocalizeResFormat(FeedBackData.LocalizeID, tParamTable[1], tParamTable[2], tParamTable[3])
  elseif Length == 4 then
    sContent = LocUtil.LocalizeResFormat(FeedBackData.LocalizeID, tParamTable[1], tParamTable[2], tParamTable[3], tParamTable[4])
  else
    return
  end
  self:LocalOnPreFilterFinish(sContent)
end
function ChatComponent:TransformMsgID(OriMsgID)
  print(bWriteLog and "[voice]ChatComponent:TransformMsgID", OriMsgID)
  local VoiceTransformSubsystem = SubsystemMgr:Get("VoiceTransformSubsystem")
  if VoiceTransformSubsystem and VoiceTransformSubsystem.TransformMsgID then
    local TransformedID = VoiceTransformSubsystem:TransformMsgID(OriMsgID)
    if TransformedID ~= OriMsgID then
      print(bWriteLog and "[voice]ChatComponent:TransformMsgID VoiceTransformSubsystem", TransformedID)
      return TransformedID
    end
  end
  return OriMsgID
end
function ChatComponent:OnCheckSpecialChatCD(MsgID)
  local EnglishMsgID = MsgID % 100000
  if self.SpecialChatMap[EnglishMsgID] then
    local MsgChatCD = self.SpecialChatCD[EnglishMsgID]
    if not MsgChatCD then
      local ForbidTimeTableData = CDataTable.GetTableData("VoiceForbidCfg", EnglishMsgID)
      if not ForbidTimeTableData then
        self.SpecialChatCD[EnglishMsgID] = 0
        return true
      end
      local ForbidTime = ForbidTimeTableData.ForbidTime
      if not ForbidTime then
        self.SpecialChatCD[EnglishMsgID] = 0
        return true
      end
      self.SpecialChatCD[EnglishMsgID] = ForbidTime
    elseif MsgChatCD == 0 then
      return true
    end
    local CurTime = UGameplayStatics.GetTimeSeconds(CGameWorld)
    local LastSendTime = self.LastSendSpecialChatTime[EnglishMsgID]
    if not LastSendTime then
      self.LastSendSpecialChatTime[EnglishMsgID] = CurTime
      return true
    end
    if CurTime > LastSendTime + MsgChatCD then
      self.LastSendSpecialChatTime[EnglishMsgID] = CurTime
      return true
    else
      return false
    end
  else
    return true
  end
end
function ChatComponent:ClearSpecialChat()
  self.SpecialChatMap = {}
end
function ChatComponent:AddSpecialChat(MsgID, SpecialType)
  self.SpecialChatMap[MsgID] = SpecialType
end
function ChatComponent:PreSendMsg(Msg, MsgID, ItemID, msgExtraParam)
  local tempDataTable = {}
  tempDataTable.RecommendType = self:CheckRecommendType(MsgID)
  tempDataTable.AutoLanguage = self:CheckAutoLanguage(msgExtraParam)
  if self.pendingMultiLikeReply then
    tempDataTable.bIsMultiLikeReply = true
    self.pendingMultiLikeReply = nil
  end
  if self.pendingSoleLikeMsg then
    tempDataTable.bIsSoleLikeMsg = true
    self.pendingSoleLikeMsg = nil
  end
  local ExtendParamsCache = self.ExtendParamsCache
  if not ExtendParamsCache then
    return
  end
  self:SetExtendParamsCache(slua.LuaArchiverEncode(LuaStateWrapper, tempDataTable))
end
function ChatComponent:CheckRecommendType(MsgID)
  local VoiceRecommendationConfig = GamePlayTools.GetCurrentConfig("VoiceRecommendationConfig")
  if not VoiceRecommendationConfig or not VoiceRecommendationConfig.ReplayVoice then
    return nil
  end
  local EnglishID = MsgID % 100000
  local MsgType = self.SpecialChatMap[MsgID]
  if MsgType then
    local VoiceRecommendationSubsystem = SubsystemMgr:Get("VoiceRecommendationSubsystem")
    if VoiceRecommendationSubsystem then
      VoiceRecommendationSubsystem:AddUseRecommendationTimes(MsgType)
    end
    print(bWriteLog and "ChatComponent:PreSendMsg MsgID: " .. MsgID .. "  Type: " .. MsgType)
    local ReplayConfig = VoiceRecommendationConfig.ReplayVoice
    if ReplayConfig[MsgType] and not ReplayConfig[MsgType][EnglishID] then
      return nil
    end
    return MsgType
  end
  return nil
end
function ChatComponent:CheckAutoLanguage(msgExtraParam)
  if msgExtraParam == 2 then
    return true
  end
  return nil
end
function ChatComponent:OnReceiveMsg(ExtendData, MsgID, IsMe)
  local ExtendDataTable = slua.LuaArchiverDecode(LuaStateWrapper, ExtendData)
  if not ExtendDataTable then
    return
  end
  if ExtendDataTable.RecommendType and not IsMe then
    print(bWriteLog and "ChatComponent:OnReceiveMsg Type: " .. ExtendDataTable.RecommendType)
    local uPlayerController = self:GetOwner()
    if not slua.isValid(uPlayerController) then
      return
    end
    if uPlayerController.IsSpectator and uPlayerController:IsSpectator() or uPlayerController.IsDemoPlaySpectator and uPlayerController:IsDemoPlaySpectator() then
      return
    end
    if slua.isValid(uPlayerController) and uPlayerController.IsInPetSpectator and uPlayerController:IsInPetSpectator() then
      log(bWriteLog and "ChatComponent:OnReceiveMsg IsInPetSpectator")
      return
    end
    EventSystem:postEvent(EVENTTYPE_INGAME_NORMAL, EVENTID_REPLY_VOICE_RECOMMENDATION, ExtendDataTable.RecommendType)
  end
  if ExtendDataTable.AutoLanguage then
    self.AutoLanguage = true
  else
    self.AutoLanguage = false
  end
  if ExtendDataTable.bIsMultiLikeReply then
    self.bIsMultiLikeReply = true
  else
    self.bIsMultiLikeReply = false
  end
  if ExtendDataTable.bIsSoleLikeMsg then
    self.bIsSoleLikeMsg = true
  else
    self.bIsSoleLikeMsg = false
  end
end
function ChatComponent:PlayAutoLanguageMsg(ActorID, MsgID)
  local BankName, EventName = self:GetAutoLanguageMsg(ActorID, MsgID)
  if not self:CheckCDMsgs(MsgID) then
    return
  end
  if EventName and self.CurrMsg and self.CurrMsg.bAudio3D then
    self:LoadBankAndPlay3D(BankName, EventName .. "_3D", self.CurrMsg.SoundLocation)
  else
    self:LoadBankAndPlay(BankName, EventName)
  end
end
function ChatComponent:GetAutoLanguageMsg(ActorID, MsgID)
  log(bWriteLog and "ChatComponent:GetAutoLanguageMsg ActorID: ", ActorID, " MsgID:", MsgID)
  local VoiceTransformSubsystem = SubsystemMgr:Get("VoiceTransformSubsystem")
  if VoiceTransformSubsystem and VoiceTransformSubsystem.GetAutoLanguageMsg then
    local BankName, EventName = VoiceTransformSubsystem:GetAutoLanguageMsg(ActorID, MsgID)
    if BankName and EventName then
      log(bWriteLog and "ChatComponent:GetAutoLanguageMsg VoiceTransformSubsystem", BankName, EventName)
      return BankName, EventName
    end
  end
end
function ChatComponent:CheckGlobalChat()
  local QuickMenu = UIManager.GetUI(UIManager.UI_Config_InGame.QuickMenu)
  if QuickMenu then
    local bIsGlobalChannel = QuickMenu.bSendToGlobal
    if not bIsGlobalChannel then
      return 1
    end
  end
  return 0
end
function ChatComponent:CheckCampCaht()
  local QuickMenu = UIManager.GetUI(UIManager.UI_Config_InGame.QuickMenu)
  if QuickMenu then
    local bIsCampChannel = QuickMenu.bSendToCamp
    if not bIsCampChannel then
      return 1
    end
  end
  return 0
end
function ChatComponent:AddToArray()
  local ArrayLength = self.UITextArray:Num()
  if ArrayLength < 4 then
    self.UITextArray:Add(self.addToUIText)
    local NewIndex = self.UITextArray:Num() - 1
    self.UIMsgIDMap:Add(NewIndex, self.addToUIMsgID)
    self.addToUIMsgID = 0
  else
    for Index = 0, ArrayLength - 1 do
      if 0 < Index then
        local PrevIndex = Index - 1
        local CurrentElement = self.UITextArray:Get(Index)
        self.UITextArray:Set(PrevIndex, CurrentElement)
        local MsgID = self.UIMsgIDMap:Get(Index)
        if MsgID then
          self.UIMsgIDMap:Add(PrevIndex, MsgID)
        end
      end
    end
    local LastIndex = ArrayLength - 1
    self.UITextArray:Set(LastIndex, self.addToUIText)
    self.UIMsgIDMap:Add(LastIndex, self.addToUIMsgID)
    self.addToUIMsgID = 0
  end
end
function ChatComponent:AddOneMsgToUIInner(IsMe)
  self.IsMe = IsMe
  self:AddToArray()
  local uPlayerController = GameplayData.GetPlayerController()
  if not slua.isValid(uPlayerController) then
    return
  end
  uPlayerController:BroadcastUIMessage("UIMsg_AddOneMsgtoUIInner", 0, "", "")
end
function ChatComponent:InitFromSetting()
  print(bWriteLog and "ChatComponent:InitFromSetting [1]")
  self.SettingConfig = slua_GameFrontendHUD:GetUserSettings()
  self:LoadInfectModeQuickMsg()
  self:LoadVehicleModeQuickMsg()
  self:SetQuickChatList()
  self:SetTurnplateQuickChatList()
  self:InitActorIDList()
  local uPlayerController = GameplayData.GetPlayerController()
  if not slua.isValid(uPlayerController) then
    return
  end
  local BusinessHelper = import("BusinessHelper")
  if BusinessHelper then
    local region = BusinessHelper.GetPublishRegion()
    uPlayerController:BroadcastUIMessage("UIMsg_InitTurnplateQuickChat", 0, region, "")
    print(bWriteLog and "ChatComponent:InitFromSetting [4]")
  end
end
function ChatComponent:PlaySound(MsgID, ActorID)
  local VoiceSDK = slua_GameFrontendHUD:GetVoiceSDKInterface()
  if not slua.isValid(VoiceSDK) then
    return
  end
  local bTeamSpeakerEnabled = VoiceSDK:TeamSpeakerEnable()
  if not bTeamSpeakerEnabled then
    return
  end
  local PufferManager = require("client.slua.logic.download.puffer.puffer_manager")
  local bIsBankExist = PufferManager.IsBankExistByActorID(ActorID)
  local bIsActorInGlobal = self:IsActorInGlobal(ActorID)
  local PublishRegion = Client.GetPublishRegion()
  local bIsKorea = PublishRegion == "KOREA"
  local bIsJapan = PublishRegion == "JAPAN"
  local LocalActorID = ActorID
  local bNeedSwitchActor = not bIsKorea and not bIsJapan and not bIsActorInGlobal or not bIsBankExist
  if bNeedSwitchActor then
    if self.MuteOnGlobal and self.MuteOnGlobal:Get(ActorID) then
      return
    end
    if bIsJapan then
      LocalActorID = 1
    else
      LocalActorID = 0
    end
  end
  if self.AutoLanguage then
    self:PlayAutoLanguageMsg(LocalActorID, MsgID)
    return
  end
  local VoiceTransformSubsystem = SubsystemMgr:Get("VoiceTransformSubsystem")
  if not VoiceTransformSubsystem then
    return
  end
  local BankName = VoiceTransformSubsystem:GetActorBankByID(LocalActorID)
  if not BankName or BankName == "" then
    return
  end
  local bCanPlay = self:CheckCDMsgs(MsgID)
  if not bCanPlay then
    return
  end
  local EventName
  if self.CurrMsg and self.CurrMsg.bAudio3D then
    EventName = string.format("play_chat_%d_%d_3D", LocalActorID, MsgID)
    self:LoadBankAndPlay3D(BankName, EventName, self.CurrMsg.SoundLocation)
  else
    EventName = string.format("play_chat_%d_%d", LocalActorID, MsgID)
    self:LoadBankAndPlay(BankName, EventName)
  end
end
function ChatComponent:InitChatFlagList()
  print(bWriteLog and "ChatComponent:InitChatFlagList [1]")
  self.ChatFlagList:Clear()
  local DataTable = CDataTable.GetTable("FlagIDCfg")
  if not DataTable then
    return
  end
  for i = 0, self.ChatFlagTypeList:Num() - 1 do
    local FlagTypeID = self.ChatFlagTypeList:Get(i)
    local RowName = tostring(FlagTypeID)
    local FlagData = DataTable[RowName]
    if FlagData then
      self.TmpChatIDList:Clear()
      local ChatIDListStr = FlagData.ChatIDList
      if ChatIDListStr and ChatIDListStr ~= "" then
        for ChatIDStr in string.gmatch(ChatIDListStr, "([^|]+)") do
          local ChatID = tonumber(ChatIDStr)
          if ChatID then
            self.TmpChatIDList:AddUnique(ChatID)
          end
        end
      end
      local FlagTypeIndex = FlagData.FlagType - 1
      local FlagTypeEnum
      if FlagTypeIndex == 0 then
        FlagTypeEnum = ChatFlagType.DanagerForward
      elseif FlagTypeIndex == 1 then
        FlagTypeEnum = ChatFlagType.SuppliesHere
      elseif FlagTypeIndex == 2 then
        FlagTypeEnum = ChatFlagType.Congregation
      else
        FlagTypeEnum = ChatFlagType.DanagerForward
      end
      local TraceDist = tonumber(FlagData.TraceDist) or 4000
      local MinDist = tonumber(FlagData.MinDist) or 5
      local QuickChatFlag = QuickChatFlag()
      QuickChatFlag.type = FlagTypeEnum
      QuickChatFlag.chatIDList = self.TmpChatIDList
      QuickChatFlag.AlternateChatID = FlagData.AlternateChatID
      QuickChatFlag.FlagIndex = FlagData.FlagIndex
      QuickChatFlag.traceDist = TraceDist
      QuickChatFlag.minDist = MinDist
      self.ChatFlagList:AddUnique(QuickChatFlag)
    end
  end
  print(bWriteLog and "ChatComponent:InitChatFlagList [2]")
end
function ChatComponent:IsInfectMode()
  local GameState = GameplayData.GetGameState()
  if not slua.isValid(GameState) then
    return false
  end
  local EGameModeType = import("EGameModeType")
  local GameModeType = GameState.GameModeType
  if GameModeType == EGameModeType.EPVEInfectionGameMode then
    return true
  else
    return false
  end
end
function ChatComponent:InitActorIDList()
  if not self.GlobalActorIDList then
    self.GlobalActorIDList = {}
  end
  self.GlobalActorIDList:Clear()
  local DataTable = CDataTable.GetTable("VoiceActorCfg")
  if not DataTable then
    return
  end
  for k, v in pairs(DataTable) do
    if v.IsPlayInGlobal then
      self.GlobalActorIDList:Add(v.ActorID)
    end
  end
end
function ChatComponent:IsVehicleWarMode()
  local GameState = GameplayData.GetGameState()
  local EGameModeType = import("EGameModeType")
  self.bIsVehicleWarMode = slua.isValid(GameState) and (GameState.GameModeType == EGameModeType.EVehicleWar_CAMP or GameState.GameModeType == EGameModeType.EVehicleWar)
  return self.bIsVehicleWarMode
end
function ChatComponent:LoadVehicleModeQuickMsg()
  print(bWriteLog and "ChatComponent:LoadVehicleModeQuickMsg [1]")
  if not self:IsVehicleWarMode() then
    return
  end
  self.ChatQuikcTextIDList_VWMenu:Clear()
  self.ChatQuikcTextIDList_VWTurnplate:Clear()
  local DataTable = CDataTable.GetTable("VehicleWarModeMsgIDCfg")
  if not DataTable then
    return
  end
  local FChatQuickTextInfo = import("ChatQuickTextInfo")
  for k, v in pairs(DataTable) do
    if v.MenuChatIDList and v.MenuChatIDList ~= "" then
      for ChatIDStr in string.gmatch(v.MenuChatIDList, "([^|]+)") do
        local ChatID = tonumber(ChatIDStr)
        if ChatID and self.ChatQuikcTextIDList_VWMenu then
          local ChatTextInfo = FChatQuickTextInfo()
          ChatTextInfo.chatTextID = ChatID
          self.ChatQuikcTextIDList_VWMenu:Add(ChatTextInfo)
        end
      end
    end
    if v.TurnplateChatIDList and v.TurnplateChatIDList ~= "" then
      for ChatIDStr in string.gmatch(v.TurnplateChatIDList, "([^|]+)") do
        local ChatID = tonumber(ChatIDStr)
        if ChatID and self.ChatQuikcTextIDList_VWTurnplate then
          local ChatTextInfo = FChatQuickTextInfo()
          ChatTextInfo.chatTextID = ChatID
          self.ChatQuikcTextIDList_VWTurnplate:Add(ChatTextInfo)
        end
      end
    end
  end
  print(bWriteLog and "ChatComponent:LoadVehicleModeQuickMsg [2]")
end
function ChatComponent:GetActorNameByID()
end
function ChatComponent:DistanceToString(Distance, MsgId, PlayerName)
  Distance = math.floor(Distance)
  local DistanceText = ""
  if 0 < Distance then
    local IsShowDistanceMsgContainsID = false
    if self.ChatFlagList then
      local SimpleMsgID = MsgId % 100000
      for i = 0, self.ChatFlagList:Num() - 1 do
        local ChatFlag = self.ChatFlagList:Get(i)
        if ChatFlag and ChatFlag.chatIDList then
          local bContains = false
          for j = 0, ChatFlag.chatIDList:Num() - 1 do
            if ChatFlag.chatIDList:Get(j) == SimpleMsgID then
              bContains = true
              break
            end
          end
          if bContains then
            IsShowDistanceMsgContainsID = true
            break
          end
        end
      end
    end
    if IsShowDistanceMsgContainsID then
      if 800 <= Distance then
        DistanceText = LocUtil.GetLocalizeResStr(33861)
      else
        DistanceText = LocUtil.LocalizeResFormat(25144, Distance)
      end
    elseif self.SpecialShowDistanceMsgID then
      local SimpleMsgID = MsgId % 100000
      local bContains = false
      for i = 0, self.SpecialShowDistanceMsgID:Num() - 1 do
        if self.SpecialShowDistanceMsgID:Get(i) == SimpleMsgID then
          bContains = true
          break
        end
      end
      if bContains and self.GetSpecialDistanceString then
        DistanceText = self:GetSpecialDistanceString(PlayerName)
      end
    end
    print(bWriteLog and "ChatComponent:DistanceToString [2]", DistanceText)
  end
  return DistanceText
end
function ChatComponent:GetSpecialDistanceString(SendPlayerName)
  print(bWriteLog and "ChatComponent:GetSpecialDistanceString [1]")
  local DistanceText = ""
  local PlayerController = GameplayData.GetPlayerController()
  if not slua.isValid(PlayerController) then
    return DistanceText
  end
  local MyPlayerState = GameplayData.GetPlayerState()
  if not slua.isValid(MyPlayerState) then
    return DistanceText
  end
  local TeamMateList = {}
  if MyPlayerState.GetTeamMatePlayerStateList then
    MyPlayerState:GetTeamMatePlayerStateList(TeamMateList, true)
  end
  local MyCharacter = GameplayData.GetPlayerCharacter()
  if not slua.isValid(MyCharacter) then
    return DistanceText
  end
  local MyLocation = MyCharacter:K2_GetActorLocation()
  for i = 1, #TeamMateList do
    local TeamMate = TeamMateList[i]
    if slua.isValid(TeamMate) then
      local bNameMatch = TeamMate.PlayerName == SendPlayerName
      local ExtraPlayerLiveState = import("ExtraPlayerLiveState")
      local bIsAlive = TeamMate.LiveState ~= ExtraPlayerLiveState.InDied
      if bNameMatch and bIsAlive then
        local TeamMateCharacter
        if TeamMate.GetPlayerCharacter then
          TeamMateCharacter = TeamMate:GetPlayerCharacter()
        end
        if slua.isValid(TeamMateCharacter) then
          local TeamMateLocation = TeamMateCharacter:K2_GetActorLocation()
          local STExtraBlueprintFunctionLibrary = import("STExtraBlueprintFunctionLibrary")
          local Distance = STExtraBlueprintFunctionLibrary.Dist2D(MyLocation, TeamMateLocation)
          local RoundedDistance = math.floor(Distance + 0.5)
          local DistanceInMeters = math.floor(RoundedDistance / 100)
          DistanceText = LocUtil.LocalizeResFormat(25144, DistanceInMeters)
          break
        end
      end
    end
  end
  print(bWriteLog and "ChatComponent:GetSpecialDistanceString [2]")
  return DistanceText
end
function ChatComponent:CheckIsAddReplyBtn(MsgID, PlayerName)
  local NeedReplyMsgID = {
    [29992] = true
  }
  if NeedReplyMsgID[MsgID] then
    EventSystem:postEvent(EVENTTYPE_LIBRARY, EVENTID_LIBRARY_SHOW_REPLY_REVIVE_BTN, PlayerName)
  end
end
function ChatComponent:AddOneMarkToUIInner(bIsMe, TextMsg)
  print(bWriteLog and "ChatComponent:AddOneMarkToUIInner [1]")
  self.IsMe = bIsMe
  if self.IsMe then
    print(bWriteLog and "ChatComponent:AddOneMarkToUIInner [2]")
    self.bIsMarkText = false
    self.addToUIText = TextMsg
    self:AddOneMsgToUIInner(bIsMe)
  else
    print(bWriteLog and "ChatComponent:AddOneMarkToUIInner [3]")
    self.bIsMarkText = true
    self.MarkText = TextMsg
    local ArrayLength = self.MarkTextArray:Num()
    if 2 <= ArrayLength then
      self.MarkTextArray:Remove(1)
    end
    self.MarkTextArray:Add(self.MarkText)
    EventSystem:postEvent(EVENTTYPE_INGAME, EVENTID_INGAME_REFRESH_CHAT)
  end
end
function ChatComponent:SetQuickChatList()
  print(bWriteLog and "ChatComponent:SetQuickChatList [1]")
  if not self.chatQuickList then
    return
  end
  self.chatQuickList:Clear()
  local TextIDList = {}
  if self:IsInfectMode() then
    local PlayerType = self.CurInfectModePlayerType or 0
    if PlayerType == 0 then
      TextIDList = self.ChatQuikcTextIDList_HumanMenu or {}
    elseif PlayerType == 1 then
      TextIDList = self.ChatQuikcTextIDList_ZombieMenu or {}
    elseif PlayerType == 2 or PlayerType == 3 then
      TextIDList = self:GetPlayerChatIDList()
    else
      TextIDList = self.ChatQuikcTextIDList_HumanMenu or {}
    end
  elseif self:IsVehicleWarMode() then
    TextIDList = self.ChatQuikcTextIDList_VWMenu or {}
  else
    TextIDList = self:GetPlayerChatIDList()
  end
  for _, ChatInfo in pairs(TextIDList) do
    local ChatTextID = ChatInfo.chatTextID or 0
    local RowName = tostring(ChatTextID)
    local RealTextID = 0
    local PersonalityVoiceCfg = CDataTable.GetTableData("PersonalityVoiceCfg", ChatTextID)
    local VoiceTextData = CDataTable.GetTableData("VoiceText", RowName)
    if PersonalityVoiceCfg then
      RealTextID = ChatTextID
    elseif VoiceTextData then
      RealTextID = ChatTextID
    else
      RealTextID = ChatTextID % 100000
    end
    local AlternateTextID = 0
    local SupplyTextData = CDataTable.GetTableData("SupplyText", RowName)
    if SupplyTextData then
      AlternateTextID = SupplyTextData.AlternateTextID or 0
    else
      AlternateTextID = 0
    end
    local FQuickChatIDAndAudio = import("QuickChatIDAndAudio")
    local QuickChat = FQuickChatIDAndAudio()
    QuickChat.ChatTextID = ChatTextID
    QuickChat.RealTextID = RealTextID
    QuickChat.AlternateTextID = AlternateTextID
    QuickChat.bIncludeAll = ChatInfo.bIncludeAll or false
    self.chatQuickList:AddUnique(QuickChat)
  end
  EventSystem:postEvent(EVENTTYPE_INGAME, EVENTID_INGAME_SET_QUICKCHATLIST)
  print(bWriteLog and "ChatComponent:SetQuickChatList [2] Count=" .. self.chatQuickList:Num())
end
function ChatComponent:GetPlayerChatIDList()
  local SettingConfig = self.SettingConfig
  if not SettingConfig then
    return self.ChatQuikcTextIDList_HumanMenu or {}
  end
  local PlayerChatIndex = SettingConfig.PlayerChatIndex or 0
  if PlayerChatIndex == 0 then
    return SettingConfig.PlayerChatQuickTextInfoList_1 or {}
  elseif PlayerChatIndex == 1 then
    return SettingConfig.PlayerChatQuickTextInfoList_2 or {}
  elseif PlayerChatIndex == 2 then
    return SettingConfig.PlayerChatQuickTextInfoList_3 or {}
  else
    return SettingConfig.PlayerChatQuickTextInfoList_1 or {}
  end
end
function ChatComponent:SetTurnplateQuickChatList()
  print(bWriteLog and "ChatComponent:SetTurnplateQuickChatList [1]")
  self.TurnplateChatQuickList:Clear()
  local TextIDList = {}
  if self:IsInfectMode() then
    local PlayerType = self.CurInfectModePlayerType or 0
    if PlayerType == 0 then
      TextIDList = self.ChatQuikcTextIDList_HumanTurnplate or {}
    elseif PlayerType == 1 then
      TextIDList = self.ChatQuikcTextIDList_ZombieTurnplate or {}
    elseif PlayerType == 2 or PlayerType == 3 then
      TextIDList = self:GetPlayerTurnplateChatIDList()
    else
      TextIDList = self.ChatQuikcTextIDList_HumanTurnplate or {}
    end
  elseif self:IsVehicleWarMode() then
    TextIDList = self.ChatQuikcTextIDList_VWMenu or {}
  else
    TextIDList = self:GetPlayerTurnplateChatIDList()
  end
  for _, ChatTextInfo in pairs(TextIDList) do
    local ChatTextID = ChatTextInfo.chatTextID or 0
    local RowName = tostring(ChatTextID)
    local RealTextID = 0
    local PersonalityVoiceCfg = CDataTable.GetTableData("PersonalityVoiceCfg", ChatTextID)
    local VoiceTextData = CDataTable.GetTableData("VoiceText", RowName)
    if PersonalityVoiceCfg then
      RealTextID = ChatTextID
    elseif VoiceTextData then
      RealTextID = ChatTextID
    else
      RealTextID = ChatTextID % 100000
    end
    local AlternateTextID = 0
    local SupplyTextData = CDataTable.GetTableData("SupplyText", RowName)
    if SupplyTextData then
      AlternateTextID = SupplyTextData.AlternateTextID or 0
    end
    local FQuickChatIDAndAudio = import("QuickChatIDAndAudio")
    local QuickChat = FQuickChatIDAndAudio()
    QuickChat.ChatTextID = ChatTextID
    QuickChat.RealTextID = RealTextID
    QuickChat.AlternateTextID = AlternateTextID
    QuickChat.bIncludeAll = ChatTextInfo.bIncludeAll or false
    self.TurnplateChatQuickList:Add(QuickChat)
  end
  print(bWriteLog and "ChatComponent:SetTurnplateQuickChatList [2] Count=" .. self.TurnplateChatQuickList:Num())
end
function ChatComponent:GetPlayerTurnplateChatIDList()
  local SettingConfig = self.SettingConfig
  if not SettingConfig then
    return self.ChatQuikcTextIDList_HumanTurnplate or {}
  end
  local PlayerChatIndex = SettingConfig.PlayerChatIndex or 0
  if PlayerChatIndex == 0 then
    return SettingConfig.PlayerWheelChatQuickTextInfoList_1 or {}
  elseif PlayerChatIndex == 1 then
    return SettingConfig.PlayerWheelChatQuickTextInfoList_2 or {}
  elseif PlayerChatIndex == 2 then
    return SettingConfig.PlayerWheelChatQuickTextInfoList_3 or {}
  else
    return SettingConfig.PlayerWheelChatQuickTextInfoList_1 or {}
  end
end
function ChatComponent:LoadInfectModeQuickMsg()
  print(bWriteLog and "ChatComponent:LoadInfectModeQuickMsg [1]")
  if not self:IsInfectMode() then
    return
  end
  self.ChatQuikcTextIDList_HumanMenu:Clear()
  self.ChatQuikcTextIDList_HumanTurnplate:Clear()
  self.ChatQuikcTextIDList_ZombieMenu:Clear()
  self.ChatQuikcTextIDList_ZombieTurnplate:Clear()
  for _, PlayerTypeID in pairs(self.InfectModePlayerType) do
    local RowName = tostring(PlayerTypeID)
    local RowData = CDataTable.GetTableData("InfectModeMsgIDCfg", RowName)
    if RowData then
      local FlagType = RowData.FlagType or 0
      local TurnplateChatIDList = RowData.TurnplateChatIDList or ""
      local MenuChatIDList = RowData.MenuChatIDList or ""
      if TurnplateChatIDList ~= "" then
        local TurnplateIDArray = {}
        for IDStr in string.gmatch(TurnplateChatIDList, "[^|]+") do
          if IDStr ~= "" then
            table.insert(TurnplateIDArray, tonumber(IDStr) or 0)
          end
        end
        local FChatQuickTextInfo = import("ChatQuickTextInfo")
        if FlagType == 0 then
          for _, ID in ipairs(TurnplateIDArray) do
            local ChatTextInfo = FChatQuickTextInfo()
            ChatTextInfo.chatTextID = ID
            self.ChatQuikcTextIDList_HumanTurnplate:AddUnique(ChatTextInfo)
          end
        elseif FlagType == 1 then
          for _, ID in ipairs(TurnplateIDArray) do
            local ChatTextInfo = FChatQuickTextInfo()
            ChatTextInfo.chatTextID = ID
            self.ChatQuikcTextIDList_ZombieTurnplate:AddUnique(ChatTextInfo)
          end
        end
      end
      if MenuChatIDList ~= "" then
        local MenuIDArray = {}
        for IDStr in string.gmatch(MenuChatIDList, "[^|]+") do
          if IDStr ~= "" then
            table.insert(MenuIDArray, tonumber(IDStr) or 0)
          end
        end
        local FChatQuickTextInfo = import("ChatQuickTextInfo")
        if FlagType == 0 then
          for _, ID in ipairs(MenuIDArray) do
            local ChatTextInfo = FChatQuickTextInfo()
            ChatTextInfo.chatTextID = ID
            self.ChatQuikcTextIDList_HumanMenu:AddUnique(ChatTextInfo)
          end
        elseif FlagType == 1 then
          for _, ID in ipairs(MenuIDArray) do
            local ChatTextInfo = FChatQuickTextInfo()
            ChatTextInfo.chatTextID = ID
            self.ChatQuikcTextIDList_ZombieMenu:AddUnique(ChatTextInfo)
          end
        end
      end
    end
  end
  print(bWriteLog and string.format("ChatComponent:LoadInfectModeQuickMsg [5]"))
end
function ChatComponent:GetLocalText(MsgID, ItemID, PlayerKeyString, Distance, PlayerName, ItemCount)
  print(bWriteLog and "ChatComponent:GetLocalText [1] MsgID=" .. MsgID .. " ItemID=" .. ItemID .. " PlayerKeyString=" .. PlayerKeyString .. " Distance=" .. Distance .. " PlayerName=" .. PlayerName .. " ItemCount=" .. ItemCount)
  local GlobalBattleUIFunctionLibrary = require("GameLua.Mod.BaseMod.Client.InGameUI.GlobalBattleUIFunctionLibrary")
  local RealTextID
  local DistanceTextStr = tostring(self:DistanceToString(Distance, MsgID, PlayerName))
  local bPlayerKeyStringInvalid = PlayerKeyString == "nil" or PlayerKeyString == "0"
  local Text = ""
  if ItemID ~= 0 then
    local SupplyTextData = CDataTable.GetTableData("SupplyText", tostring(MsgID))
    if SupplyTextData then
      RealTextID = SupplyTextData.AlternateTextID or 0
      Text = GlobalBattleUIFunctionLibrary:GetLocalizeVoiceText(RealTextID)
      local ItemData = CDataTable.GetTableData("Item", ItemID)
      if ItemData then
        local ItemNameStr = ItemData.ItemName or ""
        local MaxCount = ItemData.MaxCount or 0
        if MaxCount <= 1 then
          Text = LocUtil.LocalizeResFormatByStr(Text, ItemNameStr)
        else
          local CountFormat = LocUtil.LocalizeResFormat(77835, tostring(ItemCount))
          local ItemWithCount = ItemNameStr .. CountFormat
          Text = LocUtil.LocalizeResFormatByStr(Text, ItemWithCount)
        end
      end
    else
      local PersonalityVoiceCfg = CDataTable.GetTableData("PersonalityVoiceCfg", MsgID)
      if PersonalityVoiceCfg then
        Text = PersonalityVoiceCfg.VoiceText or ""
      else
        local VoiceTextData = CDataTable.GetTableData("VoiceText", tostring(MsgID))
        if VoiceTextData then
          Text = GlobalBattleUIFunctionLibrary:GetLocalizeVoiceText(VoiceTextData.VoiceTextId)
        end
      end
    end
    return Text .. DistanceTextStr
  else
    local PersonalityVoiceCfg = CDataTable.GetTableData("PersonalityVoiceCfg", MsgID)
    if PersonalityVoiceCfg then
      Text = PersonalityVoiceCfg.VoiceText or ""
    else
      local VoiceTextData = CDataTable.GetTableData("VoiceText", tostring(MsgID))
      if VoiceTextData then
        Text = GlobalBattleUIFunctionLibrary:GetLocalizeVoiceText(VoiceTextData.VoiceTextId)
      end
    end
  end
  if Text == "" then
    RealTextID = MsgID % 100000
    Text = GlobalBattleUIFunctionLibrary:GetLocalizeVoiceText(RealTextID)
  end
  local CurrentLanguage = Client.GetCurrentLanguage()
  local bIsChineseLanguage = CurrentLanguage == "zh"
  local ActorID = math.floor(MsgID / 100000)
  local bHasActorID = 0 < ActorID
  if bIsChineseLanguage and bHasActorID and Text and Text ~= "" and not self._IgnoreSplitActorNameID[ActorID] then
    local LeftS1, RightS1 = Text:match("^(.-)%s(.+)$")
    local bSplit1 = LeftS1 ~= nil and RightS1 ~= nil
    local TextAfterSplit1 = bSplit1 and RightS1 or Text
    local LeftS2, RightS2 = TextAfterSplit1:match("^(.-)_(.+)$")
    local bSplit2 = LeftS2 ~= nil and RightS2 ~= nil
    local FinalText = bSplit2 and RightS2 or TextAfterSplit1
    return "<ChatQuickMsg>" .. FinalText .. "</>" .. DistanceTextStr
  end
  Text = Text or ""
  if bPlayerKeyStringInvalid then
    return "<ChatQuickMsg>" .. Text .. "</>" .. DistanceTextStr
  end
  local PlayerController = GameplayData.GetPlayerController()
  if not slua.isValid(PlayerController) then
    return "<ChatQuickMsg>" .. Text .. "</>" .. DistanceTextStr
  end
  local PlayerState = GameplayData.GetPlayerState()
  if not slua.isValid(PlayerState) then
    return "<ChatQuickMsg>" .. Text .. "</>" .. DistanceTextStr
  end
  local TeammateList = PlayerState:GetTeamMatePlayerStateList({}, false)
  if not slua.isValid(TeammateList) then
    return "<ChatQuickMsg>" .. Text .. "</>" .. DistanceTextStr
  end
  for i = 0, TeammateList:Num() - 1 do
    local TeammateState = TeammateList:Get(i)
    if slua.isValid(TeammateState) and TeammateState:GetStringPlayerKey() == PlayerKeyString then
      return "<ChatQuickMsg>" .. Text .. " " .. TeammateState.PlayerName .. "</>" .. DistanceTextStr
    end
  end
  return "<ChatQuickMsg>" .. Text .. "</>" .. DistanceTextStr
end
function ChatComponent:HandlePlayerEnterFighting()
  self:InitFirstLangID()
end
function ChatComponent:InitFirstLangID()
  local uPlayerController = self:GetOwner()
  if not slua.isValid(uPlayerController) then
    return
  end
  local logic_chat_voice_const = require("client.slua.logic.chat_voice.logic_chat_voice_const")
  local LangToLang = logic_chat_voice_const.LangToLangID
  local PlayerDataMgr = require("Server.Data.ServerPlayerDataMgr")
  local PlayerInfo = PlayerDataMgr.GetPlayerInfo(uPlayerController.UID)
  if PlayerInfo and PlayerInfo.first_lang then
    self.FirstLangID = LangToLang[PlayerInfo.first_lang] or 1
  else
    self.FirstLangID = 1
  end
  print(bWriteLog and string.format("ChatComponent:InitFirstLangID: %d", self.FirstLangID))
end
function ChatComponent:AddPlayerToBlackList(PlayerName)
  self.ChatBlacklist[PlayerName] = true
end
function ChatComponent:RemovePlayerFromBlackList(PlayerName)
  self.ChatBlacklist[PlayerName] = nil
end
function ChatComponent:CheckPlayerIsBlocked(PlayerName)
  return self.ChatBlacklist[PlayerName]
end
function ChatComponent:IsPersonalizedVoice(msgID)
  log(bWriteLog and "ChatComponent:IsPersonalizedVoice msgID:" .. tostring(msgID))
  if type(msgID) ~= "number" then
    return false
  end
  local actorID = msgID // 100000
  return self._PersonalizedActorID[actorID] and true or false
end
local class = require("class")
local object = require("GameLua.Mod.BaseMod.Common.Core.ActorComponentBase")
local CChatComponent = class(object, nil, ChatComponent)
return CChatComponent
