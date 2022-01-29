---
--- Created by xingweihao.
--- DateTime: 25/10/2017 5:35 PM
---

---@class PersonInformationDetailView
local PersonInformationDetailView = class('home.PersonInformationDetailView',function ()
    local node = CLayout:create( cc.size(984,562)) --cc.size(984,562)
    node.name = 'Game.views.PersonInformationDetailView'
    node:enableNodeEvents()
    return node
end)
----dasdasd
-- tianjia
---@type GameManager
local RED_TAG = 1115
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local BUTTON_CLICK = {
    MEDAL_HONOR            = 1009, -- 勋章墙
    ENTERTAIN              = 1010, -- 飨灵屋
    MESSAGE_BOARD          = 1011, -- 留言板
    CHANGE_DECR_TEXT       = 1102, -- 修改玩家的签名
    CHANGE_PLAYER_NAME     = 1103, -- 修改玩家的签名
    CHANGE_PLAYER_HEADER   = 1104, -- 修改玩家的头像
    CHANGE_DECR            = 1105,
    BINDING_TELL_NUM       = 1106, -- 绑定手机号
    THUMB_UP               = 1107, --点赞按钮
    CHANGE_LAYOUT_TAG      = 1108, --修改的layout
    CHANGE_HEAD            = 1109, -- 修改头像
    CHANGE_HEAD_FRAME      = 1110, -- 修改头像框
    CHANGE_BG_CLOSE_LAYOUT = 1111, -- 关闭修改layout
    LEVEL_TIP_DESCR        = 1112, -- 等级提示的叙述
    MORE_PERSON_INFO_BTN   = 1113, -- 更多信息显示的BTN
    BIRTH_DAY_BTN          = 1114, -- 显示用户的生日信息
    CUSTOM_SERVICE_BTN     = 1115, -- 客服中心
}

function PersonInformationDetailView:ctor()
    self:initUI()
end

function PersonInformationDetailView:initUI()

    local layoutSize = cc.size(984,562)
    local layout = display.newLayer(layoutSize.width/2, layoutSize.height/2,{ ap =  display.CENTER , size = layoutSize })
    self:addChild(layout)
    local leftSize = cc.size(380,layoutSize.height)
    local LeftLayout =  display.newLayer(0 , layoutSize.height/2  ,{ ap =  display.LEFT_CENTER , size = leftSize })
    layout:addChild(LeftLayout,2)
    local rewardDiamond = nil

    -- 更换头像框容器
    local changeHeadLayout =  display.newLayer(leftSize.width/2  , leftSize.height/2  ,{ ap =  display.CENTER , size = leftSize })
    LeftLayout:addChild(changeHeadLayout,21)
    changeHeadLayout:setVisible(false)
    --changeLayout:setVisible(false)
    local  changeBgSize =  cc.size(138,140)
    -- 吞噬层
    local changeBgContentLayout =  display.newLayer(leftSize.width/2  , leftSize.height/2  ,{ ap =  display.CENTER , size = leftSize ,color = cc.r4b(0,0,0,0)   , enable = true })
    changeHeadLayout:addChild(changeBgContentLayout)
    changeBgContentLayout:setTag(BUTTON_CLICK.CHANGE_BG_CLOSE_LAYOUT)
    -- 内部的吞噬层
    local changeContentLayout =  display.newLayer(204 , leftSize.height - 167,{ ap =  display.CENTER , size = changeBgSize })
    changeHeadLayout:addChild(changeContentLayout)
    local changeSwallowContentLayout =  display.newLayer(changeBgSize.width/2 , changeBgSize.height /2,
    { ap =  display.CENTER , size = changeBgSize ,color = cc.c4b(0,0,0,0)  })
    changeContentLayout:addChild(changeSwallowContentLayout)
    local changeBgImage  = display.newImageView(_res('ui/home/infor/personal_information_bg_head_btn.png'),changeBgSize.width/2 , changeBgSize.height /2
    ,{ ap =  display.CENTER , scale9 = true , size = changeBgSize})
    changeContentLayout:addChild(changeBgImage)
    --修改头像按钮
    local changeHeadBtn = display.newButton(changeBgSize.width/2 , changeBgSize.height/4 * 3  -2,
                    { n = _res('ui/common/common_btn_orange.png') , s =  _res('ui/common/common_btn_orange.png')})

    display.commonLabelParams(changeHeadBtn , fontWithColor('14' , { text = __('头像') ,reqW = 120}))
    changeContentLayout:addChild(changeHeadBtn)
    changeHeadBtn:setTag(BUTTON_CLICK.CHANGE_HEAD)
    -- 修改头像框按钮
    local changeFrameBtn = display.newButton(changeBgSize.width/2 , changeBgSize.height/4 * 1 +2 , { n = _res('ui/common/common_btn_orange.png') , s =  _res('ui/common/common_btn_orange.png')})
    changeContentLayout:addChild(changeFrameBtn)
    display.commonLabelParams(changeFrameBtn , fontWithColor('14' , { text = __('头像框')}))
    changeFrameBtn:setTag(BUTTON_CLICK.CHANGE_HEAD_FRAME)
    -- 头像框的修改
    local headerNode = require('root.CCHeaderNode').new(
        {bg = _res('ui/home/infor/setup_head_bg_2.png') , pre =  gameMgr:GetUserInfo().avatarFrame , isPre = true })
    display.commonUIParams(headerNode,{po = cc.p(leftSize.width/2+10, layoutSize.height - 13), ap = display.CENTER_TOP})
    LeftLayout:addChild(headerNode)
    headerNode:setScale(0.8)

    -- 更换头像
    local changeHeadLabel = display.newLabel(leftSize.width/2+10  ,  layoutSize.height -125 , fontWithColor('14' , { text = __('更换') , color   = "#fefade" , outline = "#5b3c25", outlineSize = 1 }) )
    LeftLayout:addChild(changeHeadLabel)
    --玩家名称
    local offsetWidth = 15

    local  playerIDLabel   =  display.newRichLabel(5 ,leftSize.height - 20  , {  ap = display.LEFT_CENTER , c = {
        fontWithColor('16' ,{   text ="UID:" }) ,
        fontWithColor('6' ,{ text = gameMgr:GetUserInfo().playerId })
    }}  )
    LeftLayout:addChild(playerIDLabel)

    local  playerIDLabelValue   =  display.newLabel(offsetWidth ,leftSize.height - 20  ,
            fontWithColor('6' ,{ text = ""  , ap = display.LEFT_CENTER })
    )
    LeftLayout:addChild(playerIDLabelValue)

    local playerInfoSize = cc.size(leftSize.width ,150)
    local playerInfoLayout = display.newLayer(leftSize.width/2  ,leftSize.height -  140 , {size = playerInfoSize  , ap = display.CENTER_TOP  } )
    local playerLabel = display.newLabel(leftSize.width/2,playerInfoSize.height -20 , fontWithColor('16' ,{ ap = display.CENTER  ,fontSize = 26, text = ""}) )
    playerInfoLayout:addChild(playerLabel)
    LeftLayout:addChild(playerInfoLayout,20)
    local playerLabelBg =  display.newImageView(_res('ui/home/infor/personal_information_bg_name_bg.png'),leftSize.width/2  ,playerInfoSize.height -20 , { ap = display.CENTER , scale9 = true , size = cc.size(360,35)  })
    playerInfoLayout:addChild(playerLabelBg , -1)

    local  changeNameBtn = display.newCheckBox(playerInfoSize.width - 25 ,playerInfoSize.height - 20 , { enable = true , n = _res('ui/home/infor/setup_btn_name_revise.png') , s = _res('ui/home/infor/setup_btn_name_revise.png')})
    playerInfoLayout:addChild(changeNameBtn)
    changeNameBtn:setTag(BUTTON_CLICK.CHANGE_PLAYER_NAME)
	if isEliteSDK() then
		changeNameBtn:setVisible(false)
	end
    local bindingBtn = display.newButton(leftSize.width/2   ,50,{
        n = _res('ui/common/common_btn_orange.png'),ap = display.CENTER
    })
    local bindingBtnSize = bindingBtn:getContentSize()
    bindingBtn:setTag(BUTTON_CLICK.BINDING_TELL_NUM)
    -- 添加小红点
    local image = display.newImageView(_res('ui/common/common_hint_circle_red_ico.png'))
    image:setTag(RED_TAG)
    image:setPosition(cc.p(bindingBtnSize.width , bindingBtnSize.height))
    image:setVisible(false)
    bindingBtn:addChild(image,10)

    display.commonLabelParams(bindingBtn,fontWithColor(14,{fontSize = 22 ,text = "" }))
    if not isElexSdk() then
        if CommonUtils.GetIsOpenPhone() then
            if checkint(gameMgr:GetUserInfo().isFirstPhoneLock)  == 1  then  -- 如果是首次绑定获取100 幻晶石
                local iconPath = CommonUtils.GetGoodsIconPathById(DIAMOND_ID)
                rewardDiamond = display.newRichLabel(leftSize.width/2    , 10 , { r = true , c =  {
                            fontWithColor(16, { fontSize = 20 , text = string.format(__('首次绑定奖励%d') , 100)}) ,
                            {img =  iconPath  , scale =  0.2  }
                    }})
                LeftLayout:addChild(rewardDiamond)
                if not gameMgr:GetUserInfo().openCodeModule then
                    rewardDiamond:setVisible(false)
                end
            end
        else
            bindingBtn:setVisible(false)
        end
        if not gameMgr:GetUserInfo().openCodeModule then
            bindingBtn:setVisible(false)
        end
    end
    LeftLayout:addChild(bindingBtn)
    local accountBtn = nil
    if isElexSdk() then
        display.commonLabelParams(bindingBtn, fontWithColor(14, {text = __("幫助")}))
        display.commonUIParams(bindingBtn, {po = cc.p(leftSize.width * 0.5 - 4,40) })
        bindingBtn:setNormalImage(_res('ui/common/common_btn_white_default'))
        bindingBtn:setSelectedImage(_res("ui/common/common_btn_white_default"))
        accountBtn  = display.newButton(leftSize.width * 0.2 - 18,40,{
                n = _res('ui/common/common_btn_orange.png'),ap = display.CENTER
            })
        display.commonLabelParams(accountBtn, fontWithColor(14, {text = __("賬號")}))
        accountBtn:setTag(1211)
        local image = display.newImageView(_res('ui/common/common_hint_circle_red_ico.png'))
        image:setTag(RED_TAG)
        image:setPosition(cc.p(bindingBtnSize.width , bindingBtnSize.height))
        if app.gameMgr:GetUserInfo().isGuest == 1 then
            image:setVisible(true)
        else
            image:setVisible(false)
        end

        accountBtn:addChild(image)
        accountBtn:setOnClickScriptHandler(function(sender)
            PlayAudioByClickClose()
            local mediator = require('Game.mediator.ElexBindingMediator').new()
            AppFacade.GetInstance():RegistMediator(mediator)
        end)
        LeftLayout:addChild(accountBtn)
        if not isNewUSSdk() then
            if  checkint(gameMgr:GetUserInfo().isGuest) ~= 0 and  checkint(gameMgr:GetUserInfo().isBindAccountDrawn) == 0 then
                local iconPath = CommonUtils.GetGoodsIconPathById(DIAMOND_ID)
                rewardDiamond = display.newRichLabel(leftSize.width/2    , 10 , { r = true , c =  {
                    fontWithColor(16, { fontSize = 20 , text = string.format(__('首次绑定奖励%d') , 100)}) ,
                    {img =  iconPath  , scale =  0.2  }
                }})
                LeftLayout:addChild(rewardDiamond)
            end

            local faqButton = display.newButton(leftSize.width * 0.8 + 14,40,{
                    n = _res('ui/common/common_btn_white_default'),ap = display.CENTER
                })
            display.commonLabelParams(faqButton, fontWithColor(14, {text = __("FAQ"),w = 120 , hAlign = display.TAC,reqH  = 45 }))
            faqButton:setTag(1212)
            faqButton:setOnClickScriptHandler(function(sender)
                PlayAudioByClickNormal()
                if device.platform == 'android' and FTUtils:getTargetAPIVersion() >= 16 then
                    local AppSDK = require('root.AppSDK')
                    AppSDK:AIHelper({isShowFAQs = true})
                else
                    --直接调用sdk的方法
                    local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
                    local userInfo = gameMgr:GetUserInfo()
                    ECServiceCocos2dx:setUserId(userInfo.playerId)
                    ECServiceCocos2dx:setUserName(userInfo.playerName)
                    ECServiceCocos2dx:setServerId(userInfo.serverId)
                    local lang = i18n.getLang()
                    local tcountry = string.split(lang, '-')[1]
                    if not tcountry then tcountry = 'en' end
                    if tcountry == 'zh' then tcountry = 'zh_TW' end
                    local config = {
                        showContactButtonFlag = "1" ,
                        showConversationFlag = "1" ,
                        directConversation = "1"
                    }
                    ECServiceCocos2dx:setSDKLanguage(tcountry)
                    ECServiceCocos2dx:showFAQs(config)
                end)
                LeftLayout:addChild(faqButton)
            end
        end
    else
        bindingBtn:setVisible(false)
        if rewardDiamond then
            rewardDiamond:setVisible(false)
        end
        if isKoreanSdk() then
            local faqButton = display.newButton(leftSize.width * 0.5 ,40,{
                    n = _res('ui/common/common_btn_orange.png'),ap = display.CENTER
                })
            display.commonLabelParams(faqButton, fontWithColor(14, {text = __("客服中心"),w = 140 , hAlign = display.TAC,reqH  = 45 }))
            faqButton:setOnClickScriptHandler(function(sender)
                PlayAudioByClickNormal()
                local AppSDK = require('root.AppSDK')
                AppSDK.GetInstance():PlatformBugReport()
            end)
            LeftLayout:addChild(faqButton)
        end
    end


    local popularityImage = display.newImageView(_res('ui/home/infor/personal_information_bg_popularity.png'),leftSize.width/2 ,  playerInfoSize.height - 75 , { ap = display.CENTER , scale9 = true , size = cc.size(270,35)})
    playerInfoLayout:addChild(popularityImage)

    --玩家等级
    local levelLabel =  display.newRichLabel(offsetWidth  + 56,playerInfoSize.height  - 75   , { ap = display.LEFT_CENTER , c = {
        fontWithColor('16' ,{   text ="UID:" })
    }}  )
    playerInfoLayout:addChild(levelLabel)

    local levelTipBtn = display.newButton(leftSize.width/2 + 100 ,playerInfoSize.height  - 75,{n = _res('ui/common/common_btn_tips.png') , scale = 0.9 } )
    if GAME_MODULE_OPEN.PERSON_EXP_DESCR then
        levelTipBtn = display.newButton(leftSize.width/2 + 100 ,playerInfoSize.height  - 75,{n = _res('ui/common/common_btn_up_arrow.png')} )
    end
    playerInfoLayout:addChild(levelTipBtn)
    levelTipBtn:setScale(0.9)
    levelTipBtn:setTag(BUTTON_CLICK.LEVEL_TIP_DESCR)
    levelTipBtn:setVisible(false)
    local  levelLabelValue   =  display.newLabel(offsetWidth ,playerInfoSize.height - 60  ,
    fontWithColor('6' ,{ text = ""  , ap = display.LEFT_CENTER })
    )
    playerInfoLayout:addChild(levelLabelValue)
    -- 修改名称的按钮


    -- 欢迎iamge
    local popularityImage = display.newImageView(_res('ui/home/infor/personal_information_bg_popularity.png'),leftSize.width/2 ,  playerInfoSize.height - 125 , { ap = display.CENTER , scale9 = true , size = cc.size(270,35)})
    playerInfoLayout:addChild(popularityImage)
    local  popularityImageSize = popularityImage:getContentSize()

    local  popularityLabel   =  display.newRichLabel( 15,popularityImageSize.height/2  , { ap = display.LEFT_CENTER , c = {
        fontWithColor('16' ,{   text = "" })
    }}  )
    popularityImage:addChild(popularityLabel)

    -- 人气的数据
    local  popularityLabelValue   =  display.newLabel(offsetWidth ,playerInfoSize.height - 60  ,
    fontWithColor('6' ,{ text = ""  , ap = display.LEFT_CENTER })
    )
    popularityImage:addChild(popularityLabelValue)
    -- 点赞的按钮
    local landDefaultImage = display.newButton(leftSize.width /2 + 95 ,  playerInfoSize.height - 123 , { ap = display.LEFT_CENTER  ,
        n =  _res('ui/home/infor/personal_information_btn_laud_default.png'),
        s = _res('ui/home/infor/personal_information_btn_laud_default.png'),
        d =_res('ui/home/infor/personal_information_btn_laud_select.png') })
    playerInfoLayout:addChild(landDefaultImage)
    landDefaultImage:setTag(BUTTON_CLICK.THUMB_UP)
    --popularityImage:setVisible(false)
    --landDefaultImage:setVisible(false)

	local  personMoreBtn = display.newButton(leftSize.width+3 , leftSize.height - 335 , {
	n = _res("ui/home/infor/personal_information_btn_more") , ap = display.RIGHT_CENTER
	})
	personMoreBtn:getLabel():setAnchorPoint(display.LEFT_CENTER)
	display.commonLabelParams(personMoreBtn , { text = __('更多')  , color = '#5b3c25', offset = cc.p(-40, 0)  , fontSize = 20 })
	LeftLayout:addChild(personMoreBtn)
	personMoreBtn:setTag(BUTTON_CLICK.MORE_PERSON_INFO_BTN)




    local changeSize = cc.size(370,100)
    -- 修改姓名的layout
    local changeLayout = display.newLayer( leftSize.width/2,leftSize.height - 365 , { ap = display.CENTER_TOP,size = changeSize})
    LeftLayout:addChild(changeLayout)
    local autographIamge =  display.newImageView(_res('ui/home/infor/personal_information_bg_autograph.png'),changeSize.width/2 ,  changeSize.height / 2, { ap = display.CENTER  })
    changeLayout:addChild(autographIamge)
    -- 修改按钮
    local changeLabel = display.newLabel(changeSize.width/2,20, {ap  = display.CENTER, fontSize = 20, color = '#7c7c7c',text = __('点击修改')} )
    local changeLabelContent = display.newLayer(changeSize.width/2,changeSize.height/2 , {ap  = display.CENTER,size = changeSize })
    changeLayout:addChild(changeLabelContent,10)
    changeLabelContent:addChild(changeLabel)

	local changeLabelContent2 = display.newLayer(changeSize.width/2,changeSize.height/2 , {ap  = display.CENTER,size = changeSize ,
																						  color = cc.c4b(0,0,0,0)
	, enable = true })
	changeLabelContent2:setTag(BUTTON_CLICK.CHANGE_DECR)
	changeLabelContent:addChild(changeLabelContent2)

    -- 叙述按钮
    local decLabel = display.newRichLabel(0,0,{ap =display.CENTER_BOTTOM ,  w = 25   ,c = {fontWithColor('6', { text = "" })}})
    --changeLabelContent:addChild(decLabel)
	local scrollViewSize = cc.size(360,60)
	local scrollView = CListView:create(scrollViewSize)
	scrollView:setDirection(eScrollViewDirectionVertical)
	scrollView:setAnchorPoint(display.CENTER_TOP)
	scrollView:setPosition(changeSize.width/2  ,changeSize.height - 10)
	changeLabelContent:addChild(scrollView,10)
	local decLabelSize  = decLabel:getContentSize()
	local decLabelLayout = display.newLayer(0,0,{size= cc.size(360, decLabelSize.height) })
	decLabelLayout:addChild(decLabel)

	scrollView:insertNodeAtLast(decLabelLayout)
    local descrName = ccui.EditBox:create(cc.size(changeSize.width, 100), _res('ui/author/login_bg_Accounts_info.png'))
    display.commonUIParams(descrName, {po = cc.p(changeSize.width/2, changeSize.height * 0.5)})
    changeLayout:addChild(descrName)
    descrName:setFontSize(fontWithColor('M2PX').fontSize)
    descrName:setFontColor(ccc3FromInt('#9f9f9f'))
    descrName:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
    descrName:setPlaceHolder(__('请输入'))
    descrName:setPlaceholderFontSize(fontWithColor('M2PX').fontSize)
    descrName:setPlaceholderFontColor(ccc3FromInt('#9c9c9c'))
    descrName:setVisible(false)
    descrName:setMaxLength(100)
    descrName:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
    descrName:setTag(BUTTON_CLICK.CHANGE_DECR_TEXT)

    -- 增加一个客服中心的跳转按钮，此功能只用于韩服
    local customServiceBtn = ui.button({n = _res('ui/common/common_btn_orange.png'), tag = BUTTON_CLICK.CUSTOM_SERVICE_BTN}):updateLabel({fnt = FONT.D14, text = __("客服中心"), reqW = 100})
    LeftLayout:addList(customServiceBtn):alignTo(nil, ui.cb, {offsetY = 10})

    -- 右侧的layoutSize
    local rightSize =  cc.size(603 , 562)
    local rightLayout = display.newLayer(layoutSize.width + 5, layoutSize.height ,{ap = display.RIGHT_TOP ,  size = rightSize  })
    layout:addChild(rightLayout)

    local buttonSize = cc.size(196, 62)

    local buttonTable = {
        {name = __('飨灵屋'), tag = BUTTON_CLICK.ENTERTAIN},
        {name = __('勋章墙') , tag = BUTTON_CLICK.MEDAL_HONOR},
        {name = __('留言板'), tag = BUTTON_CLICK.MESSAGE_BOARD}
    }
    local buttonLayoutSize =  cc.size(buttonSize.width * (#buttonTable),buttonSize.height )
    local buttonLayout = display.newLayer(rightSize.width /2-2 , 0 , { ap = display.CENTER_BOTTOM , size = buttonLayoutSize })
    local tagBgImage  =  display.newImageView(_res('ui/home/infor/personal_information_tab_bg.png'),buttonLayoutSize.width/2 ,  buttonLayoutSize.height/2, { ap = display.CENTER  })
    buttonLayout:addChild(tagBgImage)
    rightLayout:addChild(buttonLayout,1)
    local buttonCollect = {}
    local button = nil
    for i =1 , #buttonTable do
        button = display.newCheckBox(buttonSize.width* (i - 0.5 ) , buttonSize.height/2 -2, { n = _res('ui/home/infor/personal_information_btn_default.png') , s = _res('ui/home/infor/personal_information_btn_select.png') } )
        button:setTag(buttonTable[i].tag)
        buttonLayout:addChild(button)
        buttonCollect[tostring(buttonTable[i].tag)] = button
        local label = display.newLabel(buttonSize.width/2 ,buttonSize.height/2 , fontWithColor('14' ,{ text =buttonTable[i].name ,w = 170 , reqH = 50 , hAlign = display.TAC }))
        button:addChild(label)
        if buttonTable[i].tag ==  BUTTON_CLICK.MESSAGE_BOARD  then
            local bindingBtnSize = button:getContentSize()
            local image = display.newImageView(_res('ui/common/common_hint_circle_red_ico.png'))
            image:setTag(RED_TAG)
            image:setPosition(cc.p(bindingBtnSize.width , bindingBtnSize.height))
            image:setVisible(false)
            button:addChild(image,10)
        end
    end
    local showSize = cc.size(603 , 496)
    local showLayout = display.newLayer(rightSize.width/2 , rightSize.height , { size = showSize  , ap = display.CENTER_TOP})
    rightLayout:addChild(showLayout)
    self:setVisible(false)

	local birthdaySize = cc.size(78,80)
	local birthBtn = display.newButton(leftSize.width , leftSize.height , {ap = display.RIGHT_TOP , color = cc.r4b(), size = birthdaySize})
	local birthImage = display.newImageView(_res('ui/home/infor/personal_information_btn_birthday'),birthdaySize.width/2 , birthdaySize.height/2)
	birthBtn:addChild(birthImage)
	LeftLayout:addChild(birthBtn)
	birthBtn:setTag(BUTTON_CLICK.BIRTH_DAY_BTN)
	birthBtn:setVisible(false)
	local bornLabel = display.newLabel(birthdaySize.width/2-8 , birthdaySize.height/2-8 , fontWithColor(10, {color = "#5b3c25" , text = __('诞生日')}))
	birthBtn:addChild(bornLabel)

	bornLabel:setRotation(45)

	local image = display.newImageView(_res('ui/common/common_hint_circle_red_ico.png'))
	image:setTag(RED_TAG)
	image:setPosition(cc.p(birthdaySize.width , birthdaySize.height))
	image:setVisible(false)
	birthBtn:addChild(image,10)

    self.viewData = {
        headerNode            = headerNode,
        LeftLayout            = LeftLayout,
        playerLabel           = playerLabel,
        playerIDLabel         = playerIDLabel,
        levelLabel            = levelLabel,
        changeNameBtn         = changeNameBtn,
        popularityLabel       = popularityLabel,
		personMoreBtn         = personMoreBtn ,
        changeLabel           = changeLabel,
        levelTipBtn           = levelTipBtn,
        changeLabelContent    = changeLabelContent,
		changeLabelContent2   = changeLabelContent2,
		decLabelLayout    	  = decLabelLayout,
        descrName             = descrName,
        landDefaultImage      = landDefaultImage,
        decLabel              = decLabel,
		scrollView        	  = scrollView,
        buttonCollect         = buttonCollect,
        rewardDiamond         = rewardDiamond,
        showLayout            = showLayout,
        bindingBtn            = bindingBtn,
		birthBtn              = birthBtn ,
        changeLayout          = changeLayout,
        changeFrameBtn        = changeFrameBtn,
        changeHeadBtn         = changeHeadBtn,
        changeHeadLayout      = changeHeadLayout,
        changeHeadLabel       = changeHeadLabel,
        popularityLabelValue  = popularityLabelValue,
        levelLabelValue       = levelLabelValue,
        playerIDLabelValue    = playerIDLabelValue,
        customServiceBtn      = customServiceBtn,
        changeBgContentLayout = changeBgContentLayout
    }
end

function PersonInformationDetailView:CreatePersonInforLayout(sender)
	local pos = cc.p(sender:getPosition())
	local senderParent = sender:getParent()
	pos.y = pos.y -15
	local worldPos = senderParent:convertToWorldSpace(pos)
	local personInforLayer = display.newLayer(display.cx , display.cy , {color = cc.c4b(0,0,0,0) ,size = display.size , ap = display.CENTER , enable = true  })
	display.commonUIParams(personInforLayer , { cb = function()
		personInforLayer:removeFromParent()
	end})
	app.uiMgr:GetCurrentScene():AddDialog(personInforLayer)

	local nodePos = personInforLayer:convertToNodeSpace(worldPos)
	local bgTipSize =  cc.size(265 , 194 )
	local bgTipLayout = display.newLayer(nodePos.x   , nodePos.y + 20  , { size = bgTipSize  , ap = display.LEFT_CENTER })
	local bgTipImage = display.newImageView(_res('ui/common/common_bg_tips') , bgTipSize.width/2 +50 , bgTipSize.height/2 , {scale9 = true , size = cc.size(365 , 194 )})
	bgTipLayout:addChild(bgTipImage)
	personInforLayer:addChild(bgTipLayout)

	local bgTipHorn = display.newImageView(_res('ui/common/common_bg_tips_horn') ,2.5 , bgTipSize.height/2)
	bgTipHorn:setRotation(-90)
	bgTipLayout:addChild(bgTipHorn)

	local collectSize =  cc.size(265 , 120 )
	local collectLayout = display.newLayer( bgTipSize.width /2  ,bgTipSize.height /2 + 25 , { ap = display.CENTER,size = collectSize})
	bgTipLayout:addChild(collectLayout)

	-- 餐厅的等级
	local height = 36
	local width = 10
	local cardCollectLabel = display.newRichLabel( 10 +width, 105,{   ap = display.LEFT_CENTER , c = {
		fontWithColor('16' ,{   text = "" })
	}}  )
	collectLayout:addChild(cardCollectLabel)

	-- 皮肤的收集进度
	local cardSkinNum = display.newRichLabel( 10 +width, 105 - height  ,  {  ap = display.LEFT_CENTER , c = {
		fontWithColor('16' ,{   text = "" })
	}}  )
	collectLayout:addChild(cardSkinNum)


	-- 餐厅的等级
	local restaurtantLabel = display.newRichLabel( 10 +width,105 - height * 2, { ap = display.LEFT_CENTER , c = {
		fontWithColor('16' ,{   text = ""})
	}}  )
	collectLayout:addChild(restaurtantLabel)
	-- 塔的最高层
	local towerMaxFooler = display.newRichLabel( 10 +width,105 - height * 3 , {  ap = display.LEFT_CENTER , c = {
		fontWithColor('16' ,{   text = "" })
	}}  )
	local unionName =  display.newRichLabel( 10 +width,105 - height * 4, {  ap = display.LEFT_CENTER , c = {
		fontWithColor('16' ,{   text = "" })
	}}  )
	collectLayout:addChild(unionName)
	collectLayout:addChild(towerMaxFooler)
	local data = {
		cardCollectLabel      = cardCollectLabel,
		towerMaxFooler        = towerMaxFooler,
		restaurtantLabel      = restaurtantLabel,
		cardSkinNum           = cardSkinNum,
		unionName             = unionName
	}
	table.merge(self.viewData , data)
end

function PersonInformationDetailView:createBirthDayInfo(sender)
	local pos = cc.p(sender:getPosition())
	local senderParent = sender:getParent()
	local worldPos = senderParent:convertToWorldSpace(pos)
	local birthDayInfoLayer = display.newLayer(display.cx , display.cy , {color = cc.c4b(0,0,0,0) ,size = display.size , ap = display.CENTER , enable = true  })
	display.commonUIParams(birthDayInfoLayer , { cb = function()
		birthDayInfoLayer:removeFromParent()
	end})
	app.uiMgr:GetCurrentScene():AddDialog(birthDayInfoLayer)

	local nodePos = birthDayInfoLayer:convertToNodeSpace(worldPos)
	local bgTipSize = cc.size(265 , 194 )
	local bgTipLayout = display.newLayer(nodePos.x  - 26 , nodePos.y -40  , { size = bgTipSize  , ap = display.CENTER_TOP })
	local bgTipImage = display.newImageView(_res('ui/common/common_bg_tips') , bgTipSize.width/2 , bgTipSize.height/2 , {scale9 = true , size = bgTipSize})
	bgTipLayout:addChild(bgTipImage)
	birthDayInfoLayer:addChild(bgTipLayout)


	local bgTipHorn = display.newImageView(_res('ui/common/common_bg_tips_horn') ,bgTipSize.width/2 , bgTipSize.height-2)
	bgTipLayout:addChild(bgTipHorn)

	local birthLabel = display.newLabel(bgTipSize.width/2 , bgTipSize.height - 25 , fontWithColor(10 , { color ="#5b3c25" , fontSize = 24 , text = __('生日'), ap = display.CENTER_TOP }))
	bgTipLayout:addChild(birthLabel)

	local birthDataLabel = display.newLabel(bgTipSize.width/2 , bgTipSize.height - 70  ,fontWithColor(6,
	{fontSize = 24 ,  text = ""}) )
	bgTipLayout:addChild(birthDataLabel)

	local birthDescr = display.newLabel(bgTipSize.width/2 , 20 , fontWithColor(6,{ap = display.CENTER_BOTTOM , hAlign = display.TAL  ,fontSize = 20,   w = 230,  text = __('每年的生日都将会收到番糖送出的礼物哦')}))
	bgTipLayout:addChild(birthDescr)
	local data = {
		birthDataLabel = birthDataLabel
	}
	table.merge(self.viewData , data)
end
return PersonInformationDetailView
