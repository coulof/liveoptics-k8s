# liveoptics-k8s
LiveOptics Kubernetes Agent enables data collection of Kubernetes metrics API.

To pull these metrics we need to:
- Create a ServiceAccount
- Obtain the authorization token
- And load that token in the LiveOptics agent

In that repository you will find a dedicated or, if you prefer, the raw YAML to setup access and obtain the token.


## `create_sa_read-api.sh`
The shell script calls `kubectl` and needs enough privileges to create a service account.


Once you have the privileges just run `bash create_sa_read-api.sh --create`

To cleanup the account run `bash create_sa_read-api.sh --delete`


## `liveoptics-read-api-permissions.yaml`

If you don't have `bash` or `kubectl` you can create the Service Account with the help of [liveoptics-read-api-permissions.yaml](liveoptics-read-api-permissions.yaml)

We can load it with `kubectl apply -f liveoptics-read-api-permissions.yaml` or from the UI.

Once the account is created you can obtain the token with `kubectl get secret liveoptics-read-api-token -o jsonpath='{.data.token}' | base64 --decode` or from the UI as well.
