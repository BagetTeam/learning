#pragma once
#include "types.hpp"


enum class OrderType {
    Limit, // with a price
    Market, // market price
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