-- =====================================================================
--  OIC from Scratch · Phase 4.2 · Joins, grouping & changing data
--  by @devwithprabir
--  Run phase4-setup.sql first, then these in order, one at a time.
-- =====================================================================

-- A · READING ===========================================================

-- ch 2 · INNER JOIN  -> 9 rows
SELECT e.first_name, e.last_name, d.dept_name, d.location
FROM   employees e
JOIN   departments d ON e.dept_id = d.dept_id
ORDER  BY e.emp_id;

-- ch 3 · LEFT -> 10 rows (Vikram with no department)
SELECT e.first_name, d.dept_name
FROM   employees e
LEFT   JOIN departments d ON e.dept_id = d.dept_id
ORDER  BY e.emp_id;

-- RIGHT -> 10 rows (Legal with no employee)
SELECT e.first_name, d.dept_name
FROM   employees e
RIGHT  JOIN departments d ON e.dept_id = d.dept_id
ORDER  BY d.dept_id, e.emp_id;

-- FULL -> 11 rows (both)
SELECT e.first_name, d.dept_name
FROM   employees e
FULL   OUTER JOIN departments d ON e.dept_id = d.dept_id
ORDER  BY d.dept_id, e.emp_id;

-- anti-join: departments with nobody -> Legal
SELECT d.dept_name
FROM   departments d
LEFT   JOIN employees e ON e.dept_id = d.dept_id
WHERE  e.emp_id IS NULL;

-- the same with NOT EXISTS -> Legal
SELECT d.dept_name
FROM   departments d
WHERE  NOT EXISTS (SELECT 1 FROM employees e WHERE e.dept_id = d.dept_id);

-- ch 4 · self join
SELECT e.first_name AS employee, m.first_name AS manager
FROM   employees e
LEFT   JOIN employees m ON e.manager_id = m.emp_id
WHERE  e.dept_id = 30
ORDER  BY e.emp_id;

-- ch 5 · aggregates
SELECT COUNT(*)                AS all_rows,
       COUNT(email)            AS with_email,
       COUNT(DISTINCT dept_id) AS depts_used,
       SUM(salary)             AS total_pay,
       AVG(salary)             AS avg_pay,
       MIN(salary)             AS lowest,
       MAX(salary)             AS highest,
       TO_CHAR(MIN(hire_date), 'YYYY-MM-DD') AS first_hire
FROM   employees;

-- ch 6 · GROUP BY
SELECT dept_id, COUNT(*) AS headcount, SUM(salary) AS total_pay, ROUND(AVG(salary)) AS avg_pay
FROM   employees
GROUP  BY dept_id
ORDER  BY dept_id;

SELECT d.dept_name, COUNT(e.emp_id) AS headcount
FROM   departments d
LEFT   JOIN employees e ON e.dept_id = d.dept_id
GROUP  BY d.dept_name
ORDER  BY headcount DESC, d.dept_name;

-- break the golden rule on purpose -> ORA-00979
SELECT d.dept_name, e.first_name, COUNT(e.emp_id) AS headcount
FROM   departments d
LEFT   JOIN employees e ON e.dept_id = d.dept_id
GROUP  BY d.dept_name;

-- ch 7 · HAVING
SELECT d.dept_name, COUNT(*) AS active_staff, ROUND(AVG(e.salary)) AS avg_pay
FROM   employees e
JOIN   departments d ON e.dept_id = d.dept_id
WHERE  e.status = 'ACTIVE'
GROUP  BY d.dept_name
HAVING COUNT(*) >= 2
ORDER  BY avg_pay DESC;

-- ch 8 · alias in WHERE -> ORA-00904
SELECT first_name, salary * 12 AS annual FROM employees WHERE annual > 1000000;
SELECT first_name, salary * 12 AS annual FROM employees WHERE salary * 12 > 1000000 ORDER BY annual DESC;

-- ch 9 · subqueries
SELECT first_name, salary FROM employees
WHERE  salary > (SELECT AVG(salary) FROM employees)
ORDER  BY salary DESC;

SELECT first_name FROM employees
WHERE  dept_id IN (SELECT dept_id FROM departments WHERE location IN ('Pune', 'Mumbai'))
ORDER  BY emp_id;

SELECT d.dept_name FROM departments d
WHERE  EXISTS (SELECT 1 FROM employees e WHERE e.dept_id = d.dept_id AND e.salary > 100000)
ORDER  BY d.dept_name;

-- B · CHANGING ==========================================================

-- ch 10 · INSERT, then COMMIT
INSERT INTO employees (emp_id, first_name, last_name, email, job_title, salary, hire_date, dept_id)
VALUES (112, 'Meera', 'Joshi', 'meera.joshi@company.com', 'Legal Advisor', 88000, DATE '2026-10-16', 50);
COMMIT;
SELECT COUNT(*) FROM employees;                 -- 11

-- collect the errors
INSERT INTO employees (emp_id, last_name, hire_date) VALUES (101, 'Again', SYSDATE);            -- ORA-00001
INSERT INTO employees (emp_id, last_name, hire_date, dept_id) VALUES (120, 'Nobody', SYSDATE, 99); -- ORA-02291
INSERT INTO employees (emp_id, hire_date) VALUES (121, SYSDATE);                                 -- ORA-01400
INSERT INTO employees (emp_id, last_name, hire_date, salary) VALUES (122, 'Minus', SYSDATE, -5); -- ORA-02290
DELETE FROM departments WHERE dept_id = 30;                                                      -- ORA-02292

-- ch 11/12 · check, update, look, undo
SELECT emp_id, salary FROM employees WHERE dept_id = 10;            -- 95000, 48000
UPDATE employees
SET    salary = salary * 1.10, last_update_date = SYSTIMESTAMP
WHERE  dept_id = 10;                                                -- 2 rows updated
SELECT emp_id, salary FROM employees WHERE dept_id = 10;            -- 104500, 52800
ROLLBACK;
SELECT emp_id, salary FROM employees WHERE dept_id = 10;            -- 95000, 48000 again

-- ch 13 · MERGE (run it twice: still 12 employees)
MERGE INTO employees e
USING (SELECT * FROM employee_stg WHERE process_status = 'NEW') s
ON    (e.emp_id = s.emp_id)
WHEN MATCHED THEN UPDATE SET
      e.first_name = s.first_name, e.last_name = s.last_name,
      e.email      = s.email,      e.job_title = s.job_title,
      e.salary     = s.salary,     e.dept_id   = s.dept_id,
      e.last_update_date = SYSTIMESTAMP
WHEN NOT MATCHED THEN INSERT
      (emp_id, first_name, last_name, email, job_title, salary, hire_date, dept_id)
      VALUES (s.emp_id, s.first_name, s.last_name, s.email, s.job_title,
              s.salary, TRUNC(SYSDATE), s.dept_id);

SELECT emp_id, first_name, job_title, salary FROM employees
WHERE  emp_id IN (104, 108, 111) ORDER BY emp_id;
SELECT COUNT(*) FROM employees;                 -- 12
COMMIT;

-- duplicates check before a load -> no rows
SELECT emp_id, COUNT(*) FROM employee_stg GROUP BY emp_id HAVING COUNT(*) > 1;

-- ch 14 · sequence
CREATE SEQUENCE emp_seq START WITH 200;
SELECT emp_seq.NEXTVAL FROM dual;               -- 200
SELECT emp_seq.NEXTVAL FROM dual;               -- 201
SELECT emp_seq.CURRVAL FROM dual;               -- 201
DROP SEQUENCE emp_seq;

-- ch 15 · view and index
CREATE OR REPLACE VIEW emp_details_v AS
SELECT e.emp_id, e.first_name, e.last_name, e.job_title, e.salary,
       d.dept_name, d.location, e.last_update_date
FROM   employees e
LEFT   JOIN departments d ON e.dept_id = d.dept_id;

SELECT first_name, dept_name FROM emp_details_v WHERE location = 'Pune';

CREATE INDEX emp_last_update_ix ON employees (last_update_date);

-- CHALLENGE ANSWERS (on fresh data: run phase4-setup.sql again first) ===

-- A: each department's top earner -> Finance Priya, HR Ravi, IT Amit, Sales Karan
SELECT d.dept_name, e.first_name, e.salary
FROM   employees e
JOIN   departments d ON e.dept_id = d.dept_id
WHERE  e.salary = (SELECT MAX(x.salary) FROM employees x WHERE x.dept_id = e.dept_id)
ORDER  BY d.dept_name;

-- B: managers and team size -> Amit 2, Karan 1, Priya 1, Ravi 1
SELECT m.first_name AS manager, COUNT(*) AS team_size
FROM   employees e
JOIN   employees m ON e.manager_id = m.emp_id
GROUP  BY m.first_name
ORDER  BY team_size DESC, m.first_name;

-- C: paid above their department's average -> Ravi, Priya, Amit, Karan
SELECT e.first_name, e.salary, e.dept_id
FROM   employees e
WHERE  e.salary > (SELECT AVG(x.salary) FROM employees x WHERE x.dept_id = e.dept_id)
ORDER  BY e.emp_id;
