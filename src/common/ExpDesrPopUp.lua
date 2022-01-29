local ExpDesrPopUp = class('ExpDesrPopUp', function()
    return display.newLayer()
end)

local app = app
local uiMgr = app.uiMgr
local gameMgr = app.gameMgr

local RES_DIR = {
    BG_IMG                    = _res('ui/common/common_bg_7.png'),
    TITLE_1                   = _res('ui/common/common_bg_title_2.png'),
    Bg_skill_unselected       = _res("ui/common/common_bg_list_3.png"),
    COMMON_BTN_CHECK_DEFAULT  = _res("ui/common/common_btn_check_default.png"),
    COMMON_BTN_CHECK_SELECTED = _res("ui/common/common_btn_check_selected.png"),
}

-------------------------------------------------
-- life cycle

function ExpDesrPopUp:ctor(args)
    local args = checktable(args)
    self.expAddition = clone(CommonUtils.GetConfigAllMess('expAddition', 'player'))
    for k,v in pairs(self.expAddition) do
        v.descr = string.gsub(v.descr, '_target_num_', '|_target_num_|')
    end
    local expBuff = gameMgr:GetUserInfo().expBuff
    -- dump(expBuff)
    self.buff = {}
    for k,v in pairs(expBuff) do
        if checkint(v) > 0 then
            table.insert( self.buff, {id = tonumber(k)} )
        end
    end
    local newbieExpAddition = CommonUtils.GetConfigAllMess('newbieExpAddition', 'player')[tostring(gameMgr:GetUserInfo().level)]
    if next(newbieExpAddition or {}) then
        if 0 < tonumber(newbieExpAddition.effect) then
            table.insert( self.buff, {id = 1} )
        end
    end
    table.sort(self.buff, function ( a, b )
        return a.id < b.id
    end)
    self.isControllable_ = true

    local function CreateView()
        local view = display.newLayer()

        local blackBg = display.newLayer(0, 0, {color = cc.c4b(0,0,0,150), enable = true})
        blackBg:setCascadeOpacityEnabled(true)
        view:addChild(blackBg)

        local size = view:getContentSize()
        local contentLayer = display.newLayer(size.width/2, size.height/2, {bg = RES_DIR.BG_IMG, ap = display.CENTER})
        contentLayer.bg:setTouchEnabled(true)
        view:addChild(contentLayer)
    
		local bgSize = contentLayer.bg:getContentSize()
        local titleBg = display.newButton(0, 0, {n = RES_DIR.TITLE_1, animation = false})
        display.commonUIParams(titleBg, {po = cc.p(bgSize.width * 0.5, bgSize.height - titleBg:getContentSize().height * 0.5 - 3)})
        display.commonLabelParams(titleBg,
            {text = __('经验获得'),
            fontSize = fontWithColor('3').fontSize, color = fontWithColor('3').color,
            font = TTF_GAME_FONT, ttf = true,
            offset = cc.p(0, -2)})
        contentLayer.bg:addChild(titleBg)
    
        local xx = display.cx
        local yy = display.cy - bgSize.height / 2 - 14
        local closeLabel = display.newButton(xx,yy,{
            n = _res('ui/common/common_bg_close.png'),
        })
        closeLabel:setEnabled(false)
        display.commonLabelParams(closeLabel,{fontSize = 18,text = __('点击空白处关闭')})
        self:addChild(closeLabel, 10)
    
        local descrLabel = display.newLabel(40, bgSize.height - 60, fontWithColor(6, {hAlign = display.TAL, w = 480, ap = cc.p(0, 1)}))
        contentLayer:addChild(descrLabel)
        local moduleExplainConf = checktable(CommonUtils.GetConfigAllMess('moduleExplain'))[tostring(MODULE_DATA[tostring(RemindTag.LEVEL)])] or {}
        display.commonLabelParams(descrLabel, {text = tostring(moduleExplainConf.descr)})
    
        local buffListSize = cc.size(504, 340)
        local buffList = CTableView:create(buffListSize)
        display.commonUIParams(buffList, {po = cc.p(27, 8), ap = display.LEFT_BOTTOM})
        buffList:setDirection(eScrollViewDirectionVertical)
        -- buffList:setBackgroundColor(cc.c4b(23, 67, 128, 128))
        buffList:setSizeOfCell(cc.size(buffListSize.width, 120))
        contentLayer:addChild(buffList)

        return {
            view            = view,
            blackBg         = blackBg,
            contentLayer    = contentLayer,
            buffList        = buffList,
        }
    end
        
    -- create view
    self.viewData_ = CreateView()
    self:addChild(self.viewData_.view)

    -- init view
    display.commonUIParams(self.viewData_.blackBg, {cb = handler(self, self.onClickBlackBgHandler_), animate = false})
    local buffList = self.viewData_.buffList
    buffList:setDataSourceAdapterScriptHandler(handler(self, self.OnBuffListDataAdapter))
    buffList:setCountOfCell(table.nums(self.buff))
    buffList:reloadData()


    self:RegistObserver()
    self:show()
end

function ExpDesrPopUp:UpdateCountDown(countdown)
    if countdown <= 0 then
        return __('已结束')
    else
        if checkint(countdown) <= 86400 then
            return string.formattedTime(checkint(countdown), '%02i:%02i:%02i')
        else
            local day  = math.floor(checkint(countdown) / 86400)
            local hour = math.floor((countdown - day * 86400) / 3600)
            return string.fmt(__('_day_天_hour_小时'), { _day_ = day, _hour_ = hour })
        end
    end
end

function ExpDesrPopUp:OnBuffListDataAdapter(p_convertview, idx )
    local pCell = p_convertview
    local index = idx + 1
    local buffList = self.viewData_.buffList
    local size = buffList:getSizeOfCell()
    local buff = self.buff[index] or self.buff[tostring(index)]
    local buffDescr = self.expAddition[tostring(buff.id)]
    if pCell == nil then
        pCell = CTableViewCell:new()
        pCell:setContentSize(size)

        local bg = display.newImageView(RES_DIR.Bg_skill_unselected, size.width / 2, size.height / 2)
        pCell:addChild(bg)

        local name = display.newRichLabel(14, size.height - 36,{c = {} , ap = display.LEFT_BOTTOM})
        pCell:addChild(name)

        local effect = display.newRichLabel(16, size.height - 45, { w = 42, ap = cc.p(0, 1)})
        pCell:addChild(effect)

        local btnChecked = display.newCheckBox(size.width -40, size.height- 28 , { animate = false ,
            ap = display.CENTER ,
            n = RES_DIR.COMMON_BTN_CHECK_DEFAULT ,
            s = RES_DIR.COMMON_BTN_CHECK_SELECTED
        })
        btnChecked:setDisabledNormalImage(RES_DIR.COMMON_BTN_CHECK_DEFAULT)
        btnChecked:setDisabledCheckedImage(RES_DIR.COMMON_BTN_CHECK_SELECTED)
        pCell:addChild(btnChecked)
        pCell.name       = name
        pCell.effect     = effect
        pCell.btnChecked = btnChecked
    end

    xTry(function()
        --pCell.name:setString(buffDescr.name)
        local timeText = __('无期限')
        local effectPercent = buffDescr.effect
        if 1 == tonumber(buff.id) then
            local newbieExpAddition = CommonUtils.GetConfigAllMess('newbieExpAddition', 'player')[tostring(gameMgr:GetUserInfo().level)]
            effectPercent = newbieExpAddition.effect
        else
            timeText = self:UpdateCountDown(gameMgr:GetUserInfo().expBuff[tostring(buff.id)])
        end
        display.reloadRichLabel(pCell.name , { width = 420  ,
            c = {
                fontWithColor(11, {text = buffDescr.name, ap = cc.p(0, 0)}),
                fontWithColor(5, {text = "(" ..  timeText .. ")"}),
            }
        })
        
        local isOpen = false
        local isVisible = false
        if GAME_MODULE_OPEN.NEWER_ADD_EXP then
            if checkint(buff.id) == 1 then
                isOpen =  checkint(app.gameMgr:GetClientDataByKey("newbieClose")) == 0
                isVisible = true
            elseif checkint(buff.id) == 4 then
                isOpen =  checkint(app.gameMgr:GetClientDataByKey("recalledClose")) == 0
                isVisible = true
            end
        end
        pCell.btnChecked:setChecked(isOpen)
        pCell.btnChecked:setVisible(isVisible)
        local textRich = {}
        local descr = string.split(buffDescr.descr, '|')
        display.commonUIParams(pCell.btnChecked , {cb = handler(self, self.CellClick)})
        pCell.btnChecked:setTag(index)
        for i,v in ipairs(descr) do
            if '_target_num_' == v then
                table.insert( textRich, fontWithColor(10, {text = tostring(tonumber(effectPercent) * 100), fontSize = 22}))
            elseif '' ~= v then
                table.insert( textRich, fontWithColor(6, {text = v}))
            end
        end
        display.reloadRichLabel(pCell.effect, {c = textRich})
    end,__G__TRACKBACK__)
    return pCell
end

function ExpDesrPopUp:CellClick(sender)
    sender:setEnabled(false)
    sender:runAction(
        cc.Sequence:create(
            cc.DelayTime:create(3),
            cc.CallFunc:create(function()
                sender:setEnabled(true)
            end)
        )
    )

    local index = sender:getTag()
    local buff = self.buff[index] or self.buff[tostring(index)]
    local id = checkint(buff.id)
    if id == 1 then -- 新手
        local newbieClose = checkint(app.gameMgr:GetClientDataByKey("newbieClose"))
        newbieClose = math.abs(newbieClose -1)
        app:DispatchSignal(POST.PLAYER_CLIENT_DATA.cmdName , {
            clientData = json.encode({
                newbieClose = newbieClose
            })})
    elseif id == 4 then -- 回归
        local recalledClose = checkint(app.gameMgr:GetClientDataByKey("recalledClose"))
        recalledClose = math.abs(recalledClose -1)
        app:DispatchSignal(POST.PLAYER_CLIENT_DATA.cmdName , {
            clientData = json.encode({
                recalledClose = recalledClose
            })})
    end
end
-------------------------------------------------
-- public method

function ExpDesrPopUp:close()
    app:UnRegistObserver('EXP_BUFF_REMAIN_TIME', self)
    app:UnRegistObserver(POST.PLAYER_CLIENT_DATA.sglName, self)
    self:runAction(cc.RemoveSelf:create())
end


-------------------------------------------------
-- private method

function ExpDesrPopUp:show()
    self.isControllable_ = false
    self.viewData_.blackBg:setOpacity(0)
    self.viewData_.contentLayer:setScaleY(0)

    local actionTime = 0.15
    self:runAction(cc.Sequence:create({
        cc.Spawn:create({
            cc.TargetedAction:create(self.viewData_.blackBg, cc.FadeTo:create(actionTime, 150)),
            cc.TargetedAction:create(self.viewData_.contentLayer, cc.ScaleTo:create(actionTime, 1))
        }),
        cc.CallFunc:create(function()
            self.isControllable_ = true
        end)
    }))
end

function ExpDesrPopUp:hide()
    self.isControllable_ = false
    self.viewData_.blackBg:setOpacity(150)
    self.viewData_.contentLayer:setScale(1)

    local actionTime = 0.1
    self:runAction(cc.Sequence:create({
        cc.Spawn:create({
            cc.TargetedAction:create(self.viewData_.blackBg, cc.FadeTo:create(actionTime, 0)),
            cc.TargetedAction:create(self.viewData_.contentLayer, cc.ScaleTo:create(actionTime, 1, 0))
        }),
        cc.CallFunc:create(function()
            self:close()
        end)
    }))
end


-------------------------------------------------
-- handler

function ExpDesrPopUp:onClickBlackBgHandler_(sender)
    if not self.isControllable_ then return end
    self:hide()
end

function ExpDesrPopUp:RegistObserver()
    app:RegistObserver(POST.PLAYER_CLIENT_DATA.sglName , mvc.Observer.new(function(context, signal)
        local buffList = self.viewData_.buffList
        buffList:reloadData()
    end, self))

    app:RegistObserver('EXP_BUFF_REMAIN_TIME', mvc.Observer.new(function (_, signal)
        local body = signal:GetBody()
        local expBuff = gameMgr:GetUserInfo().expBuff
        for k,v in pairs(self.buff) do
            if expBuff[tostring(v.id)] then
                local buffList = self.viewData_.buffList
                local pCell = buffList:cellAtIndex(k-1)
                if pCell then
                    local buffDescr = self.expAddition[tostring(v.id)]
                    local timeText = self:UpdateCountDown(expBuff[tostring(v.id)])
                    display.reloadRichLabel(pCell.name , { width = 420  ,
                       c = {
                           fontWithColor(11, {text = buffDescr.name, ap = cc.p(0, 0)}),
                           fontWithColor(5, {text = "(" ..  timeText .. ")"}),
                       }
                    })
                end
            end
        end
    end, self))
end

return ExpDesrPopUp
