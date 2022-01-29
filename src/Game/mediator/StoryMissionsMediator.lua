--[[
剧情任务mediator
--]]
local Mediator = mvc.Mediator

local StoryMissionsMediator = class("StoryMissionsMediator", Mediator)


local NAME = "StoryMissionsMediator"


Story_SubmitMissions= 'Story_SubmitMissions'
Story_AcceptMissions = 'Story_AcceptMissions'
Story_DrawMissions = 'Story_DrawMissions'

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

local sortConfig = {
	['1'] = 2,
	['2'] = 3,
	['3'] = 1
}


local StoryMissionsCell = require('home.StoryMissionsCell')
function StoryMissionsMediator:ctor( viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.storyMissionsDatas = {} --主线。支线本地数据
	self.storyDatas = {} -- 主线任务类型数据
	self.regionalDatas = {} -- 支线任务类型数据
	-- self.nowDatas = {}
	self.clickTag = 1 --点击显示1 主线剧情，或者 2 支线剧情任务
	self.preIndex = 0

	self.newestPlotTaskId = 1

	self.StoryMissionsMessageMediator = nil
	self.gridContentOffset = cc.p(0,0)
end


function StoryMissionsMediator:InterestSignals()
	local signals = {
		SIGNALNAMES.StoryMissions_List_Callback,
		SIGNALNAMES.Story_AcceptMissions_Callback,
		SIGNALNAMES.Story_DrawReward_Callback,
		SIGNALNAMES.RegionalMissions_List_Callback,
		-- Story_SubmitMissions,
		Story_AcceptMissions,
		Story_DrawMissions,
		EVENT_LEVEL_UP,
		--------------- battle ---------------
		-- 'Story_Create_Battle_Ready'
		--------------- battle ---------------
	}

	return signals
end

function StoryMissionsMediator:ProcessSignal(signal )
	local name = signal:GetName()
	-- print(name)
	-- dump(signal:GetBody())
	local isInit = false
	local showAcion = false
	if name == SIGNALNAMES.StoryMissions_List_Callback then--
		--更新UI
		-- dump(signal:GetBody())
		local tempTab = {}
		self.storyDatas = {}
		self.newestPlotTaskId = signal:GetBody().newestPlotTaskId
		local showStory = true
		if next(signal:GetBody().plotTask) == nil then
			showStory = false
			gameMgr:GetUserInfo().newestPlotTask = {hasDrawn = 1,taskId = self.newestPlotTaskId}
			local v = CommonUtils.GetConfig('quest', 'questPlot', checkint(self.newestPlotTaskId)+1)
			if v then
				v.status = 1
				v.hasDrawn = 0
				v.progress = 0
				v.isActivation = false -- 是否激活
				v.taskId = checkint(self.newestPlotTaskId + 1)
				table.insert(self.storyDatas,v)
			end
		else
			for k,v in pairs(signal:GetBody().plotTask) do
				if CommonUtils.GetConfig('quest', 'questPlot', k) then
					local data =  clone(CommonUtils.GetConfig('quest', 'questPlot', k))
					data.taskId = v.taskId
					data.status = v.status
					data.hasDrawn = v.hasDrawn
					data.progress = v.progress or 0

					data.isActivation = true -- 是否激活
					tempTab[tostring(k)] = data
					table.insert(self.storyDatas,data)
				end
			end

			if tempTab[tostring(self.newestPlotTaskId)] then
				if checkint(tempTab[tostring(self.newestPlotTaskId)].hasDrawn) == 1 then
					showStory = false
					local v = CommonUtils.GetConfig('quest', 'questPlot', checkint(self.newestPlotTaskId)+1)
					if v then
						v.status = 1
						v.hasDrawn = 0
						v.progress = 0
						v.isActivation = false -- 是否激活
						v.taskId = checkint(self.newestPlotTaskId + 1)
						table.insert(self.storyDatas,v)
					end
				end
			end
			sortByMember(self.storyDatas, "taskId", false)
			if self.storyDatas[1].isActivation == false then
				gameMgr:GetUserInfo().newestPlotTask = {hasDrawn = 1,taskId = self.newestPlotTaskId}
			else
				gameMgr:GetUserInfo().newestPlotTask = self.storyDatas[1]
			end
		end

		--相等说明完成全部的主线绝情任务
		if table.nums(self.storyDatas) == table.nums(CommonUtils.GetConfigAllMess('questPlot' ,'quest')) and
			self.storyDatas[1].hasDrawn == 1 then
			showStory = false
			self.storyDatas = {}
			gameMgr:GetUserInfo().newestPlotTask = {hasDrawn = 1,taskId = self.newestPlotTaskId}
		end

		if signal:GetBody().branchTask then
			self.regionalDatas = {}
			for k,v in pairs(signal:GetBody().branchTask) do
				if v.hasDrawn == 0 then
					if CommonUtils.GetConfig('quest', 'branch', k) then
						local data =  clone(CommonUtils.GetConfig('quest', 'branch', k))
						data.status = v.status
						data.hasDrawn = v.hasDrawn
						data.taskId = v.taskId
						data.progress = v.progress or 0
						data.isActivation = true -- 是否激活
						data.sortIndex = sortConfig[tostring(v.status)] or 1
						table.insert(self.regionalDatas,data)
					end
				end
			end
			sortByMember(self.regionalDatas, "sortIndex", true)
		end
		-- dump(self.regionalDatas)
		gameMgr:GetUserInfo().branchList = {}
		gameMgr:GetUserInfo().branchList = signal:GetBody().branchTask

		isInit = true

		AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.Updata_StoryMissions_Mess)--更新主界面剧情任务入口


		-- dump(self.storyDatas)
		-- dump(self.regionalDatas)
		if next(self.storyDatas) ~= nil then
			if self.storyDatas[1] then
				if self.storyDatas[1].isActivation == true then--显示主线
					self:InitLayer(true)
				else
					if next(self.regionalDatas) == nil then
						self:InitLayer(true)
					else
						self:InitLayer(false)
					end
				end
			end
		else--显示支线
			if next(self.regionalDatas) == nil then
				self:InitLayer(true)
			else
				self:InitLayer(false)
			end
		end
	elseif name == SIGNALNAMES.RegionalMissions_List_Callback then
		for k,v in pairs(CommonUtils.GetConfigAllMess('branch' ,'quest')) do

			v.status = 1
			v.hasDrawn = 0
			v.isActivation = false -- 是否激活
			v.taskId = v.id

			if signal:GetBody().branchTask[k] then
				v.status = signal:GetBody().branchTask[k].status
				v.hasDrawn = signal:GetBody().branchTask[k].hasDrawn
				v.taskId = signal:GetBody().branchTask[k].taskId
				v.sortIndex = sortConfig[tostring(signal:GetBody().branchTask[k].status)] or 1
				v.isActivation = true -- 是否激活
			end
			table.insert(self.regionalDatas,v)
		end
		sortByMember(self.regionalDatas, "sortIndex", true)
	elseif name == SIGNALNAMES.Story_AcceptMissions_Callback then--接受任务
		local tempTab = {}
		local path = (string.format("conf/%s/quest/questStory.json",i18n.getLang()))
		if self.clickTag == 1 then
			self.storyDatas[1].status = signal:GetBody().status or 2--v.status
			self.storyDatas[1].progress = signal:GetBody().progress or 0
			tempTab = self.storyDatas[1]
			if checkint(tempTab.taskType) == 8 or checkint(tempTab.taskType) == 9 then
				gameMgr.userInfo.storyTasks[string.format("%d_%d", Types.TYPE_STORY,checkint(self.storyDatas[1].taskId))] = {id = checkint(self.storyDatas[1].taskId), type = Types.TYPE_STORY}
				self:GetFacade():DispatchObservers(SIGNALNAMES.REFRESH_HOMEMAP_STORY_LAYER)
			end
            GuideUtils.DispatchStepEvent()
		elseif self.clickTag == 2 then
			path = (string.format("conf/%s/quest/branchStory.json",i18n.getLang()))
			self.regionalDatas[self.preIndex].status = signal:GetBody().status or 2
			self.regionalDatas[self.preIndex].progress = signal:GetBody().progress or 0
			self.regionalDatas[self.preIndex].sortIndex = sortConfig[tostring(signal:GetBody().status)] or 1

			tempTab = self.regionalDatas[self.preIndex]
			if checkint(tempTab.taskType) == 8 or checkint(tempTab.taskType) == 9 then
				gameMgr.userInfo.storyTasks[string.format("%d_%d", Types.TYPE_BRANCH,checkint(self.regionalDatas[self.preIndex].taskId))] = {id = checkint(self.regionalDatas[self.preIndex].taskId), type = Types.TYPE_BRANCH}
				self:GetFacade():DispatchObservers(SIGNALNAMES.REFRESH_HOMEMAP_STORY_LAYER)
			end
		end
		if checkint(tempTab.story.accept) ~= 0 then
			local stage = require( "Frame.Opera.OperaStage" ).new({id = tempTab.story.accept,path = path, isHideBackBtn = true,cb = function(tag)
				--出弹出框
				if self.StoryMissionsMessageMediator then
					self.StoryMissionsMessageMediator:ShowAction()
				end
			end})
			stage:setPosition(cc.p(display.cx,display.cy))
            sceneWorld:addChild(stage, GameSceneTag.Dialog_GameSceneTag)
        else
        	showAcion = true
		end

	elseif name == SIGNALNAMES.Story_DrawReward_Callback then--领取
		local tempTab = {}
		local tempStoryData = nil
		if signal:GetBody().requestData.isForm == 'StoryLayer' then
			if self.clickTag == 1 then
				self.newestPlotTaskId = signal:GetBody().newestPlotTaskId
				self.storyDatas[1].hasDrawn = 1
				tempTab = self.storyDatas[1]
				-- dump(tempTab.story.done)
				if checkint(tempTab.story.done) ~= 0 then
					if tempTab.taskType == 8 or tempTab.taskType == 9 or tempTab.taskType == 10 or tempTab.taskType == 11 then
						if signal:GetBody().rewards then
							uiMgr:AddDialog('common.RewardPopup', {rewards = signal:GetBody().rewards , mainExp = signal:GetBody().mainExp})--, mainExp = checkint(signal:GetBody().mainExp)
						end
					else
						local stage = require( "Frame.Opera.OperaStage" ).new({id = tempTab.story.done,path = (string.format("conf/%s/quest/questStory.json",i18n.getLang())), isHideBackBtn = true,cb = function(tag)
							--出弹出框
							-- CommonUtils.DrawRewards(signal:GetBody().rewards)
							if signal:GetBody().rewards then
								uiMgr:AddDialog('common.RewardPopup', {rewards = signal:GetBody().rewards, mainExp = signal:GetBody().mainExp})--
							end
						end})
						stage:setPosition(cc.p(display.cx,display.cy))
	                    sceneWorld:addChild(stage, GameSceneTag.Dialog_GameSceneTag)
	                end
				else
					-- CommonUtils.DrawRewards(signal:GetBody().rewards)
					if signal:GetBody().rewards then
						uiMgr:AddDialog('common.RewardPopup', {rewards = signal:GetBody().rewards , mainExp = signal:GetBody().mainExp})--, mainExp = checkint(signal:GetBody().mainExp)
					end
				end

				-- --这类任务类型为需要提交材料 所以要扣除
				if tempTab.taskType == 12 or tempTab.taskType == 16 then
					tempStoryData = CommonUtils.GetConfig('quest','questPlot',signal:GetBody().requestData.plotTaskId)
				end


				if next(signal:GetBody().newestPlotTask) ~= nil then --下一个剧情任务激活

					local v = clone(CommonUtils.GetConfigAllMess('questPlot' ,'quest')[tostring(checkint(self.newestPlotTaskId))])
					if v then
						-- table.merge(v,signal:GetBody().newestPlotTask)
						v.taskId = signal:GetBody().newestPlotTask.taskId
						v.status = signal:GetBody().newestPlotTask.status
						v.hasDrawn = signal:GetBody().newestPlotTask.hasDrawn
						v.isActivation = true -- 是否激活
						v.progress  = 0
						table.insert(self.storyDatas,v)
					end

					sortByMember(self.storyDatas, "taskId", false)
					gameMgr:GetUserInfo().newestPlotTask = self.storyDatas[1]
				else
					local v = CommonUtils.GetConfigAllMess('questPlot' ,'quest')[tostring(checkint(self.newestPlotTaskId)+1)]
					if v then
						v.status = 1
						v.hasDrawn = 0
						v.isActivation = false -- 是否激活
						v.progress  = 0
						v.taskId = checkint(self.newestPlotTaskId + 1)
						table.insert(self.storyDatas,v)
					end
					sortByMember(self.storyDatas, "taskId", false)
					gameMgr:GetUserInfo().newestPlotTask = {hasDrawn = 1,taskId = self.newestPlotTaskId}
					-- gameMgr:GetUserInfo().newestPlotTask = self.storyDatas[1]
				end
			elseif self.clickTag == 2 then
				self.regionalDatas[self.preIndex].hasDrawn = 1
				tempTab = self.regionalDatas[self.preIndex]
				-- dump(tempTab.story.done)
				if checkint(tempTab.story.done) ~= 0 then-- done
					if tempTab.taskType == 8 or tempTab.taskType == 9 or tempTab.taskType == 10 or tempTab.taskType == 11 then
						if signal:GetBody().rewards then
							uiMgr:AddDialog('common.RewardPopup', {rewards = signal:GetBody().rewards , mainExp = signal:GetBody().mainExp})--, mainExp = checkint(signal:GetBody().mainExp)
						end
					else
						local stage = require( "Frame.Opera.OperaStage" ).new({id = tempTab.story.done,path = (string.format("conf/%s/quest/branchStory.json",i18n.getLang())), isHideBackBtn = true,cb = function(tag)
							--出弹出框
							-- CommonUtils.DrawRewards(signal:GetBody().rewards)
							if signal:GetBody().rewards then
								uiMgr:AddDialog('common.RewardPopup', {rewards = signal:GetBody().rewards, mainExp = signal:GetBody().mainExp })--, mainExp = checkint(signal:GetBody().mainExp)
							end
						end})
						stage:setPosition(cc.p(display.cx,display.cy))
	                    sceneWorld:addChild(stage, GameSceneTag.Dialog_GameSceneTag)
                    end
				else
					-- CommonUtils.DrawRewards(signal:GetBody().rewards)
					if signal:GetBody().rewards then
						uiMgr:AddDialog('common.RewardPopup', {rewards = signal:GetBody().rewards , mainExp = signal:GetBody().mainExp})--, mainExp = checkint(signal:GetBody().mainExp)
					end
				end

				--这类任务类型为需要提交材料 所以要扣除
				if tempTab.taskType == 12 or tempTab.taskType == 16 then
					tempStoryData = CommonUtils.GetConfig('quest','branch',signal:GetBody().requestData.branchTaskId)
				end

				--删除该任务
				for i=#self.regionalDatas,1,-1 do
					if checkint(self.regionalDatas[i].taskId) == checkint(self.regionalDatas[self.preIndex].taskId) then
						table.remove(self.regionalDatas,i)
						break
					end
				end
				-- gameMgr:GetUserInfo().branchList = {}
				-- gameMgr:GetUserInfo().branchList = self.regionalDatas
				if signal:GetBody().branchTasks then
					self.regionalDatas = {}
					for k,v in pairs(signal:GetBody().branchTasks) do
						if v.hasDrawn == 0 then
							if CommonUtils.GetConfig('quest', 'branch', k) then
								local data =  clone(CommonUtils.GetConfig('quest', 'branch', k))
								data.status = v.status
								data.hasDrawn = v.hasDrawn
								data.taskId = v.taskId
								data.progress = v.progress  or 0
								data.isActivation = true -- 是否激活
								data.sortIndex = sortConfig[tostring(v.status)] or 1
								table.insert(self.regionalDatas,data)
							end
						end
					end
					sortByMember(self.regionalDatas, "sortIndex", true)
					gameMgr:GetUserInfo().branchList = {}
					-- gameMgr:GetUserInfo().branchList = self.regionalDatas
					gameMgr:GetUserInfo().branchList = signal:GetBody().branchTasks
				end
				-- dump(signal:GetBody().branchTasks)
				-- dump(gameMgr:GetUserInfo().branchList)
			end

			-- dump(tempStoryData)
			if tempStoryData then
				-- dump(tempStoryData.target)
				local targetId = tempStoryData.target.targetId[1]
				local targetNum = tempStoryData.target.targetNum
		 		CommonUtils.DrawRewards({
					{goodsId = targetId, num = -targetNum}
				})
			end
			AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.Updata_StoryMissions_Mess)
            GuideUtils.DispatchStepEvent()

            if checkint(tempTab.unlockTakeawayRoleId) ~= 0 then
				app.takeawayMgr:FreshTakeawayData()
            end
		end


	elseif name == EVENT_LEVEL_UP then--检测等级升级后重新拉取接口刷新界面
		print(gameMgr:GetUserInfo().level)
		self.clickTag = 1
		self.preIndex = 0
		self:SendSignal(COMMANDS.COMMAND_StoryMissions_List)
	elseif name == Story_SubmitMissions then
		self:SubmitMissions( )
		isInit = true
	elseif name == Story_AcceptMissions then
		self:AcceptMissions( )
		isInit = true
	elseif name == Story_DrawMissions then
		self:DrawMissions( )
		isInit = true
	end

	if isInit == false then
		self:UpdataLayer(showAcion)
	end
end


function StoryMissionsMediator:Initial( key )
	self.super.Initial(self,key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require( 'Game.views.StoryMissionsView' ).new()--{tag = 6789}
    viewComponent:setName('Game.views.StoryMissionsView')
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)

	--绑定相关的事件
	local viewData = viewComponent.viewData
	-- for k, v in pairs( viewData.leftButtons ) do
	-- 	v:setOnClickScriptHandler(handler(self,self.LeftButtonActions))
	-- end

	viewData.storyBtn:setOnClickScriptHandler(handler(self,self.StoryButtonActions))
	-- viewData.storySelectImg:setVisible(true)

	local gridView = viewData.gridView
	gridView:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSourceAction))

	self.messLayout = viewComponent.viewData.messLayout--剧情任务详情layout

	-- local StoryMissionsMessageMediator = require( 'Game.mediator.StoryMissionsMessageMediator')
	-- local mediator = StoryMissionsMessageMediator.new({self.messLayout})
	-- self:GetFacade():RegistMediator(mediator)
	-- self.StoryMissionsMessageMediator = mediator


	local StoryMissionsMessageMediator = require( 'Game.mediator.StoryMissionsMessageNewMediator')
	local mediator = StoryMissionsMessageMediator.new({self.messLayout})
	self:GetFacade():RegistMediator(mediator)
	self.StoryMissionsMessageMediator = mediator


end

function StoryMissionsMediator:OnDataSourceAction(p_convertview,idx)
    local pCell = p_convertview
    local pButton = nil
    local index = idx + 1
    local viewData = self.viewComponent.viewData
    local bg = viewData.gridView
    local sizee = cc.size(440,90)

    -- if self.datas and index <= table.nums(self.datas) then
        -- local data = CommonUtils.GetConfig('goods', 'goods', self.datas[index].goodsId)
        if pCell == nil then
            pCell = StoryMissionsCell.new()
            pCell.toggleView:setOnClickScriptHandler(handler(self,self.CellButtonAction))
        	pCell.eventnode:setPosition(cc.p(sizee.width* 0.5 - 2,sizee.height * 0.5))
        else
            pCell.selectImg:setVisible(false)

            pCell.eventnode:setPosition(cc.p(sizee.width* 0.5 - 2,sizee.height * 0.5))
        end
		xTry(function()
			pCell.toggleView:setTag(index)
			pCell:setTag(index)
			if index == self.preIndex then
				pCell.selectImg:setVisible(true)
			else
				pCell.selectImg:setVisible(false)
			end

            pCell.typeLabel:setString(string.fmt(__('【支线】_text_'), {_text_ = ""}))
			pCell.labelName:setString(self.regionalDatas[index].name)

			pCell.npcImg:setTexture(CommonUtils.GetNpcIconPathById(self.regionalDatas[index].roleId or 'role_1',3))
			pCell.npcImg:setVisible(true)

			-- dump(self.regionalDatas)
			pCell.redPointImg:setVisible(false)
			if checkint(self.regionalDatas[index].status) == 1 then--已接收任务
				pCell.redPointImg:setVisible(true)
				pCell.redPointImg:setTexture(_res('ui/card_preview_ico_new_2'))
			elseif checkint(self.regionalDatas[index].status) == 3 then--可领取任务
				pCell.redPointImg:setVisible(true)
				pCell.redPointImg:setTexture(_res('ui/common/common_ico_red_point.png'))
			end

		end,__G__TRACKBACK__)
        return pCell
    -- end
end


function StoryMissionsMediator:InitLayer( showStory )
	-- dump(showStory)
	local viewData = self.viewComponent.viewData
    if table.nums(self.storyDatas) > 0 then
        local gridView = viewData.gridView
        viewData.typeLabel:setString(string.fmt(__('【主线】_text_'),{_text_ = ""}))
        viewData.typeName:setString(self.storyDatas[1].name)
		viewData.redPointImg:setVisible(false)
		if self.storyDatas and next(self.storyDatas) ~= nil then
			if checkint(self.storyDatas[1].status) ~= 2 and self.storyDatas[1].isActivation == true then--未完成任务
				viewData.redPointImg:setVisible(true)
			end
		end
		viewData.npcImg:setTexture(CommonUtils.GetNpcIconPathById(self.storyDatas[1].roleId or 'role_1',3))
		viewData.npcImg:setVisible(true)
        gridView:setCountOfCell(table.nums(self.regionalDatas))
        gridView:reloadData()
    else
        viewData.typeLabel:setString("")
        viewData.typeName:setString(__('任务已经全部完成'))
        viewData.npcImg:setVisible(false)
        local gridView = viewData.gridView
        gridView:setCountOfCell(table.nums(self.regionalDatas))
        gridView:reloadData()
    end

    if showStory == true then -- 显示主线
		self.StoryMissionsMessageMediator:UpdataUi(self.storyDatas[1],self.clickTag)
    else-- 显示支线
    	local gridView = viewData.gridView
	    local cell = gridView:cellAtIndex(0)
	    if cell then
	        self:CellButtonAction( cell )
	    end
    end
end

function StoryMissionsMediator:UpdataLayer( showAcion )
	local viewData = self.viewComponent.viewData
	local gridView = viewData.gridView
	if self.clickTag == 1 then
        viewData.typeLabel:setString(string.fmt(__('【主线】_text_'),{_text_ = ""}))
        viewData.typeName:setString(self.storyDatas[1].name)
		viewData.redPointImg:setVisible(false)
		if checkint(self.storyDatas[1].status) ~= 2  and  self.storyDatas[1].isActivation == true then--未完成任务
			-- dump(self.storyDatas[1].status)
			viewData.redPointImg:setVisible(true)
		end
		viewData.npcImg:setTexture(CommonUtils.GetNpcIconPathById(self.storyDatas[1].roleId or 'role_1',3))
		viewData.npcImg:setVisible(true)

		-- dump(tempTab)
		if self.StoryMissionsMessageMediator then
			self.StoryMissionsMessageMediator:UpdataUi(self.storyDatas[1],self.clickTag,showAcion)
		end
	elseif self.clickTag == 2 then
		-- dump(self.preIndex)
	    local cell = gridView:cellAtIndex(self.preIndex - 1)
	    -- dump(cell)
	    if not cell then
	    	self.preIndex = 1
	    end
	    -- dump(self.preIndex)
		gridView:setCountOfCell(table.nums(self.regionalDatas))
		gridView:reloadData()

		if self.gridContentOffset.y >= gridView:getMinOffset().y then
			gridView:setContentOffset(self.gridContentOffset)
		else
			self.gridContentOffset = gridView:getContentOffset()
			gridView:setContentOffsetToTop()
		end

		-- dump(tempTab)
		if self.StoryMissionsMessageMediator then
			self.StoryMissionsMessageMediator:UpdataUi(self.regionalDatas[self.preIndex],self.clickTag,showAcion)
		end

		-- if table.nums(self.regionalDatas) == 0 then
		-- 	self.clickTag = 1
		-- 	self:UpdataLayer( showAcion )
		-- elseif not self.regionalDatas[self.preIndex] then
		-- end
	end
end
-- plotTask/submitPlotTask
function StoryMissionsMediator:SubmitMissions(  )
	if self.clickTag ==  1 then
		self:SendSignal(COMMANDS.COMMAND_Story_SubmitMissions,{plotTaskId = self.storyDatas[1].taskId,isForm = 'StoryLayer'})
	elseif self.clickTag ==  2 then
		self:SendSignal(COMMANDS.COMMAND_Regional_SubmitMissions,{branchTaskId = self.regionalDatas[self.preIndex].taskId,isForm = 'StoryLayer'})
	end
end

function StoryMissionsMediator:AcceptMissions(  )
	if self.clickTag ==  1 then
		self:SendSignal(COMMANDS.COMMAND_Story_AcceptMissions,{plotTaskId = self.storyDatas[1].taskId,isForm = 'StoryLayer'})
	elseif self.clickTag ==  2 then
		self:SendSignal(COMMANDS.COMMAND_Regional_AcceptMissions,{branchTaskId = self.regionalDatas[self.preIndex].taskId,isForm = 'StoryLayer'})
	end
end

function StoryMissionsMediator:DrawMissions(  )
	if self.clickTag ==  1 then
		self:SendSignal(COMMANDS.COMMAND_Story_DrawReward,{plotTaskId = self.storyDatas[1].taskId,isForm = 'StoryLayer'})
	elseif self.clickTag ==  2 then
		self:SendSignal(COMMANDS.COMMAND_Regional_DrawReward,{branchTaskId = self.regionalDatas[self.preIndex].taskId,isForm = 'StoryLayer'})
	end
end



--[[
主线。支线
@param sender button对象
--]]
function StoryMissionsMediator:StoryButtonActions( sender )
    PlayAudioByClickNormal()
	self.clickTag = 1
	self.preIndex = 0
	self.viewComponent.viewData.storySelectImg:setVisible(true)

	local viewData = self.viewComponent.viewData
	local gridView = viewData.gridView
	for k,v in pairs(gridView:getCells()) do
		if v then
			v.selectImg:setVisible(false)
		end
	end

	if self.StoryMissionsMessageMediator then
		-- dump(self.storyDatas[1])
		self.StoryMissionsMessageMediator:UpdataUi(self.storyDatas[1],self.clickTag)
	end
end

--[[
列表的单元格按钮的事件处理逻辑
@param sender button对象
--]]
function StoryMissionsMediator:CellButtonAction( sender )
    PlayAudioByClickNormal()
	self.clickTag = 2
	self.viewComponent.viewData.storySelectImg:setVisible(false)
	local viewData = self.viewComponent.viewData
	local gridView = viewData.gridView
    local index = sender:getTag()
    local cell = gridView:cellAtIndex(index- 1)
    if cell then
        cell.selectImg:setVisible(true)
    end
    if index == self.preIndex then return end
    --更新按钮状态
    local cell = gridView:cellAtIndex(self.preIndex - 1)
    if cell then
        cell.selectImg:setVisible(false)
    end
    self.preIndex = index

	if self.StoryMissionsMessageMediator then
		-- dump(self.regionalDatas[self.preIndex])
		self.StoryMissionsMessageMediator:UpdataUi(self.regionalDatas[self.preIndex],self.clickTag)
	end

	self.gridContentOffset = gridView:getContentOffset()
end


function StoryMissionsMediator:OnRegist(  )
	local StoryMissionsCommand = require( 'Game.command.StoryMissionsCommand')
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_StoryMissions_List, StoryMissionsCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_RegionalMissions_List, StoryMissionsCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Story_AcceptMissions, StoryMissionsCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Regional_AcceptMissions, StoryMissionsCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Story_DrawReward, StoryMissionsCommand)
	-- self:GetFacade():RegistSignal(COMMANDS.COMMAND_Story_SubmitMissions, StoryMissionsCommand)
	-- self:GetFacade():RegistSignal(COMMANDS.COMMAND_Regional_SubmitMissions, StoryMissionsCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Regional_DrawReward, StoryMissionsCommand)

	self:SendSignal(COMMANDS.COMMAND_StoryMissions_List)
	-- self:SendSignal(COMMANDS.COMMAND_RegionalMissions_List,requestData)

	-- fixed guide
	local acceptStoryStepId = checkint(GuideUtils.GetModuleData(GUIDE_MODULES.MODULE_ACCEPT_STORY))
	if not GuideUtils.IsGuiding() and acceptStoryStepId == 0 and not GuideUtils.CheckIsFinishedStorytPlot1({dontShowTips = true}) then
		GuideUtils.GetDirector():FinishLocalModule(GUIDE_MODULES.MODULE_LOBBY)
		GuideUtils.GetDirector():FinishLocalModule(GUIDE_MODULES.MODULE_DRAWCARD)
		GuideUtils.GetDirector():FinishLocalModule(GUIDE_MODULES.MODULE_TEAM)
		GuideUtils.SwitchModule(GUIDE_MODULES.MODULE_ACCEPT_STORY, 100)
	else
		GuideUtils.DispatchStepEvent()
	end
	-- self:LeftButtonActions( self.clickTag )
end

function StoryMissionsMediator:OnUnRegist(  )
	local bool = false
	for i,v in ipairs(self.storyDatas) do
		if v.status == 3 and v.hasDrawn == 0 then
			bool = true
			break
		end
	end
	if bool == false then
		for i,v in ipairs(self.regionalDatas) do
			if v.status == 3 and v.hasDrawn == 0 then
				bool = true
				break
			end
		end
	end
	if bool == true then
		AppFacade.GetInstance():GetManager("DataManager"):AddRedDotNofication(tostring(RemindTag.STORY), RemindTag.STORY, "[剧情任务]toryMissionsMediator:OnUnRegist")
	else
		AppFacade.GetInstance():GetManager("DataManager"):ClearRedDotNofication(tostring(RemindTag.STORY), RemindTag.STORY, "[剧情任务]toryMissionsMediator:OnUnRegist")
	end
	AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, tag = RemindTag.STORY})

	-- dump(self.storyDatas) -- 主线任务类型数据
	-- dump(self.regionalDatas) -- 支线任务类型数据
	--称出命令
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_StoryMissions_List)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_RegionalMissions_List)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Story_AcceptMissions)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Regional_AcceptMissions)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Story_DrawReward)
	-- self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Story_SubmitMissions)
	-- self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Regional_SubmitMissions)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Regional_DrawReward)

	local scene = uiMgr:GetCurrentScene()
	scene:RemoveDialog(self.viewComponent)

	self:GetFacade():UnRegsitMediator("StoryMissionsMessageNewMediator")
	AppFacade.GetInstance():DispatchObservers(SGL.BREAK_TO_HOME_MEDIATOR)
end

return StoryMissionsMediator
