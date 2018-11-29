SELECT
    *
FROM
    DBAdmin.dbo.DatabaseTableSizes
WHERE
    CollectedTime >= CAST(getdate() as date)
    AND DatabaseName = 'CADNCETEST'
    AND TableName NOT IN (
         'Aging'
        ,'AltAddress'
        ,'Brokers'
        ,'CalcClient'
        ,'CheckDtl'
        ,'CheckHdr'
        ,'CliBank'
        ,'CliBroker'
        ,'ClientGroup'
        ,'ClientHistory'
        ,'clients'
        ,'Contacts'
        ,'DebCredScore'
        ,'DebGroup'
        ,'DebGroupUse'
        ,'debtors'
        ,'Imagefolders'
        --,'Images'
        ,'Invoices'
        ,'InvVerNote'
        ,'MiscDataDefine'
        ,'MiscDataElement'
        ,'NoteCat'
        ,'NoteDtl'
        ,'NoteHdr'
        ,'Payments'
        ,'PmtChecks'
        ,'programs'
        ,'Transactions'
        ,'UserHdr'
        ,'VerMethod'
        ,'VerNote'
        ,'VerReceive'
    )
ORDER BY
    DataMB desc