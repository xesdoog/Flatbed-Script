---@ diagnostic disable: undefined-global, lowercase-global

flatbed_script = gui.get_tab("Flatbed Script")
local attached_vehicle = 0
local debug = false
local xAxis = 0.0
local yAxis = 0.0
local zAxis = 0.0
-- local validModel = false
local modelOverride = false
flatbed_script:add_imgui(function()
    local vehicleHandles = entities.get_all_vehicles_as_handles()
    local flatbedModel = 1353720154
    local current_vehicle = PED.GET_VEHICLE_PED_IS_USING(self.get_ped())
    local vehicle_model = ENTITY.GET_ENTITY_MODEL(current_vehicle)
    local playerPosition = ENTITY.GET_ENTITY_COORDS(self.get_ped(), false)
    local playerForwardX = ENTITY.GET_ENTITY_FORWARD_X(self.get_ped())
    local playerForwardY = ENTITY.GET_ENTITY_FORWARD_Y(self.get_ped())
-- local closestVehicle = VEHICLE.GET_CLOSEST_VEHICLE(playerPosition.x, playerPosition.y, playerPosition.z, 10.0, 0, 70) --doesn't return cop cars or occupied PVs.
    for _, veh in ipairs(vehicleHandles) do
        script.run_in_fiber(function(script)
            local detectPos = vec3:new(playerPosition.x - (playerForwardX * 10), playerPosition.y - (playerForwardY * 10), playerPosition.z)
            local vehPos = ENTITY.GET_ENTITY_COORDS(veh, false)
            local vDist = SYSTEM.VDIST(detectPos.x, detectPos.y, detectPos.z, vehPos.x, vehPos.y, vehPos.z)
            if vDist <= 5 then
                closestVehicle = veh
            else
                script:sleep(50)
                closestVehicle = nil
                return
            end
        end)
    end
    local closestVehicleModel = ENTITY.GET_ENTITY_MODEL(closestVehicle)
    local is_car = VEHICLE.IS_THIS_MODEL_A_CAR(closestVehicleModel)
    local is_bike = VEHICLE.IS_THIS_MODEL_A_BIKE(closestVehicleModel)
    local closestVehicleName = vehicles.get_vehicle_display_name(closestVehicleModel)
    if vehicle_model == flatbedModel then
        is_in_flatbed = true
    else
        is_in_flatbed = false
    end
    if closestVehicleName == "" then
        displayText = "No nearby vehicles found!"
    elseif tostring(closestVehicleName) == "Flatbed" then
        displayText = "You can not tow another flatbed truck."
    else
        displayText = ("Closest Vehicle: "..tostring(closestVehicleName))
    end
    if attached_vehicle ~= 0 then
        displayText = "Towing "..vehicles.get_vehicle_display_name(ENTITY.GET_ENTITY_MODEL(attached_vehicle)).."."
    end
    if modelOverride then
        validModel = true
    else
        validModel = false
    end
    if is_car then
        validModel = true
    end
    if is_bike then
        validModel = true
    end
    if closestVehicleModel == 745926877 then --Buzzard
        validModel = true
    end
    if is_in_flatbed then
        ImGui.Text(displayText)
        towPos, used = ImGui.Checkbox("Show Towing Position", towPos, true)
        ImGui.SameLine()
        ImGui.TextDisabled("(?)")
        if ImGui.IsItemHovered() then
            ImGui.BeginTooltip()
            ImGui.Text("Marks the position at which the script\ndetects nearby vehicles.")
            ImGui.EndTooltip()
        end
        towEverything, used = ImGui.Checkbox("Tow Everything", towEverything, true)
        ImGui.SameLine()
        ImGui.TextDisabled("(?)")
        if ImGui.IsItemHovered() then
            ImGui.BeginTooltip()
            ImGui.Text("By default, the script is limited to cars,\ntrucks and bikes only. This option\nremoves that limit.")
            ImGui.EndTooltip()
        end
        if towEverything then
            modelOverride = true
        else
            modelOverride = false
        end
        if attached_vehicle == 0 then
            if ImGui.Button("   Tow    ") then
                if validModel and closestVehicle ~= nil and closestVehicleModel ~= flatbedModel then
                    script.run_in_fiber(function()
                        controlled = entities.take_control_of(closestVehicle, 300)
                        if controlled then
                            flatbedHeading = ENTITY.GET_ENTITY_HEADING(current_vehicle)
                            flatbedBone = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(current_vehicle, "chassis_dummy")
                            vehBone = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(closestVehicle, "chassis_dummy")
                            local vehicleClass = VEHICLE.GET_VEHICLE_CLASS(closestVehicle)
                            if vehicleClass == 1 then
                                zAxis = 0.9
                                yAxis = -2.3
                            elseif vehicleClass == 2 then
                                zAxis = 0.993
                                yAxis = -2.17046
                            elseif vehicleClass == 6 then
                                zAxis = 1.00069420
                                yAxis = -2.17046
                            elseif vehicleClass == 7 then
                                zAxis = 1.009
                                yAxis = -2.17036
                            elseif vehicleClass == 15 then
                                zAxis = 1.3
                                yAxis = -2.21069
                            elseif vehicleClass == 16 then
                                zAxis = 1.5
                                yAxis = -2.21069
                            else
                                zAxis = 1.1
                                yAxis = -2.0
                            end
                            ENTITY.SET_ENTITY_HEADING(closestVehicleModel, flatbedHeading)
                            ENTITY.ATTACH_ENTITY_TO_ENTITY(closestVehicle, current_vehicle, flatbedBone, xAxis, yAxis, zAxis, 0.0, 0.0, 0.0, true, true, false, false, 1, true, 1)
                            attached_vehicle = closestVehicle
                            ENTITY.SET_ENTITY_CANT_CAUSE_COLLISION_DAMAGED_ENTITY(attached_vehicle, current_vehicle)
                        else
                            gui.show_error("Flatbed Script", "Failed to take control of the vehicle!")
                        end
                    end)
                end
                if closestVehicle ~= nil and closestVehicleModel ~= flatbedModel and not validModel then
                    gui.show_message("Flatbed Script", "You can only tow cars, trucks and bikes.")
                end
                if closestVehicle ~= nil and closestVehicleModel == flatbedModel then
                    gui.show_message("Flatbed Script", "Sorry but you can not tow another flatbed truck.")
                end
            end
        else
            if ImGui.Button(" Detach ") then
                script.run_in_fiber(function()
                    local modelHash = ENTITY.GET_ENTITY_MODEL(attached_vehicle)
                    local attachedVehicle = ENTITY.GET_ENTITY_OF_TYPE_ATTACHED_TO_ENTITY(PED.GET_VEHICLE_PED_IS_USING(self.get_ped()), modelHash)
                    local attachedVehcoords = ENTITY.GET_ENTITY_COORDS(attached_vehicle, false)
                    controlled = entities.take_control_of(attachedVehicle, 300)
                    if ENTITY.DOES_ENTITY_EXIST(attachedVehicle) then
                        if controlled then
                            ENTITY.DETACH_ENTITY(attachedVehicle)
                            ENTITY.SET_ENTITY_COORDS(attachedVehicle, attachedVehcoords.x - (playerForwardX * 10), attachedVehcoords.y - (playerForwardY * 10), playerPosition.z, false, false, false, false)
                            VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(attached_vehicle, 5.0)
                            attached_vehicle = 0
                        end
                    end
                end)
            end
            ImGui.Spacing();ImGui.Text("Adjust Vehicle Position")
            if ImGui.IsItemHovered() then
                ImGui.BeginTooltip()
                ImGui.PushTextWrapPos(ImGui.GetFontSize() * 20)
                ImGui.TextWrapped("For the arrows to make sense, move your camera to the right. (Look right)")
                ImGui.PopTextWrapPos()
                ImGui.EndTooltip()
            end
            ImGui.Separator();ImGui.Spacing()
            ImGui.Dummy(100, 1);ImGui.SameLine()
            ImGui.ArrowButton("##Up", 2)
            if ImGui.IsItemActive() then
                zAxis = zAxis + 0.01
                ENTITY.ATTACH_ENTITY_TO_ENTITY(attached_vehicle, current_vehicle, flatbedBone, xAxis, yAxis, zAxis, 0.0, 0.0, 0.0, true, true, false, false, 1, true, 1)
            end
            ImGui.Dummy(60, 1);ImGui.SameLine()
            ImGui.ArrowButton("##Left", 0)
            if ImGui.IsItemActive() then
                yAxis = yAxis + 0.01
                ENTITY.ATTACH_ENTITY_TO_ENTITY(attached_vehicle, current_vehicle, flatbedBone, xAxis, yAxis, zAxis, 0.0, 0.0, 0.0, true, true, false, false, 1, true, 1)
            end
            ImGui.SameLine();ImGui.Dummy(23, 1);ImGui.SameLine()
            ImGui.ArrowButton("##Right", 1)
            if ImGui.IsItemActive() then
                yAxis = yAxis - 0.01
                ENTITY.ATTACH_ENTITY_TO_ENTITY(attached_vehicle, current_vehicle, flatbedBone, xAxis, yAxis, zAxis, 0.0, 0.0, 0.0, true, true, false, false, 1, true, 1)
            end
            ImGui.Dummy(100, 1);ImGui.SameLine()
            ImGui.ArrowButton("##Down", 3)
            if ImGui.IsItemActive() then
                zAxis = zAxis - 0.01
                ENTITY.ATTACH_ENTITY_TO_ENTITY(attached_vehicle, current_vehicle, flatbedBone, xAxis, yAxis, zAxis, 0.0, 0.0, 0.0, true, true, false, false, 1, true, 1)
            end
        end
    else
        ImGui.Text("Get inside a flatbed truck to use the script.")
        if ImGui.Button("Spawn Flatbed Truck") then
            script.run_in_fiber(function(script)
                if not PED.IS_PED_SITTING_IN_ANY_VEHICLE(self.get_ped()) then
                    local try = 0
                    while not STREAMING.HAS_MODEL_LOADED(flatbedModel) do
                        STREAMING.REQUEST_MODEL(flatbedModel)
                        script:yield()
                        if try > 100 then
                            return
                        else
                            try = try + 1
                        end
                    end
                    fltbd = VEHICLE.CREATE_VEHICLE(flatbedModel, playerPosition.x, playerPosition.y, playerPosition.z, ENTITY.GET_ENTITY_HEADING(self.get_ped()), true, false, false)
                    -- script:sleep(200)
                    PED.SET_PED_INTO_VEHICLE(self.get_ped(), fltbd, -1)
                    ENTITY.SET_ENTITY_AS_NO_LONGER_NEEDED(fltbd)
                else
                    gui.show_error("Flatbed Script", "Exit your current vehicle first.")
                end
            end)
        end
    end
    ImGui.TextDisabled("_")
    if ImGui.IsItemHovered() and ImGui.IsItemClicked(0) then
        debug = not debug
    end
    if debug then
        ImGui.Separator()
        if ImGui.Button("debug") then
            for _, veh in ipairs(vehicleHandles) do
                script.run_in_fiber(function(script)
                    local detectPos = vec3:new(playerPosition.x - (playerForwardX * 10), playerPosition.y - (playerForwardY * 10), playerPosition.z)
                    local vehPos = ENTITY.GET_ENTITY_COORDS(veh, false)
                    local vDist = SYSTEM.VDIST(detectPos.x, detectPos.y, detectPos.z, vehPos.x, vehPos.y, vehPos.z)
                    local vHash =  ENTITY.GET_ENTITY_MODEL(veh)
                    vehicleClass = VEHICLE.GET_VEHICLE_CLASS(closestVehicle)
                end)
            end
            log.debug(tostring(closestVehicle))
            -- log.debug(tostring(vDist))
            log.debug(tostring(vehicleClass))
        end
    end
end)
script.register_looped("flatbed script", function(script)
    -- script:yield()
    local vehicleHandles = entities.get_all_vehicles_as_handles()
    local current_vehicle = PED.GET_VEHICLE_PED_IS_USING(self.get_ped())
    local vehicle_model = ENTITY.GET_ENTITY_MODEL(current_vehicle)
    local flatbedHeading = ENTITY.GET_ENTITY_HEADING(current_vehicle)
    local flatbedBone = ENTITY.GET_ENTITY_BONE_INDEX_BY_NAME(current_vehicle, "chassis")
    local playerPosition = ENTITY.GET_ENTITY_COORDS(self.get_ped(), false)
    local playerForwardX = ENTITY.GET_ENTITY_FORWARD_X(self.get_ped())
    local playerForwardY = ENTITY.GET_ENTITY_FORWARD_Y(self.get_ped())
    for _, veh in ipairs(vehicleHandles) do
        local detectPos = vec3:new(playerPosition.x - (playerForwardX * 10), playerPosition.y - (playerForwardY * 10), playerPosition.z)
        local vehPos = ENTITY.GET_ENTITY_COORDS(veh, false)
        local vDist = SYSTEM.VDIST(detectPos.x, detectPos.y, detectPos.z, vehPos.x, vehPos.y, vehPos.z)
        if vDist <= 5 then
            closestVehicle = veh
        end
    end
    local closestVehicleModel = ENTITY.GET_ENTITY_MODEL(closestVehicle)
    local is_car = VEHICLE.IS_THIS_MODEL_A_CAR(closestVehicleModel)
    local is_bike = VEHICLE.IS_THIS_MODEL_A_BIKE(closestVehicleModel)
    local validModel = false
    if modelOverride then
        validModel = true
    else
        validModel = false
    end
    if is_car then
        validModel = true
    end
    if is_bike then
        validModel = true
    end
    if closestVehicleModel == 745926877 then --Buzzard
        validModel = true
    end
    if closestVehicleModel == 1353720154 then
        validModel = false
    end
    if vehicle_model == 1353720154 then
        is_in_flatbed = true
    else
        is_in_flatbed = false
    end
    if is_in_flatbed and attached_vehicle == 0 then
        if PAD.IS_CONTROL_PRESSED(0, 73) and validModel and closestVehicleModel ~= flatbedModel then
            script:sleep(200)
            controlled = entities.take_control_of(closestVehicle, 350)
            if controlled then
                local vehicleClass = VEHICLE.GET_VEHICLE_CLASS(closestVehicle)
                if vehicleClass == 1 then
                    zAxis = 0.9
                    yAxis = -2.3
                elseif vehicleClass == 2 then
                    zAxis = 0.993
                    yAxis = -2.17046
                elseif vehicleClass == 6 then
                    zAxis = 1.00069420
                    yAxis = -2.17046
                elseif vehicleClass == 7 then
                    zAxis = 1.009
                    yAxis = -2.17036
                elseif vehicleClass == 15 then
                    zAxis = 1.3
                    yAxis = -2.21069
                elseif vehicleClass == 16 then
                    zAxis = 1.5
                    yAxis = -2.21069
                else
                    zAxis = 1.1
                    yAxis = -2.0
                end
                ENTITY.SET_ENTITY_HEADING(closestVehicleModel, flatbedHeading)
                ENTITY.ATTACH_ENTITY_TO_ENTITY(closestVehicle, current_vehicle, flatbedBone, 0.0, yAxis, zAxis, 0.0, 0.0, 0.0, false, true, true, false, 1, true, 1)
                attached_vehicle = closestVehicle
                script:sleep(200)
            else
                gui.show_error("Flatbed Script", "Failed to take control of the vehicle!")
            end
        end
        if PAD.IS_CONTROL_PRESSED(0, 73) and closestVehicle ~= nil and not validModel then
            gui.show_message("Flatbed Script", "You can only tow cars, trucks and bikes.")
            script:sleep(400)
        end
        if PAD.IS_CONTROL_PRESSED(0, 73) and closestVehicleModel == flatbedModel then
            script:sleep(400)
            gui.show_message("Flatbed Script", "Sorry but you can not tow another flatbed truck.")
        end
    elseif is_in_flatbed and attached_vehicle ~= 0 then
        if PAD.IS_CONTROL_PRESSED(0, 73) then
            script:sleep(200)
            for _, v in ipairs(vehicleHandles) do
                local modelHash = ENTITY.GET_ENTITY_MODEL(v)
                local attachedVehicle = ENTITY.GET_ENTITY_OF_TYPE_ATTACHED_TO_ENTITY(current_vehicle, modelHash)
                local attachedVehcoords = ENTITY.GET_ENTITY_COORDS(attached_vehicle, false)
                controlled = entities.take_control_of(attachedVehicle, 350)
                if ENTITY.DOES_ENTITY_EXIST(attachedVehicle) then
                    if controlled then
                        ENTITY.DETACH_ENTITY(attachedVehicle)
                        ENTITY.SET_ENTITY_COORDS(attachedVehicle, attachedVehcoords.x - (playerForwardX * 10), attachedVehcoords.y - (playerForwardY * 10), playerPosition.z, 0, 0, 0, 0)
                        VEHICLE.SET_VEHICLE_ON_GROUND_PROPERLY(attached_vehicle, 5.0)
                        attached_vehicle = 0
                    end
                end
            end
        end
    end
end)
script.register_looped("TowPos Marker", function()
    if towPos then
        if is_in_flatbed and attached_vehicle == 0 then
            local playerPosition = ENTITY.GET_ENTITY_COORDS(self.get_ped(), false)
            local playerForwardX = ENTITY.GET_ENTITY_FORWARD_X(self.get_ped())
            local playerForwardY = ENTITY.GET_ENTITY_FORWARD_Y(self.get_ped())
            local detectPos = vec3:new(playerPosition.x - (playerForwardX * 10), playerPosition.y - (playerForwardY * 10), playerPosition.z)
            GRAPHICS.DRAW_MARKER_SPHERE(detectPos.x, detectPos.y, detectPos.z, 2.5, 180, 128, 0, 0.115)
        end
    end
end)