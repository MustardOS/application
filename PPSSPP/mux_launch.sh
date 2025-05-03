#!/bin/sh
# HELP: PPSSPP
# ICON: ppsspp
# GRID: PPSSPP

. /opt/muos/script/var/func.sh

echo app >/tmp/act_go


case "$(GET_VAR "device" "board/name")" in
    rg*) PPSSPP_DIR="$(GET_VAR "device" "storage/rom/mount")/MUOS/emulator/ppsspp/rg" ;;
    tui*) PPSSPP_DIR="$(GET_VAR "device" "storage/rom/mount")/MUOS/emulator/ppsspp/tui" ;;
esac

export HOME="$PPSSPP_DIR"
export XDG_CONFIG_HOME="$HOME/.config"

case "$(GET_VAR "device" "board/name")" in
    rg*)
        if [ "$(GET_VAR "global" "boot/device_mode")" -eq 1 ]; then
            SDL_HQ_SCALER=2
            SDL_ROTATION=0
            SDL_BLITTER_DISABLED=1
        else
            SDL_HQ_SCALER="$(GET_VAR "device" "sdl/scaler")"
            SDL_ROTATION="$(GET_VAR "device" "sdl/rotation")"
            SDL_BLITTER_DISABLED="$(GET_VAR "device" "sdl/blitter_disabled")"
        fi
        export SDL_HQ_SCALER SDL_ROTATION SDL_BLITTER_DISABLED

        sed -i '/^GraphicsBackend\|^FailedGraphicsBackends\|^DisabledGraphicsBackends/d' "$PPSSPP_DIR/.config/ppsspp/PSP/SYSTEM/ppsspp.ini"
        ;;
    tui*)
        export PVR_DEBUG="enable_memory_model,disable_texture_merging,force_16bpp"
        export __PVR_SYNC_DEBUG=2
        echo 1 >/sys/module/pvrsrvkm/parameters/DisableClockGating
        echo 1 >/sys/module/pvrsrvkm/parameters/EnableFWContextSwitch
        echo 1 >/sys/module/pvrsrvkm/parameters/EnableSoftResetContextSwitch
        echo 0 >/sys/module/pvrsrvkm/parameters/PVRDebugLevel
        export LD_LIBRARY_PATH="$PPSSPP_DIR/lib:$LD_LIBRARY_PATH"
        rm -rf "$PPSSPP_DIR/.config/ppsspp/PSP/SYSTEM/CACHE/"*
		for CPU in 0 1 2 3; do
		echo 1 > "/sys/devices/system/cpu/cpu$CPU/online"
		done
		echo ondemand > /sys/devices/system/cpu/cpufreq/policy0/scaling_governor
		echo 1000000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_min_freq
		echo 2000000 > /sys/devices/system/cpu/cpufreq/policy0/scaling_max_freq 
        ;;
esac

cd "$PPSSPP_DIR" || exit

SET_VAR "system" "foreground_process" "PPSSPP"

SDL_ASSERT=always_ignore SDL_GAMECONTROLLERCONFIG=$(grep "muOS-Keys" "/opt/muos/device/current/control/gamecontrollerdb_retro.txt") ./PPSSPP

unset SDL_HQ_SCALER SDL_ROTATION SDL_BLITTER_DISABLED