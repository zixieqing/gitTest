---@class ScratcherTaskProgressMediator : Mediator
---@field viewComponent ScratcherTaskProgressView
local ScratcherTaskProgressMediator = class('ScratcherTaskProgressMediator', mvc.Mediator)

local NAME = "ScratcherTaskProgressMediator"

function ScratcherTaskProgressMediator:ctor(params, viewComponent)
	self.super.ctor(self, NAME, viewComponent)

	self.data = checktable(params) or {}

	self.tasks = self.data.myTask
	self.taskContent = CONF.FOOD_VOTE.TASK:GetAll()
end

function ScratcherTaskProgressMediator:Initial(key)
	self.super.Initial(self, key)
	local scene = app.uiMgr:GetCurrentScene()
	local viewComponent = require('Game.views.scratcher.ScratcherTaskProgressView').new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)
	local viewData = viewComponent.viewData
	viewData.eaterLayer:setOnClickScriptHandler(handler(self, self.OnBackBtnClickHandler))

	local taskMap = {}
	for taskId, value in pairs(self.tasks or {}) do
		local taskType = self.taskContent[taskId].taskType
		taskMap[tostring(taskType)] = checkint(value)
	end

	local taskList = {
		{ type = 41,  title	= __("完成邪神遗迹层数：")},
		{ type = 50,  title	= __("完成皇家对决次数：")},
		{ type = 3,   title	= __("完成通过关卡次数：")},
		{ type = 118, title	= __("完成包厢招待次数：")},
		{ type = 88,  title	= __("完成公共订单次数：")},
	}
	local content = {}
	local tasks = self.taskContent
	for index, data in ipairs(taskList) do
		local taskValue = checkint(taskMap[tostring(data.type)])
		content[#content+1] = data.title
		content[#content+1] = taskValue
		content[#content+1] = "\n\n"
	end
	content[#content+1] = __("刮刮乐次数：")
	content[#content+1] = checkint(self.data.myLotteryPlay)

	viewData.taskProgressLabel:setString(table.concat( content ))
end

function ScratcherTaskProgressMediator:OnRegist()
end

function ScratcherTaskProgressMediator:OnUnRegist()
	local scene = app.uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
end

function ScratcherTaskProgressMediator:InterestSignals()
    local signals = {
	}
	return signals
end

function ScratcherTaskProgressMediator:ProcessSignal(signal)
    local name = signal:GetName()
	local body = signal:GetBody()
	-- dump(body, name)
end

function ScratcherTaskProgressMediator:OnBackBtnClickHandler( sender )
	PlayAudioByClickClose()
	
    app:UnRegsitMediator(NAME)
end

return ScratcherTaskProgressMediator
