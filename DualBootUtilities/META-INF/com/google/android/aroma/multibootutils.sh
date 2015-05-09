#!/sbin/sh

# Common mounting functions
BOOT="/dev/block/platform/msm_sdcc.1/by-name/boot"
SYSTEM="/dev/block/platform/msm_sdcc.1/by-name/system"
CACHE="/dev/block/platform/msm_sdcc.1/by-name/cache"
DATA="/dev/block/platform/msm_sdcc.1/by-name/userdata"

unmount_system() {
    umount /system >/dev/null 2>&1 || :
}

mount_system() {
    unmount_system
    mount "${SYSTEM}" /system
}

unmount_cache() {
    umount /cache >/dev/null 2>&1 || :
}

mount_cache() {
    unmount_cache
    mount "${CACHE}" /cache
}

unmount_data() {
    umount /data >/dev/null 2>&1 || :
}

mount_data() {
    unmount_data
    mount "${DATA}" /data
}

write_kernel() {
    local path="${1}"
    dd if="${path}" of="${BOOT}" || {
        echo "Failed to write kernel" && return 1
    }
}

read_kernel() {
    local path="${1}"
    dd if="${BOOT}" of="${path}" || {
        echo "Failed to write kernel" && return 1
    }
}

migrate_roms() {
    mount_data
    mount_cache
    mount_system

    local reinstall

    echo "Migrating ROMs data ..."

    mkdir -p /data/multiboot

    if [ -d /system/dual ]; then
        if [ -d /data/multiboot/dual ]; then
            echo "Skipping dual: /data/multiboot/dual already exists"
        else
            mv /data/dual /data/multiboot/dual
            rm -rf /system/dual
            rm -rf /cache/dual
            reinstall="${reinstall} dual"
        fi
    fi

    for i in multi-slot-1 multi-slot-2 multi-slot-3; do
        if [ -d "/cache/${i}" ]; then
            if [ -d "/data/multiboot/${i}" ]; then
                echo "Skipping multi-slot-1: /data/multiboot/${i} already exists"
            else
                mv "/data/${i}" "/data/multiboot/${i}"
                rm -rf "/system/${i}"
                rm -rf "/cache/${i}"
                reinstall="${reinstall} ${i}"
            fi
        fi
    done

    unmount_data
    unmount_cache
    unmount_system

    echo

    if [ -z "${reinstall}" ]; then
        echo "Nothing to migrate"
    else
        echo "Finished migration"
        echo "NOTE: Multibooted ROMs must be reinstalled now."
    fi
}

switch_to() {
    mount_data
    mount_system
    local ret
    local kernel
    local rom="${1}"

    kernel="/data/media/0/MultiBoot/${rom}/boot.img"
    if [ ! -f "${kernel}" ]; then
        echo "There's no kernel for the ${rom} ROM. Did you remember to set the kernel in the Dual Boot Switcher app? You will need to flash a kernel for the ${rom} ROM in order to boot it again."
        ret=1
    elif ! write_kernel "${kernel}"; then
        echo "Failed to write kernel to boot partition."
        ret=1
    else
        echo "Successfully switched to the ${rom} ROM."
        ret=0
    fi

    unmount_data
    unmount_system
    exit "${ret}"
}

wipe_system() {
    mount_system
    mount_cache
    mount_data
    local rom="${1}"

    case "${rom}" in
    primary)
        for i in /system/*; do
            case "${i}" in
            /system/dual)
                echo "Skipping ${i}"
                continue
                ;;
            /system/multiboot)
                echo "Skipping ${i}"
                continue
                ;;
            /system/multi-slot-*)
                echo "Skipping ${i}"
                continue
                ;;
            *)
                echo "Deleting ${i}"
                rm -rf "${i}"
                ;;
            esac
        done

        echo "Deleting primary kernel"
        rm -f /data/media/0/MultiBoot/primary/boot.img
        ;;

    secondary)
        echo "Deleting /system/multiboot/dual/"
        rm -rf /system/multiboot/dual
        echo "Deleting secondary kernel"
        rm -f /data/media/0/MultiBoot/dual/boot.img
        ;;

    multi-slot-*)
        echo "Deleting /cache/multiboot/${rom}/"
        rm -rf "/cache/multiboot/${rom}"
        echo "Deleting ${rom} kernel"
        rm -f "/data/media/0/MultiBoot/${rom}/boot.img"
    esac

    unmount_system
    unmount_cache
    unmount_data
}

wipe_cache() {
    mount_system
    mount_cache
    local rom="${1}"

    case "${rom}" in
    primary)
        for i in /cache/*; do
            case "${i}" in
            /cache/dual)
                echo "Skipping ${i}"
                continue
                ;;
            /cache/multiboot)
                echo "Skipping ${i}"
                continue
                ;;
            /cache/multi-slot-*)
                echo "Skipping ${i}"
                continue
                ;;
            *)
                echo "Deleting ${i}"
                rm -rf "${i}"
                ;;
            esac
        done
        ;;

    secondary)
        echo "Deleting /cache/multiboot/dual"
        rm -rf /cache/multiboot/dual
        ;;

    multi-slot-*)
        echo "Deleting /system/multiboot/${rom}"
        rm -rf "/system/multiboot/${rom}"
        ;;
    esac

    unmount_system
    unmount_cache
}

wipe_data() {
    mount_data
    local rom="${1}"

    case "${rom}" in
    primary)
        for i in /data/*; do
            case "${i}" in
            /data/media)
                echo "Skipping ${i}"
                continue
                ;;
            /data/dual)
                echo "Skipping ${i}"
                continue
                ;;
            /data/multiboot)
                echo "Skipping ${i}"
                continue
                ;;
            /data/multi-slot-*)
                echo "Skipping ${i}"
                continue
                ;;
            *)
                echo "Deleting ${i}"
                rm -rf "${i}"
                ;;
            esac
        done
        ;;

    secondary)
        echo "Deleting /data/multiboot/dual"
        rm -rf /data/multiboot/dual
        ;;

    multi-slot-*)
        echo "Deleting /data/multiboot/${rom}"
        rm -rf "/data/multiboot/${rom}"
        ;;
    esac

    unmount_data
}

wipe_dalvik_cache() {
    mount_data
    local rom="${1}"

    case "${rom}" in
    primary)
        echo "Deleting /data/dalvik-cache"
        rm -rf /data/dalvik-cache
        echo "Deleting /cache/dalvik-cache"
        rm -rf /cache/dalvik-cache
        ;;

    secondary)
        echo "Deleting /data/multiboot/dual/data/dalvik-cache"
        rm -rf /data/multiboot/dual/data/dalvik-cache
        echo "Deleting /cache/multiboot/dual/cache/dalvik-cache"
        rm -rf /cache/multiboot/dual/cache/dalvik-cache
        ;;

    multi-slot-*)
        echo "Deleting /data/multiboot/${rom}/data/dalvik-cache"
        rm -rf "/data/multiboot/${rom}/data/dalvik-cache"
        echo "Deleting /system/multiboot/${rom}/cache/dalvik-cache"
        rm -rf "/system/multiboot/${rom}/cache/dalvik-cache"
        ;;
    esac

    unmount_data
}

save_last_kmsg() {
    echo "Copying /proc/last_kmsg to internal SD"
    cp /proc/last_kmsg /sdcard/ || exit 1
}

save_recovery_log() {
    echo "Copying /tmp/recovery.log to internal SD"
    cp /tmp/recovery.log /sdcard/ || exit 1
}

case "${1}" in
switch-to-*)
    switch_to "${1#switch-to-}"
    ;;
wipe-system-*)
    wipe_system "${1#wipe-system-}"
    ;;
wipe-cache-*)
    wipe_cache "${1#wipe-cache-}"
    ;;
wipe-data-*)
    wipe_data "${1#wipe-data-}"
    ;;
wipe-dalvik-cache-*)
    wipe_dalvik_cache "${1#wipe-dalvik-cache-}"
    ;;
wipe-caches-*)
    wipe_cache "${1#wipe-caches-}"
    wipe_dalvik_cache "${1#wipe-caches-}"
    ;;
wipe-all-*)
    wipe_system "${1#wipe-all-}"
    wipe_cache "${1#wipe-all-}"
    wipe_data "${1#wipe-all-}"
    wipe_dalvik_cache "${1#wipe-all-}"
    ;;
migrate-roms)
    migrate_roms
    ;;
save-last-kmsg)
    save_last_kmsg
    ;;
save-recovery-log)
    save_recovery_log
    ;;
esac
