--[[
飨灵契约满级界面
--]]
local CardContractCompleteView = class('CardContractCompleteView', function ()
	local node = CLayout:create()
	node.name = 'Game.views.CardContractCompleteView'
	node:enableNodeEvents()
	return node
end)

local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

function CardContractCompleteView:ctor( ... )
	self.args = unpack({...}) or {}
	self:setContentSize(display.size)
	self.viewData = nil
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

		local bg = display.newImageView(_res('ui/cards/marry/card_contract_bg_max'), display.cx, display.cy, {isFull = true})
        view:addChild(bg)

    	-- back button
    	local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back")})
    	backBtn:setPosition(cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.height - 53))
		view:addChild(backBtn, 5)
		local particleSpine = display.newCacheSpine(SpineCacheName.COMMON, 'effects/marry/fly')
    	-- particleSpine:setTimeScale(2.0 / 3.0)
    	particleSpine:setPosition(cc.p(display.width * 0.36, 0))
		view:addChild(particleSpine, 6)
		particleSpine:setAnimation(0, 'idle1', true)
		particleSpine:update(0)
		particleSpine:setToSetupPose()
		particleSpine:setOpacity(0)

		-- 法阵
		local matrixImg = display.newImageView(_res('ui/cards/marry/anime_fazhen.png'), 
			display.width * 0.36, display.cy - 50, {ap = cc.p(0.51, 0.47)})
		view:addChild(matrixImg)
		matrixImg:setOpacity(0)

		-- 桌子
		local tableImg = display.newImageView(_res('ui/cards/marry/card_contract_bg_below.png'), display.width * 0.36, 0, {ap = cc.p(0.5, 0)})
		view:addChild(tableImg, 10)
		tableImg:setCascadeOpacityEnabled(true)
		tableImg:setOpacity(0)

		-- 契约书
		local contractBook = display.newImageView(_res('ui/cards/marry/card_contract_btn_play'), 
			tableImg:getContentSize().width / 2, -20, {ap = cc.p(0.5, 0)})
		tableImg:addChild(contractBook)
		contractBook:setCascadeOpacityEnabled(true)

		-- 时间光效
		local dateEffect = display.newImageView(_res('ui/cards/marry/card_contract_label_text_date.png'), 
			contractBook:getContentSize().width / 2, contractBook:getContentSize().height / 2 + 10, {ap = cc.p(0.5, 0.5)})
		contractBook:addChild(dateEffect)
		
		local marryTime = os.time()
		if self.args.marryTime then
			marryTime = self.args.marryTime
		end
		local marryTimeStr = os.date('%Y.%m.%d', marryTime)
		local dateLabel = display.newLabel(contractBook:getContentSize().width / 2, contractBook:getContentSize().height / 2 - 10, 
			{fontSize = 24, color = '#a37652', text = marryTimeStr,ap = cc.p(0.5, 0.5)})
		contractBook:addChild(dateLabel)

		local tipsLabel = display.newLabel(contractBook:getContentSize().width / 2, contractBook:getContentSize().height / 2 + 15,
			{fontSize = 24, color = '#a37652',  w = 210 , hAlign = display.TAC ,   text = __('誓约成立日'),ap = cc.p(0.5, 0)})
		contractBook:addChild(tipsLabel)
		if display.getLabelContentSize(tipsLabel).height > 55  then
			display.commonLabelParams(tipsLabel , {fontSize = 20, color = '#a37652',  w = 250 , reqW = 220  , hAlign = display.TAC ,   text = __('誓约成立日'),ap = cc.p(0.5, 0)})
		end

		--卡牌立绘
		local heroImg = require("common.CardSkinDrawNode").new({cardId = self.args.cardId, coordinateType = COORDINATE_TYPE_CAPSULE})
		display.commonUIParams(heroImg, {po = cc.p(display.width * 0.36,0), ap = cc.p(0.3,0)})
		view:addChild(heroImg, 5)
		heroImg:setOpacity(0)

        local desrDetailBG = display.newImageView(_res('ui/cards/marry/card_contract_label_text_bg'), display.width * 0.85, display.cy, {scale9 = true})
		view:addChild(desrDetailBG)
		desrDetailBG:setOpacity(0)

		local waveImg = display.newImageView(_res('ui/cards/marry/card_contract_result_bg'), 
			desrDetailBG:getContentSize().width / 2 + 16, desrDetailBG:getContentSize().height - 108)
		desrDetailBG:addChild(waveImg)
		waveImg:setOpacity(0)

		local desrLabel = display.newLabel(desrDetailBG:getContentSize().width / 2, desrDetailBG:getContentSize().height - 108, 
			{fontSize = 40, ttf = true, hAlign= display.TAC ,  font = _res(TTF_GAME_FONT), w = 350, color = '#ffffff', text = __('一生的约定'),ap = cc.p(0.5, 0.5)})
		desrLabel:enableOutline(ccc4FromInt('6a3a16'), 4)
		desrDetailBG:addChild(desrLabel)
		desrLabel:setOpacity(0)

		local lineImg = display.newImageView(_res('ui/cards/marry/card_contract_split_line_2'), 
			desrDetailBG:getContentSize().width / 2,desrDetailBG:getContentSize().height - 170, {ap = cc.p(0.5, 0.5)})
		lineImg:setFlippedY(true)
		-- lineImg:setScale(0.58)
		desrDetailBG:addChild(lineImg, 10)
		lineImg:setOpacity(0)

		local lineImgAlter = display.newImageView(_res('ui/cards/marry/card_contract_split_line_2'), 
			desrDetailBG:getContentSize().width / 2,desrDetailBG:getContentSize().height - 400, {ap = cc.p(0.5, 0.5)})
		-- lineImgAlter:setScale(0.58)
		desrDetailBG:addChild(lineImgAlter, 10)
		lineImgAlter:setOpacity(0)

		local memoryButton = display.newButton(desrDetailBG:getPositionX(), desrDetailBG:getPositionY() - 230 , {
            n = _res('ui/common/common_btn_orange'),ap = cc.p(0.5,0.5) ,scale9 = true
		})
		display.commonLabelParams(memoryButton, fontWithColor(14, {text = __('回忆剧情'), offset = cc.p(0, 0) , paddingW = 20 }))
        view:addChild(memoryButton)
		memoryButton:setOpacity(0)


		return {
			view 				= view,
			bg 					= bg,
			backBtn				= backBtn,
			memoryButton		= memoryButton,
			desrDetailBG		= desrDetailBG,
			particleSpine		= particleSpine,
			lineImg				= lineImg,
			lineImgAlter		= lineImgAlter,
			waveImg				= waveImg,
			desrLabel			= desrLabel,
			matrixImg			= matrixImg,
			tableImg			= tableImg,
			contractBook		= contractBook,
			heroImg				= heroImg,
		}

	end

	xTry(function ( )
		self.viewData = CreateView( )

		
	end, __G__TRACKBACK__)

end

function CardContractCompleteView:AddBuffDesr(str, unlockStr)
	local desrDetailBG = self.viewData.desrDetailBG
	local totalPropNum = table.nums(str) + table.nums(unlockStr)
	local cutlines = {}
	local cellBGs = {}
	local buffLabels = {}
	local desrLabels = {}
	if 6 < totalPropNum then
		desrDetailBG:setContentSize(cc.size(379, 591+(totalPropNum-6)*41))
		local size = desrDetailBG:getContentSize().height
		self.viewData.waveImg:setPositionY(size - 108)
		self.viewData.desrLabel:setPositionY(size - 108)
		self.viewData.lineImg:setPositionY(size - 170)
		self.viewData.memoryButton:setPositionY(desrDetailBG:getPositionY() - 230 - (totalPropNum-6)*20)
	end
	for i = 1, totalPropNum do
		local cutline = display.newImageView(_res('ui/cards/marry/card_contract_text_line'),
				desrDetailBG:getContentSize().width / 2, desrDetailBG:getContentSize().height - 154 - i * 41)
		desrDetailBG:addChild(cutline)
		cutline:setOpacity(0)
		table.insert(cutlines, cutline)

		if 1 == i % 2 then
			local cellBG = display.newImageView(_res('ui/cards/marry/card_contract_text_label'),
					desrDetailBG:getContentSize().width / 2, desrDetailBG:getContentSize().height - 174 - i * 41)
			desrDetailBG:addChild(cellBG)
			cellBG:setOpacity(0)
			table.insert(cellBGs, cellBG)
		end

		if 1 == i or (table.nums(str) + 1) == i then
			local desrLabel = display.newLabel(desrDetailBG:getContentSize().width / 2 - 140, desrDetailBG:getContentSize().height - 174 - i * 41,
				{reqW = 100 , fontSize = 22, color = '#fff1d7', text = 1 == i and __('契约效果') or __('解锁内容'),ap = cc.p(0, 0.5)})
			desrDetailBG:addChild(desrLabel)
			desrLabel:setOpacity(0)
			table.insert(desrLabels, desrLabel)
		end
		local buffLabel = display.newLabel(desrDetailBG:getContentSize().width / 2 - 16, desrDetailBG:getContentSize().height - 174 - i * 41,
			{fontSize = 22, color = '#fff1d7', text = i > table.nums(str) and unlockStr[i - table.nums(str)] or str[i],ap = cc.p(0, 0.5) , reqW = 173})
		desrDetailBG:addChild(buffLabel)
		buffLabel:setOpacity(0)
		table.insert(buffLabels, buffLabel)
	end

	local cutline = display.newImageView(_res('ui/cards/marry/card_contract_text_line'), 
			desrDetailBG:getContentSize().width / 2, desrDetailBG:getContentSize().height - 154 - (totalPropNum + 1) * 41)
	desrDetailBG:addChild(cutline)
	cutline:setOpacity(0)
	table.insert(cutlines, cutline)

	local lineImgAlter = self.viewData.lineImgAlter
	lineImgAlter:setPositionY(cutline:getPositionY() - 30)
	local lineImg = self.viewData.lineImg
	local topPosY = lineImg:getPositionY()
	local bottomPosY = lineImgAlter:getPositionY()
	lineImg:setPositionY((topPosY + bottomPosY) / 2 + 30)
	lineImgAlter:setPositionY((topPosY + bottomPosY) / 2 - 30)

	local fadeTime = 0.6
	local matrixImg = self.viewData.matrixImg
	matrixImg:runAction(cc.FadeIn:create(fadeTime))
	matrixImg:runAction(cc.RepeatForever:create(cc.RotateBy:create(10, 90)))

	local tableImg = self.viewData.tableImg
	tableImg:setPositionY(tableImg:getPositionY() - 15)
	tableImg:runAction(cc.Sequence:create(
		cc.DelayTime:create(fadeTime),
		cc.Spawn:create(
			cc.MoveBy:create(fadeTime, cc.p(0, 15)),
			cc.FadeIn:create(fadeTime)
		)
	))

	local particleSpine = self.viewData.particleSpine
	particleSpine:runAction(cc.Sequence:create(
		cc.DelayTime:create(fadeTime + 0.3),
		cc.FadeIn:create(fadeTime)
	))

	local heroImg = self.viewData.heroImg
	heroImg:runAction(cc.Sequence:create(
		cc.DelayTime:create(fadeTime),
		cc.Spawn:create(
			-- cc.MoveBy:create(fadeTime, cc.p(0, 15)),
			cc.FadeIn:create(fadeTime),
			cc.Sequence:create(
				cc.DelayTime:create(0.4),
				cc.CallFunc:create(function ()
					local fadeTime = 1
					local openTime = 0.6
					local desrFadeTime = 1
					local waveImg = self.viewData.waveImg
					local desrLabel = self.viewData.desrLabel
					desrDetailBG:runAction(cc.Sequence:create(
						cc.FadeIn:create(fadeTime),
						cc.CallFunc:create(function ()
							self:ShowDesrAction(cutlines, cellBGs, buffLabels, desrLabels)
						end)
					))
					waveImg:runAction(cc.Sequence:create(
						cc.FadeIn:create(fadeTime)
					))
					desrLabel:setScale(1.4)
					desrLabel:runAction(cc.Sequence:create(
						cc.DelayTime:create(fadeTime),
						cc.Spawn:create(
							cc.FadeIn:create(0.6),
							cc.Sequence:create(
								cc.DelayTime:create(0.2),
								cc.ScaleTo:create(0.4, 1, 1)
							)
						)
					))
					lineImg:runAction(cc.Sequence:create(
						cc.FadeIn:create(fadeTime),
						cc.EaseBackIn:create(
							cc.MoveBy:create(openTime, cc.p(0, topPosY - ((topPosY + bottomPosY) / 2 + 30)))
						)
					))
					lineImgAlter:runAction(cc.Sequence:create(
						cc.FadeIn:create(fadeTime),
						cc.EaseBackIn:create(
							cc.MoveBy:create(openTime, cc.p(0, bottomPosY - ((topPosY + bottomPosY) / 2 - 30)))
						)
					))
				end)
			)
		)
	))
	heroImg:runAction(cc.RepeatForever:create(cc.Sequence:create(
         cc.MoveBy:create(2, cc.p(0, 15)),
         cc.MoveBy:create(2, cc.p(0, -15))
	)))
		
end

function CardContractCompleteView:ShowDesrAction(cutlines, cellBGs, buffLabels, desrLabels)
	local openTime = 0.4
	local fadeTime = 0.2
	local labelFadeInTime = 0.2
	local btnFadeInTime = 0.2
	local memoryButton = self.viewData.memoryButton

	for k, v in pairs(cutlines) do
		v:runAction(cc.Sequence:create(
			cc.DelayTime:create(openTime),
			cc.FadeIn:create(fadeTime)
		))
	end
	for k, v in pairs(cellBGs) do
		v:runAction(cc.Sequence:create(
			cc.DelayTime:create(openTime),
			cc.FadeIn:create(fadeTime)
		))
	end
	for i = 1, table.nums(buffLabels) do
		buffLabels[i]:runAction(cc.Sequence:create(
			cc.DelayTime:create(openTime + fadeTime + (i - 1) * labelFadeInTime),
			cc.FadeIn:create(fadeTime)
		))
	end
	for i = 1, table.nums(desrLabels) do
		desrLabels[i]:runAction(cc.Sequence:create(
			cc.DelayTime:create(openTime + fadeTime + (i - 1) * labelFadeInTime * (table.nums(buffLabels)-3)),
			cc.FadeIn:create(fadeTime)
		))
	end
	memoryButton:setEnabled(false)
	memoryButton:runAction(cc.Sequence:create(
		cc.DelayTime:create(openTime + fadeTime + table.nums(buffLabels) * labelFadeInTime),
		cc.FadeIn:create(btnFadeInTime),
		cc.CallFunc:create(function ()
			memoryButton:setEnabled(true)
		end)
	))
end

return CardContractCompleteView
