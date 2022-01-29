---@class LDirector: Dispatch
local LDirector = class("LDirector", mvc.Dispatch)

local shareFacade = AppFacade.GetInstance()

LDirector.instances = {}

TRIGGER_CONDITIONS = {
    QUEST_TASK = 1, --主线任务id触发
    TRIGGER_FIRST_TIME = 2, --首次进入的逻辑
    TRIGGER_PLAYER_LEVEL = 3, --达到等级的逻辑
}

CONDITION_LEVELS = {
    ACCEPT_STORY_TASK = CommonUtils.GetModuleOpenLevel(RemindTag.STORY_TASK),     -- 接受剧情任务
    FINISH_STORY_TASK = CommonUtils.GetModuleOpenLevel(RemindTag.STORY_TASK) + 1, -- 完成剧情任务
    DISCOVER_DISH     = CommonUtils.GetModuleOpenLevel(RemindTag.RESEARCH),       -- 研发菜谱
    PET               = CommonUtils.GetModuleOpenLevel(RemindTag.PET),            -- 堕神
    MARKET            = CommonUtils.GetModuleOpenLevel(RemindTag.MARKET),         -- 市场
}

TRIGGER_MEDIATOR = {
    ['17'] = 'TalentMediator',
    ['33'] = 'WorldMediator',
    ['34'] = 'AvatarMediator',
    ['32'] = 'PetDevelopMediator',
}

local scheduler = require('cocos.framework.scheduler')

local modules = CommonUtils.GetConfigAllMess('module', 'guide')
--所有的步骤信息列表
local stepAllInfos = CommonUtils.GetConfigAllMess('step', 'guide')


function LDirector:ctor( )
	self.super.ctor(self)
	self.stage =  nil --当前的舞台
    self.isStart = false--记录当前对白是否已开始执行
    self.isGuiding = false --是否在引导逻辑之中
    self.modules = {}--初始数据
    self.stopBlocking = false

    self.moduleId = GUIDE_MODULES.MODULE_LOBBY --初台放为第一个引导模块
    self.filterSteps = {} --过滤后的所有步骤
    --[[
    shareFacade:RegistObserver('EVENT_HTTP_ERROR', mvc.Observer.new(function(context,signal)
        --判断是否需要出跳过引导的按钮页面
        if self:IsInGuiding() then
            --正在引导中的需要显示跳过按钮
            local skipButton = self.stage:getChildByTag(3006)
            if skipButton then skipButton:setVisible(true) end
        end
    end), self)
    --]]
    shareFacade:RegistObserver('SavePlayerGuide', mvc.Observer.new(function(context, signal)
        --添加请求处理
        local body = signal:GetBody()
        local moduleInfo = modules[tostring(self.moduleId)]
           --body的逻辑
        if body.requestData.isStart then
            --如果会有一个奖励表示第一步
            if body.rewards and table.nums(checktable(body.rewards)) > 0 then
                CommonUtils.DrawRewards(body.rewards,nil,true)
                -- app.uiMgr:AddDialog('common.RewardPopup', {rewards = checktable(body.rewards)})
            end
            if moduleInfo then
                print('---guide--start---here-----')
                logs('[LDirector]', '---guide--start---here-----')
                local remoteStepId = checkint(self.modules[tostring(self.moduleId)])
                if checkint(moduleInfo.playStoreId) > 0 and remoteStepId <= 1 then
                    --添加剧情引导的逻辑
                    if self.stage then
                        self.stage:ShowPlotDialog(checkint(moduleInfo.playStoreId))
                    end
                else
                    --开始第一步引导的逻辑
                    self:MoveNext(true)
                end
            end

        else
            --下一个引导的逻辑
            -- self:RealStart()
            if self.moduleId == GUIDE_MODULES.MODULE_LOBBY then
                self:SwitchModule(GUIDE_MODULES.MODULE_DRAWCARD)
            elseif self.moduleId == GUIDE_MODULES.MODULE_DRAWCARD then
                self:SwitchModule(GUIDE_MODULES.MODULE_TEAM)
            else
                --引导模块结束点判断是否需要添加引导结束的统计
                if isElexSdk() or isJapanSdk() then
                    if checkint(self.moduleId) == GUIDE_MODULES.MODULE_PET then
                        --最后一个引导模块的逻辑
                        local AppSDK = require('root.AppSDK')
                        AppSDK.GetInstance():AppFlyerEventTrack("af_tutorial_completion",{af_event_end = "GuideEnd"})
                    end
                end
                if self.stage then
                    self.stage:StopBlockTouch()
                end
                self.isGuiding = false --是否在引导逻辑之中
                self.filterSteps = {} --清除之前存在的缓存
            end
        end
    end,self))
end


--[[
--是否在引导中的逻辑判断
--]]
function LDirector:IsInGuiding()
    --是否正在引导中的逻辑
    if not self.filterSteps then self.filterSteps = {} end
    return (table.nums(self.filterSteps) > 0)
end
---@return LDirector
function LDirector.GetInstance( key )
	if not key then key = "LDirector" end
	local Director = nil
	if not LDirector.instances[key] then
		Director = LDirector.new()
		LDirector.instances[key] = Director
	else
		Director = LDirector.instances[key]
	end
	return Director
end

function LDirector.Destroy(key)
	if LDirector.instances[key] then
		--清除配表数据
	    local instance = LDirector.instances[key]
        if instance.updateHandler then
            scheduler.unscheduleGlobal(instance.updateHandler)
        end
	    instance.isStart = false
	    instance = nil
		LDirector.instances[key] = nil
        shareFacade:UnRegistObserver("LDirector", self)
	end
end

--[[
--指定模块是否是初次进行
--]]
function LDirector:FirstModule(moduleId)
    -- dump(self.modules)
    return (self.modules[tostring(moduleId)] == nil)
end

--[[
-- 一次的模块是否是已经运行结束了
-- 用来判断是否需要出现主界面手指的逻辑
--@moduleId --模块id
--]]
function LDirector:OneTimeModuleFinished(moduleId)
    local isFinished = 1
    if self.modules[tostring(moduleId)] then
        if stepAllInfos[tostring(moduleId)] then
            local preKeys = sortByKey(stepAllInfos[tostring(moduleId)])
            local maxStep = checkint(preKeys[#preKeys])
            local curStep = checkint(self.modules[tostring(moduleId)])
            -- print('----------------->>>', moduleId, curStep, maxStep)
            if curStep < maxStep then
                --表示当前模块还否结束
                isFinished = 2
            end
        end
    else
        isFinished = 0
    end
    return isFinished
end

function LDirector:jumpConfId_(jumpConfId)
    local jumpStepId = 1
    if jumpConfId then
        for index, value in ipairs(self.filterSteps) do
            if checkint(value) == checkint(jumpConfId) then
                jumpStepId = index
                break
            end
        end
    end
    return jumpStepId
end

--[[
--直接进入堕神模块，如果没有起引导，需要启动引导的逻辑
--切入堕神引导的逻辑
--]]
function LDirector:PetDevelopGuide()
    if not self:IsInGuiding() then
        --未结束的模块
        local moduleId = GUIDE_MODULES.MODULE_PET
        local preKeys = sortByKey(stepAllInfos[tostring(moduleId)])
        local maxStep = checkint(preKeys[#preKeys])
        local curStep = checkint(self.modules[tostring(moduleId)])
        if curStep < maxStep then
            if stepAllInfos[tostring(moduleId)] then
                --移除需要跳过的引导步骤
                local curModuleSteps = stepAllInfos[tostring(moduleId)]
                -- dump(curModuleSteps)
                if curModuleSteps then
                    for name,val in pairs(curModuleSteps) do
                        if checkint(val.exitSkip) == 1 then --需要跳过的步骤
                            curModuleSteps[tostring(name)] = nil
                        end
                    end
                end
                -- local keys = sortByKey(stepAllInfos[tostring(moduleId)])
                local minId = checkint(preKeys[1])
                self.moduleId = moduleId
                --需要多跳过一个手指按钮的逻辑
                self.modules[tostring(moduleId)] = minId --初始化数据
                self:FilterSteps() --重新变步骤
                self.stepId = 3
                --做一个移除
                if table.nums(self.filterSteps) > 0 then
                    if self.stage then
                        self.stage:RemoveMask()
                    end
                    self:BootStart()--然后开始引导
                end
            end
        end
    end
end

function LDirector:SelectCookingStyleGuide()
    if not self:IsInGuiding() then
        --未结束的模块
        local moduleId = GUIDE_MODULES.MODULE_LOBBY
        local preKeys  = sortByKey(stepAllInfos[tostring(moduleId)])
        local maxStep  = checkint(preKeys[#preKeys])
        local curStep  = checkint(self.modules[tostring(moduleId)])
        if curStep < maxStep then
            if stepAllInfos[tostring(moduleId)] then
                --移除需要跳过的引导步骤
                local curModuleSteps = stepAllInfos[tostring(moduleId)]
                -- dump(curModuleSteps)
                if curModuleSteps then
                    for name,val in pairs(curModuleSteps) do
                        if checkint(val.exitSkip) == 1 then --需要跳过的步骤
                            curModuleSteps[tostring(name)] = nil
                        end
                    end
                end
                -- local keys = sortByKey(stepAllInfos[tostring(moduleId)])
                local minId = checkint(preKeys[1])
                self.moduleId = moduleId
                --需要多跳过一个手指按钮的逻辑
                self.modules[tostring(moduleId)] = minId --初始化数据
                self:FilterSteps() --重新变步骤
                self.stepId = 3
                --做一个移除
                if table.nums(self.filterSteps) > 0 then
                    if self.stage then
                        self.stage:RemoveMask()
                    end
                    self:BootStart()--然后开始引导
                end
            end
        end
    end
end

--[[
--远程服务端对应的引导各模块数据
--
--]]
function LDirector:SetRemoteModules(rmodules)
    if rmodules and table.nums(rmodules) > 0 then
        self.modules = rmodules
        --同步后的远程数据，后期要改这个数据
        -- dump(self.modules)
    end
end
--[[
--切到下一个模块的逻辑
---]]
function LDirector:SwitchModule(moduleId, jumpConfId)
    --切模块的逻辑
    if not self.modules[tostring(moduleId)] then
        if self.stage and self.stage.m_listener then
            self.stage.m_listener:setEnabled(true)
        end
        -- if self.moduleId > 0 and stepAllInfos[tostring(self.moduleId)] then
            -- local preKeys = sortByKey(stepAllInfos[tostring(self.moduleId)])
            -- self.modules[tostring(self.moduleId)] = checkint(preKeys[#preKeys])
        -- end
        if stepAllInfos[tostring(moduleId)] then
            --移除需要跳过的引导步骤
            local curModuleSteps = stepAllInfos[tostring(moduleId)]
            -- dump(curModuleSteps)
            if curModuleSteps then
                for name,val in pairs(curModuleSteps) do
                    if checkint(val.exitAdd) == 1 then --需要跳过的步骤
                        if checkint(val.guideModuleId) == GUIDE_MODULES.MODULE_WORLDMAP then
                            local newestAreaId =  app.gameMgr:GetUserInfo().newestAreaId
                            if newestAreaId >= 2 or app.gameMgr:GetUserInfo().level > 16    then
                                if not  stepAllInfos[tostring(moduleId)]["1047"]  then
                                    stepAllInfos[tostring(moduleId)]["1047"]  =  json.decode([[{
                                      "id": 1047,
                                      "guideModuleId": "1001",
                                      "type": "2",
                                      "location": [
                                        "2",
                                        "3"
                                      ],
                                      "highlight": [
                                        [
                                          "-5",
                                          "-5"
                                        ],
                                        [
                                          "195",
                                          "161"
                                        ]
                                      ],
                                      "highlightLocation": [
                                        [
                                          "HomeMediator#HomeSceneView#home.HomeMapPanel#HomeMapPanelView#QuestNodeLayer#TYPE_QUEST_4"
                                        ]
                                      ],
                                      "content": "点击此处<red>进入副本</red>。",
                                      "delay": "0.4",
                                      "exitSkip": "",
                                      "exitAdd": "",
                                      "goods": []
                                 }]])
                                end
                            else
                                curModuleSteps[tostring(name)] = nil
                            end
                        else
                            curModuleSteps[tostring(name)] = nil
                        end

                    end
                end
            end
            local keys = sortByKey(stepAllInfos[tostring(moduleId)])
            local minId = checkint(keys[1])
            self.moduleId = moduleId
            self.modules[tostring(moduleId)] = minId --初始化数据
            self:FilterSteps() --重新变步骤
            --做一个移除
            if table.nums(self.filterSteps) > 0 then
                if self.stage then
                    self.stage:RemoveMask()
                end
                self:BootStart(jumpConfId)--然后开始引导
            end
        end
    end
end

function LDirector:FilterSteps(jumpConfId)
    self.stepId = 1--步数始终为1
    self.filterSteps = {} --恢复初始数据
    -- for moduleId,stepId in pairs(self.modules) do
    local remoteStepId = checkint(self.modules[tostring(self.moduleId)])
    logs('[LDirector]', string.fmt('---filterSteps--self.moduleId-- %1 %2', remoteStepId, self.moduleId))
    if self.moduleId == GUIDE_MODULES.MODULE_LOBBY and  remoteStepId == 0 then
        --EVENTLOG.Log(EVENTLOG.EVENTS.newBieGuideStart)
        DotGameEvent.SendEvent(DotGameEvent.EVENTS.GUIDE_START)
    end
    local moduleInfo = modules[tostring(self.moduleId)]
    if moduleInfo and stepAllInfos[tostring(self.moduleId)] then
        local steps = sortByKey(stepAllInfos[tostring(self.moduleId)])
        local maxId = checkint(steps[#steps])
        if remoteStepId <=  maxId then
            --表示当前模块末结束的,需要接这个模块做相关的引导
            local skipIdx = {}
            if moduleInfo.keyStep then
                for idx,val in ipairs(moduleInfo.keyStep) do
                    if remoteStepId > checkint(val) then
                        --需要跳过的关键步骤
                        for _, vv in ipairs(moduleInfo.keyStepAssemble[idx]) do
                            table.insert(skipIdx, checkint(vv))
                        end
                    end
                end
            end
            for _,stepInfo in pairs(steps) do
                --添加过滤需要跳过的步骤
                if skipIdx and table.nums(skipIdx) > 0 then
                    local shouldSkip = false
                    for idx,val in ipairs(skipIdx) do
                        if val == checkint(stepInfo) then
                            shouldSkip = true
                            break
                        end
                    end

                    if not shouldSkip then
                        table.insert(self.filterSteps, stepInfo)
                    end
                else
                    table.insert(self.filterSteps, stepInfo)
                end
            end
        end
    end

    if table.nums(self.filterSteps) > 0 then
        if jumpConfId then
            self.stepId = self:jumpConfId_(jumpConfId)
        end
        local isOpen = CommonUtils.ModulePanelIsOpen()
        local stepPath1 = 'HomeMediator#HomeSceneView#home.HomeExtraPanel#HomeExtraPanelView#uiLayer#CLOSE_SLIDE'
        local stepPath2 = 'HomeMediator#HomeSceneView#LeftView#Button'
        local skipPos = -1
        local stepInfos = stepAllInfos[tostring(self.moduleId)]
        for idx,val in ipairs(self.filterSteps) do
            if stepInfos and stepInfos[tostring(val)] then
                local curStepInfo = stepInfos[tostring(val)]
                if checkint(curStepInfo.type) == 2 then
                    local highlightLocation = curStepInfo.highlightLocation
                    if highlightLocation and table.nums(highlightLocation) > 0 then
                        if checkint(self.moduleId) == GUIDE_MODULES.MODULE_PET then
                            if #highlightLocation[1] > 0 and highlightLocation[1][1] == stepPath1 and not isOpen then
                                --将第一步移除
                                skipPos = idx
                                break
                            end
                        else
                            if #highlightLocation[1] > 0 and highlightLocation[1][1] == stepPath2 and isOpen then
                                --将第一步移除
                                skipPos = idx
                                break
                            end
                        end
                    end
                end
            end
        end
        if checkint(self.moduleId) == GUIDE_MODULES.MODULE_WORLDMAP then
            local newestAreaId =  app.gameMgr:GetUserInfo().newestAreaId
            if newestAreaId >= 2  then
                for skipPos = 1, #self.filterSteps do
                    if checkint(self.filterSteps[skipPos])  == 144   then
                        table.remove(self.filterSteps,skipPos)
                    end
                end
            end
        end
        if skipPos > 0 then
            --将第一步移除
            table.remove(self.filterSteps,skipPos)
        end
        self.isGuiding = true
    end

    -- dump(self.filterSteps)
end
--[[
开始执行剧情逻辑功能
--]]
function LDirector:Start( )
    --第一次启动的时候要判断上次引起起始位置
    if next(self.modules or {}) == nil then
        self:SetRemoteModules(app.gameMgr:GetUserInfo().guide)
    end
	if (not self.updateHandler) and (not self.isStart) and (not app.uiMgr:Scene():getChildByTag(GameSceneTag.Guide_GameSceneTag)) then
        -- self.isStart = true --记录当前对白是否已开始执行
        local view = require('Frame.lead_visitor.BootLoader').new({director = self})
        display.commonUIParams(view, {po = display.center})
        app.uiMgr:Scene():addChild(view, GameSceneTag.Guide_GameSceneTag, GameSceneTag.Guide_GameSceneTag)
        --启动客户端条件达成检测的逻辑功能
        --将主界面进入游戏的判断与第一次启动的判断综合进行合并起来
        -- self:RealStart() --功能正式开始启动逻辑
        -- self:CheckCondition() --检测是否有引导的逻辑
	end
end


function LDirector:RealStart(jumpConfId)
    --如果没有引导的逻辑需要进行不在进行下一步操作
    if (not self.updateHandler) and (not self.isStart) and self.stage then
        self.isStart = true --记录当前对白是否已开始执行
        xTry(function()
            print('-------------initial moduleId-------->>>', self.moduleId)
            logs('[LDirector]', string.fmt('-------------initial moduleId-------->>> %1', self.moduleId))
            local moduleKeys = sortByKey(modules)
            local lockedModules = {}
            local playerLevel = checkint(app.gameMgr:GetUserInfo().level)
            for name,moduleId in pairs(moduleKeys) do
                --当前所有模块遍历
                local isFinished = self:OneTimeModuleFinished(moduleId)
                if isFinished == 0 or isFinished == 2 then
                    local triveModuleInfo = modules[tostring(moduleId)]
                    local triggerType = checkint(triveModuleInfo.triggerCondition[1])
                    -- local con = checkint(triveModuleInfo.triggerCondition[2])
                    if triggerType == TRIGGER_CONDITIONS.QUEST_TASK or triggerType == TRIGGER_CONDITIONS.TRIGGER_FIRST_TIME then
                        --首次进入的条件与第一次进入的条件判断
                        table.insert(lockedModules, triveModuleInfo)
                    else
                        --等级达到某一个条件时的逻辑
                        local level = checkint(triveModuleInfo.triggerCondition[2])
                        --玩家等级达到此等级时
                        if level == playerLevel then
                            table.insert(lockedModules, triveModuleInfo)
                        end
                    end
                end
            end
            if table.nums(lockedModules) > 0 then
                --开始判断是否解锁的逻辑
                local curModuleInfo = lockedModules[1]
                local minModuleId = checkint(curModuleInfo.id)
                for name,val in pairs(lockedModules) do
                    if minModuleId > checkint(val.id) then
                        minModuleId = checkint(val.id)
                        curModuleInfo = val
                    end
                end
                if DEBUG > 0 then
                    -- dump(lockedModules)
                    print('------------->>', minModuleId)
                    logs('[LDirector]', string.fmt('------------->> %1', minModuleId))
                end
                local triggerType = checkint(curModuleInfo.triggerCondition[1])
                local moduleId = checkint(curModuleInfo.id)
                if triggerType == TRIGGER_CONDITIONS.TRIGGER_PLAYER_LEVEL then
                    local level = checkint(app.gameMgr:GetUserInfo().level)
                    local triggeLevel = checkint(curModuleInfo.triggerCondition[2])
                    --是否需要添加当前等级的判断
                    if triggeLevel == level then
                        funLog(Logger.INFO,'-----------------------根据等级解锁剧情任务 ------------------')
                        logs('[LDirector]', '-----------------------根据等级解锁剧情任务 ------------------')
                        --等级达到多少时的操作
                        local preKeys = sortByKey(stepAllInfos[tostring(moduleId)])
                        local minStep = checkint(preKeys[1])
                        --移除需要跳过的引导步骤
                        local curModuleSteps = stepAllInfos[tostring(moduleId)]
                        if curModuleSteps then
                            for name,val in pairs(curModuleSteps) do
                                if checkint(val.exitSkip) == 1 and app:RetrieveMediator('HomeMediator') then --需要跳过的步骤
                                    curModuleSteps[tostring(name)] = nil
                                end
                            end
                            self.moduleId = moduleId
                            self.stopBlocking = false
                            self:FilterSteps(jumpConfId)
                            self.stage:Start(jumpConfId)
                        end
                    else
                        --表示不需要出现引导的逻辑
                        self.isGuiding = false
                        self.stage:StopBlockTouch()
                    end
                elseif triggerType == TRIGGER_CONDITIONS.TRIGGER_FIRST_TIME then
                    --第二种类型进入模块触发的类型
                    local curModuleInfo = lockedModules[1]
                    local minModuleId = 0
                    for name,val in pairs(lockedModules) do
                        local triggleType = checkint(val.triggerCondition[1])
                        if triggleType == TRIGGER_CONDITIONS.TRIGGER_FIRST_TIME then
                            local isFinished = self:OneTimeModuleFinished(val.id)
                            if isFinished == 2 then
                                curModuleInfo = val
                                minModuleId = checkint(val.id)
                                break
                            end
                        end
                    end
                    if DEBUG > 0 then
                        -- dump(lockedModules)
                        -- print('------------->>', minModuleId)
                        logs('[LDirector]', string.fmt('------------->> %1', minModuleId))
                    end
                    local moduleId = checkint(curModuleInfo.id)
                    funLog(Logger.INFO, '-----------------------根据第一次进入------------------')
                    logs('[LDirector]', '-----------------------根据第一次进入------------------')
                    --餐厅装修的逻辑，第一次进入的逻辑，断线重新进入加步骤
                    local triggerModule = checkint(curModuleInfo.triggerCondition[2])
                    --可能需要重新接上的逻辑
                    -- local lmediator = shareFacade:RetrieveMediator(TRIGGER_MEDIATOR[tostring(triggerMode)])
                    -- if lmediator then --表示正在当前模块
                    if moduleId == GUIDE_MODULES.MODULE_TALENT or moduleId == GUIDE_MODULES.MODULE_PET and minModuleId > 0 then
                        funLog(Logger.INFO, '-----------------------根据第一次进入------------------')
                        logs('[LDirector]', '-----------------------根据第一次进入------------------')
                        local isFinished = self:OneTimeModuleFinished(moduleId)
                        if isFinished == 2 then
                            --移除需要跳过的引导步骤
                            local curModuleSteps = stepAllInfos[tostring(moduleId)]
                            if curModuleSteps then
                                for name,val in pairs(curModuleSteps) do
                                    if isFinished == 0 then
                                        if checkint(val.exitAdd) == 1 then --需要跳过的步骤
                                            curModuleSteps[tostring(name)] = nil
                                        end
                                    end
                                end
                                self.moduleId = moduleId
                                self.stopBlocking = false
                                self:FilterSteps(jumpConfId)
                                self.stage:Start(jumpConfId)
                            end
                        else
                            --表示不需要出现引导的逻辑
                            self.isGuiding = false
                            self.stage:StopBlockTouch()
                        end
                    else
                        --表示不需要出现引导的逻辑
                        self.isGuiding = false
                        self.stage:StopBlockTouch()
                    end
                else
                    --其他情况下的引导，进入游戏后的引导显示的逻辑
                    funLog(Logger.INFO, '-----------------------<<< 根据刚进入游戏进入>>>------------------')
                    logs('[LDirector]', '-----------------------<<< 根据刚进入游戏进入>>>------------------')
                    if self.modules[tostring(minModuleId)] then
                        ---在服务端已存在数据的记录判断是否做完
                        local remoteStepId = checkint(self.modules[tostring(minModuleId)])
                        local keys = sortByKey(stepAllInfos[tostring(minModuleId)])
                        local maxId = checkint(keys[#keys])
                        print('----maxId ---', maxId)
                        logs('[LDirector]', string.fmt('---- maxId --- %1', maxId))
                        if remoteStepId < maxId then
                            self.moduleId = minModuleId
                            print('===========查找到数据=========', self.moduleId)
                            logs('[LDirector]', string.fmt('===========查找到数据========= %1', self.moduleId))
                            self.stopBlocking = false
                            self:FilterSteps(jumpConfId)
                            self.stage:Start(jumpConfId)
                        end
                    else
                        self.moduleId = minModuleId
                        print('===========查找到数据=========', self.moduleId)
                        logs('[LDirector]', string.fmt('===========查找到数据========= %1', self.moduleId))
                        self.stopBlocking = false
                        self:FilterSteps(jumpConfId)
                        self.stage:Start(jumpConfId)
                    end
                end
            else
                self.stage:StopBlockTouch()
            end
        end,__G__TRACKBACK__)
    end
end


function LDirector:BootStart(jumpConfId)
    if not self.stage then self:Start() end
    if not self.isStart then self:RealStart(jumpConfId) end
    --开始引导流程
    local moduleInfo = modules[tostring(self.moduleId)]
    if moduleInfo then
        --发物品道具的请求接口,完成后再进行下面的引导
        -- print('---guide--start---here-----')
        local remoteStepId = checkint(self.modules[tostring(self.moduleId)])
        -- local keys = sortByKey(stepAllInfos[tostring(self.moduleId)])
        -- local minId = checkint(keys[1])
        local stepId = checkint(self.filterSteps[1])
        -- if remoteStepId == stepId then
            --需要请求数据
            -- xTry(function()
                -- local stepId = self.filterSteps[1]
                if modules and modules[tostring(self.moduleId)] then
                    local mmInfo = modules[tostring(self.moduleId)]
                    -- local goods = mmInfo.goods
                    -- if goods and table.nums(goods) > 0 then
                    -- if stepId then
                    -- if stepId == 0 then stepId = 1 end
                    -- app.httpMgr:Post('Player/guide', 'SavePlayerGuide',{module = self.moduleId, step = stepId, isStart = 1})
                    -- else
                    -- self:MoveNext(false)
                    -- end
                    -- else
                    --没有物品的请求的时候
                    if checkint(mmInfo.playStoreId) > 0 and remoteStepId == stepId and self.stepId == 1 then
                        --添加剧情引导的逻辑
                        if self.stage then
                            self.stage:ShowPlotDialog(checkint(mmInfo.playStoreId))
                        end
                    else
                        self:MoveNext(false)
                    end
                    -- end
                end
            -- end,__G__TRACKBACK__)
    else
        if self.stage then
            self.stage:StopBlockTouch()
        end
    end
end


function LDirector:ClearCurModuleSteps()
    self.filterSteps = {}
end

--[[
--检测一定的条件是否正常可达
--]]
function LDirector:CheckCondition()
    local userInfo = app.gameMgr:GetUserInfo()
    if userInfo and modules and stepAllInfos then
        --用户信息
        local newestQuestId = checkint(userInfo.newestQuestId)
        local newestPlotTask = checktable(userInfo.newestPlotTask)
        local moduleIds = sortByKey(modules)
        local haveGuide = 0
        for idx,moduleId in ipairs(moduleIds) do
            local moduleInfo = modules[tostring(moduleId)]
            local triggerType = checkint(moduleInfo.triggerCondition[1])
            local id = checkint(moduleInfo.triggerCondition[2])
            --条件判断
            if triggerType == TRIGGER_CONDITIONS.QUEST_TASK then
                -- 主线任务时显示
                if id == newestQuestId then
                    --已达成条件的模块
                    if self.modules[tostring(moduleId)] then
                        ---在服务端已存在数据的记录判断是否做完
                        local remoteStepId = checkint(self.modules[tostring(moduleId)])
                        local keys = sortByKey(stepAllInfos[tostring(moduleId)])
                        local maxId = checkint(keys[#keys])
                        print('----maxId ---', maxId)
                        logs('[LDirector]', string.fmt('---- maxId --- %1', maxId))
                        if remoteStepId < maxId then
                            self.moduleId = checkint(moduleId)
                            print('===========查找到数据=========', self.moduleId)
                            logs('[LDirector]', string.fmt('===========查找到数据========= %1', self.moduleId))
                            haveGuide = 1
                            self.stopBlocking = false
                            self:FilterSteps()
                            self.stage:Start()
                            break
                        end
                    else
                        self.moduleId = checkint(moduleId)
                        print('===========查找到数据=========', self.moduleId)
                        logs('[LDirector]', string.fmt('===========查找到数据========= %1', self.moduleId))
                        haveGuide = 1
                        self.stopBlocking = false
                        self:FilterSteps()
                        self.stage:Start()
                        break
                    end
                end
            elseif triggerType == TRIGGER_CONDITIONS.STORY_TASK then
                -- 主线剧情任务时显示
                if id == checkint(newestPlotTask.id) and checkint(newestPlotTask.status) == 2 then
                    --已解锁的剧情任务且是已接受的逻辑
                    --已达成条件的模块
                    if self.modules[tostring(moduleId)] then
                        ---在服务端已存在数据的记录判断是否做完
                        local remoteStepId = checkint(self.modules[tostring(moduleId)])
                        local keys = sortByKey(stepAllInfos[tostring(moduleId)])
                        local maxId = checkint(keys[#keys])
                        if remoteStepId < maxId then
                            self.moduleId = checkint(moduleId)
                        end
                    else
                        self.moduleId = checkint(moduleId)
                    end
                    haveGuide = 1
                    self.stopBlocking = false
                    self:FilterSteps()
                    self.stage:Start()
                    break
                end
            end
        end

        if haveGuide == 0 then
            --如果不存在引导中的逻辑
            if not self.stopBlocking then
                print('--- no module data --')
                logs('[LDirector]', '--- no module data --')
                self.stopBlocking = true
                -- self.isStart = false--记录当前对白是否已开始执行
                self.stage:StopBlockTouch()
            end
        end
    end
end

function LDirector:TouchDisable(isable)
    if self.stage then
        self.stage:TouchDisable(isable)
    end
end

--[[
设置剧情舞台
@param stage 舞台
--]]
function LDirector:SetStage( stage)
	self.stage = stage
end

function LDirector:GetStage(  )
	return self.stage
end

--相关的方法操作
--[[
--移动到下一个命令
--]]
function LDirector:MoveNext( isNext )
    if isNext == nil then isNext = true end
    if self.filterSteps and table.nums(self.filterSteps) > 0 then
        if isNext == true then
            self.stepId = self.stepId + 1 --添加一个stepid数据
        end
        local stepId = self.filterSteps[checkint(self.stepId)]
        if stepId then
            cclog('---------stepId---------', stepId)
            logs('[LDirector]', string.fmt('---------stepId--------- %1 isNext %2', stepId, isNext))
            local stepInfos = stepAllInfos[tostring(self.moduleId)]
            if stepInfos and stepInfos[tostring(stepId)] then
                if self.stage then
                    self.stage:MoveStep(stepInfos[tostring(stepId)])
                end
            else
                if self.stage then
                    self.stage:StopBlockTouch()
                end
                funLog(Logger.DEBUG, string.format('------step over -- %d ----', self.stepId))
                logs('[LDirector]', string.fmt('------step over -- %d ----', self.stepId))
            end
        else
            -- self.stage:StopBlockTouch()
            local len = table.nums(self.filterSteps)
            local stepId = self.filterSteps[len]
            local stepInfos = stepAllInfos[tostring(self.moduleId)]
            if stepInfos and stepInfos[tostring(stepId)] then
                if self.stage then
                    self.stage:RemoveMask() --移除手指相关的节点的逻辑
                end
                stepId = checkint(stepInfos[tostring(stepId)].id)
                self.modules[tostring(self.moduleId)] = stepId
                funLog(Logger.DEBUG, string.format('------step= %d ----', stepId))
                logs('[LDirector]', string.fmt('------step= %1 ----', stepId))
                -- self.stage:StopBlockTouch()
                --如果是已经结束的引导模块，然后进行http请求同步服务端数据请求
                app.httpMgr:Post('Player/guide', 'SavePlayerGuide', {module = self.moduleId, step = checkint(stepId)})
            else
                if self.stage then
                    self.stage:StopBlockTouch()
                end
            end
        end
    end
end


function LDirector:CanSkip()
    local canSkip = false
    local moduleInfo = modules[tostring(self.moduleId)]
    if moduleInfo and checkint(moduleInfo.canSkip) == 2 then
        canSkip = true
    end
    return canSkip
end

function LDirector:PublicForceSkip()
    if self:IsInGuiding() then
        if self.stage then
            local touchView = self.stage:getChildByName('SKIP_SHOW')
            if touchView then
                self.stage:SkipMask()
                touchView:setVisible(true)
            end
        end
    end
end

function LDirector:PublicShowSkip()
    if self:IsInGuiding() then
        if self:CanSkip() and self.stage then
            local touchView = self.stage:getChildByName('SKIP_SHOW')
            if touchView then
                self.stage:SkipMask()
                touchView:setVisible(true)
            end
        end
    end
end

function LDirector:FinishLocalModule(moduleId)
    local preKeys = sortByKey(stepAllInfos[tostring(moduleId)])
    local maxStep = checkint(preKeys[#preKeys])
    self.modules[tostring(moduleId)] = maxStep
end
function LDirector:SkipGuide()
    local moduleInfo = modules[tostring(self.moduleId)]
    if moduleInfo then
        --表示可以跳过逻辑的页面
        local stepInfos = stepAllInfos[tostring(self.moduleId)]
        local skipButton = self.stage:getChildByName('SKIP_SHOW')
        if skipButton then skipButton:setVisible(false) end
        if stepInfos then
            local preKeys = sortByKey(stepAllInfos[tostring(self.moduleId)])
            local maxStep = checkint(preKeys[#preKeys])
            self.modules[tostring(self.moduleId)] = maxStep
            self.stage:StopBlockTouch()
            self.filterSteps = {}
            --如果是已经结束的引导模块，然后进行http请求同步服务端数据请求
            app.httpMgr:Post('Player/guide', 'SavePlayerGuide', {module = self.moduleId, step = maxStep})
        else
            self.filterSteps = {}
            self.stage:StopBlockTouch()
        end
    else
        self.filterSteps = {}
        self.stage:StopBlockTouch()
    end
    --[[
    self.filterSteps = {}
    self.stage:StopBlockTouch()
    --]]
end
function LDirector:ClearModuleData(moduleId)
    self.modules[tostring(moduleId)] = nil
end
function LDirector:GetModuleData(moduleId)
    return  self.modules[tostring(moduleId)]
end
return LDirector
