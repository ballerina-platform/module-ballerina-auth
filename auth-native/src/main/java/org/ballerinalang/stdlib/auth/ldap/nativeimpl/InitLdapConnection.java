/*
 * Copyright (c) 2018, WSO2 Inc. (http://www.wso2.org) All Rights Reserved.
 *
 * WSO2 Inc. licenses this file to you under the Apache License,
 * Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License.
 * You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied. See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */

package org.ballerinalang.stdlib.auth.ldap.nativeimpl;

import io.ballerina.runtime.api.creators.ValueCreator;
import io.ballerina.runtime.api.utils.StringUtils;
import io.ballerina.runtime.api.values.BDecimal;
import io.ballerina.runtime.api.values.BMap;
import io.ballerina.runtime.api.values.BString;
import org.ballerinalang.stdlib.auth.ModuleUtils;
import org.ballerinalang.stdlib.auth.ldap.CommonLdapConfiguration;
import org.ballerinalang.stdlib.auth.ldap.ConnectionContext;
import org.ballerinalang.stdlib.auth.ldap.LdapConstants;
import org.ballerinalang.stdlib.auth.ldap.SslContextTrustManager;
import org.ballerinalang.stdlib.auth.ldap.utils.LdapUtils;
import org.ballerinalang.stdlib.auth.ldap.utils.SslUtils;

import java.io.File;
import java.io.IOException;
import java.security.KeyManagementException;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.cert.CertificateException;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

import javax.naming.NamingException;
import javax.naming.directory.DirContext;
import javax.net.ssl.SSLContext;

/**
 * Initializes LDAP connection context.
 *
 * @since 0.983.0
 */
public class InitLdapConnection {

    public static Object initLdapConnection(BMap<BString, Object> authProviderConfig) {
        CommonLdapConfiguration commonLdapConfiguration = new CommonLdapConfiguration();

        String instanceId = UUID.randomUUID().toString();
        commonLdapConfiguration.setDomainName(authProviderConfig.getStringValue(
                StringUtils.fromString(LdapConstants.DOMAIN_NAME)).getValue());
        commonLdapConfiguration.setConnectionURL(authProviderConfig.getStringValue(
                StringUtils.fromString(LdapConstants.CONNECTION_URL)).getValue());
        commonLdapConfiguration.setConnectionName(authProviderConfig.getStringValue(
                StringUtils.fromString(LdapConstants.CONNECTION_NAME)).getValue());
        commonLdapConfiguration.setConnectionPassword(authProviderConfig.getStringValue(
                StringUtils.fromString(LdapConstants.CONNECTION_PASSWORD)).getValue());

        commonLdapConfiguration.setUserSearchBase(authProviderConfig.getStringValue(
                StringUtils.fromString(LdapConstants.USER_SEARCH_BASE)).getValue());
        commonLdapConfiguration.setUserEntryObjectClass(authProviderConfig.getStringValue(
                StringUtils.fromString(LdapConstants.USER_ENTRY_OBJECT_CLASS)).getValue());
        commonLdapConfiguration.setUserNameAttribute(authProviderConfig.getStringValue(
                StringUtils.fromString(LdapConstants.USER_NAME_ATTRIBUTE)).getValue());
        commonLdapConfiguration.setUserNameSearchFilter(authProviderConfig.getStringValue(
                StringUtils.fromString(LdapConstants.USER_NAME_SEARCH_FILTER)).getValue());
        commonLdapConfiguration.setUserNameListFilter(authProviderConfig.getStringValue(
                StringUtils.fromString(LdapConstants.USER_NAME_LIST_FILTER)).getValue());

        commonLdapConfiguration.setGroupSearchBase(getAsStringList(authProviderConfig.getArrayValue(
                StringUtils.fromString(LdapConstants.GROUP_SEARCH_BASE)).getStringArray()));
        commonLdapConfiguration.setGroupEntryObjectClass(authProviderConfig.getStringValue(
                StringUtils.fromString(LdapConstants.GROUP_ENTRY_OBJECT_CLASS)).getValue());
        commonLdapConfiguration.setGroupNameAttribute(authProviderConfig.getStringValue(
                StringUtils.fromString(LdapConstants.GROUP_NAME_ATTRIBUTE)).getValue());
        commonLdapConfiguration.setGroupNameSearchFilter(authProviderConfig.getStringValue(
                StringUtils.fromString(LdapConstants.GROUP_NAME_SEARCH_FILTER)).getValue());
        commonLdapConfiguration.setGroupNameListFilter(authProviderConfig.getStringValue(
                StringUtils.fromString(LdapConstants.GROUP_NAME_LIST_FILTER)).getValue());

        commonLdapConfiguration.setMembershipAttribute(authProviderConfig.getStringValue(
                StringUtils.fromString(LdapConstants.MEMBERSHIP_ATTRIBUTE)).getValue());
        commonLdapConfiguration.setUserRolesCacheEnabled(authProviderConfig.getBooleanValue(
                StringUtils.fromString(LdapConstants.USER_ROLE_CACHE_ENABLE)));
        commonLdapConfiguration.setConnectionPoolingEnabled(authProviderConfig.getBooleanValue(
                StringUtils.fromString(LdapConstants.CONNECTION_POOLING_ENABLED)));
        commonLdapConfiguration.setConnectionTimeout(((BDecimal) authProviderConfig.get(
                StringUtils.fromString(LdapConstants.CONNECTION_TIME_OUT))).floatValue());
        commonLdapConfiguration.setReadTimeout(((BDecimal) authProviderConfig.get(
                StringUtils.fromString(LdapConstants.READ_TIME_OUT))).floatValue());

        BMap<BString, Object> sslConfig = authProviderConfig.containsKey(
                StringUtils.fromString(LdapConstants.SECURE_AUTH_STORE_CONFIG)) ?
                (BMap<BString, Object>) authProviderConfig.getMapValue(
                        StringUtils.fromString(LdapConstants.SECURE_AUTH_STORE_CONFIG)) : null;
        try {
            if (sslConfig != null) {
                setSslConfig(sslConfig, commonLdapConfiguration, instanceId);
                LdapUtils.setServiceName(instanceId);
            }
            ConnectionContext connectionSource = new ConnectionContext(commonLdapConfiguration);
            DirContext dirContext = connectionSource.getContext();

            BMap<BString, Object> ldapConnectionRecord = ValueCreator.
                    createRecordValue(ModuleUtils.getModule(), LdapConstants.LDAP_CONNECTION);
            ldapConnectionRecord.addNativeData(LdapConstants.LDAP_CONFIGURATION, commonLdapConfiguration);
            ldapConnectionRecord.addNativeData(LdapConstants.LDAP_CONNECTION_SOURCE, connectionSource);
            ldapConnectionRecord.addNativeData(LdapConstants.LDAP_CONNECTION_CONTEXT, dirContext);
            ldapConnectionRecord.addNativeData(LdapConstants.ENDPOINT_INSTANCE_ID, instanceId);
            return ldapConnectionRecord;
        } catch (KeyStoreException | KeyManagementException | NoSuchAlgorithmException
                | CertificateException | NamingException | IOException | IllegalArgumentException e) {
            if (e.getCause() == null) {
                return LdapUtils.createError(e.getMessage());
            }
            return LdapUtils.createError(e.getCause().getMessage());
        } finally {
            if (sslConfig != null) {
                LdapUtils.removeServiceName();
            }
        }
    }

    private static void setSslConfig(BMap<BString, Object> sslConfig,
                                     CommonLdapConfiguration commonLdapConfiguration, String instanceId)
            throws IOException, NoSuchAlgorithmException, KeyStoreException, KeyManagementException,
            CertificateException {
        BMap<BString, BString> trustStore = (BMap<BString, BString>) sslConfig.getMapValue(
                StringUtils.fromString(LdapConstants.AUTH_STORE_CONFIG_TRUST_STORE));
        String trustCerts = sslConfig.containsKey(LdapConstants.AUTH_STORE_CONFIG_TRUST_CERTIFICATES) ?
                sslConfig.getStringValue(
                        StringUtils.fromString(LdapConstants.AUTH_STORE_CONFIG_TRUST_CERTIFICATES)).getValue() : null;

        if (trustStore != null) {
            String trustStoreFilePath = trustStore.getStringValue(
                    StringUtils.fromString(LdapConstants.FILE_PATH)).getValue();
            String trustStorePassword = trustStore.getStringValue(
                    StringUtils.fromString(LdapConstants.PASSWORD)).getValue();
            File trustStoreFile = new File(LdapUtils.substituteVariables(trustStoreFilePath));
            if (!trustStoreFile.exists()) {
                throw new IllegalArgumentException("TrustStore file '" + trustStoreFilePath + "' not found");
            }
            commonLdapConfiguration.setTrustStoreFile(trustStoreFile);
            commonLdapConfiguration.setTrustStorePass(trustStorePassword);
            SSLContext sslContext = SslUtils.createClientSslContext(trustStoreFilePath, trustStorePassword);
            SslContextTrustManager.getInstance().addSSLContext(instanceId, sslContext);
        } else if (trustCerts != null) {
            commonLdapConfiguration.setClientTrustCertificates(trustCerts);
            SSLContext sslContext = SslUtils.getSslContextForCertificateFile(trustCerts);
            SslContextTrustManager.getInstance().addSSLContext(instanceId, sslContext);
        }
    }

    private static List<String> getAsStringList(Object[] values) {
        if (values == null) {
            return null;
        }
        List<String> valuesList = new ArrayList<>();
        for (Object val : values) {
            valuesList.add(val.toString().trim());
        }
        return !valuesList.isEmpty() ? valuesList : null;
    }
}
