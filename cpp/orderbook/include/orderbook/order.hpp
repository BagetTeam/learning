#pragma once

#include <cstddef>
#include <stdexcept>
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

        OrderID getOrderId() const { return orderId_; }
        Quantity getQuantity() const { return quantity_; }
        std::optional<Price> getPrice() const { return price_; }
        Side getSide() const { return side_; }
        OrderType getOrderType() const { return orderType_; }

    private:
        OrderID orderId_;
        Side side_;
        OrderType orderType_;
        std::optional<Price> price_;
        Quantity quantity_;
};
