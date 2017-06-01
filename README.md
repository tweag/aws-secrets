aws-secrets
===========
Manage secrets on AWS instances with KMS encryption, IAM roles and S3 storage.

This fork of `aws-secrets` supports multiple applications grouped together with a base name such as 'my_apps', and supports multiple environments per application, all stored using the same KMS key and in the same S3 bucket.

The base name, env, and app name can all be specified in the command line arguments, or by environment variables (see below for examples).

It also sets up and uses S3 file versioning for the secret files. This allows the scripts to safely overwrite secrets files with updated files by keeping the history of all prior versions.
The scripts allow an application to retrieve and use a specific version of a secrets file, or defaults to the latest.

Synopsis
========

aws-secrets requires [aws-cli](https://aws.amazon.com/cli/) version 1.8 or later.

Installation:
```
git clone -o github https://github.com/prx/aws-secrets
cd aws-secrets
make install
# (or just copy `bin/*` to somewhere in your PATH)
```

Set up AWS resources with a base name `my_apps` for grouping them using `aws-secrets-init-resources`:

```
# Usage: aws-secrets-init-resources <?base>

aws-secrets-init-resources my_apps

# or set the AWS_SECRETS_BASE instead of app cmd line argument

export AWS_SECRETS_BASE=my_apps
aws-secrets-init-resources
```

Make some secrets, send them to the cloud and the AWS S3 bucket using `aws-secrets-send`:

```
# Usage: aws-secrets-send <app> <?filename|.env> <?env|development> <?base|app>

echo "SECRET=xyzzy" > quizzo-secrets
aws-secrets-send quizzo quizzo-secrets staging my_apps

# or specify using env variables instead
export APP_ENV=staging
export AWS_SECRETS_BASE=my_apps

aws-secrets-send quizzo quizzo-secrets
> {"versionId": "f1l3v3rs10ngu1D"}
```

Each `aws-secrets-send` run overwrites the existing secrets in the store for that app, env, and base, but because the bucket tracks the file versions, it is safe, and a prior version can be used by a currently running application to prevent side effects.

`aws-secrets-send` returns the version-id in json to use in the get script, or you can set version-id as 'current' to get the latest version.

Retrieve the secrets and print them to `STDOUT`:
```
# Usage: aws-secrets-get <app> <?ver|current> <?env|development> <?base|app>";
aws-secrets-get quizzo f1l3v3rs10ngu1D staging my_apps

# or specify using env variables instead
export APP_ENV=staging
export AWS_SECRETS_BASE=my_apps

aws-secrets-get quizzo f1l3v3rs10ngu1D
```

The last one can be run by:
  - users in the `my_apps-manage-secrets` group
  - programs on EC2 instances which have been started with the `my_apps-secrets` IAM instance profile

To list and add users to `my_apps-manage-secrets`:
```
aws iam list-users --query 'Users[*].UserName'
aws iam add-user-to-group --group-name my_apps-manage-secrets --user-name some_user
aws iam get-group --group-name my_apps-manage-secrets
```

To start an EC2 instance with the `my_apps-secrets` IAM instance profile from the CLI:

  `aws ec2 run-instances ... --iam-instance-profile Name=my_apps-secrets`

To start an ECS cluster with the `quizzo` IAM profile, select `quizzo-secrets-instances` from the
Container Instance IAM Role selection on the Create Cluster screen. Or you could also start an ECS task with the `quizzo` IAM role by selecting it in your Task Definition.

Description
===========

This repository contains a handful of scripts:

- `aws-secrets-init-resources`
- `aws-secrets-send`
- `aws-secrets-get`
- `aws-secrets-run-in-env`
- `aws-secrets-purge-resources`

They can be used to set up and maintain a file containing environment
variables which can then be used by an application running on an Amazon EC2
instance.  They can also be used when running an application in a
docker container on an EC2 instance.

*`aws-secrets-init-resources`* creates the following AWS resources:

- A customer master key (CMK).
- An alias for the key.
- An S3 bucket.
- A few roles to be used by an instance profile: one for S3 access, one for decryption with the CMK.
- A group with access policies to get/put to S3 and encrypt/decrypt with the CMK.

*`aws-secrets-send`* takes an app name and a  filename as input and uses
the CMK to encrypt it, then sends it to an object in the S3 bucket.

*`aws-secrets-get`* take an app name as input, and uses it to
construct the name of the S3 bucket and object.  It then retrieves
and decrypts the file and prints it to stdout.

If the file contains lines of the form:

```
X=yyyy
```
then exporting the output will put those
variables into the current environment.  i.e.

```
export `aws-secrets-get quizzo`
```

*`aws-secrets-run-in-env`* is a short script that does the above and
then executes another program, with its arguments.

*`aws-secrets-purge-resources`* removes the resources associated with this
app which were created by `aws-secrets-init-resources`.

Examples
=======
To use this in a docker file, add a line like this:
```
CMD ["aws-secrets-run-in-env", "quizzo", "start-quizzo"]
```
where "quizzo" is the name of your app, and "start-quizzo"
is the script that starts the app.

Notes
======

- These scripts depend on having the AWS CLI installed.  (See references below)

- Changing AWS_DEFAULT_REGION (or the aws-cli configuration) will effect the region used for API calls.

- Changing AWS_SECRETS_BUCKET_REGION will specify the region in which the S3 bucket is created.

References
==========

- https://www.promptworks.com/blog/handling-environment-secrets-in-docker-on-the-aws-container-service
- http://docs.aws.amazon.com/cli/latest/userguide/installing.html
- https://gist.github.com/themoxman/1d137b9a1729ba8722e4
