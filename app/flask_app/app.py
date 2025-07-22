from flask import Flask, render_template, request, redirect
from db import get_db

app = Flask(__name__)

@app.route('/')
def index():
    cur = get_db().cursor()
    cur.execute("SELECT id, name, quantity FROM inventory")
    items = cur.fetchall()
    return render_template('index.html', items=items)

@app.route('/add', methods=['POST'])
def add_item():
    name = request.form['name']
    quantity = request.form['quantity']
    cur = get_db().cursor()
    cur.execute("INSERT INTO inventory (name, quantity) VALUES (%s, %s)", (name, quantity))
    get_db().commit()
    return redirect('/')

@app.route('/delete/<int:item_id>')
def delete_item(item_id):
    cur = get_db().cursor()
    cur.execute("DELETE FROM inventory WHERE id=%s", (item_id,))
    get_db().commit()
    return redirect('/')

@app.route('/edit/<int:item_id>')
def edit_item(item_id):
    cur = get_db().cursor()
    cur.execute("SELECT id, name, quantity FROM inventory WHERE id=%s", (item_id,))
    item = cur.fetchone()
    return render_template('edit.html', item=item)

@app.route('/update/<int:item_id>', methods=['POST'])
def update_item(item_id):
    name = request.form['name']
    quantity = request.form['quantity']
    cur = get_db().cursor()
    cur.execute("UPDATE inventory SET name=%s, quantity=%s WHERE id=%s", (name, quantity, item_id))
    get_db().commit()
    return redirect('/')

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000)
