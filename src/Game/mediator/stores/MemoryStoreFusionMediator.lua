--[[
 * author : liuzhipeng
 * descpt : 新游戏商店 - 记忆商店 碎片融合Mediator
]]
local MemoryStoreFusionMediator = class('MemoryStoreFusionMediator', mvc.Mediator)
local NAME = "stores.MemoryStoreFusionMediator"

function MemoryStoreFusionMediator:ctor(params, viewComponent)
    self.args = checktable(params) or {}
    self.qualityId = checkint(params.qualityId)
    self.currency = checkint(params.currency)
    self.fragmentData = {}
    self.super.ctor(self, NAME, viewComponent)
end
-------------------------------------------------
------------------ inheritance ------------------
function MemoryStoreFusionMediator:Initial( key )
    self.super.Initial(self, key)
    
	local viewComponent  = require('Game.views.stores.MemoryStoreFusionView').new()
	viewComponent:setPosition(display.center)
	app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    self:SetViewComponent(viewComponent)
    local viewData = viewComponent.viewData
    -- 绑定
    viewComponent.eaterLayer:setOnClickScriptHandler(handler(self, self.CloseButtonCallback))
    viewComponent:GetViewData().closeBtn:setOnClickScriptHandler(handler(self, self.CloseButtonCallback))
    viewComponent:GetViewData().tipsBtn:setOnClickScriptHandler(handler(self, self.TipsButtonCallback))
    viewComponent:GetViewData().fusionBtn:setOnClickScriptHandler(handler(self, self.FusionButtonCallback))
    viewComponent:GetViewData().listView:setCellUpdateHandler(handler(self, self.OnUpdateGoodsListCellHandler))
    self:InitView()
end

function MemoryStoreFusionMediator:InterestSignals()
    local signals = {
        POST.MEMORY_STORE_FUSION.sglName
	}
	return signals
end
function MemoryStoreFusionMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local body = signal:GetBody()
    if name == POST.MEMORY_STORE_FUSION.sglName then -- 融合
        self:FusionCallback(body)
    end
end

function MemoryStoreFusionMediator:OnRegist()
    regPost(POST.MEMORY_STORE_FUSION)
end
function MemoryStoreFusionMediator:OnUnRegist()
    unregPost(POST.MEMORY_STORE_FUSION)
    -- 移除界面
	local scene = app.uiMgr:GetCurrentScene()
	scene:RemoveDialog(self:GetViewComponent())
end
------------------ inheritance ------------------
-------------------------------------------------

-------------------------------------------------
-------------------- handler --------------------
--[[
关闭按钮点击回调
--]]
function MemoryStoreFusionMediator:CloseButtonCallback( sender )
	PlayAudioByClickClose()
	app:UnRegsitMediator(NAME)
end
--[[
提示按钮点击回调 
--]]
function MemoryStoreFusionMediator:TipsButtonCallback( sender )
    PlayAudioByClickNormal()
    app.uiMgr:ShowIntroPopup({moduleId = '112'})
end
--[[
融合按钮点击回调 
--]]
function MemoryStoreFusionMediator:FusionButtonCallback( sender )
    PlayAudioByClickNormal()
    local convertAmount = self:CalculateConvertAmount()
    if convertAmount <= 0 then
        app.uiMgr:ShowInformationTips(__('碎片不足'))
        return
    end
    self:SendSignal(POST.MEMORY_STORE_FUSION.cmdName, {qualityId = self.qualityId})
end
--[[
列表刷新
--]]
function MemoryStoreFusionMediator:OnUpdateGoodsListCellHandler( cellIndex, cellViewData )
    local fragmentData = self:GetFragmentData()[cellIndex]
    cellViewData.goodsNode:RefreshSelf({goodsId = fragmentData.goodsId, amount = fragmentData.amount})
end
-------------------- handler --------------------
-------------------------------------------------

-------------------------------------------------
-------------------- private --------------------
--[[
初始化view
--]]
function MemoryStoreFusionMediator:InitView()
    self:InitFragmentData()
    self:RefreshListView()
    self:RefreshCurrency()
end
--[[
初始化碎片数据
--]]
function MemoryStoreFusionMediator:InitFragmentData()
    local qualityId = self.qualityId
    local fragmentData = {}
    local backpackData = app.gameMgr:GetUserInfo().backpack

    local breakConf = CommonUtils.GetConfig('card', 'cardBreak', qualityId)
    local breakNum = checkint(breakConf.breakNum) -- 卡牌的突破上限
    for i, v in ipairs(backpackData) do
        local type = CommonUtils.GetGoodTypeById(v.goodsId)
        if type == GoodsType.TYPE_CARD_FRAGMENT then -- 筛选碎片道具
            local goodsConf = CommonUtils.GetConfig('goods', 'goods', v.goodsId)
            if goodsConf then 
                local cardConf = CommonUtils.GetConfig('card', 'card', goodsConf.cardId)
                if checkint(cardConf.qualityId) == qualityId and checkint(v.amount) > 0 then -- 判断卡牌稀有度是否匹配
                    local cardData = app.gameMgr:GetCardDataByCardId(goodsConf.cardId)
                    if cardData and checkint(cardData.breakLevel) == breakNum then --判断是否满破
                        table.insert(fragmentData, clone(v))
                    end
                end
            end
        end
    end
    table.sort(fragmentData, function (a, b)
        return checkint(a.goodsId) < checkint(b.goodsId)
    end)
    self:SetFragmentData(fragmentData)
end
--[[
刷新碎片列表
--]]
function MemoryStoreFusionMediator:RefreshListView()
    local fragmentData = self:GetFragmentData()
    local viewComponent = self:GetViewComponent()
    viewComponent:GetViewData().listView:resetCellCount(#fragmentData)
end
--[[
刷新货币
--]]
function MemoryStoreFusionMediator:RefreshCurrency()
    local viewComponent = self:GetViewComponent()
    local convertAmount = self:CalculateConvertAmount()
    viewComponent:RefreshCurrency(self.currency, convertAmount)
end
--[[
计算转换数量
--]]
function MemoryStoreFusionMediator:CalculateConvertAmount()
    local fragmentData = self:GetFragmentData()
    local totalFragmentAmount = 0
    for i, v in ipairs(fragmentData) do
        totalFragmentAmount = totalFragmentAmount + checkint(v.amount)
    end
    local fragmentConf = CommonUtils.GetConfig('card', 'fragmentConvert', self.qualityId)
    local convertAmount = math.floor(totalFragmentAmount / checkint(fragmentConf.fragmentNum)) * checkint(fragmentConf.convertGoodsNum)
    return convertAmount
end
--[[
融合返回数据处理
--]]
function MemoryStoreFusionMediator:FusionCallback( responseData )
    local consume = checktable(responseData.consume)
    for i, v in ipairs(consume) do
        v.num = -v.num
    end
    CommonUtils.DrawRewards(consume)
    app.uiMgr:AddDialog('common.RewardPopup', {rewards = responseData.rewards})
    self:InitView()
end
-------------------- private --------------------
-------------------------------------------------

-------------------------------------------------
------------------- get / set -------------------
--[[
设置碎片数据
@params fragmentData list 卡牌碎片数据
--]]
function MemoryStoreFusionMediator:SetFragmentData( fragmentData )
    self.fragmentData = checktable(fragmentData)
end
--[[
获取碎片数据
--]]
function MemoryStoreFusionMediator:GetFragmentData()
    return self.fragmentData
end
------------------- get / set -------------------
-------------------------------------------------
return MemoryStoreFusionMediator
