--[[
 * author : liuzhipeng
 * descpt : 抽卡 常驻皮肤卡池动画View 
--]]
local CapsuleBasicSkinAnimationView = class('CapsuleBasicSkinAnimationView', function ()
    local node = CLayout:create(display.size)
    node.name = 'home.CapsuleBasicSkinAnimationView'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    BG               = _res('ui/home/capsuleNew/basicSkin/summon_skin_animation_bg.jpg'),
    BG_SPINE         = _spn('ui/home/capsuleNew/basicSkin/effect/summon_skin_crystal'),
    CARD_SPINE       = _spn('ui/home/capsuleNew/basicSkin/effect/summon_skin_ten'),
}

function CapsuleBasicSkinAnimationView:ctor( ... )
    self.rewardIndex = 1
    self:InitUI()
end
--[[
init ui
--]]
function CapsuleBasicSkinAnimationView:InitUI()
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
        -- 卡片btn
        local cardBtn = CLayout:create(cc.size(300, 390))
        cardBtn = display.newButton(size.width / 2, size.height / 2, {n = 'empty', size = cc.size(300, 390), cb = handler(self, self.CardButtonCallback)})
        cardBtn:setVisible(false)
        bgLayer:addChild(cardBtn, 10)
        -- 卡片spine
        local cardSpine = sp.SkeletonAnimation:create(
            RES_DICT.CARD_SPINE.json,
            RES_DICT.CARD_SPINE.atlas,
        1)
        cardSpine:setVisible(false)
        cardSpine:setPosition(cc.p(display.cx, display.cy))
        bgLayer:addChild(cardSpine, 10)
        return {
            view             = view,
            bgLayer          = bgLayer,
            bgSpine          = bgSpine,
            cardBtn          = cardBtn,
            cardSpine        = cardSpine,
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
--]]
function CapsuleBasicSkinAnimationView:StartAnimation( animationData, cb )
    PlayAudioClip(AUDIOS.UI.ui_skin_start.id)
    self.animationData = animationData
    self.cb = cb
    local viewData = self.viewData
    local capsuleType = animationData.capsuleType
    viewData.bgSpine:setAnimation(0, 'play', false)
    
    if capsuleType == CAPSULE_SKIN_TYPE.TEN then
        -- 添加十连页面
        local capsuleSkinAnimateTenCell = require("Game.views.drawCards.CapsuleBasicSkinAnimationTenView").new({reward = animationData.rewardData, cb = handler(self, self.BackAction), showAnimation = true})
        capsuleSkinAnimateTenCell:setPosition(cc.p(display.cx, display.cy))
        capsuleSkinAnimateTenCell:setVisible(false)
        viewData.view:addChild(capsuleSkinAnimateTenCell, 8)
        self:runAction(
            cc.Sequence:create(
                cc.DelayTime:create(5.5),
                cc.CallFunc:create(function () 
                    capsuleSkinAnimateTenCell:setVisible(true)
                end)
            )
        )
    else
        -- 单抽
        self:runAction(
            cc.Sequence:create(
                cc.DelayTime:create(5.5),
                cc.CallFunc:create(function () 
                    local rateData = app.capsuleMgr:GetRateDataByGoodsId(animationData.rewardData[1].goodsId)
                    viewData.cardSpine:setAnimation(0, string.format('summon_skin_animation_bg_%s_%d', rateData.buttonType == 'goods' and 'house' or 'skin', rateData.rate), false)
                    viewData.cardSpine:setTimeScale(0)
                    viewData.cardBtn:setVisible(true)
                    viewData.cardSpine:setVisible(true)
                end)
            )
        )
    end
    self:StopCapsuleUIEffects(4.5)
end
--[[
硬币按钮点击回调
--]]
function CapsuleBasicSkinAnimationView:CardButtonCallback( sender )
    PlayAudioClip(AUDIOS.UI.ui_skin_result.id)
    local reward = self.animationData.rewardData[1] or {}
    local capsuleSkinDetailView = require("Game.views.drawCards.CapsuleSkinDetailView").new({reward = reward, cb = handler(self, self.BackAction), showAnimation = true})
    capsuleSkinDetailView:setPosition(cc.p(display.cx, display.cy))
    app.uiMgr:GetCurrentScene():AddDialog(capsuleSkinDetailView)
end
--[[
停止抽卡音效
--]]
function CapsuleBasicSkinAnimationView:StopCapsuleUIEffects( delayTime )
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
返回
--]]
function CapsuleBasicSkinAnimationView:BackAction()
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
    AppFacade.GetInstance():UnRegsitMediator("CapsuleBasicSkinAnimationMediator")
end
return CapsuleBasicSkinAnimationView