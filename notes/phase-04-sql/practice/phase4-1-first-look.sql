-- =====================================================================
--  OIC from Scratch · Phase 4.1 · What is a database?   by @devwithprabir
--  First run phase4-setup.sql (Run Script / F5).
--  Then put your cursor in one query and press Ctrl/Cmd + Enter.
-- =====================================================================

-- ch 15 · your first queries
SELECT * FROM departments;                                   -- 5 rows
SELECT dept_name, location FROM departments;                 -- 2 columns
SELECT location, dept_name FROM departments;                 -- columns swap
SELECT emp_id, first_name, last_name, salary FROM employees; -- 10 rows

-- mistakes on purpose
SELECT * FROM department;                     -- ORA-00942: no such table
SELECT dept_nam FROM departments;             -- ORA-00904: no such column
SELECT dept_name location FROM departments;   -- no error, but a missing comma!

-- ch 16 · practice answers
SELECT * FROM employees;                              -- 1: 10 rows
SELECT first_name, job_title FROM employees;          -- 2
SELECT first_name, email FROM employees;              -- 3: Karan has no email
SELECT first_name, dept_id FROM employees;            -- 4: Vikram has no department
SELECT emp_id, first_name, manager_id FROM employees; -- 5: Sneha's manager is 103 (Amit)
SELECT * FROM staff;                                  -- 6: ORA-00942
