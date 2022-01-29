local CommonDialog = require('common.CommonDialog')
local SummerActivityRankRewardView = class('SummerActivityRankRewardView', CommonDialog)

local RES_DIR = {
    BG             = _res('ui/common/common_bg_4.png'),
    TAB_SELECTED   = _res("ui/home/activity/summerActivity/entrance/summer_activity_entrance_rank_tab_selected.png"),
    TAB_UNUSED     = _res("ui/home/activity/summerActivity/entrance/summer_activity_entrance_rank_tab_unused.png"),
}

local CreateView = nil
local summerActMgr = app.summerActMgr

local TAB_TAG = {
    TOTAL_DOT = 1,
    DAMAGE    = 2,
}

function SummerActivityRankRewardView:InitialUI()
    xTry(function ( )
        self.viewData = CreateView()
        
        self:initView()
	end, __G__TRACKBACK__)
end

function SummerActivityRankRewardView:initView()
    
end

function SummerActivityRankRewardView:refreshUI(data)
    
end

function SummerActivityRankRewardView:updateUI(data)
    
end

CreateView = function ()
    local size = cc.size(950, 645)
    local view = display.newLayer(0, 0, {size = size})
    
    local bgSize = cc.size(size.width, 590)
    local tabTexts = {
        summerActMgr:getThemeTextByText(__('乐园游玩奖励')),
        summerActMgr:getThemeTextByText(__('点数排行奖励')),
        summerActMgr:getThemeTextByText(__('伤害排行奖励'))
    }
    
    local tabs = {}
    for i, tabText in ipairs(tabTexts) do
        local tab = display.newCheckBox(150 + 240 * (i-1), bgSize.height - 2, {n = RES_DIR.TAB_UNUSED, s = RES_DIR.TAB_SELECTED, ap = display.CENTER_BOTTOM})
        view:addChild(tab)
        
        tab:addChild(display.newLabel(110, 25, fontWithColor(20, {w = 200, text = tabText, fontSize = 18, hAlign = display.TAC, outline = '#7b482f'})))
        table.insert(tabs, tab)
    end
    
    view:addChild(display.newImageView(RES_DIR.BG, size.width / 2, 0, {size = bgSize, scale9 = true, ap = display.CENTER_BOTTOM}))

    local contentLayer = display.newLayer(size.width / 2, 0, {size = bgSize, ap = display.CENTER_BOTTOM})
    view:addChild(contentLayer)

    return {
        view         = view,
        tabs         = tabs,
        contentLayer = contentLayer,
    }
end

function SummerActivityRankRewardView:getViewData()
    return self.viewData
end

function SummerActivityRankRewardView:CloseHandler()
    AppFacade.GetInstance():UnRegsitMediator(self.args.mediatorName)
end

return SummerActivityRankRewardView