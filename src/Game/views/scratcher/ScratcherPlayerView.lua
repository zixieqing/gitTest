local GameScene = require( "Frame.GameScene" )
---@class ScratcherPlayerView :GameScene
local ScratcherPlayerView = class("ScratcherPlayerView", GameScene)
local shareFacade = AppFacade.GetInstance()
local gameMgr = shareFacade:GetManager("GameManager")
local uiMgr = shareFacade:GetManager("UIManager")
local GoodNode = require('common.GoodNode')

local RES_DICT          = {
    DIALOGUE_BG                     = _res('arts/stage/ui/dialogue_bg_2.png'),
	COMMON_BG_4                     = _res('ui/common/common_bg_4.png'),
	COMMON_BTN_ORANGE_BIG           = _res('ui/common/common_btn_orange_big.png'),
	COMMON_BTN_WHITE_BIG            = _res('ui/common/common_btn_white_big.png'),
}

function ScratcherPlayerView:ctor( ... )
	GameScene.ctor(self, 'Game.views.saimoe.ScratcherPlayerView')
	self.args = unpack({...}) or {}

	self:InitUI()
end

function ScratcherPlayerView:InitUI()
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 130))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    
	local function CreateView()
        local view = CLayout:create(display.size)
        display.commonUIParams(view, {po = display.center})
        view:setName('ScratcherPlayerView')
        self:addChild(view)

		local drawNode = require('common.CardSkinDrawNode').new({
			skinId = CardUtils.GetCardDefaultSkinIdByCardId(self.args.myChoice),
        })
        view:addChild(drawNode)

        local dialogBg = display.newImageView(RES_DICT.DIALOGUE_BG, 367 + display.SAFE_L, display.cy - 150, {tag = 6000})
        view:addChild(dialogBg, 10)

        local messageConf = CONF.FOOD_VOTE.MESSAGE:GetValue(self.args.myChoice)
        local dialogLabel = display.newLabel(70, 140, {ap = cc.p(0, 1), text = tostring(messageConf.msg1), fontSize = 24, color = '#5b3c25', w = 384})
        dialogBg:addChild(dialogLabel)

        -----------------rightView start------------------
        local rightView = display.newLayer(display.cx - -6, display.cy - 335,
        {
            ap = display.LEFT_BOTTOM,
            size = cc.size(578, 646),
            enable = false,
        })
        view:addChild(rightView)

        local rightBG = display.newImageView(RES_DICT.COMMON_BG_4, 292, 321,
        {
            ap = display.CENTER,
            scale9 = true, size = cc.size(584, 651),
            enable = true,
        })
        rightView:addChild(rightBG)

        local bonusLabel = display.newLabel(295, 585,
        {
            text = __('获胜后将会回馈支持者们奖励：'),
            ap = display.CENTER,
            fontSize = 26,
            color = '#5b3c25',
        })
        rightView:addChild(bonusLabel)

        local finalRewards = self.args.finalRewards
        local count = table.nums(finalRewards)
        local goodsIcons = {}
        for i,v in ipairs(finalRewards) do
            local goodsIcon = require('common.GoodNode').new({id = v.goodsId, amount = v.num, showAmount = true})
            goodsIcon:setPosition(cc.p(289 - (count-1)/2*134 + (i-1)*134, 463))
            rightView:addChild(goodsIcon)
            goodsIcons[#goodsIcons + 1] = goodsIcon
        end

        local tipsLabel = display.newLabel(295, 7,
        {
            text = __('确认支持的飨灵后，活动结束前不可更改'),
            ap = display.CENTER_BOTTOM,
            fontSize = 22,
            color = '#5c5c5c',
        })
        rightView:addChild(tipsLabel)

        local supportBtn = display.newButton(407, 88,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_ORANGE_BIG,
            enable = true,
        })
        display.commonLabelParams(supportBtn, fontWithColor(14, {text = __('支持'), fontSize = 30, color = '#ffffff'}))
        rightView:addChild(supportBtn)

        local cancelBtn = display.newButton(175, 88,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_WHITE_BIG,
            enable = true,
        })
        display.commonLabelParams(cancelBtn, fontWithColor(14, {text = __('再想想'), fontSize = 30, color = '#ffffff'}))
        rightView:addChild(cancelBtn)

        ------------------rightView end-------------------

		return {
            view                    = view,
            drawNode                = drawNode,
            rightView               = rightView, 
            rightBG                 = rightBG, 
            bonusLabel              = bonusLabel, 
            tipsLabel               = tipsLabel, 
            supportBtn              = supportBtn, 
            cancelBtn               = cancelBtn, 
            goodsIcons              = goodsIcons,
        }
    end
	xTry(function ( )
        self.viewData = CreateView()
        self:ShowEnterAni()
	end, __G__TRACKBACK__)
end

function ScratcherPlayerView:ShowEnterAni()
    self.viewData.drawNode:setScale(1.3)
    self.viewData.drawNode:runAction(cc.ScaleTo:create(0.2, 1))

    self.viewData.rightView:setOpacity(0)
    self.viewData.rightView:runAction(cc.FadeIn:create(0.25))
end

return ScratcherPlayerView