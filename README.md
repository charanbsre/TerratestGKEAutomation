# TerratestGKEAssignment

This module tests deployment of GKE cluster. It deploys and destroys following resources
      1.	A VPC in Google Cloud
      2.	A GKE Cluster
      3.	A Secret Manager Secret (to use inside a deployment)
      4.	A Public IP
      5.	A DNS Zone for app public access
      6.	2 DNS records pointing to the public ip reserved in step 4. 

After the successful deployment of GKE cluster, it also deploys following Kubernetes components
      1.	Two deployments
        a.	Secretapp-Deployment – To simulate secretmanager integration and safe retrieval of secret
        b.	HelloApp-Deployment – To simulate ingress controller functionality.
      2.	Two services
        a.	Secret-service
        b.	Nginx-service
      3.	Secret CSI Driver plugin for GKE cluster
      4.	Ingress Resource to route traffic to above service via public IP and fqdn’s in DNS zone

After the validation is successful terraform destroy will be executed to cleanup the resources.

contact me at charanb.sre@gmail.com for futher discussions or any questions. 
