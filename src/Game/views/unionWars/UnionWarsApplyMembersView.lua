--[[

--]]
local UnionWarsApplyMembersView = class('UnionWarsApplyMembersView', function ()
	local clb = CLayout:create(cc.size(display.width, display.height))
    clb.name = 'unionWars.UnionWarsApplyMembersView'
    clb:enableNodeEvents()
    return clb
end)

------------ import ------------
------------ import ------------

------------ define ------------
local CreateView = nil
local CreateCell_ = nil

local RES_DICT = {
    COMMON_BTN_CHECK_SELECTED       = _res('ui/common/common_btn_check_selected.png'),
    COMMON_BTN_CHECK_DEFAULT        = _res('ui/common/common_btn_check_default.png'),
    COMMON_BTN_ORANGE               = _res('ui/common/common_btn_orange.png'),
    COMMON_BTN_TIPS                 = _res('ui/common/common_btn_tips.png'),
    COMMON_BTN_WHITE_DEFAULT        = _res('ui/common/common_btn_white_default.png'),
    GVG_PICK_BG                     = _res('ui/union/wars/applyMembers/gvg_pick_bg.png'),
    GVG_PICK_BG_DEFAULT             = _res('ui/union/wars/applyMembers/gvg_pick_bg_default.png'),
    GVG_PICK_BG_SELECT              = _res('ui/union/wars/applyMembers/gvg_pick_bg_select.png'),
    GVG_PICK_BG_DOWN                = _res('ui/union/wars/applyMembers/gvg_pick_bg_down.png'),
    GVG_PICK_BG_RANKS               = _res('ui/union/wars/applyMembers/gvg_pick_bg_ranks.png'),
    GVG_PICK_BTN_SORT               = _res('ui/union/wars/applyMembers/gvg_pick_btn_sort.png'),
    GVG_PICK_TAB_1                  = _res('ui/union/wars/applyMembers/gvg_pick_tab_1.png'),
    GVG_PICK_TAB_2                  = _res('ui/union/wars/applyMembers/gvg_pick_tab_2.png'),
}
------------ define ------------

function UnionWarsApplyMembersView:ctor(...)
    self.args = unpack({...}) or {}
    self:InitialUI()
end

--[[
override
initui
--]]
function UnionWarsApplyMembersView:InitialUI()

    xTry(function ( )
        self.viewData_ = CreateView( )
        self:addChild(self:GetViewData().view)
    end, __G__TRACKBACK__)

    self:RefreshUI(self.datas)
end
---------------------------------------------------
-- view control begin --
---------------------------------------------------

--[[
刷新界面
@params data list 数据
--]]
function UnionWarsApplyMembersView:RefreshUI(data)
    
end

--==============================--
--desc: 更新列表
--@params viewData table 视图数据
--@params datas    table 列表数据
--@return
--==============================--
function UnionWarsApplyMembersView:UpdateTableList(viewData, datas)
    local tableList = viewData.tableList
    tableList:setCountOfCell(#datas)
    tableList:reloadData()
end

function UnionWarsApplyMembersView:UpdateSelectMemberNum(viewData, selectNum, totalNum)
    display.commonLabelParams(viewData.selectMemberNum, {text = string.format('%d/%d', checkint(selectNum), checkint(totalNum))})
end

function UnionWarsApplyMembersView:UpdateCell(viewData, data, isSelect)
    local battlePointLabel = viewData.battlePointLabel
    local playerCards = data.playerCards or {}
    display.commonLabelParams(battlePointLabel, {text = string.format(__("队伍总灵力 %s"), tostring(data.battlePoint))})

    local head = viewData.head
    head:RefreshUI({
        showLevel       = true,
        defaultCallback = true,
        playerId        = data.playerId,
        playerLevel     = data.playerLevel,
        avatar          = data.playerAvatar,
        avatarFrame     = data.playerAvatarFrame
    })

    local nameLabel = viewData.nameLabel
    display.commonLabelParams(nameLabel, {text = tostring(data.playerName)})

    local cardLineupNode = viewData.cardLineupNode
    cardLineupNode:RefreshUI({cardDatas = playerCards})

    self:UpdateCellSelectState(viewData, isSelect)
end

function UnionWarsApplyMembersView:UpdateCellSelectState(cellViewData, isSelect)
    self:UpdateCellBg(cellViewData, isSelect)
    cellViewData.selectMemberBtn:setChecked(isSelect)
end

function UnionWarsApplyMembersView:UpdateSelectState(cellViewData, isSelect, selectNum, totalNum)
    self:UpdateCellSelectState(cellViewData, isSelect)
    self:UpdateSelectMemberNum(self:GetViewData(), selectNum, totalNum)
end

function UnionWarsApplyMembersView:UpdateCellBg(viewData, isSelect)
    local cellBg = viewData.cellBg
    cellBg:setTexture(isSelect and RES_DICT.GVG_PICK_BG_SELECT or RES_DICT.GVG_PICK_BG_DEFAULT)
end

---------------------------------------------------
-- view control end --
---------------------------------------------------

CreateView = function()
    local view = display.newLayer()

    -- block layer
    local blockLayer = display.newLayer(0, 0, {color = cc.c4b(0,0,0,130), enable = true})
    view:addChild(blockLayer)

    -------------------layer start--------------------
    local layerSize = cc.size(887, 715)

    local transparentLayer = display.newLayer(display.cx, display.cy,
    {
        ap = display.CENTER,
        size = layerSize,
        color = cc.c4b(0,0,0,0),
        enable = true,
    })
    view:addChild(transparentLayer)

    local layer = display.newLayer(display.cx, display.cy,
    {
        ap = display.CENTER,
        size = layerSize,
        enable = true,
    })
    view:addChild(layer)

    local bg = display.newImageView(RES_DICT.GVG_PICK_BG, 444, 357,
    {
        ap = display.CENTER,
        scale9 = true, size = cc.size(887, 713),
    })
    layer:addChild(bg)

    local titleLabel = display.newLabel(447, 681,
    {
        text = __('防守阵容预览'),
        ap = display.CENTER,
        fontSize = 26,
        color = '#5b3c25',
        font = TTF_GAME_FONT, ttf = true,
    })
    layer:addChild(titleLabel)

    local ruleImg = display.newImageView(RES_DICT.COMMON_BTN_TIPS, 553, 685,
    {
        ap = display.CENTER,
    })
    layer:addChild(ruleImg)

    local tab1 = display.newNSprite(RES_DICT.GVG_PICK_TAB_1, 370, 599,
    {
        ap = display.CENTER_BOTTOM,
    })
    layer:addChild(tab1)

    local teamInfoLabel = display.newLabel(40, 629,
        fontWithColor(18, {text = __('成员队伍信息'), ap = display.LEFT_CENTER}))
    layer:addChild(teamInfoLabel)

    local sortBtn = display.newButton(layerSize.width - 190, 629,
    {
        ap = display.RIGHT_CENTER,
        n = RES_DICT.GVG_PICK_BTN_SORT,
        scale9 = true, size = cc.size(191, 43),
        enable = true,
    })
    display.commonLabelParams(sortBtn, fontWithColor(7, {text = __('灵力排序'), fontSize = 22, color = '#cd0101'}))
    layer:addChild(sortBtn)

    local tab2 = display.newButton(798, 599,
    {
        ap = display.CENTER_BOTTOM,
        n = RES_DICT.GVG_PICK_TAB_2,
        scale9 = true, size = cc.size(140, 63),
        enable = false,
    })
    display.commonLabelParams(tab2, fontWithColor(18, {text = __('状态')}))
    layer:addChild(tab2)

    local listBg = display.newNSprite(RES_DICT.GVG_PICK_BG_DOWN, 444, 344,
    {
        ap = display.CENTER,
    })
    layer:addChild(listBg)

    local tableList = CTableView:create(cc.size(860, 504))
    tableList:setPosition(cc.p(444, 344))
    tableList:setAnchorPoint(display.CENTER)
    tableList:setSizeOfCell(cc.size(857, 157))
    tableList:setDirection(eScrollViewDirectionVertical)
    layer:addChild(tableList)
   
    local selectMemberNunLabel = display.newLabel(42, 44,
        fontWithColor(11, {
            text = __('选择防御成员'), ap = display.LEFT_CENTER, color = '#97241f'
        })
    )
    layer:addChild(selectMemberNunLabel)

    local selectMemberNum = display.newLabel(selectMemberNunLabel:getPositionX() + display.getLabelContentSize(selectMemberNunLabel).width + 5, 43,
        fontWithColor(16, {
            ap = display.LEFT_CENTER
        })
    )
    layer:addChild(selectMemberNum)

    local oneKeySelectMemberBtn = display.newButton(647, 44,
    {
        ap = display.CENTER,
        n = RES_DICT.COMMON_BTN_WHITE_DEFAULT,
        scale9 = true, size = cc.size(122, 62),
        enable = true,
    })
    display.commonLabelParams(oneKeySelectMemberBtn, fontWithColor(14, {text = __('一键选人')}))
    layer:addChild(oneKeySelectMemberBtn)

    local submitBtn = display.newButton(796, 44,
    {
        ap = display.CENTER,
        n = RES_DICT.COMMON_BTN_ORANGE,
        scale9 = true, size = cc.size(123, 62),
        enable = true,
    })
    display.commonLabelParams(submitBtn, fontWithColor(14, {text = __('提交报名')}))
    layer:addChild(submitBtn)

    --------------------layer end---------------------
    return {
        view                    = view,
        blockLayer              = blockLayer,
        bg                      = bg,
        titleLabel              = titleLabel,
        ruleImg                 = ruleImg,
        tab1                    = tab1,
        teamInfoLabel           = teamInfoLabel,
        sortBtn                 = sortBtn,
        tab2                    = tab2,
        listBg                  = listBg,
        tableList               = tableList,
        selectMemberNunLabel    = selectMemberNunLabel,
        selectMemberNum         = selectMemberNum,
        oneKeySelectMemberBtn   = oneKeySelectMemberBtn,
        submitBtn               = submitBtn,
    }

end

CreateCell_ = function (size)
    local cell = CTableViewCell:new()
    cell:setContentSize(size)

    --------------------cell start--------------------
    local cellBg = display.newNSprite(RES_DICT.GVG_PICK_BG_DEFAULT, 430, 80,
    {
        ap = display.CENTER,
    })
    cell:addChild(cellBg)

    local memberInfoBg = display.newNSprite(RES_DICT.GVG_PICK_BG_RANKS, 10, 78,
    {
        ap = display.LEFT_CENTER,
    })
    cell:addChild(memberInfoBg)

    local battlePointLabel = display.newLabel(27, 121,
        fontWithColor(16, {
            ap = display.LEFT_CENTER, color = '#97241f'
        })
    )
    cell:addChild(battlePointLabel)

    local head = require('common.PlayerHeadNode').new({
        enable = true, showLevel = true
    })
    head:setScale(0.58)
    display.commonUIParams(head, {po = cc.p(25, 57), ap = display.LEFT_CENTER})
    cell:addChild(head)

    local nameLabel = display.newLabel(120, 60,
    {
        ap = display.LEFT_CENTER,
        fontSize = 22,
        color = '#a87543',
        w = 160
    })
    cell:addChild(nameLabel)

    local cardLineupNode = require('common.CommonCardLineupNode').new({disabledSelfData = true, cardNodeScale = 0.44, viewSize = cc.size(420, 80)})
    display.commonUIParams(cardLineupNode, {po = cc.p(287, 57), ap = display.LEFT_CENTER})
    cell:addChild(cardLineupNode)

    ----------------selectMemberBtn start-----------------
    local selectTipLabel = display.newLabel(786, size.height - 42, fontWithColor(16, {ap = display.CENTER, text = __('入选')}))
    cell:addChild(selectTipLabel)

    local selectMemberBtn = display.newCheckBox(786, 72,
    {
        ap = display.CENTER, n = RES_DICT.COMMON_BTN_CHECK_DEFAULT, s = RES_DICT.COMMON_BTN_CHECK_SELECTED
    })
    cell:addChild(selectMemberBtn)

    -----------------selectMemberBtn end------------------
    ---------------------cell end---------------------

    cell.viewData = {
        cellBg                  = cellBg,
        memberInfoBg            = memberInfoBg,
        battlePointLabel        = battlePointLabel,
        head                    = head,
        nameLabel               = nameLabel,
        cardLineupNode          = cardLineupNode,
        selectMemberBtn         = selectMemberBtn,
    }
    return cell
end


function UnionWarsApplyMembersView:CreateCell(size)
    return CreateCell_(size)
end

---------------------------------------------------
-- get set begin --
---------------------------------------------------

function UnionWarsApplyMembersView:GetViewData()
    return self.viewData_
end

---------------------------------------------------
-- get set end --
---------------------------------------------------

return UnionWarsApplyMembersView
