-- jb_containerRegistry.lua

JBLogging = JBLogging or {}
JBLogging.Storage = {}

JBLogging.Storage.Types = {
    Logs = {
        name = "Log Storage",

        itemType = JBLogging.GatherItemList.Logs,
        sprites = {
            empty = "jb_autologging_20",
            cursor = "jb_autologging_4",
            cursorNorth = "jb_autologging_0",

            level1 = "jb_autologging_4",
            level2 = "jb_autologging_5",
            level3 = "jb_autologging_6",
            level4 = "jb_autologging_7",

            level1north = "jb_autologging_0",
            level2north = "jb_autologging_1",
            level3north = "jb_autologging_2",
            level4north = "jb_autologging_3"
        }
    },

    Planks = {
        name = "Plank Storage",
        itemType = JBLogging.GatherItemList.Planks,
        sprites = {
            empty = "jb_autologging_20",
            cursor = "jb_autologging_12",
            cursorNorth = "jb_autologging_8",

            level1 = "jb_autologging_12",
            level2 = "jb_autologging_13",
            level3 = "jb_autologging_14",
            level4 = "jb_autologging_15",

            level1north = "jb_autologging_8",
            level2north = "jb_autologging_9",
            level3north = "jb_autologging_10",
            level4north = "jb_autologging_11"
        }
    },

    Twigs = {
        name = "Twig Storage",
        itemType = JBLogging.GatherItemList.Twigs,
        sprites = {
            empty = "jb_autologging_20",
            cursor = "jb_autologging_16",
            cursorNorth = "jb_autologging_16",

            level1 = "jb_autologging_16",
            level2 = "jb_autologging_17",
            level3 = "jb_autologging_18",
            level4 = "jb_autologging_19",

            level1north = "jb_autologging_16",
            level2north = "jb_autologging_17",
            level3north = "jb_autologging_18",
            level4north = "jb_autologging_19",
        },
    },

    Firewood = {
        name = "Firewood Storage",
        itemType = JBLogging.GatherItemList.Firewood,
        sprites = {
            empty = "jb_autologging_20",
            cursor = "jb_autologging_28",
            cursorNorth = "jb_autologging_24",

            level1 = "jb_autologging_28",
            level2 = "jb_autologging_29",
            level3 = "jb_autologging_30",
            level4 = "jb_autologging_31",

            level1north = "jb_autologging_24",
            level2north = "jb_autologging_25",
            level3north = "jb_autologging_26",
            level4north = "jb_autologging_27",
        },
    },

    Stones = {
        name = "Stone Storage",
        itemType = JBLogging.GatherItemList.Stones,
        sprites = {
            empty = "jb_autologging_20",
            cursor = "jb_autologging_22",
            cursorNorth = "jb_autologging_22",

            level1 = "jb_autologging_21",
            level2 = "jb_autologging_21",
            level3 = "jb_autologging_22",
            level4 = "jb_autologging_23",

            level1north = "jb_autologging_21",
            level2north = "jb_autologging_21",
            level3north = "jb_autologging_22",
            level4north = "jb_autologging_23",
        }
    }
}