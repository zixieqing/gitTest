---@class ViewManager
local ViewManager = class("ViewManager")


---@type table<string, ViewManager>
ViewManager.instances = {}


---@param key string
function ViewManager:ctor( key )
	if ViewManager.instances[key] ~= nil then
		funLog(Logger.INFO, "注册相关的 mvc.ViewManager 类型" )
		return
	end
    ---@type string
	self.targetKey = key
    ---@type table<string, Mediator>
	self.mediatorMap = {}
    ---@type table<string, Observer[]>
	self.observersMap = {}
    ---@type Mediator[]
    self.mediatorStack = {} --用于记录所有当前视图信息的堆栈
	ViewManager.instances[key] = self
	self.InitialView()
end


function ViewManager:InitialView(  )
end


---@param key? string
---@return ViewManager
function ViewManager.GetInstance( key )
	if nil == key then
		return nil
	end
	if ViewManager.instances[key] == nil then
		ViewManager.instances[key] = ViewManager.new(key)
	end
	return ViewManager.instances[key]
end


---@param key string
function ViewManager.Destroy( key )
    local instance = ViewManager.instances[key]
    if instance then
        --清除缓存数据
        for name,val in pairs(instance.mediatorMap) do
            instance:UnRegistMediator(name)
        end
        instance.observersMap = {}
        instance.mediatorStack = {}
    end
    ViewManager.instances[key] = nil
end


---@param signalName string
---@param observer Observer
function ViewManager:RegistObserver( signalName, observer )
	if self.observersMap[signalName] ~= nil then
		if not self:HasObserver(self.observersMap[signalName],observer) then
			table.insert( self.observersMap[signalName],observer )
		else
			funLog(Logger.INFO, "当前通知里面已存在相同的observer" .. tostring(signalName))
		end
	else
		self.observersMap[signalName] = {observer}
	end
end


---@param observers Observer[]
---@param observer Observer
---@return boolean
function ViewManager:HasObserver( observers, observer )
	local has = false
	for k, o in pairs( observers ) do
		if o:Compare(observer.context) then
			has = true
			break
		end
	end
	return has
end


---@param signal Signal
function ViewManager:DispatchObservers( signal )
	local name = signal:GetName()
	if self.observersMap[name] ~= nil then
		local observers_ref = self.observersMap[name]
		for _, o in pairs(observers_ref) do
			o:Invoke(signal)
		end
	end
end


---@param signalName string
---@param notifyContext any
function ViewManager:UnRegistObserver( signalName, notifyContext)
	local observers = self.observersMap[signalName]
    if observers and next(observers) ~= nil then
        for k, o in pairs( observers ) do
            if o:Compare(notifyContext) then
                table.remove( observers, k )
                break
            end
        end
    end
	if observers == nil or table.nums(observers) == 0 then
		self.observersMap[signalName] = nil --清除通知
	end
end


--[[
mediator的相关注册
--]]
---@param mediator Mediator
function ViewManager:RegistMediator(mediator)
	local name = mediator:GetMediatorName()
    funLog(Logger.INFO,"ViewManager RegistMediator == ".. name )
    logs('+    mdt) ' .. name)
	if self.mediatorMap[name] ~= nil then
		return
	end
    mediator:Initial(self.targetKey)
    self.mediatorMap[name] = mediator
	local interests = mediator:InterestSignals()
	if next(interests) ~= nil then
        ---@type Observer
		local observer = mvc.Observer.new(mediator.ProcessSignal, mediator)
		for _, signalName in pairs(interests) do
			self:RegistObserver(signalName, observer)
		end
	end
	mediator:OnRegist()
    --最后方插入数据
    if name ~= 'AppMediator' and name ~= 'Router' then
        -- print('===================================================')
        local loc = 0
        local len = table.nums(self.mediatorStack)
        if len > 0 then
            local mediators = clone(self.mediatorStack)
            for idx,val in ipairs(mediators) do
                if val == name then
                    loc = idx
                    break
                end
            end
        end
        if loc <= 0 then
            table.insert(self.mediatorStack, name)
        end
        if mediator:AutoHiddenState() then
            -- print('===================================================')
            self:UpdatePurchageNodeState()
        end
        -- print('===================================================')
    end
end


function ViewManager:UpdatePurchageNodeState()
    if app.uiMgr then
        -- local name = self.mediatorStack[#self.mediatorStack]
        local excludes = {'BattleMediator','AuthorMediator','AvatarMediator', 'RaidBattleMediator', 'LobbyTaskMediator','CardEncyclopediaMediator',
                        'CardManualMediator', 'ExplorationMediator', 'ActivityMapMediator', 'PrivateRoomFriendMediator', 'link.popTeam.PopTeamStageMediator'}
        local hasExclude = false
        for idx,val in ipairs(self.mediatorStack) do
            if table.indexof(excludes, val) then
                hasExclude = true
                break
            end
        end
        if hasExclude then
            app.uiMgr:UpdatePurchageNodeState(false)
        else
            app.uiMgr:UpdatePurchageNodeState(true)
        end
        -- if table.indexof(excludes, name) then
            -- app.uiMgr:UpdatePurchageNodeState(false)
        -- else
            -- app.uiMgr:UpdatePurchageNodeState(true)
        -- end
    end
end


--[[
 * Retrieve a Mediator from the ViewManager
 *  The Mediator instance previously registered with the given mediatorName
]]
---@param mediatorName string
---@return Mediator
function ViewManager:RetrieveMediator(mediatorName)
	return self.mediatorMap[mediatorName]
end


--[[
    make sure return  currentScene mediator
--]]
---@return Mediator
function ViewManager:GetCurrentSceneMediator()
    local gameScene = app.uiMgr:GetCurrentScene()
    if not  gameScene then
        return
    end
    ---@param v Mediator
    for k , v  in pairs(self.mediatorMap) do
        if v.GetViewComponent then
            local view = v:GetViewComponent()
            if view then
                if  ID(view) == ID(gameScene) then
                    return v
                end
            end
        end
    end
    return nil
end


--[[
 *  The Mediator that was removed from the ViewManager
 * 删除注册
]]
---@param mediatorName string
---@return Mediator
function ViewManager:UnRegistMediator(mediatorName)
    local mediator = self.mediatorMap[mediatorName]
    logs('-    mdt) ' .. tostring(mediatorName))
	if mediator ~= nil then
		local interests = mediator:InterestSignals()
		for _, signalName in pairs(interests) do
			self:UnRegistObserver(signalName, mediator)
		end
		self.mediatorMap[mediatorName] = nil
        --弹出一条数据
        if mediatorName ~= 'AppMediator' and mediatorName ~= 'Router' then
            funLog(Logger.INFO, "------mediator UnRegistMediator --" .. mediatorName)
            -- dump(self.mediatorStack)

            local loc = 0
            local len = table.nums(self.mediatorStack)
            if len > 0 then
                ---@type Mediator[]
                local mediators = clone(self.mediatorStack)
                for idx,val in pairs(mediators) do
                    if val == mediatorName then
                        loc = idx
                        break
                    end
                end
            end
            -- print('-----------------UnRegistMediator--------------')
            -- print('-----',loc)
            -- print('-------------------UnRegistMediator-----------')
            if loc > 0 then
                table.remove(self.mediatorStack, loc)
            end
            -- dump(self.mediatorStack)
        end
        mediator:CleanupView() --移除视图的逻辑功能
		mediator:OnUnRegist()
    end
	return mediator
end


---@return string
function ViewManager:ClearStack()
    local len = table.nums(self.mediatorStack)
    local upgradeMediatorName = nil
    if len > 0 then
        ---@type Mediator[]
        local mediators = clone(self.mediatorStack)
        for idx,val in pairs(mediators) do
            if val ~= 'UpgradeLevelMediator' then
                self:UnRegistMediator(val)
            else
                upgradeMediatorName = val --不清除暂存起来的逻辑
            end
        end
    end
    return upgradeMediatorName
end


--[[
--弹出一级页面
--]]
---@param isRoot? boolean
function ViewManager:PopMediator(isRoot)
    local len = table.nums(self.mediatorStack)
    if len > 1 then
        local mediators = clone(self.mediatorStack)
        if isRoot then
            for i=len,2,-1 do
                local mediatorName = mediators[i]
                self:UnRegistMediator(mediatorName)
            end
        else
            local mediatorName = mediators[len]
            self:UnRegistMediator(mediatorName)
        end
    else
        self:ClearStack()
        local mediatorPath = require( string.format('Game.mediator.%s', 'HomeMediator'))
        local mediator = mediatorPath.new()
        self:RegistMediator(mediator)
    end
end


--[[
--回退到指定的页面
--@mediator 回退到指定的mediator
--]]
---@param mediatorName string
function ViewManager:BackMediator(mediatorName)
    local loc = 0
    local len = table.nums(self.mediatorStack)
    if len > 0 then
        ---@type Mediator[]
        local mediators = clone(self.mediatorStack)
        for idx,val in ipairs(mediators) do
            if val == mediatorName then
                loc = idx
                break
            end
        end
        --开始弹出页面
        funLog(Logger.INFO, "the view stack [LOC] = " .. tostring(loc) .. '[LEN]= ' .. tostring(len))
        if loc > 0 then
            if (loc + 1) <= len then
                for i=(loc + 1),len,1 do
                    local name = mediators[i]
                    self:UnRegistMediator(name)
                end
            end
        end
    end
end


--[[
 * Check if a Mediator is registered or not.
 * 是否存在mediator
]]
---@param mediatorName string
---@return boolean
function ViewManager:HasMediator(mediatorName)
	return self.mediatorMap[mediatorName] ~= nil
end


---@return integer
function ViewManager:GetMediatorStackNum()
    return table.nums(self.mediatorStack)
end


return ViewManager
