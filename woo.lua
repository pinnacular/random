
--[[
	Script todo:
	- make it go inside crate ✅
	- make it alot quicker❓
	- improve serverhopping ✅
	- make the car / getting vehicle speeds alot quicker ✅
	- make the ship a little quicker ✅
	- try to make mansion quicker ✅
	- add cargo plane (maybe) ❎
	- take note of #suggestions (in farmhub) 
	- make it rob stuff after mansion ❎ (removed exiting mansion)
]]

-------------------->> Luraph & Luarmor Macros <<--------------------

if not LPH_OBFUSCATED then
	script_key                  = "mCmIgbiDYBXSQGtBwuMqIdvjOofcXUbW"
	LRM_UserNote                = "Not specified"
	LRM_ScriptName              = "Auto Crate"
	LRM_SecondsLeft             = math.huge
	LRM_IsUserPremium           = true
	LRM_LinkedDiscordID         = "1"
	LRM_TotalExecutions         = 0

	getfenv().LPH_JIT           = function(...) return ... end
	getfenv().LPH_ENCSTR        = function(...) return ... end
	getfenv().LPH_JIT_MAX       = function(...) return ... end
	getfenv().LPH_HOOK_FIX      = function(...) return ... end
	getfenv().LPH_JIT_ULTRA     = function(...) return ... end
	getfenv().LPH_NO_UPVALUES   = function(f) return(function(...) return f(...) end) end
	getfenv().LPH_NO_VIRTUALIZE = function(...) return ... end
end

-------------------->> Load Game <<--------------------

if not game:IsLoaded() then 
	game.Loaded:Wait() 
	task.wait(3) 
end

local GithubLink = 'https://raw.githubusercontent.com/pinnacular/random/main/woo.lua' -- too tired copy pasting same thing

-------------------->> Execution Check <<--------------------

if getgenv().FarmHub then 
	pcall(function()
		require(game:GetService("ReplicatedStorage").Game.Notification).new({
			Text = "FarmHub has already been executed!",
			Duration = 4,
		})
	end)
	return
else
	getgenv().FarmHub = true
end

-------------------->> Directory Functions <<--------------------

local function GetDirectory()
	local Directory = "NIGGAHACK"
	if not isfolder(Directory) then
		makefolder(Directory)
	end
	return Directory
end

local function SaveFile(name, data)
	local success, error = pcall(function()
		writefile(GetDirectory() .. "\\" .. name, data)
	end)
	return success
end

local function LoadFile(name)
	local success, data = pcall(function()
		return readfile(GetDirectory() .. "\\" .. name)
	end)
	return success and data or nil
end

-------------------->> Client Services <<--------------------

local Services = setmetatable({}, {
	__index = function(self, service)
		return game:GetService(service)
	end
})

local Teams                     = Services.Teams
local Players                   = Services.Players
local Lighting                  = Services.Lighting
local Workspace                 = Services.Workspace
local StarterGui                = Services.StarterGui
local RunService                = Services.RunService
local GuiService                = Services.GuiService
local HttpService               = Services.HttpService
local VirtualUser               = Services.VirtualUser
local TweenService              = Services.TweenService
local TeleportService           = Services.TeleportService
local UserInputService          = Services.UserInputService
local CollectionService         = Services.CollectionService
local ReplicatedStorage         = Services.ReplicatedStorage
local PathfindingService        = Services.PathfindingService
local MarketplaceService        = Services.MarketplaceService

-------------------->> Settings Importation <<--------------------

local Settings = {
	IncludeAirdrops             = true,
	IncludeMansion              = true,
	IncludeCargoShip            = true,
	AutoBoostFPS                = true,
	HideInCrate                 = true,
	CollectCash                 = true,
	AutoOpenSafes               = true,
	SmallServer                 = true,
	WebhookURL                  = "",
}

local SettingsFile = LoadFile("AutoCrateSettings.json")

if SettingsFile then
	local Success, Data = pcall(function()
		return game:GetService("HttpService"):JSONDecode(SettingsFile)
	end)

	if Success then
		for i, v in pairs(Data) do
			Settings[i] = v
			print("Updated " .. i .. " to " .. tostring(v))
		end
	end
end

table.foreach(Settings, function(i, v)
	print(i .. ": " .. tostring(v))
end)

-------------------->> Client Player <<--------------------

local Player                    = Players.LocalPlayer
local PlayerGui                 = Player:WaitForChild("PlayerGui")
local Backpack                  = Player:WaitForChild("Folder")
local Leaderstats               = Player:WaitForChild("leaderstats")
local RobberyMoneyGui           = PlayerGui:WaitForChild("RobberyMoneyGui")
local Character                 = nil
local Humanoid                  = nil
local Root                      = nil
local Camera                    = Workspace.CurrentCamera
local BreakFunc                 = function() end
local ExitFunc                  = function() end
local BreakTime                 = 0 
local GetSpawnTime              = nil

local function SetupCharacter(character)
	Character = character
	Humanoid = character:WaitForChild("Humanoid")
	Root = character:WaitForChild("HumanoidRootPart")
end

if Player.Character then
	SetupCharacter(Player.Character)
end

Player.CharacterAdded:Connect(SetupCharacter)

-------------------->> Anticheat Functions <<--------------------

LPH_NO_VIRTUALIZE(function()
	for i, v in pairs(getgc(true)) do
		if typeof(v) == "function" then
			if debug.info(v, "n"):match("CheatCheck") and hookfunction then
				hookfunction(v, function() return "hook" end)
			end
			if getfenv(v).script == Player.PlayerScripts.LocalScript and getconstants then
				local con = getconstants(v)

				if table.find(con, "LastVehicleExit") and table.find(con, "tick") then
					ExitFunc = getupvalue(v, 2)
				end
			end
		elseif type(v) == "table" and type(rawget(v, "getRemainingDebounce")) == "function" then 
			GetSpawnTime = v.getRemainingDebounce
		end
	end
end)()

-------------------->> Client Statisitcs <<--------------------

getgenv().StartingMoney = getgenv().StartingMoney or Leaderstats:WaitForChild("Money").Value
getgenv().StartingTime  = getgenv().StartingTime or tick()

-------------------->> Formatting Stuff <<--------------------

local function FormatCash(number)
	local totalnum = tostring(number):split("")

	if #totalnum == 7 then
		return totalnum[1].."."..totalnum[2].."M"
	elseif #totalnum >= 10 then
		return totalnum[1].."."..totalnum[2].."B"
	elseif #totalnum == 4 and #totalnum[2] == 0 then
		return totalnum[1].."k"
	elseif #totalnum == 4  then
		return totalnum[1].."."..totalnum[2].."k"
	elseif #totalnum == 5  then
		return totalnum[1]..totalnum[2].."."..totalnum[3].."k"
	elseif #totalnum == 6  then
		return totalnum[1]..totalnum[2]..totalnum[3].."k"
	else
		return number
	end
end

local function TickToHM(seconds)
	local minutes = math.floor(seconds / 60)
	seconds = seconds % 60
	local hours = math.floor(minutes / 60)
	minutes = minutes % 60

	return hours .. "h/" .. minutes .. "m"
end

-------------------->> Interface Setup <<--------------------

local function CreateInstance(type, parent, data)
	local CreatedInstance = Instance.new(type)

	for index, value in next, data do
		CreatedInstance[index] = value
	end

	CreatedInstance.Parent = parent
	return CreatedInstance
end

local gethui = gethui or (function() return game:GetService("Players").LocalPlayer.PlayerGui end)
local FarmUI = CreateInstance("ScreenGui", gethui(), {
	Name = "VOIDCLIENT JAILBREAK..."
})

local Holder = CreateInstance("ImageLabel", FarmUI, {
	Name = "Holder",
	Parent = FarmUI,
	BackgroundTransparency = 1.000,
	BorderSizePixel = 0,
	Position = UDim2.new(0.0506075993, 0, 0.655761302, 0),
	Size = UDim2.new(0, 278, 0, 165),
})

local TabFrame = CreateInstance("Frame", Holder, {
	Name = "TabFrame",
	Parent = Holder,
	AnchorPoint = Vector2.new(0.5, 0),
	BackgroundTransparency = 1.000,
	BorderSizePixel = 0,
	Position = UDim2.new(0.5, 0, 0, 0),
	Size = UDim2.new(0, 254, 0, 20),
})

local UIListLayout = CreateInstance("UIListLayout", TabFrame, {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 5),
})

local HomeTab = CreateInstance("ImageButton", TabFrame, {
	Name = "HomeTab",
	Parent = TabFrame,
	AnchorPoint = Vector2.new(0.5, 0),
	BackgroundTransparency = 1.000,
	BorderSizePixel = 0,
	Size = UDim2.new(0, 64, 0, 35),
	Image = "rbxassetid://5743909324",
})

local HomeText = CreateInstance("TextLabel", HomeTab, {
	Name = "HomeText",
	Parent = HomeTab,
	BackgroundTransparency = 1.000,
	BorderSizePixel = 0,
	Position = UDim2.new(0, 0, 2.17982702e-07, 0),
	Size = UDim2.new(1, 0, 0.769999921, 0),
	Font = Enum.Font.SourceSansBold,
	Text = "Home",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 16.000,
})

local OptionsTab = CreateInstance("ImageButton", TabFrame, {
	Name = "OptionsTab",
	Parent = TabFrame,
	BackgroundTransparency = 1.000,
	BorderSizePixel = 0,
	Position = UDim2.new(0.271653533, 0, 0, 0),
	Size = UDim2.new(0, 68, 0, 35),
	Image = "rbxassetid://5743909324",
})

local OptionsText = CreateInstance("TextLabel", OptionsTab, {
	Name = "OptionsText",
	Parent = OptionsTab,
	BackgroundTransparency = 1.000,
	BorderSizePixel = 0,
	Position = UDim2.new(0, 0, 2.17982702e-07, 0),
	Size = UDim2.new(1, 0, 0.769999921, 0),
	Font = Enum.Font.SourceSansBold,
	Text = "Options",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextTransparency = 0.3,
	TextSize = 16.000,
})

local CreditsTab = CreateInstance("ImageButton", TabFrame, {
	Name = "CreditsTab",
	Parent = TabFrame,
	BackgroundTransparency = 1.000,
	BorderSizePixel = 0,
	Position = UDim2.new(0.271653533, 0, 0, 0),
	Size = UDim2.new(0, 68, 0, 35),
	Image = "rbxassetid://5743909324",
})

local CreditsText = CreateInstance("TextLabel", CreditsTab, {
	Name = "CreditsText",
	Parent = CreditsTab,
	BackgroundTransparency = 1.000,
	BorderSizePixel = 0,
	Position = UDim2.new(0, 0, 2.17982702e-07, 0),
	Size = UDim2.new(1, 0, 0.769999921, 0),
	Font = Enum.Font.SourceSansBold,
	Text = "Credits",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextTransparency = 0.3,
	TextSize = 16.000,
})

local MainFrame = CreateInstance("ImageLabel", Holder, {
	Name = "MainFrame",
	Parent = Holder,
	BackgroundTransparency = 1.000,
	BorderSizePixel = 0,
	Position = UDim2.new(0, 0, 0, 20),
	Size = UDim2.new(0, 278, 0, 145),
	Image = "rbxassetid://4928857387",
	ImageColor3 = Color3.fromRGB(175, 255, 88),
})

local Tabs = CreateInstance("Folder", MainFrame, {
	Name = "Tabs",
	Parent = MainFrame,
})

local Home = CreateInstance("Frame", Tabs, {
	Name = "Home",
	Parent = Tabs,
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundTransparency = 1.000,
	BorderSizePixel = 0,
	Size = UDim2.new(1, -25, 1, -20),
	Position = UDim2.new(0.5, 0, 0.5, 0),
})

local Stats = CreateInstance("TextLabel", Home, {
	Name = "Stats",
	Parent = Home,
	AnchorPoint = Vector2.new(0.5, 0),
	BackgroundTransparency = 1.000,
	BorderSizePixel = 0,
	Position = UDim2.new(0.5, 0, 0.2053103, 0),
	Size = UDim2.new(0, 248, 0, 34),
	Font = Enum.Font.SourceSansBold,
	Text = "Time Elapsed: ?h/?m     Money Earned: $???",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 15.000,
})

local Status = CreateInstance("TextLabel", Home, {
	Name = "Status",
	Parent = Home,
	AnchorPoint = Vector2.new(0.5, 0),
	BackgroundColor3 = Color3.fromRGB(33, 48, 17),
	BorderColor3 = Color3.fromRGB(0, 0, 0),
	BorderSizePixel = 0,
	Position = UDim2.new(0.5, 0, 0.476000011, 0),
	Size = UDim2.new(0, 239, 0, 34),
	Font = Enum.Font.SourceSansBold,
	Text = "   Loading..",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 20.000,
	TextXAlignment = Enum.TextXAlignment.Left,
})

local UICorner = CreateInstance("UICorner", Status, {
	CornerRadius = UDim.new(0, 10),
	Parent = Status,
})

local UIStroke = CreateInstance("UIStroke", Status, {
	ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	Color = Color3.fromRGB(175, 254, 88),
	Thickness = 3,
})

local Estimate = CreateInstance("TextLabel", Home, {
	Name = "Estimate",
	Parent = Home,
	AnchorPoint = Vector2.new(0.5, 0),
	BackgroundTransparency = 1.000,
	BorderSizePixel = 0,
	Position = UDim2.new(0.5, 0, 0.741999984, 0),
	Size = UDim2.new(0, 248, 0, 34),
	Font = Enum.Font.SourceSansBold,
	Text = "Estimated Hourly Earnings: $???",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 15.000,
})

local StoresHolder = CreateInstance("Frame", Home, {
	Name = "StoresHolder",
	Parent = Home,
	BackgroundTransparency = 1.000,
	BorderSizePixel = 0,
	Size = UDim2.new(1, 0, 0, 30),
})

local UIListLayout_2 = CreateInstance("UIListLayout", StoresHolder, {
	FillDirection = Enum.FillDirection.Horizontal,
	HorizontalAlignment = Enum.HorizontalAlignment.Center,
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 15),
})

local CrateLbl = CreateInstance("TextLabel", StoresHolder, {
	Name = "Crate",
	Parent = StoresHolder,
	BackgroundTransparency = 1.000,
	BorderSizePixel = 0,
	Size = UDim2.new(0, 38, 0, 30),
	Font = Enum.Font.SourceSansBold,
	Text = "Crate",
	TextColor3 = Color3.fromRGB(255, 50, 50),
	TextSize = 17.000,
})

local ShipLbl = CreateInstance("TextLabel", StoresHolder, {
	Name = "Ship",
	Parent = StoresHolder,
	BackgroundTransparency = 1.000,
	BorderSizePixel = 0,
	Size = UDim2.new(0, 71, 0, 30),
	Font = Enum.Font.SourceSansBold,
	Text = "Cargo Ship",
	TextColor3 = Color3.fromRGB(255, 50, 50),
	TextSize = 17.000,
})

local MansionLbl = CreateInstance("TextLabel", StoresHolder, {
	Name = "Mansion",
	Parent = StoresHolder,
	BackgroundTransparency = 1.000,
	BorderSizePixel = 0,
	Size = UDim2.new(0, 59, 0, 30),
	Font = Enum.Font.SourceSansBold,
	Text = "Mansion",
	TextColor3 = Color3.fromRGB(255, 50, 50),
	TextSize = 17.000,
})

local Options = CreateInstance("ScrollingFrame", Tabs, {
	Name = "Options",
	Parent = Tabs,
	AnchorPoint = Vector2.new(0.5, 0.5),
	BackgroundTransparency = 1.000,
	BorderSizePixel = 0,
	Size = UDim2.new(1, -35, 1, -45),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	Visible = false,
	ScrollBarThickness = 4,
})

local UIListLayout_3 = CreateInstance("UIListLayout", Options, {
	SortOrder = Enum.SortOrder.LayoutOrder,
	Padding = UDim.new(0, 5),
})

local Credits = CreateInstance("Frame", Tabs, {
	Name = "Credits",
	Parent = Tabs,
	AnchorPoint = Vector2.new(0.5, 00.5),
	BackgroundTransparency = 1.000,
	BorderSizePixel = 0,
	Size = UDim2.new(1, -25, 1, -20),
	Position = UDim2.new(0.5, 0, 0.5, 0),
	Visible = false,
})

local UIListLayout_3 = CreateInstance("UIListLayout", Credits, {
	SortOrder = Enum.SortOrder.LayoutOrder,
})

local Fayy = CreateInstance("TextLabel", Credits, {
	Name = "Fayy",
	Parent = Credits,
	BackgroundTransparency = 1.000,
	BorderSizePixel = 0,
	Size = UDim2.new(0, 256, 0, 20),
	Font = Enum.Font.SourceSansBold,
	Text = "f4yyzw0rld#0 - Scripting + Interface",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 16.000,
})

local Tempy = CreateInstance("TextLabel", Credits, {
	Name = "Tempy",
	Parent = Credits,
	BackgroundTransparency = 1.000,
	BorderSizePixel = 0,
	Size = UDim2.new(0, 256, 0, 20),
	Font = Enum.Font.SourceSansBold,
	Text = "itztempy0#0 - Scripting + Debugging",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 16.000,
})

local Veoxn = CreateInstance("TextLabel", Credits, {
	Name = "Veoxn",
	Parent = Credits,
	BackgroundTransparency = 1.000,
	BorderSizePixel = 0,
	Size = UDim2.new(0, 256, 0, 20),
	Font = Enum.Font.SourceSansBold,
	Text = "veoxn#0 - Inspiration + Debugging",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 16.000,
})

local Nonreputable = CreateInstance("TextLabel", Credits, {
	Name = "Nonreputable",
	Parent = Credits,
	BackgroundTransparency = 1.000,
	BorderSizePixel = 0,
	Size = UDim2.new(0, 256, 0, 20),
	Font = Enum.Font.SourceSansBold,
	Text = "nonreputable#0 - Operations Supervisor",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 16.000,
})

local Website = CreateInstance("TextLabel", Credits, {
	Name = "Website",
	Parent = Credits,
	BackgroundTransparency = 1.000,
	BorderSizePixel = 0,
	Size = UDim2.new(0, 256, 0, 20),
	Font = Enum.Font.SourceSansBold,
	Text = "github - open sourced savior",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 16.000,
})

local Discord = CreateInstance("TextLabel", Credits, {
	Name = "Discord",
	Parent = Credits,
	BackgroundTransparency = 1.000,
	BorderSizePixel = 0,
	Size = UDim2.new(0, 256, 0, 20),
	Font = Enum.Font.SourceSansBold,
	Text = "also fixed some stuff - pin",
	TextColor3 = Color3.fromRGB(255, 255, 255),
	TextSize = 16.000,
})

local CloseBtn = CreateInstance("ImageButton", MainFrame, {
	Name = "CloseBtn",
	Parent = MainFrame,
	BackgroundTransparency = 1.000,
	BorderSizePixel = 0,
	Position = UDim2.new(0, -6, 0, -6),
	Size = UDim2.new(0, 28, 0, 28),
	Image = "rbxassetid://4933143781",
})

local function SetHome()
	Home.Visible = true
	Options.Visible = false
	Credits.Visible = false

	HomeText.TextTransparency = 0.000
	OptionsText.TextTransparency = 0.300
	CreditsText.TextTransparency = 0.300
end

local function SetOptions()
	Home.Visible = false
	Options.Visible = true
	Credits.Visible = false

	HomeText.TextTransparency = 0.300
	OptionsText.TextTransparency = 0.000
	CreditsText.TextTransparency = 0.300
end

local function SetCredits()
	Home.Visible = false
	Options.Visible = false
	Credits.Visible = true

	HomeText.TextTransparency = 0.300
	OptionsText.TextTransparency = 0.300
	CreditsText.TextTransparency = 0.000
end

HomeTab.MouseButton1Click:Connect(SetHome)
OptionsTab.MouseButton1Click:Connect(SetOptions)
CreditsTab.MouseButton1Click:Connect(SetCredits)

local function AddSwitch(name, default, callback)
	local Switch = CreateInstance("TextButton", Options, {
		Name = "Switch",
		BackgroundColor3 = Color3.fromRGB(175, 254, 88),
		BackgroundTransparency = 0,
		BorderSizePixel = 0,
		Position = UDim2.new(0.229411766, 0, 0.20714286, 0),
		Size = UDim2.new(0, 20, 0, 20),
		ZIndex = 2,
		Font = Enum.Font.SourceSansBold,
		Text = "",
		TextColor3 = Color3.new(0, 0, 0),
		TextSize = 18,
	})

	local UICorner = CreateInstance("UICorner", Switch, {
		CornerRadius = UDim.new(0, 4),
	})

	local Title = CreateInstance("TextLabel", Switch, {
		Name = "Title",
		BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = 1,
		Position = UDim2.new(1.20000005, 0, 0, 0),
		Size = UDim2.new(0, 20, 0, 20),
		Font = Enum.Font.SourceSansBold,
		Text = "Switch",
		TextColor3 = Color3.new(0.784314, 0.784314, 0.784314),
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	Switch:FindFirstChild("Title").Text = name

	if default then
		Switch.Text = utf8.char(10003)
		pcall(callback, default)
	end


	local Toggled = default
	Switch.MouseButton1Click:Connect(function()
		Toggled = not Toggled
		Switch.Text = Toggled and utf8.char(10003) or ""
		pcall(callback, Toggled)
	end)

end

AddSwitch("Rob Crates", Settings.IncludeAirdrops, function(bool)
	Settings.IncludeAirdrops = bool
	SaveFile("AutoCrateSettings.json", HttpService:JSONEncode(Settings))
end)

AddSwitch("Rob Cargo Ship", Settings.IncludeCargoShip, function(bool)
	Settings.IncludeCargoShip = bool
	SaveFile("AutoCrateSettings.json", HttpService:JSONEncode(Settings))
end)

AddSwitch("Rob Mansion", Settings.IncludeMansion, function(bool)
	Settings.IncludeMansion = bool
	SaveFile("AutoCrateSettings.json", HttpService:JSONEncode(Settings))
end)

AddSwitch("Prefer Small Servers", Settings.SmallServer, function(bool)
	Settings.SmallServer = bool
	SaveFile("AutoCrateSettings.json", HttpService:JSONEncode(Settings))
end)

AddSwitch("Collect Dropped Cash", Settings.CollectCash, function(bool)
	Settings.CollectCash = bool
	SaveFile("AutoCrateSettings.json", HttpService:JSONEncode(Settings))
end)

AddSwitch("Hide In Crate", Settings.HideInCrate, function(bool)
	Settings.HideInCrate = bool
	SaveFile("AutoCrateSettings.json", HttpService:JSONEncode(Settings))
end)

AddSwitch("Auto Open Safes", Settings.AutoOpenSafes, function(bool)
	Settings.AutoOpenSafes = bool
	SaveFile("AutoCrateSettings.json", HttpService:JSONEncode(Settings))
end)

AddSwitch("Auto FPS Boost", Settings.AutoBoostFPS, function(bool)
	Settings.AutoBoostFPS = bool
	SaveFile("AutoCrateSettings.json", HttpService:JSONEncode(Settings))
end)

CloseBtn.MouseButton1Click:Connect(function()
	FarmUI.Enabled = false
end)

local function SetStatus(text)
	task.spawn(function()
		local function FixStat()
			Status.Text = "   " .. text
		end

		while not pcall(FixStat) do
			wait(0.01)
		end
	end)
end

local function SetStats(money, time)
	task.spawn(function()
		local function FixStat()
			Stats.Text = "Time Elapsed: " .. TickToHM(time) .. "     Money Earned: $" .. FormatCash(money)
		end

		while not pcall(FixStat) do
			task.wait(0.01)
		end
	end)
	task.spawn(function()
		local function FixEstim()
			Estimate.Text = "Estimated Hourly Earnings: $" .. FormatCash(math.floor(money / time * 3600))
		end

		while not pcall(FixEstim) do
			task.wait(0.01)
		end
	end)
end

-------------------->> ServerHop <<--------------------

--[[function GetRejoinPrefferedFunction(...)
	local prnt = print
	local pcll = pcall
	local req = (syn or http or {}).request or http_request or request
	local jsondecode = function(a)
		return game:GetService("HttpService"):JSONDecode(a)
	end

	local locale
	local function TimeString()
		return DateTime.now():FormatLocalTime("hh:mm:ss.SSS", locale or "en-us")
	end

	local function TableToString(tbl, delimit, includeNames)
		tbl = tbl or {}
		delimit = delimit or ""
		local txt
		for i, v in (includeNames and pairs or ipairs)(tbl) do
			txt = (txt and (string.gsub(txt, "^%s*(.-)%s*$", "%1") .. delimit) or "")
				.. (includeNames and ("[%s]=%s"):format(tostring(i), tostring(v)) or tostring(v))
		end
		return txt or ""
	end

	local prnt_pref_time
	local function Prnt(...)
		local args = { ... }
		local txt = (prnt_pref_time and (TimeString() .. ": ") or "") .. TableToString(args, " | ")
		prnt(txt:sub(#txt) ~= "\n" and (txt .. "\n") or txt)
	end

	local function GetAllServersForPlace(placeId, pref)
		pref = pref or {}
		local servers = {}
		local cont = true
		local cursor
		local cnt = 0
		local min_p, max_p, min_f, max_png
		local maxPlayers, maxFps, maxPing = 0, 0, 0
		local function numOrDefZero(val)
			return val and type(val) == "number" and val > 0 and val or 0
		end
		min_p = numOrDefZero(pref.MinPlayers)
		max_p = numOrDefZero(pref.MaxPlayers)
		min_f = numOrDefZero(pref.MinFps)
		max_png = numOrDefZero(pref.MaxPing)

		local rbx_games_url_frmt = "https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=Asc&limit=100%s"
		local cursor_frmt = "&cursor=%s"

		while cont do
			cont = false
			local url =
				rbx_games_url_frmt:format(tostring(placeId), cursor and cursor_frmt:format(tostring(cursor)) or "")
			local succ_rsp, rsp = pcll(function()
				return req {
					Url = url,
					Method = "GET",
				}
			end)
			if succ_rsp and rsp and rsp.StatusCode and rsp.StatusCode == 200 and rsp.Body then
				local succ_jsn, jsn = pcll(function()
					return jsondecode(rsp.Body)
				end)
				if succ_jsn and jsn then
					cursor = jsn.nextPageCursor or nil
					if jsn.data then
						cnt = cnt + 1
						if pref.PrintVerbose then
							Prnt("Call#", cnt, "NumSvrs_Before", #servers)
						end
						for i, v in pairs(jsn.data) do
							if v and v.id and v.playing ~= nil and v.fps and v.ping and v.maxPlayers then
								if
									(min_p > 0 and v.playing < min_p)
									or (max_p > 0 and v.playing > max_p)
									or (pref.ExcludeFull and v.playing == v.maxPlayers)
									or (pref.ExcludeSame and v.id == game.JobId)
									or (min_f > 0 and v.fps and v.fps < min_f)
									or (max_png > 0 and v.ping and v.ping > max_png)
								then
									continue
								end
								v.origord = #servers + 1

								if v.maxPlayers > maxPlayers then
									maxPlayers = v.maxPlayers
								end
								if v.fps > maxFps then
									maxFps = v.fps
								end
								if v.ping > maxPing then
									maxPing = v.ping
								end
								table.insert(servers, v)
							end
						end
						if pref.PrintVerbose then
							Prnt("Call#", cnt, "NumSvrs_After", #servers)
						end
					end
				elseif not succ_jsn and jsn then
					Prnt("Response was success, but json decode failed! Url >>>", url)
					Prnt("ERROR >>>", jsn)
				else
					Prnt(
						"Response was weird wtf! Url >>>",
						url,
						"json decode pcall returned",
						succ_jsn or "nil",
						jsn or "nil"
					)
				end
			elseif not succ_rsp and rsp then
				Prnt("General failure wtf! Url >>>", url)
				Prnt("ERROR >>>", rsp)
			elseif succ_rsp and rsp then
				Prnt("Response was NOT success! Url >>>", url)
				for i, v in pairs(rsp) do
					Prnt(" - ", i, v)
				end
			else
				Prnt(
					"WTF SHOULD NOT HAPPEN! Url >>>",
					url,
					"request pcall returned >>>",
					succ_rsp or "nil",
					"and >>>",
					rsp or "nil"
				)
			end
			cont = cursor ~= nil
		end
		return servers, maxPlayers, maxFps, maxPing
	end

	local function RejoinPreferredServer(preferences)
		local tm = tick()

		local prefer = {
			SizeSort = "asc",
			MinPlayers = 0,
			MaxPlayers = 12,
			ExcludeFull = true,
			ExcludeSame = true,
			MinFps = 20,
			MaxPing = 400,
			FpsSortWeight = 0,
			PingSortWeight = 0,
			SizeSortWeight = 0,
			PrintVerbose = false,
			PrintPrefixTime = false,
		}
		if preferences and type(preferences) == "table" then
			for i, v in pairs(preferences) do
				prefer[i] = v
			end
		end

		if prefer.PrintPrefixTime then
			locale = game:GetService("LocalizationService").RobloxLocaleId
			prnt_pref_time = true
		end

		Prnt("Current PlaceId", game.PlaceId)
		Prnt("Current (Job)ServerId", game.JobId)

		local allSvrs, maxPlayers, maxFps, maxPing = GetAllServersForPlace(game.PlaceId, prefer)
		Prnt(
			"Servers Found for PlaceId",
			game.PlaceId,
			"NumSvrs",
			allSvrs and #allSvrs or 0,
			"Time",
			tostring(tick() - tm):sub(1, 6)
		)
		SetStatus("Found server! Time: " .. tostring(tick() - tm):sub(1, 6))
		if allSvrs and #allSvrs > 0 then
			local sortTm = tick()
			local sort = prefer.SizeSort and type(prefer.SizeSort) == "string" and prefer.SizeSort or "asc"
			local sort_desc = sort:lower() == "desc"
			local function numOrDefaultClamp(val)
				return val and type(val) == "number" and math.clamp(val, 0.01, 1000) or 0.01
			end
			local fps_wgt = numOrDefaultClamp(prefer.FpsSortWeight)
			local png_wgt = numOrDefaultClamp(prefer.PingSortWeight)
			local size_wgt = numOrDefaultClamp(prefer.SizeSortWeight)
			local function sortWeight(svr)
				local sz_wgt
				if sort_desc then
					sz_wgt = svr.playing / maxPlayers * size_wgt
				else
					sz_wgt = (1 - svr.playing / maxPlayers) * size_wgt
				end
				return sz_wgt + svr.fps / maxFps * fps_wgt + (1 - svr.ping / maxPing) * png_wgt
			end
			table.sort(allSvrs, function(a, b)
				local a_w = sortWeight(a)
				local b_w = sortWeight(b)
				if a_w > b_w then
					return true
				elseif a_w == b_w then
					return a.origord < b.origord
				else
					return false
				end
			end)

			if prefer.PrintVerbose then
				for i, v in ipairs(allSvrs) do
					Prnt("SORT", i, v.id, "playing", v.playing, "fps", v.fps, "ping", v.ping)
				end
			end

			if prefer.PrintVerbose then
				Prnt("Sort Time", tick() - sortTm)
			end
			local function RandomizeTable(tbl)
				local returntbl = {}
				if tbl[1] ~= nil then
					for i = 1, #tbl do
						table.insert(returntbl, math.random(1, #returntbl + 1), tbl[i])
					end
				end
				return returntbl
			end
			allSvrs = RandomizeTable(allSvrs)
			for i, v in ipairs(allSvrs) do
				Prnt(
					("Preferred #%s"):format(tostring(i)),
					v.id,
					("playing %s/%s"):format(tostring(v.playing), tostring(maxPlayers)),
					"fps",
					tostring(v.fps):sub(1, 5),
					"ping",
					v.ping
				)
				Prnt "Teleporting..."
				game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, v.id)
				task.wait(1)
			end
		else
			Prnt("Found no servers for PlaceId", game.PlaceId, "Time", tostring(tick() - tm):sub(1, 6))
		end
	end

	RejoinPreferredServer(...)
end]]

function FindServer()
	local _ID = game.PlaceId
	local _SERVERLIST = string.format("https://games.roblox.com/v1/games/%s/servers/Public?sortOrder=%s&limit=100", _ID, (Settings.SmallServer and "Asc") or (not Settings.SmallServer and "Dec"))
	local TotalTime = tick()

	function ListServers(cursor)
		local Raw = game:HttpGet(_SERVERLIST .. ((cursor and "&cursor="..cursor) or ""))
		return HttpService:JSONDecode(Raw)
	end
	
	local Server, Next
	function NewServer()
		local Servers = ListServers(Next)
		local FoundServer
		
		for i, serv in ipairs(Servers.data) do
        		if serv.playing < serv.maxPlayers then
            			FoundServer = serv
            			break
        		end
  		end

		Next = Servers.nextPageCursor
		return FoundServer
	end

	SetStatus("Found Server! Time: " ..  tostring(tick() - TotalTime):sub(1, 6) .. "s")
	local success, response 
	
	repeat
		success, response = pcall(function()
			TeleportService:TeleportToPlaceInstance(_ID, NewServer(), Player)
		end)
		
		if not success then
			task.wait(1)
			SetStatus("Failed! Retrying..")
			return
		end
	until sucess
end

local Queued = false
local function ServerSwitch()
	if not Queued then
		Queued = true

		local ScriptFile = GetDirectory() .. "/AutoCrateLoader.lua"
		local ScriptSaved = game:HttpGet(GithubLink)

		SaveFile(tostring(ScriptFile), ScriptSaved)
		SaveFile("AutoCrateSettings.json", HttpService:JSONEncode(Settings))

		-- bro why
		-- mixed the 2 cus why not
		local Queue = [[getgenv().StartingMoney = ]] .. getgenv().StartingMoney .. [[; getgenv().StartingTime = ]] .. getgenv().StartingTime .. [[; script_key = "]] .. script_key .. [[";
				
			local success, error = pcall(function()
				loadstring(readfile("]] .. tostring(ScriptFile) .. [["))()
			end)
				
			if not success then
				if not game:IsLoaded() then 
					game.Loaded:Wait() 
						task.wait(1) 
					end
					
					loadstring(game:HttpGet(GithubLink))()
				end
			end
		]]
		getgenv().StartingMoney = getgenv().StartingMoney
		getgenv().StartingTime  = getgenv().StartingTime
		
		queue_on_teleport(Queue)
    end

	--[[GetRejoinPrefferedFunction({
		SizeSort = "asc",
		MinPlayers = (Settings.SmallServer and 1 or 12),
		MaxPlayers = (Settings.SmallServer and 12 or 28),
		ExcludeFull = true,
		ExcludeSame = true,
		MinFps = 0,
		MaxPing = 300,
		FpsSortWeight = 0,
		PingSortWeight = 0,
		SizeSortWeight = 0,
		PrintVerbose = false,
		PrintPrefixTime = false,
		PrintUseConsoleWindow = false,
	})]]
	FindServer()
end

-------------------->> Failed Loading <<--------------------

local IsLoaded = false
task.delay(10, function()
	if not IsLoaded then
		pcall(function()
			require(game:GetService("ReplicatedStorage").Game.Notification).new({
				Text = "Failed to load, server hopping..",
				Duration = 4,
			})
		end)
		task.wait(2)
		task.delay(1, function()
			Humanoid.Health = 0
		end)
		ServerSwitch()
	end
end)

-------------------->> Client Modules <<--------------------

local Modules                   = {
	UI                          = require(ReplicatedStorage.Module.UI),
	Npc                         = require(ReplicatedStorage.NPC.NPC),
	NpcShared                   = require(ReplicatedStorage.GuardNPC.GuardNPCShared),
	Maid                        = require(ReplicatedStorage.Std.Maid),
	Store                       = require(ReplicatedStorage.App.store),
	Raycast                     = require(ReplicatedStorage.Module.RayCast),
	Vehicle                     = require(ReplicatedStorage.Vehicle.VehicleUtils),
	GunItem                     = require(ReplicatedStorage.Game.Item.Gun),
	GuardNPC                    = require(ReplicatedStorage.GuardNPC.GuardNPCShared),
	TagUtils                    = require(ReplicatedStorage.Tag.TagUtils),
	GunShopUI                   = require(ReplicatedStorage.Game.GunShop.GunShopUI),
	CharUtils                   = require(ReplicatedStorage.Game.CharacterUtil),
	SafeConsts                  = require(ReplicatedStorage.Safes.SafesConsts),
	CartSystem                  = require(ReplicatedStorage.Game.Cart.CartSystem),
	TombSystem                  = require(ReplicatedStorage.Game.Robbery.TombRobbery.TombRobberySystem),
	ItemSystem                  = require(ReplicatedStorage.Game.ItemSystem.ItemSystem),
	BossConsts                  = require(ReplicatedStorage.MansionRobbery.BossNPCConsts),
	PuzzleFlow                  = require(ReplicatedStorage.Game.Robbery.PuzzleFlow),
	Notification                = require(ReplicatedStorage.Game.Notification),
	MansionUtils                = require(ReplicatedStorage.MansionRobbery.MansionRobberyUtils),
	Confirmation                = require(ReplicatedStorage.Module.Confirmation),
	TeamChooseUI                = require(ReplicatedStorage.TeamSelect.TeamChooseUI),
	BulletEmitter               = require(ReplicatedStorage.Game.ItemSystem.BulletEmitter),
	DartDispenser               = require(ReplicatedStorage.Game.DartDispenser.DartDispenser),
	CharacterAnim               = require(ReplicatedStorage.Game.CharacterAnim),
	RobberyConsts               = require(ReplicatedStorage.Robbery.RobberyConsts),
	ButtonService               = require(ReplicatedStorage.App.BigButtonService),
	MilitaryTurret              = require(ReplicatedStorage.Game.MilitaryTurret.MilitaryTurret),
	DefaultActions              = require(ReplicatedStorage.Game.DefaultActions),
}

local Specs = Modules.UI.CircleAction.Specs
-------------------->> Movement Setup <<--------------------

local LaggedBack = false
local BreakMove = 0
local MovementSpeeds = {
	HeliSpeed = (10000),
	VehicleSpeed = 750,
	FlightSpeed = (175),
	PathSpeed = (180)
}

LPH_NO_VIRTUALIZE(function()
	for i, v in pairs(Workspace:GetChildren()) do
		if v.Name == "Bench" then
			v:Destroy()
		end
	end
end)()

local function DistanceXZ(pos1, pos2)
	local XZVector = Vector3.new(pos1.X, 0, pos1.Z) - Vector3.new(pos2.X, 0, pos2.Z)
	return XZVector.Magnitude
end

local function DistanceXYZ(pos1, pos2)
	local XYZVector = Vector3.new(pos1.X, pos1.Y, pos1.Z) - Vector3.new(pos2.X, pos2.Y, pos2.Z)
	return XYZVector.Magnitude
end

local function LagBackCheck(part)
	local ShouldStop = false
	local OldPosition = part.Position
	local Signal = part:GetPropertyChangedSignal("CFrame"):Connect(function()
		local CurrentPosition = part.Position

		if DistanceXZ(CurrentPosition, OldPosition) > 7 then
			LaggedBack = true
			task.delay(0.2, function()
				LaggedBack = false
			end)
		end
	end)

	task.spawn(function()
		while part and ShouldStop == false do
			OldPosition = part.Position
			task.wait()
		end
	end)

	return {
		Stop = function()
			ShouldStop = true
			Signal:Disconnect()
		end
	}
end

local function NoclipStart()
	local Noclipper = nil
	local NoclipLoop = LPH_NO_VIRTUALIZE(function()
		pcall(function()
			if not Character then 
				Noclipper:Disconnect()
			end
			for i, child in pairs(Character:GetDescendants()) do
				if child:IsA("BasePart") and child.CanCollide == true then
					child.CanCollide = false
				end
			end
		end)
	end)

	Noclipper = RunService.Stepped:Connect(NoclipLoop)
	return {
		Stop = function()
			Noclipper:Disconnect()
		end
	}
end

-------------------->> Raycasting Functions <<--------------------

local RayIgnore = Modules.Raycast.RayIgnoreNonCollideWithIgnoreList
local RayDirections = { High = Vector3.new(0, 999, 0), Low = Vector3.new(0, -999, 0) }

local function Raycast(pos, dir)
	local IgnoreList = {}
	if Character then 
		table.insert(IgnoreList, Character) 
	end

	local Rain = Workspace:FindFirstChild("Rain")
	if Rain then 
		table.insert(IgnoreList, Rain) 
	end

	local Params = RaycastParams.new()
	Params.RespectCanCollide = true
	Params.FilterDescendantsInstances = IgnoreList
	Params.IgnoreWater = true

	local Result = Workspace:Raycast(pos, dir, Params)
	if Result then 
		return Result.Instance, Result.Position 
	else 
		return nil, nil 
	end
end

-------------------->> Movement Functions <<--------------------

local function SmallTP(cf, speed)
	if not Character or not Root or not Humanoid or Humanoid.Health == 0 then
		return error()
	end

	if speed == nil then
		speed = 85
	end

	local IsTargetMoving = type(cf) == "function"
	local LagCheck = LagBackCheck(Root)
	local Noclip = NoclipStart()
	local TargetPos = (IsTargetMoving and cf() or cf).Position
	local LagbackCount = 0
	local Success = true

	local Mover = Instance.new("BodyVelocity", Root)
	Mover.P = 3000
	Mover.MaxForce = Vector3.new(9e9, 9e9, 9e9)

	repeat
		TargetPos = (IsTargetMoving and cf() or cf).Position
		Mover.Velocity = CFrame.new(Root.Position, TargetPos).LookVector * speed 
		task.wait(0.03) 

		if not Character or not Root or not Humanoid or Humanoid.Health == 0 then
			return error()
		end

		if LaggedBack then
			LagbackCount = LagbackCount + 1
			Mover.Velocity = Vector3.zero
			task.wait(1)

			if LagbackCount > 7 then
				Mover:Destroy()
				Noclip:Stop()
				LagCheck:Stop()

				BreakMove = 0
				Humanoid.Health = 0
				return error()
			end
		end
	until (Root.Position - TargetPos).Magnitude <= 5 or not Success

	if not Character or not Root or not Humanoid or Humanoid.Health == 0 then
		return error()
	end

	Mover.Velocity = Vector3.new(0, 0, 0)
	TargetPos = (IsTargetMoving and cf() or cf).Position
	Root.CFrame = CFrame.new(TargetPos)
	task.wait(0.001)

	Mover:Destroy()
	Noclip:Stop()
	LagCheck:Stop()
	Root.CFrame = CFrame.new(TargetPos)
	Root.Velocity, Root.RotVelocity = Vector3.new(0, 0, 0), Vector3.new(0, 0, 0)
end

local function BigTP(cf, speed)
	if not Character or not Root or not Humanoid or Humanoid.Health == 0 then
		return error()
	end

	if speed == nil then
		speed = 130
	end

	local IsTargetMoving = type(cf) == "function"

	if DistanceXZ(Root.Position, (IsTargetMoving and cf() or cf).Position) < 20 then
		Root.CFrame = CFrame.new((IsTargetMoving and cf() or cf).Position)
		return true
	end

	if Raycast(Root.Position + Vector3.new(0, 5, 0), Vector3.new(0, 1000, 0)) then
		Humanoid.Health = 0
		return error()
	end

	local LagCheck = LagBackCheck(Root)
	local Noclip = NoclipStart()
	local TargetPos = (IsTargetMoving and cf() or cf).Position
	local TargetOffset = Vector3.new(TargetPos.X, 500, TargetPos.Z)
	local LagbackCount = 0
	local Success = true

	local Mover = Instance.new("BodyVelocity", Root)
	Mover.P = 3000
	Mover.MaxForce = Vector3.new(9e9, 9e9, 9e9)

	repeat
		TargetPos = (IsTargetMoving and cf() or cf).Position
		TargetOffset = Vector3.new(TargetPos.X, 500, TargetPos.Z)

		Root.CFrame = CFrame.new(Root.CFrame.X, 500, Root.CFrame.Z)
		Mover.Velocity = (TargetOffset - Root.Position).Unit * speed

		task.wait(0.03) 

		if not Character or not Root or not Humanoid or Humanoid.Health == 0 then
			return error()
		end

		if LaggedBack then
			LagbackCount = LagbackCount + 1
			Mover.Velocity = Vector3.zero
			task.wait(1)

			if Raycast(Root.Position + Vector3.new(0, 5, 0), Vector3.new(0, 1000, 0)) then
				Humanoid.Health = 0
				return error()
			end

			if LagbackCount > 7 then
				Mover:Destroy()
				Noclip:Stop()
				LagCheck:Stop()
				Humanoid.Health = 0
				return error()
			end
		end
	until DistanceXZ(Root.Position, TargetOffset) < 15

	Mover.Velocity = Vector3.new(0, 0, 0)
	TargetPos = (IsTargetMoving and cf() or cf).Position
	Root.CFrame = CFrame.new(TargetPos)
	task.wait(0.05)

	Mover:Destroy()
	Noclip:Stop()
	LagCheck:Stop()

	task.wait(0.6)
	if (Root.Position - TargetPos).Magnitude > 30 then
		return BigTP(cf, speed)
	end
end

-------------------->> Vehicle Functions <<--------------------

local GetVehiclePacket = Modules.Vehicle.GetLocalVehiclePacket
local GetVehicleModel = Modules.Vehicle.GetLocalVehicleModel
local OwnedVehicles = {"Camaro", "Jeep"}

local function GetVehicleType()
	if not GetVehiclePacket() then return end
	return (GetVehicleModel().Name == "Heli" and "Helicopter" or "Car")
end

local function ExitVehicle()
	if Humanoid.Health <= 0 or not GetVehiclePacket() then return end
	Modules.CharUtils.OnJump()
	repeat task.wait() until not GetVehiclePacket() or Humanoid.Health <= 0
end

local function VehicleUp(height)
	local Vehicle = GetVehicleModel()
	if not Vehicle then return end

	Vehicle:SetPrimaryPartCFrame(CFrame.new(Vehicle.PrimaryPart.Position.X, height, Vehicle.PrimaryPart.Position.Z))
	task.wait(0.35)
end

local function ClosestVehicle() 
	for i,v in pairs(Specs) do
		if v.Tag.Name == "Seat" and table.find(OwnedVehicles, v.ValidRoot.Name) and (v.Part.Position - Root.Position).Magnitude <= 60 then
			return true
		end
	end
end

local function EnterVehicle(vehicle)
	vehicle = vehicle or nil
	if vehicle then
		for i,v in pairs(Specs) do
			if v.Name == "Hijack" and v.Part and v.Part == vehicle:FindFirstChild("Seat") then
				v:Callback(true)
			end
		end
		for i,v in pairs(Specs) do
			if v.Part and v.Part == vehicle:FindFirstChild("Seat") then
				v:Callback(true)
			end
		end
	else
		for i,v in pairs(Specs) do
			if v.Name == "Hijack" then
				v:Callback(true)
			end
		end
		for i,v in pairs(Specs) do
			if v.Tag.Name == "Seat" and table.find(OwnedVehicles, v.ValidRoot.Name) and (v.Part.Position - Root.Position).Magnitude <= 60 then
				v:Callback(true)
			end
		end
	end
end

local function GetVehicle()
	if not Character or not Root or not Humanoid or Humanoid.Health == 0 then
		return error()
	end
	if GetVehiclePacket() then
		pcall(function()
			GetVehicleModel().plate.SurfaceGui.Frame.TextLabel.Text = "VOIDCLIENT"
		end)
		return true
	end
	local Vehicles = Workspace.Vehicles:GetChildren()
	local OwnedCars = {"Camaro", "Jeep"}

	table.sort(Vehicles, function(a, b)
		if a.PrimaryPart and b.PrimaryPart then
			return (a.PrimaryPart.Position - Root.Position).Magnitude < (b.PrimaryPart.Position - Root.Position).Magnitude
		end
	end)

	if ClosestVehicle() then
		EnterVehicle()
		BreakFunc = tick()
		repeat task.wait() until GetVehiclePacket() or tick() - BreakFunc > 1.5
		if GetVehiclePacket() then 
			pcall(function()
				GetVehicleModel().plate.SurfaceGui.Frame.TextLabel.Text = "VOIDCLIENT"
			end)
			return true
		end 
	end

	if GetSpawnTime() < 0 and Player.Team.Name == "Prisoner" then
		local OldPos = Root.CFrame
		Root.CFrame = Root.CFrame * CFrame.new(0, 1000, 0)
		repeat task.wait() until Player.Team.Name == "Criminal"
		
		local timeout_drop = tick()

		repeat
			task.wait()
			Root.CFrame = OldPos
		until tick() - timeout_drop > 0.75
		
		Services.ReplicatedStorage.GarageSpawnVehicle:FireServer("Chassis", (math.random(1, 2) == 1 and "Camaro" or "Jeep"))

		BreakTime = tick()
		repeat
			task.wait(0.25)
		until tick() - BreakTime > 5 or GetVehicleModel()

		if GetVehicleModel() then
			pcall(function()
				GetVehicleModel().plate.SurfaceGui.Frame.TextLabel.Text = "VOIDCLIENT"
			end)
			return true
		end
	end

	for i, v in pairs(Vehicles) do
		if table.find(OwnedCars, v.Name) and v.PrimaryPart and v.Seat and not v.Seat.Player.Value and not Raycast(v.PrimaryPart.Position, Vector3.new(0, 1000, 0)) then 
			if not Character or not Root or not Humanoid or Humanoid.Health == 0 then
				return error()
			end

			if (Root.Position - v.Seat.Position).Magnitude > 50 then
				if BigTP(v.Seat.CFrame * CFrame.new(0, 4.5, 0)) == true then
					return
				end
			end

			for i = 1, 100 do
				EnterVehicle(v)
				task.wait(0.05)

				if GetVehiclePacket() then
					pcall(function()
						GetVehicleModel().Model.plate.SurfaceGui.Frame.TextLabel.Text = "VOIDCLIENT"
					end)
					return true
				end

				if not v.PrimaryPart or not v:FindFirstChild("Seat") or v.Seat.Player.Value then
					break
				end

				if i > 10 then
					if v:GetAttribute("Locked") then
						break
					end
				end
			end
		end
	end

	return GetVehicle()
end

local function VehicleTP(cframe, leave, offset, speed)
	if not Character or not Root or not Humanoid or Humanoid.Health == 0 then
		return error()
	end

	GetVehicle()

	speed = (speed or 650)
	offset = (offset or 500)

	local IsTargetMoving = type(cframe) == "function"
	local CarModel = GetVehicleModel().PrimaryPart
	local LagCheck = LagBackCheck(CarModel)
	local TargetPos = (IsTargetMoving and cframe() or cframe).Position
	local TargetOffset = Vector3.new(TargetPos.X, offset, TargetPos.Z)
	local LagbackCount = 0
	local Success = true

	local Mover = Instance.new("BodyVelocity", Root)
	Mover.P = 3000
	Mover.MaxForce = Vector3.new(9e9, 9e9, 9e9)

	repeat

		TargetPos = (IsTargetMoving and cframe() or cframe).Position
		TargetOffset = Vector3.new(TargetPos.X, offset, TargetPos.Z)

		CarModel.CFrame = CFrame.new(CarModel.CFrame.X, offset, CarModel.CFrame.Z)
		Mover.Velocity = (TargetOffset - CarModel.Position).Unit * speed

		task.wait(0.03) 

		if not Character or not Root or not Humanoid or Humanoid.Health == 0 or not GetVehicleModel() then
			return error()
		end

		if LaggedBack then
			LagbackCount = LagbackCount + 1
			Mover.Velocity = Vector3.zero
			task.wait(1)

			if LagbackCount == 10 then
				Mover:Destroy()
				if offset == 500 then
					LagCheck:Stop()
				end

				Humanoid.Health = 0
				return error()

			end
		end
	until not Success or DistanceXZ(CarModel.Position, TargetOffset) < 15

	Mover.Velocity = Vector3.new(0, 0.01, 0)
	task.wait(0.01)
	Mover:Destroy()

	TargetPos = (IsTargetMoving and cframe() or cframe).Position
	CarModel.CFrame = CFrame.new(TargetPos)
	task.wait(0.01)
	LagCheck:Stop()
	if leave then 
		task.wait(0.25)
		ExitVehicle() 
	end
end

-------------------->> Robbery Functions <<--------------------

local RobberyState = ReplicatedStorage.RobberyState
local RobberyConsts = Modules.RobberyConsts

local RobberyData = {
	Mansion = {
		Open                    = false, 
		Value                   = 3, 
		Robbed                  = false, 
		ID                      = RobberyConsts.ENUM_ROBBERY.MANSION, 
		Callback                = nil,
	},
	CargoShip = {
		Open                    = false, 
		Value                   = 3, 
		Robbed                  = false, 
		ID                      = RobberyConsts.ENUM_ROBBERY.CARGO_SHIP, 
		Callback                = nil,
	},
	Airdrop = {
		Open                    = false,
		Callback                = nil,
	}
}

for i, v in pairs(RobberyState:GetChildren()) do
	for i2, v2 in pairs(RobberyData) do
		if v.Name == tostring(v2.ID) then
			if i2 == "Mansion" then
				v2.Open = (v.Value == 1)
			else
				v2.Open = (v.Value ~= 3)
			end

			v2.Value = v.Value
			if v.Value == 3 and v2.Robbed then
				v2.Robbed = false
			end

			v:GetPropertyChangedSignal("Value"):Connect(function()
				if i2 == "Mansion" then
					v2.Open = (v.Value == 1)
				else
					v2.Open = (v.Value ~= 3)
				end

				v2.Value = v.Value
				if v.Value == 3 and v2.Robbed then
					v2.Robbed = false
				end
			end)

			break
		end
	end
end

RobberyState.ChildAdded:Connect(function(v)
	for i2, v2 in pairs(RobberyData) do
		if v.Name == tostring(v2.ID) then
			if i2 == "Mansion" then
				v2.Open = (v.Value == 1)
			else
				v2.Open = (v.Value ~= 3)
			end

			v2.Value = v.Value

			if v.Value == 3 and v2.Robbed then
				v2.Robbed = false
			end

			v:GetPropertyChangedSignal("Value"):Connect(function()
				if i2 == "Mansion" then
					v2.Open = (v.Value == 1)
				else
					v2.Open = (v.Value ~= 3)
				end

				v2.Value = v.Value
				if v.Value == 3 and v2.Robbed then
					v2.Robbed = false
				end
			end)

			break
		end
	end
end)

task.spawn(function()
	while true do
		if Workspace:FindFirstChild("Drop") then
			RobberyData.Airdrop.Open = true
		else
			RobberyData.Airdrop.Open = false
		end

		task.wait(0.01)
	end
end)

-------------------->> Miscanellous Functions <<--------------------

local function WaitForReward()
	if Player.PlayerGui.AppUI:FindFirstChild("RewardSpinner") then
		while Player.PlayerGui.AppUI:FindFirstChild("RewardSpinner") do
			task.wait()
		end
	end
end

local function GetClosestAirdrop()
	if Workspace:FindFirstChild("Drop") then
		return Workspace:FindFirstChild("Drop")
	end

	return nil
end

local function IsArrested()
	if PlayerGui.MainGui.CellTime.Visible or Backpack:FindFirstChild("Cuffed") then
		return true
	end

	return false
end

-------------------->> No Fall Damage <<--------------------

local IsPointInTag = Modules.TagUtils.isPointInTag
Modules.TagUtils.isPointInTag = newcclosure(function(point, tag)
	if tag == "NoFallDamage" then
		return true
	end

	if tag == "NoRagdoll" then
		return true
	end

	if tag == "NoParachute" then
		return true
	end

	return IsPointInTag(point, tag)
end)

-------------------->> Stream Map Rendering <<--------------------

local FinishedRendering = false
local TargetedLocations = {
	Vector3.new(-846, 39, -6231), 
	Vector3.new(-1541, 39, 3311), 
	Vector3.new(-363, 39, -6340), 
	Vector3.new(-820, 39, 3306), 
	Vector3.new(44, 39, -6409), 
	Vector3.new(811, 39, 3206), 
	Vector3.new(308, 39, -6350), 
	Vector3.new(979, 39, 3173), 
	Vector3.new(683, 39, -6267), 
	Vector3.new(1303, 39, 3150), 
	Vector3.new(1350, 39, -5764), 
	Vector3.new(1976, 39, 3028), 
	Vector3.new(2698, 39, -5365) 
}

local function LoadMap()
	Workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
	for i, Position in pairs(TargetedLocations) do
		local TweenInfo = TweenInfo.new(0.6, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 0, false, 0)

		pcall(function()
			local Tween = TweenService:Create(Workspace.CurrentCamera, TweenInfo, {CFrame = CFrame.new(Position)})
			Tween:Play() 
			SetStatus("Rendering position.. (" .. math.floor((i / #TargetedLocations) * 100) .. "%)")

			Tween.Completed:Wait()
		end)
	end

	FinishedRendering = true
	Workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
end

-------------------->> Gun Functions <<--------------------

local SelectedGun = "Pistol"
local SetIdentity = setidentity or set_thread_identity or setcontext or setthreadcontext or set_thread_context

--[[local function GetPistol()
	-- call this when player is crim, otherwise newgen cops are gonna kill us lol
	-- retrieve guns when player is crim and map finished loading
    for i,v in pairs(workspace:GetDescendants()) do
        if v:IsA("ClickDetector") then
			if Backpack:FindFirstChild(SelectedGun) then return end
            fireclickdetector(v)
        end
    end

	if Backpack:FindFirstChild(SelectedGun) then return end

	SetIdentity(2)
	Modules.GunShopUI.open()
	task.wait()

	firesignal(PlayerGui.GunShopGui.Container.Container.Main.Container.Slider[SelectedGun].Bottom.Action.MouseButton1Down)
	SetIdentity(8)
	Modules.GunShopUI.close()
end]]

local function ShootGun()
	local CurrentGun = Modules.ItemSystem.GetLocalEquipped()
	if not CurrentGun then return end
	Modules.GunItem._attemptShoot(CurrentGun)
end

local function EquipGun(bool)
	if not Backpack:FindFirstChild(SelectedGun) then return end
	Backpack[SelectedGun]:SetAttribute("InventoryItemLocalEquipped", bool)
	Backpack[SelectedGun].InventoryEquipRemote:FireServer(bool)
end

-- maybe i dont call getpistol at all?
-- im onto something

if not FinishedLoading then
	for i,v in pairs(workspace:GetDescendants()) do
        	if v:IsA("ClickDetector") then
			if Backpack:FindFirstChild(SelectedGun) then return end
           		fireclickdetector(v)
   		end
	end
end

-------------------->> idk but robbery callback <<--------------------

RobberyData.Mansion.Callback = function()
	if not Settings.IncludeMansion then return end
	if not Backpack:FindFirstChild("MansionInvite") then
		return
	end	
	if GetVehiclePacket() then 
		ExitVehicle()
	end

	SetStatus("TPing to Mansion..")
	local MansionRobbery = Workspace.MansionRobbery
	local TouchToEnter = MansionRobbery.Lobby.EntranceElevator.TouchToEnter
	local ElevatorDoor = MansionRobbery.ArrivalElevator.Floors:GetChildren()[1].DoorLeft.InnerModel.Door
	local MansionTeleportCFrame = TouchToEnter.CFrame - Vector3.new(0, TouchToEnter.Size.Y / 2 - Player.Character.Humanoid.HipHeight * 2, -TouchToEnter.Size.Z)
	local MansionActivateDoor = CFrame.new(3154, -205, -4558)
	local FailMansion = false
	local FailedStart = false

	task.delay(10, function()
		FailMansion = true
	end)

	local ElevatorTP = RunService.Heartbeat:Connect(function()
		Root.CFrame = MansionTeleportCFrame		
	end)

	repeat
		task.wait()
		firetouchinterest(Root, TouchToEnter, 0)
		task.wait()
		firetouchinterest(Root, TouchToEnter, 1)
	until Modules.MansionUtils.isPlayerInElevator(MansionRobbery, Player) or FailMansion
	ElevatorTP:Disconnect()

	if FailMansion then
		Humanoid.Health = 0
		return
	end

	--GetPistol()
	SetStatus("Starting Mansion..")
	repeat
		wait(0.1)
	until ElevatorDoor.Position.X > 3208

	for _, instance in pairs(MansionRobbery.Lasers:GetChildren()) do
		instance:Remove()
	end
	for _, instance in pairs(MansionRobbery.LaserTraps:GetChildren()) do
		instance:Remove()
	end

	task.delay(12.5, function()
		FailedStart = true
	end)
	local CutsceneTP = RunService.Heartbeat:Connect(function()
		Root.CFrame = MansionActivateDoor
	end)

	repeat task.wait() until MansionRobbery:GetAttribute("MansionRobberyProgressionState") == 3 or Humanoid.Health <= 0 or not Character or FailedStart
	CutsceneTP:Disconnect()

	if FailedStart then
		Humanoid.Health = 0
		return
	end

	SetStatus("Playing cutscene..")
	Modules.MansionUtils.getProgressionStateChangedSignal(MansionRobbery):Wait()

	local BodyVelocity = Instance.new("BodyVelocity", Root)
	BodyVelocity.P = 3000
	BodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
	BodyVelocity.Velocity = Vector3.new()

	local OrigY = Root.CFrame.Y
	Root.CFrame = CFrame.new(Root.CFrame.X, OrigY + 9, Root.CFrame.Z)

	local NPC_new = Modules.Npc.new
	local NPCShared_goTo = Modules.NpcShared.goTo
	local GuardNPC_goTo = Modules.GuardNPC.goTo

	Modules.Npc.new = function(NPCObject, ...)
		if NPCObject.Name ~= "ActiveBoss" then
			for i, v in pairs(NPCObject:GetDescendants()) do
				pcall(function()
					v.Transparency = 1
				end)
			end
		end
		return NPC_new(NPCObject, ...)
	end

	Modules.Npc.GetTarget = function(...)
		return MansionRobbery and MansionRobbery:FindFirstChild("ActiveBoss") and MansionRobbery:FindFirstChild("ActiveBoss").HumanoidRootPart
	end

	Modules.GuardNPC.goTo = function(NPCData, Pos)
		if MansionRobbery and MansionRobbery:FindFirstChild("ActiveBoss") then
			return GuardNPC_goTo(NPCData, MansionRobbery:FindFirstChild("ActiveBoss").HumanoidRootPart.Position)
		end
	end

	Workspace.Items.DescendantAdded:Connect(function(Des)
		if Des:IsA("BasePart") then
			Des.Transparency = 1
			Des:GetPropertyChangedSignal("Transparency"):Connect(function()
				Des.Transparency = 1
			end)
		end
	end)

	for i, v in pairs(ReplicatedStorage.Game.Item:GetChildren()) do
		require(v).ReloadDropAmmoVisual = function() end
		require(v).ReloadDropAmmoSound = function() end
		require(v).ReloadRefillAmmoSound = function() end
		require(v).ShootSound = function() end
	end

	getfenv(Modules.BulletEmitter.Emit).Instance = {
		new = function()
			return {
				Destroy = function() end
			}
		end
	}

	local BossCEO = MansionRobbery:WaitForChild("ActiveBoss")
	local OldHealth = BossCEO.Humanoid.Health

	LPH_NO_VIRTUALIZE(function()
		Modules.Raycast.RayIgnoreNonCollideWithIgnoreList = function(...)
			local arg = {RayIgnore(...)}

			if (tostring(getfenv(2).script) == "BulletEmitter" or tostring(getfenv(2).script) == "Taser") then
				arg[1] = BossCEO.Head
				arg[2] = BossCEO.Head.Position
			end

			return unpack(arg)
		end
	end)()

	require(ReplicatedStorage.NPC.NPC).GetTarget = function()
		return BossCEO:FindFirstChild("Head")
	end

	Modules.NpcShared.goTo = function(NPCData, Pos)
		if MansionRobbery and MansionRobbery:FindFirstChild("ActiveBoss") then
			return NPCShared_goTo(NPCData, MansionRobbery:FindFirstChild("ActiveBoss").HumanoidRootPart.Position)
		end
	end

	Workspace.Items.DescendantAdded:Connect(function(Des)
		if Des:IsA("BasePart") then
			Des.Transparency = 1
			Des:GetPropertyChangedSignal("Transparency"):Connect(function()
				Des.Transparency = 1
			end)
		end
	end)

	SetStatus("Killing CEO Boss..")
	while Player.Folder:FindFirstChild("Pistol") and BossCEO and BossCEO:FindFirstChild("HumanoidRootPart") and BossCEO.Humanoid.Health ~= 1 do
		SetStatus("Killing ceo boss.. (" .. math.floor((OldHealth - BossCEO.Humanoid.Health) / OldHealth * 100) .. "%)")
		EquipGun(true)
		task.wait()
		ShootGun()
	end

	Root.CFrame = CFrame.new(Root.CFrame.X, OrigY, Root.CFrame.Z)
	BodyVelocity:Destroy()
	EquipGun(false)

	SetStatus("Waiting for reward..")
	repeat task.wait() until PlayerGui.AppUI:FindFirstChild("RewardSpinner")

	WaitForReward()
	task.wait(0.5)
end

RobberyData.CargoShip.Callback = function()
	if not Settings.IncludeCargoShip then return end
	if not GetVehiclePacket() and GetVehicleType() ~= "Heli" then
		ExitVehicle()
		SetStatus("Getting a helicopter..")
		for i, v in pairs(Workspace.Vehicles:GetChildren()) do
			if v.Name == "Heli" and v.PrimaryPart and v.Seat and not v.Seat.Player.Value and not v:GetAttribute("Locked") and not Raycast(v.Seat.Position, RayDirections.High) then
				VehicleTP(v.PrimaryPart.CFrame, true)
				SmallTP(v.Seat.CFrame * CFrame.new(0, 5, 0))

				local Timeout = tick()
				repeat 
					Root.CFrame = v.Seat.CFrame * CFrame.new(0, 5, 0)
					for _, spec in pairs(Specs) do
						if spec.Name == "Hijack" then spec:Callback(true) end
					end
					task.wait(0.01)
					for _, spec in pairs(Specs) do
						if spec.Part and spec.Part == v.Seat then spec:Callback(true) end
					end	
				until GetVehiclePacket() or tick() - Timeout > 8

				if GetVehiclePacket() then
					break
				end
			end
		end
	end

	if not GetVehiclePacket() then
		SetStatus("No heli's available..")
		task.wait(0.75)
		return false
	end

	VehicleUp(Root.CFrame.Y + 150)
	if GetVehiclePacket() then
		for i, v in pairs(GetVehicleModel():GetDescendants()) do
			pcall(function()
				v.Transparency = 1.000
			end)
		end
	end
	task.wait(0.5)

	SetStatus("Dropping rope..")
	Modules.Vehicle.Classes.Heli.attemptDropRope()

	local RopePull = GetVehicleModel().Preset:WaitForChild("RopePull")
	local Rope = GetVehicleModel().Winch:WaitForChild("RopeConstraint")

	if Rope and RopePull then
		Rope.Length = 999
		Rope.WinchEnabled = true
		RopePull.CanCollide = false
		RopePull.Massless = true
	end

	for i = 1, 2 do
		SetStatus("Attaching to crate".. i .. "..")
		if not RobberyData.CargoShip.Open then return end

		local Crate = Workspace.CargoShip.Crates:GetChildren()[1]
		Player:RequestStreamAroundAsync(Crate.MeshPart.Position, 1000)

		repeat
			RopePull:PivotTo(Crate.MeshPart.CFrame)
			RopePull:WaitForChild("ReqLink"):FireServer(Crate, Vector3.zero)
			task.wait()
		until RopePull.AttachedTo.Value ~= nil or not RobberyData.CargoShip.Open

		SetStatus("Turning in crate" .. i .. "..")
		if not RobberyData.CargoShip.Open then return end
		task.wait(0.1)
		repeat
			RopePull:PivotTo(CFrame.new(-471, -50, 1906))
			Crate:PivotTo(CFrame.new(-471, -50, 1906))
			task.wait()
		until not Crate:FindFirstChild("MeshPart") or not RobberyData.CargoShip.Open
		if not RobberyData.CargoShip.Open then return end
	end

	RobberyData.CargoShip.Robbed = true
	if Rope and RopePull then
		Rope.Length = 999
		Rope.WinchEnabled = true
		RopePull.CanCollide = false
		RopePull.Massless = true
	end

	task.wait(0.1)
	ExitVehicle()
end

RobberyData.Airdrop.Callback = function(drop)
	if not Settings.IncludeAirdrops then return end
	if not GetClosestAirdrop() or not drop.PrimaryPart then return end

	repeat task.wait() SetStatus("Waiting for drop..") until drop:GetAttribute("BriefcaseLanded") == true or not GetClosestAirdrop() or not drop.PrimaryPart 
	if not GetClosestAirdrop() or not drop.PrimaryPart then return end

	SetStatus("Teleporting to crate..")
	VehicleTP(drop.PrimaryPart.CFrame * CFrame.new(10, 7.5, 0), true)
	SmallTP(drop.PrimaryPart.CFrame * CFrame.new(0, 5, 0))
	if not GetClosestAirdrop() or not drop.PrimaryPart then return end

	local Noclip = nil
	if Settings.HideInCrate then
		pcall(function()
			Modules.DefaultActions.crawlButton.onPressed()
			Noclip = NoclipStart()
			Root.CFrame = drop.PrimaryPart.CFrame * CFrame.new(0, -1.5, 0)
		end)
	end

	local BodyVelocity = Instance.new("BodyVelocity", Root)
	BodyVelocity.P = 3000
	BodyVelocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
	BodyVelocity.Velocity = Vector3.new()

	SetStatus("Opening crate..")

	task.spawn(function()
		while drop and drop:FindFirstChild("NPCs") == nil do
			task.wait(0.1)
		end
		drop:FindFirstChild("NPCs"):Destroy()
	end)

	repeat task.wait() until Player.TeamColor == BrickColor.new("Bright red")

	local OldTime = drop:GetAttribute("BriefcasePressAccumulation")
	repeat 
		pcall(function()
			drop.BriefcasePress:FireServer()
			drop.BriefcaseCollect:FireServer()
			task.wait()
		end)
	until drop:GetAttribute("BriefcaseCollected") == true or not drop.PrimaryPart or IsArrested() or not Character
	if drop then drop.Name = "" end
	Camera.CameraType = Enum.CameraType.Custom
	BodyVelocity:Remove()

	if Settings.HideInCrate then
		pcall(function()
			Modules.DefaultActions.crawlButton.onPressed()
			Root.CFrame = drop.PrimaryPart.CFrame * CFrame.new(0, 5, 0)
			Noclip:Stop()
		end)
	end

	if Settings.CollectCash then
		SetStatus("Collecting cash drop..")
		task.wait(0.75)
		for i = 1, 3 do
			for _, spec in pairs(Modules.UI.CircleAction.Specs) do
				if spec.Name:sub(1, 9) == "Collect $" then
					spec:Callback(true)
				end
			end
			task.wait(0.25)
		end
	end

	SetStatus("Waiting for reward..")
	WaitForReward()

	drop:Destroy()
end

repeat task.wait(0.1) until Character and Humanoid and Root
repeat task.wait() pcall(function() Modules.TeamChooseUI.Hide() end) until PlayerGui:FindFirstChild("TeamSelectGui") == nil or PlayerGui:FindFirstChild("TeamSelectGui").Enabled == false or Player.TeamColor == BrickColor.new("Bright red") or Humanoid.Health <= 0

while Humanoid == nil do
	task.wait(0.1)
end

IsLoaded = true

task.spawn(function()
	while task.wait(0.01) do
		pcall(function()
			local TimeElapsed = tick() - getgenv().StartingTime
			local MoneyMade = Leaderstats:WaitForChild("Money").Value - getgenv().StartingMoney
			SetStats(MoneyMade, TimeElapsed)
		end)
		if IsArrested() then
			SetStatus("You're arrested, switching servers..")
			task.delay(2, function()
				Humanoid.Health = 0
			end)
			ServerSwitch()
		end

		if GetClosestAirdrop() then
			local function FixDrop()
				CrateLbl.TextColor3 = Color3.fromRGB(0, 255, 0)
			end

			task.spawn(function()
				while not pcall(FixDrop) do
					task.wait(0.1)
				end
			end)
		end

		if RobberyData.CargoShip.Open and not RobberyData.CargoShip.Robbed then
			local function FixShip()
				ShipLbl.TextColor3 = Color3.fromRGB(0, 255, 0)
			end

			task.spawn(function()
				while not pcall(FixShip) do
					task.wait(0.1)
				end
			end)
		end

		if RobberyData.Mansion.Open then 
			local function FixMansion()
				MansionLbl.TextColor3 = Color3.fromRGB(0, 255, 0)
			end

			task.spawn(function()
				while not pcall(FixMansion) do
					task.wait(0.1)
				end
			end)
		end
	end
end)
task.spawn(function()
	if not Settings.AutoBoostFPS then return end
	Workspace.Terrain.WaterWaveSize = 0
	Workspace.Terrain.WaterWaveSpeed = 0
	Workspace.Terrain.WaterReflectance = 0
	Workspace.Terrain.WaterTransparency = 0

	Lighting.GlobalShadows = false
	Lighting.FogEnd = 9e9
	Lighting.Brightness = 0

	settings().Rendering.QualityLevel = "Level01"

	for i, v in pairs(game:GetDescendants()) do
		if v:IsA("Part") or v:IsA("CornerWedgePart") or v:IsA("TrussPart") then
			v.Material = "Plastic"
			v.Reflectance = 0
		elseif v:IsA("Decal") or v:IsA("Texture") then
			v.Transparency = 1
		elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
			v.Lifetime = NumberRange.new(0)
		elseif v:IsA("Explosion") then
			v.BlastPressure = 1
			v.BlastRadius = 1
		elseif v:IsA("Fire") or v:IsA("SpotLight") or v:IsA("Smoke") then
			v.Enabled = false
		elseif v:IsA("MeshPart") then
			v.Material = "Plastic"
			v.Reflectance = 0
			v.TextureID = 10385902758728957
		end
	end

	for i, e in pairs(Lighting:GetChildren()) do
		if e:IsA("BlurEffect") or e:IsA("SunRaysEffect") or e:IsA("ColorCorrectionEffect") or e:IsA("BloomEffect") or e:IsA("DepthOfFieldEffect") then
			e.Enabled = false
		end
	end
end)

task.spawn(function()
	if Settings.AutoOpenSafes then
		local SafeAmt = #Modules.Store._state.safesInventoryItems
		if SafeAmt ~= 0 then
			for i = 1, SafeAmt do
				local CurrentSafe = Modules.Store._state.safesInventoryItems[1]

				ReplicatedStorage[Modules.SafeConsts.SAFE_OPEN_REMOTE_NAME]:FireServer(CurrentSafe.itemOwnedId)
				task.wait(3)

				if not Settings.AutoOpenSafes then break end
			end
		end
	end
end)

if Settings.IncludeAirdrops and not Workspace:FindFirstChild("Drop") then 
    LoadMap()
end

Humanoid.Died:Connect(function()
	if not FinishedRendering then
		SetStatus("Cop killed you, switching servers..")
		ServerSwitch()
		return
	end

	Character, Root, Humanoid = nil, nil, nil

	SetStatus("You died, switching servers..")
	ServerSwitch()
end)

local function FixCoreGui()
	game:GetService("CoreGui").RobloxPromptGui.promptOverlay.ChildAdded:Connect(function(child)
		if child.Name == "ErrorPrompt" and child:FindFirstChild("MessageArea") and child.MessageArea:FindFirstChild("ErrorFrame") then
			SetStatus("Client kicked, switching servers..")
			task.delay(2, function()
				Humanoid.Health = 0
			end)
			ServerSwitch()
		end
	end)
end

task.spawn(function()
	while not pcall(FixCoreGui) do
		print("Failed to load coregui kick detection, retrying in 0.1s")
		task.wait(0.1)
	end
end)

task.spawn(function()
	while task.wait(300) do
		SetStatus("Timed out, switching servers..")
		task.delay(2, function()
			Humanoid.Health = 0
		end)
		ServerSwitch()
	end
end)

if RobberyData.CargoShip.Open then
	warn(pcall(RobberyData.CargoShip.Callback))
end

if GetClosestAirdrop() then
	warn(pcall(RobberyData.Airdrop.Callback, GetClosestAirdrop()))
end

if RobberyData.CargoShip.Open and not RobberyData.CargoShip.Robbed then
	warn(pcall(RobberyData.CargoShip.Callback))
end

if GetClosestAirdrop() then
	warn(pcall(RobberyData.Airdrop.Callback, GetClosestAirdrop()))
end

if RobberyData.Mansion.Open then
	warn(pcall(RobberyData.Mansion.Callback))
end

SetStatus("No more robberies, finding server..")
ServerSwitch()

-- failsafe
task.delay(2, function()
	Humanoid.Health = 0
end)
