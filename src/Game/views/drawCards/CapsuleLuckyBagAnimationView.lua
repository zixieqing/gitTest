--[[
福袋抽卡动画view
--]]
local CapsuleLuckyBagAnimationView = class('CapsuleLuckyBagAnimationView', function ()
    local node = CLayout:create(display.size)
    node.name = 'home.CapsuleLuckyBagAnimationView'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    BG            = _res('ui/home/capsule/capsule_bg.png'),
    FRONT_BG      = _res('ui/home/capsule/draw_card_bg_front.png'),
    CAPSULE_SPINE = _spn('ui/home/capsuleNew/common/effect/capsule'),
    FINGER        = _res('ui/home/capsule/finger.png'),
    BACK_BTN      = _res("ui/common/common_btn_back.png"),
}
function CapsuleLuckyBagAnimationView:ctor( ... )
    self:InitUI()
end
--[[
init ui
--]]
function CapsuleLuckyBagAnimationView:InitUI()
    local function CreateView()
        local size = display.size
        local view = CLayout:create(size)
        local bg = display.newImageView(RES_DICT.BG, display.cx, display.cy)
        view:addChild(bg, 1)
        local bgSize = bg:getContentSize()
        local frontBg = display.newImageView(RES_DICT.FRONT_BG, display.cx, display.cy)
        view:addChild(frontBg, 5)
        -- 抽奖动画
	    local capsuleAnimation = sp.SkeletonAnimation:create(
            RES_DICT.CAPSULE_SPINE.json,
            RES_DICT.CAPSULE_SPINE.atlas,
        1)
        capsuleAnimation:setAnimation(0, 'idle', true)
        capsuleAnimation:setPosition(cc.p(0, 0))
        bg:addChild(capsuleAnimation, 2)
        
        -- 火焰动画
        local fireAnimation = sp.SkeletonAnimation:create(
            RES_DICT.CAPSULE_SPINE.json,
            RES_DICT.CAPSULE_SPINE.atlas,
        1)
        fireAnimation:update(0)
        fireAnimation:setToSetupPose()
        fireAnimation:setAnimation(0, 'huo1', true)
        fireAnimation:setPosition(cc.p(bgSize.width / 2, bgSize.height / 2))
        bg:addChild(fireAnimation, 2)
        -- 指针
        local finger = display.newImageView(RES_DICT.FINGER, display.cx + 477, display.cy - 185, {ap = cc.p(0.785, 0.5)})
        view:addChild(finger, 5)
        finger:setRotation(2) -- 2~90 
        -- 返回按钮
        -- local backBtn = display.newButton(0, 0, {n = RES_DICT.BACK_BTN})
		-- display.commonUIParams(backBtn, {po = cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.height - 18 - backBtn:getContentSize().height * 0.5)})
		-- self:addChild(backBtn, 5)
        return {
            view             = view,
            capsuleAnimation = capsuleAnimation,
            fireAnimation    = fireAnimation,
            -- backBtn          = backBtn,
        }
    end
    xTry(function ( )
        local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
        eaterLayer:setContentSize(display.size)
        eaterLayer:setTouchEnabled(true)
        eaterLayer:setPosition(utils.getLocalCenter(self))
        self:addChild(eaterLayer, -1)
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(display.center)
    end, __G__TRACKBACK__)
end

--[[
开始抽奖动画
@params isRare bool 是否为稀有卡牌(UR)
--]]
function CapsuleLuckyBagAnimationView:StartCapsuleAnimation( isRare )
    PlayAudioClip(AUDIOS.UI.ui_card_movie.id) -- 添加音效
    if isRare then
        self.viewData.capsuleAnimation:setAnimation(0, 'play2', false)
    else
        self.viewData.capsuleAnimation:setAnimation(0, 'play', false)
    end
end
--[[
将背景spine恢复为idle状态
--]]
function CapsuleLuckyBagAnimationView:RecoverCapsuleIdleState()
    self.viewData.capsuleAnimation:update(0)
    self.viewData.capsuleAnimation:setToSetupPose()
    self.viewData.capsuleAnimation:addAnimation(0, 'idle', true)
end
return CapsuleLuckyBagAnimationView