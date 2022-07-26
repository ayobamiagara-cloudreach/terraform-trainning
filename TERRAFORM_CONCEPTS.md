# Terraform key concepts

## __`State file .tfstate`__

* __Desired vs Current state:__ This is determined by the resources defined the .tf files in the current directory. Also note that the arguments present in the resources are only used to track desired state. 
For example if you dont mention security group attribute in `aws_instance` then any additions or modifications of the security group attached to the instance is not tracked as its not an attribute in desrired state. 

* __.tfstate.backup:__

__Note:-__ terraform tf state file has the password which has been used in the terraform modules. Hence we should not commit terraform.tfstate file into git repository. This can be done by updating gitignore


## __`providers`:__ 

make sure it authentication is done with service provider. More like middle man. 

```
Example:

provider "aws" {
    region = "eu-west-1"
    access_key = "Sample Access Key"
    secret_access_key = "Sample 
}
```

* __versioning:__ explicitly specify the version in the code so that any upgrades dont break the code. versions can be mentioned in the below format. 
    * version = ">=2.7" # any version greater than 2.7
    * version = "2.7" 
    * version = "~> 2.0" # any version in the range of 2.x
    * version = ">=2.3,<=2.7" # any version between 2.3 and 2.7
* __credentials type:__ Multiple credential types are allowed
    * static credentials - access and secret access key
    * Usage of EC2 instance role in case it is hosted in EC2 instance.
    * shared credentials - like a shared .aws/credentials file stored in shared place
    * aws profile name - stored in the .aws/credentials file which can be loaded. 
* __third party providers:__ Download thirdparty provider in `~/.terraform.d/plugins` to initialize using terraform init. Wont be part of local .terraform directory.


## __`resources`:__ 

This is core part of the terraform, the resource of AWS are defined using this block. This block has a below format which starts with `resource` word and followed by two labels - `resource` & `resource name` (which has be unique)
Lifecycle Customizations: create_before_destroy (bool), prevent_destroy (bool), ignore_changes (list of attribute names)
```
Example:

resource "aws_eip" "lb" {
    vpc = true # This is a argument used for the current resource.
    lifecycle {
        create_before_destroy = true # This will create resources first before destroying if resource change requires recreation.
        prevent_destroy = true # This will prevent accidental destroy of resources.
        ignore_changes = [ # Ignores the changes to attributes of resources which are managed externally.
            tags,
        ]
    }
}
```

## __`outputs`:__ 

This is to reference and print the attributes of the resources which are created.

```
Example: 

output "eip" {
    value = aws_eip.lb.public_ip
}
```

## __`variables`:__ 

Used to define a value which would be repeating or can be part of user input. Types of variable available are - list, map, string and number
string/number variables are referenced in resources using `var.<name_of_variable>`
map variables are 
```
Example: 

variable "source" {
    type = string
    default = "10.1.0.0/24"
}
reference the variable: var.source

variable "list_data" {
    type = map
    default ={
        us-east-1 = "t2.micro"
        us-east-2 = "t2.small"
    }
}
reference the variable: var.list_data["us-east-1"]

```

The variables input value can be also provided in a file with extension .tfvars in below format. Refer to `terraform plan` command section to understand usage of vars file. By default the `terraform.tfvars` file present in directory is loaded first and then files ending with .auto.tfvars

```
File name: custom.tfvars
Contents of file:
instance_type=t2.small
```

## __`count & count index`:__

count argument in the resources will create multiple resources of same type without defining multiple blocks. This is part of the `resource` block and works similar to loop.

In this resource block additional attribute is available called `count.index`. This helps in creating unique naming conventions for some resources. 

__Note:__

```
Example:
var.name is a list of iam user names

resource "aws_iam_user" "default" {
    name = var.name[count.index]
    count = 3
    path = /
}
```

## __`Conditionals`:__

A conditional expression uses the value of bool to select one of two values. This used along with count can result in execution of resource block. This can also be used in locals as well.

`condition ? true_val : false_val`

Other new conditionals: 

* for_each is supported in resources and data blocks.
* for expression allows the construction of a list or map by transforming and filtering elements in another list or map
* Example for this can be found in https://www.hashicorp.com/blog/hashicorp-terraform-0-12-preview-for-and-for-each/
* other Gotchas https://blog.gruntwork.io/terraform-tips-tricks-loops-if-statements-and-gotchas-f739bbae55f9


```
Example:
The below count is present in the resource block.
count = var.test_condition === true ? 1 : 0
```
The "count" value depends on resource attributes that cannot be determined until apply, so Terraform cannot predict how many instances will be created. To work around this, use the -target argument to first apply only the resources that the count depends on.

## __`locals`:__

A local value assign a name to an expression, allowing it to be used multiple times within a module without repeating it. This will help to prevent repetitions of the a particular argument which can be used in multiple blocks.
locals can use conditionals, functions and static values. 
Expressions of local value can refer to other locals but reference cycles such as reference to self is not allowed

```
Example:
locals in resource blocks

locals {
    common_tags = {
        Owner = "Rajesh"
        service = "HnS"
    }
}

locals using conditions

locals {
    name = var.name != "" ? "default" : var.name
}

Reference: locals.commontags["Owner"]
```

## __`data sources`:__

Data sources allow data to be fetched and computed for use elsewhere in terraform configuration. These are basically used to fetch the existing configuration in aws such as AMI, AZ's etc. This can also be used for reading templates.

```
Example: 

data "aws_ami" "default" {
    most_recent = true
    owners = ["amazon"]

    filter = {
        name = "name"
        values = ["amzn2-ami-hvm"]
    }
}

reference in resource block: data.aws_ami.default.id
```
## __`Built in functions`:__

The Terraform language includes a number of built-in functions that you can call from within expressions to transform and combine values. You cannot create a custom function. Below are the categories of functions

* Numeric Functions
* String Functions
* Collection Functions
* Encoding Functions
* Filesystem Functions
* Date and Time Functions
* Hash and Crypto Functions
* IP Network Functions
* Type Conversion Functions


## __`Debugging`:__
Terraform logging can be enabled by setting `TF_LOG` environment variable to any value - `TRACE, DEBUG, INFO, WARN, or ERROR`

TRACE: gives a lot of log output (most verbose) on what terraform is actually doing.

When you set the TF_LOG_PATH environment variable all of the logs are written to the file. 
Example: `export TF_LOG_PATH=/tmp/terraform.log`

## __Dynamic Blocks:__

Dynamic blocks allows us to dynamically construct repetable blocks which is supported inside of resource, data, provider, and provisioners blocks. This is applicable for nested configuration blocks similar to one mentioned below. 

* for_each is supported in resources and data blocks.
* for expression allows the construction of a list or map by transforming and filtering elements in another list or map
* Example for this can be found in https://www.hashicorp.com/blog/hashicorp-terraform-0-12-preview-for-and-for-each/
* other Gotchas https://blog.gruntwork.io/terraform-tips-tricks-loops-if-statements-and-gotchas-f739bbae55f9

```
Example: 
SG ingress block look like 

ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
}

variable "sg_ports" {
    default = [8200, 8203, 8300]
}

dynamic "ingress" {
    for_each = var.sg_ports  # for each value in the var lists
    iterator = port  # name of the temporary variables that 
                     # represents the current element.
    content {
        from_port  = port.value
        to_port    = port.value
        protocol   = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
```

## __`provisioners`:__

Provisioners are used to execute certain commands or instructions after a resource has been created. For example: Installing nginix server after an EC2 instance is created. Multiple provisioners can be used in a resource block which are executed in order they are defined. 

Provisioner types: local-exec, remote-exec, file, chef, connection etc. 

* `local-exec: `to execute command locally where terraform apply has been executed. Can be used to run ansible playbooks from local system.

* `remote-exec: `to execute commands in the resources which has been created
    ```
    Example: 
    resource "aws_instance" "default" {

        provisioner "remote-exec"{
            # All commands to be executed are here
            inline = [ 
                # command 1 - install nginx
                # command 2 - bring up nginx
            ]
            
            # connection credentials for terraform.
            connection { 
                type = "ssh"
                user = "ec2-user"
                private_key = file(<file_path>)
                host = self.public_ip 
                # self refers to the main resource.
            }
        }

        provisioner "local-exec" {
            command = "echo ${aws_instance.default.id} >> instance.txt"
            on_failure = "continue" # Ignore the error and continue with creation or destruction.
            when    = "destroy" # Use this feature to run provisioner during destroy time. 
        }
    }
    ```

## __`modules`:__
This is just re using the common resources tf files created so that we dont end up repeating the configuration. 

__Note:__ 
* In order to install the modules and relevant providers of modules terraform init needs to be executed.

```
Example: 
# Below is format for referring source present in various places.
module "myec2" {
    # This  usage to refer local module
    source = "../../modules/ec2"

    # This usage for the terraform registry
    source = "terraform-aws-modules/ec2-instance/aws"
    version = "" # version of the verified registry module version. 

    # This usage for github source
    source = source = "github.com/hashicorp/example"
    
    # This usage for s3 source
    source = "s3::https://s3-eu-west-1.amazonaws.com/examplecorp-terraform-modules/vpc.zip"
}

module "module_name" {
    source = "../../modules/ec2"
    instance_type = "t2.large" # This is called input & should be defined as a variable in the module. 
}

output "moduleoutput" {
    value = module.<module_name>.<outpu_name_inside_module>  # Output needs to be defined in the module
}
```

## __`environment`__

## __`workspace`:__
Workspace is like an isolated environment with different set of environment variables assigned to it. 

* Each Terraform configuration has an associated backend that defines how operations are executed and where persistent data such as the Terraform state are stored. The persistent data stored in the backend belongs to a workspace. Initially the backend has only one workspace, called "default", and thus there is only one Terraform state associated with that configuration.

* env variable available `terraform.workspace` which gives name of the current workspace.
```
tf state file for each workspace is stored in below folder
pwd/terraform.tfstate.d/<workspace_name>/

Example: 
pwd/terraform.tfstate.d/dev/terraform.tfstate

```
## __`workflow`__

terraform write --> plan --> apply 
init to be used before plan in order to download required providers

## __`registry`:__
This is nothing but a hashicorp provided modules available for ready use. They are published by hashicorp or individual users. 

```
Example:
module "myec2" {
    # This usage for the terraform registry
    source = "terraform-aws-modules/ec2-instance/aws"
    version = "" # version of the verified registry module version. 
    instance_type = "" # Input for module
    ami_id = "" # input for module
}
```
## __`remote state management`__
remote state management is required to help lock resource when a plan is being applied and prevents corruption of state file. This can be done 

## __`multi region & multi account deployment`:__
for multi region deployment we use a method called provider alias as mentioned in Example 1.

```
Example 1: 

provider "aws" {
    region = "us-east-1"
}

provider "aws" {
    alias = "ireland"
    region = "eu-west-1"
}

resource "aws_eip" "default" {
    vpc = true
}

resource "aws_eip" "default1" {
    # Below attribute is used to specify the provider resource uses
    provider = aws.ireland 
    vpc = true
}
```

## __Sensitive Parameter:__

Important to set sensitive property true while handling sensitive information. This will prevent value being shown in the output for cli or terraform cloud.

__Note:__ This will not encrypt the values in the state file.

```
Example:

output "db_password" {
    value = aws_db_instane.db.password
    sensitive = true
}
```

## __Terraform Cloud:__

Terraform cloud manages terraform runs in a consistent and reliable environment with various features like access controls, private registry for sharing modules, policy controls and others.

* All the terraform modules are managed within work spaces. Jobs Show terraform plan, terraform version, cost for resourcs and policy check for a job which has been queued for approval. 
* This also stores the terraform state file for the runs which have been completed in the workspace. 
* Option to add variables (similar to tfvars) and environment variables in a workspace.
* You can create your own module and private registry. You can also configure VCS repo where the code is stored.
* Organisation needs to created and plans can be executed in respective workspaces.

__Remote Operations:__When using full remote operations, operations like terraform plan and apply can be executed in terraform cloud's run environment, with log output streaming to local terminal.
* Define `backend "remote"` in the `terraform {}` section. No need to define provider or access key details as they are pulled from terraform cloud.
* Define `backend.hcl` file where hostname , organization and workspace of terraform cloud are defined.
* User `terraform login` to get api token and then commence the rest of the operations.
* Initialize using `terraform init -backend-config=backend.hcl`
* When using terraform cloud locally, it is important to remember to create workspaces without VCS if the code is stored locally. Single source of truth is needed either VCS or no VCS.

__Sentinel Policy check:__ 

This is similar to Azure policies where we define the policy the resources need to adhere to. Enforcement options - hard-mandatory, soft-mandatory (can override) and advisory (logging only). This will affect the final `terraform apply` step based on the enforcement options.

* Sentinel Policy will define the rules which are applicable to policy sets and policy sets are applicable to one or more workspaces
* Policy sets are applicable to all or selected workspaces. 
* __Note:__ These are part of paid plan.

## __Terraform Enterprise:__

## __Vault:__

# __Terraform key commands:__

### `terraform -help`

`Usage: terraform [-version] [-help] <command> [args]`

`terraform`: Below options in combination to above commands can be used to get help with commands. 
* --help
* -h

Common commands:

    apply              Builds or changes infrastructure
    console            Interactive console for Terraform interpolations
    destroy            Destroy Terraform-managed infrastructure
    env                Workspace management
    fmt                Rewrites config files to canonical format
    get                Download and install modules for the configuration
    graph              Create a visual graph of Terraform resources
    import             Import existing infrastructure into Terraform
    init               Initialize a Terraform working directory
    login              Obtain and save credentials for a remote host
    logout             Remove locally-stored credentials for a remote host
    output             Read an output from a state file
    plan               Generate and show an execution plan
    providers          Prints a tree of the providers used in the configuration
    refresh            Update local state file against real resources
    show               Inspect Terraform state or plan
    taint              Manually mark a resource for recreation
    untaint            Manually unmark a resource as tainted
    validate           Validates the Terraform files
    version            Prints the Terraform version
    workspace          Workspace management

All other commands:

    0.12upgrade        Rewrites pre-0.12 module source code for v0.12
    debug              Debug output management (experimental)
    force-unlock       Manually unlock the terraform state
    push               Obsolete command for Terraform Enterprise legacy (v1)
    state              Advanced state management

### `terraform init [options] [DIR]`:

* Initializes the backend (local or remote backend)
* Downloads the plugin based on the version mentioned in the providers block. If provider version is not specified then latest version is downloaded. 
* THe downloaded plug in is stored in `.terraform` folder
* `-backend=true`: Configure the backend for this configuration.
* use `-upgrade` option to upgrade the provider version

### `terraform plan [options] [DIR]`

* Also validates the .tf files, similar to functionality of `terraform validate`

* This command also refreshes the state file, similar to functionality of `terraform refresh`

[options] are 
* `-var`: This is to explicity mention the variable values overriding the default value present in `variables.tf` file. Example: 
    * `-var "size=t2.micro"` ### providing key value pair input at cmd
    * `-var-file=custom.tfvars` ### providing vars file as input at cmd
    * Alternatively, you can create an environment variable `TF_VAR_<variablename>` and this will be used when you run the plan.
    
    __Note:__ if the .tfvars file name is `terraform.tfvars` then terraform commands would understand and read the file implicitly. This would be preferable way to create terraform variables.

* `-out`: This will output the plan into a file which can be used while performing apply. The final file might have secrets, hence it is important to encrypt the file. 


### `terraform refresh [options] [dir]`

  Update the state file of your infrastructure with metadata that matches
  the physical resources they are tracking.

  This will not modify your infrastructure, but it can modify your
  state file to update metadata. This metadata might cause new changes
  to occur when you generate a plan or call apply next.

### `terraform show [options] [path]`
  Reads and outputs a Terraform state or plan file in a human-readable
  form. If no path is specified, the current state will be shown.
options: -no-color, -json


### `terraform apply [options] [DIR-OR-PLAN]`
  Builds or changes infrastructure according to Terraform configuration
  files in DIR.

  By default, apply scans the current directory for the configuration
  and applies the changes appropriately. However, a path to another
  configuration or an execution plan can be provided. Execution plans can be
  used to only execute a pre-determined set of actions.

[options] are 
* `-var`: #refer to var section in terraform plan above. 
* `-auto-approve` : Skip interactive approval of plan before applying.
* `-lock=true`: Lock the state file when locking is supported.
* `-target=resource`: Resource to target. Operation will be limited to this resource and its dependencies. This flag can be used multiple times.

### `terraform destroy [options] [DIR]`

 Destroy Terraform-managed infrastructure.

* `-auto-approve`: Skip interactive approval before destroying.
* `-target=resource`: Resource to target. Operation will be limited to this resource and its dependencies. This flag can be used multiple times.

### `terraform fmt [options] [DIR]`:

Rewrites all Terraform configuration files to a canonical format. Both configuration files (.tf) and variables files (.tfvars) are updated. JSON files (.tf.json or .tfvars.json) are not modified.

If DIR is not specified then the current working directory will be used.

If DIR is "-" then content will be read from STDIN. The given content must be in the Terraform language native syntax; JSON is not supported.

### `terraform graph [options] [DIR]`
Outputs the visual execution graph of Terraform resources according to configuration files in DIR (or the current directory if omitted).

The graph is outputted in DOT format. The typical program that can read this format is GraphViz, but many web services are also available to read this format.

### `terraform validate [options] [dir]`

 Validate runs checks that verify whether a configuration is syntactically valid and internally consistent, regardless of any provided variables or existing state. It is thus primarily useful for general verification of reusable modules, including correctness of attribute names and value types.
 
 Validate the configuration files in a directory, referring only to the configuration and not accessing any remote services such as remote state, provider APIs, etc.

### `terraform taint [options] <address>`:
  
  `<address>` example: aws_instance.foo, module.foo.module.bar.aws_instance.baz

  Manually mark a resource as tainted, forcing a destroy and recreate on the next plan/apply.

  This will not modify your infrastructure. This command changes your
  state to mark a resource as tainted so that during the next plan or
  apply that resource will be destroyed and recreated. This command on
  its own will not modify infrastructure. This command can be undone
  using the "terraform untaint" command with the same address.


### `terraform untaint [options] name`
  Manually unmark a resource as tainted, restoring it as the primary
  instance in the state.  This reverses either a manual 'terraform taint'
  or the result of provisioners failing on a resource.

  This will not modify your infrastructure. This command changes your
  state to unmark a resource as tainted.  This command can be undone by
  reverting the state backup file that is created, or by running
  'terraform taint' on the resource.

### `terraform state <subcommand> [options] [args]`

This command has subcommands for advanced state management.

These subcommands can be used to slice and dice the Terraform state. This is sometimes necessary in advanced cases. For your safety, all state management commands that modify the state create a timestamped backup of the state prior to making modifications.

__subcommands:__ 
* list: Resources part of state file. 
* mv: move items in terraform state, renaming resources without destroy. Such as renaming as resource within the tf file.
* pull: Manually download and output the state of the remote state file.
* push: Upload local state file to remote state file. should be used rarely. 
* rm: This is to remove items from terraform state file. These items are not destroyed and managed by terraform. on subsequent terraform plan run it will try to create resource.
* show: This is used to show the attributes of the resource in terraform state file. 

### `terraform workspace <subcommand>`
Refer to workspaces sub section above to understand about workspaces.
subcommands: new, list, show, select and delete Terraform workspaces.

### `terraform import [options] ADDR ID`
 
This will find and import the specified resource into your Terraform state, allowing existing infrastructure to come under Terraform management without having to be initially created by Terraform.

The ADDR specified is the address to import the resource to. Please see the documentation online for resource addresses. The ID is a resource-specific ID to identify that resource being imported. Please reference the documentation for the resource type you're importing to determine the ID syntax to use. It typically matches directly to the ID that the provider uses.


### `terraform login [hostname]`

Retrieves an authentication token for the given hostname, if it supports automatic login, and saves it in a credentials file in your home directory. 
If no hostname is provided, the default hostname is app.terraform.io, to log in to Terraform Cloud.

This is used mainly while running terraform plan in cloud from local terminal. 

### `terraform logout [hostname]`
Removes locally-stored credentials for specified hostname.

Note: the API token is only removed from local storage, not destroyed on the remote server, so it will remain valid until manually revoked.


# __Exercises for Terraform associate__

* Create a set of resources using aws provider, resources, variables, output
* Do manual changes to the resources created using terraform and see how refresh works.
* Understand the state file and use the terraform state subcommands to see how it works.
* Use count, for_each, for, functions, dynamic blocks
* Break the code and debug it, format and validate the code.
* Deploy resources in different regions using provider alias option.
* Taint a resource and observe how it is recreated. Untaint the resource and see if it is destroyed and recreated.
* Use provisioners to do some remote stuff
* Create a set of workspaces and see how it works
* Create a remote backend for each workspace and use the workspace related attributes to switch the backend.
* Create a custom module and use that module
* Create a terraform block using registry
* Try to do it via terraform cloud
* Explore vault


## Things to remember for exam:

* Terraform provider architecture
* Usage of multiple providers
* Definitions and working of the terraform commands.
