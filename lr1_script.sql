CREATE TABLE Roles (
    role_id INT IDENTITY(1,1) PRIMARY KEY,
    role_name NVARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE Users (
    user_id INT IDENTITY(1,1) PRIMARY KEY,
    login NVARCHAR(100) NOT NULL UNIQUE,
    password_hash NVARCHAR(255) NOT NULL,
    is_active BIT DEFAULT 1
);

CREATE TABLE UserRoles (
    user_id INT NOT NULL,
    role_id INT NOT NULL,
    PRIMARY KEY (user_id, role_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (role_id) REFERENCES Roles(role_id)
);

CREATE TABLE Positions (
    position_id INT IDENTITY(1,1) PRIMARY KEY,
    title NVARCHAR(255) NOT NULL,
    base_salary DECIMAL(10, 2)
);

CREATE TABLE Departments (
    department_id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(255) NOT NULL,
    manager_employee_id INT NULL, 
    updated_at DATETIME2,
    updated_by_user_id INT,
    FOREIGN KEY (updated_by_user_id) REFERENCES Users(user_id)
);

CREATE TABLE Employees (
    employee_id INT IDENTITY(1,1) PRIMARY KEY,
    first_name NVARCHAR(100) NOT NULL,
    last_name NVARCHAR(100) NOT NULL,
    position_id INT NOT NULL,
    department_id INT NOT NULL,
    user_id INT UNIQUE,
    is_deleted BIT DEFAULT 0 NOT NULL,
    updated_at DATETIME2,
    updated_by_user_id INT,
    FOREIGN KEY (position_id) REFERENCES Positions(position_id),
    FOREIGN KEY (department_id) REFERENCES Departments(department_id),
    FOREIGN KEY (user_id) REFERENCES Users(user_id),
    FOREIGN KEY (updated_by_user_id) REFERENCES Users(user_id)
);

CREATE TABLE Customers (
    customer_id INT IDENTITY(1,1) PRIMARY KEY,
    first_name NVARCHAR(100),
    last_name NVARCHAR(100),
    phone NVARCHAR(50) UNIQUE,
    is_deleted BIT DEFAULT 0 NOT NULL,
    updated_at DATETIME2,
    updated_by_user_id INT,
    FOREIGN KEY (updated_by_user_id) REFERENCES Users(user_id)
);

CREATE TABLE Suppliers (
    supplier_id INT IDENTITY(1,1) PRIMARY KEY,
    company_name NVARCHAR(255) NOT NULL,
    contact_person NVARCHAR(255),
    is_deleted BIT DEFAULT 0 NOT NULL
);

CREATE TABLE Categories (
    category_id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(255) NOT NULL,
    parent_category_id INT,
    is_deleted BIT DEFAULT 0 NOT NULL,
    FOREIGN KEY (parent_category_id) REFERENCES Categories(category_id)
);

CREATE TABLE Products (
    product_id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(255) NOT NULL,
    sku NVARCHAR(100) UNIQUE,
    category_id INT,
    supplier_id INT,
    price DECIMAL(10, 2) NOT NULL,
    is_deleted BIT DEFAULT 0 NOT NULL,
    updated_at DATETIME2,
    updated_by_user_id INT,
    FOREIGN KEY (category_id) REFERENCES Categories(category_id),
    FOREIGN KEY (supplier_id) REFERENCES Suppliers(supplier_id),
    FOREIGN KEY (updated_by_user_id) REFERENCES Users(user_id)
);

CREATE TABLE Inventory (
    inventory_id INT IDENTITY(1,1) PRIMARY KEY,
    product_id INT NOT NULL UNIQUE,
    quantity INT NOT NULL,
    updated_at DATETIME2,
    updated_by_user_id INT,
    FOREIGN KEY (product_id) REFERENCES Products(product_id),
    FOREIGN KEY (updated_by_user_id) REFERENCES Users(user_id)
);

CREATE TABLE Sales (
    sale_id INT IDENTITY(1,1) PRIMARY KEY,
    customer_id INT,
    employee_id INT NOT NULL,
    total_amount DECIMAL(10, 2) DEFAULT 0.00,
    sale_timestamp DATETIME2 DEFAULT GETDATE(),
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id),
    FOREIGN KEY (employee_id) REFERENCES Employees(employee_id)
);

CREATE TABLE SaleDetails (
    sale_detail_id INT IDENTITY(1,1) PRIMARY KEY,
    sale_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    price_at_sale DECIMAL(10, 2) NOT NULL,
    FOREIGN KEY (sale_id) REFERENCES Sales(sale_id) ON DELETE CASCADE,
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

CREATE TABLE SupplyOrders (
    order_id INT IDENTITY(1,1) PRIMARY KEY,
    supplier_id INT NOT NULL,
    created_by_employee_id INT NOT NULL,
    status NVARCHAR(50) DEFAULT 'New',
    updated_at DATETIME2,
    updated_by_user_id INT,
    FOREIGN KEY (supplier_id) REFERENCES Suppliers(supplier_id),
    FOREIGN KEY (created_by_employee_id) REFERENCES Employees(employee_id),
    FOREIGN KEY (updated_by_user_id) REFERENCES Users(user_id)
);

CREATE TABLE SupplyOrderDetails (
    order_detail_id INT IDENTITY(1,1) PRIMARY KEY,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity_ordered INT NOT NULL,
    cost_price DECIMAL(10, 2),
    FOREIGN KEY (order_id) REFERENCES SupplyOrders(order_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

ALTER TABLE Departments
ADD CONSTRAINT FK_Departments_Manager
FOREIGN KEY (manager_employee_id) REFERENCES Employees(employee_id);
GO 


CREATE VIEW vw_ActiveEmployees
AS
SELECT 
    employee_id,
    first_name,
    last_name,
    position_id,
    department_id,
    user_id
FROM 
    Employees
WHERE 
    is_deleted = 0;
GO

CREATE VIEW vw_ActiveCustomers
AS
SELECT 
    customer_id,
    first_name,
    last_name,
    phone
FROM 
    Customers
WHERE 
    is_deleted = 0;
GO


CREATE PROCEDURE sp_SoftDeleteCustomer
    @CustomerID INT,
    @UpdatedByUserID INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Customers
    SET 
        is_deleted = 1,
        updated_at = GETDATE(),
        updated_by_user_id = @UpdatedByUserID
    WHERE 
        customer_id = @CustomerID;
END;
GO

CREATE PROCEDURE sp_SoftDeleteProduct
    @ProductID INT,
    @UpdatedByUserID INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Products
    SET 
        is_deleted = 1,
        updated_at = GETDATE(),
        updated_by_user_id = @UpdatedByUserID
    WHERE 
        product_id = @ProductID;
END;
GO


CREATE PROCEDURE sp_UpdateEmployeeDetails
    @EmployeeID INT,
    @FirstName NVARCHAR(100),
    @LastName NVARCHAR(100),
    @PositionID INT,
    @DepartmentID INT,
    @UpdatedByUserID INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Employees
    SET
        first_name = @FirstName,
        last_name = @LastName,
        position_id = @PositionID,
        department_id = @DepartmentID,
        updated_at = GETDATE(),
        updated_by_user_id = @UpdatedByUserID
    WHERE
        employee_id = @EmployeeID;
END;
GO

CREATE PROCEDURE sp_UpdateInventoryQuantity
    @ProductID INT,
    @NewQuantity INT,
    @UpdatedByUserID INT
AS
BEGIN
    SET NOCOUNT ON;
    UPDATE Inventory
    SET
        quantity = @NewQuantity,
        updated_at = GETDATE(),
        updated_by_user_id = @UpdatedByUserID
    WHERE
        product_id = @ProductID;
END;
GO

CREATE FUNCTION fn_GetProductCurrentStock (@ProductID INT)
RETURNS INT
AS
BEGIN
    DECLARE @Stock INT;
    SELECT @Stock = quantity
    FROM Inventory
    WHERE product_id = @ProductID;
    RETURN ISNULL(@Stock, 0);
END;
GO

CREATE TRIGGER trg_UpdateInventoryOnSale
ON SaleDetails
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    UPDATE inv
    SET 
        inv.quantity = inv.quantity - i.quantity,
        inv.updated_at = GETDATE()
    FROM 
        Inventory AS inv
    JOIN 
        inserted AS i ON inv.product_id = i.product_id;
END;
GO

CREATE TYPE SaleItemList AS TABLE (
    ProductID INT,
    Quantity INT
);
GO

CREATE PROCEDURE sp_ProcessSale
    @CustomerID INT,
    @EmployeeID INT,
    @SaleItems SaleItemList READONLY 
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @NewSaleID INT;
    DECLARE @TotalAmount DECIMAL(10, 2);

    SELECT @TotalAmount = SUM(i.Quantity * p.price)
    FROM @SaleItems AS i
    JOIN Products AS p ON i.ProductID = p.product_id;

    BEGIN TRANSACTION;
    
    BEGIN TRY
        INSERT INTO Sales (customer_id, employee_id, total_amount, sale_timestamp)
        VALUES (@CustomerID, @EmployeeID, @TotalAmount, GETDATE());

        SET @NewSaleID = SCOPE_IDENTITY();

        INSERT INTO SaleDetails (sale_id, product_id, quantity, price_at_sale)
        SELECT 
            @NewSaleID,
            i.ProductID,
            i.Quantity,
            p.price 
        FROM 
            @SaleItems AS i
        JOIN 
            Products AS p ON i.ProductID = p.product_id;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH

        ROLLBACK TRANSACTION;
        THROW; 
    END CATCH
END;
GO


CREATE NONCLUSTERED INDEX IX_Products_Name 
ON Products (name);

CREATE NONCLUSTERED INDEX IX_Products_CategoryID 
ON Products (category_id);


CREATE UNIQUE NONCLUSTERED INDEX UQ_Customers_Phone_Active
ON Customers (phone)
WHERE (is_deleted = 0 AND phone IS NOT NULL);
GO
