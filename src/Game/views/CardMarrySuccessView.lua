--[[
飨灵结婚界面
--]]
local GameScene = require( 'Frame.GameScene' )
local CardMarrySuccessView = class('CardMarrySuccessView', GameScene)

local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

function CardMarrySuccessView:ctor( ... )
	self.args = unpack({...}) or {}
	self.viewData = nil
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 150))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setAnchorPoint(cc.p(0.5, 1.0))
    eaterLayer:setPosition(cc.p(display.cx, display.height))-- - NAV_BAR_HEIGHT
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer


	local function CreateView()
		local view = CLayout:create(display.size)
        display.commonUIParams(view, {po = display.center})
        self:addChild(view)

        local bg = display.newImageView(_res('ui/cards/marry/card_contract_bg_memory'), display.cx, display.cy, {isFull = true})
        view:addChild(bg)

    	-- back button
    	local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back")})
    	backBtn:setPosition(cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.height - 53))
    	view:addChild(backBtn, 5)

		--卡牌立绘
		-- local secData = {cardId = self.args.cardId, coordinateType = COORDINATE_TYPE_CAPSULE}
		-- local heroImg = require( "common.CardSkinDrawNode" ).new(secData)
		-- display.commonUIParams(heroImg, {po = cc.p(display.SAFE_L,0)})
		-- view:addChild(heroImg,2)

        local desrDetailBG = display.newImageView(_res('ui/cards/marry/card_contract_label_text_bg'), display.width * 0.85, display.cy, {scale9 = true})
		view:addChild(desrDetailBG)
		desrDetailBG:setOpacity(0)

		local waveImg = display.newImageView(_res('ui/cards/marry/card_contract_result_bg'), 
			desrDetailBG:getContentSize().width / 2 + 16, desrDetailBG:getContentSize().height - 108)
		desrDetailBG:addChild(waveImg)
		waveImg:setOpacity(0)

		local desrLabel = display.newLabel(desrDetailBG:getContentSize().width / 2, desrDetailBG:getContentSize().height - 90,
			{hAlign = cc.TEXT_ALIGNMENT_CENTER, fontSize = 30, ttf = true, font = _res(TTF_GAME_FONT), color = '#ffffff', w = 330 ,  text = __('誓约成立!\n飨灵获得了新的能力'),ap = cc.p(0.5, 0.5)})
		desrLabel:enableOutline(ccc4FromInt('6a3a16'), 4)
		desrDetailBG:addChild(desrLabel)
		desrLabel:setOpacity(0)

		local lineImg = display.newImageView(_res('ui/cards/marry/card_contract_split_line_2'), 
			desrDetailBG:getContentSize().width / 2,desrDetailBG:getContentSize().height - 170, {ap = cc.p(0.5, 0.5)})
		lineImg:setFlippedY(true)
		desrDetailBG:addChild(lineImg)
		lineImg:setOpacity(0)

		local lineImgAlter = display.newImageView(_res('ui/cards/marry/card_contract_split_line_2'), 
			desrDetailBG:getContentSize().width / 2,desrDetailBG:getContentSize().height - 400, {ap = cc.p(0.5, 0.5)})
		desrDetailBG:addChild(lineImgAlter)
		lineImgAlter:setOpacity(0)

		local alterNicknameButton = display.newButton(desrDetailBG:getPositionX(), desrDetailBG:getPositionY() - 230 , {
            n = _res('ui/common/common_btn_orange'),ap = cc.p(0.5,0.5) , scale9 = true
		})
		display.commonLabelParams(alterNicknameButton, fontWithColor(14, {text = __('修改昵称'), offset = cc.p(0, 0), paddingW = 20}))
        view:addChild(alterNicknameButton)
		alterNicknameButton:setOpacity(0)

		return {
			view 					= view,
			bg 						= bg,
			backBtn					= backBtn,
			alterNicknameButton		= alterNicknameButton,
			desrDetailBG			= desrDetailBG,
			lineImg					= lineImg,
			lineImgAlter			= lineImgAlter,
			waveImg					= waveImg,
			-- heroImg					= heroImg,
			desrLabel				= desrLabel,
			bgSize					= cc.size(display.width, display.height),
		}

	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)

end

function CardMarrySuccessView:AddBuffDesr(str, unlockStr)
	local desrDetailBG = self.viewData.desrDetailBG
	local totalPropNum = table.nums(str) + table.nums(unlockStr)
	local cutlines = {}
	local cellBGs = {}
	local buffLabels = {}
	if 6 < totalPropNum   then
		desrDetailBG:setContentSize(cc.size(379, 591+(totalPropNum-6)*41))
		local size = desrDetailBG:getContentSize().height
		self.viewData.waveImg:setPositionY(size - 108)
		self.viewData.desrLabel:setPositionY(size - 108)
		self.viewData.lineImg:setPositionY(size - 170)
		self.viewData.alterNicknameButton:setPositionY(desrDetailBG:getPositionY() - 230 - (totalPropNum-6)*20)
	end
	if  CardUtils.IsLinkCard(self.args.cardId) then
		self.viewData.alterNicknameButton:setVisible(false)
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

		local buffLabel = display.newLabel(desrDetailBG:getContentSize().width / 2, desrDetailBG:getContentSize().height - 174 - i * 41, 
			{fontSize = 22, color = '#fff1d7', text = i > table.nums(str) and unlockStr[i - table.nums(str)] or str[i],ap = cc.p(0.5, 0.5)})
		desrDetailBG:addChild(buffLabel)
		buffLabel:setOpacity(0)
		table.insert(buffLabels, buffLabel)
	end
	local cutline = display.newImageView(_res('ui/cards/marry/card_contract_text_line'), 
			desrDetailBG:getContentSize().width / 2, desrDetailBG:getContentSize().height - 154 - (totalPropNum + 1) * 41)
	desrDetailBG:addChild(cutline)
	cutline:setOpacity(0)
	table.insert(cutlines, cutline)

	local waveImg = self.viewData.waveImg
	local desrLabel = self.viewData.desrLabel

	-- local heroImg = self.viewData.heroImg
	-- heroImg:setOpacity(0)
	-- heroImg:setScale(1.2)
	-- -- heroImg:runAction(cc.FadeIn:create(2))
	-- heroImg:runAction(cc.ScaleTo:create(0.2, 1))

	local viewdata = self.viewData
	local secData  = {cardId = self.args.cardId, coordinateType = COORDINATE_TYPE_CAPSULE}
	
	local cardDrawNodeB = require( "common.CardSkinDrawNode" ).new(secData)
	cardDrawNodeB:setScale(1.2)
	cardDrawNodeB:setAnchorPoint(cc.p(0.26, 0.5))
	cardDrawNodeB:setPosition(cc.p(viewdata.bgSize.width * 0.26, viewdata.bgSize.height / 2))
	cardDrawNodeB:setColor(cc.c4b(0,0,0,0))
	self.viewData.view:addChild(cardDrawNodeB)
	cardDrawNodeB:setOpacity(0)

	local cardDrawNode = require( "common.CardSkinDrawNode" ).new(secData)
	cardDrawNode:setScale(1.2)
	cardDrawNode:setAnchorPoint(cc.p(0.26, 0.5))
	cardDrawNode:setTag(1001)
	cardDrawNode:setPosition(cc.p(viewdata.bgSize.width * 0.26, viewdata.bgSize.height / 2))

	local designSize = cc.size(1334, 750)
    local winSize = display.size
    local deltaHeight = (winSize.height - designSize.height) * 0.5

    local particleSpine = display.newCacheSpine(SpineCacheName.COMMON, 'effects/marry/fly')
    -- particleSpine:setTimeScale(2.0 / 3.0)
    particleSpine:setPosition(cc.p(display.SAFE_L + viewdata.bgSize.width * 0.26,deltaHeight))
    self.viewData.view:addChild(particleSpine, 1)
    particleSpine:setAnimation(0, 'idle2', true)
    particleSpine:update(0)
    particleSpine:setToSetupPose()
	particleSpine:setVisible(false)
		
	self:runAction(cc.Sequence:create(
		cc.TargetedAction:create(cardDrawNodeB, cc.FadeTo:create(1.5, 150)),
		cc.CallFunc:create(function ()
			cardDrawNodeB:removeFromParent()
			self.viewData.view:addChild(cardDrawNode)
		end),
		cc.CallFunc:create(function ()
			PlayAudioClip(AUDIOS.UI.ui_vow_settlement.id)
			local cardShadowF = require('common.CardSkinDrawNode').new(secData)
			cardShadowF:setScale(1.2)
			cardShadowF:setAnchorPoint(cc.p(0.26, 0.5))
			cardShadowF:setTag(1002)
			cardShadowF:setPosition(cc.p(viewdata.bgSize.width * 0.26, viewdata.bgSize.height / 2))

			local cardShadowS = require('common.CardSkinDrawNode').new(secData)
			cardShadowS:setScale(1.2)
			cardShadowS:setAnchorPoint(cc.p(0.26, 0.5))
			cardShadowS:setTag(1003)
			cardShadowS:setPosition(cc.p(viewdata.bgSize.width * 0.26, viewdata.bgSize.height / 2))
			viewdata.view:addChild(cardShadowS)
			viewdata.view:addChild(cardShadowF)
			cardShadowF:runAction(
				cc.Spawn:create(
					cc.ScaleTo:create(0.3, 2.1),
					cc.FadeOut:create(0.3)
				)
			)
			cardShadowS:runAction(
				cc.Sequence:create(
					cc.DelayTime:create(0.1),
					cc.Spawn:create(
						cc.ScaleTo:create(0.3, 1.8),
						cc.FadeOut:create(0.3)
					)
				)
			)
		end),
		cc.TargetedAction:create(cardDrawNode, cc.ScaleTo:create(0.2, 1)),
		cc.CallFunc:create(function ()
			particleSpine:setOpacity(0)
			particleSpine:runAction(cc.Sequence:create(
				cc.Show:create(),
				cc.FadeIn:create(0.5)
			))

			local lineImgAlter = self.viewData.lineImgAlter
			lineImgAlter:setPositionY(cutline:getPositionY() - 30)
			local lineImg = self.viewData.lineImg
			local topPosY = lineImg:getPositionY()
			local bottomPosY = lineImgAlter:getPositionY()
			lineImg:setPositionY((topPosY + bottomPosY) / 2 + 30)
			lineImgAlter:setPositionY((topPosY + bottomPosY) / 2 - 30)

			local fadeTime = 1
			local openTime = 0.6
			local desrFadeTime = 1
			desrDetailBG:runAction(cc.Sequence:create(
				cc.FadeIn:create(fadeTime),
				cc.CallFunc:create(function ()
					self:ShowDesrAction(cutlines, cellBGs, buffLabels)
				end)
			))
			waveImg:runAction(cc.Sequence:create(
				cc.FadeIn:create(fadeTime)
			))
			desrLabel:setScale(1.7)
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
	))
end

function CardMarrySuccessView:ShowDesrAction(cutlines, cellBGs, buffLabels)
	local openTime = 0.4
	local fadeTime = 0.2
	local labelFadeInTime = 0.2
	local btnFadeInTime = 0.2
	local alterNicknameButton = self.viewData.alterNicknameButton

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
	alterNicknameButton:setEnabled(false)
	alterNicknameButton:runAction(cc.Sequence:create(
		cc.DelayTime:create(openTime + fadeTime + table.nums(buffLabels) * labelFadeInTime),
		cc.FadeIn:create(btnFadeInTime),
		cc.CallFunc:create(function ()
			alterNicknameButton:setEnabled(true)
		end)
	))
end

return CardMarrySuccessView
