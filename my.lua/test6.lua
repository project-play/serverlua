-- Empfänger-Skript für Wireless Modems

-- Wireless Modem Setup
local modem = peripheral.find("modem")
if modem then
    rednet.open(peripheral.getName(modem))  -- Öffne Rednet für das Modem
else
    print("Kein Modem gefunden – Rednet deaktiviert.")
end

-- Monitor Setup
local monitor = peripheral.find("monitor")
if not monitor then
    error("Kein Monitor gefunden!")
end
monitor.setTextScale(1)
monitor.setBackgroundColor(colors.black)
monitor.clear()

-- Funktion zum Überprüfen der empfangenen Daten
local function isValidData(data)
    -- Sicherstellen, dass alle Felder vorhanden sind und nicht nil sind
    return data and data.linie and data.ziel and data.abfahrt
end

-- Funktion zur Formatierung der Abfahrtszeit (in Sekunden) in das Format hh:mm:ss
local function formatAbfahrt(abfahrt)
    local verbleibendeZeit = abfahrt - os.epoch("utc") / 1000  -- Abfahrt in Sekunden (UTC)
    if verbleibendeZeit <= 0 then
        return "sofort"
    else
        local minuten = math.floor(verbleibendeZeit / 60)
        local sekunden = math.floor(verbleibendeZeit % 60)
        return string.format("%02d:%02d", minuten, sekunden)
    end
end

-- Variablen für die letzten beiden empfangenen Züge
local linie1, ziel1, abfahrt1, bahnsteig1
local linie2, ziel2, abfahrt2, bahnsteig2

-- Funktion zur Extraktion des Bahnsteigs aus der senderID
local function getBahnsteigFromSenderID(senderID)
    return senderID % 10  -- Letzte Ziffer der senderID gibt den Bahnsteig an
end

-- Funktion zum Anzeigen der Zuginformationen
local function aktualisiereAnzeige()
    -- Leere den Monitor
    monitor.clear()
    monitor.setTextColor(colors.white)

    -- Überprüfen, ob die Zuginformationen gesetzt wurden
    print("Anzeige der Züge:")
    if linie1 then
        print("Zug 1 - Linie:", linie1, "Ziel:", ziel1, "Abfahrt:", formatAbfahrt(abfahrt1), "Steig:", bahnsteig1)
        monitor.setCursorPos(1, 1)
        monitor.write(string.format("%s -> %s in %s Steig %d", linie1, ziel1, formatAbfahrt(abfahrt1), bahnsteig1))
    else
        print("Zug 1: Keine Daten")
        monitor.setCursorPos(1, 1)
        monitor.write("Zug 1: Keine Daten")
    end

    if linie2 then
        print("Zug 2 - Linie:", linie2, "Ziel:", ziel2, "Abfahrt:", formatAbfahrt(abfahrt2), "Steig:", bahnsteig2)
        monitor.setCursorPos(1, 2)
        monitor.write(string.format("%s -> %s in %s Steig %d", linie2, ziel2, formatAbfahrt(abfahrt2), bahnsteig2))
    else
        print("Zug 2: Keine Daten")
        monitor.setCursorPos(1, 2)
        monitor.write("Zug 2: Keine Daten")
    end
end

-- Hauptloop: Empfange Zuginformationen von den Channels 1031 und 1032 und zeige sie an
while true do
    -- Warten auf eine Nachricht von den Channels 1031 und 1032 mit dem Protokoll "zuginfo"
    local senderID, message, protocol = rednet.receive("zuginfo")

    -- Debugging: Ausgabe der empfangenen SenderID und Nachricht
    print("Empfangen von SenderID:", message.senderID)
    print("Nachricht:", textutils.serialize(message))

    -- Sicherstellen, dass die empfangenen Daten valide sind
    if isValidData(message) then
        -- Nur Zuginformationen von den Channels 1031 und 1032 empfangen
        if message.senderID == 1031 then
            -- Speichern der Zuginformationen in den Variablen für Channel 1031
            linie1 = message.linie
            ziel1 = message.ziel
            abfahrt1 = message.abfahrt
            bahnsteig1 = getBahnsteigFromSenderID(message.senderID)  -- Bahnsteig aus der letzten Ziffer der senderID
            print("Zug 1 - Linie:", linie1, "Ziel:", ziel1, "Abfahrt:", formatAbfahrt(abfahrt1), "Steig:", bahnsteig1)
        elseif message.senderID == 1032 then
            -- Speichern der Zuginformationen in den Variablen für Channel 1032
            linie2 = message.linie
            ziel2 = message.ziel
            abfahrt2 = message.abfahrt
            bahnsteig2 = getBahnsteigFromSenderID(message.senderID)  -- Bahnsteig aus der letzten Ziffer der senderID
            print("Zug 2 - Linie:", linie2, "Ziel:", ziel2, "Abfahrt:", formatAbfahrt(abfahrt2), "Steig:", bahnsteig2)
        end
    else
        print("Ungültige Daten empfangen!")
    end

    -- Anzeige der Zuginformationen auf dem Monitor
    aktualisiereAnzeige()

    -- Kurze Pause, bevor die nächste Nachricht empfangen wird
    sleep(0.1)
end
