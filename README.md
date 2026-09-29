# Network Troubleshooter

A PowerShell-based network diagnostic tool designed to troubleshoot connectivity issues by working through the network stack and identifying where communication begins to fail.

Rather than simply testing whether a device has internet access, the goal is to perform a series of structured tests that help narrow down the source of a network problem.

## Current Features

The troubleshooter currently performs the following checks:

### Network Adapter
- Detects the primary Ethernet or Wi-Fi adapter
- Checks whether the adapter is enabled
- Checks whether an active network link exists
- Displays adapter type, description, administrative status, and link speed

### IPv4 Configuration
- Detects the assigned IPv4 address
- Detects APIPA/link-local addresses (`169.254.0.0/16`)
- Converts CIDR prefix length to a subnet mask
- Calculates the network address
- Verifies that the IPv4 address and default gateway belong to the same subnet

### Default Gateway
- Detects the configured default gateway
- Tests gateway reachability using ICMP
- Skips dependent tests when prerequisite network tests fail

## Diagnostic Results

Tests return structured results using the following statuses:

| Status | Meaning |
| --- | --- |
| PASS | Test completed successfully |
| FAIL | A network problem was detected |
| WARNING | A potential problem was detected |
| SKIP | Test could not be performed because a prerequisite failed |

Example:

Network Adapter Test \
Status: PASS \
Message: Adapter appears operational. \
Type: Wi-Fi \
Description: Intel(R) Wi-Fi 7 BE201 320MHz \
AdminStatus: Up \
LinkSpeed: 1.1 Gbps 

IPv4 Address Test \
Status: PASS \
Value: 10.10.6.68 \
Message: IPv4 address found and gateway is in the same subnet

## Project Goals

The long-term goal is to build an automated troubleshooting workflow that progresses through different areas of the network stack.

Planned tests may include:

- External IP connectivity
- DNS resolution
- TCP/UDP connectivity
- Internet connectivity
- DHCP diagnostics
- Routing diagnostics
- Additional adapter and interface information

## Requirements

- Windows
- PowerShell
- Windows networking cmdlets such as:
  - `Get-NetAdapter`
  - `Get-NetIPConfiguration`
  - `Test-Connection`

## Status

🚧 **Work in Progress**

This project is being actively developed as both a practical troubleshooting utility and a way to explore PowerShell, networking, and structured diagnostic logic.
