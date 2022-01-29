local GameScene = require( 'Frame.GameScene' )
local DebugCardResourceScene = class('DebugCardResourceScene', GameScene)

local LANGUAGE_TAG = 'zh-cn'

function DebugCardResourceScene:ctor( ... )
	self.args = unpack({...})

	self.configtables = {}

	self:setBackgroundColor(cc.c4b(0, 128, 128, 255))

	self.debugIds = {
		'200125_7'
	}

	self:DebugSpineByFolder()
	-- self:DebugSpineById()
	-- self:DebugResources()
	-- self:DebugAllCardResources()
	self:DebugAllCardSkinResources()
	self:DebugAllMonsterSkinResources()
	-- self:DebugAllMonsterResources()
	-- self:DebugRewriteSpineFiles()


	-- 根据玩家等级获取可以进行的关卡战斗怪物资源
	-- self:DebugNecessaryQuestResByPlayerLevel(17)


	-------------------------------- debug new spine animation cache --------------------------------
	-- local testSpineAnimationCache = sp.SpineAnimationCache:getInstance('battle')
	-- testSpineAnimationCache:addCacheData('cards/spine/avatar/200024', 'testA', 0.5)

	-- local testAvatar = testSpineAnimationCache:createWithName('testA')
	-- testAvatar:update(0)
	-- testAvatar:setAnimation(0, 'idle', true)
	-- self:addChild(testAvatar, 111)
	-- testAvatar:setPosition(display.center)

	-- sp.SpineAnimationCache:releaseInstance('battle')
	-- sp.SpineAnimationCache:clearInstances()
	-------------------------------- debug new spine animation cache --------------------------------

	-- sp.SpineAnimationCache:getInstance():addCacheData('cards/spine/avatar/300024', 'test', 1)
	-- sp.SpineAnimationCache:getInstance():addCacheData('root/skeleton', 'toucheffect', 1)

	-- local ttt = sp.SkeletonAnimation:create(
	-- 	'cards/spine/avatar/200001.json',
	-- 	'cards/spine/avatar/200001.atlas',
	-- 	1)
	-- ttt:update(0)

	-- -- for k,a in pairs(ttt:getAnimationsData()) do
	-- -- 	print(k)
	-- -- 	ttt:addAnimation(0, k, false)
	-- -- end

	-- ttt:addAnimation(0, 'idle', true)

	-- self:addChild(ttt, 99999)
	-- ttt:setPosition(cc.p(display.cx, 100))

	-- dump(ttt:getBorderBox('viewBox'))
	-- dump(ttt:getBorderBox('collisionBox'))

	-- local replayBtn = display.newButton(0, 0, {n = 'ui/common/common_btn_orange.png', cb = function (sender)
	-- 	ttt:removeFromParent()
	-- end})
	-- display.commonLabelParams(replayBtn, {text = __('重播'), fontSize = 20, color = '#ffffff'})
	-- display.commonUIParams(replayBtn, {po = cc.p(1000, 500)})
	-- self:addChild(replayBtn, 99999)

	-- local t = require('Game.config.CardDrawLocation')
	-- local tt = require('Game.config.TeamFormationCellLocation')
	-- local ttt = require('Game.config.MonsterHeadFixFootLocation')

	-- local ids1 = table.keys(t)
	-- table.sort(ids1, function (a, b)
	-- 	local sa = string.split(a, '_')
	-- 	local sb = string.split(b, '_')
	-- 	local ida = checkint(sa[1])
	-- 	local idb = checkint(sb[1])

	-- 	if ida == idb then
	-- 		return ida + checkint(sa[2]) < idb + checkint(sb[2])
	-- 	else
	-- 		return ida < idb
	-- 	end
	-- end)

	-- local ids3 = table.keys(ttt)
	-- table.sort(ids3, function (a, b)
	-- 	local sa = string.split(a, '_')
	-- 	local sb = string.split(b, '_')
	-- 	local ida = checkint(sa[1])
	-- 	local idb = checkint(sb[1])

	-- 	if ida == idb then
	-- 		return ida + checkint(sa[2]) < idb + checkint(sb[2])
	-- 	else
	-- 		return ida < idb
	-- 	end
	-- end)

	-- local str = '' 
	-- for i,v in ipairs(ids1) do
	-- 	local p1 = t[v] or {x = 0, y = 0, scale = 1, rotate = 0}
	-- 	local p2 = tt[v] or {x = 0, y = 0, scale = 1, rotate = 0}
	-- 	local p3 = ttt[v] or {x = 0, y = 0, scale = 1, rotate = 0}

	-- 	str = str .. v .. ',' .. '__主界面立绘坐标信息__,' .. (p1.x or 0) .. ',' .. (p1.y or 0) .. ',' .. (p1.scale or 1) .. ',' .. (p1.rotate or 0) .. ',' .. 
	-- 	'__编队立绘坐标信息__,' .. (p2.x or 0) .. ',' .. (p2.y or 0) .. ',' .. (p2.scale or 1) .. ',' .. (p2.rotate or 0) .. ',' .. 
	-- 	'__怪物头像修正坐标__,' .. (p3.x or 0) .. ',' .. (p3.y or 0) .. ',' .. (p3.scale or 1) .. ',' .. (p3.rotate or 0) .. ',' .. '\n'
	-- end

	-- for i,v in ipairs(ids3) do
	-- 	local p1 = t[v] or {x = 0, y = 0, scale = 1, rotate = 0}
	-- 	local p2 = tt[v] or {x = 0, y = 0, scale = 1, rotate = 0}
	-- 	local p3 = ttt[v] or {x = 0, y = 0, scale = 1, rotate = 0}

	-- 	str = str .. v .. ',' .. '__主界面立绘坐标信息__,' .. (p1.x or 0) .. ',' .. (p1.y or 0) .. ',' .. (p1.scale or 1) .. ',' .. (p1.rotate or 0) .. ',' .. 
	-- 	'__编队立绘坐标信息__,' .. (p2.x or 0) .. ',' .. (p2.y or 0) .. ',' .. (p2.scale or 1) .. ',' .. (p2.rotate or 0) .. ',' .. 
	-- 	'__怪物头像修正坐标__,' .. (p3.x or 0) .. ',' .. (p3.y or 0) .. ',' .. (p3.scale or 1) .. ',' .. (p3.rotate or 0) .. ',' .. '\n'
	-- end

	-- print(str)

	-- local fontPath = 'font/battle_font_orange.fnt'
	-- local damageLabel = CLabelBMFont:create('0123456789', fontPath)
	-- damageLabel:setAnchorPoint(cc.p(0.5, 0.5))
	-- damageLabel:setPosition(display.center)
	-- self:addChild(damageLabel, 100)
	-- damageLabel:setBMFontSize(70)

	-- local animation = cc.Animation:create()
	-- for i = 1, 10 do
	-- 	animation:addSpriteFrameWithFile(_res(string.format('update/loading_run_%d.png', i)))
	-- end
	-- animation:setDelayPerUnit(0.05)
	-- animation:setRestoreOriginalFrame(true)

	-- local loadingAvatar = display.newNSprite(_res('update/loading_run_1.png'), 0, 0)
	-- display.commonUIParams(loadingAvatar, {po = cc.p(display.cx, display.cy)})
	-- self:addChild(loadingAvatar)
	-- loadingAvatar:runAction(cc.RepeatForever:create(cc.Animate:create(animation)))

	-- local timerLabel = CLabelBMFont:create(888, 'font/small/common_text_num.fnt')
	-- timerLabel:setBMFontSize(48)
	-- timerLabel:setAnchorPoint(cc.p(0.5, 0.5))
	-- timerLabel:setPosition(display.cx, display.cy)
	-- self:addChild(timerLabel, 10)

	-- local actionSeq = cc.Sequence:create(
	-- 	cc.ScaleTo:create(10, 10))
	-- timerLabel:runAction(actionSeq)
end

function DebugCardResourceScene:DebugSpineByFolder()
	print('>>>>>>>>>>>>>start')
	self.debugPath = {}
	local lfs = require('lfs')

	local folderPath = 'res/debugspine'
	for file in lfs.dir(folderPath) do
		if nil ~= string.find(tostring(file), '.json') then
			local name = string.split(file, '.')[1]
			table.insert(self.debugPath, {path = folderPath .. '/' .. name, name = name})
		end
	end

	local scrollView = CScrollView:create(display.size)
	scrollView:setDirection(eScrollViewDirectionHorizontal)
	scrollView:setAnchorPoint(cc.p(0.5, 0.5))
	scrollView:setPosition(display.center)
	scrollView:setContainerSize(cc.size(2000, 150))
	self:addChild(scrollView)

	local resultLog = {}
	local avatarEvents = {}
	local avatars = {}

	local perRow, perCol = 4, 2
	local w = display.width / (perRow)
	local h = display.height / (perCol)
	local x, y = 0, 0

	for i,d in ipairs(self.debugPath) do
		print(d.path)
		x = w * ((i - 1) % perRow + 0.5) + display.width * (math.ceil(i / (perRow * perCol)) - 1)
		y = math.ceil(i / perRow) % 2 * h

		---------------- check error ----------------

		resultLog[tostring(d.name)] = {}
		local errorLog = ' 			error check ... \n 			'
		avatarEvents[tostring(d.name)] = {}

		local testAvatar = sp.SkeletonAnimation:create(d.path .. '.json', d.path .. '.atlas', 0.5)
		testAvatar:update(0)
		scrollView:getContainer():addChild(testAvatar)
		testAvatar:setPosition(cc.p(x, y + 25))
		dump(testAvatar:getAnimationsData())

		-- self:DebugBorderBox(testAvatar, 'collisionBox')

		table.insert(avatars, testAvatar)

		local idLabel = display.newLabel(x, y, {text = d.name, fontSize = 18, color = '#ffffff', ap = cc.p(0.5, 0)})
		scrollView:getContainer():addChild(idLabel)

		local viewBox = testAvatar:getBorderBox('viewBox')
		local collisionBox = testAvatar:getBorderBox('collisionBox')
		if nil == viewBox then
			errorLog = errorLog .. 'no #viewBox#, '
		end
		-- dump(collisionBox)
		if nil == collisionBox then
			errorLog = errorLog .. 'no #collisionBox#, '
		end

		local necessaryAnimation = {
			'idle',
			'attack',
			'attacked',
			'run',
			'die',
			'win',
			'eat'
		}
		local avatarAnimationsData = testAvatar:getAnimationsData()
		for _,v in ipairs(necessaryAnimation) do
			if nil == avatarAnimationsData[v] then
				errorLog = errorLog .. 'no #' .. v .. '#, '
			end
		end

		---------------- check error ----------------

		---------------- check event ----------------

		errorLog = errorLog .. '\n 			event check ... '

		testAvatar:registerSpineEventHandler(function (event)
			local animationName = event.animation
			local eventName = event.eventData.name
			if nil == avatarEvents[tostring(d.name)][eventName] then
				avatarEvents[tostring(d.name)][eventName] = {}
			end
			table.insert(avatarEvents[tostring(d.name)][eventName], animationName)
		end, sp.EventType.ANIMATION_EVENT)
		
		for _, aniname in ipairs(self:GetSortAnimationsName(avatarAnimationsData)) do
			testAvatar:addAnimation(0, aniname, false)
		end
		---------------- check event ----------------

		resultLog[tostring(d.name)].errorLog = errorLog
	end

	scrollView:setContainerSize(cc.size(display.width * (math.ceil(x / display.width)), display.height))

	local checkBtn = display.newButton(0, 0, {n = 'ui/common/common_btn_orange.png', cb = function (sender)
		for k,r in pairs(resultLog) do
			local l = r.errorLog
			local events = avatarEvents[k]
			for en,v in pairs(events) do
				for i,an in ipairs(v) do
					l = l .. '\n 			get event #' .. en .. '# by #' .. an .. '#'
				end
			end
			print('---------' .. k .. '---------')
			print(l)


		end
	end})
	display.commonLabelParams(checkBtn, {text = __('spine查错'), fontSize = 20, color = '#ffffff'})
	display.commonUIParams(checkBtn, {po = cc.p(checkBtn:getContentSize().width * 0.5, display.height - checkBtn:getContentSize().height * 0.5)})
	self:addChild(checkBtn, 99999)

	local replayBtn = display.newButton(0, 0, {n = 'ui/common/common_btn_orange.png', cb = function (sender)
		for i,v in ipairs(avatars) do
			v:setToSetupPose()
			v:clearTracks()
			for _, aniname in ipairs(self:GetSortAnimationsName(v:getAnimationsData())) do
				v:addAnimation(0, aniname, false)
			end
		end
	end})
	display.commonLabelParams(replayBtn, {text = __('正序播放'), fontSize = 20, color = '#ffffff'})
	display.commonUIParams(replayBtn, {po = cc.p(checkBtn:getPositionX() + checkBtn:getContentSize().width,checkBtn:getPositionY())})
	self:addChild(replayBtn, 99999)

	local replayBtn2 = display.newButton(0, 0, {n = 'ui/common/common_btn_orange.png', cb = function (sender)
		for i,v in ipairs(avatars) do
			v:setToSetupPose()
			v:clearTracks()
			for _, aniname in ipairs(self:GetSortAnimationsName(v:getAnimationsData(), true)) do
				v:addAnimation(0, aniname, false)
			end
		end
	end})
	display.commonLabelParams(replayBtn2, {text = __('倒序播放'), fontSize = 20, color = '#ffffff'})
	display.commonUIParams(replayBtn2, {po = cc.p(replayBtn:getPositionX() + replayBtn:getContentSize().width,replayBtn:getPositionY())})
	self:addChild(replayBtn2, 99999)
	print('>>>>>>>>>>>>>end')
end

function DebugCardResourceScene:DebugSpineById()

	local scrollView = CScrollView:create(display.size)
	scrollView:setDirection(eScrollViewDirectionHorizontal)
	scrollView:setAnchorPoint(cc.p(0.5, 0.5))
	scrollView:setPosition(display.center)
	scrollView:setContainerSize(cc.size(2000, 150))
	self:addChild(scrollView)

	-- scrollView:getContainer():setBackgroundColor(cc.c4b(200, 200, 0, 100))

	local resultLog = {}
	local avatarEvents = {}
	local avatars = {}

	local perRow, perCol = 4, 2
	local w = display.width / (perRow)
	local h = display.height / (perCol)
	local x, y = 0, 0

	for i,spineId in ipairs(self.debugIds) do
		local p = self:AvatarPath(spineId)
		x = w * ((i - 1) % perRow + 0.5) + display.width * (math.ceil(i / (perRow * perCol)) - 1)
		y = math.ceil(i / perRow) % 2 * h

		---------------- check error ----------------

		resultLog[tostring(spineId)] = {}
		local errorLog = ' 			error check ... \n 			'
		avatarEvents[tostring(spineId)] = {}

		local testAvatar = sp.SkeletonAnimation:create(p .. '.json', p .. '.atlas', 0.5)
		testAvatar:update(0)
		scrollView:getContainer():addChild(testAvatar)
		testAvatar:setPosition(cc.p(x, y + 25))

		table.insert(avatars, testAvatar)

		local idLabel = display.newLabel(x, y, {text = spineId, fontSize = 18, color = '#ffffff', ap = cc.p(0.5, 0)})
		scrollView:getContainer():addChild(idLabel)

		local viewBox = testAvatar:getBorderBox('viewBox')
		local collisionBox = testAvatar:getBorderBox('collisionBox')

		-- debug border box --
		self:DebugBorderBox(testAvatar, 'collisionBox')
		-- debug border box --

		if nil == viewBox then
			errorLog = errorLog .. 'no #viewBox#, '
		end
		if nil == collisionBox then
			errorLog = errorLog .. 'no #collisionBox#, '
		end

		local necessaryAnimation = {
			'idle',
			'attack',
			'attacked',
			'run',
			'die',
			'win',
		}
		local avatarAnimationsData = testAvatar:getAnimationsData()
		for _,v in ipairs(necessaryAnimation) do
			if nil == avatarAnimationsData[v] then
				errorLog = errorLog .. 'no #' .. v .. '#, '
			end
		end

		---------------- check error ----------------

		---------------- check event ----------------

		errorLog = errorLog .. '\n 			event check ... '

		testAvatar:registerSpineEventHandler(function (event)
			local animationName = event.animation
			local eventName = event.eventData.name
			if nil == avatarEvents[tostring(spineId)][eventName] then
				avatarEvents[tostring(spineId)][eventName] = {}
			end
			table.insert(avatarEvents[tostring(spineId)][eventName], animationName)
		end, sp.EventType.ANIMATION_EVENT)

		for _, aniname in ipairs(self:GetSortAnimationsName(avatarAnimationsData)) do
			testAvatar:addAnimation(0, aniname, false)
		end
		---------------- check event ----------------

		resultLog[tostring(spineId)].errorLog = errorLog
	end

	scrollView:setContainerSize(cc.size(display.width * (math.ceil(x / display.width)), display.height))

	local checkBtn = display.newButton(0, 0, {n = 'ui/common/common_btn_orange.png', cb = function (sender)
		for k,r in pairs(resultLog) do
			local l = r.errorLog
			local events = avatarEvents[k]
			for en,v in pairs(events) do
				for i,an in ipairs(v) do
					l = l .. '\n 			get event #' .. en .. '# by #' .. an .. '#'
				end
			end
			print('---------' .. k .. '---------')
			print(l)
		end
	end})
	display.commonLabelParams(checkBtn, {text = __('spine查错'), fontSize = 20, color = '#ffffff'})
	display.commonUIParams(checkBtn, {po = cc.p(checkBtn:getContentSize().width * 0.5, display.height - checkBtn:getContentSize().height * 0.5)})
	self:addChild(checkBtn, 99999)

	local replayBtn = display.newButton(0, 0, {n = 'ui/common/common_btn_orange.png', cb = function (sender)
		for i,v in ipairs(avatars) do
			v:setToSetupPose()
			v:clearTracks()
			for _, aniname in ipairs(self:GetSortAnimationsName(v:getAnimationsData())) do
				v:addAnimation(0, aniname, false)
			end
		end
	end})
	display.commonLabelParams(replayBtn, {text = __('正序播放'), fontSize = 20, color = '#ffffff'})
	display.commonUIParams(replayBtn, {po = cc.p(checkBtn:getPositionX() + checkBtn:getContentSize().width,checkBtn:getPositionY())})
	self:addChild(replayBtn, 99999)

	local replayBtn2 = display.newButton(0, 0, {n = 'ui/common/common_btn_orange.png', cb = function (sender)
		for i,v in ipairs(avatars) do
			v:setToSetupPose()
			v:clearTracks()
			for _, aniname in ipairs(self:GetSortAnimationsName(v:getAnimationsData(), true)) do
				v:addAnimation(0, aniname, false)
			end
		end
	end})
	display.commonLabelParams(replayBtn2, {text = __('倒序播放'), fontSize = 20, color = '#ffffff'})
	display.commonUIParams(replayBtn2, {po = cc.p(replayBtn:getPositionX() + replayBtn:getContentSize().width,replayBtn:getPositionY())})
	self:addChild(replayBtn2, 99999)

end
function DebugCardResourceScene:DebugResources()
	local spineLog = '\n\n...... spine files check'
	local drawLog = '\n\n...... draw files check'
	local headLog = '\n\n...... head files check'

	for i,v in ipairs(self.debugIds) do
		if not utils.isExistent(_res(self:AvatarPath(v) .. '.json')) then
			spineLog = spineLog .. '\n' .. v .. ' no spine file'
		end
		if not utils.isExistent(_res(self:DrawPath(v))) then
			drawLog = drawLog .. '\n' .. v .. ' no card file'
		end
		if not utils.isExistent(_res(self:HeadPath(v))) then
			headLog = headLog .. '\n' .. v .. ' no head file'
		end
	end

	local checkBtn = display.newButton(0, 0, {n = 'ui/common/common_btn_orange.png', cb = function (sender)
		print(spineLog)
		print(drawLog)
		print(headLog)
	end})
	display.commonLabelParams(checkBtn, {text = __('文件查错'), fontSize = 20, color = '#ffffff'})
	display.commonUIParams(checkBtn, {po = cc.p(display.width - checkBtn:getContentSize().width * 0.5, display.height - checkBtn:getContentSize().height * 0.5)})
	self:addChild(checkBtn, 99999)
end
function DebugCardResourceScene:DebugAllCardResources()
	local log = '\n\n................. here start check card resource by card config .................'

	local cardConfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('card', 'card'))

	local sk = sortByKey(cardConfigtable)
	local c_ = nil
	for i,skey in ipairs(sk) do
		c_ = cardConfigtable[skey]
		for k,v in pairs(c_.skin) do
			for skinId, _ in pairs(v) do
				---------------- check draw res ----------------
				local drawPath = self:GetCardDrawPathBySkinId(checkint(skinId))
				if not utils.isExistent(_res(drawPath)) then
					log = log .. self:GetErrorLog(string.format('cannot find card draw -> cardId:%s, skinId:%s', tostring(skey), tostring(skinId)))
				end
				---------------- check draw res ----------------

				---------------- check head res ----------------
				local headPath = self:GetCardHeadPathBySkinId(checkint(skinId))
				if not utils.isExistent(_res(headPath)) then
					log = log .. self:GetErrorLog(string.format('cannot find card head icon -> cardId:%s, skinId:%s', tostring(skey), tostring(skinId)))
				end
				---------------- check head res ----------------

				---------------- check head res ----------------
				local spinePath = self:GetCardSpinePathBySkinId(checkint(skinId))
				if not utils.isExistent(_res(spinePath .. '.json')) then
					log = log .. self:GetErrorLog(string.format('cannot find card spine -> cardId:%s, skinId:%s', tostring(skey), tostring(skinId)))
				end
				---------------- check head res ----------------

				-- 如果是ur卡需要检查背景
				if 4 == checkint(c_.qualityId) then
					---------------- check bg res ----------------
					local bgPath = self:GetCardBgPathBySkinId(checkint(skinId))
					if not utils.isExistent(_res(bgPath)) then
						log = log .. self:GetErrorLog(string.format('cannot find ur card bg -> cardId:%s, skinId:%s', tostring(skey), tostring(skinId)))
					end
					---------------- check bg res ----------------
				end
			end
		end
	end

	log = log .. '\n\n>>>>>>>>>>>>>>>>>>>>>>> here over check card resource by card config <<<<<<<<<<<<<<<<<<<<<'

	local checkBtn = display.newButton(0, 0, {n = 'ui/common/common_btn_orange.png', cb = function (sender)
		print(log)
	end})

	display.commonLabelParams(checkBtn, {text = __('卡牌资源查错'), fontSize = 20, color = '#ffffff'})
	display.commonUIParams(checkBtn, {po = cc.p(display.width - checkBtn:getContentSize().width * 1.5, display.height - checkBtn:getContentSize().height * 0.5)})
	self:addChild(checkBtn, 99999)
end
function DebugCardResourceScene:DebugAllCardSkinResources()
	local log = '\n\n................. here start check card resource by skin config .................'

	local cardSkinConfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('goods', 'cardSkin'))
	local cardConfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('card', 'card'))

	local sk = sortByKey(cardSkinConfigtable)
	local skinConfig = nil
	for i,skinId in ipairs(sk) do
		skinConfig = cardSkinConfigtable[skinId]
		---------------- check draw res ----------------
		local drawPath = self:GetCardDrawPathBySkinId(checkint(skinId))
		if not utils.isExistent(_res(drawPath)) then
			log = log .. self:GetErrorLog(string.format('cannot find card draw -> cardId:%s, skinId:%s', tostring(skinConfig.cardId), tostring(skinId)))
		end
		---------------- check draw res ----------------

		---------------- check draw bg res ----------------
		-- 检查ur卡的背景
		local cardConfig = cardConfigtable[tostring(skinConfig.cardId)]
		if nil ~= cardConfig then
			if 4 == checkint(cardConfig.qualityId) then
				local bgPath = self:GetCardBgPathBySkinId(checkint(skinId))
				if not utils.isExistent(_res(bgPath)) then
					log = log .. self:GetErrorLog(string.format('cannot find ur card bg -> cardId:%s, skinId:%s', tostring(skinConfig.cardId), tostring(skinId)))
				end
			end
		end
		---------------- check draw bg res ----------------

		---------------- check head res ----------------
		local headPath = self:GetCardHeadPathBySkinId(checkint(skinId))
		if not utils.isExistent(_res(headPath)) then
			log = log .. self:GetErrorLog(string.format('cannot find card head icon -> cardId:%s, skinId:%s', tostring(skinConfig.cardId), tostring(skinId)))
		end
		---------------- check head res ----------------

		---------------- check spine res ----------------
		local spinePath = self:GetCardSpinePathBySkinId(checkint(skinId))
		if not utils.isExistent(_res(spinePath .. '.json')) then
			log = log .. self:GetErrorLog(string.format('cannot find card spine -> cardId:%s, skinId:%s', tostring(skinConfig.cardId), tostring(skinId)))
		end
		---------------- check spine res ----------------
	end

	log = log .. '\n\n>>>>>>>>>>>>>>>>>>>>>>> here over check card resource by skin config <<<<<<<<<<<<<<<<<<<<<'

	local checkBtn = display.newButton(0, 0, {n = 'ui/common/common_btn_orange.png', cb = function (sender)
		print(log)
	end})

	display.commonLabelParams(checkBtn, {text = __('卡牌皮肤资源查错'), fontSize = 20, color = '#ffffff'})
	display.commonUIParams(checkBtn, {po = cc.p(display.width - checkBtn:getContentSize().width * 1.5, display.height - checkBtn:getContentSize().height * 0.5)})
	self:addChild(checkBtn, 99999)
end
function DebugCardResourceScene:DebugAllMonsterSkinResources()
	local log = '\n\n................. here start check monster resource by skin config .................'

	local cardSkinConfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('monster', 'monsterSkin'))
	local cardConfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('monster', 'monster'))

	local sk = sortByKey(cardSkinConfigtable)
	local skinConfig = nil
	local cardId = nil
	local cardConfig = nil

	for i,skinId in ipairs(sk) do
		skinConfig = cardSkinConfigtable[skinId]
		cardId = checkint(skinConfig.cardId)
		cardConfig = cardConfigtable[tostring(cardId)]

		if cardConfig then
			if 390000 < cardId and 400000 > cardId then

			else
				---------------- check draw res ----------------
				local drawPath = self:GetCardDrawPathBySkinId(checkint(skinId))
				if not utils.isExistent(_res(drawPath)) then
					log = log .. self:GetErrorLog(string.format('cannot find card draw -> monsterId:%s, skinId:%s', tostring(cardId), tostring(skinId)))
				end
				---------------- check draw res ----------------

				---------------- check head res ----------------
				local headPath = self:GetCardHeadPathBySkinId(checkint(skinId))
				if not utils.isExistent(_res(headPath)) then
					log = log .. self:GetErrorLog(string.format('cannot find card head icon -> monsterId:%s, skinId:%s', tostring(cardId), tostring(skinId)))
				end
				---------------- check head res ----------------

				---------------- check spine res ----------------
				local spinePath = self:GetCardSpinePathBySkinId(checkint(skinId))
				if not utils.isExistent(_res(spinePath .. '.json')) then
					log = log .. self:GetErrorLog(string.format('cannot find card spine -> monsterId:%s, skinId:%s', tostring(cardId), tostring(skinId)))
				end
				---------------- check spine res ----------------
			end
		end
	end

	log = log .. '\n\n>>>>>>>>>>>>>>>>>>>>>>> here over check monster resource by skin config <<<<<<<<<<<<<<<<<<<<<'

	local checkBtn = display.newButton(0, 0, {n = 'ui/common/common_btn_orange.png', cb = function (sender)
		print(log)
	end})

	display.commonLabelParams(checkBtn, {text = __('怪物皮肤资源查错'), fontSize = 20, color = '#ffffff'})
	display.commonUIParams(checkBtn, {po = cc.p(display.width - checkBtn:getContentSize().width * 0.5, display.height - checkBtn:getContentSize().height * 0.5)})
	self:addChild(checkBtn, 99999)
end

function DebugCardResourceScene:DebugAllMonsterResources()
	local spineLog = '\n\n...... spine files check'
	local drawLog = '\n\n...... draw files check'
	local headLog = '\n\n...... head files check'

	local cardConfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('monster', 'monster'))
	local sk = sortByKey(cardConfigtable)
	local c_ = nil
	for i,skey in ipairs(sk) do
		c_ = cardConfigtable[skey]
		if not utils.isExistent(_res(self:AvatarPath(c_.drawId) .. '.json')) then
			spineLog = spineLog .. '\n' .. c_.drawId .. ' no spine file'
		end
		if not utils.isExistent(_res(self:DrawPath(c_.drawId))) then
			drawLog = drawLog .. '\n' .. c_.drawId .. ' no card file'
		end
		if not utils.isExistent(_res(self:HeadPath(c_.drawId))) then
			headLog = headLog .. '\n' .. c_.drawId .. ' no head file'
		end
	end

	local checkBtn = display.newButton(0, 0, {n = 'ui/common/common_btn_orange.png', cb = function (sender)
		print(spineLog)
		print(drawLog)
		print(headLog)
	end})
	display.commonLabelParams(checkBtn, {text = __('怪物文件查错'), fontSize = 20, color = '#ffffff'})
	display.commonUIParams(checkBtn, {po = cc.p(display.width - checkBtn:getContentSize().width * 2.5, display.height - checkBtn:getContentSize().height * 0.5)})
	self:addChild(checkBtn, 99999)
end

function DebugCardResourceScene:AvatarPath(id)
	return 'cards/spine/avatar/' .. id
end
function DebugCardResourceScene:DrawPath(id)
	return 'cards/card/card_draw_' .. id .. '.png'
end
function DebugCardResourceScene:HeadPath(id)
	return 'cards/head/card_icon_' .. id .. '.png'
end

function DebugCardResourceScene:DebugBorderBox(avatar, borderBoxName)
	local borderBox = avatar:getBorderBox(borderBoxName)
	dump(borderBox)
	local borderBoxLayer = display.newLayer(0, 0, {size = cc.size(borderBox.width, borderBox.height), color = '#1d2a33'})
	borderBoxLayer:setOpacity(200)
	avatar:addChild(borderBoxLayer, 99)
	borderBoxLayer:schedule(function ()
		local borderBox = avatar:getBorderBox(borderBoxName)
		borderBoxLayer:setPosition(cc.p(borderBox.x, borderBox.y))
	end, 1 * cc.Director:getInstance():getAnimationInterval())
end
--[[
获取配表路径
@params modelName str 模块名
@params configName str 配表名
@return path str 配表路径
--]]
function DebugCardResourceScene:GetConfigPath(modelName, configName)
	return 'src/conf/' .. LANGUAGE_TAG .. '/' .. modelName .. '/' .. configName .. '.json'
end
--[[
根据路径获取配表缓存key
@params path str 配表路径
@return configtableKey str 
--]]
function DebugCardResourceScene:GetConfigCacheKeyByPath(path)
	local configtableKey = nil
	local ss = string.split(path, '/')
	configtableKey = ss[#ss - 1] .. string.split(ss[#ss], '.')[1]
	return configtableKey
end
--[[
获取指定路径的配表lua结构
@params filePath str 文件路径
@return _ table 配表lua结构
--]]
function DebugCardResourceScene:ConvertJsonToLuaByFilePath(filePath)
	local configtableKey = self:GetConfigCacheKeyByPath(filePath)
	if nil == self.configtables[configtableKey] then
		local file = assert(io.open(filePath, 'r'), self:GetErrorLog(string.format('cannot find config json file -> %s', filePath)))
		local fileContent = file:read('*a')
		local configtable = json.decode(fileContent)
		file:close()
		self.configtables[configtableKey] = configtable
	end
	return self.configtables[configtableKey]
end
--[[
警告输出
@params content str 输出内容
--]]
function DebugCardResourceScene:GetWaringLog(content)
	local log = ''
	if not SHOW_WARING then return log end
	log = log .. '\n\n↓↓↓WARING↓↓↓\n     ' .. content .. '\n'
	return log
end
--[[
错误输出
@params content str 输出内容
--]]
function DebugCardResourceScene:GetErrorLog(content)
	local log = ''
	log = log .. '\n\n--------------------\n↓↓↓ERROR↓↓↓\n--------------------\n     ' .. content .. '\n'
	return log
end
--[[
根据皮肤id获取卡牌立绘路径
@params skinId int 皮肤id
--]]
function DebugCardResourceScene:GetCardDrawPathBySkinId(skinId)
	local skinconfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('goods', 'cardSkin'))
	if skinId > 259000 then
		skinconfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('monster', 'monsterSkin'))
	end
	local skinConfig = skinconfigtable[tostring(skinId)]
	return string.format('cards/card/card_draw_%s.png', tostring(skinConfig.drawId))
end
--[[
根据皮肤id获取卡牌头像路径
@params skinId int 皮肤id
--]]
function DebugCardResourceScene:GetCardHeadPathBySkinId(skinId)
	local skinconfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('goods', 'cardSkin'))
	if skinId > 259000 then
		skinconfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('monster', 'monsterSkin'))
	end
	local skinConfig = skinconfigtable[tostring(skinId)]
	return string.format('cards/head/card_icon_%s.png', tostring(skinConfig.drawId))
end
--[[
根据皮肤id获取卡牌专有背景路径
@params skinId int 皮肤id
--]]
function DebugCardResourceScene:GetCardBgPathBySkinId(skinId)
	local skinconfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('goods', 'cardSkin'))
	if skinId > 259000 then
		skinconfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('monster', 'monsterSkin'))
	end
	local skinConfig = skinconfigtable[tostring(skinId)]
	return string.format('cards/card/card_draw_bg_%s.jpg', tostring(skinConfig.drawBackGroundId))
end
--[[
根据皮肤id获取卡牌专有前景路径
@params skinId int 皮肤id
--]]
function DebugCardResourceScene:GetCardFgPathBySkinId(skinId)
	local skinconfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('goods', 'cardSkin'))
	if skinId > 259000 then
		skinconfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('monster', 'monsterSkin'))
	end
	local skinConfig = skinconfigtable[tostring(skinId)]
	return string.format('cards/card/card_draw_fg_%s.png', tostring(skinConfig.drawBackGroundId))
end
--[[
根据皮肤id获取卡牌spine小人路径前缀
@params skinId int 皮肤id
--]]
function DebugCardResourceScene:GetCardSpinePathBySkinId(skinId)
	local skinconfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('goods', 'cardSkin'))
	if skinId > 259000 then
		skinconfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('monster', 'monsterSkin'))
	end
	local skinConfig = skinconfigtable[tostring(skinId)]
	return string.format('cards/spine/avatar/%s', tostring(skinConfig.spineId))
end






--[[
修改所有spine文件后缀规则
--]]
function DebugCardResourceScene:DebugRewriteSpineFiles()
	local rewriteBtn = display.newButton(0, 0, {n = 'ui/common/common_btn_orange.png', cb = function (sender)
		print('>>>>>>>>>>>>>>>>>>>>>>>>> here start rewrite spine files <<<<<<<<<<<<<<<<<<<<<')

		local lfs = require('lfs')
		local folderPath = 'res/debugspine'
		local debugfiles = {}


		for file in lfs.dir(folderPath) do
			if nil ~= string.find(tostring(file), '.json') then
				local name = string.split(file, '.')[1]
				table.insert(debugfiles, name)
			end
		end

		local atlasPath = nil
		local atlasfile = nil
		local pngPath = nil
		local pngfile
		local itor = nil

		for i,v in ipairs(debugfiles) do
			itor = 1
			atlasPath = folderPath .. '/' .. tostring(v) .. '.atlas'

			pngPath = folderPath .. '/' .. tostring(v) .. '.png'
			pngfile = io.open(pngPath, 'rb')

			local changedpngname = {}

			while nil ~= pngfile do
				pngfile:close()

				local oldpngname = string.split(pngPath, '/')[#string.split(pngPath, '/')]
				local newpngname = v .. '_p' .. tostring(itor) .. '.png'

				-- print(oldpngname, newpngname)

				-- 修改png文件名
				local newpngpath = string.gsub(pngPath, oldpngname, newpngname)
				print(newpngpath)
				local r, e = os.rename(pngPath, newpngpath)

				table.insert(changedpngname, {oldpngname = oldpngname, newpngname = newpngname})

				itor = itor + 1
				pngPath = folderPath .. '/' .. tostring(v) .. '_' .. tostring(itor) .. '.png'
				pngfile = io.open(pngPath, 'rb')
			end

			-- 修改atlas文件
			local atlasFile = io.open(atlasPath, 'r')
			local atlasData = tostring(atlasFile:read('*a'))
			atlasFile:close()

			for i,v in ipairs(changedpngname) do
				atlasData = string.gsub(atlasData, v.oldpngname, v.newpngname)
			end

			local atlasFile = io.open(atlasPath, 'w')
			atlasFile:write(atlasData)
			atlasFile:close()

		end

		print('>>>>>>>>>>>>>>>>>>>>>>>>> here end rewrite spine files <<<<<<<<<<<<<<<<<<<<<')
	end})
	display.commonLabelParams(rewriteBtn, {text = __('修改spine'), fontSize = 20, color = '#ffffff'})
	display.commonUIParams(rewriteBtn, {po = cc.p(rewriteBtn:getContentSize().width * 0.5, display.height - rewriteBtn:getContentSize().height * 0.5)})
	self:addChild(rewriteBtn, 99999)
end
--[[
根据玩家等级检测需要的关卡相关资源
@params level int 玩家等级
--]]
function DebugCardResourceScene:DebugNecessaryQuestResByPlayerLevel(level)
	local mainQuests = {}
	local plotQuests = {}
	local resturantQuests = {}
	local materialQuests = {}

	---------- 过滤能打的主线关卡 ----------
	-- 遍历章节信息
	local cityconfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('quest', 'city'))
	local sk = sortByKey(cityconfigtable)
	for _, key in ipairs(sk) do
		local cityId = checkint(key)
		local cityConfig = cityconfigtable[key]
		for d, unlockInfo in pairs(cityConfig.unlock) do
			local unlockLevel = checkint(unlockInfo[1])
			if unlockLevel <= level then
				local questsInfo = cityConfig.quests[tostring(d)]
				if nil ~= questsInfo then
					for _, questId in ipairs(questsInfo) do
						table.insert(mainQuests, checkint(questId))
					end
				end
			end
		end
	end
	---------- 过滤能打的主线关卡 ----------
	-- dump(mainQuests)

	---------- 过滤能打的剧情任务关卡 ----------
	-- 遍历剧情任务信息
	local battleQuestPlotType = {
		['4'] = true,
		['13'] = true,
		['14'] = true
	}
	local questplotconfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('quest', 'questPlot'))
	sk = sortByKey(questplotconfigtable)
	for _, key in ipairs(sk) do
		local questPlotId = checkint(key)
		local questPlotConfig = questplotconfigtable[key]
		if true == battleQuestPlotType[tostring(questPlotConfig.taskType)] then
			if nil ~= questPlotConfig.unlockType[tostring(1)] then
				unlockLevel = checkint(questPlotConfig.unlockType[tostring(1)].targetNum)
				if unlockLevel <= level then
					local questId = checkint(questPlotConfig.target.targetId[1])
					table.insert(plotQuests, questId)
				end
			end
		end
	end
	---------- 过滤能打的剧情任务关卡 ----------
	-- dump(plotQuests)

	---------- 过滤能打的霸王餐关卡 ----------
	-- 缺少用于判断的字段 直接人肉写死...
	resturantQuests = {
		6001,
		6002,
		6003,
		6004,
		6101,
		6102,
		6103
	}
	---------- 过滤能打的霸王餐关卡 ----------
	-- dump(resturantQuests)

	---------- 材料本关卡id ----------
	local unlockMQuestType = {}
	local materialquesttypeconfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('materialQuest', 'questType'))
	for k, v in pairs(materialquesttypeconfigtable) do
		if checkint(v.unlockLevel) <= level then
			unlockMQuestType[tostring(v.id)] = true
		end
	end
	local materialquestconfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('materialQuest', 'quest'))
	sk = sortByKey(materialquestconfigtable)
	for _, key in ipairs(sk) do
		local questId = checkint(key)
		local questConfig = materialquestconfigtable[key]
		if true == unlockMQuestType[tostring(questConfig.type)] then
			table.insert(materialQuests, questId)
		end
	end
	---------- 材料本关卡id ----------
	-- dump(materialQuests)

	---------- 根据关卡id获取用到的怪物id ----------
	local usedMonsterIds = {}
	local usedMonsterIds_ = {}
	local enemyconfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('quest', 'enemy'))

	local questsInfos = {
		mainQuests,
		plotQuests,
		resturantQuests,
		materialQuests
	}
	for _, quests in ipairs(questsInfos) do
		for _, questId in ipairs(quests) do
			local enemyConfig = enemyconfigtable[tostring(questId)]
			if nil ~= enemyConfig then
				for wave, waveInfo in pairs(enemyConfig) do
					for _, monsterInfo in ipairs(waveInfo.npc) do
						usedMonsterIds_[checkint(monsterInfo.npcId)] = true
					end
				end
			end
		end
	end

	for k,v in pairs(usedMonsterIds_) do
		table.insert(usedMonsterIds, k)
	end
	table.sort(usedMonsterIds, function (a, b)
		return a <= b
	end)
	---------- 根据关卡id获取用到的怪物id ----------
	-- dump(usedMonsterIds)

	---------- 根据用到的怪物id获取对应的皮肤id ----------
	local usedMonsterSkinIds = {}
	local monsterconfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('monster', 'monster'))
	local monsterskinconfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('monster', 'monsterSkin'))

	for _, monsterId in ipairs(usedMonsterIds) do
		local monsterConfig = monsterconfigtable[tostring(monsterId)]
		if nil ~= monsterConfig then
			local skinId = checkint(monsterConfig.skinId)
			local skinConfig = monsterskinconfigtable[tostring(skinId)]
			if nil ~= skinConfig then
				table.insert(usedMonsterSkinIds, skinId)
			end
		end
	end
	---------- 根据用到的怪物id获取对应的皮肤id ----------
	-- dump(usedMonsterSkinIds)

	---------- 根据皮肤信息输出需要的avatar spine ----------
	local monsterCommonRes = {
		draws = {},
		heads = {},
		spines = {}
	}
	for _, skinId in ipairs(usedMonsterSkinIds) do
		local skinConfig = monsterskinconfigtable[tostring(skinId)]

		table.insert(monsterCommonRes.draws, skinConfig.drawId)
		table.insert(monsterCommonRes.heads, skinConfig.drawId)
		table.insert(monsterCommonRes.spines, skinConfig.spineId)
	end

	-- 排序
	for _,v in pairs(monsterCommonRes) do
		table.sort(v, function (a, b)
			-- local aid = nil
			-- if nil ~= string.find(a, '_') then
			-- 	aid = checkint(string.split(a, '_')[1])
			-- else
			-- 	aid = checkint(a)
			-- end

			-- local bid = nil
			-- if nil ~= string.find(b, '_') then
			-- 	bid = checkint(string.split(b, '_')[1])
			-- else
			-- 	bid = checkint(b)
			-- end

			return checkint(a) < checkint(b)
		end)
	end
	---------- 根据皮肤信息输出需要的avatar spine ----------

	---------- 获取主线需要的其他资源 ----------
	local mainquestconfigtable = self:ConvertJsonToLuaByFilePath(self:GetConfigPath('quest', 'quest'))
	-- 战斗地图
	local mainQuestsBattleBg_ = {}
	local mainQuestsBattleBg = {}
	-- 章节背景图
	local mainQuestsCityBg_ = {}
	local mainQuestsCityBg = {}
	-- 节点小人资源id
	local mainQuestStageNodeCartoon_ = {}
	local mainQuestStageNodeCartoon = {}
	for _, questId in ipairs(mainQuests) do
		local questConfig = mainquestconfigtable[tostring(questId)]
		if nil ~= questConfig then
			-- 战斗地图
			mainQuestsBattleBg_[checkint(questConfig.backgroundId)] = true
			-- 节点小人
			local iconMonsterId = checkint(string.split(questConfig.icon, ';')[1])
			local iconMonsterConfig = monsterconfigtable[tostring(iconMonsterId)]
			if nil ~= iconMonsterConfig then
				local cartoonId = checkint(iconMonsterConfig.drawId)
				mainQuestStageNodeCartoon_[cartoonId] = true
			end
			-- 章节背景图
			local cityId = checkint(questConfig.cityId)
			local cityConfig = cityconfigtable[tostring(cityId)]
			if nil ~= cityConfig then
				local cityBgId = checkint(cityConfig.backgroundId[tostring(questConfig.difficulty)])
				mainQuestsCityBg_[cityBgId] = true
			end
		end
	end

	for _, questInfos in pairs(questsInfos) do
		for _, questId in ipairs(questInfos) do
			local questConfig = CommonUtils.GetQuestConf(questId)
			if nil ~= questConfig then
				-- 战斗地图
				mainQuestsBattleBg_[checkint(questConfig.backgroundId)] = true
			end
		end
	end

	-- 排序
	local t__ = {
		{input = mainQuestsBattleBg_, output = mainQuestsBattleBg},
		{input = mainQuestsCityBg_, output = mainQuestsCityBg},
		{input = mainQuestStageNodeCartoon_, output = mainQuestStageNodeCartoon}
	}
	for _,a in ipairs(t__) do
		for k,_ in pairs(a.input) do
			table.insert(a.output, k)
		end
		table.sort(a.output, function (x, y)
			return x <= y
		end)
	end
	---------- 获取主线需要的其他资源 ----------


	print('\n\n--------------------\ncards/card\n--------------------\n\n')
	dump(monsterCommonRes.draws)


	print('\n\n--------------------\ncards/head\n--------------------\n\n')
	dump(monsterCommonRes.heads)


	print('\n\n--------------------\ncards/spine/avatar\n--------------------\n\n')
	dump(monsterCommonRes.spines)


	print('\n\n--------------------\narts/cartoon\n--------------------\n\n')
	dump(mainQuestStageNodeCartoon)


	print('\n\n--------------------\narts/maps\n--------------------\n\n')
	dump(mainQuestsCityBg)


	print('\n\n--------------------\nbattle/map\n--------------------\n\n')
	dump(mainQuestsBattleBg)


end


--[[
获取排序后的动画动作名列表
@params animationsData map
@params reverse bool 是否是倒序
@return anis list 动作名列表
--]]
function DebugCardResourceScene:GetSortAnimationsName(animationsData, reverse)
	local anis = {}
	for k,v in pairs(animationsData) do
		if true == reverse then
			table.insert(anis, 1, k)
		else
			table.insert(anis, k)
		end
	end
	return anis
end






















return DebugCardResourceScene
