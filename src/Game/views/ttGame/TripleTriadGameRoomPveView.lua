--[[
 * author : kaishiqi
 * descpt : 打牌游戏 - PVE房间视图
]]
local TTGameBaseRoomView = require('Game.views.ttGame.TripleTriadGameRoomBaseView')
local TTGamePveRoomView  = class('TripleTriadGameRoomPveView', TTGameBaseRoomView)

local RES_DICT = {
}


function TTGamePveRoomView:ctor(args)
    self:setName('TripleTriadGameRoomPveView')
    self.super.ctor(self, args)
end


function TTGamePveRoomView:initBgLayer(ownerLayer)
    local ownerSize = ownerLayer:getContentSize()

    local npcBgLayer = display.newLayer(ownerSize.width/2, ownerSize.height/2)
    ownerLayer:addChild(npcBgLayer)

    ownerLayer:addChild(display.newLayer(0, 0, {color = cc.c4b(0,0,0,150), enable = true}))

    local npcImageLayer = display.newLayer(ownerSize.width/2 - 680, 0)
    ownerLayer:addChild(npcImageLayer)

    return {
        npcBgLayer    = npcBgLayer,
        npcImageLayer = npcImageLayer,
    }
end


function TTGamePveRoomView:updateNpcImage(npcSkinId)
    self:getViewData().npcImageLayer:removeAllChildren()
    local npcDrawNode = require('common.CardSkinDrawNode').new({skinId = npcSkinId, coordinateType = COORDINATE_TYPE_CAPSULE})
    self:getViewData().npcImageLayer:addChild(npcDrawNode)
end


function TTGamePveRoomView:updateBgImage(imageName)
    local bgImagePath = _res(string.fmt('arts/stage/bg/%1.jpg', imageName))
    self:getViewData().npcBgLayer:removeAllChildren()
    self:getViewData().npcBgLayer:addChild(display.newImageView(bgImagePath, 0, 0, {ap = display.CENTER}))
end


function TTGamePveRoomView:updateRewardLeftTimes(number)
    self.super.updateRewardLeftTimes(self, number, __('活动期间内剩余奖励次数：'))
end


return TTGamePveRoomView
