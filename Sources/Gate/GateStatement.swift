import Foundation

public struct GateStatement {
    public let transactions: [GateTransaction]
    public let trades: [GateTrade]

    public init(rows: [GateBillingRow]) throws {
        let orders = Dictionary(grouping: rows, by: { $0.orderID })

        self.transactions = try orders.compactMap(Self.transformToTransaction)
        self.trades = try orders.flatMap(Self.transformToTrades)
    }

    static func transformToTransaction(order: String, rows: [GateBillingRow]) throws -> GateTransaction? {
        guard let firstRow = rows.first else {
            throw "Order \(order) has no rows, orders should have at least one row"
        }

        switch (rows.count, firstRow.type) {
        case (1, .withdraw):
            return try GateTransaction(row: firstRow)
        case (1, .deposit):
            return try GateTransaction(row: firstRow)
        case (1, .airdropBonus):
            return try GateTransaction(row: firstRow)
        case (_, .tradingFee), (_, .orderFulfilled), (_, .orderCancelled), (_, .orderPlaced):
            return nil
        case (_, .withdraw), (_, .deposit), (_, .airdropBonus):
            throw "Order with type \(firstRow.type) should have only one row"
        }
    }

    static func transformToTrades(order: String, rows: [GateBillingRow]) throws -> [GateTrade] {
        guard let firstRow = rows.first else {
            throw "Order \(order) has no rows, orders should have at least one row"
        }

        switch (rows.count, firstRow.type) {
        case (_, .withdraw), (_, .deposit), (_, .airdropBonus):
            return []
        case (_, .orderPlaced), (_, .orderFulfilled), (_, .orderCancelled), (_, .tradingFee):
            return rows
                // group rows per trade
                .reduce(into: [[GateBillingRow]]()) { rowGroups, row in
                    var group = rowGroups.popLast() ?? [GateBillingRow]()
                    group.append(row)
                    rowGroups.append(group)

                    if row.type == .orderPlaced {
                        rowGroups.append([GateBillingRow]())
                    }
                }
                .compactMap(GateTrade.init)
        }
    }
}

extension GateTransaction {

    init(row: GateBillingRow) throws {
        let type: TransactionType

        switch row.type {
        case .withdraw:
            type = .withdrawal
        case .deposit:
            type = .deposit
        case .airdropBonus:
            type = .airdrop
        default:
            throw "Invalid row type \(row.type) for direct conversion"
        }

        self.init(
            type: type,
            date: row.date,
            amount: row.amount,
            currency: row.currency
        )
    }
}

extension GateTrade {

    init?(rows: [GateBillingRow]) {
        guard !rows.isEmpty, Set(rows.map(\.orderID)).count == 1 else {
            return nil
        }

        let rowsByType = Dictionary(grouping: rows, by: { $0.type })

        guard Set(rowsByType.keys).isSubset(of: Set([.orderPlaced, .orderFulfilled, .tradingFee])),
              let orderPlaced = rowsByType[.orderPlaced]?.first,
              let orderFulfilled = rowsByType[.orderFulfilled]?.first
        else {
            return nil
        }

        let sellAmount = rowsByType[.orderPlaced, default: []].reduce(0, { $0 + $1.amount })
        let sellCurrency = orderPlaced.currency

        let buyAmount = rowsByType[.orderFulfilled, default: []].reduce(0, { $0 + $1.amount })
        let buyCurrency = orderFulfilled.currency

        let feeAmount = rowsByType[.tradingFee, default: []].reduce(0, { $0 + $1.amount })
        let feeCurrency = rowsByType[.tradingFee]?.first?.currency ?? ""

        self.init(
            date: orderFulfilled.date,
            buyAmount: buyAmount - feeAmount,
            buyCurrency: buyCurrency,
            sellAmount: sellAmount,
            sellCurrency: sellCurrency,
            fee: feeAmount,
            feeCurrency: feeCurrency
        )
    }
}
