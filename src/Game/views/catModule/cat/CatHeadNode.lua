--[[
* author : panmeng
* descpt : 猫咪节点
]]
local CatHeadNode = class('CatHeadNode', function()
   return ui.layer({name = 'Game.views.catModule.cat.CatHeadNode', enableEvent = true, color = cc.r4b(0), enable = true})
end)

local RES_DICT = {
   CAT_FRAME         = _res('ui/catModule/headNode/grow_birth_list_bg_cat_front.png'),
   CAT_BG            = _res('ui/catModule/headNode/grow_birth_list_bg_cat_back_small.png'),
   SELECTED_IMG      = _res('ui/catModule/headNode/grow_book_details_btn_cat_light.png'),
   REBIRTH_ICON_DEAD = _res('ui/catModule/catList/grow_main_list_ico_egg_dead.png'),
   REBIRTH_ICON_NORM = _res('ui/catModule/catList/grow_main_list_ico_egg.png'),
   REBIRTH_ICON_SPE  = _res('ui/catModule/catList/grow_main_list_ico_year_chane.png'),
   REBIRTH_BG_DEAD   = _res('ui/catModule/catList/grow_main_list_bg_year_dead.png'),
   REBIRTH_BG_NORM   = _res('ui/catModule/catList/grow_main_list_bg_year_gray.png'),
   REBIRTH_BG_SPE    = _res('ui/catModule/catList/grow_main_list_bg_year_light.png'),
   GIRL_ICON         = _res('ui/catModule/catList/grow_main_list_ico_f.png'),
   BOY_ICON          = _res('ui/catModule/catList/grow_main_list_ico_m.png'),
   PROPERTY_ICON     = _res('ui/catHouse/chooseCat/cat_ico_attribute.png'),
   EQUIP_FRAME       = _res('ui/catHouse/chooseCat/cat_main_list_bg.png'),
}


function CatHeadNode:ctor(args)
   local initArgs = checktable(args)
   self.showEquippedIcon_ = initArgs.showEquippedIcon == true or false
   local cellSize = initArgs.size or cc.size(180, 180)
   self:setContentSize(cellSize)

   -- create view
   self.viewData_ = CatHeadNode.CreateView()
   self:addList(self:getViewData().view):alignTo(nil, ui.cc)
end


function CatHeadNode:getViewData()
   return self.viewData_
end


-- custom catData
function CatHeadNode:getCatData(catData)
   return self.catData_
end
function CatHeadNode:setCatData(catData)
   self.catData_ = checktable(catData)
   self:updatePageViewByCatData_(self.catData_)
end


-- myself catUuid
function CatHeadNode:getCatUuid()
   return self.catUuid
end
function CatHeadNode:setCatUuid(catUuid)
   self.catUuid   = catUuid
   self.catModel_ = app.catHouseMgr:getCatModel(self:getCatUuid())
   self:updatePageViewByCatModel_(self.catModel_)
end


function CatHeadNode:setLevelIconVisible(visible)
   self:getViewData().levelTitleBG:setVisible(visible)
end


function CatHeadNode:updateSelectedImgVisible(visible)
   self:getViewData().selectedImg:setVisible(visible)
end

function CatHeadNode:isShowEquippedIcon()
   return self.showEquippedIcon_
end

function CatHeadNode:updateEquippedState( visible )
   self:getViewData().equippedIcon:setVisible(false)
   self:getViewData().propertyIcon:setVisible(false)
   self.showEquippedIcon_ = visible == true or false
end
-------------------------------------------------------------------------------
-- update page
-------------------------------------------------------------------------------

function CatHeadNode:updatePageViewByCatModel_(catModel)
   local catViewData = self:getViewData()
   catViewData.catLayer:removeAllChildren()

   local catSpineNode = CatHouseUtils.GetCatSpineNode({catUuid = self:getCatUuid(), scale = 0.5})
   catViewData.catLayer:addList(catSpineNode):alignTo(nil, ui.cc)

   -- isAlive
   catViewData.levelTitleBG:setEnabled(catModel:isAlive())
   catViewData.levelIcon:setEnabled(catModel:isAlive())

   -- isRebirth
   catViewData.levelTitleBG:setChecked(catModel:isRebirth())
   catViewData.rebirthIcon:setVisible(catModel:isRebirth())

   -- generation
   catViewData.levelTitleText:setString(catModel:getGeneration())

   -- sex
   catViewData.sexIcon:setChecked(catModel:getSex() == CatHouseUtils.CAT_SEX_TYPE.BOY)

   -- IsCatEquipped
   if self:isShowEquippedIcon() then
      catViewData.equippedIcon:setVisible(CatHouseUtils.IsCatEquipped(catModel:getUuid()))
      catViewData.propertyIcon:setVisible(CatHouseUtils.CalculateBuffTotalAddition(catModel:getGeneMap()) > 0)
   end
   -- name
   catViewData.catName:setString(catModel:getName())
end


function CatHeadNode:updatePageViewByCatData_(catData)
   local catViewData = self:getViewData()
   catViewData.catLayer:removeAllChildren()

   local catSpineNode = CatHouseUtils.GetCatSpineNode({catData = catData, scale = 0.5})
   catViewData.catLayer:addList(catSpineNode):alignTo(nil, ui.cc)

   -- isAlive
   catViewData.levelTitleBG:setEnabled(true)
   catViewData.levelIcon:setEnabled(true)

   -- isRebirth
   local isRebirth = checkint(catData.rebirth) == 1
   catViewData.levelTitleBG:setChecked(isRebirth)
   catViewData.rebirthIcon:setVisible(isRebirth)

   -- generation
   local generation = checkint(catData.generation)
   catViewData.levelTitleText:setString(tostring(generation))

   -- sex
   local catSex = checkint(catData.sex)
   catViewData.sexIcon:setChecked(catSex == CatHouseUtils.CAT_SEX_TYPE.BOY)
   
   --isEquipped
   if self:isShowEquippedIcon() then
      catViewData.equippedIcon:setVisible(CatHouseUtils.IsCatEquipped(self:getCatUuid()))
   end

   -- name
   local catName = tostring(catData.name)
   catViewData.catName:setString(catName)
end


-------------------------------------------------------------------------------
-- view define
-------------------------------------------------------------------------------

function CatHeadNode.CreateView()
   local CELL_SIZE = cc.size(195, 210)
   local view     = ui.layer({size = CELL_SIZE, color = cc.r4b(0), enable = true})

   local catFrameGroup = view:addList({
      ui.image({img = RES_DICT.CAT_BG, mt = -10}),
      ui.layer({size = CELL_SIZE}),
      ui.layer({size = CELL_SIZE}),
      ui.image({img = RES_DICT.CAT_FRAME, mt = 5}),
      ui.layer({size = cc.resize(CELL_SIZE, -10, -10)}),
      ui.image({img = RES_DICT.SELECTED_IMG, scale9 = true, size = CELL_SIZE}),
   })
   ui.flowLayout(cc.sizep(view, ui.cc), catFrameGroup, {type = ui.flowC, ap = ui.cc})
   
   -- sex Icon
   local sexIcon = ui.tButton({n = RES_DICT.GIRL_ICON, s = RES_DICT.BOY_ICON, scale = 0.8})
   sexIcon:setTouchEnabled(false)
   catFrameGroup[3]:addList(sexIcon):alignTo(nil, ui.rb, {offsetX = -10, offsetY = 55})

   local catInfoLayer   = catFrameGroup[5]

   -- property Icon
   local propertyIcon = ui.image({img = RES_DICT.PROPERTY_ICON})
   catFrameGroup[3]:addList(propertyIcon):alignTo(nil, ui.lb, {offsetX = 15, offsetY = 55})
   propertyIcon:setVisible(false)
   -- equip icon
   local equippedIcon = ui.image({img = RES_DICT.EQUIP_FRAME})
   catFrameGroup[3]:addList(equippedIcon):alignTo(nil, ui.cc, {offsetX = 0, offsetY = 0})
   equippedIcon:setVisible(false)
   -- level
   local levelTitleBG   = ui.tButton({n = RES_DICT.REBIRTH_BG_NORM, d = RES_DICT.REBIRTH_BG_DEAD, s= RES_DICT.REBIRTH_BG_SPE})
   local levelTitleText = ui.label({fnt = FONT.D18, text = "--"})
   catInfoLayer:addList(levelTitleBG):alignTo(nil, ui.lt, {offsetY = -4})
   levelTitleBG:addList(levelTitleText):alignTo(nil, ui.cc, {offsetX = 13})
   
   -- level icon
   local levelIcon = ui.button({n = RES_DICT.REBIRTH_ICON_NORM, d = RES_DICT.REBIRTH_ICON_DEAD})
   levelTitleBG:addList(levelIcon):alignTo(nil, ui.lc, {offsetX = 10})

   -- rebirth icon
   local rebirthIcon = ui.image({img = RES_DICT.REBIRTH_ICON_SPE})
   levelTitleBG:addList(rebirthIcon):alignTo(nil, ui.lc, {offsetX = 0})

   -- catName
   local catName = ui.label({fnt = FONT.D18, text = "--", color = "#532922"})
   catInfoLayer:addList(catName):alignTo(nil, ui.cb, {offsetY = 17})

   -- selected img
   local selectedImg = catFrameGroup[6]
   selectedImg:setVisible(false)

   -- clipNode
   local catLayer    = catFrameGroup[2]
   local layerSize   = cc.resize(CELL_SIZE, -20, -20)
   local catClipNode = ui.clipNode({size = layerSize, at = 1, stencil = {img = RES_DICT.CAT_FRAME, scale9 = true, size = layerSize, ap = ui.lb}, ap = ui.lb})
   catLayer:addList(catClipNode):alignTo(nil, ui.lb, {offsetY = 10, offsetX = 10})

   return {
      catLayer       = catClipNode,
      levelTitleBG   = levelTitleBG,
      levelTitleText = levelTitleText,
      levelIcon      = levelIcon,
      rebirthIcon    = rebirthIcon,
      sexIcon        = sexIcon,
      catName        = catName,
      selectedImg    = selectedImg,
      propertyIcon   = propertyIcon,
      equippedIcon   = equippedIcon,
      view           = view,
   }
end


return CatHeadNode