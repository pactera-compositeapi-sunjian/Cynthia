<%@ page import="com.sogou.qadev.service.cynthia.bean.Key"%>
<%@ page contentType="text/xml; charset=UTF-8" %>
<%--
@description: add action to flow   
@author?liming  
@date:2014-5-7
@version:V1.0  
--%>
<%@page import="com.sogou.qadev.service.cynthia.service.ErrorManager.ErrorType"%>
<%@page import="com.sogou.qadev.service.cynthia.service.ErrorManager"%>
<%@page import="com.sogou.qadev.service.cynthia.util.ArrayUtil"%>
<%@page import="com.sogou.qadev.service.cynthia.bean.DataAccessAction"%>

<%@ page import="com.sogou.qadev.service.cynthia.bean.Flow"%>
<%@ page import="com.sogou.qadev.service.cynthia.bean.Action"%>
<%@ page import="com.sogou.qadev.service.cynthia.bean.UUID"%>
<%@ page import="com.sogou.qadev.service.cynthia.util.ConfigUtil"%>
<%@ page import="com.sogou.qadev.service.cynthia.factory.DataAccessFactory"%>
<%@ page import="com.sogou.qadev.service.cynthia.service.DataAccessSession"%>
<%@ page import="com.sogou.qadev.service.cynthia.service.DataAccessSession.ErrorCode"%>

<%
	response.setHeader("Cache-Control","no-cache"); //Forces caches to obtain a new copy of the page from the origin server
	response.setHeader("Cache-Control","no-store"); //Directs caches not to store the page under any circumstance
	response.setDateHeader("Expires", 0); //Causes the proxy cache to see the page as "stale"
	response.setHeader("Pragma","no-cache"); //HTTP 1.0 backward compatibility

	out.clear();

	Key key = (Key)session.getAttribute("key");
	Long keyId = (Long)session.getAttribute("kid");

	if(keyId == null || keyId <= 0 || key == null){
		response.sendRedirect(ConfigUtil.getCynthiaWebRoot());
		return;
	}

	DataAccessSession das = DataAccessFactory.getInstance().createDataAccessSession(key.getUsername(), keyId);

	UUID flowId = DataAccessFactory.getInstance().createUUID(request.getParameter("flowId"));

	Flow flow = das.queryFlow(flowId);
	if(flow == null)
	{
		out.println(ErrorManager.getErrorXml(ErrorType.flow_not_found));
		return;
	}

	UUID beginStatId = null;
	if(request.getParameter("beginStatId") != null)
		beginStatId = DataAccessFactory.getInstance().createUUID(request.getParameter("beginStatId"));

	UUID endStatId = DataAccessFactory.getInstance().createUUID(request.getParameter("endStatId"));

	Action action = flow.addAction(beginStatId, endStatId);
	if(action == null)
	{
		out.println(ErrorManager.getErrorXml(ErrorType.action_not_found));
		return;
	}

	action.setName(request.getParameter("name"));
	
	//设置是否指派到多人
	String assignToMore = request.getParameter("assignToMore");
	if(assignToMore != "" && assignToMore != null){
		action.setAssignToMore(assignToMore.equals("true"));
	}
	
	String[] roleRightArray = (String[])ArrayUtil.format(request.getParameterValues("roleRight"), new String[0]);
	for(String roleRight : roleRightArray)
	{
		UUID roleId = DataAccessFactory.getInstance().createUUID(roleRight.split("\\|")[0]);
		boolean right = Boolean.parseBoolean(roleRight.split("\\|")[1]);
		
		if(right)
			flow.addActionRole(action.getId(), roleId);
		else
			flow.removeActionRole(action.getId(), roleId);
	}
	

	ErrorCode errorCode = das.updateFlow(flow);
	if(errorCode.equals(ErrorCode.success)){
		das.updateCache(DataAccessAction.update, flow.getId().getValue(), flow);
		out.println("<?xml version=\"1.0\" encoding=\"UTF-8\"?><root><isError>false</isError><id>"+action.getId().getValue()+"</id></root>");
	}else{
		out.println(ErrorManager.getErrorXml(ErrorType.database_update_error));
	}
%>