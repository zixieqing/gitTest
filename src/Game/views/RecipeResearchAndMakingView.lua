local RecipeResearchAndMakingView = class('RecipeResearchAndMakingView',
	function ()
		local node = CLayout:create(display.size)
		node.name = 'Game.views.RecipeResearchAndMakingView'
		node:enableNodeEvents()
		return node
	end
)
local gameMgr = AppFacade.GetInstance():GetManager("GameManager")
local uiMgr = AppFacade.GetInstance():GetManager("UIManager")
local BtnCollect = {
    ImprovedRecipe = 1001 ,  --改进按钮
    Research       = 1002 ,  --研究按钮
    Specialization = 1003 ,	 --专精按钮
	MagicStyle     = 4 ,  --魔法菜系
	closeBtn       = 1004 ,  --关闭按钮
	STYLE_BTN      = 1005 ,  --风格按钮
	STYLE_BTN_TWO  = 1311 , -- 第二个风格按钮
	SEARCH_BTN     = 1006 ,  --搜寻按钮
	SHOW_RECIPE_DETAIL = 1007, --显示菜谱详情界面的信息
    RESEARCH_RSEARCH = 1201 ,  -- 菜谱开发中的开发
    RESEARCH_QUCIK = 1202 ,    -- 开发中的快速完成
    RESEARCH_CANCEL = 1203 ,   -- 菜谱开发取消
    RESEARCH_REWARD = 1204 ,   -- 菜谱开发奖励领取
	CURRENT_RESEARCH_STYLE = 1205 , -- 当前研究的菜系
	FOOD_METARIAL = 1206 , ---- 食材的提示
}

local RES_DICT = {

	BGImage      = _res('ui/home/kitchen/cooking_bg.png'),
	CONTAINERBG  = _res('ui/home/kitchen/kitchen_bg_food_mastery_words.png'),
	Btn_Normal   = _res("ui/common/common_btn_sidebar_common.png"),
	BTN_SELECT   = _res("ui/common/common_btn_white_default.png"),
	BTN_ORANGE   = _res("ui/common/common_btn_orange.png"),
	CheckBtnN    = _res("ui/common/common_btn_sidebar_common.png"),
	CheckBtnS    = _res("ui/common/common_btn_sidebar_selected.png"),
	GradViewBg   = _res("ui/common/common_bg_goods.png"),
	CloseBtn     = _res("ui/common/common_btn_quit.png"),
	LockImage    = _res("ui/common/common_ico_lock.png"),
	CIRCLE       = _res("ui/home/kitchen/kitchen_bg_food_quan.png"),
	Horntips     = _res("ui/home/kitchen/cooking_title_ico_down.png"),
	SearchRecipe = _res('ui/home/kitchen/cooking_btn_pokedex.png'),
	StyleRecipe  = _res('ui/home/kitchen/cooking_title_btn.png'),
	UnLockStyle  = _res('ui/home/kitchen/kitchen_btn_tab_drop_unlock.png'),
	StyleBar 	 = _res('ui/home/kitchen/kitchen_bg_tab_drop.png'),
	LockStyle    = _res('ui/home/kitchen/kitchen_btn_tab_drop.png'),
	COOKING_BG   = _res('ui/home/kitchen/cooking_foods_bg.png'),
	TIMELABEL   = _res('ui/home/kitchen/cooking_bg_time.png'),
	COOKING_GRADE= _res('ui/home/kitchen/cooking_foods_grade_bg.png'),
	GRADE_A      = _res('ui/home/kitchen/cooking_grade_ico_a.png'),
	TASK_SELECT  = _res('ui/home/kitchen/gut_task_btn_select.png'),
	GOODS_BG 	 =  _res('ui/common/common_bg_goods.png'),
	BTN_TIPS 	 =  _res('ui/common/common_btn_tips.png'),
	COOKING_STUDYBG_TIPS = _res('ui/home/kitchen/cooking_study_bg_tips.png'),
	STUDY_BG_WORDS  = _res('ui/home/kitchen/cooking_study_bg_words.png'),
	STUDY_BG      =  _res('ui/home/kitchen/cooking_study_bg.png'),
	STUDY_FOODS_LIGHT = _res('ui/home/kitchen/cooking_study_foods_bg_light.png'),
	STUDY_FOODS = _res('ui/home/kitchen/cooking_study_foods_bg.png'),
	STUDY_FOODS_NAME_BG  = _res('ui/home/kitchen/cooking_study_foods_name_bg.png'),
	DRAW_CARD_BG_NAME = _res('ui/home/kitchen/cooking_study_ico_secret.png'),
	COOK_STUDY_ICO_SECRET = _res('ui/home/capsule/draw_card_bg_name.png'),
	DRAW_CARD_ICON_NEW   = _res('ui/home/capsule/draw_card_ico_new.png'),
	GUT_TASK_BTN_SELECT  = _res('ui/home/kitchen/gut_task_btn_select_2.png'),
	FONT_NAME_BTN  =  _res('ui/common/common_cooking_bg_font_name.png'),
	BTN_DISABLED    = _res( 'ui/common/common_btn_orange_disable.png'),
	ICON_LOCK  = _res('ui/common/common_ico_lock.png'),
	COOKING_BAR1 = _res('ui/home/kitchen/cooking_mastery_bar_1.png'),
	COOKING_BAR2 = _res('ui/home/kitchen/cooking_mastery_bar_2.png'),
	COOKING_BAR = _res('ui/home/kitchen/cooking_mastery_bar_bg.png'),
	COOKING_BG_BARS = _res('ui/home/kitchen/cooking_mastery_bar_bg.png'),
	COOK_MESTERY_BG =  _res('ui/home/kitchen/cooking_mastery_bg.png'),
	COOK_MESTERY_TITLE =  _res('ui/home/kitchen/cooking_mastery_title.png'),
	COOK_MESTERY_FOOD_WORDS =  _res('ui/home/kitchen/kitchen_bg_food_mastery_words.png'),
	COOKING_NOTUNLOCK = _res('ui/home/kitchen/cooking_mastery_title_notunlock.png'),
	NEW_OBTAIN = _res('ui/home/cardslistNew/card_preview_ico_new.png') ,
	SELECT_SPECIAL_IMAGE  = _res('ui/home/kitchen/cooking_mastery_frame.png'),
	UN_SPECIAL_NAME_TITLE  = _res('ui/home/kitchen/cooking_mastery_title_unlock.png'),
	SPECIAL_NAME_TITLE = _res('ui/home/kitchen/cooking_mastery_title.png'),
	SPLIT_LINE  =  _res('ui/home/kitchen/kitchen_tool_split_line.png'),
	LEVEL_UP  =  _res('ui/home/kitchen/kitchen_ico_level_up.png')
}
function RecipeResearchAndMakingView:ctor()
	self.collectBtn = {   --这个表用烹饪三个大功能的btn

	}
	self.styleBtns = {   -- 这个是菜品风格种类改进

	}
	self.othersButtns = {  --制作其他btn搜寻

	}
	self.styleTable = app.cookingMgr:GetStyleTable()
	self.recipeData = CommonUtils.GetConfigAllMess('recipe','cooking')  -- 这个解析的是数据表

	self:initUi()

end

function RecipeResearchAndMakingView:initUi()

	local closeView = display.newLayer(display.cx,display.cy, {ap = display.CENTER ,size = display.size ,enable = true , color = cc.c4b(0,0,0,100)})
	self:addChild(closeView)
	self.closeView = closeView
	local bgImage = display.newImageView(RES_DICT.BGImage, 0,0)
	local leftLayoutSize = bgImage:getContentSize()
	local leftLayout = CLayout:create(leftLayoutSize)
	bgImage:setPosition(cc.p(leftLayoutSize.width/2, leftLayoutSize.height/2))
	leftLayout:addChild(bgImage)

	local offsetLeft = 6
	-- 计算layout 的大小
	-- 添加右侧的Layout
	local rightLayout = self:createButtonLayout()
	local rightLayoutSize = rightLayout:getContentSize()

	local width = leftLayoutSize.width + rightLayoutSize.width - offsetLeft
	local bgSize = cc.size(width,leftLayoutSize.height)
	rightLayout:setAnchorPoint(display.LEFT_TOP)
	rightLayout:setPosition(cc.p(leftLayoutSize.width - 6,bgSize.height -110))
	-- 添加左侧的Layout
	local bgLayout   = CLayout:create(bgSize)
	local swallLayer_two = display.newLayer(bgSize.width/2,bgSize.height/2, {ap = display.CENTER , size = bgSize,enable = true,color = cc.c4b(0,0,0,0) })
	bgLayout:addChild(swallLayer_two)
	bgLayout:setName("bgLayout")
	bgLayout:setPosition(cc.p(display.cx ,display.cy))
	bgLayout:addChild(leftLayout)
	bgLayout:addChild(rightLayout)
	leftLayout:setAnchorPoint(display.LEFT_CENTER)
	leftLayout:setName("leftLayout")
	leftLayout:setPosition(cc.p(0,bgSize.height/2))
	local closeBtn = display.newButton(leftLayoutSize.width -14 ,bgSize.height+5 ,{n = RES_DICT.CloseBtn,ap = display.LEFT_TOP})
	bgLayout:addChild(closeBtn)
	closeBtn:setName("closeBtn")
	self.closeBtn = closeBtn
	self:addChild(bgLayout,2)

	self.bgLayout = bgLayout
	self.leftLayout = leftLayout
	self.leftLayoutSize = leftLayoutSize
end
--制作的Layout
function RecipeResearchAndMakingView:createMakeLayout(bgSize , unLockStylekData)
	local viewData = self:createBGLayout(bgSize)
	local noRecipeView = self:AddNotRecipeView(bgSize)
	noRecipeView:setVisible(false)
	local leftLayout = viewData.view
	local leftLayoutSize =  leftLayout:getContentSize()
	local topData =  self:createTopLayout()
	local topLayout =topData.view
	topLayout:setAnchorPoint(display.CENTER_TOP)
	topLayout:setPosition(cc.p(leftLayoutSize.width/2,leftLayoutSize.height -13))
	leftLayout:addChild(topLayout)
	leftLayout:addChild(noRecipeView)
	local pos =  cc.p( self.othersButtns[tostring(BtnCollect.STYLE_BTN)]:getPosition())
	pos = topLayout:convertToWorldSpace(pos) -- 将节点坐标转化为节点坐标
	pos = leftLayout:convertToNodeSpace(pos) -- 将世界左边转化为世界坐标


	local styleData = self:createStyleButtonsLayout(unLockStylekData)
	styleData.view:setPosition(cc.p(pos.x+1,pos.y -30))
	styleData.view:setAnchorPoint(display.CENTER_TOP)
	local styleSwallowLayer = display.newLayer(bgSize.width/2 ,bgSize.height/2 , { ap = display.CENTER , size = bgSize ,enable = true ,color = cc.c4b(0,0,0,0) })
	styleSwallowLayer:setVisible(false)
	leftLayout:addChild(styleSwallowLayer)
	leftLayout:addChild(styleData.view,2)
	styleData.view:setVisible(false)
	styleData.view:setScale(0)
	return {
		gridView          = viewData.gridView,
		progressLabel     = topData.progressLabel,
		view              = viewData.view,
		styleLayout       = styleData.view,
		topLayout         = topLayout,
		styleSwallowLayer = styleSwallowLayer,
		noRecipeView      = noRecipeView,
		leftLayout        = leftLayout
	}
end
--[[
添加没有访客的说明
--]]
function RecipeResearchAndMakingView:AddNotRecipeView(bgSize)
	local noRecipeView = display.newLayer(bgSize.width/2 ,bgSize.height/2,{ap = display.CENTER , size = bgSize})
	local qImage = display.newImageView( _res('arts/cartoon/card_q_3')  , bgSize.width/2 , bgSize.height/2 , {scale = 0.7})
	noRecipeView:addChild(qImage)
	local label = display.newLabel(bgSize.width/2 , bgSize.height/2 - 170 ,fontWithColor(14 , { color = "#ba5c5c" , fontSize = 30 , ap = display.CENTER ,hAlign= display.TAC ,  text = __('没有获得当前菜系菜谱') }))
	noRecipeView:addChild(label)
	return noRecipeView
end

--右侧开发的按钮
function RecipeResearchAndMakingView:createButtonLayout()
	local btnTable = {
		{ tag = BtnCollect.Specialization ,text = __('专精') ,name = "Specialization" },
		{ tag = BtnCollect.Research ,text = __('开发') ,name = "Research"},
		{ tag = BtnCollect.ImprovedRecipe ,text = __('改良'),name = "ImprovedRecipe"},
	}
	local styleData = CommonUtils.GetConfigAllMess('style', 'cooking')

	table.insert(btnTable, 1, { tag = BtnCollect.MagicStyle ,text = styleData[tostring("4")].name,name = "MagicStyle"})
	local checkBoxSize = cc.size(143,96)
	local btnLayout = CLayout:create(cc.size(checkBoxSize.width, checkBoxSize.height * #btnTable))

	for i =1 ,#btnTable do
		local createButton = display.newCheckBox(0,0, { n =RES_DICT.CheckBtnN , s = RES_DICT.CheckBtnS})
		local fontSize = 26
		if i == 1 then
			fontSize =24
		end
		local label = display.newLabel(checkBoxSize.width /2-5,checkBoxSize.height/2 +25,fontWithColor('2' , { text =btnTable[i].text  , fontSize = fontSize})  )
		createButton:addChild(label)
		if display.getLabelContentSize(label).width > 150 then
			display.commonLabelParams(label ,{text =btnTable[i].text , hAlign = display.TAC , w = 120, reqH = 60 })
		else
			display.commonLabelParams(label ,{text =btnTable[i].text , hAlign = display.TAC , reqW = 120})
		end
		label:setTag(111) -- 内容设置值
		createButton:setTag(btnTable[i].tag)
		self.collectBtn[tostring(btnTable[i].tag)] = createButton
		createButton:setPosition(checkBoxSize.width/2,checkBoxSize.height*(i -0.5))
		createButton:setName(btnTable[i].name)
		btnLayout:addChild(createButton)
	end
	btnLayout:setName("btnLayout")
	local layoutSize = cc.size(100,65)
	local layout = CLayout:create(layoutSize)
	layout:setPosition (cc.p(checkBoxSize.width/2-10,checkBoxSize.height/2))
	layout:setTag(112)
	local image = display.newImageView(RES_DICT.TIMELABEL)
	local imageSize = image:getContentSize()
	image:setPosition(cc.p(layoutSize.width/2+7,imageSize.height/2 ))
	local countDownLabel  = display.newLabel(imageSize.width /2,imageSize.height/2,fontWithColor('10' , { text = " " })  )
	countDownLabel:setTag(112)
	image:addChild(countDownLabel)
	layout:addChild(image)
	layout.countDownLabel = countDownLabel
	local researchDoing = display.newLabel(layoutSize.width/2+5,(layoutSize.height+imageSize.height)/2+7 ,fontWithColor('2', {ap = display.CENTER , text = __('开发中') }))
	layout:addChild(researchDoing)
	researchDoing:setTag(113)
	layout:setVisible(false)
	self.collectBtn[tostring(BtnCollect.Research)]:addChild(layout)
	return btnLayout
end

--==============================--
--desc:创建顶部的内容
--time:2017-05-19 03:10:40
--return
--==============================--
function RecipeResearchAndMakingView:createTopLayout()
	local  topSize = cc.size(555,60)
	local topLayout = CLayout:create(topSize)
	local styleBtn = display.newButton(topSize.width ,topSize.height/2,{ap = display.CENTER, n = RES_DICT.StyleRecipe , s = RES_DICT.StyleRecipe , animate = true})
	topLayout:addChild(styleBtn)

	styleBtn:setName("styleBtn")
	local styleBtnSize = styleBtn:getContentSize()
	styleBtn:setPosition(cc.p(topSize.width-styleBtnSize.width/2  ,topSize.height/2))

	self.othersButtns[tostring(BtnCollect.STYLE_BTN) ] = styleBtn
	local label = display.newLabel(styleBtnSize.width/2,styleBtnSize.height/2 ,fontWithColor('14', {text = "" , fontSize = 22 }))
	label:setTag(116)
	styleBtn:addChild(label)
	local richLabel = display.newRichLabel(styleBtnSize.width/2,styleBtnSize.height/2 , { ap = display.CENTER , c= {
		fontWithColor('14',{text = "dffsfsfdsfs"}) ,
		{img = RES_DICT.Horntips ,ap = cc.p(-5, -0.5) }
	}})
	richLabel:setTag(115)
	styleBtn:addChild(richLabel)
	styleBtn:setTag(BtnCollect.STYLE_BTN)

	local searchBtn = display.newButton(0,topSize.height/2 , {ap = display.LEFT_CENTER, n = _res('ui/home/kitchen/kitchen_btn_foods_pokedex.png') , s =  _res('ui/home/kitchen/kitchen_btn_foods_pokedex.png')  , scale9 = true } )
	local searchBtnSize = searchBtn:getContentSize()
	local searchImage = display.newImageView(RES_DICT.SearchRecipe,0,searchBtnSize.height/2, { ap = display.LEFT_CENTER})
	local searchImageSize = searchImage:getContentSize()
	local searchLabel = display.newLabel( searchImageSize.width + 10, searchBtnSize.height/2, fontWithColor('10',{ ap = display.LEFT_CENTER,text =  __('菜谱图鉴') , color = "#ffffff" }))
	local searchLabelSize = display.getLabelContentSize(searchLabel)
	local searchBtnSize = cc.size(searchLabelSize.width +searchImageSize.width +20, searchBtnSize.height )
	local searchLayout = display.newLayer(searchBtnSize.width/2,searchBtnSize.height/2, { ap = display.CENTER , size = cc.size(searchLabelSize.width +searchImageSize.width +10, searchBtnSize.height ) })
	searchLayout:addChild(searchLabel)
	searchLayout:addChild(searchImage)
	searchBtn:setContentSize(searchBtnSize)
	local jiaziLayout = display.newLayer(topSize.width-styleBtnSize.width/2  ,topSize.height/2, { ap = display.CENTER , size = styleBtnSize})
	topLayout:addChild(jiaziLayout)

	searchBtn:addChild(searchLayout)
	searchBtn:setTag(BtnCollect.SEARCH_BTN)
	topLayout:addChild(searchBtn)
	self.othersButtns[ tostring(BtnCollect.SEARCH_BTN)] = searchBtn

	local progressLabel = display.newLabel(60,topSize.height/2,fontWithColor('16', {ap = display.LEFT_CENTER ,text = "ghfhgffhfgh"}))
	topLayout:addChild(progressLabel)
	topLayout.progressLabel = progressLabel
	progressLabel:setOpacity(0)
	return {
		progressLabel = progressLabel,
		view = topLayout
	}
end

--创建所有风格的Layout
function RecipeResearchAndMakingView:createStyleButtonsLayout()
	-- body
	local  bgLayout = CLayout:create()
	bgLayout:setName('goddddgodgod')
	self:renderStyleButtonsLayout(bgLayout)
	return {
		view = bgLayout
	}

end

-- 渲染 所有风格的Layout
function RecipeResearchAndMakingView:renderStyleButtonsLayout(bgLayout)
	if bgLayout:getChildrenCount() > 0 then
        bgLayout:removeAllChildren()
	end

	local chooseData = gameMgr:GetUserInfo().cookingStyles
	local count = 0
	for k , vv in pairs(chooseData) do
		if checkint(k) ~= 4  then
			count = count + 1
		end
	end
	local width  = 200
	local height = 63
	local bgSize = cc.size(200,65*count)
	bgLayout:setContentSize(bgSize)
	local bgLayer  = display.newLayer(bgSize.width/2,bgSize.height/2,{color = cc.c4b(0,0,0,0),size = bgSize , enable = true,ap = display.CENTER})
	bgLayout:addChild(bgLayer)
	local  bgImage = display.newImageView(RES_DICT.StyleBar ,bgSize.width/2 , bgSize.height/2 ,{ scale9 = true ,size = bgSize })
	bgImage:setTag(111)
	bgLayout:addChild(bgImage)
	local num =  0
	local sortRecipeStyleTable ={}
	for  k , vv in pairs(chooseData) do
		sortRecipeStyleTable[#sortRecipeStyleTable+1] = k
	end
	table.sort(sortRecipeStyleTable, function (a,b)
		-- if checkint(a) < checkint(b) then
		-- 	return false
		-- end
		-- return true
		if a == nil then return true end
		if b == nil then return false end
		return checkint(a) > checkint(b)
	end)
	-- dump(sortRecipeStyleTable, 'sortRecipeStyleTable222')
	for k , vv in pairs(sortRecipeStyleTable) do
		if checkint(vv) ~= 4 then
			local v = self.styleTable[tostring(vv)]
			num = num +1
			local btn = display.newButton(bgSize.width/2 ,height*(num - 0.5),{ n = RES_DICT.LockStyle ,scale9 = true , size = cc.size(190,58) })
			bgLayout:addChild(btn,2)
			display.commonLabelParams(btn , { fontSize = 22 ,color = "#3e1509",text = v.name})
			local labelSize = display.getLabelContentSize(btn:getLabel())
			local scale = 180 / labelSize.width  < 1  and   180 / labelSize.width  or 1
			if scale < 1 then
				local  scaleOne = btn:getLabel():getScale()
				btn:getLabel():setScale(scale *scaleOne)
			end

			local lockImage  = display.newImageView(RES_DICT.UnLockStyle ,width/2-6, height/2)
			btn:addChild(lockImage,10)
			local iconLock = display.newImageView(RES_DICT.ICON_LOCK ,width/2, height/2)
			lockImage:setTag(111)
			lockImage:addChild(iconLock)
			lockImage:setVisible(false)
			btn:setTag(tonumber(v.id))
			self.styleBtns[tostring(v.id)] = btn
		end
	end
end

--==============================--
--desc:更新菜谱风格按钮的位置按钮的位置
--time:2017-07-03 05:29:56
--@view:这个是styleout
--@return
--==============================--
function RecipeResearchAndMakingView:updateStylePos(view)
	local num = 0
	local chooseData = gameMgr:GetUserInfo().cookingStyles
	local count = table.nums(chooseData)
	local bgSize = cc.size(239,65*count)
	view:setContentSize(bgSize)
	local node = view:getChildByTag(111)
	if node then
		node:removeFromParent()
	end
	local  bgImage = display.newImageView(RES_DICT.StyleBar ,bgSize.width/2 , bgSize.height/2 ,{ scale9 = true ,size = bgSize })
	bgImage:setTag(111)
	view:addChild(bgImage)
	for  k , v in pairs(self.styleBtns) do
		num = num +1
		v:setPosition(cc.p(bgSize.width/2 ,65*(num - 0.5)))
	end
end

function RecipeResearchAndMakingView:creatGridCell()
	local gridCellSize = cc.size(185,230)
	-- 创建CELL
	local gridViewCell =  CGridViewCell:new()
    gridViewCell:enableNodeEvents()
	gridViewCell:setContentSize(gridCellSize)
	-- 背景图片
	local   bgImage = display.newImageView(RES_DICT.COOKING_BG,0,0,{ enable = true , scale9 = true ,size = gridCellSize})
	local bgSize = bgImage:getContentSize()
	bgImage:setPosition(cc.p(bgSize.width/2,bgSize.height/2))
	local bgLayout = CLayout:create(bgSize)
	bgLayout:setPosition(cc.p(gridCellSize.width/2 , gridCellSize.height/2))
	gridViewCell:addChild(bgLayout)
	bgLayout:addChild(bgImage)
	bgImage:setTag(BtnCollect.SHOW_RECIPE_DETAIL)
	-- 选上的图片
	local selectImage  =display.newImageView(RES_DICT.TASK_SELECT,bgSize.width/2, bgSize.height/2, { enable = false , scale9 = true ,size = gridCellSize})
	bgLayout:addChild(selectImage)
	selectImage:setVisible(false)
	selectImage:setTag(111)
	--成绩图片
	local gradeImage = display.newImageView(RES_DICT.GRADE_A,0, bgSize.height -3,{ap = display.LEFT_TOP})
	bgLayout:addChild(gradeImage)
	-- 菜品图片
	local circleImage  = display.newImageView(RES_DICT.CIRCLE,bgSize.width/2, bgSize.height- 90,{ap = display.CENTER})
	bgLayout:addChild(circleImage)
	circleImage:setScale(0.8)
	local iconPath = CommonUtils.GetGoodsIconPathById('190001')
	local recipeImage = display.newImageView(iconPath,bgSize.width/2, bgSize.height- 90,{ap = display.CENTER})
	bgLayout:addChild(recipeImage)
	recipeImage:setScale(0.9)

	-- 菜品标签
	local recipeNameLabel = display.newLabel(bgSize.width/2 , 10,fontWithColor('16',{fontSize = 22 , color   =  "#7c4b35" ,text = "",
        ap = display.CENTER, w = 170, ap = display.CENTER_BOTTOM}) )
    recipeNameLabel:setAlignment(cc.TEXT_ALIGNMENT_CENTER)
	bgLayout:addChild(recipeNameLabel)
	local newImage  = display.newImageView(RES_DICT.NEW_OBTAIN,bgSize.width/2,bgSize.height-20)
	newImage:setVisible(false)
	newImage:setTag(112)
	newImage:setScale(0.85)
	bgLayout:addChild(newImage,10)
	local levelupImage  = display.newImageView(RES_DICT.LEVEL_UP,bgSize.width/2+15,bgSize.height-20)
	bgLayout:addChild(levelupImage,10)
	levelupImage:setScale(0.9)
	levelupImage:setTag(113)
	levelupImage:setVisible(false)
	gridViewCell.bgLayout = bgLayout
	gridViewCell.gradeImage = gradeImage
	gridViewCell.recipeImage = recipeImage
	gridViewCell.recipeNameLabel = recipeNameLabel
	gridViewCell.bgImage = bgImage
	gridViewCell.selectImage = selectImage
	gridViewCell.newImage = newImage
	gridViewCell.levelupImage = levelupImage
	gridViewCell.circleImage  = circleImage
	return gridViewCell
end

-- 更新GradView 逻辑
function RecipeResearchAndMakingView:updateGradeCell(gradeCell,data, isTrue)
	if  not self.recipeData[tostring(data.recipeId)] then
		return
	end
	local recipeName = CommonUtils.GetConfig('goods','goods',self.recipeData[tostring(data.recipeId)].foods[1].goodsId).name
	local recipeGrade = data.gradeId
	local recipeData = CommonUtils.GetConfigAllMess('recipe' , 'cooking')
	local recipeOneData = recipeData[tostring(data.recipeId)]
	local cookingStyleId = checkint(recipeOneData.cookingStyleId)
	if RECIPE_STYLE.SHI_LUO_CAI_XI == cookingStyleId then
		gradeCell.bgImage:setTexture(_res("ui/home/kitchen/cooking_foods_bg_lost"))
	else
		gradeCell.bgImage:setTexture(_res("ui/home/kitchen/cooking_foods_bg"))
	end
	local recipePath = CommonUtils.GetGoodsIconPathById(self.recipeData[tostring(data.recipeId)].foods[1].goodsId)
	local isShow = true
	 if checkint(data.recipeId) >=  229001  and  checkint(data.recipeId) <=  229999 then
		isShow = false
	end
	gradeCell.gradeImage:setVisible(false)
	gradeCell.circleImage:setVisible(false)
	if isShow then
		gradeCell.gradeImage:setVisible(true)
		gradeCell.circleImage:setVisible(true)
		gradeCell.gradeImage:setTexture(_res(string.format('ui/home/kitchen/cooking_grade_ico_%d.png',recipeGrade or 1)) )
	end

	gradeCell.recipeNameLabel:setString(recipeName)
	gradeCell.recipeImage:setTexture(recipePath)
	gradeCell.selectImage:setVisible(isTrue)
	gradeCell.recipeId =checkint(data.recipeId)
end
--
function RecipeResearchAndMakingView:createBGLayout(bgSize)
	local bgLayout = CLayout:create(bgSize)
	local gradSize = cc.size(555,572)
	bgLayout:setName("bgLayout")
	local gradCellSize = cc.size(555/3,230 )
	local  gradImage = display.newImageView(RES_DICT.GradViewBg,bgSize.width/2,24,{scale9 = true , size = cc.size(561,572),ap = display.CENTER_BOTTOM})
	bgLayout:addChild(gradImage)
	local gridView = CGridView:create(gradSize)
	gridView:setSizeOfCell(gradCellSize)
	gridView:setName("gridView")
	gridView:setColumns(3)
	gridView:setAutoRelocate(true)
	gridView:setAnchorPoint(display.CENTER_BOTTOM)
	gridView:setPosition(cc.p(bgSize.width/2,24))
	bgLayout:addChild(gridView)
	return {
		view = bgLayout ,
		gridView = gridView
	}
end
--==============================--
--desc:开发的Layout
--time:2017-05-21 09:05:12
--return
--==============================--

function RecipeResearchAndMakingView:researchLayout(bgSize)
	local bgLayout =CLayout:create(bgSize)
	-- 最顶部的内容
	local offsetHeight = 76
	local topTopSize = cc.size(bgSize.width ,offsetHeight)
	local topTopLayout = display.newLayer(topTopSize.width/2 , bgSize.height , { ap = display.CENTER_TOP, size = topTopSize })
	bgLayout:addChild(topTopLayout)
	local guidBtn = CommonUtils.GetGuideBtn('recipe')
	local guideLabel =  guidBtn:getLabel()
	local guideSize =  display.getLabelContentSize(guideLabel)
	if guideSize.width > 60 then
		local pos = cc.p( guideLabel:getPosition())
		guideLabel:setAnchorPoint(display.RIGHT_CENTER)
		--local posX = pos.x -  ( guideSize.width - 120)
		guideLabel:setPosition(pos.x  +35 , pos.y)
		local currentScale = guideLabel:getScale()
		guideLabel:setScale(currentScale * 0.7)
	end
	bgLayout:addChild(guidBtn,10)
	guidBtn:setPosition(cc.p(bgSize.width - 65 ,bgSize.height -110 ))
	if not GuideUtils.IsGuiding() then --如果在引导的逻辑中时
		if isGuideOpened('recipe') then
			local guideNode = require('common.GuideNode').new({tmodule = 'recipe'})
				  display.commonUIParams(guideNode, { po = display.center})
		   sceneWorld:addChild(guideNode, GameSceneTag.Guide_GameSceneTag)
		end
	end
	local searchBtn = display.newButton(20,topTopSize.height/2 -5 , {scale9 = true  , ap = display.LEFT_CENTER, n = _res('ui/home/kitchen/kitchen_btn_foods_pokedex.png') , s =  _res('ui/home/kitchen/kitchen_btn_foods_pokedex.png') } )
	local searchBtnSize = searchBtn:getContentSize()
	local searchImage = display.newImageView(RES_DICT.SearchRecipe,0,searchBtnSize.height/2, { ap = display.LEFT_CENTER})
	local searchImageSize = searchImage:getContentSize()
	local searchLabel = display.newLabel( searchImageSize.width + 10, searchBtnSize.height/2, fontWithColor('10',{ ap = display.LEFT_CENTER,text =  __('菜谱图鉴') , color = "#ffffff" }))
	local searchLabelSize = display.getLabelContentSize(searchLabel)
	local searchLayoutSize =  cc.size(searchLabelSize.width +searchImageSize.width +10, searchBtnSize.height )
	searchBtnSize = cc.size(searchLayoutSize.width + 10 , searchBtnSize.height)
	local searchLayout = display.newLayer(searchBtnSize.width/2, searchBtnSize.height/2, { ap = display.CENTER , size = searchLayoutSize})
	searchLayout:addChild(searchLabel)
	searchLayout:addChild(searchImage)

	searchBtn:addChild(searchLayout)
	searchBtn:setContentSize(searchBtnSize)

	topTopLayout:addChild(searchBtn)
	searchBtn:setTag(BtnCollect.CURRENT_RESEARCH_STYLE)
	local handbookBtn = display.newButton(bgSize.width -18 ,topTopSize.height/2 -5 , {scale9 = true ,  ap = display.RIGHT_CENTER , n = _res('ui/home/kitchen/kitchen_btn_foods_pokedex.png') , s =  _res('ui/home/kitchen/kitchen_btn_foods_pokedex.png') } )
	topTopLayout:addChild(handbookBtn)


	display.commonLabelParams(handbookBtn , fontWithColor(10 , { fontSize = 20 , color = "ffffff" , text = __('食材图鉴'), w = 250 ,hAlign = display.TAC }))
	handbookBtn:setTag(BtnCollect.FOOD_METARIAL)

	local handbookBtnSize = handbookBtn:getContentSize()
	local handbookBtnLabelSize  = display.getLabelContentSize(handbookBtn:getLabel())
	local width = handbookBtnLabelSize.width > handbookBtnSize.width and (handbookBtnLabelSize.width )   or handbookBtnSize.width
	handbookBtn:setContentSize(cc.size(width+20 , handbookBtnSize.height))
	handbookBtn:setContentSize(cc.size(width+20 , handbookBtnSize.height))

	local progressLabel = display.newLabel(70 ,topTopSize.height/2 - 5 ,fontWithColor('16', {ap = display.LEFT_CENTER ,text = "ghfhgffhfgh"}))
	topTopLayout:addChild(progressLabel)
	progressLabel:setOpacity(0)
	local topBgImage = display.newImageView(RES_DICT.STUDY_BG)

	local topSize = topBgImage:getContentSize()
	local topLayout =CLayout:create(topSize)
	-- 设置顶部坐标 添加图片
	topLayout:setAnchorPoint(display.CENTER_TOP)
	topBgImage:setPosition(cc.p(topSize.width/2 , topSize.height/2))
	topLayout:addChild(topBgImage)
	topLayout:setPosition(cc.p(bgSize.width/2,bgSize.height - offsetHeight))
	bgLayout:addChild(topLayout)

	local studyWordsImage = display.newImageView(RES_DICT.STUDY_BG_WORDS,topSize.width/2,topSize.height,{ap = display.CENTER_TOP})
	topLayout:addChild(studyWordsImage)
	local studyWordsImageSize  = studyWordsImage:getContentSize()
	-- 顶部图片的说明
	local studyWordsLabel = display.newLabel(10,studyWordsImageSize.height/2 , fontWithColor('18', {ap = display.LEFT_CENTER  , text = __('放入1~3种材料可以开发新美食')}))
	studyWordsImage:addChild(studyWordsLabel)
	local studyWordsLabelSize  =  display.getLabelContentSize(studyWordsLabel)
	local scale =  490 > studyWordsLabelSize.width and  1 or  490/( studyWordsLabelSize.width +10)
	local currentScale =  studyWordsLabel:getScale()
	studyWordsLabel:setScale(scale*currentScale)
	local foodsBtns =  {}
	local studyFoodsBg = display.newImageView(RES_DICT.STUDY_FOODS)
	local studyFoodsSize = studyFoodsBg:getContentSize()


	local offsetWidth = 5
	local studyFoodsAllSize = cc.size(studyFoodsSize.width *3+ (3-1) *offsetWidth,studyFoodsSize.height)
	-- 这个里面存放的是学习的材料
	local studyAllLayout = CLayout:create(studyFoodsAllSize)
	studyAllLayout:setPosition(cc.p(topSize.width/2,150))
	topLayout:addChild(studyAllLayout)
	local foodsBtnsPos = {}
	for i = 1 ,3 do
		 local studyFoodsBg = display.newImageView(RES_DICT.STUDY_FOODS)
		 studyFoodsBg:setTouchEnabled(true)
		 studyFoodsBg:setTag(i)
		 studyFoodsBg:setPosition(cc.p((i - 0.5 ) *studyFoodsSize.width +(i-1) *offsetWidth,studyFoodsSize.height/2 ))
		 local studyFoodsBgLight = display.newImageView(RES_DICT.STUDY_FOODS_LIGHT,studyFoodsSize.width/2,studyFoodsSize.height/2)
		 studyFoodsBgLight:setTag(113)
		 studyFoodsBgLight:setVisible(false)
		 studyFoodsBg:addChild(studyFoodsBgLight)

		 local foodsBtn = display.newButton(studyFoodsSize.width/2,-10, { ap = display.CENTER_BOTTOM, n = RES_DICT.STUDY_FOODS_NAME_BG, s =  RES_DICT.STUDY_FOODS_NAME_BG , d =  RES_DICT.STUDY_FOODS_NAME_BG ,scale9 = true , size =  cc.size(125,50)})
		 studyFoodsBg:addChild(foodsBtn)
		 studyAllLayout:addChild(studyFoodsBg)
		 -- 设置tag 值 用于寻找当前按钮的名称
		 -- 如果添加时候 会在这个里面设置值为112
		 foodsBtn:setTag(111)
		 studyFoodsBg.foodsBtn = foodsBtn
		 display.commonLabelParams(foodsBtn,fontWithColor('16',{text = "" ,fontSize = 20 , w = 120 ,hAlign = display.TAC }))
		 foodsBtns[#foodsBtns+1] = studyFoodsBg
		 foodsBtnsPos[#foodsBtnsPos+1] = cc.p(studyFoodsBg:getPositionX(),studyFoodsBg:getPositionY())

	end

	foodsBtns[2]:setLocalZOrder(10)
	-- 开发的结果 首先设置的是隐藏
	local studyBgBtnTips = nil
	if isJapanSdk() then
		local pos = self.bgLayout:convertToNodeSpace(cc.p(display.cx, display.cy + 160))
		studyBgBtnTips = display.newButton(pos.x, pos.y, 
			{n =RES_DICT.COOKING_STUDYBG_TIPS,s = RES_DICT.COOKING_STUDYBG_TIPS,d = RES_DICT.COOKING_STUDYBG_TIPS ,enable = false, scale9 = true, size = cc.size(760, 32)})
		self.bgLayout:addChild(studyBgBtnTips,10)
	else
		studyBgBtnTips = display.newButton(studyFoodsAllSize.width/2,studyFoodsAllSize.height/2, {n =RES_DICT.COOKING_STUDYBG_TIPS,s = RES_DICT.COOKING_STUDYBG_TIPS,d = RES_DICT.COOKING_STUDYBG_TIPS ,enable = false})
		studyAllLayout:addChild(studyBgBtnTips,10)
	end

	display.commonLabelParams(studyBgBtnTips,fontWithColor('18',{text = "   "}))
	studyBgBtnTips:setVisible(false)

	local makingBtn = display.newButton(topSize.width/2,37,{ n = RES_DICT.BTN_ORANGE, s = RES_DICT.BTN_ORANGE , d = RES_DICT.BTN_DISABLED, enable = true ,animate = true})
	display.commonLabelParams(makingBtn,fontWithColor('14',{text = __('开发')}))
	topLayout:addChild(makingBtn)
	makingBtn:setName("makingBtn")
	topLayout:setName("topLayout")
	makingBtn:setTag(BtnCollect.RESEARCH_RSEARCH)
	local rewardBtn = display.newButton(topSize.width/2,37,{ n = RES_DICT.BTN_ORANGE, s = RES_DICT.BTN_ORANGE ,enable = true ,animate = true})
	display.commonLabelParams(rewardBtn,fontWithColor('14',{text = __('领取')}))
	topLayout:addChild(rewardBtn)
	rewardBtn:setTag(BtnCollect.RESEARCH_REWARD)
	rewardBtn:setVisible(false)
	local cancelBtn = display.newButton(topSize.width/2 -100,37,{ n = RES_DICT.BTN_SELECT, s = RES_DICT.BTN_ORANGE ,enable = true ,animate = true})
	display.commonLabelParams(cancelBtn,fontWithColor('14',{text = __('取消')}))
	topLayout:addChild(cancelBtn)
	cancelBtn:setVisible(false)
	cancelBtn:setTag(BtnCollect.RESEARCH_CANCEL)
	local quickBtn = display.newButton(topSize.width/2 +100 ,37,{ n = RES_DICT.BTN_ORANGE, s = RES_DICT.BTN_ORANGE ,enable = true ,animate = true})
	display.commonLabelParams(quickBtn,fontWithColor('14',{fontSize = 20 , text = __('立即完成')}))
	quickBtn:setName("quickBtn")
	topLayout:addChild(quickBtn)
	local btnSize = quickBtn:getContentSize()
	quickBtn:getLabel():setPosition(cc.p(btnSize.width/2 ,btnSize.height/4*1+5))
	quickBtn:setVisible(false)
	quickBtn:setTag(BtnCollect.RESEARCH_QUCIK)
	local richLabel = display.newRichLabel(btnSize.width/2 ,btnSize.height/4*3 - 2,{ c ={
		fontWithColor('14',({text = "100" })) ,
		{img = CommonUtils.GetGoodsIconPathById(DIAMOND_ID), scale = 0.2}
	}})
	quickBtn:addChild(richLabel)

	local  fontNameBtn = display.newButton(30,bgSize.height -297 -offsetHeight + 20, {ap = display.LEFT_CENTER ,scale9 = true , n = RES_DICT.FONT_NAME_BTN,s =RES_DICT.FONT_NAME_BTN ,enable  = false,ap = display.LEFT_CENTER})
	display.commonLabelParams(fontNameBtn,fontWithColor('16',{text = __('我的食材') , paddingW = 20 }) )

	bgLayout:addChild(fontNameBtn)
	local tipBtn  = display.newButton(fontNameBtn:getContentSize().width +30   ,bgSize.height -297 -offsetHeight+20 ,{n = RES_DICT.BTN_TIPS, enable = true,s =RES_DICT.BTN_TIPS,cb = function ()
		uiMgr:ShowInformationTips(__('可以自由选择食材来进行开发,每种食材只消耗一个。'))
	end,ap = display.CENTER})
	bgLayout:addChild(tipBtn)

	local foodGridbgSize = cc.size(560,333 - offsetHeight+20)
	local foodGridBgLayout =CLayout:create(foodGridbgSize)
	foodGridBgLayout:setAnchorPoint(display.CENTER_TOP)
	foodGridBgLayout:setPosition(cc.p(bgSize.width/2,bgSize.height - 318-offsetHeight+20))
	bgLayout:addChild(foodGridBgLayout)
	bgLayout:setName("researchLayout")
	local foodGridImage = display.newImageView(RES_DICT.GOODS_BG,foodGridbgSize.width/2,foodGridbgSize.height/2, { scale9 = true , size = foodGridbgSize})
	foodGridBgLayout:addChild(foodGridImage)
	local foodsGridSize = cc.size(555,324-offsetHeight+20)
	local foodGridCellSize = cc.size(555/5,111)
	local foodGridView = CGridView:create(foodsGridSize)
	foodGridView:setSizeOfCell(foodGridCellSize)
	foodGridView:setColumns(5)
	foodGridView:setAnchorPoint(display.CENTER)
	foodGridView:setAutoRelocate(true)
	foodGridView:setName("foodGridView")
	foodGridView:setPosition(cc.p(foodGridbgSize.width/2,foodGridbgSize.height/2))
	foodGridBgLayout:addChild(foodGridView)
	foodGridBgLayout:setName("foodGridBgLayout")
	return {
		view = bgLayout ,
		searchBtn = searchBtn ,
		handbookBtn = handbookBtn ,
		foodsBtns = foodsBtns,
		studyBgBtnTips = studyBgBtnTips ,
		makingBtn = makingBtn,
		cancelBtn = cancelBtn ,
		quickBtn = quickBtn ,
		tipBtn = tipBtn ,
		rewardBtn  =rewardBtn ,
		richLabel = richLabel ,
		foodGridView = foodGridView ,
		foodsBtnsPos = foodsBtnsPos ,
		studyWordsLabel = studyWordsLabel ,
		topLayout = topLayout ,
		progressLabel = progressLabel
	}
end

function RecipeResearchAndMakingView:createSpecialLayout(bgSize)
	-- body
	local bgLayout = CLayout:create(bgSize)
	local listViewSize = cc.size(570,630)
	local listView  = CListView:create(listViewSize)
	listView:setAnchorPoint(display.CENTER)
	listView:setPosition(cc.p(bgSize.width/2+2,bgSize.height/2))
	listView:setDirection(eScrollViewDirectionVertical)
	listView:setBounceable(true)
	bgLayout:addChild(listView)
	return {
		view = bgLayout ,
		listView = listView
	}
end
function RecipeResearchAndMakingView:createSpecialCell(data)
	data = data or {}
	local name  = data.name -- 这个地方赋值是专精的名称
	local isLock =  gameMgr:GetUserInfo().cookingStyles[tostring(data.id) ]  or false -- 这个是专精是否解锁
	local id = data.id or  1
	local bgImage = FilteredSpriteWithOne:create(_res(string.format( "ui/home/kitchen/cooking_mastery_title_bg_%d.png",data.id )))
	if not bgImage or tolua.isnull(bgImage) then
		bgImage = FilteredSpriteWithOne:create(_res(string.format( "ui/home/kitchen/cooking_mastery_title_bg_%d.png",1 )))
	end
 	local cellSize = cc.size(bgImage:getContentSize().width,bgImage:getContentSize().height+4)
	local selectImage  = display.newImageView(RES_DICT.SELECT_SPECIAL_IMAGE ,cellSize.width/2,cellSize.height/2  )
	selectImage:setVisible(true)
	selectImage:setTag(111)
	bgImage:setPosition(cc.p(cellSize.width/2,cellSize.height/2))
	bgImage:setTag(116)
	local cellLayout = CLayout:create(cellSize)
	local contentLayer = display.newLayer(cellSize.width/2,cellSize.height/2, {ap = display.CENTER ,size=cellSize ,color = cc.c4b(0,0,0,0) ,enable = true})
	cellLayout:addChild(contentLayer,2)
	contentLayer:addChild(selectImage ,3)
	contentLayer:addChild(bgImage)
	local titleImage  = display.newImageView(RES_DICT.SPECIAL_NAME_TITLE,0,cellSize.height/2 , { ap = display.LEFT_CENTER})
	contentLayer:addChild(titleImage)
	local titleSize = titleImage:getContentSize()

	local specialName = display.newLabel(20, titleSize.height/2 ,fontWithColor('19', {text = name, ap =display.LEFT_CENTER , fontSize = 30 }))
	titleImage:addChild(specialName)
	if not isLock then
		titleImage:setTexture(RES_DICT.UN_SPECIAL_NAME_TITLE)
		bgImage:setFilter(filter.newFilter('GRAY'))
		local lockIcon =  display.newImageView(RES_DICT.ICON_LOCK , cellSize.width - 36, cellSize.height/2 ,{enable = false})
		contentLayer:addChild(lockIcon)
		cellLayout.lockIcon = lockIcon
		local unLuckLabel = display.newLabel(0,0, { fontSize = 22 ,  color ="ffe6ab" ,font = TTF_GAME_FONT, ttf = true,text = __('点击解锁') })
		unLuckLabel:enableOutline(cc.c4b(70,39,26,255), 2)
		local unLuckSize = display.getLabelContentSize(unLuckLabel)
		unLuckLabel:setPosition(cc.p(unLuckSize.width/2,unLuckSize.height/2))
		local unLuckBtn = display.newLayer(cellSize.width - 30,cellSize.height/2 ,{ap = display.RIGHT_CENTER , font = TTF_GAME_FONT,size = unLuckSize })
		unLuckBtn:setVisible(false)
		unLuckBtn:addChild(unLuckLabel)
		cellLayout:addChild(unLuckBtn,3)
		cellLayout.unLuckBtn = unLuckBtn
		cellLayout.unLuckLabel = unLuckLabel
	end
	cellLayout.titleImage = titleImage
	cellLayout.contentLayer = contentLayer
	cellLayout.id = id
	cellLayout.selectImage = selectImage
	cellLayout.bgImage = bgImage
	return cellLayout
end

function RecipeResearchAndMakingView:createSpecialSelect(cell)
	--local name = self.styleTable[tostring(cell.id)].name
	local decName = self.styleTable[tostring(cell.id)].content  -- 这个是关于菜谱专精的介绍
	local value_Common =  0
	local value_Special = 0
	local data = gameMgr:GetUserInfo().cookingStyles[tostring(cell.id)]

	for k , v in pairs(data) do
		local recipeData = self.recipeData[tostring(v.recipeId)]
		if checkint(recipeData.canStudyUnlock) == 1    then
			value_Common = value_Common +1
		elseif checkint(recipeData.canStudyUnlock) == 0  then
			value_Special = value_Special +1
		end
	end
	local value_CommomMax =  checkint(self.styleTable[tostring(cell.id)].studyRecipe)
	local Value_SpecialMax = checkint(self.styleTable[tostring(cell.id)].rewardsRecipe)
	local layerSize =  cell.contentLayer:getContentSize()
	local desSize = cc.size(565,230)
	local cellSize = cc.size( layerSize.width ,desSize.height + layerSize.height + 2)
	cell:setContentSize(cellSize)
	local desLayout  = display.newLayer(cellSize.width/2, 2+1,{ap = display.CENTER_BOTTOM , size = desSize ,enable = false })
	cell:addChild(desLayout)
	cell.contentLayer:setPosition(cc.p(cellSize.width/2,layerSize.height/2 + desSize.height))
	local bgImage  = display.newImageView(RES_DICT.CONTAINERBG,cellSize.width/2,desSize.height/2+2 , { scale9 = true , size = desSize})
	desLayout:addChild(bgImage)
	desLayout:setTag(111)
	local bottomSize = cc.size(557,90)
	local bottomImage =CLayout:create(bottomSize)

	bottomImage:setAnchorPoint(display.CENTER_BOTTOM)
	bottomImage:setPosition(cc.p( desSize.width/2-1 ,10))

	desLayout:addChild(bottomImage)
	local splitLine = display.newImageView(RES_DICT.SPLIT_LINE,bottomSize.width/2, bottomSize.height+5)
	bottomImage:addChild(splitLine)
	local bottomImageSize = bottomImage:getContentSize()
	local posCommon = cc.p(140, 35)
	if value_CommomMax > 0 then
		if Value_SpecialMax > 0 then
			posCommon = cc.p(140, 35)

		else
			posCommon = cc.p(bottomImageSize.width/2, 35)
		end
		local expBarCommon = CProgressBar:create(RES_DICT.COOKING_BAR2)
		expBarCommon:setBackgroundImage(RES_DICT.COOKING_BAR)
		expBarCommon:setDirection(eProgressBarDirectionLeftToRight)
		expBarCommon:setMaxValue(value_CommomMax)
		expBarCommon:setValue(value_Common)
		expBarCommon:setShowValueLabel(true)
		expBarCommon:setPosition(posCommon)
		expBarCommon:setAnchorPoint(display.CENTER)
		display.commonLabelParams(expBarCommon:getLabel(),fontWithColor('18'))
		bottomImage:addChild(expBarCommon)
		cell.expBarCommon = expBarCommon
		local expBarCommonSize = expBarCommon:getContentSize()
		local commonRecipeLable =display.newLabel(expBarCommonSize.width/2,expBarCommonSize.height,fontWithColor('8',{ ap = display.CENTER_BOTTOM,text = __('基础菜谱')}))
		expBarCommon:addChild(commonRecipeLable)
	end
	local posSpecial = cc.p(370, 35)
	if Value_SpecialMax > 0 then
		if value_CommomMax > 0 then
			posSpecial = cc.p(370, 35)
		else
			posSpecial = cc.p(bottomImageSize.width/2, 35)
		end
		local expBarSpecial = CProgressBar:create(RES_DICT.COOKING_BAR1)
		local expBarSpecialSize = expBarSpecial:getContentSize()
		expBarSpecial:setBackgroundImage(RES_DICT.COOKING_BAR)
		expBarSpecial:setDirection(eProgressBarDirectionLeftToRight)
		expBarSpecial:setMaxValue(Value_SpecialMax)
		expBarSpecial:setValue(value_Special)
		expBarSpecial:setShowValueLabel(true)
		expBarSpecial:setPosition(posSpecial)
		expBarSpecial:setAnchorPoint(display.CENTER)
		cell.expBarSpecial = expBarSpecial
		display.commonLabelParams(expBarSpecial:getLabel(),fontWithColor('18'))
		bottomImage:addChild(expBarSpecial)
		local specialRecipeLable =display.newLabel(expBarSpecialSize.width/2,expBarSpecialSize.height,fontWithColor('8',{ ap = display.CENTER_BOTTOM,text = __('稀有菜谱')}))
		expBarSpecial:addChild(specialRecipeLable)
	end

	local spearSearchBtn = display.newButton(530-20,63-18,{
		n = _res('ui/home/kitchen/cooking_btn_pokedex_2.png') ,
		s =  _res('ui/home/kitchen/cooking_btn_pokedex_2.png') ,
		d =  _res('ui/home/kitchen/cooking_btn_pokedex_2.png')
	})
	desLayout:addChild(spearSearchBtn,3)

	spearSearchBtn:setTag(BtnCollect.SEARCH_BTN)
	local  topSize =  cc.size(557,130)
	local topImage  = CLayout:create(topSize)
	topImage:setAnchorPoint(display.CENTER_BOTTOM)
	topImage:setPosition(cc.p(desSize.width/2,bottomSize.height+10))
	desLayout:addChild(topImage)
	local recipeContentLabel = display.newLabel(topSize.width/2 , topSize.height - 25 , fontWithColor('8',{text = decName ,w = 450 , ap = display.CENTER_TOP , hAlign = display.TAL }) )
	topImage:addChild(recipeContentLabel)
	cell.spearSearchBtn = spearSearchBtn
	spearSearchBtn.id  = cell.id
end
-- 添加单个功能模块的leyer
function RecipeResearchAndMakingView:addShowLayer(layer,num )
	num = num or 1
	self.leftLayout:addChild(layer,num)
	layer:setPosition(cc.p(self.leftLayoutSize.width/2 ,self.leftLayoutSize.height/2))
end
return RecipeResearchAndMakingView
