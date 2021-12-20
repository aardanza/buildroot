#!/bin/sh

BOARD_DIR="$(dirname $0)"
GENIMAGE_CFG="${BOARD_DIR}/genimage.cfg"
GENIMAGE_TMP="${BUILD_DIR}/genimage.tmp"

# set -x

rm -rf "${GENIMAGE_TMP}"

cp "${BOARD_DIR}/meson-sm1-x96-max-plus-100m.dtb" "${BINARIES_DIR}"

# generate image

genimage                               \
	--rootpath "${TARGET_DIR}"     \
	--tmppath "${GENIMAGE_TMP}"    \
	--inputpath "${BINARIES_DIR}"  \
	--outputpath "${BINARIES_DIR}" \
	--config "${GENIMAGE_CFG}"


# merge bootloaders

AML_TOOLS_DIR=utils/amlogic
AML_BIN_DIR=${AML_TOOLS_DIR}/u-boot

OUTPUT_BIN_DIR=${BINARIES_DIR}/tmp
EMMC_BIN_DIR=${BINARIES_DIR}/emmc

mkdir ${OUTPUT_BIN_DIR}
rm ${OUTPUT_BIN_DIR}/*

set -e

MAINLINE_UBOOT="${BOARD_DIR}/uboot/x96maxplus-u-boot.bin.sd.bin"


##########################################
# 	Mainline U-Boot (build by Buildroot)
##########################################
	echo "========================================================================"
	echo "INFO: U-Boot used: <mainline> (build by Buildroot)"
	echo "========================================================================"

	cp ${AML_BIN_DIR}/gxl/bl2.bin   ${OUTPUT_BIN_DIR}/;
	cp ${AML_BIN_DIR}/gxl/acs.bin   ${OUTPUT_BIN_DIR}/;
	cp ${AML_BIN_DIR}/gxl/bl21.bin  ${OUTPUT_BIN_DIR}/;
	cp ${AML_BIN_DIR}/gxl/bl30.bin  ${OUTPUT_BIN_DIR}/;
	cp ${AML_BIN_DIR}/gxl/bl301.bin ${OUTPUT_BIN_DIR}/;
	cp ${AML_BIN_DIR}/gxl/bl31.img  ${OUTPUT_BIN_DIR}/;
	cp ${BINARIES_DIR}/u-boot.bin   ${OUTPUT_BIN_DIR}/bl33.bin

	${AML_BIN_DIR}/blx_fix.sh						\
				${OUTPUT_BIN_DIR}/bl30.bin 			\
				${OUTPUT_BIN_DIR}/zero_tmp 			\
				${OUTPUT_BIN_DIR}/bl30_zero.bin 		\
				${OUTPUT_BIN_DIR}/bl301.bin 			\
				${OUTPUT_BIN_DIR}/bl301_zero.bin 		\
				${OUTPUT_BIN_DIR}/bl30_new.bin			\
				bl30

	python ${AML_BIN_DIR}/acs_tool.pyc 					\
				${OUTPUT_BIN_DIR}/bl2.bin 				\
				${OUTPUT_BIN_DIR}/bl2_acs.bin 			\
				${OUTPUT_BIN_DIR}/acs.bin 				\
				0

	${AML_BIN_DIR}/blx_fix.sh 						\
				${OUTPUT_BIN_DIR}/bl2_acs.bin 			\
				${OUTPUT_BIN_DIR}/zero_tmp 			\
				${OUTPUT_BIN_DIR}/bl2_zero.bin 			\
				${OUTPUT_BIN_DIR}/bl21.bin 			\
				${OUTPUT_BIN_DIR}/bl21_zero.bin 		\
				${OUTPUT_BIN_DIR}/bl2_new.bin 			\
				bl2

	# encrypt bootloader

	${AML_BIN_DIR}/gxl/aml_encrypt_gxl					\
				--bl3enc					\
				--input ${OUTPUT_BIN_DIR}/bl30_new.bin

	${AML_BIN_DIR}/gxl/aml_encrypt_gxl					\
				--bl3enc 					\
				--input ${OUTPUT_BIN_DIR}/bl31.img

	${AML_BIN_DIR}/gxl/aml_encrypt_gxl					\
				--bl3enc 					\
				--input ${OUTPUT_BIN_DIR}/bl33.bin

	${AML_BIN_DIR}/gxl/aml_encrypt_gxl					\
				--bl2sig 					\
				--input ${OUTPUT_BIN_DIR}/bl2_new.bin 		\
				--output ${OUTPUT_BIN_DIR}/bl2.n.bin.sig

	${AML_BIN_DIR}/gxl/aml_encrypt_gxl					\
				--bootmk 					\
				--output ${OUTPUT_BIN_DIR}/u-boot.bin 		\
				--bl2    ${OUTPUT_BIN_DIR}/bl2.n.bin.sig 	\
				--bl30   ${OUTPUT_BIN_DIR}/bl30_new.bin.enc 	\
				--bl31   ${OUTPUT_BIN_DIR}/bl31.img.enc		\
				--bl33   ${OUTPUT_BIN_DIR}/bl33.bin.enc

	cp ${OUTPUT_BIN_DIR}/u-boot.bin.* ${BINARIES_DIR}/


	# Generating SDCARD.IMG

	echo "Adding bootloader to SD card image..."

#	dd if=${MAINLINE_UBOOT} of="${BINARIES_DIR}/sdcard.img" bs=1 count=444 conv=fsync 2>/dev/null status=progress
#	dd if=${MAINLINE_UBOOT} of="${BINARIES_DIR}/sdcard.img" bs=512 skip=1 seek=1 conv=fsync 2>/dev/null status=progress

	echo "========================================================================"
	echo "	Done. Please run $ ./utils/flash-sdcard to flash image "
	echo "========================================================================"
