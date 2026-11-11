#pragma once
#include "order.hpp"
#include "ordertype.hpp"
#include "types.hpp"
#include "orderbook.hpp"

// matching engine determines when an incoming order can execute against them.
class MatchingEngine {
public:
    MatchingEngine(OrderBook& book) : book_{book} {}

    void submit(Order order) {        
        OrderID id = order.getOrderId();
        Order* oldOrder = book_.getOrder(id);

        switch (order.getOrderType()) {
            case OrderType::Market:
                if (oldOrder) {
                    throw std::invalid_argument("Order already exists, cannot submit an existing order");
                }
                match(order);
                break;

            case OrderType::Limit:
                if (oldOrder) {
                    throw std::invalid_argument("Order already exists, cannot submit an existing order");
                }
                match(order);
                addOrderToBook(order);
                break;

            case (OrderType::Modify):
                if (!oldOrder) {
                    throw std::invalid_argument("Order does not exists, cannot modify it.");
                }
                book_.removeOrder(*oldOrder);
                match(order);
                addOrderToBook(order);
                break;

            case (OrderType::Cancel):
                if (!oldOrder) {
                    throw std::invalid_argument("Order does not exists, cannot cancel it.");
                }
                book_.removeOrder(*oldOrder);
                break;

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
            book_.updateOrderQuantity(*maker, fill);
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

        book_.addOrder(taker);
    }

    
private:
    OrderBook& book_;
    std::vector<Trade> trades_;
};