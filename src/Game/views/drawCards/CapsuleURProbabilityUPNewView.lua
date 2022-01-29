local CapsuleURProbabilityUPNewView = class('CapsuleURProbabilityUPNewView', function ()
    local node = CLayout:create()
    node.name = 'home.CapsuleURProbabilityUPNewView'
    node:enableNodeEvents()
    return node
end)

local app = app
local uiMgr = app.uiMgr

local RES_DICT = {
    RED_IMG                         = _res('ui/common/common_ico_red_point.png'),
    COMMON_TIPS_ICON                = _res('ui/common/common_btn_tips.png'),
    KITCHEN_MAKE_BTN_ORANGE         = _res('ui/home/capsuleNew/URProbabilityUP/kitchen_make_btn_orange.png'),
    YFDARW_BG_BONUS                 = _res('ui/home/capsuleNew/URProbabilityUP/yfdarw_bg_bonus.png'),
    YFDARW_BG_DARWBTN               = _res('ui/home/capsuleNew/URProbabilityUP/yfdarw_bg_darwbtn.png'),
    YFDARW_BG_LINE                  = _res('ui/home/capsuleNew/URProbabilityUP/yfdarw_bg_line.png'),
    YFDARW_BG_REWARD_WORD           = _res('ui/home/capsuleNew/URProbabilityUP/yfdarw_bg_reward_word.png'),
    YFDARW_LINE_1                   = _res('ui/home/capsuleNew/URProbabilityUP/yfdarw_line_1.png'),
    YFDARW_LINE_2                   = _res('ui/home/capsuleNew/URProbabilityUP/yfdarw_line_2.png'),
    YFDARW_TIPS_ARROW               = _res('ui/home/capsuleNew/URProbabilityUP/yfdarw_tips_arrow.png'),
    YFDARW_TIPS                     = _res('ui/home/capsuleNew/URProbabilityUP/yfdarw_tips.png'),
}

function CapsuleURProbabilityUPNewView:ctor( ... )
	local args = unpack({...})
    local size = args.size
    self:setContentSize(size)

    local function CreateView()
        local view = CLayout:create(size)
        view:setPosition(utils.getLocalCenter(self))
        self:addChild(view)
        local width = size.width
        local height = size.height
        local cw = width / 2

        local summonBG = display.newImageView(RES_DICT.YFDARW_BG_DARWBTN, cw, 71,
        {
            ap = display.CENTER,
        })
        view:addChild(summonBG)

        local probabilityBG = display.newImageView(RES_DICT.YFDARW_BG_LINE, cw, 192,
        {
            ap = display.CENTER,
        })
        view:addChild(probabilityBG)

        local onceBtn = display.newButton(cw - 211, 89,
        {
            ap = display.CENTER,
            n = RES_DICT.KITCHEN_MAKE_BTN_ORANGE,
            enable = true,
            tag = 1
        })
        display.commonLabelParams(onceBtn, fontWithColor(14, {text = __('抽一次'), fontSize = 24, color = '#ffffff'}))
        view:addChild(onceBtn)

        local tenBtn = display.newButton(cw + 173, 89,
        {
            ap = display.CENTER,
            n = RES_DICT.KITCHEN_MAKE_BTN_ORANGE,
            enable = true,
            tag = 2
        })
        display.commonLabelParams(tenBtn, fontWithColor(14, {text = __('抽十次'), fontSize = 24, color = '#ffffff'}))
        view:addChild(tenBtn)

        local onceLabel = display.newRichLabel(cw - 211, 33)
        view:addChild(onceLabel)

        local tenLabel = display.newRichLabel(cw + 173, 33)
        view:addChild(tenLabel)

        -------------------desrBG start-------------------
        local desrBG = FilteredSpriteWithOne:create()
        desrBG:setTexture(RES_DICT.YFDARW_BG_BONUS)
        desrBG:setPosition(cw + 346, display.height - 240)
        view:addChild(desrBG)

        local timesLabel = display.newLabel(174, 26,
        {
            text = '',
            ap = display.CENTER,
            fontSize = 24,
            color = '#ffffff',
        })
        desrBG:addChild(timesLabel)

        local upLabel = display.newRichLabel(167, 86)
        desrBG:addChild(upLabel)

        local app = cc.Application:getInstance()
        local target = app:getTargetPlatform()
        if target == cc.PLATFORM_OS_MAC or target == cc.PLATFORM_OS_IPHONE or target == cc.PLATFORM_OS_IPAD or target == cc.PLATFORM_OS_WINDOWS then
            upLabel:setScale(0.5)
        end

        --------------------desrBG end--------------------
        local progress = CProgressBar:create(RES_DICT.YFDARW_LINE_1)
        progress:setBackgroundImage(RES_DICT.YFDARW_LINE_2)
        progress:setDirection(eProgressBarDirectionLeftToRight)
        progress:setAnchorPoint(cc.p(0.5, 0.5))
        progress:setMaxValue(100)
        progress:setValue(0)
        progress:setPosition(cc.p(cw - 60, 209))
        view:addChild(progress)

        local progressLabel = display.newLabel(cw - 60, 209,
        fontWithColor(18, {
            text = '',
        }))
        view:addChild(progressLabel)

        local progressBG = display.newImageView(RES_DICT.YFDARW_TIPS, cw - 410, 236,
        {
            ap = display.CENTER_BOTTOM,
            scale9 = true
        })
        view:addChild(progressBG)

        local progressArrow = display.newImageView(RES_DICT.YFDARW_TIPS_ARROW, progressBG:getContentSize().width / 2, 2,
        {
            ap = display.CENTER,
        })
        progressBG:addChild(progressArrow)

        local currentTopLabel = display.newLabel(85, 52,
        fontWithColor(16, {
            text = '',
        }))
        progressBG:addChild(currentTopLabel)

        local currentBottomLabel = display.newRichLabel(85, 26)
        progressBG:addChild(currentBottomLabel)

        local desrBtn = display.newButton(cw - 485, 161,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_TIPS_ICON,
            enable = true
        })
        view:addChild(desrBtn)

        local desrLabel = display.newLabel(cw - 460, 161,
        {
            text = '',
            ap = display.LEFT_CENTER,
            fontSize = 23,
            color = '#ffffff',
        })
        view:addChild(desrLabel)

        local upicon = require('common.GoodNode').new({
            id = 1,
            showAmount = false,
            callBack = function (sender)
                uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
            end,
        })
        upicon:setScale(0.8, 0.8)
        upicon:setPosition(cw - 456, 226)
        view:addChild(upicon)

        local rewardBtn = display.newButton(cw + 447, 206,
        {
            ap = display.CENTER,
            n = CommonUtils.GetGoodsIconPathById(195120),
            enable = true,
        })
        rewardBtn:setScale(0.7, 0.7)
        view:addChild(rewardBtn)

        local redPointImg = display.newImageView(RES_DICT.RED_IMG, cw + 490, 228)
        redPointImg:setVisible(false)
        view:addChild(redPointImg)

        local rewardLabel = display.newButton(cw + 444, 163,
        {
            ap = display.CENTER,
            n = RES_DICT.YFDARW_BG_REWARD_WORD,
            enable = false,
        })
        display.commonLabelParams(rewardLabel, fontWithColor(14, {text = __('次数奖励'), fontSize = 22, color = '#ffffff'}))
        view:addChild(rewardLabel)

        return {
            view                    = view,
            summonBG                = summonBG,
            probabilityBG           = probabilityBG,
            onceBtn                 = onceBtn,
            tenBtn                  = tenBtn,
            onceLabel               = onceLabel,
            tenLabel                = tenLabel,
            desrBG                  = desrBG,
            timesLabel              = timesLabel,
            upLabel                 = upLabel,
            progress                = progress,
            progressLabel           = progressLabel,
            progressBG              = progressBG,
            progressArrow           = progressArrow,
            currentTopLabel         = currentTopLabel,
            currentBottomLabel      = currentBottomLabel,
            desrBtn                 = desrBtn,
            desrLabel               = desrLabel,
            upicon                  = upicon,
            rewardBtn               = rewardBtn,
            redPointImg             = redPointImg,
            rewardLabel             = rewardLabel,
        }
    end
    xTry(function ( )
        self.viewData = CreateView()
	end, __G__TRACKBACK__)
end

function CapsuleURProbabilityUPNewView:RefreshUI(  )
end

return CapsuleURProbabilityUPNewView
