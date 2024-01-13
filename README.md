To run docker containers with WSL2 on windows 11

update WSL and set WSL2 as the default version:\
```wsl.exe --update; wsl --set-default-version 2```

Then install docker desktop. To build and run the image:\
```docker build --ulimit memlock=-1 --no-cache -t docker-tg-webui:latest .; docker run --ulimit memlock=-1 -it -p 7860:7860 -p 5000:5000 --name "docker-tg-webui" --rm --gpus all docker-tg-webui:latest```
