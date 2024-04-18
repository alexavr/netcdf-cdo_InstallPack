#!/bin/bash
################################################################################
# NOTES
#
# Curl issue: curl fails to make check. 
#     Fix: (test172) https://github.com/curl/curl/commit/002d58f1
#     Fix: (test46)  https://github.com/curl/curl/commit/ffb8a21d
#     Both fixed here
# eccodes issue: needs lib64 for compilers (so the letest compilers) 
# proj issue: 
#     6.2.1 needs sqllite3: yum install libsqlite3x-devel
# jasper (new version) issue: fails at test stage. 
#     Fix: Fed up with this shit and installed the old version. Will deal with it later.
# Magic
#     4.2.0 needs: yum install boost-devel
################################################################################
# Usefull links:
#   https://software.intel.com/en-us/articles/performance-tools-for-software-developers-building-hdf5-with-intel-compilers
#   https://software.intel.com/en-us/articles/performance-tools-for-software-developers-building-netcdf-with-the-intel-compilers
################################################################################

# MODULES INSTALLED
  # 1) tbb/latest           3) debugger/latest      5) compiler/2021.4.0    7) mkl/2021.4.0
  # 2) compiler-rt/latest   4) dpl/latest           6) mpi/2021.4.0         8) null

source functions.sh

################################################################################
# USER'S BLOCK
# 1. Path to place the cdo folder and cdo version [CHANGE THIS]
CDOPATHFLODER="/home6/iocean4/opt/"
CDONAME="netcdf"
# 2. Filenames to install 
# The elements are placed in the installation order, so it is RELEVANT!!! 
TARLIST=(
  # "szip-2.1.1.tar.gz"
  # "zlib-1.2.8.tar.gz"           # WRF & WPS GRIB2  & CDO
  # "hdf5-1.10.5.tar.gz"          # WRF & WPS GRIB2  & CDO
  # "netcdf-c-4.7.2.tar.gz"       # WRF & WPS GRIB2  & CDO
  # "netcdf-fortran-4.5.2.tar.gz" # WRF & WPS GRIB2  & CDO
  "jasper-1.900.1.tar.gz"         # WPS GRIB2  & CDO
  "libpng-1.2.12.tar.gz"          # WPS GRIB2  & CDO
  # "curl-7.67.0.tar.gz"          # CDO
  # "proj-6.2.1.tar.gz"           # CDO
  # "udunits-2.2.26.tar.gz"       # CDO
  # "eccodes-2.14.1-Source.tar.gz"# CDO
  # "Magics-4.2.0-Source.tar.gz"  # CDO
  # "${CDONAME}.tar.gz"
)
################################################################################

################################################################################
# Set of enviroments
TMP=${TARLIST[-1]}
# CDONAME=${TMP%.tar.gz*}
export CDOPATH=$CDOPATHFLODER$CDONAME
export CC=icc # gcc #/usr/local/bin/gcc
export CXX=icpc # g++ #/usr/local/bin/g++
# export CPP="mpiicc -E"
# export CXXCPP='mpiicpc -E'   
export FC=ifort #/usr/local/bin/gfortran
export F77=ifort # /usr/local/bin/gfortran
export CFLAGS="-O3 -xHost -ip -fPIC" #"-fPIC"   #     # "-O3 -xHost -ip -fPIC"  -static-intel 
export FCFLAGS="-O3 -xHost -ip -fPIC"  #"-O3 -xHost -ip -no-prec-div -fPIC"    # "-O3 -xHost -ip -fPIC"  -static-intel 
# export CXXFLAGS="-fPIC" #"-O3 -xHost -ip -no-prec-div -fPIC"  # "-O3 -xHost -ip -fPIC" -static-intel 
export CPPFLAGS="-I$CDOPATH/include"
export LDFLAGS="-L$CDOPATH/lib"

if ! echo $LD_LIBRARY_PATH | grep "$CDOPATH/lib"; then
  export LD_LIBRARY_PATH="$CDOPATH/lib":$LD_LIBRARY_PATH
fi

bold=$(tput bold)
normal=$(tput sgr0)

# print some junk
print_envs

################################################################################
# Check if the folder exists and create
if [ ! -d "$CDOPATH" ]; then
  echo "    The folder $CDOPATH doesn't exist. Trying to create it..."
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
  tar -zxvf $i > untar.log

  cd $TARNAME
  echo "    Entering "$TARNAME

  # configure conditions
  echo "    Configuring and installing "$SOFTNAME"..."
  echo "    Check _configure.log, _make.log, _make_check.log, _make_install.log for more info."
  
  if [ "$SOFTNAME" == "zlib" ]; then
    # CCOLD=$CC
    # CFLAGSOLD=$CFLAGS
    # export CC=gcc
    # export CFLAGS=""
    execute "./configure --prefix=$CDOPATH --static &> _configure.log"
    execute "make &> _make.log "
    execute "make check &> _make_check.log"
    execute "make install &> _make_install.log"
    # export CC=$CCOLD
    # export CFLAGS=$CFLAGSOLD
  
  elif [ "$SOFTNAME" == "szip" ]; then
    CCOLD=$CC
    CFLAGSOLD=$CFLAGS
    export CC=gcc
    export CFLAGS=""
    execute "./configure --prefix=$CDOPATH >& _configure.log &> _configure.log"
    execute "make &> _make.log "
    execute "make check &> _make_check.log"
    execute "make install &> _make_install.log"
    export CC=$CCOLD
    export CFLAGS=$CFLAGSOLD
  
  elif [ "$SOFTNAME" == "hdf5" ]; then

    execute "./configure --prefix=$CDOPATH  \
                     --with-szlib=$CDOPATH  \
                     --with-zlib=$CDOPATH   \
                     --enable-fortran    \
                     &> _configure.log"
                     # --with-pic --with-pthread --disable-sharedlib-rpath --enable-production --disable-cxx  \
                     # --enable-parallel      \
                     # --enable-shared --enable-static \
                     # --enable-fortran       \
                     # --disable-hl \
                     # --enable-cxx           \
                     # --enable-shared        \
                     # --enable-unsupported 
    execute "make &> _make.log "
    execute "make check &> _make_check.log"
    execute "make install &> _make_install.log"
  
  elif [ "$SOFTNAME" == "netcdf-c" ]; then

    execute "./configure --prefix=$CDOPATH  \
                     --enable-netcdf-4      \
                     --with-pic             \
                     --disable-dap          \
                     &> _configure.log"
                     # --enable-dynamic-loading      \
    execute "make &> _make.log "
    execute "make check &> _make_check.log"
    execute "make install &> _make_install.log"
  
  elif [ "$SOFTNAME" == "netcdf-fortran" ]; then

    execute "./configure --prefix=$CDOPATH >& _configure.log"
    execute "make &> _make.log "
    execute "make check &> _make_check.log"
    execute "make install &> _make_install.log"

  
  elif [ "$SOFTNAME" == "curl" ]; then

    execute "./configure --prefix=$CDOPATH --with-zlib=$CDOPATH >& _configure.log"
    execute "make -j 8 &> _make.log "
    # fixing the bugs
    sed -i -e 's/1391252187/2139150993/g' tests/data/test172
    sed -i -e 's/1439150993/1739150993/g' tests/data/test46
    execute "make -j 8 check &> _make_check.log"
    execute "make install &> _make_install.log"

  elif [ "$SOFTNAME" == "proj" ]; then

    export LDFLAGS="-Wl,--copy-dt-needed-entries"
    unzip ../proj-datumgrid-1.8.zip -d nad/ >& _unsip_datumgrid.log
    execute "./configure --prefix=$CDOPATH --with-pic --without-mutex --without-jni >& _configure.log"
    execute "make -j 8 &> _make.log "
    execute "make -j 8 check &> _make_check.log"
    execute "make install &> _make_install.log"

  elif [ "$SOFTNAME" == "udunits" ]; then
    execute "./configure --prefix=$CDOPATH --with-pic >& _configure.log"
    execute "make &> _make.log "
    execute "make check &> _make_check.log"
    execute "make install &> _make_install.log"
  
  elif [ "$SOFTNAME" == "jasper" ]; then
    # OLD (1.N versions)
    execute "./configure --prefix=$CDOPATH --with-pic >& _configure.log"
    execute "make &> _make.log "
    execute "make check &> _make_check.log"
    execute "make install &> _make_install.log"

  elif [ "$SOFTNAME" == "libpng" ]; then
    # OLD (1.N versions)
    execute "./configure --prefix=$CDOPATH --with-pic >& _configure.log"
    execute "make &> _make.log "
    execute "make check &> _make_check.log"
    execute "make install &> _make_install.log"

    # # NEW VERSIONS
    # mkdir ../jasper_build
    # cd ../jasper_build
    # execute "cmake   \
    #               -DCMAKE_INSTALL_PREFIX=$CDOPATH      \
    #               >& _configure.log"
    # execute "make clean all &> _make.log "
    # execute "make test &> _make_check.log"
    # execute "make install &> _make_install.log"

    # export CFLAGS=$CFLAGS_SAVE
  
  elif [ "$SOFTNAME" == "eccodes" ]; then

    if [ -d "../eccodes_build" ]; then rm -rf ../eccodes_build; fi
    export  LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib64/
    mkdir ../eccodes_build
    cd ../eccodes_build
    echo "    Look for logs (_*.log) in eccodes_build dir!"
    execute "cmake3 -DCMAKE_INSTALL_PREFIX=$CDOPATH ../$TARNAME \
                   -DENABLE_ECCODES_THREADS=ON        \
                    >& _configure.log"
                   # -DCMAKE_C_FLAGS='-fPIC'        \
                   # -DNETCDF_PATH=$CDOPATH         \
                   # -DCMAKE_C_COMPILER="gcc"             \
                   # -DCMAKE_Fortran_COMPILER="gfortran"  \
                   # -DCMAKE_Fortran_FLAGS="-fPIC"        \
                   # -DBUILD_SHARED_LIBS=BOTH       \
                   # -DENABLE_JPG=ON          \
    execute "make -j 8 &> _make.log "
    execute "make -j 8 check &> _make_check.log"
    execute "make install &> _make_install.log"
  
  elif [ "$SOFTNAME" == "Magics" ]; then  # NOT FINISHED!!!!
    if [ -d "../Magics_build" ]; then rm -rf ../Magics_build; fi
    mkdir ../Magics_build
    cd ../Magics_build
    execute "cmake3 -DCMAKE_INSTALL_PREFIX=$CDOPATH ../$TARNAME \
                    -DECBUILD_LOG_LEVEL=DEBUG \
                    -DENABLE_PYTHON=no \
                    -DENABLE_FORTRAN=no \
                    >& _configure.log"
                    # -DACCEPT_USE_OF_DEPRECATED_PROJ_API_H=1 \
                     # -DCMAKE_Fortran_FLAGS='$FCFLAGS'         \
                     # -DCMAKE_CXX_FLAGS='-O2 -mtune=native' \
                     # -DCMAKE_C_FLAGS='$CFLAGS'                 \
    execute "make &> _make.log "
    # execute "make -j 8 check &> _make_check.log"
    execute "ctest &> _make_check.log"
    execute "make install &> _make_install.log"
  
  elif [ "$SOFTNAME" == "cdo" ]; then
    
    # if [ ${#TARLIST[@]} -lt 5 ]; then
    #   echo " "
    #   echo "--> Not enough soft to compile cdo. Skipping..."
    #   exit 0
    # fi
    # export  LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/local/lib64/
    execute "./configure --prefix=$CDOPATH      \
                     --with-netcdf=$CDOPATH     \
                     --with-szlib=$CDOPATH      \
                     --with-hdf5=$CDOPATH       \
                     --with-eccodes=$CDOPATH    \
                     --with-proj=$CDOPATH       \
                     --with-curl=$CDOPATH       \
                     --with-jasper=$CDOPATH     \
                     --with-udunits2=$CDOPATH   \
                     --with-magics=$CDOPATH     \
                     &> _configure.log"
                     # --disable-python \
                     # --with-grib_api=$CDOPATH  \
                     # --disable-fortran         \
                     # --enable-swig          \
                     # --with-pic                 \
                     # --disable-numpy            \
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
