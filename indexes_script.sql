USE MTRS;
GO

CREATE NONCLUSTERED INDEX idx_UserEmail ON Users (Email);
CREATE NONCLUSTERED INDEX idx_MovieTitle ON Movies (Title);
CREATE NONCLUSTERED INDEX idx_ShowTime ON Shows (Show_Time);