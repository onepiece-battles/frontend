docker build -t 743018522/onepiece-frontend:latest .
docker image push 743018522/onepiece-frontend:latest
docker rmi 743018522/onepiece-frontend:latest
kubectl delete pods --selector=app=onepiece-frontend
