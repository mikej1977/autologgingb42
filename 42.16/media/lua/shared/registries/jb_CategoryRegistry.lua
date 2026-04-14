-- registries/jb_CategoryRegistry.lua
local MenuOptions = require("helpers/jb_RegisterMenuOptions")
require("logic/jb_ClearingLogic")
require("logic/jb_ProcessingLogic")
require("logic/jb_GatheringLogic")

MenuOptions.registerMenuCategory("Logging", "UI_JBLogging_Category_Gathering", "media/ui/Radial/Logging.png")
MenuOptions.registerMenuCategory("Gathering", "UI_JBLogging_Category_Gathering", "media/ui/Radial/Gathering.png")
MenuOptions.registerMenuCategory("Clearing", "UI_JBLogging_Category_Clearing", "media/ui/Radial/Clearing.png")
MenuOptions.registerMenuCategory("Processing", "UI_JBLogging_Category_Processing", "media/ui/Radial/Processing.png")
MenuOptions.registerMenuCategory("Storage", "UI_JBLogging_StorageMenuTitle", "media/ui/Radial/Storage.png")
return MenuOptions
