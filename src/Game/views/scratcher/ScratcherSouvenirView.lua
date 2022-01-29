local GameScene = require( "Frame.GameScene" )
---@class ScratcherSouvenirView : GameScene
local ScratcherSouvenirView = class("ScratcherSouvenirView", GameScene)

local RES_DICT = {
    COMMON_ARROW                    = _res('ui/common/common_arrow.png'),
    CARDMATCH_TICKET_BG             = _res('ui/scratcher/cardmatch_ticket_bg.png'),
    PVP_REWARD_BAR_ACTIVE           = _res('ui/pvc/pvp_reward_bar_active.png'),
    PVP_REWARD_BAR_GREY             = _res('ui/pvc/pvp_reward_bar_grey.png'),
}

function ScratcherSouvenirView:ctor( ticketGoodsId )
	GameScene.ctor(self, 'Game.views.scratcher.ScratcherSouvenirView')

	self:InitUI()
end

function ScratcherSouvenirView:InitUI()
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
        local Panel_1 = display.newLayer(display.cx - 446, display.cy - 332,
        {
            ap = display.LEFT_BOTTOM,
            size = cc.size(910, 670),
            enable = true,
        })
        view:addChild(Panel_1)

        local Image_1 = display.newImageView(RES_DICT.CARDMATCH_TICKET_BG, 0, 0,
        {
            ap = display.LEFT_BOTTOM,
            scale9 = true, size = cc.size(910, 670),
            enable = true,
        })
        Panel_1:addChild(Image_1)

        local Text_1 = display.newLabel(89, 78,
        {
            text = __('收集小票进度'),
            ap = display.CENTER,
            fontSize = 24,
            color = '#5b3c25',
            w = 150,
        })
        Panel_1:addChild(Text_1)

        local progressBar = CProgressBar:create(RES_DICT.PVP_REWARD_BAR_ACTIVE)
        progressBar:setBackgroundImage(RES_DICT.PVP_REWARD_BAR_GREY)
        progressBar:setAnchorPoint(display.CENTER)
        progressBar:setDirection(eProgressBarDirectionLeftToRight)
        progressBar:setPosition(cc.p(484, 78))
        Panel_1:addChild(progressBar)

		local reward1 = require('common.GoodNode').new({id = DIAMOND_ID, amount = 1, showAmount = false})
		reward1:setScale(0.8)
		display.commonUIParams(reward1, {po = cc.p(492, 81)})
        Panel_1:addChild(reward1)
        
		local reward2 = require('common.GoodNode').new({id = DIAMOND_ID, amount = 1, showAmount = false})
		reward2:setScale(0.8)
		display.commonUIParams(reward2, {po = cc.p(822, 81)})
        Panel_1:addChild(reward2)
        
        local target1 = display.newLabel(492, 22,
        {
            text = '',
            ap = display.CENTER,
            fontSize = 24,
            color = '#5b3c25',
        })
        Panel_1:addChild(target1)

        local target2 = display.newLabel(822, 22,
        {
            text = '',
            ap = display.CENTER,
            fontSize = 24,
            color = '#5b3c25',
        })
        Panel_1:addChild(target2)

        local reward1GainImage = display.newImageView(RES_DICT.COMMON_ARROW, 492, 81,
        {
            ap = display.CENTER,
        })
        Panel_1:addChild(reward1GainImage)

        local reward2GainImage = display.newImageView(RES_DICT.COMMON_ARROW, 822, 81,
        {
            ap = display.CENTER,
        })
        Panel_1:addChild(reward2GainImage)

        -------------------Panel_1 end--------------------
        return {
            view                    = view,
            eaterLayer              = eaterLayer,
            Panel_1                 = Panel_1,
            Image_1                 = Image_1,
            Text_1                  = Text_1,
            progressBar             = progressBar,
            reward1                 = reward1,
            reward2                 = reward2,
            target1                 = target1,
            target2                 = target2,
            reward1GainImage        = reward1GainImage,
            reward2GainImage        = reward2GainImage,
        }
    end

	xTry(function ( )
	    self.viewData = CreateView()
	end, __G__TRACKBACK__)
end

return ScratcherSouvenirView
