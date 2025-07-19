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
    return data and data.linie and data.ziel and data.abfahrt and data.countdown
end

-- Funktion zur Formatierung der Abfahrtszeit (in Sekunden) in das Format mm:ss
local function formatAbfahrt(abfahrt)
    local verbleibendeZeit = abfahrt - os.epoch("utc") / 1000
    if verbleibendeZeit <= 0 then
        return "sofort"
    else
        local minuten = math.floor(verbleibendeZeit / 60)
        local sekunden = math.floor(verbleibendeZeit % 60)
        return string.format("%02d:%02d", minuten, sekunden)
    end
end

-- Funktion zur Formatierung von Text mit Leerzeichen
local function formatWithSpaces(text, length)
    text = tostring(text)
    if #text > length then
        return text:sub(1, length)
    else
        return text .. string.rep(" ", length - #text)
    end
end

-- Maximale Breiten für jedes Feld
local maxLinieLength = 5
local maxZielLength = 15
local maxAbfahrtLength = 7
local maxSteigLength = 6

-- Liste der empfangenen Züge
local zuege = {}

-- Erlaubte SenderIDs
local erlaubteSenderID1 = 1031
local erlaubteSenderID2 = 1032

-- Bahnsteig aus senderID extrahieren
local function getBahnsteigFromSenderID(senderID)
    return senderID % 10
end

-- Sortiere Züge nach Abfahrt
local function sortiereZuege()
    table.sort(zuege, function(a, b)
        return a.abfahrt < b.abfahrt
    end)
end

-- Filtere doppelte Ziele (nur frühester Zug pro Ziel)
local function filterZuege()
    local gefilterteZuege = {}

    for _, zug in ipairs(zuege) do
        local zielExistiertBereits = false
        for i, existierenderZug in ipairs(gefilterteZuege) do
            if existierenderZug.ziel == zug.ziel then
                if zug.abfahrt < existierenderZug.abfahrt then
                    gefilterteZuege[i] = zug
                end
                zielExistiertBereits = true
                break
            end
        end
        if not zielExistiertBereits then
            table.insert(gefilterteZuege, zug)
        end
    end

    zuege = gefilterteZuege
end

-- Anzeige aktualisieren – zwei Spalten
local function aktualisiereAnzeige()
    monitor.clear()
    monitor.setTextColor(colors.white)

    -- Kopfzeile
    monitor.setCursorPos(1, 1)
    monitor.write(
        formatWithSpaces("Linie", maxLinieLength) ..
        formatWithSpaces("Ziel", maxZielLength) ..
        formatWithSpaces("Abfahrt", maxAbfahrtLength) ..
        formatWithSpaces("Steig", maxSteigLength) ..
        "   " ..
        formatWithSpaces("Linie", maxLinieLength) ..
        formatWithSpaces("Ziel", maxZielLength) ..
        formatWithSpaces("Abfahrt", maxAbfahrtLength) ..
        formatWithSpaces("Steig", maxSteigLength)
    )

    -- Zwei Zeilen mit je zwei Zügen
    for zeile = 0, 1 do
        local zugLinks = zuege[zeile * 2 + 1]
        local zugRechts = zuege[zeile * 2 + 2]
        monitor.setCursorPos(1, zeile + 2)

        local line = ""

        -- Linke Spalte
        if zugLinks then
            local abf = formatAbfahrt(zugLinks.abfahrt)
            line = line ..
                formatWithSpaces(zugLinks.linie, maxLinieLength) ..
                formatWithSpaces(zugLinks.ziel, maxZielLength) ..
                formatWithSpaces(abf, maxAbfahrtLength) ..
                formatWithSpaces(tostring(zugLinks.bahnsteig), maxSteigLength)
        else
            line = line .. string.rep(" ", maxLinieLength + maxZielLength + maxAbfahrtLength + maxSteigLength)
        end

        line = line .. "   "

        -- Rechte Spalte
        if zugRechts then
            local abf = formatAbfahrt(zugRechts.abfahrt)
            line = line ..
                formatWithSpaces(zugRechts.linie, maxLinieLength) ..
                formatWithSpaces(zugRechts.ziel, maxZielLength) ..
                formatWithSpaces(abf, maxAbfahrtLength) ..
                formatWithSpaces(tostring(zugRechts.bahnsteig), maxSteigLength)
        end

        monitor.write(line)
    end
end

-- Hauptloop
while true do
    local senderID, message, protocol = rednet.receive("zuginfo")

    print("Empfangen von Channel:", senderID)
    print("Empfangene Nachricht: ", textutils.serialize(message))

    if senderID == 1031 or senderID == 1032 then
        if isValidData(message) then
            local zug = {
                linie = message.linie,
                ziel = message.ziel,
                abfahrt = message.abfahrt,
                bahnsteig = getBahnsteigFromSenderID(senderID),
                countdown = message.countdown
            }

            table.insert(zuege, zug)

            filterZuege()
            sortiereZuege()
        else
            print("Ungültige Daten empfangen!")
        end
    end

    aktualisiereAnzeige()
    sleep(0.1)
end
