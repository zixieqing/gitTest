--[[
新天成演武
奖励一览界面
--]]
local CommonDialog = require('common.CommonDialog')
local NewKofArenaRewardsView = class('NewKofArenaRewardsView', CommonDialog)

local RES_DIR = {
	BTN_NORMAL = _res("ui/tagMatchNew/reward/common_btn_tab_default.png"),
	BTN_SELECT = _res("ui/tagMatchNew/reward/common_btn_tab_select.png"),
}

local SECTION_STR_FUNC = {
	['1'] = function() return __('升级') end,
	['2'] = function() return __('保级') end,
	['3'] = function() return __('降级') end,
}

local function CreateItem(goodsData,section)
	local bg = display.newImageView(_res('ui/tagMatchNew/reward/anni_rewards_bg_list.png'), 0, 0,{ap = cc.p(0,0)})
	local bgSize = bg:getContentSize()
	local view = display.newLayer(0, 0, {size = bgSize, ap = cc.p(0.5, 0.5)})
	view:addChild(bg)
	local select =  display.newImageView(_res('ui/tagMatchNew/reward/3v3_reward_bg_list_top.png'), 0, 0,{ap = cc.p(0,0)})
	view:addChild(select)
	select:setVisible(false)

	local name = SECTION_STR_FUNC[tostring(section)]()
	local title = display.newLabel(0, 0, {text = name, fontSize = 22, color = '#873b12'})
	display.commonUIParams(title, {po = cc.p(utils.getLocalCenter(bg).x, utils.getLocalCenter(bg).y + bgSize.height/2 - 20)})
	bg:addChild(title)

	local goods = {}
	for i,v in ipairs(goodsData) do
		local goodsIcon = require('common.GoodNode').new({
			id = checkint(v.goodsId),
			amount = checkint(v.num),
			showAmount = true,
			callBack = function (sender)
				app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = v.goodsId, type = 1})
			end
		})
		view:addChild(goodsIcon, 99)
		table.insert(goods, goodsIcon)
	end


	display.setNodesToNodeOnCenter(bg, goods, {spaceW = 15, y = bgSize.height/2 - 20})
	return   {
		view = view, 
		select = select
	}
	-- return view
end

function NewKofArenaRewardsView:InitialUI()
	self.rewardData = self.args.data

	self.rewardsDatasConf = CONF.NEW_KOF.REWARDS:GetAll()
	self.segmentDatasConf = CONF.NEW_KOF.SEGMENT:GetAll()

	local function CreateView()
		-- bg
		local bg = display.newImageView(_res('ui/tagMatchNew/reward/3v3_rewards_bg.png'), 0, 0)
		local bgSize = bg:getContentSize()
		-- bg view
		local view = display.newLayer(0, 0, {size = cc.resize(bgSize, 0, 25), ap = cc.p(0.5, 0.5)})
		local viewSize = view:getContentSize()
		display.commonUIParams(bg, {po = cc.p(utils.getLocalCenter(view).x, utils.getLocalCenter(view).y - 25 / 2)})
		view:addChild(bg)
		local layer = display.newLayer(0, 0, {size = viewSize})
		view:addChild(layer)
		--顶端按钮
		local segmentBtns = {}
		for k, v in pairs(self.segmentDatasConf) do
			local offsetX = 15 + (k-1) *(bgSize.width/5 - 6)
			local params =  {n = RES_DIR.BTN_NORMAL,s = RES_DIR.BTN_SELECT,d = RES_DIR.BTN_SELECT, ap = display.LEFT_CENTER}
			local btn = display.newButton(offsetX, bgSize.height + 6, params)
			local name = tostring(v.name)
			local title = display.newLabel(0, 0, {text = name, fontSize = 22, color = '#5b3c25'})
			display.commonUIParams(title, {po = cc.p(utils.getLocalCenter(btn).x, utils.getLocalCenter(btn).y)})
			btn:addChild(title)
			btn:setTag(v.id)
			table.insert(segmentBtns, btn)
			view:addChild(btn, 999999)
			display.commonUIParams(btn, {cb = handler(self, self.onClickSegmentItem)})
		end

		return {
			view        = view,
			layer		= layer,
			segmentBtns = segmentBtns,
		}
	end


	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)

	--跳至玩家所在段位保级信息
	self:initShowPlayerReward()
end

function NewKofArenaRewardsView:onClickSegmentItem(sender)
	local index = checkint(sender:getTag())
	self:setSegmentBtnEnabled(index)
	local section 
	if index == self.rewardData.segmentId then
		section = self.rewardData.section
	end
	self:showPageReward(index,section)
end

---初始化玩家所属page
function NewKofArenaRewardsView:initShowPlayerReward()
	local viewData_ = self:getViewData()
	local segmentBtns = viewData_.segmentBtns
	local playerSegmentId = self.rewardData.segmentId
	for k, v in pairs(segmentBtns) do
		if checkint(v:getTag()) == checkint(playerSegmentId) then
			self:onClickSegmentItem(v)
		end
	end
end

---创建所属page
function NewKofArenaRewardsView:showPageReward(segmentId,section)
	self:hidePageReward()
	local viewData_ = self:getViewData()
	local data = self:getRewardDataById(segmentId)
	local size = viewData_.view:getContentSize()
	
	for k, v in pairs(data) do
		local offsetY = size.height - 160 - (k - 1) * 200
		self.itemViewData_ = CreateItem(v.rewards, v.section)
		self.itemViewData_.view:setPosition(size.width/2,offsetY)
		viewData_.layer:addChild(self.itemViewData_.view)
		if checkint(section) == checkint(v.section) then
			---显示选中框
			self.itemViewData_.select:setVisible(true)
		end
	end
end

---清除上页page
function NewKofArenaRewardsView:hidePageReward()
	local viewData_ = self:getViewData()
	local layer = viewData_.layer
	if self.itemViewData_ then
        self.itemViewData_.view:stopAllActions()
        self.itemViewData_.view:runAction(cc.RemoveSelf:create())
		self.itemViewData_.view:removeFromParent(true)
        self.itemViewData_ = nil
		layer:removeAllChildren()
    end
end

---获取所属段位的奖励数据
function NewKofArenaRewardsView:getRewardDataById(id)
	local conf = {}
	for k, v in pairs(self.rewardsDatasConf) do
		for _, p in pairs(v) do
			if checkint(id) == checkint(p.segmentId) then
				table.insert(conf,p)
			end
		end
	end
	table.sort(conf, function(a, b)
		return checkint(a.section) < checkint(b.section)
	end)
	return conf
end

--设置按钮点击
function NewKofArenaRewardsView:setSegmentBtnEnabled(id)
	local viewData_ = self:getViewData()
	local segmentBtns = viewData_.segmentBtns
	for k, v in pairs(segmentBtns) do
		local isEnbled = true
		if checkint(id) == checkint(v:getTag()) then
			isEnbled = false
		end			
		v:setEnabled(isEnbled)
	end
end

function NewKofArenaRewardsView:getViewData()
	return self.viewData
end

return NewKofArenaRewardsView
