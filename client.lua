local RESOURCE_NAME = GetCurrentResourceName()

local function debugLog(msg)
    print(('[%s] %s'):format(RESOURCE_NAME, msg))
end

local function getPlayerPedSafe()
    local ped = PlayerPedId()
    if ped ~= 0 and DoesEntityExist(ped) then
        return ped
    end
    return nil
end

local function resetVisibilityState()
    local ped = getPlayerPedSafe()
    if not ped then return end

    SetEntityVisible(ped, true, false)
    ResetEntityAlpha(ped)
    NetworkFadeInEntity(ped, true)
    SetLocalPlayerVisibleLocally(true)
    SetPlayerVisibleLocally(PlayerId(), true)
    FreezeEntityPosition(ped, false)
    SetEntityCollision(ped, true, true)
    SetEntityInvincible(ped, false)

    if not IsEntityDead(ped) then
        ClearPedTasksImmediately(ped)
    end

    debugLog('Visibility reset applied')
end

local function refreshStreamingState()
    local ped = getPlayerPedSafe()
    if not ped then return end

    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    ClearFocus()
    ClearHdArea()
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)

    NewLoadSceneStartSphere(coords.x, coords.y, coords.z, 60.0, 0)
    Wait(1000)
    NewLoadSceneStop()

    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z + 0.05, false, false, false)
    Wait(250)
    SetEntityCoordsNoOffset(ped, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(ped, heading)

    debugLog('Streaming refresh applied')
end

local function fullRefresh(reason)
    CreateThread(function()
        debugLog(('Running full refresh | reason=%s'):format(reason or 'unknown'))

        Wait(1000)
        resetVisibilityState()

        Wait(750)
        refreshStreamingState()

        Wait(1500)
        resetVisibilityState()

        Wait(1500)
        refreshStreamingState()
    end)
end

RegisterNetEvent('bucket_debug:client:fullRefresh', function(reason)
    fullRefresh(reason)
end)

RegisterNetEvent('bucket_debug:client:onServerLoaded', function()
    fullRefresh('server loaded callback')
end)

-- QBOX CLIENT EVENT - correct one
AddEventHandler('QBCore:Client:OnPlayerLoaded', function()
    Wait(2000)
    TriggerServerEvent('bucket_debug:server:clientLoaded')
    fullRefresh('QBCore:Client:OnPlayerLoaded')
end)

RegisterNetEvent('bucket_debug:server:acknowledgeFix', function()
    lib.notify({
        title = 'Bucket Fix',
        description = 'Bucket 0 enforcement and refresh applied.',
        type = 'success'
    })
end)

RegisterCommand('fixmyworld', function()
    fullRefresh('manual /fixmyworld')

    lib.notify({
        title = 'Visibility Refresh',
        description = 'Local visibility and streaming refresh applied.',
        type = 'success'
    })
end, false)
