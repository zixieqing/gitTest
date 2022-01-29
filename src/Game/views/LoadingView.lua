--[[
资源加载场景
@params table {
    isInit boolean 是否是第一次进入时的数据加载
	loadTasks function 开始加载逻辑回调
	done function 完成加载逻辑回调
    battleLoadingType BattleLoadingSceneType 是否显示战斗提示
    stageId int 关卡id
}
--]]
local GameScene = require('Frame.GameScene')
local LoadingView = class('LoadingView', GameScene)

------------ import ------------
------------ import ------------

------------ define ------------
local DICT = {
    Progress_Bg = "update/update_bg_loading.png",
    Progress_Image = "update/update_ico_loading.png",
    Progress_Top = "update/update_ico_loading_fornt.png",
    Progress_Descr = "update/update_bg_refresh_number.png",
}

-- 加载图类型
local LoadingViewType = {
    FIRST_PERFORMANCE                   = -1,       -- 首场演示大战
    BASE                                = 0,
    BATTLE_TIP                          = 1,        -- 一本正经的战斗提示
    COMMON_CG                           = 2,        -- 普通cg
    SEASON_ACT                          = 101,      -- 季活
    MONSTER_NIAN                        = 102,      -- 年兽活动
    WB_ALUNA                            = 103,      -- 世界boss 阿卢那
    SUMMER_ACT                          = 104,      -- 夏活
    DEFAULT                             = 999       -- 默认类型
}

-- 特殊加载图id段 闭区间
local SpecialLoadingStage = {
    [LoadingViewType.FIRST_PERFORMANCE] = {
        stageInfo           = {lower = FIRST_PERFORMANCE_STAGE_ID, upper = FIRST_PERFORMANCE_STAGE_ID},
        loadingViewType     = LoadingViewType.FIRST_PERFORMANCE
    },
    [LoadingViewType.MONSTER_NIAN] = {
        stageInfo           = {lower = 6201, upper = 6224},
        loadingViewType     = LoadingViewType.MONSTER_NIAN
    },
    [LoadingViewType.WB_ALUNA] = {
        stageInfo           = {lower = 20001, upper = 20200},
        loadingViewType     = LoadingViewType.WB_ALUNA
    },
    [LoadingViewType.SUMMER_ACT] = {
        stageInfo           = {lower = 7000, upper = 7900},
        loadingViewType     = LoadingViewType.SUMMER_ACT
    }
}

-- 加载图路径
local LoadingViewPathConfig = {
    [LoadingViewType.FIRST_PERFORMANCE] = {
        'arts/common/loading_view_0.jpg',
    },
    [LoadingViewType.BATTLE_TIP] = {
        'arts/common/loading_view_remind_1.jpg',
        'arts/common/loading_view_remind_1.jpg',
        'arts/common/loading_view_remind_3.jpg',
        'arts/common/loading_view_remind_4.jpg'
    },
    [LoadingViewType.COMMON_CG] = {
        'arts/common/loading_view_1.jpg',
        'arts/common/loading_view_2.jpg',
        'arts/common/loading_view_3.jpg',
        'arts/common/loading_view_4.jpg',
        'arts/common/loading_view_5.jpg',
        'arts/common/loading_view_6.jpg',
        'arts/common/loading_view_20.jpg',
        'arts/common/loading_view_27.jpg',
        ------------ 2018新年loading ------------
        -- 'arts/common/loading_view_9.jpg',
        -- 'arts/common/loading_view_10.jpg',
        -- 'arts/common/loading_view_11.jpg',
        -- 'arts/common/loading_view_12.jpg',
        ------------ 2018新年loading ------------
        'arts/common/loading_view_14.jpg',
        'arts/common/loading_view_15.jpg',
        'arts/common/loading_view_16.jpg',
        'arts/common/loading_view_17.jpg',
        ------------ 2019猪年新年loading ------------
        'arts/common/loading_view_21.jpg',
        'arts/common/loading_view_22.jpg',
        'arts/common/loading_view_23.jpg',
        'arts/common/loading_view_24.jpg',
        'arts/common/loading_view_25.jpg',
        'arts/common/loading_view_26.jpg'
        ------------ 2019猪年新年loading ------------
        -- 'arts/common/loading_view_19.jpg' --国内这张图被投诉删除不出现
    },
    [LoadingViewType.SEASON_ACT] = {
        'arts/common/loading_view_7.jpg'
    },
    [LoadingViewType.MONSTER_NIAN] = {
        'arts/common/loading_view_8.jpg'
    },
    [LoadingViewType.WB_ALUNA] = {
        'arts/common/loading_view_13.jpg'
    },
    [LoadingViewType.SUMMER_ACT] = {
        'arts/common/loading_view_18.jpg'
    }
}

-- 加载图随机数精度
local LoadingViewRandomAccuracy = 1000
local LoadingViewRandomAccuracyRec = 0.001
------------ define ------------
--[[
constructor
--]]
function LoadingView:ctor( ... )
    GameScene.ctor(self, 'Game.views.LoadingView')
    self:setName('Game.views.LoadingView')
	local args = unpack({...})
    local isInit = args.isInit or false
    local battleLoadingType = args.battleLoadingType
    local stageId = args.stageId

    local function CreateView()

        -- 随机一张背景图
        utils.newrandomseed()

        local loadingImgPath = self:GetLoadingBgPathByStageId(stageId)
        local __bg = display.newImageView(_res(loadingImgPath), display.cx, display.cy)
        self:addChild(__bg)

        -- 进度条
        local loadingBarBg = display.newImageView(_res('update/update_bg_black.png'), 0, 0, {scale9 = true, size = cc.size(display.width, 209)})
        display.commonUIParams(loadingBarBg, {po = cc.p(display.cx, 0), ap = cc.p(0.5, 0)})
        self:addChild(loadingBarBg)
        -- loadingBarBg:setVisible(false)

        local loadingBar = CProgressBar:create(_res(DICT.Progress_Image))
        loadingBar:setBackgroundImage(_res(DICT.Progress_Bg))
        loadingBar:setDirection(0)
        loadingBar:setMaxValue(100)
        loadingBar:setValue(0)
        loadingBar:setPosition(cc.p(display.cx, 105))
        self:addChild(loadingBar, 1)

        -- 进度条闪光
        local loadingBarShine = display.newNSprite(_res('update/update_ico_light.png'), 0, loadingBar:getPositionY())
        self:addChild(loadingBarShine, 2)
        local percent = loadingBar:getValue() / loadingBar:getMaxValue()
        loadingBarShine:setPositionX(loadingBar:getPositionX() - loadingBar:getContentSize().width * 0.5 + loadingBar:getContentSize().width * percent - 1)
        -- loadingBarShine:setOpacity(255 * percent)
        -- local loadingBarShineActionSeq = cc.RepeatForever:create(cc.Sequence:create(
        --     cc.FadeTo:create(4, 0),
        --     cc.FadeTo:create(4, 255)))
        -- loadingBarShine:runAction(loadingBarShineActionSeq)

        -- 提示
        local loadingTipsBg = display.newImageView(_res('update/loading_bg_tips.png'))
        display.commonUIParams(loadingTipsBg,
            {ap = cc.p(0.5, 1), po = cc.p(loadingBar:getPositionX(), loadingBar:getPositionY() - loadingBar:getContentSize().height * 0.5 - 3)})
        self:addChild(loadingTipsBg, 1)

        local tipsData = CommonUtils.GetConfigAllMess('loadingTips','common')
        local text = ''
        if tipsData then
            utils.newrandomseed()
            local len = table.nums(tipsData)
            local pos = math.random(1,len)
            text = tipsData[tostring(pos)].substance
        end

        local padding = cc.p(20, 7)
        local loadingTipsLabel = display.newLabel(padding.x, loadingTipsBg:getContentSize().height - padding.y,
            {text = text,
            fontSize = fontWithColor('18').fontSize, color = fontWithColor('18').color, ap = cc.p(0, 1), hAlign = display.TAL,
            w = loadingTipsBg:getContentSize().width - padding.x * 2, h = loadingTipsBg:getContentSize().height - padding.y * 2})
        loadingTipsBg:addChild(loadingTipsLabel)

        -- 小人和加载文字
        local avatarAnimationName = 'loading_avatar'
        local animation = cc.AnimationCache:getInstance():getAnimation(avatarAnimationName)
        if nil == animation then
            animation = cc.Animation:create()
            for i = 1, 10 do
                animation:addSpriteFrameWithFile(_res(string.format('update/loading_run_%d.png', i)))
            end
            animation:setDelayPerUnit(0.05)
            animation:setRestoreOriginalFrame(true)
            cc.AnimationCache:getInstance():addAnimation(animation, avatarAnimationName)
        end

        local loadingAvatar = display.newNSprite(_res('update/loading_run_1.png'), 0, 0)
        loadingAvatar:setPositionY(loadingBar:getPositionY() + loadingBar:getContentSize().height * 0.5 + loadingAvatar:getContentSize().width * 0.5 + 10)
        self:addChild(loadingAvatar, 5)
        loadingAvatar:runAction(cc.RepeatForever:create(cc.Animate:create(animation)))

        local loadingLabelBg = display.newImageView(_res('update/bosspokedex_name_bg.png'))
        loadingLabelBg:setPositionY(loadingAvatar:getPositionY() - 8)
        self:addChild(loadingLabelBg, 4)

        local loadingLabel = display.newLabel(utils.getLocalCenter(loadingLabelBg).x - 20, utils.getLocalCenter(loadingLabelBg).y - 2,fontWithColor('14',
            {text = __('正在载入'), fontSize = 24, color = '#ffffff'}))
        loadingLabel:enableOutline(ccc4FromInt('290c0c'), 1)
        loadingLabelBg:addChild(loadingLabel)

        local offsetX = -25
        local totalWidth = loadingAvatar:getContentSize().width + loadingLabelBg:getContentSize().width + offsetX
        local baseX = display.cx
        local loadingAvatarX = baseX - totalWidth * 0.5 + loadingAvatar:getContentSize().width * 0.5
        local loadingLabelBgX = loadingAvatarX + loadingAvatar:getContentSize().width * 0.5 + offsetX + loadingLabelBg:getContentSize().width * 0.5
        loadingAvatar:setPositionX(loadingAvatarX)
        loadingLabelBg:setPositionX(loadingLabelBgX)

        return {
            loadingBar = loadingBar,
            loadingBarShine = loadingBarShine
        }

    end

    self.viewData = CreateView()

    -- controller logic
	cc.Director:getInstance():getTextureCache():removeUnusedTextures()
    PlayAudioClip("ty_8")
    --EVENTLOG.Log(EVENTLOG.EVENTS.loadStart)
    if isInit then
        local dataManager = AppFacade.GetInstance():GetManager("DataManager")
        dataManager:InitialDatasAsync(function ( event )
            if event.event == 'done' then
                --EVENTLOG.Log(EVENTLOG.EVENTS.loadEnd)
                PlayAudioClip("stop_ty_8")
                local HomeMediator = require( 'Game.mediator.HomeMediator')
                local mediator = HomeMediator.new()
                AppFacade.GetInstance():RegistMediator(mediator)
            elseif event.event == 'progress' then
                self.viewData.loadingBar:setValue((event.progress / 100) * 100)
                local str = string.format('%.1f %%',(event.progress / 100) * 100)
                -- self.viewData.loadingBar:getLabel():setString(str)
                local percent = event.progress * 0.01
                -- self.viewData.loadingBarShine:setOpacity(255 * percent)
                self.viewData.loadingBarShine:setPositionX(
                    self.viewData.loadingBar:getPositionX() - self.viewData.loadingBar:getContentSize().width * 0.5 +
                    self.viewData.loadingBar:getContentSize().width * percent - 1)
            end
        end)
    else
        local loader = CCResourceLoader:getInstance()
        loader:registerScriptHandler(function ( event )
            --回调加载的进步以及是否完成的逻辑
            if event.event == 'done' then
                --EVENTLOG.Log(EVENTLOG.EVENTS.loadEnd)
                print('!!! <- loading complete -> !!!')
                PlayAudioClip("stop_ty_8")
                if args.done then
                    args.done()
                end
                self.resLoader_ = nil
            elseif event.event == 'progress' then
                self.viewData.loadingBar:setValue((event.progress / 100) * 100)
                local str = string.format('%.1f %%',(event.progress / 100) * 100)
                -- self.viewData.loadingBar:getLabel():setString(str)
                local percent = event.progress * 0.01
                -- self.viewData.loadingBarShine:setOpacity(255 * percent)
                self.viewData.loadingBarShine:setPositionX(
                    self.viewData.loadingBar:getPositionX() - self.viewData.loadingBar:getContentSize().width * 0.5 +
                    self.viewData.loadingBar:getContentSize().width * percent - 1)
            end
        end)
        -- 开始加载
        if args.loadTasks then
            args.loadTasks()
            self.resLoader_ = loader
            loader:run()
        end
    end
end
--[[
根据关卡id获取loading图路径
@params stageId int 关卡id
@return path string loading图路径
--]]
function LoadingView:GetLoadingBgPathByStageId(stageId)
    -- 重置一次随机种子
    math.randomseed(string.reverse(tostring(os.time())))
    
    ------------ 读取配置的关卡loading图id ------------
    local path = self:GetStageConfigLoadingPathByStageId(stageId)
    if nil ~= path then return path end
    ------------ 读取配置的关卡loading图id ------------

    path = LoadingViewPathConfig[LoadingViewType.FIRST_PERFORMANCE][1]

    local stageId_ = checkint(stageId)
    if nil == stageId then
        path = self:GetDefaultLoadingBgPath()
    elseif 3 >= stageId_ then
        path = LoadingViewPathConfig[LoadingViewType.BATTLE_TIP][1]
    else
        local loadingViewType = self:GetLoadingViewTypeByStageId(stageId)
        if LoadingViewType.DEFAULT == loadingViewType then
            -- 默认规则
            path = self:GetDefaultLoadingBgPath()
        else
            -- 特殊规则
            path = self:GetLoadingBgPathByLoadingViewType(loadingViewType)
        end
    end
    return path
end
--[[
根据关卡id获取loading图类型
@params stageId int 关卡id
@return loadingViewType LoadingViewType 加载图类型
--]]
function LoadingView:GetLoadingViewTypeByStageId(stageId)
    local stageId_ = checkint(stageId)
    local loadingViewType = LoadingViewType.DEFAULT

    if nil == stageId then
        return LoadingViewType.DEFAULT
    elseif 3 >= stageId_ then
        return LoadingViewType.DEFAULT
    else
        -- 遍历一次特殊关卡
        for k,v in pairs(SpecialLoadingStage) do
            if v.stageInfo.lower <= stageId and v.stageInfo.upper >= stageId then
                loadingViewType = v.loadingViewType
                break
            end
        end
    end
    return loadingViewType
end
--[[
获取默认的loading图路径
@return path loading图路径
--]]
function LoadingView:GetDefaultLoadingBgPath()
    -- 40%几率出提示 60%几率出cg
    local randomConfig = {
        {
            randomInfo = {lower = 0 * LoadingViewRandomAccuracy + 1, upper = 0.4 * LoadingViewRandomAccuracy},
            loadingViewType = LoadingViewType.BATTLE_TIP
        },
        {
            randomInfo = {lower = 0.4 * LoadingViewRandomAccuracy + 1, upper = 1 * LoadingViewRandomAccuracy},
            loadingViewType = LoadingViewType.COMMON_CG
        }
    }

    local path = ''
    local loadingViewType = LoadingViewType.COMMON_CG
    local random = math.random(LoadingViewRandomAccuracy)

    for i,v in ipairs(randomConfig) do
        if v.randomInfo.lower <= random and v.randomInfo.upper >= random then
            loadingViewType = v.loadingViewType
            break
        end
    end

    path = self:GetLoadingBgPathByLoadingViewType(loadingViewType)

    return path
end
--[[
根据加载图类型获取加载图路径
@params loadingViewType LoadingViewType 加载图类型
@return path string 加载图路径
--]]
function LoadingView:GetLoadingBgPathByLoadingViewType(loadingViewType)
    -- 给一张默认的路径
    local path = LoadingViewPathConfig[LoadingViewType.FIRST_PERFORMANCE][1]
    if nil ~= LoadingViewPathConfig[loadingViewType] then
        local loadingViewPathInfo = LoadingViewPathConfig[loadingViewType]
        local amount = #loadingViewPathInfo
        local pathIdx = math.ceil(math.random(amount * LoadingViewRandomAccuracy) * LoadingViewRandomAccuracyRec)
        path = loadingViewPathInfo[pathIdx]
    else
        path = self:GetDefaultLoadingBgPath()
    end
    return path
end
--[[
根据关卡id获取配表配置的loading图id
@params stageId int 关卡id
@return path string 路径
--]]
function LoadingView:GetStageConfigLoadingPathByStageId(stageId)
    local path = nil
    if nil ~= stageId then
        local stageConfig = CommonUtils.GetQuestConf(stageId)
        if nil ~= stageConfig then
            local loadingViews = stageConfig.loadingPictureId
            if nil ~= loadingViews and nil ~= next(loadingViews) then

                -- 随机一张loading图id
                local ac = 1000
                local randomIdx = math.ceil(math.random(#loadingViews * ac) / ac)
                local loadingViewId = loadingViews[randomIdx]
                local path_ = string.format('arts/common/%s.jpg', loadingViewId)
                if utils.isExistent(_res(path_)) then
                    -- 文件存在 走配表的逻辑
                    path = path_
                end

            end
        end
    end
    return path
end


function LoadingView:onCleanup()
    if self.resLoader_ then
        self.resLoader_:abort()
        self.resLoader_ = nil
    end
end


return LoadingView
