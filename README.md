## BlueBench
Tests both i965 and iHD drivers for performance comparison. Firefox on Linux distros has them backlisted.

To run:
```
chmod +x benchmark.sh
./benchmark.sh
```
## Quick manual test:
```
# Test i965 performance
LIBVA_DRIVER_NAME=i965 ffmpeg -hwaccel vaapi -f lavfi -i testsrc=duration=10:size=1920x1080:rate=30 -c:v h264_vaapi test_i965.mp4

# Test iHD performance  
LIBVA_DRIVER_NAME=iHD ffmpeg -hwaccel vaapi -f lavfi -i testsrc=duration=10:size=1920x1080:rate=30 -c:v h264_vaapi test_iHD.mp4
```
