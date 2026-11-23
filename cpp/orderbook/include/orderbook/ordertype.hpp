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
inline bool operator==(const Trade& a, const Trade& b) {
    return a.makerOrderId == b.makerOrderId &&
       a.takerOrderId == b.takerOrderId &&
       a.executionPrice == b.executionPrice &&
       a.executionQuantity == b.executionQuantity;
}