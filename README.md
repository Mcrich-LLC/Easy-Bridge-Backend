# Seattle-Bridge-Backend

## Contributing

## Start Here
* Fork the repo to your profile
* Clone to your computer

`git clone https://github.com/Mcrich23/Easy-Bridge-Backend.git && cd Easy-Bridge-Backend`

* Setup the upstream remote

`git remote add upstream https://github.com/Mcrich23/Seattle-Bridge-Backend.git`

* Setup the [Secrets.swift file](#setting-up-secrets)

## Setting Up Secrets
* Create an API key for vapor to update itself and also get one from [twitter](developer.twitter.com)
* Once you have your API keys, create a new file called `Secrets.swift` in the Seattle-Bridge-Backend directory of the project, by typing `touch Secrets.swift` in Terminal
* Use the file `Secrets-Example.swift` as the format for your Secrets.swift file. Paste your API key into the `bearerToken` property
