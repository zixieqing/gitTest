---
--- Created by xingweihao.
--- DateTime: 07/10/2017 2:36 PM
---
local Mediator = mvc.Mediator

local TakeawayCarUpgradeMediator = class("TakeawayCarUpgradeMediator", Mediator)
local NAME = "TakeawayCarUpgradeMediator"
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

---@type TakeawayManager
local takeawayInstance = AppFacade.GetInstance():GetManager('TakeawayManager')
local BTN_CLICK  ={
    UPGRADE_CAR = 1001 ,
}
--[[
    传入的格式为
    { diningCarId = 1  }
--]]
function TakeawayCarUpgradeMediator:ctor( params, viewComponent )
    self.super:ctor(NAME,viewComponent)
    params = params or {}
    self.diningCarId =  checkint(params.diningCarId or 1)
end

function TakeawayCarUpgradeMediator:InterestSignals()
    local signals = {
        SIGNALNAMES.SIGNALNAMES_TAKEAWAY_UPGRADE_CAR,
        "REFRESH_NOT_CLOSE_GOODS_EVENT" ,

    }

    return signals
end
function TakeawayCarUpgradeMediator:ProcessSignal(signal )
    local name = signal:GetName()
    if name == SIGNALNAMES.SIGNALNAMES_TAKEAWAY_UPGRADE_CAR then
        --升级外卖车
        local delayFuncList = nil
        --更新缓存数据,扣除需要的材料与道具
        local diningCarId = checkint(signal:GetBody().requestData.diningCarId)
        local level = 2
        for k,v in pairs(self.datas.diningCar) do
            if checkint(v.diningCarId) == diningCarId then
                local _ ,consumeTable =  self:JuageConsumeEnough(v.level)
                CommonUtils.DrawRewards(consumeTable , false , false , false)
                v.level = checkint(v.level) + 1
                level = v.level
                break
            end
        end
        table.merge(takeawayInstance.orderDatas, self.datas)
        if signal:GetBody().mainExp  then -- 升级后界面是会自动刷新的 因此 这个时候不应该发送刷新道具的事件
            local exp = checkint(signal:GetBody().mainExp) - gameMgr:GetUserInfo().mainExp
            delayFuncList = CommonUtils.DrawRewards({{goodsId = EXP_ID, num = exp}},true , false , false )
        end
        self:UpdateTakeawayCarUpgradeView()
        local RewardResearchAndMakeView = require("Game.views.RewardResearchAndMakeView")
        local layer = RewardResearchAndMakeView.new({type = 4})
        layer:updateData({level = level },delayFuncList)
        layer:setPosition(display.center)
        uiMgr:GetCurrentScene():AddDialog(layer)
        AppFacade.GetInstance():DispatchObservers("UPGRAGE_AND_UNLOCK_CHECK_RED_AND_LEVEL" , {})
    elseif name == "REFRESH_NOT_CLOSE_GOODS_EVENT" then --道具消耗刷新事件
        self:RefreshGoodsNode()
    end
end


function TakeawayCarUpgradeMediator:Initial( key )
    self.super.Initial(self,key)
    local TakeawayCarUpgradeView = require("Game.views.TakeawayCarUpgradeView")
    ---@type  TakeawayCarUpgradeView
    self.viewComponent = TakeawayCarUpgradeView.new()
    self.viewComponent:setPosition(display.center)
    self.viewComponent.viewData.upgradeBtn:setTag(BTN_CLICK.UPGRADE_CAR)
    self.viewComponent.viewData.upgradeBtn:setOnClickScriptHandler(handler(self , self.ButtonAction))
    local mediator = AppFacade.GetInstance():RetrieveMediator("OrderMediator")
    if mediator then
        if mediator:GetViewComponent() then
            self.viewComponent:setPosition(cc.p( display.width - 500 + 465 , display.height/2 ))
            self.viewComponent:runAction(cc.EaseSineOut:create(cc.MoveTo:create(0.2 , cc.p( display.SAFE_R - 500  , display.height/2 ))))
            self.viewComponent:setAnchorPoint(display.RIGHT_CENTER)
            mediator:GetViewComponent():addChild( self.viewComponent ,1)
        else
            uiMgr:GetCurrentScene():AddDialog(self.viewComponent)
        end
    else
        uiMgr:GetCurrentScene():AddDialog(self.viewComponent)
    end
    --uiMgr:GetCurrentScene():AddDialog(self.viewComponent)
    self.datas = takeawayInstance:GetDatas()
    self:UpdateTakeawayCarUpgradeView()
end
--[[
    获取当前外卖车的等级
]]
function TakeawayCarUpgradeMediator:GetNowDiningCarLevel()
    local level = 2
    for k,v in pairs(self.datas.diningCar) do
        if checkint(v.diningCarId) == self.diningCarId  then
            level = checkint(v.level)
            break
        end
    end
    return level
end

--[[
    更新外卖车的显示状态
]]
function TakeawayCarUpgradeMediator:UpdateTakeawayCarUpgradeView( )
    -- 外卖车升级表
    local data = CommonUtils.GetConfigAllMess('diningCarLevelUp', 'takeaway')
    -- 获取当前外卖车的等级
    local level = self:GetNowDiningCarLevel()
    local maxLevel = table.nums(data)
    local nextLevel = level +1
    local curLevelData = data[tostring(level)]
    ---@type  TakeawayCarUpgradeView
    local viewComponent = self.viewComponent
    if nextLevel > maxLevel then -- 已经到达最大等级的时候 所要做的事情
        viewComponent.viewData.fullLevel:setVisible(true)
        viewComponent.viewData.needLayout:setVisible(false)
        viewComponent.viewData.upgradeLevelExp:setVisible(false)
        viewComponent.viewData.upgradeBtn:setVisible(false)
        display.commonLabelParams(viewComponent.viewData.carereteProperty ,
        fontWithColor('6', { text = __('配送时间减少:')  ..tostring(curLevelData.speed *2) ..__('秒') , w = 240 } ))

    else
        local nextLevelData = data[tostring(nextLevel)]
        local expPath = CommonUtils.GetGoodsIconPathById(EXP_ID)
        display.reloadRichLabel(viewComponent.viewData.upgradeLevelExp , { c = {
            fontWithColor('6' , {text = __('（升级后获得') .. "  "}  ) ,
            fontWithColor('14' , {text = nextLevelData.mainExp }) ,
            {img = expPath , scale = 0.2 },
            fontWithColor('6' , {text = '）'}  ) ,
        }})
        CommonUtils.AddRichLabelTraceEffect(viewComponent.viewData.upgradeLevelExp , nil , nil , { 2})
        display.commonLabelParams(viewComponent.viewData.carereteProperty ,
        fontWithColor('6', { text = __('配送时间减少:')  ..tostring(curLevelData.speed  *2) ..__('秒'), w = 240 } ))
        local cousumeGoods = clone(nextLevelData.consumeGoods)
        local goldData = {}
        for i = #cousumeGoods ,1 , -1  do
            if checkint(cousumeGoods[i].goodsId ) == GOLD_ID then
                -- 将消耗的金币排除到选项中
                goldData = table.remove(cousumeGoods ,i)
            end
        end
        local num = table.nums(cousumeGoods)
        -- 首次要删除当前的容器内部的所有道具
        viewComponent.viewData.consumeGoodsLayout:removeAllChildren()
        local needSize = viewComponent.viewData.consumeGoodsLayout:getContentSize()
        local width = needSize.width / num
        -- 添加升级所需的道具
        for i , v in pairs(cousumeGoods) do
            local goodsNode = require('common.GoodNode').new({id = v.goodsId, amount = v.num, showAmount = false})
            goodsNode:setPosition(cc.p(width * ( i - 0.5 ),needSize.height/2))
            local color = "#ffffff"
            if CommonUtils.GetCacheProductNum(v.goodsId)  < checkint(v.num )  then
                color  = "#d23d3d"
                viewComponent.viewData.upgradeBtn:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
                viewComponent.viewData.upgradeBtn:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
            end
            display.commonUIParams(goodsNode, {animate = false, cb = function (sender)
                uiMgr:AddDialog("common.GainPopup", {goodId =v.goodsId})
            end})
            local numLabel = display.newRichLabel(50, -16,{ r = true  , c = {
                fontWithColor('14' , { fontSize = 24 , text =  CommonUtils.GetCacheProductNum(v.goodsId) , color =  color}) ,
                fontWithColor('14' , {fontSize = 24 , text = '/' .. tostring(v.num) })
            }})
            CommonUtils.AddRichLabelTraceEffect(numLabel)
            numLabel:setName("numLabel")
            numLabel.str =   CommonUtils.GetCacheProductNum(v.goodsId) .. '/' .. tostring(v.num)
            goodsNode:addChild(numLabel, 10)
            viewComponent.viewData.consumeGoodsLayout:addChild(goodsNode)
        end
        -- 升级所需的金币
        if table.nums(goldData) > 0 then
            local color = "#ffffff"
            print(" CommonUtils.GetCacheProductNum(goldData.goodsId) " , CommonUtils.GetCacheProductNum(goldData.goodsId) )
            if  checkint(CommonUtils.GetCacheProductNum(goldData.goodsId))   <  checkint(goldData.num )  then
                color  = "#d23d3d"
            end
            display.commonLabelParams(viewComponent.viewData.consumeGoldLabel,fontWithColor('14',{text =  tostring(goldData.num) , color = color  }) )
        end
    end

end
--[[
   判断升级消耗道具是否充足
--]]
function TakeawayCarUpgradeMediator:JuageConsumeEnough(level)
    local consumeTable ={}
    local isEnough = true
    local data = CommonUtils.GetConfigAllMess('diningCarLevelUp', 'takeaway')
    local maxLevel = table.nums(data)
    local nextLevel = checkint(level)+1
    if nextLevel <=  maxLevel then
        local consumedata = clone(data[tostring(nextLevel)]["consumeGoods"])
        for	 k, val  in  pairs(consumedata) do
            table.insert(consumeTable,#consumeTable+1,val)
            local count = CommonUtils.GetCacheProductNum(val.goodsId)
            if checkint(val.num)  > count  then
                isEnough = false
            end
            consumeTable[#consumeTable].num = 0  - consumeTable[#consumeTable].num
        end
    end
    return isEnough ,consumeTable
end
function TakeawayCarUpgradeMediator:ButtonAction(sender)
    PlayAudioClip(AUDIOS.UI.ui_depot_tabchange.id)
    local tag = sender:getTag()
    if tag == BTN_CLICK.UPGRADE_CAR then -- 外卖车升级的回调
        local data = CommonUtils.GetConfigAllMess('diningCarLevelUp', 'takeaway')
        local level = self:GetNowDiningCarLevel()
        local nextLevel = level + 1
        local maxLevel =  table.nums(data)
        if nextLevel <= maxLevel then
            local consumedata = clone(data[tostring(nextLevel)]["consumeGoods"])
            for k , v in pairs(consumedata) do
                if checkint(v.goodId) == GOLD_ID then
                    local owerNum = CommonUtils.GetCacheProductNum(GOLD_ID)
                    if checkint(owerNum) <  checkint(v.num)  then
                        uiMgr:ShowInformationTips(__('金币不足'))
                        return
                    end
                end
            end
            local isEnough , _ = self:JuageConsumeEnough(level)
            if not  isEnough then
                uiMgr:ShowInformationTips(__('升级条件不足'))
                return
            end
            self:SendSignal(COMMANDS.COMMANDS_TAKEAWAY, {action = 'Takeaway/upgradeDiningCar',diningCarId = self.diningCarId})
        end
    end
end


--- 刷新界面的goodsnode显示
function TakeawayCarUpgradeMediator:RefreshGoodsNode()
    local nodes = self.viewComponent.viewData.consumeGoodsLayout:getChildren()
    local level = self:GetNowDiningCarLevel()
    local data = CommonUtils.GetConfigAllMess('diningCarLevelUp', 'takeaway')
    local maxLevel = table.nums(data)
    local nextLevel = level  +1
    if nextLevel  <= maxLevel then
        for k , v in pairs(nodes) do
            if not  tolua.isnull(v) then
                local label = v:getChildByName("numLabel")
                if ( not tolua.isnull(label)) then
                    if data[tostring(nextLevel)]then -- 首先判断下一等级升级数据的是否存在
                        for kk , vv in pairs(data[tostring(level)].consumeGoods) do
                            if checkint(v.goodId) == checkint(vv.goodsId) then
                                local  color = "#ffffff"
                                if checkint(CommonUtils.GetCacheProductNum(v.goodId)) < vv.num then
                                    color = '#d23d3d'
                                end
                                display.reloadRichLabel(label,{
                                    c = {
                                        fontWithColor('14' , { fontSize = 24 ,color =  color,  text =  CommonUtils.GetCacheProductNum(v.goodId) }) ,
                                        fontWithColor('14' , {fontSize = 24 , text = '/' .. tostring( vv.num ) })
                                    }
                                } )
                                CommonUtils.AddRichLabelTraceEffect(label)
                                break
                            end
                        end
                    end
                end
            end
        end

    end
end


function TakeawayCarUpgradeMediator:OnRegist(  )
    local TakeAwayCommand = require( 'Game.command.TakeAwayCommand')
    self:GetFacade():RegistSignal(COMMANDS.COMMANDS_TAKEAWAY, TakeAwayCommand)
end

function TakeawayCarUpgradeMediator:OnUnRegist(  )
    -- 称出命令
    self:GetFacade():UnRegsitSignal(COMMANDS.COMMANDS_TAKEAWAY)
    -- 删除当前的界面
    local scene = uiMgr:GetCurrentScene()
    scene:RemoveDialog(self.viewComponent)
end

return TakeawayCarUpgradeMediator
