--[[
探索系统探索页面UI
--]]
local ExploreSystemConditionRewardView = class('ExploreSystemConditionRewardView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.exploreSystem.ExploreSystemConditionRewardView'
	node:enableNodeEvents()
	return node
end)

local CreateView = nil
local CreateCell = nil

local RED_DIR = {
    BG               = _res('ui/common/common_bg_7.png'),
    TITLE            = _res('ui/common/common_bg_title_2.png'),
    LIST_BG          = _res('ui/common/common_bg_goods.png'),
    LIST_CELL_BG     = _res('ui/common/common_bg_list.png'),
    CELL_TITLE       = _res('ui/home/task/task_bg_title.png'),
    CELL_SELECT      = _res('ui/mail/common_bg_list_selected.png'),
}

function ExploreSystemConditionRewardView:ctor( ... )
	self.args = unpack({...}) or {}
	self:initData(self.args)
	self:initialUI()
end

function ExploreSystemConditionRewardView:initData(data)
    self.curSatisfyConditionCount = checkint(data.curSatisfyConditionCount)
    self.conditionRewardList = data.conditionRewardList or {}
    

    self.curRewardIndex = checkint(data.curRewardIndex)
end

function ExploreSystemConditionRewardView:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView()
        self:addChild(self:getViewData().view)

        self:initView()
	end, __G__TRACKBACK__)
end

function ExploreSystemConditionRewardView:initView()
    local viewData = self:getViewData()
    local shadowLayer = viewData.shadowLayer
    display.commonUIParams(shadowLayer, {cb = handler(self, self.onClickShadowAction)})

    local gridView = viewData.gridView
    gridView:setDataSourceAdapterScriptHandler(handler(self, self.onDataSourceAdapter))
    gridView:setCountOfCell(#self.conditionRewardList)

    self:updateList()
end

function ExploreSystemConditionRewardView:refreshUI(data)
    self:initData(data)
    self:updateList()
end

function ExploreSystemConditionRewardView:updateList()
    local viewData = self:getViewData()
    local gridView = viewData.gridView
    gridView:reloadData()
end

function ExploreSystemConditionRewardView:updateCell(viewData, index)
    local data = self.conditionRewardList[index]

    local demondConditionCount = data.demondConditionCount
    local reachConditionCount = viewData.reachConditionCount
    display.commonLabelParams(reachConditionCount, {text = string.format( "%s/%s", self.curSatisfyConditionCount, demondConditionCount)})

    local extraReward         = data.extraReward
    local rewardLayer         = viewData.rewardLayer
    local rewardLayerSize     = rewardLayer:getContentSize()
    if rewardLayer:getChildrenCount() > 0 then
        rewardLayer:removeAllChildren()
    end
    local callBack = function(sender)
        local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
        uiMgr:ShowInformationTipsBoard({ targetNode = sender, iconId = sender.goodId, type = 1 })
    end
    local h = rewardLayerSize.height / 2
    for i, v in ipairs(extraReward) do
        local goodNode = require('common.GoodNode').new({id = v.goodsId, amount = v.num, showAmount = true, callBack = callBack})
        local goodNodeSize = goodNode:getContentSize()
        goodNode:setScale(0.8)
        display.commonUIParams(goodNode, {po = cc.p(rewardLayerSize.width - 50 - (i - 1) * goodNodeSize.width * 0.82, h)})
        rewardLayer:addChild(goodNode)
    end

    local selectImg           = viewData.selectImg
    local isSelect = self.curRewardIndex == index
    selectImg:setVisible(isSelect)
    
end

CreateView = function ()
    local view = display.newLayer()
    local size = view:getContentSize()

    local shadowLayer = display.newLayer(0, 0, {enable = true, color = cc.c4b(0, 0, 0, 130)})
    view:addChild(shadowLayer)

    local bg = display.newLayer(size.width / 2, size.height / 2, {ap = display.CENTER, bg = RED_DIR.BG})
    local bgSize = bg:getContentSize()
    view:addChild(bg)

    bg:addChild(display.newLayer(0, 0, {enable = true, color = cc.c4b(0, 0, 0, 0)}))

    local title = display.newButton(bgSize.width / 2, bgSize.height - 20, { n =  RED_DIR.TITLE, ap = display.CENTER , scale9 = true })
    bg:addChild(title)
    display.commonLabelParams(title, fontWithColor(5, {text = __('条件奖励'), color = '#ffffff' , paddingW = 30}))
    -- 标题的Label
    --local titleLabel = display.newLabel(titleSize.width / 2, titleSize.height / 2, fontWithColor(5, {text = __('条件奖励'), color = '#ffffff'}))
    --local titleLabelSize = display.getLabelContentSize(titleLabel)
    --
    --if titleLabelSize.width + 60 > titleSize.width then
    --    titleSize.width =  titleLabelSize.width + 60
    --    title:setContentSize(titleSize)
    --    titleLabel:setPosition(cc.p(titleSize.width/2 , titleSize.height/2))
    --end



    local tipLabel = display.newLabel(bgSize.width / 2, bgSize.height - 50, fontWithColor(15, {ap = display.CENTER_TOP, text = __('一次探索的条件奖励只会获得其中一个档位, 达到更多条件可以获得更高奖励'), w = bgSize.width - 70}))
    local tipLabelSize = display.getLabelContentSize(tipLabel)
    bg:addChild(tipLabel)

    local listSize = cc.size(bgSize.width - 50, tipLabel:getPositionY() - tipLabelSize.height - 30)
    local listBg = display.newLayer(bgSize.width / 2, tipLabel:getPositionY() - tipLabelSize.height - 20, {ap = display.CENTER_TOP, size = listSize})
    listBg:addChild(display.newImageView(RED_DIR.LIST_BG, listSize.width / 2, listSize.height / 2, {ap = display.CENTER, scale9 = true, size = listSize}))
    bg:addChild(listBg)

    local col = 1
	local gridViewCellSize = cc.size(listSize.width / col, 118)
    local gridView = CGridView:create(listSize)
    gridView:setAnchorPoint(display.CENTER)
    gridView:setSizeOfCell(gridViewCellSize)
    gridView:setPosition(cc.p(listSize.width / 2, listSize.height / 2))
    gridView:setColumns(col)
    listBg:addChild(gridView)
    
    return {
        view         = view,
        shadowLayer  = shadowLayer,
        gridView     = gridView,
    }
end

CreateCell = function ()
    local cell = CGridViewCell:new()
    local size = cc.size(508, 118)
    cell:setContentSize(size)

    local bgLayer = display.newLayer(size.width / 2, size.height / 2, {bg = RED_DIR.LIST_CELL_BG, ap = display.CENTER})
    local bgSize = bgLayer:getContentSize()
    cell:addChild(bgLayer)

    -- bgLayer:addChild(display.newImageView(_res('ui/battle/battleresult/settlement_bg_reward_white.png'), bgSize.width / 2, bgSize.height / 2, {ap = display.CENTER}))

    local touchLayer = display.newLayer(bgSize.width / 2, bgSize.height / 2, {size = bgSize, ap = display.CENTER, enable = true, color = cc.c4b(0,0,0,0)})
    bgLayer:addChild(touchLayer)

    local titleBg = display.newImageView(RED_DIR.CELL_TITLE, 2, bgSize.height - 5, {ap = display.LEFT_TOP})
    local titleBgSize = titleBg:getContentSize()
    bgLayer:addChild(titleBg, 1)

    local reachConditionLabel = display.newLabel(5, titleBgSize.height / 2, fontWithColor(15, {ap = display.LEFT_CENTER, color = '#96705c', text = __('达成条件数:')}))
    local reachConditionLabelSize = display.getLabelContentSize(reachConditionLabel)
    titleBg:addChild(reachConditionLabel)

    local reachConditionCount = display.newLabel(reachConditionLabel:getPositionX() + reachConditionLabelSize.width, titleBgSize.height / 2, fontWithColor(15, {ap = display.LEFT_CENTER, color = '#96705c', text = '0/0'}))
    titleBg:addChild(reachConditionCount)

    local rewardLayer = display.newLayer(bgSize.width / 2, bgSize.height / 2, {size = bgSize, ap = display.CENTER})
    bgLayer:addChild(rewardLayer, 2)

    local selectImg = display.newImageView(RED_DIR.CELL_SELECT, touchLayer:getPositionX(), touchLayer:getPositionY(), {ap = display.CENTER, scale9 = true, size = cc.size(bgSize.width + 8,bgSize.height + 8)})
    bgLayer:addChild(selectImg)
    selectImg:addChild(display.newLabel(150, bgSize.height / 2 - 20, {ap = display.CENTER, fontSize = 24, color = '#d34400', text = __('当前奖励')}))
    selectImg:setVisible(false)

    cell.viewData = {
        touchLayer          = touchLayer,
        reachConditionCount = reachConditionCount,
        rewardLayer         = rewardLayer,
        selectImg           = selectImg,
    }
    return cell
end

function ExploreSystemConditionRewardView:onDataSourceAdapter(p_convertview,idx)
    local pCell = p_convertview
    local index = idx + 1
    if pCell == nil then
        pCell = CreateCell()
        display.commonUIParams(pCell.viewData.touchLayer, {cb = handler(self, self.onClickCellAction)})
    end
    
    self:updateCell(pCell.viewData, index)

    pCell.viewData.touchLayer:setTag(index)

    return pCell
end

function ExploreSystemConditionRewardView:onClickShadowAction(sender)
    self:setVisible(false)
end

function ExploreSystemConditionRewardView:onClickCellAction(sender)
    local index = sender:getTag()
end

function ExploreSystemConditionRewardView:getViewData()
    return self.viewData_
end

return ExploreSystemConditionRewardView