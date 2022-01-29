--[[
堕神管理模块
--]]
---@type ChangeSkinManager
local ChangeSkinManager = require("Frame.Manager.ChangeSkinManager")
---@class AnniversaryManager
local AnniversaryManager = class('AnniversaryManager',ChangeSkinManager)
AnniversaryManager.instances = {}

-- 换皮的配置数据
AnniversaryManager.CHANGE_SKIN_CONF = {
    SKIN_MODE = GAME_MOUDLE_EXCHANGE_SKIN.ANNIVERSARY, -- 换皮的模式
    SKIN_PATH = "anniversary" , -- 换皮的路径
}

---------------------------------------------------
-- mediator extend begin --
---------------------------------------------------
local ASSISTANT_SKILL_TYPE  = {
    ONE_RECIPE_ADD_RATE = 1,
    ALL_RECIPE_ADD_RATE = 2,
    TRAFFIC_ADD         = 3, -- 客流量
    EARNINGS            = 4
}
function AnniversaryManager:ctor( key )
    self.super.ctor(self)
    self.spineCache = false
    if AnniversaryManager.instances[key] ~= nil then
        funLog(Logger.INFO,"注册相关的facade类型" )
        return
    end
    self.homeData = {}
    self.spineTable = {}
    self.parseConfig = nil
    AnniversaryManager.instances[key] = self
end
function AnniversaryManager:GetIsAddSpot()
    local changeSkinTable = self:GetChangeSkinData()
    local isAddSpotSpine = true
    if changeSkinTable.isAddSpotSpine == false  then
        isAddSpotSpine = false
    end
    return isAddSpotSpine
end
function AnniversaryManager:GetMainSpine()
    if self.CHANGE_SKIN_CONF.SKIN_MODE then
        if table.nums(self.spineTable) == 0  then
            local spine = self.changeSkinTable.spine
            for name , path in pairs(spine) do
                self.spineTable[name] = self:GetSpinePath(path).path
            end
        end
    else
        if table.nums(self.spineTable) == 0  then
            self.spineTable = {
                ANNI_FEICHUAN       = self:GetSpinePath('effects/anniversary/anni_feichuan').path,
                ANNI_MAIN_BOX       = self:GetSpinePath('effects/anniversary/anni_main_box').path,
                ANNI_MAIN_CARD      = self:GetSpinePath('effects/anniversary/anni_main_card').path,
                ANNI_MAIN_CHANGE    = self:GetSpinePath('effects/anniversary/anni_main_change').path,
                ANNI_MAIN_OPEN      = self:GetSpinePath('effects/anniversary/anni_main_open').path,
                ANNI_MAIN_WALKING   = self:GetSpinePath('effects/anniversary/anni_main_walking').path,
                ANNI_MAPS_ICON_DICE = self:GetSpinePath('effects/anniversary/anni_maps_icon_dice').path,
                ANNI_CATIN_BG       = self:GetSpinePath('effects/anniversary/anni_catin_bg').path,
                ANNI_CATIN_ZHUAN    = self:GetSpinePath('effects/anniversary/anni_catin_zhuan').path,
                ANNI_MAIN_UP        = self:GetSpinePath('effects/anniversary/anni_main_up').path,
            }
        end
    end
    
    return self.spineTable
end

function AnniversaryManager.GetInstance(key)
    key = (key or "AnniversaryManager")
    if AnniversaryManager.instances[key] == nil then
        AnniversaryManager.instances[key] = AnniversaryManager.new(key)
    end
    return AnniversaryManager.instances[key]
end

--function AnniversaryManager:GetPoText(text)
--    local changeSkinTable =  self:GetChangeSkinData()
--    local podTable = changeSkinTable.po
--    if podTable == nil then
--        return text
--    end
--    return podTable[text] or text
--end
function AnniversaryManager:AddSpineCache()
    if not  self.spineCache then
        self.spineCache = true
        local shareSpineCache = SpineCache(SpineCacheName.ANNIVERSARY)
        for spineName , spinePath in pairs(self.spineTable) do
            shareSpineCache:addCacheData(spinePath, spinePath, 1)
        end
    end
end

function AnniversaryManager:RemoveSpineCache()
    if self.spineCache then
        local shareSpineCache = SpineCache(SpineCacheName.ANNIVERSARY)
        for spineName , spinePath in pairs(self.spineTable) do
            shareSpineCache:removeCacheData(spinePath)
        end
        self.spineCache = false
    end
end
function AnniversaryManager:InitData(data)
    if not  data then
        return
    end
    self.homeData = data
    if not  self.homeData.chapterQuest  then
        self.homeData.chapterQuest = {
            gridShop = {} 
        }
    end
    if not  self.homeData.branchRefresh  then
        self.homeData.branchRefresh = {}
    end
    if not  self.homeData.chapters  then
        self.homeData.chapters = {}
    end
    if not  self.homeData.recipes  then
        self.homeData.recipes = {}
    end
    local teamData =  {
        teamCards = self.homeData.teamCards ,
        skill = self.homeData.skill
    }
   self.homeData.day =  math.ceil(( checkint(data.currentTime)   -  checkint(data.startTime))/86400)
    self:SetQusetTeamAndSkill(teamData)
end
--==============================--
---@Description: 获取到 AnniversaryManager 的配表设置
---@author : xingweihao
---@date : 2018/10/16 11:37 AM
--==============================--

function  AnniversaryManager:GetConfigDataByName(name  )
    local parseConfig = self:GetConfigParse()
    local configData  = parseConfig:GetVoById(name)
    return configData
end

---@return AnniversaryConfigParser
function AnniversaryManager:GetConfigParse()
    if not self.parseConfig then
        ---@type DataManager
        self.parseConfig = app.dataMgr:GetParserByName('anniversary')
    end
    return self.parseConfig
end
--==============================--
---@Description: 获取homeData 的数据
---@author : xingweihao
---@date : 2018/10/16 11:31 AM
--==============================--

function AnniversaryManager:GetHomeData()
    return self.homeData
end
--==============================--
---@Description: 设置菜谱的经验值
---@author : xingweihao
---@date : 2018/10/16 11:32 AM
--==============================--

function AnniversaryManager:SetRecipeIdAndExp(recipeId ,  exp )
    local  parserConfig = self:GetConfigParse()
    local recipeConfig = self:GetConfigDataByName(parserConfig.TYPE.FOOD_ATTR)
    if recipeConfig[tostring(recipeId)]  then
        local recipes = self:GetHomeData()['recipes']
        -- 如果recipes 不存在 直接设置homeData 的recipes  的key 自动补全数据
        if  not  recipes  then
            self.homeData['recipes'] = {}
        end
        self.homeData['recipes'][tostring(recipeId)] = exp
    end
end
function AnniversaryManager:GetRecipeLevelByExp(exp)
    exp = checkint(exp)
    local parserConfig = self:GetConfigParse()
    local foodLevelConfig = self:GetConfigDataByName(parserConfig.TYPE.FOOD_LEVEL)
    local countLevel =  table.nums(foodLevelConfig)
    for i = 1, countLevel do
        local foodOneConfig = foodLevelConfig[tostring(i)]
        if  checkint(foodOneConfig.exp) > exp  then
            return  i - 1
        end
    end
    return countLevel
end
--==============================--
---@Description: 获取到经验等级的上线
---@author : xingweihao
---@date : 2018/10/17 10:32 AM
--==============================--

function AnniversaryManager:GetRecipeLevelLimitExp(level)
    local parserConfig = self:GetConfigParse()
    local foodLevelConfig = self:GetConfigDataByName(parserConfig.TYPE.FOOD_LEVEL)
    local countLevel =  table.nums(foodLevelConfig)
    local nextLevel =  level >= countLevel  and countLevel  or (level +1)
    local limitExp = checkint(foodLevelConfig[tostring(nextLevel)].exp)
    return limitExp
end
--[[
　　---@Description: 设置homeData 的数据
　　---@param : key homeData 的键值 value 对应的值 isMerge 不传的时候当value 的类型为table 的时候 合并数据
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/8/8 8:53 PM
--]]
function AnniversaryManager:SetHomeDataByKeyalue(key , value , isMerge)
    -- 如果是table 表就合并数据
    isMerge = isMerge == nil  and  true or isMerge
    if type(value) == 'table' and isMerge and type(self.homeData[tostring(key)]) == 'table'   then
        table.merge(self.homeData[tostring(key)] , value)
    else
        self.homeData[tostring(key)] = value
    end
end
function AnniversaryManager:GetRecommendRecipeId()
    local parserConfig = self:GetConfigParse()
    local recipeAttr =self:GetConfigDataByName(parserConfig.TYPE.FOOD_ATTR)
    local recommendRecipeId = nil
    local days = checkint(self.homeData.day)
    for i, v in pairs(recipeAttr) do
        if  checkint(v.day) == checkint(days) then
            recommendRecipeId  = checkint(v.id)
            break
        end
    end
    return recommendRecipeId or 1
end
---@Description: 获取当前价格的成功率
---@param recipeId number @菜谱Id 、 exp 当前经验 、 
---@param value number @当前的要出售的价钱
---@param cardId number @卡牌id
---@author : xingweihao
---@date : 2018/10/15 9:43 AM
--==============================--
function AnniversaryManager:GetPriceSuccessRate(recipeId , value ,  cardId  )
    local parserConfig = self:GetConfigParse()
    local parameterConfig  =  self:GetConfigDataByName(parserConfig.TYPE.PARAMETER)
    local parameterOneConfig = parameterConfig["1"]
    local recipes = self.homeData.recipes or {}
    local exp = checkint(recipes[tostring(recipeId)])   -- 经验值
    local value = checkint(value)   -- 玩家设置的售价
    local rateParam = parameterOneConfig.rateParam
    local recommendedRecipeId = self:GetRecommendRecipeId()
    local p1 = 0
    -- TODO 图鉴料理字段添加判断
    if recommendedRecipeId == checkint(recipeId)  then
        p1 = tonumber(parameterOneConfig.successRate)
    end
    local p2 = 0
    if  checkint(cardId) > 0  then
        local cardData = app.gameMgr:GetCardDataByCardId(cardId)
        if cardData  then
            local parserConfig = self:GetConfigParse()
            local assistantConfig = self:GetConfigDataByName(parserConfig.TYPE.ASSISTANT)
            local assistantOneConfig = assistantConfig[tostring(cardData.cardId)]
            if assistantOneConfig then
                local skillId = checkint(assistantOneConfig.skillId)
                if skillId > 0  then
                    local assistantSkillConf = self:GetConfigDataByName(parserConfig.TYPE.ASSISTANT_SKILL)
                    local assistantSKillOneConfig = assistantSkillConf[tostring(skillId)] or {}
                    if checkint(assistantSKillOneConfig.type)  == ASSISTANT_SKILL_TYPE.ONE_RECIPE_ADD_RATE    then
                        if  checkint(recipeId) ==  checkint(assistantSKillOneConfig.targetId)  then
                                p2 = tonumber(assistantSKillOneConfig.targetNum) /100
                        end
                    elseif checkint(assistantSKillOneConfig.type)  == ASSISTANT_SKILL_TYPE.ALL_RECIPE_ADD_RATE    then
                        p2 = tonumber(assistantSKillOneConfig.targetNum)/100
                    end
                end
            end
        end
    end
    --[[玩家设置的售价为n，选择的菜品经验值为e，活动经营技能加成出售成功率为p1，推荐料理加成成功率为p2，
      k1k2k3k4k5为公式修正参数，读取周年庆基本参数表的成功率计算参数字段配置。
      实际销售成功率Rate =MIN(MAX(((k1+(e/k2)-(n/(k3+e/k4))^k5)+p1+p2),0),1)--]]
    local k1 = tonumber(rateParam[1])
    local k2 = tonumber(rateParam[2])
    local k3 = tonumber(rateParam[3])
    local k4 = tonumber(rateParam[4])
    local k5 = tonumber(rateParam[5])
    local reate = math.min(math.max(
            ((k1 + (exp /k2) -(value /(k3 + exp/k4) )^k5)+p1+p2 ) , 0
    ),1)
    return  math.floor(tonumber(reate) * 100)
end
--==============================--
---@Description: 根据chapterType 类型返回章节的chapterId 和chapterSort
---@author : xingweihao
---@date : 2018/10/24 3:59 PM
--==============================--

function AnniversaryManager:GetNewChapterIdAndChapterSortByType(chapterType)
    local chapters = self.homeData.chapters or {}
    local chapterId = chapters[tostring(chapterType)]
    if not  chapterId then
        local parserConfig =self:GetConfigParse()
        local chapterSortConfig =self:GetConfigDataByName(parserConfig.TYPE.CHAPTER_SORT)
        chapterId = chapterSortConfig[tostring(chapterType)]["1"]
        return chapterId ,1
    end
    local chapterSort = self:GetChapterSortByChapterIdChapterType(chapterId + 1  , chapterType)
    if chapterSort == 0  then
        chapterSort =  self:GetChapterSortByChapterIdChapterType(chapterId   , chapterType)
        return chapterId   ,chapterSort
    else
        return chapterId + 1  ,chapterSort
    end

end

function AnniversaryManager:GetAssistantSkillDescrBySkillId(skillId)
    local  tableKey  = {
        targetId =  '_target_id_',
        targetNum = '_target_num_',
    }
    local parserConfig = self:GetConfigParse()
    local assistantTypeConfig = self:GetConfigDataByName(parserConfig.TYPE.ASSISTANT_BUFF_TYPE)
    local assistantConfig = self:GetConfigDataByName(parserConfig.TYPE.ASSISTANT_SKILL)
    local assistantOneConfig = assistantConfig[tostring(skillId)] or {}
    local buffType = assistantOneConfig.type or 1
    local assistantTypeOneConfig = assistantTypeConfig[tostring(buffType)]
    local str = assistantTypeOneConfig.effect or ""
    if checkint(buffType)  ~= ASSISTANT_SKILL_TYPE.ONE_RECIPE_ADD_RATE then
        for k , v in pairs(tableKey) do
            str = string.fmt(str , { [v] =  assistantOneConfig[k] })
        end
    else
        for k , v in pairs(tableKey) do
            if k == "targetId"  then
                local foodAttrConfig  = self:GetConfigDataByName(parserConfig.TYPE.FOOD_ATTR)
                local foodOneAttrConfig = foodAttrConfig[tostring(assistantOneConfig.targetId)] or {}
                local recipeName = foodOneAttrConfig.name or ""
                str = string.fmt(str , { [v] =  recipeName })
            else
                str = string.fmt(str , { [v] =  assistantOneConfig[k] })
            end
        end
    end
    return  str
end
function AnniversaryManager:GetChapterSortByChapterIdChapterType(chapterId , chapterType)
    chapterId = checkint(chapterId)
    local parseConfig = self:GetConfigParse()
    local chapterSortConfig = self:GetConfigDataByName(parseConfig.TYPE.CHAPTER_SORT)
    local chapterOneTypeConfig = chapterSortConfig[tostring(chapterType)]
    for sortIndex, curChapterId in pairs(chapterOneTypeConfig) do
        if  checkint(curChapterId) == chapterId then
            return checkint(sortIndex)
        end
    end
    return  0
end
function AnniversaryManager:GetChpterIdByChapeterTypeChapterSort(chapterType ,chapterSort )
    local parseConfig = self:GetConfigParse()
    local chapterSortConfig = self:GetConfigDataByName(parseConfig.TYPE.CHAPTER_SORT)
    local chapterOneTypeConfig = chapterSortConfig[tostring(chapterType)]
    return  checkint(chapterOneTypeConfig[tostring(chapterSort)])
end
function AnniversaryManager:SetQusetTeamAndSkill(data)
    data = data or {}
    local teamCards = data.teamCards or ""
    local skill = data.skill or ""
    teamCards = string.split(teamCards , ",")
    skill = string.split(skill , ",")
    for i, v in pairs(teamCards) do
        if v == "" then
            teamCards[i] = nil
        end
    end
    for i, v in pairs(skill) do
        if v == "" then
            skill[i] = nil
        end
    end
    self.homeData.teamCards = teamCards
    self.homeData.skill = skill
end
--==============================--
---@Description: 根据当前时间获取到推荐的菜谱
---@author : xingweihao
---@date : 2018/10/16 5:21 PM
--==============================--

function AnniversaryManager:SetRecommendRecipeByCurrentTime(currentTime)
    local homeData = self.homeData or {}
    local startTime = tonumber(homeData.startTime)
    local distanceTime =  checkint(currentTime)  - startTime
    local day = math.ceil(distanceTime /86400)
    local parserConfig = self:GetConfigParse()
    local foodAttrConfig = self:GetConfigDataByName(parserConfig.TYPE.FOOD_ATTR)
    for recipeId, recipeData  in pairs(foodAttrConfig) do
        if checkint(recipeData.day)  == day then
            self:SetHomeDataByKeyalue("recommendedRecipeId" ,  recipeId )
        end
    end
end
--==============================--
---@Description: 根据recipeId 获取到菜谱的路径
---@author : xingweihao
---@date : 2018/10/16 7:39 PM 
--==============================--

function AnniversaryManager:GetAnniversaryRecipePathByRecipId(recipeId, isBig  )
    local path = ""
    if isBig then
        path =  self:GetResPath( string.format("ui/anniversary/recipe/big/anni_goods_icon_%d.png", checkint(recipeId) ))
        if not  utils.isExistent(path) then
            path = self:GetResPath( string.format("ui/anniversary/recipe/big/anni_goods_icon_%d.png", 1))
        end
    else
        path =  self:GetResPath( string.format("ui/anniversary/recipe/small/anni_goods_icon_%d.png", checkint(recipeId) ))
        if not  utils.isExistent(path) then
            path = self:GetResPath( string.format("ui/anniversary/recipe/small/anni_goods_icon_%d.png", 1))
        end
    end

    return path
end

--==============================--
--desc: 显示剧情
--@params id    剧情id
--@params cb    剧情结束回调
--@params bgMusicType    剧情结束回调
--@return
--==============================--
function AnniversaryManager:ShowOperaStage(id, cb, bgMusicType)
    local path = string.format("conf/%s/anniversary/anniversaryStory.json",i18n.getLang())
    local stage = require( "Frame.Opera.OperaStage" ).new({id = id, path = path, guide = false, isHideBackBtn = true, cb = function (tag)
        if cb then
            cb()
        end
        app:DispatchObservers(ANNIVERSARY_BGM_EVENT , {})
    end})
    stage:setPosition(cc.p(display.cx,display.cy))
    sceneWorld:addChild(stage, GameSceneTag.Dialog_GameSceneTag)
end

function AnniversaryManager:ConverUIPosToGamePos(pos)
    local centerPos = cc.p( 1334/2 ,  750/2 )
    local relativeX  =    centerPos.x - pos.x
    local relativeY   =   - (centerPos.y - pos.y)
    local gamePos = cc.p(0,0)
    gamePos.x  =   display.center.x - relativeX
    gamePos.y = display.center.y -  relativeY
    return  gamePos
end
--==============================--
---@Description: 获取到暂未选择过的支线类型
---@author : xingweihao
---@date : 2018/10/24 3:41 PM
--==============================--

function AnniversaryManager:GetNotChooseBranchTable()
    local branchRefresh =self.homeData.branchRefresh or {}
    local allChoseTable = {    -- 所有的选择类型 支线类型 2 ~ 6
        ["2"] = 2,
        ["3"] = 3,
        ["4"] = 4,
        ["5"] = 5,
        ["6"] = 6,
    }
    local notChooseTable = {}
    local haveChoose = {}
    -- 去除当前类型
    if checkint(branchRefresh.type)  > 0  then
        haveChoose[tostring(branchRefresh.type)] = branchRefresh.type
    end
    -- 去除已经刷子刷新过的类型
    if branchRefresh.refresh  then
        for index , branchType  in ipairs( branchRefresh.refresh) do
            haveChoose[tostring(branchType)] = branchType
        end
    end
    for branchTypeStr, branchType in pairs(allChoseTable) do
        if not  haveChoose[branchTypeStr] then
            notChooseTable[branchTypeStr] = branchType
        end
    end
    return notChooseTable
end

function AnniversaryManager:EnterAnniversary()
    local isUnlock =  CommonUtils.UnLockModule(JUMP_MODULE_DATA.ANNIVERSARY18 , true)
    if isUnlock then
        local anniversaryFirstEnterView = app.uiMgr:GetCurrentScene():GetDialogByName("AnniversaryFirstEnterView")
        if not anniversaryFirstEnterView then
            local view =  require('Game.views.anniversary.AnniversaryFirstEnterView').new()
            view:setPosition(display.center)
            app.uiMgr:GetCurrentScene():AddDialog(view)
        end
    end
end
--==============================--
---@Description: 获取到支线的最大类型
---@author : xingweihao
---@date : 2018/10/24 3:44 PM
--==============================--

function AnniversaryManager:GetMaxBranchTypeKinds()
    return 5
end

function AnniversaryManager.Destroy( key )
    key = (key or "AnniversaryManager")
    if AnniversaryManager.instances[key] == nil then
        return
    end

    AnniversaryManager.instances[key] = nil
end


--[[
是否打开过 周年庆主界面打脸
]]
function AnniversaryManager:GetOpenedHomePosterKey_()
    return string.fmt('IS_OPENED_ANNIVERSARY_POSTER_%1', app.gameMgr:GetUserInfo().playerId)
end
function AnniversaryManager:IsOpenedHomePoster()
    return cc.UserDefault:getInstance():getBoolForKey(self:GetOpenedHomePosterKey_(), false)
end
function AnniversaryManager:SetOpenedHomePoster(isOpened)
    cc.UserDefault:getInstance():setBoolForKey(self:GetOpenedHomePosterKey_(), isOpened == true)
    cc.UserDefault:getInstance():flush()
end


--[[
显示 周年庆回顾动画 弹窗
]]
function AnniversaryManager:ShowReviewAnimationDialog()
    local reviewAnimationView = require('Game.views.anniversary.AnniversaryReviewAnimationView').new()
    app.uiMgr:GetCurrentScene():AddDialog(reviewAnimationView)
end


--[[
打开 外部浏览器看周年庆h5
]]
function AnniversaryManager:OpenReviewBrowserUrl()
    local urlParams = {
        string.fmt('host=%1', Platform.serverHost),
        string.fmt('playerId=%1', tostring(app.gameMgr:GetUserInfo().encryptPlayerId)),
    }
    local targetUrl = string.fmt('http://notice-%1/anniversary/index.html?%2', Platform.serverHost, table.concat(urlParams, '&'))
    FTUtils:openUrl(targetUrl)
end

--==============================--
---@Description: 获取服务器上的当前时间
---@author : xingweihao
---@date : 2018/12/15 1:34 AM
--==============================--
function AnniversaryManager:GetTimeSeverTime(timeStr)
    local serverTimeSecond = checkint(self.homeData.currentTime)
    local timeData  = string.split(string.len(timeStr) > 0 and timeStr or '00:00', ':')
    local serverTimestamp  = os.date('!%Y-%m-%d _H_:_M_:00', serverTimeSecond + getServerTimezone())
    local timestamp   = string.fmt(serverTimestamp, {_H_ = timeData[1], _M_ = timeData[2]})
    local timeSecond  = timestampToSecond(timestamp) - getServerTimezone()
    return timeSecond
end
function AnniversaryManager:GetDialogText()
    local dialogIndex = "1"
    if self.CHANGE_SKIN_CONF.SKIN_MODE then
        local changeSkinTable = self:GetChangeSkinData()
        dialogIndex = changeSkinTable.dialogIndex
    end
    return CommonUtils.GetConfigNoParser("anniversary", "text", dialogIndex)
end

function AnniversaryManager:GetGoldenAirShipID()
    return checkint(CommonUtils.GetConfigNoParser("anniversary", "parameter", "1").diceId)
end

function AnniversaryManager:GetAnniversaryTicketID()
    return checkint(CommonUtils.GetConfigNoParser("anniversary", "parameter", "1").ticket)
end

function AnniversaryManager:GetIncomeCurrencyID()
    return checkint(CommonUtils.GetConfigNoParser("anniversary", "parameter", "1").income)
end

function AnniversaryManager:GetRingGameID()
    return checkint(CommonUtils.GetConfigNoParser("anniversary", "parameter", "1").lotteryToken)
end
-- 获取到周年庆排行榜的积分id
function AnniversaryManager:GetAnniversaryScoreId()
    local parameterConf = CommonUtils.GetConfigNoParser("anniversary", "parameter", "1")
    local integral = checkint(parameterConf.integral)
    integral = integral > 0 and integral or 890039
    return integral
end


-- 主bgm
function AnniversaryManager:PlayAnniversaryMainBGM()
    local annivMainBgmId  = AUDIOS.ZNQ.Food_Znq_China.id
    local changeSkinTable = self:GetChangeSkinData()
    if changeSkinTable and changeSkinTable.manBgmId then
        annivMainBgmId = changeSkinTable.manBgmId
    end
    PlayBGMusic(annivMainBgmId)
end
-- 抽卡bgm
function AnniversaryManager:PlayAnniversaryCapsuleBGM()
    local annivCapsuleBgmId = AUDIOS.ZNQ.Food_Znq_Sakura.id
    local changeSkinTable   = self:GetChangeSkinData()
    if changeSkinTable and changeSkinTable.capsuleBgmId then
        annivCapsuleBgmId = changeSkinTable.capsuleBgmId
    end
    PlayBGMusic(annivCapsuleBgmId)
end


return AnniversaryManager