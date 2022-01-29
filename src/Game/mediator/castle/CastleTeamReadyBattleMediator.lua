--[[
游乐园（夏活）排行榜Mediator
--]]
local Mediator = mvc.Mediator
---@class CastleTeamReadyBattleMediator : Mediator
local CastleTeamReadyBattleMediator = class("CastleTeamReadyBattleMediator", Mediator)
local NAME = "Game.mediator.castle.CastleTeamReadyBattleMediator"
---@type SpringActivityConfigParser
local SpringActivityConfigParser = require('Game.Datas.Parser.SpringActivityConfigParser')
---@type UIManager
local uiMgr = app.uiMgr
 -- 显示boss 详情
local SHOW_MONSTER_DETAIL_INFO_EVENT = "SHOW_MONSTER_DETAIL_INFO_EVENT"
--显示加成卡牌
local SHOW_CARD_ADDITION_DETAIL_EVENT = "SHOW_CARD_ADDITION_DETAIL_EVENT"
function CastleTeamReadyBattleMediator:ctor( params, viewComponent )
    self.super:ctor(NAME,viewComponent)
    local params = params or {}
    self.questType = params.questType or 1
    self.difficulty = nil
    self.homeData = params.homeData  or {}
end

function CastleTeamReadyBattleMediator:InterestSignals()
    local signals = {
        POST.SPRING_ACTIVITY_SETQUESTCONFIG.sglName ,
        SHOW_MONSTER_DETAIL_INFO_EVENT ,
        SHOW_CARD_ADDITION_DETAIL_EVENT
    }
    return signals
end

function CastleTeamReadyBattleMediator:ProcessSignal( signal )
    local name = signal:GetName()
    local data = checktable(signal:GetBody())
    if name == POST.SPRING_ACTIVITY_SETQUESTCONFIG.sglName  then
        local requestData  = data.requestData

        local questId = self:GetQuestIdByQuestTypeAndDifficulty(self.questType, self.difficulty) or 1
        -- 网络命令
        local additions = {}
        if string.len(self:GetQuesMonsterPath()) > 0  then
            local day = checkint(self.homeData.day)
            local additionConf = clone(CommonUtils.GetConfigAllMess('cardAddition', 'springActivity'))
            for i, v in pairs(additionConf) do
                if day >= checkint(v.from) and checkint(v.to) >= day then
                    additions[#additions+1] = v
                end
            end
        end

        local serverCommand = BattleNetworkCommandStruct.New(
                POST.SPRING_ACTIVITY_QUEST_AT.cmdName,
                {questId = questId},
                POST.SPRING_ACTIVITY_QUEST_AT.sglName,
                POST.SPRING_ACTIVITY_QUEST_GRADE.cmdName,
                {questId = questId},
                POST.SPRING_ACTIVITY_QUEST_GRADE.sglName,
                nil,
                nil,
                nil
        )
        local fromToStruct = BattleMediatorsConnectStruct.New(
            "castle.CastleBattleMapMediator",
            "castle.CastleBattleMapMediator"
        )
        -- 阵容信息
        local  teamData = {}
        for k, v in pairs(json.decode(requestData.cards)) do
            teamData[checkint(k)] = checkint(v)
        end
        -- 选择的主角技信息
        local playerSkillData = {
            0, 0

        }
        for k , v in pairs( json.decode(requestData.skill)  or {}) do
            playerSkillData[checkint(k)] = v
        end
        -- 创建战斗构造器
        local battleConstructor = require('battleEntry.BattleConstructor').new()
        battleConstructor:InitStageDataByNormalEvent(
                checkint(questId),
                serverCommand,
                fromToStruct,
                teamData,
                playerSkillData ,
                additions
        )
        battleConstructor:OpenBattle()
        ------------ 初始化战斗构造器 -----------
    elseif name == SHOW_MONSTER_DETAIL_INFO_EVENT  then
        self:ShowMonsterDetailInfoCallBack()
    elseif name == SHOW_CARD_ADDITION_DETAIL_EVENT  then
        local mediator = require("Game.mediator.castle.CastleCardBounsMediator").new({ day = self.homeData.day })
        app:RegistMediator(mediator)
    end
end
function CastleTeamReadyBattleMediator:Initial( key )
    self.super.Initial(self,key)
    local scene = uiMgr:GetCurrentScene()
    local viewComponent  = require( 'Game.views.castle.CastleTeamReadyBattleView' ).new()
    self:SetViewComponent(viewComponent)
    viewComponent:setPosition(display.center)
    scene:AddDialog(viewComponent)

    self:CreateView()
    self:UpdateUI()
    display.commonUIParams(viewComponent.viewData.swallowView , { cb  = function()
                                                                  app:UnRegsitMediator(NAME)
    end})
    local sendData = self:ProcessingSendData()
    local battleScriptTeamMediator = require("Game.mediator.BattleScriptTeamMediator")
    local questTypeConfig = CommonUtils.GetConfigAllMess(SpringActivityConfigParser.TYPE.QUEST_TYPE ,'springActivity' )
    local consume = questTypeConfig[tostring(self.questType)] and questTypeConfig[tostring(self.questType)].consume or {}
    sendData.goodsData = consume
    sendData.pattern =  6
    sendData.battleFontSize = 46
    sendData.isDisableHomeTopSignal = true
    sendData.backCloseShow = false
    sendData.battleText = app.activityMgr:GetCastleText(__('战斗'))
    sendData.battleTitle = app.activityMgr:GetCastleText(__('编辑队伍'))
    local questId = self:GetQuestIdByQuestTypeAndDifficulty(self.questType , self.difficulty)
    local questLimitConfig = CommonUtils.GetConfigAllMess('questLimit' , 'springActivity')
    if questLimitConfig[tostring(questId)] then
        local questLimitOneConfig = questLimitConfig[tostring(questId)]
        sendData.limitCardsCareers =  questLimitOneConfig.career
        sendData.limitCardsQualities = questLimitOneConfig.qualityId
        sendData.cardId = questLimitOneConfig.cardId or {}
    end
    local mediator = battleScriptTeamMediator.new(sendData)
    self:GetFacade():RegistMediator(mediator)
    mediator:GetViewComponent():setVisible(false)
    --viewComponent:EnterAction()
    viewComponent:runAction(
        cc.Spawn:create(
            cc.Sequence:create(
                cc.DelayTime:create(0.2),
                cc.CallFunc:create(function()
                    mediator:GetViewComponent():setVisible(true)
                    mediator:GetViewComponent():BottomRunAction(true)
                end)
            ),
            cc.Sequence:create(
                cc.CallFunc:create(function()
                    viewComponent:EnterAction()
                end),
                cc.DelayTime:create(0.2)
            )
        )
    )

end
--==============================--
---@Description: 获取到选中的index
---@author : xingweihao
---@date : 2019/3/6 5:24 PM
--==============================--

function CastleTeamReadyBattleMediator:GetDifficulty()
    if not  self.difficulty then
        local homeData = self:GetHomeData()
        local questInfo = homeData.questInfo or {}
        if questInfo  then
            if questInfo[tostring(self.questType)] then
                self.difficulty  = checkint( questInfo[tostring(self.questType)].lastDifficulty)
                self.difficulty = self.difficulty > 0 and self.difficulty or 1
            else
                self.difficulty = self:GetRecommendDifficultyByQuestType(self.questType)
            end
        end
    end
    return self.difficulty
end
function CastleTeamReadyBattleMediator:GetHomeData()
    return self.homeData
end

function CastleTeamReadyBattleMediator:CreateView()
    local questTypeConfig = CommonUtils.GetConfigAllMess(SpringActivityConfigParser.TYPE.QUEST_TYPE , 'springActivity')
    local questTypeOneConfig = questTypeConfig[tostring(self.questType)]
    if checkint(questTypeOneConfig.skipQuest) ==1  then
        self:CreateCommonView()
    else
        self:CreateSpecialView()
    end
end
---==============================--
---@Description: 创建常见的三种关卡
---@author : xingweihao
---@date : 2019/3/6 2:42 PM
--==============================--

function CastleTeamReadyBattleMediator:CreateCommonView()
    ---@type CastleTeamReadyBattleView
    local  viewComponent = self:GetViewComponent()
    viewComponent:CreateCommonView()
    self:BindCommonClick()
end
---==============================--
---@Description: 创建特殊关卡信息
---@author : xingweihao
---@date : 2019/3/6 2:42 PM
--==============================--
function CastleTeamReadyBattleMediator:CreateSpecialView()
    ---@type CastleTeamReadyBattleView
    local  viewComponent = self:GetViewComponent()
    viewComponent:CreateSpecialView()
end
--==============================--
---@Description: 绑定困难关卡的点击
---@author : xingweihao
---@date : 2019/3/7 3:54 PM
--==============================--
function CastleTeamReadyBattleMediator:BindCommonClick()
    ---@type CastleTeamReadyBattleView
    local viewComponent = self:GetViewComponent()
    local commonLayoutView = viewComponent.commonLayoutView
    local difficultTable = commonLayoutView.difficultTable
    for index , difficultLayout in pairs(difficultTable) do
        local defaultImage = difficultLayout:getChildByName("defaultImage")
        display.commonUIParams(defaultImage , { cb = handler(self, self.DifficultyClick)})
    end
    display.commonUIParams(commonLayoutView.sweepBtn, {cb = handler(self, self.SweepClick)})
end
--==============================--
---@Description: 困难关卡的点击事件
---@author : xingweihao
---@date : 2019/3/7 3:54 PM
--==============================--
function CastleTeamReadyBattleMediator:DifficultyClick(sender)
    local tag = sender:getTag()
    self.difficulty = tag
    local viewComponent = self:GetViewComponent()
    local questId  = self:GetQuestIdByQuestTypeAndDifficulty(self.questType ,tag )
    local isSweep = self:CheckIsSweep(questId)
    self:UpdateHeadNode()
    viewComponent:UpdateCommonUI(self.questType , tag,  isSweep )
end
--==============================--
---@Description: 扫荡按钮回到事件
---@author : xingweihao
---@date : 2019/3/7 3:54 PM
--==============================--
function CastleTeamReadyBattleMediator:SweepClick(sender)
    
    local questId = self:GetQuestIdByQuestTypeAndDifficulty(self.questType, self:GetDifficulty())
    local isSweep = self:CheckIsSweep(questId)
    if isSweep then
        local questTypeOneConfig = CommonUtils.GetConfigAllMess(SpringActivityConfigParser.TYPE.QUEST_TYPE , 'springActivity')[tostring(self.questType)]
        local commonSweepView = require('common.CommonSweepView').new({
            questId =questId ,
            isGoodNode = true  , 
            consumeData = questTypeOneConfig.consume  ,
            battleSweepSingalName = POST.SPRING_ACTIVITY_SWEEP.cmdName 
            
            })
        commonSweepView:setPosition(display.center)
        app.uiMgr:GetCurrentScene():AddDialog(commonSweepView)
    else
        app.uiMgr:ShowInformationTips(app.activityMgr:GetCastleText(__('请先通关当前关卡')))
        return
    end
end

function CastleTeamReadyBattleMediator:UpdateUI()
    local questTypeConfig = CommonUtils.GetConfigAllMess(SpringActivityConfigParser.TYPE.QUEST_TYPE , 'springActivity')
    local questTypeOneConfig = questTypeConfig[tostring(self.questType)]
    if checkint(questTypeOneConfig.skipQuest) ==1  then
        self:UpdateCommonUI()
    else
        self:UpdateSpecialUI()
    end
end
function CastleTeamReadyBattleMediator:UpdateCommonUI()
    ---@type CastleTeamReadyBattleView
    local  viewComponent = self:GetViewComponent()
    local difficulty = self:GetDifficulty()
    local questId  = self:GetQuestIdByQuestTypeAndDifficulty(self.questType ,self:GetDifficulty())
    local isSweep = self:CheckIsSweep(questId)
    viewComponent:UpdateCommonUI(self.questType , difficulty,  isSweep )
    viewComponent:UpdateSameUI(self.questType)
    self:UpdateHeadNode()
end


function CastleTeamReadyBattleMediator:UpdateSpecialUI()
    ---@type CastleTeamReadyBattleView
    local  viewComponent = self:GetViewComponent()
    viewComponent:UpdateSameUI(self.questType)
    local homeData = self:GetHomeData()
    viewComponent:UpdateSpecialUI(checkint(homeData.specialHighestHurt) , self.questType)
    self:UpdateHeadNode()
end
function CastleTeamReadyBattleMediator:UpdateHeadNode()
    local monsterStr = self:GetQuesMonsterPath()
    ---@type CastleTeamReadyBattleView
    local viewComponent = self:GetViewComponent()
    viewComponent:UpdateHeadNode(monsterStr)
end
--[[
    向BattleScriptTeamMediator 传输数据
--]]
function CastleTeamReadyBattleMediator:ProcessingSendData()

    local teamData = { -- 加工具有的基本卡牌数据格式
        {},
        {},
        {},
        {},
        {},
    }
    local equipedPlayerSkills = { -- 加工具有的基本的技能的数据格式
        ["1"] =  {},
        ["2"] =  {}
    }
    local homeData = self:GetHomeData()
    local castleTeamData =  homeData.questInfo or {}
    local teamDatas = castleTeamData[tostring(self.questType)] and castleTeamData[tostring(self.questType)].cards    or {}
    for k , v in pairs (teamDatas) do
        if teamData[checkint(k)] then
            teamData[checkint(k)].id = v
        end
    end
    local skill = castleTeamData[tostring(self.questType)] and castleTeamData[tostring(self.questType)].skill    or {}
    for k , v in  pairs (skill) do
        if equipedPlayerSkills[tostring(k)] then
            equipedPlayerSkills[tostring(k)].skillId = v
        end
    end
    local  needData = {
        teamData = teamData ,
        equipedPlayerSkills = equipedPlayerSkills ,
        callback = handler(self, self.BattleCallBack) ,-- 开启战斗的回调设置
        battleType = BATTLE_SCRIPT_TYPE.TAG_MATCH,
        isDisableHomeTopSignal = true,
        scriptType  = 2
    }
    return needData
end

function CastleTeamReadyBattleMediator:BattleCallBack(data)
    local questTypeConfig = CommonUtils.GetConfigAllMess(SpringActivityConfigParser.TYPE.QUEST_TYPE, 'springActivity')
    local questTypeOneConfig =questTypeConfig[tostring(self.questType)]
    local consumeData = questTypeOneConfig.consume
    local needNum = consumeData[1].num
    local ownerNum = CommonUtils.GetCacheProductNum(consumeData[1].goodsId)
    if ownerNum >= needNum  then
        self:SendSignal(POST.SPRING_ACTIVITY_SETQUESTCONFIG.cmdName , { questType = self.questType ,  cards = json.encode(data.cards)  , skill = json.encode(data.skill)})
    else
        app.uiMgr:ShowInformationTips(app.activityMgr:GetCastleText(__('道具不足')))
    end
end
---==============================--
---@Description: 显示怪物详情的回调
--==============================--
function CastleTeamReadyBattleMediator:ShowMonsterDetailInfoCallBack()
    local questId = self:GetQuestIdByQuestTypeAndDifficulty(self.questType , self.difficulty)
    local mediator = require('Game.mediator.BossDetailMediator').new({questId = questId})
    app:RegistMediator(mediator)
end
--==============================--
---@Description: 根据questType 和difficulty 查找关卡
---@param questType number  关卡类型、 difficulty 关卡难度
---@author : xingweihao
---@date : 2019/3/6 8:06 PM
--==============================--
--- 根据questType 和difficulty 查找关卡
function CastleTeamReadyBattleMediator:GetQuestIdByQuestTypeAndDifficulty(questType , difficulty)
    local questConfig  = CommonUtils.GetConfigAllMess(SpringActivityConfigParser.TYPE.QUEST , "springActivity")
    local questTypeConfig =  CommonUtils.GetConfigAllMess(SpringActivityConfigParser.TYPE.QUEST_TYPE , "springActivity")
    local specialQuestType  = 0 
    --- 取出特殊的关卡类型
    for questType , questTypeData in pairs(questTypeConfig) do
        if checkint(questTypeData.skipQuest) == 2 then 
            specialQuestType = checkint( questType)
        end     
    end
    questType = checkint(questType)
    difficulty = checkint(difficulty)
    for questId, questData in pairs(questConfig) do
        if  (checkint(questData.type) ==  questType  
        and  checkint(questData.difficulty) ==  difficulty) 
        or (specialQuestType == checkint(questData.type) and questType == specialQuestType )  then
            return questId
        end
    end
    return 45001
end
---==============================--
---@Description: 获取到关卡的怪物路径
--==============================--
function CastleTeamReadyBattleMediator:GetQuesMonsterPath()
    local questId = self:GetQuestIdByQuestTypeAndDifficulty(self.questType, self.difficulty)
    local questConfig = CommonUtils.GetConfigAllMess(SpringActivityConfigParser.TYPE.QUEST , 'springActivity')
    local questOneConfig = questConfig[tostring(questId)] or {}
    if type(questOneConfig.monsterInfo) == 'table' and table.nums(questOneConfig.monsterInfo) > 0   then
        local monsterId = questOneConfig.monsterInfo[1]
        local monsterConf = CommonUtils.GetConfigAllMess('monster' ,'monster')
        local monsterOneConf = monsterConf[tostring(monsterId)]
        local drawId = monsterOneConf.drawId or 300001
        return AssetsUtils.GetCardHeadPath(drawId)
    end
    return ''
end
--==============================--
---@Description: 检测当前关卡是否可以扫荡
---@param questId number 关卡id
---@author : xingweihao
---@date : 2019/3/6 8:15 PM
--==============================--

function CastleTeamReadyBattleMediator:CheckIsSweep(questId )
    questId = checkint(questId)
    local homeData = self:GetHomeData() or {}
    local passQuests = homeData.passQuests or {}
    local isSweep  = false
    for index , vQuestId      in pairs(passQuests) do
        if checkint(vQuestId) == questId then
            isSweep = true
            break
        end
    end
    return isSweep
end
--==============================--
---@Description: 检测当前关卡是否可以扫荡
---@param questId number 关卡id
---@author : xingweihao
---@date : 2019/3/6 8:15 PM
--==============================--
function CastleTeamReadyBattleMediator:GetRecommendDifficultyByQuestType(questType)
    local questConfig  = CommonUtils.GetConfigAllMess(SpringActivityConfigParser.TYPE.QUEST , "springActivity")
    local questOneConfig = {}
    for i, questData in pairs(questConfig) do
        if checkint(questData.type)  == questType  then
            questOneConfig[tostring(questData.difficulty)] = questData
        end
    end

    for i = 4 , 1, -1 do
        local questData =  questOneConfig[tostring(i)] or {}
        if  checkint(questData.recommendLevel) <=   app.gameMgr:GetUserInfo().level  then
            return checkint(questData.difficulty)
        end
    end
    return 1
end

function CastleTeamReadyBattleMediator:OnRegist()
    regPost(POST.SPRING_ACTIVITY_SETQUESTCONFIG)
    regPost(POST.SPRING_ACTIVITY_SWEEP)
end

function CastleTeamReadyBattleMediator:OnUnRegist()
    unregPost(POST.SPRING_ACTIVITY_SETQUESTCONFIG)
    unregPost(POST.SPRING_ACTIVITY_SWEEP)
    local viewComponent = self:GetViewComponent()
    if  viewComponent and (not tolua.isnull(viewComponent)) then
        viewComponent:removeFromParent()
    end
    local mediator = app:RetrieveMediator("BattleScriptTeamMediator")
    if mediator then
        app:UnRegsitMediator("BattleScriptTeamMediator")
    end
end
return CastleTeamReadyBattleMediator
