local BaseManager = require('Frame.Manager.ManagerBase')
---@class ChangeSkinManager
local ChangeSkinManager = class('ChangeSkinManager', BaseManager)
ChangeSkinManager.DEFAULT_NAME = 'ChangeSkinManager'
-- 换皮的配置数据
ChangeSkinManager.CHANGE_SKIN_CONF = {
	SKIN_MODE = nil, -- 换皮的模式
	SKIN_PATH = nil , -- 换皮的路径
}
-------------------------------------------------
-- life cycle

function ChangeSkinManager:ctor()
	self.super.super.ctor(self)
	self.skinMode = self.CHANGE_SKIN_CONF.SKIN_MODE
end
--[[
	获取换皮后的po
--]]
function ChangeSkinManager:GetPoText(text)
	local changeSkinTable =  self:GetChangeSkinData()
	local podTable = changeSkinTable.po
	if podTable == nil then
		return text
	end
	return podTable[text] ~= "" and podTable[text] or text
end
--[[
获取换皮的数据
--]]
function ChangeSkinManager:GetChangeSkinData()
	if self.CHANGE_SKIN_CONF.SKIN_MODE then
		if not self.changeSkinTable then
			self.changeSkinTable =  require( table.concat({"changeSkin" , self.CHANGE_SKIN_CONF.SKIN_PATH , self.CHANGE_SKIN_CONF.SKIN_MODE} , "."))
		end
		return self.changeSkinTable
	end
	return {}
end

--更换spine 的方法
function ChangeSkinManager:GetSpinePath(filePath)
	if self.CHANGE_SKIN_CONF.SKIN_MODE then
		return _spnEx(filePath, self.CHANGE_SKIN_CONF.SKIN_MODE)
	end
	return _spn(filePath)
end

--更换资源的方法
function ChangeSkinManager:GetResPath(filePath)
	if self.CHANGE_SKIN_CONF.SKIN_MODE then
		return _resEx(filePath, nil, self.CHANGE_SKIN_CONF.SKIN_MODE)
	end
	return _res(filePath)
end
---@param spineNode userdata cc.Spine
---@param key string
---deprecated spine 的位置调整
function ChangeSkinManager:UpdateSpinePos(spineNode, key)
	local skinData = self:GetChangeSkinData()
	local spinePos = skinData.spinePos
	if spinePos and spinePos[key] then
		spineNode:setPosition(spinePos[key])
	end
end
---@param uiNode userdata cc.Node
---@param key string
---deprecated UI元素的位置调整
function ChangeSkinManager:UpdateUIPos(uiNode, key)
	local skinData = self:GetChangeSkinData()
	local uiPos = skinData.uiPos
	if uiPos and uiPos[key] then
		uiNode:setPosition(uiPos[key])
	end
end
---@param uiNode userdata cc.Node
---@param key string
---deprecated UI是否可见
function ChangeSkinManager:UpdateNodeVisible(uiNode, key)
	local skinData = self:GetChangeSkinData()
	local nodeVisible = skinData.nodeVisible
	if nodeVisible and nodeVisible[key] ~=nil then
		uiNode:setVisible(nodeVisible[key])
	end
end

---deprecated 获取界面的统一偏移值
function ChangeSkinManager:GetTotalHeightOffset()
	local skinData = self:GetChangeSkinData()
	local totalHeightOffset = checkint(skinData.totalHeightOffset)
	return totalHeightOffset
end

---@param uiNode userdata cc.Node
---@param key string
---deprecated 附加UI 偏移值
function ChangeSkinManager:AdditionalOffsetTables(uiNode, key)
	local skinData = self:GetChangeSkinData()
	local additionalOffsetTables = skinData.additionalOffsetTables
	if additionalOffsetTables and additionalOffsetTables[key] ~=nil then
		local currentPos = cc.p(uiNode:getPosition())
		uiNode:setPosition(cc.p(currentPos.x + additionalOffsetTables[key].x , additionalOffsetTables[key].y +currentPos.y ))
	end
end
----@param originalMusicKey string 原有的背景音乐
---deprecated 返回换皮后的背景音乐
function ChangeSkinManager:GetBgMusic(originalMusicKey)
	local skinData = self:GetChangeSkinData()
	local bgMusics = skinData.bgMusics
	if bgMusics and bgMusics[originalMusicKey] then
		return bgMusics[originalMusicKey]
	end
	return originalMusicKey
end
return ChangeSkinManager
