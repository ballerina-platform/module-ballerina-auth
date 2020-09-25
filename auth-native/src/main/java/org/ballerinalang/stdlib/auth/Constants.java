package org.ballerinalang.stdlib.auth;

import org.ballerinalang.jvm.types.BPackage;

import static org.ballerinalang.jvm.util.BLangConstants.BALLERINA_BUILTIN_PKG_PREFIX;

/**
 * Constants related to Ballerina auth stdlib.
 */
public class Constants {

    public static final String PACKAGE_NAME = "auth";
    public static final BPackage AUTH_PACKAGE_ID = new BPackage(BALLERINA_BUILTIN_PKG_PREFIX, PACKAGE_NAME, "1.0.1");

    public static final String AUTH_INVOCATION_CONTEXT_PROPERTY = "AuthInvocationContext";
    public static final String RECORD_TYPE_INVOCATION_CONTEXT = "InvocationContext";
}
