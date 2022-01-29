--[[
成长基金活动活动mediator
--]]
local Mediator = mvc.Mediator
---@class ExchangeActivityCardMediator : Mediator
local ExchangeActivityCardMediator = class("ExchangeActivityCardMediator", Mediator)
local NAME = "activity.growthFund.ExchangeActivityCardMediator"
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager('GameManager')
local cardFragementConf = CommonUtils.GetConfigAllMess('cardFragment' , 'goods')
---@type ExchangeCardCell
local exchangeCardCell = require('Game.views.activity.exchange.ExchangeCardCell')
function ExchangeActivityCardMediator:ctor( params, viewComponent )
    self.super:ctor(NAME, viewComponent)
    local datas = params or {}
    self.activityId = datas.activityId
    self.exchangeQuality = 5 --UR 兑换的品质
    self.exchangeFragmentId = 140002   -- 兑换的碎片id
    self.exchangeFragmentRatio  = 5      --兑换的数量
    self.exchangeFragmentTotalNum   = 10     -- 兑换总数量
    self.exchangeFragmentReadyNum    = 2     -- 已经兑换数量
    self.totalSelectNum = 0            -- 总数量
    self.selectTableNum = {}

end


function ExchangeActivityCardMediator:InterestSignals()
    local signals = {
        POST.ACTIVITY_EXCHANGE_CARD_FRAGMENT_INFO.sglName,
        POST.ACTIVITY_EXCHANGE_CARD_FRAGMENT.sglName
    }
    return signals
end

function ExchangeActivityCardMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local data = signal:GetBody()
    if POST.ACTIVITY_EXCHANGE_CARD_FRAGMENT.sglName == name then
        local requestData = data.requestData
        self.selectTableNum = {}
        self.exchangeFragmentTotalNum = data.exchangeFragmentTotalNum
        self.exchangeFragmentReadyNum = data.exchangeFragmentReadyNum
        local dataRewards = {}
        for i, v in pairs(json.decode(requestData.exchangeStr) ) do
            dataRewards[#dataRewards+1] = {goodsId = i  , num = -v }
        end
        local rewardList = data.rewards
        for i, v in  pairs(rewardList)  do
            dataRewards[#dataRewards+1] = v
        end
        CommonUtils.DrawRewards(dataRewards)
        uiMgr:AddDialog('common.RewardPopup',{rewards = data.rewards , addBackpack = false })
        self:GetFragementTable()
        ---@type ExchangeActivityCardView
        local viewComponent = self:GetViewComponent()
        local viewData = viewComponent.viewData
        viewData.gridView:setCountOfCell(#self.backPackDatas)
        viewData.gridView:reloadData()
        self.totalSelectNum = 0
        if #self.backPackDatas == 0  then
            viewComponent:CreateEmptyView()
        end
        viewComponent:UpdateExchageNum( self.exchangeFragmentTotalNum ,self.exchangeFragmentReadyNum )
        viewComponent:UpdateExchageCardNum( self.totalSelectNum  ,self.exchangeFragmentRatio )
    elseif POST.ACTIVITY_EXCHANGE_CARD_FRAGMENT_INFO.sglName == name then
        self.exchangeFragmentId =  data.exchangeFragmentId or {}
        self.exchangeFragmentRatio =  string.split(data.exchangeFragmentRatio , ":" )[1]
        self.exchangeFragmentTotalNum = data.exchangeFragmentTotalNum
        self.exchangeFragmentReadyNum = data.exchangeFragmentReadyNum
        self:GetFragementTable()

        local viewComponent = self:GetViewComponent()
        local viewData = viewComponent.viewData
        if #self.backPackDatas == 0 then
            viewComponent:CreateEmptyView()
        end
        viewData.gridView:setDataSourceAdapterScriptHandler(handler(self, self.OnDataSource))
        viewData.gridView:setCountOfCell(#self.backPackDatas)
        viewData.gridView:reloadData()
        viewComponent:UpdateUI(self.totalSelectNum , self.exchangeFragmentId , self.exchangeFragmentTotalNum , self.exchangeFragmentReadyNum , self.exchangeFragmentRatio )
    end
end

function ExchangeActivityCardMediator:Initial( key )
    self.super.Initial(self, key)
    local viewComponent = require('Game.views.activity.exchange.ExchangeActivityCardView').new()
    self:SetViewComponent(viewComponent)
    uiMgr:GetCurrentScene():AddDialog(viewComponent)
    viewComponent:setPosition(display.center)
    display.commonUIParams(viewComponent.viewData.exchangeBtn , {cb = handler(self, self.ExchangeCardClick)})
    local viewData = viewComponent.viewData
    display.commonUIParams(viewData.swallowLayer , { cb = function()
          app:UnRegsitMediator(NAME)
    end})
end

function ExchangeActivityCardMediator:GetFragementTable()
    local backPackDatas = {}
    for k,v in pairs(gameMgr:GetUserInfo().backpack) do
        if v.amount > 0 then
            if checkint(v.goodsId)  ~=  self.exchangeFragmentId then
                local data =  cardFragementConf[tostring(v.goodsId)]
                if data then
                    if checkint(data.quality) == self.exchangeQuality  then
                        backPackDatas[#backPackDatas+1] = v
                    end
                end
            end
        end
    end
    self.backPackDatas = clone(backPackDatas)
    table.sort(self.backPackDatas , function( aFragementData ,bFragementData )
        if  checkint(aFragementData.amount) <=   checkint(bFragementData.amount) then
            return false
        end
        return true
    end)
end

function ExchangeActivityCardMediator:OnDataSource(cell , idx  )
    local index = idx + 1
    if not  cell then
        ---@type ExchangeCardCell
        cell = exchangeCardCell.new()
    end
    cell.viewData.touchView:setTag(index)
    cell.viewData.touchView:setOnClickScriptHandler(handler(self, self.CellButtonClick))
    cell.viewData.addBtn :setOnClickScriptHandler(handler(self, self.AddBtnClick))
    cell.viewData.reductionBtn:setOnClickScriptHandler(handler(self, self.ReducesBtnClick))
    cell.viewData.editBox:setOnClickScriptHandler(handler(self, self.NumberBtnClick))
    local isSelect = false
    if self.selectTableNum[tostring(index)] then
        isSelect = true
    end
    cell:UpdateUI(self.backPackDatas[index] ,isSelect , self.selectTableNum[tostring(index)]  )
    return  cell
end
--==============================--
---@Description: Button 的回调事件
---@author : xingweihao
---@date : 2019/4/4 9:52 PM
--==============================--

function ExchangeActivityCardMediator:CellButtonClick(sender)
    local tag = sender:getTag()
    local isSelect = false
    local viewComponent = self:GetViewComponent()
    if  self.selectTableNum[tostring(tag)] then
        self.selectTableNum[tostring(tag)] = nil
    else
        isSelect = true
        self.selectTableNum[tostring(tag)] = 0
    end
    ---@type ExchangeCardCell
    local cell =viewComponent.viewData.gridView:cellAtIndex(tag - 1 )
    if cell then
        cell:UpdateUI(self.backPackDatas[tag], isSelect , self.selectTableNum[tostring(tag)])
    end
    self:UpdateSelectAllNum()
end
--==============================--
---@Description: 兑换事件
---@author : xingweihao
---@date : 2019/4/5 11:44 AM
--==============================--

function ExchangeActivityCardMediator:ExchangeCardClick()
    local  exchangeNum =  self.totalSelectNum / self.exchangeFragmentRatio
    if self.exchangeFragmentTotalNum <= self.exchangeFragmentReadyNum  then
        app.uiMgr:ShowInformationTips(__('兑换次数不足!!!'))
        return
    end
    if exchangeNum > (self.exchangeFragmentTotalNum - self.exchangeFragmentReadyNum)  then
        app.uiMgr:ShowInformationTips(string.fmt(__('已经超过兑换碎片数量，请减少_num_个碎片') ,{ _num_ =  self.totalSelectNum -  (self.exchangeFragmentTotalNum - self.exchangeFragmentReadyNum)  * self.exchangeFragmentRatio  }) )
    elseif self.totalSelectNum % self.exchangeFragmentRatio  ~= 0  then
        if exchangeNum >1  then
            local  reduceNum = self.totalSelectNum -  math.floor(self.totalSelectNum / self.exchangeFragmentRatio) *  self.exchangeFragmentRatio
            app.uiMgr:ShowInformationTips(string.fmt(__('请减少_num_个碎片') ,{ _num_ =  reduceNum  }) )
        else
            local  addNum = math.ceil(self.totalSelectNum / self.exchangeFragmentRatio) *  self.exchangeFragmentRatio - self.totalSelectNum
            app.uiMgr:ShowInformationTips(string.fmt(__('请添加_num_个碎片') ,{ _num_ =  addNum  }) )
        end
    else
        local exchangeTable = {}
        for i, v in pairs(self.selectTableNum) do
            if checkint(v) > 0  then
                exchangeTable[tostring(self.backPackDatas[checkint(i)].goodsId)] = v
            end
        end
        if exchangeNum > 0  then
             self:SendSignal(POST.ACTIVITY_EXCHANGE_CARD_FRAGMENT.cmdName , { exchangeStr  = json.encode(exchangeTable) , activityId = self.activityId})
        else
            app.uiMgr:ShowInformationTips(__('请添加碎片'))
        end
    end
end
--==============================--
---@Description: 更新总的选中碎片的数量
---@author : xingweihao
---@date : 2019/4/5 11:29 AM
--==============================--

function ExchangeActivityCardMediator:UpdateSelectAllNum()
    self.totalSelectNum= self:GetSelectAllNum()
    ---@type ExchangeActivityCardView
    local viewComponent = self:GetViewComponent()
    viewComponent:UpdateExchageCardNum(self.totalSelectNum ,self.exchangeFragmentRatio)
end
function ExchangeActivityCardMediator:GetSelectAllNum()
    local selectNum = 0
    for index, num  in pairs(self.selectTableNum) do
        selectNum = num + selectNum
    end
    return selectNum
end
--==============================--
---@Description: 增加碎片的回调事件
---@author : xingweihao
---@date : 2019/4/5 10:33 AM
--==============================--

function ExchangeActivityCardMediator:AddBtnClick(sender)
    ---@type ExchangeCardCell
    local cell = sender:getParent():getParent()
    local index =  cell.viewData.touchView:getTag()
    local amount = self.backPackDatas[index].amount  -- 碎片的总数量
    local needNum = checkint(self.selectTableNum[tostring(index)])
    if needNum >=  amount  then
        app.uiMgr:ShowInformationTips(__('已超过碎片最大数量'))
        return
    end
    needNum =  needNum +  1
    self.selectTableNum[tostring(index)] = needNum
    cell:UpdateNum(needNum)
    self:UpdateSelectAllNum()
end

--==============================--
---@Description: 减少碎片回调事件
---@author : xingweihao
---@date : 2019/4/5 10:33 AM
--==============================--

function ExchangeActivityCardMediator:ReducesBtnClick(sender)
    ---@type ExchangeCardCell
    local cell = sender:getParent():getParent()
    local index =  cell.viewData.touchView:getTag()
    local needNum = checkint(self.selectTableNum[tostring(index)])
    if needNum <= 0   then
        app.uiMgr:ShowInformationTips(__('已经没有碎片了'))
        return
    end
    needNum =  needNum -  1
    self.selectTableNum[tostring(index)] = needNum
    cell:UpdateNum(needNum)
    self:UpdateSelectAllNum()
end

--==============================--
---@Description: 点击输入时间
---@author : xingweihao
---@date : 2019/4/5 10:33 AM
--==============================--

function ExchangeActivityCardMediator:NumberBtnClick(sender)
    ---@type ExchangeCardCell
    local tempData = {}
    tempData.callback = function(data)
        ---@type ExchangeCardCell
        local cell = sender:getParent():getParent()
        local index =  cell.viewData.touchView:getTag()
        local amount = self.backPackDatas[index].amount  -- 碎片的总数量
        if checkint(data) == 0 then
            return
        end
        if  checkint(data) > amount then
            app.uiMgr:ShowInformationTips(__('没有足够的碎片'))
            return
        end
        self.selectTableNum[tostring(index)] = checkint(data)
        cell:UpdateNum(data)
        self:UpdateSelectAllNum()
    end
    tempData.titleText = __('请输入需要选择的碎片数量')
    tempData.nums = 3
    tempData.model = NumboardModel.freeModel

    local NumKeyboardMediator = require( 'Game.mediator.NumKeyboardMediator' )
    local mediator = NumKeyboardMediator.new(tempData)
    self:GetFacade():RegistMediator(mediator)
end
function ExchangeActivityCardMediator:EnterLayer()
    self:SendSignal(POST.ACTIVITY_EXCHANGE_CARD_FRAGMENT_INFO.cmdName , {activityId = self.activityId})
end
function ExchangeActivityCardMediator:OnRegist(  )
    regPost(POST.ACTIVITY_EXCHANGE_CARD_FRAGMENT_INFO)
    regPost(POST.ACTIVITY_EXCHANGE_CARD_FRAGMENT)
    self:EnterLayer()
end

function ExchangeActivityCardMediator:OnUnRegist(  )
    unregPost(POST.ACTIVITY_EXCHANGE_CARD_FRAGMENT_INFO)
    unregPost(POST.ACTIVITY_EXCHANGE_CARD_FRAGMENT)
    local viewComponent = self:GetViewComponent()
    if viewComponent and (not tolua.isnull(viewComponent)) then
        viewComponent:runAction(cc.RemoveSelf:create())
    end
end


return ExchangeActivityCardMediator