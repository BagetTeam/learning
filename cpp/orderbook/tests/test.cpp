#include "engine.hpp"
#include "order.hpp"
#include <array>
#include <gtest/gtest.h>

OrderBook makeTestBook() {
    OrderBook orderBook = OrderBook();
    Order* bidOrder1 = new Order(1, Side::Buy, OrderType::Limit, 100, 10);
    Order* bidOrder2 = new Order(2, Side::Buy, OrderType::Limit, 100, 20);
    Order* bidOrder3 = new Order(3, Side::Buy, OrderType::Limit, 99, 50);
    Order* bidOrder4 = new Order(4, Side::Buy, OrderType::Limit, 100, 10);

    Order* sellOrder1 = new Order(5, Side::Sell, OrderType::Limit, 101, 40);
    Order* sellOrder2 = new Order(6, Side::Sell, OrderType::Limit, 105, 500);
    Order* sellOrder3 = new Order(7, Side::Sell, OrderType::Limit, 101, 80);
    Order* sellOrder4 = new Order(8, Side::Sell, OrderType::Limit, 102, 50);

    std::array<Order*, 8> orders = {
        bidOrder1, bidOrder2, bidOrder3, bidOrder4,
        sellOrder1, sellOrder2, sellOrder3, sellOrder4
    };

    MatchingEngine engine = MatchingEngine(orderBook);
    for (Order* order : orders) {
        engine.submit(*order);
    }
    return orderBook;
}

TEST (AddingOrders, AddingBidOrders) {
    OrderBook orderBook = makeTestBook();
    Order newOrder = Order(123, Side::Buy, OrderType::Limit, 100, 10);
    orderBook.addOrder(newOrder);
}


TEST (AddingOrders, AddingSellOrders) {
    
}