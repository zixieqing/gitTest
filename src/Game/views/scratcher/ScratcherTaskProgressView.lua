local GameScene = require( "Frame.GameScene" )
---@class ScratcherTaskProgressView : GameScene
local ScratcherTaskProgressView = class("ScratcherTaskProgressView", GameScene)

local RES_DICT = {
    COMMON_BG_4                     = _res('ui/common/common_bg_4.png'),
    COMMON_TITLE_5                  = _res('ui/common/common_title_5.png'),
}

function ScratcherTaskProgressView:ctor( ... )
	GameScene.ctor(self, 'Game.views.scratcher.ScratcherTaskProgressView')
	self.args = unpack({...}) or {}

	self:InitUI()
end

function ScratcherTaskProgressView:InitUI()
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
        local Panel_1 = display.newLayer(display.cx, display.cy,
        {
            ap = display.CENTER,
            size = cc.size(584, 660),
            enable = true,
        })
        view:addChild(Panel_1)

        local Image_1 = display.newImageView(RES_DICT.COMMON_BG_4, 0, 0,
        {
            ap = display.LEFT_BOTTOM,
            scale9 = true, size = cc.size(584, 650),
            enable = true,
        })
        Panel_1:addChild(Image_1)

        local Button_1 = display.newButton(291, 612,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_TITLE_5,
            -- scale9 = true, size = cc.size(186, 31),
            enable = false,
        })
        display.commonLabelParams(Button_1, {text = __('我的应援'), fontSize = 22, color = '#5b3c25'})
        Panel_1:addChild(Button_1)

        local taskProgressLabel = display.newLabel(32, 568,
        {
            text = '',
            ap = cc.p(0, 1.0),
            fontSize = 22,
            color = '#5b3c25',
        })
        Panel_1:addChild(taskProgressLabel)

        -------------------Panel_1 end--------------------

        local xx = display.cx
        local yy = display.cy - Panel_1:getContentSize().height / 2 - 14
        local closeLabel = display.newButton(xx,yy,{
            n = _res('ui/common/common_bg_close.png'),-- common_click_back
        })
        closeLabel:setEnabled(false)
        display.commonLabelParams(closeLabel,{fontSize = 18,text = __('点击空白处关闭')})
        self:addChild(closeLabel, 10)

        return {
            view                    = view,
            eaterLayer              = eaterLayer,
            Panel_1                 = Panel_1,
            Image_1                 = Image_1,
            Button_1                = Button_1,
            taskProgressLabel       = taskProgressLabel,
        }
    end

	xTry(function ( )
	    self.viewData = CreateView()
	end, __G__TRACKBACK__)
end

return ScratcherTaskProgressView
