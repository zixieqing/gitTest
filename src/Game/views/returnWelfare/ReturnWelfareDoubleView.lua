local GameScene = require( "Frame.GameScene" )
---@class ReturnWelfareDoubleView :GameScene
local ReturnWelfareDoubleView = class("ReturnWelfareDoubleView", GameScene)

local app = app
local uiMgr = app.uiMgr

local RES_DICT          = {
    COMMON_BTN_ORANGE               = _res('ui/common/common_btn_orange.png'),
    ACTIVITY_DOUBLE_BG              = _res('ui/home/returnWelfare/activity_double_bg.png'),
    ACTIVITY_DOUBLE_BG_DESCRIBE     = _res('ui/home/returnWelfare/activity_double_bg_describe.png'),
    ACTIVITY_DOUBLE_BG_EXP          = _res('ui/home/returnWelfare/activity_double_bg_exp.png'),
    ACTIVITY_DOUBLE_BG_FB           = _res('ui/home/returnWelfare/activity_double_bg_fb.png'),
    ACTIVITY_DOUBLE_BG_LB           = _res('ui/home/returnWelfare/activity_double_bg_lb.png'),
}


function ReturnWelfareDoubleView:ctor( ... )
	GameScene.ctor(self, 'ReturnWelfareDoubleView')
	self.args = unpack({...}) or {}

	self:InitUI()
end

function ReturnWelfareDoubleView:InitUI()
	local function CreateView()
        local view = CLayout:create(display.size)
        view:setPosition(display.center)
        view:setName('ReturnWelfareDoubleView')
        self:addChild(view)

        local offset = (display.SAFE_RECT.width - 182) / 6
        local start = display.SAFE_L + 91
        local fisrtPosX = start + offset
        local secondPosX = start + offset * 3
        local thirdPosX = start + offset * 5

        local BG1 = display.newNSprite(RES_DICT.ACTIVITY_DOUBLE_BG, fisrtPosX, display.cy - 51,
        {
            ap = display.CENTER,
        })
        view:addChild(BG1)

        local BG2 = display.newNSprite(RES_DICT.ACTIVITY_DOUBLE_BG, secondPosX, display.cy - 51,
        {
            ap = display.CENTER,
        })
        view:addChild(BG2)

        local BG3 = display.newNSprite(RES_DICT.ACTIVITY_DOUBLE_BG, thirdPosX, display.cy - 51,
        {
            ap = display.CENTER,
        })
        view:addChild(BG3)

        local nameBG1 = display.newNSprite(RES_DICT.ACTIVITY_DOUBLE_BG_DESCRIBE, fisrtPosX, display.cy - 198,
        {
            ap = display.CENTER,
        })
        view:addChild(nameBG1)

        local nameBG2 = display.newNSprite(RES_DICT.ACTIVITY_DOUBLE_BG_DESCRIBE, secondPosX, display.cy - 198,
        {
            ap = display.CENTER,
        })
        view:addChild(nameBG2)

        local nameBG3 = display.newNSprite(RES_DICT.ACTIVITY_DOUBLE_BG_DESCRIBE, thirdPosX, display.cy - 198,
        {
            ap = display.CENTER,
        })
        view:addChild(nameBG3)

        local name1 = display.newLabel(fisrtPosX, display.cy - -192,
        {
            text = __('学院补给翻倍'),
            ap = display.CENTER,
            fontSize = 30,
            color = '#be3f00',
            font = TTF_GAME_FONT, ttf = true,
        })
        view:addChild(name1)

        local name2 = display.newLabel(secondPosX, display.cy - -192,
        {
            text = __('独享礼包'),
            ap = display.CENTER,
            fontSize = 30,
            color = '#be3f00',
            font = TTF_GAME_FONT, ttf = true,
        })
        view:addChild(name2)

        local name3 = display.newLabel(thirdPosX, display.cy - -192,
        {
            text = __('经验加成'),
            ap = display.CENTER,
            fontSize = 30,
            color = '#be3f00',
            font = TTF_GAME_FONT, ttf = true,
        })
        view:addChild(name3)

        local desr1 = display.newLabel(fisrtPosX + 6, display.cy - 198,
        {
            text = __('材料获取up!'),
            ap = display.CENTER,
            fontSize = 24,
            color = '#be3f00',
            font = TTF_GAME_FONT, ttf = true,
        })
        view:addChild(desr1)

        local desr2 = display.newLabel(secondPosX + 6, display.cy - 199,
        {
            text = __('更多折扣off!'),
            ap = display.CENTER,
            fontSize = 24,
            color = '#be3f00',
            font = TTF_GAME_FONT, ttf = true,
        })
        view:addChild(desr2)

        local desr3 = display.newLabel(thirdPosX + 6, display.cy - 199,
        {
            text = __('升级速度up!'),
            ap = display.CENTER,
            fontSize = 24,
            color = '#be3f00',
            font = TTF_GAME_FONT, ttf = true,
        })
        view:addChild(desr3)

        local gotoBtn1 = display.newButton(fisrtPosX, display.cy - 273,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_ORANGE,
            enable = true,
        })
        display.commonLabelParams(gotoBtn1, fontWithColor(14, {text = __('点击前往'), fontSize = 24, color = '#ffffff'}))
        view:addChild(gotoBtn1)

        local gotoBtn2 = display.newButton(secondPosX, display.cy - 274,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_ORANGE,
            enable = true,
        })
        display.commonLabelParams(gotoBtn2, fontWithColor(14, {text = __('点击前往'), fontSize = 24, color = '#ffffff'}))
        view:addChild(gotoBtn2)

        local gotoBtn3 = display.newButton(thirdPosX, display.cy - 273,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_ORANGE,
            enable = true,
        })
        display.commonLabelParams(gotoBtn3, fontWithColor(14, {text = __('点击前往'), fontSize = 24, color = '#ffffff'}))
        view:addChild(gotoBtn3)

        local detailImg1 = display.newNSprite(RES_DICT.ACTIVITY_DOUBLE_BG_FB, fisrtPosX, display.cy - 8,
        {
            ap = display.CENTER,
        })
        view:addChild(detailImg1)

        local detailImg2 = display.newNSprite(RES_DICT.ACTIVITY_DOUBLE_BG_LB, secondPosX, display.cy - 8,
        {
            ap = display.CENTER,
        })
        view:addChild(detailImg2)

        local detailImg3 = display.newNSprite(RES_DICT.ACTIVITY_DOUBLE_BG_EXP, thirdPosX, display.cy - 8,
        {
            ap = display.CENTER,
        })
        view:addChild(detailImg3)

		return {
            view                    = view,
            BG1                     = BG1,
            BG2                     = BG2,
            BG3                     = BG3,
            nameBG1                 = nameBG1,
            nameBG2                 = nameBG2,
            nameBG3                 = nameBG3,
            name1                   = name1,
            name2                   = name2,
            name3                   = name3,
            desr1                   = desr1,
            desr2                   = desr2,
            desr3                   = desr3,
            gotoBtn1                = gotoBtn1,
            gotoBtn2                = gotoBtn2,
            gotoBtn3                = gotoBtn3,
            detailImg1              = detailImg1,
            detailImg2              = detailImg2,
            detailImg3              = detailImg3,
        }
    end
	xTry(function ( )
        self.viewData = CreateView()

	end, __G__TRACKBACK__)
end

return ReturnWelfareDoubleView