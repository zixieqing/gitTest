--[[
包厢纪念品描述node
--]]
local PrivateRoomSouvenirDescrNode = class('PrivateRoomSouvenirDescrNode', function ()
	local PrivateRoomSouvenirDescrNode = CLayout:create()
    PrivateRoomSouvenirDescrNode.name = 'privateRoom.PrivateRoomSouvenirDescrNode'
    node:enableNodeEvents()
    return PrivateRoomSouvenirDescrNode
    
end)
local RES_DICT = {
    COMMON_BG     = _res('ui/privateRoom/vip_details_goods_bg.png'),
    BUFF_DESCR_BG = _res('avatar/ui/avatarShop/avator_goods_bg_attibute.png'),
    LINE          = _res('ui/privateRoom/vip_line_1.png')
}
function PrivateRoomSouvenirDescrNode:ctor( ... )
    local arg = unpack({ ... })
    self.size = arg.size
    self.goodsId = arg.goodsId 
    self:InitUI()
    self:RefreshNode(self.goodsId)
end
function PrivateRoomSouvenirDescrNode:InitUI()
    local size = self.size
    self:setContentSize(size)
    local function CreateView()
        local view = CLayout:create(size)
        local bg = display.newImageView(RES_DICT.COMMON_BG, size.width / 2, size.height / 2 + 40, {scale9 = true, size = cc.size(size.width, size.height - 80)})
        view:addChild(bg, 1)
        -- 列表
        local listViewSize = cc.size(size.width - 10, size.height - 150)
        local listView = CListView:create(listViewSize)
        listView:setPosition(cc.p(size.width / 2, 122 + 30))
        listView:setAnchorPoint(cc.p(0.5, 0))
        view:addChild(listView, 5)
        -- buff描述
        local buffDescrBg = display.newButton(size.width / 2, 84, {ap = cc.p(0.5, 0), n = RES_DICT.BUFF_DESCR_BG, enable = false, scale9 = true, size = cc.size(size.width - 10, 60)})
        view:addChild(buffDescrBg, 5)
        -- 获取条件
        local gainLabel = display.newLabel(10, 60, fontWithColor(5, {ap = cc.p(0, 0.5), text = __('获取条件')}))
        view:addChild(gainLabel, 5)
        local ownedLabel = display.newLabel(size.width - 10, 60, {text = '', fontSize = 20, color = '#287d2d', ap = cc.p(1, 0.5)})
        view:addChild(ownedLabel, 5)
        -- line 
        local line = display.newImageView(RES_DICT.LINE, listViewSize.width / 2, 42)
        view:addChild(line, 5)
        local requirementLabel = display.newLabel(10, 36, fontWithColor(15, {text = '', ap = cc.p(0, 1), w = listViewSize.width - 10, w = 380}))
        view:addChild(requirementLabel, 5)
        
        return {
            view             = view,
            listView         = listView,
            buffDescrBg      = buffDescrBg,
            listViewSize     = listViewSize,
            ownedLabel       = ownedLabel,
            requirementLabel = requirementLabel
        }
    end
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view, 1)
        self.viewData.view:setPosition(utils.getLocalCenter(self))
    end, __G__TRACKBACK__)    
end
--[[
刷新node
@prarams goodsId int 纪念品goodsId
--]]
function PrivateRoomSouvenirDescrNode:RefreshNode( goodsId )
    if not goodsId then return end
    local viewData = self.viewData
    local listView = viewData.listView
    local listViewSize = viewData.listViewSize
    local giftConf = CommonUtils.GetConfig('privateRoom', 'guestGift', goodsId)
    local guestConf = CommonUtils.GetConfig('privateRoom', 'guest', giftConf.guestId)
    -- 添加cell
    listView:removeAllNodes()
    local cell = CLayout:create()
    local common_H = 5
    local guestData = app.privateRoomMgr:GetGuestDataByGuestId(giftConf.guestId)
    -- local unlockDialogueNum = table.nums(checktable(guestData.dialogues)) -- 已解锁对话数量
    -- local allDialogueNum = table.nums(checktable(guestConf.story)) -- 
    -- local progressLabel = display.newLabel(5, common_H, fontWithColor(8, {text = string.format('%d/%d', unlockDialogueNum, allDialogueNum), ap = cc.p(0, 0)}))
    -- local ownedLabel = display.newLabel(listViewSize.width - 5, common_H, {text = '', fontSize = 20, color = '#287d2d', ap = cc.p(1, 0)})

    -- local requirementLabel = display.newLabel(listViewSize.width / 2, ownedLabel:getPositionY() + display.getLabelContentSize(ownedLabel).height + common_H, fontWithColor(15, {text = giftConf.conditionDescr, ap = cc.p(0.5, 0), w = listViewSize.width - 10}))
    -- local line = display.newImageView(RES_DICT.LINE, listViewSize.width / 2, requirementLabel:getPositionY() + display.getLabelContentSize(requirementLabel).height + common_H)
    local descrLabel = display.newLabel(listViewSize.width / 2, 10, fontWithColor(6, {ap = cc.p(0.5, 0), text = giftConf.descr, w = listViewSize.width - 10}))
    local cell_H = common_H * 2 + 10 + display.getLabelContentSize(descrLabel).height
    local cellSize = cc.size(listViewSize.width, cell_H)
    cell:setContentSize(cellSize)
    -- cell:addChild(progressLabel, 1)
    -- cell:addChild(ownedLabel, 1)
    -- cell:addChild(requirementLabel, 1)
    -- cell:addChild(line, 1)
    cell:addChild(descrLabel, 1)
    listView:insertNodeAtLast(cell)
    listView:reloadData()
    -- buff描述
    display.commonLabelParams(viewData.buffDescrBg, fontWithColor(5, { w = 400 , hAlign = display.TAC,  text = app.privateRoomMgr:GetBuffDescrByGoodsId(goodsId).buffDescr}))
    --viewData.buffDescrBg:setVisible(false)
    -- 获取状态
    local str = __('未获得')
    local color = '#d23d3d'
    if app.privateRoomMgr:IsHasSouvenirByGoodsId(goodsId) then
        str = __('已获得')
        color = '#287d2d'
    end
    display.commonLabelParams(viewData.ownedLabel, {text = str, color = color})
    display.commonLabelParams(viewData.requirementLabel, fontWithColor(5, {text = giftConf.conditionDescr}))


    
end
return PrivateRoomSouvenirDescrNode