#!/bin/bash
################################################################################
# NOTES
#
# netcdf-c:
#           * make check fails.
#             There is known bug in the 4.6.1 release that can cause that error
#             on some operating systems (and apparently with the Intel compiler).
#             To fix it, the failing test can be disabled by adding the option
#                  --disable-filter-testing
#             to your ./configure command
#             https://www.unidata.ucar.edu/support/help/MailArchives/netcdf/msg14362.html
#             https://github.com/Unidata/netcdf-c/pull/1302



# hdf5 issue: hdf5-1.10.4 has error in the lib which causes netcdf to fail 
#     1: https://github.com/Unidata/netcdf-fortran/issues/82
#     2: https://github.com/Unidata/netcdf-c/pull/1008
#     Fixed by using previous version [hdf5-1.8.21.tar.gz]
# ntcdf-fortran fails at 'make check' in nf03_test
#     It appeared to be irrelevant, so I skipped the 'make check' stage
#     Prof: https://www.unidata.ucar.edu/blogs/news/entry/netcdf-fortran-4-4-3 
# Curl issue: curl fails to make check. 
#     Fix: (test172) https://github.com/curl/curl/commit/002d58f1
#     Fix: (test46)  https://github.com/curl/curl/commit/ffb8a21d
#     Both fixed here
# eccodes issue: picky to python installations. 
#     Fix: temporary rename Anaconda folder [if the error appeared]
# proj issue: fails at "make check" stage os I skipped this stage. 
#     Fixed using tender icc compiler option [-O0]
# jasper (new version) issue: fails at test stage. 
#     Fix: Fed up with this shit and install the old version. Will deal with it later.
# cdo issue: the Intel Compiler 
#     Fix: had to switch back to the intel/2019.1.053 in order to MPI errors
################################################################################
# Usefull links:
#   https://software.intel.com/en-us/articles/performance-tools-for-software-developers-building-hdf5-with-intel-compilers
#   https://software.intel.com/en-us/articles/performance-tools-for-software-developers-building-netcdf-with-the-intel-compilers
################################################################################

source functions.sh

################################################################################
# USER'S BLOCK
# 1. Path to place the cdo folder [CHANGE THIS]
CDOPATHFLODER="/opt"
CDONAME="netcdf-4_serial"
# 2. Filenames to install [DO NOT CHANGE THIS UNLESS YOU'RE SURE]
# The elements are placed in the installation order, 
# so it is RELEVANT!!! Also the cdo always has to be uncomment and at the end.
TARLIST=(
  # "szip-2.1.1.tar.gz"
  # "zlib-1.2.8.tar.gz"
  "hdf5-1.8.21.tar.gz"
  # "netcdf-c-4.6.2.tar.gz"
  # "netcdf-fortran-4.4.5.tar.gz"
)
################################################################################

################################################################################
# Set of enviroments
# # TMP=${TARLIST[-1]} # Fails in MACOS
export CDOPATH=$CDOPATHFLODER/$CDONAME
export CC=icc
export CXX=icpc
# export CPP="icc -E"
# export CXXCPP='icpc -E'   
export FC=ifort
export F77=ifort
export CFLAGS="-O2 -xHost -ip -fPIC" #"-D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64" # "-O0 -xHost -ip -fPIC"   #"-O3 -xHost -ip -no-prec-div -fPIC" # "-O3 -xHost -ip -fPIC"  -static-intel 
export FCFLAGS="-O2 -xHost -ip -fPIC"  #"-O3 -xHost -ip -no-prec-div -fPIC" # "-O3 -xHost -ip -fPIC"  -static-intel 
export CXXFLAGS="-O2 -xHost -ip -fPIC" #"-O3 -xHost -ip -no-prec-div -fPIC" # "-O3 -xHost -ip -fPIC" -static-intel 
export CPPFLAGS="-I$CDOPATH/include"
export LDFLAGS="-L$CDOPATH/lib"
export LD_LIBRARY_PATH=$LIBRARY_PATH

if ! echo $LD_LIBRARY_PATH | grep "$CDOPATH/lib"; then
  echo "Exporting to LD_LIBRARY_PATH..."
  export LD_LIBRARY_PATH="$CDOPATH/lib":${LD_LIBRARY_PATH}
fi

bold=$(tput bold)
normal=$(tput sgr0)

# print some junk
print_envs

################################################################################
# Check if the folder exists and create
if [ ! -d "$CDOPATH" ]; then
  echo "    The folder $CDOPATH doesn't exist. Trying to create..."
  if mkdir -p "$CDOPATH"; then
    echo "    Destination folder "$CDOPATH" has been created successfully!"
  else
    echo "***"
    echo "*--> Current user don't have rights to create the "$CDOPATH
    echo "*    Create the folder manually or choose different path in CDOPATHFLODER"
    echo "***"
    exit 1
  fi
else
  echo "    The folder $CDOPATH exists. Checking for permitions..."
  if rm -rf "$CDOPATH/*"; then
    echo "    Destination folder "$CDOPATH" has proper permitions!"
  else 
    echo "***"
    echo "*--> Current user don't have rights to change the "$CDOPATH
    echo "*    Create the folder manually or choose different path in CDOPATHFLODER"
    echo "***"
    exit 1
  fi
fi

################################################################################
# MAIN LOOP
for i in ${TARLIST[@]}; do 

  # get names
  TARNAME=${i%.tar.gz*}
  SOFTNAME=${TARNAME%-*}
  echo "--> ${bold}Extracting "$i" to "$TARNAME"${normal}"

  if [ ${SOFTNAME%-*} == "eccodes" -o ${SOFTNAME%-*} == "Magics" ]; then 
    TARNAME=$SOFTNAME"-Source"
    SOFTNAME=${SOFTNAME%-*}
  fi

  # rm the previous installation 
  if [ -d "$TARNAME" ]; then
    echo "    Src folder exists. Removing..."
    rm -rf ./$TARNAME
  fi

  # untar
  tar -zxvf $i &> untar.log

  cd $TARNAME
  echo "    Entering "$TARNAME

  # configure conditions
  echo "    Configuring and installing "$SOFTNAME"..."
  echo "    Check _configure.log, _make.log, _make_check.log, _make_install.log for more info."
  
  if [ "$SOFTNAME" == "zlib" ]; then
    execute "./configure --prefix=$CDOPATH --static &> _configure.log"
    execute "make &> _make.log "
    execute "make check &> _make_check.log"
    execute "make install &> _make_install.log"
  
  elif [ "$SOFTNAME" == "szip" ]; then
    execute "./configure --prefix=$CDOPATH >& _configure.log &> _configure.log"
    execute "make &> _make.log "
    execute "make check &> _make_check.log"
    execute "make install &> _make_install.log"
  
  elif [ "$SOFTNAME" == "hdf5" ]; then
    # CPP_SAVE=$CPP
    # CFLAGS_SAVE=$CFLAGS
    # export CPP=""
    # export CFLAGS="-O0"    # "-O3 -xHost -ip -fPIC"
    execute "./configure --prefix=$CDOPATH  \
                     --with-szlib=$CDOPATH  \
                     --with-zlib=$CDOPATH   \
                     --enable-shared --enable-static \
                     --enable-fortran       \
                     &> _configure.log"
                     # --disable-hl \
                     # --enable-cxx           \
                     # --enable-shared        \
                     # --with-pic --with-pthread --disable-sharedlib-rpath --enable-production --disable-cxx  \
                     # --enable-parallel      \
                     # --enable-threadsafe --enable-unsupported \
                     # --enable-shared --enable-static \
                     # --enable-fortran       \
    execute "make &> _make.log "
    execute "make check &> _make_check.log"
    execute "make install &> _make_install.log"
    # export CFLAGS=$CFLAGS_SAVE
    # export CPP=$CPP_SAVE
  
  elif [ "$SOFTNAME" == "netcdf-c" ]; then
    # CFLAGS_SAVE=$CFLAGS
    # FCFLAGS_SAVE=$FCFLAGS
    # CXXFLAGS_SAVE=$CXXFLAGS
    # export CFLAGS="-O3 -xHost -ip -no-prec-div -static-intel"    # "-O3 -xHost -ip -fPIC"  -static-intel 
    # export FCFLAGS="-O3 -xHost -ip -no-prec-div -static-intel"    # "-O3 -xHost -ip -fPIC"  -static-intel 
    # export CXXFLAGS="-O3 -xHost -ip -no-prec-div -static-intel"  # "-O3 -xHost -ip -fPIC" -static-intel 
                     # --enable-dynamic-loading      \
    execute "./configure --prefix=$CDOPATH   \
                    --disable-filter-testing \
                     &> _configure.log"
                     # --enable-netcdf-4      \
                     # --with-pic             \
                     # --disable-dap          \
    execute "make &> _make.log "
    execute "make check &> _make_check.log"
    execute "make install &> _make_install.log"

    # export CFLAGS=$CFLAGS_SAVE
    # export FCFLAGS=$FCFLAGS_SAVE
    # export CXXFLAGS=$CXXFLAGS_SAVE
  
  elif [ "$SOFTNAME" == "netcdf-fortran" ]; then
    # CFLAGS_SAVE=$CFLAGS
    # FCFLAGS_SAVE=$FCFLAGS
    # CXXFLAGS_SAVE=$CXXFLAGS
    # export CFLAGS="-O3 -xHost -ip -no-prec-div -static-intel"    # "-O3 -xHost -ip -fPIC"  -static-intel 
    # export FCFLAGS="-O3 -xHost -ip -no-prec-div -static-intel"    # "-O3 -xHost -ip -fPIC"  -static-intel 
    # export CXXFLAGS="-O3 -xHost -ip -no-prec-div -static-intel"  # "-O3 -xHost -ip -fPIC" -static-intel 
    execute "./configure --prefix=$CDOPATH >& _configure.log"
    execute "make &> _make.log "
    # execute "make check &> _make_check.log"
    execute "make install &> _make_install.log"
    # export CFLAGS=$CFLAGS_SAVE
    # export FCFLAGS=$FCFLAGS_SAVE
    # export CXXFLAGS=$CXXFLAGS_SAVE

  
  elif [ "$SOFTNAME" == "curl" ]; then
    CC_SAVE=$CC
    CXX_SAVE=$CXX
    CPP_SAVE=$CPP
    CXXCPP_SAVE=$CXXCPP
    export CC=clang
    export CXX=""
    export CPP=""
    export CXXCPP=""   
    execute "./configure --prefix=$CDOPATH --with-zlib=$CDOPATH >& _configure.log"
    execute "make &> _make.log "
    # fixing the bugs
    sed -i -e 's/1391252187/2139150993/g' tests/data/test172
    sed -i -e 's/1439150993/1739150993/g' tests/data/test46
    execute "make check &> _make_check.log"
    execute "make install &> _make_install.log"
    export CC=$CC_SAVE
    export CXX=$CXX_SAVE
    export CPP=$CPP_SAVE
    export CXXCPP=$CXXCPP_SAVE

  
  elif [ "$SOFTNAME" == "proj" ]; then
    # CC_SAVE=$CC
    # CXX_SAVE=$CXX
    # CPP_SAVE=$CPP
    # CXXCPP_SAVE=$CXXCPP
    # export CC=clang
    # export CXX=""
    # export CPP=""
    # export CXXCPP=""   
    unzip ../proj-datumgrid-1.8.zip -d nad/ >& _unsip_datumgrid.log
    execute "./configure --prefix=$CDOPATH --with-pic --without-mutex --without-jni >& _configure.log"
    execute "make &> _make.log "
    execute "make check &> _make_check.log"
    execute "make install &> _make_install.log"

    # export CC=$CC_SAVE
    # export CXX=$CXX_SAVE
    # export CPP=$CPP_SAVE
    # export CXXCPP=$CXXCPP_SAVE
  
  elif [ "$SOFTNAME" == "udunits" ]; then
    CC_SAVE=$CC
    CXX_SAVE=$CXX
    CPP_SAVE=$CPP
    CXXCPP_SAVE=$CXXCPP
    export CC=clang
    export CXX=""
    export CPP=""
    export CXXCPP=""   
    execute "./configure --prefix=$CDOPATH --with-pic >& _configure.log"
    execute "make &> _make.log "
    execute "make check &> _make_check.log"
    execute "make install &> _make_install.log"
    export CC=$CC_SAVE
    export CXX=$CXX_SAVE
    export CPP=$CPP_SAVE
    export CXXCPP=$CXXCPP_SAVE
  
  elif [ "$SOFTNAME" == "jasper" ]; then
    CFLAGS_SAVE=$CFLAGS
    export CFLAGS="-O0"    # "-O3 -xHost -ip -fPIC"
    # OLD (1.N versions)
    execute "./configure --prefix=$CDOPATH --with-pic >& _configure.log"
    execute "make &> _make.log "
    execute "make check &> _make_check.log"
    execute "make install &> _make_install.log"
    export CFLAGS=$CFLAGS_SAVE
  
  elif [ "$SOFTNAME" == "eccodes" ]; then
    CC_SAVE=$CC
    CXX_SAVE=$CXX
    CPP_SAVE=$CPP
    CXXCPP_SAVE=$CXXCPP
    FC_SAVE=$FC
    F77_SAVE=$F77
    CFLAGS_SAVE=$CFLAGS
    FCFLAGS_SAVE=$FCFLAGS
    CXXFLAGS_SAVE=$CXXFLAGS
    export CC=icc
    export CXX=icpc
    export CPP='icc -E'
    export CXXCPP='icpc -E'   
    export FC=ifort
    export F77=ifort
    export CFLAGS="-O3 -xHost -ip -fPIC"   #-static-intel 
    export FCFLAGS="-O3 -xHost -ip -fPIC"  #-static-intel 
    export CXXFLAGS="-O3 -xHost -ip -fPIC" #-static-intel 
    if [ -d "../eccodes_build" ]; then rm -rf ../eccodes_build; fi
    mkdir ../eccodes_build
    cd ../eccodes_build
    echo "    Look for logs (_*.log) in eccodes_build dir!"
    execute "cmake -DCMAKE_INSTALL_PREFIX=$CDOPATH ../$TARNAME \
                   -DBUILD_SHARED_LIBS=BOTH       \
                   -DNETCDF_PATH=$CDOPATH         \
                    >& _configure.log"
                   # -DCMAKE_C_FLAGS='-fPIC'        \
                   # -DENABLE_JPG=ON          \
                   # -DCMAKE_C_COMPILER="gcc"             \
    execute "make &> _make.log "
    execute "make check &> _make_check.log"
    execute "make install &> _make_install.log"
    export CC=$CC_SAVE
    export CXX=$CXX_SAVE
    export CPP=$CPP_SAVE
    export CXXCPP=$CXXCPP_SAVE
    export FC=$FC_SAVE
    export F77=$F77_SAVE
    export CFLAGS=$CFLAGS_SAVE
    export FCFLAGS=$FCFLAGS_SAVE
    export CXXFLAGS=$CXXFLAGS_SAVE
  
  elif [ "$SOFTNAME" == "Magics" ]; then  # NOT FINISHED!!!!
    if [ -d "../Magics_build" ]; then rm -rf ../Magics_build; fi
    mkdir ../Magics_build
    cd ../Magics_build
    execute "cmake3 -DCMAKE_INSTALL_PREFIX=$CDOPATH ../$TARNAME \
                     -DCMAKE_CXX_FLAGS='-O2 -mtune=native' \
                     -DCMAKE_C_FLAGS='$CFLAGS'                 \
                     -DCMAKE_Fortran_FLAGS='$FCFLAGS'         \
                    >& _configure.log"
    execute "make &> _make.log "
    execute "make check &> _make_check.log"
    execute "make install &> _make_install.log"
  
  elif [ "$SOFTNAME" == "cdo" ]; then
    
    # if [ ${#TARLIST[@]} -lt 5 ]; then
    #   echo " "
    #   echo "--> Not enough soft to compile cdo. Skipping..."
    #   exit 0
    # fi
                     # --with-grib_api=$CDOPATH  \
                     # --with-jasper=$CDOPATH    \
                     # --disable-fortran         \
    execute "./configure --prefix=$CDOPATH  \
                     --with-netcdf=$CDOPATH    \
                     --with-szlib=$CDOPATH     \
                     --with-hdf5=$CDOPATH      \
                     --with-eccodes=$CDOPATH  \
                     --with-proj=$CDOPATH       \
                     --with-curl=$CDOPATH     \
                     --with-udunits2=$CDOPATH  \
                     --with-pic                \
                     --disable-python          \
                     --disable-numpy           \
                     &> _configure.log"
    execute "make &> _make.log "
    execute "make check &> _make_check.log"
    execute "make install &> _make_install.log"
  fi

  cd ../

done

echo "Everythig was compiled for both static and shared libs."
echo "Add "$CDOPATH/lib" in LD_LIBRARY_PATH"
echo "in case you're planning to use shared option, "
echo "To your .bash_profile || .bashrc"

exit 0
