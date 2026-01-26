# Network Architecture

## Current State (Week 2)

            Internet
                │

┌───────────────┴───────────────┐
│ HUB VNET (10.0.0.0/16) │
│ ┌─────────────────────────┐ │
│ │ shared-services │ │
│ │ 10.0.1.0/24 │ │
│ │ - (Jump box planned) │ │
│ └─────────────────────────┘ │
└───────────────┬───────────────┘
│ VNet Peering
┌───────────────┴───────────────┐
│ SPOKE-DEV (10.1.0.0/16) │
│ ┌────────────┐ ┌───────────┐ │
│ │ snet-app │ │ snet-data │ │
│ │ 10.1.1.0/24│ │10.1.2.0/24│ │
│ └────────────┘ └───────────┘ │
└───────────────────────────────┘

## IP Address Allocation

| VNet       | CIDR        | Purpose                       |
| ---------- | ----------- | ----------------------------- |
| Hub        | 10.0.0.0/16 | Shared services, connectivity |
| Spoke-Dev  | 10.1.0.0/16 | Development workloads         |
| Spoke-Test | 10.2.0.0/16 | (Planned)                     |
| Spoke-Prod | 10.3.0.0/16 | (Planned)                     |

## Peering Status

| Source    | Destination | State        |
| --------- | ----------- | ------------ |
| Hub       | Spoke-Dev   | Connected ✅ |
| Spoke-Dev | Hub         | Connected ✅ |
