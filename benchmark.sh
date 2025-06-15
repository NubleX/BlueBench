#!/bin/bash

echo "=== VA-API Driver Benchmark ==="
echo "Testing Intel Iris Graphics 540 drivers"
echo

for tool in ffmpeg time vainfo; do
    if ! command -v $tool &> /dev/null; then
        echo "Error: $tool not found. Install with: sudo apt install ffmpeg time vainfo"
        exit 1
    fi
done

# Create test video if it doesn't exist :)

TEST_VIDEO="test_video.mp4"
if [ ! -f "$TEST_VIDEO" ]; then
    echo "Creating test video..."
    ffmpeg -f lavfi -i testsrc=duration=30:size=1920x1080:rate=30 -c:v libx264 -preset fast "$TEST_VIDEO" -y
fi

echo "Test video: $TEST_VIDEO (30s, 1080p, H.264)"
echo

test_driver() {
    local driver=$1
    local output_file="benchmark_${driver}.mp4"
    
    echo "Testing $driver driver..."
    echo "Driver info:"
    LIBVA_DRIVER_NAME=$driver vainfo | head -5
    echo
    
    echo "Hardware decode test:"
    export LIBVA_DRIVER_NAME=$driver
    /usr/bin/time -f "Time: %es, CPU: %P, Memory: %MkB" \
        ffmpeg -hwaccel vaapi -hwaccel_device /dev/dri/renderD128 \
               -i "$TEST_VIDEO" -f null - -v quiet 2>&1
    echo
    
    echo "Hardware encode test:"
    /usr/bin/time -f "Time: %es, CPU: %P, Memory: %MkB" \
        ffmpeg -hwaccel vaapi -hwaccel_device /dev/dri/renderD128 \
               -i "$TEST_VIDEO" -c:v h264_vaapi -b:v 2M "$output_file" -y -v quiet 2>&1
    echo
    
    # Firefox-specific test! FF hates intel chips.

    echo "Testing Firefox compatibility:"
    MOZ_DISABLE_RDD_SANDBOX=1 LIBVA_DRIVER_NAME=$driver timeout 10s firefox --headless \
        --new-instance --profile /tmp/ff_test_$driver https://www.youtube.com/watch?v=dQw4w9WgXcQ 2>/dev/null
    echo "Firefox test completed (check about:support in actual Firefox)"
    echo
    
    rm -f "$output_file"
    unset LIBVA_DRIVER_NAME
}

echo "=== Testing i965 driver ==="
test_driver "i965"

echo "=== Testing iHD driver ==="
test_driver "iHD"

echo "=== System Info ==="
echo "GPU: $(lspci | grep VGA)"
echo "Mesa: $(glxinfo | grep "OpenGL version")"
echo "Kernel: $(uname -r)"
echo

echo "=== Recommendations ==="
echo "Compare the benchmark results:"
echo "- Lower CPU usage = better hardware acceleration"
echo "- Faster encoding time = better performance"
echo "- Check Firefox compatibility for video playback"
echo
echo "To permanently set driver:"
echo "echo 'export LIBVA_DRIVER_NAME=<best_driver>' >> ~/.bashrc"

rm -f "$TEST_VIDEO"
rm -rf /tmp/ff_test_*
