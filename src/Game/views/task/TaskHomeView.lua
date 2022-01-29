local TaskHomeView = class('TaskHomeView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.task.TaskHomeView'
	node:enableNodeEvents()
	return node
end)

local CreateView      = nil

local RES_DIR = {
    BG                  = _res("ui/common/common_bg_13.png"),
    TITLE               = _res('ui/common/common_bg_title_2.png'),
    TAB_NORMAL 			= _res("ui/common/common_btn_sidebar_common.png"),
    TAB_PRESSED 		= _res("ui/common/common_btn_sidebar_selected.png"),
    RED_POINT_ICO       = _res('ui/common/common_ico_red_point.png'),
    DAILY_TITLE         = _res('ui/common/common_bg_title_2.png'),
    BTN_TIPS            = _res('ui/common/common_btn_tips.png'),
    ACHIEVEMENT_TITLE   = _res('ui/home/task/main/achievement_title.png'),
}

local TAB_TAG = {
    DAILY           = 1001,     -- 日常任务
    ACHIEVEMENT     = 1002,     -- 成长任务
    UNION           = 1003,     -- 工会日常任务
}

local TITLE_IMG_CONF = {
    [tostring(TAB_TAG.DAILY)]       = {img = RES_DIR.TITLE, offsetY = -20, textOffsetY = 0},
    [tostring(TAB_TAG.ACHIEVEMENT)] = {img = RES_DIR.ACHIEVEMENT_TITLE, offsetY = -13, textOffsetY = -21},
    [tostring(TAB_TAG.UNION)]       = {img = RES_DIR.TITLE, offsetY = -20, textOffsetY = 0},
}

function TaskHomeView:ctor( ... )
    self.args = unpack({...}) or {}
    self.tabConfs = self.args.tabConfs or {}
    self.tabTags = table.keys(self.tabConfs) or {}
    table.sort(self.tabTags)
    self:initialUI()
end

function TaskHomeView:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView(self.tabConfs, self.tabTags)
        self:addChild(self.viewData_.view)
	end, __G__TRACKBACK__)
end

--==============================--
--desc: 更新tab选择状态
--@params sender userdata tab
--@params isSelect bool 是否选择
--@return 
--==============================-- 
function TaskHomeView:updateTabSelectState_(sender, isSelect)
    sender:setChecked(isSelect)
    sender:setEnabled(not isSelect)
end

function TaskHomeView:updateTab(tag)
    local viewData  = self:getViewData()
    local bgSize    = viewData.bgSize

    local titleBg   = viewData.titleBg
    local titleConf = TITLE_IMG_CONF[tostring(tag)] or RES_DIR.TITLE
    local img       = titleConf.img
    local offsetY   = titleConf.offsetY
    titleBg:setTexture(img)
    titleBg:setPositionY(bgSize.height + offsetY)

    local titleBgSize = titleBg:getContentSize()

    local tabConf    = self.tabConfs[tostring(tag)] or {}
    local titleName  = tostring(tabConf.titleName)
    local titleLabel = viewData.titleLabel
    local textOffsetY = titleConf.textOffsetY
    display.commonUIParams(titleLabel,{po = cc.p(titleBgSize.width / 2, titleBgSize.height / 2 + textOffsetY)})
    display.commonLabelParams(titleLabel, {text = titleName})

    local ruleBtn = viewData.ruleBtn
    local isShowRule = tabConf.ruleTag ~= nil
    ruleBtn:setVisible(isShowRule)
    if isShowRule then
        local titleLabelSize = display.getLabelContentSize(titleLabel)
        ruleBtn:setPositionX(bgSize.width / 2 + titleLabelSize.width / 2 + 25)
    end

end

CreateView = function (tabConfs, tabTags)
    local view = display.newLayer()
    local size = view:getContentSize()
    
    local blackBg = display.newLayer(0, 0, {color = cc.c4b(0, 0, 0, 150), enable = true})
    view:addChild(blackBg)

    local layerSize = cc.size(1230, 641)
    local layer = display.newLayer(display.cx, display.cy, {ap = display.CENTER, size = layerSize})
    view:addChild(layer)

    local bgSize = cc.size(1082, 641)
    local bgLayer = display.newLayer(0, layerSize.height / 2, {ap = display.LEFT_CENTER, size = bgSize})
    layer:addChild(bgLayer)

    layer:addChild(display.newLayer(0, layerSize.height / 2, {color = cc.c4b(0,0,0,0), enable = true, ap = display.LEFT_CENTER, size = bgSize}))

    -- rule btn
    local ruleBtn = display.newButton(bgSize.width / 2, bgSize.height - 20, {ap = display.CENTER, n = RES_DIR.BTN_TIPS})
    layer:addChild(ruleBtn, 12)
    ruleBtn:setVisible(false)

    local bg = display.newImageView(RES_DIR.BG, 0, 0, {ap = display.LEFT_BOTTOM, size = bgSize, scale9 = true})
    bgLayer:addChild(bg)

    local titleBg = display.newImageView(RES_DIR.TITLE, 0, 0, {ap = display.CENTER})
	local titleBgSize = titleBg:getContentSize()
	local titleLabel = display.newLabel(0, 0, fontWithColor(7, {reqW = 240, ap = display.CENTER}))
	display.commonUIParams(titleBg,    {po = cc.p(bgSize.width / 2, bgSize.height - 20)})
	display.commonUIParams(titleLabel, {po = cc.p(titleBgSize.width / 2, titleBgSize.height / 2)})
	titleBg:addChild(titleLabel)    
    bgLayer:addChild(titleBg)
    

    local tabLayerSize = cc.size(143, layerSize.height - 50)
    local tabLayer = display.newLayer(bgSize.width - 35, tabLayerSize.height, {ap = display.LEFT_TOP, size = tabLayerSize})
    layer:addChild(tabLayer)

    local count = 1
    local tabButtons = {}
    for i,tag in ipairs(tabTags) do
        local data = tabConfs[tostring(tag)]
        if data then
            local tabButton = display.newCheckBox(0, 0, {n = RES_DIR.TAB_NORMAL, s = RES_DIR.TAB_PRESSED,})
            local tabButtonSize = tabButton:getContentSize()
            display.commonUIParams(tabButton, {ap = display.LEFT_TOP, po = cc.p(0, tabLayerSize.height - 10 - (count - 1) * tabButtonSize.height)})
            tabLayer:addChild(tabButton, 1)
            tabButton:setTag(data.tag)
            tabButtons[tostring(data.tag)] = tabButton

            tabLayer:addChild(display.newLayer(tabButton:getPositionX(), tabButton:getPositionY(), {ap = display.LEFT_TOP, size = tabButtonSize, enable = true, color = cc.c4b(0, 0, 0, 0)}))
    
            local tabNameLabel = display.newLabel(utils.getLocalCenter(tabButton).x - 5 , utils.getLocalCenter(tabButton).y + 15  ,
                fontWithColor(2,{w = 140, reqW = 120, hAlign = display.TAC, text = tostring(data.titleName),ap = cc.p(0.5, 0.5), color = '#3c3c3c', fontSize = 24}))
            tabButton:addChild(tabNameLabel)
            tabNameLabel:setTag(3)

            local tabNameLabelSize = display.getLabelContentSize(tabNameLabel)
			if tabNameLabelSize.height > 60  then
				display.commonLabelParams(tabNameLabel,{fontSize = 20,reqH = 45, text = tostring(data.titleName)})
			end
    
            local buttonSize = tabButton:getContentSize()
            local newImg = display.newImageView(RES_DIR.RED_POINT_ICO, buttonSize.width - 50, buttonSize.height, {ap = cc.p(0, 1)})
            tabButton:addChild(newImg, 6)
            newImg:setTag(789)
            newImg:setVisible(false)
    
            count = count + 1
        end
    end

    return {
        view          = view,
        layer         = layer,
        blackBg       = blackBg,
        bgLayer       = bgLayer,
        titleBg       = titleBg,
        titleLabel    = titleLabel,
        ruleBtn       = ruleBtn,
        tabButtons    = tabButtons,

        bgSize        = bgSize,
    }
end

function TaskHomeView:getViewData()
	return self.viewData_
end

return TaskHomeView