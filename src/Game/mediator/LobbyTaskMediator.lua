--[[
餐厅任务页面Mediator
--]]
local Mediator = mvc.Mediator

local LobbyTaskMediator = class("LobbyTaskMediator", Mediator)

local NAME = "LobbyTaskMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local LobbyTaskCell = require('home.LobbyTaskCell')
function LobbyTaskMediator:ctor( params, viewComponent )
	self.restaurantTasks = params.restaurantTasks
	self.super:ctor(NAME,viewComponent)
	self.taskTable = {}
	self.selectTask = nil -- 当前选中的任务
	self.isSelected = nil -- 当前是否有选中的任务
	self.canChoose = true
end


function LobbyTaskMediator:InterestSignals()
	local signals = {
		SIGNALNAMES.Restaurant_ChooseRestaurantTask_Callback,
		SIGNALNAMES.Restaurant_CancelRestaurantTask_Callback,
	}

	return signals
end

function LobbyTaskMediator:ProcessSignal( signal )
	local name = signal:GetName()
	print(name)
	if name == SIGNALNAMES.Restaurant_ChooseRestaurantTask_Callback then
		local datas = signal:GetBody()
		self.canChoose = false
		local chooseNum = nil
		for i,v in ipairs(self.restaurantTasks) do
			if v.taskId ==  datas.requestData.taskId then
				chooseNum = i
				break
			end
		end
		self.restaurantTasks[1] = self.restaurantTasks[chooseNum]
		self.restaurantTasks[1].progress = 0
		table.remove(self.restaurantTasks)
		table.remove(self.restaurantTasks)
		self.isSelected = true
		self:ChooseAction(chooseNum)
	elseif name == SIGNALNAMES.Restaurant_CancelRestaurantTask_Callback then
		local datas = signal:GetBody()
		local avatarMediator = AppFacade.GetInstance():RetrieveMediator('AvatarMediator')
		avatarMediator:UpdateTaskButtonStatus(datas.nextRestaurantTaskLeftSeconds)
		AppFacade.GetInstance():UnRegsitMediator("LobbyTaskMediator")
	end
end

function LobbyTaskMediator:Initial( key )
	self.super.Initial(self, key)
	local scene = uiMgr:GetCurrentScene()
	local viewComponent = require( 'Game.views.LobbyTaskView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)
	viewComponent.eaterLayer:setOnClickScriptHandler(function()
		AppFacade.GetInstance():UnRegsitMediator("LobbyTaskMediator")
	end)
	self:UpdateUI()
end
function LobbyTaskMediator:UpdateUI(  )
	local viewData = self:GetViewComponent().viewData_
	local function CreateTaskCard(datas, choose)
		local BASEREWARD = {
			GOLD_ID,
			DIAMOND_ID,
			POPULARITY_ID
		}
		local taskData = CommonUtils.GetConfigNoParser('restaurant', 'task', datas.taskId)
		local taskCard = LobbyTaskCell.new(cc.size(430, 500))
		table.insert(self.taskTable, taskCard)
		local title, descr = self:GetTeskDescr(datas)
		taskCard.titleLabel:setString(title)
		taskCard.descrLabel:setString(descr)
		local baseRewards = {}
		local goodsRewards = {}
		for i,v in ipairs(taskData.rewards) do
			for index,id in ipairs(BASEREWARD) do
				if id == v.goodsId then
					table.insert(baseRewards, v)
					break
				end
				if index == #taskData.rewards then
					table.insert(goodsRewards, v)
				end
			end
		end
		-- 基础奖励
		local baseRewardLayout = CLayout:create(cc.size(100 + (#baseRewards-1)*130, 40))
		baseRewardLayout:setPosition(cc.p(taskCard.size.width/2, 190))
		taskCard:addChild(baseRewardLayout, 10)
		for i,v in ipairs(baseRewards) do
			local num = cc.Label:createWithBMFont('font/small/common_text_num.fnt', v.num)
			display.commonUIParams(num, {ap = cc.p(0, 0.5)})
			num:setPosition(cc.p((i-1)*120, 20))
			baseRewardLayout:addChild(num, 10)
			local icon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(v.goodsId)), num:getContentSize().width+(i-1)*120, 20, {ap = cc.p(0, 0.5)})
			icon:setScale(0.2)
			baseRewardLayout:addChild(icon, 10)
		end
		-- 物品奖励
		local goodsRewardLayout = CLayout:create(cc.size(90 + (#goodsRewards-1)*120, 100))
		goodsRewardLayout:setPosition(cc.p(taskCard.size.width/2, 110))
		taskCard:addChild(goodsRewardLayout, 10)
		for i,v in ipairs(goodsRewards) do
			local function callBack(sender)
				AppFacade.GetInstance():GetManager("UIManager"):ShowInformationTipsBoard({targetNode = sender, iconId = v.goodsId, type = 1})
			end
			local goodsNode = require('common.GoodNode').new({id = v.goodsId, amount = v.num, showAmount = true,callBack = callBack})
			goodsNode:setPosition(cc.p(45 + (#goodsRewards-1)*120, 50))
			goodsRewardLayout:addChild(goodsNode, 10)
			goodsNode:setScale(0.82)
		end

 		if choose == true then
			taskCard.cardBtn:setNormalImage(_res('ui/home/lobby/task/restaurant_task_bg_choice_selected.png'))
			taskCard.cardBtn:setSelectedImage(_res('ui/home/lobby/task/restaurant_task_bg_choice_selected.png'))
    		taskCard.progressBar:setMaxValue(checkint(datas.targetNum))
    		taskCard.progressBar:setValue(datas.progress)
    		taskCard.progressBar:setVisible(true)
    		taskCard.progressLabel:setString(tostring(datas.progress) .. '/' .. tostring(datas.targetNum))
    		taskCard.progressLabel:setVisible(true)
		end

		return taskCard
	end
	if table.nums(self.restaurantTasks) == 1 then
		self.isSelected = true
		local taskCard = CreateTaskCard(clone(self.restaurantTasks[1]), true)
		viewData.view:addChild(taskCard, 10)
		taskCard:setPosition(cc.p(display.cx,display.cy - 40))
		viewData.revokeBtn:setVisible(true)
		viewData.revokeBtn:setOnClickScriptHandler(handler(self, self.ButtonCallback))
	elseif table.nums(self.restaurantTasks) == 3 then
		for i,v in ipairs(self.restaurantTasks) do
			self.isSelected = false
			local taskCard = CreateTaskCard(clone(self.restaurantTasks[i]), false)
			viewData.view:addChild(taskCard, 10)
			taskCard:setPosition(cc.p(display.cx - 840 + i * 420,display.cy - 40))
			taskCard.cardBtn:setTag(i)
			viewData.revokeBtn:setOnClickScriptHandler(handler(self, self.ButtonCallback))
			taskCard.cardBtn:setOnClickScriptHandler(handler(self, self.TaskCardCallback))
		end
		viewData.revokeBtn:setVisible(true)
		viewData.revokeBtn:getLabel():setString(__('确定'))
	else
		print('任务数据错误')
	end
end
--[[
任务点击回调
--]]
function LobbyTaskMediator:TaskCardCallback( sender )
	local tag = sender:getTag()
	if not self.canChoose or not self.taskTable[tag] then
		return
	end
	if tag == self.selectTask then return end
	-- 添加点击音效
	PlayAudioByClickNormal()
	if self.selectTask then
		self.taskTable[self.selectTask].cardBtn:setNormalImage(_res('ui/home/lobby/task/restaurant_task_bg_choice.png'))
		self.taskTable[self.selectTask].cardBtn:setSelectedImage(_res('ui/home/lobby/task/restaurant_task_bg_choice.png'))
	end
	self.taskTable[tag]:runAction(
		cc.Sequence:create(
			cc.ScaleTo:create(0.1, 1.1),
			cc.ScaleTo:create(0.1, 1)
		)
	)

	self.taskTable[tag].cardBtn:setNormalImage(_res('ui/home/lobby/task/restaurant_task_bg_choice_selected.png'))
	self.taskTable[tag].cardBtn:setSelectedImage(_res('ui/home/lobby/task/restaurant_task_bg_choice_selected.png'))
	self.selectTask = tag
end
--[[
任务选中动画
--]]
function LobbyTaskMediator:ChooseAction( chooseNum )
	local viewData = self:GetViewComponent().viewData_
	viewData.revokeBtn:getLabel():setString(__('撤销'))
	for i,v in ipairs(self.taskTable) do
		if i == chooseNum then -- 选中
			self.taskTable[i]:runAction(
				cc.Sequence:create(
					cc.MoveTo:create(0.5, cc.p(display.cx, display.cy - 40)),
					cc.CallFunc:create(function ()
						self:ChangeTaskStatus(v, chooseNum)
						local revokeBtn = self:GetViewComponent().viewData_.revokeBtn
						revokeBtn:setOnClickScriptHandler(handler(self, self.ButtonCallback))
						revokeBtn:setOpacity(0)
						revokeBtn:setVisible(true)
						revokeBtn:runAction(cc.FadeIn:create(0.3))
					end),
					cc.EaseSineOut:create(cc.ScaleTo:create(0.15, 1.1)),
					cc.EaseSineIn:create(cc.ScaleTo:create(0.15, 1))
				)
			)
		else -- 未选中
            local cellNode = self.taskTable[i]
			cellNode:runAction(
				cc.Sequence:create(
					cc.Spawn:create(
						cc.FadeOut:create(0.5),
						cc.MoveBy:create(0.5, cc.p(0, - 100))
					),
				cc.RemoveSelf:create()
				)
			)
            self.taskTable[i] = nil
		end
	end
end
--[[
更改任务状态
@params taskCard userdata 任务卡牌
--]]
function LobbyTaskMediator:ChangeTaskStatus( taskCard )
	taskCard.cardBtn:setNormalImage(_res('ui/home/lobby/task/restaurant_task_bg_choice_selected.png'))
	taskCard.cardBtn:setSelectedImage(_res('ui/home/lobby/task/restaurant_task_bg_choice_selected.png'))
    taskCard.progressBar:setMaxValue(checkint(self.restaurantTasks[1].targetNum))
    taskCard.progressBar:setValue(0)
    taskCard.progressBar:setVisible(true)
    taskCard.progressLabel:setString('0/' .. tostring(self.restaurantTasks[1].targetNum))
    taskCard.progressLabel:setVisible(true)
end
--[[
按钮回调
--]]
function LobbyTaskMediator:ButtonCallback( sender )
	-- 判断按钮状态
	if self.isSelected then
		local scene = uiMgr:GetCurrentScene()
	 	local CommonTip  = require( 'common.NewCommonTip' ).new({text = __('是否取消制作？'),
	 		extra = __('Tips:取消任务后将会有2小时的冷却时间'),
	 		isOnlyOK = false, callback = function ()
	    		print('确定')
				self:SendSignal(COMMANDS.COMMAND_Restaurant_CancelRestaurantTask)
			end,
			cancelBack = function ()
				print('返回')
			end
		})
		CommonTip.tip:setPosition(CommonTip.size.width /2 , CommonTip.size.height - 50 )
		CommonTip.extra:setPosition(CommonTip.size.width /2 , CommonTip.size.height - 120 )
		CommonTip:setPosition(display.center)
		scene:AddDialog(CommonTip)
	else
		if self.selectTask then
			if self.canChoose then
				self:SendSignal(COMMANDS.COMMAND_Restaurant_ChooseRestaurantTask, {taskId = self.restaurantTasks[self.selectTask].taskId})
			end
		else
			uiMgr:ShowInformationTips(__('请选择一个任务'))
		end
	end

end
function LobbyTaskMediator:UpdateTaskProgress(progress, targetNum)
	if table.nums(self.taskTable) > 0 and self.taskTable[1] then
		if self.taskTable[1].progressBar then
			self.taskTable[1].progressBar:setValue(checkint(progress))
		end
		if self.taskTable[1].progressLabel then
			self.taskTable[1].progressLabel:setString(tostring(progress) .. '/' .. tostring(targetNum))
		end
    end
end
function LobbyTaskMediator:GetTeskDescr( datas )
	local datas = datas or {}
	local taskData = CommonUtils.GetConfigNoParser('restaurant', 'task', datas.taskId) or {}
	local title = taskData.name or ''
	local descr = taskData.descr or ''
	local type = nil
	local targetData = {}
	local TARGETID_TYPE = {
		goods    = 1,
		customer = 2,
		style    = 3,
		empty    = 4
	}
	print(taskData.taskType)
	if checkint(taskData.taskType) == 1 then
		type = TARGETID_TYPE.goods
	elseif checkint(taskData.taskType) == 2 then
		type = TARGETID_TYPE.customer
	elseif checkint(taskData.taskType) == 3 then
		type = TARGETID_TYPE.goods
	elseif checkint(taskData.taskType) == 4 then
		type = TARGETID_TYPE.goods
	elseif checkint(taskData.taskType) == 5 then
		type = TARGETID_TYPE.style
	elseif checkint(taskData.taskType) == 6 then
		type = TARGETID_TYPE.style
	elseif checkint(taskData.taskType) == 7 then
		type = TARGETID_TYPE.empty
	elseif checkint(taskData.taskType) == 8 then
		type = TARGETID_TYPE.empty
	end
	if type == TARGETID_TYPE.goods then
		targetData = CommonUtils.GetConfig('goods', 'goods', checktable(datas.targetId)[1]) or {}
		title = string.gsub(title, '_target_id_', tostring(targetData.name), 1)
		descr = string.gsub(descr, '_target_id_', tostring("  " ..  targetData.name ..  "  "), 1)
	elseif type == TARGETID_TYPE.customer then
		targetData = CommonUtils.GetConfigNoParser('restaurant', 'customer', checktable(datas.targetId)[1]) or {}
		title = string.gsub(title, '_target_id_', tostring(targetData.name), 1)
		descr = string.gsub(descr, '_target_id_', tostring("  " ..  targetData.name ..  "  "), 1)
	elseif type == TARGETID_TYPE.style then
		targetData = CommonUtils.GetConfigNoParser('cooking', 'style', checktable(datas.targetId)[1]) or {}
		title = string.gsub(title, '_target_id_', tostring(targetData.name), 1)
		descr = string.gsub(descr, '_target_id_', tostring("  " ..  targetData.name ..  "  "), 1)
	elseif type == TARGETID_TYPE.empty then
	end
	descr = string.gsub(descr, '_target_num_', tostring("  " ..  datas.targetNum .. "  " ), 1)
	return title, descr
end
function LobbyTaskMediator:OnRegist(  )
	local LobbyTaskCommand = require( 'Game.command.LobbyTaskCommand' )
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Restaurant_ChooseRestaurantTask, LobbyTaskCommand)
	self:GetFacade():RegistSignal(COMMANDS.COMMAND_Restaurant_CancelRestaurantTask, LobbyTaskCommand)
end

function LobbyTaskMediator:OnUnRegist(  )
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Restaurant_ChooseRestaurantTask)
	self:GetFacade():UnRegsitSignal(COMMANDS.COMMAND_Restaurant_CancelRestaurantTask)
	self:GetViewComponent():runAction(cc.RemoveSelf:create())
end

return LobbyTaskMediator
