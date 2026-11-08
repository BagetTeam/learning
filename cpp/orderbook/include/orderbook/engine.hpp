#pragma once
#include "order.hpp"
#include "ordertype.hpp"
#include "types.hpp"

// matching engine determines when an incoming order can execute against them.
class MatchingEngine {
public:
    MatchingEngine(OrderBook& book) : book_{book} {}

    void submit(Order order) {        
        switch (order.getOrderType()) {
            case OrderType::Market:
                match(order);

            case OrderType::Limit:
                match(order);
                addOrderToBook(order);

            case (OrderType::Modify):
                if (!book_.removeOrder(&order)) {
                    throw std::invalid_argument("Order does not exists, cannot modify it.");
                }
                match(order);
                addOrderToBook(order);

            case (OrderType::Cancel):
                if (!book_.removeOrder(&order)) {
                    throw std::invalid_argument("Order does not exists, cannot cancel it.");
                }
            default:
                break;
        }
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

    void addOrderToBook(Order& taker) {
        if (taker.getQuantity() <= 0) return;
        if (taker.getOrderType() != OrderType::Limit &&
                taker.getOrderType() != OrderType::Modify) return;

        if (!book_.addOrder(&taker)) {
            throw std::runtime_error("Tried adding new order to orderbook, but failed.");
        }
    }

    
private:
    OrderBook& book_;
    std::vector<Trade> trades_;
};