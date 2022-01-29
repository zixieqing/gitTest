--[[
 * author : liuzhipeng
 * descpt : 特殊活动 选卡卡池页签mediator
]]
local SpActivityChooseCardPageMediator = class('SpActivityChooseCardPageMediator', mvc.Mediator)

local SpActivityChooseCardPageView = require("Game.views.specialActivity.SpActivityChooseCardPageView")

function SpActivityChooseCardPageMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'SpActivityChooseCardPageMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function SpActivityChooseCardPageMediator:Initial(key)
    self.super.Initial(self, key)
    self.ownerNode_ = self.ctorArgs_.ownerNode
    self.typeData_  = self.ctorArgs_.typeData

    -- create view
    if self.ownerNode_ then
        local size = self.ownerNode_:getContentSize()
        local centerPos = self.ownerNode_:convertToNodeSpace(cc.p(display.cx, display.cy))
        local view = SpActivityChooseCardPageView.new({size = size})
        display.commonUIParams(view, {po = cc.p(size.width * 0.5, size.height * 0.5)})
        self.ownerNode_:addChild(view,19)
        self:SetViewComponent(view)
        local viewData = self.viewComponent.viewData
        viewData.enterBtn:setOnClickScriptHandler(handler(self, self.EnterButtonCallback))
    end
end


function SpActivityChooseCardPageMediator:CleanupView()
    if self.ownerNode_ then
        if self.viewComponent and self.viewComponent:getParent() then
            self.viewComponent:runAction(cc.RemoveSelf:create())
            self.viewComponent = nil
        end
        self.ownerNode_ = nil
    end
end


function SpActivityChooseCardPageMediator:OnRegist()
end
function SpActivityChooseCardPageMediator:OnUnRegist()
end


function SpActivityChooseCardPageMediator:InterestSignals()
    local signals = {
	}
	return signals
end
function SpActivityChooseCardPageMediator:ProcessSignal(signal)
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
function SpActivityChooseCardPageMediator:EnterButtonCallback( sender )
    PlayAudioByClickNormal()
    app:RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'}, {name = 'drawCards.CapsuleNewMediator', params = {activityId = self.typeData_.activityId}})
end
-------------------------------------------------
-- public method
function SpActivityChooseCardPageMediator:resetHomeData(homeData)
    self.homeData_ = homeData
end


return SpActivityChooseCardPageMediator
