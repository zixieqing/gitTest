local GameScene = require( "Frame.GameScene" )
---@class ScratcherPreviewView : GameScene
local ScratcherPreviewView = class("ScratcherPreviewView", GameScene)

local RES_DICT = {
    BACK_BTN                        = _res("ui/common/common_btn_back"),
    COMMON_TITLE                    = _res('ui/common/common_title_5.png'),
    RWEARD_LAYOUT_BG                = _res('ui/common/common_bg_4.png'),
    DRAW_PROBABILITY_BTN            = _res('ui/home/capsule/draw_probability_btn.png'),
    COMMON_BG_GOODS                 = _res('ui/common/common_bg_goods'),
}

function ScratcherPreviewView:ctor( ticketGoodsId )
	GameScene.ctor(self, 'Game.views.scratcher.ScratcherPreviewView')

	self:InitUI()
end

function ScratcherPreviewView:InitUI()
    local function CreateView()
        local view = CLayout:create(display.size)
        display.commonUIParams(view, {po = display.center})
        self:addChild(view)    

        local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 120))
        eaterLayer:setTouchEnabled(true)
        eaterLayer:setContentSize(display.size)
        eaterLayer:setPosition(cc.p(display.cx, display.cy))
        view:addChild(eaterLayer)

		----------------------
        ---- rewardLayout ----
        local rewardLayoutSize = cc.size(695, 640)
        local rewardLayout = CLayout:create(rewardLayoutSize)
        view:addChild(rewardLayout, 1)
        rewardLayout:setPosition(cc.p(display.cx, display.cy))
        local rewardLayoutBg = display.newImageView(RES_DICT.RWEARD_LAYOUT_BG, rewardLayoutSize.width / 2, rewardLayoutSize.height / 2, {scale9 = true, size = rewardLayoutSize, enable = true})
        rewardLayout:addChild(rewardLayoutBg)
        -- 列表背景
        local rewardListViewSize = cc.size(645, 540)
        local listViewBg = display.newImageView(RES_DICT.COMMON_BG_GOODS, rewardLayoutSize.width / 2, 28
        , { size = rewardListViewSize, scale9 = true, ap = display.CENTER_BOTTOM})
        rewardLayout:addChild(listViewBg)
        -- 列表
        local rewardListView = CListView:create(rewardListViewSize)
        rewardListView:setDirection(eScrollViewDirectionVertical)
        display.commonUIParams(rewardListView, {po = cc.p(rewardLayoutSize.width / 2, 28), ap = display.CENTER_BOTTOM})
        rewardLayout:addChild(rewardListView)
        ---- rewardLayout ----
        ----------------------
        
        local titleBtn = display.newButton(rewardLayoutSize.width / 2, rewardLayoutSize.height - 35, { n = RES_DICT.COMMON_TITLE, enable = false } )
        display.commonLabelParams(titleBtn, fontWithColor('6', { text = '预览' }))
        rewardLayout:addChild(titleBtn)

        local probabilityBtn = display.newButton(672, rewardLayoutSize.height - 35, {ap = cc.p(1, 0.5) ,  n = RES_DICT.DRAW_PROBABILITY_BTN })
        display.commonLabelParams(probabilityBtn, fontWithColor(18, {text = __('概率')}))
        rewardLayout:addChild(probabilityBtn)

        local xx = display.cx
        local yy = display.cy - rewardLayoutSize.height / 2 - 14
        local closeLabel = display.newButton(xx,yy,{
            n = _res('ui/common/common_bg_close.png'),-- common_click_back
        })
        closeLabel:setEnabled(false)
        display.commonLabelParams(closeLabel,{fontSize = 18,text = __('点击空白处关闭')})
        self:addChild(closeLabel, 10)

        return {
            view                    = view,
            eaterLayer              = eaterLayer,
            rewardListViewSize      = rewardListViewSize,
            rewardListView          = rewardListView,
            probabilityBtn          = probabilityBtn,
        }
    end

	xTry(function ( )
	    self.viewData = CreateView()
	end, __G__TRACKBACK__)
end

return ScratcherPreviewView
