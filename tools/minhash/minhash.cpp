#include <algorithm>
#include <chrono>
#include <iostream>
#include <vector>
#include <random>

#define MIN_HASH_SIZE 10

struct doc_t {
    uint32_t orig_id = 0;
    uint32_t hashes[MIN_HASH_SIZE];
    bool operator<(const doc_t& other) const {
        for(size_t i=0;i<MIN_HASH_SIZE;i++) {
            if(hashes[i] != other.hashes[i]) {
                return hashes[i] < other.hashes[i];
            }
        }
        return false;
    }
    doc_t () {
      for (size_t i = 0; i < MIN_HASH_SIZE; i++) {
        hashes[i] = std::numeric_limits<uint32_t>::max();
      }
    }
};

uint32_t read_u32(FILE* f)
{
    uint32_t x;
    int ret = fread(&x, sizeof(uint32_t), 1, f);
    if (feof(f)) {
        return 0;
    }
    if (ret != 1) {
        fprintf(stderr,"read u32 from file failed: %d != %d", ret, 1);
        exit(EXIT_FAILURE);
    }
    return x;
}

void read_u32s(FILE* f, void* ptr, size_t n)
{
    size_t ret = fread(ptr, sizeof(uint32_t), n, f);
    if (ret != n) {
        fprintf(stderr,"read u32s from file failed: %d != %d", int(ret), int(n));
        exit(EXIT_FAILURE);
    }
}

void read_uint32_list(std::vector<uint32_t>& list,FILE* f)
{
    uint32_t list_len = read_u32(f);
    list.resize(list_len);
    if (list_len != 0) {
        read_u32s(f, list.data(), list_len);
    }
}

uint32_t hash_func(uint32_t x)
{
    x = ((x >> 16) ^ x) * 0x119de1f3;
    x = ((x >> 16) ^ x) * 0x119de1f3;
    x = (x >> 16) ^ x;
    return x;
}

std::vector<doc_t> read_ds2i_files(std::string ds2i_prefix)
{
    std::vector<doc_t> docs;
    std::string docs_file = ds2i_prefix + ".docs";
    auto df = fopen(docs_file.c_str(), "rb");
    // (1) skip the numdocs list
    std::vector<uint32_t> list;
    list.reserve(1024*1024*128);
    read_uint32_list(list,df);
    docs.resize(list[0]);
    for(size_t i=0;i<docs.size();i++) {
        docs[i].orig_id = i;
    }

    uint32_t seeds[MIN_HASH_SIZE];
    std::mt19937 rng(MIN_HASH_SIZE);
    for(size_t i=0;i<MIN_HASH_SIZE;i++)
        seeds[i] = hash_func(rng());

    uint32_t term_id = 0;
    uint32_t term_hashes[MIN_HASH_SIZE];
    while (!feof(df)) {
        uint32_t term_hash = hash_func(term_id);
        for(size_t i=0;i<MIN_HASH_SIZE;i++)
            term_hashes[i] = hash_func(term_hash^seeds[i]);
        read_uint32_list(list,df);
        size_t n = list.size();
        if (n == 0) {
            break;
        }
        for(size_t i=0;i<n;i++) {
            auto& doc = docs[list[i]];
            for(size_t j=0;j<MIN_HASH_SIZE;j++) {
                doc.hashes[j] = std::min(doc.hashes[j],term_hashes[j]);
            }
        }
        term_id++;
    }
    fclose(df);
    return docs;
}

int main(int argc, char** argv)
{
    if(argc != 2) {
      std::cerr << "Expects 1 argument: ds2i collection path" << std::endl;
      return EXIT_FAILURE;
    }
    std::string ds2i_prefix = argv[1];

    auto doc_list = read_ds2i_files(ds2i_prefix);

    std::sort(doc_list.begin(),doc_list.end());

    for(size_t i=0;i<doc_list.size();i++) {
        std::cout << doc_list[i].orig_id << " " << i 
                  << std::endl;
    }

    return EXIT_SUCCESS;
}

