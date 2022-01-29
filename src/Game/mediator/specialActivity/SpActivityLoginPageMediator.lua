--[[
 * author : liuzhipeng
 * descpt : 特殊活动 登陆礼包活动页签mediator
]]
local SpActivityLoginPageMediator = class('SpActivityLoginPageMediator', mvc.Mediator)

local CreateView = nil
local SpActivityLoginPageView = require("Game.views.specialActivity.SpActivityLoginPageView")

function SpActivityLoginPageMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'SpActivityLoginPageMediator', viewComponent)
	self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function SpActivityLoginPageMediator:Initial(key)
    self.super.Initial(self, key)

    self.ownerNode_ = self.ctorArgs_.ownerNode

    -- create view
    if self.ownerNode_ then
        local size = self.ownerNode_:getContentSize()
        local view = SpActivityLoginPageView.new({size = size})
        display.commonUIParams(view, {po = cc.p(size.width * 0.5, size.height * 0.5)})
        self.ownerNode_:addChild(view,19)
        self:SetViewComponent(view)
        local viewData = self.viewComponent.viewData
    end
end


function SpActivityLoginPageMediator:CleanupView()
    if self.ownerNode_ then
        if self.viewComponent and self.viewComponent:getParent() then
            self.viewComponent:runAction(cc.RemoveSelf:create())
            self.viewComponent = nil
        end
        self.ownerNode_ = nil
    end
end


function SpActivityLoginPageMediator:OnRegist()
    regPost(POST.ACTIVITY_LOGIN_REWARD_DRAW)
end
function SpActivityLoginPageMediator:OnUnRegist()
    unregPost(POST.ACTIVITY_LOGIN_REWARD_DRAW)
end


function SpActivityLoginPageMediator:InterestSignals()
    local signals = {
        POST.ACTIVITY_LOGIN_REWARD_DRAW.sglName,
        SP_ACTIVITY_LOGIN_REWARD_CLICK
	}
	return signals
end
function SpActivityLoginPageMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.ACTIVITY_LOGIN_REWARD_DRAW.sglName then
        self:LoginRewardDraw(body)
    elseif name == SP_ACTIVITY_LOGIN_REWARD_CLICK then
        self:ChestClickEvent(body)
    end
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
function SpActivityLoginPageMediator:RefreshView()
    local viewComponent = self:GetViewComponent()
    viewComponent:RefreshRewardsProgress(self.homeData_)
end
--[[
宝箱点击回调
@params data map {
    tag int 按钮tag
    sender button 按钮
}
--]]
function SpActivityLoginPageMediator:ChestClickEvent( data )
    local tag = data.tag
    local sender = data.sender
    local homedata = self.homeData_
    if tag == checkint(homedata.today) then
        if checkint(homedata.hasTodayDrawn) == 0 then
            PlayAudioByClickNormal()
            self:SendSignal(POST.ACTIVITY_LOGIN_REWARD_DRAW.cmdName, {activityId = homedata.requestData.activityId})
        end
    elseif tag > homedata.today then
        PlayAudioByClickNormal()
        app.uiMgr:ShowInformationTipsBoard({
            targetNode = sender,title = __('奖励预览'), showAmount = true,iconIds = homedata.loginRewardList[tag].rewards, type = 4
        })
    end 
end
--[[
领取登录奖励
--]]
function SpActivityLoginPageMediator:LoginRewardDraw( data )
    local homeData = self.homeData_
    app.uiMgr:AddDialog('common.RewardPopup', {rewards = checktable(data.rewards)})
    homeData.hasTodayDrawn = 1
    homeData.loginRewardList[checkint(homeData.today)].hasDrawn = 1
    self:RefreshView()
end
-------------------------------------------------
-- public method
function SpActivityLoginPageMediator:resetHomeData(homeData)
	self.homeData_ = homeData
    self:RefreshView()
end


return SpActivityLoginPageMediator
