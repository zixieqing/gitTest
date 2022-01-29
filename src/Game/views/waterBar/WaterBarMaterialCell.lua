--[[
活动每日签到Cell
--]]

---@class WaterBarMaterialCell
local WaterBarMaterialCell = class('WaterBarMaterialCell', function ()
	local WaterBarMaterialCell = CGridViewCell:new()
	WaterBarMaterialCell.name = 'home.WaterBarMaterialCell'
	WaterBarMaterialCell:enableNodeEvents()
	return WaterBarMaterialCell
end)
local RES_DICT={
	COMMON_FRAME_GOODS_5                       = _res("ui/common/common_frame_goods_5")
}
--[[
	@param table {
		materialId  int  材料id
		isVisible  bool  是否显示
	}
]]
function WaterBarMaterialCell:ctor( arg )
	local size =  cc.size(97,97)
	arg = arg or {}
	local isVisible  = arg.isVisible and true or false
	self:setContentSize(size)
	local materialSize = cc.size(80,80)
	local materialLayout = display.newLayer(size.width/2 , size.height/2 ,{ap = display.CENTER,size = materialSize , enable = true })
	self:addChild(materialLayout)
	local materialFrameImage = display.newImageView(RES_DICT.COMMON_FRAME_GOODS_5 , materialSize.width/2 , materialSize.height/2, {enable = true , animate = false})
	materialLayout:addChild(materialFrameImage)
	local materialIconImage = display.newImageView( _res('arts/goods/goods_icon_190002')  , materialSize.width/2 , materialSize.height/2 , {scale = 0.6 })
	materialLayout:addChild(materialIconImage)
	local numLabel = display.newLabel(80, 0, fontWithColor(14,{ap = display.RIGHT_BOTTOM ,text = ""}))
	materialLayout:addChild(numLabel)
	numLabel:setVisible(isVisible)
	self.viewData = {
		materialLayout     = materialLayout,
		materialFrameImage = materialFrameImage,
		materialIconImage  = materialIconImage,
		numLabel           = numLabel,
	}
end

function WaterBarMaterialCell:UpdateCell(materialId ,num)
	local viewData = self.viewData
	local materialPath = CommonUtils.GetGoodsIconPathById(materialId)
	viewData.materialIconImage:setTexture(materialPath)
	self.viewData.numLabel:setString(tostring(num))
end

return WaterBarMaterialCell

