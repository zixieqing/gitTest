--[[
 * author : liuzhipeng
 * descpt : 20春活 管理器
]]
local BaseManager     = require('Frame.Manager.ManagerBase')
---@class SpringActivity20Manager:ManagerBase
local SpringActivity20Manager = class('SpringActivity20Manager', BaseManager)
-------------------------------------------------
-- manager method

SpringActivity20Manager.DEFAULT_NAME = 'SpringActivity20Manager'
SpringActivity20Manager.instances_   = {}

function SpringActivity20Manager.GetInstance(instancesKey)
    instancesKey = instancesKey or SpringActivity20Manager.DEFAULT_NAME

    if not SpringActivity20Manager.instances_[instancesKey] then
        SpringActivity20Manager.instances_[instancesKey] = SpringActivity20Manager.new(instancesKey)
    end
    return SpringActivity20Manager.instances_[instancesKey]
end


function SpringActivity20Manager.Destroy(instancesKey)
    instancesKey = instancesKey or SpringActivity20Manager.DEFAULT_NAME

    if SpringActivity20Manager.instances_[instancesKey] then
        SpringActivity20Manager.instances_[instancesKey]:release()
        SpringActivity20Manager.instances_[instancesKey] = nil
    end
    
end


-------------------------------------------------
-- life cycle

function SpringActivity20Manager:ctor(instancesKey)
    self.super.ctor(self)

    if SpringActivity20Manager.instances_[instancesKey] then
        funLog(Logger.INFO, "注册相关的facade类型")
    else
        self:initial()
    end
end


function SpringActivity20Manager:initial()
end


function SpringActivity20Manager:release()
end


-------------------------------------------------
-- public method
--[[
初始化homeData
--]]
function SpringActivity20Manager:InitHomeData()
    local homeData = self:GetHomeData()
    -- 初始化时将 unlockStory 转化为Map
	local unlockStoryMap = {}
	for index, storyId in ipairs(homeData.unlockedStory or {}) do
		unlockStoryMap[tostring(storyId)] = storyId
	end
    homeData.unlockStoryMap = unlockStoryMap
    -- 初始化PassQuests
    homeData.passedQuestMap = {}
    for i, v in ipairs(homeData.passedQuest) do
        homeData.passedQuestMap[tostring(v)] = v
    end
    -- 初始化保存编队
    homeData.activityTeam = {{}}
    if homeData.teamCards then
        for i, v in ipairs(homeData.teamCards) do
            table.insert(homeData.activityTeam[1], {id = v})
        end
    end
    -- 初始化全局buff
    local additionConfig = CommonUtils.GetConfigAllMess('cardAddition', 'springActivity2020')
    local globalBuff = nil
    for i= #additionConfig, 1, -1 do
        if checkint(homeData.damagePlus) >= checkint(additionConfig[i].collectNum) then
            local conf = additionConfig[i]
            globalBuff = {
                buffId = checkint(conf.activeSkills[1]),
                descr = conf.descr,
                damagePlus = homeData.damagePlus,
            }
            if i ~= #additionConfig then
                globalBuff.nextCollectNum = additionConfig[i + 1].collectNum
                globalBuff.nextDescr = additionConfig[i + 1].descr
            end
            break
        end
    end
    local buffConfig = CommonUtils.GetConfig('common', 'payBuff', globalBuff.buffId)

    globalBuff.skillId = buffConfig.skillId
    globalBuff.buffEffect = buffConfig.descr
    homeData.globalBuff = globalBuff
    -- 初始化活动体力
    self:InitActivityHp()
    -- 初始化spBoss数据
    if next(homeData.bird) ~= nil then
        homeData.bird.duration = tonumber(homeData.rankDuration)
        homeData.bird.times = tonumber(homeData.rankTimes)
    end
end
--[[
初始化活动体力
--]]
function SpringActivity20Manager:InitActivityHp()
    local homeData = self:GetHomeData()
    local paramConfig = CommonUtils.GetConfigAllMess('param', 'springActivity2020')
    local hpData = {
        hpGoodsId                = checkint(paramConfig.hpGoodsId),
        hpPurchaseAvailableTimes = checkint(homeData.buyActivityHpTimes),
        hpMaxPurchaseTimes       = checkint(paramConfig.buyHpTimes),
        hpNextRestoreTime        = checkint(homeData.nextActivityHpSeconds),
        hpRestoreTime            = checkint(homeData.activityHpRecoverSeconds),
        hpUpperLimit             = checkint(homeData.activityHpUpperLimit),
        hp                       = checkint(homeData.activityHp),
        hpPurchaseConsume        = paramConfig.buyHpConsume[1],
        hpPurchaseCmd            = POST.SPRING_ACTIVITY_20_BUY_HP,
    }
    app.activityHpMgr:InitHpData(hpData)
end

--[[
获取活动hp的道具id
--]]
function SpringActivity20Manager:GetHPGoodsId()
    local paramConfig = CommonUtils.GetConfigAllMess('param', 'springActivity2020')
	return checkint(paramConfig.hpGoodsId)
end
--[[
获取活动id
--]]
function SpringActivity20Manager:GetActivityId()
    local activityHomeData = app.gameMgr:GetUserInfo().activityHomeData
    for i, v in ipairs(activityHomeData.activity) do
        if checkint(v.type) == checkint(ACTIVITY_TYPE.SPRING_ACTIVITY_20) then
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
function SpringActivity20Manager:GetLotteryConsume()
    local paramConfig = CommonUtils.GetConfigAllMess('param', 'springActivity2020')
	local consume = {
		goodsId = paramConfig.lotteryGoodsId,
		num = paramConfig.lotteryGoodsNum
	}
    return consume
end


---CheckStoryIsUnlocked
---检查剧情是否解锁
---@param storyId number 剧情id
---@param cb 	  fun():void 看完剧情的回调
function SpringActivity20Manager:CheckStoryIsUnlocked(storyId, cb)
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
function SpringActivity20Manager:IsStoryUnlock( storyId )
	local homeData       = self:GetHomeData()
	local unlockStoryMap = homeData.unlockStoryMap or {}
	return unlockStoryMap[tostring(storyId)] and true or false
end
---InsertUnlockStoryMap
---更新解锁剧情map
---@param storyId number 剧情id
function  SpringActivity20Manager:UpdateUnlockStoryMap(storyId)
	local homeData       = self:GetHomeData()
	local unlockStoryMap = homeData.unlockStoryMap or {}
	unlockStoryMap[tostring(storyId)] = storyId
	homeData.unlockStoryMap = unlockStoryMap
end

---ShowOperaStage
---显示剧情界面
---@param storyId number 剧情id
---@param cb 	 fun():void 看完剧情的回调
function SpringActivity20Manager:ShowOperaStage(storyId, cb, isSendReq)
    local path = string.format("conf/%s/springActivity2020/story.json",i18n.getLang())
    local stage = require( "Frame.Opera.OperaStage" ).new({id = storyId, path = path, guide = false, isHideBackBtn = true, cb = function (tag)
		if isSendReq then
			app:DispatchSignal(POST.SPRING_ACTIVITY_20_UNLOCK_STORY.cmdName, {storyId = storyId})
		end
		if cb then cb() end
        -- app:DispatchObservers(ANNIVERSARY_BGM_EVENT , {})
    end})
    stage:setPosition(display.center)
    sceneWorld:addChild(stage, GameSceneTag.Dialog_GameSceneTag)
end
--[[
显示全局buff详细信息板
--]]
function SpringActivity20Manager:ShowBuffInformationBoard( sender )
    local buff = self:GetGlobalBuff()
    local effect = self:GetPoText(__('当前全服buff效果: ')) .. buff.buffEffect
    local progress = nil 
    if buff.nextCollectNum then
        progress = string.fmt(self:GetPoText(__('进度: 升级buff全服还需收集_num_个_name_')), {['_num_'] = checkint(buff.nextCollectNum) - checkint(buff.damagePlus), ['_name_']= self:GetPoText(__('生死树之种'))})
    else
        progress = self:GetPoText(__('进度: 当前buff效果已达到上限'))
    end
    app.uiMgr:ShowInformationTipsBoard({
        targetNode = sender,
        effect = effect,
        progress = progress,
        type = 20
    })
end
-------------------------------------------------
-- get/set
--[[
设置活动homeData
@params homeData table 活动home数据
--]]
function SpringActivity20Manager:SetHomeData( homeData )
    self.homeData = checktable(homeData)
    self:InitHomeData()
end
--[[
获取活动homeData
--]]
function SpringActivity20Manager:GetHomeData( )
    return self.homeData or {}
end
--[[
获取全服buff加成
@return damagePlus num 全服buff加成
--]]
function SpringActivity20Manager:GetDamageBuff()
    local homeData = self:GetHomeData()
    return homeData.damagePlus
end
--[[
获取特殊boss数据
--]]
function SpringActivity20Manager:GetSpBoss()
    local homeData = self:GetHomeData()
    return next(homeData.bird) ~= nil and homeData.bird or nil
end
--[[
获取特殊boss出现剩余次数
--]]
function SpringActivity20Manager:GetSpBossAppearNeedTimes()
    local homeData = self:GetHomeData()
    local config = CommonUtils.GetConfigAllMess('param', 'springActivity2020')
    return checkint(config.spboss) - checkint(homeData.birdTimes)
end
--[[
获取剧情点数道具id
@return int 剧情点数道具id
--]]
function SpringActivity20Manager:GetPointGoodsId()
    local paramConfig = CommonUtils.GetConfigAllMess('param', 'springActivity2020')
    return checkint(paramConfig.crusadePoint)
end
--[[
获取剧情点数数量
@return int 剧情点数数量
--]]
function SpringActivity20Manager:GetPointAmount()
    local homeData = self:GetHomeData()
    return checkint(homeData.point)
end
--[[
获取已通过的关卡
@return PassedQusets map 通过的关卡
--]]
function SpringActivity20Manager:GetPassedQuestMap()
    local homeData = self:GetHomeData()
    return homeData.passedQuestMap or {}
end
--[[
获取活动编队
--]]
function SpringActivity20Manager:GetActivityTeam()
    local homeData = self:GetHomeData()
    return homeData.activityTeam
end
--[[
设置活动编队
--]]
function SpringActivity20Manager:SetActivityTeam( activityTeam )
    local homeData = self:GetHomeData()
    homeData.activityTeam = activityTeam
end
--[[
获取困难关卡挑战次数
--]]
function SpringActivity20Manager:GetHardQuestUsed()
    local homeData = self:GetHomeData()
    return homeData.hardQuestUsed or {}
end
--[[
获取全局buff
--]]
function SpringActivity20Manager:GetGlobalBuff()
    local homeData = self:GetHomeData()
    return homeData.globalBuff
end
--[[
获取排名奖励
@params rank int 排名
@return rewards list 奖励列表（当前段位无奖励返回为nil）
--]]
function SpringActivity20Manager:GetRankRewards( rank )
    local rankRewardConf = CommonUtils.GetConfigAllMess('rankReward', 'springActivity2020')
    local rewards = nil 
    for i, v in pairs(rankRewardConf) do
        if checkint(rank) >= checkint(v.upperLimit) and checkint(rank) <= checkint(v.lowerLimit) then
            rewards = v.rewards
            break
        end
    end
    return rewards
end
--[[
获取boss门票id
--]]
function SpringActivity20Manager:GetBossTicketGoodsId()
    local paramConfig = CommonUtils.GetConfigAllMess('param', 'springActivity2020')
    return checkint(paramConfig.crusadeGoodsId)
end
--[[
获取boss门票数量
--]]
function SpringActivity20Manager:GetBossTicketAmount()
    local homeData = self:GetHomeData()
    return checkint(homeData.bossTicket)
end


function SpringActivity20Manager:GetChangeSkinData()
    if GAME_MOUDLE_EXCHANGE_SKIN.SPRING_2020 then
        if not  self.changeSkinTable then
            self.changeSkinTable =  require("changeSkin.spring2020." .. GAME_MOUDLE_EXCHANGE_SKIN.SPRING_2020)
        end
        return self.changeSkinTable
    end
    return nil
end
--更换文字的方法
function SpringActivity20Manager:GetPoText(text)
    local changeSkinTable =  self:GetChangeSkinData() or {}
    local podTable = changeSkinTable.po
    if podTable == nil then
        return text
    end
    return podTable[text] or text
end
--更换资源的方法
function SpringActivity20Manager:GetResPath(filePath)
    if GAME_MOUDLE_EXCHANGE_SKIN.SPRING_2020 then
        return _resEx(filePath, nil, GAME_MOUDLE_EXCHANGE_SKIN.SPRING_2020)
    end
    return _res(filePath)
end
--更换spine 的方法
function SpringActivity20Manager:GetSpinePath(filePath)
    if GAME_MOUDLE_EXCHANGE_SKIN.SPRING_2020 then
        return _spnEx(filePath, GAME_MOUDLE_EXCHANGE_SKIN.SPRING_2020)
    end
    return _spn(filePath)
end
function SpringActivity20Manager:GetBuffSpinePos()
    if GAME_MOUDLE_EXCHANGE_SKIN.SPRING_2020 then
        local changeSkinTable =  self:GetChangeSkinData()
        return changeSkinTable.buffSpinePos
    end
    return cc.p(0,0)
end
function SpringActivity20Manager:GetBuffPosTable()
    if GAME_MOUDLE_EXCHANGE_SKIN.SPRING_2020 then
        local changeSkinTable =  self:GetChangeSkinData()
        return changeSkinTable.buffPosTable
    end
    return {
        buffBtnBg = cc.p(0 , 0),
        buffBtn = cc.p(0 ,0)
    }
end

function SpringActivity20Manager:GetDragonSpine()
    if GAME_MOUDLE_EXCHANGE_SKIN.SPRING_2020 then
        local changeSkinTable =  self:GetChangeSkinData()
        if changeSkinTable.dragonPath then
            return self:GetSpinePath(changeSkinTable.dragonPath)
        end
    end
end

function SpringActivity20Manager:GetStagePathByIconId(iconId)
    --iconId = checkint(iconId)
    if string.len(iconId) > 0 and checkint(iconId) > 0 then
        if GAME_MOUDLE_EXCHANGE_SKIN.SPRING_2020 then
            local changeSkinTable =  self:GetChangeSkinData()
            if changeSkinTable.stageIconPath then
                return self:GetResPath(string.format(changeSkinTable.stageIconPath , iconId))
            end
        end
    end
    return string.format('ui/anniversary19/story/%s.png', 'wonderland_plot_icon_1')
end
-------------------------------------------
return SpringActivity20Manager