local VIEW_SIZE = cc.size(1000, 640)
local AnniversaryPlotUnlockRewardView = class('common.AnniversaryPlotUnlockRewardView', function ()
	local node = CLayout:create(VIEW_SIZE)
	node.name = 'Game.views.anniversary.AnniversaryPlotUnlockRewardView'
	node:enableNodeEvents()
	return node
end)


local RES_DICT = {
    ANNI_REWARDS_BG_STORY          = app.anniversaryMgr:GetResPath('ui/anniversary/rewardPreview/anni_rewards_bg_story.png'),
    ANNI_REWARDS_LABEL_SUBTITLE     = app.anniversaryMgr:GetResPath('ui/anniversary/rewardPreview/anni_rewards_label_subtitle.png'),
    ANNI_REWARDS_LINE_1             = app.anniversaryMgr:GetResPath('ui/anniversary/rewardPreview/anni_rewards_line_1.png'),
    ANNI_REWARDS_BG_HEAD            = app.anniversaryMgr:GetResPath('ui/anniversary/rewardPreview/anni_rewards_bg_head.png'),
    COMMON_BTN_ORANGE_DISABLE       = app.anniversaryMgr:GetResPath('ui/common/common_btn_orange_disable.png'),
    COMMON_BTN_ORANGE               = app.anniversaryMgr:GetResPath('ui/common/common_btn_orange.png'),
    ACTIVITY_MIFAN_BY_ICO           = app.anniversaryMgr:GetResPath('ui/common/activity_mifan_by_ico.png'),
    ANNI_REWARDS_BG_200134_5        = app.anniversaryMgr:GetResPath('ui/anniversary/rewardPreview/anni_rewards_bg_200134_5.png'),
}

local CreateView  = nil
local CreateCell_ = nil

function AnniversaryPlotUnlockRewardView:ctor()
    xTry(function ( )
        self.viewData = CreateView(VIEW_SIZE)
        self:addChild(self.viewData.view)
	end, __G__TRACKBACK__)
end

function AnniversaryPlotUnlockRewardView:updateMainStoryUI(mainStory)
    local confData = mainStory.confData or {}
    local viewData = self:getViewData()
    self:updateMainReward(viewData, confData.rewards or {})

    self:updateMainRewardReceiveBtn(self:getViewData(), mainStory)
end

function AnniversaryPlotUnlockRewardView:updateMainReward(viewData, rewards)
    local mainRewardLayer = viewData.mainRewardLayer
    local rewardLayerSize = mainRewardLayer:getContentSize()
    local params = {parent = mainRewardLayer, midPointX = rewardLayerSize.width / 2, midPointY = rewardLayerSize.height / 2, maxCol= 4, scale = 0.8, rewards = rewards, hideCustomizeLabel = true}
    CommonUtils.createPropList(params)
end

function AnniversaryPlotUnlockRewardView:updateMainRewardReceiveBtn(viewData, data)
    local mainRewardReceiveBtn = viewData.mainRewardReceiveBtn
    mainRewardReceiveBtn:RefreshUI({drawState = data.drawState})
end

function AnniversaryPlotUnlockRewardView:updateCell(viewData, data)
    local headNode   = viewData.headNode
    local confData   = data.confData or {}
    local rewards    = confData.rewards
    if rewards and rewards[1] then
        local headNode   = viewData.headNode
        local goodsId = rewards[1].goodsId
        headNode:RefreshUI({
            avatar = app.gameMgr:GetUserInfo().avatar,
            avatarFrame = goodsId,
            callback = function (sender)
                app.uiMgr:ShowInformationTipsBoard({targetNode = headNode, iconId = goodsId, type = 1})
            end
        })
    end

    local titleLabel = viewData.titleLabel
    display.commonLabelParams(titleLabel, {reqW = 500, text = tostring(confData.title)})

    local descLabel  = viewData.descLabel
    display.commonLabelParams(descLabel, {w = 430 ,  text = tostring(confData.descr)})
    self:updateDrawBtn(viewData, data)
end

function AnniversaryPlotUnlockRewardView:updateDrawBtn(viewData, data)
    local drawBtn    = viewData.drawBtn
    drawBtn:RefreshUI({drawState = data.drawState})
end

function AnniversaryPlotUnlockRewardView:getViewData()
    return self.viewData
end

function AnniversaryPlotUnlockRewardView:CreateCell(size)
    return CreateCell_(size)
end

CreateView = function (size)
    local view  = display.newLayer(size.width / 2, size.height / 2, {ap = display.CENTER, size = size})

    --------------mainRewardTipBg start---------------
    local mainRewardTipBg = display.newNSprite(RES_DICT.ANNI_REWARDS_LABEL_SUBTITLE, 587, 552,
    {
        ap = display.RIGHT_CENTER,
    })
    view:addChild(mainRewardTipBg)

    mainRewardTipBg:addChild(display.newLabel(19, 16,
    {
        text = app.anniversaryMgr:GetPoText(__('完成主线剧情可以获得:')),
        ap = display.LEFT_CENTER,
        fontSize = 20,
        color = '#ffffff',
    }))

    local rmainRewardLayerSize = cc.size(370, 90)
    local mainRewardLayer = display.newLayer(260, 488, {ap = display.CENTER, size = rmainRewardLayerSize})
    view:addChild(mainRewardLayer)

    local mainRewardReceiveBtn = require('common.CommonDrawButton').new({btnParams = {
        ap = display.CENTER,
        scale9 = true, size = cc.size(123, 62),
        enable = true,
    }})
    display.commonUIParams(mainRewardReceiveBtn, {po = cc.p(534, 488), ap = display.CENTER})
    view:addChild(mainRewardReceiveBtn)

    view:addChild(display.newNSprite(RES_DICT.ANNI_REWARDS_LINE_1, 318, 440, { ap = display.CENTER}))

    ---------------mainRewardTipBg end----------------
    -------------branchRewardTipBg start--------------
    local branchRewardTipBg = display.newNSprite(RES_DICT.ANNI_REWARDS_LABEL_SUBTITLE, 587, 385, {ap = display.RIGHT_CENTER})
    view:addChild(branchRewardTipBg)

    branchRewardTipBg:addChild(display.newLabel(19, 16,
    {
        text = app.anniversaryMgr:GetPoText(__('支线剧情奖励:')),
        ap = display.LEFT_CENTER,
        fontSize = 20,
        color = '#ffffff',
    }))

    local listSize = cc.size(700, 356)
    local listCellSize = cc.size(listSize.width, 140)
    local tableView = CTableView:create(listSize)
    display.commonUIParams(tableView, {po = cc.p(377, 189), ap = display.CENTER})
    tableView:setDirection(eScrollViewDirectionVertical)
    -- tableView:setBackgroundColor(cc.c4b(23, 67, 128, 128))
    tableView:setSizeOfCell(listCellSize)
    view:addChild(tableView)
    --------------branchRewardTipBg end---------------
    view:addChild(display.newNSprite(RES_DICT.ANNI_REWARDS_BG_STORY, 785, 304, {ap = display.CENTER}))
    return {
        view                 = view,
        mainRewardLayer      = mainRewardLayer,
        mainRewardReceiveBtn = mainRewardReceiveBtn,
        tableView            = tableView,
    }
end

CreateCell_ = function (size)
    local cell = CTableViewCell:new()
    dump(size)
    cell:setContentSize(size)

    local headNode = require('common.PlayerHeadNode').new({
        avatar = app.gameMgr:GetUserInfo().avatar,
        showLevel = false,
    })
    display.commonUIParams(headNode, {po = cc.p(20, size.height / 2), ap = display.LEFT_CENTER})
    headNode:setScale(0.78)
    cell:addChild(headNode, 1)

    local descBg = display.newImageView(RES_DICT.ANNI_REWARDS_BG_HEAD, size.width, size.height / 2, {ap = display.RIGHT_CENTER})
    cell:addChild(descBg)
    
    local titleLabel = display.newLabel(150, size.height - 32, {fontSize = 20, color = '#c5803b', ap = display.LEFT_CENTER})
    cell:addChild(titleLabel)

    local descLabel = display.newLabel(150, size.height - 55, {text = '说服力和欧文和服务和佛宏伟后返回我和偶发回我', w = 264, fontSize = 20, color = '#bd8e4e', ap = display.LEFT_TOP})
    cell:addChild(descLabel)

    local btnParams = {
        ap = display.CENTER,
        scale9 = true, size = cc.size(123, 62),
        enable = true,
    }
    local drawBtn = require('common.CommonDrawButton').new({btnParams = btnParams})
    display.commonUIParams(drawBtn, {po = cc.p(size.width - 65, size.height/2 - 14), ap = display.CENTER})
    cell:addChild(drawBtn)

    cell.viewData = {
        headNode   = headNode,
        titleLabel = titleLabel,
        descLabel  = descLabel,
        drawBtn    = drawBtn,
    }

    return cell
end

return  AnniversaryPlotUnlockRewardView