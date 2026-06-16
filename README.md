# deploy_agent_lizaituze1

## How to Run the Script

chmod +x setup_project.sh
./setup_project.sh

Enter a project name like v1 when prompted.

## What the Script Does

1. Creates the full attendance_tracker_{name}/ folder structure
2. Writes all project files automatically
3. Lets you update attendance thresholds via config.json using sed
4. Checks if python3 is installed
5. Verifies all files are in the correct locations

## How to Trigger the Archive Feature

Run the script and press Ctrl+C at any point after the folders are created.

The script will:
1. Bundle the incomplete folder into attendance_tracker_{name}_archive.tar.gz
2. Delete the incomplete folder
3. Exit cleanly

## How to Run the Attendance App

cd attendance_tracker_v1
python3 attendance_checker.py
