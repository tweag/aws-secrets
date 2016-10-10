aws-secrets
===========
Manage secrets on AWS instances with KMS encryption, IAM roles and S3 storage.

Synopsis
========

Installation:
```
git clone -o github https://github.com/promptworks/aws-secrets
make install
# (or just copy `bin/\*` to somewhere in your PATH)
```

Set up AWS resources:
```
aws-secrets-init-resources myapp
```

Make some secrets, send them to the cloud:
```
echo "export SECRET=xyzzy" > aws-secrets
aws-secrets-send myapp aws-secrets
```

Now retrieve the secrets:

```
aws-retrieve-secrets myapp
```

The last one can be run by:
  - users in the `myapp-manage-secrets` group
  - programs on ec2 instances which have been started with the `myapp-secrets` IAM profile

To start an instance with the myapp-secrets IAM profile from the CLI:

  `aws ec2 run-instances ...--iam-instance-profile Name=myapp-secrets`

Description
===========

This repository contains four bash scripts:

- `aws-secrets-init-resources`
- `aws-secrets-send`
- `aws-secrets-receive`
- `aws-secrets-purge-resources`
- `aws-secrets-setup-env`

They can be used to set up and maintain a file containing secret
keys which can be used by an application running on an Amazon EC2
instance.  Or they can be used to set the environment for an
application running in a a docker container within an Amazon EC2 instance.

*`aws-secrets-init-resources`* creates the following AWS resources:

- A customer master key (CMK).
- An alias for the key.
- An S3 bucket.
- A few roles to be used by an instance profile: one for S3 access, one for decryption with the CMK.
- A group with access policies to get/put to S3 and encrypt/decrypt with the CMK.

*`aws-secrets-send`* takes an app name and a  filename as input and uses
the CMK to encrypt it, then sends it to an object in the S3 bucket.

*`aws-secrets-receive`* take an app name as input, and uses it to
construct the name of the S3 bucket and object.  It then retrieves
and decrypts the file and prints it to stdout.

If the file contains lines of the form:

```
export X=yyyy
```
then calling `eval` on the output will put those
variables into the current environment.  i.e.

```
eval `aws-retrieve-secrets myapp`
```

*`aws-secrets-run-in-env`* is a short script that does the above and
then executes another program, with its arguments.

*`aws-secrets-purge-resources`* removes the resources associated with this
app which were created by `aws-secrets-init-resources`.

Examples
=======
To use this in a docker file, you can addd this file:
```
CMD ["aws-run-in-env", "myapp", "myapp-script"]
```
where "myapp" is the name of your app, and "myapp-script"
is the script that starts the app.

Notes
======

- These scripts depend on having the AWS CLI installed.  (See references below)

- It may be necessary to explicitly set the region (in the env variable AWS_DEFAULT_REGION).

References
==========

- https://www.promptworks.com/blog/handling-environment-secrets-in-docker-on-the-aws-container-service
- http://docs.aws.amazon.com/cli/latest/userguide/installing.html
- https://gist.github.com/themoxman/1d137b9a1729ba8722e4
