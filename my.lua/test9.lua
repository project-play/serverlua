-- Monitor & Redstone Setup
local monitor = peripheral.find("monitor")
if not monitor then error("Monitor nicht gefunden!") end

monitor.setTextScale(1)
monitor.setBackgroundColor(colors.black)
monitor.clear()

-- Wireless Modem Setup
local modem = peripheral.find("modem")
if modem then
    rednet.open(peripheral.getName(modem))
else
    print("Kein Modem gefunden – Rednet deaktiviert.")
end

-- Einstellungen
local linienName = "A"
local linienFarbe = colors.red
local redstoneSeite = "back" -- Seite für Redstone-Signal

-- Dauer bis zur Abfahrt (in Sekunden)
local abfahrtsDauer = 140 -- 3 Minuten

-- Zeit-Funktion (reale Sekunden)
local function getTime()
    return os.epoch("utc") / 1000
end

-- Initiale Zugdaten
local zugInfo = {
    ziel = "Jeffreys Haus",
    via = "via Renes Keller",  -- Hier setzen wir den "via" Text explizit
    abfahrt = getTime() + abfahrtsDauer  -- Setzt den Abfahrtszeitpunkt
}

-- Countdown-Formatierung (nun ohne "in")
local function formatTimeLeft()
    local sekunden = math.floor(zugInfo.abfahrt - getTime())
    if sekunden <= 0 then
        return "sofort", 0
    else
        local minuten = math.floor(sekunden / 60)
        local rest = sekunden % 60
        return string.format("%02d:%02d", minuten, rest), sekunden
    end
end

-- Datum & Uhrzeit
local function getFormattedDateTime()
    local t = os.date("*t")
    return string.format("%02d.%02d.%04d - %02d:%02d:%02d", t.day, t.month, t.year, t.hour, t.min, t.sec)
end

-- Text zentrieren
local function centerText(text, y)
    local w, _ = monitor.getSize()
    local x = math.floor((w - #text) / 2) + 1
    monitor.setCursorPos(x, y)
    monitor.write(text)
end

-- Senden der Zuginformationen mit der Abfahrtszeit und Countdown
local function sendeZugInfo()
    if rednet.isOpen() then
        local daten = {
            senderID = 1031,  -- Feste 4-stellige Nummer als Sender-ID
            linie = linienName,
            ziel = zugInfo.ziel,
            via = zugInfo.via,  -- "via Ostbahnhof" wird jetzt explizit gesendet
            abfahrt = zugInfo.abfahrt,  -- Die tatsächliche Abfahrtszeit
            countdown = formatTimeLeft()  -- Der Countdown wird ebenfalls gesendet
        }
        -- Broadcast an alle (alternativ: rednet.send(ID, daten))
        rednet.broadcast(daten, "zuginfo")
    end
end

-- Anzeige der Zuginformationen auf dem Monitor
local function anzeigen()
    monitor.clear()

    -- Zeile 1: Linie -> Ziel
    monitor.setTextColor(linienFarbe)
    centerText("Linie " .. linienName .. " -> " .. zugInfo.ziel, 1)

    -- Zeile 2: Countdown
    monitor.setTextColor(colors.white)
    local countdownText, _ = formatTimeLeft()
    centerText(countdownText, 2)  -- "in" entfernt, nur Countdown angezeigt

    -- Zeile 3: via Ostbahnhof
    monitor.setTextColor(colors.yellow)
    centerText(zugInfo.via, 3)  -- "via Ostbahnhof" wird hier angezeigt

    -- Zeile 4: Datum & Uhrzeit
    monitor.setTextColor(colors.gray)
    centerText(getFormattedDateTime(), 4)
end

-- Redstone-Reset (steigende Flanke)
local redstoneWasHigh = false
local function checkRedstoneReset()
    local current = redstone.getInput(redstoneSeite)
    if current and not redstoneWasHigh then
        -- Wenn Redstone aktiviert, Abfahrtszeit zurücksetzen
        local now = getTime()
        zugInfo.abfahrt = now + abfahrtsDauer  -- Setze die Abfahrtszeit neu
        print("Redstone-Signal empfangen - Abfahrtszeit zurückgesetzt.")
    end
    redstoneWasHigh = current
end

-- Hauptloop
local sendeIntervall = 2  -- alle 2 Sekunden
local letzteSendung = 0

local function formatAbfahrt(abfahrtEpochMs)
    -- Berechnet die verbleibende Zeit in Sekunden
    local verbleibendeZeit = abfahrtEpochMs - os.epoch("utc") / 1000
    print
    if verbleibendeZeit <= 0 then
        return "sofort" -- Wenn die Zeit abgelaufen ist
    else
        local minuten = math.floor(verbleibendeZeit / 60) -- Berechnet die Minuten
        local sekunden = math.floor(verbleibendeZeit % 60) -- Berechnet die verbleibenden Sekunden
        return string.format("%02d:%02d", minuten, sekunden) -- Formatiert als mm:ss
    end
end

while true do
    local now = getTime()

    -- Überprüfe den Redstone-Eingang und setze den Timer zurück, wenn ein Signal empfangen wird
    checkRedstoneReset()

    -- Alle 2 Sekunden Zuginformation senden
    if now - letzteSendung >= sendeIntervall then
        sendeZugInfo()
        letzteSendung = now
    end

    -- Anzeige aktualisieren
    anzeigen()

    -- Kurze Pause
    sleep(0.1)
end
