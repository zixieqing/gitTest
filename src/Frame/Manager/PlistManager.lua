--[[
plist 记载管理器
--]]
local ManagerBase = require( "Frame.Manager.ManagerBase" )
---@class PlistManager
local PlistManager = class('PlistManager',ManagerBase)
PlistManager.instances = {}
-- 这个里面保存的是需要retain 的
local ASSETS_PLSIT = {
	HEAD_COLLECT = "ui/cards/head/headCollect.plist",
}

---------------------------------------------------
-- mediator extend begin --
---------------------------------------------------
function PlistManager:ctor( key )
	self.super.ctor(self)
	if PlistManager.instances[key] ~= nil then
		funLog(Logger.INFO,"注册相关的facade类型" )
		return
	end
	self.collectPlist = {

	}
	self.spriteFrames = {}
	self:addHeadPlist(true)
end

function PlistManager:addHeadPlist(isRetain)
	if not self.collectPlist.HEAD_COLLECT then
		self.collectPlist.HEAD_COLLECT = true
		self:addSpriteFrames(ASSETS_PLSIT.HEAD_COLLECT , isRetain)
	end
end
function PlistManager:GetSpriteNameByPath(path)
	return "#" ..  basename(path)
end
function PlistManager:addSpriteFrames(plistPath,isRetain )
	local spriteFrameCache = cc.SpriteFrameCache:getInstance()
	spriteFrameCache:addSpriteFrames(plistPath)
	-- 需要提前将 plist 中的每个 frame 提前 retain 一次，防止使用前被清空纹理时释放掉。（因为释放机制是清除没用到的 frame，而不是 plist 依赖的）
	local absolutePath =  cc.FileUtils:getInstance():fullPathForFilename(plistPath)
	local plistDict =  cc.FileUtils:getInstance():getValueMapFromFile(absolutePath)
	for frameKey, _ in pairs(plistDict.frames) do
		local frameObj = spriteFrameCache:getSpriteFrame(frameKey)
		if isRetain then
			if not self.spriteFrames[tostring(plistPath)] then
				self.spriteFrames[tostring(plistPath)] = {}
			end
			self.spriteFrames[tostring(plistPath)][frameKey] = frameObj
			if frameObj then
				frameObj:retain()
			end
		end
	end
end

function PlistManager:removeSpriteFramesFromFile(plistPath)
	local spriteFrameCache = cc.SpriteFrameCache:getInstance()
	if self.spriteFrames[plistPath] then
		for frameKey, frameObj  in pairs(self.spriteFrames[plistPath]) do
			if frameObj then
				frameObj:release()
			end
		end
		self.spriteFrames[plistPath] = nil
	else
		local absolutePath = cc.FileUtils:getInstance():fullPathForFilename(plistPath)
		local plistDict = cc.FileUtils:getInstance():getValueMapFromFile(absolutePath)
		if plistDict and plistDict.frames then
			for frameKey, _ in pairs(plistDict.frames) do
				local frameObj = spriteFrameCache:getSpriteFrame(frameKey)
				if frameObj then
					frameObj:release()
				end
			end
		end
	end
	spriteFrameCache:removeSpriteFramesFromFile(plistPath)
end
function PlistManager:SetSpriteFrame(node , spriteFame)
	if spriteFame and string.len(spriteFame) > 0  then
		node:setSpriteFrame(spriteFame)
	end
end
function PlistManager.GetInstance(key)
	key = (key or "PlistManager")
	if PlistManager.instances[key] == nil then
		PlistManager.instances[key] = PlistManager.new(key)
	end
	return PlistManager.instances[key]
end


function PlistManager.Destroy( key )
	key = (key or "PlistManager")
	if PlistManager.instances[key] == nil then
		return
	end
	--清除配表数据
	local mySelf = PlistManager.instances[key]
	for _, plistPath in pairs(ASSETS_PLSIT) do
		mySelf:removeSpriteFramesFromFile(plistPath)
		display.removeImage(_res(string.match(plistPath , "(.-).plist$")))
	end
	mySelf.collectPlist = nil
	PlistManager.instances[key] = nil
end


function PlistManager:checkSpriteFrame(resPath)
	local spriteFrameCache = cc.SpriteFrameCache:getInstance()
	local lastPos = 0
    for st, sp in function() return string.find(resPath, '/', lastPos, true) end do
		lastPos = sp + 1
	end
	local frameName = string.sub(resPath, lastPos)
	if spriteFrameCache:getSpriteFrame(frameName) then
		local result = '#' .. frameName
		xTry(function()
			local testNode cc.Sprite:create()
			testNode:setSpriteFrame(result)
			if DEBUG > 0 then  -- 为了测试阶段发现问题，开启报错
				error('[SpriteFrame] create failure' .. tostring(frameName))
			end
		end, function()
			result = resPath
		end)
		return result
	else
		if DEBUG > 0 then  -- 为了测试阶段发现问题，开启报错
			error('[SpriteFrame] not find frame' .. tostring(frameName))
		end
	end
	return resPath
end


return PlistManager
