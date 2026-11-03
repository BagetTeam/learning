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
        auto it = std::prev(bidBook_.end());
        return it->first;
    }

    int BestSell() {
        auto it = sellBook_.begin();
        return it->first;
    }

    void submit(Order order);

    bool cancel(OrderID target) {
        if (orders_.find(target) == orders_.end()) {
            return false;
        }

        return true;
    }

    bool modify(OrderID target, Order order) {
        if (orders_.find(target) == orders_.end()) {
            return false;
        }
        
        return true;
    }

    private:
        Book sellBook_;
        Book bidBook_;
        std::unordered_map<OrderID, Order> orders_;
};

// Represents all orders resting at a particular price, maintaining their priority.
class PriceLevel {
public:
    Price price() const;
    Quantity totalQuantity() const;
    size_t orderCount() const;
};


// matching engine determines when an incoming order can execute against them.
class Engine {
    public:
        Engine();
        void HandleNewOrder(Order order);
};