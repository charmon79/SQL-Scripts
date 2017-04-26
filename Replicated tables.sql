SELECT
    P.[publication]   AS [Publication Name]
   ,A.[publisher_db]  AS [Database Name]
   ,A.[article]       AS [Article Name]
   ,A.[source_owner]  AS [Schema]
   ,A.[source_object] AS [Table]
FROM
   [distribution].[dbo].[MSarticles] AS A
   INNER JOIN [distribution].[dbo].[MSpublications] AS P
       ON (A.[publication_id] = P.[publication_id])
        WHERE a.source_object LIKE '%property%'
ORDER BY
   P.[publication], A.[article];