--[[
 * author : kaishiqi
 * descpt : 组队副本控制器
]]
local ModelFactory      = require('Game.models.TeamQuestModelFactory')
local TeamQuestModel    = ModelFactory.getModelType('TeamQuest')
local TeamPlayerModel   = ModelFactory.getModelType('TeamPlayer')
local TeamCardModel     = ModelFactory.getModelType('TeamCard')
local TeamQuestMediator = class('TeamQuestMediator', mvc.Mediator)

------------ import ------------
local gameMgr           = AppFacade.GetInstance():GetManager("GameManager")
local uiMgr             = AppFacade.GetInstance():GetManager("UIManager")
local petMgr             = AppFacade.GetInstance():GetManager("PetManager")
------------ import ------------

------------ define ------------
local RaidBattleMdtName = 'RaidBattleMediator'
------------ define ------------

function TeamQuestMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'TeamQuestMediator', viewComponent)
end


-------------------------------------------------
-- inheritance method

function TeamQuestMediator:Initial(key)
    self.super.Initial(self, key)

    self.selfPos_        = 0
    self.isTerminal_     = false
    self.teamModel_      = TeamQuestModel.new()
    self.teamSocket_     = self:GetFacade():AddManager('Frame.Manager.TeamSocketManager')
    self.teamReadyMdt_   = nil
    self.teamBattleMdt_  = nil
    self.currentTeamMdt_ = nil
    self.isInBattle      = false
    self.needDissolveTeam = false
    self.chatPanel       = nil
    self.realTimeVoiceChatRoomId = nil
    self.anyoneBattleOver      = false

end


function TeamQuestMediator:CleanupView()

    -- 移除聊天板节点
    if nil ~= self:GetChatPanel() then
        -- 断开组队聊天
        self:DisconnectTeamChat()
        -- 断开实时语音
        self:DisconnectRealTimeVoiceChat()
        
        self:GetChatPanel():DestroyAdditional()
        self:GetChatPanel():DestroySelf()
        self:SetChatPanel(nil)
    end
    
    self:GetFacade():RemoveManager('TeamSocketManager')
    self:exitTeamBattleView_()
    self:exitTeamReadyView_()
end


function TeamQuestMediator:OnRegist()
end
function TeamQuestMediator:OnUnRegist()
end


function TeamQuestMediator:InterestSignals()
    return {

        -------------------------------------------------
        -- server signal

        SIGNALNAMES.TEAM_BOSS_SOCKET_CONNECT,
        SIGNALNAMES.TEAM_BOSS_SOCKET_CONNECTED,
        SIGNALNAMES.TEAM_BOSS_SOCKET_UNEXPECTED,
        SIGNALNAMES.TEAM_BOSS_SOCKET_JOIN_TEAM,
        SIGNALNAMES.TEAM_BOSS_SOCKET_MEMBER_NOTICE,
        SIGNALNAMES.TEAM_BOSS_SOCKET_CARD_CHANGE,
        SIGNALNAMES.TEAM_BOSS_SOCKET_CARD_NOTICE,
        SIGNALNAMES.TEAM_BOSS_SOCKET_CSKILL_CHANGE,
        SIGNALNAMES.TEAM_BOSS_SOCKET_CSKILL_NOTICE,
        SIGNALNAMES.TEAM_BOSS_SOCKET_READY_CHANGE,
        SIGNALNAMES.TEAM_BOSS_SOCKET_READY_NOTICE,
        SIGNALNAMES.TEAM_BOSS_SOCKET_ENTER_BATTLE,
        SIGNALNAMES.TEAM_BOSS_SOCKET_ENTER_NOTICE,
        SIGNALNAMES.TEAM_BOSS_SOCKET_KICK_MEMBER,
        SIGNALNAMES.TEAM_BOSS_SOCKET_KICK_NOTICE,
        SIGNALNAMES.TEAM_BOSS_SOCKET_BATTLE_RESULT,
        SIGNALNAMES.TEAM_BOSS_SOCKET_BATTLE_RESULT_NOTICE,
        SIGNALNAMES.TEAM_BOSS_SOCKET_BOSS_CHANGE,
        SIGNALNAMES.TEAM_BOSS_SOCKET_BOSS_NOTICE,
        SIGNALNAMES.TEAM_BOSS_SOCKET_EXIT_CHANGE,
        SIGNALNAMES.TEAM_BOSS_SOCKET_EXIT_NOTICE,
        SIGNALNAMES.TEAM_BOSS_SOCKET_CAPTAIN_CHANGE,
        SIGNALNAMES.TEAM_BOSS_SOCKET_CAPTAIN_NOTICE,
        SIGNALNAMES.TEAM_BOSS_SOCKET_LOADING_OVER,
        SIGNALNAMES.TEAM_BOSS_SOCKET_LOADING_OVER_NOTICE,
        SIGNALNAMES.TEAM_BOSS_SOCKET_PASSWORD_CHANGE,
        SIGNALNAMES.TEAM_BOSS_SOCKET_PASSWORD_NOTICE,
        SIGNALNAMES.TEAM_BOSS_SOCKET_ATTEND_TIMES_BUY,
        SIGNALNAMES.TEAM_BOSS_SOCKET_ATTEND_TIMES_BOUGHT,
        SIGNALNAMES.TEAM_BOSS_SOCKET_TEAM_DISSOLVED,
        SIGNALNAMES.TEAM_BOSS_SOCKET_TEAM_RECOVER,
        SIGNALNAMES.TEAM_BOSS_SOCKET_BATTLE_OVER,
        SIGNALNAMES.TEAM_BOSS_SOCKET_BATTLE_OVER_NOTICE,
        SIGNALNAMES.TEAM_BOSS_SOCKET_CHOOSE_REWARD,
        SIGNALNAMES.TEAM_BOSS_SOCKET_CHOOSE_REWARD_NOTICE,

        -------------------------------------------------
        -- local signal

        EVENT_RAID_BATTLE_OVER,
        EVENT_RAID_BATTLE_EXIT_TO_TEAM,
        EVENT_RAID_BATTLE_GAME_RESULT,
        EVENT_RAID_UPDATE_PLAYER_LEFT_CHALLENGE_TIMES,
        EVENT_RAID_BATTLE_SCENE_LOADING_OVER,
        EVENT_RAID_BATTLE_OVER_FOR_RESULT,
        'RAID_CHANGE_CARD',
        'RAID_PLAYER_CHANGE_STATUS',
        'START_RAID_BATTLE',
        'RAID_CHANGE_TEAM_PASSWORD',
        'RAID_TEAM_BUY_CHALLENGE_TIMES',
        'RAID_CHANGE_STAGE',
        'RAID_EXIT_TEAM',
        'RAID_CONNECT_REAL_TIME_VOICE_CHAT',
        'RAID_SHOW_CHAT_PANEL',
        'RAID_PLAYER_CHOOSE_REWARD'
    }
end
function TeamQuestMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if name == SIGNALNAMES.TEAM_BOSS_SOCKET_CONNECT then
        self:onToContentTeamSocket_(data)

    elseif name == SIGNALNAMES.TEAM_BOSS_SOCKET_CONNECTED then
        self:onContentedTeamSocket_()

    elseif name == SIGNALNAMES.TEAM_BOSS_SOCKET_UNEXPECTED then
        self:onTeamSocketUnexpected_(data)

    
    -------------------------------------------------
    -- 参与组队 4001
    elseif name == SIGNALNAMES.TEAM_BOSS_SOCKET_JOIN_TEAM then

        self:SendJoinTeamCallback(data.data)    

    -------------------------------------------------
    -- 成员变动 4002
    elseif name == SIGNALNAMES.TEAM_BOSS_SOCKET_MEMBER_NOTICE then

        self:PlayerJoinTeamCallback(data.data)
        
    -------------------------------------------------
    -- 卡牌变更 4003
    elseif name == SIGNALNAMES.TEAM_BOSS_SOCKET_CARD_CHANGE then

        self:SendPlayerCardChangeCallback(data.data)
    
    -------------------------------------------------
    -- 卡牌通知 4004
    elseif name == SIGNALNAMES.TEAM_BOSS_SOCKET_CARD_NOTICE then

        self:PlayerCardChangeCallback(data.data)

    -------------------------------------------------
    -- 主角技变更 4005
    elseif name == SIGNALNAMES.TEAM_BOSS_SOCKET_CSKILL_CHANGE then

        -- TODO --
        if self.sendCaptainSkillChangeData_ then
            local playerSkills = checkstr(self.sendCaptainSkillChangeData_.playerSkills)
            self.teamModel_:setCaptainSkills(string.split(playerSkills, ','))

            self.sendCaptainSkillChangeData_ = nil
        end
        -- TODO --

    -------------------------------------------------
    -- 主角技通知 4006
    elseif name == SIGNALNAMES.TEAM_BOSS_SOCKET_CSKILL_NOTICE then

        -- TODO --
        local playerSkills = checkstr(data.playerSkills)
        self.teamModel_:setCaptainSkills(string.split(playerSkills, ','))
        -- TODO --

    -------------------------------------------------
    -- 准备变更 4007
    elseif name == SIGNALNAMES.TEAM_BOSS_SOCKET_READY_CHANGE then

        self:SendReadyStatusChangeCallback(data.data)

    -------------------------------------------------
    -- 准备通知 4008
    elseif name == SIGNALNAMES.TEAM_BOSS_SOCKET_READY_NOTICE then

        self:ReadyStatusChangeCallback(data.data)

    -------------------------------------------------
    -- 开始进入 4009
    elseif name == SIGNALNAMES.TEAM_BOSS_SOCKET_ENTER_BATTLE then

        self:SendStartBattleCallback(data.data)

    -------------------------------------------------
    -- 进入通知 4010
    elseif name == SIGNALNAMES.TEAM_BOSS_SOCKET_ENTER_NOTICE then

        self:StartBattleCallback(data.data)

    -------------------------------------------------
    -- 踢出成员 4011
    elseif name == SIGNALNAMES.TEAM_BOSS_SOCKET_KICK_MEMBER then

        -- TODO --
        if self.sendKickMemberData_ then
            local playerId  = checkint(self.sendKickMemberData_.attendId)
            local playerPos = self.teamModel_:getPlayerPosById(playerId)
            self.teamModel_:removePlayerModel(playerPos)

            self.sendKickMemberData_ = nil
        end
        -- TODO --

    -------------------------------------------------
    -- 踢人通知 4012
    elseif name == SIGNALNAMES.TEAM_BOSS_SOCKET_KICK_NOTICE then

        -- TODO --
        local playerId  = checkint(data.playerId)
        local playerPos = self.teamModel_:getPlayerPosById(playerId)
        self.teamModel_:removePlayerModel(playerPos)
        -- TODO --

    -------------------------------------------------
    -- 战斗结束 4018
    elseif name == SIGNALNAMES.TEAM_BOSS_SOCKET_BATTLE_RESULT then

        self:SendRaidBattleOverCallback(data.data)        

    -------------------------------------------------
    -- 战斗结束通知 4019
    elseif name == SIGNALNAMES.TEAM_BOSS_SOCKET_BATTLE_RESULT_NOTICE then

        self:RaidBattleOverCallback(data.data)
        
    -------------------------------------------------
    -- BOSS变更 4022
    elseif name == SIGNALNAMES.TEAM_BOSS_SOCKET_BOSS_CHANGE then

        -- 更换关卡
        self:SendChangeBossCallback(data.data)

    -------------------------------------------------
    -- BOSS通知 4023
    elseif name == SIGNALNAMES.TEAM_BOSS_SOCKET_BOSS_NOTICE then

        self:ChangeBossCallback(data.data)

    -------------------------------------------------
    -- 退出组队 4024
    elseif name == SIGNALNAMES.TEAM_BOSS_SOCKET_EXIT_CHANGE then

        self:SendExitTeamQuestCallback(data.data)

    -------------------------------------------------
    -- 退出通知 4025
    elseif name == SIGNALNAMES.TEAM_BOSS_SOCKET_EXIT_NOTICE then

        self:ExitTeamQuestCallback(data.data)

    -------------------------------------------------
    -- 队长变更 4026
    elseif name == SIGNALNAMES.TEAM_BOSS_SOCKET_CAPTAIN_CHANGE then

        -- TODO --
        if self.sendCaptainChangeData_ then
            local playerId = checkint(self.sendCaptainChangeData_.captainId)
            self.teamModel_:setCaptainId(playerId)

            self.sendCaptainChangeData_ = nil
        end
        -- TODO --

    -------------------------------------------------
    -- 队长通知 4027
    elseif name == SIGNALNAMES.TEAM_BOSS_SOCKET_CAPTAIN_NOTICE then

        -- TODO --
        local playerId = checkint(data.captainId)
        self.teamModel_:setCaptainId(playerId)
        -- TODO --

    -------------------------------------------------
    -- 加载完毕 4029
    elseif name == SIGNALNAMES.TEAM_BOSS_SOCKET_LOADING_OVER then

        self:SendBattleLoadingOverCallback(data.data)

    -------------------------------------------------
    -- 加载完毕开始战斗通知 4030
    elseif name == SIGNALNAMES.TEAM_BOSS_SOCKET_LOADING_OVER_NOTICE then

        self:BattleLoadingOverCallback()

    -------------------------------------------------
    -- 密码变更 4031
    elseif name == SIGNALNAMES.TEAM_BOSS_SOCKET_PASSWORD_CHANGE then

        self:SendChangePasswordCallback()

    -------------------------------------------------
    -- 密码通知 4032
    elseif name == SIGNALNAMES.TEAM_BOSS_SOCKET_PASSWORD_NOTICE then

        self:ChangePasswordCallback(data.data)

    -------------------------------------------------
    -- 参与次数购买 4033
    elseif name == SIGNALNAMES.TEAM_BOSS_SOCKET_ATTEND_TIMES_BUY then

        self:SendBuyAttendTimesCallback(data.data)

    -------------------------------------------------
    -- 次数购买成功 4034
    elseif name == SIGNALNAMES.TEAM_BOSS_SOCKET_ATTEND_TIMES_BOUGHT then

        self:BuyAttendTimesCallback(data.data)

    -------------------------------------------------
    -- 队伍被解散 4035
    elseif name == SIGNALNAMES.TEAM_BOSS_SOCKET_TEAM_DISSOLVED then

        self:TeamDissolveCallback(data.data)

    -------------------------------------------------
    -- 房主重连逻辑 4036
    elseif name == SIGNALNAMES.TEAM_BOSS_SOCKET_TEAM_RECOVER then

        self:TeamRecoverCallback(data.data)

    -------------------------------------------------
    -- 战斗结束等待队友 4037
    elseif name == SIGNALNAMES.TEAM_BOSS_SOCKET_BATTLE_OVER then

        self:SendRaidBattleOverAndWaitTeammateCallback(data.data)

    -------------------------------------------------
    -- 战斗结束等待队友通知 4038
    elseif name == SIGNALNAMES.TEAM_BOSS_SOCKET_BATTLE_OVER_NOTICE then

        self:AllPlayerBattleOverCallback(data.data)

    -------------------------------------------------
    -- 战斗结束等待队友通知 4039
    elseif name == SIGNALNAMES.TEAM_BOSS_SOCKET_CHOOSE_REWARD then

        self:SendChooseRaidRewardCallback(data.data)

    -------------------------------------------------
    -- 战斗结束等待队友通知 4040
    elseif name == SIGNALNAMES.TEAM_BOSS_SOCKET_CHOOSE_REWARD_NOTICE then

        self:ChooseRaidRewardCallback(data.data)

    -------------------------------------------------
    -- lcoal 更换卡牌请求
    elseif 'RAID_CHANGE_CARD' == name then

        self:SendPlayerCardChange(data)

    -------------------------------------------------
    -- lcoal 玩家切换准备状态
    elseif 'RAID_PLAYER_CHANGE_STATUS' == name then

        self:SendReadyStatusChange(data)

    -------------------------------------------------
    -- lcoal 房主请求开始组队战斗
    elseif 'START_RAID_BATTLE' == name then

        self:SendStartBattle()

    -------------------------------------------------
    -- lcoal 玩家加载完毕
    elseif EVENT_RAID_BATTLE_SCENE_LOADING_OVER == name then

        self:BattleLoadingOver()

    -------------------------------------------------
    -- lcoal 战斗结束
    elseif EVENT_RAID_BATTLE_OVER == name then

        self:RaidBattleOver(data)

    -------------------------------------------------
    -- lcoal 返回组队界面
    elseif EVENT_RAID_BATTLE_EXIT_TO_TEAM == name then

        self:reenterTeamReadyView_()

    -------------------------------------------------
    -- lcoal 战斗结算成功
    elseif EVENT_RAID_BATTLE_GAME_RESULT == name then

        self:UpdateAllPlayerDataAfterBattle(data)

    -------------------------------------------------
    -- lcoal 刷新玩家剩余挑战次数
    elseif EVENT_RAID_UPDATE_PLAYER_LEFT_CHALLENGE_TIMES == name then

        local playerId = checkint(data.playerId)
        local times = nil
        if data.deltaValue then
            local playerModel = self.teamModel_:getPlayerModel(self.teamModel_:getPlayerPosById(playerId))
            if playerModel then
                times = math.max(0, checkint(playerModel:getAttendTimes()) + data.deltaValue)
            end
        end

        if times then
            self:checkPlayerLeftChallengeTimesChange_(playerId, times)
        end

    -------------------------------------------------
    -- lcoal 组队战斗结束开始请求结算
    elseif EVENT_RAID_BATTLE_OVER_FOR_RESULT == name then

        self:RaidBattleRequestForResult(data)

    -------------------------------------------------
    -- lcoal 修改密码
    elseif 'RAID_CHANGE_TEAM_PASSWORD' == name then

        self:SendPasswordChange(data)

    -------------------------------------------------
    -- lcoal 挑战次数变更
    elseif 'RAID_TEAM_BUY_CHALLENGE_TIMES' == name then

        self:SendBuyAttendTimes()

    -------------------------------------------------
    -- lcoal 组队boss变更
    elseif 'RAID_CHANGE_STAGE' == name then

        self:SendChangeBoss(data)

    -------------------------------------------------
    -- lcoal 退出队伍
    elseif 'RAID_EXIT_TEAM' == name then

        self:SendExitTeamQuest()

    -------------------------------------------------
    -- lcoal 连接实时语音
    elseif 'RAID_CONNECT_REAL_TIME_VOICE_CHAT' == name then

        self:ConnectRealTimeVoiceChat()

    -------------------------------------------------
    -- lcoal 连接实时语音
    elseif 'RAID_SHOW_CHAT_PANEL' == name then

        self:ShowChatPanel(data)

    -------------------------------------------------
    -- lcoal 发送选择奖励
    elseif 'RAID_PLAYER_CHOOSE_REWARD' == name then

        self:PlayerChooseReward(data)

    end


end
---------------------------------------------------
-- tcp logic handler begin --
---------------------------------------------------
-- /******************************************************************************
--  * NetCmd.TEAM_BOSS_JOIN_TEAM 4001 加入队伍
--  * NetCmd.TEAM_BOSS_MEMBER_NOTICE 4002 加入队伍通知
-- \******************************************************************************
--[[
加入队伍回调处理
@params responseData table 服务器返回
--]]
function TeamQuestMediator:SendJoinTeamCallback(responseData)
    -- 刷新数据
    self.teamModel_:setCaptainId(checkint(responseData.captainId))

    self:RefreshPlayersAndCards(responseData.players, responseData.cards)

    -- 加入组队聊天
    self:ConnectTeamChat()

    -- -- 刷新玩家数据
    -- for pos, playerData in pairs(responseData.players or {}) do
    --     self:checkPlayerModelChange_(checkint(pos), playerData)
    -- end

    -- -- 刷新卡牌数据
    -- local stageId = checkint(self:getTeamModel():getTeamBossId())
    -- local stageConfig = CommonUtils.GetQuestConf(stageId)
    -- local maxCardsAmount = checkint(stageConfig.attendCardNumber)

    -- for i = 1, maxCardsAmount do
    --     local pos = i
    --     local cardData = responseData.cards[tostring(pos)]
    --     if nil == cardData then
    --         cardData = {cardId = TeamCardModel.REMOVE_CARD_ID}
    --     end
    --     local preCardModel = self:getTeamModel():getCardModel(pos)
    --     if nil == preCardModel and TeamCardModel.REMOVE_CARD_ID == cardData.cardId then
    --         -- 防止空状态下卡
    --     else
    --         self:checkCardModelChange_(pos, cardData)
    --     end
    -- end

    -- for pos, cardData in pairs(responseData.cards or {}) do
    --     self:checkCardModelChange_(checkint(pos), cardData)
    -- end

    -- 进入界面
    if not self.currentTeamMdt_ then
        self:enterTeamReadyView_()
    end
end
--[[
有人加入队伍通知
@params responseData table 服务器返回信息
--]]
function TeamQuestMediator:PlayerJoinTeamCallback(responseData)
    self:RefreshPlayersAndCards(responseData.players, responseData.cards)
    -- -- 刷新一次所有的玩家数据
    -- local playersData = responseData.players
    -- if playersData then
    --     for pos, playerData in pairs(playersData) do
    --         self:checkPlayerModelChange_(checkint(pos), playerData)
    --     end
    -- end
end
--[[
刷新玩家和卡牌数据
@params players map 玩家数据
@params cards map 卡牌数据
--]]
function TeamQuestMediator:RefreshPlayersAndCards(players, cards)
    local stageId = checkint(self:getTeamModel():getTeamBossId())
    local stageConfig = CommonUtils.GetQuestConf(stageId)

    local maxPlayersAmount = checkint(stageConfig.attendNumber)
    for i = 1, maxPlayersAmount do
        local pos = i
        local playerData = players[tostring(pos)]
        if nil == playerData then
            local prePlayerModel = self:getTeamModel():getPlayerModel(pos)
            if nil ~= prePlayerModel and 0 ~= prePlayerModel:getPlayerId() then
                -- 下掉玩家
                self:checkPlayerExitRoom_(checkint(prePlayerModel.playerId), self:getTeamModel():getTeamId())
            end
        else
            -- 玩家数据不为空
            self:checkPlayerModelChange_(pos, playerData)
        end
    end

    local maxCardsAmount = checkint(stageConfig.attendCardNumber)
    for i = 1, maxCardsAmount do
        local pos = i
        local cardData = cards[tostring(pos)]
        if nil == cardData then
            cardData = {cardId = TeamCardModel.REMOVE_CARD_ID}
        end
        local preCardModel = self:getTeamModel():getCardModel(pos)
        if nil == preCardModel and TeamCardModel.REMOVE_CARD_ID == cardData.cardId then
            -- 防止空状态下卡
        else
            self:checkCardModelChange_(pos, cardData)
        end
    end
end
-- /******************************************************************************
--  * NetCmd.TEAM_BOSS_CARD_CHANGE 4003 卡牌变更
--  * NetCmd.TEAM_BOSS_CARD_NOTICE 4004 卡牌变更通知
-- \******************************************************************************
--[[
发送更换卡牌
@params data table {
    playerCardId int 玩家卡牌数据库id
    position int 卡牌位置
}
--]]
function TeamQuestMediator:SendPlayerCardChange(data)
    local playerCardId = checkint(data.playerCardId)
    local position = checkint(data.position)

    self.sendPlayerCardChangeData_ = {
        playerCardId = playerCardId,
        position = position
    }
    self.teamSocket_:sendData(NetCmd.TEAM_BOSS_CARD_CHANGE, self.sendPlayerCardChangeData_)
end
--[[
发送更换卡牌回调
@params responseData table 服务器返回信息
--]]
function TeamQuestMediator:SendPlayerCardChangeCallback(responseData)
    if self.sendPlayerCardChangeData_ then
        local pos = checkint(self.sendPlayerCardChangeData_.position)
        local newPlayerCardId = checkint(self.sendPlayerCardChangeData_.playerCardId)
        local cardData = nil

        -- 判断一次是否是移除卡牌
        if TeamCardModel.REMOVE_CARD_ID == newPlayerCardId then
            cardData = {cardId = TeamCardModel.REMOVE_CARD_ID}
        else
            cardData = clone(gameMgr:GetCardDataById(newPlayerCardId))
            if 0 ~= checkint(cardData.playerPetId) and (nil == cardData.pets or 0 >= table.nums(cardData.pets)) then
                local oldPetData = gameMgr:GetPetDataById(checkint(cardData.playerPetId))
                -- 转换一次数据
                cardData.pets = {
                    ['1'] = petMgr.ConvertOldPetData2NewPetData(oldPetData)
                }
            end
        end

        ------------ warning ------------
        -- 此处插入一次玩家id 本玩家id
        if nil == cardData.playerId or 0 == checkint(cardData.playerId) then
            cardData.playerId = checkint(gameMgr:GetUserInfo().playerId)
        end
        ------------ warning ------------

        self:checkPlayerCardModelChange_(pos, cardData)

        self.sendPlayerCardChangeData_ = nil

        uiMgr:ShowInformationTips(__('变更成功!!!'))
    end
end
--[[
卡牌变更通知回调
@params responseData table 服务器返回信息
--]]
function TeamQuestMediator:PlayerCardChangeCallback(responseData)
    local cardData = responseData
    local pos = checkint(cardData.place)
    self:checkPlayerCardModelChange_(pos, cardData)
end
-- /******************************************************************************
--  * NetCmd.TEAM_BOSS_READY_CHANGE 4007 玩家准备状态变更
--  * NetCmd.TEAM_BOSS_READY_NOTICE 4008 玩家准备状态变更通知
-- \******************************************************************************
--[[
发送玩家准备状态变更
@params data table {
    ready TeamPlayerModel.READY_EVENT 准备事件状态
}
--]]
function TeamQuestMediator:SendReadyStatusChange(data)
    local ready = data.ready

    self.sendReadyStatusChangeData_ = {
        ready = ready
    }
    self.teamSocket_:sendData(NetCmd.TEAM_BOSS_READY_CHANGE, self.sendReadyStatusChangeData_)
end
--[[
发送准备状态变更回调
@params responseData table 服务器返回信息
--]]
function TeamQuestMediator:SendReadyStatusChangeCallback(responseData)
    if nil ~= responseData.showCaptcha and 0 ~= checkint(responseData.showCaptcha) then
        -- 需要显示验证码
        AppFacade.GetInstance():DispatchObservers('SHOW_CAPTCHA_VIEW', {callback = function ()
            -- 验证码验证码结束 直接继续
            if nil ~= self.sendReadyStatusChangeData_ then
                local playerId = checkint(gameMgr:GetUserInfo().playerId)
                local ready = checkint(self.sendReadyStatusChangeData_.ready)
                self:checkPlayerStatusChange_(playerId, ready)

                self.sendReadyStatusChangeData_ = nil
            end
        end})
    else
        -- 不需要显示验证码 直接继续
        if nil ~= self.sendReadyStatusChangeData_ then
            local playerId = checkint(gameMgr:GetUserInfo().playerId)
            local ready = checkint(self.sendReadyStatusChangeData_.ready)
            self:checkPlayerStatusChange_(playerId, ready)

            self.sendReadyStatusChangeData_ = nil
        end
    end
end
--[[
准备状态变更通知
@params responseData table 服务器返回信息
--]]
function TeamQuestMediator:ReadyStatusChangeCallback(responseData)
    -- 刷新玩家数据
    self:checkPlayerStatusChange_(checkint(responseData.playerId), checkint(responseData.ready))
end
-- /******************************************************************************
--  * NetCmd.TEAM_BOSS_ENTER_BATTLE 4009 房主点击进入战斗
--  * NetCmd.TEAM_BOSS_ENTER_NOTICE 4010 房主点击进入战斗通知
-- \******************************************************************************
--[[
发送进入战斗
--]]
function TeamQuestMediator:SendStartBattle()
    -- 向服务器请求一次随机数配置
    self.sendStartBattleData_ = {
        min = 1,
        max = 1000,
        num = 100
    }
    self.teamSocket_:sendData(NetCmd.TEAM_BOSS_ENTER_BATTLE, self.sendStartBattleData_)
end
--[[
发送进入战斗回调
@params responseData table 服务器返回信息
--]]
function TeamQuestMediator:SendStartBattleCallback(responseData)
    if nil ~= responseData.showCaptcha and 0 ~= checkint(responseData.showCaptcha) then
        -- 需要显示验证码
        AppFacade.GetInstance():DispatchObservers('SHOW_CAPTCHA_VIEW', {callback = function ()
            -- 验证码验证码结束 直接继续
            if nil ~= self.sendStartBattleData_ then
                -- 设置战斗开始
                self:SetAnyoneBattleOver(false)

                -- 创建战斗随机数配置数据
                local randomvalues = checktable(responseData.random)
                local randomConfig = BattleRandomConfigStruct.New(
                    nil,
                    randomvalues,
                    checkint(responseData.min),
                    checkint(responseData.max),
                    checkint(responseData.num)
                )
                local stageId = checkint(responseData.teamBossId)
                self.sendStartBattleData_ = nil

                self:ReadyEnterBattle(stageId, randomConfig)
            end
        end})
    else
        -- 不需要显示验证码 直接继续
        if nil ~= self.sendStartBattleData_ then
            -- 设置战斗开始
            self:SetAnyoneBattleOver(false)

            -- 创建战斗随机数配置数据
            local randomvalues = checktable(responseData.random)
            local randomConfig = BattleRandomConfigStruct.New(
                nil,
                randomvalues,
                checkint(responseData.min),
                checkint(responseData.max),
                checkint(responseData.num)
            )
            local stageId = checkint(responseData.teamBossId)
            self.sendStartBattleData_ = nil

            self:ReadyEnterBattle(stageId, randomConfig)
        end
    end
end
--[[
进入战斗通知回调
@params responseData table 服务器返回信息
--]]
function TeamQuestMediator:StartBattleCallback(responseData)
    -- 额外处理一次 如果已经存在战斗管理器则不再进入战斗
    if nil ~= AppFacade.GetInstance():RetrieveMediator(RaidBattleMdtName) then
        return
    end

    -- 设置战斗开始
    self:SetAnyoneBattleOver(false)

    local randomvalues = checktable(responseData.random)
    local randomConfig = BattleRandomConfigStruct.New(
        nil,
        randomvalues,
        checkint(responseData.min),
        checkint(responseData.max),
        checkint(responseData.num)
    )
    local stageId = checkint(responseData.teamBossId)
    self:ReadyEnterBattle(stageId, randomConfig)
end
-- /******************************************************************************
--  * NetCmd.TEAM_BOSS_BATTLE_RESULT 4018 战斗结束
--  * NetCmd.TEAM_BOSS_BATTLE_RESULT_NOTICE 4019 其他人战斗结束
-- \******************************************************************************
--[[
发送战斗结束
@params data table
--]]
function TeamQuestMediator:SendRaidBattleOver(data)
    self.sendRaidBattleOverData_ = data
    -- dump(self.sendRaidBattleOverData_)
    self.teamSocket_:sendData(NetCmd.TEAM_BOSS_BATTLE_RESULT, self.sendRaidBattleOverData_)
end
--[[
发送战斗结束回调
@params responseData table 服务器返回信息
--]]
function TeamQuestMediator:SendRaidBattleOverCallback(responseData)
    if nil ~= self.sendRaidBattleOverData_ then
        -- 设置所有人状态未为准备
        self:CancelAllPlayerReadyAfterBattle()
        -- 设置有人战斗结束
        self:SetAnyoneBattleOver(true)

        self:RaidBattleResultCallback(responseData)
        self.sendRaidBattleOverData_ = nil
    end
end
--[[
战斗结束通知回调
@params responseData table 服务器返回信息
--]]
function TeamQuestMediator:RaidBattleOverCallback(responseData)
    -- 设置所有人状态未为准备
    self:CancelAllPlayerReadyAfterBattle()
    -- 设置有人战斗结束
    self:SetAnyoneBattleOver(true)

    -- 处理其他玩家的结算信息
    self:UpdateOtherPlayerDataAfterBattle(responseData)
end
--[[
战后设置所有人状态未为准备
--]]
function TeamQuestMediator:CancelAllPlayerReadyAfterBattle()
    if not self:GetAnyoneBattleOver() then
        -- 第一次收到结算时通知时 设置所有人状态为未准备
        for pos, playerModel in pairs(self.teamModel_:getPlayerModelMap()) do
            if 0 ~= playerModel:getPlayerId() then
                playerModel:setStatus(TeamPlayerModel.STATUS_IDLE)
            end
        end
    end
end
-- /******************************************************************************
--  * NetCmd.TEAM_BOSS_BOSS_CHANGE 4022 boss变更
--  * NetCmd.TEAM_BOSS_BOSS_NOTICE 4023 boss变更通知
-- \******************************************************************************
--[[
发送变更boss
@params data table {
    stageId int 关卡id
}
--]]
function TeamQuestMediator:SendChangeBoss(data)
    local bossId = checkint(data.stageId)
    self.sendChangeBossData_ = {
        teamBossId = bossId
    }
    self.teamSocket_:sendData(NetCmd.TEAM_BOSS_BOSS_CHANGE, self.sendChangeBossData_)
end
--[[
变更boss回调
@params responseData table 服务器返回数据
--]]
function TeamQuestMediator:SendChangeBossCallback(responseData)
    if nil ~= self.sendChangeBossData_ then
        local stageId = checkint(self.sendChangeBossData_.teamBossId)
        self:ChangeStage(stageId)
        self.sendChangeBossData_ = nil
    end
end
--[[
变更boss
@params responseData table 服务器返回数据
--]]
function TeamQuestMediator:ChangeBossCallback(responseData)
    local stageId = checkint(responseData.teamBossId)
    self:ChangeStage(stageId)

    ------------ view ------------
    uiMgr:ShowInformationTips(__('关卡变更!!!'))
    ------------ view ------------
end
--[[
变更关卡
@params stageId int 关卡id
--]]
function TeamQuestMediator:ChangeStage(stageId)
    -- 设置关卡id
    self.teamModel_:setTeamBossId(stageId)

    -- 将所有玩家状态置为未准备
    for pos, playerModel in pairs(self.teamModel_:getPlayerModelMap()) do
        if 0 ~= playerModel:getPlayerId() then
            playerModel:setStatus(TeamPlayerModel.STATUS_IDLE)
            -- 广播一次事件
            AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.TEAM_BOSS_MODEL_PLAYER_STATUS_CHANGE, {playerId = checkint(playerModel:getPlayerId())})
        end
    end

    AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.TEAM_BOSS_MODEL_BOSS_CHANGE, {stageId = stageId})
end
-- /******************************************************************************
--  * NetCmd.TEAM_BOSS_EXIT_CHANGE 4024 退出组队
--  * NetCmd.TEAM_BOSS_EXIT_NOTICE 4025 退出组队通知
-- \******************************************************************************
--[[
发送退出队伍
--]]
function TeamQuestMediator:SendExitTeamQuest()
    self.teamSocket_:sendData(NetCmd.TEAM_BOSS_EXIT_CHANGE)
end
--[[
发送退出队伍回调
@params responseData table 服务器返回数据
--]]
function TeamQuestMediator:SendExitTeamQuestCallback(responseData)
    -- 断开长连接 退出队伍
    self:onExitTeamQuest_()
end
--[[
玩家退出队伍通知回调
@params responseData table 服务器返回数据
--]]
function TeamQuestMediator:ExitTeamQuestCallback(responseData)
    local playerId = checkint(responseData.playerId)
    local questTeamId = checkint(responseData.questTeamId)
    self:checkPlayerExitRoom_(playerId, questTeamId)
end
-- /******************************************************************************
--  * NetCmd.TEAM_BOSS_LOADING_OVER 4029 战斗加载结束
--  * NetCmd.TEAM_BOSS_LOADING_OVER_NOTICE 4030 全员战斗加载结束开始战斗通知
-- \******************************************************************************
--[[
发送加载完成
--]]
function TeamQuestMediator:SendBattleLoadingOver()
    self.teamSocket_:sendData(NetCmd.TEAM_BOSS_LOADING_OVER)
end
--[[
发送加载完成回调
@params responseData table 服务器返回信息
--]]
function TeamQuestMediator:SendBattleLoadingOverCallback(responseData)
    AppFacade.GetInstance():DispatchObservers('RAID_BATTLE_SET_START_COUNTDOWN', {countdown = checkint(responseData.beginLeftSeconds)})
end
--[[
加载完成开始战斗通知回调
@params responseData table 服务器返回信息
--]]
function TeamQuestMediator:BattleLoadingOverCallback(responseData)
    -- 开始战斗
    self:RaidBattleStartFight()
end
-- /******************************************************************************
--  * NetCmd.TEAM_BOSS_PASSWORD_CHANGE 4031 密码变更
--  * NetCmd.TEAM_BOSS_PASSWORD_NOTICE 4032 密码变更通知
-- \******************************************************************************
--[[
请求密码变更
@params data table {
    password string 密码
}
--]]
function TeamQuestMediator:SendPasswordChange(data)
    self.sendPasswordChangeData_ = {
        password = checkstr(data.password)
    }
    self.teamSocket_:sendData(NetCmd.TEAM_BOSS_PASSWORD_CHANGE, self.sendPasswordChangeData_)
end
--[[
请求密码变更回调处理
--]]
function TeamQuestMediator:SendChangePasswordCallback()
    if nil ~= self.sendPasswordChangeData_ then
        local password = checkstr(self.sendPasswordChangeData_.password)
        self:ChangePassword(password)

        self.sendPasswordChangeData_ = nil
    end
end
--[[
密码变更处理
@params responseData table 服务器返回数据
--]]
function TeamQuestMediator:ChangePasswordCallback(responseData)
    local password = tostring(responseData.password)
    self:ChangePassword(password)
end
--[[
变更密码
@params password string 密码
--]]
function TeamQuestMediator:ChangePassword(password)
    self.teamModel_:setPassword(password)
    AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.TEAM_BOSS_MODEL_PASSWORD_CHANGE, {password = password})
end
-- /******************************************************************************
--  * NetCmd.TEAM_BOSS_ATTEND_TIMES_BUY 4033 购买次数
--  * NetCmd.TEAM_BOSS_ATTEND_TIMES_BOUGHT 4034 购买次数通知
-- \******************************************************************************
--[[
发送购买次数
--]]
function TeamQuestMediator:SendBuyAttendTimes()
    self.sendBuyAttendTimesData_ = {
        teamTypeId = self.teamModel_:getQuestTypeId(), 
    }
    self.teamSocket_:sendData(NetCmd.TEAM_BOSS_ATTEND_TIMES_BUY, self.sendBuyAttendTimesData_)
end
--[[
购买次数回调
@params responseData table 服务器返回数据
--]]
function TeamQuestMediator:SendBuyAttendTimesCallback(responseData)
    if nil ~= self.sendBuyAttendTimesData_ then
        ------------ data ------------
        -- 扣除消耗
        local diamondInfo = {
            {goodsId = DIAMOND_ID, num = checkint(responseData.diamond) - gameMgr:GetAmountByIdForce(DIAMOND_ID)}
        }
        CommonUtils.DrawRewards(diamondInfo)

        -- 扣除购买次数
        self.teamModel_:setLeftBuyTimes(self.teamModel_:getLeftBuyTimes() - 1)

        -- 刷新玩家剩余次数
        local playerId = checkint(gameMgr:GetUserInfo().playerId)
        local playerPos = self.teamModel_:getPlayerPosById(playerId)
        local playerModel = self.teamModel_:getPlayerModel(playerPos)
        local newTimes = checkint(playerModel:getAttendTimes()) + checkint(CommonUtils.getVipTotalLimitByField('questTeamBuyNum'))
        self:checkPlayerLeftChallengeTimesChange_(checkint(gameMgr:GetUserInfo().playerId), newTimes)

        self.sendBuyAttendTimesData_ = nil
        ------------ data ------------

        ------------ view ------------
        -- 显示购买成功
        uiMgr:ShowInformationTips(__('购买挑战次数成功!!!'))
        ------------ view ------------
    end
end
--[[
购买次数通知
@params responseData table 服务器返回数据
--]]
function TeamQuestMediator:BuyAttendTimesCallback(responseData)
    local playerId = checkint(responseData.playerId)
    local leftChallengeTimes = checkint(responseData.leftAttendTimes)
    self:checkPlayerLeftChallengeTimesChange_(playerId, leftChallengeTimes)
end
-- /******************************************************************************
--  * NetCmd.TEAM_BOSS_TEAM_DISSOLVED 4035 队伍被解散通知
--  * NetCmd.TEAM_BOSS_TEAM_RECOVER 4036 房间取消解散
-- \******************************************************************************
--[[
队伍被解散通知
@params responseData table 服务器返回数据
--]]
function TeamQuestMediator:TeamDissolveCallback(responseData)
    -- 判断是否在游戏中
    if self:IsInBattle() then
        -- 如果在战斗中 延迟解散
        self:SetNeedDissolveTeam(true)
        -- 发送信号
        AppFacade.GetInstance():DispatchObservers(EVENT_RAID_TEAM_DISSOLVE)
    else
        -- 不在战斗中 直接解散
        self:TeamDissolve()
    end
end
--[[
解散队伍
--]]
function TeamQuestMediator:TeamDissolve()
    self.isTerminal_ = true
    gameMgr:ShowGameAlertView({
        text = __('队伍已被解散!!!'),
        isOnlyOK = true,
        callback = function ()
            self:toExit()
        end
    })
end
--[[
房间取消解散通知
@params responseData table 服务器返回数据
--]]
function TeamQuestMediator:TeamRecoverCallback(responseData)
    self:TeamRecover()
end
--[[
房间取消解散
--]]
function TeamQuestMediator:TeamRecover()
    self:SetNeedDissolveTeam(false)
end
-- /******************************************************************************
--  * NetCmd.TEAM_BOSS_BATTLE_OVER 4037 组队战斗结束通知
--  * NetCmd.TEAM_BOSS_BATTLE_OVER_NOTICE 4038 组队战斗结束通知
-- \******************************************************************************
--[[
发送组队战斗结束并等待队友
@params data table {
    fightData string 战斗数据
    isPassed int 是否过关
}
--]]
function TeamQuestMediator:SendRaidBattleOverAndWaitTeammate(data)
    self.sendRaidBattleOverAndWaitTeammateData_ = data
    self.teamSocket_:sendData(NetCmd.TEAM_BOSS_BATTLE_OVER, self.sendRaidBattleOverAndWaitTeammateData_)
end
--[[
发送组队战斗结束并等待队友回调
@params responseData table 服务器返回数据
--]]
function TeamQuestMediator:SendRaidBattleOverAndWaitTeammateCallback(responseData)
    if nil ~= self.sendRaidBattleOverAndWaitTeammateData_ then
        AppFacade.GetInstance():DispatchObservers(EVENT_RAID_BATTLE_OVER_AND_WAIT_TEAMMATE, {countdown = checkint(responseData.endLeftSeconds)})
        self.sendRaidBattleOverAndWaitTeammateData_ = nil
    end
end
--[[
组队战斗全员结束通知
@params responseData table 服务器返回数据
--]]
function TeamQuestMediator:AllPlayerBattleOverCallback(responseData)
    AppFacade.GetInstance():DispatchObservers(EVENT_RAID_BATTLE_ALL_MEMBER_OVER)
end
-- /******************************************************************************
--  * NetCmd.TEAM_BOSS_BATTLE_OVER 4039 选择奖励
--  * NetCmd.TEAM_BOSS_BATTLE_OVER_NOTICE 4040 选择奖励通知
-- \******************************************************************************
--[[
发送选择奖励
--]]
function TeamQuestMediator:SendChooseRaidReward()
    self.teamSocket_:sendData(NetCmd.TEAM_BOSS_CHOOSE_REWARD)
end
--[[
发送选择奖励回调
--]]
function TeamQuestMediator:SendChooseRaidRewardCallback()
    
end
--[[
发送选择奖励通知
@params responseData table 服务器返回数据
--]]
function TeamQuestMediator:ChooseRaidRewardCallback(responseData)
    AppFacade.GetInstance():DispatchObservers('RAID_MEMBER_CHOOSE_REWARDS', responseData)
end
---------------------------------------------------
-- tcp logic handler end --
---------------------------------------------------

---------------------------------------------------
-- team to battle logic begin --
---------------------------------------------------
--[[
准备起战斗
@params stageId int 关卡id
@params randomConfig BattleRandomConfigStruct 战斗随机数配置数据结构
--]]
function TeamQuestMediator:ReadyEnterBattle(stageId, randomConfig)
    -- 创建战斗构造器
    local serverCommand = BattleNetworkCommandStruct.New(
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil,
        nil
    )

    local fromToStruct = BattleMediatorsConnectStruct.New(
        'TeamQuestReadyMediator',
        'TeamQuestReadyMediator'
    )

    -- local stageId = self.teamModel_.getTeamBossId()
    local teamData = self:ConvertCardsMapToTeamData(self.teamModel_:getCardModelMap())

    local battleConstructor = require('battleEntry.BattleConstructor').new()

    -- debug --
    randomConfig.randomseed = randomConfig.randomvalues[1]
    -- debug --

    battleConstructor:InitDataByThreeTwoRaid(
        stageId,
        randomConfig,
        teamData,
        serverCommand,
        fromToStruct
    )

    -- 设置玩家信息
    local playersData = {}
    local maxPlayerAmount = checkint(CommonUtils.GetQuestConf(stageId).attendNumber)
    for i = 1, maxPlayerAmount do
        local playerModel = self.teamModel_:getPlayerModel(i)
        if nil ~= playerModel and 0 ~= playerModel:getPlayerId() then
            local playerData = RaidMemberStruct.New(
                checkint(playerModel:getPlayerId()),
                tostring(playerModel:getName()),
                checkint(playerModel:getLevel()),
                0,
                tostring(playerModel:getAvatar()),
                tostring(playerModel:getAvatarFrame()),
                checkint(playerModel:getAttendTimes())
            )
            playersData[tostring(i)] = playerData
        end
    end
    battleConstructor:SetMemberData(playersData)

    -- 注册进入战斗管理器
    if not AppFacade.GetInstance():RetrieveMediator('EnterBattleMediator') then
        local enterBattleMediator = require('Game.mediator.EnterBattleMediator').new()
        AppFacade.GetInstance():RegistMediator(enterBattleMediator)
    end

    AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.Battle_Raid_Enter, battleConstructor)

    -- 重置状态
    self:SetInBattle(true)

    self:ChatPanelEnterBattle()
end
--[[
战斗加载结束
--]]
function TeamQuestMediator:BattleLoadingOver()
    -- 发送加载结束的长连接
    self:SendBattleLoadingOver()

    -- 恢复显示聊天部分
    self:ChatPanelBattleLoadingOver()
end
--[[
全员加载结束 开始战斗
--]]
function TeamQuestMediator:RaidBattleStartFight()
    AppFacade.GetInstance():DispatchObservers(EVENT_RAID_ALL_MEMBER_READY_START_FIGHT)
end
--[[
战斗胜利
@params data 战斗胜利参数集
--]]
function TeamQuestMediator:RaidBattleOver(data)
    -- 发送战斗结束的长连接
    dump(data)
    self:SendRaidBattleOverAndWaitTeammate(data)
    -- self:SendRaidBattleOver(data)
end
--[[
组队战斗全员结束开始请求结算
@params data 战斗参数集
--]]
function TeamQuestMediator:RaidBattleRequestForResult(data)
    self:SendRaidBattleOver(data)
end
--[[
接收到战斗胜利的长连接返回
@params responseData table 服务器返回数据
--]]
function TeamQuestMediator:RaidBattleResultCallback(responseData)
    -- 刷新一次自己的挑战次数
    local playerId = checkint(gameMgr:GetUserInfo().playerId)
    local leftChallengeTimes = checkint(responseData.leftAttendTimes)
    self:checkPlayerLeftChallengeTimesChange_(playerId, leftChallengeTimes)

    AppFacade.GetInstance():DispatchObservers(EVENT_RAID_BATTLE_RESULT, responseData)
end
--[[
玩家翻牌子结束
@params data table {
    playerId int 玩家id
}
--]]
function TeamQuestMediator:PlayerChooseReward(data)
    self.teamSocket_:sendData(NetCmd.TEAM_BOSS_CHOOSE_REWARD)
end
---------------------------------------------------
-- team to battle logic end --
---------------------------------------------------

---------------------------------------------------
-- chat logic begin --
---------------------------------------------------
--[[
加入组队聊天频道
--]]
function TeamQuestMediator:ConnectTeamChat()
    local chatSocketMgr = AppFacade.GetInstance():GetManager('ChatSocketManager')    
    if nil ~= chatSocketMgr then
        chatSocketMgr:JoinChatRoomByChannelAndRoomId(CHAT_CHANNELS.CHANNEL_TEAM, self:getTeamModel():getTeamId())
    end
end
--[[
断开组队聊天频道
--]]
function TeamQuestMediator:DisconnectTeamChat()
    local chatSocketMgr = AppFacade.GetInstance():GetManager('ChatSocketManager')    
    if nil ~= chatSocketMgr then
        chatSocketMgr:ExitChatRoomByChannelAndRoomId(CHAT_CHANNELS.CHANNEL_TEAM, self:getTeamModel():getTeamId())
    end
end
--[[
初始化聊天节点
--]]
function TeamQuestMediator:InitChatPanel()
    if (not isElexSdk() or isNewUSSdk())  and nil == self:GetChatPanel() then
        local parentNode = sceneWorld
        local raidChatLayer = require('Game.views.raid.RaidChatLayer').new()
        -- raidChatLayer:setBackgroundColor(cc.c4b(255, 0, 128, 200))
        display.commonUIParams(raidChatLayer, {ap = cc.p(0.5, 0.5), po = cc.p(
            display.cx,
            display.cy
        )})
        parentNode:addChild(raidChatLayer, GameSceneTag.Chat_GameSceneTag - 1)
        self:SetChatPanel(raidChatLayer)
    end
end
--[[
连接实时语音房间
--]]
function TeamQuestMediator:ConnectRealTimeVoiceChat()
    if nil ~= self:GetChatPanel() then
        -- 初始化世界聊天
        self:GetChatPanel():InitChatPanel()
        -- 连接实时语音
        self:GetChatPanel():ConnectRealTimeVoiceChat(self:GetFixedRealTimeVoiceChatRoomId())  
    end
end
--[[
断开实时语音房间
--]]
function TeamQuestMediator:DisconnectRealTimeVoiceChat()
    if nil ~= self:GetChatPanel() then        
        self:GetChatPanel():ExitRealTimeVoiceChat(self:GetFixedRealTimeVoiceChatRoomId())
    end
end
--[[
进入战斗开始加载 隐藏一些聊天节点
--]]
function TeamQuestMediator:ChatPanelEnterBattle()
    -- 隐藏聊天板
    if nil ~= self:GetChatPanel() then
        self:GetChatPanel():setVisible(false)
        self:GetChatPanel():DestroyAdditional()
    end
end
--[[
加载完毕 恢复一些聊天节点
--]]
function TeamQuestMediator:ChatPanelBattleLoadingOver()
    if nil ~= self:GetChatPanel() then
        self:GetChatPanel():setVisible(true)
    end
end
--[[
显示聊天板
@params data table {
    show bool 是否显示
}
--]]
function TeamQuestMediator:ShowChatPanel(data)
    local show = data.show ~= nil and data.show or false
    self:GetChatPanel():setVisible(show)
end
---------------------------------------------------
-- chat logic end --
---------------------------------------------------


-------------------------------------------------
-- get / set

function TeamQuestMediator:getTeamModel()
    return self.teamModel_
end
--[[
是否在战斗中
--]]
function TeamQuestMediator:IsInBattle()
    return self.isInBattle
end
function TeamQuestMediator:SetInBattle(b)
    self.isInBattle = b
end
--[[
是否需要延迟解散房间
--]]
function TeamQuestMediator:NeedDissolveTeam()
    return self.needDissolveTeam
end
function TeamQuestMediator:SetNeedDissolveTeam(b)
    self.needDissolveTeam = b
end
--[[
全局的聊天node
--]]
function TeamQuestMediator:SetChatPanel(chatPanel)
    self.chatPanel = chatPanel
end
function TeamQuestMediator:GetChatPanel()
    return self.chatPanel
end
--[[
设置组装后的实时语音房间id
--]]
function TeamQuestMediator:SetFixedRealTimeVoiceChatRoomId()
    if nil == self.realTimeVoiceChatRoomId then
        self.realTimeVoiceChatRoomId = crypto.md5(tostring(Platform.serverHost)) .. '_' .. self:getTeamModel():getTeamId()
    end
end
--[[
获取组装后的实时语音房间id
@return _ string 房间id
--]]
function TeamQuestMediator:GetFixedRealTimeVoiceChatRoomId()
    return self.realTimeVoiceChatRoomId
end

-------------------------------------------------
-- public method

function TeamQuestMediator:toExit()
    if self.currentTeamMdt_ then
        -- 断开组队聊天
        self:DisconnectTeamChat()
        -- 断开实时语音
        self:DisconnectRealTimeVoiceChat()
        -- 移除聊天板节点
        if nil ~= self:GetChatPanel() then
            self:GetChatPanel():DestroyAdditional()
            self:GetChatPanel():DestroySelf()
            self:SetChatPanel(nil)
        end

        -- 关闭长连接
        self.teamSocket_:disConnect(false)

        ------------ 检查是否在战斗中 如果是 走战中退出的逻辑 ------------
        if nil ~= self:GetFacade():RetrieveMediator(RaidBattleMdtName) then

            -- 强制退出战斗
            app:DispatchObservers('FORCE_EXIT_BATTLE')

            -- 注销自己
            self:GetFacade():UnRegsitMediator('TeamQuestMediator')

        else

            -- 跳转
            local routerMediator = self:GetFacade():RetrieveMediator('Router')
            routerMediator:Dispatch({name = 'TeamQuestMediator'}, {name = 'RaidHallMediator'})  -- TODO 暂时退回主界面，入口界面不能独立当做场景用
            
        end
        ------------ 检查是否在战斗中 如果是 走战中退出的逻辑 ------------
        
    else
        -- 移除聊天板节点
        if nil ~= self:GetChatPanel() then
            -- 断开组队聊天
            self:DisconnectTeamChat()
            -- 断开实时语音
            self:DisconnectRealTimeVoiceChat()
            
            self:GetChatPanel():DestroyAdditional()
            self:GetChatPanel():DestroySelf()
            self:SetChatPanel(nil)
        end

        ------------ 检查是否在战斗中 如果是 走战中退出的逻辑 ------------
        if nil ~= self:GetFacade():RetrieveMediator(RaidBattleMdtName) then

            -- 强制退出战斗
            app:DispatchObservers('FORCE_EXIT_BATTLE')
            
        end
        ------------ 检查是否在战斗中 如果是 走战中退出的逻辑 ------------

        self:GetFacade():UnRegsitMediator('TeamQuestMediator')
    end
end



function TeamQuestMediator:sendCaptainSkillChange(skillList)
    self.sendCaptainSkillChangeData_ = {
        playerSkills = table.concat(skillList or {}, ',')
    }
    self.teamSocket_:sendData(NetCmd.TEAM_BOSS_CSKILL_CHANGE, self.sendCaptainSkillChangeData_)
end


function TeamQuestMediator:sendKickMember(playerId)
    self.sendKickMemberData_ = {
        attendId = checkint(playerId)
    }
    self.teamSocket_:sendData(NetCmd.TEAM_BOSS_KICK_MEMBER, self.sendKickMemberData_)
end


function TeamQuestMediator:sendCaptainChange(playerId)
    self.sendCaptainChangeData_ = {
        captainId = checkint(playerId)
    }
    self.teamSocket_:sendData(NetCmd.TEAM_BOSS_CAPTAIN_CHANGE, self.sendCaptainChangeData_)
end


-------------------------------------------------
-- private method

function TeamQuestMediator:enterTeamReadyView_()
    if self.teamReadyMdt_ then return end
    local ReadyMediator  = require('Game.mediator.TeamQuestReadyMediator')
    self.teamReadyMdt_   = ReadyMediator.new({teamModel = self.teamModel_, teamQuestMdt = self})
    self.currentTeamMdt_ = self.teamReadyMdt_
    self:GetFacade():UnRegsitMediator('RaidHallMediator')
    self:GetFacade():RegistMediator(self.teamReadyMdt_)

    if ChatUtils.IsModuleAvailable() then
        -- 初始化一次语音房间id
        self:SetFixedRealTimeVoiceChatRoomId()
        -- 初始化聊天板
        self:InitChatPanel()
    end
end
function TeamQuestMediator:exitTeamReadyView_()
    if self.teamReadyMdt_ then
        self:GetFacade():UnRegsitMediator('TeamQuestReadyMediator')
        self.teamReadyMdt_   = nil
        self.currentTeamMdt_ = nil
    end
end
--[[
从战斗退回组队房间界面
--]]
function TeamQuestMediator:reenterTeamReadyView_()
    AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch(
        {name = RaidBattleMdtName},
        {name = 'TeamQuestReadyMediator', {params = {teamModel = self.teamModel_, teamQuestMdt = self}}}
    )
    -- 重置状态
    self:SetInBattle(false)

    -- 如果当前时间点房间失效了 弹打脸
    if self:NeedDissolveTeam() then
        self:TeamDissolve()
    end
end


function TeamQuestMediator:enterTeamBattleView_()
    -- TEAM_TODO
end
function TeamQuestMediator:exitTeamBattleView_()
    -- TEAM_TODO
end


function TeamQuestMediator:checkPlayerModelChange_(pos, playerData)
    local hasPlayer = self.teamModel_:hasPlayerModel(pos)

    -- check empty data
    if next(playerData or {}) == nil then
        if hasPlayer then
            self.teamModel_:releasePlayerModel(pos)
        end

    else
        local gameManagr   = self:GetFacade():GetManager('GameManager')
        local selfPlayerId = checkint(gameManagr:GetUserInfo().playerId)
        local playerModel  = nil

        if hasPlayer then
            playerModel = self.teamModel_:getPlayerModel(pos)

            -- check new player
            if playerModel:getPlayerId() ~= checkint(playerData.playerId) then
                self.teamModel_:releasePlayerModel(pos)
                playerModel = nil
            end
        end

        -- check new player
        local isNewPlayer = playerModel == nil
        if isNewPlayer then
            playerModel = ModelFactory.getModelType('TeamPlayer').new()
            playerModel:setPlayerId(checkint(playerData.playerId))
            playerModel:setName(checkstr(playerData.name))
            playerModel:setLevel(checkint(playerData.level))
            playerModel:setAvatar(checkstr(playerData.avatar))
            playerModel:setAvatarFrame(checkstr(playerData.avatarFrame))
            playerModel:setAttendTimes(checkint(playerData.leftAttendTimes))

            if selfPlayerId == playerModel:getPlayerId() then
                self.selfPos_ = pos
            end
        end

        -- update model
        playerModel:setStatus(checkint(playerData.status))  -- 1:未准备, 2:已准备, 3:离线

        if isNewPlayer then
            self.teamModel_:addPlayerModel(pos, playerModel)
        end
    end
end

--[[
变换本地记录的他人的卡牌数据
@params pos int 卡牌位置
@params cardData table 卡牌信息
--]]
function TeamQuestMediator:checkPlayerCardModelChange_(pos, cardData)
    local cardId = checkint(cardData.cardId)
    
    local playerId = nil
    if TeamCardModel.REMOVE_CARD_ID == cardId then
        local cardModel = self.teamModel_:getCardModel(pos)
        if nil ~= cardModel then
            playerId = checkint(cardModel:getPlayerId())
        end
    else
        playerId = checkint(cardData.playerId)
    end

    if nil ~= playerId then
        -- 如果该玩家已准备换卡将该玩家状态置为为准备
        local playerModel = self.teamModel_:getPlayerModel(self.teamModel_:getPlayerPosById(playerId))
        if nil ~= playerModel and TeamPlayerModel.STATUS_READY == playerModel:getStatus() then
            self:checkPlayerStatusChange_(playerId, TeamPlayerModel.READY_EVENT_CANCEL)
        end
    end

    if TeamCardModel.REMOVE_CARD_ID == cardId then
        -- 卸下一张卡
        local cardData = {cardId = TeamCardModel.REMOVE_CARD_ID}
        self:checkCardModelChange_(pos, cardData)
    else
        -- 判断此卡之前的位置
        local preCardModel = self.teamModel_:getCardModelByPlayerIdAndCardId(playerId, cardId)
        if nil ~= preCardModel then
            -- 从原来的位置卸下卡牌
            local preCardData = {cardId = TeamCardModel.REMOVE_CARD_ID}
            local preCardPos = preCardModel:getPlace()
            self:checkCardModelChange_(preCardPos, preCardData)
        end

        -- 装备一张新卡
        self:checkCardModelChange_(checkint(pos), cardData)
    end

    -- 广播消息 刷新一次连携技状态
    AppFacade.GetInstance():DispatchObservers('RAID_REFRESH_ALL_CONNECT_SKILL_STATE')
end
--[[
更换卡牌数据
@params pos int 卡牌位置
@params cardData table 卡牌数据
--]]
function TeamQuestMediator:checkCardModelChange_(pos, cardData)
    local cardModel = self.teamModel_:getCardModel(pos)

    if nil == cardModel then
        cardModel = TeamCardModel.new()
        self.teamModel_:addCardModel(pos, cardModel)
    end

    cardModel:updateCardInfo(pos, cardData)
end
--[[
玩家状态变更
@params playerId int 玩家id
@params ready TeamPlayerModel.READY_EVENT 准备状态
--]]
function TeamQuestMediator:checkPlayerStatusChange_(playerId, ready)
    local playerPos = self.teamModel_:getPlayerPosById(playerId)
    local playerModel = self.teamModel_:getPlayerModel(playerPos)

    if nil ~= playerModel and 0 ~= checkint(playerModel:getPlayerId()) then
        local status = ready == TeamPlayerModel.READY_EVENT_READY and TeamPlayerModel.STATUS_READY or TeamPlayerModel.STATUS_IDLE
        playerModel:setStatus(status)

        -- 广播一次事件
        AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.TEAM_BOSS_MODEL_PLAYER_STATUS_CHANGE, {playerId = checkint(playerId)})
    end
end
--[[
玩家剩余挑战次数变更
@params playerId int 玩家id
@params leftChallengeTimes 剩余挑战次数
--]]
function TeamQuestMediator:checkPlayerLeftChallengeTimesChange_(playerId, times)
    local playerPos = self.teamModel_:getPlayerPosById(playerId)
    local playerModel = self.teamModel_:getPlayerModel(playerPos)

    if nil ~= playerModel and 0 ~= checkint(playerModel:getPlayerId()) then
        playerModel:setAttendTimes(times)

        -- 广播一次事件
        AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.TEAM_BOSS_MODEL_PLAYER_ATTEND_CHANGE, {playerId = checkint(playerId)})
    end
end
--[[
玩家退出房间
@params playerId int 玩家id
@params teamId int 房间队伍id
--]]
function TeamQuestMediator:checkPlayerExitRoom_(playerId, teamId)
    if teamId == checkint(self.teamModel_:getTeamId()) then
        -- 容错 如果收到的长连接玩家退出不是本房间 不做处理
        local playerPos = self.teamModel_:getPlayerPosById(playerId)
        local playerModel = self.teamModel_:getPlayerModel(playerPos)
        if nil ~= playerModel and playerId == checkint(playerModel:getPlayerId()) then

            ------------ 移除该玩家已经上的卡牌 ------------
            local cardsPos = self.teamModel_:getCardsPosByPlayerId(playerId)
            for i, cardPos in ipairs(cardsPos) do
                self:checkCardModelChange_(checkint(cardPos), {cardId = TeamCardModel.REMOVE_CARD_ID})
            end
            ------------ 移除该玩家已经上的卡牌 ------------

            ------------ 移除该玩家数据 ------------
            self.teamModel_:removePlayerModel(playerPos)
            ------------ 移除该玩家数据 ------------
        end
    end
end


--[[
转换队伍配置信息
@params cardsMap map 队伍信息map
@return teamData list 队伍信息
--]]
function TeamQuestMediator:ConvertCardsMapToTeamData(cardsMap)
    local teamData = {}
    local cardModel = nil
    for i = 1, MAX_TEAM_MEMBER_AMOUNT do
        cardModel = cardsMap[tostring(i)]
        local cardData = nil
        if nil ~= cardModel and TeamCardModel.REMOVE_CARD_ID ~= checkint(cardModel:getCardId()) then
            -- 卡牌数据有效
            cardData = {
                cardId = cardModel:getCardId(),
                level = cardModel:getLevel(),
                breakLevel = cardModel:getBreakLevel(),
                favorabilityLevel = cardModel:getFavorLevel(),
                defaultSkinId = cardModel:getCardSkinId(),
                skill = cardModel:getCardSkill(),
                pets = cardModel:getPets(),
                artifactTalent = cardModel:getArtifactTalent()
            }
        else
            cardData = {}
        end
        table.insert(teamData, cardData)
    end
    return teamData
end
--[[
战后更新数据
@params data table 
--]]
function TeamQuestMediator:UpdateAllPlayerDataAfterBattle(data)

end
--[[
处理战斗结束后其他玩家的结算信息
@params data table 其他玩家的结算信息
--]]
function TeamQuestMediator:UpdateOtherPlayerDataAfterBattle(data)
    local playerId = checkint(data.playerId)
    local leftChallengeTimes = checkint(data.leftAttendTimes)
    -- 刷新剩余次数
    self:checkPlayerLeftChallengeTimesChange_(playerId, leftChallengeTimes)
    -- 将其他玩家的奖励发送给结算界面
    AppFacade.GetInstance():DispatchObservers(EVENT_RAID_MEMBER_GET_REWARDS, data)
end

-------------------------------------------------
-- handler method

function TeamQuestMediator:onToContentTeamSocket_(data)
    self.teamModel_:setTeamId(checkint(data.teamId))
    self.teamModel_:setPassword(checkstr(data.password))
    self.teamModel_:setTeamBossId(checkint(data.bossId))
    self.teamModel_:setQuestTypeId(checkint(data.typeId))
    self.teamModel_:setLeftBuyTimes(checkint(data.buyTimes))
    self.teamModel_:setBossRareReward(checktable(data.bossRareReward))

    -- connect socket
    self.teamSocket_:connect(data.ip, data.port)
end


function TeamQuestMediator:onContentedTeamSocket_()
    local selfCardsData = {}
    local selfCardsPos = self:getTeamModel():getCardsPosByPlayerId(checkint(gameMgr:GetUserInfo().playerId))
    for i, cardPos in ipairs(selfCardsPos) do
        local cardModel = self:getTeamModel():getCardModel(cardPos)
        selfCardsData[tostring(cardPos)] = checkint(cardModel:getPlayerCardId())
    end

    local sendData  = {
        questTeamId = self.teamModel_:getTeamId(), 
        password    = self.teamModel_:getPassword(),
        cards       = json.encode(selfCardsData)
    }
    self.teamSocket_:sendData(NetCmd.TEAM_BOSS_JOIN_TEAM, sendData)
end


function TeamQuestMediator:onTeamSocketUnexpected_(data)
    if self.isTerminal_ then return end

    local errText = tostring(data.errText)
    local errcode = checkint(data.errcode)

    if 0 > errcode then
        -- 错误代码小于0 强制退出队伍
        self.isTerminal_ = true
        self:GetFacade():GetManager('GameManager'):ShowGameAlertView({
            text = __('组队遇到了一点意外，原因：') .. errText,
            isOnlyOK = true,
            callback = function()
                if 0 < errcode then

                else
                    self:toExit()
                end
            end
        })
    elseif 0 < errcode then
        -- 错误代码大于0 继续操作
        uiMgr:ShowInformationTips(errText)
    end
end


function TeamQuestMediator:onEnterBattle()
    self:exitTeamReadyView_()
    self:enterTeamBattleView_()
end


function TeamQuestMediator:onExitTeamQuest_()
    self.isTerminal_ = true
    self:toExit()
end

--[[
任何人战斗结束
--]]
function TeamQuestMediator:SetAnyoneBattleOver(b)
    self.anyoneBattleOver = b
end
function TeamQuestMediator:GetAnyoneBattleOver()
    return self.anyoneBattleOver
end


return TeamQuestMediator
