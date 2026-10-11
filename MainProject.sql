
CREATE TABLE Customer (
    CustomerID SERIAL PRIMARY KEY,
    CustomerName VARCHAR(100) NOT NULL,
    Email VARCHAR(100) UNIQUE NOT NULL,
    Phone VARCHAR(15) NOT NULL
);

CREATE TABLE Venue (
    VenueID SERIAL PRIMARY KEY,
    VenueName VARCHAR(100) NOT NULL,
    Location VARCHAR(150) NOT NULL,
    Capacity INT NOT NULL CHECK (Capacity > 0),
    PricePerEvent DECIMAL(10,2) NOT NULL CHECK (PricePerEvent >= 0)
);

CREATE TABLE Event (
    EventID SERIAL PRIMARY KEY,
    EventName VARCHAR(100) NOT NULL,
    EventType VARCHAR(50) NOT NULL
);

CREATE TABLE Package (
    PackageID SERIAL PRIMARY KEY,
    PackageName VARCHAR(100) NOT NULL,
    Description VARCHAR(255),
    PackagePrice DECIMAL(10,2) NOT NULL CHECK (PackagePrice >= 0)
);

CREATE TABLE Booking (
    BookingID SERIAL PRIMARY KEY,
    CustomerID INT NOT NULL REFERENCES Customer(CustomerID),
    VenueID INT NOT NULL REFERENCES Venue(VenueID),
    EventID INT NOT NULL REFERENCES Event(EventID),
    PackageID INT REFERENCES Package(PackageID),
    EventDate DATE NOT NULL,
    StartTime TIME NOT NULL,
    EndTime TIME NOT NULL,
    GuestCount INT NOT NULL CHECK (GuestCount > 0),
    Status VARCHAR(20) NOT NULL DEFAULT 'Confirmed',
    CHECK (EndTime > StartTime)
);

CREATE TABLE Payment (
    PaymentID SERIAL PRIMARY KEY,
    BookingID INT NOT NULL REFERENCES Booking(BookingID),
    PaymentDate DATE NOT NULL DEFAULT CURRENT_DATE,
    Amount DECIMAL(10,2) NOT NULL CHECK (Amount > 0),
    PaymentStatus VARCHAR(20) NOT NULL DEFAULT 'Paid'
);



INSERT INTO Customer (CustomerName, Email, Phone)
VALUES
('Rahul Sharma', 'rahul@gmail.com', '9876543210'),
('Priya Mehta', 'priya@gmail.com', '9876543211'),
('Arjun Patel', 'arjun@gmail.com', '9876543212'),
('Sneha Kapoor', 'sneha@gmail.com', '9876543213'),
('Karan Shah', 'karan@gmail.com', '9876543214');



INSERT INTO Venue (VenueName, Location, Capacity, PricePerEvent)
VALUES
('Grand Palace', 'Mumbai', 500, 75000),
('Royal Banquet Hall', 'Navi Mumbai', 300, 50000),
('Sunset Garden', 'Thane', 800, 100000),
('Crystal Convention Centre', 'Mumbai', 1000, 150000),
('Pearl Party Hall', 'Panvel', 200, 35000);



INSERT INTO Event (EventName, EventType)
VALUES
('Rahul Wedding', 'Wedding'),
('Priya Birthday', 'Birthday'),
('Tech Conference 2026', 'Conference'),
('Corporate Annual Meet', 'Corporate'),
('Arjun Engagement', 'Engagement');



INSERT INTO Package (PackageName, Description, PackagePrice)
VALUES
('Basic', 'Basic decoration and seating', 15000),
('Standard', 'Decoration, catering and seating', 30000),
('Premium', 'Premium decoration, catering and entertainment', 60000),
('Corporate', 'Projector, sound system and catering', 45000),
('Wedding Special', 'Complete wedding decoration and catering', 80000);



INSERT INTO Booking
(CustomerID, VenueID, EventID, PackageID,
EventDate, StartTime, EndTime, GuestCount, Status)
VALUES
(1, 1, 1, 5, '2026-10-15', '18:00', '22:00', 450, 'Confirmed'),
(2, 2, 2, 2, '2026-10-18', '17:00', '20:00', 250, 'Confirmed'),
(3, 3, 3, 4, '2026-10-20', '09:00', '17:00', 700, 'Confirmed'),
(4, 4, 4, 4, '2026-10-22', '10:00', '16:00', 800, 'Confirmed'),
(5, 5, 5, 1, '2026-10-25', '18:00', '21:00', 150, 'Confirmed');



INSERT INTO Payment
(BookingID, PaymentDate, Amount, PaymentStatus)
VALUES
(1, '2026-10-01', 155000, 'Paid'),
(2, '2026-10-02', 80000, 'Paid'),
(3, '2026-10-03', 145000, 'Paid'),
(4, '2026-10-04', 195000, 'Paid'),
(5, '2026-10-05', 50000, 'Paid');


CREATE OR REPLACE FUNCTION check_booking_overlap()
RETURNS TRIGGER AS $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM Booking
        WHERE VenueID = NEW.VenueID
        AND EventDate = NEW.EventDate
        AND Status = 'Confirmed'
        AND BookingID <> COALESCE(NEW.BookingID, 0)
        AND StartTime < NEW.EndTime
        AND EndTime > NEW.StartTime
    ) THEN
        RAISE EXCEPTION
        'Venue is already booked for an overlapping time slot.';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


CREATE TRIGGER booking_overlap_trigger
BEFORE INSERT OR UPDATE ON Booking
FOR EACH ROW
EXECUTE FUNCTION check_booking_overlap();



SELECT
    c.CustomerName,
    e.EventName,
    v.VenueName,
    b.EventDate,
    b.StartTime,
    b.EndTime,
    b.GuestCount,
    b.Status
FROM Booking b
JOIN Customer c ON b.CustomerID = c.CustomerID
JOIN Event e ON b.EventID = e.EventID
JOIN Venue v ON b.VenueID = v.VenueID
ORDER BY b.EventDate;



SELECT
    v.VenueID,
    v.VenueName,
    v.Location,
    v.Capacity,
    v.PricePerEvent
FROM Venue v
WHERE v.Capacity >= 400
AND NOT EXISTS (
    SELECT 1
    FROM Booking b
    WHERE b.VenueID = v.VenueID
      AND b.EventDate = '2026-10-15'
      AND b.Status = 'Confirmed'
      AND b.StartTime < '21:00'
      AND b.EndTime > '19:00'
);


-- ---------------------------------------------------------
-- Query 3: Revenue by Venue
-- ---------------------------------------------------------

SELECT
    v.VenueName,
    SUM(p.Amount) AS TotalRevenue
FROM Payment p
JOIN Booking b ON p.BookingID = b.BookingID
JOIN Venue v ON b.VenueID = v.VenueID
WHERE p.PaymentStatus = 'Paid'
GROUP BY v.VenueName
ORDER BY TotalRevenue DESC;


-- ---------------------------------------------------------
-- Query 4: Venue Utilization
-- ---------------------------------------------------------

SELECT
    v.VenueName,
    COUNT(b.BookingID) AS TotalBookings
FROM Venue v
LEFT JOIN Booking b
    ON v.VenueID = b.VenueID
    AND b.Status = 'Confirmed'
GROUP BY v.VenueName
ORDER BY TotalBookings DESC;


-- =========================================================
-- END OF EVENTEASE PROJECT
-- =========================================================