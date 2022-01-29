--[[
中空状态 小人layer
@params table {
	size cc.size 对齐的基准size
	text string 小人的提示
}
--]]
local EmptyGodLayer = class('EmptyGodLayer', function()
	local node = CLayout:create(display.size)
	node.name = 'common.EmptyGodLayer'
	node:enableNodeEvents()
	return node
end)
--[[
constructor
--]]
function EmptyGodLayer:ctor( ... )
	local args = unpack({...})
	self.size = args.size
	self.text = args.text

	self:InitLayer()
end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化layer
--]]
function EmptyGodLayer:InitLayer()

	self:setContentSize(self.size)
	-- self:setBackgroundColor(cc.c4b(255, 128, 128, 100))

	local function CreatView()

		-- 中间小人
		local qScale = 0.7
		local loadingCardQ = AssetsUtils.GetCartoonNode(3, 0, 0)
		display.commonUIParams(loadingCardQ, {po = cc.p(
			self.size.width * 0.7,
			self.size.height * 0.5)})
	    self:addChild(loadingCardQ, 6)
	    loadingCardQ:setScale(qScale)

	    -- 提示文字
	   	local dialogue_tips = display.newButton(0, 0, {n = _res('ui/common/common_bg_dialogue_tips.png')})
		display.commonUIParams(dialogue_tips, {po = cc.p(
			loadingCardQ:getPositionX() - 470 * 0.45 * qScale - dialogue_tips:getContentSize().width * 0.5,
			loadingCardQ:getPositionY())})
		display.commonLabelParams(dialogue_tips,{text = self.text, fontSize = 24, color = '#4c4c4c'})
        self:addChild(dialogue_tips, 6)

        -- 左下小人
        local leftBottomCardQ = display.newImageView(_res("ui/common/common_ico_cartoon_1.png"), 0, 0)
	    display.commonUIParams(leftBottomCardQ, {po = cc.p(
	    	-20,
	    	leftBottomCardQ:getContentSize().height * 0.5)})
	    self:addChild(leftBottomCardQ, 6)

		return {
			loadingCardQ = loadingCardQ,
			dialogue_tips = dialogue_tips,
			leftBottomCardQ = leftBottomCardQ
		}

	end


	xTry(function ( )
		self.viewData = CreatView( )
	end, __G__TRACKBACK__)
end
---------------------------------------------------
-- init end --
---------------------------------------------------

return EmptyGodLayer
