--[[
卡片工具管理模块
--]]
local ManagerBase = require( "Frame.Manager.ManagerBase" )
---@class UnionManager
local UnionManager = class('UnionManager',ManagerBase)
UnionManager.instances = {}


---------------------------------------------------
-- mediator extend begin --
---------------------------------------------------
function UnionManager:ctor( key )
    self.super.ctor(self)
    if UnionManager.instances[key] ~= nil then
        funLog(Logger.INFO,"注册相关的facade类型" )
        return
    end
    
    self.applyMessage =  0
    self.unionWarsModel_ = nil
    UnionManager.instances[key] = self
end


function UnionManager.GetInstance(key)
    key = (key or "UnionManager")
    if UnionManager.instances[key] == nil then
        UnionManager.instances[key] = UnionManager.new(key)
    end
    return UnionManager.instances[key]
end


function UnionManager.Destroy( key )
    key = (key or "UnionManager")
    if UnionManager.instances[key] == nil then
        return
    end
    --清除配表数据
    local mySelf = UnionManager.instances[key]
    mySelf:stopPartyCountdown_()
    UnionManager.instances[key] = nil
end


-------------------------------------------------
-- union home data
function UnionManager:setUnionId(unionId)
    app.gameMgr:setUnionId(unionId)
end

function UnionManager:getUnionData()
    return app.gameMgr:getUnionData()
end
function UnionManager:setUnionData(data)
    data.name                    = data.name or ""
    data.avatar                  = data.avatar or ""
    data.unionSign               = data.unionSign or ""
    data.level                   = checkint(data.level)
    data.contributionPoint       = checkint(data.contributionPoint)
    data.member                  = data.member or {}
    data.roomId                  = data.roomId and checkint(data.roomId) or nil
    data.roomMember              = data.roomMember or {}
    data.roomMemberNumber        = data.roomMemberNumber or {}
    data.playerContributionPoint = checkint(data.playerContributionPoint)
    data.applyPermission         = checkint(data.applyPermission)
    data.leftBuildTimes          = data.leftBuildTimes or {}
    data.leftFeedPetNumber       = checkint(data.leftFeedPetNumber)
    app.gameMgr:setUnionData(data)
end

function UnionManager:updateUnionData(newData)
    app.gameMgr:updateUnionData(newData)
end


-------------------------------------------------
--[[
    更具玩家的Id 获取玩家在公会的职位
--]]
function UnionManager:GetUnionMemberJobByPlayerId(playerId)
    playerId = checkint(playerId)
    local jobType = UNION_JOB_TYPE.COMMON
    local memberList = self:getUnionData().member
    for k ,v in pairs(memberList) do
        if checkint(v.playerId) == playerId then
            jobType =  v.job
            break
        end
    end
    return checkint(jobType)
end
--[[
    根据玩家的id 删除工会成员
--]]
function UnionManager:DeleteUnionMemberByPlayerId(playerId)
    playerId = checkint(playerId)
    local memberList = self:getUnionData().member
    for i =#memberList , 1 ,-1 do
        local  v = memberList[i]
        if checkint(v.playerId) == playerId then -- 删除工会成员的信息
            table.remove(memberList , i )
        end
    end
end

--[[
    根据玩家的id 变更工会列表的职位
--]]
function UnionManager:TurnOverUnionJobTypeByPlayerId(playerId , job )
    playerId = checkint(playerId)
    job = checkint(job)
    local jobConfig = CommonUtils.GetConfigAllMess('job','union')
    local myselfJobType = self:GetMyselfInUnionJob()
    -- 移交会长的正常操作
    local memberList = self:getUnionData().member or {}
    if myselfJobType == UNION_JOB_TYPE.PRESIDENT and job == UNION_JOB_TYPE.PRESIDENT  then
        self:getUnionData().job = UNION_JOB_TYPE.COMMON
        for k ,v in pairs(memberList) do
            if checkint(v.playerId) == checkint(app.gameMgr:GetUserInfo().playerId)  then
                v.jobName = jobConfig[tostring(UNION_JOB_TYPE.COMMON)].name
                v.job= UNION_JOB_TYPE.COMMON
                break
            end
        end
    else
        if job == UNION_JOB_TYPE.PRESIDENT then -- 自己变更为会长 需要先把原来的会长变为老会长
            for k ,v in pairs(memberList) do
                if checkint(v.job) == job  then
                    v.jobName = jobConfig[tostring(UNION_JOB_TYPE.COMMON)].name
                    v.job= UNION_JOB_TYPE.COMMON
                    break
                end
            end
        end
        -- 如果我不是会长 收到通知的时候的操作
        if checkint(app.gameMgr:GetUserInfo().playerId) == playerId then
            self:getUnionData().job = job
        end
    end
    for k ,v in pairs(memberList) do
        if checkint(v.playerId) == playerId  then
            v.jobName = jobConfig[tostring(job)].name
            v.job= job
            break
        end
    end
end
function UnionManager:GetCurrentLevelExp(level, exp )
    local buildConfig = CommonUtils.GetConfigAllMess('level','union')
    exp =  exp - checkint(buildConfig[tostring(level)].totalContributionPoint)
    return exp
end

--[[
    判断是否可以任命副会长
--]]
function UnionManager:JuageUnionAppointVicePresident()
    local unionLevel = 1
    local unionHomeData = self:getUnionData() or {}
    unionLevel = unionHomeData.level or unionLevel
    local unionLevelConfig = CommonUtils.GetConfigAllMess('level' , 'union')
    local vicePresidentNum = checkint( unionLevelConfig[tostring(unionLevel)].job[tostring(UNION_JOB_TYPE.VICE_PRESIDENT)])
    local count  =  0
    for k , v in pairs(unionHomeData.member) do
        if checkint(v.job) == UNION_JOB_TYPE.VICE_PRESIDENT  then
            count = count +1
        end
    end
    if count >= vicePresidentNum then
        return false
    else
        return true
    end
end

--[[
    根据等级获取工会等级返回工会成员上限
--]]
function UnionManager:GetUnionMemberLimitNumByLevel(unionLevel)
    ---@type table
    unionLevel = unionLevel or 1
    local unionLevelConfig = CommonUtils.GetConfigAllMess('level' , 'union')
    local unionLevelOneConfig = unionLevelConfig[tostring(unionLevel)]
    local count = 0
    if unionLevelOneConfig then
        count = checkint(unionLevelOneConfig.job[tostring(UNION_JOB_TYPE.COMMON)])
    end
    return  count
end
--[[
    检测工会成员是否满员
--]]
function UnionManager:CheckUnionMemberIsFull()
    local unionLevel = 1
    local unionHomeData = self:getUnionData() or {}
    unionLevel = unionHomeData.level or unionLevel
    local memberList = unionHomeData.member
    local unionLevelConfig = CommonUtils.GetConfigAllMess('level' , 'union')
    local unionLevelOneConfig = unionLevelConfig[tostring(unionLevel)]
    local memberCount =  #memberList
    local count  = checkint(unionLevelOneConfig.job[tostring(UNION_JOB_TYPE.COMMON)])
    if checkint(count)  > checkint(memberCount)  then
        return false
    else
        return true
    end
end

--[[
    更具玩家的Id 获取玩家在公会的职位
--]]
function UnionManager:GetUnionMemberNamePlayerId(playerId)
    local name = ""
    local memberList = self:getUnionData().member
    for k ,v in pairs(memberList) do
        if checkint(v.playerId) == checkint(playerId) then
            name = v.playerName
            break
        end
    end
    return name
end
--[[
   更具玩家id 获取玩家的数据
--]]
function UnionManager:GetUnionMemberDataPlayerId(playerId)
    local data = {}
    local memberList = self:getUnionData().member
    for k ,v in pairs(memberList) do
        if checkint(v.playerId) == checkint(playerId) then
            data = v
            break
        end
    end
    return data
end

--[[
    获取到工会的总贡献
--]]
function UnionManager:GetUnionContributionPoint()
    local data = self:getUnionData()
    return  checkint(data.contributionPoint)
end
--[[
    设置到工会的总贡献
--]]
function UnionManager:SetUnionContributionPoint(contributionPoint)
    local data = self:getUnionData()
    data.contributionPoint = checkint(contributionPoint)
end

function UnionManager:GetMyselfInUnionJob()
    local jobType = UNION_JOB_TYPE.COMMON
    local unionHomeData = self:getUnionData() or {}
    if checkint(unionHomeData.job) >0 then
        jobType  = checkint(unionHomeData.job)
    end
    return jobType
end

--==============================--
--desc: 加入工会聊天室
--time:2018-01-18 09:55:59
--@return 
--==============================-- 
function UnionManager:JoinUnionChatRoom()
    app.chatMgr:JoinChatRoomByChannelAndRoomId(CHAT_CHANNELS.CHANNEL_UNION)
end

--==============================--
--desc:退出工会聊天室
--time:2018-01-18 09:54:14
--@args:
--@return 
--==============================-- 
function UnionManager:ExitUnionChatRoom()
    app.chatMgr:ExitChatRoomByChannelAndRoomId(CHAT_CHANNELS.CHANNEL_UNION)
end

--==============================--
--desc:是否是工会会长
--@args:
--@return 
--==============================-- 
function UnionManager:IsUnionPresident()
    return UNION_JOB_TYPE.PRESIDENT == self:GetMyselfInUnionJob()
end

--==============================--
--desc:是否是工会副会长
--@args:
--@return 
--==============================-- 
function UnionManager:IsUnionVicePresident()
    return UNION_JOB_TYPE.VICE_PRESIDENT == self:GetMyselfInUnionJob()
end

--==============================--
--desc:是否能报名工会战
--@args:
--@return 
--==============================-- 
function UnionManager:IsCanSignUpUnionWars()
   return self:IsUnionPresident() or self:IsUnionVicePresident() 
end

---------------------------------------------------
-- union pet begin --
---------------------------------------------------
--[[
获取工会神兽幼崽信息
--]]
function UnionManager:GetUnionPetsData()
    return app.gameMgr:GetUnionPetsData()
end
function UnionManager:SetUnionPetsData(data)
    app.gameMgr:SetUnionPetsData(data)
end
--[[
更新工会神兽幼崽信息
@params petId int 幼崽id
@params data table 信息
--]]
function UnionManager:UpdateUnionPetData(petId, data)
    app.gameMgr:UpdateUnionPetData(petId, data)
end
--[[
是否观看过神兽幼崽的剧情
@return _ bool 是否观看过神兽剧情
--]]
function UnionManager:OpenedBeastBaby()
    local selfPlayerId = checkint(app.gameMgr:GetUserInfo().playerId)
    local key = string.fmt('IS_FIRST_OPEN_UNION_BB_%1', selfPlayerId)
    return cc.UserDefault:getInstance():getBoolForKey(key, false)
end
--[[
设置观看过神兽幼崽的剧情
--]]
function UnionManager:SetOpenedBeastBaby()
    local selfPlayerId = checkint(app.gameMgr:GetUserInfo().playerId)
    local key = string.fmt('IS_FIRST_OPEN_UNION_BB_%1', selfPlayerId)
    cc.UserDefault:getInstance():setBoolForKey(key, true)
    cc.UserDefault:getInstance():flush()
end


---------------------------------------------------
-- union pet end --
---------------------------------------------------


-------------------------------------------------
-- union party about

function UnionManager:getPartyLevel()
    return checkint(self.partyLevel_)
end
function UnionManager:setPartyLevel(level)
    self.partyLevel_ = checkint(level)
end


function UnionManager:getPartyBaseTime()
    return checkint(self.partyBaseTime_)
end
function UnionManager:setPartyBaseTime(baseTime)
    local isNewParty        = self.partyBaseTime_ ~= nil and self:getPartyBaseTime() ~= checkint(baseTime)
    self.partyStepId_       = UNION_PARTY_STEPS.UNOPEN
    self.partyBaseTime_     = checkint(baseTime)
    self.partyStepList_     = {}
    self.partyNoticeMap_    = {}
    self.lastPartEndedTime_ = 0
    if isNewParty then
        self:setPartyLevel(0)
    end

    if self.partyBaseTime_ > 0 then
        local partyBaseTime  = self.partyBaseTime_
        local partyTimeConfs = CommonUtils.GetConfigAllMess('partyTimeLine', 'union') or {}
        -- logInfo.add(5, string.fmt('now server time: %1, %2', partyBaseTime, os.date('%Y-%m-%d %H:%M:%S (周%w', getServerTime()) ))
        -- logInfo.add(5, string.fmt('party base time: %1, %2', baseTime, os.date('%Y-%m-%d %H:%M:%S (周%w', baseTime) ))
        for i = UNION_PARTY_STEPS.FORESEE, UNION_PARTY_STEPS.ENDING do
            local timeConf = partyTimeConfs[tostring(i)] or {}
            local stepData = {
                stepId    = checkint(timeConf.id),
                descr     = tostring(timeConf.desc),
                duration  = checkint(timeConf.seconds),
                startTime = partyBaseTime,
                endedTime = partyBaseTime + checkint(timeConf.seconds),
            }
            partyBaseTime = stepData.endedTime
            table.insert(self.partyStepList_, stepData)
            -- logInfo.add(5, string.fmt('stepId %1, ended: %2, %3', stepData.stepId, stepData.endedTime, os.date('%Y-%m-%d %H:%M:%S (周%w', stepData.endedTime)))
        end

        self.partyStepId_       = self:partyRetrieveCurrentStepId_()
        local lastStepInfo      = self:getPartyStepInfo(self:getPartyLastStepId())
        self.lastPartEndedTime_ = checkint(lastStepInfo.endedTime)
        self:startPartyCountdown_()
    else
        self:stopPartyCountdown_()
    end
    -- logInfo.add(5, string.fmt('base party step: %1', self.partyStepId_))
end


-- get party stepInfo
function UnionManager:getPartyStepInfo(stepId)
    return self.partyStepList_ and self.partyStepList_[checkint(stepId)] or nil
end


-- get party current stepId
function UnionManager:getPartyCurrentStepId()
    return self.partyStepId_ or UNION_PARTY_STEPS.UNOPEN
end


-- get party last stepId
function UnionManager:getPartyLastStepId()
    return UNION_PARTY_STEPS.ENDING
end


-- get party current roundNum
function UnionManager:getPartyCurrentRoundNum()
    local roundNum  = 0
    local nowStepId = self:getPartyCurrentStepId()
    if nowStepId >= UNION_PARTY_STEPS.OPENING and nowStepId <= UNION_PARTY_STEPS.R1_DROP_FOOD_2 then
        roundNum = 1
    elseif nowStepId >= UNION_PARTY_STEPS.R2_READY_START and nowStepId <= UNION_PARTY_STEPS.R2_DROP_FOOD_2 then
        roundNum = 2
    elseif nowStepId >= UNION_PARTY_STEPS.R3_READY_START and nowStepId <= UNION_PARTY_STEPS.R3_DROP_FOOD_2 then
        roundNum = 3
    end
    return roundNum
end


-- get party last endedTime
function UnionManager:getPartyLastEndedTime()
    return self.lastPartEndedTime_ or 0
end


-- is party timely currentStep
function UnionManager:isPartyTimelyCurrentStep()
    local currentStepInfo = self:getPartyStepInfo(self:getPartyCurrentStepId()) or {}
    return math.max(0, getServerTime() - checkint(currentStepInfo.startTime)) < 2
end


-- is party in workflow
function UnionManager:isPartyInWorkflow()
    local partyStepId = self:getPartyCurrentStepId()
    return partyStepId >= UNION_PARTY_STEPS.OPENING and partyStepId < UNION_PARTY_STEPS.ENDING
end


function UnionManager:partyRetrieveCurrentStepId_()
    local currentPartyStepId = UNION_PARTY_STEPS.UNOPEN
    if self:getPartyBaseTime() > 0 then
        local currentServerTime = getServerTime()
        for _, stepInfo in ipairs(self.partyStepList_ or {}) do
            if currentServerTime >= stepInfo.startTime and currentServerTime < stepInfo.endedTime then
                currentPartyStepId = stepInfo.stepId
                break
            end
        end
    end
    return currentPartyStepId
end


function UnionManager:startPartyCountdown_()
    if self.partyTimeCountdownHandler_ then return end
    self.partyTimeCountdownHandler_ = scheduler.scheduleGlobal(function()

        -- check opening before 3 seconds (to show ready animation)
        if self:getPartyCurrentStepId() == UNION_PARTY_STEPS.CLEARING then
            local openingStepInfo = self:getPartyStepInfo(UNION_PARTY_STEPS.OPENING) or {}
            if checkint(openingStepInfo.startTime) - getServerTime() == 3 then
                if not self.partyNoticeMap_[tostring(UNION_PARTY_STEPS.OPENING)] then
                    self.partyNoticeMap_[tostring(UNION_PARTY_STEPS.OPENING)] = true
                    AppFacade.GetInstance():DispatchObservers(SGL.UNION_PARTY_PRE_OPENING)
                end
            end
        end

        -- check step ended
        local stepInfo = self:getPartyStepInfo(self:getPartyCurrentStepId()) or {}
        if getServerTime() >= checkint(stepInfo.endedTime) then

            -- check last step
            if (self:getPartyCurrentStepId() == self:getPartyLastStepId() or getServerTime() > self:getPartyLastEndedTime()) then
                self.partyStepId_ = UNION_PARTY_STEPS.UNOPEN
                self:stopPartyCountdown_()

                -- sync next partyTime
                local appMediator = AppFacade.GetInstance():RetrieveMediator('AppMediator')
                appMediator:syncPartyBaseTime()
            else
                -- update current step
                self.partyStepId_ = self:partyRetrieveCurrentStepId_()
            end

            -- dispatch step change
            AppFacade.GetInstance():DispatchObservers(SGL.UNION_PARTY_STEP_CHANGE, {
                stepId   = self:getPartyCurrentStepId(), 
                isTimely = self:isPartyTimelyCurrentStep()
            })
        end
    end, 0.5)
end
function UnionManager:stopPartyCountdown_()
    if self.partyTimeCountdownHandler_ then
        scheduler.unscheduleGlobal(self.partyTimeCountdownHandler_)
        self.partyTimeCountdownHandler_ = nil
    end
end


-------------------------------------------------
-- union wars about

-- 工会战数据模型
---@return UnionWarsModel
function UnionManager:getUnionWarsModel()
    return self.unionWarsModel_
end
---@see Game.models.UnionWarsModelFactory
function UnionManager:setUnionWarsModel(unionWarsModel)
    self.unionWarsModel_ = unionWarsModel
end

function UnionManager:getUnionWarsDefendTip()
    if self.unionWarsDefendTip then return self.unionWarsDefendTip end

    local text = __('选择的防守队伍卡牌，<b>不能继续使用</b>在工会进攻队伍中。')
    local labelparser = require('Game.labelparser')
    local parsedtable = labelparser.parse(text)
    local result = {}
	for name, val in ipairs(parsedtable) do
		if val.labelname == 'b' then
            table.insert(result, fontWithColor(14, {text = val.content , fontSize = 24, color = '#ff2222', descr = val.labelname}))
        else
            table.insert(result, fontWithColor(14, {text = val.content , fontSize = 24, color = '#ffe8a2', descr = val.labelname}))
        end
	end

    self.unionWarsDefendTip = result

    return result
end

function UnionManager:startUnionWarsCountdown()
    if self.unionWarsTimeCountdownHandler_ then return end
    self.unionWarsTimeCountdownHandler_ = scheduler.scheduleGlobal(function()
        
        -- check have unionWarsModel
        local unionWarsModel = self:getUnionWarsModel()
        if unionWarsModel then

            local currentServerTime = getServerTime()
            local isUnionWarsClose  = false

            -- not started
            if currentServerTime < unionWarsModel:getWarsBaseTime() then
                -- just wait
                -- logInfo.add(5, string.fmt('index %1) wait >> %2', 0, unionWarsModel:getWarsBaseTime() - currentServerTime))

            -- is over
            elseif currentServerTime > unionWarsModel:getWarsCloseTime() then
                isUnionWarsClose = true
                -- logInfo.add(5, string.fmt('index %1) close >> %2', 'max', currentServerTime - unionWarsModel:getWarsCloseTime()))
                
            else
                -- not started --> just started, so need sync once
                if unionWarsModel:getTimeLineIndex() == 0 and #unionWarsModel:getTimeLineModels() > 0 then
                    unionWarsModel:syncTimeLineIndex()
                end

                -- update current timeModel
                local currentTimeLineIndex = unionWarsModel:getTimeLineIndex()
                local currentTimeLineModel = unionWarsModel:getWarsTimeModel(currentTimeLineIndex)
                if currentTimeLineModel then
                    -- logInfo.add(5, string.fmt('index %1) update >> %2', currentTimeLineIndex, currentTimeLineModel:getEndedTime() - currentServerTime))
                    if currentServerTime >= currentTimeLineModel:getEndedTime() then

                        -- check wars is close
                        if currentTimeLineModel:getEndedTime() == unionWarsModel:getWarsCloseTime() then

                            -- close unionWars
                            isUnionWarsClose = true
                        else
                            
                            -- update curren timeLineIndex
                            unionWarsModel:syncTimeLineIndex()
                        end
                    end
                else
                    logInfo.add(5, string.fmt('index %1) unknow <<', currentTimeLineIndex))
                end
            end
            
            unionWarsModel:syncTimeLineLeftTime()
            app:DispatchObservers(SGL.UNION_WARS_COUNTDOWN_UPDATE)

            -- check unionWars is over
            if isUnionWarsClose then
                self:stopUnionWarsCountdown()
                app:DispatchObservers(SGL.UNION_WARS_CLOSE)
            end

        else
            self:stopUnionWarsCountdown()
        end
    end, 1)
end
function UnionManager:stopUnionWarsCountdown()
    if self.unionWarsTimeCountdownHandler_ then
        scheduler.unscheduleGlobal(self.unionWarsTimeCountdownHandler_)
        self.unionWarsTimeCountdownHandler_ = nil
    end
end


-- 工会任务剩余时间倒计时
function UnionManager:StopUnionTaskCountDown()
    if app.timerMgr:RetriveTimer(COUNT_DOWN_TAG_UNION_TASK) then
        app.timerMgr:RemoveTimer(COUNT_DOWN_TAG_UNION_TASK)
    end
end
function UnionManager:AddUnionTaskCountDown(seconds)
    self:StopUnionTaskCountDown()
    if not app.gameMgr:hasUnion() then return end

    if seconds ~= nil then
        app.gameMgr:GetUserInfo().unionTaskRemainSeconds = checkint(seconds)
    end

    if checkint(app.gameMgr:GetUserInfo().unionTaskRemainSeconds) <= 0 then
        app.gameMgr:GetUserInfo().unionTaskRemainSeconds = 86400
    end
    app.timerMgr:AddTimer({name = COUNT_DOWN_TAG_UNION_TASK, countdown = checkint(app.gameMgr:GetUserInfo().unionTaskRemainSeconds) + 5})
end


return UnionManager
