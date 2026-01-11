-- jb_ItemList.lua
JBLogging = JBLogging or {}

JBLogging.GatherItemList = {
    
    Logs = {
        ["Base.Log"] = true,
        ["JB_Big_Wood.LargeLog"] = true,
        ["JB_Big_Wood.VeryLargeLog"] = true,
        ["JB_Big_Wood.SmallLog"] = true, 
        ["JB_Big_Wood.MediumLog"] = true, 
        
    },

    Planks = { ["Base.Plank"] = true },
    
    Twigs = {
        ["Base.LargeBranch"] = true,
        ["Base.Sapling"] = true,
        ["Base.TreeBranch2"] = true,
        ["Base.Twigs"] = true,
        ["Base.Splinters"] = true
    }
}

JBLogging.ProcessList = {
    SawLogs = {
        ["Base.Log"] = true,
        ["JB_Big_Wood.LargeLog"] = true,
        ["JB_Big_Wood.VeryLargeLog"] = true
    }
}
