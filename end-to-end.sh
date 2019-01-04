#!/bin/bash

# 0. Check args
if [ "$#" -ne 2 ]; then
  echo "Expected two arguments: <path to indri configuration> <output prefix>"
  exit -1
fi

INDRI_PARAM=$1
OUTPUT_PREFIX=$2

# 1. Build the Indri Index
./external/indri/buildindex/IndriBuildIndex $INDRI_PARAM

# 1.1 Grab target of index
INDRI_IDX=`grep "<index>" $INDRI_PARAM | cut -d">" -f2 | cut -d"<" -f1`
OUT_NAME=`basename $INDRI_IDX`
echo "Using the output file Basename '$OUT_NAME'"
echo "If you would like a different name, input it now."
read -p "Otherwise, press enter to continue with the current name: " OUT_NAME

# 2. Convert the indri index to ds2i format
mkdir $OUTPUT_PREFIX"_original_ds2i"
DS2I_IDX=$OUTPUT_PREFIX"_original_ds2i/"$OUT_NAME

./indri_to_ds2i/indri_to_ds2i $INDRI_IDX $OUTPUT_PREFIX"_original_ds2i/"$OUT_NAME

# 3.1 Let's make a 'random' index
mkdir $OUTPUT_PREFIX"_random_ds2i"
RANDOM_IDX=$OUTPUT_PREFIX"_random_ds2i/"$OUT_NAME
# Use the shuffle_docids without any argument to apply a random shuffle
./external/pisa/build/bin/shuffle_docids $DS2I_IDX $RANDOM_IDX

# 3.2 Let's make a 'minhash' index
mkdir $OUTPUT_PREFIX"_minhash_ds2i"
MINHASH_IDX=$OUTPUT_PREFIX"_minhash_ds2i/"$OUT_NAME
# Create the minhash ordering file as input to the shuffle_docids program
./tools/minhash/minhash $DS2I_IDX > $OUTPUT_PREFIX"_minhash_ds2i/minhash.ordering"
# Now shuffle the id's using the provided ordering
./external/pisa/build/bin/shuffle_docids $DS2I_IDX $MINHASH_IDX $OUTPUT_PREFIX"_minhash_ds2i/minhash.ordering"

# 3.3 Let's make a 'bp' index
mkdir $OUTPUT_PREFIX"_bisection_ds2i"
BISECT_IDX=$OUTPUT_PREFIX"_bisection_ds2i/"$OUT_NAME
# Run bisection with min list length of 4096, log(n)-5 levels of recursion
./external/pisa/build/bin/recursive_graph_bisection -c $DS2I_IDX -o $BISECT_IDX --store-fwdidx $BISECT_IDX".forward-index" -m 4096 

# 4. Build frequency index for each, and evaluate the ordering. Also compute loggap.
mkdir $OUTPUT_PREFIX"_indexes"
cd $OUTPUT_PREFIX"_indexes"

# For each index
for idx in $RANDOM_IDX $MINHASH_IDX $BISECT_IDX; do
  # For each codec
  for codec in opt block_interpolative block_streamvbyte; do
    # Build the index but do not store it, evaluate postings size and log it 
    ../external/pisa/build/bin/create_freq_index -t $codec -c $idx &> $idx"."$codec".log"
  done
  # also grab the loggap too
  ../external/pisa/build/bin/evaluate_collection_ordering $idx &> $idx".log_gap"
done



