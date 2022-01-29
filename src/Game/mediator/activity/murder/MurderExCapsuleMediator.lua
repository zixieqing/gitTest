--[[
 * author : liuzhipeng
 * descpt : 杀人案（19夏活）抽奖 稀有奖励Mediator
--]]
local Mediator = mvc.Mediator
local MurderExCapsuleMediator = class("MurderExCapsuleMediator", Mediator)
local NAME = "MurderExCapsuleMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager('GameManager')

local CarnieExCapsuleCell = require( 'Game.views.summerActivity.carnie.CarnieExCapsuleCell' )
function MurderExCapsuleMediator:ctor( params, viewComponent )
    self.super:ctor(NAME, viewComponent)
    self.rewardsList = {}
    self.groupId = checkint(params.groupId or 1)
    self.drawnRewards = checktable(params.drawnRewards)
    self.todayIndex = 0
    self.groupData = {}
end


function MurderExCapsuleMediator:InterestSignals()
	local signals = {
        "REFRESH_CARNIE_CAPSULE"
	}
	return signals
end

function MurderExCapsuleMediator:ProcessSignal( signal )
	local name = signal:GetName()
	print(name)
    local data = checktable(signal:GetBody())
    if name == "REFRESH_CARNIE_CAPSULE" then
        self.groupId = checkint(data.groupId)
        self:InitData()
        self:RefreshGridView()
	end
end

function MurderExCapsuleMediator:Initial( key )
	self.super.Initial(self, key)
	-- 创建CarnieCapsulePoolView
	local viewComponent = require( 'Game.views.activity.murder.MurderExCapsuleView' ).new()
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
function MurderExCapsuleMediator:InitData()
    local rewardBaseConf = CommonUtils.GetConfigAllMess('rewardBase', 'newSummerActivity')
    local rewardConf = CommonUtils.GetConfigAllMess('rewardPool', 'newSummerActivity')
    
    local rewardsList = {}
    local num = 0
    for k, v in orderedPairs(clone(rewardBaseConf)) do
        local temp = {}
        temp.min = num + 1
        if checkint(k) ~= table.nums(rewardBaseConf) then
            temp.max = num + checkint(v.loop)
        end
        temp.group = v.group
        num = num + checkint(v.loop)
        temp.rewards = {}
        for _, rewards in orderedPairs(clone(rewardConf)) do
            if checkint(v.group) == checkint(rewards.group) and checkint(rewards.isRare) > 0 then
                table.insert(temp.rewards, rewards)
            end
        end
        table.sort(temp.rewards, function (a, b)
            return checkint(a.isRare) > checkint(b.isRare)
        end)
        if checkint(v.group) == checkint(self.groupId) then
            self.todayIndex = checkint(k)
        end
        table.insert(rewardsList, temp)
    end
    self.rewardsList = rewardsList
end
--[[

--]]
function MurderExCapsuleMediator:RefreshGridView()
    local viewData =self:GetViewComponent().viewData
    viewData.gridView:setCountOfCell(#self.rewardsList)
    viewData.gridView:reloadData()
end
--[[
列表处理
--]]
function MurderExCapsuleMediator:GridViewDataSource( p_convertview, idx )
	local pCell = p_convertview
    local index = idx + 1
    if not pCell then
    	local cSize = self:GetViewComponent().viewData.gridViewCellSize
		pCell = CarnieExCapsuleCell.new(cSize)
    end
    xTry(function()
        local data = self.rewardsList[index]
        if self.todayIndex == index then
            pCell.selectedBg:setVisible(true)
        else
            pCell.selectedBg:setVisible(false)
        end
        -- 标题
        if data.max then
            if data.max == data.min then
                display.commonLabelParams(pCell.dateLabel,{text = string.fmt(app.murderMgr:GetPoText(__('第_num_轮')), {['_num_'] = data.min}), fontSize = 20, color = '#6c4a31'})
            else
                display.commonLabelParams(pCell.dateLabel,{text = string.fmt(app.murderMgr:GetPoText(__('第_num1_-_num2_轮')), {['_num1_'] = data.min, ['_num2_'] = data.max}), fontSize = 20, color = '#6c4a31'})
            end
        else
            display.commonLabelParams(pCell.dateLabel,{text = string.fmt(app.murderMgr:GetPoText(__('第_num_轮之后')), {['_num_'] = data.min}), fontSize = 20, color = '#6c4a31'})
        end
        -- 奖励
        pCell.rewardsLayout:removeAllChildren()
        local rewardNum = 1
        for _, v in ipairs(data.rewards) do
            for i = 1, checkint(v.num) do
                local goodsNode = require('common.GoodNode').new({id = v.rewards[1].goodsId, amount = v.rewards[1].num, showAmount = true})
                pCell.rewardsLayout:addChild(goodsNode,3)
                goodsNode:setScale(0.7)
                display.commonUIParams(goodsNode, {animate = false, ap = cc.p(0, 0), po = cc.p(38 + (rewardNum - 1) * 95, 5), cb = function (sender)
                    uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = v.rewards[1].goodsId, type = 1})
                end})
                if self.drawnRewards[tostring(v.id)] and checkint(self.drawnRewards[tostring(v.id)]) <= i then
                    local icon = display.newImageView(app.murderMgr:GetResPath('ui/common/raid_room_ico_ready.png'), goodsNode:getContentSize().width/2, goodsNode:getContentSize().height/2)
                    goodsNode:addChild(icon, 10)
                end
                rewardNum = rewardNum + 1
            end
        end

	end,__G__TRACKBACK__)	
	return pCell

end
function MurderExCapsuleMediator:OnRegist(  )
end

function MurderExCapsuleMediator:OnUnRegist(  )
	-- 移除界面
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveDialog(self:GetViewComponent())
end
return MurderExCapsuleMediator