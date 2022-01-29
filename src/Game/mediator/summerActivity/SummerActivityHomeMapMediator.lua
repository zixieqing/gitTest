--[[
 * descpt : 夏活 第一级 地图 中介者
]]
local NAME = 'summerActivity.SummerActivityHomeMapMediator'
local SummerActivityHomeMapMediator = class(NAME, mvc.Mediator)

local uiMgr    = app.uiMgr    or AppFacade.GetInstance():GetManager('UIManager')
local gameMgr  = app.gameMgr  or AppFacade.GetInstance():GetManager("GameManager")
local timerMgr = app.timerMgr or AppFacade.GetInstance():GetManager("TimerManager")
local summerActMgr = AppFacade.GetInstance():GetManager("SummerActivityManager")

local BUTTON_TAG = {
    BACK   = 100,
    RULE   = 101,
}

local changeTeamMemberViewTag = 888

local CHILD_FIRST_MAP_NEDIATOR  = 'summerActivity.SummerActivityFirstMapMediator'
local CHILD_SECOND_MAP_NEDIATOR = 'summerActivity.SummerActivitySecondMapMediator'

local LOCAL_SA_TEAM_DATA_KEY = 'LOCAL_SA_TEAM_DATA_KEY'

function SummerActivityHomeMapMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
end

-------------------------------------------------
-- inheritance method
function SummerActivityHomeMapMediator:Initial(key)
    self.super.Initial(self, key)
    
    self.viewStore       = {}
    self.mediatorStore   = {}
    self.isControllable_ = true
    
    local requestData = self.ctorArgs_.requestData or {}
    
    local chapterId = requestData.chapterId
    self.isFirstPassChapter = false
    if chapterId then
        local chapterData = self.ctorArgs_.chapter[tostring(chapterId)] or {}
        local isPassed    = checkint(chapterData.isPassed)
        local oldIsPass   = checkint(requestData.isPassed)
        self.isFirstPassChapter = oldIsPass == 0 and isPassed > 0
    end
    
    if self.isFirstPassChapter and requestData.nodeType == 3 then
        self.curMediatorName = CHILD_FIRST_MAP_NEDIATOR
    else
        self.curMediatorName = requestData.mediatorName or CHILD_FIRST_MAP_NEDIATOR
    end
    
    local viewComponent = uiMgr:SwitchToTargetScene('Game.views.summerActivity.SummerActivityHomeMapSence')
    display.commonUIParams(viewComponent,{po = display.center, ap = display.CENTER})
	self:SetViewComponent(viewComponent)
    self.viewData_ = viewComponent:getViewData()

    -- add layer
    self:initOwnerScene_()
    
    -- init data
    if next(self.ctorArgs_) ~= nil then
        self:initData_(self.ctorArgs_)
    end

    -- init view
    self:initView_()
    
    
end

function SummerActivityHomeMapMediator:initOwnerScene_()
    self.ownerScene_ = uiMgr:GetCurrentScene()
end

function SummerActivityHomeMapMediator:initData_(body)

    self.finalQuestId = body.finalQuestId

    summerActMgr:InitActivityHp(checktable(body))

    self:GetViewComponent():UpdateCountUI()
end

function SummerActivityHomeMapMediator:initView_()
    local viewData = self:getViewData()
    local actionBtns = viewData.actionBtns
    
    for tag, btn in pairs(actionBtns) do
        display.commonUIParams(btn, {cb = handler(self, self.onBtnAction)})
        btn:setTag(checkint(tag))
    end

end

function SummerActivityHomeMapMediator:swiChildMediator(mediatorName, chapterId, backFromFirst)
    if mediatorName == nil then return end
    
    if not self.mediatorStore[mediatorName] then
        local viewData     = self:getViewData()
        local contentLayer = viewData.contentLayer
        local mediator = require("Game.mediator." .. mediatorName).new()
        self:GetFacade():RegistMediator(mediator)
        local mediatorViewComponent = mediator:GetViewComponent()
        contentLayer:addChild(mediatorViewComponent)
        display.commonUIParams(mediatorViewComponent,{po = display.center, ap = display.CENTER})

        self.mediatorStore[mediatorName] = mediator
        self.viewStore[mediatorName] = mediatorViewComponent
    end

    if self.curMediatorName ~= mediatorName then
        self.viewStore[self.curMediatorName]:setVisible(false)
        self.viewStore[mediatorName]:setVisible(true)
        self.curMediatorName = mediatorName
    end

    local requestData = self.ctorArgs_.requestData or {}

    self.mediatorStore[mediatorName]:updateUI(chapterId, self.isFirstPassChapter, requestData.nodeType)

end

function SummerActivityHomeMapMediator:CleanupView()
 
end


function SummerActivityHomeMapMediator:OnRegist()
    
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
    regPost(POST.SUMMER_ACTIVITY_STORY_UNLOCK, true)
    regPost(POST.SUMMER_ACTIVITY_ADDITION, true)
    regPost(POST.SUMMER_ACTIVITY_CHAPTER, true)

    local requestData = self.ctorArgs_.requestData or {}
    self:swiChildMediator(self.curMediatorName, requestData.chapterId)

    self:checkOvercomeBossStory()

    if next(self.ctorArgs_) == nil then
        self:enterLayer()
    end
end
function SummerActivityHomeMapMediator:OnUnRegist()
    unregPost(POST.SUMMER_ACTIVITY_STORY_UNLOCK)
    unregPost(POST.SUMMER_ACTIVITY_ADDITION)
    unregPost(POST.SUMMER_ACTIVITY_CHAPTER)

    PlayBGMusic()
end

function SummerActivityHomeMapMediator:InterestSignals()
    return {
        -------------- local --------------
        'SUMMER_ACTIVITY_SWITCH_MAP',       -- 切换地图
        'SHOW_EDIT_TEAM_LAYER',             -- 显示编辑团队界面
        'SA_CHANGE_TEAM_MEMBER_SIGNAL',     -- 改变团队信息
        'ENTER_SEASON_EVENT_BATTLE',        -- 进入战斗事件
        'CLOSE_CHANGE_TEAM_SCENE',          -- 关闭团队编辑界面
        'SA_CONTROLLABLE_EVENT',            -- 控制点击
        'SA_SYNC_DATA',                     -- 同步数据
        SGL.CACHE_MONEY_UPDATE_UI,          -- 改变货币
        -------------- local --------------

        -------------- server --------------
        POST.SUMMER_ACTIVITY_STORY_UNLOCK.sglName,        -- 解锁团队
        POST.SUMMER_ACTIVITY_ADDITION.sglName,            -- 战斗加成信息  
        POST.SUMMER_ACTIVITY_CHAPTER.sglName,             -- 章节信息
        -------------- server --------------
    }
end

function SummerActivityHomeMapMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody() or {}

    local errcode = checkint(body.errcode)
    if errcode ~= 0 then return end

    if name == 'SA_SYNC_DATA' then
        -- 同步数据
        if gameMgr:GetUserInfo().summerActivity > 0 then
            self:SendSignal(POST.SUMMER_ACTIVITY_ADDITION.cmdName, {updateRecommend = 1})
            summerActMgr:StopSummerActivityCountdown()
            self:enterLayer()
        end
    elseif name == 'SUMMER_ACTIVITY_SWITCH_MAP' then
        local chapterId = body.chapterId
        self:swiChildMediator(CHILD_SECOND_MAP_NEDIATOR, chapterId)

    elseif name == 'SA_CHANGE_TEAM_MEMBER_SIGNAL' then
        
        self:updateTeamData(body)

    elseif name == 'SHOW_EDIT_TEAM_LAYER' then

        self:showEditTeamLayer(body)

    elseif name == 'ENTER_SEASON_EVENT_BATTLE' then
        -- 检查是否活动时间已过
        if summerActMgr:ShowBackToHomeUI() then return end
        
        local actionPoint = app.activityHpMgr:GetHpAmountByHpGoodsId(summerActMgr:getTicketId())
        local questId = checkint(body.questId)
        local questData = summerActMgr:GetQuestDataById(questId)
        local consumeNum = checkint(questData.consumeNum)
        if actionPoint >= consumeNum then
            self:enterBattle(body)
        else
            local consumeGoods = checkint(questData.consumeGoods)
            if GAME_MODULE_OPEN.NEW_STORE and checkint(consumeGoods) == DIAMOND_ID then
                app.uiMgr:showDiamonTips()
            else
                local temp = CommonUtils.GetConfig('goods', 'money', consumeGoods)
                uiMgr:ShowInformationTips(string.format(summerActMgr:getThemeTextByText(__('%s不足')), tostring(temp.name)))
            end
        end
    elseif name == 'CLOSE_CHANGE_TEAM_SCENE' then
        self.editTeamLayer = nil

    elseif name == 'SA_CONTROLLABLE_EVENT' then
        self.isControllable_ = checkbool(body.controllable)
    elseif name == SGL.CACHE_MONEY_UPDATE_UI then
        self:GetViewComponent():UpdateCountUI()

    elseif name == POST.SUMMER_ACTIVITY_CHAPTER.sglName then

        self:initData_(body)

    elseif name == POST.SUMMER_ACTIVITY_ADDITION.sglName then
        self.additionInfo = body
        
        local requestData = body.requestData
        if checkint(requestData.updateRecommend) > 0 then
            local recommendCards = summerActMgr:GetRecommendCardsByAdditions(body.additions)
            self:updateRecommendCards(recommendCards)
        else
            self:showReadyView(body)
        end

    elseif name == POST.SUMMER_ACTIVITY_STORY_UNLOCK.sglName then
        local requestData = body.requestData
        local storyId   = requestData.storyId
        local chapterId = checkint(requestData.chapterId)
        local storyTag  = checkint(requestData.storyTag)

        if storyTag == 0 then
            summerActMgr:AddMainStoryId(storyId)
        else
            summerActMgr:AddBranchStoryId(chapterId, storyId)
        end

        app:DispatchObservers("CHECK_HIDE_STORY_IS_OPEN")

    end
end

-------------------------------------------------
-- get / set

function SummerActivityHomeMapMediator:getViewData()
    return self.viewData_
end

function SummerActivityHomeMapMediator:getOwnerScene()
    return self.ownerScene_
end

-------------------------------------------------
-- public method
function SummerActivityHomeMapMediator:enterLayer()
    self:SendSignal(POST.SUMMER_ACTIVITY_CHAPTER.cmdName)
end

function SummerActivityHomeMapMediator:updateTeamData(body)
    -- 可行性判断
    local teamData = body.teamData
    local isTeamEmpty = true
    for i,v in ipairs(teamData) do
        if nil ~= v.id then
            isTeamEmpty = false
        end
    end
    if isTeamEmpty then
        uiMgr:ShowInformationTips(summerActMgr:getThemeTextByText(__('队伍不能为空!!!')))
        return
    end
    
    self:updateRreadyView(teamData)
    AppFacade.GetInstance():DispatchObservers('CLOSE_CHANGE_TEAM_SCENE')
end

--==============================--
--desc: 更新战斗预览界面
--@params teamData table 团队数据
--==============================--
function SummerActivityHomeMapMediator:updateRreadyView(teamData)
    if self.readyView and not tolua.isnull(self.readyView) then
        local teamMembers = {[1] = {teamId = 1, cards = teamData}}
        self.readyView:RefreshTeamFormation(teamMembers)
    end
end

--==============================--
--desc: 更新推荐卡牌
--@params recommendCards table 推荐卡牌数据
--==============================--
function SummerActivityHomeMapMediator:updateRecommendCards(recommendCards)
    if self.readyView and not tolua.isnull(self.readyView) then
        self.readyView:RefreshRecommendCards(recommendCards)
    end

    if self.editTeamLayer and not tolua.isnull(self.editTeamLayer) then
        local selectCardLayer = self.editTeamLayer.selectCardLayer
        selectCardLayer:SetRecommendCards(recommendCards)
        selectCardLayer:RefreshFilterCardsByFilerType(selectCardLayer.selectedFilterPattern)
    end
end

--==============================--
--desc: 进入战斗
--@params data table 
--==============================--
function SummerActivityHomeMapMediator:enterBattle(data)
    local cards   = data.cards
    local questId = checkint(data.questId)
    local requestData = self.additionInfo.requestData
    local additions = self.additionInfo.additions

    local chapterId    = requestData.chapterId
    local chapterData  = self.ctorArgs_.chapter[tostring(chapterId)] or {}
    local isPassed     = checkint(chapterData.isPassed)
    local nodeGroup    = chapterData.nodeGroup
    local nodeType     = requestData.nodeType
    local mediatorName = requestData.mediatorName

    if tostring(chapterId) == summerActMgr.CHAPTER_FLAG.FINALLY_BOSS then
        questId = self.finalQuestId
        nodeType = 3
    end

    -- 阵容信息
    local teamData = {}
    local teamDataMap = {}
    local count = 0
    for k, v in pairs(cards) do
        local id = checkint(v.id)
        if id > 0 then
            count = count + 1
            teamData[checkint(k)] = id
            teamDataMap[tostring(k)] = id
        end
    end

    if count == 0 then
        -- TODO 跳转编队
		local CommonTip  = require( 'common.CommonTip' ).new({text = summerActMgr:getThemeTextByText(__('队伍不能为空')),isOnlyOK = true})
		CommonTip:setPosition(display.center)
		self:getOwnerScene():AddDialog(CommonTip)
        return
    end

    -- 设置本地团队数据
    CommonUtils.setLocalDatas(cards, summerActMgr:getCarnieThemeActivityTeamFlagByQuestId(questId))

    ------------ 初始化战斗构造器 ------------
   
    -- 网络命令
    local serverCommand = BattleNetworkCommandStruct.New(
		POST.SUMMER_ACTIVITY_QUESTAT.cmdName,
		{questId = questId, cards = json.encode(teamDataMap), chapterId = chapterId, mediatorName = mediatorName, isPassed = isPassed, nodeType = nodeType},
		POST.SUMMER_ACTIVITY_QUESTAT.sglName,
		POST.SUMMER_ACTIVITY_QUESTGRADE.cmdName,
		{questId = questId, chapterId = chapterId, chapterIsPassed = isPassed, nodeGroup = nodeGroup, nodeType = nodeType},
		POST.SUMMER_ACTIVITY_QUESTGRADE.sglName,
		nil, nil, nil
	)


    -- 跳转信息
    local fromToStruct = BattleMediatorsConnectStruct.New(
        NAME,
        NAME
    )
   
    -- 选择的主角技信息
    local playerSkillData = {
        0, 0
    }

    -- 创建战斗构造器
    local battleConstructor = require('battleEntry.BattleConstructor').new()

    battleConstructor:InitStageDataByNormalEvent(
        checkint(questId),
        serverCommand,
        fromToStruct,
        teamData,
        playerSkillData,
        additions
    )

    battleConstructor:OpenBattle()
    ------------ 初始化战斗构造器 ------------

end

-------------------------------------------------
-- check
--==============================--
--desc: 检查第一次战胜boss的剧情触发
--==============================--
function SummerActivityHomeMapMediator:checkOvercomeBossStory()
    if not self.isFirstPassChapter then return end
    local storyId = checkint(summerActMgr:GetOvercomeStoryId())
    
    -- 添加主线剧情缓存
    app.summerActMgr:AddMainStoryId(storyId)
    if storyId > 0 then
        summerActMgr:ShowOperaStage(storyId, nil, 1)
        -- 清理缓存
        summerActMgr:SetOvercomeStoryId(0)
    end
end

-------------------------------------------------
-- show UI
--==============================--
--desc: 显示编辑团队界面
--==============================--
function SummerActivityHomeMapMediator:showEditTeamLayer(data)
    local recommendCards = data.recommendCards
    local layer = require('Game.views.pvc.PVCChangeTeamScene').new({
        teamDatas = {[1] = data.teamData},
		title = summerActMgr:getThemeTextByText(__('编辑进攻队伍')),
		teamTowards = 1,
		avatarTowards = 1,
        teamChangeSingalName = "SA_CHANGE_TEAM_MEMBER_SIGNAL",
        isDisableHomeTopSignal = true,
        isOpenRecommendState = true,
        recommendCards = recommendCards,
    })
    display.commonUIParams(layer, {ap = display.CENTER, po = display.center})
	layer:setTag(changeTeamMemberViewTag)
    self:getOwnerScene():AddDialog(layer)
    self.editTeamLayer = layer
end

--==============================--
--desc: 显示战斗预览界面
--==============================--
function SummerActivityHomeMapMediator:showReadyView(data)

    local requestData = data.requestData
    local chapterId = requestData.chapterId
    
    local questId = checkint(requestData.questId)
    if tostring(chapterId) == summerActMgr.CHAPTER_FLAG.FINALLY_BOSS then
        questId = self.finalQuestId
    end

    local teamDatas = CommonUtils.getLocalDatas(summerActMgr:getCarnieThemeActivityTeamFlagByQuestId(questId)) or {}
    
    local curScene = self:getOwnerScene()
    local battleReadyViewZOrder = curScene.TAGS.TagDialogLayer
    local teamMembers = {[1] = {teamId = 1, cards = teamDatas}}
    
    local additions = self.additionInfo.additions
    local recommendCards = summerActMgr:GetRecommendCardsByAdditions(additions)
    
    -- 显示编队界面
    local battleReadyData = {
        recommendCards = recommendCards,
        stageId = questId,
        teamMembers = teamMembers,
        questBattleType = QuestBattleType.SEASON_EVENT,
        disableUpdateBackButton = true
    }
    local layer = require('Game.views.summerActivity.SummerActivityReadyView').new(battleReadyData)
    layer:setPosition(cc.p(display.cx,display.cy))
    curScene:addChild(layer, 1)

    self.readyView = layer
end


-- show UI
-------------------------------------------------

-------------------------------------------------
-- private method
function SummerActivityHomeMapMediator:closeView()
    for mediatorName, mediator in pairs(self.mediatorStore) do
        self:GetFacade():UnRegsitMediator(mediatorName)
    end
    
    self.mediatorStore = {}
    self.viewStore     = {}

    -- 清理倒计时
    summerActMgr:StopSummerActivityCountdown()
    app.activityHpMgr:StopHPCountDown(summerActMgr:getTicketId())

    -- local requestData = self.ctorArgs_.requestData or {}
    local backData = app.summerActMgr:GetBackData()

    local fromMediator = backData.fromMediator or 'HomeMediator'
    local activityId   = backData.activityId
    -- logInfo.add(5, tostring(fromMediator))
    local params = {popMediator = 'summerActivity.SummerActivityHomeMediator', activityId = activityId}
    if fromMediator == 'HomeMediator' then
        AppFacade.GetInstance():BackHomeMediator(params)
    else
        AppFacade.GetInstance():RetrieveMediator("Router"):Dispatch({name = NAME}, {name = fromMediator, params = params})
    end
end

-------------------------------------------------
-- check


-------------------------------------------------
-- handler
function SummerActivityHomeMapMediator:onBtnAction(sender)
    local tag = sender:getTag()
    
    -- 检查是否活动时间已过
    if summerActMgr:ShowBackToHomeUI() then return end

    if tag == BUTTON_TAG.BACK then
        if not self.isControllable_ then return end
        PlayAudioByClickClose()
        -- 如果是二级地图
        if self.curMediatorName == CHILD_SECOND_MAP_NEDIATOR then
            self.viewStore[CHILD_SECOND_MAP_NEDIATOR]:hideContentLayer()
            
            -- 切换为一级地图
            self:swiChildMediator(CHILD_FIRST_MAP_NEDIATOR, nil, true)
            return
        end

        self:closeView()

    else
        PlayAudioByClickNormal()
        if tag == BUTTON_TAG.RULE then
            uiMgr:ShowIntroPopup({moduleId = '-3'})
        end
    end
end

return SummerActivityHomeMapMediator
