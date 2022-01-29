---@class Observer
local Observer = class("Observer")


---@param notifyMethod fun(context:any, signal:Signal):void
---@param notifyContext any
function Observer:ctor(notifyMethod, notifyContext )
	self.method = notifyMethod
	self.context = notifyContext
end


--[[
 * Get the Object that will serve as the Observers callback execution context
 * 执行回调方法
 * @private
 * @return {Object}
]]
---@param signal Signal
function Observer:Invoke( signal )
	if self.method then
		self.method(self.context, signal)
	end
	if self.methods then
		for _, method in ipairs(self.methods) do
			method(self.context, signal)
		end
	end
end


--[[
 * Compare an object to this Observers notification context.
 * 
 * @param {Object} object
 *  
 * @return {boolean}
]]
---@param nContext any
---@return boolean
function Observer:Compare( nContext )
	return (ID(self.context) == ID(nContext))
end


return Observer
