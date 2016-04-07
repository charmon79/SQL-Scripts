USE atlas;
GO

CREATE FUNCTION dbo.awGetPersonPhoneList (@PersonId INT)
RETURNS NVARCHAR(MAX)
AS

BEGIN

DECLARE @xml XML;

SET @xml = (
SELECT
    pp.PhoneNumber
,   pnt.Name AS PhoneNumberType
FROM AdventureWorks2014.Person.PersonPhone AS pp
INNER JOIN AdventureWorks2014.Person.PhoneNumberType AS pnt ON pnt.PhoneNumberTypeID = pp.PhoneNumberTypeID
WHERE pp.BusinessEntityID = @PersonId
FOR XML PATH ('Phone'), ROOT('array')
);

RETURN atlas.dbo.FlattenedJSON(@xml, 'array', '')

END;
GO