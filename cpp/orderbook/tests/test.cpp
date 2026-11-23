#include "engine.hpp"
#include "order.hpp"
#include "orderbook.hpp"
#include "ordertype.hpp"
#include <gtest/gtest.h>
#include <optional>
#include <stdexcept>
#include <vector>


// =============================================================================
// 1. Plain tests: TEST(SuiteName, TestName)
//    Use these when each test builds everything it needs itself.
// =============================================================================

TEST(OrderTest, ConstructorStoresFields) {
    // Arrange + Act
    Order order(42, Side::Buy, OrderType::Limit, 100, 10);

    // Assert
    //   EXPECT_* records a failure and keeps going.
    //   ASSERT_* records a failure and stops this test immediately. Use it when
    //   the lines after it would crash otherwise (e.g. dereferencing).
    EXPECT_EQ(order.getOrderId(), 42u);   // 'u' suffix: avoids signed/unsigned warnings
    EXPECT_EQ(order.getSide(), Side::Buy);
    EXPECT_EQ(order.getQuantity(), 10u);
    ASSERT_TRUE(order.getPrice().has_value());
    EXPECT_EQ(*order.getPrice(), 100u);
}

TEST(OrderTest, ZeroQuantityThrows) {
    EXPECT_THROW(Order(1, Side::Buy, OrderType::Limit, 100, 0), std::invalid_argument);
}

TEST(OrderTest, LimitOrderWithoutPriceThrows) {
    EXPECT_THROW(Order(1, Side::Buy, OrderType::Limit, std::nullopt, 10), std::invalid_argument);
}

TEST(OrderTest, MarketOrderWithoutPriceIsFine) {
    EXPECT_NO_THROW(Order(1, Side::Buy, OrderType::Market, std::nullopt, 10));
}

// =============================================================================
// 2. Fixture tests: TEST_F(FixtureClass, TestName)
//    Use these when many tests share the same starting state. gtest builds a
//    brand-new fixture object for every TEST_F, so tests can't affect each other.
// =============================================================================

class OrderBookTest : public ::testing::Test {
protected:
    // Members are created in this order, so `book` exists before `engine` binds to it.
    OrderBook book;
    MatchingEngine engine{book};

    // Runs before each TEST_F. (There's also TearDown() for cleanup after each one.)
    void SetUp() override {
        // Bids: 100 -> [#1:10, #2:20, #4:10] (total 40),  99 -> [#3:50]
        engine.submit(Order(1, Side::Buy, OrderType::Limit, 100, 10));
        engine.submit(Order(2, Side::Buy, OrderType::Limit, 100, 20));
        engine.submit(Order(3, Side::Buy, OrderType::Limit, 99, 50));
        engine.submit(Order(4, Side::Buy, OrderType::Limit, 100, 10));

        // Sells: 101 -> [#5:40, #7:80] (total 120),  102 -> [#8:50],  105 -> [#6:500]
        engine.submit(Order(5, Side::Sell, OrderType::Limit, 101, 40));
        engine.submit(Order(6, Side::Sell, OrderType::Limit, 105, 500));
        engine.submit(Order(7, Side::Sell, OrderType::Limit, 101, 80));
        engine.submit(Order(8, Side::Sell, OrderType::Limit, 102, 50));
    }
};

TEST_F(OrderBookTest, InitialBookState) {
    EXPECT_EQ(book.bestBidPrice(), 100u);
    EXPECT_EQ(book.bestSellPrice(), 101u);

    // Compare whole containers in one go. Wrap braced initializers in
    // parentheses, or the commas inside them confuse the macro.
    EXPECT_EQ(book.getDepth(Side::Buy, 5), (Depth{{100, 40}, {99, 50}}));
    EXPECT_EQ(book.getDepth(Side::Sell, 2), (Depth{{101, 120}, {102, 50}}));
}

TEST_F(OrderBookTest, AddingBidOrders) {
    Order order(123, Side::Buy, OrderType::Limit, 100, 10);
    book.addOrder(order);

    EXPECT_TRUE(book.orderExists(123));
    EXPECT_EQ(book.getDepth(Side::Buy, 1), (Depth{{100, 50}}));
}

TEST_F(OrderBookTest, AddingSellOrders) {
    Order order(124, Side::Sell, OrderType::Limit, 103, 5);
    book.addOrder(order);

    EXPECT_TRUE(book.orderExists(124));
    EXPECT_EQ(book.getDepth(Side::Sell, 3), (Depth{{101, 120}, {102, 50}, {103, 5}}));
}

TEST_F(OrderBookTest, CrossingBuyFillsInTimePriority) {
    // Buy 50 @ 101 -> takes all 40 from #5 (first in line), then 10 from #7.
    engine.submit(Order(200, Side::Buy, OrderType::Limit, 101, 50));

    EXPECT_FALSE(book.orderExists(5));
    Order* seven = book.getOrder(7);
    ASSERT_NE(seven, nullptr);           // stop here if null, so the next line can't crash
    EXPECT_EQ(seven->getQuantity(), 70u);
    EXPECT_FALSE(book.orderExists(200)); // fully filled, so nothing rests
}

TEST_F(OrderBookTest, CancelRemovesOrderAndEmptyLevel) {
    engine.submit(Order(3, Side::Buy, OrderType::Cancel, std::nullopt, 1));

    EXPECT_FALSE(book.orderExists(3));
    EXPECT_EQ(book.getDepth(Side::Buy, 5), (Depth{{100, 40}}));
}

TEST_F(OrderBookTest, SubmittingDuplicateIdThrows) {
    EXPECT_THROW(engine.submit(Order(1, Side::Buy, OrderType::Limit, 98, 5)),
                 std::invalid_argument);
}

TEST_F(OrderBookTest, InitialTrades) {
    std::vector<Trade> trades = engine.getTrades();
    std::vector<Trade> expected = {};
    EXPECT_EQ(trades,expected);
}

TEST_F(OrderBookTest, TradesWithMarket) {
    std::vector<Trade> trades = engine.getTrades();

    engine.submit(Order(9, Side::Sell, OrderType::Limit, 100, 30));
    engine.submit(Order(10, Side::Sell, OrderType::Market, std::nullopt, 40));

    std::vector<Trade> expectedTrades = {
        {1, 9, 100, 10},
        {2, 9, 100, 20},
        {4, 10, 100, 10},
        {3, 10, 99, 30}
    };
    EXPECT_EQ(trades,expectedTrades);
}

TEST_F(OrderBookTest, TradesWithPartialFill) {
    std::vector<Trade> trades = engine.getTrades();

    engine.submit(Order(9, Side::Sell, OrderType::Limit, 100, 10));
    engine.submit(Order(10, Side::Sell, OrderType::Limit, 100, 40));

    std::vector<Trade> expectedTrades = {
        {1, 9, 100, 10},
        {2, 10, 100, 20},
        {4, 10, 100, 10}
    };
    EXPECT_EQ(trades,expectedTrades);
}