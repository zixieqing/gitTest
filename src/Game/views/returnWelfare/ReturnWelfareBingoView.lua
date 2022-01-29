local GameScene = require( "Frame.GameScene" )
---@class ReturnWelfareBingoView :GameScene
local ReturnWelfareBingoView = class("ReturnWelfareBingoView", GameScene)

local app = app
local uiMgr = app.uiMgr

local RES_DICT          = {
    COMMON_BTN_GREEN                = _res('ui/common/common_btn_green.png'),
    COMMON_LIGHT                    = _res('ui/common/common_light.png'),
    COMMON_ARROW                    = _res('ui/common/common_arrow.png'),
    RED_IMG                         = _res('ui/common/common_ico_red_point.png'),
    COMMON_TITLE_5                  = _res('ui/common/common_title_5.png'),
    ALLROUND_BG_SIDEBAR             = _res('ui/home/allround/allround_bg_sidebar.png'),
    ALLROUND_BG_SIDEBAR_LINE        = _res('ui/home/allround/allround_bg_sidebar_line.png'),
    PRINTING_BOX_NAME               = _res('ui/home/returnWelfare/printing_box_name.png'),
    PRINTING_BOX_NAME_COMPLETE      = _res('ui/home/returnWelfare/printing_box_name_complete.png'),
    PRINTING_ICON_1                 = _res('ui/home/returnWelfare/printing_icon_1.png'),
    PRINTING_ICON_2                 = _res('ui/home/returnWelfare/printing_icon_2.png'),
    PRINTING_ICON_3                 = _res('ui/home/returnWelfare/printing_icon_3.png'),
    PRINTING_ICON_4                 = _res('ui/home/returnWelfare/printing_icon_4.png'),
    PRINTING_TASK_BG                = _res('ui/home/returnWelfare/printing_task_bg.png'),
    PRINTING_ICON_FLOWER            = _res('ui/home/returnWelfare/printing_icon_flower'),
    PRINTING_ICON_FLOWER_2          = _res('ui/home/returnWelfare/printing_icon_flower_2'),
    TASK_BG                         = _res('ui/home/returnWelfare/task_bg.png'),
    PRINTING_LINE_1      			= _res('ui/home/returnWelfare/printing_line_1.png'),
    PRINTING_LINE_2      			= _res('ui/home/returnWelfare/printing_line_2.png'),
}

function ReturnWelfareBingoView:ctor( ... )
	GameScene.ctor(self, 'ReturnWelfareBingoView')
	self.args = unpack({...}) or {}

	self:InitUI()
end

function ReturnWelfareBingoView:InitUI()
	local function CreateView()
        local view = CLayout:create(display.size)
        view:setPosition(display.center)
        view:setName('ReturnWelfareBingoView')
        self:addChild(view)

        local taskBG = display.newNSprite(RES_DICT.TASK_BG, display.cx - 91, display.cy - 45,
        {
            ap = display.CENTER,
        })
        view:addChild(taskBG)

        local bingo1 = display.newNSprite(RES_DICT.PRINTING_ICON_1, display.cx - 437, display.cy - -168,
        {
            ap = display.CENTER,
        })
        view:addChild(bingo1)

        local bingo2 = display.newNSprite(RES_DICT.PRINTING_ICON_1, display.cx - 361, display.cy - -168,
        {
            ap = display.CENTER,
        })
        view:addChild(bingo2)

        local bingo3 = display.newNSprite(RES_DICT.PRINTING_ICON_1, display.cx - 285, display.cy - -168,
        {
            ap = display.CENTER,
        })
        view:addChild(bingo3)

        local bingo4 = display.newNSprite(RES_DICT.PRINTING_ICON_1, display.cx - 209, display.cy - -168,
        {
            ap = display.CENTER,
        })
        view:addChild(bingo4)

        local bingo5 = display.newNSprite(RES_DICT.PRINTING_ICON_2, display.cx - 437, display.cy - -93,
        {
            ap = display.CENTER,
        })
        view:addChild(bingo5)

        local bingo6 = display.newNSprite(RES_DICT.PRINTING_ICON_2, display.cx - 361, display.cy - -93,
        {
            ap = display.CENTER,
        })
        view:addChild(bingo6)

        local bingo7 = display.newNSprite(RES_DICT.PRINTING_ICON_2, display.cx - 285, display.cy - -93,
        {
            ap = display.CENTER,
        })
        view:addChild(bingo7)

        local bingo8 = display.newNSprite(RES_DICT.PRINTING_ICON_2, display.cx - 209, display.cy - -93,
        {
            ap = display.CENTER,
        })
        view:addChild(bingo8)

        local bingo9 = display.newNSprite(RES_DICT.PRINTING_ICON_3, display.cx - 437, display.cy - -18,
        {
            ap = display.CENTER,
        })
        view:addChild(bingo9)

        local bingo10 = display.newNSprite(RES_DICT.PRINTING_ICON_3, display.cx - 361, display.cy - -18,
        {
            ap = display.CENTER,
        })
        view:addChild(bingo10)

        local bingo11 = display.newNSprite(RES_DICT.PRINTING_ICON_3, display.cx - 285, display.cy - -18,
        {
            ap = display.CENTER,
        })
        view:addChild(bingo11)

        local bingo12 = display.newNSprite(RES_DICT.PRINTING_ICON_3, display.cx - 209, display.cy - -18,
        {
            ap = display.CENTER,
        })
        view:addChild(bingo12)

        local bingo13 = display.newNSprite(RES_DICT.PRINTING_ICON_4, display.cx - 437, display.cy - 57,
        {
            ap = display.CENTER,
        })
        view:addChild(bingo13)

        local bingo14 = display.newNSprite(RES_DICT.PRINTING_ICON_4, display.cx - 361, display.cy - 57,
        {
            ap = display.CENTER,
        })
        view:addChild(bingo14)

        local bingo15 = display.newNSprite(RES_DICT.PRINTING_ICON_4, display.cx - 285, display.cy - 57,
        {
            ap = display.CENTER,
        })
        view:addChild(bingo15)

        local bingo16 = display.newNSprite(RES_DICT.PRINTING_ICON_4, display.cx - 209, display.cy - 57,
        {
            ap = display.CENTER,
        })
        view:addChild(bingo16)

        local label = display.newLabel(0,0,
        fontWithColor(6, {
            text = __('提示：完成右侧任务收集印花，将印花贴在上方完成连线获取奖励。（任意横\\竖\\斜连续四朵花）'),
            ap = display.CENTER,
            fontSize = 20,
            w = 400
        }))
        local labelSize = display.getLabelContentSize(label)
        local tipLayout = display.newLayer(0,0, { size =labelSize })
        label:setPosition(labelSize.width/2,labelSize.height/2)
        tipLayout:addChild(label)

        local tipsLabel = CListView:create(cc.size(400, 90 ))
        tipsLabel:setDirection(eScrollViewDirectionVertical)
        tipsLabel:setAnchorPoint(display.CENTER_TOP)
        tipsLabel:setPosition(display.cx - 325, display.cy - 95)
        view:addChild(tipsLabel)
        tipsLabel:insertNodeAtLast(tipLayout)
        tipsLabel:reloadData()

        local flowerBingo = {true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true}
        for i=1,16 do
            local flower = display.newNSprite(RES_DICT.PRINTING_ICON_FLOWER, display.cx - 437 + 76 * ((i-1) % 4), display.cy + 168 - 75 * math.floor((i-1) / 4),
            {
                ap = display.CENTER,
                tag = i
            })
            view:addChild(flower, 2)
            flowerBingo[i] = flower
        end

        local suppleLabel = display.newLabel(display.cx - 325, display.cy - 177,
        {
            text = __('刷新印花位置'),
            ap = display.CENTER,
            fontSize = 22,
            color = '#5b3c25',
        })
        view:addChild(suppleLabel)

        local suppleBtn = display.newButton(display.cx - 325, display.cy - 131,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_GREEN,
            enable = true,
        })
        -- display.commonLabelParams(suppleBtn, fontWithColor(14, {text = ''}))
        view:addChild(suppleBtn)

        local costLabel = display.newLabel(0, 0, fontWithColor('14', {text = ''}))
        suppleBtn:addChild(costLabel)

        local costIcon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(DIAMOND_ID)), 0, 0)
        costIcon:setScale(0.2)
        suppleBtn:addChild(costIcon)

        local time = display.newLabel(display.cx - 333, display.cy - -233,
        {
            text = '',
            ap = display.LEFT_CENTER,
            fontSize = 22,
            color = '#ffffff',
            font = TTF_GAME_FONT, ttf = true,
            outline = '#5b3c25',
        })
        view:addChild(time)

        local reset = display.newLabel(display.cx - 343, display.cy - -233,
        {
            text = __('活动重置'),
            ap = display.RIGHT_CENTER,
            fontSize = 22,
            color = '#5b3c25',
            font = TTF_GAME_FONT, ttf = true,
        })
        view:addChild(reset)

        -----------------allRoundBG start-----------------
        local allRoundBG = display.newNSprite(RES_DICT.ALLROUND_BG_SIDEBAR, display.cx - -495, display.cy - 53,
        {
            ap = display.CENTER,
        })
        view:addChild(allRoundBG)

        local guess = display.newLabel(86, 610,
        {
            text = __('猜你想去：'),
            ap = display.CENTER,
            fontSize = 20,
            color = '#ffddb4',
            w = 150
        })
        allRoundBG:addChild(guess)

        local line = display.newNSprite(RES_DICT.ALLROUND_BG_SIDEBAR_LINE, 82, 586,
        {
            ap = display.CENTER,
        })
        allRoundBG:addChild(line)

        ------------------allRoundBG end------------------
        
	    local boxTitleLabel = display.newButton(display.cx - 322, display.cy - 205,
	    {
	    	ap = display.CENTER,
	    	n = RES_DICT.COMMON_TITLE_5,
	    	scale9 = true ,
	    	enable = false,
	    })
	    display.commonLabelParams(boxTitleLabel, fontWithColor(16, {text = __('连线奖励') , paddingW = 20 }))
        view:addChild(boxTitleLabel, 2)




        local light1 = display.newNSprite(RES_DICT.COMMON_LIGHT, display.cx - 456, display.cy - 266,
        {
            ap = display.CENTER,
        })
        light1:setScale(0.25)
        view:addChild(light1)

        local light2 = display.newNSprite(RES_DICT.COMMON_LIGHT, display.cx - 322, display.cy - 261,
        {
            ap = display.CENTER,
        })
        light2:setScale(0.25)
        view:addChild(light2)

        local light3 = display.newNSprite(RES_DICT.COMMON_LIGHT, display.cx - 191, display.cy - 261,
        {
            ap = display.CENTER,
        })
        light3:setScale(0.25)
        view:addChild(light3)

        local box1 = FilteredSpriteWithOne:create()
        box1:setTexture(CommonUtils.GetGoodsIconPathById(195118))
        box1:setPosition(display.cx - 457, display.cy - 270)
        box1:setScale(0.5, 0.5)
        view:addChild(box1)

        local box2 = FilteredSpriteWithOne:create()
        box2:setTexture(CommonUtils.GetGoodsIconPathById(195119))
        box2:setPosition(display.cx - 323, display.cy - 265)
        box2:setScale(0.6, 0.6)
        view:addChild(box2)

        local box3 = FilteredSpriteWithOne:create()
        box3:setTexture(CommonUtils.GetGoodsIconPathById(195120))
        box3:setPosition(display.cx - 191, display.cy - 265)
        box3:setScale(0.6, 0.6)
        view:addChild(box3)

        local box = {box1, box2, box3}
        for i=1,3 do
            local redPointImg = display.newImageView(RES_DICT.RED_IMG, box[i]:getPositionX() + 32 + i * 4, box[i]:getPositionY() + 26)
            redPointImg:setVisible(false)
            view:addChild(redPointImg)
            box[i].redPointImg = redPointImg
        end

        local boxDesr1 = display.newButton(display.cx - 457, display.cy - 304,
        {
            ap = display.CENTER,
            n = RES_DICT.PRINTING_BOX_NAME_COMPLETE,
            enable = true,
        })
        display.commonLabelParams(boxDesr1, {text = '', fontSize = 20, color = '#ffffff'})
        view:addChild(boxDesr1)

        local boxDesr2 = display.newButton(display.cx - 325, display.cy - 304,
        {
            ap = display.CENTER,
            n = RES_DICT.PRINTING_BOX_NAME,
            enable = true,
        })
        display.commonLabelParams(boxDesr2, {text = '', fontSize = 20, color = '#ffffff'})
        view:addChild(boxDesr2)

        local boxDesr3 = display.newButton(display.cx - 195, display.cy - 304,
        {
            ap = display.CENTER,
            n = RES_DICT.PRINTING_BOX_NAME,
            enable = true,
        })
        display.commonLabelParams(boxDesr3, {text = '', fontSize = 20, color = '#ffffff'})
        view:addChild(boxDesr3)

        local complete1 = display.newNSprite(RES_DICT.COMMON_ARROW, display.cx - 456, display.cy - 266,
        {
            ap = display.CENTER,
        })
        view:addChild(complete1)

        local complete2 = display.newNSprite(RES_DICT.COMMON_ARROW, display.cx - 326, display.cy - 261,
        {
            ap = display.CENTER,
        })
        view:addChild(complete2)

        local complete3 = display.newNSprite(RES_DICT.COMMON_ARROW, display.cx - 198, display.cy - 261,
        {
            ap = display.CENTER,
        })
        view:addChild(complete3)

        local boxLayer1 = display.newLayer(display.cx - 508, display.cy - 318,
        {
            ap = display.LEFT_BOTTOM,
            size = cc.size(100, 100),
            enable = true,
            color = cc.r4b(0),
        })
        boxLayer1:setTag(1)
        view:addChild(boxLayer1)

        local boxLayer2 = display.newLayer(display.cx - 374, display.cy - 318,
        {
            ap = display.LEFT_BOTTOM,
            size = cc.size(100, 100),
            enable = true,
            color = cc.r4b(0),
        })
        boxLayer2:setTag(2)
        view:addChild(boxLayer2)

        local boxLayer3 = display.newLayer(display.cx - 243, display.cy - 318,
        {
            ap = display.LEFT_BOTTOM,
            size = cc.size(100, 100),
            enable = true,
            color = cc.r4b(0),
        })
        boxLayer3:setTag(3)
        view:addChild(boxLayer3)

        local scrollView = CScrollView:create(cc.size(440, 558))
        scrollView:setDirection(eScrollViewDirectionVertical)
        scrollView:setAnchorPoint(display.LEFT_BOTTOM)
        scrollView:setPosition(cc.p(display.cx - 76, display.cy - 307))
        view:addChild(scrollView)
        -- scrollView:setBackgroundColor(cc.c3b(100,100,200))

        local functionLayer = CListView:create(cc.size(167, 570))
        functionLayer:setBounceable(true)
        functionLayer:setDirection(eScrollViewDirectionVertical)
        display.commonUIParams(functionLayer, {ap = display.LEFT_BOTTOM, po = cc.p(display.cx + 418, display.cy - 361)})
        view:addChild(functionLayer)

		return {
            view                    = view,
            taskBG                  = taskBG,
            bingo1                  = bingo1,
            bingo2                  = bingo2,
            bingo3                  = bingo3,
            bingo4                  = bingo4,
            bingo5                  = bingo5,
            bingo6                  = bingo6,
            bingo7                  = bingo7,
            bingo8                  = bingo8,
            bingo9                  = bingo9,
            bingo10                 = bingo10,
            bingo11                 = bingo11,
            bingo12                 = bingo12,
            bingo13                 = bingo13,
            bingo14                 = bingo14,
            bingo15                 = bingo15,
            bingo16                 = bingo16,
            tipsLabel               = tipsLabel,
            flowerBingo             = flowerBingo,
            suppleLabel             = suppleLabel,
            suppleBtn               = suppleBtn,
            costLabel               = costLabel,
            costIcon                = costIcon,
            time                    = time,
            reset                   = reset,
            allRoundBG              = allRoundBG,
            guess                   = guess,
            line                    = line,
            light1                  = light1,
            light2                  = light2,
            light3                  = light3,
            boxLight                = {light1, light2, light3},
            box1                    = box1,
            box2                    = box2,
            box3                    = box3,
            box                     = box,
            boxDesr1                = boxDesr1,
            boxDesr2                = boxDesr2,
            boxDesr3                = boxDesr3,
            boxDesr                 = {boxDesr1, boxDesr2, boxDesr3},
            complete1               = complete1,
            complete2               = complete2,
            complete3               = complete3,
            complete                = {complete1, complete2, complete3},
            boxLayer1               = boxLayer1,
            boxLayer2               = boxLayer2,
            boxLayer3               = boxLayer3,
            boxLayer                = {boxLayer1, boxLayer2, boxLayer3},
            scrollView              = scrollView,
            functionLayer           = functionLayer,
        }
    end
	xTry(function ( )
        self.viewData = CreateView()

	end, __G__TRACKBACK__)
end

return ReturnWelfareBingoView