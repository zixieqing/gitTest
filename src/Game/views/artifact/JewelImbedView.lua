--[[
	宝石镶嵌UI
--]]
local GameScene = require( "Frame.GameScene" )

local JewelImbedView = class('JewelImbedView', GameScene)

local RES_DICT = {
	LISTBG 			= 'ui/common/common_bg_goods.png',

	Bg_unlock		= 'ui/artifact/core_lock_bg',
	Bg_unlockTablet	= 'ui/artifact/core_lock_bg_tips',
    Bg_TITLE 		= "ui/common/common_title_5.png",

    Bg_describe 	= "ui/artifact/core_put_bg_info.png",
    Bg_property 	= "ui/artifact/core_put_bg_name.png",
    Bg_target 	    = "ui/artifact/card_weapon_gift_slot_L_1.png",
    Bg_mouse 	    = "ui/artifact/core_ico_type_1_active.png",
	
	Btn_Normal 		= "ui/common/common_btn_orange.png",
	Btn_Pressed 	= "ui/common/common_btn_orange.png",
	Btn_UnEnable    = 'ui/common/common_btn_orange_disable.png',

    Bg_skill_unselected = "ui/common/common_bg_list_3.png",
    Bg_skill_unsed 		= "ui/artifact/core_put_bg_list_unsed.png",
	Bg_skill_selected 	= "ui/artifact/core_put_bg_list_selected.png",

    CORE_BG_TITLE_UNACTIVE          = _res('ui/artifact/core_bg_title_unactive.png'),
    CORE_PUT_BG_ACTIVE_1            = _res('ui/artifact/core_put_bg_active_1.png'),
    CORE_PUT_BG_ACTIVE_2            = _res('ui/artifact/core_put_bg_active_2.png'),
    CORE_PUT_BG_ICON                = _res('ui/artifact/core_put_bg_icon.png'),
    CORE_PUT_BG_UNACTIVE_1          = _res('ui/artifact/core_put_bg_unactive_1.png'),
    CORE_PUT_BG_UNACTIVE_2          = _res('ui/artifact/core_put_bg_unactive_2.png'),
}

function JewelImbedView:ctor( ... )
    --创建页面
	local view = require("common.TitlePanelBg").new({ title = __('镶嵌塔可'), type = 13})
	display.commonUIParams(view, {ap = display.CENTER, po = cc.p(display.cx, display.cy)})
	display.commonUIParams(view.viewData.view, {ap = display.CENTER, po = cc.p(display.cx, display.cy)})
	display.commonUIParams(view.viewData.tempLayer, {ap = display.CENTER, po = cc.p(display.cx, display.cy)})
	self:addChild(view)
	view.viewData.bview:setBackgroundColor(cc.c4b(0,0,0,0))
	view.cb = function()
        PlayAudioByClickClose()
        AppFacade.GetInstance():UnRegsitMediator("artifact.JewelImbedMediator")
	end
	local function CreateTaskView( ... )
		local size = cc.size(1080,630)
		local cview = CLayout:create(size)

		-- 未解锁
		local lockSize = cc.size(450, 508)
		local lockBg = CLayout:create(lockSize)
	    display.commonUIParams(lockBg, {ap = cc.p(0,0), po = cc.p(size.width - 500, 22)})
		cview:addChild(lockBg)
		lockBg:setVisible(false)

		local unlockCostBg = display.newImageView(_res(RES_DICT.Bg_unlock), lockSize.width / 2, lockSize.height / 2)
		lockBg:addChild(unlockCostBg)

		local unlockTabletBg = display.newImageView(_res(RES_DICT.Bg_unlockTablet), lockSize.width / 2 + 10, 410)
		lockBg:addChild(unlockTabletBg)
		local unlockCostLabel = display.newLabel(185, 430, fontWithColor(5, {text = __("需要消耗以下材料才能解锁该塔可节点"), w = 300 , ap = display.CENTER_TOP ,  fontSize = 20 }))

		lockBg:addChild(unlockCostLabel)

		local titleBg = display.newButton( lockSize.width / 2, 310, { scale9 = true ,  ap = display.CENTER_TOP , n = _res(RES_DICT.Bg_TITLE) , enable = false})
		display.commonLabelParams(titleBg , fontWithColor(5, {text = __("解锁材料") ,paddingW = 30 }) )
		lockBg:addChild(titleBg)

		local goodsNode = require('common.GoodNode').new({id = 160001, callBack = function (  )
			
		end})
		display.commonUIParams(goodsNode, {po = cc.p(lockSize.width / 2, 220)})
		goodsNode:setScale(0.82)
		lockBg:addChild(goodsNode)

		local ownLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', 'xx')
		display.commonUIParams(ownLabel, {ap = display.RIGHT_CENTER, po = cc.p(lockSize.width / 2 - 6, 155)})
		lockBg:addChild(ownLabel)

		local virguleLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '/')
		display.commonUIParams(virguleLabel, {po = cc.p(lockSize.width / 2, 155)})
		lockBg:addChild(virguleLabel)

		local goodsCountLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', 'xx')
		display.commonUIParams(goodsCountLabel, {ap = display.LEFT_CENTER, po = cc.p(lockSize.width / 2 + 6, 155)})
		lockBg:addChild(goodsCountLabel)

		local unlockBtn = display.newButton(lockSize.width / 2,35, {ap = cc.p(0.5,0),n = _res(RES_DICT.Btn_Normal),scale9 = true ,  d = _res(RES_DICT.Btn_UnEnable)})
		display.commonLabelParams(unlockBtn,fontWithColor(14,{text = __('解锁' ) , paddingW = 10}))
		lockBg:addChild(unlockBtn)

		local requireLabel = display.newLabel(lockSize.width / 2, 20, fontWithColor(15, {text = __("需前置节点满级"),w = 450 , hAlign = display.TAC } ))
		lockBg:addChild(requireLabel)

		--滑动层背景图 
		local backpackSize = cc.size(450, 554)
		local backpackView = CLayout:create(backpackSize)
	    display.commonUIParams(backpackView, {ap = cc.p(0,0), po = cc.p(size.width - 500, 22)})
		cview:addChild(backpackView)

		local listSize = cc.size(450, 554)
		local ListBg = display.newImageView(_res(RES_DICT.LISTBG), 0, 0, {scale9 = true, size = listSize,ap = cc.p(0, 0)})
		backpackView:addChild(ListBg)
		--添加列表功能
		local taskListSize = cc.size(listSize.width - 2, listSize.height - 4)
		local taskListCellSize = cc.size(taskListSize.width/4 , 114)

		local gridView = CGridView:create(taskListSize)
		gridView:setSizeOfCell(taskListCellSize)
		gridView:setColumns(4)
		gridView:setAutoRelocate(true)
		backpackView:addChild(gridView,1)
		gridView:setAnchorPoint(cc.p(0, 0))
		gridView:setPosition(cc.p(1, 2))

		-- 全空状态
    	local kongBg = CLayout:create(listSize)
	    display.commonUIParams(kongBg, {ap = cc.p(0,0), po = cc.p(size.width - 500, 22)})
		cview:addChild(kongBg,9)
		kongBg:setVisible(false)
		
		local unlockTabletBg = display.newImageView(_res(RES_DICT.Bg_unlockTablet), listSize.width / 2 , listSize.height / 2)
		kongBg:addChild(unlockTabletBg)

		local unlockCostLabel = display.newLabel(170, listSize.height / 2 - 20, fontWithColor(5, {text = __("现在还没有塔可，快去塔可屋抓几只吧！"), w = 250}))
		kongBg:addChild(unlockCostLabel)

		-- 塔可属性
        local Bg_describe = display.newImageView(_res(RES_DICT.Bg_describe),0,0 ,
        {scale9 = true, size = cc.size(520, 556)})
		cview:addChild(Bg_describe)
        display.commonUIParams(Bg_describe, {ap = cc.p(0,0), po = cc.p(50, 20)})
		
        local Bg_desr = display.newImageView(RES_DICT.CORE_PUT_BG_ICON, 140, 490)
		cview:addChild(Bg_desr)

		local desrLabels = {}
		local desrLabel = display.newLabel(234, 549, fontWithColor(11, {text = '',ap = cc.p(0, 0.5)}))
		cview:addChild(desrLabel, 1)
		table.insert(desrLabels, desrLabel)

		local desrLabel = display.newLabel(270, 511, fontWithColor(6, {text = '',ap = cc.p(0, 0.5)}))
		cview:addChild(desrLabel, 1)
		table.insert(desrLabels, desrLabel)

		local ruleBtn = display.newButton(248, 511, {n = _res('ui/common/common_btn_tips.png')})
		cview:addChild(ruleBtn)
		ruleBtn:setVisible(false)
        ruleBtn:setOnClickScriptHandler(function ( sender )
            app.uiMgr:ShowIntroPopup({moduleId = INTRODUCE_MODULE_ID.JEWEL_IMBED})
        end)
		
        local Bg_target = display.newImageView(_res(RES_DICT.Bg_target),0,0)
		cview:addChild(Bg_target, 2)
		display.commonUIParams(Bg_target, {ap = cc.p(0.5,0.5), po = cc.p(140, 490)})
		
		local cageSpine = sp.SkeletonAnimation:create(
       	    'effects/artifact/anime_cage1.json',
       	    'effects/artifact/anime_cage1.atlas',
       	    1)
		cageSpine:setPosition(cc.p(Bg_target:getContentSize().width / 2, Bg_target:getContentSize().height / 2))
       	Bg_target:addChild(cageSpine)
       	cageSpine:setAnimation(0, 'stop', false)
       	cageSpine:update(0)
		cageSpine:setToSetupPose()
			   
		local jewelImg = display.newImageView('',0,0)
		jewelImg:setPosition(cc.p(Bg_target:getContentSize().width / 2, Bg_target:getContentSize().height / 2))
		Bg_target:addChild(jewelImg)
        jewelImg:setScale(0.8)
		local distanceX = 8
		jewelImg:runAction(
            cc.RepeatForever:create(
                cc.Sequence:create(
                    cc.MoveBy:create(2, cc.p(0, distanceX )),
                    cc.MoveBy:create(2, cc.p(0, -distanceX ))
                )
            )
        )

		local mouseSpine = sp.SkeletonAnimation:create(
			'effects/artifact/xiaocangshu.json',
			'effects/artifact/xiaocangshu.atlas',
			1)
		mouseSpine:setPosition(cc.p(Bg_target:getContentSize().width / 2, 47))
		Bg_target:addChild(mouseSpine)
		mouseSpine:setVisible(false)

		local lockImg = display.newImageView(_res('ui/common/common_ico_lock.png'),0, 0)
		display.commonUIParams(lockImg, {ap = cc.p(0.5,0.5), po = cc.p(Bg_target:getContentSize().width / 2, Bg_target:getContentSize().height / 2)})
		Bg_target:addChild(lockImg)
				
		local unselectedLabel = display.newLabel(220, 490, fontWithColor(5,{w = 300 , hAlign= display.TAC , text = __('请从右侧选择塔可来激活核心能力'),ap = cc.p(0, 0.5)}))
		cview:addChild(unselectedLabel)
			
		-- 从属飨灵
    	local ownerView = CLayout:create(cc.size(200, 200))
	    display.commonUIParams(ownerView, {ap = cc.p(0,0), po = cc.p(400, 400)})
		cview:addChild(ownerView,2)

		local cardHeadNode = require('common.CardHeadNode').new({
			cardData = {
				cardId = 200001,
				level = 1,
				breakLevel = 1,
			},
			showBaseState = false, showActionState = false, showVigourState = false
		})
		cardHeadNode:setScale(0.5)
		cardHeadNode:setPosition(cc.p(103, 56))
		ownerView:addChild(cardHeadNode)

		local belongLabel = display.newLabel(54, 22, fontWithColor(6,{text = __('装备于'), ap = display.RIGHT_CENTER}))
		ownerView:addChild(belongLabel)

		-- 塔克技能
        local skillBg = display.newImageView(_res(RES_DICT.LISTBG), 304, 245,
        {
            ap = display.CENTER,
            scale9 = true, size = cc.size(488, 322),
        })
		cview:addChild(skillBg, 2)

        local Bg_skill = display.newNSprite(RES_DICT.CORE_PUT_BG_UNACTIVE_1, 345, 245,
        {
            ap = display.CENTER,
        })
        cview:addChild(Bg_skill, 2)

		local mouseToggles = {}
		for i = 1, 3 do
			local mouseToggle = display.newToggleView(113, 351 - (i-1) * 105,
			{
				ap = display.CENTER,
				-- n = RES_DICT.CORE_PUT_BG_UNACTIVE_2,
				s = RES_DICT.CORE_PUT_BG_UNACTIVE_2,
				enable = true,
			})
			mouseToggle:setTag(i)
			cview:addChild(mouseToggle, 3)
			table.insert( mouseToggles, mouseToggle)
		end

		local mouseImgs = {}
		for i = 1, 3 do
			local mouseImg = display.newImageView(_res(RES_DICT.Bg_mouse), 105, 351 - (i-1) * 105)
			cview:addChild(mouseImg, 3)
			table.insert( mouseImgs, mouseImg)
		end

        local activeImage = display.newButton(338, 380,
        {
            ap = display.CENTER,
            n = RES_DICT.Bg_TITLE,
            -- scale9 = true, size = cc.size(186, 31),
            enable = false,
        })
        display.commonLabelParams(activeImage, {text = __('激活效果'), fontSize = 22, color = '#7e2b1a', paddingW = 33, safeW = 120})
		cview:addChild(activeImage, 3)
		activeImage:setVisible(false)

        local unactiveImage = display.newButton(338, 380,
        {
            ap = display.CENTER,
            n = RES_DICT.CORE_BG_TITLE_UNACTIVE,
            -- scale9 = true, size = cc.size(186, 31),
            enable = false,
        })
        display.commonLabelParams(unactiveImage, {text = __('未激活'), fontSize = 22, color = '#ece3dc', paddingW = 33, safeW = 120})
		cview:addChild(unactiveImage, 3)

        local skillDesrLabel = display.newLabel(155, 356,
        {
            text = '',
            ap = cc.p(0, 1.0),
            fontSize = 22,
			color = '#c16f32',
			w = 380
        })
		cview:addChild(skillDesrLabel, 3)

		local imbedBtn = display.newButton(0, 0, {n = _res(RES_DICT.Btn_Normal), d = _res(RES_DICT.Btn_UnEnable)})
		display.commonUIParams(imbedBtn, {ap = cc.p(0.5,0), po = cc.p(310,22)})
		display.commonLabelParams(imbedBtn,fontWithColor(14,{text = __('镶嵌')}))
		cview:addChild(imbedBtn,4)

		local releaseBtn = display.newButton(0, 0, {n = _res(RES_DICT.Btn_Normal), d = _res(RES_DICT.Btn_UnEnable)})
		display.commonUIParams(releaseBtn, {ap = cc.p(0.5,0), po = cc.p(310,22)})
		display.commonLabelParams(releaseBtn,fontWithColor(14,{text = __('移除')}))
		cview:addChild(releaseBtn,4)

		local replaceBtn = display.newButton(0, 0, {n = _res(RES_DICT.Btn_Normal), d = _res(RES_DICT.Btn_UnEnable)})
		display.commonUIParams(replaceBtn, {ap = cc.p(0.5,0), po = cc.p(310,22)})
		display.commonLabelParams(replaceBtn,fontWithColor(14,{text = __('替换')}))
		cview:addChild(replaceBtn,4)

		view:AddContentView(cview)

		return {
			bgView 			= cview,

			lockBg			= lockBg,
			unlockBtn		= unlockBtn,
			requireLabel	= requireLabel,

			backpackView	= backpackView,
			gridView 		= gridView,
			ListBg 			= ListBg,
			
			lockSize		= lockSize,
			ownLabel		= ownLabel,
			virguleLabel	= virguleLabel,
			goodsNode 		= goodsNode,
			goodsCountLabel	= goodsCountLabel,
			
			kongBg 			= kongBg,

			mouseImgs		= mouseImgs,
			Bg_desr			= Bg_desr,
			desrLabels 		= desrLabels,
			ruleBtn			= ruleBtn,
			Bg_target 		= Bg_target,
			jewelImg		= jewelImg,
			cageSpine		= cageSpine,
			lockImg			= lockImg,
			unselectedLabel	= unselectedLabel,
			mouseSpine		= mouseSpine,
			skillDesrLabel	= skillDesrLabel,
			mouseToggles	= mouseToggles,
			activeImage		= activeImage,
			unactiveImage	= unactiveImage,
			Bg_skill		= Bg_skill,

			ownerView		= ownerView,
			cardHeadNode	= cardHeadNode,

			imbedBtn		= imbedBtn,
			releaseBtn		= releaseBtn,
			replaceBtn		= replaceBtn,

		}
	end
	xTry(function()
		self.viewData_ = CreateTaskView()
	end, __G__TRACKBACK__)
end

function JewelImbedView:AddLockView( ... )
	
end

return JewelImbedView