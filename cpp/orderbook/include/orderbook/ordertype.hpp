#pragma once


#include "types.hpp"
enum class OrderType {
    Limit,
    Market,
    Cancel,
    Modify,
};

enum class Side {
    Buy,
    Sell
};

struct Trade {
    OrderID makerOrderId;
    OrderID takerOrderId; // new order
    Price executionPrice;
    Quantity executionQuantity;
};