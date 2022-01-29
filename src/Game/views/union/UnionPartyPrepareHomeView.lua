--[[
 * descpt : 工会派对筹备 home 界面
]]
local VIEW_SIZE = display.size
local UnionPartyPrepareHomeView = class('UnionPartyPrepareHomeView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.union.UnionPartyPrepareHomeView'
	node:enableNodeEvents()
	return node
end)

local CreateView = nil
-- local CreatePrepareCompleteView_ = nil


local RES_DIR = {
    BG                = _res("ui/union/party/prepare/guild_party_bg.png"),
    TOP_IMG           = _res('ui/raid/room/raid_room_bg_up.png'),
    BTN_BACK          = _res('ui/common/common_btn_back.png'),
    TOP_TITLE_BG      = _res('ui/raid/room/raid_room_btn_title.png'),
    BTN_RULE          = _res('ui/common/common_btn_tips.png'),
    BG_SUCCEED        = _res("ui/union/party/prepare/guild_party_bg_succeed.png"),
    BG_CLOSED         = _res("ui/union/party/prepare/guild_party_bg_closed.png"),
    BG_FAILED         = _res("ui/union/party/prepare/guild_party_bg_failed.png"),
}

local SPINE_CATALOG = 'effects/union/party/'

function UnionPartyPrepareHomeView:ctor( ... )
    
    self.args = unpack({...})
    self:initialUI()
end

function UnionPartyPrepareHomeView:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView()
        self:addChild(self.viewData_.view)
	end, __G__TRACKBACK__)
end

CreateView = function ()
    local view = display.newLayer()
    local size = view:getContentSize()
    
    local blackBg = display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 150), enable = true})
    view:addChild(blackBg)
    
    local bg = display.newImageView(RES_DIR.BG, VIEW_SIZE.width / 2, VIEW_SIZE.height / 2, {ap = display.CENTER})
    view:addChild(bg)
    
    -- 顶部视图
    local topLayer = display.newLayer()
    view:addChild(topLayer, 1)

    local backBtn = display.newButton(display.SAFE_L + 75, size.height - 52, {n = _res(RES_DIR.BTN_BACK)})
    topLayer:addChild(backBtn)
    
    local topImg = display.newImageView(RES_DIR.TOP_IMG, 0, 0, {ap = display.LEFT_BOTTOM})
    local topImgSize = topImg:getContentSize()
    local topImgLayer = display.newLayer(VIEW_SIZE.width / 2, VIEW_SIZE.height, {ap = display.CENTER_TOP, size = topImgSize})
    topImgLayer:addChild(topImg)
    topLayer:addChild(topImgLayer)
    topImgLayer:setVisible(false)
    
    local topTitleBg = display.newImageView(RES_DIR.TOP_TITLE_BG, topImgSize.width / 2, topImgSize.height / 2 + 5, {ap = display.CENTER})
    local topTitleBgSize = topTitleBg:getContentSize()
    topImgLayer:addChild(topTitleBg)
    
    local leftTimeDescLabel = display.newLabel(0, 0, fontWithColor(7, {fontSize = 26}))
    topTitleBg:addChild(leftTimeDescLabel)

    local leftTimeLabel = display.newLabel(0, 0, fontWithColor(7, {fontSize = 24, color = '#ffb20e', ap = display.CENTER}))
    topTitleBg:addChild(leftTimeLabel)

    local leftTimeDescLabelSize = display.getLabelContentSize(leftTimeDescLabel)
    local leftTimeLabelSize     = display.getLabelContentSize(leftTimeLabel) --leftTimeLabel:getContentSize()
    
    display.commonUIParams(leftTimeDescLabel,{po = cc.p(topTitleBgSize.width / 2 - leftTimeLabelSize.width / 2, topTitleBgSize.height / 2 + 10)})
    display.commonUIParams(leftTimeLabel,{po = cc.p(topTitleBgSize.width / 2 + leftTimeDescLabelSize.width / 2, topTitleBgSize.height / 2 + 10)})

    local ruleBtn = display.newButton(topImgSize.width / 2 + topTitleBgSize.width / 2 + 25, topImgSize.height / 2 + 8, {n = RES_DIR.BTN_RULE})
    topImgLayer:addChild(ruleBtn)
    
    local recordBtn  = display.newButton(display.SAFE_R - 20, display.height - 50, {ap = display.RIGHT_CENTER,  n =_res('ui/home/teamformation/choosehero/team_btn_selection_unused.png')})
    display.commonLabelParams(recordBtn, fontWithColor('14' , {text = __('筹备日志')}))
    topLayer:addChild(recordBtn)
    recordBtn:setVisible(false)

    local contentLayer = display.newLayer()
    view:addChild(contentLayer)

    return {
        view              = view,
        blackBg           = blackBg,
        topLayer          = topLayer,
        topImgLayer       = topImgLayer,
        leftTimeDescLabel = leftTimeDescLabel,
        leftTimeLabel     = leftTimeLabel,
        backBtn           = backBtn,
        ruleBtn           = ruleBtn,
        recordBtn         = recordBtn,
        contentLayer      = contentLayer,

        topTitleBgSize    = topTitleBgSize,
    }
end

-- CreatePrepareCompleteView_ = function (partyId)
--     local view = display.newLayer()
--     partyId = partyId or 1

--     local spine = sp.SkeletonAnimation:create(string.format("effects/union/party/guild_party_bg_grade_%s.json", partyId), string.format('effects/union/party/guild_party_bg_grade_%s.atlas', partyId), 1)
--     spine:setPosition(cc.p(display.cx, display.cy))
--     spine:setAnimation(0, 'stop', false)
--     view:addChild(spine)
    
--     local spine1 = sp.SkeletonAnimation:create('effects/union/party/diban2.json', 'effects/union/party/diban2.atlas', 1)
--     spine1:setPosition(cc.p(display.cx, display.cy))
--     spine1:setAnimation(0, 'stop', false)
--     view:addChild(spine1)

--     return view
-- end

function UnionPartyPrepareHomeView:getViewData()
	return self.viewData_
end

function UnionPartyPrepareHomeView:CreatePrepareCompleteView(partySizeData)
    local view = display.newLayer(0, 0, {ap = display.CENTER})
    
    local floorImg = display.newImageView(RES_DIR.BG_SUCCEED, display.cx, display.cy - 40, {ap = display.CENTER})
    view:addChild(floorImg)
    
    local floorSpineLayer = display.newLayer()
    view:addChild(floorSpineLayer)
    
    local partyId = partySizeData.id or 1
    -- local floorSpine = sp.SkeletonAnimation:create(string.format("effects/union/party/guild_party_bg_grade_%s.json", partyId), string.format('effects/union/party/guild_party_bg_grade_%s.atlas', partyId), 1)
    -- floorSpine:setPosition(cc.p(display.cx, display.cy + 90))
    -- floorSpine:setAnimation(0, 'stop', false)
    -- floorSpineLayer:addChild(floorSpine)

    local floorPartySizeImg = display.newImageView(_res(string.format("ui/union/party/prepare/guild_party_bg_grade_%s.png", partyId)), display.cx, display.cy + 90, {ap = display.CENTER})
    floorSpineLayer:addChild(floorPartySizeImg)

    local partyLabel = display.newLabel(display.cx, display.cy + 110, fontWithColor(14, {text = tostring(partySizeData.name), fontSize = 70, color = '#ffffff', outline = '#581111', outlineSize = 2}))
    floorSpineLayer:addChild(partyLabel)

    local partyLabelSize = partyLabel:getContentSize()
    local prepareComplete = display.newLabel(display.cx + partyLabelSize.width / 2 + 20, partyLabel:getPositionY() - partyLabelSize.height / 2 - 20, fontWithColor(14, {text = __('筹备完成!'), fontSize = 40, color = '#ffffff', outline = '#581111', outlineSize = 2}))
    floorSpineLayer:addChild(prepareComplete)

    floorSpineLayer:runAction(cc.RepeatForever:create(cc.Sequence:create(
                                cc.MoveBy:create(2, cc.p(0, 15)),
                                cc.MoveBy:create(2, cc.p(0, -15))
                            )))

    local spine = sp.SkeletonAnimation:create('effects/union/party/diban2.json', 'effects/union/party/diban2.atlas', 1)
    spine:setPosition(cc.p(display.cx, display.cy))
    spine:setAnimation(0, 'idle', true)
    view:addChild(spine)

    return view
end

function UnionPartyPrepareHomeView:CreatePrepareNotCompleteView()
    local view = display.newLayer(0, 0, {ap = display.CENTER})

    local floorImg = display.newImageView(RES_DIR.BG_FAILED, display.cx, display.cy - 40, {ap = display.CENTER})
    view:addChild(floorImg)

    local floorImgSize = floorImg:getContentSize()
    local prepareTip = display.newLabel(190, 205, fontWithColor(7, {text = __('派对没开起来。。。'), fontSize = 40, color = '#ffffff', ap = display.LEFT_CENTER}))
    floorImg:addChild(prepareTip)

    return view
end

function UnionPartyPrepareHomeView:CreatePrepareUnopenedView()
    local view = display.newLayer(0, 0, {ap = display.CENTER})

    local floorImg = display.newImageView(RES_DIR.BG_CLOSED, display.cx, display.cy - 40, {ap = display.CENTER})
    view:addChild(floorImg)

    local floorImgSize = floorImg:getContentSize()
    local prepareTip = display.newLabel(floorImgSize.width / 2 + 16, floorImgSize.height - 130, fontWithColor(7, {text = __('正在清扫'), fontSize = 30, color = '#ffffff', ap = display.CENTER}))
    floorImg:addChild(prepareTip)

    local prepareTipSize = prepareTip:getContentSize()
    local prepareTip1 = display.newLabel(prepareTip:getPositionX(), prepareTip:getPositionY() - prepareTipSize.height / 2 - 35, fontWithColor(7, {text = __('瓜皮果壳'), fontSize = 30, color = '#ffffff', ap = display.CENTER}))
    floorImg:addChild(prepareTip1)

    return view
end


return UnionPartyPrepareHomeView
