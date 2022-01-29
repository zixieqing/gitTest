local VIEW_SIZE = cc.size(1000, 640)
local AnniversaryChallengeRewardView = class('common.AnniversaryChallengeRewardView', function ()
	local node = CLayout:create(VIEW_SIZE)
	node.name = 'Game.views.anniversary.AnniversaryChallengeRewardView'
	node:enableNodeEvents()
	return node
end)


local RES_DICT = {
    COMMON_BTN_ORANGE_DISABLE       = app.anniversaryMgr:GetResPath('ui/common/common_btn_orange_disable.png'),
    COMMON_BTN_ORANGE               = app.anniversaryMgr:GetResPath('ui/common/common_btn_orange.png'),
    ACTIVITY_MIFAN_BY_ICO           = app.anniversaryMgr:GetResPath('ui/common/activity_mifan_by_ico.png'),
    ANNI_ICO_POINT                  = app.anniversaryMgr:GetResPath('ui/anniversary/rewardPreview/anni_ico_point.png'),
    ANNI_REWARDS_BG_POINT          = app.anniversaryMgr:GetResPath('ui/anniversary/rewardPreview/anni_rewards_bg_point.png'),
    ANNI_REWARDS_LINE_2             = app.anniversaryMgr:GetResPath('ui/anniversary/rewardPreview/anni_rewards_line_2.png'),
    FISH_TRAVEL_POINT_LABEL         = app.anniversaryMgr:GetResPath('ui/tastingTour/lobby/fish_travel_point_label.png'),
    FISH_TRAVEL_POINT_LINE          = app.anniversaryMgr:GetResPath('ui/tastingTour/lobby/fish_travel_point_line.png'),
    FISH_TRAVEL_POINT_BG_FRAME      = app.anniversaryMgr:GetResPath('ui/tastingTour/stage/fish_travel_point_bg_frame.png'),
    ANNI_REWARDS_BG_200115_5        = app.anniversaryMgr:GetResPath('ui/anniversary/rewardPreview/anni_rewards_bg_200115_5.png'),
}

local CreateView  = nil
local CreateCell_ = nil
local CreateGoodNode = nil

function AnniversaryChallengeRewardView:ctor()
    xTry(function ( )
        self.viewData = CreateView(VIEW_SIZE)
        self:addChild(self.viewData.view)
	end, __G__TRACKBACK__)
end

function AnniversaryChallengeRewardView:updateIntegralLabel(viewData, challengePoint)
    local integralLabel = viewData.integralLabel
    display.commonLabelParams(integralLabel, {text = tostring(challengePoint)})
end

function AnniversaryChallengeRewardView:updateCell(viewData, data)
    
    local integralNumLabel = viewData.integralNumLabel
    local confData         = data.confData or {}
    display.commonLabelParams(integralNumLabel, {text = tostring(confData.employee)})
    
    local pointIcon = viewData.pointIcon
    pointIcon:setPositionX(integralNumLabel:getPositionX() + display.getLabelContentSize(integralNumLabel).width + 3)


    self:updateDrawBtn(viewData, data)

    self:updateRewardLayer(viewData, data)
    
end

--==============================--
--desc: 更新领取按钮
--@params viewData table 视图数据
--@params data     table cell数据
--        data.drawState int 1 不可领取 2 可领取 3 已领取
--==============================--
function AnniversaryChallengeRewardView:updateDrawBtn(viewData, data)
    local drawBtn          = viewData.drawBtn
    drawBtn:RefreshUI({drawState = data.drawState})
end

--==============================--
--desc: 更新奖励层
--@params viewData table 视图数据
--@params data     table cell数据
--==============================--
function AnniversaryChallengeRewardView:updateRewardLayer(viewData, data)
    local rewardLayer      = viewData.rewardLayer
    local rewardNodes      = viewData.rewardNodes
    local confData         = data.confData or {}
    local rewards          = confData.rewards or {}
    local rewardCount      = #rewards
    local maxCount = math.max(rewardCount, #rewardNodes)
    local rewardLayerSize = rewardLayer:getContentSize()
    for i = 1, maxCount do
        local reward = rewards[i]
        local rewardNode = rewardNodes[i]
        
        if reward then
            if rewardNode then
                rewardNode:setVisible(true)
                rewardNode:RefreshSelf(reward)
            else
                rewardNode = CreateGoodNode(reward)
                rewardLayer:addChild(rewardNode)
                table.insert(rewardNodes, rewardNode)
            end
            display.commonUIParams(rewardNode, {po = cc.p(36 + (i - 1) * 93, rewardLayerSize.height / 2)})
        elseif rewardNode then
            rewardNode:setVisible(false)
        end
    end
end

function AnniversaryChallengeRewardView:getViewData()
    return self.viewData
end

function AnniversaryChallengeRewardView:CreateCell(size)
    return CreateCell_(size)
end

CreateView = function (size)
    local view  = display.newLayer(size.width / 2, size.height / 2, {ap = display.CENTER, size = size})
    view:addChild(display.newNSprite(RES_DICT.ANNI_REWARDS_BG_POINT, 30, 586, {ap = display.LEFT_TOP}))
    view:addChild(display.newLabel(947, 565, {text = app.anniversaryMgr:GetPoText(__('当前的庆典积分')), ap = display.RIGHT_CENTER, fontSize = 20, color = '#52191f'}))

    view:addChild(display.newNSprite(RES_DICT.ANNI_REWARDS_LINE_2, 957, 551, {ap = display.RIGHT_CENTER}))

    local pointIcon = display.newNSprite(RES_DICT.ANNI_ICO_POINT, 934, 536, {ap = display.CENTER})
    pointIcon:setScale(0.2)
    view:addChild(pointIcon)

    local integralLabel = display.newLabel(914, 535, fontWithColor(14, {ap = display.RIGHT_CENTER, fontSize = 20, color = '#ffffff', outline = '#382323', outlineSize = 1}))
    view:addChild(integralLabel)

    local listSize = cc.size(600, 510)
    local listCellSize = cc.size(listSize.width, 112)
    local tableView = CTableView:create(listSize)
    display.commonUIParams(tableView, {po = cc.p(659, 267), ap = display.CENTER})
    tableView:setDirection(eScrollViewDirectionVertical)
    -- tableView:setBackgroundColor(cc.c4b(23, 67, 128, 128))
    tableView:setSizeOfCell(listCellSize)
    view:addChild(tableView)

    return {
        view                 = view,
        integralLabel        = integralLabel,
        tableView            = tableView,
    }
end

CreateCell_ = function (size)
    local cell = CTableViewCell:new()
    cell:setContentSize(size)

    cell:addChild(display.newNSprite(RES_DICT.FISH_TRAVEL_POINT_BG_FRAME, size.width / 2, size.height / 2, {ap = display.CENTER}))

    cell:addChild(display.newLabel(16, 91, {text = app.anniversaryMgr:GetPoText(__('达到')), ap = display.LEFT_CENTER, fontSize = 20, color = '#8c6648'}))

    cell:addChild(display.newNSprite(RES_DICT.FISH_TRAVEL_POINT_LINE, 90, 76, {ap = display.CENTER}))

    cell:addChild(display.newNSprite(RES_DICT.FISH_TRAVEL_POINT_LABEL, 89, 57, {ap = display.CENTER}))

    local integralNumLabel = display.newLabel(18, 59,
    {
        ap = display.LEFT_CENTER,
        fontSize = 20,
        color = '#ffffff',
        outline = '#382323', outlineSize = 1,
        font = TTF_GAME_FONT, ttf = true,
    })
    cell:addChild(integralNumLabel)

    local pointIcon = display.newNSprite(RES_DICT.ANNI_ICO_POINT, 120, 61,
    {
        ap = display.LEFT_CENTER
    })
    pointIcon:setScale(0.2)
    cell:addChild(pointIcon)

    cell:addChild(display.newLabel(18, 25, {text = app.anniversaryMgr:GetPoText(__('可获得: ')), ap = display.LEFT_CENTER, fontSize = 20, color = '#786d6d'}))

    local rewardLayerSize = cc.size(276, 100)
    local rewardLayer = display.newLayer(160, size.height / 2, {ap = display.LEFT_CENTER, size = rewardLayerSize})
    cell:addChild(rewardLayer)

    local btnParams = {
        ap = display.CENTER,
        scale9 = true, size = cc.size(123, 62),
        enable = true,
    }
    local drawBtn = require('common.CommonDrawButton').new({btnParams = btnParams})
    display.commonUIParams(drawBtn, {po = cc.p(516, 57), ap = display.CENTER})
    cell:addChild(drawBtn)

    cell.viewData = {
        integralNumLabel = integralNumLabel,
        pointIcon        = pointIcon,
        rewardLayer      = rewardLayer,
        rewardNodes      = {},
        drawBtn          = drawBtn,
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

return  AnniversaryChallengeRewardView