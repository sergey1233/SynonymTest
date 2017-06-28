import UIKit
import Alamofire
import SwiftyJSON
import GRDB

class FindViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var word: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    //    static let PUBLIC_KEY = "648b5882e6f9f7a05a74727c7cfcf182";
    static let START_REQUEST = "http://words.bighugelabs.com/api/2/648b5882e6f9f7a05a74727c7cfcf182/"
    static let END_REQUEST = "/json"
    var synonymArray: [String] = []
    var path = ""
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(FindViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
        path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        do {
            let dbQueue = try DatabaseQueue(path: "\(path)/database.sqlite")
            try dbQueue.inDatabase { db in
                
//                try db.execute("DROP TABLE WORDS")
                try db.execute(
                    "CREATE TABLE IF NOT EXISTS WORDS (" +
                        "word TEXT NOT NULL, " +
                        "synonyms TEXT NOT NULL" +
                    ")")
                }
            
        } catch {
            print(error)
        }

    }
    
    //TABLEVIEW func
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let synonymArrayCount = synonymArray.count
        
        return synonymArrayCount
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 40
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        cell.textLabel?.text = self.synonymArray[(indexPath as NSIndexPath).row]
        
        return cell
        
    }
    
    @IBAction func tapFindButton(_ sender: Any) {
        dismissKeyboard()
        requestSynonym()
    }
    
    func requestSynonym() {
        let req = FindViewController.START_REQUEST + word.text! + FindViewController.END_REQUEST
        
        Alamofire.request(req).responseJSON { response in
//            print("Request: \(String(describing: response.request))")   // original url request
//            print("Response: \(String(describing: response.response))") // http url response
//            print("Result: \(response.result)")                         // response serialization result
            
            self.synonymArray.removeAll()
            
            if let data = response.data {
                let jsonData = JSON(data)
                
                if jsonData["noun"]["syn"] != JSON.null {
                    let numberNoun = jsonData["noun"]["syn"].array!.count
                    for i in 0..<numberNoun {
                        self.synonymArray.append(jsonData["noun"]["syn"].array![i].string!)
                    }
                }
                
                if jsonData["verb"]["syn"] != JSON.null {
                    let numberVerb = jsonData["verb"]["syn"].array!.count
                    for i in 0..<numberVerb {
                        self.synonymArray.append(jsonData["verb"]["syn"].array![i].string!)
                    }
                }
                
                if jsonData["adjective"]["syn"] != JSON.null {
                    let numberAdj = jsonData["adjective"]["syn"].array!.count
                    for i in 0..<numberAdj {
                        self.synonymArray.append(jsonData["adjective"]["syn"].array![i].string!)
                    }
                }
            }

            if self.synonymArray.count != 0 {
                self.updateDB()
            }
            else {
                self.findInDB()
            }
            
        }
    }
    
    func updateDB() {
        do {
            let dbQueue = try DatabaseQueue(path: "\(path)/database.sqlite")
            var needInsert = true
            
            //check if word is already in DB
            try dbQueue.inDatabase { db in
                let rows = try Row.fetchCursor(db, "SELECT * FROM WORDS")
                while let row = try rows.next() {
                    let wordFromDB: String = row.value(named: "word")
                    if self.word.text! == wordFromDB {
                        needInsert = false
                    }
                }
                
            }
            
            if needInsert {
                let synonymsOneWord = self.synonymArray.joined(separator: ",")
                
                try dbQueue.inDatabase { db in
                    try db.execute(
                        "INSERT INTO WORDS (word, synonyms) " +
                        "VALUES (?, ?)",
                        arguments: [self.word.text!, synonymsOneWord])
                }
            }
        } catch {
            print(error)
        }
        self.updateView()
    }
    
    func findInDB() {
        do {
            let dbQueue = try DatabaseQueue(path: "\(path)/database.sqlite")
            try dbQueue.inDatabase { db in
                let rows = try Row.fetchCursor(db, "SELECT * FROM WORDS")
                while let row = try rows.next() {
                    let word: String = row.value(named: "word")
                    if self.word.text! == word {
                        let synonym: String = row.value(named: "synonyms")
                        self.synonymArray = synonym.components(separatedBy: ",")
                        break
                    }
                }
            }

        } catch {
            print(error)
        }
        self.updateView()
    }
    
    func updateView() {
        self.tableView.reloadData()
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
}

