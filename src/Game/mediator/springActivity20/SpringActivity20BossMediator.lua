--[[
 * author : liuzhipeng
 * descpt : 活动 20春活 Boss选择Mediator
--]]
local SpringActivity20BossMediator = class('SpringActivity20BossMediator', mvc.Mediator)
local NAME = "springActivity20.SpringActivity20BossMediator"
local SPRING_ACTIVITY_20_BOSS_TEAM_CHANGE_NOTICE = 'SPRING_ACTIVITY_20_BOSS_TEAM_CHANGE_NOTICE'
local SPRING_ACTIVITY_20_SP_BOSS_TEAM_CHANGE_NOTICE = 'SPRING_ACTIVITY_20_SP_BOSS_TEAM_CHANGE_NOTICE'

local STAGE_LOCK_STATE = {
    LOCK = 1,
    UNLOCK = 2,
}

function SpringActivity20BossMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.bossData = {} -- boss数据
    self.difficulty = 1 -- 难度
    self.stageIndex = 1 -- 选中的关卡
    self.spBossAppear = checktable(params.requestData).spBossAppear == 1 and true or false -- 是否显示特殊boss出场动画
    self.spBattleBack = checktable(params.requestData).spBattleBack == 1 and true or false -- 是否为特殊boss战斗返回
    self.isSpBossPassed = checktable(params.requestData).isSpBossPassed == 1 and true or false -- 特殊boss是否通过
end
-------------------------------------------------
------------------ inheritance ------------------
function SpringActivity20BossMediator:Initial( key )
    self.super.Initial(self, key)
    local viewComponent = app.uiMgr:SwitchToTargetScene('Game.views.springActivity20.SpringActivity20BossScene')
    self:SetViewComponent(viewComponent)
    local viewData = viewComponent:GetViewData()
    -- 绑定
    viewData.tabNameLabel:setOnClickScriptHandler(handler(self, self.TipsButtonCallback))
    viewData.backBtn:setOnClickScriptHandler(handler(self, self.BackButtonCallback))
    viewData.battleBtn:setOnClickScriptHandler(handler(self, self.BattleButtonCallback))
    viewData.bossDetailBtn:setOnClickScriptHandler(handler(self, self.BossDetailButtonCallback))
    viewData.spBossBtn:setOnClickScriptHandler(handler(self, self.SpBossButtonCallback))
    viewData.buffBtn:setOnClickScriptHandler(handler(self, self.BuffButtonCallback))

	for i, v in ipairs(viewData.cardHeadBtnlist) do
		v:setOnClickScriptHandler(handler(self,self.CardHeadButtonCallback))
    end
    if self.payload then
        app.springActivity20Mgr:SetHomeData(self.payload)
    end
    -- 初始化boss数据
    self:InitBossData()
    -- 初始化boss选择
    self:InitSelectedBoss()
    -- 初始化页面
    if self.isSpBossPassed then
        local paramConfig = CommonUtils.GetConfigAllMess('param', 'springActivity2020')
        app.springActivity20Mgr:CheckStoryIsUnlocked(paramConfig.endStory, function()
            self:InitView()
        end)
    else
        self:InitView()
    end
end

function SpringActivity20BossMediator:InterestSignals()
    local signals = {
        POST.SPRING_ACTIVITY_20_SET_BOSS_TEAM.sglName, 
        SPRING_ACTIVITY_20_BOSS_TEAM_CHANGE_NOTICE,
        SPRING_ACTIVITY_20_SP_BOSS_TEAM_CHANGE_NOTICE,
        'SPRING_ACTIVITY_20_CATCH_SP_BOSS'
    }
    return signals
end
function SpringActivity20BossMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.SPRING_ACTIVITY_20_SET_BOSS_TEAM.sglName then
    elseif name == SPRING_ACTIVITY_20_BOSS_TEAM_CHANGE_NOTICE then
        self:UpdateTeamData(body.teamData)
    elseif name == SPRING_ACTIVITY_20_SP_BOSS_TEAM_CHANGE_NOTICE then
        self:UpdateTeamDataBySpBoss(body.teamData)
    elseif name == 'SPRING_ACTIVITY_20_CATCH_SP_BOSS' then
        -- 特殊boss被捕捉
        self:CatchSpBoss()
    end
end

function SpringActivity20BossMediator:OnRegist()
    regPost(POST.SPRING_ACTIVITY_20_SET_BOSS_TEAM)
    regPost(POST.SPRING_ACTIVITY_20_UNLOCK_STORY)
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
    
end
function SpringActivity20BossMediator:OnUnRegist()
    unregPost(POST.SPRING_ACTIVITY_20_SET_BOSS_TEAM)
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
function SpringActivity20BossMediator:TipsButtonCallback( sender )
    PlayAudioByClickNormal()
    app.uiMgr:ShowIntroPopup({moduleId = '-59'})
end
--[[
返回上层
--]]
function SpringActivity20BossMediator:BackButtonCallback( sender )
    PlayAudioByClickClose()
    app:RetrieveMediator("Router"):Dispatch({name = 'SpringActivity20BossMediator'}, {name = 'springActivity20.SpringActivity20HomeMediator'})
end
--[[
卡牌头像背景点击回调
--]]
function SpringActivity20BossMediator:CardHeadButtonCallback( sender )
    PlayAudioByClickNormal()
	local layer = require('Game.views.pvc.PVCChangeTeamScene').new({
        teamDatas = clone(app.springActivity20Mgr:GetActivityTeam()),
        title = app.springActivity20Mgr:GetPoText(__('编辑队伍')),
        teamTowards = -1,
        avatarTowards = 1,
        teamChangeSingalName = SPRING_ACTIVITY_20_BOSS_TEAM_CHANGE_NOTICE,
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
战斗按钮点击回调
--]]
function SpringActivity20BossMediator:BattleButtonCallback( sender )
    PlayAudioByClickNormal()
    -- 判断队伍是否为空
	if next(app.springActivity20Mgr:GetActivityTeam()[1]) == nil then
		app.uiMgr:ShowInformationTips(app.springActivity20Mgr:GetPoText(__('队伍不能为空！')))
		return
    end
    -- 关卡信息
    local bossData = self:GetBossData()
    local difficulty = self:GetDifficulty()
    local stageIndex = self:GetStageIndex()
    local bossStageData = bossData[difficulty].stages[stageIndex]
    local questConfig = CommonUtils.GetConfig('springActivity2020', 'quest', bossStageData.questId)
    local questId = checkint(questConfig.id)
    local questBattleType = CommonUtils.GetQuestBattleByQuestId(questId)
    -- 判断道具是否足够
    if app.gameMgr:GetAmountByIdForce(questConfig.consumeGoodsId) < checkint(questConfig.consumeGoodsNum) then
        local goodsConf = CommonUtils.GetConfig('goods', 'goods', questConfig.consumeGoodsId)
        app.uiMgr:ShowInformationTips(string.fmt(app.springActivity20Mgr:GetPoText(__('_name_不足')), {['_name_'] = tostring(goodsConf.name)}))
        return 
    end
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
			"springActivity20.SpringActivity20BossMediator",
			"springActivity20.SpringActivity20BossMediator"
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
    if checkint(bossStageData.story) ~= 0 then
        app.springActivity20Mgr:CheckStoryIsUnlocked(bossStageData.story, function()
            battleConstructor:OpenBattle()
        end)
    else
        battleConstructor:OpenBattle()
    end
end
--[[
boss详情按钮点击回调
--]]
function SpringActivity20BossMediator:BossDetailButtonCallback( sender )
    PlayAudioByClickNormal()
    local bossData = self:GetBossData()
    local difficulty = self:GetDifficulty()
    local stageIndex = self:GetStageIndex()
	AppFacade.GetInstance():RegistMediator(
		require('Game.mediator.BossDetailMediator').new({questId = bossData[difficulty].stages[stageIndex].questId})
	)
end
--[[
spBoss按钮点击回调
--]]
function SpringActivity20BossMediator:SpBossButtonCallback( sender )
    PlayAudioByClickNormal()
    if app.springActivity20Mgr:GetSpBoss() then
        -- 存在特殊boss
        local spBossMediator = require('Game.mediator.springActivity20.SpringActivity20SpBossMediator').new()
        app:RegistMediator(spBossMediator)
    else
        -- 不存在特殊boss
        app.uiMgr:ShowInformationTips(app.springActivity20Mgr:GetPoText(__('三炙鸟还没出现')))
    end
end
--[[
buff按钮点击回调
--]]
function SpringActivity20BossMediator:BuffButtonCallback( sender )
    PlayAudioByClickNormal()
    app.springActivity20Mgr:ShowBuffInformationBoard(sender)
end
--[[
难度按钮点击回调
--]]
function SpringActivity20BossMediator:DifficultyButtonCallback( sender )
    local difficulty = sender:getTag()
    local bossData = self:GetBossData()
    if difficulty == self:GetDifficulty() then return end
    PlayAudioByClickNormal()
    if bossData[difficulty].stages[1].lockState == STAGE_LOCK_STATE.LOCK then
        app.uiMgr:ShowInformationTips(app.springActivity20Mgr:GetPoText(__('请先通关前置难度')))
        return
    end
    self:SetDifficulty(difficulty)
    self:SetStageIndex(1)
    self:RefreshBossList()
end
--[[
关卡点击回调
--]]
function SpringActivity20BossMediator:StageButtonCallback( sender )
    local index = sender:getTag()
    local bossData = self:GetBossData()
    if index == self:GetStageIndex() then return end
    PlayAudioByClickNormal()
    if bossData[self:GetDifficulty()].stages[index].lockState == STAGE_LOCK_STATE.LOCK then
        app.uiMgr:ShowInformationTips(app.springActivity20Mgr:GetPoText(__('请先通关前置关卡')))
        return 
    end
    self:SetStageIndex(index)
    self:RefreshBossList()
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
初始化boss数据
--]]
function SpringActivity20BossMediator:InitBossData()
    local bossInfoConfig = CommonUtils.GetConfigAllMess('questBossInfo', 'springActivity2020')
    local questBossConfig = CommonUtils.GetConfigAllMess('questBoss', 'springActivity2020')
    local passedQuestMap = app.springActivity20Mgr:GetPassedQuestMap()
    local bossData = {}
    for i, v in orderedPairs(bossInfoConfig) do
        table.insert(bossData, clone(v))
        bossData[#bossData].stages = {}
    end
    for _, bossConfig in orderedPairs(questBossConfig) do
        for _, data in ipairs(bossData) do
            if checkint(data.questType) == checkint(bossConfig.questType) then
                local stageData = clone(bossConfig)
                stageData.isPassed = passedQuestMap[tostring(bossConfig.questId)] and true or false
                table.insert(data.stages, stageData)
                break
            end
        end
    end
    self:SetBossData(bossData)
    self:InitStageLockState()
end
--[[
初始化关卡锁定状态
--]]
function SpringActivity20BossMediator:InitStageLockState()
    local bossData = self:GetBossData()
    for difficulty, data in ipairs(bossData) do
        for stageIndex, stageData in ipairs(data.stages) do
            stageData.lockState = self:GetStageLockState(difficulty, stageIndex)
        end
    end
end
--[[
初始化选中关卡
--]]
function SpringActivity20BossMediator:InitSelectedBoss()
    local bossData = self:GetBossData()
    local selectedDifficulty = nil
    local selectedStageIndex = nil
    for difficulty, data in ipairs(bossData) do
        for index, stage in ipairs(data.stages) do
            if checkint(stage.lockState) == STAGE_LOCK_STATE.LOCK then
                if index == 1 then
                    selectedDifficulty = difficulty - 1
                    selectedStageIndex = #bossData[selectedDifficulty].stages
                else
                    selectedDifficulty = difficulty
                    selectedStageIndex = index - 1
                end
                break
            end
        end
        if selectedDifficulty and selectedStageIndex then
            break
        end
        if difficulty == #bossData then
            selectedDifficulty = #bossData
            selectedStageIndex = #bossData[selectedDifficulty].stages
        end
    end
    if selectedDifficulty and selectedStageIndex then    
        self:SetDifficulty(selectedDifficulty)
        self:SetStageIndex(selectedStageIndex)
    end
end
--[[
初始化view
--]]
function SpringActivity20BossMediator:InitView()
    -- 更新顶部货币栏
    self:InitMoneyBar()
    -- 刷新编队
    self:RefreshTeam()
    -- 刷新boss列表
    self:RefreshBossList()
    -- 刷新特殊boss
    self:RefreshSpBoss()
    -- 刷新buff
    self:RefreshBuff()
    -- 检测是否显示特殊boss页面
    self:CheckShowSpBossView()
end
--[[
初始化顶部货币栏
--]]
function SpringActivity20BossMediator:InitMoneyBar()
    local viewComponent = self:GetViewComponent()
    local hpGoodsId = app.springActivity20Mgr:GetHPGoodsId()
    local bossData = self:GetBossData()
    local questId = bossData[1].stages[1].questId
    local questConfig = CommonUtils.GetConfig('springActivity2020', 'quest', questId)
    local consumeGoodsId = questConfig.consumeGoodsId
    local moneyIdMap = {consumeGoodsId}
    viewComponent:InitMoneyBar(moneyIdMap)
end
--[[
更新编队信息
--]]
function SpringActivity20BossMediator:UpdateTeamData( teamData )
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
特殊boss页面编队替换时更新页面
--]]
function SpringActivity20BossMediator:UpdateTeamDataBySpBoss( teamData )
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
        -- 刷新编队
        self:RefreshTeam()
    end
end
--[[
判断编队信息是否合法
@teamData list 编队信息
@return valid bool 数据是否合法
--]]
function SpringActivity20BossMediator:IsTeamDataValid( teamData )
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
function SpringActivity20BossMediator:RemoveChangeTeamScene()
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
function SpringActivity20BossMediator:RefreshTeam()
    local viewComponent = self:GetViewComponent()
    local activityTeam = app.springActivity20Mgr:GetActivityTeam()
    viewComponent:RefreshTeam(activityTeam)
end
--[[
刷新特殊boss
--]]
function SpringActivity20BossMediator:RefreshSpBoss()
    local viewComponent = self:GetViewComponent()
    viewComponent:RefreshSpBoss(
        app.springActivity20Mgr:GetSpBoss(),
        app.springActivity20Mgr:GetSpBossAppearNeedTimes(),
        self.spBossAppear,
        self.isSpBossPassed
    )
end
--[[
刷新boss列表
--]]
function SpringActivity20BossMediator:RefreshBossList()
    local viewComponent = self:GetViewComponent()
    local params = {
        bossData = self:GetBossData(),
        difficulty = self:GetDifficulty(),
        stageIndex = self:GetStageIndex(),
        difficultyCb = handler(self, self.DifficultyButtonCallback),
        stageCb = handler(self, self.StageButtonCallback),
    }
    viewComponent:RefreshBossList(params)
    self:RefreshStageInfo()
end
--[[
刷新boss信息
--]]
function SpringActivity20BossMediator:RefreshStageInfo()
    local viewComponent = self:GetViewComponent()
    local bossData = self:GetBossData()
    local difficulty = self:GetDifficulty()
    local stageIndex = self:GetStageIndex()
    local params = {
        data = bossData[difficulty],
        stageIndex = stageIndex,
        difficulty = difficulty,
    }
    viewComponent:RefreshStageInfo(params)
end
--[[
刷新buff
--]]
function SpringActivity20BossMediator:RefreshBuff()
    local viewComponent = self:GetViewComponent()
    local buff = app.springActivity20Mgr:GetGlobalBuff()
    viewComponent:RefreshBuff(buff)
end
--[[
检测是否显示特殊boss页面
--]]
function SpringActivity20BossMediator:CheckShowSpBossView()
    if self.spBattleBack then
        local spBossMediator = require('Game.mediator.springActivity20.SpringActivity20SpBossMediator').new({isSpBossPassed = self.isSpBossPassed})
        app:RegistMediator(spBossMediator)
    end
end
--[[
捕捉特殊boss
--]]
function SpringActivity20BossMediator:CatchSpBoss()
    local viewComponent = self:GetViewComponent()
    viewComponent:CatchSpBoss()
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
设置boss数据
--]]
function SpringActivity20BossMediator:SetBossData( bossData )
    self.bossData = bossData
end
--[[
获取boss数据
--]]
function SpringActivity20BossMediator:GetBossData()
    return self.bossData
end
--[[
设置难度
@params difficulty int 当前难度
--]]
function SpringActivity20BossMediator:SetDifficulty( difficulty )
    self.difficulty = checkint(difficulty or 1)
end
--[[
获取难度
@return difficulty int 当前难度
--]]
function SpringActivity20BossMediator:GetDifficulty()
    return self.difficulty
end
--[[
设置选中的关卡
@params stageIndex int 当前选中的关卡
--]]
function SpringActivity20BossMediator:SetStageIndex( stageIndex )
    self.stageIndex = checkint(stageIndex or 1)
end
--[[
获取选中的关卡
@return stageIndex int 当前选中的关卡
--]]
function SpringActivity20BossMediator:GetStageIndex()
    return self.stageIndex
end
--[[
获取关卡锁定状态
@params difficulty  int 难度
@params stageIndex  int 关卡index
@return STAGE_LOCK_STATE int 关卡锁定状态
--]]
function SpringActivity20BossMediator:GetStageLockState( difficulty, stageIndex )
    local difficulty_ = checkint(difficulty or self:GetDifficulty())
    local stageIndex_ = checkint(stageIndex or self:GetStageIndex())
    local bossData = self:GetBossData()
    if stageIndex_ == 1 then 
        if difficulty_ == 1 then
            -- 第一关默认解锁
            return STAGE_LOCK_STATE.UNLOCK 
        else
            -- 判断上一难度是否通关
            if self:GetStageIsPassed(difficulty_ - 1, #bossData[difficulty_ - 1].stages) then
                return STAGE_LOCK_STATE.UNLOCK 
            else
                return STAGE_LOCK_STATE.LOCK 
            end
        end
    end
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
function SpringActivity20BossMediator:GetStageIsPassed( difficulty, stageIndex )
    local difficulty_ = checkint(difficulty or self:GetDifficulty())
    local stageIndex_ = checkint(stageIndex or self:GetStageIndex())
    local bossData = self:GetBossData()

    if bossData[difficulty_] and bossData[difficulty_].stages[stageIndex_] then
        return bossData[difficulty_].stages[stageIndex_].isPassed
    end
end
--[[
设置编队页面
--]]
function SpringActivity20BossMediator:SetChangeTeamScene( ChangeTeamScene )
	self.ChangeTeamScene = ChangeTeamScene
end
--[[
获取编队页面
--]]
function SpringActivity20BossMediator:GetChangeTeamScene( )
	return self.ChangeTeamScene
end
------------------- get / set -------------------
-------------------------------------------------
return SpringActivity20BossMediator
