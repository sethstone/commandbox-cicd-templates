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
        generateHandler: 'generateAWSFargate',
        templatePath: '/commandbox-cicd-templates/templates/aws-fargate/',
        description: 'CloudFormation templates for Blue/Green deployment to AWS Fargate using CodeDeploy'
      }
    };

    return this;
  }
  
  /**
   * @template.hint Cloud template to generate
   */
  public void function run( string template ){
    var projectDirectory = '';
    var projectPrefix = '';
    var template = '';

    if ( arguments.keyExists('template') && arguments.template.len() > 0 ) {
      template = arguments.template;
    }
    else {
      template = ask( message='Cloud template (or press Enter for list): ' );
    }

    // show list of tempalates
    if ( template.len() < 1 ) {
      print.line().cyanLine( 'The following templates are available ... ' ).line();
      for (var t in variables.templateMap) {
        print.cyan( '   * ').white(t).cyanLine(': ' & (t.len()<25 ? RepeatString('.',25-t.len()) : '') & ' '  & variables.templateMap[t].description );
      }
      print.line();
    }
     // Run the template setup if this is a known template
    else if ( variables.templateMap.keyExists( template ) ) {
      // Confirm install location
      projectDirectory = ask(
        message='Project directory: ',
        defaultResponse='#getCWD()#'
      );
      projectPrefix = ask(
        message='Project prefix (used for naming cloud resources; 28 character-limit): ',
        defaultResponse='#getCWD().listLast("/\")#'
       );
      // Enforce length (Driven by max length of ELB target groups names (32) and IAM Roles (64))
      projectPrefix = projectPrefix.left(28);

      // Generate template based on 'template' parameter
      Invoke( variables, variables.templateMap[template].generateHandler, {
          'settings': variables.templateMap[template],
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
    var cicdDirectory = projectDirectory & 'cicd';
    var dockerComposeFile = projectDirectory & 'docker-compose.yml';
    var envExampleFile = projectDirectory & '.env.example';

    var firstRun = !DirectoryExists( cicdDirectory );

    // FIRST RUN
    if ( firstRun ) {
      // Generate /cicd folder
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
      FileSetAccessMode( cicdDirectory & '/scripts/deploy.sh', '755' );  
      FileSetAccessMode( cicdDirectory & '/scripts/undeploy.sh', '755' );  
      print.cyanLine( 'Execute permissions in #cicdDirectory#/scripts set sucessfully.' );

      // If present, append .env.example contents to build-testing and prod ENV files.
      if ( FileExists( envExampleFile ) ) {
        FileAppend( cicdDirectory & '/env/build-testing.env.tmpl', Chr(10) & FileRead( envExampleFile ) );  
        FileAppend( cicdDirectory & '/env/prod.env.tmpl', Chr(10) & FileRead( envExampleFile ) );  
        // Don't let certain ENV vars slip through
        this.command( 'tokenReplace' )
          .params( 
            path = cicdDirectory & '/env/prod.env.tmpl',
            token = 'ENVIRONMENT=development',
            replacement = 'ENVIRONMENT=production'
          )
          .inWorkingDirectory( cicdDirectory )
          .run()
        ;
        print.cyanLine( 'Found .env.example file in project root, will use as template for Docker image testing and production execution.' );
      }

      // Set up an example docker-compose.yml file for development use.
      if ( !FileExists( dockerComposeFile ) ) {
        FileCopy( settings.templatePath & 'docker-compose.yml', dockerComposeFile );
        print.cyanLine( 'File #dockerComposeFile# created. (Use with local development)' );
      }
      else {
        print.boldYellowline( 'File #dockerComposeFile# already exists, won''t re-create.' );
      }
    }
    else {
        print.boldYellowline( 'Directory #cicdDirectory# already exists, won''t re-create.' );
    }

    // Output instructions for this template
    print.line();
    print.greenLine( 'SUCCESS!' );
    print.line( 'To deploy this template to AWS, first configure your aws-cli with approporiate credentials and then run: ' );
    print.line();
    print.line( '  * Mac/Windows/Linux (Bash): <PROJECT_DIR>/cicd/scripts/deploy.sh' );
    print.line( '  * Windows (Powershell): <PROJECT_DIR>\cicd\scripts\deploy.ps1' );
    print.line();
    print.line( '[Docker Hub]' );
    print.line( 'Please have your Docker Hub credentials ready when running deploy.sh (free or paid account will work).' );
    print.line();
  }
}