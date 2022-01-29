--[[
 * author : kaishiqi
 * descpt : Excel工具类
]]
ExcelUtils = {}

local xml2luaTool    = require('libs.xml2lua.xml2lua')
local xmlHandlerTree = require('libs.xml2lua.xmlhandler.tree')

ExcelUtils.CELL_TYPE = {
    UNDEFINED = 0,
    STRING    = 1,
    BOOLEAN   = 2,
    INT       = 3,
    DOUBLE    = 4,
}


-------------------------------------------------
-- ExcelSheetClass

local ExcelCellClass = class('ExcelCellClass')

function ExcelCellClass:ctor(initArgs)
    local args     = initArgs or {}
    self.rowId_    = tostring(args.rowId)
    self.colId_    = tostring(args.colId)
    self.rowNum_   = checkint(args.rowNum)
    self.colNum_   = checkint(args.colNum)
    self.cellType_ = checkint(args.cellType)
    self.cellData_ = args.cellData
end


function ExcelCellClass:getType()
    return self.cellType_
end


function ExcelCellClass:getData()
    return self.cellData_
end


-------------------------------------------------
-- ExcelSheetClass

local ExcelSheetClass = class('ExcelSheetClass')

function ExcelSheetClass:ctor(initArgs)
    local args    = initArgs or {}
    self.id_      = tostring(initArgs.id)
    self.rId_     = tostring(initArgs.rId)
    self.name_    = tostring(initArgs.name)
    self.gridMap_ = {}
end


function ExcelSheetClass:getId()
    return self.id_
end
function ExcelSheetClass:getRId()
    return self.rId_
end
function ExcelSheetClass:getName()
    return self.name_
end


function ExcelSheetClass:getGridMap()
    return self.gridMap_
end


function ExcelSheetClass:getCell(row, col)
    return checkint(self.gridMap_[tostring(row)])[tostring(col)]
end
function ExcelSheetClass:addCell(row, col, cellObj)
    self.gridMap_[tostring(row)] = self.gridMap_[tostring(row)] or {}
    self.gridMap_[tostring(row)][tostring(col)] = cellObj
end


function ExcelSheetClass:dumpGrid()
    print('[ExcelSheetClass:dumpGrid] >>', self:getName())
    local cellsMap  = self:getGridMap()
    local maxRowNum = checkint(sortByKey(cellsMap, true)[1])
    local maxColNum = 0
    for row = 1, maxRowNum do
        local rowData = {}
        local rowList = cellsMap[tostring(row)] or {}
        maxColNum = checkint(sortByKey(rowList, true)[1])
        for col = 1, maxColNum do
            local cellObj = rowList[tostring(col)]
            table.insert(rowData, cellObj and cellObj:getData() or 'nil')
        end
        print(string.format('row %d)', row), table.concat(rowData, ', '))
    end
end




-------------------------------------------------
-- ExcelFileClass

---@class ExcelFileClass
local ExcelFileClass = class('ExcelFileClass')

function ExcelFileClass:ctor()
    self.sheetMap_   = {}
    self.shareList_  = {}
    self.fileRelMap_ = {}
    self.cellXfList_ = {}
end


function ExcelFileClass:addFileRel(rId, target)
    self.fileRelMap_[tostring(rId)] = checkstr(target)
end
function ExcelFileClass:getFileRel(rId)
    return self.fileRelMap_[tostring(rId)] or ''
end


function ExcelFileClass:getCellXfList()
    return self.cellXfList_
end
function ExcelFileClass:addCellXf(xfXml)
    self.cellXfList_[#self.cellXfList_ + 1] = xfXml or {}
end


function ExcelFileClass:getShareList()
    return self.shareList_
end
function ExcelFileClass:addShareString(shareString)
    self.shareList_[#self.shareList_ + 1] = checkstr(shareString)
end


function ExcelFileClass:addSheet(sheetName, sheetObj)
    self.sheetMap_[tostring(sheetName)] = sheetObj
end
function ExcelFileClass:getSheet(sheetName)
    return self.sheetMap_[tostring(sheetName)]
end
function ExcelFileClass:getSheetCount()
    return table.nums(self.sheetMap_)
end


-------------------------------------------------
-- parser XLSX file
-------------------------------------------------

local COL_NUM_PATTERN  = '([a-zA-Z]*)(%d*)'
local LETTER_BEGIN_IDX = ('A'):byte(1)
local LETTER_ALL_COUNT = 26  -- 26 is a-z letter

local convertToColNumFunc = function(colId)
    local colNumber  = 0
    local colLetters = string.match(colId or '', COL_NUM_PATTERN)
    if colLetters then
        local letIndex  = 1
        repeat
            colNumber = colNumber * LETTER_ALL_COUNT
            colNumber = colNumber + colLetters:byte(letIndex) - LETTER_BEGIN_IDX + 1
            letIndex  = letIndex + 1
        until letIndex > #colLetters
    end
    return colNumber
end


local hasXMLChildrenFunc = function(xmlNode)
    return xmlNode and #xmlNode > 1
end


local checkSubFunc = function(result, num)
    return num > 0 and result or ''
end


---@param filePath string   xlsx file path.
ExcelUtils.ParserXLSX = function(filePath, atSheetName)
    local excelFile = nil
    
    if FTUtils:isPathExistent(filePath) then
        excelFile = ExcelFileClass.new()

        -- parse [sharedStrings.xml]
        do
            local loadedXml  = FTUtils:getFileDataFromZip(filePath, 'xl/sharedStrings.xml')
            local xmlHandler = xmlHandlerTree:new()
            local xmlParser  = xml2luaTool.parser(xmlHandler)
            xmlParser:parse(loadedXml)
            
            for _, siData in ipairs(xmlHandler.root.sst.si or {}) do
                if siData.r then
                    local concatenatedStringList = {}
                    for _, rstr in ipairs(hasXMLChildrenFunc(siData.r) and siData.r or {siData.r}) do
                        if type(rstr.t) == 'table' then
                            concatenatedStringList[#concatenatedStringList + 1] = rstr.t[1]
                        else
                            concatenatedStringList[#concatenatedStringList + 1] = rstr.t
                        end
                    end
                    excelFile:addShareString(table.concat(concatenatedStringList))
                else
                    if type(siData.t) == 'table' then
                        excelFile:addShareString(siData.t[1])
                    else
                        excelFile:addShareString(siData.t)
                    end
                end
            end
        end

        -- parse [styles.xml]
        do
            local loadedXml  = FTUtils:getFileDataFromZip(filePath, 'xl/styles.xml')
            local xmlHandler = xmlHandlerTree:new()
            local xmlParser  = xml2luaTool.parser(xmlHandler)
            xmlParser:parse(loadedXml)
            
            for _, xfsData in ipairs(xmlHandler.root.styleSheet.cellXfs.xf or {}) do
                excelFile:addCellXf(xfsData)
            end
        end

        -- parse [workbook.xml.rels]
        do
            local loadedXml  = FTUtils:getFileDataFromZip(filePath, 'xl/_rels/workbook.xml.rels')
            local xmlHandler = xmlHandlerTree:new()
            local xmlParser  = xml2luaTool.parser(xmlHandler)
            xmlParser:parse(loadedXml)
            -- xml2luaTool.printable(xmlHandler.root)

            for _, rData in ipairs(xmlHandler.root.Relationships.Relationship) do
                local rId     = checkstr(rData._attr['Id'])
                local rTarget = checkstr(rData._attr['Target'])
                excelFile:addFileRel(rId, rTarget)
            end
        end

        -- parse [workbook.xml]
        do
            local loadedXml  = FTUtils:getFileDataFromZip(filePath, 'xl/workbook.xml')
            local xmlHandler = xmlHandlerTree:new()
            local xmlParser  = xml2luaTool.parser(xmlHandler)
            xmlParser:parse(loadedXml)
            
            local parseSheetFunc = function(sheetName, sheetId, sheetRId)
                local sheetObj  = ExcelSheetClass.new({name = sheetName, id = sheetId, rId = sheetRId})
                excelFile:addSheet(sheetName, sheetObj)
                -- print(sheetName)

                -- parse [sheetXXX.xml]
                local sheetXmlPath     = string.format('xl/%s', excelFile:getFileRel(sheetRId))
                local sheetLoadedXml   = FTUtils:getFileDataFromZip(filePath, sheetXmlPath)
                
                while true do
                    local sheetDataPattern = '(<worksheet.*><sheetData>)(.*)(</sheetData>.*)'
                    -- local otherDataXml     = string.gsub(sheetLoadedXml, sheetDataPattern, '%1%3')
                    local sheetDataXml     = string.gsub(sheetLoadedXml, sheetDataPattern, '<sheetData>%2</sheetData>')

                    for rowXml in string.gmatch(string.gsub(sheetDataXml, '<row[^>]+/>', ''), '<row.->.-</row>') do
                        local rowId  = checkSubFunc(string.gsub(rowXml, '(<row r=")(.-)(".*)', '%2'))
                        local rowNum = checkint(rowId)
                        for colXml in string.gmatch(string.gsub(rowXml, '<c[^>]+/>', ''), '<c.->.-</c>') do
                            local colId    = checkSubFunc(string.gsub(colXml, '(<c r=")(.-)(".*>)', '%2'))
                            local typeId   = checkSubFunc(string.gsub(colXml, '(<c .- t=")(.-)(".*>)', '%2'))
                            local stypeId  = checkSubFunc(string.gsub(colXml, '(<c .- s=")(.-)(".*>)', '%2'))
                            local colNum   = convertToColNumFunc(colId)
                            local cellType = ExcelUtils.CELL_TYPE.UNDEFINED
                            local cellData = checkSubFunc(string.gsub(colXml, '(.-<v>)(.-)(</v>.*)', '%2'))

                            if typeId == 's' then
                                cellType = ExcelUtils.CELL_TYPE.STRING
                                cellData = excelFile:getShareList()[checkint(cellData) + 1]

                            elseif typeId == 'str' then
                                cellType = ExcelUtils.CELL_TYPE.STRING
                                
                            elseif typeId == 'b' then
                                cellType = ExcelUtils.CELL_TYPE.BOOLEAN
                                cellData = cheststr(cellData) == '1'

                            else
                                local cellXfXml = excelFile:getCellXfList()[checkint(stypeId) - 1]
                                local numFmtId  = cellXfXml and checkint(cellXfXml._attr['numFmtId']) or 0
                                if numFmtId == 0 or numFmtId == 1 then
                                    cellType = ExcelUtils.CELL_TYPE.INT
                                else
                                    cellType = ExcelUtils.CELL_TYPE.DOUBLE
                                end
                                if cellData then
                                    cellData = tonumber(cellData)
                                end
                            end

                            local cellObj  = ExcelCellClass.new({
                                rowId    = rowId,
                                colId    = colId,
                                rowNum   = rowNum,
                                colNum   = colNum,
                                cellType = cellType,
                                cellData = cellData,
                            })
                            -- print(rowNum, colNum, typeId, cellData)
                            sheetObj:addCell(rowNum, colNum, cellObj)
                        end
                    end
                    break
                end

                -- parse [sheetXXX.xml]
                while not true do
                    local sheetXmlHandler  = xmlHandlerTree:new()
                    local sheetXmlParser   = xml2luaTool.parser(sheetXmlHandler)
                    sheetXmlParser:parse(sheetLoadedXml)
                    
                    local sheetRowsData = sheetXmlHandler.root.worksheet.sheetData.row or {}
                    local sheetRowsList = hasXMLChildrenFunc(sheetRowsData) and sheetRowsData or {sheetRowsData}
                    for _, rowData in ipairs(sheetRowsList) do
                        local attr     = checktable(rowData._attr)
                        local rowId    = checkstr(attr['r'])
                        local rowNum   = checkint(rowId)
                        local colsList = hasXMLChildrenFunc(rowData.c) and rowData.c or {rowData.c}

                        for _, colData in ipairs(colsList) do
                            local colId    = checkstr(colData._attr['r'])
                            local typeId   = checkstr(colData._attr['t'])
                            local stypeId  = checkstr(colData._attr['s'])
                            local colNum   = convertToColNumFunc(colId)
                            local cellType = ExcelUtils.CELL_TYPE.UNDEFINED
                            local cellData = colData.v

                            if typeId == 's' then
                                cellType = ExcelUtils.CELL_TYPE.STRING
                                cellData = excelFile:getShareList()[checkint(cellData) + 1]

                            elseif typeId == 'str' then
                                cellType = ExcelUtils.CELL_TYPE.STRING
                                
                            elseif typeId == 'b' then
                                cellType = ExcelUtils.CELL_TYPE.BOOLEAN
                                cellData = cheststr(cellData) == '1'

                            else
                                local cellXfXml = excelFile:getCellXfList()[checkint(stypeId) - 1]
                                local numFmtId  = cellXfXml and checkint(cellXfXml._attr['numFmtId']) or 0
                                if numFmtId == 0 or numFmtId == 1 then
                                    cellType = ExcelUtils.CELL_TYPE.INT
                                else
                                    cellType = ExcelUtils.CELL_TYPE.DOUBLE
                                end
                                if cellData then
                                    cellData = tonumber(cellData)
                                end
                            end

                            local cellObj  = ExcelCellClass.new({
                                rowId    = rowId,
                                colId    = colId,
                                rowNum   = rowNum,
                                colNum   = colNum,
                                cellType = cellType,
                                cellData = cellData,
                            })
                            -- print(rowNum, colNum, typeId, cellData)
                            sheetObj:addCell(rowNum, colNum, cellObj)
                        end
                    end
                    break
                end
            end

            -- parse all sheet / at sheet
            local sheetNode  = xmlHandler.root.workbook.sheets.sheet
            local sheetList  = hasXMLChildrenFunc(sheetNode) and sheetNode or {sheetNode}
            for _, sheetData in ipairs(sheetList) do
                local sheetName = checkstr(sheetData._attr['name'])
                local sheetId   = checkstr(sheetData._attr['sheetId'])
                local sheetRId  = checkstr(sheetData._attr['r:id'])
                if atSheetName == nil or sheetName == atSheetName then
                    parseSheetFunc(sheetName, sheetId, sheetRId)
                end
            end
        end

    else
        error(string.format('[ExcelUtils.ParserXLSX] error: xlsx file is not existent. %s', filePath))
    end

    return excelFile
end


-------------------------------------------------
-- ExcelObj to table
-------------------------------------------------

local KEY_VAR_LETTER = '$'

local takeVarName = function(keyName)
    local varName = nil
    local firstLetter = string.sub(keyName, 1, 1)
    if firstLetter == KEY_VAR_LETTER then
        varName = string.sub(keyName, 2)
    end
    return varName
end

local takeConvertValue = function(rowDataDict, convertName)
    local varName = takeVarName(convertName)
    if varName then 
        return rowDataDict[varName]
    else
        return convertName
    end
end

local function convertToTableFunc(rowDataDict, convertDefine, rootTable)
    local nodeValue = nil

    if next(convertDefine) == nil then return nil end

    -- check [.filter]
    if convertDefine.filter and convertDefine.filter(rowDataDict) == false then
        return nil
    end

    -- check [.child]
    if convertDefine.child then
        nodeValue = {}
        if convertDefine.key and convertDefine.share then
            local nodeKey = takeConvertValue(rowDataDict, convertDefine.key)
            if rootTable[tostring(nodeKey)] then
                nodeValue = rootTable[tostring(nodeKey)]
            end
        end

        for _, childDefine in ipairs(convertDefine.child) do
            convertToTableFunc(rowDataDict, childDefine, nodeValue)
        end

    else
        -- check [.value]
        if type(convertDefine.value) == 'table' then
            local valueQueue  = {}
            local valueFormat = convertDefine.value[1]
            for i = 2, #convertDefine.value do
                table.insert(valueQueue, takeConvertValue(rowDataDict, convertDefine.value[i]) or '')
            end
            nodeValue = string.fmt(valueFormat, unpack(valueQueue))

        elseif type(convertDefine.value) == 'function' then
            nodeValue = convertDefine.value(rowDataDict) or convertDefine.default
        else
            nodeValue = takeConvertValue(rowDataDict, convertDefine.value) or convertDefine.default
        end
    end

    if nodeValue then
        -- check [.key]
        if convertDefine.key then
            local nodeKey = takeConvertValue(rowDataDict, convertDefine.key)
            if nodeKey then
                if convertDefine.share then
                    if not rootTable[tostring(nodeKey)] then
                        rootTable[tostring(nodeKey)] = nodeValue
                    end
                else
                    rootTable[tostring(nodeKey)] = nodeValue
                end
            end
        else
            table.insert(rootTable, nodeValue)
        end
    end
end


---@param excelObj ExcelFileClass   ExcelFileClass object.
ExcelUtils.ExcelToConfTable = function(excelObj, convertTable, sheetName)
    local confTable = {}

    if excelObj and convertTable then
        local sheetObj  = excelObj and excelObj:getSheet(sheetName) or nil
        local cellsMap  = sheetObj and sheetObj:getGridMap() or nil
        assert(sheetObj, string.fmt('Excel文件中不存在名为“%1”的sheet！！', sheetName))
        -- sheetObj:dumpGrid()
        
        -- parser conf header
        local headerList = {}
        local headerRow  = cellsMap['1'] or {}
        local rowNum     = checkint(sortByKey(cellsMap, true)[1])
        local colNum     = checkint(sortByKey(headerRow, true)[1])
        for col = 1, colNum do
            local cellObj = headerRow[tostring(col)]
            table.insert(headerList, cellObj and cellObj:getData() or '')
        end

        local descrRow  = cellsMap['2']
        local placeRow  = cellsMap['3']

        -- parser conf data
        for row = 4, rowNum do
            local rowDict  = {}
            local rowList = cellsMap[tostring(row)] or {}
            for col = 1, colNum do
                local header    = headerList[col]
                local cellObj   = rowList[tostring(col)]
                local cellValue = cellObj and cellObj:getData() or nil
                rowDict[header] = cellValue
            end

            -- check status
            local isOpenRow  = checkint(rowDict['status']) == 1
            local isValidRow = true --rowList[tostring(1)] ~= nil
            if isValidRow and isOpenRow then
                convertToTableFunc(rowDict, convertTable, confTable)
            end
        end
    end

    return confTable
end


-------------------------------------------------
-- refresh conf cache
-------------------------------------------------

--[[
    ---@param json      （必要）配表格式 '模块/名字'
    ---@param excel     （可选）如果不是默认目录，可指定自定义目录
    ---@param export    （可选）是否打印配表（本来想做成excel转json后写本地的）
    ---@see 具体导出格式定义在 Game/confParserDefine.lua
    ---@e.g
    ExcelUtils.RefreshConfCache(
        {json = 'newSummerActivity/mainStoryCollection',   excel = '/Users/kaishiqi/Downloads/19夏活剧情收录表.xlsx', export = true},
        {json = 'newSummerActivity/branchStoryCollection', excel = '/Users/kaishiqi/Downloads/19夏活剧情收录表.xlsx', export = true},
        {json = 'restaurant/avatarAnimation'},
        {json = 'module'}
    )
]]
ExcelUtils.RefreshConfCache = function(...)
    local confDefineList = {...}
    for _, confDefine in ipairs(confDefineList or {}) do
        local jsonFile  = confDefine.json
        local excelFile = confDefine.excel
        local isExport  = confDefine.export == true

        if confParserDefine[jsonFile] then
            local confDefine  = confParserDefine[jsonFile]
            local excelPath   = excelFile or confDefine.excelPath
            local subConfRule = confDefine.subConfRule
            local excelObj    = ExcelUtils.ParserXLSX(excelPath, confDefine.sheetName)
            local confTable   = ExcelUtils.ExcelToConfTable(excelObj, confDefine.convertTable, confDefine.sheetName)

            if isExport then
                print(string.fmt('[ExcelUtils.RefreshConfCache] json = %1(sub=%4), excel = %2, sheet = %3, sub = %4', jsonFile, excelPath, confDefine.sheetName, subConfRule ~= nil))
                -- print(json.encode(confTable))
            end

            -- refresh confCache
            local jsonConfig = string.split2(jsonFile, '/')
            local hasModule  = #jsonConfig > 1
            local moduleName = hasModule and jsonConfig[1] or nil
            local jsonName   = hasModule and jsonConfig[2] or jsonConfig[1]

            -------------------------------------------------
            -- 分表处理
            if subConfRule then
                for jsonFileName, _ in pairs(app.dataMgr.confCacheMap_[moduleName] or {}) do
                    if string.sub(jsonFileName, 1, #jsonName) == jsonName then
                        
                        -- clean originConf
                        local originConf = CommonUtils.GetConfigAllMess(jsonFileName, moduleName)
                        for key, value in pairs(originConf) do
                            originConf[key] = nil
                        end

                    end
                end

                -- re-fill originConf
                for key, value in pairs(confTable) do
                    local subJsonFileName = jsonName .. subConfRule(value)
                    local subOriginConf   = CommonUtils.GetConfigAllMess(subJsonFileName, moduleName)
                    subOriginConf[key]    = confTable[key]
                end

            -------------------------------------------------
            -- 单表处理
            else
                local originConf = CommonUtils.GetConfigAllMess(jsonName, moduleName)
                if originConf then
                    -- clean originConf
                    for key, value in pairs(originConf) do
                        originConf[key] = nil
                    end
                    -- re-fill originConf
                    for key, value in pairs(confTable) do
                        originConf[key] = confTable[key]
                    end
                else
                    print('[ExcelUtils.RefreshConfCache] refresh confCache failed :', jsonFile)
                end
            end

        else
            print('[ExcelUtils.RefreshConfCache] not define conf parser :', jsonFile)
        end
    end
end
