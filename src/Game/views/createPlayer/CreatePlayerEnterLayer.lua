--[[
登录弹窗
--]]
local CreatePlayerEnterLayer = class('CreatePlayerEnterLayer', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.createPlayer.CreatePlayerEnterLayer'
	node:enableNodeEvents()
	return node
end)

local RES_DICT = {
    CREATE_ROLES_BG1 = _res('ui/author/createPlayer/create_roles_bg1.png'),
    CREATE_ROLES_BG_UP = _res('ui/author/createPlayer/create_roles_bg_up.png'),

    CREATE_ROLES_BOOK  = _spn('ui/author/createPlayer/spine/create_roles_book')
}

function CreatePlayerEnterLayer:ctor( ... )
    self.args = unpack({...})
    self.pageTurning = false

    local blockLayer = display.newLayer(0, 0, {color = cc.r4b(0), enable = true})
    self:addChild(blockLayer)

	local function CreateView()
        local view  = display.newLayer()
        local size = view:getContentSize()

        local minddlePosX, minddlePosY = size.width * 0.5, size.height * 0.5

        local mainBg = display.newImageView(RES_DICT.CREATE_ROLES_BG1, minddlePosX, minddlePosY, {isFull = true})
        view:addChild(mainBg)

        local bookSpine = sp.SkeletonAnimation:create(RES_DICT.CREATE_ROLES_BOOK.json, RES_DICT.CREATE_ROLES_BOOK.atlas, 1)
        bookSpine:update(0)
        bookSpine:addAnimation(0, 'idle', true)
        bookSpine:setPosition(cc.p(minddlePosX, minddlePosY))
        view:addChild(bookSpine)

        local bgUp = display.newImageView(RES_DICT.CREATE_ROLES_BG_UP, minddlePosX, minddlePosY, {isFull = true})
        view:addChild(bgUp, 1)

        local nodeSize = cc.size(minddlePosX, size.height)
        local fixedNode = display.newLayer(size.width * 0.75, minddlePosY, {size = nodeSize, ap = display.CENTER})
        view:addChild(fixedNode)

		return {
            view      = view,
            bookSpine = bookSpine,
            fixedNode = fixedNode,
            backBtn   = backBtn,
		}
	end

	xTry(function ( )
        self.viewData = CreateView()
        self:addChild(self.viewData.view)

        self:InitView()

	end, __G__TRACKBACK__)
end

--==============================--
--desc: 初始化视图
--@return
--==============================--
function CreatePlayerEnterLayer:InitView()
    local viewData = self:GetViewData()

    local bookSpine = viewData.bookSpine
    bookSpine:registerSpineEventHandler(handler(self, self.OnBookSpineEndAction), sp.EventType.ANIMATION_END)

    self:InitTouchAction()

    app:RegistObserver("CREATE_PLAYER_SUCCESS", mvc.Observer.new(handler(self, self.CreateRoleSuccessCallback), self))
end

function CreatePlayerEnterLayer:InitTouchAction()
    self.touchListener_ = cc.EventListenerTouchOneByOne:create()
    self.touchListener_:setSwallowTouches(true)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchBegan_), cc.Handler.EVENT_TOUCH_BEGAN)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchMoved_), cc.Handler.EVENT_TOUCH_MOVED)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchEnded_), cc.Handler.EVENT_TOUCH_ENDED)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(self.touchListener_, self)
end

function CreatePlayerEnterLayer:onTouchBegan_(touch, event)
    if self.pageTurning then return false end

    local touchPoint = touch:getLocation()
    if self.beganTouchId_ and self.beganTouchId_ ~= touch:getId() then
        self.touchPoint_ = nil
    else
        self.beganTouchId_ = touch:getId() 
    end
    local isTouch = self:CheckTouch(self:GetViewData().fixedNode, touchPoint)
    if self.beganTouchId_ and isTouch then
        self.touchPoint_ = cc.p(checkint(touchPoint.x), checkint(touchPoint.y))
    end
    return true
end
function CreatePlayerEnterLayer:onTouchMoved_(touch, event)
end
function CreatePlayerEnterLayer:onTouchEnded_(touch, event)
    local touchPoint = touch:getLocation()
    -- local isTouch = self:CheckTouch(self:GetViewData().fixedNode, touchPoint)
    if self.touchPoint_ then
        local startTouchPosX = self.touchPoint_.x
        local endTouchPosX   = touchPoint.x

        -- 必须从左往右滑
        if (endTouchPosX - startTouchPosX) < -10 then
            self.pageTurning = true
            -- logInfo.add(5, 'onTouchEnded_')
            self:ShowCreatePlayerView()
        end
        
    end
    self.touchPoint_ = nil
end
function CreatePlayerEnterLayer:CheckTouch(node, touchPos)
    local size = node:getContentSize()
    local rect  = cc.rect(0, 0, size.width,size.height)
    local tPos = cc.p(node:convertToNodeSpace(touchPos))
    return cc.rectContainsPoint(rect, tPos)
end

function CreatePlayerEnterLayer:ShowCreatePlayerView()
    local viewData = self:GetViewData()
    local bookSpine = viewData.bookSpine
    bookSpine:setAnimation(0, 'play_1', false)
    bookSpine:addAnimation(0, 'play_2', false)
end

function CreatePlayerEnterLayer:OnBookSpineEndAction(event)
    local animation = event.animation

    if animation == 'play_2' then
        local viewData = self:GetViewData()
        local view = viewData.view
        local colorView = require('Game.views.createPlayer.CreatePlayerLayer').new() 
        display.commonUIParams(colorView, {po = display.center})
        view:addChild(colorView)

        colorView:ShowAcion()
    end
end

function CreatePlayerEnterLayer:CreateRoleSuccessCallback()
    self:setVisible(false)
end

function CreatePlayerEnterLayer:onCleanup()
	app:UnRegistObserver("CREATE_PLAYER_SUCCESS", self)
end

function CreatePlayerEnterLayer:GetViewData()
	return self.viewData
end

return CreatePlayerEnterLayer
