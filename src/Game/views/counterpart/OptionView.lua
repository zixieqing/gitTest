local OptionView = class('OptionView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.counterpart.OptionView'
	node:enableNodeEvents()
	return node
end)


local shareFacade = AppFacade.GetInstance()
local cardMgr = AppFacade.GetInstance():GetManager("CardManager")


--[[
-- {
-- questId = questId, -- questId,
-- zoneId = zoneId -- zoneId
-- lastSelectData = data, --serverData
-- config = config, --剧情配表的选项的内容
--]]
function OptionView:ctor( ... )
	local params = unpack({...}) or {}
    self.params = params
    self.preIndex = -1
    self.isAction = true
    local colorView = CColorView:create(cc.c4b(0,0,0,153))
    colorView:setContentSize(display.size)
    display.commonUIParams(colorView, {ap = display.CENTER, po = display.center})
    colorView:setTouchEnabled(true)
    self:addChild(colorView)

    local view = CLayout:create(display.size)
    display.commonUIParams(view, {ap = display.CENTER, po = display.center})
    view:setName("OPTION_VIEW")
    self:addChild(view,2)

    local config = checktable(params.config)
    --添加标题
    local titleLabel = display.newLabel(display.cx, display.cy + 240, fontWithColor(1, {text = tostring(config.desc),
        fontSize = 30, color = 'ffffff',outline = '5b3c25', outlineSize = 1, w = 500,hAlign = display.TAC, h = 250, ap = display.CENTER_BOTTOM}))
    view:addChild(titleLabel)

    local h = display.cy + 230
    local t = checktable(config.select)
    local len = table.nums(t)
    local offsetY = h
    local i = 1
    for selectId,val in pairs(t) do
        local text = tostring(val[1])
        --local len = UTF8len(text)
        --if len <= 32 then
        --    local newCheckBox = display.newToggleView(display.cx, h, {
        --            n = _res('ui/home/activity/activityQuest/activity_maps_answer_bg_unselected'),
        --        s = _res('ui/home/activity/activityQuest/activity_maps_answer_bg_select'), ap = display.CENTER_TOP})
        --    newCheckBox:setName("NAME_".. tostring(selectId))
        --    newCheckBox:setColor(ccc3FromInt('5b3c25'))
        --    local textLabel = display.newLabel(220, 28, fontWithColor(4, {color = '5b3c25', text = text, ap = display.CENTER}))
        --    newCheckBox:addChild(textLabel)
        --    newCheckBox:setTag(checkint(selectId))
        --    newCheckBox:setOnClickScriptHandler(handler(self, self.ButtonActions))
        --    view:addChild(newCheckBox)
        --    h = h - 88
        --    offsetY = offsetY - 88
        --else
            --需要换行的逻辑
        local newCheckBox = display.newToggleView(display.cx, h , {
                n = _res('ui/home/activity/activityQuest/activity_maps_answer_bg_unselected'),
            s = _res('ui/home/activity/activityQuest/activity_maps_answer_bg_select'), ap = display.CENTER_TOP, scale9 = true,
            size = cc.size(900, 84)})
        newCheckBox:setName("NAME_".. tostring(selectId))
        newCheckBox:setColor(ccc3FromInt('5b3c25'))
        local textLabel
        --if isJapanSdk() then
        --    textLabel = display.newLabel(12, 38, fontWithColor(4, {color = '5b3c25', text = text, w = 880, ap = display.LEFT_CENTER, hAlign = display.TAC}))
        --else
            textLabel = display.newLabel(12, 38, fontWithColor(4, {color = '5b3c25', text = text, w = 880, ap = display.LEFT_CENTER, hAlign = display.TAC}))
        --end
        newCheckBox:addChild(textLabel)
        newCheckBox:setTag(checkint(selectId))
        newCheckBox:setOnClickScriptHandler(handler(self, self.ButtonActions))
        view:addChild(newCheckBox)
        h = h - 110
        offsetY = offsetY - 110
        --end
        i = i + 1
    end

    if params.data and params.data.selected and table.nums(params.data.selected) > 0 then
        for id,val in pairs(params.data.selected) do
            local optionNode1 = self:getChildByName("OPTION_VIEW"):getChildByName("NAME_" .. tostring(id))
            local x1, y1 = optionNode1:getPosition()
            x1 = x1 + optionNode1:getContentSize().width * 0.5
            self:CreateHeadNodeView(view, val, x1, y1 - optionNode1:getContentSize().height * 0.5)
        end
    end
    local confirmButton = display.newButton(display.cx, offsetY, {
            n = _res('ui/common/common_btn_orange_l'),ap = display.CENTER_TOP
        })
    display.commonLabelParams(confirmButton, fontWithColor(14, {text = __("确定")}))
    view:addChild(confirmButton, 12)
    confirmButton:setOnClickScriptHandler(handler(self, self.ConfirmAction))

    if not self.params.isReview then
        shareFacade:UnRegistObserver(POST.ACTIVITYQUEST_STORY_QUEST.sglName, self)
        shareFacade:RegistObserver(POST.ACTIVITYQUEST_STORY_QUEST.sglName, mvc.Observer.new(handler(self, self.PostStoryResponseHandler), self))

        regPost(POST.ACTIVITYQUEST_STORY_QUEST)
    end
end

function OptionView:PostStoryResponseHandler( context, signal)
    local view = self:getChildByName("OPTION_VIEW")
    if view then view:setVisible(false) end
    -- 如果有角色加成添加另一个页面如果没有进行下一个剧情
    local body = checktable(signal:GetBody())
    -- dump(body)
    self:CreateOptionRole(checkint(body.pointId), checkint(body.point))
end

function OptionView:CreateOptionRole(id, point)
    local colorView = CColorView:create(cc.c4b(0,0,0,0))
    colorView:setContentSize(display.size)
    display.commonUIParams(colorView, {ap = display.CENTER, po = display.center})
    colorView:setTouchEnabled(true)
    colorView:setName("OPTION_ROLE_VIEW")
    local roleCoordinateConfig = CommonUtils.GetConfigNoParser("activityQuest", "coordinate", id)
    colorView:setOnClickScriptHandler(function(sender)
        --事件
        local canAction = true
        local name = "ROLE_NAME_" .. tostring(roleCoordinateConfig.id)
        local node = colorView:getChildByName(name)
        if node and node.isInAction == true then
            canAction = false
        end
        if roleCoordinateConfig.roleId2 then
            local name2 = "ROLE_NAME_" .. tostring(roleCoordinateConfig.roleId2)
            local node2 = colorView:getChildByName(name2)
            if node2 and node2.isInAction == true then
                canAction = false
            end
        end
        if canAction then
            --执行下句对白
            -- colorView:setVisible(false)
            self:setVisible(false)
            AppFacade.GetInstance():DispatchObservers("DirectorStory","next")
        end
    end)
    self:addChild(colorView)
    local OptionRoleView = require('Game.views.counterpart.OptionRoleNode')
    local curPoint = checkint(self.params.data.curPoints[tostring(roleCoordinateConfig.id)])
    local maxPoint = checkint(self.params.data.maxPoints[tostring(roleCoordinateConfig.id)])
    local roleNode = OptionRoleView.new({config = roleCoordinateConfig, point = point, curPoint = curPoint, maxPoint = maxPoint, roleId = roleCoordinateConfig.roleId})
    roleNode:setPosition(cc.p(display.cx * 0.5,display.height * 0.5))
    roleNode:setName('ROLE_NAME_' .. tostring(roleCoordinateConfig.id))
    colorView:addChild(roleNode)

    if roleCoordinateConfig.roleId2 and string.len(tostring(roleCoordinateConfig.roleId2)) > 0 then
        local config = CommonUtils.GetConfigNoParser("activityQuest", "coordinate", roleCoordinateConfig.roleId2)
        if config then
            local curPoint = checkint(self.params.data.curPoints[tostring(roleCoordinateConfig.roleId2)])
            local maxPoint = checkint(self.params.data.maxPoints[tostring(roleCoordinateConfig.roleId2)])
            local roleNode = OptionRoleView.new({config = config, point = 0, curPoint = curPoint, maxPoint = maxPoint, roleId = config.roleId})
            roleNode:setPosition(cc.p(display.cx * 1.5,display.height * 0.5))
            roleNode:setName('ROLE_NAME_' .. tostring(roleCoordinateConfig.roleId2))
            colorView:addChild(roleNode)
        end
    end
end

function OptionView:ConfirmAction(sender)
    if self.params.isReview then
        -- 预览模式直接下一步
        local view = self:getChildByName("OPTION_VIEW")
        if view then view:setVisible(false)  end
        self:setVisible(false)
        AppFacade.GetInstance():DispatchObservers("DirectorStory", "next")
        return
    end

    if self.preIndex <= 0 then
        local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
        uiMgr:ShowInformationTips(__("请您选择一个答案"))
    else
        local config = checktable(self.params.config)
        shareFacade:DispatchSignal(POST.ACTIVITYQUEST_STORY_QUEST.cmdName, {
                activityId = checkint(checktable(self.params.data).activityId),
                zoneId = checkint(checktable(self.params.data).zoneId), questId = checkint(checktable(self.params.data).questId),
                storyId = checkint(config.storyId) - 1,
                selectId = self.preIndex
            })
    end
end

function OptionView:ButtonActions(sender)
    if self.preIndex > 0 then
        local view = self:getChildByName("OPTION_VIEW")
        local optionNode = view:getChildByName("NAME_" .. tostring(self.preIndex))
        if optionNode then
            optionNode:setChecked(false)
        end
    end
    sender:setChecked(true)
    local tag = sender:getTag()
    self.preIndex = tag
end

function OptionView:CreateHeadNodeView(view, selectedData, x, y)
    local roleCoordinateConfig = CommonUtils.GetConfigNoParser("activityQuest", "coordinate", selectedData.pointId)
    local headPath = CardUtils.GetCardHeadPathByCardId(roleCoordinateConfig.roleId)
    if utils.isExistent(headPath) then
        -- 裁头像
        -- layout:setCascadeOpacityEnabled(true)
        local headClipNode = cc.ClippingNode:create()
        headClipNode:setCascadeOpacityEnabled(true)
        -- headClipNode:setPosition(cc.p(153, 340))
        headClipNode:setPosition(cc.p(x, y))
        view:addChild(headClipNode, 5)
        local headBg = display.newImageView(_res('ui/home/activity/activityQuest/activity_maps_head_red'), x, y)
        view:addChild(headBg,2)
        local headBg = display.newNSprite(_res('ui/home/activity/activityQuest/activity_maps_head_1'), x, y)
        view:addChild(headBg,10)
        local stencilNode = display.newNSprite(_res('ui/home/activity/activityQuest/activity_maps_head_mengban'), 0,0)
        stencilNode:setScale(0.9)
        headClipNode:setAlphaThreshold(0)
        headClipNode:setStencil(stencilNode)

        local headNode = display.newImageView(headPath, 0, 0)
        headNode:setScale(0.5)
        headClipNode:addChild(headNode)
    end

    local nameLabel = display.newLabel(x + 50, y, fontWithColor(2, {ap = display.LEFT_CENTER, color = 'ffbb19', text = string.fmt('+_num_', { _num_ = checkint(selectedData.point)})}))
    view:addChild(nameLabel,10)
end

function OptionView:onCleanup()
    if not self.params.isReview then
        unregPost(POST.ACTIVITYQUEST_STORY_QUEST)
        shareFacade:UnRegistObserver(POST.ACTIVITYQUEST_STORY_QUEST.sglName, self)
    end
end
return OptionView

