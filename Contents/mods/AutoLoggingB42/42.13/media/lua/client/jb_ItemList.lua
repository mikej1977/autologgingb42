-- jb_item_list.lua
JBLogging = JBLogging or {}

JBLogging.GatherItemList = {
    Logs = {
        "Base.Log", 
        "JB_Big_Wood.SmallLog", 
        "JB_Big_Wood.MediumLog", 
        "JB_Big_Wood.LargeLog", 
        "JB_Big_Wood.VeryLargeLog"
    },
    Planks = { "Base.Plank" },
    Twigs = {
        "Base.LargeBranch", 
        "Base.Sapling", 
        "Base.TreeBranch2", 
        "Base.Twigs", 
        "Base.Splinters"
    }
}

JBLogging.ProcessList = {
    SawLogs = {
        ["Base.Log"] = true,
        ["JB_Big_Wood.LargeLog"] = true,
        ["JB_Big_Wood.VeryLargeLog"] = true
    },
    ResultItem = "Plank"
}
