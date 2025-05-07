local apps =
{
    "A" = "Arc",
}
for key, app in pairs(apps) do
    hs.hotkey.bind({"opt"}, key, function()
        hs.application.launchOrFocus(app)
    end)
end
