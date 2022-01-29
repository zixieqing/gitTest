local GameScene = require( "Frame.GameScene" )
---@class ReturnWelfareWeeklyView :GameScene
local ReturnWelfareWeeklyView = class("ReturnWelfareWeeklyView", GameScene)

local app = app
local uiMgr = app.uiMgr

local RES_DICT          = {
    COMMON_BG_FLOAT_TEXT            = _res('ui/common/common_bg_float_text.png'),
    COMMON_BG_LIST                  = _res('ui/common/common_bg_list.png'),
    COMMON_BTN_ORANGE               = _res('ui/common/common_btn_orange.png'),
    RED_IMG                         = _res('ui/common/common_ico_red_point.png'),
    WEEK_LIST_BG_1                  = _res('ui/home/returnWelfare/week_list_bg_1.png'),
    WEEK_LIST_BG_2                  = _res('ui/home/returnWelfare/week_list_bg_2.png'),
    WEEK_LIST_SLO_BG                = _res('ui/home/returnWelfare/week_list_slo_bg.png'),
    WEEK_SLOGAN_BG                  = _res('ui/home/returnWelfare/week_slogan_bg.png'),
}


function ReturnWelfareWeeklyView:ctor( ... )
	GameScene.ctor(self, 'ReturnWelfareWeeklyView')
	self.args = unpack({...}) or {}

	self:InitUI()
end

function ReturnWelfareWeeklyView:InitUI()
	local function CreateView()
        local view = CLayout:create(display.size)
        view:setPosition(display.center)
        view:setName('ReturnWelfareWeeklyView')
        self:addChild(view)

        local offset = (display.SAFE_RECT.width - 114) / 8
        local start = display.SAFE_L + 57
        local fisrtPosX = start + offset
        local secondPosX = start + offset * 3
        local thirdPosX = start + offset * 5
        local fourthPosX = start + offset * 7
        local firstBG = display.newNSprite(RES_DICT.WEEK_LIST_BG_1, fisrtPosX, display.cy - 69,
        {
            ap = display.CENTER,
        })
        view:addChild(firstBG)

        local secondBG = display.newNSprite(RES_DICT.WEEK_LIST_BG_1, secondPosX, display.cy - 69,
        {
            ap = display.CENTER,
        })
        view:addChild(secondBG)

        local thirdBG = display.newNSprite(RES_DICT.WEEK_LIST_BG_1, thirdPosX, display.cy - 69,
        {
            ap = display.CENTER,
        })
        view:addChild(thirdBG)

        local fourthBG = display.newNSprite(RES_DICT.WEEK_LIST_BG_1, fourthPosX, display.cy - 69,
        {
            ap = display.CENTER,
        })
        view:addChild(fourthBG)

        local curFirstBG = display.newNSprite(RES_DICT.WEEK_LIST_BG_2, fisrtPosX, display.cy - 69,
        {
            ap = display.CENTER,
        })
        view:addChild(curFirstBG)

        local curSecondBG = display.newNSprite(RES_DICT.WEEK_LIST_BG_2, secondPosX, display.cy - 69,
        {
            ap = display.CENTER,
        })
        view:addChild(curSecondBG)

        local curThirdBG = display.newNSprite(RES_DICT.WEEK_LIST_BG_2, thirdPosX, display.cy - 69,
        {
            ap = display.CENTER,
        })
        view:addChild(curThirdBG)

        local curFourthBG = display.newNSprite(RES_DICT.WEEK_LIST_BG_2, fourthPosX, display.cy - 69,
        {
            ap = display.CENTER,
        })
        view:addChild(curFourthBG)

        local firstDateBG = display.newNSprite(RES_DICT.WEEK_LIST_SLO_BG, fisrtPosX, display.cy - -201,
        {
            ap = display.CENTER,
        })
        view:addChild(firstDateBG)

        local secondDateBG = display.newNSprite(RES_DICT.WEEK_LIST_SLO_BG, secondPosX, display.cy - -201,
        {
            ap = display.CENTER,
        })
        view:addChild(secondDateBG)

        local thirdDateBG = display.newNSprite(RES_DICT.WEEK_LIST_SLO_BG, thirdPosX, display.cy - -201,
        {
            ap = display.CENTER,
        })
        view:addChild(thirdDateBG)

        local fourthDateBG = display.newNSprite(RES_DICT.WEEK_LIST_SLO_BG, fourthPosX, display.cy - -201,
        {
            ap = display.CENTER,
        })
        view:addChild(fourthDateBG)

        local firstDate = display.newLabel(fisrtPosX, display.cy - -195,
        {
            text = '',
            ap = display.CENTER,
            fontSize = 22,
            color = '#ffffff',
            font = TTF_GAME_FONT, ttf = true,
            outline = '#522b1e',
        })
        view:addChild(firstDate)

        local secondDate = display.newLabel(secondPosX, display.cy - -195,
        {
            text = '',
            ap = display.CENTER,
            fontSize = 22,
            color = '#ffffff',
            font = TTF_GAME_FONT, ttf = true,
            outline = '#522b1e',
        })
        view:addChild(secondDate)

        local thirdDate = display.newLabel(thirdPosX, display.cy - -195,
        {
            text = '',
            ap = display.CENTER,
            fontSize = 22,
            color = '#ffffff',
            font = TTF_GAME_FONT, ttf = true,
            outline = '#522b1e',
        })
        view:addChild(thirdDate)

        local fourthDate = display.newLabel(fourthPosX, display.cy - -195,
        {
            text = '',
            ap = display.CENTER,
            fontSize = 22,
            color = '#ffffff',
            font = TTF_GAME_FONT, ttf = true,
            outline = '#522b1e',
        })
        view:addChild(fourthDate)

        local firstListBG = display.newImageView(RES_DICT.COMMON_BG_LIST, fisrtPosX, display.cy - 44,
        {
            ap = display.CENTER,
            scale9 = true, size = cc.size(265, 395),
        })
        view:addChild(firstListBG)

        local secondListBG = display.newImageView(RES_DICT.COMMON_BG_LIST, secondPosX, display.cy - 44,
        {
            ap = display.CENTER,
            scale9 = true, size = cc.size(265, 395),
        })
        view:addChild(secondListBG)

        local thirdListBG = display.newImageView(RES_DICT.COMMON_BG_LIST, thirdPosX, display.cy - 44,
        {
            ap = display.CENTER,
            scale9 = true, size = cc.size(265, 395),
        })
        view:addChild(thirdListBG)

        local fourthListBG = display.newImageView(RES_DICT.COMMON_BG_LIST, fourthPosX, display.cy - 44,
        {
            ap = display.CENTER,
            scale9 = true, size = cc.size(265, 395),
        })
        view:addChild(fourthListBG)

        local costLabels = {true, true, true, true}
        local costIcons = {true, true, true, true}

        local firstBtn = display.newButton(fisrtPosX, display.cy - 312,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_ORANGE,
            enable = true,
        })
        -- display.commonLabelParams(firstBtn, fontWithColor(14, {text = '', fontSize = 24, color = '#ffffff'}))
        view:addChild(firstBtn, 2)

        local costLabel = display.newLabel(0, 0, fontWithColor('14', {text = ''}))
        firstBtn:addChild(costLabel)

        local costIcon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(DIAMOND_ID)), 0, 0)
        costIcon:setScale(0.2)
        firstBtn:addChild(costIcon)
        costLabels[1] = costLabel
        costIcons[1] = costIcon
    
        local secondBtn = display.newButton(secondPosX, display.cy - 312,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_ORANGE,
            enable = true,
        })
        -- display.commonLabelParams(secondBtn, fontWithColor(14, {text = '', fontSize = 24, color = '#ffffff'}))
        view:addChild(secondBtn, 2)

        local costLabel = display.newLabel(0, 0, fontWithColor('14', {text = ''}))
        secondBtn:addChild(costLabel)
    
        local costIcon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(DIAMOND_ID)), 0, 0)
        costIcon:setScale(0.2)
        secondBtn:addChild(costIcon)
        costLabels[2] = costLabel
        costIcons[2] = costIcon
    
        local thirdBtn = display.newButton(thirdPosX, display.cy - 312,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_ORANGE,
            enable = true,
        })
        -- display.commonLabelParams(thirdBtn, fontWithColor(14, {text = '', fontSize = 24, color = '#ffffff'}))
        view:addChild(thirdBtn, 2)

        local costLabel = display.newLabel(0, 0, fontWithColor('14', {text = ''}))
        thirdBtn:addChild(costLabel)
    
        local costIcon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(DIAMOND_ID)), 0, 0)
        costIcon:setScale(0.2)
        thirdBtn:addChild(costIcon)
        costLabels[3] = costLabel
        costIcons[3] = costIcon
    
        local fourthBtn = display.newButton(fourthPosX, display.cy - 312,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_ORANGE,
            enable = true,
        })
        -- display.commonLabelParams(fourthBtn, fontWithColor(14, {text = '', fontSize = 24, color = '#ffffff'}))
        view:addChild(fourthBtn, 2)

        local costLabel = display.newLabel(0, 0, fontWithColor('14', {text = ''}))
        fourthBtn:addChild(costLabel)
    
        local costIcon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(DIAMOND_ID)), 0, 0)
        costIcon:setScale(0.2)
        fourthBtn:addChild(costIcon)
        costLabels[4] = costLabel
        costIcons[4] = costIcon

        local drawBtns = {firstBtn, secondBtn, thirdBtn, fourthBtn}
        local drawBtnSize = firstBtn:getContentSize()
        for k,v in pairs(drawBtns) do
            local redPointImg = display.newImageView(RES_DICT.RED_IMG, drawBtnSize.width - 6, drawBtnSize.height - 4)
            redPointImg:setVisible(false)
            v:addChild(redPointImg)
            v.redPointImg = redPointImg
        end

        ------------------titleBG start-------------------
        local titleBG = display.newNSprite(RES_DICT.WEEK_SLOGAN_BG, display.cx - 19, display.height - 75,
        {
            ap = display.CENTER,
        })
        view:addChild(titleBG)

        local title = display.newLabel(232, 38,
        {
            text = __('回归好礼周周送'),
            ap = display.CENTER,
            fontSize = 60,
            reqW = 430 ,
            color = '#ffffff',
            font = TTF_GAME_FONT, ttf = true,
        })
        titleBG:addChild(title)

        -------------------titleBG end--------------------
        local firstSupple = display.newLabel(fisrtPosX, display.cy - 266,
        {
            text = __('补签'),
            ap = display.CENTER,
            fontSize = 22,
            color = '#ffffff',
        })
        view:addChild(firstSupple)

        local secondSupple = display.newLabel(secondPosX, display.cy - 266,
        {
            text = __('补签'),
            ap = display.CENTER,
            fontSize = 22,
            color = '#ffffff',
        })
        view:addChild(secondSupple)

        local thirdSupple = display.newLabel(thirdPosX, display.cy - 266,
        {
            text = __('补签'),
            ap = display.CENTER,
            fontSize = 22,
            color = '#ffffff',
        })
        view:addChild(thirdSupple)

        local fourthSupple = display.newLabel(fourthPosX, display.cy - 266,
        {
            text = __('补签'),
            ap = display.CENTER,
            fontSize = 22,
            color = '#ffffff',
        })
        view:addChild(fourthSupple)

        local firstCountDown = display.newImageView(RES_DICT.COMMON_BG_FLOAT_TEXT, fisrtPosX, display.cy - 260, {scale = 0.8})
        view:addChild(firstCountDown)
        local secondCountDown = display.newImageView(RES_DICT.COMMON_BG_FLOAT_TEXT, secondPosX, display.cy - 260, {scale = 0.8})
        view:addChild(secondCountDown)
        local thirdCountDown = display.newImageView(RES_DICT.COMMON_BG_FLOAT_TEXT, thirdPosX, display.cy - 260, {scale = 0.8})
        view:addChild(thirdCountDown)
        local fourthCountDown = display.newImageView(RES_DICT.COMMON_BG_FLOAT_TEXT, fourthPosX, display.cy - 260, {scale = 0.8})
        view:addChild(fourthCountDown)

        local firstCountDownLabel = display.newRichLabel(fisrtPosX, display.cy - 260)
        view:addChild(firstCountDownLabel)

        local secondCountDownLabel = display.newRichLabel(secondPosX, display.cy - 260)
        view:addChild(secondCountDownLabel)

        local thirdCountDownLabel = display.newRichLabel(thirdPosX, display.cy - 260)
        view:addChild(thirdCountDownLabel)
        
        local fourthCountDownLabel = display.newRichLabel(fourthPosX, display.cy - 260)
        view:addChild(fourthCountDownLabel)
        
        local gridViews = {true, true, true, true}
        local listBGs = {firstListBG, secondListBG, thirdListBG, fourthListBG}
        for i=1,4 do
            local gridView = CGridView:create(cc.size(260, 390))
            gridView:setAnchorPoint(cc.p(0.5, 0.5))
            gridView:setPosition(cc.p(
                listBGs[i]:getPositionX(),
                listBGs[i]:getPositionY()
            ))
            gridView:setColumns(2)
            gridView:setSizeOfCell(cc.size(130, 120))
            gridView:setAutoRelocate(true)
            gridView:setBounceable(true)
            view:addChild(gridView)
            gridViews[i] = gridView
        end

		return {
            view                    = view,
            firstBG                 = firstBG,
            secondBG                = secondBG,
            thirdBG                 = thirdBG,
            fourthBG                = fourthBG,
            BGs                     = {firstBG, secondBG, thirdBG, fourthBG},
            curFirstBG              = curFirstBG,
            curSecondBG             = curSecondBG,
            curThirdBG              = curThirdBG,
            curFourthBG             = curFourthBG,
            curBGs                  = {curFirstBG, curSecondBG, curThirdBG, curFourthBG},
            firstDateBG             = firstDateBG,
            secondDateBG            = secondDateBG,
            thirdDateBG             = thirdDateBG,
            fourthDateBG            = fourthDateBG,
            dateBGs                 = {firstDateBG, secondDateBG, thirdDateBG, fourthDateBG},
            firstDate               = firstDate,
            secondDate              = secondDate,
            thirdDate               = thirdDate,
            fourthDate              = fourthDate,
            dates                   = {firstDate, secondDate, thirdDate, fourthDate},
            firstListBG             = firstListBG,
            secondListBG            = secondListBG,
            thirdListBG             = thirdListBG,
            fourthListBG            = fourthListBG,
            firstBtn                = firstBtn,
            secondBtn               = secondBtn,
            thirdBtn                = thirdBtn,
            fourthBtn               = fourthBtn,
            drawBtns                = drawBtns,
            titleBG                 = titleBG,
            title                   = title,
            firstSupple             = firstSupple,
            secondSupple            = secondSupple,
            thirdSupple             = thirdSupple,
            fourthSupple            = fourthSupple,
            supples                 = {firstSupple, secondSupple, thirdSupple, fourthSupple},
            firstCountDown          = firstCountDown,
            secondCountDown         = secondCountDown,
            thirdCountDown          = thirdCountDown,
            fourthCountDown         = fourthCountDown,
            countDowns              = {firstCountDown, secondCountDown, thirdCountDown, fourthCountDown},
            firstCountDownLabel     = firstCountDownLabel,
            secondCountDownLabel    = secondCountDownLabel,
            thirdCountDownLabel     = thirdCountDownLabel,
            fourthCountDownLabel    = fourthCountDownLabel,
            countDownLabels         = {firstCountDownLabel, secondCountDownLabel, thirdCountDownLabel, fourthCountDownLabel},
            gridViews               = gridViews,
            costLabels              = costLabels,
            costIcons               = costIcons,
        }
    end
	xTry(function ( )
        self.viewData = CreateView()

	end, __G__TRACKBACK__)
end

return ReturnWelfareWeeklyView