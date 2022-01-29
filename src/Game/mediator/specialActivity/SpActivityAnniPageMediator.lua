--[[
 * author : liuzhipeng
 * descpt : 特殊活动 周年庆活动页签mediator
]]
local SpActivityAnniPageMediator = class('SpActivityAnniPageMediator', mvc.Mediator)

local CreateView = nil
local SpActivityAnniPageView = require("Game.views.specialActivity.SpActivityAnniPageView")

function SpActivityAnniPageMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'SpActivityAnniPageMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function SpActivityAnniPageMediator:Initial(key)
    self.super.Initial(self, key)
    self.ownerNode_ = self.ctorArgs_.ownerNode
    self.typeData_  = self.ctorArgs_.typeData

    -- create view
    if self.ownerNode_ then
        local size = self.ownerNode_:getContentSize()
        local view = SpActivityAnniPageView.new({size = size})
        display.commonUIParams(view, {po = cc.p(size.width * 0.5, size.height * 0.5)})
        self.ownerNode_:addChild(view,19)
        self:SetViewComponent(view)
        local viewData = self.viewComponent.viewData
        viewData.enterBtn:setOnClickScriptHandler(handler(self, self.EnterButtonCallback))
    end
end


function SpActivityAnniPageMediator:CleanupView()
    if self.ownerNode_ then
        if self.viewComponent and self.viewComponent:getParent() then
            self.viewComponent:runAction(cc.RemoveSelf:create())
            self.viewComponent = nil
        end
        self.ownerNode_ = nil
    end
end


function SpActivityAnniPageMediator:OnRegist()
end
function SpActivityAnniPageMediator:OnUnRegist()
end


function SpActivityAnniPageMediator:InterestSignals()
    local signals = {
	}
	return signals
end
function SpActivityAnniPageMediator:ProcessSignal(signal)
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
function SpActivityAnniPageMediator:RefreshView()
    local viewComponent = self:GetViewComponent()
end
--[[
前往按钮回调
--]]
function SpActivityAnniPageMediator:EnterButtonCallback( sender )
    PlayAudioByClickNormal()
	local activityId = checkint(self.typeData_.activityId)
	local activityHomeDatas = self.typeData_
    local activityDatas = self.homeData_
    local leftSeconds = checkint(activityHomeDatas.closeTimestamp_) - os.time()
    -- 跳转至周年庆活动副本
    app.anniversaryMgr:EnterAnniversary()
end
-------------------------------------------------
-- public method
function SpActivityAnniPageMediator:resetHomeData(homeData)
    self.homeData_ = homeData
    self:RefreshView()
end


return SpActivityAnniPageMediator
