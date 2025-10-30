# GoDaddy DNS Setup for ChatKit

Guide for configuring GoDaddy DNS to point your lightshift.local domain to Cloud Run services.

## Overview

After running `./deploy/setup-domain.sh`, you'll receive DNS records that need to be added to GoDaddy. This guide shows you how to configure them.

## Step 1: Get DNS Records from Cloud Run

Run the domain setup script:

```bash
./deploy/setup-domain.sh
```

This will output DNS records like:

```
Backend (chatkit-api.lightshift.local):
NAME                              TYPE  RRDATA
chatkit-api.lightshift.local.     A     216.239.32.21
chatkit-api.lightshift.local.     A     216.239.34.21
chatkit-api.lightshift.local.     A     216.239.36.21
chatkit-api.lightshift.local.     A     216.239.38.21
chatkit-api.lightshift.local.     AAAA  2001:4860:4802:32::15
chatkit-api.lightshift.local.     AAAA  2001:4860:4802:34::15
chatkit-api.lightshift.local.     AAAA  2001:4860:4802:36::15
chatkit-api.lightshift.local.     AAAA  2001:4860:4802:38::15

Frontend (chatkit.lightshift.local):
NAME                         TYPE  RRDATA
chatkit.lightshift.local.    A     216.239.32.21
chatkit.lightshift.local.    A     216.239.34.21
chatkit.lightshift.local.    A     216.239.36.21
chatkit.lightshift.local.    A     216.239.38.21
chatkit.lightshift.local.    AAAA  2001:4860:4802:32::15
chatkit.lightshift.local.    AAAA  2001:4860:4802:34::15
chatkit.lightshift.local.    AAAA  2001:4860:4802:36::15
chatkit.lightshift.local.    AAAA  2001:4860:4802:38::15
```

**Note:** The actual IP addresses will be provided by the script. Use those values, not the examples above.

## Step 2: Access GoDaddy DNS Management

1. Log in to [GoDaddy](https://www.godaddy.com/)
2. Go to **My Products**
3. Find your **lightshift.local** domain
4. Click **DNS** or **Manage DNS**

## Step 3: Add A Records for Frontend

For `chatkit.lightshift.local`:

1. Click **Add** or **Add Record**
2. Select **Type**: `A`
3. **Name/Host**: `chatkit`
4. **Value/Points to**: `216.239.32.21` (first IP from the list)
5. **TTL**: `600` (10 minutes) or `3600` (1 hour)
6. Click **Save**

Repeat for each A record IP address:
- `216.239.34.21`
- `216.239.36.21`
- `216.239.38.21`

**Result:** You should have 4 A records for `chatkit.lightshift.local`

## Step 4: Add A Records for Backend

For `chatkit-api.lightshift.local`:

1. Click **Add** or **Add Record**
2. Select **Type**: `A`
3. **Name/Host**: `chatkit-api`
4. **Value/Points to**: `216.239.32.21` (first IP from the list)
5. **TTL**: `600` or `3600`
6. Click **Save**

Repeat for each A record IP address:
- `216.239.34.21`
- `216.239.36.21`
- `216.239.38.21`

**Result:** You should have 4 A records for `chatkit-api.lightshift.local`

## Step 5: Add AAAA Records (IPv6) - Optional but Recommended

### Frontend AAAA Records

For `chatkit.lightshift.local`:

1. Click **Add** or **Add Record**
2. Select **Type**: `AAAA`
3. **Name/Host**: `chatkit`
4. **Value/Points to**: `2001:4860:4802:32::15` (first IPv6 from the list)
5. **TTL**: `600` or `3600`
6. Click **Save**

Repeat for each AAAA record:
- `2001:4860:4802:34::15`
- `2001:4860:4802:36::15`
- `2001:4860:4802:38::15`

### Backend AAAA Records

For `chatkit-api.lightshift.local`:

1. Click **Add** or **Add Record**
2. Select **Type**: `AAAA`
3. **Name/Host**: `chatkit-api`
4. **Value/Points to**: `2001:4860:4802:32::15` (first IPv6 from the list)
5. **TTL**: `600` or `3600`
6. Click **Save**

Repeat for each AAAA record:
- `2001:4860:4802:34::15`
- `2001:4860:4802:36::15`
- `2001:4860:4802:38::15`

## Step 6: Verify DNS Records in GoDaddy

Your DNS records should look like this:

```
Type  Name         Value                      TTL
A     chatkit      216.239.32.21             600
A     chatkit      216.239.34.21             600
A     chatkit      216.239.36.21             600
A     chatkit      216.239.38.21             600
AAAA  chatkit      2001:4860:4802:32::15     600
AAAA  chatkit      2001:4860:4802:34::15     600
AAAA  chatkit      2001:4860:4802:36::15     600
AAAA  chatkit      2001:4860:4802:38::15     600

A     chatkit-api  216.239.32.21             600
A     chatkit-api  216.239.34.21             600
A     chatkit-api  216.239.36.21             600
A     chatkit-api  216.239.38.21             600
AAAA  chatkit-api  2001:4860:4802:32::15     600
AAAA  chatkit-api  2001:4860:4802:34::15     600
AAAA  chatkit-api  2001:4860:4802:36::15     600
AAAA  chatkit-api  2001:4860:4802:38::15     600
```

## Step 7: Wait for DNS Propagation

- **Minimum**: 10-30 minutes (with TTL=600)
- **Typical**: 1-2 hours
- **Maximum**: Up to 48 hours

## Step 8: Verify DNS Resolution

Test DNS resolution:

```bash
# Test frontend
nslookup chatkit.lightshift.local
dig chatkit.lightshift.local

# Test backend
nslookup chatkit-api.lightshift.local
dig chatkit-api.lightshift.local

# Should return the IP addresses you configured
```

## Step 9: Test HTTPS Access

Once DNS propagates:

```bash
# Test backend health
curl https://chatkit-api.lightshift.local/health

# Should return: {"status":"healthy"}

# Test frontend health
curl https://chatkit.lightshift.local/health

# Should return: healthy
```

## Step 10: Configure ChatKit Domain Allowlist

1. Go to [OpenAI Domain Allowlist](https://platform.openai.com/settings/organization/security/domain-allowlist)
2. Add: `chatkit.lightshift.local`
3. Copy the generated domain key
4. Update `.env.deploy`:
   ```bash
   CHATKIT_DOMAIN_KEY=your-domain-key-here
   ```
5. Redeploy frontend:
   ```bash
   ./deploy/deploy-frontend.sh
   ```

## Troubleshooting

### DNS Not Resolving

**Issue:** `nslookup` returns `NXDOMAIN` or no results

**Solutions:**
1. Wait longer for propagation (up to 48 hours)
2. Verify records are saved in GoDaddy
3. Check for typos in subdomain names
4. Clear local DNS cache:
   ```bash
   # macOS
   sudo dscacheutil -flushcache; sudo killall -HUP mDNSResponder
   
   # Linux
   sudo systemd-resolve --flush-caches
   
   # Windows
   ipconfig /flushdns
   ```

### Wrong IP Addresses Returned

**Issue:** DNS returns different IPs than configured

**Solutions:**
1. Double-check GoDaddy DNS records
2. Ensure you're using the IPs from `setup-domain.sh` output
3. Wait for propagation
4. Check if there are conflicting records

### SSL Certificate Not Working

**Issue:** HTTPS shows certificate errors

**Solutions:**
1. Wait for Google to provision certificates (15-60 minutes after DNS propagation)
2. Verify DNS records are correct
3. Check certificate status:
   ```bash
   gcloud beta run domain-mappings describe \
     --domain=chatkit.lightshift.local \
     --region=us-east4 \
     --format="get(status.certificateStatus)"
   ```

### GoDaddy Doesn't Allow Multiple A Records

**Issue:** GoDaddy interface only allows one value per record

**Solutions:**
1. Some GoDaddy interfaces support multiple values separated by commas
2. Create separate A records with the same name but different values
3. Contact GoDaddy support for assistance
4. Consider using Cloud DNS instead (see alternative below)

## Alternative: Use Google Cloud DNS

If GoDaddy doesn't work well, you can use Google Cloud DNS:

```bash
# Create DNS zone
gcloud dns managed-zones create lightshift-local \
  --dns-name=lightshift.local. \
  --description="Lightshift Local Zone"

# Add records
gcloud dns record-sets transaction start --zone=lightshift-local

# Add frontend A records
gcloud dns record-sets transaction add \
  --name=chatkit.lightshift.local. \
  --type=A \
  --zone=lightshift-local \
  --ttl=300 \
  "216.239.32.21" "216.239.34.21" "216.239.36.21" "216.239.38.21"

# Add backend A records
gcloud dns record-sets transaction add \
  --name=chatkit-api.lightshift.local. \
  --type=A \
  --zone=lightshift-local \
  --ttl=300 \
  "216.239.32.21" "216.239.34.21" "216.239.36.21" "216.239.38.21"

# Execute transaction
gcloud dns record-sets transaction execute --zone=lightshift-local

# Get nameservers
gcloud dns managed-zones describe lightshift-local \
  --format="value(nameServers)"

# Update GoDaddy to use Google Cloud DNS nameservers
```

## GoDaddy-Specific Tips

1. **Use GoDaddy's "Advanced" DNS Editor** for better control
2. **Set TTL to 600** (10 minutes) initially for faster testing
3. **Increase TTL to 3600** (1 hour) once everything works
4. **Keep a backup** of your DNS records before making changes
5. **Test with Cloud Run URLs first** before configuring custom domains

## Summary

After completing these steps:

✅ DNS records configured in GoDaddy  
✅ DNS propagation complete  
✅ HTTPS working on both domains  
✅ ChatKit domain allowlist configured  
✅ Services accessible at:
- https://chatkit.lightshift.local
- https://chatkit-api.lightshift.local

## Need Help?

- [GoDaddy DNS Help](https://www.godaddy.com/help/manage-dns-680)
- [Cloud Run Custom Domains](https://cloud.google.com/run/docs/mapping-custom-domains)
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md)

---

**Last Updated:** January 2025
