local Iris = loadstring(game:HttpGet("https://raw.githubusercontent.com/x0581/Iris-Exploit-Bundle/main/bundle.lua"))().Init(game.CoreGui)

local Closuers = {}
local HookedArgs = {}

local function gFunctionPath(DEBUG_INFO)
    local FunctionPath = "-- Generated using MikeSpy\n"

    FunctionPath = FunctionPath .. ([[
local %s = (function()
    for i, v in next, getgc(true) do
        if typeof(v) == "function" and islclosure(v) then
            local info = debug.getinfo(v)
            if info.what == "%s" and info.numparams == %s and info.currentline == %s and info.nups == %s and info.name == "%s" and info.is_vararg == %s then
                return v
            end
        end
    end
end)()]]):format(
            DEBUG_INFO.name, DEBUG_INFO.what, DEBUG_INFO.numparams, DEBUG_INFO.currentline, DEBUG_INFO.nups, DEBUG_INFO.name, DEBUG_INFO.is_vararg
        )
    return (FunctionPath)
end

local function SearchClosures(Name)
    local Closures = {}
    for _, v in next, getgc(true) do
        if typeof(v) == "function" and islclosure(v) then
            local dbginfo = debug.getinfo(v)
            if dbginfo.name:lower():find(Name:lower()) then
                Closures[#Closures+1] = {
                    _name = dbginfo.name,
                    _info = dbginfo,
                    _func = v,
                    _upval = debug.getupvalues(v),
                    _const = debug.getconstants(v)
                }
            end
        end
    end
    return Closures
end

local function RenderClosureSpy()
    local ClosureName = ""
    Iris.Window({"Mike Spy - Closure Scanner", [Iris.Args.Window.NoClose] = false}, {size = Iris.State(Vector2.new(900, 800))}) do
        Iris.SameLine() do
            ClosureName = Iris.InputText({"", [Iris.Args.InputText.TextHint] = "Closure Name"}).text.value
            if Iris.Button({"Search"}).clicked then
                Closuers = SearchClosures(ClosureName)
            end
            if Iris.Button({"Clear"}).clicked then
                Closuers = {}
            end
            Iris.End()
        end
        for _, ClosureInfo in next, Closuers do
            Iris.Tree({ClosureInfo._name}) do
                Iris.SameLine() do
                    if Iris.Button({"Copy Closure Path"}).clicked then
                        setclipboard(gFunctionPath(ClosureInfo._info))
                    end
                    -- Doesn't work properly on any major UWP client, I don't know why.
                    if Iris.Button({"Hook"}).clicked then
                        local Original Original = hookfunction(ClosureInfo._func, function(...)
                            local Logs = HookedArgs[ClosureInfo._func] or {}; HookedArgs[ClosureInfo._func] = Logs;
                            Logs[#Logs+1] = {...}
                            return Original(...)
                        end)
                    end
                    if Iris.Button({"Clear Hooked Logs"}).clicked then
                        local Logs = HookedArgs[ClosureInfo._func] or {}
                        for i in next, Logs do Logs[i] = nil end
                    end
                    Iris.End()
                end
                Iris.Tree({"Debug Info"}) do
                    Iris.Table({3, [Iris.Args.Table.RowBg] = true}) do
                        Iris.NextColumn()
                        for Name, Value in next, ClosureInfo._info do
                            Iris.Text({Name})
                            Iris.NextColumn()
                            Iris.Text({tostring(typeof(Value))})
                            Iris.NextColumn()
                            Iris.Text({tostring(Value)})
                            Iris.NextColumn()
                        end
                        Iris.End()
                    end
                    Iris.End()
                end
                Iris.Tree({"Upvalues"}) do
                    Iris.SameLine() do
                        if Iris.Button({"Refresh"}).clicked then
                            ClosureInfo._upval = debug.getupvalues(ClosureInfo._func)
                        end
                        if Iris.Button({"Copy UpValue Wrapper"}).clicked then
                            local BasePath = gFunctionPath(ClosureInfo._info)
                            local EditorWrapper = "\nlocal _wrapper = newproxy(true)\n"
                            EditorWrapper = EditorWrapper .. "local _basefunction = %s\n"
                            EditorWrapper = EditorWrapper .. "local _wrapper_meta = debug.getmetatable(_wrapper)\n"
                            EditorWrapper = EditorWrapper .. "_wrapper_meta.__index=function(_,k) debug.getupvalue(_basefunction, k) end\n"
                            EditorWrapper = EditorWrapper .. "_wrapper_meta.__newindex=function(_,k,v) debug.setupvalue(_basefunction, k, v) end\n"
                            EditorWrapper = EditorWrapper .. "-- Example of setting Upvalue with id of 1 to 100\n"
                            EditorWrapper = EditorWrapper .. "_wrapper[1] = 100\n"

                            EditorWrapper = EditorWrapper:format(ClosureInfo._info.name)

                            setclipboard(BasePath .. EditorWrapper)
                        end
                        Iris.End()
                    end
                    Iris.Table({4, [Iris.Args.Table.RowBg] = true}) do
                        Iris.Text({"ID"})
                        Iris.NextColumn()
                        Iris.Text({"Type"})
                        Iris.NextColumn()
                        Iris.Text({"Value"})
                        Iris.NextColumn()
                        Iris.Text({"Editor"})
                        Iris.NextColumn()
                        for Id, Value in next, ClosureInfo._upval do
                            Iris.Text({tostring(Id)})
                            Iris.NextColumn()
                            Iris.Text({tostring(typeof(Value))})
                            Iris.NextColumn()
                            Iris.Text({tostring(Value)})
                            Iris.NextColumn()
                            if typeof(Value) == "string" then
                                Iris.SameLine() do
                                    local text = Iris.InputText({"", [Iris.Args.InputText.TextHint] = "Value"}).text.value
                                    if Iris.Button({"Set"}).clicked then
                                        debug.setupvalue(ClosureInfo._func, Id, text)
                                    end
                                    Iris.End()
                                end
                            elseif typeof(Value) == "number" then
                                Iris.SameLine() do
                                    local number = Iris.InputNum({""}).number.value
                                    if Iris.Button({"Set"}).clicked then
                                        debug.setupvalue(ClosureInfo._func, Id, number)
                                    end
                                    Iris.End()
                                end
                            elseif typeof(Value) == "boolean" then
                                Iris.SameLine() do
                                    local Enabled = Iris.State(Value)
                                    local boolean = Iris.Checkbox({""}, {isChecked = Enabled})
                                    if Iris.Button({"Set"}).clicked then
                                        debug.setupvalue(ClosureInfo._func, Id, Enabled.value)
                                    end
                                    Iris.End()
                                end
                            else
                                Iris.Text({"NONE"})
                            end
                            Iris.NextColumn()
                        end
                        Iris.End()
                    end
                    Iris.End()
                end
                Iris.Tree({"Constants"}) do
                    if Iris.Button({"Refresh"}).clicked then
                        ClosureInfo._const = debug.getconstants(ClosureInfo._func)
                    end
                    Iris.Table({4, [Iris.Args.Table.RowBg] = true}) do
                        Iris.Text({"ID"})
                        Iris.NextColumn()
                        Iris.Text({"Type"})
                        Iris.NextColumn()
                        Iris.Text({"Value"})
                        Iris.NextColumn()
                        Iris.Text({"Editor"})
                        Iris.NextColumn()
                        for Id, Value in next, ClosureInfo._const do
                            Iris.Text({tostring(Id)})
                            Iris.NextColumn()
                            Iris.Text({tostring(typeof(Value))})
                            Iris.NextColumn()
                            Iris.Text({tostring(Value)})
                            Iris.NextColumn()
                            if typeof(Value) == "string" then
                                Iris.SameLine() do
                                    local text = Iris.InputText({"", [Iris.Args.InputText.TextHint] = "Value"}).text.value
                                    if Iris.Button({"Set"}).clicked then
                                        debug.setconstant(ClosureInfo._func, Id, text)
                                    end
                                    Iris.End()
                                end
                            elseif typeof(Value) == "number" then
                                Iris.SameLine() do
                                    local number = Iris.InputNum({""}).number.value
                                    if Iris.Button({"Set"}).clicked then
                                        debug.setconstant(ClosureInfo._func, Id, number)
                                    end
                                    Iris.End()
                                end
                            elseif typeof(Value) == "boolean" then
                                Iris.SameLine() do
                                    local Enabled = Iris.State(Value)
                                    local boolean = Iris.Checkbox({""}, {isChecked = Enabled})
                                    if Iris.Button({"Set"}).clicked then
                                        debug.setconstant(ClosureInfo._func, Id, boolean)
                                    end
                                    Iris.End()
                                end
                            else
                                Iris.Text({"NONE"})
                            end
                            Iris.NextColumn()
                        end
                        Iris.End()
                    end
                    Iris.End()
                end
                Iris.Tree({"Hook Logs"}) do
                    for ID, Log in next, (HookedArgs[ClosureInfo._func] or {}) do
                        Iris.Tree({("Call #%s"):format(ID)}) do
                            Iris.Text({"ID"})
                            Iris.NextColumn()
                            Iris.Text({"Type"})
                            Iris.NextColumn()
                            Iris.Text({"Value"})
                            Iris.Table({3, [Iris.Args.Table.RowBg] = true}) do
                                for ArgID, Arg in next, Log do
                                    Iris.Text({tostring(ArgID)})
                                    Iris.NextColumn()
                                    Iris.Text({tostring(typeof(Arg))})
                                    Iris.NextColumn()
                                    Iris.Text({tostring(Arg)})
                                    Iris.NextColumn()
                                end
                                Iris.End()
                            end
                            Iris.End()
                        end
                    end
                    Iris.End()
                end
                Iris.End()
            end
        end
        Iris.End()
    end
end

Iris:Connect(function()
    -- local RemoteSpy = Iris.State(false)
    -- local ClosureSpy = Iris.State(false)

    -- Iris.Window({"MikeSpy Settings"}, {size = Iris.State(Vector2.new(400, 220)), position = Iris.State(Vector2.new(0, 0))}) do
    --     Iris.SameLine() do
    --         Iris.Checkbox({"Remote Spy"}, {isChecked = RemoteSpy})
    --         Iris.Checkbox({"Closure Spy"}, {isChecked = ClosureSpy})
    --         Iris.End()
    --     end
    --     Iris.Text({"Known Issues:"})
    --     Iris.Text({"As skilled as I am, not even I can fix these issues."})
    --     Iris.Tree({"Closure Spy"}) do
    --         Iris.Text({"[Hook] crashes when triggered on Fluxus"})
    --         Iris.Text({"[Hook] breaks the function when triggered on Electron"})
    --         Iris.End()
    --     end
    --     Iris.Tree({"Remote Spy"}) do
    --         Iris.Text({"NONE"})
    --         Iris.End()
    --     end
    --     if Iris.Button({"Copy Invite to LittleMike57's Fan Club"}).clicked then
    --         setclipboard("https://discord.gg/a3yyUzXb")
    --     end
    --     Iris.End()
    -- end

    -- if RemoteSpy.value then
    --     RenderRemoteSpy()
    -- end

    -- if ClosureSpy.value then
        RenderClosureSpy()
    -- end

end)
