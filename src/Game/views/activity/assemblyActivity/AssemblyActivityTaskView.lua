--[[
 * author : liuzhipeng
 * descpt : 活动 组合活动 循环任务View
--]]
local AssemblyActivityTaskView = class('AssemblyActivityTaskView', function ()
    local node = CLayout:create(display.size)
    node.name = 'activity.assemblyActivity.AssemblyActivityTaskView'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    BG                   = _res('ui/common/common_bg_13.png'),
    TITLE_BG             = _res('ui/common/common_bg_title_2.png'),
    LIST_BG              = _res('ui/common/common_bg_goods.png'),
    COMMON_BTN_N         = _res('ui/common/common_btn_orange.png'), 
    COMMON_BTN_W         = _res('ui/common/common_btn_white_default.png'), 
    COMMON_BTN_F         = _res('ui/common/activity_mifan_by_ico.png'),
    COMMON_BTN_D         = _res('ui/common/common_btn_orange_disable.png'),
    TASK_CELL_BG_N       = _res('ui/home/activity/assemblyActivity/task/common_bg_list.png'),
    TASK_CELL_BG_S       = _res('ui/home/activity/assemblyActivity/task/common_bg_list_vip.png'),
    TAKS_CELL_TITLE_BG_N = _res('ui/home/task/task_bg_title.png'),
    TAKS_CELL_TITLE_BG_S = _res('ui/home/task/task_bg_title_vip.png'),


}
local CreateListCell = nil 

function AssemblyActivityTaskView:ctor( ... )
    self:InitUI()
end
--[[
init ui
--]]
function AssemblyActivityTaskView:InitUI()
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
        local titleBg = display.newButton(size.width / 2 + 2, size.height - 30, {n = RES_DICT.TITLE_BG, enable = false})
        view:addChild(titleBg, 1)
        display.commonLabelParams(titleBg, {text = __('任务'), fontSize = 22, color = '#ffffff'})
        -- 任务列表
        local gridViewSize = cc.size(980, 550)
        local taskGridViewBg = display.newImageView(RES_DICT.LIST_BG, size.width / 2, size.height / 2 - 18, {size = gridViewSize, scale9 = true})
        view:addChild(taskGridViewBg, 3)
        local taskGridView = display.newGridView(size.width / 2, size.height / 2 - 18, {cols = 1, size = gridViewSize, csize = cc.size(gridViewSize.width, 126)})
        taskGridView:setCellCreateHandler(CreateListCell)
        view:addChild(taskGridView, 5)
        
    
        return {
            view                = view,
            taskGridView        = taskGridView,
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
function AssemblyActivityTaskView:EnterAction(  )
    local viewData = self:GetViewData()
    viewData.view:setOpacity(255 * 0.3)
    viewData.view:runAction(
        cc.FadeIn:create(0.2)
    )
end
--[[
关闭动画
--]]
function AssemblyActivityTaskView:CloseAction()
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
    local titleBg = display.newImageView(RES_DICT.TAKS_CELL_TITLE_BG_N, 6, size.height - 27, {ap = display.LEFT_CENTER})
    view:addChild(titleBg, 3)
    local titleLabel = display.newLabel(20, size.height - 27, {text = '', fontSize = 22, color = '#5c5c5c', ap = display.LEFT_CENTER})
    view:addChild(titleLabel, 5)
    -- 任务描述
    local descr = display.newLabel(20, 75, {ap = display.LEFT_TOP, text = '', fontSize = 22, color = '#5c5c5c'})
    view:addChild(descr, 5)
    -- 按钮
    local button = display.newButton(size.width - 90, size.height / 2, {n = RES_DICT.COMMON_BTN_N})
    view:addChild(button, 1)
    display.commonLabelParams(button, fontWithColor(14, {text = __('领取')}))
    -- 进度
    local progressLabel = display.newLabel(size.width - 90, 22, {text = '', fontSize = 22, color = '#5c5c5c'})
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
function AssemblyActivityTaskView:RefreshTaskState( cellViewData, taskData )
    display.commonLabelParams(cellViewData.titleLabel, {text = taskData.name, fontSize = 22, color = '#5c5c5c', ap = display.LEFT_CENTER, reqW = 280})
    local descr = string.gsub(taskData.descr, '_target_num_', tostring(taskData.target))
    display.commonLabelParams(cellViewData.descr, {text = descr, fontSize = 20, color = '#5c5c5c', w = 440})
    local progress = checkint(taskData.progress)
    local target = checkint(taskData.target)
    display.commonLabelParams(cellViewData.progressLabel, {text = string.format('(%d/%d)', math.min(progress, target), target)})
    cellViewData.titleLabel:setColor(ccc3FromInt('#76553b'))
    -- 刷新奖励
    cellViewData.rewardsLayout:removeAllChildren()
    local params = {parent = cellViewData.rewardsLayout, midPointX = cellViewData.rewardsLayout:getContentSize().width / 2, midPointY = cellViewData.rewardsLayout:getContentSize().height / 2, maxCol= 3, scale = 0.7, rewards = taskData.rewards, hideCustomizeLabel = true}
    CommonUtils.createPropList(params)
    if taskData.hasDrawn then
        -- 奖励已领取
        cellViewData.cellBg:setTexture(RES_DICT.TASK_CELL_BG_N)
        cellViewData.button:setNormalImage(RES_DICT.COMMON_BTN_F)
        cellViewData.button:setSelectedImage(RES_DICT.COMMON_BTN_F)
        cellViewData.progressLabel:setVisible(false)
        cellViewData.titleBg:setTexture(RES_DICT.TAKS_CELL_TITLE_BG_N)
        cellViewData.titleLabel:setColor(ccc3FromInt('#76553b'))
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
        cellViewData.titleLabel:setColor(ccc3FromInt('#d23d3d'))
        display.commonLabelParams(cellViewData.button, fontWithColor(14, {text = __('领取')}))
        cellViewData.button:setEnabled(true)
        return 
    end
    -- 奖励不可领取
    cellViewData.cellBg:setTexture(RES_DICT.TASK_CELL_BG_N)

    local MODULE_TO_DATA = CommonUtils.GetTaskJumpModuleConfig()
    if MODULE_TO_DATA[tostring(taskData.taskType)] then
        cellViewData.button:setNormalImage(RES_DICT.COMMON_BTN_W)
        cellViewData.button:setSelectedImage(RES_DICT.COMMON_BTN_W)
        display.commonLabelParams(cellViewData.button, fontWithColor(14, {text = __('前往')}))
        cellViewData.button:setEnabled(true)
    else
        cellViewData.button:setNormalImage(RES_DICT.COMMON_BTN_D)
        cellViewData.button:setSelectedImage(RES_DICT.COMMON_BTN_D)
        display.commonLabelParams(cellViewData.button, fontWithColor(14, {text = __('未完成')}))
        cellViewData.button:setEnabled(false)
    end
    cellViewData.progressLabel:setVisible(true)
    cellViewData.titleBg:setTexture(RES_DICT.TAKS_CELL_TITLE_BG_N)
    cellViewData.titleLabel:setColor(ccc3FromInt('#76553b')) 
end
--[[
获取viewData
--]]
function AssemblyActivityTaskView:GetViewData()
    return self.viewData
end
return AssemblyActivityTaskView