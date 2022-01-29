local CommonDialog = require('common.CommonDialog')
--- @class Anniversary19ExploreTaskView
local Anniversary19ExploreTaskView = class('Anniversary19ExploreTaskView', CommonDialog)

local display = display

local RES_DICT = {
    -- WONDERLAND_EXPLORE_MAIN_BOSSTIP_BAR_ACTIVE = app.anniversary2019Mgr:GetResPath('ui/anniversary19/exploreMain/wonderland_explore_main_bosstip_bar_active.png'),
    -- WONDERLAND_EXPLORE_MAIN_BOSSTIP_BAR_GREY   = app.anniversary2019Mgr:GetResPath('ui/anniversary19/exploreMain/wonderland_explore_main_bosstip_bar_grey.png'),
    WONDERLAND_EXPLORE_TASK_BG_CARD_COMPLETED  = app.anniversary2019Mgr:GetResPath('ui/anniversary19/exploreMain/wonderland_explore_task_bg_card_completed.png'),
    WONDERLAND_EXPLORE_TASK_DOT_DEFAULT        = app.anniversary2019Mgr:GetResPath('ui/anniversary19/exploreMain/wonderland_explore_task_dot_default.png'),
    WONDERLAND_EXPLORE_TASK_DOT_COMPLETED      = app.anniversary2019Mgr:GetResPath('ui/anniversary19/exploreMain/wonderland_explore_task_dot_completed.png'),

    WONDERLAND_EXPLORE_MAIN_BG_ENTRANCE        = app.anniversary2019Mgr:GetResPath('ui/anniversary19/exploreMain/wonderland_explore_main_bg_entrance.png'),
    WONDERLAND_EXPLORE_TASK_BG_CARD_DEFAULT    = app.anniversary2019Mgr:GetResPath('ui/anniversary19/exploreMain/wonderland_explore_task_bg_card_default.png'),
    WONDERLAND_EXPLORE_TASK_BG_REWARD          = app.anniversary2019Mgr:GetResPath('ui/anniversary19/exploreMain/wonderland_explore_task_bg_reward.png'),
    WONDERLAND_EXPLORE_TASK_ICO_HOST           = app.anniversary2019Mgr:GetResPath('ui/anniversary19/exploreMain/wonderland_explore_task_ico_host.png'),
    WONDERLAND_EXPLORE_TASK_LINE_CARD          = app.anniversary2019Mgr:GetResPath('ui/anniversary19/exploreMain/wonderland_explore_task_line_card.png'),
    WONDERLAND_EXPLORE_TASK_LINE_REWARD        = app.anniversary2019Mgr:GetResPath('ui/anniversary19/exploreMain/wonderland_explore_task_line_reward.png'),
    ANNI_REWARDS_LABEL_CARD_PREVIEW            = app.anniversary2019Mgr:GetResPath('ui/anniversary/rewardPreview/anni_rewards_label_card_preview.png'),
    COMMON_BG_4                                = app.anniversary2019Mgr:GetResPath('ui/common/common_bg_4.png'),
    COMMON_BTN                                 = app.anniversary2019Mgr:GetResPath('ui/common/common_btn_orange.png'),
    COMMON_BTN_DISABLE                         = app.anniversary2019Mgr:GetResPath('ui/common/common_btn_orange_disable.png'),
    RAID_ROOM_ICO_READY                        = app.anniversary2019Mgr:GetResPath('ui/common/raid_room_ico_ready.png'),
}

local CreateView = nil
local CreateCell = nil
local CreateGoodNode = nil

function Anniversary19ExploreTaskView:InitialUI( )
    self.costText = string.split(__('消耗 |_cost_||_icon_|'), '|')

    xTry(function ( )
        self.viewData = CreateView()
        self:InitView()
	end, __G__TRACKBACK__)
end

function Anniversary19ExploreTaskView:InitView()
end

---UpdateRewardLayer
---更新奖励层
---@param viewData table 视图数据
---@param rewards table  奖励数据
function Anniversary19ExploreTaskView:UpdateRewardLayer(viewData, rewards)
    local rewardLayer = viewData.rewardLayer
    local size = rewardLayer:getContentSize()
    local middleY = size.height * 0.5
    for index, value in ipairs(rewards) do
        local goodNode = CreateGoodNode(value)
        display.commonUIParams(goodNode, {ap = display.LEFT_CENTER, po = cc.p((index - 1) * 90, middleY)})
        rewardLayer:addChild(goodNode)
    end
end

---UpdateCardPreviewBtn
---更新卡牌预览按钮
---@param viewData table 视图数据
---@param confId number     卡牌配表id
function Anniversary19ExploreTaskView:UpdateCardPreviewBtn(viewData, confId)
    viewData.cardPreviewBtn:RefreshUI({confId = confId})
end


---UpdateDrawBtn
---更新领取按钮
---@param viewData table 视图数据
---@param drawState number 1 不可领取 2 可领取 3 已领取
function Anniversary19ExploreTaskView:UpdateDrawBtn(viewData, drawState)
    local drawBtn = viewData.drawBtn
    drawBtn:RefreshUI({drawState = drawState})
end

function Anniversary19ExploreTaskView:UpdateTableView(viewData, datas)
    local tableView = viewData.tableView
    local count = table.nums(datas)
    tableView:setCountOfCell(count)
    tableView:setBounceable(count > 3)
    tableView:reloadData()
end

----------------------------------------------
--- 更新 cell

function Anniversary19ExploreTaskView:UpdateCell(viewData, data)
    local currentLevel           = data.currentLevel
    local maxLevel               = data.maxLevel
    local isCompleteConsignation = data.isCompleteConsignation
    local exploreModuleId        = data.exploreModuleId
    
    self:UpdateProgressLayer(viewData, currentLevel + 1, maxLevel)

    viewData.bg:setTexture(isCompleteConsignation and RES_DICT.WONDERLAND_EXPLORE_TASK_BG_CARD_COMPLETED or RES_DICT.WONDERLAND_EXPLORE_TASK_BG_CARD_DEFAULT)
    viewData.submitLayer:setVisible(not isCompleteConsignation)
    viewData.completeSubmitLayer:setVisible(isCompleteConsignation)
    
    local consignationConf = CommonUtils.GetConfig('anniversary2', 'consignation', exploreModuleId) or {}
    if isCompleteConsignation then
        self:UpdateCompleteSubmitLayer(viewData, consignationConf[tostring(currentLevel)] or {})
    else
        self:UpdateSubmitLayer(viewData, consignationConf[tostring(currentLevel + 1)] or {})
    end
end

---UpdateProgressLayer
---更新委托任务进度
---@param viewData table 视图数据
---@param currentLevel number 当前委托等级
---@param maxLevel number 最大委托等级
function Anniversary19ExploreTaskView:UpdateProgressLayer(viewData, currentLevel, maxLevel)
    -- 更新委托任务进度
    local progressLayer = viewData.progressLayer
    local progressNodes = viewData.progressNodes
    if next(progressNodes) == nil then
        local middleY = progressLayer:getContentSize().height * 0.5
        for i = 1, maxLevel do
            local imgPath = i < currentLevel and RES_DICT.WONDERLAND_EXPLORE_TASK_DOT_COMPLETED or RES_DICT.WONDERLAND_EXPLORE_TASK_DOT_DEFAULT
            local img = display.newNSprite(imgPath, (i - 1) * 18, middleY, {ap = display.LEFT_CENTER})
            progressLayer:addChild(img)
            table.insert(progressNodes, img)
        end
    else
        for i = 1, currentLevel - 1 do
            progressNodes[i]:setTexture(RES_DICT.WONDERLAND_EXPLORE_TASK_DOT_COMPLETED)
        end
    end
end

---UpdateSubmitLayer
---更新交纳界面
---@param viewData table 视图数据
---@param conf table     委托任务配表数据
function Anniversary19ExploreTaskView:UpdateSubmitLayer(viewData, conf)

    -- 更新消耗道具
    local consumeGoodsIcon = viewData.consumeGoodsIcon
    local consumeNumLabel  = viewData.consumeNumLabel
    local submitBtn        = viewData.submitBtn
    local descLabel        = viewData.descLabel
    local consume          = conf.consume or {}
    local consumeData      = consume[1]

    if consumeData then
        local goodsId = consumeData.goodsId
        local num = consumeData.num
        consumeGoodsIcon:setTexture(CommonUtils.GetGoodsIconPathById(goodsId))
        consumeNumLabel:setString(num)

        local ownNum = app.gameMgr:GetAmountByGoodId(goodsId)
        local isCanSubmit = ownNum >= num
        if isCanSubmit then
            local costText = {}
            for k,text in ipairs(self.costText) do
                if '_cost_' == text then
                    table.insert(costText, {text = num, fontSize = 20, color = '#a56c44'})
                elseif '_icon_' == text then
                    table.insert(costText, {img = CommonUtils.GetGoodsIconPathById(goodsId), scale = 0.2})
                elseif string.len(text) > 0 then
                    table.insert(costText, {text = text, fontSize = 20, color = '#a56c44'})
                end
            end
            display.reloadRichLabel(descLabel, {width = 240 , c = costText})
        else
            display.reloadRichLabel(descLabel, {width = 240 ,  c = {
                {fontSize = 20, color = '#f0563d', text = app.anniversary2019Mgr:GetPoText(__('材料不足'))}
            }})

        end

        local img = isCanSubmit and RES_DICT.COMMON_BTN or RES_DICT.COMMON_BTN_DISABLE
        submitBtn:setNormalImage(img)
        submitBtn:setSelectedImage(img)
    end

    -- 更新奖励
    local goodsLayer     = viewData.goodsLayer
    local goodsNodes     = viewData.goodsNodes
    local rewards        = conf.rewards or {}
    local rewardCount    = #rewards
    local maxCount       = math.max(rewardCount, #goodsNodes)
    local goodsLayerSize = goodsLayer:getContentSize()
    local middleX        = goodsLayerSize.width * 0.5
    local middleY        = goodsLayerSize.height * 0.5
    for i = 1, maxCount do
        local reward = rewards[i]
        local goodsNode = goodsNodes[i]
        if reward then
            if goodsNode then
                goodsNode:setVisible(true)
                goodsNode:RefreshSelf(reward)
            else
                goodsNode = CreateGoodNode(reward)
                goodsLayer:addChild(goodsNode)
                table.insert(goodsNodes, goodsNode)
            end
            local pos = CommonUtils.getGoodPos({index = i, goodNodeSize = goodsNode:getContentSize(), scale = goodsNode:getScale(), midPointX = middleX, midPointY = middleY, col = rewardCount, maxCol = 3, goodGap = 10})
            display.commonUIParams(goodsNode, {po = pos, ap = display.CENTER})
        elseif goodsNode then
            goodsNode:setVisible(false)
        end
    end

end

---UpdateCompleteSubmitLayer
---更新全部交纳界面
---@param viewData table 视图数据
---@param conf table     委托任务配表数据
function Anniversary19ExploreTaskView:UpdateCompleteSubmitLayer(viewData, conf)
    local goodsIcon        = viewData.goodsIcon
    local completeTipLabel = viewData.completeTipLabel

    local consume          = conf.consume or {}
    local consumeData      = consume[1]
    if consumeData then
        local goodsId = consumeData.goodsId
        goodsIcon:setTexture(CommonUtils.GetGoodsIconPathById(consumeData.goodsId))

        local goodsConf = CommonUtils.GetConfig('goods', 'goods', goodsId) or {}
        display.commonLabelParams(completeTipLabel, {text = string.format(app.anniversary2019Mgr:GetPoText(__('交纳%s的委托已全部完成！')), tostring(goodsConf.name))})
    end

end

--- 更新 cell
----------------------------------------------

CreateView = function ()
    local size = cc.size(1020, 600)
    local view = display.newLayer(0, 0, {size = size})

    local middleX, middleY = size.width * 0.5, size.height * 0.5

    local bg = display.newNSprite(RES_DICT.COMMON_BG_4, 0, 0, { scale9 = true, size = size, ap = cc.p(0, 0)})
    view:addChild(bg)

    ----------------------------------------------
    --- 顶部奖励相关UI
    -- 顶部奖励背景
    local rewardBg = display.newNSprite(RES_DICT.WONDERLAND_EXPLORE_TASK_BG_REWARD, middleX, size.height - 170, {ap = display.CENTER_BOTTOM})
    view:addChild(rewardBg)

    -- 顶部奖励视图
    local rewardUISize = cc.size(size.width, 170)
    local rewardUI = display.newLayer(middleX, size.height, {ap = display.CENTER_TOP, size = rewardUISize})
    view:addChild(rewardUI)

    -- 卡牌预览按钮
    local cardPreviewBtn = require("common.CardPreviewEntranceNode").new()
    display.commonUIParams(cardPreviewBtn, {ap = display.CENTER, po = cc.p(338, 94)})
    rewardUI:addChild(cardPreviewBtn, 5)

    local cardPreviewTip = display.newImageView(RES_DICT.ANNI_REWARDS_LABEL_CARD_PREVIEW, -155, 8, {ap = display.RIGHT_CENTER})
    cardPreviewTip:setScaleX(-1)
    cardPreviewBtn:addChild(cardPreviewTip)

    cardPreviewBtn:addChild(display.newLabel(105, 8, fontWithColor(14, {ap = display.RIGHT_CENTER, text = app.anniversary2019Mgr:GetPoText(__('卡牌详情'))})))

    local rewardDrawTipLabel = display.newLabel(420, rewardUISize.height - 15,
            {fontSize = 22, color = '#3c7564', ap = display.LEFT_TOP, text = app.anniversary2019Mgr:GetPoText(__('完成所有剧本即可获得'))})
    rewardUI:addChild(rewardDrawTipLabel)

    local rewardSplitLine = display.newNSprite(RES_DICT.WONDERLAND_EXPLORE_TASK_LINE_REWARD, 400, rewardUISize.height - 42, {ap = display.LEFT_TOP})
    rewardUI:addChild(rewardSplitLine)

    -- 奖励层
    local rewardLayerSize = cc.size(330, 100)
    local rewardLayer = display.newLayer(410, rewardUISize.height - 48, {ap = display.LEFT_TOP, size = rewardLayerSize})
    rewardUI:addChild(rewardLayer)

    -- 领取按钮
    local btnParams = {
        ap = display.CENTER,
        scale9 = true, size = cc.size(123, 62),
        enable = true,
    }
    local drawBtn = require('common.CommonDrawButton').new({btnParams = btnParams})
    display.commonUIParams(drawBtn, {po = cc.p(rewardUISize.width - 114, rewardUISize.height * 0.5), ap = display.CENTER})
    rewardUI:addChild(drawBtn)

    --- 顶部奖励相关UI
    ----------------------------------------------

    ----------------------------------------------
    --- 探索任务UI
    local exploreContentUISize = cc.size(size.width, 422)
    local exploreContentUI = display.newLayer(middleX, 0, {ap = display.CENTER_BOTTOM, size = exploreContentUISize})
    view:addChild(exploreContentUI)
    
    local roleImg = display.newNSprite(RES_DICT.WONDERLAND_EXPLORE_TASK_ICO_HOST, -62, 0, {ap = display.LEFT_BOTTOM})
    exploreContentUI:addChild(roleImg)

    -- 探索任务列表
    local cellSize = cc.size(260, 380)
    local tableViewSize = cc.size(800, cellSize.height)
    local tableView = CTableView:create(tableViewSize)
    display.commonUIParams(tableView, {ap = display.LEFT_TOP, po = cc.p(200, exploreContentUISize.height)})
    -- tableView:setBackgroundColor(cc.c4b(23, 67, 128, 128))
    tableView:setSizeOfCell(cellSize)
    tableView:setDirection(eScrollViewDirectionHorizontal)
    exploreContentUI:addChild(tableView)

    local tipLabel = display.newLabel(exploreContentUISize.width * 0.5, 24,
            {fontSize = 22, color = '#937045', ap = display.CENTER, text = app.anniversary2019Mgr:GetPoText(__('每一层梦境，你都会遇到意想不到的故事。'))})
    exploreContentUI:addChild(tipLabel)
    --- 探索任务UI
    ----------------------------------------------

    return {
        view           = view,
        cardPreviewBtn = cardPreviewBtn,
        drawBtn        = drawBtn,
        tableView      = tableView,
        rewardLayer    = rewardLayer,
    }

end

CreateCell = function (size)

    local middleX, middleY = size.width * 0.5, size.height * 0.5
    local cell = display.newLayer(0, 0, {size = size})

    local bg = display.newNSprite(RES_DICT.WONDERLAND_EXPLORE_TASK_BG_CARD_DEFAULT, middleX, middleY )
    cell:addChild(bg)

    local progressLayerSize = cc.size(160, 16)
    local progressLayer = display.newLayer(10, size.height - 16, {ap = display.LEFT_TOP, size = progressLayerSize})
    cell:addChild(progressLayer)

    ----------------------------------------------
    --- 交纳UI界面
    local submitLayerSize = cc.size(size.width, size.height - 16 - progressLayerSize.height)
    local submitLayerMiddleX = submitLayerSize.width * 0.5
    local submitLayer = display.newLayer(0, 0, {size = submitLayerSize})
    -- submitLayer:setVisible(false)
    cell:addChild(submitLayer)

    local submitLabel = display.newLabel(13, submitLayerSize.height - 45, {fontSize = 22, color = '#611e1f', ap = display.LEFT_BOTTOM, text = app.anniversary2019Mgr:GetPoText(__('交纳'))})
    submitLayer:addChild(submitLabel)

    local consumeGoodsIconScale = 0.4
    local consumeGoodsIcon = display.newNSprite(CommonUtils.GetGoodsIconPathById(880296), submitLayerSize.width - 10, submitLayerSize.height - 18, {ap = display.RIGHT_CENTER})
    consumeGoodsIcon:setScale(consumeGoodsIconScale)
    submitLayer:addChild(consumeGoodsIcon)

    -- 消耗数量
    local consumeNumLabel = CLabelBMFont:create(0, 'font/small/common_text_num.fnt')
    consumeNumLabel:setBMFontSize(24)
    display.commonUIParams(consumeNumLabel, {ap = display.RIGHT_BOTTOM, po = cc.p(consumeGoodsIcon:getPositionX() - consumeGoodsIcon:getContentSize().width * consumeGoodsIconScale, submitLayerSize.height - 47)})
    submitLayer:addChild(consumeNumLabel)

    local splitLine = display.newNSprite(RES_DICT.WONDERLAND_EXPLORE_TASK_LINE_CARD, submitLayerMiddleX, submitLayerSize.height - 54)
    submitLayer:addChild(splitLine)

    -- 可获得 标签
    local canGetLabel = display.newLabel(submitLayerMiddleX, submitLayerSize.height - 85,
            {fontSize = 22, color = '#611e1f', ap = display.CENTER, text = app.anniversary2019Mgr:GetPoText(__('可获得'))})
    submitLayer:addChild(canGetLabel)

    -- 道具层
    local goodsLayer = display.newLayer(submitLayerMiddleX, submitLayerSize.height * 0.5 + 26,
            {size = cc.size(submitLayerSize.width, 100), ap = display.CENTER})
    submitLayer:addChild(goodsLayer)

    -- 交纳按钮
    local submitBtn = display.newButton(submitLayerMiddleX, 80, {n = RES_DICT.COMMON_BTN, ap = display.CENTER})
    display.commonLabelParams(submitBtn, fontWithColor(14,{text = app.anniversary2019Mgr:GetPoText(__('交纳'))}))
    submitLayer:addChild(submitBtn)

    -- 交纳描述
    local descLabel = display.newRichLabel(submitLayerMiddleX, 35, {ap = display.CENTER})
    submitLayer:addChild(descLabel)

    --- 交纳UI界面
    ----------------------------------------------

    ----------------------------------------------
    --- 完成交纳UI界面
    local completeSubmitLayer = display.newLayer(0, 0, {size = submitLayerSize})
    completeSubmitLayer:setVisible(false)
    cell:addChild(completeSubmitLayer)

    -- 道具图标
    local goodsIcon = display.newNSprite(CommonUtils.GetGoodsIconPathById(880296), submitLayerMiddleX, submitLayerSize.height - 100, {ap = display.CENTER})
    completeSubmitLayer:addChild(goodsIcon)

    -- 对号图标
    local rightIcon = display.newNSprite(RES_DICT.RAID_ROOM_ICO_READY, 80, 130, {ap = display.CENTER_TOP})
    goodsIcon:addChild(rightIcon)

    -- 完成提示标签
    local completeTipLabel = display.newLabel(submitLayerMiddleX, 70,
        {fontSize = 22, color = '#ffffff', ap = display.CENTER, w = 205, hAlign = display.TAC})
    completeSubmitLayer:addChild(completeTipLabel)

    --- 完成交纳UI界面
    ----------------------------------------------

    local splitLine = display.newNSprite(RES_DICT.WONDERLAND_EXPLORE_TASK_LINE_CARD, middleX, 130)
    cell:addChild(splitLine)

    cell.viewData = {
        bg                  = bg,
        progressLayer       = progressLayer,
        submitLayer         = submitLayer,
        consumeGoodsIcon    = consumeGoodsIcon,
        consumeNumLabel     = consumeNumLabel,
        goodsLayer          = goodsLayer,
        goodsNodes          = {},
        submitBtn           = submitBtn,
        descLabel           = descLabel,
        completeSubmitLayer = completeSubmitLayer,
        goodsIcon           = goodsIcon,
        completeTipLabel    = completeTipLabel,
        progressNodes       = {},
    }

    return cell
end

CreateGoodNode = function (reward)
    local goodNode = require('common.GoodNode').new({id = reward.goodsId, amount = reward.num, showAmount = true, callBack = function (sender)
        app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
    end})
    goodNode:setScale(0.8)
    return goodNode
end

function Anniversary19ExploreTaskView:GetViewData()
    return self.viewData
end

function Anniversary19ExploreTaskView:CreateCell(size)
    return CreateCell(size)
end

function Anniversary19ExploreTaskView:CloseHandler()
    app:UnRegsitMediator(self.args.mediatorName)
end

return  Anniversary19ExploreTaskView