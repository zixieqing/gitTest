--[[--
请求进度显示层
--]]
local GameScene = require( 'Frame.GameScene' )
local ProgressHUD = class('ProgressHUD',GameScene)


local RES_DICT = {
    JSON    = 'loading/skeleton.json',
    ATLAS   = 'loading/skeleton.atlas',
}

function ProgressHUD:ctor(...)
    self.super.ctor(self,'common.ProgressHUD')
    self.contextName = "common.ProgressHUD"

    local demo1Avatar = sp.SkeletonAnimation:create(RES_DICT.JSON, RES_DICT.ATLAS, 0.6)
    demo1Avatar:setPosition(cc.p(display.width * 0.5, display.height * 0.5))
    self:addChild(demo1Avatar)
    demo1Avatar:setVisible(false)

    self.listener = cc.EventListenerTouchOneByOne:create()
    self.listener:setSwallowTouches(true)
    self.listener:registerScriptHandler(handler(self,self.ontouchBegin),cc.Handler.EVENT_TOUCH_BEGAN)
    self.listener:registerScriptHandler(handler(self,self.ontouchEnd),cc.Handler.EVENT_TOUCH_ENDED)
    self:getEventDispatcher():addEventListenerWithFixedPriority(self.listener,-120)

    --x秒钟后如果没有被移除，然后显示菊花进度
    self:runAction(cc.Sequence:create(
        cc.DelayTime:create(2),
        cc.CallFunc:create(function()
            demo1Avatar:setAnimation(0, 'animation', true)
            demo1Avatar:setVisible(true)
        end)
    ))
end

function ProgressHUD:onEnter()
end

function ProgressHUD:ontouchBegin(touch, event)
    return true
end

function ProgressHUD:ontouchEnd(touch, event)
end

function ProgressHUD:onCleanup()
    --移除事件监听器
    self:getEventDispatcher():removeEventListener(self.listener)
end

return ProgressHUD
