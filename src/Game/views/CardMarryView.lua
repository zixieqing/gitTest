--[[
飨灵结婚界面
--]]
local GameScene = require( 'Frame.GameScene' )
local CardSkinDrawNode = require('common.CardSkinDrawNode')
local CardMarryView = class('CardMarryView', GameScene)

local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

function CardMarryView:ctor( ... )
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
        view:addChild(bg, -1)

    	-- back button
    	local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back")})
    	backBtn:setPosition(cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.height - 53))
		view:addChild(backBtn, 5)
		backBtn:setVisible(false)

		local fazhenSpine = sp.SkeletonAnimation:create(
    		  'effects/marry/fazhen.json',
    		  'effects/marry/fazhen.atlas',
    		  1)
		fazhenSpine:setPosition(cc.p(display.width * 0.7, display.cy))
		fazhenSpine:setVisible(false)
		view:addChild(fazhenSpine, 7)

		-- local halo = display.newImageView(_res('ui/cards/marry/card_contract_btn_tap'), display.width * 0.7, display.cy - 26)
		-- view:addChild(halo)

		local touchGuideLabel = display.newLabel(display.width * 0.7, display.cy + 10, 
			{fontSize = 32, color = '#ffffff', text = __('长按\n签订誓约'),ap = cc.p(0.5, 0.5), hAlign = cc.TEXT_ALIGNMENT_CENTER})
		view:addChild(touchGuideLabel, 12)
		touchGuideLabel:setOpacity(0)

		-- touch 节点
		local touchNode = CLayout:create(cc.size(250, 250))
        -- touchNode:setBackgroundColor(cc.r4b())
        display.commonUIParams(touchNode, {ap = cc.p(0.5, 0.5), po = cc.p(display.width * 0.7, display.cy)})
    	-- touchNode:setTouchEnabled(true)
		view:addChild(touchNode, 10)

		--卡牌立绘-    	
		local mainCardNode = CardSkinDrawNode.new({coordinateType = COORDINATE_TYPE_CAPSULE, notRefresh = true})
		display.commonUIParams(mainCardNode, {ap = cc.p(0.26, 0.5), po = cc.p(display.width * 0.26, display.height / 2)})
    	view:addChild(mainCardNode,2)
		mainCardNode:setOpacity(0)
		if mainCardNode.RefreshAvatar then
			mainCardNode:RefreshAvatar({skinId = gameMgr:GetCardDataByCardId(self.args.cardId).defaultSkinId})
		end

		local dialogueSize = cc.size(628, 207)
		local dialogueLayer = display.newLayer(display.width * 0.26, 200, {size = dialogueSize, ap = cc.p(0.5, 0.5)})
		view:addChild(dialogueLayer, 6)
		dialogueLayer:setCascadeOpacityEnabled(true)
		dialogueLayer:setVisible(false)

		local dialogueBG = display.newImageView(_res('ui/cards/marry/card_contract_dialogue_bg'), dialogueSize.width / 2, dialogueSize.height, {ap = cc.p(0.5, 1)})
		dialogueLayer:addChild(dialogueBG)

        local descrContainer = CListView:create(cc.size(450, 220))
        descrContainer:setPosition(cc.p(dialogueSize.width / 2, dialogueSize.height - 54))
        descrContainer:setDirection(eScrollViewDirectionVertical)
		descrContainer:setAnchorPoint(cc.p(0.5, 1))
		dialogueLayer:addChild(descrContainer, 10)
		descrContainer:setVisible(false)

        local descrLabel = display.newLabel(0, 0, {hAlign = display.TAL, w = 450,text = '', fontSize = 26, color = '#5d2626'})
		local descrLabelLayout  = display.newLayer(0,0,{})
		descrLabelLayout:addChild(descrLabel)
		descrContainer:insertNodeAtLast(descrLabelLayout)
		descrContainer:reloadData()
		
		local dialogLabel = display.newLabel(98, 142, 
			{fontSize = 26, color = '#5d2626', text = '',ap = cc.p(0, 1), w = 450})
		dialogueLayer:addChild(dialogLabel)

		return {
			view 				= view,
			bg 					= bg,
			backBtn				= backBtn,
			touchNode			= touchNode,
			fazhenSpine			= fazhenSpine,
			mainCardNode		= mainCardNode,
			touchGuideLabel		= touchGuideLabel,
			dialogueLayer		= dialogueLayer,
			dialogueBG			= dialogueBG,
			descrContainer		= descrContainer,
			descrLabel			= descrLabel,
			descrLabelLayout	= descrLabelLayout,
			dialogLabel			= dialogLabel,
		}

	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)

end



return CardMarryView
