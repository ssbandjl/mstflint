#!/bin/bash
#
#
### BEGIN INIT INFO
# Provides:            mst
# Required-Start:        $local_fs
# Should-Start:
# Required-Stop:
# Should-Stop:
# Default-Start:         2 3 4 5
# Default-Stop:             0 1 6
# Short-Description:        mst
# Description:            Starts and stops mst service from Mellanox tools package
### END INIT INFO

#insmod_flags="-f"
prefix="/usr/mst"
modprobe=/sbin/modprobe
lspci=lspci

if [ `id -u` -ne 0 ]; then
    echo "-E- You must be root to use mst tool"
    exit 1
fi

if [[ `uname -a` == *MELLANOX* ]]; then
    IS_MLNXOS=1
fi

# Source function library.
action() {
    STRING=$1
    echo -n "$STRING"
    shift
    $*
    rc=$?
    if test $rc -ne 0
    then
        echo " - Failure: $rc"
        RETVAL=1
    else
        echo " - Success"
    fi
    return $rc
}
echo_success() {
    echo " - Success"
}
echo_failure() {
    echo " - Failure: $?"
}
failure() {
    echo -n "$* - Failure"
}


RETVAL=0

WITH_MSIX="with_msix"
WITH_UNKNOWN_ID="with_unknown"
WITH_I2CM="with_i2cm"
WITH_DEVI2C="with_i2cdev"
WITH_DEVLPC="with_lpcdev"
WITH_CABLES="with_cables"
FORCE_STOP="force"
ConnectX3_HW_ID="01F5"
ConnectX3_PRO_HW_ID="01F7"
SwitchIB_HW_ID="0247"
SwitchIB2_HW_ID="024b"
Spectrum_HW_ID="0249"
ConnectIB_HW_ID="01FF"
ConnectX4_HW_ID="0209"
ConnectX4LX_HW_ID="020B"
ConnectX5_HW_ID="020D"
ConnectX6_HW_ID="020F"
ConnectX6DX_HW_ID="0212"
ConnectX6LX_HW_ID="0216"
ConnectX7_HW_ID="0218"
ConnectX8_HW_ID="021e"
BlueField_HW_ID="0211"
BlueField2_HW_ID="0214"
BlueField3_HW_ID="021C"
BlueField4_HW_ID="0220"
Quantum_HW_ID="024D"
Quantum2_HW_ID="0257"
Specturm_2_HW_ID="024E"
Specturm_3_HW_ID="0250"
Specturm_4_HW_ID="0254"
Schrodinger_HW_ID="020F"
Freysa_P1011="0218"
NVL3_WOLF_ID="E3597"
NVL4_KONG_ID="P4697"
GB100_HW_ID="2900"
Quantum3_HW_ID="025B"


pcie_switch_device_id=(\
["0x1976"]="$Schrodinger_HW_ID" # ConnectX6dx.
["0x1979"]="$Freysa_P1011" # ConnectX-7 PCIe Bridge.
)

pci_dev_to_hw_dev_id=(\
["0x1003"]="$ConnectX3_HW_ID"
["0x1007"]="$ConnectX3_PRO_HW_ID"
["0xcb20"]="$SwitchIB_HW_ID"
["0xcf08"]="$SwitchIB2_HW_ID"
["0xcb84"]="$Spectrum_HW_ID"
["0x1011"]="$ConnectIB_HW_ID"
["0x1013"]="$ConnectX4_HW_ID"
["0x1fb3"]="$ConnectX4_HW_ID"       # - Special internal device for debug FW.
["0x1015"]="$ConnectX4LX_HW_ID"
["0x1fb5"]="$ConnectX4LX_HW_ID"     # - Special internal device for debug FW.
["0x1017"]="$ConnectX5_HW_ID"
["0x1019"]="$ConnectX5_HW_ID"
["0x101b"]="$ConnectX6_HW_ID"
["0x101d"]="$ConnectX6DX_HW_ID"
["0x101f"]="$ConnectX6LX_HW_ID"
["0x1021"]="$ConnectX7_HW_ID"
["0x1023"]="$ConnectX8_HW_ID"
["0xa2d2"]="$BlueField_HW_ID"
["0xa2d6"]="$BlueField2_HW_ID"
["0xa2dc"]="$BlueField3_HW_ID"
["0xa2de"]="$BlueField4_HW_ID"
["0xd2f0"]="$Quantum_HW_ID"
["0xd2f2"]="$Quantum2_HW_ID"
["0xcf6c"]="$Specturm_2_HW_ID"
["0xcf70"]="$Specturm_3_HW_ID"
["0xcf80"]="$Specturm_4_HW_ID"
["0x1976"]="$Schrodinger_HW_ID"
["0x2900"]="$GB100_HW_ID"
["0xd2f4"]="$Quantum3_HW_ID"
)

MST_START_FLAGS="[--$WITH_MSIX] [--$WITH_UNKNOWN_ID] [--$WITH_DEVI2C] [--$WITH_DEVLPC]" #[--$WITH_CABLES]" # [--$WITH_I2CM]  was removed to hide the feature
MST_START_HIDDEN_FLAGS="[--$WITH_I2CM]"
PMTUSB_NAME="Pmtusb"

# Mellanox dev directory
mdir="/dev/mst"        # Directory where MST devices created
mbindir=/usr/bin # Binary directory where MST-utils and modules are located



#@POST_MST_BIN_DIR@  # Update the bin dir by the post install script.

mlibdir=/usr/lib64 # Libraries directory where MST libs and modules are located
#@POST_MST_LIB_DIR@  # Update the lib dir by the post install script.
BASH_VERSION_LIB_PATH=${mlibdir}/mft/bash_libs/tools_version.sh

UNKNOWN_ID="UNKNWON_ID"


MFT_EXT_PYTHON_LIB_DIR=$mlibdir/mft/python_ext_libs
MFT_PYTHON_TOOLS=$mlibdir/mft/python_tools

if test -z "${PYTHONPATH}"; then
   PYTHONPATH=$MFT_PYTHON_TOOLS:$MFT_EXT_PYTHON_LIB_DIR
else
   PYTHONPATH=$MFT_PYTHON_TOOLS:$MFT_EXT_PYTHON_LIB_DIR:${PYTHONPATH}
fi
export PYTHONPATH

PYTHON_EXEC=`find /usr/bin /bin/ /usr/local/bin -iname 'python*' 2>&1 | grep -e='*python[0-9,.]*' | sort -d | head -n 1`
which python3 >/dev/null 2>&1
if test $? -eq 0 ; then
   PYTHON_EXEC='/usr/bin/env python3'
else
    which python2 >/dev/null 2>&1
    if test $? -eq 0 ; then
       PYTHON_EXEC='/usr/bin/env python2'
    fi
fi

MST_CONF=/etc/mft/mst.conf
CONF_DIR=/etc/mft
mlnx_switch_dev_dir="/proc/mlnx-dev"

# Use the var to save the pci slot files
pcidir="/var/mst_pci"

# Default permission
perm="600"

# Vendor / Device IDs
venid="15b3"         # Mellanox vendor ID

devid_pcurom="5a50"  # MT23108 PCIROM device ID


#    DevId              RstAddr   Description
dev_id_database=(\
    "6340               0xf0010   MT25408 [ConnectX VPI - IB SDR / 10GigE]"
    "634a               0xf0010   MT25418 [ConnectX VPI PCIe 2.0 2.5GT/s - IB DDR / 10GigE]"
    "6368               0xf0010   MT25448 [ConnectX EN 10GigE, PCIe 2.0 2.5GT/s]"
    "6372               0xf0010   MT25458 [ConnectX EN 10GigE 10GBaseT, PCIe 2.0 2.5GT/s]"
    "6732               0xf0010   MT26418 [ConnectX VPI PCIe 2.0 5GT/s - IB DDR / 10GigE]"
    "673c               0xf0010   MT26428 [ConnectX VPI PCIe 2.0 5GT/s - IB QDR / 10GigE]"
    "6750               0xf0010   MT26448 [ConnectX EN 10GigE, PCIe 2.0 5GT/s]"
    "675a               0xf0010   MT26458 [ConnectX EN 10GigE 10GBaseT, PCIe Gen2 5GT/s]"
    "676e               0xf0010   MT26478 [ConnectX EN 10GigE, PCIe 2.0 5GT/s]"
    "6746               0xf0010   MT26438 [ConnectX-2 VPI w/ Virtualization+]"
    "6764               0xf0010   MT26468 [Mountain top]"
    "cb20               0xf0010   Switch-IB"
    "1003               0xf0010   MT27500 [ConnectX-3]"
    "1005               0xf0010   MT27510 Family"
    "1007               0xf0010   MT27520 ConnectX-3 Pro Family"
    "1009               0xf0010   MT27530 Family"
    "100b               0xf0010   MT27540 Family"
    "100d               0xf0010   MT27550 Family"
    "100f               0xf0010   MT27560 Family"
    "1011               0xf0010   MT27600 [Connect-IB ]"
    "1013               0xf0010   MT27620 [ConnectX-4]"
    "1015               0xf0010   MT27630 Family [ConnectX-4LX]"
    "1017               0xf0010   MT27800 Family [ConnectX-5]"
    "1019               0xf0010   MT28800 Family [ConnectX-5, Ex]"
    "101b               0xf0010   MT28908 Family [ConnectX-6]"
    "101d               0xf0010   MT2892 Family [ConnectX-6DX]"
    "101f               0xf0010   MT2894 Family [ConnectX-6LX]"
    "1021               0xf0010   MT2910 Family [ConnectX-7]"
    "1023               0xf0010   CX8 Family [ConnectX-8]"
    "cb84               0xf0010   Spectrum"
    "cf08               0xf0010   Switch-IB 2"
    "d2f0               0xf0010   Quantum"
    "d2f2               0xf0010   Quantum 2"
    "cf6c               0xf0010   Spectrum 2"
    "cf70               0xf0010   Spectrum 3"
    "cf80               0xf0010   Spectrum 4"
    "a2d2               0xf0010   MT416842 Family BlueField integrated ConnectX-5 network controller"
    "a2d6               0xf0010   MT42822 Family BlueField2 integrated ConnectX-6 DX network controller"
    "a2dc               0xf0010   MT43244 Family BlueField3 integrated ConnectX-7 network controller"
    "a2de               0xf0010   BF4 Family BlueField4 integrated ConnectX-8 network controller"
    "1976               0xf0010   Schrodinger"
    "2900               0Xf0010   GB-100"
    "d2f4               0Xf0010   Quantum 3"

)

live_fish_id_database=(\
    "0191  0xf0010 MT25408 [ConnectX IB SDR Flash Recovery"
    "0249  0xf0010 Spectrum Flash recovery mode"
    "024b  0xf0010 Switch-IB 2 Flash recovery mode"
    "01F6  0xf0010 MT27500 [ConnectX-3 Flash Recovery]"
    "01F8  0xf0010 MT27500 [ConnectX-3 Pro Flash Recovery]"
    "01FF  0xf0010 MT27600 [Connect-IB Flash Recovery]"
    "0247  0xf0010 Switch-IB Flash recovery mode"
    "0209  0xf0010 MT27700 [ConnectX-4 Flash Recovery]"
    "020b  0xf0010 MT27630 [ConnectX-4LX Flash Recovery]"
    "020d  0xf0010 MT27800 [ConnectX-5 Flash Recovery]"
    "020f  0xf0010 MT28908 [ConnectX-6 Flash Recovery]"
    "0212  0xf0010 MT2892 [ConnectX-6DX Flash Recovery]"
    "0216  0xf0010 MT2894 [ConnectX-6LX Flash Recovery]"
    "0218  0xf0010 MT2910 [ConnectX-7 Flash Recovery]"
    "021e  0xf0010 CX8 [ConnectX-8 Flash Recovery]"
    "024d  0xf0010 Quantum Flash recovery mode"
    "0257  0xf0010 Quantum 2 Flash recovery mode"
    "024e  0xf0010 Specturm 2 Flash recovery mode"
    "0250  0xf0010 Specturm 3 Flash recovery mode"
    "0254  0xf0010 Specturm 4 Flash recovery mode"
    "0211  0xf0010 BlueField SoC Flash recovery mode"
    "0214  0xf0010 BlueField2 SoC Flash recovery mode"
    "021c  0xf0010 BlueField3 SoC Flash recovery mode"
    "0220  0xf0010 BlueField4 SoC Flash recovery mode"
    "2900  0xf0010 GB-100 Flash recovery mode"
    "d2f4  0xf0010 Quantum 3 Flash recovery mode"

)


# Title
prog="MST (Mellanox Software Tools) driver set"



PATH=${PATH}:/sbin:/usr/bin:/bin:${mbindir}

kver=`uname -r`

if [ -r /etc/mst.conf ]; then
. /etc/mst.conf
fi

###
### MAP OPS (Assuming that the MAP is an array
### with values in the format "<KEY>=<VAL>"
### -------
###

#declare -A devnums
#declare -A pf0devids

devnums=()
pf0devids=()

map_set() {

    map=$1
    key=$2
    val=$3
    if [ "$map" == "devnums" ]; then
        map_len=${#devnums[@]}
        for (( i=0; i<${map_len}; i++ )); do
            iKEY=${devnums[i]%%=*}
            if [ "$key" == "$iKEY" ]; then
                devnums[i]="$key=$val"
                return
            fi
        done
        devnums+=("$key=$val")
    elif [ "$map" == "pf0devids" ]; then
        map_len=${#pf0devids[@]}
        for (( i=0; i<${map_len}; i++ )); do
            iKEY=${pf0devids[i]%%=*}
            if [ "$key" == "$iKEY" ]; then
                pf0devids[i]="$key=$val"
                return
            fi
        done
        pf0devids+=("$key=$val")
    fi
}

map_get() {
    map=$1
    key=$2
    if [ "$map" == "devnums" ]; then
        for i in "${devnums[@]}"; do
            iKEY=${i%%=*}
            iVAL=${i#*=}
            if [ "$key" == "$iKEY" ]; then
                echo "$iVAL"
                return
            fi
        done
        printf "NA"
    elif [ "$map" == "pf0devids" ]; then
        for i in "${pf0devids[@]}"; do
            iKEY=${i%%=*}
            iVAL=${i#*=}
            if [ "$key" == "$iKEY" ]; then
                echo "$iVAL"
                return
            fi
        done
        printf "NA"
    fi
}

###
### PCI / PCICONF PCUROM
### --------------------
###

function is_device_bad() {
    dev=$1
    bar_info=`cat $dev | tail -1`
    bar_regexp="domain:bus:dev.fn=[[:xdigit:]]{4}:[[:xdigit:]]{2}:[[:xdigit:]]{2}.[[:xdigit:]]{1} bar=0x[[:xdigit:]]+ size=0x[[:xdigit:]]+"

    if [[ $bar_info =~ $bar_regexp ]]; then
        bar_size=`echo $bar_info | cut -d"=" -f4`
        if [ "$bar_size" == "0x0" ]; then
            return 1
        fi
    fi
    return 0
}

### create group of PCI devices per one instance of InfiniHost (ddr,cr,uar)
### ------------------------------------------------------------------
create_pci_dev()
{
    ## For IA64 - do not create PCI devices
    #if [ "`uname -m`" = "ia64" ]; then
    #    return
    #fi

    local devname=$1
    local busdevfn=$2
    local devnum=$3
    local major=$4
    local minor=$5
#    local c_major=$6
#    local c_minor=$7
    local bar_step=$6
    shift 6
    #Get the fn from the BDF
    fn=$(echo ${busdevfn} | cut -f2 -d.)
    local bar=0
    # PCI group of devices
    #     "_cr", "_uar"  and "_ddr" for InfiniHost
    #     ""     "_i2cm"            for Gamla
    for name
    do
        if [ x$name != xNOBAR ]; then
             new_dev=${mdir}/${devname}pci$name${devnum}
             if [[ "$fn" != "0" ]]; then
                new_dev=${new_dev}.${fn}
             fi
             if [ ! -c ${new_dev} ]; then
                 mknod -m ${perm} ${new_dev} c ${major} ${minor}
                 ${mbindir}/minit ${new_dev} $busdevfn $bar
                 if [ $? -ne 0 ]; then
                     rm ${new_dev}
                 fi
                 is_device_bad $new_dev; rc=$?
                 if [ $rc == "1" ]; then
                    ${mbindir}/mstop "$new_dev"
                    rm ${new_dev}
                  fi
             fi
             minor=$(( $minor + 1 ))
        fi
        bar=$(( $bar + $bar_step ))
    done

    is_bar_access=$(echo $@ | grep "NOBAR")
    if [ -z "$is_bar_access" ]; then
        # open mem access if closed.
        mem_byte=`setpci -s $busdevfn 4.B`
        let "mem_en = 0x$mem_byte & 0xf"
        if [ $mem_en -eq 0 ]; then
            let "mem_byte = 0x$mem_byte | 0x6"
            mem_byte=`printf "%x" $mem_byte`
            setpci -s $busdevfn 4.B=$mem_byte
        fi
    fi

    echo $minor
}

get_pciconf_dev_name()
{
    local devname=$1
    local devnum=$2
    local fn=$3
    local name=$4
    local full_name="${mdir}/${devname}pciconf$name${devnum}"

    if [[ "$fn" != "0" ]]; then
        full_name=${full_name}.${fn}
    fi

    echo ${full_name}
}

### create a PCICONF device per one instance of infinihost
### -------------------------------------------------
create_pciconf_dev()
{
    local devname=$1
    local busdevfn=$2
    local devnum=$3
    local major=$4
    local minor=$5
    local name=$6

    #Get the fn from the BDF
    fn=$(echo ${busdevfn} | cut -f2 -d.)
    # PCICONF
    fullname=`get_pciconf_dev_name $devname $devnum $fn $name`
    if [ ! -c ${fullname} ]; then
        mknod -m ${perm} $fullname c ${major} ${minor}
        ${mbindir}/minit $fullname ${busdevfn} 88 92
        if [ $? -ne 0 ]; then
            rm ${mdir}/${devname}pciconf$name${minor}
        fi
    fi
    minor=$((  $minor + 1 ))
}

get_pci_dev_args()
{
    local with_msix=$1
    local devid=$2
    local conf_dev=$3
    local dev_args=""
    local bar_size=""

    # HCAs  devid
    hw_dev_id=${pci_dev_to_hw_dev_id[0x${devid}]}
    # For the device ConnectX3, create /dev/mst/pci_****cr device
    dev_args="2 _cr"
    # For the devices ConnectX4/LX, don't create /dev/mst/pci_****cr device
    if [ x$hw_dev_id == x$ConnectIB_HW_ID ] ||
        [ x$hw_dev_id == x$ConnectX4_HW_ID ] ||
        [ x$hw_dev_id == x$ConnectX4LX_HW_ID ]; then
        dev_args="2 NOBAR _cr"
    fi
    # For the devices >= ConnectX5: if we find a bar gateway offset != -1 (determined in minit) in the pciconf ($conf_dev), 
    # then return "0 _cr" and create /dev/mst/pci_****cr device
    # otherwise, the BAR0 gateway is unsupported; return "2 NOBAR"
    if [ x$hw_dev_id == x$ConnectX5_HW_ID ] ||
        [ x$hw_dev_id == x$ConnectX6_HW_ID ] ||
        [ x$hw_dev_id == x$ConnectX6DX_HW_ID ] ||
        [ x$hw_dev_id == x$ConnectX6LX_HW_ID ] ||
        [ x$hw_dev_id == x$ConnectX7_HW_ID ] ||
        [ x$hw_dev_id == x$ConnectX8_HW_ID ] ||
        [ x$hw_dev_id == x$BlueField_HW_ID ] ||
        [ x$hw_dev_id == x$BlueField2_HW_ID ] ||
        [ x$hw_dev_id == x$BlueField3_HW_ID ] ||
        [ x$hw_dev_id == x$BlueField4_HW_ID ] ; then
        bar_size=`cat "$conf_dev" | grep "cr_bar.gw_offset=" | grep -v "\-1"`
        if [ "$bar_size" == "" ]; then
            dev_args="2 NOBAR"
        else
            dev_args="0 _cr"
        fi
    fi
    if [ "$with_msix" == "1" ]; then
        dev_args="$dev_args _msix"
        fi

    echo $dev_args
}

get_dev_id()
{
    local oper=$1
    local devidarg=$2
    local devid_lspci_out=$3

    local devid=$devidarg

    if [ "$devidarg" == $UNKNOWN_ID ] ; then
        if [ "$oper" == "before" ]; then
            devid=""
        else
            devid=`echo $devid_lspci_out | cut -f2 -d"\""`
        fi
    fi
    echo $devid
}

get_dev_name()
{
    dev_id=$1
    dev_id_dec=`printf %d 0x$dev_id`
    devname="mt"$dev_id_dec"_"
    echo $devname
}

is_pcie_switch()
{
    local devidarg=$1
    hw_dev_id=${pcie_switch_device_id[0x${devidarg}]}

    for id in ${pcie_switch_device_id[@]}; do
        if [[ $hw_dev_id == $id ]]; then
            mdevices_info -s $busdevfn
            RC=$?
            if [ $RC != 1 ]; then
                return 1
            fi
        fi
    done
    return 0
}

prepare_create_pci_dev()
{
    local devidarg=$1
    local pciminor=$2
    local pciconfminor=$3
    local pcimajor=$4
    local pciconfmajor=$5
    local with_msix=$6

    shift 6

    devid=$(get_dev_id "before" $devidarg)

    new_minors=`(
    echo $pciminor $pciconfminor
    ${lspci} -m -n -d ${venid}:$devid 2> /dev/null | while read str
    do
        set -- $str
        busdevfn=$1

        if [[ "$busdevfn" != *\:*\:*\.* ]]; then
            busdevfn="0000:$busdevfn"
        fi
        # Ignore the device if its a PCIE switch device
        # and vendor specific capability is not supported.
        if [ "$devidarg" != $UNKNOWN_ID ] ; then
            is_pcie_switch $devidarg
            if [ $? -ne 0 ]; then
                continue
            fi
        fi

        devid=$(get_dev_id "after" $devidarg $4)

        devname=$(get_dev_name $devid)

        #Get the fn from the BDF
        fn=$(echo ${busdevfn} | cut -f2 -d.)
        busdev=$(echo $busdevfn | cut -d':' -f1-2 | sed 's/://g')
        if [[ "$fn" == "0" ]]; then
            #pf0devids[$busdev]=$devid
            map_set "pf0devids" ${busdev} ${devid}
        fi
        #pf0devid=${pf0devids[$busdev]}
        pf0devid=$(map_get "pf0devids" $busdev)

        val=$(map_get "devnums" $pf0devid)
        if [ "$val" == "NA" ]; then
            #devnums[$pf0devid]=0
            map_set "devnums" $pf0devid 0
        else
            if [[ "$fn" == "0" ]]; then
                #let devnums[$pf0devid]+=1
                new_val=$(expr $val + 1)
                map_set "devnums" $pf0devid $new_val;
            fi
        fi
        devnum=$(map_get "devnums" $pf0devid)
        #devnum=${devnums[$pf0devid]}
        conf_dev_name=$(get_pciconf_dev_name $devname $devnum $fn)
        create_pciconf_dev $devname $busdevfn $devnum $pciconfmajor $pciconfminor
        pciconfminor=$((  $pciconfminor + 1 ))

        pci_dev_args=$(get_pci_dev_args $with_msix $devid $conf_dev_name)
        next_pciminor=$(create_pci_dev $devname $busdevfn $devnum $pcimajor $pciminor $pci_dev_args)
        pciminor=$next_pciminor

        echo $pciminor $pciconfminor
    done
    )| tail -1`
    echo $new_minors
}


prepare_create_pci_dev_live_fish()
{
    local devidarg=$1
    local pciconfminor=$2
    local pciconfmajor=$3

    devnum=0

    devid=$(get_dev_id "before" $devidarg)

    new_pciconfminor=`(
    echo $pciconfminor
    ${lspci} -m -n -d ${venid}:${devid} 2> /dev/null | sort | while read str
    do
        set -- $str
        busdevfn=$1
        devid=$(get_dev_id "after" $devidarg $4)

        devname=$(get_dev_name $devid)
        create_pciconf_dev $devname $busdevfn $devnum $pciconfmajor $pciconfminor

        devnum=$((  $devnum + 1 ))
        pciconfminor=$((  $pciconfminor + 1 ))
        echo $pciconfminor
    done
    )| tail -1`
    echo $new_pciconfminor
}

find_mtusb_rename()
{
    declare -i i
    i=0

    for s in ${ids[@]}
    do
        if [ "0x$1" == ${s} ]; then
            break
        fi
        i=i+1
    done
    if [[ "${devices_names[$i]}" != "" ]]; then
        mtusb_name=${devices_names[$i]}
    else
        rc=1
        while test $rc -ne 0 ; do
            mtusb_name=${mst_usb_dev}mtusb-1
            mst_usb_dev=X$mst_usb_dev
            check_existence $mtusb_name "n"
            rc=$?
        done
    fi

}

generate_serial_file ()
{
    bus=$1
    dev=$2
    fname="usb_${bus}_${dev}_serial"
    serial_file_name=${CONF_DIR}/${fname}
    if [ ! -f $serial_file_name ]; then
        iserial=$(lsusb -v -s $bus:$dev 2> /dev/null | grep iSerial | awk '{print $3}')
        echo ${iserial} > ${serial_file_name}
    fi
}

create_mtusb_devices()
{

    # Create MTUSB devices
    local dimax_vend=0x0abf
    local dimax_prod=0x3370

    local mst_usb_dev=""

    OLD_IFS=$IFS
    IFS=$'\n';
    warn_msg="-W- Missing \"lsusb\" command, skipping MTUSB devices detection"
    if [ "$IS_MLNXOS" == "1" ]; then
        warn_msg=""
    fi
    command -v lsusb >/dev/null || { echo ${warn_msg}; return; }
    if ! test -f ${mbindir}/dimax_init; then
        echo "-W- Missing \"dimax_init\", skipping MTUSB devices detection"
        return
    fi
    for lsusb_out in `lsusb -d $dimax_vend:$dimax_prod 2> /dev/null`;
    do
        IFS=$OLD_IFS
        found_devs=0
        local bus=$(echo $lsusb_out | cut -f2 -d" ")
        local device=$(echo $lsusb_out | cut -f1 -d":" | cut -f4 -d " ")
        for usb_dir in /dev/bus/usb /proc/bus/usb;
        do
            if ! test -d $usb_dir; then
                continue
            fi
            usb_dev="$usb_dir/$bus/$device"
            if chmod 0666 $usb_dev 2> /dev/null; then
                if ${mbindir}/dimax_init $usb_dev > /dev/null ; then
                    found_devs=1
                    if [[ "${ENABLE_RENAMING}" == "1" ]]; then
                         usb_serial=`get_mtusb_serial $bus $device`
                         find_mtusb_rename $usb_serial
                    else
                        mtusb_name=${mst_usb_dev}mtusb-1
                        mst_usb_dev=X$mst_usb_dev
                    fi
                    action "MTUSB-1 USB to I2C Bridge" ln -fs $usb_dev ${mdir}/${mtusb_name} 2> /dev/null
                    generate_serial_file $bus $device
                else
                    diolan_mod=`lsmod | grep diolan`
                    if [[ "${diolan_mod}" == "" ]]; then
                        echo "Can't initialize MTUSB-1 USB to I2C Bridge"
                    else
                        #echo "Failed to initialize MTUSB-1, try to blocklist the module i2c-diolan-u2c"
                        echo "Failure to initialize MTUSB-1 due to being owned by i2c-diolan-u2c."
                        echo "To use MTUSB-1 device, please remove i2c-diolan-u2c module (Run: modprobe -r i2c-diolan-u2c)"
                        echo "blocklisting the module i2c-diolan-u2c can be done by adding it to /etc/modprobe.d/blocklist."
                    fi
                fi
            fi
            # If devices were found on first dir, don't search the other dir (may be doplicated)
            if [ "$found_devs" == "1" ]; then
                break;
            fi
        done

    done
    return
}

check_lspci_existance()
{
    check_lspci=`${lspci} --version 2> /dev/null`
    if [ $? -ne 0 ]; then
        echo "-E- Could not find lspci, you may need to install \"pciutils\" package."
        return 1
    fi
}

create_pci_devices()
{
    local with_msix=$1
    local with_unknown=$2

    # ------------------------------------
    # Determine PCI/PCICONF major numbers.
    # Initialize PCI/PCICONF minor numbers.
    # ------------------------------------

    check_lspci_existance
    if [ $? -ne 0 ]; then
        return 1
    fi
    mstr=`cat /proc/devices | grep 'mst_pci$'`
    if [ $? -ne 0 ]; then
        echo
        echo "mst_pci driver not found"
        return 1
    fi
    set -- $mstr
    pcimajor=$1
    mstr=`cat /proc/devices | grep 'mst_pciconf$'`
    if [ $? -ne 0 ]; then
        echo
        echo "mst_pciconf driver not found"
        return 1
    fi
    set -- $mstr
    pciconfmajor=$1
    pciminor=0
    pciconfminor=0


    if [ "$with_unknown" == "1" ]; then
        pci_pciconf_minor=$(prepare_create_pci_dev $UNKNOWN_ID $pciminor $pciconfminor $pcimajor $pciconfmajor $with_msix)
        set -- $pci_pciconf_minor
        pciminor=$1
        pciconfminor=$2
    else
        element_count=${#dev_id_database[@]}
        index=0
        while [ "$index" -lt "$element_count" ]; do
            set -- ${dev_id_database[$index]}
            devid=$1
            pci_pciconf_minor=$(prepare_create_pci_dev $devid $pciminor $pciconfminor $pcimajor $pciconfmajor $with_msix)
            set -- $pci_pciconf_minor
            pciminor=$1
            pciconfminor=$2

            ((index++))
        done
    fi

    element_count=${#live_fish_id_database[@]}
    index=0
    while [ "$index" -lt "$element_count" ]; do
        set -- ${live_fish_id_database[$index]}
        devid=$1
        pci_pciconf_minor=$(prepare_create_pci_dev_live_fish $devid $pciconfminor $pciconfmajor)
        pciconfminor=$pci_pciconf_minor
        ((index++))
    done

    return

}

# create all devices
create_devices()
{
    echo "$1"
    create_pci_devices $2 $3
    create_mtusb_devices
    return
}

is_module()
{
local RC

    /sbin/lsmod | grep -w "$1" > /dev/null 2>&1
    RC=$?

return $RC
}
load_module()
{
    mod_name=$1
    mod_file_path=$2
    load_cmd=$3
    load_cmd_string=$4

    if is_module ${mod_name}
    then
        echo "[warn] ${mod_name} is already loaded, skipping"
    else
            action "${load_cmd_string}" "${load_cmd}" "${load_cmd_flags}" "${mod_file_path}"
    fi

}

get_dev_id_by_mst()
{
    mst_dev=$1
    dev_rev=`${mbindir}/mcra ${mst_dev} 0xf0014`
    local str=${dev_rev:6:4}
    str=`echo $str | tr a-z A-Z`
    echo $str
}

# Function to check the conf file if it's good !

check_existence()
{
    obj=$1
    if [ $2 == "n" ]; then
        list=("${devices_names[@]}")
    else
        list=("${ids[@]}")
    fi
    for l in "${list[@]}"
    do
        #echo comparing $obj with $l
        if [ $obj == $l ]; then
            return 1
        fi
    done
    return 0
}

check_conf()
{
    if [ ! -f $MST_CONF ]; then
        echo "-W- Missing mst conf file: $MST_CONF"
        return 0
    fi
    conf=$1
    while read line
    do
        if [ ${#line} != 0 ]; then
            if [[ "$line" == "#"* ]]; then
                continue
            fi
            conf_opcode=$(echo ${line} | awk '{print $1}')
            if [[ ${conf_opcode} == "RENAME" ]]; then
                dev_type=$(echo ${line} | awk '{print $2}')
                devname=$(echo ${line} | awk '{print $3}')
                id=$(echo ${line} | awk '{print $4}')
                if [[ ${dev_type} == "USB" ]]; then
                   devname=${devname}-mtusb-1
                else
                    echo -W- Renaming ${dev_type} devices is not supported !
                    continue
                fi
                check_existence ${devname} "n"
                rc=$?
                if test $rc -ne 0 ; then
                    echo -e "-E- The Conf file is not right !\n-E- line: $line have duplicated device name, Renaming was ignored !"
                    ENABLE_RENAMING=0
                    return 1
                fi
                check_existence ${id} "id"
                rc=$?
                if test $rc -ne 0 ; then
                    echo -e "$res-E- The Conf file is not right !\n-E- line: $line have duplicated ID, Renaming was ignored !"
                    ENABLE_RENAMING=0
                    return 1
                fi
                devices_names+=(${devname})
                ids+=(${id})
                ENABLE_RENAMING=1
            else
                echo -W- OPCODE=${conf_opcode} is not supported in line: $line !
                continue
            fi
        fi
    done <$MST_CONF
}

get_devname_from_pci()
{
    devs_arr=(`grep -l domain:bus:dev.fn=$1 /dev/mst/mt*pciconf*[0-9]`)
    mst_dev_t=${devs_arr[0]}
    echo "${mst_dev_t}"
}

# Main function
start()
{
    local with_msix=0
    local with_unknwon_id=0
    local with_i2cm=0

    check_conf $MST_CONF

    while (( "$#" )); do
        if [ "$1" == "--$WITH_MSIX" ]; then
            with_msix=1
        elif [ "$1" == "--$WITH_UNKNOWN_ID" ]; then
            with_unknwon_id=1
        elif [ "$1" == "--$WITH_I2CM" ]; then
            with_i2cm=1
        elif [ "$1" == "--$WITH_DEVI2C" ]; then
            ENABLE_I2C_DEV=1
        elif [ "$1" == "--$WITH_DEVLPC" ]; then
            ENABLE_LPC_DEV=1
        else
            echo "-E- Unknown argument $1"
            exit 1
        fi

        shift
    done



    echo "Starting $prog"

    # Create empty MST devices directory
    # rm -fr ${mdir}
    # mkdir ${mdir}
    if [ ! -d ${mdir} ]; then
        mkdir ${mdir}
    fi

    if [ "$ENABLE_I2C_DEV" == "1" ]; then
        if ! ls /dev/i2c-* 1> /dev/null 2>&1; then
            action "Loading I2C modules" "${modprobe}" i2c-dev
            sleep 0.1
        fi
        for f in /dev/i2c-*; do
                # enforce format
                if [[ ${f} =~ ^/dev/i2c-[0-9]+$ ]]; then
                    dev=`basename $f`
                    I2C_DEV=${mdir}/dev-$dev
                    rm -f $I2C_DEV
                    ln -s $f $I2C_DEV
                fi
        done
    fi
    if [ "$ENABLE_LPC_DEV" == "1" ]; then
        IO_PORTS_FILE="/proc/ioports"
        if [ -f ${IO_PORTS_FILE} ]; then
            num_of_ports=$(cat ${IO_PORTS_FILE} | grep lpc | wc -l)
            if [ "${num_of_ports}" != "0" ]; then
               echo "IO regions num: ${num_of_ports}" > ${mdir}/dev-lpc-1
               region_index=0
               for port_range in $(cat ${IO_PORTS_FILE} | grep lpc | awk '{print $1}')
               do
                   echo "IO region${region_index}: ${port_range}" >> ${mdir}/dev-lpc-1
                   region_index=$((region_index + 1))
               done
            fi
        fi
    fi

    MST_PCI_MOD="mst_pci"
    MST_PCICONF_MOD="mst_pciconf"
    load_module "${MST_PCI_MOD}"     "${MST_PCI_MOD}"     "${modprobe}"  "Loading MST PCI module"
    load_module "${MST_PCICONF_MOD}" "${MST_PCICONF_MOD}" "${modprobe}"  "Loading MST PCI configuration module"

    # create all related devices
    create_devices "Create devices"  $with_msix $with_unknwon_id
    if  ls ${mdir}| grep -e "_cr" > /dev/null 2>&1
    then :
    else
        action "Unloading MST PCI module (unused)" modprobe -r mst_pci
    fi
    if ls ${mdir}| grep -e "conf" > /dev/null 2>&1
    then :
    else
        action "Unloading MST PCI configuration module (unused)" modprobe -r mst_pciconf
    fi

    for dev in /dev/*
    do
        if [ -r "$dev" ]; then
            if expr match "$dev" ".*livefish.*" > /dev/null 2>&1
            then
                devnam=${mdir}/`basename $dev`
                if [ ! -L ${devnam} ]; then
                   ln -s ${dev} ${devnam}
                fi
            fi
        fi
    done

    for dev in $mlnx_switch_dev_dir/*
    do
        if [ -r "$dev" ]; then
            if expr match "$dev" ".*mlnxsw-*" > /dev/null 2>&1
            then
                devnam=${mdir}/`basename $dev`
                devnam="${devnam/mlx/mlnx}"
                if [ ! -f ${devnam} ]; then
                   ln -s ${dev} ${devnam}
                fi
            fi
        fi
    done

    if ! ls /dev/i2c-* 1> /dev/null 2>&1; then
        if lsmod | grep "i2c_dev" > /dev/null ; then
            action "Unloading I2C module (unused)" modprobe -r i2c-dev
        fi
    fi

    dev_name="${PMTUSB_NAME}-1"
    if [ x"$with_i2cm" == x"1" ]; then
        for dev in `ls ${mdir}| grep -e "conf"`; do
            conf_dev="${mdir}/$dev"
            dev_rev=`get_dev_id_by_mst $conf_dev`
            if [ x"${dev_rev}" == x"${ConnectX3_HW_ID}" ] || [ x"${dev_rev}" == x"${ConnectX3_PRO_HW_ID}" ]; then
                action "PCIe to I2c Bridge" ln -s ${conf_dev} ${mdir}/${dev_name}
                dev_name="P${dev_name}"
            fi
            #
        done
    fi
}

function check_module_busy()
{
    mod_name=$1
    used_by=$(lsmod | grep -w ${mod_name} | awk '{print $3}')
    if [ "${used_by}" == "0" -o "${used_by}" == "" ]; then
        return 0
    else
        echo "-E- ${mod_name} module is in use, stop operation failed, you may use \"mst stop --force\" to force stop operation."
        exit 1
    fi
}

function check_flint_busy()
{
    flint_name=$1
    used_by=$(ps -all | grep -w ${flint_name} | grep -v grep)
    if [ "${used_by}" == "" ]; then
        return 0
    else
        echo "-E- ${flint_name} is in use, stop operation failed, please wait until ${flint_name} is completed."
        exit 1
    fi
}

clean_mdir()
{

    if [ "$IS_MLNXOS" == "1" ]; then
        find ${mdir}/* -not -name "*dev-i2c*" -exec rm -f {} \;
    else
        rm -fr ${mdir}
    fi
    rm -fr ${CONF_DIR}/usb*serial
}

stop()
{
    check_flint_busy flint_oem
    check_flint_busy flint_ext
    check_flint_busy mlxfwmanager

    if [ "$1" == "--$FORCE_STOP" ]; then
        ENABLE_FORCE_STOP=1
    fi

    echo "Stopping $prog"

    serv_stop
    if [ "${ENABLE_FORCE_STOP}" != "1" ]; then
        check_module_busy mst_pciconf
        check_module_busy mst_pci
    fi

    for dev in ${mdir}/*
    do
        if [ -e "$dev" ]; then
          ${mbindir}/mstop "$dev" >/dev/null 2>&1
        fi
    done

    if  lsmod | grep mst_pciconf > /dev/null
    then
        action "Unloading MST PCI configuration module" modprobe -r  mst_pciconf
    fi
    if  lsmod | grep mst_pci | grep -v mst_pciconf> /dev/null
    then
        action "Unloading MST PCI module" modprobe -r mst_pci
    fi


    if lsmod | grep i2c_dev > /dev/null
    then
         action "Unloading i2c driver" modprobe -r i2c_dev
    fi

    clean_mdir
}

print_chip_rev_internal()
{
    export MTCR_REMOTE_WARN=1
    local dev_rev=`${mbindir}/mcra $1 0xF0014`
    unset MTCR_REMOTE_WARN
    if [ "$dev_rev" == "0xbad0cafe" ]; then
        local str="NA"
    elif [ "$dev_rev" == "0xbadacce5" ]; then
        local str="NA"
    else
        local str=${dev_rev:4:2}
        str=`echo $str | tr a-z A-Z`
    fi
    echo "                                   Chip revision is: $str"
}

print_chip_rev()
{
    local dev=$1
    if expr match "$dev" ".*_pci_cr" > /dev/null 2>&1
    then
        print_chip_rev_internal $dev
    fi
    if expr match "$dev" ".*_pciconf" > /dev/null 2>&1
    then
        print_chip_rev_internal $dev
    fi
}
get_mtusb_serial()
{
    bus=$1
    dev=$2
    fname="usb_${bus}_${dev}_serial"
    serial_file_name=${CONF_DIR}/${fname}
    if [ ! -f ${serial_file_name} ]; then
        generate_serial_file $1 $2
        if [ ! -f ${serial_file_name} ]; then
            echo ERROR
            return
        fi
    fi

    iserial=$(cat ${serial_file_name})
    if [ ${#iserial} == 0 ]; then
        echo ERROR
    else
        echo ${iserial}
    fi
}

print_mtusb_sn()
{
    bus=`readlink $1 | rev | cut -f2 -d/ | rev`
    dev=`readlink $1 | rev | cut -f1 -d/ | rev`
    iserial=`get_mtusb_serial $bus $dev`
    printf "%35siSerial = 0x$iserial\n"
}

function ignore_phys_fn()
{
    set dev=$1
    if expr match "$dev" ".*_pciconf[0-9]*\.[0-9]*"  > /dev/null 2>&1; then
        echo "YES"
        return
    fi
    if expr match "$dev" ".*_pci_cr[0-9]*\.[0-9]*"  > /dev/null 2>&1; then
        echo "YES"
        return
    fi
    echo "NO"

}
IGNORE_FUNCS=1

print_ul_mdevices_info()
{
    echo -e "\nPCI Devices:"
    echo -e "------------\n"
    mdevices="$(mdevices_info -vv)"
    RC=$?
    if [ $RC != 0 ]; then
        echo -e "\tNo devices were found.\n"
        return
    fi
    echo "${mdevices}" | while read -r line
    do
        if expr match "$line" "[-]*" > /dev/null 2>&1; then
            continue
        fi
        if expr match "$line" ".*PCI.*" > /dev/null 2>&1; then
            continue
        fi
        read -a arr <<< $line
        if [[ "$IGNORE_FUNCS" == "1" ]]; then
            if [[ "${arr[2]}" == *"1" ]]; then
                continue
            fi
        fi
        if [[ -z "${arr[2]}" ]]; then
            continue;
        fi
        echo -e "${arr[2]}\n"
    done

}

print_status()
{
    local verbose=$1
    is_mst_loaded=0

    # Check modules
    echo "MST modules:"
    echo "------------"
    if  is_module mst_pci
    then
        echo "    MST PCI module loaded"
        is_mst_loaded=1
    else
        echo "    MST PCI module is not loaded"
    fi
    if  is_module mst_pciconf
    then
        echo "    MST PCI configuration module loaded"
        is_mst_loaded=1
    else
        echo "    MST PCI configuration module is not loaded"
    fi

    if  cat /proc/devices | grep mst_ppc > /dev/null
    then
       echo  "    MST PPC Bus module loaded"
    fi

    if [ "$verbose" == "-v" -o "$verbose" == "-vv" ]; then
        mdevices_info $verbose
        ${PYTHON_EXEC} ${MFT_PYTHON_TOOLS}/gearbox/gearbox_status_script.py
        return
    elif [ "$verbose" != "" ]; then
        echo "    -E- Unknown argument \"$verbose\""
        exit 1
    fi

    if [ $is_mst_loaded != 1 ]; then
        #echo "User Level devices:"
        #echo "-------------------"
        print_ul_mdevices_info
        if [ ! -d ${mdir} ]; then
            return
        fi
    fi
    # Devices
    devcnt=0
    rcnt=0
    rdevs=""
    ibcnt=0
    ibdevs=""
    lpccnt=0
    lpcdev=""
    cabledevs=""
    cablescnt=0
    mlnxsw_dev_cnt=0
    mlnxsw_devs=""
    if [ $is_mst_loaded -eq 1 ]; then
        echo
        echo "MST devices:"
        echo "------------"
    fi
    for dev in ${mdir}/*
    do
        if [ -r "$dev" ]; then
            if expr match "$dev" ".*mlnxsw-*" > /dev/null 2>&1
            then
                mlnxsw_devs=$mlnxsw_devs" $dev"
                mlnxsw_dev_cnt=$((  $mlnxsw_dev_cnt + 1 ))
            elif expr match "$dev" ".*mtusb.*lx*" > /dev/null 2>&1 # linkx device on EVB
            then
                cabledevs=$cabledevs" $dev"
                cablescnt=$((  $cablescnt + 1 ))
            elif expr match "$dev" ".*cable.*" > /dev/null 2>&1
            then
                cabledevs=$cabledevs" $dev"
                cablescnt=$((  $cablescnt + 1 ))
            elif expr $dev : '.*:' > /dev/null 2>&1
            then
                rdevs=$rdevs" $dev"
                rcnt=$((  $rcnt + 1 ))
            elif expr match "$dev" ".*lid-0x[0-9A-Fa-f]*" > /dev/null 2>&1
            then
                ibdevs=$ibdevs" $dev"
                ibcnt=$((  $ibcnt + 1 ))
            elif expr match "$dev" ".*lid-[0-9]*" > /dev/null 2>&1
            then
                ibdevs=$ibdevs" $dev"
                ibcnt=$((  $ibcnt + 1 ))
            elif expr match "$dev" ".*ibdr-[0-9]*" > /dev/null 2>&1
            then
                ibdevs=$ibdevs" $dev"
                ibcnt=$((  $ibcnt + 1 ))
            elif expr match "$dev" ".*${PMTUSB_NAME}.*" > /dev/null 2>&1
            then
                    echo -e "$dev\t\t - PCIe to I2C adapter as I2C primary"
            elif expr match "$dev" ".*usb.*" > /dev/null 2>&1
            then
                    #echo -e "$dev\t\t - USB to I2C adapter as I2C primary"
                    printf "%-33s- USB to I2C adapter as I2C primary\n" "$dev"
                    print_mtusb_sn $dev
            elif expr match "$dev" ".*nvjtag.*" > /dev/null 2>&1
            then
                    printf "%-33s- USB to JTAG adapter\n" "$dev"
            elif expr match "$dev" ".*lpc.*" > /dev/null 2>&1
            then
                lpcdevs=$lpcdevs" $dev"
                lpccnt=$((  $lpccnt + 1 ))
            elif expr match "$dev" ".*dev-i2c.*" > /dev/null 2>&1
            then
                    echo -e "$dev\t\t - Embedded I2C primary"
            elif expr match "$dev" ".*livefish.*" > /dev/null 2>&1
            then
                echo -e "$dev\t - Livefish char device"
            else
                ignore_dev=$(ignore_phys_fn $dev)
                if [ "$ignore_dev" == "NO" ]; then
                    if [ ! -d "$dev" ]; then
                        cat $dev
                        print_chip_rev $dev
                    fi
                fi
            fi
            devcnt=$((  $devcnt + 1 ))
       fi
    done

    if [ ${rcnt} -ne 0 ]; then
        echo
        echo "Remote MST devices:"
        echo "-------------------"
        for dev in $rdevs
        do
            echo $dev
            print_chip_rev $dev
        done
    fi

    if [ ${ibcnt} -ne 0 ]; then
        echo
        echo "Inband devices:"
        echo "-------------------"
        for dev in $ibdevs
        do
            echo $dev
        done
    fi

    if [ ${lpccnt} -ne 0 ]; then
        echo
        echo "LPC device:"
        echo "-------------------"
        for dev in $lpcdevs
        do
            echo $dev
        done
    fi

    if [ ${cablescnt} -ne 0 ]; then
        echo
        echo "Cables:"
        echo "-------------------"
        for dev in $cabledevs
        do
            echo `basename $dev`
        done
    fi

    if [ ${mlnxsw_dev_cnt} -ne 0 ]; then
        echo "Switch - mlnxsw devices:"
        echo "-------------------------"
        first=1
        for dev in $mlnxsw_devs
        do
            ix=0
            # Go over once for getting the keys (Parameters names)
            if [ ${first} == 1 ]; then
                printf "%-20s" "NAME"
                while IFS='' read -r line || [[ -n "$line" ]]; do
                    IFS='=' read -r -a array <<< "$line"
                    printf "%-20s" "${array[0]}"
                done < "$dev"
                printf "\n"
            fi
            # Go over for getting the values (Parameters names)
            printf "%-20s" "$dev"
            while IFS='' read -r line || [[ -n "$line" ]]; do
                IFS='=' read -r -a array <<< "$line"
                        if [ "$line" != "" ]; then
                            val=${array[1]} # clean spacse
                            printf "%-20s" "${val//[[:blank:]]/}"
                        fi
            done < "$dev"
            printf "\n"
            first=0
        done
    fi
    
    #
    printf "\n"
    ${PYTHON_EXEC} ${MFT_PYTHON_TOOLS}/gearbox/gearbox_status_script.py
}



# return the matching slot file name in the PCI fs
# Check if domain need to be added.
get_pci_file()
{
    slot=$1

    local prefix=/proc/bus/pci/

    if echo $slot | grep ":..:"  > /dev/null 2>&1
    then
        dombus=`echo $slot | cut -f1,2 -d:`
        devfn=`echo  $slot | cut -f3   -d:`
    else
        dombus=`echo $slot | cut -f1   -d:`
        devfn=`echo  $slot | cut -f2   -d:`

        if [ -d "$prefix/0000:$dombus" ]
        then
            # Try to add zero domain to the name if domain not explicitly given
            dombus="0000:$dombus"
        fi
    fi

    echo "$prefix/$dombus/$devfn"
}


save_pci()
{
    if [ $# -gt 1 ]; then
        echo "save_pci() too many arguments"
        exit 1
    fi

    check_lspci_existance
    if [ $? -ne 0 ]; then
        return 1
    fi

    local pcidev=$1 # user specified pci device to save

    if [ -n "$pcidev" ]; then
        OLD_PYTHONPATH=$PYTHONPATH
        PYTHONPATH=""
        mlxpci -d $pcidev save > /dev/null 2>&1
        mlxpci_rc=$?
        PYTHONPATH=$OLD_PYTHONPATH
        if [ $mlxpci_rc -ne 0 ]; then
            echo "failed to save PCI configuration"
            exit 1
        fi
    else
        OLD_PYTHONPATH=$PYTHONPATH
        PYTHONPATH=""
        mlxpci save > /dev/null 2>&1
        mlxpci_rc=$?
        PYTHONPATH=$OLD_PYTHONPATH
        if [ $mlxpci_rc -ne 0 ]; then
            echo "failed to save PCI configuration"
            exit 1
        fi
    fi

}

load_pci()
{
    if [ $# -gt 1 ]; then
        echo "load_pci() too many arguments"
        exit 1
    fi

    check_lspci_existance
    if [ $? -ne 0 ]; then
        return 1
    fi

    local pcidev=$1 # user specified pci device to save

    if [ -n "$pcidev" ]; then
        OLD_PYTHONPATH=$PYTHONPATH
        PYTHONPATH=""
        mlxpci -d $pcidev load > /dev/null 2>&1
        mlxpci_rc=$?
        PYTHONPATH=$OLD_PYTHONPATH
        if [ $mlxpci_rc -ne 0 ]; then
            echo "failed to load PCI configuration"
            exit 1
        fi
    else
        OLD_PYTHONPATH=$PYTHONPATH
        PYTHONPATH=""
        mlxpci load > /dev/null 2>&1
        mlxpci_rc=$?
        PYTHONPATH=$OLD_PYTHONPATH
        if [ $mlxpci_rc -ne 0 ]; then
            echo "failed to load PCI configuration"
            exit 1
        fi
    fi

}

get_reset_addr()
{

    #### A trick to get the array that was passed to the function as an argument ####
    OLD_IFS=$IFS; IFS=''

    local array_string="$1[*]"
    local data_base_arr=(${!array_string})

    IFS=$OLD_IFS
    ###################################################################################\


    local raddr=0x0


    local element_count=${#data_base_arr[@]}
    local index=0

    while [ "$index" -lt "$element_count" ]; do
        set -- ${data_base_arr[$index]}
        devid=$1
        rst_addr=$2
        dev_expr=".*$(get_dev_name $devid)pci"

        if expr $device : $dev_expr > /dev/null 2>&1
        then
            raddr=$rst_addr
            break;
        fi

        ((index++))
    done

    echo $raddr
}

reset_pci()
{
    local orig_device=$1
    local device=$1
    local raddr=0x0

    if [ ! -e $device ]; then
        device="$mdir/$device"
        if [ ! -e $device ]; then
            echo "Device \"$orig_device\" (or \"$device\") doesn't exist"
            return 1
        fi
    fi

    raddr=$(get_reset_addr dev_id_database)
    if [ "$raddr" == "0x0" ]; then
        raddr=$(get_reset_addr live_fish_id_database)
        if [ "$raddr" == "0x0" ]; then
            echo "$device is a wrong device to reset"
            return 1
        fi
    fi

    echo -n "Reset device $device"

    if ${mbindir}/mcra $device $raddr 1
    then
        sleep 1
        echo_success
        echo
        return 0
    else
        echo_failure
        echo
        return 1
    fi

    return 0
}

radd()
{
    local host=$1
    local flag=$2
    local secret=$3
    local port=23108

    if expr $host : '.*:' > /dev/null 2>&1
    then
        set -- $(IFS=:; set -- $host; echo "$@")
        host=$1
        port=$2
    fi
    mkdir -p $mdir
    devs=`${mbindir}/mremote $host:$port L $flag $secret`; RETVAL=$?
    for dev in $devs
    do
      if ! [[ $dev =~ [:#][0-9]+, ]] ; then  # do not add remote devices from the target host (multiple hops remote not supported)
        local fname=${mdir}/$host:$port,`echo $dev | sed -e 's/\//@/g'`
        touch $fname
      fi
    done
}

rdel()
{
    local host=$1
    local port=23108
    if expr $host : '.*:' > /dev/null 2>&1
    then
        set -- $(IFS=:; set -- $host; echo "$@")
        host=$1
        port=$2
    fi
    rm -f ${mdir}/$host:$port,*
    ${mbindir}/mremote $host:$port 'D'

}

cabledel()
{
    rm -f ${mdir}/*cable*
    rm -f ${mdir}/*_lx*   
}


g_with_ib="--with_ib"
g_ibstat="ibstat"
g_ibv_devices="ibv_devices"
g_guids_list=""

is_guid_exists()
{
    guid=$1
    for g in ${g_guids_list[@]}; do
        if [ "$g" == "$guid" ]; then
            return 1
        fi
    done
    return 0
}

gboxadd()
{
    ${PYTHON_EXEC} ${MFT_PYTHON_TOOLS}/gearbox/abir_add_devices.py
    ${PYTHON_EXEC} ${MFT_PYTHON_TOOLS}/gearbox/amos_add_devices.py
}

gboxdel()
{
    ${PYTHON_EXEC} ${MFT_PYTHON_TOOLS}/gearbox/gearbox_remove_script.py
}

jtagadd()
{
    dev_num=`${mbindir}/nvjtag_discovery`
    for (( dev_index=0; dev_index<$dev_num; dev_index++ )) do
        touch ${mdir}/"nvjtag_$dev_index"
    done
    echo "-I- Added $dev_num Jtag devices..."

}

jtagdel()
{
    rm -f ${mdir}/nvjtag_*
}

cableadd()
{

    # Set the flags 
    WITH_IB=0  # false
    hca_id=""  # N/A
    ib_port="" # N/A

    WITH_CHIPSET=0 # false
    while [ "$1" ]; do

        case $1 in
            "${g_with_ib}")
                WITH_IB=1
                shift
                if [ "$1" ] && [[ ! "$1" =~ ^\- ]] ; then # a flag that doesn't start with "-"
                    hca_id=$1
                    shift
                else
                    continue
                fi  

                if [ "$1" ] && [[ ! "$1" =~ ^\- ]]; then # a flag that doesn't start with "-"
                    ib_port=$1
                    shift
                else
                    continue
                fi  

                ;;

            "--with_chipset")
                WITH_CHIPSET=1
                shift
                ;;

            *)
            echo "-E- Bad switch \"$1\" for mst ib add, please run mst help for more details."
            exit 1
        esac

    done

    #echo with_ib=$WITH_IB
    #echo hca_id=$hca_id
    #echo ib_port=$ib_port
    #echo with_chipset=$WITH_CHIPSET

    cblcnt=0
    if  is_module mst_pciconf; then
        devs=/dev/mst/*pciconf*
    else
        IGNORE_FUNCS=0
        devs=$(print_ul_mdevices_info)
        ul_mode=1
    fi
    if [ -f ${mbindir}/mlxcables ]; then
        for dev in $devs;
        do
            if ! expr match "$dev" ".*cable.*" > /dev/null 2>&1; then
                #MAX num of ports is 128 for switches
                #echo "Checking device: ${dev}"
                ports_type=`mlxcables -d ${dev} --get_dev_type`
                RC=$?
                if [[ $RC != 0 ]]; then
                    continue
                fi
                type=`echo $ports_type | cut -d' ' -f1`
                ports=`echo $ports_type | cut -d' ' -f2`
                if [[ "$ports" == "-1" ]]; then
                    ports=128
                fi
                if [[ "$type" == "HCA" ]]; then
                    module_num=`mlxcables -d $dev --get_module 1`
                    RC=$?
                    if [[ $RC != 0 ]]; then
                        continue
                    fi
                    cblcnt=$((  $cblcnt + 1 ))
                    cable_name=${dev#/dev/mst/}_cable_${module_num}
                    cable_dev=/dev/mst/${cable_name}
                    if [[ "$ul_mode" == "1" ]]; then
                        cable_dev=${mdir}/${cable_name}
                    fi
                    mkdir -p ${mdir}
                    touch ${cable_dev}
                    cable_check=`${mbindir}/mlxcables -d ${cable_name} -c`
                    if [[ ${cable_check} == *FAILED* ]]; then
                        rm -f ${cable_dev}
                        cblcnt=$((  $cblcnt - 1 ))
                    fi
                elif [[ "$type" == "SW" ]]; then
                    for (( port=0; port<$ports; port++ )) do
                        cblcnt=$((  $cblcnt + 1 ))
                        cable_name=${dev#/dev/mst/}_cable_$port
                        cable_dev=/dev/mst/${cable_name}
                        if [[ "$ul_mode" == "1" ]]; then
                            cable_dev=${mdir}/${cable_name}
                        fi
                        mkdir -p ${mdir}
                        touch ${cable_dev}
                        cable_check=`${mbindir}/mlxcables -d ${cable_name} -c`
                        if [[ ${cable_check} == *FAILED* ]]; then
                            rm -f ${cable_dev}
                            cblcnt=$((  $cblcnt - 1 ))
                        fi

                    done
                fi
            fi
        done
    fi
    if [ ${WITH_IB} == "1" ]; then
        ib_devs=(${hca_id})
        ports=(${ib_port})
        if [ "${hca_id}" == "" ]; then
            if [ `is_tool_existing ${g_ibstat}` == "1" ]; then
                devs=`${g_ibstat} -l | tr '\r\n' ' '`
            elif [ `is_tool_existing ${g_ibv_devices}` == "1" ]; then
                devs=`${g_ibv_devices} | tail -n+3 | tr -d ' ' | cut  -f1 | tr '\r\n' ' '`
            else
                echo "-E- Failed to find a tool to get the network IB interfaces"
                exit 1
            fi
            ib_devs=("${devs}")
            ports=(1 2)
        fi
        get_ib_tools_info_index ${tool_to_use}; index=$?
        set -- ${g_tools_database[index]}
        g_tool_path=$2; g_tool_type=$3; ca_flag=$4; p_flag=$5; g_old_indexing=$6; topo_file=$7 ;


        added_nodes_type="only_mlnx"
        use_ibdr=0
        echo "-I- Discovering the fabric for connected cables ..."
        for dev in ${ib_devs[@]}; do
            for ib_port in ${ports[@]}; do
                cmd="$g_tool_path"
                hca_idx=${dev}
                if [ "${g_tool_type}" == "${G_TT_DIAGNET}" ]; then
                    # Convert from hca name (mlx4_0,mthca0,...) to index (0,1..) using ibv_devinfo.
                    if [ ${g_old_indexing} == "1" ]; then
                        get_index_for_old_diagnet ${dev}; hca_idx=$?
                    fi
                    cmd="$cmd -skip all"
                fi
                cmd="$cmd -${ca_flag} $hca_idx -${p_flag} $ib_port"
                rm -f ${topo_file}
                $cmd &> ${g_out_file}; RC=$?
                if [ "$RC" != "0" ]; then
                    continue
                fi
                if [ ! -f ${topo_file} ]; then
                    echo "-E- File ${topo_file} not found, Skipping ..."
                    continue
                fi
                #Run mst_ib_add script
                mkdir -p $mdir
                for d in `${mbindir}/mst_ib_add ${topo_file} ${added_nodes_type} ${g_tool_type} ${use_ibdr} $dev $ib_port --with-guids`; do
                    mdev=`echo $d | cut -d'#' -f1`
                    guid=`echo $d | cut -d'#' -f2`
                    if expr match "$mdev" ".*CA_.*" > /dev/null 2>&1
                    then
                        is_guid_exists $guid; rc=$?
                        if [ $rc == 1 ]; then
                            #echo "Ignoring $mdev, it was added before by another port"
                            continue
                        fi
                        g_guids_list+=("$guid")
                    fi
                    create_lid_cable $mdev; c=$?
                    cblcnt=$(( $cblcnt + $c ))
                done
            done
        done

    fi
    if [ -f ${mbindir}/mlxcables ]; then
        mtusb_devs=/dev/mst/*mtusb*
        for dev in $mtusb_devs;
            do
                if ! expr match "$dev" ".*cable.*" > /dev/null 2>&1; then
                    for (( port=0; port<4; port++ )) do
                        cblcnt=$((  $cblcnt + 1 ))
                        cable_name=${dev#/dev/mst/}_cable_$port
                        cable_dev=${dev}_cable_$port
                        mkdir -p ${mdir}
                        touch ${cable_dev}
                        cable_check=`${mbindir}/mlxcables -d ${cable_name} -c`
                        if [[ ${cable_check} == *FAILED* ]]; then
                            rm -f ${cable_dev}
                            cblcnt=$((  $cblcnt - 1 ))
                        fi
                    done
                fi
            done

        if command -v i2cdetect &> /dev/null; then
            i2c_devs=$( i2cdetect -l | grep -i nv | grep -P "adapter [1|2]" | cut  -f1 | sort )
            for dev in $i2c_devs;
                do
                    dev="/dev/mst/dev-"$dev
                    dev_type=$(cat /sys/class/dmi/id/product_name)
                    dev_type_flag=""
                    if [ ${dev_type} == "$NVL3_WOLF_ID" -o ${dev_type} == "$NVL4_KONG_ID" ]; then
                        dev_type_flag=_${dev_type}
                    fi
                    if ! expr match "$dev" ".*cable.*" > /dev/null 2>&1; then
                    for (( port=0; port<8; port++ )) do
                        cblcnt=$((  $cblcnt + 1 ))
                        cable_name=${dev#/dev/mst/}${dev_type_flag}_cable_$port
                        cable_dev=${dev}${dev_type_flag}_cable_$port
                        mkdir -p ${mdir}
                        touch ${cable_dev}
                        cable_check=`${mbindir}/mlxcables -d ${cable_name} -c`
                        if [[ ${cable_check} == *FAILED* ]]; then
                            rm -f ${cable_dev}
                            cblcnt=$((  $cblcnt - 1 ))
                        fi
                    done
                    fi
                done
        fi
    fi

    if [ ${WITH_CHIPSET} == "1" ]; then
        mst_cable
    fi

    echo "-I- Added $cblcnt cable devices .."
}

G_TT_DIAGNET="diagnet"
G_TT_NETDISCOVER="netdiscover"


g_ibdiagnet_tmp_path="/opt/bin/ibdiagnet"
g_out_file="/tmp/mft_discover.out"
g_mlxcables_out_file="/tmp/mft_mlxcables.out"

g_ibdiag2_id="ibdiagnet2"
g_new_ibdiag_id="new_ibdiagnet"
g_old_ibdiag_id="old_ibdiagnet"
g_ibnetdiscover="ibnetdiscover"
g_ibdiagnet_tool="ibdiagnet"
g_ibdiagnet2_lst_file="/var/tmp/ibdiagnet2/ibdiagnet2.lst"

g_tools_database=(\
    "${g_ibdiag2_id}    ${g_ibdiagnet_tmp_path} ${G_TT_DIAGNET}     i p 0 ${g_ibdiagnet2_lst_file}"
    "${g_new_ibdiag_id} ${g_ibdiagnet_tool}     ${G_TT_DIAGNET}     i p 0 ${g_ibdiagnet2_lst_file}"
    "${g_old_ibdiag_id} ${g_ibdiagnet_tool}     ${G_TT_DIAGNET}     i p 1 /tmp/ibdiagnet.lst"
    "${g_ibnetdiscover} ${g_ibnetdiscover}      ${G_TT_NETDISCOVER} C P 0 ${g_out_file}"
)

get_ib_tool_index() {
    ID=$1
    element_count=${#g_tools_database[@]}
    index=0
    while [ "$index" -lt "$element_count" ]; do
        set -- ${g_tools_database[$index]}
        mem_id=$1
        if [ "${ID}" == "${mem_id}" ]; then
            return $index
        fi
        ((index++))
    done
    echo "-E- Unknown discover tool \"${ID}\", to get the supported tool list run: 'mst help'"
    exit 1
}

function is_tool_existing() {
    cmd_exists=`which $1 2> /dev/null`
    if [ "$cmd_exists" == "" ]; then
        echo "0"
    else 
        echo "1"
    fi
}
function is_ibdiagnet_new() {
    ibdiagnet_tool=$1
    version="`$ibdiagnet_tool -V 2> /dev/null| head -1`"
    new_ver_regexp=\-I\-\ IBDIAGNET\ [0-9]\.[0-9]
    if [[ "${version}" =~ ${new_ver_regexp} ]]; then
        echo "1"
    else
        echo "0"
    fi
}

function get_ib_tools_info_index()
{
    tool_to_use=$1
    if [ "${tool_to_use}" == "" ]; then
        if [ -f ${g_ibdiagnet_tmp_path} ] && [ `is_ibdiagnet_new ${g_ibdiagnet_tmp_path}` == "1" ]; then
            get_ib_tool_index ${g_ibdiag2_id}; return $?
        elif [ `is_ibdiagnet_new ${g_ibdiagnet_tool}` == "1" ]; then
            get_ib_tool_index ${g_new_ibdiag_id}; return $?
        elif [ `is_tool_existing ${g_ibnetdiscover}` == "1" ]; then
            get_ib_tool_index ${g_ibnetdiscover}; return $?
        elif [ `is_tool_existing ${g_ibdiagnet_tool}` == "1" ]; then
            get_ib_tool_index ${g_old_ibdiag_id}; return $?
        else
            echo "-E- Failed to find a tool to discover the fabric (neither ${g_ibdiagnet_tool} nor ${g_ibnetdiscover} is installed on this machine)"
            exit 1
        fi
    else
        if [ "${tool_to_use}" ==  "${g_ibdiagnet_tool}" ]; then
            if [ `is_ibdiagnet_new ${g_ibdiagnet_tool}` == "1" ]; then
                tool_to_use=${g_new_ibdiag_id}
            else
                tool_to_use=${g_old_ibdiag_id}
            fi
        fi
        get_ib_tool_index ${tool_to_use}; return $?
    fi
 }

function get_index_for_old_diagnet()
{
    hca_id=$1
    if [ "${hca_id}" == "" ]; then
        return ${hca_id}
    fi
    hca_idx=`ibv_devinfo | grep hca_id: | grep -n $hca_id | cut -f1 -d:`
    if [ "$hca_idx" == "" ]; then
        echo "-E- Failed to get hca index for hca \"$hca_id\""
        exit 1
    fi
    return ${hca_idx}
}

g_discover_tool_opt="--discover-tool"
g_topo_file_opt="--topo-file"
g_add_non_mlnx="--add-non-mlnx"
g_use_ibdr_opt="--use-ibdr"

function check_arg() {
    if [ -z $2 ] || [[ "$2" == -* ]]; then
        echo "-E- Missing parameter after \"$1\" switch."
    exit 1
    fi
}


function create_lid_cable()
{
    device=$1

    cblscnt=0
    if [ -f ${mbindir}/mlxcables ]; then
        cmd="${mbindir}/mlxcables -d ${device} --get_ports_num"
        $cmd 1> ${g_mlxcables_out_file}; RC=$?
        if [ "$RC" != "0" ]; then
            echo "-W- Failed to get number of ports for device ${device}, skipping it.."
            return 0
        fi
        ports="$(cat ${g_mlxcables_out_file})"
        no_port=0
        if [[ $ports -lt 3 ]]; then
            no_port=1
            ports=1
        fi

        for (( port=0; port<$ports; port++ )) do
            if [ "$no_port" == "0" ]; then
                cable_dev=${device}_cable_$port
            else
                cable_dev=${device}_cable
            fi
            touch $mdir/${cable_dev}
            cable_check=`${mbindir}/mlxcables -d ${cable_dev} -c`
                cblscnt=$(( $cblscnt + 1 ))
            if [[ ${cable_check} == *FAILED* ]]; then
                rm -f $mdir/${cable_dev}
                cblscnt=$(( $cblscnt - 1 ))
            fi
        done
    fi
    return $cblscnt
}


function ib_add()
{
    tool_to_use=""
    topo_file=""
    added_nodes_type="only_mlnx"
    use_ibdr=0

    # Get the parameters
    while [ "$1" ]; do
        # Stop when we have a non flag paramater (an argument that doesn't start with -)
        if ! [[ "$1" =~ ^\- ]]; then
            break;
        fi
        case $1 in
            "${g_discover_tool_opt}")
                check_arg $1 $2
                tool_to_use=$2
                shift
                ;;

            "${g_add_non_mlnx}")
                added_nodes_type="all"
                shift
                ;;

            "${g_use_ibdr_opt}")
                use_ibdr="1"
                ;;

            "${g_topo_file_opt}")
                check_arg $1 $2
                topo_file=$2
                shift
                ;;
            *)
            echo "-E- Bad switch \"$1\" for mst ib add, please run mst help for more details."
            exit 1
        esac
        shift
    done
    hca_id=$1
    ib_port=$2

    # Is Mkey feature is supported ?
    mkey_is_supported=$(cat /etc/mft/mft.conf | grep mkey_enable | cut -d '=' -f 2 | sed 's/^ *//g');
    sm_config_dir=$(cat /etc/mft/mft.conf | grep sm_config_dir | cut -d '=' -f 2 | sed 's/^ *//g');

    # Get the sm configuration directory.
    if [ "$sm_config_dir" == "" ]; then
            sm_config_dir="/var/cache/opensm/"
    fi

    if [ "$topo_file" == "" ]; then
        get_ib_tools_info_index ${tool_to_use}; index=$?
        set -- ${g_tools_database[index]}
        g_tool_path=$2; g_tool_type=$3; ca_flag=$4; p_flag=$5; g_old_indexing=$6; topo_file=$7 ;

        cmd="$g_tool_path"
        hca_idx=${hca_id}

        if [ "${g_tool_type}" == "${G_TT_DIAGNET}" ]; then
            # Convert from hca name (mlx4_0,mthca0,...) to index (0,1..) using ibv_devinfo.
            if [ ${g_old_indexing} == "1" ]; then
                get_index_for_old_diagnet ${hca_id}; hca_idx=$?
            fi

            if [ $mkey_is_supported == "yes" ]; then
                cmd="$cmd --m_key_files ${sm_config_dir}"
            fi
            if [ $use_ibdr == 1 ]; then
                echo "-E- Option $g_use_ibdr_opt is not supported when using ibdiagnet tool or an lst file"
                exit 1
            fi
        else
            if [ $use_ibdr == 1 ]; then
                cmd="$cmd -s"
            fi
        fi

        if [ "${g_tool_type}" == "${G_TT_NETDISCOVER}" ]; then
            # Is Mkey feature is supported ?
            if [ $mkey_is_supported == "yes" ]; then
                sm_conf_file_path=$(cat /etc/mft/mft.conf | grep sm_conf_file_path | cut -d '=' -f 2 | sed 's/^ *//g');
                # Is Mkey per port feature enabled on OpenSM?
                m_key_per_port_enabled_opensm=$(cat $sm_conf_file_path | grep m_key_per_port | cut -d ' ' -f 2 | sed 's/^ *//g' | awk '{print tolower($0)}');
                if [ ${m_key_per_port_enabled_opensm} == "true" ]; then
                    # Does ibnetdiscover current version support Mkey per port feature?
                    m_key_per_port_supported_ibnetdiscover=$($cmd -h 2>&1 | grep "m_key_files" | sed 's/^ *//g');
                    m_key_per_port_supported=${#m_key_per_port_supported_ibnetdiscover}
                    if [ ${m_key_per_port_supported} != 0 ]; then
                    cmd="$cmd --m_key_files ${sm_config_dir}"
                    else
                        echo "-E- m_key_per_port is not supported by current ibnetdiscover version."
                        echo "please update ibnetdiscover or disable m_key_per_port in OpenSM."
                        exit 1
                    fi
                else
                    key=$(cat ${sm_conf_file_path} | grep m_key | head -1 | cut -d " " -f 2);
                    cmd="$cmd --m_key $key"
                fi
            fi
        fi

        if [ "$hca_id" != "" ]; then
            cmd="$cmd -${ca_flag} $hca_idx"
            if [ "$ib_port" != "" ]; then
                cmd="$cmd -${p_flag} $ib_port"
            fi
        fi

        echo "-I- Discovering the fabric - Running: $cmd"
        rm -f ${topo_file}
        $cmd &> ${g_out_file}; RC=$?
        if [ "$RC" != "0" ]; then
            echo "-E- Command: \"$cmd\" failed (rc: $RC), for more details see: ${g_out_file}"
            exit 1
        fi
    else
        if [ "${tool_to_use}" == "" ]; then
            echo "-E- You should specify which tool you used to generate the given topofile by \"${g_discover_tool_opt} <tool>\""
            exit 1
        fi
        get_ib_tools_info_index ${tool_to_use}; index=$?
        set -- ${g_tools_database[index]}; g_tool_type=$3
    fi

    if [ ! -f ${topo_file} ]; then
        echo "-E- File ${topo_file} not found."
        RETVAL=1
        return
    fi

    ibcnt=0
    cblcnt=0
    mkdir -p $mdir
    for d in `${mbindir}/mst_ib_add ${topo_file} ${added_nodes_type} ${g_tool_type} ${use_ibdr} $hca_id $ib_port`; do
        touch $mdir/$d
        c=0
        ibcnt=$(( $ibcnt + 1 ))
    done

    echo "-I- Added $ibcnt in-band devices"
}

serv_start()
{
    secret=""
    port=23108
    while [ "$3" ]; do
        if [ "$3" == "-s" ]; then
            shift
            secret="$3"
            shift
        elif [[ "$3" =~ ^[0-9]+ ]]; then
            port=$3
            shift
        else
            shift
        fi
    done
    if [[ "$secret" == "" ]]; then
        ${mbindir}/mtserver -p $port &
    else
        ${mbindir}/mtserver -p $port -s $secret &
    fi
    
    mtserver_pid=$!
    ps_output=`ps -p $mtserver_pid | sed "1 d"`
    if [[ "$ps_output" == "" ]]; then
        wait $mtserver_pid
        RETVAL=$?
    fi
}

serv_stop()
{
    ps -efa | grep ${mbindir}/mtserver | grep -v grep | while read str
    do
        set -- $str
        kill $2
    done
}

check_start_args()
{
    if [[ "$1" == "" ]]; then
        return
    fi
    found=0
    read -r -a start_flags <<< "${MST_START_FLAGS} ${MST_START_HIDDEN_FLAGS}"
    for flag in "${start_flags[@]}"
    do
        if [[ "${flag}" == "[$1]" ]]; then
            found=1
        fi
    done
    if [ $found == 0 ]; then
        echo "-E- Unknown argument $1"
        exit 1
    fi
}

# See how we were called.
# --$WITH_I2CM : Create PCIe to I2C adapter as I2C primary for devices that support this feature. (Was removed to hide the feature)

##################################################################################
# functions used by add/rm commands
##################################################################################

# The function gets a number and an array and check if the number is in the array
# Example: Inputs: seeking=8 , array=(1 3 4 6 7 8 12) ; Output 1
function is_in_arr () {

    local seeking=$1 ; shift  # Input number
    local array=$@            # Input array

    local in=0
    for element in $array; do
        if [[ $element == $seeking ]]; then
            in=1
            break
        fi
    done
    echo $in # result
    #return 0 # TODO CHECK
}

# The function gets an array and max number and return a number that doesn't exist in the array and < max
# Example: Inputs: max=50, array=(0 1 2 3 4 5 6) ; Output: 7
function get_free_number () {

    local max=$1 ; shift  # Input max number to search
    local array=$@        # Input array

    local num=0
    while [ $num -le $max ]; do

        res=$(is_in_arr $num ${array[@]})

        if [ $res -eq 0 ]; then
            echo $num
            return 0
        fi

        ((num += 1))

    done

    return 1

}


# The function gets mst-device and return the serial-number
# Example: Input : /dev/mst/mt4117_pciconf3.2 ; Output: 3

function get_serial_num_from_mst_dev(){
    local mst_device=$1
    mst_device=${mst_device/.*/} # Remove .<>
    len=${#mst_device}
    serial_num=${mst_device:(len-1)}
    echo $serial_num
}

# The function gets pci-address and checks if the relvant adapter (NIC) already has serial number. if not allocate new one
# Example for serial-number: /dev/mst/mt4117_pciconf<SERIAL-NUM>.2
function get_serial_num(){

    dbdf=$1
    bus_dev=${dbdf:5:5}

    local serial_num=-1

    local mst_dev=$(mdevices_info -v | grep $bus_dev -m1 | awk '{print $2}')

    if [ -n "$mst_dev" ] && [ $mst_dev != "NA" ]; then # Serial number already exist
        serial_num=$(get_serial_num_from_mst_dev $mst_dev)
    else                    # Need to allocate new serial number for the mst device
        serial_num_arr=()
        while read line; # use here string
            do
                mst_dev=$(echo $line | awk '{print $2}')
                serial_num_ii=$(get_serial_num_from_mst_dev $mst_dev)
                serial_num_arr+=($serial_num_ii)
        done <<< "$(mdevices_info -v | grep $numeric_id)"
        serial_num=$(get_free_number 100 "${serial_num_arr[@]}")
    fi
    echo $serial_num
}



function get_major(){
    local mst_module_type=$1

    if [ $mst_module_type == "pciconf" ];then
        mst_module_name=mst_pciconf
    elif [ $mst_module_type == "pci_cr" ];then
        mst_module_name=mst_pci
    else
        echo 'mst moudle type not recognized'
        exit 1
    fi


    local major=$(cat /proc/devices | grep $mst_module_name$ | awk '{print $1}');
    echo $major
}


function get_minor(){

    local mst_module_type=$1
    local major=$2

    local minors=()
    while read line;
        do
        minor=$(echo $line | awk '{print $6}')
        minors+=($minor)
    done <<< "$(ls -l /dev/mst | grep $mst_module_type)"

    local free_minor=$(get_free_number $major "${minors[@]}")

    echo $free_minor
}



function is_valid_pci(){
    pci=$1
    num_of_match=$(lspci -s $pci 2> /dev/null | wc -l)

     if [[ $num_of_match -eq 1 ]]; then
        return 0
     else
        return 1
     fi
}

function get_numeric_id(){

    local dbdf=$1

    local numeric_id=$(lspci -s $dbdf -n | awk '{print $3}' | cut -d':' -f2)
    numeric_id=$((16#$numeric_id)) # Convert hexa to decimal
    echo $numeric_id
}

function get_fn(){
    local dbdf=$1
    local len=${#dbdf}
    echo ${dbdf:(len-1)}
}

function get_bdf(){
    local dbdf=$1
    echo ${dbdf:5}
}

function dec_to_hex(){

    _=$(which printf) # Check if "printf" exists

    if [ $? -ne 0 ]; then
        return 1
    fi

    printf '%x' $1
}


function get_device_name(){

    local numeric_id=$1
    local mst_module_type=$2
    local serial_num=$3
    local fn=$4


    mst_device=${mdir}/mt${numeric_id}_${mst_module_type}${serial_num}

    if [ $fn -ne 0 ];then
        mst_device=$mst_device.$fn
    fi

    echo $mst_device

}

function remove_device(){

    local mst_module_type=$1
    local numeric_id=$2
    local serial_num=$3
    local fn=$4

    mst_device=$(get_device_name $numeric_id $mst_module_type $serial_num $fn)

    if [ -c $mst_device ]; then
        mstop $mst_device
        rm -f $mst_device
    fi
}


function is_mst_device_exists(){
    dbdf=$1
    bdf=$(get_bdf $dbdf)

    local mst_dev=$(mdevices_info -v | grep $bdf -m1 | awk '{print $2}')

    if [ -n "$mst_dev" ] && [ $mst_dev != "NA" ]; then
        echo 1 # Exists
    else
        echo 0 # Not exists
    fi
}

###########

case "$1" in
    help)
        cat <<END

        MST (Mellanox Software Tools) service
        =====================================

   This script is used to start MST service, to stop it,
   and for some other operations with Mellanox devices
   like reset or enabling remote access.

   The mst commands are:
   -----------------------

   mst start ${MST_START_FLAGS}

       Create special files that represent Mellanox devices in
       directory ${mdir}. Load appropriate kernel modules and
       saves PCI configuration headers in temp-directory.
       After successfully completion of this command the MST driver
       is ready to work and you can invoke other Mellanox
       tools like Infiniburn or tdevmon.
       You can configure the start command by edit the configuration
       file: /etc/mft/mst.conf, for example you can rename you devices.

       Options:
       --$WITH_MSIX           : Create the msix device.
       --$WITH_UNKNOWN_ID        : Do not check if the device ID is supported.
       --$WITH_DEVI2C         : Create Embedded I2C primary

   mst stop [--$FORCE_STOP]

       Stop Mellanox MST driver service, remove all special files/directories
       and unload kernel modules.

        Options:
        --$FORCE_STOP : Force try to stop mst driver even if it's in use.

   mst restart ${MST_START_FLAGS}

       Just like "mst stop" followed by  "mst start ${MST_START_FLAGS}"

   mst server start <port> [-s <passphrase>]
       Start MST server to allow incoming connection.
       Default port is 23108
       Use '-s' flag to define the passphrase used by the server.
       If no passphrase is provided, a random one will be generated.


   mst server stop
       Stop MST server.

   mst remote add <hostname>[:port] [-s <passphrase>]
       Establish connection with specified host on specified port
       (default port is 23108). Add devices on remote peer to local
       devices list. <hostname> may be host name as well as an IP address.
       Use '-s' flag to provide the host's passphrase.
       If no passphrase is provided, you will be prompted to insert one.

   mst remote del <hostname>[:port]
       Remove all remote devices on specified hostname. <hostname>[:port] should
       be specified exactly as in the "mst remote add" command.

   mst ib add [OPTIONS] <local_hca_id> <local_hca_port>
       Add devices found in the IB fabric for inband access.
       Requires OFED installation and an active IB link.
           If local_hca_id and local_hca_port are given, the IB subnet connected
           to the given port is scanned. Otherwise, the default subnet is scanned.
       OPTIONS:
            ${g_discover_tool_opt} <discover-tool>: The tool that is used to discover the fabric.
                                             Supported tools: $g_ibnetdiscover, $g_ibdiagnet_tool. default: ${g_ibdiagnet_tool}
            ${g_add_non_mlnx} : Add non Mellanox nodes.
            ${g_topo_file_opt} <topology-file>: A prepared topology file which describes the fabric.
                         For $g_ibnetdiscover: provide an output of the tool.
                         For $g_ibdiagnet_tool: provide LST file that $g_ibdiagnet_tool generates.
            ${g_use_ibdr_opt}  : Access by direct route MADs. Available only when using ibnetdiscover tool, for 5th generation devices.
            NOTE: if a topology file is specified, device are taken from it.
                  Otherwise, a discover tool is run to discover the fabric.

   mst ib del
       Remove all inband devices.

   mst cable add [OPTIONS] [params]
       Add the cables that are connected to 5th gen devices.
       There is an option to add the cables found in the IB fabric for Cable Info access,
       requires OFED installation and active IB links.
            If local_hca_id and local_hca_port are given, the IB subnet connected
            to the given port is scanned. Otherwise, all the devices will be scanned.
        OPTIONS:
            ${g_with_ib}: Add the inband cables in addition to the local PCI devices.
                params: <local_hca_id> <local_hca_port>

   mst cable del
       Remove all cable devices.

   mst gearbox add 
       Add the gearbox devices, and gb manager (fpga), that are connected to host.

   mst gearbox del
       Remove all gearbox devices.
   
   mst jtag add 
       Add jtag devices that are connected to host.

   mst jtag del
       Remove all jtag devices.
  
   mst status

       Print current status of Mellanox devices

       Options:
       -v run with high verbosity level (print more info on each device)

   mst save

       Save PCI configuration headers in temp-directory.

   mst load

        Load PCI configuration headers from temp-directory.

   mst rm <pci-device>

        Remove the corresponding special file from /dev/mst directory.

   mst add <pci-device>

        Add the corresponding special file from /dev/mst directory.

   mst version

       Print the version info

END
        ;;
    save)
        if [ `id -u` -ne 0 ]; then
            echo "You must be root to do that"
            exit 1
        fi
        if [ $# -eq 2 ]
        then
        save_pci $2; RC=$?
        else
        save_pci; RC=$?
        fi
        if [ "$RC" != "0" ]; then
           RETVAL=1
        fi
        ;;
    load)
        if [ `id -u` -ne 0 ]; then
            echo "You must be root to do that"
            exit 1
        fi
        if [ $# -eq 2 ]
        then
        load_pci $2; RC=$?
        else
        load_pci; RC=$?
        fi
        if [ "$RC" != "0" ]; then
           RETVAL=1
        fi
        ;;
    reset)
        # We are expecting for device name
        if [ $# -lt 2 ]; then
            echo "Please specify device name"
            devcnt=0
            echo
            echo "Available devices are:"
            echo "----------------------"
            echo
            for dev in ${mdir}/*
            do
                if [ -r "$dev" ]; then
                    if ! expr "$dev" : '.*\(vtop\|ddr\|uar\)' > /dev/null 2>&1
                    then
                        cat $dev | head -n 1
                        devcnt=$((  $devcnt + 1 ))
                    fi
                fi
            done
            if [ ${devcnt} -eq 0 ]; then
                echo "    Sorry, no available devices found."
            fi
            exit 1
        fi

        # Check that we are root
        if [ `id -u` -ne 0 ]; then
            echo "You must be root to do that"
            exit 1
        fi
        if save_pci
        then
            if reset_pci $2
            then
                load_pci
            else
                echo "-E- Failed to reset the pci device $2"
                exit 1
            fi
        else
            echo "-E- Failed to save the pci configuration headres before resetting $2."
            RETVAL=1
        fi
        ;;
    server)
        # We are expecting subsommand here
        if [ $# -lt 2 ]; then
            echo "Please specify subcommand (start or stop)"
            exit 1
        fi
        case "$2" in
            start)
                serv_start $@
            ;;
            stop)
                if [ $# -gt 2 ]; then
                    echo "Unknown option/s: ${@:3}"
                    exit 1
                fi
                serv_stop
            ;;
            *)
                echo "Subcommand should be start or stop"
                RETVAL=1
            ;;
        esac
        ;;
    remote)
        # We are expecting command and host name
        if [ `id -u` -ne 0 ]; then
            echo "-E- You must be root to add/remove remote devices"
            exit 1
        fi

        if [ $# -lt 3 ]; then
            echo "Please specify subcommand (add or del) and remote host name or its IP address"
            exit 1
        fi

        case "$2" in
            add)
                radd $3 $4 $5
            ;;
            del)
                rdel $3
            ;;
            *)
                echo "Subcommand should be add or del"
                RETVAL=1
            ;;
        esac
        ;;
    ib)
        # We are expecting subsommand here
        if [ `id -u` -ne 0 ]; then
            echo "-E- You must be root to add/remove ib devices"
            exit 1
        fi
        if [ $# -lt 2 ]; then
            echo "Please specify subcommand (add or del)"
            exit 1
        fi
        case "$2" in
            add)
                shift 2
                ib_add $@
            ;;
            del)
                #rm -f $mdir/SW_* $mdir/CA_*
                ls $mdir/SW_* $mdir/CA_* 2> /dev/null | grep -v cable | xargs rm -f
            ;;
            *)
                echo "Subcommand should be add or del"
                RETVAL=1
            ;;
        esac
        ;;
    cable)
        # We are expecting command and host name
        if [ `id -u` -ne 0 ]; then
            echo "-E- You must be root to add/remove cable devices"
            exit 1
        fi

        if [ $# -lt 2 ]; then
            echo "Please specify subcommand (add or del)"
            exit 1
        fi

        case "$2" in
            add)
                shift 2
                cableadd $@
            ;;
            del)
                cabledel $3
            ;;
            *)
                echo "Subcommand should be add or del"
                RETVAL=1
            ;;
        esac
        ;;
    jtag)
        # We are expecting command and host name
        if [ `id -u` -ne 0 ]; then
            echo "-E- You must be root to add/remove jtag devices"
            exit 1
        fi

        if [ $# -lt 2 ]; then
            echo "Please specify subcommand (add or del)"
            exit 1
        fi

        case "$2" in
            add)
                shift 2
                jtagadd $@
            ;;
            del)
                jtagdel $3
            ;;
            *)
                echo "Subcommand should be add or del"
                RETVAL=1
            ;;
        esac
        ;;
    gearbox)
        # We are expecting command and host name
        if [ `id -u` -ne 0 ]; then
            echo "-E- You must be root to add/remove gearbox devices"
            exit 1
        fi

        if [ $# -lt 2 ]; then
            echo "Please specify subcommand (add or del)"
            exit 1
        fi

        case "$2" in
            add)
                shift 2
                gboxadd $@
            ;;
            del)
                gboxdel $3
            ;;
            *)
                echo "Subcommand should be add or del"
                RETVAL=1
            ;;
        esac
        ;;
    start)
        if [ `id -u` -ne 0 ]; then
            echo "You must be root to do that"
            exit 1
        fi
        check_start_args $2
        start $2 $3
        ;;
    stop)
        if [ `id -u` -ne 0 ]; then
            echo "You must be root to do that"
            exit 1
        fi
        stop $2
        rm -fr $pcidir
        ;;
    status)
            print_status $2
        ;;
    version)
        if [ -f $BASH_VERSION_LIB_PATH ]; then
            source $BASH_VERSION_LIB_PATH
            print_version_string mst
        else
            echo "N/A"
        fi
        ;;
    restart)
        if [ `id -u` -ne 0 ]; then
            echo "You must be root to do that"
            exit 1
        fi
        check_start_args $2
        stop
        start $2 $3
        ;;
     add)
        if [ `id -u` -ne 0 ]; then
            echo "You must be root to do that"
            exit 1
        fi

        pci=$2

        if [ -z $pci ]; then
            echo "Missing argument!"
            echo "Usage: mst add <pci-device>"
            exit 1
        fi


        lsmod | grep mst > /dev/null
        if [ $? -ne 0 ]; then
            echo "mst is not loaded! Please start mst and resume operation"
            exit 1
        fi

        is_valid_pci $pci
        if [ $? -ne 0 ]; then
            echo "pci \"$pci\" is not valid"
            exit 1
        fi

        dbdf=$(lspci -s $pci -D | awk '{print $1}')

        exists=$(is_mst_device_exists $dbdf)
        if [ $exists -eq 1 ]; then
            echo "mst device already exists"
            exit 1
        fi

        numeric_id=$(get_numeric_id $dbdf)
        fn=$(get_fn $dbdf)
        serial_num=$(get_serial_num $dbdf)

        # Create pciconf device
        ########################
        major=$(get_major "pciconf")
        minor=$(get_minor "pciconf" $major)
        create_pciconf_dev mt${numeric_id}_ $dbdf $serial_num $major $minor

        # Create pci_cr device
        ########################
        major=$(get_major "pci_cr")
        if [ -n "$major" ];then # create device only if module exist
            minor=$(get_minor "pci_cr" $major)
            pciconf_dev_name=$(get_device_name $numeric_id "pciconf" $serial_num $fn)
            numeric_id_hex=$(dec_to_hex $numeric_id)
            if [ $? -ne 0 ]; then
                echo "\"printf\" not found!"
                exit 1
            fi
            minit_args=$(get_pci_dev_args 0 $numeric_id_hex $pciconf_dev_name)

            _=$(create_pci_dev mt${numeric_id}_ $dbdf $serial_num $major $minor $minit_args)
        fi
        echo "mst device created"
        ;;
     rm)
        if [ `id -u` -ne 0 ]; then
            echo "You must be root to do that"
            exit 1
        fi

        pci=$2

        if [ -z $pci ]; then
            echo "Missing argument!"
            echo "Usage: mst rm <pci-device>"
            exit 1
        fi

        lsmod | grep mst > /dev/null
        if [ $? -ne 0 ]; then
            echo "mst is not loaded! Please start mst and resume operation"
            exit 1
        fi

        is_valid_pci $pci
        if [ $? -ne 0 ]; then
            echo "pci \"$pci\" is not valid"
            exit 1
        fi

        dbdf=$(lspci -s $pci -D | awk '{print $1}')
        exists=$(is_mst_device_exists $dbdf)
        if [ $exists -eq 0 ]; then
            echo "mst device doesn't exists"
            exit 1
        fi

        numeric_id=$(get_numeric_id $dbdf)
        fn=$(get_fn $dbdf)
        serial_num=$(get_serial_num $dbdf)           # The function will return all the "echo" from all the called functions

        remove_device "pciconf" $numeric_id $serial_num $fn
        remove_device "pci_cr" $numeric_id $serial_num $fn

        echo "mst device removed"

        ;;
    *)
        echo "Usage:"
        echo "    $0 {start|stop|status|remote|server|restart|save|load|rm|add|help|version|gearbox|cable}"
        echo
        echo "Type \"$0 help\" for detailed help"
        RETVAL=1
esac
exit $RETVAL
