--[[
特殊活动 拼图活动页签view
--]]
local SpActivityBinggoPageView = class('SpActivityBinggoPageView', function ()
    local node = CLayout:create()
    node.name = 'home.SpActivityBinggoPageView'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    DEF_BG           = _res('ui/home/activity/activity_bg_loading.jpg'),
    TIME_BG          = _res('ui/home/activity/activity_time_bg.png'),
    BTN_ORANGE       = _res('ui/common/common_btn_big_orange.png'),
    BTN_BG           = _res('ui/home/specialActivity/unni_activity_bg_button.png'),
    RED_POINT_IMG    = _res('ui/common/common_hint_circle_red_ico.png'),
    RULE_TITLE_BG    = _res('ui/home/activity/activity_exchange_bg_rule_title.png'),
    RULE_BG          = _res('ui/home/activity/activity_exchange_bg_rule.png'),
    REWARD_BG        = _res("ui/home/specialActivity/activity_puzzle_reward_bg.png"),
	LIST_TITLE       = _res('ui/common/common_title_5.png'),
}
function SpActivityBinggoPageView:ctor( ... )
	local args = unpack({...})
    self.size = args.size
    self:InitUI()
end
 
function SpActivityBinggoPageView:InitUI()
    local size = self.size 
    self:setContentSize(size)
    local function CreateView()
        local view = CLayout:create(size)
	
        -- 背景
        local bg = lrequire('root.WebSprite').new({url = '', hpath = RES_DICT.DEF_BG, tsize = cc.size(1028,630)})
        bg:setVisible(false)
        bg:setAnchorPoint(display.CENTER)
        bg:setPosition(cc.p(size.width/2, size.height/2))
        view:addChild(bg)
        
        -- 跳转按钮
        local btnBg = display.newImageView(RES_DICT.BTN_BG, size.width - 260, 80)
        view:addChild(btnBg, 5)
        local enterBtn = display.newButton(size.width - 260, 80, {ap = display.CENTER, n = RES_DICT.BTN_ORANGE})
        view:addChild(enterBtn, 10)
        display.commonLabelParams(enterBtn, fontWithColor(14, {text = __('前往解密')}))
        local redPoint = display.newImageView(RES_DICT.RED_POINT_IMG, enterBtn:getContentSize().width-20, enterBtn:getContentSize().height-15)
        redPoint:setName('BTN_RED_POINT')
        redPoint:setVisible(false)
        enterBtn:addChild(redPoint)
        
        local roleImgSize = cc.size(552, 562)
        local roleImgLayer = display.newLayer(0, 0, {ap = display.LEFT_BOTTOM, size = roleImgSize})
        view:addChild(roleImgLayer)

        -- local tipLabel = display.newLabel(roleImgSize.width / 2, 245, {text = __('解锁全部拼图获得神秘奖励'), fontSize = 26, color = '#ffd27c', font = TTF_GAME_FONT, ttf = true, outline = '#5b3c25', outlineSize = 1, ap = display.CENTER})
        -- roleImgLayer:addChild(tipLabel)

        -- list
        local listTitle = display.newButton(size.width - 260, size.height - 60, {n = RES_DICT.LIST_TITLE, enable = false, ap = display.CENTER_TOP})
        local listTitleSize = listTitle:getContentSize()
        display.commonLabelParams(listTitle, fontWithColor(6, {text = __('解密任务奖励')}))
        view:addChild(listTitle)
        
        local listBg = display.newImageView(RES_DICT.REWARD_BG, 0, 0, {ap = display.LEFT_BOTTOM})
        local listBgSize = listBg:getContentSize()
        
        local listBgLayer = display.newLayer(listTitle:getPositionX(), listTitle:getPositionY() - listTitleSize.height - 5, {ap = display.CENTER_TOP, size = listBgSize})
        listBgLayer:addChild(listBg)
        view:addChild(listBgLayer)
    
        local gridViewCellSize = cc.size(listBgSize.width, 88)
        local gridView = CGridView:create(listBgSize)
        gridView:setSizeOfCell(gridViewCellSize)
        gridView:setColumns(1)
        gridView:setPosition(cc.p(listBgSize.width / 2, listBgSize.height / 2))
        gridView:setAnchorPoint(display.CENTER)
        listBgLayer:addChild(gridView)
    
        return {
            bg        = bg,
            view 	  = view,
            enterBtn  = enterBtn,
    
            roleImgLayer = roleImgLayer,
            gridView = gridView,
        }
    end
    xTry(function ( )
        self.viewData = CreateView()
        self.viewData.view:setPosition(utils.getLocalCenter(self))
        self:addChild(self.viewData.view, 1)
	end, __G__TRACKBACK__)
end
function SpActivityBinggoPageView:updateRoleImg(isReceive, skinId)
	local roleImgLayer = self:getViewData().roleImgLayer
	roleImgLayer:setVisible(not isReceive)
end

function SpActivityBinggoPageView:getViewData()
	return self.viewData
end
return SpActivityBinggoPageView
