local TARGET_BUCKET = 0
local RESOURCE_NAME = GetCurrentResourceName()

local function log(msg)
    print(('^3[%s]^7 %s'):format(RESOURCE_NAME, msg))
end

local function warn(msg)
    print(('^1[%s]^7 %s'):format(RESOURCE_NAME, msg))
end

local function playerExists(src)
    src = tonumber(src)
    return src and GetPlayerName(src) ~= nil
end

local function getPlayerNameSafe(src)
    src = tonumber(src)
    if not src then return 'unknown' end
    return GetPlayerName(src) or 'unknown'
end

local function getBucketSafe(src)
    src = tonumber(src)
    if not playerExists(src) then return nil end
    return GetPlayerRoutingBucket(src)
end

local function setFiniOriginalBucket(src, reason)
    src = tonumber(src)
    if not src then return end

    TriggerEvent('FiniAC:SetPlayerOriginalRoutingBucket', tostring(src), TARGET_BUCKET)

    log(('FiniAC original bucket set for %s -> %s | reason=%s'):format(
        tostring(src),
        TARGET_BUCKET,
        reason or 'unknown'
    ))
end

local function forceBucketZero(src, reason)
    src = tonumber(src)
    if not playerExists(src) then
        warn(('forceBucketZero skipped, player %s does not exist | reason=%s'):format(
            tostring(src),
            reason or 'unknown'
        ))
        return false
    end

    local before = GetPlayerRoutingBucket(src)
    SetPlayerRoutingBucket(src, TARGET_BUCKET)
    local after = GetPlayerRoutingBucket(src)

    if after == TARGET_BUCKET then
        if before ~= TARGET_BUCKET then
            log(('Moved %s (%s) from bucket %s to %s | reason=%s'):format(
                src,
                getPlayerNameSafe(src),
                before,
                after,
                reason or 'unknown'
            ))
        else
            log(('Player %s (%s) already in bucket %s | reason=%s'):format(
                src,
                getPlayerNameSafe(src),
                after,
                reason or 'unknown'
            ))
        end
        return true
    else
        warn(('Failed to move %s (%s) to bucket %s | actual=%s | reason=%s'):format(
            src,
            getPlayerNameSafe(src),
            TARGET_BUCKET,
            tostring(after),
            reason or 'unknown'
        ))
        return false
    end
end

local function refreshClient(src, reason)
    src = tonumber(src)
    if not playerExists(src) then return end
    TriggerClientEvent('bucket_debug:client:fullRefresh', src, reason or 'unknown')
end

local function enforceBucketZero(src, reason, doRefresh)
    src = tonumber(src)
    if not playerExists(src) then return end

    setFiniOriginalBucket(src, reason)
    forceBucketZero(src, reason)

    if doRefresh == true then
        refreshClient(src, reason)
    end
end

local function scheduleRechecks(src, baseReason)
    src = tonumber(src)
    if not playerExists(src) then return end

    local delays = { 2000, 5000, 10000, 15000, 25000 }

    for _, delay in ipairs(delays) do
        SetTimeout(delay, function()
            if playerExists(src) then
                -- Important: bucket only, no client refresh here
                enforceBucketZero(src, ('%s | +%sms'):format(baseReason or 'recheck', delay), false)
            end
        end)
    end
end

local function debugSnapshot(src, reason)
    src = tonumber(src)
    if not playerExists(src) then
        warn(('DEBUG SNAPSHOT skipped for %s | player missing | reason=%s'):format(
            tostring(src),
            reason or 'unknown'
        ))
        return
    end

    log(('DEBUG SNAPSHOT | src=%s name=%s bucket=%s reason=%s'):format(
        src,
        getPlayerNameSafe(src),
        tostring(getBucketSafe(src)),
        reason or 'unknown'
    ))
end

AddEventHandler('onResourceStart', function(res)
    if res ~= RESOURCE_NAME then return end
    log(('Started. Target bucket=%s'):format(TARGET_BUCKET))
end)

-- FiniAC hooks
AddEventHandler('FiniAC:DeferStarted', function(src)
    src = tonumber(src)
    if not src then return end

    log(('FiniAC:DeferStarted temp src=%s'):format(src))
    setFiniOriginalBucket(src, 'FiniAC:DeferStarted')
end)

AddEventHandler('FiniAC:DeferFinished', function(src, joinAllowed)
    src = tonumber(src)
    if not src then return end

    log(('FiniAC:DeferFinished temp src=%s | joinAllowed=%s'):format(
        src,
        tostring(joinAllowed)
    ))

    if not joinAllowed then
        warn(('FiniAC rejected temp src=%s'):format(src))
        return
    end

    setFiniOriginalBucket(src, 'FiniAC:DeferFinished')
end)

-- QBOX server loaded event
RegisterNetEvent('QBCore:Server:OnPlayerLoaded', function()
    local src = source

    debugSnapshot(src, 'QBCore:Server:OnPlayerLoaded BEFORE')
    enforceBucketZero(src, 'QBCore:Server:OnPlayerLoaded', true)
    debugSnapshot(src, 'QBCore:Server:OnPlayerLoaded AFTER')

    scheduleRechecks(src, 'QBCore:Server:OnPlayerLoaded')
end)

RegisterNetEvent('bucket_debug:server:clientLoaded', function()
    local src = source

    debugSnapshot(src, 'bucket_debug:server:clientLoaded BEFORE')
    enforceBucketZero(src, 'bucket_debug:server:clientLoaded', false)
    debugSnapshot(src, 'bucket_debug:server:clientLoaded AFTER')

    scheduleRechecks(src, 'bucket_debug:server:clientLoaded')
end)

RegisterCommand('bucket', function(source)
    local src = source
    if src == 0 then
        print(('[%s] This command can only be used in-game.'):format(RESOURCE_NAME))
        return
    end

    local bucket = getBucketSafe(src) or 'unknown'

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Bucket Check',
        description = ('You are in bucket %s'):format(bucket),
        type = 'inform'
    })

    debugSnapshot(src, 'manual /bucket')
end, false)

RegisterCommand('fixmybucket', function(source)
    local src = source
    if src == 0 then
        print(('[%s] This command can only be used in-game.'):format(RESOURCE_NAME))
        return
    end

    enforceBucketZero(src, 'manual /fixmybucket', true)

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Bucket Fix',
        description = 'You have been forced into bucket 0 and refreshed.',
        type = 'success'
    })
end, false)

RegisterCommand('bucketdebug', function(source)
    local src = source
    if src == 0 then
        print(('[%s] This command can only be used in-game.'):format(RESOURCE_NAME))
        return
    end

    debugSnapshot(src, 'manual /bucketdebug')

    TriggerClientEvent('ox_lib:notify', src, {
        title = 'Bucket Debug',
        description = 'Server debug written to console.',
        type = 'inform'
    })
end, false)

RegisterCommand('fixbuckets', function(source)
    if source ~= 0 then
        print(('[%s] /fixbuckets can only be run from server console.'):format(RESOURCE_NAME))
        return
    end

    for _, id in ipairs(GetPlayers()) do
        local src = tonumber(id)
        enforceBucketZero(src, 'manual console /fixbuckets', true)
    end

    print(('[%s] All online players forced into bucket 0.'):format(RESOURCE_NAME))
end, true)
