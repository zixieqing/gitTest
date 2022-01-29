--[[
提供计时器管理的相关操作方法的管理类

--]]
local scheduler   = require('cocos.framework.scheduler')
local ManagerBase = require( "Frame.Manager.ManagerBase" )
---@class TimerManager
local TimerManager = class('TimerManager',ManagerBase)


local DEFUALT_TIMER_CALLBACK = function(countdown, remindTag,timeNum, params, name)
    --初始提示的逻辑
    if countdown == 0 then
        --时间到，添加小红点
        if remindTag and remindTag > 0 then
            ---@type  DataManager
            app.dataMgr:AddRedDotNofication(tostring(remindTag), remindTag)
        end
    end
    TimerManager.GetInstance():GetFacade():DispatchObservers(COUNT_DOWN_ACTION, {countdown = countdown, tag = remindTag, timeNum = timeNum, datas = params, timerName = name})
end


-- ----------------------------------------------------------------------------
-- timerInfo
-- ----------------------------------------------------------------------------

local TimerInfo = {}

--[[
添加一个计时器的信息逻辑
@params 参数 {id,tag, countdown, isStop, isDelete}
--]]
function TimerInfo:New(params)
	local this = {}
    local isUnLosetime  = params.isLosetime ~= false  and true  -- 是否不忽略忽略时间加成
	setmetatable( this, {__index = TimerInfo} )
    this.name      = params.name
    this.remindTag = params.tag --提示的tag
    this.datas     = params.datas --额外数据
    this.timeNum   = (params.countdown + 10)
    if isLosetime then
        this.countdown = (params.countdown + 10) --多出10秒用于防止问题计算
    else
        this.countdown = params.countdown
        this.timeNum   = params.countdown
    end
    this.callback  = params.callback
    this.isStop    = (params.isStop or false)
    this.isDelete  = (params.isDelete or false)
    this.autoDelete = (params.autoDelete or false)
    self.isUpdating = false -- 全局标识 是否在updating
	return this
end
--[[
是否两个计时器相等
@param timerinfo 目标计时器
--]]
function TimerInfo:Equals( timerInfo )
    local equal = false
    if self.name == timerInfo.name then
        equal = true
    end
    return equal
end


-- ----------------------------------------------------------------------------
-- clocker
-- ----------------------------------------------------------------------------

---@class TimerManager.Clocker
local Clocker = {}

function Clocker.new(updateCallback, updaterInterval)
    local this = {
        updateCallback_  = updateCallback,
        updaterInterval_ = updaterInterval or 1,
    }
    setmetatable(this, {__index = Clocker})
    return this
end

function Clocker:update()
    if self.updateCallback_ then
        self.updateCallback_()
    end
end

function Clocker:start()
    if self.updateHandler_ == nil then
        self.updateHandler_ = scheduler.scheduleGlobal(function()
            self:update()
        end, self.updaterInterval_)
        self:update()
    end
end

function Clocker:stop()
    if self.updateHandler_ then
        scheduler.unscheduleGlobal(self.updateHandler_)
        self.updateHandler_ = nil
    end
end

--[[
    -- @param updateCallback 更新回调
    -- @param updaterInterval 更新间隔（默认1秒）
]]
---@return TimerManager.Clocker
function TimerManager.CreateClocker(updateCallback, updaterInterval)
    return Clocker.new(updateCallback, updaterInterval)
end


-------------------------------------------------
-- manager method

TimerManager.DEFAULT_NAME = 'TimerManager'
TimerManager.instances_   = {}


function TimerManager.GetInstance(instancesKey)
    instancesKey = instancesKey or TimerManager.DEFAULT_NAME

	if not TimerManager.instances_[instancesKey] then
		TimerManager.instances_[instancesKey] = TimerManager.new(instancesKey)
	end
	return TimerManager.instances_[instancesKey]
end


function TimerManager.Destroy(instancesKey)
	instancesKey = instancesKey or TimerManager.DEFAULT_NAME
	if TimerManager.instances_[instancesKey] then
        TimerManager.instances_[instancesKey]:release()
        TimerManager.instances_[instancesKey] = nil
	end
end


-------------------------------------------------
-- life cycle

function TimerManager:ctor(instancesKey)
    self.super.ctor(self)

	if TimerManager.instances_[instancesKey] then
		funLog(Logger.INFO, "注册相关的facade类型" )
    else
        self:initial()
	end
end


function TimerManager:initial()
    self.timerInfos_   = {}        -- 所有的计时器集合
    self.startTime_    = os.time() -- 获取当前的系统时间
    self.isUpdating_   = false     -- 是否在update处理中
    self.interval_     = 1.0
    self.updateHandle_ = nil
end


function TimerManager:release()
    self:Stop()
end


-------------------------------------------------
-- public

function TimerManager:SetInterval(interval)
    self.interval_ = interval
end


function TimerManager:Start(interval)
    if not self.updateHandle_ then
        self.interval_     = interval or 1
        self.updateHandle_ = scheduler.scheduleGlobal(handler(self, self.onTimerScheduler_), self.interval_)
    end
end


function TimerManager:Stop()
    if self.updateHandle_ then
        scheduler.unscheduleGlobal(self.updateHandle_)
        self.updateHandle_ = nil
        self.timerInfos_   = {}
        self.interval_     = 0
    end
end


function TimerManager:RetriveTimer(timerName)
    local timerInfo = nil
    if timerName then
        for i, v in pairs(self.timerInfos_) do
            if tostring(v.name) == timerName then
                timerInfo = v
                break
            end
        end
    end
    return timerInfo
end

---11
function TimerManager:StopTimer(timerName)
    local timerInfo = self:RetriveTimer(timerName)
    if timerInfo then
        timerInfo.isStop = true
    end
end


function TimerManager:ResumeTimer(timerName)
    local timerInfo = self:RetriveTimer(timerName)
    if timerInfo then
        timerInfo.isStop = false
    end
end


--[[
--添加一个记时器的逻辑功能，用来进行递减的逻辑功能
--params = {
-- name     : string 计时器的name 必须值
-- countdown: interger 总数量
-- callback : function 回调函数
-- isStop   : boolean 是否是暂停状态
-- isDelete : booldean 是否是需要删除的对象
--}
--]]
function TimerManager:AddTimer(params)
    if params.callback == nil then
        params.callback = DEFUALT_TIMER_CALLBACK
    end
    local timerInfo = self:RetriveTimer(params.name)
    if timerInfo == nil then
        timerInfo = TimerInfo:New(params)
        table.insert(self.timerInfos_, timerInfo)
    end
    return timerInfo
end


function TimerManager:RemoveTimer(timerName)
    if timerName then
        for i = #self.timerInfos_, 1, -1 do
            local timerInfo = self.timerInfos_[i]
            if tostring(timerInfo.name) == timerName then
                timerInfo.isDelete = true
                if not self.isUpdating_ then
                    -- 不在update 直接移除
                    table.remove(self.timerInfos_, i)
                end
                break
            end
        end
    end
end


--[[
    内部的定时器
    @param dt 时间间隔
--]]
function TimerManager:onTimerScheduler_(dt)
    if next(self.timerInfos_) ~= nil then
        self.isUpdating_ = true

        local timeScale = cc.Director:getInstance():getScheduler():getTimeScale()
        if timeScale <= 0 then timeScale = 1 end --防止加速后计时器变化

        ---清除需要删除的计时器
        local curTime = os.time()
        local span = curTime - self.startTime_ 
        if span >= 0.9 then
            for i = #self.timerInfos_, 1, -1 do
                if self.timerInfos_[i].isDelete then
                    table.remove(self.timerInfos_, i) --删除所有需要清除的计时器
                end
            end

            local v = nil
            for i = #self.timerInfos_, 1, -1 do
                v = self.timerInfos_[i]
                if (not v.isStop ) then
                    local countdown = v.countdown
                    countdown = countdown - span

                    if countdown < 0 then
                        countdown = 0
                    end
                    if countdown == 0 then
                        v.isStop = true --不在进行倒计时了，但存有计时器实例的逻辑
                        if v.autoDelete then
                            table.remove(self.timerInfos_, i)
                        end
                    end
                    v.countdown = countdown
                    if v.callback then --回调计时器
                        v.callback(countdown, v.remindTag, v.timeNum,v.datas, v.name)
                    end
                end
            end
            
            self.startTime_ = curTime
        end

    else
        self.startTime_ = os.time()
    end

    -- 循环结束
    self.isUpdating_ = false
end


--==============================--
---@Description: timeStr 与当前时间的差值
---@author : xingweihao
---@date : 2018/12/15 1:34 AM
--==============================--
function TimerManager:GetTimeSeverTime(timeStr)
    local serverTimeSecond = getServerTime()
    local timeData  = string.split(string.len(timeStr) > 0 and timeStr or '00:00', ':')
    local serverTimestamp  = os.date('!%Y-%m-%d _H_:_M_:00', serverTimeSecond + getServerTimezone())
    local timestamp   = string.fmt(serverTimestamp, {_H_ = timeData[1], _M_ = timeData[2]})
    local timeSecond  = timestampToSecond(timestamp) - getServerTimezone()
    return timeSecond
end


return TimerManager
