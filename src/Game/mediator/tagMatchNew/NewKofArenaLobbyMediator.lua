--[[
 * descpt : 新天城演武 大厅 中介者
]]
local NAME = 'tagMatchNew.NewKofArenaLobbyMediator'
local NewKofArenaLobbyMediator = class(NAME, mvc.Mediator)

local AppFacadeInstance = AppFacade.GetInstance()
local uiMgr    = AppFacadeInstance:GetManager('UIManager')
local gameMgr  = AppFacadeInstance:GetManager("GameManager")
local timerMgr = AppFacadeInstance:GetManager("TimerManager")
local cardMgr  = AppFacadeInstance:GetManager("CardManager")

local BUTTON_TAG = {
    BACK            = 100, -- 返回
    MODIFY          = 102, -- 点击修改
    FIGHT           = 103, -- 战斗
    REPORT          = 104, -- 战报
    REFRESH         = 105, -- 刷新
    SHOP            = 106, -- 商店
    RANK            = 107, -- 排行榜
    GIFT            = 108, -- 战斗奖励
    LOOK_REWARD     = 109, -- 奖励预览
    ADD_FIGHT_TIMES = 110, -- 增加战斗次数
}

local SECTION_ACTION_TAG = {
    UP   = 1,
    FLAT = 2,
    DOWN = 3,
}

local IS_FIRST = {
    YES = 1,
    NO  = 0,
}

-- 天城演武 点击确定时  保存进攻团队
local NEW_TAG_MATCH_SAVE_TEAM_SIGNAL = 'NEW_TAG_MATCH_SAVE_TEAM_SIGNAL'

-- 通用改变团队
local LOCAL_SWITCH_TEAM          = 'LOCAL_SWITCH_TEAM'
-- 拖拽改变团队
local LOCAL_DRAG_CHANGE_TEAM     = 'LOCAL_DRAG_CHANGE_TEAM'
-- 进入战斗
local ENTER_TAG_MATCH_BATTLE     = 'ENTER_TAG_MATCH_BATTLE'
-- 显示敌方团队
local SHOW_OPPONENT_TEAM         = 'SHOW_OPPONENT_TEAM'
-- 显示 排行榜
local SHOW_PVC_RANK              = 'SHOW_PVC_RANK'
-- 显示编辑团队界面
-- local SHOW_TAG_MATCH_EDIT_TEAM   = 'SHOW_TAG_MATCH_EDIT_TEAM'
-- 关闭 改变团队界面
local CLOSE_CHANGE_TEAM_SCENE    = 'CLOSE_CHANGE_TEAM_SCENE'
-- 点击战报列表
local CLICK_PVC_REPORT_VIEW_CELL = 'CLICK_PVC_REPORT_VIEW_CELL'
-- 通用dialog 的关闭
local CLOSE_COMMON_DIALOG        = 'CLOSE_COMMON_DIALOG'

-- 最大对手个数
local MAX_ENEMY_COUNT = 4

function NewKofArenaLobbyMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
    self.datas = self.ctorArgs_
    self.isRequestSuc = checkint(self.datas.errcode) == 0
end

-------------------------------------------------
-- init method
function NewKofArenaLobbyMediator:Initial(key)
    self.super.Initial(self, key)
    
    self.isTimeEnd = false

    -- 当前对手下标
    self.curSelectOppoentIndex = 0
    
    -- 当前团队id 
    self.teamId = 0

    -- create view
    local viewComponent = require('Game.views.tagMatchNew.NewKofArenaLobbyView').new()
    self.viewData_      = viewComponent:getViewData()
    self:SetViewComponent(viewComponent)
    -- add layer
    self.ownerScene_ = uiMgr:GetCurrentScene()
    display.commonUIParams(viewComponent,{po = display.center, ap = display.CENTER})
    self:getOwnerScene():AddDialog(viewComponent)
    
    if self.isRequestSuc then
        -- init data
        self:initData_()
        -- init view
        self:initView_()
    end
    
end

function NewKofArenaLobbyMediator:initData_()
    self.challengeRewardsConf = CONF.NEW_KOF.CHALLENGE:GetAll()
end

function NewKofArenaLobbyMediator:initView_()
   local viewData = self:getViewData()

   local backBtn = viewData.backBtn
   display.commonUIParams(backBtn, {cb = handler(self, self.onCloseViewAction)})

    -- local titleRuleBtn = viewData.titleRuleBtn
    -- display.commonUIParams(titleRuleBtn, {cb = handler(self, self.onClickTitleRuleAction)})

   local actionBtns = viewData.actionBtns
   for tag, btn in pairs(actionBtns) do
        display.commonUIParams(btn, {cb = handler(self, self.onBtnAction)})
        btn:setTag(checkint(tag))
   end
   
   local playerTeamHeadBgs = viewData.playerTeamHeadBgs
   for i, playerTeamHeadBg in ipairs(playerTeamHeadBgs) do
       -- 初始化头像背景
       local playerTeamHeadBgViewData = playerTeamHeadBg.viewData
       local clickLayer = playerTeamHeadBgViewData.clickLayer
       display.commonUIParams(clickLayer, {cb = handler(self, self.onClickPlayerTeamHeadBg)})
       clickLayer:setTag(i)
   end

   --初始化奖励盒子
   local boxRewards = viewData.boxRewards
   for i, box in ipairs(boxRewards) do
        display.commonUIParams(box, {cb = handler(self, self.onClickRewardBoxs)})
   end

   local gridView = viewData.gridView
   gridView:setDataSourceAdapterScriptHandler(handler(self, self.onOppoentAdapter))
   
   self:showView()
end

function NewKofArenaLobbyMediator:CleanupView()
    self:hideSingleTeamInfo()
    local viewComponent = self:GetViewComponent()
    if self.ownerScene_ and viewComponent and not tolua.isnull(viewComponent) then
        self.ownerScene_:RemoveDialog(viewComponent)
        self.ownerScene_ = nil
    end
end


function NewKofArenaLobbyMediator:OnRegist()
    regPost(POST.NEW_TAG_MATCH_HOME, true)
    regPost(POST.NEW_TAG_MATCH_REFRESH_ENEMY, true)
    regPost(POST.NEW_TAG_MATCH_BUY_ATTACK_TIMES, true)
    regPost(POST.NEW_TAG_MATCH_SAVE_TEAM, true)
    regPost(POST.NEW_TAG_MATCH_ARENA_RECORD, true)
    regPost(POST.NEW_TAG_MATCH_DRAW_CHALLENGE_REWARDS, true)
    regPost(POST.PRESET_TEAM_GET_TEAM_CUSTOM_DETAIL, true)

    -- 请求失败 关闭当前界面
    if not self.isRequestSuc then
        self:closeView()
    end

    -- 如果不是走路由 重新请求
    if next(self.datas) == nil then
        self:enterLayer()
    end
    if self:getAttackTeamId() > 0 then
		self:SendSignal(POST.PRESET_TEAM_GET_TEAM_CUSTOM_DETAIL.cmdName, {teamId = self:getAttackTeamId()})
	end

end
function NewKofArenaLobbyMediator:OnUnRegist()
    unregPost(POST.NEW_TAG_MATCH_HOME)
    unregPost(POST.NEW_TAG_MATCH_REFRESH_ENEMY)
    unregPost(POST.NEW_TAG_MATCH_BUY_ATTACK_TIMES)
    unregPost(POST.NEW_TAG_MATCH_SAVE_TEAM)
    unregPost(POST.NEW_TAG_MATCH_ARENA_RECORD)
    unregPost(POST.NEW_TAG_MATCH_DRAW_CHALLENGE_REWARDS)
    unregPost(POST.PRESET_TEAM_GET_TEAM_CUSTOM_DETAIL)
    
    timerMgr:RemoveTimer(NAME)
end


function NewKofArenaLobbyMediator:InterestSignals()
    return {
        ------------ local ------------
        ENTER_TAG_MATCH_BATTLE,                         -- 进入战斗
        -- handle data
        LOCAL_SWITCH_TEAM,                              -- 点击选择团队
        LOCAL_DRAG_CHANGE_TEAM,                         -- 拖拽选择团队
        NEW_TAG_MATCH_SAVE_TEAM_SIGNAL,                 -- 确定保存团队
        SGL.PRESET_TEAM_SELECT_CARDS,                   -- 预设编队
        -- show ui
        SHOW_OPPONENT_TEAM,                             -- 显示对手团队
        SHOW_PVC_RANK,                                  -- 显示排行榜
        -- SHOW_TAG_MATCH_EDIT_TEAM,                       -- 显示编辑团队界面
        CLOSE_CHANGE_TEAM_SCENE,                        -- 关闭编辑团队界面
        COUNT_DOWN_ACTION,                              -- 倒计时
        CLICK_PVC_REPORT_VIEW_CELL,                     -- 点击战报列表cell
        CLOSE_COMMON_DIALOG,
        ------------ long connection ------------
        SGL.TAG_MATCH_SGL_PLAYER_RANK_CHANGE,
        ------------ server ------------
        POST.NEW_TAG_MATCH_HOME.sglName,
        POST.NEW_TAG_MATCH_REFRESH_ENEMY.sglName,
        POST.NEW_TAG_MATCH_BUY_ATTACK_TIMES.sglName,
        POST.NEW_TAG_MATCH_SAVE_TEAM.sglName,
        POST.NEW_TAG_MATCH_ARENA_RECORD.sglName,

        POST.PRESET_TEAM_GET_TEAM_CUSTOM_DETAIL.sglName,
        POST.NEW_TAG_MATCH_DRAW_CHALLENGE_REWARDS.sglName
    }
end

function NewKofArenaLobbyMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody() or {}
    local errcode = checkint(body.errcode)

    if name == CLICK_PVC_REPORT_VIEW_CELL then
        local data = body.data
        local cell = body.cell
        if cell and not tolua.isnull(cell) then
            uiMgr:ShowInformationTipsBoard({
                targetNode = cell, 
                type = 10,
                bgSize = cc.size(410, 530),
                title = __('总灵力'),
                viewTypeData = {
                    teamInfo = self:calcBattlePoint(data.opponent.teamInfo)
                }
            })
        end
    elseif name == CLOSE_COMMON_DIALOG then
        self:hideSingleTeamInfo()
    elseif name == POST.NEW_TAG_MATCH_HOME.sglName then
        self.datas = body
        self:updateSelectFrame(self:getViewData(), self.curSelectOppoentIndex, false)
        self:showView()
    -- 刷新对手
    elseif name == POST.NEW_TAG_MATCH_REFRESH_ENEMY.sglName then
        -- 先更改上一个 cell 的选择状态
        self:updateSelectFrame(self:getViewData(), self.curSelectOppoentIndex, false)
        self.curSelectOppoentIndex = 0
        self.datas.opponent = body.opponent or {}
        -- 检查一遍 对手列表
        self:checkEnemyList()
        self:GetViewComponent():updateOpponentInfo(self.datas)
    elseif name == POST.NEW_TAG_MATCH_BUY_ATTACK_TIMES.sglName then
        ---购买成功，次数+1
        if checkint(body.errcode) ~= 0 then return end
        local isAddFightTimes = true
        self:setLeftFightTimes(isAddFightTimes)
        self:GetViewComponent():updateFightLeftTimes(self:getLeftFightTimes())
        -- 扣除消耗
        local initParamConf = CONF.NEW_KOF.BASE_PARMS:GetAll()
        local nums = checkint(initParamConf.challengeConsume[1].num)
        local goodsId = checkint(initParamConf.challengeConsume[1].goodsId)
        CommonUtils.DrawRewards({
            {goodsId = goodsId, num = -nums}
        })
    -- 设置保存队伍
    elseif name == POST.NEW_TAG_MATCH_SAVE_TEAM.sglName then
        if checkint(body.errcode) ~= 0 then return end
        uiMgr:ShowInformationTips(__('更改进攻阵容成功'))
        local requestData = body.requestData or {}
        local cards       = json.decode(requestData.cards)
        local teamIds = {}
        for teamId, teamStr in pairs(cards) do
            local data = self:convertTeamStrToData(teamStr)
            self:setTeamDatas(teamId, data)
            table.insert(teamIds, teamId)
        end
        --第一次不消耗次数
        if self:getIsFirstEnter() == IS_FIRST.NO then
            self:setLeftSaveTeamTimes()
            self:GetViewComponent():updateModifyTeamTimes(self:getLeftSaveTeamTimes())
        else
            --隐藏动画
            self:GetViewComponent():updateFirstModifyTeamAction(false)
            self:setIsFirstEnter()
        end
        
        self:GetViewComponent():updateTeamHead(self:getTeamDatas())
        -- 保存成功 更新头像
        AppFacade.GetInstance():DispatchObservers('UPDATE_TEAM_HEAD', {teamIds = teamIds, attackTeamId = self:getAttackTeamId()})
        if self:getAttackTeamId() > 0 then
            self:SendSignal(POST.PRESET_TEAM_GET_TEAM_CUSTOM_DETAIL.cmdName, {teamId = self:getAttackTeamId()})
        end
        
    -- 进入战报界面 
    elseif name == POST.NEW_TAG_MATCH_ARENA_RECORD.sglName then
        local totalTimes = checkint(body.totalTimes)
        local winTimes   = checkint(body.winTimes)
        local records    = body.records or {}
        
        local tag = 110
        local layer = require('Game.views.tagMatchNew.NewKofArenaReportView').new({
            tag = tag,
            winTimes = winTimes,
            loseTimes = totalTimes - winTimes,
            viewType = BATTLE_SCRIPT_TYPE.TAG_MATCH,
            headDefaultCallback = true,
            enableCellCallback = true,
            reportData = records})
        layer:setTag(tag)
        layer:setAnchorPoint(cc.p(0.5, 0.5))
        layer:setPosition(cc.p(display.cx, display.cy))
        self:getOwnerScene():AddDialog(layer)

    elseif name == POST.PRESET_TEAM_GET_TEAM_CUSTOM_DETAIL.sglName  then
        if errcode == 0 then
            local tagMatchFightPrepareMediator = self:GetFacade():RetrieveMediator('NewKofArenaFightPrepareMediator')
            if checkint(body.valid) == 1 then
                if tagMatchFightPrepareMediator then
                    -- prepare fight
                    self:enterBattle(self.tempEnemyData_, body)
                else
                    -- home
	                local presetTeamInfo = checktable(body.info) or {}
                    local fixedTeamData = {}
                    for teamId, teamData in pairs(presetTeamInfo) do
                        fixedTeamData[teamId] = {}
                        for cardId, presetCardData in pairs(teamData) do
                            local cardUuid = checkint(presetCardData.id)
                            local cardData = clone(gameMgr:GetCardDataById(cardUuid))
                            cardData.pets  = presetCardData.pets or {}
                            cardData.artifactTalent = presetCardData.artifactTalent or {}
                            table.insert(fixedTeamData[teamId], cardData)
                        end
                        self:setTeamDatas(teamId, fixedTeamData[teamId])
                    end
                end
            else
                app.uiMgr:ShowInformationTips(__('当前预设编队已失效'))
            end
        else
            local tagMatchFightPrepareMediator = self:GetFacade():RetrieveMediator('NewKofArenaFightPrepareMediator')
            if tagMatchFightPrepareMediator then
                self:GetFacade():UnRegsitMediator("NewKofArenaFightPrepareMediator")
            end
            self:enterLayer()
        end
    elseif name == SGL.TAG_MATCH_SGL_PLAYER_RANK_CHANGE then
        local rank = checkint(body.rank)
        self.datas.rank = rank
        self:GetViewComponent():updateCurRankLabel(rank)
    elseif name == SHOW_PVC_RANK then
        self:showRank()
    elseif name == ENTER_TAG_MATCH_BATTLE then
        if not self:checkIsCanEnterBattlePrepare(self:getTeamDatas()) then
            uiMgr:ShowInformationTips(__('队伍不能为空'))
            return
        end 
        self.tempEnemyData_ = self.datas.opponent[self.curSelectOppoentIndex]

        if self:getAttackTeamId() > 0 then
            ---获取预设编队阵容卡牌数据
            self:SendSignal(POST.PRESET_TEAM_GET_TEAM_CUSTOM_DETAIL.cmdName, {teamId = self:getAttackTeamId()})
        else
            self:enterBattle(self.tempEnemyData_)
        end
    elseif name == NEW_TAG_MATCH_SAVE_TEAM_SIGNAL then
        if self.toCleanTeamId_ then
            self:setAttackTeamId(0)
            self.toCleanTeamId_ = false
        end

        local teamDatas = body.teamDatas or {}

        -- 1. 先检查 要替换的队伍是否能 替换
        if not self:checkIsCanEnterBattlePrepare(teamDatas) then
            uiMgr:ShowInformationTips(__('队伍不能为空'))
            return
        end

        -- 2. 再检查 队伍是否改变
        if self:checkTeamDataChange(teamDatas) then
            self:requestSetAttackTeam(teamDatas)
        end

        AppFacade.GetInstance():DispatchObservers('CLOSE_CHANGE_TEAM_SCENE')

    elseif name == LOCAL_SWITCH_TEAM then
        local isAttack = body.isAttack
        if not isAttack then return end
        
        local newTeamId = body.newTeamId
        
        if self.changeTeamLayer then
            self.changeTeamLayer:SetTeamData(clone(self.changeTeamLayer:GetSelectedCardsByTeamId(newTeamId)))
            self.changeTeamLayer:SetTeamId(tostring(newTeamId))
        end
    elseif name == LOCAL_DRAG_CHANGE_TEAM then
        local isAttack = body.isAttack
        if not isAttack then return end

        if self.toCleanTeamId_ then
            self:setAttackTeamId(0)
            self.toCleanTeamId_ = false
        end

        local oldTeamId = body.oldTeamId
        local newTeamId = body.newTeamId

        uiMgr:ShowInformationTips(__('队伍替换成功'))
        --有编辑界面的话
        if self.changeTeamLayer then
            local newTeamData, oldTeamData = self.changeTeamLayer:SwapSelectedCards(oldTeamId, newTeamId)

            -- 获取当前选中的团队id
            local curTeamId = checkint(self.changeTeamLayer:GetTeamId())
            -- 拖拽更新规则：(假设: 当前选中团队为 1)
            --     1. 无论 1 拖 2 还是 2 拖1 最后选中的团队 必是 最终拖拽结束的位置
            --     2. 如果 2和3 互拖 不会改变选中状态

            -- 如果 拖拽的团队 与 被拖拽改变位置的团队 都与 当前选中的团队 
            if not (curTeamId ~= checkint(oldTeamId) and curTeamId ~= checkint(newTeamId)) then
                self.changeTeamLayer:SetTeamId(tostring(newTeamId))
                self.changeTeamLayer:SetTeamData(oldTeamData)
                -- logInfo.add(5, checkint(curTeamId) ~= checkint(newTeamId))
                if checkint(curTeamId) ~= checkint(newTeamId) then
                    self.changeTeamLayer:RefreshBattleScriptTypeUI({newTeamId = newTeamId})
                end
            end

            self.changeTeamLayer:ResetAllCardSelectState()
        end


    -- elseif name == SHOW_TAG_MATCH_EDIT_TEAM then
    --     if self:getAttackTeamId() > 0 then
    --         app.uiMgr:AddNewCommonTipDialog({
    --             text = __('使用预设编队不能进行单独修改，是否使用普通编队？'),
    --             callback = function()
    --                 self.toCleanTeamId_ = true
    --                 self:showEditTeamView(1, true)
    --             end
    --         })
    --     else
    --         local teamId = body.teamId or '1'
    --         self:showEditTeamView(teamId)
    --     end

    elseif name == CLOSE_CHANGE_TEAM_SCENE then
        self.changeTeamLayer = nil
    elseif name == COUNT_DOWN_ACTION then
        local timerName = tostring(body.timerName)
        if NAME == timerName then
            if tolua.isnull(self:GetViewComponent()) ~= nil and self:GetViewComponent() then
                local countdown = checkint(body.countdown)
                self:GetViewComponent():updateCountDown(countdown)
                if countdown <= 0 then
                    self.isTimeEnd = true
                    uiMgr:ShowInformationTips(__('本赛季已经结束'))
                    self:GetViewComponent():performWithDelay(function ()
                        self:closeView()
                    end,1)
                end
            end
        end

    elseif name == SGL.PRESET_TEAM_SELECT_CARDS then
        if self:getLeftSaveTeamTimes() <= 0 then
            uiMgr:ShowInformationTips(__('修改编队次数不足'))
            return 
        end
        local presetTeamData = checktable(body.presetTeamData)
        self:setAttackTeamId(presetTeamData.teamId)
        self.toCleanTeamId_ = false

        local defendCards = presetTeamData.cardIds or {}
        local teamDatas = {}
        for teamId, cardIds in pairs(defendCards) do
            teamDatas[tostring(teamId)] = teamDatas[tostring(teamId)] or {}
            for i, cardUuid in ipairs(cardIds) do
                if checkint(cardUuid) > 0 then
                    table.insert(teamDatas[tostring(teamId)], {id = cardUuid})
                end
            end
        end
        app:DispatchObservers(NEW_TAG_MATCH_SAVE_TEAM_SIGNAL, {teamDatas = teamDatas})
    
    elseif name == POST.NEW_TAG_MATCH_DRAW_CHALLENGE_REWARDS.sglName then
        if errcode ~= 0 then return end
        local requestData = body.requestData or {}
        local rewardId = requestData.rewardId
        local rewardItemData = self.challengeRewardsConf[rewardId]
        local rewards = rewardItemData.rewards
        if next(rewards) ~= nil then
            app.uiMgr:AddDialog('common.RewardPopup', {rewards = rewards})
        end
        self:setDrawnRewards(rewardItemData)
        self:setHasRewardsToDraw()
        self:GetViewComponent():updateHasRewardsToDraw(self:getHasRewardsToDraw().isDraw)
        --更新盒子状态（灰色，亮色）
        self:GetViewComponent():updateBoxState(self:getDrawnRewards())
    end
end 

-------------------------------------------------
-- get / set

function NewKofArenaLobbyMediator:getCtorArgs()
    return self.ctorArgs_
end

function NewKofArenaLobbyMediator:getViewData()
    return self.viewData_
end

function NewKofArenaLobbyMediator:getOwnerScene()
    return self.ownerScene_
end

function NewKofArenaLobbyMediator:getTeamDatas()
    return self.datas.team or {}
end
function NewKofArenaLobbyMediator:setTeamDatas(teamId, teamData)
    self:getTeamDatas()[tostring(teamId)] = teamData
end


function NewKofArenaLobbyMediator:getAttackTeamId()
    return checkint(self.datas.teamCustomId)
end
function NewKofArenaLobbyMediator:setAttackTeamId(teamId)
    self.datas.teamCustomId = checkint(teamId)
end


function NewKofArenaLobbyMediator:getLeftSaveTeamTimes()
    return self.datas.leftSaveTeamTimes
end
function NewKofArenaLobbyMediator:setLeftSaveTeamTimes()
    self.datas.leftSaveTeamTimes = self.datas.leftSaveTeamTimes - 1
end

function NewKofArenaLobbyMediator:getLeftFightTimes()
    return self.datas.leftAttackTimes
end
function NewKofArenaLobbyMediator:setLeftFightTimes(isAdd)
    if isAdd then
        self.datas.leftAttackTimes = self.datas.leftAttackTimes + 1
    else
        self.datas.leftAttackTimes = self.datas.leftAttackTimes - 1
    end
end

---判断是否有奖励可领取
function NewKofArenaLobbyMediator:setHasRewardsToDraw()
    local drawnlist = self:getDrawnRewards()
    local rewards = self:getDrawRewardsList(self.datas.challengeTimes, drawnlist)
    self.datas.hasRewardsToDraw = {}
    local isDraw = next(rewards) ~= nil
    self.datas.hasRewardsToDraw.isDraw = isDraw
    self.datas.hasRewardsToDraw.rewards = rewards
end
function NewKofArenaLobbyMediator:getHasRewardsToDraw()
    return self.datas.hasRewardsToDraw
end

--已领取的奖励
function NewKofArenaLobbyMediator:setDrawnRewards(curDrawRewards)
    local hasReward = false
    local drawnList = self:getDrawnRewards()
    for i = 1, table.nums(drawnList) do
        if checkint(curDrawRewards.id) == checkint(drawnList[i]) then
            hasReward = true
            return 
        end
    end
    if not hasReward then
        table.insert(drawnList, curDrawRewards.id)
    end
end
function NewKofArenaLobbyMediator:getDrawnRewards()
    return self.datas.challengeDrawnRewards
end

function NewKofArenaLobbyMediator:getIsFirstEnter()
    return self.datas.first
end
function NewKofArenaLobbyMediator:setIsFirstEnter()
    self.datas.first = IS_FIRST.NO
end

--获取待领取的奖励列表
function NewKofArenaLobbyMediator:getDrawRewardsList(challengeTimes,drawnList)
    local rewards = {}
    for k, v in pairs(self.challengeRewardsConf) do
        local isExist = false
        for i = 1, table.nums(drawnList) do
            if checkint(v.id) == checkint(drawnList[i]) then
                isExist = true
                break
            end
        end
        if not isExist then
            if checkint(challengeTimes) >= checkint(v.targetNum) then
                table.insert(rewards, v)
            end
        end
    end
    return rewards
end

--[[
    根据排名比获取降级｜升级｜保级
]]
function NewKofArenaLobbyMediator:getCurrentSectionAction(segmentId, rankPercent)
    self.segmentConf  = CONF.NEW_KOF.SEGMENT:GetAll()
    local sectionAction
    local rankPercent = checknumber(rankPercent)/100
    if rankPercent == 0 then return nil end 
    for k, v in pairs(self.segmentConf) do
        if checkint(segmentId) == checkint(v.id) then
            local upPercent = checknumber(v.upPercent)
            local downPercent = checknumber(v.downPercent)
            local flatPercent = checknumber(v.flatPercent)
            if rankPercent <= upPercent and upPercent ~= 0 then
                sectionAction = SECTION_ACTION_TAG.UP
            elseif rankPercent <= flatPercent + upPercent then
                sectionAction = SECTION_ACTION_TAG.FLAT
            elseif rankPercent <= 1  and downPercent ~= 0 then
                sectionAction = SECTION_ACTION_TAG.DOWN
            end
        end
    end
    return sectionAction
end

-------------------------------------------------
-- public method
function NewKofArenaLobbyMediator:enterLayer()
    self:SendSignal(POST.NEW_TAG_MATCH_HOME.cmdName)
end

--[[
    请求设置战队团队数据
    @params teamDatas  所有的团队的数据
]]
function NewKofArenaLobbyMediator:requestSetAttackTeam(teamDatas)
    local cards = {}
    for i, v in pairs(teamDatas) do
        cards[tostring(i)] = self:convertTeamDataToStr(v)
    end
    self:SendSignal(POST.NEW_TAG_MATCH_SAVE_TEAM.cmdName, {cards = json.encode(cards), teamCustomId = self:getAttackTeamId()})
    -- end
end

--[[
    开启倒计时
    @params leftSeconds  剩余时间
]]
function NewKofArenaLobbyMediator:startCountDown(leftSeconds)
    leftSeconds = checkint(leftSeconds) + 2
    local timerInfo = timerMgr:RetriveTimer(NAME)
    if timerInfo then
        timerMgr:RemoveTimer(NAME)
    end
    if leftSeconds > 0 then
        timerMgr:AddTimer({name = NAME, countdown = leftSeconds})
    else
        AppFacade.GetInstance():DispatchObservers(COUNT_DOWN_ACTION, {countdown = 0, timerName = NAME})
    end
end

--[[
    进入战斗
    @params _enemyData  对手战斗数据
    @params _teamsData  自定义编队数据
]]
function NewKofArenaLobbyMediator:enterBattle(_enemyData, _teamsData)
    -- 准备战斗数据
    local enemyData = _enemyData 
    local teamsData = _teamsData
    local fixedTeamsData = nil
    if teamsData then
        local teamsDataMap = {}
        for teamIndex, cardInfoList in pairs(teamsData.info or {}) do
            for _, serverCardInfo in pairs(cardInfoList) do
                teamsDataMap[tostring(serverCardInfo.id)] = serverCardInfo
            end
        end
        fixedTeamsData = {}
        for teamId, teamData in pairs(self:getTeamDatas()) do
            local fixedTeamData = {}
            for cardIndex = 1, MAX_TEAM_MEMBER_AMOUNT do
                local cardData = {}
                local cardInfo = teamData[cardIndex]
                if nil ~= cardInfo and nil ~= cardInfo.id then
                    local playerCardUuId = checkint(cardInfo.id)
                    local serverCardInfo = teamsDataMap[tostring(playerCardUuId)]
                    if serverCardInfo ~= nil then
                        --- 把最新卡牌数据的 堕神和神器数据 替换为 预设编队中卡牌拥有的堕神和神器数据
                        cardData                = clone(gameMgr:GetCardDataById(playerCardUuId))
                        cardData.pets           = serverCardInfo.pets or {}
                        cardData.artifactTalent = serverCardInfo.artifactTalent or {}
                    end
                end
                fixedTeamData[cardIndex] = cardData
            end
            fixedTeamsData[checkint(teamId)] = fixedTeamData
        end

        -- logInfo.add(5, tableToString(fixedTeamsData, 'fixedTeamsData'))
    end
    
    -------------------------------------------------
    local friendTeams = {}
    for teamId, teamData in pairs(self:getTeamDatas()) do
        friendTeams[checkint(teamId)] = {}
        for i, v in pairs(teamData) do
            table.insert(friendTeams[checkint(teamId)] , v.id)
        end
    end
    
    local enemyTeams = {}
    local enemyPlayerCards = enemyData.team or {}
    for k, v in pairs(enemyPlayerCards) do
        enemyTeams[checkint(k)] = {}
        for ii, vv in ipairs(v) do
            table.insert(enemyTeams[checkint(k)], vv)    
        end
    end

    local enemyPlayerSkill = enemyData.enemyPlayerSkill or {}

    local enemyPostionId = self.curSelectOppoentIndex


    -- 可以进行战斗
	local serverCommand = BattleNetworkCommandStruct.New(
		POST.NEW_TAG_MATCH_QUEST_AT.cmdName,
		{enemyPositionId = checkint(enemyPostionId)},
		POST.NEW_TAG_MATCH_QUEST_AT.sglName,
		POST.NEW_TAG_MATCH_QUEST_GRADE.cmdName,
        nil,
		POST.NEW_TAG_MATCH_QUEST_GRADE.sglName,
		nil,
		nil,
		nil
	)
    AppFacade.GetInstance():DispatchObservers("DOT_LOG_EVENT_SEND" , {eventId = "63-01"})
    AppFacade.GetInstance():DispatchObservers("DOT_SET_LOG_EVENT" , {eventId = "63-02"})
	local fromToStruct = BattleMediatorsConnectStruct.New(
		NAME,
		NAME
	)
    
	local battleConstructor = nil
    if fixedTeamsData then
        battleConstructor = require('battleEntry.BattleConstructorEx').new()
        battleConstructor = require('battleEntry.BattleConstructorEx').new()
        battleConstructor:InitByCommonData(
            nil,                                -- 关卡 id
            QuestBattleType.TAG_MATCH_3V3,      -- 战斗类型
            ConfigBattleResultType.NO_DROP,     -- 结算类型
            ----
            battleConstructor:GetFormattedTeamsDataByTeamsCardData(fixedTeamsData), -- 友方阵容
            battleConstructor:GetFormattedTeamsDataByTeamsCardData(enemyTeams),     -- 敌方阵容
            ----
            nil,                                -- 友方携带的主角技
            app.gameMgr:GetUserInfo().allSkill, -- 友方所有主角技
            nil,                                -- 敌方携带的主角技
            enemyPlayerSkill,                   -- 敌方所有主角技
            ----
            nil,                                -- 全局buff
            nil,                                -- 卡牌能力增强信息
            ----
            nil,                                -- 已买活次数
            nil,                                -- 最大买活次数
            false,                              -- 是否开启买活
            ----
            nil,                                -- 随机种子
            false,                              -- 是否是战斗回放
            ----
            serverCommand,                      -- 与服务器交互的命令信息
            fromToStruct                        -- 跳转信息
        )
    else
        battleConstructor = require('battleEntry.BattleConstructor').new()
        battleConstructor:InitDataByTagMatchThreeTeams(
            friendTeams,                    -- 友方阵容
            enemyTeams,                     -- 敌方阵容
            gameMgr:GetUserInfo().allSkill, -- 友方主角技
            enemyPlayerSkill,               -- 敌方主角技
            serverCommand,                  -- 与服务器交互的命令信息
            fromToStruct                    -- 跳转信息
        )
    end

	if not AppFacade.GetInstance():RetrieveMediator('EnterBattleMediator') then
		local enterBattleMediator = require('Game.mediator.EnterBattleMediator').new()
		AppFacade.GetInstance():RegistMediator(enterBattleMediator)
	end
	GuideUtils.DispatchStepEvent()
	AppFacade.GetInstance():DispatchObservers(SIGNALNAMES.Battle_Enter, battleConstructor)
end

--[[
    显示视图
]]
function NewKofArenaLobbyMediator:showView()
    self:startCountDown(self.datas.leftSeconds)
    -- 检查一遍 对手列表
    self:checkTeamCards()
    self:checkEnemyList()
    -- 结算上赛季结果
    self:showResultView(self.datas.last)
    --设置是否有奖励可领
    self:setHasRewardsToDraw()
    
    --第一次进入时，按钮屏蔽
    self:silentListener()
    self:GetViewComponent():refreshUI(self.datas, self.teamId)
end

--[[
    显示单个队伍信息
    @params teamId  队伍id
]]
function NewKofArenaLobbyMediator:showSingleTeamInfo(sender, teamId)
    local teamData = self:getTeamDatas()[tostring(teamId)]
    local isCanShow = false
    if teamData and next(teamData) ~= nil then
        for k, v in pairs(teamData) do
            if v.id then
                isCanShow = true
                break
            end
        end
    else
        isCanShow = false
    end
    if not isCanShow then
        return
    end

    uiMgr:ShowInformationTipsBoard({
        targetNode = sender, 
        type = 12,
        bgSize = cc.size(540, 171),
        title = __('总灵力'),
        viewTypeData = {
            teamData = teamData,
            teamId = teamId,
            teamMarkPosSign = 1
        }
    })

end

function NewKofArenaLobbyMediator:hideSingleTeamInfo()
    self:getOwnerScene():RemoveDialogByTag(23456)
end

--[[
    显示编辑团队界面
    @params teamId  队伍id
]]
function NewKofArenaLobbyMediator:showEditTeamView(teamId, isCleanTeam)
    
    local oppoentData = self.datas.opponent[self.curSelectOppoentIndex] or {}
    if self:getLeftSaveTeamTimes() <= 0 then
        uiMgr:ShowInformationTips(__('修改编队次数不足'))
        return 
    end
    
    local oppoentTeamDatas = {}
    for teamIndex, teamData in pairs(oppoentData.team or {}) do
        oppoentTeamDatas[tostring(teamIndex)] = {
            cards       = teamData,
            battlePoint = teamData.battlePoint
        }
    end
    local teamDatas = self:getTeamDatas()
    if checkbool(isCleanTeam) then
        teamDatas = {}
    end
    local layer = require('Game.views.tagMatch.TagMatchChangeTeamScene').new({
        teamId       = checkint(teamId) == 0 and '1' or tostring(teamId),
        teamDatas    = teamDatas,
        teamTowards = -1,
        avatarTowards = -1,
        avatarShowType = 2,
        teamChangeSingalName = NEW_TAG_MATCH_SAVE_TEAM_SIGNAL,
        battleTypeData = {
            isShowOppentTeam = next(oppoentTeamDatas) ~= nil,
            oppoentTeamDatas = oppoentTeamDatas,
            isAttack     = true,
        },
        battleType = BATTLE_SCRIPT_TYPE.TAG_MATCH
    })
    layer:setAnchorPoint(cc.p(0.5, 0.5))
    layer:setPosition(display.center)
    self:getOwnerScene():AddDialog(layer)  
    self.changeTeamLayer = layer 

end

--[[
    显示排行榜
]]
function NewKofArenaLobbyMediator:showRank()
    local mediator = require("Game.mediator.tagMatchNew.NewKofArenaRankMediator").new()
    self:GetFacade():RegistMediator(mediator)
end

--[[
    显示赛季结算
]]
function NewKofArenaLobbyMediator:showResultView(last)
    if next(last) == nil or last == nil then return end
    local className = "Game.views.tagMatchNew.NewKofArenaSeasonResultView"
    local NewKofArenaSeasonResultView = __Require(className).new(last)
    NewKofArenaSeasonResultView:setPosition(display.center)
    uiMgr:GetCurrentScene():AddDialog(NewKofArenaSeasonResultView)
end
--[[
    关闭当前界面
    @params tipText string 关闭界面提示文字
]]
function NewKofArenaLobbyMediator:closeView(tipText, isNotAddParams)
    if tipText then
        uiMgr:ShowInformationTips(tostring(tipText))
    end
    self:GetFacade():UnRegsitMediator(NAME)
    local ActivityMediator = self:GetFacade():RetrieveMediator('ActivityMediator')
    if not ActivityMediator then
        AppFacade.GetInstance():RetrieveMediator('Router'):Dispatch(
            {name = "HomeMediator"},
            {name = "ActivityMediator", params = {activityId = ACTIVITY_ID.NEW_TAG_MATCH,isFromBattle = false}}
        )
    end
end

-------------------------------------------------
-- private method

--[[
    对手信息适配器
    @params p_convertview  cell
    @params idx 
]]
function NewKofArenaLobbyMediator:onOppoentAdapter(p_convertview, idx)
    local pCell = p_convertview
    local index = idx + 1

    if pCell == nil then
        local function headClickCallback(sender)
            local index = sender:getTag()
            local enemyData = self.datas.opponent[index].team
            local viewComponent = require("Game.views.tagMatchNew.NewKofArenaDefensiveLineupView").new({defenseTeams = enemyData or {},isOpponentTeam = true})
            viewComponent:setPosition(display.center)
            self:getOwnerScene():AddDialog(viewComponent)
            self:onClickOpponentInfoAction(sender)
        end
        pCell = self:GetViewComponent():CreateOppoentDescCell(headClickCallback)
        display.commonUIParams(pCell.viewData.clickLayer, {cb = handler(self, self.onClickOpponentInfoAction)})
    end
     
    xTry(function()
       
        local viewData = pCell.viewData       
        local data = self.datas.opponent[index] 
        self:GetViewComponent():updateOppoentDescCell(viewData, data)

        local clickLayer  = viewData.clickLayer
        clickLayer:setTag(index)

        local playerHeadNode = viewData.playerHeadNode
        playerHeadNode:setTag(index)
	end,__G__TRACKBACK__)
    
    return pCell
end

function NewKofArenaLobbyMediator:silentListener()
    local isFirstEnterDefine = LOCAL.NEW_KOF_ARENA.IS_FIRST_ENTER()
    if not isFirstEnterDefine:Load() then return end
    if self:getIsFirstEnter() == IS_FIRST.NO then return end
    local viewData = self:getViewData()
    local btnSize = viewData.modifyBtn:getContentSize()
    local worldPos = viewData.modifyBtn:getParent():convertToWorldSpace(cc.p(viewData.modifyBtn:getPosition()))
    self.m_listener = cc.EventListenerTouchOneByOne:create()
    self.m_listener:setSwallowTouches(true)
    self.m_listener:registerScriptHandler(function(touch, event) 
        local position = touch:getLocation()
        local rect = {
            width = btnSize.width,
            height = btnSize.height,
            x = worldPos.x - btnSize.width/2,
            y = worldPos.y - btnSize.height/2
        }
        if cc.rectContainsPoint(rect, position) then
            return true
        end
    end,cc.Handler.EVENT_TOUCH_BEGAN)
    self.m_listener:registerScriptHandler(function(touch, event)
        local viewData = self:getViewData()
        self:onBtnAction(viewData.actionBtns[tostring(BUTTON_TAG.MODIFY)])
        self:GetViewComponent():RemoveMask()
        local isFirstEnterDefine = LOCAL.NEW_KOF_ARENA.IS_FIRST_ENTER()
        isFirstEnterDefine:Save(false)
        if self.m_listener then
            self.m_listener:setEnabled(false)
        end
        viewData.layer:setTouchEnabled(false)
    end, cc.Handler.EVENT_TOUCH_ENDED)
    viewData.layer:getEventDispatcher():addEventListenerWithFixedPriority(self.m_listener,-128)
end

-------------------------------------------------
-- check

--[[
    检查团队卡牌
]]
function NewKofArenaLobbyMediator:checkTeamCards()
    local teamCards = {}
    local serTeamCards = self:getTeamDatas()
    for teamId, cardIds in pairs(serTeamCards) do
        teamCards[tostring(teamId)] = {}
        for i, cardId in ipairs(cardIds) do
            if checkint(cardId) > 0 then
                teamCards[tostring(teamId)][i] = {id = cardId}
            end
        end
    end
    self.datas.team = teamCards
    -- logInfo.add(5, tableToString(teamCards))
end

--[[
    检查对手卡牌

    @return isOwnEnemy 是否拥有对手
]]
function NewKofArenaLobbyMediator:checkEnemyList()
    local enemyList = {}
    local serEnemyList = self.datas.opponent
    
    local emptyEnemyCount = 0

    for i = 1, MAX_ENEMY_COUNT do
        local enemy = serEnemyList[i]
        if enemy then
            local team = enemy.team
            if team == nil then
                enemy = {}
                emptyEnemyCount = emptyEnemyCount + 1
            else
                local playerBattlePoint = 0
                for teamId, playerCard in pairs(team) do
                    local battlePoint = 0
                    local cards = playerCard or {}
                    for i, cardData in ipairs(cards) do
                        -- 计算战斗力
                        battlePoint = battlePoint + cardMgr.GetCardStaticBattlePointByCardData(cardData)
                    end
                    playerCard.battlePoint = battlePoint
                    playerBattlePoint = playerBattlePoint + battlePoint
                end
                enemy.playerBattlePoint = playerBattlePoint
            end
        else
            enemy = {}
            emptyEnemyCount = emptyEnemyCount + 1
        end
        table.insert(enemyList, enemy)
    end
    
    self.datas.opponent = enemyList
    self.datas.isOwnEnemy = emptyEnemyCount ~= MAX_ENEMY_COUNT
end

function NewKofArenaLobbyMediator:calcBattlePoint(list)
    local playerBattlePoint = 0
    for teamId, playerCard in pairs(list) do
        local battlePoint = 0
        local cards = playerCard or {}
        for i, cardData in ipairs(cards) do
            -- 计算战斗力
            battlePoint = battlePoint + cardMgr.GetCardStaticBattlePointByCardData(cardData)
        end
        playerCard.battlePoint = battlePoint
        playerBattlePoint = playerBattlePoint + battlePoint
    end
    -- list.playerBattlePoint = playerBattlePoint
    return list
end

--[[
    检查是否能进入战斗准备界面
]]
function NewKofArenaLobbyMediator:checkIsCanEnterBattlePrepare(teamDatas)
    
    local satisfyTeamConditionCount = 0
    for i = 1, 3 do
        local teamData = teamDatas[tostring(i)]
        if teamData == nil or next(teamData) == nil then return false end

        for i = 1, MAX_TEAM_MEMBER_AMOUNT do
            local cardData = teamData[i]
            if cardData and cardData.id then
                satisfyTeamConditionCount = satisfyTeamConditionCount + 1
                break
            end
        end
    end

    return satisfyTeamConditionCount >= 3
end

--[[
    检查团队是否改变
]]
function NewKofArenaLobbyMediator:checkTeamDataChange(teamDatas)
    local curTeamDatas = self:getTeamDatas()
    local isChange = false
    for teamId, teamData in pairs(teamDatas) do
        local curTeamData = curTeamDatas[tostring(teamId)] or {}

        for i, cardData in ipairs(teamData) do
            local curCurData = curTeamData[i] or {}
            local cardId = cardData.id
            local curCardId = curCurData.id

            if (cardId ~= nil and curCardId == nil) 
            or (cardId == nil and curCardId ~= nil)
            or (cardId ~= nil and curCardId ~= nil and checkint(cardId) ~= checkint(curCardId)) then
                return true
            end
        end

    end
    
    return isChange
end




-------------------------------------------------
-- handler

function NewKofArenaLobbyMediator:onCloseViewAction(sender)
    PlayAudioByClickClose()
    self:closeView()
end

function NewKofArenaLobbyMediator:onClickTitleRuleAction()
    PlayAudioByClickNormal()
    uiMgr:ShowIntroPopup({moduleId = MODULE_DATA[tostring(RemindTag.TAG_MATCH)]})
end

function NewKofArenaLobbyMediator:onBtnAction(sender)
    
    PlayAudioByClickNormal()
    self:hideSingleTeamInfo()
    if self.isTimeEnd then
        uiMgr:ShowInformationTips(__('本赛季已经结束'))
        return
    end
    local tag = sender:getTag()
    -- if self:getIsFirstEnter() == IS_FIRST.YES and tag ~= BUTTON_TAG.MODIFY then return end
    if tag == BUTTON_TAG.MODIFY then
        if self:getLeftSaveTeamTimes() <= 0 then
            uiMgr:ShowInformationTips(__('修改编队次数不足'))
            return 
        end
        if self:getAttackTeamId() > 0 then
            app.uiMgr:AddNewCommonTipDialog({
                text = __('使用预设编队不能进行单独修改，是否使用普通编队？'),
                callback = function()
                    self.toCleanTeamId_ = true
                    self:showEditTeamView(self.teamId, true)
                end
            })
        else
            self:showEditTeamView(self.teamId)
        end

    elseif tag == BUTTON_TAG.FIGHT then
        
        if next(self:getTeamDatas()) == nil then
            uiMgr:ShowInformationTips(__('请先编辑自己的队伍'))
            return
        end

        if self.curSelectOppoentIndex <= 0 then
            uiMgr:ShowInformationTips(__('请先选择挑战对手'))
            return
        end

        local enemyData = self.datas.opponent[self.curSelectOppoentIndex] or {}
        if next(enemyData) == nil then
            uiMgr:ShowInformationTips(__('请选择正确的对手进行挑战'))
            return
        end

        if checkint(self:getLeftFightTimes()) <= 0 then
            uiMgr:ShowInformationTips(__('战斗次数不足'))
            return
        end
        
        local data = {
            playerAttackData  = self:getTeamDatas(),
            opponentData = enemyData,
            attackTeamId = self:getAttackTeamId(),
        }
        local mediator = require("Game.mediator.tagMatchNew.NewKofArenaFightPrepareMediator").new(data)
        self:GetFacade():RegistMediator(mediator)
    elseif tag == BUTTON_TAG.REPORT then
        self:SendSignal(POST.NEW_TAG_MATCH_ARENA_RECORD.cmdName)
    elseif tag == BUTTON_TAG.REFRESH then
        if next(self:getTeamDatas()) == nil then
            uiMgr:ShowInformationTips(__('请先编辑自己的队伍'))
            return
        end
        self:SendSignal(POST.NEW_TAG_MATCH_REFRESH_ENEMY.cmdName)
    elseif tag == BUTTON_TAG.SHOP then
        if GAME_MODULE_OPEN.NEW_STORE then
            app.uiMgr:showGameStores({storeType = GAME_STORE_TYPE.GROCERY, subType = GAME_STORE_TYPE.NEW_KOF_ARENA})
        else
            app.router:Dispatch({name = "NewKofArenaLobbyMediator"}, {name = "ShopMediator",params = {goShopIndex = 'kofArena'}})
        end
    elseif tag == BUTTON_TAG.RANK then
        self:showRank()
    elseif tag == BUTTON_TAG.GIFT then --奖励
        --这里分为两种状态；一种是有的奖励的情况，一种是没奖励的情况
        local rewardsData = self:getHasRewardsToDraw()
        local rewards = rewardsData.rewards
        if rewardsData.isDraw then
            --从第一个奖励开始领取
            for k, v in pairs(rewards) do
                self:SendSignal(POST.NEW_TAG_MATCH_DRAW_CHALLENGE_REWARDS.cmdName, {rewardId = v.id})
                return 
            end
        else
            self:GetViewComponent():updateShowRewardBar()
        end
    elseif tag == BUTTON_TAG.LOOK_REWARD then
        local rankRewardsView = require('Game.views.tagMatchNew.NewKofArenaRewardsView').new({
            data = {
                segmentId = checkint(self.datas.segmentId),
                section = self:getCurrentSectionAction(self.datas.segmentId, self.datas.rankPercent)
            }
        })
        rankRewardsView:setTag(tag)
        rankRewardsView:setPosition(display.center)
        uiMgr:GetCurrentScene():AddDialog(rankRewardsView)

    elseif tag == BUTTON_TAG.ADD_FIGHT_TIMES then
        local initParamConf = CONF.NEW_KOF.BASE_PARMS:GetAll()
        local nums = checkint(initParamConf.challengeConsume[1].num)
        local goodsId = checkint(initParamConf.challengeConsume[1].goodsId)
        local limitNum = checkint(initParamConf.challengeTimes)
        local layer = require('common.CommonTip').new({
			text = __('是否购买战斗次数?'),
			descr = __('战斗次数每日重置，是否消耗道具购买战斗次数'),
            isOnlyOK = false,
            costInfo = {goodsId = goodsId, num = nums},
			callback = function (sender)
                if self:getLeftFightTimes() < limitNum then
                    self:SendSignal(POST.NEW_TAG_MATCH_BUY_ATTACK_TIMES.cmdName)
                else
                    app.uiMgr:ShowInformationTips(__('战斗次数已达上限'))
                end
			end
		})
		layer:setPosition(display.center)
		app.uiMgr:GetCurrentScene():AddDialog(layer)
    end
end

function NewKofArenaLobbyMediator:onClickPlayerTeamHeadBg(sender)
    local tag = checkint(sender:getTag())
    self:showSingleTeamInfo(sender, tag)
    if self.teamId == tag then return end
    -- uiMgr:ShowRewardInformationTips({targetNode = sender, type = 10})
    self:GetViewComponent():updateTeamHeadSelectState(self.teamId, false)
    self:GetViewComponent():updateTeamHeadSelectState(tag, true)
    self.teamId = tag
end

function NewKofArenaLobbyMediator:onClickRewardBoxs(sender,touch)
    local index = checkint(sender:getTag())
    --显示商品
    local goodsData = self.challengeRewardsConf[tostring(index)].rewards
    local iconIds = {}
    for k, v in pairs(goodsData) do
        table.insert(iconIds, checkint(v.goodsId))
    end
    uiMgr:ShowInformationTipsBoard({
        targetNode = sender, 
        iconIds = goodsData, 
        type = 4,
        bgSize = cc.size(260, 180)
    })
end


function NewKofArenaLobbyMediator:onClickOpponentInfoAction(sender)
    local tag = checkint(sender:getTag())
    if tag == self.curSelectOppoentIndex then
        return
    end

    local viewData = self:getViewData()
    local oldIndex = self.curSelectOppoentIndex
    self.curSelectOppoentIndex = tag
    self:updateSelectFrame(viewData, oldIndex)
    self:updateSelectFrame(viewData, tag)

end

--[[
    更新对手选中框
    @params viewData 对手cell所有视图数据
    @params index    cell index
    @params isSelect 是否选中 （可选）
]]
function NewKofArenaLobbyMediator:updateSelectFrame(viewData, index, isSelect)
    if checkint(index) <= 0 then return end

    local gridView = viewData.gridView
    local cell = gridView:cellAtIndex(index - 1)
    if cell then
        local cellViewData = cell.viewData
        local selectFrame = cellViewData.selectFrame

        local isSelectFrame = nil
        if isSelect ~= nil then
            isSelectFrame = isSelect
        else
            isSelectFrame = index == self.curSelectOppoentIndex
        end
        
        selectFrame:setVisible(isSelectFrame)
    end
end

function NewKofArenaLobbyMediator:convertTeamDataToStr(teamData)
    local teamStr = ''
    local teamDataLen = #teamData
    for i = 1, teamDataLen do
        teamStr = teamStr .. (teamData[i].id or '')
        if i ~= teamDataLen then
            teamStr = teamStr .. ','
        end
    end
    return teamStr
end

function NewKofArenaLobbyMediator:convertTeamStrToData(teamStr)
    local teamArr = string.split(teamStr, ',')
    local teamData = {}
    for i, v in ipairs(teamArr) do
        local id = checkint(v)
        table.insert(teamData, id == 0 and {} or {id = id})
        
    end
    return teamData
end

return NewKofArenaLobbyMediator
