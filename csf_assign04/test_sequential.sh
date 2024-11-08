#! /usr/bin/env bash

make gen_rand_data parsort seqsort
gcc -g -Wall -c gen_rand_data.c -o gen_rand_data.o
gcc -o gen_rand_data gen_rand_data.o
gcc -g -Wall -c parsort.c -o parsort.o
gcc -o parsort parsort.o
g++ -g -Wall -std=c++17 -c seqsort.cpp -o seqsort.o
g++ -o seqsort seqsort.o
./gen_rand_data 1M test_data_1.bin
echo "Wrote 1048576 bytes to 'test_data_1.bin'"
./parsort test_data_1.bin 65536
./gen_rand_data 1M test_data_2.bin
echo "Wrote 1048576 bytes to 'test_data_2.bin'"
./seqsort test_data_2.bin 
diff test_data_1.bin test_data_2.bin 
echo $?