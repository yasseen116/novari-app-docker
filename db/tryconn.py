import mysql.connector



db_config = {
    "host": "localhost",
    "user": "root",
    "password": "asd@123",
    "database": "novari"
}

# Connect to MariaDB
try:
    conn = mysql.connector.connect(**db_config)
    cursor = conn.cursor()
    print("✅ Connected to MariaDB using MySQL Connector!")
except mysql.connector.Error as e:
    print(f"❌ Error connecting to MariaDB: {e}")
