// Copyright (c) 2018 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
//
// WSO2 Inc. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/crypto;
import ballerina/jballerina.java;

# Represents the LDAP user store configurations.
#
# + domainName - Unique name to identify the user store
# + connectionUrl - Connection URL of the LDAP server
# + connectionName - The username used to connect to the LDAP server
# + connectionPassword - The password used to connect to the LDAP server
# + userSearchBase - DN of the context or object under which the user entries are stored in the LDAP server
# + userEntryObjectClass - Object class used to construct user entries
# + userNameAttribute - The attribute used for uniquely identifying a user entry
# + userNameSearchFilter - Filtering criteria used to search for a particular user entry
# + userNameListFilter - Filtering criteria for searching user entries in the LDAP server
# + groupSearchBase - DN of the context or object under which the group entries are stored in the LDAP server
# + groupEntryObjectClass - Object class used to construct group entries
# + groupNameAttribute - The attribute used for uniquely identifying a group entry
# + groupNameSearchFilter - Filtering criteria used to search for a particular group entry
# + groupNameListFilter - Filtering criteria for searching group entries in the LDAP server
# + membershipAttribute - Define the attribute, which contains the distinguished names (DN) of user objects that are there in a group
# + userRolesCacheEnabled -  To indicate whether to cache the role list of a user
# + connectionPoolingEnabled - Define whether LDAP connection pooling is enabled
# + connectionTimeout - Connection timeout (in seconds) when making the initial LDAP connection
# + readTimeout - Reading timeout (in seconds) for LDAP operations
# + secureSocket - The SSL configurations for the LDAP client socket. This needs to be configured in order to communicate through LDAPs
public type LdapUserStoreConfig record {|
    string domainName;
    string connectionUrl;
    string connectionName;
    string connectionPassword;
    string userSearchBase;
    string userEntryObjectClass;
    string userNameAttribute;
    string userNameSearchFilter;
    string userNameListFilter;
    string[] groupSearchBase;
    string groupEntryObjectClass;
    string groupNameAttribute;
    string groupNameSearchFilter;
    string groupNameListFilter;
    string membershipAttribute;
    boolean userRolesCacheEnabled = false;
    boolean connectionPoolingEnabled = true;
    decimal connectionTimeout = 5;
    decimal readTimeout = 60;
    SecureSocket secureSocket?;
|};

# Represents the SSL/TLS configurations.
#
# + cert - Configurations associated with the `crypto:TrustStore` or single certificate file that the client trusts
public type SecureSocket record {|
    crypto:TrustStore|string cert;
|};

// Represents the LDAP connection.
type LdapConnection record {|
|};

# Represents the LDAP-based listener Basic Auth provider, which is used to authenticate the provided credentials
# against the provided LDAP user store configurations. This connects to an active directory or an LDAP, retrieves
# the necessary user information, and performs authentication and authorization.
# ```ballerina
# auth:LdapUserStoreConfig config = {
#     domainName: "ballerina.io",
#     connectionURL: "ldap://localhost:389",
#     connectionName: "cn=admin,dc=avix,dc=lk"
# };
# auth:ListenerLdapUserStoreBasicAuthProvider provider = new(config);
# ```
public class ListenerLdapUserStoreBasicAuthProvider {

    *ListenerBasicAuthProvider;

    LdapConnection ldapConnection;
    LdapUserStoreConfig ldapUserStoreConfig;

    # Creates an LDAP auth store with the provided configurations.
    #
    # + ldapUserStoreConfig - The LDAP user store configurations
    public isolated function init(LdapUserStoreConfig ldapUserStoreConfig) {
        self.ldapUserStoreConfig = ldapUserStoreConfig;
        LdapConnection|Error ldapConnection = initLdapConnection(self.ldapUserStoreConfig);
        if (ldapConnection is LdapConnection) {
            self.ldapConnection = ldapConnection;
        } else {
            panic ldapConnection;
        }
    }

    # Attempts to authenticate the Base64-encoded `username:password` credentials.
    # ```ballerina
    # auth:UserDetails result = check provider.authenticate("<credential>");
    # ```
    #
    # + credential - The Base64-encoded `username:password` value
    # + return - `auth:UserDetails` if the authentication is successful or else an `auth:Error` if an error occurred
    public isolated function authenticate(string credential) returns UserDetails|Error {
        if (credential == "") {
            return prepareError("Credential cannot be empty.");
        }
        [string, string] [username, password] = check extractUsernameAndPassword(credential);
        Error? authenticated = authenticateWithLdap(self.ldapConnection, username, password);
        if (authenticated is Error) {
            return prepareError("Failed to authenticate username '" + username + "' with LDAP user store.", authenticated);
        }
        UserDetails userDetails = {
            username: username
        };
        string[]|Error? groups = getLdapGroups(self.ldapConnection, username);
        if (groups is string[]) {
            userDetails.scopes = groups;
        } else if (groups is Error) {
            return prepareError("Failed to get groups for the username '" + username + "' from LDAP user store.", groups);
        }
        return userDetails;
    }
}

// Retrieves the group(s) of the user related to the provided username.
isolated function getLdapGroups(LdapConnection ldapConnection, string username) returns string[]|Error? = @java:Method {
    name: "getGroups",
    'class: "org.ballerinalang.stdlib.auth.ldap.nativeimpl.GetGroups"
} external;

// Authenticates with the provided username and password.
isolated function authenticateWithLdap(LdapConnection ldapConnection, string username, string password)
                                       returns Error? = @java:Method {
    name: "authenticate",
    'class: "org.ballerinalang.stdlib.auth.ldap.nativeimpl.Authenticate"
} external;

// Initializes the LDAP connection.
isolated function initLdapConnection(LdapUserStoreConfig ldapUserStoreConfig)
                                     returns LdapConnection|Error = @java:Method {
    name: "initLdapConnection",
    'class: "org.ballerinalang.stdlib.auth.ldap.nativeimpl.InitLdapConnection"
} external;
