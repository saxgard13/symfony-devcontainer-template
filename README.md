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
- .env.local support for local configuration (add github config)
- Works out of the box with GitHub Codespaces or locally via Docker and VS Code

## File Structure

- .devcontainer/: DevContainer configuration files (Dockerfile, docker-compose, settings, setup script, .env, .en.local (create yourself))
- app/: Your Symfony project directory (you must create it)
.env modify php, nodejs and mysql version.
.env.local modify name and email github


## Requirements

- [Docker](https://www.docker.com/)
- [VS Code](https://code.visualstudio.com/) with the [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)
- [Git](https://git-scm.com/) (with name and email configured)


## Database Configuration

The MySQL service is accessible at:
- Host: db
- Port: 3306
- Username: symfony
- Password: symfony
- Database: symfony


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




## 🚀 Possible Improvements

Suggestions for enhancing this template further:


    Support for multiple PHP versions with optional Dockerfile ARGs

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
 