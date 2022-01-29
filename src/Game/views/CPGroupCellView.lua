local CPGroupCellView = class('CPGroupCellView', function ()
	local CPGroupCell = CLayout:new()
	CPGroupCell.name = 'home.CPGroupCell'
	CPGroupCell:enableNodeEvents()
	return CPGroupCell
end)

local cardMgr = AppFacade.GetInstance('AppFacade'):GetManager("CardManager")
local gameMgr = AppFacade.GetInstance('AppFacade'):GetManager("GameManager")

local function pairsByKeys(t)      
    local a = {}      
    for n in pairs(t) do          
        a[#a+1] = n      
    end      
    table.sort(a)      
    local i = 0      
    return function()          
    i = i + 1          
    return a[i], t[a[i]]      
    end  
end

function CPGroupCellView:ctor( ... )
	local arg = { ... }
	local cpData = arg[1]
	local available = arg[2]
	local cardListCellSize = cc.size(168, 162)
	local cellSize = cc.size(940, 270 + (math.ceil( table.nums(cpData.cpMembers) / 5 ) - 1) * cardListCellSize.height)
	local viewSize = cc.size(cellSize.width - 14,242 + (math.ceil( table.nums(cpData.cpMembers) / 5 ) - 1) * cardListCellSize.height)
	local cardListSize = cc.size(viewSize.width - 80, math.ceil( table.nums(cpData.cpMembers) / 5 ) * (cardListCellSize.height))
	self:setContentSize(cellSize)
	self.viewData = nil

	local function CreateView( )
		-- 计算星级总数 契约等级
		local starCount = available.starCount
		local contractLevelCount = available.contractLevelCount

		-- 是否完成系列任务
		local groupRewards = CommonUtils.GetConfigNoParser('cardCollection','groupRewards',tonumber(cpData.cpId))
		local complete = table.nums(available.available) >= table.nums(groupRewards)

		-- bg
		local cellBg = display.newImageView(complete and _res('ui/prize/collect_prize_bg_card_finish.png') or _res('ui/prize/collect_prize_bg_card.png'), 
			cellSize.width / 2, 0, {scale9 = true, ap = cc.p(0.5,0), size = cc.size(viewSize.width + (complete and 18 or 0), viewSize.height + (complete and 14 or 0))})
		self:addChild(cellBg, - 2)

		local cardLayout = display.newLayer(cellSize.width / 2, cellSize.height / 2, {size = cellSize, ap = cc.p(0.5,0.5)})
		self:addChild(cardLayout, 1)

		-- cp组合列表
		for k, perCPMember in pairs(cpData.cpMembers) do
			local index = tonumber(k) - 1
			local isHave =  gameMgr:GetCardDataByCardId(tonumber(perCPMember))
			local cardHeadNode = nil
			if not isHave then
				cardHeadNode = require('Game.views.CPCardHeadNode').new({cardData = {cardId = tonumber(perCPMember)},
					showActionState = false, showVigourState = false, showBaseState = false})
				cardHeadNode:SetGray(true)
			else
				cardHeadNode = require('Game.views.CPCardHeadNode').new({id = isHave.id,
					showActionState = false, showVigourState = false, showStarAndContractLv = true})
			end
			cardHeadNode:setAnchorPoint(cc.p(0, 0))
			cardHeadNode:setPosition(cc.p(cardListCellSize.width * (index % 5) + 50, viewSize.height - 220 - cardListCellSize.height * math.floor(index / 5)))
			cardHeadNode:setScale(0.82)
			cardLayout:addChild(cardHeadNode)
		end
		
		-- cp组合名
		local cpGroupName = display.newLabel(16,viewSize.height - 26,{fontSize = 26 , color = "#744f3c" ,text = '', ap = cc.p(0, 0.5)} )
		cardLayout:addChild(cpGroupName)
		if complete then
			cpGroupName:setPosition(cc.p(40,viewSize.height - 28))
		end

   		-- 星级 契约图片
		local starImage = display.newImageView(_res('ui/common/common_star_l_ico.png')
			, viewSize.width - 230, viewSize.height - 30, {scale = 0.84})
		cardLayout:addChild(starImage)
		local cutlineImage = display.newImageView(_res('ui/prize/collect_prize_ico_cp_line.png')
			, viewSize.width - 160, viewSize.height - 30)
		cardLayout:addChild(cutlineImage)
		local heartImage = display.newImageView(_res('ui/prize/collect_prize_contract_ico.png')
			, viewSize.width - 120, viewSize.height - 30, {scale = 0.9})
		cardLayout:addChild(heartImage)

		-- 星级总数
		local starCountLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '-')
		display.commonUIParams(starCountLabel, {fontSize = 24 , color = "#ffffff" , ap = cc.p(1,0.5)})
		starCountLabel:setPosition(cc.p(starImage:getPositionX() + 54, starImage:getPositionY()))
		cardLayout:addChild(starCountLabel)

		-- 契约等级
		local contractLevelCountLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '-')
		display.commonUIParams(contractLevelCountLabel, {fontSize = 24 , color = "#ffffff" , ap = cc.p(1,0.5)})
		contractLevelCountLabel:setPosition(cc.p(heartImage:getPositionX() + 56, heartImage:getPositionY()))
		cardLayout:addChild(contractLevelCountLabel)

		-- 收集进度条
		local barSize = cc.size(83 * math.min(5, table.nums(groupRewards)), 17)
		local progressBarBG = display.newNSprite(_res('ui/prize/collect_prize_bg_loading'), viewSize.width - 44, viewSize.height - 34, 
			{scale9 = true, size = cc.size(barSize.width + 2,barSize.height), capInsets = cc.rect(5, 5, 404, 6), ap = cc.p(1, 0.5)})
		cardLayout:addChild(progressBarBG)

		local clipper = cc.ClippingNode:create()
        clipper:setContentSize(barSize)
        display.commonUIParams(clipper, {ap = cc.p(1, 0.5), po = cc.p(viewSize.width - 45, viewSize.height - 34)})
		cardLayout:addChild(clipper)
		
        local sprite = display.newNSprite(_res('ui/prize/collect_prize_bg_loading_2'), 0,0,{scale9 = true, capInsets = cc.rect(5, 5, 402, 6), size = barSize})
		display.commonUIParams(sprite, {ap = cc.p(0,0), po = cc.p(0,0)})
        clipper:addChild(sprite)
		
		-- 遮罩 显示进度
		local back = cc.LayerColor:create(cc.c4b(0,0,0,153))
        display.commonUIParams(back, {ap = cc.p(0,0),po = cc.p(0,0)})
        clipper:setStencil(back)
        clipper:setInverted(true)

		local startPosX = clipper:getPositionX() - barSize.width
		local y = clipper:getPositionY()
		local stageImages = {}
		local offsetX = barSize.width / table.nums(groupRewards)
		for i = 1, table.nums(groupRewards) - 1 do
			local stageImage = display.newImageView(_res('ui/prize/collect_prize_ico_loading_line.png')
				, i * offsetX + startPosX, y)
			cardLayout:addChild(stageImage)
			table.insert(stageImages, stageImage)
		end
		local completeImages = {}
		local backLights = {}
		local rewardImgs = {}
		local clickLayers = {}
		local i = 1
		local lastRequire = {star = 0, love = 0}
		local isGetUpper = false
		if table.nums(available.available) == table.nums(groupRewards) then
			back:setPositionX(barSize.width)
			isGetUpper = true
		end
		for key, value in pairsByKeys(groupRewards) do    
			-- 完成进度
			if starCount >= tonumber(value.require.star) and contractLevelCount >= tonumber(value.require.love) then
				lastRequire.star = value.require.star
				lastRequire.love = value.require.love
			else
				if not isGetUpper then
					back:setPositionX(barSize.width * (table.nums(available.available) + 
					(math.min(1, (contractLevelCount - tonumber(lastRequire.love)) / (tonumber(value.require.love) - tonumber(lastRequire.love))) + 
					math.min(1, (starCount - tonumber(lastRequire.star)) / (tonumber(value.require.star) - tonumber(lastRequire.star)))) / 2) 
					/ table.nums(groupRewards))
				end

				isGetUpper = true
			end

			local completeImage = display.newImageView(_res('ui/prize/collect_prize_ico_getted.png')
				, i * offsetX + startPosX, y + 9, {ap = cc.p(0.44,0)})
			cardLayout:addChild(completeImage)
			table.insert(completeImages, completeImage)
			completeImage:setVisible(false)

			local backLight = display.newImageView(_res('ui/prize/collect_prize_area_ico_light.png')
				, i * offsetX + startPosX, y + 24)
			cardLayout:addChild(backLight)
   			backLight:runAction(cc.RepeatForever:create(cc.RotateBy:create(0.6, 25)))
   			backLight:setScale(0.3)
			table.insert(backLights, backLight)

			local rewardImg = require('common.GoodNode').new({
				id = value.rewards[1].goodsId,
				showAmount = false
			})
			cardLayout:addChild(rewardImg, 10)
			rewardImg:setPosition(cc.p(i * offsetX + startPosX, y + 24))
			rewardImg:setTag(tonumber(value.rewardId))
			rewardImg:setScale(0.4)
			table.insert(rewardImgs, rewardImg)

			local clickLayer = display.newLayer(i * offsetX + startPosX, y + 24
				, {ap = display.CENTER ,size = cc.size(60,60), color = cc.c4b(0,0,0,0) , enable = true })
			cardLayout:addChild(clickLayer, 10)
			table.insert(clickLayers, clickLayer)

			i = i + 1
		end

		return {
			cardListCellSize		= cardListCellSize,
			cellBg     				= cellBg,
			cpGroupName 			= cpGroupName,	
			starImage				= starImage,
			cutlineImage			= cutlineImage,
			heartImage				= heartImage,
			starCountLabel			= starCountLabel,
			contractLevelCountLabel	= contractLevelCountLabel,
			starCount 				= starCount,
			contractLevelCount 		= contractLevelCount,
			progressBarBG			= progressBarBG,
			clipper					= clipper,
			stageImages				= stageImages,
			completeImages			= completeImages,
			backLights				= backLights,
			rewardImgs				= rewardImgs,
			clickLayers				= clickLayers,
		}
	end

	self.viewData = CreateView()

	self:setStarAndHeartVisible(false)
	self.viewData.cpGroupName:setString(cpData.cpName)
	self.viewData.starCountLabel:setString(self.viewData.starCount)
	self.viewData.contractLevelCountLabel:setString(self.viewData.contractLevelCount)
end

function CPGroupCellView:setStarAndHeartVisible(isVisible)
	self.viewData.starImage:setVisible(isVisible)
	self.viewData.cutlineImage:setVisible(isVisible)
	self.viewData.heartImage:setVisible(isVisible)
	self.viewData.starCountLabel:setVisible(isVisible)
	self.viewData.contractLevelCountLabel:setVisible(isVisible)
end

function CPGroupCellView:HideProgress()
	self.viewData.progressBarBG:setVisible(false)
	self.viewData.clipper:setVisible(false)
	for k, v in pairs(self.viewData.stageImages) do
		v:setVisible(false)
	end
	for k, v in pairs(self.viewData.completeImages) do
		v:setVisible(false)
	end
	for k, v in pairs(self.viewData.backLights) do
		v:setVisible(false)
	end
	for k, v in pairs(self.viewData.rewardImgs) do
		v:setVisible(false)
	end
	for k, v in pairs(self.viewData.clickLayers) do
		v:setTouchEnabled(false)
	end
end

return CPGroupCellView