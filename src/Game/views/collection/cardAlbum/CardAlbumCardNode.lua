--[[
 * author : liuzhipeng
 * descpt : 图鉴 飨灵收集册 卡牌node
--]]
local CardAlbumCardNode = class('CardAlbumCardNode', function ()
    local node = CLayout:create()
    node.name = 'CardAlbumCardNode'
    node:enableNodeEvents()
    return node
end)
local NODE_SIZE = cc.size(270,284)
local RES_DICT = {
    CARD_BG_M          = _res('ui/collection/cardAlbum/collect_role_frame_m.png'),
    CARD_BG_R          = _res('ui/collection/cardAlbum/collect_role_frame_r.png'),
    CARD_BG_SR         = _res('ui/collection/cardAlbum/collect_role_frame_sr.png'),
    CARD_BG_UR         = _res('ui/collection/cardAlbum/collect_role_frame_ur.png'),
    CARD_BG_SP         = _res('ui/collection/cardAlbum/collect_role_frame_sp.png'),
    NAME_BG            = _res('ui/collection/cardAlbum/collect_role_frame_slogan.png'),
    ACTIFACT_ICON_MASK = _res('ui/collection/cardAlbum/collect_power_lock_ico.png'),
    LOCK_ICON          = _res('ui/common/common_ico_lock.png'),
    GAIN_BG            = _res('ui/collection/cardAlbum/collect_role_gain'),

}
local CARD_BG_PATH_MAP = {
	['1'] = RES_DICT.CARD_BG_M,
	['2'] = RES_DICT.CARD_BG_R,
	['3'] = RES_DICT.CARD_BG_SR,
	['4'] = RES_DICT.CARD_BG_UR,
	['5'] = RES_DICT.CARD_BG_SP,
}
--[[
@params cardId int 卡牌id
--]]
function CardAlbumCardNode:ctor( params )
    self:InitUI()
    self:RefreshNode(params)
end
--[[
init ui
--]]
function CardAlbumCardNode:InitUI()
    local function CreateView()
        local size = NODE_SIZE
        local view = CLayout:create(size)
        -- 名称
        local cardNameBg = display.newImageView(RES_DICT.NAME_BG, size.width / 2, 5, {ap = display.CENTER_BOTTOM})
        view:addChild(cardNameBg, 1)
        local cardNameLabel = display.newLabel(cardNameBg:getContentSize().width / 2, cardNameBg:getContentSize().height / 2, {text = '', fontSize = 24, color = '#FFFFFF', ttf = true, font = TTF_GAME_FONT, outline = '#5C3F30', outlineSize = 2})
        cardNameBg:addChild(cardNameLabel, 1)
        -- 背景
        local bg = display.newButton(size.width / 2, size.height / 2 + 10, {n = 'empty', size = cc.size(218, 218), useS = false})
        view:addChild(bg, 1)
        local bgFrame = FilteredSpriteWithOne:create(RES_DICT.CARD_BG_M)
        bgFrame:setPosition(cc.p(size.width / 2, size.height / 2 + 10))
		view:addChild(bgFrame, 1)
        -- 卡牌头像
		local cardIcon = FilteredSpriteWithOne:create()
        cardIcon:setPosition(cc.p(size.width / 2, size.height / 2 + 12))
        cardIcon:setScale(1.17)
		view:addChild(cardIcon, 1)
        -- 品质
		local qualityIcon = FilteredSpriteWithOne:create(CardUtils.GetCardQualityTextPathByCardId(CardUtils.DEFAULT_CARD_ID))
		qualityIcon:setAnchorPoint(display.RIGHT_CENTER)
        qualityIcon:setPosition(cc.p(size.width - 12, size.height - 36))
        qualityIcon:setScale(0.45)
        view:addChild(qualityIcon, 3)
        -- 等级
		local levelBg = FilteredSpriteWithOne:create()
		levelBg:setCascadeOpacityEnabled(true)
		levelBg:setSpriteFrame(basename(_res('ui/cards/head/kapai_zhiye_colour.png')))
		levelBg:setAnchorPoint(cc.p(0.5, 1))
		levelBg:setPosition(cc.p(60, size.height - 15))
		view:addChild(levelBg, 3)
		local levelLabel = display.newLabel(levelBg:getContentSize().width / 2, levelBg:getContentSize().height / 2 + 8, fontWithColor(9, {text = ''}))
		levelBg:addChild(levelLabel, 5)
		-- 职业
		local careerBg = FilteredSpriteWithOne:create()
		app.plistMgr:SetSpriteFrame(careerBg , basename(CardUtils.GetCardCareerIconFramePathByCardId(CardUtils.DEFAULT_CARD_ID)))
		careerBg:setPosition(cc.p(utils.getLocalCenter(levelBg).x + 1, 7))
		levelBg:addChild(careerBg)
		careerBg:setCascadeOpacityEnabled(true)
		local careerIcon = FilteredSpriteWithOne:create()
		app.plistMgr:SetSpriteFrame(careerIcon ,  basename(CardUtils.GetCardCareerIconPathByCardId(CardUtils.DEFAULT_CARD_ID)))
		careerIcon:setScale(0.65)
		careerIcon:setPosition(cc.p(utils.getLocalCenter(careerBg).x, utils.getLocalCenter(careerBg).y + 2))
        careerBg:addChild(careerIcon)
        -- 星级
        local psStarAnchorPos = cc.p(19, 29)
        local stars = {}
        for i = 1, 5 do
            local star = FilteredSpriteWithOne:create()
            star:setSpriteFrame(basename(_res('ui/cards/head/kapai_star_colour.png')))
            star:setScale(0.85 + 0.05 * i)
            star:setAnchorPoint(cc.p(psStarAnchorPos.x / star:getContentSize().width, (star:getContentSize().height - psStarAnchorPos.y) / star:getContentSize().height))
            star:setPosition(cc.p(45 + (i - 1) * 16, 48))
            view:addChild(star, 10 - i)
            table.insert(stars, star)
        end
        -- 神器
        local artifactIconPath = CommonUtils.GetArtifiactPthByCardId(CardUtils.DEFAULT_CARD_ID)
        local artifactIcon =  FilteredSpriteWithOne:create(artifactIconPath)
        artifactIcon:setPosition(cc.p(size.width - 50, 70))
        view:addChild(artifactIcon, 5)
        artifactIcon:setScale(0.3)
        local artifactIconMask = display.newImageView(RES_DICT.ACTIFACT_ICON_MASK, size.width - 50, 70)
        view:addChild(artifactIconMask, 5)
        local lockIcon = display.newImageView(RES_DICT.LOCK_ICON, artifactIconMask:getContentSize().width / 2, artifactIconMask:getContentSize().height / 2)
        lockIcon:setScale(0.7)
        artifactIconMask:addChild(lockIcon, 1)
        -- 获取
        local gainBg = display.newImageView(RES_DICT.GAIN_BG, size.width / 2, size.height / 2 + 10)
        view:addChild(gainBg, 10)
        local gainLabel = display.newLabel(gainBg:getContentSize().width / 2, gainBg:getContentSize().height / 2, {text = __('获取'), fontSize = 30, color = '#361607', ttf = true, font = TTF_GAME_FONT})
        gainBg:addChild(gainLabel, 1)
        return {
            view                = view,
            cardNameLabel       = cardNameLabel,
            bg                  = bg,
            bgFrame             = bgFrame,
            cardIcon            = cardIcon,
            qualityIcon         = qualityIcon,
            levelBg             = levelBg,
            levelLabel          = levelLabel,
            careerIcon          = careerIcon,
            stars               = stars,
            artifactIcon        = artifactIcon,
            artifactIconMask    = artifactIconMask,
            gainBg              = gainBg,
            careerBg            = careerBg,
        }
    end
    xTry(function ( )
        self:setContentSize(NODE_SIZE)
        self.viewData = CreateView( )
        self.viewData.view:setPosition(cc.p(NODE_SIZE.width / 2, NODE_SIZE.height / 2))
        self.viewData.bg:setOnClickScriptHandler(handler(self, self.BgBtnCallback))
        self:addChild(self.viewData.view)
    end, __G__TRACKBACK__)
end
--[[
刷新node
--]]
function CardAlbumCardNode:RefreshNode( params )
    local cardId = checkint(checktable(params).cardId or CardUtils.DEFAULT_CARD_ID)
    local viewData = self:GetViewData()
    local cardData = app.gameMgr:GetCardDataByCardId(cardId)
    local cardConf = CardUtils.GetCardConfig(cardId) or {}
    self.cardId = cardId

    viewData.cardNameLabel:setString(cardConf.name)
    viewData.bgFrame:setTexture(CARD_BG_PATH_MAP[tostring(cardConf.qualityId)])
    viewData.cardIcon:setTexture(CardUtils.GetCardHeadPathByCardId(cardId))
    viewData.qualityIcon:setTexture(CardUtils.GetCardQualityTextPathByCardId(cardId))
    viewData.careerIcon:setTexture(CardUtils.GetCardCareerIconPathByCardId(cardId))
    -- 神器
    if checkint(cardConf.artifactStatus) > 0 then
        -- 该卡牌拥有神器
        viewData.artifactIcon:setTexture(CommonUtils.GetArtifiactPthByCardId(cardId))
        viewData.artifactIcon:setVisible(true)
        viewData.artifactIconMask:setVisible(cardData and checkint(cardData.isArtifactUnlock) == 0)
    else
        -- 该卡牌未拥有神器
        viewData.artifactIcon:setVisible(false)
        viewData.artifactIconMask:setVisible(false)
    end
    for i, v in ipairs(checktable(self.stars)) do
        v:removeFromParent()
    end
    if cardData then
        -- 拥有卡牌
        viewData.levelBg:setVisible(true)
        viewData.gainBg:setVisible(false)
        viewData.levelLabel:setString(cardData.level)
        -- 突破星级
        local starAmount = app.cardMgr.GetCardStar(cardId, {breakLevel = cardData.breakLevel})
        for i, v in ipairs(viewData.stars) do
            v:setVisible(i <= starAmount)
        end
        self:SetGray(false)
    else
        -- 未拥有卡牌
        viewData.levelBg:setVisible(false)
        viewData.gainBg:setVisible(true)
        for i, v in ipairs(viewData.stars) do
            v:setVisible(false)
        end
        self:SetGray(true)
    end
end
--[[
背景按钮点击回调
--]]
function CardAlbumCardNode:BgBtnCallback( sender )
    PlayAudioByClickNormal()
    local cardData = app.gameMgr:GetCardDataByCardId(self.cardId)
    if cardData then
        -- 拥有卡牌
        local cardPreviewView = require('common.CardPreviewView').new({
            confId = self.cardId
        })
        display.commonUIParams(cardPreviewView, {ap = display.CENTER, po = display.center})
        app.uiMgr:GetCurrentScene():AddDialog(cardPreviewView)
    else
        -- 未拥有卡牌
        app.uiMgr:AddDialog("common.GainPopup", {goodId = self.cardId})
    end
end
--[[
灰化
@params isGray bool 是否灰化
--]]
function CardAlbumCardNode:SetGray( isGray )
	if isGray then
		if nil == self.grayFilter then
			self.grayFilter = GrayFilter:create()
		end
		-- 逐个子节点设置灰化
		self.viewData.bgFrame:setFilter(self.grayFilter)
		self.viewData.cardIcon:setFilter(self.grayFilter)
		self.viewData.levelBg:setFilter(self.grayFilter)
		self.viewData.careerBg:setFilter(self.grayFilter)
        self.viewData.careerIcon:setFilter(self.grayFilter)
        self.viewData.qualityIcon:setFilter(self.grayFilter)
        self.viewData.artifactIcon:setFilter(self.grayFilter)
	else
		-- 逐个子节点清除灰化
		self.viewData.bgFrame:clearFilter()
		self.viewData.cardIcon:clearFilter()
		self.viewData.levelBg:clearFilter()
		self.viewData.careerBg:clearFilter()
        self.viewData.careerIcon:clearFilter()
        self.viewData.qualityIcon:clearFilter()
        self.viewData.artifactIcon:clearFilter()
		self.grayFilter = nil 
	end
end
--[[
获取viewData
--]]
function CardAlbumCardNode:GetViewData()
    return self.viewData
end
return CardAlbumCardNode