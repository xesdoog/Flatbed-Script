# Flatbed script for YimMenu _[WIP]_ 

![flatbed_script](https://github.com/xesdoog/Flatbed-Script/assets/66764345/09e381d0-924b-4ffd-b2d4-3617d06b963f)

> [!WARNING]
> This is still a work in progress. **DO NOT** try to tow other players' personal vehicles. If you do and end up breaking your game or getting banned as a result, I will not be responsible and I will not help you solve any issues.

## General Knowledge:
- If you are not inside a flatbed truck, the script will let you know that you have to spawn one and will provide you with a button to do so.
#### Default Settings:
- ✅ **Vehicles you can tow:**
  - Your personal vehicle. *(Online and single player)*
  - NPC vehicles. *(You can kidnap npcs)*
  - Emergency vehicles. *(Police, Ambulance, Military... You can kidnap them too)*
- ❌ **Vehicles you can not tow:**
  - Boats, planes and helicopters.
    > _Mission vehicles? I'm not sure, I haven't tested them._
#### Using "*Tow Everything*" option:
 - ✅ **Vehicles you can tow:**
    - Everything. *(with bugs)*
## Usage
1. Get inside a flatbed truck.
   > You can hijack one from the street *(they usually spawn near [Elysian Island](https://gta.fandom.com/wiki/Elysian_Island?file=ElysianIsland-IngameGPS-GTAV-Map.png))* or spawn one using either YimMenu or this script itself.
2. Park in front of the vehicle you want to tow.
   > The detection area is behind the Tow truck. You can see the exact area by enabling "*Show Towing Position*" in the script.
3. Press **Tow** button in the script UI or vehicle duck button (Defalut: **[X]** on keyboard, **[A]** on controller).

![flatbed_script(1)](https://github.com/xesdoog/Flatbed-Script/assets/66764345/296f5b47-64fa-4d39-b386-f081412f40c8)

## Known Issues:
- Towed vehicle position is not consistent. Some will clip through the flatbed and others will sit higher.

## To Do:
- [x] ~Fix position of towed vehicles based on vehicle's size or class. *(in progress)* https://github.com/xesdoog/Flatbed-Script/issues/1~ ✅**Somewhat done!** This is a manual fix. The user would have to use arrows to manually adjust the towed vehicle's position.
- [x] ~Use another logic for finding nearby vehicles, therefore including more *if not all* GTA vehicles. *(Towing a plane still won't make sense though but whatever)*~ ✅**Done.**
  > Boats, planes and helicopters are disabled by default except the Buzzard. You can activate the "*Tow Everything*" option to enable towing for all GTA vehicles.
