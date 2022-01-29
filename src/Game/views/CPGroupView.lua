--[[
CP组合进度页面
--]]
local GameScene = require( "Frame.GameScene" )
local CPGroupView = class('CPGroupView', GameScene)

local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local cardMgr = AppFacade.GetInstance('AppFacade'):GetManager("CardManager")
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")

local SLIDE_RANGE       = 5     	-- 滑动手势识别范围
local INTERVAL_INTERVAL = 0.01   	-- 惯性滑动触发时间间隔
local INTERVAL_FALL     = 0.86  	-- 惯性滑动衰减速度
local SCROLL_TIME       = 0.2

function CPGroupView:ctor( ... )
	local arg = { ... }
	local areaData = arg[1]
	local available = arg[2]
	self.areaData = areaData

	local function CreateView( )
		local view = CLayout:create(display.size)
		display.commonUIParams(view, {po = display.center})
		self:addChild(view)

		-- 左侧详情区域
		local detailImage = display.newImageView(_res('ui/prize/collect_prize_bg_area_1.png'), display.cx - 480, display.cy - 76)
		detailImage:setAnchorPoint(0.5, 0.5)
		view:addChild(detailImage)

		-- 宝箱底下光圈
		local boxBG = display.newImageView(_res('ui/prize/collect_prize_bg_area_prize.png'), detailImage:getContentSize().width / 2, detailImage:getContentSize().height / 2 + 84)
		boxBG:setAnchorPoint(0.5, 0.5)
		detailImage:addChild(boxBG)

		-- 宝箱
		local chestSpine = sp.SkeletonAnimation:create('effects/xiaobaoxiang/box_15.json', 'effects/xiaobaoxiang/box_15.atlas')
        chestSpine:update(0)
        chestSpine:setToSetupPose()
        chestSpine:setAnimation(0, 'stop', true)
        chestSpine:setPosition(cc.p(boxBG:getContentSize().width / 2, boxBG:getContentSize().height / 2))
        boxBG:addChild(chestSpine, 10)

    	-- 点击的layer
    	local clickLayer = display.newLayer(display.cx - 480, display.cy + 26, {ap = display.CENTER ,size = cc.size(140,120), color = cc.c4b(0,0,0,0) , enable = true })
		view:addChild(clickLayer)
	
		-- 地区收集完成
		local areaFinishImg = display.newImageView(_res('ui/prize/collect_prize_bg_area_finish.png'), display.cx - 484, display.cy - 68)
		areaFinishImg:setAnchorPoint(0.5, 0.5)
		view:addChild(areaFinishImg)

		-- 地区名横幅
		local areaNameTablet = display.newButton(detailImage:getContentSize().width / 2, detailImage:getContentSize().height / 2 + 30, {n = _res('ui/home/nmain/main_maps_bg_name_local.png'), enable = false})
		detailImage:addChild(areaNameTablet)

		-- 地区名
		display.commonLabelParams(areaNameTablet, {fontSize = 24 , color = "#7e6454" ,text = '-', reqW = 120})

		local detailStartPosX = detailImage:getPositionX() - detailImage:getContentSize().width / 2
		local textList = {__('飨灵数量'), __('星级总数'), __('契约级别数')}
		for i = 1, 3 do
			local Desp = display.newLabel(detailStartPosX + 20, 300 - i * 40,fontWithColor(5,{text = textList[i], ap = cc.p(0, 0.5), reqW = 155}) )
			view:addChild(Desp)

			local Cutline = display.newImageView(_res('ui/prize/collect_prize_area_ico_line.png')
				, detailStartPosX + detailImage:getContentSize().width / 2, 284 - i * 40)
			view:addChild(Cutline)
		end

		-- 飨灵数量
		local cardCountLabel = display.newRichLabel(detailStartPosX + detailImage:getContentSize().width - 70,260,
			{ ap = cc.p(0.5, 0.5) })
		view:addChild(cardCountLabel)
		cardCountLabel:insertElement(cc.Label:createWithBMFont('font/small/common_text_num.fnt', '-'))
		cardCountLabel:insertElement(cc.Label:createWithBMFont('font/small/common_text_num.fnt', '/'))
		cardCountLabel:insertElement(cc.Label:createWithBMFont('font/small/common_text_num.fnt', '-'))
		cardCountLabel:reloadData()

		-- 星级总数
		local starCountLabel = display.newRichLabel(detailStartPosX + detailImage:getContentSize().width - 60,220,
			{ ap = cc.p(1, 0.5) })
		view:addChild(starCountLabel)
		starCountLabel:insertElement(cc.Label:createWithBMFont('font/small/common_text_num.fnt', '-'))
		starCountLabel:insertElement(cc.Label:createWithBMFont('font/small/common_text_num.fnt', '/'))
		starCountLabel:insertElement(cc.Label:createWithBMFont('font/small/common_text_num.fnt', '-'))
		starCountLabel:reloadData()
		local starImage = display.newImageView(_res('ui/common/common_star_l_ico.png')
			, starCountLabel:getPositionX() + 24, starCountLabel:getPositionY() + 2, {scale = 0.9})
		view:addChild(starImage)

		-- 契约等级
		local contractLevelCountLabel = display.newRichLabel(detailStartPosX + detailImage:getContentSize().width - 60,180,
			{ ap = cc.p(1, 0.5) })
		view:addChild(contractLevelCountLabel)
		contractLevelCountLabel:insertElement(cc.Label:createWithBMFont('font/small/common_text_num.fnt', '-'))
		contractLevelCountLabel:insertElement(cc.Label:createWithBMFont('font/small/common_text_num.fnt', '/'))
		contractLevelCountLabel:insertElement(cc.Label:createWithBMFont('font/small/common_text_num.fnt', '-'))
		contractLevelCountLabel:reloadData()
		local heartImage = display.newImageView(_res('ui/prize/collect_prize_contract_ico.png')
			, contractLevelCountLabel:getPositionX() + 24, contractLevelCountLabel:getPositionY() + 2, {scale = 0.9})
		view:addChild(heartImage)

		local height = display.cy + 208
		local cpScrollView = CScrollView:create(cc.size(940, height))
		cpScrollView:setDirection(eScrollViewDirectionVertical)
		cpScrollView:setPosition(cc.p(display.cx - 310, 70))
		cpScrollView:setAnchorPoint(display.LEFT_BOTTOM)
		view:addChild(cpScrollView)
		
		local CPGroupCells = {}
		local totalHeight = 0
		for k , perCPData in pairs (areaData.cpGroups) do
			local CPGroupCellView = require('Game.views.CPGroupCellView').new(perCPData, available[tostring(perCPData.cpId)])
			CPGroupCellView:setTag(tonumber(perCPData.cpId))
			cpScrollView:getContainer():addChild(CPGroupCellView)
			table.insert(CPGroupCells, CPGroupCellView)

			totalHeight = totalHeight + CPGroupCellView:getContentSize().height
		end
		totalHeight = math.max(height, totalHeight)
		cpScrollView:setContainerSize(cc.size(940, totalHeight))
		for k, v in pairs(CPGroupCells) do
			v:setPositionY(totalHeight - v:getContentSize().height)
			totalHeight = totalHeight - v:getContentSize().height
		end
		cpScrollView:setContentOffsetToTop()

		return {
			view					= view,
			areaFinishImg			= areaFinishImg,
			clickLayer				= clickLayer,
			cpScrollView			= cpScrollView,
			detailImage				= detailImage,
			areaNameTablet			= areaNameTablet,
			areaName 				= areaNameTablet:getLabel(),
			cardCountLabel			= cardCountLabel,
			starCountLabel 			= starCountLabel,
			contractLevelCountLabel = contractLevelCountLabel,
			CPGroupCells			= CPGroupCells,
			chestSpine				= chestSpine,
		}
	end

	self.viewData = CreateView( )

	self.viewData.detailImage:setTexture(_res(string.format('ui/prize/collect_prize_bg_area_%d.png', areaData.areaId)))
	display.commonLabelParams(self.viewData.areaNameTablet, {fontSize = 24 , color = "#7e6454" ,text = areaData.areaName, reqW = 140})
end

function CPGroupView:setLabelText( target, own, des )
	if des then
		target:removeAllElements()
		target:insertElement(cc.Label:createWithBMFont(tonumber(own) >= tonumber(des) and 'font/small/common_text_num.fnt' or 'font/small/common_text_num_5.fnt', own))
		target:insertElement(cc.Label:createWithBMFont('font/small/common_text_num.fnt', '/'))
		target:insertElement(cc.Label:createWithBMFont('font/small/common_text_num.fnt', des))
		target:reloadData()
	else
		target:removeAllElements()
		target:insertElement(cc.Label:createWithBMFont('font/small/common_text_num.fnt', own))
		target:reloadData()
	end
end

return CPGroupView