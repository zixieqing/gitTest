--[[
    燃战角色详情界面
--]]
local GameScene = require( "Frame.GameScene" )
---@class SaiMoePlayerView :GameScene
local SaiMoePlayerView = class("SaiMoePlayerView", GameScene)
local shareFacade = AppFacade.GetInstance()
local gameMgr = shareFacade:GetManager("GameManager")
local uiMgr = shareFacade:GetManager("UIManager")
local GoodNode = require('common.GoodNode')

local RES_DICT          = {
	COMMON_BG_4                   = _res('ui/common/common_bg_4.png'),
	COMMON_BTN_ORANGE_BIG         = _res('ui/common/common_btn_orange_big.png'),
	COMMON_BTN_WHITE_BIG          = _res('ui/common/common_btn_white_big.png'),
}

function SaiMoePlayerView:ctor( ... )
	GameScene.ctor(self, 'Game.views.saimoe.SaiMoePlayerView')
	self.args = unpack({...}) or {}

	self:InitUI()
end

function SaiMoePlayerView:InitUI()
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 130))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    
	local function CreateView()
        local view = CLayout:create(display.size)
        display.commonUIParams(view, {po = display.center})
        view:setName('SaiMoePlayerView')
        self:addChild(view)

		local drawNode = require('common.CardSkinDrawNode').new({
			skinId = 250370,
			-- coordinateType = COORDINATE_TYPE_HEAD
        })
        view:addChild(drawNode)
        
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

        local unlockLabel = display.newLabel(295, 585,
        {
            text = __('应援活动最终奖励:'),
            ap = display.CENTER,
            fontSize = 26,
            color = '#5b3c25',
        })
        rightView:addChild(unlockLabel)

        local bonusLabel = display.newLabel(295, 349,
        {
            text = __('获胜后将会回馈支持者们奖励：'),
            ap = display.CENTER,
            fontSize = 26,
            color = '#5b3c25',
        })
        rightView:addChild(bonusLabel)

        local tipsLabel = display.newLabel(295, 4,
        {
            text = __('确认支持的飨灵后，活动结束前不可更改'),
            hAlign = display.TAC,
            w = 560,
            ap = display.CENTER_BOTTOM,
            fontSize = 20,
            color = '#5c5c5c',
        })
        rightView:addChild(tipsLabel)

        local supportBtn = display.newButton(407, 88,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_ORANGE_BIG,
            enable = true,
        })
        display.commonLabelParams(supportBtn, fontWithColor(14, {text = __('支持'), fontSize = 24, color = '#ffffff'}))
        rightView:addChild(supportBtn)

        local cancelBtn = display.newButton(175, 88,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_WHITE_BIG,
            enable = true,
        })
        display.commonLabelParams(cancelBtn, fontWithColor(14, {text = __('再想想'), w = 160 , hAlign = display.TAC ,  fontSize = 24, color = '#ffffff'}))
        rightView:addChild(cancelBtn)
        cancelBtn:setOnClickScriptHandler(function(sender)
            PlayAudioByClickNormal()
            shareFacade:UnRegsitMediator("SaiMoePlayerMediator")
        end)

        ------------------rightView end-------------------

		return {
            view                    = view,
            drawNode                = drawNode,
            rightView               = rightView, 
            rightBG                 = rightBG, 
            unlockLabel             = unlockLabel, 
            bonusLabel              = bonusLabel, 
            tipsLabel               = tipsLabel, 
            supportBtn              = supportBtn, 
            cancelBtn               = cancelBtn, 
        }
    end
	xTry(function ( )
        self.viewData = CreateView()
        self:ShowEnterAni()
	end, __G__TRACKBACK__)
end

function SaiMoePlayerView:ShowEnterAni()
    self.viewData.drawNode:setScale(1.3)
    self.viewData.drawNode:runAction(cc.ScaleTo:create(0.2, 1))

    self.viewData.rightView:setOpacity(0)
    self.viewData.rightView:runAction(cc.FadeIn:create(0.25))
end

return SaiMoePlayerView