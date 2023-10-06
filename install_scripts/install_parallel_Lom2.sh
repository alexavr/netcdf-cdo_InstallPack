#!/bin/bash
################################################################################
# DESCRIPTION
# The script untar, compile and install cdo (with additioal packages). 
# Additional libs have been chosen according to:
# https://code.mpimet.mpg.de/projects/cdo/embedded/index.html
#        (plus jasper, curl -- wasn't sure if thay deprecated or not)
# 
# User should point the installation path in CDOPATH. It is all.
# User should write permitions in order to create or modify (if exists) CDOPATH. 
# 
# No need to untar anything. 
# It's possible to install libs separately by commenting elements 
# in the TARLIST array, but be aware as it's represents the installation order!
# 
# It's possible to download new versions, just make sure
# 1. You changed the tar name in TARLIST
# 2. Src is always has to be tar.gz [otherwise you will have to make major changes here]
# 3. Bug of new version are on your responsibility :)
#  
################################################################################
# CURRENT INSTALLATION NOTES 
# Currently Loaded Modules:
#  1) xalt/0.5.0   2) intel/15.0.3   3) openmpi/2.1.1-icc
# 
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
# proj and jasper: have issues with -O3 
#     Fixed using tender icc compiler option [-O0]
# eccodes issue: picky to python installations. 
#     Fix: If error appeared: temporary rename Anaconda folder
# jasper (new version) issue: fails at test stage. 
#     Fix: Fed up with this shit and install the old version. Will deal with it later.
################################################################################
# Usefull links:
#   https://www.unidata.ucar.edu/software/netcdf/docs/building_netcdf_fortran.html
#   https://software.intel.com/en-us/articles/performance-tools-for-software-developers-building-hdf5-with-intel-compilers
#   https://software.intel.com/en-us/articles/performance-tools-for-software-developers-building-netcdf-with-the-intel-compilers
################################################################################

source functions.sh

################################################################################
# USER'S BLOCK
# 1. Path to place the cdo folder [CHANGE THIS]
export CDOPATH="/home/anddebol_2043/_scratch/opt/cdo-1.9.5"
# 2. Filenames to install [DO NOT CHANGE THIS UNLESS YOU'RE SURE]
#    The elements are in the installation order, so it is RELEVANT!!! 
#    If you're making changes -- make sure that this *.tar.gz file is in the folder 
TARLIST=(
  "szip-2.1.1.tar.gz"
  "zlib-1.2.8.tar.gz"
  "hdf5-1.8.21.tar.gz"
  "netcdf-c-4.6.2.tar.gz"
  "netcdf-fortran-4.4.4.tar.gz"
  "jasper-1.900.1.tar.gz"        # needless for new cdo?
  "curl-7.26.0.tar.gz"           # needless for new cdo?
  "proj-5.2.0.tar.gz"
  "udunits-2.2.26.tar.gz"
  "eccodes-2.10.0-Source.tar.gz"
  # # "Magics-3.3.1-Source.tar.gz" # DOESN'T WORK YET ( Jinja2 import failure)!!!
  "cdo-1.9.5.tar.gz"
)
################################################################################

################################################################################
# MAGIC BLOCK
# Set of enviroments
export CC=mpicc                        # mpiicc           mpicc    
export CXX=mpicxx                      # mpiicpc          mpicxx    
export CPP="mpic++ -E"                 # "mpiicc -E"      mpic++ -E    
export CXXCPP=$CPP   
export FC=mpifort                      # mpiifort         mpifort 
export F77=mpif77                      # mpiifort         mpif77  
export CFLAGS="-O3 -xHost -ip -fPIC"   #"-O3 -xHost -ip -no-prec-div -fPIC"  # "-O3 -xHost -ip -fPIC"  -static-intel 
export FCFLAGS="-O3 -xHost -ip -fPIC"  #"-O3 -xHost -ip -no-prec-div -fPIC"  # "-O3 -xHost -ip -fPIC"  -static-intel 
export CXXFLAGS="-O3 -xHost -ip -fPIC" #"-O3 -xHost -ip -no-prec-div -fPIC"  # "-O3 -xHost -ip -fPIC" -static-intel 
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
# Check permition if the folder exists and create if it's not
if [ ! -d "$CDOPATH" ]; then
  echo "    The folder $CDOPATH doesn't exist. Trying to create it..."
  if mkdir -p "$CDOPATH"; then
    echo "    Destination folder "$CDOPATH" has been created successfully!"
  else
    echo "***"
    echo "*--> Current user don't have rights to create the "$CDOPATH
    echo "*    Create the folder manually or choose different path for CDOPATH"
    echo "***"
    exit 1
  fi
else
  echo "    The folder $CDOPATH exists. Checking for permitions..."
  if touch $CDOPATH/_test; then
    echo "    Destination folder "$CDOPATH" has proper permitions!"
    rm -rf $CDOPATH/_test
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
    execute "./configure --prefix=$CDOPATH  \
                     --with-szlib=$CDOPATH  \
                     --with-zlib=$CDOPATH   \
                     --enable-parallel      \
                     --enable-threadsafe --enable-unsupported \
                     --enable-shared --enable-static \
                     --enable-fortran       \
                     &> _configure.log"
                     # --disable-hl         \
                     # --enable-cxx         \
                     # --enable-shared      \
    execute "make &> _make.log "
    execute "make check &> _make_check.log"
    execute "make install &> _make_install.log"
  
  elif [ "$SOFTNAME" == "netcdf-c" ]; then
    export LIBS="-lhdf5_hl -lhdf5 -lz"
    execute "./configure --prefix=$CDOPATH  \
                         --enable-shared    \
                         --enable-static    \
                         --disable-dap      \
                     &> _configure.log"
                     # --enable-dynamic-loading \
                     # --enable-netcdf-4        \
    execute "make &> _make.log "
    execute "make check &> _make_check.log"
    execute "make install &> _make_install.log"

    export LIBS=""
  
  elif [ "$SOFTNAME" == "netcdf-fortran" ]; then
    export LIBS="-lnetcdf -lhdf5_hl -lhdf5 -lz"
    execute "./configure --prefix=$CDOPATH  \
                         --enable-shared    \
                         --enable-static    \
                         >& _configure.log"
    execute "make &> _make.log "
    # execute "make check &> _make_check.log"
    execute "make install &> _make_install.log"
    export LIBS=""
  
  elif [ "$SOFTNAME" == "curl" ]; then
    execute "./configure --prefix=$CDOPATH --with-zlib=$CDOPATH >& _configure.log"
    execute "make &> _make.log "
    # fixing bugs
    sed -i -e 's/1391252187/2139150993/g' tests/data/test172
    sed -i -e 's/1439150993/1739150993/g' tests/data/test46
    execute "make check &> _make_check.log"
    execute "make install &> _make_install.log"
  
  elif [ "$SOFTNAME" == "proj" ]; then
    CFLAGS_SAVE=$CFLAGS
    export CFLAGS="-O0"    # "-O3 -xHost -ip -fPIC"
    unzip ../proj-datumgrid-1.8.zip -d nad/ >& _unsip_datumgrid.log
    execute "./configure --prefix=$CDOPATH --with-pic --without-mutex --without-jni >& _configure.log"
    execute "make &> _make.log "
    execute "make check &> _make_check.log"
    execute "make install &> _make_install.log"
    export CFLAGS=$CFLAGS_SAVE
  
  elif [ "$SOFTNAME" == "udunits" ]; then
    export CPP=""
    execute "./configure --prefix=$CDOPATH --with-pic >& _configure.log"
    execute "make &> _make.log "
    execute "make check &> _make_check.log"
    execute "make install &> _make_install.log"
  
  elif [ "$SOFTNAME" == "jasper" ]; then
    CFLAGS_SAVE=$CFLAGS
    export CFLAGS="-O0"    # "-O3 -xHost -ip -fPIC"
    # OLD (1.N versions)
    execute "./configure --prefix=$CDOPATH --with-pic >& _configure.log"
    execute "make &> _make.log "
    execute "make check &> _make_check.log"
    execute "make install &> _make_install.log"

    # # NEW VERSION [DON'T WORK YET]
    # cd build
    # execute "cmake3 .. -G 'Unix Makefiles' -H../ -B./   \
    #               -DCMAKE_INSTALL_PREFIX=$CDOPATH      \
    #               >& _configure.log"
    # execute "make clean all &> _make.log "
    # execute "make test &> _make_check.log"
    # execute "make install &> _make_install.log"
    # cd ../../

    export CFLAGS=$CFLAGS_SAVE
  
  elif [ "$SOFTNAME" == "eccodes" ]; then
    CFLAGS_SAVE=$CFLAGS
    export CFLAGS=""
    if [ -d "../eccodes_build" ]; then rm -rf ../eccodes_build; fi
    mkdir ../eccodes_build
    cd ../eccodes_build
    execute "cmake -DCMAKE_INSTALL_PREFIX=$CDOPATH ../$TARNAME \
                   -DBUILD_SHARED_LIBS=BOTH       \
                   -DCMAKE_C_FLAGS='-fPIC'        \
                   -DNETCDF_PATH=$CDOPATH         \
                    >& _configure.log"
    execute "make &> _make.log "
    execute "make check &> _make_check.log"
    execute "make install &> _make_install.log"
    export CFLAGS=$CFLAGS_SAVE
  
  elif [ "$SOFTNAME" == "Magics" ]; then  # NOT FINISHED!!!!
    if [ -d "../Magics_build" ]; then rm -rf ../Magics_build; fi
    mkdir ../Magics_build
    cd ../Magics_build
    execute "cmake3 -DCMAKE_INSTALL_PREFIX=$CDOPATH ../$TARNAME \
                     -DCMAKE_CXX_FLAGS='-O2 -mtune=native'  \
                     -DCMAKE_C_FLAGS='$CFLAGS'              \
                     -DCMAKE_Fortran_FLAGS='$FCFLAGS'       \
                     -DENABLE_CAIRO=OFF                     \
                    >& _configure.log"
    execute "make &> _make.log "
    execute "make check &> _make_check.log"
    execute "make install &> _make_install.log"
  
  elif [ "$SOFTNAME" == "cdo" ]; then
    
    # if [ ${#TARLIST[@]} -lt 5 ]; then
    #   echo " "
    #   echo "--> Not enough packages to compile cdo. Skipping..."
    #   exit 0
    # fi
                     # --with-grib_api=$CDOPATH  \
                     # --disable-fortran         \
                     # --with-magics=$CDOPATH    \
    execute "./configure --prefix=$CDOPATH     \
                     --with-netcdf=$CDOPATH    \
                     --with-szlib=$CDOPATH     \
                     --with-hdf5=$CDOPATH      \
                     --with-eccodes=$CDOPATH   \
                     --with-proj=$CDOPATH      \
                     --with-jasper=$CDOPATH    \
                     --with-curl=$CDOPATH      \
                     --with-udunits2=$CDOPATH  \
                     --with-pic                \
                     --disable-python          \
                     --disable-numpy           \
                     &> _configure.log"
    execute "make &> _make.log "
    execute "make check &> _make_check.log"
    execute "make install &> _make_install.log"
  else
    echo "Don't know how to install package "$SOFTNAME" from TARLIST"
    echo "If it's not a mistyping, include the installation algorithm in "
    echo "this script (main loop part)."
    exit 1
  fi

  cd ../

done

echo "Everythig was compiled for both static and shared libs."
echo ""
echo "Dont forget to add "$CDOPATH/lib
echo "in LD_LIBRARY_PATH (.bash_profile || .bashrc)"

exit 0