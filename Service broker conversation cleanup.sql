

declare @conversationHandle UNIQUEIDENTIFIER
    ,   @lifetime DATETIME
    ,   @counter BIGINT = 0
;

SET NOCOUNT ON;

while (1 = 1)
begin
 
        SELECT TOP 1
            @conversationHandle = [conversation_handle]
        ,   @lifetime = [lifetime]
        FROM
            sys.conversation_endpoints;

        if @@rowcount = 0 break
        end conversation @conversationHandle with cleanup

        SET @counter += 1;
        IF @counter % 5000 = 0 CHECKPOINT;
end 


