#!/bin/bash

# Connect to the database
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Generate a random number between 1 and 1000
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))

# Ask for username
echo "Enter  username:"
read USERNAME

# Check if the user already exists in the database
USER_INFO=$($PSQL "SELECT user_id, games_played, best_game FROM users WHERE username='$USERNAME'")

# Process user information based on whether they exist in the database
if [[ -z $USER_INFO ]]; then
  # New user
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  # Insert the new user into the database
  INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username) VALUES('$USERNAME')")
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")
else
  # Returning user
  USER_ID=$(echo $USER_INFO | cut -d '|' -f 1)
  GAMES_PLAYED=$(echo $USER_INFO | cut -d '|' -f 2)
  BEST_GAME=$(echo $USER_INFO | cut -d '|' -f 3)
  echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
fi

# Initialize the guess count
NUMBER_OF_GUESSES=0

# Start the guessing game
echo "Guess the secret number between 1 and 1000:"
while true; do
  read GUESS

  # Check if input is an integer
  if ! [[ "$GUESS" =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
    continue
  fi

  # Increment the guess counter
  ((NUMBER_OF_GUESSES++))

  # Check if the guess is correct
  if (( GUESS == SECRET_NUMBER )); then
    echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
    break
  elif (( GUESS < SECRET_NUMBER )); then
    echo "It's higher than that, guess again:"
  else
    echo "It's lower than that, guess again:"
  fi
done

# Update user statistics in the database
if [[ -z $GAMES_PLAYED ]]; then
  # New user: set initial game stats
  UPDATE_STATS=$($PSQL "UPDATE users SET games_played = 1, best_game = $NUMBER_OF_GUESSES WHERE user_id = $USER_ID")
else
  # Returning user: update game stats
  ((GAMES_PLAYED++))
  if [[ -z $BEST_GAME || $NUMBER_OF_GUESSES -lt $BEST_GAME ]]; then
    BEST_GAME=$NUMBER_OF_GUESSES
  fi
  UPDATE_STATS=$($PSQL "UPDATE users SET games_played = $GAMES_PLAYED, best_game = $BEST_GAME WHERE user_id = $USER_ID")
fi


