--[[
 * author : panmeng
 * descpt : 猫屋工作回报
]]

local CommonDialog   = require('common.CommonDialog')
local CatModuleWorkRewardPopup = class('CatModuleWorkRewardPopup', CommonDialog)

local RES_DICT = {
    BG_FRAME    = _res('ui/catModule/catInfo/work/grow_cat_work_bg_present.png'),
    COM_TITLE   = _res('ui/catModule/catInfo/work/grow_cat_work_bg_present_head.png'),
    BG_TITLE    = _res("ui/catModule/catRecord/grow_cat_record_news_bg_head.png"),
    BTN_CONFIRM = _res('ui/common/common_btn_orange.png'),
}

function CatModuleWorkRewardPopup:ctor(args)
    self.ctorArgs_ = checktable(args)
    self.super.ctor(self, args)

end


function CatModuleWorkRewardPopup:InitialUI()
    -- create view
    self.viewData = CatModuleWorkRewardPopup.CreateView()
    self:setPosition(display.center)

    -- bind event
    ui.bindClick(self:getViewData().confirmBtn, handler(self, self.onClickConfirmBtnHandler_))

    -- update view
    self:setNormalRewards(self.ctorArgs_.normalRewards)
    self:setExtraRewards(self.ctorArgs_.extraRewards)
end


function CatModuleWorkRewardPopup:getViewData()
    return self.viewData
end

-------------------------------------------------------------------------------
-- get/set
-------------------------------------------------------------------------------

-- normal reward
function CatModuleWorkRewardPopup:setNormalRewards(normalRewards)
    self.normalRewards_ = checktable(normalRewards)
    self:createRewardDialog(self:getNormalRewards(), self:getViewData().normalRewardLayer, __("本周奖励次数已超上限, 暂无获得奖励"))
end
function CatModuleWorkRewardPopup:getNormalRewards()
    return checktable(self.normalRewards_)
end


-- extra reward
function CatModuleWorkRewardPopup:setExtraRewards(extraRewards)
    self.extraRewards_ = checktable(extraRewards)
    self:createRewardDialog(self:getExtraRewards(), self:getViewData().extraRewardLayer, __("本次工作未获得额外奖励"))
    
end
function CatModuleWorkRewardPopup:getExtraRewards()
    return checktable(self.extraRewards_)
end

-------------------------------------------------------------------------------
-- handler
-------------------------------------------------------------------------------

function CatModuleWorkRewardPopup:onClickConfirmBtnHandler_(sender)
    PlayAudioByClickClose()
    self:CloseHandler()
end

-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------
function CatModuleWorkRewardPopup:createRewardDialog(rewardDatas, parent, tips)
    if #rewardDatas > 4 then
        local goodsTableView = ui.tableView({dir = display.SDIR_H, size = cc.size(440, 90), csizeW = 90})
        goodsTableView:setCellCreateClass(require('common.GoodNode'), {showAmount = true, scale = 0.75, callBack = function(sender)
            app.uiMgr:ShowInformationTipsBoard({targetNode = sender, iconId = checkint(sender.goodId), type = 1})
        end})
        goodsTableView:setCellUpdateHandler(function(cellIndex, goodNode)
            local data = rewardDatas[cellIndex]
            goodNode:RefreshSelf(data)
        end)
        goodsTableView:setCellInitHandler(function(goodNode)
            goodNode:alignTo(nil, ui.cc)
        end)
        parent:add(goodsTableView)
        goodsTableView:resetCellCount(#rewardDatas)
    else
        if #rewardDatas > 0 then
            local rewardNodeGroup = {}
            for _, rewardData in ipairs(rewardDatas) do
                local rewardNode = ui.goodsNode({showAmount = true, scale = 0.75, defaultCB = true, goodsId = rewardData.goodsId, num = rewardData.num})
                parent:add(rewardNode)
                table.insert(rewardNodeGroup, rewardNode)
            end
            if #rewardNodeGroup > 0 then
                ui.flowLayout(cc.sizep(parent, ui.cc), rewardNodeGroup, {type = ui.flowH, ap = ui.cc})
            end
        else
            local emptyTip = ui.label({fnt = FONT.D14, text = tips or __("暂无奖励"), w = 450, hAlign = display.TAC})
            parent:addList(emptyTip):alignTo(nil, ui.cc)
        end
    end
end

function CatModuleWorkRewardPopup.CreateView()
    local view = ui.layer({bg = RES_DICT.BG_FRAME})
    local size = view:getContentSize()
    local cpos = cc.sizep(size, ui.cc)

    -- title bar
    local titleBar = ui.title({img = RES_DICT.COM_TITLE}):updateLabel({fnt = FONT.D14, outline = "#50262b", text = __('工作回报'), reqW = 500})
    view:addList(titleBar):alignTo(nil, ui.ct, {offsetY = -40})

    -- tableView
    local frameGroup = view:addList({
        ui.title({n = RES_DICT.BG_TITLE}):updateLabel({fnt = FONT.D4, color = "#562f1a", text = __("普通奖励"), paddingW = 30, offset = cc.p(-15, 0)}),
        ui.layer({size = cc.size(440, 90)}),
        ui.title({n = RES_DICT.BG_TITLE, mt = 20}):updateLabel({fnt = FONT.D4, color = "#562f1a", text = __("额外奖励"), paddingW = 30, offset = cc.p(-15, 0)}),
        ui.layer({size = cc.size(440, 90)}),
    })
    ui.flowLayout(cc.sizep(view, ui.cc), frameGroup, {type = ui.flowV, ap = ui.cc})

    -- btnReward
    local confirmBtn = ui.button({n = RES_DICT.BTN_CONFIRM}):updateLabel({fnt = FONT.D14, text = __("确认"), reqW = 110})
    view:addList(confirmBtn):alignTo(nil, ui.cb, {offsetY = 35})

    return {
        view              = view,
        normalRewardLayer = frameGroup[2],
        extraRewardLayer  = frameGroup[4],
        confirmBtn        = confirmBtn,
    }
end


return CatModuleWorkRewardPopup
