--[[
 * author : panmeng
 * descpt : 猫屋 = 家具中介者
]]
local labelparser            = require('Game.labelparser')
local CatHouseAvatarMediator = class('CatHouseAvatarMediator', mvc.Mediator)

function CatHouseAvatarMediator:ctor(params, viewComponent)
    self.super.ctor(self, 'CatHouseAvatarMediator', viewComponent)
    self.ctorArgs_ = checktable(params)
end

local AVATAR_MOVE_SPEED = 3

-------------------------------------------------
-- inheritance

function CatHouseAvatarMediator:Initial(key)
    self.super.Initial(self, key)
    
    -- init vars
    self.isPreviewMode_      = checkbool(self.ctorArgs_.isPreviewMode)
    self.isControllable_     = true
    self.operateAvatarId_    = nil
    self.operateAvatarUuid_  = nil
    self.selectedAvatarNode_ = nil

    if not self.isPreviewMode_ then
        -- add listener
        self.memberMoveClocker_    = app.timerMgr.CreateClocker(handler(self, self.onMemberMoveUpdateHandler_), 0)
        self:getViewData().avatarTouchLayer:setOnTouchBeganScriptHandler(handler(self, self.onAvatarLayerTouchBeginAction_))
        self:getViewData().avatarTouchLayer:setOnTouchMovedScriptHandler(handler(self, self.onAvatarLayerTouchMovedAction_))
        self:getViewData().avatarTouchLayer:setOnTouchEndedScriptHandler(handler(self, self.onAvatarLayerTouchEndedAction_))
    end
end


function CatHouseAvatarMediator:CleanupView()
    if self.memberMoveClocker_ then
        self.memberMoveClocker_:stop()
    end

    if self:getViewNode() and not tolua.isnull(self:getViewNode()) then
        self:getViewNode():removeFromParent()
    end
end


function CatHouseAvatarMediator:OnRegist()
    regPost(POST.HOUSE_KICKOUT)
    regPost(POST.HOUSE_REPAIR_AVATAR)
    regPost(POST.HOUSE_CLEAN_TRIGGER)

    self:initSchedule_()
end


function CatHouseAvatarMediator:OnUnRegist()
    unregPost(POST.HOUSE_KICKOUT)
    unregPost(POST.HOUSE_REPAIR_AVATAR)
    unregPost(POST.HOUSE_CLEAN_TRIGGER)
end


function CatHouseAvatarMediator:InterestSignals()
    return {
        SGL.CAT_HOUSE_CHANGE_AVATAR_STATUE,
        SGL.CAT_HOUSE_CLICK_AVATAR_HANDLR,
        SGL.CAT_HOUSE_AVATAR_APPEND,
        SGL.CAT_HOUSE_AVATAR_REMOVE,
        SGL.CAT_HOUSE_AVATAR_MOVED,
        SGL.CAT_HOUSE_AVATAR_NOTICE,
        SGL.CAT_HOUSE_AVATAR_CLEAR,
        SGL.CAT_HOUSE_PREVIEW_SUIT,
        SGL.Chat_GetMessage_Callback,
        SGL.CAT_HOUSE_MEMBER_LIST, 
        SGL.CAT_HOUSE_MEMBER_VISIT,
        POST.HOUSE_KICKOUT.sglName,
        SGL.CAT_HOUSE_SELF_WALK_SEND,
        SGL.CAT_HOUSE_MEMBER_WALK, 
        SGL.CAT_HOUSE_MEMBER_HEAD, 
        SGL.CAT_HOUSE_MEMBER_BUBBLE, 
        SGL.CAT_HOUSE_MEMBER_IDENTITY,
        SGL.CAT_HOUSE_CLICK_MEMBER,
        SGL.CAT_HOUSE_CLICK_REPAIR_AVATAR,
        SGL.CAT_HOUSE_CLICK_TRIGGER_NODE,
        SGL.CAT_MODULE_CAT_INTERACTION,
        POST.HOUSE_REPAIR_AVATAR.sglName,
        POST.HOUSE_CLEAN_TRIGGER.sglName,
    }
end
function CatHouseAvatarMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()

    -------------------------------------------------
    -- avatar about

    -- 改变avatar
    if name == SGL.CAT_HOUSE_CHANGE_AVATAR_STATUE then
        self:onOperateAvatarCallback_(data)

    -- 操作avatar
    elseif name == SGL.CAT_HOUSE_CLICK_AVATAR_HANDLR then
        self:onHandlerAvatarCallback_(data)

    -- 添置avatar
    elseif name == SGL.CAT_HOUSE_AVATAR_APPEND then
        if checkint(data.errcode) == 0 then
            self.operateAvatarUuid_ = checkint(data.goodsUuid)
            self:doSelectedAvatarNodeCmd_(CatHouseUtils.HOUSE_CMD_TAG.DO_PREPARE, {goodsUuid = self.operateAvatarUuid_, goodsId = self.operateAvatarId_})
        else
            app.uiMgr:ShowInformationTips(data.errmsg or __("未知错误"))
        end

    -- 撤下avatar
    elseif name == SGL.CAT_HOUSE_AVATAR_REMOVE then
        self:doSelectedAvatarNodeCmd_(CatHouseUtils.HOUSE_CMD_TAG.DO_REMOVE, {goodsUuid = self.operateAvatarUuid_, goodsId = self.operateAvatarId_})

    -- 移动avatar
    elseif name == SGL.CAT_HOUSE_AVATAR_MOVED then
        self:doSelectedAvatarNodeCmd_(CatHouseUtils.HOUSE_CMD_TAG.DO_MOVED, {goodsUuid = self.operateAvatarUuid_, goodsId = self.operateAvatarId_})
        
    -- 清空avatar
    elseif name == SGL.CAT_HOUSE_AVATAR_CLEAR then
        local goodsIdList = {}
        for _, avatarData in pairs(data.cleanList) do
            app.catHouseMgr:getHomeData().location[tostring(avatarData.goodsUuid)] = nil
            table.insert(goodsIdList, avatarData.goodsId)
        end
        -- 更新家具数量
        app:DispatchObservers(SGL.CAT_HOUSE_UPDATE_AVATAR_USE_NUM, {goodsIdList = goodsIdList})
        -- 执行取消操作
        self:doSelectedAvatarNodeCmd_(CatHouseUtils.HOUSE_CMD_TAG.DO_CANCLE)
        -- 重载家具界面
        self:initHomeData(app.catHouseMgr:getHomeData().location)
        
    -- 变更avatar
    elseif name == SGL.CAT_HOUSE_AVATAR_NOTICE then
        local friendData = app.catHouseMgr:getVisitFriendHouseData()
        friendData.location = data.location
        self:initHomeData(friendData.location)
        
    -- 预览套装
    elseif name == SGL.CAT_HOUSE_PREVIEW_SUIT then
        local previewSuitId = app.catHouseMgr:getHousePresetSuitId()
        if previewSuitId > 0 then
            local suitData = clone(app.catHouseMgr:getHomeData().customSuits[tostring(previewSuitId)])
            self:initHomeData(suitData)
        else
            self:initHomeData(app.catHouseMgr:getHomeData().location)
        end

    -- 点击破损家具
    elseif name == SGL.CAT_HOUSE_CLICK_REPAIR_AVATAR then
        self:SendSignal(POST.HOUSE_REPAIR_AVATAR.cmdName, {goodsId = data.goodsId, goodsUuid = data.goodsUuid})

    -- 修理家具
    elseif name == POST.HOUSE_REPAIR_AVATAR.sglName then
        -- update goods
        local avatarId      = checkint(data.requestData.goodsId)
        local repairConsume = CatHouseUtils.GetAvatarRepairConsume(avatarId)
        app.goodsMgr:DrawRewards({
            {goodsId = repairConsume.goodsId, num = -repairConsume.num}
        })
        -- update data
        local avatarUuid = checkint(data.requestData.goodsUuid)
        self.homeAvatarMap_[tostring(avatarUuid)].damaged = 0
        -- update view
        local avatarNode = self:getViewNode():getAvatarNode(avatarUuid)
        avatarNode:setDamageStatue(false)

    -------------------------------------------------
    -- member about

    -- 聊天消息
    elseif name == SGL.Chat_GetMessage_Callback then
        if not self.isPreviewMode_ then
            self:getMessageCallback_(data)
        end

    -- 访客列表
    elseif name == SGL.CAT_HOUSE_MEMBER_LIST then
        if not self.isPreviewMode_ then
            for _, memberData in ipairs(data.members or {}) do
                self:appendMemberCell(CatHouseUtils.MEMBER_TYPE.ROLE, memberData)
            end
        end
        
    -- 访客来访
    elseif name == SGL.CAT_HOUSE_MEMBER_VISIT then
        if not self.isPreviewMode_ then
            self:appendMemberCell(CatHouseUtils.MEMBER_TYPE.ROLE, data)
        end
        
    -- 踢出小屋
    elseif name == POST.HOUSE_KICKOUT.sglName then
        local memberId = checkint(data.requestData.memberId)
        self:removeMemberCell(CatHouseUtils.MEMBER_TYPE.ROLE, memberId)

    -- 移动通知
    elseif name == SGL.CAT_HOUSE_SELF_WALK_SEND then
        if self.myselfEffectivePos_ then
            self:getViewNode():updateMemberCell(CatHouseUtils.MEMBER_TYPE.ROLE, {memberId = app.gameMgr:GetPlayerId(), effectivePos = self.myselfEffectivePos_})
        end
        
    -- 访客移动
    elseif name == SGL.CAT_HOUSE_MEMBER_WALK then
        if not self.isPreviewMode_ then
            local memberType = checkint(data.memberType)  
            if memberType == CatHouseUtils.MEMBER_TYPE.CAT then
                local memberNode = self:getViewNode():getMemberNode(CatHouseUtils.MEMBER_TYPE.CAT, data.memberId)
                if memberNode then
                    memberNode:setTargetPoint(self:getViewNode():createMemberRandomPoint())
                end
            else
                self:getViewNode():updateMemberCell(CatHouseUtils.MEMBER_TYPE.ROLE, {memberId = data.memberId, effectivePos = cc.p(data.pointX, data.pointY)})
            end
        end

    -- 访客改头像
    elseif name == SGL.CAT_HOUSE_MEMBER_HEAD then
        if not self.isPreviewMode_ then
            self:getViewNode():updateMemberCell(CatHouseUtils.MEMBER_TYPE.ROLE, {memberId = data.memberId, head = data.head})
        end
        
    -- 访客改气泡
    elseif name == SGL.CAT_HOUSE_MEMBER_BUBBLE then
        if not self.isPreviewMode_ then
            self:getViewNode():updateMemberCell(CatHouseUtils.MEMBER_TYPE.ROLE, {memberId = data.memberId, bubble = data.bubble})
        end
        
    -- 访客改身份
    elseif name == SGL.CAT_HOUSE_MEMBER_IDENTITY then
        if not self.isPreviewMode_ then
            self:getViewNode():updateMemberCell(CatHouseUtils.MEMBER_TYPE.ROLE, {memberId = data.memberId, businessCard = data.businessCard})
        end

    -- 点击成员
    elseif name == SGL.CAT_HOUSE_CLICK_MEMBER then
        self:onClickMemberCellCallback_(data.memberType, data.memberId)

    -------------------------------------------------
    -- cat about
        
    -- 猫咪交互
    elseif name == SGL.CAT_MODULE_CAT_INTERACTION then
        -- 驱逐
        if data.type == CatHouseUtils.CAT_FRIEND_INTERACT_ACTION.DRIVE then
            self:removeMemberCell(CatHouseUtils.MEMBER_TYPE.CAT, data.catUuid)
        
        -- 玩耍
        elseif data.type == CatHouseUtils.CAT_FRIEND_INTERACT_ACTION.PLYA then
            local memberNode = self:getViewNode():getMemberNode(CatHouseUtils.MEMBER_TYPE.CAT, data.catUuid)
            memberNode:setLeftPlayTimes(data.playTimes)

        -- 喂食
        elseif data.type == CatHouseUtils.CAT_FRIEND_INTERACT_ACTION.FEED then
            local memberNode = self:getViewNode():getMemberNode(CatHouseUtils.MEMBER_TYPE.CAT, data.catUuid)
            memberNode:setLeftFeedTimes(data.feedTimes)

        end

    -- 点击猫咪的排泄物
    elseif name == SGL.CAT_HOUSE_CLICK_TRIGGER_NODE then
        self:SendSignal(POST.HOUSE_CLEAN_TRIGGER.cmdName, {eventUuids = tostring(data.eventUuid)})

    -- 清理
    elseif name == POST.HOUSE_CLEAN_TRIGGER.sglName then
        local removeEventId   = checkint(data.requestData.eventUuids)
        local catTriggerEvent = app.catHouseMgr:getHomeData().catTriggerEvent or {}
        for eventIndex = #catTriggerEvent, 1, -1 do
            local eventData = app.catHouseMgr:getHomeData().catTriggerEvent[eventIndex]
            if eventData.eventUuid == removeEventId then
                table.remove(app.catHouseMgr:getHomeData().catTriggerEvent, eventIndex)
                break
            end
        end
        self:getViewNode():removeTriggerNode(data.requestData.eventUuids)

    end
end


-------------------------------------------------
-- get / set

---@return CatHouseAvatarView
function CatHouseAvatarMediator:getViewNode()
    return self:GetViewComponent()
end
function CatHouseAvatarMediator:getViewData()
    return self:getViewNode():getViewData()
end


-------------------------------------------------
-- public

function CatHouseAvatarMediator:close()
    app:UnRegsitMediator(self:GetMediatorName())
end


function CatHouseAvatarMediator:onCloseDecoratingModeCallback()
    self:doSelectedAvatarNodeCmd_(CatHouseUtils.HOUSE_CMD_TAG.DO_CANCLE)
end


function CatHouseAvatarMediator:onClosePresetModeCallBack()
    if app.catHouseMgr:getHousePresetSuitId() > 0 then
        app.catHouseMgr:setHousePresetSuitId(0)
    end
end


function CatHouseAvatarMediator:initHomeData(locationMap)
    self.homeAvatarMap_ = checktable(locationMap)
    self:checkPreloadRes_(self.homeAvatarMap_)
end


function CatHouseAvatarMediator:initAvatarMemberView(homeData)
    self:getViewNode():cleanAllMembers()
    
    if not self.isPreviewMode_ then
        if app.gameMgr:IsPlayerSelf(app.catHouseMgr:getHouseOwnerId()) then
            -- friend out cats
            for _, memberData in ipairs(homeData.friendCats) do
                memberData.memberId  = memberData.friendCatUuid 
                memberData.needArrow = true
                self:appendMemberCell(CatHouseUtils.MEMBER_TYPE.CAT, memberData)
            end
        else
            -- friend house cats
            for _, memberData in ipairs(homeData.cats) do
                memberData.memberId = memberData.playerCatId
                self:appendMemberCell(CatHouseUtils.MEMBER_TYPE.CAT, memberData)
            end
        end
    end
end


function CatHouseAvatarMediator:initTriggerEventView(triggerDatas)
    self:getViewNode():removeAllTriggerNode()

    if not self.isPreviewMode_ then
        for _, triggerData in ipairs(triggerDatas) do
            self:getViewNode():appendTriggerNode(triggerData)
        end
    end
end


-------------------------------------------------
-- private

function CatHouseAvatarMediator:initSchedule_()
    -- start memberMoveClocker
    if self.memberMoveClocker_ then
        self.memberMoveClocker_:start()
    end
end


function CatHouseAvatarMediator:checkPreloadRes_(locationMap)
    local resDatas = {}
    for _, avatarData in pairs(checktable(locationMap)) do
        local avatarId    = checkint(avatarData.goodsId)
        local animateConf = CONF.CAT_HOUSE.AVATAR_ANIMATE:GetValue(avatarId)

        if next(animateConf) == nil then
            local avatarPath = AssetsUtils.GetCatHouseBigAvatarPath(avatarId)
            if app.gameResMgr:isExistent(avatarPath) then
                table.insert(resDatas, avatarPath)
            end
        end
    end

    local finishCB = function()
        self:getViewNode():reloadAvatars(locationMap)
    end

    if DYNAMIC_LOAD_MODE then
        app.uiMgr:showDownloadResPopup({
            resDatas = resDatas,
            finishCB = finishCB,
        })
    else
        finishCB()
    end
end


-------------------------------------------------------------------------------
-- avatar method
-------------------------------------------------------------------------------

function CatHouseAvatarMediator:doSelectedAvatarNodeCmd_(cmdTag, data)
    local commonCancleSelectedFunc = function()
        -- 隐藏操作节点
        self:getViewNode():getHandlerNode():hideHandleView()
        -- 取消装饰条选中状态
        app:DispatchObservers(SGL.CAT_HOUSE_SET_SELECTED_AVATARID, {avatarId = 0})
        -- 置空选中节点
        self.operateAvatarId_    = nil
        self.operateAvatarUuid_  = nil
        self.selectedAvatarNode_ = nil
    end
    
    -------------------------------------------------
    -- 添加 临时家具
    if cmdTag == CatHouseUtils.HOUSE_CMD_TAG.DO_PREPARE then
        local avatarId   = checkint(data.goodsId)
        local avatarUuid = checkint(data.goodsUuid)
        local avatarType = CatHouseUtils.GetAvatarTypeByGoodsId(avatarId)
        if avatarType == CatHouseUtils.AVATAR_TYPE.WALL or avatarType == CatHouseUtils.AVATAR_TYPE.FLOOR or avatarType == CatHouseUtils.AVATAR_TYPE.CELLING then
            app.socketMgr:SendPacket(NetCmd.HOUSE_AVATAR_MOVED, {goodsUuid = avatarUuid, goodsId = avatarId, x = 0, y = 0})

        else
            local locationConf  = CONF.CAT_HOUSE.AVATAR_LOCATION:GetValue(avatarId)
            local collBoxWidth  = checkint(locationConf.collisionBoxWidth)
            local collBoxHeight = checkint(locationConf.collisionBoxLength)
            local tiledWidth    = math.ceil(collBoxWidth / CatHouseUtils.AVATAR_TILED_SIZE.width)
            local tiledHeight   = math.ceil(collBoxHeight / CatHouseUtils.AVATAR_TILED_SIZE.height)
            local freeTiledRect = self:getViewNode():findFreeTiledRect(cc.size(tiledWidth, tiledHeight))
            if freeTiledRect then
                -- 添加临时家具
                self:getViewNode():appendAvatarNode(avatarUuid, {goodsId = avatarId, tiledPos = cc.p(freeTiledRect.x, freeTiledRect.y), isTempMode = true})
                -- 记录选中家具
                self.selectedAvatarNode_ = self:getViewNode():getAvatarNode(avatarUuid)
                -- 显示家具操作节点
                self:getViewNode():getHandlerNode():setHandleType(CatHouseUtils.HANDLER_TYPE.AVATAR)
                self:getViewNode():getHandlerNode():showHandleView(self.selectedAvatarNode_)
            else
                app.uiMgr:ShowInformationTips(__('没有空闲的位置'))
                -- 取消装饰条选中状态
                app:DispatchObservers(SGL.CAT_HOUSE_SET_SELECTED_AVATARID, {avatarId = 0})
            end
        end

    -------------------------------------------------
    -- 确认 家具位置
    elseif cmdTag == CatHouseUtils.HOUSE_CMD_TAG.DO_CONFIRM then
        if self.selectedAvatarNode_ then
            if self.selectedAvatarNode_:isCollision() then
                app.uiMgr:ShowInformationTips(__('家具的摆放位置有误！'))                
            else
                local avatarId     = self.selectedAvatarNode_:getGoodsId()
                local avatarUuid   = self.selectedAvatarNode_:getGoodsUuid()
                local currentPosX  = self.selectedAvatarNode_:getPositionX() + self.selectedAvatarNode_:getOffsetPoint().x
                local currentPosY  = self.selectedAvatarNode_:getPositionY() + self.selectedAvatarNode_:getOffsetPoint().y
                local effectivePos = self:getViewData().avatarEffectiveLayer:convertToNodeSpace(cc.p(currentPosX, currentPosY))
                app.socketMgr:SendPacket(NetCmd.HOUSE_AVATAR_MOVED, {goodsUuid = avatarUuid, goodsId = avatarId, x = effectivePos.x, y = effectivePos.y})
            end
        end

    -------------------------------------------------
    -- 取消 选中状态
    elseif cmdTag == CatHouseUtils.HOUSE_CMD_TAG.DO_CANCLE then
        if self.selectedAvatarNode_ then
            if self.selectedAvatarNode_:isTempMode() then
                -- 删掉临时的家具
                self:doSelectedAvatarNodeCmd_(CatHouseUtils.HOUSE_CMD_TAG.DO_REMOVE)
            else
                if self.selectedAvatarNode_:getFlagTiledX() > 0 or self.selectedAvatarNode_:getFlagTiledY() > 0 then
                    -- 还原到标记位置
                    local flagTiledPos = cc.p(self.selectedAvatarNode_:getFlagTiledX(), self.selectedAvatarNode_:getFlagTiledY())
                    self:getViewNode():updateAvatarNode(self.selectedAvatarNode_:getGoodsUuid(), {tiledPos = flagTiledPos, isFillTiled = true, editingOrder = false})
                    -- 清空标记位置
                    self.selectedAvatarNode_:setFlagTiledX(0)
                    self.selectedAvatarNode_:setFlagTiledY(0)
                else
                    self:getViewNode():updateAvatarNode(self.selectedAvatarNode_:getGoodsUuid(), {editingOrder = false})
                end
                commonCancleSelectedFunc()
            end
        end

    -------------------------------------------------
    -- 移动 家具到目标位置
    elseif cmdTag == CatHouseUtils.HOUSE_CMD_TAG.DO_MOVED then
        local avatarId   = self.selectedAvatarNode_ and self.selectedAvatarNode_:getGoodsId() or checkint(data.goodsId)
        local avatarUuid = self.selectedAvatarNode_ and self.selectedAvatarNode_:getGoodsUuid() or checkint(data.goodsUuid)
        local avatarType = CatHouseUtils.GetAvatarTypeByGoodsId(avatarId)
        if avatarType == CatHouseUtils.AVATAR_TYPE.WALL or avatarType == CatHouseUtils.AVATAR_TYPE.FLOOR or avatarType == CatHouseUtils.AVATAR_TYPE.CELLING then
            -- 清空旧的类型部件
            local oldAvatarId = 0
            for _, locationData in pairs(self.homeAvatarMap_) do
                local newAvatarType = CatHouseUtils.GetAvatarTypeByGoodsId(locationData.goodsId)
                if newAvatarType == avatarType then
                    oldAvatarId = checkint(locationData.goodsId)
                    self.homeAvatarMap_[tostring(locationData.goodsUuid)] = nil
                    break
                end
            end
            -- 填充数据
            self.homeAvatarMap_[tostring(avatarUuid)] = {goodsUuid = avatarUuid, goodsId = avatarId, location = cc.p(0, 0)}
            -- 更新家具数量
            app:DispatchObservers(SGL.CAT_HOUSE_UPDATE_AVATAR_USE_NUM, {goodsIdList = {avatarId, oldAvatarId}})
            -- 添加家具
            self:getViewNode():appendAvatarNode(avatarUuid, {goodsId = avatarId})

        elseif self.selectedAvatarNode_ then
            local currentPos   = cc.p(self.selectedAvatarNode_:getPosition())
            local currentPosX  = self.selectedAvatarNode_:getPositionX() + self.selectedAvatarNode_:getOffsetPoint().x
            local currentPosY  = self.selectedAvatarNode_:getPositionY() + self.selectedAvatarNode_:getOffsetPoint().y
            local effectivePos = self:getViewData().avatarEffectiveLayer:convertToNodeSpace(cc.p(currentPosX, currentPosY))
            -- 填充数据到当前位置
            self:getViewNode():updateAvatarNode(avatarUuid, {isFillTiled = true, editingOrder = false})
            -- 清空标记位置
            self.selectedAvatarNode_:setFlagTiledX(0)
            self.selectedAvatarNode_:setFlagTiledY(0)
            if self.selectedAvatarNode_:isTempMode() then
                -- 取消临时标记
                self.selectedAvatarNode_:setTempMode(false)
                -- 更新坐标数据
                self.homeAvatarMap_[tostring(avatarUuid)] = {goodsUuid = avatarUuid, goodsId = avatarId, location = effectivePos}
                -- 更新家具数量
                app:DispatchObservers(SGL.CAT_HOUSE_UPDATE_AVATAR_USE_NUM, {goodsIdList = {avatarId}})
            else
                -- 更新坐标数据
                self.homeAvatarMap_[tostring(avatarUuid)].location = effectivePos
            end
            commonCancleSelectedFunc()
        end

    -------------------------------------------------
    -- 移除 指定的家具
    elseif cmdTag == CatHouseUtils.HOUSE_CMD_TAG.DO_REMOVE then
        local avatarId   = self.selectedAvatarNode_ and self.selectedAvatarNode_:getGoodsId() or checkint(data.goodsId)
        local avatarUuid = self.selectedAvatarNode_ and self.selectedAvatarNode_:getGoodsUuid() or checkint(data.goodsUuid)
        local avatarType = CatHouseUtils.GetAvatarTypeByGoodsId(avatarId)
        self.homeAvatarMap_[tostring(avatarUuid)] = nil

        if avatarType == CatHouseUtils.AVATAR_TYPE.CELLING then
            -- 清空吊顶层
            self:getViewData().avatarCeilingLayer:removeAllChildren()
            -- 更新家具数量
            app:DispatchObservers(SGL.CAT_HOUSE_UPDATE_AVATAR_USE_NUM, {goodsIdList = {avatarId}})

        elseif avatarType == CatHouseUtils.AVATAR_TYPE.WALL or avatarType == CatHouseUtils.AVATAR_TYPE.FLOOR then
            -- 无法清除
        else
            local isCanCleanAvatarNode = true
            if self.selectedAvatarNode_ and not self.selectedAvatarNode_:isTempMode() then
                if self.selectedAvatarNode_:isDamage() then
                    app.uiMgr:ShowInformationTips(__('家具已损坏, 不能卸下'))
                    isCanCleanAvatarNode = false
                else
                    -- 清空占位格子
                    self:getViewNode():updateAvatarNode(self.selectedAvatarNode_:getGoodsUuid(), {isCleanTiled = true})
                    -- 更新家具数量
                    app:DispatchObservers(SGL.CAT_HOUSE_UPDATE_AVATAR_USE_NUM, {goodsIdList = {self.selectedAvatarNode_:getGoodsId()}})
                end
            end

            if isCanCleanAvatarNode then
                commonCancleSelectedFunc()
                -- 清空家具节点
                self:getViewNode():removeAvatarNode(avatarUuid)
            end
        end
        
    end
end


-------------------------------------------------------------------------------
-- mebmer method
-------------------------------------------------------------------------------

function CatHouseAvatarMediator:removeMemberCell(memberType, memberId)
    memberType = memberType or CatHouseUtils.MEMBER_TYPE.ROLE
    self:getViewNode():removeMemberCell(memberType, memberId)
end


function CatHouseAvatarMediator:appendMemberCell(memberType, memberData)
    memberType = memberType or CatHouseUtils.MEMBER_TYPE.ROLE
    self:getViewNode():appendMemberCell(memberType, memberData)
end


function CatHouseAvatarMediator:hasMemberCell(memberType, memberId)
    memberType = memberType or CatHouseUtils.MEMBER_TYPE.ROLE
    return self:getViewNode():getMemberNode(memberType, memberId) ~= nil
end


function CatHouseAvatarMediator:getMessageCallback_(data)
    local messageData    = checktable(data)
    local messageText    = checkstr(messageData.message)
    local messageType    = checkint(messageData.messagetype)
    local messageChannel = checkint(messageData.channel)

    if messageChannel == CHAT_CHANNELS.CHANNEL_HOUSE and messageType == CHAT_MSG_TYPE.TEXT then
        local parsedList   = {}
        local parsedResult = labelparser.parse(messageText)
        for _, result in ipairs(parsedResult) do
            if FILTERS[result.labelname] then
                table.insert(parsedList, result)
            end
        end

        for _, v in ipairs(parsedList) do
            if v.labelname == FILTERS.desc then
                local memberId   = checkint(messageData.playerId)
                local message    = nativeSensitiveWords(v.content)
                local memberNode = self:getViewNode():getMemberNode(CatHouseUtils.MEMBER_TYPE.ROLE, memberId)
                if memberNode then
                    memberNode:createBubble(message)
                end
                break
            end
        end
    end
end


function CatHouseAvatarMediator:onClickMemberCellCallback_(memberType, memberId)
    if not self.isControllable_  then return end

    if memberType == CatHouseUtils.MEMBER_TYPE.ROLE then
        if memberId ~= app.gameMgr:GetPlayerId() then
            local displayType = HeadPopupType.CAT_HOUSE_MINE
            -- check in myHouse
            if not app.gameMgr:IsPlayerSelf(app.catHouseMgr:getHouseOwnerId()) then
                if CommonUtils.GetIsFriendById(app.catHouseMgr:getHouseOwnerId()) then
                    displayType = HeadPopupType.CAT_HOUSE_FRIEND_FRIEND
                else
                    displayType = HeadPopupType.CAT_HOUSE_FRIEND_STRANGER
                end
            end
            app.uiMgr:AddDialog('common.PlayerHeadPopup', {playerId = memberId, type = displayType})
        end

    elseif memberType == CatHouseUtils.MEMBER_TYPE.CAT then
        if app.catHouseMgr:getCatModel(memberId) then
            local catInfoMdt = require('Game.mediator.catModule.CatModuleCatInfoMediator').new({catUuid = memberId})
            app:RegistMediator(catInfoMdt)
        else
            local memberNode     = self:getViewNode():getMemberNode(CatHouseUtils.MEMBER_TYPE.CAT, memberId)
            local firendData     = CommonUtils.GetFriendData(memberNode:getFriendId())
            if not firendData then
                app.uiMgr:ShowInformationTips(__('小猫咪的主人已经不是您的好友了'))
            else
                local catInteractMdt = require('Game.mediator.catModule.CatModuleInteractMediator').new(memberNode:getMemberData())
                app:RegistMediator(catInteractMdt)
            end
        end
    end
end


-------------------------------------------------
-- handler

function CatHouseAvatarMediator:onMemberMoveUpdateHandler_()
    local hasUpdateAvatar = false
    for avatarType, avatarCells in pairs(self:getViewNode():getAllMemberMap()) do
        for _, avatarCell in pairs(avatarCells) do
            if avatarCell.getTargetPoint and avatarCell:getTargetPoint() then
                local avatarX = avatarCell:getPositionX()
                local avatarY = avatarCell:getPositionY()
                local targetX = checkint(avatarCell:getTargetPoint().x)
                local targetY = checkint(avatarCell:getTargetPoint().y)

                if avatarX > targetX then
                    avatarCell:setPositionX(math.max(avatarX - AVATAR_MOVE_SPEED, targetX))
                elseif avatarX < targetX then
                    avatarCell:setPositionX(math.min(avatarX + AVATAR_MOVE_SPEED, targetX))
                end

                if avatarY > targetY then
                    avatarCell:setPositionY(math.max(avatarY - AVATAR_MOVE_SPEED, targetY))
                elseif avatarY < targetY then
                    avatarCell:setPositionY(math.min(avatarY + AVATAR_MOVE_SPEED, targetY))
                end

                if avatarX == targetX and avatarY == targetY then
                    avatarCell:setTargetPoint(nil)
                end

                hasUpdateAvatar = true
            end
        end
    end
    if hasUpdateAvatar then
        self:getViewNode():reorderAllMembers()
    end
end


function CatHouseAvatarMediator:onAvatarLayerTouchBeginAction_(sender, touch)
    xTry(function()
        local touchPos    = touch:getLocation()
        self.isDragging_  = false
        self.draggingPos_ = nil
        -- 是否 装饰模式中
        if app.catHouseMgr:isDecoratingMode() then
            -- 是否 重复点击同一个node
            if not self.selectedAvatarNode_ or not self:getViewNode():isTouchAvatarNode(self.selectedAvatarNode_, touchPos) then
                -- 取消旧的选择
                self:doSelectedAvatarNodeCmd_(CatHouseUtils.HOUSE_CMD_TAG.DO_CANCLE)
                -- 记录新的选择
                self.selectedAvatarNode_ = self:getViewNode():getTouchAvatarNode(touchPos)
                -- 是否 选择了新的家具
                if self.selectedAvatarNode_ then
                    self:getViewNode():updateAvatarNode(self.selectedAvatarNode_:getGoodsUuid(), {editingOrder = true})
                    app:DispatchObservers(SGL.CAT_HOUSE_SET_SELECTED_AVATARID, {avatarId = self.selectedAvatarNode_:getGoodsId()})
                end
            end
            if self.selectedAvatarNode_ then
                local currentPosX = self.selectedAvatarNode_:getPositionX() + self.selectedAvatarNode_:getOffsetPoint().x
                local currentPosY = self.selectedAvatarNode_:getPositionY() + self.selectedAvatarNode_:getOffsetPoint().y
                self.draggingPos_ = cc.p(currentPosX - touchPos.x, currentPosY - touchPos.y)
            end
        end
    end, __G__TRACKBACK__)
    return 1
end


function CatHouseAvatarMediator:onAvatarLayerTouchMovedAction_(sender,touch)
    xTry(function()
        local touchPos = touch:getLocation()
        local deltaX   = touch:getStartLocation().x - touchPos.x
        local deltaY   = touch:getStartLocation().y - touchPos.y
        -- 是否 装饰模式中
        if app.catHouseMgr:isDecoratingMode() then
            if self.selectedAvatarNode_ ~= nil and not tolua.isnull(self.selectedAvatarNode_) then
                -- 检测拖动距离
                if not self.isDragging_ and (math.abs(deltaX) > 5 or math.abs(deltaY) > 5) then
                    self.isDragging_ = true
                    self:getViewNode():getHandlerNode():hideHandleView()
                    if self.selectedAvatarNode_:getFlagTiledX() == 0 and self.selectedAvatarNode_:getFlagTiledY() == 0 then 
                        self.selectedAvatarNode_:setFlagTiledX(self.selectedAvatarNode_:getTiledPosX())
                        self.selectedAvatarNode_:setFlagTiledY(self.selectedAvatarNode_:getTiledPosY())
                    end
                    self:getViewNode():updateAvatarNode(self.selectedAvatarNode_:getGoodsUuid(), {isCleanTiled = true})
                end

                if self.isDragging_ then
                    -- moved avatarNode
                    local newDraggingPos  = cc.p(self.draggingPos_.x + touchPos.x, self.draggingPos_.y + touchPos.y)
                    local newEffectivePos = self:getViewData().avatarEffectiveLayer:convertToNodeSpace(newDraggingPos)
                    self:getViewNode():updateAvatarNode(self.selectedAvatarNode_:getGoodsUuid(), {effectivePos = newEffectivePos})
                end
            end
        end
    end, __G__TRACKBACK__)
    return true
end


function CatHouseAvatarMediator:onAvatarLayerTouchEndedAction_(sender, touch)
    xTry(function()
        local touchPos = touch:getLocation()
        -- 是否 装饰模式中
        if app.catHouseMgr:isDecoratingMode() then
            if self.selectedAvatarNode_ then
                -- 显示 家具类型 的 控制面板
                self:getViewNode():getHandlerNode():setHandleType(CatHouseUtils.HANDLER_TYPE.AVATAR)
                self:getViewNode():getHandlerNode():showHandleView(self.selectedAvatarNode_)
            end
        else
            -- 是否 处于有效房间内
            if app.catHouseMgr:getPlayerHouseHeadId() >= 0 then
                local touchEffectivePos  = self:getViewData().avatarEffectiveLayer:convertToNodeSpace(touchPos)
                local myselfMemberNode   = self:getViewNode():getMemberNode(CatHouseUtils.MEMBER_TYPE.ROLE, app.gameMgr:GetPlayerId())
                self.myselfEffectivePos_ = self:getViewNode():fixedMemberEffectivePos(myselfMemberNode, touchEffectivePos)
                app.socketMgr:SendPacket(NetCmd.HOUSE_SELF_WALK_SEND, {pointX = self.myselfEffectivePos_.x, pointY = self.myselfEffectivePos_.y})
            end
        end
    end, __G__TRACKBACK__)
    return true
end


function CatHouseAvatarMediator:onOperateAvatarCallback_(data)
    -- 摆放家具
    if data.cmdTag == CatHouseUtils.HOUSE_CMD_TAG.TO_APPEND then
        self.operateAvatarId_   = checkint(data.goodsId)
        self.operateAvatarUuid_ = nil
        app.socketMgr:SendPacket(NetCmd.HOUSE_AVATAR_APPEND, {goodsId = self.operateAvatarId_})

    -- 撤下家具
    elseif data.cmdTag == CatHouseUtils.HOUSE_CMD_TAG.TO_REMOVE then
        self.operateAvatarId_   = checkint(data.goodsId)
        self.operateAvatarUuid_ = data.goodsUuid or nil  -- 吊顶等特殊家具可能不用uuid
        app.socketMgr:SendPacket(NetCmd.HOUSE_AVATAR_REMOVE, {goodsId = self.operateAvatarId_, goodsUuid = self.operateAvatarUuid_})

    -- 取消家具
    elseif data.cmdTag == CatHouseUtils.HOUSE_CMD_TAG.TO_CANCLE then
        self.operateAvatarId_   = nil
        self.operateAvatarUuid_ = nil
        self:doSelectedAvatarNodeCmd_(CatHouseUtils.HOUSE_CMD_TAG.DO_CANCLE)
    end
end


function CatHouseAvatarMediator:onHandlerAvatarCallback_(data)
    -- 撤下家具
    if data.cmdTag == CatHouseUtils.HOUSE_CMD_TAG.BY_REMOVE then
        if self.selectedAvatarNode_ then
            if self.selectedAvatarNode_:isTempMode() then
                self:doSelectedAvatarNodeCmd_(CatHouseUtils.HOUSE_CMD_TAG.DO_REMOVE)
            else
                local avatarId   = self.selectedAvatarNode_:getGoodsId()
                local avatarUuid = self.selectedAvatarNode_:getGoodsUuid()
                app.socketMgr:SendPacket(NetCmd.HOUSE_AVATAR_REMOVE, {goodsUuid = avatarUuid, goodsId = avatarId})
            end
        end

    -- 摆放家具
    elseif data.cmdTag == CatHouseUtils.HOUSE_CMD_TAG.BY_CONFIRM then
        if self.selectedAvatarNode_ then
        if self.selectedAvatarNode_:isTempMode() then
            self:doSelectedAvatarNodeCmd_(CatHouseUtils.HOUSE_CMD_TAG.DO_CONFIRM)
        else
            if self.selectedAvatarNode_:getFlagTiledX() > 0 or self.selectedAvatarNode_:getFlagTiledY() > 0 then
                self:doSelectedAvatarNodeCmd_(CatHouseUtils.HOUSE_CMD_TAG.DO_CONFIRM)
            else
                self:doSelectedAvatarNodeCmd_(CatHouseUtils.HOUSE_CMD_TAG.DO_CANCLE)
            end
        end
        end
    end
end


return CatHouseAvatarMediator
