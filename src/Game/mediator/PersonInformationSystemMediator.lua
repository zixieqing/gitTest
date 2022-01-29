
---
--- Created by xingweihao.
--- DateTime: 24/10/2017 5:54 PM
---

---
--- Created by xingweihao.
--- DateTime: 27/09/2017 2:35 PM
--- 交易和探索的修改

local Mediator = mvc.Mediator
---@class PersonInformationSystemMediator :Mediator
local PersonInformationSystemMediator = class("PersonInformationSystemMediator", Mediator)
local NAME = "PersonInformationSystemMediator"
local downChineseVoiceFile = require("Game.mediator.DownChineseVoiceFile").GetInstance()
---@type GameManager
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
---@type UIManager
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local BUTTON_CLICK = {

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
    -- FACEBOOK_BUTTON                 = 1032,
    REMIND_PUSH                     = 1031, -- 推送提醒
    MARQUEE_PUSH                    = 1032, -- 跑马灯
    WORLD_CHANNEL_PUSH              = 1033,  -- 世界频道的推送
    CHAT_PUSH                       = 1034,  -- 聊天的推送
    WORLD_BOSS_PUSH                 = 1041, --世界boss 推送

}
function PersonInformationSystemMediator:ctor( layer, viewComponent )
    self.super:ctor(NAME,viewComponent)
    self.preIndex = nil  -- 上一次点击
    self.localData  = {}
    self.remoteData = {}
    self.diffData = {}
end

function PersonInformationSystemMediator:InterestSignals()
    local signals = {
        VOICE_DOWNLOAD_EVENT
    }
    return signals
end
function PersonInformationSystemMediator:Initial( key )
    self.super.Initial(self,key)
    ---@type PersonInformationSystemView
    self.viewComponent = require("Game.views.PersonInformationSystemView").new()
    self:SetViewComponent(self.viewComponent)
    for k , v in pairs(self.viewComponent.viewData.cellTable) do
        v.pSwitchControl:setOnClickScriptHandler(handler(self , self.ButtonAction))
        if v.pSlider and ( not tolua.isnull(v.pSlider)) then
            v.pSlider:registerControlEventHandler(handler(self,self.ButtonAction), cc.CONTROL_EVENTTYPE_VALUE_CHANGED)
        end
    end
    for k , v in pairs(self.viewComponent.viewData.checkBoxTable) do  -- 选择声音的控制
        v.button:setOnClickScriptHandler(handler(self , self.ButtonAction))
    end
    local viewData =  self.viewComponent.viewData
    viewData.chineseVoiceBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
    viewData.japanseVoiceBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
    viewData.additionalBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
    local viewData =  self.viewComponent.viewData
    --viewData.voiceLayout:setVisible(true)
    if downChineseVoiceFile.isDownLoad == 0 then
        self:GetRemoteChineseVocieData()
        self:UpdateStatus()
    else
        self.localData = self:GetLocalChineseVocieData()
        self.remoteData = app.audioMgr:GetRemoteChineseData()
        self.diffData = self:CompareLocalAndRemoteData(self.localData , self.remoteData)
        viewData.voiceLayout:setVisible(true)
        self:UpdateStatus()
    end

    -- 退出游戏
    viewData.exitGameBtn:setOnClickScriptHandler(handler(self , self.ButtonAction))
    -- viewData.facebookRelateButton:setOnClickScriptHandler(handler(self , self.ButtonAction))
    -- 重新登录
    viewData.reloadGameBtn:setOnClickScriptHandler(handler(self , self.ButtonAction))
    
    self:UpdatePushBtnStatus()
    self:UpdateWorldStatuse()
end
function PersonInformationSystemMediator:UpdateWorldStatuse()
    local worldChannel = CommonUtils.GetControlGameProterty(CONTROL_GAME.CHAT_PUSH)
    local marquee = CommonUtils.GetControlGameProterty(CONTROL_GAME.MARQUEE_PUSH)
    local viewData = self.viewComponent.viewData

    for k , v in pairs(viewData.worldTable) do
        local pushBtn = v:getChildByName("pushBtn")

        if checkint( k) == BUTTON_CLICK.MARQUEE_PUSH then
            self:SetIsChecked(pushBtn , marquee)
        elseif  checkint( k) == BUTTON_CLICK.CHAT_PUSH then
            self:SetIsChecked(pushBtn , worldChannel)
        end
        pushBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
    end
end
--[[
    更新推送按钮的状态
--]]
function PersonInformationSystemMediator:UpdatePushBtnStatus()

    local isOpenPush  = CommonUtils.GetPushNoticeIsOpen()
    local viewData = self.viewComponent.viewData
    if isOpenPush then
        local hpRecordIsOpen       = CommonUtils.GetPushLocalNoticeStatusByType(PUSH_LOCAL_NOTICE_NAME_TYPE.HP_RECOVER_TYPE)
        local loveFoodRecordIsOpen = CommonUtils.GetPushLocalNoticeStatusByType(PUSH_LOCAL_NOTICE_NAME_TYPE.LOVE_FOOD_RECOVER_TYPE )
        local publishOrderIsOpen   = CommonUtils.GetPushLocalNoticeStatusByType(PUSH_LOCAL_NOTICE_NAME_TYPE.PUBLISH_ORDER_RECOVER_TYPE )
        local airLiftRecoverIsOpen = CommonUtils.GetPushLocalNoticeStatusByType(PUSH_LOCAL_NOTICE_NAME_TYPE.AIR_LIFT_RECOVER_TYPE )
        local worldBossIsOpen = CommonUtils.GetPushLocalNoticeStatusByType(PUSH_LOCAL_NOTICE_NAME_TYPE.WORLD_BOSS_PUSH_TYPE )
        for k , v in pairs(viewData.pushTable) do
            local pushBtn = v:getChildByName("pushBtn")
            if checkint( k) == BUTTON_CLICK.HP_FULL_PUSH_LOCAL then
                self:SetIsChecked(pushBtn , hpRecordIsOpen)
            elseif checkint( k) == BUTTON_CLICK.LOVE_FOOD_RECOVER_PUSH_LOCAL then
                self:SetIsChecked(pushBtn , loveFoodRecordIsOpen)
            elseif checkint( k) == BUTTON_CLICK.PUBLISH_ORDER_RECOVER_LOCAL then
                self:SetIsChecked(pushBtn , publishOrderIsOpen)
            elseif checkint( k) == BUTTON_CLICK.AIR_TAKEAWAY_PUSH_LOCAL then
                self:SetIsChecked(pushBtn , airLiftRecoverIsOpen)
            elseif checkint( k) == BUTTON_CLICK.WORLD_BOSS_PUSH then
                self:SetIsChecked(pushBtn , worldBossIsOpen)
            end
            pushBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
        end
        if not CommonUtils.GetModuleAvailable(MODULE_SWITCH.AIR_TRANSPORTATION) then
            CommonUtils.CancelPushLocalNoticeByType(PUSH_LOCAL_NOTICE_NAME_TYPE.AIR_LIFT_RECOVER_TYPE)
        end
        if not CommonUtils.GetModuleAvailable(MODULE_SWITCH.PUBLIC_ORDER) then
            CommonUtils.CancelPushLocalNoticeByType(PUSH_LOCAL_NOTICE_NAME_TYPE.PUBLISH_ORDER_RECOVER_TYPE)
        end
        if not CommonUtils.GetModuleAvailable(MODULE_SWITCH.WORLD_BOSS) then
            CommonUtils.CancelPushLocalNoticeByType(PUSH_LOCAL_NOTICE_NAME_TYPE.WORLD_BOSS_PUSH_TYPE)
        end
    else
        for k , v in pairs(viewData.pushTable) do
            local pushBtn = v:getChildByName("pushBtn")
            self:SetIsChecked(pushBtn , false)
            pushBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
        end
    end

    if isOpenPush then
        if viewData.remindCheckBtn then
            viewData.remindCheckBtn:setChecked(true)
        end
    end
    if device.platform == 'ios' then
        if viewData.narrateLabel then
            viewData.narrateLabel:setVisible(true)
        end
    else
        if viewData.narrateLabel then
            viewData.narrateLabel:setVisible(false)
        end
    end
    viewData.remindCheckBtn:setOnClickScriptHandler(handler(self, self.ButtonAction))
end
--[[
    设置是否被选中
--]]
function PersonInformationSystemMediator:SetIsChecked(sender , checked)
    local openLabel = sender:getChildByTag(115)
    local closeLabel = sender:getChildByTag(116)
    if openLabel and not  tolua.isnull(openLabel) then
        openLabel:setVisible(checked)
    end
    if closeLabel and not  tolua.isnull(closeLabel) then
        closeLabel:setVisible(not checked)
    end
    sender:setChecked(checked)
end
--[[
    设置滑块的触摸事件的开关
--]]
function PersonInformationSystemMediator:SetControlSliderEnabled( isEnabled )
    for k , v in pairs(self.viewComponent.viewData.cellTable) do
        if v.pSlider and ( not tolua.isnull(v.pSlider)) then
            v.pSlider:setEnabled(isEnabled)
        end
    end
end
-- 点击事件
function PersonInformationSystemMediator:ButtonAction(sender)
    local clickTag = sender:getTag()
    if (clickTag >= BUTTON_CLICK.CONRROL_MUSIC and clickTag <= BUTTON_CLICK.GAME_VOICE) or
            (clickTag >= BUTTON_CLICK.ONELY_WIFI_OPEN and clickTag <= BUTTON_CLICK.PRIVATE_CHAT_VOICE_AUTO_PLAY) then
        PlayAudioByClickNormal()
        local checked = sender:isChecked()
        CommonUtils.SetControlGameProterty(sender.data.senderName,checked)
        local openLabel = sender:getChildByTag(115)
        local closeLabel = sender:getChildByTag(116)
        if openLabel and not  tolua.isnull(openLabel) then
            openLabel:setVisible(checked)
        end
        if closeLabel and not  tolua.isnull(closeLabel) then
            closeLabel:setVisible(not checked)
        end
        if clickTag == BUTTON_CLICK.GAME_VOICE then
            self.viewComponent.viewData.wiftLayout:setVisible(checked)
            self.viewComponent.viewData.buttomLayout:setVisible(checked)
        end
    elseif (clickTag >= BUTTON_CLICK.CONTREL_MUSIC_BIGORLITTLE and clickTag <= BUTTON_CLICK.CONTREL_GAME_VOICE_BIGORLITTLE)  then
        --PlayAudioByClickNormal()
        local num =  sender:getValue()
        CommonUtils.SetControlGameProterty(sender.data.senderSliderName, num - num%0.1)
    elseif clickTag == BUTTON_CLICK.RELOADGAME then
        PlayAudioByClickNormal()
        downChineseVoiceFile:SetStopDownload()
        gameMgr:ShowExitGameView(__('重新登录游戏将会清空缓存数据，请确认没有进行中的数据需要保存'), false)

    elseif  clickTag == BUTTON_CLICK.EXITGAME then
        PlayAudioByClickNormal()
        downChineseVoiceFile:SetStopDownload()
        CommonUtils.ExitGame()
    elseif clickTag == BUTTON_CLICK.FACEBOOK_BUTTON then
        --fb邀请的逻辑入口
        PlayAudioByClickNormal()
        if isEfunSdk() then
            local binding = 'no'
            -- 安卓平台是不用绑定的
            if device.platform == "android" then
                binding = 'no'
            else
                local userInfo = gameMgr:GetUserInfo()
                binding = cc.UserDefault:getInstance():getStringForKey(string.format('FACEBOOK_BINDING_%s',tostring(userInfo.playerId)), "no")
            end
            if binding == 'success' then
                --如果是已绑定过的，直接进入邀请页面
                AppFacade.GetInstance():RetrieveMediator('Router'):Dispatch({name = 'HomeMediator'}, {name = 'FacebookInviteMediator'})
            else
                require('root.AppSDK').GetInstance():relateFacebookToEfun()
            end
        else
            AppFacade.GetInstance():RetrieveMediator('Router'):Dispatch({name = 'HomeMediator'}, {name = 'FacebookInviteMediator'})
        end
    elseif clickTag == BUTTON_CLICK.CHOOSE_JAPANESE_BTN then
        PlayAudioByClickNormal()
        app.audioMgr:SetVoiceType(PLAY_VOICE_TYPE.JAPANESE)
        local viewData  =self.viewComponent.viewData
        viewData.japanseVoiceBtn:setChecked(true)
        viewData.chineseVoiceBtn:setChecked(false)
        viewData.japanseVoiceBtn:setEnabled(false)
        viewData.chineseVoiceBtn:setEnabled(true )
    elseif clickTag == BUTTON_CLICK.CHOOSE_CHINESE_BTN then
        PlayAudioByClickNormal()
        app.audioMgr:SetVoiceType(PLAY_VOICE_TYPE.CHINESE)
        local viewData  =self.viewComponent.viewData
        viewData.japanseVoiceBtn:setChecked(false)
        viewData.chineseVoiceBtn:setChecked(true)
        viewData.japanseVoiceBtn:setEnabled(true)
        viewData.chineseVoiceBtn:setEnabled(false )
    elseif clickTag == BUTTON_CLICK.CHOOSE_CHINESE_ADD_BTN then
        PlayAudioByClickNormal()
        local voiceValue = ''
        if isNewUSSdk() then
            voiceValue = __('中文语音')
        elseif isElexSdk()  then
            voiceValue = __('日文语音')
        end
        local voiceTip = require("Game.views.NewDownloadVoiceTip").new({voiceValue = voiceValue })
        local scene = uiMgr:GetCurrentScene()
        scene:AddDialog(voiceTip)
        voiceTip:setPosition(display.center)
    elseif clickTag == BUTTON_CLICK.LOVE_FOOD_RECOVER_PUSH_LOCAL then   -- 爱心便当的领取
        PlayAudioByClickNormal()
        local isChecked  = sender:isChecked()
        self:SetPushStatus(isChecked , PUSH_LOCAL_NOTICE_NAME_TYPE.LOVE_FOOD_RECOVER_TYPE)
        self:SetIsChecked(sender,  isChecked)
    elseif clickTag == BUTTON_CLICK.WORLD_BOSS_PUSH then   -- 世界boss
        PlayAudioByClickNormal()
        local isChecked  = sender:isChecked()
        self:SetPushStatus(isChecked , PUSH_LOCAL_NOTICE_NAME_TYPE.WORLD_BOSS_PUSH_TYPE)
        self:SetIsChecked(sender,  isChecked)
    elseif clickTag == BUTTON_CLICK.HP_FULL_PUSH_LOCAL then -- 体力回满
        PlayAudioByClickNormal()
        local isChecked  = sender:isChecked()
        self:SetPushStatus(isChecked , PUSH_LOCAL_NOTICE_NAME_TYPE.HP_RECOVER_TYPE)
        self:SetIsChecked(sender,  isChecked)
    elseif clickTag == BUTTON_CLICK.PUBLISH_ORDER_RECOVER_LOCAL then  -- 公有订单是否开启
        PlayAudioByClickNormal()
        local isChecked  = sender:isChecked()
        self:SetPushStatus(isChecked , PUSH_LOCAL_NOTICE_NAME_TYPE.PUBLISH_ORDER_RECOVER_TYPE)
        local isChecked  = sender:isChecked()
        self:SetIsChecked(sender,  isChecked)
    elseif clickTag == BUTTON_CLICK.AIR_TAKEAWAY_PUSH_LOCAL then      -- 飞艇是否开启
        PlayAudioByClickNormal()
        local isChecked  = sender:isChecked()
        self:SetPushStatus(isChecked , PUSH_LOCAL_NOTICE_NAME_TYPE.AIR_LIFT_RECOVER_TYPE)
        self:SetIsChecked(sender,  isChecked)
    elseif clickTag == BUTTON_CLICK.RESTAURANT_RECOVER__LOCAL then    -- 餐厅的恢复
        --PlayAudioByClickNormal()
        --self:SetPushStatus(isChecked , PUSH_LOCAL_NOTICE_NAME_TYPE.HP_FULL_PUSH_LOCAL)
        --self:SetIsChecked(sender,  isChecked)
    elseif clickTag == BUTTON_CLICK.REMIND_PUSH then
        PlayAudioByClickNormal()
        local isChecked  = sender:isChecked()
        local isOpen = isChecked and 1 or 0
        CommonUtils.SetPushNoticeStatus(isOpen)
        self:SetIsChecked(sender,  isChecked)
    elseif clickTag == BUTTON_CLICK.CHAT_PUSH or clickTag == BUTTON_CLICK.WORLD_CHANNEL_PUSH or clickTag == BUTTON_CLICK.MARQUEE_PUSH then
        PlayAudioByClickNormal()
        local isChecked  = sender:isChecked()
        if clickTag == BUTTON_CLICK.CHAT_PUSH  then
            CommonUtils.SetControlGameProterty(CONTROL_GAME.CHAT_PUSH,isChecked)
            AppFacade.GetInstance():DispatchObservers(CHAT_PANEL_VISIBLE,{open = isChecked})
        elseif clickTag == BUTTON_CLICK.WORLD_CHANNEL_PUSH  then
            CommonUtils.SetControlGameProterty(CONTROL_GAME.WORLD_CHANNEL_PUSH,isChecked)
        elseif clickTag == BUTTON_CLICK.MARQUEE_PUSH  then
            CommonUtils.SetControlGameProterty(CONTROL_GAME.MARQUEE_PUSH,isChecked)
        end
        self:SetIsChecked(sender,  isChecked)
    end
end

function PersonInformationSystemMediator:SetPushStatus(isChecked , id )
    local isOpen = isChecked and 1 or 0
    if isChecked then
        -- 如果推送是打开的 ， 就关闭该推送
        if CommonUtils.GetPushNoticeIsOpen() then
            CommonUtils.SetPushLocalNoticeStatusByType(id ,isOpen)
        end
    else
        CommonUtils.SetPushLocalNoticeStatusByType(id, isOpen)
    end
end
--[[
    获取到线上的数据
--]]

function PersonInformationSystemMediator:GetRemoteChineseVocieData()
    local url = DOWNLOAD_DEFINE.VOICE_JSON.url
    app.downloadMgr:addUrlTask(url, DOWNLOAD_DEFINE.VOICE_JSON.event)
end

function PersonInformationSystemMediator:UpdateStatus()
    local viewData = self.viewComponent.viewData
    local type =  app.audioMgr:GetVoiceType()
    if type  == PLAY_VOICE_TYPE.JAPANESE then -- 日文语音
        viewData.japanseVoiceBtn:setChecked(true)
        viewData.chineseVoiceBtn:setChecked(false)
        viewData.japanseVoiceBtn:setEnabled(false)
        viewData.chineseVoiceBtn:setEnabled(true)
    else
        viewData.japanseVoiceBtn:setChecked(false)
        viewData.chineseVoiceBtn:setChecked(true)
        viewData.japanseVoiceBtn:setEnabled(true)
        viewData.chineseVoiceBtn:setEnabled(false )
    end
    local voiceSize = viewData.voiceSize
    viewData.japanseLayout:setVisible(true )
    viewData.chineseLayout:setVisible(true )
    viewData.additionalBtn:setVisible(true )
    viewData.chineseVoiceBtn:setVisible(true)
    viewData.chineseLabel:setVisible(true)
    if table.nums(self.diffData) == 0 then
        viewData.japanseLayout:setPosition(cc.p(voiceSize.width/4 , voiceSize.height/2))
        viewData.chineseLayout:setPosition(cc.p(voiceSize.width/4 * 3 , voiceSize.height/2))
        viewData.additionalBtn:setVisible(false)
        return
    end
    if downChineseVoiceFile.isDownLoad == 0   then -- 如果存在不同的数据
        if table.nums(self.localData) > 0 then
            viewData.japanseLayout:setPosition(cc.p(voiceSize.width/ 3 * 0.5  , voiceSize.height/2))
            viewData.chineseLayout:setPosition(cc.p(voiceSize.width/3 * 1.5 , voiceSize.height/2))
            viewData.additionalBtn:setPosition(cc.p(voiceSize.width/3 * 2.5 , voiceSize.height/2))
            viewData.chineseVoiceBtn:setVisible(false)
            viewData.chineseLabel:setVisible(false)
        else
            viewData.japanseLayout:setPosition(cc.p(voiceSize.width/4 , voiceSize.height/2))
            viewData.additionalBtn:setPosition(cc.p(voiceSize.width/4 * 3 , voiceSize.height/2))
            viewData.chineseLayout:setVisible(false)

        end
    elseif  downChineseVoiceFile.isDownLoad == 1     then -- 正在下载过程中
        if table.nums(self.localData) > 0 then
            viewData.japanseLayout:setPosition(cc.p(voiceSize.width/ 3 * 0.5  , voiceSize.height/2))
            viewData.chineseLayout:setPosition(cc.p(voiceSize.width/3 * 1.5 , voiceSize.height/2))
            viewData.additionalBtn:setPosition(cc.p(voiceSize.width/3 * 2.5 , voiceSize.height/2))
            viewData.chineseLayout:setVisible(true)
            viewData.chineseVoiceBtn:setVisible(false)
            viewData.chineseLabel:setVisible(false)
        else
            viewData.japanseLayout:setPosition(cc.p(voiceSize.width/4 , voiceSize.height/2))
            viewData.additionalBtn:setPosition(cc.p(voiceSize.width/4 * 3 , voiceSize.height/2))
            viewData.chineseLayout:setVisible(false)
        end
    elseif  downChineseVoiceFile.isDownLoad == 2      then -- 下载完成
        if table.nums(self.localData) > 0 then
            viewData.japanseLayout:setPosition(cc.p(voiceSize.width/4 , voiceSize.height/2))
            viewData.chineseLayout:setPosition(cc.p(voiceSize.width/4 * 3 , voiceSize.height/2))
            viewData.additionalBtn:setVisible(false)
        end
    elseif  downChineseVoiceFile.isDownLoad == 3      then -- 下载暂停
        viewData.additionalBtn:setVisible(true )
        viewData.japanseVoiceBtn:setVisible(true )
        viewData.chineseVoiceBtn:setVisible(false)
        viewData.chineseLabel:setVisible(false)
        if table.nums(self.localData) > 0 then
            viewData.japanseLayout:setPosition(cc.p(voiceSize.width/ 3 * 0.5  , voiceSize.height/2))
            viewData.chineseLayout:setPosition(cc.p(voiceSize.width/3 * 1.5 , voiceSize.height/2))
            viewData.additionalBtn:setPosition(cc.p(voiceSize.width/3 * 2.5 , voiceSize.height/2))
        else
            viewData.japanseLayout:setPosition(cc.p(voiceSize.width/4 , voiceSize.height/2))
            viewData.additionalBtn:setPosition(cc.p(voiceSize.width/4 * 3 , voiceSize.height/2))
            viewData.chineseLayout:setVisible(false)
        end
    end
end

--[[
    比较本地和远端数据的差异
--]]
function PersonInformationSystemMediator:CompareLocalAndRemoteData(localData , remoteData)
    local remoteData = remoteData
    local localData = localData
    local data = {}
    if localData and remoteData then
        for k , v in pairs(remoteData) do
            if localData[v.name] ~= remoteData[v.name].md5 then
                -- 对比差异 获取到没有下载的文件
                data[#data+1] =  v
            else
                if not io.exists(app.audioMgr:GetVoicePathByName(v.name , PLAY_VOICE_TYPE.CHINESE , true ,false ))  then
                    data[#data+1] =  v
                end
            end
        end
        for i = #data , -1 do
            local v = data[i]
            if  io.exists(app.audioMgr:GetVoicePathByName(v.name , PLAY_VOICE_TYPE.CHINESE , true ,false ))  then
                local md5Local = crypto.md5file(v.name)
                -- 如果文件存在的话  更新本地的数据记录
                if md5Local == v.md5 then
                    localData[v.name] = md5Local
                    io.writefile(app.audioMgr:GetVoicePathByName(VOICE_DATA.VOICE_LACAL_FILE , PLAY_VOICE_TYPE.CHINESE , true , false) ,  json.encode(localData))
                end
            end
        end
    end
    return data
end
--[[
    获取本地的数据
--]]
function PersonInformationSystemMediator:GetLocalChineseVocieData()
    local  filename = app.audioMgr:GetVoicePathByName(VOICE_DATA.VOICE_LACAL_FILE , PLAY_VOICE_TYPE.CHINESE , true , false)
    --- xian
    if not  io.exists(filename) then
        io.writefile(filename ,"{}")
        return {}
    else
        local str  = io.readfile(filename)
        if str then
            local data =  json.decode(str)
            return data
        else
            return {}
        end
    end
end
function PersonInformationSystemMediator:ProcessSignal(signal)
    local name = signal:GetName()
    if name ==  VOICE_DOWNLOAD_EVENT then

        self:UpdateStatus()
    end
end

function PersonInformationSystemMediator:OnRegist()
    AppFacade.GetInstance():RegistObserver(DOWNLOAD_DEFINE.VOICE_JSON.event, mvc.Observer.new(function(context, signal)
        --下载成功的逻辑
        local data = signal:GetBody()
        if data.isDownloaded then
            
            local voiceJson = json.decode(data.downloadData)
            app.audioMgr:SetChineseVioceData(voiceJson)
            
            local localData  = self:GetLocalChineseVocieData()
            local remoteData = app.audioMgr:GetRemoteChineseData()
            local diffData   = self:CompareLocalAndRemoteData(localData, remoteData)
            self.localData   = localData
            self.remoteData  = remoteData
            self.diffData    = diffData

            downChineseVoiceFile:UpdateData({downLoadData = diffData, localData = localData})
            local filename = VOICE_DATA.VOICE_PATH .. VOICE_DATA.VOICE_ROMOTE_FILE
            if isElexSdk() then
                filename =  app.audioMgr:GetVoicePathByName(VOICE_DATA.VOICE_ROMOTE_FILE ,PLAY_VOICE_TYPE.CHINESE, true,false)
            end
            local viewData = self.viewComponent.viewData

            viewData.voiceLayout:setVisible(not isKoreanSdk())
            if table.nums(self.diffData) > 0 then
                io.writefile(filename, json.encode(app.audioMgr:GetRemoteChineseData()))
                self:UpdateStatus()
            else

                if isKoreanSdk() then
                    viewData.japanseVoiceBtn:setVisible(false)
                    viewData.chineseVoiceBtn:setVisible(false)
                    viewData.additionalBtn:setVisible(false)
                else
                    self:UpdateStatus()
                    viewData.japanseVoiceBtn:setVisible(true)
                    viewData.chineseVoiceBtn:setVisible(true)
                    viewData.additionalBtn:setVisible(false)
                end
            end
        else
            self:GetRemoteChineseVocieData()
        end
    end, self))
end

function PersonInformationSystemMediator:OnUnRegist()
    AppFacade.GetInstance():UnRegistObserver(DOWNLOAD_DEFINE.VOICE_JSON.event, self)
    cc.UserDefault:getInstance():flush()
end

return PersonInformationSystemMediator



