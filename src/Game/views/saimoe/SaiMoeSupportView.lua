--[[
    燃战助战界面
--]]
local GameScene = require( "Frame.GameScene" )
---@class SaiMoeSupportView :GameScene
local SaiMoeSupportView = class("SaiMoeSupportView", GameScene)
local shareFacade = AppFacade.GetInstance()
local uiMgr = shareFacade:GetManager("UIManager")
local RemindIcon      = require('common.RemindIcon')

local RES_DICT          = {
	NAV_BACK                        = _res("ui/common/common_btn_back.png"),
	COMMON_BTN_ORANGE               = _res('ui/common/common_btn_orange.png'),
	COMMON_BTN_WHITE_DEFAULT        = _res('ui/common/common_btn_white_default.png'),
    COMMON_BTN_TIPS                 = _res('ui/common/common_btn_tips.png'),
    MAIN_BTN_RANK                   = _res('ui/home/nmain/main_btn_rank.png'),
    RAID_BOSS_BTN_SEARCH            = _res('ui/common/raid_boss_btn_search.png'),
    STARPLAN_MAIN_ICON_LIGHT        = _res('ui/common/starplan_main_icon_light.png'),
    STARPLAN_HOMEPAGE_BG            = _res('ui/home/activity/saimoe/starplan_main_bg.jpg'),
    STARPLAN_HOMEPAGE_BTN_FIGHT_BOSS = _res('ui/home/activity/saimoe/starplan_homepage_btn_fight_boss.png'),
    STARPLAN_HOMEPAGE_BTN_FIGHT1    = _res('ui/home/activity/saimoe/starplan_homepage_btn_fight1.png'),
    STARPLAN_MAIN_BG_GIFT           = _res('ui/home/activity/saimoe/starplan_main_bg_gift.png'),
    STARPLAN_MAIN_BG_NUMBER         = _res('ui/home/activity/saimoe/starplan_main_bg_number.png'),
    STARPLAN_MAIN_FRAME_1           = _res('ui/home/activity/saimoe/starplan_main_frame_1.png'),
    STARPLAN_MAIN_FRAME_2           = _res('ui/home/activity/saimoe/starplan_main_frame_2.png'),
    STARPLAN_MAIN_FRAME_BTN_BG      = _res('ui/home/activity/saimoe/starplan_main_frame_btn_bg.png'),
    STARPLAN_MAIN_FRAME_BTN_NAME    = _res('ui/common/starplan_main_frame_btn_name.png'),
    STARPLAN_MAIN_TITLE_BG          = _res('ui/home/activity/saimoe/starplan_main_title_bg.png'),
    STARPLAN_TITLE                  = _res('ui/home/activity/saimoe/starplan_title.png'),
}

function SaiMoeSupportView:ctor( ... )
	GameScene.ctor(self, 'Game.views.saimoe.SaiMoeSupportView')
	self.args = unpack({...}) or {}

	self:InitUI()
end

function SaiMoeSupportView:InitUI()
	local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 130))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(display.size)
    eaterLayer:setPosition(cc.p(display.cx, display.cy))
    self:addChild(eaterLayer, -1)
    
	local function CreateView()
        local view = CLayout:create(display.size)
        view:setPosition(display.center)
        view:setName('SaiMoeSupportView')
        self:addChild(view)

        local BG = display.newImageView(RES_DICT.STARPLAN_HOMEPAGE_BG, display.cx - 0, display.cy - 0,
        {
            ap = display.CENTER,
        })
        view:addChild(BG)

        local drawNode = require('common.CardSkinDrawNode').new({
			skinId = 250370,
			-- coordinateType = COORDINATE_TYPE_HEAD
        })
        view:addChild(drawNode)

        local timeBG = display.newImageView(RES_DICT.STARPLAN_TITLE, display.cx - -18, display.height - 0,
        {
            ap = display.CENTER_TOP,
        })
        view:addChild(timeBG)

        local tipsBtn = display.newButton(display.cx - -220, display.height - 31,
                {
                    ap = display.CENTER,
                    n = RES_DICT.COMMON_BTN_TIPS,
                    enable = true,
                })
        -- display.commonLabelParams(tipsBtn, fontWithColor(14, {text = ''})
        view:addChild(tipsBtn)

        --local timeTitleLabel = display.newLabel(display.cx - -12, display.height - 31,
        --{
        --    text = __('比赛剩余时间：'),
        --    ap = display.RIGHT_CENTER,
        --    fontSize = 22,
        --    color = '#ffffff',
        --})
        --view:addChild(timeTitleLabel)
        --
        --local timeLabel = display.newLabel(display.cx - -11, display.height - 30,
        --{
        --    text = '',
        --    ap = display.LEFT_CENTER,
        --    fontSize = 28,
        --    color = '#ffd042',
        --})
        --view:addChild(timeLabel)

        local timeLabel = display.newRichLabel(display.cx -11,  display.height - 30, {
            c = {{
                     text = '',
                     ap = display.LEFT_CENTER,
                     fontSize = 28,
                     color = '#ffd042'
                 }}
        })
        view:addChild(timeLabel)

        local ligthImg = display.newImageView(RES_DICT.STARPLAN_MAIN_ICON_LIGHT, display.SAFE_R - 63, display.height - 64,
                {
                    ap = display.CENTER,
                })
        view:addChild(ligthImg)

        local rankingBG = display.newImageView(RES_DICT.STARPLAN_MAIN_FRAME_BTN_NAME, display.SAFE_R - 61, display.height - 104,
        {
            ap = display.CENTER,
        })
        view:addChild(rankingBG)

        -----------------rankingBtn start-----------------
        local rankingBtn = display.newButton(display.SAFE_R - 61, display.height - 55,
        {
            ap = display.CENTER,
            n = RES_DICT.MAIN_BTN_RANK,
            enable = true,
        })
        -- display.commonLabelParams(rankingBtn, fontWithColor(14, {text = ''})
        view:addChild(rankingBtn)

        local rankingLabel = display.newLabel(44, -4,
        {
            text = __('排行榜'),
            ap = display.CENTER,
            fontSize = 24,
            color = '#ffffff',
            font = TTF_GAME_FONT, ttf = true,
            outline = '#5b3c25',
        })
        rankingBtn:addChild(rankingLabel)

        ------------------rankingBtn end------------------
        ----------------supportView start-----------------
        local supportView = display.newLayer(display.cx - -180, display.cy - 152,
        {
            ap = display.LEFT_BOTTOM,
            size = cc.size(400, 300),
            enable = false,
        })
        view:addChild(supportView)

        local supportBG = display.newImageView(RES_DICT.STARPLAN_MAIN_BG_GIFT, 215, 150,
        {
            ap = display.CENTER,
        })
        supportView:addChild(supportBG)

        local supportLabel = display.newButton(214, 303,
        {
            ap = display.CENTER,
            n = RES_DICT.STARPLAN_MAIN_TITLE_BG,
            enable = false,
        })
        display.commonLabelParams(supportLabel, {text = __('应援道具'), fontSize = 28, color = '#ffffff', font = TTF_GAME_FONT, ttf = true})
        supportView:addChild(supportLabel)

        local activityItem = require('common.GoodNode').new({id = 890002, amount = 1, showName = true})
        activityItem:setPosition(cc.p(306, 152))
        supportView:addChild(activityItem)
        display.commonUIParams(activityItem, {animate = false, cb = function (sender)
            PlayAudioByClickNormal()
            uiMgr:AddDialog("common.GainPopup", {goodId = sender.goodId, isFrom = 'saimoe.SaiMoeSupportMediator'})
            --uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
        end})
        activityItem.nameLabel:setPositionY(utils.getLocalCenter(activityItem).y + activityItem.bg:getContentSize().height * 0.5 + 60)
        display.commonLabelParams(activityItem.nameLabel, {fontSize = 22, color = '#5b3c25'})

        local exclusiveItem = require('common.GoodNode').new({id = 890002, amount = 1, showName = true})
        exclusiveItem:setPosition(cc.p(121, 152))
        supportView:addChild(exclusiveItem)
        display.commonUIParams(exclusiveItem, {animate = false, cb = function (sender)
            PlayAudioByClickNormal()
            uiMgr:AddDialog("common.GainPopup", {goodId = sender.goodId, isFrom = 'saimoe.SaiMoeSupportMediator'})
            --uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
        end})
        exclusiveItem.nameLabel:setPositionY(utils.getLocalCenter(exclusiveItem).y + exclusiveItem.bg:getContentSize().height * 0.5 + 60)
        display.commonLabelParams(exclusiveItem.nameLabel, {fontSize = 22, color = '#5b3c25'})

        local activitySupportBtn = display.newButton(306, 49,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_ORANGE,
            enable = true,
            tag = 1,
        })
        display.commonLabelParams(activitySupportBtn, fontWithColor(14, {text = __('赠送'), fontSize = 24, color = '#ffffff'}))
        supportView:addChild(activitySupportBtn)

        local exclusiveSupportBtn = display.newButton(121, 49,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_ORANGE,
            enable = true,
            tag = 2,
        })
        display.commonLabelParams(exclusiveSupportBtn, fontWithColor(14, {text = __('赠送'), fontSize = 24, color = '#ffffff'}))
        supportView:addChild(exclusiveSupportBtn)


        -----------------supportView end------------------
        -----------------bottomView start-----------------
        local bottomView = display.newLayer(0, 0,
        {
            ap = display.LEFT_BOTTOM,
            size = cc.size(display.width, 200),
            enable = false,
        })
        view:addChild(bottomView)

        local btnBG = display.newImageView(RES_DICT.STARPLAN_MAIN_FRAME_BTN_BG, display.cx - -390, 56,
                {
                    ap = display.CENTER,
                })
        bottomView:addChild(btnBG)

        local bottomBGL = display.newImageView(RES_DICT.STARPLAN_MAIN_FRAME_1, display.cx - 271, 61,
        {
            ap = display.CENTER,
            scale9 = true, size = cc.size(1081, 113),
        })
        bottomView:addChild(bottomBGL)

        local bottomBGR = display.newImageView(RES_DICT.STARPLAN_MAIN_FRAME_2, display.cx - -659, 62,
        {
            ap = display.CENTER,
        })
        bottomView:addChild(bottomBGR)

        local numberBG = display.newImageView(RES_DICT.STARPLAN_MAIN_BG_NUMBER, display.SAFE_L + 431, 59,
                {
                    ap = display.CENTER,
                })
        bottomView:addChild(numberBG)

        local normalBattleBtn = display.newButton(display.cx - -466, 110,
                {
                    ap = display.CENTER,
                    n = RES_DICT.STARPLAN_HOMEPAGE_BTN_FIGHT1,
                    enable = true,
                })
        -- display.commonLabelParams(normalBattleBtn, fontWithColor(14, {text = ''})
        bottomView:addChild(normalBattleBtn)

        local normalBtnBG = display.newButton(display.cx - -472, 53,
        {
            ap = display.CENTER,
            n = RES_DICT.STARPLAN_MAIN_FRAME_BTN_NAME,
            enable = false,
        })
         display.commonLabelParams(normalBtnBG, {
                    text = __('搜寻'),
                    ap = display.CENTER,
                    fontSize = 30,
                    color = '#ffffff',
                    font = TTF_GAME_FONT, ttf = true,
                    outline = '#5b3c25',
                })
        bottomView:addChild(normalBtnBG)

        local bossBattleBtn = display.newButton(display.cx - -306, 110,
                {
                    ap = display.CENTER,
                    n = RES_DICT.STARPLAN_HOMEPAGE_BTN_FIGHT_BOSS,
                    enable = true,
                })
        -- display.commonLabelParams(bossBattleBtn, fontWithColor(14, {text = ''})
        bottomView:addChild(bossBattleBtn)

        RemindIcon.addRemindIcon({parent = bossBattleBtn, tag = RemindTag.SAIMOE_COMPOSABLE, po = cc.p(120,  120)})

        local unlockAni = sp.SkeletonAnimation:create("effects/activity/saimoe/starplan_anniu.json","effects/activity/saimoe/starplan_anniu.atlas", 1)
        unlockAni:setPosition(cc.p(display.cx - -306, 110))
        unlockAni:update(0)
        bottomView:addChild(unlockAni)

        local bossBtnBG = display.newButton(display.cx - -311, 53,
        {
            ap = display.CENTER,
            n = RES_DICT.STARPLAN_MAIN_FRAME_BTN_NAME,
            enable = false,
        })
        display.commonLabelParams(bossBtnBG, {
            text = __('追击'),
            ap = display.CENTER,
            fontSize = 30,
            color = '#ffffff',
            font = TTF_GAME_FONT, ttf = true,
            outline = '#5b3c25',
        })
        bottomView:addChild(bossBtnBG)

        ---------------voteResultBtn start----------------
        local voteResultBtn = display.newButton(display.cx - -115, 56,
        {
            ap = display.CENTER,
            n = RES_DICT.COMMON_BTN_WHITE_DEFAULT,
            enable = true,scale9 = true ,
            size = cc.size(150 , 65)
        })
        display.commonLabelParams(voteResultBtn, fontWithColor(14, {text = __('查看'), fontSize = 22, color = '#ffffff', offset = cc.p(18, 0)}))
        bottomView:addChild(voteResultBtn)

        local lookImg = display.newImageView(RES_DICT.RAID_BOSS_BTN_SEARCH, 29, 31,
        {
            ap = display.CENTER,
        })
        lookImg:setScale(0.8, 0.8)
        voteResultBtn:addChild(lookImg)

        ----------------voteResultBtn end-----------------
        local votesDesrLabel = display.newLabel(display.SAFE_L + 225, 58,
        {
            text = __('我的应援:'),
            ap = display.LEFT_CENTER ,
            fontSize = 24,
            color = '#5b3c25',
        })
        bottomView:addChild(votesDesrLabel)



        local votesTitleLabel = display.newLabel(display.SAFE_L + 652, 57,
        {
            text = __('票'),
            ap = display.RIGHT_CENTER,
            fontSize = 24,
            color = '#5b3c25',
        })
        bottomView:addChild(votesTitleLabel)

        local votesLabel = display.newLabel(display.SAFE_L + 642 - display.getLabelContentSize(votesTitleLabel).width, 61,
            {
                text = '',
                ap = display.RIGHT_CENTER,
                fontSize = 44,
                color = '#ffffff',
                font = TTF_GAME_FONT, ttf = true,
                outline = '#5b3c25',
            }
        )
        bottomView:addChild(votesLabel)

        local ligthImg = display.newImageView(RES_DICT.STARPLAN_MAIN_ICON_LIGHT, display.SAFE_L + 88, 90,
                {
                    ap = display.CENTER,
                })
        bottomView:addChild(ligthImg)
        ligthImg:runAction(cc.RepeatForever:create(cc.RotateBy:create(2, 30)))

        -- 宝箱
        local rewardBox = sp.SkeletonAnimation:create("effects/baoxiang/baoxiang8.json","effects/baoxiang/baoxiang8.atlas", 1)
        rewardBox:setPosition(cc.p(display.SAFE_L + 88, 90))
        rewardBox:update(0)
        rewardBox:setAnimation(0, 'stop', true)
        bottomView:addChild(rewardBox)

    	-- 点击的layer
    	local clickLayer = display.newLayer(display.SAFE_L + 84, 92, {ap = display.CENTER ,size = cc.size(100,86), color = cc.r4b(0) , enable = true })
        bottomView:addChild(clickLayer)
        
        local bonusLabel = display.newLabel(display.SAFE_L + 86, 38,
        {
            text = __('应援奖励'),
            ap = display.CENTER,
            fontSize = 24,
            color = '#5b3c25',
            reqW = 150
        })
        bottomView:addChild(bonusLabel)

        ------------------bottomView end------------------
		
		local backBtn = display.newButton(0, 0, {n = RES_DICT.NAV_BACK})
		display.commonUIParams(backBtn, {po = cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.height - 18 - backBtn:getContentSize().height * 0.5)})
        backBtn:setName('NAV_BACK')
		view:addChild(backBtn, 5)
        backBtn:setOnClickScriptHandler(function(sender)
            PlayAudioByClickNormal()
            shareFacade:UnRegsitMediator("saimoe.SaiMoeSupportMediator")
        end)

        local aniLayer = CColorView:create(cc.c4b(0, 0, 0, 0))
        aniLayer:setTouchEnabled(true)
        aniLayer:setContentSize(display.size)
        aniLayer:setPosition(cc.p(display.cx, display.cy))
        self:addChild(aniLayer, 100)
        aniLayer:setVisible(false)

        local supportBGAni = sp.SkeletonAnimation:create("effects/activity/saimoe/starplan_piaodai.json","effects/activity/saimoe/starplan_piaodai.atlas", 1)
        supportBGAni:setPosition(cc.p(display.cx, display.cy))
        supportBGAni:update(0)
        supportBGAni:setAnimation(0, 'idle', true)
        aniLayer:addChild(supportBGAni)

        local supportAni = sp.SkeletonAnimation:create("effects/activity/saimoe/starplan_xuanpiao.json","effects/activity/saimoe/starplan_xuanpiao.atlas", 1)
        supportAni:setPosition(cc.p(display.cx, display.cy))
        supportAni:update(0)
        aniLayer:addChild(supportAni)

		return {
            view                    = view,
            BG                      = BG,
            timeBG                  = timeBG,
            tipsBtn                 = tipsBtn,
            timeTitleLabel          = timeTitleLabel,
            timeLabel               = timeLabel,
            rankingBG               = rankingBG,
            rankingBtn              = rankingBtn,
            rankingLabel            = rankingLabel,
            supportView             = supportView,
            supportBG               = supportBG,
            supportLabel            = supportLabel,
            activitySupportBtn      = activitySupportBtn,
            exclusiveSupportBtn     = exclusiveSupportBtn,
            activityItem            = activityItem, 
            exclusiveItem           = exclusiveItem, 
            drawNode                = drawNode,
            bottomView              = bottomView,
            bottomBGL               = bottomBGL,
            bottomBGR               = bottomBGR,
            normalBtnBG             = normalBtnBG,
            normalBattleBtn         = normalBattleBtn,
            bossBtnBG               = bossBtnBG,
            bossBattleBtn           = bossBattleBtn,
            voteResultBtn           = voteResultBtn,
            lookImg                 = lookImg,
            votesDesrLabel          = votesDesrLabel,
            votesLabel              = votesLabel,
            votesTitleLabel         = votesTitleLabel,
            rewardBox               = rewardBox,
            clickLayer              = clickLayer,
            bonusLabel              = bonusLabel,
            aniLayer                = aniLayer,
            supportAni              = supportAni,
            unlockAni               = unlockAni,
        }
    end
	xTry(function ( )
        self.viewData = CreateView()
	end, __G__TRACKBACK__)
end

return SaiMoeSupportView