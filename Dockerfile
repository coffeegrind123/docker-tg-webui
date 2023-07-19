# to build and run: docker build -t docker-tg-webui:latest .; docker run -it -p 7860:7860 --name "docker-tg-webui" --rm --gpus all docker-tg-webui:latest
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND noninteractive
WORKDIR /content

RUN apt update && \
    apt install -y python3-dev python3-pip git aria2 && \
    rm -rf /var/lib/apt/lists/*

RUN git clone https://github.com/oobabooga/text-generation-webui && \
    cd /content/text-generation-webui && \
    sed -i -e 's/cu117/cu118/g' requirements.txt && \
    python3 -m pip install -r requirements.txt

RUN echo "\
    \nhttps://huggingface.co/4bit/Llama-2-13b-chat-hf/resolve/main/model-00001-of-00003.safetensors \n dir=/content/text-generation-webui/models/Llama-2-13b-chat-hf \n out=model-00001-of-00003.safetensors \
    \nhttps://huggingface.co/4bit/Llama-2-13b-chat-hf/resolve/main/model-00002-of-00003.safetensors \n dir=/content/text-generation-webui/models/Llama-2-13b-chat-hf \n out=model-00002-of-00003.safetensors \
    \nhttps://huggingface.co/4bit/Llama-2-13b-chat-hf/resolve/main/model-00003-of-00003.safetensors \n dir=/content/text-generation-webui/models/Llama-2-13b-chat-hf \n out=model-00003-of-00003.safetensors \
    \nhttps://huggingface.co/4bit/Llama-2-13b-chat-hf/raw/main/model.safetensors.index.json \n dir=/content/text-generation-webui/models/Llama-2-13b-chat-hf \n out=model.safetensors.index.json \
    \nhttps://huggingface.co/4bit/Llama-2-13b-chat-hf/raw/main/special_tokens_map.json \n dir=/content/text-generation-webui/models/Llama-2-13b-chat-hf \n out=special_tokens_map.json \
    \nhttps://huggingface.co/4bit/Llama-2-13b-chat-hf/resolve/main/tokenizer.model \n dir=/content/text-generation-webui/models/Llama-2-13b-chat-hf \n out=tokenizer.model \
    \nhttps://huggingface.co/4bit/Llama-2-13b-chat-hf/raw/main/tokenizer_config.json \n dir=/content/text-generation-webui/models/Llama-2-13b-chat-hf \n out=tokenizer_config.json \
    \nhttps://huggingface.co/4bit/Llama-2-13b-chat-hf/raw/main/config.json \n dir=/content/text-generation-webui/models/Llama-2-13b-chat-hf \n out=config.json \
    \nhttps://huggingface.co/4bit/Llama-2-13b-chat-hf/raw/main/generation_config.json \n dir=/content/text-generation-webui/models/Llama-2-13b-chat-hf \n out=generation_config.json \
    \n" | aria2c --console-log-level=error -c -x 16 -s 16 -k 1M  --input-file -

CMD cd text-generation-webui && python3 server.py --chat --load-in-8bit --listen --model /content/text-generation-webui/models/Llama-2-13b-chat-hf

EXPOSE 7860
