#!/bin/bash

cleanup() {
    echo ""
    echo "Interrupt caught! Saving your progress before exiting..."

    if [ -d "attendance_tracker_${PROJECT_NAME}" ]; then
        tar -czf "attendance_tracker_${PROJECT_NAME}_archive.tar.gz" \
            "attendance_tracker_${PROJECT_NAME}"
        echo "Archive saved: attendance_tracker_${PROJECT_NAME}_archive.tar.gz"
        rm -rf "attendance_tracker_${PROJECT_NAME}"
        echo "Incomplete directory removed."
    else
        echo "Nothing to archive yet."
    fi

    echo "Exiting. Goodbye!"
    exit 1
}

trap cleanup SIGINT

echo "================================================"
echo "   Student Attendance Tracker - Project Setup"
echo "================================================"
echo ""

read -rp "Enter a project name (e.g. v1, dev, prod): " PROJECT_NAME

if [ -z "$PROJECT_NAME" ]; then
    echo "Error: Project name cannot be empty. Exiting."
    exit 1
fi

ROOT_DIR="attendance_tracker_${PROJECT_NAME}"

echo ""
echo "Creating directory structure..."

if [ -d "$ROOT_DIR" ]; then
    echo "Warning: '$ROOT_DIR' already exists. Continuing with existing folder."
else
    mkdir -p "$ROOT_DIR"
fi

mkdir -p "$ROOT_DIR/Helpers"
mkdir -p "$ROOT_DIR/reports"

echo "Folders created."

echo "Writing project files..."

cat > "$ROOT_DIR/attendance_checker.py" << 'PYEOF'
import csv
import json
import os
from datetime import datetime

def run_attendance_check():
    with open('Helpers/config.json', 'r') as f:
        config = json.load(f)

    if os.path.exists('reports/reports.log'):
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        os.rename('reports/reports.log', f'reports/reports_{timestamp}.log.archive')

    with open('Helpers/assets.csv', mode='r') as f, open('reports/reports.log', 'w') as log:
        reader = csv.DictReader(f)
        total_sessions = config['total_sessions']

        log.write(f"--- Attendance Report Run: {datetime.now()} ---\n")

        for row in reader:
            name = row['Names']
            email = row['Email']
            attended = int(row['Attendance Count'])

            attendance_pct = (attended / total_sessions) * 100

            message = ""
            if attendance_pct < config['thresholds']['failure']:
                message = f"URGENT: {name}, your attendance is {attendance_pct:.1f}%. You will fail this class."
            elif attendance_pct < config['thresholds']['warning']:
                message = f"WARNING: {name}, your attendance is {attendance_pct:.1f}%. Please be careful."

            if message:
                if config['run_mode'] == "live":
                    log.write(f"[{datetime.now()}] ALERT SENT TO {email}: {message}\n")
                    print(f"Logged alert for {name}")
                else:
                    print(f"[DRY RUN] Email to {email}: {message}")

if __name__ == "__main__":
    run_attendance_check()
PYEOF

cat > "$ROOT_DIR/Helpers/assets.csv" << 'CSVEOF'
Email,Names,Attendance Count,Absence Count
alice@example.com,Alice Johnson,14,1
bob@example.com,Bob Smith,7,8
charlie@example.com,Charlie Davis,4,11
diana@example.com,Diana Prince,15,0
CSVEOF

cat > "$ROOT_DIR/Helpers/config.json" << 'JSONEOF'
{
    "thresholds": {
        "warning": 75,
        "failure": 50
    },
    "run_mode": "live",
    "total_sessions": 15
}
JSONEOF

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Project '${ROOT_DIR}' initialized." \
    > "$ROOT_DIR/reports/reports.log"

echo "All files written."

echo ""
echo "------------------------------------------------"
echo "Attendance Threshold Configuration"
echo "Current defaults - Warning: 75%  |  Failure: 50%"
echo "------------------------------------------------"

read -rp "Update thresholds? (yes/no): " UPDATE_CONFIG

if [[ "$UPDATE_CONFIG" == "yes" || "$UPDATE_CONFIG" == "y" ]]; then

    read -rp "  New Warning threshold % (default 75): " WARN_VAL
    WARN_VAL="${WARN_VAL:-75}"

    if ! [[ "$WARN_VAL" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        echo "  Invalid input. Keeping default (75)."
        WARN_VAL=75
    fi

    read -rp "  New Failure threshold % (default 50): " FAIL_VAL
    FAIL_VAL="${FAIL_VAL:-50}"

    if ! [[ "$FAIL_VAL" =~ ^[0-9]+([.][0-9]+)?$ ]]; then
        echo "  Invalid input. Keeping default (50)."
        FAIL_VAL=50
    fi

    sed -i "s/\"warning\": [0-9]*/\"warning\": $WARN_VAL/" \
        "$ROOT_DIR/Helpers/config.json"
    sed -i "s/\"failure\": [0-9]*/\"failure\": $FAIL_VAL/" \
        "$ROOT_DIR/Helpers/config.json"

    echo "config.json updated - Warning: ${WARN_VAL}%  |  Failure: ${FAIL_VAL}%"
else
    echo "Keeping default thresholds."
fi

echo ""
echo "------------------------------------------------"
echo "Environment Health Check"
echo "------------------------------------------------"

if python3 --version &>/dev/null; then
    PY_VER=$(python3 --version 2>&1)
    echo "Python3 found: $PY_VER"
else
    echo "Warning: python3 not found. Install it before running attendance_checker.py."
fi

echo ""
echo "Verifying structure..."
ALL_GOOD=true
for FILE in \
    "$ROOT_DIR/attendance_checker.py" \
    "$ROOT_DIR/Helpers/assets.csv" \
    "$ROOT_DIR/Helpers/config.json" \
    "$ROOT_DIR/reports/reports.log"; do
    if [ -f "$FILE" ]; then
        echo "   Found: $FILE"
    else
        echo "   MISSING: $FILE"
        ALL_GOOD=false
    fi
done

echo ""
echo "================================================"
if [ "$ALL_GOOD" = true ]; then
    echo "Setup complete! Your project is ready."
else
    echo "Setup finished with warnings. Check missing files above."
fi
echo "================================================"
echo ""
echo "  Project folder : $ROOT_DIR/"
echo "  Run the app    : cd $ROOT_DIR && python3 attendance_checker.py"
echo "  Archive trigger: Press Ctrl+C while this script runs"
echo ""
