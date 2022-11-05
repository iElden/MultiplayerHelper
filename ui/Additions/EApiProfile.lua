-------------------------------------------------
-- Game Summaries Screen
-------------------------------------------------
include( "InstanceManager" );
include( "SupportFunctions" );
include( "PopupDialog" );

local MIN_SCREEN_Y				:number = 768;

----------------------------------------------------------------
-- Utilities
----------------------------------------------------------------
-- Attempt to set a control's icon by enumerating an array.
function SetControlIcon(control, icons)
	if(icons) then
		local s = #icons;
		for i = s, 1, -1 do
			local v = icons[i];
			if(control:TrySetIcon(v)) then
				return true;
			end
		end
	end

	return false;
end


-- Global Constants
g_TabControls = {
	{Controls.OverviewTab, Controls.SelectedOverviewTab, Controls.OverviewTabPanel},
};

-- Global Variables
g_RankingManager = InstanceManager:new("RankingInstance", "RankingContainer", Controls.RankingStack);

g_StatisticsManagers = {};

g_AvailableRulesets = nil; 			-- Array of available rulesets.
g_CurrentRuleset = nil; 			-- Currently selected ruleset.
g_Games = nil;						-- List of game history data.
g_GameListings = nil;				-- List of game history listings.
g_GameListingsSortFunction = nil;	-- Currently selected sort method.
g_SortDirectionReversed = false;	-- Reverse the sort?
g_SelectedGameId = nil;				-- Track currently selected listing.
g_RulesetPlayers = nil;				-- Map of all ruleset playable leaders
g_RulesetTypes = nil;				-- Map of all ruleset types.
g_RulesetVictories = nil;			-- Map/Array of all ruleset victories.
g_Categories = nil;					-- Sorted array of all statistics categories.
g_Statistics = nil;					-- Sorted array of all statistics.

-- Release cache to free up memory.
function DumpCache()
	g_AvailableRulesets = nil;
	g_CurrentRuleset = nil;
	g_Games = nil;
	g_GameListings = nil;
	g_SelectedGameListingHandle = nil;
	g_RulesetPlayers = nil;
	g_RulesetTypes = nil;
	g_RulesetVictories = nil;
	g_Categories = nil;
	g_Statistics = nil;
end

function DumpInstances()
	for i,v in ipairs(g_StatisticsManagers) do
		v:ResetInstances();
	end
	g_HighlightsManager:ResetInstances();
	g_StatisticsBlockManager:ResetInstances();
	g_StatisticsManagers = {};

	g_GamesManager:ResetInstances();
	g_LeaderProgressManager:ResetInstances();
	g_VictoryProgressManager:ResetInstances();
end

-- Much of hall of fame is read-only and static so it can be cached.
function UpdateGlobalCache()
	DumpCache();

	local gameObjects = HallofFame.GetGameObjects();
	g_GameObjects = {};
	for i,v in ipairs(gameObjects) do
		g_GameObjects[v.ObjectId] = v;
	end

	g_AvailableRulesets = HallofFame.GetAvailableRulesets();
	if(g_AvailableRulesets and #g_AvailableRulesets > 0) then
		for i,v in ipairs(g_AvailableRulesets) do
			v.DisplayName = Locale.Lookup(v.Name);
		end

		table.sort(g_AvailableRulesets, function(a,b)
			if(a.SortIndex ~= b.SortIndex) then
				return a.SortIndex < b.SortIndex;
			else
				return Locale.Compare(a.DisplayName, b.DisplayName) == -1;
			end
		end);
	else
		g_CurrentRuleset = nil;
	end
end

function SelectTab(index)
	for i,v in ipairs(g_TabControls) do
		if(i ~= index) then
			v[1]:SetSelected(false);
			v[2]:SetHide(true);
			v[3]:SetHide(true);
		end
	end

	g_TabControls[index][3]:SetHide(false);
	g_TabControls[index][2]:SetHide(false);
	g_TabControls[index][1]:SetSelected(true);
end


----------------------------------------------------------------
-- Generic Handlers
----------------------------------------------------------------
function HandleExitRequest()
	UIManager:DequeuePopup( ContextPtr );
end

----------------------------------------------------------------
-- Event Handlers
----------------------------------------------------------------
function OnGameDetailsClicked(id)
	local kParameters = {};
	kParameters.GameId = id
	UIManager:QueuePopup(Controls.GameDetails, PopupPriority.Current, kParameters);
end

----------------------------------------------------------------

function Profile_PopulateRanking()
	g_SelectedGameId = nil;
	g_GameListings = {};
	g_RankingManager:ResetInstances();
	for i,v in ipairs(ExposedMembers.EldenAPI.profile.rating) do
		local instance = g_RankingManager:GetInstance();

		instance.RankingServerIcon:SetIcon(v[1]);
		instance.RankingLine1:SetText(v[2]);
		instance.RankingLine2:SetText(v[3]);
		instance.RankingLine3:SetText(v[4]);
		instance.RankingLine4:SetText(v[5]);
	end

	Controls.RankingStack:CalculateSize();
	Controls.RankingStack:ReprocessAnchoring();
end

function OnShow()
	UpdateGlobalCache();
	local screenX, screenY:number  = UIManager:GetScreenSizeVal();
	local hideLogo        :boolean = true;
	if(screenY >= MIN_SCREEN_Y + (Controls.LogoContainer:GetSizeY()+ Controls.LogoContainer:GetOffsetY() * 2)) then
		hideLogo = false;
		Controls.MainWindow:SetSizeY(screenY- (Controls.LogoContainer:GetSizeY() + Controls.LogoContainer:GetOffsetY()));
	else
		Controls.MainWindow:SetSizeY(screenY);
	end

	Controls.LogoContainer:SetHide(hideLogo);
	SelectTab(1);
	-- Set Profile Info
	Controls.PlayerIcon:SetIcon(ExposedMembers.EldenAPI.profile.icon);
	Controls.PlayerName:SetText(ExposedMembers.EldenAPI.profile.name);
	Profile_PopulateRanking();
end

function OnHide()
	DumpInstances();
	DumpCache();
end
----------------------------------------------------------------
function PostInit()
	if(not ContextPtr:IsHidden()) then
		OnShow();
	end
end

----------------------------------------------------------------
-- Input Handler
----------------------------------------------------------------
function InputHandler( uiMsg, wParam, lParam )
	if (uiMsg == KeyEvents.KeyUp) then
		if (wParam == Keys.VK_ESCAPE) then
			HandleExitRequest();
			return true;
		end
	end
end



----------------------------------------------------------------
-- Initializer
----------------------------------------------------------------
function Initialize()
	ContextPtr:SetInputHandler( InputHandler );
	g_PopupDialog = PopupDialog:new( "GameSummaries" );

	Controls.OverviewTab:RegisterCallback(Mouse.eLClick, function()
		UI.PlaySound("Main_Menu_Mouse_Over");
		OnOverviewTabClicked()
	end);

	for i,v in ipairs(g_TabControls) do
		v[1]:RegisterCallback( Mouse.eLClick, function()
			UI.PlaySound("Main_Menu_Mouse_Over");
			SelectTab(i);
		end);
	end


	Controls.CloseButton:RegisterCallback( Mouse.eLClick, function()
		UI.PlaySound("Main_Menu_Mouse_Over");
		HandleExitRequest();
	end);

	Controls.RulesetPullDown:GetButton():SetText("http://127.0.0.1:52525/IGProfile/discord-id/384274248799223818");

	ContextPtr:SetShowHandler( OnShow );
	ContextPtr:SetHideHandler( OnHide );
	ContextPtr:SetPostInit(PostInit);
end

Initialize();