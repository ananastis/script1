import pyodbc
import pymongo
import time
import random
from faker import Faker

SQL_SERVER = '.'
SQL_DATABASE = 'lr1'
MONGO_URI = "mongodb://localhost:27017/"

print("1.Connecting to databases...")
fake = Faker()

client = pymongo.MongoClient(MONGO_URI)
db_mongo = client["ShopDB_NoSQL"]
col_specs = db_mongo["product_specs"]
col_reviews = db_mongo["product_reviews"]

try:
    conn = pyodbc.connect(f'DRIVER={{SQL Server}};SERVER={SQL_SERVER};DATABASE={SQL_DATABASE};Trusted_Connection=yes;')
    cursor = conn.cursor()
except Exception as e:
    print(f"SQL Error: {e}")
    exit()

col_specs.delete_many({})
col_reviews.delete_many({})

COUNT_PRODUCTS = 2000
print(f"2. Generating {COUNT_PRODUCTS} products with reviews...")

start_time = time.time()

for i in range(COUNT_PRODUCTS):
    p_name = f"Product {fake.word()} {i}"
    p_sku = f"SKU-{random.randint(100000, 999999)}-{i}"

    cursor.execute("INSERT INTO Products (name, sku, price) VALUES (?, ?, ?)",
                   (p_name, p_sku, random.uniform(10, 1000)))

    cursor.execute("SELECT @@IDENTITY")
    pid = int(cursor.fetchone()[0])

    specs = {
        "Color": fake.color_name(),
        "Material": random.choice(["Metal", "Plastic", "Wood"]),
        "Weight": f"{random.randint(100, 5000)}g"
    }

    col_specs.insert_one({"ref_product_id": pid, "specs": specs})

    for k, v in specs.items():
        cursor.execute("INSERT INTO ProductAttributeValues (product_id, attr_id, attr_value) VALUES (?, 1, ?)",
                       (pid, v))

    for _ in range(random.randint(1, 3)):
        rev_user = fake.first_name()
        rev_rating = random.randint(1, 5)
        rev_text = fake.sentence()

        photos = [f"http://img.com/{random.randint(1, 100)}.jpg" for _ in range(random.randint(0, 2))]
        replies = [{"user": "Manager", "text": "Thanks!"}] if random.choice([True, False]) else []

        mongo_review_doc = {
            "ref_product_id": pid,
            "user": rev_user,
            "rating": rev_rating,
            "comment": rev_text,
            "photos": photos,
            "replies": replies
        }
        col_reviews.insert_one(mongo_review_doc)

        cursor.execute("INSERT INTO ProductReviews (product_id, user_name, rating, comment) VALUES (?, ?, ?, ?)",
                       (pid, rev_user, rev_rating, rev_text))
        cursor.execute("SELECT @@IDENTITY")
        review_id = cursor.fetchone()[0]

        for photo in photos:
            cursor.execute("INSERT INTO ReviewPhotos (review_id, photo_url) VALUES (?, ?)", (review_id, photo))

        for rep in replies:
            cursor.execute("INSERT INTO ReviewReplies (review_id, replier_name, reply_text) VALUES (?, ?, ?)",
                           (review_id, rep['user'], rep['text']))

    if i % 100 == 0:
        print(f"Progress: {i}...")
        conn.commit()

conn.commit()
print(f"Generation completed in {round(time.time() - start_time, 2)} sec.")

print("\n3. Testing: Get reviews with photos for 500 products")
test_ids = [random.randint(pid - 1000, pid) for _ in range(500)]

t1 = time.time()
for tid in test_ids:
    cursor.execute("""
        SELECT r.user_name, r.comment, p.photo_url, rep.reply_text
        FROM ProductReviews r
        LEFT JOIN ReviewPhotos p ON r.review_id = p.review_id
        LEFT JOIN ReviewReplies rep ON r.review_id = rep.review_id
        WHERE r.product_id = ?
    """, tid)
    rows = cursor.fetchall()
t2 = time.time()
sql_time = t2 - t1
print(f"SQL time (JOINs):{sql_time:.4f} sec")

t1 = time.time()
for tid in test_ids:
    docs = list(col_reviews.find({"ref_product_id": tid}))
t2 = time.time()
mongo_time = t2 - t1
print(f"Mongo time:{mongo_time:.4f} sec")

print(f"\nCONCLUSION: MongoDB is {round(sql_time / mongo_time, 1)} times faster")