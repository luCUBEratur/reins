# Complete Remote Access Guide: Chat with Iris from Anywhere

This guide combines everything you need to securely access your Iris agent on MindWorks using the Reins iOS app, whether you're at home or on the go.

## Overview

**What you're setting up:**
- Secure VPN access to your MindWorks cluster via OPNsense
- Reins app configured to connect to Iris/Ollama
- Seamless switching between local and remote access

**Prerequisites:**
- MindWorks cluster with Iris running on Ollama
- Protectli Vault with OPNsense
- iPhone with Reins app (App Store version)
- Both guides completed:
  - [WIREGUARD_OPNSENSE_SETUP.md](./WIREGUARD_OPNSENSE_SETUP.md)
  - [FINDING_OLLAMA_ENDPOINT.md](./FINDING_OLLAMA_ENDPOINT.md)

---

## Part 1: Initial Setup Checklist

Work through these steps in order:

### Step 1: Find Your Ollama Endpoint

- [ ] Follow [FINDING_OLLAMA_ENDPOINT.md](./FINDING_OLLAMA_ENDPOINT.md)
- [ ] Document your Ollama IP: `_________________`
- [ ] Verify Iris is in model list: `curl http://<ip>:11434/api/tags`
- [ ] Full Ollama URL: `http://<ip>:11434`

### Step 2: Test Local Access First

**On your iPhone (connected to same WiFi as MindWorks):**

- [ ] Open Reins app
- [ ] Go to **Settings**
- [ ] In **Server** section, enter: `http://<your-ollama-ip>:11434`
- [ ] Tap **Connect**
- [ ] Verify green status indicator
- [ ] Create new chat
- [ ] Tap **Select a LLM Model**
- [ ] Find and select **iris** from list
- [ ] Send test message: "Hello Iris!"
- [ ] Verify response from Iris

**If this works, you're good!** Now let's set up remote access.

### Step 3: Set Up WireGuard VPN

- [ ] Follow [WIREGUARD_OPNSENSE_SETUP.md](./WIREGUARD_OPNSENSE_SETUP.md)
- [ ] Install WireGuard plugin on OPNsense
- [ ] Create WireGuard server instance (MindWorks-VPN)
- [ ] Configure firewall rules
- [ ] Set up iPhone WireGuard client
- [ ] Test VPN connection
- [ ] Verify you can access MindWorks network via VPN

### Step 4: Test Remote Access

**On your iPhone (disconnect from WiFi, use cellular):**

- [ ] Disable WiFi
- [ ] Open WireGuard app
- [ ] Enable **MindWorks** tunnel
- [ ] Verify "Active" status in WireGuard
- [ ] Open Reins app
- [ ] Chat should work the same as local!
- [ ] Send test message to Iris
- [ ] Verify response

---

## Part 2: Daily Usage Workflows

### Scenario A: At Home (Local Network)

**Simple approach - no VPN needed:**

1. **Connect to home WiFi**
2. **Open Reins app**
3. **Start chatting with Iris**
   - Server already configured: `http://192.168.1.100:11434`
   - Works directly over local network
   - Fastest performance

**No VPN overhead, best speeds!**

---

### Scenario B: Away from Home (Remote Access)

**Use VPN to securely connect:**

1. **Ensure cellular/WiFi data is enabled**
2. **Open WireGuard app**
   - Toggle **MindWorks** tunnel → **ON**
   - Wait for "Active" status
   - Check RX/TX shows data transfer
3. **Open Reins app**
   - Same configuration works automatically
   - You're now on MindWorks network via VPN
4. **Chat with Iris normally**
5. **When finished:**
   - Toggle WireGuard → **OFF** (saves battery)

**Battery tip:** Only enable VPN when chatting with Iris, disable when done.

---

### Scenario C: Switching Between Local and Remote

The beauty: **You don't need to change anything!**

**How it works:**
- Reins is configured with your MindWorks node IP: `http://192.168.1.100:11434`
- When at home: Direct connection via WiFi
- When remote: Connection routed through VPN tunnel
- Same IP works in both scenarios!

**Workflow:**
```
At home:
  WiFi → MindWorks LAN → Ollama (direct, fast)

Away:
  Cellular → VPN tunnel → MindWorks LAN → Ollama (secure, slightly slower)
```

---

## Part 3: Advanced Configuration

### Option 1: Multiple Server Profiles (Manual Switching)

If you want separate profiles for different use cases:

**Profile 1: Local (Direct)**
- Server: `http://192.168.1.100:11434`
- Use when: On home network
- Speed: Fastest

**Profile 2: Remote (via VPN)**
- Server: `http://192.168.1.100:11434` (same!)
- Use when: VPN connected
- Speed: Fast, encrypted

**Profile 3: OpenWebUI (Browser Fallback)**
- Server: `http://<openwebui-ip>:8080`
- Use when: Want web interface instead

**Note:** Current Reins app stores one server address. To switch:
1. Go to Settings → Server
2. Change address
3. Tap Connect

---

### Option 2: Optimize for Battery Life

When using VPN on iPhone:

**WireGuard Settings:**
```
PersistentKeepalive = 25     # Good default
# Lower = better battery, but may drop
# Higher = more stable, worse battery
```

**Recommended approach:**
- Enable VPN only when using Reins
- Disable VPN when done chatting
- Use "On-Demand" rules (advanced)

**On-Demand VPN Setup:**

In WireGuard app → Edit tunnel → On-Demand:
- **Enable:** On-Demand
- **Cellular:** Connect On Demand
- **WiFi:** Disconnect (or Connect based on SSID)
- **Add WiFi exceptions:** Your home WiFi SSID → Disconnect

This automatically:
- Disables VPN when on home WiFi
- Enables VPN when on cellular
- Saves you manual toggling!

---

### Option 3: Split Tunneling (Advanced)

**Default configuration:**
```
AllowedIPs = 10.10.10.0/24, 192.168.1.0/24
```

This only routes MindWorks traffic through VPN.

**Benefits:**
- Other apps use regular internet (faster)
- Only MindWorks/Iris traffic encrypted via VPN
- Better battery life
- Faster general browsing

**Full tunnel alternative:**
```
AllowedIPs = 0.0.0.0/0
```
- All traffic through VPN
- More secure but slower
- Higher battery drain

**Recommendation:** Use split tunneling (default in our guide).

---

## Part 4: Troubleshooting

### Issue: "Cannot connect to server" in Reins

**When at home (WiFi):**
- [ ] Verify you're on correct WiFi network
- [ ] Test in Safari: `http://192.168.1.100:11434`
  - Should show: "Ollama is running"
- [ ] Check MindWorks node is powered on
- [ ] Restart Ollama on node: `sudo systemctl restart ollama`

**When remote (cellular):**
- [ ] Verify WireGuard is **Active**
- [ ] Check WireGuard shows RX/TX data transfer
- [ ] Test VPN is working: `http://192.168.1.100:11434` in Safari
- [ ] Verify OPNsense WireGuard service is running
- [ ] Check firewall rules allow VPN traffic

---

### Issue: VPN won't connect

**Check public IP:**
```bash
# From home computer
curl ifconfig.me

# Verify matches WireGuard config Endpoint
```

**If IP changed:**
- Update WireGuard config on iPhone
- Or set up Dynamic DNS (see WIREGUARD guide)

**Check OPNsense:**
- Login to OPNsense web interface
- **VPN → WireGuard → Diagnostics**
- Verify service is running
- Check peer list shows your iPhone

---

### Issue: VPN connects but can't reach Ollama

**Check AllowedIPs in WireGuard:**
- Must include: `10.10.10.0/24, 192.168.1.0/24`
- Adjust `192.168.1.0/24` to your actual MindWorks subnet

**Check routing:**
- OPNsense → **VPN → WireGuard → Instances**
- Verify "Disable Routes" is **unchecked**

**Check firewall:**
- OPNsense → **Firewall → Rules → WireGuard**
- Ensure rule allows traffic to LAN

---

### Issue: Iris not in model list

**Verify Ollama has Iris:**
```bash
curl http://192.168.1.100:11434/api/tags
```

**If missing:**
```bash
# SSH into Ollama node
ssh user@192.168.1.100

# Check Ollama models
ollama list

# Pull/create Iris if needed
ollama pull iris
# OR
ollama create iris -f /path/to/Modelfile
```

**In Reins:**
- Try closing and reopening the app
- Go to Settings → Server → Disconnect → Connect
- Create new chat and try selecting model again

---

### Issue: Slow responses from Iris

**When at home:**
- Should be very fast (local network)
- If slow, check MindWorks node resources (CPU/RAM/GPU)

**When remote:**
- Slightly slower is normal (VPN overhead)
- Check your cellular/WiFi signal
- Try disconnecting and reconnecting VPN
- Check upload speed: `https://fast.com`

**Optimize VPN:**
- Use split tunneling (not full tunnel)
- Reduce PersistentKeepalive to 25 (already default)
- Consider WireGuard MTU settings (advanced)

---

## Part 5: Security Best Practices

### VPN Security

- [ ] **Never share your WireGuard private key**
- [ ] **Use strong OPNsense admin password**
- [ ] **Keep OPNsense updated:** System → Firmware → Updates
- [ ] **Limit VPN peers:** Only add trusted devices
- [ ] **Monitor connections:** Check OPNsense diagnostics regularly
- [ ] **Backup OPNsense config:** System → Configuration → Backups

### Network Security

- [ ] **Don't expose Ollama directly to internet** (use VPN instead)
- [ ] **Use firewall rules to limit access**
- [ ] **Keep MindWorks nodes updated**
- [ ] **Use strong passwords for all accounts**
- [ ] **Consider 2FA for OPNsense** (if supported)

### iPhone Security

- [ ] **Enable iPhone passcode/Face ID**
- [ ] **Keep iOS updated**
- [ ] **Keep Reins and WireGuard apps updated**
- [ ] **Don't save sensitive data in chats** (or use local-only storage)

---

## Part 6: Performance Optimization

### Reins App Settings

In Reins app:
- **Message Streaming:** Enable (faster response feel)
- **Context Window:** Adjust based on Iris config
- **Temperature:** Match Iris defaults
- **System Prompt:** Customize per chat if needed

### Ollama/Iris Optimization

On MindWorks node:

**Check Ollama is using GPU:**
```bash
# If using NVIDIA
nvidia-smi

# Should show ollama process using GPU
```

**Increase Ollama performance:**
```bash
# Edit Ollama service
sudo systemctl edit ollama

# Add:
[Service]
Environment="OLLAMA_NUM_PARALLEL=4"
Environment="OLLAMA_MAX_LOADED_MODELS=2"
```

**Iris model parameters:**
- Lower `num_ctx` = faster, less context
- Higher `num_ctx` = slower, more context
- Adjust based on needs

### Network Optimization

**For best VPN performance:**
- Use 5GHz WiFi (not 2.4GHz) when available
- Enable WiFi calling on iPhone (better reliability)
- Consider dedicated WireGuard port forwarding
- Use wired connection for OPNsense (not WiFi uplink)

---

## Part 7: Backup and Recovery

### Backup OPNsense Configuration

**Before making changes:**

1. **OPNsense → System → Configuration → Backups**
2. **Click "Download configuration"**
3. **Save to secure location**
4. **Test restore process once**

**What's backed up:**
- WireGuard configuration
- Firewall rules
- All settings

### Backup Reins Configuration

**Currently Reins stores:**
- Server address (in Settings)
- Chat history (local database)
- Model selections

**To backup:**
- Note your server URL: `http://192.168.1.100:11434`
- Export chats if app supports it
- Screenshots of important settings

### Backup WireGuard Config

**From iPhone WireGuard app:**
- Tap tunnel name
- Tap "Share" or "Export"
- Save as QR code or file
- Store securely (contains private key!)

**From OPNsense:**
- Included in OPNsense config backup
- Also note down manually in password manager

---

## Part 8: Quick Reference

### Connection Checklist

**At Home (WiFi):**
```
☑ Connected to home WiFi
☐ WireGuard (disabled)
☑ Reins app
☑ Chat with Iris
```

**Away (Remote):**
```
☑ Cellular/other WiFi enabled
☑ WireGuard tunnel ON
☑ Verify "Active" status
☑ Reins app
☑ Chat with Iris
☐ Disable WireGuard when done
```

### Key Information

```
MindWorks Configuration
-----------------------
Ollama URL:       http://192.168.1.100:11434
Ollama API Port:  11434
Iris Model:       iris:latest

VPN Configuration
-----------------
VPN Type:         WireGuard
Server Port:      51820 (UDP)
Tunnel Subnet:    10.10.10.0/24
Your VPN IP:      10.10.10.2
Endpoint:         <your-public-ip>:51820

Reins Configuration
-------------------
Server Address:   http://192.168.1.100:11434
Default Model:    iris
Streaming:        Enabled
```

### Useful Commands

```bash
# Test Ollama
curl http://192.168.1.100:11434

# List models
curl http://192.168.1.100:11434/api/tags

# Check WireGuard (on OPNsense)
wg show

# Test connectivity
ping 192.168.1.100

# Check VPN routing
traceroute 192.168.1.100
```

### Useful URLs

```
Local Access:
  Ollama:     http://192.168.1.100:11434
  OpenWebUI:  http://<openwebui-ip>:8080
  OPNsense:   https://<opnsense-ip>

Remote Access:
  Requires WireGuard VPN enabled first,
  then same URLs work
```

---

## Part 9: Common Workflows

### Workflow 1: Quick Chat Session

```
1. Open WireGuard (if remote)
2. Open Reins
3. Tap existing Iris chat
4. Send message
5. Close app when done
6. Disable WireGuard (if remote)
```

**Time:** < 30 seconds to start chatting

---

### Workflow 2: New Chat with Custom Settings

```
1. Open Reins
2. Tap "+" for new chat
3. Select "iris" model
4. (Optional) Configure:
   - System prompt
   - Temperature
   - Context size
5. Start chatting
```

---

### Workflow 3: Switching from OpenWebUI to Reins

**At home:**
```
Before: Browser → OpenWebUI → Iris
Now:    Reins → Iris
```

**Away from home:**
```
Before: Can't access
Now:    WireGuard → Reins → Iris
```

---

## Part 10: Future Enhancements

### Ideas for Improvement

**Network side:**
- [ ] Set up Dynamic DNS for stable endpoint
- [ ] Configure OPNsense HAProxy for load balancing
- [ ] Add redundancy with multiple Ollama nodes
- [ ] Set up monitoring (Grafana/Prometheus)

**App side:**
- [ ] Request Reins to add multiple server profiles
- [ ] Set up automation (Shortcuts app integration)
- [ ] Create widgets for quick access
- [ ] Explore Siri integration

**Security:**
- [ ] Implement certificate-based auth for WireGuard
- [ ] Add fail2ban on OPNsense
- [ ] Set up intrusion detection
- [ ] Regular security audits

---

## Support Resources

### Documentation
- **This repo:** All guides in `/docs`
- **OPNsense:** https://docs.opnsense.org/
- **WireGuard:** https://www.wireguard.com/
- **Ollama:** https://github.com/ollama/ollama
- **Reins:** https://github.com/Mobile-Artificial-Intelligence/reins

### Troubleshooting Order
1. Check this guide first
2. Review specific guide (WireGuard or Ollama)
3. Test individual components
4. Check logs (OPNsense, Ollama)
5. Search GitHub issues
6. Ask for help with specific error messages

### Log Locations

**OPNsense:**
- **System → Log Files → General**
- **VPN → WireGuard → Log File**

**Ollama (on node):**
```bash
sudo journalctl -u ollama -f
```

**WireGuard (on iPhone):**
- WireGuard app → Tunnel → Logs

---

## Success Criteria

You'll know everything is working when:

- [ ] ✅ Can chat with Iris at home via Reins
- [ ] ✅ Can enable WireGuard VPN when away
- [ ] ✅ Can chat with Iris remotely via Reins
- [ ] ✅ Connection is fast and stable
- [ ] ✅ Iris appears in model list
- [ ] ✅ Can switch between local/remote seamlessly
- [ ] ✅ VPN doesn't drain battery excessively
- [ ] ✅ Setup is secure and private

**Congratulations!** You now have secure, on-the-go access to Iris!

---

## Conclusion

You've successfully set up:
- ✅ Secure VPN access to MindWorks cluster
- ✅ Reins app configured to chat with Iris
- ✅ Both local and remote access workflows
- ✅ Optimized for performance and security

**Your setup:**
```
iPhone (Reins) → WireGuard VPN → OPNsense → MindWorks → Ollama → Iris
```

**Enjoy chatting with Iris from anywhere! 🚀**

---

**Part of the MindWorks remote access documentation series**

See also:
- [WIREGUARD_OPNSENSE_SETUP.md](./WIREGUARD_OPNSENSE_SETUP.md) - VPN configuration
- [FINDING_OLLAMA_ENDPOINT.md](./FINDING_OLLAMA_ENDPOINT.md) - Locating Ollama

*Last updated: 2025-10-23*
