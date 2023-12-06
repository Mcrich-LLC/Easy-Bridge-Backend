# Easy-Bridge-Backend

The backend for the iOS app Easy Bridge Tracker.

Check out the full app: [Easy Bridge Tracker](https://github.com/Mcrich-LLC/Easy-Bridge-Tracker)

## Using The Database

### Accessing The Database
* Access the database at [https://backend.mcrich23.com/bridges](http://backend.mcrich23.com/bridges)

### Contributing To The Database
* Email [support@mcrich23.com](mailto:support@mcrich23.com) for a bearer token to add or force update bridges

## Contributing

### Start Here
* Fork the repo to your profile
* Clone to your computer

`git clone https://github.com/Mcrich23/Easy-Bridge-Backend.git && cd Easy-Bridge-Backend`

* Setup the upstream remote

`git remote add upstream https://github.com/Mcrich23/Seattle-Bridge-Backend.git`

* Setup your [.env file](#setting-up-secrets)

### Setting Up You Env
* Create an API key (yourself) for vapor to update itself and also get one from your firebase project (for push notification support)
* Once you have your API keys, create a new file called `.env` in the Seattle-Bridge-Backend directory of the project, by typing `touch .env` in Terminal
* Use the file `.env-example` as the format for your `.env` file.
