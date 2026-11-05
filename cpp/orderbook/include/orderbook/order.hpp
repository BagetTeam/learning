#pragma once

#include <cstddef>
#include <stdexcept>
#include <utility>
#include <vector>
#include <optional>
#include "ordertype.hpp"
#include "types.hpp"


class Order {
    public: 
        Order(OrderID orderId, Side side, OrderType orderType, std::optional<Price> price, Quantity quantity)
            : orderId_{orderId}
            , side_{side}
            , orderType_{orderType}
            , price_{price}
            , quantity_{quantity} 
        {
            if (quantity == 0) {
                throw std::invalid_argument("quantity needs to be greater than 0");
            }
            if ((orderType_ == OrderType::Limit || orderType_ == OrderType::Modify) 
            && !price.has_value()) {
                throw std::invalid_argument("limit or modify orders need to have a price with it");
            }
        }

        void removeQuantity(Quantity remove) {
            quantity_ -= remove;
        }

        OrderID getOrderId() { return orderId_; }
        Quantity getQuantity() { return quantity_; }
        std::optional<Price> getPrice() { return price_; }
        Side getSide() { return side_; }
        OrderType getOrderType() { return orderType_; }

        ~Order();

    private:
        OrderID orderId_;
        Side side_;
        OrderType orderType_;
        std::optional<Price> price_;
        Quantity quantity_;
};


class OrderBook {
public:
    OrderBook();

    Order* getOrder(OrderID id) {
        auto it = orders_.find(id);
        if (it == orders_.end()) return nullptr;
        return &it->second;
    } 
    
    bool orderExists(OrderID id) {
        return orders_.find(id) != orders_.end();
    }

    Price bestBidPrice() {
        return bidBook_.begin()->first;
    }

    Price bestSellPrice() {
        return sellBook_.begin()->first;
    }

    Order* bestBidOrder() {
        if (bidBook_.empty()) return nullptr;
        return getOrder(bidBook_.begin()->second.front());
    }

    Order* bestSellOrder() {
        if (bidBook_.empty()) return nullptr;
        return getOrder(sellBook_.begin()->second.front());
    }

    bool removeOrder(Order* order) {
        return true;
    }

    bool cancel(OrderID target) {
        if (!orderExists(target)) {
            return false;
        }

        return true;
    }

    bool modify(OrderID target, Order order) {
        if (!orderExists(target)) {
            return false;
        }
        
        return true;
    }

    std::vector<std::pair<Price, Quantity>> getDepth(Side side, int depth) {
        if (side == Side::Buy) {
            return populateDepth(bidBook_, depth);
        }
        else {
            return populateDepth(sellBook_, depth);
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

            Quantity qt = 0;
            for (const OrderID id: it->second) {
                qt += getOrder(id)->getQuantity();
            }      
            v.push_back({it->first, qt});
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

