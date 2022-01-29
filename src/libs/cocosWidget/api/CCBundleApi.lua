---@meta


---@class cc.CCBundle : cc.Ref
local CCBundle = {}


---@return cc.CCBundle
function CCBundle:create()
end


---@param key string
---@param value integer
function CCBundle:putShort(key, value)
end


---@param key string
---@return integer
function CCBundle:getShort(key)
end


---@param key string
---@param value integer
function CCBundle:putUShort(key, value)
end


---@param key string
---@return integer
function CCBundle:getUShort(key)
end


---@param key string
---@param value integer
function CCBundle:putInt(key, value)
end


---@param key string
---@return integer
function CCBundle:getInt(key)
end


---@param key string
---@param value integer
function CCBundle:putUInt(key, value)
end


---@param key string
---@return integer
function CCBundle:getUInt(key)
end


---@param key string
---@param value number
function CCBundle:putFloat(key, value)
end


---@param key string
---@return number
function CCBundle:getFloat(key)
end


---@param key string
---@param value number
function CCBundle:putDouble(key, value)
end


---@param key string
---@return number
function CCBundle:getDouble(key)
end


---@param key string
---@param value string
function CCBundle:putString(key, value)
end


---@param key string
---@return string
function CCBundle:getString(key)
end


---@param key string
---@param value cc.CCBundle
function CCBundle:putBundle(key, value)
end


---@param key string
---@return cc.CCBundle
function CCBundle:getBundle(key)
end


---@param key string
---@param value cc.Ref
function CCBundle:putObject(key, value)
end


---@param key string
---@return cc.Ref
function CCBundle:getObject(key)
end
