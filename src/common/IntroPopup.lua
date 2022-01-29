--[[
 * author : kaishiqi
 * descpt : t通用介绍框
]]
local IntroPopup = class('IntroPopup', function()
    return display.newLayer()
end)

local RES_DICT = {
    BG_IMG   = 'ui/common/common_bg_4.png',
    CUT_LINE = 'ui/common/common_tips_line.png',
}

local CreateView = nil


-------------------------------------------------
-- life cycle

function IntroPopup:ctor(args)
    local args = checktable(args)
    self.isControllable_ = true

    -- create view
    self.viewData_ = CreateView()
    self:addChild(self.viewData_.view)

    -- init view
    display.commonUIParams(self.viewData_.blackBg, {cb = handler(self, self.onClickBlackBgHandler_), animate = false})

    -- parse args
    if args.moduleId then
        local moduleExplainConf = checktable(CommonUtils.GetConfigAllMess('moduleExplain'))[tostring(args.moduleId)] or {}
        self:setTitle(moduleExplainConf.title)
        self:setDescr(moduleExplainConf.descr)

    else
        self:setTitle(args.title)
        self:setDescr(args.descr)
    end
    self:setCloseCB(args.closeCB)

    self:show()
end


CreateView = function()
    local view = display.newLayer()
    local size = view:getContentSize()

    local blackBg = display.newLayer(0, 0, {color = cc.c4b(0,0,0,150), enable = true})
    blackBg:setCascadeOpacityEnabled(true)
    view:addChild(blackBg)

    local contentSize  = cc.size(580, 650)
    local contentLayer = display.newLayer(size.width/2, size.height/2, {bg = _res(RES_DICT.BG_IMG), scale9 = true, size = contentSize, ap = display.CENTER})
    contentLayer.bg:setTouchEnabled(true)
    view:addChild(contentLayer)

    local cutLine = display.newImageView(_res(RES_DICT.CUT_LINE), contentSize.width/2, contentSize.height - 52, {scale9 = true, size = cc.size(contentSize.width - 40, 2)})
    contentLayer:addChild(cutLine)

    local titleLabel = display.newLabel(contentSize.width/2, contentSize.height - 30, fontWithColor(2, {fontSize = 24, color = '#5b3c25'}))
    contentLayer:addChild(titleLabel)

    local descrViewGapW = 25
    local descrViewGapH = 10
    local descrViewSize  = cc.size(contentSize.width - descrViewGapW*2, contentSize.height - descrViewGapH*2 - 48)
	local descrContainer = cc.ScrollView:create()
    descrContainer:setPosition(cc.p(descrViewGapW, descrViewGapH))
	descrContainer:setDirection(eScrollViewDirectionVertical)
	descrContainer:setAnchorPoint(display.LEFT_BOTTOM)
    descrContainer:setViewSize(descrViewSize)
	contentLayer:addChild(descrContainer)

    local descrLabel = display.newLabel(0, 0, fontWithColor(6, {hAlign = display.TAL, w = descrViewSize.width, ttf = true, font = TTF_TEXT_FONT, fontSize = 26}))
	descrContainer:setContainer(descrLabel)

    return {
        view           = view,
        blackBg        = blackBg,
        titleLabel     = titleLabel,
        descrLabel     = descrLabel,
        contentLayer   = contentLayer,
        descrContainer = descrContainer,
    }
end


-------------------------------------------------
-- get / set

function IntroPopup:getTitle()
    return self.title_
end
function IntroPopup:setTitle(title)
    self.title_ = title
    display.commonLabelParams(self.viewData_.titleLabel, {text = tostring(self.title_)})
end


function IntroPopup:getDescr()
    return self.descr_
end
function IntroPopup:setDescr(descr)
    self.descr_ = descr

    local descrLabel = self.viewData_.descrLabel
    display.commonLabelParams(descrLabel, {text = tostring(self.descr_)})

    local descrContainer = self.viewData_.descrContainer
	local descrScrollTop = descrContainer:getViewSize().height - display.getLabelContentSize(descrLabel).height
	descrContainer:setContentOffset(cc.p(0, descrScrollTop))
end


function IntroPopup:setCloseCB(closeCB)
    self.closeCallback_ = closeCB
end


-------------------------------------------------
-- public method

function IntroPopup:close()
    self:runAction(cc.RemoveSelf:create())
end


-------------------------------------------------
-- private method

function IntroPopup:show()
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

function IntroPopup:hide()
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
            if self.closeCallback_ then
                self.closeCallback_()
            else
                self:close()
            end
        end)
    }))
end


-------------------------------------------------
-- handler

function IntroPopup:onClickBlackBgHandler_(sender)
    if not self.isControllable_ then return end
    self:hide()
end



return IntroPopup
