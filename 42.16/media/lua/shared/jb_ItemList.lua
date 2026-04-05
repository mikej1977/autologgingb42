-- jb_ItemList.lua
JBLogging = JBLogging or {}

JBLogging.GatherItemList = {
    
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

    StoneStorage = {
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

JBLogging.ProcessList = {
    SawLogs = {
        ["Base.Log"] = true,
        ["JB_Big_Wood.LargeLog"] = true,
        ["JB_Big_Wood.VeryLargeLog"] = true,
    }
}

-- For custom name pickup item lookups
JBLogging.pickupItems = {
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
