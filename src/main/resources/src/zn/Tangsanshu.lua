-- {"id":234,"version":"1.0.0","author":"Doomsdayrs","repo":""}

local baseURL = "http://www.tangsanshu.com"

---@param page number @value
---@return string @url of said latest page
local function getLatestURL(page)
    return baseURL
end

---@param document Document @Jsoup document of the page with chapter text on it
---@return string @passage of chapter, If nothing can be parsed, then the text should describe why there isn't a chapter
local function getNovelPassage(document)
    return document:selectFirst("div.showtxt"):html():gsub("<br ?/?>", "\n"):gsub("\n+","\n"):gsub("&nbsp;", "")
end

---@param document Document @Jsoup document of the novel information page
---@return NovelPage
local function parseNovel(document)
    local novelPage = NovelPage()

    -- Info

    local info = document:selectFirst("div.info")
    novelPage:setTitle(info:selectFirst("h2"):text())
    novelPage:setImageURL(baseURL .. info:selectFirst("img"):attr("src"))

    local items = info:selectFirst("div.small"):select("span")

    novelPage:setAuthors({ items:get(0):text():gsub("作者：", "") })

    novelPage:setGenres({ items:get(1):text():gsub("分类：", ""):gsub("小说", "") })

    local status = items:get(2):text():gsub("状态：", "")
    novelPage:setStatus(NovelStatus(status == "完本" and 1 or status == "连载中" and 0 or 3))
    novelPage:setDescription(info:selectFirst("div.intro"):text():gsub("<span>简介：</span>", ""):gsub("<br>", "\n"))

    -- NovelChapters
    local found = false
    local i = 0
    novelPage:setNovelChapters(AsList(mapNotNil(document:selectFirst("div.listmain"):selectFirst("dl"):children(), function(v)
        if found then
            local chapter = NovelChapter()
            chapter:setOrder(i)
            local data = v:selectFirst("a")
            chapter:setTitle(data:text())
            chapter:setLink(baseURL .. data:attr("href"))
            i = i + 1
            return chapter
        else
            if v:text():match("正文卷") then
                found = true
            end
            return nil
        end
    end)))
    return novelPage
end

---@param document Document @Jsoup document of the novel information page
---@param increment number @Page #
---@return NovelPage
local function parseNovelI(document, increment)
    return parseNovel(document)
end

---@param url string @url of novel page
---@param increment number @which page
local function novelPageCombiner(url, increment)
    return url
end

---@param document Document @Jsoup document of latest listing
---@return Array @Novel array list
local function parseLatest(document)
    return AsList(map(document:selectFirst("div.up"):selectFirst("div.l"):select("li"), function(v)
        local novel = Novel()
        local data = v:selectFirst("span.s2"):selectFirst("a")
        novel:setTitle(data:text())
        novel:setLink(baseURL .. data:attr("href"))
        return novel
    end))
end

---@param document Document @Jsoup document of search results
---@return Array @Novel array list
local function parseSearch(document)
    return AsList(map(document:select("div.bookbox"), function(v)
        local novel = Novel()
        local data = document:selectFirst("h4.bookname"):selectFirst("a")
        novel:setTitle(data:text())
        novel:setLink(baseURL .. data:attr("href"))
        novel:setImageURL(baseURL .. document:selectFirst("a"):attr("href"))
    end))
end

---@param query string @query to use
---@return string @url
local function getSearchString(query)
    return baseURL .. "/s.php?ie=utf-8&q=" .. query:gsub("+", "%2B"):gsub(" ", "+")
end

return {
    id = 234,
    name = "Tangsanshu",
    imageURL = "",
    genres = {},
    hasCloudFlare = false,
    latestOrder = Ordering(0),
    chapterOrder = Ordering(0),
    isIncrementingChapterList = false,
    isIncrementingPassagePage = false,
    hasSearch = true,
    hasGenres = false,

    getLatestURL = getLatestURL,
    getNovelPassage = getNovelPassage,
    parseNovel = parseNovel,
    parseNovelI = parseNovelI,
    novelPageCombiner = novelPageCombiner,
    parseLatest = parseLatest,
    parseSearch = parseSearch,
    getSearchString = getSearchString
}