-- Redshift COPY command template
COPY analytics.users (id, firstname, lastname, email, status)
FROM 's3://your-redshift-bucket/topics/AnalyticdbOpt.zalvadora_local_2.users/'
IAM_ROLE 'arn:aws:iam::YOUR_ACCOUNT:role/RedshiftRole'
FORMAT AS PARQUET
DATEFORMAT 'auto'
TIMEFORMAT 'auto';