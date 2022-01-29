--[[
 * descpt : 夏活 第二级 地图 中介者
]]
local NAME = 'summerActivity.SummerActivitySecondMapMediator'
local SummerActivitySecondMapMediator = class(NAME, mvc.Mediator)

local uiMgr    = app.uiMgr    or AppFacade.GetInstance():GetManager('UIManager')
local gameMgr  = app.gameMgr  or AppFacade.GetInstance():GetManager("GameManager")
local timerMgr = app.timerMgr or AppFacade.GetInstance():GetManager("TimerManager")
local summerActMgr = AppFacade.GetInstance():GetManager("SummerActivityManager")

local NODE_STATUS = {
    UNOPEN           = 0,   -- 未开启
    OPEN_AND_NOTPASS = 1,   -- 打开但未通过
    PASS             = 2,   -- 通过
}

local NODE_TYPES = {
    UNOPEN   = 0,   -- 未开启
    PLOT     = 1,   -- 剧情
    MONSTER  = 2,   -- 怪物
    BOSS     = 3,   -- BOSS
}
local changeTeamMemberViewTag = 888

local LOCAL_SA_TEAM_DATA_KEY = 'LOCAL_SA_TEAM_DATA_KEY'

function SummerActivitySecondMapMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
    self.teamData = {}
end

-------------------------------------------------
-- inheritance method
function SummerActivitySecondMapMediator:Initial(key)
    self.super.Initial(self, key)

    self.isControllable_ = true
    
    -- create view
    local viewComponent = require('Game.views.summerActivity.SummerActivitySecondMapView').new()
    self.viewData_      = viewComponent:getViewData()
    self:SetViewComponent(viewComponent)
    -- add layer
    self:initOwnerScene_()
    -- display.commonUIParams(viewComponent,{po = display.center, ap = display.CENTER})
    -- self:getOwnerScene():AddDialog(viewComponent)

    -- init view
    self:initView_()
    
end

function SummerActivitySecondMapMediator:initOwnerScene_()
    self.ownerScene_ = uiMgr:GetCurrentScene()
end

function SummerActivitySecondMapMediator:initView_()
    local viewData = self:getViewData()

    local actionBtns = viewData.actionBtns
    
    local skeletonSpine = viewData.skeletonSpine
    if skeletonSpine then
        skeletonSpine:registerSpineEventHandler(handler(self, self.spineEvent), sp.EventType.ANIMATION_END)
    end

    local cheatBtn = viewData.cheatBtn
    display.commonUIParams(cheatBtn, {cb = handler(self, self.onClickCheatAction)})

    -- self:GetViewComponent():showPlotAni(function ()
    --     self:GetViewComponent():showBossAni()
    -- end, 200092)
    
end


function SummerActivitySecondMapMediator:CleanupView()
    local viewComponent = self:GetViewComponent()
    if self.ownerScene_ and viewComponent and not tolua.isnull(viewComponent) then
        self.ownerScene_:RemoveDialog(viewComponent)
        self.ownerScene_ = nil
    end
end

function SummerActivitySecondMapMediator:OnRegist()
    regPost(POST.SUMMER_ACTIVITY_CHAPTER_HOME, true)
    regPost(POST.SUMMER_ACTIVITY_OPEN_NODE, true)
    regPost(POST.SUMMER_ACTIVITY_SEARCH_NODE, true)

    
end
function SummerActivitySecondMapMediator:OnUnRegist()
    unregPost(POST.SUMMER_ACTIVITY_CHAPTER_HOME)
    unregPost(POST.SUMMER_ACTIVITY_OPEN_NODE)
    unregPost(POST.SUMMER_ACTIVITY_SEARCH_NODE)
end


function SummerActivitySecondMapMediator:InterestSignals()
    return {
        'SUMMER_ACTIVITY_CLICK_MAP_NODE_EVENT',    -- 点击地图节点

        POST.SUMMER_ACTIVITY_CHAPTER_HOME.sglName, -- 章节主页
        POST.SUMMER_ACTIVITY_OPEN_NODE.sglName,    -- 打开节点
        POST.SUMMER_ACTIVITY_SEARCH_NODE.sglName,  -- 搜索BOSS
    }
end

function SummerActivitySecondMapMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody() or {}

    local errcode = checkint(body.errcode)
    if errcode ~= 0 then return end

    -- 点击地图节点
    if name == 'SUMMER_ACTIVITY_CLICK_MAP_NODE_EVENT' then
        -- 检查是否活动时间已过
        if summerActMgr:ShowBackToHomeUI() then return end

        if not self.isControllable_ then return end
        
        local data = body.data or {}
        local nodeType = checkint(data.type)
        local nodeStatus = checkint(data.status)
        local nodeId = body.nodeId
        local isPlot = nodeType == NODE_TYPES.PLOT

        if nodeStatus == NODE_STATUS.UNOPEN then
            if checkint(self.datas.curNodeId) == 0 then
                self:SendSignal(POST.SUMMER_ACTIVITY_OPEN_NODE.cmdName, {chapterId = self.chapterId, nodeId = nodeId})
            else
                uiMgr:ShowInformationTips(summerActMgr:getThemeTextByText(__('请先通关已知关卡。')))
            end
        elseif nodeStatus == NODE_STATUS.OPEN_AND_NOTPASS then
            if isPlot then
                local storyId = data.storyId
                -- 解锁剧情
                self:SendSignal(POST.SUMMER_ACTIVITY_STORY_UNLOCK.cmdName, {storyId = storyId, storyTag = 1})
                self.datas.node[tostring(nodeId)].status = NODE_STATUS.PASS
                self.datas.curNodeId = nil
                
                self:sendControllableEvent(false)
                summerActMgr:ShowOperaStage(storyId, function ()
                    self:GetViewComponent():updateMapNodes(self.datas)
                    self:sendControllableEvent(true)
                end, 2)
            elseif nodeType == NODE_TYPES.MONSTER or nodeType == NODE_TYPES.BOSS then
                if nodeType == NODE_TYPES.BOSS then
                    summerActMgr:SetChapterNodeData(self.chapterId, self.datas)
                end
                self:SendSignal(POST.SUMMER_ACTIVITY_ADDITION.cmdName, {mediatorName = NAME, questId = data.questId, chapterId = self.chapterId, nodeType = nodeType})
            end
        elseif nodeStatus == NODE_STATUS.PASS then
            uiMgr:ShowInformationTips(isPlot and summerActMgr:getThemeTextByText(__('已收录')) or summerActMgr:getThemeTextByText(__('已消灭')))
        end
        
    -- 章节主页
    elseif name == POST.SUMMER_ACTIVITY_CHAPTER_HOME.sglName then

        self.datas = summerActMgr:InitChapterHomeData(body)

        local chapterId = self.datas.chapterId
        local nodeGroup = self.datas.nodeGroup

        -- 获得节点坐标
        local nodeLocations = summerActMgr:GetMapNodePosByNodeGroup(chapterId, nodeGroup)

        local battleSucFlag = summerActMgr:GetBattleSuccessFlagByChapterId(chapterId)
        if battleSucFlag then
            -- 清空 battleSucFlag
            local oldNodeLocations = summerActMgr:GetMapNodePosByNodeGroup(chapterId, nodeGroup)
            summerActMgr:SetBattleSuccessFlag(chapterId)

            local oldChapterNodeDatas = summerActMgr:GetChapterNodeData(chapterId)
            if oldChapterNodeDatas then
                self:sendControllableEvent(false)
                local oldNodeLocations = summerActMgr:GetMapNodePosByNodeGroup(chapterId, battleSucFlag)
                self:GetViewComponent():showNodesChangeAni(oldChapterNodeDatas, oldNodeLocations, self.datas, nodeLocations, function ()
                    self:sendControllableEvent(true)
                end)
            else
                self:GetViewComponent():updateMapNodes(self.datas, nodeLocations)    
            end

        else
            self:GetViewComponent():updateMapNodes(self.datas, nodeLocations)
        end
    
    -- 打开节点
    elseif name == POST.SUMMER_ACTIVITY_OPEN_NODE.sglName then
        local requestData = body.requestData
        local chapterId = requestData.chapterId
        local nodeId = requestData.nodeId

        local nodeInfo = body.info
        self.datas.node[tostring(nodeId)] = nodeInfo
        
        local storyId = nodeInfo.storyId
        local questId = nodeInfo.questId
        local nodeType = nodeInfo.type

        local monsterId, name = summerActMgr:GetNodeMonsterIdByType(nodeType, questId or storyId, chapterId)
        nodeInfo.monsterId = monsterId
        nodeInfo.name = name

        self.datas.curNodeId = nodeId
        self:sendControllableEvent(false)
        local palyStoryEndCb = function ()
            local callBack = function ()
                self:updateMapNode_(nodeInfo, nodeId)
                self:sendControllableEvent(true)
            end 
            
            local nodeShowCb = function ()
                local nData = self.datas.node[tostring(nodeId)]

                local nodeType = nodeInfo.type
                if nodeType == NODE_TYPES.BOSS then
                    self:GetViewComponent():showBossAni(callBack)
                elseif nodeType == NODE_TYPES.PLOT then
                    self:GetViewComponent():showPlotAni(callBack, monsterId)
                else
                    callBack()
                end
            end

            self:GetViewComponent():updateMapNodes(self.datas, nil, nodeId, nodeShowCb)
        end

        -- 如果是BOOS, 检查是否是遭遇BOOS
        if nodeType == NODE_TYPES.BOSS then
            local storyId = summerActMgr:GetEncounterChapterIconStoryByChapterId(chapterId)
            summerActMgr:ShowMainStory(storyId, palyStoryEndCb, function ()
                self:SendSignal(POST.SUMMER_ACTIVITY_STORY_UNLOCK.cmdName, {storyId = storyId, storyTag = 0})
            end, 2)
        else
            palyStoryEndCb()
        end
        
    -- 搜索BOSS
    elseif name == POST.SUMMER_ACTIVITY_SEARCH_NODE.sglName then

        CommonUtils.DrawRewards({
			{goodsId = summerActMgr:getCurCarnieLampId(), num = -1}
		})

        local requestData = body.requestData
        local chapterId = requestData.chapterId

        local nodeId  = body.nodeId
        local questId = body.questId

        local data = self.datas.node[tostring(nodeId)]
        local monsterId, name = summerActMgr:GetNodeMonsterIdByType(NODE_TYPES.BOSS, questId, chapterId)
        data.monsterId = monsterId
        data.name = name
        data.questId = questId
        -- data
        data.type = NODE_TYPES.BOSS
        data.status = NODE_STATUS.OPEN_AND_NOTPASS
        
        self.datas.curNodeId = nodeId

        self:sendControllableEvent(false)
        local palyStoryEndCb = function ()
            PlayAudioClip(AUDIOS.UI.ui_light_boss.id)

            local viewData = self:getViewData()
            local mapNodes = viewData.mapNodes
            local mapNode  = mapNodes[checkint(nodeId)]

            local nodeShowEndCb = function ()
                self:GetViewComponent():showBossAni(function ()
                    self:updateMapNode_(data, nodeId)
                    self:sendControllableEvent(true)
                end)
            end
            local lampnSpineEndCb = function ()
                self:GetViewComponent():updateMapNodes(self.datas, nil, nodeId, nodeShowEndCb)
            end

            self:GetViewComponent():showLampnSpine(mapNode, lampnSpineEndCb)
            
        end

        local storyId = summerActMgr:GetEncounterChapterIconStoryByChapterId(chapterId)
        summerActMgr:ShowMainStory(storyId, palyStoryEndCb, function ()
            self:SendSignal(POST.SUMMER_ACTIVITY_STORY_UNLOCK.cmdName, {storyId = storyId, storyTag = 0})
        end, 2)
        
    end
end

-------------------------------------------------
-- get / set

function SummerActivitySecondMapMediator:getViewData()
    return self.viewData_
end

function SummerActivitySecondMapMediator:getOwnerScene()
    return self.ownerScene_
end

-------------------------------------------------
-- public method
function SummerActivitySecondMapMediator:enterLayer()
    self:SendSignal(POST.SUMMER_ACTIVITY_CHAPTER_HOME.cmdName, {chapterId = self.chapterId})
end

function SummerActivitySecondMapMediator:updateUI(chapterId)
    if chapterId then
        self.chapterId = chapterId
        self:GetViewComponent():updateBg(chapterId)
    end
    self:enterLayer()

    local secondMapAudio = summerActMgr:getSecondMapAudioConf()
    PlayBGMusic(secondMapAudio.cueName)
end

function SummerActivitySecondMapMediator:sendControllableEvent(controllable)
    self.isControllable_ = controllable
    AppFacade.GetInstance():DispatchObservers('SA_CONTROLLABLE_EVENT', {controllable = controllable})
end

-------------------------------------------------
-- private method

-------------------------------------------------
-- show UI
function SummerActivitySecondMapMediator:updateMapNode_(data, nodeId)
    local viewData = self:getViewData()
    local mapNodes = viewData.mapNodes
    local mapNode  = mapNodes[checkint(nodeId)]
    self:GetViewComponent():updateMapNode(mapNode, data, self.chapterId, self.datas.curNodeId)
end

-------------------------------------------------
-- check

-------------------------------------------------
-- handler

function SummerActivitySecondMapMediator:onClickCheatAction(sender)
    -- 检查是否活动时间已过
    if summerActMgr:ShowBackToHomeUI() then return end
    
    if not self.isControllable_ then return end

    if self.datas == nil then return end

    if checkint(self.datas.curNodeId) ~= 0 then
        uiMgr:ShowInformationTips(summerActMgr:getThemeTextByText(__('请先通关已知关卡。')))
        return
    end

    local ownGoodsNum = CommonUtils.GetCacheProductNum(summerActMgr:getCurCarnieLampId())

    -- 确定弹窗
	local commonTip = require('common.CommonPopTip').new({
        viewType = 1,
        text = summerActMgr:getThemeTextByText(__('消耗1个引路灯直接找到小丑')),
        textW = 260,
        ownTip =  string.format(summerActMgr:getThemeTextByText(__('拥有引路灯: %s')), ownGoodsNum),
        btnTextL = summerActMgr:getThemeTextByText(__('确定')),
        btnImgL = ownGoodsNum <= 0 and _res('ui/common/common_btn_orange_disable') or _res("ui/common/common_btn_orange"),
        btnTextR = summerActMgr:getThemeTextByText(__('获取')),
        btnImgR = _res('ui/common/common_btn_white_default.png'),
        cancelBack = function (sender)
            if ownGoodsNum <= 0 then
                uiMgr:ShowInformationTips(summerActMgr:getThemeTextByText(__('道具不足'))) 
            else
                self:SendSignal(POST.SUMMER_ACTIVITY_SEARCH_NODE.cmdName, {chapterId = self.chapterId})
            end
        end,
        callback = function (sender)
            uiMgr:AddDialog("common.GainPopup", {goodId = summerActMgr:getCurCarnieLampId()})
		end
	})
	commonTip:setName('CommonPopTip')
	commonTip:setPosition(display.center)
	self:getOwnerScene():AddDialog(commonTip)
end

function SummerActivitySecondMapMediator:spineEvent(event)
    if event.animation == 'idle' or event.animation == 'idle1' or event.animation == 'idle2' then
        local viewData = self:getViewData()
        local skeletonSpine = viewData.skeletonSpine
        skeletonSpine:setVisible(false)
        if self.spineEndCallBack then
            self.spineEndCallBack()
            
            self.spineEndCallBack = nil
        end
    end
end

return SummerActivitySecondMapMediator
