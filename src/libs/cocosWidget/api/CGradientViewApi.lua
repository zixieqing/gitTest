---@meta


---@class CGradientView : CColorView
local CGradientView = {}


---@param startColor? cc.c4b
---@param endColor? cc.c4b
---@param vector? cc.p
---@return CGradientView
function CGradientView:create(startColor, endColor, vector)
end


---@return boolean
function CGradientView:init()
end


---@param startColor cc.c4b
---@param endColor cc.c4b
---@param vector? cc.p
---@return boolean
function CGradientView:initWithColor(startColor, endColor, vector)
end


---@param color cc.c3b
function CGradientView:setStartColor(color)
end


---@return cc.c3b
function CGradientView:getStartColor()
end


---@param opacity integer @ value range 0~255
function CGradientView:setStartOpacity(opacity)
end


---@return integer
function CGradientView:getStartOpacity()
end


---@param color cc.c3b
function CGradientView:setEndColor(color)
end


---@return cc.c3b
function CGradientView:getEndColor()
end


---@param opacity integer @ value range 0~255
function CGradientView:setEndOpacity(opacity)
end


---@return integer
function CGradientView:getEndOpacity()
end


---@param point cc.p
function CGradientView:setVector(point)
end


---@return cc.p
function CGradientView:getVector()
end


---@param isCompressedInterpolation boolean
function CGradientView:setCompressedInterpolation(isCompressedInterpolation)
end


---@return boolean
function CGradientView:isCompressedInterpolation()
end
