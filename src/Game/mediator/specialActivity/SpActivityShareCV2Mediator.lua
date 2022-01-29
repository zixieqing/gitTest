--[[
 * author : liuzhipeng
 * descpt : 特殊活动 通用跳转页签mediator
]]
local SpActivityShareCV2Mediator = class('SpActivityShareCV2Mediator', mvc.Mediator)

local SpActivityCommonPageView = require("Game.views.specialActivity.SpActivityShareCV2View")

function SpActivityShareCV2Mediator:ctor(params, viewComponent)
	self.super.ctor(self, 'SpActivityShareCV2Mediator', viewComponent)
	self.ctorArgs_ = checktable(params)
	self.typeData = self.ctorArgs_.typeData
	self.detail = self.typeData.rule[i18n.getLang()] or ""
	self.title = self.typeData.title[i18n.getLang()] or ""
end


-------------------------------------------------
-- inheritance method

function SpActivityShareCV2Mediator:Initial(key)
	self.super.Initial(self, key)
	self.ownerNode_ = self.ctorArgs_.ownerNode
	self.typeData_  = self.ctorArgs_.typeData

	-- create view
	if self.ownerNode_ then
		local size = self.ownerNode_:getContentSize()
		local centerPos = self.ownerNode_:convertToNodeSpace(cc.p(display.cx, display.cy))
		local view = SpActivityCommonPageView.new({size = size})
		display.commonUIParams(view, {po = cc.p(size.width * 0.5, size.height * 0.5)})
		self.ownerNode_:addChild(view,19)
		self:SetViewComponent(view)
		local viewData = self.viewComponent.viewData
		viewData.enterTaskBtn:setOnClickScriptHandler(handler(self, self.EnterTaskCallback))
		viewData.enterPlotBtn:setOnClickScriptHandler(handler(self, self.EnterPlotCallback))
	end
end


function SpActivityShareCV2Mediator:CleanupView()
	if self.ownerNode_ then
		if self.viewComponent and self.viewComponent:getParent() then
			self.viewComponent:runAction(cc.RemoveSelf:create())
			self.viewComponent = nil
		end
		self.ownerNode_ = nil
	end
end


function SpActivityShareCV2Mediator:OnRegist()
end
function SpActivityShareCV2Mediator:OnUnRegist()
end


function SpActivityShareCV2Mediator:InterestSignals()
	local signals = {
	}
	return signals
end
function SpActivityShareCV2Mediator:ProcessSignal(signal)
	local name = signal:GetName()
	local body = signal:GetBody()
end


-------------------------------------------------
-- handler method

-------------------------------------------------
-- get /set
-------------------------------------------------
-- private method
--[[
前往按钮回调
--]]
function SpActivityShareCV2Mediator:EnterTaskCallback( sender )
	PlayAudioByClickNormal()
	local mediator = require("Game.mediator.activity.shareCV2.ShareCV2TaskMediator").new({detail  = self.detail ,title = self.title })
	app:RegistMediator(mediator)
end
--[[
前往按钮回调
--]]
function SpActivityShareCV2Mediator:EnterPlotCallback( sender )
	PlayAudioByClickNormal()
	local mediator = require("Game.mediator.activity.shareCV2.ShareCV2PlotMediator").new()
	app:RegistMediator(mediator)

end
-------------------------------------------------
-- public method
function SpActivityShareCV2Mediator:resetHomeData(homeData)
	self.homeData_ = homeData
end


return SpActivityShareCV2Mediator
