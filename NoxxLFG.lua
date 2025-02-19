-- [NoxxLFG @ https://www.curseforge.com/wow/addons/noxxlfg]

-- Construct and post messages that dynamically update as you build your group.
-- Quickly find what you need by using at-a-glance icons like gold/silver amount for travel or role icons for raid/dungeon finding!
-- Select the specific category you need to keep the LFG frame light and focused on a specific type of group you're trying to find.
-- By default, NoxxLFG will not log groups or posts unless you are using it, reserving your memory for more important things.

-- NNNNNNNN        NNNNNNNN                                                       LLLLLLLLLLL             FFFFFFFFFFFFFFFFFFFFFF       GGGGGGGGGGGGGG
-- N:::::::N       N::::::N                                                       L:::::::::L             F::::::::::::::::::::F    GGGG::::::::::::G
-- N::::::::N      N::::::N                                                       L:::::::::L             F::::::::::::::::::::F  GGF:::::::::::::::G
-- N:::::::::N     N::::::N                                                       LL:::::::LL             FF::::::FFFFFFFFF::::F G::::::GGGGGGGG::::G
-- N::::::::::N    N::::::N   ooooooooooo xxxxxxx      xxxxxxxxxxxxxx      xxxxxxx  L:::::L                 F:::::F       FFFFFFG:::::G       GGGGGGG
-- N:::::::::::N   N::::::N oo:::::::::::oox:::::x    x:::::x  x:::::x    x:::::x   L:::::L                 F:::::F            G:::::G
-- N:::::::N::::N  N::::::No:::::::::::::::ox:::::x  x:::::x    x:::::x  x:::::x    L:::::L                 F::::::FFFFFFFFFF  G:::::G
-- N::::::N N::::N N::::::No:::::ooooo:::::o x:::::xx:::::x      x:::::xx:::::x     L:::::L                 F:::::::::::::::F  G:::::G    GGGGGGGGGGG
-- N::::::N  N::::N:::::::No::::o     o::::o  x::::::::::x        x::::::::::x      L:::::L                 F:::::::::::::::F  G:::::G    G:::::::::G
-- N::::::N   N:::::::::::No::::o     o::::o   x::::::::x          x::::::::x       L:::::L                 F::::::FFFFFFFFFF  G:::::G    GGGGG:::::G
-- N::::::N    N::::::::::No::::o     o::::o   x::::::::x          x::::::::x       L:::::L                 F:::::F            G:::::G        G:::::G
-- N::::::N     N:::::::::No::::o     o::::o  x::::::::::x        x::::::::::x      L:::::L         LLLLLL  F:::::F             G:::::G       G:::::G
-- N::::::N      N::::::::No:::::ooooo:::::o x:::::xx:::::x      x:::::xx:::::x   LL:::::::LLLLLLLLL:::::LFF:::::::FF            G:::::GGGGGGGG:::::G
-- N::::::N       N:::::::No:::::::::::::::ox:::::x  x:::::x    x:::::x  x:::::x  L::::::::::::::::::::::LF::::::::FF             GG::::::::::::::::G
-- N::::::N        N::::::N oo:::::::::::oox:::::x    x:::::x  x:::::x    x:::::x L::::::::::::::::::::::LF::::::::FF               GGG::::::GGG::::G
-- NNNNNNNN         NNNNNNN   ooooooooooo xxxxxxx      xxxxxxxxxxxxxx      xxxxxxxLLLLLLLLLLLLLLLLLLLLLLLLFFFFFFFFFFF                  GGGGGG   GGGGG

---@diagnostic disable: undefined-field

NoxxLFGBlueColorNoC = "FFF09050"
NoxxLFGBlueColor = "|c" .. NoxxLFGBlueColorNoC
local addonName = "NoxxLFG Classic"
local versionNum = "1.0.0"
local LibDD = LibStub:GetLibrary("LibUIDropDownMenu-4.0")
local shortMessageLength = 35
local hoveredCategory = false
local lfmCreationMessage = ""
local lfgCreationMessage = ""
local postingMessage = false
local postingLFGMessage = false
local triedToShowPopup = false
local triedToShowPlayerNames = {}
local postingMessageTimer = 30
local totalRoles = 0
local startedWithRoles = false
local headerColor = "|cFFFCC453"
local messageTimer
local LFGMessageTimer

local classColor = {
	["WARRIOR"] = "FFC79C6E",
	["PALADIN"] = "FFF58CBA",
	["HUNTER"] = "FFABD473",
	["ROGUE"] = "FFFFF569",
	["PRIEST"] = "FFFFFFFF",
	["SHAMAN"] = "FFF58CBA",
	["MAGE"] = "FF69CCF0",
	["WARLOCK"] = "FF9482C9",
	["DRUID"] = "FFFF7D0A",
}

local function CancelTimer()
	if not postingMessage and messageTimer then
		messageTimer:Cancel()
		messageTimer = nil
	end
end

local function CancelLFGTimer()
	if not postingLFGMessage and LFGMessageTimer then
		LFGMessageTimer:Cancel()
		LFGMessageTimer = nil
	end
end

if not NoxxLFGSettings then
	NoxxLFGSettings = {}
end

if not NoxxLFGSetRole then
	NoxxLFGSetRole = {}
end

if not NoxxLFGSettings.pausedSearching then
	NoxxLFGSettings.pausedSearching = false
end

if not NoxxLFGListings then
	NoxxLFGListings = {}
end

if not NoxxMinimapPosDB then
	NoxxMinimapPosDB = {}
end

if not NoxxLFGListings.dungeonGroups then
	NoxxLFGListings.dungeonGroups = {}
end

if not NoxxLFGListings.raidGroups then
	NoxxLFGListings.raidGroups = {}
end

if not NoxxLFGSettings.nlfgdebugmode then
	NoxxLFGSettings.nlfgdebugmode = false
end

local travelGroups = {}
local servicesGroups = {}
local eventsGroups = {}

local ignoreGroups = {
	"selling",
	"WTS",
	"WTB",
	"inv",
	"DMF",
	"smooth",
	"arms",
	"recruit",
	"casual",
	"service",
	"free",
	"tip",
	"roster",
	"LFW",
	"?",
	"what",
	"level",
	"lvl",
	"quest",
}

local ignoreEventsGroups = {
	"selling",
	"WTS",
	"WTB",
	"DMF",
	"smooth",
	"arms",
	"recruit",
	"casual",
	"service",
	"free",
	"tip",
	"roster",
	"LFW",
	"?",
	"what",
	"level",
	"lvl",
}

local ignoreSummoningGroups = { "WTB", "paying", "LF", "Need", "Tank", "DPS", "Healer", "|Hitem:", "any" }
local ignoreServicesGroups = { "WTS |Hitem:", "LF ", "Need", "Tank", "DPS", "Healer", "WTB" }

local dungeons = {
	{
		name = "Ragefire Chasm",
		location = "Orgrimmar (The Cleft of Shadow)",
		levelRange = "13-19",
		aliases = { "RFC", "Ragefire Chasm", "Ragefire", "Rage Fire", "Rage Fire Chasm", "Chasm" },
		color = "FFDD7C7C",
		checked = true,
	},
	{
		name = "Deadmines",
		location = "Westfall (Moonbrook)",
		levelRange = "18-24",
		aliases = { "VC", "VanCleef", "Van Cleef", "Deadmines", "Dead Mines" },
		color = "FFE9866D",
		checked = true,
	},
	{
		name = "Wailing Caverns",
		location = "The Barrens (South of Crossroads)",
		levelRange = "19-25",
		aliases = { "WC", "Wailing Caverns" },
		color = "FF86E96D",
		checked = true,
	},
	{
		name = "Shadowfang Keep",
		location = "Silverpine Forest (South of The Sepulcher)",
		levelRange = "23-27",
		aliases = { "Shadowfang Keep", "Shadow Fang Keep", "SFK", "Arugal" },
		color = "FFBC6DE9",
		checked = true,
	},
	{
		name = "The Stockades",
		location = "Stormwind (Northeast of The Mage Quarter)",
		levelRange = "24-32",
		aliases = { "Stocks", "Stockades", "The Stockades" },
		color = "FF6DB7E9",
		checked = true,
	},
	{
		name = "Gnomeregan",
		location = "Dun Morogh (Northwestern)",
		levelRange = "29-38",
		aliases = { "Gnomer", "Gnomeregan" },
		color = "FF98E5F3",
		checked = true,
	},
    {
		name = "Blackfathom Deeps",
		location = "Ashenvale (Western Coast)",
		levelRange = "24-32",
		aliases = { "BFD", "Blackfathom", "Black Fathom Deeps", "Deeps" },
		color = "FF3E8AEE",
		checked = true,
	},
	{
		name = "Scarlet Monestary",
		location = "Tirisfal Glades (Northeast Corner)",
		levelRange = "29-42",
		aliases = { "SM", "Scarlet Monestary", "Scarlet", "GY", "Cath", "Arm", "Lib" },
		subDungeon = {
			["Graveyard"] = { aliases = { "Graveyard", "GY" } },
			["Library"] = { aliases = { "Lib", "Library" } },
			["Armory"] = { aliases = { "Armory", "Arm", "ARM" } },
			["Cathedral"] = { aliases = { "Cath", "Cathedral" } },
		},
		color = "FFF5BDDE",
		checked = true,
	},
	{
		name = "Uldaman",
		location = "The Badlands (North Valley)",
		levelRange = "42-50",
		aliases = { "Uldaman", "Uld", "Ulda", "Uldman" },
		color = "FFE9E76D",
		checked = true,
	},
	{
		name = "Razorfen Kraul",
		location = "The Barrens (Southwestern Pass)",
		levelRange = "28-34",
		aliases = { "Razor Fen Kraul", "Razorfen Kraul", "RFK", "Kraul" },
		color = "FFEC8448",
		checked = true,
	},
	{
		name = "Razorfen Downs",
		location = "The Barrens (Southeastern Pass)",
		levelRange = "41-46",
		aliases = { "Razor Fen Downs", "Razorfen Downs", "RFD", "Downs" },
		color = "FFF1742B",
		checked = true,
	},
	{
		name = "Zul'Farrak",
		location = "Tanaris (Northwest of Gadgetzan)",
		levelRange = "43-50",
		aliases = { "ZF", "zul", "farrak", "zulfarrak" },
		color = "FF5AB972",
		checked = true,
	},
	{
		name = "Maraudon",
		location = "Desolace (North of Shadowprey Village)",
		levelRange = "45-52",
		aliases = {
			"Mara",
			"Purple",
			"Orange",
			"Inner",
			"Maraudon",
			"Marudon",
			"Maru",
			"Wicked",
			"Grotto",
			"Foulspore",
			"Earth Song",
			"Falls",
		},
		subDungeon = {
			["Wicked Grotto (Purple)"] = { aliases = { "Purple", "WG", "Grotto", "Wicked" } },
			["Foulspore Cavern (Orange)"] = { aliases = { "Orange", "Foulspore", "Cavern" } },
			["Earth Song Falls (Inner)"] = { aliases = { "Earth Song", "Falls", "Inner" } },
			["Wild Offerings"] = { aliases = { "Wild", "Offerings", "WO" } },
		},
		color = "FFEC9F6C",
		checked = true,
	},
	{
		name = "Blackrock Depths",
		location = "Blackrock Mountain (Lower)",
		levelRange = "50-60",
		aliases = { "BRD", "Blackrock", "Depths" },
		color = "FFE23F2A",
		checked = true,
	},
	{
		name = "Blackrock Spire",
		location = "Blackrock Mountain (Upper)",
		levelRange = "55-60",
		aliases = {
			"Blackrock Spire",
			"BRS",
			"UBRS",
			"LBRS",
			"Spire",
		},
		subDungeon = {
			["UBRS"] = { aliases = { "UBRS", "Upper" } },
			["LBRS"] = { aliases = { "LBRS", "Lower" } },
		},
		color = "FFD11736",
		checked = true,
	},
    {
		name = "Temple of Atal'Hakkar",
		location = "Swamp of Sorrows (East of Stonard)",
		levelRange = "50-60",
		aliases = { "ST", "Sunken", "Atal", "Hakkar" },
		color = "FF319642",
		checked = true,
	},
	{
		name = "Dire Maul",
		location = "Northern Feralas",
		levelRange = "55-60",
		aliases = {
			"DiM",
			"DM West",
			"DM East",
			"DM North",
			"DM",
			"Dire",
			"Maul",
		},
		subDungeon = {
			["West"] = { aliases = { "West", "Capital", "Gardens", "CG" } },
			["East"] = { aliases = { "East", "Warp", "Quarter", "WQ", "WWQ" } },
			["North"] = { aliases = { "North", "Gordok", "Commons", "GC" } },
		},
		color = "FF9FCC74",
		checked = true,
	},
	{
		name = "Stratholme",
		location = "Eastern Plaguelands (North)",
		levelRange = "56-60",
		aliases = {
			"Strat",
			"UD Strat",
			"Living",
			"Live Strat",
			"Strat Live",
			"Undead Strat",
			"Scarlet Strat",
			"Stratholme",
		},
		subDungeon = {
			["Undead"] = { aliases = { "UD", "Undead", "BD", "Dead", "Scourge", "Baron" } },
			["Living"] = { aliases = { "Living", "Live", "Scarlet", "FD", "West", "Hu", "Human", "Light", "Liveside" } },
		},
		color = "FFD69FE4",
		checked = true,
	},
	{
		name = "Scholomance",
		location = "Western Plaguelands (Southern)",
		levelRange = "56-60",
		aliases = { "Scholo", "Scholomance" },
		color = "FFEB84C4",
		checked = true,
	},
}

local raids = {
	{
		name = "Onyxia's Lair",
		location = "Dustwallow Marsh",
		levelRange = "60",
		aliases = { "Onyxia", "Lair", "OL", "Onyxia's Lair", "Ony" },
		color = "FFDD9F64",
		checked = true,
	},
	{
		name = "Zul'Gurub",
		location = "Stranglethorn Vale (Eastern)",
		levelRange = "60",
		aliases = { "ZG", "Zul'Gurub", "Zul", "Gurub" },
		color = "FFB3E778",
		checked = true,
	},
	{
		name = "Molten Core",
		location = "Blackrock Mountain (Bottom)",
		levelRange = "60",
		aliases = { "MC", "Molten", "Core" },
		color = "FFF7665C",
		checked = true,
	},
	{
		name = "Blackwing Lair",
		location = "Blackrock Mountain (Upper)",
		levelRange = "60",
		aliases = { "BWL", "Blackwing", "Lair" },
		color = "FFF7A25C",
		checked = true,
	},
	{
		name = "Ruins of Ahn'Qiraj",
		location = "Silithus (Southern)",
		levelRange = "60",
		aliases = { "AQ20", "Ruins", "RAQ", "RQ" },
		color = "FFEEF07B",
		checked = true,
	},
	{
		name = "Temple of Ahn'Qiraj",
		location = "Silithus (Southern)",
		levelRange = "60",
		aliases = { "AQ40", "Temple", "TAQ", "TQ" },
		color = "FFF0DE7B",
		checked = true,
	},
	{
		name = "Naxxramas",
		location = "Eastern Plaguelands (Floating)",
		levelRange = "60",
		aliases = { "Naxx", "Ramas", "Naxxramas", "NX" },
		color = "FF99E2D6",
		checked = true,
	},
}

local summons = {
	{
		name = "Stormwind",
		aliases = { "SW", "Stormwind", "Storm Wind" },
		color = "FF56BCF7",
	},
	{
		name = "Darnassus",
		aliases = { "Darn", "Darnassus", "Darnasus" },
		color = "FFA44CC7",
	},
	{
		name = "Ironforge",
		aliases = { "IF", "Ironforge", "Iron Forge" },
		color = "FFDA904A",
	},
	{
		name = "Orgrimmar",
		aliases = { "Org", "Orgrimmar" },
		color = "FFB84E33",
	},
	{
		name = "Thunder Bluff",
		aliases = { "TB", "Thunder Bluff", "Thunderbluff" },
		color = "FF95EEC9",
	},
	{
		name = "Darkmoon Faire",
		aliases = { "DMF", "Dark Moon Faire", "Darkmoon Faire", "Dark Moon", "Mulgore" },
		color = "FFCE66A6",
	},
	{
		name = "Undercity",
		aliases = { "UC", "Undercity", "Under City" },
		color = "FF9475E9",
	},
	{
		name = "Strangethorn Vale",
		aliases = {
			"STV",
			"Stranglethorn Vale",
			"Strangle Thorn Vale",
			"Blood Moon",
			"BM",
			"Booty Bay",
			"Bootybay",
			"BB",
		},
		color = "FF389635",
	},
	{
		name = "The Barrens",
		aliases = { "Barrens", "Ratchet", "Crossroads", "Cross roads" },
		color = "FFC8D458",
	},
	{
		name = "Scarlet Monestary",
		aliases = { "SM", "Scarlet", "Monestary" },
		color = "FFF5BDDE",
	},
	{
		name = "Desolace",
		aliases = { "Desolace", "Deso" },
		color = "FFA09285",
	},
	{
		name = "Westfall",
		aliases = { "Westfall", "WF", "Sentinel Hill", "West Fall" },
		color = "FFE7D571",
	},
	{
		name = "Badlands",
		aliases = { "Badlands", "Bad Lands", "BL", "Kargath" },
		color = "FFDD933F",
	},
	{
		name = "Tanaris",
		aliases = { "Tanaris", "Steamwheedle", "Gadget", "Gadgetzan", "ZF", "Zul'Farrak", "ZulFarrak", "Zul Farrak" },
		color = "FFBEA384",
	},
	{
		name = "Hinterlands",
		aliases = { "Hinterlands", "Hinter" },
		color = "FF88A276",
	},
	{
		name = "Feralas",
		aliases = { "Feralas", "Fera" },
		color = "FF4B925E",
	},
	{
		name = "Duskwood",
		aliases = { "Dusk", "Duskwood", "DW" },
		color = "FF82B19A",
	},
	{
		name = "Ashenvale",
		aliases = { "Ash", "Ashenvale", "Ashen" },
		color = "FF936C97",
	},
	{
		name = "Moonglade",
		aliases = { "Moon", "Glade", "Glades", "Moonglades", "Moonglade" },
		color = "FF9BDFD4",
	},
}

local services = {
	{
		name = "Enchanting",
		aliases = { "Enchanting", "Ench", "Chanting" },
		color = "FF73EEC5",
	},
	{
		name = "Tailoring",
		aliases = { "Tailoring", "Tailor" },
		color = "FFE7EEF1",
	},
	{
		name = "Engineering",
		aliases = { "Eng", "Engineering" },
		color = "FF8CBB9C",
	},
	{
		name = "Blacksmithing",
		aliases = { "BS", "Blacksmithing", "Black Smithing", "Smithing" },
		color = "FFDB6666",
	},
	{
		name = "Lockpicking",
		aliases = { "Lockbox", "Lock Box", "Boxes", "Lockpicking", "Picking" },
		color = "FFDAE264",
	},
	{
		name = "Alchemy",
		aliases = { "Alchemy", "Alch" },
		color = "FFB076C7",
	},
	{
		name = "Leatherworking",
		aliases = { "LW", "Leatherworking", "Leather" },
		color = "FFD6782A",
	},
	{
		name = "Leatherworking",
		aliases = { "LW", "Leatherworking", "Leather" },
		color = "FFD6782A",
	},
	{
		name = "Cooking",
		aliases = { "Cooking" },
		color = "FF567E91",
	},
	{
		name = "Boosting",
		aliases = { "Boost", "Boosting" },
		color = "FFEB3D37",
	},
}

local lfEventPhrases = { "Looking For", "LF" }

local worldEvents = {
	-- {
	-- 	type = "PvE",
	-- 	name = "Nightmare Incursion",
	-- 	aliases = {
	-- 		"Nightmare",
	-- 		"Incursion",
	-- 		"Nightmares",
	-- 		"Incursions",
	-- 		"Incur",
	-- 		"Inc",
	-- 		"Loop",
	-- 		"Loops",
	-- 		"Incurs",
	-- 		"NI",
	-- 	},
	-- 	subEvent = {
	-- 		["Ashenvale"] = { aliases = { "Ash", "Ashen", "Ashenvale" } },
	-- 		["Hinterlands"] = { aliases = { "Hint", "Hinter", "Hinterlands", "Hinterland", "Hints" } },
	-- 		["Feralas"] = { aliases = { "Fera", "Feralas", "Fer", "Ferelas" } },
	-- 		["Duskwood"] = { aliases = { "Dusk", "Duskwood", "Dusk Wood", "Dusky" } },
	-- 	},
	-- 	color = "FFBB71E5",
	-- },
	-- {
	-- 	type = "PvP",
	-- 	name = "Blood Moon (PvP)",
	-- 	aliases = { "BM", "Blood Moon", "Bloodmoon", "STV" },
	-- 	color = "FFE42F29",
	-- },
	-- {
	-- 	type = "PvP",
	-- 	name = "Ashenvale (PvP)",
	-- 	aliases = { "East", "West", "Mid", "Fel", "Moonray", "Kaz" },
	-- 	color = "FF8CBB9C",
	-- },
	{
		type = "PvP",
		name = "Pre-made Group (PvP)",
		aliases = {
			"Premade",
			"Pre-made",
			"WSG",
			"Warsong",
			"AB",
			"Arathi",
			"AV",
			"Alterac",
		},
		subEvent = {
			["Warsong Gulch"] = { aliases = { "WSG", "Warsong", "Gulch", "War Song" } },
			["Arathi Basin"] = { aliases = { "AB", "Arathi", "Basin" } },
			["Alterac Valley"] = { aliases = { "AV", "Alterac", "Valley" } },
		},
		color = "FFCA9354",
	}
}

local mainFrame = CreateFrame("ScrollFrame", "NoxxLFGMainFrame", UIParent, "BasicFrameTemplateWithInset")
mainFrame:SetSize(790, 550)
mainFrame:SetPoint("CENTER", UIParent, "CENTER", -280, 30)
mainFrame.TitleBg:SetHeight(30)
mainFrame.title = mainFrame:CreateFontString(nil, "OVERLAY")
mainFrame.title:SetFontObject("GameFontHighlight")
mainFrame.title:SetPoint("TOPLEFT", mainFrame.TitleBg, "TOPLEFT", 5, 0)
mainFrame.title:SetText(
	"|TInterface/AddOns/NoxxLFG/images/icon:20:20|t " .. NoxxLFGBlueColor .. addonName .. " v" .. versionNum .. "|r"
)
mainFrame:EnableMouse(true)
mainFrame:SetMovable(true)
mainFrame:RegisterForDrag("LeftButton")
mainFrame:SetScript("OnDragStart", function(self)
	self:StartMoving()
end)
mainFrame:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
end)
mainFrame:Hide()

mainFrame:SetScript("OnHide", function()
	PlaySound(808)
end)

mainFrame:SetScript("OnShow", function()
	PlaySound(808)
end)

local sideWindow = CreateFrame("Frame", "NoxxLFGFSideWindow", mainFrame, "BasicFrameTemplateWithInset")
sideWindow:SetSize(275, 300)
sideWindow:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", 280, 0)
sideWindow:SetFrameStrata("HIGH")

sideWindow.TitleBg:SetHeight(30)
sideWindow.title = sideWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
sideWindow.title:SetPoint("TOPLEFT", sideWindow.TitleBg, "TOPLEFT", 5, -2)

sideWindow.activityTitle = sideWindow:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
sideWindow.activityTitle:SetPoint("TOPLEFT", sideWindow, "TOPLEFT", 10, -30)

sideWindow.activityTitleSub = sideWindow:CreateFontString(nil, "OVERLAY", "GameFontNormal")
sideWindow.activityTitleSub:SetPoint("TOPLEFT", sideWindow.activityTitle, "TOPLEFT", 0, -15)

sideWindow.messageFrame = CreateFrame("Frame", "NoxxLFGSideWindowMessageFrame", sideWindow, "BackdropTemplate")
sideWindow.messageFrame:SetWidth(sideWindow:GetWidth() - 20)
sideWindow.messageFrame:SetHeight(100)
sideWindow.messageFrame:SetBackdrop({
	bgFile = "interface/garrison/classhallinternalbackground",
	edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
	tile = true,
	tileSize = 256,
	edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
sideWindow.messageFrame.message = sideWindow.messageFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
sideWindow.messageFrame.message:SetPoint("TOPLEFT", sideWindow.messageFrame, "TOPLEFT", 8, -8)
sideWindow.messageFrame.message:SetWidth(sideWindow.messageFrame:GetWidth() - 10)
sideWindow.messageFrame.message:SetJustifyH("LEFT")
sideWindow.messageFrame.message:SetScale(0.9)
sideWindow.messageFrame.message:SetWordWrap(true)
sideWindow.messageFrame.spamDungeon = sideWindow.messageFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
sideWindow.messageFrame.spamDungeon:SetScale(0.8)
sideWindow.messageFrame.spamDungeon:SetPoint("BOTTOMRIGHT", sideWindow.messageFrame, "BOTTOMRIGHT", -8, 8)

sideWindow.actionFrame = CreateFrame("Frame", "NoxxLFGSideWindowActionFrame", sideWindow, "BackdropTemplate")
sideWindow.actionFrame:SetPoint("TOPLEFT", sideWindow.messageFrame, "BOTTOMLEFT", 0, -5)
sideWindow.actionFrame:SetWidth(sideWindow:GetWidth() - 20)
sideWindow.actionFrame:SetHeight(60)
sideWindow.actionFrame:SetBackdrop({
	bgFile = "interface/garrison/classhallinternalbackground",
	edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
	tile = true,
	tileSize = 256,
	edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
sideWindow.actionFrame:SetBackdropBorderColor(0.6, 0.6, 0.6)
sideWindow.actionFrame.inviteButton =
	CreateFrame("Button", "NoxxLFGSideWindowInviteButton", sideWindow, "UIPanelButtonTemplate")
sideWindow.actionFrame.inviteButton:SetFrameStrata("DIALOG")
sideWindow.actionFrame.inviteButton:SetPoint("TOPLEFT", sideWindow.actionFrame, "TOPLEFT", 8, -8)
sideWindow.actionFrame.inviteButton:SetSize(115, 20)
sideWindow.actionFrame.inviteButton:SetText("Invite to Group")
sideWindow.actionFrame.whisperButton =
	CreateFrame("Button", "NoxxLFGSideWindowInviteButton", sideWindow, "UIPanelButtonTemplate")
sideWindow.actionFrame.whisperButton:SetFrameStrata("DIALOG")
sideWindow.actionFrame.whisperButton:SetPoint("TOPLEFT", sideWindow.actionFrame.inviteButton, "BOTTOMLEFT", 0, -5)
sideWindow.actionFrame.whisperButton:SetSize(115, 20)
sideWindow.actionFrame.whisperButton:SetText("Start Whisper")
sideWindow.actionFrame.whoButton =
	CreateFrame("Button", "NoxxLFGSideWindowInviteButton", sideWindow, "UIPanelButtonTemplate")
sideWindow.actionFrame.whoButton:SetFrameStrata("DIALOG")
sideWindow.actionFrame.whoButton:SetPoint("LEFT", sideWindow.actionFrame.inviteButton, "RIGHT", 5, 0)
sideWindow.actionFrame.whoButton:SetSize(115, 20)
sideWindow.actionFrame.whoButton:SetText("/who Player")

sideWindow.actionFrame.locationInfo = sideWindow.actionFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
sideWindow.actionFrame.locationInfo:SetJustifyH("LEFT")
sideWindow.actionFrame.locationInfo:SetPoint("BOTTOMLEFT", sideWindow.actionFrame, "BOTTOMLEFT", 3, -40)

sideWindow:Hide()

local settingsFrame = CreateFrame("Frame", "NoxxLFGSettingsFrame", UIParent, "BasicFrameTemplateWithInset")
settingsFrame:SetPoint("CENTER")
settingsFrame:SetSize(400, 500)
settingsFrame.TitleBg:SetHeight(30)
settingsFrame.title = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
settingsFrame.title:SetPoint("TOPLEFT", settingsFrame.TitleBg, "TOPLEFT", 5, -2)
settingsFrame.title:SetText(NoxxLFGBlueColor .. addonName .. "|r Settings")
settingsFrame:EnableMouse(true)
settingsFrame:SetMovable(true)
settingsFrame:RegisterForDrag("LeftButton")
settingsFrame:SetScript("OnDragStart", function(self)
	self:StartMoving()
end)
settingsFrame:SetScript("OnDragStop", function(self)
	self:StopMovingOrSizing()
end)
settingsFrame:Hide()

mainFrame.settingsButton = CreateFrame("Button", "NoxxLFGSettingsButtonFrame", mainFrame)
mainFrame.settingsButton:SetSize(24, 24)
mainFrame.settingsButton:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -14, -32)
mainFrame.settingsButton.settingsButtonTexture = mainFrame.settingsButton:CreateTexture(nil, "OVERLAY")
mainFrame.settingsButton.settingsButtonTexture:SetAllPoints(mainFrame.settingsButton)
mainFrame.settingsButton.settingsButtonTexture:SetTexture("Interface\\AddOns\\NoxxLFG\\images\\settingbuttonatlas")
mainFrame.settingsButton.settingsButtonTexture:SetTexCoord(0, 0.5, 0, 0.5)

mainFrame.settingsButton:SetScript("OnEnter", function()
	mainFrame.settingsButton.settingsButtonTexture:SetTexCoord(0.5, 1, 0, 0.5)
end)

mainFrame.settingsButton:SetScript("OnLeave", function()
	mainFrame.settingsButton.settingsButtonTexture:SetTexCoord(0, 0.5, 0, 0.5)
end)

mainFrame.settingsButton:SetScript("OnMouseDown", function()
	PlaySound(808)
	mainFrame.settingsButton.settingsButtonTexture:SetTexCoord(0, 0.5, 0.5, 1)
end)

mainFrame.settingsButton:SetScript("OnMouseUp", function()
	mainFrame:Hide()
	settingsFrame:Show()
	mainFrame.settingsButton.settingsButtonTexture:SetTexCoord(0, 0.5, 0, 0.5)
end)

settingsFrame:SetScript("OnHide", function(self)
	PlaySound(808)
	mainFrame:Show()
end)

StaticPopupDialogs["CONFIRM_RELOAD_UI"] = {
	text = "This change require a UI reload to reflect changes in the addon. Reload now?",
	button1 = "Sure, reload!",
	button2 = "Not now.",
	OnAccept = function()
		ReloadUI()
	end,
	timeout = 0,
	whileDead = true,
	hideOnEscape = true,
	preferredIndex = 3,
}

local function ShowReloadConfirmation()
	StaticPopup_Show("CONFIRM_RELOAD_UI")
end

local settings = {
	["Performance"] = {
		{
			text = "Update While Only In-Use",
			key = "enableUpdateInUse",
			tooltip = "This will only update your |cFFFFFFFFNoxxLFG list|r while you have the relevant page showing.\n\n|cFFFFFF00Disabling this may cause performance hitches based on your realm population. Looking good unfortunately comes with its cost.",
		},
	},
	["Character"] = {
		{
			type = "Dropdown",
			text = "Your Character Role",
			key = "role",
			options = { "Not Set", "DPS", "Tank", "Healer" },
			defaultOption = "Not Set",
			width = 80,
			tooltip = "When set, NoxxLFG will highlight posts that contain your role.",
		},
	},
	["General Settings"] = {
		{
			type = "Dropdown",
			text = "|cFFb265c2Travel|r Removal Interval (sec)",
			key = "travelUpdateInterval",
			options = { 30, 60, 90, 120 },
			defaultOption = 60,
			width = 60,
			tooltip = 'Entries in the |cFFFFFFFF"Travel"|r category will disappear after the set time.',
		},
		{
			type = "Dropdown",
			text = "|cFFb5b5b5Dungeons|r Removal Interval (sec)",
			key = "dungeonsUpdateInterval",
			options = { 60, 90, 120, 150, 300 },
			defaultOption = 90,
			width = 60,
			tooltip = 'Entries in the |cFFFFFFFF"Dungeons"|r category will disappear after the set time.',
		},
		{
			type = "Dropdown",
			text = "|cFFe86b6bRaids|r Removal Interval (sec)",
			key = "raidsUpdateInterval",
			options = { 60, 90, 120, 150, 300 },
			defaultOption = 90,
			width = 60,
			tooltip = 'Entries in the |cFFFFFFFF"Raids"|r category will disappear after the set time.',
		},
		{
			type = "Dropdown",
			text = "|cFF7be08cServices|r Removal Interval (sec)",
			key = "servicesUpdateInterval",
			options = { 30, 60, 90, 120, 300 },
			defaultOption = 60,
			width = 60,
			tooltip = 'Entries in the |cFFFFFFFF"Services"|r category will disappear after the set time.',
		},
		{
			type = "Dropdown",
			text = "|cFF5d8ea3Events|r Removal Interval (sec)",
			key = "eventsUpdateInterval",
			options = { 30, 60, 90, 120, 300 },
			defaultOption = 60,
			width = 60,
			tooltip = 'Entries in the |cFFFFFFFF"Events"|r category will disappear after the set time.',
		},
		{
			type = "Dropdown",
			text = "NoxxLFG Window Scale",
			key = "clientScale",
			options = { "140%", "130%", "120%", "110%", "100%", "90%", "80%" },
			defaultOption = "100%",
			width = 60,
			tooltip = "Set the scale of |cFFFFFFFFNoxxLFG|r.",
		},
		{
			type = "Dropdown",
			text = "Opacity Level While Moving",
			key = "windowOpacityWhileMoving",
			options = { "100%", "90%", "80%", "70%", "60%", "50%", "40%", "30%", "20%", "10%" },
			defaultOption = "100%",
			width = 60,
			tooltip = "While moving, set all |cFFFFFFFFNoxxLFG Windows|r to the specified opacity.",
		},
		{
			type = "Textbox",
			text = "Supported Channels:",
			key = "supportedChannels",
			width = 225,
			tooltip = "Add channels you'd like NoxxLFG to support to this list, separated by a comma.",
		},
		{
			type = "Textbox",
			text = "LFM Advertisement Channel:",
			key = "lfmChannel",
			width = 125,
			tooltip = "This defines the channel in which you post your LFM message.",
		},
		{
			type = "Textbox",
			text = "LFG Advertisement Channel:",
			key = "lfgChannel",
			width = 125,
			tooltip = "This defines the channel in which you post your LFG message.",
		},
		{
			text = "Show Spam Groups",
			key = "enableSpamGroups",
			tooltip = 'Having this enabled will display "Multi-run" or "Spam" groups in the |cFFFFFFFFDungeons|r category.',
		},
		{
			text = "Highlight Role-Matching Posts",
			key = "highlightSetRole",
			tooltip = "While enabled, this will ensure posts with a matching role to yours is highlighted in |cFF00FF00Green|r.",
		},
	},
}

local checkboxes = {}

local function CreateCheckbox(parent, id, label, tooltipText, point, dbKey)
	local checkbox = CreateFrame("CheckButton", parent:GetName() .. "Checkbox" .. id, parent, "UICheckButtonTemplate")
	checkbox:SetPoint(unpack(point))
	checkbox.Text:SetText(label)

	if NoxxLFGSettings[dbKey] == nil then
		NoxxLFGSettings[dbKey] = true
	end

	checkbox:SetChecked(NoxxLFGSettings[dbKey])

	checkbox:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetScale(0.8)
		GameTooltip:SetText(tooltipText, nil, nil, nil, nil, true)
	end)

	checkbox:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
		GameTooltip:SetScale(1)
	end)

	checkbox:SetScript("OnClick", function(self)
		NoxxLFGSettings[dbKey] = self:GetChecked()
		if dbKey == "highlightSetRole" then
			ShowReloadConfirmation()
		end
	end)

	return checkbox
end

local function CreateDropdown(parent, id, label, tooltipText, point, dbKey, settingOptions, width, defaultOption)
	local container = CreateFrame("Frame", parent:GetName() .. "Container" .. id, parent)
	container:SetPoint(unpack(point))
	container:SetSize(150, 40)

	local textLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	textLabel:SetText(label)
	textLabel:SetScale(0.8)
	textLabel:SetPoint("LEFT", container, "LEFT", 0, 0)

	local dropdown = LibDD:Create_UIDropDownMenu(parent:GetName() .. "Dropdown" .. id, container)
	dropdown:SetPoint("LEFT", textLabel, "RIGHT", -10, 0)
	dropdown:SetScale(0.8)
	LibDD:UIDropDownMenu_SetWidth(dropdown, width)

	if dbKey ~= "role" then
		if not NoxxLFGSettings[dbKey] or not tContains(settingOptions, NoxxLFGSettings[dbKey]) then
			NoxxLFGSettings[dbKey] = defaultOption
		end
	else
		if not NoxxLFGSetRole[dbKey] or not tContains(settingOptions, NoxxLFGSetRole[dbKey]) then
			NoxxLFGSetRole[dbKey] = defaultOption
		end
	end

	if dbKey ~= "role" then
		LibDD:UIDropDownMenu_SetText(dropdown, NoxxLFGSettings[dbKey])
	else
		LibDD:UIDropDownMenu_SetText(dropdown, NoxxLFGSetRole[dbKey])
	end

	if dbKey ~= "role" then
		LibDD:UIDropDownMenu_Initialize(dropdown, function(self, level, menuList)
			local info = LibDD:UIDropDownMenu_CreateInfo()
			for _, option in ipairs(settingOptions) do
				info.text = option
				info.value = option
				info.func = function(self)
					NoxxLFGSettings[dbKey] = self.value
					LibDD:UIDropDownMenu_SetText(dropdown, self.value)
					LibDD:CloseDropDownMenus()
					if dbKey == "clientScale" then
						local clientScalePercent = strsplit("%", NoxxLFGSettings.clientScale) / 100
						mainFrame:SetScale(clientScalePercent)
						settingsFrame:SetScale(clientScalePercent)
					end
				end
				info.checked = (NoxxLFGSettings[dbKey] == option)
				LibDD:UIDropDownMenu_AddButton(info)
			end
		end)
	else
		LibDD:UIDropDownMenu_Initialize(dropdown, function(self, level, menuList)
			local info = LibDD:UIDropDownMenu_CreateInfo()
			for _, option in ipairs(settingOptions) do
				info.text = option
				info.value = option
				info.func = function(self)
					NoxxLFGSetRole[dbKey] = self.value
					LibDD:UIDropDownMenu_SetText(dropdown, self.value)
					LibDD:CloseDropDownMenus()
				end
				info.checked = (NoxxLFGSetRole[dbKey] == option)
				LibDD:UIDropDownMenu_AddButton(info)
			end
		end)
	end

	dropdown:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(tooltipText, nil, nil, nil, nil, true)
		GameTooltip:SetScale(0.8)
		GameTooltip:Show()
	end)
	dropdown:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
		GameTooltip:SetScale(1)
	end)

	return container
end

local function CreateSettingsTextBox(parent, id, label, tooltipText, point, dbKey, width)
	local container = CreateFrame("Frame", parent:GetName() .. "TextBoxContainer" .. id, parent)
	container:SetPoint(unpack(point))
	container:SetSize(width + 20, 25)
	container.textLabel = container:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	container.textLabel:SetText(label)
	container.textLabel:SetScale(0.8)
	container.textLabel:SetPoint("LEFT", container, "LEFT", 5, 5)

	local textBox = CreateFrame("EditBox", parent:GetName() .. "TextBox" .. id, container, "InputBoxTemplate")
	textBox:SetAutoFocus(false)
	textBox:SetPoint("LEFT", container.textLabel, "RIGHT", 10, 0)
	textBox:SetWidth(width)
	textBox:SetHeight(15)
	textBox:SetScale(0.8)

	local saveButton = CreateFrame("Button", parent:GetName() .. "SaveButton" .. id, container, "UIPanelButtonTemplate")
	saveButton:SetSize(60, 18)
	saveButton:SetText("Save")
	saveButton:SetPoint("LEFT", textBox, "RIGHT", 5, 0)

	if NoxxLFGSettings["supportedChannels"] == nil then
		NoxxLFGSettings["supportedChannels"] = "General, Trade, LookingForGroup, LFG, World"
	elseif NoxxLFGSettings["lfmChannel"] == nil then
		NoxxLFGSettings["lfmChannel"] = "LookingForGroup"
	elseif NoxxLFGSettings["lfgChannel"] == nil then
		NoxxLFGSettings["lfgChannel"] = "LookingForGroup"
	elseif NoxxLFGSettings[dbKey] == nil then
		NoxxLFGSettings[dbKey] = ""
	end
	textBox:SetText(NoxxLFGSettings[dbKey])

	textBox:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetScale(0.8)
		GameTooltip:SetText(tooltipText, nil, nil, nil, nil, true)
		if dbKey == "supportedChannels" then
			GameTooltip:AddLine("\n\n|cFFFFFFFFChannels NoxxLFG will parse:")
			GameTooltip:AddLine("|cFFAAAAAASay")
			GameTooltip:AddLine("|cFFFF3333Yell")

			local channels = NoxxLFGSettings.supportedChannels
			for channel in string.gmatch(channels, "([^,]+)") do
				local trimmedChannel = string.match(channel, "^%s*(.-)%s*$")
				GameTooltip:AddLine(headerColor .. trimmedChannel)
			end
		elseif dbKey == "lfmChannel" then
			GameTooltip:AddLine("\n\n|cFFFFFFFFYour LFM message will post to: ")
			GameTooltip:AddLine(headerColor .. NoxxLFGSettings.lfmChannel)
		elseif dbKey == "lfgChannel" then
			GameTooltip:AddLine("\n\n|cFFFFFFFFYour LFG message will post to: ")
			GameTooltip:AddLine(headerColor .. NoxxLFGSettings.lfgChannel)
		end
		GameTooltip:Show()
	end)

	textBox:SetScript("OnLeave", function(self)
		GameTooltip:Hide()
		GameTooltip:SetScale(1)
	end)

	textBox:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)

	textBox:SetScript("OnEnterPressed", function(self)
		saveButton:Click()
	end)

	saveButton:SetScript("OnClick", function(self)
		textBox:ClearFocus()
		PlaySound(808)
		if dbKey == "lfmChannel" then
			if NoxxLFGSettings.lfmChannel ~= textBox:GetText() then
				print(
					NoxxLFGBlueColor
						.. "NoxxLFG:|r Your LFM messages will now post to: |cFFFFFF00"
						.. textBox:GetText()
						.. "|r. You will need to reload your UI for changes to reflect in NoxxLFG."
				)
				NoxxLFGSettings[dbKey] = textBox:GetText()
				ShowReloadConfirmation()
			end
		elseif dbKey == "lfgChannel" then
			if NoxxLFGSettings.lfgChannel ~= textBox:GetText() then
				print(
					NoxxLFGBlueColor
						.. "NoxxLFG:|r Your LFG messages will now post to: |cFFFFFF00"
						.. textBox:GetText()
						.. "|r. You will need to reload your UI for changes to reflect in NoxxLFG."
				)
				NoxxLFGSettings[dbKey] = textBox:GetText()
				ShowReloadConfirmation()
			end
		else
			NoxxLFGSettings[dbKey] = textBox:GetText()
		end
	end)

	return container
end

local function CreateSettingsUI(settingsFrame)
	local yOffset = -35
	local initialPoint = { 15, -35 }
	local totalHeight = initialPoint[2]

	for category, settingsList in pairs(settings) do
		if totalHeight ~= initialPoint[2] then
			totalHeight = totalHeight + -10
		end

		local categoryHeader = settingsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
		categoryHeader:SetText("|cFFFFFFFF" .. category)
		categoryHeader:SetPoint("TOPLEFT", settingsFrame, "TOPLEFT", initialPoint[1], totalHeight)
		totalHeight = totalHeight + yOffset / 2

		for _, setting in ipairs(settingsList) do
			local point = { "TOPLEFT", settingsFrame, "TOPLEFT", initialPoint[1], totalHeight }
			if setting.type == "Dropdown" then
				point = { "TOPLEFT", settingsFrame, "TOPLEFT", initialPoint[1] + 5, totalHeight + 8 }
			end
			if setting.type == "Dropdown" or setting.type == "Button" then
				totalHeight = totalHeight + -25
			elseif setting.type == "Textbox" then
				totalHeight = totalHeight - 25
			else
				totalHeight = totalHeight + yOffset
			end

			if setting.type == "Dropdown" then
				checkboxes[#checkboxes + 1] = CreateDropdown(
					settingsFrame,
					#checkboxes + 1,
					setting.text,
					setting.tooltip,
					point,
					setting.key,
					setting.options,
					setting.width,
					setting.defaultOption
				)
			elseif setting.type == "Textbox" then
				CreateSettingsTextBox(
					settingsFrame,
					#checkboxes + 1,
					setting.text,
					setting.tooltip,
					point,
					setting.key,
					setting.width
				)
			else
				checkboxes[#checkboxes + 1] =
					CreateCheckbox(settingsFrame, #checkboxes + 1, setting.text, setting.tooltip, point, setting.key)
			end
		end
	end
end

local topHintText = mainFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
topHintText:SetJustifyH("RIGHT")
topHintText:SetPoint("TOPRIGHT", mainFrame, "TOPRIGHT", -70, -45)
topHintText:SetScale(0.8)
topHintText:SetText(NoxxLFGBlueColor .. "Left-click:|cFFFFFFFF Start Whisper|r")
topHintText:Hide()

local categoryFrame = CreateFrame("Frame", "NoxxLFGCategoryFrame", mainFrame, "BackdropTemplate")
categoryFrame:SetAllPoints(categoryFrame:GetParent())

local chooseCategoryText = categoryFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge2")
chooseCategoryText:SetPoint("TOP", categoryFrame, "TOP", 0, -40)
chooseCategoryText:SetText(headerColor .. "Search in Category:")

local lfmlfgButtonGroup = CreateFrame("Frame", nil, mainFrame)
lfmlfgButtonGroup:SetSize(categoryFrame:GetWidth(), 250)
lfmlfgButtonGroup:SetPoint("TOP", categoryFrame, "TOP", 0, -380)

local lfmCreationFrame = CreateFrame("Frame", "NoxxLFGLFMCreationFrame", mainFrame)
lfmCreationFrame:SetSize(mainFrame:GetWidth() - 15, mainFrame:GetHeight() - 30)
lfmCreationFrame:SetPoint("TOP", mainFrame, "TOP", 0, -20)
lfmCreationFrame:Hide()

local lfgCreationFrame = CreateFrame("Frame", "NoxxLFGLFGCreationFrame", mainFrame)
lfgCreationFrame:SetSize(mainFrame:GetWidth() - 15, mainFrame:GetHeight() - 30)
lfgCreationFrame:SetPoint("TOP", mainFrame, "TOP", 0, -20)
lfgCreationFrame:Hide()

local lfmCreationFrameHint = lfmCreationFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
lfmCreationFrameHint:SetPoint("TOPLEFT", lfmCreationFrame, "TOPLEFT", 15, -12)
lfmCreationFrameHint:SetWidth(mainFrame:GetWidth() - 120)
lfmCreationFrameHint:SetWordWrap(true)
lfmCreationFrameHint:SetJustifyH("LEFT")

local lfgCreationFrameHint = lfgCreationFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
lfgCreationFrameHint:SetPoint("TOPLEFT", lfgCreationFrame, "TOPLEFT", 15, -12)
lfgCreationFrameHint:SetWidth(mainFrame:GetWidth() - 120)
lfgCreationFrameHint:SetWordWrap(true)
lfgCreationFrameHint:SetJustifyH("LEFT")

local lfmCreationFrameButton =
	CreateFrame("Button", "NoxxLFGLFMCreationFrameButton", lfmlfgButtonGroup, "UIPanelButtonTemplate")
lfmCreationFrameButton:SetPoint("TOPLEFT", lfmlfgButtonGroup, "TOPLEFT", 35, 0)
lfmCreationFrameButton:SetSize(170, 30)
lfmCreationFrameButton:SetText("Start LFM Message")

lfmCreationFrameButton:SetScript("OnClick", function()
	if not postingLFGMessage then
		lfmlfgButtonGroup:Hide()
		categoryFrame:Hide()
		lfmCreationFrame:Show()
	else
		print(
			NoxxLFGBlueColor
				.. addonName
				.. ":|r Please cancel your LFG posting before attempting to construct an LFM message."
		)
	end
end)

local lfgCreationFrameButton =
	CreateFrame("Button", "NoxxLFGLFMCreationFrameButton", lfmlfgButtonGroup, "UIPanelButtonTemplate")
lfgCreationFrameButton:SetPoint("TOPLEFT", lfmlfgButtonGroup, "TOPLEFT", 35, -40)
lfgCreationFrameButton:SetSize(170, 30)
lfgCreationFrameButton:SetText("Start LFG Message")

lfgCreationFrameButton:SetScript("OnClick", function()
	if not postingMessage then
		lfmlfgButtonGroup:Hide()
		categoryFrame:Hide()
		lfgCreationFrame:Show()
	else
		print(
			NoxxLFGBlueColor
				.. addonName
				.. ":|r Please cancel your LFM posting before attempting to construct an LFG message."
		)
	end
end)

local lfmBackButton = CreateFrame("Button", nil, lfmCreationFrame, "UIPanelButtonTemplate")
lfmBackButton:SetSize(50, 30)
lfmBackButton:SetPoint("TOPLEFT", lfmCreationFrame, "TOPLEFT", 12, -60)
lfmBackButton:SetText("Back")

lfmBackButton:SetScript("OnClick", function()
	lfmCreationFrame:Hide()
	categoryFrame:Show()
	lfmlfgButtonGroup:Show()
end)

local lfgBackButton = CreateFrame("Button", nil, lfgCreationFrame, "UIPanelButtonTemplate")
lfgBackButton:SetSize(50, 30)
lfgBackButton:SetPoint("TOPLEFT", lfgCreationFrame, "TOPLEFT", 12, -60)
lfgBackButton:SetText("Back")

lfgBackButton:SetScript("OnClick", function()
	lfgCreationFrame:Hide()
	categoryFrame:Show()
	lfmlfgButtonGroup:Show()
end)

local lfmPostButtonAuto = CreateFrame("Button", nil, lfmCreationFrame, "UIPanelButtonTemplate")
lfmPostButtonAuto:SetSize(120, 30)
lfmPostButtonAuto:SetPoint("TOPRIGHT", lfmCreationFrame, "TOPRIGHT", -12, -60)
lfmPostButtonAuto:SetText("Repeat Post")

lfmPostButtonAuto:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
	GameTooltip:SetScale(0.8)
	GameTooltip:SetText(
		"|cFFFFFFFFUsing this option enables "
			.. NoxxLFGBlueColor
			.. "Dynamic Message Updating|r.\n\n"
			.. NoxxLFGBlueColor
			.. 'What is Dynamic Message Updating?|r\nIf you started posting your message needing a DPS, Tank or Healer, as you fill your group while this message is using "repeat post," you will be asked what role the person you invited/joins the party fills. It will automatically update your message for you based on your role selection.\n\nOnce the number of Tanks, DPS and Healers reach zero (0), reminders will stop popping up.\n\nA reminder will pop-up every 30 seconds until you cancel it by clicking this button again or your group is filled by using '
			.. NoxxLFGBlueColor
			.. "Dynamic Message Updating|r.",
		nil,
		nil,
		nil,
		nil,
		true
	)
	GameTooltip:Show()
end)

lfmPostButtonAuto:SetScript("OnLeave", function()
	GameTooltip:Hide()
	GameTooltip:SetScale(1)
end)

local lfgPostButtonAuto = CreateFrame("Button", nil, lfgCreationFrame, "UIPanelButtonTemplate")
lfgPostButtonAuto:SetSize(120, 30)
lfgPostButtonAuto:SetPoint("TOPRIGHT", lfgCreationFrame, "TOPRIGHT", -12, -60)
lfgPostButtonAuto:SetText("Repeat Post")

local function SendMessage()
	if lfmCreationMessage and lfmCreationMessage ~= "" then
		local channelName = NoxxLFGSettings.lfmChannel or "LookingForGroup"
		local channelId, channelString = GetChannelName(channelName)

		if channelId == 0 or channelString == nil then
			print(
				NoxxLFGBlueColor
					.. addonName
					.. ': |rFailure to post message to |cFFFFFF00"'
					.. NoxxLFGSettings.lfmChannel
					.. "\"|r. Please check the channel name and make sure you've joined it first!"
			)
			return
		end

		if channelId > 0 then -- LIVE
			if not NoxxLFGSettings.nlfgdebugmode then
				DEFAULT_CHAT_FRAME.editBox:SetText("/" .. channelId .. " " .. lfmCreationMessage)
				ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
			else
				SendChatMessage(lfmCreationMessage, "WHISPER", nil, UnitName("player")) --DEBUGGING MODE
				print(
					NoxxLFGBlueColor
						.. addonName
						.. ":|r You are currently in debug mode! No global messages have been sent!"
				)
				if channelString then
					print("|cFFFFFFFFChat Channel Name: |cFFFFFF00" .. channelString)
				else
					print("|cFFFFFFFFChat Channel Name: |cFFFFFF00Null")
				end
				if channelId then
					print("|cFFFFFFFFChat Channel ID: |cFFFFFF00" .. channelId)
				else
					print("|cFFFFFFFFChat Channel ID: |cFFFFFF00Null")
				end
			end
		else
			print(
				NoxxLFGBlueColor
					.. addonName
					.. ": |rUnable to send message to |cFFFFFF00"
					.. NoxxLFGSettings.lfmChannel
					.. "|r channel! Make sure you've joined the channel first!"
			)
		end
	end
end

local function SendLFGMessage()
	if lfgCreationMessage and lfgCreationMessage ~= "" then
		local channelName = NoxxLFGSettings.lfgChannel or "LookingForGroup"
		local channelId, channelString = GetChannelName(channelName)

		if channelId == 0 or channelString == nil then
			print(
				NoxxLFGBlueColor
					.. addonName
					.. ': |rFailure to post message to |cFFFFFF00"'
					.. NoxxLFGSettings.lfgChannel
					.. "\"|r. Please check the channel name and make sure you've joined it first!"
			)
			return
		end

		if channelId > 0 then -- LIVE
			if not NoxxLFGSettings.nlfgdebugmode then
				DEFAULT_CHAT_FRAME.editBox:SetText("/" .. channelId .. " " .. lfgCreationMessage)
				ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
			else
				SendChatMessage(lfgCreationMessage, "WHISPER", nil, UnitName("player")) --DEBUGGING MODE
				print(
					NoxxLFGBlueColor
						.. addonName
						.. ":|r You are currently in debug mode! No global messages have been sent!"
				)
				if channelString then
					print("|cFFFFFFFFChat Channel Name: |cFFFFFF00" .. channelString)
				else
					print("|cFFFFFFFFChat Channel Name: |cFFFFFF00Null")
				end
				if channelId then
					print("|cFFFFFFFFChat Channel ID: |cFFFFFF00" .. channelId)
				else
					print("|cFFFFFFFFChat Channel ID: |cFFFFFF00Null")
				end
			end
		else
			print(
				NoxxLFGBlueColor
					.. addonName
					.. ": |rUnable to send message to |cFFFFFF00"
					.. NoxxLFGSettings.lfgChannel
					.. "|r channel! Make sure you've joined the channel first!"
			)
		end
	end
end

local lfmPostButton = CreateFrame("Button", nil, lfmCreationFrame, "UIPanelButtonTemplate")
lfmPostButton:SetSize(75, 30)
lfmPostButton:SetPoint("RIGHT", lfmPostButtonAuto, "LEFT", -5, 0)
lfmPostButton:SetText("Post")

lfmPostButton:SetScript("OnClick", function()
	PlaySound(808)
	if not postingMessage or postingLFGMessage then
		SendMessage()
	end
end)

local lfgPostButton = CreateFrame("Button", nil, lfgCreationFrame, "UIPanelButtonTemplate")
lfgPostButton:SetSize(75, 30)
lfgPostButton:SetPoint("RIGHT", lfgPostButtonAuto, "LEFT", -5, 0)
lfgPostButton:SetText("Post")

lfgPostButton:SetScript("OnClick", function()
	PlaySound(808)
	if not postingMessage or postingLFGMessage then
		SendLFGMessage()
	end
end)

local lfmPostButtonReset = CreateFrame("Button", nil, lfmCreationFrame, "UIPanelButtonTemplate")
lfmPostButtonReset:SetSize(75, 30)
lfmPostButtonReset:SetPoint("RIGHT", lfmPostButton, "LEFT", -5, 0)
lfmPostButtonReset:SetText("Reset")

local lfgPostButtonReset = CreateFrame("Button", nil, lfgCreationFrame, "UIPanelButtonTemplate")
lfgPostButtonReset:SetSize(75, 30)
lfgPostButtonReset:SetPoint("RIGHT", lfgPostButton, "LEFT", -5, 0)
lfgPostButtonReset:SetText("Reset")

local lookingForMoreText = lfmCreationFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge2")
lookingForMoreText:SetPoint("TOPLEFT", lfmCreationFrame, "TOPLEFT", 70, -66)
lookingForMoreText:SetText(headerColor .. "Create a Message to Post")

local postAGroupText = lfmlfgButtonGroup:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge2")
postAGroupText:SetPoint("TOP", lfmlfgButtonGroup, "TOP", 0, 20)
postAGroupText:SetText(headerColor .. "Post a Group Advertisement:")

---@diagnostic disable-next-line: param-type-mismatch
postAGroupText:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
	GameTooltip:SetText("Posting Info:")
	GameTooltip:AddLine("LFM Messages Post to: |cFFFFFFFF" .. NoxxLFGSettings.lfmChannel)
	GameTooltip:AddLine("LFG Messages Post to: |cFFFFFFFF" .. NoxxLFGSettings.lfgChannel)
	GameTooltip:Show()
end)

---@diagnostic disable-next-line: param-type-mismatch
postAGroupText:SetScript("OnLeave", function()
	GameTooltip:Hide()
end)

local dungeonCategory = CreateFrame("Frame", "NoxxLFGCategoryDungeonFrame", categoryFrame, "BackdropTemplate")
dungeonCategory:SetSize(325, 125)
dungeonCategory:SetPoint("TOPLEFT", categoryFrame, "TOPLEFT", 15, -100)
dungeonCategory:SetScale(0.80)

local dungeonCategoryText = dungeonCategory:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge2")
dungeonCategoryText:SetPoint("CENTER", dungeonCategory, "CENTER")
dungeonCategoryText:SetScale(1.75)
dungeonCategoryText:SetText(headerColor .. "Dungeons")

local dungeonCategoryTexture = dungeonCategory:CreateTexture(nil, "ARTWORK")
dungeonCategoryTexture:SetAllPoints(dungeonCategoryTexture:GetParent())
dungeonCategoryTexture:SetTexture("interface/adventuremap/adventuremap")
dungeonCategoryTexture:SetTexCoord(0.345703125, 0.78125, 0.0009765625, 0.3017578125)

local dungeonCategoryTextureBg = dungeonCategory:CreateTexture(nil, "BACKGROUND")
dungeonCategoryTextureBg:SetTexture("Interface\\AddOns\\NoxxLFG\\images\\categories")
dungeonCategoryTextureBg:SetTexCoord(0, 0.25, 0, 0.25)
dungeonCategoryTextureBg:SetWidth(406)
dungeonCategoryTextureBg:SetHeight(506)
dungeonCategoryTextureBg:SetPoint("TOPLEFT", dungeonCategory, "TOPLEFT", 8, -5)

dungeonCategory:SetScript("OnEnter", function()
	hoveredCategory = true
	dungeonCategoryText:SetText("|cFFE0E0E0Dungeons")
	dungeonCategoryTextureBg:SetTexCoord(0.5, 0.75, 0, 0.25)
end)

dungeonCategory:SetScript("OnLeave", function()
	hoveredCategory = false
	dungeonCategoryTextureBg:SetTexCoord(0, 0.25, 0, 0.25)
	dungeonCategoryText:SetText(headerColor .. "Dungeons")
end)

local raidCategory = CreateFrame("Frame", "NoxxLFGCategoryRaidsFrame", categoryFrame, "BackdropTemplate")
raidCategory:SetSize(325, 125)
raidCategory:SetPoint("TOPLEFT", dungeonCategory, "TOPRIGHT", -10, 0)
raidCategory:SetScale(0.80)

local raidCategoryText = raidCategory:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge2")
raidCategoryText:SetPoint("CENTER", raidCategory, "CENTER")
raidCategoryText:SetScale(1.75)
raidCategoryText:SetText(headerColor .. "Raids")

local raidCategoryTexture = raidCategory:CreateTexture(nil, "ARTWORK")
raidCategoryTexture:SetAllPoints(raidCategoryTexture:GetParent())
raidCategoryTexture:SetTexture("interface/adventuremap/adventuremap")
raidCategoryTexture:SetTexCoord(0.345703125, 0.78125, 0.0009765625, 0.3017578125)

local raidCategoryTextureBg = raidCategory:CreateTexture(nil, "BACKGROUND")
raidCategoryTextureBg:SetTexture("Interface\\AddOns\\NoxxLFG\\images\\categories")
raidCategoryTextureBg:SetTexCoord(0.75, 1, 0, 0.25)
raidCategoryTextureBg:SetWidth(406)
raidCategoryTextureBg:SetHeight(506)
raidCategoryTextureBg:SetPoint("TOPLEFT", raidCategory, "TOPLEFT", 8, -5)

raidCategory:SetScript("OnEnter", function()
	hoveredCategory = true
	raidCategoryText:SetText("|cFFE0E0E0Raids")
	raidCategoryTextureBg:SetTexCoord(0.25, 0.5, 0.25, 0.5)
end)

raidCategory:SetScript("OnLeave", function()
	hoveredCategory = false
	raidCategoryTextureBg:SetTexCoord(0.75, 1, 0, 0.25)
	raidCategoryText:SetText(headerColor .. "Raids")
end)

local travelCategory = CreateFrame("Frame", "NoxxLFGCategoryDungeonFrame", categoryFrame, "BackdropTemplate")
travelCategory:SetSize(325, 125)
travelCategory:SetPoint("TOPLEFT", raidCategory, "TOPRIGHT", -10, 0)
travelCategory:SetScale(0.80)

local travelCategoryText = travelCategory:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge2")
travelCategoryText:SetPoint("CENTER", travelCategory, "CENTER")
travelCategoryText:SetScale(1.75)
travelCategoryText:SetText(headerColor .. "Travel")

local travelCategoryTexture = travelCategory:CreateTexture(nil, "ARTWORK")
travelCategoryTexture:SetAllPoints(travelCategoryTexture:GetParent())
travelCategoryTexture:SetTexture("interface/adventuremap/adventuremap")
travelCategoryTexture:SetTexCoord(0.345703125, 0.78125, 0.0009765625, 0.3017578125)

local travelCategoryTextureBg = travelCategory:CreateTexture(nil, "BACKGROUND")
travelCategoryTextureBg:SetTexture("Interface\\AddOns\\NoxxLFG\\images\\categories")
travelCategoryTextureBg:SetTexCoord(0.5, 0.75, 0.25, 0.5)
travelCategoryTextureBg:SetWidth(406)
travelCategoryTextureBg:SetHeight(506)
travelCategoryTextureBg:SetPoint("TOPLEFT", travelCategory, "TOPLEFT", 8, -5)

travelCategory:SetScript("OnEnter", function()
	hoveredCategory = true
	travelCategoryText:SetText("|cFFE0E0E0Travel")
	travelCategoryTextureBg:SetTexCoord(0, 0.25, 0.5, 0.75)
end)

travelCategory:SetScript("OnLeave", function()
	hoveredCategory = false
	travelCategoryTextureBg:SetTexCoord(0.5, 0.75, 0.25, 0.5)
	travelCategoryText:SetText(headerColor .. "Travel")
end)

local servicesCategory = CreateFrame("Frame", "NoxxLFGCategoryServicesFrame", categoryFrame, "BackdropTemplate")
servicesCategory:SetSize(325, 125)
servicesCategory:SetPoint("BOTTOM", dungeonCategory, "BOTTOM", 0, -125)
servicesCategory:SetScale(0.80)

local servicesCategoryText = servicesCategory:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge2")
servicesCategoryText:SetPoint("CENTER", servicesCategory, "CENTER")
servicesCategoryText:SetScale(1.75)
servicesCategoryText:SetText(headerColor .. "Services")

local servicesCategoryTexture = servicesCategory:CreateTexture(nil, "ARTWORK")
servicesCategoryTexture:SetAllPoints(servicesCategoryTexture:GetParent())
servicesCategoryTexture:SetTexture("interface/adventuremap/adventuremap")
servicesCategoryTexture:SetTexCoord(0.345703125, 0.78125, 0.0009765625, 0.3017578125)

local servicesCategoryTextureBg = servicesCategory:CreateTexture(nil, "BACKGROUND")
servicesCategoryTextureBg:SetTexture("Interface\\AddOns\\NoxxLFG\\images\\categories")
servicesCategoryTextureBg:SetTexCoord(0.25, 0.5, 0.5, 0.75)
servicesCategoryTextureBg:SetWidth(406)
servicesCategoryTextureBg:SetHeight(506)
servicesCategoryTextureBg:SetPoint("TOPLEFT", servicesCategory, "TOPLEFT", 8, -5)

servicesCategory:SetScript("OnEnter", function()
	hoveredCategory = true
	servicesCategoryText:SetText("|cFFE0E0E0Services")
	servicesCategoryTextureBg:SetTexCoord(0.75, 1.0, 0.5, 0.75)
end)

servicesCategory:SetScript("OnLeave", function()
	hoveredCategory = false
	servicesCategoryTextureBg:SetTexCoord(0.25, 0.5, 0.5, 0.75)
	servicesCategoryText:SetText(headerColor .. "Services")
end)

local eventsCategory = CreateFrame("Frame", "NoxxLFGCategoryServicesFrame", categoryFrame, "BackdropTemplate")
eventsCategory:SetSize(325, 125)
eventsCategory:SetPoint("TOPLEFT", servicesCategory, "TOPRIGHT", -10, 0)
eventsCategory:SetScale(0.80)

local eventsCategoryText = eventsCategory:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge2")
eventsCategoryText:SetPoint("CENTER", eventsCategory, "CENTER")
eventsCategoryText:SetScale(1.75)
eventsCategoryText:SetText(headerColor .. "Events & PvP")

local eventsCategoryTexture = eventsCategory:CreateTexture(nil, "ARTWORK")
eventsCategoryTexture:SetAllPoints(eventsCategoryTexture:GetParent())
eventsCategoryTexture:SetTexture("interface/adventuremap/adventuremap")
eventsCategoryTexture:SetTexCoord(0.345703125, 0.78125, 0.0009765625, 0.3017578125)

local eventsCategoryTextureBg = eventsCategory:CreateTexture(nil, "BACKGROUND")
eventsCategoryTextureBg:SetTexture("Interface\\AddOns\\NoxxLFG\\images\\categories")
eventsCategoryTextureBg:SetTexCoord(0, 0.25, 0.75, 1)
eventsCategoryTextureBg:SetWidth(406)
eventsCategoryTextureBg:SetHeight(506)
eventsCategoryTextureBg:SetPoint("TOPLEFT", eventsCategory, "TOPLEFT", 8, -5)

eventsCategory:SetScript("OnEnter", function()
	hoveredCategory = true
	eventsCategoryText:SetText("|cFFE0E0E0Events & PvP")
	eventsCategoryTextureBg:SetTexCoord(0.5, 0.75, 0.75, 1.0)
end)

eventsCategory:SetScript("OnLeave", function()
	hoveredCategory = false
	eventsCategoryTextureBg:SetTexCoord(0, 0.25, 0.75, 1)
	eventsCategoryText:SetText(headerColor .. "Events & PvP")
end)

local categorySearchFrameDungeons =
	CreateFrame("ScrollFrame", "NoxxLFGCategorySearchFrameDungeons", mainFrame, "UIPanelScrollFrameTemplate")
categorySearchFrameDungeons:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 5, -60)
categorySearchFrameDungeons:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -40, 30)
categorySearchFrameDungeons:EnableMouseWheel(true)
categorySearchFrameDungeons:SetScript("OnMouseWheel", function(self, delta)
	local currentScroll = self:GetVerticalScroll()
	local newScroll = currentScroll - (delta * 20)

	newScroll = math.max(0, newScroll)
	newScroll = math.min(newScroll, self:GetVerticalScrollRange())

	self:SetVerticalScroll(newScroll)
end)
categorySearchFrameDungeons:Hide()

local categorySearchFrameRaids =
	CreateFrame("ScrollFrame", "NoxxLFGCategorySearchFrameRaids", mainFrame, "UIPanelScrollFrameTemplate")
categorySearchFrameRaids:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 5, -60)
categorySearchFrameRaids:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -40, 30)
categorySearchFrameRaids:EnableMouseWheel(true)
categorySearchFrameRaids:SetScript("OnMouseWheel", function(self, delta)
	local currentScroll = self:GetVerticalScroll()
	local newScroll = currentScroll - (delta * 20)

	newScroll = math.max(0, newScroll)
	newScroll = math.min(newScroll, self:GetVerticalScrollRange())

	self:SetVerticalScroll(newScroll)
end)
categorySearchFrameRaids:Hide()

local categorySearchFrameTravel =
	CreateFrame("ScrollFrame", "NoxxLFGCategorySearchFrameTravel", mainFrame, "UIPanelScrollFrameTemplate")
categorySearchFrameTravel:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 5, -60)
categorySearchFrameTravel:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -40, 30)
categorySearchFrameTravel:EnableMouseWheel(true)
categorySearchFrameTravel:SetScript("OnMouseWheel", function(self, delta)
	local currentScroll = self:GetVerticalScroll()
	local newScroll = currentScroll - (delta * 20)

	newScroll = math.max(0, newScroll)
	newScroll = math.min(newScroll, self:GetVerticalScrollRange())

	self:SetVerticalScroll(newScroll)
end)
categorySearchFrameTravel:Hide()

local categorySearchFrameServices =
	CreateFrame("ScrollFrame", "NoxxLFGCategorySearchFrameServices", mainFrame, "UIPanelScrollFrameTemplate")
categorySearchFrameServices:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 5, -60)
categorySearchFrameServices:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -40, 30)
categorySearchFrameServices:EnableMouseWheel(true)
categorySearchFrameServices:SetScript("OnMouseWheel", function(self, delta)
	local currentScroll = self:GetVerticalScroll()
	local newScroll = currentScroll - (delta * 20)

	newScroll = math.max(0, newScroll)
	newScroll = math.min(newScroll, self:GetVerticalScrollRange())

	self:SetVerticalScroll(newScroll)
end)
categorySearchFrameServices:Hide()

local categorySearchFrameEvents =
	CreateFrame("ScrollFrame", "NoxxLFGCategorySearchFrameEvents", mainFrame, "UIPanelScrollFrameTemplate")
categorySearchFrameEvents:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 5, -60)
categorySearchFrameEvents:SetPoint("BOTTOMRIGHT", mainFrame, "BOTTOMRIGHT", -40, 30)
categorySearchFrameEvents:EnableMouseWheel(true)
categorySearchFrameEvents:SetScript("OnMouseWheel", function(self, delta)
	local currentScroll = self:GetVerticalScroll()
	local newScroll = currentScroll - (delta * 20)

	newScroll = math.max(0, newScroll)
	newScroll = math.min(newScroll, self:GetVerticalScrollRange())

	self:SetVerticalScroll(newScroll)
end)
categorySearchFrameEvents:Hide()

local categorySearchFrameChildDungeons =
	CreateFrame("Frame", "NoxxLFGCategorySearchFrameChildDungeons", categorySearchFrameDungeons)
categorySearchFrameChildDungeons:SetPoint("TOP", categorySearchFrameDungeons, "TOP")
categorySearchFrameChildDungeons:SetSize(categorySearchFrameDungeons:GetWidth(), 0)
categorySearchFrameDungeons:SetScrollChild(categorySearchFrameChildDungeons)
categorySearchFrameChildDungeons:Hide()

local categorySearchFrameChildRaids =
	CreateFrame("Frame", "NoxxLFGCategorySearchFrameChildRaids", categorySearchFrameRaids)
categorySearchFrameChildRaids:SetPoint("TOP", categorySearchFrameRaids, "TOP")
categorySearchFrameChildRaids:SetSize(categorySearchFrameRaids:GetWidth(), 0)
categorySearchFrameRaids:SetScrollChild(categorySearchFrameChildRaids)
categorySearchFrameChildRaids:Hide()

local categorySearchFrameChildTravel =
	CreateFrame("Frame", "NoxxLFGCategorySearchFrameChildTravel", categorySearchFrameTravel)
categorySearchFrameChildTravel:SetPoint("TOP", categorySearchFrameTravel, "TOP")
categorySearchFrameChildTravel:SetSize(categorySearchFrameTravel:GetWidth(), 0)
categorySearchFrameTravel:SetScrollChild(categorySearchFrameChildTravel)
categorySearchFrameChildTravel:Hide()

local categorySearchFrameChildServices =
	CreateFrame("Frame", "NoxxLFGCategorySearchFrameChildServices", categorySearchFrameServices)
categorySearchFrameChildServices:SetPoint("TOP", categorySearchFrameServices, "TOP")
categorySearchFrameChildServices:SetSize(categorySearchFrameServices:GetWidth(), 0)
categorySearchFrameServices:SetScrollChild(categorySearchFrameChildServices)
categorySearchFrameChildServices:Hide()

local categorySearchFrameChildEvents =
	CreateFrame("Frame", "NoxxLFGCategorySearchFrameChildEvents", categorySearchFrameEvents)
categorySearchFrameChildEvents:SetPoint("TOP", categorySearchFrameEvents, "TOP")
categorySearchFrameChildEvents:SetSize(categorySearchFrameEvents:GetWidth(), 0)
categorySearchFrameEvents:SetScrollChild(categorySearchFrameChildEvents)
categorySearchFrameChildEvents:Hide()

local categorySearchBackButton =
	CreateFrame("Button", "NoxxLFGCategorySearchFrameBackButton", mainFrame, "UIPanelButtonTemplate")
categorySearchBackButton:SetSize(140, 25)
categorySearchBackButton:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", 10, -30)
categorySearchBackButton:SetText("Back to Categories")
categorySearchBackButton:Hide()

local pausePlayButton = CreateFrame("Frame", "NoxxLFGPlayPauseButton", mainFrame)
pausePlayButton:SetPoint("LEFT", categorySearchBackButton, "RIGHT", 3, 0)
pausePlayButton:SetSize(26, 26)
pausePlayButton:Hide()

local pausePlayButtonTexture = pausePlayButton:CreateTexture(nil, "OVERLAY")
pausePlayButtonTexture:SetAllPoints(pausePlayButton)
pausePlayButtonTexture:SetTexture("Interface\\AddOns\\NoxxLFG\\images\\pauseresumeatlas")

local function CheckIfPaused()
	if not NoxxLFGSettings.pausedSearching or NoxxLFGSettings.pausedSearching == nil then
		pausePlayButtonTexture:SetTexCoord(0.25, 0.5, 0, 0.25)
	else
		pausePlayButtonTexture:SetTexCoord(0, 0.25, 0.25, 0.5)
	end
end

local previewTextFontString = lfmCreationFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
previewTextFontString:SetWidth(mainFrame:GetWidth() - 80)
previewTextFontString:SetWordWrap(true)
previewTextFontString:SetPoint("TOP", lfmCreationFrame, "TOP", 0, -410)

local previewLFGTextFontString = lfgCreationFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
previewLFGTextFontString:SetWidth(mainFrame:GetWidth() - 80)
previewLFGTextFontString:SetWordWrap(true)
previewLFGTextFontString:SetPoint("TOP", lfgCreationFrame, "TOP", 0, -260)

local neededFrame = CreateFrame("Frame", "NoxxLFGLFMNeededFrame", UIParent, "BackdropTemplate")
neededFrame:SetSize(170, 30)
neededFrame:SetPoint("LEFT", ChatFrameChannelButton, "LEFT", 30, 32)
neededFrame:SetBackdrop({
	bgFile = "interface/garrison/classhallinternalbackground",
	edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
	tile = true,
	tileSize = 32,
	edgeSize = 16,
	insets = { left = 4, right = 4, top = 4, bottom = 4 },
})
neededFrame:Hide()

local neededFrameText = neededFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
neededFrameText:SetText("Need:")
neededFrameText:SetPoint("LEFT", neededFrame, "LEFT", 17, 0)

local neededFrameDPS = CreateFrame("Frame", nil, neededFrame)
neededFrameDPS:SetSize(18, 18)
neededFrameDPS:SetPoint("LEFT", neededFrameText, "RIGHT", 5, 0)

local neededFrameDPSTexture = neededFrameDPS:CreateTexture(nil, "ARTWORK")
neededFrameDPSTexture:SetTexture("interface/lfgframe/uilfgpromptsdf")
neededFrameDPSTexture:SetTexCoord(0.00048828125, 0.0302734375, 0.88134765625, 0.9111328125)
neededFrameDPSTexture:SetAllPoints(neededFrameDPS)

local neededFrameDPSText = neededFrameDPS:CreateFontString(nil, "OVERLAY", "GameFontNormal")
neededFrameDPSText:SetPoint("LEFT", neededFrameDPSTexture, "RIGHT", 1, 0)
neededFrameDPSText:SetText("0")
neededFrameDPSText:SetTextColor(245 / 255, 120 / 255, 120 / 255, 1)

local neededFrameTank = CreateFrame("Frame", nil, neededFrame)
neededFrameTank:SetSize(18, 18)
neededFrameTank:SetPoint("LEFT", neededFrameDPS, "RIGHT", 15, 0)

local neededFrameTankTexture = neededFrameTank:CreateTexture(nil, "ARTWORK")
neededFrameTankTexture:SetTexture("interface/lfgframe/uilfgpromptsdf")
neededFrameTankTexture:SetTexCoord(0.00048828125, 0.0302734375, 0.912109375, 0.94189453125)
neededFrameTankTexture:SetAllPoints(neededFrameTank)

local neededFrameTankText = neededFrameTank:CreateFontString(nil, "OVERLAY", "GameFontNormal")
neededFrameTankText:SetPoint("LEFT", neededFrameTankTexture, "RIGHT", 1, 0)
neededFrameTankText:SetText("0")
neededFrameTankText:SetTextColor(120 / 255, 120 / 255, 245 / 255, 1)

local neededFrameHealer = CreateFrame("Frame", nil, neededFrame)
neededFrameHealer:SetSize(18, 18)
neededFrameHealer:SetPoint("LEFT", neededFrameTank, "RIGHT", 15, 0)

local neededFrameHealerTexture = neededFrameHealer:CreateTexture(nil, "ARTWORK")
neededFrameHealerTexture:SetTexture("interface/lfgframe/uilfgpromptsdf")
neededFrameHealerTexture:SetTexCoord(0.00048828125, 0.0302734375, 0.94287109375, 0.97265625)
neededFrameHealerTexture:SetAllPoints(neededFrameHealer)

local neededFrameHealerText = neededFrameHealer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
neededFrameHealerText:SetPoint("LEFT", neededFrameHealerTexture, "RIGHT", 1, 0)
neededFrameHealerText:SetText("0")
neededFrameHealerText:SetTextColor(120 / 255, 245 / 255, 120 / 255, 1)

neededFrame:SetScript("OnMouseUp", function()
	PlaySound(808)
	mainFrame:Show()
end)

local visiblePopupsCount = 0
local yOffset = -100 - (visiblePopupsCount * 110)

local postButtonFrame = CreateFrame("Frame", "NoxxLFGLFMReminderPostButtonFrame", UIParent, "BackdropTemplate")
postButtonFrame:SetSize(550, 150)
postButtonFrame:SetPoint("TOP", UIParent, "TOP", 0, yOffset + 50)
postButtonFrame:SetFrameStrata("DIALOG")
postButtonFrame:SetBackdrop({
	bgFile = "interface/garrison/classhallinternalbackground",
	edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
	tile = true,
	tileSize = 32,
	edgeSize = 32,
	insets = { left = 8, right = 8, top = 8, bottom = 8 },
})
postButtonFrame:Hide()

local function CreateLFGCheckbox(parent, labelText, xOffset, yOffset)
	local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
	checkbox:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, yOffset)
	checkbox:SetSize(24, 24)

	local label = checkbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetPoint("LEFT", checkbox, "RIGHT", 5, 0)
	label:SetText(labelText)

	return checkbox
end

local bringConsumesCheckbox = CreateLFGCheckbox(lfmCreationFrame, "Bring Consumes & World Buffs", 180, -120)
local mustKnowFightsCheckbox = CreateLFGCheckbox(lfmCreationFrame, "Must Know Fights", 405, -120)
local spamRunCheckbox = CreateLFGCheckbox(lfmCreationFrame, "Spam Run", 555, -120)

local function ResetLFMMessage()
	postingMessage = false
	startedWithRoles = false
	totalRoles = 0
	lfmPostButtonAuto:SetText("Repeat Post")
end

local function ResetLFGMessage()
	postingLFGMessage = false
	lfgPostButtonAuto:SetText("Repeat Post")
end

local function UpdateLFMMessage(
	dungeonRaidText,
	tankText,
	dpsText,
	healerText,
	tankPreferred,
	dpsPreferred,
	healerPreferred,
	extraInfo
)
	if previewTextFontString then
		local function safeText(text)
			return (not text or text == "") and "0" or text
		end

		local function pluralizeRole(count, singular, plural, preferred)
			local roleText = tonumber(count) == 1 and (count .. " " .. singular) or (count .. " " .. plural)
			if preferred and preferred ~= "" then
				roleText = roleText .. " (" .. preferred .. ")"
			end
			return roleText
		end

		dungeonRaidText = dungeonRaidText or ""
		tankText = safeText(tankText)
		dpsText = safeText(dpsText)
		healerText = safeText(healerText)

		local roles = {}

		if tonumber(tankText) > 0 then
			local tankRoleText = pluralizeRole(tankText, "Tank", "Tanks", tankPreferred)
			table.insert(roles, tankRoleText)
		end
		if tonumber(dpsText) > 0 then
			local dpsRoleText = dpsText .. " DPS"
			if dpsPreferred and dpsPreferred ~= "" then
				dpsRoleText = dpsRoleText .. " (" .. dpsPreferred .. ")"
			end
			table.insert(roles, dpsRoleText)
		end
		if tonumber(healerText) > 0 then
			local healerRoleText = pluralizeRole(healerText, "Healer", "Healers", healerPreferred)
			table.insert(roles, healerRoleText)
		end

		if #roles > 0 and startedWithRoles then
			totalRoles = #roles
		end

		local rolesText = table.concat(roles, ", ")
		local message = ""

		if dungeonRaidText ~= "" then
			message = "LFM " .. dungeonRaidText
			if #roles > 0 then
				message = message .. " - Need " .. rolesText
			end
		end

		local options = {}
		if bringConsumesCheckbox:GetChecked() then
			table.insert(options, "Bring Consumes/WBs")
		end

		if mustKnowFightsCheckbox:GetChecked() then
			table.insert(options, "Know Fights")
		end

		if spamRunCheckbox:GetChecked() then
			table.insert(options, "SPAM RUN")
		end

		if extraInfo and extraInfo ~= "" then
			table.insert(options, extraInfo)
		end

		if #options > 0 and dungeonRaidText ~= "" then
			message = message .. " - " .. table.concat(options, ", ")
		end

		local channelName = NoxxLFGSettings.lfmChannel or "LookingForGroup"
		local channelId, channelString = GetChannelName(channelName)
		local _, class = UnitClass("player")

		if #message < 125 then
			if channelId > 0 and channelString then
				previewTextFontString:SetText(
					"|cFFFEC1C0["
						.. channelId
						.. ". "
						.. channelString
						.. "] [|c"
						.. classColor[class]
						.. UnitName("player")
						.. "|r]: "
						.. message
				)
			else
				previewTextFontString:SetText(
					"|cFFFF0000Message will not post! (Bad channel name - please set a valid channel in the settings)"
				)
			end
		else
			previewTextFontString:SetText("|cFFFF0000Message too long!")
		end

		if message ~= "" then
			lfmCreationMessage = message
			if not postingLFGMessage then
				lfmPostButtonAuto:Enable()
				lfmPostButton:Enable()
			end
		else
			lfmPostButtonAuto:Disable()
			lfmPostButton:Disable()
			ResetLFMMessage()
			CancelTimer()
		end

		if postingMessage and #roles == 0 and totalRoles > 0 then
			print(
				NoxxLFGBlueColor
					.. addonName
					.. ": |cFFFFFF00Posting canceled. |r|rYou will no longer receive reminders to post your message."
			)
			ResetLFMMessage()
			CancelTimer()
			postButtonFrame:Hide()
			neededFrame:Hide()
		end
	end
end

local function UpdateLFGMessage(dungeonRaidQuestText, playerRole, extraInfo)
	if previewLFGTextFontString then
		dungeonRaidQuestText = dungeonRaidQuestText or ""
		playerRole = playerRole or ""

		local message = ""

		if dungeonRaidQuestText and dungeonRaidQuestText ~= "" then
			message = "LFG " .. dungeonRaidQuestText
		end

		if playerRole ~= "" then
			message = playerRole .. " " .. message
		end

		if dungeonRaidQuestText ~= "" and extraInfo and extraInfo ~= "" then
			message = message .. " - " .. extraInfo
		end

		local channelName = NoxxLFGSettings.lfgChannel or "LookingForGroup"
		local channelId, channelString = GetChannelName(channelName)
		local _, class = UnitClass("player")

		if #message < 125 then
			if channelId > 0 and channelString then
				previewLFGTextFontString:SetText(
					"|cFFFEC1C0["
						.. channelId
						.. ". "
						.. channelString
						.. "] [|c"
						.. classColor[class]
						.. UnitName("player")
						.. "|r]: "
						.. message
				)
			else
				previewLFGTextFontString:SetText(
					"|cFFFF0000Message will not post! (Bad channel name - please set a valid channel in the settings)"
				)
			end
		else
			previewLFGTextFontString:SetText("|cFFFF0000Message too long!")
		end

		if message ~= "" then
			lfgCreationMessage = message
			if not postingMessage then
				lfgPostButtonAuto:Enable()
				lfgPostButton:Enable()
			end
		else
			lfgPostButtonAuto:Disable()
			lfgPostButton:Disable()
			ResetLFGMessage()
			CancelLFGTimer()
		end

		if postingLFGMessage then
			print(
				NoxxLFGBlueColor
					.. addonName
					.. ": |cFFFFFF00Posting canceled. |r|rYou will no longer receive reminders to post your message."
			)
			ResetLFGMessage()
			CancelLFGTimer()
			postButtonFrame:Hide()
		end
	end
end

local function CreateTextBox(parent, labelText, defaultText, width, height, xOffset, yOffset, isNumeric)
	local textBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
	textBox:SetSize(width, height)
	textBox:SetPoint("TOPLEFT", parent, "TOPLEFT", xOffset, yOffset)
	textBox:SetAutoFocus(false)

	local label = textBox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	label:SetPoint("BOTTOMLEFT", textBox, "TOPLEFT", -3, 5)
	label:SetText(labelText)

	textBox:SetText(defaultText)

	if isNumeric then
		textBox:SetNumeric(true)
		textBox:SetMaxLetters(3)
		textBox:SetScript("OnTextChanged", function(self)
			local text = self:GetText()
			local newText = string.gsub(text, "%D", "")
			if newText ~= text then
				self:SetText(newText)
			end
		end)
	end

	return textBox
end

-- LFM Frame Text Boxes

local tankTextBox = CreateTextBox(lfmCreationFrame, "# |cFF34b1ebTanks|r Needed:", "", 50, 20, 20, -170, true)
local dpsTextBox = CreateTextBox(lfmCreationFrame, "# |cFFed5351DPS|r Needed:", "", 50, 20, 160, -170, true)
local healerTextBox = CreateTextBox(lfmCreationFrame, "# |cFF95e879Healers|r Needed:", "", 50, 20, 300, -170, true)
local dungeonRaidTextBox = CreateTextBox(
	lfmCreationFrame,
	"Dungeon/Raid Name: " .. headerColor .. "(required)|r",
	"",
	150,
	20,
	20,
	-120,
	false
)

local tankPreferredTextBox =
	CreateTextBox(lfmCreationFrame, "Preference for |cFF34b1ebTank|r role?", "", 150, 20, 20, -220, false)
local dpsPreferredTextBox =
	CreateTextBox(lfmCreationFrame, "Preference for |cFFed5351DPS|r role?", "", 150, 20, 20, -270, false)
local healerPreferredTextBox =
	CreateTextBox(lfmCreationFrame, "Preference for |cFF95e879Healer|r role?", "", 150, 20, 20, -320, false)
local extraInfoTextBox =
	CreateTextBox(lfmCreationFrame, "|cFFEDEDEDExtra Details (6/6 Group, etc.)", "", 150, 20, 20, -370, false)

tankTextBox:SetScript("OnTabPressed", function()
	dpsTextBox:SetFocus()
end)

dpsTextBox:SetScript("OnTabPressed", function()
	healerTextBox:SetFocus()
end)

healerTextBox:SetScript("OnTabPressed", function()
	tankPreferredTextBox:SetFocus()
end)

dungeonRaidTextBox:SetScript("OnTabPressed", function()
	tankTextBox:SetFocus()
end)

tankPreferredTextBox:SetScript("OnTabPressed", function()
	dpsPreferredTextBox:SetFocus()
end)

dpsPreferredTextBox:SetScript("OnTabPressed", function()
	healerPreferredTextBox:SetFocus()
end)

healerPreferredTextBox:SetScript("OnTabPressed", function()
	extraInfoTextBox:SetFocus()
end)

extraInfoTextBox:SetScript("OnTabPressed", function()
	dungeonRaidTextBox:SetFocus()
end)

-- LFG Frame Text Boxes

local dungeonRaidQuestTextBox = CreateTextBox(
	lfgCreationFrame,
	"Dungeon/Raid/Event Name: " .. headerColor .. "(required)|r",
	"",
	150,
	20,
	20,
	-120,
	false
)

local playerRoleTextBox = CreateTextBox(lfgCreationFrame, "Your Role/Class?", "", 100, 20, 20, -170, false)

local extraInfoLFGTextBox =
	CreateTextBox(lfgCreationFrame, "|cFFEDEDEDExtra Details (Have Items, Spam, etc.)", "", 150, 20, 20, -220, false)

dungeonRaidQuestTextBox:SetScript("OnTabPressed", function()
	playerRoleTextBox:SetFocus()
end)

playerRoleTextBox:SetScript("OnTabPressed", function()
	extraInfoLFGTextBox:SetFocus()
end)

extraInfoLFGTextBox:SetScript("OnTabPressed", function()
	dungeonRaidQuestTextBox:SetFocus()
end)

local function ClearTextBoxFocus()
	tankTextBox:ClearFocus()
	dpsTextBox:ClearFocus()
	healerTextBox:ClearFocus()
	dungeonRaidTextBox:ClearFocus()
	dungeonRaidQuestTextBox:ClearFocus()
	tankPreferredTextBox:ClearFocus()
	dpsPreferredTextBox:ClearFocus()
	healerPreferredTextBox:ClearFocus()
	extraInfoTextBox:ClearFocus()
	extraInfoLFGTextBox:ClearFocus()
end

lfmPostButtonReset:SetScript("OnClick", function()
	if not postingMessage then
		PlaySound(808)
		tankTextBox:SetText("")
		dpsTextBox:SetText("")
		healerTextBox:SetText("")
		dungeonRaidTextBox:SetText("")
		tankPreferredTextBox:SetText("")
		dpsPreferredTextBox:SetText("")
		healerPreferredTextBox:SetText("")
		extraInfoTextBox:SetText("")
		bringConsumesCheckbox:SetChecked(false)
		mustKnowFightsCheckbox:SetChecked(false)
		spamRunCheckbox:SetChecked(false)
		UpdateLFMMessage(
			dungeonRaidTextBox:GetText(),
			tankTextBox:GetText(),
			dpsTextBox:GetText(),
			healerTextBox:GetText(),
			tankPreferredTextBox:GetText(),
			dpsPreferredTextBox:GetText(),
			healerPreferredTextBox:GetText(),
			extraInfoTextBox:GetText()
		)
		ClearTextBoxFocus()
	end
end)

lfgPostButtonReset:SetScript("OnClick", function()
	if not postingLFGMessage then
		PlaySound(808)
		dungeonRaidQuestTextBox:SetText("")
		playerRoleTextBox:SetText("")
		extraInfoLFGTextBox:SetText("")
		UpdateLFGMessage(dungeonRaidQuestTextBox:GetText(), playerRoleTextBox:GetText(), extraInfoLFGTextBox:GetText())
		ClearTextBoxFocus()
	end
end)

local postButtonFrameTitle = postButtonFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
postButtonFrameTitle:SetPoint("TOP", postButtonFrame, "TOP", 0, -15)
postButtonFrameTitle:SetText("Would you like to post your message again?")

local postButtonFrameMessage = postButtonFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
postButtonFrameMessage:SetPoint("TOP", postButtonFrame, "TOP", 0, -35)
postButtonFrameMessage:SetWidth(postButtonFrame:GetWidth() - 50)
postButtonFrameMessage:SetWordWrap(true)

local function PostButton()
	PlaySound(3081)
	if postingMessage then
		postButtonFrameMessage:SetText("|cFFFEC1C0" .. lfmCreationMessage)
		visiblePopupsCount = visiblePopupsCount + 1
		postButtonFrame:Show()
		messageTimer:Cancel()
	elseif postingLFGMessage then
		postButtonFrameMessage:SetText("|cFFFEC1C0" .. lfgCreationMessage)
		visiblePopupsCount = visiblePopupsCount + 1
		postButtonFrame:Show()
		LFGMessageTimer:Cancel()
	end
end

local postButton = CreateFrame("Button", "NoxxLFGLFMReminderPostButton", postButtonFrame, "UIPanelButtonTemplate")
postButton:SetText("Post Message")
postButton:SetSize(125, 30)
postButton:SetPoint("BOTTOMLEFT", postButtonFrame, "BOTTOMLEFT", 100, 15)
postButton:SetScript("OnClick", function()
	PlaySound(808)
	if postingMessage then
		messageTimer = C_Timer.NewTicker(postingMessageTimer, PostButton)
		SendMessage()
	elseif postingLFGMessage then
		LFGMessageTimer = C_Timer.NewTicker(postingMessageTimer, PostButton)
		SendLFGMessage()
	end
	postButtonFrame:Hide()
	visiblePopupsCount = visiblePopupsCount - 1
end)

local cancelButton = CreateFrame("Button", "NoxxLFGLFMReminderPostButton", postButtonFrame, "UIPanelButtonTemplate")
cancelButton:SetText("|cFFFF6666Stop Posting")
cancelButton:SetSize(125, 30)
cancelButton:SetPoint("BOTTOMRIGHT", postButtonFrame, "BOTTOMRIGHT", -100, 15)
cancelButton:SetScript("OnClick", function()
	PlaySound(808)
	print(NoxxLFGBlueColor .. addonName .. ": |rYou will no longer receive reminders to post your message.")
	CancelTimer()
	ResetLFMMessage()
	CancelLFGTimer()
	ResetLFGMessage()
	postButtonFrame:Hide()
	neededFrame:Hide()
	visiblePopupsCount = visiblePopupsCount - 1
end)

lfmCreationFrame:SetScript("OnMouseDown", ClearTextBoxFocus)
lfgCreationFrame:SetScript("OnMouseDown", ClearTextBoxFocus)

lfmPostButtonAuto:SetScript("OnClick", function()
	PlaySound(808)
	if lfmCreationMessage and lfmCreationMessage ~= "" then
		ClearTextBoxFocus()
		if not postingMessage or postingLFGMessage then
			SendMessage()
			lfmPostButtonAuto:SetText("Cancel")
			postingMessage = true
			messageTimer = C_Timer.NewTicker(postingMessageTimer, PostButton)
			mainFrame:Hide()
			if startedWithRoles then
				neededFrame:Show()
				local dpsAmt, tankAmt, healerAmt =
					tonumber(dpsTextBox:GetText()) or 0,
					tonumber(tankTextBox:GetText()) or 0,
					tonumber(healerTextBox:GetText()) or 0
				neededFrameDPSText:SetText(tostring(dpsAmt))
				neededFrameTankText:SetText(tostring(tankAmt))
				neededFrameHealerText:SetText(tostring(healerAmt))
			end
		else
			postingMessage = false
			postingLFGMessage = false
			startedWithRoles = false
			totalRoles = 0
			lfmPostButtonAuto:SetText("Repeat Post")
			print(
				NoxxLFGBlueColor
					.. addonName
					.. ": |cFFFFFF00Posting canceled. |r|rYou will no longer receive reminders to post your message."
			)
			postButtonFrame:Hide()
			neededFrame:Hide()
			CancelTimer()
			CancelLFGTimer()
		end
	else
		if postingMessage and totalRoles == 0 and startedWithRoles then
			ResetLFMMessage()
		end
	end
end)

lfgPostButtonAuto:SetScript("OnClick", function()
	PlaySound(808)
	if lfgCreationMessage and lfgCreationMessage ~= "" then
		ClearTextBoxFocus()
		if not postingLFGMessage or postingMessage then
			SendLFGMessage()
			lfgPostButtonAuto:SetText("Cancel")
			postingLFGMessage = true
			LFGMessageTimer = C_Timer.NewTicker(postingMessageTimer, PostButton)
			mainFrame:Hide()
		else
			postingLFGMessage = false
			lfgPostButtonAuto:SetText("Repeat Post")
			print(
				NoxxLFGBlueColor
					.. addonName
					.. ": |cFFFFFF00Posting canceled. |r|rYou will no longer receive reminders to post your message."
			)
			postButtonFrame:Hide()
			CancelLFGTimer()
			CancelTimer()
		end
	else
		if postingLFGMessage then
			ResetLFGMessage()
		end
	end
end)

local function CheckForRolesBeforeStarting()
	local tankCount = tonumber(tankTextBox:GetText()) or 0
	local healerCount = tonumber(healerTextBox:GetText()) or 0
	local dpsCount = tonumber(dpsTextBox:GetText()) or 0

	startedWithRoles = (tankCount > 0 or healerCount > 0 or dpsCount > 0)
end

local function setupUpdateMessageHandler(uiElements)
	local function updateHandler()
		CheckForRolesBeforeStarting()
		UpdateLFMMessage(
			dungeonRaidTextBox:GetText(),
			tankTextBox:GetText(),
			dpsTextBox:GetText(),
			healerTextBox:GetText(),
			tankPreferredTextBox:GetText(),
			dpsPreferredTextBox:GetText(),
			healerPreferredTextBox:GetText(),
			extraInfoTextBox:GetText()
		)
		UpdateLFGMessage(dungeonRaidQuestTextBox:GetText(), playerRoleTextBox:GetText(), extraInfoLFGTextBox:GetText())
	end

	for _, uiElement in pairs(uiElements) do
		if uiElement:IsObjectType("EditBox") then
			uiElement:SetScript("OnTextChanged", updateHandler)
		elseif uiElement:IsObjectType("CheckButton") then
			uiElement:SetScript("OnClick", updateHandler)
		end
	end
end

local uiElementsToUpdate = {
	tankTextBox,
	dpsTextBox,
	healerTextBox,
	dungeonRaidTextBox,
	dungeonRaidQuestTextBox,
	playerRoleTextBox,
	tankPreferredTextBox,
	dpsPreferredTextBox,
	healerPreferredTextBox,
	extraInfoTextBox,
	extraInfoLFGTextBox,
	bringConsumesCheckbox,
	mustKnowFightsCheckbox,
	spamRunCheckbox,
}

setupUpdateMessageHandler(uiElementsToUpdate)

function NoxxLFG:ShowRoleSelectionPopup(playerName, tankCount, healerCount, dpsCount)
	visiblePopupsCount = visiblePopupsCount + 1

	local frame = CreateFrame("Frame", "CustomRoleSelectionFrame" .. visiblePopupsCount, UIParent, "BackdropTemplate")
	frame:SetSize(400, 100)
	frame:SetPoint("CENTER")
	frame:SetFrameStrata("DIALOG")
	frame:SetPoint("TOP", UIParent, "TOP", 0, yOffset - 100)
	frame:SetBackdrop({
		bgFile = "interface/garrison/classhallinternalbackground",
		edgeFile = "Interface/DialogFrame/UI-DialogBox-Border",
		tile = true,
		tileSize = 32,
		edgeSize = 32,
		insets = { left = 8, right = 8, top = 8, bottom = 8 },
	})
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:RegisterForDrag("LeftButton")
	frame:SetScript("OnDragStart", frame.StartMoving)
	frame:SetScript("OnDragStop", frame.StopMovingOrSizing)

	local title = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
	title:SetPoint("CENTER", frame, "TOP", 0, -20)
	title:SetText("Please select the role for: |cFFFFFF00" .. playerName)

	local function CreateButton(point, xOffset, role)
		local btn = CreateFrame("Button", nil, frame, "GameMenuButtonTemplate")
		btn:SetPoint("CENTER", frame, point, xOffset, 0)
		btn:SetSize(80, 22)
		btn:SetText(role)
		btn:SetNormalFontObject("GameFontNormal")
		btn:SetHighlightFontObject("GameFontHighlight")
		return btn
	end

	local tankBtn = CreateButton("LEFT", 100, "Tank")
	if not tankCount or tankCount == 0 then
		tankBtn:Disable()
	end

	local healerBtn = CreateButton("CENTER", 0, "Healer")
	if not healerCount or healerCount == 0 then
		healerBtn:Disable()
	end

	local dpsBtn = CreateButton("RIGHT", -100, "DPS")
	if not dpsCount or dpsCount == 0 then
		dpsBtn:Disable()
	end

	tankBtn:SetScript("OnClick", function(self)
		local tankNum = tonumber(tankTextBox:GetText())

		if tankNum > 0 then
			tankNum = tankNum - 1
			tankTextBox:SetText(tankNum)
			if tankNum == 0 then
				tankTextBox:SetText("")
			end
			frame:Hide()
			visiblePopupsCount = visiblePopupsCount - 1
		else
			print(
				NoxxLFGBlueColor
					.. addonName
					.. ":|r Your group appears to have the required amount of tanks. Please choose a different option."
			)
			self:Disable()
		end
		UpdateLFMMessage(
			dungeonRaidTextBox:GetText(),
			tankTextBox:GetText(),
			dpsTextBox:GetText(),
			healerTextBox:GetText(),
			tankPreferredTextBox:GetText(),
			dpsPreferredTextBox:GetText(),
			healerPreferredTextBox:GetText(),
			extraInfoTextBox:GetText()
		)
		if postButtonFrame then
			postButtonFrameMessage:SetText("|cFFFEC1C0" .. lfmCreationMessage)
		end
		local tankAmt = tonumber(tankTextBox:GetText()) or 0
		neededFrameTankText:SetText(tostring(tankAmt))
	end)

	healerBtn:SetScript("OnClick", function(self)
		local healerNum = tonumber(healerTextBox:GetText())

		if healerNum > 0 then
			healerNum = healerNum - 1
			healerTextBox:SetText(healerNum)
			if healerNum == 0 then
				healerTextBox:SetText("")
			end
			frame:Hide()
			visiblePopupsCount = visiblePopupsCount - 1
		else
			print(
				NoxxLFGBlueColor
					.. addonName
					.. ":|r Your group appears to have the required amount of healers. Please choose a different option."
			)
			self:Disable()
		end
		UpdateLFMMessage(
			dungeonRaidTextBox:GetText(),
			tankTextBox:GetText(),
			dpsTextBox:GetText(),
			healerTextBox:GetText(),
			tankPreferredTextBox:GetText(),
			dpsPreferredTextBox:GetText(),
			healerPreferredTextBox:GetText(),
			extraInfoTextBox:GetText()
		)
		if postButtonFrame then
			postButtonFrameMessage:SetText("|cFFFEC1C0" .. lfmCreationMessage)
		end
		local healerAmt = tonumber(healerTextBox:GetText()) or 0
		neededFrameHealerText:SetText(tostring(healerAmt))
	end)

	dpsBtn:SetScript("OnClick", function(self)
		local dpsNum = tonumber(dpsTextBox:GetText())

		if dpsNum > 0 then
			dpsNum = dpsNum - 1
			dpsTextBox:SetText(dpsNum)
			if dpsNum == 0 then
				dpsTextBox:SetText("")
			end
			frame:Hide()
			visiblePopupsCount = visiblePopupsCount - 1
		else
			print(
				NoxxLFGBlueColor
					.. addonName
					.. ":|r Your group appears to have the required amount of DPS. Please choose a different option."
			)
			self:Disable()
		end
		UpdateLFMMessage(
			dungeonRaidTextBox:GetText(),
			tankTextBox:GetText(),
			dpsTextBox:GetText(),
			healerTextBox:GetText(),
			tankPreferredTextBox:GetText(),
			dpsPreferredTextBox:GetText(),
			healerPreferredTextBox:GetText(),
			extraInfoTextBox:GetText()
		)
		if postButtonFrame then
			postButtonFrameMessage:SetText("|cFFFEC1C0" .. lfmCreationMessage)
		end
		local dpsAmt = tonumber(dpsTextBox:GetText()) or 0
		neededFrameDPSText:SetText(tostring(dpsAmt))
	end)

	local closeBtn = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
	closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5)
	frame:Show()

	return frame
end

local function OnSystemMessage(self, event, message)
	local joinPattern = "(.+) joins the party."
	local joinedGroup = "You join the party."
	local joinedRaid = "You join the raid group."
	local leaveText = "You leave the group."
	local removedText = "You have been removed from the group."
	local disbandedText = "Your group has been disbanded."

	local disbanded = message:match(leaveText) or message:match(removedText) or message:match(disbandedText)
	local officiallyJoined = message:match(joinedGroup) or message:match(joinedRaid)

	if
		(disbanded and ((postingMessage and startedWithRoles) or postingLFGMessage))
		or (officiallyJoined and postingLFGMessage)
	then
		print(
			NoxxLFGBlueColor
				.. addonName
				.. ": |cFFFFFF00Fulfillment has been met for your LFM/LFG Post. |r|rYou will no longer receive reminders to post your message."
		)
		postButtonFrame:Hide()
		ResetLFMMessage()
		CancelTimer()
		ResetLFGMessage()
		CancelLFGTimer()
	end

	if not UnitAffectingCombat("player") then
		local playerName = message:match(joinPattern)
		if playerName then
			if postingMessage then
				NoxxLFG:CheckAndShowRolePopup(
					playerName,
					tankTextBox:GetText(),
					healerTextBox:GetText(),
					dpsTextBox:GetText(),
					startedWithRoles,
					totalRoles
				)
			end
		else
			triedToShowPopup = true
			table.insert(triedToShowPlayerNames, playerName)
		end
	end
end

local joinsPartyFunc = CreateFrame("Frame")
joinsPartyFunc:RegisterEvent("CHAT_MSG_SYSTEM")
joinsPartyFunc:SetScript("OnEvent", OnSystemMessage)

pausePlayButton:SetScript("OnEnter", function()
	if not NoxxLFGSettings.pausedSearching then
		pausePlayButtonTexture:SetTexCoord(0.25, 0.5, 0, 0.25)
	else
		pausePlayButtonTexture:SetTexCoord(0, 0.25, 0.25, 0.5)
	end
end)

pausePlayButton:SetScript("OnLeave", function()
	if not NoxxLFGSettings.pausedSearching then
		pausePlayButtonTexture:SetTexCoord(0, 0.25, 0, 0.25)
	else
		pausePlayButtonTexture:SetTexCoord(0.75, 1, 0, 0.25)
	end
end)

pausePlayButton:SetScript("OnMouseDown", function()
	PlaySound(808)
	if not NoxxLFGSettings.pausedSearching then
		pausePlayButtonTexture:SetTexCoord(0.5, 0.75, 0, 0.25)
	else
		pausePlayButtonTexture:SetTexCoord(0.25, 0.5, 0.25, 0.5)
	end
end)

pausePlayButton:SetScript("OnMouseUp", function()
	if not NoxxLFGSettings.pausedSearching then
		NoxxLFGSettings.pausedSearching = true
		pausePlayButtonTexture:SetTexCoord(0, 0.25, 0.25, 0.5)
	else
		NoxxLFGSettings.pausedSearching = false
		pausePlayButtonTexture:SetTexCoord(0.25, 0.5, 0, 0.25)
	end
end)

dungeonCategory:SetScript("OnMouseDown", function()
	PlaySound(808)
	dungeonCategoryTextureBg:SetTexCoord(0.25, 0.5, 0, 0.25)
end)

dungeonCategory:SetScript("OnMouseUp", function()
	if hoveredCategory then
		dungeonCategoryTextureBg:SetTexCoord(0.5, 0.75, 0, 0.25)
		categoryFrame:Hide()
		lfmlfgButtonGroup:Hide()
		lfmCreationFrame:Hide()
		categorySearchFrameDungeons:Show()
		categorySearchFrameChildDungeons:Show()
		mainFrame.title:SetText(
			"|TInterface/AddOns/NoxxLFG/images/icon:20:20|t "
				.. NoxxLFGBlueColor
				.. addonName
				.. " v"
				.. versionNum
				.. "|r (Searching for Dungeons)"
		)
		PlaySound(808)
	else
		dungeonCategoryTextureBg:SetTexCoord(0, 0.25, 0, 0.25)
	end
end)

raidCategory:SetScript("OnMouseDown", function()
	PlaySound(808)
	raidCategoryTextureBg:SetTexCoord(0, 0.25, 0.25, 0.5)
end)

raidCategory:SetScript("OnMouseUp", function()
	if hoveredCategory then
		raidCategoryTextureBg:SetTexCoord(0.25, 0.5, 0.25, 0.5)
		categoryFrame:Hide()
		lfmlfgButtonGroup:Hide()
		lfmCreationFrame:Hide()
		categorySearchFrameRaids:Show()
		categorySearchFrameChildRaids:Show()
		mainFrame.title:SetText(
			"|TInterface/AddOns/NoxxLFG/images/icon:20:20|t "
				.. NoxxLFGBlueColor
				.. addonName
				.. " v"
				.. versionNum
				.. "|r (Searching for Raids)"
		)
		PlaySound(808)
	else
		raidCategoryTextureBg:SetTexCoord(0.75, 1, 0, 0.25)
	end
end)

travelCategory:SetScript("OnMouseDown", function()
	PlaySound(808)
	travelCategoryTextureBg:SetTexCoord(0.75, 1, 0.25, 0.5)
end)

travelCategory:SetScript("OnMouseUp", function()
	if hoveredCategory then
		travelCategoryTextureBg:SetTexCoord(0, 0.25, 0.5, 0.75)
		categoryFrame:Hide()
		lfmlfgButtonGroup:Hide()
		lfmCreationFrame:Hide()
		categorySearchFrameTravel:Show()
		categorySearchFrameChildTravel:Show()
		mainFrame.title:SetText(
			"|TInterface/AddOns/NoxxLFG/images/icon:20:20|t "
				.. NoxxLFGBlueColor
				.. addonName
				.. " v"
				.. versionNum
				.. "|r (Searching for Travel)"
		)
		PlaySound(808)
	else
		travelCategoryTextureBg:SetTexCoord(0.5, 0.75, 0.25, 0.5)
	end
end)

servicesCategory:SetScript("OnMouseDown", function()
	PlaySound(808)
	servicesCategoryTextureBg:SetTexCoord(0.5, 0.75, 0.5, 0.75)
end)

servicesCategory:SetScript("OnMouseUp", function()
	if hoveredCategory then
		servicesCategoryTextureBg:SetTexCoord(0.75, 1.0, 0.5, 0.75)
		categoryFrame:Hide()
		lfmlfgButtonGroup:Hide()
		lfmCreationFrame:Hide()
		categorySearchFrameServices:Show()
		categorySearchFrameChildServices:Show()
		mainFrame.title:SetText(
			"|TInterface/AddOns/NoxxLFG/images/icon:20:20|t "
				.. NoxxLFGBlueColor
				.. addonName
				.. " v"
				.. versionNum
				.. "|r (Searching for Services)"
		)
		PlaySound(808)
	else
		servicesCategoryTextureBg:SetTexCoord(0.25, 0.5, 0.5, 0.75)
	end
end)

eventsCategory:SetScript("OnMouseDown", function()
	PlaySound(808)
	eventsCategoryTextureBg:SetTexCoord(0.25, 0.5, 0.75, 1.0)
end)

eventsCategory:SetScript("OnMouseUp", function()
	if hoveredCategory then
		eventsCategoryTextureBg:SetTexCoord(0.5, 0.75, 0.75, 1.0)
		categoryFrame:Hide()
		lfmlfgButtonGroup:Hide()
		lfmCreationFrame:Hide()
		categorySearchFrameEvents:Show()
		categorySearchFrameChildEvents:Show()
		mainFrame.title:SetText(
			"|TInterface/AddOns/NoxxLFG/images/icon:20:20|t "
				.. NoxxLFGBlueColor
				.. addonName
				.. " v"
				.. versionNum
				.. "|r (Searching for Events & PvP)"
		)
		PlaySound(808)
	else
		eventsCategoryTextureBg:SetTexCoord(0, 0.25, 0.75, 1.0)
	end
end)

if not dungeonFrames then
	dungeonFrames = {}
end

if not raidFoundFrames then
	raidFoundFrames = {}
end

if not travelFrames then
	travelFrames = {}
end

if not servicesFrames then
	servicesFrames = {}
end

if not eventsFrames then
	eventsFrames = {}
end

local function getDungeonByName(dungeonName)
	for _, dungeon in ipairs(dungeons) do
		if dungeon.name == dungeonName then
			return dungeon
		end
	end
	return nil
end

local function getRaidByName(raidName)
	for _, raid in ipairs(raids) do
		if raid.name == raidName then
			return raid
		end
	end
	return nil
end

local function updateDungeonCategorySearchFrameChildHeight()
	local frameHeight = 35
	local gap = 3
	local totalHeight = 0

	if #dungeonFrames > 0 then
		totalHeight = (#dungeonFrames * frameHeight) + ((#dungeonFrames - 1) * gap)
	end

	categorySearchFrameChildDungeons:SetHeight(math.max(totalHeight, frameHeight))
end

local function updateRaidCategorySearchFrameChildHeight()
	local frameHeight = 35
	local gap = 3
	local totalHeight = 0

	if #raidFoundFrames > 0 then
		totalHeight = (#raidFoundFrames * frameHeight) + ((#raidFoundFrames - 1) * gap)
	end

	categorySearchFrameChildRaids:SetHeight(math.max(totalHeight, frameHeight))
end

local function updateTravelCategorySearchFrameChildHeight()
	local frameHeight = 35
	local gap = 3
	local totalHeight = 0

	if #travelFrames > 0 then
		totalHeight = (#travelFrames * frameHeight) + ((#travelFrames - 1) * gap)
	end

	categorySearchFrameChildTravel:SetHeight(math.max(totalHeight, frameHeight))
end

local function updateServicesCategorySearchFrameChildHeight()
	local frameHeight = 35
	local gap = 3
	local totalHeight = 0

	if #servicesFrames > 0 then
		totalHeight = (#servicesFrames * frameHeight) + ((#servicesFrames - 1) * gap)
	end

	categorySearchFrameChildServices:SetHeight(math.max(totalHeight, frameHeight))
end

local function updateEventsCategorySearchFrameChildHeight()
	local frameHeight = 35
	local gap = 3
	local totalHeight = 0

	if #eventsFrames > 0 then
		totalHeight = (#eventsFrames * frameHeight) + ((#eventsFrames - 1) * gap)
	end

	categorySearchFrameChildEvents:SetHeight(math.max(totalHeight, frameHeight))
end

local cleanupFrame = CreateFrame("Frame")
local elapsedTime = 0

local function updateDungeonFramesPosition()
	local startY = -5
	local gap = 3

	for i, frame in ipairs(dungeonFrames) do
		frame:ClearAllPoints()
		if i == 1 then
			frame:SetPoint("TOP", categorySearchFrameChildDungeons, "TOP", 0, startY)
		else
			frame:SetPoint("TOP", dungeonFrames[i - 1], "BOTTOM", 0, -gap)
		end
	end

	local totalHeight = #dungeonFrames + gap
	categorySearchFrameChildDungeons:SetHeight(math.max(totalHeight, 1))
end

local function updateRaidFramesPosition()
	local startY = -5
	local gap = 3

	for i, frame in ipairs(raidFoundFrames) do
		frame:ClearAllPoints()
		if i == 1 then
			frame:SetPoint("TOP", categorySearchFrameChildRaids, "TOP", 0, startY)
		else
			frame:SetPoint("TOP", raidFoundFrames[i - 1], "BOTTOM", 0, -gap)
		end
	end

	local totalHeight = #raidFoundFrames + gap
	categorySearchFrameChildRaids:SetHeight(math.max(totalHeight, 1))
end

local function updateTravelFramesPosition()
	local startY = -5
	local gap = 3

	for i, frame in ipairs(travelFrames) do
		frame:ClearAllPoints()
		if i == 1 then
			frame:SetPoint("TOP", categorySearchFrameChildTravel, "TOP", 0, startY)
		else
			frame:SetPoint("TOP", travelFrames[i - 1], "BOTTOM", 0, -gap)
		end
	end

	local totalHeight = #travelFrames + gap
	categorySearchFrameChildTravel:SetHeight(math.max(totalHeight, 1))
end

local function updateServicesFramesPosition()
	local startY = -5
	local gap = 3

	for i, frame in ipairs(servicesFrames) do
		frame:ClearAllPoints()
		if i == 1 then
			frame:SetPoint("TOP", categorySearchFrameChildServices, "TOP", 0, startY)
		else
			frame:SetPoint("TOP", servicesFrames[i - 1], "BOTTOM", 0, -gap)
		end
	end

	local totalHeight = #servicesFrames + gap
	categorySearchFrameChildServices:SetHeight(math.max(totalHeight, 1))
end

local function updateEventsFramesPosition()
	local startY = -5
	local gap = 3

	for i, frame in ipairs(eventsFrames) do
		frame:ClearAllPoints()
		if i == 1 then
			frame:SetPoint("TOP", categorySearchFrameChildEvents, "TOP", 0, startY)
		else
			frame:SetPoint("TOP", eventsFrames[i - 1], "BOTTOM", 0, -gap)
		end
	end

	local totalHeight = #eventsFrames + gap
	categorySearchFrameChildEvents:SetHeight(math.max(totalHeight, 1))
end

local function cleanupOldDungeonGroups()
	local currentTime = time()

	if not NoxxLFGSettings.pausedSearching then
		while
			NoxxLFGListings.dungeonGroups
			and #NoxxLFGListings.dungeonGroups > 0
			and (currentTime - NoxxLFGListings.dungeonGroups[#NoxxLFGListings.dungeonGroups].timePosted)
				> NoxxLFGSettings.dungeonsUpdateInterval
		do
			if dungeonFrames[#dungeonFrames] then
				dungeonFrames[#dungeonFrames]:Hide()
				table.remove(dungeonFrames, #dungeonFrames)
			end
			table.remove(NoxxLFGListings.dungeonGroups, #NoxxLFGListings.dungeonGroups)
		end
	end

	for i = #NoxxLFGListings.dungeonGroups, 1, -1 do
		local dungeonRoles = NoxxLFGListings.dungeonGroups[i].rolesNeeded
		local dungeonName = NoxxLFGListings.dungeonGroups[i].dungeonName
		local dungeonData = getDungeonByName(dungeonName)
		if dungeonData then
			if not dungeonData.checked then
				if dungeonFrames[i] then
					dungeonFrames[i]:Hide()
					table.remove(dungeonFrames, i)
				end
				table.remove(NoxxLFGListings.dungeonGroups, i)
			end
		end
	end

	updateDungeonFramesPosition()
end

local function cleanupOldRaidGroups()
	local currentTime = time()

	if not NoxxLFGSettings.pausedSearching then
		while
			NoxxLFGListings.raidGroups
			and #NoxxLFGListings.raidGroups > 0
			and (currentTime - NoxxLFGListings.raidGroups[#NoxxLFGListings.raidGroups].timePosted)
				> NoxxLFGSettings.raidsUpdateInterval
		do
			if raidFoundFrames[#raidFoundFrames] then
				raidFoundFrames[#raidFoundFrames]:Hide()
				table.remove(raidFoundFrames, #raidFoundFrames)
			end
			table.remove(NoxxLFGListings.raidGroups, #NoxxLFGListings.raidGroups)
		end
	end

	if NoxxLFGListings.raidGroups then
		for i = #NoxxLFGListings.raidGroups, 1, -1 do
			local raidName = NoxxLFGListings.raidGroups[i].raidName
			local raidData = getRaidByName(raidName)
			if raidData then
				if not raidData.checked then
					if raidFoundFrames[i] then
						raidFoundFrames[i]:Hide()
						table.remove(raidFoundFrames, i)
					end
					table.remove(NoxxLFGListings.raidGroups, i)
				end
			end
		end
	end

	updateRaidFramesPosition()
end

local function cleanupOldTravelGroups()
	local currentTime = time()

	if not NoxxLFGSettings.pausedSearching then
		while
			#travelGroups > 0
			and (currentTime - travelGroups[#travelGroups].timePosted) > NoxxLFGSettings.travelUpdateInterval
		do
			if travelFrames[#travelFrames] then
				travelFrames[#travelFrames]:Hide()
				table.remove(travelFrames, #travelFrames)
			end
			table.remove(travelGroups, #travelGroups)
		end
	end

	updateTravelFramesPosition()
end

local function cleanupOldServicesGroups()
	local currentTime = time()

	if not NoxxLFGSettings.pausedSearching then
		while
			#servicesGroups > 0
			and (currentTime - servicesGroups[#servicesGroups].timePosted) > NoxxLFGSettings.servicesUpdateInterval
		do
			if servicesFrames[#servicesFrames] then
				servicesFrames[#servicesFrames]:Hide()
				table.remove(servicesFrames, #servicesFrames)
			end
			table.remove(servicesGroups, #servicesGroups)
		end
	end

	updateServicesFramesPosition()
end

local function cleanupOldEventsGroups()
	local currentTime = time()

	if not NoxxLFGSettings.pausedSearching then
		while
			#eventsGroups > 0
			and (currentTime - eventsGroups[#eventsGroups].timePosted) > NoxxLFGSettings.eventsUpdateInterval
		do
			if eventsFrames[#eventsFrames] then
				eventsFrames[#eventsFrames]:Hide()
				table.remove(eventsFrames, #eventsFrames)
			end
			table.remove(eventsGroups, #eventsGroups)
		end
	end

	updateEventsFramesPosition()
end

cleanupFrame:SetScript("OnUpdate", function(self, elapsed)
	elapsedTime = elapsedTime + elapsed
	if elapsedTime >= 10 then
		cleanupOldDungeonGroups()
		cleanupOldRaidGroups()
		cleanupOldTravelGroups()
		cleanupOldServicesGroups()
		cleanupOldEventsGroups()
		elapsedTime = 0
	end
end)

local dungeonFilterDropdown = LibDD:Create_UIDropDownMenu("DungeonFilterDropdown", mainFrame)
dungeonFilterDropdown:SetPoint("LEFT", categorySearchBackButton, "RIGHT", 15, -2)
dungeonFilterDropdown:Hide()
LibDD:UIDropDownMenu_SetWidth(dungeonFilterDropdown, 150)
LibDD:UIDropDownMenu_SetText(dungeonFilterDropdown, "Showing All Dungeons")

local uncheckAllDungeonsButton =
	CreateFrame("Button", "NoxxLFGUncheckDungeonsButton", dungeonFilterDropdown, "UIPanelButtonTemplate")
uncheckAllDungeonsButton:SetSize(100, 25)
uncheckAllDungeonsButton:SetText("Uncheck All")
uncheckAllDungeonsButton:SetPoint("LEFT", dungeonFilterDropdown, "RIGHT", -8, 3)

local checkAllDungeonsButton =
	CreateFrame("Button", "NoxxLFGUncheckDungeonsButton", dungeonFilterDropdown, "UIPanelButtonTemplate")
checkAllDungeonsButton:SetSize(100, 25)
checkAllDungeonsButton:SetText("Check All")
checkAllDungeonsButton:SetPoint("LEFT", uncheckAllDungeonsButton, "RIGHT", 3, 0)

local function UpdateDropdownText()
	local checkedCount = 0
	for i, dungeon in ipairs(dungeons) do
		if dungeon.checked then
			checkedCount = checkedCount + 1
		end
	end

	local dropdownText
	if checkedCount > 0 and checkedCount < #dungeons then
		dropdownText = "Filtering " .. checkedCount .. " Dungeons"
	elseif checkedCount == #dungeons then
		dropdownText = "Showing All Dungeons"
	else
		dropdownText = "No Dungeons Selected"
	end

	LibDD:UIDropDownMenu_SetText(dungeonFilterDropdown, dropdownText)
end

local function UncheckAllDungeons()
	PlaySound(808)
	for i, dungeon in ipairs(dungeons) do
		dungeon.checked = false
	end
	LibDD:UIDropDownMenu_Refresh(dungeonFilterDropdown)
	UpdateDropdownText()
	cleanupOldDungeonGroups()
end

uncheckAllDungeonsButton:SetScript("OnClick", UncheckAllDungeons)

local function CheckAllDungeons()
	PlaySound(808)
	for i, dungeon in ipairs(dungeons) do
		dungeon.checked = true
	end
	LibDD:UIDropDownMenu_Refresh(dungeonFilterDropdown)
	UpdateDropdownText()
end

checkAllDungeonsButton:SetScript("OnClick", CheckAllDungeons)

local function initializeDungeonDropdown(self, level)
	local info = LibDD:UIDropDownMenu_CreateInfo()
	for i, dungeon in ipairs(dungeons) do
		info.text = "|c" .. dungeon.color .. dungeon.name .. " |r(Lv. " .. dungeon.levelRange .. ")"
		info.isNotRadio = true
		info.keepShownOnClick = true
		info.func = function(self)
			dungeon.checked = not dungeon.checked
			cleanupOldDungeonGroups()
			UpdateDropdownText()
		end
		info.checked = dungeon.checked
		LibDD:UIDropDownMenu_AddButton(info, level)
	end
end

LibDD:UIDropDownMenu_Initialize(dungeonFilterDropdown, initializeDungeonDropdown)

local raidFilterDropdown = LibDD:Create_UIDropDownMenu("RaidFilterDropdown", mainFrame)
raidFilterDropdown:Hide()
raidFilterDropdown:SetPoint("LEFT", categorySearchBackButton, "RIGHT", 15, -2)
LibDD:UIDropDownMenu_SetWidth(raidFilterDropdown, 150)
LibDD:UIDropDownMenu_SetText(raidFilterDropdown, "Filter Raids")

local function initializeRaidDropdown(self, level)
	local info = LibDD:UIDropDownMenu_CreateInfo()
	for i, raid in ipairs(raids) do
		info.text = "|c" .. raid.color .. raid.name .. " |r(Lv. " .. raid.levelRange .. ")"
		info.isNotRadio = true
		info.keepShownOnClick = true
		info.func = function(self)
			raid.checked = not raid.checked
			cleanupOldRaidGroups()
		end
		info.checked = raid.checked
		LibDD:UIDropDownMenu_AddButton(info, level)
	end
end

LibDD:UIDropDownMenu_Initialize(raidFilterDropdown, initializeRaidDropdown)

categorySearchFrameChildDungeons:SetScript("OnShow", function()
	categorySearchBackButton:Show()
	pausePlayButton:Show()
	topHintText:SetText(
		NoxxLFGBlueColor
			.. "Left-click:|cFFFFFFFF Show Post Info\n"
			.. NoxxLFGBlueColor
			.. "Shift + Right-click: |cFFFFFFFFSend Invite|r"
	)
	dungeonFilterDropdown:Show()
	topHintText:Show()
end)

categorySearchFrameChildRaids:SetScript("OnShow", function()
	categorySearchBackButton:Show()
	pausePlayButton:Show()
	topHintText:SetText(
		NoxxLFGBlueColor
			.. "Left-click:|cFFFFFFFF Show Post Info\n"
			.. NoxxLFGBlueColor
			.. "Shift + Right-click: |cFFFFFFFFSend Invite|r"
	)
	raidFilterDropdown:Show()
	topHintText:Show()
end)

categorySearchFrameChildTravel:SetScript("OnShow", function()
	categorySearchBackButton:Show()
	pausePlayButton:Show()
	topHintText:SetText(
		NoxxLFGBlueColor
			.. "Left-click:|cFFFFFFFF Start Whisper\n"
			.. NoxxLFGBlueColor
			.. 'Shift + Right-click: |cFFFFFFFFSend "inv" Whisper'
	)
	topHintText:Show()
end)

categorySearchFrameChildServices:SetScript("OnShow", function()
	categorySearchBackButton:Show()
	pausePlayButton:Show()
	topHintText:SetText(
		NoxxLFGBlueColor
			.. "Left-click:|cFFFFFFFF Start Whisper\n"
			.. NoxxLFGBlueColor
			.. 'Shift + Right-click: |cFFFFFFFFSend "inv" Whisper'
	)
	topHintText:Show()
end)

categorySearchFrameChildEvents:SetScript("OnShow", function()
	categorySearchBackButton:Show()
	pausePlayButton:Show()
	topHintText:SetText(
		NoxxLFGBlueColor
			.. "Left-click:|cFFFFFFFF Start Whisper\n"
			.. NoxxLFGBlueColor
			.. 'Shift + Right-click: |cFFFFFFFFSend "inv" Whisper'
	)
	topHintText:Show()
end)

local function formatTimeDifference(timePosted)
	local currentTime = time()
	local difference = currentTime - timePosted

	if difference < 60 then
		return difference .. " sec ago"
	else
		return math.floor(difference / 60) .. " min ago"
	end
end

local function updateElapsedTime()
	for _, frame in ipairs(dungeonFrames) do
		if frame.timePosted then
			frame.postAuthor:SetText(frame.author .. " (" .. formatTimeDifference(frame.timePosted) .. ")")
		end
	end

	for _, frame in ipairs(raidFoundFrames) do
		if frame.timePosted then
			frame.postAuthor:SetText(frame.author .. " (" .. formatTimeDifference(frame.timePosted) .. ")")
		end
	end

	for _, frame in ipairs(travelFrames) do
		if frame.timePosted then
			frame.postAuthor:SetText(frame.author .. " (" .. formatTimeDifference(frame.timePosted) .. ")")
		end
	end

	for _, frame in ipairs(servicesFrames) do
		if frame.timePosted then
			frame.postAuthor:SetText(frame.author .. " (" .. formatTimeDifference(frame.timePosted) .. ")")
		end
	end

	for _, frame in ipairs(eventsFrames) do
		if frame.timePosted then
			frame.postAuthor:SetText(frame.author .. " (" .. formatTimeDifference(frame.timePosted) .. ")")
		end
	end
end

local updateThrottle = 0
local function OnUpdateHandler(self, elapsed)
	updateThrottle = updateThrottle + elapsed
	if updateThrottle >= 5 then
		updateElapsedTime()
		updateThrottle = 0
	end
end

local timerFrame = CreateFrame("Frame")
timerFrame:SetScript("OnUpdate", OnUpdateHandler)

local function addToDungeons(
	shortMsg,
	msg,
	author,
	timePosted,
	dungeon,
	subDungeon,
	dungeonColor,
	spamDungeon,
	classColor,
	rolesNeeded
)
	local frameWidth = categorySearchFrameChildDungeons:GetWidth() - 15
	local frameHeight = 35
	local roleHighlighted = false

	local foundFrame = CreateFrame(
		"Frame",
		"NoxxLFGDungeonSearchFrame" .. #dungeonFrames + 1,
		categorySearchFrameChildDungeons,
		"BackdropTemplate"
	)
	foundFrame:SetSize(frameWidth, frameHeight)
	foundFrame:SetFrameStrata("HIGH")

	foundFrame.author = "|c" .. classColor .. author .. "|r"
	foundFrame.timePosted = timePosted

	local foundFrameInteractions = CreateFrame("Frame", nil, foundFrame)
	foundFrameInteractions:SetSize(frameWidth, frameHeight)
	foundFrameInteractions:SetPoint("TOPLEFT", foundFrame, "TOPLEFT", 0, 0)
	foundFrameInteractions:SetPoint("BOTTOMRIGHT", foundFrame, "BOTTOMRIGHT", 0, 0)

	foundFrame:SetBackdrop({
		bgFile = "interface/garrison/classhallinternalbackground",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true,
		tileSize = 256,
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	foundFrame:SetBackdropBorderColor(0.7, 0.7, 0.7)

	if NoxxLFGSettings.highlightSetRole then
		for _, role in ipairs(rolesNeeded) do
			if NoxxLFGSetRole.role == role then
				roleHighlighted = true
				foundFrame:SetBackdrop({
					bgFile = "interface/garrison/garrisonuibackground2",
					edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
					tile = true,
					tileSize = 256,
					edgeSize = 16,
					insets = { left = 4, right = 4, top = 4, bottom = 4 },
				})
				foundFrame:SetBackdropBorderColor(0.0, 1, 0.0)
				break
			end
		end
	end

	foundFrame.title = foundFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	foundFrame.title:SetPoint("CENTER", foundFrame, "CENTER", 0, 0)
	foundFrame.title:SetScale(0.8)
	foundFrame.title:SetText((spamDungeon and "|cFFf27868Multi-run: |cFFFFFFFF" or "|cFFFFFFFF") .. shortMsg .. "|r")

	foundFrameInteractions:SetScript("OnEnter", function()
		if not roleHighlighted then
			foundFrame:SetBackdropBorderColor(0.9, 0.9, 0.9)
		end
		GameTooltip:SetOwner(foundFrameInteractions, "ANCHOR_BOTTOM", 0, -5)
		if #msg > shortMessageLength then
			GameTooltip:SetText("|cFFFFFFFF" .. msg, nil, nil, nil, nil, true)
		end
		GameTooltip:SetScale(0.8)
		GameTooltip:Show()
	end)

	foundFrameInteractions:SetScript("OnLeave", function()
		GameTooltip:Hide()
		GameTooltip:SetScale(1)
		if not roleHighlighted then
			foundFrame:SetBackdropBorderColor(0.7, 0.7, 0.7)
		end
	end)

	local dungeonInfo = getDungeonByName(dungeon)

	foundFrameInteractions:SetScript("OnMouseUp", function(self, button)
		PlaySound(808)
		if button == "LeftButton" and not IsShiftKeyDown() then
			if author:sub(-1) == "s" then
				sideWindow.title:SetText("|c" .. classColor .. author .. "'|r Dungeon Post")
			else
				sideWindow.title:SetText("|c" .. classColor .. author .. "'s|r Dungeon Post")
			end

			sideWindow.activityTitle:SetText(
				"|c"
					.. dungeonColor
					.. dungeon
					.. "|r"
					.. (dungeonInfo and " (Lv. " .. dungeonInfo.levelRange .. ")" or "")
			)

			if subDungeon and subDungeon ~= "None" then
				sideWindow.activityTitleSub:SetText("Wing: |cFFFFFFFF" .. subDungeon .. "|r")
				sideWindow.messageFrame:SetPoint("TOPLEFT", sideWindow.activityTitleSub, "TOPLEFT", 0, -20)
			else
				sideWindow.activityTitleSub:SetText("")
				sideWindow.messageFrame:SetPoint("TOPLEFT", sideWindow.activityTitle, "TOPLEFT", 0, -20)
			end

			if spamDungeon then
				sideWindow.messageFrame:SetBackdropBorderColor(1, 0.4, 0.4)
				sideWindow.messageFrame.spamDungeon:SetText("|cFFFF6666Multi-run Group")
			else
				sideWindow.messageFrame:SetBackdropBorderColor(0.6, 0.6, 0.6)
				sideWindow.messageFrame.spamDungeon:SetText("")
			end

			sideWindow.messageFrame.message:SetText(
				"|c" .. classColor .. author .. ":|r " .. "|cFFFFFFFF" .. msg .. "|r"
			)
			sideWindow:Show()

			sideWindow.actionFrame.locationInfo:SetText(
				"|cFFFFFFFFLocation: |r\n\n" .. (dungeonInfo and dungeonInfo.location or "")
			)

			sideWindow.actionFrame.inviteButton:SetScript("OnClick", function()
				DEFAULT_CHAT_FRAME.editBox:SetText("/invite " .. author)
				ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
			end)

			sideWindow.actionFrame.whisperButton:SetScript("OnClick", function()
				ChatFrame_OpenChat("/w " .. author .. " ")
			end)

			sideWindow.actionFrame.whoButton:SetScript("OnClick", function()
				C_FriendList.SendWho(author)
			end)
		elseif button == "RightButton" and IsShiftKeyDown() then
			DEFAULT_CHAT_FRAME.editBox:SetText("/invite " .. author)
			ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
		elseif button == "LeftButton" and IsShiftKeyDown() then
			PlaySound(808)
			ChatFrame_OpenChat("/w " .. author .. " ")
		end
	end)

	foundFrame.dungeonName = foundFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	foundFrame.dungeonName:SetPoint("LEFT", foundFrame, "LEFT", 15, 0)
	foundFrame.dungeonName:SetScale(0.8)
	foundFrame.dungeonName:SetText(
		"|c" .. dungeonColor .. dungeon .. (subDungeon ~= "None" and ": |cFFFFFFFF" .. subDungeon or "|r")
	)

	local iconSize = 16
	local iconSpacing = 2
	local iconOffset = 5
	local iconYOffset = 0

	for i, roleName in ipairs(rolesNeeded) do
		local roleIcon = foundFrame:CreateTexture(nil, "OVERLAY")
		roleIcon:SetSize(iconSize, iconSize)
		roleIcon:SetPoint(
			"LEFT",
			foundFrame.dungeonName,
			"RIGHT",
			iconOffset + (iconSize + iconSpacing) * (i - 1),
			iconYOffset
		)

		if roleName == "Tank" then
			roleIcon:SetTexture("interface/lfgframe/uilfgpromptsdf")
			roleIcon:SetTexCoord(0.75634765625, 0.88134765625, 0.25146484375, 0.37646484375)
		elseif roleName == "Healer" then
			roleIcon:SetTexture("interface/lfgframe/uilfgpromptsdf")
			roleIcon:SetTexCoord(0.12646484375, 0.25146484375, 0.25146484375, 0.37646484375)
		elseif roleName == "DPS" then
			roleIcon:SetTexture("interface/lfgframe/uilfgpromptsdf")
			roleIcon:SetTexCoord(0.00048828125, 0.12548828125, 0.37744140625, 0.50244140625)
		end
	end

	foundFrame.postAuthor = foundFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	foundFrame.postAuthor:SetScale(0.8)
	foundFrame.postAuthor:SetPoint("RIGHT", foundFrame, "RIGHT", -15, 0)
	foundFrame.postAuthor:SetText("|c" .. classColor .. author .. "|r (" .. formatTimeDifference(timePosted) .. ")")

	table.insert(dungeonFrames, 1, foundFrame)

	updateDungeonFramesPosition()

	updateDungeonCategorySearchFrameChildHeight()
end

local function addToRaids(shortMsg, msg, author, timePosted, raid, raidColor, classColor, rolesNeeded)
	local frameWidth = categorySearchFrameChildRaids:GetWidth() - 15
	local frameHeight = 35
	local roleHighlighted = false

	local foundFrame = CreateFrame(
		"Frame",
		"NoxxLFGRaidSearchFrame" .. #raidFoundFrames + 1,
		categorySearchFrameChildRaids,
		"BackdropTemplate"
	)
	foundFrame:SetSize(frameWidth, frameHeight)
	foundFrame:SetFrameStrata("HIGH")

	foundFrame.author = "|c" .. classColor .. author .. "|r"
	foundFrame.timePosted = timePosted

	local foundFrameInteractions = CreateFrame("Frame", nil, foundFrame)
	foundFrameInteractions:SetSize(frameWidth, frameHeight)
	foundFrameInteractions:SetPoint("TOPLEFT", foundFrame, "TOPLEFT", 0, 0)
	foundFrameInteractions:SetPoint("BOTTOMRIGHT", foundFrame, "BOTTOMRIGHT", 0, 0)

	foundFrame:SetBackdrop({
		bgFile = "interface/garrison/garrisonuibackground2",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true,
		tileSize = 128,
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	foundFrame:SetBackdropBorderColor(1, 0.35, 0.35)

	if NoxxLFGSettings.highlightSetRole then
		for _, role in ipairs(rolesNeeded) do
			if NoxxLFGSetRole.role == role then
				roleHighlighted = true
				foundFrame:SetBackdrop({
					bgFile = "interface/garrison/classhallinternalbackground",
					edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
					tile = true,
					tileSize = 256,
					edgeSize = 16,
					insets = { left = 4, right = 4, top = 4, bottom = 4 },
				})
				foundFrame:SetBackdropBorderColor(0.0, 1, 0.0)
				break
			end
		end
	end

	foundFrame.title = foundFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	foundFrame.title:SetScale(0.8)
	foundFrame.title:SetPoint("CENTER", foundFrame, "CENTER", 0, 0)
	foundFrame.title:SetText(shortMsg)

	foundFrameInteractions:SetScript("OnEnter", function()
		if not roleHighlighted then
			foundFrame:SetBackdropBorderColor(1, 0.70, 0.70)
		end
		GameTooltip:SetOwner(foundFrameInteractions, "ANCHOR_BOTTOM", 0, -5)
		if #msg > shortMessageLength then
			GameTooltip:SetText("|cFFFFFFFF" .. msg, nil, nil, nil, nil, true)
		end
		GameTooltip:SetScale(0.8)
		GameTooltip:Show()
	end)

	foundFrameInteractions:SetScript("OnLeave", function()
		GameTooltip:Hide()
		GameTooltip:SetScale(1)
		if not roleHighlighted then
			foundFrame:SetBackdropBorderColor(1, 0.35, 0.35)
		end
	end)

	local raidInfo = getRaidByName(raid)

	foundFrameInteractions:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" and not IsShiftKeyDown() then
			if author:sub(-1) == "s" then
				sideWindow.title:SetText("|c" .. classColor .. author .. "'|r Raid Post")
			else
				sideWindow.title:SetText("|c" .. classColor .. author .. "'s|r Raid Post")
			end

			sideWindow.activityTitle:SetText(
				"|c" .. raidColor .. raid .. "|r" .. (raidInfo and " (Lv. " .. raidInfo.levelRange .. ")" or "")
			)

			-- if subRaid and subRaid ~= "None" then
			-- 	sideWindow.activityTitleSub:SetText("Wing: |cFFFFFFFF" .. subRaid .. "|r")
			-- 	sideWindow.messageFrame:SetPoint("TOPLEFT", sideWindow.activityTitleSub, "TOPLEFT", 0, -20)
			-- else
			sideWindow.activityTitleSub:SetText("")
			sideWindow.messageFrame:SetPoint("TOPLEFT", sideWindow.activityTitle, "TOPLEFT", 0, -20)
			-- end

			sideWindow.messageFrame.message:SetText(
				"|c" .. classColor .. author .. ":|r " .. "|cFFFFFFFF" .. msg .. "|r"
			)
			sideWindow:Show()

			sideWindow.actionFrame.locationInfo:SetText(
				"|cFFFFFFFFLocation: |r\n\n" .. (raidInfo and raidInfo.location or "")
			)

			sideWindow.actionFrame.inviteButton:SetScript("OnClick", function()
				DEFAULT_CHAT_FRAME.editBox:SetText("/invite " .. author)
				ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
			end)

			sideWindow.actionFrame.whisperButton:SetScript("OnClick", function()
				ChatFrame_OpenChat("/w " .. author .. " ")
			end)

			sideWindow.actionFrame.whoButton:SetScript("OnClick", function()
				C_FriendList.SendWho(author)
			end)
		elseif button == "RightButton" and IsShiftKeyDown() then
			DEFAULT_CHAT_FRAME.editBox:SetText("/invite " .. author)
			ChatEdit_SendText(DEFAULT_CHAT_FRAME.editBox, 0)
		elseif button == "LeftButton" and IsShiftKeyDown() then
			PlaySound(808)
			ChatFrame_OpenChat("/w " .. author .. " ")
		end
	end)

	foundFrame.raidName = foundFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	foundFrame.raidName:SetScale(0.8)
	foundFrame.raidName:SetPoint("LEFT", foundFrame, "LEFT", 15, 0)
	foundFrame.raidName:SetText("|c" .. raidColor .. raid .. "|r")

	local iconSize = 16
	local iconSpacing = 2
	local iconOffset = 5
	local iconYOffset = 0

	for i, roleName in ipairs(rolesNeeded) do
		local roleIcon = foundFrame:CreateTexture(nil, "OVERLAY")
		roleIcon:SetSize(iconSize, iconSize)
		roleIcon:SetPoint(
			"LEFT",
			foundFrame.raidName,
			"RIGHT",
			iconOffset + (iconSize + iconSpacing) * (i - 1),
			iconYOffset
		)

		if roleName == "Tank" then
			roleIcon:SetTexture("interface/lfgframe/uilfgpromptsdf")
			roleIcon:SetTexCoord(0.75634765625, 0.88134765625, 0.25146484375, 0.37646484375)
		elseif roleName == "Healer" then
			roleIcon:SetTexture("interface/lfgframe/uilfgpromptsdf")
			roleIcon:SetTexCoord(0.12646484375, 0.25146484375, 0.25146484375, 0.37646484375)
		elseif roleName == "DPS" then
			roleIcon:SetTexture("interface/lfgframe/uilfgpromptsdf")
			roleIcon:SetTexCoord(0.00048828125, 0.12548828125, 0.37744140625, 0.50244140625)
		end
	end

	foundFrame.postAuthor = foundFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	foundFrame.postAuthor:SetScale(0.8)
	foundFrame.postAuthor:SetPoint("RIGHT", foundFrame, "RIGHT", -15, 0)
	foundFrame.postAuthor:SetText("|c" .. classColor .. author .. "|r (" .. formatTimeDifference(timePosted) .. ")")

	table.insert(raidFoundFrames, 1, foundFrame)

	updateRaidFramesPosition()

	updateRaidCategorySearchFrameChildHeight()
end

local function addToTravel(shortMsg, msg, author, timePosted, location, locationColor, classColor, goldAmount)
	local frameWidth = categorySearchFrameChildTravel:GetWidth() - 15
	local frameHeight = 35
	local iconSize = 12
	local iconSpacing = 2

	local foundFrame = CreateFrame(
		"Frame",
		"NoxxLFGTravelSearchFrame" .. #travelFrames + 1,
		categorySearchFrameChildTravel,
		"BackdropTemplate"
	)
	foundFrame:SetSize(frameWidth, frameHeight)
	foundFrame:SetFrameStrata("HIGH")

	foundFrame.author = "|c" .. classColor .. author .. "|r"
	foundFrame.timePosted = timePosted

	local foundFrameInteractions = CreateFrame("Frame", nil, foundFrame)
	foundFrameInteractions:SetSize(frameWidth, frameHeight)
	foundFrameInteractions:SetPoint("TOPLEFT", foundFrame, "TOPLEFT", 0, 0)
	foundFrameInteractions:SetPoint("BOTTOMRIGHT", foundFrame, "BOTTOMRIGHT", 0, 0)

	foundFrame:SetBackdrop({
		bgFile = "interface/garrison/classhallinternalbackground",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true,
		tileSize = 128,
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	foundFrame:SetBackdropBorderColor(1, 0.6, 0.85)

	foundFrame.title = foundFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	foundFrame.title:SetScale(0.8)
	foundFrame.title:SetPoint("CENTER", foundFrame, "CENTER", 0, 0)
	foundFrame.title:SetText(shortMsg)

	foundFrameInteractions:SetScript("OnEnter", function()
		foundFrame:SetBackdropBorderColor(1, 0.8, 1)
		GameTooltip:SetOwner(foundFrameInteractions, "ANCHOR_BOTTOM", 0, -5)
		if #msg > shortMessageLength then
			GameTooltip:SetText("|cFFFFFFFF" .. msg, nil, nil, nil, nil, true)
		end
		GameTooltip:SetScale(0.8)
		GameTooltip:Show()
	end)

	foundFrameInteractions:SetScript("OnLeave", function()
		GameTooltip:Hide()
		GameTooltip:SetScale(1)
		foundFrame:SetBackdropBorderColor(1, 0.6, 0.85)
	end)

	foundFrameInteractions:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			PlaySound(808)
			ChatFrame_OpenChat("/w " .. author .. " ")
		elseif button == "RightButton" and IsShiftKeyDown() then
			SendChatMessage("inv", "WHISPER", nil, author)
		end
	end)

	foundFrame.locName = foundFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	foundFrame.locName:SetScale(0.8)
	foundFrame.locName:SetPoint("LEFT", foundFrame, "LEFT", 15, 0)
	foundFrame.locName:SetText("|c" .. locationColor .. location .. "|r")

	foundFrame.postAuthor = foundFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	foundFrame.postAuthor:SetScale(0.8)
	foundFrame.postAuthor:SetPoint("RIGHT", foundFrame, "RIGHT", -15, 0)
	foundFrame.postAuthor:SetText("|c" .. classColor .. author .. "|r (" .. formatTimeDifference(timePosted) .. ")")

	if goldAmount then
		local goldAmountValue = tonumber(goldAmount) or 0

		local gold = math.floor(goldAmountValue)
		local silver = math.floor((goldAmountValue - gold) * 100)

		if gold then
			goldAmountValue = tonumber(gold) or 0
		end
		if silver then
			silverAmountValue = tonumber(silver) or 0
		end

		if goldAmountValue > 0 or silverAmountValue > 0 then
			local goldCoinTexture = foundFrame:CreateTexture(nil, "OVERLAY")
			goldCoinTexture:SetTexture("Interface/MoneyFrame/UI-GoldIcon")
			goldCoinTexture:SetSize(iconSize, iconSize)
			goldCoinTexture:SetPoint("LEFT", foundFrame.locName, "RIGHT", iconSpacing, 0)

			local goldText = foundFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
			goldText:SetScale(0.8)
			goldText:SetPoint("LEFT", goldCoinTexture, "RIGHT", iconSpacing, 0)
			goldText:SetText(tostring(goldAmountValue))

			if silverAmountValue > 0 then
				local silverCoinTexture = foundFrame:CreateTexture(nil, "OVERLAY")
				silverCoinTexture:SetTexture("Interface/MoneyFrame/UI-SilverIcon")
				silverCoinTexture:SetSize(iconSize, iconSize)
				silverCoinTexture:SetPoint("LEFT", goldText, "RIGHT", iconSpacing, 0)

				local silverText = foundFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
				silverText:SetScale(0.8)
				silverText:SetPoint("LEFT", silverCoinTexture, "RIGHT", iconSpacing, 0)
				silverText:SetText(tostring("|cFFE8E8E8" .. silverAmountValue))
			end
		end
	end

	table.insert(travelFrames, 1, foundFrame)

	updateTravelFramesPosition()

	updateTravelCategorySearchFrameChildHeight()
end

local function addToServices(shortMsg, msg, author, timePosted, service, serviceColor, classColor)
	local frameWidth = categorySearchFrameChildServices:GetWidth() - 15
	local frameHeight = 35

	local foundFrame = CreateFrame(
		"Frame",
		"NoxxLFGTravelSearchFrame" .. #servicesFrames + 1,
		categorySearchFrameChildServices,
		"BackdropTemplate"
	)
	foundFrame:SetSize(frameWidth, frameHeight)
	foundFrame:SetFrameStrata("HIGH")

	foundFrame.author = "|c" .. classColor .. author .. "|r"
	foundFrame.timePosted = timePosted

	local foundFrameInteractions = CreateFrame("Frame", nil, foundFrame)
	foundFrameInteractions:SetSize(frameWidth, frameHeight)
	foundFrameInteractions:SetPoint("TOPLEFT", foundFrame, "TOPLEFT", 0, 0)
	foundFrameInteractions:SetPoint("BOTTOMRIGHT", foundFrame, "BOTTOMRIGHT", 0, 0)

	foundFrame:SetBackdrop({
		bgFile = "interface/garrison/classhallinternalbackground",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true,
		tileSize = 128,
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	foundFrame:SetBackdropBorderColor(123 / 255, 224 / 255, 140 / 255)

	foundFrame.title = foundFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	foundFrame.title:SetScale(0.8)
	foundFrame.title:SetPoint("CENTER", foundFrame, "CENTER", 0, 0)
	foundFrame.title:SetText(shortMsg)

	foundFrameInteractions:SetScript("OnEnter", function()
		foundFrame:SetBackdropBorderColor(190 / 255, 245 / 255, 200 / 255)
		GameTooltip:SetOwner(foundFrameInteractions, "ANCHOR_BOTTOM", 0, -5)
		if #msg > shortMessageLength then
			GameTooltip:SetText("|cFFFFFFFF" .. msg, nil, nil, nil, nil, true)
		end
		GameTooltip:SetScale(0.8)
		GameTooltip:Show()
	end)

	foundFrameInteractions:SetScript("OnLeave", function()
		GameTooltip:Hide()
		GameTooltip:SetScale(1)
		foundFrame:SetBackdropBorderColor(123 / 255, 224 / 255, 140 / 255)
	end)

	foundFrameInteractions:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			PlaySound(808)
			ChatFrame_OpenChat("/w " .. author .. " ")
		elseif button == "RightButton" and IsShiftKeyDown() then
			SendChatMessage("inv", "WHISPER", nil, author)
		end
	end)

	foundFrame.serviceName = foundFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	foundFrame.serviceName:SetScale(0.8)
	foundFrame.serviceName:SetPoint("LEFT", foundFrame, "LEFT", 15, 0)
	foundFrame.serviceName:SetText("|c" .. serviceColor .. service .. "|r")

	foundFrame.postAuthor = foundFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	foundFrame.postAuthor:SetScale(0.8)
	foundFrame.postAuthor:SetPoint("RIGHT", foundFrame, "RIGHT", -15, 0)
	foundFrame.postAuthor:SetText("|c" .. classColor .. author .. "|r (" .. formatTimeDifference(timePosted) .. ")")

	table.insert(servicesFrames, 1, foundFrame)

	updateServicesFramesPosition()

	updateServicesCategorySearchFrameChildHeight()
end

local function addToEvents(shortMsg, msg, author, timePosted, event, eventSubName, eventColor, classColor)
	local frameWidth = categorySearchFrameChildEvents:GetWidth() - 15
	local frameHeight = 35

	local foundFrame = CreateFrame(
		"Frame",
		"NoxxLFGEventSearchFrame" .. #eventsFrames + 1,
		categorySearchFrameChildEvents,
		"BackdropTemplate"
	)
	foundFrame:SetSize(frameWidth, frameHeight)
	foundFrame:SetFrameStrata("HIGH")

	foundFrame.author = "|c" .. classColor .. author .. "|r"
	foundFrame.timePosted = timePosted

	local foundFrameInteractions = CreateFrame("Frame", nil, foundFrame)
	foundFrameInteractions:SetSize(frameWidth, frameHeight)
	foundFrameInteractions:SetPoint("TOPLEFT", foundFrame, "TOPLEFT", 0, 0)
	foundFrameInteractions:SetPoint("BOTTOMRIGHT", foundFrame, "BOTTOMRIGHT", 0, 0)

	foundFrame:SetBackdrop({
		bgFile = "interface/garrison/garrisonuibackground2",
		edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
		tile = true,
		tileSize = 128,
		edgeSize = 16,
		insets = { left = 4, right = 4, top = 4, bottom = 4 },
	})
	foundFrame:SetBackdropBorderColor(93 / 255, 142 / 255, 163 / 255)

	foundFrame.title = foundFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	foundFrame.title:SetScale(0.8)
	foundFrame.title:SetPoint("CENTER", foundFrame, "CENTER", 0, 0)
	foundFrame.title:SetText(shortMsg)

	foundFrameInteractions:SetScript("OnEnter", function()
		foundFrame:SetBackdropBorderColor(128 / 255, 185 / 255, 210 / 255)
		GameTooltip:SetOwner(foundFrameInteractions, "ANCHOR_BOTTOM", 0, -5)
		if #msg > shortMessageLength then
			GameTooltip:SetText("|cFFFFFFFF" .. msg, nil, nil, nil, nil, true)
		end
		GameTooltip:SetScale(0.8)
		GameTooltip:Show()
	end)

	foundFrameInteractions:SetScript("OnLeave", function()
		GameTooltip:Hide()
		GameTooltip:SetScale(1)
		foundFrame:SetBackdropBorderColor(93 / 255, 142 / 255, 163 / 255)
	end)

	foundFrameInteractions:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			PlaySound(808)
			ChatFrame_OpenChat("/w " .. author .. " ")
		elseif button == "RightButton" and IsShiftKeyDown() then
			SendChatMessage("inv", "WHISPER", nil, author)
		end
	end)

	foundFrame.eventName = foundFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	foundFrame.eventName:SetScale(0.8)
	foundFrame.eventName:SetPoint("LEFT", foundFrame, "LEFT", 15, 0)
	foundFrame.eventName:SetText(
		"|c" .. eventColor .. event .. (eventSubName ~= "None" and ": |cFFFFFFFF" .. eventSubName or "|r")
	)

	foundFrame.postAuthor = foundFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	foundFrame.postAuthor:SetScale(0.8)
	foundFrame.postAuthor:SetPoint("RIGHT", foundFrame, "RIGHT", -15, 0)
	foundFrame.postAuthor:SetText("|c" .. classColor .. author .. "|r (" .. formatTimeDifference(timePosted) .. ")")

	table.insert(eventsFrames, 1, foundFrame)

	updateEventsFramesPosition()

	updateEventsCategorySearchFrameChildHeight()
end

local chatListener = CreateFrame("Frame")

local function stripCurlyBracesContent(msg)
	local strippedMsg = msg:gsub("%b{}", "")
	return strippedMsg
end

local function trimMessage(msg, maxLength)
	maxLength = maxLength or shortMessageLength
	if #msg > maxLength then
		return msg:sub(1, maxLength) .. "..."
	else
		return msg
	end
end

local function eventHandler(self, event, ...)
	local msg, author, language, channelString, target, flags, _, channelNumber, channelName, _, counter, guid = ...

	local needPhrases = { "LFM", "Looking for", "LF", "Need" }
	local rolesTable = {
		{
			name = "Healer",
			aliases = { "Heals", "Healer", "Heal" },
		},
		{
			name = "Tank",
			aliases = { "Tank", "Tanks", "OT ", "MT " },
		},
		{
			name = "DPS",
			aliases = { "Damage", "DPS", "Deeps", "Pumper" },
		},
	}

	if guid and msg and author and channelName then
		local localizedClass, englishClass, localizedRace, englishRace, sex, name, realm = GetPlayerInfoByGUID(guid)
		local _, faction = UnitFactionGroup("player")

		if type(author) == "string" then
			author = Ambiguate(author, "none")
		end

		local strippedMsg = stripCurlyBracesContent(msg)
		local trimmedMsg = trimMessage(strippedMsg, shortMessageLength)
		local timePosted = time()

		local function messageContainsDungeon(msg, dungeons, ignoreGroups)
			local msgLower = msg:lower()
			local spamDungeon = false

			local needsTable = {}

			for _, ignorePhrase in ipairs(ignoreGroups) do
				if msgLower:find(ignorePhrase:lower()) then
					return false, nil
				end
			end

			local goldPattern = "(%d+[%.,/%d]*%d*)%s*[gG]"
			if msgLower:match(goldPattern) then
				return false, nil
			end

			if msgLower:find(("SPAM"):lower()) then
				spamDungeon = true
			end

			for _, dungeon in ipairs(dungeons) do
				local foundDungeon = false

				for _, alias in ipairs(dungeon.aliases) do
					local aliasLower = alias:lower()

					local startPos, endPos = msgLower:find("%f[%a]" .. aliasLower .. "%f[%A]")
					if startPos and endPos then
						foundDungeon = true
						break
					end
				end

				needsTable = {}

				for _, needphrase in ipairs(needPhrases) do
					local startIndex, endIndex = msgLower:find(needphrase:lower())
					if startIndex then
						local messageAfterNeedPhrase = msgLower:sub(endIndex + 1)

						for _, roleneeded in ipairs(rolesTable) do
							local roleAlreadyAdded = false
							for _, alias in ipairs(roleneeded.aliases) do
								if messageAfterNeedPhrase:find(alias:lower()) then
									for _, existingRole in ipairs(needsTable) do
										if existingRole == roleneeded.name then
											roleAlreadyAdded = true
											break
										end
									end

									if not roleAlreadyAdded then
										table.insert(needsTable, roleneeded.name)
									end
								end
								if roleAlreadyAdded then
									break
								end
							end
						end

						if (messageAfterNeedPhrase):lower():find("all ") then
							for _, roleneeded in ipairs(rolesTable) do
								local roleAlreadyAdded = false
								for _, existingRole in ipairs(needsTable) do
									if existingRole == roleneeded.name then
										roleAlreadyAdded = true
										break
									end
								end
								if not roleAlreadyAdded then
									table.insert(needsTable, roleneeded.name)
								end
							end
						end
					end
				end

				if foundDungeon then
					if dungeon.subDungeon then
						for subName, subDetails in pairs(dungeon.subDungeon) do
							for _, subAlias in ipairs(subDetails.aliases) do
								local aliasLower = subAlias:lower()

								local startPos, endPos = msgLower:find("%f[%a]" .. aliasLower .. "%f[%A]")
								if startPos and endPos then
									return true, dungeon.name, subName, dungeon.color, spamDungeon, needsTable
								end
							end
						end
					end

					return true, dungeon.name, nil, dungeon.color, spamDungeon, needsTable
				end
			end

			return false, nil, nil, nil, nil
		end

		local function messageContainsRaid(msg, raids, ignoreGroups)
			local msgLower = msg:lower()

			for _, ignorePhrase in ipairs(ignoreGroups) do
				if msgLower:find(ignorePhrase:lower()) then
					return false, nil
				end
			end

			local needsTable = {}

			for _, needphrase in ipairs(needPhrases) do
				local startIndex, endIndex = msgLower:find(needphrase:lower())
				if startIndex then
					local messageAfterNeedPhrase = msgLower:sub(endIndex + 1)

					for _, roleneeded in ipairs(rolesTable) do
						local roleAlreadyAdded = false
						for _, alias in ipairs(roleneeded.aliases) do
							if messageAfterNeedPhrase:find(alias:lower()) then
								for _, existingRole in ipairs(needsTable) do
									if existingRole == roleneeded.name then
										roleAlreadyAdded = true
										break
									end
								end

								if not roleAlreadyAdded then
									table.insert(needsTable, roleneeded.name)
								end
							end
							if roleAlreadyAdded then
								break
							end
						end
					end

					if (messageAfterNeedPhrase):lower():find("all ") then
						for _, roleneeded in ipairs(rolesTable) do
							local roleAlreadyAdded = false
							for _, existingRole in ipairs(needsTable) do
								if existingRole == roleneeded.name then
									roleAlreadyAdded = true
									break
								end
							end
							if not roleAlreadyAdded then
								table.insert(needsTable, roleneeded.name)
							end
						end
					end
				end
			end

			for _, raid in ipairs(raids) do
				for _, alias in ipairs(raid.aliases) do
					local aliasLower = alias:lower()

					local startPos, endPos = msgLower:find("%f[%a]" .. aliasLower .. "%f[%A]")
					if startPos and endPos then
						return true, raid.name, raid.color, needsTable
					end
				end
			end

			return false, nil, nil
		end

		local function messageContainsTravel(msg, locations, ignoreGroups)
			local msgLower = msg:lower()

			for _, ignorePhrase in ipairs(ignoreGroups) do
				if msgLower:find(ignorePhrase:lower()) then
					return false, nil, nil
				end
			end

			local function extractAndFormatAsDecimal(input, pattern, isGold)
				local amount = input:match(pattern)
				if amount then
					local normalizedAmount = amount:gsub(",", "."):gsub("[^%d.]", "")
					local number = tonumber(normalizedAmount)
					if number then
						if isGold then
							return string.format("%.2f", number)
						else
							return string.format("%.2f", number / 100)
						end
					end
				end
			end

			if
				msgLower:find("summon")
				or msgLower:find("port")
				or msgLower:find("ports")
				or msgLower:find("portal")
			then
				for _, location in ipairs(locations) do
					for _, alias in ipairs(location.aliases) do
						local aliasLower = alias:lower()

						local startPos, endPos = msgLower:find("%f[%a]" .. aliasLower .. "%f[%A]")
						if startPos and endPos then
							local goldPattern = "(%d+[%.,/%d]*%d*)%s*[gG]"
							local silverPattern = "(%d*%.?%d+)%s*[sS]"

							local goldAmount = extractAndFormatAsDecimal(msgLower, goldPattern, true)
							local silverAmount = extractAndFormatAsDecimal(msgLower, silverPattern, false)

							if goldAmount or silverAmount then
								return true, location.name, location.color, goldAmount or silverAmount
							else
								return true, location.name, location.color, nil
							end
						end
					end
				end
			end

			return false, nil, nil
		end

		local function messageContainsService(msg, services, ignoreGroups)
			local msgLower = msg:lower()

			for _, ignorePhrase in ipairs(ignoreGroups) do
				if msgLower:find(ignorePhrase:lower()) then
					return false, nil, nil
				end
			end

			for _, service in ipairs(services) do
				for _, alias in ipairs(service.aliases) do
					local aliasLower = alias:lower()

					local startPos, endPos = msgLower:find("%f[%a]" .. aliasLower .. "%f[%A]")
					if startPos and endPos then
						return true, service.name, service.color, nil
					end
				end
			end

			return false, nil, nil
		end

		local function messageContainsEvent(msg, events, ignoreGroups)
			local msgLower = msg:lower()
			local eventHasBeenFound = false

			for _, ignorePhrase in ipairs(ignoreGroups) do
				if msgLower:find(ignorePhrase:lower()) then
					return false, nil, nil
				end
			end

			for _, foundEvent in ipairs(events) do
				for _, alias in ipairs(foundEvent.aliases) do
					local aliasLower = alias:lower()

					local startPos, endPos = msgLower:find("%f[%a]" .. aliasLower .. "%f[%A]")
					if startPos and endPos then
						for i, phrase in ipairs(lfEventPhrases) do
							if msgLower:find(phrase:lower()) then
								eventHasBeenFound = true
							end
						end
					end
				end

				if eventHasBeenFound then
					if foundEvent.subEvent then
						for subName, subDetails in pairs(foundEvent.subEvent) do
							for _, subAlias in ipairs(subDetails.aliases) do
								local aliasLower = subAlias:lower()

								local startPos, endPos = msgLower:find("%f[%a]" .. aliasLower .. "%f[%A]")
								if startPos and endPos then
									return true, foundEvent.name, subName, foundEvent.color
								end
							end
						end
					end

					return true, foundEvent.name, nil, foundEvent.color
				end
			end

			return false, nil, nil
		end

		local found, dungeonName, subDungeonName, dungeonColor, spamDungeon, rolesNeeded =
			messageContainsDungeon(msg, dungeons, ignoreGroups)
		local raidFound, raidName, raidColor, raidRolesNeeded = messageContainsRaid(msg, raids, ignoreGroups)
		local summonFound, locationName, locationColor, goldAmount =
			messageContainsTravel(msg, summons, ignoreSummoningGroups)
		local serviceFound, serviceName, serviceColor = messageContainsService(msg, services, ignoreServicesGroups)
		local eventFound, eventName, eventSubName, eventColor =
			messageContainsEvent(msg, worldEvents, ignoreEventsGroups)

		local function splitString(str, delimiter)
			local result = {}
			local from = 1
			local delim_from, delim_to = string.find(str, delimiter, from)
			while delim_from do
				local substring = string.sub(str, from, delim_from - 1)
				local trimmedString = string.gsub(substring, "^%s*(.-)%s*$", "%1")
				table.insert(result, trimmedString)
				from = delim_to + 1
				delim_from, delim_to = string.find(str, delimiter, from)
			end
			local finalSubstring = string.sub(str, from)
			local finalTrimmedString = string.gsub(finalSubstring, "^%s*(.-)%s*$", "%1")
			table.insert(result, finalTrimmedString)
			return result
		end

		local function isSupportedChannel(channelName)
			if NoxxLFGSettings["supportedChannels"] == nil then
				NoxxLFGSettings["supportedChannels"] = "General, Trade, LookingForGroup, LFG, World"
			end

			local trimmedChannels = NoxxLFGSettings["supportedChannels"]:match("^%s*(.-)%s*$")

			if trimmedChannels == "" then
				return false
			end

			local lowerChannelName = string.lower(channelName)

			local supportedKeywords = splitString(NoxxLFGSettings["supportedChannels"], ",")

			--TODO Get Yell and Say to also work at all times, in addition to the supportedChannels setting
			for _, keyword in ipairs(supportedKeywords) do
				local lowerKeyword = string.lower(keyword)

				if
					string.find(lowerChannelName, lowerKeyword)
					or lowerChannelName == "yell"
					or lowerChannelName == "say"
				then
					return true
				end
			end

			return false
		end

		if found then
			if isSupportedChannel(channelName) then
				if not NoxxLFGSettings.pausedSearching then
					for i = #NoxxLFGListings.dungeonGroups, 1, -1 do
						if NoxxLFGListings.dungeonGroups[i].author == author then
							if dungeonFrames[i] then
								dungeonFrames[i]:Hide()
							end
							table.remove(NoxxLFGListings.dungeonGroups, i)
							table.remove(dungeonFrames, i)
							updateDungeonFramesPosition()
						end
					end
				end

				local dungeon = getDungeonByName(dungeonName)
				if not NoxxLFGSettings.pausedSearching then
					if
						((mainFrame:IsShown() or settingsFrame:IsShown()) and NoxxLFGSettings.enableUpdateInUse)
						or not NoxxLFGSettings.enableUpdateInUse
					then
						if dungeon and dungeon.checked then
							table.insert(NoxxLFGListings.dungeonGroups, 1, {
								message = trimmedMsg,
								longMessage = strippedMsg,
								author = author,
								timePosted = timePosted,
								dungeonName = dungeonName,
								subDungeonName = subDungeonName or "None",
								dungeonColor = dungeonColor,
								spamDungeon = spamDungeon,
								classColor = classColor[englishClass],
								rolesNeeded = rolesNeeded,
								playerFaction = faction,
							})
							if (spamDungeon and NoxxLFGSettings.enableSpamGroups) or not spamDungeon then
								addToDungeons(
									trimmedMsg,
									strippedMsg,
									author,
									timePosted,
									dungeonName,
									subDungeonName or "None",
									dungeonColor,
									spamDungeon,
									classColor[englishClass],
									rolesNeeded
								)
							end
						end
					end
				end
			end
		end

		if raidFound then
			if isSupportedChannel(channelName) then
				if not NoxxLFGSettings.pausedSearching then
					for i = #NoxxLFGListings.raidGroups, 1, -1 do
						if NoxxLFGListings.raidGroups[i].author == author then
							if raidFoundFrames[i] then
								raidFoundFrames[i]:Hide()
							end
							table.remove(NoxxLFGListings.raidGroups, i)
							table.remove(raidFoundFrames, i)
							updateRaidFramesPosition()
						end
					end
				end

				local raid = getRaidByName(raidName)
				if not NoxxLFGSettings.pausedSearching then
					if
						((mainFrame:IsShown() or settingsFrame:IsShown()) and NoxxLFGSettings.enableUpdateInUse)
						or not NoxxLFGSettings.enableUpdateInUse
					then
						if raid and raid.checked then
							table.insert(NoxxLFGListings.raidGroups, 1, {
								message = trimmedMsg,
								longMessage = strippedMsg,
								author = author,
								timePosted = timePosted,
								raidName = raidName,
								raidColor = raidColor,
								classColor = classColor[englishClass],
								raidRolesNeeded = raidRolesNeeded,
								playerFaction = faction,
							})
							addToRaids(
								trimmedMsg,
								strippedMsg,
								author,
								timePosted,
								raidName,
								raidColor,
								classColor[englishClass],
								raidRolesNeeded
							)
						end
					end
				end
			end
		end

		if summonFound then
			if isSupportedChannel(channelName) then
				if not NoxxLFGSettings.pausedSearching then
					for i = #travelGroups, 1, -1 do
						if travelGroups[i].author == author then
							if travelFrames[i] then
								travelFrames[i]:Hide()
							end
							table.remove(travelGroups, i)
							table.remove(travelFrames, i)
							updateTravelFramesPosition()
						end
					end
				end

				if not NoxxLFGSettings.pausedSearching then
					if
						((mainFrame:IsShown() or settingsFrame:IsShown()) and NoxxLFGSettings.enableUpdateInUse)
						or not NoxxLFGSettings.enableUpdateInUse
					then
						table.insert(travelGroups, 1, {
							message = trimmedMsg,
							longMessage = strippedMsg,
							author = author,
							timePosted = timePosted,
							locationName = locationName,
						})
						addToTravel(
							trimmedMsg,
							strippedMsg,
							author,
							timePosted,
							locationName,
							locationColor,
							classColor[englishClass],
							goldAmount
						)
					end
				end
			end
		end

		if serviceFound then
			if isSupportedChannel(channelName) then
				if not NoxxLFGSettings.pausedSearching then
					for i = #servicesGroups, 1, -1 do
						if servicesGroups[i].author == author then
							if servicesFrames[i] then
								servicesFrames[i]:Hide()
							end
							table.remove(servicesGroups, i)
							table.remove(servicesFrames, i)
							updateServicesFramesPosition()
						end
					end
				end

				if not NoxxLFGSettings.pausedSearching then
					if
						((mainFrame:IsShown() or settingsFrame:IsShown()) and NoxxLFGSettings.enableUpdateInUse)
						or not NoxxLFGSettings.enableUpdateInUse
					then
						table.insert(servicesGroups, 1, {
							message = trimmedMsg,
							longMessage = strippedMsg,
							author = author,
							timePosted = timePosted,
							serviceName = serviceName,
						})
						addToServices(
							trimmedMsg,
							strippedMsg,
							author,
							timePosted,
							serviceName,
							serviceColor,
							classColor[englishClass]
						)
					end
				end
			end
		end

		if eventFound then
			if isSupportedChannel(channelName) then
				if not NoxxLFGSettings.pausedSearching then
					for i = #eventsGroups, 1, -1 do
						if eventsGroups[i].author == author then
							if eventsFrames[i] then
								eventsFrames[i]:Hide()
							end
							table.remove(eventsGroups, i)
							table.remove(eventsFrames, i)
							updateEventsFramesPosition()
						end
					end
				end

				if not NoxxLFGSettings.pausedSearching then
					if
						((mainFrame:IsShown() or settingsFrame:IsShown()) and NoxxLFGSettings.enableUpdateInUse)
						or not NoxxLFGSettings.enableUpdateInUse
					then
						table.insert(eventsGroups, 1, {
							message = trimmedMsg,
							longMessage = strippedMsg,
							author = author,
							timePosted = timePosted,
							eventName = eventName,
							eventSubName = eventSubName or "None",
							eventColor = eventColor,
							classColor = classColor[englishClass],
						})
						addToEvents(
							trimmedMsg,
							strippedMsg,
							author,
							timePosted,
							eventName,
							eventSubName or "None",
							eventColor,
							classColor[englishClass]
						)
					end
				end
			end
		end
	end
end

function NoxxLFG:OpenNoxxLFG()
	mainFrame:Show()
	PlaySound(808)
end

SLASH_NOXXLFG1 = "/noxxlfg"
SLASH_NOXXLFG2 = "/nlfg"
SlashCmdList["NOXXLFG"] = function()
	mainFrame:Show()
	PlaySound(808)
end

table.insert(UISpecialFrames, "NoxxLFGMainFrame")

SLASH_NLFGDEBUG1 = "/nlfgdebug"
SlashCmdList["NLFGDEBUG"] = function()
	if NoxxLFGSettings.nlfgdebugmode then
		NoxxLFGSettings.nlfgdebugmode = false
		print(NoxxLFGBlueColor .. addonName .. ":|r Debug mode has been |cFFFFFF00disabled|r.")
	else
		NoxxLFGSettings.nlfgdebugmode = true
		print(NoxxLFGBlueColor .. addonName .. ":|r Debug mode has been |cFFFFFF00enabled|r.")
	end
end

SLASH_NLFGDEBUGSTATUS1 = "/nlfgdebugstatus"
SlashCmdList["NLFGDEBUGSTATUS"] = function()
	print(
		NoxxLFGBlueColor
			.. addonName
			.. ":|r Debug mode is "
			.. (NoxxLFGSettings.nlfgdebugmode and "|cFFFFFF00enabled|r" or "|cFFFFFF00disabled|r")
			.. "."
	)
end

categorySearchBackButton:SetScript("OnClick", function()
	categoryFrame:Show()
	lfmlfgButtonGroup:Show()
	categorySearchFrameDungeons:Hide()
	categorySearchFrameRaids:Hide()
	categorySearchFrameTravel:Hide()
	categorySearchFrameServices:Hide()
	categorySearchFrameEvents:Hide()
	categorySearchBackButton:Hide()
	dungeonFilterDropdown:Hide()
	raidFilterDropdown:Hide()
	topHintText:Hide()
	sideWindow:Hide()
	pausePlayButton:Hide()
	topHintText:SetText(NoxxLFGBlueColor .. "Left-click:|cFFFFFFFF Start Whisper|r")
	mainFrame.title:SetText(
		"|TInterface/AddOns/NoxxLFG/images/icon:20:20|t " .. NoxxLFGBlueColor .. addonName .. " v" .. versionNum .. "|r"
	)
	PlaySound(808)
end)

local function OnEvent(self, event, arg1)
	if event == "PLAYER_LOGIN" then
		CreateSettingsUI(settingsFrame)
		CheckIfPaused()

		if NoxxLFGSettings.nlfgdebugmode then
			print(NoxxLFGBlueColor .. addonName .. ":|r You are currently running NoxxLFG in debug mode!")
		end

		local lfmChannelIndex, lfmChannelName = GetChannelName(NoxxLFGSettings.lfmChannel)
		local lfgChannelIndex, lfgChannelName = GetChannelName(NoxxLFGSettings.lfgChannel)

		lfmChannelName = lfmChannelIndex and lfmChannelName or "LookingForGroup"
		lfgChannelName = lfgChannelIndex and lfgChannelName or "LookingForGroup"

		if lfmChannelIndex and lfmChannelIndex > 0 then
			lfmCreationFrameHint:SetText(
				"Use this tool to construct a message and post to |cFFFFFFFF"
					.. lfmChannelName
					.. "|r. When a member joins your party, you will be able to select their role to dynamically update your message and continue to post the message every 30 seconds when the reminder pops up."
			)
		else
			lfmCreationFrameHint:SetText(
				"|cFFFF0000The channel you have set for this function is invalid! Please set a valid channel in the settings or join the channel you've set!"
			)
		end

		if lfgChannelIndex and lfgChannelIndex > 0 then
			lfgCreationFrameHint:SetText(
				"Use this tool to construct a message and post to |cFFFFFFFF"
					.. lfgChannelName
					.. "|r. If posting as repeat, once you join a party, the repeated reminders to post your LFG message will cease."
			)
		else
			lfgCreationFrameHint:SetText(
				"|cFFFF0000The channel you have set for this function is invalid! Please set a valid channel in the settings or join the channel you've set!"
			)
		end

		local _, currentFaction = UnitFactionGroup("player")

		if NoxxLFGListings.dungeonGroups then
			for i = #NoxxLFGListings.dungeonGroups, 1, -1 do
				local listing = NoxxLFGListings.dungeonGroups[i]
				if listing.playerFaction == currentFaction then
					addToDungeons(
						listing.message,
						listing.longMessage,
						listing.author,
						listing.timePosted,
						listing.dungeonName,
						listing.subDungeonName or "None",
						listing.dungeonColor,
						listing.spamDungeon,
						listing.classColor,
						listing.rolesNeeded
					)
				end
			end
		end

		if NoxxLFGListings.raidGroups then
			for j = #NoxxLFGListings.raidGroups, 1, -1 do
				local listing = NoxxLFGListings.raidGroups[j]
				if listing.playerFaction == currentFaction then
					addToRaids(
						listing.message,
						listing.longMessage,
						listing.author,
						listing.timePosted,
						listing.raidName,
						listing.raidColor,
						listing.classColor,
						listing.raidRolesNeeded
					)
				end
			end
		end

		if NoxxLFGSettings.clientScale then
			local clientScalePercent = strsplit("%", NoxxLFGSettings.clientScale) / 100
			mainFrame:SetScale(clientScalePercent)
			settingsFrame:SetScale(clientScalePercent)
		end
	elseif event == "PLAYER_REGEN_ENABLED" then
		if triedToShowPopup then
			if triedToShowPlayerNames then
				for _, playerWaiting in ipairs(triedToShowPlayerNames) do
					if postingMessage then
						NoxxLFG:CheckAndShowRolePopup(
							playerWaiting,
							tankTextBox:GetText(),
							healerTextBox:GetText(),
							dpsTextBox:GetText(),
							startedWithRoles,
							totalRoles
						)
					end
				end
			end
			triedToShowPopup = false
			triedToShowPlayerNames = {}
		end
	end
end

chatListener:RegisterEvent("CHAT_MSG_CHANNEL")
chatListener:RegisterEvent("CHAT_MSG_YELL")
chatListener:RegisterEvent("CHAT_MSG_SAY")
chatListener:SetScript("OnEvent", eventHandler)

local loginFrame = CreateFrame("Frame")
loginFrame:RegisterEvent("PLAYER_LOGIN")
loginFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
loginFrame:SetScript("OnEvent", OnEvent)

local movementFrame = CreateFrame("Frame")
movementFrame:RegisterEvent("PLAYER_STARTED_MOVING")
movementFrame:RegisterEvent("PLAYER_STOPPED_MOVING")
movementFrame:SetScript("OnEvent", function(self, event)
	local percent = strsplit("%", NoxxLFGSettings.windowOpacityWhileMoving) / 100

	if event == "PLAYER_STARTED_MOVING" then
		if mainFrame and NoxxLFGSettings and NoxxLFGSettings.windowOpacityWhileMoving then
			mainFrame:SetAlpha(percent)
		end
	elseif event == "PLAYER_STOPPED_MOVING" then
		if mainFrame then
			mainFrame:SetAlpha(1)
		end
	end
end)

function ToggleNoxxLFGWindowBind(openDungeons)
	if openDungeons then
		openDungeons = true
	end

	PlaySound(808)
	if not mainFrame:IsShown() then
		mainFrame:Show()
		if openDungeons then
			categoryFrame:Hide()
			lfmlfgButtonGroup:Hide()
			lfmCreationFrame:Hide()
			categorySearchFrameDungeons:Show()
			categorySearchFrameChildDungeons:Show()
			mainFrame.title:SetText(
				"|TInterface/AddOns/NoxxLFG/images/icon:20:20|t "
					.. NoxxLFGBlueColor
					.. addonName
					.. " v"
					.. versionNum
					.. "|r (Searching for Dungeons)"
			)
		end
	else
		mainFrame:Hide()
	end
end

local addon = LibStub("AceAddon-3.0"):NewAddon("NoxxLFG")

local miniButton = LibStub("LibDataBroker-1.1"):NewDataObject("NoxxLFG", {
	type = "data source",
	text = "NoxxLFG",
	icon = "Interface\\AddOns\\NoxxLFG\\images\\minimap.tga",
	OnClick = function(self, btn)
		if not mainFrame:IsShown() then
			mainFrame:Show()
		else
			mainFrame:Hide()
		end
	end,

	OnTooltipShow = function(tooltip)
		if not tooltip or not tooltip.AddLine then
			return
		end

		tooltip:AddLine(NoxxLFGBlueColor .. addonName .. "\n\nLeft-click: |rOpen " .. addonName, nil, nil, nil, nil)
	end,
})

NoxxMinimapIcon = LibStub("LibDBIcon-1.0", true)

---@diagnostic disable-next-line: duplicate-set-field
function addon:OnInitialize()
	---@diagnostic disable-next-line: inject-field
	self.db = LibStub("AceDB-3.0"):New("NoxxMinimapPosDB", {
		profile = {
			minimap = {
				hide = false,
			},
		},
	})

	---@diagnostic disable-next-line: param-type-mismatch
	NoxxMinimapIcon:Register("NoxxLFG", miniButton, self.db.profile.minimap)
end

NoxxMinimapIcon:Show("NoxxLFG")
