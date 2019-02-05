#!/bin/bash

# 0. Check args
if [ "$#" -ne 2 ]; then
  echo "Expected two arguments: <path to indri configuration> <output prefix>"
  exit -1
fi

INDRI_PARAM=$1
OUTPUT_PREFIX=$2
DELIM="-------------------------------------------------"
DONE="---------------------DONE------------------------"

# 1. Build the Indri Index
echo $DELIM
echo "Building the Indri Index..."
echo $DELIM
./external/indri/buildindex/IndriBuildIndex $INDRI_PARAM
echo $DONE

# 1.1 Grab target of index
echo $DELIM
echo "Getting the index target name and basenames..."
echo $DELIM
INDRI_IDX=`grep "<index>" $INDRI_PARAM | cut -d">" -f2 | cut -d"<" -f1`
OUT_NAME=`basename $INDRI_IDX`
echo "Using the output file basename '$OUT_NAME'"
echo $DONE

# 2. Convert the indri index to ds2i format
echo $DELIM
echo "Converting the Indri Index into the ds2i binary format..."
echo $DELIM
mkdir $OUTPUT_PREFIX"_original_ds2i"
DS2I_IDX=$OUTPUT_PREFIX"_original_ds2i/"$OUT_NAME
./tools/indri_to_ds2i/indri_to_ds2i $INDRI_IDX $OUTPUT_PREFIX"_original_ds2i/"$OUT_NAME
echo $DONE

# 3.1 Let's make a 'random' index
echo $DELIM
echo "Generating a random permutation document ordering..."
echo $DELIM
mkdir $OUTPUT_PREFIX"_random_ds2i"
RANDOM_IDX=$OUTPUT_PREFIX"_random_ds2i/"$OUT_NAME
# Use the shuffle_docids without any argument to apply a random shuffle
./external/pisa/build/bin/shuffle_docids $DS2I_IDX $RANDOM_IDX
echo $DONE

# 3.2 Let's make a 'minhash' index
echo $DELIM
echo "Generating an ordering based on minhash..."
echo $DELIM
mkdir $OUTPUT_PREFIX"_minhash_ds2i"
MINHASH_IDX=$OUTPUT_PREFIX"_minhash_ds2i/"$OUT_NAME
# Create the minhash ordering file as input to the shuffle_docids program
./tools/minhash/minhash $DS2I_IDX > $OUTPUT_PREFIX"_minhash_ds2i/minhash.ordering"
# Now shuffle the id's using the provided ordering
./external/pisa/build/bin/shuffle_docids $DS2I_IDX $MINHASH_IDX $OUTPUT_PREFIX"_minhash_ds2i/minhash.ordering"
echo $DONE

# 3.3 Let's make a 'bp' index
echo $DELIM
echo "Generating an ordering based on recursive bisection..."
echo $DELIM
mkdir $OUTPUT_PREFIX"_bisection_ds2i"
BISECT_IDX=$OUTPUT_PREFIX"_bisection_ds2i/"$OUT_NAME
# Run bisection with min list length of 4096, log(n)-5 levels of recursion
./external/pisa/build/bin/recursive_graph_bisection -c $DS2I_IDX -o $BISECT_IDX --store-fwdidx $BISECT_IDX".forward-index" -m 4096 
echo $DONE

# 4. Build frequency index for each, and evaluate the ordering. Also compute loggap.
echo $DELIM
echo "Creating the frequency indexes to evaluate the collection ordering..."
echo $DELIM
mkdir $OUTPUT_PREFIX"_indexes"
cd $OUTPUT_PREFIX"_indexes"
# For each index
for idx in random minhash bisection; do
  # For each codec
  for codec in opt block_interpolative block_streamvbyte; do
    # Build the index but do not store it, evaluate postings size and log it 
    ../external/pisa/build/bin/create_freq_index -o /dev/null -t $codec -c ../$OUTPUT_PREFIX"_"$idx"_ds2i/"$OUT_NAME &> $idx"."$codec".log"
  done
  # also grab the loggap too
  ../external/pisa/build/bin/evaluate_collection_ordering ../$OUTPUT_PREFIX"_"$idx"_ds2i/"$OUT_NAME &> $idx".log_gap"
done
echo $DONE

echo $DELIM
echo "Finished... Examine .log_gap and .log files to look at the performance of each ordering."
echo $DONE


