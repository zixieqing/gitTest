---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by pengjixian.
--- DateTime: 2018/10/25 3:25 PM
---
--[[
    钻石购买界面
--]]
local CommonDialog = require('common.CommonDialog')
local DiamondPurchasePopup = class('DiamondPurchasePopup', CommonDialog)

function DiamondPurchasePopup:InitialUI()
    local datas = self.args.data
    self.datas = datas
    self.cb = self.args.cb
    local function CreateView()
        -- bg
        local bg = display.newImageView(_res('ui/common/common_bg_7.png'), 0, 0)
        local bgSize = bg:getContentSize()
        -- bg view
        local view = display.newLayer(0, 0, {size = bgSize, ap = cc.p(0.5, 0.5)})
        display.commonUIParams(bg, {po = cc.p(utils.getLocalCenter(view))})
        view:addChild(bg)
        -- title
        local titleBg = display.newButton(0, 0, {n = _res('ui/common/common_bg_title_2.png'), animation = false})
        display.commonUIParams(titleBg, {po = cc.p(bgSize.width * 0.5, bgSize.height - titleBg:getContentSize().height * 0.5 - 3)})
        display.commonLabelParams(titleBg,
                {text = __('幻晶石购买'),
                 fontSize = fontWithColor('3').fontSize, color = fontWithColor('3').color,
                 font = TTF_GAME_FONT, ttf = true,
                 offset = cc.p(0, -2)})
        bg:addChild(titleBg)

        local available = datas.num
        if checkint(datas.isFirst) == 1 then
            available = available + datas.num
        end
        local textRich = {}
        local text = string.split(__('花费|_price_|购买|_num_|个幻晶石,是否确认购买?'), '|')
        for i,v in ipairs(text) do
            if '_num_' == v then
                table.insert( textRich, fontWithColor(16, {text = available}) )
            elseif '_price_' == v then
                table.insert( textRich, fontWithColor(16, {text = '¥' .. tostring(datas.price)}) )
            elseif '' ~= v then
                table.insert( textRich, fontWithColor(16, {text = v}) )
            end
        end

        local desrLabel = display.newRichLabel(utils.getLocalCenter(view).x, bgSize.height - 120, {
            w = bgSize.width - 75, h = 250, c = textRich, r = true
        })
        view:addChild(desrLabel)

        local leftSecondsLabel = display.newLabel(bgSize.width/2, bgSize.height - 80, fontWithColor(2, {text = '', color = '5c5c5c'}))
        leftSecondsLabel:setVisible(false)
        view:addChild(leftSecondsLabel,10)
        local contentBG = display.newImageView(_res('ui/home/commonShop/shop_jp_bg_detail_diamonds.png'), bgSize.width/2, 260)
        view:addChild(contentBG)

        local titleLabel = display.newLabel(bgSize.width/2, 312, fontWithColor(5, {text = __('内容包括：')}))
        view:addChild(titleLabel)

        local content = {string.fmt(__('有偿幻晶石_num_个'), {_num_ = datas.num})}
        if checkint(datas.isFirst) == 1 then
            table.insert(content, '+')
            table.insert(content, string.fmt(__('无偿幻晶石_num_个'), {_num_ = datas.num}))
        end
        local contentLabel = display.newLabel(bgSize.width/2, 256, fontWithColor(5, {text = table.concat(content)}))
        view:addChild(contentLabel)

        local cancelBtn = display.newButton(bgSize.width/2 - 100,74,{
            n = _res('ui/common/common_btn_white_default.png'),
            cb = function(sender)
                PlayAudioByClickClose()
                self:CloseHandler()
            end
        })
        display.commonLabelParams(cancelBtn,fontWithColor(14,{text = __('取消')}))
        view:addChild(cancelBtn)

        -- entry button
        local entryBtn = display.newButton(bgSize.width/2 + 100,74,{
            n = _res('ui/common/common_btn_orange.png'),
            d = _res('ui/common/common_btn_orange_disable.png'),
            cb = function(sender)
                PlayAudioByClickNormal()
                if self.cb then
                    self.cb()
                end
                self:CloseHandler()
            end
        })
        display.commonLabelParams(entryBtn,fontWithColor(14,{text = __('确认')}))
        view:addChild(entryBtn)

        local tipsLabel = display.newLabel(bgSize.width/2, 25,
                {
                    text = __('（幻晶石将优先消耗免费部分）'),
                    fontSize = 22,
                    color = '#d34300',
                })
        view:addChild(tipsLabel)

        return {
            view        = view,
            leftTimesLabel = leftSecondsLabel,
            entryBtn   = entryBtn,
        }
    end
    xTry(function ( )
        self.viewData = CreateView( )

        if self.datas.leftSeconds and checkint(self.datas.leftSeconds) > 0 then
            --注册计时器，显示倒计时
            local shareUserDefault = cc.UserDefault:getInstance()
            local recordTime = shareUserDefault:getIntegerForKey("DIAMOND_KEY_ID", 0)
            local spanTime = os.time() - recordTime

            local leftSeconds = checkint(self.datas.leftSeconds) - spanTime
            local leftTimesLabel = self.viewData.leftTimesLabel
            local entryBtn = self.viewData.entryBtn
            if leftSeconds > 0 then
                leftTimesLabel:setVisible(true)
                if checkint(leftSeconds) <= 86400 then
                    leftTimesLabel:setString(__('剩余时间：') .. string.formattedTime(leftSeconds,'%02i:%02i:%02i'))
                else
                    local day = math.floor(checkint(leftSeconds)/86400)
                    local hour = math.floor((leftSeconds - day * 86400) / 3600)
                    leftTimesLabel:setString(__('剩余时间：') .. string.fmt(__('_day_天_hour_小时'),{_day_ = day, _hour_ = hour}))
                end
                local timerMgr  = AppFacade.GetInstance():GetManager('TimerManager')
                timerMgr:AddTimer({name = "DiamondPurchasePopup_TIMER", countdown = leftSeconds, callback = function(countdown, remindTag, timeNum,datas, name)
                    if name == 'DiamondPurchasePopup_TIMER' then
                        local nowTime   = checkint(countdown)
                        local endTime   = checkint(timeNum)
                        if 0 >= nowTime then
                            leftTimesLabel:setVisible(false)
                            entryBtn:setEnabled(false)
                        else
                            --计时
                            if nowTime <= 86400 then
                                leftTimesLabel:setString(__('剩余时间：') .. string.formattedTime(nowTime,'%02i:%02i:%02i'))
                            else
                                local day = math.floor(nowTime/86400)
                                local hour = math.floor((nowTime - day * 86400) / 3600)
                                leftTimesLabel:setString(__('剩余时间：') .. string.fmt(__('_day_天_hour_小时'),{_day_ = day, _hour_ = hour}))
                            end
                        end
                    end
                end})
            else
                leftTimesLabel:setVisible(false)
                entryBtn:setEnabled(false)

            end

        end
    end, __G__TRACKBACK__)
end

function DiamondPurchasePopup:onCleanup()
    local timerMgr  = AppFacade.GetInstance():GetManager('TimerManager')
    timerMgr:RemoveTimer("DiamondPurchasePopup_TIMER")
end

return DiamondPurchasePopup
