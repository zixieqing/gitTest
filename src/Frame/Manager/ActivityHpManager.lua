--[[
 * author : liuzhipeng
 * descpt : 20春活 管理器
]]
local BaseManager       = require('Frame.Manager.ManagerBase')
---@class ActivityHpManager : ManagerBase
local ActivityHpManager = class('ActivityHpManager', BaseManager)

-------------------------------------------------
-- manager method

ActivityHpManager.DEFAULT_NAME = 'ActivityHpManager'
ActivityHpManager.instances_   = {}

function ActivityHpManager.GetInstance(instancesKey)
    instancesKey = instancesKey or ActivityHpManager.DEFAULT_NAME

    if not ActivityHpManager.instances_[instancesKey] then
        ActivityHpManager.instances_[instancesKey] = ActivityHpManager.new(instancesKey)
    end
    return ActivityHpManager.instances_[instancesKey]
end


function ActivityHpManager.Destroy(instancesKey)
    instancesKey = instancesKey or ActivityHpManager.DEFAULT_NAME

    if ActivityHpManager.instances_[instancesKey] then
        ActivityHpManager.instances_[instancesKey]:release()
        ActivityHpManager.instances_[instancesKey] = nil
    end
end


-------------------------------------------------
-- life cycle

function ActivityHpManager:ctor(instancesKey)
    self.super.ctor(self)

    if ActivityHpManager.instances_[instancesKey] then
        funLog(Logger.INFO, "注册相关的facade类型")
    else
        self:initial()
    end
end


function ActivityHpManager:initial()
    self.hpDataDict = {}
    self.hpDefineMap = {}
end


function ActivityHpManager:release()
    for i, v in pairs(self.hpDataDict) do
        if v.hpPurchaseCmd then
            app:UnRegistObserver(v.hpPurchaseCmd.sglName, self)
        end
    end
end


-------------------------------------------------

--[[
    isAddHp     : bool     在 GoodPurchaseNode 中使用，是否 允许购买体力。
    isGetMore   : bool     在 AddPowerPopup 中购买次数用光后，是否 显示“获取更多”。
    isDrawType  : bool     在 AddPowerPopup 中显示“领取”；在 GoodPurchaseNode 中，根据剩余时间判断是否可领取。
    tipCallback : table    在 CommonTipBoard 中的使用，定义提示的数据展示。
]]
function ActivityHpManager:GetHpDefineMap(hpGoodsId)
    if not self.hpDefineMap[hpGoodsId] then
        -- 因为有动态id，所以map没有就进来动态找一遍
        local templateHpDefineMap = {
            [HP_ID]                                    = { isAddHp = true,  isGetMore  = false, tipCallback = handler(self, self.GetCommonHpRestoreTipCallback)   },
            [app.summerActMgr:getTicketId()]           = { isAddHp = true,  isGetMore  = false, tipCallback = handler(self, self.GetCommonHpRestoreTipCallback)   },
            [app.ptDungeonMgr:GetHPGoodsId()]          = { isAddHp = true,  isGetMore  = true , tipCallback = handler(self, self.GetCommonHpRestoreTipCallback)   },
            [app.murderMgr:GetMurderHpId()]            = { isAddHp = true,  isGetMore  = true , tipCallback = handler(self, self.GetCommonHpRestoreTipCallback)   },
            [app.anniversary2019Mgr:GetHPGoodsId()]    = { isAddHp = true,  isGetMore  = true , tipCallback = handler(self, self.GetCommonHpRestoreTipCallback)   },
            [app.anniversary2019Mgr:GetSuppressHPId()] = { isAddHp = false, isGetMore  = false, tipCallback = handler(self, self.GetAnniv2019SuppressTipCallback) },
            [app.springActivity20Mgr:GetHPGoodsId()]   = { isAddHp = true,  isGetMore  = true , tipCallback = handler(self, self.GetCommonHpRestoreTipCallback)   },
            [app.anniv2020Mgr:getHpGoodsId()]          = { isAddHp = false, isDrawType = true , tipCallback = handler(self, self.GetAnniv2020JumpGridTipCallback) },
        }
        self.hpDefineMap[hpGoodsId] = templateHpDefineMap[hpGoodsId]
    end
    return self.hpDefineMap[hpGoodsId]
end


function ActivityHpManager:GetCommonHpRestoreTipCallback()
    return {
        tipInfoCount = 3,
        
        getTipDescr = function(tipIndex, hpGoodsId)
            if tipIndex == 1 then
                local goodsName = GoodsUtils.GetGoodsNameById(hpGoodsId)
                return string.fmt(__('下点__name__恢复:'), {__name__ = goodsName})

            elseif tipIndex == 2 then
                local goodsName = GoodsUtils.GetGoodsNameById(hpGoodsId)
                return string.fmt(__('全部__name__回满:'), {__name__ = goodsName})

            elseif tipIndex == 3 then
                return __('今日可购次数:')
            end
            return 'descr err: out of bound'
        end,
        
        getTipValue = function(tipIndex, hpGoodsId)
            if tipIndex == 1 then
                local hpData = self:GetHpDataByHpGoodsId(hpGoodsId) or {}
                local nextSeconds = checkint(hpData.hpNextRestoreTime)
                if hpGoodsId == HP_ID then
                    nextSeconds = checkint(app.gameMgr:GetUserInfo().nextHpSeconds)
                end
                return string.formattedTime(nextSeconds, '%02i:%02i:%02i')
                
            elseif tipIndex == 2 then
                local hpData = self:GetHpDataByHpGoodsId(hpGoodsId) or {}
                local totalSeconds = checkint(hpData.hpMaxRestoreTime)
                if hpGoodsId == HP_ID then
                    totalSeconds = checkint(app.gameMgr:GetUserInfo().hpCountDownLeftSeconds)
                end
                return string.formattedTime(totalSeconds, '%02i:%02i:%02i')

            elseif tipIndex == 3 then
                local totalBuyLimit = app.activityHpMgr:GetHpMaxPurchaseTimes(hpGoodsId)
                local buyRestTimes  = app.activityHpMgr:GetHpPurchaseAvailableTimes(hpGoodsId)
                if hpGoodsId == HP_ID then
                    totalBuyLimit = checkint(CommonUtils.getVipTotalLimitByField('buyHpLimit'))
                    buyRestTimes  = checkint(app.gameMgr:GetUserInfo().buyHpRestTimes)
                end
                return totalBuyLimit == -1 and __('无限制') or string.fmt('%1 / %2', buyRestTimes, totalBuyLimit)
            end
            return 'value err: out of bound'
        end,
    }
end


function ActivityHpManager:GetAnniv2019SuppressTipCallback()
    return {
        tipInfoCount = 1,
        
        getTipDescr = function(tipIndex, hpGoodsId)
            if tipIndex == 1 then
                local goodsName = GoodsUtils.GetGoodsNameById(hpGoodsId)
                return string.fmt(__('全部__name__回满:'), {__name__ = goodsName})
            end
            return 'descr err: out of bound'
        end,
        
        getTipValue = function(tipIndex, hpGoodsId)
            if tipIndex == 1 then
                local hpData = self:GetHpDataByHpGoodsId(hpGoodsId) or {}
                local nextSeconds = checkint(hpData.hpNextRestoreTime)
                return string.formattedTime(nextSeconds, '%02i:%02i:%02i')
            end
            return 'value err: out of bound'
        end,
    }
end


function ActivityHpManager:GetAnniv2020JumpGridTipCallback()
    return {
        tipInfoCount = 1,
        
        getTipDescr = function(tipIndex, hpGoodsId)
            if tipIndex == 1 then
                local goodsName = GoodsUtils.GetGoodsNameById(hpGoodsId)
                return string.fmt(__('领取__name__剩余:'), {__name__ = goodsName})
            end
            return 'descr err: out of bound'
        end,
        
        getTipValue = function(tipIndex, hpGoodsId)
            if tipIndex == 1 then
                local hpData = self:GetHpDataByHpGoodsId(hpGoodsId) or {}
                local nextSeconds = checkint(hpData.hpNextRestoreTime)
                return nextSeconds > 0 and string.formattedTime(nextSeconds, '%02i:%02i:%02i') or __('可领取')
            end
            return 'value err: out of bound'
        end,
    }
end


-------------------------------------------------
-- public method
--[[
初始化体力数据
@params hpData map {
    hpGoodsId                int 体力道具id
    hpPurchaseAvailableTimes int 当前体力可购买次数
    hpMaxPurchaseTimes       int 体力最大购买次数（-1 无限）
    hpNextRestoreTime        int 下点体力恢复时间
    hpRestoreTime            int 每点体力恢复时间
    hpUpperLimit             int 体力上限（-1 无上限）
    hp                       int 当前体力
    hpPurchaseConsume        tab {goodsId:int, num:int} 体力购买消耗
    hpPurchaseTakeKey        str 购买后的数据更新key（可选。默认nil，取 “hp” 字段更新用）
    hpPurchaseCmd            PostData 体力购买命令
    activityId               int 活动id（可选。默认nil）
    hpBuyOnceNum             int 每次购买指定量的体力（可选。默认nil，就是按照体力上限所缺买剩余）
    isAutoRestoreToFull      bool 是否体力自动回满的机制（可选。默认nil也是false）
    calcNextRestoreTimeCb    func 计算下次恢复所需时间的回调方法。（可选。默认nil）
}
--]]
function ActivityHpManager:InitHpData( hpData )
    if self:HasHpData(hpData.hpGoodsId) then
        -- 已经存在则刷新数据
        table.merge(self:GetHpDataDict()[tostring(hpData.hpGoodsId)], hpData)
    else
        -- 插入数据
        self:GetHpDataDict()[tostring(hpData.hpGoodsId)] = hpData
        -- 注册信号
        if hpData.hpPurchaseCmd then
            app:RegistObserver( hpData.hpPurchaseCmd.sglName, mvc.Observer.new(handler(self, self.HpPurchaseHandler), self))
        end
    end
    self:StartHPCountDown(hpData.hpGoodsId)
end
--[[
购买体力事件处理
--]]
function ActivityHpManager:HpPurchaseHandler( stage, signal )
    local name = signal:GetName()
    local body = signal:GetBody() -- { hp :int }
    for i,v in pairs(self:GetHpDataDict()) do
        if v.hpPurchaseCmd and v.hpPurchaseCmd.sglName == name then
            -- 更新消耗的道具
            local buyHpConsume = checktable(v.hpPurchaseConsume)
            if next(buyHpConsume) ~= nil then
                CommonUtils.DrawRewards({ {goodsId = buyHpConsume.goodsId, num = checkint(buyHpConsume.num) * -1} })
            end
            -- 减少购买次数
            if v.hpPurchaseAvailableTimes then
                v.hpPurchaseAvailableTimes = v.hpPurchaseAvailableTimes - 1
            end
            -- 更新hp
            local targetHp = body[v.hpPurchaseTakeKey or 'hp']
            local tipsText = ''
            if targetHp then
                -- 同步至最新hp
                v.hp = checkint(targetHp)
                tipsText = string.fmt(__('【_name_】数量已更新'), {_name_ = GoodsUtils.GetGoodsNameById(v.hpGoodsId)})
            elseif v.hpBuyOnceNum then
                -- 增加指定增量hp
                v.hp = v.hp + checkint(v.hpBuyOnceNum)
                tipsText = string.fmt(__('【_name_】数量增加_num_'), {_name_ = GoodsUtils.GetGoodsNameById(v.hpGoodsId), _num_ = v.hpBuyOnceNum})
            end

            if self:GetHpDefineMap(v.hpGoodsId).isDrawType then
                v.isDrawSuccess = true
            end

            -- 重新倒计时
            self:StartHPCountDown(v.hpGoodsId)
            -- 更新货币栏
            app:DispatchObservers(SGL.CACHE_MONEY_UPDATE_UI, {hpGoodsId = v.hpGoodsId})
            app.uiMgr:ShowInformationTips(tipsText)
            break
        end
    end
end
--[[
开启体力倒计时
@params hpGoodsId int 体力道具id
--]]
function ActivityHpManager:StartHPCountDown( hpGoodsId )
    local hpData = self:GetHpDataByHpGoodsId(hpGoodsId)
    -- 获取倒计时显示标识
    local countdownName = CommonUtils.getCurrencyRestoreKeyByGoodsId(hpGoodsId)
    -- 如果存在老倒计时就先停掉
    self:StopHPCountDown(hpGoodsId)
    -- 检测下点体力恢复时间
    self:CheckHPNextRestoreTime(hpGoodsId)
    -- 检查是否达到最大体力
    if hpData.hpUpperLimit == -1 then
        if hpData.hpNextRestoreTime < 0 then
            hpData.hpNextRestoreTime = 0
            hpData.hpMaxRestoreTime = 0
            app.gameMgr:updateDownCountUi(countdownName, hpData.hpNextRestoreTime, hpData.hpMaxRestoreTime)
            return
        end
    elseif hpData.hp >= hpData.hpUpperLimit then
        hpData.hpNextRestoreTime = 0
        hpData.hpMaxRestoreTime = 0
        app.gameMgr:updateDownCountUi(countdownName, hpData.hpNextRestoreTime, hpData.hpMaxRestoreTime)
        return
    end
    
    -- 计算最大体力恢复时间
    hpData.hpMaxRestoreTime = self:CalcMaxRestoreTime(hpGoodsId)
    
    local callback = function(countdown, remindTag, timeNum, datas, timerName)
        local hpData = self:GetHpDataByHpGoodsId(hpGoodsId)
        if not hpData then return end

        hpData.hpMaxRestoreTime = countdown
        
        hpData.hpNextRestoreTime = self:CalcNextRestoreTime(hpGoodsId)
        
        if hpData.hpNextRestoreTime <= 0 then
            local needAddCount = math.floor(math.abs(hpData.hpNextRestoreTime) / hpData.hpRestoreTime) + 1
            hpData.hpNextRestoreTime = hpData.hpRestoreTime
            if hpData.isAutoRestoreToFull then
                hpData.hp = hpData.hpUpperLimit
            else
                hpData.hp = hpData.hp + (hpData.hpRestoreTime > 0 and needAddCount or 0)
            end
            app:DispatchObservers(SGL.CACHE_MONEY_UPDATE_UI, {hpGoodsId = hpData.hpGoodsId})
        end

        if countdown == 0 then
            hpData.hpNextRestoreTime = 0
            hpData.hpMaxRestoreTime = 0
        end
        app.gameMgr:updateDownCountUi(countdownName, hpData.hpNextRestoreTime, hpData.hpMaxRestoreTime)
    end
	app.timerMgr:AddTimer({name = countdownName, callback = callback, countdown = hpData.hpMaxRestoreTime})
end
--[[
停止体力倒计时
@params hpGoodsId int 体力道具id
--]]
function ActivityHpManager:StopHPCountDown( hpGoodsId )
    local hpCountdownName = CommonUtils.getCurrencyRestoreKeyByGoodsId(hpGoodsId)
    if app.timerMgr:RetriveTimer(hpCountdownName) then
        app.timerMgr:RemoveTimer(hpCountdownName)
    end
end
--[[
检查下点体力恢复时间
@params hpGoodsId int 体力道具id
--]]
function ActivityHpManager:CheckHPNextRestoreTime( hpGoodsId )
    local hpData = self:GetHpDataByHpGoodsId(hpGoodsId)
    if not hpData then return end
    if checkint(hpData.hpNextRestoreTime) <= 0 then
        if hpData.calcNextRestoreTimeCb then
            if self:GetHpDefineMap(hpGoodsId).isDrawType then
                if hpData.isDrawSuccess then
                    hpData.hpNextRestoreTime = hpData.calcNextRestoreTimeCb(hpData)
                    hpData.isDrawSuccess = false
                else
                    hpData.hpNextRestoreTime = 0
                end
            else
                hpData.hpNextRestoreTime = hpData.calcNextRestoreTimeCb(hpData)
            end
        else
            hpData.hpNextRestoreTime = hpData.hpRestoreTime
        end
    end
end
--[[
计算最大体力恢复时间
@params hpGoodsId      int 体力道具id
@return maxRestoreTime int 最大体力恢复时间
--]]
function ActivityHpManager:CalcMaxRestoreTime( hpGoodsId )
    local hpData = self:GetHpDataByHpGoodsId(hpGoodsId)
    if not hpData then return end

    if hpData.hpUpperLimit == -1 then
        return hpData.hpNextRestoreTime
    end

    local nextCount = hpData.hp + 1
    local maxRestoreTime = hpData.hpNextRestoreTime + (hpData.hpUpperLimit - nextCount) * hpData.hpRestoreTime
    return maxRestoreTime
end
--[[
下一体力恢复时间
@params hpGoodsId       int 体力道具id
@return nextRestoreTime int 下点体力恢复时间
--]]
function ActivityHpManager:CalcNextRestoreTime( hpGoodsId )
    local hpData = self:GetHpDataByHpGoodsId(hpGoodsId)
    if not hpData then return end

    if hpData.hpUpperLimit == -1 then
        return hpData.hpMaxRestoreTime
    end

    local nextRestoreTime = hpData.hpMaxRestoreTime - (hpData.hpUpperLimit - hpData.hp - 1) * hpData.hpRestoreTime
    return nextRestoreTime
end
--[[
通过hpGoodsId查找hpData是否存在
@return bool 是否存在
--]]
function ActivityHpManager:HasHpData( hpGoodsId )
    return self:GetHpDataByHpGoodsId(hpGoodsId) and true or false
end
--[[
刷新体力
@params hpGoodsId       int 体力道具id
@params amount          int 体力变更数量
--]]
function ActivityHpManager:UpdateHp( hpGoodsId, amount )
    local hpData = self:GetHpDataByHpGoodsId(hpGoodsId)
    if not hpData then return end
    hpData.hp = hpData.hp + checkint(amount)
    self:StartHPCountDown(hpGoodsId)
    app:DispatchObservers(SGL.CACHE_MONEY_UPDATE_UI, {hpGoodsId = hpData.hpGoodsId})
end
-------------------------------------------------
-- get/set
--[[
获取hpDataDict
--]]
function ActivityHpManager:GetHpDataDict()
    return self.hpDataDict
end
--[[
通过hp道具id获取hpData
@params hpGoodsId      int 体力道具id
--]]
function ActivityHpManager:GetHpDataByHpGoodsId( hpGoodsId ) 
    return self:GetHpDataDict()[tostring(hpGoodsId)]
end
--[[
通过hp道具id获取体力数量
@params hpGoodsId      int 体力道具id
--]]
function ActivityHpManager:GetHpAmountByHpGoodsId( hpGoodsId )
    local hpData = self:GetHpDataByHpGoodsId(hpGoodsId)
    if not hpData then return 0 end
    return hpData.hp
end
--[[
通过hp道具id设置体力数量
@params hpGoodsId      int 体力道具id
@params hp             int 体力
--]]
function ActivityHpManager:SetHpAmountByHpGoodsId( hpGoodsId, hp )
    local hpData = self:GetHpDataByHpGoodsId(hpGoodsId)
    if not hpData then return 0 end
    hpData.hp = checkint(hp)
    self:StartHPCountDown(hpGoodsId)
    app:DispatchObservers(SGL.CACHE_MONEY_UPDATE_UI, {hpGoodsId = hpData.hpGoodsId})
end
--[[
通过hp道具id获取体力最大购买次数
@params hpGoodsId      int 体力道具id
--]]
function ActivityHpManager:GetHpMaxPurchaseTimes( hpGoodsId )
    local hpData = self:GetHpDataByHpGoodsId(hpGoodsId)
    if not hpData then return 0 end
    return hpData.hpMaxPurchaseTimes
end
--[[
通过hp道具id获取体力剩余购买次数
@params hpGoodsId      int 体力道具id
--]]
function ActivityHpManager:GetHpPurchaseAvailableTimes( hpGoodsId )
    local hpData = self:GetHpDataByHpGoodsId(hpGoodsId)
    if not hpData then return 0 end
    return hpData.hpPurchaseAvailableTimes
end
--[[
通过hp道具id获取体力上限
@params hpGoodsId      int 体力道具id
--]]
function ActivityHpManager:GetHpUpperLimit( hpGoodsId )
    local hpData = self:GetHpDataByHpGoodsId(hpGoodsId)
    if not hpData then return 0 end
    return hpData.hpUpperLimit
end
--[[
通过hp道具id获取购买体力消耗
@params hpGoodsId      int 体力道具id
--]]
function ActivityHpManager:GetHpPurchaseConsume( hpGoodsId )
    local hpData = self:GetHpDataByHpGoodsId(hpGoodsId)
    if not hpData then return {} end
    return hpData.hpPurchaseConsume or {}
end
--[[
通过hp道具id获取购买体力信号  
@params hpGoodsId      int 体力道具id
--]]
function ActivityHpManager:GetHpPurchaseCmd( hpGoodsId )
    local hpData = self:GetHpDataByHpGoodsId(hpGoodsId)
    if not hpData then return nil end
    return hpData.hpPurchaseCmd
end
--[[
通过hp道具id获取购买体力数量
@params hpGoodsId      int 体力道具id
--]]
function ActivityHpManager:GetHpBuyOnceNum( hpGoodsId )
    local hpData = self:GetHpDataByHpGoodsId(hpGoodsId)
    if not hpData then return nil end
    return hpData.hpBuyOnceNum
end
--[[
通过hp道具id获取活动id  
@params hpGoodsId      int 体力道具id
--]]
function ActivityHpManager:GetActivityId( hpGoodsId )
    local hpData = self:GetHpDataByHpGoodsId(hpGoodsId)
    if not hpData then return 0 end
    return hpData.activityId
end
-------------------------------------------
return ActivityHpManager
