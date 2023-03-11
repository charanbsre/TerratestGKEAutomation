package test

import (
	"errors"
	"fmt"
	"path/filepath"
	"testing"
	"time"

	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	k8s "github.com/gruntwork-io/terratest/modules/k8s"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/retry"
	terraform "github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
)

func kubeWaitUntilNumNodes(t *testing.T, kubectlOptions *k8s.KubectlOptions, numNodes int, retries int, sleepBetweenRetries time.Duration) {
	statusMsg := fmt.Sprintf("Wait for %d Kube Nodes to be registered.", numNodes)
	message, err := retry.DoWithRetryE(
		t,
		statusMsg,
		retries,
		sleepBetweenRetries,
		func() (string, error) {
			nodes, err := k8s.GetNodesE(t, kubectlOptions)
			if err != nil {
				return "", err
			}
			if len(nodes) != numNodes {
				return "", errors.New("Not enough nodes")
			}
			return "All nodes registered", nil
		},
	)
	if err != nil {
		logger.Logf(t, "Error waiting for expected number of nodes: %s", err)
		t.Fatal(err)
	}
	logger.Logf(t, message)
}

// Verify that all the nodes in the cluster reach the Ready state.
func verifyGkeNodesAreReady(t *testing.T, kubectlOptions *k8s.KubectlOptions) {
	kubeWaitUntilNumNodes(t, kubectlOptions, 4, 30, 10*time.Second)
	k8s.WaitUntilAllNodesReady(t, kubectlOptions, 30, 10*time.Second)
	readyNodes := k8s.GetReadyNodes(t, kubectlOptions)
	assert.Equal(t, len(readyNodes), 4)
}

// Terratest function to test e2e deployment of GKE cluster
func TestTerraformGkeExample(t *testing.T) {

	//Setting workdir for terraform modules execution
	workingDir := test_structure.CopyTerraformFolderToTemp(t, "../", "terraform")

	//Setting kubeconfig directory
	kubeconfigDir := "C:/Users/cbaisetty/.kube"

	//Setting k8s manifest location
	kubeResourcePath, _ := filepath.Abs("../manifests/")
	secretDriverPath, _ := filepath.Abs("../secrets_dep/")

	//Initialising Terraform Options
	terraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: workingDir,
		Vars: map[string]interface{}{
			"project_id":       "protean-beaker-376112",
			"region":           "us-central1",
			"vpc_name":         "nextopsvpc01",
			"subnetwork_name":  "dev-subnet",
			"ip_cidr_range":    "10.0.0.0/18",
			"gke_cluster_name": "nextopsgke01",
			"gke_master_zone":  "us-central1-c",
			"gke_worker_zone":  "us-central1-f",
			"machine_type":     "e2-medium",
		},
	})

	//Calling Terraform Init and Apply
	terraform.InitAndApply(t, terraformOptions)

	//Setting Kubectl Options for manifest execution after cluster is ready.
	kubectlOptions := k8s.NewKubectlOptions("", kubeconfigDir+"/config", "default")
	kubectlOptions1 := k8s.NewKubectlOptions("", kubeconfigDir+"/config", "kube-system")

	//Verifying if GKE worker are ready for k8s operations, runs in multiple iterations until nodes are ready
	verifyGkeNodesAreReady(t, kubectlOptions)

	//Applying k8s manifests on the new GKE cluster with terratest k8s module and kubectlOptions
	k8s.KubectlApply(t, kubectlOptions1, secretDriverPath)
	k8s.KubectlApply(t, kubectlOptions, kubeResourcePath)

	//Verifying if ingress controller is up, runs in multiple iterations until ingress is ready.
	k8s.WaitUntilIngressAvailable(t, kubectlOptions, "ingress", 20, 60*time.Second)

	//Fetching ingress resource url's from terraform output for testing
	secretappUrl := terraform.Output(t, terraformOptions, "secretapp_fqdn")
	helloappUrl := terraform.Output(t, terraformOptions, "helloapp_fqdn")

	//forming ingress URL for testing using terraform output variables
	url1 := fmt.Sprintf("http://%s", secretappUrl)
	url2 := fmt.Sprintf("http://%s", helloappUrl)

	//Testing the ingress url's and looking for status 200 with expected output.
	http_helper.HttpGetWithRetry(t, url1, nil, 200, "281b5931-bf2f-4f36-9a88-3417469440a3", 30, 60*time.Second)
	http_helper.HttpGetWithRetry(t, url2, nil, 200, "Welcome To Webapp 01", 30, 60*time.Second)

	//Executing terraform destroy if the ingress url's are accessible
	defer terraform.Destroy(t, terraformOptions)
}
