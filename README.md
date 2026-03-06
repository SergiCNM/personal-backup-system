# Personal Backup Script

This project contains a flexible PowerShell script (`backup_personal.ps1`) designed to back up files from multiple sources, including Android devices and local drives, to a central backup location.

<img width="871" height="476" alt="terminal" src="https://github.com/user-attachments/assets/9f27d653-6332-4c66-9977-fed0680223a3" />


## Requirements

- **An Android device**. This script relies on ADB, so iOS devices are not supported.
- Android Debug Bridge (`adb`) installed and added to your system's PATH. You can download the Android SDK Platform-Tools from [here](https://developer.android.com/tools/releases/platform-tools).
- USB Debugging enabled on your Android device.
- The phone connected to the PC via USB.

## Configuration

This script uses a configuration file named `config_personal.json` located in the same directory as the script. You must create or edit this file to define the sources you want to back up and the specific destination folder for each one.

The script supports two types of sources:
- `"android"`: Copies files from a connected Android device using ADB.
- `"local"`: Copies files from another local drive or folder connection.

Example `config_personal.json`:

```json
{
  "sources": [
    {
      "type": "android",
      "path": "/sdcard/DCIM/Camera",
      "destination": "F:\\BACKUPS\\PERSONAL\\POCO F5\\Camera"
    },
    {
      "type": "local",
      "path": "D:\\OtherPhotos\\ToBackup",
      "destination": "F:\\BACKUPS\\PERSONAL\\OtherPhotos"
    }
  ]
}
```

## Usage

1. Open a PowerShell terminal.
2. Run the script:
   ```powershell
   .\backup_personal.ps1
   ```

## How it works

The script performs the following actions:
1. Reads `config_personal.json` to get the list of sources.
2. Iterates over each source defined in the configuration.
3. Uses the exact `destination` path provided. It will automatically create the folder or its parent structure if it does not already exist.
4. If a source is an `"android"` type, it uses `adb pull` to copy the device folder contents to the exact destination on the PC, bypassing the default adb behavior that often creates duplicate subfolders (e.g. `Camera\Camera`).
5. If a source is a `"local"` type, it uses standard PowerShell commands to copy the folder contents to the exact destination.
6. Outputs progress messages to the console during execution.
7. Displays a clean final summary indicating the total number of files securely stored across all backup destinations, any errors encountered, the combined total size in megabytes, and the total execution time of the script.
