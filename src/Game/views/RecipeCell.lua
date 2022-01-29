local RecipeCell = class('Game.views.RecipeCell',function ()
    local pageviewcell = display.newLayer()
    pageviewcell.name = 'Game.views.RecipeCell'
    pageviewcell:enableNodeEvents()
    return pageviewcell
end)


function RecipeCell:ctor(...)
    local arg = {...}
    local size = cc.size(184 , 210)
    self:setContentSize(size)
    self:setAnchorPoint(display.CENTER)
    

    local fragmentImg = display.newImageView(_res('ui/home/lobby/cooking/cooking_foods_bg.png'),0,0,{as = false})
    fragmentImg:setPosition(cc.p(size.width * 0.5,size.height * 0.5))
    self:addChild(fragmentImg)
    self.fragmentImg = fragmentImg

    local selectImg = display.newImageView(_res('ui/home/lobby/cooking/gut_task_btn_select.png'),0,0,{as = false})
    selectImg:setPosition(cc.p(size.width * 0.5,size.height * 0.5))
    self:addChild(selectImg,10)
    self.selectImg = selectImg
    self.selectImg:setVisible(false)


    local recipeImg = display.newImageView(CommonUtils.GetGoodsIconPathById(150060),0,0,{as = false})
    recipeImg:setPosition(cc.p(size.width * 0.5,size.height * 0.5 + 20))
    self:addChild(recipeImg)
    self.recipeImg = recipeImg

    local nameLabel = display.newLabel( size.width * 0.5, 56,{
        ap = cc.p(0.5,1), fontSize = fontWithColor('18').fontSize , color = '5c5c5c', w = 170})

    nameLabel:setAlignment(cc.TEXT_ALIGNMENT_CENTER)
    self:addChild(nameLabel)
    self.nameLabel = nameLabel


    local qualityFrame = display.newImageView(_res('ui/home/kitchen/cooking_foods_grade_bg.png'),0,0)
    qualityFrame:setAnchorPoint(cc.p(0,1))
    qualityFrame:setPosition(cc.p(10,size.height - 8))
    self:addChild(qualityFrame)


    local qualityImg= display.newImageView(_res('ui/home/kitchen/cooking_grade_ico_5.png'),0,0)
    qualityImg:setAnchorPoint(cc.p(0,1))
    qualityImg:setPosition(cc.p(4,size.height - 4))
    self:addChild(qualityImg)
    self.qualityImg = qualityImg


    self.hotspotBtn = display.newLayer(0, 0, {color = cc.r4b(0), size = self:getContentSize(), enable = true})
    self:addChild(self.hotspotBtn)


    local likePos  = cc.p(size.width - 35, size.height - 30)
    self.likeImg   = display.newImageView(_res('ui/home/kitchen/kitchen_btn_add_favourite_selected.png'), likePos.x, likePos.y)
    self.unlikeImg = display.newImageView(_res('ui/home/kitchen/kitchen_btn_add_favourite_default.png'), likePos.x, likePos.y)
    self:addChild(self.likeImg)
    self:addChild(self.unlikeImg)

    self.likeBtn = display.newLayer(likePos.x, likePos.y, {color = cc.r4b(0), size = self.likeImg:getContentSize(), ap = display.CENTER, enable = true})
    self:addChild(self.likeBtn)
    self:setLike(false)
end

function RecipeCell:isLike()
    return self.isLikeRecipe == true
end
function RecipeCell:setLike(isLike)
    self.isLikeRecipe = isLike == true
    self.likeImg:setVisible(self.isLikeRecipe)
    self.unlikeImg:setVisible(not self.isLikeRecipe)
end



return RecipeCell
