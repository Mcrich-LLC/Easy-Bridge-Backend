from flask import Flask, jsonify
import asyncio
from twscrape import API, gather
import os
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)
api = API()  # Initialize API instance outside of the route handler

threadLoop = asyncio.new_event_loop()

# Twitter User 1 Credentials
username1 = os.getenv("TWITTER1_USERNAME")
password1 = os.getenv("TWITTER1_PASSWORD")
email1 = os.getenv("TWITTER1_EMAIL")
email_password1 = os.getenv("TWITTER1_EMAIL_PASSWORD")

# Twitter User 2 Credentials
username2 = os.getenv("TWITTER2_USERNAME")
password2 = os.getenv("TWITTER2_PASSWORD")
email2 = os.getenv("TWITTER2_EMAIL")
email_password2 = os.getenv("TWITTER2_EMAIL_PASSWORD")

async def login_accounts():
    # Add account with COOKIES (with cookies login not required)
    await api.pool.add_account(username1, password1, email1, email_password1)
    await api.pool.add_account(username2, password2, email2, email_password2)
    await api.pool.login_all()  # Pass the event loop

@app.route('/tweets/<int:user_id>')
def get_tweets(user_id):
    async def fetch_tweets():
        tweet_objects = await gather(api.user_tweets(user_id, limit=20))
        tweets = [tweet.rawContent for tweet in tweet_objects]
        return tweets

    # Run asyncio loop and get the result
    if not threadLoop.is_running():
        tweets = threadLoop.run_until_complete(fetch_tweets())
        return jsonify(tweets)
    else:
        return jsonify({'error': 'Thread loop is already running'}), 429


if __name__ == "__main__":
    threadLoop.run_until_complete(login_accounts())
    app.run(debug=True)
