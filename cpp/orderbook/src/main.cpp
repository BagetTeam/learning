#include <iostream>

int main() {
    std::cout << "C++ Macro Value: " << __cplusplus << "\n";
    
    if (__cplusplus == 202302L) std::cout << "You are using C++23\n";
    else if (__cplusplus == 202002L) std::cout << "You are using C++20\n";
    else if (__cplusplus == 201703L) std::cout << "You are using C++17\n";
    else if (__cplusplus == 201402L) std::cout << "You are using C++14\n";
    else if (__cplusplus == 201103L) std::cout << "You are using C++11\n";
    else if (__cplusplus == 199711L) std::cout << "You are using C++98\n";
    else std::cout << "Pre-standard C++ or custom compiler flag\n";
    
    return 0;
}