--[[
飨灵契约详情界面
--]]
local CardContractDetailView = class('CardContractDetailView', function ()
	local node = CLayout:create()
	node.name = 'Game.views.CardContractDetailView'
	node:enableNodeEvents()
	return node
end)

local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

local colorConfig = {'83786a', 'a4654e', '239fb1',  '2c89d8', '7324cc', 'eb6218'}
--[[

--]]
function CardContractDetailView:ctor( ... )
	self.args = unpack({...}) or {}
	-- dump(self.args)
	local size = cc.size(590,550)
	self.viewData = nil
	self:setContentSize(display.size)
	-- self:setBackgroundColor(cc.c4b(100, 100, 100, 255))
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 150))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setAnchorPoint(cc.p(0.5, 1.0))
    eaterLayer:setPosition(cc.p(display.cx, display.height))-- - NAV_BAR_HEIGHT
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer


	local function CreateView()
		local view = CLayout:create()
		view:setPosition(cc.p(0,0))
		view:setAnchorPoint(cc.p(0,0))
		view:setContentSize(display.size)
		self:addChild(view)

		-- view:setBackgroundColor(cc.c4b(100, 100, 100, 100))
		-- local bg = display.newImageView(_res('ui/cards/love/card_bg_contract.png'), 0, 0,
		-- {ap = cc.p(0, 0)})
		-- view:addChild(bg)


		local bgSpine = sp.SkeletonAnimation:create('effects/favorability/qiyue.json', 'effects/favorability/qiyue.atlas', 1)
		bgSpine:update(0)
		bgSpine:setAnimation(0, 'attack', false)--shengxing1 shengji
		view:addChild(bgSpine,5)
		bgSpine:setPosition(cc.p(display.size.width*0.5,display.size.height*0.5))



		--屏蔽触摸层
		-- local cview = display.newLayer(0,0,{color = cc.c4b(0,0,0,0),enable = true,size = bgSize, ap = cc.p(0,0)})
		-- view:addChild(cview)


		-- card_bg_contract_title
		local upImg = display.newImageView(_res('ui/cards/love/card_bg_contract_title.png'), display.size.width*0.5, display.size.height - 170,
		{ap = cc.p(0.5, 0.5)})
		view:addChild(upImg)
		upImg:setOpacity(0)


		--83786a a4654e 239fb1  2c89d8 7324cc eb6218
	    local titleLabel = display.newLabel(display.size.width*0.3,display.size.height - 120,fontWithColor(14,{text = ('初级契约'),fontSize = 40,ap = cc.p(0.5,1),
	    	outline = colorConfig[(self.args.favorabilityLevel or 1)]  or '83786a',outlineSize = 4}))
	    view:addChild(titleLabel,6)
	    titleLabel:setOpacity(0)


		local favorabilityData = CommonUtils.GetConfig('cards', 'favorabilityLevel', checkint(self.args.favorabilityLevel))

		local nowLvExp = (checkint(self.args.favorability) - CommonUtils.GetConfig('cards', 'favorabilityLevel',self.args.favorabilityLevel).totalExp)
		local needLvExp = {}
		if CommonUtils.GetConfig('cards', 'favorabilityLevel',self.args.favorabilityLevel+1) then
			needLvExp = (CommonUtils.GetConfig('cards', 'favorabilityLevel',self.args.favorabilityLevel+1).exp or 999999)
		else
			needLvExp = (CommonUtils.GetConfig('cards', 'favorabilityLevel',self.args.favorabilityLevel).exp or 999999)
		end
		if nowLvExp < 0 then
			nowLvExp = 0
		end


		local loveLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')--
		loveLabel:setAnchorPoint(display.LEFT_TOP)
		loveLabel:setHorizontalAlignment(display.TAR)

		loveLabel:setPosition(cc.p(display.size.width * 0.69 -17,display.size.height - 185))
		loveLabel:setString(nowLvExp..'/'..needLvExp )

		view:addChild(loveLabel,10)
		loveLabel:setOpacity(0)
		-- loveLabel:setScale(2)

	    local tempLabel = display.newLabel(display.size.width * 0.7-25,display.size.height - 150,
	        {text = __('好感度') ,ap = display.LEFT_TOP  , fontSize = 24, color = '#ffffff'})
	    view:addChild(tempLabel)
	    tempLabel:setOpacity(0)

 		local tipsButton = display.newButton(display.size.width * 0.7- 55, display.size.height - 145 , {
            n = _res('ui/common/common_btn_tips'),ap = cc.p(0.5,1)
        })
        view:addChild(tipsButton)
        tipsButton:setOpacity(0)

	    local desLabel = display.newLabel(display.size.width*0.5,display.size.height *0.5 - 30,
	    	fontWithColor(14,{text = ('  ,'),ap = cc.p(0.5,0.5),w = 300,h = 300,
	    		outline = '4c4c4c',outlineSize = 2}))
	    view:addChild(desLabel,6)
	    desLabel:setOpacity(0)

		local lineImg = display.newImageView(_res('ui/common/kitchen_tool_split_line.png'), 
			display.size.width*0.5,display.cy - 120, {ap = cc.p(0.5, 0.5)})
		view:addChild(lineImg,6)
		lineImg:setScaleX(0.58)
		lineImg:setOpacity(0)

	    local unlockStoryLabel = display.newLabel(display.size.width*0.4 - 16,lineImg:getPositionY() - 28,
	    	fontWithColor(6,{text = (' '),ap = cc.p(0,0.5)}))
	    view:addChild(unlockStoryLabel,6)
	    unlockStoryLabel:setOpacity(0)

	    local contractBuffLabel = display.newLabel(display.size.width*0.5,lineImg:getPositionY() - 42,
	    	fontWithColor(6,{text = (' '),ap = cc.p(0.5,1)}))
	    view:addChild(contractBuffLabel,6)
		contractBuffLabel:setOpacity(0)
		
		local nextContractBtn = display.newButton(display.size.width - display.SAFE_L,  12,
			{n = _res('ui/common/common_btn_white_default.png'),ap = cc.p(1,0), scale9 = true, size = cc.size(140,62)})--s = _res('ui/home/lobby/cooking/restaurant_kitchen_btn_start_cook.png')
		view:addChild(nextContractBtn)
		display.commonLabelParams(nextContractBtn,fontWithColor(14,{text = __('下一阶契约'),fontSize  = 20 ,paddingW = 10, safeW = 122}))

		return {
			view 				= view,
			-- bg 					= bg,
			titleLabel 			= titleLabel,
			desLabel 			= desLabel,
			unlockStoryLabel 	= unlockStoryLabel,
			contractBuffLabel 	= contractBuffLabel,
			nextContractBtn 	= nextContractBtn,
			bgSpine 			= bgSpine,
			upImg 				= upImg,
			lineImg				= lineImg,

			loveLabel			= loveLabel,
			tempLabel			= tempLabel,
			tipsButton			= tipsButton,
		}

	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)

end

function CardContractDetailView:AddMarryUI()
	local view = self.viewData.view

	-- 底下粒子
	local particleSpine = sp.SkeletonAnimation:create(
		'effects/marry/qiyue.json',
		'effects/marry/qiyue.atlas',
		1)
  	particleSpine:setAnimation(0, 'idle', true)
  	particleSpine:setTimeScale(0.8)
  	particleSpine:update(0)
  	particleSpine:setToSetupPose()
  	particleSpine:setPosition(cc.p(display.cx, 360))
	view:addChild(particleSpine, 9)
	particleSpine:setOpacity(0)
	self.viewData.particleSpine = particleSpine

	-- 结婚按钮背景
	local marryBtnBG = display.newImageView(_res('ui/cards/marry/card_contract_bg_below.png'), display.cx, 0,
	{ap = cc.p(0.5, 0)})
	view:addChild(marryBtnBG, 10)
	marryBtnBG:setOpacity(0)
	self.viewData.marryBtnBG = marryBtnBG

	-- 结婚按钮
	local marryButton = display.newButton(display.size.width / 2, -5 , {
		   n = _res('ui/cards/marry/card_contract_btn_play'),ap = cc.p(0.5,0)
	})
	display.commonLabelParams(marryButton, {fontSize = 30, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, text = __('签订誓约'), offset = cc.p(0, 30)})
	view:addChild(marryButton, 10)
	marryButton:getLabel():enableOutline(ccc4FromInt('654444'), 2)
	marryButton:setOpacity(0)
	self.viewData.marryButton = marryButton

	-- 消耗
	local marryCostConfig = cardMgr.GetMarryCostConfig()
	local marryCostLabel = display.newLabel(0, 0, 
		{fontSize = 30, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, text = gameMgr:GetAmountByGoodId(marryCostConfig.goodsId) .. '/' .. marryCostConfig.num})
	marryCostLabel:enableOutline(ccc4FromInt('654444'), 2)
	marryButton:addChild(marryCostLabel, 10)
	self.viewData.marryCostLabel = marryCostLabel

	local marryCostIcon = display.newNSprite(_res(CommonUtils.GetGoodsIconPathById(marryCostConfig.goodsId)), 0, 0)
	marryCostIcon:setScale(0.25)
	marryButton:addChild(marryCostIcon, 10)

	display.setNodesToNodeOnCenter(marryButton, {marryCostLabel, marryCostIcon}, {y = 58})

	local dateEffect = display.newImageView(_res('ui/cards/marry/card_contract_label_text_date'), 
	marryButton:getContentSize().width / 2, marryButton:getContentSize().height / 2 + 6, {ap = cc.p(0.5, 0.5)})
	marryButton:addChild(dateEffect)
end

return CardContractDetailView
