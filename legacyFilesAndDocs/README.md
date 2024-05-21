# raft

original doc in repo
**TLDR**
    
    install minikube
    install docker
    clone repo
    cd into repo
    run docker build -t print-timestamp:alpine .
    minikube start
    minikube image load print-timestamp:alpine
    kb apply -f k8s/deployment.yaml
    kb apply -f k8s/service.yaml
    kb apply -f k8s/scaler.yaml
    kb get pods
    kb port-forward pod/print-timestamp-<from-prev-command-1234567890> 4430:4430
    curl 127.0.0.1:4430

    time output

VVV IN PROGRESS VVV

<p>
<strong><span style="text-decoration:underline;">TECH CHALLENGE</span></strong>
</p>
<p>
I created a Repo and cloned this locally
</p>
<h5>PYTHON SCRIPT<br></h5>
<p>
In this repo I firstly created the python script and named this
<code>print_timestamp.py<br></code>
</p>

    import time

    # ts stores the time in seconds 
    ts = time.time()

    # print the current timestamp 
    print(ts)

<p>
Running with <code>python3 print_timestamp.py</code> allowed me to test that the
script was successful and ensured that the ask of attaining console type output
can be cross-checked and referenced to the output of the kubernetes cluster once
deployed.
</p>
<p>
The  naming format utilising an underscore was retained as important so that all
understood the name to be referenced.
    
    > python3 print_timestamp.py
    1716319109.759373

</p>
<h5 id="server">SERVER</h5>
<p>
To ensure a small image size, it was decided to use the built-in Python server
to return the time.
</p>
    
    #import need libraries
    import time
    from http.server import BaseHTTPRequestHandler, HTTPServer

    #Class to be used
    class RequestHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        # Get the current timestamp
        ts = time.time()

        # Send response status code and headers
        self.send_response(200)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()

        # Send the timestamp as a response
        self.wfile.write(str(ts).encode())

    #Run the server and allow response
    def run(server_class=HTTPServer, handler_class=RequestHandler, port=4430):
        server_address = ('', port)
        httpd = server_class(server_address, handler_class)
        print(f'Starting httpd server on port {port}...')
        httpd.serve_forever()

    if __name__ == '__main__':
        run()
<p>
This was run in one terminal and in a second running <code>curl
127.0.0.1:4430</code> calls to the server and returned
<code>1716319485.656218%</code>
</p>
<p>
This was different to the original output, adding %. After research, this was
due to curl adding this to indicate the end of line as python was not returning
a new line.<br>New line was added to the script and not the % was no
longer seen <code>self.wfile.write((str(ts) + '\n').encode())</code>
</p>
<h5 id="docker">DOCKER</h5>
<p>
Now we need to create the docker image to be used in K8s.
</p>

    # Use a lightweight Python image
    FROM python:3.9-slim

    # Set the working directory in the container
    WORKDIR /app

    # Copy the Python script into the container
    COPY print_timestamp.py .

    # Command to run the Python script
    CMD ["python", "print_timestamp.py"]
<p>
Running <code>docker build -t print_timestamp:latest . </code> this will build
the image locally for us to run.
</p>
    
    > docker images
    REPOSITORY            TAG       IMAGE ID       CREATED          SIZE
    print_timestamp      latest    6b323af908dc   55 minutes ago   152MB
<p>
Running <code>docker run -p 4430:4430 print_timestamp</code> this will now run
the image locally to allow testing
</p>

    > docker ps -a
    CONTAINER ID    IMAGE          COMMAND          CREATED      STATUS         PORTS      
    780f9746a412     print_timestamp   "python print_timest…"   35 seconds ago    Up 34 seconds  0.0.0.0:4430->4430/tcp
<p>
<br>Again running the curl command will call the running server that is
open on port 4430, this giving the expected and same reply as the original
script output.
</p>
<h5 id="k8s">K8s</h5>
<h6 id="minikube">MINIKUBE</h6>
<p>
Now to look at the K8s section and to allow local testing, I used
minikube.<br>This can be built from <a
href="https://minikube.sigs.k8s.io/docs/start/">here</a>
</p>
<p>
Once installed we can start minikube with <code>minikube start</code>
</p>
<p>
<br>Running <code>kb get namespace</code> will show minikube running.
</p>

    > kb get namespaces
    NAME              STATUS   AGE
    default           Active   100m
    kube-node-lease   Active   100m
    kube-public       Active   100m
    kube-system       Active   100m
<p>
We created a deployment yaml.<br>
</p>
    
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: print_timestamp
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: print_timestamp
      template:
        metadata:
          labels:
            app: print_timestamp
        spec:
          containers:
            - name: print_timestamp
              image: print-timestamp:latest
              ports:
                - containerPort: 4430

<p>
<br>On trying to run this (<code>kb apply -f k8s/deployment.yaml</code>)
the underscore I had retained in the naming convention bit me with the
error.<br>
</p>
    
    The Deployment "print_timestamp" is invalid: spec.template.spec.containers[0].name: Invalid value: "print_timestamp": a lowercase RFC 1123 label must consist of lower case alphanumeric characters or '-', and must start and end with an alphanumeric character (e.g. 'my-name',  or '123-abc', regex used for validation is '[a-z0-9]([-a-z0-9]*[a-z0-9])?')

<p>
<br><br>I changed all naming to change the _ (snake) to - (kebab)
to maintain the ease and consistency.
</p>
    
    > cp print_timestamp.py print-timestamp.py
    > docker build -t print-timestamp:latest .
    > docker images
    REPOSITORY        TAG       IMAGE ID       CREATED          SIZE
    print-timestamp  latest    2cf3cf13630f   57 seconds ago   152MB
    print_timestamp  latest    6b323af908dc   2 hours ago      152MB
    > docker rmi 6b323af908dc
    Untagged: print_timestamp:latest
    Deleted: sha256:6b323af908df86dc8c7d70c446683d4dc7b97145b0597a644352b2f6b38bcc
<p>
I realised this image appeared to be a little chunky and so changed to use
alpine as the base.<br>
</p>
    
    # Use a lightweight image
    FROM alpine:latest

    # Install Python3 and pip
    RUN apk add --no-cache python3

    # Set the working directory in the container
    WORKDIR /app

    # Copy the Python script into the container
    COPY print-timestamp.py .

    # Command to run the Python script
    CMD ["python", "print-timestamp.py"]
<p></p>
    
    > docker build -t print-timestamp:alpine .
    > docker images
    REPOSITORY                    TAG       IMAGE ID       CREATED         SIZE
    print-timestamp               alpine    384f39153a36   3 minutes ago   76MB
    print-timestamp               latest    2cf3cf13630f   8 minutes ago   152M
<p>
This was half the size so much more pleasing, it was tested to ensure it was
working correctly.
</p>
<p>
I now updated the deployment yaml to kebab case <br>
</p>
    
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: print-timestamp
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: print-timestamp
      template:
        metadata:
          labels:
            app: print-timestamp
        spec:
          containers:
            - name: print-timestamp
              image: print-timestamp:latest
              ports:
                - containerPort: 4430
<p>
Again running <br>
</p>
    
    > kb apply -f k8s/deployment.yaml
    deployment.apps/print-timestamp created
    > kb get pods -n default
    NAME                              READY  STATUS    RESTARTS   AGE
    print-timestamp-ff5bb948f-9kpdr   0/1    Running   0          8m21s
<p>
We now create the service yaml<br>
</p>
    
    apiVersion: v1
    kind: Service
    metadata:
      name: print-timestamp
    spec:
      selector:
        app: print-timestamp
      ports:
        - protocol: TCP
          port: 4430
          targetPort: 4430
      type: ClusterIP
<p>
We now run and check the services
</p>
    
    > kb apply -f k8s/service.yaml
    service/print-timestamp created
    > kb get services
    NAME              TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)    AGE
    kubernetes        ClusterIP   10.96.0.1     <none>        443/TCP    3h5m
    print-timestamp   ClusterIP   10.99.34.31   <none>        4430/TCP   5m15s
<p>
We now use port forwarding to allow local connection to the cluster<br>
</p>
      
    kubectl port-forward pod/print-timestamp-5b76b58757-84z2k 4430:4430

    Forwarding from 127.0.0.1:4430 -> 4430
    Forwarding from [::1]:4430 -> 4430
<p>
<br>Again using curl we are able to gain a time stamp<br>
</p>
    
    curl 127.0.0.1:4430
    1716331479.8028572
<p>
With output given in the first terminal that the connection was made and
served<br><code>Handling connection for 4430 <br></code>
</p>
<h5 id="horizontal-pod-autoscaler">HORIZONTAL POD AUTOSCALER</h5>
<p>
We create a scaling policy<br>
</p>
    
    apiVersion: autoscaling/v2
    kind: HorizontalPodAutoscaler
    metadata:
      name: print-timestamp
    spec:
      scaleTargetRef:
        apiVersion: apps/v1
        kind: Deployment
        name: print-timestamp
      minReplicas: 1
      maxReplicas: 10
      metrics:
        - type: Resource
          resource:
            name: cpu
            target:
              type: Utilization
              averageUtilization: 50
<p>
<br>We apply this and can now test.<br>
    
    kb apply -f
    k8s/service.yaml
<br>
</p>
<p>
TBC……<br>TESTING, MONITOR and HELM<br>
</p>
<p>
We are to test the hpa next using hey to ensure autoscaling
works.<br><br>I deleted minikube to ensure we had a clean
env<br><br>Ran <code>minikube addons enable metrics-server</code> to ensure we
can pull metrics
</p>
<p>
Ran <code>minikube image load print-timestamp:alpine </code> to ensure image is
available<br><br>Ran <code>kb port-forward
pod/print-timestamp-5b76b58757-8lzsq 4430:4430 </code>to port
forward<br><br>Tested using curl again
</p>
<p>
Running <code>hey -z 30s -c 100 http://127.0.0.1:4430</code> places load on the
cluster and should force scaling
</p>
