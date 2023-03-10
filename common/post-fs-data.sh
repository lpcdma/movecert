#!/system/bin/sh
# Do NOT assume where your module will be located.
# ALWAYS use $MODDIR if you need to know where this script
# and module is placed.
# This will make sure your module will still work
# if Magisk change its mount point in the future
MODDIR=${0%/*}

# This script will be executed in post-fs-data mode

# If you for some reason do not want all your certificates moved from the user store to the system store, you can specify which certificates to move by replacing the * with the name of the certificate; i.e.,

# mv -f /data/misc/user/0/cacerts-added/12abc345.0 $MODDIR/system/etc/security/cacerts

su -c "resetprop ro.debuggable 1"
su -c "resetprop ro.boot.verifiedbootstate orange" # 修改解锁状态
su -c "resetprop service.adb.root 1" # 减少调用 adb root
su -c "magiskpolicy --live 'allow adbd adbd process setcurrent'" # 配置缺少的权限
su -c "magiskpolicy --live 'allow adbd su process dyntransition'" # 配置缺少的权限
su -c "magiskpolicy --live 'permissive { su }'" # 将 su 配置为 permissive，防止后续命令执行缺少权限
su -c "pkill -9 adbd" # 杀掉 adbd

cp -f /data/misc/user/0/cacerts-added/* $MODDIR/system/etc/security/cacerts
chown -R 0:0 $MODDIR/system/etc/security/cacerts

[ "$(getenforce)" = "Enforcing" ] || exit 0

default_selinux_context=u:object_r:system_file:s0
selinux_context=$(ls -Zd /system/etc/security/cacerts | awk '{print $1}')

if [ -n "$selinux_context" ] && [ "$selinux_context" != "?" ]; then
    chcon -R $selinux_context $MODDIR/system/etc/security/cacerts
else
    chcon -R $default_selinux_context $MODDIR/system/etc/security/cacerts
fi
