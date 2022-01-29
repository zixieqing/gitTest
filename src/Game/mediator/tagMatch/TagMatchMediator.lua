--[[
 * descpt : 天城演武 入口 中介者
]]
local NAME = 'TagMatchMediator'
local TagMatchMediator = class(NAME, mvc.Mediator)

------------ import ------------
local AppFacadeInstance = AppFacade.GetInstance()
local uiMgr    = AppFacadeInstance:GetManager('UIManager')
local gameMgr  = AppFacadeInstance:GetManager("GameManager")
local cardMgr  = AppFacadeInstance:GetManager('CardManager')
local timerMgr = AppFacadeInstance:GetManager("TimerManager")
------------ import ------------

local BUTTON_TAG = {
    RULE        = 100,     -- 规则说明
    FIGHT       = 101,     -- 战斗
    SIGH_UP     = 102,     -- 报名
    LOOK_REWARD = 103,     -- 查看奖励
    RANK        = 104,     -- 排行榜
}

-- 确定报名
local TAG_MATCH_DETERMINE_SIGN_UP                 = 'TAG_MATCH_DETERMINE_SIGN_UP'
-- 天城演武 点击确定时  保存团队
local TAG_MATCH_CHANGE_DEFENSE_TEAM_MEMBER_SIGNAL = 'TAG_MATCH_CHANGE_DEFENSE_TEAM_MEMBER_SIGNAL'
-- 通用改变团队
local LOCAL_SWITCH_TEAM                           = 'LOCAL_SWITCH_TEAM'
-- 拖拽改变团队
local LOCAL_DRAG_CHANGE_TEAM                      = 'LOCAL_DRAG_CHANGE_TEAM'
-- 关闭 改变团队界面
local CLOSE_CHANGE_TEAM_SCENE                     = 'CLOSE_CHANGE_TEAM_SCENE'


function TagMatchMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
    
end

-------------------------------------------------
-- init method
function TagMatchMediator:Initial(key)
    self.super.Initial(self, key)

    self.datas = {}
    self.datas.teamDatas = {}
    self.isControllable_ = true
    self.isCanSignUp = false
    -- 等级区间配置
    self.levelStageConf = {}
    -- 当前的视图状态
    self.curViewState = nil
    -- create view
    local viewComponent = require('Game.views.tagMatch.TagMatchView').new()
    self.viewData_      = viewComponent:getViewData()
    self:SetViewComponent(viewComponent)
    
    -- init data
    self:initData_()
    -- init view
    self:initView_()
    
end

function TagMatchMediator:initData_()
    -- self.levelStageConf = self:getLevelStageBySegment(gameMgr:GetUserInfo().level)
end

function TagMatchMediator:initView_()
    local viewData   = self:getViewData()
    local actionBtns = viewData.actionBtns

    for tag, btn in pairs(actionBtns) do
        btn:setTag(checkint(tag))
        display.commonUIParams(btn, {cb = handler(self, self.onButtonAction)})    
    end
    
    local teamCells  = viewData.teamCells
    for i, teamCell in ipairs(teamCells) do
        local teamCellViewData = teamCell.viewData
        local fightHeadBg = teamCellViewData.fightHeadBg
        fightHeadBg:setTag(i)
        display.commonUIParams(fightHeadBg, {cb = handler(self, self.onClickFightHeadAction)})
    end

    -- set rule
    local explainConfig = CommonUtils.GetConfigAllMess('explain', 'kofArena')
    self:GetViewComponent():updateRule(tostring(explainConfig['1'].descr))
end

function TagMatchMediator:OnRegist()
    regPost(POST.ACTIVITY_KOFARENA, true)
    regPost(POST.TAG_MATCH_SIGN_UP, true)
    self:enterLayer()
end
function TagMatchMediator:OnUnRegist()
    unregPost(POST.ACTIVITY_KOFARENA, true)
    unregPost(POST.TAG_MATCH_SIGN_UP, true)

    timerMgr:RemoveTimer(NAME)
end

function TagMatchMediator:InterestSignals()
    return {
        ---------------------- server ----------------------
        POST.ACTIVITY_KOFARENA.sglName,
        POST.TAG_MATCH_SIGN_UP.sglName,
        -- POST.TAG_MATCH_SET_ATTACK_CARDS.sglName,
        ---------------------- local ----------------------
        SGL.FRESH_3V3_MATCH_BATTLE_DATA,
        TAG_MATCH_CHANGE_DEFENSE_TEAM_MEMBER_SIGNAL,
        LOCAL_SWITCH_TEAM,
        LOCAL_DRAG_CHANGE_TEAM,
        TAG_MATCH_DETERMINE_SIGN_UP,
        'CLOSE_CHANGE_TEAM_SCENE',
        COUNT_DOWN_ACTION,
        SGL.PRESET_TEAM_SELECT_CARDS,
    }
end

function TagMatchMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody() or {}
    
    local errcode = checkint(body.errcode)
    -- 如果错误码是强制关闭 则直接关闭此界面 并回到活动界面
    if errcode == MODULE_CLOSE_ERROR.TAG_MATCH then
        gameMgr:set3v3MatchBattleData()
        return
    end

    if name == POST.ACTIVITY_KOFARENA.sglName then
        if checkint(body.section) == MATCH_BATTLE_3V3_TYPE.CLOSE then
            gameMgr:set3v3MatchBattleData()
        else
            gameMgr:set3v3MatchBattleData(body)
        end
    elseif name == SGL.FRESH_3V3_MATCH_BATTLE_DATA then
        self.datas = gameMgr:get3v3MatchBattleData()
        local defendCards = self.datas.defendCards
        
        -- 只要报名成功 防守阵容 必不为空
        local teamDatas = {}
        for teamId, cardIds in pairs(defendCards) do
            teamDatas[teamId] = teamDatas[teamId] or {}
            for i, cardId in ipairs(cardIds) do
                if checkint(cardId) > 0 then
                    table.insert(teamDatas[teamId], {id = cardId})
                end
            end
        end
        
        self.datas.teamDatas = teamDatas

        gameMgr:SetTagMatchDefendData(teamDatas)

        if next(self.levelStageConf) == nil then
            self.levelStageConf = self:getLevelStageBySegment(self.datas.segment)
        end

        self.curViewState = self:getViewData()
        self:GetViewComponent():refreshUi(self.datas, self.levelStageConf, self.curViewState)

        self:startCountDown(self.datas.leftSeconds)

        self:setDefineTeamId(self:getDefineTeamId())

        
    elseif name == POST.TAG_MATCH_SIGN_UP.sglName then
        
        uiMgr:ShowInformationTips(__('报名成功'))

        self.datas.isApply = 1
        self.curViewState = self:getViewData()

        local teamDatas = self:getTeamDatas()
        local teampDatas = {}
        for teamId, cardDatas in pairs(teamDatas) do
            teampDatas[tostring(teamId)] = teampDatas[tostring(teamId)] or {} 
            for i, cardData in ipairs(cardDatas) do
                table.insert(teampDatas[tostring(teamId)], cardData.id)
            end
        end
        -- 更新缓存数据
        gameMgr:get3v3MatchBattleData().isApply = 1
        gameMgr:get3v3MatchBattleData().defendCards = teampDatas
        gameMgr:SetTagMatchDefendData(teamDatas)
        
        self:GetViewComponent():updateBtnState(self.datas.section, self.datas.isApply)
    elseif name == TAG_MATCH_CHANGE_DEFENSE_TEAM_MEMBER_SIGNAL then
        if self.toCleanTeamId_ then
            self:setDefineTeamId(0)
            self.toCleanTeamId_ = false
        end
        local teamDatas = body.teamDatas or {}
        -- local teamId = body.teamId
        -- self:setTeamData(teamId, teamDatas[tostring(teamId)])
        self:setTeamDatas(teamDatas)
        self:GetViewComponent():updateTeamCell(self:getTeamDatas())
        -- 保存成功 更新头像
        -- AppFacade.GetInstance():DispatchObservers('UPDATE_TEAM_HEAD', {teamIds = {teamId}})
        AppFacade.GetInstance():DispatchObservers('CLOSE_CHANGE_TEAM_SCENE')
        uiMgr:ShowInformationTips(__('更换防守阵容成功!!!报名参赛后生效!'))
    elseif name == LOCAL_SWITCH_TEAM then
        local isAttack = body.isAttack
        if isAttack then return end

        local oldTeamId = body.oldTeamId
        local newTeamId = body.newTeamId
        if self.changeTeamLayer then
            -- 1. 取出 需要保存的卡牌数据
            local teamData = self.changeTeamLayer:GetSelectedCardsByTeamId(oldTeamId)
            
            self.changeTeamLayer:SetTeamData(self.changeTeamLayer:GetSelectedCardsByTeamId(newTeamId))
            self.changeTeamLayer:SetTeamId(tostring(newTeamId))

            -- 保存成功 更新头像
            AppFacade.GetInstance():DispatchObservers('UPDATE_TEAM_HEAD', {teamIds = {oldTeamId}})
        end
    elseif name == LOCAL_DRAG_CHANGE_TEAM then
        local isAttack = body.isAttack
        if isAttack then return end

        if self.toCleanTeamId_ then
            self:setDefineTeamId(0)
            self.toCleanTeamId_ = false
        end

        local oldTeamId = body.oldTeamId
        local newTeamId = body.newTeamId

        if self.changeTeamLayer then
            -- 交换数据 (warn: 返回的为交换前的数据)
            local newTeamData, oldTeamData = self.changeTeamLayer:SwapSelectedCards(oldTeamId, newTeamId)
            
            -- 获取当前选中的团队id
            local curTeamId = checkint(self.changeTeamLayer:GetTeamId())
            -- 拖拽更新规则：(假设: 当前选中团队为 1)
            --     1. 无论 1 拖 2 还是 2 拖1 最后选中的团队 必是 最终拖拽结束的位置
            --     2. 如果 2和3 互拖 不会改变选中状态

            -- 如果 拖拽的团队 与 被拖拽改变位置的团队 都与 当前选中的团队 
            if not (curTeamId ~= checkint(oldTeamId) and curTeamId ~= checkint(newTeamId)) then

                self.changeTeamLayer:SetTeamId(tostring(newTeamId))
                self.changeTeamLayer:SetTeamData(oldTeamData)
                
                if checkint(curTeamId) ~= checkint(newTeamId) then
                    self.changeTeamLayer:RefreshBattleScriptTypeUI({newTeamId = newTeamId})
                end

            end

            self.changeTeamLayer:ResetAllCardSelectState()
            
        end

    elseif name == TAG_MATCH_DETERMINE_SIGN_UP then
        
        local cards = {}
        for i, v in pairs(self:getTeamDatas()) do
            cards[i] = self:convertTeamDataToStr(v)
        end
        
        self:SendSignal(POST.TAG_MATCH_SIGN_UP.cmdName, {cards = json.encode(cards), teamCustomId = self:getDefineTeamId()})


    elseif name == 'CLOSE_CHANGE_TEAM_SCENE' then
        self.changeTeamLayer = nil
    elseif name == COUNT_DOWN_ACTION then
        local timerName = tostring(body.timerName)
        if NAME == timerName then
            local countdown = checkint(body.countdown)
            self:GetViewComponent():updateCountDown(countdown)
        end

    elseif name == SGL.PRESET_TEAM_SELECT_CARDS then
        local tagMatchLobbyMdt = self:GetFacade():RetrieveMediator('tagMatch.TagMatchLobbyMediator')
        if tagMatchLobbyMdt == nil then
            if self.datas.section ~= 1 then
                uiMgr:ShowInformationTips(__('非报名阶段'))
                return
            end
        
            local presetTeamData = checktable(body.presetTeamData)
            self:setDefineTeamId(presetTeamData.teamId)
            self.toCleanTeamId_ = false

            local defendCards = presetTeamData.cardIds or {}
            local teamDatas = {}
            for teamId, cardIds in pairs(defendCards) do
                teamDatas[tostring(teamId)] = teamDatas[tostring(teamId)] or {}
                for i, cardUuid in ipairs(cardIds) do
                    if checkint(cardUuid) > 0 then
                        table.insert(teamDatas[tostring(teamId)], {id = cardUuid})
                    end
                end
            end
            app:DispatchObservers(TAG_MATCH_CHANGE_DEFENSE_TEAM_MEMBER_SIGNAL, {teamDatas = teamDatas})
        end
        
    end
end 

-------------------------------------------------
-- get / set

function TagMatchMediator:getCtorArgs()
    return self.ctorArgs_
end

function TagMatchMediator:getViewData()
    return self.viewData_
end

function TagMatchMediator:getOwnerScene()
    return self.ownerScene_
end

function TagMatchMediator:getDatas()
    return self.datas
end


function TagMatchMediator:getDefineTeamId()
    return checkint(gameMgr:get3v3MatchBattleData().teamCustomId)
end
function TagMatchMediator:setDefineTeamId(teamId)
    gameMgr:get3v3MatchBattleData().teamCustomId = checkint(teamId)
    self:getViewData().presetTeamIcon:setVisible(checkint(teamId) > 0)
end


--[[
    更新 等级区间id 获得 等级阶段
    @params segment 等级区间id
]]
function TagMatchMediator:getLevelStageBySegment(segment)
    segment = checkint(segment)
    
    local conf = {}
    local levelSegmentConf       = CommonUtils.GetConfigAllMess('levelSegment', 'kofArena')
    local lvDatas = CommonUtils.GetConfigAllMess('level', 'player')
    local maxLv = table.nums(lvDatas)
    if segment <= 0 then
        local userLv = gameMgr:GetUserInfo().level
        
        local stage = 0
        for i, levelSegment in pairs(levelSegmentConf) do
            local upperLimit = checkint(levelSegment.upperLimit)
            local lowerLimit = checkint(levelSegment.lowerLimit)
            if userLv >= lowerLimit and userLv <= upperLimit then
                conf.id         = levelSegment.id
                conf.upperLimit = math.min(upperLimit, maxLv)
                conf.lowerLimit = lowerLimit
                conf.name       = levelSegment.name
                conf.unlock  = true
                break
            end
        end

        if next(conf) == nil then
            local levelSegment = levelSegmentConf['1']
            conf.id            = levelSegment.id
            conf.upperLimit    = checkint(levelSegment.upperLimit)
            conf.lowerLimit    = checkint(levelSegment.lowerLimit)
            conf.name          = levelSegment.name
            conf.unlock        = false
        end
    else
        local levelSegment = levelSegmentConf[tostring(segment)]
        conf.id            = levelSegment.id
        conf.upperLimit    = math.min(checkint(levelSegment.upperLimit), maxLv)
        conf.lowerLimit    = checkint(levelSegment.lowerLimit)
        conf.name          = levelSegment.name
        conf.unlock        = true
    end
    
    return conf    
end

function TagMatchMediator:getTeamDatas()
    return self.datas.teamDatas
end
function TagMatchMediator:setTeamData(teamId, teamData)
    self.datas.teamDatas[tostring(teamId)] = teamData
end
function TagMatchMediator:setTeamDatas(teamDatas)
    self.datas.teamDatas = teamDatas
end

--[[
    根据团队数据获得战力
    @params teamData 团队数据
]]
function TagMatchMediator:getBattlePointByTeamData(teamData)
    local battlePoint = 0
    for i, v in ipairs(teamData) do
        local id = v.id
        if checkint(id) > 0 then
            battlePoint = battlePoint + cardMgr.GetCardStaticBattlePointById(v.id)
        end
    end
    return battlePoint
end

-------------------------------------------------
-- public method
function TagMatchMediator:enterLayer()
    self:SendSignal(POST.ACTIVITY_KOFARENA.cmdName)
end

--[[
    开启倒计时
    @params leftSeconds 剩余时间
]]
function TagMatchMediator:startCountDown(leftSeconds)
    leftSeconds = checkint(leftSeconds)
    local timerInfo = timerMgr:RetriveTimer(NAME)
    if timerInfo then
        timerMgr:RemoveTimer(NAME)
    end
    if leftSeconds > 0 then
        timerMgr:AddTimer({name = NAME, countdown = leftSeconds})
    else
        AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, timerName = NAME})
    end
end

-------------------------------------------------
-- private method
function TagMatchMediator:CleanupView()
    local viewComponent = self:GetViewComponent()
    if viewComponent and not tolua.isnull(viewComponent) then
        viewComponent:setVisible(false)
        viewComponent:setLocalZOrder(-9999)
        viewComponent:runAction(cc.RemoveSelf:create())
    end
end


-------------------------------------------------
-- check

--[[
    检查是否报名成功
]]
function TagMatchMediator:checkIsCanSignUp()
    local teamDatas = self:getTeamDatas()
    local isCanSignUp = next(teamDatas) ~= nil
    for i, v in pairs(teamDatas) do
        if table.nums(v) < MAX_TEAM_MEMBER_AMOUNT then
            isCanSignUp = false
            return isCanSignUp
        else
            for ii, vv in ipairs(v) do
                if (next(vv) == nil) or (vv.id == nil) then
                    isCanSignUp = false
                    return isCanSignUp
                end
            end
        end
    end
    return isCanSignUp
end

-------------------------------------------------
-- handler

function TagMatchMediator:onButtonAction(sender)
    if self.levelStageConf.unlock ~= true then
        uiMgr:ShowInformationTips(string.format(__('该功能%s解锁'), self.levelStageConf.lowerLimit))
        return
    end

    local tag = sender:getTag()
    if tag == BUTTON_TAG.RULE then
        uiMgr:ShowIntroPopup({moduleId = MODULE_DATA[tostring(RemindTag.TAG_MATCH)]})
    elseif tag == BUTTON_TAG.FIGHT then
        
        -- local mediator = require("Game.mediator.tagMatch.TagMatchLobbyMediator").new()
        -- AppFacade.GetInstance():RegistMediator(mediator)

        self:GetFacade():RetrieveMediator("Router"):Dispatch({name = "HomeMediator"}, {name = "tagMatch.TagMatchLobbyMediator"})

    elseif tag == BUTTON_TAG.SIGH_UP then
        if self.datas.section ~= 1 then
            uiMgr:ShowInformationTips(__('非报名阶段'))
            return
        end
        local isCanSignUp = self:checkIsCanSignUp()
        if not isCanSignUp then
            uiMgr:ShowInformationTips(__('防守队伍未满编, 不能报名'))
            return
        end
        
        local tag = 13110
        local signUpView = require("Game.views.tagMatch.TagMatchDetermineSignUpView").new({tag = tag, cardsDatas = self:getTeamDatas()})
        signUpView:setPosition(display.center)
        signUpView:setTag(tag)
        uiMgr:GetCurrentScene():AddDialog(signUpView)
        
    elseif tag == BUTTON_TAG.LOOK_REWARD then
        local rewardsDatas = CommonUtils.GetConfigAllMess('rankReward', 'kofArena')
        local curLv = checkint(self.levelStageConf.id)
        local rewardList = rewardsDatas[tostring(curLv)] or {}

        local tag = 1200
        local rankRewardsView = require('Game.views.LobbyRewardListView').new({
            tag = tag,
            showTips = true,
            title = __('本次排行榜奖励'),
            msg = __('奖励发放时间：活动结束后两小时'),
            rewardsDatas = rewardList
        })
        rankRewardsView:setTag(tag)
        rankRewardsView:setPosition(display.center)
        uiMgr:GetCurrentScene():AddDialog(rankRewardsView)
    elseif tag == BUTTON_TAG.RANK then
        local mediator = require("Game.mediator.KofArenaRankMediator").new()
        self:GetFacade():RegistMediator(mediator)
    end
end

function TagMatchMediator:onClickFightHeadAction(sender)
    if self.levelStageConf.unlock ~= true then
        uiMgr:ShowInformationTips(__('未解锁'))
        return
    end
    if self.datas.section ~= 1 then
        uiMgr:ShowInformationTips(__('非报名阶段'))
        return
    end
    if self.datas.isApply > 0 then
        uiMgr:ShowInformationTips(__('已报名成功, 不可再编辑防守队伍'))
        return
    end

    if self:getDefineTeamId() > 0 then
        app.uiMgr:AddNewCommonTipDialog({
            text = __('使用预设编队不能进行单独修改，是否使用普通编队？'),
            callback = function()
                -- 显示编队界面
                self.toCleanTeamId_ = true
                self:showEditTeamView_(1)
            end
        })
        return
    end

    -- 显示编队界面
    local teamId = sender:getTag()
    self:showEditTeamView_(teamId)
end


function TagMatchMediator:showEditTeamView_(teamId)
    -- 进入 选择团队 界面
    local teamData = self.datas.teamDatas[tostring(teamId)] or {}
    local layer = require('Game.views.tagMatch.TagMatchChangeTeamScene').new({
        -- teamData = teamData or {},
        teamId         = tostring(teamId),
        teamDatas      = self.datas.teamDatas or {},
        teamTowards    = -1,
        avatarTowards  = -1,
        avatarShowType = 2,
        teamChangeSingalName = TAG_MATCH_CHANGE_DEFENSE_TEAM_MEMBER_SIGNAL,
        battleTypeData = {
            isShowOppentTeam = false,
            isAttack     = false,
        },
        battleType = BATTLE_SCRIPT_TYPE.TAG_MATCH
    })
    layer:setAnchorPoint(cc.p(0.5, 0.5))
    layer:setPosition(display.center)
    uiMgr:GetCurrentScene():AddDialog(layer)  
    self.changeTeamLayer = layer
end


function TagMatchMediator:convertTeamDataToStr(teamData)
    local teamStr = ''
    local teamDataLen = #teamData
    for i = 1, teamDataLen do
        teamStr = teamStr .. (teamData[i].id or '')
        if i ~= teamDataLen then
            teamStr = teamStr .. ','
        end
    end
    return teamStr
end

return TagMatchMediator
