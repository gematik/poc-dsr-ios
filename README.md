# DeviceSecurityRating

Device Security Rating (DSR) is a Proof of Concept to demonstrate the secure access to services using Zero Trust design principles. In contrast to enterprise-centric Zero Trust architectures, where devices need to be owned and/or managed by a company, the DSR PoC is designed in a way that allows participants from different legal and organisational entities without the need of giving up the ownership of their devices.

This repository contains a proof of concept implementation of an iOS client. The whole system architecture and other implementations of the PoC can be found at [https://dsr.gematik.solutions](https://dsr.gematik.solutions).

## Structure

The repository contains a library called "DeviceSecurityRating" that contains use case independend code for handling Zero Trust.

It also contains an Application Project within `App/` that demonstrates the implementation for a demo Application with a demo Service.

To build the application use either `fastlane` on command line or open the Xcode Project `App/dsrpoc.xcodeproj`.

The PoC Endpoints are not reachable by this demo as there is an API key to use (you need to fill `development.env`, example within `development.env.default`). Please contact us if you want to test this.

The repository contains a certificate and a private key to mimic an eGK in software.

## License
 
Copyright [Jahr] gematik GmbH
 
Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License.
 
See the [LICENSE](./LICENSE) for the specific language governing permissions and limitations under the License.
 
Unless required by applicable law the software is provided "as is" without warranty of any kind, either express or implied, including, but not limited to, the warranties of fitness for a particular purpose, merchantability, and/or non-infringement. The authors or copyright holders shall not be liable in any manner whatsoever for any damages or other claims arising from, out of or in connection with the software or the use or other dealings with the software, whether in an action of contract, tort, or otherwise.
 
The software is the result of research and development activities, therefore not necessarily quality assured and without the character of a liable product. For this reason, gematik does not provide any support or other user assistance (unless otherwise stated in individual cases and without justification of a legal obligation). Furthermore, there is no claim to further development and adaptation of the results to a more current state of the art.
 
Gematik may remove published results temporarily or permanently from the place of publication at any time without prior notice or justification.
