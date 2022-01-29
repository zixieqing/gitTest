--[[
 * author : kaishiqi
 * descpt : local game server
]]
local BaseServer = require('interfaces.server.BaseServer')
local GameServer = class('GameServer', BaseServer)


function GameServer:ctor()
    self.super.ctor(self, 'GameServer', Platform.TCPPort)
end


function GameServer:onReceiveData_(clientKey, cmdId, data)
    self.super.onReceiveData_(self, clientKey, cmdId, data)

    -- 1001 请求一次playerinfo的数据（常用于同步金币钻石）
    if cmdId == NetCmd.RequestPlayerInfoID then
        local data = {
            gold    = virtualData.playerData.gold,
            diamond = virtualData.playerData.diamond,
        }
        self:sendClientAt(clientKey, cmdId, data)


    --------------------------------------------------------------------------------------------------
    -- 餐厅功能
    --------------------------------------------------------------------------------------------------

    -- 6001 客人到达
    elseif cmdId == NetCmd.CustomerArrival then
        local sendData = {data = virtualData.restaurant.appendCustomer()}
        self:sendClientAt(clientKey, cmdId, sendData)

    -- 6002 客人离开
    elseif cmdId == NetCmd.CustomerLeave then
        virtualData.restaurant.removeCustomer(data.seatId)
        self:sendClientAt(clientKey, cmdId)

    -- 6007 招待客人
    elseif cmdId == NetCmd.RequestEmployUnlock then
        -- TODO

    -- 6004 家具添加
    elseif cmdId == NetCmd.RestuarantPutNewGoods then
        local sendData = {data = virtualData.restaurant.appendAvatar(data.goodsId)}
        self:sendClientAt(clientKey, cmdId, sendData)

    -- 6005 家具删除
    elseif cmdId == NetCmd.RestuarantRemoveGoods then
        virtualData.restaurant.removeAvatar(data.goodsId, data.goodsUuid)
        self:sendClientAt(clientKey, cmdId)

    -- 6006 家具移动
    elseif cmdId == NetCmd.RestuarantMoveGoods then
        virtualData.restaurant.movedAvatar(data.goodsId, data.goodsUuid, data.x, data.y)
        self:sendClientAt(clientKey, cmdId)

    -- 6008 同步桌子信息
    elseif cmdId == NetCmd.Request_6008 then
        local sendData = {data = virtualData.restaurant.getSeatInfo(data.seats)}
        self:sendClientAt(clientKey, cmdId, sendData)

    -- 6009 雇员更换
    elseif cmdId == NetCmd.RequestEmploySwich then
        local sendData = {data = virtualData.restaurant.switchEmployee(data.employeeId, data.playerCardId)}
        self:sendClientAt(clientKey, cmdId, sendData)

    -- 6010 雇员解锁
    elseif cmdId == NetCmd.RequestEmployUnlock then
        virtualData.restaurant.unlockEmployee(data.employeeId)
        self:sendClientAt(clientKey, cmdId)

    -- 6012 清空布局
    elseif cmdId == NetCmd.RestuarantCleanAll then
        local sendData = {data = virtualData.restaurant.cleanAllAvatar()}
        self:sendClientAt(clientKey, cmdId, sendData)


    --------------------------------------------------------------------------------------------------
    -- 工会功能
    --------------------------------------------------------------------------------------------------

    -- 7009 工会角色移动发送
    elseif cmdId == NetCmd.UNION_AVATAR_MOVE_SEND then
        self:sendClientAt(clientKey, cmdId)
        virtualData.union.lobbyAvatarMove(data.pointX, data.pointY)


    --------------------------------------------------------------------------------------------------
    -- 猫屋功能
    --------------------------------------------------------------------------------------------------

    -- 11001 家具添加
    elseif cmdId == NetCmd.HOUSE_AVATAR_APPEND then
        local sendData = {data = virtualData.catHouse.appendAvatar(data.goodsId)}
        self:sendClientAt(clientKey, cmdId, sendData)

    -- 11002 家具撤下
    elseif cmdId == NetCmd.HOUSE_AVATAR_REMOVE then
        virtualData.catHouse.removeAvatar(data.goodsId, data.goodsUuid)
        self:sendClientAt(clientKey, cmdId)

    -- 11003 家具移动
    elseif cmdId == NetCmd.HOUSE_AVATAR_MOVED then
        virtualData.catHouse.movedAvatar(data.goodsId, data.goodsUuid, data.x, data.y)
        self:sendClientAt(clientKey, cmdId)

    -- 11004 清空布局
    elseif cmdId == NetCmd.HOUSE_AVATAR_CLEAR then
        local sendData = {data = virtualData.catHouse.cleanAllAvatar()}
        self:sendClientAt(clientKey, cmdId, sendData)

    -- TODO
    -- NetCmd.HOUSE_AVATAR_NOTICE   = 11007, -- 猫屋 变更avatar
    -- NetCmd.HOUSE_MEMBER_LIST     = 11005, -- 猫屋 访客列表
    -- NetCmd.HOUSE_MEMBER_VISIT    = 11006, -- 猫屋 访客来访
    -- NetCmd.HOUSE_MEMBER_LEAVE    = 11008, -- 猫屋 访客离开
    -- NetCmd.HOUSE_MEMBER_HEAD     = 11011, -- 猫屋 访客改头像
    -- NetCmd.HOUSE_MEMBER_BUBBLE   = 11012, -- 猫屋 访客改气泡
    -- NetCmd.HOUSE_MEMBER_WALK     = 11010, -- 猫屋 访客移动
    -- NetCmd.HOUSE_MEMBER_IDENTITY = 11013, -- 猫屋 访客改身份
    -- NetCmd.HOUSE_INVITE_NOTICE   = 11014, -- 猫屋 邀请通知
    -- NetCmd.HOUSE_WALK_NOTICE     = 11009, -- 猫屋 移动通知

    end
end


return GameServer
