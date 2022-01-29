
--[[
抽卡通用价格node
@params table {
    text string 前置文字
    num  int    价格
    goodsId int 消耗道具id
}
--]]
local CapsuleCommonPrizeNode = class('CapsuleCommonPrizeNode', function ()
	local node = CLayout:create()
	node.name = 'CapsuleCommonPrizeNode'
	node:enableNodeEvents()
	return node
end)

function CapsuleCommonPrizeNode:ctor( ... )
    local args = unpack({...}) or {}
    self.text = args.text or __('消耗')
    self.num = checkint(args.num)
    self.goodsId = args.goodsId or DIAMOND_ID
    self:InitUI()
    self:RefreshPosition()
end
--[[
初始化头像ui
--]]
function CapsuleCommonPrizeNode:InitUI()
    local textLabel = display.newLabel(0, 0, fontWithColor(7, {text = self.text, ap = cc.p(0, 0.5)}))
    self:addChild(textLabel, 1)
    self.textLabel = textLabel
    local numLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', self.num)
    numLabel:setHorizontalAlignment(display.TAR)
    self:addChild(numLabel, 15)
    numLabel:setAnchorPoint(cc.p(0, 0.5))
    self.numLabel = numLabel
    local goodsIcon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(DIAMOND_ID)), 0, 0, {ap = cc.p(0, 0.5)})
    goodsIcon:setScale(0.2)
    self:addChild(goodsIcon, 1)
    self.goodsIcon = goodsIcon
end

--[[
刷新ui
@params args {
    text string 前置文字
    num  int    价格
    goodsId int 消耗道具id
}
--]]
function CapsuleCommonPrizeNode:RefreshUI(args)
    if not args then return end
    if args.text then
        self.text = args.text
        self.textLabel:setString(self.text)
    end
    if args.num then
        self.num = checkint(args.num)
        self.numLabel:setString(self.num)
        if isJapanSdk() then
            self.textLabel:setString(self.num)
            self.numLabel:setString('')
        end
    end
    if args.goodsId then
        self.goodsId = args.goodsId
        self.goodsIcon:setTexture(CommonUtils.GetGoodsIconPathById(self.goodsId))
    end
    self:RefreshPosition()
end
function CapsuleCommonPrizeNode:RefreshPosition()
    local textW = display.getLabelContentSize(self.textLabel).width
    local numW = self.numLabel:getContentSize().width
    local iconW = self.goodsIcon:getContentSize().width * self.goodsIcon:getScale()
    local nodeSize = cc.size(textW + numW + iconW, 30)
    self:setContentSize(nodeSize)
    self.textLabel:setPosition(cc.p(0, nodeSize.height / 2))
    self.numLabel:setPosition(cc.p(textW, nodeSize.height / 2))
    self.goodsIcon:setPosition(cc.p(textW + numW, nodeSize.height / 2))
    if isJapanSdk() then
        display.setNodesToNodeOnCenter(self, {self.goodsIcon, self.textLabel})
    end
end
return CapsuleCommonPrizeNode
