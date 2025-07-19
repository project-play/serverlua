-- Empfänger-Skript für mehrere Wireless Modems und vordefinierte Channels

-- Liste der vordefinierten Channel-IDs (4-stellige Nummern)
local channels = {1031, 1032, 1033}  -- Zum Beispiel: 1031, 1032, 1033 für verschiedene Modems

-- Funktion zum Abrufen des Bahnsteigs anhand des Channel-Index
local function getBahnsteigFromChannel(channel)
    -- Die Channels und ihre zugeordneten Bahnsteige
    local bahnsteige = {
        [1031] = 1,  -- Channel 1031 -> Bahnsteig 1
        [1032] = 2,  -- Channel 1032 -> Bahnsteig 2
        [1033] = 3,  -- Channel 1033 -> Bahnsteig 3
    }
    
    -- Gib den Bahnsteig zurück, der dem Channel zugeordnet ist
    return bahnsteige[channel] or "Unbekannt"  -- Falls der Channel nicht gefunden wird, gebe "Unbekannt" zurück
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

-- Alle angeschlossenen Modems öffnen (für alle vordefinierten Channels)
local modems = peripheral.find("modem")  -- Finde alle angeschlossenen Modems
for _, modem in ipairs(modems) do
    rednet.open(peripheral.getName(modem))  -- Öffne jedes Modem
    print("Modem geöffnet: " .. peripheral.getName(modem))
end

-- Tabelle für die Zuginformationen
local zuege = {}

-- Endlosschleife, um Nachrichten zu empfangen und Zuginformationen anzuzeigen
while true do
    -- Empfang von Nachrichten (senderID ist der Channel)
    local senderID, message = rednet.receive(5)  -- Timeout von 5 Sekunden
    
    -- Überprüfen, ob eine Nachricht empfangen wurde und was wir erhalten haben
    if senderID then
        -- Abrufen des Bahnsteigs basierend auf der `senderID` (Channel)
        local bahnsteig = getBahnsteigFromChannel(senderID)

        -- Speichern der Zuginformationen
        zuege[senderID] = {
            linie = message.linie,
            ziel = message.ziel,
            abfahrt = message.abfahrt,
            bahnsteig = bahnsteig,
        }

        -- Sortiere die Züge nach Abfahrtszeit
        local sortedZuege = {}
        for _, zug in pairs(zuege) do
            table.insert(sortedZuege, zug)
        end
        table.sort(sortedZuege, function(a, b)
            return a.abfahrt < b.abfahrt  -- Sortieren nach der Abfahrtszeit
        end)

        -- Anzeigen der Zuginformationen auf dem Monitor
        local monitor = peripheral.find("monitor")
        if monitor then
            monitor.clear()
            monitor.setTextColor(colors.white)
            local row = 1
            local w, h = monitor.getSize()

            -- Zeige die ersten 2 Züge an (Maximal 2 Zeilen)
            for i, zug in ipairs(sortedZuege) do
                if i > 2 then break end  -- Nur die ersten 2 Züge anzeigen
                local abfahrtText = formatAbfahrt(zug.abfahrt)  -- Formatierte Abfahrtszeit
                local lineText = string.format("%s -> %s in %s Steig %d", zug.linie, zug.ziel, abfahrtText, zug.bahnsteig)

                -- Zeige die Zuginformationen in den ersten 2 Zeilen an
                monitor.setCursorPos(1, row)
                monitor.write(lineText)
                row = row + 1
            end

            -- Zeige die aktuelle Uhrzeit und Datum in der 3. Zeile an
            local currentTime = getFormattedDateTime()
            monitor.setTextColor(colors.gray)

            -- Setze den Cursor auf die 3. Zeile (nur wenn sie existiert)
            if row <= h then  -- Überprüfen, dass die Zeile im Monitor verfügbar ist
                monitor.setCursorPos(1, 3)
                monitor.write(currentTime)
            end
        end
    end
end
