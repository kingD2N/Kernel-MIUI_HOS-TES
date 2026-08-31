#!/bin/bash
#
# Copyright (C) 2016 The CyanogenMod Project
# Copyright (C) 2017-2024 The LineageOS Project
#
# SPDX-License-Identifier: Apache-2.0
#
# extract-files.sh untuk device/xiaomi/ingres (ROM AOSP custom)
#
# Menarik blob proprietary yang terdaftar di proprietary-files.txt (2.851
# entri, hasil audit dump firmware asli missi_phone_cn-user-13-...-
# V14.0.23.8.14.DEV) ke dalam vendor/xiaomi/ingres/proprietary/.
#
# CATATAN PENTING: .ko (kernel module) SENGAJA TIDAK ada di proprietary-files.txt
# -- itu dibuild dari source bareng kernel kita sendiri (lihat device.mk),
# BUKAN diekstrak sebagai blob. Kalau suatu saat proprietary-files.txt di-
# regenerate dan ada .ko ikut masuk, itu bug, bukan fitur -- hapus lagi.
#

set -e

DEVICE=ingres
VENDOR=xiaomi

# Load extract_utils dan pengecekan dasar
MY_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "${MY_DIR}" ]]; then MY_DIR="${PWD}"; fi

ANDROID_ROOT="${MY_DIR}/../../.."

HELPER="${ANDROID_ROOT}/tools/extract-utils/extract_utils.sh"
if [ ! -f "${HELPER}" ]; then
    echo "Tidak menemukan helper script di ${HELPER}"
    echo "Pastikan sudah repo sync manifest LineageOS/AxionOS lengkap dulu --"
    echo "extract_utils.sh ini BUKAN sesuatu yang dibuat manual per-device,"
    echo "itu utility bersama dari source tree ROM-nya."
    exit 1
fi
source "${HELPER}"

# Default: bersihkan folder vendor sebelum ekstraksi ulang
CLEAN_VENDOR=true

ONLY_COMMON=
ONLY_TARGET=
KANG=
SECTION=

while [ "${#}" -gt 0 ]; do
    case "${1}" in
        --only-common)
            ONLY_COMMON=true
            ;;
        --only-target)
            ONLY_TARGET=true
            ;;
        -n | --no-cleanup)
            CLEAN_VENDOR=false
            ;;
        -k | --kang)
            KANG="--kang"
            ;;
        -s | --section)
            SECTION="${2}"
            shift
            CLEAN_VENDOR=false
            ;;
        *)
            SRC="${1}"
            ;;
    esac
    shift
done

if [ -z "${SRC}" ]; then
    SRC="adb"
fi

function blob_fixup() {
    case "${1}" in
        # TODO: belum ada patch yang terverifikasi di sini -- saya tidak
        # punya bukti konkret binary mana yang butuh blob_fixup tanpa
        # benar-benar coba build dan lihat error linking/dependency-nya.
        # Ini BEDA dengan device.mk/BoardConfig.mk yang sebagian besar
        # sudah bisa disusun dari fakta yang sudah kita verifikasi --
        # blob_fixup baru ketahuan kebutuhannya lewat percobaan build
        # nyata. Jangan tergoda mengarang entri di sini.
        *)
            return 1
            ;;
    esac
}

function blob_fixup_dry() {
    blob_fixup "$1" "$2" 1
}

# Bagian "common" -- kosongkan kalau ingres tidak berbagi tree dgn device lain.
# TODO: konfirmasi apakah proyek Anda mau pisah device/vendor tree per-device
# (ingres sendirian) atau pakai skema common spt cupid-development/sm8450-common.
# Kalau sendirian, --section common ini tidak perlu dipakai sama sekali dan
# skip block ini bisa dihapus.
if [ -s "${MY_DIR}/proprietary-files-common.txt" ] && [ -z "${ONLY_TARGET}" ]; then
    extract "${MY_DIR}/proprietary-files-common.txt" "${SRC}" \
        --section "${SECTION}" ${KANG} --add-common
fi

# Bagian device-specific (ingres) -- ini yang sudah kita generate.
if [ -z "${ONLY_COMMON}" ]; then
    extract "${MY_DIR}/proprietary-files.txt" "${SRC}" \
        --section "${SECTION}" ${KANG}
fi

cd "${MY_DIR}" || exit 1

"${MY_DIR}/setup-makefiles.sh"
