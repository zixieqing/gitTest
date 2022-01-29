--[[
 * author : kaishiqi
 * descpt : 组队副本准备控制器
]]
local TeamQuestReadyMediator = class('TeamQuestReadyMediator', mvc.Mediator)

------------ import ------------
local gameMgr           = AppFacade.GetInstance():GetManager("GameManager")
local uiMgr             = AppFacade.GetInstance():GetManager("UIManager")
local cardMgr           = AppFacade.GetInstance():GetManager('CardManager')
local ModelFactory      = require('Game.models.TeamQuestModelFactory')
local TeamCardModel     = ModelFactory.getModelType('TeamCard')
local TeamPlayerModel   = ModelFactory.getModelType('TeamPlayer')
------------ import ------------

------------ define ------------
RaidPlayerState = {
    CANNOT_START        = 1,
    CAN_START           = 2,
    STARTED             = 3
}

-- 弹窗tag集合
local AdditionalViewTags = {
    chooseBattleHeroViewTag             = 6401,
    buyChallengeTimesViewTag            = 6402,
    stageDetailViewTag                  = 6403,
    playerCardDetailViewTag             = 6404,
    raidHintViewTag                     = 6100
}
------------ define ------------


function TeamQuestReadyMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'TeamQuestReadyMediator', viewComponent)

    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function TeamQuestReadyMediator:Initial(key)
    self.super.Initial(self, key)

    -- team quest mediator
    self.teamQuestMdt_ = self:GetFacade():RetrieveMediator('TeamQuestMediator')

    -- create view
    local uiManager  = self:GetFacade():GetManager('UIManager')
    self.readyScene_ = uiManager:SwitchToTargetScene('Game.views.TeamQuestReadyScene')
    self:SetViewComponent(self.readyScene_)

    -- init view
    local readyViewData = self:getReadyScene():getViewData()
    display.commonUIParams(readyViewData.backBtn, {cb = handler(self, self.onClickBackButtonHandler_)})

    self:RefreshScene(self:getTeamModel())
end


function TeamQuestReadyMediator:CleanupView()

    -- 清除一些弹窗
    local parentNode = uiMgr:GetCurrentScene()
    for k,v in pairs(AdditionalViewTags) do
        if nil ~= parentNode:GetDialogByTag(v) then
            parentNode:RemoveDialogByTag(v)
        end
    end

    -- 清除玩家头像弹窗
    parentNode:RemoveDialogByName('common.PlayerHeadPopup')

end


function TeamQuestReadyMediator:OnRegist()
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
end
function TeamQuestReadyMediator:OnUnRegist()
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightShow")
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
end


function TeamQuestReadyMediator:InterestSignals()
    return {
        SIGNALNAMES.TEAM_BOSS_MODEL_BOSS_CHANGE,
        SIGNALNAMES.TEAM_BOSS_MODEL_PASSWORD_CHANGE,
        SIGNALNAMES.TEAM_BOSS_MODEL_CAPTAIN_CHANGE,
        SIGNALNAMES.TEAM_BOSS_MODEL_CAPTAIN_SKILL_CHANGE,
        SIGNALNAMES.TEAM_BOSS_MODEL_PLAYER_ADD_CHANGE,
        SIGNALNAMES.TEAM_BOSS_MODEL_PLAYER_REMOVE_CHANGE,
        SIGNALNAMES.TEAM_BOSS_MODEL_PLAYER_RELEASE_CHANGE,
        SIGNALNAMES.TEAM_BOSS_MODEL_PLAYER_STATUS_CHANGE,
        SIGNALNAMES.TEAM_BOSS_MODEL_PLAYER_ATTEND_CHANGE,
        SIGNALNAMES.TEAM_BOSS_MODEL_PLAYER_CARD_CHANGE,
        ------------ local ------------
        'RAID_SHOW_CHOOSE_CARD_VIEW',
        'RAID_REFRESH_ALL_CONNECT_SKILL_STATE',
        'RAID_BATTLE_READY',
        'RAID_SHOW_CHANGE_PASSWORD',
        'RAID_SHOW_BUY_CHALLENGE_TIMES',
        'RAID_SHOW_STAGE_DETAIL',
        'RAID_SHOW_FRIEND_REMIND_BOARD',
        'RAID_SHOW_PLAYER_CARD_DETAIL'
    }
end
function TeamQuestReadyMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    ------------ server ------------
    if false then
    ------------ lcoal  ------------
    elseif SIGNALNAMES.TEAM_BOSS_MODEL_BOSS_CHANGE == name then

        -- 有卡牌更换
        self:ChangeStageCallback(data)

    elseif SIGNALNAMES.TEAM_BOSS_MODEL_PLAYER_CARD_CHANGE == name then

        -- 有卡牌更换
        self:ChangeCardCallback(data)

    elseif SIGNALNAMES.TEAM_BOSS_MODEL_PLAYER_ADD_CHANGE == name then

        -- 有玩家加入游戏
        self:ChangePlayerCallback(data)

    elseif SIGNALNAMES.TEAM_BOSS_MODEL_PLAYER_STATUS_CHANGE == name then

        -- 有玩家变更准备状态
        self:PlayerChangeStatusCallback(data)

    elseif SIGNALNAMES.TEAM_BOSS_MODEL_PLAYER_ATTEND_CHANGE == name then

        -- 有玩家剩余次数变化
        self:PlayerChangeLeftChallengeTimsCallback(data)

    elseif SIGNALNAMES.TEAM_BOSS_MODEL_PLAYER_REMOVE_CHANGE == name then

        -- 有玩家退出房间
        self:PlayerExitRoomCallback(data)

    elseif SIGNALNAMES.TEAM_BOSS_MODEL_PASSWORD_CHANGE == name then

        -- 变更了密码
        self:ChangePasswordCallback(data)

    elseif 'RAID_SHOW_CHOOSE_CARD_VIEW' == name then

        -- 点击更换卡牌回调
        self:ShowChooseCardView(data)

    elseif 'RAID_REFRESH_ALL_CONNECT_SKILL_STATE' == name then

        -- 刷新一次所有连携技按钮
        self:RefreshAllConnectSkillState()

    elseif 'RAID_BATTLE_READY' == name then

        -- 开始战斗信号
        self:RaidBattleReady()

    elseif 'RAID_SHOW_CHANGE_PASSWORD' == name then

        -- 显示输入密码界面
        self:ShowChangePasswordView()

    elseif 'RAID_SHOW_BUY_CHALLENGE_TIMES' == name then

        -- 显示购买剩余次数
        self:ShowBuyChallengeTimes()

    elseif 'RAID_SHOW_STAGE_DETAIL' == name then

        -- 显示关卡详情界面
        self:ShowStageDetail()

    elseif 'RAID_SHOW_FRIEND_REMIND_BOARD' == name then

        -- 显示好友提示
        self:ShowFriendRemindBoard()

    elseif 'RAID_SHOW_PLAYER_CARD_DETAIL' == name then

        -- 显示玩家卡牌详情
        self:ShowPlayerCardDetail(data)

    end
end


-------------------------------------------------
-- public method

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
刷新一次界面信息
@params teamModel TeamQuestModel 组队数据模型
--]]
function TeamQuestReadyMediator:RefreshScene(teamModel)
    local selfPlayerId          = self:getSelfPlayerId()
    local selfPlayerPos         = teamModel:getPlayerPosById(selfPlayerId)
    local selfPlayerModel       = teamModel:getPlayerModel(selfPlayerPos)
    local stageId               = teamModel:getTeamBossId()
    local stageConfig           = checktable(CommonUtils.GetQuestConf(stageId))
    local maxPlayerAmount       = checkint(stageConfig.attendNumber)
    local maxCardAmount         = checkint(stageConfig.attendCardNumber)

    local data = {
        teamId          = teamModel:getTeamId(),
        password        = teamModel:getPassword(),
        stageId         = teamModel:getTeamBossId(),
        leftChallengeTimes = selfPlayerModel:getAttendTimes(),
        maxCardAmount   = self:getMaxCardAmountByPlayerPos(stageId, selfPlayerPos),
        showCaptainMark = self:isCaptainByPlayerId(selfPlayerId),
        maxPlayerAmount = maxPlayerAmount,
        playerCardsAmountConfig = stageConfig.attendPosition
    }

    self:getReadyScene():RefreshUI(data)

    -- 刷新一次所有玩家信息
    for playerPos = 1, maxPlayerAmount do
        self:RefreshPlayerByPos(playerPos)
    end

    -- 刷新一次所有玩家卡牌信息
    for cardPos = 1, maxCardAmount do
        self:RefreshCardByPos(cardPos)
    end

    -- 刷新一次战斗按钮样式
    self:RefreshBattleButtonState()
end
--[[
根据玩家位置和刷新玩家信息
@params pos int 玩家位置
--]]
function TeamQuestReadyMediator:RefreshPlayerByPos(pos)
    local stageId               = self:getTeamModel():getTeamBossId()
    local stageConfig           = CommonUtils.GetQuestConf(stageId)
    local maxPlayerAmount       = checkint(stageConfig.attendNumber)
    local playerModel           = self:getTeamModel():getPlayerModel(pos)
    local isCaptain             = nil ~= playerModel and self:isCaptainByPlayerId(playerModel:getPlayerId()) or false

    self:getReadyScene():RefreshTeamMember(pos, playerModel, isCaptain)

    if nil ~= playerModel and 0 ~= playerModel:getPlayerId() then
        -- 刷新限制标识
        self:getReadyScene():ShowPlayerLevelLimit(pos, not self:CheckPlayerCanEnterStageByPos(stageId, pos))
        self:getReadyScene():ShowPlayerChallengeTimeLimit(pos, not self:CheckPlayerChallengeTimeByPos(stageId, pos))
    end
end
--[[
根据卡牌位置刷新卡牌信息
@params pos int 卡牌位置
--]]
function TeamQuestReadyMediator:RefreshCardByPos(pos)
    local cardModel = self:getTeamModel():getCardModel(pos)
    local selfPlayerId = self:getSelfPlayerId()

    if nil == cardModel then return end

    if nil == cardModel or TeamCardModel.REMOVE_CARD_ID == cardModel:getCardId() then
        -- 下卡
        self:getReadyScene():UnequipACard(cardModel)
    else
        -- 上卡
        self:getReadyScene():EquipACard(cardModel)
    end
    local playerPos = self:getTeamModel():getPlayerPosById(cardModel:getPlayerId())
    -- 计算修正后的卡牌槽位序号
    local addCardIndex = self:getAddCardIndex(self:getTeamModel():getTeamBossId(), playerPos, cardModel:getPlace())

    -- 刷新一次队员详情中的卡牌信息
    self:getReadyScene():RefreshTeamMemberCard(playerPos, addCardIndex, cardModel)

    -- 如果是自己的卡 需要刷新一次当前装备的卡牌槽位
    if selfPlayerId == cardModel:getPlayerId() then
        self:getReadyScene():RefreshAddCardHeadNode(addCardIndex, cardModel)
    end
end
--[[
刷新一次本玩家的战斗按钮状态
--]]
function TeamQuestReadyMediator:RefreshBattleButtonState()
    local selfPlayerId = self:getSelfPlayerId()
    local selfPlayerPos = self:getTeamModel():getPlayerPosById(selfPlayerId)
    local selfPlayerModel = self:getTeamModel():getPlayerModel(selfPlayerPos)
    local isCaptain = self:isCaptainByPlayerId(selfPlayerId)

    if isCaptain then

        -- 房主可以开始的情况只有一种 满足开战条件
        local canStart = self:CanStartBattle()
        local state = canStart and RaidPlayerState.CAN_START or RaidPlayerState.CANNOT_START
        self:getReadyScene():SetBattleButtonState(isCaptain, state)

    else
        if TeamPlayerModel.STATUS_IDLE == selfPlayerModel:getStatus() then

            -- 未准备状态 判断是否可以准备
            local canReady = self:CanReadyByPlayerPos(selfPlayerPos)
            local state = canReady and RaidPlayerState.CAN_START or RaidPlayerState.CANNOT_START
            self:getReadyScene():SetBattleButtonState(isCaptain, state)

        elseif TeamPlayerModel.STATUS_READY == selfPlayerModel:getStatus() then

            -- 准备状态
            self:getReadyScene():SetBattleButtonState(isCaptain, RaidPlayerState.STARTED)

        end
    end
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- logic control begin --
---------------------------------------------------

---------------------------------------------------
-- logic control end --
---------------------------------------------------
--[[
根据玩家位置判断是否满足准备的条件
@params pos int 玩家位置
@return result bool 是否可以准备
--]]
function TeamQuestReadyMediator:CanReadyByPlayerPos(pos)    
    local stageId = self:getTeamModel():getTeamBossId()

    ------------ 判断剩余挑战次数 ------------
    if not self:CheckPlayerChallengeTimeByPos(stageId, pos) then
        -- 现在次数不足仍然能进入战斗
        -- return false
    end
    ------------ 判断剩余挑战次数 ------------

    ------------ 判断是否可以进入关卡 ------------
    if not self:CheckPlayerCanEnterStageByPos(stageId, pos) then
        return false
    end
    ------------ 判断是否可以进入关卡 ------------

    ------------ 判断是否满足上卡需求 ------------
    -- 关卡信息
    local maxCardAmount = self:getMaxCardAmountByPlayerPos(stageId, pos)

    local playerModel = self:getTeamModel():getPlayerModel(pos)
    local playerId = playerModel:getPlayerId()
    local playerCardsPos = self:getTeamModel():getCardsPosByPlayerId(playerId)

    if maxCardAmount > #playerCardsPos then
        return false
    end
    ------------ 判断是否满足上卡需求 ------------

    return true
end
--[[
根据玩家位置判断玩家的剩余挑战次数是否可以进行战斗
@params stageId int 关卡id
@params playerPos int 玩家位置
@return _ bool 是否可以进入战斗
--]]
function TeamQuestReadyMediator:CheckPlayerChallengeTimeByPos(stageId, playerPos)
    local playerModel = self:getTeamModel():getPlayerModel(playerPos)
    -- return 0 < checkint(playerModel:getAttendTimes())
    return true
end
--[[
根据玩家位置判断玩家是否满足进入关卡的条件
@params stageId int 关卡id
@params playerPos int 玩家位置
@return _ bool 是否满足关卡条件
--]]
function TeamQuestReadyMediator:CheckPlayerCanEnterStageByPos(stageId, playerPos)
    local stageConfig = CommonUtils.GetQuestConf(stageId)
    local playerModel = self:getTeamModel():getPlayerModel(playerPos)
    return checkint(stageConfig.unlockLevel) <= checkint(playerModel:getLevel())
end
--[[
是否可以开始战斗
@params _ bool 是否可以开始战斗
--]]
function TeamQuestReadyMediator:CanStartBattle()
    local captainId = self:getTeamModel():getCaptainId()
    local stageId = self:getTeamModel():getTeamBossId()

    local playerAmount = 0

    for pos, playerModel in pairs(self:getTeamModel():getPlayerModelMap()) do
        local playerId = checkint(playerModel:getPlayerId())
        if 0 ~= playerId then

            playerAmount = playerAmount + 1

            if captainId == playerId then
                local result = self:CanReadyByPlayerPos(checkint(pos))
                if not result then
                    return false
                end
            else
                if TeamPlayerModel.STATUS_READY ~= playerModel:getStatus() then
                    return false
                end
            end
        end
    end

    -- 检查人数
    local stageConfig = CommonUtils.GetQuestConf(stageId)
    if nil ~= stageConfig then
        if playerAmount < checkint(stageConfig.leastAttendNumber) then
            return false
        end
    end

    return true
end


-------------------------------------------------
-- private method

--[[
更换卡牌按钮事件
@params data table {
    index int 卡牌序号
}
--]]
function TeamQuestReadyMediator:ShowChooseCardView(data)
    local index = checkint(data.index)
    local selfPlayerId = self:getSelfPlayerId()
    local selfPlayerPos = self:getTeamModel():getPlayerPosById(selfPlayerId)
    local cardPos = self:getFixedCardPosInTeam(self:getTeamModel():getTeamBossId(), selfPlayerPos, index)
    local curCardModel = self:getTeamModel():getCardModel(cardPos)
    local curId = nil
    if nil ~= curCardModel and not curCardModel:isCardEmpty() then
        curId = curCardModel:getPlayerCardId()
    end

    -- 显示选择卡牌列表
    local chooseBattleHeroView  = require('Game.views.ChooseCardsHouseView').new({
        id = curId,
        clickHeroTag = cardPos,
        callback = function (data)
            local playerId = self:getSelfPlayerId()
            local playerPos = self:getTeamModel():getPlayerPosById(playerId)
            local cardPos = self:getFixedCardPosInTeam(self:getTeamModel():getTeamBossId(), playerPos, index)
            local playerCardId = checkint(data.id)

            -- 根据卡牌id判断一次这张卡有没有在场
            local cardData = clone(gameMgr:GetCardDataById(playerCardId))
            if nil ~= cardData and 0 ~= checkint(cardData.cardId) then
                local cardId = checkint(cardData.cardId)
                if not self:getTeamModel():canAddCardByCardIdAndPlayerId(cardId, playerId) then
                    -- 此卡已上阵
                    local cardConfig = CardUtils.GetCardConfig(cardId)
                    uiMgr:ShowInformationTips(string.format(__('%s已上阵!!!'), tostring(cardConfig.name)))
                    return
                end
            end

            local data = {
                playerCardId = playerCardId,
                position = cardPos
            }

            AppFacade.GetInstance():DispatchObservers('RAID_CHANGE_CARD', data)

        end
    })
    chooseBattleHeroView:setTag(AdditionalViewTags.chooseBattleHeroViewTag)
    chooseBattleHeroView:setPosition(display.center)
    uiMgr:GetCurrentScene():AddDialog(chooseBattleHeroView)

    -- 绑定关闭回调
    chooseBattleHeroView.eaterLayer:setOnClickScriptHandler(function (sender)
        if uiMgr:GetCurrentScene():GetDialogByTag(AdditionalViewTags.chooseBattleHeroViewTag) then
            uiMgr:GetCurrentScene():RemoveDialogByTag(AdditionalViewTags.chooseBattleHeroViewTag)
        end
    end)

end
--[[
更换卡牌广播事件回调
@params data table {
    pos 更换的卡牌位置
}
--]]
function TeamQuestReadyMediator:ChangeCardCallback(data)
    local pos = data.pos

    -- 刷新一次准备状态
    self:RefreshBattleButtonState()

    ------------ view ------------
    self:RefreshCardByPos(pos)
    ------------ view ------------
end
--[[
刷新连携技事件
--]]
function TeamQuestReadyMediator:RefreshAllConnectSkillState()
    local tmpTeamData = {}
    for pos, cardModel in pairs(self:getTeamModel():getCardModelMap()) do
        if not cardModel:isCardEmpty() then
            local tmpCardData = {cardId = cardModel:getCardId()}
            table.insert(tmpTeamData, tmpCardData)
        end
    end

    for pos, cardModel in pairs(self:getTeamModel():getCardModelMap()) do
        if not cardModel:isCardEmpty() then
            local cardId = cardModel:getCardId()
            local skillEnable = CardUtils.IsConnectSkillEnable(cardId, tmpTeamData)
            self:getReadyScene():RefreshConnectSkillNodeState(cardModel:getPlace(), skillEnable)
        end
    end
end
--[[
有玩家变动
@params data table {
    pos int 变动的玩家位置
}
--]]
function TeamQuestReadyMediator:ChangePlayerCallback(data)
    local pos = checkint(data.pos)

    -- 刷新该玩家位
    self:RefreshPlayerByPos(pos)

    -- 如果本玩家是房主 检查一次开始状态
    if self:isCaptainByPlayerId(self:getSelfPlayerId()) then
        self:RefreshBattleButtonState()
    end
end
--[[
战斗准备
--]]
function TeamQuestReadyMediator:RaidBattleReady()
    local selfPlayerId = self:getSelfPlayerId()
    local isCaptain = self:isCaptainByPlayerId(selfPlayerId)

    if isCaptain then
        -- 如果是队长 判断一次是否可以开始战斗
        local canStart = self:CanStartBattle()
        if canStart then
            ------------ here start raid battle ------------
            AppFacade.GetInstance():DispatchObservers('START_RAID_BATTLE')
            ------------ here start raid battle ------------
        else
            uiMgr:ShowInformationTips(__('无法开始战斗!!!'))
            self:RefreshBattleButtonState()
            return
        end
    else
        -- 如果不是队长 判断一次状态
        local selfPlayerPos = self:getTeamModel():getPlayerPosById(selfPlayerId)
        local selfPlayerModel = self:getTeamModel():getPlayerModel(selfPlayerPos)

        if nil ~= selfPlayerModel and 0 ~= selfPlayerModel:getPlayerId() then

            local playerStatus = selfPlayerModel:getStatus()

            if TeamPlayerModel.STATUS_IDLE == playerStatus then
                -- 准备
                if self:CanReadyByPlayerPos(selfPlayerPos) then
                    print('\n\n\n >>>>>>>>>>>>>>>>>>>>>>> here should ready <<<<<<<<<<<<<<<<<<\n\n\n')
                    local data = {
                        ready = TeamPlayerModel.READY_EVENT_READY
                    }
                    AppFacade.GetInstance():DispatchObservers('RAID_PLAYER_CHANGE_STATUS', data)

                else
                    uiMgr:ShowInformationTips(__('未满足准备条件!!!'))
                    return
                end
            elseif TeamPlayerModel.STATUS_READY == playerStatus then
                -- 取消准备
                print('\n\n\n >>>>>>>>>>>>>>>>>>>>>>> here should cancel ready <<<<<<<<<<<<<<<<<<\n\n\n')

                if TeamPlayerModel.STATUS_READY == selfPlayerModel:getStatus() then

                    local data = {
                        ready = TeamPlayerModel.READY_EVENT_CANCEL
                    }
                    AppFacade.GetInstance():DispatchObservers('RAID_PLAYER_CHANGE_STATUS', data)

                else
                    print('here find data error when player cancel ready, status in playerModel is already idle')
                end
            end

        else
            uiMgr:ShowInformationTips(__('数据出错!!!'))
            return
        end
    end
end
--[[
玩家准备状态回调
@params data table {
    playerId int 玩家id
}
--]]
function TeamQuestReadyMediator:PlayerChangeStatusCallback(data)
    local playerId = checkint(data.playerId)
    local selfPlayerId = self:getSelfPlayerId()
    local playerPos = self:getTeamModel():getPlayerPosById(playerId)
    local playerModel = self:getTeamModel():getPlayerModel(playerPos)

    if nil ~= playerModel then
        -- 刷新玩家准备状态
        self:getReadyScene():RefreshTeamMemberReadyState(playerPos, playerModel)

        if selfPlayerId == playerId or self:isCaptainByPlayerId(selfPlayerId) then
            -- 如果是自己或者房主 刷新一次战斗按钮的状态
            self:RefreshBattleButtonState()
        end
    end

end
--[[
玩家剩余次数回调
@params data table {
    playerId int 玩家id
}
--]]
function TeamQuestReadyMediator:PlayerChangeLeftChallengeTimsCallback(data)
    local playerId = checkint(data.playerId)
    local selfPlayerId = self:getSelfPlayerId()

    local playerPos = self:getTeamModel():getPlayerPosById(playerId)
    local playerModel = self:getTeamModel():getPlayerModel(playerPos)
    local stageId = checkint(self:getTeamModel():getTeamBossId())

    -- 刷新一次准备状态
    self:RefreshBattleButtonState()

    -- 刷新挑战次数限制
    self:getReadyScene():ShowPlayerChallengeTimeLimit(playerPos, not self:CheckPlayerChallengeTimeByPos(stageId, playerPos))

    -- 如果该玩家是自己 刷新一些界面信息
    if selfPlayerId == playerId then
        local leftChallengeTimes = checkint(playerModel:getAttendTimes())
        -- 刷新挑战次数
        self:getReadyScene():RefreshLeftTimes(leftChallengeTimes)
        local stageDetailView = uiMgr:GetCurrentScene():GetDialogByTag(AdditionalViewTags.stageDetailViewTag)
        if stageDetailView and stageDetailView.RefreshLeftChallengeTimes then
            stageDetailView:RefreshLeftChallengeTimes(leftChallengeTimes)
        end

        -- 刷新一些全局界面
        AppFacade.GetInstance():DispatchObservers('RAID_REFRESH_LEFT_CHALLENGE_TIMES', {
            currentTimes = leftChallengeTimes
        })
    end
end
--[[
玩家退出房间
@params data table {
    pos 玩家位置
}
--]]
function TeamQuestReadyMediator:PlayerExitRoomCallback(data)
    local pos = checkint(data.pos)

    -- 刷新玩家状态
    self:RefreshPlayerByPos(pos)
    -- 刷新一次战斗按钮样式
    self:RefreshBattleButtonState()
end
--[[
显示输入密码界面
--]]
function TeamQuestReadyMediator:ShowChangePasswordView()
    -- 只有房主才能更改密码
    if self:isCaptainByPlayerId(self:getSelfPlayerId()) then
        uiMgr:ShowNumberKeyBoard({
            nums = 6,
            model = 2,
            callback = function (str)
                ------------ 请求修改密码 ------------
                AppFacade.GetInstance():DispatchObservers('RAID_CHANGE_TEAM_PASSWORD', {password = str})
                ------------ 请求修改密码 ------------
            end,
            titleText = __('请输入六位数字密码'),
            defaultContent = self:getTeamModel():getPassword()
        })
    end
end
--[[
变更了密码
@params data table {
    password string 密码
}
--]]
function TeamQuestReadyMediator:ChangePasswordCallback(data)
    ------------ view ------------
    -- 刷新密码
    self:getReadyScene():RefreshPasswordIcon(data.password)
    ------------ view ------------
end
--[[
显示购买剩余次数
--]]
function TeamQuestReadyMediator:ShowBuyChallengeTimes()
    local teamTypeConfig = CommonUtils.GetConfig('quest', 'teamType', self:getTeamModel():getQuestTypeId())
    local costInfo = {
        goodsId = DIAMOND_ID,
        num = checkint(teamTypeConfig.buyTimesPrice)
    }
    local challengeTimes = checkint(CommonUtils.getVipTotalLimitByField('questTeamBuyNum'))

    local leftBuyTimes = checkint(self:getTeamModel():getLeftBuyTimes())

    local textRich = {
        {text = __('确定要追加')},
        {text = tostring(challengeTimes), fontSize = 26, color = '#ff0000'},
        {text = __('次挑战次数吗?')}
    }
    local descrRich = {
        {text = __('当前还可以购买')},
        {text = tostring(leftBuyTimes), fontSize = fontWithColor('15').fontSize, color = '#ff0000'},
        {text = __('次\n挑战次数每日00:00重置')},
    }
    -- 显示购买弹窗
    local layer = require('common.CommonTip').new({
        textRich = textRich,
        descrRich = descrRich,
        defaultRichPattern = true,
        costInfo = costInfo,
        callback = function (sender)
            -- 可行性判断
            if 0 >= leftBuyTimes then
                uiMgr:ShowInformationTips(__('剩余购买次数已用完!!!'))
                return
            end

            local goodsAmount = gameMgr:GetAmountByIdForce(costInfo.goodsId)
            if costInfo.num > goodsAmount then
                if GAME_MODULE_OPEN.NEW_STORE and checkint(costInfo.goodsId) == DIAMOND_ID then
					app.uiMgr:showDiamonTips()
				else
                    local goodsConfig = CommonUtils.GetConfig('goods', 'goods', costInfo.goodsId)
                    uiMgr:ShowInformationTips(string.format(__('%s不足!!!'), goodsConfig.name))
                end
                return
            end

            AppFacade.GetInstance():DispatchObservers('RAID_TEAM_BUY_CHALLENGE_TIMES')
        end
    })
    layer:setTag(AdditionalViewTags.buyChallengeTimesViewTag)

    layer:setPosition(display.center)
    uiMgr:GetCurrentScene():AddDialog(layer)
end
--[[
显示关卡详情界面
--]]
function TeamQuestReadyMediator:ShowStageDetail()
    local stageId = self:getTeamModel():getTeamBossId()
    local selfPlayerModel = self:getTeamModel():getPlayerModel(self:getTeamModel():getPlayerPosById(self:getSelfPlayerId()))
    local leftChallengeTimes = checkint(selfPlayerModel:getAttendTimes())

    -- 房主更改boss 队员查看boss
    if self:isCaptainByPlayerId(self:getSelfPlayerId()) then
        -- 更改boss
        local raidQuestType = self:getTeamModel():getQuestTypeId()
        local view = require('Game.views.raid.RaidHallScene').new({
            raidQuestType = raidQuestType,
            pattern = 2
        })
        view:setTag(AdditionalViewTags.stageDetailViewTag)
        display.commonUIParams(view, {ap = cc.p(0.5, 0.5), po = utils.getLocalCenter(self:GetViewComponent())})
        uiMgr:GetCurrentScene():AddDialog(view)

        view:RefreshUIByRaidQuestType(
            raidQuestType,
            checkint(gameMgr:GetUserInfo().level),
            self:getTeamModel():getBossRareReward()
        )
        view:JumpByStageId(stageId)
        view:RefreshDefaultPassword(self:getTeamModel():getPassword())
        view:RefreshLeftChallengeTimes(leftChallengeTimes)
    else
        -- 查看boss
        local view = require('Game.views.raid.RaidRoomStageDetailScene').new({
            stageId = stageId,
            leftChallengeTimes = leftChallengeTimes,
            bossRareReward = self:getTeamModel():getBossRareReward()
        })
        view:setTag(AdditionalViewTags.stageDetailViewTag)
        display.commonUIParams(view, {ap = cc.p(0.5, 0.5), po = utils.getLocalCenter(self:GetViewComponent())})
        uiMgr:GetCurrentScene():AddDialog(view)
    end
end
--[[
变更boss回调
@params data table {
    stageId int 关卡id
}
--]]
function TeamQuestReadyMediator:ChangeStageCallback(data)
    local stageId               = checkint(data.stageId)
    local stageConfig           = checktable(CommonUtils.GetQuestConf(stageId))
    local maxPlayerAmount       = checkint(stageConfig.attendNumber)
    ------------ view ------------
    -- 刷新房间信息
    self:getReadyScene():RefreshStageInfoByStageId(stageId)
    -- 刷新一次所有玩家的进入关卡限制
    for playerPos = 1, maxPlayerAmount do
        local playerModel = self:getTeamModel():getPlayerModel(playerPos)
        if nil ~= playerModel and 0 ~= playerModel:getPlayerId() then 
            self:getReadyScene():ShowPlayerLevelLimit(playerPos, not self:CheckPlayerCanEnterStageByPos(stageId, playerPos))
        end
    end
    ------------ view ------------
end
--[[
显示好友提示
--]]
function TeamQuestReadyMediator:ShowFriendRemindBoard()
    local isFriend = false
    for k,v in pairs(self:getTeamModel():getPlayerModelMap()) do
        local playerId = checkint(v:getPlayerId())
        if 0 ~= playerId and self:getSelfPlayerId() ~= playerId then
            if CommonUtils.GetIsFriendById(playerId) then
                isFriend = true
                break
            end
        end
    end

    local descr = ''
    if isFriend then
        descr = __('与好友一起协力作战可增加亲密度。每次+1')
    else
        descr = __('你和房间内玩家还不是好友。好友每次协力作战可增加亲密度。')
    end

    uiMgr:ShowInformationTipsBoard({
        targetNode = self:getReadyScene():getViewData().friendIcon,
        descr = descr,
        type = 5
    })
end
--[[
显示玩家卡牌详情
@params data table {
    cardPos int 卡牌位置
}
--]]
function TeamQuestReadyMediator:ShowPlayerCardDetail(data)
    local cardPos = data.cardPos
    print('here check fuck cardpos <<<<<<<<<<<<<<<<<<', cardPos)
    local cardModel = self:getTeamModel():getCardModel(cardPos)
    if nil == cardModel or TeamCardModel.REMOVE_CARD_ID == checkint(cardModel:getCardId()) then
        -- 没有卡 如果是自己显示上卡界面
    else
        -- 有卡 显示卡牌详情界面
        local cardData = {
            cardId = checkint(cardModel:getCardId()),
            level = checkint(cardModel:getLevel()),
            breakLevel = checkint(cardModel:getBreakLevel()),
            favorLevel = checkint(cardModel:getFavorLevel()),
            skinId = checkint(cardModel:getCardSkinId()),
            nickname = cardModel:getCardNickname(),
            artifactTalent =  cardModel:getArtifactTalent(),
            bookLevel = cardModel:getBookLevel(),
            equippedHouseCatGene = cardModel:getEquippedHouseCatGene(),
        }

        local petsData = cardModel:getPets()

        local playerId = checkint(cardModel:getPlayerId())
        local playerModel = self:getTeamModel():getPlayerModel(self:getTeamModel():getPlayerPosById(playerId))

        local playerData = {
            playerId = playerId,
            playerName = playerModel and playerModel:getName() or '----',
            playerLevel = playerModel and playerModel:getLevel() or 0,
            playerAvatar = playerModel and playerModel:getAvatar() or 0,
            playerAvatarFrame = playerModel and playerModel:getAvatarFrame() or 0,
        }

        local playerCardDetailView = require('Game.views.raid.PlayerCardDetailView').new({
            cardData = cardData,
            petsData = petsData,
            playerData = playerData
        })
        playerCardDetailView:setTag(AdditionalViewTags.playerCardDetailViewTag)
        display.commonUIParams(playerCardDetailView, {ap = cc.p(0.5, 0.5), po = cc.p(
            display.cx, display.cy
        )})
        uiMgr:GetCurrentScene():AddDialog(playerCardDetailView)
    end
end


-------------------------------------------------
-- handler method

function TeamQuestReadyMediator:onClickBackButtonHandler_(sender)
    local tipText = __('确定要退出当前队伍吗？')
    local tipView = require('common.NewCommonTip').new({text = tipText, callback = function ()
        -- 发送退出的通知
        AppFacade.GetInstance():DispatchObservers('RAID_EXIT_TEAM')
    end})
    tipView:setPosition(display.center)
    self:GetViewComponent():AddDialog(tipView)
end


-------------------------------------------------
-- get / set

function TeamQuestReadyMediator:getTeamModel()
    return self.teamQuestMdt_:getTeamModel()
end


function TeamQuestReadyMediator:getReadyScene()
    return self.readyScene_
end

--[[
获取可以上阵的最大卡牌数量
@params stageId int 关卡id
@params playerPos int 玩家所在位置
@return _ int 可以上阵的最大卡牌数量
--]]
function TeamQuestReadyMediator:getMaxCardAmountByPlayerPos(stageId, playerPos)
    local stageConfig = CommonUtils.GetQuestConf(stageId)
    if nil ~= stageConfig then
        return checkint(stageConfig.attendPosition[playerPos])
    else
        return 0
    end
end
--[[
根据自己的槽位序号获取修正后对应队伍里卡牌的位置
@params stageId int 关卡id
@params playerPos int 玩家位置
@params index int 槽位序号
@return fixedPos int 修正后的队伍卡牌位置
--]]
function TeamQuestReadyMediator:getFixedCardPosInTeam(stageId, playerPos, index)
    local fixedPos = 0
    local stageConfig = CommonUtils.GetQuestConf(stageId)

    if nil ~= stageConfig and nil ~= stageConfig.attendPosition then
        for i = 1, (playerPos - 1) do
            fixedPos = fixedPos + checkint(stageConfig.attendPosition[i])
        end
    end

    fixedPos = fixedPos + index
    return fixedPos
end
--[[
根据队伍的卡牌位置获取自己的上卡槽位
@params stageId int 关卡id
@params playerPos int 玩家位置
@params cardPos int 卡牌位置
@return index int 上卡槽位
--]]
function TeamQuestReadyMediator:getAddCardIndex(stageId, playerPos, cardPos)
    local fixedPos = 0
    local stageConfig = CommonUtils.GetQuestConf(stageId)

    if nil ~= stageConfig and nil ~= stageConfig.attendPosition then
        for i = 1, (playerPos - 1) do
            fixedPos = fixedPos + checkint(stageConfig.attendPosition[i])
        end
    end

    local index = cardPos - fixedPos
    return index
end
--[[
根据玩家id判断是否是队长
@params playerId int 玩家id
@return _ bool 是否是队长
--]]
function TeamQuestReadyMediator:isCaptainByPlayerId(playerId)
    return self:getTeamModel():getCaptainId() == playerId
end
--[[
获取本玩家id
@return _ int 玩家id
--]]
function TeamQuestReadyMediator:getSelfPlayerId()
    return checkint(gameMgr:GetUserInfo().playerId)
end

return TeamQuestReadyMediator

