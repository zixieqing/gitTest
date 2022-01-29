---@class BaseModel
local BaseModel = class('BaseModel')


function BaseModel:ctor(modelName)
    self:initProperties_({
        {name = 'ModelName', value = modelName or 'BaseModel'}
    })
end


--[[
defineList is property define struct list, format is
{name:string, value:*, event:string, isForced:bool}
Notice: Any names begin with a capital letter.
]]
function BaseModel:initProperties_(defineList)
    for _, define in ipairs(defineList) do
		local propertyItem = define
		local propertyName = propertyItem.name .. '_'

		-- init property value
		if type(propertyItem.value) == 'table' then
			self[propertyName] = clone(propertyItem.value)
		else
			self[propertyName] = propertyItem.value
		end

		-- property getter method
		if type(propertyItem.value) == 'boolean' then
			self['is'.. propertyItem.name] = function()
				return self[propertyName]
			end
		else
			self['get' .. propertyItem.name] = function()
				return self[propertyName]
			end
		end

		-- property setter method
		if propertyItem.isReadOnly ~= true then
			self['set' .. propertyItem.name] = function(__, newValue)
				if self[propertyName] ~= newValue or propertyItem.isForced then
					local oldValue = self[propertyName]
					self[propertyName] = newValue
					if propertyItem.event then
						self:dispatchEvent_(propertyItem.event, {oldValue = oldValue, newValue = newValue})
					end
				end
			end
		end

	end
end


function BaseModel:getFacade_()
    return AppFacade.GetInstance()
end


function BaseModel:dispatchEvent_(signalName, body, type)
    self:getFacade_():DispatchObservers(signalName, body, type)
end


return BaseModel
