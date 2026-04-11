-- jb_RegisterMenuOptions.lua
local RegisterOptions = {}

RegisterOptions.OptionsList = {}
RegisterOptions.MenuCategories = {}

--- @param id string Identifier (e.g., "Gathering")
--- @param translationKey string Translation key for the UI (e.g., "UI_JBLogging_Category_Gathering")
function RegisterOptions.registerMenuCategory(id, translationKey)
    if type(id) ~= "string" or type(translationKey) ~= "string" then
        print("ERROR: RegisterOptions.registerMenuCategory - 'id' and 'translationKey' must both be strings.")
        return
    end
    RegisterOptions.MenuCategories[id] = translationKey
end

--- @param option table
function RegisterOptions.registerMenuOption(option)
    if type(option) ~= "table" then
        print("ERROR: RegisterOptions.registerMenuOption - 'option' must be a table.")
        return false
    end

    local requiredFields = {
        category = "string",
        translate = "string",
        condition = "function",
    }

    for field, expectedType in pairs(requiredFields) do
        if type(option[field]) ~= expectedType then
            print(string.format(
                "ERROR: RegisterOptions.registerMenuOption - Missing or invalid field '%s' (expected %s, got %s)",
                field, expectedType, type(option[field])))
            return false
        end
    end

    if not RegisterOptions.MenuCategories[option.category] then
        print("WARNING: RegisterOptions - Category '" ..
            tostring(option.category) .. "' is not registered in MenuCategories.")
    end

    if option.tooltip and type(option.tooltip) ~= "string" then
        print("ERROR: RegisterOptions.registerMenuOption - 'tooltip' must be a string.")
        return false
    end

    if option.params and type(option.params) ~= "table" then
        print("ERROR: RegisterOptions.registerMenuOption - 'params' must be a table.")
        return false
    end

    local actionType = type(option.action)
    if actionType ~= "function" and actionType ~= "table" then
        print("ERROR: RegisterOptions - 'action' must be a function or a table.")
        return false
    end

    if actionType == "table" then
        local firstElement = type(option.action[1])
        if firstElement ~= "function" and firstElement ~= "string" then
            print("ERROR: RegisterOptions - action table must start with a function or a string name.")
            return false
        end
    end

    table.insert(RegisterOptions.OptionsList, option)
    return true
end

-- This is the crucial part: return the local table so require() can catch it
return RegisterOptions
