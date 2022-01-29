--[[
包厢功能 贵宾信息主页面 view
--]]
local VIEW_SIZE = display.size
local PrivateRoomGuestInfoHomeView = class('PrivateRoomGuestInfoHomeView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.privateRoom.PrivateRoomGuestInfoHomeView'
	node:enableNodeEvents()
	return node
end)


local CreateView = nil

local RES_DIR = {
    BTN_BACK        = _res('ui/common/common_btn_back.png'),
    TITLE_BAR       = _res('ui/common/common_title_new.png'),
    BTN_TIPS        = _res('ui/common/common_btn_tips.png'),
}

local BUTTON_TAG = {
    BACK     = 100, -- 返回
    RULE     = 101, --规则
}

function PrivateRoomGuestInfoHomeView:ctor( ... ) 
    
    self.args = unpack({...})
    self:initialUI()
end

function PrivateRoomGuestInfoHomeView:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView()
        self:addChild(self.viewData_.view)
	end, __G__TRACKBACK__)
end

function PrivateRoomGuestInfoHomeView:refreshUI()
    local viewData = self:getViewData()
end

function PrivateRoomGuestInfoHomeView:updateBg(path)
    local viewData = self:getViewData()
    local bg = viewData.bg
    bg:setTexture(path)
end

function PrivateRoomGuestInfoHomeView:updateTitle(title)
    local viewData = self:getViewData()
    local actionBtns = viewData.actionBtns
    local titleBtn = actionBtns[tostring(BUTTON_TAG.RULE)]
    display.commonLabelParams(titleBtn, {text = title})
end

CreateView = function ()
    local view = display.newLayer()
    local size = view:getContentSize()

    view:addChild(display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 0), enable = true}))

    -- local 
    local bg = display.newImageView('', size.width / 2, size.height / 2, {ap = display.CENTER})
    view:addChild(bg)
    
    local actionBtns = {}
    
    local backBtn = display.newButton(0, 0, {n = RES_DIR.BTN_BACK})
    display.commonUIParams(backBtn, {po = cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, size.height - 18 - backBtn:getContentSize().height * 0.5)})
    actionBtns[tostring(BUTTON_TAG.BACK)] = backBtn
    view:addChild(backBtn, 5)
    
    local titleBtn = display.newButton(display.SAFE_L + 130, display.height, {n = RES_DIR.TITLE_BAR, ap = display.LEFT_TOP, animate = false, enable = false, scale9 = true, capInsets = cc.rect(100, 70, 80, 1)})
    display.commonLabelParams(titleBtn, fontWithColor(1, {text = __('贵宾信息'), offset = cc.p(0, -10), ttf = false}))
    actionBtns[tostring(BUTTON_TAG.RULE)] = titleBtn
    view:addChild(titleBtn)
    
    local contentLayer = display.newLayer()
    view:addChild(contentLayer)
    

    return {
        view               = view,
        bg                 = bg,
        actionBtns         = actionBtns,

        contentLayer       = contentLayer,
    }
end

function PrivateRoomGuestInfoHomeView:getViewData()
	return self.viewData_
end

return PrivateRoomGuestInfoHomeView