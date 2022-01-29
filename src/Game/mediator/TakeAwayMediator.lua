local Mediator = mvc.Mediator

local TakeAwayMediator = class("TakeAwayMediator", Mediator)
local NAME = "TakeAwayMediator"
local shareFacade = AppFacade.GetInstance()

local timerMgr = AppFacade.GetInstance():GetManager("TimerManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
---@type DataManager
local dataMgr = AppFacade.GetInstance():GetManager("DataManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local takeawayInstance = AppFacade.GetInstance():GetManager('TakeawayManager')
local RED_TAG = 1115
--[[
--创建外卖车的页面	
--]]
local function CreateCarView(num)
	local bgImage = display.newImageView(_res('ui/home/takeaway/workshop_bg.png'))
	local bgSize = bgImage:getContentSize()
	bgImage:setPosition(cc.p(bgSize.width/2,bgSize.height/2))
	local bgLayer = CLayout:create(bgSize)
	bgLayer:setAnchorPoint(display.LEFT_BOTTOM)
	bgLayer:addChild(bgImage)
	bgLayer:setPosition(cc.p(700,0))
	-- bgLayer:setOpacity(0)
	local cellLayout = CLayout:create(bgSize)
	cellLayout:setPosition(cc.p(0,0))
	cellLayout:setAnchorPoint(display.LEFT_BOTTOM)
	cellLayout:addChild(bgLayer)
    local size = cc.size(350,175)
    -- local view = CLayout:create(size)
	local  view = display.newLayer(0,0,{ap = display.CENTER ,size =size , color = cc.c4b(0,0,0,0) })
    local actionView = CColorView:create(cc.c4b(0,200,100,0))
    actionView:setTouchEnabled(true)
    display.commonUIParams(actionView, { po = cc.p(136,80)})
    actionView:setContentSize(cc.size(274,120))
    view:addChild(actionView)
	local unLockBtn = display.newButton(bgSize.width -100 , bgSize.height /2 ,{ 
		n = _res('ui/common/common_btn_orange.png'),
		s = _res('ui/common/common_btn_orange.png'),
		d = _res('ui/common/common_btn_orange_disable.png')
	})
	display.commonLabelParams(unLockBtn,fontWithColor('14',{text =__('点击解锁')}))
	bgLayer:addChild(unLockBtn)
    --创建车
    local spnPath = _spn(HOME_THEME_STYLE_DEFINE.LONGXIA_SPINE or 'ui/home/takeaway/longxiache')
	local qAvatar = sp.SkeletonAnimation:create(spnPath.json, spnPath.atlas, 1.0)
    qAvatar:setPosition(cc.p(136,30))
    view:addChild(qAvatar,5)
    qAvatar:setToSetupPose()
    qAvatar:setAnimation(0, 'idle', true)
    qAvatar:setTimeScale(0)
    qAvatar:setColor(cc.c3b(100,100,100))

	local levelButton = display.newButton(0, bgSize.height, {
            n = _res('ui/home/takeaway/workshop_bg_level_up.png'),
			s = _res('ui/home/takeaway/workshop_bg_level_up.png') ,
			enable = false ,ap = display.LEFT_TOP
        })	
	levelButton:setEnabled(false)
	display.commonLabelParams(levelButton, {fontSize = 20, color = 'ffffff', text = '',offset = cc.p(-10, 20)})
	bgLayer:addChild(levelButton,1)

	local upgradeButton = display.newButton(bgSize.width -100, bgSize.height/2, {
        n =_res('ui/common/common_btn_orange.png'),enable = true
    })
	local porpertyButton = display.newButton(bgSize.width -100, bgSize.height/2, {
        n =_res('ui/common/common_btn_orange.png'),enable = true
    })
	
	bgLayer:addChild(porpertyButton,4)
	porpertyButton:setVisible(false)
	local upgradeButtonSize = upgradeButton:getContentSize()
    display.commonLabelParams(upgradeButton, fontWithColor('14', { text = __('升级'),offset = cc.p(-upgradeButtonSize.width/4+10, 0), font = TTF_GAME_FONT, ttf = true}))
	local upgradeImage = display.newImageView(_res("ui/home/takeaway/workshop_ico_level_up.png"),upgradeButtonSize.width/4*3 +15 ,upgradeButtonSize.height/2+15)
	upgradeButton:addChild(upgradeImage)
	display.commonLabelParams(porpertyButton, fontWithColor('14', { text = __('查看属性'), font = TTF_GAME_FONT, ttf = true}))
	-- upgradeImage:setScale(0.8)
    bgLayer:addChild(upgradeButton,4)
    upgradeButton:getLabel():enableOutline(cc.c4b(0, 0, 0, 255), 1)
    upgradeButton:setVisible(false)

    --宝箱
    local rewardBox = sp.SkeletonAnimation:create("ui/home/takeaway/baoxiang.json","ui/home/takeaway/baoxiang.atlas", 1.0)
    rewardBox:setPosition(cc.p(290,50))
    rewardBox:setAnchorPoint(cc.p(0,0))
    view:addChild(rewardBox, 2)
    rewardBox:setToSetupPose()
    rewardBox:setAnimation(0, 'baoxiang1', true)
    rewardBox:setTimeScale(0)
    --盘子
    local rewardBoxBg = sp.SkeletonAnimation:create("ui/home/takeaway/panche.json","ui/home/takeaway/panche.atlas", 1.0)
    rewardBoxBg:setPosition(cc.p(290,30))
    rewardBoxBg:setAnchorPoint(cc.p(0,0.5))
    view:addChild(rewardBoxBg,1)
    rewardBoxBg:setToSetupPose()
    rewardBoxBg:setAnimation(0, 'idle', true)
    rewardBoxBg:setTimeScale(0)
    local lighting = sp.SkeletonAnimation:create("ui/home/takeaway/shanguang.json","ui/home/takeaway/shanguang.atlas", 1.0)
    lighting:setPosition(cc.p(290,40))
    view:addChild(lighting,5)
    lighting:setToSetupPose()
    lighting:setAnimation(0, 'idle', true)
    lighting:setVisible(false)
	local levelUpBtn = display.newImageView(_res('ui/common/common_ico_lock.png'),136, size.height * 0.5)
    view:addChild(levelUpBtn,5)
    -- levelUpBtn:enableOutline(cc.c4b(0, 0, 0, 255), 1)
    local timeBg = display.newImageView(_res('ui/home/takeaway/workshop_bg_time.png'),size.width/2, size.height -20)
    local timerLabel = display.newRichLabel(60,48, {
        text = '', fontSize = 20, color = '#5c5c5c', ttf = true, font = TTF_GAME_FONT
    })
    timerLabel:setPosition(utils.getLocalCenter(timeBg))
    timeBg:addChild(timerLabel)
	timeBg:setVisible(false)
	view:addChild(timeBg)
	view:setVisible(true)
	view:setPosition(cc.p(size.width/2 , size.height/2))
	bgLayer:addChild(view)
    return {
        view            = bgLayer,
		cview          = view ,
        actionView      = actionView,
        cardNode        = qAvatar,
		upgradeButton = upgradeButton, --升级按钮
		porpertyButton = porpertyButton ,
		upgradeImage = upgradeImage ,
        rewardBoxBg     = rewardBoxBg,
        rewardBox       = rewardBox,
        lighting        = lighting,
        unLockImage     = levelUpBtn,
		unLockBtn 		= unLockBtn ,
        timeBg          = timeBg,
        timerLabel      = timerLabel,
		levelButton     = levelButton, --级别标题
		cellLayout = cellLayout ,
    }
end
--[[
--创建主页面
--]]

local moveToLeft =function (view ,num)
	local delayTime = cc.DelayTime:create(num*0.06)
	local spawnAction = cc.Spawn:create(cc.FadeIn:create(0.15) ,cc.MoveTo:create(0.15,cc.p(0,0)))
	local seqAction = cc.Sequence:create(delayTime,cc.EaseSineIn:create(spawnAction))
	view:runAction(seqAction)
end
local function CreateView(cb)
	local view = require("common.TitlePanelBg").new({ title = __('车库'), type = 2, cb = cb, offsetY = 4})
	view.viewData.eaterLayer:setLocalZOrder(1)
	local listViewSize = cc.size(700 ,560)
	local listView = CListView:create(listViewSize)
	listView:setDirection(eScrollViewDirectionVertical)
	listView:setAnchorPoint(cc.p(0.5, 0))
	local bviewSize = view.viewData.bview:getContentSize()
	view.viewData.bview:addChild(listView,2)
	listView:setPosition(cc.p((bviewSize.width -55)/2 , 30))
    local cardViewData = CreateCarView(1)
	listView:insertNodeAtLast(cardViewData.cellLayout)
	moveToLeft(cardViewData.view ,1)
    local cardViewData2 = CreateCarView(2)
	listView:insertNodeAtLast(cardViewData2.cellLayout)
	moveToLeft(cardViewData2.view ,2)
    local cardViewData3 = CreateCarView(3)
	listView:insertNodeAtLast(cardViewData3.cellLayout)
	moveToLeft(cardViewData3.view ,3)
	listView:reloadData()
    return {
        view          = view,
		cardViewDatas = {cardViewData, cardViewData2,cardViewData3},
    }
end
--[[
--创建外卖车的升级与解锁页面	
--levelId 等级id
--]]
local function CreateUnlockUpgradeView(type, cb)
    -- type 1 是解锁 2为升级
    local text =__("解锁外卖车")
    if type == 2 then
        text = __('升级外卖车')
    end
	local view = require("common.TitlePanelBg").new({ title = text, type = 3, cb = cb, offsetY = 4})
	display.commonUIParams(view, {ap = display.CENTER, po = cc.p(display.cx, display.cy)})
    local size = cc.size(540,594)
    local cview = CLayout:create(size)
    -- cview:setBackgroundColor(cc.c4b(100,100,200,100))
    view:AddContentView(cview)
    if type == 1 then
		--解锁车
		local topBg = display.newImageView(_res('ui/home/takeaway/takeup_bg_delivery.png'),10, size.height)
        display.commonUIParams(topBg, {ap = display.LEFT_TOP})
        cview:addChild(topBg)
		local btnSpine = sp.SkeletonAnimation:create('effects/shenti/skeleton.json', 'effects/shenti/skeleton.atlas', 0.5)
		btnSpine:update(0) 
		btnSpine:setAnimation(0, 'animation', false)
		topBg:addChild(btnSpine,10)
		btnSpine:setPosition(utils.getLocalCenter(topBg))
		btnSpine:setVisible(false)

        local spnPath = _spn(HOME_THEME_STYLE_DEFINE.LONGXIA_SPINE or 'ui/home/takeaway/longxiache')
		local qAvatar = sp.SkeletonAnimation:create(spnPath.json, spnPath.atlas, 1.0)
        qAvatar:setPosition(cc.p(size.width * 0.5,350))
        cview:addChild(qAvatar,5)
        qAvatar:setToSetupPose()
        qAvatar:setAnimation(0, 'idle', true)
		--添加需要的材料
        local upgradeTitleLabel = display.newButton(286,246, {
            n = _res('ui/home/takeaway/common_title_3.png'),animate = false,
        })
        upgradeTitleLabel:setEnabled(false)
        display.commonLabelParams(upgradeTitleLabel, {fontSize = 22, color = '4c4c4c', text = __('解锁条件')})
        cview:addChild(upgradeTitleLabel)
        --奖励列表格子
        local rewardView = CLayout:create(cc.size(500,132))
        -- rewardView:setBackgroundColor(cc.c4b(100,100,100,100))
        display.commonUIParams(rewardView, {po = cc.p(278,158)})
        cview:addChild(rewardView)
        --升级按钮
        local upgradeButton = display.newButton(286,54, {
            n = _res('ui/common/common_btn_orange.png'),
        })
        display.commonLabelParams(upgradeButton, fontWithColor(14,{text = __('解锁')}))
        cview:addChild(upgradeButton,2)
		return {
			view = view,
			topBg = topBg,
			btnSpine = btnSpine,
			rewardView = rewardView,
            upgradeButton = upgradeButton,
		}
    elseif type == 2 then
        --升级
        local topBg = display.newImageView(_res('ui/home/takeaway/takeup_bg_delivery.png'),10, size.height)
        display.commonUIParams(topBg, {ap = display.LEFT_TOP})
        cview:addChild(topBg)
		local btnSpine = sp.SkeletonAnimation:create('effects/shenti/skeleton.json', 'effects/shenti/skeleton.atlas', 0.5)
		btnSpine:update(0) 
		topBg:addChild(btnSpine,10)
		btnSpine:setPosition(utils.getLocalCenter(topBg))
		btnSpine:setVisible(false)

        local spnPath = _spn(HOME_THEME_STYLE_DEFINE.LONGXIA_SPINE or 'ui/home/takeaway/longxiache')
		local qAvatar = sp.SkeletonAnimation:create(spnPath.json, spnPath.atlas, 1.0)
        qAvatar:setPosition(cc.p(188,350))
        cview:addChild(qAvatar,5)
        qAvatar:setToSetupPose()
        qAvatar:setAnimation(0, 'idle', true)
        -- qAvatar:setTimeScale(0)
        local levelButton = display.newButton(188, 330, {
            n = _res('ui/home/takeaway/maps_fight_bg_title_s.png'),
        })
        levelButton:setEnabled(false)
        display.commonLabelParams(levelButton, {fontSize = 24, ttf = true,font = TTF_GAME_FONT ,  color = 'ffffff', text = ''})
        cview:addChild(levelButton,1)
        local upgradeBg = display.newImageView(_res('ui/home/takeaway/takeout_bg_level_up_attribute.png'),size.width - 32, size.height - 34)
        display.commonUIParams(upgradeBg, {ap = display.RIGHT_TOP})
        cview:addChild(upgradeBg, 2)
        --添加当前升级参数
        local lsize = upgradeBg:getContentSize()
        local aTitleLabel = display.newButton(lsize.width * 0.5,lsize.height - 22, {
            n = _res('ui/home/takeaway/common_title_3.png'),animate = false,
        })
        aTitleLabel:setEnabled(false)
        display.commonLabelParams(aTitleLabel, {fontSize = 22, color = '4c4c4c', text = __('外卖车效果')})
        upgradeBg:addChild(aTitleLabel)

        local energyLabel = display.newRichLabel(20,170,
            {ap = cc.p(0, 1.0), c = {
                {text = __('速度:'), fontSize = 20, color = '5c5c5c'},
                {text = tostring(0), fontSize = 22, color = '4c4c4c'},
                {text = string.format(" +%d", 0), fontSize = 22, color = 'ff6886'},
            }
        })
		local nextEnergyLabel = display.newRichLabel(20,140,
		{ap = cc.p(0, 1.0), c = {
			{text = __('速度:'), fontSize = 20, color = '5c5c5c'},
			{text = tostring(0), fontSize = 22, color = '4c4c4c'},
			{text = string.format(" +%d", 0), fontSize = 22, color = 'ff6886'},
		}
		})
        -- energyLabel:reloadData()
        upgradeBg:addChild(energyLabel)
		upgradeBg:addChild(nextEnergyLabel)
        local expLabel =  display.newLabel(size.width/2, 20 , fontWithColor(5,{ap = cc.p(0.5,0.5),text =  ""}))
        cview:addChild(expLabel,12)

        --添加需要的材料
        local upgradeTitleLabel = display.newButton(286,246, {
            n = _res('ui/home/takeaway/common_title_3.png'),animate = false,
        })
        upgradeTitleLabel:setEnabled(false)
        display.commonLabelParams(upgradeTitleLabel, {fontSize = 22, color = '4c4c4c', text = __('升级材料')})
        cview:addChild(upgradeTitleLabel)
        --奖励列表格子
        local rewardView = CLayout:create(cc.size(500,132))
        -- rewardView:setBackgroundColor(cc.c4b(100,100,100,100))
        display.commonUIParams(rewardView, {po = cc.p(278,158)})
        cview:addChild(rewardView)
        --升级按钮
        local upgradeButton = display.newButton(286,60, {
            n = _res('ui/common/common_btn_orange.png'),
        })
        display.commonLabelParams(upgradeButton, fontWithColor(14,{text = __('升级')}))
        cview:addChild(upgradeButton,2)
       
        return {
            view = view,
			topBg = topBg,
			btnSpine = btnSpine,
            upgradeBg = upgradeBg,
            upgradeTitleLabel = upgradeTitleLabel,
            rewardView = rewardView,
            upgradeButton = upgradeButton,
            energyLabel = energyLabel, --速度
			nextEnergyLabel = nextEnergyLabel ,
            expLabel = expLabel, --主角经验
            aTitleLabel = aTitleLabel, --加城标题
			levelButton = levelButton,
        }
    end
    return {
        view = view,
    }
end
---- 升级外买车可加速外卖配送时间
---- 本级加速
---- 下级加速

function TakeAwayMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
	self.collectTakeWayBtns = {}
end

function TakeAwayMediator:InterestSignals()
	local signals = {
		SIGNALNAMES.SIGNALNAMES_TAKEAWAY_HOME,
		SIGNALNAMES.SIGNALNAMES_TAKEAWAY_UPGRADE_CAR,
		SIGNALNAMES.SIGNALNAMES_TAKEAWAY_UNLOCK_CAR,
        FRESH_TAKEAWAY_POINTS,
	}

	return signals
end


function TakeAwayMediator:ProcessSignal(signal )
	local name = signal:GetName()
	if name == SIGNALNAMES.SIGNALNAMES_TAKEAWAY_HOME then
		--外卖首页的逻辑显示
		self.datas = signal:GetBody()
		-- AppFacade.GetInstance():RetrieveMediator('BusinessMediator'):UpdateHeroUi(checkint(self.datas.assistantId))
		table.merge(takeawayInstance.orderDatas, signal:GetBody())
		--更新车的相关数据
		self:RefreshCards(true)
    elseif name == FRESH_TAKEAWAY_POINTS then
        --更新数据的逻辑,可能弹出界面进行领取的逻辑
        local instance = AppFacade.GetInstance():GetManager('TakeawayManager')
        local datas = instance:GetDatas()
		self.datas = datas
        self:RefreshCards() --刷新一下外卖车的显示状态

    elseif name == SIGNALNAMES.SIGNALNAMES_TAKEAWAY_UPGRADE_CAR then
        --升级外卖车
		-- gameMgr:GetUserInfo().mainExp = checkint(signal:GetBody().mainExp) --主角经验
		local delayFuncList = nil
		--更新缓存数据,扣除需要的材料与道具
		local diningCarId = checkint(signal:GetBody().requestData.diningCarId)
		local level = 2
		for k,v in pairs(checktable(self.datas).diningCar or {}) do
			if checkint(v.diningCarId) == diningCarId then
				local _ ,consumeTable =  self:juageConsumeEnough(v.level)
				CommonUtils.DrawRewards(consumeTable)
				v.level = checkint(v.level) + 1
				self:FreshUpgradeAttributes(v.level)
				level = v.level 
				break
			end
		end
		table.merge(takeawayInstance.orderDatas, self.datas)
		if signal:GetBody().mainExp  then
			local exp = checkint(signal:GetBody().mainExp) - gameMgr:GetUserInfo().mainExp
			delayFuncList = CommonUtils.DrawRewards({{goodsId = EXP_ID, num = exp}},true )
		end
		self.upgradeViewData.btnSpine:setVisible(true)
		self.upgradeViewData.btnSpine:setToSetupPose()
		self.upgradeViewData.btnSpine:setAnimation(0, 'animation', false)
		self:RefreshCards(false)--刷新界面
		local RewardResearchAndMakeView = require("Game.views.RewardResearchAndMakeView")
		local layer = RewardResearchAndMakeView.new({type = 4})
		layer:updateData({level = level },delayFuncList)
		layer:setPosition(display.center)
		uiMgr:GetCurrentScene():AddDialog(layer)

	elseif name == SIGNALNAMES.SIGNALNAMES_TAKEAWAY_UNLOCK_CAR then
		if not self.datas.diningCar then
			self.datas.diningCar = {}
		end
		local diningCarId = checkint(signal:GetBody().requestData.diningCarId)
		table.insert( self.datas.diningCar, {diningCarId = diningCarId,
			level = 1,status = 1
		})
		table.merge(takeawayInstance.orderDatas, self.datas)
		self:ReduceGoodsCache(diningCarId) --更新数量
		self.lockViewData.btnSpine:setVisible(true)
		self.lockViewData.btnSpine:setToSetupPose()
		self.lockViewData.btnSpine:setAnimation(0, 'animation', false)
		self:RefreshCards(false) --刷新界面
		self.lockViewData.view:runAction(cc.Sequence:create(cc.DelayTime:create(0.5) ,cc.RemoveSelf:create()))
		self.lockViewData = nil
	elseif name == "REFRESH_NOT_CLOSE_GOODS_EVENT" then
		self:RefreshGoodsNode()
		self:CheckAndAddCardUnLocakAndUpgradeRed()
	end
end


function TakeAwayMediator:Initial( key )
	self.super.Initial(self,key)
	self.collectTable = {}

	local scene = uiMgr:GetCurrentScene()
	self.viewData = CreateView(function()
		self:GetFacade():UnRegsitMediator('TakeAwayMediator')	
    end)
	local 	cardViewDatas  = self.viewData.cardViewDatas
	self.collectTakeWayBtns ={}
	for i =1 , #self.viewData.cardViewDatas do
		self.collectTakeWayBtns[i]  = {}
		self.collectTakeWayBtns[i].unLockBtn = self.viewData.cardViewDatas[i].unLockBtn
		self.collectTakeWayBtns[i].upgradeBtn = self.viewData.cardViewDatas[i].upgradeButton
	end
    display.commonUIParams(self.viewData.view, {po = display.center})
	scene:AddDialog(self.viewData.view)
	self:SetViewComponent(self.viewData.view)
	self:CheckAndAddCardUnLocakAndUpgradeRed()
	shareFacade:RegistObserver(COUNT_DOWN_ACTION_UI, mvc.Observer.new(function(item, signal)
		xTry(function()
			local body = signal:GetBody()
			local orderType = checkint(body.orderType)
			local orderInfo = body.datas
			if orderInfo then
				local targetCarViewData = nil 
				for diningCarId,carViewData in pairs(self.viewData.cardViewDatas) do
					if diningCarId == checkint(orderInfo.diningCarId) then
						targetCarViewData = carViewData
						break
					end
				end
				if targetCarViewData then
					--刷新状态
					local countdown = checkint(body.countdown)
					if countdown == 0 then
						--可领取奖励了的逻辑
						orderInfo.status = 4
						local viewSize  = targetCarViewData.view:getContentSize()
						targetCarViewData.cview:setPosition(cc.p(viewSize.width/2 , viewSize.height/2))
						targetCarViewData.cview:setAnchorPoint(display.CENTER)
						targetCarViewData.rewardBox:setTimeScale(1.0)
						targetCarViewData.rewardBoxBg:setTimeScale(1.0)
						targetCarViewData.cardNode:setTimeScale(1.0)
						targetCarViewData.upgradeButton:setVisible(false)
						targetCarViewData.timeBg:setVisible(false)
						targetCarViewData.rewardBoxBg:setAnimation(0, 'idle', true)
						targetCarViewData.lighting:setVisible(true)
						targetCarViewData.lighting:setTimeScale(1.0)
						targetCarViewData.unLockBtn:setVisible(true)
						targetCarViewData.rewardBox:setAnimation(0, 'baoxiang2', true)
					else
						targetCarViewData.timeBg:setVisible(true)
						display.reloadRichLabel(targetCarViewData.timerLabel , { c =  { 
							fontWithColor('16', { text = __('配送中')}),fontWithColor('10', 
							{ text =  string.formattedTime(countdown,'%02i:%02i:%02i')})
						}})
						-- targetCarViewData.timerLabel:setString( string.formattedTime(countdown,'%02i:%02i:%02i'))
					end
				end
			end
		end, __G__TRACKBACK__)
	end,self))
end


--[[
	--修正缓存
]]
function TakeAwayMediator:ReduceGoodsCache(diningCarId)
	local carConfig = CommonUtils.GetConfigAllMess('diningCar','takeaway')
	local carId = checkint(diningCarId)
	if carConfig[tostring(carId)] then
		local types = carConfig[tostring(carId)].unlockType
		--更新升级所需的相关属性变化
		for k,v in pairs(types) do
			if checkint(k) ~= UnlockTypes.AS_LEVEL and checkint(k) ~= UnlockTypes.PLAYER then
				if checkint(k) == UnlockTypes.GOLD then
					CommonUtils.DrawRewards({{goodsId = GOLD_ID, num  = - checkint(v.targetNum)}})
				elseif checkint(k) == UnlockTypes.DIAMOND then
					CommonUtils.DrawRewards({{goodsId = DIAMOND_ID, num  = - checkint(v.targetNum)}})
				elseif checkint(k) == UnlockTypes.GOODS then
					CommonUtils.DrawRewards({{goodsId = checkint(v.targetId), num  = - checkint(v.targetNum)}})
				end
			end
		end
	end
end

--[[
	判断升级材料是否充足，返回需要消耗的升级材料
]]
function TakeAwayMediator:juageConsumeEnough(level ,isJump )
	local consumeTable ={}
	local isEnough = true
	local data = CommonUtils.GetConfigAllMess('diningCarLevelUp', 'takeaway')
	local maxLevel = table.nums(data)
	local nextLevel = checkint(level)+1
	if nextLevel <=  maxLevel then
		local consumedata = clone(data[tostring(nextLevel)]["consumeGoods"]) 
		for	 k, val  in  pairs(consumedata) do
			table.insert(consumeTable,#consumeTable+1,val)
			local count = CommonUtils.GetCacheProductNum(val.goodsId) 
			if checkint(val.num)  > count  then
				isEnough = false 
			end
			consumeTable[#consumeTable].num = 0  - consumeTable[#consumeTable].num 
		end
	end
	return isEnough ,consumeTable
end
function TakeAwayMediator:FreshUpgradeAttributes(level)
	self.collectTable  = {}
	local data = CommonUtils.GetConfigAllMess('diningCarLevelUp', 'takeaway')
    local maxLevel = table.nums(data)
	if self.upgradeViewData then
	 	local nextLevel = level + 1 --下一级的逻辑功能
		display.commonLabelParams(self.upgradeViewData.levelButton, {ttf = true,font = TTF_GAME_FONT, fontSize = 22, color = 'ffffff', text = string.fmt(__('__num__级'), {__num__ =level})})
        local curLevelData = data[tostring(level)]
        if nextLevel > maxLevel then
            --已达满级
            self.upgradeViewData.expLabel:setVisible(false)
            self.upgradeViewData.rewardView:setVisible(false)
            self.upgradeViewData.upgradeButton:setVisible(false)
            display.commonLabelParams(self.upgradeViewData.upgradeTitleLabel, {fontSize = 22, color = '4c4c4c', text = __('已达满级')})
            display.commonLabelParams(self.upgradeViewData.aTitleLabel, {fontSize = 22, color = '4c4c4c', text = __('满级属性')})
            local curLevelData = data[tostring(maxLevel)]
            if curLevelData then
                display.reloadRichLabel(self.upgradeViewData.energyLabel, {c = {
                    {text = __('配送减少:'), fontSize = 20, color = '5c5c5c'},
                    {text = string.format(__('%s秒') ,tostring(curLevelData.speed)  *2), fontSize = 20, color = '4c4c4c'},
                }})
				self.upgradeViewData.nextEnergyLabel:setVisible(false)
            end
			--- 本级配送时间
        else
           local nextLevelData = data[tostring(nextLevel)]
		   self.upgradeViewData.expLabel:setString(__('经验 + ') ..  nextLevelData.mainExp)
            display.reloadRichLabel(self.upgradeViewData.energyLabel, {c = {
                {text = __('配送减少:'), fontSize = 20, color = '5c5c5c'},
                {text = string.format(__("%d秒"), checkint(curLevelData.speed)*2) , fontSize = 20, color = '4c4c4c'},

            }})
			display.reloadRichLabel(self.upgradeViewData.nextEnergyLabel, {c = {
				{text = __('下级配送减少:'), fontSize = 20, color = '5c5c5c'},
				{text = string.format(__("%d秒"), checkint(nextLevelData.speed)*2) , fontSize = 20, color = 'ff6886'}
			}})
            --添加升级所需的材料
            self.upgradeViewData.rewardView:removeAllChildren()
            --然后添加材料格子
            local len = table.nums(nextLevelData.consumeGoods) 
            local centerPos = math.floor((len + 1) / 2)
            local cx,cy = self.upgradeViewData.rewardView:getContentSize().width * 0.5,  self.upgradeViewData.rewardView:getContentSize().height * 0.5
            for i,v in ipairs(nextLevelData.consumeGoods) do
                local function callBack(sender)
                    AppFacade.GetInstance():GetManager("UIManager"):ShowInformationTipsBoard({targetNode = sender, iconId = v.goodsId, type = 1})
                end
                if len % 2 == 0 then
                    --偶数
                    local x, y = (cx - (centerPos - i  + 0.5) * 140),cy
                    local goodsNode = require('common.GoodNode').new({id = v.goodsId, amount = v.num, showAmount = false,callBack = callBack})
					display.commonUIParams(goodsNode, {animate = false, cb = function (sender)
						uiMgr:AddDialog("common.GainPopup", {goodId =v.goodsId})
						-- uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = data.goodsId, type = 1})
					end})
                    goodsNode:setPosition(cc.p(x,y))
                    goodsNode:setScale(0.75)
                    self.upgradeViewData.rewardView:addChild(goodsNode, 5)
					local fontNum = 8
					if CommonUtils.GetCacheProductNum(v.goodsId)  < checkint(v.num )  then 
						fontNum = 10 
					end 

					local numLabel = display.newRichLabel(50, -16,{ r = true  , c = { 
						fontWithColor(fontNum , { fontSize = 24 , text =  CommonUtils.GetCacheProductNum(v.goodsId) }) ,
						fontWithColor('8' , {fontSize = 24 , text = '/' .. tostring(v.num) }) 
					}})
					numLabel:setName("numLabel")
					numLabel.str =   CommonUtils.GetCacheProductNum(v.goodsId) .. '/' .. tostring(v.num)
                    goodsNode:addChild(numLabel, 10)
					table.insert(self.collectTable,#self.collectTable+1 , goodsNode)
                else
                    -- 奇数
                    local x, y = (cx - (centerPos - i ) * 140),cy
                    local goodsNode = require('common.GoodNode').new({id = v.goodsId, amount = v.num, showAmount = false,callBack = callBack})
                    goodsNode:setPosition(cc.p(x,y))
                    goodsNode:setScale(0.75)
					display.commonUIParams(goodsNode, {animate = false, cb = function (sender)
						uiMgr:AddDialog("common.GainPopup", {goodId =v.goodsId})
						-- uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = data.goodsId, type = 1})
					end})
                    self.upgradeViewData.rewardView:addChild(goodsNode, 5)
                    -- local numLabel = display.newLabel(50, -16, {
                    --     fontSize = 24, text = string.format( "%d/%d", CommonUtils.GetCacheProductNum(v.goodsId), checkint(v.num)),color = '5c5c5c',ttf = true, font = TTF_GAME_FONT
                    -- })
					local fontNum = 8
					if CommonUtils.GetCacheProductNum(v.goodsId)  < checkint(v.num )  then 
						fontNum = 10 
					end 

					local numLabel = display.newRichLabel(50, -16,{ r = true  , c = { 
						fontWithColor(fontNum , { fontSize = 24 , text =  CommonUtils.GetCacheProductNum(v.goodsId) }) ,
						fontWithColor('8' , {fontSize = 24 ,text = '/' .. tostring(v.num) }) 
					}})
					numLabel.str =   CommonUtils.GetCacheProductNum(v.goodsId) .. '/' .. tostring(v.num)
					numLabel:setName("numLabel")
					goodsNode:addChild(numLabel, 10)
					table.insert(self.collectTable,#self.collectTable+1 , goodsNode)
                end
            end
        end
	end
end
--[[
	--升级按钮的显示逻辑窗口
]]
--==============================--
--desc:
--time:2017-06-20 05:56:03
--@carInfo:
--@return fskdff
--==============================--sdf
function TakeAwayMediator:ShowUpgradeUI(carInfo)
    PlayAudioClip(AUDIOS.UI.ui_moto.id)
	local viewData = CreateUnlockUpgradeView(2, function()
        PlayAudioByClickNormal()
		if self.upgradeViewData and ( not tolua.isnull(self.upgradeViewData.view )) then
			self.upgradeViewData.view:runAction(cc.RemoveSelf:create())
			self.upgradeViewData = nil
		end
    end)
	self.upgradeViewData = viewData
	local scene = uiMgr:GetCurrentScene()
	display.commonUIParams(viewData.view, {po = display.center})
	scene:AddDialog(viewData.view,20)
	local level = checkint(carInfo.level)
    --更新数据的逻辑
    self:FreshUpgradeAttributes(level)
	viewData.upgradeButton:setUserTag(checkint(carInfo.diningCarId))
    viewData.upgradeButton:setOnClickScriptHandler(function(sender)
        --升级的逻辑
        --更新玩家属性 刷新页面
		
		local id = sender:getUserTag()
		local level = nil 
		for k, v in pairs(self.datas.diningCar) do
			if checkint(v.diningCarId)  ==  id then 
				level = v.level 	
			end
		end
		if  not  level then
			uiMgr:ShowInformationTips(__('该外卖车不存在~'))
		end 
		local isEnough ,consumeTable =  self:juageConsumeEnough(level)
		if not isEnough then
			uiMgr:ShowInformationTips(__('升级外卖车所需材料不足~'))
			return
		end
        self:SendSignal(COMMANDS.COMMANDS_TAKEAWAY, {action = 'Takeaway/upgradeDiningCar',diningCarId = id})
    end)
end

--[[
	显示解锁页面
]]
function TakeAwayMediator:ShowLockUI(carInfo)
	self.collectTable  ={}
	local viewData = CreateUnlockUpgradeView(1, function()
        PlayAudioByClickNormal()
		if  self.lockViewData  and  ( not tolua.isnull( self.lockViewData.view)) then
			self.lockViewData.view:runAction(cc.RemoveSelf:create())
			self.lockViewData = nil
		end
    end)
	self.lockViewData = viewData
	local scene = uiMgr:GetCurrentScene()
	display.commonUIParams(viewData.view, {po = display.center})
	scene:AddDialog(viewData.view,20)
	local carConfig = CommonUtils.GetConfigAllMess('diningCar','takeaway')
	local carId = checkint(carInfo.diningCarId)
	if carConfig[tostring(carId)] then
		local types = carConfig[tostring(carId)].unlockType
		local goods = {}
		for k,v in pairs(types) do
			if checkint(k) == UnlockTypes.AS_LEVEL then
				if checkint(gameMgr:GetUserInfo().restaurantLevel) >= checkint(v.targetNum) then
					--达到等级的逻辑
					viewData.upgradeButton:setNormalImage(_res('ui/common/common_btn_orange.png'))
					viewData.upgradeButton:setSelectedImage(_res('ui/common/common_btn_orange.png'))
				else
					--没有达到要求的等级
					viewData.upgradeButton:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
					viewData.upgradeButton:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
				end
			else
				if checkint(k) == UnlockTypes.GOLD then
					table.insert( goods,{goodsId = GOLD_ID, num = checkint(v.targetNum)} )
				elseif checkint(k) == UnlockTypes.DIAMOND then
					table.insert( goods,{goodsId = DIAMOND_ID, num = checkint(v.targetNum)} )
				elseif checkint(k) == UnlockTypes.GOODS then
					table.insert( goods,{goodsId = checkint(v.targetId), num = checkint(v.targetNum)} )
				end
			end
		end
		--添加升级所需的材料
		viewData.rewardView:removeAllChildren()
		local len = table.nums(goods) 
		local centerPos = math.floor((len + 1) / 2)
		local cx,cy = viewData.rewardView:getContentSize().width * 0.5,  viewData.rewardView:getContentSize().height * 0.5
		local goodsEnough = true 
		for i,v in ipairs(goods) do
			local function callBack(sender)
				AppFacade.GetInstance():GetManager("UIManager"):ShowInformationTipsBoard({targetNode = sender, iconId = v.goodsId, type = 1})
			end
			if len % 2 == 0 then
				--偶数
				local x, y = (cx - (centerPos - i  + 0.5) * 140),cy
				local goodsNode = require('common.GoodNode').new({id = v.goodsId, amount = v.num, showAmount = false,callBack = callBack})
				display.commonUIParams(goodsNode, {animate = false, cb = function (sender)
					uiMgr:AddDialog("common.GainPopup", {goodId =v.goodsId,})
					-- uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = data.goodsId, type = 1})
				end})
				goodsNode:setPosition(cc.p(x,y))
				goodsNode:setScale(0.75)
				viewData.rewardView:addChild(goodsNode, 5)
				-- local numLabel = display.newLabel(50, -16, {
				-- 	fontSize = 24, text = string.format( "%d/%d", CommonUtils.GetCacheProductNum(v.goodsId), checkint(v.num)),color = '5c5c5c',ttf = true, font = TTF_GAME_FONT
				-- })
				if CommonUtils.GetCacheProductNum(v.goodsId)< checkint(v.num) then
					goodsEnough = false 
				end
				local fontNum = 8
				
				if gameMgr:GetUserInfo().gold  < checkint(v.num )  then 
					fontNum = 10 
				end 

				local numLabel = display.newRichLabel(50, -16,{ r = true  , c = { 
					fontWithColor(fontNum , { text =  CommonUtils.GetCacheProductNum(v.goodsId) }) ,
					fontWithColor('8' , {text = '/' .. tostring(v.num) }) 
				}})
				goodsNode:addChild(numLabel, 10)
				numLabel:setName("numLabel")
				numLabel.str =   CommonUtils.GetCacheProductNum(v.goodsId) .. '/' .. tostring(v.num)
				table.insert(self.collectTable,#self.collectTable+1, goodsNode)
			else
				-- 奇数
				local x, y = (cx - (centerPos - i ) * 140),cy
				local goodsNode = require('common.GoodNode').new({id = v.goodsId, amount = v.num, showAmount = false,callBack = callBack})
				display.commonUIParams(goodNode, {animate = false, cb = function (sender)
					uiMgr:AddDialog("common.GainPopup", {goodId =v.goodsId,})
					-- uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = data.goodsId, type = 1})
				end})
				goodsNode:setPosition(cc.p(x,y))
				goodsNode:setScale(0.75)
				viewData.rewardView:addChild(goodsNode, 5)
				-- local numLabel = display.newLabel(50, -16, {
				-- 	fontSize = 24, text = string.format( "%d/%d", CommonUtils.GetCacheProductNum(v.goodsId), checkint(v.num)),color = '5c5c5c',ttf = true, font = TTF_GAME_FONT
				-- })

				if CommonUtils.GetCacheProductNum(v.goodsId)< checkint(v.num) then
					goodsEnough = false 
				end
				local fontNum = 8
				if gameMgr:GetUserInfo().gold   < checkint(v.num )  then 
					fontNum = 10 
				end 

				local numLabel = display.newRichLabel(50, -16,{  r = true  , c = { 
					fontWithColor(fontNum , {text =  CommonUtils.GetCacheProductNum(v.goodsId) }) ,
					fontWithColor('8' , {text = '/' .. tostring(v.num) }) 
				}})
				goodsNode:addChild(numLabel, 10)
				numLabel:setName("numLabel")
				numLabel.str =   CommonUtils.GetCacheProductNum(v.goodsId) .. '/' .. tostring(v.num)
				table.insert(self.collectTable,#self.collectTable+1, goodsNode)
			end
		end
		viewData.upgradeButton:setUserTag(checkint(carInfo.diningCarId))
		viewData.upgradeButton:setOnClickScriptHandler(function(sender)
			--升级的逻辑
			local id = sender:getUserTag()
			--no lock
			if carConfig[tostring(id)] then
				local types = carConfig[tostring(id)].unlockType
				if types[tostring(UnlockTypes.AS_LEVEL)] then
					if checkint(gameMgr:GetUserInfo().level) >= checkint(types[tostring(UnlockTypes.AS_LEVEL)].targetNum) then
						--当等级达到的时候判断物品是否足够 
						if goodsEnough then
							self:SendSignal(COMMANDS.COMMANDS_TAKEAWAY, {action = 'Takeaway/unlockDiningCar',diningCarId = id})
						else
							uiMgr:ShowInformationTips(__('解锁外卖车道具不足'))
						end						
					else
						--提示等级未达到的逻辑
						local typeInfos = CommonUtils.GetConfigAllMess('unlockType')
						uiMgr:ShowInformationTips(string.fmt(typeInfos[tostring(UnlockTypes.AS_LEVEL)],{_target_num_ = checkint(types[tostring(UnlockTypes.AS_LEVEL)].targetNum)}))
					end
				else
					if goodsEnough then
						self:SendSignal(COMMANDS.COMMANDS_TAKEAWAY, {action = 'Takeaway/unlockDiningCar',diningCarId = id})
					else
						uiMgr:ShowInformationTips(__('解锁外卖车道具不足'))
					end
				end
			else
				return 
			 end
		end)
		
	end
end
--[[
-- 刷新所有的车的逻辑
--]]
function TakeAwayMediator:RefreshCards()
	xTry(function()
        local cars = nil 
        if not self.datas then
            self.datas = takeawayInstance:GetDatas() 
        end 
		cars = checktable(self.datas.diningCar)
		for diningCarId,cardViewData in pairs(self.viewData.cardViewDatas) do
			--遍历所有的卡车
			local serverCarInfo = nil
			for i,v in ipairs(cars) do
				if checkint(v.diningCarId) == checkint(diningCarId) then
					serverCarInfo = v
					break
				end
			end
			cardViewData.unLockBtn:setEnabled(true)
			cardViewData.upgradeButton:setEnabled(true)
		
			if serverCarInfo then
				--已有的车的数据
				local level = serverCarInfo.level
				local upgradeButtonSize = cardViewData.upgradeButton:getContentSize()
				local isEnough ,consumeTable =  self:juageConsumeEnough(checkint( level))
				if  isEnough then 
					cardViewData.upgradeButton:getLabel():setPosition(cc.p(upgradeButtonSize.width/2 - upgradeButtonSize.width/4+10 , upgradeButtonSize.height/2 ))
					cardViewData.upgradeButton:setVisible(true)
				else
					cardViewData.upgradeButton:setVisible(false)
				end
				local status = checkint(serverCarInfo.status)
				local level = checkint(serverCarInfo.level)
				display.commonLabelParams(cardViewData.unLockBtn , fontWithColor('14',{ text   = __('领取奖励')}) )
				cardViewData.unLockBtn:setOnClickScriptHandler(function(sender)
					--表示其他状态 但是只处理配送中相关的处理
                    PlayAudioClip(AUDIOS.UI.ui_moto.id)
                    local orderInfo = takeawayInstance:GetOrderInfoByOrderInfo({orderId = checkint(serverCarInfo.orderId), orderType = checkint(serverCarInfo.orderType)})
                    if orderInfo and checkint(orderInfo.status) == 4 then
                        --完成配送的逻辑
                        local LargeAndOrdinaryMediator = require( 'Game.mediator.LargeAndOrdinaryMediator')
                        orderInfo.orderType = checkint(serverCarInfo.orderType)
                        local mediator = LargeAndOrdinaryMediator.new(orderInfo)
                        shareFacade:RegistMediator(mediator)
                    end
				end)				
                cardViewData.upgradeButton:setOnClickScriptHandler(function(sender)
					--升级按钮的显示逻辑窗口,弹出升级或者解锁的窗口
					self:ShowUpgradeUI(serverCarInfo)
				end)
				cardViewData.porpertyButton:setOnClickScriptHandler(function(sender)
					--升级按钮的显示逻辑窗口,弹出升级或者解锁的窗口
					self:ShowUpgradeUI(serverCarInfo)
				end)
				--解锁的再判读状态值
				cardViewData.levelButton:setVisible(true)
	 
				display.commonLabelParams(cardViewData.levelButton, {ttf = true,font = TTF_GAME_FONT, fontSize = 35, color = 'ffffff', text = string.fmt(__('__num__级'), {__num__ =level})})
				cardViewData.cardNode:setColor(cc.c3b(255,255,255))
				cardViewData.unLockImage:setVisible(false)
				if status == 1 then
					--等待送
                    local levels = CommonUtils.GetConfigAllMess('diningCarLevelUp', 'takeaway')
                    local maxLevel = table.nums(checktable(levels))
                    if checkint(serverCarInfo.level) >= maxLevel or (not   isEnough )   then
                        cardViewData.upgradeButton:setVisible(false)
						cardViewData.porpertyButton:setVisible(true) 
                    else
                        cardViewData.upgradeButton:setVisible(true)
						cardViewData.porpertyButton:setVisible(false) 
                    end
					-- cardViewData.timeCountDownBg:setVisible(false)
					cardViewData.lighting:setVisible(false)
					cardViewData.rewardBox:setVisible(false)
					cardViewData.rewardBoxBg:setVisible(false)
					cardViewData.unLockBtn:setVisible(false)
					cardViewData.cardNode:setTimeScale(1.0)
					local viewSize  = cardViewData.view:getContentSize()
					cardViewData.cview:setAnchorPoint(display.LEFT_CENTER)
					cardViewData.cview:setPosition(cc.p(0, viewSize.height/2))
				elseif status == 2 or status == 3 then
					--配送中
					local orderInfo = takeawayInstance:GetOrderInfoByOrderInfo(serverCarInfo)
					if orderInfo then
						cardViewData.upgradeButton:setVisible(false)
						-- cardViewData.timeCountDownBg:setVisible(true)
						cardViewData.lighting:setVisible(false)
						cardViewData.rewardBox:setVisible(true)
						cardViewData.rewardBoxBg:setVisible(true)
						cardViewData.unLockBtn:setVisible(false)
						cardViewData.rewardBox:setTimeScale(1.0)
						cardViewData.rewardBoxBg:setTimeScale(1.0)
						cardViewData.cardNode:setTimeScale(1.0)
						--配送中的计时器刷新的逻辑
						local type = checkint(serverCarInfo.orderType)
						local timerName = app.takeawayMgr:GetOrderTimerKey(checkint(orderInfo.areaId), type, checkint(orderInfo.orderId))
						local timerInfo = timerMgr:RetriveTimer(timerName) --移除旧的计时器，活加新计时器
						if not  timerInfo then
							timerMgr:AddTimer({name = timerName, countdown = checkint(orderInfo.leftSeconds), tag = RemindTag.TAKEAWAY_TIMER, datas = serverCarInfo} )
							timerInfo = timerMgr:RetriveTimer(timerName) --移除旧的计时器，活加新计时器
						end 
						if timerInfo.countdown == 0 then
									--可领取奖励了的逻辑
									cardViewData.timeBg:setVisible(false)
								else
								cardViewData.timeBg:setVisible(true)
								cardViewData.timerLabel:setVisible(true)
								display.reloadRichLabel(cardViewData.timerLabel , { c =  { 
								fontWithColor('16', { text = __('配送中')}),
								fontWithColor('10', 
								{ text =  string.formattedTime(checkint(countdown),'%02i:%02i:%02i')})
							}})
						end
						--播放宝箱的动画
						cardViewData.rewardBoxBg:setAnimation(0, 'idle', true)
						cardViewData.rewardBox:setAnimation(0, 'can', true)
						--播放送的功画
						cardViewData.cardNode:setAnimation(0, 'idle', true)
						local viewSize  = cardViewData.view:getContentSize()
						cardViewData.cview:setAnchorPoint(display.CENTER)
						cardViewData.cview:setPosition(cc.p(viewSize.width/2 , viewSize.height/2))
					end
				elseif status == 4 then
					--配送完成
					local viewSize  = cardViewData.view:getContentSize()
					cardViewData.cview:setPosition(cc.p(viewSize.width/2 , viewSize.height/2))
					cardViewData.cview:setAnchorPoint(display.CENTER)
					cardViewData.rewardBox:setTimeScale(1.0)
					cardViewData.rewardBoxBg:setTimeScale(1.0)
					cardViewData.cardNode:setTimeScale(1.0)
					cardViewData.upgradeButton:setVisible(false)
					-- cardViewData.timeCountDownBg:setVisible(true)
					cardViewData.timeBg:setVisible(false)
					cardViewData.rewardBoxBg:setAnimation(0, 'idle', true)
					cardViewData.lighting:setVisible(true)
					cardViewData.lighting:setTimeScale(1.0)
					cardViewData.unLockBtn:setVisible(true)
					cardViewData.rewardBox:setAnimation(0, 'baoxiang2', true)
				end
			else
				--需要手动解锁的车的数据
				cardViewData.levelButton:setVisible(false)
				cardViewData.cardNode:setColor(cc.c3b(100,100,100))
				cardViewData.upgradeButton:setVisible(false)
				cardViewData.lighting:setVisible(false)
				cardViewData.rewardBox:setVisible(false)
				cardViewData.rewardBoxBg:setVisible(false)
				cardViewData.unLockBtn:setVisible(true)
				local carInfo = {diningCarId = checkint(diningCarId)}
				local carConfig = CommonUtils.GetConfigAllMess('diningCar','takeaway')
				local id  = checkint(carInfo.diningCarId) 
				if carConfig[tostring(id)] then --  判断等级解锁
				local types = carConfig[tostring(id)].unlockType
				local  isEnabled = true
				local typeInfos = nil 
 				if types[tostring(UnlockTypes.AS_LEVEL)] then
					if checkint(gameMgr:GetUserInfo().restaurantLevel) < checkint(types[tostring(UnlockTypes.AS_LEVEL)].targetNum) then -- 餐厅两级解锁
						--提示等级未达到的逻辑
						isEnabled = false  
						cardViewData.unLockBtn:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
						typeInfos = CommonUtils.GetConfigAllMess('unlockType')
					end 
			 	end
				cardViewData.unLockBtn:setOnClickScriptHandler(function(sender)
					--表示锁定的页面 处理解锁的逻辑
					if not  isEnabled then
						
						uiMgr:ShowInformationTips(string.fmt(typeInfos[tostring(UnlockTypes.AS_LEVEL)],{_target_num_ = checkint(types[tostring(UnlockTypes.AS_LEVEL)].targetNum)}))
						return
					end  
                    PlayAudioClip(AUDIOS.UI.ui_moto.id)
					 
					self:ShowLockUI({diningCarId = checkint(diningCarId)})
				end)
			end
		end
	end 
	end,__G__TRACKBACK__)
end
--- 刷新界面的goodsnode显示
function TakeAwayMediator:RefreshGoodsNode()
	for k , v in pairs(self.collectTable) do
		if not  tolua.isnull(v) then
			local label = v:getChildByName("numLabel")
			dump(label)
			if label and ( not  tolua.isnull(label)) then
				dump(self.collectTable)
				if label.str and label.str ~= "" then
					local strTable = string.split(label.str, "/")
					if #strTable == 2 then
						local fontNum =  8
						if CommonUtils.GetCacheProductNum(v.goodId) < checkint(strTable[2]) then
							fontNum = 10
						end
						display.reloadRichLabel(label,{
							c = {
								fontWithColor(fontNum , { fontSize = 24 , text =  CommonUtils.GetCacheProductNum(v.goodId) }) ,
								fontWithColor('8' , {fontSize = 24 , text = '/' .. tostring(strTable[2]) })
							}
						} )
					end
				end
			end
		end
	end
end
-- 添加红点
function TakeAwayMediator:AddBtnRedDot(btn)
	local node = btn:getChildByTag(RED_TAG)
	if not  node  then
		local image = display.newImageView(_res('ui/common/common_hint_circle_red_ico.png'))
		image:setTag(RED_TAG)
		local size =  btn:getContentSize()
		image:setPosition(cc.p(size.width-20,size.height-20))
		btn:addChild(image,10)
	end
end
-- 清理红点
function TakeAwayMediator:ClearBtnRedDot(btn)
	local image =  btn:getChildByTag(RED_TAG)
	if image and not  tolua.isnull(image) then
		image:runAction(cc.RemoveSelf:create())
	end
end
---
function TakeAwayMediator:CheckAndAddCardUnLocakAndUpgradeRed()
	if gameMgr:GetUserInfo().isCardRed then
		local diningCar = takeawayInstance:GetDatas().diningCar or  {}
		for i  =1 ,  3 do
			local num = dataMgr:GetRedDotNofication("TakeAway", tostring(i))
			if num > 0 then
				if  diningCar[i] then
					self:AddBtnRedDot(self.collectTakeWayBtns[i].upgradeBtn)
				else
					self:AddBtnRedDot(self.collectTakeWayBtns[i].unLockBtn)
				end
			else
				if   takeawayInstance:GetDatas().diningCar[i] then
					self:AddBtnRedDot(self.collectTakeWayBtns[i].upgradeBtn)
				else
					self:ClearBtnRedDot(self.collectTakeWayBtns[i].unLockBtn)
				end
			end
		end
	end
end
function TakeAwayMediator:OnRegist(  )
	local TakeAwayCommand = require( 'Game.command.TakeAwayCommand')
	self:GetFacade():RegistSignal(COMMANDS.COMMANDS_TAKEAWAY, TakeAwayCommand)
	self:GetFacade():RegistObserver("REFRESH_NOT_CLOSE_GOODS_EVENT", mvc.Observer.new(self.ProcessSignal, self))
	if not takeawayInstance.freshSuccess then
		self:SendSignal(COMMANDS.COMMANDS_TAKEAWAY, {action = "Takeaway/home"})
	else
		self:GetFacade():DispatchObservers(SIGNALNAMES.SIGNALNAMES_TAKEAWAY_HOME,takeawayInstance.orderDatas)
	end
	local moduleData = CommonUtils.GetConfigAllMess('module')
	if gameMgr:GetUserInfo().level ==  checkint(moduleData[ tostring(MODULE_DATA[tostring(RemindTag.CARVIEW)])  ].openLevel)  then
		self:SendSignal(COMMANDS.COMMANDS_TAKEAWAY, {action = "Takeaway/home"})
	end
end

function TakeAwayMediator:OnUnRegist(  )
	-- 称出命令
	shareFacade:UnRegistObserver(COUNT_DOWN_ACTION_UI, self)
	app.badgeMgr:JudageTakeAwayCarAddRed()
	self:GetFacade():UnRegistObserver("REFRESH_NOT_CLOSE_GOODS_EVENT",self)


	self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_TAKEAWAY)
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveDialog(self.viewComponent)
end

return TakeAwayMediator
