--[[
飨灵回忆界面
--]]
local CardMemoryView = class('CardMemoryView', function ()
	local node = CLayout:create()
	node.name = 'Game.views.CardMemoryView'
	node:enableNodeEvents()
	return node
end)

local utf8 = require("root.utf8")
function CardMemoryView:ctor( ... )
	local args = unpack({...}) or {}
	self:setContentSize(display.size)
	self.args = args
	self.viewData = nil
	self.cueSheet = nil
	self.words = {}
	self.labelSprites = {}
    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 150))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setAnchorPoint(cc.p(0.5, 1.0))
    eaterLayer:setPosition(cc.p(display.cx, display.height))-- - NAV_BAR_HEIGHT
    self:addChild(eaterLayer, -1)
    self.eaterLayer = eaterLayer

	local function CreateView()
		local view = CLayout:create(display.size)
        display.commonUIParams(view, {po = display.center})
        self:addChild(view)

        local bg = display.newImageView(_res('ui/cards/marry/card_contract_bg_memory'), display.cx, display.cy, {isFull = true})
        view:addChild(bg)

		-- back button
		local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back")})
    	backBtn:setPosition(cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.height - 53))
		view:addChild(backBtn, 5)
		backBtn:setVisible(false)

        local headset = display.newImageView(_res('ui/cards/marry/card_contract_ico_headphone'), display.SAFE_L + 30, display.height - 30)
        view:addChild(headset, 10)

		local playerTipsLabel = display.newLabel(display.SAFE_L + 60, display.height - 34, 
			{fontSize = 24, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, text = __('建议戴上耳机欣赏'),ap = cc.p(0, 0.5)})
		view:addChild(playerTipsLabel, 10)

		local startSpine = sp.SkeletonAnimation:create(
			'effects/marry/pre.json',
			'effects/marry/pre.atlas',
			1)
		startSpine:setAnimation(0, 'star', false)
		startSpine:update(0)
		startSpine:setToSetupPose()
		-- startSpine:setTimeScale(2.0 / 3.0)
		startSpine:setPosition(cc.p(display.cx, display.cy))
		view:addChild(startSpine, 5)

		local dialogSpine = sp.SkeletonAnimation:create(
			'effects/marry/pre.json',
			'effects/marry/pre.atlas',
			1)
		-- dialogSpine:setTimeScale(2.0 / 3.0)
		dialogSpine:setPosition(cc.p(display.cx, display.cy))
		view:addChild(dialogSpine, 7)
			
		local stageTablet = display.newImageView(_res('ui/cards/marry/card_contract_label_moviesubtitle'), 0, 0, {ap = cc.p(0,0)})
		view:addChild(stageTablet)
		stageTablet:setOpacity(0)

		local stageLabel = display.newLabel(display.SAFE_L + 20, 26, 
			{fontSize = 36, color = '#e3bf7d', font = TTF_GAME_FONT, ttf = true, text = '',ap = cc.p(0, 0.5)})
		view:addChild(stageLabel)
		stageLabel:setOpacity(0)

		local chairWordsBG = display.newImageView(_res('ui/cards/marry/card_contract_label_guidetext'), display.cx, display.cy)
		view:addChild(chairWordsBG, 8)
		chairWordsBG:setVisible(false)

		local dialogueSize = cc.size(628, 207)
		local dialogueLayer = display.newLayer(display.cx, display.cy, {size = dialogueSize})
		view:addChild(dialogueLayer, 6)
		local dialogueBG = display.newImageView(_res('ui/cards/marry/card_contract_dialogue_bg'), dialogueSize.width / 2, dialogueSize.height, {ap = cc.p(0.5, 1)})
		dialogueLayer:addChild(dialogueBG)
		dialogueBG:setOpacity(0)

		local dialogLabel = display.newLabel(98, 142, 
			{fontSize = 26, color = '#5d2626', text = '',ap = cc.p(0, 1), w = 450})
		dialogueLayer:addChild(dialogLabel)
		dialogLabel:setOpacity(0)

		-- local endBtn = display.newButton(display.width - 100, 100 , {
        --     n = _res('ui/common/common_btn_orange'),ap = cc.p(0.5,0.5)
		-- })
		-- display.commonLabelParams(endBtn, fontWithColor(14, {text = __('结束'), offset = cc.p(0, 0)}))
		-- view:addChild(endBtn)
		
		return {
			view 				= view,
			bg 					= bg,
			headset				= headset,
			playerTipsLabel		= playerTipsLabel,
			backBtn				= backBtn,
			-- endBtn				= endBtn,
			startSpine			= startSpine,
			dialogSpine			= dialogSpine,
			stageTablet			= stageTablet,
			stageLabel			= stageLabel,
			chairWordsBG		= chairWordsBG,	
			dialogueLayer		= dialogueLayer,
			dialogueBG			= dialogueBG,
			dialogLabel			= dialogLabel,
		}

	end

	xTry(function ( )
		self.viewData = CreateView( )
	end, __G__TRACKBACK__)

end

function CardMemoryView:PreLoadLabel(words, isTTF)
	local sizes = {}
	local sprites = {}
	local widths = {}

	local startY = 100
	local texture = cc.RenderTexture:create(display.width, display.height)
	texture:begin()
	for k, v in pairs(words) do
		local width = 0
		local message = string.restorehtmlspecialchars(v)
		-- local len = string.utf8len(message)
		local len = utf8.len(message)
    	local txt = {}
		for i= 1, len do
			table.insert( txt, utf8.sub(message, i, i))
			-- table.insert( txt, utf8sub(message, i, 1))
		end
		if txt[#txt] == '' then
			table.remove(txt)
		end
		local perSizes = {}
		for _, word in ipairs(txt) do
			if word == '\n' then
				if not widths[k] then
					widths[k] = {}
				end
				table.insert(widths[k], width)
				width = 0
				startY = startY + 50
				if not sizes[k] then
					sizes[k] = {}
				end
				table.insert(sizes[k], perSizes)
				perSizes = {}
			else
				local dialogueLabel = nil
				-- if isTTF then
					dialogueLabel = display.newLabel(width, startY,
					{fontSize = 38, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, text = word,ap = cc.p(0, 0)})
				-- else
				-- 	dialogueLabel = display.newLabel(width, startY,
				-- 	{fontSize = 38, color = '#ffffff', text = word,ap = cc.p(0, 0)})
				-- end
				table.insert(perSizes, display.getLabelContentSize(dialogueLabel))
				dialogueLabel:visit()

				width = width + display.getLabelContentSize(dialogueLabel).width
			end
		end
		if not widths[k] then
			widths[k] = width
		else
			table.insert(widths[k], width)
		end
		if not sizes[k] then
			sizes[k] = perSizes
		else
			table.insert(sizes[k], perSizes)
		end
		startY = startY + 50
	end
	texture:endToLua()
	-- dump(sizes)
	local tt = texture:getSprite():getTexture()
	tt:setAntiAliasTexParameters()
	startY = 100
	local initBlurValue = 4
	for k, v in pairs(sizes) do
		local perSprites = {}
		local startX = 0
		local startPosX
		if type(widths[k]) ~= 'table' then
			startPosX = display.cx - widths[k] / 2 - 100
		end
		for lines, perWordSize in ipairs(v) do
			if type(widths[k]) == 'table' then
				startPosX = display.cx - widths[k][lines] / 2 - 100
				startX = 0
				for _,pword in ipairs(perWordSize) do
					local tempSp = cc.Sprite:createWithTexture(tt, cc.rect(startX, startY, pword.width, pword.height))
					tempSp:setFlippedY(true)
					tempSp:setBlendFunc( {src = gl.ONE, dst = gl.ONE_MINUS_SRC_ALPHA} )
					self.viewData.view:addChild(tempSp, 9)
					tempSp:setVisible(false)
					display.commonUIParams(tempSp, {po = cc.p(startPosX, display.cy - 60 + (table.nums(v) / 2) * 21 - (lines-1)*42), ap = cc.p(0, 0.5)})

					self:initBlurFilter(tempSp, initBlurValue)

					startPosX = pword.width + startPosX - 1
					startX = startX + pword.width
					table.insert(perSprites, tempSp)
				end
				if lines ~= table.nums(v) then
					startY = startY + 50
				end
			else
				local tempSp = cc.Sprite:createWithTexture(tt, cc.rect(startX, startY, perWordSize.width, perWordSize.height))
				tempSp:setFlippedY(true)
				tempSp:setBlendFunc( {src = gl.ONE, dst = gl.ONE_MINUS_SRC_ALPHA} )
				self.viewData.view:addChild(tempSp, 9)
				tempSp:setVisible(false)
				display.commonUIParams(tempSp, {po = cc.p(startPosX, display.cy - 60), ap = cc.p(0, 0.5)})

				self:initBlurFilter(tempSp, initBlurValue)

				startPosX = perWordSize.width + startPosX - 1
				startX = startX + perWordSize.width
				table.insert(perSprites, tempSp)
			end
		end

		startY = startY + 50
		sprites[k] = perSprites
	end
	self.labelSprites = sprites
end

function CardMemoryView:ShowStageText(stage)
	local fadeTime = 2
	local stageTablet = self.viewData.stageTablet
	local stageLabel = self.viewData.stageLabel
	stageTablet:setOpacity(0)
	stageLabel:setOpacity(0)
	stageLabel:setString(stage)
	stageTablet:setPositionX(stageTablet:getPositionX() - stageTablet:getContentSize().width)
	-- stageLabel:setPositionX(stageLabel:getPositionX() - stageTablet:getContentSize().width)
	stageTablet:runAction(cc.Spawn:create(
		cc.FadeIn:create(fadeTime),
		cc.MoveBy:create(fadeTime, cc.p(stageTablet:getContentSize().width, 0))
	))
	stageLabel:runAction(cc.Spawn:create(
		cc.FadeIn:create(fadeTime)
		-- cc.MoveBy:create(fadeTime, cc.p(stageTablet:getContentSize().width, 0))
	))
end

function CardMemoryView:HideStageText(fadeTime)
	local stageTablet = self.viewData.stageTablet
	local stageLabel = self.viewData.stageLabel
	stageTablet:runAction(cc.Spawn:create(
		cc.FadeOut:create(fadeTime)
	))
	stageLabel:runAction(cc.Spawn:create(
		cc.FadeOut:create(fadeTime)
	))
end

function CardMemoryView:ShowChairWords(index, duration, delay, pos)
	local initBlurValue = 4
	local rotation = 45
	local count = table.nums(self.labelSprites[index])

	local function DelayShowChairWords()
		local chairWordsBG = self.viewData.chairWordsBG
		chairWordsBG:stopAllActions()
		chairWordsBG:setOpacity(0)
		chairWordsBG:runAction(cc.Sequence:create(
			cc.Show:create(),
			cc.FadeIn:create(1 + count / 30)
		))
		self.words = {}
		local textSprites = self.labelSprites[index]
		for i = 1, #textSprites do
			local dialogueLabel = textSprites[i]
			dialogueLabel:setVisible(true)
			-- local glProgramState = self:initBlurFilter(dialogueLabel, initBlurValue)
			dialogueLabel:setRotation(rotation)
			dialogueLabel:runAction(cc.Sequence:create(
				cc.DelayTime:create((i - 1) / 30),
				cc.Spawn:create(
					cc.EaseOut:create(cc.RotateBy:create(1, -rotation), 5),
					cc.EaseOut:create(cc.MoveBy:create(1, cc.p(120,64)), 5),
					cc.CallFunc:create(function ()
						self:RunBlurAction(dialogueLabel, i, initBlurValue)
					end)
				)
			))

			table.insert(self.words, dialogueLabel)
		end
	end
	self:runAction(cc.Sequence:create(
		cc.DelayTime:create(delay),
		cc.CallFunc:create(function ()
			DelayShowChairWords()
		end)
	))

	self:runAction(cc.Sequence:create(
		cc.DelayTime:create(duration + 1 + count / 30 + delay),
		cc.CallFunc:create(function ()
			self:DelayClearWords()
		end)
	))
	return duration + 1 + count / 30 + 2.0 / 3.0 + count / 30
end

function CardMemoryView:initBlurFilter(tempSp, initBlurValue)
	local vert = [[
		attribute vec4 a_position; 
		attribute vec2 a_texCoord; 
		attribute vec4 a_color; 
		#ifdef GL_ES  
		varying lowp vec4 v_fragmentColor;
		varying mediump vec2 v_texCoord;
		#else                      
		varying vec4 v_fragmentColor; 
		varying vec2 v_texCoord;  
		#endif    
		void main() 
		{
			gl_Position = CC_PMatrix * a_position; 
			v_fragmentColor = a_color;
			v_texCoord = a_texCoord;
		}
	]]

	local frag = [[
		#ifdef GL_ES
		precision mediump float;
		#endif

		varying vec4 v_fragmentColor;
		varying vec2 v_texCoord;

		uniform float fadeAlpha;
		uniform float u_resolution;
		uniform float u_radius;
		uniform vec2 u_direction;

		void main()
		{
			//this will be our RGBA sum
			vec4 sum = vec4(0.0);

			//our original texcoord for this fragment
			vec2 tc = v_texCoord;

			//the amount to blur, i.e. how far off center to sample from 
			//1.0 -> blur by one pixel
			//2.0 -> blur by two pixels, etc.
			float blur = u_radius/u_resolution; 

    		//the u_direction of our blur
    		//(1.0, 0.0) -> x-axis blur
    		//(0.0, 1.0) -> y-axis blur
			float hstep = u_direction.x;
			float vstep = u_direction.y;


    		//apply blurring, using a 9-tap filter with predefined gaussian weights

			sum += texture2D(CC_Texture0, vec2(tc.x - 4.0*blur*hstep, tc.y - 4.0*blur*vstep)) * 0.0162162162;
			sum += texture2D(CC_Texture0, vec2(tc.x - 3.0*blur*hstep, tc.y - 3.0*blur*vstep)) * 0.0540540541;
			sum += texture2D(CC_Texture0, vec2(tc.x - 2.0*blur*hstep, tc.y - 2.0*blur*vstep)) * 0.1216216216;
			sum += texture2D(CC_Texture0, vec2(tc.x - 1.0*blur*hstep, tc.y - 1.0*blur*vstep)) * 0.1945945946;

			sum += texture2D(CC_Texture0, vec2(tc.x, tc.y)) * 0.2270270270;

			sum += texture2D(CC_Texture0, vec2(tc.x + 1.0*blur*hstep, tc.y + 1.0*blur*vstep)) * 0.1945945946;
			sum += texture2D(CC_Texture0, vec2(tc.x + 2.0*blur*hstep, tc.y + 2.0*blur*vstep)) * 0.1216216216;
			sum += texture2D(CC_Texture0, vec2(tc.x + 3.0*blur*hstep, tc.y + 3.0*blur*vstep)) * 0.0540540541;
			sum += texture2D(CC_Texture0, vec2(tc.x + 4.0*blur*hstep, tc.y + 4.0*blur*vstep)) * 0.0162162162;

			//discard alpha for our simple demo, multiply by vertex color and return
			gl_FragColor = v_fragmentColor * sum * fadeAlpha;
		}
	]]
	-- 1.创建glProgram
	local glProgram = cc.GLProgram:createWithByteArrays(vert, frag)
	-- 2.获取glProgramState
	local glProgramState = cc.GLProgramState:getOrCreateWithGLProgram(glProgram)
	-- 3.设置属性值
	local textureSize = tempSp:getContentSize()
	glProgramState:setUniformVec2("u_direction", cc.vertex2F(1.0, 1.0))
	glProgramState:setUniformFloat("u_radius", initBlurValue)
	glProgramState:setUniformFloat("u_resolution", 1024)
	glProgramState:setUniformFloat("fadeAlpha", 0.0)

	tempSp:setGLProgram(glProgram)
	tempSp:setGLProgramState(glProgramState)

	return glProgramState
end

function CardMemoryView:RunBlurAction(tempSp, index, initBlurValue)
	local curBlurValue = initBlurValue
	local curAlpha = 0.0
	if not self.updateHandler then
		self.updateHandler = {}
	end
	local glProgramState = tempSp:getGLProgramState()
	self.updateHandler[index] = scheduler.scheduleUpdateGlobal(function (dt)
		curBlurValue = curBlurValue - initBlurValue * dt
		curAlpha = curAlpha + dt
		if 0 > curBlurValue then
			if self.updateHandler then
				scheduler.unscheduleGlobal(self.updateHandler[index])
				self.updateHandler[index] = nil
			end
			glProgramState:setUniformFloat("u_radius", 0.0)
		else
			glProgramState:setUniformFloat("u_radius", curBlurValue)
		end
		if 1 < curAlpha then
			glProgramState:setUniformFloat("fadeAlpha", 1.0)
		else
			glProgramState:setUniformFloat("fadeAlpha", curAlpha)
		end
	end)
end

function CardMemoryView:DelayClearWords()
	local rotation = 45
	local endBlurValue = 4
	local chairWordsBG = self.viewData.chairWordsBG
	chairWordsBG:stopAllActions()
	chairWordsBG:runAction(cc.Sequence:create(
		cc.FadeOut:create(2.0 / 3.0 + table.nums(self.words) / 30),
		cc.Hide:create()
	))
	for i = 1, table.nums(self.words) do
		self.words[i]:runAction(cc.Sequence:create(
			cc.DelayTime:create(i / 30),
			cc.Spawn:create(
				cc.EaseIn:create(cc.RotateBy:create(2.0 / 3.0, rotation), 2),
				cc.EaseIn:create(cc.MoveBy:create(2.0 / 3.0, cc.p(200,80)), 2),
				cc.CallFunc:create(function ()
					self:RunBlurOutAction(self.words[i], i, endBlurValue)
				end)
			)
			-- ,cc.RemoveSelf:create()
		))
	end
end

function CardMemoryView:RunBlurOutAction(tempSp, index, endBlurValue)
	local curBlurValue = 0.0
	local curAlpha = 1.0
	if not self.updateHandler then
		self.updateHandler = {}
	end
	local glProgramState = tempSp:getGLProgramState()
	self.updateHandler[index] = scheduler.scheduleUpdateGlobal(function (dt)
		curBlurValue = curBlurValue + endBlurValue * dt * 3.0 / 2.0
		curAlpha = curAlpha - dt * 3.0 / 2.0
		if endBlurValue < curBlurValue then
			-- scheduler.unscheduleGlobal(self.updateHandler[index])
			glProgramState:setUniformFloat("u_radius", endBlurValue)
		else
			glProgramState:setUniformFloat("u_radius", curBlurValue)
		end
		if 0 > curAlpha then
			if self.updateHandler then
				scheduler.unscheduleGlobal(self.updateHandler[index])
				self.updateHandler[index] = nil
			end
			tempSp:removeFromParent()
		else
			glProgramState:setUniformFloat("fadeAlpha", curAlpha)
		end
	end)
end

function CardMemoryView:ShowDialog(text, delay, pos, cueSheet, cueName, acbFile)
	local dialogFadeTime = 1
	local duration = 2

	-- 获取cue时长
	if acbFile and utils.isExistent(acbFile) then
		app.audioMgr:AddCueSheet(cueSheet, acbFile)
		local time = app.audioMgr:GetPlayerCueTime(cueSheet, cueName)
		if time > 0 then
			duration = time
		end
	end
	self:runAction(cc.Sequence:create(
		cc.DelayTime:create(delay),
		cc.CallFunc:create(function ()
			local dialogSpine = self.viewData.dialogSpine
			dialogSpine:setAnimation(1, 'words', false)
			dialogSpine:update(0)
			dialogSpine:setToSetupPose()
			dialogSpine:setPosition(cc.p(pos.x + 310,pos.y + 110))
			PlayAudioClip(AUDIOS.UI.ui_vow_interim.id)

			local dialogueBG = self.viewData.dialogueBG
			local dialogueLayer = self.viewData.dialogueLayer


			local dialogLabel = self.viewData.dialogLabel
			dialogLabel:setOpacity(0)
			dialogLabel:setString(text)
			dialogLabel:runAction(cc.Sequence:create(
				cc.DelayTime:create(0.8),
				cc.FadeIn:create(dialogFadeTime),
				cc.DelayTime:create(duration - 0.5),
				cc.FadeOut:create(dialogFadeTime)
			))

			local contentSize = cc.size(628, 207)
			local offset = 0
			local maxY = display.height - 31 - contentSize.height
			if 80 < display.getLabelContentSize(dialogLabel).height then
				local scale = (display.getLabelContentSize(dialogLabel).height + 124) / 207
				dialogueBG:setScaleY(scale)
				offset = (scale - 1) * contentSize.height
				pos.y = math.max(pos.y, offset)
				dialogueLayer:setPosition(cc.p(pos.x, pos.y))
			else
				dialogueBG:setScaleY(1)
				dialogueLayer:setPosition(pos)
			end

			local dialogSpine = self.viewData.dialogSpine
			dialogSpine:setAnimation(1, 'words', false)
			dialogSpine:update(0)
			dialogSpine:setToSetupPose()
			dialogSpine:setPosition(cc.p(pos.x + 310,pos.y + 110 - offset / 2))
			PlayAudioClip(AUDIOS.UI.ui_vow_interim.id)

			dialogueBG:setOpacity(0)
			dialogueBG:runAction(cc.Sequence:create(
				cc.DelayTime:create(0.5),
				cc.CallFunc:create(function ()
					-- 播放音频
					if acbFile and utils.isExistent(acbFile) then
						app.audioMgr:AddCueSheet(cueSheet, acbFile)
						self.cueSheet = cueSheet
						app.audioMgr:PlayAudioClip(cueSheet, cueName)
					end
				end),
				cc.FadeIn:create(dialogFadeTime),
				cc.DelayTime:create(duration),
				cc.CallFunc:create(function ()
					self.cueSheet = nil
				end),
				cc.FadeOut:create(dialogFadeTime)
			))
		end)
	))
	return 0.5 + duration + dialogFadeTime * 2
end

return CardMemoryView
