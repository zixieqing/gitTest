---@meta


-------------------------------------------------------------------------------
-- CCSceneExTransition
-------------------------------------------------------------------------------

--- Base class for CCTransition scenes
---@class cc.CCSceneExTransition : cc.CSceneExtension
local CCSceneExTransition = {}


--- creates a base transition with duration and incoming scene
---@param duration number
---@param scene cc.CSceneExtension
---@return cc.CCSceneExTransition
function CCSceneExTransition:create(duration, scene)
end


--- initializes a transition with duration and incoming scene
---@param duration number
---@param scene cc.CSceneExtension
---@return boolean
function CCSceneExTransition:initWithDuration(duration, scene)
end


---@return cc.CSceneExtension
function CCSceneExTransition:getInScene()
end


--- called after the transition finishes
function CCSceneExTransition:finish()
end


--- used by some transitions to hide the outer scene
function CCSceneExTransition:hideOutShowIn()
end


---@param renderer cc.Renderer
---@param transform cc.mat4
---@param flags integer
function CCSceneExTransition:draw(renderer, transform, flags)
end


function CCSceneExTransition:cleanup()
end


-------------------------------------------------------------------------------
-- CCSceneExTransitionEase
-------------------------------------------------------------------------------

--- CCTransitionEaseScene can ease the actions of the scene protocol.
---@class cc.CCSceneExTransitionEase
local CCSceneExTransitionEase = {}


--- returns the Ease action that will be performed on a linear action.
---@param action cc.ActionInterval
---@return cc.ActionInterval
function CCSceneExTransitionEase:easeActionWithAction(action)
end


-------------------------------------------------------------------------------
-- CCSceneExTransitionOriented
-------------------------------------------------------------------------------

--- A CCTransition that supports orientation like. 
--- Possible orientation: LeftOver, RightOver, UpOver, DownOver
---@class cc.CCSceneExTransitionOriented : cc.CCSceneExTransition
local CCSceneExTransitionOriented = {}


---@param duration number
---@param scene cc.CSceneExtension
---@param orientation integer
---@see cc#TRANSITION_ORIENTATION_UP_OVER
---@see cc#TRANSITION_ORIENTATION_DOWN_OVER
---@see cc#TRANSITION_ORIENTATION_LEFT_OVER
---@see cc#TRANSITION_ORIENTATION_RIGHT_OVER
---@return cc.CCSceneExTransition
function CCSceneExTransitionOriented:create(duration, scene, orientation)
end


---@param duration number
---@param scene cc.CSceneExtension
---@param orientation integer
---@see cc#TRANSITION_ORIENTATION_UP_OVER
---@see cc#TRANSITION_ORIENTATION_DOWN_OVER
---@see cc#TRANSITION_ORIENTATION_LEFT_OVER
---@see cc#TRANSITION_ORIENTATION_RIGHT_OVER
---@return boolean
function CCSceneExTransitionOriented:initWithDuration(duration, scene, orientation)
end


-------------------------------------------------------------------------------
-- CCSceneExTransitionZoomFlipX
-------------------------------------------------------------------------------

--- Flips the screen horizontally doing a zoom out/in 
--- The front face is the outgoing scene and the back face is the incoming scene.
---@class cc.CCSceneExTransitionZoomFlipX : cc.CCSceneExTransitionOriented
local CCSceneExTransitionZoomFlipX = {}


---@param duration number
---@param scene cc.CSceneExtension
---@param orientation? integer
---@see cc#TRANSITION_ORIENTATION_LEFT_OVER
---@see cc#TRANSITION_ORIENTATION_RIGHT_OVER
---@return cc.CCSceneExTransitionZoomFlipX
function CCSceneExTransitionZoomFlipX:create(duration, scene, orientation)
end


-------------------------------------------------------------------------------
-- CCSceneExTransitionZoomFlipY
-------------------------------------------------------------------------------

--- Flips the screen vertically doing a little zooming out/in 
--- The front face is the outgoing scene and the back face is the incoming scene.
---@class cc.CCSceneExTransitionZoomFlipY : cc.CCSceneExTransitionOriented
local CCSceneExTransitionZoomFlipY = {}


---@param duration number
---@param scene cc.CSceneExtension
---@param orientation? integer
---@see cc#TRANSITION_ORIENTATION_UP_OVER
---@see cc#TRANSITION_ORIENTATION_DOWN_OVER
---@return cc.CCSceneExTransitionZoomFlipY
function CCSceneExTransitionZoomFlipY:create(duration, scene, orientation)
end


-------------------------------------------------------------------------------
-- CCSceneExTransitionFlipX
-------------------------------------------------------------------------------

--- Flips the screen horizontally. 
--- The front face is the outgoing scene and the back face is the incoming scene.
---@class cc.CCSceneExTransitionFlipX : cc.CCSceneExTransitionOriented
local CCSceneExTransitionFlipX = {}


---@param duration number
---@param scene cc.CSceneExtension
---@param orientation? integer
---@see cc#TRANSITION_ORIENTATION_LEFT_OVER
---@see cc#TRANSITION_ORIENTATION_RIGHT_OVER
---@return cc.CCSceneExTransitionFlipX
function CCSceneExTransitionFlipX:create(duration, scene, orientation)
end


-------------------------------------------------------------------------------
-- CCSceneExTransitionFlipY
-------------------------------------------------------------------------------

--- Flips the screen vertically. 
--- The front face is the outgoing scene and the back face is the incoming scene.
---@class cc.CCSceneExTransitionFlipY : cc.CCSceneExTransitionOriented
local CCSceneExTransitionFlipY = {}


---@param duration number
---@param scene cc.CSceneExtension
---@param orientation? integer
---@see cc#TRANSITION_ORIENTATION_LEFT_OVER
---@see cc#TRANSITION_ORIENTATION_RIGHT_OVER
---@return cc.CCSceneExTransitionFlipY
function CCSceneExTransitionFlipY:create(duration, scene, orientation)
end


-------------------------------------------------------------------------------
-- CCSceneExTransitionFlipAngular
-------------------------------------------------------------------------------

--- Flips the screen half horizontally and half vertically. 
--- The front face is the outgoing scene and the back face is the incoming scene.
---@class cc.CCSceneExTransitionFlipAngular : cc.CCSceneExTransitionOriented
local CCSceneExTransitionFlipAngular = {}


---@param duration number
---@param scene cc.CSceneExtension
---@param orientation? integer
---@see cc#TRANSITION_ORIENTATION_UP_OVER
---@see cc#TRANSITION_ORIENTATION_DOWN_OVER
---@see cc#TRANSITION_ORIENTATION_LEFT_OVER
---@see cc#TRANSITION_ORIENTATION_RIGHT_OVER
---@return cc.CCSceneExTransitionFlipAngular
function CCSceneExTransitionFlipAngular:create(duration, scene, orientation)
end


-------------------------------------------------------------------------------
-- CCSceneExTransitionZoomFlipAngular
-------------------------------------------------------------------------------

--- Flips the screen half horizontally and half vertically doing a little zooming out/in. 
--- The front face is the outgoing scene and the back face is the incoming scene.
---@class cc.CCSceneExTransitionZoomFlipAngular : cc.CCSceneExTransitionOriented
local CCSceneExTransitionZoomFlipAngular = {}


---@param duration number
---@param scene cc.CSceneExtension
---@param orientation? integer
---@see cc#TRANSITION_ORIENTATION_UP_OVER
---@see cc#TRANSITION_ORIENTATION_DOWN_OVER
---@see cc#TRANSITION_ORIENTATION_LEFT_OVER
---@see cc#TRANSITION_ORIENTATION_RIGHT_OVER
---@return cc.CCSceneExTransitionZoomFlipAngular
function CCSceneExTransitionZoomFlipAngular:create(duration, scene, orientation)
end


-------------------------------------------------------------------------------
-- CCSceneExTransitionProgress
-------------------------------------------------------------------------------

---@class cc.CCSceneExTransitionProgress : cc.CCSceneExTransition
local CCSceneExTransitionProgress = {}


---@param duration number
---@param scene cc.CSceneExtension
---@return cc.CCSceneExTransitionProgress
function CCSceneExTransitionProgress:create(duration, scene)
end


-------------------------------------------------------------------------------
-- CCSceneExTransitionProgressInOut
-------------------------------------------------------------------------------

---@class cc.CCSceneExTransitionProgressInOut : cc.CCSceneExTransitionProgress
local CCSceneExTransitionProgressInOut = {}


---@param duration number
---@param scene cc.CSceneExtension
---@return cc.CCSceneExTransitionProgressInOut
function CCSceneExTransitionProgressInOut:create(duration, scene)
end


-------------------------------------------------------------------------------
-- CCSceneExTransitionProgressOutIn
-------------------------------------------------------------------------------

---@class cc.CCSceneExTransitionProgressOutIn : cc.CCSceneExTransitionProgress
local CCSceneExTransitionProgressOutIn = {}


---@param duration number
---@param scene cc.CSceneExtension
---@return cc.CCSceneExTransitionProgressOutIn
function CCSceneExTransitionProgressOutIn:create(duration, scene)
end


-------------------------------------------------------------------------------
-- CCSceneExTransitionProgressVertical
-------------------------------------------------------------------------------

---@class cc.CCSceneExTransitionProgressVertical : cc.CCSceneExTransitionProgress
local CCSceneExTransitionProgressVertical = {}


---@param duration number
---@param scene cc.CSceneExtension
---@return cc.CCSceneExTransitionProgressVertical
function CCSceneExTransitionProgressVertical:create(duration, scene)
end


-------------------------------------------------------------------------------
-- CCSceneExTransitionProgressHorizontal
-------------------------------------------------------------------------------

--- CCTransitionProgressHorizontal transition. 
--- A  clock-wise radial transition to the next scene
---@class cc.CCSceneExTransitionProgressHorizontal : cc.CCSceneExTransitionProgress
local CCSceneExTransitionProgressHorizontal = {}


---@param duration number
---@param scene cc.CSceneExtension
---@return cc.CCSceneExTransitionProgressHorizontal
function CCSceneExTransitionProgressHorizontal:create(duration, scene)
end


-------------------------------------------------------------------------------
-- CCSceneExTransitionProgressRadialCW
-------------------------------------------------------------------------------

--- A counter clock-wise radial transition to the next scene
---@class cc.CCSceneExTransitionProgressRadialCW : cc.CCSceneExTransitionProgress
local CCSceneExTransitionProgressRadialCW = {}


---@param duration number
---@param scene cc.CSceneExtension
---@return cc.CCSceneExTransitionProgressRadialCW
function CCSceneExTransitionProgressRadialCW:create(duration, scene)
end


-------------------------------------------------------------------------------
-- CCSceneExTransitionProgressRadialCCW
-------------------------------------------------------------------------------

--- A counter clock-wise radial transition to the next scene
---@class cc.CCSceneExTransitionProgressRadialCCW : cc.CCSceneExTransitionProgress
local CCSceneExTransitionProgressRadialCCW = {}


---@param duration number
---@param scene cc.CSceneExtension
---@return cc.CCSceneExTransitionProgressRadialCCW
function CCSceneExTransitionProgressRadialCCW:create(duration, scene)
end


-------------------------------------------------------------------------------
-- CCSceneExTransitionFade
-------------------------------------------------------------------------------

--- Fade out the outgoing scene and then fade in the incoming scene.
---@class cc.CCSceneExTransitionFade : cc.CCSceneExTransition
local CCSceneExTransitionFade = {}


---@param duration number
---@param scene cc.CSceneExtension
---@param color? cc.c3b
---@return cc.CCSceneExTransitionFade
function CCSceneExTransitionFade:create(duration, scene, color)
end


---@param duration number
---@param scene cc.CSceneExtension
---@param color? cc.c3b
---@return boolean
function CCSceneExTransitionFade:initWithDuration(duration, scene, color)
end


-------------------------------------------------------------------------------
-- CCSceneExTransitionFadeTR
-------------------------------------------------------------------------------

--- Fade the tiles of the outgoing scene from the left-bottom corner the to top-right corner.
---@class cc.CCSceneExTransitionFadeTR : cc.CCSceneExTransition
local CCSceneExTransitionFadeTR = {}


---@param duration number
---@param scene cc.CSceneExtension
---@return cc.CCSceneExTransitionFadeTR
function CCSceneExTransitionFadeTR:create(duration, scene)
end


---@param size cc.size
---@return cc.ActionInterval
function CCSceneExTransitionFadeTR:actionWithSize(size)
end


--- returns the Ease action that will be performed on a linear action.
---@param action cc.ActionInterval
---@return cc.ActionInterval
function CCSceneExTransitionFadeTR:easeActionWithAction(action)
end


-------------------------------------------------------------------------------
-- CCSceneExTransitionFadeBL
-------------------------------------------------------------------------------

--- Fade the tiles of the outgoing scene from the top-right corner to the bottom-left corner.
---@class cc.CCSceneExTransitionFadeBL : cc.CCSceneExTransitionFadeTR
local CCSceneExTransitionFadeBL = {}


---@param duration number
---@param scene cc.CSceneExtension
---@return cc.CCSceneExTransitionFadeBL
function CCSceneExTransitionFadeBL:create(duration, scene)
end


-------------------------------------------------------------------------------
-- CCSceneExTransitionFadeUp
-------------------------------------------------------------------------------

--- Fade the tiles of the outgoing scene from the bottom to the top.
---@class cc.CCSceneExTransitionFadeUp : cc.CCSceneExTransitionFadeTR
local CCSceneExTransitionFadeUp = {}


---@param duration number
---@param scene cc.CSceneExtension
---@return cc.CCSceneExTransitionFadeUp
function CCSceneExTransitionFadeUp:create(duration, scene)
end


-------------------------------------------------------------------------------
-- CCSceneExTransitionFadeDown
-------------------------------------------------------------------------------

--- Fade the tiles of the outgoing scene from the top to the bottom.
---@class cc.CCSceneExTransitionFadeDown : cc.CCSceneExTransitionFadeTR
local CCSceneExTransitionFadeDown = {}


---@param duration number
---@param scene cc.CSceneExtension
---@return cc.CCSceneExTransitionFadeDown
function CCSceneExTransitionFadeDown:create(duration, scene)
end


-------------------------------------------------------------------------------
-- CCSceneExTransitionSlideInL
-------------------------------------------------------------------------------

--- Slide in the incoming scene from the left border.
---@class cc.CCSceneExTransitionSlideInL : cc.CCSceneExTransition
local CCSceneExTransitionSlideInL = {}


---@param duration number
---@param scene cc.CSceneExtension
---@return cc.CCSceneExTransitionSlideInL
function CCSceneExTransitionSlideInL:create(duration, scene)
end


--- initializes the scenes
function CCSceneExTransitionSlideInL:initScenes()
end


--- returns the action that will be performed by the incoming and outgoing scene
---@return cc.ActionInterval
function CCSceneExTransitionSlideInL:action()
end


--- returns the Ease action that will be performed on a linear action.
---@param action cc.ActionInterval
---@return cc.ActionInterval
function CCSceneExTransitionSlideInL:easeActionWithAction(action)
end


-------------------------------------------------------------------------------
-- CCSceneExTransitionSlideInR
-------------------------------------------------------------------------------

--- Slide in the incoming scene from the right border.
---@class cc.CCSceneExTransitionSlideInR : cc.CCSceneExTransitionSlideInL
local CCSceneExTransitionSlideInR = {}


---@param duration number
---@param scene cc.CSceneExtension
---@return cc.CCSceneExTransitionSlideInR
function CCSceneExTransitionSlideInR:create(duration, scene)
end


-------------------------------------------------------------------------------
-- CCSceneExTransitionSlideInB
-------------------------------------------------------------------------------

--- Slide in the incoming scene from the bottom border.
---@class cc.CCSceneExTransitionSlideInB : cc.CCSceneExTransitionSlideInL
local CCSceneExTransitionSlideInB = {}


---@param duration number
---@param scene cc.CSceneExtension
---@return cc.CCSceneExTransitionSlideInB
function CCSceneExTransitionSlideInB:create(duration, scene)
end


-------------------------------------------------------------------------------
-- CCSceneExTransitionSlideInT
-------------------------------------------------------------------------------

--- Slide in the incoming scene from the top border.
---@class cc.CCSceneExTransitionSlideInT : cc.CCSceneExTransitionSlideInL
local CCSceneExTransitionSlideInT = {}


---@param duration number
---@param scene cc.CSceneExtension
---@return cc.CCSceneExTransitionSlideInT
function CCSceneExTransitionSlideInT:create(duration, scene)
end


-------------------------------------------------------------------------------
-- CCSceneExTransitionSplitCols
-------------------------------------------------------------------------------

--- The odd columns goes upwards while the even columns goes downwards.
---@class cc.CCSceneExTransitionSplitCols : cc.CCSceneExTransition
local CCSceneExTransitionSplitCols = {}


---@param duration number
---@param scene cc.CSceneExtension
---@return cc.CCSceneExTransitionSplitCols
function CCSceneExTransitionSplitCols:create(duration, scene)
end


---@return cc.ActionInterval
function CCSceneExTransitionSplitCols:action()
end


--- returns the Ease action that will be performed on a linear action.
---@param action cc.ActionInterval
---@return cc.ActionInterval
function CCSceneExTransitionSplitCols:easeActionWithAction(action)
end


-------------------------------------------------------------------------------
-- CCSceneExTransitionSplitRows
-------------------------------------------------------------------------------

--- The odd rows goes to the left while the even rows goes to the right.
---@class cc.CCSceneExTransitionSplitRows : cc.CCSceneExTransitionSplitCols
local CCSceneExTransitionSplitRows = {}


---@param duration number
---@param scene cc.CSceneExtension
---@return cc.CCSceneExTransitionSplitRows
function CCSceneExTransitionSplitRows:create(duration, scene)
end


-------------------------------------------------------------------------------
-- CCSceneExTransitionMoveInL
-------------------------------------------------------------------------------

--- Move in from to the left the incoming scene.
---@class cc.CCSceneExTransitionMoveInL : cc.CCSceneExTransition
local CCSceneExTransitionMoveInL = {}


---@param duration number
---@param scene cc.CSceneExtension
---@return cc.CCSceneExTransitionMoveInL
function CCSceneExTransitionMoveInL:create(duration, scene)
end


--- initializes the scenes
function CCSceneExTransitionMoveInL:initScenes()
end


---@return cc.ActionInterval
function CCSceneExTransitionMoveInL:action()
end


--- returns the Ease action that will be performed on a linear action.
---@param action cc.ActionInterval
---@return cc.ActionInterval
function CCSceneExTransitionMoveInL:easeActionWithAction(action)
end


-------------------------------------------------------------------------------
-- CCSceneExTransitionMoveInR
-------------------------------------------------------------------------------

--- Move in from to the right the incoming scene.
---@class cc.CCSceneExTransitionMoveInR : cc.CCSceneExTransitionMoveInL
local CCSceneExTransitionMoveInR = {}


---@param duration number
---@param scene cc.CSceneExtension
---@return cc.CCSceneExTransitionMoveInR
function CCSceneExTransitionMoveInR:create(duration, scene)
end


-------------------------------------------------------------------------------
-- CCSceneExTransitionMoveInT
-------------------------------------------------------------------------------

--- Move in from to the top the incoming scene.
---@class cc.CCSceneExTransitionMoveInT : cc.CCSceneExTransitionMoveInL
local CCSceneExTransitionMoveInT = {}


---@param duration number
---@param scene cc.CSceneExtension
---@return cc.CCSceneExTransitionMoveInT
function CCSceneExTransitionMoveInT:create(duration, scene)
end


-------------------------------------------------------------------------------
-- CCSceneExTransitionMoveInB
-------------------------------------------------------------------------------

--- Move in from to the bottom the incoming scene.
---@class cc.CCSceneExTransitionMoveInB : cc.CCSceneExTransitionMoveInL
local CCSceneExTransitionMoveInB = {}


---@param duration number
---@param scene cc.CSceneExtension
---@return cc.CCSceneExTransitionMoveInB
function CCSceneExTransitionMoveInT:create(duration, scene)
end


-------------------------------------------------------------------------------
-- CCSceneExTransitionTurnOffTiles
-------------------------------------------------------------------------------

--- Turn off the tiles of the outgoing scene in random order
---@class cc.CCSceneExTransitionTurnOffTiles : cc.CCSceneExTransition
local CCSceneExTransitionTurnOffTiles = {}


---@param duration number
---@param scene cc.CSceneExtension
---@return cc.CCSceneExTransitionTurnOffTiles
function CCSceneExTransitionTurnOffTiles:create(duration, scene)
end


function CCSceneExTransitionTurnOffTiles:sceneOrder()
end


--- returns the Ease action that will be performed on a linear action.
---@param action cc.ActionInterval
---@return cc.ActionInterval
function CCSceneExTransitionTurnOffTiles:easeActionWithAction(action)
end



-------------------------------------------------------------------------------
-- CCSceneExTransitionCrossFade
-------------------------------------------------------------------------------

--- Cross fades two scenes using the CCRenderTexture object.
---@class cc.CCSceneExTransitionCrossFade : cc.CCSceneExTransition
local CCSceneExTransitionCrossFade = {}


---@param duration number
---@param scene cc.CSceneExtension
---@return cc.CCSceneExTransitionCrossFade
function CCSceneExTransitionCrossFade:create(duration, scene)
end


-------------------------------------------------------------------------------
-- CCSceneExTransitionRotoZoom
-------------------------------------------------------------------------------

--- Rotate and zoom out the outgoing scene, and then rotate and zoom in the incoming 
---@class cc.CCSceneExTransitionRotoZoom : cc.CCSceneExTransition
local CCSceneExTransitionRotoZoom = {}


---@param duration number
---@param scene cc.CSceneExtension
---@return cc.CCSceneExTransitionRotoZoom
function CCSceneExTransitionRotoZoom:create(duration, scene)
end


-------------------------------------------------------------------------------
-- CCSceneExTransitionJumpZoom
-------------------------------------------------------------------------------

--- Zoom out and jump the outgoing scene, and then jump and zoom in the incoming 
---@class cc.CCSceneExTransitionJumpZoom : cc.CCSceneExTransition
local CCSceneExTransitionJumpZoom = {}


---@param duration number
---@param scene cc.CSceneExtension
---@return cc.CCSceneExTransitionJumpZoom
function CCSceneExTransitionJumpZoom:create(duration, scene)
end


-------------------------------------------------------------------------------
-- CCSceneExTransitionShrinkGrow
-------------------------------------------------------------------------------

--- Shrink the outgoing scene while grow the incoming scene
---@class cc.CCSceneExTransitionShrinkGrow : cc.CCSceneExTransition
local CCSceneExTransitionShrinkGrow = {}


---@param duration number
---@param scene cc.CSceneExtension
---@return cc.CCSceneExTransitionShrinkGrow
function CCSceneExTransitionShrinkGrow:create(duration, scene)
end


--- returns the Ease action that will be performed on a linear action.
---@param action cc.ActionInterval
---@return cc.ActionInterval
function CCSceneExTransitionShrinkGrow:easeActionWithAction(action)
end


-------------------------------------------------------------------------------
-- CCSceneExTransitionPageTurn
-------------------------------------------------------------------------------

--- A transition which peels back the bottom right hand corner of a scene 
--- to transition to the scene beneath it simulating a page turn. 
--- 
--- This uses a 3DAction so it's strongly recommended that depth buffering 
--- is turned on in CCDirector using: 
--- 
--- CCDirector::sharedDirector()->setDepthBufferFormat(kDepthBuffer16);
--- 
---@class cc.CCSceneExTransitionPageTurn : cc.CCSceneExTransition
local CCSceneExTransitionPageTurn = {}


---@param duration number
---@param scene cc.CSceneExtension
---@param backwards boolean
---@return cc.CCSceneExTransitionPageTurn
function CCSceneExTransitionPageTurn:create(duration, scene, backwards)
end


---@param duration number
---@param scene cc.CSceneExtension
---@param backwards boolean
---@return boolean
function CCSceneExTransitionPageTurn:initWithDuration(duration, scene, backwards)
end


---@param size cc.size
---@return cc.ActionInterval
function CCSceneExTransitionPageTurn:actionWithSize(size)
end
