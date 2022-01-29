local GameScene = require( "Frame.GameScene" )
---@class NewDownloadCommonTip
local NewDownloadCommonTip = class('NewCommonTip', GameScene)

function NewDownloadCommonTip:ctor( ... )
    local arg = unpack({...})
    self.args = arg
    self:init()
end
---@type DownChineseVoiceFile
local downChineseVoiceFile = require("Game.mediator.DownChineseVoiceFile").GetInstance()
function NewDownloadCommonTip:ctor( ... )
    local arg = unpack({...})
    self.args = arg or {}
    self.voiceValue = self.args.voiceValue
    self:init()
end

function NewDownloadCommonTip:init()
    local str = __('确定')
    if downChineseVoiceFile.isDownLoad  == 0  then
        str = __('下载')
    elseif  downChineseVoiceFile.isDownLoad  == 1 then
        str = __('取消')
    elseif  downChineseVoiceFile.isDownLoad  == 2 then
        str = __('确定')
    elseif  downChineseVoiceFile.isDownLoad  == 3 then
        str = __('继续下载')
    end

    self.btnTextL           =  __('取消')
    self.btnTextR           =  str

    local commonBG = require('common.CloseBagNode').new({callback = function()

        if not self.isForced_ then
            self:removeFromParent()
        end
    end, showLabel = not self.isForced_})
    commonBG:setName('CLOSE_BAG')
    commonBG:setPosition(utils.getLocalCenter(self))
    self:addChild(commonBG)


    --view
    local view = CLayout:create()
    view:setName('view')
    view:setPosition(display.cx, display.cy)
    view:setAnchorPoint(display.CENTER)
    self.view = view


    local outline = display.newImageView(_res('ui/common/common_bg_8.png'),{
        enable = true
    })

    local size   = outline:getContentSize()
    outline:setAnchorPoint(display.LEFT_BOTTOM)
    view:addChild(outline)
    view:setContentSize(size)
    commonBG:addContentView(view)
    self.size = size
    local cancelBtn = display.newButton(size.width/2 - 80,50,{
        n = _res('ui/common/common_btn_white_default.png'),
        cb = function(sender)
            PlayAudioByClickNormal()
            if downChineseVoiceFile.isDownLoad ==  0  then -- 没有下载的话就关闭界面
                if self.cancelBack then
                    self.cancelBack()
                end
                self:removeFromParent()
            end
        end
    })
    display.commonLabelParams(cancelBtn,fontWithColor(14,{text = __(self.btnTextL)}))
    view:addChild(cancelBtn)
    self.cancelBtn = cancelBtn

    -- entry button
    local entryBtn = display.newButton(size.width/2 + 80,50,{
        n = _res('ui/common/common_btn_orange.png'), scale9 = true ,
        cb = function(sender)
            PlayAudioByClickNormal()
            if downChineseVoiceFile.isDownLoad == 0 then
                downChineseVoiceFile:SetRestartDownload()
            elseif  downChineseVoiceFile.isDownLoad == 1 then
                -- 暂停下载
                downChineseVoiceFile:SetStopDownload()
            elseif downChineseVoiceFile.isDownLoad == 2 then
                -- 下载完成
                self:removeFromParent()
            elseif downChineseVoiceFile.isDownLoad == 3 then
                -- 暂停
                downChineseVoiceFile:SetRestartDownload()
            end
        end
    })
    entryBtn:setName('entryBtn')
    display.commonLabelParams(entryBtn,fontWithColor(14,{text = __(self.btnTextR) , paddingW = 10 }))
    view:addChild(entryBtn)
    self.entryBtn  = entryBtn


    local progressBarThree = CProgressBar:create(_res('ui/home/infor/settings_ico_loading'))
    progressBarThree:setBackgroundImage(_res('ui/home/infor/settings_bg_loading'))
    progressBarThree:setDirection(eProgressBarDirectionLeftToRight)
    progressBarThree:setAnchorPoint(cc.p(0.5, 0.5))
    progressBarThree:setPosition(cc.p(size.width / 2  , size.height / 2 + 40))
    progressBarThree:setMaxValue(checkint(math.floor( downChineseVoiceFile.totalDownloadSize /1024/1024 * 100 )/100))
    progressBarThree:setValue(0)
    progressBarThree:setVisible(false )
    view:addChild(progressBarThree)
    self.progressBarThree = progressBarThree
    local progressBarThreeSize = progressBarThree:getContentSize()

    -- 任务进度
    local prograssThreeLabel = display.newLabel(progressBarThreeSize.width / 2, progressBarThreeSize.height / 2 - 30, fontWithColor('16', { text = "" }) )
    progressBarThree:addChild(prograssThreeLabel, 10)
    self.prograssThreeLabel = prograssThreeLabel

    -- 下载状态
    local prograssThreeStatusLabel = display.newLabel(progressBarThreeSize.width / 2 , progressBarThreeSize.height / 2 + 30,  fontWithColor('16', { text = "" }) )
    progressBarThree:addChild(prograssThreeStatusLabel, 10)
    self.prograssThreeStatusLabel = prograssThreeStatusLabel

    local richLabel = display.newRichLabel(size.width / 2, size.height * 0.6,
                                           {display.LEFT_BOTTOM, w = 30,  sp = 5, c = {
                                               fontWithColor('14', { text = ""})
                                           } })
    view:addChild(richLabel)
    self.richLabel = richLabel
    self.richLabel:setVisible(false)
    AppFacade.GetInstance():RegistObserver(VOICE_DOWNLOAD_EVENT, mvc.Observer.new(self.ProcessSignal, self))
    AppFacade.GetInstance():DispatchObservers( VOICE_DOWNLOAD_EVENT , {})
end

function NewDownloadCommonTip:ProcessSignal(signal)
    local name = signal:GetName()
    if tolua.isnull(self) then return end
    if  name ==  VOICE_DOWNLOAD_EVENT then
        if downChineseVoiceFile.isDownLoad == 1 then -- 下载过程中
            self.richLabel:setVisible(false )
            self.progressBarThree:setVisible(true)
            self.cancelBtn:setVisible(false)
            self.entryBtn:setPositionX(self.size.width/2)
            print(checkint(math.floor( downChineseVoiceFile.totalDownloadSize /1024/1024 * 100 )/100))
            self.progressBarThree:setValue(checkint(math.floor( downChineseVoiceFile.downloadSize /1024/1024 * 100 )/100))
            display.commonLabelParams(self.prograssThreeStatusLabel , {text = __('下载中 ... ')})
            display.commonLabelParams(self.prograssThreeLabel , {text = string.format('(%s/%sMB)' ,
                  math.floor( downChineseVoiceFile.downloadSize /1024/1024 * 100 )/100,
                math.floor( downChineseVoiceFile.totalDownloadSize /1024/1024 * 100 )/100
            ) })
            display.commonLabelParams(self.entryBtn , { text = __('取消') , paddingW = 10})
        elseif downChineseVoiceFile.isDownLoad == 2 then -- 下载完成
            self.richLabel:setVisible(false )
            self.progressBarThree:setVisible(true)
            self.cancelBtn:setVisible(false)
            self.entryBtn:setPositionX(self.size.width/2)
            display.commonLabelParams(self.entryBtn , { text = __('确定') ,  paddingW = 10})

            self.progressBarThree:setValue(checkint(math.floor( downChineseVoiceFile.downloadSize /1024/1024 * 100 )/100))
            display.commonLabelParams(self.prograssThreeStatusLabel , {text = __('下载完成 ')})
            display.commonLabelParams(self.prograssThreeLabel , {text = string.format('(%s/%sMB)' ,
                                                                                      math.floor( downChineseVoiceFile.totalDownloadSize /1024/1024 * 100 )/100,
                                                                                      math.floor( downChineseVoiceFile.totalDownloadSize /1024/1024 * 100 )/100
            ) })
        elseif downChineseVoiceFile.isDownLoad == 3 then -- 暂停
            self.richLabel:setVisible(false )
            self.progressBarThree:setVisible(true)
            self.cancelBtn:setVisible(false)
            self.entryBtn:setPositionX(self.size.width/2)
            display.commonLabelParams(self.entryBtn , { text = __('继续下载') ,  paddingW = 10})
            self.progressBarThree:setValue(checkint(math.floor( downChineseVoiceFile.downloadSize /1024/1024 * 100 )/100))
            display.commonLabelParams(self.prograssThreeStatusLabel , {text = __('暂停 ')})
            display.commonLabelParams(self.prograssThreeLabel , {text = string.format('(%s/%sMB)' ,
                                                                                      math.floor( downChineseVoiceFile.downloadSize /1024/1024 * 100 )/100,
                                                                                      math.floor( downChineseVoiceFile.totalDownloadSize /1024/1024 * 100 )/100
            ) })
        elseif downChineseVoiceFile.isDownLoad == 0  then
            self.richLabel:setVisible(true )
            self.progressBarThree:setVisible(false )
            self.cancelBtn:setVisible(true )
            self.entryBtn:setVisible(true)
            local cData = {
                fontWithColor('16', {text = string.fmt(__('需要下载_lang_') ,{ _lang_ = self.voiceValue or "" })  }),
                fontWithColor('10', {text = string.format('(%sMB)' ,
                tostring(math.floor( downChineseVoiceFile.totalDownloadSize /1024/1024 * 100 )/100)) }),
                fontWithColor('16', {text = __('，是否确认下载？')})
            }
            display.reloadRichLabel(self.richLabel , { c = cData })
        end
    end
end



return NewDownloadCommonTip
