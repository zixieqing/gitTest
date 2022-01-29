--[[
堕神管理模块
--]]
---@type ChangeSkinManager
local ChangeSkinManager = require( "Frame.Manager.ChangeSkinManager" )
---@class Anniversary2019Manager : ChangeSkinManager
local Anniversary2019Manager = class('Anniversary2019Manager',ChangeSkinManager)
local ANNIVERSARY_2019_AUGURY_REFRESH_COUNTDOWN = 'ANNIVERSARY_2019_AUGURY_REFRESH_COUNTDOWN'
Anniversary2019Manager.instances = {}
Anniversary2019Manager.CHANGE_SKIN_CONF = {
	SKIN_MODE = GAME_MOUDLE_EXCHANGE_SKIN.ANNIV2019, -- 换皮的模式
	SKIN_PATH = "anniversary19" , -- 换皮的路径
}
---------------------------------------------------
-- mediator extend begin --
---------------------------------------------------
function Anniversary2019Manager:ctor( key )
	self.super.ctor(self)

	self.spineCache = false
	self.isEnd = false
	if Anniversary2019Manager.instances[key] ~= nil then
		funLog(Logger.INFO,"注册相关的facade类型" )
		return
	end
	self.dreamQuestType = {
		LITTLE_MONSTER = 1,      -- 小怪关：1
		ELITE_SHUT     = 2,      -- 精英关：2
		ANSWER_SHUT    = 3,      -- 答题关：3
		GUAN_PLOT      = 4,      -- 剧情关：4
		CHEST_SHUT     = 5,      -- 宝箱关：5
		TRAP_SHUT      = 6,      -- 陷阱关：6
		CARDS_SHUT     = 7       -- 打牌关：7
	}
	self.maxStep = 7  -- 探索最大的步骤数
	self.isObserver = false
	self.spineTable = self:InitSpineTable()
	self.homeData = {}
	Anniversary2019Manager.instances[key] = self
end
function Anniversary2019Manager:InitSpineTable()
	local changeSkin =  self:GetChangeSkinData()
	local spine = changeSkin.spine
	local data = {}
	if spine then
		for key , value in pairs(spine) do
			data[key] = self:GetSpinePath(value).path
		end
	else
		data = {
			WONDERLAND_MAIN_ZZZ       = "ui/anniversary19/effects/wonderland_main_zzz",
			WONDERLAND_EXPLORE_BOSS   = "ui/anniversary19/effects/wonderland_explore_boss",
			WONDERLAND_EXPLORE_STORY  = "ui/anniversary19/effects/wonderland_explore_story",
			WONDERLAND_EXPLORE_LIGHT = "ui/anniversary19/effects/wonderland_explore_light",
			WONDERLAND_EXPLORE_BOX    = "ui/anniversary19/effects/wonderland_explore_box",
			WONDERLAND_DRAW_BOX       = "ui/anniversary19/effects/wonderland_draw_box",
			WONDERLAND_OPENING_BOOM   = "ui/anniversary19/effects/wonderland_opening_boom",
			WONDERLAND_MAIN_POINT     = "ui/anniversary19/effects/wonderland_main_point",
			WONDERLAND_DRAW_RABBIT    = "ui/anniversary19/effects/wonderland_draw_rabbit",
			WONDERLAND_MAIN_TREE      = "ui/anniversary19/effects/wonderland_main_tree",
			WONDERLAND_EXPLORE_BUFF   = "ui/anniversary19/effects/wonderland_explore_buff",
			WONDERLAND_EXPLORE_DOOR   = "ui/anniversary19/effects/wonderland_explore_door",
		}
	end
	return data
end
function Anniversary2019Manager.GetInstance(key)
	key = (key or "Anniversary2019Manager")
	if Anniversary2019Manager.instances[key] == nil then
		Anniversary2019Manager.instances[key] = Anniversary2019Manager.new(key)
	end
	return Anniversary2019Manager.instances[key]
end


function Anniversary2019Manager:InitData(data)
	if not  data then
		return
	end
	self.homeData = data

	-- 初始化时将 unlockStory 转化为Map
	local unlockStoryMap = {}
	for index, storyId in ipairs(data.unlockStoryInfo or {}) do
		unlockStoryMap[tostring(storyId)] = storyId
	end
	self.homeData.unlockStoryMap = unlockStoryMap
	-- 设置活动是否结束
	self:SetIsEnd(self.homeData.isEnd)
	-- 初始化活动体力
	self:InitActivityHp()
	-- 初始化讨伐体力
	self:InitSuppressHp()
	-- 占卜倒计时
	self:StartAuguryRefreshCountdown(data.expire)
end
---@param isEnd number  @活动是否结束 1:结束 0:未结束
function Anniversary2019Manager:SetIsEnd(isEnd)
	isEnd = checkint(isEnd)
	self.isEnd = isEnd == 1 and true or false
end

function Anniversary2019Manager:IsEnd()
	return self.isEnd
end


--==============================--
---@Description: 获取homeData 的数据
---@author : xingweihao
---@date : 2018/10/16 11:31 AM
--==============================--

function Anniversary2019Manager:GetHomeData()
	return self.homeData
end

---GetDreamQuestTypeNameByDreamQuestType
---@param dreamType string
function Anniversary2019Manager:GetDreamQuestTypeNameByDreamQuestType(dreamType)
	local anniversary2ConfigParser = self:GetConfigParse()
	local dreamQuestType = self.dreamQuestType
	local configName = {
		[tostring(dreamQuestType.LITTLE_MONSTER)] = anniversary2ConfigParser.TYPE.EXPLORE_MONSTER,       -- 小怪关：1
		[tostring(dreamQuestType.ELITE_SHUT)]     = anniversary2ConfigParser.TYPE.EXPLORE_ELITE_MONSTER, -- 精英关：2
		[tostring(dreamQuestType.ANSWER_SHUT)]    = anniversary2ConfigParser.TYPE.EXPLORE_OPTION,        -- 答题关：3
		[tostring(dreamQuestType.GUAN_PLOT)]      = anniversary2ConfigParser.TYPE.EXPLORE_STORY,         -- 剧情关：4
		[tostring(dreamQuestType.CHEST_SHUT)]     = anniversary2ConfigParser.TYPE.EXPLORE_CHEST,         -- 宝箱关：5
		[tostring(dreamQuestType.TRAP_SHUT)]      = nil,          										  -- 陷阱关：6
		[tostring(dreamQuestType.CARDS_SHUT)]     = anniversary2ConfigParser.TYPE.EXPLORE_BATTLE_CARD,   -- 打牌关：7
	}
	return configName[tostring(dreamType)]
end

function Anniversary2019Manager:GetDreamQuestTypeConfByDreamQuestType(dreamType)
	local dreamQuestTypeName = self:GetDreamQuestTypeNameByDreamQuestType(dreamType)
	return  self:GetConfigDataByName(dreamQuestTypeName)
end

---GetDreamTypeReward
---@param exploreModuleId string  探索模式
---@param dreamQuestType number 梦境循环类型
---@param exploreId string  梦境循环id
function Anniversary2019Manager:GetDreamTypeReward(exploreModuleId ,dreamQuestType , exploreId )
	local parseConfig = self:GetConfigParse()
	local dreamQuestTypeConf = self:GetDreamQuestTypeConfByDreamQuestType(dreamQuestType)
	local dreamQuestTypeOneConf = dreamQuestTypeConf[tostring(exploreModuleId)][tostring(exploreId)]
	local exoloreConf = self:GetConfigDataByName(parseConfig.TYPE.EXPLORE)
	local exoloreOneConf =exoloreConf[tostring(exploreModuleId)]
	if checkint(dreamQuestType)  == self.dreamQuestType.CARDS_SHUT then
		local accumulativeRewardNum = self:GetAccumulativeRewardNum()
		return {
			goodsId = exoloreOneConf.rewardGoodsId ,
			num = math.floor(accumulativeRewardNum * (dreamQuestTypeOneConf.rewardNumPower /100 ) ) ,
			rewardNumPower = dreamQuestTypeOneConf.rewardNumPower
		}
	else
		return  {
			goodsId = exoloreOneConf.rewardGoodsId ,
			num = dreamQuestTypeOneConf.rewardNum ,
		}
	end
end
function Anniversary2019Manager:AddSpineCacheByPath(spinePath)
	if not  self.spineCache then
		local shareSpineCache = SpineCache(SpineCacheName.ANNIVERSARY_2019)
		if not shareSpineCache:hasSpineCacheData(spinePath) then
			shareSpineCache:addCacheData(spinePath, spinePath, 1)
		end
	end
end
function Anniversary2019Manager:SetSpineChangeData(key , node)
	local changeSkinTable =  self:GetChangeSkinData()
	if changeSkinTable.spineChangeData then
		local spineChangeData = changeSkinTable.spineChangeData
		local data =  spineChangeData[key]
		node:setPosition(data.pos)
		node:setScale(data.scale or 1)
	end
end
--function Anniversary2019Manager:GetPoText(text)
--	local changeSkinTable =  self:GetChangeSkinData()
--	local podTable = changeSkinTable.po
--	if podTable == nil then
--		return text
--	end
--	return podTable[text] ~= "" and podTable[text] or text
--end


--function Anniversary2019Manager:GetChangeSkinData()
--	if GAME_MOUDLE_EXCHANGE_SKIN.ANNIV2019 then
--		if not  self.changeSkinTable then
--			self.changeSkinTable =  require("changeSkin.anniversary19." .. GAME_MOUDLE_EXCHANGE_SKIN.ANNIV2019)
--		end
--		return self.changeSkinTable
--	end
--	return {}
--end

--更换spine 的方法
--function Anniversary2019Manager:GetSpinePath(filePath)
--	if GAME_MOUDLE_EXCHANGE_SKIN.ANNIV2019 then
--		return _spnEx(filePath, GAME_MOUDLE_EXCHANGE_SKIN.ANNIV2019)
--	end
--	return _spn(filePath)
--end

--更换资源的方法
--function Anniversary2019Manager:GetResPath(filePath)
--	if GAME_MOUDLE_EXCHANGE_SKIN.SPRING_2020 then
--		return _resEx(filePath, nil, GAME_MOUDLE_EXCHANGE_SKIN.SPRING_2020)
--	end
--	return _res(filePath)
--end


function Anniversary2019Manager:RemoveSpineCache()
	if self.spineCache then
		local shareSpineCache = SpineCache(SpineCacheName.ANNIVERSARY_2019)
		for spineName , spinePath in pairs(self.spineTable) do
			if shareSpineCache:hasSpineCacheData(spinePath) then
				-- 判断spine 是否加载没有加载就不进行删除
				shareSpineCache:removeCacheData(spinePath)
			end
		end
	end
end

function Anniversary2019Manager:SetExploreData(data , exploreModuleId)
	local homeData = self:GetHomeData()
	homeData.exploreData = data or {}
	homeData.exploreData.exploreModuleId = exploreModuleId
end

function Anniversary2019Manager:GetExploreData()
	return self.homeData.exploreData
end
----=======================----
--@author : xingweihao
--@date : 2019/10/21 7:08 PM
--@Description 放回当前正在探索的 exploreModuleId
--@params
--@return
---=======================----
function Anniversary2019Manager:GetCurrentExploreModuleId()
	local exploreData = self:GetHomeData().exploreData or {}
	local exploreModuleId = exploreData.exploreModuleId
	return checkint(exploreModuleId)
end
----=======================----
--@author : xingweihao
--@date : 2019/10/21 5:40 PM
--@Description 获取到当前探索的进度
--@params
--@return
---=======================----
function Anniversary2019Manager:GetCurrentExploreProgress()
	local exploreData = self:GetExploreData()
	local sectionData = exploreData.section
	local progress = 1
	local isHave = false
	for index, section in pairs(sectionData) do
		if checkint(section.type) == self.dreamQuestType.TRAP_SHUT then
			progress = index
			isHave = true
			break
		elseif checkint(section.passed) == 0 then
			progress = index
			isHave = true
			break
		end
	end
	if not isHave then
		progress =  table.nums(sectionData) + 1
	end
	return progress
end

---@return number  @0 未开始 1 进行中 2.完成
function Anniversary2019Manager:GetDreamCircleStatus()
	local exploreData = self:GetExploreData()
	local sectionData = exploreData.section
	local status = 0
	local isComplete = true  
	for i, v in pairs(sectionData) do
		if checkint(v.type) ~= self.dreamQuestType.TRAP_SHUT then
			if checkint(v.passed) ~= 1 then
				if checkint(v.type) ~= self.dreamQuestType.CARDS_SHUT  then
					if (checkint(v.result) >= 2 and v.isGiveup == true) or  checkint(v.result) == 1 then
						status = 2
					elseif checkint(v.result) > 0 or checkint(v.enter) > 0  then
						status = 1
					else
						status = 0
					end
				else
					if checkint(v.result) > 0 then
						status = 2
					elseif  checkint(v.enter) > 0 then
						status = 1
					else
						status = 0
					end
				end
				isComplete = false
				break
			end

		else
			if checkint(v.passed) == 1 or checkint(v.result) == 1 then
				status = 2
			elseif checkint(v.enter) > 0  then
				status = 1
			else
				status = 0
			end
			isComplete = false
			break
		end
	end
	if isComplete then
		status = 2
	end
	print("isComplete = " ,status )
	return status
end
----=======================----
--@author : xingweihao
--@date : 2019/10/21 5:40 PM
--@Description 设置当前的探索进度
--@params data table  {exploreModuleId  : 当前探索的模块 , progress 当前探索的进度}
--@return
---=======================----
function Anniversary2019Manager:SetCurrentExploreProgress(data)
	local exploreData = self:GetExploreData()
	local sectionData = exploreData.section
	local progress = data.progress
	if sectionData[checkint(progress)] then
		local result = checkint(data.result)
		if result > 0 then
			sectionData[checkint(progress)].result = result
		end

		if data.isGiveup  then
			sectionData[checkint(progress)].result = 2
			sectionData[checkint(progress)].isGiveup = true
		end
		if  checkint(data.enter) > 0   then
			sectionData[checkint(progress)].enter = 1
		end
	end
end
----=======================----
--@author : xingweihao
--@date : 2019/10/21 5:40 PM
--@Description 设置当前的探索进度通过
--@params exploreModuleId  : 当前探索的模块 , progress 当前探索的进度
--@return
---=======================----
function Anniversary2019Manager:SetCurrentExploreProgressPass(progress)
	local exploreData = self:GetExploreData()
	local sectionData = exploreData.section
	local exploreModuleId = self:GetCurrentExploreModuleId()
	if sectionData[checkint(progress)] then
		sectionData[checkint(progress)].passed = 1
		self:SetHomeProgress(exploreModuleId , progress )
	end
end

function Anniversary2019Manager:GetAccumulativeRewardNum()
	local exploreData = self:GetExploreData()
	local accumulativeRewardNum = checkint(exploreData.accumulativeRewardNum)
	return accumulativeRewardNum
end

function Anniversary2019Manager:GetRewardGoodsId(exploreModuleId)
	local parseConf = self:GetConfigParse()
	local exploreConf = self:GetConfigDataByName(parseConf.TYPE.EXPLORE)
	local rewardGoodsId = exploreConf[tostring(exploreModuleId)].rewardGoodsId
	return rewardGoodsId
end

function Anniversary2019Manager:AddPrograssRewardNum(exploreModuleId , progress)
	local exploreData = self:GetExploreData()
	local explore = exploreData.section
	local result = checkint(explore[checkint(progress)].result)
	if  explore[checkint(progress)].passed == 1 then
		return
	end
	if result == 1 then
		local exploreType =  checkint(explore[checkint(progress)].type)
		local exploreId = explore[checkint(progress)].exploreId
		local rewardData = self:GetDreamTypeReward(exploreModuleId , exploreType ,exploreId)
		exploreData.accumulativeRewardNum = checkint(exploreData.accumulativeRewardNum)  + checkint(rewardData.num)
	end
end

function Anniversary2019Manager:SetHomeProgress(exploreModuleId , progress)
	local homeData  = self:GetHomeData()
	local explore =  homeData.explore
	if not  explore[tostring(exploreModuleId)] then
		explore[tostring(exploreModuleId)] = {}
	end
	explore[tostring(exploreModuleId)].progress = progress
end

---@param isExploring number @1 为正在探索中 0 为结束探索
function Anniversary2019Manager:SetHomeExploreStatus(exploreModuleId , isExploring)
	local homeData  = self:GetHomeData()
	local explore =  homeData.explore
	if not  explore[tostring(exploreModuleId)] then
		explore[tostring(exploreModuleId)] = {}
	end
	explore[tostring(exploreModuleId)].exploring  = isExploring
	if isExploring == 0  then
		explore[tostring(exploreModuleId)].progress = 0
	end
end
function Anniversary2019Manager:GetHomeExploreData()
	local homeData  = self:GetHomeData()
	local explore =  homeData.explore
	return explore or {}
end

---CheckStoryIsUnlocked
---检查剧情是否解锁
---@param storyId number @剧情id
---@param cb 	  fun():void @看完剧情的回调
function Anniversary2019Manager:CheckStoryIsUnlocked(storyId, cb)
	local homeData       = self:GetHomeData()
	local unlockStoryMap = homeData.unlockStoryMap or {}
	if unlockStoryMap[tostring(storyId)] then
		if cb then cb() end
		return  
	end
	-- 进入剧情
	self:ShowOperaStage(storyId, cb, true)
end
--[[
判断剧情是否解锁
--]]
function Anniversary2019Manager:IsStoryUnlock( storyId )
	local homeData       = self:GetHomeData()
	local unlockStoryMap = homeData.unlockStoryMap or {}
	return unlockStoryMap[tostring(storyId)] and true or false
end
---InsertUnlockStoryMap
---更新解锁剧情map
---@param storyId number @剧情id
function  Anniversary2019Manager:UpdateUnlockStoryMap(storyId)
	local homeData       = self:GetHomeData()
	local unlockStoryMap = homeData.unlockStoryMap or {}
	unlockStoryMap[tostring(storyId)] = storyId
	homeData.unlockStoryMap = unlockStoryMap
end

---ShowOperaStage
---显示剧情界面
---@param storyId number @剧情id
---@param cb 	  fun():void  @看完剧情的回调
function Anniversary2019Manager:ShowOperaStage(storyId, cb, isSendReq)
    local path = string.format("conf/%s/anniversary2/story.json",i18n.getLang())
    local stage = require( "Frame.Opera.OperaStage" ).new({id = storyId, path = path, guide = false, isHideBackBtn = true, cb = function (tag)
		if isSendReq then
			app:DispatchSignal(POST.ANNIVERSARY2_STORY_UNLOCK.cmdName, {storyId = storyId})
		end
		if cb then cb() end
        -- app:DispatchObservers(ANNIVERSARY_BGM_EVENT , {})
    end})
    stage:setPosition(display.center)
    sceneWorld:addChild(stage, GameSceneTag.Dialog_GameSceneTag)
end


---InitIntegralGoodsId_
---初始化积分道具id
---@return number 积分道具id
function Anniversary2019Manager:InitIntegralGoodsId_()
	local parameterConf =  CommonUtils.GetConfigAllMess('parameter', 'anniversary2') or {}
	self.integralGoodsId = checkint(parameterConf.crusadePoint)
	return self.integralGoodsId
end

--==============================--
---@Description: 获取到 Anniversary2019Manager 的配表设置
---@author : xingweihao
---@date : 2018/10/16 11:37 AM
--==============================--
function  Anniversary2019Manager:GetConfigDataByName(name)
	local parseConfig = self:GetConfigParse()
	local configData  = parseConfig:GetVoById(name)
	return configData
end

function Anniversary2019Manager:AddObserver()
	if not self.isObserver then
		AppFacade.GetInstance():RegistObserver(ANNIVERSARY19_EXPLORE_RESULT_EVENT , mvc.Observer.new(self.ExploreResult, self) )
		self.isObserver = true
	end
end

---ExploreResult
---@param signal Signal
function Anniversary2019Manager:ExploreResult(signal)
	local data = signal:GetBody()
	local progress = self:GetCurrentExploreProgress()
	data.progress = progress
	if self:GetHomeData().exploreData then
		-- 胜利
		if checkint(data.result) > 2  then
			data.result = 2
		end
		self:SetCurrentExploreProgress(data)
	end
end
function Anniversary2019Manager:ReducesBossLevelLeftDiscoveryTimes(exploreModuleId)
	local homeExploreData  = self:GetHomeExploreData()
	local exploreOneData = homeExploreData[tostring(exploreModuleId)]
	if checkint(exploreOneData.nextBossLevelLeftDiscoveryTimes) > 0    then
		exploreOneData.nextBossLevelLeftDiscoveryTimes = exploreOneData.nextBossLevelLeftDiscoveryTimes - 1
	end
end
---@return Anniversary2ConfigParser
function Anniversary2019Manager:GetConfigParse()
	if not self.parseConfig then
		---@type DataManager
		self.parseConfig = app.dataMgr:GetParserByName('anniversary2')
	end
	return self.parseConfig
end

function Anniversary2019Manager.Destroy( key )
	key = (key or "Anniversary2019Manager")
	if Anniversary2019Manager.instances[key] == nil then
		return
	end
	--清除配表数据
	local instance = Anniversary2019Manager.instances[key]
	instance:GetFacade():UnRegistObserver(ANNIVERSARY19_EXPLORE_RESULT_EVENT, instance)
	Anniversary2019Manager.instances[key] = nil

end

---GetIntegralGoodsId
---获得积分道具id
function Anniversary2019Manager:GetIntegralGoodsId()
	return self.integralGoodsId == nil and self:InitIntegralGoodsId_() or self.integralGoodsId
end

--[[
初始化活动体力
--]]
function Anniversary2019Manager:InitActivityHp()
	local homeData = self:GetHomeData()
	local parserConfig  = self:GetConfigParse()
    local paramConfig = self:GetConfigDataByName(parserConfig.TYPE.PARAMETER)
    local hpData = {
        hpGoodsId                = self:GetHPGoodsId(),
        hpPurchaseAvailableTimes = checkint(homeData.buyActivityHpTimes),
        hpMaxPurchaseTimes       = checkint(paramConfig.buyHpTimes),
        hpNextRestoreTime        = checkint(homeData.nextActivityHpSeconds),
        hpRestoreTime            = checkint(homeData.activityHpRecoverSeconds),
        hpUpperLimit             = checkint(homeData.activityHpUpperLimit),
        hp                       = checkint(homeData.activityHp),
        hpPurchaseConsume        = paramConfig.buyHpConsume[1],
        hpPurchaseCmd            = POST.ANNIVERSARY2_BUY_HP,
    }
    app.activityHpMgr:InitHpData(hpData)
end

--[[
获取活动hp的道具id
--]]
function Anniversary2019Manager:GetHPGoodsId()
	local parserConfig  = self:GetConfigParse()
	local paramConfig = self:GetConfigDataByName(parserConfig.TYPE.PARAMETER)
	return checkint(paramConfig.hpGoodsId)
end
--[[
获取活动id
--]]
function Anniversary2019Manager:GetActivityId()
    local activityHomeData = app.gameMgr:GetUserInfo().activityHomeData
    for i, v in ipairs(activityHomeData.activity) do
        if checkint(v.type) == checkint(ACTIVITY_TYPE.ANNIVERSARY19) then
            return checkint(v.activityId)
        end
    end
    return 0
end
--[[
获取单次抽奖消耗
@return map {
	goodsId int 道具id
	num     int 道具数量
}
--]]
function Anniversary2019Manager:GetLotteryConsume()
	local parserConfig  = self:GetConfigParse()
	local paramConfig = self:GetConfigDataByName(parserConfig.TYPE.PARAMETER)
	local consume = {
		goodsId = paramConfig.lotteryGoodsId,
		num = paramConfig.lotteryGoodsNum
	}
    return consume
end


--[[
初始化讨伐体力
--]]
function Anniversary2019Manager:InitSuppressHp()
	local paramConfig = self:GetConfigDataByName(self:GetConfigParse().TYPE.PARAMETER)
    local homeData = self:GetHomeData()
    local hpData   = {
        hpGoodsId             = self:GetSuppressHPId(),
		isAutoRestoreToFull   = true,
        hpNextRestoreTime     = 0,
		hpRestoreTime         = 0,
        hpUpperLimit          = checkint(paramConfig.crusadeHpLimit),
		hp                    = checkint(homeData.crusadeHp),
		calcNextRestoreTimeCb = function()
			local startTime = getLoginServerTime()
			local curTime = getServerTime()
			local diff = (curTime - startTime)
			local remainTime = checkint(app.gameMgr:GetUserInfo().tomorrowLeftSeconds)
			return remainTime - diff
		end
    }
    app.activityHpMgr:InitHpData(hpData)
end


--[[
获取用于讨伐的体力的道具id
--]]
function Anniversary2019Manager:GetSuppressHPId()
	if self.suppressHPId == nil then
		local parameter = self:GetConfigDataByName(self:GetConfigParse().TYPE.PARAMETER)
		self.suppressHPId = checkint(parameter.crusadeGoodsId)
	end
	return self.suppressHPId
end

--[[
播放背景音乐
--]]
function Anniversary2019Manager:PlayBGMusic(key , fileName)
	local changeSkinData = self:GetChangeSkinData()
	if changeSkinData.musicBG then
		local musicBG = changeSkinData.musicBG
		PlayBGMusic(musicBG[key].cueName)
	else
		local fileName = fileName or "ALICE"
		PlayBGMusic(AUDIOS[fileName][key].id)
	end
end


--[[
获取用于讨伐的体力的单次消耗数值
--]]
function Anniversary2019Manager:GetSuppressHPConsume()
	if self.suppressHPConsume == nil then
		local parameter = self:GetConfigDataByName(self:GetConfigParse().TYPE.PARAMETER)
		self.suppressHPConsume = parameter.crusadeHpConsumeNum
	end
	return self.suppressHPConsume
end


function Anniversary2019Manager:StopAuguryRefreshCountdown()
	if app.timerMgr:RetriveTimer(ANNIVERSARY_2019_AUGURY_REFRESH_COUNTDOWN) then
        app.timerMgr:RemoveTimer(ANNIVERSARY_2019_AUGURY_REFRESH_COUNTDOWN)
    end
end

function Anniversary2019Manager:StartAuguryRefreshCountdown(countdown)
	self:StopAuguryRefreshCountdown()
	if countdown <= 0 then
		return
	end
	app.timerMgr:AddTimer({name = ANNIVERSARY_2019_AUGURY_REFRESH_COUNTDOWN, callback = function (countdown)
		if countdown <= 0 then
			self:StopAuguryRefreshCountdown()
			app:DispatchSignal(POST.ANNIVERSARY2_HOME.cmdName)
		end
	end, countdown = countdown})
end


--[[
是否打开过 周年庆主界面打脸
]]
function Anniversary2019Manager:GetOpenedHomePosterKey_()
    return string.fmt('IS_OPENED_ANNIVERSARY2019_POSTER_%1', app.gameMgr:GetUserInfo().playerId)
end
function Anniversary2019Manager:IsOpenedHomePoster()
    return cc.UserDefault:getInstance():getBoolForKey(self:GetOpenedHomePosterKey_(), false)
end
function Anniversary2019Manager:SetOpenedHomePoster(isOpened)
    cc.UserDefault:getInstance():setBoolForKey(self:GetOpenedHomePosterKey_(), isOpened == true)
    cc.UserDefault:getInstance():flush()
end


--[[
显示 周年庆回顾动画 弹窗
]]
function Anniversary2019Manager:ShowReviewAnimationDialog()
    local reviewAnimationView = require('Game.views.anniversary19.Anniversary19ReviewAnimationView').new()
    app.uiMgr:GetCurrentScene():AddDialog(reviewAnimationView)
end


--[[
打开 外部浏览器看周年庆h5
]]
function Anniversary2019Manager:OpenReviewBrowserUrl()
    local urlParams = {
        string.fmt('host=%1', Platform.serverHost),
        string.fmt('playerId=%1', tostring(app.gameMgr:GetUserInfo().playerId)),
    }
    local targetUrl = string.fmt('http://notice-%1/anniversary2019/index.html?%2', Platform.serverHost, table.concat(urlParams, '&'))
	FTUtils:openUrl(targetUrl)
end


return Anniversary2019Manager
