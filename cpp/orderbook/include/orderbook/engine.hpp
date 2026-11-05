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
        case (OrderType::Market):
            return handleMarketTrade(order);
        case (OrderType::Limit):
            
        
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
            if (!maker) break;

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

    bool crosses(Order& taker, Order& )
    Quantity handleMarketTrade(Order* order) {
        Quantity qt = order->getQuantity();
        while (qt > 0) {
            if (!fillOnBestOrder(&qt, order)) break;
        }
        return qt;
    }

    bool handleLimitTrade(Order* order) {
        Quantity qt = order->getQuantity();
        Price pr = order->getPrice().value();
        while (qt > 0 && orderCanFill(pr, order->getSide())) {
            if (!fillOnBestOrder(&qt, order)) break;
        }
    }

    
private:
    OrderBook book_;
    std::vector<Trade> trades_;
    
    bool orderCanFill(Price price, Side side) {
        if (side == Side::Buy) {
            return price >= book_.bestSellPrice();
        }
        else {
            return price <= book_.bestBidPrice();
        }
    }

    bool fillOnBestOrder(Quantity* qt, Order* order) {
        
    }
    
};