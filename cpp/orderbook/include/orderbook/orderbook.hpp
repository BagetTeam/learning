#pragma once

#include <optional>
#include <utility>
#include <vector>
#include "book_types.hpp"
#include "ordertype.hpp"



class OrderBook {
public:
    Order* getOrder(OrderID id) {
        auto it = orders_.find(id);
        if (it == orders_.end()) return nullptr;
        return &*(it->second.it);
    } // be mindful that if used, then we call cancel(), we have dangling pointer now
    
    bool orderExists(OrderID id) {
        return orders_.find(id) != orders_.end();
    }

    std::optional<Price> bestBidPrice() {
        if (bidBook_.empty()) return std::nullopt;
        return bidBook_.begin()->first;
    }

    std::optional<Price> bestSellPrice() {
        if (sellBook_.empty()) return std::nullopt;
        return sellBook_.begin()->first;
    }

    Order* bestBidOrder() {
        if (bidBook_.empty()) return nullptr;
        return &(bidBook_.begin()->second.orders.front());
    }

    Order* bestSellOrder() {
        if (sellBook_.empty()) return nullptr;
        return &(sellBook_.begin()->second.orders.front());
    }

    void addOrder(Order& order) {
        OrderID id = order.getOrderId();
        Price pr = order.getPrice().value();
        Side side = order.getSide();
        std::list<Order>::iterator loc_it;

        if (side == Side::Buy) {
            auto [it, _] = bidBook_.try_emplace(pr);
            loc_it = it->second.push(order);
        }
        else {
            auto [it, _] = sellBook_.try_emplace(pr);
            loc_it = it->second.push(order);
        }
        orders_.insert({id, {.side=side, .price=pr, .it=loc_it}});
    }

    void removeOrder(Order& order) {
        OrderID id = order.getOrderId();
        OrderLocation loc = orders_.find(id)->second;
        Price pr = loc.price;

        if (loc.side == Side::Buy) {
            auto it = bidBook_.find(pr);
            if (it == bidBook_.end()) {
                throw std::runtime_error("Order " + std::to_string(id) + " could not get removed");
            }
            it->second.erase(loc.it);
            if (it->second.empty()) bidBook_.erase(it);
        }
        else {
            auto it = sellBook_.find(pr);
            if (it == sellBook_.end()) {
                throw std::runtime_error("Order " + std::to_string(id) + " could not get removed");
            }
            it->second.erase(loc.it);
            if (it->second.empty()) sellBook_.erase(it);
        }

        orders_.erase(id);
    }

    std::vector<std::pair<Price, Quantity>> getDepth(Side side, int depth) {
        if (side == Side::Buy) {
            return populateDepth(bidBook_, depth);
        }
        else {
            return populateDepth(sellBook_, depth);
        }
    }

    ~OrderBook() {
        // should delete all orders, clean up memory
    }

private:
    BidBook bidBook_;
    SellBook sellBook_;
    std::unordered_map<OrderID, OrderLocation> orders_;

    
    template<typename BookTypes>
    std::vector<std::pair<Price, Quantity>> populateDepth(BookTypes& book, int depth) {
        std::vector<std::pair<Price, Quantity>> v;
        v.reserve(depth); 

        int i = 0;
        for (auto it = book.begin(); it != book.end(); it++) {
            if (i >= depth) break;             
            v.push_back({it->first, it->second.totalQuantity});
            i++;
        }
        return v;
    }

};

