--[[
剧情任务图鉴会看Mediator
--]]
local Mediator = mvc.Mediator
---@class StoryMissionsCollectionMediator :Mediator
local StoryMissionsCollectionMediator = class("StoryMissionsCollectionMediator", Mediator)


local NAME = "StoryMissionsCollectionMediator"

---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

local StoryMissionsCell = require('home.StoryMissionsCell')
function StoryMissionsCollectionMediator:ctor(params, viewComponent )
	self.ctorArgs_ = checktable(params)
	self.super.ctor(self, NAME, viewComponent)
	self.storyMissionsDatas = {} --主线。支线本地数据
	-- self.storyDatas = {} -- 主线任务类型数据
	-- self.regionalDatas = {} -- 支线任务类型数据
	-- self.nowDatas = {}
	self.clickTag = 1 --点击显示1 主线剧情，或者 2 支线剧情任务
	self.preIndex = 1
	self.isSubPopup = self.ctorArgs_.subPopup == true

	self.newestPlotTaskId = 1
	self.jsonName = 'questPlot'
	if GAME_MODULE_OPEN.NEW_PLOT then
		self.jsonName = 'questPlotOld'

		local confs = CommonUtils.GetConfigAllMess(self.jsonName, 'quest') or {}
		gameMgr:GetUserInfo().newestPlotTask.taskId = table.nums(confs) + 1
	end
end


function StoryMissionsCollectionMediator:InterestSignals()
	local signals = {
	}

	return signals
end

function StoryMissionsCollectionMediator:ProcessSignal(signal )
	local name = signal:GetName()
	print(name)
	-- dump(signal:GetBody())
end


function StoryMissionsCollectionMediator:Initial( key )
	self.super.Initial(self,key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require( 'Game.views.StoryMissionsCollectionView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)

	--绑定相关的事件
	local viewData = viewComponent.viewData
	-- viewData.storySelectImg:setVisible(true)

	viewData.closeBtn:setOnClickScriptHandler(function(sender)
		PlayAudioByClickClose()
		AppFacade.GetInstance():UnRegsitMediator("StoryMissionsCollectionMediator")

		if not self.isSubPopup and not GAME_MODULE_OPEN.NEW_PLOT then
			AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = "HomeMediator"},
			{name = "HandbookMediator"})
		end
	end)

	local gridView = viewData.gridView
	gridView:setDataSourceAdapterScriptHandler(handler(self,self.OnDataSourceAction))

	local reReadBtn = viewData.reReadBtn
	local desLabel = viewData.desLabel
	self.stage = nil
    reReadBtn:setOnClickScriptHandler(function(sender)


		local path = (string.format("conf/%s/quest/questStory.json",i18n.getLang()))
		if self.clickTag == 2 then
			path  = (string.format("conf/%s/quest/branchStory.json",i18n.getLang()))
		end
		
		local storyMissionConf = self.storyMissionsDatas[self.preIndex]
		if storyMissionConf and storyMissionConf.story then
			if checkint(storyMissionConf.story.accept) ~= 0 then
				-- dump(storyMissionConf.story)
				local stage = require( "Frame.Opera.OperaStage" ).new({id = storyMissionConf.story.accept, path = path, guide = true, isHideBackBtn = true, cb = function(tag)
					if tag == 3006 or tag == 3007 then
						--出弹出框
						-- self.stage:removeFromParent()
						self.viewComponent:runAction(cc.Sequence:create(cc.DelayTime:create(0.01),cc.CallFunc:create(function()
							if checkint(storyMissionConf.story.done) ~= 0 then
								local stage = require( "Frame.Opera.OperaStage" ).new({id = storyMissionConf.story.done, path = path, guide = true, isHideBackBtn = true, cb = function(tag)
									if tag == 3006 or tag == 3007 then
										--出弹出框
										if checkint(storyMissionConf.story.pass) ~= 0 then
											self.viewComponent:runAction(cc.Sequence:create(cc.DelayTime:create(0.01),cc.CallFunc:create(function()
												local stage = require( "Frame.Opera.OperaStage" ).new({id = storyMissionConf.story.pass, path = path, guide = true, isHideBackBtn = true})
												stage:setPosition(cc.p(display.cx,display.cy))
							        			sceneWorld:addChild(stage, GameSceneTag.Dialog_GameSceneTag)
						        			end)))
										end
									end
								end})
								stage:setPosition(cc.p(display.cx,display.cy))
								sceneWorld:addChild(stage, GameSceneTag.Dialog_GameSceneTag)
								
							elseif checkint(storyMissionConf.story.pass) ~= 0 then
								local stage = require( "Frame.Opera.OperaStage" ).new({id = storyMissionConf.story.pass, path = path, guide = true, isHideBackBtn = true})
								stage:setPosition(cc.p(display.cx,display.cy))
			        			sceneWorld:addChild(stage, GameSceneTag.Dialog_GameSceneTag)
							end

						end)))

					end
				end})
				stage:setPosition(cc.p(display.cx,display.cy))
		        sceneWorld:addChild(stage, GameSceneTag.Dialog_GameSceneTag)
		    else
		    	uiMgr:ShowInformationTips(__('该任务无剧情回看'))
		    end
	    end

    end)


	viewData.branchButton:setOnClickScriptHandler(handler(self,self.TabButtonAction))
	viewData.storyButton:setOnClickScriptHandler(handler(self,self.TabButtonAction))

	if table.nums(gameMgr:GetUserInfo().newestPlotTask) > 0 then
		for k,v in orderedPairs(CommonUtils.GetConfigAllMess(self.jsonName, 'quest')) do--pairs()
			if k ~= '__orderedIndex' then
				if checkint(k) < checkint(gameMgr:GetUserInfo().newestPlotTask.taskId) then
					table.insert(self.storyMissionsDatas,v)
				else
					if checkint(k) > checkint(gameMgr:GetUserInfo().newestPlotTask.taskId) then
						-- dump(CommonUtils.CheckLockCondition(v.unlockType))
						-- dump(v.unlockType)
						if CommonUtils.CheckLockCondition(v.unlockType) and checkint(gameMgr:GetUserInfo().newestPlotTask.hasDrawn) ~= 0 then
							local  data = CommonUtils.GetConfig('quest', self.jsonName, gameMgr:GetUserInfo().newestPlotTask.taskId)
							table.insert(self.storyMissionsDatas,data)
						end
						break
					end
				end
			end
		end
	end
	-- dump(self.storyMissionsDatas)
    gridView:setCountOfCell(table.nums(self.storyMissionsDatas))
    gridView:reloadData()
	if table.nums(self.storyMissionsDatas) == 0 then
		viewData.richLayout:setVisible(true)
	else
		viewData.richLayout:setVisible(false)
	end
    local cell = gridView:cellAtIndex(0)
    if cell then
    	cell.selectImg:setVisible(true)
    	viewData.desLabel:setString(self.storyMissionsDatas[1].descr)
	else
		viewData.desLabel:setString(__('暂无任务描述'))
    end
end

function StoryMissionsCollectionMediator:OnDataSourceAction(p_convertview,idx)
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
            pCell.labelName:setPositionY(pCell:getContentSize().height - 34)
        else
            pCell.selectImg:setVisible(false)

            pCell.eventnode:setPosition(cc.p(sizee.width* 0.5 - 2,sizee.height * 0.5))
        end
		xTry(function()
			pCell.toggleView:setTag(index)
			pCell:setTag(index)
			pCell.redPointImg:setVisible(false)
			if index == self.preIndex then
				pCell.selectImg:setVisible(true)
			else
				pCell.selectImg:setVisible(false)
			end

			pCell.labelName:setString(string.fmt(('_text_'), {_text_ = self.storyMissionsDatas[index].name}))

			pCell.npcImg:setTexture(CommonUtils.GetNpcIconPathById(self.storyMissionsDatas[index].roleId or 'role_1',3))
			pCell.npcImg:setVisible(true)
		end,__G__TRACKBACK__)
        return pCell
    -- end
end


function StoryMissionsCollectionMediator:TabButtonAction(sender)
	local tag = sender:getTag()
	sender:setChecked(true)
	local senderlabel = sender:getChildByTag(1)
	if self.clickTag == tag then return end
	self.clickTag = tag

	local viewData = self.viewComponent.viewData
	viewData.storyButton:setChecked(false)
	viewData.branchButton:setChecked(false)
	local storylabel = viewData.storyButton:getChildByTag(1)
	local branchlabel = viewData.branchButton:getChildByTag(1)
	display.commonLabelParams(storylabel,fontWithColor(18 , {w = 150 , fontSize = 20 , hAlign = display.TAC}))
	display.commonLabelParams(branchlabel,fontWithColor(18 , {w = 150 , fontSize = 20 , hAlign = display.TAC}))

	sender:setChecked(true)
	display.commonLabelParams(senderlabel,fontWithColor(16 ,{w = 150 , fontSize = 20 , hAlign = display.TAC}))

	self.storyMissionsDatas = {}
	self.preIndex = 1
	-- dump(gameMgr:GetUserInfo().newestPlotTask)
	if tag == 1 then
		if table.nums(gameMgr:GetUserInfo().newestPlotTask) > 0 then

			for k,v in orderedPairs(CommonUtils.GetConfigAllMess(self.jsonName, 'quest')) do
				if k ~= '__orderedIndex' then
					if checkint(k) < checkint(gameMgr:GetUserInfo().newestPlotTask.taskId) then
						table.insert(self.storyMissionsDatas,v)
					else
						if checkint(k) > checkint(gameMgr:GetUserInfo().newestPlotTask.taskId) and checkint(gameMgr:GetUserInfo().newestPlotTask.hasDrawn) ~= 0 then
							if CommonUtils.CheckLockCondition(v.unlockType) then
								local  data = CommonUtils.GetConfig('quest', self.jsonName, gameMgr:GetUserInfo().newestPlotTask.taskId)
								table.insert(self.storyMissionsDatas,data)
							end
							break
						end
					end
				end
			end
		end
	else
		if table.nums(gameMgr:GetUserInfo().branchList) > 0 then
	        for id,val in pairs(gameMgr:GetUserInfo().branchList) do
	        	if checkint(val.status) == 3 then
	        		local data = CommonUtils.GetConfig('quest', 'branch', id)
	        		if data then
	        			table.insert(self.storyMissionsDatas,data)
	        		end
        		end
        	end
			self.storyMissionsDatas = {}
		end
	end

	local gridView = viewData.gridView
    gridView:setCountOfCell(table.nums(self.storyMissionsDatas))
    gridView:reloadData()
	if table.nums(self.storyMissionsDatas) == 0 then
		viewData.richLayout:setVisible(true)
	else
		viewData.richLayout:setVisible(false)
	end
    local cell = gridView:cellAtIndex(0)
    if cell then
    	cell.selectImg:setVisible(true)
    	viewData.desLabel:setString(self.storyMissionsDatas[1].descr)
    else
		viewData.desLabel:setString(__('暂无任务描述'))
    end
end

--[[
列表的单元格按钮的事件处理逻辑
@param sender button对象
--]]
function StoryMissionsCollectionMediator:CellButtonAction( sender )
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

    viewData.desLabel:setString(self.storyMissionsDatas[index].descr)
end


function StoryMissionsCollectionMediator:OnRegist(  )

end

function StoryMissionsCollectionMediator:OnUnRegist(  )
	--称出命令)
	local scene =  uiMgr:GetCurrentScene()
	scene:RemoveDialog(self:GetViewComponent())
end

return StoryMissionsCollectionMediator
