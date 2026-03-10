# bash

# brotli
# bash build-apple.sh

# Export documentation to pdf
# groff -man -Tps ./man3/types.h.3 | ps2pdf - types.pdf
# groff -man -Tps ./man3/constants.h.3 | ps2pdf - constants.pdf
# groff -man -Tps ./man3/decode.h.3 | ps2pdf - decode.pdf
# groff -man -Tps ./man3/encode.h.3 | ps2pdf - encode.pdf


# Define some global variables
ft_developer="/Applications/Xcode.app/Contents/Developer"
# Your signing identity to sign the xcframework. Execute "security find-identity -v -p codesigning" and select one from the list
identity=YOUR_SIGNING_IDENTITY

# Android NDK path
ndk_path="/Users/evgenij/Library/Android/sdk/ndk/29.0.13846066"


# Output library name. Determined by the build system. Try to change the name if possible in the future
libname=brotli
# Source code folder name
source_name="brotli-1.2.0"
output_name="brotli"


# Console output formatting
# https://stackoverflow.com/a/2924755
bold=$(tput bold)
normal=$(tput sgr0)

last_directory=$(pwd)


# Remove logs if exist
# rm -f "build/log.txt"


exit_if_error() {
  local result=$?
  if [ $result -ne 0 ] ; then
     echo "Received an exit code $result, aborting"
     cd "$last_directory"
     exit 1
  fi
}


build_library() {
  local platform=$1
  local arch=$2
  local min_os=$3

  # Reset variables
  export LT_SYS_LIBRARY_PATH=""
  export AR=""
  export CC=""
  export AS=""
  export CXX=""
  export LD=""
  export RANLIB=""
  export STRIP=""
  export CPPFLAGS=""
  export CFLAGS=""

  # Determine host based on platform and architecture
  # Apple
  if [[ "$platform" == "MacOSX" ]] || \
    [[ "$platform" == "iPhoneOS" ]] || [[ "$platform" == "iPhoneSimulator" ]] || \
    [[ "$platform" == "AppleTVOS" ]] || [[ "$platform" == "AppleTVSimulator" ]] || \
    [[ "$platform" == "WatchOS" ]] || [[ "$platform" == "WatchSimulator" ]] || \
    [[ "$platform" == "XROS" ]] || [[ "$platform" == "XRSimulator" ]]; then
    local os_family="Apple"

    if   [[ "$arch" == "arm64" ]];  then local host="arm-apple-darwin"
    elif [[ "$arch" == "x86_64" ]]; then local host="x86_64-apple-darwin"
    fi

    local sysroot="$ft_developer/Platforms/$platform.platform/Developer/SDKs/$platform.sdk"
    local arch_flags="-arch $arch"
    local target_os_flags="-mtargetos=$min_os"
    export CC="$ft_developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang"
    export CXX="$ft_developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang++"
    #export LD="$ft_developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/ld"
    export LT_SYS_LIBRARY_PATH="-isysroot $sysroot/usr/include"
    export CPPFLAGS="-I$sysroot/usr/include"
    export CFLAGS="-isysroot $sysroot $arch_flags -std=c17 $target_os_flags -O2"
    export CXXFLAGS="-isysroot $sysroot $arch_flags -std=c++20 $target_os_flags -O2"

  # Android
  elif [[ "$platform" == "Android" ]]; then
    local os_family="Android"

    if   [[ "$arch" == "aarch64" ]];  then local host="aarch64-linux-android"
    elif [[ "$arch" == "arm" ]];      then local host="arm-linux-androideabi"
    elif [[ "$arch" == "i686" ]];     then local host="i686-linux-android"
    elif [[ "$arch" == "riscv64" ]];  then local host="riscv64-linux-android"
    elif [[ "$arch" == "x86_64" ]];   then local host="x86_64-linux-android"
    fi

    local sysroot="$ndk_path/toolchains/llvm/prebuilt/darwin-x86_64/sysroot"
    local arch_flags=""
    local target_os_flags="--target=$host$min_os"
    export LT_SYS_LIBRARY_PATH=""

    local toolchain="$ndk_path/toolchains/llvm/prebuilt/darwin-x86_64"
    export AR=$toolchain/bin/llvm-ar
    export CC="$toolchain/bin/clang"
    export AS=$CC
    export CXX="$toolchain/bin/clang++"
    export LD=$toolchain/bin/ld
    export RANLIB=$toolchain/bin/llvm-ranlib
    export STRIP=$toolchain/bin/llvm-strip

    export CPPFLAGS=""
    export CFLAGS="-std=c17 $target_os_flags -O2"
    export CXXFLAGS="-std=c++20 $target_os_flags -O2"

  else
    echo "Unknown platform $platform"
    exit 1
  fi

  # Determine ASTC compression feature flags (probably to improve performance) or noting if not supported
  if [[ "$os_family" == "Apple" ]]; then
    local make_program=""
    local android_settings=""

  elif [[ "$platform" == "Android" ]]; then
    local make_program="-DCMAKE_TOOLCHAIN_FILE=${ndk_path}/build/cmake/android.toolchain.cmake"
    local android_common_settings="-DANDROID_PLATFORM=android-$min_os -DANDROID_TOOLCHAIN=clang -DANDROID_STL=c++_static"

    # Android ABIs
    # https://developer.android.com/ndk/guides/abis
    if [[ "$arch" == "aarch64" ]];  then
      local android_settings="-DANDROID_ABI=arm64-v8a $android_common_settings"
    elif [[ "$arch" == "arm" ]]; then
      local android_settings="-DANDROID_ABI=armeabi-v7a $android_common_settings"
    elif [[ "$arch" == "i686" ]]; then
      local android_settings="-DANDROID_ABI=x86 $android_common_settings"
    elif [[ "$arch" == "riscv64" ]]; then
      local android_settings="-DANDROID_ABI=riscv64 $android_common_settings"
    elif [[ "$arch" == "x86_64" ]]; then
      local android_settings="-DANDROID_ABI=x86_64 $android_common_settings"
    fi
  fi

  # Are we sure that we need to specify the architecture for the linker?
  export LDFLAGS="$arch_flags"

  # Welcome message
  echo "Build for ${bold}$platform $host${normal}"

  # Clean
  #make clean

  # Remove previously build foler for the specified platform and architecture if exists
  rm -rf "build/$platform/$arch"
  mkdir -p "build/$platform/$arch/tmp"

  # Configure for the specified platform and architecture
  cd build/$platform/$arch/tmp
  cmake ../../../../$source_name \
    -DCMAKE_BUILD_TYPE=Release\
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_INSTALL_PREFIX=../install \
    -DCMAKE_OSX_SYSROOT=${sysroot} \
    -DCMAKE_OSX_ARCHITECTURES=$arch \
    $make_program \
    $android_settings
  exit_if_error

  # Build
  #make -j$(sysctl -n hw.ncpu)
  cmake --build . --config Release --target install
  exit_if_error

  # Go back
  cd ../../../..

  # Remove temporary build data
  rm -rf "build/$platform/$arch/tmp"

  # Copy the module map into the directory with installed header files
  mkdir -p build/$platform/$arch/install/$libname
  cp -r Contents/libbrotlicommon build/$platform/$arch/install/$libname/libbrotlicommon
  cp build/$platform/$arch/install/include/brotli/port.h build/$platform/$arch/install/$libname/libbrotlicommon/headers/brotli/port.h
  cp build/$platform/$arch/install/include/brotli/types.h build/$platform/$arch/install/$libname/libbrotlicommon/headers/brotli/types.h
  cp build/$platform/$arch/install/include/brotli/shared_dictionary.h build/$platform/$arch/install/$libname/libbrotlicommon/headers/brotli/shared_dictionary.h

  cp -r Contents/libbrotlienc build/$platform/$arch/install/$libname/libbrotlienc
  cp build/$platform/$arch/install/include/brotli/encode.h build/$platform/$arch/install/$libname/libbrotlienc/headers/brotli/encode.h

  cp -r Contents/libbrotlidec build/$platform/$arch/install/$libname/libbrotlidec
  cp build/$platform/$arch/install/include/brotli/decode.h build/$platform/$arch/install/$libname/libbrotlidec/headers/brotli/decode.h

  exit_if_error

}

# Build for Apple systems
# build_library MacOSX           arm64  macos11
# build_library MacOSX           x86_64 macos10.13
# build_library iPhoneOS         arm64  ios12
# build_library iPhoneSimulator  arm64  ios14-simulator
# build_library iPhoneSimulator  x86_64 ios12-simulator
# build_library AppleTVOS        arm64  tvos12
# build_library AppleTVSimulator arm64  tvos12-simulator
# build_library AppleTVSimulator x86_64 tvos12-simulator
# build_library WatchOS          arm64  watchos8
# build_library WatchSimulator   arm64  watchos8-simulator
# build_library WatchSimulator   x86_64 watchos8-simulator
# build_library XROS             arm64  xros1
# build_library XRSimulator      arm64  xros1-simulator
# build_library XRSimulator      x86_64 xros1-simulator

# Build for Android
# build_library Android aarch64 21
# build_library Android arm     21
# build_library Android i686    21
# build_library Android riscv64 35
# build_library Android x86_64  21


create_framework() {
  local target_lib=$1

  # Remove previously created framework if exists
  rm -rf build/$target_lib.xcframework
  exit_if_error

  # Merge macOS arm and x86 binaries
  mkdir -p build/MacOSX
  exit_if_error
  lipo -create -output build/MacOSX/$target_lib.a \
    build/MacOSX/arm64/install/lib/$target_lib.a \
    build/MacOSX/x86_64/install/lib/$target_lib.a
  exit_if_error

  # Merge iOS simulator arm and x86 binaries
  mkdir -p build/iPhoneSimulator
  exit_if_error
  lipo -create -output build/iPhoneSimulator/$target_lib.a \
    build/iPhoneSimulator/arm64/install/lib/$target_lib.a \
    build/iPhoneSimulator/x86_64/install/lib/$target_lib.a
  exit_if_error

  # Merge tvOS simulator arm and x86 binaries
  mkdir -p build/AppleTVSimulator
  exit_if_error
  lipo -create -output build/AppleTVSimulator/$target_lib.a \
    build/AppleTVSimulator/arm64/install/lib/$target_lib.a \
    build/AppleTVSimulator/x86_64/install/lib/$target_lib.a
  exit_if_error

  # Merge watchOS simulator arm and x86 binaries
  mkdir -p build/WatchSimulator
  exit_if_error
  lipo -create -output build/WatchSimulator/$target_lib.a \
    build/WatchSimulator/arm64/install/lib/$target_lib.a \
    build/WatchSimulator/x86_64/install/lib/$target_lib.a
  exit_if_error

  # Merge visionOS simulator arm and x86 binaries
  mkdir -p build/XRSimulator
  exit_if_error
  lipo -create -output build/XRSimulator/$target_lib.a \
    build/XRSimulator/arm64/install/lib/$target_lib.a \
    build/XRSimulator/x86_64/install/lib/$target_lib.a
  exit_if_error

  # Create the framework with multiple platforms
  xcodebuild -create-xcframework \
    -library build/MacOSX/$target_lib.a                      -headers build/MacOSX/arm64/install/brotli/$target_lib/Headers \
    -library build/iPhoneOS/arm64/install/lib/$target_lib.a  -headers build/iPhoneOS/arm64/install/brotli/$target_lib/Headers \
    -library build/iPhoneSimulator/$target_lib.a             -headers build/iPhoneSimulator/arm64/install/brotli/$target_lib/Headers \
    -library build/AppleTVOS/arm64/install/lib/$target_lib.a -headers build/AppleTVOS/arm64/install/brotli/$target_lib/Headers \
    -library build/AppleTVSimulator/$target_lib.a            -headers build/AppleTVSimulator/arm64/install/brotli/$target_lib/Headers \
    -library build/WatchOS/arm64/install/lib/$target_lib.a   -headers build/WatchOS/arm64/install/brotli/$target_lib/Headers \
    -library build/WatchSimulator/$target_lib.a              -headers build/WatchSimulator/arm64/install/brotli/$target_lib/Headers \
    -library build/XROS/arm64/install/lib/$target_lib.a      -headers build/XROS/arm64/install/brotli/$target_lib/Headers \
    -library build/XRSimulator/$target_lib.a                 -headers build/XRSimulator/arm64/install/brotli/$target_lib/Headers \
    -output build/$target_lib.xcframework
  exit_if_error

  # And sign the framework
  codesign --timestamp -s $identity build/$target_lib.xcframework
  exit_if_error
}
# create_framework libbrotlicommon
# create_framework libbrotlienc
# create_framework libbrotlidec


create_artifactbundle() {
  local target_lib=$1

  # Remove previously created artifact if exists
  rm -rf build/$target_lib.artifactbundle
  exit_if_error

  # Create the artifact bundle folder
  mkdir -p build/$target_lib.artifactbundle
  exit_if_error

  # info.json
  cp Contents/$target_lib/info.json build/$target_lib.artifactbundle/info.json
  exit_if_error

  # Headers
  cp -r build/Android/aarch64/install/brotli/$target_lib/Headers build/$target_lib.artifactbundle/include
  exit_if_error

  # aarch64-linux-android
  mkdir -p build/$target_lib.artifactbundle/aarch64-linux-android
  exit_if_error
  cp build/Android/aarch64/install/lib/$target_lib.a build/$target_lib.artifactbundle/aarch64-linux-android/$target_lib.a
  exit_if_error

  # arm-linux-androideabi
  mkdir -p build/$target_lib.artifactbundle/arm-linux-androideabi
  exit_if_error
  cp build/Android/arm/install/lib/$target_lib.a build/$target_lib.artifactbundle/arm-linux-androideabi/$target_lib.a
  exit_if_error

  # i686-linux-android
  mkdir -p build/$target_lib.artifactbundle/i686-linux-android
  exit_if_error
  cp build/Android/i686/install/lib/$target_lib.a build/$target_lib.artifactbundle/i686-linux-android/$target_lib.a
  exit_if_error

  # riscv64-linux-android
  mkdir -p build/$target_lib.artifactbundle/riscv64-linux-android
  exit_if_error
  cp build/Android/riscv64/install/lib/$target_lib.a build/$target_lib.artifactbundle/riscv64-linux-android/$target_lib.a
  exit_if_error

  # x86_64-linux-android
  mkdir -p build/$target_lib.artifactbundle/x86_64-linux-android
  exit_if_error
  cp build/Android/x86_64/install/lib/$target_lib.a build/$target_lib.artifactbundle/x86_64-linux-android/$target_lib.a
  exit_if_error
}
create_artifactbundle libbrotlicommon
create_artifactbundle libbrotlienc
create_artifactbundle libbrotlidec





# Done!