import Foundation
import SQLite3

protocol Statement {
    var sql: String { get }
    func bindTo(statement: OpaquePointer?) -> Bool
}

struct CreateStatement: Statement {
    let sql: String = """
        CREATE TABLE IF NOT EXISTS data (
            identifier TEXT PRIMARY KEY UNIQUE NOT NULL,
            kind       TEXT NOT NULL,
            flags      INTEGER NOT NULL,
            content    BLOB NOT NULL
        );

        CREATE INDEX data_identifier_pkey ON data (identifier);
    """

    func bindTo(statement: OpaquePointer?) -> Bool {
        return true
    }
}

struct UpsertStatement: Statement {
    let sql: String = """
        INSERT INTO data (identifier, kind, flags, content)
        VALUES (?, ?, ?, ?)
        ON CONFLICT(identifier) DO
            UPDATE SET kind = excluded.kind,
                flags = excluded.flags,
                content = excluded.content;
    """

    let record: Record
    init(_ record: Record) {
        self.record = record
    }

    func bindTo(statement: OpaquePointer?) -> Bool {
        guard let idChars = record.identifier.cString(using: .utf8) else { return false }
        guard let kindChars = record.kind.cString(using: .utf8) else { return false }

        guard sqlite3_bind_text(statement, 1, idChars, Int32(idChars.count), nil) == SQLITE_OK else { return false }
        guard sqlite3_bind_text(statement, 2, kindChars, Int32(kindChars.count), nil) == SQLITE_OK else { return false }
        guard sqlite3_bind_int(statement, 3, Int32(record.flags)) == SQLITE_OK else { return false }

        let boundContent = record.content.withUnsafeBytes { (bytes) -> Int32 in
            sqlite3_bind_blob(statement, 4, bytes, Int32(self.record.content.count), nil)
        }

        guard boundContent == SQLITE_OK else { return false }
        return true
    }
}

struct SelectIdentifierStatement: Statement {
    let sql: String = """
        SELECT * FROM data WHERE identifier = ?;
    """

    let identifier: String
    init (_ identifier: String) {
        self.identifier = identifier
    }

    func bindTo(statement: OpaquePointer?) -> Bool {
        guard let idChars = identifier.cString(using: .utf8) else { return false }
        guard sqlite3_bind_text(statement, 1, idChars, Int32(idChars.count), nil) == SQLITE_OK else { return false }
        return true
    }
}

struct SelectAllStatement: Statement {
    let sql: String = """
        SELECT * FROM data;
    """

    func bindTo(statement: OpaquePointer?) -> Bool {
        return true
    }
}
