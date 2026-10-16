-- =====================================================================
--  OIC from Scratch · Phase 4.3 · PL/SQL & databases in OIC
--  by @devwithprabir
--  Run phase4-setup.sql first. Paste one block at a time and run it with
--  Run Script (F5): printed lines appear in the Script Output.
--  (SQL*Plus / SQL Developer: run SET SERVEROUTPUT ON first)
-- =====================================================================

-- ch 2 · hello ---------------------------------------------------------
BEGIN
  DBMS_OUTPUT.PUT_LINE('Hello from inside the database');
END;
/

-- ch 3 · variables and SELECT INTO  -> Sneha earns 85000, bonus 8500 ---
DECLARE
  v_name   employees.first_name%TYPE;
  v_salary employees.salary%TYPE;
  c_bonus  CONSTANT NUMBER := 0.10;
BEGIN
  SELECT first_name, salary
  INTO   v_name, v_salary
  FROM   employees
  WHERE  emp_id = 104;

  DBMS_OUTPUT.PUT_LINE(v_name || ' earns ' || v_salary
                       || ', bonus ' || v_salary * c_bonus);
END;
/

-- %ROWTYPE  -> Ravi Kumar, HR Manager
DECLARE
  r employees%ROWTYPE;
BEGIN
  SELECT * INTO r FROM employees WHERE emp_id = 101;
  DBMS_OUTPUT.PUT_LINE(r.first_name || ' ' || r.last_name || ', ' || r.job_title);
END;
/

-- ch 4 · IF  -> Arjun is in band B ----------------------------------------
DECLARE
  v_salary employees.salary%TYPE;
  v_band   VARCHAR2(10);
BEGIN
  SELECT salary INTO v_salary FROM employees WHERE emp_id = 105;

  IF v_salary >= 100000 THEN
    v_band := 'A';
  ELSIF v_salary >= 70000 THEN
    v_band := 'B';
  ELSE
    v_band := 'C';
  END IF;

  DBMS_OUTPUT.PUT_LINE('Arjun is in band ' || v_band);
END;
/

-- ch 5 · loops -------------------------------------------------------------
BEGIN
  FOR r IN (SELECT first_name, salary
            FROM   employees
            WHERE  dept_id = 30
            ORDER  BY emp_id) LOOP
    DBMS_OUTPUT.PUT_LINE(r.first_name || ': ' || r.salary);
  END LOOP;
END;
/

BEGIN
  FOR i IN 1 .. 3 LOOP
    DBMS_OUTPUT.PUT_LINE('Attempt ' || i);
  END LOOP;
END;
/

DECLARE
  v_wait NUMBER := 1;
BEGIN
  WHILE v_wait <= 8 LOOP
    DBMS_OUTPUT.PUT_LINE('wait ' || v_wait || 's');
    v_wait := v_wait * 2;
  END LOOP;
END;
/

-- ch 6 · exceptions  -> No employee 999 -----------------------------------
--        (change the WHERE to dept_id = 30 -> More than one row)
DECLARE
  v_name employees.first_name%TYPE;
BEGIN
  SELECT first_name INTO v_name FROM employees WHERE emp_id = 999;
  DBMS_OUTPUT.PUT_LINE('Found ' || v_name);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    DBMS_OUTPUT.PUT_LINE('No employee 999');
  WHEN TOO_MANY_ROWS THEN
    DBMS_OUTPUT.PUT_LINE('More than one row');
END;
/

-- ch 7 · a procedure ------------------------------------------------------
CREATE OR REPLACE PROCEDURE give_raise (
  p_emp_id     IN  employees.emp_id%TYPE,
  p_percent    IN  NUMBER,
  p_new_salary OUT employees.salary%TYPE
) AS
BEGIN
  IF p_percent NOT BETWEEN 0 AND 50 THEN
    RAISE_APPLICATION_ERROR(-20002, 'Raise must be between 0 and 50 percent');
  END IF;

  UPDATE employees
  SET    salary = ROUND(salary * (1 + p_percent / 100), 2),
         last_update_date = SYSTIMESTAMP
  WHERE  emp_id = p_emp_id
  RETURNING salary INTO p_new_salary;

  IF SQL%ROWCOUNT = 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'Employee ' || p_emp_id || ' not found');
  END IF;
END give_raise;
/

-- call it  -> New salary: 85800
DECLARE
  v_new employees.salary%TYPE;
BEGIN
  give_raise(p_emp_id => 105, p_percent => 10, p_new_salary => v_new);
  DBMS_OUTPUT.PUT_LINE('New salary: ' || v_new);
  ROLLBACK;
END;
/

-- employee 999 -> ORA-20001: Employee 999 not found
DECLARE
  v_new employees.salary%TYPE;
BEGIN
  give_raise(999, 10, v_new);
END;
/

-- 80% -> ORA-20002
DECLARE
  v_new employees.salary%TYPE;
BEGIN
  give_raise(105, 80, v_new);
END;
/

-- ch 8 · a function -------------------------------------------------------
CREATE OR REPLACE FUNCTION get_dept_name (
  p_dept_id IN departments.dept_id%TYPE
) RETURN VARCHAR2 AS
  v_name departments.dept_name%TYPE;
BEGIN
  SELECT dept_name INTO v_name FROM departments WHERE dept_id = p_dept_id;
  RETURN v_name;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN 'Unknown';
END get_dept_name;
/

-- -> Sneha IT, Vikram Unknown
SELECT first_name, get_dept_name(dept_id) AS dept
FROM   employees WHERE emp_id IN (104, 109) ORDER BY emp_id;

-- ch 9-10 · the package --------------------------------------------------
CREATE OR REPLACE PACKAGE hr_int AS
  PROCEDURE load_staged_employees (
    p_run_name IN  VARCHAR2,
    p_merged   OUT NUMBER,
    p_errors   OUT NUMBER);

  FUNCTION get_dept_name (p_dept_id IN NUMBER) RETURN VARCHAR2;
END hr_int;
/

CREATE OR REPLACE PACKAGE BODY hr_int AS

  -- private: not in the spec, so only this package can call it
  PROCEDURE log_run (p_run_name IN VARCHAR2, p_status IN VARCHAR2, p_message IN VARCHAR2) IS
  BEGIN
    INSERT INTO integration_log (run_name, status, message)
    VALUES (p_run_name, p_status, SUBSTR(p_message, 1, 400));
  END log_run;

  PROCEDURE load_staged_employees (p_run_name IN  VARCHAR2,
                                   p_merged   OUT NUMBER,
                                   p_errors   OUT NUMBER) IS
  BEGIN
    -- 1. validate: the department must exist
    UPDATE employee_stg s
    SET    s.process_status = 'ERROR',
           s.error_message  = 'Unknown department ' || s.dept_id
    WHERE  s.process_status = 'NEW'
    AND    NOT EXISTS (SELECT 1 FROM departments d WHERE d.dept_id = s.dept_id);
    p_errors := SQL%ROWCOUNT;

    -- 2. upsert the good rows
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
    p_merged := SQL%ROWCOUNT;

    -- 3. mark them done
    UPDATE employee_stg SET process_status = 'PROCESSED' WHERE process_status = 'NEW';

    -- 4 + 5. log and save, all together
    log_run(p_run_name, 'SUCCESS', p_merged || ' merged, ' || p_errors || ' rejected');
    COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;                                 -- undo 1-3
      log_run(p_run_name, 'FAILED', SQLERRM);   -- remember why
      COMMIT;                                   -- keep the log row
      RAISE;                                    -- and tell the caller (OIC) it failed
  END load_staged_employees;

  FUNCTION get_dept_name (p_dept_id IN NUMBER) RETURN VARCHAR2 IS
    v_name departments.dept_name%TYPE;
  BEGIN
    SELECT dept_name INTO v_name FROM departments WHERE dept_id = p_dept_id;
    RETURN v_name;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      RETURN 'Unknown';
  END get_dept_name;

END hr_int;
/

-- a bad staging row: department 99 does not exist
INSERT INTO employee_stg (emp_id, first_name, last_name, email, job_title, salary, dept_id)
VALUES (113, 'Kavya', 'Rao', 'kavya.rao@company.com', 'Analyst', 65000, 99);
COMMIT;

-- run the loader  -> Merged: 3, errors: 1   (run it again -> Merged: 0, errors: 0)
DECLARE
  v_merged NUMBER;
  v_errors NUMBER;
BEGIN
  hr_int.load_staged_employees('manual-test-1', v_merged, v_errors);
  DBMS_OUTPUT.PUT_LINE('Merged: ' || v_merged || ', errors: ' || v_errors);
END;
/

SELECT emp_id, process_status, error_message FROM employee_stg ORDER BY emp_id;
SELECT log_id, run_name, status, message FROM integration_log ORDER BY log_id;

-- ch 12 · JSON ------------------------------------------------------------
SELECT JSON_VALUE('{"emp":{"id":101,"name":"Ravi"}}', '$.emp.name') AS name FROM dual;

SELECT jt.id, jt.name
FROM   JSON_TABLE(
         '{"employees":[{"id":201,"name":"Kiran"},{"id":202,"name":"Asha"}]}',
         '$.employees[*]'
         COLUMNS (id   NUMBER       PATH '$.id',
                  name VARCHAR2(30) PATH '$.name')) jt;

SELECT JSON_OBJECT('id' VALUE emp_id, 'name' VALUE first_name) AS payload
FROM   employees WHERE emp_id = 104;

-- ch 15 · a bind variable in dynamic SQL  -> 1
DECLARE
  v_count NUMBER;
  p_input VARCHAR2(50) := 'Kumar';
BEGIN
  EXECUTE IMMEDIATE
    'SELECT COUNT(*) FROM employees WHERE last_name = :name'
    INTO v_count
    USING p_input;
  DBMS_OUTPUT.PUT_LINE(v_count);
END;
/

-- CHALLENGE ANSWERS ========================================================

-- A: years of service  -> 9
CREATE OR REPLACE FUNCTION years_of_service (
  p_emp_id IN employees.emp_id%TYPE,
  p_as_of  IN DATE DEFAULT SYSDATE
) RETURN NUMBER AS
  v_hired employees.hire_date%TYPE;
BEGIN
  SELECT hire_date INTO v_hired FROM employees WHERE emp_id = p_emp_id;
  RETURN TRUNC(MONTHS_BETWEEN(p_as_of, v_hired) / 12);
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN NULL;
END years_of_service;
/
SELECT years_of_service(103, DATE '2026-10-16') AS years FROM dual;

-- B: add this UPDATE to load_staged_employees, right after step 1,
--    and add its SQL%ROWCOUNT to p_errors:
--
--    UPDATE employee_stg
--    SET    process_status = 'ERROR', error_message = 'Invalid salary'
--    WHERE  process_status = 'NEW'
--    AND    (salary IS NULL OR salary <= 0);
--    p_errors := p_errors + SQL%ROWCOUNT;

-- C: department summary  -> 30: 3 and 293000 (fresh data)
CREATE OR REPLACE PROCEDURE dept_summary (
  p_dept_id   IN  departments.dept_id%TYPE,
  p_headcount OUT NUMBER,
  p_total_pay OUT NUMBER
) AS
BEGIN
  SELECT COUNT(*), NVL(SUM(salary), 0)
  INTO   p_headcount, p_total_pay
  FROM   employees
  WHERE  dept_id = p_dept_id;
END dept_summary;
/

DECLARE
  v_count NUMBER;
  v_total NUMBER;
BEGIN
  dept_summary(30, v_count, v_total);
  DBMS_OUTPUT.PUT_LINE(v_count || ' people, total pay ' || v_total);
END;
/
