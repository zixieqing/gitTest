--[[
通用道具列表
@params {
	rewards table 道具列表
}
--]]
local CommonGoodList = class('CommonGoodList', function()
    return display.newLayer()
end)

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")

local CreateCell = nil

function CommonGoodList:ctor( ... )
    local args = unpack({...}) or {}

    self:initData(args)
    self:initUI()
    self:initView()

    if not args.notRefresh then
        self:refreshList()
    end
end

function CommonGoodList:initData(args)
    self.size = args.size or display.size
    self.col  = args.col or 1
    self.cellSize = args.cellSize or cc.size(self.size.width / self.col, 110)
    self.goodScale = args.goodScale or 1
    self.goodBg    = args.goodBg
    self.showAmount = checkbool(args.showAmount)
    self.showDefCellAni = args.showDefCellAni
    self.isDisableFilter = args.isDisableFilter
    self.states = {}

    self.rewards = self:checkRewards(args.rewards or {})
    self.scrollCondition = args.scrollCondition

end

function CommonGoodList:checkRewards(rws)
    if self.isDisableFilter then
        return rws
    end
    local rewards = {}
    local temp = {}
    
    local isNeedSort = false
    for i, reward in ipairs(rws) do
        local goodsId = reward.goodsId
        local num = checkint(reward.num)
        local turnGoodsId = reward.turnGoodsId

        -- 1.检查该道具是否是不稳定道具
        if turnGoodsId then
            table.insert(rewards, reward)
            isNeedSort = true
        else
            -- 不是
            if temp[goodsId] then
                temp[goodsId].num = temp[goodsId].num + num
            else
                temp[goodsId] = reward
            end
        end
    end

    for i, v in pairs(temp) do
        table.insert(rewards, v)
    end

    if next(rewards) ~= nil and isNeedSort then
        table.sort(rewards, function (a, b)
            if a == nil then return true end
            if b == nil then return false end

            local aTurnGoodsId = checkint(a.turnGoodsId)
            local bTurnGoodsId = checkint(b.turnGoodsId)
            return aTurnGoodsId < bTurnGoodsId
        end)
    end

    return rewards
end

function CommonGoodList:initView()
    self:setContentSize(self.size)

    local viewData = self:getViewData()
    local gridView = viewData.gridView
    gridView:setDataSourceAdapterScriptHandler(handler(self, self.onDataSourceAdapter))
end

function CommonGoodList:refreshList()
    local viewData = self:getViewData()
    local gridView = viewData.gridView
    local count = #self.rewards
    gridView:setCountOfCell(count)
    if self.scrollCondition then
        gridView:setBounceable(count > self.scrollCondition)
    end
	gridView:reloadData()
end

function CommonGoodList:initUI()
    local CreateView = function ()

        local view = display.newLayer(0,0,{size = self.size})
        self:addChild(view)

        local gridView = CGridView:create(self.size)
        gridView:setSizeOfCell(self.cellSize)
        gridView:setColumns(self.col)
        gridView:setAnchorPoint(display.CENTER)
        display.commonUIParams(gridView, {po = cc.p(self.size.width / 2, self.size.height / 2)})
        view:addChild(gridView)

        return {
            gridView = gridView,
        }
    end

    xTry(function ( )
        self.viewData_ = CreateView()
	end, __G__TRACKBACK__)

end

function CommonGoodList:onDataSourceAdapter(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1

    if pCell == nil then
        pCell = self:createCell()
    else
        pCell:stopAllActions()
        if self.showDefCellAni then
            display.commonUIParams(pCell.viewData.goodNode1, {po = cc.p(self.cellSize.width / 2, self.cellSize.height / 2)})
            pCell.viewData.goodNode1:setScale(self.goodScale)
        end
    end

    local viewData = pCell.viewData

    local reward = self.rewards[index]
    local turnGoodsId = reward.turnGoodsId

    local goodNode1 = viewData.goodNode1
    local goodNode2 = viewData.goodNode2

    goodNode1:setVisible(true)
    goodNode2:setVisible(false)
    goodNode2:setScaleX(1)

    local getGoodState = function (turnGoodsId)
        local state = 0
        if self.states[index] then
            state = 1
        elseif turnGoodsId ~= nil then
            state = 2
        end
        return state
    end

      local state = getGoodState(turnGoodsId)
    if state == 0 then
        goodNode1:RefreshSelf({goodsId = reward.goodsId, amount = reward.num})
        if self.goodBg then
            goodNode1.bg:setTexture(self.goodBg)
        end
    elseif state == 1 then
        goodNode1:RefreshSelf({goodsId = turnGoodsId, amount = checkint(reward.turnGoodsNum)})
        if self.goodBg then
            goodNode1.bg:setTexture(self.goodBg)
        end
    elseif state == 2 then
        goodNode1:RefreshSelf({goodsId = reward.goodsId, amount = reward.num})
        goodNode2:RefreshSelf({goodsId = turnGoodsId, amount = checkint(reward.turnGoodsNum)})
        if self.goodBg then
            goodNode1.bg:setTexture(self.goodBg)
            goodNode2.bg:setTexture(self.goodBg)
        end
        self:showTurnAction(pCell, goodNode1, goodNode2, index)
        self.states[index] = true
    end
    
    return pCell
end

function CommonGoodList:showTurnAction(cell, node1, node2, index)
    local nodeScale1 = node1:getScale()
    cell:runAction(cc.Sequence:create({
        cc.TargetedAction:create(node1 , cc.Sequence:create({
            cc.DelayTime:create(0.2),
            cc.ScaleTo:create(0.5, nodeScale1, nodeScale1),
            cc.CallFunc:create(
                function ()
                    node1:setVisible(false)
                    node2:setScaleX(0)
                    node2:setVisible(true)
                end
            )
        })),
        cc.TargetedAction:create(node2 , cc.TargetedAction:create(node2 , cc.Sequence:create({
            cc.ScaleTo:create(0.5, 1, 1)
        })))

    }))
end

function CommonGoodList:getCellsActionList()
    local viewData = self:getViewData()
    local gridView = viewData.gridView
    local cells = gridView:getCells()
    local acitonList = {}
    for i, cell in ipairs(cells) do
        local node = cell.viewData.goodNode1
        local action = self:createCellAction(node, i)
        table.insert(acitonList, action)
    end
    return acitonList
end

function CommonGoodList:createCellAction(node, index)
    local nodeScale = node:getScale()
    node:setOpacity(0)
    node:setScale(2)

    local aciton = cc.TargetedAction:create(node, cc.Sequence:create({
        cc.DelayTime:create((index - 1) * 2 / 30),
        cc.Spawn:create({
            cc.ScaleTo:create(4/30, nodeScale, nodeScale),
            cc.FadeIn:create(15 / 30)
        })
    }))

    return aciton
end

function CommonGoodList:showCellsAction()
    local actionList = self:getCellActionList()
    self:runAction(cc.Spawn:create(actionList))
end

function CommonGoodList:showCellAction(cell, node, index)
    local nodeScale = node:getScale()
    node:setOpacity(0)
    node:setScale(2)

    cell:runAction(cc.TargetedAction:create(node, cc.Sequence:create({
        cc.DelayTime:create((index - 1) * 2 / 30),
        cc.Spawn:create({
            cc.ScaleTo:create(4/30, nodeScale, nodeScale),
            cc.FadeIn:create(15 / 30)
        })
    })))

    -- cell:runAction(cc.Sequence:create({
    --     cc.TargetedAction:create(node, cc.Sequence:create({
    --         cc.DelayTime:create((index - 1) * 2 / 30),
    --         cc.Spawn:create({
    --             cc.ScaleTo:create(4/30, nodeScale, nodeScale),
    --             cc.FadeIn:create(15 / 30)
    --         })
    --     }))
    -- }))
end

function CommonGoodList:createCell()
    local cell = CGridViewCell:new()
    cell:setContentSize(self.cellSize)
    
    local goodNode1 = require('common.GoodNode').new({ id = EXP_ID, amount = 0, showAmount = self.showAmount, callBack = function(sender)
        uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
    end})
    local goodNode1Size = goodNode1:getContentSize()
    display.commonUIParams(goodNode1, {po = cc.p(self.cellSize.width / 2, self.cellSize.height / 2)})
    goodNode1:setScale(self.goodScale)
    goodNode1:setCascadeOpacityEnabled(true)
    goodNode1:setName('goodNode1')
    cell:addChild(goodNode1)

    local goodNode2 = require('common.GoodNode').new({ id = EXP_ID, amount = 0, showAmount = self.showAmount, callBack = function(sender)
        uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
    end})
    local goodNode2Size = goodNode2:getContentSize()
    goodNode2:setName('goodNode2')
    display.commonUIParams(goodNode2, {po = cc.p(self.cellSize.width / 2, self.cellSize.height / 2)})
    goodNode2:setScale(self.goodScale)
    goodNode2:setCascadeOpacityEnabled(true)
    cell:addChild(goodNode2)
    goodNode2:setVisible(false)

    cell.viewData = {
        goodNode1 = goodNode1,
        goodNode2 = goodNode2
    }

    return cell    
end

function CommonGoodList:setRewards(rewards)
    self.rewards = self:checkRewards(rewards or {})
    self:refreshList()
end

function CommonGoodList:getViewData()
    return self.viewData_
end

return CommonGoodList