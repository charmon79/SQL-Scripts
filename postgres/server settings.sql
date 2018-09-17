SELECT
	name
,	setting
,	unit
,	short_desc
,	context
FROM pg_settings
WHERE name like '%work%'
;