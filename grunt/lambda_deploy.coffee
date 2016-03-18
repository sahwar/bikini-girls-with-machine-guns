module.exports =
	development:
		options:
			region: 'eu-west-1'
			aliases: 'development'
			enableVersioning: false
		arn: 'your_arn'

	staging:
		options:
			region: 'eu-west-1'
			aliases: 'staging'
			enableVersioning: true
		arn: 'your_arn'

	production:
		options:
			region: 'eu-west-1'
			aliases: 'production'
			enableVersioning: true
		arn: 'your_arn'
