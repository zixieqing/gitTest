local GameScene = require( "Frame.GameScene" )
---@class ReturnWelfareTreasureView :GameScene
local ReturnWelfareTreasureView = class("ReturnWelfareTreasureView", GameScene)

local app = app
local uiMgr = app.uiMgr

local RES_DICT          = {
    COMMON_BTN_ORANGE               = _res('ui/common/common_btn_orange.png'),
    COMMON_BTN_GREEN                = _res('ui/common/common_btn_green.png'),
    COMMON_BG_GOODS                 = _res('ui/common/common_bg_goods.png'),
    RED_IMG                         = _res('ui/common/common_ico_red_point.png'),
    DIAO_KUANG_BG                   = _res('ui/home/returnWelfare/diao_kuang_bg.png'),
}


function ReturnWelfareTreasureView:ctor( ... )
	GameScene.ctor(self, 'ReturnWelfareTreasureView')
	self.args = unpack({...}) or {}

	self:InitUI()
end

function ReturnWelfareTreasureView:InitUI()
	local function CreateView()
        local view = CLayout:create(display.size)
        view:setPosition(display.center)
        view:setName('ReturnWelfareTreasureView')
        self:addChild(view)

        local cardDraw = require( "common.CardSkinDrawNode" ).new({skinId = 250221, coordinateType = COORDINATE_TYPE_CAPSULE})
        cardDraw.avatar:setScale(1)
        cardDraw:setPosition(display.cx - 740, -70)
        view:addChild(cardDraw)

        -----------------treasureBG start-----------------
        local treasureBG = display.newNSprite(RES_DICT.DIAO_KUANG_BG, display.SAFE_R - 440, display.cy - 50,
        {
            ap = display.CENTER,
        })
        view:addChild(treasureBG)
        treasureBG:setCascadeOpacityEnabled(true)

        local title = display.newLabel(425, 496,
        {
            text = __('鲷鱼秘宝'),
            ap = display.CENTER,
            fontSize = 74,
            reqW = 480 ,
            color = '#fff5e9',
            font = TTF_GAME_FONT, ttf = true,
            outline = '#833f2a',
        })
        treasureBG:addChild(title)

        local shining = display.newLabel(91, 194,
        {
            text = __('闪耀秘宝'),
            ap = display.LEFT_CENTER,
            fontSize = 24,
            color = '#935742',
        })
        treasureBG:addChild(shining)

        local normal = display.newLabel(91, 392,
        {
            text = __('普通秘宝'),
            ap = display.LEFT_CENTER,
            fontSize = 24,
            color = '#935742',
        })
        treasureBG:addChild(normal)

        local shiningListBG = display.newImageView(RES_DICT.COMMON_BG_GOODS, 364, 104,
        {
            ap = display.CENTER,
            scale9 = true, size = cc.size(609, 148),
        })
        treasureBG:addChild(shiningListBG)

        local normalListBG = display.newImageView(RES_DICT.COMMON_BG_GOODS, 364, 303,
        {
            ap = display.CENTER,
            scale9 = true, size = cc.size(609, 148),
        })
        treasureBG:addChild(normalListBG)

        ------------------treasureBG end------------------

        local eventLayer = display.newLayer(display.SAFE_R - 760, display.cy - 330, {size = cc.size(670, 400)})
        view:addChild(eventLayer)

        local normalTreasure = display.newNSprite(_res('arts/goods/goods_icon_190002'), 550, 310)
        normalTreasure:setScale(0.9)
        eventLayer:addChild(normalTreasure)

        local shiningTreasure = display.newNSprite(_res('arts/goods/goods_icon_190003'), 550, 110)
        shiningTreasure:setScale(0.9)
        eventLayer:addChild(shiningTreasure)

        local normalDrawBtn = display.newButton(550, 260,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_ORANGE,
            enable = true,
            tag = 1,
        })
        eventLayer:addChild(normalDrawBtn)
        
        local normalDrawBtnSize = normalDrawBtn:getContentSize()
        local redPointImg = display.newImageView(RES_DICT.RED_IMG, normalDrawBtnSize.width - 6, normalDrawBtnSize.height - 4)
        redPointImg:setVisible(false)
        normalDrawBtn:addChild(redPointImg)

        local shiningDrawBtn = display.newButton(550, 60,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_GREEN,
            enable = true,
            tag = 2,
        })
        eventLayer:addChild(shiningDrawBtn)

        local costLabel = display.newLabel(0, 0, fontWithColor('14', {text = ''}))
        shiningDrawBtn:addChild(costLabel)
    
        local costIcon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(DIAMOND_ID)), 0, 0)
        costIcon:setScale(0.2)
        shiningDrawBtn:addChild(costIcon)
        
		return {
            view                    = view,
            treasureBG              = treasureBG,
            title                   = title,
            shining                 = shining,
            normal                  = normal,
            shiningListBG           = shiningListBG,
            normalListBG            = normalListBG,
            eventLayer              = eventLayer,
            normalTreasure          = normalTreasure,
            shiningTreasure         = shiningTreasure,
            normalDrawBtn           = normalDrawBtn,
            redPointImg             = redPointImg,
            shiningDrawBtn          = shiningDrawBtn,
            costLabel               = costLabel,
            costIcon                = costIcon,
            cardDraw                = cardDraw,
        }
    end
	xTry(function ( )
        self.viewData = CreateView()

	end, __G__TRACKBACK__)
end

return ReturnWelfareTreasureView