# Redmine with MySql deployed in EKS cluster using Terrafom/Helm
## Pre-requisites
Initially you have to setup your local server(deployment box). This can be your desktop or and EC2.

* AWS account with privileges. 
* AWS cli should be installed.(Refer https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html)
* Helm and Tiller should be installed. (https://docs.helm.sh/using_helm/#installing-helm)
* Install IAM Authenticator. (https://docs.aws.amazon.com/eks/latest/userguide/install-aws-iam-authenticator.html)
* Install kubectl.(https://kubernetes.io/docs/tasks/tools/install-kubectl/#install-kubectl) (probably you have to set repo_gpgcheck=1)
* Install Terraform.(https://learn.hashicorp.com/terraform/getting-started/install.html)

## Procedure
Clone this repository. 
Here, I have used local tfstate as the backend due to demonstration.

1. Configure aws cli with your AWS Access Key ID and AWS Secret Access Key. This is to avoid store your credentials in terraform files.
   ```
   aws configure     
   ```
2. Clone the reposroty.
   ```
   git clone https://github.com/codefreaker/terraform-eks-rail-helm.git
   ```
3. Move to the directory.
   ```
   cd terraform-eks-rail-helm
   ```
4. Run below terraform commands.
   ``` 
   terraform init
   terraform plan 
   ```
5. If plan ran sucessfully, now you may apply the changes.(remove --auto--approve if you want)
   ```
   terraform apply --auto--approve
   ```
6. After creating the EKS cluter, run below script to join the nodes to EKS master.
   ```
   chmod +x join-nodes.sh;./join-nodes.sh
   ```
7. Now you get the nodes and from kubectl.
   ```
   kubectl get nodes
   [ec2-user@ip-172-31-82-243 terraform-eks-rail-helm]$ kubectl get nodes
   NAME                         STATUS   ROLES    AGE   VERSION
   ip-10-0-0-8.ec2.internal     Ready    <none>   7m    v1.11.5
   ip-10-0-1-189.ec2.internal   Ready    <none>   7m    v1.11.5
   ip-10-0-1-234.ec2.internal   Ready    <none>   7m    v1.11.5
   ```
      
8. Run start and initiate tiller now.
   ```
   helm init
   ```
   
9. Now, we need to set permission to run tiller in EKS cluster since EKS is RBAC enabled.
   ```
   kubectl create serviceaccount tiller --namespace kube-system
   kubectl create -f tiller-clusterrolebinding.yaml
   helm init --service-account tiller --upgrade
   ```
10. It's time to install Redmine using Helm.
    ```
    helm install --name redmine stable/redmine
    ```
11. Verify the deployment.
    ```
    [ec2-user@ip-172-31-82-243 terraform-eks-rail-helm]$ helm ls
    NAME    REVISION        UPDATED                         STATUS          CHART           APP VERSION     NAMESPACE
    redmine 1               Sun Feb 17 02:16:49 2019        DEPLOYED        redmine-8.0.3   4.0.1           default
    ```
    ```
    [ec2-user@ip-172-31-82-243 terraform-eks-rail-helm]$ kubectl get pods -o wide
    NAME                               READY   STATUS    RESTARTS   AGE   IP           NODE                         NOMINATED NODE
    redmine-mariadb-0                  1/1     Running   0          10m   10.0.1.237   ip-10-0-1-234.ec2.internal   <none>
    redmine-redmine-65c84c84b7-b42mf   1/1     Running   0          10m   10.0.0.37    ip-10-0-0-8.ec2.internal     <none>
    ```  
12. Run below script to get the Redmine cluster and login info.
	 ```
	 chmod +x redmine-info.sh;./redmine-info.sh
    ```
13. To uninstall/delete Redmine.
    ```
	 helm delete redmine
    ```
14. Dispose the EKS cluster.
    ```
    terraform destroy --auto-approve
    ```
   



