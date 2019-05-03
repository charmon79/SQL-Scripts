SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
 
;WITH cteWaits (DeviceID, ConnectionID, Class, WaitTime)
AS
(
  SELECT
    dat.DeviceID,
    dat.EventSourceConnectionID,
    waitclass.Name AS Class, 
    SUM(dat.Value) AS WaitTime
  FROM dbo.PerformanceAnalysisDataRollup2 AS dat
  INNER JOIN dbo.PerformanceAnalysisWaitType AS waittype
    ON dat.PerformanceAnalysisCounterID = waittype.WaitCounterID
  INNER JOIN dbo.PerformanceAnalysisWaitTypeClass AS waitclass
    ON waitclass.ID = waittype.WaitTypeClassID
  GROUP BY
    dat.DeviceID,
    dat.EventSourceConnectionID,
    waitclass.Name
),
cteSignalWaits (DeviceID, ConnectionID, Class, SignalWaitTime)
AS
(
  SELECT
    dat.DeviceID,
    dat.EventSourceConnectionID,
    waitclass.Name AS Class, 
    SUM(dat.Value) AS SignalWaitTime
  FROM dbo.PerformanceAnalysisDataRollup2 AS dat
  INNER JOIN dbo.PerformanceAnalysisWaitType AS sigwaittype
    ON dat.PerformanceAnalysisCounterID = sigwaittype.SignalWaitCounterID
  INNER JOIN dbo.PerformanceAnalysisWaitTypeClass AS waitclass
    ON waitclass.ID = sigwaittype.WaitTypeClassID
  GROUP BY
    dat.DeviceID,
    dat.EventSourceConnectionID,
    waitclass.Name
)
SELECT
  c.ServerName, 
  InstanceName = COALESCE(c.InstanceName, 'DEFAULT'),
  w.Class,
  w.WaitTime,
  CASE WHEN (w.WaitTime - COALESCE(s.SignalWaitTime, 0) < 0) THEN
      0
  ELSE
      w.WaitTime - COALESCE(s.SignalWaitTime, 0)
  END AS ResourceWaitTime,
  COALESCE(s.SignalWaitTime, 0) AS CPUWaitTime,
  CASE WHEN (COALESCE(s.SignalWaitTime, 0) * 100 / w.WaitTime > 100) THEN
      100
  ELSE
      COALESCE(s.SignalWaitTime, 0) * 100 / w.WaitTime
  END AS PercentCPUWaits
FROM dbo.Device AS d
INNER JOIN dbo.EventSourceConnection AS c
  ON c.DeviceID = d.ID
INNER JOIN cteWaits AS w
  ON d.ID = w.DeviceID
  AND c.ID = w.ConnectionID
LEFT OUTER JOIN cteSignalWaits s 
  ON s.DeviceID = w.DeviceID
  AND s.ConnectionID = w.ConnectionID
  AND s.Class = w.Class
WHERE
  c.IsPerformanceAnalysisEnabled = 1
  and c.ServerName = 'SQL01.lab.local'
ORDER BY
  c.ServerName,
  c.InstanceName,
  w.Class;