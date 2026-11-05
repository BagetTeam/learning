#pragma once
#include "Order.hpp"
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
            if (order.getSide() == Side::Buy) {
                handleMarketBuy(order);
            }
            else {
                handleMarketSell(order);
            }
        
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

    Price handleMarketBuy(Order order) {
        Quantity qt = order.getQuantity();
        while (qt > 0) {
            Order* best_sell = book_.bestSellOrder();
            Quantity sell_qt = best_sell->getQuantity();
            if (qt >= sell_qt) {
                book_.removeOrder(best_sell);
                
            }
        }

    }

    
    
    
    bool handleMarketSell() {
        
    }
    
    bool handleLimitBuy() {
        
    }
    
    bool handleLimitSell() {
        
    }
    
private:
    OrderBook book_;
    

    
};