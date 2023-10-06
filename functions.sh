#!/bin/bash
execute() {
  start=$SECONDS
  echo "    running: "$1
  if ! eval $1; then
      let "elapsed=($SECONDS-$start)/60"
      echo "    Something's went wrong. Check $TARNAME/_*.log"
      echo "    Time elapsed "$elapsed" (min)"
      exit 1
  else
	  let "elapsed=($SECONDS-$start)/60"
	  echo "    Successfully! Time elapsed "$elapsed" (min)"
  fi
}

print_envs() {
  echo "===================================================================="
  echo "--> ${bold}Enviroment settings:${normal}"
  echo "    Total installation path: "$CDOPATH
  echo "    CC="$CC
  echo "    CXX="$CXX
  echo "    CPP="$CPP
  echo "    CXXCPP="$CXXCPP
  echo "    CFLAGS="$CFLAGS
  echo "    CXXFLAGS="$CXXFLAGS
  echo "    CPPFLAGS="$CPPFLAGS
  echo "    FC="$FC
  echo "    F77="$F77
  echo "    FCFLAGS="$FCFLAGS
  echo "    LDFLAGS="$LDFLAGS
  echo "    LD_LIBRARY_PATH="$LD_LIBRARY_PATH
  echo "    *** CHECK IF NO NETCDF IN LD_LIBRARY_PATH!!!"  
  echo "        You can do module purge"  
  echo "                   export LD_LIBRARY_PATH=''"  
  echo "                   module add [compiler and mpi (if needed) modules]"  
  echo "===================================================================="  
}