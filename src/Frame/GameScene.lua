---@class GameScene : CLayout
local GameScene = class('GameScene', function ()
	local node = CLayout:create(display.size)
	node.name = 'GameScene'
	node:enableNodeEvents()
	return node
end)

GameScene.TAGS = {
	TagGameLayer	= 100,
	TagUILayer		= 201,
	TagDialogLayer	= 302
}


function GameScene:ctor( contextName )
	self.contextName = contextName
	local gameLayer = CLayout:create(display.size)
	gameLayer:setPosition(display.center)
	self:addChild(gameLayer, GameScene.TAGS.TagGameLayer, GameScene.TAGS.TagGameLayer)

	local uilayer = CLayout:create(display.size)
	uilayer:setPosition(display.center)
	self:addChild(uilayer, GameScene.TAGS.TagUILayer, GameScene.TAGS.TagUILayer)

	-- local dialogLayer = CLayout:create(display.size)
	-- dialogLayer:setPosition(display.center)
	-- self:addChild(dialogLayer, GameScene.TAGS.TagDialogLayer, GameScene.TAGS.TagDialogLayer)

	self.childDatas = {
		gameNode = gameLayer,
		uiNode   = uilayer,
		-- dialogNode = dialogLayer
	}
end

function GameScene:GetContext( )
	return self.contextName
end

--[[
-- 获取指定的Game层
-- @param tagGameLayer 指字的tag值
--]]
function GameScene:GetGameLayerByTag( tagGameLayer )
	return self.childDatas.gameNode:getChildByTag(tagGameLayer)
end

--[[
-- 获取指定的Game层
-- @param tagGameLayer 指字的tag值
--]]
function GameScene:GetGameLayerByName( nameLayer)
	return self.childDatas.gameNode:getChildByName( nameLayer )
end

--[[
-- 获取指定的Game层
-- @param gamelayer 添加game结点
--]]
function GameScene:AddGameLayer( gamelayer, zorder )
    if DEBUG > 0 then
        logs('+  layer) ' .. tostring(gamelayer.__cname or gamelayer:getName()))
        if gamelayer.onCleanupCallback_ == nil then
            gamelayer:onNodeEvent('cleanup', function()
                logs('-  layer) ' .. tostring(gamelayer.__cname or gamelayer:getName()))
            end)
        end
    end
	self.childDatas.gameNode:addChild(gamelayer, zorder or 2)
end
--[[
-- 移出指定的Game层
-- @param tagGameLayer tag值
-- @param cleanup  是否指定的清除功能
--]]
function GameScene:RemoveGameLayerByTag( tagGameLayer, cleanup )
	if not cleanup then cleanup = true end
    local gameNode = self.childDatas.gameNode:getChildByTag(tagGameLayer)
    if gameNode then
        gameNode:setVisible(false)
        gameNode:setLocalZOrder(-9999)
        -- gameNode:removeFromParent()
        gameNode:runAction(cc.RemoveSelf:create())
        -- gameNode:removeChildByTag(tagGameLayer, cleanup)
    end
end
--[[
-- 移出指定的Game层
-- @param gameNode gameNode
-- @param cleanup  是否指定的清除功能
--]]
function GameScene:RemoveGameLayer( gameNode, cleanup )
	if not cleanup then cleanup = true end
    gameNode:setVisible(false)
    gameNode:setLocalZOrder(-9999)
    -- gameNode:removeFromParent()
    gameNode:runAction(cc.RemoveSelf:create())
	-- self.childDatas.gameNode:removeChild(gameNode, cleanup)
end
--
--=============================
--
function GameScene:GetUIByTag( tagUI )
	return self.childDatas.uiNode:getChildByTag(tagUI)
end
--[[
添加UI层的逻辑功能
@param nodeLayer 添加ui节点
--]]
function GameScene:AddUILayer( nodeLayer )
	self.childDatas.uiNode:addChild(nodeLayer)
end

function GameScene:RemoveUILayerByTag( tagUILayer, cleanup )
	if not cleanup then cleanup = true end
    local uiNode = self.childDatas.uiNode:getChildByTag(tagUILayer)
    if uiNode then
        uiNode:setVisible(false)
        uiNode:setLocalZOrder(-9999)
        -- uiNode:removeFromParent()
        uiNode:runAction(cc.RemoveSelf:create())
    end
	-- self.childDatas.uiNode:removeChildByTag(tagUILayer, cleanup)
end

function GameScene:RemoveUILayer( uinode, cleanup )
	if not cleanup then cleanup = true end
    uinode:setVisible(false)
    uinode:setLocalZOrder(-9999)
    -- uinode:removeFromParent()
    uinode:runAction(cc.RemoveSelf:create())
	-- self.childDatas.uiNode:removeChild(uinode, cleanup)
end


-------------------------------------------------
--[[
-- 获取指定的Game层
-- @param tagGameLayer 指字的tag值
--]]
function GameScene:GetDialogByName( name )
    local dialogLayer = sceneWorld:getChildByTag(GameSceneTag.Dialog_GameSceneTag)
    local dialogNode  = dialogLayer and dialogLayer:getChildByName(name) or nil
    if dialogNode and not dialogNode.isFree then
        return dialogNode
    end
end

function GameScene:GetDialogByTag( tag )
    local dialogLayer = sceneWorld:getChildByTag(GameSceneTag.Dialog_GameSceneTag)
    local dialogNode  = dialogLayer and dialogLayer:getChildByTag(tag) or nil
    if dialogNode and not dialogNode.isFree then
        return dialogNode
    end
end

function GameScene:AddDialog( dialogNode )
    local dialogLayer = sceneWorld:getChildByTag(GameSceneTag.Dialog_GameSceneTag)
    if dialogNode then
        if DEBUG > 0 then
            logs('+ dialog) ' .. tostring(dialogNode.__cname or dialogNode:getName()))
            if dialogNode.onCleanupCallback_ == nil then
                dialogNode:onNodeEvent('cleanup', function()
                    logs('- dialog) ' .. tostring(dialogNode.__cname or dialogNode:getName()))
                end)
            end
        end
        dialogLayer:addChild(dialogNode)
    end
end

function GameScene:RemoveDialogByTag( tag, cleanup )
	if not cleanup then cleanup = true end
    local dialogLayer = sceneWorld:getChildByTag(GameSceneTag.Dialog_GameSceneTag)
    local dialogNode  = dialogLayer and dialogLayer:getChildByTag(tag) or nil
    if  dialogNode and not dialogNode.isFree then
        dialogNode.isFree = true
        dialogNode:setVisible(false)
        dialogNode:setLocalZOrder(-9999)
        dialogNode:runAction(cc.SafeRemoveSelf:create(dialogNode))
    end
end

function GameScene:RemoveDialogByName( name, cleanup )
    if not cleanup then cleanup = true end
    local dialogLayer = sceneWorld:getChildByTag(GameSceneTag.Dialog_GameSceneTag)
    local dialogNode  = dialogLayer and dialogLayer:getChildByName(name) or nil
    if  dialogNode and not dialogNode.isFree then
        dialogNode.isFree = true
        dialogNode:setVisible(false)
        dialogNode:setLocalZOrder(-9999)
        dialogNode:runAction(cc.SafeRemoveSelf:create(dialogNode))
    end
end

function GameScene:RemoveDialog( dialogNode, cleanup )
	if not cleanup then cleanup = true end
    if  dialogNode and not dialogNode.isFree then
        dialogNode.isFree = true
        dialogNode:setVisible(false)
        dialogNode:setLocalZOrder(-9999)
        dialogNode:runAction(cc.SafeRemoveSelf:create(dialogNode))
    end
end


-------------------------------------------------

function GameScene:AddViewForNoTouch()
    local dialogNodeLayer = sceneWorld:getChildByTag(GameSceneTag.Dialog_GameSceneTag)
	local colorLayer = dialogNodeLayer:getChildByTag(9999999)
	if not colorLayer then
		colorLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
		colorLayer:setTag(9999999)
		colorLayer:setTouchEnabled(true)
		colorLayer:setContentSize(display.size)
		colorLayer:setAnchorPoint(cc.p(0.5, 1.0))
		colorLayer:setPosition(cc.p(display.cx, display.height))-- - NAV_BAR_HEIGHT
        dialogNodeLayer:addChild(colorLayer,600)
	end
	colorLayer:setVisible(true)
end

function GameScene:RemoveViewForNoTouch()
    local dialogNodeLayer = sceneWorld:getChildByTag(GameSceneTag.Dialog_GameSceneTag)
	local touchNode = dialogNodeLayer:getChildByTag(9999999)
	if touchNode then
		touchNode:setVisible(false)
	end
end
function GameScene:onEnter()
end

return GameScene
