--[[
主角技图标
@params table {
	id int 技能id
}
--]]
local PlayerSkillNode = class('PlayerSkillNode', function ()
	local node = CButton:create()
	-- node:setColor(display.COLOR_WHITE)
	node.name = 'common.PlayerSkillNode'
	node:enableNodeEvents()
	return node
end)

---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
constructor
--]]
function PlayerSkillNode:ctor( ... )
	local args = unpack({...})
	self.id = checkint(args.id)

	self:InitUI()
end
--[[
init ui 
--]]
function PlayerSkillNode:InitUI()

	local function CreateView()

		local cover = display.newNSprite(_res('ui/battle/team_lead_skill_frame_l.png'), 0, 0)
		local size = cover:getContentSize()
		self:setContentSize(size)
		display.commonUIParams(cover, {po = cc.p(size.width * 0.5, size.height * 0.5)})
		self:addChild(cover, 10)

		local skillIcon = display.newNSprite(_res(CommonUtils.GetSkillIconPath(self.id)), size.width * 0.5, size.height * 0.5)
		skillIcon:setScale((size.width - 15) / skillIcon:getContentSize().width)
		self:addChild(skillIcon, 4)

		return {
			skillIcon = skillIcon
		}

	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)

end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
刷新技能ui
@params data table 技能信息
--]]
function PlayerSkillNode:RefreshUI(data)
	if nil == data then return end
	self.id = checkint(data.id)
	self.viewData.skillIcon:setTexture(_res(CommonUtils.GetSkillIconPath(self.id)))
end
--[[
刷新技能icon已装备状态
@params s bool 是否已装备
--]]
function PlayerSkillNode:RefreshEquipState(s)
	if nil == self.viewData.equipedMask then
		self.viewData.equipedMask = display.newNSprite(_res('ui/map/team_lead_skill_frame_replace.png'), utils.getLocalCenter(self).x, utils.getLocalCenter(self).y)
		self:addChild(self.viewData.equipedMask, 5)

		local equipLabel = display.newLabel(utils.getLocalCenter(self.viewData.equipedMask).x, utils.getLocalCenter(self.viewData.equipedMask).y,
			fontWithColor(9,{text = __('已装备')}))
		self.viewData.equipedMask:addChild(equipLabel)
	end

	self.viewData.equipedMask:setVisible(s)
end
--[[
刷新主角技选中状态
@params s bool 是否已选中
--]]
function PlayerSkillNode:RefreshSelectedState(s)
	if nil == self.viewData.selectedBottom then
		self.viewData.selectedBottom = display.newNSprite(_res('ui/map/team_lead_skill_frame_light.png'), utils.getLocalCenter(self).x, utils.getLocalCenter(self).y)
		self:addChild(self.viewData.selectedBottom, 1)
	end

	self.viewData.selectedBottom:setVisible(s)
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

return PlayerSkillNode
