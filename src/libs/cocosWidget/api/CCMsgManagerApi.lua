---@meta


---@class cc.CCMsgManager : cc.Ref
local CCMsgManager = {}


---@return cc.CCMsgManager @ the single instance func
function CCMsgManager:getInstance()
end


--- frame called
function CCMsgManager:update()
end


--- post the message to this delegate on next frame, or
--- post the message to all delegates of game on next frame
---@param delegate cc.CCMsgDelegate
---@param msgId    integer
---@param msgObj?  table
---@overload fun(msgId:integer, msgObj:table):void
function CCMsgManager:PostMessage(delegate, msgId, msgObj)
end


--- register a new delegate for handle message
---@param delegate cc.CCMsgDelegate
function CCMsgManager:registerMsgDelegate(delegate)
end


--- unregister message
---@param delegate cc.CCMsgDelegate
function CCMsgManager:unregisterMsgDelegate(delegate)
end
