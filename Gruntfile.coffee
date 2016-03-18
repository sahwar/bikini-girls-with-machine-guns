module.exports = (grunt) ->
	require('load-grunt-config') grunt
	grunt.registerTask('test', ['mochaTest','coffeelint'])
	grunt.registerTask('deploy:development', ['lambda_package:development', 'lambda_deploy:development'])
	grunt.registerTask('deploy:staging', ['lambda_package:staging', 'lambda_deploy:staging'])
	grunt.registerTask('deploy:production', ['lambda_package:production', 'lambda_deploy:production'])
