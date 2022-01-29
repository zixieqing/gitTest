--[[
NPC图鉴大图View
--]]

local NPCManualDrawView = class('NPCManualDrawView', function()
	local node = CLayout:create(display.size)
	node.name = 'common.NPCManualDrawView'
	node:enableNodeEvents()
	return node
end)
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
function NPCManualDrawView:ctor( ... )
	self.args = unpack({...}) or {}
	self.viewData_ = nil
	local function CreateView()
		local view = CLayout:create(display.size)
		local bgPath = _res('ui/home/handbook/pokedex_npc_bg_xl.jpg')
		local bg = display.newImageView(_res(bgPath), display.cx, display.cy, {isFull = true})
		bg:setRotation(-90)
		view:addChild(bg, -1)
		local role = CommonUtils.GetRoleNodeById(self.args.roleId, 1)
		display.commonUIParams(role, {po = cc.p(display.cx, display.cy)})
		role:setScale(0.8)
		role:setRotation(-90)
		view:addChild(role, 5)


		return {
			view      = view,
		}
	end
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
	eaterLayer:setTouchEnabled(true)
	eaterLayer:setContentSize(display.size)
	eaterLayer:setPosition(utils.getLocalCenter(self))
	self:addChild(eaterLayer, -1)
	self.eaterLayer = eaterLayer
	self.viewData_ = CreateView()
	display.commonUIParams(self.viewData_.view, {po = display.center})
	self:addChild(self.viewData_.view, 1)
end
return NPCManualDrawView
