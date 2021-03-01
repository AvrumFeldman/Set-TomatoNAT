# Set-TomatoNAT
Function to enable or disable NAT rules on FreshTomato routers

### About
I am automating SSL certificate renewal using acme-dns but didn't want to leave my DNS server open to the web when it didn't need to, so I created this dirty little script to enable or disables my DNS NAT rule on my FreshTomato router.


### Note:
The script is working but does require customizations per enviroment. For exmaple row 51 requires a destination address. Also, this script assumes you want to forward port 53 and so on...
