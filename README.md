# Symfony DevContainer Template

This repository provides a ready-to-use development environment for Symfony using DevContainers, ideal for consistent local setups and onboarding.

## Features

- PHP with essential extensions
- Composer
- Symfony CLI
- MySQL (with preconfigured environment)
- Node.js (for assets, Encore, etc.)
- PHP-CS-Fixer preconfigured with PSR-12 rules ()  
👉  You will need to install php-cs-fixer via composer once symfony is installed, and add a configuration file to the root of the app/ .
- Xdebug, Intelephense, Docblocker, and other useful VS Code extensions  
- Works out of the box with GitHub Codespaces or locally via Docker and VS Code

## Files Structure

- .devcontainer/: DevContainer configuration files (Dockerfile, docker-compose, settings, setup script, .env, .en.local (create yourself))
- app/: Your Symfony project directory (you must create it)
- `.devcontainer/.env` file configures the PHP and Node.js versions, the backend container image name, the ports used, and the project name to avoid conflicts with database names.
- `.devcontainer/.env.local` file modify name and email github
- `setup.sh` script initializes the development environment by optionally cleaning VS Code server extensions cache, displaying versions of PHP, Symfony, Composer, Node, and npm. It also loads environment variables from `.env.local` and configures Git user name and email if provided.
- The `ini.sh` script checks if the external Docker network named `devcontainer-network` exists, and creates it if it does not. This shared network allows multiple containers (e.g., a Symfony API and a React frontend) to communicate with each other within the development environment.


## Requirements

- [Docker](https://www.docker.com/)
- [VS Code](https://code.visualstudio.com/) with the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- [Git](https://git-scm.com/) (with name and email configured)
- [Symfony CLI](https://symfony.com/download) (Required to run the Symfony local server with HTTPS support, manage TLS certificates, and streamline development.)



## Database Configuration

- Host: db
- Mysql Port: 3306
- Postgre Port: 5432
- Username: symfony
- Password: symfony
- Database: <project_name>_db
This ensures consistency and avoids conflicts between projects. The `<project_name>` value is defined in the `.env` file (via the `PROJECT_NAME` variable).

## How to Switch the Database Engine

To change the database engine used by the project (e.g., from MySQL to PostgreSQL or MariaDB), you need to update a few configurations:

**Modify dockerComposeFile in devcontainer.json:**

Replace the default database compose file to the one matching your chosen database engine. For example, to use PostgreSQL instead of MySQL or MariaDB:


```
"dockerComposeFile": [
  "docker-compose.yml",
  "docker-compose.postgre.yml"
],
```

**Update the DATABASE_URL environment variable in your Docker Compose file:**

Change the connection URL to reflect the selected database engine, user credentials, port, and server version. Examples:

MySQL or MariaDB:

```
DATABASE_URL: mysql://symfony:symfony@db:3306/${PROJECT_NAME}_db?serverVersion=${SERVER_VERSION}
```   

PostgreSQL:

```
DATABASE_URL: pgsql://symfony:symfony@db:5432/${PROJECT_NAME}_db
```

Note: For PostgreSQL, the serverVersion parameter is not required and can be omitted.

**Set the appropriate variables in your .env file:**

Make sure you set the corresponding variables for your database engine, image, and version. For example:

```
DB_IMAGE=postgres:16
SERVER_VERSION=   # Leave empty for PostgreSQL
```

Or for MySQL:

```
DB_IMAGE=mysql:8.3
SERVER_VERSION=8.3
```

Or for MariaDB:

```
DB_IMAGE=mariadb:10.11
SERVER_VERSION=mariadb-10.11
```

By following these steps, you can easily switch between MySQL, MariaDB, and PostgreSQL in your development environment.


## Credentials Security in This Devcontainer

The database credentials provided in this template are generic values intended for local development only.

They should never be used in production or exposed in any publicly accessible environment.

To customize these values, it is recommended to use environment variables or a local (untracked) .env file, which you can configure according to your needs.

This devcontainer is designed to run in an isolated environment and does not expose databases externally, minimizing security risks.


## 🔧 How to use

This DevContainer template can be used in two different ways, depending on your project organization preferences.


### Option 1 : Single Repository: DevContainer + Symfony App in One Git Repo


This approach keeps both the DevContainer setup and the Symfony application in the same Git repository. It is useful when:

    You want to version your full development environment alongside your Symfony app.
    You may want to customize PHP, Node.js, or other container settings per project.

**Steps:**

- Click "Use this template" on GitHub to create a new repository based on this template.
- Clone your new repository locally:

```
git clone git@github.com:your-username/your-new-project.git
```
- Open the project in VS Code with the Dev Container support.
- Not yet : Reopen in container when prompted
- Create app folder
- Create .env.local with your github config (name and email)
- Open the DevContainer via the blue button at the bottom left of your VS Code (the container will open in the app folder) 
- If prompted with:

    “A Git repository was found in the parent folders. Would you like to open it?”
    👉 Choose “Yes” to use the main repository, not a nested one.    
- Install Symfony in this app/ folder from the VS Code terminal

```
symfony new . --version="7.2.*"
```
or with web stack
```
symfony new . --version="7.2.*" --webapp
```

- Symfony will initialize a .git repo — delete it. Inside the container (you should already be located in the `app/` folder), run:
```
rm -rf .git
```
- Your first commit 
```
git add .
git commit -m "your message"
git push
```

This prevents Git conflicts and ensures that the root repository controls the whole project.

✅ Git will still respect Symfony’s .gitignore file


### Option 2  : Separate Repositories: Symfony App Only

Recommended if you want to reuse this template across projects and version only your Symfony code.

**Steps:**

- Clone this template or download manually:

```
git clone git@github.com:your-username/symfony-devcontainer-template.git
```

- Copy .devcontainer/, .gitignore, .env, README.md into your Symfony project folder.
- Create app/ and .env.local with your github config (name and email)
- Open the DevContainer via the blue button at the bottom left of your VS Code (VS Code will open in app/) 
- If prompted with:

    “A Git repository was found in the parent folders. Would you like to open it?”
    ❌ Choose “No” (but this shouldn’t happen if .git isn’t present).  
- Install Symfony in this app/ from the VS Code terminal
```
symfony new . --version="7.2.*"
```
or with web stack
```
symfony new . --version="7.2.*" --webapp
```
Note: You usually don't need to run `git init` — Symfony automatically creates a `.git` folder during installation. Just ensure you're not ending up with nested Git repositories.

- Initialize your own Git repo:

```
git remote add origin git@github.com:your-username/your-repo.git
git add .
git commit -m "Initial commit"
git push -u origin main
```
✅ From this point, you can use `git add .`, `git commit`, and `git push` from inside the `app/` folder as usual.


## Symfony Local Web Server

This project uses the [Symfony CLI](https://symfony.com/download) to run the local web server for development.

To access the application in your browser with HTTPS support:

**Install Symfony CLI on your host machine**  
This is required to enable TLS support and trusted HTTPS connections.  
➜ Run `sudo symfony server:ca:install` **on the host**, not in the container.

**Start the server inside the container**  
From the DevContainer terminal, run:  
```bash
symfony server:start --listen-ip=0.0.0.0
```

without https :

```bash
symfony server:start --allow-http --no-tls --listen-ip=0.0.0.0
```

- --allow-http disables the HTTPS enforcement (useful if TLS is not configured).
- --no-tls starts the server without HTTPS (you can omit this if TLS is installed).
- --listen-ip=0.0.0.0 makes the server accessible from the host (not just inside the container).



## 🚀 Possible Improvements

Suggestions for enhancing this template further:

    Optional Redis, PostgreSQL, or RabbitMQ containers

    GitHub Actions CI/CD pipeline example (lint, test, build)
    
    Makefile for common development commands (make build, make lint, etc.)

    Provide devcontainer.json features for faster onboarding

    Allow custom project scaffolding (e.g., symfony new options passed as arguments)

    Add support for PostgreSQL as an alternative to MySQL

    Include a Makefile for common commands (build, test, lint, etc.)


Credits

Created by saxgard13

Let me know if you want a French version, badges, images, or a GitHub Actions section added too.
 