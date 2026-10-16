-- =====================================================================
--  OIC from Scratch · Phase 4.1 · Databases & SELECT     by @devwithprabir
--  Run phase4-setup.sql first. Then run each query on its own
--  (put the cursor in it and press Ctrl/Cmd + Enter).
-- =====================================================================

-- ch 8 · SELECT -------------------------------------------------------
SELECT * FROM departments;

SELECT emp_id,
       first_name || ' ' || last_name AS full_name,
       salary * 12                    AS annual_salary
FROM   employees
WHERE  dept_id = 30
ORDER  BY emp_id;

SELECT 2 + 3 AS answer, UPPER('oic') AS shout FROM dual;

-- ch 9 · WHERE --------------------------------------------------------
SELECT emp_id, first_name, salary FROM employees
WHERE  salary BETWEEN 50000 AND 80000 ORDER BY emp_id;

SELECT first_name, last_name FROM employees
WHERE  last_name LIKE '_a%' ORDER BY emp_id;

-- precedence: 3 rows, then 2 rows
SELECT emp_id, dept_id, salary FROM employees
WHERE  dept_id = 30 OR dept_id = 40 AND salary > 80000 ORDER BY emp_id;

SELECT emp_id, dept_id, salary FROM employees
WHERE  (dept_id = 30 OR dept_id = 40) AND salary > 80000 ORDER BY emp_id;

-- the NULL traps
SELECT * FROM employees WHERE email = NULL;      -- no rows!
SELECT * FROM employees WHERE email IS NULL;     -- Karan

SELECT emp_id, dept_id FROM employees
WHERE  dept_id NOT IN (10, 20) ORDER BY emp_id;  -- Vikram is missing
SELECT emp_id, dept_id FROM employees
WHERE  dept_id NOT IN (10, 20) OR dept_id IS NULL ORDER BY emp_id;

-- ch 10 · ORDER BY and DISTINCT ---------------------------------------
SELECT emp_id, first_name, dept_id FROM employees ORDER BY dept_id NULLS FIRST, emp_id;
SELECT DISTINCT job_title FROM employees ORDER BY job_title;

-- ch 11 · paging ------------------------------------------------------
SELECT first_name, salary FROM employees
ORDER  BY salary DESC FETCH FIRST 3 ROWS ONLY;

SELECT first_name, salary FROM employees
ORDER  BY salary DESC OFFSET 3 ROWS FETCH NEXT 3 ROWS ONLY;

SELECT first_name, salary FROM employees
ORDER  BY salary DESC, emp_id OFFSET 6 ROWS FETCH NEXT 3 ROWS ONLY;

-- ch 12 · functions ---------------------------------------------------
SELECT emp_id,
       UPPER(last_name)                                          AS surname,
       NVL(SUBSTR(email, 1, INSTR(email, '@') - 1), 'no email')  AS username
FROM   employees
WHERE  dept_id = 40 ORDER BY emp_id;

SELECT first_name FROM employees WHERE UPPER(first_name) = 'RAVI';

SELECT INITCAP('ravi KUMAR') AS a, LENGTH('Pune') AS b, TRIM('  HR  ') AS c,
       REPLACE('IT Dept', 'Dept', 'Team') AS d, ROUND(97666.667, 2) AS e, TRUNC(7.9) AS f
FROM   dual;

-- ch 13 · dates -------------------------------------------------------
SELECT first_name,
       TO_CHAR(hire_date, 'DD-Mon-YYYY') AS hired,
       TO_CHAR(hire_date, 'DD/MM/YYYY')  AS hired_in
FROM   employees ORDER BY emp_id;

SELECT DATE '2026-10-16' + 30                  AS plus_30,
       DATE '2026-10-16' - DATE '2026-10-01'   AS days_between,
       ADD_MONTHS(DATE '2026-01-31', 1)        AS month_end
FROM   dual;

SELECT emp_id,
       TO_CHAR(last_update_date, 'YYYY-MM-DD"T"HH24:MI:SS') AS updated_iso
FROM   employees
WHERE  last_update_date > TIMESTAMP '2026-10-13 00:00:00'
ORDER  BY emp_id;

SELECT first_name, TRUNC(MONTHS_BETWEEN(DATE '2026-10-16', hire_date) / 12) AS years
FROM   employees ORDER BY years DESC FETCH FIRST 3 ROWS ONLY;

-- ch 14 · CASE --------------------------------------------------------
SELECT first_name, salary,
       CASE
         WHEN salary >= 100000 THEN 'Band A'
         WHEN salary >=  70000 THEN 'Band B'
         ELSE                       'Band C'
       END AS band
FROM   employees
ORDER  BY salary DESC;

SELECT emp_id,
       CASE status WHEN 'ACTIVE' THEN 'A' WHEN 'INACTIVE' THEN 'I' ELSE '?' END AS status_code
FROM   employees WHERE emp_id IN (109, 110);

-- ch 15 · challenge answers --------------------------------------------
-- A: active developers, highest salary first  -> Sneha, Arjun
SELECT first_name, job_title, salary FROM employees
WHERE  status = 'ACTIVE' AND job_title LIKE '%Developer%'
ORDER  BY salary DESC;

-- B: hired before 2020, oldest first  -> Amit, Priya, Ravi
SELECT first_name, TO_CHAR(hire_date, 'DD/MM/YYYY') AS hired
FROM   employees
WHERE  hire_date < DATE '2020-01-01'
ORDER  BY hire_date;

-- C: email check  -> 9 x Y, Karan N
SELECT first_name,
       CASE WHEN email LIKE '%@company.com' THEN 'Y' ELSE 'N' END AS email_ok
FROM   employees ORDER BY emp_id;
