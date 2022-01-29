--[[
 * author : kaishiqi
 * descpt : 猫屋 - 卡牌节点
]]
local CatHouseCardNode = class('CatHouseCardNode', function()
    return ui.layer({name = 'CatHouseCardNode', enableEvent = true})
end)

local RES_DICT = {
    AVATAR_SHADOW = _res('ui/battle/battle_role_shadow.png'),
    SMOKE_SPINE   = _spn('ui/union/lobby/yan'),
}

local CARD_NODE_SIZE = cc.size(120, 170)


function CatHouseCardNode:ctor(args)
    self:setAnchorPoint(ui.cb)
    self:setContentSize(CARD_NODE_SIZE)

    -- create view
    self.viewData_ = CatHouseCardNode.CreateView()
    self:add(self.viewData_.view)

    -- add listen
    ui.bindClick(self:getViewData().clickArea, handler(self, self.onClickCardNodeHandler_))

    -- init views
    self:setBubbleId(0)
    self:setIdentityId(0)
    self:setMemberName('')
end


-------------------------------------------------
-- get / set

function CatHouseCardNode:getViewData()
    return self.viewData_
end


-- memberId
function CatHouseCardNode:getMemberId()
    return checkint(self.memberId_)
end
function CatHouseCardNode:setMemberId(memberId)
    self.memberId_ = checkint(memberId)
    self:setTag(self:getMemberId())
    self:getViewData().clickArea.memberId = self:getMemberId()
    self:getViewData().clickArea:setTouchEnabled(self:getMemberId() ~= app.gameMgr:GetPlayerId())
end


-- memberName
function CatHouseCardNode:getMemberName()
    return tostring(self.memberName_)
end
function CatHouseCardNode:setMemberName(memberName)
    self.memberName_ = tostring(memberName)
    self:updateIdentity_()
end


-- bubbleId
function CatHouseCardNode:getBubbleId()
    return checkint(self.bubbleId_)
end
function CatHouseCardNode:setBubbleId(bubblieId)
    local defaultId   = CatHouseUtils.HOUSE_PARAM_FUNCS.INIT_BUBBLE_ID()
    local newBubbleId = checkint(bubblieId) > 0 and bubblieId or defaultId
    self.bubbleId_    = newBubbleId
end


-- identityId
function CatHouseCardNode:getIdentityId()
    return checkint(self.identityId_)
end
function CatHouseCardNode:setIdentityId(identityId)
    local defaultId     = CatHouseUtils.HOUSE_PARAM_FUNCS.INIT_IDENTITY_ID()
    local newIdentityId = checkint(identityId) > 0 and identityId or defaultId
    self.identityId_    = newIdentityId
    self:updateIdentity_()
end


-- cardSkinId
function CatHouseCardNode:getCardSkinId()
    return checkint(self.cardSkinId_)
end
function CatHouseCardNode:setCardSkinId(cardSkinId)
    local defaultId     = CatHouseUtils.AVATAR_DEFAULT_HEAD_ID
    local newCardSkinId = checkint(cardSkinId) > 0 and cardSkinId or defaultId
    self.cardSkinId_    = newCardSkinId
    self:updateCardSkin_()
end


-- targetPoint
function CatHouseCardNode:getTargetPoint()
    return self.targetPoint_
end
function CatHouseCardNode:setTargetPoint(point)
    self.targetPoint_ = point

    if self.targetPoint_ then
        self.targetPoint_.x = checkint(self.targetPoint_.x)
        self.targetPoint_.y = checkint(self.targetPoint_.y)

        if self.cardSpineNode_ then
            local currentX = self:getPositionX()
            local targetX  = self:getTargetPoint().x
            if currentX ~= targetX then
                self.cardSpineNode_:setScaleX(currentX < targetX and 1 or -1)
            end

            if self.cardSpineNode_:getCurrent() ~= 'run' then
                self.cardSpineNode_:setToSetupPose()
                self.cardSpineNode_:setAnimation(0, 'run', true)
            end
        end
    else
        if self.cardSpineNode_ then
            if self.cardSpineNode_:getCurrent() ~= 'idle' then
                self.cardSpineNode_:setToSetupPose()
                self.cardSpineNode_:setAnimation(0, 'idle', true)
            end
        end
    end
end


function CatHouseCardNode:isReachTargetPoint()
    if self:getTargetPoint() then
        return (checkint(self:getTargetPoint().x) == checkint(self:getPositionX()) and 
                checkint(self:getTargetPoint().y) == checkint(self:getPositionY()))
    else
        return true
    end
end


-------------------------------------------------
-- public

function CatHouseCardNode:eraseFromParent(hasEffect)
    if hasEffect then
        local nodePoint  = cc.p(self:getPosition())
        local smokeSpine = ui.spine({cache = SpineCacheName.CAT_HOUSE, path = RES_DICT.SMOKE_SPINE, scale = 0.5, init = 'go', loop = false, p = nodePoint})
        smokeSpine:registerSpineEventHandler(function(event)
            smokeSpine:runAction(cc.RemoveSelf:create())
        end, sp.EventType.ANIMATION_COMPLETE)
        self:getParent():add(smokeSpine)
        
        PlayAudioClip(AUDIOS.UI.ui_union_change.id)
    end
    
    self:removeFromParent()
end


function CatHouseCardNode:createBubble(message)
    local bubbleText = tostring(message)
    local bubbleNode = CatHouseUtils.GetBubbleNode(self:getBubbleId(), bubbleText, nil, 350)
    local delayTime  = math.max(1, math.min(3.5, 0.2 * string.len(bubbleText)))
    self:getViewData().bubbleLayer:addList(bubbleNode):alignTo(nil, ui.cb)

    bubbleNode:runAction(cc.Sequence:create(
        cc.FadeIn:create(0.25), 
        cc.DelayTime:create(delayTime), 
        cc.FadeOut:create(0.25), 
        cc.RemoveSelf:create()
    ))
end


-------------------------------------------------
-- private

function CatHouseCardNode:updateIdentity_()
    local identityNode = CatHouseUtils.GetBusinessCardNode(self:getIdentityId(), self:getMemberName())
    self:getViewData().identityLayer:addAndClear(identityNode):alignTo(nil, ui.ct)
end


function CatHouseCardNode:updateCardSkin_()
    -- new cardSpine
    local cardSkinId   = self:getCardSkinId()
    local initAniName  = self:isReachTargetPoint() and 'idle' or 'run'
    local newCardSpine = ui.cardSpineNode({skinId = cardSkinId, scale = 0.45, cacheName = SpineCacheName.CAT_HOUSE, spineName = cardSkinId, init = initAniName})
    self:getViewData().avatarLayer:add(newCardSpine)

    -- show cardSpine
    newCardSpine:setOpacity(0)
    newCardSpine:runAction(cc.FadeIn:create(0.2))

    -- check has old spine
    local oldCardSpine = self.cardSpineNode_
    if oldCardSpine then
        oldCardSpine:stopAllActions()
        oldCardSpine:runAction(cc.Sequence:create(
            cc.FadeOut:create(0.2),
            cc.RemoveSelf:create()
        ))
        
        -- switch spine
        local smokeSpine = ui.spine({cache = SpineCacheName.CAT_HOUSE, path = RES_DICT.SMOKE_SPINE, scale = 0.5, init = 'go', loop = false})
        smokeSpine:registerSpineEventHandler(function(event)
            smokeSpine:runAction(cc.RemoveSelf:create())
        end, sp.EventType.ANIMATION_COMPLETE)
        self:getViewData().avatarLayer:add(smokeSpine)
        
        PlayAudioClip(AUDIOS.UI.ui_union_change.id)
    end
    
    -- update data
    self.cardSpineNode_ = newCardSpine
end


-------------------------------------------------
-- handler

function CatHouseCardNode:onClickCardNodeHandler_(sender)
    PlayAudioByClickNormal()

    app:DispatchObservers(SGL.CAT_HOUSE_CLICK_MEMBER, {memberId = self:getMemberId(), memberType = CatHouseUtils.MEMBER_TYPE.ROLE}) 
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function CatHouseCardNode.CreateView()
    local size = CARD_NODE_SIZE
    local view = ui.layer({size = size})

    view:addChild(ui.image({img = RES_DICT.AVATAR_SHADOW, p = cc.p(size.width/2, 0), scale = 0.35}))

    local avatarLayer = ui.layer({p = cc.p(size.width/2, 0)})
    view:add(avatarLayer)

    local identityLayer = ui.layer()
    view:addList(identityLayer):alignTo(nil, ui.ct, {offsetY = -size.height})

    local bubbleLayer = ui.layer()
    view:addList(bubbleLayer):alignTo(nil, ui.cb, {offsetY = size.height})

    local clickArea = ui.layer({size = CARD_NODE_SIZE, color = cc.r4b(0), enable = true})
    view:add(clickArea)

    return {
        view          = view,
        avatarLayer   = avatarLayer,
        identityLayer = identityLayer,
        bubbleLayer   = bubbleLayer,
        clickArea     = clickArea,
    }
end


return CatHouseCardNode
