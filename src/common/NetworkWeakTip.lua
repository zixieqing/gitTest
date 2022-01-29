--[[--
网络信号弱的提示
--]]
local GameScene = require('Frame.GameScene')
local NetworkWeakTip = class('NetworkWeakTip', GameScene)


local RES_DICT = {
    WEAK_IMG = 'loading/wifi_weak_signal.png',
	TIPS_BAR = 'loading/wifi_weak_signal_bg.png'
}

function NetworkWeakTip:ctor(...)
    self.super.ctor(self, 'common.NetworkWeakTip')
    self.contextName = 'common.NetworkWeakTip'


    local viewSize  = cc.size(display.width, display.height)
    local viewLayer = display.newLayer(0, 0, {size = viewSize})
    self:addChild(viewLayer)

	viewLayer:addChild(display.newImageView(_res(RES_DICT.WEAK_IMG), viewSize.width/2, viewSize.height/2))

	local tipsBar = display.newButton(viewSize.width/2, viewSize.height/2 - 80, {n = RES_DICT.TIPS_BAR, enable = false})
	display.commonLabelParams(tipsBar, fontWithColor(9, {text = __('您当前的网络状况不佳'), paddingW = 10}))
	viewLayer:addChild(tipsBar)

	local actions = {}
	table.insert(actions, cc.EaseCubicActionOut:create(cc.FadeIn:create(0.6)))
	table.insert(actions, cc.EaseCubicActionIn:create(cc.FadeOut:create(0.6)))
	viewLayer:runAction(cc.RepeatForever:create(cc.Sequence:create(actions)))
end


function NetworkWeakTip:onEnter()
end


function NetworkWeakTip:onCleanup()
end


return NetworkWeakTip
