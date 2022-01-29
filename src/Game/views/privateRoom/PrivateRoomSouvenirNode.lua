--[[
包厢纪念品node
--]]
local PrivateRoomSouvenirNode = class('PrivateRoomSouvenirNode', function ()
	local PrivateRoomSouvenirNode = CLayout:create()
    PrivateRoomSouvenirNode.name = 'home.privateRoom.PrivateRoomSouvenirNode'
	PrivateRoomSouvenirNode:enableNodeEvents()
	return PrivateRoomSouvenirNode
end)
local RES_DICT = {
    SHADOW = _res('ui/privateRoom/vip_wall_frame_shadow.png'),
    FRAME  = _res('ui/privateRoom/vip_wall_frame_0.png'),
    FRAME_SELECT = _res('ui/privateRoom/vip_wall_frame_selected.png')
}
function PrivateRoomSouvenirNode:ctor( ... )
    local arg = unpack({ ... })
    self.size = arg.size -- 尺寸
    self.scale = arg.scale -- 缩放比
    self.id = checkint(arg.id)
    self.callback = nil 
    self:InitUI()

end
function PrivateRoomSouvenirNode:InitUI()
    local size = self.size
    local scale = self.scale
    self:setContentSize(size)
    local function CreateView()
        local view = CLayout:create(size)
        local shadow = display.newImageView(RES_DICT.SHADOW, size.width / 2, size.height / 2, {scale9 = true, size = cc.size(size.width + 14, size.height + 14)})
        view:addChild(shadow, 1)
        local frame = display.newButton(size.width / 2, size.height / 2, {n = RES_DICT.FRAME, scale9 = true, size = size})
        view:addChild(frame, 3)
        local selectedFrame = display.newImageView(RES_DICT.FRAME_SELECT, size.width / 2 - 6, size.height / 2 + 10, {scale9 = true, size = cc.size(size.width + 42, size.height + 42)})
        view:addChild(selectedFrame, 5)
        selectedFrame:setVisible(false)
        local goodsIcon = display.newImageView('', size.width / 2, size.height / 2)
        goodsIcon:setScale(scale)
        view:addChild(goodsIcon, 3)
        return {
            view = view,
            shadow = shadow,
            frame = frame,
            selectedFrame = selectedFrame, 
            goodsIcon = goodsIcon,
        }
    end
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view, 1)
        self.viewData.view:setPosition(utils.getLocalCenter(self))
        self.viewData.frame:setTag(self.id)
        self.viewData.frame:setOnClickScriptHandler(handler(self, self.FrameBtnCallback))
    end, __G__TRACKBACK__)    
end
--[[
设置纪念品
@params goodsId int 物品id(为空则隐藏)
--]]
function PrivateRoomSouvenirNode:SetGoods( goodsId )
    if not goodsId or goodsId == 0 then
        self.viewData.goodsIcon:setVisible(false)
        -- self.viewData.frame:setEnabled(false)
    else
        self.viewData.goodsIcon:setVisible(true)
        self.viewData.frame:setEnabled(true)
        self.viewData.goodsIcon:setTexture(CommonUtils.GetGoodsIconPathById(goodsId))
    end
end
--[[
点击回调
--]]
function PrivateRoomSouvenirNode:FrameBtnCallback( sender )
    if self.callback then
        self.callback(sender)
    end
end
--[[
设施回调
--]]
function PrivateRoomSouvenirNode:SetOnClick( callback )
    self.callback = callback
end
--[[
设置选中状态
--]]
function PrivateRoomSouvenirNode:SetSelected( isSelected )
    self.viewData.selectedFrame:setVisible(isSelected)
    if isSelected then
        self.viewData.frame:setContentSize(cc.size(self.size.width + 6, self.size.height + 6))
        self.viewData.frame:setPosition(cc.p(self.size.width / 2 - 6, self.size.height / 2 + 10))
        self.viewData.shadow:setPosition(cc.p(self.size.width / 2 + 6, self.size.height / 2 - 10))
        self.viewData.goodsIcon:setPosition(cc.p(self.size.width / 2 - 6, self.size.height / 2 + 10))
    else
        self.viewData.frame:setContentSize(cc.size(self.size.width, self.size.height))
        self.viewData.frame:setPosition(cc.p(self.size.width / 2, self.size.height / 2))
        self.viewData.shadow:setPosition(cc.p(self.size.width / 2, self.size.height / 2))
        self.viewData.goodsIcon:setPosition(cc.p(self.size.width / 2, self.size.height / 2))
    end
end
return PrivateRoomSouvenirNode