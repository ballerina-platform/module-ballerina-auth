## Overview

This module provides a framework for authentication/authorization with the Basic Authentication scheme as specified in [RFC 7617](https://datatracker.ietf.org/doc/html/rfc7617).

The "Basic" Hypertext Transfer Protocol (HTTP) authentication scheme transmits credentials as user-id/password pairs encoded using Base64. This scheme is not considered to be a secure method of user authentication unless used in conjunction with some external secure system such as TLS as the user ID and password are passed over the network as cleartext.

The Ballerina `auth` module facilitates auth providers that are to be used by the clients and listeners of different protocol connectors.

### Listener File User Store Basic Auth Provider

Represents the file user store-based listener Basic Auth provider, which is used to authenticate the provided credentials against the provided file user store configurations. The users are denoted by a section in the `Config.toml` file. The username, password, and the scopes of a particular user are denoted as keys under the `users` section as shown below. For multiple users, the complete section has to be duplicated.

```toml
[[ballerina.auth.users]]
username="alice"
password="xxx"
scopes=["read", "write"]
```

### Listener LDAP User Store Basic Auth Provider

Represents the LDAP-based listener Basic Auth provider, which is used to authenticate the provided credentials against the provided LDAP user store configurations. This connects to an active directory or an LDAP, retrieves the necessary user information, and performs authentication and authorization.

### Client Basic Auth Provider

Represents the client Basic Auth provider, which is used to authenticate with an external endpoint by generating a Basic Auth token against the provided credential configurations.
