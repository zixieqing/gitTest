local CommonDialog = require('common.CommonDialog')
local ActivityPayCumulativeLoginRewardView = class('ActivityPayCumulativeLoginRewardView', CommonDialog)

local CreateView = nil
local CreateCell = nil

local RES_DICT = {
    NOVICE_SIGNIN_BG_REWARD       = _res('ui/home/activity/payLoginReward/novice_signin_bg_reward.png'),
    NOVICE_SIGNIN_REWARD_FRAME    = _res('ui/home/activity/payLoginReward/novice_signin_reward_frame.png'),
}

function ActivityPayCumulativeLoginRewardView:InitialUI()

    self.viewData = CreateView()
    self:InitData()
    self:InitView()
end

function ActivityPayCumulativeLoginRewardView:InitData()
    self.datas = self.args.datas or {}
    self.richTable = self:InitRichTable()
end

function ActivityPayCumulativeLoginRewardView:InitRichTable()
	local richText = __('累计签到满<b>num</b>天')
	local parsedtable = require('Game.labelparser').parse(richText)
	return parsedtable
end

function ActivityPayCumulativeLoginRewardView:InitView()
    local datas = self.args.datas or {}
    local viewData  = self:GetViewData()
    local tableView = viewData.tableView
    tableView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataSourceAdapter))
    tableView:setCountOfCell(#datas)
    tableView:reloadData()
end

function ActivityPayCumulativeLoginRewardView:UpdateCell(cell, data)
    local viewData = cell.viewData
    
    -- update desc
    local taskNum  = data.taskNum
    local textRich = self:GetTextRich(taskNum)
    self:UpdateDescLabel(viewData, textRich)

    -- update rewards node
    local endPosX = self:UpdateRewardNodes(cell, data)

    local rewardsTipLabel = viewData.rewardsTipLabel
    rewardsTipLabel:setPositionX(endPosX - 60)
end

function ActivityPayCumulativeLoginRewardView:GetTextRich(times)
	local textRich      = {}
    for index, value in ipairs(self.richTable) do
        if value.labelname == 'b' then
            local day = {' ', times, ' '}
            table.insert(textRich, {text = table.concat(day), fontSize = 22, color = '#ff7200'})
        else
            table.insert(textRich, fontWithColor(16, {text = value.content}))
        end
	end
	return textRich
end

function ActivityPayCumulativeLoginRewardView:UpdateDescLabel(viewData, textRich)
    local descLabel = viewData.descLabel
    display.reloadRichLabel(descLabel, {c = textRich})
end

function ActivityPayCumulativeLoginRewardView:UpdateRewardNodes(cell, data)
    local viewData    = cell.viewData
    local size        = viewData.size
    local rewardNodes = viewData.rewardNodes
    
    local rewards     = data.rewards or {}
    local nodeCount   = table.nums(rewardNodes)
    local rewardCount = #rewards
    local maxCount    = math.max(nodeCount, rewardCount)
    local startX      = size.width - 80
    local startY      = size.height * 0.5

    local endPosX     = startX
    for i = 1, maxCount do
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
                cell:addChild(rewardNode)
                table.insert(rewardNodes, rewardNode)
            end
            reward.highlight = checkint(reward.highlight)
            rewardNode:RefreshSelf(reward)
            endPosX = startX + (i-1) * 94
            display.commonUIParams(rewardNode, {po = cc.p(endPosX, startY)})
        else
            if rewardNode then
                rewardNode:setVisible(false)
            end
        end
    end
    return endPosX
end

function ActivityPayCumulativeLoginRewardView:OnDataSourceAdapter(p_convertview, idx)
	local pCell = p_convertview
    local index = idx + 1
    if pCell == nil then
		local tableView = self:GetViewData().tableView
		pCell = CreateCell(tableView:getSizeOfCell())
    end
    local data = self.datas[index]
    if data then
        self:UpdateCell(pCell, data)
    end
    return pCell
end

CreateView = function ()
    local size = cc.size(588, 506)
    local view = display.newLayer(0, 0, {size = size})

    local centrePosX = size.width / 2
	local centrePosY = size.height / 2

    local bg = display.newNSprite(RES_DICT.NOVICE_SIGNIN_BG_REWARD, centrePosX, centrePosY, {ap = display.CENTER})
    view:addChild(bg)
    
    local tableViewSize = cc.size(570, 480)
    local tableViewCellSize = cc.size(tableViewSize.width, 146)
    local tableView = CTableView:create(tableViewSize)
    tableView:setDirection(eScrollViewDirectionVertical)
    tableView:setSizeOfCell(tableViewCellSize)
    display.commonUIParams(tableView, {ap = display.CENTER, po = cc.p(centrePosX, centrePosY)})
    -- tableView:setBackgroundColor(cc.c3b(100, 100, 100))
    view:addChild(tableView)

    return {
        view      = view,
        tableView = tableView,
    }
end

CreateCell = function (size)
    local cell = CTableViewCell:new()
    cell:setContentSize(size)

    local centrePosX = size.width / 2
    local centrePosY = size.height / 2
    
    local bg = display.newNSprite(RES_DICT.NOVICE_SIGNIN_REWARD_FRAME, centrePosX, centrePosY, {ap = display.CENTER})
    cell:addChild(bg)

    local descLabel = display.newRichLabel(38, centrePosY, {ap = display.LEFT_CENTER})
    cell:addChild(descLabel)

    local rewardsTipLabel = display.newLabel(centrePosX + 50, centrePosY, fontWithColor(16, {ap = display.RIGHT_CENTER, text = __('奖励')}))
    cell:addChild(rewardsTipLabel)

    cell.viewData = {
        descLabel       = descLabel,
        rewardsTipLabel = rewardsTipLabel,
        rewardNodes     = {},

        size            = size,
    }

    return cell
end

function ActivityPayCumulativeLoginRewardView:CloseHandler()
    self:setVisible(false)
    self:runAction(cc.RemoveSelf:create())
end

function ActivityPayCumulativeLoginRewardView:GetViewData()
    return self.viewData
end

return  ActivityPayCumulativeLoginRewardView