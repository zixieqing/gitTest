local Mediator = mvc.Mediator
---@class ReturnWelfareWeeklyMediator:Mediator
local ReturnWelfareWeeklyMediator = class("ReturnWelfareWeeklyMediator", Mediator)

local NAME = "ReturnWelfareWeeklyMediator"
local app = app
local uiMgr = app.uiMgr

function ReturnWelfareWeeklyMediator:ctor( params, viewComponent )
	self.super:ctor(NAME,viewComponent)
    self.datas = checktable(params) or {}
    self.time = string.split(__('倒计时: |_time_|'), '|')
    self.range = string.split(__('|_from_month_|月|_from_day_|日~|_to_month_|月|_to_day_|日'), '|')
end

function ReturnWelfareWeeklyMediator:InterestSignals()
	local signals = { 
		POST.BACK_DRAW_WEEKLY_LOGIN.sglName,
		'RETURN_WELFARE_WEEK_COUNT_DOWN'
	}

	return signals
end

function ReturnWelfareWeeklyMediator:ProcessSignal( signal )
	local name = signal:GetName() 
	local body = signal:GetBody()
	-- dump(body, name)
    if name == POST.BACK_DRAW_WEEKLY_LOGIN.sglName then
        uiMgr:AddDialog('common.RewardPopup', body)
        CommonUtils.RefreshDiamond(body)
        local weeklyRewardId = body.requestData.weeklyRewardId
        for k,v in pairs(self.datas.data.weeklyRewards) do
            if v.weeklyRewardId == weeklyRewardId then
                v.hasDrawn = 1
                break
            end
        end
        self:RefreshUI()
        app:DispatchObservers('EVENT_HOME_RED_POINT')
	elseif name == 'RETURN_WELFARE_WEEK_COUNT_DOWN' then
		local viewData = self.viewComponent.viewData
        local data = self.datas.data
        local today = checkint(data.weeklyRewardsCurrentId)
        local weeklyRewards = data.weeklyRewards[today]
        local textRich = {}
        for k,text in ipairs(self.time) do
            if '_time_' == text then
                table.insert(textRich, {text = self:FormatTime(weeklyRewards.leftSeconds), fontSize = 18, color = '#ffe9b4', font = TTF_GAME_FONT, ttf = true, outline = '#37180e'})
            elseif '' ~= text then
                table.insert(textRich, {text = text, fontSize = 18, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#37180e'})
            end
        end
        display.reloadRichLabel(viewData.countDownLabels[today], {c = textRich})
    end
end

function ReturnWelfareWeeklyMediator:Initial( key )
	self.super.Initial(self, key)
	-- local scene = uiMgr:GetCurrentScene()
	local viewComponent  = require('Game.views.returnWelfare.ReturnWelfareWeeklyView').new()
	self:SetViewComponent(viewComponent)
	viewComponent:setPosition(display.center)
    -- scene:AddDialog(viewComponent)
    self.datas.parent:addChild(viewComponent)
    
    -- if not cc.SpriteFrameCache:getInstance():getSpriteFrame(_res('ui/common/common_frame_goods_1.png')) then
    --     self:CreateSpriteSheet()
    -- end
    self:InitUI()
    self:RefreshUI()
    local viewData = viewComponent.viewData
    local drawBtns = viewData.drawBtns
    local gridViews = viewData.gridViews
    local data = self.datas.data
    for i=1,4 do
        drawBtns[i]:setTag(data.weeklyRewards[i].weeklyRewardId)
        drawBtns[i]:setOnClickScriptHandler(handler(self, self.DrawBtnClickHandler))
    end
end

function ReturnWelfareWeeklyMediator:InitUI(  )
    local viewData = self.viewComponent.viewData
    local gridViews = viewData.gridViews

    local data = self.datas.data

    local handlers = {
        handler(self, self.RewardsGridViewDataAdapter1),
        handler(self, self.RewardsGridViewDataAdapter2),
        handler(self, self.RewardsGridViewDataAdapter3),
        handler(self, self.RewardsGridViewDataAdapter4)
    }
    for i=1,4 do
        local gridView = gridViews[i]
        gridView:setCountOfCell(table.nums(data.weeklyRewards[i].rewards))
        gridView:setDataSourceAdapterScriptHandler(handlers[i])
        gridView:reloadData()
    end
    local dates = viewData.dates
    for i=1,4 do
        local weeklyRewards = data.weeklyRewards[i]
        local from = string.split(weeklyRewards.beginDay, '-')
        local to = string.split(weeklyRewards.endDay, '-')
        local text = {}
        for k,v in ipairs(self.range) do
            if '_from_month_' == v then
                table.insert( text, tonumber(from[2]) )
            elseif '_from_day_' == v then
                table.insert( text, tonumber(from[3]) )
            elseif '_to_month_' == v then
                table.insert( text, tonumber(to[2]) )
            elseif '_to_day_' == v then
                table.insert( text, tonumber(to[3]) )
            elseif '' ~= v then
                table.insert( text, v )
            end
        end
        dates[i]:setString(table.concat( text ))
    end
end

function ReturnWelfareWeeklyMediator:RefreshUI(  )
    local viewData = self.viewComponent.viewData
    local BGs = viewData.BGs
    local curBGs = viewData.curBGs
    local dateBGs = viewData.dateBGs
    local supples = viewData.supples
    local drawBtns = viewData.drawBtns
    local countDowns = viewData.countDowns
    local countDownLabels = viewData.countDownLabels
    local costLabels = viewData.costLabels
    local costIcons = viewData.costIcons

    local data = self.datas.data

    local today = checkint(data.weeklyRewardsCurrentId)

    for i=1,4 do
        local weeklyRewards = data.weeklyRewards[i]
        if today == i then
            BGs[i]:setVisible(false)
            curBGs[i]:setVisible(true)
            dateBGs[i]:setVisible(true)
        else
            BGs[i]:setVisible(true)
            curBGs[i]:setVisible(false)
            dateBGs[i]:setVisible(false)
        end
        supples[i]:setVisible(false)
        countDowns[i]:setVisible(false)
        countDownLabels[i]:setVisible(false)
        costLabels[i]:setVisible(false)
        costIcons[i]:setVisible(false)
        if 1 == checkint(weeklyRewards.hasDrawn) and i <= today then
            drawBtns[i]:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
            drawBtns[i]:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
            display.commonLabelParams(drawBtns[i], fontWithColor(14, {text = __('已领取')}))
            drawBtns[i].redPointImg:setVisible(false)
        else
            if i > today then
                drawBtns[i]:setNormalImage(_res('ui/common/common_btn_orange_disable.png'))
                drawBtns[i]:setSelectedImage(_res('ui/common/common_btn_orange_disable.png'))
                display.commonLabelParams(drawBtns[i], fontWithColor(14, {text = __('领取')}))
                drawBtns[i].redPointImg:setVisible(false)
            else
                if i == today then
                    drawBtns[i]:setNormalImage(_res('ui/common/common_btn_orange.png'))
                    drawBtns[i]:setSelectedImage(_res('ui/common/common_btn_orange.png'))
                    display.commonLabelParams(drawBtns[i], fontWithColor(14, {text = __('领取')}))
                    countDowns[i]:setVisible(true)
                    countDownLabels[i]:setVisible(true)
                    local textRich = {}
                    for k,text in ipairs(self.time) do
                        if '_time_' == text then
                            table.insert(textRich, {text = self:FormatTime(weeklyRewards.leftSeconds), fontSize = 18, color = '#ffe9b4', font = TTF_GAME_FONT, ttf = true, outline = '#37180e'})
                        elseif '' ~= text then
                            table.insert(textRich, {text = text, fontSize = 18, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#37180e'})
                        end
                    end
                    display.reloadRichLabel(countDownLabels[i], {c = textRich})
                    drawBtns[i].redPointImg:setVisible(true)
                else
                    supples[i]:setVisible(true)
                    drawBtns[i]:setNormalImage(_res('ui/common/common_btn_green.png'))
                    drawBtns[i]:setSelectedImage(_res('ui/common/common_btn_green.png'))
                    display.commonLabelParams(drawBtns[i], fontWithColor(14, {text = ''}))
                    costLabels[i]:setVisible(true)
                    costIcons[i]:setVisible(true)
                    costLabels[i]:setString(data.weeklyRewardsReplenishConsumeNum)
                    display.setNodesToNodeOnCenter(drawBtns[i], {costLabels[i], costIcons[i]})
                    drawBtns[i].redPointImg:setVisible(false)
                end
            end
        end
    end
end

function ReturnWelfareWeeklyMediator:ResetMdt( data )
    self.datas.data = checktable(data) or {}
    self:RefreshUI()
end

function ReturnWelfareWeeklyMediator:FormatTime(countdown)
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

function ReturnWelfareWeeklyMediator:DrawBtnClickHandler(sender)
	PlayAudioByClickNormal()
    local tag = sender:getTag()
    local data = self.datas.data
    local today = checkint(data.weeklyRewardsCurrentId)
    for i,v in ipairs(data.weeklyRewards) do
        if v.weeklyRewardId == tag then
            if today < i then
                uiMgr:ShowInformationTips(__('不符合领取条件'))
            elseif 0 == checkint(v.hasDrawn) then
                local available = true
                if today > i then
                    if CommonUtils.GetCacheProductNum(DIAMOND_ID) < checkint(data.weeklyRewardsReplenishConsumeNum) then
                        available = false
                    end
                end
                if not available then
                    uiMgr:ShowInformationTips(__('幻晶石不足'))
                else
                    self:SendSignal(POST.BACK_DRAW_WEEKLY_LOGIN.cmdName, {weeklyRewardId = tag})
                end
            else
                uiMgr:ShowInformationTips(__('不可重复领取'))
            end
            break
        end
    end
end

function ReturnWelfareWeeklyMediator:RewardsGridViewDataAdapter1(c, i)
    return self:RewardsGridViewDataAdapter(c, i, self.datas.data.weeklyRewards[1].rewards)
end

function ReturnWelfareWeeklyMediator:RewardsGridViewDataAdapter2(c, i)
    return self:RewardsGridViewDataAdapter(c, i, self.datas.data.weeklyRewards[2].rewards)
end

function ReturnWelfareWeeklyMediator:RewardsGridViewDataAdapter3(c, i)
    return self:RewardsGridViewDataAdapter(c, i, self.datas.data.weeklyRewards[3].rewards)
end

function ReturnWelfareWeeklyMediator:RewardsGridViewDataAdapter4(c, i)
    return self:RewardsGridViewDataAdapter(c, i, self.datas.data.weeklyRewards[4].rewards)
end

function ReturnWelfareWeeklyMediator:RewardsGridViewDataAdapter(c, i, s)
	local index = i + 1
	local cell = c

    if nil == cell then
		cell = CGridViewCell:new()
        cell:setContentSize(cc.size(130, 120))
        cell:setCascadeOpacityEnabled(true)

        local goodsIcon = require('common.GoodNode').new({
            id = s[index].goodsId,
            amount = s[index].num,
            showAmount = true,
            -- useSpriteFrame = true,
            callBack = function (sender)
                uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
            end
        })
        goodsIcon:setPosition(65, 60)
        cell:addChild(goodsIcon)
	end

	return cell
end

function ReturnWelfareWeeklyMediator:CreateSpriteSheet(  )
    unrequire('Game.utils.RectanglePacker')
	local RectanglePacker = require('Game.utils.RectanglePacker')
	local frameRes = {
		{w = 108, h = 108, path = _res('ui/common/common_frame_goods_1.png')},
		{w = 108, h = 108, path = _res('ui/common/common_frame_goods_2.png')},
		{w = 108, h = 108, path = _res('ui/common/common_frame_goods_3.png')},
		{w = 108, h = 108, path = _res('ui/common/common_frame_goods_4.png')},
		{w = 108, h = 108, path = _res('ui/common/common_frame_goods_5.png')},
		{w = 108, h = 108, path = _res('ui/common/common_frame_goods_6.png')},
        {w = 108, h = 108, path = _res('ui/common/common_frame_goods_7.png')},
        
		{w = 108, h = 108, path = _res('ui/common/common_ico_fragment_1.png')},
		{w = 108, h = 108, path = _res('ui/common/common_ico_fragment_2.png')},
		{w = 108, h = 108, path = _res('ui/common/common_ico_fragment_3.png')},
		{w = 108, h = 108, path = _res('ui/common/common_ico_fragment_4.png')},
        {w = 108, h = 108, path = _res('ui/common/common_ico_fragment_5.png')},
        
		{w = 108, h = 108, path = _res('ui/common/common_ico_food_horn.png')},
        {w = 108, h = 108, path = _res('ui/common/common_frame_food.png')},
        {w = 108, h = 108, path = _res('ui/common/common_frame_goods_7_pifu.png')},

        {w = 160, h = 160, path = _res(CommonUtils.GetGoodsIconPathById(140050))},
	}
    for i,v in ipairs(frameRes) do
        RectanglePacker.insertRectangle(v.w, v.h)
    end
    
    local totalNums = RectanglePacker.packRectangles()
    local iconPlist = {}
    table.insert(iconPlist, [[
		<?xml version="1.0" encoding="UTF-8"?>
		<plist version="1.0">
			<dict>
				<key>frames</key>
				<dict>
	]])
	local renderTexture = cc.RenderTexture:create(1024, 1024)
	local gl = cc.Director:getInstance():getOpenGLView()
	gl:setDesignResolutionSize(1024, 1024, cc.ResolutionPolicy.EXACT_FIT)
	renderTexture:begin()
	local index = 1
	for i=1,totalNums do
		local rectangle = RectanglePacker.getRectangle(i)
        local frameConfig = frameRes[rectangle.id]
        local frameImg = display.newNSprite(frameConfig.path, rectangle.x, rectangle.y, {ap = cc.p(0, 0)})
        frameImg:visit()
        table.insert(iconPlist, '<key>')
        table.insert(iconPlist, frameConfig.path)
        table.insert(iconPlist, [[</key>
            <dict>
                <key>aliases</key>
                <array/>
                <key>spriteOffset</key>
                <string>{0,0}</string>
                <key>spriteSize</key>
                <string>{]] .. frameConfig.w .. ',' .. frameConfig.h .. [[}</string>
                <key>spriteSourceSize</key>
                <string>{]] .. frameConfig.w .. ',' .. frameConfig.h .. [[}</string>
                <key>textureRect</key>
                <string>{{]] .. rectangle.x .. ',' .. rectangle.y .. [[},{]] .. frameConfig.w .. ',' .. frameConfig.h .. [[}}</string>
                <key>textureRotated</key>
                <false/>
            </dict>
        ]])
    end
    table.insert( iconPlist, [[
            </dict>
            <key>metadata</key>
            <dict>
                <key>format</key>
                <integer>3</integer>
                <key>size</key>
                <string>{2048,2048}</string>
            </dict>
        </dict>
    </plist>
    ]])
    renderTexture:endToLua()
    display.setAutoScale(CC_DESIGN_RESOLUTION)
    local iconTexture = renderTexture:getSprite():getTexture()
    iconTexture:setAntiAliasTexParameters()
    cc.SpriteFrameCache:getInstance():addSpriteFramesWithFileContent(table.concat( iconPlist ), iconTexture)
end

function ReturnWelfareWeeklyMediator:OnRegist(  )
	regPost(POST.BACK_DRAW_WEEKLY_LOGIN)
end

function ReturnWelfareWeeklyMediator:OnUnRegist(  )
	unregPost(POST.BACK_DRAW_WEEKLY_LOGIN)
	-- local scene = uiMgr:GetCurrentScene()
	-- scene:RemoveGameLayer(self.viewComponent)
end

return ReturnWelfareWeeklyMediator