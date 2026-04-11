-- registries/jb_ItemList.lua
local ItemList = {}

ItemList.GatherItemList = {
    Logs = {
        ["Base.Log"] = true,
        ["JB_Big_Wood.LargeLog"] = true,
        ["JB_Big_Wood.VeryLargeLog"] = true,
        ["JB_Big_Wood.SmallLog"] = true,
        ["JB_Big_Wood.MediumLog"] = true,
        ["Log"] = true,
    },

    Planks = { ["Base.Plank"] = true },
    
    Twigs = {
        ["Base.LargeBranch"] = true,
        ["Base.Sapling"] = true,
        ["Base.TreeBranch2"] = true,
        ["Base.Twigs"] = true,
        ["Base.Splinters"] = true,
        ["Twigs"] = true,
        ["StoneTwigs"] = true,
        ["TreeBranch2"] = true,
        ["Base.UnusableWood"] = true,
    },
    
    Firewood = {
        ["Base.Firewood"] = true,
    },
    
    Stones = {
        ["4Stones"] = true,
        ["LargeStoneTwigs"] = true,
        ["LargeStone"] = true,
        ["FlatStone"] = true,
        ["StoneTwigs"] = true,
        ["Stone"] = true,
        ["Limestone"] = true,
        ["Base.FlatStone"] = true,
        ["Base.LargeStone"] = true,
        ["Base.Limestone"] = true,
        ["Base.Stone2"] = true,
    },

    StonesStorage = {
        ["Base.Stone2"] = true,
    },

    Boulders = {
        ["Boulder"] = true,
    },
    
    Stumps = {
        ["Small Stump"] = true,
        ["Tree Stump"] = true,
        ["Stump"] = true,
    },
}

ItemList.ProcessList = {
    SawLogs = {
        ["Base.Log"] = true,
        ["JB_Big_Wood.LargeLog"] = true,
        ["JB_Big_Wood.VeryLargeLog"] = true,
    }
}

-- For custom name pickup item lookups
ItemList.PickupItems = {
    ["4Stones"] = "Stone2",
    ["LargeStoneTwigs"] = "LargeStone",
    ["LargeStone"] = "LargeStone",
    ["FlatStone"] = "FlatStone",
    ["StoneTwigs"] = "Stone2",
    ["Stone"] = "Stone2",
    ["Limestone"] = "Limestone",
    ["Stump"] = "UnusableWood",
    ["Small Stump"] = "UnusableWood",
    ["Tree Stump"] = "UnusableWood",
    ["Twigs"] = "Twigs",
    ["TreeBranch2"] = "TreeBranch2",
    ["Log"] = "Log",
}

ItemList.BoulderConfig = {
    -- we match "boulders_" + min to max
    { min = 0,  max = 7,  tool = true,  time = 150, stones = 3 },
    { min = 8,  max = 15, tool = false, time = 50,  stones = 1 },
    { min = 16, max = 35, tool = true,  time = 250, stones = 5 },
    { min = 36, max = 43, tool = true,  time = 150, stones = 3 },
    { min = 44, max = 51, tool = false, time = 100, stones = 2 },
    { min = 52, max = 59, tool = true,  time = 200, stones = 3 },
}

return ItemList