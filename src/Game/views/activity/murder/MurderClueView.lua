--[[
 * author : liuzhipeng
 * descpt : 杀人案（19夏活）线索view
--]]
local MurderClueView = class('MurderClueView', function ()
    local node = CLayout:create(display.size)
    node.name = 'Game.views.activity.murder.MurderClueView'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    COMMON_TITLE                    = app.murderMgr:GetResPath('ui/common/common_title.png'),
	COMMON_TIPS       		        = app.murderMgr:GetResPath('ui/common/common_btn_tips.png'),
    BACK_BTN                        = app.murderMgr:GetResPath("ui/common/common_btn_back"),
    CLUE_BG                         = app.murderMgr:GetResPath('ui/home/activity/murder/murder_clue_bg.jpg'),
    CLUE_BTN_DEFAULT                = app.murderMgr:GetResPath('ui/home/activity/murder/murder_clue_btn_default.png'),
    CLUE_BTN_LOCK                   = app.murderMgr:GetResPath('ui/home/activity/murder/murder_clue_btn_lock.png'),
    CLUE_LABEL_BG                   = app.murderMgr:GetResPath('ui/home/activity/murder/murder_clue_label_num.png'),
    
    CLUE_SPINE                      = app.murderMgr:GetSpinePath('ui/home/activity/murder/effect/murder_clue_point'),
}
function MurderClueView:ctor( ... )
    self:InitUI()
end
--[[
init ui
--]]
function MurderClueView:InitUI()
    local function CreateView()
        local size = display.size
        local view = CLayout:create(size)
        local bg = display.newImageView(RES_DICT.CLUE_BG, size.width / 2, size.height / 2, {ap = cc.p(0.5, 0.5)})
        local clueLayout = CLayout:create(bg:getContentSize())
        clueLayout:setPosition(cc.p(size.width / 2, bg:getContentSize().height))
        clueLayout:setAnchorPoint(display.CENTER_BOTTOM)
        view:addChild(clueLayout, 1)
        bg:setPosition(cc.p(bg:getContentSize().width / 2, bg:getContentSize().height / 2))
        clueLayout:addChild(bg, 1)
        -- 标题版
		local tabNameLabel = display.newButton(display.SAFE_L + 130, display.height, {n = RES_DICT.COMMON_TITLE,enable = true,ap = cc.p(0, 1)})
		display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = app.murderMgr:GetPoText(__('镇魂歌之迷')), fontSize = 30, color = '473227',offset = cc.p(0,-8)})
        self:addChild(tabNameLabel, 20)
        -- 提示按钮
		local tabtitleTips = display.newImageView(RES_DICT.COMMON_TIPS, 242, 28)
        tabNameLabel:addChild(tabtitleTips, 1)
        -- 返回按钮
        local backBtn = display.newButton(0, 0, {n = RES_DICT.BACK_BTN})
        display.commonUIParams(backBtn, {po = cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.height - 18 - backBtn:getContentSize().height * 0.5)})
        view:addChild(backBtn, 10)
        return {
            bg               = bg,
            size             = size,
            view             = view,
            clueLayout       = clueLayout,
            tabNameLabel     = tabNameLabel,
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
        self:EnterAnimation()
    end, __G__TRACKBACK__)
end
--[[
进入动画
--]]
function MurderClueView:EnterAnimation()
    local viewData = self:GetViewData()
    -- 弹出标题板
	local tabNameLabelPos = cc.p(viewData.tabNameLabel:getPosition())
	viewData.tabNameLabel:setPositionY(display.height + 100)
	local action = cc.EaseBounceOut:create(cc.MoveTo:create(1, tabNameLabelPos))
	viewData.tabNameLabel:runAction( action )
    viewData.clueLayout:runAction(
        cc.Sequence:create(
            cc.EaseBackOut:create(
                cc.MoveBy:create(0.4, cc.p(0, -viewData.bg:getContentSize().height -viewData.bg:getContentSize().height / 2 + display.cy))
            ),
            cc.CallFunc:create(function ()
                app.uiMgr:GetCurrentScene():RemoveViewForNoTouch()
            end)
        )
    )
end
--[[
创建线索按钮
@params btnData map 线索配表数据
--]]
function MurderClueView:CreateClueButton( btnData )
    local viewData = self:GetViewData()
    local bgSize = viewData.bg:getContentSize()
    local size = cc.size(btnData.width, btnData.length)
    local layout = CLayout:create(size)
    layout:setPosition(cc.p(btnData.x, bgSize.height - btnData.y))
    viewData.clueLayout:addChild(layout, 1) 
    local btnIcon = display.newImageView(RES_DICT.CLUE_BTN_DEFAULT, size.width / 2, size.height / 2)
    layout:addChild(btnIcon, 1)
    local clueBtn = display.newButton(size.width / 2, size.height / 2, {n = 'empty', size = size})
    layout:addChild(clueBtn , 2)
    local clueSpine = sp.SkeletonAnimation:create(
        RES_DICT.CLUE_SPINE.json,
        RES_DICT.CLUE_SPINE.atlas,
        1)
    clueSpine:update(0)
    clueSpine:setToSetupPose()
    clueSpine:setAnimation(0, 'idle0', true)
    clueSpine:setPosition(cc.p(size.width / 2, size.height / 2))
    layout:addChild(clueSpine, 2)
    local titleBg = display.newImageView(RES_DICT.CLUE_LABEL_BG, size.width / 2, size.height / 2 - 90)
    layout:addChild(titleBg, 10)
    local titleLabel = display.newLabel(titleBg:getContentSize().width / 2, titleBg:getContentSize().height / 2, {text = '', fontSize = 20, color = '#ffffff'})
    titleBg:addChild(titleLabel, 1)
    return {
        layout     = layout,
        btnIcon    = btnIcon,
        clueBtn    = clueBtn,
        clueSpine  = clueSpine,
        titleBg    = titleBg,
        titleLabel = titleLabel,
    }
end
--[[
改变按钮icon状态
--]]
function MurderClueView:ChangeBtnIcon( btnIcon, isLock )
    local texture = RES_DICT.CLUE_BTN_DEFAULT
    if isLock then
        texture = RES_DICT.CLUE_BTN_LOCK
    end
    btnIcon:setTexture(texture)
end
--[[
获取viewData
--]]
function MurderClueView:GetViewData()
    return self.viewData
end

return MurderClueView