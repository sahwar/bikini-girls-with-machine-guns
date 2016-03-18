module.exports =
	app:
		files:
			src: ['*.coffee', 'lib/**/*.coffee']
		options:
			no_tabs:
				level: 'ignore'
			indentation:
				level: 'error'
				value: 1
			max_line_length:
				value: 164
				level: 'warn'
