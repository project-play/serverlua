-- receive_and_display_train_data
-- Empfängt Zugdaten über ein Modem und zeigt sie auf Monitoren an

local modem = peripheral.find("modem")
local monitors = peripheral.find("monitor")
local channel = 123 -- Der Kanal, auf dem empfangen wird

if not modem then
    error("Kein Modem gefunden! Bitte stelle sicher, dass ein Modem an diesen Computer angeschlossen ist.")
end

if monitors == 0 then
    error("Keine Monitore gefunden! Bitte stelle sicher, dass Monitore an diesen Computer angeschlossen sind.")
end

-- Funktion zum Löschen und Schreiben auf alle Monitore
local function displayData(data_table)
    for _, monitor_name in ipairs(monitors) do
        local mon = peripheral.wrap(monitor_name)
        mon.clear()
        mon.setCursorPos(1, 1)
        mon.setTextScale(1) -- Setze Standard-Textgröße zurück

        if data_table then
            mon.write("Zug-ID: " .. (data_table.id or "N/A"))
            mon.setCursorPos(1, 2)
            mon.write("Status: " .. (data_table.status or "N/A"))
            mon.setCursorPos(1, 3)
            mon.write("Position: " .. (data_table.position or "N/A"))
            mon.setCursorPos(1, 4)
            mon.write("Geschwindigkeit: " .. (data_table.speed or "N/A"))
            mon.setCursorPos(1, 5)
            mon.write("Ziel: " .. (data_table.destination or "N/A"))
            mon.setCursorPos(1, 6)
            mon.write("Ankunft: " .. (data_table.arrival_time or "N/A"))
        else
            mon.write("Warte auf Zugdaten...")
        end
    end
end

print("Warte auf Zugdaten auf Kanal " .. channel .. "...")
print("Empfangene Daten werden auf den Monitoren angezeigt.")
print("Drücke STRG+T, um das Programm zu beenden.")

displayData(nil) -- Zeige "Warte auf Daten" beim Start

while true do
    local event, p1, p2, p3, p4, p5 = os.pullEvent("modem_message")

    if event == "modem_message" then
        local senderChannel = p1
        local replyChannel = p2
        local message = p3
        local distance = p4

        if senderChannel == channel then
            print("Daten empfangen von Kanal " .. senderChannel .. ": " .. textutils.serialize(message))
            displayData(message)
        end
    end
end