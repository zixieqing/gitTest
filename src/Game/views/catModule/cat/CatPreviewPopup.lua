--[[
 * author : panmeng
 * descpt : 猫屋猫咪 - 自己猫咪预览
]]
local CatHouseModelFactory    = require('Game.models.CatHouseModelFactory')
local HouseCatModel           = CatHouseModelFactory.HouseCatModel
local CommonDialog            = require('common.CommonDialog')
local CatPreviewPopup = class('CatPreviewPopup', CommonDialog)

local RES_DICT = {
    BG_FRAME      = _res('ui/common/common_bg_9.png'),
    COM_TITLE     = _res('ui/common/common_bg_title_2.png'),
    IMG_LIGHT     = _res('ui/common/common_light.png'),
    ICON_BG       = _res('ui/catModule/catPreview/grow_get_ball.png'),
    IMG_TYPE_LINE = _res('ui/catModule/catPreview/grow_get_line.png'),
    IMG_TYPE_BG   = _res('ui/catModule/catPreview/grow_get_little.png'),
    IMG_NAME_BG   = _res('ui/catModule/catPreview/grow_get_name.png'),
    IMG_MAT       = _res('ui/catModule/catPreview/grow_get_mat.png'),
    IMG_GIRL      = _res('ui/catModule/catPreview/grow_get_type_sex_f.png'),
    IMG_BOY       = _res('ui/catModule/catPreview/grow_get_type_sex_m.png'),
}


function CatPreviewPopup:ctor(args)
    local initArgs      = checktable(args)
    self.catModel_      = app.catHouseMgr:getCatModel(initArgs.catUuid) or HouseCatModel.new(initArgs.catUuid)
    self.closeCallback  = initArgs.closeCallback
    self.isRetain_      = initArgs.isRetain == true
    
    -- create view
    self.viewData_ = CatPreviewPopup.CreateView(self.catModel_)
    self:addChild(self:getViewData().view)
    self:setPosition(display.center)

    -- add listener
    ui.bindClick(self:getViewData().blockLayer, handler(self, self.onClickBlockBtnHandler_), false)
    
    -- init views
    self:updateAttributeInfo()
end


function CatPreviewPopup:getViewData()
    return self.viewData_
end


function CatPreviewPopup:getCatModule()
    return self.catModel_
end


-------------------------------------------------------------------------------
-- public
-------------------------------------------------------------------------------

function CatPreviewPopup:updateAttributeInfo()
    local leftInitPos  = cc.p(-310, 170)
    local rightInitPos = cc.p(310, 120)
    for index, geneId in pairs(table.keys(self:getCatModule():getGeneMap())) do
        local isRight  = index%2 == 0
        local initPos  = isRight and rightInitPos or leftInitPos
        local offsetX  = isRight and math.random(0,50) or math.random(-50,0)
        local offsetY  = (math.ceil(index/2) - 1) * -100
        local geneCell = CatPreviewPopup.CreateGeneCell(geneId, cc.rep(initPos, offsetX, offsetY), isRight)
        self:getViewData().geneLayer:add(geneCell)
    end
end


-------------------------------------------------------------------------------
-- handler
-------------------------------------------------------------------------------

function CatPreviewPopup:onClickBlockBtnHandler_(sender)
    PlayAudioByClickClose()

    if self.closeCallback then
        self.closeCallback()
    end
    if not self.isRetain_ then
        self:runAction(cc.RemoveSelf:create())
    end
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function CatPreviewPopup.CreateView(catModule)
    local catData = checktable(catInfo)
    local view    = ui.layer()

    -- [blackLayer| blockLayer]
    local backGroundGroup = view:addList({
        ui.layer({color = cc.c4b(0,0,0,150)}),
        ui.layer({color = cc.r4b(0), enable = true}),
        ui.layer(),
        ui.layer(),
    })

    local centerLayer = backGroundGroup[3]
    local catImgGroup = centerLayer:addList({
        ui.image({img = RES_DICT.IMG_LIGHT, mt = 30}),
        ui.image({img = RES_DICT.IMG_MAT, mt = 180}),
        CatHouseUtils.GetCatSpineNode({catUuid = catModule:getUuid()}),
    })
    ui.flowLayout(cc.rep(cc.sizep(view, ui.cc), 0, 30), catImgGroup, {type = ui.flowC, ap = ui.cc})

    local nameTitle = ui.title({n = RES_DICT.IMG_NAME_BG}):updateLabel({fnt = FONT.D11, color = "#fef2cf", text = catModule:getName(), offset = cc.p(18, 0), reqW = 180})
    centerLayer:addList(nameTitle):alignTo(nil, ui.cc, {offsetY = -150})

    local sexIconPath = catModule:getSex() == CatHouseUtils.CAT_SEX_TYPE.BOY and "grow_get_type_sex_m" or "grow_get_type_sex_f"
    local sexIconNode = ui.image({img = _res(string.format('ui/catModule/catPreview/%s.png', sexIconPath))})
    nameTitle:addList(sexIconNode):alignTo(nil, ui.lc, {offsetX = -10, offsetY = 5})

    return {
        view         = view,
        blackBgLayer = backGroundGroup[1],
        blockLayer   = backGroundGroup[2],
        centerLayer  = backGroundGroup[3],
        geneLayer    = backGroundGroup[4],
    }
end


function CatPreviewPopup.CreateGeneCell(geneId, pos, isRight)
    local view  = ui.layer({size = cc.size(270, 50), color = cc.r4b(0), p = cc.rep(display.center, checkint(pos.x), checkint(pos.y)), ap = ui.cc})
    local bg    = ui.image({img = RES_DICT.IMG_TYPE_BG, scaleX = 1})
    view:addList(bg):alignTo(nil, ui.cc)

    local lineBg = ui.image({img = RES_DICT.IMG_TYPE_LINE, scaleX = isRight and -1 or 1})
    view:addList(lineBg):alignTo(nil, ui.cb, {offsetY = -50})

    local iconPath = CatHouseUtils.GetCatGeneIconPathByGeneId(geneId)
    local iconGroup = bg:addList({
        ui.image({img = RES_DICT.ICON_BG}),
        ui.image({img = iconPath, ml = 3, mt = -3}),
    })
    ui.flowLayout(cc.rep(cc.sizep(bg, ui.rc), -50, 0), iconGroup, {type = ui.flowC, ap = ui.lc})

    local geneConf = CONF.CAT_HOUSE.CAT_GENE:GetValue(geneId)
    local geneName = ui.label({fnt = FONT.D4, color = "#894b1c", text = tostring(geneConf.name), reqW = 150})
    view:addList(geneName):alignTo(nil, ui.cc, {offsetX = isRight and -7 or 7})
    bg:setScaleX(isRight and 1 or -1)

    return view
end


return CatPreviewPopup
