//
//  DetailViewController.swift
//  lab1
//
//  Created by arek on 23/12/2019.
//  Copyright © 2019 aolesek. All rights reserved.
//

import UIKit
import LinearProgressBarMaterial
import Charts

extension String {
    func usd() -> String {
        return self + " USD"
    }
}

class DetailViewController: UIViewController, UITableViewDataSource {
    
    // MARK: Outlets
    
    @IBOutlet weak var company: UILabel!
    
    @IBOutlet weak var symbol: UILabel!
    
    @IBOutlet weak var percentage: UILabel!
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var chart: CandleStickChartView!
    
    //MARK: Properties
    
    private var api: StocksApi = AlphaVantageApi()
    
    let linearBar: LinearProgressBar = LinearProgressBar()
    
    //MARK: Properties setters/getters
    
    var currentQuote: StockQuote? { // current price is in close field
        didSet {
            tableView?.reloadData()
        }
    }
    
    var detailItem: CompanyDescriptor? {
        didSet {
            configureView()
        }
    }
    
    var quotes: [StockQuote] = []
    
    func configureView() {
        
        // Update the user interface for t  he detail item.
        if let detail = detailItem {
            if let companyLabel = company {
                companyLabel.text = detail.name
            }
            if let symbolLabel = symbol {
                symbolLabel.text = detail.symbol
            }
        }
        
        tableView?.dataSource = self
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        fillChart()
        
        if let company = detailItem {
            self.linearBar.startAnimation()
            api.getCurrentQuote(symbol: company.symbol ) { result in
                if let quote = try? result.get() {
                    self.currentQuote = quote
                    self.tableView?.reloadData()
                    if let perc = self.percentage {
                        perc.text = quote.changePercentage
                    }
                }
                self.linearBar.stopAnimation()
                
                self.fillChart();
            }
            
        }
    }
    
    //MARK: UITableViewDataSource
    
    func numberOfSections(in tableView:UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 5
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "QuoteCell")!
        cell.textLabel?.text = ""
        cell.detailTextLabel?.text = ""
        if let quote = currentQuote {
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Open"
                cell.detailTextLabel?.text = String(quote.open).usd()
            case 1:
                cell.textLabel?.text = "High"
                cell.detailTextLabel?.text = String(quote.high).usd()
            case 2:
                cell.textLabel?.text = "Low"
                cell.detailTextLabel?.text = String(quote.low).usd()
            case 3:
                cell.textLabel?.text = "Price"
                cell.detailTextLabel?.text = String(quote.close).usd()
            case 4:
                cell.textLabel?.text = "Change"
                cell.detailTextLabel?.text = String(quote.change).usd()
            case 5:
                cell.textLabel?.text = "Volume"
                cell.detailTextLabel?.text = String(quote.volume)
            default:
                return cell
            }
            return cell
        } else {
            return cell
        }
    }
    
    //MARK: Chart
    
    func fillChart() {
        if let quote = detailItem {
            self.linearBar.startAnimation()
            api.getLastQuotes(symbol: quote.symbol ) { result in
                if let quotes = try? result.get() {
                    self.quotes = Array(quotes.prefix(10))
                    self.createChartContents()
                }
                self.linearBar.stopAnimation()
            }
        }
    }
    
    func createChartContents() {
        if (quotes.isEmpty) {
            NSLog("Quotes list for chart is empty!")
            return
        }
        
        var number = 0.0;
        let entries =
            quotes.map { (quote) -> CandleChartDataEntry in
                let ccde = CandleChartDataEntry(x: number, shadowH: quote.low, shadowL: quote.high, open: quote.open, close: quote.close)
                number += 1.0
                return ccde
        }
        
        chart.xAxis.valueFormatter = XAxisNameFormater(quotes: self.quotes)
        chart.xAxis.granularity = 1.0
        let chartDataSet = CandleChartDataSet(entries: entries, label: detailItem!.symbol)
        
        var  colors: [UIColor] = []
        colors.append(UIColor.blue)
        
        chartDataSet.colors = colors
        
        
        let chartData = CandleChartData(dataSet: chartDataSet)
        
        chart.data = chartData
    }
    
    final class XAxisNameFormater: NSObject, IAxisValueFormatter {
        
        private var quotes: [StockQuote]
        
        init(quotes: [StockQuote]) {
            self.quotes = quotes
        }
        
        func stringForValue( _ value: Double, axis _: AxisBase?) -> String {
            let intValue = Int(value)
            let quote = self.quotes[intValue]
            return quote.time
        }
    }
}
