--[[
顺序点击小游戏
--]]
local BaseMiniGameScene = __Require('battle.miniGame.BaseMiniGameScene')
local ClickSortGame = class('ClickSortGame', BaseMiniGameScene)
local scheduler = require('cocos.framework.scheduler')
--[[
@override
--]]
function ClickSortGame:init()
	BaseMiniGameScene.init(self)
end
--[[
@override
初始化界面
--]]
function ClickSortGame:initView()
	BaseMiniGameScene.initView(self)
	-- 触摸组
	local bgSize = self:getContentSize()
	self.nodeAmount = 4
	for i = 1, self.nodeAmount do
		local id = tostring(i)
		local btn = display.newImageView(_res('battle/ui/battle_btn_weakness_2.png'), 0, 0)
		display.commonUIParams(btn, {po = cc.p(bgSize.width * 0.5 + btn:getContentSize().width * (-0.5 + (i - 1) % 2),
			bgSize.height * 0.5 + btn:getContentSize().height * (0.5 - (math.floor(i / 3))))})
		self:addChild(btn)
		local idxLabel = display.newLabel(utils.getLocalCenter(btn).x, utils.getLocalCenter(btn).y,
			{text = id, fontSize = 36, color = '#ffffff'})
		btn:addChild(idxLabel)
		local touchItem = {id = id, node = btn}
		self:addTouchItem(touchItem)
	end
end
--[[
@override
开始游戏
--]]
function ClickSortGame:start()
	BaseMiniGameScene.start(self)
	self.holdingItem = nil
	self.nextTouch = 1
end
---------------------------------------------------
-- touch logic begin --
---------------------------------------------------
function ClickSortGame:onTouchBegan_(touch, event)
	self.holdingItem = self:touchCheck(touch)
	return true
end
function ClickSortGame:onTouchMoved_(touch, event)

end
function ClickSortGame:onTouchEnded_(touch, event)
	local tiId = self:touchCheck(touch)
	if nil ~= tiId and self.holdingItem == tiId then
		self:touchedItemHandler(tiId)
	end
end
---------------------------------------------------
-- touch logic end --
---------------------------------------------------
--[[
@override
触摸到了item 做出对应的处理
@params id int touch item id
--]]
function ClickSortGame:touchedItemHandler(id)
	local idx = checkint(id)
	if idx == self.nextTouch then
		self.touchItems[id].node:setVisible(false)
		self.nextTouch = self.nextTouch + 1
	end
	if self.nextTouch > self.nodeAmount then
		self.result = true
		self:over()
	end
end


return ClickSortGame
