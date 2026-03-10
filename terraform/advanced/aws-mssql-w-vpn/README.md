# Dev MSSQL — VPN-Secured Environment

Replicates the RDS network security pattern for a dev SQL Server instance.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  VPC 10.50.0.0/16                                           │
│                                                             │
│  ┌─────────────────────┐    ┌────────────────────────────┐  │
│  │  Public Subnet       │    │  Private Subnet             │  │
│  │  10.50.100.0/24      │    │  10.50.1.0/24               │  │
│  │                      │    │                              │  │
│  │  ┌──────────────┐   │    │  ┌────────────────────────┐  │  │
│  │  │  NAT Gateway  │   │    │  │  EC2 Windows + MSSQL   │  │  │
│  │  │  (outbound    │   │    │  │  - SQL Server 2022 Dev │  │  │
│  │  │   only)       │   │    │  │  - SSMS installed      │  │  │
│  │  └──────────────┘   │    │  │  - No public IP         │  │  │
│  │                      │    │  └────────────────────────┘  │  │
│  └─────────────────────┘    │                              │  │
│                              │  ┌────────────────────────┐  │  │
│           ┌──────────────────│──│  Client VPN Endpoint   │  │  │
│           │                  │  └────────────────────────┘  │  │
│           │                  └────────────────────────────┘  │
│           ▼                                                 │
│  ┌──────────────┐                                           │
│  │  IGW          │                                           │
│  └──────┬───────┘                                           │
└─────────┼───────────────────────────────────────────────────┘
          │
     ┌────▼────┐
     │ Internet │
     └────▲────┘
          │
     ┌────┴─────────────┐
     │  Your Laptop      │
     │  (VPN Client)     │
     │  10.100.0.0/22    │
     └──────────────────┘
```

## Security Groups (mirrors RDS pattern)

| Port | Protocol | Source          | Purpose                    |
|------|----------|----------------|----------------------------|
| 1433 | TCP      | 10.100.0.0/22  | SQL Server from VPN clients |
| 1433 | TCP      | 10.50.0.0/16   | SQL Server from VPC         |
| 3389 | TCP      | 10.100.0.0/22  | RDP from VPN clients        |

No public inbound access. All outbound allowed (for Windows Update, SSMS download).

## Deploy

```powershell
# 1. Set sensitive vars
. .\load-env.ps1

# 2. Init and apply
terraform init
terraform plan
terraform apply
```

## Connect via VPN

### Step 1: Download the VPN client config

```powershell
# Get the VPN endpoint ID from terraform output
$vpnId = terraform output -raw vpn_endpoint_id

# Export the base OpenVPN config
aws ec2 export-client-vpn-client-configuration `
  --client-vpn-endpoint-id $vpnId `
  --output text > vpn-config/client-config.ovpn
```

### Step 2: Append client certs to the .ovpn file

Add the following to the **end** of `client-config.ovpn`:

```
<cert>
[paste contents of vpn-config/client-cert.pem]
</cert>

<key>
[paste contents of vpn-config/client-key.pem]
</key>
```

Or run this PowerShell to do it automatically:

```powershell
$ovpn = Get-Content "vpn-config/client-config.ovpn" -Raw
$cert = Get-Content "vpn-config/client-cert.pem" -Raw
$key  = Get-Content "vpn-config/client-key.pem" -Raw

$ovpn += "`n<cert>`n$cert</cert>`n<key>`n$key</key>"
$ovpn | Set-Content "vpn-config/client-config.ovpn"
```

### Step 3: Connect

1. Install [AWS VPN Client](https://aws.amazon.com/vpn/client-vpn-download/) or OpenVPN
2. Import `vpn-config/client-config.ovpn`
3. Connect

### Step 4: RDP to the EC2

```powershell
# Get the Windows Administrator password
$instanceId = terraform output -raw ec2_instance_id
aws ec2 get-password-data `
  --instance-id $instanceId `
  --priv-launch-key vpn-config/dev-mssql-key.pem `
  --query PasswordData --output text

# RDP to private IP
$ip = terraform output -raw ec2_private_ip
mstsc /v:$ip
```

### Step 5: Connect SSMS to SQL Server

From your laptop (while on VPN) or from the EC2 via RDP:

- **Server:** `<private_ip>,1433`
- **Auth:** SQL Server Authentication
- **Login:** `sa`
- **Password:** (whatever you set in `load-env.ps1`)

## Estimated Costs (ap-southeast-2)

| Resource                  | ~Monthly Cost |
|---------------------------|---------------|
| EC2 m5.xlarge (on-demand) | ~$280         |
| EBS gp3 100GB             | ~$12          |
| NAT Gateway               | ~$50          |
| Client VPN endpoint       | ~$75          |
| Client VPN association    | ~$150         |
| **Total**                 | **~$567/mo**  |

> **Tip:** Stop the EC2 when not in use. Consider using `t3.xlarge` (~$200/mo)
> to save costs, or schedule start/stop with EventBridge.

## Tear Down

```powershell
terraform destroy
```

This removes everything: VPC, VPN, EC2, NAT Gateway, certs, security groups.
