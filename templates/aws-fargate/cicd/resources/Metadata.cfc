/**
* Container Metadata Info Example
*/
component extends="BaseHandler"{
	
	// OPTIONAL HANDLER PROPERTIES
	this.prehandler_only 	= "";
	this.prehandler_except 	= "";
	this.posthandler_only 	= "";
	this.posthandler_except = "";
	this.aroundHandler_only = "";
	this.aroundHandler_except = "";		

	// REST Allowed HTTP Methods Ex: this.allowedMethods = {delete='POST,DELETE',index='GET'}
	this.allowedMethods = {};
	
	/**
	* Index
	*/
	any function index( event, rc, prc ){
		prc.response.setData( {
			'server-id': Right(Server.os.macAddress,2),
			'server-name': Server.os.hostname,
			'metadata-url': Server.system.environment['ECS_CONTAINER_METADATA_URI']
		} );
	}
	
}