--模拟枚举
local enumt = {
	__index = function(table, key)
		if rawget(table.enums,key) then
			return rawget(table.enums,key)
		end
	end
}
--[[
字义的枚举类型
--]]
function Enum(t)
	local e = {enums = t}
	return setmetatable(e, enumt)
end


--[[
    定义 只读属性的 table
]]
function readOnly(t)
    local proxy = {}
    local mt = {
        __index = t,
        __newindex = function(t, k, v)
            error('attempt to update a read-only table', 2)
        end
    }
    setmetatable(proxy, mt)
    return proxy
end


utf8 = require('root.utf8')


mvc = mvc or {}
mvc.VERSION = '0.1.2'

---@type Signal
mvc.Signal        = require( 'Frame.mvc.Signal' ) -- is Notification
---@type Dispatch
mvc.Dispatch      = require( 'Frame.mvc.Dispatch' ) -- is Notifier
---@type Observer
mvc.Observer      = require( 'Frame.mvc.Observer' )
---@type Proxy
mvc.Proxy         = require( 'Frame.mvc.Proxy' )
---@type SimpleCommand
mvc.SimpleCommand = require( 'Frame.mvc.SimpleCommand' )
---@type QueueCommand
mvc.QueueCommand  = require( 'Frame.mvc.QueueCommand' )
---@type Mediator
mvc.Mediator      = require( 'Frame.mvc.Mediator' )
---@type Controller
mvc.Controller    = require( 'Frame.mvc.Controller' )
---@type ViewManager
mvc.ViewManager   = require( 'Frame.mvc.ViewManager' ) -- is view
---@type ModelGroup
mvc.ModelGroup    = require( 'Frame.mvc.ModelGroup' ) -- is model
---@type Facade
mvc.Facade        = require( 'Frame.mvc.Facade' )
