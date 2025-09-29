# activemq-kubernetes

## Copyright

(c) 2025 Mark Himsley

## Description

The intention of this project is to demonstrate creating a Highly Available ActiveMQ Classic cluster running in Kubernetes.

This repository contains Docker build files to create two Open Container Initiative (OCI) images to be used as containers in a Kubernetes Pod. One container runs ActiveMQ Classic, the other container runs a bash script to monitor the ActiveMQ container.

This repository also contains example Kubernetes [kubectl kustomize](https://kubernetes.io/docs/reference/kubectl/generated/kubectl_kustomize/) manifest fragments to create a highly available ActiveMQ instance running as a Deployment in a [Kubernetes cluster](https://kubernetes.io/docs/concepts/overview/components/).

The example Kubernetes manifest fragments assume that some highly available persistent storage is available for storing persistent data and that the ActiveMQ services will be available to connect to from outside of the Kubernetes cluster. It is possible to use [Longhorn](https://longhorn.io/) to create highly available persistent storage for Kubernetes, but that is out of scope for this demonstration project.

Please make sure you are familiar with [ActiveMQ](https://activemq.apache.org/components/classic/), [building and publishing OCI images with Docker](https://docs.docker.com/get-started/docker-concepts/building-images/build-tag-and-publish-an-image/) and [Kubernetes](https://kubernetes.io/).

Warning: the [`jetty.xml`](src/base/activemq-config/jetty.xml) configuration includes the demo application context. You don't want that to be available on an ActiveMQ that is accessible to anyone who you do not trust.

## Proposed Solution

Since have a NAS with shared NFS storage I opted for the shared file-system "master/slave" (as they continue to call it) Classic ActiveMQ configuration, [as documented here](https://activemq.apache.org/shared-file-system-master-slave).

I can make a Kubernetes *Deployment* requesting two (or more) classic ActiveMQ server instances to be run in *Pods*, mounting the NFS storage using *Persistent Volumes*.

## Problems to overcome

In an ActiveMQ cluster running in this configuration there will be a *leader* ActiveMQ server, and one (or more) *standby* ActiveMQ servers. Only the *leader* server binds to the network, listens for connections, and processes the messages on the topics/queues. The *standby* servers wait for the *leader* to fail, and then one will take over as *leader*.

There is a wrinkle with Kubernetes Services when running that system.

Kubernetes *Services* are designed to load balance across multiple identical copies of a running application.

Were a Kubernetes *Deployment* be deployed to create an ActiveMQ cluster in this configuration, with two ActiveMQ *Pods*, the Kubernetes Service would load balance across all of the *Pods*.

This is of no use with the *leader* + *standby* system.

Only one of the *Pods*, the one with the *leader* ActiveMQ instance, would be listening for network connections. 50% of the time the service would be connecting a client to the *standby* *Pod*, which is not listening for network connections.

In [this blog post](https://notes.mark.himsley.org/blog/2025/01/08/ActiveMQ_Kubernetes/) I describe the method of making Kubernetes *Services* only route traffic to the *Pod* running the *leader* instance of ActiveMQ which is implemented in this solution.

## Build the OCI images

The Dockerfiles to build the [Active-MQ server](src/activemq/Dockerfile) and the [reddiness probe](src/activemq-readiness/Dockerfile) are located in the `src` folder.

I assume you'll be pushing the built OCI images to a local registry, so these are the commands you'll need to run from a shell at the root of this repository.

```console
docker build \
 -t <your-registry>/activemq:5.18.6 \
 src/activemq/

docker push \
 <your-registry>/activemq:5.18.6

docker build \
 -t <your-registry>/activemq-reddiness:5.18.6 \
 src/activemq-readiness/

docker push \
 <your-registry>/activemq-reddiness:5.18.6
```

You can override the ActiveMQ version with the following Dockerfile build arguments.

```text
 --build-arg "activemq_version=5.18.6" \
 --build-arg "postgresqljdbc_version=42.5.1" \
```

## Configuration

* Make a new kubectl kustomize override directory by copying the directory `override/example` and its contents to a new directory within the `override` directory.

  ```code
  pushd src/kustomize/override
  cp -va example foo
  popd
  ```

In the copied override directory:

* Edit the file [`kustomization.yaml`](src/kustomize/override/example/kustomization.yaml) to replace the current values for `images/newName` and `images/newTag` with your registry, image name, and tag.
* Edit the file [`activemq-config/jetty-realm.properties`](src/kustomize/override/example/activemq-config/jetty-realm.properties) to set sensible usernames and passwords for the web admin pages of ActiveMQ Classic server.
* Edit the file [`service-patch.yaml`](src/kustomize/override/example/service-patch.yaml) to set the `loadBalancerIP` address for the ActiveMQ service.
* Edit the file [`persistentVolume.yaml`](src/kustomize/override/example/persistentVolume.yaml) to point to your persistent storage.

Please check that the [`activemq.xml`](src/kustomize/base/activemq-config/activemq.xml) and [`jetty.xml`](src/kustomize/base/activemq-config/jetty.xml) configuration files contain only the configuration you require, and optionally override them in your override directory.

These kubectl kustomize manifest fragments assume that you will deploy the ActiveMQ system into a new `namespace` called `active-mq`. If that is not the case then edit the files [`kustomization.yaml`](src/kustomize/override/example/kustomization.yaml) and [`namespace.yaml`](src/kustomize/override/example/namespace.yaml) in your override directory to set the namespace you will use.

Now you should be ready to deploy the ActiveMQ system into your Kubernetes cluster.

## Deploying to Kubernetes

Check that the kustomized yaml manifests are correct by running `kubectl kustomize` against your override directory.

```code
kubectl kustomize src/kustomize/override/foo
```

When you believe the output is correct, apply that to your kubernetes cluster.

```code
kubectl kustomize src/kustomize/override/foo | kubectl apply -f - --context <cluster-name>
```

## Warranty

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
