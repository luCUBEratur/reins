# Finding Your MindWorks Ollama Endpoint

This guide will help you locate the Ollama server running Iris on your MindWorks cluster so you can configure the Reins app correctly.

## Overview

Your MindWorks cluster consists of three primary nodes. Ollama (with Iris) is running on one or more of these nodes. You need to find:
- The IP address of the node running Ollama
- The port Ollama is listening on (usually 11434)
- Verify Iris is available as a model

---

## Quick Method: If You Already Use OpenWebUI

If you're already using OpenWebUI to chat with Iris, the easiest method is to check the OpenWebUI configuration.

### Option 1: Check OpenWebUI Settings

1. **Open OpenWebUI in browser** (on your local network)
2. **Go to Settings → Connections** or **Admin Panel → Settings**
3. **Look for "Ollama API URL"** or "Base URL"
   - Example: `http://192.168.1.100:11434`
   - This is your Ollama endpoint!

### Option 2: Check OpenWebUI Docker Container

If OpenWebUI is running in Docker:

```bash
# SSH into the node running OpenWebUI
ssh user@openwebui-host

# Check the container environment variables
docker inspect open-webui | grep OLLAMA

# Look for output like:
# "OLLAMA_BASE_URL=http://192.168.1.100:11434"
```

---

## Method 1: Network Scan (From Any Computer on MindWorks Network)

### Using Nmap

If you have `nmap` installed on any computer:

```bash
# Scan your local network for Ollama's default port (11434)
nmap -p 11434 192.168.1.0/24

# Or if your network uses a different subnet:
nmap -p 11434 10.0.0.0/24
```

**Look for output like:**
```
Nmap scan report for mindworks-node1 (192.168.1.100)
PORT      STATE SERVICE
11434/tcp open  unknown
```

The IP address shown is your Ollama server!

### Using Netcat

If you don't have nmap, try netcat (usually pre-installed):

```bash
# Test each potential node IP
nc -zv 192.168.1.100 11434
nc -zv 192.168.1.101 11434
nc -zv 192.168.1.102 11434

# Successful connection shows:
# Connection to 192.168.1.100 11434 port [tcp/*] succeeded!
```

---

## Method 2: Check from OPNsense Firewall

Since your OPNsense Protectli Vault is connected to MindWorks:

1. **SSH into OPNsense**
   ```bash
   ssh root@<opnsense-ip>
   ```

2. **Scan the network**
   ```bash
   # Use nmap (if installed)
   nmap -p 11434 192.168.1.0/24

   # Or use netcat
   nc -zv 192.168.1.100 11434
   ```

3. **Check DHCP leases** (if nodes use DHCP)
   - Via Web UI: **Services → DHCPv4 → Leases**
   - Look for hostnames like "mindworks-node1", "mindworks-node2", etc.
   - Note their IP addresses

---

## Method 3: Direct Node Access

If you know the hostnames or can access the MindWorks nodes directly:

### SSH into Each Node

```bash
# SSH into first node
ssh user@mindworks-node1  # or use IP like 192.168.1.100

# Check if Ollama is running
systemctl status ollama
# OR
docker ps | grep ollama
# OR
ps aux | grep ollama

# Check if port 11434 is listening
sudo netstat -tlnp | grep 11434
# OR
sudo ss -tlnp | grep 11434

# If found, note the node's IP address
ip addr show | grep inet
```

### Quick Test for All Nodes

Create a simple script to test all three nodes:

```bash
#!/bin/bash
# save as check-ollama.sh

NODES=(
  "192.168.1.100"
  "192.168.1.101"
  "192.168.1.102"
)

for node in "${NODES[@]}"; do
  echo "Testing $node..."
  if curl -s -m 2 http://$node:11434 > /dev/null 2>&1; then
    echo "✓ Ollama found at http://$node:11434"
  else
    echo "✗ No Ollama at $node"
  fi
done
```

Run it:
```bash
chmod +x check-ollama.sh
./check-ollama.sh
```

---

## Method 4: Check from Your iPhone (When on Local Network)

If you're on the same WiFi as MindWorks:

### Using Safari

Try these URLs in Safari (replace with your network subnet):
- `http://192.168.1.100:11434`
- `http://192.168.1.101:11434`
- `http://192.168.1.102:11434`
- `http://10.0.0.100:11434`
- `http://10.0.0.101:11434`

**Success shows:** `Ollama is running`

### Using Network Analyzer Apps

Install a network scanner app from App Store:
- **Fing** (free)
- **Network Analyzer** (free)
- **Scany** (free)

1. Open the app
2. Scan your network
3. Look for devices with port 11434 open
4. Check the IP addresses

---

## Method 5: Query Your Router/DHCP Server

1. **Access your router's admin panel**
2. **Check DHCP client list** or **Connected Devices**
3. **Look for MindWorks nodes** by hostname or MAC address
4. **Note their IP addresses**
5. **Test each IP** using curl or browser

---

## Verify Ollama and Find Iris

Once you've found a potential Ollama server IP, verify it's working:

### Test 1: Check Ollama is Running

```bash
# From terminal
curl http://192.168.1.100:11434

# Should return:
# Ollama is running
```

Or visit in browser: `http://192.168.1.100:11434`

### Test 2: List Available Models

```bash
# Check if Iris is available
curl http://192.168.1.100:11434/api/tags

# Returns JSON like:
{
  "models": [
    {
      "name": "iris:latest",
      "modified_at": "2025-10-20T10:30:00Z",
      "size": 4000000000
    },
    {
      "name": "llama2:latest",
      ...
    }
  ]
}
```

Look for **"iris"** in the model list!

### Test 3: Chat with Iris (Verify Functionality)

```bash
# Send a test message to Iris
curl http://192.168.1.100:11434/api/generate -d '{
  "model": "iris",
  "prompt": "Hello Iris, this is a test",
  "stream": false
}'
```

Should return a response from Iris.

---

## Common Network Configurations

### Typical Home Network
- **Subnet:** `192.168.1.0/24`
- **Router:** `192.168.1.1`
- **OPNsense:** `192.168.1.1` (if it's your main router) or `192.168.1.x`
- **MindWorks nodes:** `192.168.1.100-102` (or similar)

### Common Private Subnets
- `192.168.0.0/24` → Test `192.168.0.100-102`
- `192.168.1.0/24` → Test `192.168.1.100-102`
- `10.0.0.0/24` → Test `10.0.0.100-102`
- `10.0.1.0/24` → Test `10.0.1.100-102`
- `172.16.0.0/24` → Test `172.16.0.100-102`

---

## Troubleshooting

### Ollama Not Found on Any Node

**Possible reasons:**
1. **Ollama is running but not exposed to network**
   - Check Ollama config: `OLLAMA_HOST=0.0.0.0:11434`
   - Default might be `127.0.0.1` (localhost only)

2. **Ollama running on non-standard port**
   - Try scanning common alternatives: 8080, 8000, 3000

3. **Firewall blocking access**
   - Check iptables/firewall on nodes
   - Temporarily disable to test: `sudo ufw allow 11434`

4. **Ollama not actually running**
   - SSH into nodes and start it:
   ```bash
   sudo systemctl start ollama
   # OR
   docker start ollama
   ```

### Found Ollama but Iris Not Listed

If `/api/tags` doesn't show Iris:

```bash
# SSH into the Ollama host
ssh user@192.168.1.100

# List installed models
ollama list

# If Iris is missing, check if you need to pull/create it
ollama pull iris
# OR if it's a custom model:
ollama create iris -f /path/to/Modelfile
```

### Multiple Ollama Instances Found

If you find Ollama on multiple nodes:
- **Check which one has Iris:** Test `/api/tags` on each
- **Use the one with Iris** (or your preferred configuration)
- **Or use a load balancer** IP if you have one set up

---

## Document Your Findings

Once you've found your Ollama endpoint, document it:

```
MindWorks Ollama Configuration
==============================
Ollama Host IP:    192.168.1.100
Ollama Port:       11434
Full URL:          http://192.168.1.100:11434
Models Available:  iris, llama2, mistral, etc.
Node Hostname:     mindworks-node1
Last Verified:     2025-10-23
```

Save this info for:
- Reins app configuration
- Future troubleshooting
- Documentation

---

## Quick Reference Commands

```bash
# Test if Ollama is accessible
curl http://192.168.1.100:11434

# List all models
curl http://192.168.1.100:11434/api/tags | jq .

# Test chat with Iris
curl http://192.168.1.100:11434/api/generate -d '{"model":"iris","prompt":"test"}'

# Scan network for Ollama
nmap -p 11434 192.168.1.0/24

# Check from iPhone Safari
http://192.168.1.100:11434
```

---

## Next Steps

Once you've found your Ollama endpoint:

1. **Test locally** (when on same network as MindWorks)
   - Open Reins app
   - Settings → Server → Enter `http://192.168.1.100:11434`
   - Click Connect → Should show green status
   - Create chat → Select Iris → Test

2. **Set up remote access**
   - Follow [WIREGUARD_OPNSENSE_SETUP.md](./WIREGUARD_OPNSENSE_SETUP.md)
   - Configure WireGuard VPN
   - Use same Ollama URL remotely

3. **Configure Reins for both scenarios**
   - See [REMOTE_ACCESS_GUIDE.md](./REMOTE_ACCESS_GUIDE.md)
   - Local vs Remote access workflows

---

## Need Help?

Common issues:
- **"Connection refused"** → Ollama not running or firewall blocking
- **"No route to host"** → Wrong IP or node offline
- **"Timeout"** → Network issue or wrong subnet
- **"Ollama is running" but no models** → Models not installed

Check the troubleshooting section or consult:
- Ollama docs: https://github.com/ollama/ollama
- Your MindWorks cluster documentation

---

**Part of the MindWorks remote access documentation series**
*Last updated: 2025-10-23*
