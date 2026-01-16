# demon-windows

Dual-boot gaming partition (Windows side of the demon host).

## Hostname

Set your Windows hostname to `demon-windows`:

```powershell
Rename-Computer -NewName "demon-windows" -Restart
```

## What's Installed

- Steam, Valorant, Discord
- NVIDIA GeForce Experience
- OBS Studio
- Chrome

## Customization

To add/remove apps, edit `apps.winget` in this directory.
