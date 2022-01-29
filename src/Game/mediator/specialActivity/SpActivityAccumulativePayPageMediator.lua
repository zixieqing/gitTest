--[[
 * author : liuzhipeng
 * descpt : 特殊活动 累充活动页签mediator
]]
local SpActivityAccumulativePayPageMediator = class('SpActivityAccumulativePayPageMediator', mvc.Mediator)

local CreateView = nil
local SpActivityAccumulativePayPageView = require("Game.views.specialActivity.SpActivityAccumulativePayPageView")

function SpActivityAccumulativePayPageMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'SpActivityAccumulativePayPageMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function SpActivityAccumulativePayPageMediator:Initial(key)
    self.super.Initial(self, key)
    self.ownerNode_ = self.ctorArgs_.ownerNode
    self.typeData_  = self.ctorArgs_.typeData

    -- create view
    if self.ownerNode_ then
        local size = self.ownerNode_:getContentSize()
        local view = SpActivityAccumulativePayPageView.new({size = size})
        display.commonUIParams(view, {po = cc.p(size.width * 0.5, size.height * 0.5)})
        self.ownerNode_:addChild(view,19)
        self:SetViewComponent(view)
        local viewData = self.viewComponent.viewData
        viewData.enterBtn:setOnClickScriptHandler(handler(self, self.EnterButtonCallback))
    end
end


function SpActivityAccumulativePayPageMediator:CleanupView()
    if self.ownerNode_ then
        if self.viewComponent and self.viewComponent:getParent() then
            self.viewComponent:runAction(cc.RemoveSelf:create())
            self.viewComponent = nil
        end
        self.ownerNode_ = nil
    end
end


function SpActivityAccumulativePayPageMediator:OnRegist()
end
function SpActivityAccumulativePayPageMediator:OnUnRegist()
end


function SpActivityAccumulativePayPageMediator:InterestSignals()
    local signals = {
	}
	return signals
end
function SpActivityAccumulativePayPageMediator:ProcessSignal(signal)
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
刷新页面
--]]
function SpActivityAccumulativePayPageMediator:RefreshView()
    local viewComponent = self:GetViewComponent()
end
--[[
前往按钮回调
--]]
function SpActivityAccumulativePayPageMediator:EnterButtonCallback( sender )
    PlayAudioByClickNormal()
	local activityId = checkint(self.typeData_.activityId)
	local activityHomeDatas = self.typeData_
    local activityDatas = self.homeData_
    local leftSeconds = checkint(activityHomeDatas.closeTimestamp_) - os.time()
	activityHomeDatas.homeDatas = clone(activityDatas)
	local mediator = require( 'Game.mediator.ActivityPropExchangeMediator').new({data = {activityId = activityId, activityHomeDatas = activityHomeDatas, leftSeconds = leftSeconds, tag = 110122}})
	self:GetFacade():RegistMediator(mediator)
end
-------------------------------------------------
-- public method
function SpActivityAccumulativePayPageMediator:resetHomeData(homeData)
    self.homeData_ = homeData
    self:RefreshView()
end


return SpActivityAccumulativePayPageMediator
