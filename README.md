# Device Security Rating - iOS Client

<details>
  <summary>Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
       <ul>
        <li><a href="#release-notes">Release Notes</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#license">License</a></li>
    <li><a href="#contact">Contact</a></li>
  </ol>
</details>

## About The Project

> [!NOTE]
> This software is a proof of concept and is not intended for production use. It will not be maintained or receive updates. Concepts from this project will be used in gematik specifications to standardize Zero Trust in Telematics Infrastructure. Developers are encouraged to use the implementation ideas in their own software.

Device Security Rating (DSR) is a Proof of Concept to demonstrate the secure access to services using Zero Trust design principles. In contrast to enterprise-centric Zero Trust architectures, where devices need to be owned and/or managed by a company, the DSR PoC is designed in a way that allows participants from different legal and organisational entities without the need of giving up the ownership of their devices.

This repository contains a proof of concept implementation of an iOS client. The whole system architecture and other implementations of the PoC can be found at [https://dsr.gematik.solutions](https://dsr.gematik.solutions).

### Release Notes
See [ReleaseNotes.md](./ReleaseNotes.md) for all information regarding the (newest) releases.

## Getting Started

The repository contains a library called "DeviceSecurityRating" that contains use case independent code for handling Zero Trust.

It also contains an Application Project within `App/` that demonstrates the implementation for a demo Application with a demo Service.

### Prerequisites

- Xcode (latest version recommended)
- fastlane (optional, for command line builds)

### Installation

To build the application use either `fastlane` on command line or open the Xcode Project `App/dsrpoc.xcodeproj`.

The PoC Endpoints are not reachable by this demo as there is an API key to use (you need to fill `development.env`, example within `development.env.default`). Please contact us if you want to test this.

## Usage

The repository contains a certificate and a private key to mimic an eGK in software.

For more examples or in-depth documentation, please refer to [https://dsr.gematik.solutions](https://dsr.gematik.solutions).

## License

Copyright 2023-2025 gematik GmbH

Apache License, Version 2.0

See the [LICENSE](./LICENSE) for the specific language governing permissions and limitations under the License

## Additional Notes and Disclaimer from gematik GmbH

1. Copyright notice: Each published work result is accompanied by an explicit statement of the license conditions for use. These are regularly typical conditions in connection with open source or free software. Programs described/provided/linked here are free software, unless otherwise stated.
2. Permission notice: Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
    1. The copyright notice (Item 1) and the permission notice (Item 2) shall be included in all copies or substantial portions of the Software.
    2. The software is provided "as is" without warranty of any kind, either express or implied, including, but not limited to, the warranties of fitness for a particular purpose, merchantability, and/or non-infringement. The authors or copyright holders shall not be liable in any manner whatsoever for any damages or other claims arising from, out of or in connection with the software or the use or other dealings with the software, whether in an action of contract, tort, or otherwise.
    3. The software is the result of research and development activities, therefore not necessarily quality assured and without the character of a liable product. For this reason, gematik does not provide any support or other user assistance (unless otherwise stated in individual cases and without justification of a legal obligation). Furthermore, there is no claim to further development and adaptation of the results to a more current state of the art.
3. Gematik may remove published results temporarily or permanently from the place of publication at any time without prior notice or justification.
4. Please note: Parts of this code may have been generated using AI-supported technology. Please take this into account, especially when troubleshooting, for security analyses and possible adjustments.

## Contact

This software is currently being tested to ensure its technical quality and legal compliance. Your feedback is highly valued. 
If you find any issues or have any suggestions or comments, or if you see any other ways in which we can improve, please reach out to: ospo@gematik.de.
