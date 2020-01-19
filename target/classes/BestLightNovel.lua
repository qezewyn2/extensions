-- {"id":5,"version":"1.0.0","author":"Doomsdayrs","repo":""}
--- @author Doomsdayrs
--- @version 1.0.0

local luajava = require("luajava")

--local LuaSupport = luajava.newInstance("com.github.doomsdayrs.api.shosetsu.services.core.objects.LuaSupport")
local baseURL = "https://bestlightnovel.com"

--- @return boolean
function isIncrementingChapterList()
    return false
end

--- @return boolean
function isIncrementingPassagePage()
    return false
end

--- @return Ordering
function chapterOrder()
    return LuaSupport:getOrdering(0)
end

--- @return Ordering
function latestOrder()
    return LuaSupport:getOrdering(0)
end

--- @return boolean
function hasCloudFlare()
    return false
end

--- @return boolean
function hasSearch()
    return true
end

--- @return boolean
function hasGenres()
    return false
end

---@return ArrayList
function genres()
    return LuaSupport:getGAL()
end

---@return int
function getID()
    return 5
end

---@return string
function getName()
    return "BestLightNovel"
end

---@return string
function getImageURL()
    return ""
end

---@return string
function getLatestURL(page)
    return baseURL .. "/novel_list?type=latest&category=all&state=all&page=" .. (page <= 0 and 1 or page)
end

---@return string
function getNovelPassage(document)
    local elements = document:selectFirst("div.vung_doc"):select("p")
    print(elements:size())
    if elements:size() > 0 then
        local t = {}
        for i=1, elements:size(), 1 do
            t[i] = elements:get(i-1):text()
        end
        return table.concat(t, "\n")
    else
        return "NOT YET TRANSLATED"
    end
end

---@return Novel
function parseNovel(document)
    local novelPage = LuaSupport:getNovelPage()
    -- Image
    novelPage:setImageURL(document:selectFirst("div.truyen_info_left"):selectFirst("img"):attr("src"))

    -- Bulk data
    local elements = document:selectFirst("ul.truyen_info_right"):select("li")
    novelPage:setTitle(elements:get(0):selectFirst("h1"):text())
    
    -- Authors
    do
        local strings = LuaSupport:getStringArray()
        local subElements = elements:get(1):select("a")
        strings:setSize(subElements:size())
        for y = 0, subElements:size() - 1, 1 do
            strings:setPosition(y, subElements:get(y):text())
        end
        novelPage:setAuthors(strings:getStrings())
    end

    -- Genres
    do
        local strings = LuaSupport:getStringArray()
        local subElements = elements:get(2):select("a")
        strings:setSize(subElements:size())
        for y = 0, subElements:size() - 1, 1 do
            strings:setPosition(y, subElements:get(y):text())
        end
        novelPage:setGenres(strings:getStrings())
    end

    -- Status
    do
        local s = elements:get(3):select("a"):text()
        novelPage:setStatus(LuaSupport:getStatus(
            s == "ongoing" and 0 or
                (s == "completed" and 1 or 3)
        ))
    end

    -- Description
    local elements = document:selectFirst("div.entry-header"):select("div")
    for i = 0, elements:size() - 1, 1 do
        local div = elements:get(i)
        if div:id() == "noidungm" then
            novelPage:setDescription(div:text():gsub("<br>", "\n"))
        break end
    end


    -- Chapters
    novelPage:setNovelChapters(LuaSupport:getChapterArrayList())
    local novelChapters = LuaSupport:getCAL()
    local chapters = document:selectFirst("div.chapter-list"):select("div.row")
    local a = chapters:size()
    for i = 0, chapters:size() - 1, 1 do
        local novelChapter = LuaSupport:getNovelChapter()
        local elements = chapters:get(i):select("span")
        local titleLink = elements:get(0):selectFirst("a")
        novelChapter:setTitle(titleLink:attr("title"):gsub(novelPage:getTitle(), ""):match("^%s*(.-)%s*$"))
        novelChapter:setLink(titleLink:attr("href"))
        novelChapter:setRelease(elements:get(1):text())
        novelChapter:setOrder(a-i)
        novelChapters:add(novelChapter)
    end
    novelChapters = LuaSupport:reverseAL(novelChapters)
    novelPage:setNovelChapters(novelChapters)
    return novelPage
end

function parseNovelI(document, increment)
    return parseNovel(document)
end

function novelPageCombiner(url, increment)
    return url
end

function parseLatest(document)
    local novels = LuaSupport:getNAL()
    local elements = document:select("div.update_item.list_category")
    for i = 1, elements:size() - 1, 1 do
        local element = elements:get(i)
        local novel = LuaSupport:getNovel()
        local e = element:selectFirst("h3.nowrap"):selectFirst("a")
        novel:setTitle(e:attr("title"))
        novel:setLink(e:attr("href"))
        novel:setImageURL(element:selectFirst("img"):attr("src"))
        novels:add(novel)
    end
    return novels
end

function parseSearch(document)
    local novels = LuaSupport:getNAL()
    local elements = document:select("div.update_item.list_category")
    for i = 1, elements:size() - 1, 1 do
        local element = elements:get(i)
        local novel = LuaSupport:getNovel()
        local e = element:selectFirst("h3.nowrap"):selectFirst("a")
        novel:setTitle(e:attr("title"))
        novel:setLink(e:attr("href"))
        novel:setImageURL(element:selectFirst("img"):attr("src"))
        novels:add(novel)
    end
    return novels
end

function getSearchString(query)
    return baseURL .. "/search_novels/" .. query:gsub(" ", "_")
end
