#!/bin/sh

DIR=$(dirname $0)

if [ -n "$LAZ_VER" ]; then
    # Lazarus build (with wine)

    $DIR/lazarus/.travis.install.py

elif [ "$TRAVIS_OS_NAME" = "osx" ]; then
    # OSX build

    # already present on travis
    #brew cask install xquartz

    brew install sdl2 sdl2_gfx sdl2_image sdl2_mixer sdl2_net sdl2_ttf \
        fpc portaudio binutils freetype libpng lua libtiff opencv \
        portmidi

    # This is from: https://github.com/Homebrew/homebrew-core
    brew install ffmpeg@4

elif [ "$VARIANT" = flatpak ]; then
    # Linux build

    sudo tee /etc/apt/preferences.d/flatpak <<EOF
Package: ostree
Pin: version 2018*
Pin-Priority: -1

Package: flatpak
Pin: version 1.0.*
Pin-Priority: -1

Package: flatpak
Pin: version 1.1.*
Pin-Priority: -1

Package: flatpak-builder
Pin: version 0.*
Pin-Priority: -1
EOF
    sudo apt-get install elfutils
    if ! sudo apt-get install flatpak flatpak-builder ; then
        sudo apt-get install fakeroot
        for i in ostree flatpak flatpak-builder ; do
            date +"%c building $i"
            mkdir build
            if ! (
                set -e
                cd  build
                sudo apt-get build-dep $i
                apt-get source --compile $i
                rm -f *-dbgsym_*.deb *-doc_*.deb *-tests*.deb
                sudo dpkg -i *.deb
            ) > build.log 2>&1 then
                tail -n 10000 build.log
                exit 1
            fi
            rm -fR build
            date +"%c done building $i"
        done
    fi
    case "$TRAVIS_CPU_ARCH" in
    amd64)
        if [ "$BUILD_32BIT" = yes ] ; then
            FLATPAK_ARCH=i386
            # 18.08 was the last runtime to officially support x86-32
            sed -i "/runtime-version:/s/:.*/: '18.08'/" $DIR/../../dists/flatpak/eu.usdx.UltraStarDeluxe.yaml
        else
            FLATPAK_ARCH=x86_64
        fi
        ;;
    arm64)
        if [ "$BUILD_32BIT" = yes ] ; then
            FLATPAK_ARCH=arm
        else
            FLATPAK_ARCH=aarch64
        fi
        ;;
    *) FLATPAK_ARCH=$TRAVIS_CPU_ARCH
    esac
    case "$TRAVIS_CPU_ARCH" in
    ppc64le)
        FLATPAK_REMOTE=freedesktop-sdk
        FLATPAK_REMOTE_URL=https://cache.sdk.freedesktop.org/freedesktop-sdk.flatpakrepo
        ;;
    *)
        FLATPAK_REMOTE=flathub
        FLATPAK_REMOTE_URL=https://flathub.org/repo/flathub.flatpakrepo
        ;;
    esac
    flatpak remote-add --user --if-not-exists $FLATPAK_REMOTE $FLATPAK_REMOTE_URL
    RUNTIME_VERSION=`sed -n "/runtime-version:/s/.*'\([^']*\)'/\1/p" $DIR/../../dists/flatpak/eu.usdx.UltraStarDeluxe.yaml`
    flatpak install --user --arch=$FLATPAK_ARCH --noninteractive -y $FLATPAK_REMOTE org.freedesktop.Platform//$RUNTIME_VERSION org.freedesktop.Sdk//$RUNTIME_VERSION

else
    # Linux build

    #sudo apt-get install fpc \
    #    libsdl2-dev libsdl2-image-dev libsdl2-mixer-dev libsdl2-net-dev \
    #    libsdl2-ttf-dev libsdl2-gfx-dev \
    #    libavcodec-dev libavformat-dev libswscale-dev \
    #    portaudio19-dev libprojectm-dev libopencv-highgui-dev \
    #    libsqlite3-dev liblua5.1-dev libpng-dev \
    #    ttf-dejavu ttf-freefont
        
    # Extra dependencies for ffmpeg from ppa
    # sudo apt-get install \
    #    libavcodec-ffmpeg-dev libavformat-ffmpeg-dev libswscale-ffmpeg-dev \
    #    libavutil-ffmpeg-dev libswresample-ffmpeg-dev

    sudo apt-get install \
        fpc liblua5.1-dev libopencv-highgui-dev \
        cmake ftgl-dev libglew-dev \
        build-essential autoconf automake \
        libtool libasound2-dev libx11-dev libxext-dev \
        libxrandr-dev libxcursor-dev libxi-dev libxinerama-dev libxxf86vm-dev \
        libxss-dev libgl1-mesa-dev libdbus-1-dev libudev-dev \
        libgles1-mesa-dev libgles2-mesa-dev libegl1-mesa-dev \
        libsamplerate0-dev libxkbcommon-dev \
        curl realpath

fi
