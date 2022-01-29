--[[
工会活动场景
--]]
local GameScene = require( "Frame.GameScene" )
local UnionActivityScene = class("UnionActivityScene", GameScene)

------------ import ------------
local unionMgr = AppFacade.GetInstance():GetManager("UnionManager")
------------ import ------------

------------ define ------------
------------ define ------------

--[[
constructor
--]]
function UnionActivityScene:ctor(...)

	GameScene.ctor(self, 'Game.views.union.UnionActivityScene')

	local args = unpack({...})

	self.activityInfo = {}
	self.curLevel = 0

	self:InitUI()
end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
初始化ui
--]]
function UnionActivityScene:InitUI()
	local function CreateView()

		local size = self:getContentSize()

		local eaterLayer = display.newLayer(0, 0, {size = size, color = cc.c4b(0, 0, 0, 100), animate = false, enable = true, cb = function (sender)
			PlayAudioByClickClose()
			AppFacade.GetInstance():DispatchObservers('CLOSE_UNION_ACTIVITY')
		end})
		display.commonUIParams(eaterLayer, {ap = cc.p(0.5, 0.5), po = cc.p(size.width * 0.5, size.height * 0.5)})
		self:addChild(eaterLayer)

		local bg = display.newImageView(_res('ui/union/activity/guild_activity_hamepage_bg_1.png'), 0, 0)
		display.commonUIParams(bg, {po = cc.p(
			size.width * 0.5,
			size.height * 0.5
		)})
		self:addChild(bg, 2)

		local bgCover = display.newImageView(_res('ui/union/activity/guild_activity_hamepage_bg_2.png'), 0, 0)
		display.commonUIParams(bgCover, {po = cc.p(
			bg:getPositionX(),
			bg:getPositionY()
		)})
		self:addChild(bgCover, 15)

		local eaterBtn = display.newButton(0, 0, {size = bg:getContentSize()})
		display.commonUIParams(eaterBtn, {ap = cc.p(0.5, 0.5), po = cc.p(
			bg:getPositionX(),
			bg:getPositionY()
		)})
		self:addChild(eaterBtn)

		local listViewSize = cc.size(bg:getContentSize().width - 140, 425)
		local cellSize = cc.size(330, listViewSize.height)

		local listView = CTableView:create(listViewSize)
		display.commonUIParams(listView, {ap = cc.p(0.5, 1), po = cc.p(
			bg:getPositionX(),
			bg:getPositionY() + bg:getContentSize().height * 0.5 - 165
		)})
		self:addChild(listView, 5)

		listView:setSizeOfCell(cellSize)
		listView:setCountOfCell(0)
		listView:setDirection(eScrollViewDirectionHorizontal)
		listView:setDataSourceAdapterScriptHandler(handler(self, self.ActivityListViewDataAdapter))
		-- listView:setBackgroundColor(cc.c4b(255, 128, 128, 100))

		return {
			listView = listView
		}
	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)

end
---------------------------------------------------
-- init end --
---------------------------------------------------

---------------------------------------------------
-- view control begin --
---------------------------------------------------
--[[
data adapter
--]]
function UnionActivityScene:ActivityListViewDataAdapter(c, i)
	local cell = c
	local index = i + 1
	local cellSize = self.viewData.listView:getSizeOfCell()

	local ainfo = self.activityInfo[index]
	local lock = self.curLevel < ainfo.unlockLevel

	if nil == cell then
		-- 初始化一个cell
		cell = CTableViewCell:new()
		cell:setContentSize(cellSize)

		local btn = display.newButton(0, 0, {size = cellSize, cb = handler(self, self.ActivityCellClickHandler)})
		display.commonUIParams(btn, {po = cc.p(
			cellSize.width * 0.5,
			cellSize.height * 0.5
		)})
		cell:addChild(btn)

		local bg = display.newImageView(_res('ui/home/battleAssemble/mode_select_bg_active.png'), 0, 0)
		local bgSize = bg:getContentSize()
		display.commonUIParams(bg, {po = cc.p(
			cellSize.width * 0.5,
			cellSize.height * 0.5
		)})
		cell:addChild(bg)
		bg:setTag(3)

		local iconBg = display.newImageView(_res('ui/home/battleAssemble/mode_select_bg_frame.png'), 0, 0)
		display.commonUIParams(iconBg, {po = cc.p(
			bgSize.width * 0.5,
			bgSize.height - 35 - iconBg:getContentSize().height * 0.5
		)})
		bg:addChild(iconBg)

		local icon = display.newImageView(_res(ainfo.iconPath), 0, 0)
		display.commonUIParams(icon, {po = cc.p(
			iconBg:getPositionX(),
			iconBg:getPositionY()
		)})
		bg:addChild(icon)
		icon:setTag(3)

		local iconFg = display.newImageView(_res('ui/home/battleAssemble/mode_select_mask_locked.png'), 0, 0)
		display.commonUIParams(iconFg, {po = cc.p(
			iconBg:getPositionX(),
			iconBg:getPositionY()
		)})
		bg:addChild(iconFg, 5)
		iconFg:setTag(5)

		local lockIcon = display.newNSprite(_res('ui/common/common_ico_lock.png'), 0, 0)
		display.commonUIParams(lockIcon, {po = cc.p(
			iconFg:getContentSize().width * 0.5,
			iconFg:getContentSize().height * 0.65
		)})
		iconFg:addChild(lockIcon)

		local lockLabel = display.newLabel(0, 0, fontWithColor('18', {text = 'testlock'}))
		display.commonUIParams(lockLabel, {po = cc.p(
			lockIcon:getPositionX(),
			lockIcon:getPositionY() - 45
		)})
		iconFg:addChild(lockLabel)
		lockLabel:setTag(3)

		local splitLine = display.newNSprite(_res('ui/home/battleAssemble/mode_select_bg_line1.png'), 0, 0)
		display.commonUIParams(splitLine, {po = cc.p(
			bgSize.width * 0.5,
			iconBg:getPositionY() - iconBg:getContentSize().height * 0.5 - 35
		)})
		bg:addChild(splitLine)

		local aUpLabel = display.newLabel(0, 0, {text = 'test title', fontSize = 22, color = '#b58a79'})
		display.commonUIParams(aUpLabel, {ap = cc.p(0.5, 0), po = cc.p(
			splitLine:getPositionX(),
			splitLine:getPositionY() + 2
		)})
		bg:addChild(aUpLabel)
		aUpLabel:setTag(7)

		local aDownLabel = display.newLabel(0, 0, {text = 'test descrrrrr', fontSize = 22, color = '#b58a79'})
		display.commonUIParams(aDownLabel, {ap = cc.p(0.5, 1), po = cc.p(
			splitLine:getPositionX(),
			splitLine:getPositionY() - 5
		)})
		bg:addChild(aDownLabel)
		aDownLabel:setTag(9)

		local titleBtn = display.newImageView(_res('ui/home/battleAssemble/mode_select_btn_active.png'), 0, 0)
		display.commonUIParams(titleBtn, {po = cc.p(
			bgSize.width * 0.5,
			titleBtn:getContentSize().height * 0.5 + 65
		)})
		bg:addChild(titleBtn)
		titleBtn:setTag(11)

		local titleLabel = display.newLabel(0, 0,
			{text = 'testtitle', fontSize = 24, color = '#ffffff', ttf = true, font = TTF_GAME_FONT, outline = '#813f25', outlineSize = 2})
		display.commonUIParams(titleLabel, {po = cc.p(
			titleBtn:getContentSize().width * 0.5,
			titleBtn:getContentSize().height * 0.5
		)})
		titleBtn:addChild(titleLabel)
		titleLabel:setTag(3)

		local disableTitleLabel = display.newLabel(0, 0,
			{text = 'testtitle', fontSize = 24, color = '#ffffff', ttf = true, font = TTF_GAME_FONT})
		display.commonUIParams(disableTitleLabel, {po = cc.p(
			titleBtn:getContentSize().width * 0.5 - 2,
			titleBtn:getContentSize().height * 0.5 - 2
		)})
		titleBtn:addChild(disableTitleLabel)
		disableTitleLabel:setTag(5)
	end

	local bg = cell:getChildByTag(3)

	-- 背景图
	local bgPath = 'ui/home/battleAssemble/mode_select_bg_active.png'
	local descrColor = ccc3FromInt('#b58a79')
	local titleBtnPath = 'ui/home/battleAssemble/mode_select_btn_active.png'

	if lock then
		bgPath = 'ui/home/battleAssemble/mode_select_bg_locked.png'
		descrColor = ccc3FromInt('#7c7c7c')
		titleBtnPath = 'ui/home/battleAssemble/mode_select_btn_locked.png'
	end

	bg:setTexture(_res(bgPath))
	bg:getChildByTag(3):setTexture(_res(ainfo.iconPath))
	bg:getChildByTag(5):setVisible(lock)
	display.commonLabelParams(bg:getChildByTag(5):getChildByTag(3) ,
	{ text = string.format(__('工会%d级解锁'), ainfo.unlockLevel) , hAlign = display.TAC , w = 210  })
	display.commonLabelParams(bg:getChildByTag(7) ,
			{ text = ainfo.updescr , hAlign = display.TAC ,reqW = 210  })
	display.commonLabelParams(bg:getChildByTag(9) ,
			{ text = ainfo.downdescr , hAlign = display.TAC ,reqW = 210 , w = 300 })
	--bg:getChildByTag(5):getChildByTag(3):setString(string.format(__('工会%d级解锁'), ainfo.unlockLevel))
	--bg:getChildByTag(7):setString(ainfo.updescr)
	bg:getChildByTag(7):setColor(descrColor)

	--bg:getChildByTag(9):setString(ainfo.downdescr)
	bg:getChildByTag(9):setColor(descrColor)

	bg:getChildByTag(11):setTexture(_res(titleBtnPath))
	display.commonLabelParams(bg:getChildByTag(11):getChildByTag(5) , {text = ainfo.name , reqW = 200 })
	display.commonLabelParams(bg:getChildByTag(11):getChildByTag(3) , {text = ainfo.name , reqW = 200 })
	--bg:getChildByTag(11):getChildByTag(3):setString(ainfo.name)
	bg:getChildByTag(11):getChildByTag(3):setVisible(not lock)
	--bg:getChildByTag(11):getChildByTag(5):setString(ainfo.name)
	bg:getChildByTag(11):getChildByTag(5):setVisible(lock)

	cell:setTag(index)

	return cell
end
--[[
根据活动内容刷新活动列表
@params activityInfo list 活动信息
{
	id int id
	name string 活动名
	updescr string 上说明
	downdescr string 下说明
	unlockLevel int 解锁等级
	iconPath string 图标路径
}
@params level int 当前等级
--]]
function UnionActivityScene:RefreshUI(activityInfo, level)
	local amount = #activityInfo
	self.activityInfo = activityInfo
	self.curLevel = level

	self.viewData.listView:setCountOfCell(amount)
	self.viewData.listView:reloadData()
end
---------------------------------------------------
-- view control end --
---------------------------------------------------

---------------------------------------------------
-- handler begin --
---------------------------------------------------
--[[
列表cell点击回调
--]]
function UnionActivityScene:ActivityCellClickHandler(sender)
	local index = sender:getParent():getTag()
	local activityInfo = self.activityInfo[index]

	PlayAudioByClickNormal()
	AppFacade.GetInstance():DispatchObservers('ENTER_UNION_ACTIVITY', {id = checkint(activityInfo.id)})
end
---------------------------------------------------
-- handler end --
---------------------------------------------------

return UnionActivityScene
