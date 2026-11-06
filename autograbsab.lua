local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")

local player = Players.LocalPlayer
local TARGET_PLACE = 85621847059032

print("========== LTM TELEPORT ==========")
print("Jugador:", player.Name)
print("Place actual:", game.PlaceId)
print("Place destino:", TARGET_PLACE)

TeleportService.TeleportInitFailed:Connect(
    function(plr, result, message, placeId)
        if plr == player then
            warn("TELEPORT FALLIDO")
            warn("Resultado:", result)
            warn("Mensaje:", message)
            warn("Destino:", placeId)
        end
    end
)

local success, err = pcall(function()
    TeleportService:Teleport(TARGET_PLACE, player)
end)

if success then
    print("Solicitud de teleport enviada.")
else
    warn("Error al iniciar:", tostring(err))
end
