import os
import MySQLdb
from flask import g

DB_HOST = os.getenv("DB_HOST", "localhost")
DB_USER = os.getenv("DB_USER", "admin")
DB_PASS = os.getenv("DB_PASS", "wolfpassword123")
DB_NAME = os.getenv("DB_NAME", "inventory_db")

def get_db():
    if 'db' not in g:
        g.db = MySQLdb.connect(
            host=DB_HOST,
            user=DB_USER,
            passwd=DB_PASS,
            db=DB_NAME
        )
    return g.db

def close_db(e=None):
    db = g.pop('db', None)
    if db is not None:
        db.close()
