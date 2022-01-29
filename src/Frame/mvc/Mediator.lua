---@class Mediator : Dispatch
local Mediator = class("Mediator", mvc.Dispatch)


Mediator.NAME = 'Mediator'


---@param mediatorName string
---@param viewComponent cc.Node
function Mediator:ctor(mediatorName, viewComponent)
	mvc.Dispatch.ctor(self)
	self.mediatorName = mediatorName or Mediator.NAME
	self.viewComponent = viewComponent
	self.payload = nil
	self.initLayerData = nil --显示指定页面信息数据
end


---@return string
function Mediator:GetMediatorName(  )
	return self.mediatorName
end


---@param viewComponent cc.Node
function Mediator:SetViewComponent( viewComponent )
	self.viewComponent = viewComponent
end


---@return cc.Node
function Mediator:GetViewComponent(  )
	return self.viewComponent
end


--[[
注册所关心的信号
抽象方法
--]]
---@return string[]
function Mediator:InterestSignals( )
	return {}
end


function Mediator:CleanupView()
    --对视图组件的移除的相关操作,子类可以重写操作
end


---@param signal Signal
function Mediator:ProcessSignal( signal )
end


function Mediator:OnRegist(  )
end


function Mediator:OnUnRegist(  )
end


function Mediator:AutoHiddenState(  )
	return true
end


return Mediator
