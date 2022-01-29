--[[
 * author : kaishiqi
 * descpt : 工会派对 - 掉菜视图
]]
local AbsorbEffectNode       = require('common.AbsorbEffectNode')
local UnionPartyDropFoodView = class('UnionPartyDropFoodView', function()
    return display.newLayer(0, 0, {name = 'Game.views.union.UnionPartyDropFoodView'})
end)

local RES_DICT = {
}

local CreateView = nil


function UnionPartyDropFoodView:ctor(args)
    local uiManager  = AppFacade.GetInstance():GetManager('UIManager')
    self.ownerScene_ = uiManager:GetCurrentScene()

    -- create view
    self.viewData_ = CreateView()
    self:addChild(self.viewData_.view)
end


CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()

    -- block bg
    local blockBg = display.newLayer(0, 0, {color = cc.c4b(0,0,0,100), enable = true})
    view:addChild(blockBg)

    -- motion layer
    local motionLayer = display.newLayer()
    view:addChild(motionLayer)

    -- food layer
    local foodLayer = display.newLayer()
    view:addChild(foodLayer)

    -- sprite layer
    local spriteLayer = display.newLayer()
    view:addChild(spriteLayer)
    
    -- effect layer
    local effectLayer = display.newLayer()
    view:addChild(effectLayer)

    return {
        view        = view,
        foodLayer   = foodLayer,
        motionLayer = motionLayer,
        spriteLayer = spriteLayer,
        effectLayer = effectLayer,
    }
end


function UnionPartyDropFoodView:getViewData()
    return self.viewData_
end


-------------------------------------------------
-- food view
function UnionPartyDropFoodView:appendFoodView(foodId)
    local iconPath = CommonUtils.GetGoodsIconPathById(foodId)
    local foodView  = display.newImageView(_res(iconPath), 0, 0, {ap = display.CENTER_BOTTOM, enable = true})
    self:getViewData().foodLayer:addChild(foodView)
    return foodView
end
function UnionPartyDropFoodView:removeFoodView(foodView)
    if foodView and foodView:getParent() then
        foodView:runAction(cc.RemoveSelf:create())
    end
end
function UnionPartyDropFoodView:getFoodViewByTag(tag)
    return self:getViewData().foodLayer:getChildByTag(checkint(tag))
end
function UnionPartyDropFoodView:deadFoodView(foodView, foodScore, isSpecial)
    if not foodView then return end

    local centerPos = cc.p(
        foodView:getPositionX(), 
        foodView:getPositionY() + foodView:getContentSize().height/2
    )
    
    -- add spine cache
    local foodSpinePath = 'effects/union/party/huode'
    if not SpineCache(SpineCacheName.UNION):hasSpineCacheData(foodSpinePath) then
        SpineCache(SpineCacheName.UNION):addCacheData(foodSpinePath, foodSpinePath, 1)
    end

    -------------------------------------------------
    -- food dead spine
    local foodSpine = SpineCache(SpineCacheName.UNION):createWithName(foodSpinePath)
    foodSpine:update(0)
    foodSpine:setAnimation(0, 'play', false)
    foodSpine:setPosition(centerPos)
    self:getViewData().effectLayer:addChild(foodSpine)

    foodSpine:registerSpineEventHandler(function(event)
        foodSpine:runAction(cc.Sequence:create(
            cc.DelayTime:create(0.1),
            cc.CallFunc:create(function()
                foodSpine:clearTracks()
                foodSpine:unregisterSpineEventHandler(sp.EventType.ANIMATION_COMPLETE)
            end),
            cc.RemoveSelf:create())
        )
    end, sp.EventType.ANIMATION_COMPLETE)

    -------------------------------------------------
    -- food dead action
    local deadTime = 0.4
    foodView:runAction(cc.Sequence:create({
        cc.FadeOut:create(deadTime),
        cc.CallFunc:create(function()
            self:removeFoodView(foodView)
        end)
    }))

    -------------------------------------------------
    -- show score text
    local scoreShowTime = 0.2
    local scoreHideTime = 0.4
    local scoreString   = string.fmt('+%1', foodScore)
    local scoreLabel    = display.newLabel(centerPos.x, centerPos.y, fontWithColor(20, {fontSize = 40, text = scoreString}))
    self:getViewData().effectLayer:addChild(scoreLabel)
    scoreLabel:setScale(1)
    scoreLabel:setOpacity(0)
    scoreLabel:runAction(cc.Sequence:create({
        cc.Spawn:create({
            cc.FadeIn:create(scoreShowTime),
            cc.ScaleTo:create(scoreShowTime, 1),
            cc.MoveBy:create(scoreShowTime, cc.p(0, 80))
        }),
        cc.DelayTime:create(0.1),
        cc.Spawn:create({
            cc.FadeOut:create(scoreHideTime),
            cc.MoveBy:create(scoreHideTime, cc.p(0, 20))
        }),
        cc.RemoveSelf:create()
    }))

    -------------------------------------------------
    -- add score effect
    local iconPath = CommonUtils.GetGoodsIconPathById(UNION_POINT_ID)
    local absorbEffectNode = AbsorbEffectNode.new({
        path     = iconPath,
        num      = isSpecial and 30 or 10,
        range    = isSpecial and 60 or 50,
        scale    = 0.2,
        beginPos = centerPos,
        endedPos = cc.p(display.SAFE_L + 90, display.height/2 - 10),
    })
    self.ownerScene_:AddDialog(absorbEffectNode)
end


-------------------------------------------------
-- motion view
function UnionPartyDropFoodView:appendMotionView(foodView)
    local streakView = nil
    if foodView then
        local imgW = foodView:getContentSize().width
        streakView = cc.MotionStreak:create(0.26, 1, imgW, cc.c3b(250,250,250), foodView:getTexture())
        streakView:setAnchorPoint(display.CENTER_BOTTOM)
        self:getViewData().motionLayer:addChild(streakView)
    end
    return streakView
end
function UnionPartyDropFoodView:removeMotionView(motionView)
    if motionView and motionView:getParent() then
        motionView:runAction(cc.RemoveSelf:create())
    end
end


-------------------------------------------------
-- sprite cell
function UnionPartyDropFoodView:appendSpriteView()
    local spriteSize = cc.size(160, 160)
    local spriteView = display.newLayer(0, 0, {size = spriteSize, color = cc.r4b(0), enable = true, ap = display.CENTER_BOTTOM})
    self:getViewData().spriteLayer:addChild(spriteView)

    -- add cpine cache
    local spriteSpinePath = 'effects/union/party/paiduicangying'
    if not SpineCache(SpineCacheName.UNION):hasSpineCacheData(spriteSpinePath) then
        SpineCache(SpineCacheName.UNION):addCacheData(spriteSpinePath, spriteSpinePath, 0.5)
    end
    
    -- sprite spine
    spriteView.spine = SpineCache(SpineCacheName.UNION):createWithName(spriteSpinePath)
    spriteView.spine:update(0)
    spriteView.spine:setAnimation(0, 'idle2', true)
    spriteView.spine:setPosition(cc.p(spriteSize.width/2, 0))
    spriteView:addChild(spriteView.spine)
    return spriteView
end
function UnionPartyDropFoodView:removeSpriteView(foodView)
    if foodView and foodView:getParent() then
        foodView:runAction(cc.RemoveSelf:create())
    end
end
function UnionPartyDropFoodView:deadSpriteView(spriteView, deadTime)
    if not spriteView then return end
    
    -- dead setting
    spriteView:setTouchEnabled(false)
    spriteView:setLocalZOrder(1)
    if spriteView.spine then
        spriteView.spine:setAnimation(0, 'die', false)
    end

    -- dead action
    local moveTime  = 0.2
    local delayTime = 0.2
    local dropTime  = math.max(checknumber(deadTime) - moveTime - delayTime, 0.1)
    spriteView:runAction(cc.Sequence:create({
        cc.MoveTo:create(moveTime, display.center),
        cc.DelayTime:create(delayTime),
        cc.Spawn:create({
            cc.TargetedAction:create(spriteView.spine, cc.EaseQuarticActionIn:create(cc.FadeOut:create(dropTime))),
            cc.EaseQuarticActionIn:create(cc.MoveTo:create(dropTime, cc.p(display.cx, -display.height)))
        }),
        cc.CallFunc:create(function()
            self:removeSpriteView(spriteView)
        end)
    }))
end


return UnionPartyDropFoodView
