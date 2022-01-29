--[[
 * author : liuzhipeng
 * descpt : 活动 20春活 特殊boss Mediator
--]]
local SpringActivity20SpBossMediator = class('SpringActivity20SpBossMediator', mvc.Mediator)
local NAME = "springActivity20.SpringActivity20SpBossMediator"
local SPRING_ACTIVITY_20_SP_BOSS_TEAM_CHANGE_NOTICE = 'SPRING_ACTIVITY_20_SP_BOSS_TEAM_CHANGE_NOTICE'
function SpringActivity20SpBossMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.isSpBossPassed = checktable(params).isSpBossPassed
end
-------------------------------------------------
------------------ inheritance ------------------
function SpringActivity20SpBossMediator:Initial( key )
    self.super.Initial(self, key)
    local viewComponent = require('Game.views.springActivity20.SpringActivity20SpBossView').new()
	self:SetViewComponent(viewComponent)
    local viewData = viewComponent:GetViewData()
    viewComponent:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(viewComponent)

    -- 绑定
    viewData.backBtn:setOnClickScriptHandler(handler(self, self.BackButtonCallback))
    viewData.battleBtn:setOnClickScriptHandler(handler(self, self.BattleButtonCallback))
    viewData.bossDetailBtn:setOnClickScriptHandler(handler(self, self.BossDetailButtonCallback))
    viewData.buffBtn:setOnClickScriptHandler(handler(self, self.BuffButtonCallback))

	for i, v in ipairs(viewData.cardHeadBtnlist) do
		v:setOnClickScriptHandler(handler(self,self.CardHeadButtonCallback))
    end
    -- 初始化页面
    self:InitView()
end

function SpringActivity20SpBossMediator:InterestSignals()
    local signals = {
        POST.SPRING_ACTIVITY_20_SET_BOSS_TEAM.sglName, 
        SPRING_ACTIVITY_20_SP_BOSS_TEAM_CHANGE_NOTICE,
    }
    return signals
end
function SpringActivity20SpBossMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.SPRING_ACTIVITY_20_SET_BOSS_TEAM.sglName then
    elseif name == SPRING_ACTIVITY_20_SP_BOSS_TEAM_CHANGE_NOTICE then
        self:UpdateTeamData(body.teamData)
    end
end

function SpringActivity20SpBossMediator:OnRegist()

end
function SpringActivity20SpBossMediator:OnUnRegist()
    -- 移除界面
	local scene = app.uiMgr:GetCurrentScene()
	scene:RemoveDialog(self:GetViewComponent())
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
--[[
关闭按钮点击回调
--]]
function SpringActivity20SpBossMediator:BackButtonCallback( sender )
	PlayAudioByClickClose()
	app:UnRegsitMediator(NAME)
end
--[[
战斗按钮点击回调
--]]
function SpringActivity20SpBossMediator:BattleButtonCallback( sender )
    PlayAudioByClickNormal()
	if next(app.springActivity20Mgr:GetActivityTeam()[1]) == nil then
		app.uiMgr:ShowInformationTips(app.springActivity20Mgr:GetPoText(__('队伍不能为空！')))
		return
    end
    local spBossData = self:GetSpBossData()
    local questId = checkint(spBossData.spQuestId)
    local questBattleType = CommonUtils.GetQuestBattleByQuestId(questId)
	-- 服务器参数
	local serverCommand = BattleNetworkCommandStruct.New(
			POST.SPRING_ACTIVITY_20_QUEST_AT.cmdName,
			{questId = questId},
			POST.SPRING_ACTIVITY_20_QUEST_AT.sglName,
			POST.SPRING_ACTIVITY_20_QUEST_GUADE.cmdName,
			{questId = questId},
			POST.SPRING_ACTIVITY_20_QUEST_GUADE.sglName,
			nil,
			nil,
			nil
	)
	local fromToStruct = BattleMediatorsConnectStruct.New(
			"springActivity20.SpringActivity20SpBossMediator",
			"springActivity20.SpringActivity20SpBossMediator"
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
    ------------ 初始化怪物血量参数 这里写死一波一个怪 ------------
	local monsterAttrData = {
		['1'] = {
			[1] = {
				[CardUtils.PROPERTY_TYPE.HP] = {percent = 1, value = checknumber(spBossData.hp)}
			}
		}
	}
    ------------ 初始化怪物血量参数 这里写死一波一个怪 ------------
	--- 敌方阵容
	local formattedEnemyTeamData = battleConstructor:ExConvertEnemyFormationData(
        questId, questBattleType, {
				monsterIntensityData = nil, monsterAttrData = monsterAttrData
    })
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
    battleConstructor:OpenBattle()
end
--[[
boss详情点击回调
--]]
function SpringActivity20SpBossMediator:BossDetailButtonCallback( sender )
    PlayAudioByClickNormal()
    local spBossData = self:GetSpBossData()
	AppFacade.GetInstance():RegistMediator(
		require('Game.mediator.BossDetailMediator').new({questId = spBossData.spQuestId})
	)
end
--[[
boss详情点击回调
--]]
function SpringActivity20SpBossMediator:BuffButtonCallback( sender )
    PlayAudioByClickNormal()
    app.springActivity20Mgr:ShowBuffInformationBoard(sender)
end
--[[
卡牌头像背景点击回调
--]]
function SpringActivity20SpBossMediator:CardHeadButtonCallback( sender )
    PlayAudioByClickNormal()
	local layer = require('Game.views.pvc.PVCChangeTeamScene').new({
        teamDatas = clone(app.springActivity20Mgr:GetActivityTeam()),
        title = app.springActivity20Mgr:GetPoText(__('编辑队伍')),
        teamTowards = -1,
        avatarTowards = 1,
        teamChangeSingalName = SPRING_ACTIVITY_20_SP_BOSS_TEAM_CHANGE_NOTICE,
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
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
初始化view
--]]
function SpringActivity20SpBossMediator:InitView()
    -- 初始化boss数据
    self:InitSpBossData()
    -- 刷新编队
    self:RefreshTeam()
    -- 刷新特殊boss信息
    self:RefreshSpBossInfo()
    -- 刷新buff
    self:RefreshBuff()
    -- 检测boss是否通过
    self:CheckSpBossPassed()
end
--[[
初始化特殊boss数据
--]]
function SpringActivity20SpBossMediator:InitSpBossData()
    local spBossData = clone(app.springActivity20Mgr:GetSpBoss()) or {}
    local config = CommonUtils.GetConfigAllMess('param', 'springActivity2020')
    spBossData.spQuestId = config.spQuestId
    local questConfig = CommonUtils.GetConfig('springActivity2020', 'quest', spBossData.spQuestId)
    spBossData.rewards = clone(questConfig.rewards)
    local monsterConfig = CommonUtils.GetConfig('monster', 'monster', questConfig.monsterInfo[1])
    spBossData.maxHp = monsterConfig.hp
    self:SetSpBossData(spBossData)
end
--[[
更新编队信息
--]]
function SpringActivity20SpBossMediator:UpdateTeamData( teamData )
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
function SpringActivity20SpBossMediator:IsTeamDataValid( teamData )
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
function SpringActivity20SpBossMediator:RemoveChangeTeamScene()
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
function SpringActivity20SpBossMediator:RefreshTeam()
    local viewComponent = self:GetViewComponent()
    local activityTeam = app.springActivity20Mgr:GetActivityTeam()
    viewComponent:RefreshTeam(activityTeam)
end
--[[
刷新特殊boss信息
--]]
function SpringActivity20SpBossMediator:RefreshSpBossInfo()
    local viewComponent = self:GetViewComponent()
    local spBossData = self:GetSpBossData()
    viewComponent:RefreshSpBossInfo(spBossData)
end
--[[
刷新buff
--]]
function SpringActivity20SpBossMediator:RefreshBuff()
    local viewComponent = self:GetViewComponent()
    local buff = app.springActivity20Mgr:GetGlobalBuff()
    viewComponent:RefreshBuff(buff)
end
--[[
检测spBoss是否通过
--]]
function SpringActivity20SpBossMediator:CheckSpBossPassed()
    if self.isSpBossPassed then
        local viewComponent = self:GetViewComponent()
        viewComponent:CatchSpBoss()
    end
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
设置编队页面
--]]
function SpringActivity20SpBossMediator:SetChangeTeamScene( ChangeTeamScene )
	self.ChangeTeamScene = ChangeTeamScene
end
--[[
获取编队页面
--]]
function SpringActivity20SpBossMediator:GetChangeTeamScene( )
	return self.ChangeTeamScene
end
--[[
设置特殊boss数据
--]]
function SpringActivity20SpBossMediator:SetSpBossData( spBossData )
    self.spBossData = spBossData
end
--[[
获取特殊boss数据
--]]
function SpringActivity20SpBossMediator:GetSpBossData()
    return self.spBossData
end
------------------- get / set -------------------
-------------------------------------------------

return SpringActivity20SpBossMediator
