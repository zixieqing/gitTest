--[[
CV分享活动抽卡view
--]]
local ActivityCVShareCapsuleView = class('ActivityCVShareCapsuleView', function ()
    local node = CLayout:create(display.size)
    node:setAnchorPoint(cc.p(0, 0))
    node.name = 'home.ActivityCVShareCapsuleView'
    node:enableNodeEvents()
    return node
end)
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

function ActivityCVShareCapsuleView:ctor( ... )
    self.args = unpack({...})
    self:InitUI()
end
--[[
init ui
--]]
function ActivityCVShareCapsuleView:InitUI()
    local function CreateView()
        local view = display.newLayer(0,0,{size = display.size, ap = cc.p(0.5,0.5)})
        local frontBg = display.newImageView(_res('ui/home/capsule/draw_card_bg_front.png'), display.cx, display.cy)
        view:addChild(frontBg, 5)
        local bg = display.newImageView(_res('ui/home/capsule/capsule_bg.png'), display.cx, display.cy)
        view:setName('views.CapsuleView')
        view:addChild(bg)
        local bgSize = bg:getContentSize()
        -- 抽奖动画
        local capsuleAnimation = sp.SkeletonAnimation:create(
          'effects/capsule/capsule.json',
          'effects/capsule/capsule.atlas',
          1)
        capsuleAnimation:setAnimation(0, 'play', false)
        capsuleAnimation:addAnimation(0, 'idle', true)
        capsuleAnimation:setPosition(cc.p(0, 0))
        bg:addChild(capsuleAnimation)
        -- 指针
        local finger = display.newImageView(_res('ui/home/capsule/finger.png'), display.cx + 477, display.cy - 185, {ap = cc.p(0.785, 0.5)})
        view:addChild(finger)
        finger:setRotation(2)
        return {
            view             = view,
            capsuleAnimation = capsuleAnimation
        }

    end
    -- eaterLayer
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255*0.6))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    xTry(function ( )
        self.viewData_ = CreateView( )
        self:addChild(self.viewData_.view)
        self.viewData_.view:setPosition(display.center)
        self.viewData_.capsuleAnimation:registerSpineEventHandler(handler(self, self.SpineEventHandler), sp.EventType.ANIMATION_EVENT)
        PlayAudioClip(AUDIOS.UI.ui_card_movie.id)
    end, __G__TRACKBACK__)
end
--[[
spine结束回调
--]]
function ActivityCVShareCapsuleView:SpineEventHandler(event)
    if not event then return end
    if not event.eventData then return end
    if 'play' == event.eventData.name then
        AppFacade.GetInstance():DispatchObservers('ACTIVITY_CVSHARE_CAPSULE')
        self:runAction(cc.RemoveSelf:create())
    end
end

return ActivityCVShareCapsuleView