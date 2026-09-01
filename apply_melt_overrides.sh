#!/bin/bash
#
# apply_melt_overrides.sh
#
# Menerapkan ulang override khusus melt-MIX ke arch/arm64/configs/vendor/
# ingres_GKI.config, supaya tidak hilang lagi kalau file itu di-sync ulang
# dari source resmi Xiaomi (sudah 2x kejadian sebelumnya).
#
# AMAN dijalankan berkali-kali (idempotent) -- tidak akan bikin baris
# duplikat walau dipanggil berulang pada file yang sudah benar.
#
# Cara pakai manual:
#   ./apply_melt_overrides.sh arch/arm64/configs/vendor/ingres_GKI.config
#
# Otomatis: sudah dipanggil dari workflow (lihat step "Terapkan override
# melt-MIX" di build.yml), tidak perlu dijalankan manual kalau lewat CI.

set -e

CONFIG_FILE="${1:-arch/arm64/configs/vendor/ingres_GKI.config}"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "::error::File tidak ditemukan: $CONFIG_FILE"
    exit 1
fi

echo "Menerapkan override melt-MIX ke: $CONFIG_FILE"
BEFORE_HASH=$(md5sum "$CONFIG_FILE" | cut -d' ' -f1)

# 1. Nonaktifkan ARCH_CAPE/ARCH_DIWALI kalau kedapatan aktif (=y) --
#    sed di sini cuma menyentuh baris yang PERSIS "CONFIG_X=y", jadi kalau
#    sudah dalam bentuk "# ... is not set" tidak akan disentuh lagi.
sed -i 's/^CONFIG_ARCH_CAPE=y$/# CONFIG_ARCH_CAPE is not set/' "$CONFIG_FILE"
sed -i 's/^CONFIG_ARCH_DIWALI=y$/# CONFIG_ARCH_DIWALI is not set/' "$CONFIG_FILE"

# 2. Kalau baris ARCH_CAPE/ARCH_DIWALI ternyata tidak ada SAMA SEKALI
#    (bukan =y, bukan juga "is not set") -- misal source upstream suatu saat
#    menghapusnya total -- tambahkan versi "is not set" supaya tetap eksplisit.
grep -q "CONFIG_ARCH_CAPE" "$CONFIG_FILE" || echo "# CONFIG_ARCH_CAPE is not set" >> "$CONFIG_FILE"
grep -q "CONFIG_ARCH_DIWALI" "$CONFIG_FILE" || echo "# CONFIG_ARCH_DIWALI is not set" >> "$CONFIG_FILE"

# 3. Tambahkan CONFIG_MI_CHARGER_M81=y kalau belum ada -- cek dulu supaya
#    tidak dobel kalau script ini dijalankan dua kali pada file yang sama.
if ! grep -qx "CONFIG_MI_CHARGER_M81=y" "$CONFIG_FILE"; then
    echo "CONFIG_MI_CHARGER_M81=y" >> "$CONFIG_FILE"
    echo "  + CONFIG_MI_CHARGER_M81=y ditambahkan"
else
    echo "  = CONFIG_MI_CHARGER_M81 sudah ada, dilewati"
fi

AFTER_HASH=$(md5sum "$CONFIG_FILE" | cut -d' ' -f1)

echo ""
echo "--- Status akhir 3 baris kunci ---"
grep -n "CONFIG_MI_CHARGER_M81\|CONFIG_ARCH_CAPE\|CONFIG_ARCH_DIWALI" "$CONFIG_FILE"

if [ "$BEFORE_HASH" = "$AFTER_HASH" ]; then
    echo ""
    echo "Tidak ada perubahan -- file sudah benar sebelum script ini jalan."
else
    echo ""
    echo "File diperbarui."
fi
