--[[
 * descpt : 世界BOSS手册中介者
]]
local NAME = 'WorldBossManualMediator'
local BossConfigParser = require('Game.Datas.Parser.WorldBossQuestConfigParser')
local MANUAL_CONFS = CommonUtils.GetConfigAllMess(BossConfigParser.TYPE.MANUAL, 'worldBossQuest') or {}
local WorldBossManualMediator = class(NAME, mvc.Mediator)

local facadeInstance = AppFacade.GetInstance()
local uiMgr          = facadeInstance:GetManager('UIManager')
local gameMgr        = facadeInstance:GetManager("GameManager")

local BUTTON_TAG = {
    BACK      = 100, 
    RULE      = 101,
}

local WORLD_BOSS_MANUAL_CLICK_PLAYER_HEAD = 'WORLD_BOSS_MANUAL_CLICK_PLAYER_HEAD'
local WORLD_BOSS_MANUAL_ENABLED_LIST      = 'WORLD_BOSS_MANUAL_ENABLED_LIST'

function WorldBossManualMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
end


-------------------------------------------------
-- inheritance method

function WorldBossManualMediator:Initial(key)
    self.super.Initial(self, key)

    self.isControllable_ = true
    self.clickCellTag = 1
    self.datas = {}

    -- create view
    local viewComponent = require('Game.views.worldboss.WorldBossManualView').new()
    self.viewData_      = viewComponent:getViewData()
    self:SetViewComponent(viewComponent)
    -- add layer
    self.ownerScene_ = uiMgr:GetCurrentScene()
    display.commonUIParams(viewComponent,{po = display.center, ap = display.CENTER})
    self:getOwnerScene():AddDialog(viewComponent)

    -- init data
    self:initData_()
    -- init view
    self:initView_()
end

function WorldBossManualMediator:initData_()
    -- for questId, manualConf in pairs(MANUAL_CONFS) do
        
    -- end
    
    -- local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
    -- logInfo.add(5, tableToString(cardMgr:GetCardSkinConfig(300021)))

end

function WorldBossManualMediator:initManualData()
    for i, manualData in ipairs(self.manualDatas or {}) do
        if manualData.manualConf == nil then
            local questId = manualData.questId
            local testReward = manualData.testReward
            manualData.manualConf = MANUAL_CONFS[tostring(questId)] or {}
            manualData.canReceiveCount = 0
            manualData.frameId = self:getListFrameId(testReward, manualData.manualConf.test or {})
            
            self:sortTopRank(manualData.topRank)
            if self.clickCellTag == i then
                self:initStageDatas(i)
            end
        end
    end
end

--[[
    根据试炼Id初始化试炼阶段数据
]]
function WorldBossManualMediator:initStageDatas(manualDataIndex)
    local manualData = checktable(self.manualDatas)[manualDataIndex]
    if manualData == nil then return end
    if manualData.stageDatas ~= nil then return end

    local stageDatas = {}
    local testReward = manualData.testReward
    local manualConf = manualData.manualConf
    local questId = manualConf.questId
    local test = manualConf.test
    local progress = checkint(manualData.myMaxDamage)

    local testCompleteState = {}
    for testId, testData in pairs(test) do
        local testRewardList = testReward[tostring(testId)] or {}
        local testRewardMap  = {}
        for i, v in ipairs(testRewardList) do
            testRewardMap[tostring(v)] = v
        end
        
        local stageDataCount = #testData
        testCompleteState[testId] = testCompleteState[testId] or {}
        testCompleteState[testId].stageDataCount = stageDataCount
        testCompleteState[testId].completeStageCount = 0

        for stage = 1, stageDataCount do
            local stageData = testData[stage] or {}
            local hasDrawn = testRewardMap[tostring(stage)] ~= nil and 1 or 0

            local targetNum = checkint(stageData.require)
            if targetNum <= progress and hasDrawn <= 0 then
                manualData.canReceiveCount  = manualData.canReceiveCount + 1
            end
            if hasDrawn > 0 then
                testCompleteState[testId].completeStageCount = testCompleteState[testId].completeStageCount + 1
            end         
            table.insert(stageDatas, {
                questId = questId,
                testId = testId,
                stage = stage,
                name = stageData.name,
                targetNum = targetNum,
                progress = progress,
                status = 0,
                hasDrawn = hasDrawn,
                rewards = stageData.rewards,
            })
        end
    end
    manualData.testCompleteState = testCompleteState
    manualData.stageDatas = stageDatas
    return stageDatas
end

function WorldBossManualMediator:initView_()
    local viewData = self:getViewData()

    local actionBtns = viewData.actionBtns
    for tag, btn in pairs(actionBtns) do
        display.commonUIParams(btn, {cb = handler(self, self.onButtonAction)})
        btn:setTag(tag)
    end

    local zoomSliderList = viewData.zoomSliderList
    
    -- local cellSize = cc.size(214,232)
    zoomSliderList:setCellChangeCB(handler(self, self.onListCellChangeAction))
    zoomSliderList:setIndexPassChangeCB(function(sender, index)
        -- logInfo.add(5, 'pass index = ' .. index)
    end)
    zoomSliderList:setIndexOverChangeCB(function(sender, index)
        local viewData       = self:getViewData()
        local zoomSliderList = viewData.zoomSliderList
        local usedCellMap_ = zoomSliderList.usedCellMap_
        if self.clickCellTag ~= index then            
            self.clickCellTag = index
            self:initStageDatas(index)
            self:GetViewComponent():refreshUI(checktable(self.manualDatas)[self.clickCellTag])
        end

        local usedCellMap_   = zoomSliderList.usedCellMap_
        for index, cell in pairs(usedCellMap_) do
            self:updateCellSelect(cell.viewData, false)      
        end

        self:updateCellSelectState(index, true)

    end)

    local rewardBox = viewData.rewardBox
    display.commonUIParams(rewardBox, {animate = false, cb = handler(self, self.onClickRewardBoxAction)})

end

function WorldBossManualMediator:CleanupView()
    local viewComponent = self:GetViewComponent()
    if self.ownerScene_ and viewComponent and not tolua.isnull(viewComponent) then
        self.ownerScene_:RemoveDialog(viewComponent)
        self.ownerScene_ = nil
    end
end


function WorldBossManualMediator:OnRegist()
    regPost(POST.WORLD_BOSS_DAMAGE_MANUAL)
    -- regPost(POST.WORLD_BOSS_DAMAGE_TESTREWARD)
    self:SendSignal(POST.WORLD_BOSS_DAMAGE_MANUAL.cmdName)
end
function WorldBossManualMediator:OnUnRegist()
    unregPost(POST.WORLD_BOSS_DAMAGE_MANUAL)
    -- unregPost(POST.WORLD_BOSS_DAMAGE_TESTREWARD)

    -- 更新总红点
    self:updateTotalRedPoint()
end

function WorldBossManualMediator:InterestSignals()
    return {
        ------------ local ------------
        WORLD_BOSS_MANUAL_CLICK_PLAYER_HEAD,            -- 点击玩家头像
        WORLD_BOSS_MANUAL_ENABLED_LIST,
        ------------ server ------------
        POST.WORLD_BOSS_DAMAGE_MANUAL.sglName,
        POST.WORLD_BOSS_DAMAGE_TESTREWARD.sglName,
    }
end
function WorldBossManualMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody()

    if name == WORLD_BOSS_MANUAL_CLICK_PLAYER_HEAD then
        local rankData = body.rankData
        
        local view = require('Game.views.worldboss.WorldBossManualPlayerCardShowView').new( {playerInfo = rankData })
        display.commonUIParams(view,{po = display.center, ap = display.CENTER})
        self:getOwnerScene():AddDialog(view)

    elseif name == WORLD_BOSS_MANUAL_ENABLED_LIST then
        local isEnabled = body.isEnabled

        local viewData = self:getViewData()
        local zoomSliderList = viewData.zoomSliderList
        zoomSliderList:setEnabled(isEnabled)

    elseif name == POST.WORLD_BOSS_DAMAGE_MANUAL.sglName then
        
        self.manualDatas = body.manual or {}
        self:initManualData()

        local viewData = self:getViewData()
        local zoomSliderList = viewData.zoomSliderList
        zoomSliderList:setCellCount(#self.manualDatas)
        zoomSliderList:reloadData()
        -- logInfo.add(5, tableToString(self.manualDatas[self.clickCellTag]))
        self:GetViewComponent():refreshUI(checktable(self.manualDatas)[self.clickCellTag])

        self:updateTotalRedPoint()
    elseif name == POST.WORLD_BOSS_DAMAGE_TESTREWARD.sglName then

        local requestData = body.requestData
        local questId     = requestData.questId
        local testId      = tostring(requestData.testId)
        local stage       = requestData.stage
        local cellTag     = requestData.cellTag

        local manualData  = self:getManualDataByIndex(cellTag)
        manualData.canReceiveCount = manualData.canReceiveCount - 1
        self:GetViewComponent():updateRedPointImg(manualData.canReceiveCount)

        local testReward = manualData.testReward
        testReward[testId] = testReward[testId] or {}
        table.insert(testReward[testId], stage)
        
        local testCompleteState = manualData.testCompleteState
        local testState = testCompleteState[testId] or {}

        testState.completeStageCount = testState.completeStageCount + 1
        local stageDataCount = testState.stageDataCount
        if testState.completeStageCount >= stageDataCount then
            manualData.frameId = self:getListFrameId(testReward, manualData.manualConf.test or {})
            local cell = self:getListUsedCell()[cellTag]
            self:GetViewComponent():updateCellFrame(cell.viewData, manualData.frameId)
        end

    end
end


-------------------------------------------------
-- get / set

function WorldBossManualMediator:getViewData()
    return self.viewData_
end

function WorldBossManualMediator:getOwnerScene()
    return self.ownerScene_
end

function WorldBossManualMediator:getListUsedCell()
    local viewData        = self:getViewData()
    local zoomSliderList = viewData.zoomSliderList
    return zoomSliderList.usedCellMap_
end

function WorldBossManualMediator:getManualDataByIndex(index)
    local manualData = checktable(self.manualDatas)[index] or {}
    return manualData
end

function WorldBossManualMediator:getListFrameId(testReward, test)
    local frameId = 0
    local stageDatas = {}
    local tempTestId = 0
    for testId, v in pairs(testReward) do
        if #(v) == #(test[testId] or {}) then
            tempTestId = math.max(tempTestId, checkint(testId))
        end
    end
    frameId = table.nums(test) - tempTestId + 1   
    return frameId 
end
-------------------------------------------------
-- public method

function WorldBossManualMediator:updateCellSelectState(index, isSelect)
    local viewData       = self:getViewData()
    local zoomSliderList = viewData.zoomSliderList
    local usedCellMap_   = zoomSliderList.usedCellMap_
    
    local cell           = usedCellMap_[index]
    if cell then
        self:updateCellSelect(cell.viewData, isSelect)      
    end
end

function WorldBossManualMediator:updateCellSelect(viewData, isSelect)
    local selectBg = viewData.selectBg
    selectBg:setVisible(isSelect)
end

function WorldBossManualMediator:updateTotalRedPoint()
    local isHasRedPoint = false
    for i, v in ipairs(self.manualDatas or {}) do
        if v.canReceiveCount > 0 then
            isHasRedPoint = true
            break
        end
    end
    gameMgr:SetWorldBossTestReward(isHasRedPoint and 1 or 0)
end

-------------------------------------------------
-- private method

function WorldBossManualMediator:onListCellChangeAction(pcell, index)
    local cell = pcell
    if cell == nil then
        logInfo.add(5, '--------------')
        cell = self:GetViewComponent():CreateListCell()
    end

    xTry(function()
        local viewData    = cell.viewData     
        local manualData  = self:getManualDataByIndex(index)

        self:GetViewComponent():updateListCell(viewData, manualData)
	end,__G__TRACKBACK__)

    return cell
end

function WorldBossManualMediator:sortTopRank(topRank)
    table.sort(topRank, function (a, b)
        if a == nil then return true end
        if b == nil then return false end
        return checkint(a.playerRank) < checkint(b.playerRank)
    end)
end

function WorldBossManualMediator:sortStageDatas(stageDatas)
    local getPriority = function (data)
        local hasDrawn = data.hasDrawn
        local priority = 0
        if hasDrawn > 0 then
            priority = 99
        end
        return priority
    end
    table.sort(stageDatas, function (a, b)
        if a == nil then return true end
        if b == nil then return false end

        local aPriority = getPriority(a)
        local bPriority = getPriority(b)
        
        local aTargetNum = a.targetNum
        local bTargetNum = b.targetNum

        if aPriority == bPriority then
            return aTargetNum < bTargetNum
        end

        return aPriority < bPriority
    end)
    return stageDatas
end

-------------------------------------------------
-- handler

function WorldBossManualMediator:onButtonAction(sender)
    local tag = sender:getTag()
    if tag == BUTTON_TAG.BACK then
        PlayAudioByClickClose()
        self:GetFacade():UnRegsitMediator(NAME)
    elseif tag == BUTTON_TAG.RULE then
        uiMgr:ShowIntroPopup({moduleId = MODULE_DATA[tostring(RemindTag.WORLD_BOSS_MANUAL)]})
    end
end

function WorldBossManualMediator:onClickRewardBoxAction(sender)
    -- self:initStageDatas(self.clickCellTag)
    local manualData = checktable(self.manualDatas)[self.clickCellTag]

    local data = {
        tag = 110126,
        isAddDialog = true,
        cellTag =  self.clickCellTag,
        activityHomeDatas = {
            stageDatas =  self:sortStageDatas(manualData.stageDatas),
            myMaxDamage = checkint(manualData.myMaxDamage)
        }
    }
    local mediator = require( 'Game.mediator.ActivityPropExchangeMediator').new({data = data})
	AppFacade.GetInstance():RegistMediator(mediator)
end

return WorldBossManualMediator
