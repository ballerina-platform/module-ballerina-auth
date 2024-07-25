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

@test:Config {}
isolated function testExtractUsernameAndPasswordSuccess() returns Error? {
    string usernameAndPassword = "YWxpY2U6MTIz";
    [string, string] [username, password] = check extractUsernameAndPassword(usernameAndPassword);
    test:assertEquals(username, "alice");
    test:assertEquals(password, "123");
}

@test:Config {}
isolated function testExtractUsernameAndPasswordForInvalidBase64Value() {
    string usernameAndPassword = "!nval!d-b@$e64-encoded-va!ue";
    [string, string]|Error result = extractUsernameAndPassword(usernameAndPassword);
    if result is Error {
        assertContains(result, "Failed to convert string credential to byte[].");
    } else {
        test:assertFail("Expected error not found.");
    }
}

@test:Config {}
isolated function testExtractUsernameAndPasswordForWithoutColon() {
    string usernameAndPassword = "YWxpY2UxMjM=";
    [string, string]|Error result = extractUsernameAndPassword(usernameAndPassword);
    if result is Error {
        assertContains(result, "Incorrect credential format. Format should be username:password");
    } else {
        test:assertFail("Expected error not found.");
    }
}

@test:Config {}
isolated function testExtractUsernameAndPasswordForEmptyPassword() returns Error? {
    string usernameAndPassword = "YWxpY2U6";
    [string, string]|Error result = extractUsernameAndPassword(usernameAndPassword);
    if result is Error {
        assertContains(result, "Incorrect credential format. Format should be username:password");
    } else {
        test:assertFail("Expected error not found.");
    }
}

@test:Config {}
isolated function testExtractUsernameAndPasswordForEmptyUsername() returns Error? {
    string usernameAndPassword = "OjEyMw==";
    [string, string]|Error result = extractUsernameAndPassword(usernameAndPassword);
    if result is Error {
        assertContains(result, "Incorrect credential format. Format should be username:password");
    } else {
        test:assertFail("Expected error not found.");
    }
}

@test:Config {}
isolated function testExtractUsernameAndPasswordWherePasswordIncludesColon() returns Error? {
    string usernameAndPassword = "YWxpY2U6YWxpY2U6QDU=";
    [string, string] [username, password] = check extractUsernameAndPassword(usernameAndPassword);
    test:assertEquals(username, "alice");
    test:assertEquals(password, "alice:@5");
}

@test:Config {}
isolated function testExtractUsernameAndPasswordWherePasswordEndsWithColon() returns Error? {
    string usernameAndPassword = "YWxpY2U6YWxpY2UxMjM6YWxpY2U6";
    [string, string] [username, password] = check extractUsernameAndPassword(usernameAndPassword);
    test:assertEquals(username, "alice");
    test:assertEquals(password, "alice123:alice:");
}
