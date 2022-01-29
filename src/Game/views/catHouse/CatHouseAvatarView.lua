--[[
 * author : panmeng
 * descpt : 猫屋 = 家具视图
]]
local CatHouseCatNode     = require('Game.views.catHouse.avatar.CatHouseCatNode')
local CatHouseDragNode    = require('Game.views.catHouse.avatar.CatHouseDragNode')
local CatHouseCardNode    = require('Game.views.catHouse.avatar.CatHouseCardNode')
local CatHouseBaseNode    = require('Game.views.catHouse.avatar.CatHouseAvatarNode')
local CatHouseHandNode    = require('Game.views.catHouse.avatar.CatHouseHandlerNode')
local CatHouseTriggerNode = require('Game.views.catHouse.avatar.CatHouseTriggerNode')
---@class CatHouseAvatarView
local CatHouseAvatarView  = class('CatHouseAvatarView', function()
    return ui.layer({name = 'Game.views.catHouse.CatHouseAvatarView', enableEvent = true})
end)

local RES_DICT = {
}

local AVATAR_SIZE = cc.size(1334, 1002)
local TILED_SIZE  = CatHouseUtils.AVATAR_TILED_SIZE
local TILED_AREA  = CatHouseUtils.AVATAR_TILED_AREA
local SHOW_TILED  = false



function CatHouseAvatarView:ctor(args)
    -- init vars
    self.avatarNodeMap_  = {}  -- 所有家具节点
    self.memberNodeMap_  = {}  -- 所有成员节点（人、猫）
    self.spineLoadList_  = {}  -- 需要加载的动画数据
    self.triggerNodeMap_ = {}  -- 需要加载的交互节点
    
    -- create view
    self.viewData_ = CatHouseAvatarView.CreateView()
    self:addChild(self.viewData_.view)
end


function CatHouseAvatarView:onCleanup()
    self:endedCheckAvatarSpineLoad_()
end


-------------------------------------------------
-- get / set

function CatHouseAvatarView:getViewData()
    return self.viewData_
end
function CatHouseAvatarView:getHandlerNode()
    return self:getViewData().handlerNode
end


function CatHouseAvatarView:isDecortingStatue()
    return self.isDecorting_ == true
end
function CatHouseAvatarView:setDecortingStatue(isDecorting)
    self.isDecorting_ = checkbool(isDecorting)

    -- hide all members
    for _, avatarMembers in pairs(self:getAllMemberMap()) do
        for _, avatarMember in pairs(avatarMembers) do
            avatarMember:setVisible((not self:isDecortingStatue()))
        end
    end

    self:getViewData().triggerLayer:setVisible(not self:isDecortingStatue())
end


-------------------------------------------------------------------------------
-- avatar method
-------------------------------------------------------------------------------

function CatHouseAvatarView:cleanAllAvatarNode()
    for _, avatarNode in pairs(self.avatarNodeMap_) do
        avatarNode:removeFromParent()
    end
    self.avatarNodeMap_ = {}
    self:resetTiledMapData_()

    self:getViewData().avatarWallLayer:removeAllChildren()
    self:getViewData().avatarFloorLayer:removeAllChildren()
    self:getViewData().avatarEffectLayer:removeAllChildren()
    self:getViewData().avatarCeilingLayer:removeAllChildren()
end


function CatHouseAvatarView:removeAvatarNode(avatarUuid)
    if self:getAvatarNode(avatarUuid) then
        self.avatarNodeMap_[checkint(avatarUuid)]:removeFromParent()
        self.avatarNodeMap_[checkint(avatarUuid)] = nil
    end
end


function CatHouseAvatarView:getAvatarNode(avatarUuid)
    return self.avatarNodeMap_[checkint(avatarUuid)]
end


--[[
    @param avatarUuid : int      家具唯一id
    @param avatarData : table    家具数据
    {
        goodsId      : int     家具配表id
        effectivePos : cc.p    有效层坐标（可选）
        isCleanTiled : bool    是否 清除格子数据（可选）
        isFillTiled  : bool    是否 填充格子数据（可选）
    }
]]
function CatHouseAvatarView:appendAvatarNode(avatarUuid, avatarData)
    if avatarData then
        local avatarId     = checkint(avatarData.goodsId)
        local avatarType   = CatHouseUtils.GetAvatarTypeByGoodsId(avatarId)
        local locationConf = CONF.CAT_HOUSE.AVATAR_LOCATION:GetValue(avatarId)
        local locationInfo = string.split(checkstr(checktable(locationConf.location)[1]), ',')
        
        if avatarType == CatHouseUtils.AVATAR_TYPE.WALL then
            local avatarNode = CatHouseBaseNode.new({confId = avatarId, x = display.cx, y = locationInfo[2], ap = ui.cb})
            self:getViewData().avatarWallLayer:removeAllChildren()
            self:getViewData().avatarWallLayer:addChild(avatarNode)
        
        elseif avatarType == CatHouseUtils.AVATAR_TYPE.FLOOR then
            local avatarNode = CatHouseBaseNode.new({confId = avatarId, x = display.cx, y = locationInfo[2], ap = ui.cb})
            self:getViewData().avatarFloorLayer:removeAllChildren()
            self:getViewData().avatarFloorLayer:addChild(avatarNode)
        
        elseif avatarType == CatHouseUtils.AVATAR_TYPE.CELLING then
            local avatarNode = CatHouseBaseNode.new({confId = avatarId, x = display.cx, y = locationInfo[2], ap = ui.cb})
            self:getViewData().avatarCeilingLayer:removeAllChildren()
            self:getViewData().avatarCeilingLayer:addChild(avatarNode)
        
        else
            local dragNode = CatHouseDragNode.new({uuid = avatarUuid, avatarId = avatarId})
            self:getViewData().avatarNodeLayer:addChild(dragNode)
            self.avatarNodeMap_[checkint(avatarUuid)] = dragNode
            
            -- update avatar
            dragNode:setTempMode(avatarData.isTempMode == true)
            dragNode:setDamageStatue(avatarData.damaged == 1)
            avatarData.isFillTiled  = not dragNode:isTempMode() and true or false
            avatarData.effectivePos = avatarData.effectivePos or avatarData.location
            self:updateAvatarNode(avatarUuid, avatarData)
        end
    end
end


function CatHouseAvatarView:updateAvatarNode(avatarUuid, updateData)
    local avatarNode = self:getAvatarNode(avatarUuid)
    if avatarNode and updateData then

        local isDirtyOrder = false
        if updateData.editingOrder ~= nil then
            isDirtyOrder = true
            avatarNode:setEditing(updateData.editingOrder)
        end

        if updateData.effectivePos then
            local fixedPos = self:fixedAvatarEffectivePos(avatarNode, updateData.effectivePos)
            local tiledPos = self:convertToTiledPos(fixedPos)
            if updateData.tiledPos == nil then
                updateData.tiledPos = tiledPos
            end
        end
        if updateData.tiledPos then
            local tiledPos  = updateData.tiledPos
            local newstPos  = cc.p(TILED_SIZE.width * tiledPos.x, TILED_SIZE.height * tiledPos.y)
            local worldPos  = self:getViewData().avatarEffectiveLayer:convertToWorldSpace(newstPos)
            local targetPos = cc.p(worldPos.x - avatarNode:getOffsetPoint().x, worldPos.y - avatarNode:getOffsetPoint().y)
            avatarNode:setTiledPos(tiledPos)
            avatarNode:setPosition(targetPos)
            avatarNode:setCollison(self:isCollisionTiled(avatarNode:getTiledRect()))
            isDirtyOrder = true
        end
        
        if isDirtyOrder then
            if avatarNode:isEditing() then
                avatarNode:setLocalZOrder(display.height)
            else
                avatarNode:setLocalZOrder(display.height - avatarNode:getRectPosY())
            end
        end

        if updateData.isCleanTiled then
            self:cleanTiledMapData_(avatarNode:getTiledRect(), checkint(avatarUuid))
            if SHOW_TILED then self:refreshTiledTestLayer_() end
        end

        if updateData.isFillTiled then
            self:fillTiledMapData_(avatarNode:getTiledRect(), checkint(avatarUuid))
            avatarNode:setLocalZOrder(display.height - avatarNode:getRectPosY())
            if SHOW_TILED then self:refreshTiledTestLayer_() end
        end
    end
end


function CatHouseAvatarView:reloadAvatars(avatarMap)
    self:cleanAllAvatarNode()

    for avatarUuid, avatarData in pairs(avatarMap or {}) do
        self:appendAvatarNode(avatarUuid, avatarData)
    end
end


function CatHouseAvatarView:isTouchAvatarNode(avatarNode, touchPos)
    if avatarNode and touchPos then
        return cc.rectContainsPoint(avatarNode:getBoundingBox(), touchPos)
    end
    return false
end


--[[
    根据 触摸点 返回按到的家具
]]
function CatHouseAvatarView:getTouchAvatarNode(touchPos)
    local touchedNodeList = {}
    for _, avatarNode in pairs(self.avatarNodeMap_) do
        if self:isTouchAvatarNode(avatarNode, touchPos) then
            table.insert(touchedNodeList, avatarNode)
        end
    end
    local touchedNode = nil
    for _, avatarNode in ipairs(touchedNodeList) do
        if touchedNode then
            if avatarNode:getLocalZOrder() > touchedNode:getLocalZOrder() then
                touchedNode = avatarNode
            end
        else
            touchedNode = avatarNode
        end
    end
    return touchedNode
end


function CatHouseAvatarView:fixedAvatarEffectivePos(avatarNode, effectivePos)
    if avatarNode and effectivePos then
        local cellW    = avatarNode:getFixedWidth()
        local cellH    = avatarNode:getFixedHeight()
        local limitL   = 0
        local limitB   = 0
        local limitR   = self:getViewData().avatarEffectiveLayer:getContentSize().width - cellW
        local limitT   = self:getViewData().avatarEffectiveLayer:getContentSize().height - cellH
        effectivePos.x = math.min(math.max(limitL, effectivePos.x), limitR)
        effectivePos.y = math.min(math.max(limitB, effectivePos.y), limitT)
    end
    return effectivePos
end


--[[
    根据 视图坐标 转化 网格坐标
]]
function CatHouseAvatarView:convertToTiledPos(pos)
    local nowPos = pos or cc.p(0,0)
    local tiledX = math.round(checkint(nowPos.x) / TILED_SIZE.width)
    local tiledY = math.round(checkint(nowPos.y) / TILED_SIZE.height)
    tiledX = math.max(0, math.min(tiledX, TILED_AREA.width))
    tiledY = math.max(0, math.min(tiledY, TILED_AREA.height))
    return cc.p(tiledX, tiledY)
end


--[[
    清空 家具网格数据
]]
function CatHouseAvatarView:resetTiledMapData_()
    self.tileMapUsed_ = {}
    self.tileMapFree_ = {}

    for row = 0, TILED_AREA.height - 1 do
        self.tileMapFree_[row] = {}
        self.tileMapUsed_[row] = {}
        for col = 0, TILED_AREA.width - 1 do
            self.tileMapFree_[row][col] = true
        end
    end

    if SHOW_TILED then self:refreshTiledTestLayer_() end
end


--[[
    填充 家具网格数据
    @param tiledRect  : cc.rect    网格范围
    @param avatarUuid : int        家具uuid
]]
function CatHouseAvatarView:fillTiledMapData_(tiledRect, avatarUuid)
    local startX = math.max(tiledRect.x, 0)
    local startY = math.max(tiledRect.y, 0)
    local endedX = math.min(startX + tiledRect.width - 1, TILED_AREA.width - 1)
    local endedY = math.min(startY + tiledRect.height - 1, TILED_AREA.height - 1)

    for row = startY, endedY do
        for col = startX, endedX do
            self.tileMapUsed_[row][col] = avatarUuid
            self.tileMapFree_[row][col] = nil
        end
    end
end


--[[
    清除 家具网格数据
    @param tiledRect  : cc.rect    网格范围
    @param avatarUuid : int        家具uuid
]]
function CatHouseAvatarView:cleanTiledMapData_(tiledRect, avatarUuid)
    local startX = math.max(tiledRect.x, 0)
    local startY = math.max(tiledRect.y, 0)
    local endedX = math.min(startX + tiledRect.width - 1, TILED_AREA.width - 1)
    local endedY = math.min(startY + tiledRect.height - 1, TILED_AREA.height - 1)

    for row = startY, endedY do
        for col = startX, endedX do
            if self.tileMapUsed_[row] and self.tileMapUsed_[row][col] == avatarUuid then
                self.tileMapUsed_[row][col] = nil
                self.tileMapFree_[row][col] = true
            end
        end
    end
end


--[[
    是否 碰撞到网格
    @param tiledRect  : cc.rect    网格范围
]]
function CatHouseAvatarView:isCollisionTiled(tiledRect)
    local startX = checkint(tiledRect.x)
    local startY = checkint(tiledRect.y)
    local endedX = checkint(startX + tiledRect.width - 1)
    local endedY = checkint(startY + tiledRect.height - 1)
    for row = startY, endedY do
        for col = startX, endedX do
            if self.tileMapUsed_[row] ~= nil and self.tileMapUsed_[row][col] ~= nil then
                return true
            end
        end
    end
    return false
end


--[[
    查找 可用网格位置
    @param tiledSize   : cc.size    网格尺寸
    @return tiledRect  : cc.rect    网格范围
]]
function CatHouseAvatarView:findFreeTiledRect(tiledSize)
    local row             = TILED_AREA.height - 1
    local keyTab          = {}
    local findWidthIsFit  = false
    local everyRowFreeNum = {}
    local resetInitRow    = 0
    local curRowFreeNum   = 0

    while(row >= tiledSize.height - 1) do
        keyTab    = table.keys(self.tileMapFree_[row])

        if #keyTab < tiledSize.width then
            row = row - 1
        else
            resetInitRow = row
            for rowIndex = row - 1, row - tiledSize.height + 1, -1 do
                curRowFreeNum = everyRowFreeNum[rowIndex]
                if not curRowFreeNum then
                    everyRowFreeNum[rowIndex] = table.nums(self.tileMapFree_[rowIndex])
                    curRowFreeNum             = everyRowFreeNum[rowIndex]
                end
                if curRowFreeNum < tiledSize.width then
                    resetInitRow  = rowIndex - 1
                end
            end

            if resetInitRow >= row then
                table.sort(keyTab, function(a,b)
                    return a < b
                end)

                while(#keyTab >= tiledSize.width) do
                    findWidthIsFit = true
                    for col = keyTab[1] + 1, keyTab[1] + tiledSize.width - 1 do
                        if not self.tileMapFree_[row][col] then
                            table.remove(keyTab, 1)
                            findWidthIsFit = false
                            break
                        end
                    end
                    if findWidthIsFit then
                        if self:findFitRectByInitPos_(row - 1, keyTab[1], tiledSize.width, tiledSize.height) then
                            return cc.rect(keyTab[1], row - tiledSize.height + 1, tiledSize.width, tiledSize.height)
                        else
                            table.remove(keyTab, 1)
                        end
                    end
                end
                row = row - 1
            else
                row = resetInitRow
            end
        end
    end
end
function CatHouseAvatarView:findFitRectByInitPos_(initRow, initCol, width, height)
    for row = initRow, initRow - height + 1, -1 do
        for col = initCol, initCol + width - 1 do
            if not self.tileMapFree_[row] or not self.tileMapFree_[row][col] then
                return false
            end
        end
    end
    return true
end


function CatHouseAvatarView:refreshTiledTestLayer_()
    if self:getViewData().tiledTestLayer == nil then
        local tiledTestLayer = cc.DrawNode:create(2)
        self:getViewData().view:add(tiledTestLayer)
        self:getViewData().tiledTestLayer = tiledTestLayer
    end
    
    local boundingBox = self:getViewData().avatarEffectiveLayer:getBoundingBox()
    self:getViewData().tiledTestLayer:clear()
    for row = 1, TILED_AREA.height do
        for col = 1, TILED_AREA.width do
            local i = row + col
            local p = cc.pAdd(cc.p(TILED_SIZE.width * (col - 1), TILED_SIZE.height * (row - 1)), cc.p(boundingBox.x, boundingBox.y))
            if self.tileMapFree_[row-1] and self.tileMapFree_[row-1][col-1] then
                self:getViewData().tiledTestLayer:drawSolidRect(p, cc.rep(p, TILED_SIZE.width, TILED_SIZE.height), cc.c4f(0,0.5,0,0.5))
                self:getViewData().tiledTestLayer:drawRect(p, cc.rep(p, TILED_SIZE.width, TILED_SIZE.height), cc.c4f(0,0.5,0,1))
            end
            if self.tileMapUsed_[row-1] and self.tileMapUsed_[row-1][col-1] then
                self:getViewData().tiledTestLayer:drawSolidRect(p, cc.rep(p, TILED_SIZE.width, TILED_SIZE.height), cc.c4f(0.5,0,0,0.5))
                self:getViewData().tiledTestLayer:drawRect(p, cc.rep(p, TILED_SIZE.width, TILED_SIZE.height), cc.c4f(0.5,0,0,1))
            end
        end
    end
end


-------------------------------------------------------------------------------
-- mebmer method
-------------------------------------------------------------------------------

--[[
    获取 全部成员节点
]]
function CatHouseAvatarView:getAllMemberMap()
    return checktable(self.memberNodeMap_)
end


--[[
    清除 全部成员节点
]]
function CatHouseAvatarView:cleanAllMembers()
    for _, memberNodes in pairs(self:getAllMemberMap()) do
        for _, memberNode in pairs(memberNodes) do
            memberNode:eraseFromParent()
        end
    end
    self.memberNodeMap_ = {}
    
    -- clean spineLoad
    self.spineLoadList_ = {}
    self:endedCheckAvatarSpineLoad_()
end


--[[
    获取 指定成员节点
    @param memberType : int    成员类型 @see CatHouseUtils.MEMBER_TYPE
    @param memberId   : int    成员id
]]
function CatHouseAvatarView:getMemberNode(memberType, memberId)
    return self.memberNodeMap_[checkint(memberType)] and self.memberNodeMap_[checkint(memberType)][tostring(memberId)] or nil
end


--[[
    移除 指定成员节点
    @param memberType : int    成员类型 @see CatHouseUtils.MEMBER_TYPE
    @param memberId   : int    成员id
]]
function CatHouseAvatarView:removeMemberCell(memberType, memberId)
    local memberNode = self:getMemberNode(memberType, memberId)
    if memberNode then
        memberNode:eraseFromParent(not self:isDecortingStatue())
    end
    if self.memberNodeMap_[checkint(memberType)] and memberId ~= nil then
        self.memberNodeMap_[checkint(memberType)][tostring(memberId)] = nil
    end
end


--[[
    添加 指定成员节点
    @param memberType : int      成员类型 @see CatHouseUtils.MEMBER_TYPE
    @param memberData : table    成员数据
    {
        memberId     : int     成员id
        memberName   : str     卡牌名字（可选）
        head         : int     卡牌皮肤id（可选）
        bubble       : int     卡牌气泡id（可选）
        businessCard : int     卡牌名片id（可选）
        effectivePos : cc.p    有效层坐标（可选）
    }
]]
function CatHouseAvatarView:appendMemberCell(memberType, _memberData)
    local memberData = checktable(_memberData)
    local memberId   = tostring(memberData.memberId)
    local memberNode = self:getMemberNode(memberType, memberId)
    
    -- check memberNode
    if not memberNode then
        if memberType == CatHouseUtils.MEMBER_TYPE.ROLE then
            memberNode = CatHouseCardNode.new()
            memberNode:setPosition(CatHouseUtils.HOUSE_PARAM_FUNCS.INIT_GUEST_POS())

        elseif memberType == CatHouseUtils.MEMBER_TYPE.CAT then
            memberNode = CatHouseCatNode.new()
            memberNode:setPosition(self:createMemberRandomPoint())
        end

        if memberNode then
            -- update memberId
            memberNode:setMemberId(memberId)
            
            -- append data
            self.memberNodeMap_[memberType] = self.memberNodeMap_[memberType] or {}
            self.memberNodeMap_[memberType][memberId] = memberNode

            self:getViewData().avatarNodeLayer:addChild(memberNode)
        end
    end

    -- update memberNode
    self:updateMemberCell(memberType, memberData)
    return memberNode
end


function CatHouseAvatarView:updateMemberCell(memberType, _memberData)
    local memberData = checktable(_memberData)
    local memberId   = tostring(memberData.memberId)
    local memberNode = self:getMemberNode(memberType, memberId)

    if memberNode then
        if memberType == CatHouseUtils.MEMBER_TYPE.ROLE then
            if memberData.memberName then
                memberNode:setMemberName(memberData.memberName)
            end
            
            -- update identity
            if memberData.businessCard then
                memberNode:setIdentityId(memberData.businessCard)
            end

            -- check update bubble
            if memberData.bubble then
                memberNode:setBubbleId(memberData.bubble)
            end
    
            -- update avatarSpine
            if memberData.head then
                self:begainCheckAvatarSpineLoad_({
                    skinId     = memberData.head,
                    memberId   = memberId,
                    memberType = memberType,
                })
            end
            
        elseif memberType == CatHouseUtils.MEMBER_TYPE.CAT then
            memberNode:setMemberData(memberData)

            -- update catSpine
            self:begainCheckAvatarSpineLoad_({
                memberId   = memberId,
                memberType = memberType,
            })
        end
            
        -- update effectivePos
        if memberData.effectivePos then
            local worldPos = self:getViewData().avatarEffectiveLayer:convertToWorldSpace(memberData.effectivePos)
            memberNode:setTargetPoint(worldPos)
        end
        
        -- update memberCell
        memberNode:setLocalZOrder(display.height - checkint(memberNode:getPositionY()))
        memberNode:setVisible((not self:isDecortingStatue()))
    end
end


function CatHouseAvatarView:toLoadMemberSpine_(spineLoadData)
    local skinId     = checkint(spineLoadData.skinId)
    local memberId   = tostring(spineLoadData.memberId)
    local memberType = checkint(spineLoadData.memberType)
    local memberNode = self:getMemberNode(memberType, memberId)

    if memberNode then
        if spineLoadData.memberType == CatHouseUtils.MEMBER_TYPE.ROLE then
            memberNode:setCardSkinId(skinId)

        elseif spineLoadData.memberType == CatHouseUtils.MEMBER_TYPE.CAT then
            memberNode:updateCatSpineNode()

        end
    end
end


function CatHouseAvatarView:fixedMemberEffectivePos(memberCell, effectivePos)
    if memberCell and effectivePos then
        local cellW    = memberCell:getContentSize().width
        local cellH    = memberCell:getContentSize().height
        local limitL   = cellW/2
        local limitB   = 0
        local limitR   = self:getViewData().avatarEffectiveLayer:getContentSize().width - cellW/2
        local limitT   = self:getViewData().avatarEffectiveLayer:getContentSize().height - TILED_SIZE.height
        effectivePos.x = math.min(math.max(limitL, effectivePos.x), limitR)
        effectivePos.y = math.min(math.max(limitB, effectivePos.y), limitT)
    end
    return effectivePos
end


function CatHouseAvatarView:reorderAllMembers()
    for memberType, memberNodes in pairs(self:getAllMemberMap()) do
        for _, memberNode in pairs(memberNodes) do
            memberNode:setLocalZOrder(display.height - checkint(memberNode:getPositionY()))
        end
    end
end


function CatHouseAvatarView:createMemberRandomPoint()
    local effectivePos = cc.p(self:getViewData().avatarEffectiveLayer:getPosition())
    local targetPosX   = math.random(0, CatHouseUtils.AVATAR_SAFE_SIZE.width)
    local targetPosY   = math.random(0, CatHouseUtils.AVATAR_SAFE_SIZE.height)
    return cc.p(targetPosX + effectivePos.x - CatHouseUtils.AVATAR_SAFE_SIZE.width / 2, targetPosY + effectivePos.y - CatHouseUtils.AVATAR_SAFE_SIZE.height / 2)
end


-------------------------------------------------------------------------------
-- trigger event func
-------------------------------------------------------------------------------
--[[
    加入 触发事件 节点
    @param triggerData  :table 触发事件数据
]]
function CatHouseAvatarView:appendTriggerNode(triggerData)
    local triggerNode = CatHouseTriggerNode.new(triggerData)
    self:getViewData().triggerLayer:add(triggerNode)

    self.triggerNodeMap_[checkint(triggerData.eventUuid)] = triggerNode
end


function CatHouseAvatarView:getTriggerNodeMap()
    return self.triggerNodeMap_
end


function CatHouseAvatarView:removeTriggerNode(triggerId)
    if self.triggerNodeMap_[checkint(triggerId)] then
        self.triggerNodeMap_[checkint(triggerId)]:eraseFromParent()
        self.triggerNodeMap_[checkint(triggerId)] = nil
    end
end


function CatHouseAvatarView:removeAllTriggerNode()
    self:getViewData().triggerLayer:removeAllChildren()
    self.triggerNodeMap_ = {}
end


-------------------------------------------------
-- private

function CatHouseAvatarView:endedCheckAvatarSpineLoad_()
    if self.checkAvatarSpineLoadHandler_ then
        scheduler.unscheduleGlobal(self.checkAvatarSpineLoadHandler_)
        self.checkAvatarSpineLoadHandler_ = nil
    end
end
function CatHouseAvatarView:begainCheckAvatarSpineLoad_(_spineLoadData)
    table.insert(self.spineLoadList_, _spineLoadData)

    if self.checkAvatarSpineLoadHandler_ then return end
    self.checkAvatarSpineLoadHandler_ = scheduler.scheduleGlobal(function()
        if #self.spineLoadList_ > 0 then
            local spineLoadData = table.remove(self.spineLoadList_, 1)
            self:toLoadMemberSpine_(spineLoadData)
        else
            self:endedCheckAvatarSpineLoad_()
        end
    end, 0.25)
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function CatHouseAvatarView.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    ------------------------------------------------- [center]
    local avatarLayer = ui.layer()
    view:add(avatarLayer)

    -- [avatorFloorLayer | avatarWallLayer | avatarEffectiveLayer | avatarTouchLayer | avatarNodeLayer | operatorLayer | avatarCeilingLayer | triggerLayer| avatarEffectLayer]
    local elementLayerGroup = avatarLayer:addList({
        ui.layer({p = cc.p(0, (display.height - AVATAR_SIZE.height) * 0.5)}),
        ui.layer({p = cc.p(0, (display.height - AVATAR_SIZE.height) * 0.5)}),
        ui.layer({p = cc.rep(display.center, 0, -40), size = CatHouseUtils.AVATAR_SAFE_SIZE, ap = ui.cc}),
        ui.layer(),
        ui.layer(),
        ui.layer(), 
        ui.layer({p = cc.p(0, (display.height - AVATAR_SIZE.height) * 0.5)}),
        ui.layer({p = cc.rep(display.center, 0, -40), size = CatHouseUtils.AVATAR_SAFE_SIZE, ap = ui.cc}),
        ui.layer(),
    })

    -- handlerNode
    local handlerNode = CatHouseHandNode.new()
    avatarLayer:add(handlerNode)

    if CatHouseUtils.AVATAR_NODE_DEBUG then
        local tiledLayer = cc.DrawNode:create()
        elementLayerGroup[3]:add(tiledLayer)
        
        for row = 1, TILED_AREA.height do
            for col = 1, TILED_AREA.width do
                local i = row + col
                local p = cc.p(TILED_SIZE.width * (col - 1), TILED_SIZE.height * (row - 1))
                local c = i%2==1 and cc.c4f(0,0,0,0.3) or cc.c4f(0.5,0.5,0.5,0.3)
                tiledLayer:drawSolidRect(p, cc.rep(p, TILED_SIZE.width, TILED_SIZE.height), c)
            end
        end
    end

    return {
        view                 = view,
        avatarLayer          = avatarLayer,
        avatarFloorLayer     = elementLayerGroup[1],
        avatarWallLayer      = elementLayerGroup[2],
        avatarEffectiveLayer = elementLayerGroup[3],
        avatarTouchLayer     = elementLayerGroup[4],
        avatarNodeLayer      = elementLayerGroup[5],
        operatorLayer        = elementLayerGroup[6],
        avatarCeilingLayer   = elementLayerGroup[7],
        triggerLayer         = elementLayerGroup[8],
        avatarEffectLayer    = elementLayerGroup[9],
        handlerNode          = handlerNode,
    }
end


return CatHouseAvatarView
