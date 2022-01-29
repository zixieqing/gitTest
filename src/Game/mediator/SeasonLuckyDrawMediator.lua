---
--- Created by xingweihao.
--- DateTime: 27/10/2017 9:53 AM
---
local Mediator                = mvc.Mediator
---@class SeasonLuckyDrawMediator :Mediator
local SeasonLuckyDrawMediator = class("SeasonLuckyDrawMediator", Mediator)
local NAME                    = "SeasonLuckyDrawMediator"
local DRAW_POOL_WAY =           {-- 抽奖池的方式
    ONE = 1, -- 第一种抽奖池
    TWO = 2 -- 第二种抽奖池
}
local SPINE_ANIMATION = {  -- 记录不同NODE 的不同动作
    [tostring(DRAW_POOL_WAY.ONE)] = {
        ['idle'] = 1,
        ['play'] = 2,
        ['end']  = 3,
        ['go']   = 4,
        ['play2'] = 5,
        ['idle2'] = 6
    },
    [tostring(DRAW_POOL_WAY.TWO)] = {
        ['idle'] = 7,
        ['play'] = 8,
        ['end']  = 9,
        ['go']   = 10 ,
        ['play2'] = 11
    }
}
local BUTTON_TAG              = {
    ONEWAY_DRAW_ONE        = 1001,
    ONEWAY_DRAW_TIMES      = 1002,
    TWOWAY_DRAW_ONE        = 1003,
    TWOWAY_DRAW_TIMES      = 1004,
    LOOK_POOL_ONE_REWARD   = 1005, -- 查看第一个奖池的奖励
    LOOK_POOL_TWO_REWARD   = 1006, -- 查看第二个奖池的奖励
    RESET_ONE_POOL         = 1007, -- 重置第一个奖池的奖励
    BACK_CLOSE_VIEW        = 1008, -- 关闭界面的tag 值
    LOOK_POOL_THREE_REWARD = 1009, -- 查看积分奖励的
    RESET_TWO_POOL         = 1010, -- 重置第二个奖池的奖励
    FIRST_POOL_TIP         = 1011, -- 第一个奖池的体会是
    SECOND_POOL_TIP        = 1012, -- 第二个奖池的提示
}
local rewardPoolConfig        = CommonUtils.GetConfigAllMess('rewardPool', 'seasonActivity')
local scoreRewardConfig       = CommonUtils.GetConfigAllMess('scoreReward', 'seasonActivity')
local rewardPoolConsumeConfig       = CommonUtils.GetConfigAllMess('rewardPoolConsume', 'seasonActivity')
---@type UIManager
local uiMgr                   = AppFacade.GetInstance():GetManager("UIManager")
function SeasonLuckyDrawMediator:ctor( param, viewComponent )
    self.super:ctor(NAME, viewComponent)
    self.newYearPoint        = param.newYearPoint or 0
    self.count = table.nums(scoreRewardConfig)
    self.maxnewYearPoint     = 0
    self.sortKey = {}
    self.currentPoolId = 1
    self.scoreRewardReceived = {} -- 奖励领取过的ID
    self.isChange            = false
    self.isAction     = false
    self.isFull = false
end
function SeasonLuckyDrawMediator:InterestSignals()
    local signals = {
        POST.SEASON_ACTIVITY_LOTTERY_HOME.sglName, -- 季活抽奖的home 接口
        POST.SEASON_ACTIVITY_RECEIVESCOER_REWARD.sglName, -- 抽奖或活动按钮
        POST.SEASON_ACTIVITY_RESET_REWARD_POOL.sglName, -- 重置抽奖的卡池

        POST.SEASON_ACTIVITY_LOTTERY.sglName  , -- 季活
        -------------- 自定义刷新时间
        ALREADY_RECEIVE_NEW_YEAR_POINT_EVENT ,
    }
    return signals
end
function SeasonLuckyDrawMediator:Initial( key )
    self.super.Initial(self, key)
    --获取排列材料本的拍了顺序
    ---@type SeasonLuckyDrawView
    self.viewComponent = require('Game.views.SeasonLuckyDrawView').new()
    self.viewComponent:setPosition(display.center)
    self:SetViewComponent(self.viewComponent)
    self.sortKey = self:GetSorceReardsKeyBySortUp()
    local index          = self:GetMaxNewyeasPintIndex()
    self.maxnewYearPoint = checkint( scoreRewardConfig[tostring(index)].newYearPoint)

    local viewData = self.viewComponent.viewData
    display.commonLabelParams(viewData.titleOneBtn , {text = rewardPoolConsumeConfig[tostring(DRAW_POOL_WAY.ONE)].name})
    display.commonLabelParams(viewData.titleTwoBtn , {text = rewardPoolConsumeConfig[tostring(DRAW_POOL_WAY.TWO)].name})

    self:AddReciveTagImage()
    self.viewComponent:CreateSpineAnimation(DRAW_POOL_WAY.ONE)
    self.viewComponent:CreateSpineAnimation(DRAW_POOL_WAY.TWO)
    viewData.oneSpineAnimation:registerSpineEventHandler(handler(self, self.SpineAction), sp.EventType.ANIMATION_COMPLETE)
    viewData.twoSpineAnimation:registerSpineEventHandler(handler(self, self.SpineAction), sp.EventType.ANIMATION_COMPLETE)
    uiMgr:GetCurrentScene():AddDialog( self.viewComponent)
    self:BindClickHandler()
end
--[[
    添加领取阶段的标志
--]]
function SeasonLuckyDrawMediator:AddReciveTagImage()
    local tagSize = cc.size(392,20)
    local viewData = self.viewComponent.viewData
    local topCenterLayer = viewData.topCenterLayer
    local topCenterSize = topCenterLayer:getContentSize()
    local tagLayout = display.newLayer(topCenterSize.width / 2 - 72 , topCenterSize.height / 2 - 13 , { ap = display.CENTER_TOP , size = tagSize } )
    topCenterLayer:addChild(tagLayout)
    local data = {}
    for k , v in pairs(scoreRewardConfig) do
        local percent =   checkint(v.newYearPoint)/self.maxnewYearPoint
        data[#data+1] =  cc.p(percent* tagSize.width , tagSize.height/2 )
    end
    for i =1 ,#data do
        local image = display.newImageView(_res('ui/home/activity/seasonlive/season_loots_bar_spot'))
        image:setPosition(data[i])
        tagLayout:addChild(image)
    end
end

function SeasonLuckyDrawMediator:SpineAction(event)
    if event then
        local index =  event.trackIndex
        local type = checkint(index) > table.nums( SPINE_ANIMATION[tostring(DRAW_POOL_WAY.ONE)] ) and DRAW_POOL_WAY.TWO or  DRAW_POOL_WAY.ONE
        local node =  nil
        if DRAW_POOL_WAY.ONE == type then
            node = self.viewComponent.viewData.oneSpineAnimation
        else
            node = self.viewComponent.viewData.twoSpineAnimation
        end
        if event.animation == "play" or event.animation == "play2" then
            self.isAction = false
            node:setToSetupPose()
            if DRAW_POOL_WAY.ONE == type then
                if self.isFull then
                    node:setAnimation(SPINE_ANIMATION[tostring(type)]['idle2'], 'idle2', false )
                else
                    node:setAnimation(SPINE_ANIMATION[tostring(type)]['idle'], 'idle', true)
                end
                if self.rewards then
                    uiMgr:AddDialog("common.RewardPopup", { rewards = self.rewards ,addBackpack = false })
                    self.rewards = nil
                end
            else
                node:setAnimation(SPINE_ANIMATION[tostring(type)]['idle'], 'idle', true )
                if self.rewards then
                    uiMgr:AddDialog("common.RewardPopup", { rewards = self.rewards ,addBackpack = false })
                    self.rewards = nil
                end
            end
        elseif event.animation == "end" then
            node:setToSetupPose()
            node:setAnimation(SPINE_ANIMATION[tostring(type)]['go'], 'go', false)
        elseif event.animation == "go" then
            node:setToSetupPose()
            node:setAnimation(SPINE_ANIMATION[tostring(type)]['idle'], 'idle', true)
        elseif event.animation == "idle2"  then
            if DRAW_POOL_WAY.ONE == type and (not self.isFull) then
                node:setToSetupPose()
                node:setAnimation(SPINE_ANIMATION[tostring(type)]['idle'], 'idle', true)
            else
                if DRAW_POOL_WAY.TWO == type then
                    node:setAnimation(SPINE_ANIMATION[tostring(type)]['idle'], 'idle', true)
                else
                    node:setAnimation(SPINE_ANIMATION[tostring(type)]['idle2'], 'idle2', false)
                end
            end

        end
    end
end
function SeasonLuckyDrawMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
    if name == POST.SEASON_ACTIVITY_LOTTERY_HOME.sglName then
        self.luckyDrawData = data.progress
        -- 奖池的进度
        for k, v in pairs(self.luckyDrawData) do
            local data        = self:MergeTable({}, v.receivedRewards or "")
            v.receivedRewards = data
        end
        self.scoreRewardReceived = self:MergeTable(self.scoreRewardReceived, data.scoreRewardReceived)
        self:UpdateView()
        for  k ,v  in pairs(rewardPoolConfig) do
            for kk, vv  in pairs(v) do
                if checkint(vv.rewardPoolType) == 1 then -- rewardPoolType 表示卡池是可以重置的
                    local isMax =  self:JudageDrawTimesIsMaxTimesByPoolId(1)
                    if isMax then
                        self.viewComponent.viewData.oneSpineAnimation:setToSetupPose()
                        self.viewComponent.viewData.oneSpineAnimation:setAnimation(SPINE_ANIMATION[tostring(DRAW_POOL_WAY.ONE)].idle2 , 'idle2' , true)
                        self:IsShowResetPoolDisplayByPoolId(k , isMax)
                    end
                end
                break
            end
        end
        self:SetRedPointIsVisble()
    elseif name == POST.SEASON_ACTIVITY_LOTTERY.sglName then
        -- 抽奖的返回

        local requestData = data.requestData
        local body = data
        -- 抽出消耗的道具
        if requestData.rewardPoolId then
            local data           = {}
            local poolId         = requestData.rewardPoolId
            local consumeData    = CommonUtils.GetConfigAllMess('rewardPoolConsume', 'seasonActivity')
            local consumeOneData = consumeData[tostring(poolId)]
            if consumeOneData then
                for k, v in pairs(consumeOneData.goodsConsume) do
                    data[#data + 1] = { goodsId = v.goodsId, num = -checkint(v.num) * checkint(requestData.lotteryTimes) }
                end
            end
            -- 扣除消耗道具
            if table.nums(data) > 0 then
                CommonUtils.DrawRewards(data)
            end
            -- 统计抽奖卡池
            self.luckyDrawData[tostring(poolId)].receivedRewards = self:MergeTable(self.luckyDrawData[tostring( requestData.rewardPoolId)].receivedRewards, body.rewardId)
            self.luckyDrawData[tostring(poolId)].currentTimes       = self.luckyDrawData[tostring(poolId)].currentTimes + checkint(requestData.lotteryTimes)
            CommonUtils.DrawRewards(body.rewards )
            self.rewards = clone(body.rewards)
            self.newYearPoint = body.newYearPoint
            local node  = nil
            if DRAW_POOL_WAY.ONE == poolId then
                node = self.viewComponent.viewData.oneSpineAnimation
            else
                node = self.viewComponent.viewData.twoSpineAnimation
            end
            node:setToSetupPose()
            if checkint(requestData.lotteryTimes)  == 1 then
                node:setAnimation(SPINE_ANIMATION[tostring(poolId)].play , 'play' , false)
            else
                node:setAnimation(SPINE_ANIMATION[tostring(poolId)].play2 , 'play2' , false)
            end
            self.isAction = true
            for  k ,v  in pairs(rewardPoolConfig[tostring(poolId)]) do
                if checkint(v.rewardPoolType) == DRAW_POOL_WAY.ONE then -- rewardPoolType 表示卡池是可以重置的
                    local isMax =  self:JudageDrawTimesIsMaxTimesByPoolId(poolId)
                    if isMax then

                        self:IsShowResetPoolDisplayByPoolId(poolId, isMax)
                    end
                end
                break
            end
            self.currentPoolId = poolId
            self:UpdateView()
            self:SetRedPointIsVisble()
            self.isChange     = true
        end
        -- 更新抽奖池的次数

    elseif name == POST.SEASON_ACTIVITY_RESET_REWARD_POOL.sglName then
        -- 重置卡池的返回
        local progress    = data.progress
        local requestData = data.requestData
        local poolId      = requestData.rewardPoolId
        self.luckyDrawData[tostring(poolId)].resetTimes = checkint(self.luckyDrawData[tostring(poolId)].resetTimes) + 1
        for k, v in pairs(progress) do
            -- 合并数据
            --初始化重制卡池
            if checkint(k) == poolId then
                self.luckyDrawData[k] = {}
                v.receivedRewards = {}
            end
            table.merge(self.luckyDrawData[k], v)
        end
        local node =  nil
        if DRAW_POOL_WAY.ONE == poolId then
            node = self.viewComponent.viewData.oneSpineAnimation
        else
            node = self.viewComponent.viewData.twoSpineAnimation
        end
        self:IsShowResetPoolDisplayByPoolId(poolId , false )
        node:setToSetupPose()
        node:setAnimation(SPINE_ANIMATION[tostring(poolId)]['end'],'end' , false)
        -- 重置过之后直接让界面
        self:UpdateView()

        -- TODO  加刷新的进度条的界面
    elseif name == ALREADY_RECEIVE_NEW_YEAR_POINT_EVENT then
        -- 积分领取后红点提示的状态的状态
        -- 传输数据格式
        --[[
            {
                scoreRewardReceived = {}  -- 记录已经领取的类型,必传改字段
                newYearPoint =  -- 传输的是积分的数量
            }
        --]]
        if data.isChange then
            local scoreRewardReceived = clone(data.scoreRewardReceived or {})
            local newYearPoint        = data.newYearPoint
            self.scoreRewardReceived  = scoreRewardReceived
            self.newYearPoint         = newYearPoint or self.newYearPoint --
            self.scoreRewardReceived  = self:MergeTable(self.scoreRewardReceived, tostring(rewardId))
            self:SetRedPointIsVisble()
        end

        self:SetTopCentrLayerIsVisible(true)
    end

end
function SeasonLuckyDrawMediator:SetTopCentrLayerIsVisible(isVisible)
    local viewData = self.viewComponent.viewData
    viewData.topCenterLayer:setVisible(isVisible)
end
function SeasonLuckyDrawMediator:SetRedPointIsVisble()
    local isRed     = self:JudagePointRedIsTrue()
    local viewData = self.viewComponent.viewData
    local pointImage  = viewData.pointImage
    pointImage:setVisible(isRed)
end
--[[
    判断是否添加红点
--]]
function SeasonLuckyDrawMediator:JudagePointRedIsTrue()
    local isRed = false
    for i =1 , self.count do
        if not  self.scoreRewardReceived[tostring(self.sortKey[i] )] then
            -- 判断该积分奖励是否已经领取  未领取判断是否符合条件
            local newYearPoint = checkint(scoreRewardConfig[tostring(self.sortKey[i] )].newYearPoint)
            if checkint( self.newYearPoint) >= newYearPoint  then
                isRed =  true
                break
            end
        end
    end
    return isRed
end
--[[
    获取到积分的升序表的key
--]]
function SeasonLuckyDrawMediator:GetSorceReardsKeyBySortUp()
    local data = {}
    for i, v in pairs(scoreRewardConfig) do
        data[#data+1] = i
    end
    table.sort(data, function (a, b )
        if a <= b then
            return false
        end
        return true
    end)
    return data
end
--[[
    是否显示重置充值按钮和对话
--]]
function SeasonLuckyDrawMediator:IsShowResetPoolDisplayByPoolId(poolId, isVisible )
    local viewData          = self.viewComponent.viewData

    self.isFull  =  isVisible
    local dialogueLayout = nil
    local buttonLayout = nil
    local dialogueText = nil
    if checkint(poolId) == DRAW_POOL_WAY.ONE then
        dialogueLayout= viewData.dialogueOneLayout
        buttonLayout     = viewData.buttonLayout
        dialogueText =  viewData.dialogueText
    else
        dialogueLayout= viewData.dialogueTwoLayout
        buttonLayout     = viewData.buttonLayoutTwo
        dialogueText =  viewData.dialogueTwoText
    end
    dialogueLayout:setVisible(isVisible)
    buttonLayout:setVisible(not isVisible)
end
--[[
    根据卡池的ID 算出已经的到的积分
--]]
function SeasonLuckyDrawMediator:GetRewardnewyearPoinByPooId(poolId)
    local receivedRewards = self.luckyDrawData[tostring(poolId)].receivedRewards
    local rewardOnePoint  = CommonUtils.GetConfigAllMess('rewardPool', 'seasonActivity')[tostring(poolId)]
    local count           = 0
    for i, v in pairs(receivedRewards or {}) do
        if rewardOnePoint[tostring(i)] then
            local num = checkint(rewardOnePoint[tostring(i)].newYearPoint) * checkint(v)
            count     = count + num
        end
    end
    return count
end
--[[
    更新界面的信息
--]]
function SeasonLuckyDrawMediator:UpdateView()
    local viewData         = self.viewComponent.viewData
    local consumeOneLayout = viewData.consumeOneLayout
    local consumeSize      = viewData.consumeSize
    -- 更新卡池一的消耗
    --local node             = consumeOneLayout:getChildByName("consumeLayout")
    --if node and (not tolua.isnull(node)) then
    --    node:removeFromParent()
    --end
    local  node = self:ReturnNeedGoodsLayoutByPoolId(DRAW_POOL_WAY.ONE)
    node:setPosition(cc.p(consumeSize.width / 2, consumeSize.height / 2))
    consumeOneLayout:addChild(node)
    --更新卡池二的消耗
    local consumeTwoLayout = viewData.consumeTwoLayout
    local  node                   = consumeTwoLayout:getChildByName("consumeLayout")
    --if node and (not tolua.isnull(node)) then
    --    node:removeFromParent()
    --end
    node = self:ReturnNeedGoodsLayoutByPoolId(DRAW_POOL_WAY.TWO)
    node:setPosition(cc.p(consumeSize.width / 2, consumeSize.height / 2))
    consumeTwoLayout:addChild(node)
    local initTimes = viewData.initTimes
    display.commonLabelParams(initTimes, { text = string.format(__('已喂饱:%d'),
                                                                checkint( self.luckyDrawData[tostring(DRAW_POOL_WAY.ONE)].resetTimes))  ,color = "#580606"  })
    self:UpdateLuckyDrawTimes()
    self:UpdateProcessLabel()
end
--[[
    更新进度条的显示
--]]
function SeasonLuckyDrawMediator:UpdateProcessLabel()
    local viewData           = self.viewComponent.viewData
    local progressBarOne     = viewData.progressBarOne
    local progressBarTwo     = viewData.progressBarTwo
    local prograssOneLabel   = viewData.prograssOneLabel
    local prograssTwoLabel   = viewData.prograssTwoLabel
    local prograssThreeLabel = viewData.prograssThreeLabel
    local progressBarThree   = viewData.progressBarThree

    local allOneTimes    = self.luckyDrawData[tostring(DRAW_POOL_WAY.ONE)].maxTimes
    local allTwoTimes    = self.luckyDrawData[tostring(DRAW_POOL_WAY.TWO)].maxTimes
    local rewardOneTimes = self.luckyDrawData[tostring(DRAW_POOL_WAY.ONE)].currentTimes
    local rewardTwoTimes = self.luckyDrawData[tostring(DRAW_POOL_WAY.TWO)].currentTimes
    progressBarOne:setMaxValue(allOneTimes)
    progressBarOne:setValue(allOneTimes - rewardOneTimes )
    progressBarTwo:setMaxValue(allTwoTimes)
    progressBarTwo:setValue(allTwoTimes - rewardTwoTimes)
    progressBarThree:setMaxValue(self.maxnewYearPoint)
    progressBarThree:setValue(self.newYearPoint)
    display.commonLabelParams(prograssOneLabel, { text = string.format(__('饥饿度:%s/%s'), allOneTimes - rewardOneTimes, allOneTimes ) })
    display.commonLabelParams(prograssTwoLabel, { text = string.format(__('饥饿度:%s/%s'), allTwoTimes - rewardTwoTimes, allTwoTimes ) })
    display.commonLabelParams(prograssThreeLabel, { text = string.format(__('压岁钱：%s/%s'), checkint(self.newYearPoint) , checkint(self.maxnewYearPoint)  ) })
end
--[[
    获取到最大的积分的index
--]]
function SeasonLuckyDrawMediator:GetMaxNewyeasPintIndex()
    local maxNum =  0
    local index = 0
    for i =1 , #self.sortKey  do
        local v = scoreRewardConfig[tostring(self.sortKey[i])]
        if maxNum <=  checkint(v.newYearPoint) then
            maxNum = checkint(v.newYearPoint)
            index = i
        end
    end
    return self.sortKey[index]
end
--[[
   更新抽奖次数的显示
--]]
function SeasonLuckyDrawMediator:UpdateLuckyDrawTimes()
    local onePoolTimes = self:GetDrawTimesByPoolId(DRAW_POOL_WAY.ONE)
    local twoPoolTimes = self:GetDrawTimesByPoolId(DRAW_POOL_WAY.TWO)
    local viewData     = self.viewComponent.viewData
    display.commonLabelParams( viewData.mutliTime, { text = string.format(__('吃%s份'), onePoolTimes) })
    display.commonLabelParams( viewData.mutliTimeTwo, { text = string.format(__('吃%s份'), twoPoolTimes) })
end

--[[
    判断抽奖将次数是否充足
--]]
function SeasonLuckyDrawMediator:JudageDrawTimesIsEnoughByPoolIdAndTimes(poolId, needTimes)
    local consumeData    = CommonUtils.GetConfigAllMess('rewardPoolConsume', 'seasonActivity')
    local consumeOneData = consumeData[tostring(poolId)]
    local isEnough       = true
    if consumeOneData then
        for k, v in pairs(consumeOneData.goodsConsume) do
            local num   = CommonUtils.GetCacheProductNum(v.goodsId)
            local times = math.floor(num / checkint(v.num))
            if needTimes > times then
                isEnough = false
                break
            end
        end
    else
        isEnough = false
    end
    return isEnough
end
--[[
    根据卡池ID 返回兑换的次数
--]]
function SeasonLuckyDrawMediator:GetDrawTimesByPoolId(poolId)
    local consumeData    = CommonUtils.GetConfigAllMess('rewardPoolConsume', 'seasonActivity')
    local consumeOneData = consumeData[tostring(poolId)]
    local minTimes       = 10 -- 返回道具的最小值
    if consumeOneData then
        for k, v in pairs(consumeOneData.goodsConsume) do
            local num   = CommonUtils.GetCacheProductNum(v.goodsId)
            local times = math.floor(num / checkint(v.num))
            minTimes    = math.min(minTimes, times)
        end
    end
    local data         = self.luckyDrawData[tostring(poolId)]
    local residueTimes = checkint(data.maxTimes) - checkint(data.currentTimes)
    --获取到最大次数和上线次数进行比较
    minTimes           = math.min(residueTimes, minTimes)
    if minTimes > 1 then
        return minTimes
    else
        return 10
    end
end
--[[
    返回需要卡池的内容
--]]
function SeasonLuckyDrawMediator:ReturnNeedGoodsLayoutByPoolId(poolId)
    local isExit = false
    local viewData = self.viewComponent.viewData
    local consumeLayout = nil

    if poolId == DRAW_POOL_WAY.ONE then
        consumeLayout = viewData.consumeOneLayout
    elseif   poolId == DRAW_POOL_WAY.TWO then
        consumeLayout = viewData.consumeTwoLayout
    end
    local node = consumeLayout:getChildByName('consumeLayout')
    if node then
        isExit  = true
        node:removeFromParent()
    end

    local consumeData    = CommonUtils.GetConfigAllMess('rewardPoolConsume', 'seasonActivity')
    local consumeOneData = consumeData[tostring(poolId)]
    local consumeSize    = self.viewComponent.viewData.consumeSize
    local nums           = table.nums(consumeOneData.goodsConsume)
    local width          = consumeSize.width / nums
    local height         = 108
    local layoutSize     = cc.size(width * nums, height)
    local layout         = display.newLayer(0, 0, { ap = display.CENTER, size = layoutSize })
    local str = 'effects/seasonlive/guang'
    for k, v in pairs(consumeOneData.goodsConsume or {}) do
        k                    = checkint(k)
        local goodNodeLayout = display.newLayer((k - 0.5 ) * width, height / 2, { ap = display.CENTER, size = cc.size(width, height ) })
        local goodNode       = display.newImageView(CommonUtils.GetGoodsIconPathById(v.goodsId))
        goodNode:setTouchEnabled(true)
        goodNode:setOnClickScriptHandler(
        function (sender)
            uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = v.goodsId, type = 1})
        end)
        if isExit and checkint(self.currentPoolId)   == checkint(poolId)  then
            local spineAnimation = sp.SkeletonAnimation:create(
                    string.format('%s.json',str ) ,
                    string.format('%s.atlas',str ) ,
                    1
            )
            spineAnimation:setAnimation(1, 'play', false)
            goodNode:addChild(spineAnimation , 10)
            spineAnimation:setPosition(cc.p(width/ k /2 +30 , height / 2 +10))
        end
        goodNode:setPosition(cc.p(width / 2,  height / 2 + 20))
        goodNodeLayout:setPosition(cc.p((k - 0.5 ) * width, height / 2))
        goodNodeLayout:addChild(goodNode)
        goodNode:setScale(0.7)
        local countNum = CommonUtils.GetCacheProductNum(v.goodsId)
        local data     = {}
        if countNum >= checkint(v.num) then
            data[#data + 1] = fontWithColor('14', { text = string.format("%s/%s", tostring( countNum), tostring(v.num)  ) })
        else
            data[#data + 1] = fontWithColor('14', { color = '#d23d3d', text = string.format("%s", tostring( countNum)   ) })
            data[#data + 1] = fontWithColor('14', { text = string.format("/%s", tostring(v.num)  ) })
        end
        local richLabel = display.newRichLabel(width / 2, 15, { ap = display.CENTER, r = true, c = data })
        goodNodeLayout:addChild(richLabel)
        CommonUtils.AddRichLabelTraceEffect(richLabel)
        layout:addChild(goodNodeLayout)
    end
    layout:setName("consumeLayout")
    return layout
end
--[[
统一绑定事件
--]]
function SeasonLuckyDrawMediator:BindClickHandler()
    local viewData     = self.viewComponent.viewData
    local oneTimeBtn   = viewData.oneTime
    local mutliTime    = viewData.mutliTime
    local oneTimeTwo   = viewData.oneTimeTwo
    local mutliTimeTwo = viewData.mutliTimeTwo
    local resetOneBtn = viewData.resetOneBtn
    local resetTwoBtn = viewData.resetTwoBtn
    local lookPointReards = viewData.lookPointReards
    local commonTwoTip = viewData.commonTwoTip
    local commonOneTip = viewData.commonOneTip

    oneTimeBtn:setTag(BUTTON_TAG.ONEWAY_DRAW_ONE)
    mutliTime:setTag(BUTTON_TAG.ONEWAY_DRAW_TIMES)
    oneTimeTwo:setTag(BUTTON_TAG.TWOWAY_DRAW_ONE)
    mutliTimeTwo:setTag(BUTTON_TAG.TWOWAY_DRAW_TIMES)
    resetOneBtn:setTag(BUTTON_TAG.RESET_ONE_POOL)
    resetTwoBtn:setTag(BUTTON_TAG.RESET_TWO_POOL)
    lookPointReards:setTag(BUTTON_TAG.LOOK_POOL_THREE_REWARD)
    commonOneTip:setTag(BUTTON_TAG.FIRST_POOL_TIP)
    commonTwoTip:setTag(BUTTON_TAG.SECOND_POOL_TIP)
    -- 第一个卡池单抽和多抽事件注册
    oneTimeBtn:setOnClickScriptHandler(handler(self, self.DrawButtonAction))
    mutliTime:setOnClickScriptHandler(handler(self, self.DrawButtonAction))
    -- 第二个卡池单抽和多抽事件注册
    oneTimeTwo:setOnClickScriptHandler(handler(self, self.DrawButtonAction))
    mutliTimeTwo:setOnClickScriptHandler(handler(self, self.DrawButtonAction))



    local lookBtnTwo = viewData.lookBtnTwo
    local lookBtnOne = viewData.lookBtnOne
    lookBtnOne:setTag(BUTTON_TAG.LOOK_POOL_ONE_REWARD)
    lookBtnTwo:setTag(BUTTON_TAG.LOOK_POOL_TWO_REWARD)
    lookBtnOne:setOnClickScriptHandler(handler(self, self.ButtonAction))
    lookBtnTwo:setOnClickScriptHandler(handler(self, self.ButtonAction))
    resetOneBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
    resetTwoBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
    lookPointReards:setOnClickScriptHandler(handler(self, self.ButtonAction))
    commonOneTip:setOnClickScriptHandler(handler(self, self.ButtonAction))
    commonTwoTip:setOnClickScriptHandler(handler(self, self.ButtonAction))
    -- 返回界面按钮
    local navBack = viewData.navBack
    navBack:setTag(BUTTON_TAG.BACK_CLOSE_VIEW)
    navBack:setOnClickScriptHandler(handler(self, self.ButtonAction))
end
--[[
    注册按钮绑定的事件
--]]
function SeasonLuckyDrawMediator:ButtonAction(sender)
    if self.isAction then  return  end
    local tag = sender:getTag()
    if tag == BUTTON_TAG.BACK_CLOSE_VIEW then
        -- 关闭界面
        self:GetFacade():UnRegsitMediator(NAME)
    elseif tag == BUTTON_TAG.LOOK_POOL_ONE_REWARD then
        -- 查看第一个卡池的奖励
        uiMgr:AddDialog("Game.views.LookSeasonActivityRewardView",{type = DRAW_POOL_WAY.ONE ,receivedRewards =  self.luckyDrawData[tostring( DRAW_POOL_WAY.ONE)].receivedRewards })
    elseif tag == BUTTON_TAG.LOOK_POOL_TWO_REWARD then
        -- 查看第二个卡池的奖励
        uiMgr:AddDialog("Game.views.LookSeasonActivityRewardView",{type = DRAW_POOL_WAY.TWO ,receivedRewards =  self.luckyDrawData[tostring( DRAW_POOL_WAY.TWO)].receivedRewards })
    elseif tag == BUTTON_TAG.LOOK_POOL_THREE_REWARD then
        local mediator = require("Game.mediator.SeasonnewYearPointRewardMediator").new({ newYearPoint = self.newYearPoint, scoreRewardReceived = self.scoreRewardReceived })
        self:GetFacade():RegistMediator(mediator)
        self:SetTopCentrLayerIsVisible(false)
    elseif tag == BUTTON_TAG.RESET_TWO_POOL then
        self:SendSignal(POST.SEASON_ACTIVITY_RESET_REWARD_POOL.cmdName, { rewardPoolId = DRAW_POOL_WAY.Two})
    elseif tag == BUTTON_TAG.RESET_ONE_POOL then
        -- 重置第一个卡池
        self:SendSignal(POST.SEASON_ACTIVITY_RESET_REWARD_POOL.cmdName, { rewardPoolId = DRAW_POOL_WAY.ONE })
    elseif tag == BUTTON_TAG.FIRST_POOL_TIP then
        uiMgr:ShowInformationTipsBoard({ targetNode = sender, type = 5, descr =rewardPoolConsumeConfig[tostring(DRAW_POOL_WAY.ONE)].descr  })
    elseif tag == BUTTON_TAG.SECOND_POOL_TIP then
        uiMgr:ShowInformationTipsBoard({ targetNode = sender, type = 5, descr =rewardPoolConsumeConfig[tostring(DRAW_POOL_WAY.TWO)].descr  })
    end
end
--[[
    传入的数组  , 字符串 ，返回加工后的数据
-- ]]
function SeasonLuckyDrawMediator:MergeTable(data, str)
    -- 转化为字符串
    str              = tostring(str)
    local spliteData = table.split(str, ",")
    for k, v in pairs(spliteData) do
        data[v] = checkint(data[v]) + 1
    end
    return data
end


--[[
    根据poolId 判断是否达到最大抽奖次数
--]]
function SeasonLuckyDrawMediator:JudageDrawTimesIsMaxTimesByPoolId(poolId)
    print("poolId = " , poolId )
    local data       = self.luckyDrawData[tostring(poolId)]
    local isMaxTimes = false
    if checkint(data.currentTimes) >= checkint(data.maxTimes) then
        isMaxTimes = true
    end
    return isMaxTimes
end
--[[
    抽奖按钮的事件
--]]
function SeasonLuckyDrawMediator:DrawButtonAction(sender)
    if self.isAction then return end
    local tag    = sender:getTag()
    local times  = 1
    local poolId = DRAW_POOL_WAY.ONE

    if tag == BUTTON_TAG.ONEWAY_DRAW_ONE then
        if self:JudageDrawTimesIsMaxTimesByPoolId(DRAW_POOL_WAY.ONE) then
            uiMgr:ShowInformationTips(__('已经达到最大抽奖次数，请充置抽奖'))
            return
        end
        times = 1
    elseif tag == BUTTON_TAG.ONEWAY_DRAW_TIMES then
        -- 获取到抽奖的方式
        if self:JudageDrawTimesIsMaxTimesByPoolId(DRAW_POOL_WAY.ONE) then
            uiMgr:ShowInformationTips(__('已经达到最大抽奖次数，请充置抽奖'))
            return
        end
        times = self:GetDrawTimesByPoolId(poolId)
    elseif tag == BUTTON_TAG.TWOWAY_DRAW_ONE then
        if self:JudageDrawTimesIsMaxTimesByPoolId(DRAW_POOL_WAY.TWO) then
            uiMgr:ShowInformationTips(__('已经达到最大抽奖次数'))
            return
        end
        times  = 1
        poolId = DRAW_POOL_WAY.TWO
    elseif tag == BUTTON_TAG.TWOWAY_DRAW_TIMES then
        if self:JudageDrawTimesIsMaxTimesByPoolId(DRAW_POOL_WAY.TWO) then
            uiMgr:ShowInformationTips(__('已经达到最大抽奖次数'))
            return
        end
        poolId = DRAW_POOL_WAY.TWO
        -- 获取到抽奖的方式
        times  = self:GetDrawTimesByPoolId(poolId)
    end
    local data  = self.luckyDrawData[tostring(poolId)]
    local distance = checkint(data.maxTimes - data.currentTimes)
    if times > distance then
        uiMgr:ShowInformationTips(__('卡池的抽奖次数不足'))
        return
    end
    local isEnough = self:JudageDrawTimesIsEnoughByPoolIdAndTimes(poolId, times)
    if isEnough then
        local node = nil
        if poolId == DRAW_POOL_WAY.ONE then
            node = self.viewComponent.viewData.oneSpineAnimation
        elseif    poolId == DRAW_POOL_WAY.TWO then
            node = self.viewComponent.viewData.twoSpineAnimation
        end
        print("rewardPoolId = " , poolId)
        self:SendSignal(POST.SEASON_ACTIVITY_LOTTERY.cmdName, { rewardPoolId = poolId, lotteryTimes = times })
    else
        uiMgr:ShowInformationTips(__('抽奖所需的道具不足'))
    end
end

--[[
    进入的时候材料副本的请求
--]]
function SeasonLuckyDrawMediator:EnterLayer()
    self:SendSignal(POST.SEASON_ACTIVITY_LOTTERY_HOME.cmdName, {})
end

function SeasonLuckyDrawMediator:OnRegist()
    regPost(POST.SEASON_ACTIVITY_LOTTERY_HOME)
    regPost(POST.SEASON_ACTIVITY_LOTTERY)
    regPost(POST.SEASON_ACTIVITY_RESET_REWARD_POOL)
    self:EnterLayer()
end

function SeasonLuckyDrawMediator:OnUnRegist()
    unregPost(POST.SEASON_ACTIVITY_HOME)

    unregPost(POST.SEASON_ACTIVITY_LOTTERY)
    unregPost(POST.SEASON_ACTIVITY_RESET_REWARD_POOL)
    self:GetFacade():DispatchObservers(ALREADY_RECEIVE_NEW_YEAR_POINT_EVENT,{scoreRewardReceived = clone(self.scoreRewardReceived ) , newYearPoint = self.newYearPoint ,  isChange = self.isChange })

    if self.viewComponent and (not tolua.isnull(self.viewComponent)) then
        self.viewComponent:runAction(cc.RemoveSelf:create())
    end
end
return SeasonLuckyDrawMediator



