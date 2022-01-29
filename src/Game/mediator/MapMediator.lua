--[[
主线地图场景mediator
@params 区域id
--]]
local Mediator = mvc.Mediator
local MapMediator = class("MapMediator", Mediator)
local NAME = "MapMediator"

local MapCommand = require('Game.command.MapCommand')
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

local DifficultyLevel = {
	Normal 	= 1,
	Hard  	= 2,
	History	= 3,
}
local DifficultyLevelDescr = {
	__('普通'),
	__('史诗'),
	__('团本')
}

local dialogueTags = {
	starRewardDetailTag =			 5001
}

---------------------------------------------------
-- mediator extend begin --
---------------------------------------------------
function MapMediator:ctor( params, viewComponent )
	self.super:ctor(NAME, viewComponent)
	
	-- 初始化外部传参
	self.currentAreaId = gameMgr:GetAreaId()
    self.selectedDiffType = QUEST_DIFF_NORMAL
	if nil ~= params then
		self.currentAreaId = checkint(params.currentAreaId)
        if checkint(params.type) > 0 then
            self.selectedDiffType = checkint(params.type) --困难副本类型
        end
	end
	
end
function MapMediator:InterestSignals()
	local signals = {
		POST.QUEST_STORY.sglName,
		SIGNALNAMES.Quest_GetCityReward_Callback,
		SIGNALNAMES.Quest_DrawCityReward_Callback,
		"DRAW_CITY_STAR_REWARD",
		"SHOW_CITY_STAR_REWARD_DETAIL",
		"MAP_STAGE_CLICK_EVENT",
		"MAP_PLOT_CLICK_EVENT"
	}
	return signals
end
function MapMediator:Initial( key )
	self.super.Initial(self,key)
end
function MapMediator:ProcessSignal( signal )
	local name = signal:GetName()
	local responseData = signal:GetBody()

	if POST.QUEST_STORY.sglName == name then
		
		local rewards = responseData.rewards or {}
		if next(rewards) ~= nil then
			uiMgr:AddDialog('common.RewardPopup', {rewards = rewards})
		end
		local requestData = responseData.requestData or {}
		gameMgr:GetUserInfo().questStory[tostring(requestData.storyId)] = requestData.storyId
		-- reload init
		app.badgeMgr:RemovePlotRemindData(requestData)

	elseif SIGNALNAMES.Quest_GetCityReward_Callback == name then

		local chapterId = self:GetCurrentSelectedChapterId()
		-- 获取满星奖励信息成功
		local tag = 1005
		if nil == self:GetViewComponent():GetDialogByTag(1005) then
			local star = 0
			if self.starNumDatas[tostring(chapterId)] and self.starNumDatas[tostring(chapterId)][tostring(self.selectedDiffType)] then
				star = self.starNumDatas[tostring(chapterId)][tostring(self.selectedDiffType)]
			end
			local starRewardsData = nil
			if nil ~= CommonUtils.GetConfig('quest', 'city', chapterId).rewards then
				starRewardsData = CommonUtils.GetConfig('quest', 'city', chapterId).rewards[tostring(self.selectedDiffType)]
			end
			local layer = require('Game.views.StarRewardPopup').new({
				mediatorName = NAME,
				tag = tag,
				starRewardsData = starRewardsData,
				star = star,
				serverRewardsData = responseData.cityRewards,
				chapterId = chapterId,
				diffType = self.selectedDiffType
			})
			display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
			layer:setTag(tag)
			self:GetViewComponent():AddDialog(layer)
		end

	elseif SIGNALNAMES.Quest_DrawCityReward_Callback == name then
		-- 领取满星奖励成功
		uiMgr:AddDialog('common.RewardPopup', {rewards = responseData.rewards})
		if self.drawCityRewardCallback then
			self.drawCityRewardCallback()
		end

		-- 减去本地小红点计数
		gameMgr:RefreshCityRewardNotDrawnDataByChapterId(responseData.requestData.cityId, self.selectedDiffType, -1)
		-- 刷新一次本章满星奖励小红点
		self:RefreshStarRewardRemindIcon(self:GetCurrentSelectedChapterId())

	elseif "DRAW_CITY_STAR_REWARD" == name then

		-- 请求领取满星奖励
		self:SendSignal(COMMANDS.COMMAND_Quest_Draw_City_Reward, responseData.requestData)
		self.drawCityRewardCallback = responseData.callback

	elseif "SHOW_CITY_STAR_REWARD_DETAIL" == name then

		-- 显示扫荡选择弹窗
		self:ShowCityStarRewardDetail(responseData.rewards)

	elseif "MAP_STAGE_CLICK_EVENT" == name then

		-- 地图点点击事件
		self:EnterStage(responseData)
	
	elseif "MAP_PLOT_CLICK_EVENT" == name then
		
		-- 地图点点击事件
		self:EnterPlot(responseData)

	end
end
-- function MapMediator:showCommentView(taget, single)

-- end
function MapMediator:OnRegist()
	-- 初始化数据
	self:InitialDatas()

    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "show")
	-- 创建地图界面
	local scene = uiMgr:SwitchToTargetScene("Game.views.map.MapView", {chapterId = 1})
	self:SetViewComponent(scene)
	self:InitialActions()
	self:SetDoubleActivity()
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Quest_Get_City_Reward, MapCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Quest_Draw_City_Reward, MapCommand)
	regPost(POST.QUEST_STORY)

	-- 初始化战斗网络管理器
	self.BNetworkMediator = AppFacade.GetInstance():RetrieveMediator('BattleNetworkMediator')
	if not self.BNetworkMediator then
		local BattleNetworkMediator = require('battleEntry.network.BattleNetworkMediator')
		self.BNetworkMediator = BattleNetworkMediator.new()
		self:GetFacade():RegistMediator(self.BNetworkMediator)
	end

    --引导下一步事件发送
    local newestQuestId = checkint(gameMgr:GetUserInfo().newestQuestId)
	local currentQuestId = checkint(gameMgr:GetUserInfo().currentQuestId)
	
	-- fixed guide
	local cardTeamStepId = checkint(GuideUtils.GetModuleData(GUIDE_MODULES.MODULE_TEAM))
	if not GuideUtils.IsGuiding() and cardTeamStepId == 0 and not GuideUtils.CheckIsFinishedQuest1({dontShowTips = true}) then
		GuideUtils.GetDirector():FinishLocalModule(GUIDE_MODULES.MODULE_LOBBY)
		GuideUtils.GetDirector():FinishLocalModule(GUIDE_MODULES.MODULE_DRAWCARD)
		GuideUtils.SwitchModule(GUIDE_MODULES.MODULE_TEAM, 75)
	else
		GuideUtils.DispatchStepEvent()
	end
	
        --如果是第一次打关卡
    if gameMgr:GetUserInfo().isFirstGuide then
        gameMgr:GetUserInfo().isFirstGuide = false
		--如果是第一次打第一关，弹出一个剧情页面
		local operaArgs = {id = 10, cb = function(sender)
            --升级奖励的逻辑
            local UpgradeLevelMediator = require('Game.mediator.UpgradeLevelMediator')
            local mediator = UpgradeLevelMediator.new({})
            self:GetFacade():RegistMediator(mediator)
		end}
		if GAME_MODULE_OPEN.NEW_PLOT then
			operaArgs.path = string.format('conf/%s/plot/story0.json', i18n.getLang())
			operaArgs.id   = 10
		end
		local stage = require('Frame.Opera.OperaStage').new(operaArgs)
        stage:setPosition(cc.p(display.cx,display.cy))
        sceneWorld:addChild(stage, GameSceneTag.Dialog_GameSceneTag)
    end

end

function MapMediator:OnUnRegist()
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Quest_Get_City_Reward)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Quest_Draw_City_Reward)
	unregPost(POST.QUEST_STORY)
end
---------------------------------------------------
-- mediator extend end --
---------------------------------------------------

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化数据
--]]
function MapMediator:InitialDatas()
	self.currentAreaId = self.currentAreaId
	self.currentChapters = {}
	self.maxChapters = 0
	self.cityStarRewardsData = {}
	------------ 根据区域信息初始化章节信息 ------------
	local areaConf = CommonUtils.GetConfig('common', 'area', self.currentAreaId)

	local cityId = nil
	for i,v in ipairs(areaConf.cities) do
		cityId = checkint(v)
		table.insert(self.currentChapters, cityId)
	end
	self.maxChapters = #self.currentChapters
	------------ 根据区域信息初始化章节信息 ------------

	------------ 初始化星级奖励数据 ------------
	-- 星级信息 二维 章节-关卡
	self.starDatas = {}
	-- 星级数量信息
	self.starNumDatas = {}
	local allStarInfo = gameMgr:GetUserInfo().questGrades
	local chapterStarInfo = nil
	local chapterId = nil
	local stageConf = nil
	for i,v in ipairs(self.currentChapters) do
		chapterId = v
		self.starDatas[tostring(chapterId)] = {}
		self.starNumDatas[tostring(chapterId)] = {}
		chapterStarInfo = allStarInfo[tostring(chapterId)]
		
		if nil ~= chapterStarInfo then
			for stageId_, grade_ in pairs(chapterStarInfo.grades) do
				-- 插入星级信息
				self.starDatas[tostring(chapterId)][tostring(stageId_)] = checkint(grade_)
				-- 判断是否需要插入满星数量
				stageConf = CommonUtils.GetConfig('quest', 'quest', stageId_)
				
				if nil == stageConf then
					print('[warning] \n 	[you have stage star data in server but local config can not find stage ---> stage id: ' .. stageId_ .. ']')
				else
					-- 1 可以复刷
					-- print('here check 3star >>>>>>>>', chapterId, stageId_, grade_, stageConf.repeatChallenge)
					if QuestRechallenge.QR_CAN == checkint(stageConf.repeatChallenge) then
						-- 可以复刷的关卡插入星级数量
						if nil == self.starNumDatas[tostring(chapterId)][tostring(stageConf.difficulty)] then
							self.starNumDatas[tostring(chapterId)][tostring(stageConf.difficulty)] = 0
						end
						self.starNumDatas[tostring(chapterId)][tostring(stageConf.difficulty)] = self.starNumDatas[tostring(chapterId)][tostring(stageConf.difficulty)] + checkint(grade_)
					end
				end
			end
		end
	end
	------------ 初始化星级奖励数据 ------------

	self.selectedChapterIdx = 0
	self.newestStageId = 0
	-- 网络回调
	self.changePlayerSkillCallback = nil
	self.drawCityRewardCallback = nil

	-- 当前区域 全剧情点检测
	app.badgeMgr:CheckAreaPlotRemindAt(self.currentAreaId)
end
function MapMediator:SetDoubleActivity()
	local data = {}
	if self.selectedDiffType == QUEST_DIFF_NORMAL then
		data = app.activityMgr:GetActivityDataByType(ACTIVITY_TYPE.DOUNBLE_EXP_NORMAL)
	elseif self.selectedDiffType == QUEST_DIFF_HISTORY or 	self.selectedDiffType == QUEST_DIFF_HARD  then
		data = app.activityMgr:GetActivityDataByType(ACTIVITY_TYPE.DOUNBLE_EXP_HARD)
	end
	if #data  > 0  then
		---@type MapView
		local viewComponent = self:GetViewComponent()
		local viewData = viewComponent.viewData
		if viewData.doubleExpTwoImage then
			viewData.doubleExpTwoImage:setVisible(true)
		end
	end
end
--[[
初始化viewComponent中内容
--]]
function MapMediator:InitialActions( )
	local view = self:GetViewComponent()
	-- 初始化地图page
	view.viewData.mapPageView:setCountOfCell(self.maxChapters)
	view.viewData.mapPageView:setDataSourceAdapterScriptHandler(handler(self, self.MapPageViewDataAdapter))
	view.viewData.mapPageView:setOnPageChangedScriptHandler(handler(self, self.MapPageViewChangedHandler))

    if checkint(gameMgr:GetUserInfo().newestQuestId) <= 2 then
        view.viewData.mapPageView:setDragable(false)
    end
	-- 返回按钮回调
	view.viewData.backBtn:setOnClickScriptHandler(function(sender)
        -- 同时销毁战斗网络管理器
        sender:setEnabled(false)
        PlayAudioClip(AUDIOS.UI.ui_change.id)
		self:GetFacade():UnRegsitMediator("BattleNetworkMediator")
		self:GetFacade():UnRegsitMediator("MapMediator")

        self:GetFacade():RetrieveMediator("Router"):Dispatch({name = "MapMediator"},
			{name = "HomeMediator"})
		self:GetFacade():RetrieveMediator("Router"):RegistBackMediators()
        GuideUtils.DispatchStepEvent()
	end)

	-- 翻页按钮回调
	display.commonUIParams(view.viewData.prevBtn, {cb = handler(self, self.ChangeChapterBtnCallback)})
	display.commonUIParams(view.viewData.nextBtn, {cb = handler(self, self.ChangeChapterBtnCallback)})

	-- 难度按钮回调
    --[[
	for i,v in ipairs(view.viewData.diffButtons) do
		display.commonUIParams(v, {cb = handler(self, self.DiffBtnCallback)})
	end
    --]]

	-- 满星奖励回调
	display.commonUIParams(view.viewData.starRewardBtn, {cb = handler(self, self.StarRewardsCallback), animate = true})

	------------ 判断玩家本次游戏缓存的选择关卡 ------------
	local localCurQuestId = gameMgr:GetUserInfo().localCurrentQuestId
	local localCurChapterDiff = self.selectedDiffType
	local currentChapterId = 0

	if 0 ~= localCurQuestId then
		local stageConf = CommonUtils.GetQuestConf(localCurQuestId)
		local chapterConf = CommonUtils.GetConfig('quest', 'city', checkint(stageConf.cityId))

		if self.currentAreaId == checkint(chapterConf.areaId) and localCurChapterDiff == checkint(stageConf.difficulty) then

			-- 缓存的关卡是当前难度当前区域
			currentChapterId = checkint(stageConf.cityId)

		else

			-- 缓存的关卡不是当前区域
			currentChapterId = self:GetCanEnterChapterIdByDifficulty(self.selectedDiffType)

		end

	else

		-- 缓存的关卡不是当前区域
		currentChapterId = self:GetCanEnterChapterIdByDifficulty(self.selectedDiffType)


	end

	-- 如果计算的最新章节不在本区域 取本区域最后进度的章节
	local chapterInThisArea = false
	for i,v in ipairs(self.currentChapters) do
		if currentChapterId == checkint(v) then
			chapterInThisArea = true
			break
		end
	end

	local tempChapterId = 0
	-- 新剧情开启 并且 没有缓存关卡点
	if app.gameMgr:IsOpenMapPlot() and 0 == localCurQuestId then
		local plotRemindDatas = gameMgr:GetUserInfo().plotRemindDatas
		local chapterIds = plotRemindDatas[tostring(self.currentAreaId)]
		if chapterIds and next(chapterIds) then
			tempChapterId = 999999
			for chapterId, questId in pairs(chapterIds) do
				tempChapterId = math.min(checkint(chapterId), tempChapterId)
			end
		end

	end
	
	if not chapterInThisArea and tempChapterId == 0 then
		-- 根据难度取最新关卡id 再取最新章节id
		local newestStageId = 0
		if DifficultyLevel.Normal == self.selectedDiffType then
			newestStageId = gameMgr:GetUserInfo().newestQuestId
		elseif DifficultyLevel.Hard == self.selectedDiffType then
			newestStageId = gameMgr:GetUserInfo().newestHardQuestId
		elseif DifficultyLevel.History == self.selectedDiffType then
			newestStageId = gameMgr:GetUserInfo().newestInsaneQuestId
		end
		local newestStageConfig = CommonUtils.GetQuestConf(newestStageId)
		if nil ~= newestStageConfig then
			for i,v in ipairs(self.currentChapters) do
				currentChapterId = math.min(checkint(v), checkint(newestStageConfig.cityId))
			end
		else
			-- 刷新为本区域最新关卡
			currentChapterId = self.currentChapters[self.maxChapters]
		end
	else
		for i, chapterId in ipairs(self.currentChapters) do
			if tempChapterId == checkint(chapterId) then
				currentChapterId = tempChapterId
				break
			end
		end
	end
	self:RefreshMap(currentChapterId, self.selectedDiffType)
	------------ 判断玩家本次游戏缓存的选择关卡 ------------

	-- local diffType = 0
	-- local newestChapterId = 0
	-- local localCurQuestId = gameMgr:GetUserInfo().localCurrentQuestId
	-- if 0 == localCurQuestId then
	-- 	-- 初始化一次最新关卡
	-- 	diffType = DifficultyLevel.Normal
	-- 	newestChapterId = self:GetCanEnterChapterIdByDifficulty(diffType)
	-- else
	-- 	-- 本地有缓存 直接走本地的
	-- 	local stageConf = CommonUtils.GetConfig('quest', 'quest', localCurQuestId)
	-- 	newestChapterId = checkint(stageConf.cityId)
	-- 	diffType = checkint(stageConf.difficulty)
	-- end
	-- -- 如果最新章节不在本区域 则跳转到本区域最后章节
	-- local maxChapterId = self.currentChapters[#self.currentChapters]
	-- if maxChapterId < newestChapterId then
	-- 	newestChapterId = maxChapterId
	-- 	diffType = DifficultyLevel.Normal
	-- end

	-- -- 刷新界面
 --    local chapterId, errorLog = self:GetCanEnterChapterIdByDifficulty(self.selectedDiffType)
 --    if chapterId > 0 then
 --        self:RefreshMap(chapterId, self.selectedDiffType)
 --    else
 --        local CommonTip = require( 'common.CommonTip' ).new({text = errorLog, hideAllButton = true})
 --        CommonTip:setPosition(display.center)
 --        AppFacade.GetInstance():GetManager("UIManager"):GetCurrentScene():AddDialog(CommonTip)
 --    end

	-- self:RefreshMap(newestChapterId, self.selectedDiffType)

end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
page cell 回调
--]]
function MapMediator:MapPageViewDataAdapter(c, i)
	local cell = c
	local index = i + 1
	local chapterId = self:GetChapterIdByPageIndex(index)
	local mapData = {
		chapterId = chapterId,
		diffType = self.selectedDiffType,
		starDatas = checktable(self.starDatas[tostring(chapterId)]),
		newestStageId = self.newestStageId
	}
	xTry(function()
		if nil == cell then
		cell = require('Game.views.map.MapPageViewCell').new({
			size = self:GetViewComponent().viewData.mapPageView:getContentSize()
		})
		end

		cell:setTag(index)
		cell:RefresUI(mapData)
	end, function()
		__G__TRACKBACK__(debug.traceback())
		cell = CPageViewCell:new()
	end)


	return cell
end
--[[
page view 翻页回调
--]]
function MapMediator:MapPageViewChangedHandler(sender, i)
	self.selectedChapterIdx = i + 1
	self:RefreshUIInfo()
	self:RefreshChangeChapterBtnState()
end
--[[
根据难度和章节刷新界面
@params chapterId int 章节
@params diffType DifficultyLevel 难度
--]]
function MapMediator:RefreshMap(chapterId, diffType)
	if chapterId == self:GetCurrentSelectedChapterId() and diffType == self.selectedDiffType then return  end

	if diffType then
		self.selectedDiffType = diffType
		if DifficultyLevel.Normal == self.selectedDiffType then
			self.newestStageId = gameMgr:GetUserInfo().newestQuestId
		elseif DifficultyLevel.Hard == self.selectedDiffType then
			self.newestStageId = gameMgr:GetUserInfo().newestHardQuestId
		elseif DifficultyLevel.History == self.selectedDiffType then
			self.newestStageId = gameMgr:GetUserInfo().newestInsaneQuestId
		end
	end

	if chapterId then
		self.selectedChapterIdx = self:GetPageIndexByChapterId(chapterId)
		self:RefreshChangeChapterBtnState()
	end

	self:RefreshUIInfo()

	-- 刷新难度按钮
    --[[
	for i,v in ipairs(self:GetViewComponent().viewData.diffButtons) do
		v:getChildByTag(3):setVisible(not (v:getTag() == self.selectedDiffType))
	end
    --]]

	self:GetViewComponent().viewData.mapPageView:reloadData()
	self:JumpToPageByChapterId(chapterId)

end
--[[
跳转界面到指定关卡
@params stageId int 关卡id
--]]
function MapMediator:JumpToPageByStageId(stageId)
	local stageConf = CommonUtils.GetConfig('quest', 'quest', localCurQuestId)
	if not stageConf then return end
	self:JumpToPageByChapterId(checkint(stageConf.cityId))
end
--[[
跳转界面到指定章节
@params chapterId int 章节id
--]]
function MapMediator:JumpToPageByChapterId(chapterId)
	local pageSize = self:GetViewComponent().viewData.mapPageView:getContentSize()
	local offsetX = - pageSize.width * (self:GetPageIndexByChapterId(chapterId) - 1)
	self:GetViewComponent().viewData.mapPageView:setContentOffset(cc.p(offsetX, 0))
end
--[[
翻页按钮回调
2001 上一页
2002 下一页
--]]
function MapMediator:ChangeChapterBtnCallback(sender)
	PlayAudioByClickNormal()
	local tag = sender:getTag()
	if 2001 == tag then
		self.selectedChapterIdx = math.max(1, self.selectedChapterIdx - 1)
		self:JumpToPageByChapterId(self:GetCurrentSelectedChapterId())
	elseif 2002 == tag then
		local nextChapterId = math.min(self.maxChapters, self.selectedChapterIdx + 1)
		self.selectedChapterIdx = nextChapterId
		self:JumpToPageByChapterId(self:GetCurrentSelectedChapterId())
		-- local canEnterNextChapter, errorLog = self:CanEnterByChapterId(nextChapterId, self.selectedDiffType)
		-- if canEnterNextChapter then
		-- 	self.selectedChapterIdx = nextChapterId
		-- 	self:JumpToPageByChapterId(self.selectedChapterIdx)
		-- else
		-- 	local CommonTip = require( 'common.CommonTip' ).new({text = errorLog, isOnlyOK = true})
		-- 	CommonTip:setPosition(display.center)
		-- 	AppFacade.GetInstance():GetManager("UIManager"):GetCurrentScene():AddDialog(CommonTip)
		-- end
	end
	self:RefreshChangeChapterBtnState()
end
--[[
更新翻页按钮状态
--]]
function MapMediator:RefreshChangeChapterBtnState()
	local prevBtn = self:GetViewComponent().viewData.prevBtn
	local nextBtn = self:GetViewComponent().viewData.nextBtn
	prevBtn:setVisible(not (1 == self.selectedChapterIdx))
	nextBtn:setVisible(not (self.maxChapters == self.selectedChapterIdx))
end
--[[
难度按钮回调
--]]
function MapMediator:DiffBtnCallback(sender)
	PlayAudioByClickNormal()
	local diffType = sender:getTag()
	if self.selectedDiffType == diffType then return end

	-- 判断是否能跳转
	local unlockDifficulty = CommonUtils.UnLockModule(RemindTag.DIFFICULT_MAP,true)
	if unlockDifficulty then
		local chapterId, errorLog = self:GetCanEnterChapterIdByDifficulty(diffType)
		if chapterId > 0 then
			self:RefreshMap(chapterId, diffType)
		else
			local CommonTip = require( 'common.CommonTip' ).new({text = errorLog, hideAllButton = true})
			CommonTip:setPosition(display.center)
			AppFacade.GetInstance():GetManager("UIManager"):GetCurrentScene():AddDialog(CommonTip)
		end
	end
end
--[[
刷新ui信息
--]]
function MapMediator:RefreshUIInfo()
	local chapterId = self:GetCurrentSelectedChapterId()
	-- 刷新地图标题版
	local cityConf = CommonUtils.GetConfig('quest', 'city', chapterId)
	--self:GetViewComponent().viewData.tabNameLabel:getLabel():setString(cityConf.name)
	if CommonUtils.IsGoldSymbolToSystem() then
		CommonUtils.SetCardNameLabelStringByIdUseSysFont(self:GetViewComponent().viewData.tabNameLabel:getLabel() , nil ,{fontSizeN = 28 ,colorN = '473227' } ,  cityConf.name)
		display.commonLabelParams(self:GetViewComponent().viewData.tabNameLabel:getLabel(),{reqW = 250 })
	else
		display.commonLabelParams(self:GetViewComponent().viewData.tabNameLabel:getLabel(),{text = cityConf.name ,reqW = 250 })

	end


	-- 刷新三星数量
	local star = 0
	if self.starNumDatas[tostring(chapterId)] and self.starNumDatas[tostring(chapterId)][tostring(self.selectedDiffType)] then
		star = self.starNumDatas[tostring(chapterId)][tostring(self.selectedDiffType)]
	end
	local totalStar = 0
	local stageConf = nil

	for i,v in pairs(cityConf.quests[tostring(self.selectedDiffType)]) do
		stageConf = CommonUtils.GetQuestConf(checkint(v))
		if nil ~= stageConf and QuestRechallenge.QR_CAN == checkint(stageConf.repeatChallenge) then
			totalStar = totalStar + table.nums(stageConf.allClean)
		end
	end
	self:GetViewComponent().viewData.starsLabel:setString(string.format('%02d/%02d',
		star,
		totalStar)
	)

	-- 刷新满星奖励小红点
	self:RefreshStarRewardRemindIcon(chapterId)
end
--[[
显示星级奖励预览
@params rewards table 奖励集
--]]
function MapMediator:ShowCityStarRewardDetail(rewards)
	local tag = dialogueTags.starRewardDetailTag
	local layer = require('common.RewardDetailPopup').new({tag = tag, rewards = rewards})
	display.commonUIParams(layer, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
	layer:setTag(tag)
	uiMgr:GetCurrentScene():AddDialog(layer)
end
--[[
刷新满星奖励小红点
@params chapterId int 章节id
--]]
function MapMediator:RefreshStarRewardRemindIcon(chapterId)
	local rewardAmount = gameMgr:GetCityRewardNotDrawnAmount(chapterId, self.selectedDiffType)
	local show = 0 ~= rewardAmount
	self:GetViewComponent():ShowStarRewardRemindIcon(show)
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- callback begin --
---------------------------------------------------
--[[
关卡点击事件
@params data table {
	stageId int 关卡id
}
--]]
function MapMediator:EnterStage(data)
	local stageId = checkint(data.stageId)
	local stageConf = CommonUtils.GetConfig('quest', 'quest', stageId) or {}

	--------------- 可行性判断 ---------------
	if self.newestStageId < stageId then

		uiMgr:ShowInformationTips(__('还未达到该关卡'))
		return

	elseif self.newestStageId == stageId then



	else

		if QuestRechallenge.QR_CAN ~= checkint(stageConf.repeatChallenge) then
			-- uiMgr:ShowInformationTips(__('无法重复挑战'))

			local stageTitleStr   = ''
			local questBattleType = CommonUtils.GetQuestBattleByQuestId(stageId)
			if QuestBattleType.MAP == questBattleType then
				-- stageTitleStr = string.format('%s-%s %s', tostring(stageConf.cityId), tostring(stageConf.position), tostring(stageConf.name))
				stageTitleStr = string.format('%s', tostring(stageConf.name))

			elseif QuestBattleType.ACTIVITY_QUEST == CommonUtils.GetQuestBattleByQuestId(stageId) then
				stageTitleStr = string.format('%s', tostring(stageConf.name))

			elseif QuestBattleType.ARTIFACT_ROAD == CommonUtils.GetQuestBattleByQuestId(stageId) then
				stageTitleStr = string.format('%s', tostring(stageConf.name))
			end

			AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.QuestComment_CommentView, {
				stageId        = stageId,
				stageTitleText = stageTitleStr
			})
			return
		end

	end

	-- 判断是否可以进入该关卡
	local canEnterStage, waringStr = self:CanEnterByStageId(stageId)
	if not canEnterStage then
		uiMgr:ShowInformationTips(waringStr)
		return
	end
	--------------- 可行性判断 ---------------

	self:ShowEnterStageView(stageId)
end
--[[
关卡点击回调
@params stageId int 关卡id
--]]
function MapMediator:ShowEnterStageView(stageId)
	PlayAudioByClickNormal()
	local stageConf = CommonUtils.GetConfig('quest', 'quest', stageId)
	local questType = checkint(stageConf.questType)
	local battleReadyViewZOrder = self:GetViewComponent().TAGS.TagDialogLayer

	--------------- 初始化战斗传参 ---------------
	local battleReadyData = BattleReadyConstructorStruct.New(
		2,
		gameMgr:GetUserInfo().localCurrentBattleTeamId,
		gameMgr:GetUserInfo().localCurrentEquipedMagicFoodId,
		stageId,
		CommonUtils.GetQuestBattleByQuestId(stageId),
		nil,
		POST.QUEST_AT.cmdName,
		{questId = stageId},
		POST.QUEST_AT.sglName,
		POST.QUEST_GRADE.cmdName,
		{questId = stageId},
		POST.QUEST_GRADE.sglName,
		NAME,
		NAME
	)
	--------------- 初始化战斗传参 ---------------
	local chapterId = self:GetCurrentSelectedChapterId()
	if questType ~= QUEST_TYPE_TREASURE then
		--如果不是宝箱的逻辑
		local tag = 1001
		local star = 0
		if self.starDatas[tostring(chapterId)] and self.starDatas[tostring(chapterId)][tostring(stageId)] then
			star = checkint(self.starDatas[tostring(chapterId)][tostring(stageId)])
		end
		if checkint(stageConf.hasPlot) == 1 then
			local stage = require( "Frame.Opera.OperaStage" ).new({id = stageId, cb = function(tag)
				if tag == 3006 or tag == 3007 then
					--出弹出框
					local layer = require('Game.views.BattleReadyView').new(battleReadyData)
					layer:setPosition(cc.p(display.cx,display.cy))
					uiMgr:GetCurrentScene():addChild(layer, battleReadyViewZOrder - 1)

				end
			end})
			stage:setPosition(cc.p(display.cx,display.cy))
            sceneWorld:addChild(stage, GameSceneTag.Dialog_GameSceneTag)
		else
			local layer = require('Game.views.BattleReadyView').new(battleReadyData)
			layer:setPosition(cc.p(display.cx,display.cy))
			uiMgr:GetCurrentScene():addChild(layer, battleReadyViewZOrder - 1)
		end
	else
		if self.newestStageId <= stageId then
			--出弹出框
			local star = 0
			if self.starDatas[tostring(chapterId)] and self.starDatas[tostring(chapterId)][tostring(stageId)] then
				star = checkint(self.starDatas[tostring(chapterId)][tostring(stageId)])
			end
			local layer = require('Game.views.BattleReadyView').new(battleReadyData)
			-- local layer = require('Game.views.BattleReadyView').new({battleType = 1})
			layer:setPosition(cc.p(display.cx,display.cy))
			uiMgr:GetCurrentScene():addChild(layer, battleReadyViewZOrder - 1)
		end
	end
    GuideUtils.DispatchStepEvent()
end

--[[
剧情点击事件
@params data table {
	stageId int 关卡id
}
--]]
function MapMediator:EnterPlot(data)
	local stageId = checkint(data.stageId)
	--------------- 可行性判断 ---------------
	if not gameMgr:JudgePassedStageByStageId(stageId) then
		uiMgr:ShowInformationTips(string.format(__('还未达到%s'), tostring(data.stageName)))
		return
	end
	
	local questPlotId        = checkint(data.questPlotId)
	local storyRewardConf    = CommonUtils.GetConfig("plot", "storyReward", questPlotId) or {}
	local plotStoryConfs     = CommonUtils.GetConfigAllMess(string.format('story%s', tostring(storyRewardConf.areaId)), 'plot') or {}
	local storyFinishFunc    = function(tag)
		-- 1.检查剧情是否被跳过
		if not app.gameMgr:GetUserInfo().questStory[tostring(questPlotId)] then
			local data = {storyId = questPlotId, questId = storyRewardConf.unlock, areaId = storyRewardConf.areaId, chapterId = storyRewardConf.chapterId}
			self:SendSignal(POST.QUEST_STORY.cmdName, data)
		end
	end
	
	if next(plotStoryConfs) == nil then
		storyFinishFunc()
	else
		local stage = require( "Frame.Opera.OperaStage" ).new({id = storyRewardConf.id, path = string.format("conf/%s/plot/story%s.json", i18n.getLang(), storyRewardConf.areaId), 
			guide = false, isHideBackBtn = true, cb = storyFinishFunc})
		stage:setPosition(cc.p(display.cx,display.cy))
		sceneWorld:addChild(stage, GameSceneTag.Dialog_GameSceneTag)
	end
end

--[[
满星奖励回调
--]]
function MapMediator:StarRewardsCallback(sender)
	self:SendSignal(COMMANDS.COMMAND_Quest_Get_City_Reward, {cityId = self:GetCurrentSelectedChapterId(), difficulty = self.selectedDiffType})
end
---------------------------------------------------
-- callback end --
---------------------------------------------------

---------------------------------------------------
-- config expression begin --
---------------------------------------------------
--[[
判断是否可以进入某一关
@params stageId int 关卡id
@return _ bool 是否可以进入 _ str 不能进入的错误提示
--]]
function MapMediator:CanEnterByStageId(stageId)
	local stageConf = CommonUtils.GetConfig('quest', 'quest', stageId)
	-- 锁章节不锁关卡 如果本章解锁 本章所有关卡都解锁
	return self:CanEnterByChapterId(checkint(stageConf.cityId), checkint(stageConf.difficulty))
end
--[[
判断是否可以进入某一章
@params chapterId int 章节id
@params diffType DifficultyLevel 难度
@return _ bool 是否可以进入 _ str 不能进入的错误提示
--]]
function MapMediator:CanEnterByChapterId(chapterId, diffType)
	local cityConf = CommonUtils.GetConfig('quest', 'city', chapterId)
	if nil == cityConf then return false, string.format(__('章节%d数据不存在'), chapterId) end
	local unlockLimitConf = cityConf.unlock[tostring(diffType)]
	if unlockLimitConf then
		-- 角色等级限制
		local playerLevelLimitConf = unlockLimitConf[1]
		if playerLevelLimitConf then
			if checkint(playerLevelLimitConf) > gameMgr:GetUserInfo().level then

				return false, string.format(__('解锁%s第%d章需要玩家等级达到%d并通过前一章的最后一关'), DifficultyLevelDescr[diffType], checkint(chapterId), checkint(playerLevelLimitConf))

			end
		end
		-- 关卡限制
		local stageLimitConf = unlockLimitConf[2]
		if stageLimitConf then
			local stageLimitConf_ = checkint(stageLimitConf)
			if not (gameMgr:GetUserInfo().newestQuestId > stageLimitConf_ or
				gameMgr:GetUserInfo().newestHardQuestId > stageLimitConf_ or
				gameMgr:GetUserInfo().newestInsaneQuestId > stageLimitConf_) then

				local stageConf = CommonUtils.GetConfig('quest', 'quest', stageLimitConf_)
				return false, string.format(__('解锁%s第%d章需要通过%d-%d'), DifficultyLevelDescr[diffType], checkint(chapterId),checkint(chapterId), checkint(stageConf.position))

			end
		end
	end
	return true
end
--[[
获取当前难度玩家的最新能进入的章节
@params diffType DifficultyLevel 难度
@return _ int 章节id, _ 错误信息
--]]
function MapMediator:GetCanEnterChapterIdByDifficulty(diffType)
	gameMgr:UpdatePlayerNewestQuestId()
	local chapterId = 0
	local newestStageId = 0
	if DifficultyLevel.Normal == diffType then
		newestStageId = gameMgr:GetUserInfo().newestQuestId
	elseif DifficultyLevel.Hard == diffType then
		newestStageId = gameMgr:GetUserInfo().newestHardQuestId
	elseif DifficultyLevel.History == diffType then
		newestStageId = gameMgr:GetUserInfo().newestInsaneQuestId
	end
	if newestStageId == 0 then
		-- 此情况为未能解锁第一个困难关卡
		local result, errorLog = CommonUtils.CanEnterChapterByChapterIdAndDiff(1, diffType)
		if result then
			return 0, '本地数据出错'
		else
			return 0, errorLog
		end
	end
	local stageConf = CommonUtils.GetConfig('quest', 'quest', newestStageId)
	if not stageConf then
		print('[warning] \n 	[you have stage star data in server but local config can not find stage ---> stage id: ' .. newestStageId .. ']')
		return 1, 1
	else
		chapterId = checkint(stageConf.cityId)
		local result, resultStr = self:CanEnterByStageId(newestStageId)
		if false == result then
			print('\n\nwaring>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>\n', resultStr, '\n\n')
			return chapterId, resultStr
		else
			return chapterId
		end
	end
end
---------------------------------------------------
-- config expression end --
---------------------------------------------------

---------------------------------------------------
-- local check begin --
---------------------------------------------------
--[[
获取当前选择的章节id
@return _ int 当前选择的章节id
--]]
function MapMediator:GetCurrentSelectedChapterId()
	return self:GetChapterIdByPageIndex(self.selectedChapterIdx)
end
--[[
根据页序号获取章节id
@params index int 页序号
@return _ int 章节id
--]]
function MapMediator:GetChapterIdByPageIndex(index)
	return self.currentChapters[index]
end
--[[
根据章节id获取当前页序号
@params chapterId int 章节id
@return _ int 页序号
--]]
function MapMediator:GetPageIndexByChapterId(chapter)
	for i,v in ipairs(self.currentChapters) do
		if v == checkint(chapter) then
			return i
		end
	end
	return 1
end
---------------------------------------------------
-- local check end --
---------------------------------------------------

return MapMediator
