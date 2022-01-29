--[[
 * author : kaishiqi
 * descpt : 猫屋 - 猫咪节点
]]
local CatHouseCatNode = class('CatHouseCatNode', function()
    return ui.layer({name = 'CatHouseCatNode', enableEvent = true})
end)

local RES_DICT = {
    CAT_SHADOW = _res('ui/battle/battle_role_shadow.png'),
    CAT_ARROW  = _res('ui/catModule/catList/cat_house_ico_arrowhead.png'),
}

local CARD_NODE_SIZE  = cc.size(120, 140)
local CAT_SPINE_SCALE = 0.5
local HOUSE_CAT_STATE = {
    FREE   = 1, -- 空闲
    MOVE   = 2, -- 行走
    --ACTOR  = 3, -- 行为
}


function CatHouseCatNode:ctor(args)
    self:setAnchorPoint(ui.cb)
    self:setContentSize(CARD_NODE_SIZE)

    self.viewData_ = CatHouseCatNode.CreateView()
    self:add(self.viewData_.view)

    ui.bindClick(self:getViewData().clickArea, handler(self, self.onClickCatNodeHandler_))
    self.autoEventCloker_ = app.timerMgr.CreateClocker(handler(self, self.onAutoEventClokerHandler_), 5)
end

function CatHouseCatNode:onEnter()
    app:RegistObserver(SGL.CAT_MODEL_UPDATE_ALIVE, mvc.Observer.new(self.onCatModuleAliveUpdate_, self))
end

function CatHouseCatNode:onExit()
    app:UnRegistObserver(SGL.CAT_MODEL_UPDATE_ALIVE, self)
    if self.autoEventCloker_ then
        self.autoEventCloker_:stop()
    end
end


-------------------------------------------------
-- get / set

function CatHouseCatNode:getViewData()
    return self.viewData_
end


-- memberId
function CatHouseCatNode:getMemberId()
    return self.memberId_
end
function CatHouseCatNode:setMemberId(memberId)
    self.memberId_  = memberId
    self.catModel_ = app.catHouseMgr:getCatModel(self:getMemberId())
    self:getViewData().clickArea.memberId = self:getMemberId()
end


function CatHouseCatNode:isMyCat()
    return self:getMyCatModel() ~= nil
end


---@return HouseCatModel
function CatHouseCatNode:getMyCatModel()
    return self.catModel_
end


-- target point
function CatHouseCatNode:getTargetPoint()
    return self.targetPoint_
end
function CatHouseCatNode:setTargetPoint(targetPoint)
    self.targetPoint_ = targetPoint

    if self.targetPoint_ then
        self.targetPoint_.x = checkint(self.targetPoint_.x)
        self.targetPoint_.y = checkint(self.targetPoint_.y)

        local currentX = checkint(self:getPositionX())
        local currentY = checkint(self:getPositionY())
        local targetX  = checkint(self:getTargetPoint().x)
        local targetY  = checkint(self:getTargetPoint().y)
        if currentX ~= targetX then
            self:getViewData().avatarLayer:setScaleX(currentX < targetX and 1 or -1)
        end

        if self.catSpineNode_ then
            if self.catSpineNode_:isIdlingAnime() then
                if math.abs(currentX - targetX) > 150 or math.abs(currentY - targetY) > 150 then
                    self.catSpineNode_:doRunAnime()
                else
                    self.catSpineNode_:doWalkAnime()
                end
            end
        end
    else

        if self.catSpineNode_ then
            if not self.catSpineNode_:isIdlingAnime() then
                self.catSpineNode_:doIdleAnime()
            end
        end
    end
end


function CatHouseCatNode:isReachTargetPoint()
    if self:getTargetPoint() then
        return (checkint(self:getTargetPoint().x) == checkint(self:getPositionX()) and 
                checkint(self:getTargetPoint().y) == checkint(self:getPositionY()))
    else
        return true
    end
end


-- memberData
function CatHouseCatNode:getMemberData()
    return self.memberData_
end
function CatHouseCatNode:setMemberData(memberData)
    self.memberData_ = checktable(memberData)
    if memberData.leftPlayTimes then self:setLeftPlayTimes(memberData.leftPlayTimes) end
    if memberData.leftFeedTimes then self:setLeftFeedTimes(memberData.leftFeedTimes) end
    if memberData.age           then self:setMemberAge(memberData.age) end
    if memberData.catId         then self:setMemberRaceId(memberData.catId) end
    if memberData.gene          then self:setMemberGeneIdList(memberData.gene) end
    if memberData.friendId      then self:setFriendId(memberData.friendId) end
    local isDie = false
    if memberData.alive then
        isDie = checkint(memberData.alive) == 0
    end
    self:setMemberDie(isDie)
    self:getViewData().arrowBg:setVisible(memberData.needArrow == true)
end


-- leftPlayTimes
function CatHouseCatNode:setLeftPlayTimes(leftPlayTimes)
    self.leftPlayTimes_ = checkint(leftPlayTimes)
end
function CatHouseCatNode:getLeftPlayTimes()
    return checkint(self.leftPlayTimes_)
end


-- leftPlayTimes
function CatHouseCatNode:setLeftFeedTimes(leftFeedTimes)
    self.leftFeedTimes_ = checkint(leftFeedTimes)
end
function CatHouseCatNode:getLeftFeedTimes()
    return checkint(self.leftFeedTimes_)
end


-- friend Id
function CatHouseCatNode:getFriendId()
    return checkint(self.friendId_)
end
function CatHouseCatNode:setFriendId(friendId)
    self.friendId_ = checkint(friendId)
end


-- member gene list
function CatHouseCatNode:getMemberGeneIdList()
    return checktable(self.memberGeneIdList_)
end
function CatHouseCatNode:setMemberGeneIdList(geneIdList)
    self.memberGeneIdList_ = checktable(geneIdList)
end


-- member raceId
function CatHouseCatNode:setMemberRaceId(raceId)
    self.memberRaceId_ = checkint(raceId)
end


-- member conf id
function CatHouseCatNode:getCatRaceId()
    local catModule = self:getMyCatModel()
    if catModule then
        return catModule:getRace()
    else
        return checkint(self.memberRaceId_)
    end
end


-- member age
function CatHouseCatNode:setMemberAge(age)
    self.memberAge_ = checkint(age)
end
function CatHouseCatNode:getMemberAge()
    local catModule = self:getMyCatModel()
    if catModule then
        return catModule:getAge()
    else
        return checkint(self.memberAge_)
    end
end


-- member gene list
function CatHouseCatNode:isMemberDie()
    local catModel = self:getMyCatModel()
    if catModel then
        return not catModel:isAlive()
    else
        return checkbool(self.isMemberDie_)
    end
end
function CatHouseCatNode:setMemberDie(isDie)
    self.isMemberDie_ = checkbool(isDie)
    self:updateCatAliveState()
end
-------------------------------------------------
-- public

function CatHouseCatNode:eraseFromParent(hasEffect)
    self:removeFromParent()
end


function CatHouseCatNode:updateCatSpineNode()
    self:getViewData().avatarLayer:removeAllChildren()
    
    local initAnime = self:isReachTargetPoint() and 'idle' or 'run'
    local catParams = {}
    if self:getMyCatModel() then
        catParams = {initAnime = initAnime, catUuid = self:getMemberId(), scale = CAT_SPINE_SCALE, freeMode = true}
    else
        catParams = {initAnime = initAnime, catData = {gene = self:getMemberGeneIdList(), catId = self:getCatRaceId(), age = self:getMemberAge(), isAlive = not self:isMemberDie()}, scale = CAT_SPINE_SCALE}
    end
    self.catSpineNode_ = CatHouseUtils.GetCatSpineNode(catParams)
    self:getViewData().avatarLayer:addList(self.catSpineNode_):alignTo(nil, ui.cb)
end


function CatHouseCatNode:onAutoEventClokerHandler_()
    if self:isMemberDie() then
        return
    end
    local actionTagList = table.keys(HOUSE_CAT_STATE)
    local actionTag     = HOUSE_CAT_STATE[actionTagList[math.random(1, #actionTagList)]]

    if actionTag == HOUSE_CAT_STATE.MOVE then
        AppFacade.GetInstance():DispatchObservers(SGL.CAT_HOUSE_MEMBER_WALK, {memberId = self:getMemberId(), memberType = CatHouseUtils.MEMBER_TYPE.CAT})
    end
end


function CatHouseCatNode:onCatModuleAliveUpdate_(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    if self:getMemberId() == data.catUuid then
        self:updateCatAliveState()
    end
end


function CatHouseCatNode:updateCatAliveState()
    if self:isMemberDie() and self.autoEventCloker_ then
        self.autoEventCloker_:stop()
    elseif self.autoEventCloker_ then
        self.autoEventCloker_:start()
    end
end

-------------------------------------------------
-- handler

function CatHouseCatNode:onClickCatNodeHandler_(sender)
    PlayAudioByClickNormal()
    if app.catHouseMgr:getHouseOwnerId() ~= app.gameMgr:GetPlayerId() then
        return
    end

    app:DispatchObservers(SGL.CAT_HOUSE_CLICK_MEMBER, {memberId = self:getMemberId(), memberType = CatHouseUtils.MEMBER_TYPE.CAT}) 
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function CatHouseCatNode.CreateView()
    local size = CARD_NODE_SIZE
    local view = ui.layer({size = size})

    view:addChild(ui.image({img = RES_DICT.CAT_SHADOW, p = cc.p(size.width/2, 0), scale = 0.35}))

    local avatarLayer = ui.layer({color = cc.r4b(0), enable = true, size = size, ap = ui.cc})
    view:addList(avatarLayer):alignTo(nil, ui.cc)

    local arrowBg = ui.image({img = RES_DICT.CAT_ARROW})
    view:addList(arrowBg):alignTo(nil, ui.ct)
    arrowBg:setVisible(false)
    arrowBg:runAction(cc.RepeatForever:create(cc.Sequence:create(
        cc.JumpBy:create(0.8, cc.p(0,0), 16, 1),
        cc.DelayTime:create(0.1)
    )))

    local bubbleLayer = ui.layer()
    view:addList(bubbleLayer):alignTo(nil, ui.cb, {offsetY = size.height})

    local clickArea = ui.layer({size = CARD_NODE_SIZE, color = cc.r4b(0), enable = true})
    view:add(clickArea)

    return {
        view        = view,
        avatarLayer = avatarLayer,
        bubbleLayer = bubbleLayer,
        clickArea   = clickArea,
        arrowBg     = arrowBg,
    }
end


return CatHouseCatNode

