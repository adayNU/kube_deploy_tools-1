
# Releasing

## Prerequisites
Ensure that your Jenkins build is set up according to
[documentation/setup.md](setup.md).

For building, tagging, and pushing your Docker images, as well as
rendering, pushing, and deploying your Kubernetes manifests, see below.

## Jenkins build

Your project's Jenkins build is responsible for the following:

- building and tagging your Docker images
- pushing your Docker images
- rendering your Kubernetes manifests
- pushing your deploy artifacts containg your Kubernetes manifests

This translates to:

- running `docker build . -t local-registry/<container>` for all containers in
your project
- running `bundle exec kdt publish_container <container> --target=aws` for all
containers in your project
- running `bundle exec kdt render_deploys`
- uploading the deploy artifacts to Artifactory, as described in
[documentation/setup.md](setup.md).

This results in the following:

- all Docker images tagged and pushed at a well-known tag
- all Kubernetes manifests referencing the same Docker images at the same
well-known tag in a single deploy artifact

## Releasing a deploy artifact from Jenkins

To release the deploy artifact from your Jenkins build:

```bash
# Ensure that you have the same version of kube_deploy_tools in Gemfile.lock
bundle install

bundle exec kdt deploy \
  --target <target in deploy.yml> \
  --environment <environment in deploy.yml> \
  --project <project name of build in Jenkins> \
  --build <number of build in Jenkins> \
  --dry-run false
```

For example, to release [OpsRepos/kube-infra](https://git.***REMOVED***/OpsRepos/kube-infra)
to the AWS staging cluster:
```bash

bundle exec kdt deploy \
  --target us-east-1 \
  --environment staging \
  --project kube_infra_master \
  --build 1234 \
  --dry-run false
```

See `bundle exec kdt deploy --help` for a description of all flags.

## Releasing manually

```bash
bundle install

# Build and tag all containers in your project
# Run |bundle exec kdt publish_container| for all containers in your project

bundle exec kdt render_deploys

bundle exec kdt deploy \
  --context <Kubernetes context> \
  --from-files build/kubernetes/... \
  --dry-run false
```

## Releasing a deploy artifact from Jenkins with Pentagon on Rampmaster

Add a Capfile for your project to [MasterRepos/pentagon](https://git.***REMOVED***/MasterRepos/pentagon).
```ruby
# pentagon:cap3
set :application, "arbor_admin"
set :project, "arbor_admin"
set :repo_url, 'git@git.***REMOVED***:RailsRepos/arbor_admin.git'
load(File.expand_path("../lib/cap/kube_deploy.rb", File.dirname(__FILE__)))
```

An example of the deploy command:

```bash
please deploy target=colo-service environment=staging build=61
```
