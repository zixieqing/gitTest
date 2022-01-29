--[[
游乐园（夏活）今日蛋池mediator   
--]]
local Mediator = mvc.Mediator
local CarnieCapsulePoolMediator = class("CarnieCapsulePoolMediator", Mediator)
local NAME = "CarnieCapsulePoolMediator"

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
local summerActMgr = app.summerActMgr

function CarnieCapsulePoolMediator:ctor( params, viewComponent )
	self.super:ctor(NAME, viewComponent)
    self.rewards        = checktable(params.rewards)
    self.groupId        = checkint(params.groupId or 1)
    self.rareGoods      = checktable(params.rareGoods)
	self.leftNum        = 0  -- 剩余扭蛋
	self.totalNum       = 0  -- 扭蛋总数 
	self.exRewards      = {} -- 特典扭蛋池
	self.commonRewards  = {} -- 普通扭蛋池
	self:InitData(self.rewards)
	
end


function CarnieCapsulePoolMediator:InterestSignals()
	local signals = {
	}
	return signals
end

function CarnieCapsulePoolMediator:ProcessSignal( signal )
	local name = signal:GetName()
	print(name)
	local datas = checktable(signal:GetBody())
end

function CarnieCapsulePoolMediator:Initial( key )
	self.super.Initial(self, key)
	-- 创建CarnieCapsulePoolView
	local viewComponent = require( 'Game.views.summerActivity.carnie.CarnieCapsulePoolView' ).new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
	local scene = uiMgr:GetCurrentScene()
	scene:AddDialog(viewComponent)
	-- 绑定事件
	viewComponent.viewData.probabilityBtn:setOnClickScriptHandler(handler(self, self.ProbabilityButtonCallback))
	viewComponent.viewData.forenoticeBtn:setOnClickScriptHandler(handler(self, self.ForenoticeButtonCallback))
	self:InitView()
end
--[[
初始化数据
--]]
function CarnieCapsulePoolMediator:InitData( data )	
	local exRewards = {}
	local commonRewards = {}
	local leftNum = 0
	local totalNum = 0
	for i, v in ipairs(data) do
		-- 判断是否为特殊奖励
		if checkint(v.isRare) == 1 then
			table.insert(exRewards, v)
		else
			table.insert(commonRewards, v)
		end
		-- 剩余扭蛋
		leftNum = leftNum + checkint(v.stock)
		-- 扭蛋总数
		totalNum = totalNum + checkint(v.num)
	end
    self.exRewards = exRewards
	self.commonRewards = commonRewards
	self.leftNum = leftNum
	self.totalNum = totalNum
end
--[[
初始化页面
--]]
function CarnieCapsulePoolMediator:InitView()
	local viewData = self:GetViewComponent().viewData
	local rewardListView = viewData.rewardListView
	-- 刷新剩余数目
    viewData.leftNumTitle:setString(string.fmt(summerActMgr:getThemeTextByText(__('剩余: _num1_/_num2_')), {['_num1_'] = self.leftNum, ['_num2_'] = self.totalNum}))
    -- 动画
    viewData.forenoticeImg:runAction(
        cc.RepeatForever:create(
            cc.Sequence:create(
                cc.RotateTo:create(0.1, 15),
                cc.RotateTo:create(0.2, -15),
                cc.RotateTo:create(0.2, 15),
                cc.RotateTo:create(0.2, -15),
                cc.RotateTo:create(0.1, 0),
                cc.DelayTime:create(2)
            )
        )
    )
	-- 创建列表
    local unCommonLayout =self:CreateLayoutByUnCommon(true)
    local commonLayout =self:CreateLayoutByUnCommon(false)
    rewardListView:insertNodeAtLast(unCommonLayout)
    rewardListView:insertNodeAtLast(commonLayout)
    rewardListView:reloadData()

    local accRewardConf = CommonUtils.GetConfigAllMess('overTimeReward', 'summerActivity')['1'] or {}
    local goodsId = accRewardConf.rewards[1].goodsId
    local cardPreviewBtn     = viewData.cardPreviewBtn
    cardPreviewBtn:setVisible(true)
    local cardPreviewData = {confId = goodsId}
    cardPreviewBtn:RefreshUI(cardPreviewData)
end
--[[
创建列表
@Params isTrue bool 是否为特典扭蛋
--]]
function CarnieCapsulePoolMediator:CreateLayoutByUnCommon(isTrue)
    local viewData = self:GetViewComponent().viewData
    local cellSize = cc.size(120, 151)
    local width    = viewData.listViewLayoutSize.width
    local distance = ( viewData.listViewLayoutSize.width - cellSize.width * 5) / 2
    local layout = nil
    local data = self.commonRewards or {}
    local str = summerActMgr:getThemeTextByText(__('普通扭蛋'))
    if isTrue then
        str  = summerActMgr:getThemeTextByText(__('今日特典扭蛋'))
        data = self.exRewards or {}
    end
    local count = #data
    if count > 0 then
        local fiveCount = math.ceil(count /5)  * 5
        local height =  math.ceil(count /5)* cellSize.height + 35
        local layoutSize = cc.size(width,height)
        layout = display.newLayer(width/2 , height, {color1 = cc.r4b() , size =layoutSize })
        local label = display.newLabel(distance -5 , height -20 , fontWithColor('8' ,{ap = display.LEFT_CENTER ,  text = str}))
        layout:addChild(label)
        local line = display.newImageView(_res('ui/common/season_loots_line_1'),width/2 , height -35)
        layout:addChild(line)
        for i, v in pairs(data) do
            local gridCellLayout = self:CreateGridCell(v)
            local heightline  = math.floor(((fiveCount -  i-0.5 + 1)/5))+0.5
            local widthline = (i-0.5 )%5
            gridCellLayout:setPosition(cc.p( cellSize.width*widthline  +distance , heightline *cellSize.height ))
            layout:addChild(gridCellLayout)
        end
    end
    return layout or CLayout:create(cc.size(0,0))
end
--[[
创建列表Cell
--]]
function CarnieCapsulePoolMediator:CreateGridCell(data)
    data  = data or {}
    local bgImage = display.newImageView(_res('ui/home/activity/seasonlive/season_loots_label_goods'))
    local bgSize = bgImage:getContentSize()
    local bgLayout = display.newLayer(bgSize.width/2 ,bgSize.height/2 ,{ap = display.CENTER , size = bgSize , color1 = cc.r4b()})
    bgLayout:addChild(bgImage)
    bgImage:setPosition(cc.p(bgSize.width/2 ,bgSize.height/2))
    local goodsNode = require("common.GoodNode").new({id = data.rewards[1].goodsId ,showAmount = true , num = checkint(data.rewards[1].num) })
    bgLayout:addChild(goodsNode)
    goodsNode:setScale(0.8)
    goodsNode:setPosition(cc.p(bgSize.width/2 , bgSize.height -60))
    local numLabel = display.newLabel(bgSize.width/2 , 25 ,fontWithColor('6',
                             { text = string.format("%d/%d" , checkint(data.stock), checkint(data.num))}))
    bgLayout:addChild(numLabel)
    display.commonUIParams(goodsNode, {animate = false, cb = function (sender)
        uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = data.rewards[1].goodsId, type = 1})
    end})
    if checkint(data.stock) == 0 then
        local blackImage = display.newImageView(_res('ui/home/activity/seasonlive/season_loots_label_goods_bk'), bgSize.width/2 ,bgSize.height/2)
        bgLayout:addChild(blackImage)
    end
    return bgLayout
end
--------------------------------------------------------------
------------------------- 点击回调 ----------------------------
--[[
概率按钮点击回调
--]]
function CarnieCapsulePoolMediator:ProbabilityButtonCallback( sender )
	print('概率')
end
--[[
特典预告按钮点击回调
--]]
function CarnieCapsulePoolMediator:ForenoticeButtonCallback( sender )
	AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = 'CarnieCapsulePoolMediator'}, {name = 'summerActivity.carnie.CarnieExCapsuleMediator', params = {groupId = self.groupId, rareGoods = self.rareGoods}})
end
------------------------- 点击回调 ----------------------------
--------------------------------------------------------------

function CarnieCapsulePoolMediator:OnRegist(  )
end

function CarnieCapsulePoolMediator:OnUnRegist(  )
	-- 移除界面
	local scene = uiMgr:GetCurrentScene()
	scene:RemoveDialog(self:GetViewComponent())
end
return CarnieCapsulePoolMediator