local GameScene = require( "Frame.GameScene" )
---@class ReturnWelfareDailyView :GameScene
local ReturnWelfareDailyView = class("ReturnWelfareDailyView", GameScene)

local app = app
local uiMgr = app.uiMgr

local RES_DICT          = {
    COMMON_BTN_ORANGE               = _res('ui/common/common_btn_orange.png'),
    RED_IMG                         = _res('ui/common/common_ico_red_point.png'),
    DAY_LIST_BG                     = _res('ui/home/returnWelfare/day_list_bg.png'),
    DAY_LIST_XUANZHONG              = _res('ui/home/returnWelfare/day_list_xuanzhong.png'),
    DAY_SLOGAN_BG                   = _res('ui/home/returnWelfare/day_slogan_bg.png'),
}

function ReturnWelfareDailyView:ctor( ... )
	GameScene.ctor(self, 'ReturnWelfareDailyView')
	self.args = unpack({...}) or {}

	self:InitUI()
end

function ReturnWelfareDailyView:InitUI()
	local function CreateView()
        local view = CLayout:create(display.size)
        view:setPosition(display.center)
        view:setName('ReturnWelfareDailyView')
        self:addChild(view)

        local listBG = display.newImageView(RES_DICT.DAY_LIST_BG, display.cx - -1, 188,
        {
            ap = display.CENTER,
        })
        view:addChild(listBG)
        
        ------------------titleBG start-------------------
        local titleBG = display.newImageView(RES_DICT.DAY_SLOGAN_BG, display.cx - 423, 409,
        {
            ap = display.CENTER,
        })
        view:addChild(titleBG)
        titleBG:setCascadeOpacityEnabled(true)

        local titleLabel = display.newLabel(134, 38,
        {
            text = __('每日登录'),
            ap = display.CENTER,
            fontSize = 60,
            reqW = 250 ,
            color = '#ffe9b4',
            font = TTF_GAME_FONT, ttf = true,
            outline = '#53291c',
        })
        titleBG:addChild(titleLabel)

        -------------------titleBG end--------------------
        local first = display.newRichLabel(display.cx - 453, 306,
        {
            -- text = '',
            -- ap = display.CENTER,
            -- fontSize = 26,
            -- color = '#ffffff',
            -- font = TTF_GAME_FONT, ttf = true,
            -- outline = '#6d544c',
        })
        view:addChild(first)

        local second = display.newRichLabel(display.cx - 302, 306,
        {
            -- text = '',
            -- ap = display.CENTER,
            -- fontSize = 26,
            -- color = '#ffffff',
            -- font = TTF_GAME_FONT, ttf = true,
            -- outline = '#6d544c',
        })
        view:addChild(second)

        local third = display.newRichLabel(display.cx - 151, 306,
        {
            -- text = '',
            -- ap = display.CENTER,
            -- fontSize = 26,
            -- color = '#ffffff',
            -- font = TTF_GAME_FONT, ttf = true,
            -- outline = '#6d544c',
        })
        view:addChild(third)

        local fourth = display.newRichLabel(display.cx - 0, 306,
        {
            -- text = '',
            -- ap = display.CENTER,
            -- fontSize = 26,
            -- color = '#ffffff',
            -- font = TTF_GAME_FONT, ttf = true,
            -- outline = '#6d544c',
        })
        view:addChild(fourth)

        local fifth = display.newRichLabel(display.cx - -153, 306,
        {
            -- text = '',
            -- ap = display.CENTER,
            -- fontSize = 26,
            -- color = '#ffffff',
            -- font = TTF_GAME_FONT, ttf = true,
            -- outline = '#6d544c',
        })
        view:addChild(fifth)

        local sixth = display.newRichLabel(display.cx - -305, 306,
        {
            -- text = '',
            -- ap = display.CENTER,
            -- fontSize = 26,
            -- color = '#ffffff',
            -- font = TTF_GAME_FONT, ttf = true,
            -- outline = '#6d544c',
        })
        view:addChild(sixth)

        local seventh = display.newRichLabel(display.cx - -457, 306,
        {
            -- text = '',
            -- ap = display.CENTER,
            -- fontSize = 26,
            -- color = '#ffffff',
            -- font = TTF_GAME_FONT, ttf = true,
            -- outline = '#6d544c',
        })
        view:addChild(seventh)

        local todayImg = display.newNSprite(RES_DICT.DAY_LIST_XUANZHONG, display.cx - 0, 150,
        {
            ap = display.CENTER,
        })
        view:addChild(todayImg)

        local firstBtn = display.newButton(display.cx - 456, 93,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_ORANGE,
            enable = true,
        })
        -- display.commonLabelParams(firstBtn, fontWithColor(14, {text = '', fontSize = 24, color = '#414146'}))
        view:addChild(firstBtn)

        local secondBtn = display.newButton(display.cx - 304, 93,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_ORANGE,
            enable = true,
        })
        -- display.commonLabelParams(secondBtn, fontWithColor(14, {text = '', fontSize = 24, color = '#414146'}))
        view:addChild(secondBtn)

        local thirdBtn = display.newButton(display.cx - 152, 93,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_ORANGE,
            enable = true,
        })
        -- display.commonLabelParams(thirdBtn, fontWithColor(14, {text = '', fontSize = 24, color = '#414146'}))
        view:addChild(thirdBtn)

        local fourthBtn = display.newButton(display.cx - 0, 93,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_ORANGE,
            enable = true,
        })
        -- display.commonLabelParams(fourthBtn, fontWithColor(14, {text = '', fontSize = 24, color = '#414146'}))
        view:addChild(fourthBtn)

        local fifthBtn = display.newButton(display.cx - -152, 93,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_ORANGE,
            enable = true,
        })
        -- display.commonLabelParams(fifthBtn, fontWithColor(14, {text = '', fontSize = 24, color = '#414146'}))
        view:addChild(fifthBtn)

        local sixthBtn = display.newButton(display.cx - -304, 93,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_ORANGE,
            enable = true,
        })
        -- display.commonLabelParams(sixthBtn, fontWithColor(14, {text = '', fontSize = 24, color = '#414146'}))
        view:addChild(sixthBtn)

        local seventhBtn = display.newButton(display.cx - -456, 93,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_ORANGE,
            enable = true,
        })
        -- display.commonLabelParams(seventhBtn, fontWithColor(14, {text = '', fontSize = 24, color = '#414146'}))
        view:addChild(seventhBtn)

        local drawBtnSize = firstBtn:getContentSize()
        local drawBtns = {firstBtn, secondBtn, thirdBtn, fourthBtn, fifthBtn, sixthBtn, seventhBtn}
        for k,v in pairs(drawBtns) do
            local redPointImg = display.newImageView(RES_DICT.RED_IMG, drawBtnSize.width - 6, drawBtnSize.height - 4)
            redPointImg:setVisible(false)
            v:addChild(redPointImg)
            v.redPointImg = redPointImg
        end

		return {
            view                    = view,
            listBG                  = listBG,
            titleBG                 = titleBG,
            titleLabel              = titleLabel,
            first                   = first,
            second                  = second,
            third                   = third,
            fourth                  = fourth,
            fifth                   = fifth,
            sixth                   = sixth,
            seventh                 = seventh,
            todayImg                = todayImg,
            firstBtn                = firstBtn,
            secondBtn               = secondBtn,
            thirdBtn                = thirdBtn,
            fourthBtn               = fourthBtn,
            fifthBtn                = fifthBtn,
            sixthBtn                = sixthBtn,
            seventhBtn              = seventhBtn,
            timeLabels              = {first, second, third, fourth, fifth, sixth, seventh},
            drawBtns                = drawBtns
        }
    end
	xTry(function ( )
        self.viewData = CreateView()

	end, __G__TRACKBACK__)
end

return ReturnWelfareDailyView