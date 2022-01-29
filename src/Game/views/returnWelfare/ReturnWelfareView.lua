local GameScene = require( "Frame.GameScene" )
---@class ReturnWelfareView :GameScene
local ReturnWelfareView = class("ReturnWelfareView", GameScene)

local app = app
local uiMgr = app.uiMgr

local RES_DICT          = {
    COMMON_BTN_SWITCH               = _res('ui/common/common_btn_switch.png'),
    COMMON_BG_FLOAT_TEXT            = _res('ui/common/common_bg_float_text.png'),
    COMMON_BTN_BACK                 = _res('ui/common/common_btn_back.png'),
    COMMON_TITLE_NEW                = _res('ui/common/common_title_new.png'),
    RED_IMG                         = _res('ui/common/common_ico_red_point.png'),
    COMMON_BTN_TIPS                 = _res('ui/common/common_btn_tips.png'),
    DAY_BG                          = _res('ui/home/returnWelfare/day_bg.png'),
    TOP_TIME_BG                     = _res('ui/home/returnWelfare/top_time_bg.png'),
}

function ReturnWelfareView:ctor( ... )
	GameScene.ctor(self, 'ReturnWelfareView')
	self.args = unpack({...}) or {}

	self:InitUI()
end

function ReturnWelfareView:InitUI()
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 130))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    
	local function CreateView()
        local view = CLayout:create(display.size)
        view:setPosition(display.center)
        view:setName('ReturnWelfareView')
        self:addChild(view)

        local BG = display.newImageView(RES_DICT.DAY_BG, display.cx - 0, display.cy - 0,
        {
            ap = display.CENTER,
        })
        view:addChild(BG)

        local topTimeBG = display.newNSprite(RES_DICT.TOP_TIME_BG, display.width, display.height - 62,
        {
            ap = display.RIGHT_CENTER,
            scale9 = true ,
            size = cc.size(642, 120 )

        })
        view:addChild(topTimeBG)

        -------------------timeBG start-------------------
        local timeBG = display.newNSprite(RES_DICT.COMMON_BG_FLOAT_TEXT, display.SAFE_R - 187, display.height - 47,
        {
            ap = display.CENTER,
        })
        view:addChild(timeBG)

        local leftTime = display.newLabel(148, 17,
        {
            text = __('剩余时间:'),
            ap = display.RIGHT_CENTER,
            fontSize = 22,
            color = '#ffffff',
            font = TTF_GAME_FONT, ttf = true,
        })
        timeBG:addChild(leftTime)

        local timeLabel = display.newLabel(150, 17,
        {
            text = '',
            ap = display.LEFT_CENTER,
            fontSize = 22,
            color = '#ffe9b4',
            font = TTF_GAME_FONT, ttf = true,
            outline = '#3c1e0e',
        })
        timeBG:addChild(timeLabel)

        --------------------timeBG end--------------------
        local desc = display.newLabel(display.SAFE_R - 27, display.height - 85,
        {
            text = __('您已离开游戏较长时间，开启专属活动'),
            ap = display.RIGHT_CENTER,
            w = 430,
            hAlign = display.TAR ,
            fontSize = 20,
            color = '#935742',
        })
        view:addChild(desc)

        local contentView = CLayout:create(display.size)
        contentView:setPosition(display.center)
        view:addChild(contentView)

        local tabNameLabel = display.newButton(display.SAFE_L + 97, display.height, {n = RES_DICT.COMMON_TITLE_NEW, ap = cc.p(0, 1)})
        display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = __('回归福利'), reqW = 200 ,  fontSize = 30, color = '473227', offset = cc.p(-25, -10)})
        view:addChild(tabNameLabel)
		local tabtitleTips = display.newImageView(RES_DICT.COMMON_BTN_TIPS, 242, 30)
		tabNameLabel:addChild(tabtitleTips, 1)

		local backBtn = display.newButton(display.SAFE_L + 58, display.height - 54, {n = RES_DICT.COMMON_BTN_BACK})
        backBtn:setName('NAV_BACK')
        view:addChild(backBtn, 5)

        local leftBtn = display.newButton(0, 0, {n = RES_DICT.COMMON_BTN_SWITCH, tag = -1, isFlipX = true})
        leftBtn:setScale(1.4)
        leftBtn:runAction(cc.RepeatForever:create(cc.Sequence:create(
            cc.ScaleTo:create(1, 1.8),
            cc.ScaleTo:create(1, 1.4)
        )))
		display.commonUIParams(leftBtn, {po = cc.p(display.SAFE_L + 40, display.cy)})
        view:addChild(leftBtn)

		local rightBtn = display.newButton(0, 0, {n = RES_DICT.COMMON_BTN_SWITCH, tag = 1})
        rightBtn:setScale(1.4)
        rightBtn:runAction(cc.RepeatForever:create(cc.Sequence:create(
            cc.ScaleTo:create(1, 1.8),
            cc.ScaleTo:create(1, 1.4)
        )))
		display.commonUIParams(rightBtn, {po = cc.p(display.SAFE_R - 40, display.cy)})
        view:addChild(rightBtn)

        local rightBtnSize = rightBtn:getContentSize()
        local redPointImg = display.newImageView(RES_DICT.RED_IMG, display.SAFE_R - 14, display.cy + 40)
        redPointImg:setVisible(false)
        view:addChild(redPointImg)

		return {
            view                    = view,
            BG                      = BG,
            contentView             = contentView,
            tabNameLabel            = tabNameLabel,
            backBtn                 = backBtn,
            timeLabel               = timeLabel,
            leftBtn                 = leftBtn,
            rightBtn                = rightBtn,
            redPointImg             = redPointImg,
        }
    end
	xTry(function ( )
        self.viewData = CreateView()
	end, __G__TRACKBACK__)
end

return ReturnWelfareView