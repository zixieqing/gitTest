--[[
包厢纪念品view
--]]
local PrivateRoomSouvenirView = class('PrivateRoomSouvenirView', function ()
    local node = CLayout:create(display.size)
    node.name = 'home.PrivateRoomSouvenirView'
    node:enableNodeEvents()
    return node
end)
local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local RES_DICT = {
    BG           = _res('ui/common/common_bg_14.png'),
    GOODS_BG     = _res('ui/privateRoom/vip_wall_bg_goods_default.png'), 
    GRIDVIEW_BG  = _res('ui/common/common_bg_goods.png'), 
    BUFF_BTN     = _res('ui/home/kitchen/cooking_btn_pokedex_2.png'),
    COMMON_BTN   = _res('ui/common/common_btn_orange.png'),
    BTN_BACK     = _res('ui/common/common_btn_back.png'),
}
function PrivateRoomSouvenirView:ctor( ... )
    self.args = unpack({...}) or {}
    self:InitUI()
    self:RefreshView(self.args.goodsId or 340001)
end
--[[
init ui
--]]
function PrivateRoomSouvenirView:InitUI()
    local function CreateView()
        local bgSize = display.size
        local view = CLayout:create(bgSize)
        local wallView = require('Game.views.privateRoom.PrivateRoomWallView').new()
		wallView:setPosition(cc.p(display.cx - 180, display.cy))
        view:addChild(wallView, 5) 
        -- detailLayout
        local detailLayoutSize = cc.size(490, 720)
        local detailLayout = CLayout:create(detailLayoutSize)
        detailLayout:setPosition(cc.p(display.cx + 405, display.cy + 15))
        view:addChild(detailLayout)
        -- mask
        local mask = CColorView:create(cc.c4b(0, 0, 0, 0))
        mask:setTouchEnabled(true)
        mask:setContentSize(detailLayoutSize)
        mask:setPosition(cc.p(detailLayoutSize.width / 2, detailLayoutSize.height / 2))
        detailLayout:addChild(mask, -1)
        -- bg
        local bg = display.newImageView(RES_DICT.BG, detailLayoutSize.width / 2, detailLayoutSize.height / 2 - 20, {scale9 = true, size = detailLayoutSize})
        detailLayout:addChild(bg, 1)
        -- name
        local nameLabel = display.newLabel(50, detailLayoutSize.height - 90, {text = '', fontSize = 28, color = '#845229', ap = cc.p(0, 0.5)})
        detailLayout:addChild(nameLabel, 5)
        -- goods 
        local goodsBg = display.newImageView(RES_DICT.GOODS_BG, detailLayoutSize.width - 80, detailLayoutSize.height - 90)
        goodsBg:setScale(0.6)
        detailLayout:addChild(goodsBg, 3)
        local goodsIcon = display.newImageView('empty', goodsBg:getContentSize().width / 2, goodsBg:getContentSize().height / 2)
        goodsIcon:setScale(0.55)
        goodsBg:addChild(goodsIcon)
        -- descrNode
        local descrNode = require('Game.views.privateRoom.PrivateRoomSouvenirDescrNode').new({goodsId = 340001, size = cc.size(400, 258)})
        descrNode:setAnchorPoint(cc.p(0.5, 1))
        descrNode:setPosition(cc.p(detailLayoutSize.width / 2, detailLayoutSize.height - 130))
        detailLayout:addChild(descrNode, 5)
        -- gridView
        local gridViewSize = cc.size(400, 224)
        local gridViewCellSize = cc.size(98, 100)
        local gridViewBg = display.newImageView(RES_DICT.GRIDVIEW_BG, detailLayoutSize.width / 2, 90, {scale9 = true, size = gridViewSize, ap = cc.p(0.5, 0)})
        detailLayout:addChild(gridViewBg, 3)
		local gridView = CGridView:create(cc.size(gridViewSize.width - 8, gridViewSize.height - 4))
		gridView:setSizeOfCell(gridViewCellSize)
		gridView:setColumns(4)
		-- gridView:setAutoRelocate(true)
		detailLayout:addChild(gridView, 5)
		gridView:setAnchorPoint(cc.p(0.5, 0))
		gridView:setPosition(cc.p(detailLayoutSize.width / 2, 91))
        -- buffBtn
        local buffBtn = display.newButton(70, 50, {n = RES_DICT.BUFF_BTN})
        detailLayout:addChild(buffBtn, 5)
        local putLabel = display.newLabel(105, 64, {text = __('已摆放'), fontSize = 22, color = '#845229', ap = cc.p(0, 0.5)})
        detailLayout:addChild(putLabel, 5)
        local showNumLabel = display.newLabel(105, 36,fontWithColor(16, {text = '1/1', ap = cc.p(0, 0.5)}))
        detailLayout:addChild(showNumLabel, 5)
        -- okBtn
        local okBtn = display.newButton(detailLayoutSize.width - 105, 50, {n = RES_DICT.COMMON_BTN})
        detailLayout:addChild(okBtn, 5)
        display.commonLabelParams(okBtn, fontWithColor(14, {text = __('确定')}))
        -- back button
        local backBtn = display.newButton(display.SAFE_L + 75, bgSize.height - 52, {n = _res(RES_DICT.BTN_BACK)})
        self:addChild(backBtn, 10)
        return {
            view             = view,
            nameLabel        = nameLabel,
            goodsIcon        = goodsIcon,
            descrNode        = descrNode,
            wallView         = wallView,
            gridView         = gridView,
            buffBtn          = buffBtn,
            showNumLabel     = showNumLabel,
            okBtn            = okBtn,
            gridViewCellSize = gridViewCellSize,
            backBtn          = backBtn,
        }
    end
    -- eaterLayer
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 255*0.6))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(display.center)
    end, __G__TRACKBACK__)
end
--[[
刷新view
--]]
function PrivateRoomSouvenirView:RefreshView( goodsId )
    if not goodsId then return end
    local viewData = self.viewData
    local giftConf = CommonUtils.GetConfig('privateRoom', 'guestGift', goodsId)
    viewData.nameLabel:setString(giftConf.name)
    viewData.goodsIcon:setTexture(CommonUtils.GetGoodsIconPathById(goodsId))
    viewData.descrNode:RefreshNode(goodsId)
end
--[[
刷新陈列墙
--]]
function PrivateRoomSouvenirView:RefreshWall( wallData )
    if not wallData then return end
    self.viewData.wallView:RefreshWall(wallData)
end
--[[
陈列墙展品框选中
@params id int 展品框位置id
--]]
function PrivateRoomSouvenirView:SelectedSouvenirNode( id )
    if not id then return end
    self.viewData.wallView:SetSouvenirNodeSelected(id)
end
--[[
设置cell数目
--]]
function PrivateRoomSouvenirView:SetGridViewCellCount( count )
    self.viewData.gridView:setCountOfCell(checkint(count))
    self.viewData.gridView:reloadData()
end
--[[
设置展示数量  
@params count int 纪念品展示数目
--]]
function PrivateRoomSouvenirView:SetSouvenirShowCount( count )
    local giftConf = CommonUtils.GetConfigAllMess('giftPosition', 'privateRoom')
    local maxNum = table.nums(giftConf)
    if checkint(count) < maxNum then
        display.commonLabelParams(self.viewData.showNumLabel, fontWithColor(16, {text = string.format('%d/%d', checkint(count), maxNum)}))
    else
        display.commonLabelParams(self.viewData.showNumLabel, fontWithColor(10, {text = string.format('%d/%d', math.min(checkint(count), maxNum), maxNum)}))
    end
end
--[[
重载gridView
--]]
function PrivateRoomSouvenirView:ReloadGridView()
	local gridView = self.viewData.gridView
	local offset = gridView:getContentOffset()
	gridView:reloadData()
	gridView:setContentOffset(offset)
end
--[[
获取列表cell尺寸
--]]
function PrivateRoomSouvenirView:GetGridViewCellSize()
    return self.viewData.gridViewCellSize
end

return PrivateRoomSouvenirView