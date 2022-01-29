--[[
 * author : liuzhipeng
 * descpt : 活动 20春活 关卡选择Mediator
--]]
local SpringActivity20StageMediator = class('SpringActivity20StageMediator', mvc.Mediator)
local NAME = "springActivity20.SpringActivity20StageMediator"
local SPRING_ACTIVITY_20_STAGE_TEAM_CHANGE_NOTICE = 'SPRING_ACTIVITY_20_STAGE_TEAM_CHANGE_NOTICE'
local DIFFICULTY_TYPE = {
    EASY = 1,
    HARD = 2
}
local STAGE_LOCK_STATE = {
    LOCK = 1,
    UNLOCK = 2,
}
function SpringActivity20StageMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.stageData = {}
    self.difficulty = DIFFICULTY_TYPE.EASY -- 难度
    self.stageIndex = 1 -- 选中的关卡
end
-------------------------------------------------
------------------ inheritance ------------------
function SpringActivity20StageMediator:Initial( key )
    self.super.Initial(self, key)
    local viewComponent = app.uiMgr:SwitchToTargetScene('Game.views.springActivity20.SpringActivity20StageScene')
    self:SetViewComponent(viewComponent)
    local viewData = viewComponent:GetViewData()
    -- 绑定
    viewData.tabNameLabel:setOnClickScriptHandler(handler(self, self.TipsButtonCallback))
    viewData.backBtn:setOnClickScriptHandler(handler(self, self.BackButtonCallback))
    viewData.easyBtn:setOnClickScriptHandler(handler(self, self.DiffcultyButtonCallback))
    viewData.hardBtn:setOnClickScriptHandler(handler(self, self.DiffcultyButtonCallback))
    viewData.battleBtn:setOnClickScriptHandler(handler(self, self.BattleButtonCallback))
    viewData.sweepBtn:setOnClickScriptHandler(handler(self, self.SweepButtonCallback))
    viewData.buffBtn:setOnClickScriptHandler(handler(self, self.BuffButtonCallback))
	for i, v in ipairs(viewData.cardHeadBtnlist) do
		v:setOnClickScriptHandler(handler(self,self.CardHeadButtonCallback))
    end
    
    viewData.stageTableView:setCellInitHandler(handler(self, self.OnInitStageListCellHandler))
    viewData.stageTableView:setCellUpdateHandler(handler(self, self.OnUpdateStageListCellHandler))
    if self.payload then
        app.springActivity20Mgr:SetHomeData(self.payload)
    end
    self:InitStageData()
    self:InitSelectedStage()
    self:InitView()
end

function SpringActivity20StageMediator:InterestSignals()
    local signals = {
        POST.SPRING_ACTIVITY_20_SET_BOSS_TEAM.sglName, 
        SPRING_ACTIVITY_20_STAGE_TEAM_CHANGE_NOTICE,
        "QUEST_SWEEP_OVER",
    }
    return signals
end
function SpringActivity20StageMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.SPRING_ACTIVITY_20_SET_BOSS_TEAM.sglName then

    elseif name == SPRING_ACTIVITY_20_STAGE_TEAM_CHANGE_NOTICE then
        self:UpdateTeamData(body.teamData)
    elseif  name == 'QUEST_SWEEP_OVER' then -- 扫荡完成
        self:SweepOver(body)
    end
end

function SpringActivity20StageMediator:OnRegist()
    regPost(POST.SPRING_ACTIVITY_20_SET_BOSS_TEAM)
    regPost(POST.SPRING_ACTIVITY_20_SWEEP)
    regPost(POST.SPRING_ACTIVITY_20_UNLOCK_STORY)
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
    
end
function SpringActivity20StageMediator:OnUnRegist()
    unregPost(POST.SPRING_ACTIVITY_20_SET_BOSS_TEAM)
    unregPost(POST.SPRING_ACTIVITY_20_SWEEP)
    unregPost(POST.SPRING_ACTIVITY_20_UNLOCK_STORY)
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightShow")
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
--[[
提示按钮点击回调
--]]
function SpringActivity20StageMediator:TipsButtonCallback( sender )
    PlayAudioByClickNormal()
    app.uiMgr:ShowIntroPopup({moduleId = '-58'})
end
--[[
返回上层
--]]
function SpringActivity20StageMediator:BackButtonCallback( sender )
    PlayAudioByClickClose()
    app:RetrieveMediator("Router"):Dispatch({name = 'SpringActivity20StageMediator'}, {name = 'springActivity20.SpringActivity20HomeMediator'})
end
--[[
难度按钮点击回调
--]]
function SpringActivity20StageMediator:DiffcultyButtonCallback( sender )
    local diffculty = sender:getTag()
    if diffculty == self:GetDifficulty() then return end
    PlayAudioByClickNormal()
    if not self:CheckHardStageUnlock() then
        app.uiMgr:ShowInformationTips(app.springActivity20Mgr:GetPoText(__('通关普通难度解锁困难关卡')))
        return 
    end
    self:SetDifficulty(diffculty)
    self:SetStageIndex(1)
    self:RefreshStageList()
    self:RefreshStageInfo()
end
--[[
buff按钮点击回调
--]]
function SpringActivity20StageMediator:BuffButtonCallback( sender )
    PlayAudioByClickNormal()
    app.springActivity20Mgr:ShowBuffInformationBoard(sender)
end
--[[
战斗按钮点击回调
--]]
function SpringActivity20StageMediator:BattleButtonCallback( sender )
    PlayAudioByClickNormal()
    -- 判断队伍是否为空
	if next(app.springActivity20Mgr:GetActivityTeam()[1]) == nil then
		app.uiMgr:ShowInformationTips(app.springActivity20Mgr:GetPoText(__('队伍不能为空！')))
		return
    end
    local questConfig, exQuestConfig = self:GetQuestConfig()
    -- 判断挑战次数是否足够
    local leftChallengeTimes = self:GetLeftChallengeTimes()
    if leftChallengeTimes and leftChallengeTimes <= 0 then
        app.uiMgr:ShowInformationTips(app.springActivity20Mgr:GetPoText(__('挑战次数不足')))
        return 
    end
    -- 判断体力是否足够
    local hpGoodsId = app.springActivity20Mgr:GetHPGoodsId()
    if app.gameMgr:GetAmountByIdForce(hpGoodsId) < checkint(questConfig.consumeHpNum) then
        local goodsConf = CommonUtils.GetConfig('goods', 'goods', hpGoodsId)
        app.uiMgr:ShowInformationTips(string.fmt(app.springActivity20Mgr:GetPoText(__('_name_不足')), {['_name_'] = tostring(goodsConf.name)}))
        return 
    end
    -- 关卡信息
    local questId = checkint(questConfig.id)
    local questBattleType = CommonUtils.GetQuestBattleByQuestId(questId)

	-- 服务器参数
	local serverCommand = BattleNetworkCommandStruct.New(
			POST.SPRING_ACTIVITY_20_QUEST_AT.cmdName,
			{questId = checkint(questConfig.id)},
			POST.SPRING_ACTIVITY_20_QUEST_AT.sglName,
			POST.SPRING_ACTIVITY_20_QUEST_GUADE.cmdName,
			{questId = checkint(questConfig.id)},
			POST.SPRING_ACTIVITY_20_QUEST_GUADE.sglName,
			nil,
			nil,
			nil
	)
	local fromToStruct = BattleMediatorsConnectStruct.New(
			"springActivity20.SpringActivity20StageMediator",
			"springActivity20.SpringActivity20StageMediator"
    )

    -- 阵容信息
    local teamData = {}
    for i, v in ipairs(app.springActivity20Mgr:GetActivityTeam()[1]) do
        table.insert(teamData, v.id)
    end
	-- 创建战斗构造器
	local battleConstructor = require('battleEntry.BattleConstructorEx').new()

    -- 友方阵容
    local formattedFriendTeamData = battleConstructor:GetFormattedTeamsDataByTeamsMyCardData({[1] = teamData})
    -- 敌方阵容
	local formattedEnemyTeamData = battleConstructor:GetCommonEnemyTeamDataByStageId(questId)
    -- buff信息
    local globalBuff = app.springActivity20Mgr:GetGlobalBuff()
    local skills = battleConstructor:GetFormattedGlobalSkillsByBuffs({[1] = {buff = globalBuff.buffId, level = 1}})
    local skillData = GlobalEffectConstructStruct.New(
        globalBuff.buffId,
        globalBuff.skillId,
        1
    )
	battleConstructor:InitByCommonData(
		questId, questBattleType, ConfigBattleResultType.NONE_STAR,
		formattedFriendTeamData, formattedEnemyTeamData,
		nil, nil, nil, nil,
		{skillData}, nil,
		nil, nil, nil,
		nil, false,
		serverCommand, fromToStruct
    )
    app.springActivity20Mgr:CheckStoryIsUnlocked(exQuestConfig.story, function()
        battleConstructor:OpenBattle()
    end)
end
--[[
扫荡按钮点击回调
--]]
function SpringActivity20StageMediator:SweepButtonCallback( sender )
    PlayAudioByClickNormal()
    -- 判断扫荡功能是否开启
    local isPassed = self:GetStageIsPassed()
    if not isPassed then 
        app.uiMgr:ShowInformationTips(app.springActivity20Mgr:GetPoText(__("通关关卡才可开启快速挑战功能")))
        return
    end

    local questConfig = self:GetQuestConfig()
    local stageId = checkint(questConfig.id)
    local tag     = 4001
    local layer   = require('Game.views.SweepPopup').new({
        tag                 = tag,
        stageId             = stageId,
        canSweepCB          = handler(self, self.CanSweepCallback),
        sweepRequestCommand = POST.SPRING_ACTIVITY_20_SWEEP.cmdName,
        sweepResponseSignal = POST.SPRING_ACTIVITY_20_SWEEP.sglName
    })
    display.commonUIParams(layer, { ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5) })
    layer:setTag(tag)
    layer:setName('SweepPopup')
    app.uiMgr:GetCurrentScene():AddDialog(layer)
end
--[[
判断是否可以扫荡
--]]
function SpringActivity20StageMediator:CanSweepCallback( stageId, times )
    local consumeHp = tonumber(CommonUtils.GetQuestConf(checkint(stageId)).consumeHpNum)
    local hpGoodsId = app.springActivity20Mgr:GetHPGoodsId()
    local leftChallengeTimes = self:GetLeftChallengeTimes()
    if leftChallengeTimes and leftChallengeTimes < times then
        app.uiMgr:ShowInformationTips(app.springActivity20Mgr:GetPoText(__('挑战次数不足')))
        return false
    end
    if app.gameMgr:GetAmountByIdForce(hpGoodsId) >= consumeHp * times then
        return true
    else
        local goodsConf = CommonUtils.GetConfig('goods', 'goods', hpGoodsId)
        app.uiMgr:ShowInformationTips(string.fmt(app.springActivity20Mgr:GetPoText(__('_name_不足')), {['_name_'] = tostring(goodsConf.name)}))
    end
end
--[[
卡牌头像背景点击回调
--]]
function SpringActivity20StageMediator:CardHeadButtonCallback( sender )
    PlayAudioByClickNormal()
	local layer = require('Game.views.pvc.PVCChangeTeamScene').new({
        teamDatas = clone(app.springActivity20Mgr:GetActivityTeam()),
        title = app.springActivity20Mgr:GetPoText(__('编辑队伍')),
        teamTowards = -1,
        avatarTowards = 1,
        teamChangeSingalName = SPRING_ACTIVITY_20_STAGE_TEAM_CHANGE_NOTICE,
        limitCardsCareers =  {},
        limitCardsQualities =  {},
        isDisableHomeTopSignal = true,
        battleType  = 1
    })
    layer:setAnchorPoint(cc.p(0.5, 0.5))
    layer:setPosition(display.center)
    layer:setTag(4001)
	app.uiMgr:GetCurrentScene():AddDialog(layer)
	self:SetChangeTeamScene(layer)
end
--[[
列表cell初始化
--]]
function SpringActivity20StageMediator:OnInitStageListCellHandler( cellViewData )
    display.commonUIParams(cellViewData.btn, {cb = handler(self, self.OnClickStageListCellHandler)})
end
--[[
列表cell点击回调
--]]
function SpringActivity20StageMediator:OnClickStageListCellHandler( sender )
    PlayAudioByClickNormal()
    local index = sender:getTag()
    if index == self:GetStageIndex() then return end
    -- 判断解锁
    if not (self:GetStageLockState(self:GetDifficulty(), index) == STAGE_LOCK_STATE.UNLOCK) then 
        app.uiMgr:ShowInformationTips(app.springActivity20Mgr:GetPoText(__('请先通关前置关卡')))
        return 
    end
    self:SetStageIndex(index)
    local stageTableView = self:GetViewComponent():GetViewData().stageTableView
    local offset = stageTableView:getContentOffset()
    stageTableView:reloadData()
    stageTableView:setContentOffset(offset)
    self:RefreshStageInfo()
end
--[[
列表刷新处理
--]]
function SpringActivity20StageMediator:OnUpdateStageListCellHandler( cellIndex, cellViewData )
    cellViewData.btn:setTag(cellIndex)
    local viewComponent = self:GetViewComponent()
    local questConfig, exQuestConfig = self:GetQuestConfig(self:GetDifficulty(), cellIndex)
    local config = {
        name = questConfig.name,
        smallPic = exQuestConfig.smallPic,
    }
    local lockState = self:GetStageLockState(self:GetDifficulty(), cellIndex)
    local nextStageLockState = self:GetStageLockState(self:GetDifficulty(), cellIndex + 1)
    local stageNum = #self:GetStageData()[self:GetDifficulty()]
    viewComponent:RefreshStageCell(cellViewData, config, cellIndex == self:GetStageIndex(), cellIndex == stageNum, lockState, nextStageLockState)
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
初始化关卡数据
--]]
function SpringActivity20StageMediator:InitStageData()
    local stageConfig = CommonUtils.GetConfigAllMess('questCommon', 'springActivity2020')
    local passedQuestMap = app.springActivity20Mgr:GetPassedQuestMap()
    local stageData = {{},{}}
    for i, v in orderedPairs(stageConfig) do
        if checkint(v.questType) == DIFFICULTY_TYPE.EASY or checkint(v.questType) == DIFFICULTY_TYPE.HARD then
            table.insert(stageData[checkint(v.questType)], {
                questId = v.questId,
                isPassed = passedQuestMap[tostring(v.questId)] and true or false
            })
        end
    end
    self:SetStageData(stageData)
end
--[[
初始化选中关卡
--]]
function SpringActivity20StageMediator:InitSelectedStage()
    local stageData = self:GetStageData()
    if self:CheckHardStageUnlock() then
        self:SetDifficulty(DIFFICULTY_TYPE.HARD)
    else
        self:SetDifficulty(DIFFICULTY_TYPE.EASY)
    end
    local stage = nil
    for i, v in ipairs(stageData[self:GetDifficulty()]) do
        if self:GetStageLockState(self:GetDifficulty(), i) == STAGE_LOCK_STATE.LOCK then
            stage = i - 1
            break
        end
    end
    if stage then
        self:SetStageIndex(stage)
    else
        self:SetStageIndex(#stageData[self:GetDifficulty()])
    end
end
--[[
初始化view
--]]
function SpringActivity20StageMediator:InitView()
    -- 更新顶部货币栏
    self:InitMoneyBar()
    -- 刷新关卡列表
    self:RefreshStageList()
    -- 刷新关卡信息
    self:RefreshStageInfo()
    -- 刷新编队
    self:RefreshTeam()
    -- 刷新buff
    self:RefreshBuff()
end
--[[
初始化顶部货币栏
--]]
function SpringActivity20StageMediator:InitMoneyBar()
    local viewComponent = self:GetViewComponent()
    local hpGoodsId = app.springActivity20Mgr:GetHPGoodsId()
    local moneyIdMap = {hpGoodsId}
    viewComponent:InitMoneyBar(moneyIdMap)
end
--[[
刷新关卡列表
--]]
function SpringActivity20StageMediator:RefreshStageList()
    local viewComponent = self:GetViewComponent()
    local stageData = self:GetStageData()
    local difficulty = self:GetDifficulty()
    viewComponent:RefreshDifficulty(difficulty)
    viewComponent:RefreshStageList(#stageData[difficulty], self:GetStageIndex())
end
--[[
刷新关卡信息
--]]
function SpringActivity20StageMediator:RefreshStageInfo()
    local viewComponent = self:GetViewComponent()
    local questConfig, exQuestConfig = self:GetQuestConfig()
    local isPassed = self:GetStageIsPassed()
    local hardQuestUsed = app.springActivity20Mgr:GetHardQuestUsed()
    local leftChallengeTimes = nil
    if checkint(questConfig.challengeTime) ~= 0 then
        leftChallengeTimes = checkint(questConfig.challengeTime) - checkint(hardQuestUsed[tostring(questConfig.id)])
    end
    local config = {
        largePic           = exQuestConfig.largePic,
        word               = exQuestConfig.word,
        firstRewards       = questConfig.firstRewards,
        rewards            = questConfig.rewards,
        consumeHpNum       = questConfig.consumeHpNum,
        challengeTime      = questConfig.challengeTime,
        leftChallengeTimes = leftChallengeTimes,
        isPassed           = isPassed,
    }   
    viewComponent:RefreshStageInfo(config)
end 
--[[
更新编队信息
--]]
function SpringActivity20StageMediator:UpdateTeamData( teamData )
	if self:IsTeamDataValid(teamData) then
		-- 更新本地编队数据
        local temp = {}
        local teamStr = ''
        for i, v in ipairs(teamData) do
            if v.id then
                if teamStr == '' then
                    teamStr = teamStr .. v.id
                else
                    teamStr = teamStr .. ',' .. v.id
                end
                table.insert(temp, v)
            end
        end
        -- 更新本地数据
        app.springActivity20Mgr:SetActivityTeam({temp})
        -- 刷新编队
        self:RefreshTeam()
        -- 移除编队页面
        self:RemoveChangeTeamScene()
        -- 保存编队
        self:SendSignal(POST.SPRING_ACTIVITY_20_SET_BOSS_TEAM.cmdName, {teamCards = teamStr})
	else
		app.uiMgr:ShowInformationTips(app.springActivity20Mgr:GetPoText(__('编队不能为空')))
	end
end
--[[
判断编队信息是否合法
@teamData list 编队信息
@return valid bool 数据是否合法
--]]
function SpringActivity20StageMediator:IsTeamDataValid( teamData )
	local valid = false 
	for i, v in ipairs(checktable(teamData)) do
		if v.id or v.cardId then
			valid = true
			break
		end
	end
	return valid
end
--[[
移除编队页面
--]]
function SpringActivity20StageMediator:RemoveChangeTeamScene()
	local changeTeamScene = self:GetChangeTeamScene()
	if changeTeamScene and not tolua.isnull(changeTeamScene) then
		-- 移除编队界面
		changeTeamScene:runAction(cc.RemoveSelf:create()) 
		self.ChangeTeamScene = nil
	end
end
--[[
刷新编队
--]]
function SpringActivity20StageMediator:RefreshTeam()
    local viewComponent = self:GetViewComponent()
    local activityTeam = app.springActivity20Mgr:GetActivityTeam()
    viewComponent:RefreshTeam(activityTeam)
end
--[[
刷新buff
--]]
function SpringActivity20StageMediator:RefreshBuff()
    local viewComponent = self:GetViewComponent()
    local buff = app.springActivity20Mgr:GetGlobalBuff()
    viewComponent:RefreshBuff(buff)
end
--[[
扫荡结束处理
--]]
function SpringActivity20StageMediator:SweepOver( body )
    local data = body.responseData
    local questId      = checkint(data.requestData.questId)
    local consumeHp    = tonumber(CommonUtils.GetQuestConf(checkint(questId)).consumeHpNum)
    app.activityHpMgr:UpdateHp(app.springActivity20Mgr:GetHPGoodsId(), - consumeHp * data.requestData.times)
    local questConfig = CommonUtils.GetConfig('springActivity2020', 'quest', questId)
    if checkint(questConfig.challengeTime) > 0 then
        local hardQuestUsed = app.springActivity20Mgr:GetHardQuestUsed()
        hardQuestUsed[tostring(questId)] = checkint(hardQuestUsed[tostring(questId)]) + data.requestData.times
    end
    self:RefreshStageInfo()
end
--[[
检测困难模式是否解锁
@return isUnlock bool 困难难度是否解锁
--]]
function SpringActivity20StageMediator:CheckHardStageUnlock()
    local stageData = self:GetStageData()
    return self.stageData[DIFFICULTY_TYPE.EASY][#self.stageData[DIFFICULTY_TYPE.EASY]].isPassed
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
设置关卡数据
--]]
function SpringActivity20StageMediator:SetStageData( stageData )
    self.stageData = stageData
end
--[[
获取关卡数据
--]]
function SpringActivity20StageMediator:GetStageData()
    return self.stageData
end
--[[
设置难度
@params difficulty int 当前难度
--]]
function SpringActivity20StageMediator:SetDifficulty( difficulty )
    self.difficulty = checkint(difficulty or 1)
end
--[[
获取难度
@return difficulty int 当前难度
--]]
function SpringActivity20StageMediator:GetDifficulty()
    return self.difficulty
end
--[[
设置选中的关卡
@params stageIndex int 当前选中的关卡
--]]
function SpringActivity20StageMediator:SetStageIndex( stageIndex )
    self.stageIndex = checkint(stageIndex or 1)
end
--[[
获取选中的关卡
@return stageIndex int 当前选中的关卡
--]]
function SpringActivity20StageMediator:GetStageIndex()
    return self.stageIndex
end
--[[
获取关卡配置
@params difficulty    int 难度
@params stageIndex    int 关卡index
@return questConfig   map 关卡配置
@return exQuestConfig map 额外关卡配置
--]]
function SpringActivity20StageMediator:GetQuestConfig( difficulty, stageIndex )
    local difficulty_ = checkint(difficulty or self:GetDifficulty())
    local stageIndex_ = checkint(stageIndex or self:GetStageIndex())
    local stageData = self:GetStageData()
    local questId = stageData[difficulty_][stageIndex_].questId
    local questConfig = CommonUtils.GetConfig('springActivity2020', 'quest', questId)
    local exQuestConfig = CommonUtils.GetConfig('springActivity2020', 'questCommon', questId)
    return questConfig, exQuestConfig
end
--[[
获取关卡锁定状态
@params difficulty  int 难度
@params stageIndex  int 关卡index
@return STAGE_LOCK_STATE int 关卡锁定状态
--]]
function SpringActivity20StageMediator:GetStageLockState( difficulty, stageIndex )
    local difficulty_ = checkint(difficulty or self:GetDifficulty())
    local stageIndex_ = checkint(stageIndex or self:GetStageIndex())
    local stageData = self:GetStageData()
    -- 第一关默认解锁
    if stageIndex_ == 1 then return STAGE_LOCK_STATE.UNLOCK end

    if self:GetStageIsPassed(difficulty_, stageIndex_) or self:GetStageIsPassed(difficulty_, stageIndex_ - 1) then
        return STAGE_LOCK_STATE.UNLOCK
    else
        return STAGE_LOCK_STATE.LOCK
    end
end
--[[
获取关卡是否解锁
@params difficulty int  难度
@params stageIndex int  关卡index
@return isPassed   bool 是否通过
--]]
function SpringActivity20StageMediator:GetStageIsPassed( difficulty, stageIndex )
    local difficulty_ = checkint(difficulty or self:GetDifficulty())
    local stageIndex_ = checkint(stageIndex or self:GetStageIndex())
    local stageData = self:GetStageData()

    if stageData[difficulty_] and stageData[difficulty_][stageIndex_] then
        return stageData[difficulty_][stageIndex_].isPassed
    end
end
--[[
设置编队页面
--]]
function SpringActivity20StageMediator:SetChangeTeamScene( ChangeTeamScene )
	self.ChangeTeamScene = ChangeTeamScene
end
--[[
获取编队页面
--]]
function SpringActivity20StageMediator:GetChangeTeamScene( )
	return self.ChangeTeamScene
end
--[[
获取当前选中关卡的剩余挑战次数
--]]
function SpringActivity20StageMediator:GetLeftChallengeTimes()
    local questConfig, exQuestConfig = self:GetQuestConfig()
    if checkint(questConfig.challengeTime) ~= 0 then
        local hardQuestUsed = app.springActivity20Mgr:GetHardQuestUsed()
        local leftChallengeTimes = checkint(questConfig.challengeTime) - checkint(hardQuestUsed[tostring(questConfig.id)])
        return leftChallengeTimes
    else
        return
    end
end
------------------- get / set -------------------
-------------------------------------------------
return SpringActivity20StageMediator
