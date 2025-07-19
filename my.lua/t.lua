-- Empfänger-Skript für Wireless Modems
-- Zeigt ausschließlich die Daten des ZULETZT empfangenen Zuges an.
-- Es werden KEINE Listen, Tabellen oder Variablen verwendet,
-- die Daten über den aktuellen Schleifendurchlauf hinaus speichern.

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

-- Farben definieren (Konstanten, kein Speicher)
local red = colors.red
local yellow = colors.yellow
local green = colors.green
local white = colors.white
local gray = colors.gray

-- Funktion zum Überprüfen der empfangenen Daten auf Gültigkeit
local function isValidData(data)
    -- Prüft, ob die Nachricht eine Tabelle ist und die notwendigen Felder enthält
    return data and type(data) == "table" and
           data.linie and data.ziel and data.abfahrt and data.countdown
end

-- Funktion zur Formatierung der Abfahrtszeit (in Millisekunden seit Epoch) in das Format mm:ss
local function formatAbfahrt(abfahrtEpochMs)
    -- Berechnet die verbleibende Zeit in Sekunden
    local verbleibendeZeit = (abfahrtEpochMs / 1000) - os.epoch("utc")
    if verbleibendeZeit <= 0 then
        return "sofort" -- Wenn die Zeit abgelaufen ist
    else
        local minuten = math.floor(verbleibendeZeit / 60) -- Berechnet die Minuten
        local sekunden = math.floor(verbleibendeZeit % 60) -- Berechnet die verbleibenden Sekunden
        return string.format("%02d:%02d", minuten, sekunden) -- Formatiert als mm:ss
    end
end

-- Funktion zur Formatierung der Abfahrtszeit als ganze Zahl (Sekunden)
local function formatAbfahrtint(abfahrtEpochMs)
    -- Berechnet die verbleibende Zeit in Sekunden
    local verbleibendeZeit = (abfahrtEpochMs / 1000) - os.epoch("utc")
    return verbleibendeZeit
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

-- Maximale Breiten für jedes Feld in der Anzeige (als einzelne Variablen/Konstanten)
local maxLinieLength = 5
local maxZielLength = 15
local maxAbfahrtLength = 7
local maxSteigLength = 6

-- Erlaubte SenderIDs (als individuelle Variablen/Konstanten, kein Speicher)
local allowedSenderID1 = 1031
local allowedSenderID2 = 1032

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
-- Diese Funktion wird nun direkt mit den Daten des ZULETZT empfangenen Zuges aufgerufen.
-- Die "andere" Zeile wird immer als "Warte auf Daten..." angezeigt.
local function aktualisiereAnzeige(activeSenderID, activeLinie, activeZiel, activeAbfahrt, activeBahnsteig)
    monitor.clear() -- Löscht den gesamten Monitorinhalt
    monitor.setTextColor(white) -- Setzt die Standardtextfarbe

    local monitorWidth, monitorHeight = monitor.getSize() -- Aktuelle Monitorgröße abrufen

    -- Dynamische Spaltenbreiten basierend auf der Monitorbreite
    local col1_width = 5 -- Linie (fix)
    local col3_width = 7 -- Abfahrt (fix)
    local col4_width = 6 -- Steig (fix)
    local separator_width = 2 -- Leerzeichen zwischen Spalten

    -- Berechne die Breite für die Ziel-Spalte
    local fixedUsedWidth = col1_width + col3_width + col4_width + (separator_width * 3)
    local col2_width = math.max(10, monitorWidth - fixedUsedWidth) -- Ziel (flexibel, mindestens 10)

    -- Kopfzeile
    monitor.setCursorPos(1, 1)
    monitor.write(
        formatWithSpaces("Linie", col1_width) .. string.rep(" ", separator_width) ..
        formatWithSpaces("Ziel", col2_width) .. string.rep(" ", separator_width) ..
        formatWithSpaces("Abfahrt", col3_width) .. string.rep(" ", separator_width) ..
        formatWithSpaces("Steig", col4_width)
    )

    -- Anzeige der Zugdaten für die erste Zeile (SenderID1)
    monitor.setCursorPos(1, 2)
    if activeSenderID == allowedSenderID1 and activeLinie then -- Prüft, ob dies der aktive Sender ist
        local abf = formatAbfahrt(activeAbfahrt)
        local ai = formatAbfahrtint(activeAbfahrt)

        monitor.setTextColor(red) -- Farbe für Linie 1 (fest)
        monitor.write(formatWithSpaces(activeLinie, col1_width))

        monitor.setTextColor(yellow) -- Farbe für Ziel
        monitor.write(string.rep(" ", separator_width) .. formatWithSpaces(activeZiel, col2_width))

        -- Farbe für Abfahrt basierend auf Countdown
        if ai > 100 then
            monitor.setTextColor(green)
        elseif ai < 30 then
            monitor.setTextColor(red)
        else
            monitor.setTextColor(yellow)
        end
        monitor.write(string.rep(" ", separator_width) .. formatWithSpaces(abf, col3_width))

        monitor.setTextColor(white) -- Farbe für Steig
        monitor.write(string.rep(" ", separator_width) .. formatWithSpaces(tostring(activeBahnsteig), col4_width))
    else
        monitor.setTextColor(red)
        monitor.write("Warte auf Daten (Sender 1)...")
    end

    -- Anzeige der Zugdaten für die zweite Zeile (SenderID2)
    monitor.setCursorPos(1, 3)
    if activeSenderID == allowedSenderID2 and activeLinie then -- Prüft, ob dies der aktive Sender ist
        local abf = formatAbfahrt(activeAbfahrt)
        local ai = formatAbfahrtint(activeAbfahrt)

        monitor.setTextColor(green) -- Farbe für Linie 2 (fest)
        monitor.write(formatWithSpaces(activeLinie, col1_width))

        monitor.setTextColor(yellow) -- Farbe für Ziel
        monitor.write(string.rep(" ", separator_width) .. formatWithSpaces(activeZiel, col2_width))

        -- Farbe für Abfahrt basierend auf Countdown
        if ai > 100 then
            monitor.setTextColor(green)
        elseif ai < 30 then
            monitor.setTextColor(red)
        else
            monitor.setTextColor(yellow)
        end
        monitor.write(string.rep(" ", separator_width) .. formatWithSpaces(abf, col3_width))

        monitor.setTextColor(white) -- Farbe für Steig
        monitor.write(string.rep(" ", separator_width) .. formatWithSpaces(tostring(activeBahnsteig), col4_width))
    else
        monitor.setTextColor(red)
        monitor.write("Warte auf Daten (Sender 2)...")
    end

    -- Datum & Uhrzeit am unteren Rand zentriert
    if monitorHeight >= 4 then -- Nur anzeigen, wenn genug Platz ist
        monitor.setCursorPos(1, 4)
        monitor.setTextColor(gray)
        centerText(getFormattedDateTime(), 4)
    end
end

-- Initialisiere die Anzeige beim Start (zeigt "Warte auf Daten..." für beide Zeilen)
aktualisiereAnzeige(nil, nil, nil, nil, nil)

print("Empfänger-Skript aktiv. Lausche auf Rednet-Nachrichten.")
print("Drücke STRG+T, um das Programm zu beenden.")

-- Hauptloop zum Empfangen von Nachrichten
while true do
    -- Empfängt eine Nachricht über Rednet mit dem Protokoll "zuginfo"
    local senderID, message, protocol = rednet.receive("zuginfo")

    print("Empfangen von SenderID:", senderID)
    print("Empfangene Nachricht: ", textutils.serialize(message))

    if isValidData(message) then
        local currentBahnsteig = getBahnsteigFromSenderID(senderID)

        -- Ruft aktualisiereAnzeige mit den Daten des EINEN gerade empfangenen Zuges auf.
        -- Die anderen Argumente werden nur gesetzt, wenn die SenderID übereinstimmt,
        -- ansonsten bleiben sie nil, was dazu führt, dass die "Warte auf Daten..."-Meldung erscheint.
        aktualisiereAnzeige(senderID, message.linie, message.ziel, message.abfahrt, currentBahnsteig)
    else
        print("Ungültige Daten empfangen!")
        -- Wenn ungültige Daten empfangen werden, wird die Anzeige zurückgesetzt.
        aktualisiereAnzeige(nil, nil, nil, nil, nil)
    end

    sleep(0.1) -- Kurze Pause, um CPU-Last zu reduzieren
end
