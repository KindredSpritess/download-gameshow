<p align="center"><a href="https://laravel.com" target="_blank"><img src="https://raw.githubusercontent.com/laravel/art/master/logo-lockup/5%20SVG/2%20CMYK/1%20Full%20Color/laravel-logolockup-cmyk-red.svg" width="400"></a></p>

## R6 Digital Template -Laravel 9.2 

This template is designed to provide a simplified solution for building and deploying new Laravel projects for R6 Digital and our clients.

The template aims to reduce the number of decisions and complexity inherent in deploying to our platform whilst staying out of your way during development.

## create your repository
---

In order to build a new Laravel project you should make a new repository in github using this template as the base.
## Getting started for local development
---
### dependencies
- <a href="https://github.com/lando/lando/releases">Lando</a> - Also available with `brew install lando`
  - Docker Desktop - Lando will add this if missing



### clone your repository

Clone your new repository to your local machine

### start the lando environment

`lando start` - This command will create a fresh environment for you to start working immediately

`docker compose up -d` - This is an alternative method of creating the containers required for local development.  May be useful for validating assumptions in the build and production pipelines


## Getting started with Staging / Production deployment
---

### Decisions
- What region will this project deploy to?
- What will the staging and production uri be?

### Process - You may only need staging to start

Legend:
 - `{{repo}}`: the name of your github repository after /r6digital/
 - `{{env}}`: the environment - likely `prod` or `staging`
 - `{{region}}`: the region shortname - likely `sgp`, `use` or `lon`
#### SSH to any node in your desired region
  - Create directories for static files
    - /data/region/{{repo}}/app/{{env}}/public
    - /data/region/{{repo}}/app/{{env}}/storage
  - Ensure these directories permissions are correct
    - chown -R 33:33 /data/region/{{repo}}
  
#### Create a Database for your deployment
  - Access phpmyadmin for your region `{{region}}.pma.r6internal.com`
    - Go to `User accounts` in the top menu
    - Go to `Add user account` near the bottom
    - The User Name should be `{{repo}}-{{env}}`
    - Create an entirely random password
    - Select `Create database with same name and grant all privileges`
    - Do not add any additional privileges

#### Create .env secrets through portainer
  - Go to <a href="portainer.r6servers.com"> portainer </a> and select <a href="https://portainer.r6servers.com/#!/1/docker/secrets"> secrets </a>
  - Select `Add Secret`
  - Name the secret `{{repo}}_app-{{env}}-env`
  - Add the required environment variables for your env - most likely this will be database credentials as a minimum

#### Create a stack through portainer
  - Go to <a href="portainer.r6servers.com"> portainer </a> and select <a href="https://portainer.r6servers.com/#!/1/docker/stacks"> stacks </a>
  - Select `Add stack`
  - Name the stack `{{repo}}` - if the stack name is changed from the repo name some further configuration should be expected
  - Under `Build Method` select `git Repository`
  - Repository URL should be `https://github.com/r6digital/{{repo}}`
  - Repository reference should be `refs/heads/master`
  - Compose path should be `docker-stack.yml`
  - Enable Authentication and add you git username and PAT
  - Do not enable Automatic Updates
  - Do not add any Environment variables
  - Do not change Access control
  - Deploy the stack

#### Configure the DNS to point to `{{region}}.lin.r6servers.com`