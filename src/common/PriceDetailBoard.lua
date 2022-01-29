local PriceDetailBoard = class('PriceDetailBoard', function ()
	return display.newLayer()
end)
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")

local oriSize = cc.size(274, 374)

---------------------------------------------------
-- init logic begin --
---------------------------------------------------
--[[
constructor
--]]
function PriceDetailBoard:ctor( ... )
	self:setName('common.PriceDetailBoard')
	self.args = unpack({...})

	self.targetNode = self.args.targetNode
	self.recipeData = self.args.recipeData
	self:Init()
end
--[[
init
--]]
function PriceDetailBoard:Init()
	self:InitView()
end
--[[
init view
--]]
function PriceDetailBoard:InitView()

	local function CreateView()

		display.commonUIParams(self, {size = display.size, ap = cc.p(0, 0), po = cc.p(0, 0)})

		local bgSize = cc.size(oriSize.width, oriSize.height)

		local boardBg = display.newImageView(_res('ui/common/common_bg_tips_common.png'), 0, 0,
		{ap = cc.p(0.5, 0.5), animate = false, enable = true, scale9 = true, size = bgSize})
		self:addChild(boardBg, 1)
		local bgSize = boardBg:getContentSize()

		local boardArrow = display.newNSprite(_res('ui/common/common_bg_tips_horn.png'), 0,   0)
        boardBg:addChild(boardArrow)

		local boardTop = display.newNSprite(_res('ui/home/lobby/cooking/kitchen_make_bg_detail.png'), bgSize.width / 2, bgSize.height, {ap = cc.p(0.5, 1)})
        boardBg:addChild(boardTop)

        for i = 1, 3 do
            local line = display.newImageView(_res('ui/common/common_ico_line_1.png'), bgSize.width / 2, 80 * i, {scaleX = 0.7})
            boardBg:addChild(line)
        end

		local originLabel = display.newLabel(120, bgSize.height - 32,fontWithColor('4',{
			text = __('原价:'),ap = display.CENTER
		}))
		local originLabelSize = display.getLabelContentSize(originLabel)

		--boardBg:addChild(originLabel)

        local priceLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
        priceLabel:setAnchorPoint(display.CENTER)
        priceLabel:setPosition(120 + 4, bgSize.height - 32)

		local priceLabelSize = cc.size(60, 30 )
		local img_money_type = display.newImageView(_res(string.format( "arts/goods/goods_icon_%d.png", GOLD_ID )),0,0,{ap = display.CENTER})
		img_money_type:setScale(0.2)

        local img_money_typeSize = img_money_type:getContentSize()
		local topSize =  cc.size(priceLabelSize.width  +img_money_typeSize.width * 0.2 + originLabelSize.width , 30  )
		local topLayout = display.newLayer(bgSize.width/2, bgSize.height - 32 , {ap = display.CENTER  , size =topSize })
		boardBg:addChild(topLayout)
		topLayout:addChild(img_money_type)
		topLayout:addChild(priceLabel)
		topLayout:addChild(originLabel)
		originLabel:setPosition(originLabelSize.width /2 , topSize.height/2 )
		img_money_type:setPosition(originLabelSize.width + priceLabelSize.width + img_money_typeSize.width * 0.2/2 , topSize.height/2  )
		priceLabel:setPosition(originLabelSize.width  +priceLabelSize.width/2 , topSize.height/2 )
        local text = {
            __('皇家经营特权加成10%'),
            __('冒险月卡加成300%'),
            __('召唤月卡加成200%'),
            __('提尔菈的祝福加成100%'),
        }

        local buffLabels = {true, true, true, true}
        for i = 1, 4 do
            local buffLabel = display.newLabel(bgSize.width / 2, 80 * i - 40,fontWithColor('5',{
                text = text[i], w = 230, hAlign = display.TAC
            }))
            boardBg:addChild(buffLabel)
            buffLabels[i] = buffLabel
        end

		return {
            boardBg         = boardBg,
            boardArrow      = boardArrow,
            priceLabel      = priceLabel,
            buffLabels      = buffLabels,
            img_money_type  = img_money_type,
		}
	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)

	-- 重写触摸
	self.touchListener_ = cc.EventListenerTouchOneByOne:create()
    -- self.touchListener_:setSwallowTouches(true)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchBegan_), cc.Handler.EVENT_TOUCH_BEGAN)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchMoved_), cc.Handler.EVENT_TOUCH_MOVED)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchEnded_), cc.Handler.EVENT_TOUCH_ENDED)
    self.touchListener_:registerScriptHandler(handler(self, self.onTouchCanceled_), cc.Handler.EVENT_TOUCH_CANCELLED)
    self:getEventDispatcher():addEventListenerWithSceneGraphPriority(self.touchListener_, self)

    self:RefreshTipBoardContent()
    self:RefreshTipBoardPos()
end
---------------------------------------------------
-- init logic end --
---------------------------------------------------

---------------------------------------------------
-- control logic begin --
---------------------------------------------------
--[[
刷新ui
@params data table 数据
--]]
function PriceDetailBoard:RefreshUI(data)
	self.targetNode = data.targetNode
	self.recipeData = data.recipeData
	self:RefreshTipBoardPos()
	self:RefreshTipBoardContent()
end
--[[
刷新内容
--]]
function PriceDetailBoard:RefreshTipBoardContent()
    local data = CommonUtils.GetConfigNoParser('cooking','recipe', self.recipeData.recipeId)
    local viewData = self.viewData
    local priceLabel = viewData.priceLabel 
    local img_money_type = viewData.img_money_type 
    local buffLabels = viewData.buffLabels 
	local bgSize = viewData.boardBg:getContentSize()
    priceLabel:setString(tonumber(data.grade[tostring(self.recipeData.gradeId)].gold))
    --img_money_type:setPosition(cc.p(priceLabel:getPositionX() + priceLabel:getBoundingBox().width + 5 , bgSize.height - 32))

	local member = app.gameMgr:GetUserInfo().member
	-- 召唤月卡
	local memberInfo1 = member['1']
	if memberInfo1 then
		buffLabels[3]:setColor(ccc3FromInt('7e6454'))
	else
		buffLabels[3]:setColor(ccc3FromInt('6c6c6c'))
	end
	-- 冒险月卡
	local memberInfo2 = member['2']
	if memberInfo2 then
		buffLabels[2]:setColor(ccc3FromInt('7e6454'))
	else
		buffLabels[2]:setColor(ccc3FromInt('6c6c6c'))
	end
	-- 皇家经营特权
	local memberInfo3 = member['3']
	if memberInfo3 then
		buffLabels[1]:setColor(ccc3FromInt('7e6454'))
	else
		buffLabels[1]:setColor(ccc3FromInt('6c6c6c'))
	end
end
--[[
刷新位置
--]]
function PriceDetailBoard:RefreshTipBoardPos()
	local targetBoundingBox = self.targetNode and self.targetNode:getBoundingBox() or cc.rect(0, 0, display.width, display.height)
	local worldPos = self.targetNode and self.targetNode:getParent():convertToWorldSpace(cc.p(targetBoundingBox.x, targetBoundingBox.y)) or cc.p(0,display.cy)
	local nodePos = self:convertToNodeSpace(worldPos)

	local boardBgSize = self.viewData.boardBg:getContentSize()
    -- 计算x坐标 不超屏
    local x = nodePos.x + targetBoundingBox.width * 0.5 + boardBgSize.width * 0.5 + 30
    local y = math.min(display.height, nodePos.y + targetBoundingBox.height * 0.5 + 80) - boardBgSize.height / 2
    display.commonUIParams(self.viewData.boardBg, {po = cc.p(x, y)})
    self.viewData.boardArrow:setRotation(-90)
    display.commonUIParams(self.viewData.boardArrow, {po = cc.p(2, nodePos.y + targetBoundingBox.height * 0.5 - y + boardBgSize.height / 2)})
end
--[[
移除自己
--]]
function PriceDetailBoard:RemoveSelf_()
	self:setVisible(false)
	if self.touchListener_ then
		self:getEventDispatcher():removeEventListener(self.touchListener_)
		self.touchListener_ = nil
	end
	self:runAction(cc.RemoveSelf:create())
end
---------------------------------------------------
-- control logic end --
---------------------------------------------------

---------------------------------------------------
-- touch logic begin --
---------------------------------------------------
function PriceDetailBoard:onTouchBegan_(touch, event)
	if self:TouchedSelf(touch:getLocation()) then
		return true
	else
        self:RemoveSelf_()
        return false
	end
end
function PriceDetailBoard:onTouchMoved_(touch, event)

end
function PriceDetailBoard:onTouchEnded_(touch, event)
	self:RemoveSelf_()
end
function PriceDetailBoard:onTouchCanceled_( touch, event )
	-- print('here touch canceled by some unknown reason')
end
--[[
是否触摸到了提示板
@params touchPos cc.p 触摸位置
@return _ bool
--]]
function PriceDetailBoard:TouchedSelf(touchPos)
	local boundingBox = self.viewData.boardBg:getBoundingBox()
	local fixedP = cc.CSceneManager:getInstance():getRunningScene():convertToNodeSpace(
		self.viewData.boardBg:getParent():convertToWorldSpace(cc.p(boundingBox.x, boundingBox.y)))
	if cc.rectContainsPoint(cc.rect(fixedP.x, fixedP.y, boundingBox.width, boundingBox.height), touchPos) then
		return true
	end
	return false
end
---------------------------------------------------
-- touch logic end --
---------------------------------------------------


return PriceDetailBoard


