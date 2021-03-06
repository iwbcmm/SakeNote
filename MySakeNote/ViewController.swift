//
//  ViewController.swift
//  MySakeNote
//
//  Created by 岩渕真未 on 2020/12/07.
//  Copyright © 2020 岩渕真未. All rights reserved.
//

import UIKit
import Foundation
import Alamofire
import SwiftyJSON
import SafariServices

class ViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, SFSafariViewControllerDelegate, UIAdaptivePresentationControllerDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var scrollView: UIScrollView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchBar.delegate = self
        tableView.delegate = self
        tableView.dataSource = self
        
        self.title = "マイ酒"
        
        addBtn = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.onClick))
        self.navigationItem.rightBarButtonItem = addBtn
        
        self.navigationController?.navigationBar.barTintColor = UIColor(red: 135/255, green: 206/255, blue: 235/255, alpha: 255/255)
        self.navigationController?.navigationBar.tintColor = UIColor(red: 255/255, green: 228/255, blue: 225/255, alpha: 255/255)
        self.navigationController?.navigationBar.titleTextAttributes = [ .foregroundColor: UIColor.white ]
        
        if UserDefaults.standard.stringArray(forKey: "sakeNameArray") != nil {
        allFavoritedSake()
        }
        
        navigationItem.hidesBackButton = true
    }
    
    var addBtn: UIBarButtonItem!
    var loading: Bool = false
    var searchWord: String = ""
    var sakes : [SakeModel] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    var searchResult: [SakeModel] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    var deletedSearchResult: [SakeModel] = []
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UserDefaults.standard.register(defaults: ["sakeNameArray": []])
        
        if UserDefaults.standard.stringArray(forKey: "sakeNameArray") != nil {
        allFavoritedSake()
        }
    }
    
  @objc func onClick() {
    let sakeVC = storyboard?.instantiateViewController(withIdentifier: "toSake")
    sakeVC?.hidesBottomBarWhenPushed = true
    let navigationController = UINavigationController(rootViewController: sakeVC!)
    navigationController.modalPresentationStyle = .fullScreen
    navigationController.presentationController?.delegate = self
    let transition = CATransition()
    transition.duration = 0.15
    transition.type = CATransitionType.push
    transition.subtype = CATransitionSubtype.fromRight
    view.window!.layer.add(transition, forKey: kCATransition)
    self.navigationController?.pushViewController(sakeVC!, animated: false)
    sakeVC?.hidesBottomBarWhenPushed = false
    }
    
    func allFavoritedSake() {
        
        if loadStatus == .isLoading || loadStatus == .full {
            return
        }
        
        loadStatus = .isLoading
        var getSakeArray: [String] = []
        
        if UserDefaults.standard.stringArray(forKey: "sakeNameArray") != nil {
        getSakeArray = UserDefaults.standard.array(forKey: "sakeNameArray") as? [String] ?? []
        }
        print(getSakeArray)
        
        sakes = []
        
        for i in 0 ..< getSakeArray.count {
            
            let SN = getSakeArray[i]
            print(SN)
            
            var params: [String:Any] = [:]
            params["sake_name"] = SN
            
            guard let req_url = URL(string: "https://www.sakenote.com/api/v1/sakes?token=614dec4fa2aa98801c2d9f79fb214beb5dd3c4d9") else {
                return
            }
            
            let request = AF.request(req_url, method: .get,  parameters: params, encoding: URLEncoding.default, headers: nil)
            .response { response in
                guard let data = response.data else {
                    return
                }
                do {
                    let decoder: JSONDecoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let sakej : Sakes = try JSONDecoder().decode(Sakes.self, from: data)
                    if sakej.sakes.count == 0 {
                        loadStatus = .full
                        return
                    }
                    let filteredSake = sakej.sakes.filter{ $0.sakeName == getSakeArray[i] }
                    self.sakes =  self.sakes + filteredSake
                    self.sakes.sort{
                        $0.sakeName < $1.sakeName
                    }
                    loadStatus = .loadmore
                    } catch let error {
                        print(error)
                    }
            }
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.view.endEditing(true)
        
        searchWord = ""
        
        var word: String = ""
        word = searchBar.text!
        
        if  word != "" {
            
            loadStatus = .empty
            self.searchWord = word
            searchFavoritedSakeBar(keyword: searchWord)
            
        } else {
            
            loadStatus = .empty
            allFavoritedSake()
        }
    }
//    var isFirst = true
    
    func searchFavoritedSakeBar(keyword: String){
        
        if deletedSearchResult != [] {
            searchResult = deletedSearchResult
        } else if deletedSearchResult == [] {
//            if isFirst {
//                isFirst = false
            searchResult = sakes.filter { sakes in
                return sakes.sakeName.contains(keyword)
            } as Array
        }
//        } else if keyword == "" && deletedSearchResult != [] {
//            allFavoritedSake()
//        } else if keyword == "" && deletedSearchResult == [] {
//            allFavoritedSake()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if searchWord == "" {
            return sakes.count
        } else {
            return searchResult.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if searchWord == "" {
            let cell: UITableViewCell =
            tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
            cell.textLabel!.text = sakes[indexPath.row].sakeName
            cell.detailTextLabel!.text = sakes[indexPath.row].sakeAlphabet
            return cell
        } else {
            let cell: UITableViewCell =
            tableView.dequeueReusableCell(withIdentifier: "Cell", for:
            indexPath)
            cell.textLabel!.text = searchResult[indexPath.row].sakeName
            cell.detailTextLabel!.text = searchResult[indexPath.row].sakeAlphabet
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if searchWord == "" {
            print(sakes[indexPath.row])
            tableView.deselectRow(at: indexPath, animated: true)
            let safariViewController = SFSafariViewController(url: sakes[indexPath.row].url)
            safariViewController.delegate = self
            present(safariViewController, animated: true, completion: nil)
        } else {
            print(searchResult[indexPath.row])
            tableView.deselectRow(at: indexPath, animated: true)
            let safariViewController = SFSafariViewController(url: searchResult[indexPath.row].url)
            safariViewController.delegate = self
            present(safariViewController, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath)-> UITableViewCell.EditingStyle {
           return .delete
       }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCell.EditingStyle.delete {
            
            if searchWord == "" {
                UserDefaults.standard.removeObject(forKey: sakes[indexPath.row].sakeIdentifyCode)
                
                let sakeNameArray = UserDefaults.standard.array(forKey: "sakeNameArray") as? [String] ?? []
                let fileteredSakeArray = sakeNameArray.filter { $0 != sakes[indexPath.row].sakeName }
                UserDefaults.standard.set(fileteredSakeArray, forKey: "sakeNameArray")
                
                self.sakes.remove(at: indexPath.row)
                let indexSet = NSMutableIndexSet()
                self.tableView.deleteSections(indexSet as IndexSet, with: .fade)
    
            } else {
                self.tableView.beginUpdates()
                
                UserDefaults.standard.removeObject(forKey: searchResult[indexPath.row].sakeIdentifyCode)
                
                let sakeNameArray = UserDefaults.standard.array(forKey: "sakeNameArray") as? [String] ?? []
                let fileteredSakeArray = sakeNameArray.filter { $0 != searchResult[indexPath.row].sakeName }
                UserDefaults.standard.set(fileteredSakeArray, forKey: "sakeNameArray")
  
                self.tableView.deleteRows(at: [indexPath], with: .fade)
                self.searchResult.remove(at: indexPath.row)
                
                deletedSearchResult = searchResult
                print(deletedSearchResult)
                
                if deletedSearchResult == [] {
                    allFavoritedSake()
                }
                
                self.tableView.endUpdates()

            }
        }
    }

}
