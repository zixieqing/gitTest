local VIEW_SIZE = cc.size(497, 132)
local SummerActivityRankRewardCell = class('SummerActivityRankRewardCell', function ()
    local node = CLayout:create(VIEW_SIZE)
    -- node:setBackgroundColor(cc.c4b(23, 67, 128, 128))
	node.name = 'Game.views.summerActivity.SummerActivityRankRewardCell'
	node:enableNodeEvents()
	return node
end)

local appIns   = AppFacade.GetInstance()
local summerActMgr = appIns:GetManager("SummerActivityManager")

local RES_DIR_ = {
    SUMMER_ACTIVITY_ENTRANCE_LABEL_2      = _res("ui/home/activity/summerActivity/entrance/summer_activity_entrance_label_2.png"),
    -- RANK_BG      = _res("ui/home/activity/summerActivity/entrance/summer_activity_entrance_rank_bg.png"),
    SUMMER_ACTIVITY_ENTRANCE_RANK_LIST    = _res("ui/home/activity/summerActivity/entrance/summer_activity_entrance_rank_list.png"),
    CELL_SELECT  = _res('ui/mail/common_bg_list_selected.png'),
}
local RES_DIR = {}

local CreateView = nil

function SummerActivityRankRewardCell:ctor( ... )
    RES_DIR = summerActMgr:resetResPath(RES_DIR_)

    self.args = unpack({...}) or {}
    self.state = self.args.state
    self:initialUI()
end

function SummerActivityRankRewardCell:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView(VIEW_SIZE)
        self:addChild(self.viewData_.view)

        self:initView()
	end, __G__TRACKBACK__)
end

function SummerActivityRankRewardCell:initView()
    local viewData        = self:getViewData()
    local curRankLabel    = viewData.curRankLabel
    local rankTipLabel    = viewData.rankTipLabel
    local listRankLabelBg = viewData.listRankLabelBg
    local listRankLabel   = viewData.listRankLabel
    local rewardLayer     = viewData.rewardLayer
    local selectImg       = viewData.selectImg

    if self.state == 1 then
        curRankLabel:setVisible(false)
        rankTipLabel:setVisible(true)
        -- display.commonLabelParams(listRankLabel, {color = '#ffffff',})
    else
        curRankLabel:setVisible(false)
        rankTipLabel:setVisible(false)
        listRankLabelBg:setVisible(false)
    end

    -- self:refreshUI(nil, self.state)
end

function SummerActivityRankRewardCell:refreshUI(data, state, isSelect, rankTipText)
    self:updateUI(data, state, isSelect, rankTipText)
end

function SummerActivityRankRewardCell:updateUI(data, state, isSelect, rankTipText)
    local viewData        = self:getViewData()
    local pointData = nil
    if state == 1 then
        pointData = data
        local upperLimit = checkint(data.upperLimit)
        local lowerLimit = checkint(data.lowerLimit)
        local text = nil
        if rankTipText then
            text = rankTipText
        elseif upperLimit ~= 0 and lowerLimit ~= 0 and lowerLimit ~= upperLimit then
            text = string.format(summerActMgr:getThemeTextByText(__('名次: %s~%s')), upperLimit, lowerLimit)
        else
            text = string.format(summerActMgr:getThemeTextByText(__('名次: %s')), upperLimit)
        end
        
        self:updateRankTipLabel(viewData, text)
        self:updateSelectImg(viewData, isSelect)

        if isSelect then
            self:updateListRankLabel(viewData, summerActMgr:getThemeTextByText(__('当前')))
        else
            self:updateListRankLabel(viewData)
        end
    else
        pointData = summerActMgr:GetCurPointRankDataByRank(checkint(data.mySummerPointRank))
        viewData.curRankLabel:setVisible(checkint(data.mySummerPointRank) > 0)
        self:updateListRankLabel(viewData, checkint(data.mySummerPointRank))

    end
    self:updateRewardLayer(viewData, pointData.rewards)
end

function SummerActivityRankRewardCell:updateListRankLabel(viewData, rank)
    local isShow = rank ~= nil -- checkint(rank) > 0
    local listRankLabelBg = viewData.listRankLabelBg
    listRankLabelBg:setVisible(isShow)

    if isShow then
        local listRankLabel = viewData.listRankLabel
        display.commonLabelParams(listRankLabel, {text = tostring(rank)})
    end
end

function SummerActivityRankRewardCell:updateRewardLayer(viewData, rewards)
    local isShowReward = rewards ~= nil and next(rewards) ~= nil
    
    local emptyRankTip = viewData.emptyRankTip
    local rewardLayer  = viewData.rewardLayer
    emptyRankTip:setVisible(not isShowReward)  
    rewardLayer:setVisible(isShowReward)

    if isShowReward then
        local scale = 0.8
        local callBack = function(sender)
            app.uiMgr:ShowInformationTipsBoard({ targetNode = sender, iconId = sender.goodId, type = 1 })
        end
        
        local rewardNodes = viewData.rewardNodes
        local rewardNodeCount = #rewardNodes--table.nums(rewardNodes)
        local rewardCount = #rewards
        local showIndexs  = {}
        local ergodicTimes = math.max(rewardNodeCount, rewardCount)
        
        for i = 1, ergodicTimes do
            local goodNode  = rewardNodes[i]
            local reward    = rewards[i]
            if reward then
                if goodNode then
                    goodNode:setVisible(true)
                    goodNode:RefreshSelf(reward)
                else
                    local goodNode = require('common.GoodNode').new({id = reward.goodsId, amount = reward.num, showAmount = true, callBack = callBack})
                    goodNode:setScale(scale)
                    rewardLayer:addChild(goodNode)
                    table.insert(rewardNodes, goodNode)
                end
                table.insert(showIndexs, i)
            else
                if goodNode then
                    goodNode:setVisible(false)
                end
            end
        end

        local goodNodeSize = nil
        local rewardLayerSize = rewardLayer:getContentSize()
        local midPointX = rewardLayerSize.width / 2
        local midPointY = rewardLayerSize.height / 2
        local showIndexCount = #showIndexs
        for i, index in ipairs(showIndexs) do
            local node = rewardNodes[i]
            if goodNodeSize == nil then
                goodNodeSize = node:getContentSize()
            end
            local pos = CommonUtils.getGoodPos({index = index, goodNodeSize = goodNodeSize, scale = scale, midPointX = midPointX, midPointY = midPointY, col = showIndexCount, maxCol = 5, goodGap = 10})
            display.commonUIParams(node, {po = pos})
        end
    end
end

function SummerActivityRankRewardCell:updateSelectImg(viewData, isSelect)
    local selectImg = viewData.selectImg
    selectImg:setVisible(checkbool(isSelect))
end

function SummerActivityRankRewardCell:updateRankTipLabel(viewData, text)
    local rankTipLabel = viewData.rankTipLabel
    display.commonLabelParams(rankTipLabel, {text = text, reqW = 330})
end

function SummerActivityRankRewardCell:updateRankTipLabelColor(color)
    display.commonLabelParams(self:getViewData().rankTipLabel, {color = color})
end

function SummerActivityRankRewardCell:updateBg(path)
    self:getViewData().bg:setTexture(path)
end

CreateView = function (size)
    local view = display.newLayer(0, 0, {size = size, ap = display.LEFT_BOTTOM})
    local bg = display.newImageView(RES_DIR.SUMMER_ACTIVITY_ENTRANCE_RANK_LIST, size.width / 2, size.height / 2, {ap = display.CENTER})
    view:addChild(bg)

    local curRankLabel = display.newLabel(42, size.height - 16, fontWithColor(5, {fontSize = 18, color = '#61410e', text = summerActMgr:getThemeTextByText(__('当前排名奖励')), ap = display.LEFT_CENTER}))
    curRankLabel:setVisible(false)
    view:addChild(curRankLabel)

    local rankTipLabel = display.newLabel(size.width / 2, size.height - 19, fontWithColor(5, {ap = display.CENTER}))
    rankTipLabel:setVisible(false)
    view:addChild(rankTipLabel)

    local listRankLabelBg = display.newImageView(RES_DIR.SUMMER_ACTIVITY_ENTRANCE_LABEL_2, size.width + 7, size.height - 16, {ap = display.RIGHT_CENTER})
    listRankLabelBg:setVisible(false)
    view:addChild(listRankLabelBg, 1)

    local listRankLabel = display.newLabel(65, 14, fontWithColor(5, {fontSize = 20, color = '#ffffff'}))
    listRankLabelBg:addChild(listRankLabel)

    local rewardLayerSize = cc.size(size.width, 86)
    local rewardLayer = display.newLayer(size.width / 2, 53, {size = rewardLayerSize, ap = display.CENTER})
    view:addChild(rewardLayer)

    local selectImg = display.newImageView(RES_DIR.CELL_SELECT, size.width / 2, size.height / 2, {ap = display.CENTER, scale9 = true, size = cc.size(size.width + 4, size.height + 8)})
    selectImg:setVisible(false)
    view:addChild(selectImg)

    local emptyRankTip = display.newLabel(size.width / 2, 53, fontWithColor(3, {fontSize = 22, text = summerActMgr:getThemeTextByText(__('您还没有参与游乐园的活动哦~')), w = size.width - 120, hAlign = display.TAC, ap = display.CENTER}))
    emptyRankTip:setVisible(false)
    view:addChild(emptyRankTip)

    return {
        view            = view,
        bg              = bg,
        curRankLabel    = curRankLabel,
        rankTipLabel    = rankTipLabel,
        listRankLabelBg = listRankLabelBg,
        listRankLabel   = listRankLabel,
        rewardLayer     = rewardLayer,
        selectImg       = selectImg,
        emptyRankTip    = emptyRankTip,

        rewardNodes     = {},
    }
end

function SummerActivityRankRewardCell:getViewData()
    return self.viewData_
end

return SummerActivityRankRewardCell