--[[
 * author : panmeng
 * descpt : 猫屋 - 拖拽节点
]]
local CatHouseDragNode = class('CatHouseDragNode', function()
    return ui.layer({name = 'CatHouseDragNode', enableEvent = true})
end)

local RES_DICT = {
    DAMAGE_SPINE = _spn('ui/catHouse/home/anim/cat_house_repair'),
    REPAIR_SPINE = _spn('ui/catHouse/home/anim/cat_main_repair'),
    REPAIR_BG    = _res('ui/catHouse/home/cat_house_repair_bg.png'),
    COST_BG      = _res('ui/catHouse/home/cat_house_repair_bg_1.png'),
}

local VIEW_NODE_ORDER = {
    AVATAR_LAYER    = 1,  -- 家具
    DRAW_NODE_LAYER = 2,  -- 碰撞框
    DAMEGE_LAYER    = 3,  -- 损坏
}


--[[
    uuid     : int      家具uuid
    avatarId : int      家具Id
]]
function CatHouseDragNode:ctor(args)
    self.uuid_       = checkint(args.uuid)
    self.avatarId_   = checkint(args.avatarId)
    self.avatarConf_ = CONF.CAT_HOUSE.AVATAR_LOCATION:GetValue(self.avatarId_)
    self.offsetPos_  = cc.p(0, 0)
    self.collSize_   = cc.size(0, 0)
    self.fixedSize_  = cc.size(0, 0)
    self.tiledRect_  = cc.rect(0, 0, 0, 0)
    self:setContentSize(cc.size(0, 0))
    self.isTouchEnable = args.enable == nil and true or args.enable

    if next(self.avatarConf_) ~= nil then

        -- avatar node
        self.avatarNode_ = AssetsUtils.GetCatHouseBigAvatarNode(self.avatarId_)
        self:addList(self.avatarNode_, VIEW_NODE_ORDER.AVATAR_LAYER):alignTo(nil, ui.lb)

        -- collision layer
        local offsetInfo       = string.split(tostring(checktable(self.avatarConf_.offset)[1]), ',')
        self.offsetPos_        = cc.p(checkint(offsetInfo[1]), checkint(offsetInfo[2]))
        self.collSize_.width   = checkint(self.avatarConf_.collisionBoxWidth)
        self.collSize_.height  = checkint(self.avatarConf_.collisionBoxLength)
        self.tiledRect_.width  = math.ceil(self.collSize_.width / CatHouseUtils.AVATAR_TILED_SIZE.width)
        self.tiledRect_.height = math.ceil(self.collSize_.height / CatHouseUtils.AVATAR_TILED_SIZE.height)
        self.fixedSize_.width  = self:getTiledWidth() * CatHouseUtils.AVATAR_TILED_SIZE.width
        self.fixedSize_.height = self:getTiledHeight() * CatHouseUtils.AVATAR_TILED_SIZE.height
        
        -- content size
        local avatarSize = self.avatarNode_:getContentSize()
        local dragNodeW  = math.max(avatarSize.width, self.collSize_.width)
        local dragNodeH  = math.max(avatarSize.height, self.collSize_.height)
        self:setContentSize(cc.size(dragNodeW, dragNodeH))

        -- damage layer
        self.damageLayer_ = ui.layer({size = cc.size(dragNodeW, dragNodeH), color = cc.r4b(0), enable = self.isTouchEnable})
        self:add(self.damageLayer_, VIEW_NODE_ORDER.DAMEGE_LAYER)
        ui.bindClick(self.damageLayer_, handler(self, self.onClickRepairNodeHandler_), false)
        
        -- rect drawNode
        self.drawNode_  = cc.DrawNode:create(2)
        local starPoint = self.offsetPos_
        local endPoint  = cc.p(starPoint.x + self.collSize_.width, starPoint.y + self.collSize_.height)
        local rectColor = ccc4fFromInt('#FF9664FF')
        local lineColor = ccc4fFromInt('#FF4B0D4B')
        self.drawNode_:drawSolidRect(starPoint, endPoint, lineColor)
        self.drawNode_:drawRect(starPoint, endPoint, rectColor)
        self:addChild(self.drawNode_, VIEW_NODE_ORDER.DRAW_NODE_LAYER)
        
        -- debug info
        if CatHouseUtils.AVATAR_NODE_DEBUG == true then
            local realRect   = ui.layer({size = cc.size(self.fixedSize_.width, self.fixedSize_.height), p = self.offsetPos_, color = cc.c4b(0,0,0,120)})
            self:add(realRect, VIEW_NODE_ORDER.AVATAR_LAYER)

            local collRect = ui.layer({size = cc.size(self.collSize_.width, self.collSize_.height), p = self.offsetPos_, color = cc.r4b(120)})
            self:add(collRect, VIEW_NODE_ORDER.AVATAR_LAYER)

            local uuidLabel = ui.label({fnt = FONT.D14, text = self.uuid_, ap = ui.lb})
            self:add(uuidLabel, VIEW_NODE_ORDER.AVATAR_LAYER)
        end
    end

    -- init views
    self:setCollison(false)
end


-------------------------------------------------
-- get / set

function CatHouseDragNode:getHandleViewData()
    return self.handleViewData_
end


function CatHouseDragNode:getGoodsUuid()
    return checkint(self.uuid_)
end


function CatHouseDragNode:getGoodsId()
    return checkint(self.avatarId_)
end


function CatHouseDragNode:getOffsetPoint()
    return self.offsetPos_
end


-- coll size
function CatHouseDragNode:getCollWidth()
    return self.collSize_.width
end
function CatHouseDragNode:getCollHeight()
    return self.collSize_.height
end


-- fixed size
function CatHouseDragNode:getFixedWidth()
    return self.fixedSize_.width
end
function CatHouseDragNode:getFixedHeight()
    return self.fixedSize_.height
end


-- tiled rect
function CatHouseDragNode:getTiledRect()
    return self.tiledRect_
end
function CatHouseDragNode:getTiledWidth()
    return self.tiledRect_.width
end
function CatHouseDragNode:getTiledHeight()
    return self.tiledRect_.height
end
function CatHouseDragNode:getTiledPosX()
    return self.tiledRect_.x
end
function CatHouseDragNode:getTiledPosY()
    return self.tiledRect_.y
end
function CatHouseDragNode:setTiledPos(tiledPos)
    self.tiledRect_.x = checkint(tiledPos.x)
    self.tiledRect_.y = checkint(tiledPos.y)
end


-- flag tiledX
function CatHouseDragNode:getFlagTiledX()
    return checkint(self.flagTiledX_)
end
function CatHouseDragNode:setFlagTiledX(tiledX)
    self.flagTiledX_ = checkint(tiledX)
end


-- flag tiledY
function CatHouseDragNode:getFlagTiledY()
    return checkint(self.flagTiledY_)
end
function CatHouseDragNode:setFlagTiledY(tiledY)
    self.flagTiledY_ = checkint(tiledY)
end


-- is tempMode
function CatHouseDragNode:isTempMode()
    return self.isTempMode_ == true
end
function CatHouseDragNode:setTempMode(isTemp)
    self.isTempMode_ = checkbool(isTemp)
    self:changeEditAndTempAnimStatue()
end



-- is editing
function CatHouseDragNode:isEditing()
    return self.isEditing_ == true
end
function CatHouseDragNode:setEditing(isEditing)
    self.isEditing_ = checkbool(isEditing)
    self:changeEditAndTempAnimStatue()
    self:updateDamageLayerEnable()
end


-- is collision
function CatHouseDragNode:isCollision()
    return self.drawNode_ and self.drawNode_:isVisible() or false
end
function CatHouseDragNode:setCollison(isCollision)
    if not self.drawNode_ then return end
    self.drawNode_:setVisible(isCollision == true)
end


-- is damage
function CatHouseDragNode:isDamage()
    return self.isDamage_ == true
end
function CatHouseDragNode:setDamageStatue(isDamage)
    local oldStatue = self:isDamage()
    self.isDamage_ = checkbool(isDamage)

    if self.damageLayer_ then
        if self:isDamage() then
            self.damageLayer_:removeAllChildren()
            self.damageSpine_ = CatHouseDragNode.CreateDamageNode(self:getGoodsId())
            self.damageLayer_:addList(self.damageSpine_):alignTo(nil, ui.cc)

        elseif oldStatue == true then
            if self.damageSpine_ then
                self.damageSpine_:runAction(cc.RemoveSelf:create())
            end
            local repairSpine = ui.spine({path = RES_DICT.REPAIR_SPINE, init = "play", loop = false, cache = SpineCacheName.CAT_HOUSE})
            self.damageLayer_:addList(repairSpine):alignTo(nil, ui.cb)
            repairSpine:registerSpineEventHandler(function()
                repairSpine:runAction(cc.RemoveSelf:create())
            end, sp.EventType.ANIMATION_COMPLETE)
        else
            self.damageLayer_:removeAllChildren()
        end
    end

    self:updateDamageLayerEnable()
end

function CatHouseDragNode:getRectPosY()
    return checkint(self.avatarConf_.type) == 0 and self:getPositionY() or self:getPositionY() + self:getContentSize().height
end

---------------------------------------------------------------
-- handler

function CatHouseDragNode:onClickRepairNodeHandler_()
    PlayAudioByClickNormal()

    if app.catHouseMgr:getHouseOwnerId() ~= app.gameMgr:GetPlayerId() then
        return
    end

    local repairConsume = CatHouseUtils.GetAvatarRepairConsume(self:getGoodsId())
    app.uiMgr:AddCommonTipDialog({
        text = string.fmt(__("是否花费_num__name_修复[_avatarName_]"), {
            _num_ = repairConsume.num, _name_ = GoodsUtils.GetGoodsNameById(repairConsume.goodsId), _avatarName_ = GoodsUtils.GetGoodsNameById(self:getGoodsId())
        }),
        callback = function()
            if app.goodsMgr:getGoodsNum(repairConsume.goodsId) < repairConsume.num then
                if GAME_MODULE_OPEN.NEW_STORE and repairConsume.goodsId == DIAMOND_ID then
                    app.uiMgr:showDiamonTips()
                else
                    app.uiMgr:ShowInformationTips(string.fmt(__("_name_不足"), {_name_ = GoodsUtils.GetGoodsNameById(repairConsume.goodsId)}))
                end
            else
                app:DispatchObservers(SGL.CAT_HOUSE_CLICK_REPAIR_AVATAR, {goodsId = self:getGoodsId(), goodsUuid = self:getGoodsUuid()}) 
            end
        end
    })
    
end


---------------------------------------------------------------
-- public

function CatHouseDragNode:changeEditAndTempAnimStatue()
    self:stopAllActions()
    self:setOpacity(255)

    if self:isEditing() or self:isTempMode() then
        self:runAction(cc.RepeatForever:create(cc.Sequence:create(
            cc.FadeTo:create(0.4, 125),
            cc.FadeTo:create(0.4, 255)
        )))
    end
end


function CatHouseDragNode:updateDamageLayerEnable()
    if self.damageLayer_ then
        self.damageLayer_:setTouchEnabled(self.isTouchEnable and not self:isEditing() and self:isDamage())
    end
end

-------------------------------------------------------------------------------
-- create
function CatHouseDragNode.CreateDamageNode(avatarId)
    local parent = ui.image({img = RES_DICT.REPAIR_BG})

    local spine = ui.spine({path = RES_DICT.DAMAGE_SPINE, init = "idle", loop = true, cache = SpineCacheName.CAT_HOUSE})
    parent:addList(spine):alignTo(nil, ui.cc, {offsetX = -30, offsetY = -85})

    local costBg = ui.image({img = RES_DICT.COST_BG, scale9 = true, cut = cc.dir(5, 5, 5, 5)})
    parent:addList(costBg):alignTo(nil, ui.cb)

    local repairConsume = CatHouseUtils.GetAvatarRepairConsume(avatarId)
    local richLabel = ui.rLabel({r = true, c = {
        {img = CommonUtils.GetGoodsIconPathById(repairConsume.goodsId), scale = 0.15},
        fontWithColor('4', {text = tostring(repairConsume.num), color = "#ffffff"})
    }})
    costBg:setContentSize(cc.size(display.getLabelContentSize(richLabel).width + 20, costBg:getContentSize().height))
    costBg:addList(richLabel):alignTo(nil, ui.cc)

    return parent
end

return CatHouseDragNode