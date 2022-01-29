--[[
工会活动
--]]
local Mediator = mvc.Mediator
local UnionActivityMediator = class("UnionActivityMediator", Mediator)
local NAME = "UnionActivityMediator"

------------ import ------------
local unionMgr = AppFacade.GetInstance():GetManager("UnionManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")

local UnionConfigParser  = require('Game.Datas.Parser.UnionConfigParser')
------------ import ------------

------------ define ------------
local UnionEntranceConfig = {
	['1'] = {path = _res('ui/union/activity/guild_activity_ico_1.png'), mediatorName = 'UnionHuntMediator'}, 
	['2'] = {path = _res('ui/union/activity/guild_activity_ico_2.png'), mediatorName = 'UnionPartyPrepareHomeMediator'},
	['3'] = {path = _res('ui/union/activity/guild_activity_ico_3.png'), mediatorName = 'unionWars.UnionWarsHomeMediator', moduleState = GAME_MODULE_OPEN.UNION_WARS, customEnterFunc = function()
		local warsModelFactory = require('Game.models.UnionWarsModelFactory')
		local UnionWarsModel   = warsModelFactory.UnionWarsModel
		local unionMemberList  = checktable(app.unionMgr:getUnionData()).member or {}
		local unionMemberCount = table.nums(unionMemberList)
		if unionMemberCount < UnionWarsModel.ATTEND_MIN then
			return false, string.fmt(__('当前工会人数少于_num_人，不满足工会竞赛参与条件。'), {_num_ = UnionWarsModel.ATTEND_MIN})
		else
			return true
		end
	end},
}
------------ define ------------

--[[
constructor
--]]
function UnionActivityMediator:ctor(params, viewComponent)
	Mediator.ctor(self, NAME, viewComponent)

	local initArgs       = checktable(params)
	self.autoInitArgs_   = initArgs.autoInitArgs
	self.autoActivityId_ = checkint(initArgs.autoActivityId)

	-- 即将进入的活动
	self.selectedActivityId = nil
end
---------------------------------------------------
-- mediator extend begin --
---------------------------------------------------
function UnionActivityMediator:InterestSignals()
	local signals = {
		'ENTER_UNION_ACTIVITY',
		'CLOSE_UNION_ACTIVITY'
	}

	-- 插入一次需要关注的信号
	for k,v in pairs(UnionEntranceConfig) do
		if nil ~= v.homeCmd then
			table.insert(signals, v.homeCmd.sglName)
		end
	end

	return signals
end
function UnionActivityMediator:ProcessSignal( signal )
	local name = signal:GetName()
	local body = signal:GetBody()

	if 'ENTER_UNION_ACTIVITY' == name then

		-- 进入指定工会活动
		self:EnterUnionActivity(body)

	elseif 'CLOSE_UNION_ACTIVITY' == name then

		-- 关闭自己
		self:CloseSelf()

	else

		-- 请求回调的信号
		self:ResponseForActivityHome(body)

	end
end
function UnionActivityMediator:Initial( key )
	self.super.Initial(self, key)
end
function UnionActivityMediator:OnRegist()
	-- 初始化一次home信号
	for k,v in pairs(UnionEntranceConfig) do
		if nil ~= v.homeCmd then
			regPost(v.homeCmd)
		end
	end

	-- 初始化界面
	self:InitScene()
end
function UnionActivityMediator:OnUnRegist()
	-- 注销home信号
	for k,v in pairs(UnionEntranceConfig) do
		if nil ~= v.homeCmd then
			unregPost(v.homeCmd)
		end
	end

	-- 销毁界面
	uiMgr:GetCurrentScene():RemoveDialog(self:GetViewComponent())
end
---------------------------------------------------
-- mediator extend end --
---------------------------------------------------

---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化界面
--]]
function UnionActivityMediator:InitScene()
	local scene = require('Game.views.union.UnionActivityScene').new()
	display.commonUIParams(scene, {ap = cc.p(0.5, 0.5), po = cc.p(display.cx, display.cy)})
	uiMgr:GetCurrentScene():AddDialog(scene)

	self:SetViewComponent(scene)

	local activityConfig = CommonUtils.GetConfigAllMess(UnionConfigParser.TYPE.ENTRANCE, 'union')
	local activityInfo = {}
	if not CommonUtils.GetModuleAvailable(MODULE_SWITCH.UNION_HUNT) then
		if activityConfig['1'] then
			activityConfig['1'] = nil
		end
	end

	-- 处理活动数据
	for aid, aconf in pairs(activityConfig) do
		local updescr        = string.split(tostring(aconf.descr), '\\')[1]
		local downdescr      = string.split(tostring(aconf.descr), '\\')[2]
		local entranceDefine = checktable(UnionEntranceConfig[tostring(aid)])
		if entranceDefine.moduleState ~= false then
			local info = {
				id          = checkint(aid),
				name        = tostring(aconf.name),
				updescr     = updescr,
				downdescr   = downdescr,
				unlockLevel = checkint(aconf.openUnionLevel),
				iconPath    = checkstr(entranceDefine.path),
				sequence    = checkint(aconf.sequence)
			}
			table.insert(activityInfo, info)
		end
	end
	
	-- 根据sequence排序
	table.sort(activityInfo, function (a, b)
		if a.sequence == b.sequence then
			return a.id < b.id
		else
			return a.sequence < b.sequence
		end
	end)

	scene:RefreshUI(activityInfo, checkint(unionMgr:getUnionData().level))

	-- check auto popup activity
	if self.autoActivityId_ > 0 then
		self:EnterUnionActivity({id = self.autoActivityId_})
	end
end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- control begin --
---------------------------------------------------
--[[
进入指定模块
@params data table {
	id int 活动模块id
}
--]]
function UnionActivityMediator:EnterUnionActivity(data)
	local activityId = checkint(data.id)
	local activityConfig = CommonUtils.GetConfig('union', UnionConfigParser.TYPE.ENTRANCE, activityId)

	if nil == activityConfig then
		uiMgr:ShowInformationTips(__('活动不存在!!!'))
		return
	end

	-- 检查是否解锁
	if checkint(activityConfig.openUnionLevel) > checkint(unionMgr:getUnionData().level) then
		uiMgr:ShowInformationTips(string.format(__('工会%d级解锁!!!'), checkint(activityConfig.openUnionLevel)))
		return
	end

	-- 检测是否有自定义进入口的检测方法
	local entranceConfig = UnionEntranceConfig[tostring(activityId)]
	if entranceConfig.customEnterFunc then
		local isEnable, errorMsg = entranceConfig.customEnterFunc()
		if not isEnable then
			uiMgr:ShowInformationTips(errorMsg)
			return
		end
	end

	-- 跳转至指定界面
	local isFirstOpen = false
	local key = ''
	if checkint(activityId) == 1 then
		key = string.format('IS_FIRST_OPEN_UNION_ACTIVITY_%d_%d', checkint(gameMgr:GetUserInfo().playerId), activityId)
		-- cc.UserDefault:getInstance():setBoolForKey(key , true)
		isFirstOpen = cc.UserDefault:getInstance():getBoolForKey(key, true)
	end
	if isFirstOpen then
		local storyStage = require('Frame.Opera.OperaStage').new({id = checkint(2), path = string.format("conf/%s/union/story.json",i18n.getLang()), guide = true, cb = function(sender)
            cc.UserDefault:getInstance():setBoolForKey(key, false)
            cc.UserDefault:getInstance():flush()
			self:JumpToActivity(activityId)
        end})
        storyStage:setPosition(display.center)
        sceneWorld:addChild(storyStage, GameSceneTag.Dialog_GameSceneTag)
	else
		self:JumpToActivity(activityId)
	end

	-- 移除自己
	-- AppFacade.GetInstance():DispatchObservers('CLOSE_UNION_ACTIVITY')
end


--[[
关闭自己
--]]
function UnionActivityMediator:CloseSelf()
	AppFacade.GetInstance():UnRegsitMediator(NAME)
end


--[[
创建指定活动页面
@params id int 活动id
--]]
function UnionActivityMediator:JumpToActivity(id)
	local entranceConfig = UnionEntranceConfig[tostring(id)]
	if nil ~= entranceConfig then
		local mediatorName = checkstr(entranceConfig.mediatorName)
		if 0 < string.len(string.gsub(mediatorName, ' ', '')) then

			if app.router.routes[mediatorName] then
				app.router:Dispatch({name = 'UnionLobbyMediator'}, {name = mediatorName})
			else
				-- 跳转信息有效
				if nil ~= entranceConfig.homeCmd then
					self:RequestForActivityHome(id, entranceConfig.homeCmd)
				else
					local mediator = require(string.format('Game.mediator.%s', mediatorName)).new(self.autoInitArgs_)
					AppFacade.GetInstance():RegistMediator(mediator)
					self.autoInitArgs_ = nil
				end
			end

		end
	end
end


--[[
请求活动首页信息
@params id int 活动id
@params homeCmd PostData 请求的数据
--]]
function UnionActivityMediator:RequestForActivityHome(id, homeCmd)
	self.selectedActivityId = id
	self:SendSignal(homeCmd.cmdName)
end


--[[
接收到活动首页请求的回调信号
@params responseData table 服务器返回的信息
--]]
function UnionActivityMediator:ResponseForActivityHome(responseData)
	if self.selectedActivityId then

		local entranceConfig   = UnionEntranceConfig[tostring(self.selectedActivityId)]
		local entranceMdtName  = checkstr(entranceConfig.mediatorName)
		local entranceMediator = require(string.format('Game.mediator.%s', entranceMdtName)).new(responseData)
		AppFacade.GetInstance():RegistMediator(entranceMediator)
		
		self.selectedActivityId = nil
	end
end


---------------------------------------------------
-- control end --
---------------------------------------------------

return UnionActivityMediator
