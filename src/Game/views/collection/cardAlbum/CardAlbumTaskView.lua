--[[
 * author : liuzhipeng
 * descpt : 图鉴 飨灵收集册 任务View
--]]
local CardAlbumTaskView = class('CardAlbumTaskView', function ()
    local node = CLayout:create(display.size)
    node.name = 'collection.cardAlbum.CardAlbumTaskView'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    BG                   = _res('ui/collection/cardAlbum/task_bg.png'),
    COMMON_BTN_N         = _res('ui/common/common_btn_orange.png'), 
    COMMON_BTN_W         = _res('ui/common/common_btn_white_default.png'), 
    COMMON_BTN_F         = _res('ui/common/activity_mifan_by_ico.png'),
    COMMON_BTN_D         = _res('ui/common/common_btn_orange_disable.png'),
    TASK_CELL_BG_N       = _res('ui/collection/cardAlbum/task_bg_list.png'),
    TASK_CELL_BG_S       = _res('ui/collection/cardAlbum/task_bg_list.png'),
    TASK_CELL_BG_F       = _res('ui/collection/cardAlbum/task_bg_list_grey.png'),
    TAKS_CELL_TITLE_BG_N = _res('ui/collection/cardAlbum/task_list_title.png'),
    TAKS_CELL_TITLE_BG_S = _res('ui/collection/cardAlbum/task_list_title.png'),
    TAKS_CELL_TITLE_BG_F = _res('ui/collection/cardAlbum/task_list_title_grey.png'),
    CLOSE_BTN            = _res("ui/common/common_btn_quit.png"),
    LIST_BOTTOM_FG       = _res('ui/collection/cardAlbum/task_list_bottom_grey.png'),


}
local CreateListCell = nil 

function CardAlbumTaskView:ctor( ... )
    self:InitUI()
end
--[[
init ui
--]]
function CardAlbumTaskView:InitUI()
    local function CreateView()
        local bg = display.newImageView(RES_DICT.BG, 0, 0)
        local size = bg:getContentSize()
        local view = CLayout:create(size)
        bg:setPosition(cc.p(size.width / 2, size.height / 2))
        view:addChild(bg, 1)
        -- mask
        local mask = display.newLayer(size.width/2 ,size.height/2 ,{ap = display.CENTER , size = size, enable = true, color = cc.c4b(0,0,0,0)})
        view:addChild(mask, -1)
        -- 标题
        local titileLabel = display.newLabel(size.width / 2 - 55, size.height - 30, {text = __('等级任务'), fontSize = 22, color = '#ffffff'})
        view:addChild(titileLabel, 1)
        -- 任务列表
        local gridViewSize = cc.size(980, 550)
        local taskGridView = display.newGridView(size.width / 2 - 55, size.height / 2 - 18, {cols = 1, size = gridViewSize, csize = cc.size(gridViewSize.width, 146)})
        taskGridView:setCellCreateHandler(CreateListCell)
        view:addChild(taskGridView, 5)
        local listBottomFg = display.newImageView(RES_DICT.LIST_BOTTOM_FG, size.width / 2 - 55, 25)
        view:addChild(listBottomFg, 5)
        -- 一键领取
        local drawBtn = display.newButton(size.width - 74, 78, {n = RES_DICT.COMMON_BTN_N})
        view:addChild(drawBtn, 5)
        display.commonLabelParams(drawBtn, fontWithColor(14, {text = __('一键领取'), reqW = 95}))
        -- 关闭按钮
        local closeBtn = display.newButton(size.width - 105 ,size.height - 50 ,{n = RES_DICT.CLOSE_BTN})
        view:addChild(closeBtn, 5)
        return {
            view                = view,
            taskGridView        = taskGridView,
            drawBtn             = drawBtn,
            closeBtn            = closeBtn,
        }
    end
    -- eaterLayer
    local eaterLayer = display.newLayer(display.cx, display.cy, {size = display.size, ap = display.CENTER, color = cc.c4b(0, 0, 0, 255 * 0.6), enable = true})
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer
    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(display.center)
        self:EnterAction()
    end, __G__TRACKBACK__)
end
--[[
进入动画
--]]
function CardAlbumTaskView:EnterAction(  )
    local viewData = self:GetViewData()
    viewData.view:setOpacity(255 * 0.3)
    viewData.view:runAction(
        cc.FadeIn:create(0.2)
    )
end
--[[
关闭动画
--]]
function CardAlbumTaskView:CloseAction()
    local viewData = self:GetViewData()
    viewData.view:runAction(
        cc.Sequence:create(
            cc.FadeOut:create(0.2),
            cc.CallFunc:create(function()
                local scene = app.uiMgr:GetCurrentScene()
                scene:RemoveDialog(self)
            end)
        )
    )
end
--[[
创建列表cell
--]]
CreateListCell = function( cellParent )
    local view = cellParent
    local size = cellParent:getContentSize()
    -- 背景
    local cellBg = display.newImageView(RES_DICT.TASK_CELL_BG_N, size.width / 2, size.height / 2)
    view:addChild(cellBg, 1)
    -- 任务标题
    local titleBg = display.newImageView(RES_DICT.TAKS_CELL_TITLE_BG_N, 4, size.height - 35, {ap = display.LEFT_CENTER})
    view:addChild(titleBg, 3)
    local titleLabel = display.newLabel(15, size.height - 35, {text = '', fontSize = 26, color = '#ffffff', ap = display.LEFT_CENTER})
    view:addChild(titleLabel, 5)
    -- 任务描述
    local descr = display.newLabel(15, 85, {ap = display.LEFT_TOP, text = '', fontSize = 22, color = '#906866', w = 740})
    view:addChild(descr, 5)
    -- 按钮
    local button = display.newButton(size.width - 90, size.height / 2, {n = RES_DICT.COMMON_BTN_N})
    view:addChild(button, 1)
    display.commonLabelParams(button, fontWithColor(14, {text = __('领取')}))
    -- 进度
    local progressLabel = display.newLabel(size.width - 90, 30, {text = '', fontSize = 20, color = '#7d7d7c'})
    view:addChild(progressLabel, 1)
    -- 奖励layout
    local rewardsLayout = CLayout:create(cc.size(260, size.height))
    rewardsLayout:setPosition(size.width - 305, size.height / 2)
    view:addChild(rewardsLayout, 1)
    return {
        view              = view,
        cellBg            = cellBg,
        titleLabel        = titleLabel,
        descr             = descr,
        button            = button,
        progressLabel     = progressLabel,
        titleBg           = titleBg,
        rewardsLayout     = rewardsLayout,
    }
end
--[[
刷新任务状态
--]]
function CardAlbumTaskView:RefreshTaskState( cellViewData, taskData )
    display.commonLabelParams(cellViewData.titleLabel, {text = taskData.name, fontSize = 22, color = '#5c5c5c', ap = display.LEFT_CENTER, reqW = 280})
    local descr = string.gsub(taskData.descr, '_target_num_', tostring(taskData.targetNum))
    display.commonLabelParams(cellViewData.descr, {text = descr, fontSize = 20, color = '#5c5c5c', w = 440})
    local progress = checkint(taskData.progress)
    local target = checkint(taskData.targetNum)
    display.commonLabelParams(cellViewData.progressLabel, {text = string.format('(%d/%d)', math.min(progress, target), target)})
    cellViewData.titleLabel:setColor(ccc3FromInt('#ffffff'))
    cellViewData.descr:setColor(ccc3FromInt('#906866'))
    -- 刷新奖励
    cellViewData.rewardsLayout:removeAllChildren()
    local params = {parent = cellViewData.rewardsLayout, midPointX = cellViewData.rewardsLayout:getContentSize().width / 2, midPointY = cellViewData.rewardsLayout:getContentSize().height / 2, maxCol= 3, scale = 0.7, rewards = taskData.rewards, hideCustomizeLabel = true}
    CommonUtils.createPropList(params)
    if taskData.hasDrawn then
        -- 奖励已领取
        cellViewData.cellBg:setTexture(RES_DICT.TASK_CELL_BG_F)
        cellViewData.button:setNormalImage(RES_DICT.COMMON_BTN_F)
        cellViewData.button:setSelectedImage(RES_DICT.COMMON_BTN_F)
        cellViewData.progressLabel:setVisible(false)
        cellViewData.titleBg:setTexture(RES_DICT.TAKS_CELL_TITLE_BG_F)
        cellViewData.titleLabel:setColor(ccc3FromInt('#9c9291'))
        cellViewData.descr:setColor(ccc3FromInt('#9c9291'))
        display.commonLabelParams(cellViewData.button, {text = __('已完成'), fontSize = 24, color = '#ffffff', font = TTF_GAME_FONT, ttf = true})
        cellViewData.button:setEnabled(false)
        return 
    end
    if progress >= target then
        -- 奖励可领取
        cellViewData.cellBg:setTexture(RES_DICT.TASK_CELL_BG_S)
        cellViewData.button:setNormalImage(RES_DICT.COMMON_BTN_N)
        cellViewData.button:setSelectedImage(RES_DICT.COMMON_BTN_N)
        cellViewData.progressLabel:setVisible(true)
        cellViewData.titleBg:setTexture(RES_DICT.TAKS_CELL_TITLE_BG_S)
        display.commonLabelParams(cellViewData.button, fontWithColor(14, {text = __('领取')}))
        cellViewData.button:setEnabled(true)
        return 
    end
    -- 奖励不可领取
    cellViewData.cellBg:setTexture(RES_DICT.TASK_CELL_BG_N)

    -- local MODULE_TO_DATA = CommonUtils.GetTaskJumpModuleConfig()
    -- if MODULE_TO_DATA[tostring(taskData.taskType)] then
    --     cellViewData.button:setNormalImage(RES_DICT.COMMON_BTN_W)
    --     cellViewData.button:setSelectedImage(RES_DICT.COMMON_BTN_W)
    --     display.commonLabelParams(cellViewData.button, fontWithColor(14, {text = __('前往')}))
    --     cellViewData.button:setEnabled(true)
    -- else
        cellViewData.button:setNormalImage(RES_DICT.COMMON_BTN_D)
        cellViewData.button:setSelectedImage(RES_DICT.COMMON_BTN_D)
        display.commonLabelParams(cellViewData.button, fontWithColor(14, {text = __('未完成')}))
        cellViewData.button:setEnabled(false)
    -- end
    cellViewData.progressLabel:setVisible(true)
    cellViewData.titleBg:setTexture(RES_DICT.TAKS_CELL_TITLE_BG_N)
end
--[[
获取viewData
--]]
function CardAlbumTaskView:GetViewData()
    return self.viewData
end
return CardAlbumTaskView