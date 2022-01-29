--[[
 * author : liuzhipeng
 * descpt : 活动 新手福利 任务View
--]]
local NoviceWelfareTaskView = class('NoviceWelfareTaskView', function ()
    local node = CLayout:create(cc.size(1150, 600))
    node.name = 'NoviceWelfareTaskView'
    node:enableNodeEvents()
    return node
end)
local RES_DICT = {
    TASK_ROLE_IMG              = _res('ui/home/activity/noviceWelfare/tast_role_bg.png'),
    POINT_ICON                 = _res('ui/home/activity/noviceWelfare/integral_icon.png'),
    POINT_PROGRESS_BAR         = _res('ui/home/activity/noviceWelfare/task_bar_orange.png'),
    POINT_PROGRESS_BAR_BG      = _res('ui/home/activity/noviceWelfare/task_bar_grey.png'),
    POINT_BG                   = _res('ui/home/activity/noviceWelfare/integral_total_bg.png'),
    DAY_BTN_N                  = _res('ui/home/activity/noviceWelfare/days_common_finish.png'),
    DAY_BTN_S                  = _res('ui/home/activity/noviceWelfare/days_common_selected.png'),
    DAY_BTN_D                  = _res('ui/home/activity/noviceWelfare/days_common_lock.png'),
    TICK                       = _res('ui/home/activity/noviceWelfare/days_common_finish_mark.png'),
    LOCK                       = _res('ui/common/common_ico_lock.png'),
    DAY_BTN_SPLIT_LINE         = _res('ui/home/activity/noviceWelfare/days_selection_line.png'),
    TASK_CELL_BG_N             = _res('ui/home/activity/noviceWelfare/anni_go_bg_head.png'),
    TASK_CELL_BG_S             = _res('ui/home/activity/noviceWelfare/anni_rewards_bg_head.png'),
    TASK_CELL_BG_D             = _res('ui/home/activity/noviceWelfare/anni_rewards_finish_bg.png'),
    COMMON_BTN_N               = _res('ui/common/common_btn_orange.png'), 
    COMMON_BTN_W               = _res('ui/common/common_btn_white_default.png'), 
    COMMON_BTN_F               = _res('ui/common/activity_mifan_by_ico.png'),
    COMMON_BTN_D               = _res('ui/common/common_btn_orange_disable.png'),
    COMMON_BTN_G               = _res('ui/common/common_btn_green.png'),
    TASK_SPLIT_LINE            = _res('ui/home/activity/noviceWelfare/days_crosswise_line.png'),
    REMIND_ICON                = _res('ui/common/common_hint_circle_red_ico.png'),
}
local CreateListCell = nil 
function NoviceWelfareTaskView:ctor( ... )
    self:InitUI()
end
--[[
init ui
--]]
function NoviceWelfareTaskView:InitUI()
    local function CreateView()
        local size = self:getContentSize()
        local view = CLayout:create(size)
        -- mask --
        local mask = display.newLayer(size.width/2 ,size.height/2 ,{ap = display.CENTER , size = size, enable = true, color = cc.c4b(0,0,0,0)})
        view:addChild(mask, -1)
        -- mask --
        -- 卡牌切图
        local roleImg = display.newImageView(RES_DICT.TASK_ROLE_IMG, 340, -22, {ap = display.RIGHT_BOTTOM})
        view:addChild(roleImg, 1)
        -- 卡牌预览按钮
        local cardPreviewBtn = require("common.CardPreviewEntranceNode").new({confId = 200001})
        display.commonUIParams(cardPreviewBtn, {ap = display.RIGHT_BOTTOM, po = cc.p(150, 10)})
        view:addChild(cardPreviewBtn, 5)
        cardPreviewBtn:addChild(display.newLabel(105, 8, fontWithColor(14, {ap = display.RIGHT_CENTER, text = __('卡牌详情')})))
        -- 点数进度
        local pointProgressBar = CProgressBar:create(RES_DICT.POINT_PROGRESS_BAR)
        pointProgressBar:setBackgroundImage(RES_DICT.POINT_PROGRESS_BAR_BG)
        pointProgressBar:setDirection(eProgressBarDirectionLeftToRight)
        pointProgressBar:setAnchorPoint(display.CENTER)
        pointProgressBar:setPosition(cc.p(size.width / 2 + 140, 520))
        view:addChild(pointProgressBar, 1)

        local pointIcon = display.newImageView(RES_DICT.POINT_ICON, 330, 530)
        view:addChild(pointIcon, 5)
        local pointBg = display.newImageView(RES_DICT.POINT_BG, 330, 492)
        view:addChild(pointBg, 5)
        local pointTitle = display.newLabel(pointBg:getContentSize().width / 2, pointBg:getContentSize().height / 2 + 8, {text = __("当前积分"), fontSize = 14, color = '#774837'})
        pointBg:addChild(pointTitle, 1)
        local pointLabel = display.newLabel(pointBg:getContentSize().width / 2, pointBg:getContentSize().height / 2 - 8, {text = '0', fontSize = 14, color = '#ff9215'})
        pointBg:addChild(pointLabel, 1)
        local pointRewardsLayout = CLayout:create(cc.size(833, 100))
        pointRewardsLayout:setPosition(cc.p(size.width / 2 + 140, 520))
        view:addChild(pointRewardsLayout, 5)
        
        -- 日期按钮
        local dayBtnList = {}
        for i = 1, 7 do
            local btn = display.newButton(350 + (i - 1) * 120, 434, {n = RES_DICT.DAY_BTN_N})
            btn:setTag(i)
            view:addChild(btn, 5)
            table.insert(dayBtnList, btn)
            local remindIcon = display.newImageView(RES_DICT.REMIND_ICON, 10, 60)
            remindIcon:setScale(0.6)
            remindIcon:setName('remindIcon')
            remindIcon:setVisible(false)
            btn:addChild(remindIcon, 5)
            local tickIcon = display.newImageView(RES_DICT.TICK, 105, 18)
            tickIcon:setName('tickIcon')
            tickIcon:setVisible(false)
            btn:addChild(tickIcon, 5)
            local lockIcon = display.newImageView(RES_DICT.LOCK, 105, 14)
            lockIcon:setName('lockIcon')
            lockIcon:setScale(0.6)
            lockIcon:setVisible(false)
            btn:addChild(lockIcon, 5)
            local title = display.newLabel(btn:getContentSize().width / 2, btn:getContentSize().height / 2, {text = string.fmt(__('第_num_天'), {['_num_'] = i}), color = '#bd8e4e', fontSize = 24})
            btn:addChild(title, 1)
            if i ~= 7 then
                local line = display.newImageView(RES_DICT.DAY_BTN_SPLIT_LINE, 410 + (i - 1) * 120, 434)
                view:addChild(line, 10)
            end
        end
        local splitLine = display.newImageView(RES_DICT.TASK_SPLIT_LINE, size.width / 2 + 130, 402)
        view:addChild(splitLine, 10)
        -- 任务列表
        local gridViewSize = cc.size(842, 394)
        local taskGridView = display.newGridView(size.width / 2 + 135, size.height / 2 - 98, {cols = 1, size = gridViewSize, csize = cc.size(gridViewSize.width, 118)})
        taskGridView:setCellCreateHandler(CreateListCell)
        view:addChild(taskGridView, 5)

        return {
            view                = view,
            dayBtnList          = dayBtnList,
            taskGridView        = taskGridView,
            pointProgressBar    = pointProgressBar,
            pointLabel          = pointLabel,
            pointRewardsLayout  = pointRewardsLayout,
            cardPreviewBtn      = cardPreviewBtn,
        }
    end

    xTry(function ( )
        self.viewData = CreateView( )
        self:addChild(self.viewData.view)
        self.viewData.view:setPosition(utils.getLocalCenter(self))
    end, __G__TRACKBACK__)
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
    local cellDrawMask = display.newImageView(RES_DICT.TASK_CELL_BG_D, size.width / 2, size.height / 2)
    view:addChild(cellDrawMask, 1)
    -- 任务描述
    local descr = display.newLabel(60, size.height / 2, {ap = display.LEFT_CENTER, text = '', fontSize = 22, color = '#5c5c5c', w = 280, reqH = 80})
    view:addChild(descr, 5)
    -- 按钮
    local button = display.newButton(size.width - 130, size.height / 2 + 5, {n = RES_DICT.COMMON_BTN_N})
    view:addChild(button, 1)
    display.commonLabelParams(button, fontWithColor(14, {text = __('领取')}))
    -- 价格label
    local priceLabel = display.newRichLabel(button:getContentSize().width / 2, button:getContentSize().height / 2)
    button:addChild(priceLabel, 5)
    -- 已完成label
    local finishLabel = display.newLabel(size.width - 130, size.height / 2, {text = __('已完成'), color = '#5c5c5c', fontSize = 20, font = TTF_GAME_FONT, ttf = true})
    view:addChild(finishLabel, 1)
    -- 进度
    local progressLabel = display.newLabel(size.width - 130, 22, {text = '', fontSize = 20, color = '#5c5c5c'})
    view:addChild(progressLabel, 1)
    -- 奖励layout
    local rewardsLayout = CLayout:create(cc.size(260, size.height))
    rewardsLayout:setPosition(size.width - 362, size.height / 2)
    view:addChild(rewardsLayout, 1)
    
    return {
        view              = view,
        cellBg            = cellBg,
        cellDrawMask      = cellDrawMask,
        descr             = descr,
        button            = button,
        progressLabel     = progressLabel,
        rewardsLayout     = rewardsLayout,
        finishLabel       = finishLabel,
        priceLabel        = priceLabel,
    }
end
--[[
刷新任务按钮状态
--]]
function NoviceWelfareTaskView:RefreshTaskState( cellViewData, taskData, today )
    cellViewData.descr:setString(taskData.descr)
    local progress = checkint(taskData.progress)
    local target = checkint(taskData.targetNum)
    local params = {parent = cellViewData.rewardsLayout, midPointX = cellViewData.rewardsLayout:getContentSize().width / 2, midPointY = cellViewData.rewardsLayout:getContentSize().height / 2, maxCol= 3, scale = 0.7, rewards = taskData.rewards, hideCustomizeLabel = true}
    CommonUtils.createPropList(params)
    display.commonLabelParams(cellViewData.progressLabel, {text = string.format('(%d/%d)', math.floor(progress, target), target)})
    if checkint(taskData.hasDrawn) == 1 then
        -- 奖励已领取
        cellViewData.cellBg:setTexture(RES_DICT.TASK_CELL_BG_N)
        cellViewData.cellDrawMask:setVisible(true)
        cellViewData.progressLabel:setVisible(false)
        cellViewData.button:setEnabled(false)
        cellViewData.button:setVisible(false)
        cellViewData.finishLabel:setVisible(true)
        return 
    end
    cellViewData.button:setVisible(true)
    cellViewData.priceLabel:setVisible(false)
    cellViewData.finishLabel:setVisible(false)
    cellViewData.cellDrawMask:setVisible(false)
    if checkint(taskData.isTimeLimit) == 1 and checkint(taskData.openDay) ~= today then
        -- 限定非当日
        cellViewData.cellBg:setTexture(RES_DICT.TASK_CELL_BG_N)
        cellViewData.button:setNormalImage(RES_DICT.COMMON_BTN_G)
        cellViewData.button:setSelectedImage(RES_DICT.COMMON_BTN_G)
        cellViewData.progressLabel:setVisible(false)
        display.commonLabelParams(cellViewData.button, fontWithColor(14, {text = ''}))
        cellViewData.button:setEnabled(true)
        -- 刷新重置价格
        cellViewData.priceLabel:setVisible(true)
        display.reloadRichLabel(cellViewData.priceLabel, { c= {
            fontWithColor('14', {text = taskData.skipGoodsNum}),
            img = { img = CommonUtils.GetGoodsIconPathById(taskData.skipGoodsId), scale = 0.2 }
        }})
        return 
    end
    if progress >= target then
        -- 奖励可领取
        cellViewData.cellBg:setTexture(RES_DICT.TASK_CELL_BG_S)
        cellViewData.button:setNormalImage(RES_DICT.COMMON_BTN_N)
        cellViewData.button:setSelectedImage(RES_DICT.COMMON_BTN_N)
        cellViewData.progressLabel:setVisible(true)
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
end
--[[
刷新日期页签状态
@params tasksData list 任务数据
@params today     int  今天的日期
--]]
function NoviceWelfareTaskView:RefreshTabState( tasksData, today )
    local viewData = self:GetViewData()
    for i, btn in ipairs(viewData.dayBtnList) do
        local tickIcon = btn:getChildByName('tickIcon')
        local lockIcon = btn:getChildByName('lockIcon')
        if i > today then
            btn:setNormalImage(RES_DICT.DAY_BTN_D)
            btn:setSelectedImage(RES_DICT.DAY_BTN_D)
            tickIcon:setVisible(false)
            lockIcon:setVisible(true)
        else
            btn:setNormalImage(RES_DICT.DAY_BTN_N)
            btn:setSelectedImage(RES_DICT.DAY_BTN_N)
            lockIcon:setVisible(false)
            -- 判断任务是否全部完成
            local showTick = true
            for _, v in ipairs(tasksData[i]) do
                if checkint(v.hasDrawn) ~= 1 then
                    showTick = false
                    break
                end
            end
            tickIcon:setVisible(showTick)
        end
    end
end
--[[
刷新日期页签选中状态
@params day int  日期
@params day bool 是否选中
--]]
function NoviceWelfareTaskView:RefreshTabSelectState( day, isSelected )
    local viewData = self:GetViewData()
    local img = nil
    if isSelected then
        img = RES_DICT.DAY_BTN_S
    else
        img = RES_DICT.DAY_BTN_N
    end
    viewData.dayBtnList[day]:setNormalImage(img)
    viewData.dayBtnList[day]:setSelectedImage(img)
end
--[[
刷新点数奖励进度条
@params pointRewards list 点数奖励数据
@params curPoint     int  当前点数 
--]]
function NoviceWelfareTaskView:RefreshPointProgressBar( pointRewards, curPoint )
    local viewData = self:GetViewData()
    -- 最大点数为最后一个奖励所需点数
    local maxPoint = checkint(pointRewards[#pointRewards].activePoint)
    local point = checkint(curPoint)
    viewData.pointLabel:setString(point)
    viewData.pointProgressBar:setMaxValue(maxPoint)
    viewData.pointProgressBar:setValue(point)
    -- 更新点数奖励 --
    viewData.pointRewardsLayout:removeAllChildren()
    local progressW = viewData.pointProgressBar:getContentSize().width
    for i, v in ipairs(pointRewards) do
        local posX = 50 + checkint(v.activePoint) / maxPoint * progressW
        local goodNode = require('common.GoodNode').new({ id = v.rewards[1].goodsId, amount = v.rewards[1].num, showAmount = true, callBack = function(sender)
            app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
        end})
        goodNode:setScale(0.6)
        goodNode:setPosition(cc.p(posX, 72))
        viewData.pointRewardsLayout:addChild(goodNode, 1)
        if point >= checkint(v.activePoint) then
            goodNode.icon:setColor(cc.c3b(255, 255, 255))
            goodNode.fragmentImg:setColor(cc.c3b(255, 255, 255))
        else
            goodNode.icon:setColor(cc.c3b(160, 160, 160))
            goodNode.fragmentImg:setColor(cc.c3b(160, 160, 160))
        end
        local pointLabel = display.newLabel(posX, 30, {text = v.activePoint, fontSize = 20, color = '#5b3c25'})
        viewData.pointRewardsLayout:addChild(pointLabel, 1)
    end
end
--[[
刷新卡牌预览按钮
@params goodsId int 卡牌碎片道具id
--]]
function NoviceWelfareTaskView:RefreshCardPreviewButton( goodsId )
    local viewData = self:GetViewData()
    viewData.cardPreviewBtn:RefreshUI({goodsId = goodsId})
end
--[[
刷新日期按钮小红点
@params tasksData list 任务数据
@params isLimit   bool 是否为限时任务
@params today     int  今天的日期
--]]
function NoviceWelfareTaskView:RefreshDayButtonRemindIcon( tasksData, isLimit, today )
    local viewData = self:GetViewData()
    for i, btn in ipairs(viewData.dayBtnList) do
        local remindIcon = btn:getChildByName('remindIcon')
        if i > today then
            -- 超过当天的不需要判断
            remindIcon:setVisible(false)
        else
            if isLimit and i ~= today then
                -- 限时任务除了当天外都不显示
                remindIcon:setVisible(false)
            else
                -- 其余情况需要判断
                remindIcon:setVisible(self:CheckTaskRemindIcon(tasksData[i]))
            end
        end
    end
end
--[[
根据任务信息判断是否需要显示小红点
--]]
function NoviceWelfareTaskView:CheckTaskRemindIcon( tasksData )
    local show = false
    for i, v in ipairs(tasksData) do
        if checkint(v.progress) >= checkint(v.targetNum) and checkint(v.hasDrawn) == 0 then
            show = true
            break
        end
    end
    return show
end
--[[
获取viewData
--]]
function NoviceWelfareTaskView:GetViewData()
    return self.viewData
end
return NoviceWelfareTaskView