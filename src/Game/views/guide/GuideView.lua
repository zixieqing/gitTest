--[[
 * descpt : 指南view
]]
local VIEW_SIZE = cc.size(988, 645)
local GuideView = class('GuideView', function ()
	local node = CLayout:create(VIEW_SIZE)
	node.name = 'Game.views.guide.GuideView'
	node:enableNodeEvents()
	return node
end)

local RES_DIR = {
    ARROW             = _res('ui/common/common_bg_tips_horn.png'),
    BOARD             = _res('ui/common/common_bg_tips.png'),
    ORANGE_BTN        = _res('ui/common/common_btn_orange.png'),
    SEARCHRECIPE      = _res('ui/home/kitchen/cooking_btn_pokedex.png'),
    FOODS_POKEDEX_IMG = _res('ui/home/kitchen/kitchen_btn_foods_pokedex.png'),
    FRAME_DOTTEDLINE  = _res('guide/guide_frame_dottedline.png'),
    ICO_HAND          = _res('guide/guide_ico_hand.png'),
    LABEL_TITLE       = _res('guide/guide_label_title.png'),
    LINE_DOTTED_1     = _res('guide/guide_line_dotted_1.png'),
}

local REUSE_DEFINE = {
    [MODULE_DATA[tostring(RemindTag.CAT_HOUSE)]] = {
        [2] = 1, [3] = 1, [5] = 4, [15] = 14, [16] = 14, [17] = 14
    }
}

local GetFilePageIndex = function(moduleId, pageIndex)
    if not REUSE_DEFINE[checkint(moduleId)] or not REUSE_DEFINE[checkint(moduleId)][checkint(pageIndex)] then
        return pageIndex
    else
        return REUSE_DEFINE[checkint(moduleId)][checkint(pageIndex)]
    end
end


local CreateView = nil

function GuideView:ctor(...)
    local args = unpack({...}) or {}
    self.prePageIndex = 0
    self.pageViewCachePool = {}
    self.moudleId = args.moudleId
    self.pageName = self:getGuidePageNameByMoudleId(self.moudleId)
    self:initialUI()
end

function GuideView:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView(VIEW_SIZE)
        self:addChild(self:getViewData().view)

        self:initView()
	end, __G__TRACKBACK__)
end

function GuideView:initView()
    
end

function GuideView:refreshUI(data)
    local confData  = data.confData or {}
    local pageIndex = data.pageIndex

    self:updateTitleLabel(confData['1'])
    self:updateDescLabel2(confData['2'])

    self:updatePageInfoPageIndex(pageIndex, confData)
end

function GuideView:updateTitleLabel(title)
    local viewData   = self:getViewData()
    local titleLabel = viewData.titleLabel
    display.commonLabelParams(titleLabel, {text = tostring(title),reqH = 110})
end

function GuideView:updateDescLabel2(desc)
    local viewData   = self:getViewData()
    local descLabel2 = viewData.descLabel2
    display.commonLabelParams(descLabel2, {text = CommonUtils.parserGuideDesc(desc)  ,reqH = 130})
end

function GuideView:updatePageInfoPageIndex(pageIndex, confData)
    local prePageView = self.pageViewCachePool[tostring(self.prePageIndex)]
    if self.prePageIndex ~= 0 and prePageView then
        prePageView:setVisible(false)
    end

    self.prePageIndex = pageIndex
    if self.pageViewCachePool[tostring(pageIndex)] then
        self.pageViewCachePool[tostring(pageIndex)]:setVisible(true)
    else
        local viewData = self:getViewData()
        local name     = string.fmt("Game.views.guide._name_._name__index_", {_name_ = self.pageName, _index_ = GetFilePageIndex(self.moudleId, pageIndex)})
        print("self.pageName" , self.pageName)
        print("pageIndex" , pageIndex)
        local pageView = require(name).new({pageIndex = pageIndex})
        display.commonUIParams(pageView, {po = cc.p(0, 0), ap = display.LEFT_BOTTOM})
        viewData.view:addChild(pageView)
        self.pageViewCachePool[tostring(pageIndex)] = pageView
        self.pageViewCachePool[tostring(pageIndex)]:refreshUI(confData)
    end
end

function GuideView:getGuidePageNameByMoudleId(moudleId)
    local name = ''
    if moudleId == MODULE_DATA[tostring(RemindTag.RESEARCH)] then
        name = 'GuideCookPage'
    elseif moudleId == MODULE_DATA[tostring(RemindTag.ORDER)] then
        name = 'GuideTakeoutPage'
    elseif moudleId == MODULE_DATA[tostring(RemindTag.CARDS)] then
        name = 'GuideCardPage'
    elseif moudleId == MODULE_DATA[tostring(RemindTag.PVC)] then
        name = 'GuidePVPPage'
    elseif moudleId == MODULE_DATA[tostring(RemindTag.TOWER)] then
        name = 'GuideTowerPage'
    elseif moudleId == MODULE_DATA[tostring(RemindTag.EXPLORE_SYSTEM)] then
        name = 'GuideExploreSystemPage'
    elseif moudleId == MODULE_DATA[tostring(RemindTag.TTGAME)] then
        name = 'GuideTTGamePage'
    elseif moudleId == MODULE_DATA[tostring(RemindTag.CAT_HOUSE)] then
        name = 'GuideCatModulePage'
    end
    return name
end

CreateView = function (size)
    local view = display.newLayer(0, 0, {size = size})

    local titleLabelBg = display.newImageView(RES_DIR.LABEL_TITLE, 5, size.height + 5, {ap = display.LEFT_TOP})
    view:addChild(titleLabelBg)

    local titleLabel = display.newLabel(50, 138, {ap = display.LEFT_TOP, fontSize = 29, w = 360, color = '#ffffff', outline = '#522514', outlineSize = 2})
    titleLabelBg:addChild(titleLabel)
    
    local line = display.newImageView(RES_DIR.LINE_DOTTED_1, 254, 180, {ap = display.CENTER})
    view:addChild(line)

    local descLabel2 = display.newLabel(55, 170, {ap = display.LEFT_TOP, w = 400, fontSize = 20, color = '#97766f'})
    view:addChild(descLabel2)

    return {
        view       = view,
        titleLabel = titleLabel,
        descLabel2 = descLabel2,
    }
end

function GuideView:getViewData()
    return self.viewData_
end

return GuideView