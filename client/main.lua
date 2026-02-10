local resourceName = GetCurrentResourceName()

-- --------------------------------------------------------
-- Action Keys
-- --------------------------------------------------------
local activeNotifications = {}

local function RegisterNotificationKeys(notificationId, keyActions, placement)
    if not keyActions then return end
    
    local validKeyActions = {}
    for keyName, action in pairs(keyActions) do
        local keyHash = Keys[string.upper(keyName)]
        if keyHash then
            validKeyActions[keyHash] = {
                action = action,
                keyName = string.upper(keyName)
            }
        else
            print(string.format("Warning: Invalid key name '%s' for notification", keyName))
        end
    end
    
    activeNotifications[notificationId] = {
        keyActions = validKeyActions,
        active = true,
        placement = placement
    }
end

local function RemoveNotificationKeys(notificationId)
    if activeNotifications[notificationId] then
        activeNotifications[notificationId].active = false
        activeNotifications[notificationId] = nil
    end
end

local function SendItemNotification(options, template)
    if type(options) ~= "table" and type(template) ~= "table" then
        return print("Error: options or template must be a table")
    end

    local finalOptions = {}
    
    -- (โค้ดส่วนรวม Template เหมือนเดิม หรือจะตัดออกก็ได้ถ้าไม่ใช้ Template)
    if template and type(template) == "string" and Config.Templates[template] then
        for k, v in pairs(Config.Templates[template]) do
            finalOptions[k] = v
        end
    end
    
    for k, v in pairs(options) do
        finalOptions[k] = v
    end

    local notificationId = GetGameTimer() .. math.random(1000000) .. GetPlayerServerId(PlayerId())
    finalOptions.id = notificationId
    
    -- ส่ง type เป็น MTN_NOTIFY_ITEM
    SendNUIMessage({
        type = "MTN_NOTIFY_ITEM", 
        options = finalOptions
    })
    
    -- (Item ส่วนใหญ่ไม่ต้องมี keyActions แต่ถ้าจะใส่ก็เก็บ logic เดิมไว้ได้)
end

CreateThread(function()
    while true do
        Wait(0)
        for notificationId, data in pairs(activeNotifications) do
            if data.active then
                for keyHash, keyData in pairs(data.keyActions) do
                    if IsControlJustPressed(0, keyHash) then
                        SendNUIMessage({
                            type = 'MTN_NOTIFY_KEY_PRESSED', -- เปลี่ยนจาก BLN เป็น MTN
                            notificationId = notificationId,
                            key = keyData.keyName,
                            placement = data.placement
                        })
                        TriggerEvent('mtn_notify:keyPressed', keyData.action) -- เปลี่ยน Event Name
                    end
                end
            end
        end
    end
end)

-- --------------------------------------------------------
-- Notification System
-- --------------------------------------------------------

local function SendNotification(options, template)
    if type(options) ~= "table" and type(template) ~= "table" then
        return print("Error: options or template must be a table")
    end

    local finalOptions = {}
    
    if template and type(template) == "string" and Config.Templates[template] then
        for k, v in pairs(Config.Templates[template]) do
            finalOptions[k] = v
        end
    end
    
    for k, v in pairs(options) do
        finalOptions[k] = v
    end

    local notificationId = GetGameTimer() .. math.random(1000000) .. GetPlayerServerId(PlayerId())
    
    finalOptions.id = notificationId
    
    if finalOptions.keyActions then
        RegisterNotificationKeys(notificationId, finalOptions.keyActions, finalOptions.placement)
    end

    SendNUIMessage({
        type = "MTN_NOTIFY", -- เปลี่ยนจาก BLN เป็น MTN
        options = finalOptions
    })

    if options.duration then
        SetTimeout(options.duration, function()
            RemoveNotificationKeys(notificationId)
        end)
    end
end

RegisterNuiCallback("playSound", function(data, cb)

    if data.sound and data.soundSet then
        PlaySoundFrontend(data.sound, data.soundSet, true, 0)
    else
        local sound = "INFO_HIDE"
        local soundSet = "Ledger_Sounds"
        PlaySoundFrontend(sound, soundSet, true, 0)
    end
    cb("ok")
end)

RegisterNetEvent(resourceName .. ":send")
AddEventHandler(resourceName .. ":send", function(options, template)
    SendNotification(options, template)
end)

RegisterCommand('testnotify', function()
    TriggerEvent("mtn_notify:send", { -- เปลี่ยน Event Name
        title = "ทดสอบระบบ",
        description = "นี่คือข้อความแจ้งเตือนจากคำสั่ง ~green~testnotify~e~",
        icon = "tick",
        placement = "bottom-right",
        duration = 5000
    })
end)

RegisterCommand('testprogress', function()
    TriggerEvent("mtn_notify:send", { -- เปลี่ยน Event Name
        title = "กำลังขุดแร่...",
        description = "กรุณารอสักครู่จนกว่าแถบจะเต็ม",
        icon = "warning",
        placement = "middle-right",
        duration = 10000, -- 10 วินาที
        progress = {
            enabled = true,
            type = 'bar', -- มีแบบ 'bar' และ 'circle'
            color = 'FFFFFFFF'
        }
    })
end)

RegisterCommand('testask', function()
    TriggerEvent("mtn_notify:send", { -- เปลี่ยน Event Name
        title = "~#FFFFFFFF~ยืนยันการขาย~e~",
        description = "กด ~key:E~ เพื่อขายสินค้า หรือ ~key:F6~ เพื่อยกเลิก",
        icon = "toast_mp_daily_objective_small",
        duration = 10000,
        keyActions = {
            ['E'] = "accept_trade",
            ['F6'] = "cancel_trade"
        }
    })
end)

-- ส่วนรับค่าจากการกดปุ่ม (ใส่ไว้ใน Client เช่นกัน)
RegisterNetEvent("mtn_notify:keyPressed") -- เปลี่ยน Event Name
AddEventHandler("mtn_notify:keyPressed", function(action)
    if action == "accept_trade" then
        print("คุณกดตกลงขายสินค้า")
        -- ใส่ Logic การขายตรงนี้
    elseif action == "cancel_trade" then
        print("คุณกดยกเลิก")
    end
end)

-- ลงทะเบียน Event ชื่อ mtn_notify:sendItem
RegisterNetEvent(resourceName .. ":sendItem")
AddEventHandler(resourceName .. ":sendItem", function(options, template)
    SendItemNotification(options, template)
end)

-- สร้างคำสั่งทดสอบ
RegisterCommand('testitem', function()
    TriggerEvent("mtn_notify:sendItem", {
        title = "ได้รับไอเทม",
        description = "น้ำดื่มสะอาด x1",
        icon = "tick", -- หรือชื่อไฟล์รูปไอเทม
        placement = "bottom-right",
        duration = 3000
    })
end)