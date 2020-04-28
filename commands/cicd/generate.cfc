/**
* Generate infrastructure-as-code files for your target cloud platform.  
*
* {code:bash}
* cicd generate template=aws-fargate
* {code} 
*
* Run without a 'template' parameter to see available templates.
* 
**/
component {

	/**
	 * Constructor
	 */
	function init(){

		// Available tempalates
		variables.templateMap = {
			'aws-fargate' : { 
        handler: 'generateAWSFargate',
        templatePath: '/commandbox-cicd-templates/templates/aws-fargate/',
        description: 'CloudFormation templates for Blue/Green deployment to AWS Fargate using CodePipeline'
      }
    };

    return this;
  }
  
  /**
   * @template.hint Cloud template to generate or press Enter for list
   */
  public void function run( required string template ){
    var projectDirectory = '';
    var projectPrefix = '';

    // show list of tempaates
    if ( template.len() < 1 ) {
      print.line().cyanLine( 'The following templates are available ... ' ).line();
      for (var t in variables.templateMap) {
        print.cyan( '   * ').white(t).cyanLine(': .......  #variables.templateMap[t].description#' );
      }
      print.line();
    }
 		// Run the template setup if this is a known template
		else if ( variables.templateMap.keyExists( arguments.template ) ) {
      // Confirm install location
      projectDirectory = ask(
        message='Project directory: ',
        defaultResponse='#getCWD()#'
      );
      projectPrefix = ask(
        message='Project prefix (used for naming cloud resources): ',
        defaultResponse='#getCWD().listLast("/\")#'
       );

      // Generate template based on 'template' parameter
      Invoke( variables, variables.templateMap[arguments.template].handler, {
          'settings': variables.templateMap[arguments.template],
          'projectDirectory': projectDirectory,
          'projectPrefix': projectPrefix
      });
		}
    else {
      print.line().redLine( 'Could not find: #template#!' );
    }
  }

  /**
   * Generates the cloud files for aws-fargate template
   * 
   * @return {void}
   */
  private void function generateAWSFargate(
    required struct settings,
    required string projectDirectory,
    required string projectPrefix
  ) {
    // TODO:
    // ✅ Copy files
    // ✅ Check for preesence of existing files and skip
    // ✅ Tokenize
    // Make deploy.sh executable
    // output instructions for running deploy.sh
    // Add a template id file to cicd folder

    var cicdDirectory = projectDirectory & 'cicd';
    var dockerCompose = projectDirectory & 'docker-compose.yml';
    var dockerIgnore = projectDirectory & '.dockerignore';

    // Generate /cicd fodler, docker-compse.yml and .dockerignore
    if ( !DirectoryExists(cicdDirectory) ) {
      DirectoryCopy( settings.templatePath & 'cicd', cicdDirectory, true );
      this.command( 'tokenReplace' )
        .params( 
          path = '**/*',
          token = '@@CICDTEMPLATE_PROJECT_PREFIX@@',
          replacement = projectPrefix
        )
        .inWorkingDirectory( cicdDirectory )
        .run()
      ;
      print.cyanLine( 'Directory #cicdDirectory# created.' );
    }
    else {
      print.yellowline( 'Directory #cicdDirectory# already exists, won''t re-create.' );
    }

    if ( !FileExists(dockerCompose) ) {
      FileCopy( settings.templatePath & 'docker-compose.yml', dockerCompose );
      print.cyanLine( 'File #dockerCompose# created.' );
    }
    else {
      print.boldYellowline( 'File #dockerCompose# already exists, won''t re-create.' );
    }

    if ( !FileExists(dockerIgnore) ) {
      FileCopy( settings.templatePath & '.dockerignore', dockerIgnore );
      print.cyanLine( 'File #dockerIgnore# created.' );
    }
    else {
      print.boldYellowline( 'File #dockerIgnore# already exists, won''t re-create.' );
    }
  }
}