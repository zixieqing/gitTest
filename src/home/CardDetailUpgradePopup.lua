--[[
详情升级弹窗
@params table {
	id int card id
	lv int card level
	breakLv int breakLv
	exp int card exp
}
--]]
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local GameScene = require( "Frame.GameScene" )

local CDUpgradePopup = class('CDUpgradePopup', GameScene)


-- local CDUpgradePopup = class('CDUpgradePopup', function ()
-- 	local node = CLayout:create()
-- 	-- node:setBackgroundColor(cc.c4b(0, 0, 0, 100))
-- 	node.name = 'home.CDUpgradePopup'
-- 	node:enableNodeEvents()
-- 	return node
-- end)

function CDUpgradePopup:ctor( ... )
	local args = unpack({...})
    self.args = args
    self.callback = self.args.callback
    self.useItemsNum = 0
	self.numBei = 4
    -- dump(self.args)
	--------------------------------------
	-- ui

	self.detailBg = nil
	self.expBar = nil
	self.propListView = nil
	self.expLabel = nil
	self.goodsItem = {}
	self.isLongClick = false
	self.touPos = cc.p(0,0)

	self.tempExp  = self.args.exp 
	self.oldLevel = self.args.level
	-- self.newLevel = self.args.level

	--------------------------------------
	-- ui data

	self.propertyData = {
		{pName = 'lv', name = __('等级')},
		{pName = 'attack', name = __('攻击力')},
		{pName = 'defence', name = __('防御力')},
		{pName = 'hp', name = __('生命值')},
		{pName = 'critRate', name = __('暴击')},
		{pName = 'critDamage', name = __('暴击伤害')},
		{pName = 'attackRate', name = __('攻击速度')}
	}

	--------------------------------------
	-- ui

	self:initUI()
end



function CDUpgradePopup:initUI()
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
	eaterLayer:setTouchEnabled(true)
	eaterLayer:setContentSize(display.size)
	eaterLayer:setAnchorPoint(cc.p(0.5, 1.0))
	eaterLayer:setPosition(cc.p(display.cx, display.height))-- - NAV_BAR_HEIGHT
	self:addChild(eaterLayer, -1)
	eaterLayer:setOnClickScriptHandler(function (sender)
        self:removeFromParent()
		-- self:runAction(cc.RemoveSelf:create())
	end)

	local bgPoint = cc.p(400, display.cy - 250)
	local bgSize  = cc.size(386, 300)
	local bgLayer = CommonUtils.getCommonPopupBg({bgSize = bgSize, closeCallback = function ()
		self:runAction(cc.RemoveSelf:create())
	end})
	bgLayer:setAnchorPoint(cc.p(0.5,0))
	bgLayer:setPosition(bgPoint)
	self:addChild(bgLayer)

	bgLayer:setOpacity(0)
	bgLayer:setPositionY(bgPoint.y - display.cy)
	bgLayer:runAction(
        cc.Sequence:create(cc.DelayTime:create(0.02),
        cc.Spawn:create(cc.FadeIn:create(0.6),
        	cc.EaseOut:create(cc.MoveTo:create(0.3, bgPoint), 0.7)
        ))
 
    )

	
	-- title
	local titleLabel = display.newLabel(bgSize.width * 0.5, bgSize.height * 0.86,
		{text = string.fmt(__('使用药水可以增加经验值')) , fontSize = 20, color = '#7e6454'})
	bgLayer:addChild(titleLabel)
	local titleLabelSize =  display.getLabelContentSize(titleLabel)
	if titleLabelSize.width > 370 then
		local currentScale = titleLabel:getScale()
		titleLabel:setScale(currentScale * 370 /titleLabelSize.width )
	end


	local t = {
		{goodId = 130001,name = __('小经验药水'),tag = 1},
		{goodId = 130002,name = __('中经验药水'),tag = 2},
		{goodId = 130003,name = __('大经验药水'),tag = 3}
	}
	local goodIconSize = cc.size(85, 85)
	for i,v in ipairs(t) do
		local goodConfig = CommonUtils.GetConfig('goods', 'goods', v.goodId)
		local num = gameMgr:GetAmountByGoodId(v.goodId) or 0

		local goodIcon = require('common.GoodNode').new({id = v.goodId, showAmount = true,showName = false,amount = num})--,callBack = callBack
		local goodIconScale = goodIconSize.width / goodIcon:getContentSize().width
		goodIconScale = 0.7
		goodIcon:setScale(goodIconScale)
		goodIcon:setAnchorPoint(cc.p(0.5, 0.5))
		goodIcon:setPosition(cc.p(bgSize.width * 0.5 - (2 - i) * 100,bgSize.height * 0.5))-- expBg:getPositionY()- expBg:getContentSize().height*0.25
		bgLayer:addChild(goodIcon,1)
		local descLabel = display.newLabel(goodIcon:getPositionX(), goodIcon:getPositionY() - goodIcon:getContentSize().height * goodIconScale * 0.5 - 4 ,
			{text = string.format('+%d', checkint(goodConfig.effectNum)), fontSize = 20, color = '#6c6c6c', ap = cc.p(0.5, 1)})
		bgLayer:addChild(descLabel)
		goodIcon:setTag(v.tag)
		goodIcon:setOnClickScriptHandler(function (sender)
			if self.isAction == true then return end
			local num = gameMgr:GetAmountByGoodId(v.goodId)
			if num <= 0 then
				print('******* 跳转获取该货币页面 **********')
				-- goodIcon:setTouchEnabled(false)]
				if GAME_MODULE_OPEN.NEW_STORE then
					uiMgr:AddDialog("common.GainPopup", {goodId = t[i].goodId })
				else
					if isJapanSdk then
						uiMgr:ShowInformationTips(isJapanSdk() and __('经验瓶数量不足') or __('所需材料不足'))
					else
						uiMgr:ShowInformationTips( __('所需材料不足'))
					end
				end

			else
				local breakLevel = self.args.breakLevel
				-- if checkint(breakLevel) >= CommonUtils.GetConfig('cards', 'cardBreak',self.args.qualityId).breakNum then
				-- 	breakLevel = CommonUtils.GetConfig('cards', 'cardBreak',self.args.qualityId).breakNum
				-- else
				-- 	breakLevel = breakLevel + 1
				-- end
				local maxLevel = CommonUtils.GetConfig('cards', 'card',self.args.cardId).breakLevel[checkint(breakLevel)+1]
				if checkint(self.args.level) < checkint(gameMgr:GetUserInfo().level) and checkint(self.args.level) < checkint(maxLevel) then
					-- print('adasdasdasdasdasdassdasdasdasdasd')
					local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
					httpManager:Post("card/cardLevelUp",SIGNALNAMES.Hero_LevelUp_Callback,{ playerCardId = self.args.id,goodsId = v.goodId,num = 1,BshowLevelUpAction = 1},true)
				else
					local totalExp = 0
					local temp_str = ''
					-- print(maxLevel,gameMgr:GetUserInfo().level)
					if checkint(maxLevel) >= checkint(gameMgr:GetUserInfo().level) then
						totalExp = CommonUtils.GetConfig('cards', 'level',checkint(gameMgr:GetUserInfo().level)+1).totalExp
						if checkint(self.args.exp) < checkint(totalExp) then
							local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
							httpManager:Post("card/cardLevelUp",SIGNALNAMES.Hero_LevelUp_Callback,{ playerCardId = self.args.id,goodsId = v.goodId,num = 1,BshowLevelUpAction = 1},true)
							return
						else
							temp_str = string.fmt(__('无法升级，卡牌等级不能超过主角等级。'))
						end
					else
						totalExp = CommonUtils.GetConfig('cards', 'level',checkint(maxLevel+1)).totalExp
						if checkint(self.args.exp) < checkint(totalExp) then
							local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
							httpManager:Post("card/cardLevelUp",SIGNALNAMES.Hero_LevelUp_Callback,{ playerCardId = self.args.id,goodsId = v.goodId,num = 1,BshowLevelUpAction = 1},true)
							return
						else
							temp_str = __('无法升级，卡牌等级已达到等级上限.升星可提升等级上限。')
						end
					end
					uiMgr:ShowInformationTips(string.fmt('_text_',{_text_ = temp_str}))
				end
			end
		end)
		table.insert(self.goodsItem,goodIcon)

		local itemBg = display.newImageView(_res('ui/cards/property/role_main_bg_good.png'), goodIcon:getPositionX(),goodIcon:getPositionY(),
			{ap = cc.p(0.5, 0.5)})
		bgLayer:addChild(itemBg)
	end


    local uplevelBtn = display.newButton(0, 0,
    	{n = _res('ui/common/common_btn_orange.png'), animate = true, cb = handler(self, self.oneKeyLevelUpBtnCallback)})
    display.commonUIParams(uplevelBtn, {ap = cc.p(0.5,0),po = cc.p( bgSize.width * 0.5 - 4, 15)})
    display.commonLabelParams(uplevelBtn, fontWithColor(14,{text = __('一键升级')}))
    bgLayer:addChild(uplevelBtn,1)


	self:refreshUI(self.args)

     self.touchListener_ = cc.EventListenerTouchOneByOne:create()
     self.touchListener_:registerScriptHandler(handler(self, self.onTouchBegan_), cc.Handler.EVENT_TOUCH_BEGAN)
     self.touchListener_:registerScriptHandler(handler(self, self.onTouchMoved_), cc.Handler.EVENT_TOUCH_MOVED)
     self.touchListener_:registerScriptHandler(handler(self, self.onTouchEnded_), cc.Handler.EVENT_TOUCH_ENDED)
     self.touchListener_:registerScriptHandler(handler(self, self.onTouchCancelled_), cc.Handler.EVENT_TOUCH_CANCELLED)
     self:getEventDispatcher():addEventListenerWithSceneGraphPriority(self.touchListener_, self)
end

function CDUpgradePopup:oneKeyLevelUpBtnCallback(pSender)
	-- dump(self.args)
	local t = {
		{goodId = 130001,name = __('小经验药水'),tag = 1},
		{goodId = 130002,name = __('中经验药水'),tag = 2},
		{goodId = 130003,name = __('大经验药水'),tag = 3}
	}
	local canLvUp = false
	local temp_str = ''
	local breakLevel = self.args.breakLevel
	local maxLevel = CommonUtils.GetConfig('cards', 'card',self.args.cardId).breakLevel[checkint(breakLevel)+1]
	if checkint(self.args.level) < checkint(gameMgr:GetUserInfo().level) and checkint(self.args.level) < checkint(maxLevel) then
		canLvUp = true
	else
		local totalExp = 0
		if checkint(maxLevel) >= checkint(gameMgr:GetUserInfo().level) then
			-- totalExp = CommonUtils.GetConfig('cards', 'level',checkint(gameMgr:GetUserInfo().level)+1).totalExp
			-- if checkint(self.args.exp) < checkint(totalExp) then
			-- 	canLvUp = true
			-- else
			-- 	canLvUp = false
			-- 	temp_str = string.fmt(__('无法升级，卡牌等级不能超过主角等级。'))
			-- end

			canLvUp = false
			temp_str = string.fmt(__('目前已经达到当前最高等级，不可进行一键升级。'))
		else
			totalExp = CommonUtils.GetConfig('cards', 'level',checkint(maxLevel+1)).totalExp
			if checkint(self.args.exp) < checkint(totalExp) then
				canLvUp = true
			else
				canLvUp = false
				temp_str = __('无法升级，卡牌等级已达到等级上限.升星可提升等级上限。')
			end
		end
	end

	local goodsNum = 0
	for i,v in ipairs(t) do
		local num = gameMgr:GetAmountByGoodId(v.goodId)
		goodsNum = goodsNum + num
	end
	if goodsNum <= 0 then
		canLvUp = false
		temp_str = __('所需材料不足')
	end

	if canLvUp == true then
		local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
		httpManager:Post("card/cardUpgradeMaxKey",SIGNALNAMES.Hero_OneKeyLevelUp_Callback,{ playerCardId = self.args.id })
	else
		if GAME_MODULE_OPEN.NEW_STORE and goodsNum <= 0 then
			uiMgr:AddDialog("common.GainPopup", {goodId = 130003})
		else
			uiMgr:ShowInformationTips(string.fmt('_text_',{_text_ = temp_str}))
		end
	end
end

function CDUpgradePopup:onTouchBegan_(touch, event)
	local point = touch:getLocation()
	self.touPos = point
	for i,v in ipairs(self.goodsItem) do
		local parent = v:getParent()
		local btnAddRect = v:getBoundingBox()
		if cc.rectContainsPoint(btnAddRect,parent:convertToNodeSpace(point))then
			print("------------------>>>" , i)
			local actionSeq = cc.Sequence:create(
			cc.DelayTime:create(0.5/self.numBei),
			cc.CallFunc:create(function ()
				if cc.rectContainsPoint(btnAddRect,parent:convertToNodeSpace(self.touPos))then
					self.isAction = true
					self.isLongClick = true
					self:dcdLongAction(v)
				else
					self:stopAllActions()
				end
			end))
			self:runAction( actionSeq )
			break
		end
	end
    return true

end

function CDUpgradePopup:onTouchMoved_(touch, event)
	local point = touch:getLocation()
	self.touPos = point
end


function CDUpgradePopup:onTouchEnded_(touch, event)
	self:stopAllActions()
	if self.useItemsNum > 0  then
		self:longClickEndAction()

	end
	self.isAction = false
	self.isLongClick = false
end

function CDUpgradePopup:longClickEndAction(sender,touch,duration)
    self:stopAllActions()
	local t = {
		{goodId = 130001},
		{goodId = 130002},
		{goodId = 130003}
	}
	for i,v in ipairs(t) do
		if self.goodsItem[i] then
			local num = gameMgr:GetAmountByGoodId(v.goodId)
			self.goodsItem[i]:updataNum( num )
		end
	end
	local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
	httpManager:Post("card/cardLevelUp",SIGNALNAMES.Hero_LevelUp_Callback,{ playerCardId = self.args.id,goodsId = t[self.tag].goodId,num = self.useItemsNum,BshowLevelUpAction = 2},true)
	self.useItemsNum = 0
end
function CDUpgradePopup:dcdLongAction(sender,touch)
    self.tag = sender:getTag()
	print("self.tag = " , self.tag)
    self:stopAllActions()
	local t = {
		{goodId = 130001},
		{goodId = 130002},
		{goodId = 130003}
	}
	local clickGoodsId = checkint(checktable(t[self.tag]).goodId)
	local goodConfig = CommonUtils.GetConfig('goods', 'goods', clickGoodsId) or {}
    local actionSeq = cc.Sequence:create(
		cc.CallFunc:create(function ()
			local useItemsNum = self.useItemsNum + 1
			local breakLevel = checkint(self.args.breakLevel)
			local cardOneConfig =  CommonUtils.GetConfig('cards', 'card',self.args.cardId)
			local breakLevelIndex  =  table.nums(cardOneConfig.breakLevel) > breakLevel and (breakLevel +1) or breakLevel
			local maxLevel = cardOneConfig.breakLevel[checkint(breakLevelIndex)]
			local countNum =  gameMgr:GetAmountByGoodId(clickGoodsId)
			local num = countNum - useItemsNum
			local levelConfig = CommonUtils.GetConfigAllMess('level' ,'cards' )
			local oldLevel = checkint(self.oldLevel)
			if countNum == 0  then
				self.isLongClick = false
				self:stopAllActions()
				if GAME_MODULE_OPEN.NEW_STORE then
					uiMgr:AddDialog("common.GainPopup", {goodId = clickGoodsId})
				else
					uiMgr:ShowInformationTips(__('所需材料不足'))
				end
			end
			if num < 0  then
				return
			else
				local levelOneConfig = nil
				local maxExp  = nil
				local tempExp = self.tempExp + checkint(goodConfig.effectNum)
				if checkint(maxLevel) <= checkint(gameMgr:GetUserInfo().level)  then
					levelOneConfig = levelConfig[tostring(maxLevel+1)]
					maxExp = levelOneConfig and levelOneConfig.totalExp or levelConfig[tostring(maxLevel)].totalExp
				else
					levelOneConfig = levelConfig[tostring(gameMgr:GetUserInfo().level+1)]
					maxExp = levelOneConfig.totalExp
				end
				if tempExp >=  maxExp then
					if oldLevel >=  gameMgr:GetUserInfo().level  then
						self.isLongClick = false
						self:stopAllActions()
						uiMgr:ShowInformationTips(__('无法升级，卡牌等级不能超过主角等级。'))
						return
					else
						self.isLongClick = false
						self:stopAllActions()
						uiMgr:ShowInformationTips(__('无法升级，卡牌等级已达到等级上限.升星可提升等级上限。'))
						return
					end
				end
				local oldLevelExp =  levelConfig[tostring(oldLevel+1)].totalExp
				if checkint(tempExp)  >=  checkint(oldLevelExp) then
					oldLevel = oldLevel +1
				end
				self.tempExp = tempExp
				self.oldLevel = oldLevel
				self.useItemsNum = useItemsNum
				self.goodsItem[self.tag]:updataNum( num )
				if self.callback then
					self.callback(self.oldLevel,self.tempExp)
				end
			end
		end),
		cc.DelayTime:create(0.5/self.numBei))
	self:runAction( cc.RepeatForever:create(actionSeq))
end

function CDUpgradePopup:refreshUI(data)
	if data then
		self.args = data
	end
	self.tempExp  = self.args.exp
	self.oldLevel = self.args.level

	local t = {
		{goodId = 130001},
		{goodId = 130002},
		{goodId = 130003}
	}
	for i,v in ipairs(t) do
		if self.goodsItem[i] then
			local num = gameMgr:GetAmountByGoodId(v.goodId)
			self.goodsItem[i]:updataNum( num )
		end
	end
end

function CDUpgradePopup:onCleanup()
	 -- self:getEventDispatcher():removeEventListener(self.touchListener_)
end


return CDUpgradePopup
