--[[
 * descpt : 创建工会 home 界面
]]

local TagMatchDetermineSignUpView = class('TagMatchDetermineSignUpView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.tagMatch.TagMatchDetermineSignUpView'
	node:enableNodeEvents()
	return node
end)

local cardMgr  = AppFacade.GetInstance():GetManager('CardManager')

local CreateView         = nil
local CreateTeamView     = nil

local RES_DIR = {
    BG                    = _res("ui/home/activity/tagMatch/activity_3v3_team_bg_all.jpg"),
    
}


function TagMatchDetermineSignUpView:ctor( ... )
    self.args = unpack({...}) or {}
    self:initData()
    self:initialUI()
end

function TagMatchDetermineSignUpView:initData()
    
end

function TagMatchDetermineSignUpView:initialUI()
    xTry(function ( )
        -- logInfo.add(5, logStr,isAutoWrap)
        self.viewData_ = CreateView(self.args.cardsDatas or {})
        self:addChild(self:getViewData().view)
        
        self:initView()
	end, __G__TRACKBACK__)
end

function TagMatchDetermineSignUpView:initView()
    local viewData = self:getViewData()
    local shallowLayer = viewData.shallowLayer
    display.commonUIParams(shallowLayer, {cb = handler(self, self.onCloseView)})

    local signUpBtn = viewData.signUpBtn
    display.commonUIParams(signUpBtn, {cb = handler(self, self.onSignUpAction)})
end

function TagMatchDetermineSignUpView:onCloseView()
    PlayAudioByClickClose()
    AppFacade.GetInstance():GetManager('UIManager'):GetCurrentScene():RemoveDialogByTag(self.args.tag)
end

function TagMatchDetermineSignUpView:onSignUpAction(sender)
    AppFacade.GetInstance():DispatchObservers('TAG_MATCH_DETERMINE_SIGN_UP')
    self:onCloseView()
end

CreateView = function (cardsDatas)
    local view = display.newLayer()
    local size = view:getContentSize()

    local shallowLayer = display.newLayer(0, 0, {ap = display.LEFT_BOTTOM, size = size, color = cc.c4b(0, 0, 0, 150), enable = true})
    view:addChild(shallowLayer)

    local bgLayer = display.newLayer(size.width / 2, size.height / 2, {ap = display.CENTER, bg = RES_DIR.BG, enable = true})
    local bgSize = bgLayer:getContentSize()
    view:addChild(bgLayer)

    for i = 1, 3 do
        local teamView = CreateTeamView(i, cardsDatas[tostring(i)], 1)
        display.commonUIParams(teamView, {po = cc.p(bgSize.width / 2, bgSize.height - 100 - 150 * (i - 1))})
        bgLayer:addChild(teamView)
    end

    view:addChild(display.newLabel(size.width / 2, size.height / 2 + bgSize.height / 2 + 30, {text = __('确认防守队伍'), ap = display.CENTER, fontSize = 40, color = '#ffffff', font = TTF_GAME_FONT, ttf = true, outline = '#5b3c25', outlineSize = 1}))
    view:addChild(display.newLabel(size.width / 2, size.height / 2 - bgSize.height / 2 - 20, {text = __('确认报名后不能再修改防守队伍'), ap = display.CENTER, fontSize = 22, color = '#ffe9b4', font = TTF_GAME_FONT, ttf = true, outline = '#3c1e0e', outlineSize = 1}))

    local signUpBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_orange.png')})
    display.commonUIParams(signUpBtn, {po = cc.p(size.width / 2, size.height / 2 - bgSize.height / 2 - 75), ap = display.CENTER})
    display.commonLabelParams(signUpBtn, fontWithColor(14, {text = __('确认报名')}))
    view:addChild(signUpBtn)

    return {
        view           = view,
        shallowLayer   = shallowLayer,
        signUpBtn      = signUpBtn,
    }
end

CreateTeamView = function (teamId, teamCards, teamMarkPosSign)
    local teamView = require("Game.views.tagMatch.TagMatchDefensiveTeamView").new({teamId = teamId or 1, teamDatas = teamCards or {}, teamMarkPosSign = teamMarkPosSign})
    return teamView
end

function TagMatchDetermineSignUpView:getViewData()
	return self.viewData_
end

return TagMatchDetermineSignUpView