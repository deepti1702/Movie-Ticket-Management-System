import streamlit as st
import matplotlib.pyplot as plt
from database import run_query, execute_query

st.set_page_config(layout="wide")
st.title("🎬 MTRS Movie Ticket Booking Dashboard")

page = st.sidebar.selectbox("Menu", [
    "🏠 Home", "👤 Users", "🎞️ Movies", "🎟️ Bookings", "💳 Payments"
])

# 🏠 HOME
if page == "🏠 Home":
    st.header("Welcome to MTRS Dashboard")
    total_users = run_query("SELECT COUNT(*) FROM Users").iloc[0, 0]
    total_bookings = run_query("SELECT COUNT(*) FROM Bookings").iloc[0, 0]
    total_revenue = run_query("SELECT ISNULL(SUM(Payment_Amount), 0) FROM Payments WHERE Payment_Status='Success'").iloc[0, 0]

    col1, col2, col3 = st.columns(3)
    col1.metric("👤 Total Users", total_users)
    col2.metric("🎟️ Total Bookings", total_bookings)
    col3.metric("💵 Revenue", f"${total_revenue:.2f}")

    st.markdown("---")
    st.subheader("📊 Average Ratings per Movie")
    ratings_df = run_query("SELECT * FROM MovieRatings")
    fig, ax = plt.subplots(figsize=(6,3))
    ax.bar(ratings_df["Title"], ratings_df["AvgRating"], color='tomato')
    ax.set_ylabel("Avg Rating")
    ax.set_xticklabels(ratings_df["Title"], rotation=45, ha='right')
    st.pyplot(fig)

# 👤 USERS
elif page == "👤 Users":
    st.header("User Management")
    users_df = run_query("SELECT * FROM Users")
    st.dataframe(users_df)

    action = st.selectbox("Choose Action", ["Add User", "Update User Email", "Delete User"])
    if action == "Add User":
        with st.form("add_user"):
            name = st.text_input("Name")
            email = st.text_input("Email")
            phone = st.text_input("Phone")
            password = st.text_input("Password", type="password")
            address = st.text_input("Address")
            if st.form_submit_button("Add User"):
                execute_query("""INSERT INTO Users (User_ID, Name, Email, Phone_Number, Password, Address)
                                 VALUES ((SELECT ISNULL(MAX(User_ID), 0)+1 FROM Users), ?, ?, ?, ?, ?)""",
                              (name, email, phone, password, address))
                st.success("User added.")
    elif action == "Update User Email":
        user_id = st.number_input("User ID to Update", min_value=1)
        new_email = st.text_input("New Email")
        if st.button("Update Email"):
            execute_query("UPDATE Users SET Email=? WHERE User_ID=?", (new_email, user_id))
            st.success("User email updated.")
    elif action == "Delete User":
        user_id = st.number_input("User ID to Delete", min_value=1)
        if st.button("Delete User"):
            execute_query("DELETE FROM Users WHERE User_ID=?", (user_id,))
            st.success("User deleted.")

# 🎞️ MOVIES
elif page == "🎞️ Movies":
    st.header("Movie Info and Ratings")
    movies_df = run_query("SELECT * FROM Movies")
    st.dataframe(movies_df)

    action = st.selectbox("Choose Action", ["Update Rating", "Add Movie", "Delete Movie"])
    if action == "Update Rating":
        movie_id = st.number_input("Movie ID", min_value=1)
        new_rating = st.number_input("New Rating", min_value=0.0, max_value=10.0, step=0.1)
        if st.button("Update Rating"):
            execute_query("EXEC UpdateMovieRating ?, ?", (movie_id, new_rating))
            st.success("Rating updated.")
    elif action == "Add Movie":
        with st.form("add_movie"):
            title = st.text_input("Title")
            genre = st.text_input("Genre")
            language = st.text_input("Language")
            rating = st.number_input("Rating", min_value=0.0, max_value=10.0, step=0.1)
            duration = st.number_input("Duration")
            description = st.text_area("Description")
            if st.form_submit_button("Add Movie"):
                execute_query("""INSERT INTO Movies (Movie_ID, Title, Genre, Language, Rating, Duration, Description)
                                 VALUES ((SELECT ISNULL(MAX(Movie_ID), 0)+1 FROM Movies), ?, ?, ?, ?, ?, ?)""",
                              (title, genre, language, rating, duration, description))
                st.success("Movie added.")
    elif action == "Delete Movie":
        movie_id = st.number_input("Movie ID to Delete", min_value=1)
        if st.button("Delete Movie"):
            execute_query("DELETE FROM Movies WHERE Movie_ID=?", (movie_id,))
            st.success("Movie deleted.")

# 🎟️ BOOKINGS
elif page == "🎟️ Bookings":
    st.header("Booking Management")
    bookings_df = run_query("SELECT * FROM UserBookingDetails")
    st.dataframe(bookings_df)

    st.subheader("📊 Total Bookings")
    movie_id = st.number_input("Enter Movie ID", min_value=1)
    if st.button("Get Total Bookings"):
        result = run_query("DECLARE @t INT; EXEC GetTotalBookingsForMovie ?, @t OUTPUT; SELECT @t AS TotalBookings", [movie_id])
        st.metric("Total Bookings", result.iloc[0, 0])

    # Fetch data for dropdowns
    users = run_query("SELECT User_ID, Name FROM Users")
    movies = run_query("SELECT Movie_ID, Title FROM Movies")
    showtimes = run_query("SELECT Showtime_ID, CONCAT(Movie_ID, ' | ', Start_Time) AS ShowTime FROM Showtimes")

    # Streamlit booking form
    with st.form("book_movie"):
        user = st.selectbox("Select User", users["Name"])
        user_id = users.loc[users["Name"] == user, "User_ID"].values[0]

        movie = st.selectbox("Select Movie", movies["Title"])
        movie_id = movies.loc[movies["Title"] == movie, "Movie_ID"].values[0]

        showtime_option = st.selectbox("Select Showtime", showtimes["ShowTime"])
        showtime_id = showtimes.loc[showtimes["ShowTime"] == showtime_option, "Showtime_ID"].values[0]

        num_tickets = st.number_input("Number of Tickets", min_value=1, step=1)
        price_per_ticket = 10  # Hardcoded, or fetch from your movie table if needed
        total_amount = price_per_ticket * num_tickets

        if st.form_submit_button("Book Now"):
            # Insert booking
            execute_query("""
                INSERT INTO Bookings (User_ID, Movie_ID, Showtime_ID, Number_of_Tickets, Booking_Date)
                VALUES (?, ?, ?, ?, GETDATE())
            """, (user_id, movie_id, showtime_id, num_tickets))

            # Insert payment
            execute_query("""
                INSERT INTO Payments (Payment_ID, User_ID, Payment_Amount, Payment_Status)
                VALUES ((SELECT ISNULL(MAX(Payment_ID), 0)+1 FROM Payments), ?, ?, 'Success')
            """, (user_id, total_amount))

            st.success(f"🎉 Booking successful! Amount paid: ${total_amount}")

# 💳 PAYMENTS
elif page == "💳 Payments":
    st.header("Payment Records")
    st.dataframe(run_query("SELECT * FROM Payments"))
