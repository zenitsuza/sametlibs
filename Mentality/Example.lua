local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/sametexe001/sametlibs/refs/heads/main/Mentality/Library.lua"))()


local Window = Library:Window({
    Name = "Window",
    SubName = "sub name",
    Logo = "120959262762131"
})

local KeybindList = Library:KeybindList("keys loll fucker")

local ESPPage = Window:Page({Name = "ESP", Icon = "100050851789190", Columns = 1})
local SettingsPage = Library:CreateSettingsPage(Window, KeybindList)

local GlobalChat = ESPPage:GlobalChat(1)

local Name = "spongebob"
local Status = false
local Avatar = "rbxassetid://78993485446406"
local Count = 0
GlobalChat:OnMessageSendPressed(function()
    Count += 1
    if Count == 1 then
        Avatar = "rbxassetid://78993485446406"
        Name = "spongebob"
        Status = true
    elseif Count == 2 then
        Avatar = "rbxassetid://136061992085389"
        Name = "patrick"
        Status = false
    elseif Count == 3 then
        Avatar = "rbxassetid://92657697206261"
        Count = 0
        Name = "squidward"
        Status = false
    end

    GlobalChat:SendMessage(Avatar, Name, GlobalChat:GetTypedMessage(), Status)
end)

Library:Notification({
    Title = "Notification title",
    Description = "Notification description",
    Duration = 5,
    Icon = "73789337996373",
    --IconColor = {
        --Start = Color3.fromRGB(255, 255, 255),
        --End = Color3.fromRGB(0, 0, 0)
   -- }
})

Window:Init()
