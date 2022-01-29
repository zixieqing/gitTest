--[[
 * author : kaishiqi
 * descpt : create on 2016-03-18
]]

i18n = i18n or {}


-- require language code defines
i18n.langMap = require 'i18n.LangCode'
for langCode, define in pairs(i18n.langMap) do
	local shortKey = string.gsub(langCode, '-', '_')
	i18n[shortKey] = langCode
end


-- require I18nUtils
i18n.i18nUtils   = require 'i18n.I18nUtils'
i18n.D_DEFAULT   = i18n.i18nUtils.D_DEFAULT
i18n.addMO       = i18n.i18nUtils.addMO
i18n.hasMO       = i18n.i18nUtils.hasMO
i18n.removeMO    = i18n.i18nUtils.removeMO
i18n.removeAllMO = i18n.i18nUtils.removeAllMO


-- close file popup notify
cc.FileUtils:getInstance():setPopupNotify(false)


function i18n.refreshMO()
	i18n.removeAllMO()
	i18n.addMO(string.format('res/lang/%s.mo', i18n.getLang()), i18n.i18nUtils.D_DEFAULT)  -- client lang mo
end


-- current lang
i18n.LANG_CACHE_KEY = 'summerLang'
function i18n.getLang()
	return i18n.language_ and tostring(i18n.language_) or 'zh-cn'
end
function i18n.setLang(langCode)
	i18n.language_ = tostring(langCode)
	print('\tcurrent lang:', langCode)

	-- save userData
	cc.UserDefault:getInstance():setStringForKey(i18n.LANG_CACHE_KEY, i18n.language_)
	cc.UserDefault:getInstance():flush()

	-- refresh mo file
	i18n.refreshMO()

	-- update lua cache
	local excludeList = {'i18n.', 'cocos.', 'update.', 'root.', 'conf.', 'config', 'main'}
	local reloadMap = {}
	local reloadLua = function(name)
		local rootDir   = string.sub(name, 0, string.find(name, '[.]'))
		local isExclude = false
		for _,v in ipairs(excludeList) do
			if rootDir == v then
				isExclude = true
				break
			end
		end
		local path = string.gsub(tostring(name), '[.]', '/') .. '.lua'
		if not isExclude and FTUtils:isPathExistent(path) then
			package.loaded[name] = nil
			local str = string.format('require \'%s\'', name)
			if not reloadMap[str] then
				reloadMap[str] = true
				local ret, flist = pcall(loadstring(tostring(str)))
			end
		end
	end
	for k,v in pairs(package.loaded) do
		reloadLua(k)
	end
	for k,v in pairs(package.preload) do
		reloadLua(k)
	end

	-- dispatch change lang event
	local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
	eventDispatcher:dispatchEvent(cc.EventCustom:new('CHANG_LANG'))
end


-------------------------------------------------
-- gettext
-------------------------------------------------

-- general text
function __(text, domain)
    return i18n.i18nUtils.gettext(text, domain)
end

-- context text
function _x(text, context, domain)
	return i18n.i18nUtils.xgettext(text, context, domain)
end

-- plural text
function _n(singular, plural, number, domain)
	return i18n.i18nUtils.ngettext(singular, plural, number, domain)
end

-- plural + context
function _nx(singular, plural, number, context, domain)
	return i18n.i18nUtils.nxgettext(singular, plural, number, context, domain)
end

function _n_noop(singular, plural, domain)
	return i18n.i18nUtils.ngettextNoop(singular, plural, domain)
end

function _nx_noop(singular, plural, context, domain)
	return i18n.i18nUtils.nxgettextNoop(singular, plural, context, domain)
end

function t_nooped(noopEntry, number, domain)
	return i18n.i18nUtils.translateNoop(noopEntry, count, domain)
end


-------------------------------------------------
-- res
-------------------------------------------------

function _res(resPath, notImg)
	local resPath = tostring(resPath)
	local getFileName = function(name)
		return (utils and not notImg) and utils.getFileName(name) or name
	end
    local lastPos = 0
    for st, sp in function() return string.find(resPath, '/', lastPos, true) end do
	    lastPos = sp + 1
	end
	local lang = i18n.getLang()
	local path = string.sub(resPath, 1, lastPos - 1)
	local name = string.sub(resPath, lastPos)
	local file = utils.getFileName(string.format('%s%s/%s', path, lang, name))
	return FTUtils:isPathExistent(file) and file or getFileName(resPath)
end


-------------------------------------------------
-- conf
-------------------------------------------------

function _confp(name)
	local lang = string.len(i18n.getLang()) > 0 and i18n.getLang() or tostring(i18n.defaultLang)
	-- if lang == 'zh-cn' then
	-- 	return string.format('conf/%s.lua', name)
	-- else
		return string.format('conf/%s/%s.lua', lang, name)
	-- end
end

function _conf(name)
	local start = os.clock()
	local path = _confp(name)
	local modn = string.gsub(string.gsub(path, '.lua', ''), '[/]', '.')
	local nhas = package.loaded[modn] == nil
	local isEx = FTUtils:isPathExistent(path)
	local data = isEx and require (modn) or {}
    if DEBUG and DEBUG > 0 and nhas then
        print(modn)
        local crashLog = "\n"
        crashLog = crashLog .. ("----------------------------------------\n")
        crashLog = crashLog .. ("cost time " .. string.format('%f', os.clock() - start) .. '\n')
        crashLog = crashLog .. ("----------------------------------------\n")
        print(crashLog)
    end
    if not isEx then print(string.format('!!!! conf [%s] not find !!!!', modn)) end
    return data
end

