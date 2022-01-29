--[[
卡牌详情剧情层
@params table {
	id int card id
	lv int card level
	star int card star
}
--]]
local CardDetailStory = class('CardDetailStory', function ()
	local node = CLayout:create()
	node.name = 'home.CardDetailStory'
	node:enableNodeEvents()
	return node
end)
function CardDetailStory:ctor( ... )
	self.args = unpack({...}) or {}

	--------------------------------------
	-- ui

	self.storyListView = nil

	--------------------------------------
	-- ui data

	self.selectedCellIdx = 0

	--------------------------------------
	-- data
	self.cardData = CommonUtils.GetConfig('cards', 'card', self.args.cardId)

	self:initUI()
end
function CardDetailStory:initUI()
	local bgSize = self.args.size --or cc.size(511, 619)
	self:setContentSize(bgSize)

	local nameLabel = display.newLabel(bgSize.width * 0.5, bgSize.height * 0.96,
		{text = string.format('%s', self.cardData.name), fontSize = 28, color = '#ffffff', ap = cc.p(0.5, 0.5)})
	self:addChild(nameLabel)


	local desButton = display.newButton(0, 0, {n = _res('ui/common/common_title.png'),enable = false})
 	display.commonUIParams(desButton, {po = cc.p( 10, bgSize.height * 0.90 - 6),ap = cc.p(0,0.5)})
 	display.commonLabelParams(desButton, {text = __('简介'), fontSize = 24, color = '#ffffff'})
 	self:addChild(desButton)



	local propBgSize = cc.size(bgSize.width*0.95, bgSize.height*0.3)
	-- title

	local storyBg = display.newImageView(_res('ui/common/common_bg_list.png'),
		bgSize.width * 0.5, desButton:getPositionY() - 30,
		{ap = cc.p(0.5, 1),scale9 = true, size = propBgSize,})
	self:addChild(storyBg)
	-- local storyIcon = display.newImageView(_res('ui/home/card/role_bg_intro_triangle.png'),
	-- 	storyBg:getPositionX() + storyBg:getContentSize().width * 0.5 - 4, storyBg:getPositionY() - storyBg:getContentSize().height + 7,
	-- 	{ap = cc.p(1, 0)})
	-- self:addChild(storyIcon, 20)
	-- desc
	local padding = cc.p(15, 0)
	local scrollViewSize = cc.size(storyBg:getContentSize().width - padding.x * 2,
		storyBg:getContentSize().height - 10 - padding.y * 2)
	local descLabel = display.newLabel(0, 0,
		{text = '\n' .. '        按时打算大大的按时打算大大的按时按时打算大大的按时打算大大的按时按时打算大大的按时打算大大的按时按时打算大大的按时打算大大的按时按时打算大大的按时打算大大的按时按时打算大大的按时打算大大的按时按时打算大大的按时打算大大的按时按时打算大大的按时打算大大的按时按时打算大大的按时打算大大的按时按时打算大大的按时打算大大的按时按时打算大大的按时打算大大的按时打算大大的按时打算大大的按时打算大大的按时打算大大的按时打算大大的按时打算大大的按时打算大大的按时打算大大的按时打算大大的按时打算大大的',
		fontSize = 18, color = '#4c4c4c', w = scrollViewSize.width, ap = cc.p(0.5, 1), hAligh = display.TAL})
	local scrollView = CScrollView:create(scrollViewSize)
	scrollView:setDirection(eScrollViewDirectionVertical)
	scrollView:setAnchorPoint(cc.p(0.5, 1))
	scrollView:setPosition(cc.p(storyBg:getPositionX(), storyBg:getPositionY()))
	self:addChild(scrollView)
	-- scrollView:getContainer():setBackgroundColor(cc.c4b(200, 200, 0, 100))
	-- scrollView:setPosition(cc.p(storyBg:getContentSize().width * 0.5, storyBg:getContentSize().height))
	-- storyBg:addChild(scrollView)
	scrollView:setContainerSize(cc.size(scrollViewSize.width, display.getLabelContentSize(descLabel).height))
	display.commonUIParams(descLabel, {po = cc.p(scrollView:getContainerSize().width * 0.5,
	 scrollView:getContainerSize().height)})
	scrollView:setContentOffset(cc.p(0, math.min(0, scrollViewSize.height - scrollView:getContainerSize().height)))
	scrollView:getContainer():addChild(descLabel)

	local scrollBarBg = ccui.Scale9Sprite:create(_res('ui/home/card/rold_bg_gliding_orange'))
	local scrollBarBtn = cc.Sprite:create(_res('ui/home/card/rold_gliding_orange'))
	local scrollBar = FTScrollBar:create(scrollBarBg, scrollBarBtn)
	scrollBar:attachToUIScrollView(scrollView)

	local desButton1 = display.newButton(0, 0, {n = _res('ui/common/common_title.png'),enable = false})
 	display.commonUIParams(desButton1, {po = cc.p( 10, storyBg:getPositionY() - storyBg:getContentSize().height - 10),ap = cc.p(0,1)})
 	display.commonLabelParams(desButton1, {text = __('剧情'), fontSize = 24, color = '#ffffff'})
 	self:addChild(desButton1)

	-- story data
	local t = {
		{name = __('剧情1'), target = 20, progress = 10},
		{name = __('剧情2'), target = 20, progress = 20},
		{name = __('剧情3'), target = 20, progress = 10},
	}
	local listSize = cc.size(bgSize.width - 10,bgSize.height * 0.43  )--
	local storyListView = CListView:create(listSize)
    storyListView:setDirection(eScrollViewDirectionVertical)
    storyListView:setAnchorPoint(cc.p(0.5,1))
    storyListView:setPosition(cc.p(bgSize.width * 0.5, storyBg:getPositionY() - storyBg:getContentSize().height - desButton1:getContentSize().height - 12))
    storyListView:setBounceable(true)
    self:addChild(storyListView)
    -- storyListView:setBackgroundColor(cc.c4b(200, 200, 0, 100))
    self.storyListView = storyListView

	local scrollBarBg = ccui.Scale9Sprite:create(_res('ui/home/card/rold_bg_gliding_orange'))
	local scrollBarBtn = cc.Sprite:create(_res('ui/home/card/rold_gliding_orange'))
	local scrollBar = FTScrollBar:create(scrollBarBg, scrollBarBtn)
	scrollBar:attachToUIScrollView(storyListView)

    for i,v in ipairs(t) do
    	local cell = self:createStoryCellNode(v)
    	cell:setTag(i)
    	storyListView:insertNodeAtLast(cell)
    end
    storyListView:reloadData()
end
function CardDetailStory:createStoryCellNode(data)
	local cellSize = cc.size(self.storyListView:getContentSize().width, 110)
	local cellBgSize = cc.size(465, 100)
	local cell = display.newLayer(0, 0, {size = cellSize})
	local bgPath = 'ui/common/role_main_bg_story_pink.png'
	local lockPath = 'ui/common/comon_lock_gray_ico.png'
	if data.target <= data.progress then
		bgPath = 'ui/common/role_main_bg_story_pink.png'
		lockPath = 'ui/common/comon_lock_ico.png'
	end
	local rewardIcon = require('common.GoodNode').new({})
	rewardIcon:setScale(0.6)
	rewardIcon:setAnchorPoint(cc.p(0, 0.5))
	rewardIcon:setPosition(cc.p(40, cellSize.height * 0.5))
	cell:addChild(rewardIcon, 5)
	local cellBg = display.newImageView(_res(bgPath), cellSize.width * 0.5, cellSize.height * 0.5,
		{scale9 = true, size = cellBgSize, enable = true, animate = false, cb = handler(self, self.storyCellCallback)})
	cell:addChild(cellBg)
	local storyNameLabel = display.newLabel(90, cellBgSize.height * 0.5,
		{text = data.name, fontSize = 22, color = '#cb8766', ap = cc.p(0, 0.5)})
	cellBg:addChild(storyNameLabel)
	local storyLockIcon = display.newNSprite(_res(lockPath), cellBgSize.width - 10, cellBgSize.height - 10,{ap = cc.p(1,1)})
	cellBg:addChild(storyLockIcon)
	local progressLabel = display.newLabel(cellBgSize.width * 0.9, cellBgSize.height * 0.5,
		{text = string.format('%d/%d', data.progress, data.target), fontSize = 20, color = '#ff8875'})
	cellBg:addChild(progressLabel)
	local selectedBox = display.newImageView(_res('ui/common/conmon_function_bg_story_yellow.png'), cellBg:getPositionX(), cellBg:getPositionY(),
		{scale9 = true, size = cellBgSize})
	cell:addChild(selectedBox)
	selectedBox:setTag(3)
	selectedBox:setVisible(false)
	return cell
end
function CardDetailStory:storyCellCallback(pSender)
    PlayAudioByClickNormal()
	local idx = pSender:getParent():getTag()
	self:refreshCellSelected(idx)
end
function CardDetailStory:refreshCellSelected(idx)
	if idx ~= self.selectedCellIdx then
		local preCell = self.storyListView:getNodeAtIndex(self.selectedCellIdx - 1)
		if preCell then
			preCell:getChildByTag(3):setVisible(false)
		end
		local curCell = self.storyListView:getNodeAtIndex(idx - 1)
		if curCell then
			curCell:getChildByTag(3):setVisible(true)
		end
		self.selectedCellIdx = idx
	end
end

function CardDetailStory:refreshUI( data )
	if data then
	end
end







return CardDetailStory
