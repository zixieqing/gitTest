---
--- Created by xingweihao.
--- DateTime: 23/08/2017 7:59 PM
---
---@type TastingTourManager
local tastingTourMgr = AppFacade.GetInstance():GetManager("TastingTourManager")
local GameScene = require( 'Frame.GameScene' )
---@class TastingTourChooseRecipeStyleView :Node
local TastingTourChooseRecipeStyleView = class('home.TastingTourChooseRecipeStyleView',GameScene)
local RemindIcon     = require('common.RemindIcon')
local BUTTON_CLICK = {
    BACK_BTN = 1101,
    REWARD_BTN = RemindTag.TASTINGTOUR_ZONE_REWARD,
    TIP_BUTTON = 1103,

}
function TastingTourChooseRecipeStyleView:ctor(param)
    param = param or {}
    self.pageData = param.activity or {}
    self.currentPage =1
    self.showRemindIcon = 0 -- 是否显示小红点
    self:initUI()
end

function TastingTourChooseRecipeStyleView:initUI()
    -- 背景的layout
    local bgLayout =  display.newLayer(display.cx , display.cy ,{ ap = display.CENTER })
    self:addChild(bgLayout)

    -- back button
    local backBtn = display.newButton(0, 0, {n = _res("ui/common/common_btn_back")})
    backBtn:setPosition(cc.p(display.SAFE_L + backBtn:getContentSize().width * 0.5 + 30, display.height - 53))
    bgLayout:addChild(backBtn, 5)
    backBtn:setTag(BUTTON_CLICK.BACK_BTN)

    local swallowLayer = display.newLayer(display.cx , display.cy ,
          {ap = display.CENTER_TOP , color  = cc.c4b(0,0,0,0) , enable= true})
    bgLayout:addChild(swallowLayer)


    local bgImage = display.newImageView(_res("ui/tastingTour/stage/fish_travel_bg_choice"),
    display.cx, display.cy )
    bgLayout:addChild(bgImage)


    local topImage  = display.newImageView(_res("ui/tastingTour/stage/fish_travel_bg_up"))
    local topImageSize = topImage:getContentSize()
    topImage:setPosition(cc.p(topImageSize.width/2 , topImageSize.height/2 ))

    local toplayout = display.newLayer(display.width/2 , display.height, {ap = display.CENTER_TOP ,size = topImageSize })
    toplayout:addChild(topImage)
    bgLayout:addChild(toplayout)

    -- 进度条
    local progressBarOne = CProgressBar:create(_res("ui/union/hunt/guild_hunt_bg_loading_blood_l"))
    progressBarOne:setBackgroundImage(_res('ui/union/hunt/guild_hunt_bg_blood_l.png'))
    progressBarOne:setDirection(eProgressBarDirectionLeftToRight)
    progressBarOne:setAnchorPoint(cc.p(0.5, 0.5))
    progressBarOne:setPosition(cc.p(topImageSize.width / 2 , topImageSize.height/2 + 10))
    toplayout:addChild(progressBarOne)
    progressBarOne:setMaxValue(100)
    progressBarOne:setValue(0)



    local progressBarOneSize  = progressBarOne:getContentSize()
    -- 星星的图片
    local starImage  = display.newImageView( _res('ui/tastingTour/stage/fish_travel_ico_star'),
                                             0 , progressBarOneSize.height/2,{ap = display.CENTER })
    progressBarOne:addChild(starImage,10)

    -- 进度条的label
    local prograssLabel = cc.Label:createWithBMFont('font/small/common_text_num.fnt', '')
    prograssLabel:setPosition(progressBarOneSize.width/2 ,progressBarOneSize.height/2)
    progressBarOne:addChild(prograssLabel,10)
    prograssLabel:setString("")


    -- 确定星级奖励按钮的位置
    local posX  =   (topImageSize.width/2 + display.SAFE_R - display.width/2 - 70)

    local rewardStarBtn  = display.newButton(posX,45,
                                       {n = _res('ui/common/common_btn_orange'), scale9 = true , ap = display.RIGHT_CENTER }  )
    toplayout:addChild(rewardStarBtn)
    display.commonLabelParams(rewardStarBtn, fontWithColor('14',{text = __('星级奖励') , paddingW = 20 }))
    rewardStarBtn:setTag(BUTTON_CLICK.REWARD_BTN)
    local rewardStarBtnSize = rewardStarBtn:getContentSize()
    RemindIcon.addRemindIcon({parent = rewardStarBtn, tag =RemindTag.TASTINGTOUR_ZONE_REWARD, po = cc.p(rewardStarBtnSize.width/2 + 40, rewardStarBtnSize.height/2 + 28)})

    local centerSize = cc.size(display.width, 570)
    
    local centerLayout = display.newLayer(display.cx, display.cy ,{ap =  display.CENTER , size = centerSize })
    bgLayout:addChild(centerLayout)
    -- 标题
    local titleImage  = display.newButton(centerSize.width/2 , centerSize.height,
              {n = _res('ui/home/activity/seasonlive/season_loots_bg_title_1') , ap = display.CENTER_TOP , enable = false }  )
    display.commonLabelParams(titleImage,fontWithColor('18', {text =  __('品鉴旅程')}))
    centerLayout:addChild(titleImage)
    titleImage:setCascadeOpacityEnabled(true)
    local titleSize = titleImage:getContentSize()

    -- 提示的按钮
    local tipButton = display.newButton(display.width/2 +titleSize.width/2 + 30 , centerSize.height - titleSize.height/2 ,
                                        {  n = _res('ui/common/common_btn_tips')})
    centerLayout:addChild(tipButton)
    tipButton:setTag(BUTTON_CLICK.TIP_BUTTON)
    tipButton:setCascadeOpacityEnabled(true)

    -- 获取奖励的图片
    local rewardTitile = display.newButton(0,0,{ n = _res('ui/tastingTour/stage/fish_travel_bg_tips.png') , enable = true } )
    centerLayout:addChild(rewardTitile)
    local rewardTitileSize  = rewardTitile:getContentSize()
    rewardTitile:setPosition(cc.p(centerSize.width/2, centerSize.height - titleSize.height -rewardTitileSize.height/2 - 5  ))
    rewardTitile:setVisible(false)
    -- 更新的label
    --local richLabel = display.newLabel(rewardTitileSize.width/2, rewardTitileSize.height/2, { c = {
    --    fontWithColor('11',{text = ""})
    --}})
    --rewardTitile:addChild(richLabel)


    local gridSize = cc.size(1280, centerSize.height - 110 )
    local gridCellSize = cc.size(gridSize.width/4, gridSize.height)
    local gridView = CTableView:create(gridSize)
    gridView:setAnchorPoint(display.CENTER_TOP)
    gridView:setPosition(cc.p(centerSize.width * 0.5, centerSize.height -110))
    gridView:setDirection(eScrollViewDirectionHorizontal)
    gridView:setSizeOfCell(gridCellSize)
    --gridView:setBounceable(false)
    centerLayout:addChild(gridView)
    centerLayout:setVisible(false)
    toplayout:setVisible(false)
    tipButton:setVisible(false)
    titleImage:setVisible(false)
    self.viewData = {
        gridSize       = gridSize,
        gridView       = gridView,
        gridCellSize   = gridCellSize,
        backBtn        = backBtn,
        richLabel      = richLabel,
        rewardTitile   = rewardTitile,
        prograssLabel  = prograssLabel,
        progressBarOne = progressBarOne,
        rewardStarBtn  = rewardStarBtn ,
        toplayout      = toplayout,
        centerLayout   = centerLayout ,
        titleImage     = titleImage ,
        tipButton     = tipButton ,
    }
end
--[[
    创建tableViewCell
--]]
function TastingTourChooseRecipeStyleView:CreateTableViewCell()
    local tableCell = CTableViewCell:new()
    tableCell:setContentSize(self.viewData.gridCellSize)
    -- 风格的图片
    local bgImage = display.newImageView(_res('ui/tastingTour/stage/fish_travel_bg_food_mastery_lock'))
    local prograssSize = bgImage:getContentSize()

    -- 进度的layout
    local prograssLayout = display.newLayer(self.viewData.gridCellSize.width/2 , self.viewData.gridCellSize.height
    ,{ap = display.CENTER_TOP , size = prograssSize })
    tableCell:addChild(prograssLayout)
    prograssLayout:addChild(bgImage)
    prograssLayout:setVisible(false)
    bgImage:setPosition(cc.p(prograssSize.width/2, prograssSize.height/2))

    local levelImage = display.newImageView(_res("ui/tastingTour/stage/fish_travel_bg_level_1"), prograssSize.width/2 , prograssSize.height  , {ap = display.CENTER_TOP})
    prograssLayout:addChild(levelImage,10)
    levelImage:setVisible(false)
    local progressBarOne = CProgressBar:create(_res("ui/tastingTour/stage/fish_travel_bg_level_loading_1"))
    progressBarOne:setBackgroundImage(_res("ui/tastingTour/stage/fish_travel_bg_level_loading_2"))
    progressBarOne:setDirection(eProgressBarDirectionLeftToRight)
    progressBarOne:setAnchorPoint(cc.p(0.5, 0.5))
    progressBarOne:setPosition(cc.p(prograssSize.width/2 -10 , 55))
    prograssLayout:addChild(progressBarOne)
    progressBarOne:setMaxValue(100)
    progressBarOne:setValue(0)

    local progressBarOneSize  = progressBarOne:getContentSize()
    -- 添加starImage
    local starImage  = display.newImageView(_res('ui/tastingTour/stage/fish_travel_ico_star'),progressBarOneSize.width+20 , progressBarOneSize.height/2,{ap = display.RIGHT_CENTER , scale = 0.6 })
    progressBarOne:addChild(starImage, 10)
    progressBarOne:setVisible(false)


    
    -- 风格的图片
    local styleImage = display.newImageView(_res('ui/tastingTour/stage/fish_travel_bg_01'),
            prograssSize.width/2, prograssSize.height/2)
    prograssLayout:addChild(styleImage)

    local styleLabel = display.newLabel(prograssSize.width/2 , 90,
                    fontWithColor('14',{text = '11', color = '#ffffff', fontSize = 28 , outline =  '5b3c35' , outlineSize  = 2 }))
    prograssLayout:addChild(styleLabel ,10)

    local statusImage = display.newImageView(_res('ui/tastingTour/stage/fish_travel_bg_star_number'),prograssSize.width/2 , 55)
    prograssLayout:addChild(statusImage)
    --local statusSize = statusImage:getContentSize()
    local richLabel = display.newRichLabel(prograssSize.width/2 , 55 ,
                                           {c = {
                                               fontWithColor('14',{text = ""})
                                           }})
    prograssLayout:addChild(richLabel)

    local enterBtn = display.newButton(self.viewData.gridCellSize.width/2 ,35,
                               {n = _res('ui/common/common_btn_orange')} )
    tableCell:addChild(enterBtn)
    display.commonLabelParams(enterBtn, fontWithColor('14',{text =__('确认')}))

    tableCell.bgImage        = bgImage
    tableCell.richLabel      = richLabel
    tableCell.statusImage    = statusImage
    tableCell.styleLabel     = styleLabel
    tableCell.enterBtn       = enterBtn
    tableCell.styleImage     = styleImage
    tableCell.prograssLayout = prograssLayout
    tableCell.progressBarOne = progressBarOne
    tableCell.levelImage     = levelImage
    return  tableCell
end

--[[
更新cell 的逻辑
--]]
function TastingTourChooseRecipeStyleView:UpdateCell(cell , data, isSelect )
    if cell == nil then return end
    local unLock  = data.isUnlock == 1 or false
    local star    = tastingTourMgr:GetStageStarNumByStyleId(data.id)
    local name    = data.name
    local count   =  tastingTourMgr:GetStageCountStarById(data.id)
    local stageConfig = tastingTourMgr:GetConfigDataByName(tastingTourMgr:GetConfigParse().TYPE.STAGE)[tostring(data.id)] or {}
    local effect = 1
    if stageConfig then  -- 获取到应该更新的效果
        local rateTable = stageConfig.rate
        for i = 1, #rateTable do
            effect =  i
            if star <  checkint(rateTable[i])   then
                effect = i -1
                break
            end
        end
    end
    cell.progressBarOne:setVisible(false)
    cell.levelImage:setVisible(false)
    cell.statusImage:setVisible(false)
    local styleId = data.cookId
    if isSelect then
        cell.bgImage:setTexture(_res('ui/tastingTour/stage/fish_travel_bg_food_mastery_selected'))
        cell.styleLabel:setString(name)
        display.reloadRichLabel(cell.richLabel, { c= {
            fontWithColor('14' , {fontSize = 28, text = string.format("%s/%s ", star, count)})
            --{img = _res('ui/tastingTour/stage/fish_travel_ico_star') , scale =  0.6 }
        }})
        cell.styleImage:setTexture(_res(string.format("ui/tastingTour/stage/fish_travel_bg_%02d", styleId)) )
        CommonUtils.AddRichLabelTraceEffect(cell.richLabel ,nil , nil ,{1} )
        cell.progressBarOne:setVisible(true)
        cell.levelImage:setVisible(true)
        cell.statusImage:setVisible(false)
        cell.progressBarOne:setMaxValue(count)
        cell.progressBarOne:setValue(star)
        cell.levelImage:setTexture(_res(string.format("ui/tastingTour/stage/fish_travel_bg_level_%d", effect)))
    elseif unLock then
        cell.bgImage:setTexture(_res('ui/tastingTour/stage/fish_travel_bg_food_mastery_normal'))
        cell.styleLabel:setString(name)
        display.reloadRichLabel(cell.richLabel, { c= {
            fontWithColor('14' , {fontSize = 28,text = string.format("%s/%s  ", star, count)})
            --{img = _res('ui/tastingTour/stage/fish_travel_ico_star') ,scale = 0.6   }
        }})
        cell.styleImage:setTexture(_res(string.format("ui/tastingTour/stage/fish_travel_bg_%02d", styleId)) )
        CommonUtils.AddRichLabelTraceEffect(cell.richLabel ,nil , nil ,{1} )
        cell.progressBarOne:setVisible(true)
        cell.levelImage:setVisible(true)
        cell.progressBarOne:setMaxValue(count)
        cell.progressBarOne:setValue(star)
        cell.levelImage:setTexture(_res(string.format("ui/tastingTour/stage/fish_travel_bg_level_%d", effect)))
    else

        cell.bgImage:setTexture(_res('ui/tastingTour/stage/fish_travel_bg_food_mastery_lock'))
        cell.styleLabel:setString(name)
        display.reloadRichLabel(cell.richLabel, { c= {
            {img = _res('ui/common/common_ico_lock') , ap = cc.p(0, -0.05)}
        }})
        cell.styleImage:setTexture(_res(string.format("ui/tastingTour/stage/fish_travel_bg_%02d", styleId)) )
        cell.statusImage:setVisible(true)
    end
    cell.enterBtn:setVisible(isSelect)
end

return TastingTourChooseRecipeStyleView
