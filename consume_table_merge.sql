----Merge Statement
MERGE INTO demo_aws_s3.yusuf_cattaneo_demo.customer as a
USING (
    SELECT
        coalesce(before.custkey, after.custkey) as custkey,
        after.first_name,
        after.city,
        after.state,
        after.fico,
        after.registration_date,
        ts_ms,
        op,
        ROW_NUMBER() OVER (PARTITION BY coalesce(before.custkey, after.custkey) ORDER BY ts_ms DESC) as row_num,
        source.lsn
    FROM
        "demo_aws_s3"."yusuf_cattaneo_demo"."postgres.burst_bank.customer"
) latest_changes
ON a.custkey = latest_changes.custkey AND latest_changes.row_num = 1
WHEN MATCHED and latest_changes.op = 'd' THEN DELETE
WHEN MATCHED AND a.ts_ms < latest_changes.ts_ms THEN UPDATE
    SET
        custkey = latest_changes.custkey,
        first_name = latest_changes.first_name,
        city = latest_changes.city,
        state = latest_changes.state,
        fico = latest_changes.fico,
        registration_date = latest_changes.registration_date,
        ts_ms = latest_changes.ts_ms
WHEN NOT MATCHED and latest_changes.row_num = 1 and latest_changes.op != 'd' THEN
    INSERT (custkey, first_name, city, state, fico, registration_date, ts_ms)
    VALUES (
        latest_changes.custkey,
        latest_changes.first_name,
        latest_changes.city,
        latest_changes.state,
        latest_changes.fico,
        latest_changes.registration_date,
        latest_changes.ts_ms
    );
