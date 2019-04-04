WITH numbers AS (
    SELECT ROW_NUMBER() OVER (ORDER BY c1.column_id) AS number
    FROM sys.columns c1, sys.columns c2
)
SELECT TOP 255
    numbers.number
,   CHAR(numbers.number)
,   NCHAR(numbers.number)
FROM numbers