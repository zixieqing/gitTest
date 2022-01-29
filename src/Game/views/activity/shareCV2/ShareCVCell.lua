---@class ShareCVCell
local ShareCVCell = class('ShareCVCell', function ()
	local ShareCVCell = CGridViewCell:new()
	ShareCVCell.name = 'home.ShareCVCell'
	ShareCVCell:enableNodeEvents()
	return ShareCVCell
end)
local newLayer = display.newLayer
local newButton = display.newButton
local newLabel = display.newLabel
local newImageView = display.newImageView
local RES_DICT ={
	CVSHARE_TASK_BG_LOCK          = _res('ui/home/activity/cv2/cvshare_task_bg_lock.png'),
	CVSHARE_TASK_BG               = _res('ui/home/activity/cv2/cvshare_task_bg.png'),
	SHOP_RECHARGE_LIGHT_RED       = _res('ui/home/commonShop/shop_recharge_light_red.png'),
	COMMON_ARROW                  = _res('ui/home/commonShop/common_arrow.png'),
	CVSHARE_TASK_BG_COMPLETE      = _res('ui/home/activity/cv2/cvshare_task_bg_complete.png'),
	GOODS_ICON_195149             = _res('arts/goods/goods_icon_195149.png')
}
function ShareCVCell:ctor( ... )
	local cellSize = cc.size(355, 90)
	self:setContentSize(cellSize)
	self:setCascadeOpacityEnabled(true)
	local cellLayout = newButton(cellSize.width/2, cellSize.height/2 ,
			{ ap = display.CENTER, size = cellSize , enable = true })
	self:addChild(cellLayout)
	--cellLayout:setVisible(false)
	local cellBgImage = newImageView(RES_DICT.CVSHARE_TASK_BG, 177, 44,
			{ ap = display.CENTER, tag = 17, enable = false })
	cellLayout:addChild(cellBgImage)

	local rewardImage = newImageView(RES_DICT.SHOP_RECHARGE_LIGHT_RED, 52, 40,
			{ ap = display.CENTER, tag = 49, enable = false })
	cellLayout:addChild(rewardImage)
	rewardImage:setVisible(false)

	local chestImage = newImageView(RES_DICT.GOODS_ICON_195149, 54, 44,
			{ ap = display.CENTER, tag = 18, enable = false })
	cellLayout:addChild(chestImage)
	chestImage:setScale(0.5)
	local taskDescrLabel = newLabel(115, 60,
			{ ap = display.LEFT_CENTER, color = '#5b3c25', text = __('累计完成日常任务'), fontSize = 22, tag = 19 })
	cellLayout:addChild(taskDescrLabel)

	local taskPrograssLabel = newLabel(115, 25,
			{ ap = display.LEFT_CENTER, color = '#5b3c25', text = "", fontSize = 22, tag = 20 })
	cellLayout:addChild(taskPrograssLabel)

	local completeImage = newImageView(RES_DICT.CVSHARE_TASK_BG_LOCK, 177, 44,
			{ ap = display.CENTER, tag = 48, enable = false })
	cellLayout:addChild(completeImage)
	completeImage:setVisible(false)

	local hasDrawnImage = newImageView(RES_DICT.COMMON_ARROW , 54, 44 )
	cellLayout:addChild(hasDrawnImage)
	hasDrawnImage:setVisible(false)
	self.viewData = {
		cellLayout              = cellLayout,
		cellBgImage             = cellBgImage,
		rewardImage             = rewardImage,
		chestImage              = chestImage,
		taskDescrLabel          = taskDescrLabel,
		taskPrograssLabel       = taskPrograssLabel,
		hasDrawnImage           = hasDrawnImage,
		completeImage           = completeImage,
	}
end
---UpdateTaskCell 更新任务的分享
---@param data table
function ShareCVCell:UpdateTaskCell(data)
	local targetNum = checkint(data.targetNum)
	local progress =  checkint(data.progress)
	local hasDrawn = checkint(data.hasDrawn) --  0:未领取 1:已领取 |
	self.viewData.rewardImage:setVisible(false)
	self.viewData.completeImage:setVisible(false)
	self.viewData.hasDrawnImage:setVisible(false)
	self.viewData.chestImage:setPosition(54, 44)
	self.viewData.chestImage:setScale(0.5)
	self.viewData.chestImage:stopAllActions()
	local readySpine = self:getChildByName("readySpine")
	if readySpine then
		readySpine:setVisible(false)
	end
	self.viewData.cellBgImage:setTexture(RES_DICT.CVSHARE_TASK_BG)
	if hasDrawn == 1 then
		self.viewData.rewardImage:setVisible(false)
		self.viewData.hasDrawnImage:setVisible(true)
		self.viewData.completeImage:setVisible(true)
	else
		if progress >=  targetNum then
			if not  readySpine then
				readySpine = self:CreateReadySpine()
			end
			readySpine:setVisible(true)
			-- 可以领取
			self.viewData.cellBgImage:setTexture(RES_DICT.CVSHARE_TASK_BG_COMPLETE)
			self.viewData.rewardImage:setVisible(true)
			self.viewData.rewardImage:runAction(
				cc.RepeatForever:create(
					cc.Spawn:create(
						cc.RotateBy:create(1 ,15)  ,
						cc.Sequence:create(
							cc.FadeTo:create(0.5 , 125) ,
							cc.FadeTo:create(0.5 , 255)
						)
					)
				)
			)
			local num = 0.5
			self.viewData.chestImage:runAction(cc.RepeatForever:create(cc.Sequence:create({
				cc.DelayTime:create(0.8),
				cc.ScaleTo:create(0.1, 1.1*num, 0.8 * num ),
				cc.ScaleTo:create(0.1, 1*num),
				cc.JumpBy:create(0.4, cc.p(0,0), 20, 1),
				cc.ScaleTo:create(0.1, 1.1*num, 0.8*num),
				cc.ScaleTo:create(0.1, 1*num)
			})))
		end
	end
	display.commonLabelParams(self.viewData.taskPrograssLabel , { text = table.concat( {progress, targetNum  } , '/') })
	display.commonLabelParams(self.viewData.taskDescrLabel , { w = 220 ,hAlign = display.TAL ,fontSize = 20 ,   text = __('累计每日活跃度满100') })
end
function ShareCVCell:CreateReadySpine()
	local spineTable =  _spn('ui/home/activity/cv2/effect/pintu_biankuang')
	local readySpine = sp.SkeletonAnimation:create(spineTable.json, spineTable.atlas, 1)
	readySpine:update(0)
	readySpine:setScale(0.85)
	readySpine:setAnimation(0, 'idle', true)
	self:addChild(readySpine,10)
	readySpine:setPosition(177.5 , 45)
	readySpine:setName("readySpine")
	readySpine:setScale(1)
	return readySpine
end
---UpdateCVCell 更新CV的分享
function ShareCVCell:UpdateCVCell(data)
	local targetNum = checkint(data.targetNum)
	local progress =  checkint(data.progress)
	local name =  data.name or ""
	local hasDrawn = checkint(data.hasDrawn) --  0:未领取 1:已领取 |
	self.viewData.rewardImage:setVisible(false)
	self.viewData.completeImage:setVisible(false)
	self.viewData.hasDrawnImage:setVisible(false)
	self.viewData.chestImage:setPosition(54, 44)
	self.viewData.chestImage:setScale(0.5)
	self.viewData.chestImage:stopAllActions()
	local readySpine = self:getChildByName("readySpine")
	if readySpine then
		readySpine:setVisible(false)
	end
	self.viewData.cellBgImage:setTexture(RES_DICT.CVSHARE_TASK_BG)
	if hasDrawn == 1 then
		self.viewData.rewardImage:setVisible(false)
		self.viewData.hasDrawnImage:setVisible(true)
		self.viewData.completeImage:setVisible(true)
	else
		if progress >= targetNum then
			if not readySpine then
				readySpine = self:CreateReadySpine()
			end
			readySpine:setVisible(true)
			-- 可以领取
			self.viewData.cellBgImage:setTexture(RES_DICT.CVSHARE_TASK_BG_COMPLETE)
			self.viewData.rewardImage:setVisible(true)
			self.viewData.rewardImage:runAction(
				cc.RepeatForever:create(
					cc.Spawn:create(
						cc.RotateBy:create(1 ,15)  ,
						cc.Sequence:create(
							cc.FadeTo:create(0.5 , 125) ,
							cc.FadeTo:create(0.5 , 255)
						)
					)
				)
			)
			local num = 0.5
			self.viewData.chestImage:runAction(cc.RepeatForever:create(cc.Sequence:create({
				cc.DelayTime:create(0.8),
				cc.ScaleTo:create(0.1, 1.1*num, 0.8 * num ),
				cc.ScaleTo:create(0.1, 1*num),
				cc.JumpBy:create(0.4, cc.p(0,0), 20, 1),
				cc.ScaleTo:create(0.1, 1.1*num, 0.8*num),
				cc.ScaleTo:create(0.1, 1*num)
			})))
		end
	end
	display.commonLabelParams(self.viewData.taskPrograssLabel , { text = table.concat( {progress, targetNum  } , '/') })
	display.commonLabelParams(self.viewData.taskDescrLabel , { w = 240 , fontSize = 22,  text = string.fmt(__('累计分享_name_') , { _name_ = name })    })
end


return ShareCVCell