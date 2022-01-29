--[[
奖励mediator
--]]
local Mediator = mvc.Mediator
---@class CastleBattleMapMediator :Mediator
local CastleBattleMapMediator = class("CastleBattleMapMediator", Mediator)
local NAME = "Game.mediator.castle.CastleBattleMapMediator"
CastleBattleMapMediator.NAME = NAME
---@type SpringActivityConfigParser
local SpringActivityConfigParser = require('Game.Datas.Parser.SpringActivityConfigParser')

function CastleBattleMapMediator:ctor(params, viewComponent)
    self.super.ctor(self, NAME, viewComponent)
    self.ctorArgs_ = checktable(params)
    self.homeData = params.homeData or {}
    -- 解锁的关卡模式
    self.unLockTable = {
        ['1'] = false ,
        ['2'] = false ,
        ['3'] = false ,
        ['4'] = false
    }
end
function CastleBattleMapMediator:GetHomeData()
    return self.homeData or {}
end
function CastleBattleMapMediator:InterestSignals()
    return {
        SGL.REFRESH_NOT_CLOSE_GOODS_EVENT,
        POST.SPRING_ACTIVITY_BATTLE_HOME.sglName,
        POST.SPRING_ACTIVITY_UNLOCK_STORY.sglName,
        CASTLE_END_EVENT ,
        POST.SPRING_ACTIVITY_SWEEP.sglName
    }
end
function CastleBattleMapMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local body = signal:GetBody() or {}
    if name  == SGL.REFRESH_NOT_CLOSE_GOODS_EVENT then
        self:UpdateBottomUI()
        self:UpdateTopUI()
    elseif name == POST.SPRING_ACTIVITY_BATTLE_HOME.sglName then
        self.homeData = body
        self:InsertPassQuest()
        self:CheckCurrentQuestTypeUnLock()
        self:UpdateUI()
        self:PlayStoryPlot()
    elseif name == POST.SPRING_ACTIVITY_UNLOCK_STORY.sglName then
        local requestData = body.requestData
        self.homeData.story[#self.homeData.story+1] = requestData.storyId
    elseif name == POST.SPRING_ACTIVITY_SWEEP.sglName then
        local responseData = body
        local rewardsTable = {}
        for index , sweepOneData in pairs(responseData.sweep) do
            local rewards = sweepOneData.rewards
            for aIndex, goodsData in pairs(rewards) do
                if rewardsTable[tostring(goodsData.goodsId)] then
                    rewardsTable[tostring(goodsData.goodsId)] =  checkint(rewardsTable[tostring(goodsData.goodsId)]) + goodsData.num
                else
                    rewardsTable[tostring(goodsData.goodsId)] = checkint( goodsData.num )
                end
            end
        end
        local  rewardsArray = {}
        for goodsId , num  in pairs(rewardsTable) do
            rewardsArray[#rewardsArray+1] = {
                goodsId = goodsId ,
                num = num
            }
        end
        local requestData  = responseData.requestData
        local consumeData ={{
                                goodsId = requestData.consumeGoodId ,
                                num = - requestData.consumeOneNums  *  requestData.times ,
                            }}
        --rewardsArray[#rewardsArray+1] = consumeData
        CommonUtils.DrawRewards(consumeData)
        app.uiMgr:AddDialog('common.RewardPopup', {rewards = rewardsArray })
    elseif name == CASTLE_END_EVENT then
        app.activityMgr:ShowBackToHomeUI()
    end
end
-- inheritance method
function CastleBattleMapMediator:Initial(key)
    self.super.Initial(self, key)
    local viewComponent = require("Game.views.castle.CastleBattleMapView").new({callback = handler(self, self.ModuleClick)})
    app.uiMgr:SwitchToScene(viewComponent)
    self:SetViewComponent(viewComponent)
    local viewData = viewComponent.viewData
    -- 返回到主界面

    viewData.backBtn:setOnClickScriptHandler(handler(self, self.BackCastMain))
    display.commonUIParams(viewData.tabNameLabel , { cb = handler(self, self.TipModuleExplain)})
   --viewComponent:EnterAction()
end
--==============================--
---@Description:更新战斗地图界面
---@author : xingweihao
---@date : 2019/3/6 10:47 AM
--==============================--

function CastleBattleMapMediator:UpdateUI()
    self:UpdateQusetTypeModule()
    self:UpdateTopUI()
    self:UpdateBottomUI()
end
--==============================--
---@Description: 检测当前类型的关卡是否解锁
---@author : xingweihao
---@date : 2019/3/12 2:04 PM
--==============================--
function CastleBattleMapMediator:CheckCurrentQuestTypeUnLock()
    local homeData = self:GetHomeData()
    local  passQuests = homeData.passQuests or {}
    local questConfig = CommonUtils.GetConfigAllMess(SpringActivityConfigParser.TYPE.QUEST , 'springActivity')
    for index  , questId  in pairs(passQuests) do
        local questData = questConfig[tostring(questId)]
        if questData then
            local questType  = questData.type
            self.unLockTable[tostring(questType)] = true
        end
    end
end
--==============================--
---@Description: 获取到特殊关卡id
---@author : xingweihao
---@date : 2018/10/16 11:37 AM
--==============================--
function CastleBattleMapMediator:GetSpecialQuestId()
    local questTypeConfig = CommonUtils.GetConfigAllMess(SpringActivityConfigParser.TYPE.QUEST_TYPE, 'springActivity')
    local questConfig = CommonUtils.GetConfigAllMess(SpringActivityConfigParser.TYPE.QUEST, 'springActivity')
    local questId = 0 
    local questType = 0 
    for aQuestType, questTypeData in pairs(questTypeConfig) do
        if checkint(questTypeData.skipQuest ) == 2 then 
            questType = checkint(aQuestType ) 
            break 
        end      
    end
    for aQuestId, questData in pairs(questConfig) do
        if checkint(questData.type  ) == questType  then 
            questId = aQuestId 
            break 
        end      
    end
    return questId 
end

--==============================--
---@Description: 新增通关关卡 插入 
---@author : xingweihao
---@date : 2019/3/12 2:04 PM
--==============================--
function CastleBattleMapMediator:InsertPassQuest()
    local homeData = self:GetHomeData() or {}
    local specialHighestHurt = checkint(homeData.specialHighestHurt) 
    local passQuests = homeData.passQuests or {}
    if specialHighestHurt > 0  then
        local questId =  self:GetSpecialQuestId()
        passQuests[#passQuests+1] = questId 
    end 
end     
--==============================--
---@Description: 播放剧情动画事件
---@author : xingweihao
---@date : 2019/3/12 2:04 PM
--==============================--
function CastleBattleMapMediator:PlayStoryPlot()
    local questTypeConfig = CommonUtils.GetConfigAllMess(SpringActivityConfigParser.TYPE.QUEST_TYPE, 'springActivity')
    local qusetTypeStroyTable =  {} 
    for questType, questData in pairs(questTypeConfig) do
        local isFirstOpen =self:GetStoryIdIsUnlock(questData.storyId2)
        if isFirstOpen then
            qusetTypeStroyTable[tostring(questType)] =  tostring(questData.storyId2)
        end     
    end
    local homeData = self:GetHomeData()
    local passQuests = homeData.passQuests
    local questConfig = CommonUtils.GetConfigAllMess(SpringActivityConfigParser.TYPE.QUEST, 'springActivity')
    local passQuestNumTable = {  ['1']=0,   ['2'] = 0,   ['3']= 0,  ['4']=0  }
    for index, questId in pairs(passQuests) do
        local questData = questConfig[tostring(questId)] or {} 
        local questType = questData.type or 1
        passQuestNumTable[tostring(questType)] = passQuestNumTable[tostring(questType)] +1
    end
    for i =1,  table.nums(questTypeConfig) do
        local  questType =  tostring(i)
        if passQuestNumTable[questType] >= 1 and
        (not  qusetTypeStroyTable[questType]) then
            local questTypeOneConfig = questTypeConfig[tostring(questType)]  or {}
            local storyId2 = questTypeOneConfig.storyId2 or "1"
            local storyStage = require('Frame.Opera.OperaStage').new({id = storyId2, path = string.format("conf/%s/springActivity/story.json",i18n.getLang()), guide = true, cb = function(sender)
                -- play bg music
                PlayBGMusic(AUDIOS.WYS.FOOD_WYS_GUILINGGAO_SAD.id)

                self:SendSignal(POST.SPRING_ACTIVITY_UNLOCK_STORY.cmdName , {
                    storyId = storyId2 
                })
            end})
            storyStage:setPosition(display.center)
            sceneWorld:addChild(storyStage, GameSceneTag.Dialog_GameSceneTag)
            break 
        end     
    end     
end
---==============================--
---@Description:获取古堡活动的活动说明
---@author : xingweihao
---@date : 2019/3/1 5:59 PM
--==============================--
function CastleBattleMapMediator:TipModuleExplain()
    app.uiMgr:ShowIntroPopup({moduleId = -28})
end
--==============================--
---@Description:更新战斗地图关卡模块
---@author : xingweihao
---@date : 2019/3/6 10:47 AM
--==============================--
function CastleBattleMapMediator:UpdateQusetTypeModule()
    ---@type CastleBattleMapView
    local viewComponent = self:GetViewComponent()
    local isUnlockTable  = {
        ["1"] = true ,
        ["2"] = false ,
        ["3"] = false ,
        ["4"] = false
    }
    for questType, isUnlock in pairs(self.unLockTable) do
        if isUnlock  then
            isUnlockTable[tostring(questType)] = isUnlock
            if questType + 1 <= 4  then
                isUnlockTable[tostring(questType+1)] = isUnlock
            end
        end
    end
    viewComponent:UpdateQusetTypeModule(isUnlockTable)
end
--==============================--
---@Description:更新顶部道具显示
---@author : xingweihao
---@date : 2019/3/6 10:47 AM
--==============================--
function CastleBattleMapMediator:UpdateTopUI()
    ---@type CastleBattleMapView
    local viewComponent = self:GetViewComponent()
    viewComponent:UpdateTopUI()
end
--==============================--
---@Description:更新底部道具显示
---@author : xingweihao
---@date : 2019/3/6 10:47 AM
--==============================--
function CastleBattleMapMediator:UpdateBottomUI()
    ---@type CastleBattleMapView
    local viewComponent = self:GetViewComponent()
    viewComponent:UpdateBottomUI()
end
-- 模块的点击事件
function CastleBattleMapMediator:ModuleClick(sender)
    local tag = sender:getTag()
    local isUnlock = self.unLockTable[tostring(tag)]
    local callfunc = function()
        local mediator = require("Game.mediator.castle.CastleTeamReadyBattleMediator").new({questType = tag , homeData = self:GetHomeData() })
        app:RegistMediator(mediator)
    end
    -- 解锁了 直接跳转
    if isUnlock  then
        callfunc()
    else
        -- 没有解锁 
        if tag == 1 then
            isUnlock = true
        else
            isUnlock =  self.unLockTable[tostring(tag-1)]
        end
        if isUnlock then -- 如果 isUnlock 为true 可以直接打关卡
            local  questTypeData = CommonUtils.GetConfigAllMess(SpringActivityConfigParser.TYPE.QUEST_TYPE, 'springActivity')[tostring(tag)] or {}
            local storyId1 = tostring(questTypeData.storyId1)
            local isFirstOpen =  self:GetStoryIdIsUnlock(storyId1)
            if not isFirstOpen then
                local storyStage = require('Frame.Opera.OperaStage').new({id = storyId1, path = string.format("conf/%s/springActivity/story.json",i18n.getLang()), guide = true, cb = function(sender)
                    -- play bg music
                    PlayBGMusic(AUDIOS.WYS.FOOD_WYS_GUILINGGAO_SAD.id)

                    self:SendSignal(POST.SPRING_ACTIVITY_UNLOCK_STORY.cmdName , {
                        storyId = storyId1
                    })
                    callfunc()
                end})
                storyStage:setPosition(display.center)
                sceneWorld:addChild(storyStage, GameSceneTag.Dialog_GameSceneTag)
            else
                callfunc()
            end
        else
            local  questTypeData = CommonUtils.GetConfigAllMess(SpringActivityConfigParser.TYPE.QUEST_TYPE, 'springActivity')[tostring(tag-1)] or {}
            local name  = questTypeData.name or ""
            app.uiMgr:ShowInformationTips(string.fmt(app.activityMgr:GetCastleText(__('请先通关 _name_ 关卡')) ,{ _name_ = name }))
            return
        end
    end

end
---==============================--
---@Description: TODO
---@param storyId number 故事的storyId
---@author : xingweihao
---@date : 2019/3/20 2:18 PM
--==============================--

function CastleBattleMapMediator:GetStoryIdIsUnlock(storyId)
    storyId = checkint(storyId)
    local isUnlock = false
    local  story = self:GetHomeData().story or {}
    for i, v in ipairs(story) do
        if storyId == checkint(v)  then
            isUnlock = true
            break
        end
    end
    return isUnlock
end
function CastleBattleMapMediator:BackCastMain()
    local viewData = self:GetViewComponent().viewData
    viewData.backBtn:setEnabled(false)
    local router =  app:RetrieveMediator("Router")
    router:Dispatch({name  = "castle.CastleBattleMapMediator"} , {name ="castle.CastleMainMediator"})
end
function CastleBattleMapMediator:EnterLayer()
    -- 如果homeData 数据元素为空 就需要重新请求
    if table.nums(self:GetHomeData()) > 0  then
        self:InsertPassQuest()
        self:CheckCurrentQuestTypeUnLock()
        self:UpdateUI()
        self:PlayStoryPlot()
    else 
        self:SendSignal(POST.SPRING_ACTIVITY_BATTLE_HOME.cmdName, {} )
    end
end
function CastleBattleMapMediator:OnRegist()
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
    -- play bg music
    PlayBGMusic(AUDIOS.WYS.FOOD_WYS_GUILINGGAO_SAD.id)

    regPost(POST.SPRING_ACTIVITY_BATTLE_HOME)
    regPost(POST.SPRING_ACTIVITY_UNLOCK_STORY)
    regPost(POST.SPRING_ACTIVITY_SWEEP)
    self:EnterLayer()
end
function CastleBattleMapMediator:OnUnRegist()
    unregPost(POST.SPRING_ACTIVITY_BATTLE_HOME)
    unregPost(POST.SPRING_ACTIVITY_UNLOCK_STORY)
    unregPost(POST.SPRING_ACTIVITY_SWEEP)
    local viewComponent = self:GetViewComponent()
    if viewComponent and (not tolua.isnull(viewComponent)) then
        viewComponent:runAction(cc.RemoveSelf:create())
    end
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightShow")
    self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")
end

return CastleBattleMapMediator
