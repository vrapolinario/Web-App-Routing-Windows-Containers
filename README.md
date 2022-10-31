# Web Application Routing with Windows containers

This repo is a companion for the #1 blog post on a blog series - 5 Tips for containerizing IIS apps on Windows containers. The first blog post is focused on SSL certificate lifecycle management and in this repo I show how to use Web Application Routing for Windows containers.

## How to use

To get stareted, run the CreateAKSWebAppRouting.ps1 script. You can run it from:
- Azure Cloud Shell.
  - In this case, you can run the script as-is.
- You can also run it from any PowerShell session. In this case, you'll need to change:
  -	Uncomment the line #5 to properly log in to Azure from PowerShell.
  - Install OpenSSL on your machine to generate the SSL Certificate to be used.

For questions, comments, and feedback, feel free to reach out to me:

- [E-mail](mailto:viniap@microsoft)
- [Twitter](https://www.twitter.com/vrapolinario)
