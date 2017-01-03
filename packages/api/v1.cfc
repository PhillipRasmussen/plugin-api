component extends="base" {

	/** 
	* @handle GET /{typename}
	* @displayname Get items
	* @hint This endpoint returns an array of the requested content type.
	* @tags Content
	* @200 []#/definitions/ContentType:A content item
	* @default #/definitions/FailedRequest:Failure
	* @permission {typename}:list
	*/
	function getList (
		required string typename in="path" description="The content type" swagger_type="string",
		string page in="query" default=1 description="The page number" swagger_type="integer" swagger_format="int32",
		string pagesize in="query" default=10 description="The page size. Maximum 100." swagger_type="integer" swagger_format="int32",
		string order in="query" default="datetimeLastUpdated desc" description="The array order" swagger_type="string" enum="datetimeLastUpdated asc,datetimeLastUpdated desc"
	) {
		var q = "";
		var i = 0;
		var aResult = [];

		if (arguments.pagesize lt 1 or arguments.pagesize gt 100) {
			addError(code="202", detail="pagesize must be between 1 and 100");
			return;
		}

		if (not listFindNoCase("datetimeLastUpdated asc,datetimeLastUpdated desc", arguments.order)) {
			addError(code="202", detail="Order must be one of (datetimeLastUpdated asc|datetimeLastUpdated desc)");
			return;
		}

		addResponse("page", round(arguments.page));
		addResponse("pagesize", round(arguments.pagesize));

		q = application.fapi.getContentObjects(typename=arguments.typename, orderBy=arguments.order, maxrows=arguments.page*arguments.pagesize);
		for (i=(arguments.page-1)*arguments.pagesize+1; i lte min(arguments.page*arguments.pagesize, q.recordcount); i++) {
			arrayAppend(aResult, getResponseObject(typename=q.typename[i], objectid=q.objectid[i]));
		}
		addResponse("items", aResult);

		q = new Query();
		q.setDatasource(application.dsn);
		if (structKeyExists(application.stCOAPI[arguments.typename].stProps, "status")) {
			q.setSQL("SELECT count(*) as record_count FROM #arguments.typename# WHERE status IN (:allowedstatus)");
			q.addParam(name="allowedstatus", list=true, value=request.mode.lValidStatus, cfsqltype="cf_sql_varchar");
		}
		else  {
			q.setSQL("SELECT count(*) as record_count FROM #arguments.typename#");
		}
		q = q.execute().getResult();
		addResponse("total", q.record_count);
	}

	/** 
	* @handle GET /{typename}/{objectid}
	* @displayname Get item
	* @hint This endpoint returns the requested content item.
	* @tags Content
	* @200 #/definitions/ContentType:A content item
	* @default #/definitions/FailedRequest:Failure
	* @permission {typename}:get
	*/
	function getItem (
		required string typename in="path" description="The content type" swagger_type="string",
		required string objectid in="path" description="The object id" swagger_type="string" swagger_format="uuid"
	) {
		var stObject = application.fapi.getContentObject(typename=arguments.typename, objectid=arguments.objectid);

		if (structKeyExists(stObject, "bDefaultObject")) {
			addError(code="203")
			return;
		}

		setResponse(getResponseObject(stObject=stObject));
	}

}