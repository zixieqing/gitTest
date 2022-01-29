---@class WoodenDummyScene : GameScene
local WoodenDummyScene = class('WoodenDummyScene', require('Frame.GameScene'))

local RES_DICT = {
	EXERCISE_BG          = _res('ui/home/cardslistNew/woodenDummy/exercise_bg'),
	EXERCISES_BTN_RECORD = _res('ui/home/cardslistNew/woodenDummy/exercises_btn_record'),
	COMMON_TITLE         = _res('ui/common/common_title.png'),
	COMMON_BTN_TIPS      = _res('ui/common/common_btn_tips.png'),
}
function WoodenDummyScene:ctor()
	self.super.ctor(self, 'Game.views.woodenDummy.WoodenDummyScene')
	self:InitUI()
end
function WoodenDummyScene:InitUI()
	local swallowLayer = display.newButton(display.cx , display.cy , { size = display.size , enable = true})
	self:addChild(swallowLayer)
	local bgImage = display.newImageView(RES_DICT.EXERCISE_BG , display.cx , display.cy )
	swallowLayer:addChild(bgImage)
	--end
	local tabNameLabel = display.newButton(97, 744, {
		ap = display.LEFT_TOP ,
		n = RES_DICT.COMMON_TITLE,
		d = RES_DICT.COMMON_TITLE,
		s = RES_DICT.COMMON_TITLE,
		scale9 = true,
		size = cc.size(303, 78) ,
		cb = function()
			app.uiMgr:ShowIntroPopup({moduleId ="104"})
		end
	})
	display.commonLabelParams(tabNameLabel, {text = "" , fontSize = 14, color = '#414146'})
	tabNameLabel:setPosition(display.SAFE_L + 130, display.size.height)
	self:addChild(tabNameLabel ,101)

	local recordBtn = display.newButton( display.SAFE_R -70  ,display.size.height, {ap = display.RIGHT_TOP ,   n = RES_DICT.EXERCISES_BTN_RECORD})
	self:addChild(recordBtn,200)
	display.commonLabelParams(recordBtn, fontWithColor(14,{text = __('战斗记录') ,offset = cc.p(0, -30)}))

	local moduleName = display.newLabel(138, 30,
			fontWithColor('14' , { outline = false ,  ap = display.CENTER, color = '#5b3c25', text =  __("战斗演练"), fontSize = 30, tag = 71 }))
	tabNameLabel:addChild(moduleName)


	local tipButton = display.newNSprite(RES_DICT.COMMON_BTN_TIPS, 237, 30,
	                                     { ap = display.CENTER, tag = 72 })
	tipButton:setScale(1, 1)
	tabNameLabel:addChild(tipButton)

	local tableSize  =  cc.size(display.SAFE_RECT.width, 700)
	local tableView = CTableView:create(tableSize)
	tableView:setSizeOfCell(cc.size(404, 680))
	tableView:setAutoRelocate(true)
	tableView:setDirection(eScrollViewDirectionHorizontal)
	tableView:setPosition(display.cx , display.cy - 30)
	tableView:setCountOfCell(0)
	tableView:setAnchorPoint(cc.p(0.5,0.5))
	self:addChild(tableView)
	local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back")})
	backBtn:setPosition(cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.height - 53))
	self:addChild(backBtn, 5)
	local tabNameLabelPos = cc.p(tabNameLabel:getPosition())
	tabNameLabel:setPositionY(display.height + 100)
	local action = cc.EaseBounceOut:create(cc.MoveTo:create(1, tabNameLabelPos))
	tabNameLabel:runAction( action )
	self.viewData =  {
		tableView = tableView ,
		swallowLayer = swallowLayer ,
		recordBtn = recordBtn ,
		navBack = backBtn
	}
end




return WoodenDummyScene
