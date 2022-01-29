local GameScene = require( "Frame.GameScene" )
---@class Anniversary19SuppressRewardPreviewView : GameScene
local Anniversary19SuppressRewardPreviewView = class("Anniversary19SuppressRewardPreviewView", GameScene)

local RES_DICT = {
    COMMON_BG_2                     = app.anniversary2019Mgr:GetResPath('ui/common/common_bg_2.png'),
    COMMON_BG_CLOSE                 = app.anniversary2019Mgr:GetResPath('ui/common/common_bg_close.png'),
    COMMON_BG_GOODS                 = app.anniversary2019Mgr:GetResPath('ui/common/common_bg_goods.png'),
    COMMON_BG_TITLE_2               = app.anniversary2019Mgr:GetResPath('ui/common/common_bg_title_2.png'),
    WONDERLAND_BG_TITLE_PRIZE       = app.anniversary2019Mgr:GetResPath('ui/anniversary19/wonderland/wonderland_bg_title_prize.png'),
    WONDERLAND_ICO_SHARE_LINE       = app.anniversary2019Mgr:GetResPath('ui/anniversary19/wonderland/wonderland_ico_share_line.png'),
}

function Anniversary19SuppressRewardPreviewView:ctor( ... )
	GameScene.ctor(self, 'Game.views.anniversary19.Anniversary19SuppressRewardPreviewView')
	self.args = unpack({...}) or {}

	self:InitUI()
end

function Anniversary19SuppressRewardPreviewView:InitUI()
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 180))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    eaterLayer:setOnClickScriptHandler(function()
        app:UnRegsitMediator("Anniversary19SuppressRewardPreviewMediator")
    end)
    
	local function CreateView()
        local view = CLayout:create(display.size)
        display.commonUIParams(view, {po = display.center})
        self:addChild(view)

        local Image_1 = display.newImageView(RES_DICT.COMMON_BG_2, display.cx - -44, display.cy - -10,
        {
            ap = display.CENTER,
            enable = true,
        })
        view:addChild(Image_1)

        local Button_1 = display.newButton(display.cx - -45, display.cy - -308,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BG_TITLE_2,
            enable = false,
        })
        display.commonLabelParams(Button_1, fontWithColor(14, {text = app.anniversary2019Mgr:GetPoText(__('奖励预览')), fontSize = 24, color = '#ffffff'}))
        view:addChild(Button_1)

        local Text_1 = display.newLabel(display.cx - -44, display.cy - -244,
        {
            text = app.anniversary2019Mgr:GetPoText(__('讨伐时间结束后可去结算页面领取对应奖励')),
            ap = display.CENTER,
            fontSize = 22,
            color = '#7e6454',
        })
        view:addChild(Text_1)

        local Image_2 = display.newImageView(RES_DICT.COMMON_BG_GOODS, display.cx - -43, display.cy - -139,
        {
            ap = display.CENTER,
            scale9 = true, size = cc.size(686, 142),
        })
        view:addChild(Image_2)

        local Image_2_0 = display.newImageView(RES_DICT.COMMON_BG_GOODS, display.cx - -43, display.cy - 31,
        {
            ap = display.CENTER,
            scale9 = true, size = cc.size(686, 182),
        })
        view:addChild(Image_2_0)

        local Image_2_1 = display.newImageView(RES_DICT.COMMON_BG_GOODS, display.cx - -43, display.cy - 214,
        {
            ap = display.CENTER,
            scale9 = true, size = cc.size(686, 164),
        })
        view:addChild(Image_2_1)

        local Image_5 = display.newImageView(RES_DICT.WONDERLAND_BG_TITLE_PRIZE, display.cx - -43, display.cy - -192,
        {
            ap = display.CENTER,
        })
        view:addChild(Image_5)

        local Image_5_0 = display.newImageView(RES_DICT.WONDERLAND_BG_TITLE_PRIZE, display.cx - -43, display.cy - -42,
        {
            ap = display.CENTER,
        })
        view:addChild(Image_5_0)

        local Image_5_1 = display.newImageView(RES_DICT.WONDERLAND_BG_TITLE_PRIZE, display.cx - -43, display.cy - 152,
        {
            ap = display.CENTER,
        })
        view:addChild(Image_5_1)

        local Image_8 = display.newImageView(RES_DICT.WONDERLAND_ICO_SHARE_LINE, display.cx - 128, display.cy - 15,
        {
            ap = display.CENTER,
        })
        Image_8:setScaleX(1.8)
        view:addChild(Image_8)

        local Image_8_0 = display.newImageView(RES_DICT.WONDERLAND_ICO_SHARE_LINE, display.cx - -230, display.cy - 15,
        {
            ap = display.CENTER,
        })
        Image_8_0:setScaleX(1.8)
        view:addChild(Image_8_0)

        local Text_2 = display.newLabel(display.cx - 126, display.cy - 1,
        {
            text = app.anniversary2019Mgr:GetPoText(__('发现BOSS奖励')),
            ap = display.CENTER,
            fontSize = 20,
            color = '#5f4d48',
        })
        view:addChild(Text_2)

        local Text_2_0 = display.newLabel(display.cx - -224, display.cy - 1,
        {
            text = app.anniversary2019Mgr:GetPoText(__('最高伤害额外奖励')),
            ap = display.CENTER,
            fontSize = 20,
            color = '#5f4d48',
        })
        view:addChild(Text_2_0)

        local Text_4 = display.newLabel(display.cx - -42, display.cy - 182,
        {
            text = app.anniversary2019Mgr:GetPoText(__('若时间结束时没有成功讨伐BOSS，则只能获得')),
            ap = display.CENTER,
            fontSize = 20,
            color = '#5f4d48',
        })
        view:addChild(Text_4)

        local Text_5 = display.newLabel(display.cx - -43, display.cy - -192,
        {
            text = app.anniversary2019Mgr:GetPoText(__('参与讨伐奖励')),
            ap = display.CENTER,
            fontSize = 22,
            color = '#ffdfaf',
        })
        view:addChild(Text_5)

        local Text_5_0 = display.newLabel(display.cx - -43, display.cy - -42,
        {
            text = app.anniversary2019Mgr:GetPoText(__('额外奖励')),
            ap = display.CENTER,
            fontSize = 22,
            color = '#ffdfaf',
        })
        view:addChild(Text_5_0)

        local Text_5_1 = display.newLabel(display.cx - -43, display.cy - 152,
        {
            text = app.anniversary2019Mgr:GetPoText(__('失败奖励')),
            ap = display.CENTER,
            fontSize = 22,
            color = '#ffdfaf',
        })
        view:addChild(Text_5_1)

        local closeLabel = display.newButton(display.cx - -43, display.cy - 321,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BG_CLOSE,
            scale9 = true, size = cc.size(210, 26),
            enable = false,
        })
        display.commonLabelParams(closeLabel, {text = app.anniversary2019Mgr:GetPoText(__('点击空白处关闭')), fontSize = 18, color = '#ffffff'})
        view:addChild(closeLabel)

        return {
            view                    = view,
            Image_1                 = Image_1,
            Button_1                = Button_1,
            Text_1                  = Text_1,
            Image_2                 = Image_2,
            Image_2_0               = Image_2_0,
            Image_2_1               = Image_2_1,
            Image_5                 = Image_5,
            Image_5_0               = Image_5_0,
            Image_5_1               = Image_5_1,
            Image_8                 = Image_8,
            Image_8_0               = Image_8_0,
            Text_2                  = Text_2,
            Text_2_0                = Text_2_0,
            Text_4                  = Text_4,
            Text_5                  = Text_5,
            Text_5_0                = Text_5_0,
            Text_5_1                = Text_5_1,
            closeLabel              = closeLabel,
        }
    end
	xTry(function ( )
        self.viewData = CreateView()
	end, __G__TRACKBACK__)
end

return Anniversary19SuppressRewardPreviewView
