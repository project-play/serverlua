-- Alle Modems im System finden
local modems = {}
local modemIDs = {}  -- Hier speichern wir die zugewiesenen 4-stelligen IDs für jedes Modem

-- Alle Modems im System finden
for _, name in ipairs(peripheral.getNames()) do
    local p = peripheral.wrap(name)
    if peripheral.getType(p) == "modem" then
        table.insert(modems, p)
    end
end

-- Wenn keine Modems gefunden wurden, Fehler ausgeben
if #modems == 0 then
    error("Kein Modem gefunden!")
end

-- Jedes Modem eine 4-stellige ID manuell zuweisen
for i, modem in ipairs(modems) do
    -- Benutzer auffordern, eine ID für jedes Modem einzugeben
    print("Bitte gebe eine 4-stellige ID für Modem " .. i .. " ein:")
    local modemID = tonumber(io.read())  -- Die Eingabe wird als Zahl gespeichert
    
    -- Überprüfen, ob die ID gültig ist
    if modemID and modemID >= 1000 and modemID <= 9999 then
        modemIDs[peripheral.getName(modem)] = modemID
    else
        error("Ungültige Modem-ID! Bitte eine 4-stellige Zahl zwischen 1000 und 9999 eingeben.")
    end
end

-- Alle Modems öffnen
for _, modem in ipairs(modems) do
    rednet.open(peripheral.getName(modem))
end

-- Funktion zum Extrahieren des Bahnsteigs aus der Modem-ID (letzte Ziffer)
local function getBahnsteigFromModemID(modemID)
    return modemID % 10  -- Die letzte Ziffer der Modem-ID gibt den Bahnsteig an
end

-- Hier speichern wir die Zuginformationen nach Modem-ID
local zuege = {}

-- Funktion zum Anzeigen der empfangenen Zuginformationen auf dem Monitor
local function displayData()
    local monitor = peripheral.find("monitor")
    if monitor then
        monitor.clear()
        monitor.setTextColor(colors.white)

        -- Anzeigen der Züge, sortiert nach Abfahrtszeit
        local yPos = 1
        local w, h = monitor.getSize()

        -- Züge nach Abfahrtszeit sortieren
        local sortedZuege = {}
        for modemID, zug in pairs(zuege) do
            table.insert(sortedZuege, zug)
        end

        table.sort(sortedZuege, function(a, b)
            return a.abfahrt < b.abfahrt  -- Sortieren nach der Abfahrtszeit
        end)

        for _, zug in ipairs(sortedZuege) do
            -- Linie und Ziel in einer Zeile
            local zielText = zug.linie .. " -> " .. zug.ziel
            local abfahrtText = "in " .. zug.zeitBisAbfahrt .. " Steig " .. zug.bahnsteig

            -- Die Textlänge des gesamten Textes (Ziel + Abfahrtszeit + Steig)
            local fullText = zielText .. string.rep(" ", w - #zielText - #abfahrtText) .. abfahrtText

            monitor.setCursorPos(1, yPos)
            monitor.write(fullText)

            yPos = yPos + 1

            -- Falls Platz auf dem Monitor, mit Leerzeichen auffüllen
            while yPos < h do
                yPos = yPos + 1
                monitor.setCursorPos(1, yPos)
                monitor.write(string.rep(" ", w))  -- Füllt die restlichen Zeilen mit Leerzeichen
            end
        end
    end
end

-- Nachrichten empfangen und Zuginformationen nach Modem-ID aktualisieren
while true do
    
    -- Empfang von Nachrichten von allen Modems (wir erwarten Zuginformationen)
    local senderID, message, protocol = rednet.receive("zuginfo")
    
    -- Debugging-Ausgabe: Zeigt, von welchem Modem die Nachricht kommt
    print("Nachricht empfangen von Modem-ID: " .. senderID)
    print("Nachricht Inhalt: " .. textutils.serialize(message))
    
    -- Falls eine Nachricht von einem bekannten Modem kommt, aktualisieren wir die Zuginformationen
    if senderID then
        -- Extrahiere den Bahnsteig aus der letzten Ziffer der Modem-ID
        local bahnsteig = getBahnsteigFromModemID(senderID)

        -- Berechne die verbleibende Zeit bis zur Abfahrt
        local verbleibendeZeit = math.floor(message.abfahrt - os.epoch("utc") / 1000)
        local minuten = math.floor(verbleibendeZeit / 60)
        local sekunden = verbleibendeZeit % 60
        local zeitBisAbfahrt = string.format("%d:%02d", minuten, sekunden)

        -- Speichern oder Aktualisieren der Zuginformationen für diese Modem-ID
        zuege[senderID] = {
            linie = message.linie,
            ziel = message.ziel,
            abfahrt = message.abfahrt,
            bahnsteig = bahnsteig,
            zeitBisAbfahrt = zeitBisAbfahrt,
        }

        -- Anzeige der Züge auf dem Monitor
        displayData()
    else
        print("Unbekannte senderID:", senderID)
    end

    -- Eine kleine Verzögerung, um die Anzeige zu optimieren
    sleep(0.1)
end