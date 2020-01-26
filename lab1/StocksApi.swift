//
//  StocksApi.swift
//  lab1
//
//  Created by arek on 23/12/2019.
//  Copyright © 2019 aolesek. All rights reserved.
//

import Foundation

protocol StocksApi {
    
    func search(phrase: String, completion: @escaping (Swift.Result<[CompanyDescriptor], Error>) -> Void)
    
    func getCurrentQuote(symbol: String, completion: @escaping (Result<StockQuote, Error>) -> Void)
    
    func getLastQuotes(symbol: String, completion: @escaping (Result<[StockQuote], Error>) -> Void)
}
