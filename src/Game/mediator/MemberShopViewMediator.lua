local Mediator = mvc.Mediator

local NAME = "MemberShopViewMediator"
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local MemberShopViewMediator = class("MemberShopViewMediator", Mediator)
local scheduler = require('cocos.framework.scheduler')
local MEMBERTYPE = 2   -- 月卡的充值类型  api_socket.md 2019. 充值成功
local MEMBER_DURATION = 30 * 24 * 60 * 60  -- 单月会员时间

local getVipData = nil
local splitVipDesc = nil
local getRichTextByStr = nil

function MemberShopViewMediator:ctor(params, viewComponent)
    self.super:ctor(NAME, viewComponent)
	self.vipData = {}
	self.vipDesc = {}

    if params then
		if params.data then
			self.shopData = params.data
		end
	end

	self.leftSeconds = self.shopData and self.shopData.leftSeconds or 0
	
	self:initData()
end

-------------------------------------------------
-- Interest Process Signals
function MemberShopViewMediator:InterestSignals( )
	local signals = {
		SIGNALNAMES.Restaurant_Shop_GetPayOrder_Callback,	-- 创建支付订单信号
		EVENT_PAY_MONEY_SUCCESS_UI,
	}
	return signals
end

function MemberShopViewMediator:ProcessSignal( signal )
    local name = signal:GetName()
	-- print(name)
	local body = signal:GetBody()
    -- dump(body)
	if name == SIGNALNAMES.Restaurant_Shop_GetPayOrder_Callback then
		-- body不存在  或  请求名称不相同
		if not body or body.requestData.name ~= 'MemberShopView' then return end

		if body.orderNo then
	        if device.platform == 'android' or device.platform == 'ios' then
			    local AppSDK = require('root.AppSDK')
				local amount = self.shopData.price
				local property = body.orderNo
			    AppSDK.GetInstance():InvokePay({amount = amount, property = property,goodsId = tostring(self.shopData.channelProductId),
                    goodsName = __('幻晶石'), quantifier = __('个'),price = 0.1, count = 1})
			end
		end
	elseif name == EVENT_PAY_MONEY_SUCCESS_UI then
		-- body不存在  或  会员id不相同
        if checkint(body.type) == PAY_TYPE.PT_MEMBER then
            local memberId = tostring(self.shopData.memberId)
            if not body or (body.member[memberId] == nil) then return end
            local memberData = body.member[memberId]
            self:updateMustRewardNodes()
            self:updateBottomState(memberData.leftSeconds)
        end
	end
end

-------------------------------------------------
-- init view
function MemberShopViewMediator:Initial( key )
	self.super:Initial(key)
	local tag = 5001
	local viewComponent  = require('Game.views.MemberShopView').new({tag = tag, mediatorName = "MemberShopViewMediator", vipData = self.vipData})
	viewComponent:setTag(tag)
	display.commonUIParams(viewComponent, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.5, display.height * 0.5)})
	self:SetViewComponent(viewComponent)

	local scene = uiMgr:GetCurrentScene()
	scene:AddDialog(viewComponent)

    self.viewData = viewComponent.viewData

    self:InitUi()

end

function MemberShopViewMediator:initData()
	if self.shopData then
		local memberId = checkint(self.shopData.memberId)
		self.vipData = getVipData(memberId)
		self.vipData.mustGoodState = gameMgr:GetUserInfo().member[tostring(memberId)] and -1 or 1
		local vipDescrStr = self.vipData.vipDescr
		self.vipDesc = splitVipDesc(vipDescrStr)
	end
end

function MemberShopViewMediator:InitUi( ... )
	local titleLabel = self.viewData.titleLabel
	display.fixLabelText(titleLabel, {text = self.vipData.vipName})

	-- local listView = self.viewData.listView
	-- self:updateList(listView)

	self:setVipDescLayer()

	local cancelBtn = self.viewData.cancelBtn
	cancelBtn:setOnClickScriptHandler(handler(self,self.CloseView))

	local buyBtn = self.viewData.buyBtn
	buyBtn:setOnClickScriptHandler(handler(self,self.BuyButtonCallback))

	self:updateBottomState()

end

function MemberShopViewMediator:setVipDescLayer()
	local descLayer = self.viewData.descLayer
	local descLayerSize = descLayer:getContentSize()

	local lbHeight = nil

	local textH = 0
	local tempStrTb = {}
	local vipDescCount = #self.vipDesc
	for i = 1, vipDescCount do
		local str =  string.gsub(table.concat(self.vipDesc[i]), "^%s*(.-)%s*$", "%1")
		table.insert(tempStrTb, str)
		if i~=vipDescCount then
			table.insert(tempStrTb, '\n\n')
		end
	end
	
	local label = display.newLabel(0, 0, {hAlign = display.TAL, ap = display.CENTER_TOP, fontSize = 22, color = '#5b3c25', w = 22 * 20 + 6, text = table.concat(tempStrTb)})
	local labelSize = display.getLabelContentSize(label)
	descLayerSize.height = labelSize.height + 22
	display.commonUIParams(label, {po = cc.p(descLayerSize.width / 2, labelSize.height + 22)})
	descLayer:addChild(label)
	descLayer:setContentSize(descLayerSize)
	
	local contentView = self.viewData.contentView
	local scrollView = self.viewData.scrollView

	local contentTopHeight = self.viewData.contentTopHeight
	local oldContentViewSize = contentView:getContentSize()
	local contentViewSize = cc.size(568 * 0.98, contentTopHeight + descLayerSize.height)

	if contentViewSize.height > oldContentViewSize.height then
		contentView:setContentSize(contentViewSize)
		contentView:setPosition(cc.p(contentView:getPositionX(),contentViewSize.height - oldContentViewSize.height))
		scrollView:setContainerSize(contentViewSize)
		scrollView:setContentOffset(cc.p(0,-(contentViewSize.height - oldContentViewSize.height)))
	end
end

-------------------------------------------------
-- ui state update
function MemberShopViewMediator:updateMustRewardNodes()
	local mustRewardNodes = self.viewData.mustRewardNodes
	for i,v in ipairs(mustRewardNodes) do
		local arrow = v.arrow
		v:setState(-1)
		arrow:setVisible(true)
	end
end


function MemberShopViewMediator:updateBottomState(leftSeconds)
	if leftSeconds then
		self.leftSeconds = leftSeconds
	end
	local isShowBtn = self.leftSeconds == 0

	local cancelBtn = self.viewData.cancelBtn
	local buyBtn = self.viewData.buyBtn
	local downCountLayer = self.viewData.downCountLayer
	
	local bgSize = self.viewData.bgSize

	downCountLayer:setVisible(not isShowBtn)

	local buyBtnText = isShowBtn and __('购买') or __('续费')
	local btnPosY = isShowBtn and 60 or 80
	
	display.commonUIParams(cancelBtn, {po = cc.p(cancelBtn:getPositionX(), btnPosY)})
	display.commonUIParams(buyBtn,    {po = cc.p(buyBtn:getPositionX(), btnPosY)})
	display.commonLabelParams(buyBtn, {text = buyBtnText})

	if not isShowBtn then
		self:updateCountDown_(self.leftSeconds)
		if self.leftSeconds <= 3 * 24 * 60 * 60 then
			self:startCountDown_()
		end
	else
		self:stopCountDown_()
	end
end


-------------------------------------------------
-- countDown
function MemberShopViewMediator:startCountDown_()
	local startTime = os.time()
	self.countDownHandler = scheduler.scheduleGlobal(function ()
		local deltaTime = math.floor(os.time() - startTime)
		local time = self.leftSeconds - deltaTime
		-- print(time)
		self:updateCountDown_(time)
		if time <= 0 then
			self.leftSeconds = 0
			self:updateBottomState()
		end
    end,1)

end

function MemberShopViewMediator:stopCountDown_()
	if self.countDownHandler then
		scheduler.unscheduleGlobal(self.countDownHandler)
		self.countDownHandler = nil
	end
end

function MemberShopViewMediator:updateCountDown_(time)
	
	local leftTimeLabel = self.viewData.leftTimeLabel
	local countDownLabel = self.viewData.countDownLabel
	local downCountBgSize = self.viewData.downCountBgSize

	countDownLabel:setString(CommonUtils.getTimeFormatByType(time, 1))
	
	local leftTimeLabelSize = display.getLabelContentSize(leftTimeLabel)
	local countDownLabelSize = display.getLabelContentSize(countDownLabel)

	leftTimeLabel:setPosition(405 - countDownLabelSize.width/2, downCountBgSize.height / 2)
    countDownLabel:setPosition(405 + leftTimeLabelSize.width/2, downCountBgSize.height / 2)
end

-------------------------------------------------
-- buy callback
function MemberShopViewMediator:BuyButtonCallback()
	local data = self.shopData
	self:SendSignal(COMMANDS.COMMANDS_All_Shop_GetPayOrder, {productId = data.productId, name = 'MemberShopView'})
end

-------------------------------------------------
-- Regist UnRegist
function MemberShopViewMediator:CloseView()
	self:GetFacade():UnRegsitMediator("MemberShopViewMediator")
end

-------------------------------------------------
--==============================--
-- desc: warn
-- 月卡 属于 幻晶石商城(DiamondShopViewMediator) 的子界面 所以不用注册 COMMANDS.COMMANDS_All_Shop_GetPayOrder
-- 如果 幻晶石商城(DiamondShopViewMediator) 未注册 请 在此界面添加注册
--==============================---------------
function MemberShopViewMediator:OnRegist(  )
end

function MemberShopViewMediator:OnUnRegist(  )
	-- self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
	self:stopCountDown_()
    local scene = uiMgr:GetCurrentScene()
	scene:RemoveDialogByTag(5001)
end

getVipData = function (index)
    local vipConfig = CommonUtils.GetConfigAllMess('vip','player')
	local vipData = {}
    for i,v in pairs(vipConfig) do
        if v.vipLevel == index then
            return v
        end
    end
    return vipData
end

splitVipDesc = function (vipDescrStr)
	local t = string.split(vipDescrStr, '||')
	local vipDesc = {}
	for i,v in ipairs(t) do
		local t1 = string.split(v, '#')
		-- dump(t1)
		table.insert(vipDesc, t1)
	end
	return vipDesc
end

getRichTextByStr = function (strs)
	local t = {}
	for i,v in ipairs(strs) do
		if i == 2 then
			table.insert( t, {text = v, fontSize = 24, color = '#ffac4a'})
		else
			table.insert( t, {text = v, fontSize = 22, color = '#5b3c25'})
		end
	end
	return t
end

return MemberShopViewMediator
