--[[
 * author : liuzhipeng
 * descpt : 联动 pop子 关卡Mediator
--]]
local PopTeamStageMediator = class('PopTeamStageMediator', mvc.Mediator)
local NAME = "link.popTeam.PopTeamStageMediator"
function PopTeamStageMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
	local args = checktable(params)
    self.activityId = checkint(args.requestData.activityId)
	self.battleBackQuestId = args.requestData.questId -- 战斗返回的questId
	self.zoneIndex = args.requestData.zoneIndex or 1
    self.zoneId = 1
    self.selectedPageIdx = 1
	self.mapDatas = {}

end
-------------------------------------------------
------------------ inheritance ------------------
function PopTeamStageMediator:Initial( key )
    self.super.Initial(self, key)
    local viewComponent = app.uiMgr:SwitchToTargetScene('Game.views.link.popTeam.PopTeamStageScene')
    self:SetViewComponent(viewComponent)
    local viewData = viewComponent:GetViewData()
    -- 绑定
    viewData.tabNameLabel:setOnClickScriptHandler(handler(self, self.TipsButtonCallback))
    viewData.backBtn:setOnClickScriptHandler(handler(self, self.BackButtonCallback))
	viewData.mapPageView:setDataSourceAdapterScriptHandler(handler(self, self.MapPageViewDataAdapter))
	viewData.mapPageView:setOnPageChangedScriptHandler(handler(self, self.MapPageViewChangedHandler))
	viewData.prevBtn:setOnClickScriptHandler(handler(self, self.ChangePageBtnCallback))
	viewData.nextBtn:setOnClickScriptHandler(handler(self, self.ChangePageBtnCallback))
	if self.payload then
		self:InitView(self.payload)
	end
end

function PopTeamStageMediator:InterestSignals()
    local signals = {
		POST.POP_TEAM_HOME.sglName, 
		POST.POP_TEAM_STORY_QUEST.sglName,
		POST.POP_TEAM_CHEST_QUEST.sglName,
        POP_TEAM_QUEST_BATTLE_EVENT,
        POP_TEAM_QUEST_STORY_EVENT,
        POP_TEAM_QUEST_CHEST_EVENT,
    }
    return signals
end
function PopTeamStageMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.POP_TEAM_HOME.sglName then
		self:InitView(body)
	elseif name == POST.POP_TEAM_STORY_QUEST.sglName then
		self:SendSignal(POST.POP_TEAM_HOME.cmdName, {activityId = self.activityId})
	elseif name == POST.POP_TEAM_CHEST_QUEST.sglName then
		app.uiMgr:AddDialog('common.RewardPopup', {rewards = body.rewards})
		local questId = checkint(body.requestData.questId)
		for _, pageData in ipairs(self.mapDatas) do
			for _, data in ipairs(pageData) do
				if checkint(data.id) == questId then
					data.isPassed = true
					break
				end
			end
		end
		self:RefreshView()
    elseif name == POP_TEAM_QUEST_BATTLE_EVENT then
        -- 进入战斗准备界面
		self:ShowEnterStageView(body.stageDatas)
    elseif name == POP_TEAM_QUEST_STORY_EVENT then
		-- 进入剧情界面
		self:EnterQuestStory(body.stageDatas)
    elseif name == POP_TEAM_QUEST_CHEST_EVENT then
		-- 领取宝箱
		self:ShowChest(body.stageDatas)
    end
end

function PopTeamStageMediator:OnRegist()
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
    regPost(POST.POP_TEAM_HOME)
    regPost(POST.POP_TEAM_STORY_QUEST)
    regPost(POST.POP_TEAM_CHEST_QUEST)
end
function PopTeamStageMediator:OnUnRegist()
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightShow")
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
    unregPost(POST.POP_TEAM_HOME)
    unregPost(POST.POP_TEAM_STORY_QUEST)
    unregPost(POST.POP_TEAM_CHEST_QUEST)
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
--[[
提示按钮点击回调
--]]
function PopTeamStageMediator:TipsButtonCallback( sender )
    PlayAudioByClickNormal()
    app.uiMgr:ShowIntroPopup({moduleId = '-44'})
end
--[[
返回主界面
--]]
function PopTeamStageMediator:BackButtonCallback( sender )
    PlayAudioByClickClose()
	local router = app:RetrieveMediator("Router")
	router:Dispatch({}, {name = "link.popMain.PopMainMediator" , params ={activityId = self.activityId} })
end
--[[
page cell 回调
--]]
function PopTeamStageMediator:MapPageViewDataAdapter( p_convertview, idx )
    local pCell = p_convertview
    local index = idx + 1
    local cSize = self:GetViewComponent():GetViewData().mapPageView:getContentSize()
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
			local node = require('Game.views.link.popTeam.PopTeamStageNode').new({stageDatas = v})
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
function PopTeamStageMediator:MapPageViewChangedHandler( sender, i )
	self:RefreshChangeChapterBtnState()
end
--[[
更新翻页按钮状态
--]]
function PopTeamStageMediator:RefreshChangeChapterBtnState()
	local prevBtn = self:GetViewComponent():GetViewData().prevBtn
	local nextBtn = self:GetViewComponent():GetViewData().nextBtn
	prevBtn:setVisible(not (1 == self.selectedPageIdx))
	nextBtn:setVisible(not (#self.mapDatas == self.selectedPageIdx))
end
--[[
翻页按钮回调
2001 上一页
2002 下一页
--]]
function PopTeamStageMediator:ChangePageBtnCallback( sender )
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
function PopTeamStageMediator:JumpToPageByPageIndex( pageIndex )
	local pageSize = self:GetViewComponent():GetViewData().mapPageView:getContentSize()
	local offsetX = - pageSize.width * (self.selectedPageIdx - 1)
	self:GetViewComponent():GetViewData().mapPageView:setContentOffset(cc.p(offsetX, 0))
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
初始化地图数据
@params homeDatas table home数据
--]]
function PopTeamStageMediator:InitMapDatas( homeDatas )
	self.zoneId = checkint(homeDatas.zones[self.zoneIndex].zoneId)
	local mapConfig = CommonUtils.GetConfig('activity', 'farmQuestType', self.zoneId)
	-- 初始化地图页签
	self:InitSelectedPageIdx()
    local mapDatas = {}
    local newestQuestId = checkint(homeDatas.zones[self.zoneId].newestQuestId)
	for k, v in orderedPairs(mapConfig) do
		local temp = clone(v)
        -- 是否通过
        temp.isPassed = checkint(k) < newestQuestId
        temp.isNewestQuest = checkint(k) == newestQuestId
        -- 是否锁定
        temp.isLock = checkint(k) > newestQuestId
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
显示战前页面
@params stageId int 关卡id
--]]
function PopTeamStageMediator:ShowEnterStageView( stageDatas )
	if stageDatas.isLock then
		app.uiMgr:ShowInformationTips(__("关卡未解锁"))
		return 
	end
	local stageId = checkint(stageDatas.id)
	--------------- 初始化战斗传参 ---------------
	local battleReadyData = BattleReadyConstructorStruct.New(
		2,
		app.gameMgr:GetUserInfo().localCurrentBattleTeamId,
		nil,
		stageId,
		CommonUtils.GetQuestBattleByQuestId(stageId),
		nil,
		POST.POP_TEAM_QUEST_AT.cmdName,
		{questId = stageId, activityId = self.activityId, zoneIndex = self.zoneIndex},
		POST.POP_TEAM_QUEST_AT.sglName,
		POST.POP_TEAM_QUEST_GRADE.cmdName,
		{questId = stageId, activityId = self.activityId},
		POST.POP_TEAM_QUEST_GRADE.sglName,
		NAME,
		NAME
	)
	--------------- 初始化战斗传参 ---------------
	AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.Battle_UI_Create_Battle_Ready, battleReadyData)
end
--[[
进入副本剧情
--]]
function PopTeamStageMediator:EnterQuestStory( stageDatas )
	if stageDatas.isLock then
		app.uiMgr:ShowInformationTips(__("关卡未解锁"))
		return 
	end
	-- 获取剧情的taskId
	local storyConfig = CommonUtils.GetConfig('activity', 'farmQuestPlot', stageDatas.zoneId)
	local storyId = checkint(storyConfig[tostring(stageDatas.id)].storyId)
    local path = string.format("conf/%s/activity/farmStory.json",i18n.getLang())
	local stage = require( "Frame.Opera.OperaStage" ).new({id = storyId, path = path, guide = false, isHideBackBtn = true, cb = function (tag)
		if not stageDatas.isPassed then
			self:SendSignal(POST.POP_TEAM_STORY_QUEST.cmdName, {activityId = self.activityId, zoneId = stageDatas.zoneId, questId = stageDatas.id})
		end
    end})
    stage:setPosition(display.center)
    sceneWorld:addChild(stage, GameSceneTag.Dialog_GameSceneTag)
end
--[[
显示宝箱页面
--]]
function PopTeamStageMediator:ShowChest( stageDatas )
	app.uiMgr:AddDialog("Game.views.link.popTeam.PopTeamStageRewardsView", {questId = stageDatas.id, rewards = stageDatas.chestReward, isLock = stageDatas.isLock, drawCB = handler(self, self.DrawChest)})
end
--[[
领取宝箱奖励
--]]
function PopTeamStageMediator:DrawChest( questId )
	-- 获取剧情的taskId
	local storyConfig = CommonUtils.GetConfig('activity', 'farmQuestPlot', self.zoneId)
	local storyId = checkint(storyConfig[tostring(questId)].storyId)
    local path = string.format("conf/%s/activity/farmStory.json",i18n.getLang())
	local stage = require( "Frame.Opera.OperaStage" ).new({id = storyId, path = path, guide = false, isHideBackBtn = true, cb = function (tag)
		self:SendSignal(POST.POP_TEAM_CHEST_QUEST.cmdName, {activityId = self.activityId, questId = questId, zoneId = self.zoneId})
    end})
    stage:setPosition(display.center)
    sceneWorld:addChild(stage, GameSceneTag.Dialog_GameSceneTag)
end
--[[
初始化view
--]]
function PopTeamStageMediator:InitView( body )
	if checkint(body.errcode) ~= 0 then
		if self.args.battleBack then -- 判断是否是战斗返回
			AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'NAME'}, {name = 'HomeMediator'})
		end
	else
		self:InitMapDatas(body)
		self:RefreshView()
	end
	-- 标题
	self:GetViewComponent():GetViewData().tabNameLabel:getLabel():setString(self.mapDatas[1][1].name)
end
--[[
刷新页面
--]]
function PopTeamStageMediator:RefreshView()
	self:RefreshChangeChapterBtnState()
	self:GetViewComponent():GetViewData().mapPageView:setCountOfCell(#self.mapDatas)
	self:GetViewComponent():GetViewData().mapPageView:reloadData()
	self:JumpToPageByPageIndex(self.selectedPageIdx)
end
--[[
初始化地图页签
--]]
function PopTeamStageMediator:InitSelectedPageIdx()
	if self.battleBackQuestId then
		local mapConfig = CommonUtils.GetConfig('activity', 'farmQuestType', self.zoneId)
		for i, v in pairs(mapConfig) do
			if checkint(v.id) == checkint(self.battleBackQuestId) then
				self.selectedPageIdx = checkint(v.areaId)
			end
		end
		self.battleBackQuestId = nil
	end
end
--[[
更新翻页按钮状态
--]]
function PopTeamStageMediator:RefreshChangeChapterBtnState()
	local prevBtn = self:GetViewComponent():GetViewData().prevBtn
	local nextBtn = self:GetViewComponent():GetViewData().nextBtn
	prevBtn:setVisible(not (1 == self.selectedPageIdx))
	nextBtn:setVisible(not (#self.mapDatas == self.selectedPageIdx))
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
设置homeData
--]]
function PopTeamStageMediator:SetHomeData( homeData )
    self.homeData = homeData
end
--[[
获取homeData
--]]
function PopTeamStageMediator:GetHomeData()
    return self.homeData
end
------------------- get / set -------------------
-------------------------------------------------
return PopTeamStageMediator