--[[
包厢纪念品页面纪念品cell
--]]
local PrivateRoomSouvenirCell = class('PrivateRoomSouvenirCell', function ()
    local PrivateRoomSouvenirCell = CGridViewCell:new()
	PrivateRoomSouvenirCell.name = 'home.PrivateRoomSouvenirCell'
    PrivateRoomSouvenirCell:enableNodeEvents()
	return PrivateRoomSouvenirCell
end)
local RES_DICT = {
    GOODS_BG            = _res('ui/privateRoom/vip_wall_bg_goods_default.png'),
    GOODS_BG_DISABLE    = _res('ui/privateRoom/vip_wall_bg_goods_disable.png'),
    GOODS_BG_SELECTED   = _res('ui/privateRoom/vip_wall_bg_goods_selected.png'),
    GOODS_FRAME         = _res('ui/mail/common_bg_list_selected.png'),
    TICK                = _res('ui/common/raid_room_ico_ready.png'),
}
function PrivateRoomSouvenirCell:ctor( ... )
	local arg = { ... }
    local size = arg[1]
	self:setContentSize(size)
	local eventNode = CLayout:create(size)
	eventNode:setPosition(utils.getLocalCenter(self))
	self:addChild(eventNode)
    self.eventNode = eventNode
    self.goodsBg = display.newButton(size.width / 2, size.height / 2, {n = RES_DICT.GOODS_BG})
    self.eventNode:addChild(self.goodsBg, 1)
    
    self.goodsIcon = FilteredSpriteWithOne:create(_res(CommonUtils.GetGoodsIconPathById(340001)))
    self.goodsIcon:setScale(0.55)
    self.goodsIcon:setPosition(size.width / 2, size.height / 2)
    self.eventNode:addChild(self.goodsIcon, 2)
    self.tick = display.newImageView(RES_DICT.TICK, size.width / 2, size.height / 2)
    self.tick:setVisible(false)
    self.eventNode:addChild(self.tick, 3)
    self.frame = display.newImageView(RES_DICT.GOODS_FRAME, size.width / 2, size.height / 2, {scale9 = true, size = size})
    self.frame:setVisible(false)
    self.eventNode:addChild(self.frame, 5)
end
--[[
刷新cell
@params data table {
    isSelected  bool 是否选中
    goodsId int 纪念品id
    isShow bool 是否展示(显示对勾)
    tag int 按钮tag
}
--]]
function PrivateRoomSouvenirCell:RefreshCell( data )
    local goodsId = data.goodsId or 340001
    local isSelected = data.isSelected
    local isShow = data.isShow
    local tag = checkint(data.tag)
    self.goodsIcon:setTexture(CommonUtils.GetGoodsIconPathById(goodsId))
    self.goodsBg:setTag(tag)
    -- 判断是否获取
    if app.privateRoomMgr:IsHasSouvenirByGoodsId(goodsId) then
        self.goodsIcon:clearFilter()
        if isShow then
            self.goodsBg:setNormalImage(RES_DICT.GOODS_BG_SELECTED)
            self.goodsBg:setSelectedImage(RES_DICT.GOODS_BG_SELECTED)
            self.tick:setVisible(true)
        else
            self.goodsBg:setNormalImage(RES_DICT.GOODS_BG)
            self.goodsBg:setSelectedImage(RES_DICT.GOODS_BG)
            self.tick:setVisible(false)
        end
        -- 是否被选中
        self.frame:setVisible(isSelected)
    else
        self.goodsIcon:setFilter(GrayFilter:create())
        self.goodsBg:setNormalImage(RES_DICT.GOODS_BG_DISABLE)
        self.goodsBg:setSelectedImage(RES_DICT.GOODS_BG_DISABLE)
        self.tick:setVisible(false)
        self.frame:setVisible(false)
    end
end
return PrivateRoomSouvenirCell