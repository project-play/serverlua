-- https://pastebin.com/4HatcTqd

local modem = peripheral.find("modem")
if modem then
    rednet.open(peripheral.getName(modem)) -- Öffne Rednet für das Modem
else
    print("Kein Modem gefunden – Rednet deaktiviert.")
end



local allowedSenderID1 = 1033

local linie1, ziel1, abfahrt1, bahnsteig1, countdown1 = nil, nil, nil, nil, nil

local function isValidData(data)
    -- Prüft, ob die Nachricht eine Tabelle ist und die notwendigen Felder enthält
    return data and type(data) == "table" and
           data.linie and data.ziel and data.abfahrt and data.countdown
end


local function sendeZugInfo()
    if rednet.isOpen() then
        local daten = {
            senderID = 1033,  -- Feste 4-stellige Nummer als Sender-ID
            linie = linie1,
            ziel = ziel1,
            via = "Max ist leider OP",  -- "via Ostbahnhof" wird jetzt explizit gesendet
            abfahrt = abfahrt1,  -- Die tatsächliche Abfahrtszeit
            countdown = countdown1  -- Der Countdown wird ebenfalls gesendet
        }
        print(linie1, ziel1, abfahrt1, countdown1)
        -- Broadcast an alle (alternativ: rednet.send(ID, daten))
        rednet.broadcast(daten, "zuginfo")
    end
end

while true do
    -- Empfängt eine Nachricht über Rednet mit dem Protokoll "zuginfo"
    local senderID, message, protocol = rednet.receive("zuginfo")
    if message.senderID == allowedSenderID1 then
    print("Empfangen von SenderID:", message.senderID)
    
    print("Empfangene Nachricht: ", textutils.serialize(message))
    end

    if isValidData(message) then
        --local currentBahnsteig = getBahnsteigFromSenderID(message.senderID)

        if message.senderID == allowedSenderID1 then
            -- Aktualisiere die Variablen für SenderID1
            linie1 = message.linie
            ziel1 = message.ziel
            abfahrt1 = message.abfahrt
            countdown1 = message.countdown
            

        sendeZugInfo()
        else
            
        end
    else
        print("Ungültige Daten empfangen!")
    end
end