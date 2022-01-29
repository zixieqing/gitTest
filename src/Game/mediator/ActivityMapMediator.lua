--[[
活动副本地图mediator
--]]
local Mediator = mvc.Mediator
local ActivityMapMediator = class("ActivityMapMediator", Mediator)
local NAME = "ActivityMapMediator"
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
RESET_MAP_COST = 240 -- 重置副本消耗
BUY_QUEST_HP_COST_NUM = 45 -- 购买行动力幻晶石消耗
BUY_QUEST_HP_GOODS_NUM = 100 -- 每次购买获得的行动力
function ActivityMapMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.args = params
	self.isNewActivityQuestType = 0    -- 是否为新关卡活动类型
	self.activityId = checkint(self.args.activityId)
	self.battleBackQuestId = self.args.questId -- 战斗返回的questId
	self.selectedPageIdx = 1
	self.zoneId = 1 -- 区域id
	self.canReset = false -- 是否可以重置
	self.canSweep = 0 -- 是否可以扫荡
	self.buyQuestHpTimes = 0 -- 剩余行动力购买次数
	self.mapDatas = {}
end

function ActivityMapMediator:InterestSignals()
	local signals = {
		POST.ACTIVITYQUEST_HOME.sglName,
		POST.ACTIVITYQUEST_RESET_STORY_QUEST.sglName,
		POST.ACTIVITYQUEST_STORY_QUEST.sglName,
		POST.ACTIVITYQUEST_DRAW_CHEST.sglName,
		POST.ACTIVITYQUEST_RESET_ALL_STORY.sglName,
		POST.ACTIVITYQUEST_STORY_SWEEP.sglName,
		POST.ACTIVITYQUEST_BUY_QUESTHP.sglName,
		ACTIVITY_QUEST_BATTLE_EVENT,
		ACTIVITY_QUEST_STORY_EVENT,
		ACTIVITY_QUEST_RESET_STORY_EVENT,
		ACTIVITY_QUEST_CHEST_DRAW_EVENT, 
		SIGNALNAMES.CACHE_MONEY_UPDATE_UI,
		"SHOW_SWEEP_POPUP",
		"NEXT_TIME_DATE",
		ACTIVITY_QUEST_BUY_HP,
	}
	return signals
end

function ActivityMapMediator:ProcessSignal( signal )
	local name = signal:GetName()
	local datas = signal:GetBody()
	if name == POST.ACTIVITYQUEST_HOME.sglName then
		if checkint(datas.errcode) ~= 0 then
			if self.args.battleBack then -- 判断是否是战斗返回
				AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'NAME'}, {name = 'HomeMediator'})
			end
		else
			self.isNewActivityQuestType = checkint(datas.isNewActivityQuestType)
			self.currentDay = datas.currentDay
			self:InitMapDatas(datas)
			self:SetActivityQuestHp(datas.questHp)
			self:RefreshView()
		end
	elseif name == POST.ACTIVITYQUEST_RESET_STORY_QUEST.sglName then
		-- 扣除道具
		local questConfig = CommonUtils.GetConfig('activityQuest', 'questPlot', self.zoneId)[tostring(datas.requestData.questId)]
		local temp = clone(questConfig.consume)
		for i,v in ipairs(temp) do
			v.num = -v.num
		end
		CommonUtils.DrawRewards(temp)
		uiMgr:AddDialog('common.RewardPopup', {rewards = datas.rewards})
		self:SendSignal(POST.ACTIVITYQUEST_HOME.cmdName, {activityId = self.activityId})
	elseif name == POST.ACTIVITYQUEST_STORY_QUEST.sglName then
		self:SendSignal(POST.ACTIVITYQUEST_HOME.cmdName, {activityId = self.activityId})
	elseif name == POST.ACTIVITYQUEST_DRAW_CHEST.sglName then
		-- 扣除道具
		local questConfig = CommonUtils.GetConfig('activityQuest', 'questChest', self.zoneId)[tostring(datas.requestData.questId)]
		if questConfig then
		local temp = clone(questConfig.consume)
			for i,v in ipairs(temp) do
				v.num = -v.num
			end
			CommonUtils.DrawRewards(temp)
		end
		uiMgr:AddDialog('common.RewardPopup', {rewards = datas.rewards})
		self:SendSignal(POST.ACTIVITYQUEST_HOME.cmdName, {activityId = self.activityId})
	elseif name == POST.ACTIVITYQUEST_RESET_ALL_STORY.sglName then
		gameMgr:GetUserInfo().diamond = signal:GetBody().diamonds
		self:GetFacade():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI)
		self:SendSignal(POST.ACTIVITYQUEST_HOME.cmdName, {activityId = self.activityId})
	elseif name == POST.ACTIVITYQUEST_STORY_SWEEP.sglName then
		-- 更新行动力
		local consumeHp = self:GetConsumeHp(datas.requestData.questId)
		local questHp = self:GetActivityQuestHp() - consumeHp * checkint(datas.requestData.times)
		self:SetActivityQuestHp(questHp)
		self:UpdateCountUI()
	elseif name == POST.ACTIVITYQUEST_BUY_QUESTHP.sglName then
		-- 购买体力
		gameMgr:GetUserInfo().diamond = signal:GetBody().diamond
		self:SetActivityQuestHp(self:GetActivityQuestHp() + BUY_QUEST_HP_GOODS_NUM)
		self:UpdateCountUI()
		self.buyQuestHpTimes = self.buyQuestHpTimes - 1
		AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.CACHE_MONEY_UPDATE_UI)
	elseif name == ACTIVITY_QUEST_BATTLE_EVENT then
		-- 进入战斗准备界面
		self:ShowEnterStageView(datas.stageDatas)
	elseif name == ACTIVITY_QUEST_STORY_EVENT then
		-- 进入剧情界面
		self:EnterQuestStory(datas.stageDatas)
	elseif name == ACTIVITY_QUEST_RESET_STORY_EVENT then
		-- 重置剧情关卡
		self:ResetStoryState(datas.stageDatas)
	elseif name == ACTIVITY_QUEST_CHEST_DRAW_EVENT then
		-- 领取宝箱
		self:ChestStageDraw(datas.stageDatas)
	elseif name == SIGNALNAMES.CACHE_MONEY_UPDATE_UI then
		self:UpdateCountUI()
	elseif name == "SHOW_SWEEP_POPUP" then
		-- 显示扫荡选择弹窗
		self:ShowSweepPopup(datas.stageId)
	elseif name == "NEXT_TIME_DATE" then
		self:SendSignal(POST.ACTIVITYQUEST_HOME.cmdName, {activityId = self.activityId})
	elseif name == ACTIVITY_QUEST_BUY_HP then
		-- 购买行动力
		self:ShowBuyQuestHpView()
	end
end

function ActivityMapMediator:Initial( key )
	self.super:Initial(key)
end
--[[
刷新页面
--]]
function ActivityMapMediator:RefreshView()
	if not self:GetViewComponent() then
		self:InitView()
	end
	self:UpdateCountUI()
	self:RefreshChangeChapterBtnState()
	self:GetViewComponent().viewData_.resetLayout:setVisible(true)
	self:GetViewComponent().viewData_.mapPageView:setCountOfCell(#self.mapDatas)
	self:GetViewComponent().viewData_.mapPageView:reloadData()
	self:GetViewComponent().viewData_.resetLayout:setVisible(self.canReset)
	self:JumpToPageByPageIndex(self.selectedPageIdx)
end
function ActivityMapMediator:InitView()
	local viewComponent = require('Game.views.activityMap.ActivityMapView').new()

	uiMgr:SwitchToScene(viewComponent)
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	viewComponent.viewData_.mapPageView:setDataSourceAdapterScriptHandler(handler(self, self.MapPageViewDataAdapter))
	viewComponent.viewData_.mapPageView:setOnPageChangedScriptHandler(handler(self, self.MapPageViewChangedHandler))
	viewComponent.viewData_.backBtn:setOnClickScriptHandler(handler(self, self.backButtonCallback))
	viewComponent.viewData_.prevBtn:setOnClickScriptHandler(handler(self, self.ChangePageBtnCallback))
	viewComponent.viewData_.nextBtn:setOnClickScriptHandler(handler(self, self.ChangePageBtnCallback))
	viewComponent.viewData_.tabNameLabel:setOnClickScriptHandler(handler(self, self.TabTipsBtnCallback))
	viewComponent.viewData_.resetTipsBtn:setOnClickScriptHandler(handler(self, self.ResetTipsBtnCallback))
	viewComponent.viewData_.resetBtn:setOnClickScriptHandler(handler(self, self.ResetBtnCallback))
	-- 标题
	display.commonLabelParams(viewComponent.viewData_.tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = self.mapDatas[1][1].name, fontSize = 30, color = '473227',offset = cc.p(0,-8), reqW = 200})
end
--[[
page cell 回调
--]]
function ActivityMapMediator:MapPageViewDataAdapter( p_convertview, idx )
    local pCell = p_convertview
    local index = idx + 1
    local cSize = self:GetViewComponent().viewData_.mapPageView:getContentSize()
		if nil == pCell then
			pCell = require('Game.views.activityMap.ActivityMapPageViewCell').new(cSize)
		end
	xTry(function()
		-- 移除现有关卡
		for i, v in ipairs(pCell.stageNodeTable) do
			v:removeFromParent()
		end
		pCell.stageNodeTable = {}
		for i, v in ipairs(self.mapDatas[index]) do
			local node = require('Game.views.activityMap.ActivityMapStageNode').new({stageDatas = v})
			pCell.bgView:addChild(node, 3)
			node:setPosition(checkint(v.location.x), 1002 - checkint(v.location.y))
			table.insert(pCell.stageNodeTable, node)
		end
		local backgroundId = self.mapDatas[index][1].backgroundId or 1
		pCell.leftImage:setTexture(_res(string.format('arts/maps/maps_bg_%d_01.png', backgroundId)))
		pCell.rightImage:setTexture(_res(string.format('arts/maps/maps_bg_%d_02.png', backgroundId)))
	end,__G__TRACKBACK__)
	return pCell
end
--[[
page view 翻页回调
--]]
function ActivityMapMediator:MapPageViewChangedHandler( sender, i )
	self:RefreshChangeChapterBtnState()
end
--[[
更新翻页按钮状态
--]]
function ActivityMapMediator:RefreshChangeChapterBtnState()
	local prevBtn = self:GetViewComponent().viewData_.prevBtn
	local nextBtn = self:GetViewComponent().viewData_.nextBtn
	prevBtn:setVisible(not (1 == self.selectedPageIdx))
	nextBtn:setVisible(not (#self.mapDatas == self.selectedPageIdx))
end
--[[
翻页按钮回调
2001 上一页
2002 下一页
--]]
function ActivityMapMediator:ChangePageBtnCallback( sender )
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	if 2001 == tag then -- 上一页
		self.selectedPageIdx = math.max(1, self.selectedPageIdx - 1)
		self:JumpToPageByPageIndex(self.selectedPageIdx)
	elseif 2002 == tag then -- 下一页
		local nextChapterId = math.min(#self.mapDatas, self.selectedPageIdx + 1)
		self.selectedPageIdx = nextChapterId
		self:JumpToPageByPageIndex(self.selectedPageIdx)
	end
	self:RefreshChangeChapterBtnState()
end
--[[
跳转界面到指定页面
--]]
function ActivityMapMediator:JumpToPageByPageIndex( pageIndex )
	local pageSize = self:GetViewComponent().viewData_.mapPageView:getContentSize()
	local offsetX = - pageSize.width * (self.selectedPageIdx - 1)
	self:GetViewComponent().viewData_.mapPageView:setContentOffset(cc.p(offsetX, 0))
end
--[[
返回按钮回调
--]]
function ActivityMapMediator:backButtonCallback( sender )
	PlayAudioByClickClose()
	local activityHomeData = app.gameMgr:GetUserInfo().activityHomeData
	local isSpActivity = false
	for i, v in ipairs(activityHomeData.activity) do
		if v.type == ACTIVITY_TYPE.SP_ACTIVITY then
			isSpActivity = true
			break 
		end
	end
	if isSpActivity then
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'NAME'}, {name = 'specialActivity.SpActivityMediator', params = {activityId = self.activityId}})
	else
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'NAME'}, {name = 'ActivityMediator', params = {activityId = self.activityId}})
	end
	-- self:GetFacade():UnRegsitMediator("ActivityMapMediator")
end
--[[
标题tips按钮回调
--]]
function ActivityMapMediator:TabTipsBtnCallback( sender )
	PlayAudioByClickNormal()
	local descr = __('1.本次【飨灵物语】剧情活动内容共分为剧情关卡，战斗关卡，和活动奖励三个部分。\n\n【剧情关卡】\n1.御侍可通过在剧情中的问答做出不同的选择，增加和选择对应的飨灵亲密度。\n2.剧情问答中的选项会出现不增加亲密度的可能，可通过消耗幻晶石来改变选择，每日每个剧情点最多重置3次。\n\n【战斗关卡】\n1.挑战活动战斗关卡会掉落活动的专属道具，可在活动的兑换界面兑换游戏内各种道具。\n2.参与活动的战斗关卡将不会消耗体力，而是消耗此次活动专有的【行动力】。\n3.行动力每日0点刷新，恢复至100点。若刷新时，行动力高于100点，则不会刷新。\n4.御侍可消耗45幻晶石购买100点行动力，每日购买次数上限为10次。\n5.只有通关整个副本后，才可以在战斗关卡进行扫荡。\n\n【活动奖励】\n1.活动奖励分为战斗关卡的掉落和通关后所得的宝箱。\n2.通关后所得的宝箱：当御侍完成所有关卡并达到宝箱开启所需的飨灵亲密度时，即可领取与该飨灵对应的宝箱，获得丰厚奖励。\n3.此次剧情活动中的所有宝箱只可领取一次，不可重置')
	uiMgr:ShowIntroPopup({title = __('飨灵物语规则'), descr = descr})
end
--[[
重置全部剧情回调
--]]
function ActivityMapMediator:ResetBtnCallback( sender )
	PlayAudioByClickNormal()
	if CommonUtils.GetCacheProductNum(DIAMOND_ID) >= RESET_MAP_COST then
		local scene = uiMgr:GetCurrentScene()
		local strs = string.split(string.fmt(__('是否消耗|_num_|幻晶石重置所有关卡？'),{['_num_'] = RESET_MAP_COST}), '|')
 		local CommonTip  = require( 'common.NewCommonTip' ).new({richtext = {
 			{text = strs[1], fontSize = 22, color = '#4c4c4c'},
 			{text = strs[2], fontSize = 24, color = '#da3c3c'},
 			-- {img = CommonUtils.GetGoodsIconPathById(DIAMOND_ID), scale = 0.2},
 			{text = strs[3], fontSize = 22, color = '#4c4c4c'}},
 			isOnlyOK = false, callback = function ()
    	self:SendSignal(POST.ACTIVITYQUEST_RESET_ALL_STORY.cmdName, {activityId = self.activityId})
		end,
		cancelBack = function ()
		end})
		CommonTip:setPosition(display.center)
		scene:AddDialog(CommonTip)
	else
		if GAME_MODULE_OPEN.NEW_STORE then
			app.uiMgr:showDiamonTips()
		else
			uiMgr:ShowInformationTips(__("幻晶石不足"))
		end
	end

	
end
--[[
重置剧情tips按钮回调
--]]
function ActivityMapMediator:ResetTipsBtnCallback( sender )
	PlayAudioByClickNormal()
	local descr = __('1.在通关所有关卡并领取对应宝箱后，若御侍希望获得另一个活动通关奖励，需消耗240幻晶石进行活动剧情重置。\n2.点击重置剧情后，所有剧情关卡都可以重新进行选择。\n3.剧情重置后，仍需达到另一个宝箱开启所需的飨灵亲密度，才能领取通关后的宝箱奖励。\n')
	uiMgr:ShowIntroPopup({title = __('活动剧情重置规则'), descr = descr})
end
--[[
初始化地图数据
@params homeDatas table home数据
--]]
function ActivityMapMediator:InitMapDatas( homeDatas )
	self.zoneId = checkint(homeDatas.zoneId)
	self.canSweep = checkint(homeDatas.isDone)
	self.buyQuestHpTimes = checkint(homeDatas.buyQuestHpTimes)
	local mapConfig = CommonUtils.GetConfig('activityQuest', 'questType', self.zoneId) or {}
	-- 初始化地图页签
	self:InitSelectedPageIdx()
	-- 初始化角色颜色
	if homeDatas.points	then
		local roleIds = {}
		for i,v in pairs(checktable(homeDatas.points)) do
			table.insert(roleIds, checkint(i))
		end
		homeDatas.roleColor = {}
		homeDatas.roleColor[tostring(math.max(roleIds[1], roleIds[2]))] = 'red'
		homeDatas.roleColor[tostring(math.min(roleIds[1], roleIds[2]))] = 'blue'
	end
	local maxPoints = {} -- 好感度最大值
	local clearQuest = true -- 是否通关
	local drawAllRewards = true -- 是否领取全部奖励
	for k, v in pairs(mapConfig) do
		if checkint(v.questType) == ActivityQuestType.CHEST then
			local chestConfig = CommonUtils.GetConfig('activityQuest', 'questChest', v.zoneId)[tostring(v.id)]
			maxPoints[tostring(chestConfig.roleId)] = checkint(chestConfig.point)
			if drawAllRewards then -- 判断是否所有奖励都已领取
				if not homeDatas.quests[tostring(v.id)] or checkint(homeDatas.quests[tostring(v.id)].isPassed) <= 0 then
					drawAllRewards = false
				end
			end
		elseif checkint(v.questType) == ActivityQuestType.BATTLE then
			if clearQuest then -- 判断是否通关
				if not homeDatas.quests[tostring(v.id)] or checkint(homeDatas.quests[tostring(v.id)].isPassed) <= 0 then
					clearQuest = false
				end
			end
		end
	end
	-- 判断是否可以重置副本
	if checkint(homeDatas.isDrawn) > 0 and not drawAllRewards then
		self.canReset = true
	else
		self.canReset = false
	end
	local mapDatas = {}
	for k, v in orderedPairs(mapConfig) do
		local temp = clone(v)
		-- 是否通过
		if homeDatas.quests[tostring(temp.id)] then
			temp.isPassed = checkint(homeDatas.quests[tostring(temp.id)].isPassed)
		else
			temp.isPassed = 0
		end
		-- 判断任务点类型
		if checkint(v.questType) == ActivityQuestType.BATTLE then -- 战斗
		elseif checkint(temp.questType) == ActivityQuestType.STORY then -- 剧情
			if homeDatas.quests[tostring(temp.id)] and homeDatas.quests[tostring(temp.id)].content then
				temp.content = homeDatas.quests[tostring(temp.id)].content
			end
			if homeDatas.resetTimes[tostring(temp.id)] then
				temp.resetTimes = checkint(homeDatas.resetTimes[tostring(temp.id)])
			end
			temp.isDrawn = checkint(homeDatas.isDrawn)
			temp.points = homeDatas.points
			temp.roleColor = homeDatas.roleColor
			temp.maxPoints = maxPoints
		elseif checkint(temp.questType) == ActivityQuestType.CHEST then -- 宝箱
			temp.points = homeDatas.points
			temp.roleColor = homeDatas.roleColor
			temp.clearQuest = clearQuest
		end
		-- 判断关卡是否锁定
		if self.isNewActivityQuestType == 1 then
			local time = checkint(temp.time)
			if time == 0 then
				temp.isLock = false
			elseif self.currentDay >=  time then
				temp.isLock = false
			else
				temp.isLock = true
			end
		else
			temp.isLock = checkint(temp.id) > checkint(homeDatas.newestQuestId)
		end

		-- 当前关卡
		if checkint(temp.id) == checkint(homeDatas.newestQuestId) then
			temp.newestQuestId = 1
		else
			temp.newestQuestId = 0
		end
		-- 区域划分
		if mapDatas[checkint(temp.areaId)] then
			table.insert(mapDatas[checkint(temp.areaId)], temp)
		else
			mapDatas[checkint(temp.areaId)] = {temp}
		end
	end
	self.mapDatas = mapDatas

end
--[[
更新顶部货币数量
--]]
function ActivityMapMediator:UpdateCountUI()
	if not self:GetViewComponent() then return end
	local viewData = self:GetViewComponent().viewData_
	if viewData.moneyNods then
		for id,v in pairs(viewData.moneyNods) do
			v:updataUi(checkint(id)) --刷新每一个货币数量
		end
	end
end
--[[
关卡点击回调
@params stageId int 关卡id
--]]
function ActivityMapMediator:ShowEnterStageView( stageDatas )
	if stageDatas.isLock then
		uiMgr:ShowInformationTips(__("关卡未解锁"))
		return 
	end
	local stageId = checkint(stageDatas.id)
	local consumeHp = self:GetConsumeHp(stageDatas.id)
	if self:GetActivityQuestHp() < consumeHp then
		uiMgr:ShowInformationTips(__("行动力不足"))
		return 
	end
	-- 判断是否需要下载资源
	if 0 < checkint(SUBPACKAGE_LEVEL) and cc.UserDefault:getInstance():getBoolForKey('SubpackageRes_' .. tostring(FTUtils:getAppVersion()), false) == false then
        local gameManager   = self:GetFacade():GetManager('GameManager')
        local playerLevel   = checkint(gameManager:GetUserInfo().level)
        if playerLevel >= checkint(SUBPACKAGE_LEVEL) then
            local uiMgr = self:GetFacade():GetManager("UIManager")
            local scene = uiMgr:GetCurrentScene()
            local CommonTip  = require( 'common.NewCommonTip' ).new({text = __('您已经初步体验了我们的游戏，如需体验更多更优质的游戏内容，还需继续下载完整游戏包～'),
				callback = function ()
					if cc.UserDefault:getInstance():getBoolForKey('SubpackageRes_' .. tostring(FTUtils:getAppVersion()), false) == false then
						AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'}, {name = 'ResourceDownloadMediator', params = {
							closeFunc = function (  )
								AppFacade.GetInstance():BackHomeMediator()
							end
						}})
					end
                end})
            CommonTip:setPosition(display.center)
            scene:AddDialog(CommonTip)
		end
		return
    end
	--------------- 初始化战斗传参 ---------------
	local battleReadyData = BattleReadyConstructorStruct.New(
		2,
		gameMgr:GetUserInfo().localCurrentBattleTeamId,
		gameMgr:GetUserInfo().localCurrentEquipedMagicFoodId,
		stageId,
		CommonUtils.GetQuestBattleByQuestId(stageId),
		nil,
		POST.ACTIVITY_QUEST_QUESTAT.cmdName,
		{questId = stageId, activityId = self.activityId},
		POST.ACTIVITY_QUEST_QUESTAT.sglName,
		POST.ACTIVITY_QUEST_QUESTGRADE.cmdName,
		{questId = stageId, activityId = self.activityId},
		POST.ACTIVITY_QUEST_QUESTGRADE.sglName,
		NAME,
		NAME
	)
	--------------- 初始化战斗传参 ---------------
	local layer = require('Game.views.BattleReadyView').new(battleReadyData)
	layer:setPosition(cc.p(display.cx,display.cy))
	uiMgr:GetCurrentScene():AddDialog(layer)
end
--[[
	播放副本剧情
	taskId / 10
]]
function ActivityMapMediator:PlayQuestStory(taskId, stageDatas, closeCb)
	local subIndex   = math.ceil(checkint(taskId) / 10)
	local storyStage = require( "Frame.Opera.OperaStage" ).new({
		id = taskId, 
		data = {
			activityId = self.activityId,
			questId    = stageDatas.id,
			zoneId     = stageDatas.zoneId,
			maxPoints  = checktable(stageDatas.maxPoints),
			selected   = checktable(checktable(stageDatas.content).selected), curPoints = checktable(stageDatas.points)
		},
		path = string.format("conf/%s/activityQuest/cardWords%d.json", i18n.getLang(), subIndex),
		isHideSkipBtn = true,
		cb = function(tag)
			if closeCb then closeCb(tag) end
		end,
	})
	storyStage:setPosition(display.center)
	self:GetViewComponent():addChild(storyStage, GameSceneTag.Dialog_GameSceneTag)
end
--[[
进入副本剧情
--]]
function ActivityMapMediator:EnterQuestStory( stageDatas )
	if stageDatas.isLock then
		uiMgr:ShowInformationTips(__("关卡未解锁"))
		return 
	end
	-- 获取剧情的taskId
	local storyConfig = CommonUtils.GetConfig('activityQuest', 'questPlot', stageDatas.zoneId)
	local taskId = checkint(storyConfig[tostring(stageDatas.id)].taskId)
	self:PlayQuestStory(taskId, stageDatas, function()
		if checkint(stageDatas.questType) == ActivityQuestType.PURE_STORY then
		else
			AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'BattleMediator'}, {name = 'ActivityMapMediator', params = {activityId = self.activityId}})
		end
	end)
end
--[[
重置剧情点剧情
--]]
function ActivityMapMediator:ResetStoryState( stageDatas )
	local questConfig = CommonUtils.GetConfig('activityQuest', 'questPlot', self.zoneId)[tostring(stageDatas.id)]
	local activityMapResetStoryTips = require('Game.views.activityMap.ActivityMapResetStoryTips').new({
		callback = function () 
			if gameMgr:GetUserInfo().diamond >= checkint(questConfig.consume[1].num) then
				self:SendSignal(POST.ACTIVITYQUEST_RESET_STORY_QUEST.cmdName, {activityId = self.activityId, questId = stageDatas.id})
			else
				if GAME_MODULE_OPEN.NEW_STORE then
					app.uiMgr:showDiamonTips()
				else
					uiMgr:ShowInformationTips(__("幻晶石不足"))
				end
			end
		end,
		consume = questConfig.consume[1],
		rewards = questConfig.rewards,
		maxResetTimes = 3,
		leftResetTimes = stageDatas.resetTimes,

	})
	uiMgr:GetCurrentScene():AddDialog(activityMapResetStoryTips)
	display.commonUIParams(activityMapResetStoryTips, {po = display.center})
end
--[[
领取宝箱关奖励
--]]
function ActivityMapMediator:ChestStageDraw( stageDatas )
	local chestConfig = CommonUtils.GetConfig('activityQuest', 'questChest', stageDatas.zoneId)
	local roleId = chestConfig[tostring(stageDatas.id)].roleId
	local coordinateConfig = CommonUtils.GetConfig('activityQuest', 'coordinate', chestConfig[tostring(stageDatas.id)].roleId)
	local point = checkint(stageDatas.points[tostring(roleId)])
	local maxPoint = checkint(chestConfig[tostring(stageDatas.id)].point)
	local pointEnough = point >= maxPoint
	local materialEnough = true
	for i, v in ipairs(stageDatas.consume) do
		local hasNums = checkint(gameMgr:GetAmountByGoodId(v.goodsId))
		if hasNums < v.num then
			materialEnough = false
			break
		end
	end
	local activityMapChestPopup = require('Game.views.activityMap.ActivityMapChestPopup').new({
		title = stageDatas.checkpointName,
		rewards = stageDatas.chestReward,
		consume = stageDatas.consume,
		isGray = not (pointEnough and materialEnough),
		callback = function ()
			if pointEnough then
				if materialEnough then
					-- 获取剧情的taskId
					local storyConfig = CommonUtils.GetConfig('activityQuest', 'questChest', stageDatas.zoneId)
					local taskId = checkint(storyConfig[tostring(stageDatas.id)].taskId)
					self:PlayQuestStory(taskId, stageDatas, function()
						if ActivityQuestType.PURE_STORY == checkint(stageDatas.questType) then
						else
							AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'BattleMediator'}, {name = 'ActivityMapMediator', params = {activityId = self.activityId}})
							self:SendSignal(POST.ACTIVITYQUEST_DRAW_CHEST.cmdName, {activityId = self.activityId, questId = stageDatas.id})
						end
					end)
				else
					uiMgr:ShowInformationTips(__("材料不足"))
				end
			else
				uiMgr:ShowInformationTips(__("好感度不足"))
			end
		end
	})
	uiMgr:GetCurrentScene():AddDialog(activityMapChestPopup)
	display.commonUIParams(activityMapChestPopup, {po = display.center})
end
--[[
更新行动力
--]]
function ActivityMapMediator:SetActivityQuestHp( activityQuestHp )
	gameMgr:GetUserInfo().activityQuestHp = checkint(activityQuestHp)
end
--[[
获取行动力
--]]
function ActivityMapMediator:GetActivityQuestHp()
	return checkint(gameMgr:GetUserInfo().activityQuestHp)
end
--[[
显示扫荡弹窗
--]]
function ActivityMapMediator:ShowSweepPopup( stageId )
	self.sweepQuestId = checkint(stageId)
	local tag = 4001
	local layer = require('Game.views.SweepPopup').new({
		tag = tag,
		stageId = stageId,
		sweepRequestData = {activityId = self.activityId},
		canSweepCB = handler(self, self.CanSweepCallback),
		sweepRequestCommand = POST.ACTIVITYQUEST_STORY_SWEEP.cmdName, 
		sweepResponseSignal = POST.ACTIVITYQUEST_STORY_SWEEP.sglName
	})
	display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
	layer:setTag(tag)
    layer:setName('SweepPopup')
	uiMgr:GetCurrentScene():AddDialog(layer)
end
--[[
判断是否可以扫荡
--]]
function ActivityMapMediator:CanSweepCallback( stageId, times )
	local consumeHp = self:GetConsumeHp(stageId)
	if checkint(self.canSweep) > 0 then
		if self:GetActivityQuestHp() >=consumeHp*times then
			return true
		else
			uiMgr:ShowInformationTips(__("行动力不足"))
		end
	else
		uiMgr:ShowInformationTips(__("通关全部关卡才可开启扫荡功能"))
	end
end
--[[
获取副本所需行动力
--]]
function ActivityMapMediator:GetConsumeHp( questId )
	local stageConf = CommonUtils.GetQuestConf(checkint(questId))
	return checkint(stageConf.consumeHp)
end
--[[
展示购买体力页面
--]]
function ActivityMapMediator:ShowBuyQuestHpView()
	uiMgr:AddDialog('Game.views.AddPowerPopup', {
		payId        = ACTIVITY_QUEST_HP,
		leftBuyTimes = self.buyQuestHpTimes,
		goodsNum     = BUY_QUEST_HP_GOODS_NUM,
		costNum      = BUY_QUEST_HP_COST_NUM,
		callback     = function ()
			local hasDiamond = CommonUtils.GetCacheProductNum(DIAMOND_ID)
			if GAME_MODULE_OPEN.NEW_STORE and hasDiamond < BUY_QUEST_HP_COST_NUM then
				app.uiMgr:showDiamonTips()
			else
				AppFacade.GetInstance():DispatchSignal(POST.ACTIVITYQUEST_BUY_QUESTHP.cmdName, {activityId = self.activityId, num = 1})
			end
		end
	})
end
--[[
初始化地图页签
--]]
function ActivityMapMediator:InitSelectedPageIdx()
	if self.battleBackQuestId then
		local mapConfig = CommonUtils.GetConfig('activityQuest', 'questType', self.zoneId)
		for i, v in pairs(mapConfig) do
			if checkint(v.id) == checkint(self.battleBackQuestId) then
				self.selectedPageIdx = checkint(v.areaId)
			end
		end
		self.battleBackQuestId = nil
	end
end

function ActivityMapMediator:EnterLayer()
	self:SendSignal(POST.ACTIVITYQUEST_HOME.cmdName, {activityId = self.activityId})
end
function ActivityMapMediator:OnRegist()
	regPost(POST.ACTIVITYQUEST_HOME, true)
	regPost(POST.ACTIVITYQUEST_RESET_STORY_QUEST)
	regPost(POST.ACTIVITYQUEST_DRAW_CHEST)
	regPost(POST.ACTIVITYQUEST_RESET_ALL_STORY)
	regPost(POST.ACTIVITYQUEST_STORY_SWEEP)
	regPost(POST.ACTIVITYQUEST_BUY_QUESTHP)
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
    self:EnterLayer()
end
function ActivityMapMediator:OnUnRegist()
	unregPost(POST.ACTIVITYQUEST_HOME)
	unregPost(POST.ACTIVITYQUEST_RESET_STORY_QUEST)
	unregPost(POST.ACTIVITYQUEST_DRAW_CHEST)
	unregPost(POST.ACTIVITYQUEST_RESET_ALL_STORY)
	unregPost(POST.ACTIVITYQUEST_STORY_SWEEP)
	unregPost(POST.ACTIVITYQUEST_BUY_QUESTHP)
    if self:GetViewComponent() and not  tolua.isnull(self:GetViewComponent()) then
        self:GetViewComponent():runAction(cc.RemoveSelf:create())
    end
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightShow")
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
end

return ActivityMapMediator
