	 ▄▄▄▄    ▄████ █     █░███▄ ▄███▓ ▄████
	▓█████▄ ██▒ ▀█▓█░ █ ░█▓██▒▀█▀ ██▒██▒ ▀█▒
	▒██▒ ▄█▒██░▄▄▄▒█░ █ ░█▓██    ▓██▒██░▄▄▄░
	▒██░█▀ ░▓█  ██░█░ █ ░█▒██    ▒██░▓█  ██▓
	░▓█  ▀█░▒▓███▀░░██▒██▓▒██▒   ░██░▒▓███▀▒
	░▒▓███▀▒░▒   ▒░ ▓░▒ ▒ ░ ▒░   ░  ░░▒   ▒
	▒░▒   ░  ░   ░  ▒ ░ ░ ░  ░      ░ ░   ░
	 ░    ░░ ░   ░  ░   ░ ░      ░  ░ ░   ░
	 ░           ░    ░          ░        ░
	      ░

# Bikini Girls With Machine Guns

## Remember this

Everything you have experienced in your entire life has brought you to this instant. All things are now possible in the limitless void of counter-actuality. All things that are knowable will be realized in this new dimension of Bikini Girls With Machine Guns.

## But what does it do?

Load tester that utilizes a Lambda function with PhantomJS

# Usage

Make sure you use node v0.10.36 before installing dependencies! Cuz the NodeJs version of AWS Lambda is lagging behind.

	nvm use v0.10.36

	npm install

	npm test

To locally run the lambda-function with a test SNS message (see test/data/lambda.json)

	grunt lambda_invoke

To package the lambda module for a certain environment: [development, staging or production]

	grunt lambda_package:development

To deploy to AWS Lambda

	grunt deploy:development

