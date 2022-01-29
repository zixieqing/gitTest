--[[
剧情对白的入口初始化逻辑功能
---]]
local GameScene = require( 'Frame.GameScene' )
local OperaStage = class('OperaStage', GameScene)

local Director = require( "Frame.Opera.Director" )

local shareFacade = AppFacade.GetInstance()

local OperaConfig = {
    DIALOGBOX_MAX = 9,  -- 气泡框样式最大值
}

--[[
-- 如何使用
--local node = require( "Frame.Opera.OperaStage" ).new({id = 2})
--node:setPosition(cc.p(display.cx,display.cy))
--self:addChild(node)
-- @params {
    -- cb    结束回调函数
    -- id    对白对应的id
    -- path  对白配表路径
    -- data  选项任务的数据（可选）
    -- isReview       是否 回放方式播放剧情
    -- guide          是否 使用透明黑底阻挡
    -- customSkip     是否 开启创角跳过功能（创角界面特定）
    -- isHideSkipBtn  是否 隐藏跳过按钮
    -- isHideBackBtn  是否 隐藏后退按钮
--}
--]]
function OperaStage:ctor(...)
    local args      = unpack({...})
    self.operaId    = args.id
    self.finishCB   = args.cb
    self.customSkip = args.customSkip
    self.executed   = false
    self.oldBGMKey_ = app.audioMgr:GetPlayingBGCueKey()
    self.optionData = args.data
    self.isReview_  = args.isReview == true
    local dialogPath = args.path or (string.format("conf/%s/quest/questStory.json",i18n.getLang()))
    --    local backgroundImage = args.image or "stage_bg_1"
    local colorView = nil
    if args.guide then
        colorView = CColorView:create(cc.c4b(0,0,0,255))
    else
        colorView = CColorView:create(cc.c4b(0,0,0,255))
    end
    self:setPosition(display.center)
    self:addChild(colorView)
    colorView:setContentSize(display.size)
    colorView:setTouchEnabled(true)
    colorView:setTag(3211)
    colorView:setPosition(display.center)
    colorView:setOnClickScriptHandler(handler(self, self.ActionEvent))
    --    local imageId = _res(string.format("arts/stage/bg/%s.png", backgroundImage))
    --    local bg = display.newImageView(imageId, display.cx, display.cy)
    --    self:addChild(bg)
    self.m_director = Director.GetInstance( "Director" )
    self.m_director:SetStage(self) -- 设置舞台,以便其它的添加操作
    self.isStarting = false --是否已经开始
    self.isOver  = false
    self.isAuto  = false
    --    self.m_director:PushImage(imageId, bg) --加入管理

    -- clean l2d env
    app.cardL2dNode.CleanEnv()
    
    -- init l2d rootContainer
    local l2dContainer = display.newLayer()
    self.m_director:GetStage():addChild(l2dContainer, Director.ZorderTAG.Z_LIVE2D_LAYER, Director.ZorderTAG.Z_LIVE2D_LAYER)
    app.cardL2dNode.InitEnv(l2dContainer)

    -- append globalLvContainer
    self.lvContainer = l2dContainer
    app.cardL2dNode.AppendGlobalLvContainerList(self.lvContainer)

    --加载数据配表路径的数据
    self:LoadStory(dialogPath, self.operaId)
    
    local backBtn = display.newButton(0, 0, {n = _res('ui/common/common_btn_back.png')})
    display.commonUIParams(backBtn, {po = cc.p(backBtn:getContentSize().width * 0.5 + 30, display.height - 18 - backBtn:getContentSize().height * 0.5),
    cb = function(sender)
        sender:setEnabled(false)
        PlayAudioClip(AUDIOS.UI.ui_change.id)
        if self.finishCB then
            self.finishCB(3005)
        end
        self:runAction(cc.RemoveSelf:create())
    end})
    self:addChild(backBtn, 3005,3005)

    local skipButton = display.newButton(0, 0, {n = _res('arts/stage/ui/opera_btn_skip.png')})
    display.commonLabelParams(skipButton, {fontSize = 26, text = __("跳过"),color = "220404", offset= cc.p(45,0)})
    display.commonUIParams(skipButton, {po = cc.p(display.width - skipButton:getContentSize().width * 0.5 , backBtn:getPositionY()),
    cb = function(sender)
        PlayAudioByClickNormal()
        if self.customSkip then
            sender:setVisible(false)
            if not self.executed then
                self.executed = true
                self:SkipToCreateRole()
            end
        else
            sender:setEnabled(false)
            if self.finishCB then
                self.finishCB(3007)
            end
            self:runAction(cc.RemoveSelf:create())
        end
    end})
    skipButton:setVisible(false)
    -- if DEBUG == 0 then
        -- skipButton:setVisible(false)
    -- end

    --剧情任务隐藏返回按钮和跳过按钮
    if args.isHideBackBtn then
        backBtn:setVisible(false)
    end
    if args.isHideSkipBtn then
        skipButton:setVisible(false)
    else
        skipButton:setVisible(true)
    end

    if args.guide then
        backBtn:setVisible(false)
        -- skipButton:setVisible(false) --测试把这个显示出来
    end
    -- skipButton:setVisible(true)
    -- local iconSprite = display.newSprite(_res("arts/stage/ui/opera_ico_skip.png"))
    -- display.commonUIParams(iconSprite, {ap = display.RIGHT_CENTER, po = cc.p(skipButton:getContentSize().width - 10, skipButton:getContentSize().height * 0.5)})
    -- skipButton:addChild(iconSprite,2)
    self:addChild(skipButton, 3005,3006)
    --点击处理层
    shareFacade:RegistObserver("DirectorStory", mvc.Observer.new(handler(self,self.StoryActionEvent), self))
end

function OperaStage:LoadStory(dialogPath, storyId)
    self.operaId = checkint(storyId)
    self.m_director:LoadFromFile(dialogPath, function(path, data)
        if not data then
            funLog(Logger.INFO, "json格式存在问题")
        else
            local opera = data[tostring(self.operaId)]
            if opera then
                print("--------------------->>>>>>>>>")
                local RoleCommand        = require("Frame.Opera.RoleCommand")
                local DialogueCommand    = require("Frame.Opera.DialogueCommand")
                local MoveCommand        = require("Frame.Opera.MoveCommand")
                local ColorScreenCommand = require("Frame.Opera.ColorScreenCommand")
                local AnimPlayCommand    = require("Frame.Opera.AnimPlayCommand")
                local OpenBlackCommand   = require("Frame.Opera.OpenBlackCommand")
                local ImageCommand       = require("Frame.Opera.ImageCommand")
                local CGCommand          = require("Frame.Opera.CGCommand")
                local WhenCommand        = require("Frame.Opera.WhenCommand")
                local EnterStageCommand  = require("Frame.Opera.EnterStageCommand")
                local OptionCommand      = require("Frame.Opera.OptionCommand")
                local MusicCommand       = require("Frame.Opera.MusicCommand")
                local SpineCommand       = require("Frame.Opera.SpineCommand")
                local AppendDescrCommand = require("Frame.Opera.AppendDescrCommand")

                if opera[1] then
                    if not string.match( tostring(opera[1].setting), ".+" ) then
                        --有背景的数据
                        local c = ImageCommand:New()
                        c:SetBgColor(cc.c4b(0,0,0,255))
                        self.m_director:AddCommand(c)
                    end
                end
                
                for k,v in pairs(opera) do
                    local roleId    = v.name
                    local isL2dRole = false
                    if string.len(checkstr(roleId)) > 0 and string.sub(checkstr(roleId), 1,1) == 'l' then
                        roleId    = string.sub(checkstr(v.name), 2)
                        isL2dRole = true
                    end

                    if checkint(v.type) == Director.Type.OPTION then --选项
                        local optionCmd = OptionCommand:New({isReview = self.isReview_, data = self.optionData, id = self.operaId, config = v})
                        self.m_director:AddCommand(optionCmd)
                    else
                        if string.match( tostring(v.setting), ".+" ) then
                            --有背景的数据
                            local imagecmd = ImageCommand:New(v.setting)
                            self.m_director:AddCommand(imagecmd)
                            if v.filter and string.match(v.filter, '.+') then
                                imagecmd:setFilter(v.filter)
                            end
                        end
                        
                        --
                        if v.controlmusic and string.find(v.controlmusic, '^%d+') then
                            local imagecmd = MusicCommand:New(v.controlmusic)
                            self.m_director:AddCommand(imagecmd)
                        end

                        --
                        if checkint(v.func) > 0 then
                            local funId = checkint(v.func)
                            if funId == 3 then
                                --播放视频的逻辑
                                if device.platform == 'ios' or device.platform == 'android' then
                                    -- if checkint(Platform.id) ~= 2005 and checkint(Platform.id) ~= 2006 then
                                    local VideoCommand = require("Frame.Opera.VideoCommand")
                                    local c = VideoCommand:New(v.desc or v.descr)
                                    self.m_director:AddCommand(c)
                                    -- end
                                end
                            elseif funId == 1 then
                                --去战斗的命令
                                local FightCommand = require("Frame.Opera.FightCommand")
                                local c = FightCommand:New()
                                self.m_director:AddCommand(c)
                            elseif funId == 2 then
                                --创角的逻辑
                                if not self.isReview_ then
                                    local CreateRoleCommand = require("Frame.Opera.CreateRoleCommand")
                                    local c = CreateRoleCommand:New()
                                    self.m_director:AddCommand(c)
                                end
                            elseif funId == 5 then
                                --选神器的逻辑
                                local ChooseArtifactCommand = require("Frame.Opera.ChooseArtifactCommand")
                                local c = ChooseArtifactCommand:New()
                                self.m_director:AddCommand(c)
                            end
                            
                        else
                            --分析数据
                            if checkint(v.characteranime) == 2 then  -- 角色动画2：立绘登场
                                --显示角色介绍
                                self.m_director:AddCommand(EnterStageCommand:New(roleId, nil, nil, v.face, v.flip))
                                --再加上对白的一句话
                                if roleId and tostring(v.dialogboxplaces) ~= '0' then --添加角色
                                    local c = RoleCommand:New({roleId = roleId, replace = v.replace, iscard = false, align = checkint(v.left), faceId = v.face, scale = v.scale, offset = v.offset, mysteryMode = checkint(v.characteranime) == 11})
                                    if checkint(v.flip) == 1 then c.flip = true end
                                    if checkint(v.characteranime) == 3 or checkint(v.characteranime) == 4 then
                                        --左入镜
                                        --右入镜
                                        c:AnimateEnter()
                                    end
                                    self.m_director:AddCommand(c)
                                    --添加一个移动命令
                                    if checkint(v.characteranime) == 3 then
                                        --左入镜
                                        self.m_director:AddCommand(c:GetRoleMoveCommand())
                                    elseif checkint(v.characteranime) == 4 then
                                        --右入镜
                                        self.m_director:AddCommand(c:GetRoleMoveCommand())
                                    end
                                end
                                local boxId = rangeId(v.dialogbox, OperaConfig.DIALOGBOX_MAX)
                                local c = DialogueCommand:New(v.dialogboxplaces, boxId, roleId, v.voice)
                                c:CommandDialogue(roleId, (v.desc or v.descr), v.displayitems)
                                c:StoryMusic(v.music)
                                if checkint(v.sceneanime) == 1 then
                                    c:ShakeSameTime(true)
                                end
                                self.m_director:AddCommand(c)

                            else
                                if (checkint(v.type) ~= Director.Type.CG_RETAIN and 
                                    checkint(v.type) ~= Director.Type.SPINE_RETAIN and
                                    checkint(v.type) ~= Director.Type.APPEND_DESCR) then
                                    --不是cg下面的对白的情况下才添加相关的角色
                                    if roleId and tostring(v.dialogboxplaces) ~= '0' then --添加角色
                                        local c = RoleCommand:New({roleId = roleId, replace = v.replace, iscard = false, align = checkint(v.left), faceId = v.face, scale = v.scale, offset = v.offset, isL2d = isL2dRole, mysteryMode = checkint(v.characteranime) == 11})
                                        if checkint(v.flip) == 1 then c.flip = true end
                                        if checkint(v.characteranime) == 3 or checkint(v.characteranime) == 4 then
                                            --左入镜
                                            --右入镜
                                            c:AnimateEnter()
                                        end
                                        self.m_director:AddCommand(c)
                                        --添加一个移动命令
                                        if checkint(v.characteranime) == 3 then
                                            --左入镜
                                            self.m_director:AddCommand(c:GetRoleMoveCommand())
                                        elseif checkint(v.characteranime) == 4 then
                                            --右入镜
                                            self.m_director:AddCommand(c:GetRoleMoveCommand())
                                        end
                                    end
                                end
                                
                                if (checkint(v.type) == Director.Type.STORY or --对白数据
                                    checkint(v.type) == Director.Type.CG_RETAIN or --cg上的对白语言
                                    checkint(v.type) == Director.Type.SPINE_RETAIN) then --spine上的对白语言
                                    --旁白
                                    local boxId = rangeId(v.dialogbox, OperaConfig.DIALOGBOX_MAX)
                                    local c = DialogueCommand:New(v.dialogboxplaces, boxId, roleId, v.voice)
                                    c:CommandDialogue(roleId, (v.desc or v.descr), v.displayitems)

                                    if (checkint(v.type) == Director.Type.CG_RETAIN or
                                        checkint(v.type) == Director.Type.SPINE_RETAIN) then
                                        c:IsCG()
                                    end

                                    c:StoryMusic(v.music)
                                    if v.sound and string.len(v.sound) > 0 then
                                        c:AudioEffects({audioPath = v.sound})
                                    end
                                    if checkint(v.sceneanime) == 1 then
                                        c:ShakeSameTime(true)
                                    end
                                    self.m_director:AddCommand(c)

                                    -- 处理角色
                                    if checkint(v.type) == Director.Type.STORY then
                                        if checkint(v.characteranime) == 5 then
                                            --左出镜
                                            self.m_director:AddCommand(MoveCommand:New(roleId, -display.width * 2, display.cy, 0.7))
                                        elseif checkint(v.characteranime) == 6 then
                                            --右出镜
                                            self.m_director:AddCommand(MoveCommand:New(roleId, display.width * 2, display.cy, 0.7))
                                        end
                                    end
                                    
                                    --添加色彩屏的动画
                                    local displayColor = checkint(v.displaycolor)
                                    if displayColor > 0 then
                                        local color = "#ffffffff"
                                        if displayColor == 4 then
                                            color = "#000000ff"
                                        elseif displayColor == 6 then
                                            color = "#ff0000ff"
                                        end
                                        self.m_director:AddCommand(ColorScreenCommand:New(color, 2))
                                    end

                                    --添加特效动画
                                    local effect = checkint(v.specialeffects)
                                    if effect > 1 then
                                        --特效的逻辑功能
                                        self.m_director:AddCommand(AnimPlayCommand:New(effect))
                                    end

                                elseif checkint(v.type) == Director.Type.CG_BEGEN then --出cg
                                    if string.match( tostring(v.CG), ".+" ) then
                                        --有背景的数据
                                        local imagecmd = CGCommand:New(v.type, v.CG)
                                        self.m_director:AddCommand(imagecmd)
                                        if v.filter and string.match(v.filter, '.+') then
                                            imagecmd:setFilter(v.filter)
                                        end
                                    end

                                elseif checkint(v.type) == Director.Type.CG_ENDED then --结束cg
                                    if string.match( tostring(v.CG), ".+" ) then  -- 这段逻辑是骗人的，根本不会执行。CG的移除是根据设置新背景图来替换掉的。
                                        --有背景的数据
                                        local imagecmd = CGCommand:New(v.type, v.CG)
                                        self.m_director:AddCommand(imagecmd)
                                        if v.filter and string.match(v.filter, '.+') then
                                            imagecmd:setFilter(v.filter)
                                        end
                                    end

                                elseif checkint(v.type) == Director.Type.SPINE_BEGEN then --出spine
                                    if string.match( tostring(v.spineanime), ".+" ) then
                                        local spineCmd = SpineCommand:New(v.type, v.spineanime)
                                        self.m_director:AddCommand(spineCmd)
                                    end

                                elseif checkint(v.type) == Director.Type.SPINE_ENDED then --结束spine
                                    if string.match( tostring(v.spineanime), ".+" ) then
                                        local spineCmd = SpineCommand:New(v.type, v.spineanime, true)
                                        self.m_director:AddCommand(spineCmd)
                                    end

                                elseif checkint(v.type) == Director.Type.BLACK then
                                    --黑背景
                                    self.m_director:AddCommand(OpenBlackCommand:New({content = (v.desc or v.descr), face = v.face}))

                                elseif checkint(v.type) == Director.Type.LOCATION then
                                    --时间标题显示
                                    local a = string.split((v.desc or v.descr), '_when_')
                                    local when, address = a[1], a[2]
                                    self.m_director:AddCommand(WhenCommand:New({when = when, address = address}))

                                elseif checkint(v.type) == Director.Type.APPEND_DESCR then
                                    self.m_director:AddCommand(AppendDescrCommand:New(v.face, (v.desc or v.descr)))
                                    
                                end
                            end

                        end
                    end
                end
                self.m_director:Start()
            else
                funLog(Logger.INFO, "不存在对应id的配表数据" .. tostring(self.operaId))
            end
        end

    end)
end


function OperaStage:HiddenSkip()
    local skipButton = self:getChildByTag(3006)
    if skipButton then skipButton:setVisible(false) end
end

function OperaStage:SkipToCreateRole()
    if isElexSdk() then
        local AppSDK = require('root.AppSDK')
        AppSDK.GetInstance():AppFlyerEventTrack("DialogOperaSkip",{af_event_start = "DialogOperaSkip"})
    end
    self.m_director:SkipToCreateRole()
end
--[[
正常的处理事件
--]]
function OperaStage:ActionEvent( sender )
    if self.isOver then return end
    if self.isAuto then return end --如里是自动的 屏蔽点击
    self.isOver = true
    xTry(function()
        local director = Director.GetInstance( )
        local command = director:GetCurrentCommand()
        if command then
            --需要添加哪几种命令类型时需要移除相关的node节点
            local relationNode = command.relationNode
            if command.NAME == 'DialogueCommand' then
                if command.viewData and command.viewData.view and command.isTyping == false then
                    if director.delayDescrData then
                        director.delayDescrData.view:setVisible(true)  -- 不要做动画，万一动画做到一半，被切换到下一句
                        director.delayDescrData = nil
                    else
                        if director:GetStage():getChildByTag(Director.ZorderTAG.Z_APPEND_DESCR_LAYER) then
                            director:GetStage():removeChildByTag(Director.ZorderTAG.Z_APPEND_DESCR_LAYER)
                        end
                        command.viewData.view:removeFromParent()
                        director:MoveNext()
                    end
                else
                    command:ShowFullStory()
                end
            elseif command.NAME == "ColorScreenCommand" then
                self.isAuto = true
                -- if relationNode and command.inAction == false then
                    -- relationNode:removeFromParent()
                    -- director:MoveNext()
                -- end
            elseif command.NAME == "EnterStageCommand" then
                if relationNode and command.inAction == false then
                    relationNode:removeFromParent()
                    director:MoveNext()
                end
            elseif command.NAME == "MoveCommand" then
                --移动命令的逻辑
                if command.inAction == false then
                    director:MoveNext()
                end
            elseif command.NAME == "AnimPlayCommand" then
                --特效命令
                self.isAuto = true
                if relationNode and command.inAction == false then
                    relationNode:removeFromParent()
                    director:MoveNext() --下移
                end
            elseif command.NAME == "OpenBlackCommand" then
                if command.inAction == false then
                    command:ExecuteAfter() --执行下一句的逻辑
                end
            elseif command.NAME == "WhenCommand" then
                if command.inAction == false then
                    command:ExecuteAfter() --执行下一句的逻辑
                end
            elseif command.NAME == 'ImageCommand' then
                --无视这条命令
            elseif command.NAME == 'VideoCommand' then
                --无视这条命令
            elseif command.NAME == 'ChooseArtifactCommand' then
                --无视这条命令
            elseif command.NAME == 'AppendDescrCommand' then
                if command.inAction == false then
                    command:ExecuteAfter() --执行下一句的逻辑
                end
            elseif command.NAME == 'RoleCommand' then
                -- 避免创建角色资源耗时过长，此时点击了屏幕，被触发了下一步跳过创建命令
                if command.inAction == false then
                    command:ExecuteAfter() --执行下一句的逻辑
                end
            elseif command.NAME == 'SpineCommand' then
                self.isAuto = true
                if command.inAction == false then
                    director:MoveNext()
                end
            else
                director:MoveNext()
            end
        else
            funLog(Logger.INFO, "当前命令为空的逻辑")
        end
        self:runAction(cc.Sequence:create(cc.DelayTime:create(0.4), cc.CallFunc:create(function()
            self.isOver = false
        end)))

    end,__G__TRACKBACK__)
end
function OperaStage:StoryActionEvent(stage, signal)
    local name = signal:GetName()
    local body = signal:GetBody()
    
    if name == 'DirectorStory' then
        if body == 'success' then
            --剧情结束
            self.isOver = true
            if self.finishCB then
                self:setVisible(false)
                self:runAction(cc.Sequence:create(cc.CallFunc:create(function()
                    if self.finishCB then self.finishCB(3006) end
                end),cc.RemoveSelf:create()))--,cc.DelayTime:create(0.2)
            else
                shareFacade:DispatchObservers("DirectorSuccess", "success")
            end
        elseif body == 'next' then
            --下一步剧情进行
            local director = Director.GetInstance( )
            local command = director:GetCurrentCommand()
            if command.NAME == 'ColorScreenCommand' then
                self:removeChildByTag(Director.ZorderTAG.Z_COLOR_SCREEN_LAYER)
            end
            director:MoveNext() --下移
            self.isAuto = false
        end
    end
end

--[[
--需要加载哪个对白文件
--]]
function OperaStage:Initial( filepath )
    self.m_director:LoadFromFile(filepath) --从文件加载命令集
end


function OperaStage:Start( )
    if self.isStarting then return end
    self.isStarting = true --防止重复启动
    self.m_director:Start()
end

--[[
--结束剧情的相关逻辑
--]]
function OperaStage:StopStory( )
    shareFacade:UnRegistObserver("DirectorStory", self)
    Director.Destroy("Director")
    self.m_director = nil --清理工作
end

function OperaStage:onCleanup( )
    --执行清理工作
    self:StopStory()

    -- stop all acb
    app.audioMgr:StopAllPlayers()

    -- 检查是否禁用退出时的背景音乐
    if self.oldBGMKey_ then
        PlayBGMusic(self.oldBGMKey_)
    else
        PlayBGMusic()
    end

    -- clean live2d env
    app.cardL2dNode.CleanEnv()

    -- popup globalLvContainer
    app.cardL2dNode.PopupGlobalLvContainerList(self.lvContainer, true)
end

return OperaStage
