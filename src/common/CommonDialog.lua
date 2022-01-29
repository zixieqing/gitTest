--[[
通用弹窗
@params table {
	tag int self tag
}
--]]
local CommonDialog = class('CommonDialog', function ()
	local node = CLayout:create(display.size)
	node.name = 'common.CommonDialog'
	node:enableNodeEvents()
	return node
end)

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")

function CommonDialog:ctor( ... )
	self.args = unpack({...}) or {}
	self.viewData = nil
	self.commonBg = nil
    if self.args.name then
        self.name = self.args.name
    end
    self.isNeedCloseLayer = true
    if self.args.isNeedCloseLayer == false then
        self.isNeedCloseLayer = self.args.isNeedCloseLayer
	end
	self.executeAction = self.args.executeAction
	self.delayFuncList_ = self.args.delayFuncList_ or {}
    if self.args.tag then
        self:setTag(checkint(self.args.tag))
    end
	self:InitialUI()
	self:AddCloseFrame()
end


function CommonDialog:InitialUI()
	local function CreateView()
		return {
			
		}
	end

	self.viewData = CreateView()
end


function CommonDialog:AddCloseFrame()
	if self.viewData.view then
		local commonBg = require('common.CloseBagNode').new(
			{showLabel = self.showLabel == nil and true or self.showLabel, callback = function ()
				if nil ~= self.delayFuncList_ then
					if table.nums(self.delayFuncList_ ) > 0 then
						self.delayFuncList_[1]()
						self.delayFuncList_ = nil   -- 防止二次调用
					end 
				end
				if self.isNeedCloseLayer then
					self:CloseHandler()
				end
			end , executeAction = self.executeAction })
		commonBg:setPosition(utils.getLocalCenter(self))
		commonBg:setEnableAction(self.executeAction)
		self:addChild(commonBg)
        commonBg:setName('CLOSE_BAG')
		commonBg:addContentView(self.viewData.view)
	end
end
function CommonDialog:setEnableAction(isTrue)
	self.executeAction = isTrue 
	-- -- body
end
function CommonDialog:CloseHandler()
	-- if self.args.mediatorName and self.args.tag then
	-- 	local mediator = AppFacade.GetInstance():RetrieveMediator(self:GetParentMediatorName())
	-- 	if mediator then
	-- 		mediator:GetViewComponent():RemoveDialogByTag(self.args.tag)
	-- 	end
	-- end

	local currentScene = uiMgr:GetCurrentScene()
	if currentScene then
		-- currentScene:RemoveDialog(self)
		AppFacade.GetInstance():DispatchObservers('CLOSE_COMMON_DIALOG')
		if self.args.tag then
			currentScene:RemoveDialogByTag(self.args.tag)
		else
			currentScene:RemoveDialog(self)
		end
	end
end

--[[
获取管理此弹窗的mediator的name
--]]
function CommonDialog:GetParentMediatorName()
	return self.args.mediatorName
end


return CommonDialog
