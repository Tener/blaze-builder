
##############################################################################
## Benchmarks
##############################################################################

## Config
#########

GHC6 = ghc-6.12.3
GHC7 = ghc-7.0.0.20100924

GHC = $(GHC6)

GHCI = ghci-6.12.3


## All benchmarks
#################

bench-all: bench-compression bench-string-and-text bench-throughput bench-chunked-write

clean-bench-all:
	rm -f benchmarks/*.o benchmarks/*.hi
	rm -f benchmarks/Throughput/*.o benchmarks/Throughput/*.hi
	rm -f Text/Blaze/Builder.o Text/Blaze/Builder.hi
	rm -f Text/Blaze/Builder/*.o Text/Blaze/Builder/*.hi
	rm -f Text/Blaze/Builder/Char/*.o Text/Blaze/Builder/Char/*.hi
	rm -f Text/Blaze/Builder/Html/*.o Text/Blaze/Builder/Html/*.hi
	rm -f Text/Blaze/Builder/Core/*.o Text/Blaze/Builder/Core/*.hi
	rm -f benchmarks/Compression benchmarks/StringAndText benchmarks/BenchThroughput benchmarks/ChunkedWrite benchmarks/BlazeVsBinary
	rm -f Criterion/*.o Criterion/*.hi
	rm -f Criterion/ScalingBenchmark

## Individual benchmarks
########################

# 'blaze-builder' vs. 'binary' comparision
bench-blaze-vs-binary:
	$(GHC) --make -O2 -fforce-recomp -main-is BlazeVsBinary benchmarks/BlazeVsBinary.hs
	./benchmarks/BlazeVsBinary --resamples 10000

# throughput benchmarks: interactive development
ghci-throughput: benchmarks/Throughput/CBenchmark.o 
	$(GHCI) -O2 -fforce-recomp -ibenchmarks -main-is BenchThroughput benchmarks/Throughput/CBenchmark.o benchmarks/BenchThroughput.hs

bench-throughput: benchmarks/Throughput/CBenchmark.o
	$(GHC) --make -O2 -fforce-recomp -fliberate-case-threshold=1000 -ibenchmarks -main-is BenchThroughput benchmarks/Throughput/CBenchmark.o benchmarks/BenchThroughput.hs
	./benchmarks/BenchThroughput 100

benchmarks/Throughput/CBenchmark.o: benchmarks/Throughput/CBenchmark.c
	gcc -O3 -c $< -o $@

# Benchmark benefit of serializing several list elements at once
bench-chunked-write:
	$(GHC) --make -O2 -fforce-recomp -main-is ChunkedWrite benchmarks/ChunkedWrite.hs
	./benchmarks/ChunkedWrite --resamples 10000

core-chunked-write:
	ghc-core -- --make -O2 -fforce-recomp -main-is ChunkedWrite benchmarks/ChunkedWrite.hs

# Benchmark best serialization techniques for 'String' and 'Text'
bench-string-and-text:
	$(GHC) --make -O2 -fforce-recomp -ibenchmarks -main-is StringAndText StringAndText
	echo $(GHC)
	./benchmarks/StringAndText --resamples 10000

# Benchmark benefit of compaction before compression
bench-compression:
	$(GHC) --make -O2 -fforce-recomp -ibenchmarks -main-is Compression Compression
	./benchmarks/Compression --resamples 10000

# core after rule applications for fromWriteList
core-fromWriteList:
	ghc-core -- --make -O2 -fforce-recomp Blaze/ByteString/Builder/Write.hs

# check rule applications
rules-fromWriteList:
	$(GHC) --make -O2 -dppr-debug -ddump-rules -ddump-rule-firings -fforce-recomp Blaze/ByteString/Builder/Write.hs

##############################################################################
## Plots
##############################################################################

plot-all:
	$(GHC) --make -O2 -fforce-recomp -main-is Criterion.ScalingBenchmark Criterion.ScalingBenchmark
	./Criterion/ScalingBenchmark --resamples 10000


##############################################################################
## Tests
##############################################################################

test:
	$(GHC) --make -O2 -itests -main-is Tests Tests
	./tests/Tests

clean-tests:
	rm -f tests/Tests tests/*.o tests/*.hi

ghci-llvm-segfault: 
	$(GHCI) -itests -main-is LlvmSegfault tests/LlvmSegfault 

test-llvm-segfault: 
	ghc-7.0.0.20100924 --make -fllvm -itests -main-is LlvmSegfault tests/LlvmSegfault 
	./tests/LlvmSegfault

##############################################################################
## All inclusive targets
##############################################################################

clean: clean-tests clean-bench-all
