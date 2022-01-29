---@meta


---@class cc.CSceneManager : cc.Scene
---@field end fun():void @ end the game
local CSceneManager = {}


---@return cc.CSceneManager @ the single instance func
function CSceneManager:getInstance()
end


--- get the running scene, top of running scene stack
---@return cc.CSceneExtension
function CSceneManager:getRunningScene()
end


---@return boolean @ is send clean up
function CSceneManager:isSendCleanupToScene()
end


--- run scene when the game is first enter, just call once
---@param scene  cc.CSceneExtension
---@param extra? cc.Ref
function CSceneManager:runWithScene(scene, extra)
end


--- push the scene to top
---@param scene  cc.CSceneExtension
---@param extra? cc.Ref
function CSceneManager:pushScene(scene, extra)
end


--- replace running scene, the param scene will be running
---@param scene  cc.CSceneExtension
---@param extra? cc.Ref
function CSceneManager:replaceScene(scene, extra)
end


--- pop the top scene, if stack empty, it will end the game
---@param extra? cc.Ref
function CSceneManager:popScene(extra)
end


--- pop to the stack level 1
---@param extra? cc.Ref
function CSceneManager:popToRootScene(extra)
end


--- pop to the stack level, if the level < 1, will end the game
---@param level  integer
---@param extra? cc.Ref
function CSceneManager:popToSceneStackLevel(level, extra)
end


--- open a ui scene
---@param scene  cc.CSceneExtension
---@param extra? cc.Ref
function CSceneManager:runUIScene(scene, extra)
end


--- close a ui scene
---@param scene  cc.CSceneExtension
function CSceneManager:popUIScene(scene)
end


--- close all ui scene
function CSceneManager:popAllUIScene()
end


--- opan a suspend scene
---@param scene  cc.CSceneExtension
---@param extra? cc.Ref
function CSceneManager:runSuspendScene(scene, extra)
end


--- close a suspend scene
---@param scene  cc.CSceneExtension
function CSceneManager:popSuspendScene(scene)
end


--- close all Suspend scene
function CSceneManager:popAllSuspendScene()
end


--- is ui scene are running
---@param sceneName string
function CSceneManager:isSceneRunning(sceneName)
end


--- remove the cached scene from scene pool by scene name
---@param sceneName string
function CSceneManager:removeCachedScene(sceneName)
end


--- remove all cached scene from scene pool
function CSceneManager:removeAllCachedScenes()
end


--- remove all unused ( single reference ) scene from scene pool
function CSceneManager:removeUnusedCachedScenes()
end


--- registe the scene class when the game is first enter
---@param sceneName string
---@param createFunc fun():cc.CSceneExtension
function CSceneManager:registerSceneClassScriptFunc(sceneName, createFunc)
end


--- load scene if it not in scene pool
---@param sceneName string
---@return cc.CSceneExtension
function CSceneManager:loadScene(sceneName)
end


--- seek the scene from running stack and scene pool
---@param sceneName string
---@return cc.CSceneExtension
function CSceneManager:seekScene(sceneName)
end


---@return integer @ get the static touch priority, the touch priority will less 1 while every call
function CSceneManager:getTouchPriority()
end


---@return integer
function CSceneManager:getSceneSize()
end
