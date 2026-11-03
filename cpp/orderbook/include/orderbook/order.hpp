#pragma once

#include <string>
#include <iostream>
#include <stdexcept>
#include "ordertype.hpp"
#include "types.hpp"


class Order {
    public: 
        Order(OrderID orderId, Side side, OrderType orderType, Price price, Quantity quantity)
            : orderId_{orderId}
            , side_{side}
            , orderType_{orderType}
            , price_{price}
            , quantity_{quantity} 
        {
            if (quantity == 0) {
                throw std::invalid_argument("quantity needs to be greater than 0");
            }
        }

    private:
        OrderID orderId_;
        Side side_;
        OrderType orderType_;
        Price price_;
        Quantity quantity_;
};


class OrderBook {
    OrderBook();

    int BestBid() {
        auto it = std::prev(_bidBook.end());
        return it->first;
    }

    int BestSell() {
        auto it = _sellBook.first();
        return it->first;
    }

    void submit();

    boolean cancel();

    private:
        Book _sellBook;
        Book _bidBook;
        std::unordered_map<OrderId, Order> _orders;
}


// matching engine determines when an incoming order can execute against them.
class Engine {
    public:
        Engine();
        void HandleNewOrder(Order order);
}