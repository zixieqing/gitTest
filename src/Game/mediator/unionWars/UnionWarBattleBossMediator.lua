
---
--- Created by xingweihao.
--- DateTime: 27/10/2017 9:53 AM
---
local Mediator = mvc.Mediator
---@class UnionWarBattleBossMediator : Mediator
local UnionWarBattleBossMediator = class("UnionWarBattleBossMediator", Mediator)
---@type UIManager
local uiMgr = app.uiMgr
---@type UnionConfigParser
local unionConfigParser = require('Game.Datas.Parser.UnionConfigParser')
local NAME = "UnionWarBattleBossMediator"
local UWB_CHANGE_TEAM_MEMBER_SIGNAL = 'UWB_CHANGE_TEAM_MEMBER_SIGNAL'
local LOCAL_UWB_BOSS_SR_TEAM_MEMBERS_KEY =  'LOCAL_UWB_BOSS_SR_TEAM_MEMBERS_KEY'
local LOCAL_UWB_BOSS_R_TEAM_MEMBERS_KEY =  'LOCAL_UWB_BOSS_R_TEAM_MEMBERS_KEY'
local LOCAL_UWB_TEAM_MEMBERS_KEY = 'LOCAL_UWB_TEAM_MEMBERS_KEY'
--- 用于中转所谓的get方法
local WARS_SITE_MODEL = {
    BUILDINGID         = 'BuildingId',
    PLAYERID           = 'PlayerId',
    PLAYER_LEVEL       = 'PlayerLevel',
    PLAYER_NAME        = 'PlayerName',
    PLAYER_AVATAR      = 'PlayerAvatar',
    PLAYER_AVATARFRAME = 'PlayerAvatarFrame',
    PLAYER_CARDS       = 'PlayerCards',
    PLAYER_HP          = 'PlayerHP',
    DEFEND_STATE       = 'DefendState',
}

local UNION_WARS_MODEL = {
    WARS_BASE_TIME   = "WarsBaseTime",
    WARS_STEPID      = "WarsStepId",
    DEFEND_CARDS_MAP = "DefendCards",
    DEAD_CARDS_MAP   = "DeadCardsMap",
    LEFT_ATTACH_NUM  = "LeftAttachNum",
    TOTAL_ATTACH_NUM = "TotalAttachNum",
    UNION_MAP_MODEL  = "UnionMapModel",
    ENEMY_MAP_MODEL  = "EnemyMapModel",
}

local WARS_MAP_MODEL = {
    UNION_NAME           = "UnionName",
    UNION_AVATAR         = "UnionAvatar",
    UNION_LEVEL          = "UnionLevel",
    WARS_BOSS_R_QUESTID  = "WarsBossRQuestId",
    WARS_BOSS_SR_QUESTID = "WarsBossSRQuestId",
    MAP_SITE_MODEL_MAP   = "MapSiteModelMap",
}

function UnionWarBattleBossMediator:ctor( param, viewComponent )
    self.super:ctor(NAME,viewComponent)
    self.warsBeastQuestId = param.warsBeastQuestId
    self.warsBeastLevel = param.warsBeastLevel
    local warsBeastQuestConf = CommonUtils.GetConfigAllMess(unionConfigParser.TYPE.WARS_BOSS_QUEST , 'union')
    local warsOneBeastQuestConf =  warsBeastQuestConf[tostring(self.warsBeastQuestId )] or {}
    LOCAL_UWB_TEAM_MEMBERS_KEY =  checkint(warsOneBeastQuestConf.type) == 2 and   LOCAL_UWB_BOSS_SR_TEAM_MEMBERS_KEY or LOCAL_UWB_BOSS_R_TEAM_MEMBERS_KEY

end
function UnionWarBattleBossMediator:InterestSignals()
    local signals = {
        UWB_CHANGE_TEAM_MEMBER_SIGNAL
    }
    return signals
end
function UnionWarBattleBossMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local responseData = signal:GetBody()
    if name == UWB_CHANGE_TEAM_MEMBER_SIGNAL  then
       self:EditTeamMemberCallback(responseData)
    end
end
function UnionWarBattleBossMediator:Initial( key )
    self.super.Initial(self,key)
    ---@type UnionWarBattleBossView
    local viewComponent = require("Game.views.unionWars.UnionWarBattleBossView").new()
    viewComponent:setPosition(display.center)
    self:SetViewComponent(viewComponent)
    app.uiMgr:GetCurrentScene():AddDialog(viewComponent)
    viewComponent:UpdateView(self:GetUnionWarBossQuestId()  ,self:GetTotalAttackNum() , self:GetLeftAttackNum())
    self:SetTeamData(self:GetLocalWBTeamMembers())
    viewComponent:RefreshTeamMember(self:GetTeamData())
    self:BindingClick()
end
function UnionWarBattleBossMediator:BindingClick()
    ---@type  UnionWarBattleBossView
    local viewComponent = self:GetViewComponent() 
    local viewData  = viewComponent.viewData
    for k, v in pairs(viewData.addBtns) do
        display.commonUIParams(v, {cb = handler(self , self.EditTeamClick)  })
    end
    display.commonUIParams(viewData.bossDetailBtn , {cb = handler(self , self.BossDetailBtnClickHandler)})
    display.commonUIParams(viewData.battleBtn , {cb = handler(self , self.ReadyEnterUnionWBBattle)})
    display.commonUIParams(viewData.backBtn , {cb = function()
        PlayAudioByClickClose()
       app:UnRegsitMediator(NAME)
    end})
end
--==============================--
---@Description: 获取到剩余挑战次数
---@author : xingweihao
---@date : 2019/4/16 5:55 PM
--==============================--
function UnionWarBattleBossMediator:GetLeftAttackNum()
    local leftAttackNum = self:GetUnionWarsModelValueByKey(UNION_WARS_MODEL.LEFT_ATTACH_NUM)
    return  leftAttackNum
end
---==============================--
---@Description: 获取到公会战挑战的总次数
--==============================--
function UnionWarBattleBossMediator:GetTotalAttackNum()
    local totalAttackNum = self:GetUnionWarsModelValueByKey(UNION_WARS_MODEL.TOTAL_ATTACH_NUM)
    return totalAttackNum
end

function UnionWarBattleBossMediator:SetTeamData(data)
    self.teamData = data
end
--[[
获取编队数据
--]]
function UnionWarBattleBossMediator:GetTeamData()
    return self.teamData or {}
end
function UnionWarBattleBossMediator:SetLocalWBTeamMembers(data)
    local str = json.encode(data)
    cc.UserDefault:getInstance():setStringForKey(self:GetLocalTeamDataKey(), str)
    cc.UserDefault:getInstance():flush()
end
--[[
本地保存的队伍信息
--]]
function UnionWarBattleBossMediator:GetLocalWBTeamMembers()
    local str = cc.UserDefault:getInstance():getStringForKey(self:GetLocalTeamDataKey(), '{}')
    local table = json.decode(str)
    return table
end
--[[
获取保存阵容的本地key
--]]
function UnionWarBattleBossMediator:GetLocalTeamDataKey()
    return tostring(app.gameMgr:GetUserInfo().playerId) .. LOCAL_UWB_TEAM_MEMBERS_KEY
end

---==============================--
---@Description: 通过key 返回对应的 UnionWarsModel属性
--==============================--
function UnionWarBattleBossMediator:GetUnionWarsModelValueByKey(key)
    local unionWarsModel =   app.unionMgr:getUnionWarsModel()
    local values =  unionWarsModel["get" ..  key](unionWarsModel)
    return values
end

---==============================--
---@Description: 通过key 返回对应的 UnionWarsModel属性
--==============================--
function UnionWarBattleBossMediator:GetTotalAttackNum()
    local totalAttackNum = self:GetUnionWarsModelValueByKey(UNION_WARS_MODEL.TOTAL_ATTACH_NUM)
    return totalAttackNum
end

---==============================--
---@Description: 获取防守的卡牌
--==============================--
function UnionWarBattleBossMediator:GetDefenceCards()
    local  defencesMapCardsStr =  self:GetUnionWarsModelValueByKey(UNION_WARS_MODEL.DEFEND_CARDS_MAP)
    local defencesListCards = table.split(defencesMapCardsStr ,",")
    local limitDefences = {}
    local cards = app.gameMgr:GetUserInfo().cards
    local cardId = nil
    for index , id  in pairs(defencesListCards) do
        if checkint(id) > 0  then
            if  cards[tostring(id)] then
                cardId = cards[tostring(id)].cardId
                limitDefences[tostring(cardId)] = cardId
            end
        end
    end
    return limitDefences
end


---==============================--
---@Description: 获取到已经阵亡的卡牌
--==============================--
function UnionWarBattleBossMediator:GetDeadCards()
    local  deadMapCards =  self:GetUnionWarsModelValueByKey(UNION_WARS_MODEL.DEAD_CARDS_MAP)
    local deadListCards = {}
    local cards = app.gameMgr:GetUserInfo().cards
    local cardId = nil
    for id , v in pairs(deadMapCards) do
        cardId = cards[tostring(id)]
        deadListCards[tostring(cardId)] = cardId
    end
    return deadListCards
end

function UnionWarBattleBossMediator:EditTeamMemberCallback(data)
    ------------ data ------------
    self:SetTeamData(data.teamData)
    -- 保存一次本地缓存
    self:SetLocalWBTeamMembers(self:GetTeamData())
    ------------ data ------------

    ------------ view ------------
    -- 关闭阵容界面
    AppFacade.GetInstance():DispatchObservers('CLOSE_CHANGE_TEAM_SCENE')

    self:GetViewComponent():RefreshTeamMember(self:GetTeamData())
    ------------ view ------------
end
--==============================--
---@Description: 编辑队伍
---@author : xingweihao
---@date : 2019/4/11 2:04 PM
--==============================--
function UnionWarBattleBossMediator:EditTeamClick()
    PlayAudioByClickNormal()
    local deadCards = self:GetDeadCards()
    --local defencesCards = app.unionMgr:getUnionWarsModel():isJoinMember() and self:GetDefenceCards() or {}
    local defencesCards = {}
    local limitCards = {}
    -- 收集限制的卡牌
    for i, cardId  in pairs(deadCards) do
        limitCards[tostring(cardId)] = cardId
    end
    for i, cardId  in pairs(defencesCards) do
        limitCards[tostring(cardId)] = cardId
    end

    local cards = app.gameMgr:GetUserInfo().cards
    local allCards = {}
    for id, cardData  in pairs(cards) do
        -- 排除掉收集限制的卡牌
        if not limitCards[tostring(cardData.cardId)]  then
            allCards[#allCards+1] = cardData.cardId
        end
    end
    local questConf = CommonUtils.GetConfigAllMess(unionConfigParser.TYPE.WARS_BOSS_LIMIT , 'union')
    local questId = self:GetUnionWarBossQuestId()
    local limitCardsQualities = questConf[tostring(questId)].qualityId
    local limitCardsCareers = questConf[tostring(questId)].career
    local layer = require('Game.views.pvc.PVCChangeTeamScene').new({
       teamDatas             = {[1] = clone(self:GetTeamData())},
       title                 = __('编辑队伍'),
       teamTowards           = 1,
       avatarTowards         = 1,
       backCloseShow         = false,
       isDisableHomeTopSignal = true,
       teamChangeSingalName  = UWB_CHANGE_TEAM_MEMBER_SIGNAL,
       limitCardsQualities   = limitCardsQualities,
       limitCardsCareers     = limitCardsCareers,
       allCards              = allCards,
       battleType            = 1
   })
    layer:setAnchorPoint(cc.p(0.5, 0.5))
    layer:setPosition(display.center)
    app.uiMgr:GetCurrentScene():AddDialog(layer)
end

---==============================--
---@Description: 获取到敌方工会的姓名
---@author : xingweihao
---@date : 2019/4/16 10:22 AM
--==============================--
function UnionWarBattleBossMediator:GetUnionWarBossQuestId()
    return checkint(self.warsBeastQuestId)
end
function UnionWarBattleBossMediator:GetUnionWarBossLevel()
    return checkint( self.warsBeastLevel)
end


--==============================--
---@Description: boss 详情的回调
---@author : xingweihao
---@date : 2019/4/11 2:04 PM
--==============================--

function UnionWarBattleBossMediator:BossDetailBtnClickHandler()
    PlayAudioByClickNormal()
    local warsBeastQuestId =  self:GetUnionWarBossQuestId()
    local BossDetailMediator = require("Game.mediator.BossDetailMediator")
    local mediator = BossDetailMediator.new({ questId = warsBeastQuestId  })
    AppFacade.GetInstance():RegistMediator(mediator)
end
function UnionWarBattleBossMediator:ReadyEnterUnionWBBattle(data)
    -- 检查阵容
    PlayAudioByClickNormal()
    local leftAttackNum = self:GetLeftAttackNum()
    if leftAttackNum <= 0 then
        uiMgr:ShowInformationTips(__('次数不足!!!'))
        return
    end
    local teamData = self:GetTeamData()
    local hasCard = false
    for i,v in ipairs(teamData) do
        if nil ~= v.id then
            local c_id = checkint(v.id)
            local cardData = app.gameMgr:GetCardDataById(c_id)
            if nil ~= cardData and 0 ~= checkint(cardData.cardId) then
                hasCard = true
                break
            end
        end
    end
    if not hasCard then
        -- 没带卡
        uiMgr:ShowInformationTips(__('队伍不能为空!!!'))
        return
    end
    self:EnterUnionWBBattle()
end

--[[
进入战斗
--]]
function UnionWarBattleBossMediator:EnterUnionWBBattle()
    local teamDataStr = self:ConvertTeamData2Str(self:GetTeamData())
    local fixedTeamData = {}
    for i = 1, MAX_TEAM_MEMBER_AMOUNT do
        local cardInfo = self:GetTeamData()[i]
        if nil ~= cardInfo and nil ~= cardInfo.id then
            fixedTeamData[i] = checkint(cardInfo.id)
        end
    end

    -- 服务器参数
    local serverCommand = BattleNetworkCommandStruct.New(
            POST.UNION_WARS_BOSS_QUEST_AT.cmdName,
            {warsBossQuestId = self:GetUnionWarBossQuestId(), cards = teamDataStr},
            POST.UNION_WARS_BOSS_QUEST_AT.sglName,
            
            POST.UNION_WARS_BOSS_QUEST_GRADE.cmdName,
            {warsBossQuestId = self:GetUnionWarBossQuestId()},
            POST.UNION_WARS_BOSS_QUEST_GRADE.sglName,
            
            nil ,
            nil,
            nil
    )

    local fromToStruct = BattleMediatorsConnectStruct.New(
            "unionWars.UnionWarsBattleMemberMediator",
            "unionWars.UnionWarsHomeMediator"
    )
    local  teamData = {}
    for k, v in pairs(self:GetTeamData()) do
        teamData[checkint(k)] = checkint(v.id)
    end
    -- 选择的主角技信息
    local playerSkillData = {
        0, 0
    }
    --local warsBeastQuestConf = CommonUtils.GetConfigAllMess(unionConfigParser.TYPE.WARS_BOSS_QUEST , 'union')
    local bossQuestId = self:GetUnionWarBossQuestId()
    local level = self:GetUnionWarBossLevel()
    if bossQuestId > 0 then
        -- 创建战斗构造器
        local battleConstructor = require('battleEntry.BattleConstructor').new()
        battleConstructor:InitByUnionWarsPVB(
                bossQuestId,
                level,
                teamData,
                playerSkillData,
                {},
                serverCommand,
                fromToStruct
        )
        battleConstructor:OpenBattle()
    else
        app.uiMgr:ShowInformationTips(__('关卡_id_不存在'), {_id_ = bossQuestId})
    end
    ------------ 初始化战斗构造器 -----------
end
--[[
获取转换后传给服务器的阵容数据
@params teamData table
@return str string 阵容数据
--]]
function UnionWarBattleBossMediator:ConvertTeamData2Str(teamData)
    local str = ''
    for i = 1, MAX_TEAM_MEMBER_AMOUNT do
        local cardInfo = teamData[i]
        if nil ~= cardInfo and nil ~= cardInfo.id and 0 ~= checkint(cardInfo.id) then
            str = str .. cardInfo.id
        end
        str = str .. ','
    end
    return str
end
--[[
    注册的通知
--]]
function UnionWarBattleBossMediator:OnRegist()

end

function UnionWarBattleBossMediator:OnUnRegist()
    local viewComponent = self:GetViewComponent()
    if viewComponent and (not tolua.isnull(viewComponent)) then
        viewComponent:runAction(cc.RemoveSelf:create())
    end
end

return UnionWarBattleBossMediator

