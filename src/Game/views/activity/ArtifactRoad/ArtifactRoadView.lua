--[[
    神器之路界面
--]]
local GameScene = require( "Frame.GameScene" )
---@class ArtifactRoadView :GameScene
local ArtifactRoadView = class("ArtifactRoadView", GameScene)
local shareFacade = AppFacade.GetInstance()
local cardMgr = app.cardMgr

local RES_DICT          = {
	NAV_BACK                        = _res("ui/common/common_btn_back.png"),
    COMMON_TITLE                    = _res('ui/common/common_title.png'),
    MAIN_BG_MONEY                   = _res('ui/home/nmain/main_bg_money'),
    CORE_ROAD_BG_MAP                = _res('ui/home/activity/ArtifactRoad/core_road_bg_map.png'),
    CORE_ROAD_BG                    = _res('ui/home/activity/ArtifactRoad/core_road_bg.png'),
    CORE_ROAD_BG_CORE               = _res('ui/home/activity/ArtifactRoad/core_road_bg_core.png'),
    CORE_ROAD_BG_TEXT               = _res('ui/home/activity/ArtifactRoad/core_road_bg_text.png'),
}

function ArtifactRoadView:ctor( ... )
	GameScene.ctor(self, 'Game.views.activity.ArtifactRoad.ArtifactRoadView')
	self.args = unpack({...}) or {}

	self:InitUI()
end

function ArtifactRoadView:InitUI()
	local eaterLayer = CColorView:create(cc.r4b(0))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)

    local CardId = self.args.CardId
    local cardConfig = CommonUtils.GetConfigAllMess('card','card')[tostring(CardId)]
    
	local function CreateView()
        local view = CLayout:create(display.size)
        display.commonUIParams(view, {po = display.center})
        self:addChild(view)
    
        local descrScrollView = CScrollView:create(cc.size(display.width/2 + 138, display.height))
		descrScrollView:setDirection(eScrollViewDirectionHorizontal)
		--descrScrollView:setViewSize(cc.size(display.width/2 + 138, display.height))
		descrScrollView:setPosition(cc.p(display.cx - 138, 0))
        descrScrollView:setAnchorPoint(display.LEFT_BOTTOM)
        descrScrollView:setBounceable(false)
        view:addChild(descrScrollView)

        --local BG = display.newImageView(RES_DICT.CORE_ROAD_BG_MAP, 0, 0,
        --{
        --    ap = display.LEFT_BOTTOM,
        --})
        --local size = BG:getContentSize()
        --BG:setPositionY((display.height - size.height) / 2)
        --descrScrollView:setContainer(BG)
        
        -- local BG = display.newImageView(RES_DICT.CORE_ROAD_BG_MAP, display.cx, display.cy,
        -- {
        --     ap = display.CENTER
        -- })
        -- view:addChild(BG)

        local AmbryImg = display.newNSprite(RES_DICT.CORE_ROAD_BG, display.cx - 98, display.cy - 1,
        {
            ap = display.CENTER,
        })
        view:addChild(AmbryImg)

        local secData  = {cardId = CardId, coordinateType = COORDINATE_TYPE_CAPSULE}
        local mainCardNode = require('common.CardSkinDrawNode').new(secData)
        view:addChild(mainCardNode)
        local winSize = display.size
        if (winSize.width / winSize.height) <= (1024 / 768) then
            -- ipad尺寸 不放大
            mainCardNode.avatar:setScale(mainCardNode.avatar:getScale()/1.15)
        end
        mainCardNode:GetAvatar():runAction(cc.RepeatForever:create(cc.Sequence:create(
            cc.MoveBy:create(2, cc.p(0, 15)),
            cc.MoveBy:create(2, cc.p(0, -15))
        )))

        -- marry spine
        local marrySpine = nil
        local CardData = app.gameMgr:GetCardDataByCardId(CardId)
        if CardData then
            if CommonUtils.GetModuleAvailable(MODULE_SWITCH.MARRY) and utils.isExistent('effects/marry/fly.atlas') and cardMgr.GetCouple(CardData.id) then
                local cardCoordConf = CommonUtils.GetConfig('cards', 'coordinate', CardId) or {}
                local coordTeamConf = cardCoordConf[COORDINATE_TYPE_TEAM] or {}
                local coordHomeConf = cardCoordConf[COORDINATE_TYPE_HOME] or {}

                marrySpine = display.newCacheSpine(SpineCacheName.COMMON, 'effects/marry/fly')
                marrySpine:setPositionX(-checkint(coordTeamConf.x) / checkint(coordTeamConf.scale) * checkint(coordHomeConf.scale) + checkint(coordHomeConf.x) + 80)
                marrySpine:setPositionY(checkint((display.height - CC_DESIGN_RESOLUTION.height) / 2))
                marrySpine:setAnimation(0, 'idle2', true)
                marrySpine:update(0)
                marrySpine:setToSetupPose()
                mainCardNode:addChild(marrySpine, 2)
            end
        end

        -------------------DesrBG start-------------------
        local DesrBG = display.newNSprite(RES_DICT.CORE_ROAD_BG_TEXT, display.SAFE_L + 124, 110,
        {
            ap = display.LEFT_CENTER,
            scale9 = true , size = cc.size(620 ,181)
        })
        view:addChild(DesrBG)
        -- local DesrBG = display.newNSprite(RES_DICT.CORE_ROAD_BG_TEXT, 0, 181,
        -- {
        --     ap = display.RIGHT_CENTER,
        -- })

        -- local size = DesrBG:getContentSize()
        -- local DoubleSize = cc.size(size.width * 2, size.height * 2)
        -- -- 裁剪节点
        -- local sceneClipNode = cc.ClippingNode:create()
        -- sceneClipNode:setCascadeOpacityEnabled(true)
        -- sceneClipNode:setContentSize(DoubleSize)
        -- sceneClipNode:setAnchorPoint(cc.p(0, 0.5))
        -- sceneClipNode:setPosition(display.SAFE_L + 124, 110)
        -- view:addChild(sceneClipNode)

        -- local DoubleDesrBG = display.newNSprite(RES_DICT.CORE_ROAD_BG_TEXT, 0, 0,
        -- {
        --     ap = display.LEFT_BOTTOM,
        -- })
        -- DoubleDesrBG:setScale(2)
        -- sceneClipNode:setInverted(false)
        -- sceneClipNode:setAlphaThreshold(0.1)
        -- sceneClipNode:setStencil(DoubleDesrBG)

        -- sceneClipNode:addChild(DesrBG)

        local NameLabel = display.newLabel(271, 142,
        {
            text = cardConfig.artifactName,
            ap = display.CENTER,
            fontSize = 24,
            color = '#ffedad',
            font = TTF_GAME_FONT, ttf = true,
        })
        DesrBG:addChild(NameLabel)

        local DesrLabel = display.newLabel(98, 124,
        {
            text = '',
            ap = cc.p(0, 1.0),
            fontSize = 22,
            color = '#ffffff',
            w = 480
        })
        DesrBG:addChild(DesrLabel)

        --------------------DesrBG end--------------------
        local ArtifactBtn = display.newButton(display.SAFE_L + 113, 110,
        {
            ap = display.CENTER,
            n = RES_DICT.CORE_ROAD_BG_CORE,
            enable = true,
        })
        -- display.commonLabelParams(ArtifactBtn, fontWithColor(14, {text = ''})
        view:addChild(ArtifactBtn)
        ArtifactBtn:runAction(cc.RepeatForever:create(cc.RotateBy:create(1, 30)))

        local ArtifactImg = display.newImageView(CommonUtils.GetArtifiactPthByCardId(CardId, true), display.SAFE_L + 113, 114,
        {
            ap = display.CENTER,
        })
        ArtifactImg:setScale(0.4, 0.4)
        view:addChild(ArtifactImg)

        local UnlockLabel = display.newLabel(display.SAFE_L + 113, 44,
        {
            text = __('去解锁'),
            ap = display.CENTER,
            fontSize = 24,
            color = '#ffffff',
            font = TTF_GAME_FONT, ttf = true,
            outline = '#311717',
        })
        view:addChild(UnlockLabel)

        local GoodPurchaseNode = require('common.GoodPurchaseNode')
        -- top icon
        local currencyBG = display.newImageView(RES_DICT.MAIN_BG_MONEY,0,0,{enable = false, scale9 = true, size = cc.size(700 + (display.width - display.SAFE_R),54)})
        display.commonUIParams(currencyBG,{ap = cc.p(1.0,1.0), po = cc.p(display.width, display.height)})
        view:addChild(currencyBG)

        local currency = { cardConfig.artifactCostId, HP_ID, DIAMOND_ID }
        local moneyNodes = {}
        for i,v in ipairs(currency) do
            local purchaseNode = GoodPurchaseNode.new({id = v, animate = false, datas = self.datas})
            purchaseNode:updataUi(checkint(v))
            display.commonUIParams(purchaseNode,
                    {ap = cc.p(1, 0.5), po = cc.p(display.SAFE_R - 20 - (( #currency - i) * (purchaseNode:getContentSize().width + 16)), currencyBG:getPositionY()- 26)})
            view:addChild(purchaseNode, 5)
            purchaseNode:setName('purchaseNode' .. i)
            purchaseNode.viewData.touchBg:setTag(checkint(v))
            moneyNodes[tostring( v )] = purchaseNode
        end

		local tabNameLabel = display.newButton(display.SAFE_L + 130, display.size.height + 2 ,{n = RES_DICT.COMMON_TITLE,enable = false,ap = cc.p(0, 1)})
		display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('试炼之门'), fontSize = 30, color = '473227',offset = cc.p(0,-8)})
        view:addChild(tabNameLabel,5)
        
		return {
            view                    = view,
            descrScrollView         = descrScrollView,
            AmbryImg                = AmbryImg,
            DesrBG                  = DesrBG,
            NameLabel               = NameLabel,
            DesrLabel               = DesrLabel,
            ArtifactBtn             = ArtifactBtn,
            ArtifactImg             = ArtifactImg,
            UnlockLabel             = UnlockLabel,
            moneyNodes              = moneyNodes,
			tabNameLabel 			= tabNameLabel,
			tabNameLabelPos 		= cc.p(tabNameLabel:getPosition()),
        }
    end
	xTry(function ( )
        self.viewData = CreateView()

        self.viewData.tabNameLabel:setPositionY(display.height + 100)
        local action = cc.EaseBounceOut:create(cc.MoveTo:create(1, self.viewData.tabNameLabelPos))
        self.viewData.tabNameLabel:runAction( action )

        -- self:ShowEnterAni()
	end, __G__TRACKBACK__)
end

function ArtifactRoadView:ShowEnterAni(  )
    local viewData = self.viewData
    local DesrBG = viewData.DesrBG
    DesrBG:runAction(cc.MoveBy:create(0.4, cc.p(DesrBG:getContentSize().width, 0)))
end

return ArtifactRoadView