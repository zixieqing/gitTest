--[[
 * author : kaishiqi
 * descpt : pt本 管理器
]]
local BaseManager  = require('Frame.Manager.ManagerBase')
---@class PTDungeonManager
local PTDungeonManager = class('PTDungeonManager', BaseManager)


-------------------------------------------------
-- manager method

PTDungeonManager.DEFAULT_NAME = 'PTDungeonManager'
PTDungeonManager.instances_   = {}


function PTDungeonManager.GetInstance(instancesKey)
    instancesKey = instancesKey or PTDungeonManager.DEFAULT_NAME

    if not PTDungeonManager.instances_[instancesKey] then
        PTDungeonManager.instances_[instancesKey] = PTDungeonManager.new(instancesKey)
    end
    return PTDungeonManager.instances_[instancesKey]
end


function PTDungeonManager.Destroy(instancesKey)
    instancesKey = instancesKey or PTDungeonManager.DEFAULT_NAME

    if PTDungeonManager.instances_[instancesKey] then
        PTDungeonManager.instances_[instancesKey]:release()
        PTDungeonManager.instances_[instancesKey] = nil
    end
end


-------------------------------------------------
-- life cycle

function PTDungeonManager:ctor(instancesKey)
    self.super.ctor(self)
    self.homeData = {}
    if PTDungeonManager.instances_[instancesKey] then
        funLog(Logger.INFO, "注册相关的facade类型")
    else
        self:initial()
    end
end


function PTDungeonManager:initial()
    -- 由于属于隐藏道具，所以要自己接管刷新
    -- self:GetFacade():RegistObserver(SGL.CACHE_MONEY_UPDATE_UI, mvc.Observer.new(self.onHpChangeHandler_, self))
end


function PTDungeonManager:release()
    -- self:GetFacade():UnRegistObserver(SGL.CACHE_MONEY_UPDATE_UI, self)
end


-------------------------------------------------
-- public method
function PTDungeonManager:InitData(data, activityId)
    if not data then
        return
    end
    -- 每进入一次pt副本主界面都会根据活动id初始化一次数据
    self:SetActivityId(activityId)
    self:SetPTDungeonName(data.requestData.title)
    data.questId = self:GetQuestIdByPtId(data.ptId)
    local summary = CommonUtils.GetConfigAllMess('summary', 'pt')[data.ptId]
    self.lastHpId_ = checkint(summary.goodsId)
    data.hpGoodsId = self.lastHpId_
    self.homeData[tostring(activityId)] = data -- 多开
    self:InitActivityHp(data.ptId)
end

--==============================--
---@desc: 获取活动id
---@return number 活动id
--==============================--
function PTDungeonManager:GetActivityId()
    return self.activityId
end

--==============================--
---@desc: 设置活动id
---@params activityId number 活动id
--==============================--
function PTDungeonManager:SetActivityId(activityId)
    self.activityId = activityId
end

--==============================--
---@desc: 获取homeData 的数据
--==============================--
function PTDungeonManager:GetHomeData()
    return self.homeData[tostring(self:GetActivityId())] or {}
end

--[[
    活动体力id
]]
function PTDungeonManager:GetHPGoodsId()
    return self.lastHpId_ or 880227 -- pt副本入场券
end

--[[
初始化活动体力
--]]
function PTDungeonManager:InitActivityHp(ptId)
    local homeData = self:GetHomeData()
    local paramConfig = CommonUtils.GetConfigAllMess('summary', 'pt')[ptId] or {}
    local hpData = {
        hpGoodsId                = self:GetHPGoodsId(),
        hpPurchaseAvailableTimes = checkint(homeData.buyHpLimit) - checkint(homeData.buyHpTimes),
        hpMaxPurchaseTimes       = checkint(homeData.buyHpLimit),
        hpNextRestoreTime        = checkint(homeData.nextHpSeconds),
        hpRestoreTime            = checkint(homeData.hpRecoverSeconds),
        hpUpperLimit             = checkint(homeData.maxHp),
        hp                       = checkint(homeData.hp),
        hpPurchaseConsume        = CommonUtils.GetCapsuleConsume(homeData.buyHpConsume),
        hpPurchaseCmd            = POST.PT_BUY_HP,
        hpBuyOnceNum             = checkint(homeData.buyHpNum),
        activityId               = self:GetActivityId(),
    }
    app.activityHpMgr:InitHpData(hpData)
end

--==============================--
--desc: 显示剧情
--@params id    剧情id
--@params cb    剧情结束回调
--@return
--==============================--
function PTDungeonManager:ShowOperaStage(id, cb)
    local path = string.format("conf/%s/pt/story.json",i18n.getLang())
    local stage = require( "Frame.Opera.OperaStage" ).new({id = id, path = path, guide = false, isHideBackBtn = true, cb = function (tag)
        if cb then cb() end
    end})
    stage:setPosition(cc.p(display.cx,display.cy))
    sceneWorld:addChild(stage, GameSceneTag.Dialog_GameSceneTag)
end

--==============================--
--desc: 根据ptId获取questId
--@params ptId  int pt副本id
--@return questId int 探索id
--==============================--
function PTDungeonManager:GetQuestIdByPtId(ptId)
    local questId = nil
    local ptId = checkint(ptId)
    local ptQuestConfs       = CommonUtils.GetConfigAllMess('quest', 'pt') or {}
    for k, ptQuestConf in pairs(ptQuestConfs) do
        if checkint(ptQuestConf.ptId) == ptId then
            questId = ptQuestConf.id
        end
    end
    return questId
end

--==============================--
--desc: 获取点数
--@return point int 点数
--==============================--
function PTDungeonManager:GetPoint()
    return tonumber(self:GetHomeData().point)
end

--==============================--
--desc: 设置pt本名字
--==============================--
function PTDungeonManager:SetPTDungeonName(name)
    if name and name ~= '' then
        self.PTDungeonName = name
    end
end

--==============================--
--desc: 获取pt本名字
--@return string pt本名字
--==============================--
function PTDungeonManager:GetPTDungeonName()
    return self.PTDungeonName or __('PT本')
end

-------------------------------------------------
-- private method

-- function PTDungeonManager:onHpChangeHandler_(signal)
--     local dataBody    = signal:GetBody() or {}
--     local hideGoodsId = checkint(dataBody.hideGoodsId)
--     local goodsAmount = checkint(dataBody.num)
--     if hideGoodsId == self:GetHPGoodsId() then
--         if next(self:GetHomeData()) then
--             app.activityHpMgr:UpdateHp(hideGoodsId, goodsAmount)
--             -- 刷新货币栏，更新体力显示
--             AppFacade.GetInstance():DispatchObservers(SGL.CACHE_MONEY_UPDATE_UI, {})
--         end
--     end
-- end


return PTDungeonManager
