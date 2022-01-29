--[[
 * author : liuzhipeng
 * descpt : 特殊活动 兑换活动页签mediator
]]
local SpActivityExchangePageMediator = class('SpActivityExchangePageMediator', mvc.Mediator)

local CreateView = nil
local SpActivityExchangePageView = require("Game.views.specialActivity.SpActivityExchangePageView")

function SpActivityExchangePageMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'SpActivityExchangePageMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function SpActivityExchangePageMediator:Initial(key)
    self.super.Initial(self, key)
    self.ownerNode_ = self.ctorArgs_.ownerNode
    self.typeData_  = self.ctorArgs_.typeData
    self.homeData_  = {}

    -- create view
    if self.ownerNode_ then
        local size = self.ownerNode_:getContentSize()
        local view = SpActivityExchangePageView.new({size = size})
        display.commonUIParams(view, {po = cc.p(size.width * 0.5, size.height * 0.5)})
        self.ownerNode_:addChild(view,19)
        self:SetViewComponent(view)
        local viewData = self.viewComponent.viewData
        viewData.enterBtn:setOnClickScriptHandler(handler(self, self.EnterButtonCallback))
    end

end


function SpActivityExchangePageMediator:CleanupView()
    if self.ownerNode_ then
        if self.viewComponent and self.viewComponent:getParent() then
            self.viewComponent:runAction(cc.RemoveSelf:create())
            self.viewComponent = nil
        end
        self.ownerNode_ = nil
    end
end


function SpActivityExchangePageMediator:OnRegist()
end
function SpActivityExchangePageMediator:OnUnRegist()
end


function SpActivityExchangePageMediator:InterestSignals()
    local signals = {
	}
	return signals
end
function SpActivityExchangePageMediator:ProcessSignal(signal)
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
function SpActivityExchangePageMediator:RefreshView()
    local viewComponent = self:GetViewComponent()
end
--[[
前往按钮回调
--]]
function SpActivityExchangePageMediator:EnterButtonCallback( sender )
    PlayAudioByClickNormal()
	local activityId = checkint(self.typeData_.activityId)
	local activityHomeDatas = self.typeData_
    local activityDatas = self.homeData_
    local leftSeconds = checkint(activityHomeDatas.closeTimestamp_) - os.time()
	-- 添加开始剧情
	local function enterView ()
		local temp = {homeDatas = activityDatas}
		local mediator = require( 'Game.mediator.ActivityPropExchangeMediator').new({data = {activityId = activityId,  activityHomeDatas = temp, leftSeconds = leftSeconds, tag = 110120, isAddDialog = true}})
		self:GetFacade():RegistMediator(mediator)
	end
	if checkint(activityDatas.startStoryId) > 0 then
		app.activityMgr:ShowActivityStory({
			activityId = activityId,
			storyId = activityDatas.startStoryId,
			storyType = 'START',
			callback = enterView
		})
	else
        if next(activityDatas) ~= nil then
            enterView()
        end
	end
end
-------------------------------------------------
-- public method
function SpActivityExchangePageMediator:resetHomeData(homeData)
    self.homeData_ = homeData
    self:RefreshView()
end


return SpActivityExchangePageMediator
