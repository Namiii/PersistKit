import UIKit
import PersistKit

class ListViewModel {
    lazy var db: Database = ListViewModel.loadDatabase()

    private(set) var todoItems: [TodoItem] = []

    init() {
        todoItems = db.loadAll()
    }

    func add(item: TodoItem) {
        print("adding item")
        db.save(item)
        todoItems = db.loadAll()
    }

    private static func loadDatabase() -> Database {
        print("loading database...")
        guard let dir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
            fatalError("could not access the filesystem")
        }

        let dbPath = URL(fileURLWithPath: dir).appendingPathComponent("mydb.sqlite3").absoluteString
        guard let db = Database(filename: dbPath) else {
            fatalError("failed to initialize the database")
        }

        db.ensureInitialized()
        print("initialized database at: \(dbPath)")
        return db
    }
}
