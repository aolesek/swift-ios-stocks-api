//
//  AlphaVantageApi.swift
//  lab1
//
//  Created by arek on 23/12/2019.
//  Copyright © 2019 aolesek. All rights reserved.
//

import Foundation
import Alamofire

extension String {
    func toDouble() -> Double {
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale(identifier: "en_US_POSIX")
        return numberFormatter.number(from: self)?.doubleValue ?? 0.0
    }
    
    func toInt() -> Int {
        let numberFormatter = NumberFormatter()
        numberFormatter.locale = Locale(identifier: "en_US_POSIX")
        return numberFormatter.number(from: self)?.intValue ?? 0
    }
}

class AlphaVantageApi : StocksApi {
    
    //MARK: Constants
    let API_URL = "https://www.alphavantage.co/"
    let SEARCH_PATH = "query?function=SYMBOL_SEARCH"
    let QUOTE_PATH = "query?function=GLOBAL_QUOTE"
    let LAST_QUOTES = "query?function=TIME_SERIES_DAILY"
    
    //MARK: Properites
    var apiKey: String?;
    
    init () {
        self.apiKey = nil;
        
        if let path = Bundle.main.path(forResource: "avapi", ofType: "txt")
        {
            let fm = FileManager()
            let exists = fm.fileExists(atPath: path)
            if(exists){
                let content = fm.contents(atPath: path)
                let contentAsString = String(data: content!, encoding: String.Encoding.utf8)
                if let validApiKey = contentAsString {
                    self.apiKey = validApiKey.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            } else {
            }
        } else {
        }
        
        NSLog("Api key determined as: " + (self.apiKey ?? "undefined"))
    }
    
    func search(phrase: String, completion: @escaping (Result<[CompanyDescriptor], Error>) -> Void) {
        let key = apiKey ?? "keyNotFound";
        let query = API_URL + SEARCH_PATH + "&keywords=" + phrase + "&apikey=" + key;
        AF.request(query as String).validate()
            .responseJSON { response in
                switch response.result {
                case .success(let JSON):
                    let response = JSON as! NSDictionary
                    let result: [CompanyDescriptor] = self.deserializeSearchResult(response: response.object(forKey: "bestMatches") as! NSArray)
                    completion(.success(result))
                case .failure(_):
                    NSLog("Unable to fetch descriptors!")
                    completion(.failure(response.error!))
                    break
                }
        }
    }
    
    func deserializeSearchResult(response: NSArray) -> [CompanyDescriptor] {
        var result: [CompanyDescriptor] = []
        response.forEach { (element) in
            if let dict = element as? NSDictionary {
                let symbol = dict.value(forKey: "1. symbol")
                let name = dict.value(forKey: "2. name")
                
                if let eSymbol = symbol as? String, let eName = name as? String {
                    result.append(CompanyDescriptor(name: eName, symbol: eSymbol))
                }
            }            
        }
        return result
    }
    
    func getCurrentQuote(symbol: String, completion: @escaping (Result<StockQuote, Error>) -> Void) {
        let key = apiKey ?? "keyNotFound";
        let query = API_URL + QUOTE_PATH + "&symbol=" + symbol + "&apikey=" + key;
        AF.request(query as String).validate()
            .responseJSON { response in
                switch response.result {
                case .success(let JSON):
                    let response = JSON as! NSDictionary
                    do {
                        if let resTimSer = response.object(forKey: "Global Quote") as? NSDictionary {
                            let result: StockQuote =  try self.deserializeCurrentQuote(response: )(resTimSer )
                            completion(.success(result))
                            
                        } else {
                            let t = type(of:response.object(forKey: "Global Quote"))
                            NSLog("Deserialization error! query: '\(query)' of type '\(t)'")
                            completion(.failure(ApiError.unableToDeserializeCurrentQuote))
                        }
                        //
                        //                        let result: StockQuote =  try self.deserializeCurrentQuote(response: )
                        //                        completion(.success(result))
                    } catch let error as NSError {
                        completion(.failure(error))
                    }
                case .failure(_):
                    NSLog("Unable to fetch current quote!")
                    completion(.failure(response.error!))
                    break
                }
        }
    }
    
    func deserializeCurrentQuote(response: NSDictionary) throws -> StockQuote {
        if let symbol = response.value(forKey: "01. symbol") as? String,
            let open = response.value(forKey: "02. open") as? String,
            let high = response.value(forKey: "03. high")  as? String,
            let low = response.value(forKey: "04. low") as? String,
            let price = response.value(forKey: "05. price") as? String,
            let volume = response.value(forKey: "06. volume") as? String,
            let change = response.value(forKey: "09. change") as? String,
            let percent = response.value(forKey: "10. change percent") as? String {
            
            return StockQuote(time: "current", symbol: symbol, open: open.toDouble(), high: high.toDouble(), low: low.toDouble(), close: price.toDouble(), volume: volume.toInt(), change: change.toDouble(), changePercentage: percent )
        }
        
        throw ApiError.unableToDeserializeCurrentQuote
    }
    
    func getLastQuotes(symbol: String, completion: @escaping (Result<[StockQuote], Error>) -> Void) {
        let key = apiKey ?? "keyNotFound";
        let query = API_URL + LAST_QUOTES + "&symbol=" + symbol + "&apikey=" + key;
        AF.request(query as String).validate()
            .responseJSON { response in
                switch response.result {
                case .success(let JSON):
                    let response = JSON as! NSDictionary
                    do {
                        if let resTimSer = response.object(forKey: "Time Series (Daily)") as? NSDictionary {
                            let result: [StockQuote] =  try self.deserializeLastQuotes(symbol: symbol, response:resTimSer )
                            completion(.success(result))
                            
                        } else {
                            let t = type(of:response.object(forKey: "Time Series (Daily)"))
                            NSLog("Deserialization error! query: '\(query)' of type '\(t)'")
                            
                            completion(.failure(ApiError.unableToDeserializeCurrentQuote))
                        }
                    } catch let error as NSError {
                        completion(.failure(error))
                    }
                case .failure(_):
                    NSLog("Unable to fetch current quote!")
                    completion(.failure(response.error!))
                    break
                }
        }
    }
    
    func deserializeLastQuotes(symbol: String, response: NSDictionary) throws -> [StockQuote] {
        var quotes: [StockQuote] = []
        response.forEach { (r) in
            if let key = r.key as? String {
                do {
                    let result: StockQuote =  try self.deserializeLastQuote(time: key, symbol: symbol, response: r.value as! NSDictionary)
                    quotes.append(result)
                } catch _ as NSError {
                    NSLog("An error occured while deserializing quote")
                }
            }
        }
        return quotes;
    }
    
    func deserializeLastQuote(time: String, symbol: String, response: NSDictionary) throws -> StockQuote {
        if  let open = response.value(forKey: "1. open") as? String,
            let high = response.value(forKey: "2. high")  as? String,
            let low = response.value(forKey: "3. low") as? String,
            let price = response.value(forKey: "4. close") as? String,
            let volume = response.value(forKey: "5. volume") as? String {
            
            return StockQuote(time: time, symbol: symbol, open: open.toDouble(), high: high.toDouble(), low: low.toDouble(), close: price.toDouble(), volume: volume.toInt(), change: 0.0, changePercentage: "?" )
        }
        
        throw ApiError.unableToDeserializeCurrentQuote
    }
    
    enum ApiError: Error {
        case unableToDeserializeCurrentQuote
    }
    
}
