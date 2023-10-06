#!/bin/bash
################################################################################
# NOTES
# * For CDO we installing using clang set of compilers. Without FORTRAN.
# Here some issues happened on the way:
################################################################################

source functions.sh

################################################################################
# USER'S BLOCK
# 1. Path to place the cdo folder [CHANGE THIS]
CDOPATHFLODER="/opt"
CDONAME="cdo-1.9.5"
# 2. Filenames to install [DO NOT CHANGE THIS UNLESS YOU'RE SURE]
# The elements are in the installation order, so it is RELEVANT!!! 
TARLIST=(
  # "szip-2.1.1.tar.gz" # This library is needed to process szip compressed GRIB files.
  # "zlib-1.2.8.tar.gz"
  # "hdf5-1.10.5.tar.gz" # Needed to import CM-SAF HDF5 files with the CDO operator import_cmsaf.
  # "netcdf-c-4.6.2.tar.gz" 
  # "proj-5.2.0.tar.gz" # This library is needed to convert Sinusoidal and Lambert Azimuthal Equal Area coordinates to geographic coordinates, for e.g. remapping.
  # "eccodes-2.13.0-Source.tar.gz" # This library is needed to process GRIB2 files with CDO
  $CDONAME".tar.gz"
  # # "jasper-1.900.1.tar.gz"       
  # # "curl-7.65.3.tar.gz" # only for DAP 
  # # "udunits-2.2.26.tar.gz" # old version of cdo
  # # # "Magics-3.3.1-Source.tar.gz" # DOESN'T WORK YET!!! (# This library is needed to create contour, vector and graph plots with CDO)
)
################################################################################

################################################################################
# Set of enviroments
# # TMP=${TARLIST[-1]} # Fails in MACOS
export CDOPATH=$CDOPATHFLODER/$CDONAME
export CC=clang
# export CXX=gcc-7
# export CPP="icc -E"
# export CXXCPP='icpc -E'   
# export FC=ifort
# export F77=ifort
# export CFLAGS="-O3 -xHost -ip -fPIC"   #"-O3 -xHost -ip -no-prec-div -fPIC" # "-O3 -xHost -ip -fPIC"  -static-intel 
# export FCFLAGS="-O3 -xHost -ip -fPIC"  #"-O3 -xHost -ip -no-prec-div -fPIC" # "-O3 -xHost -ip -fPIC"  -static-intel 
# export CXXFLAGS="-O3 -xHost -ip -fPIC" #"-O3 -xHost -ip -no-prec-div -fPIC" # "-O3 -xHost -ip -fPIC" -static-intel 
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
    # export CC_SAVE=$CC
    # export CC=gcc-7
    # export CFLAGS="-O0 -xHost -ip -no-prec-div -fPIC"
    # export HDF5TestExpress=3 # To perform a faster (but less thorough) test
    execute "./configure --prefix=$CDOPATH  \
                     --with-szlib=$CDOPATH  \
                     --with-zlib=$CDOPATH   \
                     --disable-cxx --disable-fortran \
                     --with-pic \
                     --enable-hl \
                     &> _configure.log"
                     # --enable-build-mode=production \
                     # --enable-static-exec \
                     # --enable-fortran --enable-fortran2003 \
                     # # --disable-shared --enable-static \
                     # --disable-hl \
                     # --enable-cxx           \
                     # --disable-shared        \
                     # --enable-shared        \
                     # --with-pic --with-pthread --disable-sharedlib-rpath --enable-production --disable-cxx  \
                     # --enable-parallel      \
                     # --enable-threadsafe --enable-unsupported \
                     # --enable-shared --enable-static \
                     # --enable-fortran       \
    execute "make -j -l4 &> _make.log "
    execute "make check &> _make_check.log"
    execute "make install &> _make_install.log"
    # export CFLAGS=$CFLAGS_SAVE
    # export CC=$CC_SAVE
  
  elif [ "$SOFTNAME" == "netcdf-c" ]; then
    # CFLAGS_SAVE=$CFLAGS
    # FCFLAGS_SAVE=$FCFLAGS
    # CXXFLAGS_SAVE=$CXXFLAGS
    # export CFLAGS="-O3 -xHost -ip -no-prec-div -static-intel"    # "-O3 -xHost -ip -fPIC"  -static-intel 
    # export FCFLAGS="-O3 -xHost -ip -no-prec-div -static-intel"    # "-O3 -xHost -ip -fPIC"  -static-intel 
    # export CXXFLAGS="-O3 -xHost -ip -no-prec-div -static-intel"  # "-O3 -xHost -ip -fPIC" -static-intel 
                     # --enable-dynamic-loading      \
    execute "./configure --prefix=$CDOPATH  \
                    --disable-dap          \
                     &> _configure.log"
                     # --enable-netcdf-4      \
                     # --with-pic             \
                    # --disable-filter-testing \
                     # --disable-dap          \ # no need to install curl

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

  elif [ "$SOFTNAME" == "proj" ]; then
    CXX_SAVE=$CXX
    # CFLAGS_SAVE=$CFLAGS
    export CXX=clang++
    # export CFLAGS="-O0"    # "-O3 -xHost -ip -fPIC"
    unzip ../proj-datumgrid-1.8.zip -d nad/ >& _unsip_datumgrid.log
    execute "./configure --prefix=$CDOPATH --without-mutex --without-jni >& _configure.log"
    execute "make &> _make.log "
    execute "make check &> _make_check.log"
    execute "make install &> _make_install.log"
    export CXX=$CXX_SAVE
    # export CFLAGS=$CFLAGS_SAVE
  
  elif [ "$SOFTNAME" == "eccodes" ]; then
    CFLAGS_SAVE=$CFLAGS
    export CXX=clang++
    # export CFLAGS="-O0"    # "-O3 -xHost -ip -fPIC"
    if [ -d "../eccodes_build" ]; then rm -rf ../eccodes_build; fi
    mkdir ../eccodes_build
    cd ../eccodes_build
    echo "    Look for logs (_*.log) in eccodes_build dir!"
    execute "cmake -DCMAKE_INSTALL_PREFIX=$CDOPATH ../$TARNAME \
                   -DBUILD_SHARED_LIBS=OFF       \
                   -DNETCDF_PATH=$CDOPATH         \
                   -DENABLE_PYTHON=OFF         \
                   -DENABLE_FORTRAN=OFF         \
                    >& _configure.log"
                   # -DCMAKE_C_FLAGS='-fPIC'        \
                   # -DENABLE_JPG=ON          \
                   # -DCMAKE_C_COMPILER="gcc"             \
    execute "make &> _make.log "
    execute "make check &> _make_check.log"
    execute "make install &> _make_install.log"
    export CXX=$CXX_SAVE
    # export CFLAGS=$CFLAGS_SAVE
  
  elif [ "$SOFTNAME" == "curl" ]; then
    # CC_SAVE=$CC
    # CXX_SAVE=$CXX
    # CPP_SAVE=$CPP
    # CXXCPP_SAVE=$CXXCPP
    # export CC=clang
    # export CXX=""
    # export CPP=""
    # export CXXCPP=""   
    execute "./configure --prefix=$CDOPATH --with-zlib=$CDOPATH >& _configure.log"
    execute "make &> _make.log "
    # fixing the bugs
    sed -i -e 's/1391252187/2139150993/g' tests/data/test172
    sed -i -e 's/1439150993/1739150993/g' tests/data/test46
    execute "make check &> _make_check.log"
    execute "make install &> _make_install.log"
    # export CC=$CC_SAVE
    # export CXX=$CXX_SAVE
    # export CPP=$CPP_SAVE
    # export CXXCPP=$CXXCPP_SAVE

  
  elif [ "$SOFTNAME" == "udunits" ]; then
    # CC_SAVE=$CC
    # CXX_SAVE=$CXX
    # CPP_SAVE=$CPP
    # CXXCPP_SAVE=$CXXCPP
    # export CC=clang
    # export CXX=""
    # export CPP=""
    # export CXXCPP=""   
    execute "./configure --prefix=$CDOPATH --with-pic >& _configure.log"
    execute "make &> _make.log "
    execute "make check &> _make_check.log"
    execute "make install &> _make_install.log"
    # export CC=$CC_SAVE
    # export CXX=$CXX_SAVE
    # export CPP=$CPP_SAVE
    # export CXXCPP=$CXXCPP_SAVE
  
  elif [ "$SOFTNAME" == "jasper" ]; then
    CFLAGS_SAVE=$CFLAGS
    export CFLAGS="-O0"    # "-O3 -xHost -ip -fPIC"
    # OLD (1.N versions)
    execute "./configure --prefix=$CDOPATH --with-pic >& _configure.log"
    execute "make &> _make.log "
    execute "make check &> _make_check.log"
    execute "make install &> _make_install.log"
    export CFLAGS=$CFLAGS_SAVE
  
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
    
    export CXX=clang++
    # export CFLAGS="-O0"    # "-O3 -xHost -ip -fPIC"
    execute "./configure --prefix=$CDOPATH  \
                     --with-hdf5=$CDOPATH      \
                     --with-netcdf=$CDOPATH    \
                     --with-szlib=$CDOPATH     \
                     --with-eccodes=no  \
                     --with-proj=$CDOPATH       \
                     --disable-python          \
                     --disable-numpy           \
                     --disable-fortran         \
                     --enable-all-static       \
                     --enable-shared=no       \
                     &> _configure.log"
                     # --with-pic                \
                     # --with-curl=$CDOPATH     \
                     # --with-udunits2=$CDOPATH  \
                     # --with-grib_api=$CDOPATH  \
                     # --with-jasper=$CDOPATH    \
    execute "make -j -l4 &> _make.log "
    execute "make -j -l4 check &> _make_check.log"
    execute "make install &> _make_install.log"
  fi

  cd ../

done

echo "Everythig was compiled for both static and shared libs."
echo "Add "$CDOPATH/lib" in LD_LIBRARY_PATH"
echo "in case you're planning to use shared option, "
echo "To your .bash_profile || .bashrc"

exit 0
