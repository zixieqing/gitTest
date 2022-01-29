--[[
 * author : panmeng
 * descpt : 皮肤收集 - 收集任务
]]
local SkinCollectionTaskView = class('SkinCollectionTaskView', function()
    return ui.layer({name = 'Game.views.collection.skinCollection.SkinCollectionTaskView', enableEvent = true})
end)

local RES_DICT = {
    VIEW_FRAME          = _res("ui/home/story/task_bg.png"),
    PUZ_PROGRESS_IMG    = _res('ui/collection/skinCollection/allround_bg_bar_active.png'),
    PUZ_PROGRESS_BG_IMG = _res('ui/collection/skinCollection/allround_bg_bar_grey.png'),
    TITLE_BG            = _res('ui/collection/skinCollection/allround_label_path_name.png'),
    TITLE_ICON          = _res('ui/collection/skinCollection/vip_main_btn_customer.png'),
    COMMON_BTN          = _res('ui/common/common_btn_orange.png'),
    DISABLE_BTN         = _res("ui/common/common_btn_orange_disable.png"),
    COMPLETE_IMG        = _res('ui/collection/skinCollection/allround_ico_completed.png'),
    CELL_BG             = _res('ui/collection/skinCollection/allround_bg_list_under.png'),
    BG_UP               = _res('ui/collection/skinCollection/allround_bg_book_cover_up.png'),
    BG_DOWN             = _res('ui/collection/skinCollection/allround_bg_book_cover_down.png'),
    CLOSE_BG_BAR        = _res('ui/common/common_bg_close.png'),
}


function SkinCollectionTaskView:ctor(args)
    -- create view
    self.viewData_ = SkinCollectionTaskView.CreateView()
    self:addChild(self:getViewData().view)

    self:getViewData().taskTableView:setCellCreateHandler(SkinCollectionTaskView.CreateCell)
end


function SkinCollectionTaskView:getViewData()
    return self.viewData_
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function SkinCollectionTaskView.CreateView()
    local view = ui.layer()
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- black / block layer
    local backGroundGroup = view:addList({
        ui.layer({color = cc.c4b(0,0,0,150)}),
        ui.layer({color = cc.r4b(0), enable = true}),
    })

    ------------------------------------------------- [center]
    local centerLayer = ui.layer()
    view:add(centerLayer)

    -- view frame
    local viewFrameNode = ui.layer({p = cpos, bg = RES_DICT.VIEW_FRAME, ap = ui.cc, enable = true})
    local viewFrameSize = viewFrameNode:getContentSize()
    centerLayer:add(viewFrameNode)
    

    -- taskTableView
    local taskTableView = ui.tableView({size = cc.resize(viewFrameSize, -100, -70), dir = display.SDIR_V, csizeH = 140})
    viewFrameNode:addList(taskTableView):alignTo(nil, ui.cc)
    viewFrameNode:addList(ui.image({img = RES_DICT.BG_UP})):alignTo(nil, ui.ct)
    viewFrameNode:addList(ui.image({img = RES_DICT.BG_DOWN})):alignTo(nil, ui.cb, {offsetY = -2})


    -- title bar
    local title = ui.title({img = RES_DICT.TITLE_BG, scale9 = true}):updateLabel({fnt = FONT.D20, fontSize = 24, outline = "#5e0e0e", text = __('收集奖励'), paddingW = 20, safeW = 245, ap = ui.rc})
    viewFrameNode:addList(title):alignTo(nil, ui.lt, {offsetY = 15, offsetX = 40})
    viewFrameNode:addList(ui.image({img = RES_DICT.TITLE_ICON})):alignTo(nil,  ui.lt, {offsetY = 30, offsetX = -30})

    local tipText = ui.title({img = RES_DICT.CLOSE_BG_BAR}):updateLabel({text = __("点击空白处关闭"), fontSize = 18})
    viewFrameNode:addList(tipText):alignTo(nil, ui.cb, {offsetY = -20})

    return {
        view          = view,
        blackLayer    = backGroundGroup[1],
        blockLayer    = backGroundGroup[2],
        --            = top
        --            = center
        taskTableView = taskTableView,
    }
end


function SkinCollectionTaskView.CreateCell(cellParent)
    local view = cellParent

    local layer = ui.layer({bg = RES_DICT.CELL_BG})
    view:addList(layer):alignTo(nil, ui.cc)

    ------------------------------------- left
    local leftGroup = layer:addList({
        ui.label({ap = ui.lt, w = 320, fontSize = 20, color = "#906866"}),
        ui.pBar({mt = 20, img = RES_DICT.PUZ_PROGRESS_IMG, bg = RES_DICT.PUZ_PROGRESS_BG_IMG, value = 0, ap = ui.lb}),
    })
    ui.flowLayout(cc.rep(cc.sizep(layer, ui.lc), 60, 0), leftGroup, {type = ui.flowV, ap = ui.lc, gapH = 40})

    local progressNum = ui.label({fontSize = 20})
    layer:addList(progressNum):alignTo(leftGroup[2], ui.cc)

    ------------------------------------- center
    local centerGroup = layer:addList({
        ui.label({text = __("奖励:"), fontSize = 20, color = "#9b4848"}),
        ui.layer({size = cc.size(240, 80)})
    })
    ui.flowLayout(cc.sizep(layer, ui.cc), centerGroup, {type = ui.flowV, ap = ui.lc, gapH = 5})

    local rewardLayer = centerGroup[2]
    local rewardNodes = {}
    for rewardIndex = 1, 3 do
        local goodNode = ui.goodsNode({scale = 0.7, defaultCB = true, showAmount = true})
        rewardLayer:add(goodNode)
        table.insert(rewardNodes, goodNode)
    end
    ui.flowLayout(cc.sizep(rewardLayer, ui.lc), rewardNodes, {type = ui.flowH, ap = ui.lc, gapW = 5})

    -------------------------------------- right
    local receiveBtn = ui.button({n = RES_DICT.COMMON_BTN, d = RES_DICT.DISABLE_BTN, ap = ui.rc, scale9 = true, maxWidth = 50}):updateLabel({fnt = FONT.D20, fontSize = 24, outline = "#7b482f", safeW = 80, text = __("领取"), paddingW = 20})
    layer:addList(receiveBtn):alignTo(nil, ui.rc, {offsetX = -30})


    ------------------------------------------ grey layer
    local greyLayer = ui.layer({size = cc.resize(layer:getContentSize(), -4, -14), color = cc.c4b(0,0,0,120)})
    layer:addList(greyLayer):alignTo(nil, ui.cc, {offsetX = -2, offsetY = -2})

    local  completeTitle = ui.title({img = RES_DICT.COMPLETE_IMG}):updateLabel({text = __("已完成！"), fnt = FONT.D20, fontSize = 22, outline = "#9d3b3b", ap = ui.ct, offset = cc.p(10, -20)})
    local offsetX = math.min(completeTitle:getLabel():getContentSize().width - completeTitle:getContentSize().width, 0)
    greyLayer:addList(completeTitle):alignTo(nil, ui.rc, {offsetX = offsetX - 20})

    return {
        view        = view,
        layer       = layer,
        receiveBtn  = receiveBtn,
        rewardNodes = rewardNodes,
        titleLabel  = leftGroup[1],
        progress    = leftGroup[2],
        greyLayer   = greyLayer,
        progressNum = progressNum,
    }
end

function SkinCollectionTaskView:updateTaskCell(cellIndex, cellViewData, taskData)
    local taskConf = CONF.CARD.SKIN_COLL_TASK:GetValue(checkint(taskData.taskId))

    ---      update receive state
    cellViewData.greyLayer:setVisible(taskData.isFinish)
    cellViewData.receiveBtn:setVisible(not taskData.isFinish)
    
    ----     check is can receive
    cellViewData.receiveBtn:setEnabled(checkbool(taskData.canGet))

    --   update progress
    local currentNum = taskData.currentNum or taskConf.targetNum
    cellViewData.progressNum:setString(tostring(currentNum) .. " / " .. tostring(taskConf.targetNum))

    local progress = math.floor(checkint(taskData.currentNum) / checkint(taskConf.targetNum) * 100)
    cellViewData.progress:setValue(progress)

    --   update info
    cellViewData.titleLabel:setString(string.fmt(tostring(taskConf.name), {_target_num_ = tostring(taskConf.targetNum)}))

    for rewardIndex = 1, 3 do
        local rewardConf = taskConf.rewards[rewardIndex]
        local rewardNode = cellViewData.rewardNodes[rewardIndex]

        rewardNode:setVisible(rewardConf ~= nil)
        if rewardConf then
            rewardNode:RefreshSelf(rewardConf)
        end
    end

    cellViewData.receiveBtn:setTag(cellIndex)
end

return SkinCollectionTaskView
