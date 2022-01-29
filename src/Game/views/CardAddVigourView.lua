--[[
吃菜恢复疲劳值弹窗

--]]
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local GameScene = require( "Frame.GameScene" )

local CardAddVigourView = class('CardAddVigourView', GameScene)


function CardAddVigourView:ctor( ... )
	local arg = unpack({...})
    self.args = arg
    self.useItemsNum = 0
    -- dump(self.args)
	--------------------------------------
	-- ui

	self.goodsItem = {}
	--------------------------------------
	-- ui data
	self.vigour = checkint(self.args.vigour)
	--------------------------------------
	-- ui

	self:initUI()
end



function CardAddVigourView:initUI()
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
	eaterLayer:setTouchEnabled(true)
	eaterLayer:setContentSize(display.size)
	eaterLayer:setAnchorPoint(cc.p(0.5, 1.0))
	eaterLayer:setPosition(cc.p(display.cx, display.height))-- - NAV_BAR_HEIGHT
	self:addChild(eaterLayer, -1)
	eaterLayer:setOnClickScriptHandler(function (sender)
		self:runAction(cc.RemoveSelf:create())
	end)

	local bgSize = cc.size(386, 300)
	local bgLayer = CommonUtils.getCommonPopupBg({bgSize = bgSize, closeCallback = function ()
		self:runAction(cc.RemoveSelf:create())
	end})
	bgLayer:setPosition(cc.p(display.width * 0.5, display.height * 0.5))
	self:addChild(bgLayer)
	-- bgLayer:setBackgroundColor(cc.c4b(0, 255, 128, 128))
	
	-- title
	local titleLabel = display.newLabel(bgSize.width * 0.5, bgSize.height * 0.86,
		{text = __('食用菜谱可以增加疲劳值'), fontSize = 20, color = '#7e6454'})
	bgLayer:addChild(titleLabel)

	local t = {
		{goodId = 180001,name = __('精力充沛剂'),tag = 1},
		{goodId = 180003,name = __('死灰复燃药'),tag = 3}
	}
	local goodIconSize = cc.size(85, 85)
	for i,v in ipairs(t) do
		local goodConfig = CommonUtils.GetConfig('goods', 'goods', v.goodId)
		local num = gameMgr:GetAmountByGoodId(v.goodId) or 0

		local function callBack(sender)
			local num = gameMgr:GetAmountByGoodId(v.goodId)
			if num <= 0 then
				-- uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = v.goodId, type = 1})
				-- uiMgr:AddDialog("common.GainPopup", {goodId = v.goodId})
				uiMgr:ShowInformationTips(__('材料不足'))
			else
				local effectNum = checkint(goodConfig.effectNum)
                local maxVigour = app.restaurantMgr:getCardVigourLimit(self.args.id)
				if checkint(self.vigour) < maxVigour then
					local httpManager = AppFacade.GetInstance():GetManager("HttpManager")
					httpManager:Post("backpack/cardVigourMagicFoodRecover",SIGNALNAMES.Hero_AddVigour_Callback,{ playerCardId = self.args.id,goodsId = v.goodId,num = 1})
				else
					uiMgr:ShowInformationTips(__('该卡牌疲劳已满'))
				end
			end
		end

		local goodIcon = require('common.GoodNode').new({id = v.goodId, showAmount = true,showName = false,amount = num,callBack = callBack})--,showName = false,name = v.name
		local goodIconScale = goodIconSize.width / goodIcon:getContentSize().width
		goodIconScale = 0.7
		goodIcon:setScale(goodIconScale)
		goodIcon:setAnchorPoint(cc.p(0.5, 0.5))
		goodIcon:setPosition(cc.p(bgSize.width * 0.5 - (2 - i) * 100,bgSize.height * 0.5))-- expBg:getPositionY()- expBg:getContentSize().height*0.25
		bgLayer:addChild(goodIcon,1)
		local descLabel = display.newLabel(goodIcon:getPositionX(), goodIcon:getPositionY() - goodIcon:getContentSize().height * goodIconScale * 0.5 - 20 ,
			{text = string.format('+%d', checkint(goodConfig.effectNum)), fontSize = 20, color = '#6c6c6c', ap = cc.p(0.5, 1)})
		bgLayer:addChild(descLabel)
		goodIcon:setTag(v.tag)
		table.insert(self.goodsItem,goodIcon)

		local itemBg = display.newImageView(_res('ui/cards/property/role_main_bg_good.png'), goodIcon:getPositionX(),goodIcon:getPositionY(),
			{ap = cc.p(0.5, 0.5)})
		bgLayer:addChild(itemBg)

	end
	self:refreshUI(self.args)
end

function CardAddVigourView:refreshUI(data)
	if data then
		self.args = data
	end
	self.vigour = checkint(self.args.vigour)

	local t = {
		{goodId = 180001},
		{goodId = 180003}
	}
	for i,v in ipairs(t) do
		if self.goodsItem[i] then
			local num = gameMgr:GetAmountByGoodId(v.goodId)
			self.goodsItem[i]:updataNum( num )
		end
	end
end

return CardAddVigourView
