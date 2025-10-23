# WireGuard Setup on OPNsense for Remote Access to Iris

This guide will help you configure WireGuard on your Protectli Vault running OPNsense to securely access your Iris agent on MindWorks from anywhere.

## Overview

**What you'll accomplish:**
- Set up WireGuard VPN server on OPNsense
- Create mobile client configuration for iPhone
- Secure access to MindWorks cluster from anywhere
- Maintain end-to-end encryption

**Time required:** 15-30 minutes

---

## Prerequisites

- OPNsense running on Protectli Vault (connected to MindWorks network)
- Administrative access to OPNsense web interface
- iPhone with WireGuard app installed (App Store: [WireGuard](https://apps.apple.com/us/app/wireguard/id1441195209))
- MindWorks cluster with Ollama/Iris running

---

## Part 1: Install WireGuard Plugin on OPNsense

1. **Log in to OPNsense**
   - Open browser to your OPNsense IP (e.g., `https://192.168.1.1`)
   - Enter admin credentials

2. **Install WireGuard Plugin**
   - Navigate to: **System → Firmware → Plugins**
   - Search for: `os-wireguard`
   - Click **Install** (+ icon)
   - Wait for installation to complete

3. **Verify Installation**
   - Navigate to: **VPN → WireGuard**
   - You should see WireGuard configuration pages

---

## Part 2: Configure WireGuard Server

### Step 1: Create Server Instance

1. **Navigate to WireGuard Settings**
   - Go to: **VPN → WireGuard → Instances**
   - Click **Add** (+ icon)

2. **Configure Server Instance**
   ```
   Name:              MindWorks-VPN
   Public Key:        (auto-generated, leave blank)
   Private Key:       (auto-generated, leave blank)
   Listen Port:       51820
   Tunnel Address:    10.10.10.1/24
   Peers:             (leave empty for now)
   Disable Routes:    ☐ (unchecked)
   ```

3. **Click Save**
   - Public/Private keys will be generated automatically
   - **Important:** Copy the Public Key - you'll need it later

### Step 2: Create Firewall Rule for WireGuard

1. **Allow WireGuard Traffic**
   - Go to: **Firewall → Rules → WAN**
   - Click **Add** (+ icon at top for top of rule list)

2. **Configure Rule**
   ```
   Action:            Pass
   Interface:         WAN
   Direction:         in
   TCP/IP Version:    IPv4
   Protocol:          UDP
   Source:            any
   Destination:       WAN address
   Destination Port:  51820
   Description:       Allow WireGuard VPN
   ```

3. **Click Save** and **Apply Changes**

### Step 3: Create Firewall Rule for VPN Client Access

1. **Allow VPN Clients to Access LAN**
   - Go to: **Firewall → Rules → WireGuard** (new interface tab)
   - Click **Add**

2. **Configure Rule**
   ```
   Action:            Pass
   Interface:         WireGuard
   Direction:         in
   TCP/IP Version:    IPv4
   Protocol:          any
   Source:            WireGuard net
   Destination:       any
   Description:       Allow VPN clients to access LAN
   ```

3. **Click Save** and **Apply Changes**

---

## Part 3: Create iPhone Client Configuration

### Step 1: Add Client Peer

1. **Navigate to Peers**
   - Go to: **VPN → WireGuard → Peers**
   - Click **Add** (+ icon)

2. **Configure Peer**
   ```
   Name:              iPhone
   Public Key:        (leave blank - we'll generate on iPhone)
   Allowed IPs:       10.10.10.2/32
   Endpoint Address:  (leave blank)
   Endpoint Port:     (leave blank)
   Keepalive:         25
   Instance:          MindWorks-VPN
   ```

3. **Click Save** (but don't apply yet)

### Step 2: Generate Client Configuration

You'll need:
- **Server Public Key:** (from Step 1 above)
- **Your Public WAN IP or DDNS hostname**
- **Server Listen Port:** 51820

**On your iPhone, you'll generate the client keys**, but here's the configuration template:

```ini
[Interface]
PrivateKey = <GENERATED_ON_IPHONE>
Address = 10.10.10.2/32
DNS = 1.1.1.1

[Peer]
PublicKey = <SERVER_PUBLIC_KEY_FROM_OPNSENSE>
AllowedIPs = 10.10.10.0/24, 192.168.0.0/16
Endpoint = <YOUR_PUBLIC_IP_OR_DDNS>:51820
PersistentKeepalive = 25
```

**Important Notes:**
- `AllowedIPs = 10.10.10.0/24, 192.168.0.0/16` - Adjust `192.168.0.0/16` to match your MindWorks subnet
  - If MindWorks uses `192.168.1.0/24`, use: `10.10.10.0/24, 192.168.1.0/24`
  - If MindWorks uses `10.0.0.0/24`, use: `10.10.10.0/24, 10.0.0.0/24`

---

## Part 4: Configure iPhone WireGuard Client

### Method A: Manual Configuration (Recommended)

1. **Open WireGuard app on iPhone**
   - Tap **Add a tunnel**
   - Select **Create from scratch**

2. **Configure Interface**
   - Name: `MindWorks`
   - Tap **Generate keypair** (this creates your Private/Public key)
   - **Important:** Copy the **Public key** that was generated
   - Addresses: `10.10.10.2/32`
   - DNS servers: `1.1.1.1` (or your preferred DNS)

3. **Add Peer**
   - Tap **Add peer**
   - Public key: Paste server public key from OPNsense
   - Endpoint: `<YOUR_PUBLIC_IP>:51820`
   - Allowed IPs: `10.10.10.0/24, 192.168.1.0/24` (adjust to your subnet)
   - Persistent keepalive: `25`

4. **Save Configuration**

### Method B: QR Code Configuration

1. **Generate QR Code**
   - You can use online tools like [WireGuard Config Generator](https://www.wireguardconfig.com/)
   - Or use command line: `qrencode -t ansiutf8 < client.conf`

2. **Scan in WireGuard App**
   - Tap **Add a tunnel**
   - Select **Create from QR code**
   - Scan the generated QR code

---

## Part 5: Complete OPNsense Configuration

1. **Add iPhone Public Key to OPNsense**
   - Go back to: **VPN → WireGuard → Peers**
   - Edit the **iPhone** peer you created
   - Paste the **Public Key** from iPhone WireGuard app
   - Click **Save**

2. **Enable WireGuard Instance**
   - Go to: **VPN → WireGuard → Instances**
   - Check the **Enable** checkbox for MindWorks-VPN
   - Click **Apply**

3. **Verify Service is Running**
   - Go to: **VPN → WireGuard → Diagnostics**
   - You should see your instance listed
   - Status should show as active

---

## Part 6: Testing the Connection

### Test 1: Establish VPN Connection

1. **On iPhone:**
   - Open WireGuard app
   - Toggle the **MindWorks** tunnel ON
   - Should show "Active" with data transfer

2. **Verify Connection:**
   - Check that you see RX/TX data flowing
   - Connection should remain stable

### Test 2: Access MindWorks Network

1. **Find your MindWorks node IP** (see FINDING_OLLAMA_ENDPOINT.md)
   - Example: `192.168.1.100`

2. **Test connectivity from iPhone:**
   - Open Safari
   - Navigate to: `http://192.168.1.100:11434`
   - You should see: `Ollama is running`

### Test 3: Connect Reins to Iris

1. **Open Reins app on iPhone**
2. **Go to Settings**
3. **Server section:**
   - Enter: `http://192.168.1.100:11434` (your MindWorks node IP)
   - Tap **Connect**
   - Should show green status indicator

4. **Create or open a chat**
5. **Select Iris model**
6. **Start chatting!**

---

## Troubleshooting

### Cannot Connect to VPN

**Check OPNsense:**
```bash
# Via OPNsense shell
wg show
```
Should show your interface and peer

**Check Firewall Rules:**
- Ensure WAN rule allows UDP 51820
- Ensure WireGuard interface rule allows all traffic

**Check Public IP:**
- Verify your public IP hasn't changed
- Consider using Dynamic DNS (DynDNS, No-IP, Cloudflare)

### VPN Connects but Cannot Access MindWorks

**Check AllowedIPs:**
- Ensure iPhone config includes your MindWorks subnet
- Example: `10.10.10.0/24, 192.168.1.0/24`

**Check Routing:**
- In OPNsense: **VPN → WireGuard → Instances**
- Ensure "Disable Routes" is **unchecked**

**Check LAN Firewall:**
- Go to: **Firewall → Rules → WireGuard**
- Ensure rule allows traffic to LAN

### Iris Not Appearing in Model List

**Verify Ollama is accessible:**
```bash
# From iPhone Safari (while VPN connected)
http://<mindworks-ip>:11434/api/tags
```
Should return JSON with model list including Iris

**Check Reins settings:**
- Ensure server address is correct
- Try disconnecting and reconnecting

---

## Security Best Practices

1. **Use Strong Keys:**
   - Never share your private keys
   - WireGuard generates strong keys automatically

2. **Limit Access:**
   - Only add trusted devices as peers
   - Use unique IPs for each peer (10.10.10.2, 10.10.10.3, etc.)

3. **Monitor Connections:**
   - Regularly check: **VPN → WireGuard → Diagnostics**
   - Review connected peers

4. **Update Regularly:**
   - Keep OPNsense updated: **System → Firmware → Updates**
   - Keep WireGuard plugin updated

5. **Backup Configuration:**
   - **System → Configuration → Backups**
   - Download backup before making changes

---

## Dynamic DNS Setup (Optional but Recommended)

If your ISP changes your public IP, you'll need to update your iPhone config each time. Dynamic DNS solves this.

### Using Cloudflare (Free)

1. **In OPNsense:**
   - Go to: **Services → Dynamic DNS → Settings**
   - Click **Add**

2. **Configure:**
   ```
   Service:       Cloudflare
   Username:      <your-cloudflare-email>
   Password:      <cloudflare-api-token>
   Hostname:      mindworks.yourdomain.com
   ```

3. **In iPhone WireGuard config:**
   - Change Endpoint from IP to: `mindworks.yourdomain.com:51820`

---

## Performance Optimization

### Reduce Battery Drain

In iPhone WireGuard config:
- Use `PersistentKeepalive = 25` (current setting is good)
- Enable "On-Demand" activation

### Improve Speed

In OPNsense:
- **VPN → WireGuard → Instances**
- Advanced settings:
  - MTU: `1420` (default, works well)
  - Disable unnecessary firewall logging

---

## Alternative: Split Tunneling

If you only want MindWorks traffic through VPN (not all traffic):

**In iPhone WireGuard config:**
- Change `AllowedIPs` from `0.0.0.0/0` to:
  ```
  AllowedIPs = 10.10.10.0/24, 192.168.1.0/24
  ```
  (Only routes VPN subnet and MindWorks LAN)

**Benefit:** Faster general browsing, only MindWorks traffic uses VPN

---

## Quick Reference Card

### Connection Steps
1. Open WireGuard app → Enable MindWorks tunnel
2. Open Reins app → Already configured
3. Chat with Iris!

### Server Details
- **VPN Tunnel:** `10.10.10.1/24`
- **Your VPN IP:** `10.10.10.2`
- **MindWorks Ollama:** `http://192.168.1.100:11434` (update with your IP)
- **WAN Port:** `51820 UDP`

---

## Next Steps

1. Complete WireGuard setup using this guide
2. Follow [FINDING_OLLAMA_ENDPOINT.md](./FINDING_OLLAMA_ENDPOINT.md) to locate your Iris endpoint
3. Follow [REMOTE_ACCESS_GUIDE.md](./REMOTE_ACCESS_GUIDE.md) for complete Reins configuration

---

## Questions or Issues?

- OPNsense Documentation: https://docs.opnsense.org/manual/how-tos/wireguard-client.html
- WireGuard Documentation: https://www.wireguard.com/
- Reins GitHub Issues: https://github.com/Mobile-Artificial-Intelligence/reins/issues

---

**Created for MindWorks cluster remote access**
*Last updated: 2025-10-23*
