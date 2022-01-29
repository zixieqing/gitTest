--[[
 * author : liuzhipeng
 * descpt : 活动 周年庆19 抽奖 稀有奖励Mediator
--]]
local Mediator = mvc.Mediator
local Anniversary19LotteryRareMediator = class("Anniversary19LotteryRareMediator", Mediator)
local NAME = "Anniversary19LotteryRareMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager('GameManager')

local Anniversary19LotteryRareCell = require( 'Game.views.anniversary19.Anniversary19LotteryRareCell' )
function Anniversary19LotteryRareMediator:ctor( params, viewComponent )
    self.super:ctor(NAME, viewComponent)
    self.rewardsList = {}
    self.groupId = checkint(params.groupId or 1)
    self.drawnRewards = checktable(params.drawnRewards)
    self.rewardBaseConf = params.rewardBaseConf
    self.rewardConf = params.rewardConf
    self.rewardsData = params.rewardsData
    self.todayIndex = 0
    self.groupData = {}
end


function Anniversary19LotteryRareMediator:InterestSignals()
	local signals = {
        "REFRESH_ANNIVERASARY19_LOTTERY_RARE_VIEW"
	}
	return signals
end

function Anniversary19LotteryRareMediator:ProcessSignal( signal )
	local name = signal:GetName()
	print(name)
    local data = checktable(signal:GetBody())
    if name == "REFRESH_ANNIVERASARY19_LOTTERY_RARE_VIEW" then
        self.groupId = checkint(data.groupId)
        self:InitData()
        self:RefreshGridView()
	end
end

function Anniversary19LotteryRareMediator:Initial( key )
	self.super.Initial(self, key)
	-- 创建CarnieCapsulePoolView
	local viewComponent = require( 'Game.views.anniversary19.Anniversary19LotteryRareView' ).new()
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
function Anniversary19LotteryRareMediator:InitData()
    if self.rewardsData then
        -- 组合活动数据特殊处理
        local rewardsList = {}
        local num = 0
        for n, v in ipairs(self.rewardsData) do
            local temp = {}
            temp.group = checkint(v.group)
            temp.min = num + 1
            if n ~= #self.rewardsData then
                temp.max = num + checkint(v.loop)
            end
            num = num + checkint(v.loop)
            temp.rewards = {}
            for _, rewards in ipairs(v.totalRewards) do
                if checkint(rewards.isRare) > 0 then
                    table.insert(temp.rewards, rewards)
                end
            end
            if checkint(v.group) == checkint(self.groupId) then
                self.todayIndex = n
            end
            table.insert(rewardsList, temp)
        end
        dump(rewardsList)
        self.rewardsList = rewardsList
        return 
    end

    local rewardBaseConf = self.rewardBaseConf or  CommonUtils.GetConfigAllMess('lottery', 'anniversary2')
    local rewardConf = self.rewardConf or CommonUtils.GetConfigAllMess('lotteryPool', 'anniversary2')
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
function Anniversary19LotteryRareMediator:RefreshGridView()
    local viewData =self:GetViewComponent().viewData
    viewData.gridView:setCountOfCell(#self.rewardsList)
    viewData.gridView:reloadData()
end
--[[
列表处理
--]]
function Anniversary19LotteryRareMediator:GridViewDataSource( p_convertview, idx )
	local pCell = p_convertview
    local index = idx + 1
    if not pCell then
    	local cSize = self:GetViewComponent().viewData.gridViewCellSize
		pCell = Anniversary19LotteryRareCell.new(cSize)
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
                display.commonLabelParams(pCell.dateLabel,{text = string.fmt(app.anniversary2019Mgr:GetPoText(__('第_num_轮')), {['_num_'] = data.min}), fontSize = 20, color = '#6c4a31'})
            else
                display.commonLabelParams(pCell.dateLabel,{text = string.fmt(app.anniversary2019Mgr:GetPoText(__('第_num1_-_num2_轮')), {['_num1_'] = data.min, ['_num2_'] = data.max}), fontSize = 20, color = '#6c4a31'})
            end
        else
            display.commonLabelParams(pCell.dateLabel,{text = string.fmt(app.anniversary2019Mgr:GetPoText(__('第_num_轮之后')), {['_num_'] = data.min}), fontSize = 20, color = '#6c4a31'})
        end
        -- 奖励
        pCell.rewardsLayout:removeAllChildren()
        local rewardNum = 1
        for _, v in ipairs(data.rewards) do
            for i = 1, checkint(v.num) do
                local goodsNode = require('common.GoodNode').new({id = v.rewards[1].goodsId, amount = v.rewards[1].num, showAmount = true})
                pCell.rewardsLayout:addChild(goodsNode,3)
                goodsNode:setScale(0.7)
                display.commonUIParams(goodsNode, {animate = false, ap = cc.p(0, 0), po = cc.p(38 + (rewardNum - 1) * 95, 15), cb = function (sender)
                    uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = v.rewards[1].goodsId, type = 1})
                end})
                if self.drawnRewards[tostring(v.id)] and checkint(self.drawnRewards[tostring(v.id)]) <= i then
                    local icon = display.newImageView(app.anniversary2019Mgr:GetResPath('ui/common/raid_room_ico_ready.png'), goodsNode:getContentSize().width/2, goodsNode:getContentSize().height/2)
                    goodsNode:addChild(icon, 10)
                end
                rewardNum = rewardNum + 1
            end
        end

	end,__G__TRACKBACK__)	
	return pCell

end
function Anniversary19LotteryRareMediator:OnRegist(  )
end

function Anniversary19LotteryRareMediator:OnUnRegist(  )
	-- 移除界面
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveDialog(self:GetViewComponent())
end
return Anniversary19LotteryRareMediator