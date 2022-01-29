--[[
表情node
--]]
local ExpressionNode = class('ExpressionNode', function ()
	local node = cc.Sprite:create()
	node.name = 'common.ExpressionNode'
	node:enableNodeEvents()
	return node
end)
--[[
表情类型
--]]
ExpressionType = {
	PLEASED 			= 1,
	SWEAT 				= 2,
	EMBRARASSED 		= 3,
}
function ExpressionNode:ctor( ... )
	self.args = unpack({...})
	self.viewData = nil

	self:initView()
end
--[[
init view
--]]
function ExpressionNode:initView()
	
	local function CreateView()
		-- 初始化纹理
		local texturePath = string.format('ui/common/expression_ico_%d.png', self.args.nodeType or 1)
		self:setTexture(_res(texturePath))
		-- 初始化锚点
		local ap = cc.p(0.4, 0.15)
		self:setAnchorPoint(ap)

		return {
			
		}
	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)

end

return ExpressionNode