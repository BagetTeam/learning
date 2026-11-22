## Running tests

```sh
cmake -S . -B build                   # once, or after changing CMakeLists.txt
cmake --build build --target run_tests
./build/run_tests                           # run everything
./build/run_tests --gtest_filter='OrderBookTest.*'   # run only one suite
```