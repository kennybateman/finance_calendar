import 'package:sqflite/sqflite.dart';

class DatabaseSchema {
  /* SCHEMA POLICIES...
    1. id is called pk for primary key
    2. there are no dates, save as string YYYY-MM-DD
    3. store currency as integer so no floating point or decimal necessary
  */
  Future createDB(Database db, int version) async {
    /* Accounts can be debit or credit.
      Credit accounts require extra columns; all are nullable for the debit cases.
    */
    await db.execute('''
      CREATE TABLE accounts (
        pk            INTEGER PRIMARY KEY AUTOINCREMENT,
        name          TEXT NOT NULL UNIQUE,
        balance       INTEGER NOT NULL,
        balance_date  TEXT,
        account_type  TEXT NOT NULL CHECK(account_type In ('debit', 'credit')),
        credit_limit  INTEGER,
        interest      INTEGER,
        due_date      TEXT,
        due_date_anchor_day INTEGER,
        due_frequency TEXT CHECK(due_frequency IN ('monthly', 'bimonthly', 'weekly', 'biweekly')),  
        pay_from_account_pk INTEGER,
        FOREIGN KEY (pay_from_account_pk) REFERENCES accounts (pk)
      )
    ''');

    await db.execute('''
      CREATE TABLE bills (
        pk            INTEGER PRIMARY KEY AUTOINCREMENT,
        name          TEXT    NOT NULL UNIQUE,
        amount        INTEGER NOT NULL,
        due_date      TEXT,
        due_date_anchor_day INTEGER,
        due_frequency TEXT    NOT NULL CHECK(due_frequency IN ('monthly', 'bimonthly', 'weekly', 'biweekly')),
        pay_from_account_pk INTEGER,
        FOREIGN KEY (pay_from_account_pk) REFERENCES accounts (pk)
      )
    ''');

    /* Pay from or Pay to fields are nullable to accomodate cases
      where the user is setting up a bill or income but hasn't set up an account yet.
    */
    await db.execute('''
      CREATE TABLE income (
        pk INTEGER PRIMARY KEY AUTOINCREMENT,
        name      TEXT     NOT NULL UNIQUE,
        amount    INTEGER  NOT NULL,
        due_date  TEXT,
        due_date_anchor_day INTEGER,
        due_frequency TEXT NOT NULL CHECK(due_frequency IN ('monthly', 'bimonthly', 'weekly', 'biweekly')),
        pay_to_account_pk INTEGER,
        FOREIGN KEY (pay_to_account_pk) REFERENCES accounts (pk)
      )
    ''');

    /*
      Projections is supported by 2 more tables.
    */
    await db.execute('''
      CREATE TABLE projections (
        pk INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE
      )
    ''');

    await db.execute('''
      CREATE TABLE account_projections (
        pk INTEGER PRIMARY KEY AUTOINCREMENT,
        projected_balance INTEGER NOT NULL,
        projection_pk     INTEGER NOT NULL,
        account_pk        INTEGER,
        FOREIGN KEY (projection_pk) REFERENCES projections (pk),
        FOREIGN KEY (account_pk) REFERENCES accounts (pk)
      )
    ''');

    /*
      Transaction links to either bill or income, both should be forbidden.
    */
    await db.execute('''
      CREATE TABLE transaction_projections (
        pk INTEGER PRIMARY KEY AUTOINCREMENT,
        projected_amount INTEGER NOT NULL,
        projection_pk    INTEGER NOT NULL,
        bill_pk   INTEGER,
        income_pk INTEGER,
        account_pk INTEGER,
        FOREIGN KEY (projection_pk) REFERENCES projections (pk),
        FOREIGN KEY (bill_pk) REFERENCES bills (pk),
        FOREIGN KEY (income_pk) REFERENCES income (pk)
        FOREIGN KEY (account_pk) REFERENCES accounts (pk)
      )
    ''');
  }

  Future deleteAllTables(Database db) async {
    await db.execute('''
      DROP TABLE IF EXISTS accounts;
      DROP TABLE IF EXISTS bills;
      DROP TABLE IF EXISTS income;
      DROP TABLE IF EXISTS projections;
      DROP TABLE IF EXISTS account_projections;
      DROP TABLE IF EXISTS transaction_projections;
    ''');
  }

  Future onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE bills ADD COLUMN due_date_anchor_day INTEGER;
        ALTER TABLE income ADD COLUMN due_date_anchor_day INTEGER;
        ALTER TABLE accounts ADD COLUMN due_date_anchor_day INTEGER;
      ''');
    }

    if (oldVersion < 3) {
    }
  }
}
