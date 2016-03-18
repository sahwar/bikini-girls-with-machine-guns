module.exports =
	api:
		options:
			file_name: 'lambda.js'
			handler: 'handler'
			event: 'test/data/lambda-api.json'
	sns:
		options:
			file_name: 'lambda.js'
			handler: 'handler'
			event: 'test/data/lambda-sns.json'