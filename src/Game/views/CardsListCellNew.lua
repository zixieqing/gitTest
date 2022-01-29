local CardsListCellNew = class('home.CardsListCellNew',function ()
    local pageviewcell = CTableViewCell:new()
    -- local pageviewcell = CGridViewCell:new()
    pageviewcell.name = 'home.CardsListCellNew'
    pageviewcell:enableNodeEvents()
    return pageviewcell
end)

function CardsListCellNew:ctor(...)
    local arg = {...}
    local size = cc.size(525,107)
    self:setContentSize(size)

    local eventNode = CLayout:create(cc.size(525,107))
    eventNode:setName('eventNode')
    eventNode:setPosition(utils.getLocalCenter(self))
    self:addChild(eventNode)
    self.eventnode = eventNode

    local toggleView = display.newCheckBox(size.width * 0.5,size.height * 0.5,{--newButton
        n = _res('ui/home/cardslistNew/card_preview_bg_list_unslected.png')
        ,s = _res('ui/home/cardslistNew/card_preview_bg_list_selected.png')
    })
    self.toggleView = toggleView
    self.eventnode:addChild(self.toggleView)


    self.selectGoBg = display.newImageView(_res('ui/home/cardslistNew/card_preview_btn_list_edit.png'), 0,0)
    self.selectGoBg:setName('selectGoBg')
    self.selectGoBg:setAnchorPoint(cc.p(1,0.5))
    self.selectGoBg:setPosition(cc.p(size.width - 10,size.height * 0.5 + 2))
    self.eventnode:addChild(self.selectGoBg)
    self.selectGoBg:setTouchEnabled(true)
    self.selectGoBg:setVisible(false)
    self.selectGoBg:setTag(500)

    local imgswitch = display.newImageView(_res('ui/home/cardslistNew/common_btn_switch.png'), 0,0)
    imgswitch:setName('imgswitch')
    imgswitch:setAnchorPoint(cc.p(0.5,0.5))
    imgswitch:setPosition(cc.p(self.selectGoBg:getContentSize().width * 0.5 + 10,self.selectGoBg:getContentSize().height * 0.5 + 10))
    self.selectGoBg:addChild(imgswitch)


    local tempLabel = display.newLabel(self.selectGoBg:getContentSize().width * 0.5 + 10, self.selectGoBg:getContentSize().height * 0.5 - 30,
        {text = __('查看'), fontSize = 18, color = '#4c4c4c', ap = cc.p(0.5, 0.5)})
    self.selectGoBg:addChild(tempLabel)
    tempLabel:setVisible(false)

    --卡牌头像框
    self.headRankImg = FilteredSpriteWithOne:create()
    self.headRankImg:setSpriteFrame("kapai_frame_white.png")
    self.headRankImg:setPosition(cc.p( 10 , size.height * 0.5 + 2))
    self.headRankImg:setAnchorPoint(cc.p(0, 0.5))
    self.eventnode:addChild(self.headRankImg, 10)
    self.headRankImg:setScale(0.58)


    -- self.headRankImg = display.newImageView(_res('ui/common/common_frame_goods_1.png'), 10 , size.height * 0.5 + 2,
    --         {ap = cc.p(0, 0.5)
    --     })
    -- self.headRankImg:setScale(0.58)
    -- self.eventnode:addChild(self.headRankImg,2)

    local img = display.newImageView('#kapai_frame_bg.png', 11 , size.height * 0.5 + 2,
            {ap = cc.p(0, 0.5)
        })
    img:setScale(0.6)
    self.eventnode:addChild(img) 

     --卡牌头像
    self.headImg = FilteredSpriteWithOne:create()
    self.headImg:setTexture(_res('ui/home/teamformation/choosehero/card_order_ico_selected.png'))
    self.headImg:setPosition(cc.p( 15 , size.height * 0.5 + 2))
    self.headImg:setAnchorPoint(cc.p(0, 0.5))
    self.eventnode:addChild(self.headImg, 1)
    self.headImg:setScale(0.58)

    local particleSpine = nil
    if CommonUtils.GetModuleAvailable(MODULE_SWITCH.MARRY) then
        particleSpine =  display.newCacheSpine(SpineCacheName.COMMON, 'effects/marry/fly_tx')
        -- particleSpine:setTimeScale(2.0 / 3.0)
        particleSpine:setPosition(cc.p(66 , size.height * 0.5 + 2))
        self.eventnode:addChild(particleSpine, 1)
        particleSpine:setAnimation(0, 'idle3', true)
        particleSpine:update(0)
        particleSpine:setToSetupPose()
        particleSpine:setScale(0.66)
        particleSpine:setVisible(false)
    end
    self.particleSpine = particleSpine
    
    --卡牌类型
    self.bgJob = display.newImageView('#card_order_ico_blue.png',self.headRankImg:getContentSize().width -70, size.height,
            {ap = cc.p(0, 1)
        })
    self.eventnode:addChild(self.bgJob,6) 

    self.jobImg = display.newImageView('#card_ico_battle_defend.png',self.headRankImg:getContentSize().width -53, size.height-17,
            {ap = cc.p(0.5, 0.5)
        })
    self.jobImg:setScale(0.7)

    self.eventnode:addChild(self.jobImg,10)



    self.heroLvLabel = display.newLabel(self.bgJob:getPositionX() + 40,self.bgJob:getPositionY() - 16,
        fontWithColor(14,{text = '13级',color = 'ff8e74' , fontSize = 20,  ap = cc.p(0, 0.5)}))--  {text = ' ', fontSize = 20, color = '#4c4c4c', ap = cc.p(0, 0.5)}
    self.eventnode:addChild(self.heroLvLabel,6)

    self.heroNameLabel = display.newLabel(self.heroLvLabel:getPositionX() + display.getLabelContentSize(self.heroLvLabel).width + 50  ,self.bgJob:getPositionY() - 16,
        fontWithColor(14,{text = ' ', reqW = 250  , fontSize = 20,  ap = cc.p(0, 0.5)}))--  {text = ' ', fontSize = 20, color = '#4c4c4c', ap = cc.p(0, 0.5)}
    self.eventnode:addChild(self.heroNameLabel,6)
    self.nameLabelParams = fontWithColor(14, {fontSizeN = 24, colorN = 'ffffff'})


    self.heroFightLabel = display.newLabel(self.bgJob:getPositionX() + 10,self.bgJob:getPositionY() -  50,
        {text = ' ', fontSize = 20, color = '#4c4c4c', ap = cc.p(0, 0.5)})
    self.eventnode:addChild(self.heroFightLabel,6)

    --新货的
    self.newImg = display.newImageView(_res('ui/home/cardslistNew/card_preview_ico_new.png'),66, 10,
            {ap = cc.p(0.5, 0.5)
        })
    self.eventnode:addChild(self.newImg,20)

    --红点
    self.redImg = display.newImageView(_res('ui/common/common_ico_red_point.png'),0,  size.height + 10,
            {ap = cc.p(0, 1)
        })
    self.eventnode:addChild(self.redImg,20)

    --碎片滑动条
    self.fragmentBarBg = display.newImageView(_res('ui/home/cardslistNew/card_preview_bg_loading_fragment.png'))
    display.commonUIParams(self.fragmentBarBg, {po = cc.p(size.width - 90,20)})
    self.eventnode:addChild(self.fragmentBarBg, 5)

    self.fragmentBar = cc.ProgressTimer:create(cc.Sprite:create(_res('ui/home/cardslistNew/card_preview_ico_loading_fragment_not.png')))
    self.fragmentBar:setType(cc.PROGRESS_TIMER_TYPE_BAR)
    self.fragmentBar:setMidpoint(cc.p(0, 0))
    self.fragmentBar:setBarChangeRate(cc.p(1, 0))
    self.fragmentBar:setPosition(utils.getLocalCenter(self.fragmentBarBg))
    self.fragmentBar:setPercentage(50)
    self.fragmentBarBg:addChild(self.fragmentBar)

    self.fragmentLabel = display.newLabel(utils.getLocalCenter(self.fragmentBarBg).x, utils.getLocalCenter(self.fragmentBarBg).y,
        {text = '2/4', fontSize = 20, color = '#ffffff', ap = cc.p(0.5,0.5)})
    self.fragmentBarBg:addChild(self.fragmentLabel,10)


    self.fragmentBtn = display.newButton(0, 0,
        {n = _res('ui/common/common_btn_orange.png')})--, cb = handler(self, self.upgradeBtnCallback)
    self.fragmentBtn :setVisible(false)
    display.commonUIParams(self.fragmentBtn, {ap = cc.p(0.5,0.5),po = cc.p(size.width - 90,66)})
    display.commonLabelParams(self.fragmentBtn, fontWithColor(14,{text = __('合成')}))
    self.eventnode:addChild(self.fragmentBtn,7)
    -- self.fragmentBtn:setVisible(false)

    self.stateLabel = display.newButton( size.width * 0.5, 4 ,{n = _res('ui/home/cardslistNew/card_preview_bg_state_card.png'),enable = false,ap = cc.p(0.5, 0)})
    display.commonLabelParams(self.stateLabel, { text = ('飨灵列表'), fontSize = 20, color = 'fff3ca'})
    self.eventnode:addChild(self.stateLabel,10)

    local artifactIcon = display.newImageView(CommonUtils.GetArtifiactPthByCardId(200001),145, 25,{scale = 0.25 }  )
    self.eventnode:addChild(artifactIcon,10)
    self.artifactIcon = artifactIcon
    self.artifactIcon:setVisible(false)
end
return CardsListCellNew
