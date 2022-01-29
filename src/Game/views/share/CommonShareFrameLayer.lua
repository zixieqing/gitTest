--[[
通用分享界面框架
--]]
local GameScene = require( "Frame.GameScene" )
local CommonShareFrameLayer = class('CommonShareFrameLayer', GameScene)

------------ import ------------
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function CommonShareFrameLayer:ctor(...)

	local args = unpack({...})
	GameScene.ctor(self,'Game.views.share.CommonShareFrameLayer')

	self:InitUI()

	-- 添加分享通用框架
	local node = require('common.ShareNode').new({visitNode = self, type = args.type})
	node:setName('ShareNode')
	display.commonUIParams(node, {po = utils.getLocalCenter(self)})
	self:addChild(node, 999)
end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化ui
--]]
function CommonShareFrameLayer:InitUI()

	local function CreateView()

		return {

		}
	end

	xTry(function ( )
		self.viewData = CreateView()
	end, __G__TRACKBACK__)

end
---------------------------------------------------
-- init end --
---------------------------------------------------





return CommonShareFrameLayer
