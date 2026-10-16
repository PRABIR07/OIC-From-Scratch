-- =====================================================================
--  OIC from Scratch · Phase 4 · practice data          by @devwithprabir
--  Run this whole script once in FreeSQL (freesql.com) or Oracle Live SQL.
--  Safe to run again: it drops and recreates everything.
-- =====================================================================

-- 0) Clean up old copies (this block is PL/SQL; you'll learn it in Part 4.3)
BEGIN
  FOR t IN (SELECT table_name FROM user_tables
            WHERE table_name IN ('INTEGRATION_LOG','EMPLOYEE_STG','EMPLOYEES','DEPARTMENTS')) LOOP
    EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS PURGE';
  END LOOP;
END;
/

-- 1) DEPARTMENTS: one row per department
CREATE TABLE departments (
  dept_id    NUMBER(4)     CONSTRAINT dept_pk PRIMARY KEY,
  dept_name  VARCHAR2(50)  CONSTRAINT dept_name_nn NOT NULL
                           CONSTRAINT dept_name_uk UNIQUE,
  location   VARCHAR2(50)
);

-- 2) EMPLOYEES: one row per employee
CREATE TABLE employees (
  emp_id           NUMBER(6)     CONSTRAINT emp_pk PRIMARY KEY,
  first_name       VARCHAR2(30),
  last_name        VARCHAR2(30)  CONSTRAINT emp_last_nn NOT NULL,
  email            VARCHAR2(100) CONSTRAINT emp_email_uk UNIQUE,
  job_title        VARCHAR2(50),
  salary           NUMBER(10,2)  CONSTRAINT emp_salary_ck CHECK (salary > 0),
  hire_date        DATE          CONSTRAINT emp_hire_nn NOT NULL,
  dept_id          NUMBER(4)     CONSTRAINT emp_dept_fk REFERENCES departments (dept_id),
  manager_id       NUMBER(6)     CONSTRAINT emp_mgr_fk  REFERENCES employees (emp_id),
  status           VARCHAR2(10)  DEFAULT 'ACTIVE'
                                 CONSTRAINT emp_status_ck CHECK (status IN ('ACTIVE','INACTIVE')),
  last_update_date TIMESTAMP     DEFAULT SYSTIMESTAMP
);

-- 3) EMPLOYEE_STG: a staging table, filled by an integration from another HR system
CREATE TABLE employee_stg (
  emp_id         NUMBER(6),
  first_name     VARCHAR2(30),
  last_name      VARCHAR2(30),
  email          VARCHAR2(100),
  job_title      VARCHAR2(50),
  salary         NUMBER(10,2),
  dept_id        NUMBER(4),
  process_status VARCHAR2(10) DEFAULT 'NEW',      -- NEW -> PROCESSED or ERROR
  error_message  VARCHAR2(400)
);

-- 4) INTEGRATION_LOG: one row per integration run (used in Part 4.3)
CREATE TABLE integration_log (
  log_id      NUMBER GENERATED ALWAYS AS IDENTITY CONSTRAINT log_pk PRIMARY KEY,
  run_name    VARCHAR2(50),
  status      VARCHAR2(10),
  message     VARCHAR2(400),
  created_at  TIMESTAMP DEFAULT SYSTIMESTAMP
);

-- 5) Data
INSERT INTO departments VALUES (10, 'HR',      'Pune');
INSERT INTO departments VALUES (20, 'Finance', 'Mumbai');
INSERT INTO departments VALUES (30, 'IT',      'Bengaluru');
INSERT INTO departments VALUES (40, 'Sales',   'Delhi');
INSERT INTO departments VALUES (50, 'Legal',   'Chennai');

INSERT INTO employees VALUES (101,'Ravi','Kumar','ravi.kumar@company.com','HR Manager',95000,DATE '2019-04-01',10,NULL,'ACTIVE',TIMESTAMP '2026-10-01 10:00:00');
INSERT INTO employees VALUES (102,'Priya','Sharma','priya.sharma@company.com','Finance Manager',120000,DATE '2018-07-15',20,NULL,'ACTIVE',TIMESTAMP '2026-10-01 10:00:00');
INSERT INTO employees VALUES (103,'Amit','Patel','amit.patel@company.com','IT Manager',130000,DATE '2017-01-10',30,NULL,'ACTIVE',TIMESTAMP '2026-10-01 10:00:00');
INSERT INTO employees VALUES (104,'Sneha','Iyer','sneha.iyer@company.com','Integration Developer',85000,DATE '2021-06-01',30,103,'ACTIVE',TIMESTAMP '2026-10-14 09:30:00');
INSERT INTO employees VALUES (105,'Arjun','Singh','arjun.singh@company.com','Integration Developer',78000,DATE '2022-02-14',30,103,'ACTIVE',TIMESTAMP '2026-10-01 10:00:00');
INSERT INTO employees VALUES (106,'Neha','Gupta','neha.gupta@company.com','Accountant',60000,DATE '2020-09-01',20,102,'ACTIVE',TIMESTAMP '2026-10-01 10:00:00');
INSERT INTO employees VALUES (107,'Karan','Mehta',NULL,'Sales Executive',55000,DATE '2023-03-20',40,NULL,'ACTIVE',TIMESTAMP '2026-10-01 10:00:00');
INSERT INTO employees VALUES (108,'Pooja','Reddy','pooja.reddy@company.com','HR Executive',48000,DATE '2023-11-05',10,101,'ACTIVE',TIMESTAMP '2026-10-15 11:00:00');
INSERT INTO employees VALUES (109,'Vikram','Das','vikram.das@company.com','Consultant',70000,DATE '2024-01-08',NULL,NULL,'ACTIVE',TIMESTAMP '2026-10-01 10:00:00');
INSERT INTO employees VALUES (110,'Anjali','Nair','anjali.nair@company.com','Sales Executive',52000,DATE '2021-08-30',40,107,'INACTIVE',TIMESTAMP '2026-10-13 18:00:00');

INSERT INTO employee_stg (emp_id,first_name,last_name,email,job_title,salary,dept_id)
  VALUES (104,'Sneha','Iyer','sneha.iyer@company.com','Senior Integration Developer',92000,30);
INSERT INTO employee_stg (emp_id,first_name,last_name,email,job_title,salary,dept_id)
  VALUES (108,'Pooja','Reddy','pooja.reddy@company.com','HR Executive',48000,10);
INSERT INTO employee_stg (emp_id,first_name,last_name,email,job_title,salary,dept_id)
  VALUES (111,'Rahul','Verma','rahul.verma@company.com','Integration Developer',75000,30);

COMMIT;

-- 6) Check: you should see 5, 10, 3 and 0
SELECT (SELECT COUNT(*) FROM departments)     AS departments,
       (SELECT COUNT(*) FROM employees)       AS employees,
       (SELECT COUNT(*) FROM employee_stg)    AS staged,
       (SELECT COUNT(*) FROM integration_log) AS log_rows
FROM dual;
