--[[
铸池抽卡动画view
--]]
local CapsuleRandomPoolAnimationView = class('CapsuleRandomPoolAnimationView', function ()
    local node = CLayout:create(display.size)
    node.name = 'home.CapsuleRandomPoolAnimationView'
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
function CapsuleRandomPoolAnimationView:ctor( ... )
    self:InitUI()
end
--[[
init ui
--]]
function CapsuleRandomPoolAnimationView:InitUI()
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
        -- 人物立绘
        local roleImg = display.newImageView('', bgSize.width / 2, bgSize.height / 2)
        bg:addChild(roleImg, 1)
        return {
            view             = view,
            capsuleAnimation = capsuleAnimation,
            fireAnimation    = fireAnimation,
            roleImg          = roleImg,
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
function CapsuleRandomPoolAnimationView:StartCapsuleAnimation( isRare )
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
function CapsuleRandomPoolAnimationView:RecoverCapsuleIdleState()
    self.viewData.capsuleAnimation:update(0)
    self.viewData.capsuleAnimation:setToSetupPose()
    self.viewData.capsuleAnimation:addAnimation(0, 'idle', true)
end
--[[
进入动画
--]]
function CapsuleRandomPoolAnimationView:EnterAnimation( imageList )
    local viewData = self.viewData
    local roleImg = viewData.roleImg
    local function flash( target, params )
        roleImg:stopAllActions()
        roleImg:setTexture(_res(string.format('ui/home/capsule/activityCapsule/%s.png', tostring(params.path))))
        roleImg:setScale(1)
        roleImg:setOpacity(255)
        roleImg:runAction(
            cc.Spawn:create(
                cc.FadeOut:create(0.3),
                cc.ScaleTo:create(0.3, 1.1)
            )
        )
    end
    local function final( target, params )
        roleImg:stopAllActions()
        roleImg:setTexture(_res(string.format('ui/home/capsule/activityCapsule/%s.png', tostring(params.path))))
        roleImg:setScale(1)
        roleImg:setOpacity(255)
        local phantom = display.newImageView(_res(string.format('ui/home/capsule/activityCapsule/%s.png', tostring(params.path))),roleImg:getContentSize().width / 2, roleImg:getContentSize().height / 2)
        roleImg:addChild(phantom)
        phantom:runAction(
            cc.Sequence:create(
                cc.Spawn:create(
                    cc.FadeOut:create(0.3),
                    cc.ScaleTo:create(0.3, 1.5)
                ),
                cc.RemoveSelf:create()
            )
        )
        
    end
    -- 创建动画
    local seqTable = {}
    for i = 1, #imageList - 1 do
        seqTable[#seqTable + 1] = cc.CallFunc:create(flash, {path = imageList[i]})
        seqTable[#seqTable + 1] = cc.DelayTime:create(0.3)
    end
    seqTable[#seqTable + 1] = cc.CallFunc:create(final, {path = imageList[#imageList]})
    seqTable[#seqTable + 1] = cc.DelayTime:create(0.4)
    seqTable[#seqTable + 1] = cc.CallFunc:create(function () 
        self:StartCapsuleAnimation()
    end)
	local seqAction = cc.Sequence:create(seqTable)
	self:runAction(seqAction)
end
return CapsuleRandomPoolAnimationView