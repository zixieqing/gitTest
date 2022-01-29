--[[
包厢菜单view
--]]
local PrivateRoomMenuView = class('PrivateRoomMenuView', function ()
    local node = CLayout:create(display.size)
    node.name = 'home.PrivateRoomMenuView'
    node:enableNodeEvents()
    return node
end)
local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local RES_DICT = {
    BG            = _res('ui/privateRoom/vip_menu_bg.png'),
    CLAMP         = _res('ui/privateRoom/menu_img_jiazi.png'), 
    LIST_BG       = _res('ui/common/commcon_bg_text.png'),
    TITLE_BG      = _res('ui/common/common_title_5.png'),
    COMMON_BTN    = _res('ui/common/common_btn_orange.png'),
    BTN_WHITE     = _res('ui/common/common_btn_white_default.png'),
    REWARD_NUM_BG = _res('ui/home/takeaway/takeout_bg_reward_number.png'),

}
function PrivateRoomMenuView:ctor( ... )
    self:InitUI()
end
--[[
init ui
--]]
function PrivateRoomMenuView:InitUI()
    local function CreateView()
        local size = cc.size(514, 730)
        local view = CLayout:create(size)
        local mask = CColorView:create(cc.c4b(0, 0, 0, 0))
        mask:setTouchEnabled(true)
        mask:setContentSize(size)
        mask:setPosition(cc.p(size.width / 2, size.height / 2))
        view:addChild(mask, -1)
        local bg = display.newImageView(RES_DICT.BG, size.width/2, size.height/2 - 10)
        view:addChild(bg, -1)
        local clamp = display.newImageView(RES_DICT.CLAMP, size.width / 2, size.height, {ap = cc.p(0.5, 1)})
        view:addChild(clamp, 1)
        local nameLabel = display.newLabel(size.width / 2, size.height - 100, {text = '', fontSize = 24, color = '#5b3c25', font = TTF_GAME_FONT, ttf = true})
        view:addChild(nameLabel, 5)
        -- gridView
        local gridViewSize = cc.size(376, 270)
        local gridViewCellSize = cc.size(125, 135)
        local gridViewBg = display.newImageView(RES_DICT.LIST_BG, size.width / 2, size.height - 260, {scale9 = true, size = gridViewSize})
        view:addChild(gridViewBg, 3)
		local gridView = CGridView:create(cc.size(gridViewSize.width, gridViewSize.height))
		gridView:setSizeOfCell(gridViewCellSize)
        gridView:setColumns(3)
        gridView:setBounceable(false)
        view:addChild(gridView, 5)
		gridView:setPosition(cc.p(size.width / 2, size.height - 260))
        -- title
        local titleBg = display.newButton(size.width / 2, 294, {n = RES_DICT.TITLE_BG, enable = false})
        view:addChild(titleBg, 5)
        display.commonLabelParams(titleBg, fontWithColor(4, {text = __('奖励')}))
        -- 知名度
        local popularityBtn = display.newButton(160, 250, {n = RES_DICT.REWARD_NUM_BG, scale9 = true, size = cc.size(190, 37)})
        view:addChild(popularityBtn, 5)
        local popularityIcon = display.newImageView(CommonUtils.GetGoodsIconPathById(POPULARITY_ID), 20 ,popularityBtn:getContentSize().height / 2)
        popularityIcon:setScale(0.2)
        popularityBtn:addChild(popularityIcon, 1)
        local popularityNum = display.newLabel(popularityBtn:getContentSize().width - 5, popularityBtn:getContentSize().height / 2, {text = '', fontSize = 22, color = '#d23d3d', ap = cc.p(1, 0.5)})
        popularityBtn:addChild(popularityNum, 1)
        -- 金币
        local goldBtn = display.newButton(size.width - 160, 250, {n = RES_DICT.REWARD_NUM_BG, scale9 = true, size = cc.size(190, 37)})
        view:addChild(goldBtn, 5)
        local goldIcon = display.newImageView(CommonUtils.GetGoodsIconPathById(GOLD_ID), 20 ,goldBtn:getContentSize().height / 2)
        goldIcon:setScale(0.2)
        goldBtn:addChild(goldIcon, 1)
        local goldNum = display.newLabel(goldBtn:getContentSize().width - 5, goldBtn:getContentSize().height / 2, {text = '', fontSize = 22, color = '#d23d3d', ap = cc.p(1, 0.5)})
        goldBtn:addChild(goldNum, 1)
        -- 按钮
        local abandonBtn = display.newButton(130, 90, {n = RES_DICT.BTN_WHITE})
        display.commonLabelParams(abandonBtn, fontWithColor(14, {text = __('放弃')}))
        view:addChild(abandonBtn, 5)
        local serveBtn = display.newButton(size.width - 130, 90, {n = RES_DICT.COMMON_BTN})
        display.commonLabelParams(serveBtn, fontWithColor(14, {text = __('上菜')}))
        view:addChild(serveBtn, 5)

        return {
            size             = size,
            view             = view,
            gridViewCellSize = gridViewCellSize,
            gridView         = gridView,
            abandonBtn       = abandonBtn, 
            serveBtn         = serveBtn,
            popularityBtn    = popularityBtn,
            popularityNum    = popularityNum,
            goldBtn          = goldBtn,
            goldNum          = goldNum,
            nameLabel        = nameLabel,
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
    end, __G__TRACKBACK__)
end
return PrivateRoomMenuView