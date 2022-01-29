--[[
通用道具图标
@params table
{
	id int 道具id
	amount int 道具数量
	showAmount bool 显示数量
	showName bool 显示名称
	callBack function 点击回调
	highlight int 是否高亮
	additionNum int 附加数量
	useSpriteFrame bool 使用SpriteFrame创建
}
--]]
---@class GoodNode : CButton
local GoodNode = class('GoodNode', function ()
	local node = CButton:create()
	node.name = 'common.GoodNode'
	node:enableNodeEvents()
	return node
end)
function GoodNode:ctor( ... )
	local t = unpack({...}) or {}

	-- 初始化数据
	self.goodId = checkint(t.id or t.goodsId or GOLD_ID)
	self.goodAmount = t.amount or t.num or 0
	self.showAmount = t.showAmount or false
	self.showName = t.showName or false
	self.highlight = checkint(t.highlight or 0)
	self.callBack = t.callBack
	self.from = t.from
	self.goodData = CommonUtils.GetConfig('goods', 'goods',self.goodId) or {}
	self.blingLimit = t.blingLimit -- 抽宝石保底显示闪光
	self.additionNum = checkint(t.additionNum)
	self.showRemindIcon = t.showRemindIcon or false -- 显示小红点
	self.useSpriteFrame = t.useSpriteFrame or false
	self:setScale(t.scale or 1)

	-- 初始化ui
	self:initUI()

	-- 绑定点击回调
	if self.callBack then
		self:setTouchEnabled(true)
		self:setOnClickScriptHandler(function (sender)
			-- print('---TODO---\nshow good introduction')
	    	local isFlipX = sender:getScaleX() < 0
	        local fScale  = math.abs(sender:getScaleX())
	        if isFlipX then
	            fScale = 1.0
	        end
	        transition.execute(sender,cc.Sequence:create(
	            cc.EaseOut:create(cc.ScaleTo:create(0.03, (isFlipX and -1 or 1) * 0.97*fScale, 0.97*fScale), 0.03),
	            cc.EaseOut:create(cc.ScaleTo:create(0.03, (isFlipX and -1 or 1) * 1*fScale, 1*fScale), 0.03),
	            cc.CallFunc:create(function()
	                self.callBack(sender)
	            end)
	        ))
		end)
	end
end
function GoodNode:initUI()
	-- bg
	local quality = CommonUtils.GetGoodsQuality(self.goodId)
	local bgPath = string.format('ui/common/common_frame_goods_%d.png', quality)
	local bg
	if self.useSpriteFrame then
		bg = FilteredSpriteWithOne:createWithSpriteFrameName(_res(bgPath))
		bg:setFlippedY(true)
	else
		bg = display.newImageView(_res(bgPath), 0, 0)
	end
	local bgSize = bg:getContentSize()
	self:setContentSize(bgSize)
	self:addChild(bg, 6)
	local selfCenterPoint = utils.getLocalCenter(self)
	bg:setPosition(selfCenterPoint)
	self.bg = bg

	-- icon
	local iconPath = CommonUtils.GetGoodsIconPathById(self.goodId)
	local icon
	if self.useSpriteFrame then
		icon = FilteredSpriteWithOne:createWithSpriteFrameName(_res(iconPath))
		icon:setPosition(selfCenterPoint.x, selfCenterPoint.y)
		icon:setFlippedY(true)
	else
		icon = display.newLayer(selfCenterPoint.x, selfCenterPoint.y)
		icon:addChild(CommonUtils.GetGoodsIconNodeById(self.goodId))
	end
	icon:setScale(0.55)
	self:addChild(icon, 6)
	self.icon = icon

	local fragmentPath = string.format('ui/common/common_ico_fragment_%d.png', checkint(self.goodData.quality or 1))
	local fragmentImg
	if self.useSpriteFrame then
		fragmentImg = FilteredSpriteWithOne:createWithSpriteFrameName(_res(fragmentPath))
		fragmentImg:setPosition(selfCenterPoint.x, selfCenterPoint.y)
		fragmentImg:setFlippedY(true)
	else
		fragmentImg = display.newImageView(_res(fragmentPath), selfCenterPoint.x, selfCenterPoint.y,{as = false})
	end
    self:addChild(fragmentImg,6)
    self.fragmentImg = fragmentImg
    self.fragmentImg:setVisible(false)
    if self.goodData.type then
    	if tostring(self.goodData.type) == GoodsType.TYPE_CARD_FRAGMENT then
    		self.fragmentImg:setVisible(true)
		elseif 	 tostring(self.goodData.type) == GoodsType.TYPE_RECIPE then
			self.fragmentImg:setVisible(true)
			if self.useSpriteFrame then
				self.fragmentImg:setSpriteFrame(cc.SpriteFrameCache:getInstance():getSpriteFrame(_res('ui/common/common_ico_food_horn.png')))
				self.bg:setSpriteFrame(cc.SpriteFrameCache:getInstance():getSpriteFrame(_res('ui/common/common_frame_food.png')))
			else
				self.fragmentImg:setTexture(_res('ui/common/common_ico_food_horn.png'))
				self.bg:setTexture(_res('ui/common/common_frame_food.png'))
			end
    	end
		self:AddAchieverSpine(self.goodData)
    end
    ------------ 皮肤外框 ------------
    local coverPath = 'ui/common/common_frame_goods_7_pifu.png'
	local coverImg
	if self.useSpriteFrame then
		coverImg = FilteredSpriteWithOne:createWithSpriteFrameName(_res(coverPath))
		coverImg:setPosition(selfCenterPoint.x, selfCenterPoint.y)
		coverImg:setFlippedY(true)
	else
		coverImg = display.newImageView(_res(coverPath), selfCenterPoint.x, selfCenterPoint.y)
	end
    self:addChild(coverImg, 6)
    self.coverImg = coverImg
    self.coverImg:setVisible(GoodsType.TYPE_CARD_SKIN == CommonUtils.GetGoodTypeById(self.goodId))
    ------------ 皮肤外框 ------------



	if self.blingLimit then
		if GoodsType.TYPE_GEM == CommonUtils.GetGoodTypeById(self.goodId) then
			local artiMgr = AppFacade.GetInstance():GetManager("ArtifactManager")
			local gemstone = artiMgr:GetConfigDataByName(artiMgr:GetConfigParse().TYPE.GEM_STONE)
			local grade = gemstone[tostring(self.goodId)].grade
			for k,v in pairs(self.blingLimit) do
				if checkint(v) == checkint(grade) then
					local luckySpine = sp.SkeletonAnimation:create(
						'effects/artifact/biaoqian.json',
						'effects/artifact/biaoqian.atlas',
					1)
					luckySpine:setPosition(cc.p(selfCenterPoint.x, selfCenterPoint.y - 6))
					self:addChild(luckySpine, 10)
					luckySpine:setAnimation(0, 'idle3', true)
					luckySpine:update(0)
					luckySpine:setToSetupPose()
					break
				end
			end
		end
	end

	-- amount Label
	local infoLabelStr = ''
	if self.showAmount then
		infoLabelStr = tostring(self.goodAmount)
	end
	local infoLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
	display.commonUIParams(infoLabel, {ap = cc.p(1,0.5)})
	infoLabel:setPosition(cc.p(bgSize.width - 5, selfCenterPoint.y - bgSize.height * 0.5 + 15))
	infoLabel:setString(infoLabelStr)
	-- infoLabel:setScale(0.6)
	self:addChild(infoLabel,10)
	self.infoLabel = infoLabel
	if self.additionNum > 0 and self.showAmount then
		local str = '+' .. tostring(self.additionNum)
		local additionLabel = cc.Label:createWithBMFont('font/small/common_num_unused.fnt', str)
		display.commonUIParams(additionLabel, {ap = cc.p(1,0.5)})
		additionLabel:setPosition(cc.p(bgSize.width - 5, selfCenterPoint.y - bgSize.height * 0.5 + 15))
		self:addChild(additionLabel,10)
		infoLabel:setPositionX(bgSize.width - 8 - additionLabel:getContentSize().width)
	end

	-- name Label
	infoLabelStr = ''
	if self.showName then
		-- 金币 体力 幻晶石 不在道具表中 需要特殊判断 t
		if self.goodId == GOLD_ID then
			infoLabelStr = __('金币')
		elseif self.goodId == DIAMOND_ID then
			infoLabelStr = __('幻晶石')
		elseif self.goodId == HP_ID then
			infoLabelStr = __('体力')
		elseif self.goodId == EXP_ID then
			infoLabelStr = __('经验值')
		elseif self.goodId == CARD_EXP_ID then
			infoLabelStr = __('飨灵经验')
		else
			infoLabelStr = self.goodData.name or string.format('%s不存在', tostring(self.goodId))
		end
	end
	if self.highlight == 1 then
		self.frameSpine = sp.SkeletonAnimation:create('effects/activity/biankuang.json', 'effects/activity/biankuang.atlas', 1)
		self.frameSpine:update(0)
		self.frameSpine:setAnimation(0, 'idle', true)
		self:addChild(self.frameSpine,10)
		self.frameSpine:setPosition(utils.getLocalCenter(self))
	end
	if self.showRemindIcon then
		local remindIcon = display.newImageView(_res('ui/common/common_hint_circle_red_ico.png'), 5, bgSize.height - 5)
		self:addChild(remindIcon, 10)
	end
	local nameLabel = display.newLabel(selfCenterPoint.x, selfCenterPoint.y - bgSize.height * 0.5 - 15,
		{ap = display.CENTER_TOP, text = infoLabelStr,hAlign = display.TAC ,fontSize = 20, color = '#6b5959', w = 140})
	self:addChild(nameLabel,10)
	self.nameLabel = nameLabel

	-- 宝石显示等级
	-- level
	local levelBg = FilteredSpriteWithOne:create()
	levelBg:setCascadeOpacityEnabled(true)
	levelBg:setTexture(_res('ui/cards/head/kapai_zhiye_colour.png'))
	levelBg:setAnchorPoint(cc.p(0.5, 1))
	levelBg:setPosition(cc.p(bgSize.width * 0.26, bgSize.height + 2))
	self:addChild(levelBg, 20)
	levelBg:setVisible(CommonUtils.GetGoodTypeById(self.goodId) == GoodsType.TYPE_GEM)
	self.levelBg = levelBg

	local level = ''
	if CommonUtils.GetGoodTypeById(self.goodId) == GoodsType.TYPE_GEM then
		local artiMgr = AppFacade.GetInstance():GetManager("ArtifactManager")
		local gemstone = artiMgr:GetConfigDataByName(artiMgr:GetConfigParse().TYPE.GEM_STONE)
		if gemstone[tostring(self.goodId)] then
			level = gemstone[tostring(self.goodId)].grade
		end
	end
	-- level label
	local levelLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', level)
	display.commonUIParams(
		levelLabel,
		{
			ap = cc.p(0.5, 1),
			po = cc.p(utils.getLocalCenter(levelBg).x - 1, levelBg:getContentSize().height - 7)
		})
	levelBg:addChild(levelLabel)
	self.levelLabel = levelLabel

	local selectedImg = display.newImageView(_res('ui/common/common_bg_frame_goods_elected.png'),selfCenterPoint.x,selfCenterPoint.y,{as = false, scale = 0.95})
	self:addChild(selectedImg, 30)
	self.selectedImg = selectedImg
	self:updateSelectedImgVisible(false)

	local newImg = ui.image({img = _res('ui/card_preview_ico_new_2.png')})
	self:addList(newImg, 31):alignTo(nil, ui.lt)
	self.newImg = newImg
	self:updateNewImgVisible(false)
end

function GoodNode:setState( num )
	-- body
	if num < 0 then
		self.icon:setColor(ccc3FromInt('#9c9c9c'))
		-- self.bg:setColor(ccc3FromInt('#9c9c9c'))
		self.infoLabel:setColor(ccc3FromInt('#be462a'))
	else
		-- self.bg:setColor(ccc3FromInt('#ffffff'))
		self.icon:setColor(ccc3FromInt('#ffffff'))
		self.infoLabel:setColor(ccc3FromInt('#ffffff'))
	end
end

function GoodNode:updataNum( num )
	-- body
	if num <= 0 then
		self.icon:setColor(ccc3FromInt('#9c9c9c'))
		self.bg:setColor(ccc3FromInt('#9c9c9c'))
		self.infoLabel:setString(tostring(0))
		self.infoLabel:setColor(ccc3FromInt('#be462a'))
	else
		self.bg:setColor(ccc3FromInt('#ffffff'))
		self.icon:setColor(ccc3FromInt('#ffffff'))
		self.infoLabel:setString(tostring(num))
		self.infoLabel:setColor(ccc3FromInt('#ffffff'))
	end
end


function GoodNode:updateSelectedImgVisible(visible)
	self.selectedImg:setVisible(visible)
end

function GoodNode:updateNewImgVisible(visible)
	self.newImg:setVisible(visible)
end

function GoodNode:setGoodAmount( num )
	self.infoLabel:setString(tostring(num))
end


--[[
刷新goodNode
@params data table {
	goodsId int 道具id
	amount int 道具数量
	nameMaxW int 名字的最大宽度
}
--]]
function GoodNode:RefreshSelf(data)
	if data.goodsId or data.id then
		self.goodId = checkint(data.id or data.goodsId or GOLD_ID)
		self.goodData = CommonUtils.GetConfig('goods', 'goods', self.goodId) or {}
		local bgPath = string.format('ui/common/common_frame_goods_%d.png', checkint(self.goodData.quality or 1))
		if self.useSpriteFrame then
			self.bg:setSpriteFrame(cc.SpriteFrameCache:getInstance():getSpriteFrame(_res(bgPath)))
			self.icon:setSpriteFrame(cc.SpriteFrameCache:getInstance():getSpriteFrame(_res(CommonUtils.GetGoodsIconPathById(self.goodId))))
			local fragmentPath = string.format('ui/common/common_ico_fragment_%d.png', checkint(self.goodData.quality or 1))
			self.fragmentImg:setSpriteFrame(cc.SpriteFrameCache:getInstance():getSpriteFrame(_res(fragmentPath)))
		else
			self.bg:setTexture(_res(bgPath))
			self.icon:removeAllChildren()
			self.icon:addChild(CommonUtils.GetGoodsIconNodeById(self.goodId))
			local fragmentPath = string.format('ui/common/common_ico_fragment_%d.png', checkint(self.goodData.quality or 1))
			self.fragmentImg:setTexture(_res(fragmentPath))
		end

	    self.fragmentImg:setVisible(false)
	    if self.goodData.type then
	    	if tostring(self.goodData.type) == GoodsType.TYPE_CARD_FRAGMENT then
	    		self.fragmentImg:setVisible(true)
	    	end
	    end

	    ------------ 皮肤外框 ------------
	    self.coverImg:setVisible(GoodsType.TYPE_CARD_SKIN == CommonUtils.GetGoodTypeById(self.goodId))
	    ------------ 皮肤外框 ------------
	end
	if (data.amount or data.num) and (self.showAmount or data.showAmount) then
		self.goodAmount = data.amount or data.num or 0
		self.infoLabel:setString(string.format('%d', self.goodAmount))
	end
	if self.highlight == 1 and data.highlight then
		if checkint(data.highlight) == 1 then
			self.frameSpine:setVisible(true)
		else
			self.frameSpine:setVisible(false)
		end
	end
	if self.callBack and data.callBack then
		self.callBack = data.callBack
	end
	if self.showName then
		local infoLabelStr = ''
		-- 金币 体力 幻晶石 不在道具表中 需要特殊判断
		if self.goodId == GOLD_ID then
			infoLabelStr = __('金币')
		elseif self.goodId == DIAMOND_ID then
			infoLabelStr = __('幻晶石')
		elseif self.goodId == HP_ID then
			infoLabelStr = __('体力')
		else
			infoLabelStr = self.goodData.name or string.format('%s不存在', tostring(self.goodId))
		end
		if checkint(data.nameMaxW) > 0 then
			display.commonLabelParams(self.nameLabel, {text = infoLabelStr, maxW = data.nameMaxW})
		else
			self.nameLabel:setString(infoLabelStr)
		end
	end

	-- 宝石显示等级
	self.levelBg:setVisible(CommonUtils.GetGoodTypeById(self.goodId) == GoodsType.TYPE_GEM)

	local level = ''
	if CommonUtils.GetGoodTypeById(self.goodId) == GoodsType.TYPE_GEM then
		local artiMgr = AppFacade.GetInstance():GetManager("ArtifactManager")
		local gemstone = artiMgr:GetConfigDataByName(artiMgr:GetConfigParse().TYPE.GEM_STONE)
		if gemstone[tostring(self.goodId)] then
			level = gemstone[tostring(self.goodId)].grade
		end
	end
	self.levelLabel:setString(level)
	self:AddAchieverSpine(self.goodData)
end
function GoodNode:AddAchieverSpine(goodData)
	goodData = goodData or {}
	if self.spineAction and (not tolua.isnull( self.spineAction)) then
		self.spineAction:removeFromParent()
	end
	if 	 tostring(goodData.type) == GoodsType.TYPE_ARCHIVE_REWARD then
		local spineAction = CommonUtils.GetAchieveRewardsGoodsSpineActionById(goodData.goodId or goodData.id )
		if spineAction then
			local bgSize = self:getContentSize()
			self:addChild(spineAction,12)
			spineAction:setPosition(bgSize.width * 0.5, bgSize.height * 0.5)
			spineAction:setScale(0.55)
		end
		self.spineAction = spineAction

	end
end


return GoodNode
