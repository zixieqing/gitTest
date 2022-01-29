--[[
高级米饭心意活动view
--]]
local VIEW_SIZE = cc.size(1035, 637)
local ActivityLevelRewardView = class('ActivityLevelRewardView', function ()
    local node = CLayout:create(VIEW_SIZE)
    node.name = 'home.view.activity.levelReward.ActivityLevelRewardView'
    node:enableNodeEvents()
    return node
end)

local CreateView = nil

local RES_DIR = {
    BG              = _res('ui/home/activity/levelReward/activity_bg_level.jpg'),
    BG_PROP         = _res('ui/home/activity/levelReward/activity_level_bg_prop.jpg'),
    BG_REWARD_BLACK = _res('ui/home/activity/levelReward/activity_level_bg_reward_black.jpg'),
    BG_REWARD       = _res('ui/home/activity/levelReward/activity_level_bg_reward.jpg'),
    BTN_DISABLE     = _res('ui/common/common_btn_orange_disable.png'),
    BTN_ORANGE      = _res('ui/common/common_btn_orange.png')
}

function ActivityLevelRewardView:ctor( ... )
    self.args = unpack({...})
    self:InitUI()
end
--[[
init ui
--]]
function ActivityLevelRewardView:InitUI()
    xTry(function ( )
        self.viewData_ = CreateView(VIEW_SIZE)
        self:addChild(self.viewData_.view)
	end, __G__TRACKBACK__)
    
end

function ActivityLevelRewardView:refreshUI(datas)
    local viewData = self:getViewData()
	local tableView = viewData.tableView
    tableView:setCountOfCell(#datas)
    tableView:reloadData()
    
    
end

function ActivityLevelRewardView:updateCell(viewData, data)
    self:updateTitleLabel(viewData, data)

    self:updateRewardLayer(viewData, data)

    self:updateDrawState(viewData, data)
end

function ActivityLevelRewardView:updateTitleLabel(viewData, data)
    local titleLabel  = viewData.titleLabel

    function stringSplit(input, delimiter)
        input = tostring(input)
        delimiter = tostring(delimiter)
        if (delimiter=='') then return false end
        local pos,arr = 0, {}
        -- for each divider found
        for st,sp in function() return string.find(input, delimiter, pos, true) end do
            table.insert(arr, string.sub(input, pos, st - 1))
            -- 返回 delimiter 也一并返回 
            table.insert(arr, string.sub(input, st, sp))
            pos = sp + 1
        end
        table.insert(arr, string.sub(input, pos))
        return arr
    end

    local target = tostring(data.target)
    local t = stringSplit(data.descr, target)
    if t then
        local titles = {}
        for i, v in ipairs(t) do
            if tostring(v) == target then
                table.insert(titles, fontWithColor(10, {fontSize = 24, text = v}))
            else
                table.insert(titles, fontWithColor(5, {text = v}))
            end
        end
        display.reloadRichLabel(titleLabel, {c = titles})
    end
end

function ActivityLevelRewardView:updateRewardLayer(viewData, data)
    local rewardLayer = viewData.rewardLayer
    local rewards     = data.rewards or {}
    
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

function ActivityLevelRewardView:updateDrawState(viewData, data)
    local drawBtn     = viewData.drawBtn
    local drawLabel   = viewData.drawLabel
    local blackBg     = viewData.blackBg
    local hasDrawn = checkint(data.hasDrawn) > 0
    drawBtn:setVisible(not hasDrawn)
    if hasDrawn then
        display.commonLabelParams(drawLabel, {text = __('已领取')})
    else
        local lv = app.gameMgr:GetUserInfo().level
        local target = checkint(data.target)
        local isSatisfy = lv >= target
        drawBtn:setNormalImage(isSatisfy and RES_DIR.BTN_ORANGE or RES_DIR.BTN_DISABLE)
        drawBtn:setSelectedImage(isSatisfy and RES_DIR.BTN_ORANGE or RES_DIR.BTN_DISABLE)
        display.commonLabelParams(drawLabel, { reqW =100 , text = isSatisfy and  __('领取') or __('未完成')})
    end
    blackBg:setVisible(hasDrawn)
end

CreateView = function (size)
    local view = display.newLayer(size.width / 2, size.height / 2, {size = size, ap = display.CENTER})

    view:addChild(display.newImageView(RES_DIR.BG, size.width / 2, size.height / 2, {ap = display.CENTER}))
    
    local tableViewSize = cc.size(441, size.height - 20)
    local tableViewCellSize = cc.size(441, 147)
    local tableView = CTableView:create(tableViewSize)
    tableView:setDirection(eScrollViewDirectionVertical)
    tableView:setSizeOfCell(tableViewCellSize)
    display.commonUIParams(tableView, {ap = display.RIGHT_CENTER, po = cc.p(size.width - 20, size.height / 2)})
    -- tableView:setBackgroundColor(cc.c4b(178, 63, 88, 100))
    view:addChild(tableView)

    return {
        view        = view,
        tableView   = tableView,
    }

end

function ActivityLevelRewardView:CreateCell(size)
    local cell = CTableViewCell:new()
    cell:setContentSize(size)

    cell:addChild(display.newImageView(RES_DIR.BG_REWARD, size.width / 2, size.height / 2, {ap = display.CENTER}))

    local titleLabel = display.newRichLabel(30, size.height - 18, {ap = display.LEFT_CENTER})
    cell:addChild(titleLabel)

    -- local 
    -- local numLabel = display.newLabel(210, 126, {text = '', fontSize = 28, color = '#fbbe55', ttf = true, font = TTF_GAME_FONT, outline = '4e2e1e', outlineSize = 1})
	-- cell:addChild(numLabel)

    local rewardLayerSize = cc.size(258, 96)
    local rewardLayer = display.newLayer(26, 64, {size = rewardLayerSize, ap = display.LEFT_CENTER})
    cell:addChild(rewardLayer)

    rewardLayer:addChild(display.newImageView(RES_DIR.BG_PROP, rewardLayerSize.width / 2, rewardLayerSize.height / 2, {ap = display.CENTER}))

    local drawBtn = display.newButton(size.width - 74, size.height/2, {n = RES_DIR.BTN_DISABLE})
    cell:addChild(drawBtn)

    local drawLabel = display.newLabel(drawBtn:getPositionX(), drawBtn:getPositionY(), fontWithColor(4, {color = '#2b2017'}))
    cell:addChild(drawLabel)

    local blackBg = display.newImageView(RES_DIR.BG_REWARD_BLACK, size.width / 2, size.height / 2, {ap = display.CENTER})
    cell:addChild(blackBg)
    blackBg:setVisible(false)

    cell.viewData = {
        titleLabel  = titleLabel,
        rewardLayer = rewardLayer,
        drawBtn     = drawBtn,
        drawLabel   = drawLabel,
        blackBg     = blackBg,
        
        rewardNodes = {},
    }

    return cell
end

function ActivityLevelRewardView:getViewData()
    return self.viewData_
end

return ActivityLevelRewardView