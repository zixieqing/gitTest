local Command = require( 'Frame.Opera.Command' )

local Director = require( "Frame.Opera.Director" )

local DialogueCommand = Command:New()

DialogueCommand.NAME = "DialogueCommand"

-- local WW = (display.width - 40) / 4
local WW = (display.width - 760) / 4
local HH = (display.height - 80) / 3

local OFFSETY = 160

local DIALOG_POS = {
	["0"] = { anchor = cc.p(0.5, 0.0), pos = cc.p(display.cx, 80)},
	L1    = { anchor = cc.p(0.5, 1.0), pos = cc.p(display.cx - WW * 0.5, display.cy + 1.5 * HH - OFFSETY)},
	L2    = { anchor = cc.p(0.5, 0.5), pos = cc.p(display.cx - WW * 0.5, display.cy - OFFSETY)},
	L3    = { anchor = cc.p(0.5, 0.0), pos = cc.p(display.cx - WW * 0.5, display.cy - HH * 1.5 - OFFSETY)},
	L4    = { anchor = cc.p(0.0, 1.0), pos = cc.p(display.cx - WW * 2.0, display.cy + 1.5 * HH - OFFSETY)},
	L5    = { anchor = cc.p(0.0, 0.5), pos = cc.p(display.cx - WW * 2.0, display.cy - OFFSETY)},
	L6    = { anchor = cc.p(0.0, 0.0), pos = cc.p(display.cx - WW * 2.0, display.cy - 1.5 * HH - OFFSETY)},
	R1    = { anchor = cc.p(0.5, 1.0), pos = cc.p(display.cx + WW * 0.5, display.cy + 1.5 * HH - OFFSETY)},
	R2    = { anchor = cc.p(0.5, 0.5), pos = cc.p(display.cx + WW * 0.5, display.cy - OFFSETY)},
	R3    = { anchor = cc.p(0.5, 0.0), pos = cc.p(display.cx + WW * 0.5, display.cy - 1.5 * HH - OFFSETY)},
	R4    = { anchor = cc.p(1.0, 1.0), pos = cc.p(display.cx + WW * 2.0, display.cy + 1.5 * HH - OFFSETY)},
	R5    = { anchor = cc.p(1.0, 0.5), pos = cc.p(display.cx + WW * 2.0, display.cy - OFFSETY)},
	R6    = { anchor = cc.p(1.0, 0.0), pos = cc.p(display.cx + WW * 2.0, display.cy - 1.5 * HH - OFFSETY)},
}

local DIALOG_BG = {
	['1'] = {id = 1, name = 'dialogue_bg_1',     offset = cc.p(44,26),  size = cc.size(748,120)},
	['2'] = {id = 2, name = 'dialogue_bg_2',     offset = cc.p(34,40),  size = cc.size(518,120)},
	['3'] = {id = 3, name = 'dialogue_bg_3',     offset = cc.p(84,90),  size = cc.size(430,136)},
	['4'] = {id = 4, name = 'dialogue_bg_4',     offset = cc.p(46,78),  size = cc.size(350,100)},
	['5'] = {id = 5, name = 'dialogue_bg_5',     offset = cc.p(44,50),  size = cc.size(468,100)},
	['6'] = {id = 6, name = 'dialogue_bg_6',     offset = cc.p(56,40),  size = cc.size(540,142)},
	['7'] = {id = 7, name = 'dialogue_bg_aside', offset = cc.p(187,40), size = cc.size(960,100), fontColor = '#67653F'},
	['8'] = {id = 8, name = 'dialogue_bg_role',  offset = cc.p(45,60),  size = cc.size(978,100), fontColor = '#67653F'},
	['9'] = {id = 9, name = 'dialogue_bg_role',  offset = cc.p(185,60), size = cc.size(838,100), fontColor = '#67653F'},
}

if isElexSdk() then
	DIALOG_BG = {
		['1'] = { id = 1, name = 'dialogue_bg_1', offset = cc.p(43, 21), size = cc.size(766, 138) },
		['2'] = { id = 2, name = 'dialogue_bg_2', offset = cc.p(87, 36), size = cc.size(650, 144) },
		['3'] = { id = 3, name = 'dialogue_bg_3', offset = cc.p(119, 61), size = cc.size(588,174) },
		['4'] = { id = 4, name = 'dialogue_bg_4', offset = cc.p(69, 74), size = cc.size(530, 140) },
		['5'] = { id = 5, name = 'dialogue_bg_5', offset = cc.p(71, 66), size = cc.size(660,142 ) },
		['6'] = { id = 6, name = 'dialogue_bg_6', offset = cc.p(68, 45), size = cc.size(662, 140) },
		['7'] = {id = 7, name = 'dialogue_bg_aside', offset = cc.p(187,40), size = cc.size(960,100), fontColor = '#67653F'},
		['8'] = {id = 8, name = 'dialogue_bg_role',  offset = cc.p(45,60),  size = cc.size(978,100), fontColor = '#67653F'},
		['9'] = {id = 9, name = 'dialogue_bg_role',  offset = cc.p(185,60), size = cc.size(838,100), fontColor = '#67653F'},
	}
end
local TYPING_ENDED_ARROW = {
	['7'] = {id = 7, pos = cc.p(1334-250, 45)},
	['8'] = {id = 8, pos = cc.p(1060-70, 40)},
	['9'] = {id = 9, pos = cc.p(1060-70, 40)},
}
	
local ROLE_INFO_DEFINE = {
	['8'] = {id = 8, showName = true, namePos = cc.p(45,140), showHead = false},
	['9'] = {id = 9, showName = true, namePos = cc.p(185,140), showHead = true, headPos = cc.p(92,88), headScale = 0.8},
}

--[[
* ?????????????????????????????????????????? ???????????? ???????????????
* ?????????????????????
--]]
function DialogueCommand:New(id,bubbleId,roleId,voiceId)
	local this = {}
	setmetatable( this, {__index = DialogueCommand} )
	this.renationNode = nil
	this.id           = id -- ??????????????????id??????
	this.isTyping     = false --?????????????????????????????????
	this.isDisable    = false --?????????????????????????????????????????????
	this.viewData     = nil
	this.roleId       = roleId
	this.voiceId      = voiceId
	if string.len(checkstr(id)) > 0 and not DIALOG_POS[tostring(id)] then
		funLog(Logger.ERROR, string.format( "the %s is not validate id", tostring(id) ))
	end
	this.bubbleId = bubbleId --bubbleid ??????
	return this
end

--[[
--???????????????????????????
--]]
function DialogueCommand:ShowFullStory( )
	if not self.isDisable then
		self.isDisable = true --??????
		if self.isTyping then
			self:SetTypeAction(false)
			--?????????????????????????????????
			if self.delay > 0 then
				self.viewData.view:runAction(cc.Sequence:create(cc.DelayTime:create(self.delay), cc.CallFunc:create(function()
					self.isDisable = false
					--??????delay??????????????????????????????????????????
				end)))
			end
		else
			--??????????????????????????????
			self.isDisable = true
			--????????????????????????
			self:Dispatch("DirectorStory","next")
		end
	end
end


function DialogueCommand:SetTypeAction( isTyping )
	self.isTyping = isTyping --??????????????????typing
	if self.viewData.typingEndedImg then
		self.viewData.typingEndedImg:setVisible(not self.isTyping)
	end
	if self.isTyping == false then
		--???????????????????????????
		--??????????????????
		self.viewData.contentLabel:stopAllActions()
        self.viewData.contentLabel:setVisible(true)
		self.viewData.contentLabel:setScale(self.viewData.contentLabel.originalScale or 1)
		display.commonLabelParams(self.viewData.contentLabel, {text = self.content })
		local labelSize = display.getLabelContentSize(self.viewData.contentLabel)
		if labelSize.height <= self.viewData.contentLabel.maxHeight then
		else
			local fontSize = math.floor(math.sqrt(24 * 24 * (self.viewData.contentLabel.maxHeight/labelSize.height)))
			fontSize = fontSize >24 and 24 or fontSize
			display.commonLabelParams(self.viewData.contentLabel , {fontSize = fontSize ,  reqH = self.viewData.contentLabel.maxHeight , text =self.content  })
		end

	else
		--????????????????????????
		if self.viewData.contentLabel then
			self.viewData.contentLabel:setScale(self.viewData.contentLabel.originalScale or 1)
			display.commonLabelParams(self.viewData.contentLabel, {text = self.content })
			local labelSize = display.getLabelContentSize(self.viewData.contentLabel)
			if labelSize.height <= self.viewData.contentLabel.maxHeight then

			else
				local fontSize = math.floor(math.sqrt(24 * 24 * (self.viewData.contentLabel.maxHeight/labelSize.height)))
				fontSize = fontSize >24 and 24 or fontSize
				display.commonLabelParams(self.viewData.contentLabel , {fontSize = fontSize ,  reqH = self.viewData.contentLabel.maxHeight , text =self.content  })
			end
			self.viewData.contentLabel:setVisible(false)
			local duration = string.utf8len(self.content) * 0.06
			if self.shake == true then
				local shareSceneManager = cc.CSceneManager:getInstance()
				local scene = shareSceneManager:getRunningScene()
				if self.hasShakeLine then
					local director = Director.GetInstance()
					local stage = director:GetStage()
					local shakeImage = display.newSprite(_res("arts/stage/ui/stage_shake_line.png"))
					display.commonUIParams(shakeImage, {po = display.center})
					shakeImage:setTag(Director.ZorderTAG.Z_BG_COLOR_LAYER + 2)
					stage:addChild(shakeImage, Director.ZorderTAG.Z_BG_COLOR_LAYER + 2)
				end
				scene:runAction(ShakeAction:create(duration, 5, 2))
			end
	        local writer = TypewriterAction:create(duration)
	        self.viewData.contentLabel:runAction(cc.Sequence:create(writer,cc.CallFunc:create(function ( )
		        --?????????????????????????????????
				if self.delay > 0 then
					self.viewData.view:runAction(cc.Sequence:create(cc.DelayTime:create(self.delay), cc.CallFunc:create(function()
						--??????delay??????????????????????????????????????????
						self.isTyping  = false
						self.isDisable = false

						if self.viewData.typingEndedImg then
							self.viewData.typingEndedImg:setVisible(true)
						end
					end)))
				end
	        end)))
	    end
	end
end

--[[
??????????????????????????????
@param name  ?????????????????????
@param content ?????????????????????
@param goodsId
@param delay ??????????????????
@param audioPath ???????????????
--]]
function DialogueCommand:CommandDialogue(name, content, goodsId, delay, audioPath)
	self.name = name
	self.content = content --?????????????????????????????????????????????
    self.goodsId = goodsId
	self.delay = (delay or 0.1)
	self.audioPath = audioPath
end

function DialogueCommand:IsCG()
    self.isCG = true
end

function DialogueCommand:StoryMusic(musicPath)
    self.musicPath = musicPath
end

function DialogueCommand:AudioEffects(params)
    self.audioPath = params.audioPath
end
--[[
?????????????????????contentsize
@param size ???????????????
--]]
function DialogueCommand:SetMsgSize( size )
	self.msgSize = size
end
--[[
??????????????????????????????
@param color ?????????
--]]
function DialogueCommand:SetMsgColor( color )
	self.msgColor = color
end
--[[
???????????????????????????
@param x x??????
@param y y??????
--]]
function DialogueCommand:SetMsgPostion( x, y )
	self.msgPos = cc.p(x, y)
end
--[[
?????????????????????anchor
@param x x??????
@param y y??????
--]]
function DialogueCommand:SetMsgAnchor( x,y )
	self.msgAnchor = cc.p(x, y)
end
--[[
?????????????????????????????????
@param align ??????left,center,right
--]]
function DialogueCommand:SetMsgAlign( align )
	self.msgAlign = align
end

--[[
?????????????????????????????????
@param fontName fontName
--]]
function DialogueCommand:SetFontName( fontName )
	self.fontName = fontName
end

--[[
????????????????????????????????????
@param fontName fontName
--]]
function DialogueCommand:SetNamePos( x,y )
	self.namePos = cc.p(x, y)
end

function DialogueCommand:ShakeSameTime(hasShakeLine)
   self.shake = true
   self.hasShakeLine = (hasShakeLine or false)
end

--[[
??????????????????????????????????????????
@param color ??????
@param fontSize ????????????
@param anchor ????????????
--]]
function DialogueCommand:SetNameParams( color, fontSize, anchor )
	if not color then color = cc.c3b(0, 0, 0) end
	if not fontSize then fontSize = 26 end
	if not anchor then anchor = cc.p(0.5, 0.5) end
	self.color = color
	self.fontSize = fontSize
	self.anchor = anchor
end

--[[
* ???????????????????????????
* @return ????????????????????????????????????
--]]
function DialogueCommand:CanMoveNext( )
	return false
end

--[[
--????????????????????????
--]]
function DialogueCommand:Execute( )
	--????????????????????????
	local director = Director.GetInstance( "Director" )
	local stage = director:GetStage()
	if stage then
		--?????????????????????
        --???????????????????????????
        if self.roleId == 'role_0' then
            director:ClearRoles() -- ?????????????????????????????????????????????
        end
        if self.roleId == 'role_0000' then
            director:OpacityRoles()
        end
        local messageLayer = stage:getChildByTag(Director.ZorderTAG.Z_BG_COLOR_LAYER + 2)
        if messageLayer then
            messageLayer:removeFromParent()
            -- stage:removeChildByTag(Director.ZorderTAG.Z_MESSAGE_LAYER)
		end
		if stage:getChildByTag(Director.ZorderTAG.Z_MESSAGE_LAYER) then
			stage:removeChildByTag(Director.ZorderTAG.Z_MESSAGE_LAYER)
		end
		local shakeImage = stage:getChildByTag(Director.ZorderTAG.Z_BG_COLOR_LAYER + 2)
		if shakeImage then
			shakeImage:removeFromParent()
		end
        local posInfo = DIALOG_POS[tostring(self.id)]
        if posInfo == nil then posInfo = DIALOG_POS['0'] end

		local CreateMsgView = function (  )
			local bgInfo = DIALOG_BG[tostring(self.bubbleId)] or {}
			local view = CLayout:create()
            -- view:setBackgroundColor(ccc3FromInt('787878'))
			local imagePath = nil
			if posInfo.pos.x == display.cx then
				imagePath = _res(string.format("arts/stage/ui/%s.png", tostring(bgInfo.name)))
			elseif posInfo.pos.x < display.cx then
				imagePath = _res(string.format("arts/stage/ui/%s.png", tostring(bgInfo.name)))
			else
				imagePath = _res(string.format("arts/stage/ui/%s.png", tostring(bgInfo.name)))
			end
			-- print(imagePath)
			local bubbleImage = display.newImageView(imagePath)
			local size = bubbleImage:getContentSize()
			view:setContentSize(size)
			bubbleImage:setPosition(utils.getLocalCenter(view))
			view:addChild(bubbleImage,2)

			-- role info
			local roleInfoDefine = ROLE_INFO_DEFINE[tostring(self.bubbleId)]
			local isShowRoleName = roleInfoDefine and roleInfoDefine.showName or false
			if roleInfoDefine then
				if roleInfoDefine.showName then
					local roleNameText  = Director.GetRoleName(self.roleId)
					local roleNamePoint = roleInfoDefine.namePos or PointZero
					local roleNameFonParams = isEfunSdk() and 
						{fontSize = 28, color = '#724c42', text = roleNameText, hAlign = display.TAL, ap = display.LEFT_CENTER}
						or fontWithColor(1, {color = '#724c42', text = roleNameText, hAlign = display.TAL, ap = display.LEFT_CENTER})
					local roleNameLabel = display.newLabel(roleNamePoint.x, roleNamePoint.y, roleNameFonParams)
					bubbleImage:addChild(roleNameLabel,4)
				end
				if roleInfoDefine.showHead then
					local roleHeadNode, isCard  = Director.GetRoleHead(self.roleId)
					local roleHeadPoint = roleInfoDefine.headPos or PointZero
					roleHeadNode:setScale(roleInfoDefine.headScale or 1)
					roleHeadNode:setPosition(roleHeadPoint)
					roleHeadNode:setAnchorPoint(display.CENTER)
					bubbleImage:addChild(roleHeadNode,4)

					local roleHeadMask = display.newImageView(_res('arts/stage/ui/dia_frame_ico_mask_role.png'), roleHeadPoint.x, roleHeadPoint.y)
					bubbleImage:addChild(roleHeadMask,4)
				end
			end

			-- ????????????????????????
            local roleName = tostring(app.gameMgr:GetUserInfo().playerName)
            if roleName == nil or (type(roleName) == 'string' and string.len(roleName) == 0) then
                roleName = '???'
            end
            if string.find(tostring(self.content), '_name_') then
                self.content = string.fmt(self.content, {_name_ = tostring(app.gameMgr:GetUserInfo().playerName)})
            end

			if not isShowRoleName then
				if self.roleId == 'role_0000' then
					local nameBg = display.newImageView(_res('arts/stage/ui/story_bg_name.png'), bubbleImage:getContentSize().width * 0.5, - 30)
					local nameLabel = display.newLabel(0, 0,{fontSize = 26,color = '6c6c6c',text = roleName})
					nameLabel:setPosition(utils.getLocalCenter(nameBg))
					nameBg:addChild(nameLabel)
					bubbleImage:addChild(nameBg,2)
					
				elseif self.isCG and self.roleId ~= 'role_0' then
					local cardId = self.roleId
					local roleName = Director.GetRoleName(self.roleId)
					local nameBg = display.newImageView(_res('arts/stage/ui/story_bg_name.png'), bubbleImage:getContentSize().width * 0.5, - 30)
					local nameLabel = display.newLabel(0, 0,{fontSize = 26,color = '6c6c6c',text = roleName})
					nameLabel:setPosition(utils.getLocalCenter(nameBg))
					nameBg:addChild(nameLabel)
					bubbleImage:addChild(nameBg,2)
				end
			end
			
			-- check goodsId
			if self.goodsId and type(self.goodsId) == 'string' and string.len(self.goodsId) > 0 then
				local goodsNode = require('Frame.Opera.PlotGoodsNode').new({id = self.goodsId})
				goodsNode:setPosition(size.width * 0.5 + 5, display.cy)
				view:addChild(goodsNode, 10)
            end

			local bgOffset, bgSize = bgInfo.offset or {}, bgInfo.size or {}
			local contentColor = bgInfo.fontColor or '#6c6c6c'
			local contentLabel = display.newLabel(checkint(bgOffset.x), size.height - checkint(bgOffset.y), {fontSize = 24, color = contentColor, text = '',
				w = checkint(bgSize.width)})
			contentLabel.maxHeight = bgSize.height
			display.commonUIParams(contentLabel, {ap = cc.p(0, 1.0)})
			bubbleImage:addChild(contentLabel,3)
			contentLabel:setAlignment(cc.TEXT_ALIGNMENT_LEFT)

			-- typingEndedImg
			local typingEndedImg = nil
			local typingEndedDefine = TYPING_ENDED_ARROW[tostring(self.bubbleId)]
			if typingEndedDefine then
				typingEndedImg = display.newImageView(_res('arts/stage/ui/dialogue_btn_next.png'))
				typingEndedImg:setPosition(typingEndedDefine.pos or PointZero)
				typingEndedImg:runAction(cc.RepeatForever:create(cc.Sequence:create(
					cc.FadeOut:create(0.8),
					cc.FadeIn:create(0.8),
					cc.DelayTime:create(0.2)
				)))
				bubbleImage:addChild(typingEndedImg,4)
				typingEndedImg:setVisible(false)
			end

			return {
				view = view,
				-- nameLabel = nameLabel,
				contentLabel = contentLabel,
				typingEndedImg = typingEndedImg,
			}
		end
		--??????????????????
		self.viewData = CreateMsgView()
		display.commonUIParams(self.viewData.view, {ap = posInfo.anchor, po = posInfo.pos})
		-- local dialogLayer = require( "Frame.Opera.Dialogue" ).new({command = self})
		-- display.commonUIParams(dialogLayer, {po = display.center})
		stage:addChild(self.viewData.view, Director.ZorderTAG.Z_MESSAGE_LAYER,Director.ZorderTAG.Z_MESSAGE_LAYER)

		-- [.audioPath]
        if self.audioPath and string.len(self.audioPath) > 0 then
            local audiosConfig = string.split2(self.audioPath, ',')
			for _, val in pairs(audiosConfig or {}) do
				if string.len(val) > 0 then
					PlayAudioClip(val)
                end
            end
		end
		
		-- [.musicPath]
        if self.musicPath and string.len(self.musicPath) > 0 then
			if string.find(self.musicPath, 'stop') then
				app.audioMgr:PauseBGMusic()
			else
				PlayBGMusic(self.musicPath)
			end
		end
		
		self:SetTypeAction(true) --??????????????????

		-- [.voiceId]
		if self.roleId and self.voiceId and self.voiceId ~= '' then
			if string.match(self.roleId, '^%d+') then
				local cardId = self.roleId
				if CommonUtils.GetGoodTypeById(self.roleId) == GoodsType.TYPE_CARD_SKIN then
					local skinConf = CardUtils.GetCardSkinConfig(self.roleId) or {}
					cardId = checkint(skinConf.cardId)
				end
				CommonUtils.PlayCardPlotSoundById(cardId, self.voiceId, 'plot')
			end
		end

	end
end

return DialogueCommand
