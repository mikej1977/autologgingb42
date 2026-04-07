JBLogging = JBLogging or {}
require("menu/jb_RegisterMenuOptions")
require("logic/jb_ClearingLogic")
require("logic/jb_ProcessingLogic")
require("logic/jb_GatheringLogic")

JBLogging.registerMenuCategory("Gathering", "UI_JBLogging_Category_Gathering")
JBLogging.registerMenuCategory("Clearing", "UI_JBLogging_Category_Clearing")
JBLogging.registerMenuCategory("Processing", "UI_JBLogging_Category_Processing")
JBLogging.registerMenuCategory("Storage", "UI_JBLogging_StorageMenuTitle")