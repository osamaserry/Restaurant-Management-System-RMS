
DROP TABLE RESERVATION CASCADE CONSTRAINTS;
DROP TABLE PAYMENT CASCADE CONSTRAINTS;
DROP TABLE ORDER_ITEM CASCADE CONSTRAINTS;
DROP TABLE ORDERS CASCADE CONSTRAINTS;
DROP TABLE ORDER_STATUS CASCADE CONSTRAINTS;
DROP TABLE INVENTORY CASCADE CONSTRAINTS;
DROP TABLE SUPPLIER CASCADE CONSTRAINTS;
DROP TABLE MENU_ITEM_INGREDIENT CASCADE CONSTRAINTS;
DROP TABLE INGREDIENT CASCADE CONSTRAINTS;
DROP TABLE MENU_ITEM CASCADE CONSTRAINTS;
DROP TABLE CATEGORY CASCADE CONSTRAINTS;
DROP TABLE RESTAURANT_TABLE CASCADE CONSTRAINTS;
DROP TABLE EMPLOYEE CASCADE CONSTRAINTS;
DROP TABLE ROLE CASCADE CONSTRAINTS;
DROP TABLE CUSTOMER CASCADE CONSTRAINTS;

CREATE TABLE CUSTOMER (
    customer_id NUMBER PRIMARY KEY,
    full_name   VARCHAR2(100) NOT NULL,
    phone       VARCHAR2(20) UNIQUE,
    city        VARCHAR2(50),
    join_date   DATE DEFAULT SYSDATE
);

CREATE TABLE ROLE (
    role_id   NUMBER PRIMARY KEY,
    role_name VARCHAR2(50) NOT NULL UNIQUE
);

CREATE TABLE EMPLOYEE (
    employee_id NUMBER PRIMARY KEY,
    role_id     NUMBER NOT NULL,
    full_name   VARCHAR2(100) NOT NULL,
    phone       VARCHAR2(20) UNIQUE,
    salary      NUMBER(10,2),
    shift       VARCHAR2(20),
    hire_date   DATE DEFAULT SYSDATE,
    CONSTRAINT chk_emp_salary CHECK (salary > 0),
    CONSTRAINT fk_emp_role FOREIGN KEY (role_id) REFERENCES ROLE(role_id)
);

CREATE TABLE RESTAURANT_TABLE (
    table_id     NUMBER PRIMARY KEY,
    table_number NUMBER NOT NULL UNIQUE,
    capacity     NUMBER NOT NULL,
    location     VARCHAR2(50),
    status       VARCHAR2(20),
    CONSTRAINT chk_tbl_capacity CHECK (capacity > 0),
    CONSTRAINT chk_tbl_status CHECK (status IN ('AVAILABLE','RESERVED','OCCUPIED'))
);

CREATE TABLE CATEGORY (
    category_id   NUMBER PRIMARY KEY,
    category_name VARCHAR2(50) NOT NULL UNIQUE
);

CREATE TABLE MENU_ITEM (
    menu_item_id NUMBER PRIMARY KEY,
    category_id  NUMBER NOT NULL,
    pizza_name   VARCHAR2(100) NOT NULL,
    item_size    VARCHAR2(20),
    unit_price   NUMBER(10,2) NOT NULL,
    description  VARCHAR2(255),
    is_available CHAR(1) DEFAULT 'Y',
    image_url    VARCHAR2(255),
    CONSTRAINT chk_menu_price CHECK (unit_price > 0),
    CONSTRAINT chk_menu_avail CHECK (is_available IN ('Y','N')),
    CONSTRAINT fk_menu_cat FOREIGN KEY (category_id) REFERENCES CATEGORY(category_id) ON DELETE CASCADE
);

CREATE TABLE INGREDIENT (
    ingredient_id   NUMBER PRIMARY KEY,
    ingredient_name VARCHAR2(100) NOT NULL UNIQUE,
    unit            VARCHAR2(20)
);

CREATE TABLE MENU_ITEM_INGREDIENT (
    menu_item_id   NUMBER NOT NULL,
    ingredient_id  NUMBER NOT NULL,
    ingredient_qty NUMBER(10,2) NOT NULL,
    CONSTRAINT pk_menu_item_ing PRIMARY KEY (menu_item_id, ingredient_id),
    CONSTRAINT chk_ing_qty CHECK (ingredient_qty > 0),
    CONSTRAINT fk_mii_menu_id FOREIGN KEY (menu_item_id) REFERENCES MENU_ITEM(menu_item_id) ON DELETE CASCADE,
    CONSTRAINT fk_mii_ing_id FOREIGN KEY (ingredient_id) REFERENCES INGREDIENT(ingredient_id) ON DELETE CASCADE
);

CREATE TABLE SUPPLIER (
    supplier_id      NUMBER PRIMARY KEY,
    supplier_name    VARCHAR2(100) NOT NULL,
    contact_name     VARCHAR2(100),
    phone            VARCHAR2(20),
    city             VARCHAR2(50),
    lead_time_days   NUMBER,
    supplier_rating  NUMBER(2,1),
    CONSTRAINT chk_spl_lead_time CHECK (lead_time_days >= 0),
    CONSTRAINT chk_spl_rating CHECK (supplier_rating BETWEEN 0 AND 5)
);

CREATE TABLE INVENTORY (
    inventory_id   NUMBER PRIMARY KEY,
    ingredient_id  NUMBER NOT NULL,
    supplier_id    NUMBER,
    stock_qty      NUMBER(10,2) DEFAULT 0,
    reorder_level  NUMBER(10,2) DEFAULT 0,
    last_updated   DATE DEFAULT SYSDATE,
    CONSTRAINT chk_inv_stock CHECK (stock_qty >= 0),
    CONSTRAINT chk_inv_reorder CHECK (reorder_level >= 0),
    CONSTRAINT fk_inv_ingredient FOREIGN KEY (ingredient_id) REFERENCES INGREDIENT(ingredient_id) ON DELETE CASCADE,
    CONSTRAINT fk_inv_supplier FOREIGN KEY (supplier_id) REFERENCES SUPPLIER(supplier_id) ON DELETE SET NULL
);

CREATE TABLE ORDER_STATUS (
    status_id   NUMBER PRIMARY KEY,
    status_name VARCHAR2(30) UNIQUE NOT NULL
);

CREATE TABLE ORDERS (
    order_id      NUMBER PRIMARY KEY,
    customer_id   NUMBER NOT NULL,
    employee_id   NUMBER NOT NULL,
    status_id     NUMBER NOT NULL,
    order_date    DATE DEFAULT SYSDATE,
    order_time    VARCHAR2(20),
    CONSTRAINT fk_ord_customer FOREIGN KEY (customer_id) REFERENCES CUSTOMER(customer_id) ON DELETE CASCADE,
    CONSTRAINT fk_ord_employee FOREIGN KEY (employee_id) REFERENCES EMPLOYEE(employee_id),
    CONSTRAINT fk_ord_status FOREIGN KEY (status_id) REFERENCES ORDER_STATUS(status_id)
);

CREATE TABLE ORDER_ITEM (
    order_item_id NUMBER PRIMARY KEY,
    order_id      NUMBER NOT NULL,
    menu_item_id  NUMBER NOT NULL,
    quantity      NUMBER NOT NULL,
    unit_price    NUMBER(10,2) NOT NULL,
    CONSTRAINT chk_item_qty CHECK (quantity > 0),
    CONSTRAINT chk_item_price CHECK (unit_price > 0),
    CONSTRAINT fk_ori_order FOREIGN KEY (order_id) REFERENCES ORDERS(order_id) ON DELETE CASCADE,
    CONSTRAINT fk_ori_menu FOREIGN KEY (menu_item_id) REFERENCES MENU_ITEM(menu_item_id)
);

CREATE TABLE PAYMENT (
    payment_id      NUMBER PRIMARY KEY,
    order_id        NUMBER NOT NULL,
    amount          NUMBER(10,2) NOT NULL,
    payment_method  VARCHAR2(30),
    payment_status  VARCHAR2(30),
    payment_date    DATE DEFAULT SYSDATE,
    transaction_ref VARCHAR2(100) UNIQUE,
    CONSTRAINT chk_pay_amount CHECK (amount > 0),
    CONSTRAINT chk_pay_method CHECK (payment_method IN ('CASH','CARD','ONLINE')),
    CONSTRAINT chk_pay_status CHECK (payment_status IN ('PENDING','PAID','FAILED')),
    CONSTRAINT fk_pay_order FOREIGN KEY (order_id) REFERENCES ORDERS(order_id) ON DELETE CASCADE
);

CREATE TABLE RESERVATION (
    reservation_id      NUMBER PRIMARY KEY,
    customer_id         NUMBER NOT NULL,
    table_id            NUMBER NOT NULL,
    reservation_date    DATE NOT NULL,
    reservation_time    VARCHAR2(20),
    number_of_guests    NUMBER,
    reservation_status  VARCHAR2(30),
    special_request     VARCHAR2(255),
    CONSTRAINT chk_res_guests CHECK (number_of_guests > 0),
    CONSTRAINT fk_res_customer FOREIGN KEY (customer_id) REFERENCES CUSTOMER(customer_id) ON DELETE CASCADE,
    CONSTRAINT fk_res_table FOREIGN KEY (table_id) REFERENCES RESTAURANT_TABLE(table_id)
);

/* ========================================================
   3. إسقاط المتسلسلات القديمة وإنشاء متسلسلات (Sequences) جديدة للترقيم
======================================================= */
BEGIN
    FOR seq IN (SELECT sequence_name FROM user_sequences WHERE sequence_name LIKE 'SEQ_%') LOOP
        EXECUTE IMMEDIATE 'DROP SEQUENCE ' || seq.sequence_name;
    END LOOP;
END;
/

CREATE SEQUENCE seq_customer START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_role START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_employee START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_table START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_category START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_menu_item START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_ingredient START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_supplier START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_inventory START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_order_status START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_orders START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_order_item START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_payment START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_reservation START WITH 1 INCREMENT BY 1;
/

/* ========================================================
   4. إنشاء المشغلات (Triggers) لتطبيق الترقيم التلقائي بالترتيب الصحيح
======================================================= */
CREATE OR REPLACE TRIGGER trg_customer BEFORE INSERT ON CUSTOMER FOR EACH ROW BEGIN :NEW.customer_id := seq_customer.NEXTVAL; END;
/
CREATE OR REPLACE TRIGGER trg_role BEFORE INSERT ON ROLE FOR EACH ROW BEGIN :NEW.role_id := seq_role.NEXTVAL; END;
/
CREATE OR REPLACE TRIGGER trg_employee BEFORE INSERT ON EMPLOYEE FOR EACH ROW BEGIN :NEW.employee_id := seq_employee.NEXTVAL; END;
/
CREATE OR REPLACE TRIGGER trg_table BEFORE INSERT ON RESTAURANT_TABLE FOR EACH ROW BEGIN :NEW.table_id := seq_table.NEXTVAL; END;
/
CREATE OR REPLACE TRIGGER trg_category BEFORE INSERT ON CATEGORY FOR EACH ROW BEGIN :NEW.category_id := seq_category.NEXTVAL; END;
/
CREATE OR REPLACE TRIGGER trg_menu_item BEFORE INSERT ON MENU_ITEM FOR EACH ROW BEGIN :NEW.menu_item_id := seq_menu_item.NEXTVAL; END;
/
CREATE OR REPLACE TRIGGER trg_ingredient BEFORE INSERT ON INGREDIENT FOR EACH ROW BEGIN :NEW.ingredient_id := seq_ingredient.NEXTVAL; END;
/
CREATE OR REPLACE TRIGGER trg_supplier BEFORE INSERT ON SUPPLIER FOR EACH ROW BEGIN :NEW.supplier_id := seq_supplier.NEXTVAL; END;
/
CREATE OR REPLACE TRIGGER trg_inventory BEFORE INSERT ON INVENTORY FOR EACH ROW BEGIN :NEW.inventory_id := seq_inventory.NEXTVAL; END;
/
CREATE OR REPLACE TRIGGER trg_order_status BEFORE INSERT ON ORDER_STATUS FOR EACH ROW BEGIN :NEW.status_id := seq_order_status.NEXTVAL; END;
/
CREATE OR REPLACE TRIGGER trg_orders BEFORE INSERT ON ORDERS FOR EACH ROW BEGIN :NEW.order_id := seq_orders.NEXTVAL; END;
/
CREATE OR REPLACE TRIGGER trg_order_item BEFORE INSERT ON ORDER_ITEM FOR EACH ROW BEGIN :NEW.order_item_id := seq_order_item.NEXTVAL; END;
/
CREATE OR REPLACE TRIGGER trg_payment BEFORE INSERT ON PAYMENT FOR EACH ROW BEGIN :NEW.payment_id := seq_payment.NEXTVAL; END;
/
CREATE OR REPLACE TRIGGER trg_reservation BEFORE INSERT ON RESERVATION FOR EACH ROW BEGIN :NEW.reservation_id := seq_reservation.NEXTVAL; END;
/