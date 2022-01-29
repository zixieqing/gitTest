--[[
 * author : liuzhipeng
 * descpt : 杀人案（19夏活）棋盘view
--]]
local MurderChessboardView = class('MurderChessboardView', function ()
    local node = CLayout:create(display.size)
    node.name = 'Game.views.activity.murder.MurderChessboardView'
    node:enableNodeEvents()
    return node
end)
local GoodPurchaseNode = require('common.GoodPurchaseNode')
local RES_DICT = {
    BACK_BTN                        = app.murderMgr:GetResPath("ui/common/common_btn_back"),
    CHESSBOARD_BG                   = app.murderMgr:GetResPath('ui/home/activity/murder/murder_chess_bg.png'),
    COMMON_TITLE                    = app.murderMgr:GetResPath('ui/common/common_title.png'),
    COMMON_TIPS       		        = app.murderMgr:GetResPath('ui/common/common_btn_tips.png'),
    CHESSBOARD_ITEM_1               = app.murderMgr:GetResPath('ui/home/activity/murder/murder_chess_ico_item_1.png'),
    CHESSBOARD_ITEM_2               = app.murderMgr:GetResPath('ui/home/activity/murder/murder_chess_ico_item_2.png'),
    CHESSBOARD_ITEM_3               = app.murderMgr:GetResPath('ui/home/activity/murder/murder_chess_ico_item_3.png'),
    CHESSBOARD_PLATE_1              = app.murderMgr:GetResPath('ui/home/activity/murder/murder_chess_img_base_1.png'),
    CHESSBOARD_PLATE_2              = app.murderMgr:GetResPath('ui/home/activity/murder/murder_chess_img_base_2.png'),
    CHESSBOARD_PLATE_3              = app.murderMgr:GetResPath('ui/home/activity/murder/murder_chess_img_base_3.png'),
    CHESSBOARD_CLOCK_2              = app.murderMgr:GetResPath('ui/home/activity/murder/murder_chess_img_clock_2.png'),
    CHESSBOARD_CLOCK_3              = app.murderMgr:GetResPath('ui/home/activity/murder/murder_chess_img_clock_3.png'),
    CHESS_PRIECES_1                 = app.murderMgr:GetResPath('ui/home/activity/murder/murder_chess_img_rook.png'),
    CHESS_PRIECES_2                 = app.murderMgr:GetResPath('ui/home/activity/murder/murder_chess_img_queen.png'),
    CHESS_PRIECES_3                 = app.murderMgr:GetResPath('ui/home/activity/murder/murder_chess_img_king.png'),
    LOCK_MASK_2                     = app.murderMgr:GetResPath('ui/home/activity/murder/murder_chess_shade_2.png'),
    LOCK_MASK_3                     = app.murderMgr:GetResPath('ui/home/activity/murder/murder_chess_shade_3.png'), 
    COMMON_LOCK_ICON                = app.murderMgr:GetResPath('ui/common/common_ico_lock.png'),
    MONEY_INFO_BAR       		    = app.murderMgr:GetResPath('ui/home/nmain/main_bg_money.png'),

    POINTER_SPINE      	 	 	    = app.murderMgr:GetSpinePath('ui/home/activity/murder/effect/murder_material_spot'),
}
local CHESSBOARD_CONFIG = {
    {
        type = 1,
        confList = {
            {centerOffset = cc.p(-325, 56), itemOffset = cc.p(0, 0), size = cc.size(180, 100)},
            {centerOffset = cc.p(-395, -62), itemOffset = cc.p(0, 0), size = cc.size(250, 135)},
            {centerOffset = cc.p(-494, -235), itemOffset = cc.p(0, 0), size = cc.size(270, 205)}
        }
    },
    {
        type = 2,
        plate = '',
        light = '',
        confList = {
            {centerOffset = cc.p(-120, 56), itemOffset = cc.p(0, 0), size = cc.size(220, 100)},
            {centerOffset = cc.p(-138, -62), itemOffset = cc.p(0, 0), size = cc.size(245, 135)},
            {centerOffset = cc.p(-170, -235), itemOffset = cc.p(0, 0), size = cc.size(315, 205)}
        }
        
    },
    {
        type = 2,
        plate = '',
        light = '',
        confList = {
            {centerOffset = cc.p(100, 56), itemOffset = cc.p(0, 0), size = cc.size(200, 100)},
            {centerOffset = cc.p(118, -62), itemOffset = cc.p(0, 0), size = cc.size(245, 135)},
            {centerOffset = cc.p(145, -235), itemOffset = cc.p(0, 0), size = cc.size(305, 205)}
        }
        
    },
    {
        type = 2,
        plate = '',
        light = '',
        confList = {
            {centerOffset = cc.p(320, 56), itemOffset = cc.p(0, 0), size = cc.size(220, 100)},
            {centerOffset = cc.p(390, -62), itemOffset = cc.p(0, 0), size = cc.size(280, 135)},
            {centerOffset = cc.p(480, -235), itemOffset = cc.p(0, 0), size = cc.size(330, 205)}
        }
        
    }
}
function MurderChessboardView:ctor( ... )
    self:InitUI()
end
--[[
init ui
--]]
function MurderChessboardView:InitUI()
    local function CreateView()
        local size = display.size
        local view = CLayout:create(size)
        local bg = display.newImageView(RES_DICT.CHESSBOARD_BG, size.width / 2, size.height / 2)
        view:addChild(bg, 1)
        -- 标题版
		local tabNameLabel = display.newButton(display.SAFE_L + 130, display.height, {n = RES_DICT.COMMON_TITLE,enable = true,ap = cc.p(0, 1)})
		display.commonLabelParams(tabNameLabel, {ttf = true, font = TTF_GAME_FONT, text = app.murderMgr:GetPoText(__('时间棋局')), fontSize = 30, color = '473227',offset = cc.p(0,-8)})
        self:addChild(tabNameLabel, 20)
        -- 提示按钮
		local tabtitleTips = display.newImageView(RES_DICT.COMMON_TIPS, 242, 28)
        tabNameLabel:addChild(tabtitleTips, 1)
        -- 棋盘mask2
        local chessboardMask2 = display.newImageView(RES_DICT.LOCK_MASK_2, size.width / 2 + 172, size.height / 2 - 115)
        chessboardMask2:setVisible(false)
        view:addChild(chessboardMask2, 3)
        local lockIcon2 = display.newImageView(RES_DICT.COMMON_LOCK_ICON, chessboardMask2:getContentSize().width / 2 - 50, chessboardMask2:getContentSize().height / 2 + 85)
        lockIcon2:setScale(1.75)
        chessboardMask2:addChild(lockIcon2, 1)
        local locklabel2 = display.newLabel(chessboardMask2:getContentSize().width / 2 - 50, chessboardMask2:getContentSize().height / 2 + 20, {text = string.fmt(app.murderMgr:GetPoText(__('时针指向_num_点解锁')), {['_num_'] = app.murderMgr:GetNumTimes(4)}), fontSize = 22, color = '#ffffff', reqW = 235})
        chessboardMask2:addChild(locklabel2, 1)
        local clockIcon2 = display.newImageView(RES_DICT.CHESSBOARD_CLOCK_2, chessboardMask2:getContentSize().width / 2 - 85,  chessboardMask2:getContentSize().height - 10, {ap = display.CENTER_BOTTOM})
        chessboardMask2:addChild(clockIcon2, 1)
        -- 棋盘mask3
        local chessboardMask3 = display.newImageView(RES_DICT.LOCK_MASK_3, size.width / 2 + 450, size.height / 2 - 115)
        chessboardMask3:setVisible(false)
        view:addChild(chessboardMask3, 3)
        local lockIcon3 = display.newImageView(RES_DICT.COMMON_LOCK_ICON, chessboardMask3:getContentSize().width / 2 - 65, chessboardMask3:getContentSize().height / 2 + 85)
        lockIcon3:setScale(1.75)
        chessboardMask3:addChild(lockIcon3, 1)
        local locklabel3 = display.newLabel(chessboardMask3:getContentSize().width / 2 - 50, chessboardMask3:getContentSize().height / 2 + 20, {text = string.fmt(app.murderMgr:GetPoText(__('时针指向_num_点解锁')), {['_num_'] = app.murderMgr:GetNumTimes(6)}), fontSize = 22, color = '#ffffff', reqW = 235})
        chessboardMask3:addChild(locklabel3, 1)
        local clockIcon3 = display.newImageView(RES_DICT.CHESSBOARD_CLOCK_3, chessboardMask3:getContentSize().width / 2 - 160,  chessboardMask3:getContentSize().height - 10, {ap = display.CENTER_BOTTOM})
        chessboardMask3:addChild(clockIcon3, 1)
        -- top ui layer
		local topUILayer = display.newLayer()
		topUILayer:setPositionY(190)
		view:addChild(topUILayer, 10)
        -- money barBg
		local moneyBarBg = display.newImageView(app.murderMgr:GetResPath(RES_DICT.MONEY_INFO_BAR), display.width, display.height, {ap = display.RIGHT_TOP, scale9 = true, size = cc.size(1, 54)})
		topUILayer:addChild(moneyBarBg)
		-- money layer
		local moneyLayer = display.newLayer()
		topUILayer:addChild(moneyLayer)
        -- 返回按钮
        local backBtn = display.newButton(0, 0, {n = RES_DICT.BACK_BTN})
        display.commonUIParams(backBtn, {po = cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.height - 18 - backBtn:getContentSize().height * 0.5)})
        view:addChild(backBtn, 10)
        return {
            size             = size,
            view             = view,
            tabNameLabel     = tabNameLabel,
            backBtn          = backBtn,
            chessboardMask2  = chessboardMask2,
            chessboardMask3  = chessboardMask3,
            moneyBarBg       = moneyBarBg,
            moneyLayer       = moneyLayer,
            topUILayer       = topUILayer,
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
        self.viewData.topUILayer:runAction(cc.MoveTo:create(0.4, cc.p(0, 0)))
		-- 弹出标题板
		local tabNameLabelPos = cc.p(self.viewData.tabNameLabel:getPosition())
		self.viewData.tabNameLabel:setPositionY(display.height + 100)
		local action = cc.EaseBounceOut:create(cc.MoveTo:create(1, tabNameLabelPos))
        self.viewData.tabNameLabel:runAction( action )
    end, __G__TRACKBACK__)
end
--[[
刷新棋盘
@params clockLevel int 时钟等级（用于判断材料本解锁情况）
@params btnCallback function 按钮点击回调
--]]
function MurderChessboardView:RefreshChessboard( clockLevel, btnCallback )
    local viewData = self:GetViewData()
    local materialConfig = CommonUtils.GetConfigAllMess('materialSchedule', 'newSummerActivity')
    for column, columnConf in ipairs(CHESSBOARD_CONFIG) do
        if column == 3 then
            -- 中级副本解锁
            if checkint(materialConfig[2].unlockCondition) > clockLevel then
                viewData.chessboardMask2:setVisible(true)
            else 
                self:AddChess(column, columnConf, btnCallback)
            end
        elseif column == 4 then 
            -- 高级副本解锁
            if checkint(materialConfig[3].unlockCondition) > clockLevel then
                viewData.chessboardMask3:setVisible(true)
            else
                self:AddChess(column, columnConf, btnCallback)
            end
        else
            self:AddChess(column, columnConf, btnCallback)
        end
    end
end
--[[
添加棋子
--]]
function MurderChessboardView:AddChess( column, columnConf, btnCallback )
    local viewData = self:GetViewData()
    local size = viewData.size
    local view = viewData.view
    local materialConfig = CommonUtils.GetConfigAllMess('materialSchedule', 'newSummerActivity')
    if columnConf.type == 1 then
        -- 棋子
        for row, conf in ipairs(columnConf.confList) do
            local chess = display.newImageView(app.murderMgr:GetResPath(string.format('ui/home/activity/murder/murder_chess_img_%d.png', 4 - row)), size.width / 2 + conf.centerOffset.x, size.height / 2 + conf.centerOffset.y, {ap = cc.p(0.5, 0.2)})
            viewData.view:addChild(chess, 5) 
        end
    elseif columnConf.type == 2 then
        -- 按钮
        for row, conf in ipairs(columnConf.confList) do
            local plate = display.newImageView(app.murderMgr:GetResPath(string.format('ui/home/activity/murder/murder_chess_img_base_%d.png', column - 1)), size.width / 2 + conf.centerOffset.x, size.height / 2 + conf.centerOffset.y)
            viewData.view:addChild(plate, 4) 
            local pointer = sp.SkeletonAnimation:create(
                RES_DICT.POINTER_SPINE.json,
                RES_DICT.POINTER_SPINE.atlas,
                1)
            pointer:update(0)
            pointer:setToSetupPose()
            pointer:setAnimation(0, string.format('play%d', 4 - row), true)
            pointer:setPosition(cc.p(size.width / 2 + conf.centerOffset.x, size.height / 2 + conf.centerOffset.y))
            view:addChild(pointer, 5)
            if row == 1 then
                plate:setScale(0.64)
                pointer:setScale(0.64)
            elseif row == 2 then
                plate:setScale(0.75)
                pointer:setScale(0.75)
            end
            local button = display.newButton(size.width / 2 + conf.centerOffset.x, size.height / 2 + conf.centerOffset.y, {n = '', size = conf.size, cb = btnCallback})
            button:setTag(materialConfig[column - 1].pointId[row])
            viewData.view:addChild(button, 5) 
        end
    end
end
--[[
重载货币栏
--]]
function MurderChessboardView:ReloadMoneyBar(moneyIdMap, isDisableGain)
    if moneyIdMap then
        moneyIdMap[tostring(GOLD_ID)]         = nil
        moneyIdMap[tostring(DIAMOND_ID)]      = nil
        moneyIdMap[tostring(PAID_DIAMOND_ID)] = nil
        moneyIdMap[tostring(FREE_DIAMOND_ID)] = nil
    end
    
    -- money data
    local moneyIdList = table.keys(moneyIdMap or {})
    table.insert(moneyIdList, GOLD_ID)
    table.insert(moneyIdList, DIAMOND_ID)
    
    -- clean moneyLayer
    local moneyBarBg = self:GetViewData().moneyBarBg
    local moneyLayer = self:GetViewData().moneyLayer
    moneyLayer:removeAllChildren()
    
    -- update moneyLayer
    local MONEY_NODE_GAP = 16
    local moneyLayerSize = moneyLayer:getContentSize()
    local moneryBarSize  = cc.size(20, moneyBarBg:getContentSize().height)
    for i = #moneyIdList, 1, -1 do
        local moneyId = checkint(moneyIdList[i])
        local isDisable = moneyId ~= GOLD_ID and moneyId ~= DIAMOND_ID and isDisableGain
        local moneyNode = GoodPurchaseNode.new({id = moneyId, animate = true, disable = isDisable, isEnableGain = not isDisableGain})
        moneyNode.viewData.touchBg:setTag(checkint(moneyId))
        moneyNode:setPosition(display.SAFE_R - moneryBarSize.width, moneyLayerSize.height - 26)
        moneyNode:setAnchorPoint(display.RIGHT_CENTER)
        moneyNode:setName(moneyId)
        moneyLayer:addChild(moneyNode)

        moneryBarSize.width = moneryBarSize.width + moneyNode:getContentSize().width + MONEY_NODE_GAP
    end

    -- update moneyBarBg
    moneryBarSize.width = 40 + moneryBarSize.width + (display.width - display.SAFE_R)
    moneyBarBg:setContentSize(moneryBarSize)

    -- update money value
    self:UpdateMoneyBar()
end
--[[
更新货币栏
--]]
function MurderChessboardView:UpdateMoneyBar()
    for _, moneyNode in ipairs(self:GetViewData().moneyLayer:getChildren()) do
        local moneyId = checkint(moneyNode:getName())
        moneyNode:updataUi(moneyId)
    end
end
--[[
获取viewData
--]]
function MurderChessboardView:GetViewData()
    return self.viewData
end
return MurderChessboardView