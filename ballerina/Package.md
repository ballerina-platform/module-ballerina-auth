## Package Overview

The `auth` library is one of the standard library modules of the <a target="_blank" href="https://ballerina.io/">Ballerina</a> language.

This module provides a framework for authentication/authorization based on the Basic Authentication scheme specified in <a target="_blank" href="https://datatracker.ietf.org/doc/html/rfc7617">RFC 7617</a>.

The Basic Authentication scheme transmits credentials as user-id/password pairs encoded using Base64. This scheme is not considered to be a secure method of user authentication unless used in conjunction with some external secure system such as TLS as the user ID and password are passed over the network as cleartext.

The Ballerina `auth` module facilitates auth providers that are to be used by the clients and listeners of different protocol connectors.

### Report Issues

To report bugs, request new features, start new discussions, view project boards, etc., go to the <a target="_blank" href="https://github.com/ballerina-platform/ballerina-standard-library">Ballerina standard library parent repository</a>.

### Useful Links

- Chat live with us via our <a target="_blank" href="https://ballerina.io/community/slack/">Slack channel</a>.
- Post all technical questions on Stack Overflow with the <a target="_blank" href="https://stackoverflow.com/questions/tagged/ballerina">#ballerina</a> tag.
