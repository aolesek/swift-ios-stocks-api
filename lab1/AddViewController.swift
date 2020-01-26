//
//  AddViewController.swift
//  lab1
//
//  Created by arek on 23/12/2019.
//  Copyright © 2019 aolesek. All rights reserved.
//

import UIKit
import Alamofire
import LinearProgressBarMaterial

class AddViewController: UIViewController, UITableViewDataSource, UITextFieldDelegate, UITableViewDelegate {
    
    //MARK: Properties
    
    @IBOutlet weak var tableView: UITableView!
    
    @IBOutlet weak var phraseTextField: UITextField!
    
    @IBAction func performSearchButton(_ sender: Any) {
        self.performSearch(textField: phraseTextField)
        phraseTextField.resignFirstResponder()
    }
    
    let linearBar: LinearProgressBar = LinearProgressBar()
    
    private var data: [CompanyDescriptor] = []
    
    var master: MasterViewController?
    
    private var api: StocksApi = AlphaVantageApi()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.dataSource = self
        tableView.delegate = self
        self.tableView.allowsMultipleSelection = true
        
        phraseTextField.delegate = self
    }
    
    func performSearch(textField: UITextField) {
        if let text = textField.text {
            self.linearBar.startAnimation()
            api.search(phrase: text) { result in
                if let validResults = try? result.get() {
                    self.data.removeAll();
                    self.data.append(contentsOf: validResults)
                    self.tableView?.reloadData()
                }
                self.linearBar.stopAnimation()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        
        if self.isMovingFromParent {
            if let mvc = master {
                for n in 0...data.count {
                    let maybeCell = self.tableView.cellForRow(at: IndexPath(row: n, section: 0))
                    if let cell = maybeCell {
                        if cell.isSelected {
                            mvc.userSavedDescriptors.append(self.data[n])
                        }
                    }
                }
                mvc.tableView?.reloadData()
            }
        }
    }
    
    //MARK: UITableViewDataSource
    
    func numberOfSections(in tableView:UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")!
        
        let descriptor = data[indexPath.row]
        
        cell.textLabel?.text = descriptor.name
        cell.detailTextLabel?.text = descriptor.symbol
        
        return cell
    }
       
    //MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()        // Hide the keyboard.
        return true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.performSearch(textField: textField)
    }
    
}
