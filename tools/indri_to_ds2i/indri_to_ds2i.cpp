#include <iostream>
#include <chrono>
#include <vector>
#include <unordered_map>
#include <map>
#include <fstream>
#include <utility>
#include <algorithm>
#include <memory>

// INDRI includes
#include "indri/Repository.hpp"
#include "indri/CompressedCollection.hpp"

#include <string>
#include <unistd.h>
#include <stdlib.h>
#include <iostream>

#include <sys/types.h>
#include <sys/stat.h>


int main(int argc, char **argv) {

  using clock = std::chrono::high_resolution_clock;
  
  if (argc != 3) {
    std::cout << "USAGE: " << argv[0];
    std::cout << " <indri_index> output_basename\n";
    return EXIT_FAILURE;
  }

  std::string repository_name = argv[1];
  std::string basename = argv[2];
  std::ofstream doc_file(basename+".docs", std::ios::binary);
  std::ofstream freq_file(basename+".freqs", std::ios::binary);
  std::ofstream size_file(basename+".sizes", std::ios::binary);
  std::ofstream doc_id_file(basename+".docids");
  std::ofstream dict_file(basename+".lexicon");

  auto build_start = clock::now();

  // load stuff
  indri::collection::Repository repo;
  repo.openRead(repository_name);
  indri::collection::Repository::index_state state = repo.indexes();
  const auto& index = (*state)[0];

  // Write first sequence: no docs in collectio
  uint32_t t = 1;
  doc_file.write((char *)&t, sizeof(uint32_t));
  t = index->documentCount();
  doc_file.write((char *)&t, sizeof(uint32_t));
  
  // Also write no. docs in as the sequence header for the doc lengths file
  size_file.write((char *)&t, sizeof(uint32_t));

  std::cout << "Writing document lengths and ID's." << std::endl;
  // Write lengths and names
  {
    indri::collection::CompressedCollection* collection = repo.collection();
    int64_t document_id = index->documentBase();
    indri::index::TermListFileIterator* iter = index->termListFileIterator();
    iter->startIteration();
    while( !iter->finished() ) {
      indri::index::TermList* list = iter->currentEntry();
      std::string doc_name = collection->retrieveMetadatum( document_id , "docno" );
      doc_id_file << doc_name << std::endl;
      uint32_t length = list->terms().size();
      size_file.write((char *)&length, sizeof(uint32_t));
      document_id++;
      iter->nextEntry();
    }
  }

  // write dictionary
  {
    std::cout << "Writing dictionary and postings." << std::endl;
    const auto& index = (*state)[0];
    indri::index::VocabularyIterator* iter = index->vocabularyIterator();
    iter->startIteration();

    size_t j = 0;
    while( !iter->finished() ) {
      indri::index::DiskTermData* entry = iter->currentEntry();
      indri::index::TermData* termData = entry->termData;
      uint32_t list_length = termData->corpus.documentCount;
      dict_file << termData->term << " " << j << " "
              << termData->corpus.documentCount << " "
              << termData->corpus.totalCount << " "
              <<  std::endl;

      if (j % 1000000 == 0) {
        std::cerr << "Processing term " << j << ", " << termData->term << std::endl;
      }
      // write inverted files
      {
        doc_file.write((char *)&list_length, sizeof(uint32_t));
        freq_file.write((char *)&list_length, sizeof(uint32_t));
 
        const auto& index = (*state)[0];
        indri::index::DocListIterator* piter = index->docListIterator(termData->term);
        piter->startIteration();

        while( !piter->finished() ) {
          indri::index::DocListIterator::DocumentData* doc = 
            piter->currentEntry();
          // Write
          uint32_t doc_id = doc->document - 1;
          uint32_t term_freq = doc->positions.size();
          doc_file.write((char *)&doc_id, sizeof(uint32_t));
          freq_file.write((char *)&term_freq, sizeof(uint32_t));

          piter->nextEntry();
        }
        delete piter;
      }

      iter->nextEntry();
      j++;
    }
    delete iter;
  }

  doc_file.close();
  freq_file.close();
  size_file.close();
  doc_id_file.close();
  dict_file.close();
 
  auto build_stop = clock::now();
  auto build_time_sec = std::chrono::duration_cast<std::chrono::seconds>(build_stop-build_start);
  std::cout << "Index transformed in " << build_time_sec.count() << " seconds." << std::endl;

  return EXIT_SUCCESS;
}



