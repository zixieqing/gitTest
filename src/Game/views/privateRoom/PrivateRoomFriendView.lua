--[[
包厢好友view
--]]
local PrivateRoomFriendView = class('PrivateRoomFriendView', function ()
    local node = CLayout:create(display.size)
    node.name = 'home.PrivateRoomFriendView'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    SWITCH_DOOR       = _res('avatar/ui/restaurant_anime_door.png'),
    FRIEND_NAME_BAR   = _res('avatar/ui/restaurant_friends_bg_avator_name.png'),
    FRIEND_HEAD_BG    = _res('ui/common/common_avatar_frame_bg.png'),
    COMMON_BTN_BACK   = _res("ui/common/common_btn_back"),
}
local CreateDoorView = nil
function PrivateRoomFriendView:ctor( ... )
    self.args = unpack({...})
    self:InitUI()
end
--[[
init ui
--]]
function PrivateRoomFriendView:InitUI()
    local function CreateView()
        local bgSize = display.size
        local view = CLayout:create(bgSize)
        -- themeNode
		local themeNode = require('Game.views.privateRoom.PrivateRoomThemeNode').new()
		themeNode:setPosition(bgSize.width / 2, bgSize.height / 2)
        view:addChild(themeNode, 1)
        -------------------------------------------------
        -- friend info bar

        local friendInfoLayer = display.newLayer(display.SAFE_L, 0)
        view:addChild(friendInfoLayer, 10)

        local friendRNameBar = display.newButton(0, 10, {n = _res(RES_DICT.FRIEND_NAME_BAR), ap = display.CENTER_BOTTOM, scale9 = true, enable = false})
        display.commonLabelParams(friendRNameBar, fontWithColor(16))
        friendInfoLayer:addChild(friendRNameBar)
        
        local friendHeaderNode = require('root.CCHeaderNode').new({bg = _res(RES_DICT.FRIEND_HEAD_BG), pre = '', tsize = cc.size(90,90)})
        friendHeaderNode:setPosition(50, 50)
        friendInfoLayer:addChild(friendHeaderNode)
        -- friendInfoLayer:addChild(display.newImageView(_res(RES_DICT.FRIEND_HEAD_FRAME), 50, 50))

        local friendLevelLable = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '---')
        friendLevelLable:setAnchorPoint(display.RIGHT_BOTTOM)
        friendLevelLable:setPosition(92, 3)
        friendInfoLayer:addChild(friendLevelLable)
        -------------------------------------------------
        -- back button
		local backBtn = display.newButton(0, 0, {n = RES_DICT.COMMON_BTN_BACK })
		backBtn:setPosition(cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.height - 53))
		self:addChild(backBtn, 5)
        return {
            view             = view,
            themeNode        = themeNode,
            friendHeaderNode = friendHeaderNode,
            friendRNameBar   = friendRNameBar,
            friendLevelLable = friendLevelLable,
            friendInfoLayer  = friendInfoLayer,
            backBtn          = backBtn,
        }
    end
    -- eaterLayer
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(display.center)
        self.viewData.themeNode.viewData.wallBg:setOnClickScriptHandler(function()  
            PlayAudioByClickNormal()
            AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'privateRoom.PrivateRoomHomeMediator'}, {name = 'privateRoom.PrivateRoomWallShowMediator', params = {wallData = self.wall}}) 
        end)
    end, __G__TRACKBACK__)
end
--[[
刷新view
--]]
function PrivateRoomFriendView:RefreshView( data )
    self.themeId = data.themeId or app.privateRoomMgr:GetDefaultThemeId()
    self.wall = data.wall or {}
    self.waiterId = data.assistantCardSkinId -- 皮肤id
    self:RefreshTheme(self.themeId)
    self:RefreshWall(self.wall)
    self:RefreshWaiter(self.waiterId)
    if data then
        self.viewData.friendHeaderNode.headerSprite:setWebURL(data.avatar)
        self.viewData.friendHeaderNode:SetPreImageTexture(CommonUtils.GetGoodsIconPathById(CommonUtils.GetAvatarFrame(data.avatarFrame)))
        local nameText = string.fmt(__('_name_的_level_级包厢'), {_name_ = data.name, _level_ = data.restaurantLevel})
        display.commonLabelParams(self.viewData.friendRNameBar, {text = nameText, paddingW = 30, safeW = 160})
        self.viewData.friendRNameBar:setPositionX(self.viewData.friendRNameBar:getContentSize().width/2 + 80)
        display.commonLabelParams(self.viewData.friendLevelLable, {text = tostring(data.level)})
    else
        self.viewData.friendHeaderNode.headerSprite:setWebURL('')
        self.viewData.friendHeaderNode:SetPreImageTexture(CommonUtils.GetGoodsIconPathById(CommonUtils.GetAvatarFrame('')))
        display.commonLabelParams(self.viewData.friendRNameBar, {text = '', paddingW = 30, safeW = 160})
        display.commonLabelParams(self.viewData.friendLevelLable, {text = ''})
    end
end
--[[
刷新陈列墙
@params wallData map 纪念品数据
--]]
function PrivateRoomFriendView:RefreshWall( wallData )
	self.viewData.themeNode:RefreshWall(wallData)
end
--[[ 
刷新主题信息
@params themeId int 主题id
--]]
function PrivateRoomFriendView:RefreshTheme( themeId )
    self.avatar = self.viewData.themeNode:SetTheme(themeId).avatars
end

--[[
刷新服务员状态
@params cardSkinId int 卡牌皮肤id
--]]
function PrivateRoomFriendView:RefreshWaiter( cardSkinId )
    if checkint(cardSkinId) == 0 then return end
	local servePos = app.privateRoomMgr:GetWaiterServePos(self.avatar[1], self.viewData.themeNode.viewData.avatarLayout, self.themeId)
	local qAvatar = require('Game.views.privateRoom.PrivateRoomWaiterNode').new({cardSkinId = cardSkinId,  servePos = servePos})
	self.viewData.themeNode.viewData.avatarLayout:addChild(qAvatar, 15)
end
CreateDoorView = function()
    local view  = display.newLayer(0, 0, {color = cc.c4b(0,0,0,0), enable = true})
    local doorL = display.newImageView(_res(RES_DICT.SWITCH_DOOR), display.cx, display.cy, {ap = display.RIGHT_CENTER})
    local doorR = display.newImageView(_res(RES_DICT.SWITCH_DOOR), display.cx, display.cy, {ap = display.LEFT_CENTER})
    view:addChild(doorL)
    view:addChild(doorR)
    return {
        view  = view,
        doorL = doorL,
        doorR = doorR,
    }
end
function PrivateRoomFriendView:CreateDoorView()
    return CreateDoorView()
end
return PrivateRoomFriendView