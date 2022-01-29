---@class ScratcherPreviewMediator : Mediator
---@field viewComponent ScratcherPreviewView
local ScratcherPreviewMediator = class('ScratcherPreviewMediator', mvc.Mediator)

local NAME = "ScratcherPreviewMediator"

function ScratcherPreviewMediator:ctor(params, viewComponent)
	self.super.ctor(self, NAME, viewComponent)
    self.data = checktable(params) or {}

    local collectted = {}
    for k, v in pairs(self.data.collected) do
        collectted[#collectted+1] = clone(v)
    end
    self.collectted = collectted
end

function ScratcherPreviewMediator:Initial(key)
	self.super.Initial(self, key)
	local scene = app.uiMgr:GetCurrentScene()
	local viewComponent = require('Game.views.scratcher.ScratcherPreviewView').new(self.ticketGoodsId)
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	scene:AddDialog(viewComponent)
    local viewData = viewComponent.viewData
    
    viewData.probabilityBtn:setOnClickScriptHandler(handler(self, self.ProbabilityButtonCallback)) 
    viewData.eaterLayer:setOnClickScriptHandler(handler(self, self.OnBackBtnClickHandler))
    self:RefreshRewardListView()
end

function ScratcherPreviewMediator:OnRegist()
end

function ScratcherPreviewMediator:OnUnRegist()
	local scene = app.uiMgr:GetCurrentScene()
	scene:RemoveGameLayer(self.viewComponent)
end

function ScratcherPreviewMediator:InterestSignals()
    local signals = {
	}
	return signals
end

function ScratcherPreviewMediator:ProcessSignal(signal)
    local name = signal:GetName()
	local body = signal:GetBody()
	-- dump(body, name)
end

function ScratcherPreviewMediator:OnBackBtnClickHandler( sender )
	PlayAudioByClickClose()
	
    app:UnRegsitMediator(NAME)
end

function ScratcherPreviewMediator:RefreshRewardListView(  )
    local lotteryData = self:ConvertLotteryData()
    local viewData = self.viewComponent.viewData
    local rewardListView = viewData.rewardListView
    rewardListView:removeAllNodes()
    rewardListView:insertNodeAtLast(self:CreateRewardsLayout(lotteryData.rareRewards, true))
    rewardListView:insertNodeAtLast(self:CreateRewardsLayout(lotteryData.commonRewards, false))
    rewardListView:reloadData()
end

function ScratcherPreviewMediator:CreateRewardsLayout( rewardsData, isRare )
    for k, v in pairs(rewardsData) do
        v.left = tonumber(v.appear)
        for i = #self.collectted, 1, -1 do
            local reward = v.rewards
            local collectted = self.collectted[i]
            if reward.goodsId == collectted.goodsId and reward.num == collectted.num then
                if 0 < v.left then
                    v.left = v.left - 1
                    table.remove(self.collectted, i)
                    if 0 == v.left then
                        break
                    end
                end
            end
        end
    end
    local viewData = self.viewComponent.viewData
    local cellSize = cc.size(120, 151)
    local width    = viewData.rewardListViewSize.width
    local distance = ( viewData.rewardListViewSize.width - cellSize.width * 5) / 2
    local layout = nil
    local str = __('普通')
    if isRare then
        str  = __('稀有')
    end
    local count = #rewardsData
    if count > 0 then
        local fiveCount = math.ceil(count /5)  * 5
        local height =  math.ceil(count /5)* cellSize.height + 35
        local layoutSize = cc.size(width,height)
        layout = display.newLayer(width/2 , height, {color1 = cc.r4b() , size =layoutSize })
        local label = display.newLabel(distance -5 , height -20 , fontWithColor('8' ,{ap = display.LEFT_CENTER ,  text = str}))
        layout:addChild(label)
        local line = display.newImageView(_res('ui/common/season_loots_line_1'), width/2 , height -35)
        layout:addChild(line)
        for i, v in pairs(rewardsData) do
            local gridCellLayout = self:CreateGridCell(v, isRare)
            local heightline  = math.floor(((fiveCount -  i-0.5 + 1)/5))+0.5
            local widthline = (i-0.5 )%5
            gridCellLayout:setPosition(cc.p( cellSize.width*widthline  +distance , heightline *cellSize.height ))
            layout:addChild(gridCellLayout)
        end
    end
    return layout or CLayout:create(cc.size(0,0))
end

function ScratcherPreviewMediator:ConvertLotteryData()
    local lotteryData = {
        rareRewards = {},
        commonRewards = {}
    }
    for k, v in orderedPairs(self.data.lotteryPool) do
        if type(v) == "table" then
            if "0" == v.rare then
                -- 普通
                table.insert(lotteryData.commonRewards, v)
            else
                -- 稀有
                table.insert(lotteryData.rareRewards, v)
            end
        end
    end
    return lotteryData
end

function ScratcherPreviewMediator:CreateGridCell(data, isRare)
    data = data or {}
    local bgImage = nil
    if isRare then
        bgImage = display.newImageView(_res('ui/anniversary19/lottery/season_loots_label_goods_rare.png')) 
    else
        bgImage = display.newImageView(_res('ui/home/activity/seasonlive/season_loots_label_goods')) 
    end
    local bgSize = bgImage:getContentSize()
    local bgLayout = display.newLayer(bgSize.width/2 ,bgSize.height/2 ,{ap = display.CENTER , size = bgSize , color1 = cc.r4b()})
    bgLayout:addChild(bgImage)
    bgImage:setPosition(cc.p(bgSize.width/2 ,bgSize.height/2))
    local goodsId = data.rewards.goodsId
    local goodsNode = require("common.GoodNode").new({id = goodsId ,showAmount = true , num = checkint(data.rewards.num) })
    bgLayout:addChild(goodsNode)
    goodsNode:setScale(0.8)
    goodsNode:setPosition(cc.p(bgSize.width/2 , bgSize.height -60))
    local left = data.left
    local numLabel = display.newLabel(bgSize.width/2 , 25 ,fontWithColor('6',
                             { text = string.format("%d/%d" , left, checkint(data.appear))}))
    bgLayout:addChild(numLabel)
    display.commonUIParams(goodsNode, {animate = false, cb = function (sender)
        app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = data.rewards.goodsId, type = 1})
    end})
    if left == 0 then
        local blackImage = display.newImageView(_res('ui/home/activity/seasonlive/season_loots_label_goods_bk'), bgSize.width/2 ,bgSize.height/2)
        bgLayout:addChild(blackImage)
    end
    return bgLayout
end

--[[
概率按钮点击回调
--]]
function ScratcherPreviewMediator:ProbabilityButtonCallback( sender )
    PlayAudioByClickNormal()
    local rate = {}
    for i, v in orderedPairs(self.data.lotteryPool) do
        if type(v) == "table" then
            table.insert(rate, {descr = CommonUtils.GetConfig('goods', 'goods', v.rewards.goodsId).name, rate = v.rate * 100})
        end
    end
    local capsuleProbabilityView = require( 'Game.views.drawCards.CapsuleProbabilityView' ).new({rate = rate})
    display.commonLabelParams(capsuleProbabilityView.viewData_.title, fontWithColor(18, {text = __('概率')}))
    local scene = app.uiMgr:GetCurrentScene()
    scene:AddDialog(capsuleProbabilityView)
end

return ScratcherPreviewMediator
