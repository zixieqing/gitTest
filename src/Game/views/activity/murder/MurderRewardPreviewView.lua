--[[
 * author : liuzhipeng
 * descpt : 杀人案（19夏活）奖励预览View
]]
local CommonDialog = require('common.CommonDialog')
local MurderRewardPreviewView = class('MurderRewardPreviewView', CommonDialog)

local RES_DIR = {
    BG             = app.murderMgr:GetResPath('ui/common/common_bg_4.png'),
    TAB_SELECTED   = app.murderMgr:GetResPath("ui/home/activity/summerActivity/entrance/summer_activity_entrance_rank_tab_selected.png"),
    TAB_UNUSED     = app.murderMgr:GetResPath("ui/home/activity/summerActivity/entrance/summer_activity_entrance_rank_tab_unused.png"),
}

local CreateView = nil
local summerActMgr = app.summerActMgr

local TAB_TAG = {
    TOTAL_DOT = 1,
    DAMAGE    = 2,
}

function MurderRewardPreviewView:InitialUI()
    xTry(function ( )
        self.viewData = CreateView()
        
        self:initView()
	end, __G__TRACKBACK__)
end

function MurderRewardPreviewView:initView()
    
end

function MurderRewardPreviewView:refreshUI(data)
    
end

function MurderRewardPreviewView:updateUI(data)
    
end

CreateView = function ()
    local size = cc.size(950, 645)
    local view = display.newLayer(0, 0, {size = size})
    
    local bgSize = cc.size(size.width, 590)
    local tabTexts = {
        summerActMgr:getThemeTextByText(app.murderMgr:GetPoText(__('推进时钟奖励'))),
        summerActMgr:getThemeTextByText(app.murderMgr:GetPoText(__('点数排行奖励')))
    }
    
    local tabs = {}
    for i, tabText in ipairs(tabTexts) do
        local tab = display.newCheckBox(150 + 240 * (i-1), bgSize.height - 2, {n = RES_DIR.TAB_UNUSED, s = RES_DIR.TAB_SELECTED, ap = display.CENTER_BOTTOM})
        view:addChild(tab)
        
        tab:addChild(display.newLabel(110, 25, fontWithColor(20, {text = tabText, fontSize = 20, outline = '#7b482f'})))
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

function MurderRewardPreviewView:getViewData()
    return self.viewData
end

function MurderRewardPreviewView:CloseHandler()
    AppFacade.GetInstance():UnRegsitMediator(self.args.mediatorName)
end

return MurderRewardPreviewView