#pragma once

#include <string>
#include <iostream>
#include <stdexcept>
#include <ordertype.hpp>
#include <types.hpp>


class Order {
    public: 
        Order(OrderID orderId, Side side, OrderType orderType, Price price, Quantity quantity, Sequence sequenceNumber)
            : orderId_{orderId}
            , side_{side}
            , orderType_{orderType}
            , price_{price}
            , quantity_{quantity} 
            , sequenceNumber_{sequenceNumber}
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
        Sequence sequenceNumber_;
};
