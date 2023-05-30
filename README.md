# Easy-Bridge-Backend

The backend for the iOS app Easy Bridge Tracker.

Check out the full app: [Easy Bridge Tracker](https://github.com/Mcrich23/Easy-Bridge-Tracker)

## Using The Database

### Accessing The Database
* Access the database at [http://mc.mcrich23.com/bridges](http://mc.mcrich23.com/bridges)

### Contributing To The Database
* Email [support@mcrich23.com](mailto:support@mcrich23.com) for a bearer token to add or force update bridges

## Contributing

### Start Here
* Fork the repo to your profile
* Clone to your computer

`git clone https://github.com/Mcrich23/Easy-Bridge-Backend.git && cd Easy-Bridge-Backend`

* Setup the upstream remote

`git remote add upstream https://github.com/Mcrich23/Seattle-Bridge-Backend.git`

* Setup the [Secrets.swift file](#setting-up-secrets)

### Setting Up Secrets
* Create an API key (yourself) for vapor to update itself and also get one from [twitter](https://developer.twitter.com)
* Once you have your API keys, create a new file called `Secrets.swift` in the Seattle-Bridge-Backend directory of the project, by typing `touch Secrets.swift` in Terminal
* Use the file `Secrets-Example.swift` as the format for your Secrets.swift file. Paste your API key into the `bearerToken` property
