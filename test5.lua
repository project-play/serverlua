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
    return data and data.linie and data.ziel and data.abfahrt and data.bahnsteig
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

-- Funktion zur Formatierung von Datum und Uhrzeit
local function getFormattedDateTime()
    local t = os.date("*t")  -- Aktuelles Datum und Uhrzeit
    return string.format("%02d.%02d.%04d - %02d:%02d:%02d", t.day, t.month, t.year, t.hour, t.min, t.sec)
end

-- Variablen für die letzten beiden empfangenen Züge
local linie1, ziel1, abfahrt1, bahnsteig1
local linie2, ziel2, abfahrt2, bahnsteig2

-- Funktion zum Anzeigen der Zuginformationen
local function aktualisiereAnzeige()
    -- Leere den Monitor
    monitor.clear()
    monitor.setTextColor(colors.white)

    -- Zeige die ersten zwei Züge an
    if linie1 then
        local abfahrt1Formatted = formatAbfahrt(abfahrt1)
        monitor.setCursorPos(1, 1)
        monitor.write(string.format("%s -> %s in %s Steig %d", linie1, ziel1, abfahrt1Formatted, bahnsteig1))
    end

    if linie2 then
        local abfahrt2Formatted = formatAbfahrt(abfahrt2)
        monitor.setCursorPos(1, 2)
        monitor.write(string.format("%s -> %s in %s Steig %d", linie2, ziel2, abfahrt2Formatted, bahnsteig2))
    end

    -- Zeige die aktuelle Uhrzeit und Datum in der 3. Zeile an
    monitor.setCursorPos(1, 3)
    monitor.write(getFormattedDateTime())
end

-- Hauptloop: Empfange Zuginformationen von den Channels 1031 und 1032 und zeige sie an
while true do
    -- Warten auf eine Nachricht von den Channels 1031 und 1032 mit dem Protokoll "zuginfo"
    local senderID, message, protocol = rednet.receive("zuginfo")

    -- Debugging: Ausgabe der empfangenen SenderID und Nachricht
    print("Empfangen von SenderID:", senderID)
    print("Nachricht:", textutils.serialize(message))

    -- Nur Zuginformationen von den Channels 1031 und 1032 empfangen
    if senderID == 1031 then
        -- Überprüfen, ob die empfangenen Daten gültig sind
        if isValidData(message) then
            -- Speichern der Zuginformationen in den Variablen für Channel 1031
            linie1 = message.linie
            ziel1 = message.ziel
            abfahrt1 = message.abfahrt
            bahnsteig1 = message.bahnsteig
        else
            print("Ungültige Daten von Channel 1031 empfangen!")
        end
    elseif senderID == 1032 then
        -- Überprüfen, ob die empfangenen Daten gültig sind
        if isValidData(message) then
            -- Speichern der Zuginformationen in den Variablen für Channel 1032
            linie2 = message.linie
            ziel2 = message.ziel
            abfahrt2 = message.abfahrt
            bahnsteig2 = message.bahnsteig
        else
            print("Ungültige Daten von Channel 1032 empfangen!")
        end
    end

    -- Anzeige der Zuginformationen auf dem Monitor
    aktualisiereAnzeige()

    -- Kurze Pause, bevor die nächste Nachricht empfangen wird
    sleep(0.1)
end
