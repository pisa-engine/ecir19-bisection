#!/bin/bash

BASE=`pwd`

# Just in case clone was not recursive
git submodule init
git submodule update --recursive

# Indri build
echo "Build Indri"
cd $BASE/external/indri/
mkdir -p obj contrib/antlr/obj contrib/lemur/obj contrib/xpdf/obj contrib/zlib/obj
./configure
make -j 5
if [ $? -ne 0 ];
then
  echo "ERROR: Build Indri failed!"
  exit -1
fi


# Indri to ds2i build
echo "Building Indri to ds2i conversion tool"
cd $BASE/tools/indri_to_ds2i/
make

# Minhash build 
# XXX: Move this into pisa and refactor
echo "Building Minhash tool"
cd $BASE/tools/minhash/
make

# Pisa build
cd $BASE/external/pisa
mkdir build
cd build
cmake ..
make recursive_graph_bisection shuffle_docids create_freq_index evaluate_collection_ordering


cd $BASE
