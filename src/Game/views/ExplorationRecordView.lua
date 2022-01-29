--[[
探索记录界面
--]]
local CommonDialog = require('common.CommonDialog')
local ExplorationRecordView = class('ExplorationRecordView', CommonDialog)

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
function ExplorationRecordView:InitialUI()
	local currentNum = self.args.floorNum or 1
	local recordDatas = self.args.recordDatas or {}
	local function CreateView()
		-- bg
		local bg = display.newImageView(_res('ui/common/common_bg_2.png'), 0, 0)
		local bgSize = bg:getContentSize()
		-- bg view
		local view = display.newLayer(0, 0, {size = bgSize, ap = cc.p(0.5, 0.5)})
		display.commonUIParams(bg, {po = cc.p(utils.getLocalCenter(view))})
		view:addChild(bg, 5)
		-- title
		local titleBg = display.newButton(0, 0, {n = _res('ui/common/common_bg_title_2.png'), animation = false})
		display.commonUIParams(titleBg, {po = cc.p(bgSize.width * 0.5, bgSize.height - titleBg:getContentSize().height * 0.5)})
		display.commonLabelParams(titleBg,
			fontWithColor(14,{text = __('探索记录'),
			fontSize = fontWithColor('3').fontSize, color = fontWithColor('3').color,
			offset = cc.p(0, -2)}))
		bg:addChild(titleBg)
		-- local floorLabel = display.newLabel(bgSize.width/2, 550, {text = __('本次探索已达到          层'), fontSize = 24, color = '#5b3c25'})
		-- view:addChild(floorLabel, 10)
		local titleLayout = CLayout:create()
		local strs = string.split(__('本次探索已达到|_num_|层'), "|")
		local afterLabel = display.newLabel(0, 30, {text = strs[3], fontSize = 24, color = '#5b3c25', ap = cc.p(1, 0.5)})
    	local floorNum = cc.Label:createWithBMFont('font/levelup.fnt', '888')
    	floorNum:setString(tostring(currentNum))
    	floorNum:setAnchorPoint(cc.p(1,0.5))
    	floorNum:setPosition(cc.p(0, 35))
    	local frontLabel = display.newLabel(0, 30, {text = strs[1], fontSize = 24, color = '#5b3c25', ap = cc.p(1, 0.5)})
    	local titleW = display.getLabelContentSize(afterLabel).width + floorNum:getContentSize().width + display.getLabelContentSize(frontLabel).width
    	titleLayout:setContentSize(cc.size(titleW, 60))
    	titleLayout:setPosition(bgSize.width/2, 550)
    	view:addChild(titleLayout, 10)
    	
		local posX = titleW
		afterLabel:setPositionX(posX)
    	titleLayout:addChild(afterLabel, 10)
    	local posX = posX - display.getLabelContentSize(afterLabel).width - 10
		floorNum:setPositionX(posX)
    	titleLayout:addChild(floorNum, 10)
    	local posX = posX - floorNum:getContentSize().width - 10
		frontLabel:setPositionX(posX)
    	titleLayout:addChild(frontLabel, 10)

    	local line = display.newImageView(_res('ui/home/exploration/discovery_record_bg_line.png'), bgSize.width/2, 515)
    	view:addChild(line, 10)
		local function CreateCell( text ) 
			local size = cc.size(696, 122)
			local cell = CLayout:create(size)
			cell:setAnchorPoint(cc.p(0.5, 0.5))
			local bg = display.newImageView(_res('ui/home/exploration/discovery_record_bg.png'), size.width/2, size.height/2)
			cell:addChild(bg, -1)
			local titleBg = display.newButton(size.width/2, 106, {n = _res('ui/common/common_bg_title_5.png'), enable = false, scale9 = true, size = cc.size(300, 24)})
			cell:addChild(titleBg, 10)
			display.commonLabelParams(titleBg, fontWithColor(14, {text = text, fontSize = 24}))
			return cell
		end 
		local basicRewardCell = CreateCell(__('当前探索获得'))
		basicRewardCell:setPosition(cc.p(bgSize.width/2, 449))
		view:addChild(basicRewardCell, 10)
		if next(recordDatas.baseReward) ~= nil then
			local layout = CLayout:create(cc.size(180 + (#recordDatas.baseReward-1)*180, 122))
			layout:setPosition(cc.p(basicRewardCell:getContentSize().width/2, basicRewardCell:getContentSize().height/2))
			basicRewardCell:addChild(layout)
			for i,v in ipairs(recordDatas.baseReward) do
				local num = cc.Label:createWithBMFont('font/small/common_text_num.fnt', v.num)
				num:setPosition(cc.p((i-1)*180, 35))
				num:setAnchorPoint(cc.p(0, 0.5))
				layout:addChild(num, 10)
				local goodsIcon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(v.goodsId)), num:getContentSize().width + (i-1)*180, 35, {ap = cc.p(0, 0.5)})
				goodsIcon:setScale(0.4)
				layout:addChild(goodsIcon, 10)
			end
		end
		local chestCell = CreateCell(__('当前获得宝箱'))
		chestCell:setPosition(cc.p(bgSize.width/2, 326))
		view:addChild(chestCell, 10)
		if next(recordDatas.chestReward) ~= nil then
			local layout = CLayout:create(cc.size(100 + (#recordDatas.chestReward-1)*100, 122))
			layout:setPosition(cc.p(chestCell:getContentSize().width/2, chestCell:getContentSize().height/2))
			chestCell:addChild(layout)
			for i,v in ipairs(recordDatas.chestReward) do
				local chestIcon = display.newImageView(_res(CommonUtils.GetGoodsIconPathById(v.goodsId)), 50 + (i-1)*100, 35, {ap = cc.p(0.5, 0.5)})
				chestIcon:setScale(0.55)
				layout:addChild(chestIcon, 10)
				local chestNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', tostring(v.num))
				chestNum:setPosition(cc.p(85 + (i-1)*100, 0))
				chestNum:setScale(0.6)
				chestNum:setAnchorPoint(cc.p(1, 0))
				layout:addChild(chestNum, 10)
			end
		end
		local BossCell = CreateCell(__('探索打败BOSS'))
		BossCell:setPosition(cc.p(bgSize.width/2, 203))
		view:addChild(BossCell, 10)
		if next(recordDatas.boss) ~= nil then
			local layout = CLayout:create(cc.size(80 + (#recordDatas.boss-1)*100, 122))
			layout:setPosition(cc.p(BossCell:getContentSize().width/2, BossCell:getContentSize().height/2))
			BossCell:addChild(layout)
			for i,v in ipairs(recordDatas.boss) do
				local drawId = CommonUtils.GetConfig('monster', 'monster', v.bossId).drawId
                local drawPath = AssetsUtils.GetCardHeadPath(drawId)
				local bossHeadImage = display.newImageView(drawPath, (i-1)*100, 45, {ap = cc.p(0, 0.5)})
				layout:addChild(bossHeadImage, 10)
				bossHeadImage:setScale(0.5)
				local bossNum = cc.Label:createWithBMFont('font/small/common_text_num.fnt', v.num)
				bossNum:setPosition(cc.p(160, 0))
				bossNum:setScale(0.8)
				bossNum:setAnchorPoint(cc.p(1, 0))
				bossHeadImage:addChild(bossNum, 10)		
			end
		end
		local goodsCell = CreateCell(__('探索获得道具'))
		goodsCell:setPosition(cc.p(bgSize.width/2, 80))
		view:addChild(goodsCell, 10)
		local listSize = cc.size(500, 110)
		local listCellSize = cc.size(100, 122)
		local listView = CListView:create(listSize)
		listView:setDirection(eScrollViewDirectionHorizontal)
		listView:setBounceable(true)
		goodsCell:addChild(listView)
		listView:setAnchorPoint(cc.p(0.5, 0.5))
		listView:setPosition(cc.p(goodsCell:getContentSize().width/2, 45))
		for i,v in ipairs(recordDatas.goodsReward) do
			local layout = CLayout:create(cc.size(100, 100))
			local goodsNode = require('common.GoodNode').new({
				id = v.goodsId,
				amount = v.num,
				showAmount = true,
				callBack = function (sender)
					local index_ = sender:getParent():getTag()
					uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = v.goodsId, type = 1})
				end
			})
			goodsNode:setScale(0.8)
			goodsNode:setPosition(cc.p(50, 55))
			layout:addChild(goodsNode)
			listView:insertNodeAtLast(layout)
		end
		listView:reloadData()
		return {
			view        = view,

		}
	end
	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)
end
return ExplorationRecordView
