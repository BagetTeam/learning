#pragma once
#include "Order.hpp"
#include "ordertype.hpp"
#include "types.hpp"

// matching engine determines when an incoming order can execute against them.
class MatchingEngine {
public:
    MatchingEngine();

    bool submit(Order order) {
        if (!book_.orderExists(order.getOrderId())) return false;
        
        switch (order.getOrderType())
        {
        case (OrderType::Market || OrderType::Limit):
            match(order);
        case (OrderType::Modify):
            
            
        
        default:
            break;
        }
        if (order.getSide() == Side::Buy) {
            // check sell book, and fill
            if (bidBook_.fin)
            bidBook_.insert({})
        }   
        else {

        }     
        
        return true;
    }

    bool cancel(OrderID id) {

    }

    void match(Order& taker) {
        while (taker.getQuantity() > 0) {
            Order* maker = (taker.getSide() == Side::Buy) ? book_.bestSellOrder() : book_.bestBidOrder();
            if (!maker || !crosses(taker, *maker)) break;

            Quantity fill = std::min(maker->getQuantity(), taker.getQuantity());
            trades_.push_back({ maker->getOrderId(),
                                taker.getOrderId(),
                                maker->getPrice().value(),
                                fill});

            taker.removeQuantity(fill);
            maker->removeQuantity(fill);
            if (maker->getQuantity() == 0) book_.removeOrder(maker);
        }
    }

    bool crosses(Order& taker, Order& maker) {
        if (taker.getOrderType() == OrderType::Market) return true;
        Price tprice = taker.getPrice().value();
        Price mprice = maker.getPrice().value();
        return (taker.getSide() == Side::Buy) ? tprice >= mprice : tprice <= mprice ;
    }

    
private:
    OrderBook book_;
    std::vector<Trade> trades_;
};