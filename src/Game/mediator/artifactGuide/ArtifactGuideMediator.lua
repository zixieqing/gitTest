--[[
 * author : liuzhipeng
 * descpt : 神器引导 Mediator
--]]
local Mediator = mvc.Mediator

local ArtifactGuideMediator = class("ArtifactGuideMediator", Mediator)

local NAME = "artifactGuide.ArtifactGuideMediator"
local ArtifactGuideCell = require('Game.views.artifactGuide.ArtifactGuideCell')

function ArtifactGuideMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	local homeData = checktable(params)
	self:SetHomeData(homeData)
	self.firstRefresh = true
end
-------------------------------------------------
------------------ inheritance ------------------
function ArtifactGuideMediator:Initial( key )
	self.super.Initial(self,key)
	local viewComponent  = require( 'Game.views.artifactGuide.ArtifactGuideView' ).new()
	viewComponent:setPosition(display.center)
	app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
	self:SetViewComponent(viewComponent)
	
	-- 绑定
	viewComponent.eaterLayer:setOnClickScriptHandler(handler(self, self.CloseButtonCallback))
	viewComponent:GetViewData().taskGridView:setDataSourceAdapterScriptHandler(handler(self, self.TaskGridViewDataSource))
	-- 刷新页面
	self:RefreshView()
end

function ArtifactGuideMediator:InterestSignals()
	local signals = { 
		POST.ARTIFACT_GUIDE_HOME.sglName,
		POST.ARTIFACT_GUIDE_REWARD_DRAW.sglName,
		POST.ARTIFACT_GUIDE_FINAL_REWARD_DRAW.sglName,
	}
	return signals
end

function ArtifactGuideMediator:ProcessSignal( signal )
	local name = signal:GetName() 
	local body = signal:GetBody()
	print(name)
	if name == POST.ARTIFACT_GUIDE_HOME.sglName then -- home 
		self:SetHomeData(body)
		self:RefreshView()
	elseif name == POST.ARTIFACT_GUIDE_REWARD_DRAW.sglName then -- 任务奖励
		app.uiMgr:AddDialog('common.RewardPopup', {rewards = body.rewards, closeCallback = handler(self, self.CheckFinalRewardsCanDraw)})
		-- 更新本地数据
		local homeData = self:GetHomeData()
		for i, v in ipairs(homeData.tasks) do
			if checkint(v.id) == body.requestData.taskId then
				v.collected = 1
				break
			end
		end
		-- 刷新页面
		self:RefreshView()
	elseif name == POST.ARTIFACT_GUIDE_FINAL_REWARD_DRAW.sglName then -- 最终奖励
		app.uiMgr:AddDialog('common.RewardPopup', {rewards = body.rewards})
		-- 更新本地数据
		local homeData = self:GetHomeData()
		homeData.finished = 1
		-- 刷新页面
		self:RefreshView()
		-- 更新gameMgr数据
		app.gameMgr:GetUserInfo().artifactGuide = 2
		-- 刷新主界面
		app:DispatchObservers(SGL.REFRES_ARTIFACT_GUIDE_ICON, { countdown = 0, tag = RemindTag.ARTIFACT_GUIDE})
	end
end

function ArtifactGuideMediator:OnRegist(  )
	regPost(POST.ARTIFACT_GUIDE_HOME)
	regPost(POST.ARTIFACT_GUIDE_REWARD_DRAW)
	regPost(POST.ARTIFACT_GUIDE_FINAL_REWARD_DRAW)
	self:CheckFinalRewardsCanDraw()
end

function ArtifactGuideMediator:OnUnRegist(  )
	print( "OnUnRegist" )
	unregPost(POST.ARTIFACT_GUIDE_HOME)
	unregPost(POST.ARTIFACT_GUIDE_REWARD_DRAW)
	unregPost(POST.ARTIFACT_GUIDE_FINAL_REWARD_DRAW)
	local scene = app.uiMgr:GetCurrentScene()
	scene:RemoveDialog(self.viewComponent)
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
--[[
关闭按钮点击回调
--]]
function ArtifactGuideMediator:CloseButtonCallback( sender )
	PlayAudioByClickNormal()
	app:UnRegsitMediator(NAME)
end
--[[
任务列表数据处理
--]]
function ArtifactGuideMediator:TaskGridViewDataSource( p_convertview, idx )
	local pCell = p_convertview
	local index = idx + 1
	local cSize = self:GetViewComponent():GetViewData().taskListCellSize
    if pCell == nil then
		pCell = ArtifactGuideCell.new(cSize)
		pCell.drawBtn:setOnClickScriptHandler(handler(self, self.TaskCellDrawButtonCallback))
    end
	xTry(function()
		local data = self:GetHomeData().tasks[index]
		local guideConfig = CommonUtils.GetConfig('artifact', 'guide', data.id)
		-- 刷新cell
		pCell.title:setString(guideConfig.name)
		pCell.descrLabel:setString(guideConfig.descr)
		local goodsData = guideConfig.rewards[1]
		pCell.goodsIcon:RefreshSelf({goodsId = goodsData.goodsId, amount = goodsData.num})
        pCell.goodsIcon.callBack = function ( sender ) 
            PlayAudioByClickNormal()
            AppFacade.GetInstance():GetManager("UIManager"):ShowInformationTipsBoard({targetNode = sender, iconId = goodsData.goodsId, type = 1})
        end
		-- 刷新按钮状态
		if checkint(data.collected) == 1 then
			-- 已领取
			pCell:ChangeDrawBtnState(3)
		else
			-- 未领取
			local progress = checkint(data.progress)
			local targetNum = checkint(guideConfig.targetNum)
			if progress >= targetNum then
				-- 可领取
				pCell:ChangeDrawBtnState(1)
			else
				-- 不可领取
				pCell:ChangeDrawBtnState(2, progress, targetNum)
			end
		end
		pCell.drawBtn:setTag(checkint(data.id))
	end,__G__TRACKBACK__)

	return pCell
end
--[[
任务列表按钮点击回调
--]]
function ArtifactGuideMediator:TaskCellDrawButtonCallback( sender )
	PlayAudioByClickNormal()
	local taskId = sender:getTag()
	local homeData = self:GetHomeData()
	local progress = nil
	for i, v in ipairs(homeData.tasks) do
		if checkint(v.id) == taskId then
			progress = checkint(v.progress)
			break
		end
	end
	local guideConfig = CommonUtils.GetConfig('artifact', 'guide', taskId)
	-- 判断按钮是跳转状态还是领取状态
	if progress >= checkint(guideConfig.targetNum) then
		-- 领取
		self:SendSignal(POST.ARTIFACT_GUIDE_REWARD_DRAW.cmdName, {taskId = taskId})
	else
		-- 跳转
		self:JumpToModule(guideConfig)
	end
	
end
--[[
检测最终奖励是否可领取
--]]
function ArtifactGuideMediator:CheckFinalRewardsCanDraw()
	local homeData = self:GetHomeData()
	for i,v in ipairs(homeData.tasks) do
		if checkint(v.collected) == 0 then
			return 
		end
	end
	self:SendSignal(POST.ARTIFACT_GUIDE_FINAL_REWARD_DRAW.cmdName)
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
刷新页面
--]]
function ArtifactGuideMediator:RefreshView()
	self:RefereshLeftLayout()
	self:RefreshRightLayout()
	self:RefreshRemindIcon()
end
--[[
刷新左侧layout
--]]
function ArtifactGuideMediator:RefereshLeftLayout()
	local homeData = self:GetHomeData()
	self:RefreshFinalRewards(homeData)
end
--[[
刷新最终奖励列表
@params homeData map {
	finished int  是否领取
	tasks    list 任务列表
}
--]]
function ArtifactGuideMediator:RefreshFinalRewards( homeData )
	local prizeConfig = CommonUtils.GetConfigAllMess('guidePrize', 'artifact')
	local viewComponent = self:GetViewComponent()
	local canDraw = true 
	for i, v in ipairs(homeData.tasks) do
		if checkint(v.collected) == 0 then
			canDraw = false
			break
		end
	end
	viewComponent:RefreshFinalRewards(checkint(homeData.finished) == 1, canDraw, prizeConfig)
end
--[[
刷新右侧layout
--]]
function ArtifactGuideMediator:RefreshRightLayout()
	local homeData = self:GetHomeData()
	self:RefreshTaskGridView(homeData.tasks)
end
--[[
刷新任务列表
--]]
function ArtifactGuideMediator:RefreshTaskGridView( tasks )
	local viewComponent = self:GetViewComponent()
	local taskGridView = viewComponent:GetViewData().taskGridView
	local offset = taskGridView:getContentOffset()
	taskGridView:setCountOfCell(table.nums(tasks))
	taskGridView:reloadData()
	if self.firstRefresh then
		self.firstRefresh = false
	else
		taskGridView:setContentOffset(offset)
	end
end
--[[
刷新小红点
--]]
function ArtifactGuideMediator:RefreshRemindIcon()
	local homeData = self:GetHomeData()
	local guideConfig = CommonUtils.GetConfigAllMess('guide', 'artifact')
	for i, v in ipairs(homeData.tasks) do
		local config = guideConfig[tostring(v.id)]
		if checkint(v.collected) == 0 and checkint(v.progress) >= checkint(config.targetNum) then
			app.dataMgr:AddRedDotNofication(tostring(RemindTag.ARTIFACT_GUIDE),RemindTag.ARTIFACT_GUIDE)
			app:DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.ARTIFACT_GUIDE})
			return 
		end
	end
	app.dataMgr:ClearRedDotNofication(tostring(RemindTag.ARTIFACT_GUIDE),RemindTag.ARTIFACT_GUIDE)
	app:DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.ARTIFACT_GUIDE})
end
--[[
跳转至某一模块
@params guideConfig map 配表信息
--]]
function ArtifactGuideMediator:JumpToModule( guideConfig )
	if not guideConfig then return end
	if guideConfig.taskType == 44 then -- 将_target_num_个飨灵升_target_id_级 // 跳转至飨灵列表
		app:RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'CardsListMediatorNew'})
	elseif guideConfig.taskType == 64 then -- 将_target_id_（飨灵id）的卡牌星级提升到_target_num_ // 跳转至飨灵列表
		app:RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'},{name = 'CardsListMediatorNew', params = {cardId = guideConfig.targetId}})
	elseif guideConfig.taskType == 131 then -- 完成_target_num_次关卡_target_id_ // 跳转至神器战斗页面
		local cardConfig = CommonUtils.GetConfigAllMess('card', 'card')
		local cardData = nil
		for k, v in pairs(cardConfig) do
			if checkint(v.artifactQuestId) == checkint(guideConfig.targetId) then
				cardData = app.gameMgr:GetCardDataByCardId(v.id)
			end
		end
		local jumpMediator = self:JumpToArtifactView(cardData)
		if jumpMediator then
			app.artifactMgr:GoToBattleReadyView(
				guideConfig.targetId, jumpMediator, jumpMediator, cardData.id
			)
		end
	elseif guideConfig.taskType == 129 then -- 激活_target_id_的神器 // 跳转至神器激活页面
		local cardData = app.gameMgr:GetCardDataByCardId(guideConfig.targetId)
		self:JumpToArtifactView(cardData)
	elseif guideConfig.taskType == 130 then -- 以3星条件完成关卡_target_id_ // 跳转至神器战斗页面
		local cardConfig = CommonUtils.GetConfigAllMess('card', 'card')
		local cardData = nil
		for k, v in pairs(cardConfig) do
			if checkint(v.artifactQuestId) == checkint(guideConfig.targetId) then
				cardData = app.gameMgr:GetCardDataByCardId(v.id)
			end
		end
		local jumpMediator = self:JumpToArtifactView(cardData)
		if jumpMediator then
			app.artifactMgr:GoToBattleReadyView(
				guideConfig.targetId, jumpMediator, jumpMediator, cardData.id
			)
		end
	elseif guideConfig.taskType == 132 then -- 激活_target_id_神器的_target_num_节点 // 跳转至神器页面
		local cardData = app.gameMgr:GetCardDataByCardId(guideConfig.targetId)
		self:JumpToArtifactView(cardData)
	elseif guideConfig.taskType == 133 then -- 在_target_id_神器的_target_num_节点镶嵌宝石 // 跳转至神器页面
		local cardData = app.gameMgr:GetCardDataByCardId(guideConfig.targetId)
		self:JumpToArtifactView(cardData)
	elseif guideConfig.taskType == 134 then -- 抽取宝石_target_num_次 // 跳转塔可抽取页面
		AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({} , { name ="artifact.JewelCatcherPoolMediator"})
	elseif guideConfig.taskType == 135 then -- 合成宝石_target_num_次 // 跳转塔可合成页面
		local mediator = require("Game.mediator.artifact.JewelEvolutionMediator").new()
        self:GetFacade():RegistMediator(mediator)
	end
	app:UnRegsitMediator(NAME)
end
--[[
跳转至神器页面
@params cardData map 卡牌数据
@return mediator string 跳转到的mediator, nil则表示跳转失败
--]]
function ArtifactGuideMediator:JumpToArtifactView( cardData )
	local mediator = nil
	if not cardData then
		app.uiMgr:ShowInformationTips(__('还未拥有该飨灵'))
	elseif checkint(cardData.breakLevel) < 2 then
		app.uiMgr:ShowInformationTips(__('飨灵突破等级未达到两星'))
	elseif checkint(cardData.isArtifactUnlock) == 1 then
		app.artifactMgr:SetCardsList({cardData})
		app:RetrieveMediator("Router"):Dispatch({name = "CardsListMediatorNew", sortIndex = 0 ,params = { selectPlayerCardId = cardData.id, x = 1}}, { name ="artifact.ArtifactTalentMediator" , params = {playerCardId = cardData.id} }, {isBack = true})
		mediator = 'artifact.ArtifactTalentMediator'
	else
		app.artifactMgr:SetCardsList({cardData})
		app:RetrieveMediator("Router"):Dispatch({name = "CardsListMediatorNew", sortIndex = 0 ,params = { selectPlayerCardId = cardData.id, x = 1}}, { name ="artifact.ArtifactLockMediator" , params = {playerCardId = cardData.id } }, {isBack = true})
		mediator = 'artifact.ArtifactLockMediator'
	end
	return mediator
end
--[[
进入界面
--]]
function ArtifactGuideMediator:EnterLayer()
	self:SendSignal(POST.ARTIFACT_GUIDE_HOME.cmdName)
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
设置homeData
--]]
function ArtifactGuideMediator:SetHomeData( data )
	self.homeData = checktable(data)
end
--[[
获取homeData
--]]
function ArtifactGuideMediator:GetHomeData()
	return self.homeData or {}
end
------------------- get / set -------------------
-------------------------------------------------
return ArtifactGuideMediator
