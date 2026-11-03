#pragma once

#include <cstdint>
#include <ctime>
#include <deque>
#include <map>

using Price = std::uint32_t;
using Quantity = std::uint32_t;
using OrderID = std::uint64_t;

using OrderQueue = std::deque<OrderID>; // would be a linked list for better efficiency when cancelling
using BidBook = std::map<Price, OrderQueue, std::greater<int>>; //sorted keys descending
using SellBook = std::map<Price, OrderQueue>; //sorted keys ascending


/*
{
    10.99: [12, 55, 92]
    10.98: []
    10.96: []

}

*/