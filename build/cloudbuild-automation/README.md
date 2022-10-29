### Building with CloudBuild - Automated Builds

This repo shows how you can leverage Google Cloud Build triggers to automate your custom collector builds based on certain events on GitHub (or other similar version control repository hosting service).

After you have followed instructions in this README, you should have the following automation setup - 
 - You will have an [Artifact Registry](https://cloud.google.com/artifact-registry) setup in your GCP project where all your custom opentelemetry collector docker images will be published. 
 - You will have the GitHub repository (containing the code to build your custom collector) linked with a [Cloud Build Trigger](https://cloud.google.com/build/docs/triggers) which will be configured to trigger an automated build for a collector image whenever there is a push to the `main` branch of the repository (*this can be updated to track any branch*).

#### Prerequisites
- Make sure that you have [docker](https://docs.docker.com/engine/install/) installed on your machine.
    - Also verify that you are able to run docker commands without the need to gain root permissions using sudo. You can follow the [post-installation steps](https://docs.docker.com/engine/install/linux-postinstall/) to achieve this.
- Set the following environment variables 
    - `PROJECT_ID` with the GCP project ID in which you will submit cloud builds.
    - `GOOGLE_APPLICATION_CREDENTIALS` with the path to where your GCP credentials are present, most likely, it will be something like `${HOME}/.config/gcloud/application_default_credentials.json`.
    - You can set them by executing  
        ```bash
        export PROJECT_ID=<your-project-id>
        # This is where the default credentials live, might be different in case your default location is something else
        export GOOGLE_APPLICATION_CREDENTIALS=${HOME}/.config/gcloud/application_default_credentials.json
        ```

#### Repository Structure - Cloudbuild-Automation

1. `tf/main.tf` - folder containing Terraform files that will create necessary resources in your GCP account. 
2. `tf/setup-build-automation.sh` - convenience shell script that runs the terraform script to generate the resources in GCP account. 
3. `builder-config.yaml` - configuration defining how to build the custom opentelemetry collector. 
4. `cloudbuild.yaml` - the YAML file containing steps that need to be run in cloud build. The cloudbuild trigger uses this file to build the docker image for the opentelemetry custom collector.

#### How to run this sample

1. `cd` into the `cloudbuild-automation/tf`. 
2. Modify the variables declared at the top in `setup-build-automation.sh` script to suit your needs. 
3. Run the `setup-build-automation.sh` script. 
    ```
    sh setup-build-automation.sh
    ```
4. Upon running the script, terraform should initialize and will generate a few files in the current directory.
5. **IMPORTANT:** When you run the script for the first time, you will notice that the script fails with an error asking you to connect the repository to your GCP account. You will have to resolve this error before continuing, look at the [Connecting your repository to GCP account](#connecting-your-repository-to-gcp-account) section. 
6. After running the script successfuly and connecting your repository, you should have a Cloud Build trigger and an Artifact Registry configured for your selected project. You can verify this by looking these services in [Google Cloud Console](https://console.cloud.google.com).

If your Google Cloud project has the required resources - you're done! They should already be configured to automatically build docker images of the collector whenever there is a `push` to the configured branch of your repository - You can test this by making a commit and pushing it. 

#### Notes 
 - Whenever you make changes to the terraform file to modify/reconfigure the Google cloud resources, you will need to run the `setup-build-automation.sh` script again so that the changes can be put into effect. 
 - You only need to connect your repository to your GCP account once, unless you need to connect a new repository which was not connected before.

#### Connecting your repository to GCP account

When running the `setup-build-automation.sh` script for the first time, it is expected that you run into an error which basically asks you to connect your GitHub repository to your Google Cloud account. This step needs to be handled separately since it requires  GitHub authentication and permissions. The error looks something like - 
```bash 
Error: Error creating Trigger: googleapi: Error 400: Repository mapping does not exist. Please visit https://console.cloud.google.com/cloud-build/triggers/connect?project=<your-project-id> to connect a repository to your project
```
The error should contain a URL to your project and when you open the link, it should take you to Google Cloud Console &rarr; Build Trigger page and a popup would be shown that looks similar to - 
![connect-repo](images/connect-repo.png)

The UI takes you through a series of simple prompts asking you to authenticate GitHub application and select which repositories to connect to the account. The selected repository & repository owner should match the one you define in `setup-build-automation.sh`. 

**You may skip the last - 'Create a Trigger' step, which is marked optional** - this is because after connecting the repository, we can run the `setup-build-automation.sh` script again to automatically create and configure the build trigger.
After connecting your repository, while still in `cloudbuild-automation/tf` directory, run - 
```bash
sh setup-build-automation.sh
``` 
If the repository was connected successfully, the script should execute successfully with no issues. 

In case you wish to connect repository before running the script or for more detailed instructions on how to connect repositories, you can check out the below links - 
- [Connecting to Repositories](https://cloud.google.com/build/docs/automating-builds/create-manage-triggers#connect_repo)
- GitHub specific [Connect to a GitHub repository](https://cloud.google.com/build/docs/automating-builds/github/connect-repo-github)
