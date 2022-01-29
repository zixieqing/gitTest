local GameScene = require( "Frame.GameScene" )
---@class ScratcherTaskView : GameScene
local ScratcherTaskView = class("ScratcherTaskView", GameScene)

local RES_DICT = {
    COMMON_BTN_BACK                 = _res('ui/common/common_btn_back.png'),
    COMMON_BTN_ORANGE               = _res('ui/common/common_btn_orange.png'),
	COMMON_BTN_TIPS                 = _res('ui/common/common_btn_tips.png'),
    STARPLAN_TITLE                  = _res('ui/home/activity/saimoe/starplan_title.png'),
    SUMMON_NEWHAND_BTN_DRAW         = _res('ui/home/capsuleNew/common/summon_newhand_btn_draw.png'),
    CARDMATCH_MAIN_BG               = _res('ui/scratcher/cardmatch_main_bg.jpg'),
    CARDMATCH_TASK_BG               = _res('ui/scratcher/cardmatch_task_bg.png'),
    CARDMATCH_TASK_TITLE_BG         = _res('ui/scratcher/cardmatch_task_title_bg.png'),
}

function ScratcherTaskView:ctor( ... )
	GameScene.ctor(self, 'Game.views.scratcher.ScratcherTaskView')
	self.args = unpack({...}) or {}

	self:InitUI()
end

function ScratcherTaskView:InitUI()
    local function CreateView()
        local view = CLayout:create(display.size)
        display.commonUIParams(view, {po = display.center})
        self:addChild(view)    

        local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 120))
        eaterLayer:setTouchEnabled(true)
        eaterLayer:setContentSize(display.size)
        eaterLayer:setPosition(cc.p(display.cx, display.cy))
        view:addChild(eaterLayer)

        local BG = display.newImageView(RES_DICT.CARDMATCH_MAIN_BG, display.cx - 0, display.cy - 0,
        {
            ap = display.CENTER,
        })
        view:addChild(BG)

        local drawNode = require('common.CardSkinDrawNode').new({
			skinId = CardUtils.GetCardDefaultSkinIdByCardId(self.args.myChoice),
        })
        view:addChild(drawNode)

        local scrapeBtn = display.newButton(display.cx - 355, 79,
        {
            ap = display.CENTER,
            n = RES_DICT.SUMMON_NEWHAND_BTN_DRAW,
            enable = true,
        })
        display.commonLabelParams(scrapeBtn, fontWithColor(14, {text = __('刮刮乐'), fontSize = 34, color = '#ffffff', outline = '#5b3c25', outlineSize = 2, offset = cc.p(0, -3)}))
        view:addChild(scrapeBtn)

        local statusBtn = display.newButton(display.cx - 85, display.height - 151,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_ORANGE,
            enable = true,
        })
        display.commonLabelParams(statusBtn, fontWithColor(14, {text = __('对决状态')}))
        view:addChild(statusBtn)

        ------------------topView start-------------------
        local topView = display.newLayer(0, display.height,
        {
            ap = cc.p(0, 1.0),
            size = cc.size(display.width, 100),
            enable = false,
        })
        view:addChild(topView)

        local timeBG = display.newImageView(RES_DICT.STARPLAN_TITLE, display.cx - -18, 100,
        {
            ap = display.CENTER_TOP,
        })
        topView:addChild(timeBG)

        local tipsBtn = display.newButton(display.cx - -220, 68,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_TIPS,
            enable = true,
        })
        -- display.commonLabelParams(tipsBtn, fontWithColor(14, {text = ''})
        topView:addChild(tipsBtn)

        local timeTitleLabel = display.newLabel(display.cx - -12, 71,
        {
            text = __('比赛剩余时间：'),
            ap = display.RIGHT_CENTER,
            fontSize = 22,
            color = '#ffffff',
        })
        topView:addChild(timeTitleLabel)

        local timeLabel = display.newLabel(display.cx - -11, 71,
        {
            text = '',
            ap = display.LEFT_CENTER,
            fontSize = 28,
            color = '#ffd042',
        })
        topView:addChild(timeLabel)

        -------------------topView end--------------------
        local Image_2 = display.newImageView(RES_DICT.CARDMATCH_TASK_BG, display.cx - -333, display.height - 101,
        {
            ap = display.CENTER_TOP,
            scale9 = true, size = cc.size(646, display.height - 106),
        })
        view:addChild(Image_2)

        ------------------Image_1 start-------------------
        local Image_1 = display.newImageView(RES_DICT.CARDMATCH_TASK_TITLE_BG, display.cx - -333, display.height - 127,
        {
            ap = display.CENTER,
        })
        view:addChild(Image_1)

        local Text_2 = display.newLabel(17, 18,
        {
            text = __('做任务拿刮刮乐'),
            ap = display.LEFT_CENTER,
            fontSize = 24,
            color = '#ffffff',
        })
        Image_1:addChild(Text_2)

        -------------------Image_1 end--------------------

		local taskGridview = CGridView:create(cc.size(620, display.height - 170))
		taskGridview:setSizeOfCell(cc.size(620, 122))
		taskGridview:setColumns(1)
		taskGridview:setAutoRelocate(true)
		view:addChild(taskGridview)
		taskGridview:setAnchorPoint(cc.p(0, 1.0))
		taskGridview:setPosition(display.cx - -22, display.height - 152)

        local backBtn = display.newButton(display.SAFE_L + 75, display.height - 53,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_BACK,
            enable = true,
        })
        -- display.commonLabelParams(backBtn, fontWithColor(14, {text = ''}))
        view:addChild(backBtn)

        return {
            view                    = view,
            scrapeBtn               = scrapeBtn,
            statusBtn               = statusBtn,
            topView                 = topView,
            timeBG                  = timeBG,
            tipsBtn                 = tipsBtn,
            timeTitleLabel          = timeTitleLabel,
            timeLabel               = timeLabel,
            Image_2                 = Image_2,
            Image_1                 = Image_1,
            Text_2                  = Text_2,
            taskGridview            = taskGridview,
            backBtn                 = backBtn,
        }
    end

	xTry(function ( )
	    self.viewData = CreateView()
	end, __G__TRACKBACK__)
end

return ScratcherTaskView
