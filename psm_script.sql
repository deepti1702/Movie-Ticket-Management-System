USE MTRS;
GO

CREATE PROCEDURE GetUserDetails 
    @UserID INT,
    @UserEmail VARCHAR(255) OUTPUT
AS
BEGIN
    SELECT @UserEmail = Email 
    FROM Users
    WHERE User_ID = @UserID;
    DECLARE @UserName VARCHAR(255), @UserPhone VARCHAR(20);
    
    SELECT @UserName = Name, @UserPhone = Phone_Number
    FROM Users
    WHERE User_ID = @UserID;
END;
GO

ALTER PROCEDURE GetUserDetails 
    @UserID INT,
    @UserEmail VARCHAR(255) OUTPUT,
    @UserName VARCHAR(255) OUTPUT,
    @UserPhone VARCHAR(20) OUTPUT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        SELECT @UserEmail = Email, @UserName = Name, @UserPhone = Phone_Number
        FROM Users
        WHERE User_ID = @UserID;

        -- Ensure the user exists
        IF @UserEmail IS NULL
        BEGIN
            RAISERROR('User not found', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT 'Error: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

--Displaying Output from GetUserDetails Procedure

DECLARE @UserEmail VARCHAR(255),
        @UserName VARCHAR(255),
        @UserPhone VARCHAR(20);

-- Execute the procedure with a UserID of 1 
EXEC GetUserDetails @UserID = 1, 
                    @UserEmail = @UserEmail OUTPUT, 
                    @UserName = @UserName OUTPUT, 
                    @UserPhone = @UserPhone OUTPUT;

-- Display the output variables
SELECT @UserEmail AS 'User Email',
       @UserName AS 'User Name',
       @UserPhone AS 'User Phone';


CREATE PROCEDURE UpdateMovieRating 
    @MovieID INT,
    @NewRating DECIMAL(3, 1)
AS
BEGIN
    UPDATE Movies
    SET Rating = @NewRating
    WHERE Movie_ID = @MovieID;
END;
GO

ALTER PROCEDURE UpdateMovieRating 
    @MovieID INT,
    @NewRating DECIMAL(3, 1)
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Check if movie exists
        IF NOT EXISTS (SELECT 1 FROM Movies WHERE Movie_ID = @MovieID)
        BEGIN
            RAISERROR('Movie not found', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Update rating
        UPDATE Movies 
        SET Rating = @NewRating 
        WHERE Movie_ID = @MovieID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT 'Error: ' + ERROR_MESSAGE();
    END CATCH;
END;
GO

--Displaying Output from UpdateMovieRating Procedure

EXEC UpdateMovieRating @MovieID = 10,  
                       @NewRating = 4.5; 

-- Display the updated movie rating
SELECT Title, Rating
FROM Movies
WHERE Movie_ID = 10; 


CREATE PROCEDURE GetTotalBookingsForMovie 
    @MovieID INT,
    @TotalBookings INT OUTPUT
AS
BEGIN
    SELECT @TotalBookings = COUNT(*)
    FROM Bookings
    WHERE Show_ID IN (SELECT Show_ID FROM Shows WHERE Movie_ID = @MovieID);
END;
GO

ALTER PROCEDURE GetTotalBookingsForMovie 
    @MovieID INT,
    @TotalBookings INT OUTPUT
AS
BEGIN
    BEGIN TRY
        BEGIN TRANSACTION;

        -- Initialize @TotalBookings to 0 to prevent NULL output
        SET @TotalBookings = 0;

        -- Calculate total bookings
        SELECT @TotalBookings = COUNT(*)
        FROM Bookings
        WHERE Show_ID IN (SELECT Show_ID FROM Shows WHERE Movie_ID = @MovieID);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        PRINT 'Error: ' + ERROR_MESSAGE();
        SET @TotalBookings = -1; -- Indicate an error
    END CATCH;
END;
GO

-- Displaying Output from GetTotalBookingsForMovie Procedure

DECLARE @TotalBookings INT;
-- Execute the procedure to get total bookings for a specific MovieID
EXEC GetTotalBookingsForMovie @MovieID = 10, 
                              @TotalBookings = @TotalBookings OUTPUT;
-- Display the total bookings
SELECT @TotalBookings AS 'Total Bookings';

CREATE FUNCTION GetDiscountedPrice(@OriginalPrice DECIMAL(10, 2), @DiscountID INT)
RETURNS DECIMAL(10, 2)
AS
BEGIN
    DECLARE @DiscountRate DECIMAL(5, 2);
    SELECT @DiscountRate = Discount_Percentage FROM Discounts WHERE Discount_ID = @DiscountID;
    RETURN @OriginalPrice * (1 - @DiscountRate / 100);
END;
GO

CREATE FUNCTION GetUserFullName(@UserID INT)
RETURNS VARCHAR(255)
AS
BEGIN
    DECLARE @FullName VARCHAR(255);
    SELECT @FullName = Name FROM Users WHERE User_ID = @UserID;
    RETURN @FullName;
END;
GO

CREATE FUNCTION AvailableSeatsForShow(@ShowID INT)
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM Seats WHERE Show_ID = @ShowID AND Status = 'A');
END;
GO

CREATE VIEW UserBookingDetails AS
SELECT u.Name, b.Booking_ID, s.Show_Time, m.Title
FROM Users u
JOIN Bookings b ON u.User_ID = b.User_ID
JOIN Shows s ON b.Show_ID = s.Show_ID
JOIN Movies m ON s.Movie_ID = m.Movie_ID;
GO

CREATE VIEW AvailableSeats AS
SELECT s.Seat_Number, m.Title, sh.Show_Time
FROM Seats s
JOIN Shows sh ON s.Show_ID = sh.Show_ID
JOIN Movies m ON sh.Movie_ID = m.Movie_ID 
WHERE s.Status = 'A';
GO

CREATE VIEW MovieRatings AS
SELECT m.Title, AVG(r.Rating) AS AvgRating
FROM Reviews r
JOIN Movies m ON r.Movie_ID = m.Movie_ID 
GROUP BY m.Title;
GO

CREATE TRIGGER trgAfterBookingUpdate
ON Bookings
AFTER UPDATE
AS
BEGIN
    INSERT INTO BookingLogs (Booking_ID, ChangedOn, ChangeType)
    SELECT Booking_ID, GETDATE(), 'UPDATE'
    FROM INSERTED;
END;
GO

 --create log table
 — CREATE TABLE BookingLogs (
    LogID INT IDENTITY(1,1) PRIMARY KEY,
    Booking_ID INT,
    ChangedOn DATETIME,
    ChangeType VARCHAR(50)
);
GO

-- Make an update to a booking to trigger the trigger
UPDATE Bookings
SET Show_ID = 2 
WHERE Booking_ID = 1; 
 --query from log table 
SELECT * FROM BookingLogs;