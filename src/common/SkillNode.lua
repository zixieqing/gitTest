--[[
技能图标
@params table {
	id int 技能id
}
--]]
local SkillNode = class('SkillNode', function ()
	local node = CLayout:create()
	-- node:setColor(display.COLOR_WHITE)
	node.name = 'common.SkillNode'
	node:enableNodeEvents()
	return node
end)
---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
constructor
--]]
function SkillNode:ctor( ... )
	self.args = unpack({...})

	self.skillId = checkint(self.args.id)
	self.grayFilter = nil

	self:Init()
end
--[[
init
--]]
function SkillNode:Init()
	self:InitValue()
	self:InitView()
end
--[[
init value
--]]
function SkillNode:InitValue()
	
end
--[[
init view
--]]
function SkillNode:InitView()
	
	local function CreateView()

		local cover = display.newImageView(_res('ui/map/team_lead_skill_frame_l.png'), 0, 0)
		local size = cover:getContentSize()
		self:setContentSize(size)
		display.commonUIParams(cover, {po = cc.p(size.width * 0.5, size.height * 0.5)})
		self:addChild(cover, 5)

		local skillIconPath = CommonUtils.GetSkillIconPath(self.skillId)
		-- local skillIcon = display.newNSprite(skillIconPath, size.width * 0.5, size.height * 0.5)
		local skillIcon = FilteredSpriteWithOne:create()
		skillIcon:setTexture(skillIconPath)
		display.commonUIParams(skillIcon, {po = cc.p(size.width * 0.5, size.height * 0.5)})
		-- local grayFilter = GrayFilter:create()
		-- skillIcon:setFilter(grayFilter)
		-- skillIcon:clearFilter()
		self:addChild(skillIcon, 1)
		skillIcon:setScale((size.width - 30) / skillIcon:getContentSize().width)

		return {
			skillIcon = skillIcon,
		}

	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)
end
--[[
刷新ui
@params data table {
	id int 技能id
}
--]]
function SkillNode:RefreshUI(data)
	self.skillId = checkint(data.id)
	self.viewData.skillIcon:setTexture(CommonUtils.GetSkillIconPath(self.skillId))
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------
--[[
技能icon灰化控制
@params gray bool 是否灰化
--]]
function SkillNode:setGray(gray)
	if gray then
		if not self.grayFilter then
			self.grayFilter = GrayFilter:create()
			self.viewData.skillIcon:setFilter(self.grayFilter)
		end
	else
		self.viewData.skillIcon:clearFilter()
		self.grayFilter = nil
	end
end



return SkillNode