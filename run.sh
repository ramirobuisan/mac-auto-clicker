#!/bin/bash
set -e

# Build the app
./build.sh

# Run the app
echo "🚀 Launching MacAutoClicker..."
open MacAutoClicker.app
