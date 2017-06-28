import UIKit
import GRDB

class HistoryTableViewController: UITableViewController {

    var wordArray: [String] = []
    var path = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getAllWordsWasFound()
        self.tableView.reloadData()
    }
    
    func getAllWordsWasFound() {
        wordArray.removeAll()
        path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        do {
            let dbQueue = try DatabaseQueue(path: "\(path)/database.sqlite")
            try dbQueue.inDatabase { db in
                let rows = try Row.fetchCursor(db, "SELECT * FROM WORDS")
                while let row = try rows.next() {
                    let word: String = row.value(named: "word")
                    wordArray.append(word)
                }
            }
            
        } catch {
            print(error)
        }

    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return wordArray.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = wordArray[(indexPath as NSIndexPath).row]

        return cell
    }
}
