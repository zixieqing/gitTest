--[[
新等级奖励view
--]]
local VIEW_SIZE = cc.size(1035, 637)
local ActivityNoviceAccumulativePayView = class('ActivityNoviceAccumulativePayView', function ()
    local node = CLayout:create(VIEW_SIZE)
    node.name = 'home.view.noviceAccumulativePay.levelReward.ActivityNoviceAccumulativePayView'
    node:enableNodeEvents()
    return node
end)

local CreateView = nil
local CreatePopup = nil 

local RES_DICT = {
    BG              = _res('ui/home/activity/noviceAccumulativePay/new_welfare_bg.png'),
    BG_ROLE         = _res('ui/home/activity/noviceAccumulativePay/new_welfare_role.png'),
    COMMON_TIPS     = _res('ui/common/common_btn_tips.png'),
    
    CARD_NAME       = _res('ui/home/activity/noviceAccumulativePay/common_ico_text_ur_cn.png'),
    TIME_BG         = _res('ui/home/activity/noviceAccumulativePay/new_welfare_ico_bg.png'),
    CLOCK_ICON      = _res('ui/common/new_welfare_ico_making_2.png'),
    CLOCK_ICON_2    = _res('ui/home/activity/noviceAccumulativePay/new_welfare_ico_time.png'),
    CLOCK_LINE      = _res('ui/home/activity/noviceAccumulativePay/new_welfare_ico_time_line.png'),
    LOCK_ICON       = _res('ui/common/common_ico_lock.png'),

    BG_REWARD       = _res('ui/home/activity/levelReward/level_reward_bg_1.jpg'),
    BTN_DISABLE     = _res('ui/common/common_btn_orange_disable.png'),
    BTN_ORANGE      = _res('ui/common/common_btn_orange.png'),
    BTN_GREEN       = _res('ui/common/common_btn_green.png'),
    BTN_GREY        = _res('ui/common/common_btn_grey.png'),

    POPUP_BG        = _res('ui/home/activity/noviceAccumulativePay/activity_open_bg_danchong.png'),
    POPUP_TITLE     = _res('ui/home/activity/noviceAccumulativePay/new_welfare_title_cn.png'),
    POPUP_TIME_BG   = _res('ui/home/activity/noviceAccumulativePay/activity_time_bg.png'),
    POPUP_CLOCK_ICON = _res('ui/home/activity/noviceAccumulativePay/new_welfare_ico_making.png'),
    CLOSE_BTN 	    = _res('ui/home/activity/activity_open_btn_quit.png'),

    ROLE_SPINE      = _spn("ui/home/activity/noviceAccumulativePay/new_welfare_role_title_cn")
}

function ActivityNoviceAccumulativePayView:ctor( ... )
    local args = unpack({...})
    self.isPopup = args.isPopup
    self:InitUI()
end
--[[
init ui
--]]
function ActivityNoviceAccumulativePayView:InitUI()
    xTry(function ( )
        if self.isPopup then
            self:setContentSize(display.size)
            self.viewData_ = CreatePopup(display.size)
            self:addChild(self.viewData_.view)
            -- eaterLayer
            local eaterLayer = display.newLayer(display.cx, display.cy, {size = display.size, ap = display.CENTER, color = cc.c4b(0, 0, 0, 255 * 0.6), enable = true})
            self:addChild(eaterLayer, -1)
            self.eaterLayer = eaterLayer
            self:EnterAction()
        else
            self.viewData_ = CreateView(VIEW_SIZE)
            self:addChild(self.viewData_.view)
        end
	end, __G__TRACKBACK__)
    
end

function ActivityNoviceAccumulativePayView:refreshUI(datas, isFinalTurn, progress)
    local viewData = self:getViewData()
    local tableView = viewData.tableView
    local offset = tableView:getContentOffset()
    local cellsNum = #tableView:getCells()
    tableView:setCountOfCell(#datas)
    tableView:reloadData()
    if cellsNum ~= 0 then
        tableView:setContentOffset(offset)
    end
    if isFinalTurn and viewData.tipsRichLabel then
        display.reloadRichLabel(viewData.tipsRichLabel, {c = {
            {text = __('该部分为最后一档奖励，将不会有下一轮奖励'), color = '#ffffff', ttf = true, font = TTF_GAME_FONT, fontSize = 20}
        }})
    end
    if viewData.scoreLabel then
        display.commonLabelParams(viewData.scoreLabel, {text = progress, reqW = 140})
    end
end

function ActivityNoviceAccumulativePayView:updateCell(viewData, data, stageData)
    self:updateCellUi(viewData, data)

    self:updateRewardLayer(viewData, data)

    self:updateDrawState(viewData, data, stageData)
end

function ActivityNoviceAccumulativePayView:updateCellUi(viewData, data)
    local roleImg = viewData.roleImg
    local richLabel = viewData.richLabel
    roleImg:setTexture(_res(string.format('ui/home/activity/noviceAccumulativePay/%s.png', data.pictureId)))
    local strs = string.split(string.fmt(__('累计充值| _num_积分 |即可领取'), {['_num_'] = data.moneyPoints}), '|')
    display.reloadRichLabel(richLabel, {c = {
        {text = strs[1], fontSize = 22, color = '#93572b'},
        {text = strs[2], fontSize = 32, color = '#d23d3d', ttf = true, font = TTF_GAME_FONT},
        {text = strs[3], fontSize = 22, color = '#93572b'},
    }})
end

function ActivityNoviceAccumulativePayView:updateRewardLayer(viewData, data)
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
                rewardNode:setScale(0.75)
                rewardLayer:addChild(rewardNode)
                table.insert(rewardNodes, rewardNode)
            end
            reward.highlight = checkint(reward.highlight)
            rewardNode:RefreshSelf(reward)
            display.commonUIParams(rewardNode, {po = cc.p(cc.p(40 + (i-1) * 94, rewardLayerSize.height/2))})
        else
            if rewardNode then
                rewardNode:setVisible(false)
            end
        end
    end

end

function ActivityNoviceAccumulativePayView:updateDrawState(viewData, data, stageData)
    local drawBtn     = viewData.drawBtn
    local drawLabel   = viewData.drawLabel
    local drawData    = stageData[tostring(data.id)]
    if checkint(drawData.hasDrawn) == 1 then
        drawBtn:setEnabled(false)
        drawBtn:setNormalImage(RES_DICT.BTN_GREY)
        drawBtn:setSelectedImage(RES_DICT.BTN_GREY)
        display.commonLabelParams(drawLabel, {text = __('已领取')})
        return 
    end
    if checkint(drawData.progress) >= checkint(data.moneyPoints) then
        drawBtn:setEnabled(true)
        drawBtn:setNormalImage(RES_DICT.BTN_ORANGE)
        drawBtn:setSelectedImage(RES_DICT.BTN_ORANGE)
        display.commonLabelParams(drawLabel, {text = __('领取')})
        return 
    end
    drawBtn:setEnabled(false)
    drawBtn:setNormalImage(RES_DICT.BTN_DISABLE)
    drawBtn:setSelectedImage(RES_DICT.BTN_DISABLE)
    display.commonLabelParams(drawLabel, {text = __('未领取')})
end

function ActivityNoviceAccumulativePayView:UpdateTimeLabel( seconds )
    local viewData = self:getViewData()
    display.commonLabelParams(viewData.timeLabel, {text = CommonUtils.getTimeFormatByType(seconds, 2), reqW = 120})
end

CreateView = function (size)
    local view = display.newLayer(size.width / 2, size.height / 2, {size = size, ap = display.CENTER})
    local bg = display.newImageView(RES_DICT.BG, size.width / 2, size.height / 2)
    view:addChild(bg, 1)
    local tipsBtn = display.newButton(size.width - 30, 25, {n = RES_DICT.COMMON_TIPS})
    view:addChild(tipsBtn, 5)
    -- clipNode --
    local clipNode = cc.ClippingNode:create()
    clipNode:setContentSize(size)
    clipNode:setAnchorPoint(display.CENTER)
    clipNode:setPosition(cc.p(size.width / 2, size.height / 2))
	view:addChild(clipNode, 1)
	local stencilNode = display.newNSprite(RES_DICT.BG, size.width / 2, size.height / 2)
    clipNode:setAlphaThreshold(0.1)
	clipNode:setInverted(false)
	clipNode:setStencil(stencilNode)
    local roleSpine = display.newPathSpine(RES_DICT.ROLE_SPINE)
    roleSpine:setPosition(cc.p(size.width / 2 - 110, size.height / 2 + 45))
    roleSpine:setAnimation(0, 'idle', true)
    clipNode:addChild(roleSpine, 1)
    -- clipNode --
    local cardName = display.newImageView(RES_DICT.CARD_NAME, 120, 200)
    view:addChild(cardName, 5)
    local clockIcon = display.newImageView(RES_DICT.CLOCK_ICON_2, size.width - 160, size.height - 28)
    view:addChild(clockIcon, 1)
    local timeLabel = display.newLabel(size.width - 90, size.height - 28, {text = '', fontSize = 22, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT, reqW = 110})
    view:addChild(timeLabel, 1)
    local line = display.newImageView(RES_DICT.CLOCK_LINE, size.width - 100, size.height - 45)
    view:addChild(line, 1)
    local currentScoreLabel = display.newLabel(size.width - 630, size.height - 30, {text = __('当前活动积分'), fontSize = 24, color = '#d23d3c', ap = display.LEFT_CENTER})
    view:addChild(currentScoreLabel, 1)
    local scoreBg = display.newImageView(RES_DICT.TIME_BG, currentScoreLabel:getPositionX() + display.getLabelContentSize(currentScoreLabel).width + 10, size.height - 30, {ap = display.LEFT_CENTER})
    view:addChild(scoreBg, 1) 
    local scoreLabel = display.newLabel(scoreBg:getContentSize().width / 2, scoreBg:getContentSize().height  / 2, {text = '0', color = 'd23d3d', fontSize = 22, ttf = true, font = TTF_GAME_FONT})
    scoreBg:addChild(scoreLabel, 3)

    local listBgSize = cc.size(630, 577)
    local listSize = cc.size(630, 542)
    local tableViewCellSize = cc.size(listSize.width, 180)
    local tableView = CTableView:create(listSize)
    tableView:setDirection(eScrollViewDirectionVertical)
    tableView:setSizeOfCell(tableViewCellSize)
    display.commonUIParams(tableView, {ap = display.RIGHT_CENTER, po = cc.p(size.width - 8, size.height / 2 - 10)})
    view:addChild(tableView, 5)
    local tipsRichLabel = display.newRichLabel(710, 25, {r = true, c = {
        {img = RES_DICT.LOCK_ICON, scale = 0.7},
        {text = __('全部领取完毕后，可解锁进阶奖励'), color = '#ffffff', ttf = true, font = TTF_GAME_FONT, fontSize = 20}
    }})
    view:addChild(tipsRichLabel, 5)
    return {
        view        = view,
        tableView   = tableView,
        timeLabel   = timeLabel,
        tipsRichLabel = tipsRichLabel,
        tipsBtn     = tipsBtn,
        scoreLabel  = scoreLabel
    }
end

CreatePopup = function (size)
    local bgSize = cc.size(1040, 646)
    local view = display.newLayer(size.width / 2 + 50, size.height / 2 - 25, {size = bgSize, ap = display.CENTER})
    local mask = display.newLayer(bgSize.width / 2, bgSize.height / 2, {size = bgSize, ap = display.CENTER, color = cc.c4b(0, 0, 0, 0), enable = true})
    view:addChild(mask, -1)
    local bg = display.newImageView(RES_DICT.POPUP_BG, bgSize.width / 2 -124, bgSize.height / 2 + 32)
    view:addChild(bg, 1)
    local timeBg = display.newImageView(RES_DICT.POPUP_TIME_BG, 130, bgSize.height - 50)
    view:addChild(timeBg, 5)
    local clockIcon = display.newImageView(RES_DICT.POPUP_CLOCK_ICON, 60, timeBg:getContentSize().height / 2)
    timeBg:addChild(clockIcon, 1)
    local timeLabel = display.newLabel(timeBg:getContentSize().width / 2 + 16, timeBg:getContentSize().height / 2, {text = '', fontSize = 22, color = '#FFDD9B', ttf = true, font = TTF_GAME_FONT, reqW = 110})
    timeBg:addChild(timeLabel, 1)
    local title = display.newImageView(RES_DICT.POPUP_TITLE, 100, 130)
    view:addChild(title,  5)
    local tipsBtn = display.newButton(30, bgSize.height - 50, {n = RES_DICT.COMMON_TIPS})
    view:addChild(tipsBtn, 5)
    local listBgSize = cc.size(630, bgSize.height - 60)
    local listSize = cc.size(630, bgSize.height - 95)
    local tableViewCellSize = cc.size(listSize.width, 180)
    local tableView = CTableView:create(listSize)
    tableView:setDirection(eScrollViewDirectionVertical)
    tableView:setSizeOfCell(tableViewCellSize)
    tableView:setScale(1.06) 
    display.commonUIParams(tableView, {ap = display.RIGHT_CENTER, po = cc.p(bgSize.width - 50, bgSize.height / 2 )})
    view:addChild(tableView, 5)
    local closeBtn = display.newButton(bgSize.width - 20, bgSize.height - 20, {n = RES_DICT.CLOSE_BTN})
    view:addChild(closeBtn, 5)
    return {
        view        = view,
        tableView   = tableView,
        timeLabel   = timeLabel,
        closeBtn    = closeBtn,
        tipsBtn     = tipsBtn,
    }
end

function ActivityNoviceAccumulativePayView:CreateCell(size)
    local cell = CTableViewCell:new()
    cell:setContentSize(size)
    local cellBg = display.newImageView(RES_DICT.BG_REWARD, size.width / 2, size.height / 2, {ap = display.CENTER})
    cell:addChild(cellBg)

    local roleImg = display.newImageView('', size.width / 2, size.height / 2 - 15)
    cell:addChild(roleImg)

    local richLabel = display.newRichLabel(20, size.height - 35, {ap = display.LEFT_CENTER})
    cell:addChild(richLabel)
    
    local rewardLayerSize = cc.size(160, 96)
    local rewardLayer = display.newLayer(300, 70, {size = rewardLayerSize, ap = display.LEFT_CENTER})
    cell:addChild(rewardLayer)

    local drawBtn = display.newButton(size.width - 90, size.height/2 - 24, {n = RES_DICT.BTN_ORANGE})
    cell:addChild(drawBtn)
    local drawLabel = display.newLabel(drawBtn:getPositionX(), drawBtn:getPositionY(), fontWithColor(14, {}))
    cell:addChild(drawLabel)

    local tipsLabel = display.newLabel(size.width - 30, size.height/2 + 50, {text = __('每充值1元=1积分'), fontSize = 20, color = '#7c7c7c', ap = display.RIGHT_CENTER})
    cell:addChild(tipsLabel, 1)
    cell.viewData = {
        rewardLayer = rewardLayer,
        richLabel   = richLabel,
        roleImg     = roleImg,
        drawBtn     = drawBtn,
        drawLabel   = drawLabel,
        rewardNodes = {},
    }

    return cell
end
--[[
进入动画
--]]
function ActivityNoviceAccumulativePayView:EnterAction()
    local viewData = self:getViewData()
	viewData.view:setScale(0.8)
	viewData.view:runAction(
		cc.Sequence:create(
			cc.EaseBackOut:create(
				cc.ScaleTo:create(0.25, 1)
			)
		)
	)
end
function ActivityNoviceAccumulativePayView:getViewData()
    return self.viewData_
end

return ActivityNoviceAccumulativePayView