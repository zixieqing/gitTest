--[[
    召回分享界面
--]]
local CommonShareFrameLayer = require('Game.views.share.CommonShareFrameLayer')
local RecallShareLayer = class('RecallShareLayer', CommonShareFrameLayer)

------------ import ------------
local dataMgr = AppFacade.GetInstance():GetManager("DataManager")
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
---@type CardManager
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
------------ import ------------

------------ define ------------
------------ define ------------
local function GetFullPath( imgName )
	return _res('ui/home/recall/' .. imgName)
end
--[[
@override
constructor
--]]
function RecallShareLayer:ctor(...)
	local args = unpack({...})
	self.inviteCode = args.inviteCode
	CommonShareFrameLayer.ctor(self, {type = SHARE_TEXT_TYPE.RECALL})

	local ShareNode = self:getChildByName('ShareNode')
	local logoImage = ShareNode.viewData.logoImage
	logoImage:setPosition(cc.p(display.width - 180 - display.SAFE_L, display.height - 120))

end
---------------------------------------------------
-- init begin --
---------------------------------------------------
--[[
@overr
初始化ui
--]]
function RecallShareLayer:InitUI()
	local function CreateView()
		local view = CLayout:create(display.size)
		self:addChild(view, 1)
		view:setPosition(display.center)

		-- 背景
		local bg = display.newImageView(GetFullPath('recall_share_bg'), display.cx, display.cy)
		view:addChild(bg, 2)

		local desrBg = display.newImageView(GetFullPath('recall_share_bg_words'), display.width - 174 - 90 - display.SAFE_L, display.height - 400, {scale9 = true, size = cc.size(503, 412), capInsets = cc.rect(50, 50, 220, 312)})
		view:addChild(desrBg, 2)
		
		local richLabel = display.newRichLabel(display.width - 182 - display.SAFE_L, display.height - 225,
			{w = 25, ap = display.CENTER_TOP, sp = 6})
		view:addChild(richLabel, 10)
		richLabel:setVisible(false)
		local ContentLabel = display.newLabel(display.width - 182 - 80 - display.SAFE_L, display.height - 225,
			{text = '', fontSize = 24, color = 'ffffff', w = 480, ap = display.CENTER_TOP})
		view:addChild(ContentLabel, 10)
		
		local inviteCodeTitleLabel = display.newLabel(display.width - 330 - 90 - display.SAFE_L, display.height - 580, {ap = display.LEFT_CENTER ,  text = __('召回码：'), font = TTF_GAME_FONT, ttf = true, fontSize = 30, color = 'ffffff'})
		view:addChild(inviteCodeTitleLabel, 10)
		
		local inviteCodeLabel = display.newLabel(display.width - 180 - display.SAFE_L, display.height - 540, {ap = display.LEFT_CENTER, text = '', font = TTF_GAME_FONT, ttf = true, fontSize = 30, color = 'ffffff'})
		view:addChild(inviteCodeLabel, 10)

		return {
			view                 = view,
			richLabel            = richLabel,
			ContentLabel         = ContentLabel,
			inviteCodeTitleLabel = inviteCodeTitleLabel,
			--inviteCodeLabel		= inviteCodeLabel,
		}
	end

	xTry(function ( )
		self.viewData = CreateView()
		display.commonLabelParams(self.viewData.inviteCodeTitleLabel , {text = __('召回码：')  .. (self.inviteCode or "") , reqW = 400 })

		-- local day = math.floor(checkint(getServerTime() - gameMgr:GetUserInfo().roleCtime)/86400)
		-- display.reloadRichLabel(self.viewData.richLabel,{w = 25, ap = display.CENTER_TOP, sp = 6, c = {
		-- 		{text = __('食之契约周年庆\n\n御侍大人！我们都在等您！食之契约周年庆&老玩家召回多重福利正在派送！灵火种、调味料、各种珍贵道具拿不停！更有UR飨灵供您选择！这个周年庆，注定不平凡，我们在这里等你！'), fontSize = 24, color = 'ffffff'},
		-- 	}
		-- })
		self.viewData.ContentLabel:setString(__('食之契约全新版本\n\n御侍大人！剧情全部重置！全新表现形式！新增Live2D！各种回归福利免费拿！更有小樱联动，全新活动，等着你！！'))
	end, __G__TRACKBACK__)

end
---------------------------------------------------
-- init end --
---------------------------------------------------

return RecallShareLayer