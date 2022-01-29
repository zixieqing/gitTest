local GameScene = require( "Frame.GameScene" )
---@class ScratcherSelectView : GameScene
local ScratcherSelectView = class("ScratcherSelectView", GameScene)

local RES_DICT = {
    COMMON_BTN_BACK                 = _res('ui/common/common_btn_back.png'),
    COMMON_BTN_ORANGE               = _res('ui/common/common_btn_orange.png'),
    ARROW_IMG = _res('ui/home/recharge/recharge_btn_arrow.png'),
}

function ScratcherSelectView:ctor( ... )
	GameScene.ctor(self, 'Game.views.scratcher.ScratcherSelectView')
	self.args = unpack({...}) or {}

	self:InitUI()
end

function ScratcherSelectView:InitUI()
    local function CreateView()
        local view = CLayout:create(display.size)
        display.commonUIParams(view, {po = display.center})
        self:addChild(view)    

        local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 120))
        eaterLayer:setTouchEnabled(true)
        eaterLayer:setContentSize(display.size)
        eaterLayer:setPosition(cc.p(display.cx, display.cy))
        view:addChild(eaterLayer)

        local Text_1 = display.newLabel(display.cx - -26, display.height - 54,
        {
            text = __('选择您要的刮刮乐飨灵'),
            ap = display.CENTER,
            fontSize = 40,
            color = '#ffffff',
            font = TTF_GAME_FONT, ttf = true,
            outline = '#5b3c25',
            outlineSize = 2,
        })
        view:addChild(Text_1)

        local confirmBtn = display.newButton(display.cx - -26, 79,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_ORANGE,
            enable = true,
        })
        display.commonLabelParams(confirmBtn, fontWithColor(14, {text = __('确定选择')}))
        view:addChild(confirmBtn)

        local Text_2 = display.newLabel(display.cx - -26, 32,
        {
            text = __('选择一个目标飨灵，他的碎片会隐藏在奖池中'),
            ap = display.CENTER,
            fontSize = 22,
            color = '#ffffff',
        })
        view:addChild(Text_2)

        local backBtn = display.newButton(display.SAFE_L + 75, display.height - 53,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_BACK,
            enable = true,
        })
        -- display.commonLabelParams(backBtn, fontWithColor(14, {text = ''}))
        view:addChild(backBtn)

		local targetGridview = CTableView:create(cc.size(display.SAFE_RECT.width, 480))
		targetGridview:setSizeOfCell(cc.size(260, 480))
		targetGridview:setDirection(eScrollViewDirectionHorizontal)
		targetGridview:setAutoRelocate(true)
		view:addChild(targetGridview)
		-- targetGridview:setAnchorPoint(cc.p(0, 1.0))
        targetGridview:setPosition(display.cx, display.cy)
        
        local leftArrowImg  = display.newImageView(RES_DICT.ARROW_IMG, display.SAFE_L + 50, display.cy - 300, {enable = true, scaleX = -1})
        local rightArrowImg = display.newImageView(RES_DICT.ARROW_IMG, display.SAFE_R - 50, display.cy - 300, {enable = true})
        view:addChild(rightArrowImg)
        view:addChild(leftArrowImg)
        rightArrowImg:runAction(cc.RepeatForever:create(cc.Sequence:create(
            cc.MoveBy:create(0.2, cc.p(10,0)),
            cc.MoveBy:create(0.2, cc.p(-10,0))
        )))
        leftArrowImg:runAction(cc.RepeatForever:create(cc.Sequence:create(
            cc.MoveBy:create(0.2, cc.p(-10,0)),
            cc.MoveBy:create(0.2, cc.p(10,0))
        )))
        rightArrowImg:setOnClickScriptHandler(function(sender)
            local offsetPos  = targetGridview:getContentOffset()
            local maxOffsetX = targetGridview:getContainerSize().width - targetGridview:getContentSize().width
            targetGridview:setContentOffsetInDuration(cc.p(math.max(-maxOffsetX, offsetPos.x - 260), 0), 0.2)
        end)
        leftArrowImg:setOnClickScriptHandler(function(sender)
            local offsetPos  = targetGridview:getContentOffset()
            local maxOffsetX = targetGridview:getContainerSize().width
            targetGridview:setContentOffsetInDuration(cc.p(math.min(0, offsetPos.x + 260), 0), 0.2)
        end)

        return {
            view                    = view,
            Text_1                  = Text_1,
            confirmBtn              = confirmBtn,
            Text_2                  = Text_2,
            backBtn                 = backBtn,
            targetGridview          = targetGridview,
        }
    end

	xTry(function ( )
	    self.viewData = CreateView()
	end, __G__TRACKBACK__)
end

return ScratcherSelectView
