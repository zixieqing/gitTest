local VIEW_SIZE = cc.size(950, 645)
local SummerActivityDamageRewardView = class('SummerActivityDamageRewardView', function ()
	local node = CLayout:create(VIEW_SIZE)
	node.name = 'Game.views.summerActivity.SummerActivityDamageRewardView'
    node:enableNodeEvents()
    -- node:setBackgroundColor(cc.c3b(100,100,200))
	return node
end)

local summerActMgr = app.summerActMgr

local RES_DIR_ = {
    SUMMER_ACTIVITY_RANK_BG_BOSS          = _res('ui/home/activity/summerActivity/entrance/summer_activity_rank_bg_boss.png'),
    SUMMER_ACTIVITY_RANK_BG_LIST_EXTRA    = _res('ui/home/activity/summerActivity/entrance/summer_activity_rank_bg_list_extra.png'),
    SUMMER_ACTIVITY_ENTRANCE_RANK_BG_HEAD = _res('ui/home/activity/summerActivity/entrance/summer_activity_entrance_rank_bg_head.png'),
}
local RES_DIR = {}

local CreateView   = nil
local CreateCell_  = nil

function SummerActivityDamageRewardView:ctor( ... )
    RES_DIR = summerActMgr:resetResPath(RES_DIR_)

    self.args = unpack({...})
    self:initialUI()
end

function SummerActivityDamageRewardView:initialUI()
    xTry(function ( )
        self.viewData = CreateView()
        self:addChild(self.viewData.view)
        display.commonUIParams(self.viewData.view, {ap = display.CENTER, po = cc.p(VIEW_SIZE.width / 2, VIEW_SIZE.height / 2)})
        self:initView()
	end, __G__TRACKBACK__)
end

function SummerActivityDamageRewardView:initView()
    
end

function SummerActivityDamageRewardView:refreshUI(data)
    
end

function SummerActivityDamageRewardView:updateUI(data)
    
end

function SummerActivityDamageRewardView:updateCell(viewData, additionData)
    local data = additionData.data
    local rewards = data.rewards
    -- logInfo.add(5, 'goodsId = ' .. tableToString(rewards))
    local goodsId = nil
    if rewards and rewards[1] then
        local headNode   = viewData.headNode
        goodsId = rewards[1].goodsId
        

        local avatar, avatarFrame
        local goodsData = CommonUtils.GetConfigAllMess('achieveReward','goods')
        local rewardConf = goodsData[tostring(goodsId)] or {}
        if checkint(rewardConf.rewardType) == 2 then
            avatar = goodsId
            avatarFrame = app.gameMgr:GetUserInfo().avatarFrame
        else
            avatar = app.gameMgr:GetUserInfo().avatar
            avatarFrame = goodsId
        end

        headNode:RefreshUI({
            avatar = avatar,
            avatarFrame = avatarFrame,
            callback = function (sender)
                app.uiMgr:ShowInformationTipsBoard({targetNode = headNode, iconId = goodsId, type = 1})
            end
        })
    end
    local titleLabel = viewData.titleLabel
    display.commonLabelParams(titleLabel, {text = tostring(additionData.title), reqW = 330})

    local descLabel  = viewData.descLabel
    display.commonLabelParams(descLabel, {text = tostring(additionData.desc)})

end

CreateView = function ()
    local size = cc.size(950, 590)
    local view = display.newLayer(0, 0, {size = size})
    view:addChild(display.newImageView(RES_DIR.SUMMER_ACTIVITY_RANK_BG_BOSS, size.width - 176, size.height / 2 + 39, {ap = display.CENTER}), 1)

    local rewardTipLayer = require('Game.views.summerActivity.SummerActivityRankRewardCell').new({state = 1})
    display.commonUIParams(rewardTipLayer, {ap = display.CENTER, po = cc.p(310, size.height - 96)})
    view:addChild(rewardTipLayer)

    local extraListSize = cc.size(497, 389)
    local extraListLayer = display.newLayer(rewardTipLayer:getPositionX(), 212, {ap = display.CENTER, size = extraListSize})
    extraListLayer:addChild(display.newImageView(RES_DIR.SUMMER_ACTIVITY_RANK_BG_LIST_EXTRA, extraListSize.width / 2, extraListSize.height / 2, {ap = display.CENTER}))
    view:addChild(extraListLayer)

    local extraRewardTipLabel = display.newLabel(extraListSize.width / 2, extraListSize.height - 18, {fontSize = 20, color = '#85642e', text = summerActMgr:getThemeTextByText(__('第1名的额外奖励: ')), ap = display.CENTER})
    extraListLayer:addChild(extraRewardTipLabel)

    local gridViewSize = cc.size(480, extraListSize.height - 50)
    local gridViewCellSize = cc.size(gridViewSize.width, 130)
    local gridView = CGridView:create(gridViewSize)
    gridView:setPosition(cc.p(extraListSize.width / 2, extraListSize.height / 2 - 14))
    -- gridView:setBackgroundColor(cc.c3b(100,100,200))
    gridView:setAnchorPoint(display.CENTER)
    gridView:setSizeOfCell(gridViewCellSize)
    gridView:setColumns(1)
    extraListLayer:addChild(gridView)

    return {
        rewardTipLayer = rewardTipLayer,
        view         = view,
        gridView     = gridView,
    }
end

CreateCell_ = function ()
    local cell = CGridViewCell:new()
    local size = cc.size(440, 130)

    -- local headNode = require("root.CCHeaderNode").new({isSystemHead = true , url  = app.gameMgr:GetUserInfo().avatar, role_head = nil , pre = nil, isPre = true, isSelf = true})
    -- display.commonUIParams(headNode, {po = cc.p(10, size.height / 2), ap = display.LEFT_CENTER})
    -- headNode:setScale(0.6)
    -- cell:addChild(headNode, 1)
    local headNode = require('common.PlayerHeadNode').new({
        avatar = app.gameMgr:GetUserInfo().avatar,
        showLevel = false,
    })
    display.commonUIParams(headNode, {po = cc.p(10, size.height / 2), ap = display.LEFT_CENTER})
    headNode:setScale(0.78)
    cell:addChild(headNode, 1)

    local bgSize = cc.size(360, 109)
    local bgLayer = display.newLayer(size.width / 2 + 40, size.height / 2, {size = bgSize, ap = display.CENTER})
    cell:addChild(bgLayer)

    local bg = display.newImageView(RES_DIR.SUMMER_ACTIVITY_ENTRANCE_RANK_BG_HEAD, bgSize.width / 2, bgSize.height / 2, {ap = display.CENTER})
    bgLayer:addChild(bg)

    local titleLabel = display.newLabel(60, bgSize.height - 16, {fontSize = 18, color = '#d89233', ap = display.LEFT_CENTER})
    bgLayer:addChild(titleLabel)

    local descLabel = display.newLabel(60, bgSize.height / 2 - 12, {w = 340, fontSize = 18, color = '#a17840', ap = display.LEFT_CENTER})
    bgLayer:addChild(descLabel)

    cell.viewData = {
        headNode   = headNode,
        titleLabel = titleLabel,
        descLabel  = descLabel,
    }

    return cell
end

function SummerActivityDamageRewardView:CreateCell()
    return CreateCell_()
end

function SummerActivityDamageRewardView:getViewData()
    return self.viewData
end


return SummerActivityDamageRewardView