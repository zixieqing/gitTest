--[[
 * author : kaishiqi
 * descpt : 打牌游戏 - 好友房间视图
]]
local CommonChatPanel      = require('common.CommonChatPanel')
local TTGameBaseRoomView   = require('Game.views.ttGame.TripleTriadGameRoomBaseView')
local TTGameFriendRoomView = class('TripleTriadGameRoomFriendView', TTGameBaseRoomView)

local RES_DICT = {
    ROOM_READYED_ICON = _res('ui/common/raid_room_ico_ready.png'),
    ROOM_FRAME_CENTER = _res('ui/ttgame/room/cardgame_prepare_bg_room.png'),
    ROOM_FRAME_TITLE  = _res('ui/ttgame/room/cardgame_prepare_label_room.png'),
    ROOM_INFO_FRAME   = _res('ui/common/commcon_bg_text.png'),
    ROOM_START_ICON   = _res('ui/ttgame/room/cardgame_prepare_ico_friend_ready.png'),
    ROOM_READYED_BAR  = _res('ui/ttgame/room/cardgame_prepare_label_friend_ready.png'),
    RIGHT_MASK_FRAME  = _res('ui/ttgame/room/cardgame_prepare_bg_deck_cover.png'),
    CANCEL_BTN_N      = _res('ui/ttgame/room/cardgame_prepare_btn_cancel.png'),
    CANCEL_NAME_BAR   = _res('ui/ttgame/room/cardgame_prepare_label_fight.png'),
    READYED_SPINE     = _spn('ui/ttgame/room/cardgame_prepare'),
    MOOD_TALK_BTN     = _res('ui/common/raid_btn_talk.png'),
}

local CreateMatchView = nil


function TTGameFriendRoomView:ctor(args)
    self:setName('TripleTriadGameRoomFriendView')
    self.super.ctor(self, args)
end


function TTGameFriendRoomView:initRightLayer(ownerLayer)
    local rightViewData = self.super.initRightLayer(self, ownerLayer, __('准备'))
    local ownerSize     = ownerLayer:getContentSize()

    local rightMaskLayer = display.newLayer(0, rightViewData.rightCenterPos.y, {ap = display.LEFT_CENTER})
    rightMaskLayer:addChild(display.newImageView(RES_DICT.RIGHT_MASK_FRAME, 0, ownerSize.height/2, {ap = display.LEFT_CENTER}))
    rightMaskLayer:addChild(display.newLayer(0, 0, {size = ownerSize, color = cc.r4b(0), enable = true}))
    ownerLayer:addChild(rightMaskLayer)

    local playGameBtnPos  = cc.p(rightViewData.playGameBtn:getPosition())
    local rightReadySpine = TTGameUtils.CreateSpine(RES_DICT.READYED_SPINE)
    rightReadySpine:setPosition(playGameBtnPos)
    rightReadySpine:setAnimation(0, 'play', true)
    rightMaskLayer:addChild(rightReadySpine)

    local canclelReadyBtn = display.newButton(playGameBtnPos.x, playGameBtnPos.y, {n = RES_DICT.CANCEL_BTN_N})
    rightMaskLayer:addChild(canclelReadyBtn)
    
    local playGameNameBarPos = cc.p(rightViewData.playGameNameBar:getPosition())
    local cancelReadyNameBar = display.newButton(playGameNameBarPos.x, playGameNameBarPos.y, {n = RES_DICT.CANCEL_NAME_BAR, enable = false})
    display.commonLabelParams(cancelReadyNameBar, fontWithColor(20, {fontSize = 36, text = gameBtnName or __('取消')}))
    rightMaskLayer:addChild(cancelReadyNameBar)
    
    local rightReadyIcon = display.newImageView(RES_DICT.ROOM_READYED_ICON, playGameBtnPos.x, playGameBtnPos.y, {scale = 1.5})
    rightMaskLayer:addChild(rightReadyIcon)


    local moodTalkBtn = display.newButton(playGameBtnPos.x - 182, playGameBtnPos.y - 105, {n = RES_DICT.MOOD_TALK_BTN})
    ownerLayer:addChild(moodTalkBtn)
    
    table.merge(rightViewData, {
        rightMaskLayer  = rightMaskLayer,
        canclelReadyBtn = canclelReadyBtn,
        moodTalkBtn     = moodTalkBtn,
    })
    return rightViewData
end


function TTGameFriendRoomView:initRewardsLayer(ownerLayer)
    return {}
end


function TTGameFriendRoomView:initCenterLayer(ownerLayer)
    local ownerSize     = ownerLayer:getContentSize()
    local roomInfoSize  = cc.size(630, 530)
    local roomInfoLayer = display.newLayer(ownerSize.width/2 - 250, ownerSize.height/2, {size = roomInfoSize, ap = display.CENTER})
    roomInfoLayer:addChild(display.newImageView(RES_DICT.ROOM_FRAME_CENTER, roomInfoSize.width/2, 0, {ap = display.CENTER_BOTTOM}))
    roomInfoLayer:addChild(display.newImageView(RES_DICT.ROOM_FRAME_TITLE, roomInfoSize.width/2, roomInfoSize.height, {ap = display.CENTER_TOP}))
    ownerLayer:addChild(roomInfoLayer)
    
    ------------------------------------------------- [title]
    local roomNumberIntro = display.newLabel(roomInfoSize.width/2, roomInfoSize.height - 20, fontWithColor(5, {color = '#CC583b', text = __('牌室号')}))
    local roomNumberLabel = display.newLabel(roomInfoSize.width/2, roomInfoSize.height - 62, fontWithColor(3, {fontSize = 40, text = '----'}))
    roomInfoLayer:addChild(roomNumberIntro)
    roomInfoLayer:addChild(roomNumberLabel)


    ------------------------------------------------- [waiting]
    local centerInfoSize   = cc.size(roomInfoSize.width, roomInfoSize.height - 90)
    local waitingInfoLayer = display.newLayer(roomInfoSize.width/2, 0, {size = centerInfoSize, ap = display.CENTER_BOTTOM})
    roomInfoLayer:addChild(waitingInfoLayer)

    local waitingTipsString = __('小提醒：牌室是私密的，请把牌室号告诉想要邀请的朋友吧。')
    local waitingTipsIntro  = display.newLabel(centerInfoSize.width/2, centerInfoSize.height - 70, fontWithColor(3, {color = '#a1a1a1', text = waitingTipsString, w = centerInfoSize.width - 180}))
    waitingInfoLayer:addChild(waitingTipsIntro)

    local waitingInfoIntro = display.newLabel(centerInfoSize.width/2, centerInfoSize.height/2 - 10, fontWithColor(3, {fontSize = 30, color = '#8b8163', text = __('等待玩家加入……')}))
    waitingInfoLayer:addChild(waitingInfoIntro)


    ------------------------------------------------- [roomer]
    local roomerInfoLayer = display.newLayer(roomInfoSize.width/2, 0, {size = centerInfoSize, ap = display.CENTER_BOTTOM})
    roomInfoLayer:addChild(roomerInfoLayer)

    local roomerFrameSize  = cc.size(480, 200)
    local roomerFrameImage = display.newImageView(RES_DICT.ROOM_INFO_FRAME, centerInfoSize.width/2, centerInfoSize.height/2 + 5, {size = roomerFrameSize, scale9 = true, ap = display.CENTER_BOTTOM})
    roomerInfoLayer:addChild(roomerFrameImage)

    local roomerHeadNode = require('common.PlayerHeadNode').new()
    roomerHeadNode:setPositionY(roomerFrameImage:getPositionY() + roomerFrameSize.height/2 + 18)
    roomerHeadNode:setPositionX(roomerFrameImage:getPositionX())
    roomerHeadNode:setScale(0.85)
    roomerInfoLayer:addChild(roomerHeadNode)
    
    local roomerNameLabel = display.newLabel(roomerFrameImage:getPositionX(), roomerFrameImage:getPositionY() + 25, fontWithColor(3, {color = '#7c7c7c', text = '----'}))
    roomerInfoLayer:addChild(roomerNameLabel)


    roomerInfoLayer:addChild(display.newImageView(RES_DICT.ROOM_START_ICON, centerInfoSize.width/2, centerInfoSize.height/4 + 20))


    ------------------------------------------------- [ready]
    local roomerReadyLayer = display.newLayer(roomInfoSize.width/2, 0, {size = centerInfoSize, ap = display.CENTER_BOTTOM})
    roomInfoLayer:addChild(roomerReadyLayer)

    roomerReadyLayer:addChild(display.newLabel(centerInfoSize.width/2, 50, fontWithColor(5, {color = '#8b8163', text = __('等待对手确认牌组……')})))


    ------------------------------------------------- [ready]
    local roomerConfirmLayer = display.newLayer(roomInfoSize.width/2, 0, {size = centerInfoSize, ap = display.CENTER_BOTTOM})
    roomInfoLayer:addChild(roomerConfirmLayer)

    local roomerReadyBtnPos = cc.p(centerInfoSize.width/2, centerInfoSize.height/4 + 20)
    local roomerReadySpine  = TTGameUtils.CreateSpine(RES_DICT.READYED_SPINE)
    roomerReadySpine:setPosition(roomerReadyBtnPos)
    roomerReadySpine:setAnimation(0, 'play', true)
    roomerConfirmLayer:addChild(roomerReadySpine)

    roomerConfirmLayer:addChild(display.newImageView(RES_DICT.ROOM_READYED_ICON, roomerReadyBtnPos.x, roomerReadyBtnPos.y))
    roomerConfirmLayer:addChild(display.newImageView(RES_DICT.ROOM_READYED_BAR, roomerReadyBtnPos.x, roomerReadyBtnPos.y - 70))
    roomerConfirmLayer:addChild(display.newLabel(roomerReadyBtnPos.x, roomerReadyBtnPos.y - 70, fontWithColor(7, {fontSize = 30, text = __('准备好了！')})))


    -- chat panel
    local chatPanel = nil
    if ChatUtils.IsModuleAvailable() then
        chatPanel = CommonChatPanel.new({channelId = CHAT_CHANNELS.CHANNEL_WORLD})
        ownerLayer:addChild(chatPanel)
    end

    return {
        chatPanel          = chatPanel,
        roomNumberLabel    = roomNumberLabel,
        roomerHeadNode     = roomerHeadNode,
        roomerNameLabel    = roomerNameLabel,
        waitingInfoLayer   = waitingInfoLayer,
        roomerInfoLayer    = roomerInfoLayer,
        roomerReadyLayer   = roomerReadyLayer,
        roomerConfirmLayer = roomerConfirmLayer,
    }
end


-------------------------------------------------

function TTGameFriendRoomView:updateRewardGoodsList(goodsList)
end


function TTGameFriendRoomView:updateRewardLeftTimes(number)
end


function TTGameFriendRoomView:updateRewardBuyStatus(isEnable)
end


function TTGameFriendRoomView:updateRoomNumber(roomNumber)
    display.commonLabelParams(self:getViewData().roomNumberLabel, {text = tostring(roomNumber)})
end


function TTGameFriendRoomView:updateRoomerName(roomerName)
    display.commonLabelParams(self:getViewData().roomerNameLabel, {text = tostring(roomerName)})
end


function TTGameFriendRoomView:updateRoomerFrame(roomerAvatar, roomerFrame, roomerLevel)
    self:getViewData().roomerHeadNode:RefreshUI({
        avatar      = roomerAvatar,
        avatarFrame = roomerFrame,
        playerLevel = roomerLevel,
    })
end


function TTGameFriendRoomView:showWaitingRoomerLayer()
    self:getViewData().waitingInfoLayer:setVisible(true)
    self:getViewData().roomerInfoLayer:setVisible(false)
    self:getViewData().roomerReadyLayer:setVisible(false)
    self:getViewData().roomerConfirmLayer:setVisible(false)
end
function TTGameFriendRoomView:showRoomerReadyLayer()
    self:getViewData().waitingInfoLayer:setVisible(false)
    self:getViewData().roomerInfoLayer:setVisible(true)
    self:getViewData().roomerReadyLayer:setVisible(true)
    self:getViewData().roomerConfirmLayer:setVisible(false)
end
function TTGameFriendRoomView:showRoomerConfirmLayer()
    self:getViewData().waitingInfoLayer:setVisible(false)
    self:getViewData().roomerInfoLayer:setVisible(true)
    self:getViewData().roomerReadyLayer:setVisible(false)
    self:getViewData().roomerConfirmLayer:setVisible(true)
end


function TTGameFriendRoomView:showReadyedMaskLayer()
    self:getViewData().rightMaskLayer:setVisible(true)
end
function TTGameFriendRoomView:hideReadyedMaskLayer()
    self:getViewData().rightMaskLayer:setVisible(false)
end


return TTGameFriendRoomView
