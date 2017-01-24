aws-secrets
===========
Manage secrets on AWS instances with KMS encryption, IAM roles and S3 storage.

Synopsis
========

aws-secrets requires [aws-cli](https://aws.amazon.com/cli/) version 1.8 or later.

Installation:
```
git clone -o github https://github.com/promptworks/aws-secrets
cd aws-secrets
make install
# (or just copy `bin/*` to somewhere in your PATH)
```

Set up AWS resources for an application named quizzo:
```
aws-secrets-init-resources quizzo
```

Make some secrets, send them to the cloud:
```
echo "SECRET=xyzzy" > quizzo-env
aws-secrets-send quizzo quizzo-env
```

Retrieve the secrets and print them to stdout:

```
aws-secrets-get quizzo
```

The last one can be run by:
  - users in the `quizzo-manage-secrets` group
  - programs on ec2 instances which have been started with the `quizzo-secrets` IAM profile

To start an EC2 instance with the quizzo-secrets IAM profile from the CLI:

  `aws ec2 run-instances ...--iam-instance-profile Name=quizzo-secrets`

To start an ECS cluster with the quizzo IAM profile, select quizzo-secrets-instances from the
Container Instance IAM Role selection on the Create Cluster screen.

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
then calling `eval` on the output will put those
variables into the current environment.  i.e.

```
export $(aws-secrets-get quizzo | xargs)
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

- It may be necessary to explicitly set the region (e.g. using the AWS_DEFAULT_REGION environment variable).

References
==========

- https://www.promptworks.com/blog/handling-environment-secrets-in-docker-on-the-aws-container-service
- http://docs.aws.amazon.com/cli/latest/userguide/installing.html
- https://gist.github.com/themoxman/1d137b9a1729ba8722e4
