--[[
 * author : kaishiqi
 * descpt : 打牌游戏 - PVP房间视图
]]
local TTGameBaseRoomView = require('Game.views.ttGame.TripleTriadGameRoomBaseView')
local TTGamePvpRoomView  = class('TripleTriadGameRoomPvpView', TTGameBaseRoomView)

local RES_DICT = {
    MATCHED_ICON   = _res('ui/common/raid_room_ico_ready.png'),
    PVP_ROLE_IMG   = _res('ui/ttgame/room/cardgame_prepare_img_pvp_role.png'),
    CANCEL_BTN     = _res('ui/ttgame/room/cardgame_prepare_btn_cancel.png'),
    SEARCH_FRAME   = _res('ui/ttgame/room/cardgame_prepare_bg_searching.png'),
    MATCHING_SPINE = _spn('ui/ttgame/room/cardgame_searching'),
}

local CreateMatchView = nil


function TTGamePvpRoomView:ctor(args)
    self:setName('TripleTriadGameRoomPvpView')
    self.super.ctor(self, args)
end


function TTGamePvpRoomView:initBgLayer(ownerLayer)
    local ownerSize = ownerLayer:getContentSize()

    local npcImageLayer = display.newLayer(ownerSize.width/2 - 250, ownerSize.height/2 - 115)
    ownerLayer:addChild(npcImageLayer)

    npcImageLayer:addChild(display.newImageView(RES_DICT.PVP_ROLE_IMG))

    return {
        npcImageLayer = npcImageLayer,
    }
end


function TTGamePvpRoomView:initRightLayer(ownerLayer)
    return self.super.initRightLayer(self, ownerLayer, __('匹配'))
end


function TTGamePvpRoomView:updateRewardLeftTimes(number)
    self.super.updateRewardLeftTimes(self, number, __('今日剩余奖励次数：'))
end


-------------------------------------------------
-- match view

CreateMatchView = function()
    local view = display.newLayer()
    local size = display.size

    -- block layer
    view:addChild(display.newLayer(0, 0, {color = cc.c4b(0,0,0,150), enable = true}))

    local MATCH_INFO_Y    = size.height/2 -85 -128
    local MATCH_INFO_SIZE = cc.size(size.width, 200)
    view:addChild(display.newImageView(RES_DICT.SEARCH_FRAME, size.width/2, MATCH_INFO_Y))


    -------------------------------------------------
    -- matching layer
    local matchingLayer = display.newLayer()
    view:addChild(matchingLayer)

    local cancelMatchBtnX = display.SAFE_R - ((540 + display.SAFE_L) - display.SAFE_L)/2 + 14
    local cancelMatchBtn  = display.newButton(cancelMatchBtnX, MATCH_INFO_Y, {n = RES_DICT.CANCEL_BTN})
    display.commonLabelParams(cancelMatchBtn, fontWithColor(20, {fontSize = 36, text = __('取消')}))
    matchingLayer:addChild(cancelMatchBtn)
    
    local matchingSpine = TTGameUtils.CreateSpine(RES_DICT.MATCHING_SPINE)
    matchingSpine:setPosition(cc.p(size.width/2, MATCH_INFO_Y + 35))
    matchingSpine:setAnimation(0, 'play', true)
    matchingLayer:addChild(matchingSpine)

    local matchingLabel = display.newLabel(size.width/2, MATCH_INFO_Y - 50, fontWithColor(7, {fontSize = 28, text = __('正在铺桌布。。。')}))
    matchingLayer:addChild(matchingLabel)


    -------------------------------------------------
    -- matched layer
    local matchedLayer = display.newLayer()
    view:addChild(matchedLayer)

    local matchedIcon = display.newImageView(RES_DICT.MATCHED_ICON, matchingLabel:getPositionX(), matchingLabel:getPositionY() + 80)
    matchedLayer:addChild(matchedIcon)

    local matchedLabel = display.newLabel(matchingLabel:getPositionX(), matchingLabel:getPositionY(), fontWithColor(7, {fontSize = 28, text = __('铺好了！')}))
    matchedLayer:addChild(matchedLabel)


    return {
        view           = view,
        matchedLayer   = matchedLayer,
        matchingLayer  = matchingLayer,
        cancelMatchBtn = cancelMatchBtn,
    }
end


function TTGamePvpRoomView.CreateMatchView()
    return CreateMatchView()
end


return TTGamePvpRoomView
