component {
  function configure(){
    settings = {};
    interceptors = [];
  }

  function onCLIStart( interceptData ) {}
  function onCLIExit() {}

  function preCommandParamProcess( interceptData ) {}
  function preCommand( interceptData ) {}
  function postCommand( interceptData ) {}
  function prePrompt( interceptData ) {}
  function preProcessLine( interceptData ) {}
  function postProcessLine( interceptData ) {}
}