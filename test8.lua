-- Empfänger-Skript für Wireless Modems
-- Zeigt die zuletzt empfangenen Zugdaten für zwei separate Sender-IDs in unterschiedlichen Zeilen an.
-- Dieser Code verwendet KEINE Listen oder Tabellen, nur individuelle Variablen,
-- um die Zugdaten für die Anzeige zu speichern.

-- Wireless Modem Setup
local modem = peripheral.find("modem")
if modem then
    rednet.open(peripheral.getName(modem)) -- Öffne Rednet für das Modem
else
    print("Kein Modem gefunden – Rednet deaktiviert.")
end

-- Monitor Setup
local monitor = peripheral.find("monitor")
if not monitor then
    error("Kein Monitor gefunden! Bitte stelle sicher, dass ein Monitor angeschlossen und mit dem Computer verbunden ist (Rechtsklick auf den Computer mit dem Monitor in der Hand).")
end
monitor.setTextScale(1) -- Setzt die Textgröße auf Standard
monitor.setBackgroundColor(colors.black) -- Setzt den Hintergrund auf Schwarz
monitor.clear() -- Löscht den Monitorinhalt


local red = colors.red
local yellow = colors.yellow
local green = colors.green
--local white = colors.white


-- Funktion zum Überprüfen der empfangenen Daten auf Gültigkeit
local function isValidData(data)
    -- Prüft, ob die Nachricht eine Tabelle ist und die notwendigen Felder enthält
    return data and type(data) == "table" and
           data.linie and data.ziel and data.abfahrt and data.countdown
end

-- Funktion zur Formatierung der Abfahrtszeit (in Millisekunden seit Epoch) in das Format mm:ss
local function formatAbfahrt(abfahrtEpochMs)
    -- Berechnet die verbleibende Zeit in Sekunden
    local verbleibendeZeit = abfahrtEpochMs - os.epoch("utc") / 1000
    if verbleibendeZeit <= 0 then
        return "sofort" -- Wenn die Zeit abgelaufen ist
    else
        local minuten = math.floor(verbleibendeZeit / 60) -- Berechnet die Minuten
        local sekunden = math.floor(verbleibendeZeit % 60) -- Berechnet die verbleibenden Sekunden
        return string.format("%02d:%02d", minuten, sekunden) -- Formatiert als mm:ss
    end
end



local function formatAbfahrtint(abfahrtEpochMs)
    -- Berechnet die verbleibende Zeit in Sekunden
    local verbleibendeZeit = abfahrtEpochMs - os.epoch("utc") / 1000
    
        local minuten = math.floor(verbleibendeZeit / 60) -- Berechnet die Minuten
        local sekunden = math.floor(verbleibendeZeit % 60) -- Berechnet die verbleibenden Sekunden
        return sekunden -- Formatiert als mm:ss
    
end



-- Funktion zur Formatierung von Text mit Leerzeichen, um eine feste Länge zu erreichen
local function formatWithSpaces(text, length)
    text = tostring(text) -- Stellt sicher, dass es ein String ist
    if #text > length then
        return text:sub(1, length) -- Kürzt den Text, wenn er zu lang ist
    else
        return text .. string.rep(" ", length - #text) -- Fügt Leerzeichen hinzu, wenn er zu kurz ist
    end
end

-- Maximale Breiten für jedes Feld in der Anzeige (als einzelne Variablen)
local maxLinieLength = 5
local maxZielLength = 15
local maxAbfahrtLength = 7
local maxSteigLength = 6

-- Erlaubte SenderIDs (als individuelle Variablen, keine Liste)
-- Diese Variablen dienen der Konfiguration und speichern keine dynamischen Zugdaten.
local allowedSenderID1 = 1031
local allowedSenderID2 = 1032
-- Bei Bedarf können hier weitere allowedSenderID3, allowedSenderID4 usw. hinzugefügt werden.

-- Variablen zur Speicherung der Daten für SenderID1 (erste Zeile)
local linie1, ziel1, abfahrt1, bahnsteig1 = nil, nil, nil, nil

-- Variablen zur Speicherung der Daten für SenderID2 (zweite Zeile)
local linie2, ziel2, abfahrt2, bahnsteig2 = nil, nil, nil, nil

-- Funktion zum Extrahieren des Bahnsteigs aus der SenderID
local function getBahnsteigFromSenderID(senderID)
    -- Nimmt an, dass die letzte Ziffer der SenderID der Bahnsteig ist
    return senderID % 10
end



-- Datum & Uhrzeit
local function getFormattedDateTime()
    local t = os.date("*t")
    return string.format("%02d.%02d.%04d - %02d:%02d:%02d", t.day, t.month, t.year, t.hour, t.min, t.sec)
end

local function centerText(text, y)
    local w, _ = monitor.getSize()
    local x = math.floor((w - #text) / 2) + 1
    monitor.setCursorPos(x, y)
    monitor.write(text)
end



-- Funktion zum Aktualisieren der Anzeige auf dem Monitor
-- Zeigt die Daten für zwei separate Züge in zwei Zeilen an.
-- Diese Funktion nimmt nun alle Datenfelder für beide Zeilen als Argumente entgegen.
local function aktualisiereAnzeige(l1, z1, a1, b1, l2, z2, a2, b2)
    monitor.clear() -- Löscht den gesamten Monitorinhalt
    monitor.setTextColor(colors.white) -- Setzt die Standardtextfarbe

    -- Kopfzeile
    monitor.setCursorPos(1, 1)
    monitor.write(
        formatWithSpaces("Linie", maxLinieLength) ..
        formatWithSpaces("Ziel", maxZielLength) ..
        formatWithSpaces("Abfahrt", maxAbfahrtLength) ..
        formatWithSpaces("Steig", maxSteigLength)
    )

    -- Anzeige der Zugdaten für die erste Zeile (SenderID1)
    monitor.setCursorPos(1, 2)
    if l1 and z1 and a1 and b1 then
        local abf1 = formatAbfahrt(a1)
        local ai1 = formatAbfahrtint(a1)
        local displayLine1 =
            formatWithSpaces(l1, maxLinieLength) ..
            formatWithSpaces(z1, maxZielLength) ..
            formatWithSpaces(abf1, maxAbfahrtLength) ..
            formatWithSpaces(tostring(b1), maxSteigLength)
       
            
            monitor.setTextColor(yellow)
            monitor.write(displayLine1)
        
        
    else
        monitor.setTextColor(red)
        monitor.write("Warte auf Daten (Sender 2)...")
    end

    -- Anzeige der Zugdaten für die zweite Zeile (SenderID2)
    monitor.setCursorPos(1, 3)
    if l2 and z2 and a2 and b2 then
        local abf2 = formatAbfahrt(a2)
        local ai2 = formatAbfahrtint(a2)
        local displayLine2 =
            formatWithSpaces(l2, maxLinieLength) ..
            formatWithSpaces(z2, maxZielLength) ..
            formatWithSpaces(abf2, maxAbfahrtLength) ..
            formatWithSpaces(tostring(b2), maxSteigLength)

        
            
            monitor.setTextColor(green)
            monitor.write(displayLine2)
        
        
    else
        monitor.setTextColor(red)
        monitor.write("Warte auf Daten (Sender 2)...")
    end
    monitor.setCursorPos(1, 4)
    monitor.setTextColor(colors.gray)
    centerText(getFormattedDateTime(), 4)


end

-- Initialisiere die Anzeige beim Start
aktualisiereAnzeige(linie1, ziel1, abfahrt1, bahnsteig1, linie2, ziel2, abfahrt2, bahnsteig2)

print("Empfänger-Skript aktiv. Lausche auf Rednet-Nachrichten.")
print("Drücke STRG+T, um das Programm zu beenden.")

-- Hauptloop zum Empfangen von Nachrichten
while true do
    -- Empfängt eine Nachricht über Rednet mit dem Protokoll "zuginfo"
    local senderID, message, protocol = rednet.receive("zuginfo")

    print("Empfangen von SenderID:", message.senderID)
    print("Empfangene Nachricht: ", textutils.serialize(message))

    if isValidData(message) then
        local currentBahnsteig = getBahnsteigFromSenderID(message.senderID)

        if message.senderID == allowedSenderID1 then
            -- Aktualisiere die Variablen für SenderID1
            linie1 = message.linie
            ziel1 = message.ziel
            abfahrt1 = message.abfahrt
            bahnsteig1 = currentBahnsteig
        elseif message.senderID == allowedSenderID2 then
            -- Aktualisiere die Variablen für SenderID2
            linie2 = message.linie
            ziel2 = message.ziel
            abfahrt2 = message.abfahrt
            bahnsteig2 = currentBahnsteig
        else
            print("Nachricht von nicht erlaubter SenderID empfangen:", message.senderID)
        end
    else
        print("Ungültige Daten empfangen!")
    end

    -- Aktualisiere die Anzeige mit den aktuellen Werten beider Sätze von Variablen
    aktualisiereAnzeige(linie1, ziel1, abfahrt1, bahnsteig1, linie2, ziel2, abfahrt2, bahnsteig2)

    sleep(0.1) -- Kurze Pause, um CPU-Last zu reduzieren
end
