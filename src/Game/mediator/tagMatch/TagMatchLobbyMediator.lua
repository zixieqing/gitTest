--[[
 * descpt : 天城演武 大厅 中介者
]]
local NAME = 'tagMatch.TagMatchLobbyMediator'
local TagMatchLobbyMediator = class(NAME, mvc.Mediator)

local AppFacadeInstance = AppFacade.GetInstance()
local uiMgr    = AppFacadeInstance:GetManager('UIManager')
local gameMgr  = AppFacadeInstance:GetManager("GameManager")
local timerMgr = AppFacadeInstance:GetManager("TimerManager")
local cardMgr  = AppFacadeInstance:GetManager("CardManager")

local BUTTON_TAG = {
    BACK        = 100,  -- 返回
    SHIELD      = 101,  -- 点击盾牌
    MODIFY      = 102,  -- 点击修改
    FIGHT       = 103,  -- 战斗
    REPORT      = 104,  -- 战报
    REFRESH     = 105,  -- 刷新
    SHOP        = 106,  -- 商店
    RANK        = 107,  -- 排行榜
}

-- 天城演武 点击确定时  保存进攻团队
local TAG_MATCH_CHANGE_ATTACK_TEAM_MEMBER_SIGNAL = 'TAG_MATCH_CHANGE_ATTACK_TEAM_MEMBER_SIGNAL'

-- 通用改变团队
local LOCAL_SWITCH_TEAM          = 'LOCAL_SWITCH_TEAM'
-- 拖拽改变团队
local LOCAL_DRAG_CHANGE_TEAM     = 'LOCAL_DRAG_CHANGE_TEAM'
-- 进入战斗
local ENTER_TAG_MATCH_BATTLE     = 'ENTER_TAG_MATCH_BATTLE'
-- 显示敌方团队
local SHOW_OPPONENT_TEAM         = 'SHOW_OPPONENT_TEAM'
-- 显示 排行榜
local SHOW_PVC_RANK              = 'SHOW_PVC_RANK'
-- 显示编辑团队界面
local SHOW_TAG_MATCH_EDIT_TEAM   = 'SHOW_TAG_MATCH_EDIT_TEAM'
-- 关闭 改变团队界面
local CLOSE_CHANGE_TEAM_SCENE    = 'CLOSE_CHANGE_TEAM_SCENE'
-- 点击战报列表
local CLICK_PVC_REPORT_VIEW_CELL = 'CLICK_PVC_REPORT_VIEW_CELL'
-- 通用dialog 的关闭
local CLOSE_COMMON_DIALOG        = 'CLOSE_COMMON_DIALOG'

-- 最大对手个数
local MAX_ENEMY_COUNT = 4

function TagMatchLobbyMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
    -- logInfo.add(5, tableToString(self.ctorArgs_))
    self.datas = self.ctorArgs_
    self.isRequestSuc = checkint(self.datas.errcode) == 0
end

-------------------------------------------------
-- init method
function TagMatchLobbyMediator:Initial(key)
    self.super.Initial(self, key)

    self.isControllable_ = true
    
    self.isTimeEnd = false

    self.isCanEnterBattlePrepare = false
    -- 当前对手下标
    self.curSelectOppoentIndex = 0
    
    -- 当前团队id 
    self.teamId = 0

    -- create view
    local viewComponent = require('Game.views.tagMatch.TagMatchLobbyView').new()
    self.viewData_      = viewComponent:getViewData()
    self:SetViewComponent(viewComponent)
    -- add layer
    self.ownerScene_ = uiMgr:GetCurrentScene()
    display.commonUIParams(viewComponent,{po = display.center, ap = display.CENTER})
    self:getOwnerScene():AddDialog(viewComponent)
    
    if self.isRequestSuc then
        -- init data
        self:initData_()
        -- init view
        self:initView_()
    end
    
end

function TagMatchLobbyMediator:initData_()

end

function TagMatchLobbyMediator:initView_()
   local viewData = self:getViewData()
    
   local backBtn = viewData.backBtn
   display.commonUIParams(backBtn, {cb = handler(self, self.onCloseViewAction)})

   local ruleBtn = viewData.ruleBtn
   display.commonUIParams(ruleBtn, {cb = handler(self, self.onClickRuleAction)})

   local titleRuleBtn = viewData.titleRuleBtn
   display.commonUIParams(titleRuleBtn, {cb = handler(self, self.onClickTitleRuleAction)})

   local actionBtns = viewData.actionBtns
   for tag, btn in pairs(actionBtns) do
        display.commonUIParams(btn, {cb = handler(self, self.onBtnAction)})
        btn:setTag(checkint(tag))
   end
   
   local playerTeamHeadBgs = viewData.playerTeamHeadBgs
   for i, playerTeamHeadBg in ipairs(playerTeamHeadBgs) do
       -- 初始化头像背景
       local playerTeamHeadBgViewData = playerTeamHeadBg.viewData
       local clickLayer = playerTeamHeadBgViewData.clickLayer
       display.commonUIParams(clickLayer, {cb = handler(self, self.onClickPlayerTeamHeadBg)})
       clickLayer:setTag(i)
   end

   local gridView = viewData.gridView
   gridView:setDataSourceAdapterScriptHandler(handler(self, self.onOppoentAdapter))
   
   self:showView()
end

function TagMatchLobbyMediator:CleanupView()
    self:hideSingleTeamInfo()
    local viewComponent = self:GetViewComponent()
    if self.ownerScene_ and viewComponent and not tolua.isnull(viewComponent) then
        self.ownerScene_:RemoveDialog(viewComponent)
        self.ownerScene_ = nil
    end
end


function TagMatchLobbyMediator:OnRegist()
    regPost(POST.TAG_MATCH_HOME, true)
    regPost(POST.TAG_MATCH_REFRESH_ENEMY, true)
    regPost(POST.TAG_MATCH_SET_ATTACK_CARDS, true)
    regPost(POST.TAG_MATCH_ARENA_RECORD, true)
    regPost(POST.TAG_MATCH_GET_ENEMY_INFO, true)
    regPost(POST.PRESET_TEAM_GET_TEAM_CUSTOM_DETAIL, true)

    -- 请求失败 关闭当前界面
    if not self.isRequestSuc then
        self:closeView()
    end

    -- 如果不是走路由 重新请求
    if next(self.datas) == nil then
        self:enterLayer()
    end

end
function TagMatchLobbyMediator:OnUnRegist()
    
    
    unregPost(POST.TAG_MATCH_HOME)
    unregPost(POST.TAG_MATCH_REFRESH_ENEMY)
    unregPost(POST.TAG_MATCH_SET_ATTACK_CARDS)
    unregPost(POST.TAG_MATCH_ARENA_RECORD)
    unregPost(POST.TAG_MATCH_GET_ENEMY_INFO)
    unregPost(POST.PRESET_TEAM_GET_TEAM_CUSTOM_DETAIL)

    timerMgr:RemoveTimer(NAME)
end


function TagMatchLobbyMediator:InterestSignals()
    return {
        ------------ local ------------
        ENTER_TAG_MATCH_BATTLE,                         -- 进入战斗
        -- handle data
        LOCAL_SWITCH_TEAM,                              -- 点击选择团队
        LOCAL_DRAG_CHANGE_TEAM,                         -- 拖拽选择团队
        TAG_MATCH_CHANGE_ATTACK_TEAM_MEMBER_SIGNAL,     -- 确定保存团队
        SGL.PRESET_TEAM_SELECT_CARDS,
        -- show ui
        SHOW_OPPONENT_TEAM,                             -- 显示对手团队
        SHOW_PVC_RANK,                                  -- 显示排行榜
        SHOW_TAG_MATCH_EDIT_TEAM,                       -- 显示编辑团队界面
        CLOSE_CHANGE_TEAM_SCENE,                        -- 关闭编辑团队界面
        COUNT_DOWN_ACTION,                              -- 倒计时
        CLICK_PVC_REPORT_VIEW_CELL,                     -- 点击战报列表cell
        CLOSE_COMMON_DIALOG,
        ------------ long connection ------------
        SGL.TAG_MATCH_SGL_PLAYER_RANK_CHANGE,
        SGL.TAG_MATCH_SGL_PLAYER_SHIELD_POINT_CHANGE,
        ------------ server ------------
        POST.TAG_MATCH_HOME.sglName,
        POST.TAG_MATCH_REFRESH_ENEMY.sglName,
        POST.TAG_MATCH_SET_ATTACK_CARDS.sglName,
        POST.TAG_MATCH_ARENA_RECORD.sglName,
        POST.TAG_MATCH_GET_ENEMY_INFO.sglName,
        POST.PRESET_TEAM_GET_TEAM_CUSTOM_DETAIL.sglName,
    }
end

function TagMatchLobbyMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody() or {}
    local errcode = checkint(body.errcode)
    -- 如果错误码是强制关闭 则直接关闭此界面 并回到活动界面
    if errcode == MODULE_CLOSE_ERROR.TAG_MATCH then
        gameMgr:set3v3MatchBattleData()
        self:closeView(nil, true)
        return
    end

    if name == CLICK_PVC_REPORT_VIEW_CELL then
        local data = body.data
        local cell = body.cell

        -- logInfo.add(5, tableToString(data))
        if cell and not tolua.isnull(cell) then
            uiMgr:ShowInformationTipsBoard({
                targetNode = cell, 
                type = 10,
                bgSize = cc.size(410, 530),
                title = __('总灵力'),
                viewTypeData = {
                    teamInfo = data.opponent.teamInfo
                }
            })
        end
    elseif name == CLOSE_COMMON_DIALOG then
        self:getOwnerScene():RemoveDialogByTag(23456)
    elseif name == POST.TAG_MATCH_HOME.sglName then
        self.datas = body
        self:updateSelectFrame(self:getViewData(), self.curSelectOppoentIndex, false)
        self:showView()
    -- 刷新对手
    elseif name == POST.TAG_MATCH_REFRESH_ENEMY.sglName then
        
        -- 先更改上一个 cell 的选择状态
        self:updateSelectFrame(self:getViewData(), self.curSelectOppoentIndex, false)
        self.curSelectOppoentIndex = 0
        self.datas.enemyList = body.enemyList or {}
        self.datas.leftRefreshTimes = checkint(body.leftRefreshTimes)

        uiMgr:ShowInformationTips(string.format(__('更换成功!!!本次演武剩余更换次数为: %s'), self.datas.leftRefreshTimes))

        -- 检查一遍 对手列表
        self:checkEnemyList()
        self:GetViewComponent():updateLeftRefreshTimes(self.datas.leftRefreshTimes, self.datas.maxRefreshTimes)
        self:GetViewComponent():updateOpponentInfo(self.datas)
        
    -- 设置进攻卡牌
    elseif name == POST.TAG_MATCH_SET_ATTACK_CARDS.sglName then
        uiMgr:ShowInformationTips(__('更改进攻阵容成功'))

        local requestData = body.requestData
        local cards       = json.decode(requestData.cards)
        -- logInfo.add(5, tableToString(cards))
        -- local teamDatas   = self:getTeamDatas()
        local teamIds = {}
        for teamId, teamStr in pairs(cards) do
            -- logInfo.add(5, tableToString(self:convertTeamStrToData(teamStr)))
            self:setTeamDatas(teamId, self:convertTeamStrToData(teamStr))
            table.insert(teamIds, teamId)
        end

        self:GetViewComponent():updateTeamHead(self:getTeamDatas())
        -- 保存成功 更新头像
        AppFacade.GetInstance():DispatchObservers('UPDATE_TEAM_HEAD', {teamIds = teamIds, attackTeamId = self:getAttackTeamId()})
        
    -- 进入战报界面 
    elseif name == POST.TAG_MATCH_ARENA_RECORD.sglName then
        local totalTimes = checkint(body.totalTimes)
        local winTimes   = checkint(body.winTimes)
        local records    = body.records or {}
        
        local tag = 110
        local layer = require('Game.views.pvc.PVCReportView').new({
            tag = tag,
            winTimes = winTimes,
            loseTimes = totalTimes - winTimes,
            viewType = BATTLE_SCRIPT_TYPE.TAG_MATCH,
            headDefaultCallback = true,
            enableCellCallback = true,
            reportData = records})
        layer:setTag(tag)
        layer:setAnchorPoint(cc.p(0.5, 0.5))
        layer:setPosition(cc.p(display.cx, display.cy))
        self:getOwnerScene():AddDialog(layer)

    elseif POST.PRESET_TEAM_GET_TEAM_CUSTOM_DETAIL.sglName == name then
        
        if errcode == 0 then
            if checkint(body.valid) == 1 then
                self:enterBattle(self.tempEnemyData_, body)
            else
                app.uiMgr:ShowInformationTips(__('当前预设编队已失效'))
            end
        else
            local tagMatchFightPrepareMediator = self:GetFacade():RetrieveMediator('TagMatchFightPrepareMediator')
            if tagMatchFightPrepareMediator then
                self:GetFacade():UnRegsitMediator("TagMatchFightPrepareMediator")
            end
            self:enterLayer()
        end

    elseif name == POST.TAG_MATCH_GET_ENEMY_INFO.sglName then
        -- local errcode = checkint(body.errcode)
        local data = body.data or {}
        
        if errcode == 0 then
            if self:getAttackTeamId() > 0 then
                self.tempEnemyData_ = body
                ---获取预设编队阵容卡牌数据
                self:SendSignal(POST.PRESET_TEAM_GET_TEAM_CUSTOM_DETAIL.cmdName, {teamId = self:getAttackTeamId()})
            else
                self:enterBattle(body)
            end

        elseif errcode == 2 then
            -- uiMgr:ShowInformationTips(__('该御侍已被淘汰，请重新选择对手'))
            local tagMatchFightPrepareMediator = self:GetFacade():RetrieveMediator('TagMatchFightPrepareMediator')
            if tagMatchFightPrepareMediator then
                self:GetFacade():UnRegsitMediator("TagMatchFightPrepareMediator")
            end
            self:enterLayer()
        end
    elseif name == SGL.TAG_MATCH_SGL_PLAYER_RANK_CHANGE then
        local rank = checkint(body.rank)
        self.datas.rank = rank
        self:GetViewComponent():updateCurRankLabel(rank)
    elseif name == SGL.TAG_MATCH_SGL_PLAYER_SHIELD_POINT_CHANGE then
        local shieldPoint = checkint(body.shieldPoint)
        self.datas.shieldPoint = shieldPoint
        self:GetViewComponent():updateShield(shieldPoint, checkint(self.datas.maxShieldPoint), true)
    elseif name == SHOW_PVC_RANK then
        self:showRank()
    elseif name == ENTER_TAG_MATCH_BATTLE then
        if not self:checkSwordPoint() then
            uiMgr:ShowInformationTips(__('失败次数已达三次上限, 不能再挑战其他御侍'))
            return
        end
        if not self:checkShieldPoint() then
            uiMgr:ShowInformationTips(__('护盾值已用完, 不能再挑战其他御侍'))
            return
        end
        if not self:checkIsCanEnterBattlePrepare(self:getTeamDatas()) then
            uiMgr:ShowInformationTips(__('队伍不能为空'))
            return
        end 
        
        local enemyPlayerId = body.enemyPlayerId
        self:SendSignal(POST.TAG_MATCH_GET_ENEMY_INFO.cmdName, {enemyPlayerId = enemyPlayerId})
        
    elseif name == TAG_MATCH_CHANGE_ATTACK_TEAM_MEMBER_SIGNAL then
        if self.toCleanTeamId_ then
            self:setAttackTeamId(0)
            self.toCleanTeamId_ = false
        end

        local teamDatas = body.teamDatas or {}

        -- 1. 先检查 要替换的队伍是否能 替换
        if not self:checkIsCanEnterBattlePrepare(teamDatas) then
            uiMgr:ShowInformationTips(__('队伍不能为空'))
            return
        end

        -- 2. 再检查 队伍是否改变
        if self:checkTeamDataChange(teamDatas) then
            self:requestSetAttackTeam(teamDatas)
        end

        AppFacade.GetInstance():DispatchObservers('CLOSE_CHANGE_TEAM_SCENE')

    elseif name == LOCAL_SWITCH_TEAM then
        local isAttack = body.isAttack
        if not isAttack then return end
        
        local oldTeamId = body.oldTeamId
        local newTeamId = body.newTeamId
        
        if self.changeTeamLayer then
            self.changeTeamLayer:SetTeamData(clone(self.changeTeamLayer:GetSelectedCardsByTeamId(newTeamId)))
            self.changeTeamLayer:SetTeamId(tostring(newTeamId))
        end
    elseif name == LOCAL_DRAG_CHANGE_TEAM then
        local isAttack = body.isAttack
        if not isAttack then return end

        if self.toCleanTeamId_ then
            self:setAttackTeamId(0)
            self.toCleanTeamId_ = false
        end

        local oldTeamId = body.oldTeamId
        local newTeamId = body.newTeamId

        uiMgr:ShowInformationTips(__('队伍替换成功'))
        --有编辑界面的话
        if self.changeTeamLayer then
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
                -- logInfo.add(5, checkint(curTeamId) ~= checkint(newTeamId))
                if checkint(curTeamId) ~= checkint(newTeamId) then
                    self.changeTeamLayer:RefreshBattleScriptTypeUI({newTeamId = newTeamId})
                end
            end

            self.changeTeamLayer:ResetAllCardSelectState()
        end


    elseif name == SHOW_TAG_MATCH_EDIT_TEAM then
        if self:getAttackTeamId() > 0 then
            app.uiMgr:AddNewCommonTipDialog({
                text = __('使用预设编队不能进行单独修改，是否使用普通编队？'),
                callback = function()
                    self.toCleanTeamId_ = true
                    self:showEditTeamView(1)
                end
            })
        else
            local teamId = body.teamId or '1'
            self:showEditTeamView(teamId)
        end

    elseif name == CLOSE_CHANGE_TEAM_SCENE then
        self.changeTeamLayer = nil
    elseif name == COUNT_DOWN_ACTION then
        local timerName = tostring(body.timerName)
        if NAME == timerName then
            local countdown = checkint(body.countdown)
            self:GetViewComponent():updateCountDown(countdown)
            if countdown <= 0 then
                self.isTimeEnd = true
                -- self:closeView(__('时间已结束'))
            end
        end


    elseif name == SGL.PRESET_TEAM_SELECT_CARDS then
        local presetTeamData = checktable(body.presetTeamData)
        self:setAttackTeamId(presetTeamData.teamId)
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
        app:DispatchObservers(TAG_MATCH_CHANGE_ATTACK_TEAM_MEMBER_SIGNAL, {teamDatas = teamDatas})
    
    end
end 

-------------------------------------------------
-- get / set

function TagMatchLobbyMediator:getCtorArgs()
    return self.ctorArgs_
end

function TagMatchLobbyMediator:getViewData()
    return self.viewData_
end

function TagMatchLobbyMediator:getOwnerScene()
    return self.ownerScene_
end

function TagMatchLobbyMediator:getTeamDatas()
    return self.datas.teamInfo.cards or {}
end
function TagMatchLobbyMediator:setTeamDatas(teamId, teamData)
    self:getTeamDatas()[tostring(teamId)] = teamData
end


function TagMatchLobbyMediator:getAttackTeamId()
    return checkint(self.datas.teamCustomId)
end
function TagMatchLobbyMediator:setAttackTeamId(teamId)
    self.datas.teamCustomId = checkint(teamId)
end

-------------------------------------------------
-- public method
function TagMatchLobbyMediator:enterLayer()
    self:SendSignal(POST.TAG_MATCH_HOME.cmdName)
end

--[[
    请求设置战队团队数据
    @params teamDatas  所有的团队的数据
]]
function TagMatchLobbyMediator:requestSetAttackTeam(teamDatas)
    -- local isChange = self:checkTeamDataChange(teamId, teamData)
    -- if isChange then
    local cards = {}
    for i, v in pairs(teamDatas) do
        cards[tostring(i)] = self:convertTeamDataToStr(v)
    end

    self:SendSignal(POST.TAG_MATCH_SET_ATTACK_CARDS.cmdName, {cards = json.encode(cards), teamCustomId = self:getAttackTeamId()})
    -- end
end

--[[
    开启倒计时
    @params leftSeconds  剩余时间
]]
function TagMatchLobbyMediator:startCountDown(leftSeconds)
    leftSeconds = checkint(leftSeconds) + 2
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

--[[
    进入战斗
    @params _enemyData  对手战斗数据
    @params _teamsData  自定义编队数据
]]
function TagMatchLobbyMediator:enterBattle(_enemyData, _teamsData)
    if not self:checkShieldPoint() then
        uiMgr:ShowInformationTips(__('护盾值已用完, 不能再挑战其他御侍'))
        return
    end

    -- 保存进攻生命
    gameMgr:SetTagMatchSwordPoint(self.datas.swordPoint)

    -- 准备战斗数据
    local enemyData = _enemyData -- self.datas.enemyList[1 or self.curSelectOppoentIndex] or {}
    local teamsData = _teamsData

    local fixedTeamsData = nil
    if teamsData then
        local teamsDataMap = {}
        for teamIndex, cardInfoList in pairs(teamsData.info or {}) do
            for _, serverCardInfo in pairs(cardInfoList) do
                teamsDataMap[tostring(serverCardInfo.id)] = serverCardInfo
            end
        end

        fixedTeamsData = {}
        for teamId, teamData in pairs(self:getTeamDatas()) do
            local fixedTeamData = {}
            for cardIndex = 1, MAX_TEAM_MEMBER_AMOUNT do
                local cardData = {}
                local cardInfo = teamData[cardIndex]
                if nil ~= cardInfo and nil ~= cardInfo.id then
                    local playerCardUuId = checkint(cardInfo.id)
                    local serverCardInfo = teamsDataMap[tostring(playerCardUuId)]
                    if serverCardInfo ~= nil then
                        --- 把最新卡牌数据的 堕神和神器数据 替换为 预设编队中卡牌拥有的堕神和神器数据
                        cardData                = clone(gameMgr:GetCardDataById(playerCardUuId))
                        cardData.pets           = serverCardInfo.pets or {}
                        cardData.artifactTalent = serverCardInfo.artifactTalent or {}
                    end
                end
                fixedTeamData[cardIndex] = cardData
            end
            fixedTeamsData[checkint(teamId)] = fixedTeamData
        end

        -- logInfo.add(5, tableToString(fixedTeamsData, 'fixedTeamsData'))
    end
    
    -------------------------------------------------
    local friendTeams = {}
    for teamId, teamData in pairs(self:getTeamDatas()) do
        friendTeams[checkint(teamId)] = {}
        for i, v in ipairs(teamData) do
            table.insert(friendTeams[checkint(teamId)] , v.id)
        end
    end
    
    local enemyTeams = {}--friendTeams or {}
    local enemyPlayerCards = enemyData.enemyPlayerCards or {}
    for k, v in pairs(enemyPlayerCards) do
        enemyTeams[checkint(k)] = {}
        for ii, vv in pairs(v) do
            table.insert(enemyTeams[checkint(k)], vv)    
        end
    end

    local enemyPlayerSkill = enemyData.enemyPlayerSkill or {}

    local enemyPlayerId = enemyData.enemyPlayerId

    local teamCustomId = nil
    if self:getAttackTeamId() > 0 then
        teamCustomId = self:getAttackTeamId()
    end

    -- 可以进行战斗
	local serverCommand = BattleNetworkCommandStruct.New(
		POST.TAG_MATCH_QUEST_AT.cmdName,
		{enemyPlayerId = enemyPlayerId},
		POST.TAG_MATCH_QUEST_AT.sglName,
		POST.TAG_MATCH_QUEST_GRADE.cmdName,
		{enemyPlayerId = enemyPlayerId, teamCustomId = teamCustomId},
		POST.TAG_MATCH_QUEST_GRADE.sglName,
		nil,
		nil,
		nil
	)
    AppFacade.GetInstance():DispatchObservers("DOT_LOG_EVENT_SEND" , {eventId = "63-01"})
    AppFacade.GetInstance():DispatchObservers("DOT_SET_LOG_EVENT" , {eventId = "63-02"})
	local fromToStruct = BattleMediatorsConnectStruct.New(
		NAME,
		NAME
	)
    
	local battleConstructor = nil
    if fixedTeamsData then
        battleConstructor = require('battleEntry.BattleConstructorEx').new()
        battleConstructor:InitByCommonData(
            nil,                                -- 关卡 id
            QuestBattleType.TAG_MATCH_3V3,      -- 战斗类型
            ConfigBattleResultType.NO_DROP,     -- 结算类型
            ----
            battleConstructor:GetFormattedTeamsDataByTeamsCardData(fixedTeamsData), -- 友方阵容
            battleConstructor:GetFormattedTeamsDataByTeamsCardData(enemyTeams),     -- 敌方阵容
            ----
            nil,                                -- 友方携带的主角技
            app.gameMgr:GetUserInfo().allSkill, -- 友方所有主角技
            nil,                                -- 敌方携带的主角技
            enemyPlayerSkill,                   -- 敌方所有主角技
            ----
            nil,                                -- 全局buff
            nil,                                -- 卡牌能力增强信息
            ----
            nil,                                -- 已买活次数
            nil,                                -- 最大买活次数
            false,                              -- 是否开启买活
            ----
            nil,                                -- 随机种子
            false,                              -- 是否是战斗回放
            ----
            serverCommand,                      -- 与服务器交互的命令信息
            fromToStruct                        -- 跳转信息
        )
    else
        battleConstructor = require('battleEntry.BattleConstructor').new()
        battleConstructor:InitDataByTagMatchThreeTeams(
            friendTeams,                    -- 友方阵容
            enemyTeams,                     -- 敌方阵容
            gameMgr:GetUserInfo().allSkill, -- 友方主角技
            enemyPlayerSkill,               -- 敌方主角技
            serverCommand,                  -- 与服务器交互的命令信息
            fromToStruct                    -- 跳转信息
        )
    end

	if not AppFacade.GetInstance():RetrieveMediator('EnterBattleMediator') then
		local enterBattleMediator = require('Game.mediator.EnterBattleMediator').new()
		AppFacade.GetInstance():RegistMediator(enterBattleMediator)
	end
	GuideUtils.DispatchStepEvent()
	AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.Battle_Enter, battleConstructor)
end

--[[
    显示视图
]]
function TagMatchLobbyMediator:showView()
    self:startCountDown(self.datas.leftSeconds)
    -- 检查一遍 对手列表
    self:checkTeamCards()
    self:checkEnemyList()
    self:GetViewComponent():refreshUI(self.datas, self.teamId)
end

--[[
    显示单个队伍信息
    @params teamId  队伍id
]]
function TagMatchLobbyMediator:showSingleTeamInfo(sender, teamId)
    local teamData = self:getTeamDatas()[tostring(teamId)]
    
    local isCanShow = false
    if teamData and next(teamData) ~= nil then
        for k, v in pairs(teamData) do
            if v.id then
                isCanShow = true
                break
            end
        end
    else
        isCanShow = false
    end
    if not isCanShow then
        return
    end

    uiMgr:ShowInformationTipsBoard({
        targetNode = sender, 
        type = 12,
        bgSize = cc.size(540, 171),
        title = __('总灵力'),
        viewTypeData = {
            teamData = teamData,
            teamId = teamId,
            teamMarkPosSign = 1
        }
    })

end

function TagMatchLobbyMediator:hideSingleTeamInfo()
    self:getOwnerScene():RemoveDialogByTag(23456)
end

--[[
    显示编辑团队界面
    @params teamId  队伍id
]]
function TagMatchLobbyMediator:showEditTeamView(teamId)
    
    local oppoentData = self.datas.enemyList[self.curSelectOppoentIndex] or {}
    local oppoentTeamDatas = oppoentData.playerCards or {}
    
    -- logInfo.add(5, '----------------cccccccccccccccccc>>>>>>>>>>>>>')
    -- logInfo.add(5, tableToString(self:getTeamDatas()))
    -- logInfo.add(5, tableToString(oppoentTeamDatas))
    -- logInfo.add(5, '----------------cccccccccccccccccc>>>>>>>>>>>>> end')
    local layer = require('Game.views.tagMatch.TagMatchChangeTeamScene').new({
        teamId       = checkint(teamId) == 0 and '1' or tostring(teamId),
        teamDatas    = self:getTeamDatas(),
        teamTowards = -1,
        avatarTowards = -1,
        avatarShowType = 2,
        teamChangeSingalName = TAG_MATCH_CHANGE_ATTACK_TEAM_MEMBER_SIGNAL,
        battleTypeData = {
            isShowOppentTeam = next(oppoentTeamDatas) ~= nil,
            oppoentTeamDatas = oppoentTeamDatas,
            isAttack     = true,
        },
        battleType = BATTLE_SCRIPT_TYPE.TAG_MATCH
    })
    layer:setAnchorPoint(cc.p(0.5, 0.5))
    layer:setPosition(display.center)
    self:getOwnerScene():AddDialog(layer)  
    self.changeTeamLayer = layer 

end

--[[
    显示排行榜
]]
function TagMatchLobbyMediator:showRank()
    local mediator = require("Game.mediator.KofArenaRankMediator").new()
    self:GetFacade():RegistMediator(mediator)
end

--[[
    关闭当前界面
    @params tipText string 关闭界面提示文字
]]
function TagMatchLobbyMediator:closeView(tipText, isNotAddParams)
    if tipText then
        uiMgr:ShowInformationTips(tostring(tipText))
    end
    self:GetFacade():UnRegsitMediator(NAME)
    local ActivityMediator = self:GetFacade():RetrieveMediator('ActivityMediator')
    if not ActivityMediator then
        local params = {activityId = ACTIVITY_ID.TAG_MATCH}
        if isNotAddParams then
            params = nil
        end
        AppFacade.GetInstance():RetrieveMediator('Router'):Dispatch({name = "HomeMediator"}, { name = "ActivityMediator", params = params})
    end
end

-------------------------------------------------
-- private method

--[[
    对手信息适配器
    @params p_convertview  cell
    @params idx 
]]
function TagMatchLobbyMediator:onOppoentAdapter(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1

    if pCell == nil then
        pCell = self:GetViewComponent():CreateOppoentDescCell()
        display.commonUIParams(pCell.viewData.clickLayer, {cb = handler(self, self.onClickOpponentInfoAction)})
        -- pCell.viewData.playerHeadNode:setOnClickScriptHandler(handler(self, self.onClickOpponentHeadAction))
    end
     
    xTry(function()
       
        local viewData = pCell.viewData       
        local data = self.datas.enemyList[index] 
        self:GetViewComponent():updateOppoentDescCell(viewData, data)
        
        -- local selectFrame = viewData.selectFrame
        -- selectFrame:setVisible(index == self.curSelectOppoentIndex)

        local clickLayer  = viewData.clickLayer
        clickLayer:setTag(index)

        local playerHeadNode = viewData.playerHeadNode
        playerHeadNode:setTag(index)
	end,__G__TRACKBACK__)
    
    return pCell
end

-------------------------------------------------
-- check

--[[
    检查团队卡牌
]]
function TagMatchLobbyMediator:checkTeamCards()
    local teamCards = {}
    local serTeamCards = self:getTeamDatas()
    for teamId, cardIds in pairs(serTeamCards) do
        teamCards[tostring(teamId)] = {}
        for i, cardId in ipairs(cardIds) do
            if checkint(cardId) > 0 then
                teamCards[tostring(teamId)][i] = {id = cardId}
            end
        end
    end
    self.datas.teamInfo.cards = teamCards
    -- logInfo.add(5, tableToString(teamCards))
end

--[[
    检查对手卡牌

    @return isOwnEnemy 是否拥有对手
]]
function TagMatchLobbyMediator:checkEnemyList()
    local enemyList = {}
    local serEnemyList = self.datas.enemyList
    
    local emptyEnemyCount = 0

    for i = 1, MAX_ENEMY_COUNT do
        local enemy = serEnemyList[i]
        if enemy then
            local playerCards = enemy.playerCards
            if playerCards == nil then
                enemy = {}
                emptyEnemyCount = emptyEnemyCount + 1
            else
                local playerBattlePoint = 0
                for teamId, playerCard in pairs(playerCards) do
                    local battlePoint = 0
                    local cards = playerCard.cards or {}
                    for i, cardData in ipairs(cards) do
                        -- 计算战斗力
                        battlePoint = battlePoint + cardMgr.GetCardStaticBattlePointByCardData(cardData)
                    end
                    playerCard.battlePoint = battlePoint
                    playerBattlePoint = playerBattlePoint + battlePoint
                end
                enemy.playerBattlePoint = playerBattlePoint
            end
            
        else
            enemy = {}
            emptyEnemyCount = emptyEnemyCount + 1
        end
        table.insert(enemyList, enemy)
    end
    
    self.datas.enemyList = enemyList
    self.datas.isOwnEnemy = emptyEnemyCount ~= MAX_ENEMY_COUNT
end

--[[
    检查是否能进入战斗准备界面
]]
function TagMatchLobbyMediator:checkIsCanEnterBattlePrepare(teamDatas)
    
    local satisfyTeamConditionCount = 0
    for i = 1, 3 do
        local teamData = teamDatas[tostring(i)]
        if teamData == nil or next(teamData) == nil then return false end

        for i = 1, MAX_TEAM_MEMBER_AMOUNT do
            local cardData = teamData[i]
            if cardData and cardData.id then
                satisfyTeamConditionCount = satisfyTeamConditionCount + 1
                break
            end
        end
    end

    return satisfyTeamConditionCount >= 3
end

--[[
    检查团队是否改变
]]
function TagMatchLobbyMediator:checkTeamDataChange(teamDatas)
    local curTeamDatas = self:getTeamDatas()
    local isChange = false

    -- logInfo.add(5, tableToString(teamDatas))
    for teamId, teamData in pairs(teamDatas) do
        local curTeamData = curTeamDatas[tostring(teamId)] or {}

        for i, cardData in ipairs(teamData) do
            local curCurData = curTeamData[i] or {}
            local cardId = cardData.id
            local curCardId = curCurData.id

            if (cardId ~= nil and curCardId == nil) 
            or (cardId == nil and curCardId ~= nil)
            or (cardId ~= nil and curCardId ~= nil and checkint(cardId) ~= checkint(curCardId)) then
                return true
            end
        end

    end
    
    return isChange
end

--[[
    检查进攻生命值
]]
function TagMatchLobbyMediator:checkSwordPoint()
    return checkint(self.datas.swordPoint) > 0
end

--[[
    检查防守生命值
]]
function TagMatchLobbyMediator:checkShieldPoint()
    return checkint(self.datas.shieldPoint) > 0
end

-------------------------------------------------
-- handler

function TagMatchLobbyMediator:onCloseViewAction(sender)
    PlayAudioByClickClose()
    self:closeView()
end

function TagMatchLobbyMediator:onClickRuleAction(sender)
    PlayAudioByClickNormal()
    -- uiMgr:ShowIntroPopup({moduleId = MODULE_DATA[tostring(RemindTag.TAG_MATCH)]})
    uiMgr:ShowInformationTipsBoard({
        targetNode = sender, 
        type = 5,
        descr = __('每次演武初始护盾值为10, 每次防守失败都会扣除一个护盾值, 护盾值为0时不能继续参与演武内容。')
    })
end

function TagMatchLobbyMediator:onClickTitleRuleAction()
    PlayAudioByClickNormal()
    uiMgr:ShowIntroPopup({moduleId = MODULE_DATA[tostring(RemindTag.TAG_MATCH)]})
end

function TagMatchLobbyMediator:onBtnAction(sender)
    PlayAudioByClickNormal()
    self:hideSingleTeamInfo()
    if self.isTimeEnd then
        uiMgr:ShowInformationTips(__('时间已结束'))
        return
    end
    local tag = sender:getTag()
    if tag == BUTTON_TAG.SHIELD then
        local viewComponent = require("Game.views.tagMatch.TagMatchDefensiveLineupView").new({defenseTeams = gameMgr:GetTagMatchDefendData() or {}})
        viewComponent:setPosition(display.center)
        self:getOwnerScene():AddDialog(viewComponent)

    elseif tag == BUTTON_TAG.MODIFY then
        if self:getAttackTeamId() > 0 then
            app.uiMgr:AddNewCommonTipDialog({
                text = __('使用预设编队不能进行单独修改，是否使用普通编队？'),
                callback = function()
                    self.toCleanTeamId_ = true
                    self:showEditTeamView(self.teamId)
                end
            })
        else
            self:showEditTeamView(self.teamId)
        end

    elseif tag == BUTTON_TAG.FIGHT then

        if not self:checkSwordPoint() then
            uiMgr:ShowInformationTips(__('失败次数已达三次上限, 不能再挑战其他御侍'))
            return
        end
        if not self:checkShieldPoint() then
            uiMgr:ShowInformationTips(__('护盾值已用完, 不能再挑战其他御侍'))
            return
        end

        if self.curSelectOppoentIndex <= 0 then
            uiMgr:ShowInformationTips(__('请先选择挑战对手'))
            return
        end

        local enemyData = self.datas.enemyList[self.curSelectOppoentIndex] or {}
        if next(enemyData) == nil then
            uiMgr:ShowInformationTips(__('请选择正确的对手进行挑战'))
            return
        end
        
        local data = {
            playerAttackData  = self:getTeamDatas(),
            oppoentData = enemyData,
            attackTeamId = self:getAttackTeamId(),
        }
        local mediator = require("Game.mediator.tagMatch.TagMatchFightPrepareMediator").new(data)
        self:GetFacade():RegistMediator(mediator)
    elseif tag == BUTTON_TAG.REPORT then

        self:SendSignal(POST.TAG_MATCH_ARENA_RECORD.cmdName)

    elseif tag == BUTTON_TAG.REFRESH then
        local leftRefreshTimes = self.datas.leftRefreshTimes
        if leftRefreshTimes <= 0 then
            uiMgr:ShowInformationTips(__('本次演武更换次数已用完'))
            return
        end

        local commonTip = require('common.NewCommonTip').new({
			text = __('每次开启后更换次数有限, 确定要换一批?'),
			callback = function ()
                self:SendSignal(POST.TAG_MATCH_REFRESH_ENEMY.cmdName)
			end
		})
		commonTip:setPosition(display.center)
        self:getOwnerScene():AddDialog(commonTip)
    elseif tag == BUTTON_TAG.SHOP then
        if GAME_MODULE_OPEN.NEW_STORE then
            app.uiMgr:showGameStores({storeType = GAME_STORE_TYPE.GROCERY, subType = GAME_STORE_TYPE.KOF_ARENA})
        else
            app.router:Dispatch({name = "TagMatchLobbyMediator"}, {name = "ShopMediator",params = {goShopIndex = 'kofArena'}})
        end
    elseif tag == BUTTON_TAG.RANK then
    
        self:showRank()
        
    end
end

function TagMatchLobbyMediator:onClickPlayerTeamHeadBg(sender)
    local tag = checkint(sender:getTag())

    self:showSingleTeamInfo(sender, tag)

    if self.teamId == tag then return end
    -- uiMgr:ShowRewardInformationTips({targetNode = sender, type = 10})
    self:GetViewComponent():updateTeamHeadSelectState(self.teamId, false)
    self:GetViewComponent():updateTeamHeadSelectState(tag, true)
    self.teamId = tag
end


function TagMatchLobbyMediator:onClickOpponentInfoAction(sender)
    local tag = checkint(sender:getTag())
    if tag == self.curSelectOppoentIndex then
        return
    end

    local viewData = self:getViewData()
    local oldIndex = self.curSelectOppoentIndex
    self.curSelectOppoentIndex = tag
    self:updateSelectFrame(viewData, oldIndex)
    self:updateSelectFrame(viewData, tag)

end

--[[
    更新对手选中框
    @params viewData 对手cell所有视图数据
    @params index    cell index
    @params isSelect 是否选中 （可选）
]]
function TagMatchLobbyMediator:updateSelectFrame(viewData, index, isSelect)
    if checkint(index) <= 0 then return end

    local gridView = viewData.gridView
    local cell = gridView:cellAtIndex(index - 1)
    if cell then
        local cellViewData = cell.viewData
        local selectFrame = cellViewData.selectFrame

        local isSelectFrame = nil
        if isSelect ~= nil then
            isSelectFrame = isSelect
        else
            isSelectFrame = index == self.curSelectOppoentIndex
        end
        
        selectFrame:setVisible(isSelectFrame)
    end
end

function TagMatchLobbyMediator:convertTeamDataToStr(teamData)
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

function TagMatchLobbyMediator:convertTeamStrToData(teamStr)
    local teamArr = string.split(teamStr, ',')
    local teamData = {}
    for i, v in ipairs(teamArr) do
        local id = checkint(v)
        table.insert(teamData, id == 0 and {} or {id = id})
        
    end
    return teamData
end

return TagMatchLobbyMediator
