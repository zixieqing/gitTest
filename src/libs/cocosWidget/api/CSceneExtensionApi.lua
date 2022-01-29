---@meta


---@class cc.CSceneExtension : CWidgetWindow
local CSceneExtension = {}


---@return cc.CSceneExtension
function CSceneExtension:create()
end


---@return boolean
function CSceneExtension:init()
end


---@param bAuto boolean @ is auto remove unused texture on scene destory
function CSceneExtension:setAutoRemoveUnusedTexture(bAuto)
end


---@return boolean @ is auto remove on scene destory
function CSceneExtension:isAutoRemoveUnusedTexture()
end


---@param bCachable boolean @ set true it will be a cachable scene
function CSceneExtension:setCachable(bCachable)
end


---@return boolean @ is a cachable scene ?
function CSceneExtension:isCachable()
end


---@param className string @ set the class name for scene
function CSceneExtension:setClassName(className)
end


---@return string @ get class name, work on every time
function CSceneExtension:getClassName()
end


---@param extraObject cc.Ref @ set the extra data
function CSceneExtension:setExtraObject(extraObject)
end


---@return cc.Ref @ get extra data
function CSceneExtension:getExtraObject()
end


--- add image in sync, it will block the main loop for a while
function CSceneExtension:addImage()
end


--- add image in async, it will not block the main loop
function CSceneExtension:addImageAsync()
end


---@return boolean @ is this scene is already loaded ?
function CSceneExtension:isLoaded()
end


--- the first call, load resources if needed, it will call just once
function CSceneExtension:onLoadResources()
end


--- the seconed call, load completed, it will call just once
function CSceneExtension:onLoadResourcesCompleted()
end


---@param handler fun():void
function CSceneExtension:setOnLoadResourcesScriptHandler(handler)
end


---@param handler fun():void
function CSceneExtension:setOnLoadResourcesCompletedScriptHandler(handler)
end


---@param handler fun():void
function CSceneExtension:setOnLoadRescourcesProgressScriptHandler(handler)
end


---@param handler fun(messageObj:table):void
function CSceneExtension:setOnMessageScriptHandler(handler)
end
