---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kuard
spec:
  selector:
    matchLabels:
      app: kuard
  replicas: 1
  template:
    metadata:
      labels:
        app: kuard
    spec:
      containers:
      - name: kuard
        image: gcr.io/kuar-demo/kuard-amd64:blue
        ports:
        - containerPort: 8080
---
kind: Service
apiVersion: v1
metadata:
  name: kuard
spec:
  type: NodePort
  selector:
    app: kuard
  ports:
  - name: http
    targetPort: 8080
    port: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: kuard
  annotations:
    kubernetes.io/ingress.class: "alb"
    alb.ingress.kubernetes.io/group.name: internet-facing
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/certificate-arn: ${ACM_ARN}
    alb.ingress.kubernetes.io/ssl-policy: ELBSecurityPolicy-FS-1-2-Res-2020-10
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS":443}]'  
    alb.ingress.kubernetes.io/ssl-redirect: '443'
    external-dns.alpha.kubernetes.io/hostname: ${APP_NAME}.integration-test.guideplatform.nl
spec:
  rules:
  - host: ${APP_NAME}.integration-test.guideplatform.nl
    http:
      paths:
      - backend:
          service:
            name: kuard
            port: 
              number: 80
        path: "/*"
        pathType: ImplementationSpecific
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: internal-kuard
  annotations:
    kubernetes.io/ingress.class: "alb"
    alb.ingress.kubernetes.io/group.name: internal
    alb.ingress.kubernetes.io/scheme: internal
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/certificate-arn: ${ACM_ARN}
    alb.ingress.kubernetes.io/ssl-policy: ELBSecurityPolicy-FS-1-2-Res-2020-10
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS":443}]'  
    alb.ingress.kubernetes.io/ssl-redirect: '443'
    external-dns.alpha.kubernetes.io/hostname: ${APP_NAME}-internal.integration-test.guideplatform.nl
spec:
  rules:
  - host: ${APP_NAME}-internal.integration-test.guideplatform.nl
    http:
      paths:
      - backend:
          service:
            name: kuard
            port: 
              number: 80
        path: "/*"
        pathType: ImplementationSpecific
