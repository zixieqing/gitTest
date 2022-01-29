--[[
 * descpt : pass卡 管理器
]]
local BaseManager      = require('Frame.Manager.ManagerBase')
---@class PassTicketManager
local PassTicketManager = class('PassTicketManager', BaseManager)

local PassTicketConfigParser = require('Game.Datas.Parser.PassTicketConfigParser')
-------------------------------------------------
-- manager method

PassTicketManager.DEFAULT_NAME = 'PassTicketManager'
PassTicketManager.instances_   = {}

PassTicketManager.MODULE_TYPE = {
    DAILY_TASK     = '1',            -- 日常任务
    ACTIVITY_QUEST = '2',            -- 活动副本
    CYCLIC_TASK    = '3',            -- 循环任务
    MAP_QUEST      = '4',            -- 主线本
    ARTIFACT_ROAD  = '5',            -- 神器之路
}

PassTicketManager.MODULE_CONFIG_NAME = {
    [tostring(PassTicketManager.MODULE_TYPE.DAILY_TASK)]     = PassTicketConfigParser.TYPE.POINT_DAILY_TASK,
    [tostring(PassTicketManager.MODULE_TYPE.ACTIVITY_QUEST)] = PassTicketConfigParser.TYPE.POINT_ACTIVITY_QUEST,
    [tostring(PassTicketManager.MODULE_TYPE.CYCLIC_TASK)]    = PassTicketConfigParser.TYPE.POINT_CIRCLE_TASK,
    [tostring(PassTicketManager.MODULE_TYPE.MAP_QUEST)]      = PassTicketConfigParser.TYPE.POINT_QUEST,
    [tostring(PassTicketManager.MODULE_TYPE.ARTIFACT_ROAD)]  = PassTicketConfigParser.TYPE.POINT_ARTIFACT_QUEST,
}

function PassTicketManager.GetInstance(instancesKey)
    instancesKey = instancesKey or PassTicketManager.DEFAULT_NAME

    if not PassTicketManager.instances_[instancesKey] then
        PassTicketManager.instances_[instancesKey] = PassTicketManager.new(instancesKey)
    end
    return PassTicketManager.instances_[instancesKey]
end


function PassTicketManager.Destroy(instancesKey)
    instancesKey = instancesKey or PassTicketManager.DEFAULT_NAME

    if PassTicketManager.instances_[instancesKey] then
        PassTicketManager.instances_[instancesKey]:release()
        PassTicketManager.instances_[instancesKey] = nil
    end
end


-------------------------------------------------
-- life cycle

function PassTicketManager:ctor(instancesKey)
    self.super.ctor(self)
    self.homeData = nil
    self:SetTimeEndState(true)
    if PassTicketManager.instances_[instancesKey] then
        funLog(Logger.INFO, "注册相关的facade类型")
    else
        self:initial()
    end
end


function PassTicketManager:initial()
    
end


function PassTicketManager:release()
end


-------------------------------------------------
-- public method
function PassTicketManager:InitData(data)
    if next(checktable(data)) == nil then
        return
    end
    
    local openModule = data.openModule or {}
    local tempOpenModule = {}
    for i, module in ipairs(openModule) do
        local moduleId = tostring(module)
        tempOpenModule[moduleId] = moduleId
    end
    data.openModule = tempOpenModule

    local cardId = nil
    for i, v in ipairs(data.level or {}) do
        local additionalRewards = v.additionalRewards or {}
        for _, additionalReward in ipairs(additionalRewards) do
            if CommonUtils.GetGoodTypeById(additionalReward.goodsId) == GoodsType.TYPE_CARD then
                cardId = additionalReward.goodsId
                break
            end
        end
        for _, baseReward in ipairs(v.baseRewards) do
            if CommonUtils.GetGoodTypeById(baseReward.goodsId) == GoodsType.TYPE_CARD then
                cardId = baseReward.goodsId
                break
            end
        end
    end
    self.passTickeCardId = cardId
    
    self.homeData = data
    data.exp = checkint(data.exp) - checkint(data.overflowRewardsDrawnTimes) * checkint(data.overflowCircle)
    self:InitCurLevelData(data.exp)
    self:SetTimeEndState(false)
end

function PassTicketManager:InitCurLevelData(exp)
    local curLevel, curLvExp, lvMaxExp = self:CalcLevelByExp(exp)
    self:UpdateCurLevelData(curLevel, curLvExp, lvMaxExp)
end

function PassTicketManager:InitUpgradeData(deltaExp)
    local exp = checkint(self:GetHomeData().exp) + checkint(deltaExp)
    local upgradeData = nil
    -- 检查是否满级
    if self:CheckIsMaxLevel() then
        self:InitCurLevelData(exp)
    else
        local oldCurLevel = self:GetCurLevel()
        local curLevel, curLvExp, lvMaxExp = self:CalcLevelByExp(exp)
        if curLevel ~= oldCurLevel then
            upgradeData = {oldLevel = oldCurLevel, newLevel = curLevel}
        end

        self:UpdateCurLevelData(curLevel, curLvExp, lvMaxExp)
    end
    self:SetExp(exp)
    self:SetUpgradeData(upgradeData)
end

function PassTicketManager:UpdateCurLevelData(curLevel, curLvExp, lvMaxExp)
    self:SetCurLevel(curLevel)
    self:SetCurLvExp(curLvExp)
    self:SetLvMaxExp(lvMaxExp)
end

--==============================--
---@desc: 获取homeData 的数据
--==============================--
function PassTicketManager:GetHomeData()
    return self.homeData or {}
end

function PassTicketManager:SetExp(exp)
    self:GetHomeData().exp = exp
end
function PassTicketManager:UpdateExp(exp)
    self:SetExp(exp)
    self:InitCurLevelData(exp)
end

--==============================--
---@desc: 根据 战斗关卡类型 更新 经验
---@param questType number  战斗类型
---@param isSuccess boolean 是否成功
---@param times     number  通关次数
--==============================--
function PassTicketManager:UpdateExpByQuestId(questId, isSuccess, times)
    -- if not isSuccess then return end
    isSuccess = isSuccess == nil and true or isSuccess
    times = times or 1
    local moduleId = self:GetModuleIdByQuestId(questId)
    self:UpdateExpByTask(moduleId, questId, times)
end

--==============================--
---@desc: 根据task 更新exp
---@param moduleId number 模块id
---@param task table | number 任务id
---@param times number 完成次数
--==============================--
function PassTicketManager:UpdateExpByTask(moduleId, task, times)
    if self:GetTimeEndState() then return end
    
    -- if not self:CheckOpenModuleByModuleId(moduleId) then return end

    -- local confName = self:GetPointConfNameByModleId(moduleId)

    -- if confName == nil then return end
    
    -- local point = self:GetTaskPoint(confName, task)
    times = times or 1
    local point = self:GetTaskPointByModuleId(moduleId, task) * times
    
    if point <= 0 then return end
    
    self:InitUpgradeData(point)
end

function PassTicketManager:GetCurLevel()
    return self:GetHomeData().curLevel
end
function PassTicketManager:SetCurLevel(curLevel)
    self:GetHomeData().curLevel = curLevel
end

function PassTicketManager:GetCurLvExp()
    return self:GetHomeData().curLvExp
end
function PassTicketManager:SetCurLvExp(curLvExp)
    self:GetHomeData().curLvExp = curLvExp
end

function PassTicketManager:GetLvMaxExp()
    return self:GetHomeData().lvMaxExp
end
function PassTicketManager:SetLvMaxExp(lvMaxExp)
    self:GetHomeData().lvMaxExp = lvMaxExp
end

function PassTicketManager:GetOverflowCircle()
    return self:GetHomeData().overflowCircle
end

function PassTicketManager:GetLevelList()
    return self:GetHomeData().level or {}
end

function PassTicketManager:GetPassTicketId()
    return self:GetHomeData().passTicketId
end

function PassTicketManager:GetOpenModule()
    return self:GetHomeData().openModule or {}
end

function PassTicketManager:GetPointAddition()
    return tonumber(self:GetHomeData().pointAddition)
end

function PassTicketManager:GetHasPurchasePassTicket()
    return checkint(self:GetHomeData().hasPurchasePassTicket)
end

function PassTicketManager:SetHasPurchasePassTicket(hasPurchasePassTicket)
    self:GetHomeData().hasPurchasePassTicket = hasPurchasePassTicket
end

function PassTicketManager:GetOverflowRewardsDrawnTimes()
    return checkint(self:GetHomeData().overflowRewardsDrawnTimes)
end
function PassTicketManager:SetOverflowRewardsDrawnTimes(overflowRewardsDrawnTimes)
    self:GetHomeData().overflowRewardsDrawnTimes = overflowRewardsDrawnTimes
end
function PassTicketManager:UpdateOverflowRewardsDrawnTimes(deltaTimes)
    self:SetOverflowRewardsDrawnTimes(self:GetOverflowRewardsDrawnTimes() + (deltaTimes or 1))
end

function PassTicketManager:GetPassTickeCardId()
    return self.passTickeCardId
end

--==============================--
---@desc: 获取升级数据
---@return table 升级数据
--==============================--
function PassTicketManager:GetUpgradeData()
    return self.upgradeData
end
--==============================--
---@desc: 设置升级数据
---@param upgradeData table 升级数据
--==============================--
function PassTicketManager:SetUpgradeData(upgradeData)
    self.upgradeData = upgradeData
end

--==============================--
---@desc: 获取活动时间结束状态
---@return boolean 活动时间结束状态
--==============================--
function PassTicketManager:GetTimeEndState()
    return self.timeEndState
end
--==============================--
---@desc: 设置活动时间结束状态
---@param state boolean 活动时间结束状态
--==============================-
function PassTicketManager:SetTimeEndState(state)
    self.timeEndState = state
end

--==============================--
---@desc: 根据 模块id 获取 模块id
---@param moduleId number 模块id
---@return string 配表名
--==============================-
function PassTicketManager:GetPointConfNameByModleId(modleId)
    return PassTicketManager.MODULE_CONFIG_NAME[tostring(modleId)]
end

-- function PassTicketManager:GetPointConfByModleId(modleId)
--     local confName = self:GetPointConfNameByModleId(modleId)
--     if confName == nil then return end

--     return CommonUtils.GetConfigAllMess(confName , 'passTicket') or {}
-- end

--==============================--
---@desc: 根据 关卡id 获取 模块id
---@param questId number 关卡id
---@return number 模块id
--==============================-
function PassTicketManager:GetModuleIdByQuestId(questId)
    local moduleId = nil
    local questBattleType = CommonUtils.GetQuestBattleByQuestId(questId)
    if questBattleType == QuestBattleType.MAP then
        moduleId = PassTicketManager.MODULE_TYPE.MAP_QUEST
    elseif questBattleType == QuestBattleType.ARTIFACT_ROAD then
        moduleId = PassTicketManager.MODULE_TYPE.ARTIFACT_ROAD
    elseif questBattleType == QuestBattleType.ACTIVITY_QUEST then
        moduleId = PassTicketManager.MODULE_TYPE.ACTIVITY_QUEST
    end
    return moduleId
end

function PassTicketManager:GetTaskPointByQuestId(questId)
    local moduleId = self:GetModuleIdByQuestId(questId)

    local point = self:GetTaskPointByModuleId(moduleId, questId)

    return point
end

function PassTicketManager:GetTaskPointByModuleId(moduleId, task)
    if not self:CheckOpenModuleByModuleId(moduleId) then return 0 end

    local confName = self:GetPointConfNameByModleId(moduleId)

    if confName == nil then return 0 end
    
    local point = self:GetTaskPoint(confName, task)

    return point
end

--==============================--
---@desc: 获取任务加成点数
---@param confName string @pass卡任务配表名称
---@param task number | table @任务id 或 任务列表
---@return table 等级配表
--==============================-
function PassTicketManager:GetTaskPoint(confName, task)
    local taskList = nil
    if type(task) ~= 'table' then
        taskList = {task}
    else
        taskList = task
    end

    local confs = CommonUtils.GetConfigAllMess(confName , 'passTicket') or {}
    local taskConfs = confs[tostring(self:GetPassTicketId())] or {}
    local point = 0
    local pointAddition = self:GetHasPurchasePassTicket() > 0 and self:GetPointAddition() or 0
    for i, taskId in ipairs(taskList) do
        local confData = taskConfs[tostring(taskId)]
        if confData then
            local confPoint = checkint(confData.point)
            point = point + confPoint + math.floor(pointAddition * confPoint + 0.5)
        end
    end

    return point
end

--==============================--
---@desc: 获取等级配表
---@param passTicketId number pass卡ID
---@return table 等级配表
--==============================-
function PassTicketManager:GetLevelConf(passTicketId)
    local levelConfs = CommonUtils.GetConfigAllMess('level' , 'passTicket') or {}
    local levelConf = levelConfs[tostring(passTicketId)] or {}
    return levelConf
end

--==============================--
---@desc: 获取跳级消耗
---@param level number pass卡等级
---@return table 跳级消耗
--==============================-
function PassTicketManager:GetSkipConsume(level)
    local levelConf = self:GetLevelConf(self:GetPassTicketId()) 
    local levelConfData = levelConf[tostring(level)] or {}
    local skipConsume = levelConfData.skipConsume or {}
    return skipConsume
end

--==============================--
---@desc: 通过经验计算等级
---@param exp number 经验
---@return table
--           level int 与经验相对应的升级 (tips: level 为 0 即为 达到最大等级)
--           lvExp int 该等级下剩余的经验
--==============================--
function PassTicketManager:CalcLevelByExp(exp)
    local passTicketId = self:GetPassTicketId()
    local levelConf = self:GetLevelConf(passTicketId)
    exp = checkint(exp)
    local level = 0
    local lvExp = exp
    local lvMaxExp = 0
    for k, v in orderedPairs(levelConf) do
        if checkint(v.totalExp) > exp then
            level = checkint(v.level)
            lvMaxExp = checkint(v.exp)
            break
        end
        lvExp = lvExp - checkint(v.exp)
    end

    return level, lvExp, lvMaxExp
end

--==============================--
---@desc: 显示pass升级界面
--==============================--
function PassTicketManager:ShowUppgradeLevelView(isOnlyTips)
    if self:GetTimeEndState() then return end
    
    local upgradeData = self:GetUpgradeData()
    if upgradeData == nil then return end

    local unlockFuncMdt = app:RetrieveMediator('HomeUnlockFunctionMediator')
    -- if GuideUtils.IsGuiding() or self:CheckIsCanTriggerGuiding() then  -- 不推荐用
    if GuideUtils.IsGuiding() or unlockFuncMdt or isOnlyTips then
        app.uiMgr:ShowInformationTips(__('书签 等级提升'))
        -- clear UpgradeData 
        self:SetUpgradeData()
        return 
    end
    
    local popView = require('Game.views.passTicket.PassTicketUpgradeLevelPopup').new()
    display.commonUIParams(popView, {ap = display.CENTER, po = display.center})
    app.uiMgr:GetCurrentScene():AddDialog(popView)
    -- clear UpgradeData 
    -- self:SetUpgradeData()

    return true
end

function PassTicketManager:IsCanPopPassTicketView(isOnlyTips)
    return not self:GetTimeEndState() and self:GetUpgradeData() ~= nil and not isOnlyTips
end

-- 不建议再写一套解析
-- function PassTicketManager:CheckIsCanTriggerGuiding()
-- 	local appMediator = AppFacade.GetInstance():RetrieveMediator('AppMediator')
--     local unlockOData = appMediator:getUpgradeUnlockOrderData()
--     if unlockOData and next(unlockOData) ~= nil and app.gameMgr:GetAreaId() == checkint(unlockOData.areaId) then
--         if not CommonUtils.ModulePanelIsOpen() then
--             return true
--         else
-- 			return false
--         end
--     else
--         local popUnlockIdx = 0
-- 		local openModuleId = 0
-- 		local unlockList   = appMediator:getUpgradeUnlockModuleList()
-- 		for i, moduleId in ipairs(unlockList) do
-- 			if CommonUtils.ModulePanelIsOpen() then
-- 				if HOME_FUNC_FROM_MAP[checkint(moduleId)] == 'EXTRA_PANEL' then
-- 					popUnlockIdx = i
-- 					break
-- 				end
-- 			else
-- 				if HOME_FUNC_FROM_MAP[checkint(moduleId)] ~= 'EXTRA_PANEL' then
-- 					popUnlockIdx = i
-- 					break
-- 				end
-- 			end
-- 		end
-- 		if popUnlockIdx > 0 then
-- 			openModuleId = checkint(table.remove(unlockList, popUnlockIdx))
--         end
        
--         return openModuleId > 0
--     end
-- end

--==============================--
---@desc: 根据 关卡id 检查 是否有开放的功能模块
---@param questId number 关卡id
---@return boolean 是否有开放的功能模块
--==============================-
function PassTicketManager:CheckOpenModuleByQuestId(questId)
    local moduleId = self:GetModuleIdByQuestId(questId)
    return self:GetOpenModule()[tostring(moduleId)] ~= nil
end

--==============================--
---@desc: 根据 模块id 检查 是否有开放的功能模块
---@param moduleId number 模块id
---@return boolean 是否有开放的功能模块
--==============================-
function PassTicketManager:CheckOpenModuleByModuleId(moduleId)
    return self:GetOpenModule()[tostring(moduleId)] ~= nil
end

--==============================--
---@desc: 检查 pass卡是否达到最大等级
---@return boolean 是否达到最大等级
--==============================-
function PassTicketManager:CheckIsMaxLevel()
    return checkint(self:GetCurLevel()) == 0
end

function PassTicketManager:CheckPlayerUpgradeLevel(data)
    local mainExp = data.mainExp
    if mainExp == nil then return false end

    local oldLevel = app.gameMgr:GetUserInfo().level
    local expData = CommonUtils.GetConfig('player', 'level', oldLevel + 1)

    local newLevel = oldLevel
    while (nil ~= expData) and (mainExp >= checkint(expData.totalExp)) do
        print('here log while when calc main exp')
        newLevel = checkint(expData.level)
        expData = CommonUtils.GetConfig('player', 'level', newLevel + 1)

        if nil == expData then
            break
        end
    end

    return newLevel > oldLevel
end

function PassTicketManager:CreatePassTicketNode(moduleId, taskId)
    local point = self:GetTaskPointByModuleId(moduleId, taskId)
    local goodsNode = nil
    if point > 0 then
        local img = CommonUtils.GetGoodsIconPathById(PASS_TICKET_ID)
        local passTicketConf = CommonUtils.GetConfig('goods', "money", PASS_TICKET_ID) or {}
        
        local bg = _res('ui/common/common_frame_goods_'..(passTicketConf.quality or '1')..'.png')
        goodsNode = display.newButton(0, 0, {n = bg, cb = function (sender)
            local params = {targetNode = sender, type = 9, title = tostring(passTicketConf.name),
                descr = tostring(passTicketConf.descr),
                mainIconConf = {img = img, bg = bg}
            }
            app.uiMgr:ShowInformationTipsBoard(params)
        end})
        local nodeSize = goodsNode:getContentSize()
        local icon = display.newImageView(img, nodeSize.width / 2, nodeSize.height / 2, {ap = display.CENTER})
        icon:setScale(0.55)
        goodsNode:addChild(icon)
        
        local infoLabel = display.newLabel(nodeSize.width - 5, 3, fontWithColor(9, {text = point, ap = display.RIGHT_BOTTOM, color = '#ffffff'}))
        goodsNode:addChild(infoLabel)
    end

    return goodsNode
end
-------------------------------------------------
-- private method


return PassTicketManager
