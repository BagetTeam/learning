#pragma once

#include <array>
#include <cstddef>
#include <optional>
#include <iostream>
#include <stdexcept>
#include <utility>
#include <vector>
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

        void removeQuantity(Quantity remove) {
            quantity_ -= remove;
        }

        Quantity getQuantity() { return quantity_; }
        Price getPrice() { return price_; }
        Side getSide() { return side_; }
        OrderType getOrderType() { return orderType_; }

    private:
        OrderID orderId_;
        Side side_;
        OrderType orderType_;
        Price price_;
        Quantity quantity_;
};


class OrderBook {
public:
    OrderBook();

    Order* getOrder(OrderID id) {
        auto it = orders_.find(id);
        if (it == orders_.end()) return std::nullptr_t();
        return &it->second;
    } 

    Price bestBid() {
        auto it = bidBook_.begin(); 
        return it->first;
    }

    Price bestSell() {
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

    std::vector<std::pair<Price, Quantity>> getDepth(Side side, int depth) {
        if (side == Side::Buy) {
            populateDepth(bidBook_, depth);
        }
        else {
            populateDepth(sellBook_, depth);
        }
    }

private:
    BidBook bidBook_;
    SellBook sellBook_;
    std::unordered_map<OrderID, Order> orders_;

    template<typename BookTypes>
    std::vector<std::pair<Price, Quantity>> populateDepth(BookTypes& book, int depth) {
        std::vector<std::pair<Price, Quantity>> v;
        v.reserve(depth); 

        int i = 0;
        for (auto it = book.begin(); it != book.end(); it++) {
            if (i >= depth) break;

            Quantity q = 0;
            for (const OrderID id: it->second) {
                q += getOrder(id)->getQuantity();
            }      
            v.push_back({it->first, q});
            i++;
        }
        return v;
    }
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