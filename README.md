# raft-action

You can now run your [rest api fuzz testing](https://github.com/microsoft/rest-api-fuzz-testing) (RAFT) jobs in a github action!
Any RAFT [job definition](https://github.com/microsoft/rest-api-fuzz-testing/blob/main/docs/schema/jobdefinition.md) 
file can be used, see the [RAFT documentation](https://github.com/microsoft/rest-api-fuzz-testing/blob/main/docs/index.md)
for more details.

Tools currently supported by RAFT are:
* [RESTler](https://github.com/microsoft/restler-fuzzer)
* [ZAP](https://github.com/zaproxy/zaproxy) (not available in `local` mode)
* [dredd](https://github.com/apiaryio/dredd) (not available in `local` mode)
* [schemathesis](https://github.com/schemathesis/schemathesis) (not available in `local` mode)

### Action inputs
```
inputs:
  mode:
    description: 'Setting the mode to "azure" will deploy against your azure RAFT deployment'
    required: false
    default: local
  arguments :
    description: 'RAFT CLI arguments'
    required: true
  logDirectory:
    description: 'Copy logs to this directory'
    required: false
    default: '.raft'
  raftDefaults:
    description: 'RAFT defaults.json contents'
    required: false
  secret:
    description: 'Service Principal secret for RAFT deployment'
    required: false
```

### Action Requirements and Limitations

* [RESTler](https://github.com/microsoft/restler-fuzzer) is the only supported tool when running in `local` mode.
To use other tools in your job definition, use the `azure` mode.

* Jobs are limited to 6 hours (this is a github limitation), if you want to fuzz for longer periods of time you will need
to use your azure deployment of RAFT.

* For this action to work you will need to setup python. Include the following in your workflow before the raft-action.
  ```
  - name: Setup Python
    uses: actions/setup-python@v2
    with:
      python-version: '3.8'    
  ```

* Authentication is not currently supported in `local` mode. If your service APIs are authenticated, use `azure` mode.
Support for authentication in `local` mode is planned.

### Available versions

This action contains scripts that are used to run RAFT. These scripts are from specific versions
of the RAFT CLI. The action tags use the same version numbers. For example, action tag v3.2 using
RAFT CLI release v3.2. If you are using this action to run your job on your azure deployment of RAFT, 
it is recommended that you use the same version as your deployment. 

Supported tags are:
- v3.2

### Action Input Arguments

- `mode` - this value can be `local` or `azure`</br>
  Optional. Default is `local`.</br> 

  This input argument controls where the RAFT job will run, in Azure on your RAFT deployment
or locally on the VM where the workflow is running. 

  Running locally RAFT uses docker to deploy the containers on the VM. For most jobs this works
without error. In some edge cases some containers do not behave the same as running in an Azure
Container Instance. 

- `arguments`</br>
  Required. No default value.</br>

  The RAFT CLI [command line arguments](https://github.com/microsoft/rest-api-fuzz-testing/blob/main/docs/cli-reference.md). 

- `logDirectory`</br>
  Optional. Default is `.raft`.</br>

  When running RAFT locally there will be logs produced by the tools that are run. 
  For example RESTler will produce a number of bug files and Postman collections that can be used to
reproduce the bugs. You can use
this input to control where the logs are copied before you create artifacts. 

- `raftDefaults`</br>
  Required for mode `azure`. No default value.</br>
  Your RAFT deployment has a `defaults.json` file. The contents of that file is the 
value for this field. Since the 
`defaults.json` data is a json blob with quote marks, 
you will need to escape the quotes, see example below. A simple way to handle this data
is to place it in a github secret. You can then reference it's value with `${{ secrets.MYDEFAULTS }}`
where `MYDEFAULTS` is the name of your secret.
```
{
    \"subscription\": \"00000000-6e2b-0000-b201-000000000000\",
    \"deploymentName\": \"demo\",
    \"region\": \"westus2\",
    \"registry\": \"mcr.microsoft.com\",
    \"metricsOptIn\": true,
    \"useAppInsights\": true,
    \"clientId\": \"00000000-7c83-0000-b3b3-000000000000\",
    \"tenantId\": \"00000000-86f1-0000-91ab-000000000000\"
}
```

- `secret`</br>
  Required for mode `azure`. No default value.</br>
  When running your fuzz job on your RAFT deployment an authentication secret is needed to access
the deployment. You can create the secret via the azure portal on your AAD RAFT application registration. 
Place the secret value into the github secret store
and reference it using `${{ secrets.MYSECRETVALUE }}` where `MYSECRETVALUE` is the name of your secret.

### Running RAFT within the Github Actions Runner

Here is an example of the RAFT action where a job definition file has been
checked in at `raft-fuzz/run.json`
```
# Run the raft command to fuzz locally
- name: Run RAFT
  uses: mgreisen/raft-action@v3.1
  with:
    # Mode tells the action we want to run using our raft local script
    mode: local

    # The raft cli command arguments. 
    # In this example the URL is kept in a secret because this is a public repo.
    # In this example the URL points to a logic app which creates a github issue.
    # You can use any URL that accepts a POST method to process the webhook. 
    arguments: 'job create --file raft-fuzz/run.json --bugFoundWebhookUrl ${{ secrets.BUG_FOUND_URL }}'
```

### Running RAFT on Azure

Here is an example of the RAFT action where a job definition file has been
checked in at `raft-fuzz/run.json`

```
- name: Run RAFT
  uses: mgreisen/raft-action@v3.1
  with:
    # Mode tells the action we want to run against our raft deployment on azure
    mode: azure
    
    # This is our raft defaults.json file contents kept as a secret
    # It tells the action how to access our deployment
    raftDefaults: ${{ secrets.RAFT_DEFAULTS }}

    # This is our service principal secret that allows us to
    # authenticate and use our deployment.
    secret: ${{ secrets.RAFT_SECRET }}

    # The raft cli command arguments. 
    arguments: 'job create --file raft-fuzz/run.json --poll 5'
```

### Saving the logs as an artifact

You can use the `upload-artifact` action to save the logs when RAFT is run locally.

If you specify the `logDirectory` input in the RAFT action, 
you can tell the action where to copy the logs. If `logDirectory`
is not specified the directory `.raft` will be used.

Example of saving the logs as an artifact. You will want to capture the logs to find the detailed output
of the tools.

```
        # Save the local logs into the pipeline artifacts for
        # access to raw bug buckets and postman collections.
      - name: Archive logs
        uses: actions/upload-artifact@v2
        with: 
            name: tool-logs
            path: .raft
```

### Example Job Definition file

The RAFT project has many [samples](https://github.com/microsoft/rest-api-fuzz-testing/tree/main/cli/samples)
of job definition files. 

Here is a simple example that runs RESTler 
against the deployed petstore sample service.

```
{
  "testTasks": {
    "targetConfiguration": {
      "apiSpecifications": [ "https://petstore.swagger.io/v2/swagger.json" ],
      "endpoint": "https://petstore.swagger.io"
    },
    "tasks": [
      {
        "toolName": "RESTler",
        "outputFolder": "restler-logs",
        "toolConfiguration": {
          "tasks": [
            {
              "task": "compile"
            },
            {
              "task": "Fuzz",
              "runConfiguration": {
                "Duration": "00:10:00"
              }
            }
          ]
        }
      }
    ]
  }
}
```

See the [RAFT documentation](https://github.com/microsoft/rest-api-fuzz-testing/tree/main/cli/samples/restler/self-contained) 
for examples on how to use RAFT to both deploy and test
your service in the same job. 
