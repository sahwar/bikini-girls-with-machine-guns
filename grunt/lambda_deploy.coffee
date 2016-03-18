module.exports =
	development:
		options:
			region: 'eu-west-1'
			aliases: 'development'
			enableVersioning: false
		arn: '<lambdaArn>'

	staging:
		options:
			region: 'eu-west-1'
			aliases: 'staging'
			enableVersioning: true
		arn: '<lambdaArn>'

	production:
		options:
			region: 'eu-west-1'
			aliases: 'production'
			enableVersioning: true
		arn: '<lambdaArn>'
