#pragma once

#include <cstdint>
#include <ctime>
#include <map>
#include <queue>

using Price = std::uint32_t;
using Quantity = std::uint32_t;
using OrderID = std::uint64_t;

using OrderQueue = std::queue<OrderID>; // would be a linked list for better efficiency when cancelling
using Book = std::map<Price, OrderQueue>; //sorted keys


/*
{
    10.99: [12, 55, 92]
    10.98: []
    10.96: []

}

*/