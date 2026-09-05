## Overview

This module provides a framework for authentication and authorization based on the Basic Authentication scheme specified in [RFC 7617](https://datatracker.ietf.org/doc/html/rfc7617), used to define auth providers for clients and listeners of different protocol connectors.

## Key Features

- File-based and LDAP-based Basic Auth providers for listeners
- Basic Auth provider for clients
- Credentials transmitted as Base64-encoded user-id/password pairs, per RFC 7617

### Listener file user store Basic Auth provider

Represents the file user store based listener Basic Auth provider, which is used to authenticate the provided credentials against the provided file user store configurations. The users are denoted by a section in the `Config.toml` file. The username, password, and the scopes of a particular user are denoted as keys under the `users` section as shown below. For multiple users, the complete section has to be duplicated.

```toml
[[ballerina.auth.users]]
username="alice"
password="xxx"
scopes=["read", "write"]
```

### Listener LDAP user store Basic Auth provider

Represents the LDAP-based listener Basic Auth provider, which is used to authenticate the provided credentials against the provided LDAP user store configurations. This connects to an active directory or an LDAP, which retrieves the necessary user information and performs authentication and authorization.

### Client Basic Auth provider

Represents the client Basic Auth provider, which is used to authenticate with an external endpoint by generating a Basic Auth token against the provided credential configurations.
