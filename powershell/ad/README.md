# Attention reader

This script installs an ADDS environment with DHCP and RAS fully automatically that i've made in college since i was sick of doing the same thing with "clicking" many times. 
The script works but it's by no means profesional at all.

---

# Steps before running script!!
This script requires some initial steps before hand:
- You need to make sure that you've set your computername to the desire name before you run this script
- Make sure you've added a NAT adapter and a LAN adapter in your VMware environment
  - The script assumes you've left the default names of the adapters (assuming Ethernet0 is the NAT adapter).
- The AD roles are static in the script, so if you wish to change them, change the static values. (~~I'm planning to add this to the parameter in the near future~~ its 2024 and still didn't do it...)

<br>

---

# Things i'll probably fix in the script (starting 2024)
- Make ad roles dynamic and make a param for them (ADDS,DHCP,RAS and other optional roles that wont be configured in script but are nice to install nevertheless)
- Param integrity checks
- Check vadility of said commands
- Split the configuration of given roles into functions for reusability and optimization
