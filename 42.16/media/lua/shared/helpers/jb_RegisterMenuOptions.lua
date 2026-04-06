-- jb_RegisterMenuOptions.lua
JBLogging = JBLogging or {}
JBLogging.MenuOptions = JBLogging.MenuOptions or {}


--- register a new menu option in the Auto Logging context menu
--- @param option table
function JBLogging.registerMenuOption(option)
    if type(option) ~= "table" then
        print("ERROR: JBLogging.registerMenuOption - 'option' must be a table.")
        return false
    end

    local requiredFields = {
        category = "string",
        translate = "string",
        condition = "function",
    }

    for field, expectedType in pairs(requiredFields) do
        if type(option[field]) ~= expectedType then
            print(string.format("ERROR: JBLogging.registerMenuOption - Missing or invalid field '%s' (expected %s, got %s)", 
                field, expectedType, type(option[field])))
            return false
        end
    end

    if option.tooltip and type(option.tooltip) ~= "string" then
        print("ERROR: JBLogging.registerMenuOption - 'tooltip' must be a string.")
        return false
    end

    if option.params and type(option.params) ~= "table" then
        print("ERROR: JBLogging.registerMenuOption - 'params' must be a table.")
        return false
    end

    local actionType = type(option.action)
    if actionType ~= "function" and actionType ~= "table" then
        print("ERROR: JBLogging - 'action' must be a function or a table.")
        return false
    end

    if actionType == "table" then
        local firstElement = type(option.action[1])
        if firstElement ~= "function" and firstElement ~= "string" then
            print("ERROR: JBLogging - action table must start with a function or a string name.")
            return false
        end
    end
    table.insert(JBLogging.MenuOptions, option)
    return true
end