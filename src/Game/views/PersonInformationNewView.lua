---
--- Created by xingweihao.
--- DateTime: 24/10/2017 6:11 PM
---
---@class PersonInformationNewView
local PersonInformationNewView = class('home.PersonInformationNewView',function ()
    local node = CLayout:create(display.size)
    node.name = 'Game.views.PersonInformationNewView'
    node:enableNodeEvents()
    return node
end)
---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local BUTTON_CLICK = {
    INFORCLICK = 1004 , -- 个人信息点击事件
    SYSTEMCLICK = 1005 , --系统设置
    PUSHCLICK = 1006 ,  -- 推送设置
    CONTACTCLICK = 1007,  -- 联系客服
    OTHER = 1008,  --活动h5
    EXCHANGE_NUM = 100011 , -- 兑换码
}
function PersonInformationNewView:ctor()
    self:initUI()
end

function PersonInformationNewView:initUI()
    local bg = display.newImageView(_res('ui/common/common_bg_13.png'), 0, 0)
    local bgSize = bg:getContentSize()

    local  bgLayout = CLayout:create(bgSize)
    bgLayout:setPosition(cc.p(display.cx ,display.cy))
    bg:setPosition(cc.p(bgSize.width/2  , bgSize.height/2))
    bgLayout:addChild(bg)
    -- 标签
    local titleBg = display.newButton(0, 0, {n = _res('ui/common/common_bg_title_2.png'), animation = false})
    display.commonUIParams(titleBg, {po = cc.p(bgSize.width * 0.5, bgSize.height - titleBg:getContentSize().height * 0.5 - 10)})
    if isJapanSdk() then
        display.commonLabelParams(titleBg,
        {text = __('个人信息'),
            fontSize = 24,color = fontWithColor('BC').color,ttf = true, font = TTF_GAME_FONT,
            offset = cc.p(0, 0)})
    else
        display.commonLabelParams(titleBg,
        {text = __('个人信息'),
            fontSize = 24,color = fontWithColor('BC').color,ttf = true, font = TTF_GAME_FONT,
            offset = cc.p(0, -2)})
    end
    bg:addChild(titleBg)

    --  点击关闭层

    local  closeView = display.newLayer(display.cx,display.cy,{ap = display.CENTER , size = display.size  , enable = true, color = cc.c4b(0,0,0,100)})
    self:addChild(closeView)
    --吞噬曾
    local  swallowView = display.newLayer(bgSize.width/2, bgSize.height/2,{ap = display.CENTER , size = bgSize  , enable = true, color = cc.c4b(0,0,0,0)})
    bgLayout:addChild(swallowView)
    swallowView:setContentSize(cc.size(bgSize.width, bgSize.height ))
    bgLayout:setContentSize(cc.size(bgSize.width, bgSize.height))
    -- 这个是功能切换的按钮
    local buttonSize = cc.size(143,96)
    local buttonLayotSize = cc.size(buttonSize.width, buttonSize.height*4)
    local swallowButtonLayout = display.newLayer(buttonLayotSize.width/2  , buttonLayotSize.height/2 ,{ size =buttonLayotSize , enable = true , ap = display.CENTER , color = cc.c4b(0,0,0,0) })
    local buttonLayot = CLayout:create(buttonLayotSize)
    buttonLayot:addChild(swallowButtonLayout)
    buttonLayot:setPosition(cc.p(bgSize.width/2 + display.cx - 35 , bgSize.height/2 + display.cy - 100))
    buttonLayot:setAnchorPoint(display.LEFT_TOP)
    self:addChild(buttonLayot ,10 )
    ---
    local buttonNameTable = {
        { name    =    __('个人信息') ,tag = BUTTON_CLICK.INFORCLICK}  ,
        { name  =  __('个人设置') ,tag = BUTTON_CLICK.SYSTEMCLICK}

    }

    -- if not gameMgr:GetUserInfo().openCodeModule then
    --     buttonNameTable = {
    --         { name  =  __('个人设置') ,tag = BUTTON_CLICK.SYSTEMCLICK}
    --     }
    -- end
    if  gameMgr:GetUserInfo().openCodeModule then
       table.insert(buttonNameTable, #buttonNameTable+1 ,{ name    =  __('兑换码') ,tag = BUTTON_CLICK.EXCHANGE_NUM})
    end
    if ( not isNewUSSdk()) and isElexSdk() then
        table.insert(buttonNameTable, #buttonNameTable+1 ,{ name    =  __('其他') ,tag = BUTTON_CLICK.OTHER})
    end
    local buttonTable  = {}
    local len = table.nums(buttonNameTable)
    for  i = 1, len do
        local btn = display.newCheckBox(buttonSize.width/2,buttonLayotSize.height -((i -0.5) * buttonSize.height),
        {n = _res("ui/common/common_btn_sidebar_common.png"),
            s = _res("ui/common/common_btn_sidebar_selected.png")})
        local lsize = utf8len(buttonNameTable[i].name)
        local label = nil
        if isJapanSdk() then
            if lsize > 10 then
                label = display.newLabel(buttonSize.width / 2 - 2, buttonSize.height /2 + 10 ,fontWithColor(15,{ttf = true, font = TTF_GAME_FONT, fontSize = 20, color = '3c3c3c', ap = display.CENTER , text =buttonNameTable[i].name, w = 106,h = 80
                    }) )
            else
                label = display.newLabel(buttonSize.width / 2 - 2, buttonSize.height /2 + 25 ,fontWithColor(15,{ttf = true, font = TTF_GAME_FONT, fontSize = 20, color = '3c3c3c', ap = display.CENTER , text =buttonNameTable[i].name}) )
            end
        else
            label = display.newLabel(buttonSize.width /2 - 5 , buttonSize.height /2 +25 ,fontWithColor(15,{ fontSize = 19, color = '3c3c3c', ap = display.CENTER , text =buttonNameTable[i].name,w = 110}) )
            if display.getLabelContentSize(label).height > 30  then
                display.commonLabelParams(label , {fontSize = 19 ,  text = buttonNameTable[i].name})
                label:setPosition(buttonSize.width /2 -5 , buttonSize.height /2 +25)
            end
        end
        btn:addChild(label)
        label:setTag(111)
        label:setAlignment(cc.TEXT_ALIGNMENT_CENTER)
        btn:setTag(buttonNameTable[i].tag)
        buttonTable[tostring(buttonNameTable[i].tag)] = btn
        -- btn:setOnClickScriptHandler(handler(self,self.ButtonAction))
        buttonLayot:addChild(btn)
    end
    --右侧的Layout
    local contentSize = cc.size(982,562)
    local contentLayout =  display.newLayer(bgSize.width/2 ,bgSize.height - 57 , { size = contentSize  } )
    bgLayout:addChild(contentLayout)
    contentLayout:setAnchorPoint(display.CENTER_TOP)
    self:addChild(bgLayout,2)
    --bgLayout:setVisible(false)
    display.animationIn(bgLayout,function()
        PlayAudioClip(AUDIOS.UI.ui_window_open.id)
    end)

    -- 番糖会员按钮
    if app.gameMgr:GetUserInfo().ftMemberPointOpened  == 1 then
        local funtoyBtnSize =  cc.size(87,131)
        local funtoyLayout  = display.newLayer(display.cx  - 630, display.size.height, {ap = display.LEFT_TOP , size = funtoyBtnSize  })
        local funtoyBtn = display.newButton(funtoyBtnSize.width /2 , funtoyBtnSize.height/2 , { n = _res('ui/home/infor/personal_information_icon_funtoy.png')})
        funtoyLayout:addChild(funtoyBtn)
        self:addChild(funtoyLayout,10)
        local titleBtn = display.newButton(funtoyBtnSize.width/2 , 0 ,{ n = _res('ui/home/infor/guild_icon_name_bg.png') } )
        funtoyBtn:addChild(titleBtn)
        display.commonLabelParams(titleBtn , fontWithColor(14,{fontSize = 22,  text = __('番糖会员') }))

        -------------------------------------------------
        local tabNameLabelPos = cc.p(funtoyLayout:getPosition())
        funtoyLayout:setPositionY(display.height + 100)
        local action = cc.EaseBounceOut:create(cc.MoveTo:create(1, tabNameLabelPos))
        funtoyLayout:runAction( action )
        funtoyBtn:setOnClickScriptHandler(function()
            local function createH5View( url )
                print(url)
                local viewData = self.viewData
                local pos = viewData.view:convertToNodeSpace(cc.p(display.cx, display.cy))
                if not self.webviewLayer then
                    local webviewLayer = display.newLayer(pos.x, pos.y, {size = display.size, ap = cc.p(0.5, 0.5), color = cc.c3b(255, 255, 255)})
                    viewData.view:addChild(webviewLayer, 10)
                    self.webviewLayer = webviewLayer
                end
                -- if device.platform == 'ios' or device.platform == 'android' then
                    local _webView = ccexp.WebView:create()
                    _webView:setAnchorPoint(cc.p(0.5, 0.5))
                    _webView:setPosition(pos)
                    _webView:setContentSize(cc.size(display.width, display.height))
                    _webView:setScalesPageToFit(true)
                    _webView:setOnShouldStartLoading(function( webview, url)
                        local scheme = 'liuzhipeng'
                        local urlInfo = string.split(url, '://')
                        if 2 == table.nums(urlInfo) then
                            if urlInfo[1] == scheme then
                                local urlParams = string.split(urlInfo[2], '&')
                                local params = {}
                                for k,v in pairs(urlParams) do
                                    local param = string.split(v, '=')
                                    -- -- 构造表单做get请求 所以结尾多一个？
                                    -- params[param[1]] = string.split(param[2], '?')[1]
                                    -- 构造表单做get请求（win上面的ie浏览器结尾多一个/，其他浏览器或其他平台尾多一个？，所以不能用上面的）
                                    local lastChar = string.sub(param[2], string.len(param[2]))
                                    if lastChar == '/' or lastChar == '?' then
                                        params[param[1]] = string.sub(param[2], 0, string.len(param[2]) - 1)
                                    else
                                        params[param[1]] = param[2]
                                    end
                                end
                                if params.action then
                                    if 'getId' == params.action then
                                        local playerData = {id = gameMgr:GetUserInfo().playerId }
                                        webview:evaluateJS('onGetIdAction(' .. json.encode(playerData).. ')')
                                    elseif 'close' == params.action then
                                        webview:runAction(cc.RemoveSelf:create())
                                        self.webView = nil
                                        if self.webviewLayer then
                                            self.webviewLayer:runAction(cc.RemoveSelf:create())
                                            self.webviewLayer = nil
                                        end
                                    elseif 'reload' == params.action then
                                        webview:reload()
                                    else
                                        return true
                                    end
                                end
                                return false
                            end
                        end
                        return true
                    end)
                    viewData.view:addChild(_webView,100)
                    _webView:loadURL(url)
                    self.webView = _webView
                -- end
            end
            local platformId = checkint(Platform.id)
            if platformId == BetaAndroid or platformId == BetaIos then
                createH5View(string.format('http://cs-test.dddwan.com?playerId=%s&gameId=%s', app.gameMgr:GetUserInfo().encryptPlayerId, CommonUtils.GetGameId()))
            else
                createH5View(string.format('http://vip.dddwan.com?playerId=%s&gameId=%s', app.gameMgr:GetUserInfo().encryptPlayerId, CommonUtils.GetGameId()))
            end
        end)
    end

    self.viewData = {
        buttonTable = buttonTable ,
        contentLayout = contentLayout ,
        buttonLayot =  buttonLayot ,
        closeView = closeView ,
        view = self ,
        bg = bg ,
    }
end
return PersonInformationNewView
