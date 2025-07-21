-- Consolidated filtering patterns to reduce local variable count
local filterPatterns = {
	dungeonRaid = {
		patterns = {
			"%f[%w]selling%f[%W]", "%f[%w]WTS%f[%W]", "%f[%w]ninja%f[%W]", "%f[%w]WTB%f[%W]",
			"%f[%w]inv%f[%W]", "%f[%w]DMF%f[%W]", "%f[%w]smooth%f[%W]", "%f[%w]arms%f[%W]",
			"%f[%w]recruit[%w]*", "%f[%w]casual%f[%W]", "%f[%w]service[s]?%f[%W]", "%f[%w]free%f[%W]",
			"%f[%w]tip[s]?%f[%W]", "%f[%w]roster%f[%W]", "%f[%w]LFW%f[%W]", "%?",
			"%f[%w]what%f[%W]", "level%s*%d+", "lvl%s*%d+", "%f[%w]quest[s]?%f[%W]", "<[^>]+>",
		},
		legacy = { "selling", "WTS", "WTB", "inv", "DMF", "smooth", "arms", "recruit", "casual", "service", "free", "tip", "roster", "LFW", "?", "what", "level", "lvl", "quest" }
	},
	travel = {
		patterns = {
			"%f[%w]WTB%f[%W]", "%f[%w]paying%f[%W]", "%f[%w]LF%f[%W]", "%f[%w]Need%f[%W]",
			"%f[%w]Tank%f[%W]", "%f[%w]DPS%f[%W]", "%f[%w]Healer%f[%W]", "|Hitem:",
			"%f[%w]any%f[%W]", "%f[%w]boost[%w]*",
		},
		legacy = { "WTB", "paying", "LF", "Need", "Tank", "DPS", "Healer", "|Hitem:", "any", "boost" }
	},
	services = {
		patterns = {
			"WTS%s+|Hitem:", "LF%s", "%f[%w]Need%f[%W]", "%f[%w]Tank%f[%W]",
			"%f[%w]DPS%f[%W]", "%f[%w]Healer%f[%W]", "%f[%w]WTB%f[%W]",
		},
		legacy = { "WTS |Hitem:", "LF ", "Need", "Tank", "DPS", "Healer", "WTB" }
	},
	events = {
		legacy = { "selling", "WTS", "WTB", "DMF", "smooth", "arms", "recruit", "casual", "service", "free", "tip", "roster", "LFW", "?", "what", "level", "lvl" }
	}
}

-- Enhanced pattern matching function that works with the consolidated structure
local function messageMatchesPattern(msg, category)
	local msgLower = msg:lower()
	local categoryPatterns = filterPatterns[category]
	
	if categoryPatterns and categoryPatterns.patterns then
		for _, pattern in ipairs(categoryPatterns.patterns) do
			if msgLower:match(pattern:lower()) then
				return true, pattern
			end
		end
	end
	return false, nil
end

-- Legacy matching function for compatibility
local function messageMatchesLegacy(msg, category)
	local msgLower = msg:lower()
	local categoryPatterns = filterPatterns[category]
	
	if categoryPatterns and categoryPatterns.legacy then
		for _, phrase in ipairs(categoryPatterns.legacy) do
			if msgLower:find(phrase:lower()) then
				return true, phrase
			end
		end
	end
	return false, nil
end
