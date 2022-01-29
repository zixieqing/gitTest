
---
--- Created by xingweihao.
--- DateTime: 27/10/2017 9:53 AM
---
local Mediator = mvc.Mediator
---@class ActivitySeasonLiveMediator :Mediator
local ActivitySeasonLiveMediator = class("ActivitySeasonLiveMediator", Mediator)
local NAME = "ActivitySeasonLiveMediator"
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local scoreRewardConfig = CommonUtils.GetConfigAllMess('scoreReward','seasonActivity')
local BUTTON_TAG             = {
    THEME_PREVIEW_BTN        = 1101, --显示主题
    BATTLE_BTN               = 1102, -- 进入季活的战斗按钮
    EXCHANGE_BTN             = 1103, -- 抽奖兑换积分按钮
    RECEIVE_NEWYEASPOINT_BTN = 1104, -- 兑换积分奖励的tag
    GUN_REWARD_BTN           = 1105, -- 领取开门炮
}

--[[
{
 seasonActivityData = {}
}
--]]
function ActivitySeasonLiveMediator:ctor( param, viewComponent )
    self.super:ctor(NAME,viewComponent)
    param = param or {}
    param.seasonActivityData = param.seasonActivityData or {}
    -- 活动的背景图片
    param.seasonActivityData.activityId = param.seasonActivityData.activityId
    param.seasonActivityData.leftSeconds = param.seasonActivityData.leftSeconds or 0
    self.seasonActivityData = param.seasonActivityData
    self.activityId = param.seasonActivityData.activityId
    -- 时间的倒计时
    self.newYearPoint = 0
    self.sortKey = {}
    self.count = table.nums(scoreRewardConfig)
    self.scoreRewardReceived = {}
end
function ActivitySeasonLiveMediator:InterestSignals()
    local signals = {
        POST.SEASON_ACTIVITY_HOME.sglName ,
        ALREADY_RECEIVE_NEW_YEAR_POINT_EVENT,
    }
    return signals
end
function ActivitySeasonLiveMediator:Initial( key )
    self.super.Initial(self,key)
    ---@type ActivitySeasonLiveView
    self.viewComponent = require('Game.views.ActivitySeasonLiveView').new()
    self.viewComponent:setPosition(display.center)
    self.sortKey = self:GetSorceReardsKeyBySortUp()
    self:SetViewComponent(self.viewComponent)
    self:BindClickHandler()
    local viewData_ = self.viewComponent.viewData_
    self.viewComponent:runAction(
        cc.RepeatForever:create(
            cc.Sequence:create(
                cc.DelayTime:create(1) ,
                cc.CallFunc:create(
                    function ()
                        self:UpdateCountDownTime()
                    end
                )
            )
        )
    )
    local  isRecieve =  app.activityMgr:JudageSeasonFoodIsReward()
    if isRecieve ==1 then
        local redImage  = viewData_.rewardGunBtn:getChildByName("redTwoImage")
        if redImage then
            redImage:setVisible(true)
        end
    end
    self:UpdateCountDownTime()
end

--[[
    获取到积分的升序表的key
--]]
function ActivitySeasonLiveMediator:GetSorceReardsKeyBySortUp()
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

function ActivitySeasonLiveMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
    if name == POST.SEASON_ACTIVITY_HOME.sglName then
        self.scoreRewardReceived = self:MergeTable(self.scoreRewardReceived , data.scoreRewardReceived or "")
        gameMgr:GetUserInfo().seasonActivityTickets = data.ticketReceived
        self.newYearPoint = data.newYearPoint
        self:UpdateView()
        self:SetRedPointIsVisble()
    elseif name == ALREADY_RECEIVE_NEW_YEAR_POINT_EVENT then
        -- 积分领取后红点提示的状态的状态
        -- 传输数据格式
        --[[
            {
                scoreRewardReceived = {}  -- 记录已经领取的类型,必传改字段
                newYearPoint =  -- 传输的是积分的数量
                isChange =  true -- 是否发生改变
            }
        --]]
        if data.isChange then
            local scoreRewardReceived = clone(data.scoreRewardReceived or {})
            local newYearPoint        = data.newYearPoint
            self.scoreRewardReceived  = scoreRewardReceived
            self.newYearPoint         = newYearPoint or self.newYearPoint --
            self.scoreRewardReceived  = self:MergeTable(self.scoreRewardReceived, tostring(rewardId))
            self:SetRedPointIsVisble()
            local viewData_ = self.viewComponent.viewData_
            display.reloadRichLabel(viewData_.intergalLabel,{
                c = {
                    fontWithColor('4' ,{fontSize = 24, color = '490403',  text = __('压岁钱：')} ) ,
                    fontWithColor('4', {fontSize = 24 ,color = '490403',  text  = self.newYearPoint})
                }
            })

        end
        local showRemindIcon = 0
        local viewData_ = self.viewComponent.viewData_
        showRemindIcon = app.activityMgr:JudageSeasonFoodIsReward()
        if  showRemindIcon ==1 then
            self:GetFacade():DispatchObservers(ACTIVITY_RED_REGRESH_EVENT ,{ activityId = self.activityId ,showRemindIcon = showRemindIcon })
            local redImage  = viewData_.rewardGunBtn:getChildByName("redTwoImage")
            if redImage then
                redImage:setVisible(true)
            end
            return
        else
            local redImage  = viewData_.rewardGunBtn:getChildByName("redTwoImage")
            if redImage then
                redImage:setVisible(false )
            end
        end
        self:GetFacade():DispatchObservers(ACTIVITY_RED_REGRESH_EVENT ,
                   { activityId = self.activityId ,showRemindIcon = gameMgr:GetUserInfo().tips.seasonActivity  })
    end
end
function ActivitySeasonLiveMediator:SetRedPointIsVisble()
    local isRed     = self:JudagePointRedIsTrue()
    if isRed then
        gameMgr:GetUserInfo().tips.seasonActivity = 1
    else
        gameMgr:GetUserInfo().tips.seasonActivity = 0
    end
    local viewData_ = self.viewComponent.viewData_
    local redImage  = viewData_.redImage
    redImage:setVisible(isRed)

end
--[[
    更新界面的信息
--]]
function ActivitySeasonLiveMediator:UpdateView()
    local viewData_ = self.viewComponent.viewData_
    viewData_.avatorImage:setTexture(CommonUtils.GetGoodsIconPathById('107032') )
    viewData_.avatorImage:setScale(0.8)
    display.commonLabelParams(viewData_.ruleLabel, {fontSize =20 ,  text =  __('帮助酵母菌夺回年夜饭吧！将年夜饭交还给酵母菌就可以获得丰厚奖励和压岁钱，累积足够的压岁钱后将获得意外惊喜！\n活动期间"开门炮"道具在每日的12,18,21点可在活动界面领取,每个时段只可领取一次。') })
    display.reloadRichLabel(viewData_.intergalLabel,{
        c = {
            fontWithColor('4' ,{fontSize = 24, color = '490403',  text = __('压岁钱：')} ) ,
            fontWithColor('4', {fontSize = 24 ,color = '490403',  text  = self.newYearPoint})
        }
    })

end
function ActivitySeasonLiveMediator:UpdateCountDownTime()
    local viewData_ = self.viewComponent.viewData_
    local countDownTable = string.formattedTime(self.seasonActivityData.leftSeconds) or 0
    local countDoenText = ""
    if checkint(countDownTable.h) > 0 then
        if checkint(countDownTable.h) > 24 then
            local hours = countDownTable.h%24
            local days = math.floor(countDownTable.h/24)
            countDoenText = string.format(__('%d天%d小时') , days , hours )
        else
            countDoenText = string.format('%02d:%02d:%02d' , checkint(countDownTable.h ) , checkint(countDownTable.m ) ,checkint(countDownTable.s ) )
        end
    else
        countDoenText = string.format('%02d:%02d:%02d' , checkint(countDownTable.h ) , checkint(countDownTable.m ) ,checkint(countDownTable.s ) )

    end
    display.reloadRichLabel(viewData_.timeLabel, {
        c = {
            {text = __('剩余时间:'), fontSize = 22, color = '#ffffff', outline = '#5b3c25', outlineSize = 1},
            {text = countDoenText, fontSize = 24, color = '#ffe9b4', ttf = true, font = TTF_GAME_FONT, outline = '#5b3c25', outlineSize = 1}
        }

    })
    CommonUtils.AddRichLabelTraceEffect(viewData_.timeLabel , nil , 2 , {2})
end
--[[
    传入的数组  , 字符串 ，返回加工后的数据
-- ]]
function ActivitySeasonLiveMediator:MergeTable(data, str)
    -- 转化为字符串
    str              = tostring(str)
    local spliteData = table.split(str, ",")
    for k, v in pairs(spliteData) do
        data[v] = checkint(data[v]) + 1
    end
    return data
end

--[[
    判断是否添加红点
--]]
function ActivitySeasonLiveMediator:JudagePointRedIsTrue()
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
统一绑定事件
--]]
function ActivitySeasonLiveMediator:BindClickHandler()
    local viewData_ = self.viewComponent.viewData_
    viewData_.battleBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
    viewData_.exchangeBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
    viewData_.themePreViewBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
    display.commonUIParams( viewData_.intergalLayout, { cb = handler(self, self.ButtonAction) })
    --viewData_.intergalLayout:setOnClickScriptHandler(handler(self, self.ButtonAction))
    viewData_.rewardGunBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
end
--[[
    按钮执行的事件
--]]
function ActivitySeasonLiveMediator:ButtonAction(sender)
    local tag = sender:getTag()
    if tag == BUTTON_TAG.BATTLE_BTN then   -- 进入季活
        AppFacade.GetInstance():RetrieveMediator('Router'):Dispatch({name = "HomeMediator"} , { name = "SeasonLiveMediator" , params = { activityId = self.activityId}})
    elseif tag == BUTTON_TAG.EXCHANGE_BTN then -- 兑换积分界面
        local mediator = require("Game.mediator.SeasonLuckyDrawMediator").new({newYearPoint =  self.newYearPoint })
        self:GetFacade():RegistMediator(mediator)
    elseif tag == BUTTON_TAG.THEME_PREVIEW_BTN then -- 欣赏主题界面
        uiMgr:AddDialog("Game.views.PreviewThemeView",{goodsId = self:GetAvatorId()})
    elseif tag == BUTTON_TAG.RECEIVE_NEWYEASPOINT_BTN then
        local mediator = require("Game.mediator.SeasonnewYearPointRewardMediator").new({ newYearPoint =  self.newYearPoint  , scoreRewardReceived = self.scoreRewardReceived })
        self:GetFacade():RegistMediator(mediator)
    elseif tag == BUTTON_TAG.GUN_REWARD_BTN then
        local mediator = require("Game.mediator.ActivitySeasonWelfareMediator").new()
        self:GetFacade():RegistMediator(mediator)
    end
end
--[[
    获取avatar 的Image
--]]
function ActivitySeasonLiveMediator:GetAvatorId()
    return 270013
end
--[[
    进入的时候材料副本的请求
--]]
function ActivitySeasonLiveMediator:EnterLayer()
    self:SendSignal(POST.SEASON_ACTIVITY_HOME.cmdName, {})
end

function ActivitySeasonLiveMediator:OnRegist()
    regPost(POST.SEASON_ACTIVITY_HOME)
    self:EnterLayer()
end

function ActivitySeasonLiveMediator:OnUnRegist()
    unregPost(POST.SEASON_ACTIVITY_HOME)
end

return ActivitySeasonLiveMediator



