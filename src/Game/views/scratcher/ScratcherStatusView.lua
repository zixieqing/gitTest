local GameScene = require( "Frame.GameScene" )
---@class ScratcherStatusView : GameScene
local ScratcherStatusView = class("ScratcherStatusView", GameScene)

local RES_DICT = {
    COMMON_BG                       = _res('ui/scratcher/cardmatch_data_bg.png'),
    COMMON_BTN_ORANGE_BIG           = _res('ui/common/common_btn_orange_big.png'),
    REWARDS_ICON                    = CommonUtils.GetGoodsIconPathById(701166),
    COMMON_BTN_TIPS                 = _res('ui/common/common_btn_tips.png'),
    CARDMATCH_VOTE_BAR_1            = _res('ui/scratcher/cardmatch_vote_bar_1.png'),
    CARDMATCH_VOTE_BAR_2            = _res('ui/scratcher/cardmatch_vote_bar_2.png'),
    CARDMATCH_VOTE_BAR_BG           = _res('ui/scratcher/cardmatch_vote_bar_bg.png'),
    CARDMATHCH_WORDS_CHAMPION       = _res('ui/scratcher/cardmathch_words_champion.png'),
}

function ScratcherStatusView:ctor( ... )
	GameScene.ctor(self, 'Game.views.scratcher.ScratcherStatusView')
	self.args = unpack({...}) or {}

	self:InitUI()
end

function ScratcherStatusView:InitUI()
    local function CreateView()
        local view = CLayout:create(display.size)
        display.commonUIParams(view, {po = display.center})
        self:addChild(view)    

        local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 120))
        eaterLayer:setTouchEnabled(true)
        eaterLayer:setContentSize(display.size)
        eaterLayer:setPosition(cc.p(display.cx, display.cy))
        view:addChild(eaterLayer)

        ------------------Panel_1 start-------------------
        local Panel_1 = display.newLayer(display.cx - 604, display.cy - 365,
        {
            ap = display.LEFT_BOTTOM,
            size = cc.size(1220, 690),
            enable = true,
        })
        view:addChild(Panel_1)

        local Image_1 = display.newImageView(RES_DICT.COMMON_BG, 610, 345,
        {
            ap = display.CENTER,
            enable = true,
        })
        Panel_1:addChild(Image_1)

        local Text_1 = display.newLabel(36, 648,
        {
            text = __('飨灵数据比拼'),
            ap = display.LEFT_CENTER,
            fontSize = 38,
            color = '#5b3c25',
            font = TTF_GAME_FONT, ttf = true,
        })
        Panel_1:addChild(Text_1)

        local Text_2 = display.newLabel(37, 607,
        {
            text = __('数据比拼每日0点更新最新统计'),
            ap = display.LEFT_CENTER,
            fontSize = 22,
            color = '#5b3c25',
        })
        Panel_1:addChild(Text_2)

        local tipsBtn = display.newButton(304, 650,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_TIPS,
            enable = true,
        })
        -- display.commonLabelParams(tipsBtn, fontWithColor(14, {text = ''}))
        Panel_1:addChild(tipsBtn)

        local myBtn = display.newButton(1118, 634,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_ORANGE_BIG,
            enable = true,
        })
        display.commonLabelParams(myBtn, fontWithColor(14, {text = __('我的应援'), fontSize = 24, color = '#ffffff'}))
        Panel_1:addChild(myBtn)

        local previewBtn = display.newButton(900+40, 634+10,
        {
            ap = display.CENTER,
            n = RES_DICT.REWARDS_ICON,
            enable = true,
        })
        display.commonLabelParams(previewBtn, fontWithColor(14, {text = __('获胜奖励'), fontSize = 24, color = '#ffffff', offset = cc.p(0,-40)}))
        previewBtn:getNormalImage():setScale(0.65)
        previewBtn:getSelectedImage():setScale(0.65)
        Panel_1:addChild(previewBtn)

        local image_right = display.newLayer(1032, 299)
        Panel_1:addChild(image_right)

        local image_left = display.newLayer(191, 299)
        Panel_1:addChild(image_left)

        local barBGs = {}
        for i = 1, 7 do
            local barBG = display.newImageView(RES_DICT.CARDMATCH_VOTE_BAR_BG, 611, 537 - (i-1)*83,
            {
                ap = display.CENTER,
            })
            Panel_1:addChild(barBG)
            barBGs[#barBGs + 1] = barBG
        end

        self.safeProgressSpace = 6
        self.safeProgressGap = 1.5
        self.safeProgressWidth = 20
        local progressBarImg = display.newImageView(_res(RES_DICT.CARDMATCH_VOTE_BAR_1))
        local progressBgImg  = display.newImageView(_res(RES_DICT.CARDMATCH_VOTE_BAR_BG))
        local progressScalle = (progressBgImg:getContentSize().width - self.safeProgressWidth*2 - self.safeProgressGap*2 - self.safeProgressSpace) / progressBarImg:getContentSize().width
        local progressSafeSize = cc.size(self.safeProgressWidth+self.safeProgressGap, progressBarImg:getContentSize().height)
        local progressSafeRect = cc.rect(2,2,233,29)

        local leftBars = {}
        for i = 1, 7 do
            local barPos = cc.p(611+self.safeProgressGap - self.safeProgressSpace/2, 537 - (i-1)*83)
            if self.safeProgressWidth > 0 then
                local leftImg = display.newImageView(RES_DICT.CARDMATCH_VOTE_BAR_1, 0, barPos.y, {ap = display.LEFT_CENTER, scale9 = true, size = progressSafeSize, capInsets = progressSafeRect})
                leftImg:setPositionX(barBGs[i]:getPositionX() - progressBgImg:getContentSize().width/2 + self.safeProgressGap)
                Panel_1:addChild(leftImg)
            end
            local leftBar = CProgressBar:create(RES_DICT.CARDMATCH_VOTE_BAR_1)
            leftBar:setAnchorPoint(display.CENTER)
            leftBar:setDirection(eProgressBarDirectionLeftToRight)
            leftBar:setPosition(barPos)
            leftBar:setScaleX(progressScalle)
            Panel_1:addChild(leftBar)
            leftBars[#leftBars + 1] = leftBar
            leftBar:setTag(i)
        end

        local rightBars = {}
        for i = 1, 7 do
            local barPos = cc.p(611-self.safeProgressGap + self.safeProgressSpace/2, 537 - (i-1)*83)
            if self.safeProgressWidth > 0 then
                local rightImg = display.newImageView(RES_DICT.CARDMATCH_VOTE_BAR_2, 0, barPos.y, {ap = display.RIGHT_CENTER, scale9 = true, size = progressSafeSize, capInsets = progressSafeRect})
                rightImg:setPositionX(barBGs[i]:getPositionX() + progressBgImg:getContentSize().width/2 - self.safeProgressGap)
                Panel_1:addChild(rightImg)
            end
            local rightBar = CProgressBar:create(RES_DICT.CARDMATCH_VOTE_BAR_2)
            rightBar:setAnchorPoint(display.CENTER)
            rightBar:setDirection(eProgressBarDirectionRightToLeft)
            rightBar:setPosition(barPos)
            rightBar:setScaleX(progressScalle)
            Panel_1:addChild(rightBar)
            rightBars[#rightBars + 1] = rightBar
            rightBar:setTag(i + 10)
        end

        local taskNameLabels = {}
        for i = 1, 7 do
            local taskNameLabel = display.newLabel(378, 570 - (i-1)*83,
            {
                text = '',
                ap = display.LEFT_CENTER,
                fontSize = 22,
                color = '#5b3c25',
            })
            Panel_1:addChild(taskNameLabel)  
            taskNameLabels[#taskNameLabels + 1] = taskNameLabel  
        end

        local leftNums = {}
        for i = 1, 7 do
            local leftNum = display.newLabel(378, 537 - (i-1)*83,
            {
                text = '',
                ap = display.RIGHT_CENTER,
                fontSize = 22,
                color = '#5b3c25',
            })
            Panel_1:addChild(leftNum)  
            leftNums[#leftNums + 1] = leftNum  
        end

        local rightNums = {}
        for i = 1, 7 do
            local rightNum = display.newLabel(613, 537 - (i-1)*83,
            {
                text = '',
                ap = display.LEFT_CENTER,
                fontSize = 22,
                color = '#5b3c25',
            })
            Panel_1:addChild(rightNum)  
            rightNums[#rightNums + 1] = rightNum  
        end

        local leftVoteLabel = display.newLabel(192, 63,
        {
            text = '',
            ap = display.CENTER,
            fontSize = 50,
            color = '#fed780',
            font = TTF_GAME_FONT, ttf = true,
            outline = '#5b3c25',
            outlineSize = 4,
        })
        Panel_1:addChild(leftVoteLabel)

        local rightVoteLabel = display.newLabel(1032, 63,
        {
            text = '',
            ap = display.CENTER,
            fontSize = 50,
            color = '#fed780',
            font = TTF_GAME_FONT, ttf = true,
            outline = '#5b3c25',
            outlineSize = 4,
        })
        Panel_1:addChild(rightVoteLabel)

        local leftChampionImage = display.newImageView(RES_DICT.CARDMATHCH_WORDS_CHAMPION, 192, 183,
        {
            ap = display.CENTER,
        })
        Panel_1:addChild(leftChampionImage)
        leftChampionImage:setVisible(false)

        local rightChampionImage = display.newImageView(RES_DICT.CARDMATHCH_WORDS_CHAMPION, 1037, 183,
        {
            ap = display.CENTER,
        })
        Panel_1:addChild(rightChampionImage)
        rightChampionImage:setVisible(false)

        -------------------Panel_1 end--------------------
        return {
            view                    = view,
            eaterLayer              = eaterLayer,
            Panel_1                 = Panel_1,
            Image_1                 = Image_1,
            Text_1                  = Text_1,
            Text_2                  = Text_2,
            tipsBtn                 = tipsBtn,
            myBtn                   = myBtn,
            previewBtn              = previewBtn,
            image_left              = image_left,
            image_right             = image_right,
            barBGs                  = barBGs,
            leftBars                = leftBars,
            rightBars               = rightBars,
            taskNameLabels          = taskNameLabels,
            leftNums                = leftNums,
            rightNums               = rightNums,
            leftVoteLabel           = leftVoteLabel,
            rightVoteLabel          = rightVoteLabel,
            leftChampionImage       = leftChampionImage,
            rightChampionImage      = rightChampionImage,
        }
    end

	xTry(function ( )
        self.viewData = CreateView()
	end, __G__TRACKBACK__)
end

function ScratcherStatusView:updateLeftCardImg(cardId)
    self.viewData.image_left:removeAllChildren()
    local imgPath = _res('ui/scratcher/cardmatch_data_card_bg_' .. tostring(cardId))
    self.viewData.image_left:addChild(display.newImageView(imgPath))
end

function ScratcherStatusView:updateRightCardImg(cardId)
    self.viewData.image_right:removeAllChildren()
    local imgPath = _res('ui/scratcher/cardmatch_data_card_bg_' .. tostring(cardId))
    self.viewData.image_right:addChild(display.newImageView(imgPath))
end

return ScratcherStatusView
