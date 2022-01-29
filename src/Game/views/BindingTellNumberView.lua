
--- Created by xingweihao.
--- DateTime: 25/10/2017 3:29 PM
---
---@class BindingTellNumberView
local BindingTellNumberView = class('home.BindingTellNumberView',function ()
    local node = CLayout:create( display.size )
    node.name = 'Game.views.BindingTellNumberView'
    node:enableNodeEvents()
    return node
end)
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local facade = AppFacade.GetInstance()
local BUTTON_CLICK = {
    INPUT_TELL_NUMBER = 100011 , -- 输入手机号
    INPUT_VERIFICATION_CODE  = 100012 , -- 输入验证吗
    MAKE_SURE = 100022,
}
function BindingTellNumberView:ctor(param )
    self.isFirstPhoneLock = param.isFirstPhoneLock
    self.tellNumber = param.tellNumber or ""        -- 电话号码
    self.unLockPhone = param.unLockPhone
    self.verificationcode = ""  -- 验证码
    self.countDownTimes =  0  -- 倒计时
    self:initUI()
    self:RegisterObserver()
end
function BindingTellNumberView:initUI()
    -- body
    local closeLayer = display.newLayer(display.cx, display.cy ,{ ap =  display.CENTER , size = display.size , color = cc.c4b(0,0,0,100 ) , enable  = true ,cb = function ()
        self:removeFromParent()
    end})
    self:addChild(closeLayer)
    local bgSize = cc.size(435 ,308)
    local bgLayout  = display.newLayer(display.cx, display.cy ,{ ap =  display.CENTER , size = bgSize})
    self:addChild(bgLayout)
    -- 吞噬层
    local swallowLayer = display.newLayer(bgSize.width/2 , bgSize.height/2 ,{ ap =  display.CENTER , size = bgSize , color =  cc.c4b(0,0,0,0 ), enable  = true })
    bgLayout:addChild(swallowLayer)
    -- 背景的图片
    local bgImage =  display.newImageView(_res("ui/common/common_bg_8.png"),bgSize.width/2 , bgSize.height/2)
    bgLayout:addChild(bgImage)
    closeLayer:setPosition(display.center)
    -- 手机内容
    local tellSize = cc.size(380, 50)
    local tellLayout  =  display.newLayer(bgSize.width/2 , bgSize.height - 47   ,{ ap =  display.CENTER_TOP , size = tellSize ,  enable  = true })
    bgLayout:addChild(tellLayout)

    -- 手机号
    local tellLabel = display.newLabel( 27,  tellSize.height /2  , fontWithColor('16' , { ap = display.LEFT_CENTER,  text = __('手机号')})  )
    tellLayout:addChild(tellLabel)

    local editBoxBg = display.newImageView(_res('ui/common/common_roles_bg_name.png') , 0,0 , { size = cc.size(220 , 50 ) , ap = display.LEFT_CENTER, scale9 = true })
    local editBoxBgSize = cc.size(260,50)

    local editBoxLayout = display.newLayer(100  , tellSize.height/2  , { ap = display.LEFT_CENTER , size = editBoxBgSize })
    editBoxBg:setPosition(cc.p(0, editBoxBgSize.height/2))
    editBoxLayout:addChild(editBoxBg)
    local editorTellNum = ccui.EditBox:create(cc.size(210, 35), 'empty')
    display.commonUIParams(editorTellNum, {po = cc.p(2 , editBoxBgSize.height/2),ap = cc.p(0,0.5)})
    editorTellNum:setFontSize(20)
    editorTellNum:setTag(BUTTON_CLICK.INPUT_TELL_NUMBER)
    editorTellNum:setFontColor(ccc3FromInt('#5b3c25'))
    editorTellNum:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
    editorTellNum:setPlaceHolder(__('请输入手机号'))
    editorTellNum:setPlaceholderFontSize(20)
    editorTellNum:setMaxLength(11)
    editorTellNum:setPlaceholderFontColor(ccc3FromInt('#8c8c8c'))
    editorTellNum:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
    editorTellNum:registerScriptEditBoxHandler(function(eventType,sender)
        if eventType == 'began' then  -- 输入开始
        elseif eventType == 'ended' then  -- 输入结束
            self:EditBoxClick(sender)
        elseif eventType == 'changed' then  -- 内容变化
        elseif eventType == 'return' then  -- 从输入返回
            self:EditBoxClick(sender)
        end
    end)
    local tipBtn = display.newButton(editBoxBgSize.width-15 , editBoxBgSize.height/2 , { n = _res('ui/common/common_btn_tips') , s = _res('ui/common/common_btn_tips') , cb = function (sender)
        local node =  editBoxLayout:getChildByName("layout")
        if node then
            node:removeFromParent()
            return
        end
        local str = __('绑定手机号仅作为实名认证不作为账号归属的依据')
        local tipLabel = display.newLabel(0,0, fontWithColor(6,{text = str , w = 200 }))
        local contentSize = display.getLabelContentSize(tipLabel)
        contentSize = cc.size(contentSize.width + 50 , contentSize.height +20)
        tipLabel:setPosition(cc.p(contentSize.width/2 , contentSize.height/2))

        local layout = display.newLayer(contentSize.width/2, contentSize.height/2, { size = contentSize ,ap = display.CENTER_BOTTOM ,color =cc.c4b(0,0,0,0)})
        layout:addChild(tipLabel ,2)
        local image  = display.newImageView( _res('ui/common/common_bg_tips_common'),contentSize.width/2,contentSize.height/2, { scale9 = true , ap =  display.CENTER, size = contentSize})
        layout:addChild(image)
        local tipImage = display.newImageView(_res('ui/common/common_bg_tips_horn') , contentSize.width/2,3  )
        layout:addChild(tipImage)
        tipImage:setScale(-1)
        local pos = cc.p(sender:getPosition())   -- sender:getParent():convertToWorldSpace(cc.p( sender:getPosition()))
        layout:setPosition(cc.p(pos.x , pos.y + 30))
        editBoxLayout:addChild(layout)
        layout:setName("layout")
    end})
    editBoxLayout:addChild(tipBtn)
    if self.unLockPhone then
        editorTellNum:setVisible(false)
        -- 显示手机号如果是解绑 则不能编辑
        local editorLabel =  display.newLabel(20 , editBoxBgSize.height/2 ,  fontWithColor('10' , { color = '#5b3c25' , ap = display.LEFT_CENTER ,text = self.tellNumber }))
        editBoxLayout:addChild(editorLabel)
    end
    editBoxLayout:addChild(editorTellNum)
    tellLayout:addChild(editBoxLayout)
    editorTellNum:setText(tostring(self.tellNumber))

    -- 验证码
    local verificationCodeLayout  =  display.newLayer(bgSize.width/2 , bgSize.height - 120   ,{ ap =  display.CENTER_TOP , size = tellSize , enable  = true })
    bgLayout:addChild(verificationCodeLayout)

    -- 验证码
    local  verificationCodeLabel  = display.newLabel( 27,  tellSize.height /2  , fontWithColor('16' , { ap = display.LEFT_CENTER,  text = __('验证码')})  )
    verificationCodeLayout:addChild(verificationCodeLabel)
    local editBoxBgSize = cc.size(144 , 50 )
    local editBoxBg = display.newImageView(_res('ui/common/common_roles_bg_name') , 0,0, { scale9 = true , size =  editBoxBgSize})

    local editBoxLayout = display.newLayer(100  , tellSize.height/2  , { ap = display.LEFT_CENTER , size =editBoxBgSize })
    editBoxBg:setPosition(cc.p(editBoxBgSize.width/2 , editBoxBgSize.height/2))
    editBoxLayout:addChild(editBoxBg)
    -- 输入验证码逻辑
    local editorVerificationNum = ccui.EditBox:create(cc.size(136, 35), 'empty')
    display.commonUIParams(editorVerificationNum, {po = cc.p(4 , editBoxBgSize.height/2),ap = cc.p(0,0.5)})
    editorVerificationNum:setFontSize(20)
    editorVerificationNum:setTag(BUTTON_CLICK.INPUT_VERIFICATION_CODE)
    editorVerificationNum:setFontColor(ccc3FromInt('#5b3c25'))
    editorVerificationNum:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)
    editorVerificationNum:setPlaceHolder(__('请输入验证码'))
    editorVerificationNum:setPlaceholderFontSize(20)
    editorVerificationNum:setPlaceholderFontColor(ccc3FromInt('#8c8c8c'))
    editorVerificationNum:setReturnType(cc.KEYBOARD_RETURNTYPE_DONE)
    editorVerificationNum:setMaxLength(6)
    editorVerificationNum:registerScriptEditBoxHandler(function(eventType,sender)
        if eventType == 'began' then  -- 输入开始
        elseif eventType == 'ended' then  -- 输入结束
            self:EditBoxClick(sender)
        elseif eventType == 'changed' then  -- 内容变化
        elseif eventType == 'return' then  -- 从输入返回
            self:EditBoxClick(sender)
        end
    end)
    -- tianjia
    editBoxLayout:addChild(editorVerificationNum)
    verificationCodeLayout:addChild(editBoxLayout)
    -- 验证码
    local verificationBtn = display.newButton(252   ,tellSize.height/2,{
        n = _res('ui/common/common_btn_orange.png'),
        s = _res('ui/common/common_btn_orange.png'),
        d =  _res('ui/common/common_btn_orange_disable.png'),
        ap = display.LEFT_CENTER
    })
    display.commonLabelParams(verificationBtn,fontWithColor(14,{fontSize =22 , text = __('获取验证码')}))
    verificationCodeLayout:addChild(verificationBtn)
    verificationBtn:setScale(0.9)
    verificationBtn:setOnClickScriptHandler(handler(self , self.GetVerificationUnlockOrLock))
    -- 修改名字的btn 按钮
    local bindingBtn = display.newButton(bgSize.width/2   ,40,{
        n = _res('ui/common/common_btn_orange.png'),ap = display.CENTER_BOTTOM
    })
    local text  =__('绑定')
    if self.unLockPhone then
        text = __('解除绑定')
    end
    display.commonLabelParams(bindingBtn,fontWithColor(14,{text = text}))
    bgLayout:addChild(bindingBtn)
    display.commonUIParams(bindingBtn , fontWithColor('14' , { cb = handler(self , self.SendVerificationTell)}))
    local iconPath = CommonUtils.GetGoodsIconPathById(DIAMOND_ID)
    -- 消耗幻晶石的
    if checkint(self.isFirstPhoneLock)  == 1  then  -- 如果是首次绑定获取100 幻晶石
        local rewardDiamond = display.newRichLabel(bgSize.width/2    , 27 , { r = true , c =  {
            fontWithColor(16, { text = string.format(__('首次绑定奖励%d') , 100)}) ,
            {img =  iconPath  , scale =  0.2  }
        }})
        bgLayout:addChild(rewardDiamond)

    end
    --基本设置标签
    self.viewData =  {
        editorTellNum = editorTellNum ,
        editorVerificationNum = editorVerificationNum,
        bindingBtn = bindingBtn ,
        verificationBtn = verificationBtn ,
        tipBtn = tipBtn
    }
end
-- 走倒计时
function BindingTellNumberView:RunCountTimes(signal)
    local data = signal:GetBody()
    local tag = checkint(data.tag)
    if tag == RemindTag.BINDING_TELL  then
        local countdown = checkint(data.countdown)
        if countdown == 0 then
            self.viewData.verificationBtn:setEnabled(true)
            display.commonLabelParams( self.viewData.verificationBtn , fontWithColor('14' ,{ fontSize = 22 , text = __('获取验证码')}) )
        else
            self.viewData.verificationBtn:setEnabled(false)
            display.commonLabelParams( self.viewData.verificationBtn , fontWithColor('14' ,{ fontSize = 22 , text = string.format(__('倒计时:%d') , countdown)}) )
        end
    end

end
-- 编辑事件
function BindingTellNumberView:EditBoxClick(sender)
    local tag = sender:getTag()
    if tag == BUTTON_CLICK.INPUT_TELL_NUMBER then
        local str = sender:getText()
        self.tellNumber = str
    elseif tag == BUTTON_CLICK.INPUT_VERIFICATION_CODE then
        local str = sender:getText()
        self.verificationcode = str
    end
end
-- 获取验证码
function BindingTellNumberView:GetVerificationUnlockOrLock(sender)
    local tellLength = string.len(self.tellNumber)
    if tellLength ==11 and tonumber(self.tellNumber) then
        if self.unLockPhone then
            AppFacade.GetInstance():DispatchSignal(POST.PLAYER_GET_UNLOCK_VERIFICATION.cmdName ,{ phone = self.tellNumber })
        else
            AppFacade.GetInstance():DispatchSignal(POST.PLAYER_GET_LOCK_VERIFICATION.cmdName ,{ phone = self.tellNumber })
        end
    else
        uiMgr:ShowInformationTips(__('手机号不正确'))
    end
end
-- 发送验证码和电话号码
function BindingTellNumberView:SendVerificationTell()
    if self.verificationcode  and self.verificationcode ~= "" then
        local len = string.len(self.verificationcode)
        if len == 6 then
            local num  =  tonumber(self.verificationcode)
            if num then
                if tonumber(self.tellNumber) then
                    local tellLength = string.len(self.tellNumber)
                    if tellLength ==11 then
                        if not  self.unLockPhone then

                            print("self.tellNumber" , self.tellNumber)
                            print("self.self.verificationcode " , self.verificationcode )
                            AppFacade.GetInstance():DispatchSignal(POST.PLAYER_LOCK_PHONE.cmdName ,{ phone = self.tellNumber , verificationCode =  tostring(self.verificationcode)   })
                        else
                            AppFacade.GetInstance():DispatchSignal(POST.PLAYER_UNLOCK_PHONE.cmdName ,{ phone = self.tellNumber , verificationCode = tostring( self.verificationcode )  })
                        end
                    else
                        uiMgr:ShowInformationTips(__('手机号不正确'))
                    end
                else
                    uiMgr:ShowInformationTips(__('手机号不正确'))
                end

            else
                uiMgr:ShowInformationTips(__('验证码不正确'))
            end
        else
            uiMgr:ShowInformationTips(__('验证码不正确'))
        end
    else
        uiMgr:ShowInformationTips(__('验证码不能为空'))
    end
end
-- 注册观察者
function BindingTellNumberView:RegisterObserver()
    facade:RegistObserver(COUNT_DOWN_ACTION , mvc.Observer.new(self.RunCountTimes , self))
end

function BindingTellNumberView:onCleanup()
    facade:UnRegistObserver(COUNT_DOWN_ACTION ,self)
end
return BindingTellNumberView