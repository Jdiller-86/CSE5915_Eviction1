```markdown
# Developer Manual

## Introduction

This Developer’s Manual provides future developers with essential documentation to understand, modify, and maintain the Eviction Mediation Platform. This document outlines the system architecture, installation procedures, and key source files to ensure continuity in development. Also, it includes best practices for testing and debugging and anticipated improvements for future iterations. By using this guide, developers can efficiently contribute to the project’s success.

## Environment Set Up

### Required Software & Tools

To develop and run the Eviction1 Ruby on Rails application, the following software and tools are required:

#### Operating Systems

*   Windows 10/11 (with Windows Subsystem for Linux – WSL/Ubuntu)
    
*   macOS (M1 or later recommended)
    

#### Development Tools

*   Visual Studio Code (Extensions: WSL, SQL Server)
    
*   Ruby 3.4.1
    
*   Rails 7.x
    
*   Bundler
    
*   Git
    
*   Node.js (for npm and frontend assets)
    

#### Database

*   Microsoft SQL Server
    
    *   Windows: SQL Server Developer Edition
        
    *   macOS: Dockerized SQL Server (Azure SQL Edge)
        

#### Additional Tools

*   Docker (for macOS)
    
*   MS SQL CLI
    
*   Azure Data Studio (optional, for database management)
    

## Installation Instructions

### Windows 10

#### 1\. Install WSL & Ubuntu

Follow the [GoRails Windows 10 setup,](https://gorails.com/setup/windows) including the Rails installation. **Do not follow the database installation steps.**

#### 2\. Setup Visual Studio Code

a. Install WSL extension and SQL Server extensions.

b. Open a new VS Code window with “code .” from the WSL terminal.

#### 3\. Set Up Git & Permissions

a. Run the following in WSL or Ubuntu terminal:

```sh
sudo mount -t drvfs D: /mnt/d -o metadata
sudo umount /mnt/d
wsl --shutdown

```

Reminder: Replace `D:` with your drive letter.

b. Navigate to the desired folder and run:

```sh
git clone <ssh link to repository>

```

Potential Problem: If you encounter an error when trying to clone the repository like:

```sh
error: chmod on /mnt/d/eviction1/CSE5915_Eviction1/.git/config.lock failed: Operation not permitted
fatal: could not set 'core.filemode' to 'false'

```

Solution:

Run:

```sh
sudo mount -t drvfs D: /mnt/d -o metadata
sudo umount /mnt/d

```

The above was an issue with my D: drive not having proper permissions to interact with the linux subsystem, so replace the "D:" and two "d" with the drive you installed it on. Changes won't take effect until you do the wsl shut down below.

Open Windows PowerShell and run:

```sh
wsl --shutdown

```

Finally, retry the Git Clone Command.

#### 4\. Install Required Gems

a. In WSL or Ubuntu terminal run:

```sh
sudo apt-get --assume-yes update
curl -sSL https://rvm.io/pkuczynski.asc | gpg --import -
\curl -sSL https://get.rvm.io/ | bash -s stable

*ENSURE YOU RUN THE COMMAND SPECIFIED IN THE RECENT OUTPUT TO CONSOLE, THEN PROCEED BELOW*

rvm install "ruby-3.4.1"
sudo apt-get --assume-yes 
install freetds-dev freetds-bin
bundle install

```

#### 5\. Install SQL Server

a. Download and install Microsoft SQL Server Developer Edition.

#### 6\. Configure SQL Server

a. Enable TCP/IP in SQL Server Configuration Manager.

b. Set the port to 1433 and update database.yml to the specified configuration settings.

#### 7\. Firewall Settings

a. You may need to open PowerShell as ADMIN and run:

```sh
New-NetFirewallRule -DisplayName "Allow SQL Server from WSL" -Direction Inbound -Protocol TCP -LocalPort 1433 -Action Allow

```

#### 8\. Initialize Database

a. To make sure you can initialize properly, run the following in terminal:

```sh
rails db:create
rails db:drop

```

b. Now add proper dependencies for SQL Server:

```sh
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
sudo add-apt-repository "$(curl -fsSL https://packages.microsoft.com/config/ubuntu/20.04/prod.list)"
sudo apt update
sudo apt install mssql-tools unixodbc-dev -y
Accept the terms, then:
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
source ~/.bashrc

```

c. Ensure SQL Browser service is installed and running: i. In Powershell, run:

```sh
Get-Service -Name SQLBrowser

```

ii. It should return the SQLBrowser and it's status. If it's stopped run:

```sh
Start-Service -Name SQLBrowser

```

iii. If it doesn't let you start it, do the following: open run (windows key + r), type services.msc and hit enter. iv. Then scroll down and find SQL Service Browser, right-click, go to properties, change Startup Type to Manual, and then start then click start and make sure it's running.

d. Check for connection to the DB using the following command (Replace IP, username, password with your setups details) in wsl/ubuntu terminal:

```sh
sqlcmd -S 172.21.176.1 -U sa -P changeme

```

It should show the following if you successfully connected:

```sh
1>

```

Then you'll want to check if you have a DB. From the 1>, type the following:

```sh
1> SELECT name FROM sys.databases;
2> GO
hit enter, if database name is already present then skip this next part about creating DB, otherwise:
BEGIN creating db
type the following (REPLACE EVICTION_TEST with your db name):
1> CREATE DATABASE EVICTION_TEST;
2> GO
hit enter
END creating db
then type the following (REPLACE EVICTION_TEST with your db name):
1> USE EVICTION_TEST;
2> GO

```

Hit enter.

Alter permission to your user, in this case it's user sa:

```sh
1> ALTER AUTHORIZATION ON DATABASE::EVICTION_TEST TO sa;
2> GO

```

Hit enter.

Then, input this again:

```sh
1> USE EVICTION_TEST;
2> GO

```

Hit enter.

e. Then run the following command to initialize from “DBInitTest.sql” file (replace username, password, ip and db name as needed):

```sh
sqlcmd -S 172.21.176.1 -U sa -P changeme -d EVICTION_TEST -i "DBInitTest.sql"

```

f. Run the needed migrations:

```sh
rails db:migrate

```

### macOS (M1)

#### 1\. Install Prerequisites

a. Install **Homebrew**

```sh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install docker

```

b. Install **Docker** for Mac with Apple Silicon: [Docker Setup for Mac](https://docs.docker.com/desktop/setup/install/mac-install/)

c. Follow [GoRails macOS 14 Setup](https://gorails.com/setup/macos/14-sonoma) to install **Ruby on Rails**

i. Click on the linked tutorial and follow the instructions according to your macOS).

ii. Follow instructions UP TO AND including rails installation, DO NOT follow db installation.

#### 2\. Run MS SQL Server in Docker

a. Use this link as a guide on [Setting Up A Local SQL Server on a Mac](https://medium.com/@aleksej.gudkov/how-to-set-up-a-local-sql-server-on-an-m1-mac-88d0ff0fed4c)

b. Start the SQL Server Container:

```sh
docker run mcr.microsoft.com/azure-sql-edge
docker run -p 1433:1433 mcr.microsoft.com/azure-sql-edge
docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=StrongPassword1" -p 1433:1433 -d mcr.microsoft.com/azure-sql-edge docker ps
docker ps

```

#### 3\. Run in the VS Code Terminal

a. Clone your Git repository.

b. Update database.yml to specfic configurations.

c. Run the following:

```sh
bundle install
ruby ./bin/rails server

```

d. Now, you can run the code, and the database has been initialized in the container, but not locally on your machine.

#### 4\. Initialize Database

a. Create a folder on your local machine, preferably in the same directory that you cloned the git repository. (e.g. filename: SQLData)

b. Open **Docker** Terminal and run:

```sh
docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=StrongPassword1" -p 1433:1433 -v ./SQLData:/var/opt/mssql --name sqlserver -d --rm mcr.microsoft.com/azure-sql-edge

```

i. This is to save the db to your local machine: -v ./SQLData:/var/opt/mssql

ii. Name your container to sqlserver: --name sqlserver

iii. Add --rm so that it will remove unused container when you stop it: -d --rm mcr.microsoft.com/azure-sql-edge

c. On VSCode, run:

```sh
ruby ./bin/rails server

```

d. Every time you run docker use this command:

```sh
docker run -e "ACCEPT_EULA=Y" -e "MSSQL_SA_PASSWORD=StrongPassword1" -p 1433:1433 -v ./SQLData:/var/opt/mssql --name sqlserver -d --rm mcr.microsoft.com/azure-sql-edge

```

e. Download [MS Azure Data Studio](https://builtin.com/software-engineering-perspectives/sql-server-management-studio-mac)

f. Install **MS SQL CLI**

i. Download [npm](https://nodejs.org/en/download/)

ii. Run on the terminal to install and test installation:

```sh
$ npm install -g sql-cli 

OR

$ sudo npm install -g sql-cli
$ mssql -u sa -p

```

g. Install GUI application – [Azure Data Studio](https://learn.microsoft.com/en-us/azure-data-studio/download-azure-data-studio?view=sql-server-ver15&viewFallbackFrom=sql-server-ver15%5D&tabs=win-install%2Cwin-user-install%2Credhat-install%2Cwindows-uninstall%2Credhat-uninstall)

i. Add necessary credentials once installed. Click connect.

h. Initialize DB using DBinit file.

## Version Numbers & Configuration Settings

### Software Versions

*   **Ruby**: 3.4.1
    
*   **Rails**: 7.x
    
*   **SQL Server**: Developer Edition (Windows) / Azure SQL Edge (macOS)
    
*   **Node.js**: Latest LTS
    
*   **Docker**: Latest stable
    

### Configuration Settings

a. config/database.yml: (modify to your specific setup, host ip, database, username, password)

```yaml
development:
  adapter: sqlserver
  host: '127.0.0.1'
  port: 1433
  database: EVICTION_TEST
  username: 'sa'
  password: 'StrongPassword1'
  trust_server_certificate: true
  timeout: 5000

```

b. freetds.conf: (modify to your specific sqlserver name, host ip.)

```conf
[EVICTION_TEST]
    host = 127.0.0.1
    port = 1433
    tds version = 7.4

```

### SQL Server Configurations

*   **TCP/IP**: Enabled
    
*   **Port**: 1433
    
*   **Firewall Rule**: Allow Inbound TCP 1433
    

### Email Configurations

a. Config/environments/development.rb (For development) and Config/environments/production.rb (for production):

```rb
config.action_mailer.delivery_method = :smtp

  # Configuring smpt settings, will need changed to proper MSA.
  config.action_mailer.smtp_settings = {
    address: "smtp.gmail.com",
    port: 587,
    domain: "gmail.com",
    authentication: "plain",
    enable_starttls_auto: true,
    user_name: ENV["GMAIL_USERNAME"], # Use environment variables for security
    password: ENV["GMAIL_PASSWORD"]   # Use environment variables for security
  }

  # Show error if mailer can't send
  config.action_mailer.raise_delivery_errors = true

  # Make template changes take effect immediately.
  config.action_mailer.perform_caching = false

  # Mailer performs deliveries
  config.action_mailer.perform_deliveries = true

```

Note: You can change ENV\[\] values in the .env file (like Gmail user & pass).

## Source File Locations & Overview

### 1\. Directory Structure

a. Our project uses the standard Ruby on Rails directory structure. Some key notes are:

*   The app folder, which contains the main application logic (the MVC components)
    
*   The config folder, which manages some application settings (database connection and routes file)
    
*   The db folder which contains the db migrations and schema file (though these are less useful in that our database is external.
    

### 2\. Key Source Files & Functions

*   As an MVC application, the model, controller, and view files (and the functions contained within) are obviously quite important.
    
*   Beyond this, another important file is Routes.rb, which lays out the routes that connect our views.
    
*   Lastly, schema.rb and database.yml; while schema.rb is typically very important, it is less important in this project as we use an external database (though schema.rb is kept in line with this database). Building on this, database.yml serves to connect our project to our external MS SQL Server database. This is explained in more detail in the environment setup.
    

### 3\. Configuration Files & Roles

*   Database.yml serves to connect the local DB and the rails application, allowing for the system to function properly
    
*   Schema.rb is kept in line with our local DB, this allows us to leverage rails’ innate strengths and MVC structure properly.
    

## Running the Application

### Starting the Server

To start the server simply run “rails s or rails server” in your rails command line interface. There should be a brief message confirming the server is online and if working in VSCode you should be prompted to view the application in your browser. If not prompted the server can be accessed at localhost:3000.

### Navigating the Application

The various pages can be navigated via the bar on the top of the page:

<table><tbody><tr><th><p>Home</p></th><th><p>Messages</p></th><th><p>Documents</p></th><th><p>Account</p></th></tr></tbody></table>

Different account types will have access to different pages in the application. For example, a landlord account type can have multiple mediations going at the same time while a tenant can only have one active mediation at a time. **More details will be added for the different account types as functionality is implemented, i.e. admins.**

## Test Suite & Manual Tests

### Automated Tests

Rails utilizes **Continuous Integration Tests** that automatically scan the codebase for any known ruby and JavaScript vulnerabilities. Additionally, the CI tests also utilize lint to scan for consistent styling. CI tests can be configured by modifying the CI.yml file located in the .github folder in the repository.

### Running the Tests Suite

Rails provides its own testing framework for developing test cases. Under the test folder in the repository, you can view all the current tests for the various components. When executing test cases run “rails test” in the ruby CLI and all files in the test folder will automatically execute and ruby will report on the number of assertions, failures and errors. To run a specific subcategory of tests, for example controllers, execute “rails test:controllers” replacing controllers with the relevant section you wish to test.

### Manual Tests

By running the test suite above you will be running all cases developed for the project thus far. To further develop test cases, you can reference the link below to help you get started:

[Testing Rails Applications — Ruby on Rails Guides](https://guides.rubyonrails.org/testing.html)

## Unique Aspects & Known Issues

### Unique Features

The primary unique feature of our application is our use of Microsoft SQL Server with ruby on rails. This is an unorthodox pairing and can lead to technical difficulties during setup.

### Common Issues

No specific common issues to document as of the time of writing, this will be updated as new issues arise that fit into this category. For issues relating to the SQL Server setup, all known issues relating to the SQL Server setup have already been addressed in the latest iteration of the setup instructions. Any issues not mentioned there have either not been solved by us or we have not encountered them yet.

### Troubleshooting Development Issues

One member's Windows 11 device is still unable to connect to a local instance of SQL Server, this is at of the time of writing still unresolved and we do not currently have a solution. Whenever a solution is discovered, it will be added to this section.

## Next Steps for Development

### Feature Roadmap

**1.	Production Deployment**

•	Plan for deployment to production over the summer.

•	Conduct security compliance validation to meet the state’s security requirements.

•	Enable Admins to collect data on user engagement.

•	Establish a process for collecting user feedback.

**2.	Language and Translation**

•	Implement translation features beyond the current flagging system for Admin review.

**3.	Authentication & Accessibility**

•	Username and Authentication Considerations

•	Using a phone number as username would improve accessibility.

•	However, authentication currently relies on email relay, so email remains the most practical option for now.

•	Landlord verification: Method to verify the landlord of the property.

**4.	Accessibility Enhancements**

•	Explore text-to-speech functionality.

•	Improve screen reader compatibility.

**5.	Legal Considerations**

•	Integrating educational and other resources directly within the app (and potentially in collaboration with Eviction 2) especially for users who do not reach an agreement.

•	Expanding the kinds of agreements that can be entered into and enhancing customizability of individual provisions of agreements.

•	Integrating a tool like LLMediator that is able to flag parties’ language in real time and suggest less adversarial language.

•	Providing a space for parties to vent more freely before mediation (adding more flexibility to the text-communication medium).

### Anticipated Next Steps
1.	Finalize security and legal compliance measures.
2.	Assess the feasibility of phone number-based usernames while maintaining email authentication.
3.	Expand accessibility features for broader user inclusivity.
4.	Improve translation support for multilingual users.
5.	Gather and analyze user feedback to guide future updates.

### Suggestions for Future Improvements
1.	Enhance production monitoring and analytics.
2.	Optimize user onboarding and authentication experience.
3.	Expand accessibility and localization efforts.
4.	Implement additional security features as per evolving compliance needs.

## Appendices
```