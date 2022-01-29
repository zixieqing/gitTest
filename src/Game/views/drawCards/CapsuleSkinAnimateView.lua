--[[
皮肤抽卡动画view
--]]
local CapsuleSkinAnimateView = class('CapsuleSkinAnimateView', function ()
    local node = CLayout:create(display.size)
    node.name = 'home.CapsuleSkinAnimateView'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    BG               = _res('ui/home/capsuleNew/common/summon_skin_bg_animation.jpg'),
    BG_SPINE         = _spn('ui/home/capsuleNew/common/effect/zhong_di'),
    COIN_SPINE       = _spn('ui/home/capsuleNew/common/effect/zhong_shang'),
    COIN_LIGHT_SPINE = _spn('ui/home/capsuleNew/common/effect/fx_yinbi'), 
    FINGER_SPINE     = _spn('ui/home/capsuleNew/common/effect/zhizhen'),
    DOT_SPINE        = _spn('ui/home/capsuleNew/common/effect/dian'),
}
local CENTER = cc.p(display.size.width / 2 + 2, display.size.height / 2 + 10) -- 圆心
local RADIUS = 251 -- 半径
local DEFAULT_ANGLE = 9 -- 默认角度
local DEFAULT_DOT_NUM = 20 -- 光点数量

function CapsuleSkinAnimateView:ctor( ... )
    self.rewardIndex = 1
    self:InitUI()
end
--[[
init ui
--]]
function CapsuleSkinAnimateView:InitUI()
    local function CreateView()
        local size = display.size
        local view = CLayout:create(size)
        local bgLayer = display.newLayer(display.cx, display.cy, {ap = cc.p(0.5, 0.5)})
        view:addChild(bgLayer, 2)
        local bg = display.newImageView(RES_DICT.BG, display.cx, display.cy)
        view:addChild(bg, 1)
        -- 背景spine
        local bgSpine = sp.SkeletonAnimation:create(
            RES_DICT.BG_SPINE.json,
            RES_DICT.BG_SPINE.atlas,
        1)
        bgSpine:setPosition(cc.p(size.width / 2, size.height / 2))
        bgLayer:addChild(bgSpine, 2)
        local lightSpine = sp.SkeletonAnimation:create(
            RES_DICT.COIN_SPINE.json,
            RES_DICT.COIN_SPINE.atlas,
        1)
        lightSpine:setPosition(cc.p(size.width / 2, size.height / 2))
        bgLayer:addChild(lightSpine, 10)
        -- 指针spine
        local fingerSpine = sp.SkeletonAnimation:create(
            RES_DICT.FINGER_SPINE.json,
            RES_DICT.FINGER_SPINE.atlas,
        1)
        fingerSpine:setPosition(cc.p(size.width / 2, size.height / 2))  
        bgLayer:addChild(fingerSpine, 5)
        -- 硬币spine
        local coinSpine = sp.SkeletonAnimation:create(
            RES_DICT.COIN_SPINE.json,
            RES_DICT.COIN_SPINE.atlas,
        1)
        coinSpine:setPosition(cc.p(display.cx, display.cy))
        bgLayer:addChild(coinSpine, 10)
        local dotList = self:AddDotSpine(bgLayer)
        

        return {
            view             = view,
            bgLayer          = bgLayer,
            bgSpine          = bgSpine,
            lightSpine       = lightSpine,
            fingerSpine      = fingerSpine,
            coinSpine        = coinSpine,
            dotList          = dotList,
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
        self.viewData.coinSpine:registerSpineEventHandler(handler(self, self.CoinSpineEventEndHandler), sp.EventType.ANIMATION_END)
    end, __G__TRACKBACK__)
end
--[[
开始抽奖动画
--]]
function CapsuleSkinAnimateView:StartAnimation( animationData, cb )
    PlayAudioClip(AUDIOS.UI.ui_skin_start.id)
    self.animationData = animationData
    self.cb = cb
    local viewData = self.viewData
    local capsuleType = animationData.capsuleType
    if capsuleType == CAPSULE_SKIN_TYPE.ONE_CARD_SKIN then
        viewData.bgSpine:setAnimation(0, 'play1', false)
        self:SetCoinSpineAnimation(animationData.rewardData[1].goodsId)
        self:StopCapsuleUIEffects(4.8)
    elseif capsuleType == CAPSULE_SKIN_TYPE.ONE_GOODS then
        viewData.bgSpine:setAnimation(0, 'play2', false)
        self:SetCoinSpineAnimation(animationData.rewardData[1].goodsId)
        self:StopCapsuleUIEffects(4.8)
    elseif capsuleType == CAPSULE_SKIN_TYPE.TEN then
        viewData.bgSpine:setAnimation(0, 'play3', false)
        viewData.lightSpine:setAnimation(0, 'play3', false)
        -- 添加十连页面
        local capsuleSkinAnimateTenCell = require("Game.views.drawCards.CapsuleSkinAnimateTenCell").new({reward = animationData.rewardData, cb = handler(self, self.BackAction), showAnimation = true})
        capsuleSkinAnimateTenCell:setPosition(cc.p(display.cx, display.cy))
        capsuleSkinAnimateTenCell:setVisible(false)
        viewData.view:addChild(capsuleSkinAnimateTenCell, 8)
        self:runAction(
            cc.Sequence:create(
                cc.DelayTime:create(7),
                cc.CallFunc:create(function () 
                    capsuleSkinAnimateTenCell:setVisible(true)
                end)
            )
        )
        self:StopCapsuleUIEffects(7)
    end
    viewData.fingerSpine:runAction(
        cc.Sequence:create(
            cc.EaseSineIn:create(
                cc.RotateTo:create(2.1, 360 * 7)
            ),
            cc.CallFunc:create(handler(self, self.RunFingerAction))
        )
    )
end
--[[
停止抽卡音效
--]]
function CapsuleSkinAnimateView:StopCapsuleUIEffects( delayTime )
    if not delayTime then return end
    self:runAction(
        cc.Sequence:create(
            cc.DelayTime:create(delayTime),
            cc.CallFunc:create(function () 
                PlayAudioClip(AUDIOS.UI.ui_skin_end.id)
            end)
        )
    )
end
--[[
创建光点
--]]
function CapsuleSkinAnimateView:AddDotSpine( layer )
    local dotList = {}
    for i = 1, 20 do
        local angle = self:GetDotAngleByIndex(i)
        local radian = math.rad(angle)
        local bgSpine = sp.SkeletonAnimation:create(
            RES_DICT.DOT_SPINE.json,
            RES_DICT.DOT_SPINE.atlas,
        1)
        bgSpine:setAnimation(0, 'play1', true)
        bgSpine:setPosition(cc.p(CENTER.x + RADIUS * math.sin(radian), display.size.height / 2 + 10 + RADIUS * math.cos(radian)))
        table.insert(dotList, bgSpine)
        layer:addChild(bgSpine, 3)
    end
    return dotList
end
--[[
指针旋转动画
--]]
function CapsuleSkinAnimateView:RunFingerAction()
    local rewardIndex = self.rewardIndex
    local rewardData = self.animationData.rewardData[rewardIndex]
    local viewData = self.viewData
    if rewardData then
        local index = self:GetDotIndex(rewardData)
        local angle = 360 + self:GetDotAngleByIndex(index)
        if rewardIndex > 1 and index < self:GetDotIndex(self.animationData.rewardData[rewardIndex - 1]) then
            angle = angle + 360
        end
        viewData.fingerSpine:runAction(
            cc.Sequence:create(
                cc.EaseSineOut:create(
                    cc.RotateTo:create(0.2, angle)
                ),
                cc.CallFunc:create( function ()
                    PlayAudioClip(AUDIOS.UI.ui_skin_pointer.id)
                    viewData.dotList[index]:setAnimation(0, 'play2', true)
                    viewData.fingerSpine:setAnimation(0, 'play2', false)
                    viewData.fingerSpine:addAnimation(0, 'play1', true)
                end),
                cc.DelayTime:create(0.2),
                cc.CallFunc:create( function ()
                    self.rewardIndex = rewardIndex + 1
                    if self.rewardIndex <= #self.animationData.rewardData then
                        self:RunFingerAction()
                    else
                        self:HideDotSpine()
                        self:HideFingerSpine()
                    end
                end)
            )
        )
    end
end
--[[
隐藏指针
--]]
function CapsuleSkinAnimateView:HideFingerSpine()
    local viewData = self.viewData
    viewData.fingerSpine:runAction(cc.FadeOut:create(0.3))
end 
--[[
隐藏光点
--]]
function CapsuleSkinAnimateView:HideDotSpine()
    local viewData = self.viewData
    for i, v in ipairs(viewData.dotList) do
        v:runAction(cc.FadeOut:create(0.3))
    end
end
--[[
播放硬币动画
--]]
function CapsuleSkinAnimateView:SetCoinSpineAnimation( goodsId )
    local viewData = self.viewData
    local rateData = app.capsuleMgr:GetRateDataByGoodsId(goodsId)
    viewData.coinSpine:setAnimation(0, string.format('play%d_%d', rateData.coinType, rateData.rate), false)
end
--[[
获取光点spine的index
@params rewardData map 奖励数据
--]]
function CapsuleSkinAnimateView:GetDotIndex( rewardData )
    if not rewardData then return end
    local index = rewardData.dotIndex
    if tostring(rewardData.type) == GoodsType.TYPE_CARD_SKIN then
        index = index + 10
    end
    return index
end
--[[
根据index获取光点角度
@params index int 索引
--]]
function CapsuleSkinAnimateView:GetDotAngleByIndex( index )
    return DEFAULT_ANGLE + 360 / DEFAULT_DOT_NUM * (index - 1)
end
--[[
硬币spine动画结束回调
--]]
function CapsuleSkinAnimateView:CoinSpineEventEndHandler( event )
    local viewData = self.viewData
    local goodsId = self.animationData.rewardData[1].goodsId
    local rateData = app.capsuleMgr:GetRateDataByGoodsId(goodsId)

    local coinBtn = display.newButton(display.cx, display.cy, {n = _res(string.format('ui/home/capsuleNew/common/summon_skin_ico_%s_coin_%d.png', rateData.buttonType, rateData.rate)), cb = handler(self, self.CoinButtonCallback)})
    coinBtn:setScale(2)
    viewData.view:addChild(coinBtn, 5)
    local lightSpine = sp.SkeletonAnimation:create(
        RES_DICT.COIN_LIGHT_SPINE.json,
        RES_DICT.COIN_LIGHT_SPINE.atlas,
    1)
    lightSpine:setPosition(cc.p(display.cx, display.cy))
    viewData.view:addChild(lightSpine, 5)
    if rateData.rate == 1 then
        lightSpine:setAnimation(0, 'idle1', true)
    elseif rateData.rate == 2 then
        lightSpine:setAnimation(0, 'idle2', true)
    else
        lightSpine:setVisible(false)
    end
    viewData.bgLayer:runAction(cc.RemoveSelf:create())
end
--[[
硬币按钮点击回调
--]]
function CapsuleSkinAnimateView:CoinButtonCallback( sender )
    PlayAudioClip(AUDIOS.UI.ui_skin_result.id)
    local reward = self.animationData.rewardData[1] or {}
    local capsuleSkinDetailView = require("Game.views.drawCards.CapsuleSkinDetailView").new({reward = reward, cb = handler(self, self.BackAction), showAnimation = true})
    capsuleSkinDetailView:setPosition(cc.p(display.cx, display.cy))
    app.uiMgr:GetCurrentScene():AddDialog(capsuleSkinDetailView)
end
--[[
返回
--]]
function CapsuleSkinAnimateView:BackAction()
    PlayAudioByClickClose()


	-- 先转化数据数据后加入到背包中
	for i, v in pairs(self.animationData.rewardData) do
		if v.turnGoodsId and checkint(v.turnGoodsNum)  > 0   then
			v.turnGoodsId , v.goodsId =v.goodsId  , v.turnGoodsId
			v.turnGoodsNum , v.num =v.num , v.turnGoodsNum
        end
	end
    CommonUtils.DrawRewards(self.animationData.rewardData)
    if self.cb then
        self.cb()
    end
    AppFacade.GetInstance():UnRegsitMediator("CapsuleSkinAnimateMediator")
end
return CapsuleSkinAnimateView