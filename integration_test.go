package test

import (
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/stretchr/testify/require"

	http_helper "github.com/gruntwork-io/terratest/modules/http-helper"
	"github.com/gruntwork-io/terratest/modules/k8s"
)

func TestClusterModule(t *testing.T) {
	t.Parallel()

	// Path to the Kubernetes resource config we will test
	sampleResourcePath, err := filepath.Abs("./kuard.yaml")

	require.NoError(t, err)

	// To ensure we can reuse the resource config on the same cluster to test different scenarios, we setup a unique
	// namespace for the resources for this test.
	// Note that namespaces must be lowercase.
	namespaceName := os.Getenv("APP_NAMESPACE") //fmt.Sprintf("integration-%s", strings.ToLower(random.UniqueId()))

	// - HOME/.kube/config for the kubectl config file
	// - Current context of the kubectl config file
	// - Random namespace
	options := k8s.NewKubectlOptions("", "", namespaceName)
	appName := os.Getenv("APP_NAME")

	// create the random namespace
	//k8s.CreateNamespace(t, options, namespaceName)

	// cleanup resources before finishing the test.
	//defer k8s.DeleteNamespace(t, options, namespaceName)
	defer k8s.KubectlDelete(t, options, sampleResourcePath)
	//defer k8s.KubectlDelete(t, options, validatorResourcePath)

	// This will run `kubectl apply -f RESOURCE_CONFIG` and fail the test if there are any errors
	k8s.KubectlApply(t, options, sampleResourcePath)
	// This will launch the pod validator for the sample app

	t.Run("Evaluate Sample Application is deployed", func(t *testing.T) {

		// This will get the service resource and verify that it exists and was retrieved successfully. This function will
		// fail the test if the there is an error retrieving the service resource from Kubernetes.
		service := k8s.GetService(t, options, "kuard")
		require.Equal(t, service.Name, "kuard")
	})

	t.Run("Check external endpoint works", func(t *testing.T) {
		endpoint := "https://" + appName + ".integration-test.guideplatform.nl/healthy"

		// Make an HTTP request to the external ingress and make sure it returns a "ok"
		http_helper.HttpGetWithRetry(t, endpoint, nil, 200, "ok", 60, 15*time.Second)
	})

	t.Run("Check internal endpoint works", func(t *testing.T) {
		endpoint := "https://" + appName + "-internal.integration-test.guideplatform.nl/healthy"

		// Make an HTTP request to the internal ingress and make sure it returns a "ok"
		http_helper.HttpGetWithRetry(t, endpoint, nil, 200, "ok", 60, 15*time.Second)
	})
}
