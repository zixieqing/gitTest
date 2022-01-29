--[[
游乐园（夏活）特典奖池mediator   
--]]
local Mediator = mvc.Mediator
local CarnieExCapsuleMediator = class("CarnieExCapsuleMediator", Mediator)
local NAME = "CarnieExCapsuleMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
local summerActMgr = app.summerActMgr

local CarnieExCapsuleCell = require( 'Game.views.summerActivity.carnie.CarnieExCapsuleCell' )
function CarnieExCapsuleMediator:ctor( params, viewComponent )
    self.super:ctor(NAME, viewComponent)
    self.exRewards = {}
    self.groupId = checkint(params.groupId or 1)
    self.rareGoods = checktable(params.rareGoods)
    self.todayIndex = 0
    self.groupData = {}
end


function CarnieExCapsuleMediator:InterestSignals()
	local signals = {
        "REFRESH_CARNIE_CAPSULE"
	}
	return signals
end

function CarnieExCapsuleMediator:ProcessSignal( signal )
	local name = signal:GetName()
	print(name)
    local data = checktable(signal:GetBody())
    if name == "REFRESH_CARNIE_CAPSULE" then
        self.groupId = checkint(data.groupId)
        self:InitData()
        self:RefreshGridView()
	end
end

function CarnieExCapsuleMediator:Initial( key )
	self.super.Initial(self, key)
	-- 创建CarnieCapsulePoolView
	local viewComponent = require( 'Game.views.summerActivity.carnie.CarnieExCapsuleView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	local scene = uiMgr:GetCurrentScene()
    scene:AddDialog(viewComponent)
    
    viewComponent.viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.GridViewDataSource))
    self:InitData()
    self:RefreshGridView()
end
--[[
初始化数据
--]]
function CarnieExCapsuleMediator:InitData()
    local rewardConf = CommonUtils.GetConfigAllMess('rewardPool', 'summerActivity')
    local rewards = {}
    for k, v in orderedPairs(rewardConf) do
        local temp = {}
        for key, val in orderedPairs(v) do
            if checkint(val.isRare) == 1 then
                table.insert(temp, val)
            end
        end
        if checkint(k) == checkint(self.groupId) then
            self.todayIndex = #rewards + 1
        end
        table.insert(rewards, temp)
        table.insert(self.groupData, k)
    end
    self.exRewards = rewards
end
--[[

--]]
function CarnieExCapsuleMediator:RefreshGridView()
    local viewData =self:GetViewComponent().viewData
    viewData.gridView:setCountOfCell(#self.exRewards)
    viewData.gridView:reloadData()
end
--[[
列表处理
--]]
function CarnieExCapsuleMediator:GridViewDataSource( p_convertview, idx )
	local pCell = p_convertview
    local index = idx + 1
    if not pCell then
    	local cSize = self:GetViewComponent().viewData.gridViewCellSize
		pCell = CarnieExCapsuleCell.new(cSize)
    end
    xTry(function()
        -- 标题
        if self.todayIndex == index then
            display.commonLabelParams(pCell.dateLabel,{text = summerActMgr:getThemeTextByText(__('今日特典扭蛋')), fontSize = 20, color = '#d23d3d'})
            pCell.selectedBg:setVisible(true)
        elseif self.todayIndex < index then
            display.commonLabelParams(pCell.dateLabel,{text = string.fmt(summerActMgr:getThemeTextByText(__('第_num_天')), {['_num_'] = index}), fontSize = 20, color = '#6c4a31'})
            pCell.selectedBg:setVisible(false)
        elseif self.todayIndex > index then
            display.commonLabelParams(pCell.dateLabel,{text = string.fmt(summerActMgr:getThemeTextByText(__('第_num_天（已结束）')), {['_num_'] = index}), fontSize = 20, color = '#6c4a31'})
            pCell.selectedBg:setVisible(false)
        end
        -- 奖励
        local rewards = self.exRewards[index]
        pCell.rewardsLayout:removeAllChildren()
        local rewardNum = 1
        for _, v in ipairs(rewards) do
            for i = 1, checkint(v.num) do
                local goodsNode = require('common.GoodNode').new({id = v.rewards[1].goodsId, amount = v.rewards[1].num, showAmount = true})
                pCell.rewardsLayout:addChild(goodsNode,3)
                goodsNode:setScale(0.7)
                display.commonUIParams(goodsNode, {animate = false, ap = cc.p(0, 0), po = cc.p(38 + (rewardNum - 1) * 95, 5), cb = function (sender)
                    uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = v.rewards[1].goodsId, type = 1})
                end})
                local k = self.groupData[index]
                if self.rareGoods[tostring(k)] and self.rareGoods[tostring(k)][tostring(v.id)] then
                    if checkint(self.rareGoods[tostring(k)][tostring(v.id)]) <= i then
                        local icon = display.newImageView(_res('ui/common/raid_room_ico_ready.png'), goodsNode:getContentSize().width/2, goodsNode:getContentSize().height/2)
                        goodsNode:addChild(icon, 5)
                    end
                end
                rewardNum = rewardNum + 1
            end
        end

	end,__G__TRACKBACK__)	
	return pCell

end
function CarnieExCapsuleMediator:OnRegist(  )
end

function CarnieExCapsuleMediator:OnUnRegist(  )
	-- 移除界面
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveDialog(self:GetViewComponent())
end
return CarnieExCapsuleMediator