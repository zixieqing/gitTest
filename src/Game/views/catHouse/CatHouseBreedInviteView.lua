--[[
 * author : liuzhipeng
 * descpt : 猫屋 好友邀请View
--]]
local CatHouseBreedInviteView = class('CatHouseBreedInviteView', function ()
    return ui.layer({name = 'Game.views.catHouse.CatHouseBreedInviteView', enableEvent = true, ap = display.CENTER})
end)
-------------------------------------------------
-------------------- define ---------------------
local RES_DICT = {
    LIST_BG       = _res('ui/common/common_bg_4.png'),
    TITLE_BG      = _res('ui/common/common_title_5.png'), 
    SPLIT_LINE    = _res('ui/cards/propertyNew/card_ico_attribute_line.png'),
    CELL_BG       = _res('avatar/ui/restaurant_bg_friends_list.png'),
    CELL_BG_S     = _res('avatar/ui/restaurant_bg_friends_list_selected.png'), 
    COMMON_BTN    = _res('ui/common/common_btn_orange.png'),
    COMMON_BTN_W  = _res('ui/common/common_btn_white_default.png'),
    HEAD_BG       = _res('ui/author/create_roles_head_down_default.png'),
    CHECKBOX_N    = _res('ui/common/common_btn_check_default.png'),
    CHECKBOX_S    = _res('ui/common/common_btn_check_selected.png')
}
local CreateFriendListCell = nil
-------------------- define ---------------------
-------------------------------------------------

-------------------------------------------------
------------------ inheritance ------------------
function CatHouseBreedInviteView:ctor( ... )
    self:InitUI()
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
init ui
--]]
function CatHouseBreedInviteView:InitUI()
    local function CreateView()
        local size = cc.size(410, 750)
        local view = CLayout:create(size)
        view:setAnchorPoint(display.RIGHT_CENTER)
        local bg = display.newImageView(RES_DICT.LIST_BG, size.width / 2, size.height / 2, {scale9 = true, size = size})
        view:addChild(bg, 1)
        -- mask
        local mask = display.newLayer(size.width/2 ,size.height/2 ,{ap = display.CENTER , size = size, enable = true, color = cc.c4b(0,0,0,0)})
        view:addChild(mask, -1)
        -- 标题
        local titleBg = display.newImageView(RES_DICT.TITLE_BG, size.width / 2, size.height - 14, {ap = display.CENTER_TOP})
        view:addChild(titleBg, 1)
        local titleLabel = display.newLabel(titleBg:getContentSize().width / 2, titleBg:getContentSize().height / 2, {text = __('我的好友'), color = '#796545', fontSize = 20})
        titleBg:addChild(titleLabel, 1)
        -- 好友人数
        local friendAmountLabel = display.newLabel(20, size.height - 70, fontWithColor(4, {text = '', ap = display.LEFT_CENTER}))
        view:addChild(friendAmountLabel, 3)
        -- 分割线
        local line = display.newImageView(RES_DICT.SPLIT_LINE, size.width / 2, size.height - 90)
        view:addChild(line, 1)
        -- 列表
        local friendListViewSize = cc.size(size.width, 560)
        local friendListView = ui.tableView({x = size.width / 2, y = size.height / 2, size = friendListViewSize, csizeH = 93, auto = true, dir = display.SDIR_V})
        friendListView:setCellCreateHandler(CreateFriendListCell)
        view:addChild(friendListView, 3)
        
        -- 邀请按钮
        local inviteBtn = display.newButton(size.width / 2 - 75, 50, {n = RES_DICT.COMMON_BTN})
        display.commonLabelParams(inviteBtn, fontWithColor(14, {text = __('邀请')}))
        view:addChild(inviteBtn, 5)
        local checkAllBtn = display.newButton(size.width / 2 + 75, 50, {n = RES_DICT.COMMON_BTN_W})
        display.commonLabelParams(checkAllBtn, fontWithColor(14, {text = __('全选')}))
        view:addChild(checkAllBtn, 5)
        
        return {
            view              = view,
            friendAmountLabel = friendAmountLabel,
            friendListView    = friendListView,
            inviteBtn         = inviteBtn,
            checkAllBtn       = checkAllBtn,
        }
    end
    -- eaterLayer
    local eaterLayer = display.newLayer(display.cx, display.cy, {size = display.size, ap = display.CENTER, color = cc.c4b(0, 0, 0, 255 * 0.6), enable = true})
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(cc.p(display.width - display.SAFE_L, display.cy))
        self:EnterAction()
    end, __G__TRACKBACK__)
end
--[[
进入动画
--]]
function CatHouseBreedInviteView:EnterAction(  )
    local viewData = self:GetViewData()
    viewData.view:setPositionX(display.width + self:getContentSize().width + 50)
    viewData.view:runAction(
        cc.MoveTo:create(0.3, cc.p(display.width - display.SAFE_L, display.cy))
    )
end

CreateFriendListCell = function ( cellParent )
    local view = cellParent
    local size = cellParent:getContentSize()
    -- 背景
    local bg = display.newImageView(RES_DICT.CELL_BG, size.width / 2, size.height / 2)
    view:addChild(bg, 1)

    local headerButton = require('root.CCHeaderNode').new({bg = RES_DICT.HEAD_BG, pre = 500077})
    headerButton:setPosition(cc.p(55, size.height / 2))
    headerButton:setScale(0.5)
    headerButton.headerSprite:setScale(0.8)
    view:addChild(headerButton, 5)
    -- 名称
    local nameLabel = display.newLabel(105, size.height - 25, fontWithColor(11, {text = '', ap = display.LEFT_CENTER}))
    view:addChild(nameLabel, 1)
    -- 等级
    local levelLabel = display.newLabel(105, size.height / 2 - 5, fontWithColor(6, {text = '', ap = display.LEFT_CENTER}))
    view:addChild(levelLabel, 1)
    -- 复选框
    local checkbox = display.newCheckBox(size.width - 70, size.height / 2, {ap = display.CENTER , n = RES_DICT.CHECKBOX_N, d = RES_DICT.CHECKBOX_S, s = RES_DICT.CHECKBOX_S})
    checkbox:setName('checkbox')
    view:addChild(checkbox, 5)
    -- 已邀请
    local invitedLabel = display.newLabel(size.width - 70, size.height / 2, {text = __('已邀请'), fontSize = 26, color = '#b1613a', ttf = true, font = TTF_GAME_FONT})
    view:addChild(invitedLabel, 5)
    return {
        size           = size,
        view           = view,
        headerButton   = headerButton,
        nameLabel      = nameLabel,
        levelLabel     = levelLabel,
        checkbox       = checkbox,
        invitedLabel   = invitedLabel,
    }
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- public ---------------------
--[[
更新好友数量
--]]
function CatHouseBreedInviteView:UpdateFriendAmountLabel( friendData )
    local viewData = self:GetViewData()
    local online = 0
    for i, v in ipairs(checktable(friendData)) do
        if checkint(v.isOnline) == 1 then
            online = online + 1
        end
    end
    viewData.friendAmountLabel:setString(string.format(__('好友人数: %s/%s'), tostring(online), tostring(#friendData)))
end
-------------------- public ---------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
获取viewData
--]]
function CatHouseBreedInviteView:GetViewData()
    return self.viewData
end
------------------- get / set -------------------
-------------------------------------------------
return CatHouseBreedInviteView