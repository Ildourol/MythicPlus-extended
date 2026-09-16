# MythicPlus Client Setup

To make the MythicPlus features work correctly, you need to create a custom patch file for your WoW client.

## Creating Your Custom Patch File

### Required Files

You need to include these files in your custom patch:

**Textures:**
- `Interface/Icons/inv_relics_hourglass.blp`
- `Interface/MythicPlus/textures/Banner.blp`
- `Interface/MythicPlus/textures/BigTimerNumbers.blp`
- `Interface/MythicPlus/textures/Border_Bottom.blp`
- `Interface/MythicPlus/textures/Border_Left.blp`
- `Interface/MythicPlus/textures/Border_Right.blp`
- `Interface/MythicPlus/textures/Border_Top.blp`
- `Interface/MythicPlus/textures/Border.blp`
- `Interface/MythicPlus/textures/MythicBar.blp`
- `Interface/MythicPlus/textures/MythicFrame.blp`
- `Interface/MythicPlus/textures/Paper.blp`
- `Interface/MythicPlus/textures/VaultFrame.blp`

**Sounds:**
- `Interface/MythicPlus/sounds/UI_BattlegroundCountdown_End.ogg`
- `Interface/MythicPlus/sounds/UI_BattlegroundCountdown_Timer.ogg`

All these files are available in the `Data/Client/Raw/all/` folder.

### Step-by-Step Guide

1. **Download an MPQ Editor**
   - We recommend [Ladik's MPQ Editor](https://www.hiveworkshop.com/threads/ladiks-mpq-editor.249562/)

2. **Create a New MPQ File**
   - Open your MPQ editor and create a new MPQ file
   - Name it `Patch-Z.MPQ` (or something that loads after other patches alphabetically)

3. **Add the Required Files**
   - Add all files from the list above, preserving their folder structure
   - Example: `Data/Client/Raw/all/Interface/Icons/inv_relics_hourglass.blp` should be added as `Interface/Icons/inv_relics_hourglass.blp`

4. **Optional: Add Keystone Icon Support**
   - Without this step, the Mythic Keystone will show as a question mark icon
   - There are two ways to implement this:

   **Option 1: Direct DBC Modification** (Advanced)
   - Extract your current `item.dbc` and `ItemDisplayInfo.dbc` from the game files
   - Use [WDBXEditor](https://github.com/WowDevTools/WDBXEditor) to open and modify these files
   - Import the CSV data from:
     - `Data/Client/Raw/changes/Item.csv` → into `item.dbc`
     - `Data/Client/Raw/changes/ItemDisplayInfo.csv` → into `ItemDisplayInfo.dbc`
   - Save the modified DBC files and add them to your MPQ at `DBFilesClient/Item.dbc` and `DBFilesClient/ItemDisplayInfo.dbc`

   **Option 2: CSV Import** (Easier)
   - Open your DBC files in WDBXEditor
   - Choose "Import" -> "Import from CSV"
   - Select the CSV files from `Data/Client/Raw/changes/`
   - Ensure these options are selected:
     - "Import New"
     - "Has Header Row?"
     - "Take Newest"
   - Save the modified DBC files and add them to your MPQ

5. **Final MPQ Structure**
   Your MPQ should contain:

   ```
   DBFilesClient/              (optional - only if adding icon support)
       Item.dbc
       ItemDisplayInfo.dbc
   Interface/
       Icons/
           inv_relics_hourglass.blp
       MythicPlus/
           sounds/
               UI_BattlegroundCountdown_End.ogg
               UI_BattlegroundCountdown_Timer.ogg
           textures/
               Banner.blp
               BigTimerNumbers.blp
               Border_Bottom.blp
               Border_Left.blp
               Border_Right.blp
               Border_Top.blp
               Border.blp
               MythicBar.blp
               MythicFrame.blp
               Paper.blp
               VaultFrame.blp
   ```

6. **Install the Patch**
   - Place your completed `Patch-Z.MPQ` file in your WoW client's `Data` folder
   - The path should be: `.../World of Warcraft/Data/Patch-Z.MPQ`
   - Restart your WoW client completely

## Important Notes

- **DBC IDs**: We use specific IDs in the DBC files:
  - `item.dbc`: IDs 900100, 900101, 900102
  - `ItemDisplayInfo.dbc`: ID 62471
  - If you have existing content using these IDs, they will be overwritten

- **File Names**: Ensure all file paths and names match exactly as listed (case-sensitive)

- **Load Order**: Your patch file needs to load after other patches. Use a name that comes alphabetically last (like `Patch-Z.MPQ`)

- **Missing Keystone Icon**: If you skip the DBC modification steps, the keystone will still function normally, but will display with a question mark icon

## Troubleshooting

If textures or sounds aren't working:

1. **Verify MPQ Structure**: Check that all files are in the correct paths within your MPQ
2. **Check Load Order**: Ensure your patch loads after other patches (check alphabetical order)
3. **Full Client Restart**: Completely exit and restart your WoW client
4. **File Corruption**: Re-copy the original files from `Data/Client/Raw/all/`
