local Command = require( 'Frame.Opera.Command' )

local Director = require( "Frame.Opera.Director" )
---@class ChooseArtifactCommand
local ChooseArtifactCommand = Command:New()

ChooseArtifactCommand.NAME = "ChooseArtifactCommand"

local CardConfig = CommonUtils.GetConfigAllMess('card','card')
--[[
* content
--]]
function ChooseArtifactCommand:New(params)
	local this = {}
	setmetatable( this, {__index = ChooseArtifactCommand} )
	this.inAction = true
	this.curIndex = nil
	local storyVoiceConf = CommonUtils.GetConfigAllMess('storyVoice','plot')
	this.cards = {}
	for i, v in pairs(storyVoiceConf) do
		this.cards[checkint(i)] =  v
	end
	return this
end

--[[
* 是否可以进行下一步
* @return 初始是可以进行下一步操作
--]]
function ChooseArtifactCommand:CanMoveNext( )
	return false
end

--[[
--执行方法的虚方法
--]]
function ChooseArtifactCommand:Execute( )
	--执行方法的虚方法
	local director = Director.GetInstance( "Director" )
	local stage = director:GetStage()

	if stage then
		--首先移除消息层
		if stage:getChildByTag(Director.ZorderTAG.Z_WHEN_LAYER) then
			stage:removeChildByTag(Director.ZorderTAG.Z_WHEN_LAYER)
		end
		local CreateMsgView = function (  )
			local selectButtons = {}

			local view = display.newLayer(display.cx , display.cy ,{ ap = display.CENTER, size = display.size } )

			local bgImge = display.newImageView(_res('arts/stage/bg/main_bg_17') , display.cx , display.cy,  {isFull = true})
			view:addChild(bgImge)
			local layer = display.newLayer(display.cx , display.cy , { ap = display.CENTER , color = cc.c4b(0,0,0,180)})
			view:addChild(layer)
			local swallowLayer = display.newButton(display.cx , display.cy ,{ap = display.CENTER,  size = display.size, enable = true , cb = function()
				-- self:ExecuteAfter()
			end })
			view:addChild(swallowLayer)


			for i = 1, 4 do
				local layer = display.newButton(display.cx  - 610, display.cy + (3-i)* 187.5-20, { size = cc.size(150,150), ap = display.LEFT_TOP  , color = cc.r4b()} )
				view:addChild(layer,100)
				layer:setTag(i)
				display.commonUIParams(layer ,{ cb = handler(self, self.ArtifactCallBack)} )
				selectButtons[#selectButtons+1] = layer
			end

			local cardName = display.newLabel(display.cx  + 610, display.cy + 2* 187.5-70, fontWithColor(14, {ap = display.RIGHT_TOP ,fontSize = 48,  text = ""}))
			view:addChild(cardName,2)

			local makeSureBtn = display.newButton( display.cx  + 610, display.cy -187.5-140 , { n = _res('ui/common/common_btn_orange.png'), ap =display.RIGHT_BOTTOM})
			view:addChild(makeSureBtn,2)
			display.commonUIParams(makeSureBtn , {cb = handler(self, self.ArtifactOperaCallback)})
			makeSureBtn:setVisible(false)
			local cubeLabel = display.newLabel(display.cx , display.cy ,fontWithColor(14, {fontSize = 40, outline = false  ,ap = display.CENTER,outline = false,  color = "#ffffff"  , text = __('谁是你未尽的心愿？')}))
			view:addChild(cubeLabel,1001)
			cubeLabel:setOpacity(0)
			display.commonLabelParams(makeSureBtn , fontWithColor(14 , {text = __('开启剧情'), color = "#5b3c25" , outline = false }))
			local chooseArtifactSpine = sp.SkeletonAnimation:create("arts/stage/spine/chooseArtifact/skeleton.json","arts/stage/spine/chooseArtifact/skeleton.atlas",1)
			chooseArtifactSpine:setToSetupPose()
			chooseArtifactSpine:update(0)
			chooseArtifactSpine:setAnimation(0, 'play', false)
			chooseArtifactSpine:setPosition(display.center)
			chooseArtifactSpine:setAnchorPoint(display.CENTER)
			chooseArtifactSpine:registerSpineEventHandler(function()
				chooseArtifactSpine:setAnimation(0,'idle',true)
				if self.inAction then
					cubeLabel:setOpacity(100)
					cubeLabel:runAction(
						cc.Repeat:create(
							cc.Sequence:create(
									cc.FadeTo:create(1.5,255),
									cc.FadeTo:create(1.5,100)
							),1000
						)
					)
				end
				self.inAction = false
			end, sp.EventType.ANIMATION_COMPLETE)
			view:addChild(chooseArtifactSpine,1000)
			return   {
				view = view ,
				cubeLabel = cubeLabel,
				chooseArtifactSpine = chooseArtifactSpine ,
				cardName = cardName ,
				makeSureBtn = makeSureBtn ,
				cardOne = nil,
				cardTwo = nil 
			}
		end
		--再添加消息层
		self.viewData = CreateMsgView()
		display.commonUIParams(self.viewData.view, {po = display.center})
		stage:addChild(self.viewData.view, Director.ZorderTAG.Z_WHEN_LAYER,Director.ZorderTAG.Z_WHEN_LAYER)
	end
end
function ChooseArtifactCommand:ArtifactCallBack(sender)
	local tag = sender:getTag()
	if self.inAction then
		return
	end
	self.viewData.cubeLabel:setVisible(false)
	self.curIndex = tag
	local viewData = self.viewData
	self.inAction = true
	local cardId =  self.cards[tag].cardId
	local getNode = function()
		local node = AssetsUtils.GetCardDrawNode(cardId)
		node:setPosition(display.center)
		node:setAnchorPoint(display.CENTER)
		viewData.view:addChild(node)
		node:setOpacity(0)
		node:setScale(0.2)
		local showAction = self:GetShowAction()
		node:runAction(
				showAction
		)
		return node
	end
	if not  self.viewData.cardOne then
		self.viewData.cardOne = getNode()
	elseif not self.viewData.cardTwo then
		self.viewData.cardTwo = getNode()
		self.viewData.cardOne:runAction(self:GetHideAction())
	else
		local oneNode = nil
		local twoNode = nil
		if self.viewData.cardOne:isVisible() then
			oneNode = self.viewData.cardOne
			twoNode = self.viewData.cardTwo
		else
			twoNode = self.viewData.cardOne
			oneNode = self.viewData.cardTwo
		end
		twoNode:setTexture(AssetsUtils.GetCardDrawPath(cardId))
		twoNode:setScale(0.2)
		oneNode:runAction(self:GetHideAction())
		twoNode:runAction(self:GetShowAction())
	end
	CommonUtils.PlayCardPlotSoundById( self.cards[tag].cardId ,self.cards[tag].voice ,'plot')
	viewData.makeSureBtn:setVisible(true)
	viewData.chooseArtifactSpine:setToSetupPose()
	viewData.chooseArtifactSpine:setAnimation(0, 'idle' .. tag, true)
	display.commonLabelParams(viewData.cardName, {text = CardConfig[tostring(cardId)].name })
end


-- 展示剧情的回调事件
function ChooseArtifactCommand:ArtifactOperaCallback()
	local director = Director.GetInstance( "Director" )
	local stage = director:GetStage()
	if stage and self.cards[self.curIndex] then
		
		local storyId   = self.cards[self.curIndex].storyId
		local storyPath = string.format('conf/%s/plot/story0.json', i18n.getLang())
		stage:LoadStory(storyPath, storyId)

		stage:LoadStory(storyPath, 6)
		stage:LoadStory(storyPath, 7)
		self:ExecuteAfter()
		
	end
end


function ChooseArtifactCommand:GetShowAction()
	local showAction =  cc.Sequence:create(
		cc.Show:create(),
			cc.EaseSineOut:create(
				cc.Spawn:create(
					cc.ScaleTo:create(1.2,0.6),
					cc.FadeIn:create(1.2)
				)
			),
		cc.CallFunc:create(
			function()
				self.inAction = false
			end
		)
	)
	return showAction
end
function ChooseArtifactCommand:GetHideAction()
	local hideAction = cc.Sequence:create(
			cc.FadeOut:create(0.1),
			cc.Hide:create()
	)
	return hideAction
end
function ChooseArtifactCommand:ExecuteAfter( )
	--移除自身
	local director = Director.GetInstance( "Director" )
	local stage = director:GetStage()
	if stage then
		local node = stage:getChildByTag(Director.ZorderTAG.Z_WHEN_LAYER)
		if node then
			node:runAction(cc.Sequence:create(cc.FadeIn:create(0.1),cc.CallFunc:create(function()
				director:MoveNext()
			end),cc.RemoveSelf:create()))
		end
	end
end
return ChooseArtifactCommand 
