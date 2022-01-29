local GameScene = require( "Frame.GameScene" )
---@class Anniversary19SuppressFilterView : GameScene
local Anniversary19SuppressFilterView = class("Anniversary19SuppressFilterView", GameScene)

local RES_DICT = {
    COMMON_BG_4                             = app.anniversary2019Mgr:GetResPath('ui/common/common_bg_4.png'),
    COMMON_BG_CLOSE                         = app.anniversary2019Mgr:GetResPath('ui/common/common_bg_close.png'),
    COMMON_BTN_ORANGE                       = app.anniversary2019Mgr:GetResPath('ui/common/common_btn_orange.png'),
    COMMON_TITLE_5                          = app.anniversary2019Mgr:GetResPath('ui/common/common_title_5.png'),
    WONDERLAND_BATTLE_BG_CHOICE_DEFAULT     = app.anniversary2019Mgr:GetResPath('ui/anniversary19/wonderland/wonderland_battle_bg_choice_default.png'),
    WONDERLAND_BATTLE_BG_CHOICE_SELECTED    = app.anniversary2019Mgr:GetResPath('ui/anniversary19/wonderland/wonderland_battle_bg_choice_selected.png'),
    WONDERLAND_BATTLE_BG_LEVEL_DEFAULT      = app.anniversary2019Mgr:GetResPath('ui/anniversary19/wonderland/wonderland_battle_bg_level_default.png'),
    WONDERLAND_BATTLE_BG_LEVEL_SELECTED     = app.anniversary2019Mgr:GetResPath('ui/anniversary19/wonderland/wonderland_battle_bg_level_selected.png'),
    WONDERLAND_ICO_LINE_2                   = app.anniversary2019Mgr:GetResPath('ui/anniversary19/wonderland/wonderland_ico_line_2.png'),
}

function Anniversary19SuppressFilterView:ctor( ... )
	GameScene.ctor(self, 'Game.views.anniversary19.Anniversary19SuppressFilterView')
	self.args = unpack({...}) or {}

	self:InitUI()
end

function Anniversary19SuppressFilterView:InitUI()
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 180))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    eaterLayer:setOnClickScriptHandler(function()
        app:UnRegsitMediator("Anniversary19SuppressFilterMediator")
    end)
    
	local function CreateView()
        local view = CLayout:create(display.size)
        display.commonUIParams(view, {po = display.center})
        self:addChild(view)

        local BG = display.newImageView(RES_DICT.COMMON_BG_4, display.cx - -54, display.cy - 1,
        {
            ap = display.CENTER,
            scale9 = true, size = cc.size(830, 580),
            enable = true,
        })
        view:addChild(BG)

        local ownerType = display.newButton(display.cx - -54, display.cy - -245,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_TITLE_5,
            scale9 = true, size = cc.size(186, 31),
            enable = false,
        })
        display.commonLabelParams(ownerType, {text = app.anniversary2019Mgr:GetPoText(__('提供者类型')), fontSize = 22, color = '#7e2b1a', paddingW = 33, safeW = 120})
        view:addChild(ownerType)

        local bossType = display.newButton(display.cx - -54, display.cy - -89,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_TITLE_5,
            scale9 = true, size = cc.size(186, 31),
            enable = false,
        })
        display.commonLabelParams(bossType, {text = app.anniversary2019Mgr:GetPoText(__('BOSS种类')), fontSize = 22, color = '#7e2b1a', paddingW = 33, safeW = 120})
        view:addChild(bossType)

        local bossLevel = display.newButton(display.cx - -54, display.cy - 63,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_TITLE_5,
            scale9 = true, size = cc.size(186, 31),
            enable = false,
        })
        display.commonLabelParams(bossLevel, {text = app.anniversary2019Mgr:GetPoText(__('BOSS等级')), fontSize = 22, color = '#7e2b1a', paddingW = 33, safeW = 120})
        view:addChild(bossLevel)
        local toggleSize =  cc.size(200,60)
        local guild = display.newToggleView(display.cx - 141-40, display.cy - -183,
        {
            ap = display.CENTER,
            n = RES_DICT.WONDERLAND_BATTLE_BG_CHOICE_DEFAULT,
            s = RES_DICT.WONDERLAND_BATTLE_BG_CHOICE_SELECTED,
            scale9=true, size =toggleSize ,
            enable = true,
        })
        display.commonLabelParams(guild, fontWithColor(14, {text = app.anniversary2019Mgr:GetPoText(__('工会提供')), fontSize = 24, color = '#ffffff'}))
        guild:setTag(1)
        view:addChild(guild)

        local friend = display.newToggleView(display.cx - -54, display.cy - -183,
        {
            ap = display.CENTER,
            n = RES_DICT.WONDERLAND_BATTLE_BG_CHOICE_DEFAULT,
            s = RES_DICT.WONDERLAND_BATTLE_BG_CHOICE_SELECTED,
            scale9=true, size =toggleSize ,
            enable = true,
        })
        display.commonLabelParams(friend, fontWithColor(14, {text = app.anniversary2019Mgr:GetPoText(__('好友提供')),  scale9=true, size =toggleSize ,fontSize = 24, color = '#ffffff'}))
        friend:setTag(2)
        view:addChild(friend)

        local total = display.newToggleView(display.cx - -250+40, display.cy - -183,
        {
            ap = display.CENTER,
            n = RES_DICT.WONDERLAND_BATTLE_BG_CHOICE_DEFAULT,
            s = RES_DICT.WONDERLAND_BATTLE_BG_CHOICE_SELECTED,
            scale9=true, size =toggleSize ,
            enable = true,
        })
        display.commonLabelParams(total, fontWithColor(14, {text = app.anniversary2019Mgr:GetPoText(__('所有')),  scale9=true, size =toggleSize ,fontSize = 24, color = '#ffffff'}))
        total:setTag(3)
        total:setChecked(true)
        view:addChild(total)

        local Image_2 = display.newImageView(RES_DICT.WONDERLAND_ICO_LINE_2, display.cx - -54, display.cy - -127,
        {
            ap = display.CENTER,
        })
        view:addChild(Image_2)

        local Image_2_0 = display.newImageView(RES_DICT.WONDERLAND_ICO_LINE_2, display.cx - -54, display.cy - 39,
        {
            ap = display.CENTER,
        })
        view:addChild(Image_2_0)

        local confirmBtn = display.newButton(display.cx - -54, display.cy - 227,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_ORANGE,
            scale9 = true, size = cc.size(123, 62),
            enable = true,
        })
        display.commonLabelParams(confirmBtn, fontWithColor(14, {text = app.anniversary2019Mgr:GetPoText(__('确认'))}))
        view:addChild(confirmBtn)
        local maxLevel = 5
        local changeSkinData = app.anniversary2019Mgr:GetChangeSkinData()
        local bossCountLevel = changeSkinData.bossCountLevel or maxLevel
        local offwidth = ((maxLevel  - bossCountLevel)/2 ) * 80
        local levelToggles = {}
        for i = 1, bossCountLevel do
            local levelToggle = display.newToggleView(display.cx - 385 + 200 + 80 * i + offwidth, display.cy - 122,
            {
                ap = display.CENTER,
                n = RES_DICT.WONDERLAND_BATTLE_BG_LEVEL_DEFAULT,
                s = RES_DICT.WONDERLAND_BATTLE_BG_LEVEL_SELECTED,
                enable = true,
            })
            display.commonLabelParams(levelToggle, {text = i, fontSize = 46, color = '#ffffff'})
            levelToggle:setTag(i)
            view:addChild(levelToggle)
            levelToggles[i] = levelToggle
        end

        local closeLabel = display.newButton(display.cx - -54, display.cy - 306,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BG_CLOSE,
            scale9 = true, size = cc.size(210, 26),
            enable = false,
        })
        display.commonLabelParams(closeLabel, {text = app.anniversary2019Mgr:GetPoText(__('点击空白处关闭')), fontSize = 18, color = '#ffffff', paddingW = 40, safeW = 130, offset = cc.p(0, 2)})
        view:addChild(closeLabel)

        return {
            view                    = view,
            BG                      = BG,
            ownerType               = ownerType,
            bossType                = bossType,
            bossLevel               = bossLevel,
            guild                   = guild,
            friend                  = friend,
            total                   = total,
            Image_2                 = Image_2,
            Image_2_0               = Image_2_0,
            confirmBtn              = confirmBtn,
            levelToggles            = levelToggles,
        }
    end
	xTry(function ( )
        self.viewData = CreateView()
	end, __G__TRACKBACK__)
end

return Anniversary19SuppressFilterView
