--[[
 * author : liuzhipeng
 * descpt : 特殊活动 活动副本页签mediator
]]
local SpActivityQuestPageMediator = class('SpActivityQuestPageMediator', mvc.Mediator)

local CreateView = nil
local SpActivityQuestPageView = require("Game.views.specialActivity.SpActivityQuestPageView")

function SpActivityQuestPageMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'SpActivityQuestPageMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function SpActivityQuestPageMediator:Initial(key)
    self.super.Initial(self, key)
    self.ownerNode_ = self.ctorArgs_.ownerNode
    self.typeData_  = self.ctorArgs_.typeData

    -- create view
    if self.ownerNode_ then
        local size = self.ownerNode_:getContentSize()
        local view = SpActivityQuestPageView.new({size = size})
        display.commonUIParams(view, {po = cc.p(size.width * 0.5, size.height * 0.5)})
        self.ownerNode_:addChild(view,19)
        self:SetViewComponent(view)
        local viewData = self.viewComponent.viewData
        viewData.exchangeBtn:setOnClickScriptHandler(handler(self, self.ExchangeButtonCallback))
        viewData.enterBtn:setOnClickScriptHandler(handler(self, self.EnterButtonCallback))
    end
end


function SpActivityQuestPageMediator:CleanupView()
    if self.ownerNode_ then
        if self.viewComponent and self.viewComponent:getParent() then
            self.viewComponent:runAction(cc.RemoveSelf:create())
            self.viewComponent = nil
        end
        self.ownerNode_ = nil
    end
end


function SpActivityQuestPageMediator:OnRegist()
end
function SpActivityQuestPageMediator:OnUnRegist()
end


function SpActivityQuestPageMediator:InterestSignals()
    local signals = {
        SIGNALNAMES.Activity_Quest_Exchange_Callback,
	}
	return signals
end
function SpActivityQuestPageMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == SIGNALNAMES.Activity_Quest_Exchange_Callback then
        self:ActivityQuestExchangeSuccess(body)
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
function SpActivityQuestPageMediator:RefreshView()
    local viewComponent = self:GetViewComponent()
end
--[[
前往按钮回调
--]]
function SpActivityQuestPageMediator:EnterButtonCallback( sender )
    PlayAudioByClickNormal()
	local activityId = checkint(self.typeData_.activityId)
	local activityHomeDatas = self.typeData_
    local activityDatas = self.homeData_
    local leftSeconds = checkint(activityHomeDatas.closeTimestamp_) - os.time()
	-- 添加开始剧情
	local function enterView ()
	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'HomeMediator'}, {name = 'ActivityMapMediator', params = {activityId = activityId}})
	end
	if checkint(activityDatas.startStoryId) > 0 then
		app.activityMgr:ShowActivityStory({
			activityId = activityId,
			storyId = activityDatas.startStoryId,
			storyType = 'START',
			callback = enterView
		})
	else
		enterView()
	end
end
--[[
兑换按钮回调
--]]
function SpActivityQuestPageMediator:ExchangeButtonCallback( sender )
    PlayAudioByClickNormal()
	local activityId = checkint(self.typeData_.activityId)
	local activityHomeDatas = self.typeData_
    local activityDatas = self.homeData_
    local leftSeconds = checkint(activityHomeDatas.closeTimestamp_) - os.time()
	-- 构建兑换页面所需的数据结构 --
	local exchangeDatas = {homeDatas = {exchange = {}}}
	-- 获取道具兑换配表
	local exchangeConfig = CommonUtils.GetConfig('activityQuest', 'exchange', checkint(activityDatas.zoneId))
	for k,v in orderedPairs(exchangeConfig) do
		v.require = v.consume
		v.leftExchangeTimes = checkint(activityDatas.exchangeTimes[tostring(v.id)])
		table.insert(exchangeDatas.homeDatas.exchange, v)
	end
	local mediator = require( 'Game.mediator.ActivityPropExchangeMediator').new({data = {activityId = activityId,  activityHomeDatas = exchangeDatas, leftSeconds = leftSeconds, tag = 110123}})
	self:GetFacade():RegistMediator(mediator)
end
--[[
活动副本兑换成功
--]]
function SpActivityQuestPageMediator:ActivityQuestExchangeSuccess( datas )
    local activityDatas = self.homeData_
	activityDatas.exchangeTimes[tostring(datas.requestData.exchangeId)] = activityDatas.exchangeTimes[tostring(datas.requestData.exchangeId)] - checkint(datas.requestData.num)
end
-------------------------------------------------
-- public method
function SpActivityQuestPageMediator:resetHomeData(homeData)
    self.homeData_ = homeData
    self:RefreshView()
end


return SpActivityQuestPageMediator
