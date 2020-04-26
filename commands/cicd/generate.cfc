/**
* This is a description of what this command does!
* This is how you call it:
*
* {code:bash}
* cicd generate param1
* {code} 
* 
* https://commandbox.ortusbooks.com/developing-for-commandbox/commands/tab-completion-and-help
**/
component {
  
  /**
  * @param1.hint Description of the first parameter
  */
  function run( required String param1 ){
      return 'Hello World!'; 
  }
}