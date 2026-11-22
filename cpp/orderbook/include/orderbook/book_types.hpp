#pragma once
#include "order.hpp"
#include "ordertype.hpp"
#include <list>
#include <map>


struct OrderLocation {
    Side side;
    Price price;
    std::list<Order>::iterator it;
};

// Represents all orders resting at a particular price, maintaining their priority.
struct PriceLevel {
    std::list<Order> orders; // would be a linked list for better efficiency when cancelling
    Quantity totalQuantity = 0;
    
    std::list<Order>::iterator push(Order order) {
        totalQuantity += order.getQuantity();
        return orders.insert(orders.end(), order);
    }

    void erase(std::list<Order>::iterator it) {
        totalQuantity -= it->getQuantity();
        orders.erase(it);
    }

    void reduce(std::list<Order>::iterator it, Quantity q) {
        it->removeQuantity(q);
        totalQuantity -= q;
    };

    bool empty() const { return orders.empty(); };
};


using BidBook = std::map<Price, PriceLevel, std::greater<int>>; //sorted keys descending
using SellBook = std::map<Price, PriceLevel>; //sorted keys ascending

using Depth = std::vector<std::pair<Price, Quantity>>;

