--[[
    家园主界面UI
--]] 
local Mediator = mvc.Mediator
---@class HomelandMediator:Mediator
local HomelandMediator = class("HomelandMediator", Mediator)

local NAME = "HomelandMediator"
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")

-- 功能类型
local MODULE_TYPE = {
	RESTAURANT   = 1, -- 餐厅
	PRIVATE_ROOM = 2, -- 包厢
	FISH_PLACE   = 3, -- 钓场
	WATER_BAR    = 4, -- 水吧
	CAT_HOUSE    = 5, -- 猫屋
}

-- 模块id映射
local MODULE_MAP = {
	[MODULE_TYPE.RESTAURANT]   = JUMP_MODULE_DATA.RESTAURANT,
	[MODULE_TYPE.PRIVATE_ROOM] = JUMP_MODULE_DATA.BOX,
	[MODULE_TYPE.FISH_PLACE]   = JUMP_MODULE_DATA.FISHING_GROUND,
	[MODULE_TYPE.WATER_BAR]    = JUMP_MODULE_DATA.WATER_BAR,
	[MODULE_TYPE.CAT_HOUSE]    = JUMP_MODULE_DATA.CAT_HOUSE,
}

--[[
　　---@Description: params
　　---@param : playerId 玩家的id
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/8/27 3:23 PM
--]]
function HomelandMediator:ctor(params, viewComponent )
	self.super:ctor(NAME, viewComponent)

	params = params or {}
	self.isAction   = true
	self.playerId   = checkint(params.playerId) == 0 and app.gameMgr:GetPlayerId() or checkint(params.playerId)
	self.delayTimes = params.delayTimes or 0
	self.friendData = {}

	if app.gameMgr:IsPlayerSelf(self.playerId) then
		self.friendData = {
			restaurantLevel = app.gameMgr:GetUserInfo().restaurantLevel,
			fishPlaceLevel  = app.gameMgr:GetUserInfo().fishPlaceLevel,
			barLevel        = app.waterBarMgr:getBarLevel(),
			houseLevel      = app.catHouseMgr:getHouseLevel(),
			level           = app.gameMgr:GetUserInfo().level,
		}
	else
		self.friendData = self:GetMyFriendDataById_(self.playerId)
	end
end


function HomelandMediator:Initial(key)
	self.super.Initial(self,key)

	-- create view
	self.homelandView_ = require('Game.views.HomelandView').new({playerId = self.playerId})
	self.homelandView_:setPosition(display.center)
	self:SetViewComponent(self.homelandView_)
	uiMgr:SwitchToScene(self.homelandView_)

	-- add listener
    local viewData = self:getHomelandViewData()
	display.commonUIParams(viewData.fishingGroundBtn, {cb = handler(self, self.FishingGroundButtonAction)})
	display.commonUIParams(viewData.restaurantBtn, {cb = handler(self, self.RestaurantButtonAction)})
	display.commonUIParams(viewData.waterBarBtn, {cb = handler(self, self.WaterBarButtonAction)})
	display.commonUIParams(viewData.catHouseBtn, {cb = handler(self, self.CatHouseButtonAction)})
	-- if not  CommonUtils.JuageMySelfOperation(self.playerId) then
	-- 	viewData.boxBtn:setVisible(false)
	-- end
	display.commonUIParams(viewData.boxBtn , {cb = handler(self, self.BoxButtonAction)})
	display.commonUIParams(viewData.backBtn , {animate = false, cb = function()
		if not self.isAction then
			self.isAction = true
			self:GetFacade():BackHomeMediator()
		end
	end})

	-- update views
	self:SetModuleBtnStatus_(viewData.fishingGroundBtn, MODULE_TYPE.FISH_PLACE)
	self:SetModuleBtnStatus_(viewData.restaurantBtn, MODULE_TYPE.RESTAURANT)
	self:SetModuleBtnStatus_(viewData.waterBarBtn, MODULE_TYPE.WATER_BAR)
	self:SetModuleBtnStatus_(viewData.catHouseBtn, MODULE_TYPE.CAT_HOUSE)
	self:SetModuleBtnStatus_(viewData.boxBtn, MODULE_TYPE.PRIVATE_ROOM)

	if GAME_MODULE_OPEN.WATER_BAR then
		viewData.waterBarBtn:setVisible(app.gameMgr:IsPlayerSelf(self.playerId))  -- only show in self
	else
		viewData.waterBarBtn:setVisible(false)
	end

	viewData.catHouseBtn:setVisible(GAME_MODULE_OPEN.CAT_HOUSE)
	
	-- show
	self:OnEnterAction()
end


function HomelandMediator:CleanupView()
end


function HomelandMediator:OnRegist()
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightHide")
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "allhide")
end


function HomelandMediator:OnUnRegist()
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "rightShow")
	self:GetFacade():DispatchObservers(HomeScene_ChangeCenterContainer, "hide")

    uiMgr:GetCurrentScene():RemoveGameLayer(self.viewComponent)
end


function HomelandMediator:InterestSignals()
	return {}
end
function HomelandMediator:ProcessSignal(signal)
	local name = signal:GetName()
    local data = signal:GetBody()
end


-------------------------------------------------
-- get / set

function HomelandMediator:getHomelandView()
    return self.homelandView_
end


function HomelandMediator:getHomelandViewData()
    return self:getHomelandView().viewData
end


-------------------------------------------------
-- private

--[[
　　---@Description: 根据好友的id 获取到好友的数据
　　---@param :playerId 好友的id
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/8/27 3:35 PM
--]]
function HomelandMediator:GetMyFriendDataById_(playerId)
	local friendList = app.gameMgr:GetUserInfo().friendList
	local friendData = {}
	for i, v in pairs(friendList) do
		if checkint(v.friendId)  == self.playerId then
			friendData = v
			break
		end
	end
	return friendData
end


--[[
　　---@Description: 检测模块是否解锁
　　---@param :
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/8/27 4:06 PM
--]]
function HomelandMediator:CheckModuleIsUnLockByType_(type)
	local playerLevel         = checkint(self.friendData.level)
	local restaurantLevel     = checkint(self.friendData.restaurantLevel)
	local moduleTag           = MODULE_MAP[checkint(type)]
	local openLevel           = CommonUtils.GetModuleOpenLevel(moduleTag)
	local openRestaurantLevel = CommonUtils.GetModuleOpenRestaurantLevel(moduleTag)
	local isUnLock            = playerLevel >= openLevel and restaurantLevel >= openRestaurantLevel
	return isUnLock
end
--[[
　　---@Description: 根据type 的类型获取到图片的路径
　　---@param :type 1餐厅，2包厢，3钓场
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/8/27 12:00 PM
--]]
function HomelandMediator:GetModuleImageByType_(type)
	local path = ""
	local level = 1

	-- 如果玩家是自己
	local friendData = self.friendData
	if type == MODULE_TYPE.RESTAURANT then
		level = math.max(checkint(friendData.restaurantLevel), 1)
	elseif type == MODULE_TYPE.PRIVATE_ROOM  then
		level = math.max(checkint(friendData.restaurantLevel), 1)
	elseif type == MODULE_TYPE.FISH_PLACE then
		level = math.max(checkint(friendData.fishPlaceLevel), 1)
	elseif type == MODULE_TYPE.WATER_BAR then
		level = math.max(checkint(friendData.barLevel), 1)
	elseif type == MODULE_TYPE.CAT_HOUSE then
		level = math.max(checkint(friendData.hosueLevel), 1)
	end

	local entranceConfs = CONF.BUSINESS.ENTRANCE:GetValue(type) or {}
	local homeOneConfig = entranceConfs[tostring(level)] or {}
	path = homeOneConfig.icon or ""
	path = string.len(path) > 0 and _res(string.format("ui/home/homeland/%s.png", path)) or _res('ui/home/homeland/management_home_btn_box_1.png')
	return path
end


--[[
　　---@Description: 设置模块按钮的状态
　　---@param :moduleBtn 模块的btn  值 moduleType 类型值
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/8/27 4:47 PM
--]]
function HomelandMediator:SetModuleBtnStatus_(moduleBtn, moduleType)
	if not moduleBtn then return end

	-- update image
	local imagePath     = self:GetModuleImageByType_(moduleType)
	local moudleImage   = moduleBtn:getChildByName("moudleImage")
	local moudleNameBtn = moudleImage:getChildByName("moudleNameBtn")
	moudleImage:setTexture(imagePath)

	if not self:CheckModuleIsUnLockByType_(moduleType) then
		local grayFilter = GrayFilter:create()
		moudleImage:setFilter(grayFilter)
		local moudleNameBlock = moudleNameBtn:getChildByName("moudleNameBlock")
		local lockBtn         = moudleNameBtn:getChildByName("lockBtn")
		moudleNameBlock:setVisible(true)
		lockBtn:setVisible(true)
	end

	-- update text
	local text = ""
	if moduleType == MODULE_TYPE.PRIVATE_ROOM then
		text = string.fmt("Lv _level_" , {_level_ = self.friendData.restaurantLevel})
		if not CommonUtils.CheckModuleIsExitByModuleId(JUMP_MODULE_DATA.BOX) then
			moudleNameBtn:setVisible(false)
		end
	elseif  moduleType == MODULE_TYPE.RESTAURANT then
		text = string.fmt("Lv _level_" , {_level_ = self.friendData.restaurantLevel})
	elseif  moduleType == MODULE_TYPE.FISH_PLACE then
		text = string.fmt("Lv _level_" , {_level_ = self.friendData.fishPlaceLevel})
	elseif  moduleType == MODULE_TYPE.WATER_BAR then
		text = string.fmt("Lv _level_" , {_level_ = self.friendData.barLevel})
	elseif  moduleType == MODULE_TYPE.CAT_HOUSE then
		text = string.fmt("Lv _level_" , {_level_ = self.friendData.houseLevel})
	end
	
	display.commonLabelParams(moudleNameBtn, {text = text .. ' ' .. tostring(moduleBtn.moduleName)})
end


--[[
　　---@Description: 进入动画
　　---@param :
　  ---@return :
　　---@author : xingweihao
　　---@date : 2018/8/30 9:01 PM
--]]
function HomelandMediator:OnEnterAction()
	local viewComponent= self:GetViewComponent()
	local viewData     = viewComponent.viewData
	local entranceList = {
		viewData.restaurantBtn,
		viewData.boxBtn,
		viewData.fishingGroundBtn,
		viewData.waterBarBtn,
		viewData.catHouseBtn,
	}
	local entranceSPosMap = {}
	local entranceEPosMap = {}
	local entranceActList = {}
	for index, entranceBtn in ipairs(entranceList) do
		local entranceStartPos = cc.p(entranceBtn:getPosition())
		local entranceEndedPos = cc.p(entranceBtn:getPositionX(), entranceBtn:getPositionY() + 300)
		entranceSPosMap[entranceBtn] = entranceStartPos
		entranceEPosMap[entranceBtn] = entranceEndedPos
		entranceBtn:setPosition(entranceEndedPos)
		entranceBtn:setOpacity(0)

		table.insert(entranceActList, cc.TargetedAction:create(entranceBtn,
			cc.Sequence:create(
				cc.DelayTime:create(0.1 * (index -1)),
				cc.Spawn:create(
					cc.JumpTo:create(0.3, entranceSPosMap[entranceBtn], -150 ,1),
					cc.FadeIn:create(0.3)
				),
				cc.DelayTime:create(0.2)
			)
		))
	end

	local seqAction = cc.Sequence:create(
		cc.FadeIn:create(0.2),
		cc.DelayTime:create(self.delayTimes),
		cc.Spawn:create(entranceActList),
		cc.CallFunc:create(function()
			self.isAction = false
		end)
	)
	viewComponent:setOpacity(0)
	viewComponent:runAction(seqAction)
end


function HomelandMediator:TransitionalSceneAction(scene, sender, callback)
	self.isAction = true
	local targetPos = sender:convertToWorldSpaceAR(utils.getLocalCenter(sender))
	local prevContentSnapshot = self:createSnapshot_(scene, targetPos)
	uiMgr:GetCurrentScene():AddDialog(prevContentSnapshot)
	prevContentSnapshot:setPosition(display.center)
	prevContentSnapshot:setReverseDirection(true)
	prevContentSnapshot:setPercentage(0.01)
	callback()
	prevContentSnapshot:runAction(
		cc.Sequence:create(
			cc.DelayTime:create(0.05),
			cc.EaseCubicActionIn:create(cc.ProgressTo:create(0.6, 100)),
			cc.RemoveSelf:create()
		)
	)
end
function HomelandMediator:createSnapshot_(viewObj, midPos)
	-- create the second render texture for outScene
	local texture = cc.RenderTexture:create(display.width, display.height)
	texture:setPosition(display.cx, display.cy)
	texture:setAnchorPoint(display.CENTER)

	-- render outScene to its texturebuffer
	texture:clear(0, 0, 0, 0)
	texture:begin()
	viewObj:visit()
	texture:endToLua()

	local middle = cc.ProgressTimer:create(texture:getSprite())
	middle:setType(cc.PROGRESS_TIMER_TYPE_BAR)
	-- Setup for a bar starting from the bottom since the midpoint is 0 for the y
	middle:setMidpoint(cc.p(midPos.x / display.width, (display.height - midPos.y) / display.height))
	-- middle:setMidpoint(display.CENTER)
	-- Setup for a vertical bar since the bar change rate is 0 for x meaning no horizontal change
	middle:setBarChangeRate(cc.p(1, 1))
	middle:setPosition(display.cx, display.cy)
	return middle
end


-------------------------------------------------
-- handler

function HomelandMediator:RestaurantButtonAction( sender )
    PlayAudioByClickNormal()
	if self.isAction then
		return
	end
	if CommonUtils.JuageMySelfOperation(self.playerId) then
		local callback =  function ()
			app.router:Dispatch({name = 'AvatarMediator'}, {name = 'AvatarMediator'})
		end
		self:TransitionalSceneAction(sceneWorld, sender, callback)
	else
		local friendId = self.playerId
		local friendAvatarMdt = AppFacade.GetInstance():RetrieveMediator('FriendAvatarMediator')

		if friendAvatarMdt then
			if friendAvatarMdt:getCurrentFriendId() ~= checkint(friendId) then
				friendAvatarMdt:setCurrentFriendId(friendId)
				AppFacade.GetInstance():DispatchObservers(UPDATE_LOBBY_FRIEND_LIST_SELECT_STATE, {friendId = friendId})
			end
		else
			friendAvatarMdt = require('Game.mediator.FriendAvatarMediator').new({friendId = friendId})
			AppFacade.GetInstance():RegistMediator(friendAvatarMdt)
			AppFacade.GetInstance():DispatchObservers(UPDATE_LOBBY_FRIEND_LIST_SELECT_STATE, {friendId = friendId})
		end
	end

end


function HomelandMediator:FishingGroundButtonAction( sender )
    PlayAudioByClickNormal()
	if self.isAction then
		return
	end
	if CommonUtils.JuageMySelfOperation(self.playerId) then
		if not CommonUtils.UnLockModule(JUMP_MODULE_DATA.FISHING_GROUND, true ) then
			return
		end
	else
		if not  self:CheckModuleIsUnLockByType_(MODULE_TYPE.FISH_PLACE)  then
			uiMgr:ShowInformationTips(string.fmt(__('好友的_function_尚未解锁'), {_function_ = tostring(sender.moduleName)}))
			return
		end
	end
	local callback =  function ()
		app.router:Dispatch({name = 'fishing.FishingGroundMediator'}, {name = 'fishing.FishingGroundMediator', params = {queryPlayerId =self.playerId}})
	end
	self:TransitionalSceneAction(sceneWorld, sender, callback)

end


function HomelandMediator:BoxButtonAction( sender )
	PlayAudioByClickNormal()
	if self.isAction  then
		return
	end
	if not  CommonUtils.CheckModuleIsExitByModuleId(JUMP_MODULE_DATA.BOX) then
		uiMgr:ShowInformationTips(__('敬请期待'))
		return
	end
	if CommonUtils.JuageMySelfOperation(self.playerId) then
		if not CommonUtils.UnLockModule(JUMP_MODULE_DATA.BOX , true ) then
			return
		end
		local callback =  function ()
			app.router:Dispatch({name = NAME}, {name = 'privateRoom.PrivateRoomHomeMediator'})
		end
		self:TransitionalSceneAction(sceneWorld, sender, callback)
	else
		if not  self:CheckModuleIsUnLockByType_(MODULE_TYPE.PRIVATE_ROOM)  then
			uiMgr:ShowInformationTips(string.fmt(__('好友的_function_尚未解锁'), {_function_ = tostring(sender.moduleName)}))
			return
		end
		local friendId = self.playerId
		local friendAvatarMdt = require('Game.mediator.privateRoom.PrivateRoomFriendMediator').new({friendId = friendId})
		AppFacade.GetInstance():RegistMediator(friendAvatarMdt)
	end
end


function HomelandMediator:WaterBarButtonAction(sender)
	PlayAudioByClickNormal()
	if self.isAction  then
		return
	end

	if CommonUtils.JuageMySelfOperation(self.playerId) then
		if not CommonUtils.UnLockModule(JUMP_MODULE_DATA.WATER_BAR, true ) then
			return
		end
		local callback =  function ()
			app.router:Dispatch({name = NAME}, {name = 'waterBar.WaterBarHomeMediator'})
		end
		self:TransitionalSceneAction(sceneWorld, sender, callback)
	else
		-- 好友并不能访问此功能
		-- if not self:CheckModuleIsUnLockByType_(MODULE_TYPE.WATER_BAR) then
		-- 	uiMgr:ShowInformationTips(string.fmt(__('好友的_function_尚未解锁'), {_function_ = tostring(sender.moduleName)}))
		-- 	return
		-- end
		-- local friendId  = self.playerId
		-- local friendAvatarMdt = require('Game.mediator.waterBar.WaterBarFriendMediator').new({friendId = friendId})
		-- AppFacade.GetInstance():RegistMediator(friendAvatarMdt)
	end
end


function HomelandMediator:CatHouseButtonAction(sender)
	PlayAudioByClickNormal()
	if self.isAction  then
		return
	end
	
	if CommonUtils.JuageMySelfOperation(self.playerId) then
		if not CommonUtils.UnLockModule(JUMP_MODULE_DATA.CAT_HOUSE , true ) then
			return
		end
		local callback =  function ()
			app.router:Dispatch({name = NAME}, {name = 'catHouse.CatHouseHomeMediator'}) 	
		end
		self:TransitionalSceneAction(sceneWorld, sender, callback)
	else
		if not  self:CheckModuleIsUnLockByType_(MODULE_TYPE.CAT_HOUSE)  then
			uiMgr:ShowInformationTips(string.fmt(__('好友的_function_尚未解锁'), {_function_ = tostring(sender.moduleName)}))
			return
		end
		local callback = function ()
			local friendId = self.playerId
			local friendAvatarMdt = require('Game.mediator.catHouse.CatHouseFriendAvatarMediator').new({friendId = friendId})
			AppFacade.GetInstance():RegistMediator(friendAvatarMdt)
			self.isAction = false
		end
		self:TransitionalSceneAction(sceneWorld, sender, callback)
	end
end


return HomelandMediator
