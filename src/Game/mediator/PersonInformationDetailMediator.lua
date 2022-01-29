
---
--- Created by xingweihao.
--- DateTime: 25/10/2017 3:25 PM
---
local Mediator = mvc.Mediator
---@class PersonInformationDetailMediator :Mediator
local PersonInformationDetailMediator = class("PersonInformationDetailMediator", Mediator)
local NAME = "PersonInformationDetailMediator"
---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
---@type TimerManager
local timerMgr = AppFacade.GetInstance():GetManager("TimerManager")
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
---@type CardManager
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")
local CHANGE_NAME_NEED_DIAMON =  500
local BUTTON_CLICK = {
    MEDAL_HONOR            = 1009, -- 勋章墙
    ENTERTAIN              = 1010, -- 飨灵屋
    MESSAGE_BOARD          = 1011, -- 留言板
    CHANGE_DECR_TEXT       = 1102, -- 修改玩家的签名
    CHANGE_PLAYER_NAME     = 1103, -- 修改玩家的签名
    CHANGE_PLAYER_HEADER   = 1104, -- 修改玩家的头像
    CHANGE_DECR            = 1105,
    BINDING_TELL_NUM       = 1106, -- 实名认证
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
local PersonDeatailTableMediator = {
    [tostring(BUTTON_CLICK.MEDAL_HONOR)]  = "MedalWallMediator",
    [tostring(BUTTON_CLICK.ENTERTAIN)]   = "EntertainHouseMediator",
    [tostring(BUTTON_CLICK.MESSAGE_BOARD)] = "MessageBoardMediator"

}
local CHANGE_TYPE = {
    CHANGE_THROPHY   = 1 ,  -- 更换奖杯
    CHANGE_HEAD = 2 ,  -- 更换头像
    CHANGE_HEAD_FRAME = 3  -- 更换外框

}
local RED_TAG = 1115
function PersonInformationDetailMediator:ctor( param , viewComponent )
    self.super:ctor(NAME,viewComponent)
    self.datas = param or {}

    self.preIndex = nil  -- 上一次点击
    self.collectMediator = {} -- 用于收集和管理mediator
    self.exchangeNum = ""
    self.bindingTellNumView = nil
    self.isFirstPhoneLock = gameMgr:GetUserInfo().isFirstPhoneLock -- 是否是第一次绑定
end

function PersonInformationDetailMediator:InterestSignals()
    local signals = {
        POST.CHANGE_PLAYER_SIGN.sglName , -- 修改用户的签名
        POST.CHANGE_PLAYER_NAME.sglName , -- 修改用户的名字
        POST.PLAYER_UNLOCK_PHONE.sglName ,-- 解绑手机号
        POST.PLAYER_LOCK_PHONE.sglName ,  -- 实名认证
        POST.PLAYER_GET_LOCK_VERIFICATION.sglName , -- 获取绑定的验证码
        POST.PLAYER_GET_UNLOCK_VERIFICATION.sglName ,-- 获取解绑的验证码
        POST.PLAYER_PERSON_INFO.sglName  ,  -- 获取个人的信息
        POST.PERSON_THUMBUP.sglName  ,  -- 点赞接口
        POST.PERSON_CHANGE_AVATAR_FRAME.sglName  ,  -- 更换头像框
        POST.PERSON_BIRTHDAY.sglName  ,  -- 设置生日
        POST.PERSON_CHANGE_AVATAR.sglName  ,  -- 更换头像框
        POST.ACCOUNT_BIND.sglName,
        POST.PLAYER_ZM_BIND_ACCOUNT.sglName, -- 智明账户绑定
        REFRESH_MESSAGE_BOARD_EVENT ,
        FRIEND_REFRESH_EDITBOX ,          -- 刷新editbox
        "PHONE_BIND_STATE",
        'BIRTHDAY_SET_COMMPLETE' ,          -- 刷新editbox
        "PHOME_FIRST_LOCK_EVENT_REFRESH"    --第一次绑定任务的刷新
    }

    return signals
end
function PersonInformationDetailMediator:Initial( key )
    self.super.Initial(self,key)
    ---@type PersonInformationDetailView
    self.viewComponent = require('Game.views.PersonInformationDetailView').new()
    self:SetViewComponent(self.viewComponent)
    local viewData = self.viewComponent.viewData
    local isShow = nil
    if CommonUtils.JuageMySelfOperation(self.datas.playerId) then
        display.commonUIParams(viewData.changeNameBtn ,{ cb = handler(self, self.ButtonAction) , animate = true  })
        display.commonUIParams(viewData.changeLabelContent2 ,{ cb = handler(self, self.ButtonAction) , animate = true  })
        display.commonUIParams(viewData.bindingBtn ,{ cb = handler(self, self.ButtonAction) , animate = true  })
        display.commonUIParams(viewData.landDefaultImage ,{ cb = handler(self, self.ButtonAction) , animate = true  })
        display.commonUIParams(viewData.changeHeadBtn ,{ cb = handler(self, self.ButtonAction) , animate = true  })
        display.commonUIParams(viewData.changeFrameBtn ,{ cb = handler(self, self.ButtonAction) , animate = true  })
        display.commonUIParams(viewData.changeBgContentLayout ,{ cb = handler(self, self.ButtonAction) , animate = true  })
        display.commonUIParams(viewData.birthBtn ,{ cb = handler(self, self.ButtonAction) , animate = true  })

        if isKoreanSdk() then
            display.commonUIParams(viewData.customServiceBtn ,{ cb = handler(self, self.ButtonAction) , animate = true  })
        end
        viewData.levelTipBtn:setOnClickScriptHandler( handler(self, self.ButtonAction))
        viewData.headerNode.callback =  handler(self, self.ButtonAction)
        viewData.headerNode.bg:setTag(BUTTON_CLICK.CHANGE_PLAYER_HEADER)
        viewData.headerNode.preBg:setTag(BUTTON_CLICK.CHANGE_PLAYER_HEADER)
        viewData.descrName:registerScriptEditBoxHandler(function(eventType,sender)
            if eventType == 'began' then  -- 输入开始
            elseif eventType == 'ended' then  -- 输入结束
                self:ButtonAction(sender)
            elseif eventType == 'changed' then  -- 内容变化

            elseif eventType == 'return' then  -- 从输入返回
                self:ButtonAction(sender)
            end
        end)
        if gameMgr:GetUserInfo().personalMessage == 1 then
            local viewData =   self.viewComponent.viewData
            local node =  viewData.buttonCollect[tostring(BUTTON_CLICK.MESSAGE_BOARD)]:getChildByTag(RED_TAG)
            if node and ( not  tolua.isnull(node )) then
                node:setVisible(true )
            end
        end
        if  gameMgr:GetUserInfo().phone  and   gameMgr:GetUserInfo().phone ~= "" then
            viewData.bindingBtn:setVisible(false)
        end
        -- 自己不能给自己点赞
        viewData.landDefaultImage:setVisible(false)
        viewData.levelTipBtn:setVisible(true)
        viewData.customServiceBtn:setVisible(isKoreanSdk())
        isShow = true
    else
        if viewData.rewardDiamond then
            viewData.rewardDiamond:setVisible(false)
        end
        display.commonUIParams(viewData.landDefaultImage ,{ cb = handler(self, self.ButtonAction) , animate = true  })
        viewData.bindingBtn:setVisible(false)
        viewData.changeLabel:setVisible(false)
        viewData.changeNameBtn:setVisible(false)
        viewData.levelTipBtn:setVisible(false)
        viewData.descrName:setVisible(false)
        viewData.changeHeadLabel:setVisible(false)
        viewData.customServiceBtn:setVisible(false)
        isShow = false
    end
    if  not (isShow and GAME_MODULE_OPEN.NEW_CREATE_ROLE)  then
        isShow = false
    end
    viewData.birthBtn:setVisible(isShow)


    display.commonUIParams(viewData.personMoreBtn , { cb = handler(self, self.ButtonAction) , animate = true  } )
    -- button 按钮
    for i, v in pairs(viewData.buttonCollect) do
        v:setOnClickScriptHandler(handler(self, self.SwitchModule))
    end

end
---@param signal Signal
function PersonInformationDetailMediator:ProcessSignal(signal)
    local name = signal:GetName()
    local data = signal:GetBody()
    if name == POST.CHANGE_PLAYER_SIGN.sglName then

        local viewData =   self.viewComponent.viewData
        display.reloadRichLabel(viewData.decLabel , {  c = CommonUtils.dealWithEmoji(fontWithColor('6') ,self.personData.playerSign )})
        local rect =  viewData.decLabel:getBoundingBox()
        viewData.decLabel:setPosition(cc.p(180,0))
        viewData.decLabelLayout:setContentSize(cc.size(360, rect.height))
        local scrollView = viewData.scrollView
        scrollView:reloadData()
        scrollView:setContentOffsetToTop()
        viewData.descrName:setVisible(false)
        viewData.changeBgContentLayout:runAction(cc.Sequence:create(
        cc.DelayTime:create(0.1) ,
            cc.CallFunc:create(
                function ()
                    viewData.changeLabelContent:setVisible(true)
                end
            )))
    elseif name == POST.ACCOUNT_BIND.sglName then
        local viewData =   self.viewComponent.viewData
        if viewData.accountBtn then
            local node =  viewData.accountBtn:getChildByTag(RED_TAG)
            if node and ( not  tolua.isnull(node )) then
                node:setVisible(false)
            end
        end
    elseif name == POST.PLAYER_ZM_BIND_ACCOUNT.sglName then
        local rewards = data.rewards
        local viewData =   self.viewComponent.viewData
        uiMgr:AddDialog('common.RewardPopup' , {rewards =rewards })
        gameMgr:GetUserInfo().isBindAccountDrawn = 1
        if viewData.rewardDiamond and ( not tolua.isnull( viewData.rewardDiamond) )then
            viewData.rewardDiamond:setVisible(false)
        end
        local mediator = app:RetrieveMediator("ElexBindingMediator")
        if mediator then
            app:UnRegsitMediator("ElexBindingMediator")
        end
        local node =  viewData.bindingBtn:getChildByTag(RED_TAG)
        if node and ( not  tolua.isnull(node )) then
            node:setVisible(false)
        end
    elseif name == POST.CHANGE_PLAYER_NAME.sglName then
        uiMgr:ShowInformationTips(__('昵称修改成功'))
        data.playerName =  data.playerName or ""
        self.personData.playerName = data.playerName
        gameMgr:GetUserInfo().playerName = data.playerName
        self.viewComponent.viewData.playerLabel:setString( data.playerName)
        display.commonLabelParams(self.viewComponent.viewData.playerLabel , fontWithColor('16', {text = data.playerName , fontSize =22  }))
        if checkint(gameMgr:GetUserInfo().isChangeName ) == 1 then
            CommonUtils.DrawRewards({{goodsId =  DIAMOND_ID , num =  - CHANGE_NAME_NEED_DIAMON  } } )
        end
        gameMgr:GetUserInfo().isChangeName = 1
        self:GetFacade():DispatchObservers(REFRESH_PLAYERNAME_EVENT)
    elseif name == POST.PLAYER_GET_UNLOCK_VERIFICATION.sglName then
        local isSend =  checkint(data.isSend)
        if isSend == 1 then
            -- 删除timer
            timerMgr:RemoveTimer("PLAYER_GET_UNLOCK_VERIFICATION")
            timerMgr:AddTimer( {tag = RemindTag.BINDING_TELL ,  countdown =  60 , isLosetime = false  , name = "PLAYER_GET_UNLOCK_VERIFICATION"})
        elseif isSend == 1  then
            uiMgr:ShowInformationTips(__('验证码发送失败'))
        end
    elseif name == POST.PLAYER_GET_LOCK_VERIFICATION.sglName then
        local isSend =  checkint(data.isSend)
        if isSend == 1 then
            --删除timer
            timerMgr:RemoveTimer("PLAYER_GET_LOCK_VERIFICATION")
            timerMgr:AddTimer({tag = RemindTag.BINDING_TELL ,  countdown =  60 , isLosetime = false ,name = "PLAYER_GET_LOCK_VERIFICATION" })
        elseif   isSend == 0 then
            uiMgr:ShowInformationTips(__('验证码发送失败'))
        end
    elseif name == POST.PLAYER_LOCK_PHONE.sglName then
        if self.bindingTellNumView and ( not  tolua.isnull(self.bindingTellNumView)) then
        self.bindingTellNumView:runAction(cc.RemoveSelf:create())
        end
        local diamondNum  =  checkint(data.diamond)
        self.isFirstPhoneLock = 0
        if  gameMgr:GetUserInfo().isFirstPhoneLock ==1 then
            gameMgr:GetUserInfo().isFirstPhoneLock = 0
            self:GetFacade():DispatchObservers( "PHOME_FIRST_LOCK_EVENT_REFRESH"  , { })
        end
        gameMgr:GetUserInfo().isFirstPhoneLock = 0
        -- 绑定的手机号
        gameMgr:GetUserInfo().phone = data.phone
        --首先删除定时器
        timerMgr:RemoveTimer("PLAYER_GET_LOCK_VERIFICATION")
        if diamondNum > gameMgr:GetUserInfo().diamond then
            local num = diamondNum - gameMgr:GetUserInfo().diamond
            local data = { goodsId = DIAMOND_ID , num = num }
            uiMgr:AddDialog('common.RewardPopup' , {rewards ={data} })
            local viewData =   self.viewComponent.viewData
            if viewData.rewardDiamond and ( not  tolua.isnull( viewData.rewardDiamond) )then
                viewData.rewardDiamond:setVisible(false)
            end
        end
        local viewData =   self.viewComponent.viewData
        viewData.bindingBtn:setVisible(false)
        display.commonLabelParams(viewData.bindingBtn , { text = __('解除认证')})
    elseif name == POST.PLAYER_UNLOCK_PHONE.sglName then
        gameMgr:GetUserInfo().phone = ""
        -- 删除解绑的定时器
        timerMgr:RemoveTimer("PLAYER_GET_UNLOCK_VERIFICATION")
        self.phone = ""
        gameMgr:GetUserInfo().phone = ""
        self.bindingTellNumView:runAction(cc.RemoveSelf:create())
        local bindingTellNumberView = require("Game.views.BindingTellNumberView").new({isFirstPhoneLock = self.isFirstPhoneLock , unLockPhone = false , tellNumber = gameMgr:GetUserInfo().phone })
        bindingTellNumberView:setPosition(display.center)
        uiMgr:GetCurrentScene():AddDialog(bindingTellNumberView)
        self.bindingTellNumView = bindingTellNumberView
        local viewData =   self.viewComponent.viewData
        display.commonLabelParams(viewData.bindingBtn , { text = __('实名认证')})
    elseif name == 'PHONE_BIND_STATE' then
        if data.cmd and data.cmd == 'query' then
            if data.state  == "failed" then
                display.commonLabelParams(self.viewComponent.viewData.bindingBtn , { text = __('实名认证')})
            elseif data.state == "success" then
                if device.platform == 'android'  then
                    -- 调起查询的接口
                    local AppSDK = require('root.AppSDK')
                    AppSDK.GetInstance():EfunIsBindPhone()
                else
                    AppFacade.GetInstance():DispatchSignal(POST.PLAYER_LOCK_PHONE.cmdName,{})
                end
            elseif data.state ==  "ALRESDY_BIND"  then
                AppFacade.GetInstance():DispatchSignal(POST.PLAYER_LOCK_PHONE.cmdName,{})
            end
        end
    elseif name == POST.PLAYER_PERSON_INFO.sglName then
        self.personData =  data
        self:UpdatePersonInformation()
        local viewData =   self.viewComponent.viewData
        viewData.headerNode.headerSprite:setTexture(CommonUtils.GetGoodsIconPathById(self.personData.avatar))
        self.personData.avatarFrame = CommonUtils.GetAvatarFrame(self.personData.avatarFrame)
        viewData.headerNode:SetPreImageTexture(CommonUtils.GetGoodsIconPathById(self.personData.avatarFrame ))
        self:SwitchModule(viewData.buttonCollect[tostring(BUTTON_CLICK.ENTERTAIN)])
        if not  CommonUtils.JuageMySelfOperation(self.datas.playerId) then
            local viewData = self:GetViewComponent().viewData
            self:ButtonAction(viewData.personMoreBtn)
        end
    elseif name == "BIRTHDAY_SET_COMMPLETE"  then
        local year= checkint(data.year)
        local month= checkint(data.month)
        local day= checkint(data.day)
        local birthdayStr = string.format("%04d-%02d-%02d",year , month ,day )
        self:SendSignal(POST.PERSON_BIRTHDAY.cmdName , {birthday = birthdayStr })
    elseif name == POST.PERSON_BIRTHDAY.sglName  then
        local requestData = data.requestData
        local birthday =    requestData.birthday
        gameMgr:SetBirthday(birthday)
        app.badgeMgr:CheckHomeInforRed()
        uiMgr:ShowInformationTips(__('设置生日成功'))
        ---@type PersonInformationDetailView
        local viewComponent = self:GetViewComponent()
        local viewData = viewComponent.viewData
        local birthBtn = viewData.birthBtn
        local image = birthBtn:getChildByTag(RED_TAG)
        image:setVisible(false)

    elseif name == "PHOME_FIRST_LOCK_EVENT_REFRESH"  then
        local viewData =   self.viewComponent.viewData
        local node =  viewData.bindingBtn:getChildByTag(RED_TAG)
        if node and ( not  tolua.isnull(node )) then
            node:setVisible(false)
        end
    elseif name == REFRESH_MESSAGE_BOARD_EVENT  then
        if  CommonUtils.JuageMySelfOperation(self.datas.playerId)  then

            if checkint(self.preIndex)  == BUTTON_CLICK.MESSAGE_BOARD then
                gameMgr:GetUserInfo().personalMessage = 0
                -- 清除红点的逻辑
                app.badgeMgr:CheckHomeInforRed()
            end
            local viewData =   self.viewComponent.viewData
            local node =  viewData.buttonCollect[tostring(BUTTON_CLICK.MESSAGE_BOARD)]:getChildByTag(RED_TAG)
            if gameMgr:GetUserInfo().personalMessage == 1 then
                if node and ( not  tolua.isnull(node )) then
                    node:setVisible(true )
                end
            elseif  gameMgr:GetUserInfo().personalMessage == 0  then
                if node and ( not  tolua.isnull(node )) then
                    node:setVisible(false)
                end
            end
        end
    elseif name == POST.PERSON_THUMBUP.sglName then

        local viewData = self.viewComponent.viewData
        self.personData.isThumbUp = 1
        self.personData.thumbUpNum = checkint(self.personData.thumbUpNum)  + 1
        --display.reloadRichLabel(viewData.popularityLabel, {
        --    c = {
        --        fontWithColor('14' ,{   text = __('人气:  ') , fontSize = 20 ,color = '#5b3c25'}) ,
        --        fontWithColor('6' ,{ text =  " " .. tostring(self.personData.thumbUpNum) })
        --    }}  )
        self:SetOffsetLabel( { relativeNode = viewData.popularityLabel , node = viewData.popularityLabelValue , text = self.personData.thumbUpNum } )
        local landDefaultImageSize =  viewData.landDefaultImage:getContentSize()
        local image = display.newImageView( _res('ui/home/infor/personal_information_btn_laud_select.png'), landDefaultImageSize.width/2 ,landDefaultImageSize.height/2  )
        viewData.landDefaultImage:addChild(image)
        image:setOpacity(0)
        local num = 0.5
        image:runAction(
            cc.Sequence:create(
                cc.Spawn:create(
                cc.FadeIn:create(num) ,
                cc.EaseBackOut:create(cc.JumpBy:create(num ,cc.p(0,50) , 10 ,1))
                ),
                cc.CallFunc:create(function ()
                    viewData.landDefaultImage:setNormalImage(_res('ui/home/infor/personal_information_btn_laud_select.png') ) -- 不可以点赞
                    viewData.landDefaultImage:setSelectedImage(_res('ui/home/infor/personal_information_btn_laud_select.png') ) -- 不可以点赞
                end),
                cc.RemoveSelf:create()

            )
        )
    elseif name == POST.PERSON_CHANGE_AVATAR.sglName then  -- 修改头像的回调
        local requestData = data.requestData
        gameMgr:GetUserInfo().avatar  = requestData.playerAvatar
        local viewData =   self.viewComponent.viewData
        viewData.headerNode.headerSprite:setTexture(CommonUtils.GetGoodsIconPathById(requestData.playerAvatar))
        self:GetFacade():DispatchObservers(REFRESH_AVATAR_HEAD_EVENT,{})
    elseif name == POST.PERSON_CHANGE_AVATAR_FRAME.sglName then -- 修改头像框的修改
        local requestData = data.requestData
        gameMgr:GetUserInfo().avatarFrame  = requestData.playerAvatarFrame
        local viewData =   self.viewComponent.viewData
        viewData.headerNode:SetPreImageTexture(CommonUtils.GetGoodsIconPathById(requestData.playerAvatarFrame))
        self:GetFacade():DispatchObservers(REFRESH_AVATAR_HEAD_EVENT,{})
    elseif name == FRIEND_REFRESH_EDITBOX then
        if data.tag == DISABLE_EDITBOX_MEDIATOR.PERSON_DETAIL_TAG then
            local viewData = self.viewComponent.viewData
            if data.isEnabled then
                viewData.descrName:setVisible(true)
            else
                viewData.descrName:setVisible(false)
            end
        end
    end

end
-- 切换功能模块的按钮
function PersonInformationDetailMediator:SwitchModule(sender)
    local tag = sender:getTag()
    local name = PersonDeatailTableMediator[tostring(tag)]
    if not  name then -- 没有该观察者就直接报错
        return
    end
    if   not  self.collectMediator[name] then
        local mediator = require("Game.mediator." .. name).new(self.personData )
        self:GetFacade():RegistMediator(mediator)
        self.viewComponent.viewData.showLayout:addChild(mediator:GetViewComponent())
        -- 加载过后释放引用计数器
        mediator:GetViewComponent():release()
        mediator:GetViewComponent():setPosition(cc.p(603/2 , 496/2))
        self.collectMediator[name] = mediator
    end
    if self.preIndex then
        if self.preIndex == tag then
            return
        else
            self:DealWithButtonStatus(self.preIndex , false)
            self:DealWithButtonStatus(tag , true)
            local preName =  PersonDeatailTableMediator[tostring(self.preIndex)]
            self.collectMediator[preName]:GetViewComponent():setVisible(false)
            self.collectMediator[name]:GetViewComponent():setVisible(true)
        end
        PlayAudioByClickNormal()
    else
        self:DealWithButtonStatus(tag , true)
    end
    self.preIndex = tag  ---根据逻辑需要
    if tag == BUTTON_CLICK.MESSAGE_BOARD then
        gameMgr:GetUserInfo().personalMessage = 0
        self:GetFacade():DispatchObservers(REFRESH_MESSAGE_BOARD_EVENT,{})
    end

end

--- 处理btn 的状态
function PersonInformationDetailMediator:DealWithButtonStatus(tag , selected)
    local name = PersonDeatailTableMediator[tostring(tag)]
    if not  name then -- 没有该观察者就直接报错
        return
    end
    local sender = self.viewComponent.viewData.buttonCollect[tostring(tag)]
    if  sender  then
        if selected then
            sender:setChecked(true)
            sender:setEnabled(false)
        else
            sender:setChecked(false)
            sender:setEnabled(true)
        end
    end
end
function PersonInformationDetailMediator:ButtonAction(sender)
    local tag = sender:getTag()
    local viewData = self.viewComponent.viewData
    PlayAudioByClickNormal()
    if tag == BUTTON_CLICK.CHANGE_PLAYER_NAME then
        app.uiMgr:AddChangeNamePopup({
            preName       = app.gameMgr:GetUserInfo().playerName,
            renameCB      = function(newName)
                self:SendSignal(POST.CHANGE_PLAYER_NAME.cmdName , {playerName = newName})
            end,
            renameConsume = {goodsId = DIAMOND_ID, num = CHANGE_NAME_NEED_DIAMON},
            isFreeCharge  = checkint(app.gameMgr:GetUserInfo().isChangeName) == 0
        })
    elseif tag == BUTTON_CLICK.CHANGE_DECR then
        local sender = sender:getParent()
        sender:setVisible(false)
        --sender:setTouchEnabled(false)
        sender:runAction(cc.Sequence:create(
            cc.DelayTime:create(0.2),
            cc.CallFunc:create(
            function ()
                viewData.descrName:setVisible(true)
                if self.personData then
                    viewData.descrName:setText(self.personData.playerSign)
                end
            end
            )
        ))


    elseif tag == BUTTON_CLICK.CHANGE_DECR_TEXT then
        if viewData.changeLabelContent:isVisible() then
            return
        end
        local str = sender:getText()
        if str ~=  '' then
            if self.personData.playerSign ~= str then
                if not CommonUtils.CheckIsDisableInputDay() then
                    self.personData.playerSign = str
                    gameMgr:GetUserInfo().playerSign = str
                    self:SendSignal(POST.CHANGE_PLAYER_SIGN.cmdName ,{playerSign = str})
                    sender:setVisible(false)
                end
            end
        else
            uiMgr:ShowInformationTips(__('签名不能为空'))
        end


    elseif tag == BUTTON_CLICK.BINDING_TELL_NUM then
        ---@type BindingTellNumberView
        if isElexSdk() and (not isNewUSSdk()) then
            if device.platform == 'android' and FTUtils:getTargetAPIVersion() >= 16 then
                local AppSDK = require('root.AppSDK')
                AppSDK:AIHelper({isSetCustom = true})
            else
                --调用帮助页面接口
                local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
                local userInfo = gameMgr:GetUserInfo()
                ECServiceCocos2dx:setUserId(userInfo.playerId)
                ECServiceCocos2dx:setUserName(userInfo.playerName)
                ECServiceCocos2dx:setServerId(userInfo.serverId)
                local lang = i18n.getLang()
                local tcountry = string.split(lang, '-')[1]
                if not tcountry then tcountry = 'en' end
                if tcountry == 'zh' then tcountry = 'zh_TW' end
                ECServiceCocos2dx:setSDKLanguage(tcountry)
                ECServiceCocos2dx:showElva(tostring(userInfo.playerName),
                    tostring(userInfo.playerId),
                    checkint(userInfo.serverId),
                    "",
                    "1",{["aihelp-custom-metadata"] = {
                        ["aihelp-tags"] = "vip0,s0,and_usa",
                        ["level"] = tostring(userInfo.level),
                        ["playerId"] = tostring(userInfo.playerId),
                        ["server"]  = "0",
                        ["Conversation"] = "1",
                        ["playerName"] = tostring(userInfo.playerName),
                        ["channel"] = "and_usa",
                        ["viplevel"] = "0",
                        ["resVersion"] = tostring(utils.getAppVersion()),
                    }})
            end
         elseif isNewUSSdk()then
            self:GoToH5Actions()
        else
            local unLockPhone = false
            if gameMgr:GetUserInfo().phone  and  gameMgr:GetUserInfo().phone ~= "" then
                unLockPhone = true
            end
            if unLockPhone then
                --已绑定手机
            else
                if isEfunSdk() then
                    local AppSDK = require('root.AppSDK')
                    AppSDK.GetInstance():EfunBindPhone()
                end
            end
        end
    elseif tag == BUTTON_CLICK.CHANGE_PLAYER_HEADER then
        viewData.changeHeadLayout:setVisible(true)
        viewData.descrName:setVisible(false)
    elseif tag == BUTTON_CLICK.CHANGE_BG_CLOSE_LAYOUT then
        viewData.changeHeadLayout:setVisible(false)
        if viewData.changeLabelContent:isVisible() then
            return
        end
        viewData.descrName:setVisible(true)
    elseif tag == BUTTON_CLICK.CHANGE_HEAD then
        local   tempData  = {
            id =  gameMgr:GetUserInfo().avatar ,
            avatarFrame = gameMgr:GetUserInfo().avatarFrame,
            type = CHANGE_TYPE.CHANGE_HEAD ,
            callback = handler(self, self.ChooseHeadOrFrameCallBack)
        }
        local changeHeadOrHeadFrameMediator = require("Game.mediator.ChangeHeadOrHeadFrameMediator")
        local medaitor = changeHeadOrHeadFrameMediator.new(tempData)
        self:GetFacade():RegistMediator(medaitor)
        viewData.changeHeadLayout:setVisible(false)
    elseif tag == BUTTON_CLICK.CHANGE_HEAD_FRAME then
        local   tempData  = {
            id =  gameMgr:GetUserInfo().avatarFrame ,
            type = CHANGE_TYPE.CHANGE_HEAD_FRAME ,
            callback = handler(self, self.ChooseHeadOrFrameCallBack),
        }
        local changeHeadOrHeadFrameMediator = require("Game.mediator.ChangeHeadOrHeadFrameMediator")
        local medaitor = changeHeadOrHeadFrameMediator.new(tempData)
        self:GetFacade():RegistMediator(medaitor)
        viewData.changeHeadLayout:setVisible(false)
    elseif tag == BUTTON_CLICK.THUMB_UP then
        if CommonUtils.JuageMySelfOperation(self.datas.playerId) then
            uiMgr:ShowInformationTips(__('自己不能给自己点赞'))
        elseif  checkint(self.personData.isThumbUp)  == 1 then
            uiMgr:ShowInformationTips(__('今日已经点过赞了,欢迎明日再来点赞'))
        else
            self:SendSignal(POST.PERSON_THUMBUP.cmdName, { thumpUpPlayerId = self.datas.playerId})
        end
    elseif tag == BUTTON_CLICK.LEVEL_TIP_DESCR then
        if GAME_MODULE_OPEN.PERSON_EXP_DESCR then
            local node = require('common.ExpDesrPopUp').new()
            uiMgr:GetCurrentScene():AddDialog(node)
        else
            uiMgr:ShowIntroPopup({moduleId = MODULE_DATA[tostring(RemindTag.LEVEL)]})
        end
    elseif tag == BUTTON_CLICK.BIRTH_DAY_BTN then
        ---@type PersonInformationDetailView
        local viewComponent = self:GetViewComponent()
        local userInfo = gameMgr:GetUserInfo()
        local birthday = tostring(userInfo.birthday)
        if string.len(userInfo.birthday) > 0   then
            viewComponent:createBirthDayInfo(sender)
            self:UpdateBirthDayInfo()
        else
            uiMgr:AddDialog("common.DateSelectView")
        end
    elseif tag == BUTTON_CLICK.MORE_PERSON_INFO_BTN then
        ---@type PersonInformationDetailView
        local viewComponent = self:GetViewComponent()
        viewComponent:CreatePersonInforLayout(sender)
        self:UpdatePersonMoreInfo()
    elseif tag == BUTTON_CLICK.CUSTOM_SERVICE_BTN then
        FTUtils:openUrl("http://kr.foodfantasygame.com/")
    end
end
function PersonInformationDetailMediator:GoToH5Actions( sender )
    local function createH5View( url )
        local viewComponent = self.viewComponent
        local pos = viewComponent:convertToNodeSpace(cc.p(display.cx, display.cy))
        if not self.webviewLayer then
            local webviewLayer = display.newLayer(display.cx, display.cy, {size = display.size, ap = cc.p(0.5, 0.5), color = cc.c3b(255, 255, 255), enable = true})
            local PersonInformationMediator = AppFacade.GetInstance():RetrieveMediator('PersonInformationMediator')
            PersonInformationMediator.viewComponent:addChild(webviewLayer, 100)

            self.webviewLayer = webviewLayer
        end
        if device.platform == 'ios' or device.platform == 'android' then
            local _webView = ccexp.WebView:create()
            _webView:setAnchorPoint(cc.p(0.5, 0.5))
            _webView:setPosition(pos)
            _webView:setContentSize(cc.size(display.width, display.height))
            _webView:setScalesPageToFit(true)
            _webView:setOnShouldStartLoading(handler(self, self.HandleH5Request))
            viewComponent:addChild(_webView)

            _webView:loadURL(url)
        end
    end
    createH5View(string.format('http://notice-%s/customerService/%s/index.html', Platform.serverHost, i18n.getLang()))
end
function PersonInformationDetailMediator:HandleH5Request( webview, url )
    local scheme = 'liuzhipeng'
    local urlInfo = string.split(url, '://')
    if 2 == table.nums(urlInfo) then
        if urlInfo[1] == scheme then
            local urlParams = string.split(urlInfo[2], '&')
            local params = {}
            for k,v in pairs(urlParams) do
                local param = string.split(v, '=')
                -- 构造表单做get请求 所以结尾多一个？
                params[param[1]] = string.split(param[2], '?')[1]
            end
            if params.action then
                if 'GetUserInfo' == params.action then
                    local userinfo = {
                        id = gameMgr:GetUserInfo().playerId,
                        name = gameMgr:GetUserInfo().playerName,
                        avatarFrame = gameMgr:GetUserInfo().avatarFrame,
                        avatar = gameMgr:GetUserInfo().avatar,
                    }
                    webview:evaluateJS('onGetUserInfoAction(' .. json.encode(userinfo) .. ')')
                elseif 'reload' == params.action then
                    webview:reload()
                elseif 'close' == params.action then
                    webview:removeFromParent()
                    if self.webviewLayer then
                        self.webviewLayer:removeFromParent()
                        self.webviewLayer = nil
                    end
                else
                    return true
                end
            end
            return false
        end
    end
    return true
end

function PersonInformationDetailMediator:createURLChooseLayer( ... )
    local node = CLayout:create(display.size)

    local eaterLayer = CColorView:create(cc.c4b(0, 0, 0, 122))
    eaterLayer:setTouchEnabled(true)
    eaterLayer:setContentSize(node:getContentSize())
    eaterLayer:setPosition(utils.getLocalCenter(node))
    node:addChild(eaterLayer)
    eaterLayer:setOnClickScriptHandler(function()
        PlayAudioByClickClose()
        node:removeFromParent()
    end)

    local bg = display.newLayer(utils.getLocalCenter(node).x, utils.getLocalCenter(node).y, {enable = true, bg = _res('ui/common/common_bg_9.png'), ap = cc.p(0.5, 0.5)})
    node:addChild(bg)
    local bgSize = bg:getContentSize()

    -- title
    local titleBg = display.newButton(0, 0, {n = _res('ui/common/common_bg_title_2.png'), animation = false})
    display.commonUIParams(titleBg, {po = cc.p(bgSize.width * 0.5, bgSize.height - titleBg:getContentSize().height * 0.5 -3)})
    display.commonLabelParams(titleBg,
            {text = ('选择URL'),
             fontSize = fontWithColor('3').fontSize, color = fontWithColor('3').color,
             offset = cc.p(0, -2)})
    bg:addChild(titleBg)

    local urlBox = ccui.EditBox:create(cc.size(300, 44), _res('ui/common/common_bg_input_default.png'))
    display.commonUIParams(urlBox, {po = cc.p(utils.getLocalCenter(bg).x, bgSize.height * 0.8)})
    bg:addChild(urlBox)
    urlBox:setFontSize(fontWithColor('M2PX').fontSize)
    urlBox:setFontColor(ccc3FromInt('#9f9f9f'))
    urlBox:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
    urlBox:setPlaceHolder(('请输入URL'))
    urlBox:setPlaceholderFontSize(fontWithColor('M2PX').fontSize)
    urlBox:setPlaceholderFontColor(ccc3FromInt('#9c9c9c'))
    urlBox:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)

    local defaultButton = display.newButton(bgSize.width * 0.5, bgSize.height * 0.4, {ap = cc.p(0.5, 1), n = _res('ui/common/common_btn_orange.png')})
    display.commonLabelParams(defaultButton, fontWithColor(14,{text = ('默认')}))
    bg:addChild(defaultButton)

    local confirmButton = display.newButton(bgSize.width * 0.5, bgSize.height * 0.6, {ap = cc.p(0.5, 1), n = _res('ui/common/common_btn_orange.png')})
    display.commonLabelParams(confirmButton, fontWithColor(14,{text = ('确认')}))
    bg:addChild(confirmButton)

    node.viewData = {
        urlBox          = urlBox,
        defaultButton   = defaultButton,
        confirmButton   = confirmButton,
    }

    return node
end
-- 更换头像和头像框的回调
function PersonInformationDetailMediator:ChooseHeadOrFrameCallBack(data)
    if data then
        if data.id then
            local cmdName =  ""
            local requestData = {}
            if checkint(data.type) == CHANGE_TYPE.CHANGE_HEAD_FRAME then
                if checkint(gameMgr:GetUserInfo().avatarFrame)  ==  checkint(data.id) then

                else
                    requestData.playerAvatarFrame = data.id
                    cmdName = POST.PERSON_CHANGE_AVATAR_FRAME.cmdName
                end
            elseif checkint(data.type) == CHANGE_TYPE.CHANGE_HEAD then
                if checkint(gameMgr:GetUserInfo().avatar) ==  checkint(data.id) then
                else
                    requestData.playerAvatar = data.id
                    cmdName = POST.PERSON_CHANGE_AVATAR.cmdName

                end
            end
            self:SendSignal(cmdName, requestData )
        end
    end
end
-- 设置Label的相对偏移量
--[[
    {
        node = ,           -- 自己的node 节点
        relativeNode = ,   -- 相对relativeNode 节点
        text =             -- 文本数据
    }
--]]
function PersonInformationDetailMediator:SetOffsetLabel(data)
    local relativeSize  = display.getLabelContentSize(data.relativeNode)
    local relativePos = cc.p(data.relativeNode:getPosition())
    local pos = cc.p(relativePos.x +relativeSize.width + 10  , relativePos.y -1)
    display.commonLabelParams(data.node , { text = data.text })
    data.node:setPosition(pos)
end
--- 更新玩家的信息
function PersonInformationDetailMediator:UpdatePersonInformation()
    local viewData = self.viewComponent.viewData
    -- 玩家姓名
    local userName = self.personData.playerName or ""
    -- 玩家的id
    local playerId = self.personData.playerId or ""
    -- 玩家的等级
    local playerLevel = self.personData.level
    -- 人气
    -- 玩家的签名
    local playerSign = self.personData.playerSign or ""
    -- 玩家的头像
    -- 是否给该玩家点赞
    local isThumbup  = CommonUtils.JuageMySelfOperation(self.datas.playerId)  or self.personData.isThumbUp == 1
    -- 玩家的点赞数量
    local thumbUpNum = checkint(self.personData.thumbUpNum)
    local isRedDisPlay =  checkint(gameMgr:GetUserInfo().isFirstPhoneLock )  == 1 and true or false
    viewData.playerLabel:setString(userName)

    display.commonLabelParams(self.viewComponent.viewData.playerLabel , fontWithColor('16', {text = userName , fontSize = 22  }))
    display.reloadRichLabel(viewData.playerIDLabel, {
        c = {
            {   text ='UID' , fontSize = 20 ,color = '#5b3c25'}
        }
    })

    self:SetOffsetLabel({
        relativeNode = viewData.playerIDLabel ,
        node =  viewData.playerIDLabelValue ,
        text = playerId
    })
    display.reloadRichLabel(viewData.levelLabel, {
        c = {
            fontWithColor('10' ,{   text = __('等级:  ') , fontSize = 20 ,color = '#5b3c25'}) ,
        }
    })
    self:SetOffsetLabel({
        relativeNode = viewData.levelLabel ,
        node =  viewData.levelLabelValue ,
        text = playerLevel
    })
    -- 人气数量
    display.reloadRichLabel(viewData.popularityLabel, {
        c = {
            fontWithColor('10' ,{   text = __('人气:  ') , fontSize = 20 ,color = '#5b3c25'}),
        }} )
    self:SetOffsetLabel({
        relativeNode = viewData.popularityLabel ,
        node =  viewData.popularityLabelValue ,
        text = thumbUpNum
    })

    if CommonUtils.GetIsOpenPhone() then
        if isRedDisPlay then
            local node =  viewData.bindingBtn:getChildByTag(RED_TAG)
            if node and ( not  tolua.isnull(node )) then
                node:setVisible(true)
            end
            display.commonLabelParams(viewData.bindingBtn , {text = __('实名认证')})
        else
            if isEfunSdk() then
                if gameMgr:GetUserInfo().isFirstPhoneLock == 0 then
                    viewData.bindingBtn:setVisible(false)
                else
                    if gameMgr:GetUserInfo().phone and gameMgr:GetUserInfo().phone ~="" then
                        display.commonLabelParams(viewData.bindingBtn , {text = __('解除认证')})
                    else
                        display.commonLabelParams(viewData.bindingBtn , {text = __('实名认证')})
                    end
                end
            else
                if gameMgr:GetUserInfo().phone and gameMgr:GetUserInfo().phone ~="" then
                    display.commonLabelParams(viewData.bindingBtn , {text = __('解除认证')})
                else
                    display.commonLabelParams(viewData.bindingBtn , {text = __('实名认证')})
                end
            end
        end
    end

    local userInfo = gameMgr:GetUserInfo()
    local birthdayStr = userInfo.birthday
    if string.len(birthdayStr) == 0  then
        local birthBtn = viewData.birthBtn
        local image    = birthBtn:getChildByTag(RED_TAG)
        image:setVisible(true)
    end
    if isThumbup then
        viewData.landDefaultImage:setNormalImage(_res('ui/home/infor/personal_information_btn_laud_select.png') ) -- 不可以点赞
        viewData.landDefaultImage:setSelectedImage(_res('ui/home/infor/personal_information_btn_laud_select.png') ) -- 不可以点赞
    end
    display.reloadRichLabel(viewData.decLabel, { c = CommonUtils.dealWithEmoji(fontWithColor('6' ),playerSign) })
    viewData.decLabel:setPosition(cc.p(180,0))
    local rect =  viewData.decLabel:getBoundingBox()
    viewData.decLabelLayout:setContentSize(cc.size(360, rect.height))
    viewData.scrollView:reloadData()
    viewData.scrollView:setContentOffsetToTop()
    self.viewComponent:setVisible(true)
end

function PersonInformationDetailMediator:UpdatePersonMoreInfo()
    local viewData = self.viewComponent.viewData
    -- 拥有卡牌的总数量
    local cardTotalNum = cardMgr.GetAllCardsNum()
    -- 拥有的卡牌数量
    local onwerNum = checkint(self.personData.cardNum)
    -- 餐厅的等级
    local restaurantLevel = self.personData.restaurantLevel or "0"
    -- 邪神遗迹的最高层
    local towerMaxFloor = self.personData.towerMaxFloor or "0"

    local unionInfo =  self.personData.unionInfo or {}
    local unionName = unionInfo.name or  ""
    local skinNum = checkint(self.personData.cardSkinNum)
    local skinTotalNum = cardMgr.GetAllCardsSkinNums()
    display.reloadRichLabel(viewData.cardCollectLabel, {
        c = {
            fontWithColor('16' ,{   text = __('飨灵收集度: ') }) ,
            fontWithColor('6' ,{ text =  string.format("%d/%d" , checkint(onwerNum) , checkint(cardTotalNum)) })
        }
    })

    display.reloadRichLabel(viewData.cardSkinNum, {
        c = {
            fontWithColor('16' ,{   text = __('外观收集度: ') }) ,
            fontWithColor('6' ,{ text = string.format("%d/%d" , checkint(skinNum) , checkint(skinTotalNum)) })
        }
    })
    if unionName ~= "" then
        if not  CommonUtils.JuageMySelfOperation(self.datas.playerId) then

            display.reloadRichLabel(viewData.unionName, {
                c = {
                    fontWithColor('16' ,{   text =__('工会名称:  ') ,color = '#5b3c25'}) ,
                    fontWithColor('6' ,{ text = unionName})
                }
            })
        else
            viewData.unionName:setVisible(false)
        end
    else
        viewData.unionName:setVisible(false)
    end
    if CommonUtils.GetModuleAvailable(MODULE_SWITCH.RESTAURANT) then
        display.reloadRichLabel(viewData.restaurtantLabel, {
            c = {
                fontWithColor('16' ,{   text = __('餐厅等级: ') }) ,
                fontWithColor('6' ,{ text =   restaurantLevel })
            }
        })
    else
        viewData.restaurtantLabel:setVisible(false)
    end
    if CommonUtils.GetModuleAvailable(MODULE_SWITCH.TOWER) then
        display.reloadRichLabel(viewData.towerMaxFooler, {
            c = {
                fontWithColor('16' ,{   text = __('邪神遗迹最高层: ') }) ,
                fontWithColor('6' ,{ text = towerMaxFloor })
            }
        })
    if not isJapanSdk() then CommonUtils.SetNodeScale(viewData.towerMaxFooler , {width = 350} ) end
    if not CommonUtils.GetModuleAvailable(MODULE_SWITCH.RESTAURANT) then
            viewData.towerMaxFooler:setPositionY(viewData.restaurtantLabel:getPositionY())
        end
    else
        viewData.towerMaxFooler:setVisible(false)
    end
end

function PersonInformationDetailMediator:UpdateBirthDayInfo()
    local viewData = self.viewComponent.viewData
    local userInfo = gameMgr:GetUserInfo()
    local birthdayStr = userInfo.birthday
    local birthTable = string.split(birthdayStr , "-")
    display.commonLabelParams(viewData.birthDataLabel, fontWithColor(6 , { text = string.fmt(__('_num1_年_num2_月_num3_日'),{_num1_ = checkint(birthTable[1]),_num2_ = checkint(birthTable[2]) ,_num3_ = checkint(birthTable[3]) })}))
end

-- 进入界面请求
function PersonInformationDetailMediator:EnterLayer()
    self:SendSignal(POST.PLAYER_PERSON_INFO.cmdName , {personalPlayerId = self.datas.playerId})
end


function PersonInformationDetailMediator:OnRegist()
    regPost(POST.CHANGE_PLAYER_SIGN)
    regPost(POST.PLAYER_ZM_BIND_ACCOUNT)
    regPost(POST.CHANGE_PLAYER_NAME)
    regPost(POST.PLAYER_GET_LOCK_VERIFICATION)
    regPost(POST.PLAYER_GET_UNLOCK_VERIFICATION)
    regPost(POST.PLAYER_LOCK_PHONE)
    regPost(POST.PLAYER_UNLOCK_PHONE)
    regPost(POST.PLAYER_PERSON_INFO)
    regPost(POST.PERSON_THUMBUP) -- 点赞接口
    regPost(POST.PERSON_CHANGE_AVATAR) -- 更换头像
    regPost(POST.PERSON_CHANGE_AVATAR_FRAME) --更换头像框
    regPost(POST.PERSON_BIRTHDAY) --设置生日
    self:EnterLayer()
    AppFacade.GetInstance():DispatchObservers(FRIEND_REFRESH_EDITBOX, {isEnabled = false })
end

function PersonInformationDetailMediator:OnUnRegist()
    AppFacade.GetInstance():DispatchObservers(FRIEND_REFRESH_EDITBOX, {isEnabled = true})
    unregPost(POST.CHANGE_PLAYER_SIGN)
    unregPost(POST.CHANGE_PLAYER_NAME)
    unregPost(POST.PLAYER_GET_LOCK_VERIFICATION)
    unregPost(POST.PLAYER_GET_UNLOCK_VERIFICATION)
    unregPost(POST.PLAYER_LOCK_PHONE)
    unregPost(POST.PLAYER_UNLOCK_PHONE)
    unregPost(POST.PLAYER_PERSON_INFO)
    unregPost(POST.PERSON_THUMBUP)
    unregPost(POST.PERSON_CHANGE_AVATAR_FRAME)
    unregPost(POST.PERSON_CHANGE_AVATAR)
    unregPost(POST.PERSON_BIRTHDAY)
    for i, v in pairs(PersonDeatailTableMediator) do
        self:GetFacade():UnRegsitMediator(v)
    end
end

return PersonInformationDetailMediator



