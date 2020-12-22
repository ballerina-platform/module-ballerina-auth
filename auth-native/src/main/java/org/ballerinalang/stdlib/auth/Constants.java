package org.ballerinalang.stdlib.auth;

import io.ballerina.runtime.api.Module;

import static io.ballerina.runtime.api.constants.RuntimeConstants.BALLERINA_BUILTIN_PKG_PREFIX;

/**
 * Constants related to Ballerina auth stdlib.
 */
public class Constants {

    public static final String PACKAGE_NAME = "auth";
    public static final Module AUTH_PACKAGE_ID = new Module(BALLERINA_BUILTIN_PKG_PREFIX, PACKAGE_NAME, "1.0.5");

    public static final String AUTH_INVOCATION_CONTEXT_PROPERTY = "AuthInvocationContext";
    public static final String RECORD_TYPE_INVOCATION_CONTEXT = "InvocationContext";
}
