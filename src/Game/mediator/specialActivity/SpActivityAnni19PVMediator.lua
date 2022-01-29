--[[
 * author : liuzhipeng
 * descpt : 特殊活动 周年庆pv回顾页签mediator
]]
local SpActivityAnni19PVMediator = class('SpActivityAnni19PVMediator', mvc.Mediator)

local SpActivityAnniPVView = require("Game.views.specialActivity.SpActivityAnniPVView")

function SpActivityAnni19PVMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'SpActivityAnni19PVMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function SpActivityAnni19PVMediator:Initial(key)
    self.super.Initial(self, key)
    self.ownerNode_ = self.ctorArgs_.ownerNode
    self.typeData_  = self.ctorArgs_.typeData

    -- create view
    if self.ownerNode_ then
        local size = self.ownerNode_:getContentSize()
        local centerPos = self.ownerNode_:convertToNodeSpace(cc.p(display.cx, display.cy))
        local view = SpActivityAnniPVView.new({size = size})
        display.commonUIParams(view, {po = cc.p(size.width * 0.5, size.height * 0.5)})
        self.ownerNode_:addChild(view,19)
        self:SetViewComponent(view)
        local viewData = self.viewComponent.viewData
        viewData.pvBtn:setOnClickScriptHandler(handler(self, self.PVButtonCallback))
        viewData.anniBtn:setOnClickScriptHandler(handler(self, self.AnniButtonCallback))
    end
end


function SpActivityAnni19PVMediator:CleanupView()
    if self.ownerNode_ then
        if self.viewComponent and self.viewComponent:getParent() then
            self.viewComponent:runAction(cc.RemoveSelf:create())
            self.viewComponent = nil
        end
        self.ownerNode_ = nil
    end
end


function SpActivityAnni19PVMediator:OnRegist()
end
function SpActivityAnni19PVMediator:OnUnRegist()
end


function SpActivityAnni19PVMediator:InterestSignals()
    local signals = {
	}
	return signals
end
function SpActivityAnni19PVMediator:ProcessSignal(signal)
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
回看按钮回调
--]]
function SpActivityAnni19PVMediator:PVButtonCallback( sender )
    PlayAudioByClickNormal()
    app.anniversary2019Mgr:ShowReviewAnimationDialog()
end
--[[
h5按钮回调
--]]
function SpActivityAnni19PVMediator:AnniButtonCallback( sender )
    PlayAudioByClickNormal()
    app.anniversary2019Mgr:OpenReviewBrowserUrl()
end
-------------------------------------------------
-- public method
function SpActivityAnni19PVMediator:resetHomeData(homeData)
    self.homeData_ = homeData
end


return SpActivityAnni19PVMediator
