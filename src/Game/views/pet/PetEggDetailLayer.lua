--[[
堕神蛋详情layer 显示可能出现的堕神
@params table {
	petEggId int 堕神蛋id
}
--]]
local PetEggDetailLayer = class('PetEggDetailLayer', function()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.pet.PetEggDetailLayer'
	node:enableNodeEvents()
	return node
end)

------------ import ------------
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
------------ import ------------

--[[
constructor
--]]
function PetEggDetailLayer:ctor( ... )
	local args = unpack({...})

	self.petEggId = args.petEggId

	self:InitLayer()
end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化layer
--]]
function PetEggDetailLayer:InitLayer()
	-- self:setBackgroundColor(cc.c4b(255, 188, 188, 100))

	local petEggConfig = CommonUtils.GetConfig('pet', 'petEgg', self.petEggId)

	-- 标题
	local titleLabel = display.newLabel(0, 0, fontWithColor('5', {text = __('可能出现')}))

	------------ 计算层size ------------
	local cellSize = cc.size(100, 80)
	local padding = cc.p(5, 10)
	local border = cc.p(5, 10)
	local cellPerLine = 5
	local titleSize = display.getLabelContentSize(titleLabel)
	local amount = #petEggConfig.includePets

	local size = cc.size(
		cellSize.width * math.min(cellPerLine, amount) + padding.x * 2 + border.x * 2 ,
		cellSize.height * math.ceil(amount / cellPerLine) + padding.y * 2 + titleSize.height + border.y * 2 +20)
	------------ 计算层size ------------

	self:setContentSize(size)

	local bg = display.newImageView(_res('ui/common/common_bg_tips_common.png'), size.width * 0.5, size.height * 0.5,
		{scale9 = true, size = size})
	self:addChild(bg)

	display.commonUIParams(titleLabel, {po = cc.p(size.width * 0.5, size.height - titleSize.height * 0.5 - border.y)})
	bg:addChild(titleLabel)
	petEggConfig.petsRate = petEggConfig.petsRate  or {}

	-- 堕神图标
	for i,v in ipairs(petEggConfig.includePets) do
		local petIcon = require('common.GoodNode').new({
			goodsId = checkint(v),
			showAmount = false,
			callBack = function (sender)
				uiMgr:ShowInformationTipsBoard({
					targetNode = sender,
					iconId = checkint(v),
					type = 7
				})
			end
		})
		local num =( petEggConfig.petsRate[i] and  petEggConfig.petsRate[i] *100) or 0
		local label = display.newLabel(cellSize.width/2 , -20 , fontWithColor('5' ,{fontSize = 26 ,  text = num .. "%"}))
		petIcon:addChild(label,10)
		petIcon:setScale((cellSize.width - 10) / petIcon:getContentSize().width)
		petIcon:setPosition(cc.p(
			border.x + padding.x + (i - 0.5) * cellSize.width ,
			border.y + padding.y + cellSize.height * 0.5 + 20
		))
		self:addChild(petIcon, 10)
	end
end
---------------------------------------------------
-- init end --
---------------------------------------------------

return PetEggDetailLayer
