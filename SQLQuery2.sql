IF OBJECT_ID('ProductAttributeValues', 'U') IS NULL
BEGIN
    CREATE TABLE ProductAttributeValues (
        value_id INT IDENTITY(1,1) PRIMARY KEY,
        product_id INT NOT NULL,
        attr_id INT NOT NULL,  
        attr_value NVARCHAR(255) NOT NULL,
        FOREIGN KEY (product_id) REFERENCES Products(product_id) ON DELETE CASCADE
    );
END

IF OBJECT_ID('ProductReviews', 'U') IS NULL
BEGIN
    CREATE TABLE ProductReviews (
        review_id INT IDENTITY(1,1) PRIMARY KEY,
        product_id INT NOT NULL,
        user_name NVARCHAR(100),
        rating TINYINT,
        comment NVARCHAR(MAX),
        created_at DATETIME2 DEFAULT GETDATE(),
        FOREIGN KEY (product_id) REFERENCES Products(product_id) ON DELETE CASCADE
    );
END

IF OBJECT_ID('ReviewPhotos', 'U') IS NULL
BEGIN
    CREATE TABLE ReviewPhotos (
        photo_id INT IDENTITY(1,1) PRIMARY KEY,
        review_id INT NOT NULL,
        photo_url NVARCHAR(500),
        FOREIGN KEY (review_id) REFERENCES ProductReviews(review_id) ON DELETE CASCADE
    );
END

IF OBJECT_ID('ReviewReplies', 'U') IS NULL
BEGIN
    CREATE TABLE ReviewReplies (
        reply_id INT IDENTITY(1,1) PRIMARY KEY,
        review_id INT NOT NULL,
        replier_name NVARCHAR(100),
        reply_text NVARCHAR(MAX),
        FOREIGN KEY (review_id) REFERENCES ProductReviews(review_id) ON DELETE CASCADE
    );
END