// Copyright (c) 2021 WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
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

import ballerina/test;

@test:Config {
    groups: ["ldap"]
}
isolated function testLdapAuthenticationEmptyCredential() {
    string usernameAndPassword = "";
    UserDetails|Error result = authenticateLdap(usernameAndPassword);
    if (result is Error) {
        test:assertEquals(result.message(), "Credential cannot be empty.");
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {
    groups: ["ldap"]
}
isolated function testLdapAuthenticationOfNonExistingUser() {
    string usernameAndPassword = "dave:123";
    UserDetails|Error result = authenticateLdap(usernameAndPassword);
    if (result is Error) {
        test:assertEquals(result.message(), "Failed to authenticate username 'dave' with LDAP user store.");
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {
    groups: ["ldap"]
}
isolated function testLdapAuthenticationOfInvalidPassword() {
    string usernameAndPassword = "alice:invalid";
    UserDetails|Error result = authenticateLdap(usernameAndPassword);
    if (result is Error) {
        test:assertEquals(result.message(), "Failed to authenticate username 'alice' with LDAP user store.");
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {
    groups: ["ldap"]
}
isolated function testLdapAuthenticationSuccessForUser() {
    string usernameAndPassword = "alice:alice123";
    UserDetails|Error result = authenticateLdap(usernameAndPassword);
    if (result is UserDetails) {
        test:assertEquals(result.username, "alice");
        test:assertEquals(result?.scopes, ["Developer"]);
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {
    groups: ["ldap"]
}
isolated function testLdapAuthenticationSuccessForSuperUser() {
    string usernameAndPassword = "ldclakmal:ldclakmal123";
    UserDetails|Error result = authenticateLdap(usernameAndPassword);
    if (result is UserDetails) {
        test:assertEquals(result.username, "ldclakmal");
        test:assertEquals(result?.scopes, ["Admin", "Developer"]);
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {
    groups: ["ldap"]
}
isolated function testLdapAuthenticationWithEmptyUsername() {
    string usernameAndPassword = ":xxx";
    UserDetails|Error result = authenticateLdap(usernameAndPassword);
    if (result is Error) {
        test:assertEquals(result.message(), "Incorrect credential format. Format should be username:password");
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {
    groups: ["ldap"]
}
isolated function testLdapAuthenticationWithEmptyPassword() {
    string usernameAndPassword = "alice:";
    UserDetails|Error result = authenticateLdap(usernameAndPassword);
    if (result is Error) {
        test:assertEquals(result.message(), "Incorrect credential format. Format should be username:password");
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {
    groups: ["ldap"]
}
isolated function testLdapAuthenticationWithEmptyPasswordAndInvalidUsername() {
    string usernameAndPassword = "invalid:";
    UserDetails|Error result = authenticateLdap(usernameAndPassword);
    if (result is Error) {
        test:assertEquals(result.message(), "Incorrect credential format. Format should be username:password");
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

@test:Config {
    groups: ["ldap"]
}
isolated function testLdapAuthenticationWithEmptyUsernameAndEmptyPassword() {
    string usernameAndPassword = ":";
    UserDetails|Error result = authenticateLdap(usernameAndPassword);
    if (result is Error) {
        test:assertEquals(result.message(), "Incorrect credential format. Format should be username:password");
    } else {
        test:assertFail(msg = "Test Failed!");
    }
}

isolated function authenticateLdap(string usernameAndPassword) returns UserDetails|Error {
    LdapUserStoreConfig ldapUserStoreConfig = {
        domainName: "avix.lk",
        connectionUrl: "ldap://localhost:389",
        connectionName: "cn=admin,dc=avix,dc=lk",
        connectionPassword: "avix123",
        userSearchBase: "ou=Users,dc=avix,dc=lk",
        userEntryObjectClass: "inetOrgPerson",
        userNameAttribute: "uid",
        userNameSearchFilter: "(&(objectClass=inetOrgPerson)(uid=?))",
        userNameListFilter: "(objectClass=inetOrgPerson)",
        groupSearchBase: ["ou=Groups,dc=avix,dc=lk"],
        groupEntryObjectClass: "groupOfNames",
        groupNameAttribute: "cn",
        groupNameSearchFilter: "(&(objectClass=groupOfNames)(cn=?))",
        groupNameListFilter: "(objectClass=groupOfNames)",
        membershipAttribute: "member",
        userRolesCacheEnabled: true,
        connectionPoolingEnabled: false,
        connectionTimeoutInMillis: 5000,
        readTimeoutInMillis: 60000
    };
    ListenerLdapUserStoreBasicAuthProvider basicAuthProvider = new(ldapUserStoreConfig);
    string credential = usernameAndPassword.toBytes().toBase64();
    return basicAuthProvider.authenticate(credential);
}
