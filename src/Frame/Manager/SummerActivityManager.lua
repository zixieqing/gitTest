
--[[
夏活管理模块
--]]
local ManagerBase = require( "Frame.Manager.ManagerBase" )
---@class SummerActivityManager
local SummerActivityManager = class('SummerActivityManager',ManagerBase)

SummerActivityManager.instances = {}
SummerActivityManager.CHAPTER_FLAG = {
    MAZE           = '1',  -- 镜子迷宫
    EACUP          = '2',  -- 旋转茶杯
    ROLLER_COASTER = '3',  -- 洞穴云霄飞车
    HAUNTED_HOUSE  = '4',  -- 鬼屋
    FINALLY_BOSS   = '5',  -- 最终BOSS
}
SummerActivityManager.STORY_FLAG = {
    SA_ICON                                  = '1',  -- 第一次点击夏活icon
    SA_MAP_ICON                              = '2',  -- 第一次点击夏活地图icon
    SA_CHAPTER_MAZE_ICON                     = '3',  -- 第一次点击镜子迷宫（副本点1）icon
    SA_CHAPTER_MAZE_ENCOUNTER_BOSS           = '4',  -- 第一次在镜子迷宫（副本点1）内遭遇大怪
    SA_CHAPTER_MAZE_OVERCOME_BOSS            = '5',  -- 第一次在镜子迷宫（副本点1）内战胜了大怪
    SA_CHAPTER_TEACUP_ICON                   = '6',  -- 第一次点击旋转茶杯（副本点2）icon
    SA_CHAPTER_TEACUP_ENCOUNTER_BOSS         = '7',  -- 第一次在旋转茶杯（副本点2）内遭遇大怪
    SA_CHAPTER_TEACUP_OVERCOME_BOSS          = '8',  -- 第一次在旋转茶杯（副本点2）内战胜了大怪
    SA_CHAPTER_ROLLER_COASTER_ICON           = '9',  -- 第一次点击洞穴云霄飞车（副本点3）icon
    SA_CHAPTER_ROLLER_COASTER_ENCOUNTER_BOSS = '10', -- 第一次在洞穴云霄飞车（副本点3）内遭遇大怪
    SA_CHAPTER_ROLLER_COASTER_OVERCOME_BOSS  = '11', -- 第一次在洞穴云霄飞车（副本点3）内战胜了大怪
    SA_CHAPTER_HAUNTED_HOUSE_ICON            = '12', -- 第一次点击鬼屋（副本点4）icon
    SA_CHAPTER_HAUNTED_HOUSE_ENCOUNTER_BOSS  = '13', -- 第一次在鬼屋（副本点4）内遭遇大怪
    SA_CHAPTER_HAUNTED_HOUSE_OVERCOME_BOSS   = '14', -- 第一次在鬼屋（副本点4）内战胜了大怪
    SA_CHAPTER_FINALLY_BOSS_ICON             = '15', -- 第一次点击最终BOSS的icon
    SA_CHAPTER_FINALLY_BOSS_OVERCOME_BOSS    = '16', -- 第一次战胜了最终BOSS
}

local CARNIE_THEME_TYPE = {
    SUMMER_ACT_18    = '1',    -- 18夏活
    SPRING_ACT_19    = '2',    -- 19春活
    SPRING_ACT_20    = '3',    -- 20春节活动
    SCHOOL_ACT_20    = '4',    -- 20开学活动
    SPRING_ACT_21    = '5',    -- 21春活活动
    JAPAN_ACT_21     = '6',    -- 21日本活动
}

local THEME_SKIN_DEFINES = {
    [CARNIE_THEME_TYPE.SUMMER_ACT_18] = 'one',   -- 18夏活
    [CARNIE_THEME_TYPE.SPRING_ACT_19] = 'two',   -- 19春活
    [CARNIE_THEME_TYPE.SPRING_ACT_20] = 'three', -- 20春节活动
    [CARNIE_THEME_TYPE.SCHOOL_ACT_20] = 'four',  -- 20开学活动
    [CARNIE_THEME_TYPE.SPRING_ACT_21] = 'five',  -- 21春活活动
    [CARNIE_THEME_TYPE.JAPAN_ACT_21]  = 'six',   -- 21日本活动
}


---------------------------------------------------
-- mediator extend begin --
---------------------------------------------------
function SummerActivityManager:ctor( key )
    self.super.ctor(self)
    if SummerActivityManager.instances[key] ~= nil then
        funLog(Logger.INFO,"注册相关的facade类型" )
        return
    end
    self.stoneData = nil
    self.parseConfig = nil
    self.battleSuccessFlags  = {}      -- 存储 战斗成功的章节Id
    self.chapterNodeDatas    = {}      -- 存储 章节节点数据

    SummerActivityManager.instances[key] = self
end

function SummerActivityManager.GetInstance(key)
    key = (key or "SummerActivityManager")
    if SummerActivityManager.instances[key] == nil then
        SummerActivityManager.instances[key] = SummerActivityManager.new(key)
    end
    return SummerActivityManager.instances[key]
end


function SummerActivityManager.Destroy( key )
    key = (key or "SummerActivityManager")
    if SummerActivityManager.instances[key] == nil then
        return
    end
    --清除配表数据
    SummerActivityManager.instances[key] = nil
end
---------------------------------------------------
-- mediator extend end --
---------------------------------------------------

function SummerActivityManager:GetChangeSkinData()
    -- if GAME_MOUDLE_EXCHANGE_SKIN.SUMMER_ACT then
    if THEME_SKIN_DEFINES[self:getCurCarnieTheme()] then
        if not  self.changeSkinTable then
            self.changeSkinTable = require("changeSkin.summerAct." .. THEME_SKIN_DEFINES[self:getCurCarnieTheme()])
        end
        return self.changeSkinTable
    else
        if not  self.changeSkinTable then
            self.changeSkinTable = require("changeSkin.summerAct." .. THEME_SKIN_DEFINES[CARNIE_THEME_TYPE.SUMMER_ACT_18])
        end
        return self.changeSkinTable
    end
    return nil
end

---------------------------------------------------
-- utils begin --
---------------------------------------------------

function SummerActivityManager:InitHomeData(data)
    
end

function SummerActivityManager:InitCarnieTheme()
    if self.curCarnieTheme ~= nil then return end
    
    local paramsConf = self:GetCurParameter()
    local theme = paramsConf.id and tostring(paramsConf.id) or CARNIE_THEME_TYPE.SUMMER_ACT_18
    self.curCarnieTheme = tostring(theme)
    self.changeSkinTable = nil
end

function SummerActivityManager:InitChapterData(chapter)
    chapter = chapter or {}
    local chapterDatas = {}
    local maxRemainUnlockTime = 0

    local nextChapterId = SummerActivityManager.CHAPTER_FLAG.FINALLY_BOSS
    local minRemainUnlockTime = checkint(checktable(chapter[tostring(nextChapterId)]).remainUnlockTime)
    for chapterId, chapterData in pairs(chapter) do
        local remainUnlockTime = checkint(chapterData.remainUnlockTime)
        maxRemainUnlockTime = math.max(maxRemainUnlockTime, remainUnlockTime)

        local isPassed = checkint(chapterData.isPassed) > 0

        chapterDatas[chapterId] = {
            chapterId = chapterId,
            isPassed = isPassed,
            remainUnlockTime = remainUnlockTime,
            chapterConf = self:GetSummerChapterByChapterId(chapterId)
        }

        if chapterId ~= SummerActivityManager.CHAPTER_FLAG.MAZE and remainUnlockTime > 0 then
            minRemainUnlockTime = math.min(minRemainUnlockTime, remainUnlockTime)
            if minRemainUnlockTime ==  remainUnlockTime then
                nextChapterId = chapterId
            end
        end
    end

    return chapterDatas, maxRemainUnlockTime, nextChapterId
end

function SummerActivityManager:InitChapterHomeData(datas)

    local requestData = datas.requestData
    local chapterId = requestData.chapterId
    local nodeGroup = datas.nodeGroup
    
    local nodeDatas = datas.node or {}
    local curNodeId = nil
    local tempId = nil
    for nodeId, nodeData in pairs(nodeDatas) do
        local type = checkint(nodeData.type)
        
        tempId = nodeData.questId or nodeData.storyId
        if tempId then
            local monsterId, name = self:GetNodeMonsterIdByType(type, tempId, chapterId)
            nodeData.monsterId = monsterId
            nodeData.name = name
            tempId = nil
        else
            nodeData.name = __('未知')
        end
        
        local status = nodeData.status
        if status == 1 then
            curNodeId = nodeId
        end
    end

    local chapterHomeDatas = {
        node = nodeDatas,
        chapterId = chapterId,
        nodeGroup = nodeGroup,
        curNodeId = curNodeId
    }

    return chapterHomeDatas
end

function SummerActivityManager:GetMainStory()
    return self.mainStory or {}
end
function SummerActivityManager:SetMainStory(mainStory)
    self.mainStory = mainStory or {}
end
function SummerActivityManager:AddMainStoryId(storyId)
    self:GetMainStory()[tostring(storyId)] = storyId
end
function SummerActivityManager:CheckMainStoryIsUnlock(storyId)
    return self:GetMainStory()[tostring(storyId)]
end

function SummerActivityManager:GetBranchStory()
    return self.branchStory or {}
end
function SummerActivityManager:SetBranchStory(branchStory)
    self.branchStory = branchStory or {}
end
function SummerActivityManager:AddBranchStoryId(chapterId, storyId)
    local chapterDatas = self:GetBranchStory()[tostring(chapterId)] or {}
    chapterDatas[tostring(storyId)] = storyId
end
function SummerActivityManager:CheckBranchStoryIsUnlock(chapterId, storyId)
    local chapterDatas = self:GetBranchStory()[tostring(chapterId)] or {}
    return chapterDatas[tostring(storyId)]
end

function SummerActivityManager:GetNodeMonsterIdByType(type, id, chapterId)
    if id == nil then return end
    local monsterId = 0
    local name = ''
    -- 如果该节点是剧情
    if type == 1 then
        local storyConfDatas = self:GetConfigDataByName(self:GetConfigParse().TYPE.BRANCH_STORY_COLLECTION) or {}
        local storyDatas = storyConfDatas[tostring(chapterId)] or {}
        for k, v in pairs(storyDatas) do
            if checkint(v.storyId) == id then
                monsterId = v.icon
                name = v.name
                break
            end
        end
    elseif type == 2 or type == 3 then
        local storyData = self:GetQuestDataById(id)
        monsterId = storyData.icon
        name = storyData.name
    end
    return monsterId, name
end

--==============================--
--desc: 获得当前点数排行数据
--@return pointRankDatas table 当前点数排行数据
--==============================--
function SummerActivityManager:GetCurPointRankDataByRank(mySummerPointRank)
    mySummerPointRank = checkint(mySummerPointRank)
    if mySummerPointRank == 0 then
        return {}
    end
    local pointRankConfDatas = self:GetConfigDataByName(self:GetConfigParse().TYPE.SUMMER_POINT_RANK_REWARDS) or {}

    for k, pointRankConfData in pairs(pointRankConfDatas) do
        local upperLimit = checkint(pointRankConfData.upperLimit)
        local lowerLimit = checkint(pointRankConfData.lowerLimit)
        if upperLimit <= mySummerPointRank and lowerLimit >= mySummerPointRank then
            return pointRankConfData
        end
    end
    return {}
end

function SummerActivityManager:GetPlayRewardDatasByQuestTimes(questTimes, questOverHasDraw)
    local rewardConf = CommonUtils.GetConfig('summerActivity', 'questOverTimesRewards', 1) or {}
    local datas = {
        questTimes = checkint(questTimes),
        targetTimes = checkint(rewardConf.times),
        questOverHasDraw = checkint(questOverHasDraw)
    }
    return datas
end

function SummerActivityManager:GetNewPlayRewardDatasByQuestTimes(questTimes, questTimesDrawn)
    local questTimesDrawnMap = {}
    for index, value in ipairs(questTimesDrawn) do
        questTimesDrawnMap[tostring(value)] = value
    end

    local confDatas = self:GetConfigDataByName(self:GetConfigParse().TYPE.QUEST_REWARDS) or {}
    
    local datas = {
        overRewardDatas = {},
        ordinaryDatas   = {}
    }

    -- get max key
    local maxRewardKey
    for key, value in pairs(confDatas) do
        if maxRewardKey == nil then
            maxRewardKey = checkint(key)
        else
            maxRewardKey = math.max(checkint(key), maxRewardKey)
        end
    end

    -- init data
    local tempData
    for key, conf in orderedPairs(confDatas) do
        local times = checkint(conf.times)
        local state = 1
        if questTimes >= times then
            if questTimesDrawnMap[tostring(times)] then
                state = 3
            else
                state = 2
            end
        end
        tempData = {conf = conf, state = state, times = times}
        if checkint(key) == maxRewardKey then
            datas.overRewardDatas = tempData
        else
            table.insert(datas.ordinaryDatas, tempData)
        end

    end
    
    return datas
end

--==============================--
--desc: 获得点数排行数据
--@return pointRankDatas table 点数排行数据
--==============================--
function SummerActivityManager:GetPointRankDataByRank(mySummerPointRank, summerPointRank)
    mySummerPointRank = checkint(mySummerPointRank)
    local pointRankConfDatas = self:GetConfigDataByName(self:GetConfigParse().TYPE.SUMMER_POINT_RANK_REWARDS) or {}
    local poineRankDatas = {}

    for k, pointRankConfData in pairs(pointRankConfDatas) do
        local upperLimit = checkint(pointRankConfData.upperLimit)
        local lowerLimit = checkint(pointRankConfData.lowerLimit)

        local lowerLimitRankLv = nil
        local lowerLimitValue = nil
        for rankLv, v in pairs(summerPointRank) do
            if checkint(rankLv) >= upperLimit and checkint(rankLv) <= lowerLimit then
                lowerLimitValue = v
                lowerLimitRankLv = checkint(rankLv) 
            end
        end
        table.insert(poineRankDatas, {
            pointRankConfData = pointRankConfData,
            isCurRank         = upperLimit <= mySummerPointRank and lowerLimit >= mySummerPointRank,
            lowerLimit        = lowerLimit,
            upperLimit        = upperLimit,
            lowerLimitValue   = lowerLimitValue,
            lowerLimitRankLv  = lowerLimitRankLv,
        })
    end

    table.sort(poineRankDatas, function (a, b)
        if a == nil then return true end
        if b == nil then return false end
        local aUpperLimit = checkint(a.upperLimit)
        local bUpperLimit = checkint(b.upperLimit)
        return aUpperLimit < bUpperLimit
    end)

    poineRankDatas[#poineRankDatas].isMinStage = true

    return poineRankDatas
end

--==============================--
--desc: 获得伤害排行数据
--@return damageRankDatas table 伤害排行数据
--==============================--
function SummerActivityManager:GetDamageRankRewardData()
    local damageRankRewardDatas = self:GetConfigDataByName(self:GetConfigParse().TYPE.DAMAGE_RANK_REWARDS) or {}
    if next(damageRankRewardDatas) == nil then return {} end

    local additionalDatas = {}
    local chapterIds = {}
    for chapterId, damageRankRewardData in pairs(damageRankRewardDatas) do
        table.insert(chapterIds, chapterId)
    end

    local titleConfs = {
        [SummerActivityManager.CHAPTER_FLAG.MAZE] =  self:getThemeTextByText(__('镜子迷宫第1名')),
        [SummerActivityManager.CHAPTER_FLAG.EACUP] =  self:getThemeTextByText(__('旋转茶杯第1名')),
        [SummerActivityManager.CHAPTER_FLAG.ROLLER_COASTER] = self:getThemeTextByText( __('矿道飞车第1名')),
        [SummerActivityManager.CHAPTER_FLAG.HAUNTED_HOUSE] =  self:getThemeTextByText(__('鬼屋第1名')),
        [SummerActivityManager.CHAPTER_FLAG.FINALLY_BOSS] =  self:getThemeTextByText(__('马戏团第1名')),
    }

    local descConfs = {
        [SummerActivityManager.CHAPTER_FLAG.MAZE] =  self:getThemeTextByText(__('在镜子迷宫内对小丑的单次伤害最高的玩家可以获得。')),
        [SummerActivityManager.CHAPTER_FLAG.EACUP] =  self:getThemeTextByText(__('在旋转茶杯内对小丑的单次伤害最高的玩家可以获得。')),
        [SummerActivityManager.CHAPTER_FLAG.ROLLER_COASTER] =  self:getThemeTextByText(__('在矿道飞车内对小丑的单次伤害最高的玩家可以获得。')),
        [SummerActivityManager.CHAPTER_FLAG.HAUNTED_HOUSE] =  self:getThemeTextByText(__('在鬼屋内对小丑的单次伤害最高的玩家可以获得。')),
        [SummerActivityManager.CHAPTER_FLAG.FINALLY_BOSS] =  self:getThemeTextByText(__('在马戏团内对小丑的单次伤害最高的玩家可以获得。')),
    }

    table.sort(chapterIds, function (a, b)
        if a == nil then return true end
        if b == nil then return false end
        return checkint(a) < checkint(b)
    end)

    for i, chapterId in ipairs(chapterIds) do
        local damageRankRewardData = damageRankRewardDatas[chapterId]

        table.insert(additionalDatas, {
            data = damageRankRewardData[1] or {},
            title = titleConfs[tostring(chapterId)],
            desc = descConfs[tostring(chapterId)],
        })
    end

    local damageRankRewardData = damageRankRewardDatas['1'] or {}
    local stageRewardConfs = damageRankRewardData[2] or {}
    local data = {
        stageRewardConfs = stageRewardConfs,
        additionalDatas = additionalDatas
    }
    
    return data

end

--==============================--
--desc: 获得主线剧情数据
--@return mainStoryDatas table 主线剧情数据
--==============================--
function SummerActivityManager:GetMainStoryConfDatas()
    local mainStoryConfDatas = self:GetConfigDataByName(self:GetConfigParse().TYPE.MAIN_STORY_COLLECTION) or {}
    if next(mainStoryConfDatas) == nil then return {} end

    local mainStoryDatas = {}
    for k, mainStoryConfData in orderedPairs(mainStoryConfDatas) do
        table.insert(mainStoryDatas, mainStoryConfData)
    end

    return mainStoryDatas
end

--==============================--
--desc: 获得支线剧情数据
--@return branchStoryDatas table 支线剧情数据
--==============================--
function SummerActivityManager:GetBranchStoryConfDatas()
    local branchStoryConfDatas = self:GetConfigDataByName(self:GetConfigParse().TYPE.BRANCH_STORY_COLLECTION) or {}
    
    if next(branchStoryConfDatas) == nil then return {} end

    local branchStoryDatas = {}
    for chapterId, branchStoryConfData in orderedPairs(branchStoryConfDatas) do
        table.insert(branchStoryDatas, {
            chapterId = chapterId,
            branchStoryConfData = branchStoryConfData,
        })
    end
    -- logInfo.add(5, tableToString(branchStoryDatas))
    return branchStoryDatas
end

--==============================--
--desc: 通过章节id获得章节数据
--@params id int 章节id
--@return questData table 章节数据
--==============================--
function SummerActivityManager:GetSummerChapterByChapterId(chapterId)
    local summerChapterConfDatas = self:GetConfigDataByName(self:GetConfigParse().TYPE.CHAPTER) or {}
    if next(summerChapterConfDatas) == nil then return summerChapterConfDatas end

    return summerChapterConfDatas[tostring(chapterId)] or {}

end

--==============================--
--desc: 通过关卡id获得关卡数据
--@params id int 关卡id
--@return questData table 关卡数据
--==============================--
function SummerActivityManager:GetQuestDataById(id)
    local confDatas = self:GetConfigDataByName(self:GetConfigParse().TYPE.QUEST) or {}
    return confDatas[tostring(id)] or {}
end


--==============================--
--desc: 获得二级地图节点坐标
--@params chapterId int 章节id
--@params nodeGroup int 二级地图节点组id
--@return poss table 二级地图节点坐标
--==============================--
function SummerActivityManager:GetMapNodePosByNodeGroup(chapterId, nodeGroup)
    local summerLocationConfDatas = self:GetConfigDataByName(self:GetConfigParse().TYPE.LOCATION) or {}
    return checktable(summerLocationConfDatas[tostring(chapterId)])[tostring(nodeGroup)] or {}
end

--==============================--
--desc: 获得第一次点击BOSS 剧情id 
--@params chapterId int 章节id
--@return storyId int 剧情id
--==============================--
function SummerActivityManager:GetClickChapterIconStoryByChapterId(chapterId)
    chapterId = tostring(chapterId)
    local storyId = nil
    if chapterId == SummerActivityManager.CHAPTER_FLAG.MAZE then
        storyId = SummerActivityManager.STORY_FLAG.SA_CHAPTER_MAZE_ICON
    elseif chapterId == SummerActivityManager.CHAPTER_FLAG.EACUP then
        storyId = SummerActivityManager.STORY_FLAG.SA_CHAPTER_TEACUP_ICON
    elseif chapterId == SummerActivityManager.CHAPTER_FLAG.ROLLER_COASTER then
        storyId = SummerActivityManager.STORY_FLAG.SA_CHAPTER_ROLLER_COASTER_ICON
    elseif chapterId == SummerActivityManager.CHAPTER_FLAG.HAUNTED_HOUSE then
        storyId = SummerActivityManager.STORY_FLAG.SA_CHAPTER_HAUNTED_HOUSE_ICON
    elseif chapterId == SummerActivityManager.CHAPTER_FLAG.FINALLY_BOSS then
        storyId = SummerActivityManager.STORY_FLAG.SA_CHAPTER_FINALLY_BOSS_ICON
    end
    return storyId
end

--==============================--
--desc: 获得第一次遭遇BOSS 剧情id 
--@params chapterId int 章节id
--@return storyId int 剧情id
--==============================--
function SummerActivityManager:GetEncounterChapterIconStoryByChapterId(chapterId)
    chapterId = tostring(chapterId)
    local storyId = nil
    if chapterId == SummerActivityManager.CHAPTER_FLAG.MAZE then
        storyId = SummerActivityManager.STORY_FLAG.SA_CHAPTER_MAZE_ENCOUNTER_BOSS
    elseif chapterId == SummerActivityManager.CHAPTER_FLAG.EACUP then
        storyId = SummerActivityManager.STORY_FLAG.SA_CHAPTER_TEACUP_ENCOUNTER_BOSS
    elseif chapterId == SummerActivityManager.CHAPTER_FLAG.ROLLER_COASTER then
        storyId = SummerActivityManager.STORY_FLAG.SA_CHAPTER_ROLLER_COASTER_ENCOUNTER_BOSS
    elseif chapterId == SummerActivityManager.CHAPTER_FLAG.HAUNTED_HOUSE then
        storyId = SummerActivityManager.STORY_FLAG.SA_CHAPTER_HAUNTED_HOUSE_ENCOUNTER_BOSS
    end
    return storyId
end

--==============================--
--desc: 获得第一次通关BOSS 剧情id 
--@params chapterId int 章节id
--@return storyId int 剧情id
--==============================--
function SummerActivityManager:GetOvercomeChapterIconStoryByChapterId(chapterId)
    chapterId = tostring(chapterId)
    local storyId = nil
    if chapterId == SummerActivityManager.CHAPTER_FLAG.MAZE then
        storyId = SummerActivityManager.STORY_FLAG.SA_CHAPTER_MAZE_OVERCOME_BOSS
    elseif chapterId == SummerActivityManager.CHAPTER_FLAG.EACUP then
        storyId = SummerActivityManager.STORY_FLAG.SA_CHAPTER_TEACUP_OVERCOME_BOSS
    elseif chapterId == SummerActivityManager.CHAPTER_FLAG.ROLLER_COASTER then
        storyId = SummerActivityManager.STORY_FLAG.SA_CHAPTER_ROLLER_COASTER_OVERCOME_BOSS
    elseif chapterId == SummerActivityManager.CHAPTER_FLAG.HAUNTED_HOUSE then
        storyId = SummerActivityManager.STORY_FLAG.SA_CHAPTER_HAUNTED_HOUSE_OVERCOME_BOSS
    elseif chapterId == SummerActivityManager.CHAPTER_FLAG.FINALLY_BOSS then
        storyId = SummerActivityManager.STORY_FLAG.SA_CHAPTER_FINALLY_BOSS_OVERCOME_BOSS
    end
    return storyId
end

--==============================--
--desc: 获得推荐卡牌
--@params additions table 附加卡牌数据
--@return recommendCards table 推荐卡牌
--==============================--
function SummerActivityManager:GetRecommendCardsByAdditions(additions)
    local activeCards = {}
    for i, v in pairs(additions) do
        local tempActiveCards = v.activeCards or {}
        for i, cardId in ipairs(tempActiveCards) do
            activeCards[tostring(cardId)] = cardId
        end
    end

    return table.values(activeCards) or {}
end

--==============================--
--desc: 停止夏活章节倒计时
--==============================--
function SummerActivityManager:StopSummerActivityCountdown()
    if app.timerMgr:RetriveTimer('COUNT_DOWN_TAG_SUMMER_ACTIVITY') then
        app.timerMgr:RemoveTimer('COUNT_DOWN_TAG_SUMMER_ACTIVITY')
    end
end
--==============================--
--desc: 开启夏活章节倒计时
--@params seconds int 剩余时间
--==============================--
function SummerActivityManager:StartSummerActivityCountdown(seconds)
    self:StopSummerActivityCountdown()

    if checkint(seconds) > 0 then
        local countTime = checkint(seconds) + 2
        app.timerMgr:AddTimer({name = 'COUNT_DOWN_TAG_SUMMER_ACTIVITY', countdown = countTime})
    end
end

--==============================--
--desc: 检查是否能打开章节
--@params chapterDatas 章节数据
--@params chapterId    章节id
--@return isOpenChapater bool 是否能开启章节 , errTip string  错误提示
--==============================--
function SummerActivityManager:CheckIsOpenChapter(chapterDatas, chapterId)
    chapterDatas = chapterDatas or {}
    if tostring(chapterId) == SummerActivityManager.CHAPTER_FLAG.MAZE then return true end

    -- 开启条件
    -- 上一章节通关 并且点击章节倒计时为0
    local preChapterId = tostring(checkint(chapterId) - 1)
    local preChapterData = chapterDatas[preChapterId] or {}
    local isPassedPreChapter = preChapterData.isPassed
    
    local chapterData = chapterDatas[tostring(chapterId)] or {}
    local remainUnlockTime = checkint(chapterData.remainUnlockTime)
    local isSatisfyTime = checkint(remainUnlockTime) <= 0

    local errTip = nil
    if isPassedPreChapter == false then
        errTip = __('请通关前置章节')
    elseif isSatisfyTime == false then
        errTip = __('还没有到开放时间哦~')
    end

    return isPassedPreChapter and isSatisfyTime, errTip
end

--==============================--
--desc: 显示剧情
--@params id    剧情id
--@params cb    剧情结束回调
--@params bgMusicType    剧情结束回调
--@return
--==============================--
function SummerActivityManager:ShowOperaStage(id, cb, bgMusicType)
    local path = string.format("conf/%s/summerActivity/summerStory.json",i18n.getLang())
    local stage = require( "Frame.Opera.OperaStage" ).new({id = id, path = path, guide = false, isHideBackBtn = true, cb = function (tag)
        if cb then cb() end
    end})
    stage:setPosition(cc.p(display.cx,display.cy))
    sceneWorld:addChild(stage, GameSceneTag.Dialog_GameSceneTag)
end

--==============================--
--desc: 显示主线剧情
--@params storyId    剧情id
--@params cb         剧情结束回调
--@params unlockCb   解锁回调
--@return
--==============================--
function SummerActivityManager:ShowMainStory(storyId, cb, unlockCb, bgMusicType)
    if self:CheckMainStoryIsUnlock(storyId) == nil then
        if unlockCb then
            unlockCb()
        end
        self:ShowOperaStage(storyId, cb, bgMusicType)
    else
        if cb then
            cb()
        end
    end 
end

--==============================--
--desc: 获得战斗成功标识
--@params chapterId     章节id
--@return successFlag   成功标识(二级地图坐标组id))
--==============================--
function SummerActivityManager:GetBattleSuccessFlagByChapterId(chapterId)
    return self.battleSuccessFlags[tostring(chapterId)]
end
--==============================--
--desc: 设置战斗成功标识
--@params chapterId     章节id
--@params successFlag   成功标识(二级地图坐标组id))
--@return
--==============================--
function SummerActivityManager:SetBattleSuccessFlag(chapterId, successFlag)
    self.battleSuccessFlags[tostring(chapterId)] = successFlag
end

--==============================--
--desc: 设置通关BOSS剧情ID
--@params overcomeStoryId     通关BOSS剧情ID
--@return
--==============================--
function SummerActivityManager:GetOvercomeStoryId(overcomeStoryId)
    return self.overcomeStoryId
end
--==============================--
--desc: 设置通关BOSS剧情ID
--@params overcomeStoryId     通关BOSS剧情ID
--@return
--==============================--
function SummerActivityManager:SetOvercomeStoryId(overcomeStoryId)
    self.overcomeStoryId = overcomeStoryId
end

--==============================--
--desc: 获得章节节点数据
--@return nodeDatas   章节节点数据
--==============================--
function SummerActivityManager:GetChapterNodeData(chapterId)
    return self.chapterNodeDatas[tostring(chapterId)]
end
--==============================--
--desc: 保存章节数据
--@params chapterId   章节id
--@params nodeDatas   章节节点数据
--@return
--==============================--
function SummerActivityManager:SetChapterNodeData(chapterId, nodeDatas)
    self.chapterNodeDatas[tostring(chapterId)] = nodeDatas
end

--==============================--
--desc: 保存界面返回数据
--@params chapterId   章节id
--@params nodeDatas   章节节点数据
--@return
--==============================--
function SummerActivityManager:SetBackData(fromMediator, activityId)
    self.backData = {}
    if fromMediator then
        self.backData.fromMediator = fromMediator
    end
    self.backData.activityId = activityId
end
function SummerActivityManager:GetBackData()
    return self.backData
end

--==============================--
--desc: 显示返回HomeUI

--@return
--==============================--
function SummerActivityManager:ShowBackToHomeUI()
    local isCanBack = app.gameMgr:GetUserInfo().summerActivity <= 0
    if isCanBack then
        local commonTip  = require( 'common.NewCommonTip' ).new({
            text =__('活动已过期, 点击确定返回主界面'), isForced = true,
            isOnlyOK = true, callback = function ()
                AppFacade.GetInstance():BackMediator()
        end})
        commonTip:setPosition(display.center)
        sceneWorld:addChild(commonTip, GameSceneTag.Dialog_GameSceneTag)
    end

    return isCanBack
end

--==============================--
--desc: 显示夏活HomeUI

--@return
--==============================--
function SummerActivityManager:ShowSAHomeUI()
    self:InitCarnieTheme()
    local callback = function ()
        if app.gameMgr:GetUserInfo().summerActivity > 0 then
            app.router:Dispatch({name = 'HomeMediator'}, {name = 'summerActivity.SummerActivityHomeMediator', params = {fromMediator = 'HomeMediator'}})
		else
			app.uiMgr:ShowInformationTips(__('活动已过期'))
		end
	end
	local storyTag = checkint(CommonUtils.getLocalDatas(self:getCarnieThemeActivityStoryFlagByChapterId('1')))
	if storyTag > 0 then
		callback()
	else
		CommonUtils.setLocalDatas(1, self:getCarnieThemeActivityStoryFlagByChapterId('1'))
		local path = string.format("conf/%s/summerActivity/summerStory.json",i18n.getLang())
		local stage = require( "Frame.Opera.OperaStage" ).new({id = 1, path = path, guide = true, isHideBackBtn = true, cb = callback})
		stage:setPosition(cc.p(display.cx,display.cy))
		sceneWorld:addChild(stage, GameSceneTag.Dialog_GameSceneTag)
	end
end


---------------------------------------------------
-- utils end --
---------------------------------------------------

---------------------------------------------------
-- get set begin --
---------------------------------------------------

function SummerActivityManager:GetConfigParse()
    if not self.parseConfig then
        ---@type DataManager
        self.parseConfig = app.dataMgr:GetParserByName('SummerActivity')
    end
    return self.parseConfig
end

function SummerActivityManager:GetConfigDataByName(name)
    ---@type SummerActivityConfigParser
    local parseConfig = self:GetConfigParse()
    local configData  = parseConfig:GetVoById(name)
    return configData
end

function SummerActivityManager:getThemeTextByText(text)
    local changeSkinTable = self:GetChangeSkinData() or {}
    local podTable = changeSkinTable.po
    if podTable == nil then
        return text
    end
    return podTable[text] or text
end

function SummerActivityManager:resetResPath(resDict)
    -- 无视 18 夏活
    local carnieTheme = self:getCurCarnieTheme()
    local resDict_ = clone(resDict)
    if carnieTheme == CARNIE_THEME_TYPE.SUMMER_ACT_18 then return resDict_ end

    local NEED_REP_KEY_ = self:GetChangeSkinData().keepRepKey or {}
    local baseThemePath = self:GetChangeSkinData().carnieThemeBasePath
    if baseThemePath == nil then
        logs('CARNIE_THEME_BASE_PATH 未查找到 基础路径')
        return resDict_
    end
    for key, path in pairs(resDict) do
        if NEED_REP_KEY_[key] then
            resDict_[key] = string.gsub(path, "summerActivity", baseThemePath)
            logs(resDict_[key])
        end
    end
    return resDict_
end

function SummerActivityManager:getCurCarnieTheme()
    return self.curCarnieTheme
end
function SummerActivityManager:setCurCarnieTheme(carnieTheme)
    self.curCarnieTheme  = carnieTheme
    self.changeSkinTable = nil
end

function SummerActivityManager:IsSpringAct19()
    return self:getCurCarnieTheme() == CARNIE_THEME_TYPE.SPRING_ACT_19
end

function SummerActivityManager:IsSpringAct20()
    return self:getCurCarnieTheme() == CARNIE_THEME_TYPE.SPRING_ACT_20
end

function SummerActivityManager:getCurCarnieCoin()
    local paramsConf = self:GetCurParameter()
    return paramsConf.lotteryId and checkint(paramsConf.lotteryId) or -110
end

function SummerActivityManager:getCurCarnieLampId()
    local paramsConf = self:GetCurParameter()
    return paramsConf.findBossId and checkint(paramsConf.findBossId) or -110
end

function SummerActivityManager:getFirstMapNodePostions()
    return self:GetChangeSkinData().firstMapNodePostions
end

function SummerActivityManager:getFirstMapLotteryNodePostions()
    return self:GetChangeSkinData().firstMapLotteryNodePostions
end


function SummerActivityManager:getSecondMapBgByChapterId(chapterId)
    return _res(self:GetChangeSkinData().getSecondMapBgByChapterId(chapterId))
end

function SummerActivityManager:getUnopenImg(chapterId)
    return _res(self:GetChangeSkinData().getUnopenImg(chapterId))
end

function SummerActivityManager:getTicketId()
    local paramsConf = self:GetCurParameter()
    return paramsConf.powerId and checkint(paramsConf.powerId) or -110
end

--[[
初始化活动体力
--]]
function SummerActivityManager:InitActivityHp(homeData)
    local paramsConf = self:GetCurParameter()
    local hpData = {
        hpGoodsId                = self:getTicketId(),
        hpPurchaseAvailableTimes = checkint(homeData.remainBuyTimes),
        hpMaxPurchaseTimes       = checkint(homeData.maxBuyTimes),
        hpNextRestoreTime        = checkint(homeData.actionPointNextRestoreTime),
        hpRestoreTime            = checkint(homeData.actionPointRestoreTime),
        hpUpperLimit             = checkint(homeData.actionPointMax),
        hp                       = checkint(homeData.actionPoint),
        hpPurchaseConsume        = {goodsId = DIAMOND_ID, num = 100},
        hpPurchaseTakeKey        = 'actionPoint',
        hpPurchaseCmd            = POST.SUMMER_ACTIVITY_BUY_ACTION_POINT,
        hpBuyOnceNum             = 100,
    }
    app.activityHpMgr:InitHpData(hpData)
end


function SummerActivityManager:getCarnieThemeActivityStoryFlagByChapterId(chapterId)
    return string.format('CARNIE_THEME_ACTIVITY_STORY_FLAG_%s_%s', tostring(self:getCurCarnieTheme()), tostring(chapterId))
end

function SummerActivityManager:getCarnieThemeActivityTeamFlagByQuestId(questId)
    return string.format('CARNIE_THEME_ACTIVITY_TEAM_FLAG_%s_%s', tostring(self:getCurCarnieTheme()), tostring(questId))
end

function SummerActivityManager:getFirstMapAudioConf()
    return self:GetChangeSkinData().audioConf.FIRST_MAP or {}
end
function SummerActivityManager:getSecondMapAudioConf()
    return self:GetChangeSkinData().audioConf.SECOND_MAP or {}
end

function SummerActivityManager:GetCurParameter()
    if self.paramsConf == nil then
        self.paramsConf = CommonUtils.GetConfigAllMess('param', 'summerActivity') or {}
    end
    return self.paramsConf[1] or {}
end

function SummerActivityManager:GetHideStoryId()
    local paramsConf = self:GetCurParameter()
    return checkint(paramsConf.hideStoryId)
end

function SummerActivityManager:GetHideStoryPos()
    return self:GetChangeSkinData().hideStoryPos
end

function SummerActivityManager:GetTotalStoryCount()
    if self.totalStoryCount == nil then
        local conf = CommonUtils.GetConfigAllMess('summerStory', 'summerActivity') or {}
        self.totalStoryCount = table.nums(conf)
    end
    return self.totalStoryCount
end


function SummerActivityManager:setIsClosed(isEnd)
    self.isEnd_ = checkbool(isEnd)
end
function SummerActivityManager:isClosed()
    return checkbool(self.isEnd_)
end

---------------------------------------------------
-- get set end --
---------------------------------------------------

function SummerActivityManager:ClearData()
    self.summerStory = nil
end

return SummerActivityManager
