--[[
黑市
--]]
local ManagerBase = require( "Frame.Manager.ManagerBase" )
---@class BlackGoldManager : ManagerBase
local BlackGoldManager = class('BlackGoldManager',ManagerBase)
local BLACK_GOLD_COUNT_DOWN =  "BLACK_GOLD_COUNT_DOWN"
BlackGoldManager.instances = {}
local BUSINESS_STATUS = {
	OUT_TO_SEA = 1 ,
	SHORE = 2
}
function BlackGoldManager:ctor( key )
	self.super.ctor(self)
	self.spineCache = false
	if BlackGoldManager.instances[key] ~= nil then
		funLog(Logger.INFO,"注册相关的facade类型" )
		return
	end
	self.homeData = {}
	self:OnRegist()
	self.spineTable = {
		GOLD_HOME_RUDDER = 'ui/home/blackShop/effect/gold_home_rudder',
		GOLD_TRADE_BARD  = 'ui/home/blackShop/effect/gold_trade_bard',
		GOLD_TRADE_PAPER = 'ui/home/blackShop/effect/gold_trade_paper',
	}
	self.parseConfig = nil
	BlackGoldManager.instances[key] = self
end

function BlackGoldManager:ProcessSignal(signal)
	local data = signal:GetBody()
	local name = signal:GetName()
	if name  == POST.COMMERCE_HOME.sglName  then
		self:InitData(data)
		self:AddTimer()
	end
end


function BlackGoldManager:AddTimer()
	local timerMgr = self:GetTimerManager()
	timerMgr:AddTimer({name = BLACK_GOLD_COUNT_DOWN , countdown = self.homeData.leftSeconds , callback = handler(self, self.UpdateCountdownTimes), autoDelete = true})
end
function BlackGoldManager:GetLeftSeconds()
	return self.homeData.leftSeconds
end
function BlackGoldManager:UpdateCountdownTimes(coutdown)
	self.homeData.leftSeconds  = coutdown
	self:GetFacade():DispatchObservers(SGL.FRESH_BLACK_GOLD_COUNT_DOWN_EVENT)
	if coutdown == 0  then
		self:FreshBlackData()
	end
end


function BlackGoldManager:GetWarehouseGrade()
	return checkint(self.homeData.warehouseGrade)
end


function BlackGoldManager:GetTitleGrade()
	return checkint(self.homeData.titleGrade)
end

function BlackGoldManager:GetStatus()
	return self.homeData.status
end

function BlackGoldManager:SetWarehouseGrade(warehouseGrade)
	self.homeData.warehouseGrade = warehouseGrade
end

function BlackGoldManager:SetTitleGrade(titleGrade)
	self.homeData.titleGrade = titleGrade
end

function BlackGoldManager:SetStatus(status)
	self.homeData.status = status
end

function BlackGoldManager.GetInstance(key)
	key = (key or "BlackGoldManager")
	if BlackGoldManager.instances[key] == nil then
		BlackGoldManager.instances[key] = BlackGoldManager.new(key)
	end
	return BlackGoldManager.instances[key]
end

function BlackGoldManager:AddSpineCache()
	if not  self.spineCache then
		self.spineCache = true
		local shareSpineCache = SpineCache(SpineCacheName.BLACK_GOLD)
		for spineName , spinePath in pairs(self.spineTable) do
			shareSpineCache:addCacheData(spinePath, spinePath, 1)
		end
	end
end

function BlackGoldManager:RemoveSpineCache()
	if self.spineCache then
		local shareSpineCache = SpineCache(SpineCacheName.BLACK_GOLD)
		for spineName , spinePath in pairs(self.spineTable) do
			shareSpineCache:removeCacheData(spinePath)
		end
		self.spineCache = false
	end
end


function BlackGoldManager:InitData(data)
	self.homeData = data
	self.homeData.titleGrade = checkint(data.titleGrade)
	self.homeData.status = checkint(data.status)
	self.homeData.leftSeconds = checkint(data.leftSeconds)
end


function BlackGoldManager:GetFuturesPtahByFutureId(futuresId)
	local path = _res(string.format("ui/home/blackShop/futures/gold_trade_goods_%s", tostring(futuresId)) )
	return path
end

function BlackGoldManager:FreshBlackData()
	if checkint(self.homeData.leftSeconds)  > 0   then

	else
		AppFacade.GetInstance():DispatchSignal(POST.COMMERCE_HOME.cmdName , { })
	end
end
--[[
	是否可以进行交易
--]]
function BlackGoldManager:GetIsTrade()
	if self:GetStatus() == BUSINESS_STATUS.OUT_TO_SEA then
		return false
	else
		return true
	end
end
---@Description: 获取homeData 的数据
---@author : xingweihao
---@date : 2018/10/16 11:31 AM
--==============================--
function BlackGoldManager:GetHomeData()
	return self.homeData
end


function BlackGoldManager:OnRegist()
	regPost(POST.COMMERCE_HOME)
	---@type Observer
	app:RegistObserver(POST.COMMERCE_HOME.sglName, mvc.Observer.new(self.ProcessSignal, self))
end
function BlackGoldManager:OnUnRegist()
	unregPost(POST.COMMERCE_HOME)
	app:UnRegistObserver(POST.COMMERCE_HOME.sglName, self)
end


function BlackGoldManager.Destroy( key )
	key = (key or "BlackGoldManager")
	if BlackGoldManager.instances[key] == nil then
		return
	end
	BlackGoldManager.instances[key]:OnUnRegist()
	BlackGoldManager.instances[key] = nil
end


return BlackGoldManager
