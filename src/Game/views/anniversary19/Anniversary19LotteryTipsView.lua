--[[
 * author : liuzhipeng
 * descpt : 活动 周年庆19 抽奖 抽空tips
--]]
local Anniversary19LotteryTipsView = class('Anniversary19LotteryTipsView', function ()
    local node = CLayout:create(display.size)
    node.name = 'anniversary19.Anniversary19LotteryTipsView'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    BG = app.anniversary2019Mgr:GetResPath('ui/anniversary19/lottery/wonderland_draw_bg_empty.png'),
}
function Anniversary19LotteryTipsView:ctor( ... )
    self.args = unpack({...})
    self:InitUI()
end
--[[
init ui
--]]
function Anniversary19LotteryTipsView:InitUI()
    local function CreateView()
        local bg = display.newImageView(RES_DICT.BG, 0, 0)
        local bgSize = bg:getContentSize()
        local view = CLayout:create(bgSize)
        bg:setPosition(cc.p(bgSize.width/2, bgSize.height/2))
        view:addChild(bg, 1)
        local tipsLabel = display.newLabel(360, 180, {text = app.anniversary2019Mgr:GetPoText(__('没有礼物了\n换一个兔子吧')), fontSize = 22, color = '#C5A26A', ap = display.LEFT_TOP, w = 440})
        view:addChild(tipsLabel, 5)
         -- mask
		local mask = CColorView:create(cc.c4b(0, 0, 0, 0))
		mask:setTouchEnabled(true)
		mask:setContentSize(bgSize)
		mask:setAnchorPoint(cc.p(0.5, 0.5))
		mask:setPosition(cc.p(bgSize.width/2, bgSize.height/2))
		view:addChild(mask, -1)
        return {
            view             = view,
        }
    end
    -- eaterLayer
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255*0.6))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    eaterLayer:setOnClickScriptHandler(function()
        PlayAudioByClickClose()
        self:runAction(cc.RemoveSelf:create())
    end)
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(display.center)
        -- action
        self.viewData.view:setScale(0.5)
        self.viewData.view:runAction(
            cc.EaseBackOut:create(cc.ScaleTo:create(0.25, 1))
        )
    end, __G__TRACKBACK__)
end
return Anniversary19LotteryTipsView