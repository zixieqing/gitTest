--[[
新等级奖励view
--]]
local VIEW_SIZE = cc.size(1035, 637)
local ActivityNewLevelRewardView = class('ActivityNewLevelRewardView', function ()
    local node = CLayout:create(VIEW_SIZE)
    node.name = 'home.view.activity.levelReward.ActivityNewLevelRewardView'
    node:enableNodeEvents()
    return node
end)

local CreateView = nil

local RES_DIR = {
    BG              = _res('ui/home/activity/levelReward/level_reward_bg.png'),
    BG_ROLE         = _res('ui/home/activity/levelReward/level_reward_role.png'),
    TITLE           = _res('ui/home/activity/levelReward/level_reward_title_cn.png'),
    CARD_NAME       = _res('ui/home/activity/levelReward/level_reward_ur_cn.png'),
    LIST_BG         = _res('ui/common/common_bg_goods.png'),
    CLOCK_ICON      = _res('ui/common/new_welfare_ico_making_2.png'),

    BG_REWARD_BLACK = _res('ui/home/activity/levelReward/level_reward_frame_grey.jpg'),
    BG_REWARD       = _res('ui/home/activity/levelReward/level_reward_bg_1.jpg'),
    BTN_DISABLE     = _res('ui/common/common_btn_orange_disable.png'),
    BTN_ORANGE      = _res('ui/common/common_btn_orange.png'),
    BTN_GREEN       = _res('ui/common/common_btn_green.png'),
    BTN_GREY        = _res('ui/common/common_btn_grey.png'),
}

function ActivityNewLevelRewardView:ctor( ... )
    self.args = unpack({...})
    self:InitUI()
end
--[[
init ui
--]]
function ActivityNewLevelRewardView:InitUI()
    xTry(function ( )
        self.viewData_ = CreateView(VIEW_SIZE)
        self:addChild(self.viewData_.view)
	end, __G__TRACKBACK__)
    
end

function ActivityNewLevelRewardView:refreshUI(datas)
    local viewData = self:getViewData()
    local tableView = viewData.tableView
    local offset = tableView:getContentOffset()
    local cellsNum = #tableView:getCells()
    tableView:setCountOfCell(#datas)
    tableView:reloadData()
    if cellsNum ~= 0 then
        tableView:setContentOffset(offset)
    end
end

function ActivityNewLevelRewardView:updateCell(viewData, data)
    self:updateTitleLabel(viewData, data)

    self:updateRewardLayer(viewData, data)

    self:updateDrawState(viewData, data)
end

function ActivityNewLevelRewardView:updateTitleLabel(viewData, data)
    local lvStr = string.gsub(data.descr, '主角等级到达', '')
    viewData.levelLabel:setString(lvStr)
end

function ActivityNewLevelRewardView:updateRewardLayer(viewData, data)
    local rewardLayer = viewData.rewardLayer
    local rewards     = data.rewards or {}
    if checkint(data.hasDrawn) == 1 then
        rewards = data.productRewards or {}
    end

    local rewardNodes = viewData.rewardNodes
    
    local nodeCount = table.nums(rewardNodes)
    local rewardCount = #rewards
    local rewardLayerSize = rewardLayer:getContentSize()
    for i = 1, 3 do
        local reward = rewards[i]
        local rewardNode = rewardNodes[i]
        if reward then
            if rewardNode then
                rewardNode:setVisible(true)
            else
                rewardNode = require('common.GoodNode').new({
                    id = checkint(reward.goodsId),
                    amount = checkint(reward.num),
                    showAmount = true,
                    highlight = 1,
                    callBack = function (sender)
                        app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
                    end
                })
                rewardNode:setScale(0.8)
                rewardLayer:addChild(rewardNode)
                table.insert(rewardNodes, rewardNode)
            end
            reward.highlight = checkint(reward.highlight)
            rewardNode:RefreshSelf(reward)
            display.commonUIParams(rewardNode, {po = cc.p(cc.p(36 + (i-1) * 94, rewardLayerSize.height/2))})
        else
            if rewardNode then
                rewardNode:setVisible(false)
            end
        end
    end

end

function ActivityNewLevelRewardView:updateDrawState(viewData, data)
    local drawBtn     = viewData.drawBtn
    local drawLabel   = viewData.drawLabel
    local blackBg     = viewData.blackBg
    local lv          = app.gameMgr:GetUserInfo().level
    local target      = checkint(data.target)

    drawBtn:setEnabled(true)
    blackBg:setVisible(false)
    viewData.timeLabel:setVisible(false)
    viewData.clockIcon:setVisible(false)
    -- 等级不足
    if lv < target then
        drawBtn:setNormalImage(RES_DIR.BTN_DISABLE)
        drawBtn:setSelectedImage(RES_DIR.BTN_DISABLE)
        display.commonLabelParams(drawLabel, {text = __('未领取')})
        return 
    end
    -- 奖励可领取
    if checkint(data.hasDrawn) <= 0 then 
        drawBtn:setNormalImage(RES_DIR.BTN_ORANGE)
        drawBtn:setSelectedImage(RES_DIR.BTN_ORANGE)
        display.commonLabelParams(drawLabel, {text = __('领取')})
        return 
    end 
    -- 奖励可购买
    if checkint(data.hasPurchased) <= 0 and checkint(data.productLeftSeconds) > 0 then
        drawBtn:setNormalImage(RES_DIR.BTN_GREEN)
        drawBtn:setSelectedImage(RES_DIR.BTN_GREEN)
        -- 刷新时间
        display.commonLabelParams(viewData.timeLabel, {text = CommonUtils.getTimeFormatByType(data.productLeftSeconds, 2), reqW = 120})
        -- 刷新价格
        display.commonLabelParams(drawLabel, {text = string.format(__("￥%s") ,tostring(data.price))})
        viewData.timeLabel:setVisible(true)
        viewData.clockIcon:setVisible(true)
        return 
    end
    -- 奖励已结束
    drawBtn:setNormalImage(RES_DIR.BTN_GREY)
    drawBtn:setSelectedImage(RES_DIR.BTN_GREY)
    if checkint(data.hasProductDrawn) == 1 then
        display.commonLabelParams(drawLabel, {text = __('已领取')})
    else
        display.commonLabelParams(drawLabel, {text = __('已过期')})
    end
    drawBtn:setEnabled(false)
    blackBg:setVisible(true)
end

CreateView = function (size)
    local view = display.newLayer(size.width / 2, size.height / 2, {size = size, ap = display.CENTER})
    local bg = display.newImageView(RES_DIR.BG, size.width / 2, size.height / 2)
    view:addChild(bg, 1)
    local role = display.newImageView(RES_DIR.BG_ROLE, size.width / 2, size.height / 2)
    view:addChild(role, 1)
    local title = display.newImageView(RES_DIR.TITLE, 230, 560)
    view:addChild(title, 5)
    local cardName = display.newImageView(RES_DIR.CARD_NAME, 250, 110)
    view:addChild(cardName, 5)
    local cardGiftLabel = display.newLabel(250, 140, {text = __('购买限时礼包获得'), fontSize = 24, color = '#ffffff', ttf = true, font = TTF_GAME_FONT, outline = '#b63c00', outlineSize = 4, reqW = 230})
    view:addChild(cardGiftLabel, 5)
    local listSize = cc.size(640, size.height - 20)
    local listBg = display.newImageView(RES_DIR.LIST_BG, size.width - 10, size.height / 2, { ap = display.RIGHT_CENTER, scale9 = true, size = listSize})
    view:addChild(listBg, 5)
    local tableViewCellSize = cc.size(listSize.height, 180)
    local tableView = CTableView:create(listSize)
    tableView:setDirection(eScrollViewDirectionVertical)
    tableView:setSizeOfCell(tableViewCellSize)
    display.commonUIParams(tableView, {ap = display.RIGHT_CENTER, po = cc.p(size.width - 10, size.height / 2)})
    view:addChild(tableView, 5)
    
    return {
        view        = view,
        tableView   = tableView,
    }

end

function ActivityNewLevelRewardView:CreateCell(size)
    local cell = CTableViewCell:new()
    cell:setContentSize(size)
    local cellBg = display.newImageView(RES_DIR.BG_REWARD, size.width / 2 + 12, size.height / 2, {ap = display.CENTER})
    cell:addChild(cellBg)

    local titleLabel = display.newLabel(100, 142, fontWithColor(5, {fontSize = 20, text = __('主角等级达到'), reqW = 150}))
    cell:addChild(titleLabel)
    
    local levelLabel = display.newLabel(100, 70, {text = '', color = '#d23d3d', fontSize = 26, ttf = true, font = TTF_GAME_FONT})
    cell:addChild(levelLabel)

    local rewardLabel = display.newLabel(329, 142, fontWithColor(5, {fontSize = 20, text = __('奖励')}))
    cell:addChild(rewardLabel)

    local clockIcon = display.newImageView(RES_DIR.CLOCK_ICON, size.width - 150, 142)
    cell:addChild(clockIcon)

    local timeLabel = display.newLabel(size.width - 10, 142, {text = '', fontSize = 22, color = '#93572b', ttf = true, font = TTF_GAME_FONT, ap = display.RIGHT_CENTER, reqW = 110})
    cell:addChild(timeLabel)
    local rewardLayerSize = cc.size(258, 96)
    local rewardLayer = display.newLayer(200, 70, {size = rewardLayerSize, ap = display.LEFT_CENTER})
    cell:addChild(rewardLayer)

    local drawBtn = display.newButton(size.width - 74, size.height/2 - 24, {n = RES_DIR.BTN_DISABLE})
    cell:addChild(drawBtn)

    local drawLabel = display.newLabel(drawBtn:getPositionX(), drawBtn:getPositionY(), fontWithColor(14, {}))
    cell:addChild(drawLabel)

    local blackBg = display.newImageView(RES_DIR.BG_REWARD_BLACK, size.width / 2 + 12, size.height / 2, {ap = display.CENTER})
    cell:addChild(blackBg)
    blackBg:setVisible(false)

    cell.viewData = {
        titleLabel  = titleLabel,
        rewardLayer = rewardLayer,
        drawBtn     = drawBtn,
        drawLabel   = drawLabel,
        blackBg     = blackBg,
        levelLabel  = levelLabel,
        timeLabel   = timeLabel,
        clockIcon   = clockIcon,
        
        rewardNodes = {},
    }

    return cell
end

function ActivityNewLevelRewardView:getViewData()
    return self.viewData_
end

return ActivityNewLevelRewardView