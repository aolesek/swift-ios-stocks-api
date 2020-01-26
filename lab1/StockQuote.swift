//
//  StockQuote.swift
//  lab1
//
//  Created by arek on 02/01/2020.
//  Copyright © 2020 aolesek. All rights reserved.
//

import Foundation

class StockQuote {
    
    var time: String
    var symbol: String
    var open: Double
    var high: Double
    var low: Double
    var close: Double
    var volume: Int
    var change: Double
    var changePercentage: String
    
    init(time: String, symbol: String,open: Double, high: Double, low: Double, close: Double, volume: Int, change: Double, changePercentage: String) {
        self.time = time
        self.symbol = symbol
        self.open = open
        self.high = high
        self.low = low
        self.close = close
        self.volume = volume
        self.change = change
        self.changePercentage = changePercentage
    }
}
