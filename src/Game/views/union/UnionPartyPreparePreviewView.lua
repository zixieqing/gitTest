--[[
 * descpt : 工会派对筹备 preview 界面
]]
local VIEW_SIZE = display.size
local UnionPartyPreparePreviewView = class('UnionPartyPreparePreviewView', function ()
	local node = CLayout:create(display.size)
	node.name = 'Game.views.union.UnionPartyPreparePreviewView'
	node:enableNodeEvents()
	return node
end)

local CreateView = nil
local CreateCell = nil

local RES_DIR = {
    BG              = _res("ui/union/party/prepare/guild_party_bg_trailer.png"),
    LIST_BG         = _res("ui/union/party/prepare/guild_party_bg_black.png"),
    ORDER_BG        = _res("ui/home/raidMain/raid_mode_bg_active.png"),
}

function UnionPartyPreparePreviewView:ctor( ... )
    self.args = unpack({...})
    self:initialUI()
end

function UnionPartyPreparePreviewView:initialUI()
    xTry(function ( )
        self.viewData_ = CreateView()
        self:addChild(self.viewData_.view)
	end, __G__TRACKBACK__)
end

CreateView = function ()
    local view = display.newLayer()
    local size = view:getContentSize()
    
    -- role
    local roleLayer = display.newLayer()
	local roleNode = CommonUtils.GetRoleNodeById('role_45', 1)
    roleNode:setAnchorPoint(display.LEFT_TOP)
    roleNode:setPosition(cc.p(display.SAFE_L + roleNode:getContentSize().width - 152, display.height - 50))
    roleNode:setScaleX(-1)
    roleLayer:addChild(roleNode)
    view:addChild(roleLayer)

    -- list
    local bg = display.newLayer(display.SAFE_R - 10, display.cy - 50, {ap = display.RIGHT_CENTER, bg = RES_DIR.BG})
    local bgSize = bg:getContentSize()
    view:addChild(bg)
    
    local listTitle = display.newLabel(bgSize.width / 2, bgSize.height - 15, fontWithColor(16, {ap = display.CENTER_TOP, text = __('下次派对需求菜品预告')}))
    bg:addChild(listTitle)

    local listBgSize = cc.size(bgSize.width - 30, bgSize.height - 70)
    local listBgLayer = display.newLayer(bgSize.width / 2, bgSize.height / 2 - 10, {size = listBgSize, ap = display.CENTER})
    local listBg = display.newImageView(RES_DIR.LIST_BG, listBgSize.width / 2, listBgSize.height / 2, {size = listBgSize, scale9 = true, ap = display.CENTER})
    bg:addChild(listBgLayer)
    listBgLayer:addChild(listBg)
    
    local gridViewCellSize = cc.size(184, 208)
    local gridView = CGridView:create(listBgSize)
    gridView:setPosition(cc.p(listBgSize.width / 2, listBgSize.height / 2))
    gridView:setSizeOfCell(gridViewCellSize)
    gridView:setAnchorPoint(display.CENTER)
    gridView:setColumns(5)
    listBgLayer:addChild(gridView)

    return {
        view          = view,
        gridView      = gridView,
    }
end

CreateCell_ = function ()
    local cell = CGridViewCell:new()
    local cellSize = cc.size(187, 210)
    cell:setContentSize(cellSize)

    local orderBg = display.newImageView(RES_DIR.ORDER_BG, cellSize.width / 2, cellSize.height / 2, {ap = display.CENTER})
    local orderBgSize = orderBg:getContentSize()
    orderBg:setScale(0.58)
    cell:addChild(orderBg)
    
    local gradeImg = display.newImageView(_res('ui/home/kitchen/cooking_grade_ico_5.png'), 20, cellSize.height - 10, {ap = display.LEFT_TOP})
    cell:addChild(gradeImg)

    local goodNode = require('common.GoodNode').new({id = 150061, showAmount = false, callBack = function (sender)
        AppFacade.GetInstance():GetManager("UIManager"):ShowInformationTipsBoard({targetNode = sender, iconId = sender.goodId, type = 1})
    end})
    goodNode.fragmentImg:setVisible(false)
    goodNode.bg:setVisible(false)
    display.commonUIParams(goodNode,{po = cc.p(cellSize.width / 2, cellSize.height / 2 + 5), ap = display.CENTER})
    goodNode:setScale(1.5)
    cell:addChild(goodNode)
    
    local goodName = display.newLabel(cellSize.width / 2, 42, fontWithColor(16, {ap = display.CENTER, text = goodNode.goodData.name}))
    cell:addChild(goodName)

    cell.viewData = {
        gradeImg = gradeImg,
        goodNode = goodNode,
        goodName = goodName,
    }
    return cell
end

function UnionPartyPreparePreviewView:CreateCell()
    return CreateCell_()
end

function UnionPartyPreparePreviewView:getViewData()
	return self.viewData_
end

return UnionPartyPreparePreviewView