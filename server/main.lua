local resourceName = "mtn_notify" -- กำหนดชื่อ Resource ตายตัวเพื่อให้ตรงกับ Client

RegisterNetEvent(resourceName .. ":send")
AddEventHandler(resourceName .. ":send", function(source, options, template)
    if source == nil then
        return print("Error: source must be provided (use -1 for all players)")
    end

    TriggerClientEvent(resourceName .. ":send", source, options, template)
end)

RegisterNetEvent(resourceName .. ":sendAll")
AddEventHandler(resourceName .. ":sendAll", function(options, template)
    -- ตรวจสอบว่า options มีค่าและมีการระบุชื่อ icon มา
    if type(options) == "table" and options.icon then
        -- ถ้าชื่อ icon ไม่ได้มี "//" (เช่นยังไม่ได้เป็น nui:// หรือ http://)
        if not string.find(options.icon, "//") then
            -- ให้เติม Path ของ vorp_inventory เข้าไปด้านหน้า และใส่ .png ด้านหลัง
            options.icon = "nui://vorp_inventory/html/img/items/" .. options.icon .. ".png"
        end
    end

    -- แจ้งเตือนไปยัง Client ของผู้เล่นทุกคนโดยใช้ -1
    TriggerClientEvent(resourceName .. ":send", -1, options, template)
end)