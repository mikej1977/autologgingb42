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
        ["TreeBranch2"] = true,
        ["Base.UnusableWood"] = true,
    },

    Firewood = {
        ["Base.Firewood"] = true,
    }
}

JBLogging.ProcessList = {
    SawLogs = {
        ["Base.Log"] = true,
        ["JB_Big_Wood.LargeLog"] = true,
        ["JB_Big_Wood.VeryLargeLog"] = true,
    }
}
