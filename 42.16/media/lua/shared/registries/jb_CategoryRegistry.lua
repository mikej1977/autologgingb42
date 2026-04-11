-- registries/jb_CategoryRegistry.lua
local MenuOptions = require("helpers/jb_RegisterMenuOptions")
require("logic/jb_ClearingLogic")
require("logic/jb_ProcessingLogic")
require("logic/jb_GatheringLogic")

MenuOptions.registerMenuCategory("Gathering", "UI_JBLogging_Category_Gathering")
MenuOptions.registerMenuCategory("Clearing", "UI_JBLogging_Category_Clearing")
MenuOptions.registerMenuCategory("Processing", "UI_JBLogging_Category_Processing")
MenuOptions.registerMenuCategory("Storage", "UI_JBLogging_StorageMenuTitle")

return MenuOptions
