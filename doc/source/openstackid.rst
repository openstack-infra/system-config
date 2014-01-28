:title: OpenstackId
==================
OpenstackId Server
==================

OpenId Idp/ OAuth2.0 AS/RS

At a Glance
===========

:Hosts:
  * https://openstackid-dev.openstack.org
:Puppet:
  * :file:`modules/openstackid`
  * :file:`modules/openstack_project/manifests/openstackid_dev.pp`
:Projects:
  * http://git.openstack.org/cgit/openstack-infra/openstackid/
:Bugs:
  * https://bugs.launchpad.net/openstackid
:Resources:
  * http://laravel.com/docs/installation
  * http://laravel.com/docs/configuration
  * http://openid.net/specs/openid-authentication-2_0.html
  * http://openid.net/specs/openid-attribute-exchange-1_0.html
  * http://openid.net/specs/openid-simple-registration-extension-1_0.html
  * http://step2.googlecode.com/svn/spec/openid_oauth_extension/latest/openid_oauth_extension.html
  * http://tools.ietf.org/html/rfc6749
  * http://tools.ietf.org/html/rfc6750
  * http://tools.ietf.org/html/rfc7009
  * http://tools.ietf.org/html/draft-richer-oauth-introspection-04

Overview
========

Openstack Id Idp (Identity Provider) supports the `OpenID 2.0 protocol
<(http://openid.net/specs/openid-authentication-2_0.html)>`_ providing authentication support as an OpenID provider. 
also supports the following OpenId extensions: 

* `OpenID Attribute Exchange 1.0: <http://openid.net/specs/openid-attribute-exchange-1_0.html>`_
  Allows web developers to access, with the user's approval, certain user information stored with Openstack DB, 
  including user name and email address

* `OpenID Simple Registration Extension 1.0: <http://openid.net/specs/openid-simple-registration-extension-1_0.html>`_
  OpenID Simple Registration is an extension to the OpenID Authentication protocol that allows for very light-weight profile exchange. 
  It is designed to pass eight commonly requested pieces of information when an End User goes to register a new account with a web service. 

* `OpenID OAuth Extension: <http://step2.googlecode.com/svn/spec/openid_oauth_extension/latest/openid_oauth_extension.html>`_ The OpenID OAuth Extension describes how to make the OpenID Authentication and OAuth2 Core specifications work 
  well together. In its current form, it addresses the use case where the OpenID Provider and OAuth Service Provider are the same service. 
  To provide good user experience, it is important to present, to the user, a combined authentication and authorization screen for 
  the two protocols. 

Its also support `The OAuth 2.0 Authorization Framework <http://tools.ietf.org/html/rfc6749>`_ , turning Openstack Id Server in a 
Combined Provider (A web service that is simultaneously an OpenID Identity Provider (OP) and an OAuth2 Service Provider (SP).).

:OAUTH2 Grants Support:
  * `Authorization Code Grant <http://tools.ietf.org/html/rfc6749#section-4.1>`_
  * `Implicit Grant <http://tools.ietf.org/html/rfc6749#section-4.2>`_
  * `Client Credentials Grant <http://tools.ietf.org/html/rfc6749#section-4.4>`_


OpenID 2.0 endpoint
===================

To get the Openstack ID OpenID endpoint, perform discovery by sending a GET HTTP request to https://openstackid.openstack.org.
We recommend setting the Accept header to "application/xrds+xml". Openstack Id returns an XRDS document containing an OpenID provider endpoint URL.The endpoint address is annotated as: 

.. code:: xml

<Service priority="0">
<Type>http://specs.openid.net/auth/2.0/server</Type>
<URI>{OpenstackId's login endpoint URI}</URI>
</Service>

OpenID 2.0 request parameters
_____________________________

Once you've acquired the Openstack Id endpoint, send authentication requests to it, specifying the following parameters as relevant.
Connect to the endpoint by sending a request to the URL or by making an HTTP POST request.

+---------------------+--------------------------------------------------------------------------------------------------------------------------+
| Parameter           | Description                                                                                                              |
+=====================+==========================================================================================================================+
| openid.mode         | (required) Interaction mode. Specifies                                                                                   |
|                     | whether Openstack Id IdP may interact with the user to determine the outcome of the request.                             |
|                     | Valid values are:                                                                                                        |
|                     | * checkid_immediate (No interaction allowed)                                                                             |
|                     | * checkid_setup (Interaction allowed)                                                                                    |
|                     |                                                                                                                          |
+---------------------+--------------------------------------------------------------------------------------------------------------------------+
| openid.ns           | (required) Protocol version. Value identifying the OpenID protocol version being used.                                   |
|                     | This value should be "http://specs.openid.net/auth/2.0".                                                                 |
|                     |                                                                                                                          |
+---------------------+--------------------------------------------------------------------------------------------------------------------------+
| openid.return_to    | (required) Return URL. Value indicating the URL where the user should be returned to after signing in.                   |
|                     | Openstack Id Idp only supports HTTPS address types                                                                       |
|                     |                                                                                                                          |
+---------------------+--------------------------------------------------------------------------------------------------------------------------+
| openid.assoc_handle | (optional) Association handle. Set if an association was established between the relying party (web application) and the |
|                     | identity provider (Openstack).                                                                                           |
|                     | See OpenID specification Section 8.                                                                                      |
|                     |                                                                                                                          |
+---------------------+--------------------------------------------------------------------------------------------------------------------------+
| openid.claimed_id   | (required) Claimed identifier. This value must be set to "http://specs.openid.net/auth/2.0/identifier_select".           |
|                     | or to user claimed identity (user local identifier or user owned identity                                                |
|                     | [ex: custom html hosted on a owned domain set to html discover])                                                         |
|                     |                                                                                                                          |
+---------------------+--------------------------------------------------------------------------------------------------------------------------+
| openid.identity     | (required) Alternate identifier. This value must be set to http://specs.openid.net/auth/2.0/identifier_select.           |
|                     |                                                                                                                          |
+---------------------+--------------------------------------------------------------------------------------------------------------------------+
| openid.realm        | (required) Authenticated realm. Identifies the domain that the end user is being asked to trust.                         |
|                     | (Example: "http://*.myexamplesite.com") This value must be consistent with the domain defined in openid.return_to.       |
|                     |                                                                                                                          |
+---------------------+--------------------------------------------------------------------------------------------------------------------------+

Attribute exchange extension
____________________________

+--------------------------+--------------------------------------------------------------------------------------------------------------------------+
| Parameter                | Description                                                                                                              |
+==========================+==========================================================================================================================+
| openid.ns.ax             |(required) Indicates request for user attribute information. This value must be set to "http://openid.net/srv/ax/1.0".    |
|                          |                                                                                                                          |
+--------------------------+--------------------------------------------------------------------------------------------------------------------------+
| openid.ax.mode           | (required) This value must be set to "fetch_request".                                                                    |
|                          |                                                                                                                          |
+--------------------------+--------------------------------------------------------------------------------------------------------------------------+
| openid.ax.required       | (required) Specifies the attribute being requested. Valid values include:                                                |
|                          | "country","email","firstname","language","lastname"                                                                      |
|                          | To request multiple attributes, set this parameter to a comma-delimited list of attributes.                              |
|                          |                                                                                                                          |
+--------------------------+--------------------------------------------------------------------------------------------------------------------------+
| openid.ax.type.country   | (optional) Requests the user's home country. This value must be set to "http://axschema.org/contact/country/home".       |
|                          |                                                                                                                          |
+--------------------------+--------------------------------------------------------------------------------------------------------------------------+
| openid.ax.type.email     | (optional) Requests the user's gmail address. This value must be set to "http://axschema.org/contact/email"              |
|                          |                                                                                                                          |
+--------------------------+--------------------------------------------------------------------------------------------------------------------------+
| openid.ax.type.firstname | (optional) Requests the user's first name. This value must be set to "http://axschema.org/namePerson/first".             |
|                          |                                                                                                                          |
+--------------------------+--------------------------------------------------------------------------------------------------------------------------+
| openid.ax.type.language  | (optional) Requests the user's preferred language. This value must be set to "http://axschema.org/pref/language".        |
|                          |                                                                                                                          |
+--------------------------+--------------------------------------------------------------------------------------------------------------------------+
| openid.ax.type.lastname  | (optional) Requests the user's last name. This value must be set to "http://axschema.org/namePerson/last".               |
|                          |                                                                                                                          |
+--------------------------+--------------------------------------------------------------------------------------------------------------------------+


Simple Registration Extension
_____________________________

+--------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| Parameter                | Description                                                                                                                     |
+==========================+=================================================================================================================================+
| openid.ns.sreg           | (required) Indicates request for user attribute information. This value must be set to "http://openid.net/extensions/sreg/1.1". |
|                          |                                                                                                                                 |
+--------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| openid.sreg.required     | (required) Comma-separated list of field names which, if absent from the response, will prevent the Consumer from completing    |
|                          | the registration without End User interation. The field names are those that are specified in the Response Format,              |
|                          | with the "openid.sreg." prefix removed.                                                                                         |
|                          | Valid values include:                                                                                                           |
|                          | "country", "email", "firstname", "language", "lastname"                                                                         |
+--------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| openid.sreg.optional     | (required) Comma-separated list of field names Fields that will be used by the Consumer, but whose absence will not prevent     |
|                          | the registration from completing. The field names are those that are specified in the Response Format, with the "openid.sreg."  |
|                          | prefix removed.                                                                                                                 |
|                          | Valid values include:                                                                                                           |
|                          | "country", "email", "firstname", "language", "lastname"                                                                         |
+--------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| openid.sreg.policy_url   | (optional) A URL which the Consumer provides to give the End User a place to read about the how the profile data will be used.  |
|                          | The Identity Provider SHOULD display this URL to the End User if it is given.                                                   |
|                          |                                                                                                                                 |
+--------------------------+---------------------------------------------------------------------------------------------------------------------------------+


OAuth 2.0 Extension
_____________________________

+------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| Parameter                    | Description                                                                                                                     |
+==============================+=================================================================================================================================+
| openid.ns.oauth              | (required) Indicates request for OAuth2. This value must be set to "http://specs.openid.net/extensions/oauth/2.0".              |
|                              |                                                                                                                                 |
+------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| openid.oauth.client_id       | (required) Identifies the client that is making the request. The value passed in this parameter must exactly match the value    |
|                              | shown in the OpenstackId OAUTH2 Console.                                                                                        |
|                              |                                                                                                                                 |
+------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| openid.oauth.scope           | (required) Identifies the Openstack API access that your application is requesting. The values passed in this parameter         |
|                              | inform the consent screen that is shown to the user.                                                                            |
|                              |                                                                                                                                 |
+------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| openid.oauth.state           | (required) Provides any state that might be useful to your application upon receipt of the response.                            |
|                              | The OpenstackId Authorization Server roundtrips this parameter, so your application receives the same value it sent.            |
|                              | Possible uses include redirecting the user to the correct resource in your site, nonces, and cross-site-request-forgery         |
|                              | mitigations.                                                                                                                    |
|                              |                                                                                                                                 |
+------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| openid.oauth.approval_prompt | (optional) Indicates whether the user should be re-prompted for consent. The default is auto, so a given user should only       |
|                              | see the consent page for a given set of scopes the first time through the sequence. If the value is force,                      |
|                              | then the user sees a consent page even if they previously gave consent to your application for a given set of scopes.           |
|                              |                                                                                                                                 |
+------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| openid.oauth.access_type     | (optional) Indicates whether your application needs to access a OpenstackId API when the user is not present at the browser.    |
|                              | This parameter defaults to "online". If your application needs to refresh access tokens when the user is not present at         |
|                              | the browser, then use "offline". This will result in your application obtaining a refresh token the first time your application |
|                              | exchanges an authorization code for a user.                                                                                     |
|                              |                                                                                                                                 |
+------------------------------+---------------------------------------------------------------------------------------------------------------------------------+


OpenID 2.0 request authentication response
__________________________________________

Once OpenstackId accepts the authentication request, the user is redirected to a OpenstackId authentication page. At this point the authentication sequence
takes over. On successful authentication, OpenstackId redirects the user back to the URL specified in the openid.return_to parameter of the original request.
Response data is appended as query parameters, including a OpenstackId-supplied identifier, user information, if requested, and an OAuth 2.0 request token,
if requested.
OpenstackId may redirect through an HTTP 302 status code to the return URL, resulting in a GET request, or may cause the browser to issue a POST request to the
return URL, passing the OpenID 2.0 parameters in the POST body. A website or application should be prepared to accept responses as both GETs and POSTs.
If the user doesn't approve the authentication request, OpenstackId sends a negative assertion to the requesting website.


OAuth 2.0 endpoint
==================

Using OAuth 2.0 to Access OpenstackId APIs
________________________________________

OpenstackId APIs use the OAuth 2.0 protocol for authorization. OpenstackId supports common OAuth 2.0 scenarios such as those for web server, Service Accounts,
and client-side applications.
OAuth 2.0 is a relatively simple protocol. To begin, you register your application with OpenstackId. Then your client application requests an access token from
the OpenstackId Authorization Server, extracts a token from the response, and sends the token to the OpenstackId API that you want to access.


Basic steps
___________

All applications follow a basic pattern when accessing an OpenstackId API using OAuth 2.0. At a high level, you follow four steps:

1. Register your application.
   All applications that access an OpenstackId API must be registered through the OpenstackId OAUTH2 Console. The result
   of this registration process is a set of values (such as a client ID and client secret) that are known to both OpenstackId
   and your application. The set of values varies based on what type of application you are building. For example, a
   JavaScript application does not require a secret, but a web server application does.

2. Obtain an access token from the OpenstackId Authorization Server.
   Before your application can access private data using an OpenstackId API, it must obtain an access token that grants access to that API.
   A single access token can grant varying degrees of access to multiple APIs. A variable parameter called "scope"
   controls the set of resources and operations that an access token permits. During the access-token request, your
   application sends one or more values in the scope parameter.
   Some requests require an authentication step where the user logs in with their OpenstackId account. After logging in,
   the user is asked whether they are willing to grant the permissions that your application is requesting.
   This process is called user consent.
   If the user grants the permission, the OpenstackId Authorization Server sends your application an access token
   (or an authorization code that your application can use to obtain an access token). If the user does not grant the permission,
   the server returns an error.

3.Send the access token to an API.
  After an application obtains an access token, it sends the token to an OpenstackId API in an HTTP authorization header.
  It is possible to send tokens as URI query-string parameters, but we don't recommend it, because URI parameters can end up in log files
  that are not completely secure.
  Access tokens are valid only for the set of operations and resources described in the scope of the token request.

4.Refresh the access token (if necessary)
  Access tokens have limited lifetimes. If your application needs access to an OpenstackId API beyond the lifetime of a single access token,
  it can obtain a refresh token. A refresh token allows your application to obtain new access tokens.

Scenarios
_________


Web server applications
+++++++++++++++++++++++

The OpenstackId OAuth 2.0 endpoint supports web server applications that use languages and frameworks such as PHP,
Java, Python, Ruby, and ASP.NET. These applications might access an OpenstackId API while the user is present at
the application or after the user has left the application. **This flow requires that the application can keep a secret.**

Overview
********

The authorization sequence begins when your application redirects a browser to the OpenstackId OAuth 2.0 Endpoint;
the URL includes query parameters that indicate the type of access being requested.The result is an authorization code,
which OpenstackId returns to your application in a query string.
After receiving the authorization code, your application can exchange the code (along with a client ID and client secret)
for an access token and, in some cases, a refresh token.
The application can then use the access token to access an OpenstackId API.
If a refresh token is present in the authorization code exchange, then it can be used to obtain new access tokens at
any time. This is called **offline access**, because the user does not have to be present at the browser when
the application obtains a new access token.

Forming the URL
***************

The URL used when authenticating a user is https://openstackid.openstack.org/oauth2/auth.
This endpoint is accessible over SSL, and HTTP connections are refused.
This endpoint is the target of the initial request. It handles active session lookup, authenticating the user,
and user consent. The result of requests to this endpoint include access tokens, refresh tokens, and authorization codes.

The set of query string parameters supported by the OpenstackId Authorization Server for web server applications are:

+------------------------------+-------------------------------------------------------------------------------------------------------------------------------------------+
| Parameter                    | Values                                            | Description                                                                           |
+==============================+===========================================================================================================================================+
| response_type                | code                                              | Determines whether the OpenstackId OAuth 2.0 endpoint returns an authorization code.  |
|                              |                                                   | Web server applications should use code.                                              |
|                              |                                                   |                                                                                       |
+------------------------------+---------------------------------------------------+---------------------------------------------------------------------------------------+
| client_id                    | The client ID you obtain from the OpenstackId     | Identifies the client that is making the request. The value passed in this parameter  |
|                              | OAUTH2 Console when you register your app.        | must exactly match the value shown in                                                 |
|                              |                                                   | the OpenstackId OAUTH2 Console.                                                       |
|                              |                                                   |                                                                                       |
+------------------------------+---------------------------------------------------+---------------------------------------------------------------------------------------+
| redirect_uri                 | One of the redirect_uri values registered at the  | Determines where the response is sent. The value of this parameter must exactly match |
|                              | OpenstackId OAUTH2 Console.                       | one of the values registered in the OpenstackId OAUTH2 Console                        |
|                              |                                                   | (including https scheme, case, and trailing '/').                                     |
|                              |                                                   |                                                                                       |
+------------------------------+---------------------------------------------------+---------------------------------------------------------------------------------------+
| scope                        | Space-delimited set of permissions that the       | Identifies the OpenstackId API access that your application is requesting. The values |
|                              | application requests.                             | passed in this parameter inform the consent screen that is shown to the user.         |
|                              |                                                   |                                                                                       |
+------------------------------+---------------------------------------------------+---------------------------------------------------------------------------------------+
| state                        | Any string                                        | Provides any state that might be useful to your application upon receipt of the       |
|                              |                                                   | response. The Openstack Authorization Server roundtrips this parameter, so your       |
|                              |                                                   | application receives the same value it sent. Possible uses include redirecting the    |
|                              |                                                   | user to the correct resource in your site, nonces, and cross-site-request-forgery     |
|                              |                                                   | mitigations.                                                                          |
|                              |                                                   |                                                                                       |
+------------------------------+---------------------------------------------------+---------------------------------------------------------------------------------------+
| access_type                  | online or offline                                 | Indicates whether your application needs to access an OpenstackId API when the user   |
|                              |                                                   | is not present at the browser. This parameter defaults to online. If your application |
|                              |                                                   | needs to refresh access tokens when the user is not present at the browser,           |
|                              |                                                   | then use offline. This will result in your application obtaining a refresh token the  |
|                              |                                                   | first time your application exchanges an authorization code for a user.               |
|                              |                                                   |                                                                                       |
+------------------------------+---------------------------------------------------+---------------------------------------------------------------------------------------+
| approval_prompt              | force or auto                                     | Indicates whether the user should be re-prompted for consent. The default is auto,    |
|                              |                                                   | so a given user should only see the consent page for a given set of scopes the first  |
|                              |                                                   | time through the sequence. If the value is force, then the user sees a consent page   |
|                              |                                                   | even if they previously gave consent to your application for a given set of scopes.   |
|                              |                                                   |                                                                                       |
+------------------------------+---------------------------------------------------+---------------------------------------------------------------------------------------+

Handling the response
*********************

The response will be sent to the redirect_uri as specified in the request URL. If the user approves the access request,
then the response contains an authorization code and the state parameter (if included in the request). If the user does
not approve the request, the response contains an error message. All responses are returned to the web server on the
query string, as shown below:

An error response:

https://oauth2-demo.com/code?error=access_denied&state=xyz

An authorization code response:

https://oauth2-demo.com/code?state=xyz&code=123456

After the web server receives the authorization code, it may exchange the authorization code for an access token and a
refresh token. This request is an HTTPS post, and includes the following parameters:

+------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| Parameter                    | Description                                                                                                                     |
+==============================+=================================================================================================================================+
| code                         | The authorization code returned from the initial request.                                                                       |
|                              |                                                                                                                                 |
+------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| client_id                    | The client ID obtained from the OpenstackId OAUTH2 Console during application registration.                                     |
|                              |                                                                                                                                 |
+------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| client_secret                | The client secret obtained during application registration                                                                      |
|                              |                                                                                                                                 |
+------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| redirect_uri                 | The URI registered with the application.                                                                                        |
|                              |                                                                                                                                 |
+------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| grant_type                   | As defined in the OAuth 2.0 specification, this field must contain a value of authorization_code.                               |
|                              |                                                                                                                                 |
+------------------------------+---------------------------------------------------------------------------------------------------------------------------------+

**REMARK**
It is advisable that you exclude client_id/client_secret params from query string and use instead the Authorization Header
like this:
Authorization: Basic Base64-Encoded(client_id:client_secret)

The actual request might look like the following:

 POST /oauth2/token HTTP/1.1
 Host: openstackid.openstack.org
 Authorization: Basic Base64-Encoded(client_id:client_secret)
 Content-Type: application/x-www-form-urlencoded

 grant_type=authorization_code&code=SplxlOBeZQQYbYS6WxSbIA
 &redirect_uri=https%3A%2F%2Fclient%2Eexample%2Ecom%2Fcb

A successful response to this request contains the following fields:

+------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| Field                        | Description                                                                                                                     |
+==============================+=================================================================================================================================+
| access_token                 | The token that can be sent to an OpenstackId API.                                                                               |
|                              |                                                                                                                                 |
+------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| refresh_token                | A token that may be used to obtain a new access token. Refresh tokens are valid until the user revokes access.                  |
|                              | This field is only present if access_type=offline is included in the authorization code request.                                |
|                              |                                                                                                                                 |
+------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| expires_in                   | The remaining lifetime of the access token in seconds.                                                                          |
|                              |                                                                                                                                 |
+------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| token_type                   | Identifies the type of token returned. At this time, this field will always have the value Bearer.                              |
|                              |                                                                                                                                 |
+------------------------------+---------------------------------------------------------------------------------------------------------------------------------+

An example successful response:

     HTTP/1.1 200 OK
     Content-Type: application/json;charset=UTF-8
     Cache-Control: no-store
     Pragma: no-cache

     {
       "access_token":"2YotnFZFEjr1zCsicMWpAA",
       "token_type":"Bearer",
       "expires_in":3600,
       "refresh_token":"tGzv3JOkF0XG5Qx2TlKWIA",
     }


Calling an OpenstackId API
**************************

After your application obtains an access token, you can use the token to make calls to a Openstackid API on behalf of a
given user. To do this, include the access token in a request to the API by including either an access_token query
parameter or an Authorization: Bearer HTTP header. When possible, it is preferable to use the HTTP Header, since query
strings tend to be visible in server logs.

Examples

Here is a call to the same API for the authenticated user (me) using the access_token Authorization: Bearer HTTP header:

GET /api/v1/users/me HTTP/1.1
Authorization: Bearer 1/fFBGRNJru1FQd44AzqT3Zg
Host: openstackid.openstack.org


Offline access
**************

In some cases, your application may need to access an OpenstackId API when the user is not present.
This style of access is called offline, and web server applications may request offline access from a user. The normal
and default style of access is called online.
If your application needs offline access to an OpenstackId API, then the request for an authorization code should
include the access_type parameter, where the value of that parameter is offline.
The first time a given user's browser is sent to this URL, they see a consent page. If they grant access, then the
response includes an authorization code which may be redeemed for an access token and a refresh token.
If this is the first time the application has exchanged an authorization code for a user, then the response includes
an access token and a refresh token, as shown below:

{
  "access_token":"1/fFAGRNJru1FTz70BzhT3Zg",
  "expires_in":3600,
  "token_type":"Bearer",
  "refresh_token":"1/xEoDL4iW3cxlI7yDbSRFYNG01kVKM2C-259HOF2aQbI"
}

**IMPORTANT**: When your application receives a refresh token, it is important to store that refresh token for future
use. If your application loses the refresh token, it will have to re-prompt the user for consent before obtaining
another refresh token. If you need to re-prompt the user for consent, include the approval_prompt parameter in the
authorization code request, and set the value to force.

After your application receives the refresh token, it may obtain new access tokens at any time.
The next time your application requests an authorization code for that user, the user will not be asked to grant
consent (assuming they previously granted access, and you are asking for the same scopes). As expected, the response
includes an authorization code which may be redeemed. However, unlike the first time an authorization code is exchanged
for a given user, a refresh token will not be returned from the authorization code exchange.
The following is an example of such a response:

{
  "access_token":"1/fFAGRNJru1FQd77BzhT3Zg",
  "expires_in":3600,
  "token_type":"Bearer",
}

Using a refresh token
*********************

As indicated in the previous section, a refresh token is obtained in offline scenarios during the first authorization
code exchange. In these cases, your application may obtain a new access token by sending a refresh token to the
OpenstackId OAuth 2.0 Authorization server.
To obtain a new access token this way, your application performs an HTTPS POST to
https://openstackid.openstack.org/oauth2/token. The request must include the following parameters:

+------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| Parameter                    | Description                                                                                                                     |
+==============================+=================================================================================================================================+
| refresh_token                | (required) The refresh token returned from the authorization code exchange.                                                     |
|                              |                                                                                                                                 |
+------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| grant_type                   | (required) As defined in the OAuth 2.0 specification, this field must contain a value of refresh_token.                         |
|                              |                                                                                                                                 |
+------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| scope                        | (optional) The requested scope MUST NOT include any scope not originally granted by the resource owner, and if omitted is       |
|                              | treated as equal to the scope originally granted by the resource owner.                                                         |
|                              |                                                                                                                                 |
+------------------------------+---------------------------------------------------------------------------------------------------------------------------------+


Such a request will look similar to the following:

POST /oauth2/token HTTP/1.1
Host: openstackid.openstack.org
Authorization: Basic Base64-Encoded(client_id:client_secret)
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token&refresh_token=tGzv3JOkF0XG5Qx2TlKWIA

As long as the user has not revoked the access granted to your application, the response includes a new access token.
A response from such a request is shown below:

{
  "access_token":"1/fFBGRNJru1FQd44AzqT3Zg",
  "expires_in":3600,
  "token_type":"Bearer",
}

Revoking a token
****************

In some cases a user may wish to revoke access given to an application. A user can revoke access by visiting the
following URL and explicitly revoking access: https://openstackid.openstack.org/admin/grants . It is also possible for
an application to programmatically revoke the access given to it. Programmatic revocation is important in instances
where a user unsubscribes or removes an application. In other words, part of the removal process can include an API
request to ensure the permissions granted to the application are removed.

To programmatically revoke a token, your application makes a request to

https://openstackid.openstack.org/oauth2/token/revoke and includes the token as a parameter and a hint


+------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| Parameter                    | Description                                                                                                                     |
+==============================+=================================================================================================================================+
| token                        | (required) Token value to revoke                                                                                                |
|                              |                                                                                                                                 |
+------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| token_type_hint              | (optional) access_token/refresh_token Hint to allow Authorization Server to do a  more performant token search                  |
|                              |                                                                                                                                 |
+------------------------------+---------------------------------------------------------------------------------------------------------------------------------+

The token can be an access token or a refresh token. If the token is an access token and it has a corresponding refresh token,
the refresh token will also be revoked.
If the revocation is successfully processed, then the status code of the response is 200.
For error conditions, a status code 400 is returned along with an error code.

Token Introspection
*******************

In OAuth 2.0, the contents of tokens are opaque to clients. This means that the client does not need to know anything
about the content or structure of the token itself, if there is any. However, there is still a large amount of metadata
that may be attached to a token, such as its current validity, approved scopes, and extra information about the
authentication context in which the token was issued.
These pieces of information are often vital to Protected Resources making authorization decisions based on the tokens
being presented. Since OAuth2 defines no direct relationship between the Authorization Server and the Protected Resource,
only that they must have an agreement on the tokens themselves, there have been many different approaches to bridging this gap.

OpenstackId Authorization Server implements `OAuth Token Introspection <http://tools.ietf.org/html/draft-richer-oauth-introspection-04>`_
to fix that gap.

To programmatically get info  for a token, your application makes a request to

https://openstackid.openstack.org/oauth2/token/introspection


Such a request will look similar to the following:

POST /oauth2/token/introspection HTTP/1.1
Host: openstackid.openstack.org
Authorization: Basic Base64-Encoded(client_id:client_secret)
Content-Type: application/x-www-form-urlencoded

token=tGzv3JOkF0XG5Qx2TlKWIA

**IMPORTANT** the token must belongs to clientid provided on the request, otherwise request will fail

The TokenInfo endpoint will respond with a JSON array that describes the token or an error.
Below is a table of the fields included in the non-error case:

+------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| Parameter                    | Description                                                                                                                     |
+==============================+=================================================================================================================================+
| audience                     | The Resource Server that is the intended target of the token.                                                                   |
|                              |                                                                                                                                 |
+------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| access_token                 | Token Value                                                                                                                     |
|                              |                                                                                                                                 |
+------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| client_id                    | The application that is the intended target of the token.                                                                       |
|                              |                                                                                                                                 |
+------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| scope                        | The space-delimited set of scopes that the user consented to.                                                                   |
|                              |                                                                                                                                 |
+------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| expires_in                   | The number of seconds left in the lifetime of the token.                                                                        |
|                              |                                                                                                                                 |
+------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| token_type                   | Identifies the type of token returned. At this time, this field will always have the value Bearer.                              |
|                              |                                                                                                                                 |
+------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| userid                       | This field is only present if a resource owner (end-user) had approved access on the consent screen.                            |
|                              |                                                                                                                                 |
+------------------------------+---------------------------------------------------------------------------------------------------------------------------------+


A response from such a request is shown below:

{
  "access_token":"1/fFBGRNJru1FQd44AzqT3Zg",
  "client_id": "xyz",
  "expires_in":3600,
  "token_type":"Bearer",
  "scope":"profile email",
  "audience": "resource.server1.com"
  "user_id": 123456
}

Using OAuth 2.0 for Client-side Applications
++++++++++++++++++++++++++++++++++++++++++++

The OpenstackId OAuth 2.0 endpoint supports JavaScript-centric applications. These applications may access an OpenstackId API
while the user is present at the application, and this type of application cannot keep a secret.

Overview
********

This scenario begins by redirecting a browser (full page or popup) to a OpenstackId URL with a set of query parameters
that indicate the type of OpenstackId API access the application requires. As in other scenarios, OpenstackId handles
user authentication and consent, and the result is an access token. OpenstackId returns the access token on the fragment
of the response, and client side script extracts the access token from the response.
The application may access an OpenstackId API after it receives the access token.

**NOTE:** Your application should always use HTTPS in this scenario.

Handling the response
*********************

OpenstackId returns an access token to your application if the user grants your application the permissions it requested.
The access token is returned to your application in the fragment as part of the access_token parameter. Since a fragment
is not returned to the server, client-side script must parse the fragment and extract the value of the access_token
parameter.
Other parameters included in the response include expires_in and token_type. These parameters describe the lifetime of
the token in seconds, and the kind of token that is being returned. If the state parameter was included in the request,
then it is also included in the response.
An example User Agent flow response is shown below:


https://oauth2-demo.com//oauthcallback#access_token=123456&token_type=Bearer&expires_in=3600

Calling an OpenstackId API
**************************

After your application obtains an access token, you can use the token to make calls to an Openstack API on behalf of a
given user. To do this, include the access token in a request to the API by including either an access_token query
parameter or an Authorization: Bearer HTTP header. When possible, it is preferable to use the HTTP Header, since query
strings tend to be visible in server logs.

**NOTE**: Be sure that OpenstackId Endpoint API that your application wants to access it's been
`CORS <http://www.w3.org/TR/cors/>`_ enabled


Using OAuth 2.0 for Server to Server Applications
+++++++++++++++++++++++++++++++++++++++++++++++++

The OpenstackId OAuth 2.0 Authorization Server supports server-to-server interactions. The requesting application has
to prove its own identity to gain access to an API, and an end-user doesn't have to be involved.

The client can request an access token using only its client credentials (or other supported means of authentication)
when the client is requesting access to the protected resources under its control, or those of another resource owner
that have been previously arranged with the authorization server.

The client makes a request to the token endpoint by adding the following parameters:

+------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| Parameter                    | Description                                                                                                                     |
+==============================+=================================================================================================================================+
| grant_type                   | (required) Value MUST be set to "client_credentials".                                                                           |
|                              |                                                                                                                                 |
+------------------------------+---------------------------------------------------------------------------------------------------------------------------------+
| scope                        | (required) Required Scopes                                                                                                      |
|                              |                                                                                                                                 |
+------------------------------+---------------------------------------------------------------------------------------------------------------------------------+


For example, the client makes the following HTTP request using
transport-layer security (with extra line breaks for display purposes
only):

POST /oauth2/token HTTP/1.1
Host: openstackid.openstack.org
Authorization: Basic Base64-Encoded(client_id:client_secret)
Content-Type: application/x-www-form-urlencoded

grant_type=client_credentials&scope=write.endpoint.api


An example successful response:

HTTP/1.1 200 OK
Content-Type: application/json;charset=UTF-8
Cache-Control: no-store
Pragma: no-cache

{
    "access_token":"123456",
    "token_type":"Bearer",
    "expires_in":3600,
}




Configuration
=============


Environment Configuration
_________________________

We need to instruct the Laravel Framework how to determine which environment it is running in. The default environment
is always production. However, you may setup other environments within the *bootstrap/start.php* file at the root of
your installation.

It is include on folder bootstrap a file called bootstrap/environment.php.tpl
you must make a copy and rename it to bootstrap/environment.php

In this file you will find an **$app->detectEnvironment** call. The array passed to this method is
used to determine the current environment. You may add other environments and machine names to the array as needed.

.. code:: php

<?php

$env = $app->detectEnvironment(array(

    'local' => array('your-machine-name'),

));

Database Configuration
______________________

It is often helpful to have different configuration values based on the environment the application is running in. For example, you may wish to use a different database configuration on your development machine than on the production server. It is easy to accomplish this using environment based configuration.
Simply create a folder within the config directory that matches your environment name, such as **dev**. Next, create the configuration files you wish to override and specify the options for that environment. For example, to override the database configuration for the local environment, you would create a database.php file in app/config/dev.

OpenstackId server makes use of two database connections:

* openstackid
* os_members

**openstackid** is its own OpenstackId Server DB, where stores all related configuration to openid/oauth2 protocol.
**os_members** is SS DB (http://www.openstack.org/).
both configuration are living on config file **database.php**, which could be a set per environment as forementioned
like app/config/dev/database.php


Error Log Configuration
_______________________

Error log configuration is on file *app/config/log.php*  but could be overriden per environment
such as *app/config/dev/log.php* , here you set two variables:

* to_email : The receiver of the error log email.
* from_email: The sender of the error log email.


Recaptcha Configuration
_______________________

OpenstackId server uses recaptcha facility to discourage brute force attacks attempts on login page, so in order to work
properly recaptcha plugin must be provided with a public and a private key (http://www.google.com/recaptcha).
These keys are set on file *app/config/packages/greggilbert/recaptcha/config.php* , but also could be set per environment
using following directory structure *app/config/packages/greggilbert/recaptcha/dev/config.php*.

Installation
____________

OpenstackId Server uses composer utility in order to install all needed dependencies. After you get the source code from git,
you must run following commands on application root directory:

* curl -sS https://getcomposer.org/installer | php
* php composer.phar install
* php artisan migrate --env=YOUR ENVIRONMENT
* php artisan db:seed --env=YOUR ENVIRONMENT

** your virtual host must point to /public folder.

Permissions
___________

Laravel may require one set of permissions to be configured: folders within app/storage require write access by the web server.