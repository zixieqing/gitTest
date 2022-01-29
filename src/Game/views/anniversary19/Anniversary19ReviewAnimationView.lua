--[[
 * author : kaishiqi
 * descpt : 周年庆-回顾动画 界面
]]
local Anniversary19ReviewAnimationView = class('Anniversary19ReviewAnimationView', function()
    return display.newLayer(0, 0, {name = 'Game.views.anniversary19.Anniversary19ReviewAnimationView'})
end)

local RES_DICT = {
    SKIP_BTN = app.anniversary2019Mgr:GetResPath('arts/stage/ui/opera_btn_skip.png'),
    BG_IMAGE = app.anniversary2019Mgr:GetResPath('ui/cards/marry/card_contract_bg_memory.jpg'),
}

local HIDE_SKIP_DELAY   = 2  -- 自动隐藏跳过按钮时间
local LOAD_TASK_DELAY   = 0.4  -- 加载资源的任务间隔
local ROLE_NAME_PREFIX  = 'role_'
local CARD_NAME_PREFIX  = 'card_draw_'
local SPINE_NAME_PREFIX = 'spn_'
local BGM_NAME_PREFIX   = 'bgm_'
local ROLE_NAME_LENGTH  = string.len(ROLE_NAME_PREFIX)
local CARD_NAME_LENGTH  = string.len(CARD_NAME_PREFIX)
local SPINE_NAME_LENGTH = string.len(SPINE_NAME_PREFIX)
local BGM_NAME_LENGTH   = string.len(BGM_NAME_PREFIX)
local ROLE_NAME_SCHEMA  = string.fmt('(%1[0-9]+)_.*', ROLE_NAME_PREFIX)
local CARD_NAME_SCHEMA  = string.fmt('%1([0-9]+)_.*', CARD_NAME_PREFIX)
local SPINE_NAME_SCHEMA = string.fmt('%1(.*)', SPINE_NAME_PREFIX)
local BGM_NAME_SCHEMA   = string.fmt('%1(.*)', BGM_NAME_PREFIX)

local CreateView = nil
local CreatePage = nil


-------------------------------------------------
-- life cycle

function Anniversary19ReviewAnimationView:ctor(args)
    self.isControllable_ = true
    StopBGMusic()

    -- create view
    self.viewData_ = CreateView()
    self:addChild(self.viewData_.view)

    -- add listen
    display.commonUIParams(self:getViewData().hotspot, {cb = handler(self, self.onClickSkipHotspotHandler_)})
    display.commonUIParams(self:getViewData().skipBtn, {cb = handler(self, self.onClickCloseButtonHandler_), animate = false})

    -- init views
    self:hideSkip_(true)
    self:playPage('kaichang')
end


-------------------------------------------------
-- view define

CreateView = function() 
    local view = display.newLayer()
    local size = view:getContentSize()

    -- block layer
    view:addChild(display.newLayer(0, 0, {size = size, color = cc.c4b(0,0,0,255), enable = true}))
    view:addChild(display.newImageView(RES_DICT.BG_IMAGE, size.width/2, size.height/2))

    -- play layer
    local playLayer = display.newLayer()
    view:addChild(playLayer)
    
    -- skip button
    local skipGapL = 0
    local initSize = cc.size(176, 62)
    local skipSize = cc.size(skipGapL + initSize.width + display.SAFE_L, initSize.height)
    local skipOffP = cc.p(skipSize.width/2 - display.SAFE_L - 20, 0)
    local capRect  = cc.rect(110, 0, 1, initSize.height)
    local skipBtn  = display.newButton(display.width, 75, {n = RES_DICT.SKIP_BTN, ap = display.RIGHT_CENTER, scale9 = true, capInsets = capRect, size = skipSize})
    display.commonLabelParams(skipBtn, fontWithColor(20, {text = app.anniversary2019Mgr:GetPoText(__('跳过')), fontSize = 24, ap = display.RIGHT_CENTER, offset = skipOffP}))
    view:addChild(skipBtn)

    -- hotspot
    local hotspot = display.newLayer(0, 0, {size = size, color = cc.r4b(0), enable = true})
    view:addChild(hotspot)

    return {
        view      = view,
        skipBtn   = skipBtn,
        hotspot   = hotspot,
        playLayer = playLayer,
    }
end


CreatePage = function(pageName)
    local view     = display.newLayer()
	local pageView = nil
	local timeline = nil

    local pageFile = app.anniversary2019Mgr:GetResPath(string.format('ui/anniversary19/reviewAnimate/%s.csb', tostring(pageName)))
	if utils.isExistent(pageFile) then
        pageView = cc.CSLoader:createNode(pageFile)
        timeline = cc.CSLoader:createTimeline(pageFile)
        pageView:setAnchorPoint(display.CENTER)
        pageView:setPosition(display.center)
        pageView:runAction(timeline)
        view:addChild(pageView)
	end

	return {
		view     = view,
		pageView = pageView,
		timeline = timeline
	}
end


-------------------------------------------------
-- get / set
function Anniversary19ReviewAnimationView:getViewData()
    return self.viewData_
end


-------------------------------------------------
-- public method

function Anniversary19ReviewAnimationView:close()
    -- clean page
    self:cleanPage()

    -- play default bgm
    PlayBGMusic()
    
    -- close self
    self:runAction(cc.RemoveSelf:create())
end


function Anniversary19ReviewAnimationView:cleanPage()
    -- stop listen
    self:stopCheckPlayEnd_()

    -- remove pageView
    if self.pageViewData_ then
        if self.pageViewData_.timeline then
            self.pageViewData_.timeline:clearFrameEventCallFunc()
        end
        if self.pageViewData_.view and self.pageViewData_.view:getParent() then
            self.pageViewData_.view:stopAllActions()
            self.pageViewData_.view:runAction(cc.RemoveSelf:create())
        end
        self.pageViewData_ = nil
    end

    -- stop page audio
    self:stopAudio_()

    -- stop page bgm
    StopBGMusic()
end


function Anniversary19ReviewAnimationView:playPage(pageName)
    -- clean page
    self:cleanPage()

    -- create page
    self.pageViewData_ = CreatePage(pageName)
    self:getViewData().playLayer:addChild(self.pageViewData_.view)
    
    -- play page
    if self.pageViewData_.timeline then
        local onFrameEvent = function(frame)
            if nil == frame then return end
            local frameName = checkstr(frame:getEvent())

            -- check bgm
            if string.sub(frameName, 0, BGM_NAME_LENGTH) == BGM_NAME_PREFIX then
                local bgmName = string.gsub(frameName, BGM_NAME_SCHEMA, '%1')
                PlayBGMusic(bgmName)
            else
                local audioPath = app.anniversary2019Mgr:GetResPath(string.fmt('ui/anniversary19/reviewAnimate/mp3/%1.mp3', frameName))
                self:playAudio_(audioPath)
            end
        end
		self.pageViewData_.timeline:setFrameEventCallFunc(onFrameEvent)
        self.pageViewData_.timeline:gotoFrameAndPlay(0, false)
        -- self.pageViewData_.timeline:gotoFrameAndPause(100)
        
        -- add load task
        local loadActList = {}
        self:eachPageNode_(self.pageViewData_.pageView, function(node)
            local nodeName = node:getName()

            -- check role
            if string.sub(nodeName, 0, ROLE_NAME_LENGTH) == ROLE_NAME_PREFIX then
                local roleId = string.gsub(nodeName, ROLE_NAME_SCHEMA, '%1')
                table.insert(loadActList, cc.DelayTime:create(LOAD_TASK_DELAY))
                table.insert(loadActList, cc.CallFunc:create(handler({node = node, roleId = roleId}, function(args)
                    local roleNode = CommonUtils.GetRoleNodeById(args.roleId)
                    roleNode:setAnchorPoint(display.LEFT_BOTTOM)
                    args.node:addChild(roleNode)
                end)))

            -- check card
            elseif string.sub(nodeName, 0, CARD_NAME_LENGTH) == CARD_NAME_PREFIX then
                local cardId = string.gsub(nodeName, CARD_NAME_SCHEMA, '%1')
                local skinId = CardUtils.GetCardSkinId(cardId)
                table.insert(loadActList, cc.DelayTime:create(LOAD_TASK_DELAY))
                table.insert(loadActList, cc.CallFunc:create(handler({node = node, skinId = skinId}, function(args)
                    local drawName = CardUtils.GetCardDrawNameBySkinId(args.skinId)
                    local drawNode = AssetsUtils.GetCardDrawNode(drawName)
                    drawNode:setAnchorPoint(display.LEFT_BOTTOM)
                    args.node:addChild(drawNode)
                end)))

            -- check spine
            elseif string.sub(nodeName, 0, SPINE_NAME_LENGTH) == SPINE_NAME_PREFIX then
                local spinePath = app.anniversary2019Mgr:GetSpinePath(string.fmt('ui/anniversary19/reviewAnimate/spine/%1', nodeName))
                local pageSpine = sp.SkeletonAnimation:create(spinePath.json, spinePath.atlas, 1)
                pageSpine:setAnimation(0, nodeName, true)
                node:addChild(pageSpine)
            end
        end)
        self.pageViewData_.view:runAction(cc.Sequence:create(loadActList))
    end

    -- listen playEnd
    self:startCheckPlayEnd_()
end


-------------------------------------------------
-- private method

function Anniversary19ReviewAnimationView:playAudio_(audioPath)
    if CommonUtils.GetControlGameProterty(CONTROL_GAME.GAME_MUSIC_EFFECT) then
        cc.SimpleAudioEngine:getInstance():playMusic(audioPath, false)
    end
end
function Anniversary19ReviewAnimationView:stopAudio_()
    cc.SimpleAudioEngine:getInstance():stopMusic(true)
end


function Anniversary19ReviewAnimationView:hideSkip_(isFast)
    self.isControllable_ = false
    local finishCB = function()
        self.isControllable_ = true
        self:getViewData().skipBtn:setOpacity(0)
        self:getViewData().skipBtn:stopAllActions()
        self:getViewData().hotspot:setVisible(true)
    end

    if isFast then
        finishCB()
    else
        self:runAction(cc.Sequence:create(
            cc.TargetedAction:create(self:getViewData().skipBtn, cc.FadeOut:create(0.2)),
            cc.CallFunc:create(finishCB)
        ))
    end
end


function Anniversary19ReviewAnimationView:showSkip_(isFast, isForever)
    self.isControllable_ = false
    local finishCB = function()
        self.isControllable_ = true
        self:getViewData().hotspot:setVisible(false)
        self:getViewData().skipBtn:setOpacity(255)
        self:getViewData().skipBtn:stopAllActions()
        if not isForever then
            self:getViewData().skipBtn:runAction(cc.Sequence:create(
                cc.DelayTime:create(HIDE_SKIP_DELAY),
                cc.CallFunc:create(function()
                    self:getViewData().skipBtn:stopAllActions()
                    self:hideSkip_()
                end)
            ))
        end
    end

    if isFast then
        finishCB()
    else
        self:runAction(cc.Sequence:create(
            cc.TargetedAction:create(self:getViewData().skipBtn, cc.FadeIn:create(0.2)),
            cc.CallFunc:create(finishCB)
        ))
    end
end


function Anniversary19ReviewAnimationView:eachPageNode_(pageView, eachFunc)
    if not pageView then return end

    local children = pageView:getChildren()
    for _, child in ipairs(children) do
        self:eachPageNode_(child, eachFunc)
        if eachFunc then eachFunc(child) end
    end
end


function Anniversary19ReviewAnimationView:startCheckPlayEnd_()
    if self.updateFrameFunc_ then return end
    self.updateFrameFunc_ = scheduler.scheduleUpdateGlobal(function()
        
        -- check play ended
        local currentPageTimeline = self.pageViewData_ and self.pageViewData_.timeline or nil
        if currentPageTimeline and currentPageTimeline:getCurrentFrame() >= currentPageTimeline:getEndFrame() then

        	-- stop countdown
            self:stopCheckPlayEnd_()
            
            -- show skip
            self:showSkip_(false, true)
        end
    end)
end
function Anniversary19ReviewAnimationView:stopCheckPlayEnd_()
	if self.updateFrameFunc_ then
        scheduler.unscheduleGlobal(self.updateFrameFunc_)
        self.updateFrameFunc_ = nil
    end
end


-------------------------------------------------
-- handler

function Anniversary19ReviewAnimationView:onClickSkipHotspotHandler_(sender)
    if not self.isControllable_ then return end
    
    self:showSkip_()
end


function Anniversary19ReviewAnimationView:onClickCloseButtonHandler_(sender)
    PlayAudioByClickClose()
    if not self.isControllable_ then return end

    self:close()
end


return Anniversary19ReviewAnimationView
