---
--- Created by xingweihao.
--- DateTime: 24/10/2017 7:35 PM
---
---
--- Created by xingweihao.
--- DateTime: 24/10/2017 6:11 PM
---
---@class PersonInformationSystemView
local PersonInformationSystemView = class('home.PersonInformationSystemView',function ()
    local node = CLayout:create(cc.size(982,562)) --cc.size(984,562)
    node.name = 'Game.views.PersonInformationSystemView'
    node:enableNodeEvents()
    return node
end)
local BUTTON_CLICK = {
    WORLD_VOICE_AUTO_PLAY           = 1019, --世界语音自动播放
    RELOADGAME                      = 1003, -- 重新进入游戏按钮
    EXITGAME                        = 1009, -- 退出游戏
    CONRROL_MUSIC                   = 1010, -- 控制音乐
    GAME_MUSIC_EFFECT               = 1011, -- 控制音效
    TELIPHONE_VIBRATE               = 1012, -- 控制振动
    GAME_VOICE                      = 1013, -- 游戏语音

    CONTREL_MUSIC_BIGORLITTLE       = 1014, --控制音乐大小
    CONTREL_GAME_EFFECT_BIGORLITTLE = 1015, --控制音乐大小
    CONTREL_TEL_VIBRATE_BIGORLITTLE = 1016, --控制手机振动
    CONTREL_GAME_VOICE_BIGORLITTLE  = 1017, --控制游戏声音大小
    ONELY_WIFI_OPEN                 = 1018, -- 这些仅在wift 下开启
    WORLD_VOICE_AUTO_PLAY           = 1019, --世界语音自动播放
    GUILD_VOICE_AUTO_PLAY           = 1020, --公会语音自动播放
    FORM_TEAM_VOICE_AUTO_PLAY       = 1021, --组队语音控制
    PRIVATE_CHAT_VOICE_AUTO_PLAY    = 1022, -- 私聊语音自动播放
    CHOOSE_JAPANESE_BTN             = 1023,
    CHOOSE_CHINESE_BTN              = 1024,
    CHOOSE_CHINESE_ADD_BTN          = 1025,
    HP_FULL_PUSH_LOCAL              = 1026, -- 体力回满通知
    AIR_TAKEAWAY_PUSH_LOCAL         = 1027, -- 空运的推送
    LOVE_FOOD_RECOVER_PUSH_LOCAL    = 1028, -- 爱心便当
    PUBLISH_ORDER_RECOVER_LOCAL     = 1029, -- 公有订单推送
    RESTAURANT_RECOVER__LOCAL       = 1030, -- 餐厅恢复的推送
    REMIND_PUSH                     = 1031,
    MARQUEE_PUSH                    = 1032, -- 跑马灯
    WORLD_CHANNEL_PUSH              = 1033, -- 世界频道的推送
    CHAT_PUSH                       = 1034, -- 聊天的推送
    WORLD_BOSS_PUSH                 = 1041, --世界boss 推送
}

function PersonInformationSystemView:ctor()
    self:initUI()
end

function PersonInformationSystemView:initUI()
    local layoutSize = cc.size(984,580)
    local layout = display.newLayer(layoutSize.width/2 , layoutSize.height/2,{ ap =  display.CENTER , size = layoutSize, enable  = true })
    --基本设置标签
    local topImageSize = cc.size(984 , 232)
    local topLayout =  display.newLayer(layoutSize.width/2 , layoutSize.height , { ap = display.CENTER_TOP , size = topImageSize})
    layout:addChild(topLayout)

    local bgBottomImage  = display.newImageView(_res('ui/home/infor/settings_bg_1'),topImageSize.width/2 , topImageSize.height/2 , {scale9 = true , size = topImageSize  })
    topLayout:addChild(bgBottomImage)

    local bgBottomImageTwo  = display.newImageView(_res('ui/home/infor/settings_bg_2'),topImageSize.width/2 , topImageSize.height - 4  , { ap = display.CENTER_TOP , scale9 = true , size =  cc.size(980, 72) })
    topLayout:addChild(bgBottomImageTwo)

    local bottomImageSize = cc.size(984 , 250)
    local bottomImageLayout =  display.newLayer(layoutSize.width/2 , layoutSize.height /2 - 45, { ap = display.CENTER_TOP , size = bottomImageSize })
    layout:addChild(bottomImageLayout)

    local bgBottomImage  = display.newImageView(_res('ui/home/infor/settings_bg_1'),bottomImageSize.width/2 , bottomImageSize.height/2 , {scale9 = true , size = bottomImageSize  })
    bottomImageLayout:addChild(bgBottomImage)

    local bgBottomImageTwo  = display.newImageView(_res('ui/home/infor/settings_bg_2'),bottomImageSize.width/2 , bottomImageSize.height - 4  , { ap = display.CENTER_TOP , scale9 = true , size =  cc.size(980, 72) })
    bottomImageLayout:addChild(bgBottomImageTwo)
    local pushRemindLable = nil
    local remindCheckBtn = nil
    local narrateLabel = nil
    narrateLabel = display.newLabel(bottomImageSize.width/2 ,bottomImageSize.height- 95,
                                    fontWithColor('8' , { fontSize = 20 , color = "#9e8383" ,  text = __('请在iPhone的"设置" - "通知" 中进行修改' )}))
    bottomImageLayout:addChild(narrateLabel)
    local   oneLabel  = display.newLabel(bottomImageSize.width/2,bottomImageSize.height - 36,
    {
       fontSize = 24, font = TTF_GAME_FONT, color = "#5b3c24", ttf = true ,text = __('推送提醒')
    })
    remindCheckBtn = display.newCheckBox(0,0, {n = _res('ui/common/common_btn_check_default') , s= _res('ui/common/common_btn_check_selected') })
    local oneLabelSize = display.getLabelContentSize(oneLabel)
    remindCheckBtn:setTag(BUTTON_CLICK.REMIND_PUSH)
    local remindCheckBtnSize = remindCheckBtn:getContentSize()
    pushRemindLable = display.newLayer(bottomImageSize.width/2 ,bottomImageSize.height - 36 , {
        ap = display.CENTER  , size = cc.size(oneLabelSize.width +20 +  remindCheckBtnSize.width , remindCheckBtnSize.height)
    } )

    oneLabel:setPosition(cc.p(oneLabelSize.width/2 ,remindCheckBtnSize.height/2 ))
    remindCheckBtn:setPosition(cc.p(oneLabelSize.width +20 +  remindCheckBtnSize.height/2 ,remindCheckBtnSize.height/2 ))
    pushRemindLable:addChild(oneLabel)
    pushRemindLable:addChild(remindCheckBtn)
    bottomImageLayout:addChild(pushRemindLable)





    --local basicTitleImage =  display.newImageView(_res('ui/common/common_title_5.png'),layoutSize.width/2 , layoutSize.height - 35  )
    --layout:addChild(basicTitleImage)
    --local basicTitleSize = basicTitleImage:getContentSize()
    --
    --local basicTitleLabel = display.newLabel(basicTitleSize.width/2, basicTitleSize.height/2 ,fontWithColor('16', { ap = display.CENTER ,text = __('基本设置') }))
    --basicTitleImage:addChild(basicTitleLabel)

    --游戏语言标签
    local gameVoiceImage =  display.newImageView(_res('ui/common/common_title_5.png'),layoutSize.width/2 , layoutSize.height -265 )
    layout:addChild(gameVoiceImage,2)
    local gameVoiceSize = gameVoiceImage:getContentSize()

    local gameVoiceLabel = display.newLabel(gameVoiceSize.width/2, gameVoiceSize.height/2 ,fontWithColor('16', { ap =  display.CENTER ,text = __('语音设置') }))
    gameVoiceImage:addChild(gameVoiceLabel)

    local bgImageTwo = display.newImageView(_res("ui/common/common_bg_goods.png"), layoutSize.width/2 -2 ,layoutSize.height - 240 , { ap = display.CENTER_TOP , size = cc.size(982,249) , scale9 = true } )
    layout:addChild(bgImageTwo)
    --该方法使用控制声音和大小的
    local createControl = function (controlTable)
        --local bgImage = display.newImageView(_res('ui/home/infor/setup_bg_white.png'),0,0,{scale9 = true , size = cc.size(738,60)})
        local bgImage = display.newLayer(0,0, { ap = display.CENTER , size = cc.size(738,60) })
        local bgSize = bgImage:getContentSize()
        display.commonUIParams(bgImage, { po = cc.p(bgSize.width/2 , bgSize.height/2)  })
        local layout = CLayout:create(bgSize)
        layout:setPosition(cc.p(layoutSize.width/2,layoutSize.height - controlTable.height))
        layout:addChild(bgImage)
        --左边的label 说明
        local label =  display.newLabel(165 - 18,bgSize.height/2 , fontWithColor('16',  {fontSize = 20 ,  ap = display.RIGHT_CENTER, text = controlTable.name}))
        layout:addChild(label)
        local labelSize = display.getLabelContentSize(label)
        if labelSize.width > 250  then
            local currentScale = label:getScale()
            label:setScale(currentScale * 250/ labelSize.width)
        end

        local pSwitchControl = display.newCheckBox(165 - 25,bgSize.height/2,{n = _res('ui/home/infor/setup_btn_bg_close.png'),s = _res('ui/home/infor/setup_btn_bg_open.png'),ap =display.LEFT_CENTER})
        local openLabel =  display.newLabel( 57+72/2 + 3 ,pSwitchControl:getContentSize().height/2, fontWithColor('16',{  fontSize = 20 ,color = "#ffffff" ,text = __('打开')}) )
        --pSwitchControl.openLabel = openLabel
        openLabel:setTag(115)
        pSwitchControl:addChild(openLabel)
        local closeLabel =  display.newLabel(72/2 + 20,pSwitchControl:getContentSize().height/2, fontWithColor('16',{fontSize = 20 ,color = "#ffffff" , text = __('关闭')}) )
        pSwitchControl:addChild(closeLabel)
        --pSwitchControl.closeLabel = closeLabel
        closeLabel:setTag(116)
        local isChecked = CommonUtils.GetControlGameProterty(CONTROL_GAME[controlTable.senderName])
        pSwitchControl:setChecked(isChecked)
        layout:addChild(pSwitchControl)
        --pSwitchControl:setOnClickScriptHandler(handler(self,self.ButtonAction))
        pSwitchControl:setTag(BUTTON_CLICK[controlTable.senderName])
        pSwitchControl.data = controlTable
        openLabel:setVisible(isChecked)
        closeLabel:setVisible( not  isChecked)
        layout.pSwitchControl = pSwitchControl
        if not  controlTable.isShowSlider then
            return layout
        end
        local pSlider = cc.ControlSlider:create( _res("ui/home/infor/setup_volume_bg.png"),_res("ui/home/infor/setup_volume_bg.png") ,_res("ui/home/infor/setup_volume_btn.png"))
        pSlider:setAnchorPoint(cc.p(0.5, 1.0))
        pSlider:setMinimumValue(0.0)
        pSlider:setValue(CommonUtils.GetControlGameProterty(CONTROL_GAME_VLUE[controlTable.senderSliderName]))
        pSlider:setMaximumValue(1)
        pSlider:setAnchorPoint(display.LEFT_CENTER)
        pSlider:setPosition(cc.p(340 - 30, bgSize.height/2))
        pSlider:setTag(BUTTON_CLICK[controlTable.senderSliderName])
        layout:addChild(pSlider)
        --When the value of the slider will change, the given selector will be call
        pSlider:registerControlEventHandler(handler(self,self.ButtonAction), cc.CONTROL_EVENTTYPE_VALUE_CHANGED)
        pSlider.data = controlTable
        layout.pSlider = pSlider
        return layout
    end
    -- 这个表中openTag 为控制开关按钮, controlBigOrLittleTag 这个是控制声音大小
    local offset = 120
    local heightoffset = 65
    local controlTable = {
        {
            name = __('背景音乐'),
            height = offset ,
            senderName = CONTROL_GAME.CONRROL_MUSIC, --传入键值
            senderSliderName = CONTROL_GAME_VLUE.CONTREL_MUSIC_BIGORLITTLE,
            isShowSlider = true
        },
        {
            name = __('游戏音效'),
            height = offset+heightoffset,
            senderName = CONTROL_GAME.GAME_MUSIC_EFFECT ,
            senderSliderName = CONTROL_GAME_VLUE.CONTREL_GAME_EFFECT_BIGORLITTLE,
            isShowSlider = true
        },
        --{
        --    name = __('语音'),
        --    height = offset+heightoffset*2+ 90 ,
        --    senderSliderName = CONTROL_GAME_VLUE.CONTREL_GAME_VOICE_BIGORLITTLE,
        --    senderName = CONTROL_GAME.GAME_VOICE ,
        --    isShowSlider = false,
        --
        --}
    }
    local cellTable = {}
    for  i =1 , #controlTable do
        local layoutCell = createControl(controlTable[i])
        table.insert(cellTable, #cellTable+1 ,layoutCell )
        layout:addChild(layoutCell)
    end
    local bottomBgSize = cc.size(738,144)
    --这个值标志着居中的距离
    local alignCenterOffset = 15

    local createOpenVoice = function (openVocieContralTable)
        --左侧的label 叙述
        local bgSize =cc.size(270 , 60 )
        local voiceLayout =CLayout:create(bgSize)
        local label = display.newLabel(0,0,fontWithColor('16',{ ap = display.RIGHT_CENTER, text =openVocieContralTable.name}) )
        --右侧的按钮
        local button = display.newCheckBox(0,0 ,{n = _res('ui/common/common_btn_check_default.png') , s = _res('ui/common/common_btn_check_selected.png')})
        button:setTag( BUTTON_CLICK[openVocieContralTable.senderName] )
        local buttonSize = button:getContentSize()
        button.data = openVocieContralTable
        voiceLayout:setPosition(openVocieContralTable.po)
        label:setPosition(cc.p(bgSize.width - buttonSize.width , bgSize.height/2))
        voiceLayout:addChild(label)
        button:setPosition(cc.p(bgSize.width - buttonSize.width /2 , bgSize.height/2 ))
        voiceLayout:addChild(button)
        local  isChecked = CommonUtils.GetControlGameProterty(openVocieContralTable.senderName)
        button:setChecked(isChecked)
        voiceLayout.button = button
        return voiceLayout
    end
    local openVocieContralTable = {
        {
            name = __('仅在wifi下开启') ,
            senderName = CONTROL_GAME.ONELY_WIFI_OPEN,
            po = cc.p(layoutSize.width/2 +110 , layoutSize.height - 367+ 65 -18),
        },
        {
            name = __('世界语音自动播放') ,
            senderName = CONTROL_GAME.WORLD_VOICE_AUTO_PLAY,
            po = cc.p(bottomBgSize.width/4 + alignCenterOffset -14 , bottomBgSize.height/4*3 -20  ),
        },
        {
            name = __('工会语音自动播放')  ,
            po = cc.p(bottomBgSize.width/4*3 - alignCenterOffset +11 , bottomBgSize.height/4*3 -20 ),
            senderName = CONTROL_GAME.GUILD_VOICE_AUTO_PLAY,
        },
        {
            name = __('组队语音自动播放') ,
            po = cc.p(bottomBgSize.width/4*1 + alignCenterOffset -14, bottomBgSize.height/4 -18),
            senderName = CONTROL_GAME.FORM_TEAM_VOICE_AUTO_PLAY,

        },
        {
            name = __('私聊语音自动播放'),
            po = cc.p(bottomBgSize.width/4*3 - alignCenterOffset +11 , bottomBgSize.height/4 -18) ,
            senderName = CONTROL_GAME.PRIVATE_CHAT_VOICE_AUTO_PLAY,
        }
    }
    local wiftLayout = createOpenVoice(openVocieContralTable[1])
    layout:addChild(wiftLayout)
    --创建下部分内容
    local buttomLayout = CLayout:create(bottomBgSize)
    local bgImage = display.newLayer(bottomBgSize.width/2 , bottomBgSize.height/2,{ap = display.CENTER , size = cc.size(738,144)})
    buttomLayout:setPosition(cc.p(layoutSize.width/2 , layoutSize.height -  390+65  ))
    buttomLayout:setAnchorPoint(display.CENTER_TOP)
    buttomLayout:addChild(bgImage)
    buttomLayout:setAnchorPoint(display.CENTER_TOP)
    layout:addChild(buttomLayout)

    -- local facebookRelateButton = display.newButton(90,32,{n = _res('share/common_btn_facebook.png'), ap = display.CENTER ,cb = handler(self,self.ButtonAction)} )
    -- layout:addChild(facebookRelateButton)
    -- display.commonLabelParams(facebookRelateButton , fontWithColor('14',{text = __('邀請好友'),offset= cc.p(6,0)}) )
    -- facebookRelateButton:setTag(BUTTON_CLICK.FACEBOOK_BUTTON)
    -- local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
    -- if not gameMgr:GetUserInfo().openCodeModule then
        -- facebookRelateButton:setVisible(false)
    -- end
    local  reloadGameBtn  =display.newButton(layoutSize.width /2 + 150,32,{n = _res('ui/common/common_btn_orange.png'), ap = display.CENTER ,cb = handler(self,self.ButtonAction), scale9 = true,size = cc.size(124,62)} )
    self:addChild(reloadGameBtn)
    display.commonLabelParams(reloadGameBtn , fontWithColor('14',{text = __('重新登录'), paddingW = 20  }) )
    reloadGameBtn:setTag(BUTTON_CLICK.RELOADGAME)
    -- 退出游戏的按钮
    local  exitGameBtn  =display.newButton(layoutSize.width /2 -150,32,{n = _res('ui/common/common_btn_orange.png'), ap = display.CENTER ,cb = handler(self,self.ButtonAction) , scale9 = true } )
    self:addChild(exitGameBtn)
    display.commonLabelParams(exitGameBtn , fontWithColor('14',{text = __('退出游戏') , paddingW = 20}) )
    exitGameBtn:setTag(BUTTON_CLICK.EXITGAME)
    wiftLayout:setVisible(false)
    buttomLayout:setVisible(false)
    gameVoiceImage:setVisible(false)
    bgImageTwo:setVisible(false)
    -- 收集到的选择按钮
    local checkBoxTable = {}
    for i = 2 , # openVocieContralTable do
        local layoutVoice = createOpenVoice(openVocieContralTable[i])
        checkBoxTable[#checkBoxTable+1] = layoutVoice
        buttomLayout:addChild(layoutVoice)
    end
    local listSize = cc.size(980,490)

    local listView = CListView:create(listSize)
    listView:setDirection(eScrollViewDirectionVertical)
    listView:setBounceable(true)
    listView:insertNodeAtLast(layout)
    listView:setAnchorPoint(display.CENTER_TOP)
    listView:setPosition(layoutSize.width/2, layoutSize.height-20)
    listView:reloadData()
    self:addChild(listView)

    --self:addChild(layout)
    -- 设置的底部layout
    local voiceSize = cc.size(700 , 90)
    local voiceOneSize = cc.size(voiceSize.width/3 , voiceSize.height)

    local voiceSize = cc.size(700 , 90)
    local voiceLayout = display.newLayer(layoutSize.width /2 , layoutSize.height -40 ,{ ap = display.CENTER , size = voiceSize  } )
    layout:addChild(voiceLayout)
    voiceLayout:setVisible(false)
    local voiceOneSize = cc.size(voiceSize.width/3 , voiceSize.height)
    local japanseLayout = display.newLayer(voiceSize.width /3 * 0.5  ,voiceSize.height/2 ,
       { ap = display.CENTER , size = voiceOneSize } )
    voiceLayout:addChild(japanseLayout)
    -- 日文语音

    local japanseLabel
    if isNewUSSdk() then
        japanseLabel  = display.newLabel(voiceOneSize.width/2, voiceOneSize.height/2 ,
                                         { ap = display.RIGHT_CENTER , fontSize = 22, color = '#5b3c25', font = TTF_GAME_FONT, ttf = true , text = __('日文语音')})
    else
        japanseLabel  = display.newLabel(voiceOneSize.width/2, voiceOneSize.height/2 ,
                                         { ap = display.RIGHT_CENTER , fontSize = 22, color = '#5b3c25', font = TTF_GAME_FONT, ttf = true , text = __('英文语音')})

    end
    japanseLayout:addChild(japanseLabel)
    local japanseVoiceBtn = display.newCheckBox(voiceOneSize.width /2 , voiceOneSize.height/2 ,
    { ap = display.LEFT_CENTER , n = _res('ui/common/common_btn_check_default') , s= _res('ui/common/common_btn_check_selected') } )
    japanseLayout:addChild(japanseVoiceBtn)
    japanseVoiceBtn:setTag(BUTTON_CLICK.CHOOSE_JAPANESE_BTN)


    local chineseLayout = display.newLayer(voiceSize.width /3  * ( 2- 0.5 ) ,voiceSize.height/2 , { ap = display.CENTER , size = voiceOneSize } )
    voiceLayout:addChild(chineseLayout)
    -- 中文语音
    local chineseLabel
    if isNewUSSdk() then
        chineseLabel = display.newLabel(voiceOneSize.width/2, voiceOneSize.height/2 ,
                                        { ap = display.RIGHT_CENTER , fontSize = 22, color = '#5b3c25', font = TTF_GAME_FONT, ttf = true , text = __('中文语音')})
    else
        chineseLabel = display.newLabel(voiceOneSize.width/2, voiceOneSize.height/2 ,
                                        { ap = display.RIGHT_CENTER , fontSize = 22, color = '#5b3c25', font = TTF_GAME_FONT, ttf = true , text = __('日文语音')})
    end
    chineseLayout:addChild(chineseLabel)
    local lwidth = display.getLabelContentSize(chineseLabel).width
    if lwidth < 124 then lwidth = 124 end
    local chineseVoiceBtn = display.newCheckBox(voiceOneSize.width/2 , voiceOneSize.height/2 ,
        { ap = display.LEFT_CENTER  , n = _res('ui/common/common_btn_check_default') , s= _res('ui/common/common_btn_check_selected') } )
    chineseLayout:addChild(chineseVoiceBtn)
    voiceLayout:setVisible(false )
    chineseVoiceBtn:setTag(BUTTON_CLICK.CHOOSE_CHINESE_BTN)

    local additionalBtn = display.newButton(voiceSize.width * 2.5/3 , voiceSize.height/2 ,
        {n = _res('ui/common/common_btn_orange'),
                s =  _res('ui/common/common_btn_orange'), scale9 = true, size = cc.size(lwidth + 30, 62)
        }  )
    if isNewUSSdk() then
        display.commonLabelParams(additionalBtn , fontWithColor('8' , { text = __('中文语音')} ))
    else
        display.commonLabelParams(additionalBtn , fontWithColor('8' , { text = __('日文语音')} ))
    end
    voiceLayout:addChild(additionalBtn)
    additionalBtn:setTag(BUTTON_CLICK.CHOOSE_CHINESE_ADD_BTN)
    local createPushLayout =  function (data)
        -- 推送的layout
        local pushSize = cc.size(270,70)
        local pushLayout = display.newLayer(0,0, { ap = display.CENTER , size = pushSize})
        local pushBtn = display.newCheckBox(pushSize.width , voiceOneSize.height/2 ,
        { ap = display.RIGHT_CENTER  , n = _res('ui/home/infor/setup_btn_bg_close') ,
                s= _res('ui/home/infor/setup_btn_bg_open')  } )
        local pushBtnSize  = pushBtn:getContentSize()
        -- 打开的label
        local openLabel =  display.newLabel( 57+72/2 + 3,pushBtnSize.height/2, fontWithColor('16',{  fontSize = 20 , color  =  "#ffffff" ,text = __('打开')}) )
        openLabel:setTag(115)
        pushBtn:addChild(openLabel)
        pushBtn:setTag(data.tag)
        pushBtn:setChecked(data.isShowSlider)
        openLabel:setVisible(data.isShowSlider)
        -- 关闭的label
        local closeLabel =  display.newLabel(72/2 + 20,pushBtnSize.height/2, fontWithColor('16',{fontSize = 20 ,  color  =  "#ffffff" ,text = __('关闭')}) )
        closeLabel:setTag(116)
        pushBtn:addChild(closeLabel)
        pushLayout:addChild(pushBtn)
        pushBtn:setName("pushBtn")
        closeLabel:setVisible(not  data.isShowSlider)
        if isJapanSdk() then
            local pushNameLabel = display.newLabel(pushSize.width - 150 , voiceOneSize.height * 0.5 ,
                fontWithColor('8',{ap = display.RIGHT_CENTER , text = data.name}) )
            pushLayout:addChild(pushNameLabel)
        else
            local pushNameLabel = display.newLabel(pushSize.width - 130 , pushSize.height * 0.5 ,
                fontWithColor('8',{ap = display.RIGHT_CENTER , text = data.name, w = 160, reqH = 60}) )
            pushLayout:addChild(pushNameLabel)
        end

        return pushLayout
    end

    local pushData = {
        { name = __('体力回满'), tag = BUTTON_CLICK.HP_FULL_PUSH_LOCAL , isShowSlider = true   },
        { name = __('空运刷新'), tag = BUTTON_CLICK.AIR_TAKEAWAY_PUSH_LOCAL , isShowSlider = true,          switch = MODULE_SWITCH.AIR_TRANSPORTATION  },
        { name = __('爱心便当'), tag = BUTTON_CLICK.LOVE_FOOD_RECOVER_PUSH_LOCAL , isShowSlider = true },
    }
    if CommonUtils.UnLockModule(tostring(RemindTag.PUBLIC_ORDER))   then
        table.insert(pushData,#pushData+1,{ name = __('公有订单刷新') , tag = BUTTON_CLICK.PUBLISH_ORDER_RECOVER_LOCAL , isShowSlider = true,  switch = MODULE_SWITCH.PUBLIC_ORDER })
    end

    local pushLayoutSize = cc.size(984, 140)
    if CommonUtils.UnLockModule(tostring(RemindTag.WORLD_BOSS)) then
        table.insert(pushData,#pushData+1,{ name = __('世界boss') , tag = BUTTON_CLICK.WORLD_BOSS_PUSH , isShowSlider = true,  switch = MODULE_SWITCH.WORLD_BOSS })
    end
    local pushLayout = display.newLayer(bottomImageSize.width/2 ,bottomImageSize.height  -110 , {ap = display.CENTER_TOP , size = pushLayoutSize   } )
    bottomImageLayout:addChild(pushLayout)
    local pushTable = {}

    for i = 1 , #pushData do
        print((#pushData - i + 0.5  ) /3 + 0.3)
        if not pushData[i].switch or CommonUtils.GetModuleAvailable(pushData[i].switch) then
            local layout = createPushLayout(pushData[i])
            layout:setPosition(cc.p((i - 0.5)%3 * bottomImageSize.width/3 , (2 - math.ceil( i / 3 )) *pushLayoutSize.height /2    +  25  )   )
            bottomImageLayout:addChild(layout)
            pushTable[tostring(pushData[i].tag)] = layout
        end
    end
    local worldData = {
        { name = __('顶部滚动信息'), tag = BUTTON_CLICK.MARQUEE_PUSH },
        { name = __('聊天信息'), tag = BUTTON_CLICK.CHAT_PUSH  }

    }
    local worldSize =  cc.size(984 , 100)
    local worldLayout = display.newLayer(layoutSize.width/2 ,layoutSize.height -235 ,{ap = display.CENTER_TOP , size = cc.size(984 , 100) } )
    layout:addChild(worldLayout)

    local worldBottomImage  = display.newImageView(_res('ui/home/infor/settings_bg_1'),worldSize.width/2 , worldSize.height/2 , {scale9 = true , size = worldSize  })
    worldLayout:addChild(worldBottomImage)
    local worldTable = {}
    for i =1 ,#worldData do
        local layout = createPushLayout(worldData[i])
        layout:setPosition(cc.p((i - 0.5)%3 * worldSize.width/3 ,worldSize.height/2-10 ))
        worldLayout:addChild(layout)
        worldTable[tostring(worldData[i].tag)] = layout
    end
    self.viewData =  {
        view            = layout,
        wiftLayout      = wiftLayout,
        buttomLayout    = buttomLayout,
        checkBoxTable   = checkBoxTable,
        cellTable       = cellTable,
        exitGameBtn     = exitGameBtn,
        reloadGameBtn   = reloadGameBtn,
        -- facebookRelateButton = facebookRelateButton,
        ---------------语音包的显示 -----------------------
        japanseVoiceBtn = japanseVoiceBtn,
        chineseVoiceBtn = chineseVoiceBtn,
        additionalBtn   = additionalBtn,
        voiceLayout     = voiceLayout,
        japanseLayout   = japanseLayout,
        chineseLayout   = chineseLayout,
        voiceSize       = voiceSize,
        remindCheckBtn  = remindCheckBtn ,
        narrateLabel    = narrateLabel ,
        pushRemindLable =  pushRemindLable,
        chineseLabel    = chineseLabel ,
        pushTable       = pushTable,
        worldTable      = worldTable,
    }
end
return PersonInformationSystemView
