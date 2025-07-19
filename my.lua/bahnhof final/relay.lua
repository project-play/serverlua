local modem = peripheral.find("modem")
if modem then
    rednet.open(peripheral.getName(modem)) -- Öffne Rednet für das Modem
else
    print("Kein Modem gefunden – Rednet deaktiviert.")
end