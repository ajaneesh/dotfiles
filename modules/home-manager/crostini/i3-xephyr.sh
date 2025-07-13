#!/usr/bin/env bash

# i3-xephyr: Launch i3 window manager in a nested X server using Xephyr
# This allows running i3 on systems where another window manager is already running

# Find an available display number
DISPLAY_NUM=1
while [ -S "/tmp/.X11-unix/X${DISPLAY_NUM}" ] || [ -f "/tmp/.X${DISPLAY_NUM}-lock" ]; do
    DISPLAY_NUM=$((DISPLAY_NUM + 1))
done

XEPHYR_DISPLAY=":${DISPLAY_NUM}"

# Auto-detect display size and use 80% of it
DISPLAY_INFO=$(xrandr | grep ' connected' | head -1 | grep -o '[0-9]*x[0-9]*')
if [ -n "$DISPLAY_INFO" ]; then
    WIDTH=$(echo $DISPLAY_INFO | cut -d'x' -f1)
    HEIGHT=$(echo $DISPLAY_INFO | cut -d'x' -f2)
    # Use 80% of display size
    SCREEN_WIDTH=$((WIDTH * 80 / 100))
    SCREEN_HEIGHT=$((HEIGHT * 80 / 100))
    SCREEN_SIZE="${SCREEN_WIDTH}x${SCREEN_HEIGHT}"
else
    # Fallback size
    SCREEN_SIZE="1400x900"
fi

echo "Using display ${XEPHYR_DISPLAY} with size ${SCREEN_SIZE}"

# Kill any existing Xephyr instance on our display
pkill -f "Xephyr.*:${DISPLAY_NUM}"

# Start Xephyr in the background with higher DPI for larger fonts and resizable window
Xephyr "${XEPHYR_DISPLAY}" -ac -host-cursor -reset -terminate -dpi 144 -screen "${SCREEN_SIZE}" -resizeable &
XEPHYR_PID=$!

# Wait for Xephyr to start
sleep 3

# Check if Xephyr is running
if ! kill -0 $XEPHYR_PID 2>/dev/null; then
    echo "Failed to start Xephyr"
    exit 1
fi

# Start i3 in the nested X server
echo "Starting i3 on display ${XEPHYR_DISPLAY}..."
DISPLAY="${XEPHYR_DISPLAY}" i3 &
I3_PID=$!

# Wait a bit for i3 to start
sleep 2

# i3 is now running with the keybinding from config

# Focus the Xephyr window by starting a simple application
DISPLAY="${XEPHYR_DISPLAY}" xterm -fa "DejaVu Sans Mono" -fs 10 -e "echo 'i3 workspace ready. Use Alt+Enter for terminal, Alt+d for dmenu, Alt+p for rofi'; sleep 2" &

# Function to cleanup on exit
cleanup() {
    echo "Cleaning up..."
    [ -n "$I3_PID" ] && kill "$I3_PID" 2>/dev/null
    [ -n "$XEPHYR_PID" ] && kill "$XEPHYR_PID" 2>/dev/null
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

echo "i3 running in Xephyr on display ${XEPHYR_DISPLAY}"
echo "Press Ctrl+C to exit"

# Wait for processes to finish
wait $I3_PID
cleanup