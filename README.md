Compressing Graphs and Indexes with Recursive Graph Bisection: A Reproducibility Study
======================================================================================

Welcome. This repository contains the required data to reproduce the experiments from
the following paper. We request you cite this work if you decide to use our algorithm
for your own papers.

Joel Mackenzie, Antonio Mallia, Matthias Petri, J. Shane Culpepper, and Torsten Suel:
**Compressing Inverted Indexes with Recursive Graph Bisection: A Reproducibility Study.**
To appear in ECIR, 2019.

```
@inproceedings{

}
```

Codebase
--------
The core bisection algorithm exists in the [PISA](https://github.com/pisa-engine/pisa) project, which is included
here as a submodule. We also use [Indri](https://github.com/lgrz/indri) to index the text collections.


Acknowledgements
----------------
The original paper can be found here: [Compressing Graphs and Indexes with Recursive Graph Bisection](http://www.kdd.org/kdd2016/papers/files/rpp0883-dhulipalaAemb.pdf), (Proceedings Link)[https://dl.acm.org/citation.cfm?id=2939862]

```
@inproceedings{dk+16-kdd,
 author = {L. Dhulipala and I. Kabiljo and B. Karrer and G. Ottaviano and S. Pupyrev and A. Shalita},
 title = {Compressing Graphs and Indexes with Recursive Graph Bisection},
 booktitle = {Proc. SIGKDD},
 year = {2016},
 pages = {1535--1544}
} 
```

We thank the authors of this paper for their assistance in our reproducibility study.



Usage
----
This repository aims to show how we go from end-to-end for our experiments, allowing
others to repeat them. The main scripts are `build.sh` and `end-to-end.sh`.

Note that the Indri configuration files in `configuration/indri_config` must be
populated with correct paths before proceeding.

So, the steps are as follows:
1. Configure the Indri parameter file correctly.
2. Build the code: `./build.sh`
3. Run the code, end to end: `./end-to-end.sh <path_to_indri_config> <output_basename>`

An example of running end-to-end.sh and explanation is shown below for the `gov2`
collection: `./end-to-end.sh ./configuration/indri_config/gov2.param my-gov2`

1. Create the Indri index for the specified collection. Output path depends on the Indri configuration file.
2. Convert the Indri index into the ds2i binary collection format: `my-gov2_original_ds2i/`
3. Generate a random shuffle of the binary collection: `my-gov2_random_ds2i/`
4. Generate a minhash shuffle of the binary collection: `my-gov2_minhash_ds2i/`
5. Generate a bp shuffle of the binary collection: `my-gov2_bisection_ds2i/`
6. Generate a frequency index for each collection: `my-gov2_indexes/`

Additional Data
---------------
As mentioned in the paper, two of the collections are generated from dumps that
are difficult to reproduce. We have archived these collections and we are happy
to make them available to anyone interested in reproducing our experiments.
We also retained the URL orderings used, but again, these are too cumbersome for
uploading in this repo.
Please email `joel.mackenzie@rmit.edu.au` if you are looking for this data or
any further assistance with these experiments.
