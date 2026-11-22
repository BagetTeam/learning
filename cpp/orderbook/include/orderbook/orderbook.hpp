#pragma once

#include <list>
#include <optional>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>
#include "book_types.hpp"
#include "ordertype.hpp"
#include "types.hpp"



class OrderBook {
public:
    std::optional<std::list<Order>::iterator> getOrderIt(OrderID id) {
        auto it = orders_.find(id);
        if (it == orders_.end()) return std::nullopt;
        return it->second.it;
    }

    Order* getOrder(OrderID id) {
        auto it = getOrderIt(id);
        if (!it.has_value()) return nullptr;
        auto orderIt = it.value();
        return &(*orderIt);
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

    void removeOrder(OrderID id) {
        auto locIt = orders_.find(id);
        if (locIt == orders_.end()) 
            throw std::invalid_argument("Order " + std::to_string(id) + " does not exist");
        
        if (locIt->second.side == Side::Buy)
            removeInBook(bidBook_, locIt, id);
        else removeInBook(sellBook_, locIt, id);
    }

    void updateOrderQuantity(OrderID id, Quantity remove) {
        auto locIt = orders_.find(id);
        if (locIt == orders_.end()) 
            throw std::invalid_argument("Order " + std::to_string(id) + " does not exist");
        
        if (remove > locIt->second.it->getQuantity())
            throw std::runtime_error("Removing more quantity than what exists");
        
        if (locIt->second.side == Side::Buy) reduceInBook(bidBook_, locIt, id, remove);
        else reduceInBook(sellBook_, locIt, id, remove);
    }

    Depth getDepth(Side side, int depth) {
        if (side == Side::Buy) {
            return populateDepth(bidBook_, depth);
        }
        else {
            return populateDepth(sellBook_, depth);
        }
    }

    // ~OrderBook() {
    //     // should delete all orders, clean up memory
    // }

private:
    BidBook bidBook_;
    SellBook sellBook_;
    std::unordered_map<OrderID, OrderLocation> orders_;

    template<typename BookTypes>
    Depth populateDepth(BookTypes& book, int depth) {
        Depth v;
        v.reserve(depth); 
        
        int i = 0;
        for (auto it = book.begin(); it != book.end(); it++) {
            if (i >= depth) break;             
            v.push_back({it->first, it->second.totalQuantity});
            i++;
        }
        return v;
    }

    template<typename Book>
    void orderDelete(Book& book, typename Book::iterator it, std::unordered_map<OrderID, OrderLocation>::iterator locIt) {
        auto& loc = locIt->second;
        it->second.erase(loc.it);
        if (it->second.empty()) book.erase(it);
        orders_.erase(locIt);
    }

    template<typename Book>
    void removeInBook(Book& book, std::unordered_map<OrderID, OrderLocation>::iterator locIt, OrderID id) {
        auto &loc = locIt->second;
        auto it = book.find(locIt->second.price);
        if (it == book.end()) {
            throw std::runtime_error("Order " + std::to_string(id) + " could not get removed");
        }
        orderDelete(book, it, locIt);
    }

    template<typename Book>
    void reduceInBook(Book& book, std::unordered_map<OrderID, OrderLocation>::iterator locIt, OrderID id, Quantity remove) {
        auto& loc = locIt->second;
        auto it = book.find(loc.price);
        if (it == book.end()) {
            throw std::runtime_error("Order " + std::to_string(id) + " exists but isn't in book");
        }
        it->second.reduce(loc.it, remove);
        if (loc.it->getQuantity() == 0) {
            orderDelete(book, it, locIt);
        }
    }

};

