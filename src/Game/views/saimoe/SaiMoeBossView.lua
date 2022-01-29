--[[
    燃战BOSS界面
--]]
local GameScene = require( "Frame.GameScene" )
---@class SaiMoeBossView :GameScene
local SaiMoeBossView = class("SaiMoeBossView", GameScene)
local shareFacade = AppFacade.GetInstance()
local gameMgr = shareFacade:GetManager("GameManager")
local uiMgr = shareFacade:GetManager("UIManager")
local GoodNode = require('common.GoodNode')

local RES_DICT          = {
    COMMON_BG_FLOAT_TEXT            = _res('ui/common/common_bg_float_text.png'),
    COMMON_BTN_ORANGE               = _res('ui/common/common_btn_orange.png'),
    COMMON_BTN_GREEN                = _res('ui/common/common_btn_green.png'),
    COMMON_BTN_TIPS                 = _res('ui/common/common_btn_tips.png'),
    COMMON_BTN_WHITE_DEFAULT        = _res('ui/common/common_btn_white_default.png'),
    COMMON_TITLE_5                  = _res('ui/common/common_title_5.png'),
    STARPLAN_BOOS_MAPS_1            = _res('ui/home/activity/saimoe/starplan_boos_maps_1.png'),
    STARPLAN_BOOS_MAPS_2            = _res('ui/home/activity/saimoe/starplan_boos_maps_2.png'),
    STARPLAN_BOOS_MAPS_3            = _res('ui/home/activity/saimoe/starplan_boos_maps_3.png'),
    STARPLAN_BOOS_MAPS_4            = _res('ui/home/activity/saimoe/starplan_boos_maps_4.png'),
    STARPLAN_BOSS_BG                = _res('ui/home/activity/saimoe/starplan_boss_bg.png'),
    STARPLAN_BOSS_FALLDOWN_BG       = _res('ui/home/activity/saimoe/starplan_boss_falldown_bg.png'),
    STARPLAN_BOSS_HUNT_BG_MOSTER_INFO = _res('ui/home/activity/saimoe/starplan_boss_hunt_bg_moster_info.png'),
    STARPLAN_BOSS_MAPS_BG           = _res('ui/home/activity/saimoe/starplan_boss_maps_bg.png'),
    STARPLAN_BOSS_MAPS_CLUE         = _res('ui/home/activity/saimoe/starplan_boss_maps_clue.png'),
}

function SaiMoeBossView:ctor( ... )
	GameScene.ctor(self, 'Game.views.saimoe.SaiMoeBossView')
	self.args = unpack({...}) or {}

	self:InitUI()
end

function SaiMoeBossView:InitUI()
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 180))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    eaterLayer:setOnClickScriptHandler(function(sender)
        shareFacade:UnRegsitMediator("SaiMoeBossMediator")
    end)
    
	local function CreateView()
        local view = CLayout:create(display.size)
        display.commonUIParams(view, {po = display.center})
        view:setName('SaiMoeBossView')
        self:addChild(view)

        local BG = display.newImageView(RES_DICT.STARPLAN_BOSS_BG, display.cx - 570, display.cy - 341,
        {
            ap = display.LEFT_BOTTOM,
            enable = true,
        })
        view:addChild(BG)

        local clipper = cc.ClippingNode:create()
        clipper:setContentSize(display.size)
        clipper:setAlphaThreshold(0.1)
        clipper:setStencil(display.newImageView(RES_DICT.STARPLAN_BOSS_BG, display.cx - 570 + 5, display.cy - 341 + 5, {ap = display.LEFT_BOTTOM, scale = 2}))
        clipper:setInverted(false)
        display.commonUIParams(clipper, {ap = display.CENTER, po = cc.p(display.cx, display.cy)})
        view:addChild(clipper)

        local drawNode = require('common.CardSkinDrawNode').new({
			confId = 301218,
			-- coordinateType = COORDINATE_TYPE_HEAD
        })
        clipper:addChild(drawNode)

        ------------------desrView start------------------
        local desrView = display.newLayer(display.cx - -11, display.cy - 23,
        {
            ap = display.LEFT_BOTTOM,
            size = cc.size(500, 330),
            enable = false,
        })
        view:addChild(desrView)

        local upBG = display.newImageView(RES_DICT.STARPLAN_BOSS_HUNT_BG_MOSTER_INFO, 252, 263,
        {
            ap = display.CENTER,
        })
        desrView:addChild(upBG)

        local downBG = display.newImageView(RES_DICT.STARPLAN_BOSS_FALLDOWN_BG, 251, 92,
        {
            ap = display.CENTER,
        })
        desrView:addChild(downBG)

        local tipBtn = display.newButton(41, 259,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_TIPS,
            enable = true,
        })

        desrView:addChild(tipBtn)

		local bossNameLabel = display.newRichLabel(27, 262, {ap = display.LEFT_CENTER})
		desrView:addChild(bossNameLabel)
        local detailBtn = display.newButton(417, 260,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_WHITE_DEFAULT,
            scale9 = true, size = cc.size(140, 62),
            enable = true,
        })
        display.commonLabelParams(detailBtn, fontWithColor(14, {text = __('BOSS详情'), fontSize = 24, color = '#ffffff'}))
        desrView:addChild(detailBtn)

        local bonusTabletImg = display.newButton(251, 163,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_TITLE_5,
            enable = false,
        })
        display.commonLabelParams(bonusTabletImg, {text = __('掉落'), fontSize = 22, color = '#5b3c25'})
        desrView:addChild(bonusTabletImg)

        local bonusTipsLabel = display.newLabel(251, 14,
        {
            text = __('(伤害越高，奖励数量越多)'),
            ap = display.CENTER,
            fontSize = 20,
            color = '#ffca27',
        })
        desrView:addChild(bonusTipsLabel)
        display.setNodesToNodeOnCenter(desrView, {bonusTipsLabel, tipBtn}, {y = 16})
        -------------------desrView end-------------------
        
        local unlockSpine = sp.SkeletonAnimation:create("effects/activity/saimoe/starplan_ditu.json","effects/activity/saimoe/starplan_ditu.atlas", 1)
        unlockSpine:setPosition(cc.p(display.cx - 10, display.cy + 8))
        unlockSpine:update(0)
        view:addChild(unlockSpine)

        ----------------fragmentView start----------------
        local fragmentView = display.newLayer(display.cx - 570, display.cy - 342,
        {
            ap = display.LEFT_BOTTOM,
            size = cc.size(1120, 300),
            enable = false,
        })
        view:addChild(fragmentView)

        local mapBG = display.newImageView(RES_DICT.STARPLAN_BOSS_MAPS_BG, 553, 140,
        {
            ap = display.CENTER,
        })
        fragmentView:addChild(mapBG)

        local fragmentImgs = {true, true, true, true}

        local fragmentButtons = {true, true, true, true}
        local fragmentFirstLayout = CColorView:create(cc.r4b(0))
        fragmentFirstLayout:setContentSize(cc.size(250, 200))
        fragmentFirstLayout:setTouchEnabled(true)
        fragmentFirstLayout:setTag(1)
        display.commonUIParams(fragmentFirstLayout, {ap = cc.p(0.5, 0.5), po = cc.p(170, 137)})
        fragmentView:addChild(fragmentFirstLayout)
        fragmentButtons[1] = fragmentFirstLayout

		local fragmentFirstImg = FilteredSpriteWithOne:create()
		fragmentFirstImg:setCascadeOpacityEnabled(true)
		fragmentFirstImg:setTexture(RES_DICT.STARPLAN_BOOS_MAPS_1)
		fragmentFirstImg:setAnchorPoint(display.LEFT_BOTTOM)
        fragmentFirstLayout:addChild(fragmentFirstImg)
        fragmentImgs[1] = fragmentFirstImg

        local fragmentSecondLayout = CColorView:create(cc.r4b(0))
        fragmentSecondLayout:setContentSize(cc.size(250, 200))
        fragmentSecondLayout:setTouchEnabled(true)
        fragmentSecondLayout:setTag(2)
        display.commonUIParams(fragmentSecondLayout, {ap = cc.p(0.5, 0.5), po = cc.p(430, 140)})
        fragmentView:addChild(fragmentSecondLayout)
        fragmentButtons[2] = fragmentSecondLayout

		local fragmentSecondImg = FilteredSpriteWithOne:create()
		fragmentSecondImg:setCascadeOpacityEnabled(true)
		fragmentSecondImg:setTexture(RES_DICT.STARPLAN_BOOS_MAPS_2)
		fragmentSecondImg:setAnchorPoint(display.LEFT_BOTTOM)
        fragmentSecondLayout:addChild(fragmentSecondImg)
        fragmentImgs[2] = fragmentSecondImg

        local fragmentThirdLayout = CColorView:create(cc.r4b(0))
        fragmentThirdLayout:setContentSize(cc.size(250, 200))
        fragmentThirdLayout:setTouchEnabled(true)
        fragmentThirdLayout:setTag(3)
        display.commonUIParams(fragmentThirdLayout, {ap = cc.p(0.5, 0.5), po = cc.p(696, 140)})
        fragmentView:addChild(fragmentThirdLayout)
        fragmentButtons[3] = fragmentThirdLayout

		local fragmentThirdImg = FilteredSpriteWithOne:create()
		fragmentThirdImg:setCascadeOpacityEnabled(true)
		fragmentThirdImg:setTexture(RES_DICT.STARPLAN_BOOS_MAPS_3)
		fragmentThirdImg:setAnchorPoint(display.LEFT_BOTTOM)
        fragmentThirdLayout:addChild(fragmentThirdImg)
        fragmentImgs[3] = fragmentThirdImg

        local fragmentFourthLayout = CColorView:create(cc.r4b(0))
        fragmentFourthLayout:setContentSize(cc.size(250, 200))
        fragmentFourthLayout:setTouchEnabled(true)
        fragmentFourthLayout:setTag(4)
        display.commonUIParams(fragmentFourthLayout, {ap = cc.p(0.5, 0.5), po = cc.p(954, 138)})
        fragmentView:addChild(fragmentFourthLayout)
        fragmentButtons[4] = fragmentFourthLayout

		local fragmentFourthImg = FilteredSpriteWithOne:create()
		fragmentFourthImg:setCascadeOpacityEnabled(true)
		fragmentFourthImg:setTexture(RES_DICT.STARPLAN_BOOS_MAPS_4)
		fragmentFourthImg:setAnchorPoint(display.LEFT_BOTTOM)
        fragmentFourthLayout:addChild(fragmentFourthImg)
        fragmentImgs[4] = fragmentFourthImg

        local fragmentCountLabels = {true, true, true, true}
        local fragmentCountFirstLabel = display.newImageView(RES_DICT.STARPLAN_BOSS_MAPS_CLUE, 168, 49,
        {
            ap = display.CENTER,
        })
        fragmentView:addChild(fragmentCountFirstLabel)
        fragmentCountLabels[1] = fragmentCountFirstLabel

        local fragmentCountSecondLabel = display.newImageView(RES_DICT.STARPLAN_BOSS_MAPS_CLUE, 429, 49,
        {
            ap = display.CENTER,
        })
        fragmentView:addChild(fragmentCountSecondLabel)
        fragmentCountLabels[2] = fragmentCountSecondLabel

        local fragmentCountThirdLabel = display.newImageView(RES_DICT.STARPLAN_BOSS_MAPS_CLUE, 694, 49,
        {
            ap = display.CENTER,
        })
        fragmentView:addChild(fragmentCountThirdLabel)
        fragmentCountLabels[3] = fragmentCountThirdLabel

        local fragmentCountFourthLabel = display.newImageView(RES_DICT.STARPLAN_BOSS_MAPS_CLUE, 952, 49,
        {
            ap = display.CENTER,
        })
        fragmentView:addChild(fragmentCountFourthLabel)
        fragmentCountLabels[4] = fragmentCountFourthLabel

        local composedBtn = display.newButton(554, 150,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_ORANGE,
            scale9 = true, size = cc.size(140, 62),
            enable = true,
        })
        display.commonLabelParams(composedBtn, fontWithColor(14, {text = __('找寻BOSS'), fontSize = 24, color = '#ffffff'}))
        fragmentView:addChild(composedBtn)

        -----------------fragmentView end-----------------

        ----------------completeView start----------------
        local completeView = display.newLayer(display.cx - 570, display.cy - 342,
        {
            ap = display.LEFT_BOTTOM,
            size = cc.size(1120, 300),
            enable = false,
        })
        view:addChild(completeView)

        local battleBtn = display.newButton(858, 60,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_ORANGE,
            enable = true,
        })
        display.commonLabelParams(battleBtn, fontWithColor(14, {text = __('揍他'), fontSize = 24, color = '#fffff0'}))
        completeView:addChild(battleBtn, 2)

        local shopBtn = display.newButton(858, 60,
                {
                    ap = display.CENTER,
                    n = RES_DICT.COMMON_BTN_GREEN,
                    enable = true,
					scale9 = true
                })
        display.commonLabelParams(shopBtn, fontWithColor(14, {text = __('神秘商店'), fontSize = 24,  color = '#fffff0' , paddingW = 30 , safeW = 120}))
        completeView:addChild(shopBtn, 2)
            
        local forkSpine = sp.SkeletonAnimation:create('arts/effects/map_fighting_fork.json', 'arts/effects/map_fighting_fork.atlas', 1)
        forkSpine:update(0)
        forkSpine:addAnimation(0, 'idle', true)
        completeView:addChild(forkSpine, 5)
        forkSpine:setPosition(cc.p(850, 250))

        -----------------completeView end-----------------
        local accessLabel = display.newButton(display.cx - 8, display.cy - 55,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BG_FLOAT_TEXT,
            scale9 = true,
            enable = false,
        })
        display.commonLabelParams(accessLabel, {text = __('拼凑出完整的地图去寻找暴食的踪迹'), paddingW = 50 ,  fontSize = 22, color = '#ffca27'})
        view:addChild(accessLabel)

        local showSpine = sp.SkeletonAnimation:create("effects/activity/saimoe/starplan_guang.json","effects/activity/saimoe/starplan_guang.atlas", 1)
        showSpine:setPosition(cc.p(858, 160))
        showSpine:update(0)
        completeView:addChild(showSpine, 100)

        ----------------bottomView start----------------
		-- 底部选卡界面
        local bottomView = display.newLayer(0, 0,
        {
            ap = display.LEFT_BOTTOM,
            size = display.size,
            enable = false,
        })
        view:addChild(bottomView)

        local eaterLayer = CColorView:create(cc.r4b(0))
        eaterLayer:setTouchEnabled(true)
        eaterLayer:setContentSize(display.size)
        eaterLayer:setPosition(cc.p(display.cx, display.cy))
        bottomView:addChild(eaterLayer, -1)
        eaterLayer:setOnClickScriptHandler(function(sender)
            bottomView:setVisible(false)
        end)

		local bottomBg = display.newImageView(_res('ui/worldboss/home/worldboss_bg_below.png'), 0, 0, {enable = true, scale9 = true})
		display.commonUIParams(bottomBg, {po = cc.p(
			display.cx,
			bottomBg:getContentSize().height * 0.5
		)})
		bottomView:addChild(bottomBg)
		bottomBg:setContentSize(cc.size(display.width, bottomBg:getContentSize().height))

		local teamBg = display.newImageView(_res('ui/worldboss/home/worldboss_team_bg.png'), 0, 0)
		display.commonUIParams(teamBg, {po = cc.p(
			display.SAFE_L - 60 + teamBg:getContentSize().width * 0.5,
			teamBg:getContentSize().height * 0.5
		)})
		bottomView:addChild(teamBg)

        local cardHeadNodeSize = cc.size(96, 96)
		local emptyCardNodes = {}
		for i = 1, MAX_TEAM_MEMBER_AMOUNT do
			local emptyCardHeadBg = display.newImageView(_res('ui/common/kapai_frame_bg_nocard.png'))
			local scale = cardHeadNodeSize.width / emptyCardHeadBg:getContentSize().width
			emptyCardHeadBg:setScale(scale)
			display.commonUIParams(emptyCardHeadBg, {po = cc.p(
				teamBg:getPositionX() + (emptyCardHeadBg:getContentSize().width * scale + 10) * (i - 0.5 - MAX_TEAM_MEMBER_AMOUNT * 0.5),
				teamBg:getPositionY() - 30
			)})
			bottomView:addChild(emptyCardHeadBg)

			local emptyCardHeadFrame = display.newImageView(_res('ui/common/kapai_frame_nocard.png'), 0, 0)
			display.commonUIParams(emptyCardHeadFrame, {po = utils.getLocalCenter(emptyCardHeadBg)})
			emptyCardHeadBg:addChild(emptyCardHeadFrame)

			local addIcon = display.newNSprite(_res('ui/common/maps_fight_btn_pet_add.png'), 0, 0)
			display.commonUIParams(addIcon, {po = utils.getLocalCenter(emptyCardHeadBg)})
			addIcon:setScale(1 / scale)
			emptyCardHeadBg:addChild(addIcon)

			local btn = display.newButton(0, 0, {size = cardHeadNodeSize})
			display.commonUIParams(btn, {po = cc.p(
				emptyCardHeadBg:getPositionX(),
				emptyCardHeadBg:getPositionY()
			)})
			bottomView:addChild(btn, 2)

			-- 添加队长标识
			if 1 == i then
				local captainMark = display.newImageView(_res('ui/home/teamformation/team_ico_captain.png'), 0, 0)
				display.commonUIParams(captainMark, {po = cc.p(
					emptyCardHeadBg:getPositionX(),
					emptyCardHeadBg:getPositionY() + emptyCardHeadBg:getContentSize().height * 0.5 * scale
				)})
				bottomView:addChild(captainMark)
			end

			emptyCardNodes[i] = {emptyCardHeadBg = emptyCardHeadBg, btn = btn}
        end
        
        local fightImage = display.newImageView(_res('ui/common/discovery_bg_fight.png'))
        local fightImageSize = fightImage:getContentSize()
        fightImage:setAnchorPoint(cc.p(1, 0.5))
        fightImage:setPosition(cc.p(display.SAFE_R + 40, fightImageSize.height/2))
        bottomView:addChild(fightImage)

        -- fight button
        local fightBtn = require('common.CommonBattleButton').new({pattern = 1})
        fightBtn:setPosition(display.SAFE_R - 116, 117)
        bottomView:addChild(fightBtn)
        -----------------bottomView end-----------------
    

		return {
            view                    = view,
            BG                      = BG, 
            drawNode                = drawNode,
            desrView                = desrView, 
            upBG                    = upBG, 
            downBG                  = downBG, 
            tipBtn                  = tipBtn, 
            bossNameLabel           = bossNameLabel, 
            bossStateLabel          = bossStateLabel, 
            detailBtn               = detailBtn, 
            bonusTabletImg          = bonusTabletImg, 
            fragmentView            = fragmentView, 
            mapBG                   = mapBG,
            fragmentButtons         = fragmentButtons,
            fragmentFirstImg        = fragmentFirstImg,
            fragmentSecondImg       = fragmentSecondImg,
            fragmentThirdImg        = fragmentThirdImg,
            fragmentFourthImg       = fragmentFourthImg,
            fragmentImgs            = fragmentImgs,
            fragmentCountFirstLabel = fragmentCountFirstLabel, 
            fragmentCountSecondLabel = fragmentCountSecondLabel, 
            fragmentCountThirdLabel = fragmentCountThirdLabel, 
            fragmentCountFourthLabel = fragmentCountFourthLabel, 
            fragmentCountLabels     = fragmentCountLabels,
            composedBtn             = composedBtn,
            completeView            = completeView,
            battleBtn               = battleBtn,
            shopBtn                 = shopBtn,
            forkSpine               = forkSpine,
            accessLabel             = accessLabel, 
            unlockSpine             = unlockSpine,
            showSpine               = showSpine,
            bottomView              = bottomView,
            emptyCardNodes          = emptyCardNodes,
            fightBtn                = fightBtn,
			teamCardHeadNodes       = {},
        }
    end
	xTry(function ( )
        self.viewData = CreateView()
	end, __G__TRACKBACK__)
end

function SaiMoeBossView:ShowEnterAni(actionType)
    local aniTime = 0.3
    if actionType then
        if actionType.isScale then
            if actionType.cb then
                actionType.cb()
            end
            self.viewData.view:setScale(0.6)
            self.viewData.view:runAction(cc.EaseBackOut:create(cc.ScaleTo:create(aniTime, 1)))
            return
        end
    end
    self.viewData.view:setOpacity(0)
    self.viewData.view:setPosition(display.cx - 20, display.cy - 20)
    self.viewData.view:runAction(cc.Spawn:create(
            cc.FadeIn:create(aniTime),
            cc.MoveBy:create(aniTime, cc.p(20, 20))
    ))
    self.viewData.drawNode:setOpacity(0)
    self.viewData.drawNode:runAction(cc.FadeIn:create(aniTime))
end

--[[
刷新队伍阵容界面
@params teamData table
--]]
function SaiMoeBossView:RefreshTeamMember(teamData)
    local cardHeadNodeSize = cc.size(96, 96)
	for i = 1, MAX_TEAM_MEMBER_AMOUNT do
		local cardHeadNode = self.viewData.teamCardHeadNodes[i]
		if nil ~= cardHeadNode then
			cardHeadNode:removeFromParent()
		end
	end
	self.viewData.teamCardHeadNodes = {}

	for i,v in ipairs(teamData) do
		local nodes = self.viewData.emptyCardNodes[i]

		if nil ~= v.id and 0 ~= checkint(v.id) then
            local c_id = checkint(v.id)
			local cardHeadNode = require('common.CardHeadNode').new({
				id = c_id,
				showBaseState = true,
				showActionState = false,
				showVigourState = false
			})
			local scale = (cardHeadNodeSize.width) / cardHeadNode:getContentSize().width
			cardHeadNode:setScale(scale)
			display.commonUIParams(cardHeadNode, {po = cc.p(
				nodes.emptyCardHeadBg:getPositionX(),
				nodes.emptyCardHeadBg:getPositionY()
			)})
			self.viewData.bottomView:addChild(cardHeadNode)

			self.viewData.teamCardHeadNodes[i] = cardHeadNode
		end
	end
end
return SaiMoeBossView